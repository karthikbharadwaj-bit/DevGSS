@IsTest
public class DialogflowShowEmailsGCPTest {
   	private static final String requestUri = '/services/apexrest/getCaseEmailsForGCP';
    private static final String requestPost ='POST';
    private static final String textSubject ='Case With Text Email';
    private static final String htmlSubject ='Case With HTML Email';
    private static final String withoutSubject ='Case Without Email';
    
    @TestSetup
    static void setupData() {
        // Case with plain text email
        Case cs = (Case) new SObjectBuilder(Case.SObjectType)
            .quantity(1)
            .setFields(
                new Map<SObjectField, Object>{
                    Case.RecordTypeId => CaseHelper.RT_ID_SUPPORT_CASE,
                    Case.Subject => textSubject,
                    Case.Description => 'test Description',
                    Case.Status => 'New',
                    Case.Origin => 'Phone'
                }
            )
            .create()
            .getRecord();
        
        EmailMessage emText = (EmailMessage) new SObjectBuilder(EmailMessage.SObjectType)
            .quantity(1)
            .setFields(
                new Map<SObjectField, Object>{
                    EmailMessage.ParentId => cs.Id,
                    EmailMessage.Subject => 'Test Email Subject',
                    EmailMessage.FromAddress => 'testDescription@test.com',
                    EmailMessage.ToAddress => 'testemail@test.com',
                    EmailMessage.MessageDate => System.now().addMinutes(-5),
                    EmailMessage.TextBody => 'Plain text body',
                    EmailMessage.Status => '3'
                }
            )
            .create()
            .getRecord();

        // Case with HTML email
        Case caseHtml = (Case) new SObjectBuilder(Case.SObjectType)
            .quantity(1)
            .setFields(
                new Map<SObjectField, Object>{
                    Case.RecordTypeId => CaseHelper.RT_ID_SUPPORT_CASE,
                    Case.Subject => htmlSubject,
                    Case.Description => 'test Description',
                    Case.Status => 'New',
                    Case.Origin => 'Phone'
                }
            )
            .create()
            .getRecord();

        EmailMessage emHtml = (EmailMessage) new SObjectBuilder(EmailMessage.SObjectType)
            .quantity(1)
            .setFields(
                new Map<SObjectField, Object>{
                    EmailMessage.ParentId => caseHtml.Id,
                    EmailMessage.Subject => 'Test HTML Email',
                    EmailMessage.FromAddress => 'html@test.com',
                    EmailMessage.ToAddress => 'receiver@test.com',
                    EmailMessage.MessageDate => System.now().addMinutes(-10),
                    EmailMessage.HtmlBody => '<html><body><p>Hello&nbsp;World</p></body></html>',
                    EmailMessage.Status => '3'
                }
            )
            .create()
            .getRecord();

        // Case without email
        Case caseNoEmail = (Case) new SObjectBuilder(Case.SObjectType)
            .quantity(1)
            .setFields(
                new Map<SObjectField, Object>{
                    Case.RecordTypeId => CaseHelper.RT_ID_SUPPORT_CASE,
                    Case.Subject => withoutSubject,
                    Case.Description => 'test Description',
                    Case.Status => 'New',
                    Case.Origin => 'Phone'
                }
            )
            .create()
            .getRecord();

    }

    @IsTest
    static void test_withEmail_textBody() {
        Case c = [SELECT Id FROM Case where Subject =: textSubject LIMIT 1];
        
        RestRequest req = new RestRequest();
        req.requestUri = requestUri;
        req.httpMethod = requestPost;
        req.requestBody = Blob.valueOf(
            JSON.serialize(new Map<String,Object>{ 'recordId' => c.id })
        );
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        DialogflowShowEmailsGCP.getEmailsByCaseId();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode, 'Response should be OK');
        String body = RestContext.response.responseBody.toString();
        System.assert(body.contains('"hasEmail":true'), 'Should return email');
        System.assert(body.contains('Plain text body'), 'Should include text body');
    }

    @IsTest
    static void test_withEmail_htmlBody() {
        Case c = [SELECT Id FROM Case where Subject =:htmlSubject  LIMIT 1];
        
        RestRequest req = new RestRequest();
        req.requestUri = requestUri;
        req.httpMethod = requestPost;
        req.requestBody = Blob.valueOf(
            JSON.serialize(new Map<String,Object>{ 'recordId' => c.id })
        );
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        DialogflowShowEmailsGCP.getEmailsByCaseId();
        Test.stopTest();

        String body = RestContext.response.responseBody.toString();
        System.assert(body.contains('"hasEmail":true'), 'Should return email');
        System.assert(body.contains('Hello World'), 'HTML should be stripped &nbsp; handled');
    }

    @IsTest
    static void test_noEmailFound() {
        Case c = [SELECT Id FROM Case where Subject =: withoutSubject LIMIT 1];
        
        RestRequest req = new RestRequest();
        req.requestUri = requestUri;
        req.httpMethod = requestPost;
        req.requestBody = Blob.valueOf(
            JSON.serialize(new Map<String,Object>{ 'recordId' => c.id })
        );
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        DialogflowShowEmailsGCP.getEmailsByCaseId();
        Test.stopTest();

        String body = RestContext.response.responseBody.toString();
        System.assert(body.contains('"hasEmail":false'), 'No emails should be found');
    }

    @IsTest
    static void test_missingRecordId() {
        RestRequest req = new RestRequest();
        req.requestUri  = requestUri;
        req.httpMethod  = requestPost;
        req.requestBody = Blob.valueOf('{}'); 
        RestContext.request  = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        DialogflowShowEmailsGCP.getEmailsByCaseId();
        Test.stopTest();

        RestResponse res = RestContext.response;
        System.assertEquals(500, res.statusCode, 'Should return error when recordId missing');
        String body = res.responseBody.toString();
        System.assert(body.contains('"success":false'), 'Should indicate failure');
    }
}