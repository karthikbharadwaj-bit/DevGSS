@IsTest
public class TestRCPlatformAPICalloutQueueableJob {
    
    @IsTest
    static void testSuccessfullCallout() {
        
        RC_Platform_API_setting__mdt setting = [SELECT Case_Origin__c, Internal_Case_RTs__c, Ebonding_Case_Rts__c ,MakeCallouts__c, Client_ID__c, PrivateKey__c, BaseURL__c 
                                                     FROM RC_Platform_API_setting__mdt WHERE MasterLabel = 'SCP_API' LIMIT 1];
        
        Account accountObj = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'Test account',
                    Account.RC_User_ID__c => '12345678'
                }
            )
            .create()
            .getRecord();
        
        Contact contactObj = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.FirstName => 'TestFirstName',
                Contact.LastName => 'TestLastName',
                Contact.Email => 'test@test.test',
                Contact.AccountId => accountObj.Id
            })
            .create()
            .getRecord();
        
         List<Case> caseList = new List<Case>();
        
         Case newCase1 = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Subject => 'Test case 1',
                Case.Origin => 'Web',
                Case.AccountId => accountObj.Id,
                Case.ContactId => contactObj.Id,
                Case.RecordTypeId => CaseHelper.RT_ID_SUPPORT_T1
            })
            .create()
            .getRecord();
        
           caseList.add(newCase1); 

          Case newCase2 = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Subject => 'Test case 1',
                Case.Origin => 'Web',
                Case.AccountId => accountObj.Id,
                Case.ContactId => contactObj.Id,
                Case.RecordTypeId => CaseHelper.RT_ID_SUPPORT_T1
            })
            .create()
            .getRecord();

        caseList.add(newCase2);

        caseList = [SELECT Id,Subject,AccountId,ContactId,RecordTypeId, ContactEmail, CaseUID__c,CaseNumber, Origin FROM Case WHERE Id IN :caseList];
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockSuccessfullCallout());
        RCPlatformAPICalloutQueueableJob job = new RCPlatformAPICalloutQueueableJob(caseList, setting);
        System.enqueueJob(job);
        Test.stopTest();
        
        List<AsyncApexJob> jobList = [select Status from AsyncApexJob where ApexClass.Name = 'RCPlatformAPICalloutQueueableJob'];
        Assert.isTrue(jobList[0].Status == 'Completed');
    }
    
    @IsTest
    static void testErrorCallout() {
        RC_Platform_API_setting__mdt setting = [SELECT Case_Origin__c, Internal_Case_RTs__c, Ebonding_Case_Rts__c ,MakeCallouts__c, Client_ID__c, PrivateKey__c, BaseURL__c 
                                                     FROM RC_Platform_API_setting__mdt WHERE MasterLabel = 'SCP_API' LIMIT 1];
        
        Account accountObj = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'Test account',
                    Account.RC_User_ID__c => '12345678'
                }
            )
            .create()
            .getRecord();
        
        Contact contactObj = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.FirstName => 'TestFirstName',
                Contact.LastName => 'TestLastName',
                Contact.Email => 'test@test.test',
                Contact.AccountId => accountObj.Id
            })
            .create()
            .getRecord();
        
        List<Case> caseList = new List<Case>();
        
         Case newCase1 = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Subject => 'Test case 1',
                Case.Origin => 'Web',
                Case.AccountId => accountObj.Id,
                Case.ContactId => contactObj.Id,
                Case.RecordTypeId => CaseHelper.RT_ID_SUPPORT_T1
            })
            .create()
            .getRecord();

        caseList.add(newCase1); 

        caseList = [SELECT Id,Subject,AccountId,ContactId,RecordTypeId, ContactEmail, CaseUID__c,CaseNumber, Origin FROM Case WHERE Id IN :caseList];
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockErrorCallout());
        RCPlatformAPICalloutQueueableJob job = new RCPlatformAPICalloutQueueableJob(caseList, setting);
        System.enqueueJob(job);
        Test.stopTest();
        
        List<AsyncApexJob> jobList = [SELECT Status FROM AsyncApexJob WHERE ApexClass.Name = 'RCPlatformAPICalloutQueueableJob'];
        Assert.isTrue(jobList[0].Status == 'Completed');
    }
    
    
    public class MockSuccessfullCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            
            if (req.getEndpoint().contains('/restapi/oauth/token')) {
                res.setStatusCode(200);
                res.setBody('{"access_token":"mockAccessToken"}');
                return res;
            }
            
            // Mock for callDirectorySearchAPI
            if (req.getEndpoint().contains('/directory/entries/search')) {
                res.setStatusCode(200);
                res.setBody('{"records":[{"id":"14155214","type":"User","email":"test@test.test"},{"id":"67890","type":"User","email":"test@test.test"}]}');
                return res;
            }
            
            //Mock for API fetching the filtered extension Id
            if (req.getEndpoint().contains('/extension')) {
                res.setStatusCode(207); // Simulate boundary-separated response
                // Generate a random boundary value
                String boundary = 'Boundary_' + String.valueOf(Crypto.getRandomInteger());
            
                // Setting the Content-Type header with the generated boundary
                res.setHeader('Content-Type', 'multipart/mixed;boundary=' + boundary);
                res.setBody(
                    '--Boundary\r\n' +
                    'Content-Type: application/json\r\n\r\n' +
                    '{"id":"14155214","type":"User","contact":{"emailAsLoginName":true,"email":"test@test.test"}}\r\n' +
                    '--Boundary\r\n' +
                    'Content-Type: application/json\r\n\r\n' +
                    '{"id":"67890","type":"User","contact":{"emailAsLoginName":false,"email":"test@test.test"}}\r\n' +
                    '--Boundary--'
                );
                return res;
            }
            
            res.setStatusCode(200);
            res.setBody('{"status":"Updated"}');
            return res;
        }
    }
    
    public class MockErrorCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            
            if (req.getEndpoint().contains('/restapi/oauth/token')) {
                res.setStatusCode(200);
                res.setBody('{"access_token":"mockAccessToken"}');
                return res;
            }
            
            // Mock for callDirectorySearchAPI
            if (req.getEndpoint().contains('/directory/entries/search')) {
                res.setStatusCode(200);
                res.setBody('{"records":[{"id":"14155214","type":"User","email":"test@test.test"},{"id":"67890","type":"User","email":"test@test.test"}]}');
                return res;
            }
            
            //Mock for API fetching the filtered extension Id
            if (req.getEndpoint().contains('/extension')) {
                res.setStatusCode(207); // Simulate boundary-separated response
                res.setBody(
                    '--Boundary\r\n' +
                    'Content-Type: application/json\r\n\r\n' +
                    '{"id":"67890","type":"User","contact":{"emailAsLoginName":true,"email":"test@test.test"}}\r\n' +
                    '--Boundary\r\n' +
                    'Content-Type: application/json\r\n\r\n' +
                    '{"id":"14155214","type":"User","contact":{"emailAsLoginName":false,"email":"test@test.test"}}\r\n' +
                    '--Boundary--'
                );
                return res;
            }
            
            res.setStatusCode(500);
            res.setBody('{"error":"error occurred"}');
            return res;
        }
    }
}