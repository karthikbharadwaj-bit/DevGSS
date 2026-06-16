/**
* EmailArchiveBackfillBatch
* ------------------------------------------------------------------
* Copies EmailMessage → ArchivedEmail__c, and (optionally) deletes the
* source only after a verified archive row exists for that EmailMessage.
*
* Driven by EmailArchiveSettings__c (Org Defaults):
*   RunMode__c              : RANGE | OLDER_THAN
*   WindowStartDate__c      : Date (used when RANGE)
*   WindowEndDate__c        : Date (used when RANGE)
*   OlderThanDays__c        : Number (used when OLDER_THAN)
*   DeleteNow__c            : Boolean (copy + delete in one pass)
*   SummaryEmailTo__c       : Email or CSV (Text(255))
*   IncludeAttachments__c   : Boolean (relink Files to archive)
*   FallbackToHtml__c       : Boolean (use HtmlBody only when TextBody is blank)
*   DeleteOnlyIfClosed__c   : Boolean (optional Case gate)
*   ExcludeCaseStatuses__c  : CSV (optional Case gate; case-insensitive)
*   ArchiveFlag__c          : Boolean (when true, use EmailMessage.ArchiveFlag__c instead of date filters)

* Observability:
* Selection modes (admin chooses any one from below:
*
* 1) Flag-only
*    - settings.ArchiveFlag__c = true
*    - RunMode__c, WindowStartDate__c, WindowEndDate__c, OlderThanDays__c left blank
*    - Result: archive ONLY EmailMessage rows where EmailMessage.ArchiveFlag__c = true
*
* 2) Date-only
*    - settings.ArchiveFlag__c = false
*    - RunMode__c = RANGE  → set WindowStartDate__c and WindowEndDate__c
*      RunMode__c = OLDER_THAN → set OlderThanDays__c (no start/end dates needed)
*    - Result: archive ONLY rows in the computed date window
*
* 3) Flag + Date (intersection)
*    - settings.ArchiveFlag__c = true AND a valid date window
*    - Result: archive rows where (ArchiveFlag__c = true) AND (within date window)
*
*   - Logs exceptions to Exception_And_Notification_History__c (RecordType: Email_Archive_Job)
*   - Sends a plain-text run summary email             
*/

public with sharing class EmailArchiveBackfillBatch
implements Database.Batchable<SObject>, Database.Stateful {

    
    // -----------------------------
    // Runtime state & counters
    // -----------------------------
    private EmailArchiveSettings__c settings;
    private Set<String> excludedCaseStatuses; // lowercase set
    private Id exceptionRecordTypeId;
    
    private Integer totalScanned         = 0;
    private Integer totalArchived        = 0;
    private Integer totalDeleteSucceeded = 0;
    private Integer totalDeleteFailed    = 0;
    
    private List<Exception_And_Notification_History__c> pendingExceptionRows =
        new List<Exception_And_Notification_History__c>();

    
    private static final Integer MAX_ERR_LEN = 255;
    
    // Simple holder for a resolved date window
    private class DateWindow {
        Datetime startDt; // inclusive; may be null
        Datetime endDt;   // inclusive; may be null
    }
    
    // -----------------------------
    // Batchable: start
    // -----------------------------
    public Database.QueryLocator start(Database.BatchableContext bc) {
        settings = EmailArchiveSettings__c.getOrgDefaults();
        if (settings == null) {
            settings = new EmailArchiveSettings__c();
        }
       
        excludedCaseStatuses  = parseCsvToLowerSet(settings.ExcludeCaseStatuses__c);
        exceptionRecordTypeId = findExceptionRecordTypeId('Email_Archive_Job');

        // Compute the date window (RANGE or OLDER_THAN) – it may be unused if blank
        DateWindow window = String.isBlank(settings.RunMode__c)
            ? new DateWindow()
            : resolveDateWindow(settings);
        Datetime startDt = window.startDt;
        Datetime endDt   = window.endDt;

        
        // Build WHERE clause
        List<String> conditions = new List<String>();
        
        // 1) ArchiveFlag mode (optional)
        if (settings.ArchiveFlag__c == true) {
            conditions.add('ArchiveFlag__c = true');
        }

        // 2) Date filters (optional)
        if (startDt != null) {
            conditions.add('CreatedDate >= :startDt');
        }

        if (endDt   != null) {
            conditions.add('CreatedDate <= :endDt');
        }
        
        // Final SOQL
        String soql = 'SELECT Id FROM EmailMessage';
        if (!conditions.isEmpty()) {
            soql += ' WHERE ' + String.join(conditions, ' AND ');
        }
        soql += ' ORDER BY CreatedDate ASC, Id ASC';

        return Database.getQueryLocator(soql);

    }
                
    
    // -----------------------------
    // Batchable: execute
    // -----------------------------
    public void execute(Database.BatchableContext bc, List<EmailMessage> scope) {
        if (scope.isEmpty()) {
            return;
        }
        totalScanned += scope.size();

        
        // collect scope ids
        Set<Id> scopeIds = new Set<Id>();
        for (EmailMessage emailMessage : scope) {
            scopeIds.add(emailMessage.Id);
        }

        
        // Which already have archives? (OriginalEmailMessageId__c is TEXT)
        Set<String> alreadyArchived = new Set<String>();
        for (ArchivedEmail__c archivedEmail : [
            SELECT OriginalEmailMessageId__c
            FROM ArchivedEmail__c
            WHERE OriginalEmailMessageId__c IN :scopeIds
        ]) {
            alreadyArchived.add(archivedEmail.OriginalEmailMessageId__c);
        }

        
        // ----------------- Copy → ArchivedEmail__c -----------------
        List<ArchivedEmail__c> archivesToUpsert = new List<ArchivedEmail__c>();

        
        List<EmailMessage> sources = [
            SELECT Id, Name, ParentId, Subject, FromName, FromAddress, ToAddress, CcAddress, BccAddress,
            TextBody, HtmlBody, MessageDate, Incoming, HasAttachment,
            ThreadIdentifier, MessageIdentifier, Status, IsBounced
            FROM EmailMessage
            WHERE Id IN :scopeIds
        ];

        
        for (EmailMessage emailMessage : sources) {
            if (alreadyArchived.contains((String)emailMessage.Id)) {
                continue; // idempotent
            }

            
            ArchivedEmail__c archive = new ArchivedEmail__c();
            archive.OriginalEmailMessageId__c = emailMessage.Id;
            archive.Case__c                   = emailMessage.ParentId;
            archive.Direction__c              = emailMessage.Incoming ? 'Inbound' : 'Outbound';
            archive.Subject__c                = emailMessage.Subject;
            archive.FromName__c               = emailMessage.FromName;
            archive.FromAddress__c            = emailMessage.FromAddress;
            archive.To__c                     = emailMessage.ToAddress;
            archive.Cc__c                     = emailMessage.CcAddress;
            archive.Bcc__c                    = emailMessage.BccAddress;
            archive.MessageDate__c            = emailMessage.MessageDate;
            archive.HasAttachment__c          = emailMessage.HasAttachment;
            archive.Name                      = toName(emailMessage.Subject);

            
            // Body: copy TextBody; optional fallback from HtmlBody ONLY when TextBody blank.
            String body = emailMessage.TextBody;
            if ((body == null || body.trim() == '') &&
                settings.FallbackToHtml__c == true &&
                emailMessage.HtmlBody != null) {
                    body = stripHtmlToPlainText(emailMessage.HtmlBody);
                }
            archive.BodyText__c = body;

            
            // Threading / diagnostics
            archive.ThreadKey__c = emailMessage.ThreadIdentifier;
            archive.MessageId__c = emailMessage.MessageIdentifier;

            
            // NEW copies
            archive.Status__c    = emailMessage.Status;      // picklist or text, align field type accordingly
            archive.Is_Bounced__c  = emailMessage.IsBounced;   // checkbox

            
            // default queue status for new rows
            if (archive.DeleteStatus__c == null) {
                archive.DeleteStatus__c = 'Pending';
            }

            
            archivesToUpsert.add(archive);
        }

        
        // Upsert by external id
        Map<Id, Id> emailIdToArchiveId = new Map<Id, Id>();
        if (!archivesToUpsert.isEmpty()) {

            try {
                Database.UpsertResult[] upsertResults = Database.upsert(
                    archivesToUpsert,
                    ArchivedEmail__c.Fields.OriginalEmailMessageId__c,
                    /*allOrNone*/ false
                );

                for (Integer index = 0; index < upsertResults.size(); index++) {
                    Database.UpsertResult upsertResult = upsertResults[index];
                    ArchivedEmail__c row = archivesToUpsert[index];
                    if (upsertResult.isSuccess()) {
                        totalArchived++;
                        emailIdToArchiveId.put((Id)row.OriginalEmailMessageId__c, (Id)upsertResult.getId());
                    } else {
                        String msg = (upsertResult.getErrors()!=null && !upsertResult.getErrors().isEmpty())
                            ? upsertResult.getErrors()[0].getMessage()
                            : 'Unknown upsert failure';
                        logException('Archive upsert failed', null, msg, (String)row.OriginalEmailMessageId__c);
                    }
                }

            } catch (Exception ex) {
                logException('Archive upsert threw exception', ex, null, null);
            }
        }

        
        // Optionally re-link Files to the archive record (does not block)
        if (settings.IncludeAttachments__c == true && !emailIdToArchiveId.isEmpty()) {
            moveFilesAndAttachmentsToArchive(emailIdToArchiveId);
        }

        
        // ----------------- Optional Delete -----------------
        if (settings.DeleteNow__c != true) {
            return; // copy-only mode
        }

        
        // Only emails that upserted successfully are candidates for delete.
        // Re-fetch their archive rows (TEXT bind → Set<String>)
        Set<String> emailIdText = new Set<String>();
        for (Id emailId : emailIdToArchiveId.keySet()) {
            emailIdText.add((String)emailId);
        }
        if (emailIdText.isEmpty()) {
            return;
        }

        
        Map<Id, ArchivedEmail__c> archiveByEmailId = new Map<Id, ArchivedEmail__c>();
        for (ArchivedEmail__c archivedEmail : [
            SELECT Id, OriginalEmailMessageId__c,
            Case__c, Case__r.IsClosed, Case__r.Status,
            DeleteStatus__c, LastDeleteError__c, SourceDeleted__c, SourceDeletedDate__c
            FROM ArchivedEmail__c
            WHERE OriginalEmailMessageId__c IN :emailIdText
        ]) {
            archiveByEmailId.put((Id)archivedEmail.OriginalEmailMessageId__c, archivedEmail);
        }

        
        // Apply case gates (optional)
        Set<Id> deleteCandidates = new Set<Id>();
        for (Id emailId : emailIdToArchiveId.keySet()) {
            ArchivedEmail__c archivedEmail = archiveByEmailId.get(emailId);
            if (archivedEmail != null && passesCaseGates(archivedEmail)) {
                deleteCandidates.add(emailId);
            }
        }
        if (deleteCandidates.isEmpty()) {
            return;
        }

        
        // Delete with partial success
        List<EmailMessage> toDelete = [
            SELECT Id
            FROM EmailMessage
            WHERE Id IN :deleteCandidates
            ORDER BY Id
        ];
        if (toDelete.isEmpty()) {
            return;
        }

        
        Database.DeleteResult[] deleteResults = Database.delete(toDelete, /*allOrNone*/ false);

        
        List<ArchivedEmail__c> markDeleted = new List<ArchivedEmail__c>();
        List<ArchivedEmail__c> markFailed  = new List<ArchivedEmail__c>();
        Datetime nowTs = System.now();

        
        for (Integer index = 0; index < toDelete.size(); index++) {
            Id emailId = toDelete[index].Id;
            ArchivedEmail__c archivedEmail = archiveByEmailId.get(emailId);
            if (archivedEmail == null) {
                continue;
            }

            
            Database.DeleteResult deleteResult = deleteResults[index];
            if (deleteResult.isSuccess()) {
                archivedEmail.SourceDeleted__c     = true;
                archivedEmail.SourceDeletedDate__c = nowTs;
                archivedEmail.DeleteStatus__c      = 'Deleted';
                archivedEmail.LastDeleteError__c   = null;
                markDeleted.add(archivedEmail);
                totalDeleteSucceeded++;
            } else {
                String msg = (deleteResult.getErrors()!=null && !deleteResult.getErrors().isEmpty())
                    ? deleteResult.getErrors()[0].getMessage()
                    : 'Unknown delete failure';
                archivedEmail.DeleteStatus__c      = 'Failed';
                archivedEmail.LastDeleteError__c   = truncate(msg);
                markFailed.add(archivedEmail);
                totalDeleteFailed++;
                logException('EmailMessage delete failed', null, msg, String.valueOf(emailId));
            }
        }

        
        if (!markDeleted.isEmpty()) {
            update markDeleted;
        }
        if (!markFailed.isEmpty()) {
            update markFailed;
        }
    }

    
    // -----------------------------
    // Batchable: finish
    // -----------------------------
    public void finish(Database.BatchableContext bc) {
        if (!pendingExceptionRows.isEmpty()) {
            try {
                insert pendingExceptionRows;
                pendingExceptionRows.clear();
            } catch (Exception ex) {
                logException('Persist buffered exceptions failed', ex, null, null);
            }
        }

        
        String subject =
            '[Email Archive] Done | scanned=' + totalScanned +
            ', archived=' + totalArchived +
            ', deletedSuccess=' + totalDeleteSucceeded +
            ', deletedFailed=' + totalDeleteFailed;

        
        String body =
            'Email Archive Backfill — Summary\n' +
            '--------------------------------\n' +
            'Scanned:        ' + totalScanned         + '\n' +
            'Archived:       ' + totalArchived        + '\n' +
            'Deleted Success:' + totalDeleteSucceeded + '\n' +
            'Deleted Failed: ' + totalDeleteFailed    + '\n' +
            'RunMode:        ' + settings.RunMode__c  + '\n' +
            'WindowStart:    ' + String.valueOf(settings.WindowStartDate__c) + '\n' +
            'WindowEnd:      ' + String.valueOf(settings.WindowEndDate__c)   + '\n' +
            'OlderThanDays:  ' + String.valueOf(settings.OlderThanDays__c)   + '\n' +
            'ArchiveFlagMode:' + String.valueOf(settings.ArchiveFlag__c) + '\n' +
            'DeleteNow:      ' + String.valueOf(settings.DeleteNow__c) + '\n';

        
        sendSummary(subject, body);
    }

    
    // ----------------------------------------------------------------
    // Helpers
    // ----------------------------------------------------------------
    private static Set<String> parseCsvToLowerSet(String csv) {
        Set<String> result = new Set<String>();
        if (String.isBlank(csv)) {
            return result;
        }
        for (String token : csv.split('\\s*,\\s*')) {
            if (!String.isBlank(token)) {
                result.add(token.toLowerCase());
            }
        }
        return result;
    }

    
    private DateWindow resolveDateWindow(EmailArchiveSettings__c settings) {
        DateWindow window = new DateWindow();
        String mode = (settings.RunMode__c == null) ? '' : settings.RunMode__c.trim().toUpperCase();

        
        if (mode == 'RANGE') {
            if (settings.WindowStartDate__c != null) {
                window.startDt = DateTime.newInstanceGmt(settings.WindowStartDate__c, Time.newInstance(0, 0, 0, 0));
            }
            if (settings.WindowEndDate__c != null) {
                window.endDt   = DateTime.newInstanceGmt(settings.WindowEndDate__c, Time.newInstance(23, 59, 59, 999));
            }
        } else if (mode == 'OLDER_THAN') {
            if (settings.OlderThanDays__c != null && settings.OlderThanDays__c > 0) {
                Datetime cutoff = System.now().addDays(-(Integer)settings.OlderThanDays__c);
                window.endDt = cutoff; // everything up to this cutoff
            }
        } else {
            // Misconfig → log; query returns nothing if both start & end null.
            logException('Settings invalid: RunMode__c', null,
                         'RunMode__c must be RANGE or OLDER_THAN', null);
        }
        return window;
    }

    
    private Boolean passesCaseGates(ArchivedEmail__c archivedEmail) {
        // If DeleteOnlyIfClosed__c is unchecked, we don't gate on case.closed
        if (settings.DeleteOnlyIfClosed__c == true) {
            if (!(archivedEmail.Case__r != null && archivedEmail.Case__r.IsClosed == true)) {
                return false;
            }
        }
        // If ExcludeCaseStatuses__c is blank, we don't gate on status
        if (!excludedCaseStatuses.isEmpty()) {
            String status = (archivedEmail.Case__r == null || archivedEmail.Case__r.Status == null)
                ? '' : archivedEmail.Case__r.Status.toLowerCase();
            if (excludedCaseStatuses.contains(status)) {
                return false;
            }
        }
        return true;
    }

    
    // --- Logging to Exception_And_Notification_History__c -------------
    private void logException(String title, Exception ex, String details, String affectedId) {
        Exception_And_Notification_History__c row = new Exception_And_Notification_History__c();
        if (exceptionRecordTypeId != null) {
            row.RecordTypeId = exceptionRecordTypeId;
        }
        row.Object_Type__c      = 'EmailMessage';
        row.Record_Id__c        = affectedId;
        row.Exception__c        = truncate(title);
        row.Exception_Desc__c   = truncate(ex == null ? (details == null ? 'No Exception Message' : details) : ex.getMessage());
        row.stackTraceString__c = truncate(ex == null ? 'No Stack Trace' : ex.getStackTraceString());
        pendingExceptionRows.add(row);
    }
    
    private void logException(String title, Exception ex, String details) {
        logException(title, ex, details, null);
    }

    
    private static String truncate(String val) {
        if (val == null) {
            return null;
        }
        return (val.length() > MAX_ERR_LEN) ? val.substring(0, MAX_ERR_LEN - 3) + '...' : val;
    }

    
    private Id findExceptionRecordTypeId(String developerName) {
        try {
            return [
                SELECT Id
                FROM RecordType
                WHERE SObjectType = 'Exception_And_Notification_History__c'
                AND DeveloperName = :developerName
                LIMIT 1
            ].Id;
        } catch (Exception ignore) {
            return null;
        }
    }
    
    
    // --- Files & classic Attachments mover --------------------------------------
    private void moveFilesAndAttachmentsToArchive(Map<Id, Id> emailToArchiveId) {
        if (emailToArchiveId.isEmpty()) {
            return;
        }
        
        Set<Id> emailIds   = emailToArchiveId.keySet();
        Set<Id> archiveIds = new Set<Id>(emailToArchiveId.values());
        
        List<ContentDocumentLink> linksToInsert = new List<ContentDocumentLink>();
        List<Attachment>          attsToInsert  = new List<Attachment>();
        
        // ---------- A) Files already linked to EmailMessage (CDL on EmailMessage) ----------
        try {
            List<ContentDocumentLink> srcFileLinks = [
                SELECT ContentDocumentId, LinkedEntityId, ShareType, Visibility
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN :emailIds
            ];
            for (ContentDocumentLink l : srcFileLinks) {
                Id archiveId = emailToArchiveId.get(l.LinkedEntityId);
                if (archiveId == null) {
                    continue; 
                }
                
                linksToInsert.add(new ContentDocumentLink(
                    ContentDocumentId = l.ContentDocumentId,
                    LinkedEntityId    = archiveId,
                    ShareType         = l.ShareType,
                    Visibility        = l.Visibility
                ));
            }
        } catch (Exception ex) {
            logException('Query ContentDocumentLink for EmailMessage failed', ex, null, null);
        }
        
        // ---------- (Optional) De-dupe links so we don’t hit DUPLICATE_VALUE ----------
        try {
            if (!archiveIds.isEmpty()) {
                Map<Id, Set<Id>> existingByArchive = new Map<Id, Set<Id>>();
                for (ContentDocumentLink existing : [
                    SELECT LinkedEntityId, ContentDocumentId
                    FROM ContentDocumentLink
                    WHERE LinkedEntityId IN :archiveIds
                ]) {
                    if (!existingByArchive.containsKey(existing.LinkedEntityId)) {
                        existingByArchive.put(existing.LinkedEntityId, new Set<Id>());
                    }
                    existingByArchive.get(existing.LinkedEntityId).add(existing.ContentDocumentId);
                }
                
                List<ContentDocumentLink> deduped = new List<ContentDocumentLink>();
                for (ContentDocumentLink cand : linksToInsert) {
                    Set<Id> setForArchive = existingByArchive.get(cand.LinkedEntityId);
                    if (setForArchive == null || !setForArchive.contains(cand.ContentDocumentId)) {
                        deduped.add(cand);
                    }
                }
                linksToInsert = deduped;
            }
        } catch (Exception ex) {
            logException('De-dup existing ContentDocumentLinks failed', ex, null, null);
        }
        
        // ---------- B) Classic Attachments on EmailMessage (blob copy) ----------
        try {
            List<Attachment> srcAttachments = [
                SELECT Id, Name, Body, ContentType, ParentId
                FROM Attachment
                WHERE ParentId IN :emailIds
            ];
            for (Attachment a : srcAttachments) {
                Id archiveId = emailToArchiveId.get(a.ParentId);
                if (archiveId == null) { continue; }
                
                attsToInsert.add(new Attachment(
                    Name        = a.Name,
                    Body        = a.Body,
                    ContentType = a.ContentType,
                    ParentId    = archiveId
                ));
            }
        } catch (Exception ex) {
            logException('Query classic Attachments failed', ex, null, null);
        }
        
        // ---------- DML with per-row error logging ----------
        if (!linksToInsert.isEmpty()) {
            Database.SaveResult[] cdlResults = Database.insert(linksToInsert, /*allOrNone*/ false);
            for (Integer i = 0; i < cdlResults.size(); i++) {
                if (!cdlResults[i].isSuccess()) {
                    String details = (cdlResults[i].getErrors() != null && !cdlResults[i].getErrors().isEmpty())
                        ? cdlResults[i].getErrors()[0].getMessage()
                        : 'Unknown error inserting ContentDocumentLink';
                    ContentDocumentLink failed = linksToInsert[i];
                    String affected = 'ArchiveId=' + String.valueOf(failed.LinkedEntityId) +
                        ', ContentDocumentId=' + String.valueOf(failed.ContentDocumentId);
                    logException('File relink failed (CDL insert)', null, details, affected);
                }
            }
        }
        
        if (!attsToInsert.isEmpty()) {
            Database.SaveResult[] attResults = Database.insert(attsToInsert, /*allOrNone*/ false);
            for (Integer i = 0; i < attResults.size(); i++) {
                if (!attResults[i].isSuccess()) {
                    String details = (attResults[i].getErrors() != null && !attResults[i].getErrors().isEmpty())
                        ? attResults[i].getErrors()[0].getMessage()
                        : 'Unknown error inserting Attachment';
                    Attachment failed = attsToInsert[i];
                    String affected = 'ArchiveId=' + String.valueOf(failed.ParentId) + ', Name=' + failed.Name;
                    logException('Classic attachment copy failed', null, details, affected);
                }
            }
        }
    }
    
    // --- HTML→Text fallback (only when enabled) ------------------------
    private static String stripHtmlToPlainText(String html) {
        if (html == null) {
            return null;
        }
        //stripHtmlTags() also removes whitespace characters
        return html.stripHtmlTags();
    }
    
    // Populate the subject to name field, which is set by default to be visible on the related list view
    private static String toName(String subj) {
        // Record Name has an 80-char limit on text-name objects
        if (String.isBlank(subj)){
            return '(no subject)';
        } 
        return (subj.length() > 80) ? subj.substring(0, 80) : subj;
    }
  
    // --- Summary email -------------------------------------------------
    private void sendSummary(String subject, String body) {
        List<String> toAddresses = new List<String>();
        if (!String.isBlank(settings.SummaryEmailTo__c)) {
            toAddresses.addAll(settings.SummaryEmailTo__c.split('\\s*,\\s*'));
        } else {
            toAddresses.add(UserInfo.getUserEmail());
        }

        
        try {
            Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
            emailMessage.setToAddresses(toAddresses);
            emailMessage.setSubject(subject);
            emailMessage.setPlainTextBody(body);
            Messaging.sendEmail(new List<Messaging.Email>{ emailMessage });
        } catch (Exception ex) {
            logException('Summary email failed', ex, null, null);
            if (!pendingExceptionRows.isEmpty()) {               
                insert pendingExceptionRows;                
                pendingExceptionRows.clear();
            }
        }
    }
}