@isTest
public class Test_Partner_NumberPortingBoomiProcess {
    @testSetup
    static void testSetup() {
        //Profile p = [select Id, name from Profile where Name = 'Atos Partner Community - Partner Admin' limit 1];
        Profile p = [Select Id from Profile where name = 'System Administrator'];
        UserRole r = new UserRole(PortalType = 'None', Name = 'Test Partner Manager');
        insert r;
        User newUser = new User(
            profileId = p.id,
            UserRoleId = r.Id,
            username = 'UNIT_TEST_USER@email.com',
            email = 'pb@ff.com',
            emailencodingkey = 'UTF-8',
            localesidkey = 'en_US',
            languagelocalekey = 'en_US',
            timezonesidkey = 'America/Los_Angeles',
            alias='nuser',
            lastname='lastname'
        );
        insert newUser;
        System.runAs(newuser) {
            Account acc = new Account (
                Name = 'Test ATOS Account',
                RC_Brand__c ='ATOS Cloud Office',
                OwnerId = newUser.Id
            );
            insert acc;
            Contact con = new Contact (
                AccountId = acc.id,
                LastName = 'Test ATOS Top Master',
                Email = System.now().millisecond() + 'test@2test.com'
            );
            insert con;
            Profile portalProfile = [SELECT Id FROM Profile where name='Atos Partner Community - Partner Admin' Limit 1];
            User anotherUser = new User(alias = 'test123',
                                        email ='test123@noemail.com',
                                        emailencodingkey ='UTF-8', 
                                        lastname ='Testing', 
                                        languagelocalekey ='en_US',
                                        localesidkey ='en_US', 
                                        PortalRole = 'Manager',
                                        profileid = portalProfile.Id, 
                                        country ='United States',IsActive =true,
                                        ContactId = con.Id,
                                        timezonesidkey ='America/Los_Angeles', 
                                        username ='ATOSTOPMASTERUSER@noemail.com');
            insert anotherUser;
            AccountShare testShare = new AccountShare(
                AccountAccessLevel = 'Edit', 
                AccountId = acc.id, 
                CaseAccessLevel = 'Edit', 
                ContactAccessLevel = 'Edit', 
                OpportunityAccessLevel = 'Edit',
                RowCause = 'Manual',
                UserOrGroupId = anotherUser.Id
            );
            insert testShare;
        }
    }
    @isTest
    static void getNumberPortingMappingDetails() {
        User testUser = [select id from user where username = 'ATOSTOPMASTERUSER@noemail.com'];
        //System.runAs(testUser) {
            List<Partner_NumberPortingBoomiProcess.NumberPortingMappingWrapper> results = Partner_NumberPortingBoomiProcess.getNumberPortingMappingDetails();
            System.assertEquals(false, results.isEmpty());   
        //}
    }
    @isTest
    static void generateNumberPortingRequest() {
        User testUser = [select id from user where username = 'ATOSTOPMASTERUSER@noemail.com'];
        System.runAs(testUser) {
            List<String> numberList = new List<String>();
            numberList.add('+12345678');
            Partner_NumberPortingBoomiProcess.StageOneResponseWrapper result = Partner_NumberPortingBoomiProcess.generateNumberPortingRequest('United States', 'US', '2010', 1, true, 'Phone\n+12345678', 'test.csv', numberList);
            Partner_NumberPortingBoomiProcess.getProcessExecutionStatus(result.portingRequestId);
            System.assertNotEquals(null, result);
        }
    }
    @isTest 
    static void checkPortability() {
        Lead testLead = (Lead) new SobjectBuilder(Lead.SObjectType)
        .setFields(
            new Map<SObjectField, Object>{
                Lead.Status => LeadHelper.STATUS_NEW
            }
        )
        .create()
        .getRecord();
        
        Partner_NumberPortingBoomiProcess.StageTwoResponseWrapper result = Partner_NumberPortingBoomiProcess.checkPortability('2010', 'Test', 'GPFS', testLead.id);
        System.assertNotEquals(null, result);
    }
    
    @isTest
    static void getContentDocumentCount() {
        Lead testLead = (Lead) new SobjectBuilder(Lead.SObjectType)
        .setFields(
            new Map<SObjectField, Object>{
                Lead.Status => LeadHelper.STATUS_NEW
            }
        )
        .create()
        .getRecord();
            
        Integer result = Partner_NumberPortingBoomiProcess.getContentDocumentCount(testLead.id);
        System.assertEquals(0, result);
    }
    @isTest
    static void getPortabilityCheckResults() {
        Lead testLead = (Lead) new SobjectBuilder(Lead.SObjectType)
        .setFields(
            new Map<SObjectField, Object>{
                Lead.Status => LeadHelper.STATUS_NEW
            }
        )
        .create()
        .getRecord();
            
        Partner_NumberPortingBoomiProcess.StageThreeResponseWrapper result = Partner_NumberPortingBoomiProcess.getPortabilityCheckResults('GPFS', 'Test', 'United States', testLead.id, true);
        System.assertNotEquals(null, result);
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void getPortabilityHistory() {
        User testUser = [select id from user where username = 'ATOSTOPMASTERUSER@noemail.com'];
        System.runAs(testUser) {
            List<String> numberList = new List<String>();
            numberList.add('+12345678');
            Partner_NumberPortingBoomiProcess.generateNumberPortingRequest('United States', 'US', '2010', 1, true, 'Phone\n+12345678', 'test.csv', numberList);
            Partner_NumberPortingBoomiProcess.getPortabilityHistory(0, 1);
        }
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @istest
    static void getFileData() {
        User testUser = [select id from user where username = 'ATOSTOPMASTERUSER@noemail.com'];
        System.runAs(testUser) {List<String> numberList = new List<String>();
                                numberList.add('+12345678');
                                Partner_NumberPortingBoomiProcess.StageOneResponseWrapper result = Partner_NumberPortingBoomiProcess.generateNumberPortingRequest('United States', 'US', '2010', 1, true, 'Phone\n+12345678', 'test.csv', numberList);
                                Set<Id> numberSet = new Set<Id>();
                                numberSet.add(Id.valueOf(result.portingRequestId));
                                Partner_NumberPortingBoomiProcess.getFileData(numberSet);
                               }
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void checkParsing() {
        StaticResource sr = [SELECT Id, Body FROM StaticResource WHERE Name = 'GPFS_JSON_Response' LIMIT 1];
        String body = sr.Body.toString();
        List<String> bodies = new List<String>();
        bodies.add(body);
        List<Partner_NumberPortingBoomiProcess.NumberPortingResponse> responses = Partner_NumberPortingBoomiProcess.parseResponseBodies('GPFS', 'TEST', 'FR', bodies);
        responses[0].generateCsvHeader();
        responses[0].generateCsvRowData();
        
        StaticResource sr1 = [SELECT Id, Body FROM StaticResource WHERE Name = 'LERGERATOR_US_TOLL_FREE_Response' LIMIT 1];
        String body1 = sr1.Body.toString();
        StaticResource sr2 = [SELECT Id, Body FROM StaticResource WHERE Name = 'LERGERATOR_US_NON_TOLL_FREE_Response' LIMIT 1];
        String body2 = sr2.Body.toString();
        List<String> bodies2 = new List<String>();
        bodies2.add(body1);
        bodies2.add(body2);
        List<Partner_NumberPortingBoomiProcess.NumberPortingResponse> responses2 = Partner_NumberPortingBoomiProcess.parseResponseBodies('Lergerator_US', 'TEST', 'US', bodies2);
        
        StaticResource sr3 = [SELECT Id, Body FROM StaticResource WHERE Name = 'LERGERATOR_US_TOLL_FREE_ERROR_Response' LIMIT 1];
        String body3 = sr3.Body.toString();
        LergeratorUSTollFreeResponse tollFreeResponse = LergeratorUSTollFreeResponse.parse(body3);
        
        StaticResource sr4 = [SELECT Id, Body FROM StaticResource WHERE Name = 'LERGERATOR_UK_Response' LIMIT 1];
        String body4 = sr4.Body.toString();
        LergeratorUKResponse ukResponse = LergeratorUKResponse.parse(body4);
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void updatePortabilityRequestData() {
        User testUser = [select id from user where username = 'ATOSTOPMASTERUSER@noemail.com'];
        System.runAs(testUser) {
            List<String> numberList = new List<String>();
            numberList.add('+12345678');
            Partner_NumberPortingBoomiProcess.StageOneResponseWrapper result = Partner_NumberPortingBoomiProcess.generateNumberPortingRequest('United States', 'US', '2010', 1, true, 'Phone\n+12345678', 'test.csv', numberList);
            StaticResource sr = [SELECT Id, Body FROM StaticResource WHERE Name = 'GPFS_JSON_Response' LIMIT 1];
            String body = sr.Body.toString();
            List<String> bodies = new List<String>();
            bodies.add(body);
            List<Partner_NumberPortingBoomiProcess.NumberPortingResponse> responses = Partner_NumberPortingBoomiProcess.parseResponseBodies('GPFS', 'TEST', 'US', bodies);
            Partner_NumberPortingBoomiProcess.updatePortabilityRequestData(Id.valueOf(result.portingRequestId), 200, '', responses);
        }
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void checkInnerClasses() {
        Partner_NumberPortingBoomiProcess.NumberPortingHistory n = new Partner_NumberPortingBoomiProcess.NumberPortingHistory();
        n.fileList = new List<Partner_NumberPortingBoomiProcess.FileData>();
        n.countryISOCode = '';
        n.countryName = '';
        n.brandCode = '';
        n.requestDateTime = '';
        n.requestType = '';
        n.requestingUser = '';
        n.requestSize = 0;
        n.responseCode = '';
        n.partnerAccount = '';
        n.partnerAccount = '';
        n.uploadFileName = '';
        n.uploadFileContent = '';
        n.uploadFileContentType = '';
        n.requestFileName = '';
        n.requestFileContent = '';
        n.requestFileContentType = '';
        n.resultsFileName = '';
        n.resultsFileContent = '';
        n.resultsFileContentType = '';
        
        Partner_NumberPortingBoomiProcess.FileData f = new Partner_NumberPortingBoomiProcess.FileData();
        f.Content = '';
        f.ContentType = '';
        f.FileUrl = '';
        f.DownloadUrl = '';
        f.Title = '';
        
        Partner_NumberPortingBoomiProcess.NumberPortingResponse npr1 = new Partner_NumberPortingBoomiProcess.NumberPortingResponse();
        LergeratorUSTollFreeResponse.Data data1 = new LergeratorUSTollFreeResponse.Data();
        data1.TN = '12345';
        data1.Number_Type = '';
        data1.Provider_Name = 'test';
        Partner_NumberPortingBoomiProcess.NumberPortingResponse npr2 = new Partner_NumberPortingBoomiProcess.NumberPortingResponse(data1, 'US');
        
        LergeratorUSTollFreeResponse.Errors error1 = new LergeratorUSTollFreeResponse.Errors();
        error1.phone_number = '';
        error1.error_message = '';
        Partner_NumberPortingBoomiProcess.NumberPortingResponse npr3 = new Partner_NumberPortingBoomiProcess.NumberPortingResponse(error1, 'US');
        
        LergeratorUSNonTollFreeResponse.Data data2 = new LergeratorUSNonTollFreeResponse.Data();
        data2.TN = '1234';
        data2.Preferred_Provider_For_Porting = 'Test';
        Partner_NumberPortingBoomiProcess.NumberPortingResponse npr4 = new Partner_NumberPortingBoomiProcess.NumberPortingResponse(data2, 'US');
        
        LergeratorUSNonTollFreeResponse.Errors error2 = new LergeratorUSNonTollFreeResponse.Errors();
        error1.phone_number = '';
        error1.error_message = '';
        Partner_NumberPortingBoomiProcess.NumberPortingResponse npr5 = new Partner_NumberPortingBoomiProcess.NumberPortingResponse(error2, 'US');
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testFileUpload() {
        ApexFileUpload.getContentType('docx');
        ApexFileUpload.getContentType('csv');
        ApexFileUpload.getContentType('txt');
        ApexFileUpload.getContentType('json');
        ApexFileUpload.getContentType('wav');
        ApexFileUpload.getContentType('wmv');
        ApexFileUpload.getContentType('mp3');
        ApexFileUpload.getContentType('mp4');
        ApexFileUpload.getContentType('png');
        ApexFileUpload.getContentType('pdf');
        ApexFileUpload.getContentType('');
        
        Account acc = new Account (
                Name = 'Test Account',
                RC_Brand__c ='Cloud Office',
                OwnerId = UserInfo.getUserId()
            );
        insert acc;
        ApexFileUpload.uploadFile('test', 'test.txt', acc.Id);
    }
}