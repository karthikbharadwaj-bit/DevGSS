public with sharing class KnowledgeArticleController {

    @AuraEnabled(cacheable=true)
    public static ContentVersionWrapper getKnowledgeArticleContentVersions(String knowledgeArticleId) {
        try {
            // Fetch the latest ContentVersion record linked to the Knowledge Article
            List<ContentVersion> contentVersions = [
                SELECT Id, Title, VersionData, CreatedDate, FileExtension, FileType, ContentDocumentId
                FROM ContentVersion
                WHERE Knowledge__c = :knowledgeArticleId
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];

            // If no content version is found, return a wrapper with no content
            if (contentVersions.isEmpty()) {
                return new ContentVersionWrapper('', '', '', '', ''); // No content attached
            }

            // Return the content wrapped in the wrapper class
            ContentVersion contentVersion = contentVersions[0];
            return new ContentVersionWrapper(
                contentVersion.Title, 
                getFileContent(contentVersion.Id),
                contentVersion.FileExtension,
                contentVersion.FileType,
                contentVersion.ContentDocumentId
            );
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching content version: ' + e.getMessage());
        }
    }

    // Helper method to retrieve Base64 encoded file content
    @AuraEnabled
    public static String getFileContent(Id contentVersionId) {
        ContentVersion cv = [SELECT VersionData, FileExtension FROM ContentVersion WHERE Id = :contentVersionId LIMIT 1];
        Blob fileData = cv.VersionData;
        String fileExtension = cv.FileExtension?.toLowerCase();
        
        // Handle different file types appropriately
        if (fileExtension == 'html' || fileExtension == 'htm') {
            // For HTML files, convert to string and prepend meta tag
            String fileContent = '<meta charset="UTF-8">' + fileData.toString();
            return EncodingUtil.base64Encode(Blob.valueOf(fileContent));
        } else if (fileExtension == 'pdf') {
            // For PDF files, just encode the binary data as Base64
            return EncodingUtil.base64Encode(fileData);
        } else {
            // For other file types, encode as Base64 without string conversion
            return EncodingUtil.base64Encode(fileData);
        }
    }


    // Wrapper class
    public class ContentVersionWrapper {
        @AuraEnabled public String title;
        @AuraEnabled public String base64Content;
        @AuraEnabled public String fileExtension;
        @AuraEnabled public String fileType;
        @AuraEnabled public String contentDocumentId;

        public ContentVersionWrapper(String title, String base64Content, String fileExtension, String fileType, String contentDocumentId) {
            this.title = title;
            this.base64Content = base64Content;
            this.fileExtension = fileExtension;
            this.fileType = fileType;
            this.contentDocumentId = contentDocumentId;
        }	
    }
    
   }