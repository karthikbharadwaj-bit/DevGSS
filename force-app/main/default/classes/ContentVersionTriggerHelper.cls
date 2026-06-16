public with sharing class ContentVersionTriggerHelper {

    public class DocuSignDocumentsProcessing extends Triggers.TriggerHandlerBase {
        override public void handle() {

            Set<Id> contentDocumentsIds = new Set<Id>();

            for (ContentVersion cv : (List<ContentVersion>) Trigger.new) {
                contentDocumentsIds.add(cv.ContentDocumentId);
            }

            List<ContentDocumentLink> links = [SELECT ContentDocumentId, LinkedEntityId,
                TYPEOF LinkedEntity
                    WHEN dsfs__DocuSign_Status__c THEN dsfs__Envelope_Status__c, dsfs__Company__c
                END
                FROM ContentDocumentLink
                WHERE ContentDocumentId IN: contentDocumentsIds];

            List<ContentDocumentLink> linksToDocusignRecords = new List<ContentDocumentLink>();
            for (ContentDocumentLink cdl : links) {
                if (cdl.LinkedEntityId.getSobjectType() == dsfs__DocuSign_Status__c.SObjectType) {
                    linksToDocusignRecords.add(cdl);
                }
            }

            if (linksToDocusignRecords.isEmpty()) {
                return;
            }

            Set<Id> accIdSet = new Set<Id>();
            for (ContentDocumentLink cdl : linksToDocusignRecords) {
                dsfs__DocuSign_Status__c envelope = cdl.LinkedEntity;
                if (envelope.dsfs__Company__c != null) {
                    accIdSet.add(envelope.dsfs__Company__c);
                }
            }

            List<ContentDocumentLink> toInsert = buildDocumentLinks(linksToDocusignRecords, accIdSet);
            insert toInsert;
        }

        private List<ContentDocumentLink> buildDocumentLinks(List<ContentDocumentLink> links, Set<Id> accIdSet) {

            List<ContentDocumentLink> result = new List<ContentDocumentLink>();

            if (links == null || links.isEmpty()) {
                return result;
            }

            Map<Id, Set<SObjectType>> documentIdToRelatedTypesMap = buildDocumentIdToRelatedTypesMap(links);
            Map<Id, Id> accountIdToActiveContractIdMap = buildAccountIdToActiveContractIdMap(accIdSet);

            for (ContentDocumentLink cdl : links) {
                Set<SObjectType> relatedTypes = documentIdToRelatedTypesMap.get(cdl.ContentDocumentId);
                Boolean isAccountLinkExist = relatedTypes.contains(Account.SObjectType);
                Boolean isContractLinkExist = relatedTypes.contains(Contract.SObjectType);
                Boolean isLinkExistOnRequiredTypes = isAccountLinkExist && isContractLinkExist;
                dsfs__DocuSign_Status__c envelope = cdl.LinkedEntity;
                if (envelope.dsfs__Envelope_Status__c == DocuSignHelper.ENVELOPE_STATUS_COMPLETED && !isLinkExistOnRequiredTypes) {
                    if (!isAccountLinkExist) {
                        ContentDocumentLink linkForAccount = cdl.clone();
                        linkForAccount.LinkedEntityId = envelope.dsfs__Company__c;
                        result.add(linkForAccount);
                    }

                    if (!isContractLinkExist && accountIdToActiveContractIdMap.containsKey(envelope.dsfs__Company__c)) {
                        ContentDocumentLink linkForContract = cdl.clone();
                        linkForContract.LinkedEntityId = accountIdToActiveContractIdMap.get(envelope.dsfs__Company__c);
                        result.add(linkForContract);
                    }
                }
            }

            return result;
        }

        @testVisible
        private Map<Id, Set<SObjectType>> buildDocumentIdToRelatedTypesMap(List<ContentDocumentLink> links) {

            Map<Id, Set<SObjectType>> documentIdToRelatedTypesMap = new Map<Id, Set<SObjectType>>();

            if (links == null || links.isEmpty()) {
                return documentIdToRelatedTypesMap;
            }

            for (ContentDocumentLink cdl : links) {
                if (!documentIdToRelatedTypesMap.containsKey(cdl.ContentDocumentId)) {
                    documentIdToRelatedTypesMap.put(cdl.ContentDocumentId, new Set<SObjectType>());
                }
                documentIdToRelatedTypesMap.get(cdl.ContentDocumentId).add(cdl.LinkedEntityId.getSObjectType());
            }

            return documentIdToRelatedTypesMap;
        }

        @testVisible
        private Map<Id, Id> buildAccountIdToActiveContractIdMap(Set<Id> accIdSet) {

            Map<Id, Id> accountIdToActiveContractIdMap = new Map<Id, Id>();

            if (accIdSet == null || accIdSet.isEmpty()) {
                return accountIdToActiveContractIdMap;
            }

            List<Account> accs = (List<Account>) new AccountSelector()
                .selectAccountsWithActiveContract(new List<Object>{new List<Id>(accIdSet)})
                .executeQuery();

            for (Account acc : accs) {
                Contract activeContract = !acc.Contracts.isEmpty() ? acc.Contracts[0] : null;
                if (activeContract != null) {
                    accountIdToActiveContractIdMap.put(acc.Id, activeContract.Id);
                }
            }

            return accountIdToActiveContractIdMap;
        }
    }

    // This code is added as part of PBC-24750 Accommodate new versions of content document and delete the old one
   
    public class HandleAfterUpdateProcessing extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<ContentVersion> newContentVersions = (List<ContentVersion>) Trigger.new;
            handleAfterUpdate(newContentVersions);
        }
        
        public void handleAfterUpdate(List<ContentVersion> newContentVersions) {
            Map<Id, ContentVersion> latestContentVersionByKnowledge = new Map<Id, ContentVersion>();
            
            // Identify the latest ContentVersion for each Knowledge Article
            
            for (ContentVersion cv : newContentVersions) {
                // Ensure the ContentVersion is not null and has a valid Knowledge Article ID and CreatedDate
                if (cv != null && cv.Knowledge__c != null && cv.CreatedDate != null) {
                    ContentVersion existingCv = latestContentVersionByKnowledge.get(cv.Knowledge__c); 
                    if (existingCv == null || cv.CreatedDate > existingCv.CreatedDate) {  // Check if a ContentVersion for this Knowledge Article already exists in the map
                        latestContentVersionByKnowledge.put(cv.Knowledge__c, cv);  // If no existing ContentVersion is found, or the current one is newer, update the map
                    }
                }
            }
            
            
            // Collect Knowledge Article IDs and ContentVersion Titles for filtering
            Set<Id> knowledgeIds = latestContentVersionByKnowledge.keySet();
            Map<Id, String> knowledgeIdToLatestTitlePart = new Map<Id, String>();
            
            for (Id knowledgeId : knowledgeIds) {
                ContentVersion latestCv = latestContentVersionByKnowledge.get(knowledgeId);
                
                // Ensure ContentVersion and Title are valid
                if (latestCv != null && latestCv.Title != null) {
                    knowledgeIdToLatestTitlePart.put(knowledgeId, getTitlePart(latestCv.Title));
                }
            }
            
            // Fetch all relevant ContentDocuments for these Knowledge Articles and titles
            List<ContentDocument> documentsToDelete = new List<ContentDocument>();
            List<ContentVersion> olderContentVersions = (List<ContentVersion>) new ContentVersionSelector()
            .selectContentVersionsByKnowledgeIds(knowledgeIds)
            .executeQuery();
            
            for (ContentVersion cv : olderContentVersions) {
                // Ensure ContentVersion is valid, associated with a Knowledge Article, and has a Title
                if (cv != null && cv.Knowledge__c != null && cv.Title != null) {
                    ContentVersion latestContentVersion = latestContentVersionByKnowledge.get(cv.Knowledge__c);
                    if (latestContentVersion != null) {
                        // Extract the title part for the current and latest ContentVersions
                        String currentTitlePart = getTitlePart(cv.Title); // Get the title part of the current version
                        String latestTitlePart = knowledgeIdToLatestTitlePart.get(cv.Knowledge__c); // Get the title part of the latest version
                        
                        // Check if both title parts exist, match, and the current version is not the latest
                        if (currentTitlePart != null && latestTitlePart != null &&
                            currentTitlePart == latestTitlePart && cv.Id != latestContentVersion.Id) {
                                // Add the ContentDocument associated with the older version to the deletion list
                                documentsToDelete.add(new ContentDocument(Id = cv.ContentDocumentId));
                            }
                    }
                }
            }
            // Delete all older ContentDocuments
            if (!documentsToDelete.isEmpty()) {
                try {
                    delete documentsToDelete;
                } catch (DmlException e) {
                    Exception_And_Notification_History__c exceptionRecord = new Exception_And_Notification_History__c(
                        Exception_Desc__c = e.getMessage(),
                        stackTraceString__c = e.getStackTraceString(),
                        Exception__c = e.getTypeName(),
                        Line_Number__c = e.getLineNumber()
                    );
                    ExceptionAndNotificationHelper.trackExceptions(exceptionRecord, e);
                }
            }
            
        }
        
        // Helper method to extract the part after '/' from the title
        private String getTitlePart(String title) {
            if (title != null && title.contains('/')) {
                String[] parts = title.split('/');
                if (parts != null && parts.size() > 1) {
                    return parts[1].trim(); // Return the part after '/'
                }
            }
            return title != null ? title.trim() : null; // Return the original title if '/' is not found
        }
        
    }

}