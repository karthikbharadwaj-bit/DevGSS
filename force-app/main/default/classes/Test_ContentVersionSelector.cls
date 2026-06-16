@isTest
private class Test_ContentVersionSelector {
    //Content version fields defined
    private static final String CONTENT_VERSION_TITLE = '0';
    private static final String CONTENT_VERSION_PATH_ON_CLIENT = 'path';
    private static final String CONTENT_VERSION_VERSION_DATE_VALUE = 'TestContent 1';
	
    //Assert messages defined
    private static final String ASSERT_MESSAGE = 'Content versions should be selected';
    private static final String ASSERT_EQUALS_MESSAGE = 'Wrong content version selected';
    
    @TestSetup
    private static void createTestData(){        
        ContentVersion cv = (ContentVersion) new SObjectBuilder(ContentVersion.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    ContentVersion.Title => CONTENT_VERSION_TITLE,
                    ContentVersion.VersionData => Blob.valueOf(CONTENT_VERSION_VERSION_DATE_VALUE),
                    ContentVersion.PathOnClient => CONTENT_VERSION_PATH_ON_CLIENT
            		}
            )
            .create()
            .getRecord();
    }
    
    @isTest
    private static void testSelectContentVersions(){
    	List<ContentVersion> contentVersions = new ContentVersionSelector(true, true)
            .selectContentVersions()
            .executeQuery();
        
    	System.assert(contentVersions.size() > 0, ASSERT_MESSAGE);
    }
    
    @isTest
    private static void testSelectContentVersionByContentDocumentId(){
        List<ContentVersion> contentVersions = new ContentVersionSelector()
            .selectContentVersions()
            .executeQuery();
        
    	List<ContentVersion> contentVersionByContentDocumentId = new ContentVersionSelector()
            .selectContentVersionByContentDocumentId(new List<Object>{new Set<Id>{contentVersions[0].ContentDocumentId}})
            .executeQuery();
        
        System.assert(contentVersionByContentDocumentId.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(contentVersions[0].Id, contentVersionByContentDocumentId[0].Id, ASSERT_EQUALS_MESSAGE);
    }
    
	@isTest
    private static void testSelectContentVersionById(){
        List<ContentVersion> contentVersions = new ContentVersionSelector()
            .selectContentVersions()
            .executeQuery();
        
    	List<ContentVersion> contentVersionById = new ContentVersionSelector()
            .selectContentVersionById(new List<Object>{new Set<Id>{contentVersions[0].Id}})
            .executeQuery();
        
        System.assert(contentVersionById.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(contentVersions[0].Id, contentVersionById[0].Id, ASSERT_EQUALS_MESSAGE);
    }    
}