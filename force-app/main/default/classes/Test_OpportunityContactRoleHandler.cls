@isTest
public with sharing class Test_OpportunityContactRoleHandler {
    @testSetup
    static void prepareData() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test account')
            .setField(Account.Phone, '5465491')
            .setField(Account.RC_Account_Status__c, 'Paid')
            .create()
            .getRecord();

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Primary')
            .setField(Contact.LastName, 'Contact')
            .setField(Contact.Email, 'primary@contact.con')
            .setField(Contact.Phone, '5465491')
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.AccountId, acc.Id)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.Type, 'Syndicated - New')
            .setField(Opportunity.StageName, '5. Agreement')
            .setField(Opportunity.CloseDate, System.today().addMonths(1))
            .setField(Opportunity.AccountId, acc.Id)
            .setField(Opportunity.CustomerConfirmation__c, 'Pending')
            .create()
            .getRecord();

            PriceBook2 testPB2 = TestDataGenerator.createPricebook2();
            testPB2.Plan__c = 'Monthly';
            update testPB2;
            Quote testQuote1 = TestDataGenerator.createQuote(opp, testPB2);
            testQuote1.RecordTypeId = TestDataGenerator.getQuoteRecordTypeIdByName('Sales_Quote');

    }

    @isTest
    static void testOppConRoleOpenOpp() {
        //Adding the bypasstrigger flag to not trigger the validation when creating contact. PBC-10858
        ByPassTrigger__c byPassTrigger = ByPassTrigger__c.getOrgDefaults();
        byPassTrigger.ByPass_OppContactRole_Validation__c = true;
        insert byPassTrigger;

        Opportunity opp = (Opportunity) new OpportunitySelector().selectOpportunities().executeQuery()[0];
        Contact con = (Contact) new ContactSelector().selectContacts().executeQuery()[0];

        Test.startTest();
        OpportunityContactRole oppConRole = (OpportunityContactRole) new SObjectBuilder(
                OpportunityContactRole.SObjectType
            )
            .setField(OpportunityContactRole.OpportunityId, opp.Id)
            .setField(OpportunityContactRole.ContactId, con.Id)
            .create()
            .getRecord();
        Test.stopTest();
        List<Contact> assertContacts = (List<Contact>) new ContactSelector()
            .selectContacts()
            .selectField(Contact.Contact_Status__c)
            .executeQuery();

        System.assertEquals('3. Working Opp', assertContacts[0].Contact_Status__c);
    }

    @isTest
    static void testOppConRoleClosedWonOpp() {
        //Adding the bypasstrigger flag to not trigger the validation when creating contact. PBC-10858
        ByPassTrigger__c byPassTrigger = ByPassTrigger__c.getOrgDefaults();
        byPassTrigger.ByPass_OppContactRole_Validation__c = true;
        Test.startTest();
        insert byPassTrigger;

        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = true;
        TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = true;
        Opportunity opp = (Opportunity) new OpportunitySelector().selectOpportunities().executeQuery()[0];
        Contact con = (Contact) new ContactSelector().selectContacts().executeQuery()[0];

        opp.StageName = '7. Closed Won';
        update opp;

        OpportunityContactRole oppConRole = (OpportunityContactRole) new SObjectBuilder(
                OpportunityContactRole.SObjectType
            )
            .setField(OpportunityContactRole.OpportunityId, opp.Id)
            .setField(OpportunityContactRole.ContactId, con.Id)
            .create()
            .getRecord();
        Test.stopTest();
        List<Contact> assertContacts = (List<Contact>) new ContactSelector()
            .selectContacts()
            .selectField(Contact.Contact_Status__c)
            .executeQuery();

        system.assertEquals('4. Customer', assertContacts[0].Contact_Status__c);
    }

    @isTest
    static void testOppConRoleDowngradedOpp() {
        //Adding the bypasstrigger flag to not trigger the validation when creating contact. PBC-10858
        ByPassTrigger__c byPassTrigger = ByPassTrigger__c.getOrgDefaults();
        byPassTrigger.ByPass_OppContactRole_Validation__c = true;
        insert byPassTrigger;

        Opportunity opp = (Opportunity) new OpportunitySelector().selectOpportunities().executeQuery()[0];
        Contact con = (Contact) new ContactSelector().selectContacts().executeQuery()[0];

        opp.StageName = '0. Downgraded';
        opp.Downgrade_Reason_Opp__c = 'Lost';
        opp.Primary_Competitor__c = 'Unknown';
        Test.startTest();
        update opp;

        OpportunityContactRole oppConRole = (OpportunityContactRole) new SObjectBuilder(
                OpportunityContactRole.SObjectType
            )
            .setField(OpportunityContactRole.OpportunityId, opp.Id)
            .setField(OpportunityContactRole.ContactId, con.Id)
            .create()
            .getRecord();
        Test.stopTest();
        List<Contact> assertContacts = (List<Contact>) new ContactSelector()
            .selectContacts()
            .selectField(Contact.Contact_Status__c)
            .executeQuery();

        System.assertEquals('0. Downgraded', assertContacts[0].Contact_Status__c);
    }

    @isTest
    static void testDeletePrimaryOppContactRole() {
        //Adding the bypasstrigger flag to not trigger the validation when creating contact. PBC-10858
        ByPassTrigger__c byPassTrigger = ByPassTrigger__c.getOrgDefaults();
        byPassTrigger.ByPass_OppContactRole_Validation__c = true;
        insert byPassTrigger;

        Opportunity opp = (Opportunity) new OpportunitySelector().selectOpportunities().executeQuery()[0];
        Contact con = (Contact) new ContactSelector().selectContacts().executeQuery()[0];

        Test.startTest();
        opp.Primary_Opportunity_Contact__c = con.Id;
        update opp;
        OpportunityContactRole priOppConRole = (OpportunityContactRole) new OpportunityContactRoleSelector()
            .selectOppConRolesByListConIdsAndListOppIds(
                new List<Object>{ new Set<Id>{ opp.Id }, new Set<Id>{ con.Id } }
            )
            .executeQuery()[0];
        Boolean isErrorThrown = false;
        try {
            delete priOppConRole;
        } catch (Exception e) {
            isErrorThrown = true;
            System.assert(
                e.getMessage()
                    .contains(
                        'In order to remove this contact role, you first need to replace it on the Primary Opportunity Contact field.'
                    ),
                'Error message is wrong'
            );
        }
        Test.stopTest();
        System.assert(isErrorThrown, 'No error thrown on primary contact role deletion');
    }

    @isTest
    static void testDeleteNonPrimaryOppContactRole() {
        Triggers.switchOff();
        //Adding the bypasstrigger flag to not trigger the validation when creating contact. PBC-10858
        ByPassTrigger__c byPassTrigger = ByPassTrigger__c.getOrgDefaults();
        byPassTrigger.ByPass_OppContactRole_Validation__c = true;
        insert byPassTrigger;

        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
        Opportunity opp = (Opportunity) new OpportunitySelector().selectOpportunities().executeQuery()[0];
        Contact con = (Contact) new ContactSelector().selectContacts().executeQuery()[0];

        Contact conRole = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Contact')
            .setField(Contact.LastName, 'Role')
            .setField(Contact.Email, 'contact@role.con')
            .setField(Contact.Phone, '5465491')
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.AccountId, acc.Id)
            .create()
            .getRecord();

        opp.Primary_Opportunity_Contact__c = con.Id;
        update opp;
        Triggers.switchOn();
        Test.startTest();
        OpportunityContactRole oppConRole = (OpportunityContactRole) new SObjectBuilder(
                OpportunityContactRole.SObjectType
            )
            .setField(OpportunityContactRole.OpportunityId, opp.Id)
            .setField(OpportunityContactRole.ContactId, conRole.Id)
            .create()
            .getRecord();
        delete oppConRole;
        Test.stopTest();
        List<OpportunityContactRole> oppConRoleList = (List<OpportunityContactRole>) new OpportunityContactRoleSelector()
            .selectOppConRolesByListConIdsAndListOppIds(
                new List<Object>{ new Set<Id>{ opp.Id }, new Set<Id>{ conRole.Id } }
            )
            .executeQuery();
        System.assertEquals(0, oppConRoleList.size(), 'Opportunity Contact Role was not deleted');
    }

    @isTest
    static void testDeletePriOppConRoleWithMoreThanOnePrimary() {
        //Adding the bypasstrigger flag to not trigger the validation when creating contact. PBC-10858
        ByPassTrigger__c byPassTrigger = ByPassTrigger__c.getOrgDefaults();
        byPassTrigger.ByPass_OppContactRole_Validation__c = true;
        insert byPassTrigger;

        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
        Opportunity opp = (Opportunity) new OpportunitySelector().selectOpportunities().executeQuery()[0];
        Contact con = (Contact) new ContactSelector().selectContacts().executeQuery()[0];

        Test.startTest();
        opp.Primary_Opportunity_Contact__c = con.Id;
        update opp;
        OpportunityContactRole oppConRole = (OpportunityContactRole) new SObjectBuilder(
                OpportunityContactRole.SObjectType
            )
            .setField(OpportunityContactRole.OpportunityId, opp.Id)
            .setField(OpportunityContactRole.ContactId, con.Id)
            .create()
            .getRecord();
        List<OpportunityContactRole> oppConRoleList = (List<OpportunityContactRole>) new OpportunityContactRoleSelector()
            .selectOppConRolesByListConIdsAndListOppIds(
                new List<Object>{ new Set<Id>{ opp.Id }, new Set<Id>{ con.Id } }
            )
            .executeQuery();
        System.assertEquals(2, oppConRoleList.size(), 'The number of Opportunity Contact Roles created is not 2');
        Test.stopTest();
        delete oppConRole;
        List<OpportunityContactRole> oppConRolesAfterDelete = (List<OpportunityContactRole>) new OpportunityContactRoleSelector()
            .selectOppConRolesByListConIdsAndListOppIds(
                new List<Object>{ new Set<Id>{ opp.Id }, new Set<Id>{ con.Id } }
            )
            .executeQuery();
        System.assertEquals(1, oppConRolesAfterDelete.size(), 'The Opportunity Contact Role was not deleted');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testUpdatePrimaryContact() {
        //Adding the bypasstrigger flag to not trigger the validation when creating contact. PBC-10858
        ByPassTrigger__c byPassTrigger = ByPassTrigger__c.getOrgDefaults();
        byPassTrigger.ByPass_OppContactRole_Validation__c = true;
        insert byPassTrigger;

        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
        Opportunity opp = (Opportunity) new OpportunitySelector().selectOpportunities().executeQuery()[0];
        Contact con = (Contact) new ContactSelector().selectContacts().executeQuery()[0];
        Quote quo = (Quote) new QuoteSelector().selectQuotes().executeQuery()[0];

        Test.startTest();
        acc.RC_Account_Status__c = 'Active';
        update acc;

        opp.Brand_Name__c = 'RingCentral';
        opp.PrimaryQuote__c = quo.Id;
        update opp;
        OpportunityContactRole oppConRole = (OpportunityContactRole) new SObjectBuilder(
                OpportunityContactRole.SObjectType
            )
            .setField(OpportunityContactRole.OpportunityId, opp.Id)
            .setField(OpportunityContactRole.ContactId, con.Id)
            .setField(OpportunityContactRole.IsPrimary, false)
            .setField(OpportunityContactRole.Role, 'Administrator')
            .create()
            .getRecord();

		oppConRole.Role = 'Signatory';
        oppConRole.IsPrimary = true;
        update oppConRole;
        Test.stopTest();
    }

}