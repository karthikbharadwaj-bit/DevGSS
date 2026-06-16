@isTest
private class Test_ConvertLeadController {

    private final static String EMAIL = (String) ValueProviderBuilder.provideUniqueEmail().getValue();
    private final static String PHONE = '12345678';
    private final static String ALLOW_NGBS_CUSTOM_PERMISSION = 'AllowToUseNGBSForNewCustomers';
    private final static String EMAIL_OR_PHONE = 'email or phone';
    private final static String PHONE_OR_ACCOUNT = 'phone or (account';
    private final static String EMAIL_OR_ACCOUNT = 'email or (account';
    private final static Integer CURRENT_OFFSET = 5;
    private final static Integer RECORD_NUMBER = 10;

    @isTest
    private static void testGetLeadQualificationsCorrectList() {

        SObjectFactory factory = new SObjectFactory();

        Lead ld = (Lead) factory
            .create(
                Lead.SObjectType
            );

        List<Lead_Qualification__c> qualifications = (List<Lead_Qualification__c>) factory
            .create(
                Lead_Qualification__c.SObjectType,
                3,
                new Map<SObjectField, Object> {
                    Lead_Qualification__c.Lead__c => ld.Id
                }
            );

        Test.startTest();
            Response result = ConvertLeadController.getLeadQualifications(ld.Id);
            Map<Id, Lead_Qualification__c> qualificationsById = new Map<Id, Lead_Qualification__c>(
                (List<Lead_Qualification__c>) result.data.get('leadQualifications')
            );
        Test.stopTest();

        System.assertEquals(
            qualificationsById.keySet().size(),
            qualifications.size(),
            'Not all Lead Qualifications was retrieved.'
        );

        for (Lead_Qualification__c qual : qualifications) {
            System.assertNotEquals(
                qualificationsById.get(qual.Id),
                null,
                'Incorrect Lead Qualifications was retrieved.'
            );
        }

        System.assertEquals(
            (Boolean) result.data.get('hasMoreQualifications'),
            false,
            'List of Lead Qualifications should not have all records.'
        );
    }

    @isTest
    private static void testGetLeadQualificationsWithOffset() {

        SObjectFactory factory = new SObjectFactory();

        Lead ld = (Lead) factory
            .create(
                Lead.SObjectType
            );

        List<Lead_Qualification__c> qualifications = (List<Lead_Qualification__c>) factory
            .create(
                Lead_Qualification__c.SObjectType,
                RECORD_NUMBER,
                new Map<SObjectField, Object> {
                    Lead_Qualification__c.Lead__c => ld.Id
                }
            );

        Test.startTest();
            Response result = ConvertLeadController.getLeadQualifications(ld.Id, CURRENT_OFFSET, RECORD_NUMBER);
            List<Lead_Qualification__c> testQualifications =
                (List<Lead_Qualification__c>) result.data.get('leadQualifications');
        Test.stopTest();

        System.assertEquals(
            testQualifications.size(),
            RECORD_NUMBER - CURRENT_OFFSET,
            'Offset in Lead Qualifications query is incorrect.'
        );
    }

    @isTest
    private static void testGetLeadQualificationsIncorrectList() {

        SObjectFactory factory = new SObjectFactory();

        Lead ld = (Lead) factory
            .create(
                Lead.SObjectType
            );

        List<Lead_Qualification__c> qualifications = (List<Lead_Qualification__c>) factory
            .create(
                Lead_Qualification__c.SObjectType,
                3
            );

        Test.startTest();
            Response result = ConvertLeadController.getLeadQualifications(ld.Id);
            List<Lead_Qualification__c> testQualifications =
                (List<Lead_Qualification__c>) result.data.get('leadQualifications');
        Test.stopTest();

        System.assertNotEquals(
            testQualifications.size(),
            qualifications.size(),
            'Incorrect Lead Qualifications was retrieved.'
        );
    }

    @isTest
    private static void testGetAccountsCorrectList() {

        SObjectFactory factory = new SObjectFactory();

        Lead ld = (Lead) factory
            .create(
                Lead.SObjectType,
                new Map<SObjectField, Object> {
                    Lead.Email => EMAIL,
                    Lead.Phone => PHONE
                }
            );

        Account acc = (Account) factory
            .create(
                Account.SObjectType
            );

        Contact cont = (Contact) factory
            .create(
                Contact.SObjectType,
                new Map<SObjectField, Object> {
                    Contact.AccountId => acc.Id,
                    Contact.Email => EMAIL,
                    Contact.Phone => PHONE
                }
            );

        Test.startTest();
            Response result = ConvertLeadController.getAccounts(ld);
            List<Account> accounts = (List<Account>) result.data.get('accounts');
        Test.stopTest();

        System.assertEquals(
            accounts.size(),
            1,
            'Not all Accounts was retrieved.'
        );

        System.assertEquals(
            accounts.get(0).Id,
            acc.Id,
            'Incorrect Account was retrieved.'
        );
    }

    @isTest
    private static void testGetAccountsCorrectListWithIncorrectContacts() {

        SObjectFactory factory = new SObjectFactory();

        Lead ld = (Lead) factory
            .create(
                Lead.SObjectType,
                new Map<SObjectField, Object> {
                    Lead.Email => EMAIL,
                    Lead.Phone => PHONE
                }
            );

        Account acc = (Account) factory
            .create(
                Account.SObjectType
            );

        List<Contact> cont = (List<Contact>) factory
            .create(
                Contact.SObjectType,
                3,
                new Map<SObjectField, Object> {
                    Contact.AccountId => acc.Id,
                    Contact.Email => EMAIL,
                    Contact.Phone => PHONE
                }
            );

        Test.startTest();
            Response result = ConvertLeadController.getAccounts(ld);
            List<Account> accounts = (List<Account>) result.data.get('accounts');
        Test.stopTest();

        System.assertEquals(
            accounts.size(),
            1,
            'Not all Accounts was retrieved.'
        );

        System.assertEquals(
            accounts.get(0).Id,
            acc.Id,
            'Incorrect Account was retrieved.'
        );
    }

    @isTest
    private static void testGetAccountsWithOffset() {

        SObjectFactory factory = new SObjectFactory();

        Lead ld = (Lead) factory
            .create(
                Lead.SObjectType,
                new Map<SObjectField, Object> {
                    Lead.Email => EMAIL,
                    Lead.Phone => PHONE
                }
            );

        List<Account> acc = (List<Account>) factory
            .create(
                Account.SObjectType,
                RECORD_NUMBER
            );

        List<Contact> cont = (List<Contact>) factory
            .create(
                Contact.SObjectType,
                RECORD_NUMBER,
                new Map<SObjectField, Object> {
                    Contact.AccountId => ValueProviderBuilder.provideParents(acc),
                    Contact.Email => EMAIL,
                    Contact.Phone => PHONE
                }
            );

        Test.startTest();
            Response result = ConvertLeadController.getAccounts(ld, CURRENT_OFFSET);
            List<Account> testAccounts = (List<Account>) result.data.get('accounts');
        Test.stopTest();

        System.assertEquals(
            testAccounts.size(),
            RECORD_NUMBER - CURRENT_OFFSET,
            'Offset in Accounts query is incorrect.'
        );
    }

    @isTest
    private static void testGetAccountsIncorrectList() {

        SObjectFactory factory = new SObjectFactory();

        Lead ld = (Lead) factory
            .create(
                Lead.SObjectType
            );

        Account acc = (Account) factory
            .create(
                Account.SObjectType
            );

        Test.startTest();
            Response result = ConvertLeadController.getAccounts(ld);
            List<Account> testAccounts = (List<Account>) result.data.get('accounts');
        Test.stopTest();

        System.assert(
            testAccounts.isEmpty(),
            'Incorrect Accounts was retrieved.'
        );
    }

    // @isTest
    // private static void testGetUserCustomPermissions() {
    //     User leadConvertUser = (User) new SObjectBuilder(User.SObjectType)
    //         .setFields(
    //             new Map<SObjectField, Object> {
    //                 User.FirstName => 'qwerty',
    //                 User.LastName => 'qwerty',
    //                 User.isActive => true
    //             }
    //         )
    //         .create()
    //         .getRecord();

    //     Id ngbsPermissionSetId = [
    //         SELECT ParentId
    //         FROM SetupEntityAccess
    //         WHERE SetupEntityId IN (
    //             SELECT Id
    //             FROM CustomPermission
    //             WHERE DeveloperName = :ALLOW_NGBS_CUSTOM_PERMISSION
    //         )
    //         AND Parent.IsOwnedByProfile = FALSE
    //         LIMIT 1
    //     ][0].ParentId;

    //     new SObjectBuilder(PermissionSetAssignment.SObjectType)
    //         .setFields(
    //             new Map<SObjectField, Object>{
    //                 PermissionSetAssignment.AssigneeId => leadConvertUser.Id,
    //                 PermissionSetAssignment.PermissionSetId => ngbsPermissionSetId
    //             }
    //         )
    //         .create();

    //     System.runAs(leadConvertUser) {

    //         Test.startTest();
    //         Response result = ConvertLeadController.getNGBSPermissionAssignment();
    //         Test.stopTest();

    //         List<String> userPermissions = (List<String>)JSON.deserialize((String)result.data.get('userCustomPermissions'), List<String>.class);

    //         System.assertEquals(userPermissions.contains(ALLOW_NGBS_CUSTOM_PERMISSION),
    //         true,
    //         'NGBS allowed custom permission is assigned to user');
    //     }
    // }

    @isTest
    private static void testGetQueryValidEmailAndPhone() {

        System.assert(
            ConvertLeadController.getQuery(true, true).containsIgnoreCase(EMAIL_OR_PHONE),
            'Incorrect query string with valid Email and Phone was retrieved.'
        );
    }

    @isTest
    private static void testGetQueryValidEmailAndInvalidPhone() {

        System.assert(
            ConvertLeadController.getQuery(true, false).containsIgnoreCase(EMAIL_OR_ACCOUNT),
            'Incorrect query string with valid Email and invalid Phone was retrieved.'
        );

        System.assert(
            !ConvertLeadController.getQuery(true, false).containsIgnoreCase(EMAIL_OR_PHONE),
            'Incorrect query string with valid Email and invalid Phone was retrieved.'
        );
    }

    @isTest
    private static void testGetQueryInvalidEmailAndValidPhone() {

        System.assert(
            ConvertLeadController.getQuery(false, true).containsIgnoreCase(PHONE_OR_ACCOUNT),
            'Incorrect query string with valid Email and invalid Phone was retrieved.'
        );

        System.assert(
            !ConvertLeadController.getQuery(false, true).containsIgnoreCase(EMAIL_OR_PHONE),
            'Incorrect query string with invalid Email and valid Phone was retrieved.'
        );
    }

    @isTest
    private static void testGetQueryInvalidEmailAndPhone() {

        System.assertEquals(
            ConvertLeadController.getQuery(false, false),
            null,
            'Incorrect query string with invalid Email and Phone was retrieved.'
        );
    }

    @isTest
    private static void testGetServiceEntitlement() {
        SObjectFactory factory = new SObjectFactory();

        Account accNoEntitlements = (Account) factory.create(Account.SObjectType);
        Account accNoService = (Account) factory.create(Account.SObjectType);
        Account accWithService = (Account) factory.create(Account.SObjectType);

        Product2 product = (Product2) new SobjectBuilder(Product2.SObjectType)
            .setField(Product2.Name, ValueProviderBuilder.provideUniqueString())
            .setField(Product2.IsActive, true)
            .setField(Product2.Family, Product2Helper.FAMILY_ADDONS)
            .create()
            .getRecord();

        Product2 productService = (Product2) new SobjectBuilder(Product2.SObjectType)
            .setField(Product2.Name, ValueProviderBuilder.provideUniqueString())
            .setField(Product2.IsActive, true)
            .setField(Product2.Family, Product2Helper.FAMILY_SERVICE)
            .setField(Product2.Feature__c, Product2Helper.FEATURE_SERVICE_PLAN)
            .create()
            .getRecord();

        List<PricebookEntry> pbes = new SobjectBuilder(PricebookEntry.SObjectType)
            .setField(PricebookEntry.Pricebook2Id, Test.getStandardPricebookId())
            .setField(PricebookEntry.Product2Id, ValueProviderBuilder.provideParents(new List<Product2> {
                product, productService
            }))
            .setField(PricebookEntry.IsActive, true)
            .quantity(2)
            .create()
            .getRecords();

        List<Entitlement__c> entitlements = new SobjectBuilder(Entitlement__c.SObjectType)
            .setField(Entitlement__c.Account__c, ValueProviderBuilder.provideParents(new List<Account> {
                accNoService, accWithService
            }))
            .setField(Entitlement__c.Product__c, ValueProviderBuilder.provideParents(new List<Product2> {
                product, productService
            }))
            .setField(Entitlement__c.Active__c, true)
            .quantity(2)
            .create()
            .getRecords();

        System.debug([SELECT Id, Account__r.Name, Product__r.Family FROM Entitlement__c]);

        Test.startTest();
            Response resultNoEntitlements = ConvertLeadController.getServiceEntitlement(accNoEntitlements.Id);
            Response resultNoService = ConvertLeadController.getServiceEntitlement(accNoService.Id);
            Response resultWithService = ConvertLeadController.getServiceEntitlement(accWithService.Id);
        Test.stopTest();

        System.assertEquals(resultNoEntitlements.data.get('serviceEntitlement'), null,
            'Account without Entitlements'
        );
        System.assertEquals(resultNoEntitlements.data.get('servicePricebookEntry'), null,
            'Account without Entitlements'
        );

        System.assertEquals(resultNoService.data.get('serviceEntitlement'), null,
            'Account without Service Entitlement'
        );
        System.assertEquals(resultNoService.data.get('servicePricebookEntry'), null,
            'Account without Service Entitlement'
        );

        System.assertEquals(( (Entitlement__c) resultWithService.data.get('serviceEntitlement')).Id,
            entitlements.get(1).Id,
            'Account with Service Entitlement'
        );
        System.assertEquals(( (PricebookEntry) resultWithService.data.get('servicePricebookEntry')).Id,
            pbes.get(1).Id,
            'Account with Service Entitlement'
        );
    }

    @isTest
    private static void testSwitchTriggersOnForLeadConvert() {
        Test.startTest();
            ConvertLeadController.switchTriggers(true);
        Test.stopTest();

        System.assert(
            TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT,
            'Account trigger on Insert was not bypassed.'
        );
        System.assert(
            TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE,
            'Account trigger on Update was not bypassed.'
        );
        System.assert(
            TriggerHandler.BY_PASS_CONTACT_ON_UPDATE,
            'Contact trigger on Update was not bypassed.'
        );
        System.assert(
            TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT,
            'Opportunity trigger on Insert was not bypassed.'
        );
        System.assert(
            TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE,
            'Opportunity trigger on Update was not bypassed.'
        );
    }

    @isTest
    private static void testSwitchTriggersOffForLeadConvert() {
        Test.startTest();
            ConvertLeadController.switchTriggers(false);
        Test.stopTest();

        System.assert(
            !TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT,
            'Account trigger on Insert was not bypassed.'
        );
        System.assert(
            !TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE,
            'Account trigger on Update was not bypassed.'
        );
        System.assert(
            !TriggerHandler.BY_PASS_CONTACT_ON_UPDATE,
            'Contact trigger on Update was not bypassed.'
        );
        System.assert(
            !TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT,
            'Opportunity trigger on Insert was not bypassed.'
        );
        System.assert(
            !TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE,
            'Opportunity trigger on Update was not bypassed.'
        );
    }

    @isTest
    static void testGetDataWave1() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .create()
            .getRecord();

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.FirstName => 'John',
                Contact.LastName => 'Doe',
                Contact.AccountId => acc.Id,
                Contact.Email => 'somemail@fortest.com',
                Contact.Phone => '1234567890'
            })
            .create()
            .getRecord();

        Lead lead = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Lead.LastName => 'TestLead',
                Lead.Email => 'somemail@fortest.com'
            })
            .create()
            .getRecord();

        User testUser = (User) new SObjectBuilder(User.SObjectType)
            .setField(User.TimeZoneSidKey, 'Pacific/Pago_Pago')
            .create()
            .getRecord();

        System.runAs(testUser) {
            Test.startTest();
                Response resp = ConvertLeadController.getDataWave1(lead.Id);
            Test.stopTest();

            Integer expectedTimezoneOffset = UserInfo.getTimeZone().getOffset(System.now());

            Assert.areEqual('somemail@fortest.com', ((Lead) resp.data.get('lead')).Email, 'Incorrect population of Email on Lead');
            Assert.areEqual('My Account', ((List<Account>) resp.data.get('accounts'))[0].Name, 'Incorrect matched Account');
            Assert.isFalse((Boolean) resp.data.get('hasMoreAccounts'), 'Only ONE Account should be matched');
            Assert.areEqual(expectedTimezoneOffset, resp.data.get('userTimezoneOffset'),  'userTimezoneOffset must be populated');
        }
    }

    @isTest
    private static void testGetDataWave2() {

        Lead lead = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Lead.LastName => 'TestLead',
                Lead.Email => 'somemail@fortest.com'
            })
            .create()
            .getRecord();

        Test.startTest();
            Response resp = ConvertLeadController.getDataWave2(lead.Id);
        Test.stopTest();

        System.assert(resp != null, 'getDataWave2 should not return null');
        System.assertEquals(
            resp.status,
            Response.STATUS_SUCCESS,
            'getDataWave2 should return Response with "success" status'
        );
        System.assert(
            resp.data.containsKey('leadQualifications'),
            'getDataWave2 should return Response with key "leadQualifications"'
        );
        System.assert(
            resp.data.containsKey('legacyServices'),
            'getDataWave2 should return Response with key "legacyServices"'
        );
        System.assert(
            resp.data.containsKey('hasMoreQualifications'),
            'getDataWave2 should return Response with key "hasMoreQualifications"'
        );
        System.assertEquals(
            resp.data.get('hasMoreQualifications'),
            false,
            'getDataWave2 should return Response with key "hasMoreQualifications" and value false'
        );
    }

    @isTest
    private static void testGetLeadQualificationsPage() {

        Lead lead = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Lead.LastName => 'TestLead',
                Lead.Email => 'somemail@fortest.com'
            })
            .create()
            .getRecord();

        Test.startTest();
            Response resp = ConvertLeadController.getLeadQualificationsPage(lead.Id, 0);
        Test.stopTest();

        System.assert(resp != null, 'getLeadQualificationsPage should not return null');
        System.assertEquals(
            resp.status,
            Response.STATUS_SUCCESS,
            'getLeadQualificationsPage should return Response with "success" status'
        );
        System.assert(
            resp.data.containsKey('leadQualifications'),
            'getLeadQualificationsPage should return Response with key "leadQualifications"'
        );
        System.assert(
            resp.data.containsKey('hasMoreQualifications'),
            'getLeadQualificationsPage should return Response with key "hasMoreQualifications"'
        );
        System.assertEquals(
            resp.data.get('hasMoreQualifications'),
            false,
            'getLeadQualificationsPage should return Response with key "hasMoreQualifications" and value false'
        );
    }

    @isTest
    private static void testGetAccountsPage() {

        Lead lead = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Lead.LastName => 'TestLead',
                Lead.Email => 'somemail@fortest.com'
            })
            .create()
            .getRecord();

        Test.startTest();
            Response resp = ConvertLeadController.getAccountsPage(lead.Id, 0);
        Test.stopTest();

        System.assert(resp != null, 'getAccountsPage should not return null');
        System.assertEquals(
            resp.status,
            Response.STATUS_SUCCESS,
            'getAccountsPage should return Response with "success" status'
        );
        System.assert(
            resp.data.containsKey('accounts'),
            'getAccountsPage should return Response with key "accounts"'
        );
        System.assert(
            resp.data.containsKey('hasMoreAccounts'),
            'getAccountsPage should return Response with key "hasMoreAccounts"'
        );
        System.assertEquals(
            resp.data.get('hasMoreAccounts'),
            false,
            'getAccountsPage should return Response with key "hasMoreAccounts" and value false'
        );
    }

     @isTest
    private static void testGetOpportunities() {

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .create()
            .getRecord();

        List<Opportunity> opp = new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => acc.Id,
                Opportunity.Name => 'testOpp'
            })
            .quantity(11)
            .create()
            .getRecords();

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Lead.LastName => 'TestLead',
                Lead.Email => 'emailtest12345@test.com'
            })
            .create()
            .getRecord();

        Test.startTest();
        Response res = ConvertLeadController.getOpportunities(acc.Id,0);
        Test.stopTest();

        System.assertEquals(
            'testOpp',
            ((List<Opportunity>) res.data.get('opportunities'))[0].Name,
            'Incorrect Opportunity'
        );
        System.assertEquals(
            true,
            res.data.get('hasMoreOpportunities'),
            'Incorrect assignation of hasMoreOpportunities'
        );
        System.assertEquals(
            10,
            ((List<Opportunity>) res.data.get('opportunities')).size(),
            'Incorrect Number of Opportunities retrieved'
        );

    }
     @isTest
    private static void testGetOppContactRoleInfo() {

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Name => 'testOpp'
            })
            .create()
            .getRecord();

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.FirstName => 'Pepe',
                Contact.LastName => 'Tester',
                Contact.AccountId => acc.Id,
                Contact.Email => 'emailtest12345@test.com',
                Contact.Phone => '1234567890'
            })
            .create()
            .getRecord();

        OpportunityContactRole ocr = (OpportunityContactRole) new SObjectBuilder(OpportunityContactRole.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                OpportunityContactRole.ContactId => con.Id,
                OpportunityContactRole.OpportunityId => opp.Id,
                OpportunityContactRole.Role => 'Influencer',
                OpportunityContactRole.IsPrimary => true
            })
            .create()
            .getRecord();

        Test.startTest();
        Response res = ConvertLeadController.getOppContactRoleInfo(opp.Id,con.Id);
        Test.stopTest();

        System.assertEquals(
            'Influencer',
             res.data.get('role'),
            'Incorrect Role Selected'
        );
        System.assertEquals(
            true,
            res.data.get('alreadyAContactRole'),
            'Incorrect OpportunityContactRole Selected'
        );
        System.assertEquals(
            true,
            res.data.get('alreadyHasPrimary'),
            'Incorrect Primary Selected'
        );

    }

    @isTest
    private static void testGetOppContactRoleInfoInvalid() {

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Name => 'testOpp'
            })
            .create()
            .getRecord();

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.FirstName => 'Pepe',
                Contact.LastName => 'Tester',
                Contact.AccountId => acc.Id,
                Contact.Email => 'emailtest12345@test.com',
                Contact.Phone => '1234567890'
            })
            .create()
            .getRecord();


        Test.startTest();
        Response res = ConvertLeadController.getOppContactRoleInfo(opp.Id,con.Id);
        Test.stopTest();

        System.assertEquals(
            false,
            res.data.get('alreadyAContactRole'),
            'No OpportunityContactRole should be selected'
        );
        System.assertEquals(
            false,
            res.data.get('alreadyHasPrimary'),
            'No OpportunityContactRole should be selected'
        );

    }

    @isTest
    private static void testGetContactsWithNullPhone() {

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .create()
            .getRecord();

        List<Contact> con = new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.FirstName => 'Pepe',
                Contact.LastName => 'Tester',
                Contact.AccountId => acc.Id,
                Contact.Email => 'testemail@test.com',
                Contact.Phone => null
            })
            .quantity(11)
            .create()
            .getRecords();

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Lead.LastName => 'TestLead',
                Lead.Email => 'notmatch@test.com',
                Lead.Phone => null
            })
            .create()
            .getRecord();

        Test.startTest();
        Response res = ConvertLeadController.getContacts(ld.Id,acc.Id,0);
        Test.stopTest();

        System.assertEquals(
            0,
            ((List<Contact>) res.data.get('contacts')).size(),
            'It shouldnt bring a contact'
        );
    }

    @isTest
    private static void testGetContacts() {

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .create()
            .getRecord();

        List<Contact> con = new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.FirstName => 'Pepe',
                Contact.LastName => 'Tester',
                Contact.AccountId => acc.Id,
                Contact.Email => 'emailtest12345@test.com',
                Contact.Phone => '1234567890'
            })
            .quantity(11)
            .create()
            .getRecords();

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Lead.LastName => 'TestLead',
                Lead.Email => 'emailtest12345@test.com'
            })
            .create()
            .getRecord();

        Test.startTest();
        Response res = ConvertLeadController.getContacts(ld.Id,acc.Id,0);
        Test.stopTest();

        System.assertEquals(
            'Pepe',
            ((List<Contact>) res.data.get('contacts'))[0].FirstName,
            'Incorrect Contact'
        );
        System.assertEquals(
            true,
            res.data.get('hasMoreContacts'),
            'Incorrect assignation of hasMoreContacts'
        );
        System.assertEquals(
            10,
            ((List<Contact>) res.data.get('contacts')).size(),
            'Incorrect Number of contacts retrieved'
        );

    }

    @isTest
    private static void testCheckAvailableVATNumberSFWithApproval() {

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .setField(Account.BillingStreet, 'Lenin')
            .setField(Account.BillingCity, 'Chicago')
            .setField(Account.BillingState, 'Alabama')
            .setField(Account.BillingPostalCode, '12345')
            .setField(Account.BillingCountry, 'California')
            .setField(Account.Billing_System__c, AccountHelper.BILLING_SYSTEM_NBS)
            .create()
            .getRecord();

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.Email, 'email@example.com')
            .setField(Contact.FirstName, 'FirstName')
            .setField(Contact.LastName, 'LastName')
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.RecordTypeId, OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY)
            .setField(Opportunity.Brand_Name__c, OpportunityHelper.BRAND_RINGCENTRAL_EU)
            .setField(Opportunity.AccountId, acc.Id)
            .create()
            .getRecord();

        Approval__c approval =  (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.Name => 'Tax Exempt Approval',
                    Approval__c.RecordTypeId => ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL,
                    Approval__c.Account__c => acc.Id,
                    Approval__c.Contact__c => con.Id,
                    Approval__c.VATNumber__c => '23423255',
                    Approval__c.Opportunity__c => opp.Id,
                    Approval__c.VATCountryForCheck__c => 'AT',
                    Approval__c.Status__c => ApprovalHelper.STATUS_APPROVED})
            .create()
            .getRecord();

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Lead.LastName => 'TestLead',
                Lead.Email => 'emailtest12345@test.com',
                Lead.VATNumber__c => '111111'
            })
            .create()
            .getRecord();

        Test.startTest();
        Response res = ConvertLeadController.checkAvailableVATNumberSF(acc.Id,ld.Id);
        Test.stopTest();

        System.assertEquals(res.messages[0].message, AccountHelper.VAT_NUMBER_EXCEPTION_APPROVAL, 'Exception must be not null');
    }

    @isTest
    private static void testCheckAvailableVATNumberSFWTApproval() {

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
                .setField(Account.BillingStreet, 'Lenin')
                .setField(Account.BillingCity, 'Chicago')
                .setField(Account.BillingState, 'Alabama')
                .setField(Account.BillingPostalCode, '12345')
                .setField(Account.BillingCountry, 'California')
                .setField(Account.Billing_System__c, AccountHelper.BILLING_SYSTEM_NBS)
                .setField(Account.VATNumber__c, '22222')
                .create()
                .getRecord();

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
                .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
                .setField(Contact.AccountId, acc.Id)
                .setField(Contact.Email, 'email@example.com')
                .setField(Contact.FirstName, 'FirstName')
                .setField(Contact.LastName, 'LastName')
                .create()
                .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setField(Opportunity.RecordTypeId, OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY)
                .setField(Opportunity.Brand_Name__c, OpportunityHelper.BRAND_RINGCENTRAL_EU)
                .setField(Opportunity.AccountId, acc.Id)
                .create()
                .getRecord();

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                        Lead.LastName => 'TestLead',
                        Lead.Email => 'emailtest12345@test.com',
                        Lead.VATNumber__c => '111111'
                })
                .create()
                .getRecord();

        Test.startTest();
        Response res = ConvertLeadController.checkAvailableVATNumberSF(acc.Id,ld.Id);
        Test.stopTest();

        System.assertEquals(res.messages[0].message, AccountHelper.VAT_NUMBER_EXCEPTION_ACCOUNT, 'Exception must be not null');
    }

    @isTest
    private static void testHasTaxExemptionApprovals() {

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .setField(Account.BillingStreet, 'Lenin')
            .setField(Account.BillingCity, 'Chicago')
            .setField(Account.BillingState, 'Alabama')
            .setField(Account.BillingPostalCode, '12345')
            .setField(Account.BillingCountry, 'California')
            .setField(Account.Billing_System__c, AccountHelper.BILLING_SYSTEM_NBS)
            .create()
            .getRecord();

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.Email, 'email@example.com')
            .setField(Contact.FirstName, 'FirstName')
            .setField(Contact.LastName, 'LastName')
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.RecordTypeId, OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY)
            .setField(Opportunity.Brand_Name__c, OpportunityHelper.BRAND_RINGCENTRAL_EU)
            .setField(Opportunity.AccountId, acc.Id)
            .create()
            .getRecord();

        Approval__c approval =  (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.Name => 'Tax Exempt Approval',
                    Approval__c.RecordTypeId => ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL,
                    Approval__c.Account__c => acc.Id,
                    Approval__c.Contact__c => con.Id,
                    Approval__c.VATNumber__c => '23423255',
                    Approval__c.Opportunity__c => opp.Id,
                    Approval__c.VATCountryForCheck__c => 'AT',
                    Approval__c.Status__c => ApprovalHelper.STATUS_APPROVED})
            .create()
            .getRecord();

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                        Lead.LastName => 'TestLead',
                        Lead.Email => 'emailtest12345@test.com',
                        Lead.VATNumber__c => '111111'
                })
                .create()
                .getRecord();

        Test.startTest();
        Response res = ConvertLeadController.hasTaxExemptionApprovals(acc.Id,OpportunityHelper.BRAND_RINGCENTRAL);
        Test.stopTest();

        System.assertEquals(res.data.get('approvals'), true, 'Approvals must be true');
        System.assertEquals(res.data.get('accountId'), acc.Id, 'Account id must be same as created');
        System.assertNotEquals(res.data.get('brand'), opp.Brand_Name__c, 'Brand must be Ringcentral EU');
    }

    @isTest
    private static void testRejectTaxExemptionApprovals() {

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .setField(Account.BillingStreet, 'Lenin')
            .setField(Account.BillingCity, 'Chicago')
            .setField(Account.BillingState, 'Alabama')
            .setField(Account.BillingPostalCode, '12345')
            .setField(Account.BillingCountry, 'California')
            .setField(Account.Billing_System__c, AccountHelper.BILLING_SYSTEM_NBS)
            .create()
            .getRecord();

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.Email, 'email@example.com')
            .setField(Contact.FirstName, 'FirstName')
            .setField(Contact.LastName, 'LastName')
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.RecordTypeId, OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY)
            .setField(Opportunity.Brand_Name__c, OpportunityHelper.BRAND_RINGCENTRAL_EU)
            .setField(Opportunity.AccountId, acc.Id)
            .create()
            .getRecord();

        Approval__c approval =  (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.Name => 'Tax Exempt Approval',
                    Approval__c.RecordTypeId => ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL,
                    Approval__c.Account__c => acc.Id,
                    Approval__c.Contact__c => con.Id,
                    Approval__c.VATNumber__c => '23423255',
                    Approval__c.Opportunity__c => opp.Id,
                    Approval__c.VATCountryForCheck__c => 'AT',
                    Approval__c.Status__c => ApprovalHelper.STATUS_APPROVED})
            .create()
            .getRecord();

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Lead.LastName => 'TestLead',
                Lead.Email => 'emailtest12345@test.com',
                Lead.VATNumber__c => '111111'
            })
            .create()
            .getRecord();

        Test.startTest();
        Response res = ConvertLeadController.rejectTaxExemptionApprovals(acc.Id, 'test');
        Test.stopTest();

        Approval__c reselectApproval = (Approval__c) new ApprovalSelector()
            .selectApprovals()
            .selectFields(new Set<String>{'Status__c'})
            .executeQuery()
            .get(0);

        System.assertEquals(res.data.get('accountId'), acc.Id, 'Account id must be same as created');
        System.assertEquals(reselectApproval.Status__c, ApprovalHelper.STATUS_REJECTED, 'Approval status must be Rejected');
    }

    @isTest
    private static void testGetDefaultBI() {
        Lead testLead = (Lead) new SObjectBuilder(Lead.SObjectType)
            .create()
            .getRecord();

        Test.startTest();
            Response result = ConvertLeadController.getSubBrandAndDefaultBI(testLead);
        Test.stopTest();

        Response resp = new Response();
        resp.setData('defaultBI', '');
        resp.setData('subBrand', '');
        resp.setData('availableBIs', '[]');

        System.assertEquals(JSON.serialize(resp), JSON.serialize(result), 'Wrong defaultBI');
    }

    @isTest
    private static void testGetCountriesForSalesLead() {
        String leadCountry1 = 'Test Country';
        String leadCountry2 = 'France';

        Test.startTest();
            Response result1 = ConvertLeadController.getCountriesForSalesLead(leadCountry1);
            Response result2 = ConvertLeadController.getCountriesForSalesLead(leadCountry2);
        Test.stopTest();

        System.assertEquals(LeadHelper.DEFAULT_COUNTRY, result1.getData('country'), 'Country has to be default');
        System.assertEquals('France', result2.getData('country'), 'Country has not to be changed');
    }

    @isTest
    private static void testGetBrandForSalesLead() {
        String leadCountry = 'United Kingdom';
        String leadBrand;

        Test.startTest();
            String result = ConvertLeadController.getBrandForSalesLead(leadCountry, leadBrand);
        Test.stopTest();

        System.assertEquals('RingCentral UK', result, 'Wrong brand');
    }

    @IsTest
    static void testValidateDataForSelectedAccountBlankDefaultBI() {
        Map<String, String> subBrandBIMap = new Map<String, String>();
        subBrandBIMap.put('defaultBI', '');

        Test.startTest();
        ConvertLeadController.validateDataForSelectedAccount(subBrandBIMap);
        Test.stopTest();

        System.assertEquals('', subBrandBIMap.get('defaultBI'), 'DefaultBI should remain empty for blank input');
    }

    @IsTest
    static void testValidateDataForSelectedAccount() {
        Map<String, String> subBrandBIMap = new Map<String, String>();
        subBrandBIMap.put('defaultBI', 'RingCentral Inc.');
        subBrandBIMap.put('subBrand', '');
        subBrandBIMap.put('country', 'United States');
        subBrandBIMap.put('brand', 'RingCentral');

        Test.startTest();
        ConvertLeadController.validateDataForSelectedAccount(subBrandBIMap);
        Test.stopTest();

        System.assertEquals('RingCentral Inc.', subBrandBIMap.get('defaultBI'), 'DefaultBI should be RingCentral Inc.');
    }

    @IsTest
    static void testGetDataForSelectedAccount() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.EnableBusinessIdentityMapping__c, true)
            .create();

        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Test  Account',
                Account.BillingCountry => 'United States',
                Account.CurrencyIsoCode => 'USD',
                Account.RC_Brand__c => 'RingCentral'
            })
            .create()
            .getRecord();

        Test.startTest();
            Response result = ConvertLeadController.getDataForSelectedAccount(null, testAccount.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals('RingCentral Inc.', result.getData('defaultBI'), 'DefaultBI should be RingCentral Inc.');
        System.assertEquals('', result.getData('subBrand'), 'SubBrand should be blank');
    }
}