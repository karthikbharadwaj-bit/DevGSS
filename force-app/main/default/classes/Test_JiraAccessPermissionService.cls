@IsTest
private class Test_JiraAccessPermissionService {

    @TestSetup
    static void testData() {
        Account acct = new Account(Name = 'JAPS Test Account');
        insert acct;

        List<RecordType> rts = [
            SELECT Id, DeveloperName
            FROM RecordType
            WHERE SObjectType = 'Case'
            AND DeveloperName = 'Service_Engineer'
            LIMIT 1
        ];

        Case primaryCase = new Case(
            Subject    = 'JAPS Primary Test Case',
            AccountId  = acct.Id
        );
        if (!rts.isEmpty()) {
            primaryCase.RecordTypeId = rts[0].Id;
        }
        insert primaryCase;

        insert new Case(Subject = 'JAPS No RT Case');
    }

    private static Case getPrimaryCase() {
         String subject = 'JAPS Primary Test Case';
        List<SObject> results = new CaseSelector()
            .selectCases()
            .selectFields(new List<Schema.SObjectField>{
                Case.Id, Case.RecordTypeName__c, Case.Jira__c, Case.Jira_Case__c
            })
            .setCondition('Subject = :bind0')
            .setQueryBindings(new List<Object>{ subject })
            .setLimit(1)
            .executeQuery();
        return (Case) results[0];
    }

    private static Case getBareCase() {
        String subject = 'JAPS No RT Case';
        List<SObject> results = new CaseSelector()
            .selectCases()
            .selectFields(new List<Schema.SObjectField>{
                Case.Id, Case.RecordTypeName__c, Case.Jira__c, Case.Jira_Case__c
            })
            .setCondition('Subject = :bind0')
            .setQueryBindings(new List<Object>{ subject })
            .setLimit(1)
            .executeQuery();
        return (Case) results[0];
    }

    // ── getAccessContext ──────────────────────────────────────────────────────

    @IsTest
    static void shouldReturnEmptyContext_WhenCaseIdNull() {
        Test.startTest();
        JiraAccessPermissionService.JiraAccessContext ctx =
            JiraAccessPermissionService.getAccessContext(null);
        Test.stopTest();

        Assert.isNotNull(ctx,
            'Should return an empty context object, not null');
        Assert.areEqual(false, ctx.canCreate,
            'canCreate should default to false for null caseId');
        Assert.areEqual(false, ctx.canLink,
            'canLink should default to false for null caseId');
        Assert.areEqual(false, ctx.canViewComments,
            'canViewComments should default to false for null caseId');
        Assert.areEqual(false, ctx.hasLinkedJiraDetail,
            'hasLinkedJiraDetail should default to false for null caseId');
        Assert.areEqual(false, ctx.isProfileRecordTypeInScope,
            'isProfileRecordTypeInScope should default to false for null caseId');
    }

    @IsTest
    static void shouldReturnSameInstance_WhenCacheHit() {
        Case cs = getPrimaryCase();
        JiraAccessPermissionService.resetCache();

        Test.startTest();
        JiraAccessPermissionService.JiraAccessContext first  =
            JiraAccessPermissionService.getAccessContext(cs.Id);
        JiraAccessPermissionService.JiraAccessContext second =
            JiraAccessPermissionService.getAccessContext(cs.Id);
        Test.stopTest();

        Assert.isTrue(first === second,
            'Second call should return the same cached instance without rebuilding');
    }

    @IsTest
    static void shouldRebuildContext_WhenCacheReset() {
        Case cs = getPrimaryCase();

        JiraAccessPermissionService.getAccessContext(cs.Id);

        Test.startTest();
        JiraAccessPermissionService.resetCache();
        JiraAccessPermissionService.JiraAccessContext ctx =
            JiraAccessPermissionService.getAccessContext(cs.Id);
        Test.stopTest();

        Assert.isNotNull(ctx,
            'Should successfully rebuild context after cache reset');
    }

    // ── isOperationAllowed — all branches ─────────────────────────────────────

    @IsTest
    static void shouldReturnBoolean_WhenCreateOperationChecked() {
        Case cs = getPrimaryCase();
        JiraAccessPermissionService.resetCache();

        Test.startTest();
        Boolean result = JiraAccessPermissionService.isOperationAllowed(cs.Id, 'Create');
        Test.stopTest();

        Assert.isNotNull(result,
            'Create operation check should return a non-null Boolean');
    }

    @IsTest
    static void shouldReturnBoolean_WhenLinkOperationChecked() {
        Case cs = getPrimaryCase();
        JiraAccessPermissionService.resetCache();

        Test.startTest();
        Boolean result = JiraAccessPermissionService.isOperationAllowed(cs.Id, 'Link');
        Test.stopTest();

        Assert.isNotNull(result,
            'Link operation check should return a non-null Boolean');
    }

    @IsTest
    static void shouldRequireBothPermissions_WhenBothOperationChecked() {
        Case cs = getPrimaryCase();
        JiraAccessPermissionService.resetCache();

        Test.startTest();
        Boolean result = JiraAccessPermissionService.isOperationAllowed(cs.Id, 'Both');
        Test.stopTest();

        JiraAccessPermissionService.JiraAccessContext ctx =
            JiraAccessPermissionService.getAccessContext(cs.Id);
        Boolean expected = ctx.canCreate && ctx.canLink;

        Assert.areEqual(expected, result,
            'Both operation should require canCreate AND canLink to be true');
    }

    @IsTest
    static void shouldReturnFalse_WhenOperationInvalid() {
        Case cs = getPrimaryCase();
        JiraAccessPermissionService.resetCache();

        Test.startTest();
        Boolean result = JiraAccessPermissionService.isOperationAllowed(cs.Id, 'DeleteAll');
        Test.stopTest();

        Assert.areEqual(false, result,
            'Unrecognized operation type should always return false');
    }

    @IsTest
    static void shouldReturnFalse_WhenOperationEmpty() {
        Case cs = getPrimaryCase();
        JiraAccessPermissionService.resetCache();

        Test.startTest();
        Boolean result = JiraAccessPermissionService.isOperationAllowed(cs.Id, '');
        Test.stopTest();

        Assert.areEqual(false, result,
            'Empty operation string should return false');
    }

    @IsTest
    static void shouldReturnFalse_WhenOperationNull() {
        Case cs = getPrimaryCase();
        JiraAccessPermissionService.resetCache();

        Test.startTest();
        Boolean result = JiraAccessPermissionService.isOperationAllowed(cs.Id, null);
        Test.stopTest();

        Assert.areEqual(false, result,
            'Null operation type should return false');
    }

    // ── isRecordTypeConfigured ────────────────────────────────────────────────

    @IsTest
    static void shouldReturnFalse_WhenRecordTypeNameNull() {
        JiraAccessPermissionService.resetCache();

        Test.startTest();
        Boolean result = JiraAccessPermissionService.isRecordTypeConfigured(null);
        Test.stopTest();

        Assert.areEqual(false, result,
            'Null record type name should return false immediately');
    }

    @IsTest
    static void shouldReturnFalse_WhenRecordTypeNameBlank() {
        JiraAccessPermissionService.resetCache();

        Test.startTest();
        Boolean result = JiraAccessPermissionService.isRecordTypeConfigured('   ');
        Test.stopTest();

        Assert.areEqual(false, result,
            'Blank/whitespace-only record type name should return false');
    }

    @IsTest
    static void shouldReturnFalse_WhenRecordTypeUnknown() {
        JiraAccessPermissionService.resetCache();

        Test.startTest();
        Boolean result = JiraAccessPermissionService.isRecordTypeConfigured(
            'NonExistent_RT_XYZ_99999'
        );
        Test.stopTest();

        Assert.areEqual(false, result,
            'Record type not present in any CMDT row should return false');
    }

    @IsTest
    static void shouldBeCaseInsensitive_WhenRecordTypeNormalized() {
        JiraAccessPermissionService.resetCache();

        Test.startTest();
        Boolean upper = JiraAccessPermissionService.isRecordTypeConfigured('SERVICE_ENGINEER');
        Boolean lower = JiraAccessPermissionService.isRecordTypeConfigured('service_engineer');
        Test.stopTest();

        Assert.areEqual(upper, lower,
            'isRecordTypeConfigured should be case-insensitive');
    }

    // ── getConfiguredRecordTypeKeys ───────────────────────────────────────────

    @IsTest
    static void shouldReturnNonNullSet_WhenGetConfiguredRecordTypeKeys() {
        JiraAccessPermissionService.resetCache();

        Test.startTest();
        Set<String> keys = JiraAccessPermissionService.getConfiguredRecordTypeKeys();
        Test.stopTest();

        Assert.isNotNull(keys,
            'Should return a non-null Set even when CMDT is empty');
    }

    @IsTest
    static void shouldReturnNormalizedKeys_WhenGetConfiguredRecordTypeKeys() {
        JiraAccessPermissionService.resetCache();

        Test.startTest();
        Set<String> keys = JiraAccessPermissionService.getConfiguredRecordTypeKeys();
        Test.stopTest();

        for (String key : keys) {
            Assert.areEqual(key.toLowerCase(), key,
                'All returned keys should be lowercase-normalized. Found: ' + key);
            Assert.areEqual(key.trim(), key,
                'All returned keys should be trimmed. Found: ' + key);
        }
    }

    @IsTest
    static void shouldBeConsistentWithIsConfigured_WhenGetConfiguredRecordTypeKeys() {
        JiraAccessPermissionService.resetCache();

        Test.startTest();
        Set<String> keys = JiraAccessPermissionService.getConfiguredRecordTypeKeys();
        Test.stopTest();

        for (String key : keys) {
            Boolean found = JiraAccessPermissionService.isRecordTypeConfigured(key);
            Assert.areEqual(true, found,
                'Key "' + key + '" from getConfiguredRecordTypeKeys should be recognized by isRecordTypeConfigured');
        }
    }

    // ── buildAccessContext — blank recordTypeName path ────────────────────────

    @IsTest
    static void shouldBeOutOfScope_WhenRecordTypeNameBlank() {
        Case cs = getBareCase();
        JiraAccessPermissionService.resetCache();

        Test.startTest();
        JiraAccessPermissionService.JiraAccessContext ctx =
            JiraAccessPermissionService.getAccessContext(cs.Id);
        Test.stopTest();

        Assert.areEqual(false, ctx.isProfileRecordTypeInScope,
            'Blank RecordTypeName__c should result in out-of-scope context');
        Assert.areEqual(false, ctx.canCreate,
            'canCreate should be false when record type key is blank');
        Assert.areEqual(false, ctx.canLink,
            'canLink should be false when record type key is blank');
        Assert.areEqual(false, ctx.canViewComments,
            'canViewComments should be false when record type key is blank');
        Assert.isTrue(
            String.isNotBlank(ctx.message),
            'message should be populated when out of scope. Actual: ' + ctx.message
        );
    }

    // ── hasLinkedJiraDetail — all three field paths ───────────────────────────

    @IsTest
    static void shouldReturnFalse_WhenNoJiraFieldsPopulated() {
        Case cs = getPrimaryCase();
        cs.Jira__c = null;
        update cs;
        JiraAccessPermissionService.resetCache();

        Test.startTest();
        JiraAccessPermissionService.JiraAccessContext ctx =
            JiraAccessPermissionService.getAccessContext(cs.Id);
        Test.stopTest();

        Assert.areEqual(false, ctx.hasLinkedJiraDetail,
            'hasLinkedJiraDetail should be false when no Jira fields are populated');
    }

    @IsTest
    static void shouldReturnTrue_WhenJiraTextFieldPopulated() {
        Case cs = getPrimaryCase();
        cs.Jira__c = 'ABC-111';
        update cs;
        JiraAccessPermissionService.resetCache();

        Test.startTest();
        JiraAccessPermissionService.JiraAccessContext ctx =
            JiraAccessPermissionService.getAccessContext(cs.Id);
        Test.stopTest();

        Assert.areEqual(true, ctx.hasLinkedJiraDetail,
            'hasLinkedJiraDetail should be true when Jira__c text field is populated');
    }

    @IsTest
    static void shouldReturnTrue_WhenJiraCaseLookupPopulated() {
        Case cs = getPrimaryCase();

        Jira_Case__c jiraRecord = new Jira_Case__c(
            Name         = 'ABC-222',
            Issue_Key__c = 'ABC-222',
            Issue_Id__c  = '222'
        );
        insert jiraRecord;

        cs.Jira_Case__c = jiraRecord.Id;
        update cs;
        JiraAccessPermissionService.resetCache();

        Test.startTest();
        JiraAccessPermissionService.JiraAccessContext ctx =
            JiraAccessPermissionService.getAccessContext(cs.Id);
        Test.stopTest();

        Assert.areEqual(true, ctx.hasLinkedJiraDetail,
            'hasLinkedJiraDetail should be true when Jira_Case__c lookup is populated');
    }

    // ── applyDeniedMessages — out-of-scope combinations ──────────────────────

    @IsTest
    static void shouldPopulateAllDeniedMessages_WhenOutOfScope() {
        Case cs = getBareCase();
        JiraAccessPermissionService.resetCache();

        Test.startTest();
        JiraAccessPermissionService.JiraAccessContext ctx =
            JiraAccessPermissionService.getAccessContext(cs.Id);
        Test.stopTest();

        Assert.areEqual(
            JiraAccessPermissionService.MSG_OUT_OF_SCOPE_CREATE_LINK,
            ctx.deniedCreateMessage,
            'Out-of-scope deniedCreateMessage should be MSG_OUT_OF_SCOPE_CREATE_LINK'
        );
        Assert.areEqual(
            JiraAccessPermissionService.MSG_OUT_OF_SCOPE_CREATE_LINK,
            ctx.deniedLinkMessage,
            'Out-of-scope deniedLinkMessage should be MSG_OUT_OF_SCOPE_CREATE_LINK'
        );
        Assert.areEqual(
            JiraAccessPermissionService.MSG_COMMENTS_NOT_ACCESSIBLE,
            ctx.commentsAccessMessage,
            'Out-of-scope commentsAccessMessage should be MSG_COMMENTS_NOT_ACCESSIBLE'
        );
    }

    @IsTest
    static void shouldMatchConstant_WhenOutOfScopeMessage() {
        Case cs = getBareCase();
        JiraAccessPermissionService.resetCache();

        Test.startTest();
        JiraAccessPermissionService.JiraAccessContext ctx =
            JiraAccessPermissionService.getAccessContext(cs.Id);
        Test.stopTest();

        Assert.areEqual(
            JiraAccessPermissionService.MSG_OUT_OF_SCOPE_CREATE_LINK,
            ctx.message,
            'message field should equal MSG_OUT_OF_SCOPE_CREATE_LINK when out of scope'
        );
    }

    // ── resetCache ────────────────────────────────────────────────────────────

    @IsTest
    static void shouldAllowRebuild_WhenCacheReset() {
        Case cs = getPrimaryCase();

        JiraAccessPermissionService.getAccessContext(cs.Id);
        JiraAccessPermissionService.isRecordTypeConfigured('service_engineer');
        JiraAccessPermissionService.getConfiguredRecordTypeKeys();

        Test.startTest();
        JiraAccessPermissionService.resetCache();
        Test.stopTest();

        JiraAccessPermissionService.JiraAccessContext ctx =
            JiraAccessPermissionService.getAccessContext(cs.Id);
        Boolean configured = JiraAccessPermissionService.isRecordTypeConfigured('service_engineer');
        Set<String> keys   = JiraAccessPermissionService.getConfiguredRecordTypeKeys();

        Assert.isNotNull(ctx,        'Context should rebuild after reset');
        Assert.isNotNull(configured, 'isRecordTypeConfigured should work after reset');
        Assert.isNotNull(keys,       'getConfiguredRecordTypeKeys should work after reset');
    }

    // ── JiraAccessContextWrapper — constructor coverage ───────────────────────

    @IsTest
    static void shouldDefaultToSafeValues_WhenWrapperBuiltFromNull() {
        Test.startTest();
        CreateJiraController.JiraAccessContextWrapper wrapper =
            new CreateJiraController.JiraAccessContextWrapper(null);
        Test.stopTest();

        Assert.areEqual(false, wrapper.canCreate,
            'canCreate should default false when built from null');
        Assert.areEqual(false, wrapper.canLink,
            'canLink should default false when built from null');
        Assert.areEqual(false, wrapper.canViewComments,
            'canViewComments should default false when built from null');
        Assert.areEqual(false, wrapper.hasLinkedJiraDetail,
            'hasLinkedJiraDetail should default false when built from null');
        Assert.areEqual(false, wrapper.isProfileRecordTypeInScope,
            'isProfileRecordTypeInScope should default false when built from null');
        Assert.areEqual('', wrapper.message,
            'message should default to empty string when built from null');
        Assert.areEqual('', wrapper.profileName,
            'profileName should default to empty string when built from null');
        Assert.areEqual('', wrapper.recordTypeName,
            'recordTypeName should default to empty string when built from null');
        Assert.areEqual('', wrapper.deniedCreateMessage,
            'deniedCreateMessage should default to empty string when built from null');
        Assert.areEqual('', wrapper.deniedLinkMessage,
            'deniedLinkMessage should default to empty string when built from null');
        Assert.areEqual('', wrapper.commentsAccessMessage,
            'commentsAccessMessage should default to empty string when built from null');
    }

    @IsTest
    static void shouldMirrorSource_WhenWrapperBuiltFromRealContext() {
        Case cs = getPrimaryCase();
        JiraAccessPermissionService.resetCache();

        JiraAccessPermissionService.JiraAccessContext source =
            JiraAccessPermissionService.getAccessContext(cs.Id);

        Test.startTest();
        CreateJiraController.JiraAccessContextWrapper wrapper =
            new CreateJiraController.JiraAccessContextWrapper(source);
        Test.stopTest();

        Assert.areEqual(source.canCreate,                  wrapper.canCreate,               'canCreate should mirror source');
        Assert.areEqual(source.canLink,                    wrapper.canLink,                 'canLink should mirror source');
        Assert.areEqual(source.canViewComments,            wrapper.canViewComments,         'canViewComments should mirror source');
        Assert.areEqual(source.hasLinkedJiraDetail,        wrapper.hasLinkedJiraDetail,     'hasLinkedJiraDetail should mirror source');
        Assert.areEqual(source.isProfileRecordTypeInScope, wrapper.isProfileRecordTypeInScope, 'isProfileRecordTypeInScope should mirror source');
        Assert.areEqual(source.message,                    wrapper.message,                 'message should mirror source');
        Assert.areEqual(source.profileName,                wrapper.profileName,             'profileName should mirror source');
        Assert.areEqual(source.recordTypeName,             wrapper.recordTypeName,          'recordTypeName should mirror source');
        Assert.areEqual(source.deniedCreateMessage,        wrapper.deniedCreateMessage,     'deniedCreateMessage should mirror source');
        Assert.areEqual(source.deniedLinkMessage,          wrapper.deniedLinkMessage,       'deniedLinkMessage should mirror source');
        Assert.areEqual(source.commentsAccessMessage,      wrapper.commentsAccessMessage,   'commentsAccessMessage should mirror source');
    }

    // ── JiraAccessContext default constructor ─────────────────────────────────

    @IsTest
    static void shouldDefaultAllFieldsFalseOrEmpty_WhenDefaultConstructor() {
        Test.startTest();
        JiraAccessPermissionService.JiraAccessContext ctx =
            new JiraAccessPermissionService.JiraAccessContext();
        Test.stopTest();

        Assert.areEqual(false, ctx.canCreate,                  'canCreate default should be false');
        Assert.areEqual(false, ctx.canLink,                    'canLink default should be false');
        Assert.areEqual(false, ctx.canViewComments,            'canViewComments default should be false');
        Assert.areEqual(false, ctx.hasLinkedJiraDetail,        'hasLinkedJiraDetail default should be false');
        Assert.areEqual(false, ctx.isProfileRecordTypeInScope, 'isProfileRecordTypeInScope default should be false');
        Assert.areEqual('',   ctx.message,                    'message default should be empty string');
        Assert.areEqual('',   ctx.profileName,                'profileName default should be empty string');
        Assert.areEqual('',   ctx.recordTypeName,             'recordTypeName default should be empty string');
        Assert.areEqual('',   ctx.deniedCreateMessage,        'deniedCreateMessage default should be empty string');
        Assert.areEqual('',   ctx.deniedLinkMessage,          'deniedLinkMessage default should be empty string');
        Assert.areEqual('',   ctx.commentsAccessMessage,      'commentsAccessMessage default should be empty string');
    }
}