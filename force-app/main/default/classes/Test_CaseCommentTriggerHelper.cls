@isTest
private class Test_CaseCommentTriggerHelper {

    @isTest
    private static void testCompleteFollowUpSupportIntegrationMilestoneBase() {

        CaseCommentTriggerHelper.CompleteFollowUpSupportIntegrationMilestone handlerInstance = new CaseCommentTriggerHelper.CompleteFollowUpSupportIntegrationMilestone();

        System.assertEquals(
            new Set<Id>(),
            handlerInstance.findCaseIdsToCompleteFollowUpMilestone(null),
            'method findCaseIdsToCompleteFollowUpMilestone should return empty set if passed arg is NULL'
        );

        System.assertEquals(
            new Set<Id>(),
            handlerInstance.findCaseIdsToCompleteFollowUpMilestone(new Set<Id>()),
            'method findCaseIdsToCompleteFollowUpMilestone should return empty set if passed arg is empty set'
        );
    }

    @isTest
    private static void testCompleteFollowUpSupportIntegrationMilestoneWithTestData() {

        SObjectFactory factory = new SObjectFactory();

        List<Account> accountRecords = (List<Account>) factory
            .create(
                Account.SObjectType,
                1,
                new Map<SObjectField, Object>{
                    Account.Name => ValueProviderBuilder.provideUniqueString('TestAccountName_')
                }
            );

        List<Contact> contactRecords = (List<Contact>) factory
            .create(
                Contact.SObjectType,
                1,
                new Map<SObjectField, Object>{
                    Contact.AccountId => ValueProviderBuilder.provideParents(accountRecords)
                }
            );

        List<Case> caseRecords = (List<Case>) factory
            .build(
                Case.SObjectType,
                2,
                new Map<SObjectField, Object>{
                    Case.AccountId => ValueProviderBuilder.provideParents(accountRecords),
                    Case.ContactId => ValueProviderBuilder.provideParents(contactRecords),
                    Case.RecordTypeId => CaseHelper.RT_ID_SUPPORT_INTEGRATIONS,
                    Case.Subject => ValueProviderBuilder.provideUniqueString('TestSubject_'),
                    Case.Description => ValueProviderBuilder.provideUniqueString('TestDescription_')
                }
            );

        // mark first Case as 'Closed'
        caseRecords.get(0).Status = CaseHelper.CASE_STATUS_CLOSED;
        insert caseRecords;

        Set<Id> casesIdSet = new Set<Id>();
        for(Case c : caseRecords) {
            casesIdSet.add(c.Id);
        }

        List<CaseComment> caseCommentsRecords = (List<CaseComment>) factory
            .create(
                CaseComment.SObjectType,
                2,
                new Map<SObjectField, Object>{
                    CaseComment.ParentId => ValueProviderBuilder.provideParents(caseRecords),
                    CaseComment.CommentBody => ValueProviderBuilder.provideUniqueString('TestCommentBody_')
                }
            );

        CaseCommentTriggerHelper.CompleteFollowUpSupportIntegrationMilestone handlerInstance = new CaseCommentTriggerHelper.CompleteFollowUpSupportIntegrationMilestone();

        System.assertEquals(
            1,
            handlerInstance.findCaseIdsToCompleteFollowUpMilestone(casesIdSet).size(),
            'method findCaseIdsToCompleteFollowUpMilestone should return set of case Ids with Status != "Closed"'
        );
    }


    @isTest
    private static void testCompleteFirstResponseMilestoneBase() {

        CaseCommentTriggerHelper.CompleteFirstResponseMilestoneHandler handlerInstance = new CaseCommentTriggerHelper.CompleteFirstResponseMilestoneHandler();

        System.assertEquals(
            new Set<Id>(),
            handlerInstance.findCaseIdsToCompleteFirstResponseMilestone(null),
            'method findCaseIdsToCompleteFollowUpMilestone should return empty set if passed arg is NULL'
        );

        System.assertEquals(
            new Set<Id>(),
            handlerInstance.findCaseIdsToCompleteFirstResponseMilestone(new Set<Id>()),
            'method findCaseIdsToCompleteFollowUpMilestone should return empty set if passed arg is empty set'
        );
    }

    @isTest
    private static void testCompleteFirstResponseMilestoneWithTestData() {

        insert new EntitlementEnable__c(
            Name = 'IsEntitlementsEnabled',
            IsEntitlementsEnabled__c = true
        );


        SObjectFactory factory = new SObjectFactory();

        Account accountRecord = (Account) factory.create(Account.SObjectType);

        List<Contact> contactRecords = (List<Contact>) factory
            .create(
                Contact.SObjectType,
                1,
                new Map<SObjectField, Object>{
                    Contact.AccountId => ValueProviderBuilder.provideParents(new List<Account>{accountRecord})
                }
            );

        List<User> portalUserRecords = (List<User>) factory
            .create(
                User.SObjectType,
                1,
                new Map<SObjectField, Object>{
                    User.ProfileId => ProfileHelper.PROFILE_ID_CUSTOMER_PORTAL_USER,
                    User.ContactId => ValueProviderBuilder.provideParents(contactRecords),
                    User.Username => 'portal!user@gmail.com',
                    User.LastName => ValueProviderBuilder.provideUniqueString('testPortalUser_'),
                    User.Email => 'portal!user@gmail.com',
                    User.Alias => ValueProviderBuilder.provideUniqueFixedLengthString(7),
                    User.CommunityNickname => ValueProviderBuilder.provideUniqueString('testPortalUser_'),
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.LanguageLocaleKey => 'en_US'
                }
            );

        List<Entitlement> entitlementRecords = (List<Entitlement>) factory
            .create(
                Entitlement.SObjectType,
                2,
                new Map<SObjectField, Object>{
                    Entitlement.AccountId => ValueProviderBuilder.provideParents(new List<Account>{accountRecord}),
                    Entitlement.Name => ValueProviderBuilder.provideUniqueString('TestEntitlementName_')
                }
            );

        List<Case> caseRecords = (List<Case>) factory
            .build(
                Case.SObjectType,
                2,
                new Map<SObjectField, Object>{
                    Case.AccountId => ValueProviderBuilder.provideParents(new List<Account>{accountRecord}),
                    Case.ContactId => ValueProviderBuilder.provideParents(contactRecords),
                    Case.EntitlementId => ValueProviderBuilder.provideParents(entitlementRecords),
                    Case.RecordTypeId => CaseHelper.RT_ID_SUPPORT_CASE,
                    Case.SlaStartDate => System.now(),
                    Case.Subject => ValueProviderBuilder.provideUniqueString('TestSubject_'),
                    Case.Description => ValueProviderBuilder.provideUniqueString('TestDescription_')
                }
            );

        // mark first Case as 'Closed'
        caseRecords.get(0).Status = CaseHelper.CASE_STATUS_CLOSED;
        insert caseRecords;

        Set<Id> casesIdSet = new Set<Id>();
        for(Case c : caseRecords) {
            casesIdSet.add(c.Id);
        }

        Test.startTest();

        CaseCommentTriggerHelper.CompleteFirstResponseMilestoneHandler handlerInstance = new CaseCommentTriggerHelper.CompleteFirstResponseMilestoneHandler();

        System.assertEquals(
            1,
            handlerInstance.findCaseIdsToCompleteFirstResponseMilestone(casesIdSet).size(),
            'method findCaseIdsToCompleteFirstResponseMilestone should return set of case Ids with Status != "Closed"'
        );

        List<CaseComment> caseCommentsRecords = new SObjectBuilder(CaseComment.SObjectType)
            .quantity(2)
            .setFields(
                new Map<SObjectField, Object>{
                    CaseComment.IsPublished => true,
                    CaseComment.ParentId => ValueProviderBuilder.provideParents(caseRecords),
                    CaseComment.CommentBody => ValueProviderBuilder.provideUniqueString('TestCommentBody_')
                }
            )
            .createAsUser(portalUserRecords.get(0))
            .getRecords();

        Test.stopTest();
    }

    @isTest
    private static void testCaseCommentCountWitTestDataOnInsert() {

        SObjectFactory factory = new SObjectFactory();

        Account accountRecord = (Account) factory.create(Account.SObjectType);

        List<Contact> contactRecords = (List<Contact>) factory
            .create(
                Contact.SObjectType,
                1,
                new Map<SObjectField, Object>{
                    Contact.AccountId => ValueProviderBuilder.provideParents(new List<Account>{accountRecord})
                }
            );

        List<Case> caseRecords = (List<Case>) factory
            .create(
                Case.SObjectType,
                2,
                new Map<SObjectField, Object>{
                    Case.AccountId => ValueProviderBuilder.provideParents(new List<Account>{accountRecord}),
                    Case.ContactId => ValueProviderBuilder.provideParents(contactRecords),
                    Case.Subject => ValueProviderBuilder.provideUniqueString('TestSubject_'),
                    Case.Description => ValueProviderBuilder.provideUniqueString('TestDescription_')
                }
            );

        Set<Id> casesIdSet = new Set<Id>();
        for(Case caseObj : caseRecords) {
            casesIdSet.add(caseObj.Id);
        }

        List<CaseComment> publishedCaseCommentsRecords = (List<CaseComment>) factory
            .build(
                CaseComment.SObjectType,
                2,
                new Map<SObjectField, Object>{
                    CaseComment.ParentId => ValueProviderBuilder.provideParents(caseRecords),
                    CaseComment.IsPublished => true,
                    CaseComment.CommentBody => ValueProviderBuilder.provideUniqueString('TestCommentBody_')
                }
            );

        List<CaseComment> notPublishedCaseCommentsRecords = (List<CaseComment>) factory
            .build(
                CaseComment.SObjectType,
                2,
                new Map<SObjectField, Object>{
                    CaseComment.ParentId => ValueProviderBuilder.provideParents(caseRecords),
                    CaseComment.IsPublished => false,
                    CaseComment.CommentBody => ValueProviderBuilder.provideUniqueString('TestCommentBody_')
                }
            );

        List<CaseComment> caseCommentsToInsertList = new List<CaseComment>(publishedCaseCommentsRecords);
        caseCommentsToInsertList.addAll(notPublishedCaseCommentsRecords);

        List<User> userRecords = (List<User>) factory
            .create(
                User.SObjectType,
                1,
                new Map<SObjectField, Object>{
                    User.ProfileId => ProfileHelper.PROFILE_ID_SYSADMIN,
                    User.Username => 'tstuser@ringcentral.com',
                    User.LastName => ValueProviderBuilder.provideUniqueString('testRCUser_'),
                    User.Email => 'tstuser@ringcentral.com',
                    User.Alias => ValueProviderBuilder.provideUniqueFixedLengthString(7),
                    User.CommunityNickname => ValueProviderBuilder.provideUniqueString('testRCUser_'),
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.LanguageLocaleKey => 'en_US'
                }
            );

        User rcAgentUser = userRecords.get(0);

        Test.startTest();

        System.runAs(rcAgentUser) {
            // we create 4 CaseComment records(2 for each Case): 2 IsPublished comments and 2 Not published
            // so for each Case record it would be 1 "PrivateComment" and 1 "public comment", and both CaseComments created by RingCentral Agent
            insert caseCommentsToInsertList;
        }

        List<Case> reselectedCasesList = [SELECT Id, Created_by_Agent__c, No_of_Private_Comments__c, No_of_Public_Comments__c, Created_by_customer__c FROM Case WHERE Id IN :casesIdSet];

        for(Case caseObj : reselectedCasesList) {
            System.assertEquals(2, caseObj.Created_by_Agent__c, 'value in Created_by_Agent__c should be 2');
            System.assertEquals(1, caseObj.No_Of_Private_Comments__c, 'value in No_Of_Private_Comments__c should be 1');
            System.assertEquals(1, caseObj.No_of_Public_Comments__c, 'value in No_of_Public_Comments__c should be 1');
            System.assertEquals(0, caseObj.Created_by_customer__c, 'value in Created_by_customer__c should be 0');
        }

        Test.stopTest();
    }




    @isTest
    private static void testCaseCommentCountWitTestDataOnDelete() {

        SObjectFactory factory = new SObjectFactory();

        Account accountRecord = (Account) factory.create(Account.SObjectType);

        List<Contact> contactRecords = (List<Contact>) factory
            .create(
                Contact.SObjectType,
                1,
                new Map<SObjectField, Object>{
                    Contact.AccountId => ValueProviderBuilder.provideParents(new List<Account>{accountRecord})
                }
            );

        List<Case> caseRecords = (List<Case>) factory
            .create(
                Case.SObjectType,
                2,
                new Map<SObjectField, Object>{
                    Case.AccountId => ValueProviderBuilder.provideParents(new List<Account>{accountRecord}),
                    Case.ContactId => ValueProviderBuilder.provideParents(contactRecords),
                    Case.Subject => ValueProviderBuilder.provideUniqueString('TestSubject_'),
                    Case.Description => ValueProviderBuilder.provideUniqueString('TestDescription_')
                }
            );

        Set<Id> casesIdSet = new Set<Id>();
        for(Case caseObj : caseRecords) {
            casesIdSet.add(caseObj.Id);
        }

        List<CaseComment> publishedCaseCommentsRecords = (List<CaseComment>) factory
            .build(
                CaseComment.SObjectType,
                2,
                new Map<SObjectField, Object>{
                    CaseComment.ParentId => ValueProviderBuilder.provideParents(caseRecords),
                    CaseComment.IsPublished => true,
                    CaseComment.CommentBody => ValueProviderBuilder.provideUniqueString('TestCommentBody_')
                }
            );

        List<CaseComment> notPublishedCaseCommentsRecords = (List<CaseComment>) factory
            .build(
                CaseComment.SObjectType,
                2,
                new Map<SObjectField, Object>{
                    CaseComment.ParentId => ValueProviderBuilder.provideParents(caseRecords),
                    CaseComment.IsPublished => false,
                    CaseComment.CommentBody => ValueProviderBuilder.provideUniqueString('TestCommentBody_')
                }
            );

        List<CaseComment> caseCommentsToInsertList = new List<CaseComment>(publishedCaseCommentsRecords);
        caseCommentsToInsertList.addAll(notPublishedCaseCommentsRecords);

        List<User> userRecords = (List<User>) factory
            .create(
                User.SObjectType,
                1,
                new Map<SObjectField, Object>{
                    User.ProfileId => ProfileHelper.PROFILE_ID_SYSADMIN,
                    User.Username => 'tstuser@ringcentral.com',
                    User.LastName => ValueProviderBuilder.provideUniqueString('testRCUser_'),
                    User.Email => 'tstuser@ringcentral.com',
                    User.Alias => ValueProviderBuilder.provideUniqueFixedLengthString(7),
                    User.CommunityNickname => ValueProviderBuilder.provideUniqueString('testRCUser_'),
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.LanguageLocaleKey => 'en_US'
                }
            );

        User rcAgentUser = userRecords.get(0);

        System.runAs(rcAgentUser) {
            // we create 4 CaseComment records(2 for each Case): 2 IsPublished comments and 2 Not published
            // so for each Case record it would be 1 "PrivateComment" and 1 "public comment", and both CaseComments created by RingCentral Agent
            insert caseCommentsToInsertList;
        }

        Test.startTest();

        System.runAs(rcAgentUser) {
            delete caseCommentsToInsertList;
        }

        List<Case> reselectedCasesList = [SELECT Id, Created_by_Agent__c, No_of_Private_Comments__c, No_of_Public_Comments__c, Created_by_customer__c FROM Case WHERE Id IN :casesIdSet];

        for(Case caseObj : reselectedCasesList) {
            System.assertEquals(0, caseObj.Created_by_Agent__c, 'we remove all case comments, value in Created_by_Agent__c should be 0');
            System.assertEquals(0, caseObj.No_Of_Private_Comments__c, 'we remove all case comments, value in No_Of_Private_Comments__c should be 0');
            System.assertEquals(0, caseObj.No_of_Public_Comments__c, 'we remove all case comments, value in No_of_Public_Comments__c should be 0');
            System.assertEquals(0, caseObj.Created_by_customer__c, 'we remove all case comments, value in Created_by_customer__c should be 0');
        }

        Test.stopTest();
    }


    @isTest
    private static void testCaseCommentCountWitTestDataOnUpdate() {

        SObjectFactory factory = new SObjectFactory();

        Account accountRecord = (Account) factory.create(Account.SObjectType);

        List<Contact> contactRecords = (List<Contact>) factory
            .create(
                Contact.SObjectType,
                1,
                new Map<SObjectField, Object>{
                    Contact.AccountId => ValueProviderBuilder.provideParents(new List<Account>{accountRecord})
                }
            );

        List<Case> caseRecords = (List<Case>) factory
            .create(
                Case.SObjectType,
                1,
                new Map<SObjectField, Object>{
                    Case.AccountId => ValueProviderBuilder.provideParents(new List<Account>{accountRecord}),
                    Case.ContactId => ValueProviderBuilder.provideParents(contactRecords),
                    Case.Subject => ValueProviderBuilder.provideUniqueString('TestSubject_'),
                    Case.Description => ValueProviderBuilder.provideUniqueString('TestDescription_')
                }
            );

        Set<Id> casesIdSet = new Set<Id>();
        for(Case caseObj : caseRecords) {
            casesIdSet.add(caseObj.Id);
        }

        List<User> userRecords = (List<User>) factory
            .create(
                User.SObjectType,
                1,
                new Map<SObjectField, Object>{
                    User.ProfileId => ProfileHelper.PROFILE_ID_SYSADMIN,
                    User.Username => 'tstuser@ringcentral.com',
                    User.LastName => ValueProviderBuilder.provideUniqueString('testRCUser_'),
                    User.Email => 'tstuser@ringcentral.com',
                    User.Alias => ValueProviderBuilder.provideUniqueFixedLengthString(7),
                    User.CommunityNickname => ValueProviderBuilder.provideUniqueString('testRCUser_'),
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.LanguageLocaleKey => 'en_US'
                }
            );

        List<CaseComment> notPublishedCaseCommentsRecords = new SObjectBuilder(CaseComment.SObjectType)
            .quantity(1)
            .setFields(
                new Map<SObjectField, Object>{
                    CaseComment.ParentId => ValueProviderBuilder.provideParents(caseRecords),
                    CaseComment.IsPublished => false,
                    CaseComment.CommentBody => ValueProviderBuilder.provideUniqueString('TestCommentBody_')
                }
            )
            .createAsUser(userRecords.get(0))
            .getRecords();


        Test.startTest();

        // make all caseComment IsPublished, and verify Case.No_Of_Private_Comments__c, Case.No_of_Public_Comments__c is updated
        List<CaseComment> ccToUpdate = new List<CaseComment>();
        for(CaseComment cc : notPublishedCaseCommentsRecords) {
            cc.IsPublished = true;
            ccToUpdate.add(cc);
        }

        update ccToUpdate;

        List<Case> reselectedCasesList = [SELECT Id, Created_by_Agent__c, No_of_Private_Comments__c, No_of_Public_Comments__c, Created_by_customer__c FROM Case WHERE Id IN :casesIdSet];

        for(Case caseObj : reselectedCasesList) {
            System.assertEquals(1, caseObj.Created_by_Agent__c, 'we remove all case comments, value in Created_by_Agent__c should be 0');
            System.assertEquals(0, caseObj.No_Of_Private_Comments__c, 'we remove all case comments, value in No_Of_Private_Comments__c should be 0');
            System.assertEquals(1, caseObj.No_of_Public_Comments__c, 'we remove all case comments, value in No_of_Public_Comments__c should be 0');
            System.assertEquals(0, caseObj.Created_by_customer__c, 'we remove all case comments, value in Created_by_customer__c should be 0');
        }

        Test.stopTest();
    }
}