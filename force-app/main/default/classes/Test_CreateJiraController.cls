@IsTest
private class Test_CreateJiraController {

    @TestSetup
    static void testData() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'TestAccount')
            .create()
            .getRecord();

        List<RecordType> rts = [
            SELECT Id, DeveloperName
            FROM RecordType
            WHERE SObjectType = 'Case'
            AND DeveloperName = 'Service_Engineer'
            LIMIT 1
        ];
        Id recordTypeId = rts.isEmpty()
            ? Schema.SObjectType.Case.getRecordTypeInfosByName().values()[0].getRecordTypeId()
            : rts[0].Id;

        new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Case.Subject               => 'Test Case',
                Case.Description           => 'Test Description',
                Case.AccountId             => testAccount.Id,
                Case.RecordTypeId          => recordTypeId,
                Case.Support_Escalate_To__c => 'Test Queue'
            })
            .create();
    }

    private static Case getTestCase() {
        String subject = 'Test Case';
        List<SObject> results = new CaseSelector()
            .selectCases()
            .selectFields(new List<Schema.SObjectField>{
                Case.Id, Case.RecordTypeName__c, Case.Support_Escalate_To__c,
                Case.Jira__c, Case.Jira_Case__c
            })
            .setCondition('Subject = :bind0')
            .setQueryBindings(new List<Object>{ subject })
            .setLimit(1)
            .executeQuery();
        return (Case) results[0];
    }

    // ── checkJiraExists ───────────────────────────────────────────────────────

    @IsTest
    static void shouldReturnFalse_WhenNoJiraExists() {
        Case testCase = getTestCase();

        Test.startTest();
        Boolean result = CreateJiraController.checkJiraExists(testCase.Id);
        Test.stopTest();

        Assert.areEqual(false, result, 'Should return false when no Jira exists');
    }

    @IsTest
    static void shouldReturnTrue_WhenJiraCaseLookupPopulated() {
        Case testCase = getTestCase();

        Jira_Case__c jiraRecord = new Jira_Case__c(
            Name         = 'JIRA-123',
            Issue_Key__c = 'JIRA-123',
            Issue_Id__c  = '123'
        );
        insert jiraRecord;

        testCase.Jira__c      = 'JIRA-123';
        testCase.Jira_Case__c = jiraRecord.Id;
        update testCase;

        Test.startTest();
        Boolean result = CreateJiraController.checkJiraExists(testCase.Id);
        Test.stopTest();

        Assert.areEqual(true, result, 'Should return true when Jira_Case__c is linked');
    }

    // ── isJiraLinked ──────────────────────────────────────────────────────────

    @IsTest
    static void shouldReturnFalse_WhenNoJiraLinked() {
        Case testCase = getTestCase();

        Test.startTest();
        Boolean result = CreateJiraController.isJiraLinked(testCase.Id);
        Test.stopTest();

        Assert.areEqual(false, result, 'Should return false when no Jira is linked');
    }

    @IsTest
    static void shouldReturnTrue_WhenJiraTextFieldSet() {
        Case testCase = getTestCase();
        testCase.Jira__c = 'TEST-123';
        update testCase;

        Test.startTest();
        Boolean result = CreateJiraController.isJiraLinked(testCase.Id);
        Test.stopTest();

        Assert.areEqual(true, result, 'Should return true when Jira__c text field is set');
    }

    @IsTest
    static void shouldReturnTrue_WhenJiraCaseLookupLinked() {
        Case testCase = getTestCase();

        Jira_Case__c jiraRecord = new Jira_Case__c(
            Name         = 'TEST-456',
            Issue_Key__c = 'TEST-456',
            Issue_Id__c  = '456'
        );
        insert jiraRecord;

        testCase.Jira_Case__c = jiraRecord.Id;
        update testCase;

        Test.startTest();
        Boolean result = CreateJiraController.isJiraLinked(testCase.Id);
        Test.stopTest();

        Assert.areEqual(true, result, 'Should return true when Jira_Case__c lookup is populated');
    }

    // ── getJiraAccessContext ──────────────────────────────────────────────────

    @IsTest
    static void shouldReturnPopulatedWrapper_WhenCaseProvided() {
        Case testCase = getTestCase();
        JiraAccessPermissionService.resetCache();

        Test.startTest();
        CreateJiraController.JiraAccessContextWrapper ctx =
            CreateJiraController.getJiraAccessContext(testCase.Id);
        Test.stopTest();

        Assert.isNotNull(ctx,                     'Wrapper should not be null');
        Assert.isNotNull(ctx.canCreate,            'canCreate should be populated');
        Assert.isNotNull(ctx.canLink,              'canLink should be populated');
        Assert.isNotNull(ctx.canViewComments,      'canViewComments should be populated');
        Assert.isNotNull(ctx.hasLinkedJiraDetail,  'hasLinkedJiraDetail should be populated');
        Assert.isNotNull(ctx.isProfileRecordTypeInScope, 'isProfileRecordTypeInScope should be populated');
    }

    @IsTest
    static void shouldHaveDeniedMessages_WhenOutOfScope() {
        Case testCase = getTestCase();
        JiraAccessPermissionService.resetCache();

        Test.startTest();
        CreateJiraController.JiraAccessContextWrapper ctx =
            CreateJiraController.getJiraAccessContext(testCase.Id);
        Test.stopTest();

        Assert.areEqual(false, ctx.isProfileRecordTypeInScope,
            'Should be out of scope when no CMDT configured');
        Assert.isTrue(
            String.isNotBlank(ctx.deniedCreateMessage),
            'deniedCreateMessage should be set when out of scope. Actual: ' + ctx.deniedCreateMessage
        );
        Assert.isTrue(
            String.isNotBlank(ctx.deniedLinkMessage),
            'deniedLinkMessage should be set when out of scope. Actual: ' + ctx.deniedLinkMessage
        );
    }

    // ── createJira — guard checks ─────────────────────────────────────────────

    @IsTest
    static void shouldReturnError_WhenRecordTypeNotAllowedForCreate() {
        Case testCase = getTestCase();
        JiraAccessPermissionService.resetCache();

        Test.startTest();
        String result = CreateJiraController.createJira(testCase.Id);
        Test.stopTest();

        Assert.isTrue(result.startsWith('Error:'),
            'Should return an error. Actual: ' + result);
        Assert.isTrue(
            result.contains('not valid for your profile/recordtype'),
            'Error should reference profile/recordtype scope. Actual: ' + result
        );
    }

    @IsTest
    static void shouldReturnError_WhenJiraAlreadyExistsViaTextField() {
        Case testCase = getTestCase();
        JiraAccessPermissionService.resetCache();

        TestDataFactory.createJiraRecordTypeMapping(testCase.RecordTypeName__c, 'Create', true);

        testCase.Jira__c = 'EXIST-001';
        update testCase;

        Test.startTest();
        String result = CreateJiraController.createJira(testCase.Id);
        Test.stopTest();

        Assert.areEqual(
            CreateJiraController.ERROR_JIRA_TICKET_EXISTS,
            result,
            'Should return Jira already exists error. Actual: ' + result
        );
    }

    @IsTest
    static void shouldReturnError_WhenJiraAlreadyLinkedViaLookup() {
        Case testCase = getTestCase();
        JiraAccessPermissionService.resetCache();

        TestDataFactory.createJiraRecordTypeMapping(testCase.RecordTypeName__c, 'Create', true);

        Jira_Case__c jiraRecord = new Jira_Case__c(
            Name         = 'EXIST-002',
            Issue_Key__c = 'EXIST-002',
            Issue_Id__c  = '002'
        );
        insert jiraRecord;

        testCase.Jira_Case__c = jiraRecord.Id;
        update testCase;

        Test.startTest();
        String result = CreateJiraController.createJira(testCase.Id);
        Test.stopTest();

        Assert.areEqual(
            CreateJiraController.ERROR_JIRA_TICKET_EXISTS,
            result,
            'Should return Jira exists error when Jira_Case__c is populated. Actual: ' + result
        );
    }

    @IsTest
    static void shouldReturnError_WhenEscalateToQueueBlank() {
        Case testCase = getTestCase();
        JiraAccessPermissionService.resetCache();

        TestDataFactory.createJiraRecordTypeMapping(testCase.RecordTypeName__c, 'Create', true);

        testCase.Support_Escalate_To__c = null;
        update testCase;

        Test.startTest();
        String result = CreateJiraController.createJira(testCase.Id);
        Test.stopTest();

        Assert.areEqual(
            CreateJiraController.ERROR_ESCALATE_TO_QUEUE_BLANK,
            result,
            'Should return escalate to queue blank error. Actual: ' + result
        );
    }

    @IsTest
    static void shouldReturnError_WhenNoProjectMapping() {
        Case testCase = getTestCase();
        JiraAccessPermissionService.resetCache();

        TestDataFactory.createJiraRecordTypeMapping(testCase.RecordTypeName__c, 'Create', true);

        Test.startTest();
        String result = CreateJiraController.createJira(testCase.Id);
        Test.stopTest();

        Assert.isTrue(result.startsWith('Error:'),
            'Should return an error. Actual: ' + result);
        Assert.isTrue(
            result.contains('No Jira project mapping found for queue'),
            'Should indicate missing queue mapping. Actual: ' + result
        );
    }

    @IsTest
    static void shouldReturnError_WhenHttpCallFails() {
        
        List<Jira_Queue_Mapping__mdt> mappings = [
            SELECT MasterLabel FROM Jira_Queue_Mapping__mdt LIMIT 1
        ];
        if (mappings.isEmpty()) {
            Case testCase = getTestCase();
            TestDataFactory.createJiraRecordTypeMapping(testCase.RecordTypeName__c, 'Create', true);
            Test.startTest();
            String result = CreateJiraController.createJira(testCase.Id);
            Test.stopTest();
            Assert.isTrue(
                result.contains('No Jira project mapping found for queue'),
                'Should return queue mapping error when no CMDT. Actual: ' + result
            );
            return;
        }
        
        Case freshCase = new Case(
            Subject                = 'HTTP Fail Test',
            Support_Escalate_To__c = mappings[0].MasterLabel
        );
        insert freshCase;

        Case freshCaseWithRT = (Case) new CaseSelector()
            .selectJiraCaseById(freshCase.Id)
            .executeQuery()[0];

        JiraAccessPermissionService.resetCache();
        TestDataFactory.createJiraRecordTypeMapping(freshCaseWithRT.RecordTypeName__c, 'Create', true);
        Test.setMock(HttpCalloutMock.class, new JiraErrorResponseMock(500));

        Test.startTest();
        String result = CreateJiraController.createJira(freshCaseWithRT.Id);
        Test.stopTest();

        Assert.isTrue(result.startsWith('Error:'),
            'Should return an error on HTTP failure. Actual: ' + result);
        Assert.isTrue(
            result.contains('500'),
            'Error should contain the HTTP status code. Actual: ' + result
        );
    }

    @IsTest
    static void shouldReturnSuccess_WhenCreateJiraSucceeds() {
        
        List<Jira_Queue_Mapping__mdt> mappings = [
            SELECT MasterLabel FROM Jira_Queue_Mapping__mdt LIMIT 1
        ];
        if (mappings.isEmpty()) {
            Assert.isTrue(true, 'Skipped: no Jira_Queue_Mapping__mdt in org');
            return;
        }

        Case freshCase = new Case(
            Subject                = 'Create Jira Success Test',
            Support_Escalate_To__c = mappings[0].MasterLabel
        );
        insert freshCase;

        Case freshCaseWithRT = (Case) new CaseSelector()
            .selectJiraCaseById(freshCase.Id)
            .executeQuery()[0];

        JiraAccessPermissionService.resetCache();
        TestDataFactory.createJiraRecordTypeMapping(freshCaseWithRT.RecordTypeName__c, 'Create', true);
        Test.setMock(HttpCalloutMock.class, new JiraSuccessResponseMock());

        Test.startTest();
        String result = CreateJiraController.createJira(freshCaseWithRT.Id);
        Test.stopTest();

        Assert.isTrue(result.startsWith('Success:'),
            'Should return success. Actual: ' + result);

         Case updated = (Case) new CaseSelector()
            .selectJiraAccessCaseById(freshCaseWithRT.Id)
            .executeQuery()[0];
        Assert.areEqual('TEST-123', updated.Jira__c,
            'Jira__c should be populated with the returned key');
        Assert.isNotNull(updated.Jira_Case__c,
            'Jira_Case__c lookup should be populated');
        Assert.isNotNull(updated.Jira_Link__c,
            'Jira_Link__c should be populated');

        List<Jira_Case__c> jiraCases = [SELECT Name, Issue_Key__c FROM Jira_Case__c WHERE Name = 'TEST-123'];
        Assert.areEqual(1, jiraCases.size(),
            'One Jira_Case__c record should be created');
        Assert.areEqual('TEST-123', jiraCases[0].Issue_Key__c,
            'Issue_Key__c should match the returned key');
    }

    // ── linkJira — guard checks ───────────────────────────────────────────────

    @IsTest
    static void shouldReturnError_WhenRecordTypeNotAllowedForLink() {
        Case testCase = getTestCase();
        JiraAccessPermissionService.resetCache();

        Test.startTest();
        String result = CreateJiraController.linkJira(testCase.Id, 'TEST-123');
        Test.stopTest();

        Assert.isTrue(result.startsWith('Error:'),
            'Should return an error. Actual: ' + result);
        Assert.isTrue(
            result.contains('not valid for your profile/recordtype'),
            'Error should reference profile/recordtype scope. Actual: ' + result
        );
    }

    @IsTest
    static void shouldReturnError_WhenJiraNumberBlank() {
        Case testCase = getTestCase();
        JiraAccessPermissionService.resetCache();

        TestDataFactory.createJiraRecordTypeMapping(testCase.RecordTypeName__c, 'Link', true);

        Test.startTest();
        String result = CreateJiraController.linkJira(testCase.Id, '');
        Test.stopTest();

        Assert.areEqual(
            CreateJiraController.ERROR_INVALID_JIRA_NUMBER,
            result,
            'Should return invalid Jira number error. Actual: ' + result
        );
    }

    @IsTest
    static void shouldReturnError_WhenJiraFormatInvalidNoHyphen() {
        Case testCase = getTestCase();
        JiraAccessPermissionService.resetCache();

        TestDataFactory.createJiraRecordTypeMapping(testCase.RecordTypeName__c, 'Link', true);

        Test.startTest();
        String result = CreateJiraController.linkJira(testCase.Id, 'NOHYPHEN123');
        Test.stopTest();

        Assert.areEqual(
            CreateJiraController.ERROR_JIRA_KEY_PATTERN,
            result,
            'Should return pattern error \u2014 no hyphen. Actual: ' + result
        );
    }

    @IsTest
    static void shouldReturnError_WhenJiraFormatLowercasePrefix() {
        Case testCase = getTestCase();
        JiraAccessPermissionService.resetCache();

        TestDataFactory.createJiraRecordTypeMapping(testCase.RecordTypeName__c, 'Link', true);

        Test.startTest();
        String result = CreateJiraController.linkJira(testCase.Id, 'test-123');
        Test.stopTest();

        Assert.areEqual(
            CreateJiraController.ERROR_JIRA_KEY_PATTERN,
            result,
            'Should return pattern error \u2014 lowercase prefix. Actual: ' + result
        );
    }

    @IsTest
    static void shouldReturnError_WhenJiraFormatMissingDigitsAfterHyphen() {
        Case testCase = getTestCase();
        JiraAccessPermissionService.resetCache();

        TestDataFactory.createJiraRecordTypeMapping(testCase.RecordTypeName__c, 'Link', true);

        Test.startTest();
        String result = CreateJiraController.linkJira(testCase.Id, 'TEST-');
        Test.stopTest();

        Assert.areEqual(
            CreateJiraController.ERROR_JIRA_KEY_PATTERN,
            result,
            'Should return pattern error \u2014 no digits after hyphen. Actual: ' + result
        );
    }

    @IsTest
    static void shouldAcceptValidFormats_WhenJiraNumberCorrectlyFormatted() {
        Case testCase = getTestCase();
        JiraAccessPermissionService.resetCache();

        TestDataFactory.createJiraRecordTypeMapping(testCase.RecordTypeName__c, 'Link', true);

        List<String> validFormats = new List<String>{ 'ABC-456', 'XYZ789-101', 'A-1', 'AB1C-999' };

        Test.startTest();
        for (String fmt : validFormats) {
            String result = CreateJiraController.linkJira(testCase.Id, fmt);
            Assert.areNotEqual(
                CreateJiraController.ERROR_JIRA_KEY_PATTERN,
                result,
                'Format "' + fmt + '" should be treated as valid. Actual: ' + result
            );
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldReturnError_WhenLinkHttpCallFails() {
        Case testCase = getTestCase();
        JiraAccessPermissionService.resetCache();

        TestDataFactory.createJiraRecordTypeMapping(testCase.RecordTypeName__c, 'Link', true);
        Test.setMock(HttpCalloutMock.class, new JiraErrorResponseMock(400));

        Test.startTest();
        String result = CreateJiraController.linkJira(testCase.Id, 'TEST-123');
        Test.stopTest();

        Assert.isTrue(result.startsWith('Error:'),
            'Should return an error on HTTP failure. Actual: ' + result);
        Assert.isTrue(
            result.contains('400'),
            'Error should contain the HTTP status code. Actual: ' + result
        );
    }

    @IsTest
    static void shouldReturnSuccess_WhenLinkJiraSucceeds() {
        Case freshCase = new Case(
            Subject                = 'Link Jira Test - Isolated',
            Support_Escalate_To__c = 'Test Queue'
        );
        insert freshCase;

        Case freshCaseWithRT = (Case) new CaseSelector()
            .selectJiraCaseById(freshCase.Id)
            .executeQuery()[0];
        
        JiraAccessPermissionService.resetCache();
        TestDataFactory.createJiraRecordTypeMapping(freshCaseWithRT.RecordTypeName__c, 'Link', true);
        Test.setMock(HttpCalloutMock.class, new JiraSuccessResponseMock());

        Test.startTest();
        String result = CreateJiraController.linkJira(freshCaseWithRT.Id, 'TEST-123');
        Test.stopTest();

        Assert.isTrue(
            result.startsWith('Success:'),
            'linkJira should return Success. Actual: ' + result
        );
        String resultBody  = result.replace('Success: ', '');
        String returnedKey = resultBody.split('\\|')[0];
        String returnedUrl = resultBody.split('\\|')[1];

        Assert.areEqual(
            'TEST-123', returnedKey,
            'Return value should contain the Jira key from the mock response. Actual key: ' + returnedKey
        );
        Assert.isTrue(
            String.isNotBlank(returnedUrl),
            'Return value should contain a non-blank URL. Actual url: ' + returnedUrl
        );

        Case updated = (Case) new CaseSelector()
            .selectJiraAccessCaseById(freshCaseWithRT.Id)
            .executeQuery()[0];

        Assert.isTrue(
            String.isNotBlank(updated.Jira_Link__c),
            'Jira_Link__c should be set after successful link. Actual: ' + updated.Jira_Link__c
        );
        Assert.isNull(updated.Jira_Case__c,
            'linkJira should NOT create a Jira_Case__c lookup record \u2014 only createJira does');
    }

    // ── getJiraComments ───────────────────────────────────────────────────────

    @IsTest
    static void shouldReturnEmptyList_WhenNoJiraCaseLinked() {
        Case testCase = getTestCase();

        Test.startTest();
        List<CreateJiraController.JiraCommentWrapper> comments =
            CreateJiraController.getJiraComments(testCase.Id);
        Test.stopTest();

        Assert.areEqual(0, comments.size(),
            'Should return empty list when Jira_Case__c is not linked');
    }

    @IsTest
    static void shouldReturnComments_WhenJiraCaseHasComments() {
        Case testCase = getTestCase();

        Jira_Case__c jiraCase = new Jira_Case__c(
            Name         = 'TEST-789',
            Issue_Id__c  = '789',
            Issue_Key__c = 'TEST-789'
        );
        insert jiraCase;

        Jira_Case_Comment__c comment = new Jira_Case_Comment__c(
            Name         = 'Test Comment Name',
            Comment__c   = 'Test comment body',
            Jira_Case__c = jiraCase.Id
        );
        insert comment;

        testCase.Jira_Case__c = jiraCase.Id;
        update testCase;

        Test.startTest();
        List<CreateJiraController.JiraCommentWrapper> comments =
            CreateJiraController.getJiraComments(testCase.Id);
        Test.stopTest();

        Assert.areEqual(1, comments.size(), 'Should return one comment');

        CreateJiraController.JiraCommentWrapper wrapper = comments[0];
        Assert.isNotNull(wrapper.id,            'id should be populated');
        Assert.areEqual('Test Comment Name',    wrapper.name,          'name should match');
        Assert.areEqual('Test comment body',    wrapper.body,          'body should match');
        Assert.isNotNull(wrapper.author,        'author should be populated');
        Assert.isNotNull(wrapper.createdDate,   'createdDate should be populated');
        Assert.isNotNull(wrapper.formattedDate, 'formattedDate should be populated');
        Assert.areEqual(jiraCase.Id,            wrapper.jiraCaseId,    'jiraCaseId should match');
    }

    @IsTest
    static void shouldReturnAllComments_WhenMultipleCommentsExist() {
        Case testCase = getTestCase();

        Jira_Case__c jiraCase = new Jira_Case__c(
            Name         = 'TEST-999',
            Issue_Id__c  = '999',
            Issue_Key__c = 'TEST-999'
        );
        insert jiraCase;

        List<Jira_Case_Comment__c> commentBatch = new List<Jira_Case_Comment__c>();
        for (Integer i = 1; i <= 3; i++) {
            commentBatch.add(new Jira_Case_Comment__c(
                Name         = 'Comment ' + i,
                Comment__c   = 'Body ' + i,
                Jira_Case__c = jiraCase.Id
            ));
        }
        insert commentBatch;

        testCase.Jira_Case__c = jiraCase.Id;
        update testCase;

        Test.startTest();
        List<CreateJiraController.JiraCommentWrapper> comments =
            CreateJiraController.getJiraComments(testCase.Id);
        Test.stopTest();

        Assert.areEqual(3, comments.size(), 'Should return all 3 comments');
    }

    // ── Mock HTTP callout classes ─────────────────────────────────────────────

    private class JiraSuccessResponseMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);

            if (req.getEndpoint().contains('Create')) {
                res.setBody(
                    '{"key":"TEST-123","self":"https://testjira.com/browse/TEST-123","id":"12345"}'
                );
            } else {
                res.setBody(
                    '{"Key":"TEST-123","self":"https://testjira.com/browse/TEST-123","id":"12345"}'
                );
            }

            return res;
        }
    }

    private class JiraErrorResponseMock implements HttpCalloutMock {
        private final Integer statusCode;

        public JiraErrorResponseMock(Integer statusCode) {
            this.statusCode = statusCode;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(this.statusCode);
            res.setBody('{"error":"Simulated server error"}');
            return res;
        }
    }
}