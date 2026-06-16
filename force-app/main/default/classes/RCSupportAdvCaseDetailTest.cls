/**
 * This class contains unit tests for validating the behavior of Apex classe 'RCSupportAdvCaseDetail'
*/
@isTest
private class RCSupportAdvCaseDetailTest {
    static private final String CASE_OWNER_NAME = 'CaseOwner';

    @testSetup
    static void createCaseOwner() {
        Account accountOfCaseOwner = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'Test account'
                }
            )
            .create()
            .getRecord();
        Contact contactOfCaseOwner = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => accountOfCaseOwner.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();
        User us = (User) new SObjectBuilder (User.SObjectType)        
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'Test_' + CASE_OWNER_NAME,
                    User.Username => CASE_OWNER_NAME + '_!user@gmail.com',
                    User.Email => CASE_OWNER_NAME + '_user@gmail.com',
                    User.Alias => 'Test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id FROM Profile WHERE Name = 'RC Guest User' LIMIT 1].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep',
                    User.ContactId => contactOfCaseOwner.Id,
                    User.CommunityNickname => 'test123'
                }
            )    
            .create()
            .getRecord();
        
        Triggers.switchOff();
        Case caseObj = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Case.Subject => 'Test1',
                    Case.status => 'Open',
                    Case.AccountId => accountOfCaseOwner.Id,
                    Case.ContactId => contactOfCaseOwner.Id,
                    Case.Priority => 'P3',
                    Case.Description => 'Test Description'
                }
            )
            .create()
            .getRecord();
        Triggers.switchOn();
      
    }

    static User getCaseOwner() {
        return [SELECT ContactId, Contact.AccountId FROM User WHERE Username LIKE :CASE_OWNER_NAME + '%' LIMIT 1];
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testCreateCase() {
        try {
            EntitlementEnable__c mycs = EntitlementEnable__c.getValues('IsEntitlementsEnabled__c');
            if(mycs == null) {
                mycs = new EntitlementEnable__c();
                mycs.IsEntitlementsEnabled__c = true;
                mycs.Name = 'IsEntitlementsEnabled';
                insert mycs;
            }
            EntitlementHelper.IsEntitlementsEnabled();
            Schema.DescribeSObjectResult result = Account.SObjectType.getDescribe();
            Map<string,Schema.RecordTypeInfo> rtMapByName = result.getRecordTypeInfosByName();

            User caseOwner = getCaseOwner();
            Entitlement ent = createEntitlement(caseOwner.Contact.AccountId, 'Support - Basic');
            Case caseObj = createTestCase(caseOwner, null, ent.Id, 'Level 2 - Urgent');

            Test.startTest();
            TriggerHandler.BY_PASS_CASE_ON_INSERT();
            TriggerHandler.BY_PASS_CASE_ON_UPDATE();

            CaseComment casecommentObj1 = new CaseComment();
            casecommentObj1.CommentBody = 'Test';
            casecommentObj1.ParentId = caseObj.id;
            casecommentObj1.IsPublished = true;
            insert casecommentObj1;

            CaseComment casecommentObj2 = new CaseComment();
            casecommentObj2.CommentBody = 'Test1';
            casecommentObj2.ParentId = caseObj.id;
            casecommentObj2.IsPublished = true;
            insert casecommentObj2;

            Attachment attachObj = new  Attachment();
            attachObj.ParentId = caseObj.id;
            attachObj.Name = 'testAttachment';
            attachObj.body = Blob.valueOf('dkjghdksgjdshgdkh');
            insert attachObj;

            Attachment attachObj1 = new  Attachment();
            attachObj1.Name = 'testAttachment';
            attachObj1.body = Blob.valueOf('dkjghdksgjdshgdkh');

            RCSupportAdvCaseDetail createcaseObj1 = initiateController(caseOwner, caseObj);
            createcaseObj1.addCaseCommentSC();
            createcaseObj1.commentDesc = 'New Comment';
            createcaseObj1.addCaseComment();
            createcaseObj1.sentToClone();
            createcaseObj1.attachFileSC();
            createcaseObj1.attachment = attachObj1;
            createcaseObj1.attachFile();
            createcaseObj1.deleteAttachment();
            createcaseObj1.deleteAttachId = attachObj.id;
            createcaseObj1.deleteAttachment();

            Test.stopTest();
        } catch(Exception ex) {}
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testCreateCase1() {
        try {
            EntitlementEnable__c mycs = EntitlementEnable__c.getValues('IsEntitlementsEnabled__c');
            if(mycs == null) {
            mycs = new EntitlementEnable__c();
            mycs.IsEntitlementsEnabled__c = true;
            mycs.Name = 'IsEntitlementsEnabled';
            insert mycs;
            }
            EntitlementHelper.IsEntitlementsEnabled();
            Schema.DescribeSObjectResult result = Account.SObjectType.getDescribe();
            Map<string,Schema.RecordTypeInfo> rtMapByName = result.getRecordTypeInfosByName();

            User caseOwner = getCaseOwner();

            Entitlement ent = createEntitlement(caseOwner.Contact.AccountId, 'Support - Basic');
            Case caseObj2 = createTestCase(caseOwner, null, ent.Id, 'Level 3 - High');

            Test.startTest();

            RCSupportAdvCaseDetail createcaseObj2 = initiateController(caseOwner, caseObj2);

            Test.stopTest();
        } catch(Exception ex) {}
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testCreateCase2() {
        try {
            EntitlementEnable__c mycs = EntitlementEnable__c.getValues('IsEntitlementsEnabled__c');
            if(mycs == null) {
                mycs = new EntitlementEnable__c();
                mycs.IsEntitlementsEnabled__c = true;
                mycs.Name = 'IsEntitlementsEnabled';
                insert mycs;
            }
            EntitlementHelper.IsEntitlementsEnabled();
            Schema.DescribeSObjectResult result = Account.SObjectType.getDescribe();
            Map<string,Schema.RecordTypeInfo> rtMapByName = result.getRecordTypeInfosByName();

            User caseOwner = getCaseOwner();
            Entitlement ent = createEntitlement(caseOwner.Contact.AccountId, 'Support - Basic');
            Test.startTest();
            Case caseObj1 = createTestCase(caseOwner, null, ent.Id, 'Level 4 - Medium');
            RCSupportAdvCaseDetail createcaseObj2 = initiateController(caseOwner, caseObj1);

            Test.stopTest();
        } catch(Exception ex) {
            system.debug('@@@@@@@'+ex.getMessage());
        }
        
    }

    private static Entitlement createEntitlement(Id accountId, String businessHoursName) {
        BusinessHours businessObj = [
            SELECT WednesdayStartTime, WednesdayEndTime, TuesdayStartTime, TuesdayEndTime,
                ThursdayStartTime, ThursdayEndTime, SundayStartTime,  SundayEndTime,
                SaturdayStartTime, SaturdayEndTime, Name, MondayStartTime,  MondayEndTime,
                FridayStartTime, FridayEndTime
            FROM BusinessHours
            WHERE  Name = :businessHoursName];


        Entitlement entlt = new Entitlement();
        entlt.AccountId = accountId;
        entlt.Name = 'Test Entitlement';
        entlt.BusinessHoursId = businessObj.Id;
        insert entlt;

        return entlt;
    }

    private static Case createTestCase(User owner, Id recordTypeId, Id entitlementId, string severity) {
        Case caseObj = new Case();
        caseObj.AccountId = owner.Contact.AccountId;
        caseObj.ContactId = owner.ContactId;
        caseObj.Subject = 'Test Case';
        caseObj.Description = 'Test Case Desc1';
        if (recordTypeId != null) {
            caseObj.RecordTypeId = recordTypeId;
        }
        if (entitlementId != null) {
            caseObj.EntitlementId = entitlementId;
        }
        if (String.IsNotBlank(severity)) {
            caseObj.Case_Severity__c = severity;
        }

        insert caseObj;

        return caseObj;
    }

    private static Case getCaseWithEntitlements(String caseSeverity, String businessHoursName) {
        User caseOwner = getCaseOwner();
        Entitlement entl = createEntitlement(caseOwner.Contact.AccountId, businessHoursName);
        return createTestCase(caseOwner, null, entl.Id, caseSeverity);
    }

    private static RcSupportAdvCaseDetail initiateController(User caseOwner, Case caseObj) {
        Test.setCurrentPage(Page.RcSupportAdvCaseDetail);
        ApexPages.currentPage().getParameters().put('Id', caseObj.Id);
        RcSupportAdvCaseDetail result = null;
        System.runAs(caseOwner) {
            result = new RcSupportAdvCaseDetail(new ApexPages.StandardController(caseObj));
            result.getCaseDetail();
        }
        return result;
    }

    private static String getControllerStrTimeMessageProperty(User caseOwner, Case caseObj) {
        RcSupportAdvCaseDetail ctrl = initiateController(caseOwner, caseObj);
        return ctrl.strTimeMessage;
    }

    @isTest
    static void testGetCaseDetail_Negative_OtherOwner() {
        User caseOwner = getCaseOwner();
        Account account = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.AccountId => account.Id,
                Contact.Email => 'test@test.com',
                Contact.LastName => 'Test1',
                Contact.FirstName => 'Test1',
                Contact.Phone => '1234567890',
                Contact.Preferred_Language__c => 'en_US'
            })
            .create()
            .getRecord();

        User portalUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(User.SObjectType))
            .setField(User.ContactId, contact.Id)
            .setField(User.ProfileId, ProfileHelper.PROFILE_ID_CUSTOMER_PORTAL_USER)
            .create()
            .getRecord();
        Test.startTest();
        Case caseObj = createTestCase(caseOwner, null, null, null);
        Test.stopTest();

        RCSupportAdvCaseDetail ctrl = initiateController(portalUser, caseObj);
        System.assertNotEquals(
            ctrl.caseDetailObj.Id,
            caseObj.Id,
            'Due sharing rules, ctrl.caseDetailObj must be empty case'
        );
    }

    @isTest
    static void testSlaMessages_Basic_Support() {
        Case caseUrgent = getCaseWithEntitlements('Level 2 - Urgent', 'Support - Basic');
        Case caseHigh = getCaseWithEntitlements('Level 3 - High', 'Support - Basic');
        Case caseMedium = getCaseWithEntitlements('Level 4 - Medium', 'Support - Basic');

        //

        Test.startTest();

        String result = getControllerStrTimeMessageProperty(getCaseOwner(), caseUrgent);

         if ('Your case has been submitted. You will receive a response within 1 hour.'
            .equalsIgnoreCase(result) == false) {
            if ('Your case has been submitted. You will receive a response on the next business day.'
                .equalsIgnoreCase(result) == false) {
                System.assert(true == false, 'SLA message not correct for Urgent severity');
            }
        }

        //

        result = getControllerStrTimeMessageProperty(getCaseOwner(), caseHigh);

        if ('Your case has been submitted. You will receive a response within 4 hours.'
            .equalsIgnoreCase(result) == false) {
            if ('Your case has been submitted. You will receive a response on the next business day.'
                .equalsIgnoreCase(result) == false) {
                System.assert(true == false, 'SLA message not correct for High severity');
            }
        }

        //

        result = getControllerStrTimeMessageProperty(getCaseOwner(), caseMedium);

        if ('Your case has been submitted. You will receive a response within 8 hours.'
            .equalsIgnoreCase(result) == false) {
            if ('Your case has been submitted. You will receive a response on the next business day.'
                .equalsIgnoreCase(result) == false) {
                System.assert(true == false, 'SLA message not correct for Medium severity');
            }
        }

        Test.stopTest();
    }

    @isTest
    static void testSlaMessage_OfficePremium() {
        Case caseObj = getCaseWithEntitlements('Level 2 - Urgent', 'Support - Office Premium');
        String result = getControllerStrTimeMessageProperty(getCaseOwner(), caseObj);
        System.assertEquals('You will receive a response within 1 hour.', result,
            'SLA message not correct for Office Premium support level');
    }

    @isTest
    static void testSlaMessage_OfficeStandard() {
        Case caseObj = getCaseWithEntitlements('Level 3 - High', 'Support Office Standard');
        String result = getControllerStrTimeMessageProperty(getCaseOwner(), caseObj);
        System.assertEquals('You will receive a response within 1 hour.', result,
            'SLA message not correct for Office Standard support level');
    }
    @isTest
    static void testTriggerOnUpdate() {  
        Case caseObj = [SELECT Id FROM Case LIMIT 1];
        
        Triggers.switchOff();

        CaseComment casecommentObj = new CaseComment();
        casecommentObj.CommentBody = 'Test';
        casecommentObj.ParentId = caseObj.id;
        casecommentObj.IsPublished = true;
        insert casecommentObj;

        Triggers.switchOn();
            
        Partner_Communication__c partnerComm = new Partner_Communication__c();
        partnerComm.Vendor_CommentBody__c = 'Updated Comment from Trigger';
        partnerComm.Case_Comment_ID__c = casecommentObj.Id;
        insert partnerComm;

        partnerComm.Vendor_CommentBody__c = 'Updated Comment from Trigger 2';
        TriggerHandler.BY_PASS_PARTNERCOMM_ON_UPDATE = false;
        TriggerHandler.BY_PASS_PARTNERCOMM_ON_INSERT = false;
        update partnerComm;
        
        TriggerHandler.BY_PASS_PARTNERCOMM_ON_UPDATE = false;
        TriggerHandler.BY_PASS_PARTNERCOMM_ON_INSERT = false;
        
        partnerComm.ConnectionIdOfPartner__c = new List<Id>(S2SConnectionHelperCls.getConnectionId('TELUS'))[0];
        partnerComm.Case_Id__c = caseObj.Id;
        partnerComm.Case_Comment_ID__c = '';

        update partnerComm;
        System.assert(partnerComm.Vendor_CommentBody__c == 'Updated Comment from Trigger 2');
    }
}