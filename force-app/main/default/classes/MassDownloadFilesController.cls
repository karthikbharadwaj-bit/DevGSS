public with sharing class MassDownloadFilesController {
    
    @AuraEnabled(cacheable=true)
    public static List<FileWrapper> fetchRelatedFiles(Id recordId) {
        if (String.isEmpty(recordId)) {
            throw new AuraHandledException('Record ID cannot be null.');
        }

        List<FileWrapper> fileList = new List<FileWrapper>();

        try {            
            // ✅ Using QuerySelector instead of direct SOQL
            List<ContentDocumentLink> documentLinks = new ContentDocumentLinkSelector()
                .selectLinksByLinkedEntityIdForBulkDownloads(new Set<Id>{recordId})
                .executeQuery();

            for (ContentDocumentLink cdl : documentLinks) {
                if (cdl.ContentDocument.LatestPublishedVersionId != null) {
                    fileList.add(new FileWrapper(cdl.ContentDocument.LatestPublishedVersionId, cdl.ContentDocument.Title));
                } 
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving files. Please try again.');
        }
        return fileList;
    }

    public class FileWrapper {
        @AuraEnabled public String Id;
        @AuraEnabled public String Title;
        
        public FileWrapper(String id, String title) {
            this.Id = id;
            this.Title = title;
        }
    }
}