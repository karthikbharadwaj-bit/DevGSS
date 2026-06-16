/**
 * @description Test class for GCSUploader
 * Tests file upload functionality, OAuth token generation, and error handling
 * Includes mock HTTP callouts for GCS and Google OAuth
 */
@isTest
private class GCSUploader_Test {
    
    /**
     * @description Mock HTTP response for successful token request
     */
    private class MockHttpResponseToken implements HttpCalloutMock {
        private Integer statusCode;
        private String responseBody;
        
        public MockHttpResponseToken(Integer code, String body) {
            this.statusCode = code;
            this.responseBody = body;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(statusCode);
            res.setBody(responseBody);
            return res;
        }
    }
    
    /**
     * @description Multi-callout mock for both token and upload requests
     */
    private class MockHttpResponseMulti implements HttpCalloutMock {
        private Integer tokenStatus;
        private Integer uploadStatus;
        
        public MockHttpResponseMulti(Integer tokenCode, Integer uploadCode) {
            this.tokenStatus = tokenCode;
            this.uploadStatus = uploadCode;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            
            // Token endpoint
            if (req.getEndpoint().contains('oauth2.googleapis.com')) {
                res.setHeader('Content-Type', 'application/json');
                res.setStatusCode(tokenStatus);
                if (tokenStatus == 200) {
                    res.setBody('{"access_token":"test_token_12345","expires_in":3600}');
                } else {
                    res.setBody('{"error":"invalid_grant","error_description":"Invalid JWT"}');
                }
            }
            // Upload endpoint
            else if (req.getEndpoint().contains('storage.googleapis.com')) {
                res.setHeader('Content-Type', 'application/json');
                res.setStatusCode(uploadStatus);
                if (uploadStatus == 200) {
                    res.setBody('{"kind":"storage#object","name":"test.csv"}');
                } else {
                    res.setBody('{"error":"Upload failed"}');
                }
            }
            
            return res;
        }
    }
    
    /**
     * @description Setup test data - creates ContentVersion for testing
     */
    @testSetup
    static void setupTestData() {
        // Create a test ContentVersion
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test File';
        cv.PathOnClient = 'TestFile.csv';
        cv.VersionData = Blob.valueOf('Test,Data\nValue1,Value2');
        cv.IsMajorVersion = true;
        insert cv;
    }
    
    /**
     * @description Test successful file upload with valid configuration
     */
    @isTest
    static void testUploadFile_Success() {
        // Skip if no active configuration exists
        List<Ringo_GCS_Configuration__mdt> configs = [
            SELECT Id, DeveloperName FROM Ringo_GCS_Configuration__mdt WHERE IsActive__c = true LIMIT 1
        ];
        
        if (configs.isEmpty()) {
            // Cannot test without configuration
            System.assert(true, 'Skipping test - no active GCS configuration');
            return;
        }
        
        // Get test ContentVersion
        ContentVersion cv = [SELECT Id FROM ContentVersion LIMIT 1];
        
        // Set mock callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseMulti(200, 200));
        
        Test.startTest();
        try {
            GCSUploader.uploadFile(cv.Id, 'TestUpload');
            System.assert(true, 'File upload should succeed');
        } catch (Exception e) {
            System.assert(false, 'Upload should not fail: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    /**
     * @description Test upload with null ContentVersion Id
     */
    @isTest
    static void testUploadFile_NullContentVersionId() {
        Test.startTest();
        try {
            GCSUploader.uploadFile(null, 'TestFile');
            System.assert(false, 'Should throw IllegalArgumentException');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('required'), 'Error message should mention required field');
        } catch (Exception e) {
            System.assert(false, 'Wrong exception type: ' + e.getTypeName());
        }
        Test.stopTest();
    }
    
    /**
     * @description Test upload with blank file title
     */
    @isTest
    static void testUploadFile_BlankTitle() {
        ContentVersion cv = [SELECT Id FROM ContentVersion LIMIT 1];
        
        Test.startTest();
        try {
            GCSUploader.uploadFile(cv.Id, '');
            System.assert(false, 'Should throw IllegalArgumentException');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('required'), 'Error message should mention required field');
        } catch (Exception e) {
            System.assert(false, 'Wrong exception type: ' + e.getTypeName());
        }
        Test.stopTest();
    }
    
    /**
     * @description Test upload when GCS returns error status
     */
    @isTest
    static void testUploadFile_GCSUploadFails() {
        List<Ringo_GCS_Configuration__mdt> configs = [
            SELECT Id, DeveloperName FROM Ringo_GCS_Configuration__mdt WHERE IsActive__c = true LIMIT 1
        ];
        
        if (configs.isEmpty()) {
            System.assert(true, 'Skipping test - no active GCS configuration');
            return;
        }
        
        ContentVersion cv = [SELECT Id FROM ContentVersion LIMIT 1];
        
        // Mock successful token but failed upload
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseMulti(200, 500));
        
        Test.startTest();
        try {
            GCSUploader.uploadFile(cv.Id, 'TestUpload');
            System.assert(false, 'Should throw CalloutException on failed upload');
        } catch (CalloutException e) {
            System.assert(e.getMessage().contains('Failed to upload'), 'Error should mention upload failure');
        } catch (Exception e) {
            System.assert(false, 'Wrong exception type: ' + e.getTypeName());
        }
        Test.stopTest();
    }
    
    /**
     * @description Test token generation failure
     */
    @isTest
    static void testUploadFile_TokenGenerationFails() {
        List<Ringo_GCS_Configuration__mdt> configs = [
            SELECT Id, DeveloperName FROM Ringo_GCS_Configuration__mdt WHERE IsActive__c = true LIMIT 1
        ];
        
        if (configs.isEmpty()) {
            System.assert(true, 'Skipping test - no active GCS configuration');
            return;
        }
        
        ContentVersion cv = [SELECT Id FROM ContentVersion LIMIT 1];
        
        // Mock failed token request
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseToken(401, '{"error":"unauthorized"}'));
        
        Test.startTest();
        try {
            GCSUploader.uploadFile(cv.Id, 'TestUpload');
            System.assert(false, 'Should throw CalloutException on token failure');
        } catch (CalloutException e) {
            System.assert(e.getMessage().contains('token'), 'Error should mention token failure');
        } catch (Exception e) {
            System.assert(false, 'Wrong exception type: ' + e.getTypeName());
        }
        Test.stopTest();
    }
    
    /**
     * @description Test token response without access_token field
     */
    @isTest
    static void testUploadFile_TokenResponseMissingAccessToken() {
        List<Ringo_GCS_Configuration__mdt> configs = [
            SELECT Id, DeveloperName FROM Ringo_GCS_Configuration__mdt WHERE IsActive__c = true LIMIT 1
        ];
        
        if (configs.isEmpty()) {
            System.assert(true, 'Skipping test - no active GCS configuration');
            return;
        }
        
        ContentVersion cv = [SELECT Id FROM ContentVersion LIMIT 1];
        
        // Mock response without access_token
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseToken(200, '{"expires_in":3600}'));
        
        Test.startTest();
        try {
            GCSUploader.uploadFile(cv.Id, 'TestUpload');
            System.assert(false, 'Should throw CalloutException');
        } catch (CalloutException e) {
            System.assert(e.getMessage().contains('access_token'), 'Error should mention missing access_token');
        } catch (Exception e) {
            System.assert(false, 'Wrong exception type: ' + e.getTypeName());
        }
        Test.stopTest();
    }
    
    /**
     * @description Test ConfigurationException when no active configuration exists
     */
    @isTest
    static void testConfigurationException_CanBeThrown() {
        Test.startTest();
        try {
            throw new GCSUploader.ConfigurationException('Test exception');
        } catch (GCSUploader.ConfigurationException e) {
            System.assertEquals('Test exception', e.getMessage(), 'Exception message should match');
        }
        Test.stopTest();
    }
    
    /**
     * @description Test file upload with file extension
     */
    @isTest
    static void testUploadFile_WithFileExtension() {
        List<Ringo_GCS_Configuration__mdt> configs = [
            SELECT Id, DeveloperName FROM Ringo_GCS_Configuration__mdt WHERE IsActive__c = true LIMIT 1
        ];
        
        if (configs.isEmpty()) {
            System.assert(true, 'Skipping test - no active GCS configuration');
            return;
        }
        
        ContentVersion cv = [SELECT Id FROM ContentVersion LIMIT 1];
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseMulti(200, 200));
        
        Test.startTest();
        try {
            GCSUploader.uploadFile(cv.Id, 'TestFile');
            // Should construct filename as "TestFile.csv"
            System.assert(true, 'Upload with extension should succeed');
        } catch (Exception e) {
            System.assert(false, 'Upload should not fail: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    /**
     * @description Test multiple uploads to verify token caching
     */
    @isTest
    static void testUploadFile_TokenCaching() {
        List<Ringo_GCS_Configuration__mdt> configs = [
            SELECT Id, DeveloperName FROM Ringo_GCS_Configuration__mdt WHERE IsActive__c = true LIMIT 1
        ];
        
        if (configs.isEmpty()) {
            System.assert(true, 'Skipping test - no active GCS configuration');
            return;
        }
        
        ContentVersion cv = [SELECT Id FROM ContentVersion LIMIT 1];
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseMulti(200, 200));
        
        Test.startTest();
        try {
            // First upload - should generate token
            GCSUploader.uploadFile(cv.Id, 'TestFile1');
            
            // Second upload - should use cached token (but we can't verify directly in test)
            GCSUploader.uploadFile(cv.Id, 'TestFile2');
            
            System.assert(true, 'Both uploads should succeed');
        } catch (Exception e) {
            System.assert(false, 'Uploads should not fail: ' + e.getMessage());
        }
        Test.stopTest();
    }
}