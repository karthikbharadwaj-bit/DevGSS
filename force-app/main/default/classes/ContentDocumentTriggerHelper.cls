public class ContentDocumentTriggerHelper {

    public class CloneContentDocumentToAttachment extends Triggers.TriggerHandlerBase {
        override public void handle() {
            String casePrefix = String.valueOf(Case.SObjectType.getDescribe().getKeyPrefix());
            Set<Id> contentDocumentIds = new Set<Id>();

            // Handle Insert & Update
            if (Trigger.isInsert || Trigger.isUpdate) {
                for (ContentDocument cv : (List<ContentDocument>) Trigger.new) {
                    contentDocumentIds.add(cv.Id);
                }
            }

            // Handle Delete
            if (Trigger.isDelete) {
                for (ContentDocument cdl : (List<ContentDocument>) Trigger.old) {
                    contentDocumentIds.add(cdl.Id); 
                }
            }

            if (!contentDocumentIds.isEmpty()) {
                Map<Id, Id> contentToCaseMap = new Map<Id, Id>();
                for (ContentDocumentLink cdl : [
                                                SELECT ContentDocumentId, LinkedEntityId 
                                                FROM ContentDocumentLink 
                                                WHERE ContentDocumentId IN :contentDocumentIds
            		]) {
                    if (String.valueOf(cdl.LinkedEntityId).startsWith(casePrefix)) {
                        contentToCaseMap.put(cdl.ContentDocumentId, cdl.LinkedEntityId);
                    }
            	}
                if (!contentToCaseMap.isEmpty()) {
                    if (Trigger.isInsert || Trigger.isUpdate) {
                        replicateAttachments(contentDocumentIds, contentToCaseMap);
                    }
                    if (Trigger.isDelete) {
                        deleteAttachments(contentDocumentIds, contentToCaseMap);
                    }
                }
            }
        }

        private void replicateAttachments(Set<Id> contentDocumentIds, Map<Id, Id> contentToCaseMap) {
            List<Attachment> backupAttachments = new List<Attachment>();

            try {
                if (Trigger.isUpdate) {
                    backupAndDeleteAttachments(contentToCaseMap, contentDocumentIds, backupAttachments);
                }

                Map<Id, ContentVersion> contentVersionMap = new Map<Id, ContentVersion>();
                for (ContentVersion cv : [
                    SELECT Id, Title, VersionData, ContentDocumentId, FileExtension, Description, CreatedDate 
                    FROM ContentVersion 
                    WHERE ContentDocumentId IN :contentToCaseMap.keySet() ORDER BY CreatedDate ASC
                ]) {
                    contentVersionMap.put(cv.ContentDocumentId, cv);
                }

                List<Attachment> attachmentsToInsert = new List<Attachment>();
                for (Id contentDocId : contentToCaseMap.keySet()) {
                    if (contentVersionMap.containsKey(contentDocId)) {
                        ContentVersion cv = contentVersionMap.get(contentDocId);
                        Id caseId = contentToCaseMap.get(contentDocId);

                        String formattedName = contentDocId + ' | ' + cv.Title + '.' + cv.FileExtension;

                        Attachment attachment = new Attachment(
                            ParentId = caseId,
                            Name = formattedName,
                            Body = cv.VersionData,
                            Description = cv.Description
                        );
                        attachmentsToInsert.add(attachment);
                    }
                }

                if (!attachmentsToInsert.isEmpty()) {
                    insert attachmentsToInsert;
                }
            } catch (Exception ex) {
                if (!backupAttachments.isEmpty()) {
                    insert backupAttachments;
                }
            }
        }

        private void deleteAttachments(Set<Id> contentDocumentIds, Map<Id, Id> contentToCaseMap) {
            List<Attachment> backupAttachments = new List<Attachment>();
            List<Attachment> filteredAttachmentsToDelete = new List<Attachment>();

            try {
                filteredAttachmentsToDelete = backupAndDeleteAttachments(contentToCaseMap, contentDocumentIds, backupAttachments);
            } catch (Exception ex) {
                if (!backupAttachments.isEmpty()) {
                    insert backupAttachments;
                }
            }
        }

        private List<Attachment> backupAndDeleteAttachments(Map<Id, Id> contentToCaseMap, Set<Id> contentDocumentIds, List<Attachment> backupAttachments) {
            List<Attachment> attachmentsToDelete = [
                SELECT Id, Name, ParentId, Body, Description 
                FROM Attachment 
                WHERE ParentId IN :contentToCaseMap.values()
            ];

            // Backup each attachment properly
            for (Attachment att : attachmentsToDelete) {
                Attachment backupAtt = new Attachment(
                    ParentId = att.ParentId,
                    Name = att.Name,
                    Body = att.Body,  
                    Description = att.Description
                );
                backupAttachments.add(backupAtt);
            }

            List<Attachment> filteredAttachmentsToDelete = new List<Attachment>();
            for (Attachment att : attachmentsToDelete) {
                if (att.Name.contains('|')) {
                    String[] parts = att.Name.split('\\|');
                    if (parts.size() > 1) {
                        Id extractedContentDocId = parts[0].trim();
                        if (contentDocumentIds.contains(extractedContentDocId)) {
                            filteredAttachmentsToDelete.add(att);
                        }
                    }
                }
            }

            if (!filteredAttachmentsToDelete.isEmpty()) {
                delete filteredAttachmentsToDelete;
            }
            return filteredAttachmentsToDelete;
        }
    }
}