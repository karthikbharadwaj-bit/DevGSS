@isTest
private class Test_GDPRHelper
{
    @TestSetup
    static void setup() {

        Map<SObjectField, Object> settingsMap = new Map<SObjectField, Object> {
            GDPR_Requests__c.Name => ValueProviderBuilder.provideList(new List<String>{'Account', 'Contact'}),
            GDPR_Requests__c.Object_name__c => ValueProviderBuilder.provideList(new List<String>{'Account', 'Contact'}),
            GDPR_Requests__c.Priority__c => ValueProviderBuilder.provideList(new List<Integer>{100, 10}),
            GDPR_Requests__c.RetentionPeriod__c => ValueProviderBuilder.provideList(new List<Integer>{120, 55}),
            GDPR_Requests__c.CsvLogLimit__c => ValueProviderBuilder.provideList(new List<Integer>{5, 5})
        };

        SObjectBuilder settings = new SObjectBuilder(GDPR_Requests__c.SObjectType)
                                        .quantity(2)
                                        .setFields(settingsMap)
                                        .create();



        Map<SObjectField, Object> churnDate = new Map<SObjectField, Object> {
            Account.RC_Churn_Date__c => Datetime.now().addMonths(-121)
        };
        List<SObject> accs = new SObjectBuilder(Account.SObjectType).quantity(10)
                                    .setFields(churnDate)
                                    .create()
                                    .getRecords();


        SObjectBuilder contsBuilder = new SObjectBuilder(Contact.SObjectType)
                                            .quantity(10)
                                            .setField(Contact.AccountId, ValueProviderBuilder.provideParents(accs))
                                            .create();
    }

    @isTest
    static void testProcessDeactivation () {
        List<Contact> conts = [SELECT Id FROM Contact LIMIT 1];
        User u = createPortalUser(conts[0]);
        insert u;

        List<GDPRHelper> allRequests = GDPRHelper.getRequestsQueue(false);
        GDPRHelper userDeactivation = allRequests[0];

        Test.startTest();
            userDeactivation.processRequest(userDeactivation.getRecords());
        Test.stopTest();
        User uToCheck = [SELECT Id, IsActive FROM User WHERE Id = :u.Id];
        System.assertEquals(false, uToCheck.IsActive);
    }

    @isTest
    static void testScrambling () {
        GDPRHelper gdpr = new GDPRHelper('Contact', null, 1, null, null, null, null);
        gdpr.fieldsToScramble = new List<String> {'LastName'};
        gdpr.setCustomWhere(' LastName != null ');

        List<sObject> records = gdpr.getRecords();
        for (Contact c : [SELECT Id, LastName FROM Contact]) {
            System.assertEquals('Doe', c.LastName);
        }
        System.assertEquals(10, records.size());

        Test.startTest();
            gdpr.processRequest(records);
            for (Contact c : [SELECT Id, LastName FROM Contact]) {
                System.assertNotEquals('Doe', c.LastName);
            }
        Test.stopTest();
    }

    @isTest
    static void testDeletion () {
        List<GDPRHelper> allRequests = GDPRHelper.getRequestsQueue(false);
        GDPRHelper contactDeletionRequest = allRequests[1];

        Id rtId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(GDPRHelper.SFDC_DATA_DELETION).getRecordTypeId();
        List<Case> similarCases = [SELECT Id, (Select Id FROM Attachments) FROM Case WHERE RecordTypeId =:rtId];
        System.assertEquals(0, similarCases.size());

        List<Contact> conts = [SELECT Id FROM Contact];
        System.assertEquals(10, conts.size());

        contactDeletionRequest.processRequest(contactDeletionRequest.getRecords());
        conts = [SELECT Id FROM Contact];
        System.assertEquals(0, conts.size());

        contactDeletionRequest.logAsCsv(true);

        similarCases = [SELECT Id, (Select Id FROM Attachments) FROM Case WHERE RecordTypeId =:rtId];
        System.assertEquals(1, similarCases.size());
        System.assertEquals(1, similarCases[0].Attachments.size());
    }

    @isTest
    static void testDeletion_testMode () {
        List<GDPRHelper> allRequests = GDPRHelper.getRequestsQueue(true);
        GDPRHelper contactDeletionRequest = allRequests[1];

        List<Contact> conts = [SELECT Id FROM Contact];
        System.assertEquals(10, conts.size());

        List<sObject> objs = contactDeletionRequest.getRecords();
        System.assertEquals(10, objs.size());

        contactDeletionRequest.processRequest(objs);
        conts = [SELECT Id FROM Contact];
        System.assertEquals(10, conts.size());
        System.assertEquals(10, contactDeletionRequest.recordsToExport.size());

        contactDeletionRequest.logAsCsv(true);

        Id rtId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(GDPRHelper.SFDC_DATA_DELETION).getRecordTypeId();
        List<Case> similarCases = [SELECT Id, (Select Id FROM Attachments) FROM Case WHERE RecordTypeId =:rtId];
        System.assertEquals(1, similarCases.size());
        System.assertEquals(1, similarCases[0].Attachments.size());
    }

    @isTest
    static void testDeletionWithLogging_severalAttachments_testMode () {
        System.assert(
            processDeletionRequests_severalAttachments(true),
            'Records deletion failed'
        );
    }

    private static Boolean processDeletionRequests_severalAttachments(Boolean isTestMode) {
        Test.startTest();
        List<GDPRHelper> allRequests = GDPRHelper.getRequestsQueue(isTestMode);
        GDPRHelper contactDeletionRequest = allRequests[1];
        Integer csvLogLimit = contactDeletionRequest.csvLogLimit;

        Id rtId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(GDPRHelper.SFDC_DATA_DELETION).getRecordTypeId();
        List<Case> similarCases = [SELECT Id, (Select Id FROM Attachments) FROM Case WHERE RecordTypeId =:rtId];
        System.assertEquals(0, similarCases.size());

        List<sObject> initialConts = contactDeletionRequest.getRecords();
        System.assertEquals(10, initialConts.size());

        Integer processRecordsRunTimes = initialConts.size()/csvLogLimit
                                + ((initialConts.size() - (initialConts.size()/csvLogLimit)*csvLogLimit) > 0
                                    ? 1
                                    : 0);

        List<List<Contact>> listsOfContactsToProcess = (List<List<Contact>>) ListHelper.splitSObjectList(initialConts, csvLogLimit);

        for(List<Contact> contList : listsOfContactsToProcess) {
            contactDeletionRequest.processRequest(contList);
            contactDeletionRequest.logAsCsv(false);
        }

        List<Contact> contsAfterBatch = [SELECT Id FROM Contact];
        System.assertEquals((isTestMode ? 10 : 0), contsAfterBatch.size());

        similarCases = [SELECT Id, (Select Id FROM Attachments) FROM Case WHERE RecordTypeId =:rtId];
        System.assertEquals(1, similarCases.size());
        System.assertEquals(
            processRecordsRunTimes,
            similarCases[0].Attachments.size(),
            'Not all attachments for processed records were created'
        );
        Test.stopTest();

        return true;
    }

    @isTest
    static void testCaseCreatedWithoutAttachmentsIfNoRecordsDeleted () {
        List<SObject> reqsToDelete = [SELECT Id FROM GDPR_Requests__c WHERE Name != 'Contact'];
        delete reqsToDelete;

        List<GDPRHelper> allRequests = GDPRHelper.getRequestsQueue(true);
        GDPRHelper contactDeletionRequest = allRequests[0];

        List<Contact> conts = [SELECT Id FROM Contact];
        System.assertEquals(10, conts.size());

        delete conts;

        conts = [SELECT Id FROM Contact];
        System.assertEquals(0, conts.size());

        List<sObject> objs = contactDeletionRequest.getRecords();
        System.assertEquals(0, objs.size());

        contactDeletionRequest.processRequest(objs);
        System.assertEquals(0, contactDeletionRequest.recordsToExport.size());

        contactDeletionRequest.logAsCsv(true);

        Id rtId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(GDPRHelper.SFDC_DATA_DELETION).getRecordTypeId();
        List<Case> similarCases = [SELECT Id, (Select Id FROM Attachments) FROM Case WHERE RecordTypeId =:rtId];
        System.assertEquals(1, similarCases.size());
        System.assertEquals(1, similarCases[0].Attachments.size(), 'One empty attachment should be created');
    }

    @isTest
    static void testForStatics() {
        List<GDPRHelper> allRequests = GDPRHelper.getRequestsQueue(false);
        System.assertEquals(3, allRequests.size());

        System.assertEquals('User', allRequests[0].sObjectName);
        System.assertEquals(10, allRequests[0].priority);
        System.assertEquals(true, allRequests[0].isUserDeactivation);
        System.assertEquals(60, allRequests[0].retentionPeriod);
        System.assertEquals(
            GDPRHelper.objectToWhereClauseMap
                .get('User')
                .replace(GDPRHelper.RETENTION_PLACEHOLDER, String.valueOf(60)),
            allRequests[0].whereClause
        );

        System.assertEquals('Contact', allRequests[1].sObjectName);
        System.assertEquals(10, allRequests[1].priority);
        System.assertEquals(60, allRequests[1].retentionPeriod);
        System.assertEquals(
            GDPRHelper.objectToWhereClauseMap
                .get('Contact')
                .replace(GDPRHelper.RETENTION_PLACEHOLDER, String.valueOf(60)),
            allRequests[1].whereClause
        );

        System.assertEquals('Account', allRequests[2].sObjectName);
        System.assertEquals(100, allRequests[2].priority);
        System.assertEquals(120, allRequests[2].retentionPeriod);
        System.assertEquals(
            GDPRHelper.objectToWhereClauseMap
                .get('Account')
                .replace(GDPRHelper.RETENTION_PLACEHOLDER, String.valueOf(120)),
            allRequests[2].whereClause
        );

        List<Account> accs = [SELECT Id, Name FROM Account];
        System.assertEquals(10, accs.size());

        Contact c = new Contact();
        Database.SaveResult saveRes = Database.update(c, false);
        PlatformLog__c log = GDPRHelper.getResultLog('Test', c.Id, saveRes.getErrors());
        System.assertNotEquals(null, log);
    }

    @isTest
    static void testMisc () {
        GDPRHelper gdpr = new GDPRHelper('Account', null, 1, null, null, null, null);
        System.assertEquals(3, gdpr.fieldsToLog.size());
        System.assert(gdpr.fieldsToLog.contains('Id'));
        System.assert(gdpr.fieldsToLog.contains('Name'));
        System.assert(gdpr.fieldsToLog.contains('RC_User_ID__c'));

        Account acc = new Account(Name = 'Test', RC_User_ID__c = '123123');

        gdpr = new GDPRHelper('Contact', null, 1, null, null, null, null);
        System.assertEquals(3, gdpr.fieldsToLog.size());
        System.assert(gdpr.fieldsToLog.contains('Id'));
        System.assert(gdpr.fieldsToLog.contains('Name'));
        System.assert(gdpr.fieldsToLog.contains('Email'));

        gdpr = new GDPRHelper('Lead', null, 1, null, null, null, null);
        System.assertEquals(4, gdpr.fieldsToLog.size());
        System.assert(gdpr.fieldsToLog.contains('Id'));
        System.assert(gdpr.fieldsToLog.contains('Name'));
        System.assert(gdpr.fieldsToLog.contains('Email'));
        System.assert(gdpr.fieldsToLog.contains('Company'));

        gdpr = new GDPRHelper('Opportunity', null, 1, null, null, null, null);
        System.assertEquals(3, gdpr.fieldsToLog.size());
        System.assert(gdpr.fieldsToLog.contains('Id'));
        System.assert(gdpr.fieldsToLog.contains('AccountId'));
        System.assert(gdpr.fieldsToLog.contains('Account.Name'));

        gdpr = new GDPRHelper('User', null, 1, null, null, null, null);
        System.assertEquals(3, gdpr.fieldsToLog.size());
        System.assert(gdpr.fieldsToLog.contains('Id'));
        System.assert(gdpr.fieldsToLog.contains('Name'));
        System.assert(gdpr.fieldsToLog.contains('Email'));

        GDPR_Requests__c req = new GDPR_Requests__c(
            Name = 'Contact', Object_name__c = 'Contact', Priority__c = 100,
            RetentionPeriod__c = 120,
            FieldsToScramble1__c = 'FirstName;LastName;Email;',
            FieldsToScramble2__c = 'Phone;MailingStreet;NoSuchField__c;'
        );

        gdpr = new GDPRHelper(req, false);
        System.assert(!gdpr.isValid(), 'Settings is not valid as NoSuchField__c does not exist');
        PlatformLog__c recentLog = PlatformLog.getMostRecent();
        System.assertEquals('GDPRHelper.isValid', recentLog.Source__c);
        System.assert(recentLog.Error__c.contains('Invalid field type NoSuchField__c for sObject type'));
        delete recentLog;

        req.FieldsToScramble2__c = 'Phone;MailingStreet;';
        gdpr = new GDPRHelper(req, false);
        System.assert(!gdpr.isValid(), 'Settings is not valid as Scrambled__c does not exist');
        recentLog = PlatformLog.getMostRecent();
        System.assertEquals('GDPRHelper.isValid', recentLog.Source__c);
        System.assert(
            recentLog.Error__c.contains('Scrambled__c field do not exist on the sObject type Contact'),
            recentLog.Error__c
        );
    }

    @isTest
    static void testPostfixUsageForGettingQuery_postfixPopulated() {
        GDPR_Requests__c req = new GDPR_Requests__c(
            Name = 'TestObject', Object_name__c = 'TestObject', Object_Key_Postfix__c = 'TestPostfix'
        );

        GDPRHelper gh;

        Test.startTest();
            gh = new GDPRHelper(req, false);
        Test.stopTest();

        System.assertEquals(
            'TestObject.TestPostfix',
            gh.sObjectName + gh.objKeyPostfix,
            'Map key generated not correctly'
        );
    }

    @isTest
    static void testPostfixUsageForGettingQuery_postfixNotPopulated() {
        GDPR_Requests__c req = new GDPR_Requests__c(
            Name = 'TestObject', Object_name__c = 'TestObject', Object_Key_Postfix__c = ''
        );

        GDPRHelper gh;

        Test.startTest();
            gh = new GDPRHelper(req, false);
        Test.stopTest();

        System.assertEquals('TestObject', gh.sObjectName, 'Map key generated not correctly');
    }

    @isTest
    static void testRcArticleRatingScrambling_RCCreatedByName() {
        User testUser = (User) new SObjectBuilder(User.SObjectType)
            .setField(User.DeactivationDate__c, Date.today().addMonths(-121))
            .setField(User.isActive, false)
            .create()
            .getRecord();

        RC_Article_Rating__c rating = (RC_Article_Rating__c) new SObjectBuilder(RC_Article_Rating__c.SObjectType)
            .setField(RC_Article_Rating__c.RCCreatedByName__c, 'TEST')
            .setField(RC_Article_Rating__c.RCCreatedBy__c, testUser.Id)
            .create()
            .getRecord();

        new SObjectBuilder(GDPR_Requests__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    GDPR_Requests__c.Name => 'TestReq',
                    GDPR_Requests__c.Object_name__c => 'RC_Article_Rating__c',
                    GDPR_Requests__c.Object_Key_Postfix__c => 'CreatedBy',
                    GDPR_Requests__c.Priority__c => 10,
                    GDPR_Requests__c.RetentionPeriod__c => 120,
                    GDPR_Requests__c.FieldsToScramble1__c => 'RCCreatedByName__c'
                }
            )
            .create();

        Test.startTest();
            BatchJob_DeleteMainData batch = new BatchJob_DeleteMainData(GDPRHelper.getRequestsQueue(false));
            Database.executeBatch(batch, batch.getScope());
        Test.stopTest();

        RC_Article_Rating__c ratingScrambled = [
            SELECT RCCreatedByName__c
            FROM RC_Article_Rating__c
            WHERE Id = :rating.Id
        ];
        System.assert(
            'scrambled'.equalsIgnoreCase(ratingScrambled.RCCreatedByName__c),
            'RCCreatedByName__c field wasn\'t scrambled'
        );
    }

    @isTest
    static void testRcArticleRatingScrambling_RCLastModifiedByName() {
        User testUser = (User) new SObjectBuilder(User.SObjectType)
            .setField(User.DeactivationDate__c, Date.today().addMonths(-121))
            .setField(User.isActive, false)
            .create()
            .getRecord();

        RC_Article_Rating__c rating = (RC_Article_Rating__c) new SObjectBuilder(RC_Article_Rating__c.SObjectType)
            .setField(RC_Article_Rating__c.RCLastModifiedByName__c, 'TEST')
            .setField(RC_Article_Rating__c.RCLastModifiedBy__c, testUser.Id)
            .create()
            .getRecord();

        new SObjectBuilder(GDPR_Requests__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    GDPR_Requests__c.Name => 'TestReq',
                    GDPR_Requests__c.Object_name__c => 'RC_Article_Rating__c',
                    GDPR_Requests__c.Priority__c => 10,
                    GDPR_Requests__c.RetentionPeriod__c => 120,
                    GDPR_Requests__c.FieldsToScramble1__c => 'RCLastModifiedByName__c'
                }
            )
            .create();

        Test.startTest();
            BatchJob_DeleteMainData batch = new BatchJob_DeleteMainData(GDPRHelper.getRequestsQueue(false));
            Database.executeBatch(batch, batch.getScope());
        Test.stopTest();

        RC_Article_Rating__c ratingScrambled = [
            SELECT RCLastModifiedByName__c
            FROM RC_Article_Rating__c
            WHERE Id = :rating.Id
        ];
        System.assert(
            'scrambled'.equalsIgnoreCase(ratingScrambled.RCLastModifiedByName__c),
            'RCLastModifiedByName__c field wasn\'t scrambled'
        );
    }

    static User createPortalUser(Contact c) {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Customer Portal User'];

        Map<SObjectField, Object> userFields = new Map<SObjectField, Object> {
            User.ContactId => c.Id,
            User.Alias => 'standt',
            User.Email => 'standarduser@testorg.com',
            User.EmailEncodingKey => 'UTF-8',
            User.LastName => 'Testing',
            User.LanguageLocaleKey => 'en_US',
            User.LocaleSidKey => 'en_US',
            User.ProfileId => p.Id,
            User.TimeZoneSidKey => 'America/Los_Angeles',
            User.UserName => 'standarduser@testorg.com'
        };
        return (User)new SObjectBuilder(User.SObjectType)
                        .setFields(userFields)
                        .build()
                        .getRecord();
    }
}