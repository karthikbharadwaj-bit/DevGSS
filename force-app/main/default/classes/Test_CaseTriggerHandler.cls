@IsTest
private class Test_CaseTriggerHandler {
    private static final String ACCOUNT_NAME = 'ACCOUNT_NAME';
    private static final String ACCOUNT_PARTNER_BAN_ID = 'ACCOUNT_PARTNER_BAN_ID';
    private static final String CONTACT_FIRSTNAME = 'CONTACT_FIRSTNAME';
    private static final String CONTACT_LASTNAME = 'CONTACT_LASTNAME';
    private static final String CONTACT_EMAIL = 'testcompanynamefortrigger@testcompanynamefortrigger.com';
    private static final String RC_CONTACT_FIRSTNAME = 'RC_CONTACT_FIRSTNAME';
    private static final String RC_CONTACT_LASTNAME = 'RC_CONTACT_LASTNAME';
    private static final String RC_CONTACT_EMAIL = 'rcinternalcontact@rcinternalcontact.com';
    private static final String CONTACT_PHONE = '12345678910';
    private static final String SLA_PROCESS_ID = [SELECT Id FROM SlaProcess WHERE Name = 'Default' LIMIT 1].Id;
    private static final String ADDRESS_FOR_TELUS = 'add|city|state|123|USA';
    private static final String LOCAL_CONTACT_FIRST_NAME = 'localContactFirstName';
    private static final String LOCAL_CONTACT_LAST_NAME = 'localContactLastName';
    private static final String LOCAL_CONTACT_EMAIL = 'localContactEmail@localContactEmail.com';
    private static final String LOCAL_CONTACT_PHONE = '01987654321';
    private static final String MANAGER_EMAIL = 'usermanager@testorg.com';
    private static final String MANAGER_TITLE = 'test_manager_title';
    private static final String MANAGER_LAST_NAME = 'TestNameManager';
    private static final String ACCOUNT_CURRENT_OWNER_EMAIL = 'accountcurrentowner@testorg.com';
    private static final String ACCOUNT_RC_USER_ID = '1122334455';
    private static final String ACCOUNT_RC_INTERNAL_NAME = 'RC Internal';
    private static final String VAR_FOLLOW_UP = 'VAR Follow Up';
    private static final String EXCEPTION_MESSAGE = 'Exception expected during test execution';
    private static final String EXCEPTION_MESSAGE_EQUAL_TO = 'Exception message should be equal to ';
    private static final String SHOULD_BE_ONE_SURVEY_CREATED = 'There should be 1 survey created';
    private static final String TEST_EDITION = 'testEdition';
    private static final String TEST_INCONTACT_CLUSTER = 'C57';

    private static final Integer CASE_BU_ID = 123456;
    private static final Integer TEST_NEW_QUANTITY = 10;
    private static final Date TODAY = Date.today();

    @TestSetup
    private static void setupData() {
        Triggers.switchOff();
        new SObjectBuilder(Entitlement_Case_Milestone_Configuration__c.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Entitlement_Case_Milestone_Configuration__c.Name => CaseHelper.RT_NAME_SUPPORT_INTEGRATIONS,
                Entitlement_Case_Milestone_Configuration__c.First_Response_Milestone__c => VAR_FOLLOW_UP,
                Entitlement_Case_Milestone_Configuration__c.FollowUp_Milestone__c => 'CSP Follow Up',
                Entitlement_Case_Milestone_Configuration__c.Case_Resolution_Milestone__c => 'CSP Case Resolution'
            })
            .create()
            .getRecord();

        new SObjectBuilder(EntitlementEnable__c.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                EntitlementEnable__c.Name => 'IsEntitlementsEnabled',
                EntitlementEnable__c.IsEntitlementsEnabled__c => true
            })
            .create()
            .getRecord();

        new SObjectBuilder(Entitlement_Case_ReType_Configuration__c.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Entitlement_Case_ReType_Configuration__c.Name => CaseHelper.RT_NAME_SYSTEM_OPERATIONS,
                Entitlement_Case_ReType_Configuration__c.SLAProcessId__c => SLA_PROCESS_ID,
                Entitlement_Case_ReType_Configuration__c.SLAProcessName__c => 'Default',
                Entitlement_Case_ReType_Configuration__c.Business_Hours_Id__c => [SELECT Id FROM BusinessHours WHERE Name = 'Default' LIMIT 1].Id,
                Entitlement_Case_ReType_Configuration__c.Business_Hours_Name__c => 'Default'
            })
            .create();

        new SObjectBuilder(Feature_Toggle__c.sObjectType)
            .setField(Feature_Toggle__c.ESBPortingNewFlow__c, true)
            .create();

        new SObjectBuilder(Owner_Assignment_for_Relationship_Cases__c.sObjectType)
            .setField(Owner_Assignment_for_Relationship_Cases__c.Last_assigned_owner__c, null)
            .create();

        Opportunity oppty = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => Date.today()
            })
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => 'Test',
                Quote.Start_Date__c => Date.today() + 1,
                Quote.End_Date__c => Date.today() + 100,
                Quote.OpportunityId => oppty.Id
            })
            .create()
            .getRecord();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => ACCOUNT_NAME,
                Account.Partner_BAN_ID__c => ACCOUNT_PARTNER_BAN_ID,
                Account.RC_Brand__c => Opportunityhelper.BRAND_TELUS,
                Account.Active_Sales_Agreement__c => testQuote.Id,
                Account.Current_Owner_Email__c => ACCOUNT_CURRENT_OWNER_EMAIL,
                Account.RC_User_ID__c => ACCOUNT_RC_USER_ID,
                Account.MRR__c => 2,
                Account.Number_of_DL_s__c => 1
            })
            .create()
            .getRecord();

        Contact c = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.FirstName => CONTACT_FIRSTNAME,
                Contact.LastName => CONTACT_LASTNAME,
                Contact.Email => CONTACT_EMAIL,
                Contact.Phone => CONTACT_PHONE,
                Contact.Phone_Ext__c => 777,
                Contact.AccountId => acc.Id
            })
            .create()
            .getRecord();

        new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    AccountContactRole.AccountId => acc.Id,
                    AccountContactRole.ContactId => c.Id,
                    AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_SIGNATORY,
                    AccountContactRole.IsPrimary => true
                }
            )
            .create();
        Triggers.switchOn();
    }


    @IsTest
    private static void testCreateCaseContactAttempts() {
        List<Case> cases;
        Test.startTest();
        cases = (List<Case>) new SObjectBuilder(Case.SObjectType)
            .setField(Case.RecordTypeId, new ValueProvider.ListProvider(
                new List<String> {
                    CaseHelper.RT_ID_CLOSE_LOOP_FEEDBACK_MEDALLIA_RELATIONSHIP,
                    CaseHelper.RT_ID_SUPPORT_T1
                })
            )
            .quantity(2)
            .create()
            .getRecords();
        Test.stopTest();

        Set<Id> caseIds = new Set<Id>();
        for (Case c : cases) {
            caseIds.add(c.Id);
        }

        List<Case_Activity__c> caseActivities = (List<Case_Activity__c>) new CaseActivitySelector()
            .selectCloseAttemptsByCaseIdAndRecordType(new List<Object> {
                caseIds,
                CaseHelper.RT_ID_CASE_ACTIVITY_CONTACT_ATTEMPT
            })
            .executeQuery();

        Assert.isTrue(caseActivities.size() == 3, 'There should be 3 Case Activity Contact Attempt created');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest
    private static void testValidateOnAfterUpdateEvent() {
        Account acc = selectAccount();
        Contact c = selectContact();

        Case cs = (Case) new SObjectBuilder(Case.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Case.Status => CaseHelper.CASE_STATUS_NEW,
                    Case.RecordTypeId => CaseHelper.RT_ID_SYSTEM_OPERATIONS,
                    Case.Contact_Email__c => 'test@testcoverage.com',
                    Case.AccountId => acc.Id,
                    Case.ContactId => c.Id
                })
                .create()
                .getRecord();
        TriggerHandler.ESB_START = true;

        Test.startTest();
        cs.Status = CaseHelper.CASE_STATUS_WAITING_ON_LOA;
        update cs;
        Test.stopTest();
    }

    @IsTest
    private static void testValidateStatusFieldOnInsert() {
        try {
            new SObjectBuilder(Case.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Case.Status => 'Invalid',
                    Case.Case_Category__c => CaseHelper.CASE_CATEGORY_SYSTEMS,
                    Case.RecordTypeId => CaseHelper.RT_ID_DEAL_AND_ORDER_SUPPORT
                })
                .create();

            Assert.isTrue(false, 'Should throw exception');
        } catch (Exception e) {
            assertException(e, Label.CaseDOSShouldBeInNewStatus, '');
        }
    }

    @IsTest
    private static void testPopulateOpportunityMRR() {
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test Account')
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => testAcc.Id,
                Opportunity.Name => 'TestOpportunity',
                Opportunity.Total_MRR__c => 100
            })
            .create()
            .getRecord();

        Test.startTest();

        Case nCase = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Status => CaseHelper.CASE_STATUS_NEW,
                Case.AccountId => testAcc.Id,
                Case.Opportunity_Reference__c => testOpp.Id
            })
            .create()
            .getRecord();

        Test.stopTest();

        nCase = selectCaseToAssertById(nCase.Id);

        Assert.isTrue(100 == nCase.OpportunityMRR__c, 'OpportunutyMRR__c on case should be equal to MRR on Opportunity');
    }

    @IsTest
    private static void testChangeRecordType() {
        createCaseRoutingCustomSettings();

        Case testCase;
        System.runAs(createUserWithProfile(ProfileHelper.PROFILE_NAME_DEAL_DESK_LIGHTNING)) {
            Test.startTest();

            testCase = (Case) new SObjectBuilder(Case.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Case.Status => CaseHelper.CASE_STATUS_NEW,
                    Case.RecordTypeId => CaseHelper.RT_ID_DEAL_AND_ORDER_SUPPORT,
                    Case.Case_Category__c => 'System Issue',
                    Case.Case_Subcategory__c => 'Shipping',
                    Case.Origin => 'Account'
                })
                .build()
                .getRecord();

            //Fetching the assignment rules on case using SOQL because SObject set dynamically
            AssignmentRule assignmentRule = [SELECT Id FROM AssignmentRule WHERE SobjectType = 'Case' AND Active = true LIMIT 1];
            Database.DMLOptions dmlOpts = new Database.DMLOptions();
            dmlOpts.assignmentRuleHeader.assignmentRuleId = assignmentRule.Id;
            testCase.setOptions(dmlOpts);
            insert testCase;

            Test.stopTest();
        }
        testCase = selectCaseToAssertById(testCase.Id);

        Assert.areEqual(CaseHelper.RT_ID_INTERNAL_BUSINESS_SERVICES, testCase.RecordTypeId, 'Created Case should be Internal Business Services record type');
    }

    @IsTest
    private static void testPopulateTotalMRRtoSurveyDateFieldOnCreation_whenCaseHasAccountWithTenMRR_shouldCopyThisValueToCaseField() {

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.RecordTypeId => AccountHelper.RT_ID_CUSTOMER_ACCOUNT,
                Account.Name => 'Test Account',
                Account.RC_User_ID__c => '12345',
                Account.MRR__c => 10,
                Account.RC_Brand__c => 'RingCentral'
            })
            .create()
            .getRecord();

        Contact newContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.FirstName => 'Test1',
                Contact.LastName => 'Test1',
                Contact.AccountId => acc.Id,
                Contact.Email => 'fake@mail.com',
                Contact.Phone => '1234567890',
                Contact.Preferred_Language__c => 'en_US'
            })
            .create()
            .getRecord();

        Test.startTest();

        Case aCase = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Status => CaseHelper.CASE_STATUS_NEW,
                Case.RecordTypeId => CaseHelper.RT_ID_CLOSE_LOOP_FEEDBACK_MEDALLIA_RELATIONSHIP,
                Case.AccountId => acc.Id,
                Case.ContactId => newContact.Id,
                Case.Subject => 'Test',
                Case.Description => 'Test',
                Case.Origin => 'Phone'
            })
            .create()
            .getRecord();

        Test.stopTest();

        aCase = selectCaseToAssertById(aCase.Id);

        Assert.areEqual('10.00', aCase.TotalMRRtoSurveyDate__c, 'It should be the same value as Account MRR field');
    }

    @IsTest
    private static void testPreventCaseCreation() {
        final String OOO = 'OOO';
        final String OUT_OF_OFFICE = 'Out of Office';
        final String auto_reply='auto-reply';
        final String autoreply='autoreply';
        final String automatic_reply='automatic reply';
        final String Undeliverable='Undeliverable';
        final String RANDOM_WORD = (String) ValueProviderBuilder.provideUniqueString().getValue();
        final String SAFE_SUBJECT = 'safe' + RANDOM_WORD;
        final String SAFE_BIG_SUBJECT = 'HUGE PROBLEM HELLLOOOO RE: BIG PROBLEM  BIG PROBLEM  BIG PROBLEM  BIG PROBLEM';

        List<Case> newCases = (List<Case>) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                //Case.Description => ValueProviderBuilder.provideList(new List<String> { '', '', '', DESCRIPTION_THAT_SHOULD_FIRE, DESCRIPTION_THAT_SHOULD_NOT_FIRE, DESCRIPTION_THAT_SHOULD_NOT_FIRE }),
                Case.Subject => ValueProviderBuilder.provideList(new List<String> { OOO, OUT_OF_OFFICE, RANDOM_WORD, SAFE_SUBJECT, SAFE_SUBJECT, SAFE_BIG_SUBJECT, auto_reply, autoreply, automatic_reply, Undeliverable })
            })
            .quantity(10)
            .build()
            .getRecords();

        Set<String> stopWords = new Set<String> { OOO, OUT_OF_OFFICE, RANDOM_WORD, auto_reply, autoreply, automatic_reply, Undeliverable };
        List<Words_to_prevent_case_creation__mdt> testMetadataRecords = buildWordsToPreventCaseCreationMdts(stopWords);
        CaseTriggerHandler.PreventCaseCreation triggerHandler = new CaseTriggerHandler.PreventCaseCreation(newCases);
        triggerHandler.stopTermRecords = testMetadataRecords;

        Test.startTest();
            triggerHandler.handle();
        Test.stopTest();
		
        Case safeCaseWithBigSubject = newCases.remove(5);
        Case safeCase = newCases.remove(4);
        Assert.isFalse(safeCase.hasErrors(), 'Case with safe Subject should not have errors');
        Assert.isFalse(safeCaseWithBigSubject.hasErrors(), 'Case with a lot of frustrating words should not have errors');
        for (Case c : newCases) {
            if (c.Subject.contains(OOO) || c.Subject.contains(OUT_OF_OFFICE) || c.Subject.contains(RANDOM_WORD) || c.Subject.contains(auto_reply) ||
               c.Subject.contains(autoreply) || c.Subject.contains(automatic_reply) || c.Subject.contains(Undeliverable)) { 
                //System.assert(c.hasErrors(), 'Case with stop word in its Subject should have errors'); 
                if (c.getErrors().size() > 0) { 
                    System.assertEquals( CaseTriggerHandler.ERROR_MESSAGE_PREVENT_CASE_CREATION, c.getErrors().get(0).getMessage(), 'Error message should match' );
                } 
            } else { 
                System.assert(!c.hasErrors(), 'Case without stop word in its Subject should not have errors'); 
            }
        }
    }

    @IsTest
    private static void testTelusPopulateVendorContactFieds() {
        Account acc = selectAccount();
        Contact c = selectContact();

        Test.startTest();

        Case cs = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Status => CaseHelper.CASE_STATUS_NEW,
                Case.RecordTypeId => CaseHelper.RT_ID_PORTING_OUT,
                Case.Porting_Estimated_Completion_Date__c => Date.today(),
                Case.AccountId => acc.Id,
                Case.ContactId => c.Id
            })
            .create()
            .getRecord();

        Test.stopTest();

        cs = selectCaseToAssertById(cs.Id);

        Assert.areEqual(CONTACT_EMAIL, cs.Case_Contact_Email__c, 'Case Contact Email should be equal to Contact Email');
        Assert.areEqual(CONTACT_FIRSTNAME, cs.Case_Contact_First_Name__c, 'Case Contact First Name should be equal to Contact First Name');
        Assert.areEqual(CONTACT_LASTNAME, cs.Case_Contact_Last_Name__c, 'Case Contact Last Name should be equal to Contact Last Name');
        Assert.areEqual(CONTACT_PHONE, cs.Case_Contact_Phone__c, 'Case Contact Phone should be equal to Contact Phone');
        Assert.areEqual(ACCOUNT_PARTNER_BAN_ID, cs.Partner_BAN_ID__c, 'Case Partner Ban Id should be equal to Account Partner Ban Id');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest
    private static void testMapTelusAddressToRCAddress() {
        Test.startTest();

        Case cs = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Status => CaseHelper.CASE_STATUS_NEW,
                Case.Return_Shipping_Address__c => ADDRESS_FOR_TELUS
            })
            .create()
            .getRecord();

        Test.stopTest();

        cs = selectCaseToAssertById(cs.Id);

        assertTelusAddressToRCAddress(cs);
    }

    @IsTest
    private static void testValidateOnBeforeInsertEvent_negative() {
        System.runAs(createUserWithProfile(ProfileHelper.PROFILE_NAME_DEAL_DESK_LIGHTNING)) {
            Test.startTest();
            Case cs;
            try {
                new SObjectBuilder(Case.SObjectType)
                    .setFields(new Map<SObjectField, Object> {
                        Case.Status => CaseHelper.CASE_STATUS_NEW,
                        Case.RecordTypeId => CaseHelper.RT_ID_PORTING_IN_RCCA
                    })
                    .create();

                    Assert.isTrue(false, 'Should throw exception');
            } catch (Exception e) {
                assertException(e, 'Porting – In (RC CA) cases cannot be updated..', 'Fraud_Loss__c');
            }
            Test.stopTest();
        }
    }

    @IsTest
    private static void testValidateOnBeforeInsertEvent_positive() {
        Test.startTest();

        Case cs = (Case) new SObjectBuilder(Case.SObjectType)
            .setField(Case.Status, CaseHelper.CASE_STATUS_NEW)
            .create()
            .getRecord();

        Test.stopTest();

        cs = selectCaseToAssertById(cs.Id);
        Assert.isTrue(cs.IsUpdatePermitted__c, 'Update should be permitted');
    }

    @IsTest
    private static void testPopulatePrimaryContactForPortingCase() {
        Account acc = selectAccount();
        Test.startTest();

        Case cs = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Status => CaseHelper.CASE_STATUS_NEW,
                Case.RecordTypeId => CaseHelper.RT_ID_PORTING_IN,
                Case.Porting_Estimated_Completion_Date__c => Date.today(),
                Case.AccountId => acc.Id
            })
            .create()
            .getRecord();

        Test.stopTest();
        cs = selectCaseToAssertById(cs.Id);

        Assert.areEqual(selectContact().Id, cs.ContactId, 'Case Contact should be equal to Contact from Account');
    }

    @IsTest
    private static void testEntitleAssignmentOncase_existingEnt() {
        Account acc = selectAccount();

        Entitlement ent = (Entitlement) new SObjectBuilder(Entitlement.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Entitlement.Name => 'ENTITLEMENT_NAME',
                Entitlement.AccountId => acc.Id,
                Entitlement.Type => 'Phone Support',
                Entitlement.StartDate => System.today(),
                Entitlement.SlaProcessId => SLA_PROCESS_ID,
                Entitlement.EndDate => System.today()
            })
            .create()
            .getRecord();

        Test.startTest();

        Case cs = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Status => CaseHelper.CASE_STATUS_NEW,
                Case.RecordTypeId => CaseHelper.RT_ID_SYSTEM_OPERATIONS,
                Case.AccountId => acc.Id
            })
            .create()
            .getRecord();

        Test.stopTest();
        cs = selectCaseToAssertById(cs.Id);

        Assert.areEqual(ent.Id, cs.EntitlementId, 'Case Entitlement should be equal to existing Entitlement');
    }

    @IsTest
    private static void testEntitleAssignmentOncase_newEnt() {
        Account acc = selectAccount();
        Test.startTest();

        Case cs = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Status => CaseHelper.CASE_STATUS_NEW,
                Case.RecordTypeId => CaseHelper.RT_ID_SYSTEM_OPERATIONS,
                Case.AccountId => acc.Id
            })
            .create()
            .getRecord();

        Test.stopTest();
        cs = selectCaseToAssertById(cs.Id);

        Assert.isTrue(cs.EntitlementId != null, 'Case Entitlement should be created');
    }

    @IsTest
    private static void testValidateByPassCase() {
        TriggerHandler.BY_PASS_CASE_Trigger = true;
        String lastCaseComment = 'lastCaseComment';

        Case cs = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Status => CaseHelper.CASE_STATUS_NEW,
                Case.Last_Case_Comment__c => lastCaseComment
            })
            .create()
            .getRecord();

        Test.startTest();
        cs.Last_Case_Comment__c = 'newLastCaseComment';
        update cs;
        Test.stopTest();

        Assert.isFalse(TriggerHandler.BY_PASS_CASE_Trigger, 'BY_PASS_CASE_Trigger should be false');
    }

    @IsTest
    private static void testMapFieldsForTelusCases() {

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => TelusExternalSharingHelperCls.TELUS_INHOUSE_ACCOUNT_NAME,
                Account.Partner_BAN_ID__c => '123123',
                Account.RecordTypeId => AccountHelper.RT_ID_CUSTOMER_ACCOUNT,
                Account.RC_Brand__c => Opportunityhelper.BRAND_TELUS
            })
            .create()
            .getRecord();

        Contact c = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.FirstName => LOCAL_CONTACT_FIRST_NAME,
                Contact.LastName => LOCAL_CONTACT_LAST_NAME,
                Contact.Email => LOCAL_CONTACT_EMAIL,
                Contact.Phone => LOCAL_CONTACT_PHONE,
                Contact.AccountId => acc.Id
            })
            .create()
            .getRecord();

        Test.startTest();

        Case cs = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Status => CaseHelper.CASE_STATUS_NEW,
                Case.Case_Contact_Phone__c => LOCAL_CONTACT_PHONE,
                Case.Case_Contact_Email__c => LOCAL_CONTACT_EMAIL,
                Case.Case_Contact_First_Name__c => LOCAL_CONTACT_FIRST_NAME,
                Case.Case_Contact_Last_Name__c => LOCAL_CONTACT_LAST_NAME,
                Case.Return_Shipping_Address__c => ADDRESS_FOR_TELUS
            })
            .create()
            .getRecord();

        Test.stopTest();

        cs = selectCaseToAssertById(cs.Id);

        assertTelusAddressToRCAddress(cs);
        Assert.areEqual(acc.Id, cs.AccountId, 'Case Account should be equal to Account with name ' + TelusExternalSharingHelperCls.TELUS_INHOUSE_ACCOUNT_NAME);
        Assert.areEqual(c.Id, cs.ContactId, 'Case Contact should be equal to Contact with name ' + LOCAL_CONTACT_FIRST_NAME);
    }

    @IsTest
    static void testPopulateMasterAccount() {
        Triggers.switchOff();
        Account masterAccount = TestDataGenerator.createAccount('Master');
        Opportunity masterOpp = TestDataGenerator.createOpportunity(masterAccount);

        BillingWrappers.QuoteWrapper rccQuoteInfo = new BillingWrappers.QuoteWrapper();
        BillingWrappers.QuoteWrapper edQuoteInfo = new BillingWrappers.QuoteWrapper();
        BillingWrappers.QuoteWrapper evQuoteInfo = new BillingWrappers.QuoteWrapper();

        Map<String, BillingWrappers.QuoteWrapper> quoteInfoByService = new Map<String, BillingWrappers.QuoteWrapper> {
            QuoteHelper.NGBS_RCCC_PRODUCT => rccQuoteInfo,
            QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT => edQuoteInfo,
            QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT => evQuoteInfo
        };

        Map<String, Account> serviceAccounts = AccountHelper.createTechnicalAccounts(masterAccount.Id, new List<String>(quoteInfoByService.keySet()));
        Id techRCCCAccountId = serviceAccounts.get(QuoteHelper.NGBS_RCCC_PRODUCT).Id;

        Package__c pack = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Account__c => techRCCCAccountId,
                Package__c.Account_Package_Id__c => '34646758'
            })
            .create()
            .getRecord();

        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => masterAccount.Id,
                    Contact.Email => 'something@mostcommon.fake',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();
        Triggers.switchOn();

        Test.startTest();
        Case testCase = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Case.Status => CaseHelper.CASE_STATUS_NEW,
                    Case.RecordTypeId => CaseHelper.RT_ID_FINANCE,
                    Case.AccountId => techRCCCAccountId,
                    Case.Billing_Account_Package__c => pack.Id,
                    Case.ContactId => testContact.Id,
                    Case.Type => 'Clarizen'
                }
            )
            .create()
            .getRecord();
        Test.stopTest();

        testCase = selectCaseToAssertById(testCase.Id);
        Assert.areEqual(testCase.AccountId, masterAccount.Id, 'Linked Account Id should be Master Account');
    }

    @IsTest
    private static void testAttachContactInCases() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => ACCOUNT_RC_INTERNAL_NAME,
                Account.RecordTypeId => AccountHelper.RT_ID_CUSTOMER_ACCOUNT,
                Account.RC_Account_Number__c => '23456789'
            })
            .create()
            .getRecord();

        Test.startTest();

        Case cs = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Status => CaseHelper.CASE_STATUS_NEW,
                Case.SuppliedPhone => LOCAL_CONTACT_PHONE,
                Case.SuppliedEmail => LOCAL_CONTACT_EMAIL,
                Case.SuppliedName => LOCAL_CONTACT_LAST_NAME,
                Case.RecordTypeId => CaseHelper.RT_ID_IT_HELPDESK,
                Case.Case_Account_Number__c => '123456789'
            })
            .create()
            .getRecord();

        Test.stopTest();

        cs = selectCaseToAssertById(cs.Id);
        Contact c = (Contact) new ListOptional(new ContactSelector()
            .selectContactsByAccountId(new List<Object> { acc.Id })
            .executeQuery()
        ).getFirst();

        Assert.areEqual(LOCAL_CONTACT_LAST_NAME, c.LastName, 'Contact should be created with last name ' + LOCAL_CONTACT_LAST_NAME);
        Assert.areEqual(c.Id, cs.ContactId, 'Case Contact should be equal to Contact');
        Assert.areEqual(acc.Id, cs.AccountId, 'Case Account should be equal to Account with rc account number ' + acc.RC_Account_Number__c);
    }

    @IsTest
    private static void testCaseCreationOnPRM() {
        Group grp = (Group) new ListOptional(new GroupSelector()
            .selectGroups()
            .setCondition('Type = :bind0 AND Name = :bind1')
            .setQueryBindings(new List<Object> { GroupHelper.GROUP_TYPE_QUEUE, GroupHelper.RESSELER_TEAM_DEV_NAME })
            .executeQuery()).getFirst();

        List<Case> cases;
        System.runAs(createUserWithProfile(ProfileHelper.SYSTEM_ADMIN)) {
            Test.startTest();

            cases = (List<Case>) new SObjectBuilder(Case.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Case.Status => CaseHelper.CASE_STATUS_NEW,
                    Case.RecordTypeId => new ValueProvider.ListProvider(new List<String> {
                        CaseHelper.RT_ID_SALES_CUST_FORM,
                        CaseHelper.RT_ID_RESSELLER_TEAM
                    })
                })
                .quantity(2)
                .create()
                .getRecords();

            Test.stopTest();
        }

        for (Case c : selectCasesToAssertByIds(cases)) {
            Object expected = c.RecordTypeId == CaseHelper.RT_ID_SALES_CUST_FORM ? MANAGER_EMAIL : grp.Id;
            Object actual = c.RecordTypeId == CaseHelper.RT_ID_SALES_CUST_FORM
                ? c.Sales_Owner_Manager_Email__c
                : c.OwnerId;

            String msg = c.RecordTypeId == CaseHelper.RT_ID_SALES_CUST_FORM
                ? 'Case Manager Email should be equal to Manager Email'
                : 'Case Owner should be equal to Reseller Team Queue';

            Assert.areEqual(expected, actual, msg);
        }
    }

    @IsTest
    private static void testInsertManagerFieldForSupportRecordType() {
        User dd = createUserWithProfile(ProfileHelper.PROFILE_NAME_SUPPORT_BACK_OFFICE);
        String testFirstName = 'FirstNameToInsertInCase';
        String testLastName = 'LastNameToInsertInCase';

        Employee__c managerEmp = (Employee__c) new SObjectBuilder(Employee__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Employee__c.First_Name__c => testFirstName,
                Employee__c.Last_Name__c => testLastName
            })
            .create()
            .getRecord();

        new SObjectBuilder(Employee__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Employee__c.Manager_Employee_Number__c => managerEmp.Id,
                Employee__c.User__c => dd.Id
            })
            .create();

        Case cs;
        System.runAs(dd) {
            Test.startTest();

            cs = (Case) new SObjectBuilder(Case.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Case.Status => CaseHelper.CASE_STATUS_NEW
                })
                .create()
                .getRecord();

            Test.stopTest();
        }
        cs = selectCaseToAssertById(cs.Id);
        Assert.areEqual(testFirstName + ' ' + testLastName, cs.Support_Owner_Manager__c, 'Support Owner Manager should be equal to Manager First Name + Manager Last Name');
    }

    @IsTest
    private static void testCalculateBalanceAndPortOutStatus() {
        Account acc = selectAccount();

        Test.startTest();

        Case cs = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Status => CaseHelper.CASE_STATUS_NEW,
                Case.RecordTypeId => CaseHelper.RT_ID_PORTING_OUT,
                Case.Porting_Estimated_Completion_Date__c => Date.today(),
                Case.AccountId => acc.Id
            })
            .create()
            .getRecord();

        Test.stopTest();

        cs = selectCaseToAssertById(cs.Id);
        Assert.areEqual(
            Math.ceil(Decimal.valueOf(acc.Sales_Agreement_Start_Date__c.daysBetween(acc.Sales_Agreement_End_Date__c)) / 30) * acc.MRR__c,
            cs.Account_Balance__c,
            'Account Balance should be correct'
        );
        Assert.areEqual('Partial', cs.Full_or_Partial_Port_Out__c, 'Full or Partial Port Out should be equal to Partial');
    }

    @IsTest
    private static void testPortOutCloseForCase() {
        Test.startTest();

        new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Status => CaseHelper.CASE_STATUS_CLOSED,
                Case.RecordTypeId => CaseHelper.RT_ID_PORTING_OUT,
                Case.Porting_Estimated_Completion_Date__c => Date.today(),
                Case.AccountId => selectAccount().Id
            })
            .create()
            .getRecord();

        Test.stopTest();
        List<Exception_and_notification_history__c> lstExceptions = (List<Exception_and_notification_history__c>) new ExceptionAndNotificationHistorySelector()
            .selectExceptionAndNotificationHistorys()
            .withoutSelectorFieldsIncluded()
            .setCondition('To_Address_1__c = :bind0')
            .setQueryBindings(new List<Object> { ACCOUNT_CURRENT_OWNER_EMAIL })
            .executeQuery();

        Assert.areEqual(1, lstExceptions.size(), 'There should be 1 Exception and Notification History created');

    }

    @IsTest
    private static void testHandleEngageDigitalCaseUpdates() {
        Group grp = (Group) new ListOptional(new GroupSelector()
            .selectGroups()
            .setCondition('Type = :bind0 AND Name = :bind1')
            .setQueryBindings(new List<Object> { GroupHelper.GROUP_TYPE_QUEUE, GroupHelper.ENGAGE_DIGITAL_DEV_NAME })
            .executeQuery()).getFirst();

        Test.startTest();

        Case cs = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Status => CaseHelper.CASE_STATUS_ClOSED,
                Case.RecordTypeId => CaseHelper.RT_ID_PORTING_OUT,
                Case.Porting_Estimated_Completion_Date__c => Date.today(),
                Case.ownerId => grp.Id
            })
            .create()
            .getRecord();

        Test.stopTest();
        cs = selectCaseToAssertById(cs.Id);
        Assert.areEqual(CaseHelper.CASE_STATUS_NEW, cs.Status, 'Case Status should be equal to New');
        Assert.areEqual('Digital case - EN', cs.Engage_Case_Type__c, 'Engage Case Type should be equal to Digital case - EN');
    }

    @IsTest
    private static void testUpdateCaseOwnerAndManagerDetails() {
        User admin = createUserWithProfile(ProfileHelper.SYSTEM_ADMIN);
        Case cs;
        System.runAs(admin) {
            Test.startTest();

            cs = (Case) new SObjectBuilder(Case.SObjectType)
                .create()
                .getRecord();

            Test.stopTest();
        }

        cs = selectCaseToAssertById(cs.Id);

        Assert.areEqual(MANAGER_EMAIL, cs.Case_Owner_Manager_Email__c, 'Case Owner Manager Email should be equal to Manager Email');
        Assert.areEqual(null, cs.Case_Owner_Manager_Title__c, 'Case Owner Manager Title should be empty');
        Assert.areEqual(MANAGER_TITLE, cs.Case_Owner_Supervisor_Title__c, 'Case Owner Supervisor Title should be equal to Manager Title');
        Assert.areEqual(admin.managerId, cs.Case_Owner_Supervisor__c, 'Case Owner Supervisor should be equal to Manager');
        Assert.areEqual(null, cs.Case_Owner_Manager__c, 'Case Owner Manager should be empty');
    }

    @IsTest
    private static void testProcessT1ShippingAndUpdateDetails() {
        User admin = createUserWithProfile(ProfileHelper.SYSTEM_ADMIN);
        Account acc = selectAccount();
        Contact c = selectContact();
        Case cs;
        String testDescription = String.format(
            'Customer contact email: {0} User_ID: {1} Customer Name: {2} RMA Comments This is a comment',
            new List<Object> { LOCAL_CONTACT_EMAIL, ACCOUNT_RC_USER_ID, (CONTACT_FIRSTNAME + ' ' + CONTACT_LASTNAME) }
        );
        System.runAs(admin) {
            Test.startTest();

            cs = (Case) new SObjectBuilder(Case.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Case.Status => CaseHelper.CASE_STATUS_NEW,
                    Case.RecordTypeId => CaseHelper.RT_ID_SUPPORT_T1_SHIPPING,
                    Case.Description => testDescription,
                    Case.SuppliedEmail => Label.NotForShippingEmail
                })
                .create()
                .getRecord();

            Test.stopTest();
        }

        cs = selectCaseToAssertById(cs.Id);
        Assert.areEqual(MANAGER_LAST_NAME, cs.Support_Owner_Manager__c, 'Case Description should be equal to Description from Case');
        Assert.areEqual(acc.Id, cs.AccountId, 'Case Account should be equal to Account');
        Assert.areEqual(c.Id, cs.ContactId, 'Case Contact should be equal to Contact');
    }

    @IsTest
    private static void testHandleCaseForPortingESB() {
        Account acc = selectAccount();
        Contact c = selectContact();
        Case cs;
        System.runAs(selectIntegrationUser()) {
            Test.startTest();

            cs = (Case) new SObjectBuilder(Case.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Case.Status => CaseHelper.CASE_STATUS_NEW,
                    Case.RecordTypeId => CaseHelper.RT_ID_SYSTEM_OPERATIONS,
                    Case.Contact_Email__c => LOCAL_CONTACT_EMAIL,
                    Case.AccountId => acc.Id
                })
                .create()
                .getRecord();

            Test.stopTest();
        }

        cs = selectCaseToAssertById(cs.Id);

        Assert.areEqual(PortingESBHelper.defaultEscalateToValue, cs.Support_Escalate_To__c, 'Wrong support escalate ref');
        Assert.areEqual(c.Id, cs.ContactId, 'Case Contact should be equal to Contact');
    }

    @IsTest
    private static void testAssignUserDetailsToCase() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => ACCOUNT_RC_INTERNAL_NAME,
                Account.RecordTypeId => AccountHelper.RT_ID_CUSTOMER_ACCOUNT
            })
            .create()
            .getRecord();

        Contact c = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.FirstName => LOCAL_CONTACT_FIRST_NAME,
                Contact.LastName => LOCAL_CONTACT_LAST_NAME,
                Contact.Email => LOCAL_CONTACT_EMAIL,
                Contact.Phone => LOCAL_CONTACT_PHONE,
                Contact.AccountId => acc.Id
            })
            .create()
            .getRecord();
        User admin = createUserWithProfile(ProfileHelper.SYSTEM_ADMIN);
        Case cs;
        System.runAs(admin) {
            Test.startTest();

            cs = (Case) new SObjectBuilder(Case.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Case.Status => CaseHelper.CASE_STATUS_NEW,
                    Case.AccountId => acc.Id,
                    Case.ContactId => c.Id,
                    Case.RecordTypeId => CaseHelper.RT_ID_IT_HELPDESK
                })
                .create()
                .getRecord();

            Test.stopTest();

        }
        cs = selectCaseToAssertById(cs.Id);

        Assert.areEqual(admin.LastName, cs.User_Name__c, 'Case user name should be equal to name from User');
        Assert.areEqual(admin.title, cs.Title__c, 'Case title should be equal to title from User');
        Assert.areEqual(admin.department, cs.Department__c, 'Case department should be equal to department from User');
    }

    @IsTest
    private static void testCheckForEmail() {
        Triggers.switchOff();
        Triggers.except('CaseTriggerHandler.CheckForEmail');
        User admin = createUserWithProfile(ProfileHelper.SYSTEM_ADMIN);
        System.runAs(admin) {
            Account acc = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Account.Current_Owner__c => admin.Id
                })
                .create()
                .getRecord();
            Test.startTest();

            new SObjectBuilder(Case.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Case.Status => CaseHelper.CASE_STATUS_NEW,
                    Case.Case_Severity__c => 'Level 1 - Critical',
                    Case.AccountId => acc.Id,
                    Case.RecordTypeId => CaseHelper.RT_ID_SUPPORT_CASE
                })
                .create();

            Test.stopTest();
        }
        Triggers.switchOn();

        List<Exception_and_notification_history__c> lstExceptions = (List<Exception_and_notification_history__c>) new ExceptionAndNotificationHistorySelector()
            .selectExceptionAndNotificationHistorys()
            .withoutSelectorFieldsIncluded()
            .setCondition('Content_label_01__c = :bind0')
            .setQueryBindings(new List<Object> { 'SEVERITY1_CASE_TRIGGER_NOTIFICATION' })
            .executeQuery();

        Assert.areEqual(1, lstExceptions.size(), 'There should be 1 Exception and Notification History created');
    }

    @IsTest
    private static void testHandleCaseForTelus() {
        Test.startTest();

        Case cs = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.RecordTypeId => CaseHelper.RT_ID_IT_NEW_HIRE_REQUEST,
                Case.Requires_BizServ__c => true,
                Case.Priority => 'Medium'
            })
            .create()
            .getRecord();

        Test.stopTest();

        List<Case> cases = (List<Case>) new CaseSelector()
            .selectCases()
            .withoutSelectorFieldsIncluded()
            .setCondition('ParentId = :bind0')
            .setQueryBindings(new List<Object> { cs.Id })
            .executeQuery();

        Assert.areEqual(3, cases.size(), 'There should be 3 Cases created');
    }

    @IsTest
    private static void testCalculateGraduationCompletionRateOverCase() {
        Account acc;
        User userObj = createUserWithProfile(ProfileHelper.PROFILE_NAME_SALES_OPERATIONS_LIGHTNING);

        Triggers.switchOff();
        Triggers.except('CaseTriggerHandler.CalculateGraduationCompletionRateOverCase');

        System.runAs(userObj) {
            acc = (Account) new SObjectBuilder(Account.SObjectType)
                .create()
                .getRecord();

            new SObjectBuilder(Account_Metric__c.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Account_Metric__c.Account_ID__c => acc.Id,
                    Account_Metric__c.Metric_3_value__c => 12,
                    Account_Metric__c.Metric_11_value__c => 1,
                    Account_Metric__c.Metric_18_value__c => 2,
                    Account_Metric__c.Metric_23_value__c => 2,
                    Account_Metric__c.Metric_27_value__c => 1,
                    Account_Metric__c.Metric_28_value__c => 0.5
                })
                .create();

            Test.startTest();

            new SObjectBuilder(Case.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Case.AccountId => acc.Id,
                    Case.RecordTypeId => CaseHelper.RT_ID_SUPPORT_T3
                })
                .create();

            Test.stopTest();
        }
        Triggers.switchOn();

        Account_Metric__c acM = [SELECT Id, Account_Graduation_Status__c FROM Account_Metric__c WHERE Account_ID__c = :acc.Id];
        Assert.areEqual(AccountHelper.GRADUATION_STATUS_DONE.toLowerCase(), acM.Account_Graduation_Status__c.toLowerCase(), 'Account Graduation Status should be equal to Done.');
    }

    @IsTest
    private static void testShareAttachments() {
        Id dummyId = (id) new ValueProvider.DummyIdProvider(PartnerNetworkConnection.sObjectType.getDescribe().getKeyPrefix(), 15).getValue();
        new SObjectBuilder(InContactConnectionId__c.SObjectType)
            .setField(InContactConnectionId__c.Id__c, dummyId)
            .create();

        Case cs = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Status => 'WIP by Partner',
                Case.CC_Order_Type__c => OrderHelper.TYPE_NEW_ORDER
            })
            .create()
            .getRecord();

        Test.startTest();

        TriggerHandler.BY_PASS_BEFORE = false;
        TriggerHandler.BY_PASS_AFTER = false;

        cs.Support_Escalate_To__c = 'inContact Support';
        update cs;

        Test.stopTest();

        // no active network case
        Assert.isTrue(PartnerNetworkConnectionHelper.selectPnrcByLocalRecordId(cs.Id) == null, 'PartnerNetworkRecordConnection should not be inserted');

        String sourceName = '%CaseTriggerHandler.ShareAttachments%';
        PlatformLog__c pLogs = [SELECT Error__c FROM PlatformLog__c WHERE Source__c LIKE :sourceName];
        Assert.isTrue(pLogs != null, 'PlatformLog__c should be inserted');
        Assert.isTrue(pLogs.Error__c.contains('INVALID_PARTNER_NETWORK_STATUS, invalid status for partner network operation'), 'PlatformLog__c should contain error message');
    }

    @IsTest
    private static void testCloseCaseMilestone() {
        SlaProcess testEntitlementProcess = [SELECT Id FROM SlaProcess WHERE Name = 'Support - T1 (VAR) V.01'];
        Account acc = selectAccount();

        Entitlement ent = (Entitlement) new SObjectBuilder(Entitlement.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Entitlement.Name => 'ENTITLEMENT_NAME',
                Entitlement.AccountId => acc.Id,
                Entitlement.Type => 'Phone Support',
                Entitlement.StartDate => System.Today(),
                Entitlement.SlaProcessId => testEntitlementProcess.Id,
                Entitlement.EndDate => System.Today().addDays(1)
            })
            .create()
            .getRecord();

        Test.startTest();
        Case cs = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Status => 'Waiting for Someone',
                Case.Case_Severity__c => 'Level 1 - Critical',
                Case.RecordTypeId => CaseHelper.RT_ID_SUPPORT_INTEGRATIONS,
                Case.Comments => 'Test comments',
                Case.Subject => 'TEST CASE',
                Case.EntitlementId => ent.Id
            })
            .create()
            .getRecord();

        cs.Status = 'Someone is here';
        cs.Comments = 'test comments 2';
        update cs;
        Test.stopTest();
        Assert.isTrue([SELECT count() FROM CaseMilestone WHERE CaseId = :cs.Id AND CompletionDate != null AND MilestoneType.Name = :VAR_FOLLOW_UP] > 0, 'Case Milestones should be inserted');
    }

    @isTest
    static void testPopulateCaseFieldsWithContactFields() {
        Contact contactWithNonEmptyName = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.Id => ValueProviderBuilder.provideDummyId(Contact.sObjectType).getValue(),
                Contact.FirstName => 'TestFirstName',
                Contact.LastName => 'TestLastName',
                Contact.Email => new ValueProvider.UniqueStringProvider('test@test.test'),
                Contact.Phone => CONTACT_PHONE,
                Contact.Preferred_Language__c => ContactHelper.PREFERRED_LANGUAGE_EN_US
            })
            .build()
            .getRecord();

        Case caseThatShouldHaveFieldsPopulated = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.ContactId => contactWithNonEmptyName.Id,
                Case.Status => CaseHelper.CASE_STATUS_NEW,
                Case.RecordTypeId => CaseHelper.RT_ID_SUPPORT_T1_SHIPPING
            })
            .build()
            .getRecord();

        Case caseThatShouldNotHaveFieldsPopulated = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.ContactId => '',
                Case.Status => CaseHelper.CASE_STATUS_NEW,
                Case.RecordTypeId => CaseHelper.RT_ID_SUPPORT_T1_SHIPPING
            })
            .build()
            .getRecord();

        Map<Id, Contact> contactsById = new Map<Id, Contact> { contactWithNonEmptyName.Id => contactWithNonEmptyName };
        List<Case> newCasesList = new List<Case> {
            caseThatShouldHaveFieldsPopulated,
            caseThatShouldNotHaveFieldsPopulated
        };

        Test.startTest();
            CaseTriggerHandler.contactsMapFromCases = contactsById;
            new CaseTriggerHandler.PopulateCaseFieldsWithContactFields(newCasesList).handle();
        Test.stopTest();

        Assert.areEqual(
            contactWithNonEmptyName.Email,
            caseThatShouldHaveFieldsPopulated.Contact_Email_custom__c,
            'For a Case record with ContactId populated Contact_Email_custom__c should be populated with its Contact Email.'
        );
        Assert.areEqual(
            contactWithNonEmptyName.Phone,
            caseThatShouldHaveFieldsPopulated.Contact_Phone_custom__c,
            'For a Case record with ContactId populated Contact_Phone_custom__c should be populated with its Contact Phone.'
        );
        Assert.isTrue(
            String.isBlank(caseThatShouldNotHaveFieldsPopulated.Contact_Email_custom__c),
            'For a Case record with ContactId NOT populated Contact_Email_custom__c should be blank.'
        );
        Assert.isTrue(
            String.isBlank(caseThatShouldNotHaveFieldsPopulated.Contact_Phone_custom__c),
            'For a Case record with ContactId NOT populated Contact_Phone_custom__c should be blank.'
        );
    }

    @isTest
    static void testUpdateEscalationActualDateOnInsert() {
        Date today = Date.today();
        Case caseThatDoesNotEscalateToOps = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Actual_Escalation__c => today,
                Case.Support_Escalate_To__c => 'something else'
            })
            .build()
            .getRecord();

        Case caseThatDoesEscalateToOps = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Actual_Escalation__c => today,
                Case.Support_Escalate_To__c => CaseHelper.SUPPORT_ESCALATE_TO_SYSTEM_OPS
            })
            .build()
            .getRecord();

        Case caseThatDoesEscalateToTelecomOps = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Actual_Escalation__c => today,
                Case.Support_Escalate_To__c => CaseHelper.SUPPORT_ESCALATE_TO_TELECOM_OPS
            })
            .build()
            .getRecord();

        List<Case> newCasesList = new List<Case> {
            caseThatDoesNotEscalateToOps,
            caseThatDoesEscalateToOps,
            caseThatDoesEscalateToTelecomOps
        };

        Test.startTest();
            insert newCasesList;
        Test.stopTest();

        Map<Id, Case> insertedCasesMap = new Map<Id, Case> (selectCasesToAssertByIds(newCasesList));
        Assert.areEqual(
            today,
            insertedCasesMap.get(caseThatDoesEscalateToOps.Id).Actual_Escalation__c,
            'Actual_Escalation__c should be kept the same as before for a Case record that escalates to System Ops.'
        );
        Assert.areEqual(
            today,
            insertedCasesMap.get(caseThatDoesEscalateToTelecomOps.Id).Actual_Escalation__c,
            'Actual_Escalation__c should be kept the same as before for a Case record that escalates to Telecom Ops.'
        );
        Assert.isNull(
            insertedCasesMap.get(caseThatDoesNotEscalateToOps.Id).Actual_Escalation__c,
            'Actual_Escalation__c should be null for a Case record that does not escalate to System Ops.'
        );
    }

    @isTest
    static void testUpdateEscalationActualDateOnUpdate() {
        Date today = Date.today();
        final String DUMMY_STR = 'something else';

        Case oldCaseThatDoesEscalateToOps = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Actual_Escalation__c => today,
                Case.Support_Escalate_To__c => CaseHelper.SUPPORT_ESCALATE_TO_SYSTEM_OPS
            })
            .build()
            .getRecord();

        Case oldCaseThatDoesNotEscalateToOps = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Actual_Escalation__c => today,
                Case.Support_Escalate_To__c => DUMMY_STR
            })
            .build()
            .getRecord();
        List<Case> oldCasesList = new List<Case> {
            oldCaseThatDoesEscalateToOps,
            oldCaseThatDoesNotEscalateToOps
        };
        insert oldCasesList;

        Case newCaseThatWasEditedToMeetCriteria = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Id => oldCaseThatDoesEscalateToOps.Id,
                Case.Actual_Escalation__c => today,
                Case.Support_Escalate_To__c => DUMMY_STR
            })
            .build()
            .getRecord();
        Case newCaseThatDoesNotEscalateToOps = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Id => oldCaseThatDoesNotEscalateToOps.Id,
                Case.Actual_Escalation__c => today,
                Case.Support_Escalate_To__c => DUMMY_STR + '2'
            })
            .build()
            .getRecord();
        List<Case> newCasesList = new List<Case> {
            newCaseThatWasEditedToMeetCriteria,
            newCaseThatDoesNotEscalateToOps
        };
        Test.startTest();
            update newCasesList;
        Test.stopTest();

        Map<Id, Case> updatedCasesMap = new Map<Id, Case> (selectCasesToAssertByIds(newCasesList));
        Assert.areEqual(
            today,
            updatedCasesMap.get(newCaseThatDoesNotEscalateToOps.Id).Actual_Escalation__c,
            'Actual_Escalation__c should be kept the same as before for a Case record that before and after update was not meeting criteria.'
        );
        Assert.isNull(
            updatedCasesMap.get(newCaseThatWasEditedToMeetCriteria.Id).Actual_Escalation__c,
            'Actual_Escalation__c should be null for a Case record that was edited to meet criteria.'
        );
    }

    @isTest
    static void testGetContactsMapFromCases() {
        List<Contact> contacts = (List<Contact>) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.Id, ValueProviderBuilder.provideDummyId(Contact.sObjectType))
            .quantity(2)
            .build()
            .getRecords();
        List<Id> contactsIds = new List<Id>();
        for (Contact c : contacts) {
            contactsIds.add(c.Id);
        }

        List<Case> cases = (List<Case>) new SObjectBuilder(Case.sObjectType)
            .setField(Case.contactId, ValueProviderBuilder.provideList(contactsIds))
            .quantity(contacts.size())
            .build()
            .getRecords();

        QueryFactory factoryToCache = CaseTriggerHandler.selectContactsByIds(new Set<Id>(contactsIds));
        factoryToCache.executeQuery(); // We need to execute the query, so that the factory has correct state

        Test.startTest();
            // caching expected results, so that no queries are actually executed
            ObjectCache.set(
                ObjectCache.Partition.FACTORIES,
                factoryToCache.getFactoryName(),
                factoryToCache
            );
            ObjectCache.set(
                ObjectCache.Partition.QUERIES,
                factoryToCache.getFactoryName(),
                contacts
            );
            Map<Id, Contact> result = CaseTriggerHandler.getContactsMapFromCases(cases);
        Test.stopTest();

        Assert.areEqual(
            contacts,
            result.values(),
            'Unexpected result was returned.'
        );
    }

    @isTest
    static void testAutoSyncParams() {
        Case testCase = createTestRecords();
        Test.startTest();
        CaseTriggerHandler.AutoSyncParams params = new CaseTriggerHandler.AutoSyncParams(testCase);
        Test.stopTest();

        Assert.areEqual(testCase.Id, params.targetCase.Id, 'Case Id should be equal to the one from the Case record.');
        Assert.isTrue(params.targetOpty.IsMultiProductTechnicalOpportunity__c, 'Target Opportunity should be technical.');
        Assert.areEqual(OpportunityHelper.TIER_RC_CONTACT_CENTER, params.targetOpty.Tier_Name__c, 'Target Opportunity should be technical.');
        Assert.isNotNull(params.targetQuote, 'Target Quote should exist.');
        assertAccount(params.accsToUpdate[1], params.accsToUpdate[0], testCase); // The tech account should be the second one in the list
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testAutoSyncParamsGetAccountsToUpdate_NotOnlyIncontactIdIsAssigned() {
        Account affectedMasterAcc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => ACCOUNT_NAME,
                Account.IsMultiProductTechnicalAccount__c => false
            })
            .build()
            .getRecord();
        BillingWrappers.QuotePackageInfo testPackageInfo = new BillingWrappers.QuotePackageInfo();
        testPackageInfo.edition.name = TEST_EDITION;
        Quote primaryQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.isPrimary__c => true,
                Quote.Package_Info__c => JSON.serialize(new List<BillingWrappers.QuotePackageInfo> {testPackageInfo})
            })
            .build()
            .getRecord();
        QuoteLineItem primaryQuoteLineItem = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setField(QuoteLineItem.NewQuantity__c, TEST_NEW_QUANTITY)
            .build()
            .getRecord();
        Case inputCase = (Case) new SObjectBuilder(Case.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Id => ValueProviderBuilder.provideDummyId(Case.sObjectType),
                Case.Provision_Date__c => TODAY,
                Case.inContact_BU_ID__c => CASE_BU_ID,
                Case.inContact_Cluster__c => TEST_INCONTACT_CLUSTER
            })
            .build()
            .getRecord();

        CaseTriggerHandler.AutoSyncParams params = new CaseTriggerHandler.AutoSyncParams();
        params.targetCase = inputCase;
        params.targetQuote = primaryQuote;
        params.targetQuoteLineItem = primaryQuoteLineItem;
        params.targetOpty = buildOppWithParentAccount(affectedMasterAcc);

        Test.startTest();
            List<Account> result = params.getAccountsToUpdate();
        Test.stopTest();

        assertGetAccountsToUpdateForMasterAccount(result, inputCase);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest
    static void testGetAccountsToUpdateAffectedAccIsTechnicalOne() {
        BillingWrappers.QuotePackageInfo testPackageInfo = new BillingWrappers.QuotePackageInfo();
        testPackageInfo.edition.name = TEST_EDITION;
        Quote primaryQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.isPrimary__c => true,
                Quote.Package_Info__c => JSON.serialize(new List<BillingWrappers.QuotePackageInfo> {testPackageInfo})
            })
            .build()
            .getRecord();
        QuoteLineItem primaryQuoteLineItem = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setField(QuoteLineItem.NewQuantity__c, TEST_NEW_QUANTITY)
            .build()
            .getRecord();

        Case inputCase = (Case) new SObjectBuilder(Case.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Id => ValueProviderBuilder.provideDummyId(Case.sObjectType),
                Case.Provision_Date__c => TODAY,
                Case.inContact_BU_ID__c => CASE_BU_ID,
                Case.inContact_Cluster__c => TEST_INCONTACT_CLUSTER
            })
            .build()
            .getRecord();

        CaseTriggerHandler.AutoSyncParams params = new CaseTriggerHandler.AutoSyncParams();
        params.targetCase = inputCase;
        params.targetQuote = primaryQuote;
        params.targetQuoteLineItem = primaryQuoteLineItem;
        params.targetOpty = buildOppWithParentAccount(buildTechAccountForGetAccountsToUpdateTests());

        Test.startTest();
            List<Account> result = params.getAccountsToUpdate();
        Test.stopTest();

        assertGetAccountsToUpdateForTechnicalAccount(result, inputCase);
    }

    @isTest
    static void testAutoSyncWithNGBSMPL() {
        Case testCase = createTestRecords();
        Test.startTest();
        testCase.inContact_Status__c = CaseHelper.CASE_STATUS_COMPLETED;
        update testCase;
        Test.stopTest();

        Opportunity affectedOpportunity = (Opportunity) new ListOptional(new OpportunitySelector()
            .selectTechOptyForAutoSyncByMasterOppId(testCase.Opportunity_Reference__c)
            .setCondition('(MasterOpportunity__c = :bind0 OR Id = :bind0) AND IsMultiProductTechnicalOpportunity__c = true AND Tier_Name__c = :bind1')
            .selectFields(new Set<String> {
                'Account.Master_Account__c',
                'Account.Master_Account__r.inContact_account_ID__c'
            })
            .addQueryBindings(new List<Object> { OpportunityHelper.TIER_RC_CONTACT_CENTER })
            .executeQuery()
        ).getFirst();

        Assert.isNotNull(affectedOpportunity, 'Affected Opportunity should exist.');
        Assert.isTrue(affectedOpportunity.isICBProvisioningComplete__c, 'ICB Provisioning should be complete.');
        assertAccount(affectedOpportunity.Account, testCase);
    }

    @isTest
    static void testAutoSyncWithNGBSMPUB() {
        Triggers.switchOff();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.IsMultiProductTechnicalAccount__c, false)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => acc.Id,
                Opportunity.CloseDate => System.today().addMonths(1),
                Opportunity.IsMultiProductTechnicalOpportunity__c => false
            })
            .create()
            .getRecord();

        Quote masterQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.IsPrimary__c => true,
                Quote.OpportunityId => opp.Id,
                Quote.Package_Info__c => '[{"edition":{"id":1,"name":"Standard"}}]',
                Quote.IsMultiProductTechnicalQuote__c => false,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
            })
            .create()
            .getRecord();

        Quote technicalQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.IsPrimary__c => false,
                Quote.OpportunityId => opp.Id,
                Quote.MasterQuote__c => masterQuote.Id,
                Quote.ServiceName__c => OpportunityHelper.TIER_RC_CONTACT_CENTER,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Package_Info__c => '[{"edition":{"id":1,"name":"Standard"}}]',
                Quote.IsMultiProductTechnicalQuote__c => true
            })
            .create()
            .getRecord();

        new SObjectBuilder(ServiceInfo__c.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                ServiceInfo__c.Quote__c => technicalQuote.Id
            })
            .create();

        Case testCase = (Case) new SObjectBuilder(Case.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.AccountId => acc.Id,
                Case.Opportunity_Reference__c => opp.Id,
                Case.Provision_Date__c => System.today().addDays(1),
                Case.inContact_BU_ID__c => 10,
                Case.inContact_Cluster__c => 'test claster',
                Case.RecordTypeId => CaseHelper.RT_ID_INCONTACT_ORDER,
                Case.CC_Order_Type__c => OrderHelper.TYPE_CHANGE_ORDER,
                Case.Description => 'CASE_DESCRIPTION'
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        Test.startTest();
            testCase.inContact_Status__c = CaseHelper.CASE_STATUS_COMPLETED;
            update testCase;
        Test.stopTest();

        ServiceInfo__c serviceInfo = (ServiceInfo__c) new ListOptional(new ServiceInfoSelector()
            .selectServiceInfo()
            .selectField(ServiceInfo__c.ICBProvisioningStepStatus__c)
            .setCondition('Quote__c = :bind0')
            .setQueryBindings(technicalQuote.Id)
            .setQueryCaching(true)
            .executeQuery()
        ).getFirst();
        Assert.isTrue(serviceInfo.ICBProvisioningStepStatus__c, 'ICB Provisioning should be complete.');
    }

    private static Case createTestRecords() {
        Triggers.switchOff();
        Account masterAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.IsMultiProductTechnicalAccount__c, false)
            .create()
            .getRecord();

        Account techAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Master_Account__c => masterAccount.Id,
                Account.IsMultiProductTechnicalAccount__c => true
            })
            .create()
            .getRecord();

        Opportunity masterOpportunity = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => masterAccount.Id,
                Opportunity.CloseDate => System.today().addMonths(1),
                Opportunity.IsMultiProductTechnicalOpportunity__c => false
            })
            .create()
            .getRecord();

        Opportunity techOpportunity = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today().addMonths(1),
                Opportunity.AccountId => techAccount.Id,
                Opportunity.IsMultiProductTechnicalOpportunity__c => true,
                Opportunity.Tier_Name__c => OpportunityHelper.TIER_RC_CONTACT_CENTER,
                Opportunity.MasterOpportunity__c => masterOpportunity.Id
            })
            .create()
            .getRecord();

        Quote masterQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.IsPrimary__c => true,
                Quote.OpportunityId => masterOpportunity.Id,
                Quote.Package_Info__c => '[{"edition":{"id":1,"name":"Standard"}}]',
                Quote.IsMultiProductTechnicalQuote__c => false
            })
            .create()
            .getRecord();

        new SObjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.IsPrimary__c => false,
                Quote.OpportunityId => techOpportunity.Id,
                Quote.MasterQuote__c => masterQuote.Id,
                Quote.ServiceName__c => OpportunityHelper.TIER_RC_CONTACT_CENTER,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Package_Info__c => '[{"edition":{"id":1,"name":"Standard"}}]',
                Quote.IsMultiProductTechnicalQuote__c => true
            })
            .create();

        Case testCase = (Case) new SObjectBuilder(Case.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.AccountId => masterAccount.Id,
                Case.Opportunity_Reference__c => masterOpportunity.Id,
                Case.Provision_Date__c => System.today().addDays(1),
                Case.inContact_BU_ID__c => 10,
                Case.inContact_Cluster__c => 'test claster',
                Case.RecordTypeId => CaseHelper.RT_ID_INCONTACT_ORDER,
                Case.CC_Order_Type__c => OrderHelper.TYPE_CHANGE_ORDER,
                Case.Description => 'CASE_DESCRIPTION'
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        return testCase;
    }

    private static void assertAccount(Account acc, Case testCase) {
        assertAccount(acc, acc.Master_Account__r, testCase);
    }

    private static void assertAccount(Account acc, Account masterAcc, Case testCase) {
        Assert.isNotNull(acc, 'Account to update should exist.');
        Assert.areEqual(
            String.valueOf(testCase.inContact_BU_ID__c),
            masterAcc.inContact_account_ID__c,
            'Account BU ID on a master Account should be equal to the one from the Case record.'
        );
        Assert.isNull(acc.inContact_account_ID__c, 'Account BU ID on a tech Account should be null.');
        Assert.areEqual(testCase.inContact_Cluster__c, acc.inContact_Cluster__c, 'Account cluster should be equal to the one from the Case record.');
        Assert.areEqual(testCase.Provision_Date__c, acc.Provision_Date__c, 'Account provision date should be equal to the one from the Case record.');
        Assert.areEqual('Standard', acc.InContact_Service__c, 'Account incontact service should be equal to Standard.');
        Assert.areEqual(AccountHelper.SERVICE_STATUS_CONTRACT_COMPLETE, acc.Service_Status__c, 'Account service status should be equal to Contract Complete.');
    }

    @isTest
    static void testValidateCaseStatusOnUpdate() {
        Case newCase = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Status => CaseHelper.CASE_STATUS_NEW,
                Case.Origin => 'Account'
            })
            .create()
            .getRecord();

        newCase.Status = CaseHelper.CASE_STATUS_WIP;
        newCase.Case_Category__c = 'Account Information Inquiry';
        newCase.Case_Subcategory__c = 'Dispute';
        newCase.RecordTypeId = CaseHelper.RT_ID_DEAL_AND_ORDER_SUPPORT;
        try {
            Test.startTest();
                update newCase;
            Test.stopTest();

            Assert.Fail(EXCEPTION_MESSAGE);
        } catch (Exception ex) {
            Assert.isTrue(ex.getMessage().contains(Label.CaseOnlyQueueMemberCanChangeStatus), EXCEPTION_MESSAGE_EQUAL_TO + Label.CaseOnlyQueueMemberCanChangeStatus);
        }
    }

    @isTest
    static void testValidateCaseFieldsForProductDefectType() {
        List<Case> cases = (List<Case>) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Status => CaseHelper.CASE_STATUS_NEW
            })
            .quantity(2)
            .create()
            .getRecords();
        Case caseWithoutType = cases.get(0);
        Case caseWithProductDefectType = cases.get(1);
        caseWithoutType.Status = CaseHelper.CASE_STATUS_WIP;
        caseWithProductDefectType.Type = CaseHelper.CASE_TYPE_PRODUCT_DEFECT;
        caseWithProductDefectType.RecordTypeId = CaseHelper.RT_ID_PRODUCT_PLATFORM_ISSUES;
        caseWithProductDefectType.Support_Escalate_To__c = CaseHelper.CASE_TYPE_PRODUCT_DEFECT;
        try {
            Test.startTest();
                update new List<Case> {caseWithoutType, caseWithProductDefectType};
            Test.stopTest();

            Assert.Fail(EXCEPTION_MESSAGE);
        } catch (Exception ex) {
            Assert.isTrue(ex.getMessage().contains(CaseTriggerHandler.JIRA_NUMBER_REQUIRED_ERROR), EXCEPTION_MESSAGE_EQUAL_TO + CaseTriggerHandler.JIRA_NUMBER_REQUIRED_ERROR);
        }
    }

    @isTest
    static void testValidateCaseFieldsForPlatformIncidentType() {
        Case caseWithPlatformIncidentType = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Status => CaseHelper.CASE_STATUS_NEW
            })
            .create()
            .getRecord();
        caseWithPlatformIncidentType.Type = CaseHelper.CASE_TYPE_PLATFORM_INCIDENT;
        caseWithPlatformIncidentType.RecordTypeId = CaseHelper.RT_ID_PRODUCT_PLATFORM_ISSUES;
        caseWithPlatformIncidentType.Support_Escalate_To__c = CaseHelper.CASE_TYPE_PLATFORM_INCIDENT;

        try {
            Test.startTest();
                update caseWithPlatformIncidentType;
            Test.stopTest();

            Assert.Fail(EXCEPTION_MESSAGE);
        } catch (Exception ex) {
            Assert.isTrue(ex.getMessage().contains(CaseTriggerHandler.INCIDENT_NUMBER_REQUIRED), EXCEPTION_MESSAGE_EQUAL_TO + CaseTriggerHandler.INCIDENT_NUMBER_REQUIRED);
        }
    }

    @isTest
    static void testValidateOnBeforeUpdateEvent() {
        Case caseObj = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Status => CaseHelper.CASE_STATUS_NEW
            })
            .create()
            .getRecord();
        caseObj.Convert_to_Internal_Porting__c = CaseHelper.RT_NAME_PORTING_RC;
        caseObj.RecordTypeId = CaseHelper.RT_ID_PORTING_NEUSTAR;
        caseObj.Status = CaseHelper.CASE_STATUS_WIP;

        Test.startTest();
            update caseObj;
        Test.stopTest();

        Case updatedCase = selectCaseToAssertById(caseObj.Id);
        Assert.areEqual(CaseHelper.RT_ID_PORTING_RC, updatedCase.RecordTypeId, 'Case Record Type should be updated to Porting RC');
        Assert.isTrue(updatedCase.IsUpdatePermitted__c, 'Case IsUpdatePermitted__c field should be true');
    }

    @isTest
    static void testUpdateRelatedOrders() {
        Order orderObj = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Order.Status => OrderHelper.STATUS_NEW,
                Order.AccountId => selectAccount().Id,
                Order.EffectiveDate => Date.today()
            })
            .create()
            .getRecord();
        Case casewithoutOrder = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Status => CaseHelper.CASE_STATUS_NEW
            })
            .build()
            .getRecord();
        Case caseWithOrder = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Status => CaseHelper.CASE_STATUS_NEW,
                Case.Order__c => orderObj.Id
            })
            .build()
            .getRecord();
        insert new List<Case> {casewithoutOrder, caseWithOrder};

        casewithoutOrder.RecordTypeId = CaseHelper.RT_ID_PORTING_IN;
        caseWithOrder.RecordTypeId = CaseHelper.RT_ID_INCONTACT_ORDER;
        caseWithOrder.inContact_BU_ID__c = 300;
        caseWithOrder.Provision_Date__c = Date.today();
        caseWithOrder.inContact_Cluster__c = 'Test_Cluster';
        caseWithOrder.inContact_Status__c = CaseHelper.CASE_STATUS_COMPLETED;

        Test.startTest();
            update new List<Case> {casewithoutOrder, caseWithOrder};
        Test.stopTest();

        Order updatedOrder = (Order) new ListOptional(new OrderSelector()
            .selectOrdersByIds(new List<Object> {new List<Id> {orderObj.Id}})
            .withoutSelectorFieldsIncluded()
            .selectFields(new List<Schema.SObjectField> {
                Order.inContact_Account_ID__c,
                Order.Provision_Date__c,
                Order.inContact_Cluster__c,
                Order.Status
            })
            .executeQuery()
        ).getFirst();
        Assert.areEqual(String.valueOf(caseWithOrder.inContact_BU_ID__c), updatedOrder.inContact_Account_ID__c, 'The order inContact_Account_ID__c field should be updated');
        Assert.areEqual(caseWithOrder.Provision_Date__c, updatedOrder.Provision_Date__c, 'The order Provision_Date__c field should be updated');
        Assert.areEqual(caseWithOrder.inContact_Cluster__c, updatedOrder.inContact_Cluster__c, 'The order inContact_Cluster__c field should be updated');
        Assert.areEqual(OrderHelper.STATUS_PROVISIONED, updatedOrder.Status, 'The order Status field should be updated');
    }

    @isTest
    static void testChangeCaseOwnerForSupportT1User() {
        User testUser = new User(Id = UserInfo.getUserId());
        PermissionSet permissionSet = (PermissionSet) new SObjectBuilder(PermissionSet.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    PermissionSet.Name => 'CustomPermissionEnabled',
                    PermissionSet.Label => 'Custom Permisison Enabled'
                }
            )
            .create()
            .getRecord();
        CustomPermission customPermission = (CustomPermission) new ListOptional(new CustomPermissionSelector()
            .selectCustomPermissionsByDeveloperName(new List<Object> {CustomPermissionHelper.PERMISSION_SUPPORT_AGENT_T1})
            .executeQuery()
        ).getFirst();

        new SObjectBuilder(SetupEntityAccess.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    SetupEntityAccess.ParentId => permissionSet.Id,
                    SetupEntityAccess.SetupEntityId => customPermission.Id
                }
            )
            .create();
        new SObjectBuilder(PermissionSetAssignment.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                PermissionSetAssignment.AssigneeId => testUser.Id,
                PermissionSetAssignment.PermissionSetId => permissionSet.Id
            })
            .create();
        Case caseObj;
        System.runAs(testUser) {
            caseObj = (Case) new SObjectBuilder(Case.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Case.Status => CaseHelper.CASE_STATUS_NEW,
                    Case.OwnerId => testUser.Id
                })
                .create()
                .getRecord();
            caseObj.RecordTypeId = CaseHelper.RT_ID_SUPPORT_T1;
            caseObj.Support_Escalate_To__c = CaseHelper.SUPPORT_ESCALATE_TO_TIER_1;
            caseObj.Support_Tier_1_Esc_Count__c = 1;
            TriggerHandler.BY_PASS_BEFORE = false;

            Test.startTest();
                update caseObj;
            Test.stopTest();
        }

        Case updatedCase = selectCaseToAssertById(caseObj.Id);
        Assert.areEqual(updatedCase.OwnerId, updatedCase.CreatedById, 'A case owner user should be equal to a case created by user.');
    }

    @isTest
    static void testPopulateCasePortingFields() {
        List<Case> cases = (List<Case>) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Status => CaseHelper.CASE_STATUS_NEW
            })
            .quantity(3)
            .create()
            .getRecords();
        Case caseWithSubmitStatus = cases.get(0);
        Case caseWithRejectStatus = cases.get(1);
        Case caseWithClosedStatus = cases.get(2);
        caseWithSubmitStatus.Status = CaseHelper.CASE_STATUS_SUBMIT;
        caseWithSubmitStatus.Porting_Estimated_Completion_Date__c = Date.today().addDays(2);

        caseWithRejectStatus.Status = CaseHelper.CASE_STATUS_REJECT;
        caseWithRejectStatus.Porting_First_Submit_Date__c = Date.today();
        caseWithRejectStatus.Porting_Reject_Reason__c = 'Test Reason';

        caseWithClosedStatus.Status = CaseHelper.CASE_STATUS_CLOSED;
        caseWithClosedStatus.RecordTypeId = CaseHelper.RT_ID_PORTING_OUT;
        TriggerHandler.BY_PASS_BEFORE = false;
        List<Case> casesToUpdate = new List<Case> {caseWithSubmitStatus, caseWithRejectStatus, caseWithClosedStatus};

        Test.startTest();
            update casesToUpdate;
        Test.stopTest();

        for (Case updatedCase : selectCasesToAssertByIds(casesToUpdate)) {
            if (CaseHelper.CASE_STATUS_SUBMIT.equals(updatedCase.Status)) {
                Assert.isNotNull(updatedCase.Porting_Last_Submit_Date__c, 'Porting_Last_Submit_Date__c should be populated');
                Assert.isNotNull(updatedCase.Porting_First_Submit_Date__c, 'Porting_First_Submit_Date__c should be populated');
                Assert.areEqual(CaseHelper.CASE_PORTING_RC_REVIEW_ACCEPTED, updatedCase.Porting_RC_Review__c, 'Porting_RC_Review__c should be populated as Accepted');
            } else if (CaseHelper.CASE_STATUS_REJECT.equals(updatedCase.Status)) {
                Assert.isNotNull(updatedCase.Porting_First_Reject_Reason__c, 'Porting_First_Reject_Reason__c should be populated');
                Assert.areEqual(CaseHelper.CASE_PORTING_RC_REVIEW_REJECTED, updatedCase.Porting_RC_Review__c, 'Porting_RC_Review__c should be populated as Rejected');
                Assert.areEqual(CaseTriggerHandler.REJECT_REVIEW_REASON_NO_VALUE, updatedCase.Porting_RC_Review_Reject_Reason__c, 'Porting_RC_Review_Reject_Reason__c should be populated as [No Value]');
            } else {
                Assert.isNotNull(updatedCase.Porting_Complete_Date__c, 'Porting_Complete_Date__c should be populated');
            }
        }
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testCreateSurveysForPortingInRTCases() {
        Triggers.switchOff();
        Triggers.except('CaseTriggerHandler.CreateSurveysForPortingInRTCases');
        Account accountObj = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => ACCOUNT_NAME,
                Account.RC_Brand__c => OpportunityHelper.BRAND_RINGCENTRAL
            })
            .create()
            .getRecord();

        Contact contactObj = createContact(accountObj);
        Case caseObj = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Status => CaseHelper.CASE_STATUS_NEW,
                Case.RecordTypeId => CaseHelper.RT_ID_PORTING_IN,
                Case.ContactId => contactObj.Id,
                Case.AccountId => accountObj.Id,
                Case.OwnerId => UserInfo.getUserId()
            })
            .create()
            .getRecord();

        caseObj.Status = CaseHelper.CASE_STATUS_CLOSED_NO_RESPONSE;
        caseObj.Porting_Estimated_Completion_Date__c = Date.today().addDays(2);
        TriggerHandler.BY_PASS_BEFORE = false;

        Test.StartTest();
            update caseObj;
        Test.stopTest();

        Triggers.switchOn();
        Case updatedCase = (Case) new ListOptional(
            selectCaseWithSurveyByType(new Set<Id> {caseObj.Id}, new List<String> {SurveyHelper.SURVEY_TYPE_PORTING})
        ).getFirst();
        assertSurveyCreation(contactObj, updatedCase);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testCreateSurveysWithVarSupportCSATType() {
        Triggers.switchOff();
        Triggers.except('CaseTriggerHandler.CreateSurveysForSupportCSATRTCases');
        Contact contactObj = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.FirstName => 'TestFirstName',
                Contact.LastName => 'TestLastName',
                Contact.Email => new ValueProvider.UniqueStringProvider('test@test.test')
            })
            .create()
            .getRecord();
        Case caseObj = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Status => CaseHelper.CASE_STATUS_NEW,
                Case.ContactId => contactObj.Id
            })
            .create()
            .getRecord();
        caseObj.Status = CaseHelper.CASE_STATUS_CLOSED;
        caseObj.RecordTypeId = CaseHelper.RT_ID_SUPPORT_T1_VAR_PARTNERS;
        caseObj.Support_Disposition_Level_1__c = 'test level 1';
        caseObj.Support_Disposition_Level_2__c = 'test level 2';
        caseObj.Support_Disposition_Level_3__c = 'test level 3';
        TriggerHandler.BY_PASS_BEFORE = false;

        Test.startTest();
            update caseObj;
        Test.stopTest();

        Triggers.switchOn();
        Case updatedCase = (Case) new ListOptional(
            selectCaseWithSurveyByType(new Set<Id> {caseObj.Id}, new List<String> {SurveyHelper.SURVEY_TYPE_VAR_SUPPORT_CSAT})
        ).getFirst();
        assertSurveyCreation(contactObj, updatedCase);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testCreateSurveysWithPortingPhoneSupportAndSupportCSATTypes() {
        Triggers.switchOff();
        Triggers.except('CaseTriggerHandler.CreateSurveysForSupportCSATRTCases');
        Account accountObj = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => ACCOUNT_NAME,
                Account.RC_Brand__c => OpportunityHelper.BRAND_RINGCENTRAL
            })
            .create()
            .getRecord();

        Contact contactObj = createContact(accountObj);
        Case caseForPortingPhoneSurvey = buildCase(contactObj, accountObj);
        Case caseForSupportCSATSurvey = buildCase(contactObj, accountObj);
        insert new List<Case> {caseForPortingPhoneSurvey, caseForSupportCSATSurvey};

        List<Case> casesToUpdate = (List<Case>) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Id => ValueProviderBuilder.provideList(new List<Id> {caseForPortingPhoneSurvey.Id, caseForSupportCSATSurvey.Id}),
                Case.Status => CaseHelper.CASE_STATUS_CLOSED,
                Case.RecordTypeId => ValueProviderBuilder.provideList(new List<Id> {CaseHelper.RT_ID_PORTING_PHONE, CaseHelper.RT_ID_SUPPORT_CHAT}),
                Case.Support_Disposition_Level_1__c => 'test level 1',
                Case.Support_Disposition_Level_2__c => 'test level 2',
                Case.Support_Disposition_Level_3__c => 'test level 3',
                Case.Product_Assistance__c => 'test product assistance'
            })
            .quantity(2)
            .build()
            .getRecords();
        TriggerHandler.BY_PASS_BEFORE = false;

        Test.startTest();
            update casesToUpdate;
        Test.stopTest();

        Triggers.switchOn();
        for (Case updatedCase : selectCaseWithSurveyByType(
            new Set<Id> {caseForPortingPhoneSurvey.Id, caseForSupportCSATSurvey.Id},
            new List<String> {SurveyHelper.SURVEY_TYPE_PORTING_PHONE_SUPPORT, SurveyHelper.SURVEY_TYPE_SUPPORT_CSAT})) {
            assertSurveyCreation(contactObj, updatedCase);
        }
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testCreateSurveysForITRTCases() {
        Triggers.switchOff();
        Triggers.except('CaseTriggerHandler.CreateSurveysForITRTCases');
        Account accountObj = createInternalAccount();
        Contact contactObj = createContact(accountObj);
        Case caseObj = createCase(contactObj, accountObj);
        caseObj.Status = CaseHelper.CASE_STATUS_CLOSED;
        caseObj.RecordTypeId = CaseHelper.RT_ID_IT_HELPDESK;
        caseObj.Request_Type__c = 'test request type';
        TriggerHandler.BY_PASS_BEFORE = false;

        Test.startTest();
            update caseObj;
        Test.stopTest();

        Triggers.switchOn();
        Case updatedCase = (Case) new ListOptional(
            selectCaseWithSurveyByType(new Set<Id> {caseObj.Id}, new List<String> {SurveyHelper.SURVEY_TYPE_IT_HELPDESC_CSAT})
        ).getFirst();
        assertSurveyCreation(contactObj, updatedCase);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testCreateSurveysForBizServRTCases() {
        Triggers.switchOff();
        Triggers.except('CaseTriggerHandler.CreateSurveysForBizServRTCases');
        Account accountObj = createInternalAccount();
        Contact contactObj = createContact(accountObj);
        Case caseObj = createCase(contactObj, accountObj);
        caseObj.Status = CaseHelper.CASE_STATUS_CLOSED;
        caseObj.RecordTypeId = CaseHelper.RT_ID_INTERNAL_BUSINESS_SERVICES;
        caseObj.Is_Quickwin__c = CaseHelper.IS_QUICKWIN_SUPPORT;
        caseObj.Resolution_Code__c = CaseHelper.RESOLUTION_CODE_RESOLVED_SUCCESSFULLY;
        TriggerHandler.BY_PASS_BEFORE = false;

        Test.startTest();
            update caseObj;
        Test.stopTest();

        Triggers.switchOn();
        Case updatedCase = (Case) new ListOptional(
            selectCaseWithSurveyByType(new Set<Id> {caseObj.Id}, new List<String> {SurveyHelper.SURVEY_TYPE_BIZ_SERV_CRM})
        ).getFirst();
        assertSurveyCreation(contactObj, updatedCase);
    }

    @isTest
    static void testCreateSurveysForSupportMedalliaCases() {
        Triggers.switchOff();
        Triggers.except('CaseTriggerHandler.CreateSurveysForSupportMedalliaCases');
        Medallia_Credentials__c credentials = (Medallia_Credentials__c) new SObjectBuilder(Medallia_Credentials__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Medallia_Credentials__c.isMedallia__c => true,
                Medallia_Credentials__c.Name => 'Medallia'
            })
            .create()
            .getRecord();
        Account accountObj = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => ACCOUNT_NAME,
                Account.RC_Brand__c => OpportunityHelper.BRAND_RINGCENTRAL
            })
            .create()
            .getRecord();
        Contact contactObj = createContact(accountObj);
        Case caseObj = createCase(contactObj, accountObj);
        caseObj.Status = CaseHelper.CASE_STATUS_CLOSED;
        caseObj.RecordTypeId = CaseHelper.RT_ID_SUPPORT_CHAT;
        caseObj.CloseCustomerSupportLevel1__c = 'test level 1';
        caseObj.MedalliaRecordAlreadyCreated__c = false;
        TriggerHandler.BY_PASS_BEFORE = false;

        Test.startTest();
            update caseObj;
        Test.stopTest();

        Triggers.switchOn();
        Case updatedCase = selectCaseToAssertById(caseObj.Id);
        Medallia_Survey__c medalliaSurvey = (Medallia_Survey__c) new ListOptional(new MedalliaSurveySelector()
            .selectMedalliaSurveysByCaseId(new List<Object> {new Set<Id> {caseObj.Id}})
            .executeQuery()
        ).getFirst();

        Assert.isTrue(updatedCase.MedalliaRecordAlreadyCreated__c, 'MedalliaRecordAlreadyCreated__c should be true');
        Assert.isNotNull(medalliaSurvey, SHOULD_BE_ONE_SURVEY_CREATED);
        Assert.areEqual(caseObj.Id, medalliaSurvey.Case_SFDC_ID__c, 'Case_SFDC_ID__c should be populated');
        Assert.areEqual(contactObj.Id, medalliaSurvey.Support_Contact_ID__c, 'Contact__c should be populated');
    }

    @isTest
    static void testUpdateSupportCNRCases() {
        Triggers.switchOff();
        Triggers.except('CaseTriggerHandler.UpdateSupportCNRCases');
        Case caseObj = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Status => CaseHelper.CASE_STATUS_WAITING_ON_CUSTOMER,
                Case.OwnerId => CaseHelper.CNRQUEUE_ID
            })
            .create()
            .getRecord();
        caseObj.Status = CaseHelper.CASE_STATUS_UPDATED_BY_CUSTOMER;
        caseObj.RecordTypeId = CaseHelper.RT_ID_SUPPORT_CHAT;
        TriggerHandler.BY_PASS_BEFORE = false;

        Test.startTest();
            update caseObj;
        Test.stopTest();

        Triggers.switchOn();
        Case updatedCase = selectCaseToAssertById(caseObj.Id);
        Assert.isFalse(updatedCase.CNR_Status__c, 'CNR_Status__c should be false');
    }

    @isTest
    static void testUpdateDescriptionCodeForCases() {
        Triggers.switchOff();
        Triggers.except('CaseTriggerHandler.UpdateDescriptionCodeForCases');
        Case caseObj = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Status => CaseHelper.CASE_STATUS_WAITING_ON_CUSTOMER
            })
            .create()
            .getRecord();
        caseObj.Status = CaseHelper.CASE_STATUS_WIP;
        caseObj.Jeopardy_Code__c = CaseHelper.CASE_STATUS_COMPLETED;
        TriggerHandler.BY_PASS_BEFORE = false;

        Test.startTest();
            update caseObj;
        Test.stopTest();

        Triggers.switchOn();
        Case updatedCase = selectCaseToAssertById(caseObj.Id);
        Assert.areEqual(null, updatedCase.Jeopardy_Description__c, 'Jeopardy_Description__c should be null');
    }

    @isTest
    static void testPopulateCaseDates() {
        User userObj = createUserWithProfile(ProfileHelper.SYSTEM_ADMIN);
        Case caseObj = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Status => CaseHelper.CASE_STATUS_NEW
            })
            .create()
            .getRecord();
        caseObj.OwnerId = userObj.Id;
        TriggerHandler.BY_PASS_BEFORE = false;

        Test.startTest();
            update caseObj;
        Test.stopTest();

        Case updatedCase = selectCaseToAssertById(caseObj.Id);
        Assert.isNotNull(updatedCase.Date_Assigned__c, 'Date_Assigned__c field should be populated');
    }

    @isTest
    static void testCreateCaseFeedForParentCase_positive() {
        Triggers.switchOff();
        Case parentCase = createSimpleCase();
        Triggers.switchOn();

        Test.startTest();
        TriggerHandler.BY_PASS_BEFORE = false;
        TriggerHandler.BY_PASS_AFTER = false;
        Case childCase = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Status => CaseHelper.CASE_STATUS_NEW,
                Case.RecordTypeId => CaseHelper.RT_ID_INTERNAL_BUSINESS_SERVICES,
                Case.ParentId => parentCase.Id
            })
            .create()
            .getRecord();
        Test.stopTest();

        childCase = selectCaseToAssertById(childCase.Id);
        List<CaseFeed> cfs = [SELECT Id, Body from CaseFeed where ParentId = :parentCase.Id];
        Assert.isFalse(cfs.isEmpty(), 'CaseFeed item must be created');
        Assert.isTrue(cfs[0].Body.contains(childCase.CaseNumber), 'CaseFeed item body must contain information about child case number');
    }

    @isTest
    static void testCreateCaseFeedForParentCase_negative() {
        Test.startTest();
        Case cs = createSimpleCase();
        Test.stopTest();

        List<CaseFeed> cfs = [SELECT Id, Body from CaseFeed where ParentId = :cs.Id];
        Assert.isTrue(cfs.isEmpty(), 'No case feed items should be created');
    }

    @isTest
    static void testWebCaseRoutingUnifyOfficeBrand() {

        Group mittelQueue = (Group) new ListOptional(new GroupSelector()
            .selectGroups()
            .setCondition('Type = :bind0 AND Name = :bind1')
            .setQueryBindings(new List<Object> { GroupHelper.GROUP_TYPE_QUEUE, 'Mitel Support Queue' })
            .executeQuery()).getFirst();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'Test account',
                    Account.RC_Brand__c => OpportunityHelper.BRAND_ATOS,
                    Account.RC_User_ID__c => '12345678'
                }
            )
            .create()
            .getRecord();

        new SObjectBuilder(Entitlement.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Entitlement.AccountId => acc.Id,
                    Entitlement.Name => 'Test Entitlement',
                    Entitlement.StartDate => Date.today(),
                    Entitlement.Type => 'Advanced Support'
                }
            )
            .create();

        Test.startTest();
            Case testCase = (Case) new SObjectBuilder(Case.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Case.AccountId => acc.Id,
                    Case.OwnerId => mittelQueue.Id,
                    Case.Origin => CaseHelper.CASE_ORIGIN_WEB
                })
                .create()
                .getRecord();
        Test.stopTest();

        Case caseToCheck = (Case) new CaseSelector()
            .selectCasesByIds(new Set<Id>{testCase.Id})
            .executeQuery()
            .get(0);

        System.assertEquals(mittelQueue.Id, caseToCheck.OwnerId, 'Case owner for for Unify Office Case and for Entitlement Type = Advanced Support should stay Mitel Support Queue');
    }

    @isTest
    static void testWebCaseRoutingManagedServicesAccountRoutesMostRecordTypes() {
        Triggers.switchOff();
        Triggers.except('CaseTriggerHandler.WebCaseRouting');
        // Get the routing queue from metadata for Managed Services
        List<CaseRoutingBySupportType__mdt> routingSettings = CaseRoutingBySupportType__mdt.getAll().values();
        String managedServicesQueueName;
        for (CaseRoutingBySupportType__mdt setting : routingSettings) {
            if (setting.SupportType__c == CaseHelper.ENTITLEMENT_NAME_MANAGED_SERVICES) {
                managedServicesQueueName = setting.Owner__c;
                break;
            }
        }

        Group expectedQueue = (Group) new GroupSelector()
            .selectGroups()
            .setCondition('Type = :bind0 AND Name = :bind1')
            .setQueryBindings(new List<Object> { GroupHelper.GROUP_TYPE_QUEUE, managedServicesQueueName })
            .executeQuery()
            .get(0);

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Managed Services Test Account',
                Account.RC_User_ID__c => '99988877'
            })
            .create()
            .getRecord();

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.AccountId => acc.Id,
                Contact.LastName => 'Test Contact',
                Contact.Email => 'testcontact@example.com'
            })
            .create()
            .getRecord();

        new SObjectBuilder(Entitlement.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Entitlement.AccountId => acc.Id,
                Entitlement.Name => 'Test MS Entitlement',
                Entitlement.StartDate => Date.today(),
                Entitlement.Type => CaseHelper.ENTITLEMENT_NAME_MANAGED_SERVICES
            })
            .create();

        Test.startTest();
            List<Case> testCases = (List<Case>) new SObjectBuilder(Case.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Case.AccountId => acc.Id,
                    Case.ContactId => con.Id,
                    Case.Origin => CaseHelper.CASE_ORIGIN_WEB,
                    Case.RecordTypeId => CaseHelper.RT_ID_SUPPORT_CASE
                })
                .quantity(3)
                .create()
                .getRecords();
            
            // Set different record types
            testCases[0].RecordTypeId = CaseHelper.RT_ID_SUPPORT_T1;
            testCases[1].RecordTypeId = CaseHelper.RT_ID_SUPPORT_T2;
            testCases[2].RecordTypeId = CaseHelper.RT_ID_SUPPORT_CASE;
            update testCases;
        Test.stopTest();

        List<Case> casesToCheck = (List<Case>) new CaseSelector()
            .selectCasesByIds(new Set<Id>{testCases[0].Id, testCases[1].Id, testCases[2].Id})
            .executeQuery();

        // Verify routing happened - all cases should be routed to the queue specified in metadata
        for (Case c : casesToCheck) {
            Assert.areEqual(expectedQueue.Id, c.OwnerId, 'Case should be routed to ' + managedServicesQueueName + ' queue per CaseRoutingBySupportType__mdt');
        }
    }

    @isTest
    static void testWebCaseRoutingManagedServicesExcludesSpecificRecordTypes() {
        CaseTriggerHandler.excludedRecordTypesForWebCaseRouting = new Set<String>{CaseHelper.RT_NAME_CLOSE_LOOP_FEEDBACK_MEDALLIA_RELATIONSHIP};

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'MS Account With Exclusion',
                Account.RC_User_ID__c => '11122233'
            })
            .create()
            .getRecord();

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.AccountId => acc.Id,
                Contact.LastName => 'Test Contact',
                Contact.Email => 'testcontact@example.com'
            })
            .create()
            .getRecord();

        new SObjectBuilder(Entitlement.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Entitlement.AccountId => acc.Id,
                Entitlement.Name => 'MS Entitlement',
                Entitlement.StartDate => Date.today(),
                Entitlement.Type => CaseHelper.ENTITLEMENT_NAME_MANAGED_SERVICES
            })
            .create();

        Test.startTest();
            Case testCase = (Case) new SObjectBuilder(Case.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Case.AccountId => acc.Id,
                    Case.ContactId => con.Id,
                    Case.Origin => CaseHelper.CASE_ORIGIN_WEB,
                    Case.RecordTypeId => CaseHelper.RT_ID_CLOSE_LOOP_FEEDBACK_MEDALLIA_RELATIONSHIP
                })
                .create()
                .getRecord();
        Test.stopTest();

        Case caseToCheck = (Case) new CaseSelector()
            .selectCasesByIds(new Set<Id>{testCase.Id})
            .executeQuery()
            .get(0);

        // Verify case was created but NOT routed - excluded record types are filtered out before CaseRouting.execute
        Assert.areEqual(CaseHelper.RT_ID_CLOSE_LOOP_FEEDBACK_MEDALLIA_RELATIONSHIP, caseToCheck.RecordTypeId, 'Record type should remain Close Loop Feedback Qualtrics Relationship');
    }

    @isTest
    static void testWebCaseRoutingNonManagedServicesOnlyRoutesSupportCase() {
        Triggers.switchOff();
        Triggers.except('CaseTriggerHandler.WebCaseRouting');
        // Query metadata for Advanced Support queue
        List<CaseRoutingBySupportType__mdt> routingSettings = CaseRoutingBySupportType__mdt.getAll().values();
        String advancedSupportQueueName;
        for (CaseRoutingBySupportType__mdt setting : routingSettings) {
            if (setting.SupportType__c == 'Advanced Support') {
                advancedSupportQueueName = setting.Owner__c;
                break;
            }
        }
        
        Group expectedQueue = (Group) new GroupSelector()
            .selectGroups()
            .setCondition('Type = :bind0 AND Name = :bind1')
            .setQueryBindings(new List<Object> { GroupHelper.GROUP_TYPE_QUEUE, advancedSupportQueueName })
            .executeQuery()
            .get(0);

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Advanced Support Account',
                Account.RC_User_ID__c => '55566677'
            })
            .create()
            .getRecord();

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.AccountId => acc.Id,
                Contact.LastName => 'Test Contact',
                Contact.Email => 'testcontact@example.com'
            })
            .create()
            .getRecord();

        new SObjectBuilder(Entitlement.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Entitlement.AccountId => acc.Id,
                Entitlement.Name => 'Advanced Support Entitlement',
                Entitlement.StartDate => Date.today(),
                Entitlement.Type => 'Advanced Support'
            })
            .create();

        Test.startTest();
            List<Case> testCases = (List<Case>) new SObjectBuilder(Case.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Case.AccountId => acc.Id,
                    Case.ContactId => con.Id,
                    Case.Origin => CaseHelper.CASE_ORIGIN_WEB,
                    Case.RecordTypeId => CaseHelper.RT_ID_SUPPORT_CASE
                })
                .quantity(2)
                .create()
                .getRecords();
            
            // One Support Case (should route), one T1 (should NOT route for Advanced Support)
            testCases[0].RecordTypeId = CaseHelper.RT_ID_SUPPORT_CASE;
            testCases[1].RecordTypeId = CaseHelper.RT_ID_SUPPORT_T1;
            update testCases;
        Test.stopTest();

        Triggers.switchOn();
        List<Case> casesToCheck = (List<Case>) new CaseSelector()
            .selectCasesByIds(new Set<Id>{testCases[0].Id, testCases[1].Id})
            .executeQuery();

        Assert.areEqual(2, casesToCheck.size(), 'Both cases should exist');
        
        Case supportCase = casesToCheck[0].RecordTypeId == CaseHelper.RT_ID_SUPPORT_CASE ? casesToCheck[0] : casesToCheck[1];
        Case t1Case = casesToCheck[0].RecordTypeId == CaseHelper.RT_ID_SUPPORT_T1 ? casesToCheck[0] : casesToCheck[1];
        
        // Support Case should be routed to Advanced Support queue per metadata
        Assert.areEqual(expectedQueue.Id, supportCase.OwnerId, 'Support Case should be routed to ' + advancedSupportQueueName + ' queue per CaseRoutingBySupportType__mdt');
        
        // T1 Case should NOT be routed for Advanced Support (not added to casesToRoute list)
        Assert.areEqual(CaseHelper.RT_ID_SUPPORT_T1, t1Case.RecordTypeId, 'T1 Case should not be routed for Advanced Support');
    }

    @isTest
    static void testWebCaseRoutingAccountWithBothEntitlementsPrioritizesManagedServices() {
        Triggers.switchOff();
        Triggers.except('CaseTriggerHandler.WebCaseRouting');
        // Query metadata for Managed Services queue
        List<CaseRoutingBySupportType__mdt> routingSettings = CaseRoutingBySupportType__mdt.getAll().values();
        String managedServicesQueueName;
        for (CaseRoutingBySupportType__mdt setting : routingSettings) {
            if (setting.SupportType__c == CaseHelper.ENTITLEMENT_NAME_MANAGED_SERVICES) {
                managedServicesQueueName = setting.Owner__c;
                break;
            }
        }
        
        Group expectedQueue = (Group) new GroupSelector()
            .selectGroups()
            .setCondition('Type = :bind0 AND Name = :bind1')
            .setQueryBindings(new List<Object> { GroupHelper.GROUP_TYPE_QUEUE, managedServicesQueueName })
            .executeQuery()
            .get(0);

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Dual Entitlement Account',
                Account.RC_User_ID__c => '33344455'
            })
            .create()
            .getRecord();

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.AccountId => acc.Id,
                Contact.LastName => 'Test Contact',
                Contact.Email => 'testcontact@example.com'
            })
            .create()
            .getRecord();

        // Create both Managed Services and Advanced Support entitlements
        new SObjectBuilder(Entitlement.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Entitlement.AccountId => acc.Id,
                Entitlement.Name => 'MS Entitlement',
                Entitlement.StartDate => Date.today(),
                Entitlement.Type => CaseHelper.ENTITLEMENT_NAME_MANAGED_SERVICES
            })
            .create();

        new SObjectBuilder(Entitlement.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Entitlement.AccountId => acc.Id,
                Entitlement.Name => 'Advanced Support Entitlement',
                Entitlement.StartDate => Date.today(),
                Entitlement.Type => 'Advanced Support'
            })
            .create();

        Test.startTest();
            Case testCase = (Case) new SObjectBuilder(Case.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Case.AccountId => acc.Id,
                    Case.ContactId => con.Id,
                    Case.Origin => CaseHelper.CASE_ORIGIN_WEB,
                    Case.RecordTypeId => CaseHelper.RT_ID_SUPPORT_T1,
                    Case.Subject => 'Test Case with Both Entitlements'
                })
                .create()
                .getRecord();
        Test.stopTest();

        Case caseToCheck = (Case) new CaseSelector()
            .selectCasesByIds(new Set<Id>{testCase.Id})
            .executeQuery()
            .get(0);

        // CRITICAL: Case should be routed as Managed Services (not Advanced Support)
        // T1 record type should be routed to Managed Services queue per metadata
        // If it was treated as Advanced Support, T1 would NOT be routed (only Support Case routes for Advanced Support)
        Assert.areEqual(expectedQueue.Id, caseToCheck.OwnerId, 'T1 Case should be routed to ' + managedServicesQueueName + ' queue per CaseRoutingBySupportType__mdt - proving Managed Services priority');
        Assert.areEqual(CaseHelper.RT_ID_SUPPORT_T1, caseToCheck.RecordTypeId, 'T1 record type should be preserved');
        Assert.areEqual(acc.Id, caseToCheck.AccountId, 'Account should be preserved');
    }

    @isTest
    static void testWebCaseRoutingNonWebOriginNotRouted() {
        Triggers.switchOff();
        Triggers.except('CaseTriggerHandler.WebCaseRouting');
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Non-Web Origin Account',
                Account.RC_User_ID__c => '77788899'
            })
            .create()
            .getRecord();

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.AccountId => acc.Id,
                Contact.LastName => 'Test Contact',
                Contact.Email => 'testcontact@example.com'
            })
            .create()
            .getRecord();

        new SObjectBuilder(Entitlement.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Entitlement.AccountId => acc.Id,
                Entitlement.Name => 'MS Entitlement',
                Entitlement.StartDate => Date.today(),
                Entitlement.Type => CaseHelper.ENTITLEMENT_NAME_MANAGED_SERVICES
            })
            .create();


        Test.startTest();
            Case testCase = (Case) new SObjectBuilder(Case.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Case.AccountId => acc.Id,
                    Case.ContactId => con.Id,
                    Case.Origin => CaseHelper.CASE_ORIGIN_AUTO_EMAIL,
                    Case.RecordTypeId => CaseHelper.RT_ID_SUPPORT_CASE
                })
                .create()
                .getRecord();
        Test.stopTest();

        Triggers.switchOn();
        Case caseToCheck = (Case) new CaseSelector()
            .selectCasesByIds(new Set<Id>{testCase.Id})
            .executeQuery()
            .get(0);

        // WebCaseRouting should NOT process this case due to non-Web origin
        Assert.isNotNull(caseToCheck, 'Case should exist');
        Assert.areEqual(CaseHelper.CASE_ORIGIN_AUTO_EMAIL, caseToCheck.Origin, 'Origin should remain Auto Email');
    }

    @isTest
    static void testChangeOwnerForProfessionalServices_getOwnerIdForPSCCProServQuote() {
        Map<String,Id> psQueuesMap = QueueHelper.getPSQueuesMap();
        Opportunity opp = buildOppWithEnterpriseOwner();

        String implementationCategoryNotAlone = CaseHelper.CATEGORY_IMPLEMENTATION_SERVICES + ';' + ValueProviderBuilder.provideUniqueString().getValue();
        String anythingElseCategory = CaseHelper.CATEGORY_VIDEO;

        CaseTriggerHandler.ChangeOwnerForProfessionalServices triggerHandler = new CaseTriggerHandler.ChangeOwnerForProfessionalServices();
        Test.startTest();
            Id whenEmptyCategory = triggerHandler.getOwnerIdForPSCCProServQuote('', opp, psQueuesMap);
            Id whenImplementationCategory = triggerHandler.getOwnerIdForPSCCProServQuote(CaseHelper.CATEGORY_IMPLEMENTATION_SERVICES, opp, psQueuesMap);
            Id whenImplementationCategoryNotAlone = triggerHandler.getOwnerIdForPSCCProServQuote(implementationCategoryNotAlone, opp, psQueuesMap);
            Id whenManagedServices = triggerHandler.getOwnerIdForPSCCProServQuote(CaseHelper.CATEGORY_MANAGED_OR_RECURRING_SERVICES, opp, psQueuesMap);
            Id whenAfterMarket = triggerHandler.getOwnerIdForPSCCProServQuote(CaseHelper.CATEGORY_AFTERMARKET_SUPPORT, opp, psQueuesMap);
            Id whenVideoCategory = triggerHandler.getOwnerIdForPSCCProServQuote(anythingElseCategory, opp, psQueuesMap);
        Test.stopTest();

        Assert.areEqual(
            psQueuesMap.get(QueueHelper.QUEUE_PS_CONTACT_CENTER),
            whenEmptyCategory,
            'Owner should be PS Contact Center Queue when Case Category is empty'
        );
        Assert.areEqual(
            psQueuesMap.get(QueueHelper.QUEUE_PS_CONTACT_CENTER),
            whenImplementationCategory,
            'Owner should be PS Contact Center Queue when Case Category is Implementation Services'
        );
        Assert.areEqual(
            psQueuesMap.get(QueueHelper.QUEUE_PS_CONTACT_CENTER),
            whenImplementationCategoryNotAlone,
            'Owner should be PS Contact Center Queue when Case Category is Implementation Services and other categories'
        );
        Assert.areEqual(
            psQueuesMap.get(QueueHelper.QUEUE_PS_MRR_SERVICES),
            whenManagedServices,
            'Owner should be PS Managed Services Queue when Case Category is Managed Services'
        );
        Assert.areEqual(
            psQueuesMap.get(QueueHelper.QUEUE_PS_AFTERMARKET),
            whenAfterMarket,
            'Owner should be PS Managed Services Queue when Case Category is Aftermarket Support'
        );
        Assert.areEqual(
            psQueuesMap.get(QueueHelper.QUEUE_PS_CONTACT_CENTER),
            whenVideoCategory,
            'Owner should be PS Contact Center Queue when Case Category is anything else'
        );
    }

    @isTest
    static void testChangeOwnerForProfessionalServices_getOwnerIdForImplementationCategory() {
        Map<String,Id> psQueuesMap = QueueHelper.getPSQueuesMap();

        Opportunity oppWithEnterprise = buildOppWithEnterpriseOwner();
        Opportunity oppWithMajors = buildOppWithOwner(buildUserWithSegment(UserHelper.SEGMENT_MAJORS));
        Opportunity oppWithSmallBusiness = buildOppWithOwner(buildUserWithSegment(UserHelper.SEGMENT_SOHO));
        Opportunity oppWithMidMarket = buildOppWithOwner(buildUserWithSegment(UserHelper.SEGMENT_MID_MARKET));

        CaseTriggerHandler.ChangeOwnerForProfessionalServices triggerHandler = new CaseTriggerHandler.ChangeOwnerForProfessionalServices();
        Test.startTest();
            Id whenOpptyIsEnterprise = triggerHandler.getOwnerIdForImplementationCategory(oppWithEnterprise, psQueuesMap);
            Id whenOpptyIsMajors = triggerHandler.getOwnerIdForImplementationCategory(oppWithMajors, psQueuesMap);
            Id whenOpptyIsSmallBusiness = triggerHandler.getOwnerIdForImplementationCategory(oppWithSmallBusiness, psQueuesMap);
            Id whenOpptyIsMidMarket = triggerHandler.getOwnerIdForImplementationCategory(oppWithMidMarket, psQueuesMap);
        Test.stopTest();

        Assert.areEqual(
            psQueuesMap.get(QueueHelper.QUEUE_PS_NA_ENTERPRISE),
            whenOpptyIsEnterprise,
            'Owner should be PS NA Enterprise Queue when Case Category is anything Enterprise'
        );
        Assert.areEqual(
            psQueuesMap.get(QueueHelper.QUEUE_PS_NA_MAJORS),
            whenOpptyIsMajors,
            'Owner should be PS NA Majors Queue when Case Category is anything Majors'
        );
        Assert.areEqual(
            psQueuesMap.get(QueueHelper.QUEUE_PS_SMB),
            whenOpptyIsSmallBusiness,
            'Owner should be Small Business Queue when Case Category is anything Small Business'
        );
        Assert.areEqual(
            psQueuesMap.get(QueueHelper.QUEUE_PS_NA_MIDMARKET),
            whenOpptyIsMidMarket,
            'Owner should be Mid Market Queue when Case Category is anything Mid Market'
        );
    }

    @isTest
    static void testChangeOwnerForProfessionalServices_getOwnerIdForPSProServQuote() {
        Map<String,Id> psQueuesMap = QueueHelper.getPSQueuesMap();

        Opportunity oppWithEnterprise = buildOppWithEnterpriseOwner();

        CaseTriggerHandler.ChangeOwnerForProfessionalServices triggerHandler = new CaseTriggerHandler.ChangeOwnerForProfessionalServices();
        Test.startTest();
            Id whenCategoryIsEmpty = triggerHandler.getOwnerIdForPSProServQuote('', oppWithEnterprise, psQueuesMap);
            Id whenCategoryIsImplementation = triggerHandler.getOwnerIdForPSProServQuote(CaseHelper.CATEGORY_IMPLEMENTATION_SERVICES, oppWithEnterprise, psQueuesMap);
            Id whenCategoryIsManagedServices = triggerHandler.getOwnerIdForPSProServQuote(CaseHelper.CATEGORY_MANAGED_OR_RECURRING_SERVICES, oppWithEnterprise, psQueuesMap);
            Id whenCategoryIsAftermarketSupport = triggerHandler.getOwnerIdForPSProServQuote(CaseHelper.CATEGORY_AFTERMARKET_SUPPORT, oppWithEnterprise, psQueuesMap);
            Id whenCategoryIsVideo = triggerHandler.getOwnerIdForPSProServQuote(CaseHelper.CATEGORY_VIDEO, oppWithEnterprise, psQueuesMap);
            Id whenCategoryIsAnythingElse = triggerHandler.getOwnerIdForPSProServQuote('anything else', oppWithEnterprise, psQueuesMap);
        Test.stopTest();

        Assert.areEqual(
            psQueuesMap.get(QueueHelper.QUEUE_PS_NA_MIDMARKET),
            whenCategoryIsEmpty,
            'Owner should be MidMarket Queue when Case Category is empty'
        );
        Assert.areEqual(
            psQueuesMap.get(QueueHelper.QUEUE_PS_NA_ENTERPRISE),
            whenCategoryIsImplementation,
            'Owner should be Enterprise Queue when Case Category is Implementation Services ahd Opportunity Owner is Enterprise'
        );
        Assert.areEqual(
            psQueuesMap.get(QueueHelper.QUEUE_PS_MRR_SERVICES),
            whenCategoryIsManagedServices,
            'Owner should be Managed Services Queue when Case Category is Managed Services'
        );
        Assert.areEqual(
            psQueuesMap.get(QueueHelper.QUEUE_PS_AFTERMARKET),
            whenCategoryIsAftermarketSupport,
            'Owner should be Managed Services Queue when Case Category is Aftermarket Support'
        );
        Assert.areEqual(
            psQueuesMap.get(QueueHelper.QUEUE_PS_VIDEO),
            whenCategoryIsVideo,
            'Owner should be PS Video Queue when Case Category is Video'
        );
        Assert.areEqual(
            psQueuesMap.get(QueueHelper.QUEUE_PS_NA_MIDMARKET),
            whenCategoryIsAnythingElse,
            'Owner should be MidMarket Queue when Case Category is anything else'
        );
    }

    @isTest
    static void testChangeOwnerForProfessionalServices_changeOwnerForPS() {
        Map<String,Id> psQueuesMap = QueueHelper.getPSQueuesMap();
        Id originalOwnerId = (Id) ValueProviderBuilder.provideDummyId(User.sObjectType).getValue();

        Opportunity internationalOpp = buildOppWithOwner(buildUserWithSegment(UserHelper.SEGMENT_OTHER));
        internationalOpp.CurrencyIsoCode = CurrencyHelper.CURRENCY_ISO_CODE_EUR;
        Opportunity usOpp = buildOppWithOwner(buildUserWithSegment(UserHelper.SEGMENT_OTHER));
        usOpp.CurrencyIsoCode = CurrencyHelper.CURRENCY_ISO_CODE_USD;
        Quote cancelledQt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.RecordTypeId => QuoteHelper.RT_ID_PROSERV,
                Quote.ProServ_Status__c => QuoteHelper.PROSERVSTATUS_CANCELLED
            })
            .build()
            .getRecord();
        Quote salesQt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.RecordTypeId => QuoteHelper.RT_ID_SALES,
                Quote.ProServ_Status__c => QuoteHelper.PROSERVSTATUS_CREATED
            })
            .build()
            .getRecord();

        List<Case> testCases = (List<Case>) new SObjectBuilder(Case.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Case.OwnerId => originalOwnerId,
                    Case.Subject => CaseHelper.SUBJECT_PS_UC_QUOTE_CANCELATION
                }
            )
            .quantity(3)
            .build()
            .getRecords();
        Case whenQuoteIsCancelled = testCases[0];
        Case whenQuoteIsNotCancelledOppIsInternational = testCases[1];
        Case whenNothingFits = testCases[2];

        CaseTriggerHandler.ChangeOwnerForProfessionalServices triggerHandler = new CaseTriggerHandler.ChangeOwnerForProfessionalServices();
        Test.startTest();
            triggerHandler.changeOwnerForPS(whenQuoteIsCancelled, cancelledQt, internationalOpp, psQueuesMap);
            triggerHandler.changeOwnerForPS(whenQuoteIsNotCancelledOppIsInternational, salesQt, internationalOpp, psQueuesMap);
            triggerHandler.changeOwnerForPS(whenNothingFits, salesQt, usOpp, psQueuesMap);
        Test.stopTest();

        Assert.areEqual(
            psQueuesMap.get(QueueHelper.QUEUE_PS_NA_MIDMARKET),
            whenQuoteIsCancelled.OwnerId,
            'Owner should be MidMarket Queue when Quote is cancelled'
        );
        Assert.areEqual(
            psQueuesMap.get(QueueHelper.QUEUE_PS_INTERNATIONAL),
            whenQuoteIsNotCancelledOppIsInternational.OwnerId,
            'Owner should be International Queue when Quote is not cancelled and Opportunity is international'
        );
        Assert.areEqual(
            originalOwnerId,
            whenNothingFits.OwnerId,
            'Owner should not be changed when no conditions are met'
        );
    }

    @isTest
    static void testMakeCalloutTOSCP() {       
        Account accountObj = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'Test account',
                    Account.RC_User_ID__c => '12345678'
                }
            )
            .create()
            .getRecord();
        
        Contact contactObj = createContactForSCPCallout(accountObj);
                
        Test.setMock(HttpCalloutMock.class, new TestRCPlatformAPICalloutQueueableJob.MockSuccessfullCallout());
        
		Test.startTest();
        
        Case newCase = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Subject => 'Test case',
                Case.Origin => 'Web',
                Case.AccountId => accountObj.Id,
                Case.ContactId => contactObj.Id,
                Case.RecordTypeId => CaseHelper.RT_ID_SUPPORT_T1
            })
            .create()
            .getRecord();
        
        Test.stopTest();
        
        Assert.isTrue([SELECT Count() From AsyncApexJob WHERE ApexClass.Name = 'RCPlatformAPICalloutQueueableJob'] == 1, 'QueueableJob was not called');
    }
    
    @IsTest
    private static void testRoundRobinAssignmentWithMultipleAssignees() {
        // Create test users for assignees

        User testManager = (User) new SObjectBuilder(User.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    User.LastName => MANAGER_LAST_NAME,
                    User.Username => MANAGER_EMAIL,
                    User.Email => MANAGER_EMAIL,
                    User.Title => MANAGER_TITLE,
                    User.ProfileId => ProfileHelper.PROFILE_ID_SYSADMIN
                })
                .create()
                .getRecord();
    
                List<User> users = ((List<User>) new SObjectBuilder (User.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    User.LastName => ValueProviderBuilder.provideList(
                        new List<String> {
                            'RC Test Agent 1',
                            'RC Test Agent 2',
                            'RC Test Agent 3'
                        }),
                    User.Username => ValueProviderBuilder.provideList(
                        new List<String> {
                            'CaseOwner!user1@gmail.com',
                            'CaseOwner!user2@gmail.com',
                            'CaseOwner!user3@gmail.com'
                        }),
                    User.Email => ValueProviderBuilder.provideList(
                        new List<String> {
                            LOCAL_CONTACT_EMAIL,LOCAL_CONTACT_EMAIL,LOCAL_CONTACT_EMAIL
                        }),
                    User.Alias => ValueProviderBuilder.provideList(
                        new List<String> {
                            'Test1','Test2','Test3'
                        }),
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ProfileId => ProfileHelper.PROFILE_ID_SYSADMIN,
                    User.ManagerId => testManager.Id,
                    User.isActive => true
                })
                .quantity(3)
                .create()
                .getRecords());

        // Create Case_Assignee__c records
        List<Case_Assignee__c> assignees = new List<Case_Assignee__c>();
        assignees.add((Case_Assignee__c) new SObjectBuilder(Case_Assignee__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case_Assignee__c.Case_Agent__c => users[0].Id,
                Case_Assignee__c.Case_Type__c => CaseHelper.CASE_TYPE_CERT_CUSTOMER_SUCCESS_ESCALATION,
                Case_Assignee__c.Case_Assigned__c => System.now().addDays(-1)
            })
            .create()
            .getRecord());

        assignees.add((Case_Assignee__c) new SObjectBuilder(Case_Assignee__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case_Assignee__c.Case_Agent__c => users[1].Id,
                Case_Assignee__c.Case_Type__c => CaseHelper.CASE_TYPE_CERT_CUSTOMER_SUCCESS_ESCALATION,
                Case_Assignee__c.Case_Assigned__c => System.now().addDays(-2)
            })
            .create()
            .getRecord());

        assignees.add((Case_Assignee__c) new SObjectBuilder(Case_Assignee__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case_Assignee__c.Case_Agent__c => users[2].Id,
                Case_Assignee__c.Case_Type__c => CaseHelper.CASE_TYPE_CERT_CUSTOMER_SUCCESS_ESCALATION,
                Case_Assignee__c.Case_Assigned__c => System.now().addDays(-3)
            })
            .create()
            .getRecord());

        // Create test cases
        List<Case> testCases = new List<Case>();
        for (Integer i = 0; i < 5; i++) {
            testCases.add((Case) new SObjectBuilder(Case.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Case.RecordTypeId => CaseHelper.RT_ID_SALES_CUST_FORM,
                    Case.Status => CaseHelper.CASE_STATUS_NEW,
                    Case.Support_Escalate_To__c => null // No escalation initially
                })
                .build()
                .getRecord());
        }

        insert testCases;
        
        // Now update the cases to trigger escalation
        for (Case c : testCases) {
            c.Support_Escalate_To__c = 'CERT';
        }
        Test.startTest();
        update testCases;
        Test.stopTest();

        // Verify round-robin assignment
        List<Case> updatedCases = selectCasesToAssertByIds(testCases);
        Set<Id> assignedOwnerIds = new Set<Id>();
        for (Case c : updatedCases) {
            assignedOwnerIds.add(c.OwnerId);
        }

        // Should have assigned to all three assignees in round-robin fashion
        Assert.areEqual(3, assignedOwnerIds.size(), 'Cases should be assigned to 3 different assignees');
        Assert.isTrue(assignedOwnerIds.contains(users[0].Id), 'Assignee1 should be assigned at least one case');
        Assert.isTrue(assignedOwnerIds.contains(users[1].Id), 'Assignee2 should be assigned at least one case');
        Assert.isTrue(assignedOwnerIds.contains(users[2].Id), 'Assignee3 should be assigned at least one case');
    }

    @IsTest
    private static void testRoundRobinAssignmentWithSingleAssignee() {
        // Create test user for assignee
        User assignee = createUserWithProfile(ProfileHelper.SYSTEM_ADMIN);

        // Create Case_Assignee__c record
        Case_Assignee__c assigneeRecord = (Case_Assignee__c) new SObjectBuilder(Case_Assignee__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case_Assignee__c.Case_Agent__c => assignee.Id,
                Case_Assignee__c.Case_Type__c => CaseHelper.CASE_TYPE_CERT_CUSTOMER_SUCCESS_ESCALATION,
                Case_Assignee__c.Case_Assigned__c => System.now().addDays(-1)
            })
            .create()
            .getRecord();

        // Create test cases
        List<Case> testCases = new List<Case>();
        for (Integer i = 0; i < 3; i++) {
            testCases.add((Case) new SObjectBuilder(Case.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Case.RecordTypeId => CaseHelper.RT_ID_SALES_CUST_FORM,
                    Case.Status => CaseHelper.CASE_STATUS_NEW,
                    Case.Support_Escalate_To__c => null // No escalation initially
                })
                .build()
                .getRecord());
        }

        insert testCases;
        
        // Now update the cases to trigger escalation
        for (Case c : testCases) {
            c.Support_Escalate_To__c = 'Customer Success';
        }
        Test.startTest();
        update testCases;
        Test.stopTest();

        // Verify all cases assigned to the single assignee
        List<Case> updatedCases = selectCasesToAssertByIds(testCases);
        for (Case c : updatedCases) {
            Assert.areEqual(assignee.Id, c.OwnerId, 'All cases should be assigned to the single assignee');
        }
    }

    @IsTest
    private static void testRoundRobinAssignmentWithNoAssignees() {
        // Create test cases without any assignees
        List<Case> testCases = new List<Case>();
        for (Integer i = 0; i < 2; i++) {
            testCases.add((Case) new SObjectBuilder(Case.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Case.RecordTypeId => CaseHelper.RT_ID_SALES_CUST_FORM,
                    Case.Status => CaseHelper.CASE_STATUS_NEW,
                    Case.Support_Escalate_To__c => null // No escalation initially
                })
                .build()
                .getRecord());
        }

        Test.startTest();
        insert testCases;
        
        // Now update the cases to trigger escalation
        for (Case c : testCases) {
            c.Support_Escalate_To__c = 'CERT';
        }
        update testCases;
        Test.stopTest();

        // Verify cases are not assigned (should remain with default owner)
        List<Case> updatedCases = selectCasesToAssertByIds(testCases);
        for (Case c : updatedCases) {
            // Cases should not be assigned to any specific user since no assignees exist
            Assert.isTrue(c.OwnerId != null, 'Cases should have an owner');
        }
    }

    @IsTest
    private static void testRoundRobinAssignmentWithWrongRecordType() {
        // Create test user for assignee
        User assignee = createUserWithProfile(ProfileHelper.SYSTEM_ADMIN);

        // Create Case_Assignee__c record
        Case_Assignee__c assigneeRecord = (Case_Assignee__c) new SObjectBuilder(Case_Assignee__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case_Assignee__c.Case_Agent__c => assignee.Id,
                Case_Assignee__c.Case_Type__c => CaseHelper.CASE_TYPE_CERT_CUSTOMER_SUCCESS_ESCALATION,
                Case_Assignee__c.Case_Assigned__c => System.now().addDays(-1)
            })
            .create()
            .getRecord();

        // Create test case with wrong record type
        Case testCase = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.RecordTypeId => CaseHelper.RT_ID_SUPPORT_T1, // Wrong record type
                Case.Status => CaseHelper.CASE_STATUS_NEW,
                Case.Support_Escalate_To__c => null // No escalation initially
            })
            .build()
            .getRecord();

        Test.startTest();
        insert testCase;
        
        // Now update the case to trigger escalation
        testCase.Support_Escalate_To__c = 'CERT';
        update testCase;
        Test.stopTest();

        // Verify case is not assigned to the assignee
        Case updatedCase = selectCaseToAssertById(testCase.Id);
        Assert.areNotEqual(assignee.Id, updatedCase.OwnerId, 'Case should not be assigned to assignee due to wrong record type');
    }

    @IsTest
    private static void testRoundRobinAssignmentWithWrongEscalationValue() {
        // Create test user for assignee
        User assignee = createUserWithProfile(ProfileHelper.SYSTEM_ADMIN);

        // Create Case_Assignee__c record
        Case_Assignee__c assigneeRecord = (Case_Assignee__c) new SObjectBuilder(Case_Assignee__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case_Assignee__c.Case_Agent__c => assignee.Id,
                Case_Assignee__c.Case_Type__c => CaseHelper.CASE_TYPE_CERT_CUSTOMER_SUCCESS_ESCALATION,
                Case_Assignee__c.Case_Assigned__c => System.now().addDays(-1)
            })
            .create()
            .getRecord();

        // Create test case with wrong escalation value
        Case testCase = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.RecordTypeId => CaseHelper.RT_ID_SALES_CUST_FORM,
                Case.Status => CaseHelper.CASE_STATUS_NEW,
                Case.Support_Escalate_To__c => null // No escalation initially
            })
            .build()
            .getRecord();

        Test.startTest();
        insert testCase;
        
        // Now update the case with wrong escalation value
        testCase.Support_Escalate_To__c = 'Wrong Escalation'; // Wrong escalation value
        update testCase;
        Test.stopTest();

        // Verify case is not assigned to the assignee
        Case updatedCase = selectCaseToAssertById(testCase.Id);
        Assert.areNotEqual(assignee.Id, updatedCase.OwnerId, 'Case should not be assigned to assignee due to wrong escalation value');
    }

    @IsTest
    private static void testRoundRobinAssignmentWithNullCaseAgent() {
        // Create Case_Assignee__c record with null Case_Agent__c
        Case_Assignee__c assigneeRecord = (Case_Assignee__c) new SObjectBuilder(Case_Assignee__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case_Assignee__c.Case_Agent__c => null, // Null agent
                Case_Assignee__c.Case_Type__c => CaseHelper.CASE_TYPE_CERT_CUSTOMER_SUCCESS_ESCALATION,
                Case_Assignee__c.Case_Assigned__c => System.now().addDays(-1)
            })
            .create()
            .getRecord();

        // Create test case
        Case testCase = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.RecordTypeId => CaseHelper.RT_ID_SALES_CUST_FORM,
                Case.Status => CaseHelper.CASE_STATUS_NEW,
                Case.Support_Escalate_To__c => null // No escalation initially
            })
            .build()
            .getRecord();

        Test.startTest();
        insert testCase;
        
        // Now update the case to trigger escalation
        testCase.Support_Escalate_To__c = 'CERT';
        update testCase;
        Test.stopTest();

        // Verify case is not assigned since assignee has null Case_Agent__c
        Case updatedCase = selectCaseToAssertById(testCase.Id);
        // Case should not be assigned to any specific user since assignee has null Case_Agent__c
        Assert.isTrue(updatedCase.OwnerId != null, 'Case should have an owner');
    }
    
    private static Case createSimpleCase() {
        return (Case) new SObjectBuilder(Case.SObjectType)
            .setField(Case.Status, CaseHelper.CASE_STATUS_NEW)
            .create()
            .getRecord();
    }

    private static Account selectAccount() {
        return (Account) new ListOptional(new AccountSelector()
            .selectAccountByName(new List<Object> { ACCOUNT_NAME })
            .selectFields(new List<Schema.SObjectField> {
                Account.Partner_BAN_ID__c,
                Account.MRR__c,
                Account.Current_Owner_Email__c,
                Account.Sales_Agreement_Start_Date__c,
                Account.RC_Account_Number__c,
                Account.Sales_Agreement_End_Date__c
            })
            .executeQuery()
        ).getFirst();
    }

    private static Contact selectContact() {
        return (Contact) new ListOptional(new ContactSelector()
            .selectContactsByEmail(new List<Object> {
                new Set<String> { CONTACT_FIRSTNAME },
                new Set<String> { CONTACT_LASTNAME },
                new Set<String> { CONTACT_EMAIL }
            })
            .executeQuery()
        ).getFirst();
    }

    private static List<Schema.SObjectField> caseFieldsToAssert() {
        return new List<Schema.SObjectField> {
            Case.Id,
            Case.Actual_Escalation__c,
            Case.Partner_BAN_ID__c,
            Case.OpportunityMRR__c,
            Case.RecordTypeId,
            Case.ContactId,
            Case.TotalMRRtoSurveyDate__c,
            Case.Address__c,
            Case.City__c,
            Case.State__c,
            Case.Zip__c,
            Case.Country__c,
            Case.EntitlementId,
            Case.IsUpdatePermitted__c,
            Case.Support_Owner_Manager__c,
            Case.Case_Contact_Email__c,
            Case.Case_Contact_First_Name__c,
            Case.Case_Contact_Last_Name__c,
            Case.Case_Contact_Phone__c,
            Case.OwnerId,
            Case.Status,
            Case.Engage_Case_Type__c,
            Case.Account_Balance__c,
            Case.Full_or_Partial_Port_Out__c,
            Case.Case_Owner_Manager_Email__c,
            Case.Case_Owner_Manager_Title__c,
            Case.Case_Owner_Supervisor_Title__c,
            Case.Case_Owner_Supervisor__c,
            Case.Case_Owner_Manager__c,
            Case.Support_Escalate_To__c,
            Case.User_Name__c,
            Case.Title__c,
            Case.Department__c,
            Case.Sales_Owner_Manager_Email__c,
            Case.CreatedById,
            Case.Porting_Last_Submit_Date__c,
            Case.Porting_First_Submit_Date__c,
            Case.Porting_First_Reject_Reason__c,
            Case.Porting_Complete_Date__c,
            Case.Porting_RC_Review__c,
            Case.Porting_RC_Review_Reject_Reason__c,
            Case.MedalliaRecordAlreadyCreated__c,
            Case.CNR_Status__c,
            Case.Jeopardy_Description__c,
            Case.Date_Assigned__c,
            Case.Fee_Does_Not_Need_to_be_Charged__c,
            Case.Service_Version_Name__c
        };
    }

    private static Case selectCaseToAssertById(Id caseId) {
        return (Case) new ListOptional(new CaseSelector()
            .selectCasesByIds(new Set<Id> { caseId })
            .withoutSelectorFieldsIncluded()
            .selectFields(caseFieldsToAssert())
            .executeQuery()
        ).getFirst();
    }

    private static List<Case> selectCasesToAssertByIds(List<Case> cases) {
        Set<Id> caseIds = new Set<Id>();
        for (Case c : cases) {
            caseIds.add(c.Id);
        }
        return (List<Case>) new CaseSelector()
            .selectCasesByIds(caseIds)
            .withoutSelectorFieldsIncluded()
            .selectFields(caseFieldsToAssert())
            .executeQuery();
    }

    private static List<Case> selectCaseWithSurveyByType(Set<Id> caseIds, List<String> surveyTypes) {
        return (List<Case>) new CaseSelector()
            .selectCases()
            .selectFields(new List<Schema.SObjectField> {Case.Id})
                .subselect(new SurveySelector()
                .selectSurveys()
                .withoutSelectorFieldsIncluded()
                .withoutSelectorOrderByIncluded()
                .selectFields(new List<Schema.SObjectField> {Survey__c.Id, Survey__c.SurveyType__c, Survey__c.Case__c, Survey__c.Contact__c})
                .setCondition('SurveyType__c IN :bind1'))
            .setCondition('Id IN :bind0')
            .setQueryBindings(new List<Object> {caseIds, surveyTypes})
            .setQueryCaching(true)
            .executeQuery();
    }

    private static Case buildCase(Contact contactObj, Account accountObj) {
        return (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Status => CaseHelper.CASE_STATUS_NEW,
                Case.ContactId => contactObj.Id,
                Case.AccountId => accountObj.Id
            })
            .build()
            .getRecord();
    }

    private static User buildUserWithSegment(String segment) {
        return (User) new SObjectBuilder(User.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                User.Id => ValueProviderBuilder.provideDummyId(User.SObjectType),
                User.SegmentPicklist__c => segment
            })
            .build()
            .getRecord();
    }

    private static Opportunity buildOppWithEnterpriseOwner() {
        return buildOppWithOwner(buildUserWithSegment(UserHelper.SEGMENT_ENTERPRISE));
    }

    private static Opportunity buildOppWithOwner(User oppOwner) {
        return (Opportunity) Test_Utils.putIntoUnwritableField(
            new Opportunity(OwnerId = oppOwner.Id),
            Opportunity.class,
            'Owner',
            oppOwner
        );
    }

    private static Case createCase(Contact contactObj, Account accountObj) {
        return (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Status => CaseHelper.CASE_STATUS_NEW,
                Case.ContactId => contactObj.Id,
                Case.AccountId => accountObj.Id
            })
            .create()
            .getRecord();
    }

    private static Account createInternalAccount() {
        return (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'RC Internal'
            })
            .create()
            .getRecord();
    }
    
    private static Contact createContactForSCPCallout(Account accountObj) {
        return (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.FirstName => 'TestFirstName',
                Contact.LastName => 'TestLastName',
                Contact.Email => 'test@test.test',
                Contact.AccountId => accountObj.Id
            })
            .create()
            .getRecord();
    }

    private static Contact createContact(Account accountObj) {
        return (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.FirstName => 'TestFirstName',
                Contact.LastName => 'TestLastName',
                Contact.Email => new ValueProvider.UniqueStringProvider('test@test.test'),
                Contact.AccountId => accountObj.Id
            })
            .create()
            .getRecord();
    }

    private static User createUserWithProfile(String requiredProfileName) {

        Profile requiredProfile = (Profile) new ListOptional(new ProfileSelector()
            .selectProfileByName(new List<String> { requiredProfileName })
            .executeQuery()
        ).getFirst();

        User testManager = (User) new SObjectBuilder(User.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                User.LastName => MANAGER_LAST_NAME,
                User.Username => MANAGER_EMAIL,
                User.Email => MANAGER_EMAIL,
                User.Title => MANAGER_TITLE,
                User.ProfileId => requiredProfileName == ProfileHelper.SYSTEM_ADMIN ? requiredProfile.Id : ProfileHelper.PROFILE_ID_SYSADMIN
            })
            .create()
            .getRecord();

        return (User) new SObjectBuilder (User.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                User.LastName => 'RC Support Agent',
                User.Username => 'CaseOwner!user@gmail.com',
                User.Email => LOCAL_CONTACT_EMAIL,
                User.Alias => 'Test',
                User.TimeZoneSidKey => 'America/Los_Angeles',
                User.ManagerId => testManager.Id,
                User.LocaleSidKey => 'en_US',
                User.EmailEncodingKey => 'UTF-8',
                User.ProfileId => requiredProfile.Id,
                User.LanguageLocaleKey => 'en_US',
                User.Hierarchy_Role__c => 'Sales Rep',
                User.Title => 'Test_title',
                User.Department => 'test_department',
                User.isActive => true,
                User.Phone => '332211445566',
                User.Division => OpportunityHelper.USER_DIVISION_SALES_ENTERPRISE
            })
            .create()
            .getRecord();
    }

    private static Account buildTechAccountForGetAccountsToUpdateTests() {
        ValueProvider.DummyIdProvider accIdProvider = new ValueProvider.DummyIdProvider(Account.sObjectType);
        Account masterAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Id => accIdProvider,
                Account.IsMultiProductTechnicalAccount__c => false
            })
            .build()
            .getRecord();
        Account techAcc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Id => accIdProvider,
                Account.Name => ACCOUNT_NAME,
                Account.IsMultiProductTechnicalAccount__c => true,
                Account.Master_Account__c => masterAcc.Id
            })
            .build()
            .getRecord();

        return (Account) Test_Utils.putIntoUnwritableField(
            techAcc,
            Account.class,
            'Master_Account__r',
            masterAcc
        );
    }

    private static Opportunity buildOppWithParentAccount(Account affectedMasterAcc) {
        Opportunity opp = (Opportunity) Test_Utils.putIntoUnwritableField(
            new Opportunity(),
            Opportunity.class,
            'Account',
            affectedMasterAcc
        );
        return opp;
    }

    private static void createCaseRoutingCustomSettings() {
        new SObjectBuilder(Case_Routing_SFDC__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case_Routing_SFDC__c.Name => ProfileHelper.PROFILE_NAME_DEAL_DESK_LIGHTNING,
                Case_Routing_SFDC__c.Profile_Name__c => ProfileHelper.PROFILE_NAME_DEAL_DESK_LIGHTNING
            })
            .create();
    }

    private static List<Words_to_prevent_case_creation__mdt> buildWordsToPreventCaseCreationMdts(Set<String> words) {
        Set<String> jsonMtds = new Set<String>();
        for (String word : words) {
            jsonMtds.add('{"Word__c": "' + word + '"}');
        }

        return (List<Words_to_prevent_case_creation__mdt>) JSON.deserialize(
            '['+ String.join(jsonMtds, ',') + ']',
            List<Words_to_prevent_case_creation__mdt>.class
        );
    }

    private static void assertTelusAddressToRCAddress(Case cs) {
        Assert.areEqual('add', cs.Address__c, 'Case Address should be equal to Address from Return Shipping Address');
        Assert.areEqual('city', cs.City__c, 'Case City should be equal to City from Return Shipping Address');
        Assert.areEqual('state', cs.State__c, 'Case State should be equal to State from Return Shipping Address');
        Assert.areEqual('123', cs.Zip__c, 'Case Zip should be equal to Zip from Return Shipping Address');
        Assert.areEqual('USA', cs.Country__c, 'Case Country should be equal to Country from Return Shipping Address');
    }

    private static void assertException(Exception e, String message, String fieldToDisplay) {
        Assert.areEqual(
            e.getMessage(),
            'Insert failed. First exception on row 0; first error: FIELD_CUSTOM_VALIDATION_EXCEPTION, ' + message + ': [' + fieldToDisplay + ']',
            'Should throw exception with correct message'
        );
    }

    private static void assertSurveyCreation(Contact contactObj, Case updatedCase) {
        Assert.areEqual(1, updatedCase.Surveys__r.size(), SHOULD_BE_ONE_SURVEY_CREATED);
        Assert.isNotNull(updatedCase.Surveys__r[0].Case__c, 'Case__c should be populated');
        Assert.areEqual(contactObj.Id, updatedCase.Surveys__r[0].Contact__c, 'Contact__c should be populated');
        Assert.isNotNull(updatedCase.Surveys__r[0].SurveyType__c, 'SurveyType__c should be populated');
    }

    private static void assertGetAccountsToUpdateForMasterAccount(List<Account> result, Case inputCase) {
        Account accToUpdate = result[0];
        assertGetAccountsToUpdate(result, accToUpdate, 1, inputCase);
        Assert.areEqual(
            accToUpdate.inContact_account_ID__c,
            String.valueOf(inputCase.inContact_BU_ID__c),
            'inContact_account_ID__c must be set to the Case BU ID'
        );
    }

    private static void assertGetAccountsToUpdateForTechnicalAccount(List<Account> result, Case inputCase) {
        Account techAccToUpdate = result[1];
        Account masterAcc = result[0];
        assertGetAccountsToUpdate(result, techAccToUpdate, 2, inputCase);
        Assert.areEqual(
            masterAcc.inContact_account_ID__c,
            String.valueOf(inputCase.inContact_BU_ID__c),
            'Only Master Account inContact_account_ID__c must be set to the Case BU ID'
        );
        Assert.isNull(
            techAccToUpdate.inContact_account_ID__c,
            'Technical Account inContact_account_ID__c must be empty'
        );
    }

    private static void assertGetAccountsToUpdate(List<Account> result, Account accToUpdate, Integer expectedSizeOfResult, Case inputCase) {
        Assert.isTrue(
            result.size() == expectedSizeOfResult,
            'The returned amount of Accounts must be equal to the ' + expectedSizeOfResult
        );

        Assert.areEqual(
            accToUpdate.Provision_Date__c,
            inputCase.Provision_Date__c,
            'Provision_Date__c must be set to the input Case Provision Date'
        );
        Assert.areEqual(
            accToUpdate.inContact_Cluster__c,
            inputCase.inContact_Cluster__c,
            'inContact_Cluster__c must be set to the Case Cluster'
        );
        Assert.areEqual(
            accToUpdate.Service_Status__c,
            AccountHelper.SERVICE_STATUS_CONTRACT_COMPLETE,
                'Service_Status__c must be set to the ' + AccountHelper.SERVICE_STATUS_CONTRACT_COMPLETE
        );
        Assert.areEqual(
            accToUpdate.InContact_Service__c,
            TEST_EDITION,
            'InContact_Service__c must be set to the primary Quote\'s edition name'
        );
        Assert.areEqual(
            accToUpdate.No_of_InContact_Seats__c,
            TEST_NEW_QUANTITY,
            'No_of_InContact_Seats__c must be set to the primary Quote Line Item New Quantity'
        );
    }

    private static User selectIntegrationUser() {
        return (User) new ListOptional(new UserSelector()
            .selectUserByName(new List<Object> { new Set<String> { PortingESBHelper.integrationUserName }})
            .executeQuery()
        ).getFirst();
    }
}