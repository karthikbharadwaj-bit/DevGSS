@isTest
public with sharing class Test_ContactUpdatePlatformEventsHelper {
    @testSetup
    static void prepareData() {
        //Adding the bypasstrigger flag to not trigger the validation when creating contact. PBC-10858
        ByPassTrigger__c byPassTrigger = ByPassTrigger__c.getOrgDefaults();
        byPassTrigger.ByPass_OppContactRole_Validation__c = true;
        insert byPassTrigger;
        
        Test.startTest();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test account')
            .setField(Account.Phone, '5465491')
            .setField(Account.RC_Account_Status__c, AccountHelper.PAID_STATUS)
            .create()
            .getRecord();

        Contact priCon = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Primary')
            .setField(Contact.LastName, 'Contact')
            .setField(Contact.Email, 'primary@contact.con')
            .setField(Contact.Phone, '5465491')
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.AccountId, acc.Id)
            .create()
            .getRecord();

        Contact conRole = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Contact')
            .setField(Contact.LastName, 'Role')
            .setField(Contact.Email, 'contact@role.con')
            .setField(Contact.Phone, '5465491')
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.AccountId, acc.Id)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.Type, 'Syndicated - New')
            .setField(Opportunity.StageName, OpportunityHelper.STAGE_NAME_AGREEMENT)
            .setField(Opportunity.CloseDate, System.today().addMonths(1))
            .setField(Opportunity.ForcastedDimeloUsers__c, 1)
            .setField(Opportunity.Forecast_Connect_First_Users__c, 1)
            .setField(Opportunity.Forecast_Contact_Center_Users__c, 1)
            .setField(Opportunity.Forecasted_Global_Office_Users__c, 1)
            .setField(Opportunity.Forecasted_RingCentral_Video_Users__c, 1)
            .setField(Opportunity.Forecasted_Users__c, 1)
            .setField(Opportunity.Brand_Name__c, OpportunityHelper.BRAND_RINGCENTRAL)
            .setField(Opportunity.RecordTypeId, OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY)
            .setField(Opportunity.Primary_Opportunity_Contact__c, priCon.Id)
            .setField(Opportunity.Type, OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS)
            .setField(Opportunity.CurrencyIsoCode, RingCentralHelper.USD)
            .setField(Opportunity.Is_Billing_Opportunity__c, true)
            .setField(Opportunity.AccountId, acc.Id)
            .setField(Opportunity.Tier_Name__c, OpportunityHelper.TIER_OFFICE)
            .create()
            .getRecord();

        OpportunityContactRole oppConRole = (OpportunityContactRole) new SObjectBuilder(
                OpportunityContactRole.SObjectType
            )
            .setField(OpportunityContactRole.OpportunityId, opp.Id)
            .setField(OpportunityContactRole.ContactId, conRole.Id)
            .create()
            .getRecord();
        
		new SObjectBuilder(OpportunityContactRole.SObjectType)
            .setField(OpportunityContactRole.OpportunityId, opp.Id)
            .setField(OpportunityContactRole.ContactId, priCon.Id)
            .create();

        Test.stopTest();
    }

    @isTest
    static void testCustomerRecordUpdate() {
        Opportunity opp = (Opportunity) new OpportunitySelector().selectOpportunities().executeQuery()[0];

        Test.startTest();
        opp.StageName = OpportunityHelper.STAGE_NAME_CLOSED_WON;
        update opp;
        Test.stopTest();

        List<Contact> assertContacts = (List<Contact>) new ContactSelector()
            .selectContacts()
            .selectField(Contact.Customer_Record__c)
            .executeQuery();

        System.assertEquals(true, assertContacts[0].Customer_Record__c);
        System.assertEquals(true, assertContacts[1].Customer_Record__c);
    }

    @isTest
    static void testContactCenterUpdate() {
        Opportunity opp = (Opportunity) new OpportunitySelector().selectOpportunities().executeQuery()[0];
        createQuotesForOpportunity(opp, QuoteHelper.RT_ID_CC, '1', 1);

        Test.startTest();
        opp.StageName = OpportunityHelper.STAGE_NAME_CLOSED_WON;
        opp.Estimated_12M_Contact_Center_Pipeline__c = 1;
        update opp;
        Test.stopTest();

        List<Contact> assertContacts = (List<Contact>) new ContactSelector()
            .selectContacts()
            .selectField(Contact.Quoted_Products__c)
            .executeQuery();

        System.assertEquals(true, assertContacts[0].Quoted_Products__c.contains('Contact Center'));
        System.assertEquals(true, assertContacts[1].Quoted_Products__c.contains('Contact Center'));
    }

    @isTest
    static void testEngageDigitalUpdate() {
        Opportunity opp = (Opportunity) new OpportunitySelector().selectOpportunities().executeQuery()[0];
        createQuotesForOpportunity(
            opp,
            QuoteHelper.RT_ID_SALES,
            Product2Helper.PRODUCT_ID_ENGAGE_DIGITAL_STANDALONE,
            1
        );

        Test.startTest();
        opp.StageName = OpportunityHelper.STAGE_NAME_CLOSED_WON;
        opp.Estimated_12M_Engage_Digital_Pipeline__c = 1;
        update opp;
        Test.stopTest();

        List<Contact> assertContacts = (List<Contact>) new ContactSelector()
            .selectContacts()
            .selectField(Contact.Quoted_Products__c)
            .executeQuery();

        System.assertEquals(true, assertContacts[0].Quoted_Products__c.contains('Engage Digital'));
        System.assertEquals(true, assertContacts[1].Quoted_Products__c.contains('Engage Digital'));
    }

    @isTest
    static void testEngageVoiceUpdate() {
        Opportunity opp = (Opportunity) new OpportunitySelector().selectOpportunities().executeQuery()[0];
        createQuotesForOpportunity(opp, QuoteHelper.RT_ID_SALES, Product2Helper.PRODUCT_ID_ENGAGE_VOICE_STANDALONE, 1);

        Test.startTest();
        opp.StageName = OpportunityHelper.STAGE_NAME_CLOSED_WON;
        opp.Estimated_12M_Engage_Voice_Pipeline__c = 1;
        update opp;
        Test.stopTest();

        List<Contact> assertContacts = (List<Contact>) new ContactSelector()
            .selectContacts()
            .selectField(Contact.Quoted_Products__c)
            .executeQuery();

        System.assertEquals(true, assertContacts[0].Quoted_Products__c.contains('Engage Voice'));
        System.assertEquals(true, assertContacts[1].Quoted_Products__c.contains('Engage Voice'));
    }

    @isTest
    static void testProfessionalServicesUpdate() {
        Opportunity opp = (Opportunity) new OpportunitySelector().selectOpportunities().executeQuery()[0];
        List<Quote> quotes = createQuotesForOpportunity(opp, QuoteHelper.RT_ID_CC_PROSERV, '1', 2);
        Test.startTest();
        createQuoteLineItem(quotes[1], '', OpportunityTriggerHelperRefactored.PRODUCT_CHARGETERM_ONETIME);
        List<Quote> quotesQueried = (List<Quote>) new QuoteSelector()
            .selectQuotesByAccountAndOpportunity(new Set<Id>(), new Set<Id>{ opp.Id })
            .selectFields(OpportunityHelper.quoteFields)
            .subselect(
                new QuoteLineItemSelector()
                    .selectQuoteLineItems()
                    .withoutSelectorFieldsIncluded()
                    .selectFields(OpportunityHelper.qliFields)
            )
            .executeQuery();
        OpportunityHelper.opptyToQuotesMapStatic.get(opp.Id).addAll(quotesQueried);

        opp.StageName = OpportunityHelper.STAGE_NAME_CLOSED_WON;
        update opp;
        Test.stopTest();

        List<Contact> assertContacts = (List<Contact>) new ContactSelector()
            .selectContacts()
            .selectField(Contact.Quoted_Products__c)
            .executeQuery();

        System.assertEquals(true, assertContacts[0].Quoted_Products__c.contains('Professional Services'));
        System.assertEquals(true, assertContacts[1].Quoted_Products__c.contains('Professional Services'));
    }

    @isTest
    static void testGlobalOfficeUpdate() {
        Opportunity opp = (Opportunity) new OpportunitySelector().selectOpportunities().executeQuery()[0];
        Quote quote = createQuotesForOpportunity(opp, QuoteHelper.RT_ID_SALES, '1', 1)[0];

        Test.startTest();
        createQuoteLineItem(quote, 'GOA_Global_Office', '');
        opp.StageName = OpportunityHelper.STAGE_NAME_CLOSED_WON;
        opp.Estimated_12M_Global_Office_Pipeline__c = 1;
        update opp;
        Test.stopTest();

        List<Contact> assertContacts = (List<Contact>) new ContactSelector()
            .selectContacts()
            .selectField(Contact.Quoted_Products__c)
            .executeQuery();

        System.assertEquals(true, assertContacts[0].Quoted_Products__c.contains('Global Office'));
        System.assertEquals(true, assertContacts[1].Quoted_Products__c.contains('Global Office'));
    }

    @isTest
    static void testOfficeUpdate() {
        Opportunity opp = (Opportunity) new OpportunitySelector().selectOpportunities().executeQuery()[0];
        Quote quote = createQuotesForOpportunity(opp, QuoteHelper.RT_ID_SALES, '1', 1)[0];

        Test.startTest();
        createQuoteLineItem(quote, '', '');
        opp.StageName = OpportunityHelper.STAGE_NAME_CLOSED_WON;
        opp.Estimated_12M_Office_Pipeline__c = 1;
        update opp;
        Test.stopTest();

        List<Contact> assertContacts = (List<Contact>) new ContactSelector()
            .selectContacts()
            .selectField(Contact.Quoted_Products__c)
            .executeQuery();

        System.assertEquals(true, assertContacts[0].Quoted_Products__c.contains('Office'));
        System.assertEquals(true, assertContacts[1].Quoted_Products__c.contains('Office'));
    }

    @isTest
    static void testRingCentralVideoUpdate() {
        Opportunity opp = (Opportunity) new OpportunitySelector().selectOpportunities().executeQuery()[0];
        createQuotesForOpportunity(opp, QuoteHelper.RT_ID_SALES, '1', 1);

        Test.startTest();
        opp.Tier_Name__c = 'RC Meetings';
        opp.StageName = OpportunityHelper.STAGE_NAME_CLOSED_WON;
        opp.Estimated_12M_RingCentral_Video_Pipeline__c = 1;
        update opp;
        Test.stopTest();

        List<Contact> assertContacts = (List<Contact>) new ContactSelector()
            .selectContacts()
            .selectField(Contact.Quoted_Products__c)
            .executeQuery();

        System.assertEquals(true, assertContacts[0].Quoted_Products__c.contains('RingCentral Video'));
        System.assertEquals(true, assertContacts[1].Quoted_Products__c.contains('RingCentral Video'));
    }

    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testOppDowngradedNoCustomerNoOpenOpp() {
        Opportunity opp = [SELECT Id, StageName, Downgrade_Reason_Opp__c, Primary_Competitor__c FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        Test.startTest();
        opp.StageName = OpportunityHelper.STAGE_NAME_DOWNGRADED;
        opp.Downgrade_Reason_Opp__c = 'Lost';
        opp.Primary_Competitor__c = 'Unknown';
        update opp;
        Test.stopTest();

        List<Contact> assertContacts = (List<Contact>) new ContactSelector()
            .selectContacts()
            .selectField(Contact.Contact_Status__c)
            .executeQuery();
        }

    @isTest
    static void testOppDowngradedWithCustomerNoOpenOpp() {
        Opportunity oppClose = (Opportunity) new OpportunitySelector()
            .selectOpportunities()
            .selectField(Opportunity.Primary_Opportunity_Contact__c)
            .executeQuery()[0];

        Opportunity oppDowngrade = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.StageName, OpportunityHelper.STAGE_NAME_AGREEMENT)
            .setField(Opportunity.RecordTypeId, OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY)
            .setField(Opportunity.Primary_Opportunity_Contact__c, oppClose.Primary_Opportunity_Contact__c)
            .setField(Opportunity.AccountId, oppClose.AccountId)
            .create()
            .getRecord();

        Test.startTest();
        oppClose.StageName = OpportunityHelper.STAGE_NAME_CLOSED_WON;
        update oppClose;
        oppDowngrade.StageName = OpportunityHelper.STAGE_NAME_DOWNGRADED;
        oppDowngrade.Downgrade_Reason_Opp__c = 'Lost';
        oppDowngrade.Primary_Competitor__c = 'Unknown';
        update oppDowngrade;
        Test.stopTest();

        List<Contact> assertContacts = (List<Contact>) new ContactSelector()
            .selectContactById(new List<Object>{ oppDowngrade.Primary_Opportunity_Contact__c })
            .selectField(Contact.Contact_Status__c)
            .executeQuery();

        System.assertEquals(ContactTriggerHandler.CONTACT_STATUS_CUSTOMER, assertContacts[0].Contact_Status__c);
    }

    @isTest
    static void testOppDowngradedNoCustomerWithOpenOpp() {
        Opportunity opp = (Opportunity) new OpportunitySelector()
            .selectOpportunities()
            .selectField(Opportunity.Primary_Opportunity_Contact__c)
            .executeQuery()[0];

        Opportunity oppDowngrade = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.StageName, OpportunityHelper.STAGE_NAME_AGREEMENT)
            .setField(Opportunity.RecordTypeId, OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY)
            .setField(Opportunity.Primary_Opportunity_Contact__c, opp.Primary_Opportunity_Contact__c)
            .setField(Opportunity.AccountId, opp.AccountId)
            .create()
            .getRecord();

        Test.startTest();
        oppDowngrade.StageName = OpportunityHelper.STAGE_NAME_DOWNGRADED;
        oppDowngrade.Downgrade_Reason_Opp__c = 'Lost';
        oppDowngrade.Primary_Competitor__c = 'Unknown';
        update oppDowngrade;
        Test.stopTest();

        List<Contact> assertContacts = (List<Contact>) new ContactSelector()
            .selectContactById(new List<Object>{ oppDowngrade.Primary_Opportunity_Contact__c })
            .selectField(Contact.Contact_Status__c)
            .executeQuery();

        System.assertEquals(ContactTriggerHandler.CONTACT_STATUS_WORKINGOPP, assertContacts[0].Contact_Status__c);
    }

    @isTest
    static void testOppClosedWithOpenOpp() {
        Opportunity oppClose = (Opportunity) new OpportunitySelector()
            .selectOpportunities()
            .selectField(Opportunity.Primary_Opportunity_Contact__c)
            .executeQuery()[0];

        Opportunity oppOpen = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.StageName, OpportunityHelper.STAGE_NAME_AGREEMENT)
            .setField(Opportunity.RecordTypeId, OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY)
            .setField(Opportunity.Primary_Opportunity_Contact__c, oppClose.Primary_Opportunity_Contact__c)
            .setField(Opportunity.AccountId, oppClose.AccountId)
            .create()
            .getRecord();

        Test.startTest();
        oppClose.StageName = OpportunityHelper.STAGE_NAME_CLOSED_WON;
        update oppClose;
        Test.stopTest();

        List<Contact> assertContacts = (List<Contact>) new ContactSelector()
            .selectContactById(new List<Object>{ oppClose.Primary_Opportunity_Contact__c })
            .selectField(Contact.Contact_Status__c)
            .executeQuery();

        System.assertEquals(ContactTriggerHandler.CONTACT_STATUS_WORKINGOPP, assertContacts[0].Contact_Status__c);
    }

    @isTest
    static void testPrimaryOppContactUpdate() {
        List<Contact> con = (List<Contact>) new ContactSelector()
            .selectContactsByEmail(
                new List<Object>{
                    new List<String>{ 'Contact' },
                    new List<String>{ 'Role' },
                    new List<String>{ 'contact@role.con' }
                }
            )
            .executeQuery();
        Opportunity opp = (Opportunity) new OpportunitySelector()
            .selectOpportunities()
            .selectField(Opportunity.Primary_Opportunity_Contact__c)
            .executeQuery()[0];

        Id previousPrimary = opp.Primary_Opportunity_Contact__c;

        List<OpportunityContactRole> oppConRoles = (List<OpportunityContactRole>) new OpportunityContactRoleSelector()
            .selectOpportunityContactRolesByListConIds(new List<Object>{ new Set<Id>{ previousPrimary } })
            .executeQuery();

        Test.startTest();
        opp.Primary_Opportunity_Contact__c = con[0].Id;
        update opp;
        delete oppConRoles;
        Test.stopTest();

        Map<Id, Contact> assertContacts = new Map<Id, Contact>(
            (List<Contact>) new ContactSelector()
                .selectContactsByIds(
                    new List<Object>{ new Set<id>{ opp.Primary_Opportunity_Contact__c, previousPrimary } }
                )
                .selectField(Contact.Contact_Status__c)
                .executeQuery()
        );

        System.assertEquals(
            ContactTriggerHandler.CONTACT_STATUS_WORKINGOPP,
            assertContacts.get(opp.Primary_Opportunity_Contact__c).Contact_Status__c,
            'Contact Status should be 3. Working Opp for Contacts with open Opportunities'
        );
        System.assertEquals(
            ContactTriggerHandler.CONTACT_STATUS_WORKINGOPP,
            assertContacts.get(previousPrimary).Contact_Status__c,
            'Contact Status should be 3. Working Opp for Contacts with open Opportunities'
        );
    }

    @isTest
    static void testSetCustomerRecordFalse() {
        Opportunity opp = (Opportunity) new OpportunitySelector().selectOpportunities().executeQuery()[0];
        Quote quote = createQuotesForOpportunity(opp, QuoteHelper.RT_ID_SALES, '1', 1)[0];

        List<Contact> con = (List<Contact>) new ContactSelector()
            .selectContactsByEmail(
                new List<Object>{
                    new List<String>{ 'Contact' },
                    new List<String>{ 'Role' },
                    new List<String>{ 'contact@role.con' }
                }
            )
            .executeQuery();

        List<OpportunityContactRole> oppConRoles = (List<OpportunityContactRole>) new OpportunityContactRoleSelector()
            .selectOpportunityContactRolesByListConIds(new List<Object>{ new Set<Id>{ con[0].Id } })
            .executeQuery();

        Test.startTest();
        createQuoteLineItem(quote, '', '');
        opp.StageName = OpportunityHelper.STAGE_NAME_CLOSED_WON;
        update opp;
        delete oppConRoles;
        Test.stopTest();

        List<Contact> assertContacts = (List<Contact>) new ContactSelector()
            .selectContactsByIds(new List<Object>{ new Set<id>{ con[0].Id } })
            .selectField(Contact.Customer_Record__c)
            .selectField(Contact.Quoted_Products__c)
            .executeQuery();

        System.assertEquals(false, assertContacts[0].Customer_Record__c);
        System.assertEquals(null, assertContacts[0].Quoted_Products__c);
    }

    @isTest
    static void testCustomerRecordTrueForRCESBUser() {
        User allowedUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(User.SObjectType))
            .setFields(
                new Map<SObjectField, Object>{
                    User.UserPermissionsMarketingUser => true,
                    User.UserName => 'RCTest@user.com',
                    User.CommunityNickname => 'rcTest'
                }
            )
            .create()
            .getRecord();

        Contact_Customer_Status_Users__c ContactStatusCS = new Contact_Customer_Status_Users__c(
            SetupOwnerId = allowedUser.Id,
            isPopulatingCustomer__c = true
        );
        insert ContactStatusCS;
        Account testAcc = (Account) new AccountSelector()
            .selectAccountByName(new List<Object>{ 'Test account' })
            .executeQuery()[0];
        Test.startTest();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Pepe',
                    Contact.LastName => 'Test',
                    Contact.Email => 'thisIsAEmailTest@TessstingEmail.com',
                    Contact.Phone => '1234567890',
                    Contact.AccountId => testAcc.Id,
                    Contact.Contact_Status__c => null,
                    Contact.RCService_ContactStatus__c => 'Active'
                }
            )
            .createAsUser(allowedUser)
            .getRecord();

        Opportunity opp = (Opportunity) new OpportunitySelector().selectOpportunities().executeQuery()[0];
        opp.Primary_Opportunity_Contact__c = con.Id;
        update opp;
        Test.getEventBus().deliver();
        Test.stopTest();

        Contact testContact = (Contact) new ContactSelector()
            .selectContactsByIds(new List<Object>{ new Set<Id>{ con.Id } })
            .selectField(Contact.Customer_Record__c)
            .executeQuery()[0];
        System.assert(testContact.Customer_Record__c, 'Customer_Record__c changed to False for RCESB user');
    }

    @isTest
    static void testCloseOppUpdatesContactStatusToClosedWonOpp() {
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
        Opportunity opp = (Opportunity) new OpportunitySelector().selectOpportunities().executeQuery()[0];

        Contact con = (Contact) new ContactSelector()
            .selectContactsByEmail(
                new List<Object>{
                    new List<String>{ 'Contact' },
                    new List<String>{ 'Role' },
                    new List<String>{ 'contact@role.con' }
                }
            )
            .executeQuery()[0];

        acc.RC_Account_Status__c = 'Other';
        update acc;
        Test.startTest();
        opp.StageName = OpportunityHelper.STAGE_NAME_CLOSED_WON;
        update opp;
        Test.getEventBus().deliver();
        Test.stopTest();
        List<Contact> assertContacts = (List<Contact>) new ContactSelector()
            .selectContactsByIds(new List<Object>{ new Set<id>{ con.Id } })
            .selectField(Contact.Contact_Status__c)
            .executeQuery();

        System.assertEquals(
            ContactTriggerHandler.CONTACT_STATUS_CLOSED_WON_OPP,
            assertContacts[0].Contact_Status__c,
            'Contact Status should be 3.5 Closed Won Opp for Contacts without Account Status Paid or Trial'
        );
    }

    @isTest
    static void testContactStatusUpdateToCustomerWhenAccountIsPaid() {
        User allowedUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(User.SObjectType))
            .setFields(
                new Map<SObjectField, Object>{
                    User.UserPermissionsMarketingUser => true,
                    User.UserName => 'RCTest@user.com',
                    User.CommunityNickname => 'rcTest'
                }
            )
            .create()
            .getRecord();

        Contact_Customer_Status_Users__c ContactStatusCS = new Contact_Customer_Status_Users__c(
            SetupOwnerId = allowedUser.Id,
            isPopulatingCustomer__c = true
        );
        insert ContactStatusCS;

        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Pepe',
                    Contact.LastName => 'Test',
                    Contact.Email => 'thisIsAEmailTest@TessstingEmail.com',
                    Contact.Phone => '1234567890',
                    Contact.AccountId => acc.Id,
                    Contact.RCService_ContactStatus__c => 'Active'
                }
            )
            .createAsUser(allowedUser)
            .getRecord();
        
        Opportunity opp = (Opportunity) new OpportunitySelector().selectOpportunities().executeQuery()[0];

        acc.RC_Account_Status__c = 'Other';
        update acc;

        Test.startTest();
        opp.StageName = OpportunityHelper.STAGE_NAME_CLOSED_WON;
        update opp;
        Test.getEventBus().deliver();
        acc.RC_Account_Status__c = AccountHelper.PAID_STATUS;
        update acc;
        Test.stopTest();

        Contact testContact = (Contact) new ContactSelector()
            .selectContactsByIds(new List<Object>{ new Set<Id>{ con.Id } })
            .selectField(Contact.Contact_Status__c)
            .selectField(Contact.Customer_Record__c)
            .executeQuery()[0];

        System.assertEquals(
            ContactTriggerHandler.CONTACT_STATUS_CUSTOMER,
            testContact.Contact_Status__c,
            'Contact_Status__c should be 4. Customer when Account is paid'
        );
        System.assert(testContact.Customer_Record__c, 'Customer_Record__c should be true when Account is paid');
    }

    @isTest
    static void testContactStatusDoNotUpdateToCustomerWhenAccountIsPaid() {
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
        Opportunity opp = (Opportunity) new OpportunitySelector().selectOpportunities().executeQuery()[0];
		
        
        acc.RC_Account_Status__c = 'Other';
        update acc;

        Test.startTest();
        acc.RC_Account_Status__c = AccountHelper.PAID_STATUS;
        update acc;
        Test.getEventBus().deliver();
        Test.stopTest();

        Contact con = (Contact) new ContactSelector()
            .selectContactsByEmail(
                new List<Object>{
                    new List<String>{ 'Contact' },
                    new List<String>{ 'Role' },
                    new List<String>{ 'contact@role.con' }
                }
            )
            .selectField(Contact.Contact_Status__c)
            .selectField(Contact.Customer_Record__c)
            .executeQuery()[0];

        System.assertEquals(
            ContactTriggerHandler.CONTACT_STATUS_WORKINGOPP,
            con.Contact_Status__c,
            'Contact_Status__c should be 3. Working Opp when Account is paid'
        );
        System.assert(!con.Customer_Record__c, 'Customer_Record__c should be false when Account is paid');
    }

    @isTest
    static void testContactStatusOnContactStatusNotChangeToDowngradedWhenAccountIsCancel() {
        Triggers.switchOff();
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
        acc.RC_Account_Status__c = 'Canceled';
        update acc;
        Triggers.switchOn();
        Test.startTest();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'John')
            .setField(Contact.LastName, 'Doe')
            .setField(Contact.Email, 'johndoe@test.test')
            .setField(Contact.Phone, '12345678')
            .setField(Contact.Contact_Status__c, LeadTriggerHelper.LEADSTATUSNEW)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.AccountId, acc.Id)
            .create()
            .getRecord();

        con.Contact_Status__c = LeadTriggerHelper.LEADSTATUSCONTACTED;
        update con;
        Test.stopTest();

        Contact testCon = (Contact) new ContactSelector()
            .selectContactsByEmail(
                new List<Object>{
                    new List<String>{ 'John' },
                    new List<String>{ 'Doe' },
                    new List<String>{ 'johndoe@test.test' }
                }
            )
            .selectField(Contact.Contact_Status__c)
            .executeQuery()[0];

        System.assertEquals(
            LeadTriggerHelper.LEADSTATUSCONTACTED,
            testCon.Contact_Status__c,
            'Contact Status should be Contacted'
        );
    }

    @isTest
    static void testContactStatusOnContactStatusNotChangeToDowngradedWhenAccountChurnDatePopulated() {
        Triggers.switchOff();
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
        acc.RC_Account_Status__c = '';
        acc.RC_Churn_Date__c = Datetime.now();
        update acc;
        Triggers.switchOn();
        Test.startTest();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'John')
            .setField(Contact.LastName, 'Doe')
            .setField(Contact.Email, 'johndoe@test.test')
            .setField(Contact.Phone, '12345678')
            .setField(Contact.Contact_Status__c, LeadTriggerHelper.LEADSTATUSNEW)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.AccountId, acc.Id)
            .create()
            .getRecord();

        con.Contact_Status__c = LeadTriggerHelper.LEADSTATUSCONTACTED;
        update con;
        Test.stopTest();

        Contact testCon = (Contact) new ContactSelector()
            .selectContactsByEmail(
                new List<Object>{
                    new List<String>{ 'John' },
                    new List<String>{ 'Doe' },
                    new List<String>{ 'johndoe@test.test' }
                }
            )
            .selectField(Contact.Contact_Status__c)
            .executeQuery()[0];

        System.assertEquals(
            LeadTriggerHelper.LEADSTATUSCONTACTED,
            testCon.Contact_Status__c,
            'Contact Status should be Contacted'
        );
    }

    @isTest
    static void testAddContactsForHandRaiseEmail() {
        Triggers.switchOff();
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
        acc.RC_Account_Status__c = 'Cancelled';
        update acc;
        Triggers.switchOn();
        Test.startTest();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'John')
            .setField(Contact.LastName, 'Doe')
            .setField(Contact.Email, 'johndoe@test.test')
            .setField(Contact.Phone, '123456487')
            .setField(Contact.Contact_Status__c, LeadTriggerHelper.LEADSTATUSNEW)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.AccountId, acc.Id)
            .create()
            .getRecord();

        con.Contact_Status__c = LeadTriggerHelper.LEADSTATUSCONTACTED;
        update con;
        Test.getEventBus().deliver();
        Test.stopTest();

        List<Exception_And_Notification_History__c> eanhRecords = (List<Exception_And_Notification_History__c>) new ExceptionAndNotificationHistorySelector()
            .selectExceptionAndNotificationHistorys()
            .selectField(Exception_and_Notification_History__c.Affected_record_ID__c)
            .executeQuery();

        System.assert(eanhRecords[0].Affected_record_ID__c.contains(con.Id), 'EANH record should contain contact id');
    }

    @isTest
    static void testSendHandRaiseEmail() {
        insert new Feature_Toggle__c(Hand_Raise_Email_Sending__c = true);
        Id handRaiseRecordTypeId = Schema.SObjectType.Exception_And_Notification_History__c.getRecordTypeInfosByName()
            .get('Hand Raise Email Sending')
            .getRecordTypeId();
        List<Contact> conList = (List<Contact>) new ContactSelector().selectContacts().executeQuery();
        String affectedIds = conList[0].Id + ',' + conList[1].Id;
        Exception_And_Notification_History__c eanh = (Exception_And_Notification_History__c) new SObjectBuilder(
                Exception_And_Notification_History__c.SObjectType
            )
            .setField(Exception_And_Notification_History__c.RecordTypeId, handRaiseRecordTypeId)
            .setField(Exception_And_Notification_History__c.Affected_record_ID__c, affectedIds)
            .create()
            .getRecord();

        Test.startTest();
        ContactUpdatePlatformEventsHelper.sendAccCancelledNotification();
        List<Exception_And_Notification_History__c> eanhRecords = (List<Exception_And_Notification_History__c>) new ExceptionAndNotificationHistorySelector()
            .selectExceptionAndNotificationHistorys()
            .executeQuery();

        System.assertEquals(0, eanhRecords.size(), 'All EANH records shuold be deleted');
        System.assertEquals(1, Limits.getEmailInvocations(), '1 Email invocation should be done');
        Test.stopTest();
    }

    static List<Quote> createQuotesForOpportunity(
        Opportunity opp,
        Id quoteRecordTypeId,
        String productId,
        Integer quantity
    ) {
        List<Quote> quotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => ValueProviderBuilder.provideUniqueString('Test Quote'),
                    Quote.OpportunityId => opp.Id,
                    Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                    Quote.Approved_Status__c => QuoteHelper.APPROVAL_STATUS_NOT_REQUIRED,
                    Quote.Total_Number_of_Digital_Lines__c => 1,
                    Quote.Start_Date__c => Date.today(),
                    Quote.End_Date__c => Date.today().addDays(2),
                    Quote.RecordTypeId => quoteRecordTypeId,
                    Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo(
                        new Map<String, Object>{ 'productId' => productId }
                    ),
                    Quote.Pricebook2Id => Test.getStandardPricebookId(),
                    Quote.HasContactCenter__c => true,
                    Quote.ProServ_Status__c => 'Created',
                    Quote.Delta_CC_ARR__c => 100,
                    Quote.Delta_ARR__c => 100
                }
            )
            .quantity(quantity)
            .create()
            .getRecords();
        return quotes;
    }

    static void createQuoteLineItem(Quote quote, String goaGroup, String changeTerm) {
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];

        Product2 prod = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Product2.Name => 'Test Product',
                    Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                    Product2.IsActive => true,
                    Product2.GOA_Group_V2__c => goaGroup,
                    Product2.Charge_Term__c => changeTerm
                }
            )
            .create()
            .getRecord();

        PricebookEntry pbe = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                    PricebookEntry.Product2Id => prod.Id,
                    PricebookEntry.UnitPrice => 0,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false,
                    PricebookEntry.CurrencyIsoCode => RingCentralHelper.USD
                }
            )
            .create()
            .getRecord();

        Entitlement__c ent = (Entitlement__c) new SObjectBuilder(Entitlement__c.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Entitlement__c.Quote__c => quote.Id,
                    Entitlement__c.Account__c => acc.Id,
                    Entitlement__c.Product__c => prod.Id,
                    Entitlement__c.Quantity__c => 1,
                    Entitlement__c.Price__c => 50,
                    Entitlement__c.ChargeTerm__c => Product2Helper.CHARGE_TERM_MONTHLY,
                    Entitlement__c.Discount__c => 10,
                    Entitlement__c.Discount_Type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                    Entitlement__c.PackageCatalogId__c => '7',
                    Entitlement__c.PackageVersion__c => '1',
                    Entitlement__c.Active__c => true
                }
            )
            .create()
            .getRecord();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    QuoteLineItem.Product2Id => prod.Id,
                    QuoteLineItem.QuoteId => quote.Id,
                    QuoteLineItem.Entitlement__c => ent.Id,
                    QuoteLineItem.Quantity => 1,
                    QuoteLineItem.NewQuantity__c => 1,
                    QuoteLineItem.Zero_Quantity__c => false,
                    QuoteLineItem.UnitPrice => 50,
                    QuoteLineItem.PricebookEntryId => pbe.Id,
                    QuoteLineItem.Delta_ARR__c => 100
                }
            )
            .create()
            .getRecord();
    }
}