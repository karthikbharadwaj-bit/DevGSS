@isTest
public with sharing class Test_Batchjob_ContactStatusFieldFix {
    @isTest
    public static void ContactStatusIs2ContactedAndAccountStatusContainsTrial_WhenRunBatchJob_ShouldUpdateContactStatusTo4Customer() {

        Triggers.switchOff();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Account test')
            .setField(Account.RC_Account_Status__c, 'XtrialX')
            .create()
            .getRecord();

        List<Contact> contacts = (List<Contact>) new sObjectBuilder(Contact.sObjectType)
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.FirstName, 'Ronaldo')
            .setField(Contact.LastName, 'Test')
            .setField(Contact.Customer_Record__c, false)
            .setField(Contact.Contact_Status__c, '2. Contacted')
            .setField(Contact.Quoted_Products__c, 'Office;Contact Center;Engage Voice')
            .quantity(20)
            .create()
            .getRecords();

        List<Opportunity> opportunities = (List<Opportunity>) new sObjectBuilder(Opportunity.sObjectType)
            .setField(Opportunity.Name, 'Opp test')
            .setField(Opportunity.StageName, '7. Closed Won')
            .setField(Opportunity.CloseDate, system.today().addMonths(1))
            .setField(Opportunity.AccountId, acc.Id)
            .setField(Opportunity.Estimated_12M_Engage_Voice_Pipeline__c, 2.0)
            .setField(Opportunity.Estimated_12M_RingCentral_Video_Pipeline__c, 2.0)
            .setField(Opportunity.EstimatedProfessionalServices12Month__c, 2.0)
            .quantity(20)
            .create()
            .getRecords();
        
        List<OpportunityContactRole> oppContRoles = new List<OpportunityContactRole>();
        
        for (Integer i=0; i < 20; i++) {
            oppContRoles.add((OpportunityContactRole) new SObjectBuilder(OpportunityContactRole.SObjectType)
                .setField(OpportunityContactRole.OpportunityId, opportunities[i].Id)
                .setField(OpportunityContactRole.ContactId, contacts[i].Id)
                .build()
                .getRecord()
            );
        }

        insert oppContRoles;
        Triggers.switchOn();
        Test.startTest();
            Database.executeBatch(new Batchjob_ContactStatusFieldFix(Datetime.now().addDays(-1), Datetime.now().AddDays(1)));
        Test.stopTest();

        contacts = (List<Contact>) new ContactSelector()
            .selectContactsByAccountId(new Object[]{acc.Id})
            .selectField(Contact.Quoted_Products__c)
            .selectField(Contact.Contact_Status__c)
            .selectField(Contact.Customer_Record__c)
            .executeQuery();

        System.assertEquals(20, contacts.size(), 'Should be 20 contacts');

        for (Contact cont : contacts) {
            System.assertEquals('Office;Contact Center;Engage Voice;RingCentral Video;Professional Services', cont.Quoted_Products__c);
            System.assertEquals('4. Customer', cont.Contact_Status__c);
            System.assertEquals(true, cont.Customer_Record__c);
        }
    }
    @isTest
    public static void ContactStatusIs2ContactedAndAccountStatusIsPaid_WhenRunBatchJob_ShouldUpdateContactStatusTo4Customer() {

        Triggers.switchOff();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Account test')
            .setField(Account.RC_Account_Status__c, 'Paid')
            .create()
            .getRecord();

        List<Contact> contacts = (List<Contact>) new sObjectBuilder(Contact.sObjectType)
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.FirstName, 'Ronaldo')
            .setField(Contact.LastName, 'Test')
            .setField(Contact.Customer_Record__c, false)
            .setField(Contact.Contact_Status__c, '2. Contacted')
            .setField(Contact.Quoted_Products__c, 'Engage Voice')
            .quantity(20)
            .create()
            .getRecords();

        List<Opportunity> opportunities = (List<Opportunity>) new sObjectBuilder(Opportunity.sObjectType)
            .setField(Opportunity.Name, 'Opp test')
            .setField(Opportunity.StageName, '7. Closed Won')
            .setField(Opportunity.CloseDate, system.today().addMonths(1))
            .setField(Opportunity.AccountId, acc.Id)
            .setField(Opportunity.Estimated_12M_Engage_Voice_Pipeline__c, 2.0)
            .setField(Opportunity.Estimated_12M_RingCentral_Video_Pipeline__c, 2.0)
            .setField(Opportunity.EstimatedProfessionalServices12Month__c, 2.0)
            .quantity(20)
            .create()
            .getRecords();
        
        List<OpportunityContactRole> oppContRoles = new List<OpportunityContactRole>();
        
        for (Integer i=0; i < 20; i++) {
            oppContRoles.add((OpportunityContactRole) new SObjectBuilder(OpportunityContactRole.SObjectType)
                .setField(OpportunityContactRole.OpportunityId, opportunities[i].Id)
                .setField(OpportunityContactRole.ContactId, contacts[i].Id)
                .build()
                .getRecord()
            );
        }

        insert oppContRoles;
        Triggers.switchOn();
        Test.startTest();
            Database.executeBatch(new Batchjob_ContactStatusFieldFix(Datetime.now().addDays(-1), Datetime.now().AddDays(1)));
        Test.stopTest();

        contacts = (List<Contact>) new ContactSelector()
            .selectContactsByAccountId(new Object[]{acc.Id})
            .selectField(Contact.Quoted_Products__c)
            .selectField(Contact.Contact_Status__c)
            .selectField(Contact.Customer_Record__c)
            .executeQuery();

        System.assertEquals(20, contacts.size(), 'Should be 20 contacts');

        for (Contact cont : contacts) {
            System.assertEquals('Engage Voice;RingCentral Video;Professional Services', cont.Quoted_Products__c);
            System.assertEquals('4. Customer', cont.Contact_Status__c);
            System.assertEquals(true, cont.Customer_Record__c);
        }
    }
    @isTest
    public static void ContactStatusIs2ContactedAndAccountStatusIsNotPaidAndDoesntContainTrial_WhenRunBatchJob_ShouldUpdateContactStatusTo4Customer() {

        Triggers.switchOff();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Account test')
            .create()
            .getRecord();

        List<Contact> contacts = (List<Contact>) new sObjectBuilder(Contact.sObjectType)
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.FirstName, 'Ronaldo')
            .setField(Contact.LastName, 'Test')
            .setField(Contact.Customer_Record__c, true)
            .setField(Contact.Contact_Status__c, '2. Contacted')
            .setField(Contact.Quoted_Products__c, 'Office;Contact Center;Engage Voice')
            .quantity(20)
            .create()
            .getRecords();

        List<Opportunity> opportunities = (List<Opportunity>) new sObjectBuilder(Opportunity.sObjectType)
            .setField(Opportunity.Name, 'Opp test')
            .setField(Opportunity.StageName, '7. Closed Won')
            .setField(Opportunity.CloseDate, system.today().addMonths(1))
            .setField(Opportunity.AccountId, acc.Id)
            .setField(Opportunity.Estimated_12M_Engage_Voice_Pipeline__c, 2.0)
            .setField(Opportunity.Estimated_12M_RingCentral_Video_Pipeline__c, 2.0)
            .setField(Opportunity.EstimatedProfessionalServices12Month__c, 2.0)
            .quantity(20)
            .create()
            .getRecords();
        
        List<OpportunityContactRole> oppContRoles = new List<OpportunityContactRole>();
        
        for (Integer i=0; i < 20; i++) {
            oppContRoles.add((OpportunityContactRole) new SObjectBuilder(OpportunityContactRole.SObjectType)
                .setField(OpportunityContactRole.OpportunityId, opportunities[i].Id)
                .setField(OpportunityContactRole.ContactId, contacts[i].Id)
                .build()
                .getRecord()
            );
        }

        insert oppContRoles;
        Triggers.switchOn();
        Test.startTest();
            Database.executeBatch(new Batchjob_ContactStatusFieldFix(Datetime.now().addDays(-1), Datetime.now().AddDays(1)));
        Test.stopTest();

        contacts = (List<Contact>) new ContactSelector()
            .selectContactsByAccountId(new Object[]{acc.Id})
            .selectField(Contact.Quoted_Products__c)
            .selectField(Contact.Contact_Status__c)
            .executeQuery();

        System.assertEquals(20, contacts.size(), 'Should be 20 contacts');

        for (Contact cont : contacts) {
            System.assertEquals('Office;Contact Center;Engage Voice', cont.Quoted_Products__c);
            System.assertEquals('3.5 Closed Won Opp', cont.Contact_Status__c);
        }
    }
}