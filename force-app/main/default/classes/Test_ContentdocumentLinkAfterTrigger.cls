@isTest
private class Test_ContentdocumentLinkAfterTrigger {
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void createDocumentWithLink() {
        String error;
        try {
            SupportCommunityImagelnk__c scl = new SupportCommunityImagelnk__c (
                Image__c = 'tester'
            );
            insert scl;

            ContentVersion cv = new ContentVersion();
            cv.ContentLocation = 'S';
            cv.VersionData = EncodingUtil.base64Decode('d2RTRGZhc2RmYXNkZg==');
            cv.Title = 'test';
            cv.PathOnClient = '/test.txt';
            insert cv;

            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = [
                SELECT Id, ContentDocumentId
                FROM ContentVersion
                WHERE Id =: cv.Id].ContentDocumentId;
            cdl.LinkedEntityId = scl.id;
            cdl.ShareType = 'V';
            insert cdl;

        } catch (Exception e) {
            error = e.getMessage();
        }
        
        System.assertEquals(true, String.isEmpty(error));
    }
}