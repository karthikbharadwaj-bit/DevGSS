@isTest
public class Test_Queueable_DG_DFR_Class {
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void TestMethod1() {
        Boolean result = Queueable_DG_DFR_Class.isQueueuableLimitsReached();
        
        Account testSetupAccount = new Account(Name = 'Test Account',
                                                Partner_ID__c = 'testIDAcc',
                                                Permitted_Brands__c = 'RingCentral');
        insert testSetupAccount;
		
        List<Contact> listContacts = new List<Contact>();
        Contact testSetupContact = new Contact(LastName = 'Test Contact',
                                                Preferred_Language__c = 'en_US',
                                                AccountId = testSetupAccount.Id,
                                                Email = 'test@domaintest.com',
                                                Phone = '+18885550505',
                                                CurrencyIsoCode = 'USD');
        listContacts.add(testSetupContact);
        
        Contact testSetupContact2 = new Contact(LastName = 'Test Contact2',
                                                Preferred_Language__c = 'en_US',
                                                AccountId = testSetupAccount.Id,
                                                Email = 'test2@domaintest.com',
                                                Phone = '+18885550505',
                                                CurrencyIsoCode = 'USD');
        listContacts.add(testSetupContact2);
        insert listContacts;
		Triggers.switchOff();
        List<Contact> multiContacts = new List<Contact>();
        for (integer i = 0; i < 51; i++) {
            Contact testContact = new Contact(LastName = 'Test Contact ' +i,
                                                Preferred_Language__c = 'en_US',
                                                AccountId = testSetupAccount.Id,
                                                Email = 'test'+i+'@domaintest.com',
                                                Phone = '+18885550505',
                                                CurrencyIsoCode = 'USD');
        	multiContacts.add(testContact);
        }
        insert multiContacts;
        Triggers.switchOn();
        Map<Id, Contact> oldContactMap = new Map<Id, Contact>(listContacts);

        testSetupContact.Email = 'test@rc.com';
        testSetupContact2.Email = 'test2@rc.com';
        List<Contact> updatingItems = new List<Contact> {testSetupContact, testSetupContact2};
        Test.startTest();
        Queueable_DG_DFR_Class.DFR_Contacts qdfr = new Queueable_DG_DFR_Class.DFR_Contacts(updatingItems, oldContactMap); 
		System.enqueueJob(qdfr);
        
        Contact testSetupContact3 = new Contact(LastName = 'Test Contact3',
                                                Preferred_Language__c = 'en_US',
                                                AccountId = testSetupAccount.Id,
                                                Email = 'test@domaintest.com',
                                                Phone = '+18885550505',
                                                CurrencyIsoCode = 'USD');
        
        Contact testSetupContact4 = new Contact(LastName = 'Test Contact4',
                                                Preferred_Language__c = 'en_US',
                                                AccountId = testSetupAccount.Id,
                                                Email = 'test@domaintest.com',
                                                Phone = '+18885550505',
                                                CurrencyIsoCode = 'USD');
        List<Contact> newContacts = new List<Contact> { testSetupContact3, testSetupContact4 };
        Queueable_DG_DFR_Class.DFR_Contacts qdfr2 = new Queueable_DG_DFR_Class.DFR_Contacts(newContacts, null); 
        System.enqueueJob(qdfr2);
        
        Map<Id, Contact> multiContactMap = new Map<Id, Contact>(multiContacts);
        Queueable_DG_DFR_Class.DFR_Contacts qdfr3 = new Queueable_DG_DFR_Class.DFR_Contacts(multiContacts, multiContactMap); 
        System.enqueueJob(qdfr3);
        Test.stopTest();
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void TestMethod2() {
        
        Account testSetupAccount = new Account(Name = 'Test Account',
                                                Partner_ID__c = 'testIDAcc',
                                                Permitted_Brands__c = 'RingCentral');
        insert testSetupAccount;

        Contact testSetupContact = new Contact(LastName = 'Test Contact',
                                                Preferred_Language__c = 'en_US',
                                                AccountId = testSetupAccount.Id,
                                                Email = 'test@domaintest.com',
                                                Phone = '+18885550505',
                                                CurrencyIsoCode = 'USD');
        insert testSetupContact;
        
        Triggers.switchOff();
        Opportunity testSetupOpportunity = new Opportunity(Name = 'Test Oppty',
                                                            CurrencyIsoCode = 'USD',
                                                            AccountId = testSetupAccount.Id,
                                                            StageName = '4. Proof',
                                                            RecordTypeId = OpportunityHelper.RT_ID_SALES_OPPORTUNITY,
                                                            Primary_Opportunity_Contact__c = testSetupContact.Id,
                                                            Tier_Name__c = 'Fax1000',
                                                            Brand_Name__c = 'RingCentral',
                                                            CloseDate = System.Today(),
                                                            Forecasted_Users__c = 23);
        insert testSetupOpportunity;
        Triggers.switchOn();
        Test.startTest();
            List<Opportunity> oppList = new List<Opportunity> {testSetupOpportunity};
            Queueable_DG_DFR_Class.DFR_AddOpportunity qdfr = new Queueable_DG_DFR_Class.DFR_AddOpportunity(oppList, true);
            System.enqueueJob(qdfr);

            Queueable_DG_DFR_Class.DFR_AddOpportunity qdfr2 = new Queueable_DG_DFR_Class.DFR_AddOpportunity(oppList, false);
            System.enqueueJob(qdfr2);
        Test.stopTest();

    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void TestMethod3() {
        
        Account testSetupAccount = new Account(Name = 'Test Account',
                                                Partner_ID__c = 'testIDAcc',
                                                Permitted_Brands__c = 'RingCentral');
        insert testSetupAccount;

        Contact testSetupContact = new Contact(LastName = 'Test Contact',
                                                Preferred_Language__c = 'en_US',
                                                AccountId = testSetupAccount.Id,
                                                Email = 'test@domaintest.com',
                                                Phone = '+18885550505',
                                                CurrencyIsoCode = 'USD');
        insert testSetupContact;

        Triggers.switchOff();
        List<Opportunity> opptyList = new List<Opportunity>();
        for (integer i = 0; i < 11; i++) {
        	Opportunity testSetupOpportunity = new Opportunity(Name = 'Test Oppty',
                                                            CurrencyIsoCode = 'USD',
                                                            AccountId = testSetupAccount.Id,
                                                            StageName = '4. Proof',
                                                            RecordTypeId = OpportunityHelper.RT_ID_SALES_OPPORTUNITY,
                                                            Primary_Opportunity_Contact__c = testSetupContact.Id,
                                                            Tier_Name__c = 'Fax1000',
                                                            Brand_Name__c = 'RingCentral',
                                                            CloseDate = System.Today(),
                                                            Forecasted_Users__c = 23);
            opptyList.add(testSetupOpportunity);
        }
        insert opptyList;
        
        Opportunity finalOpportunity = new Opportunity(Name = 'Test Oppty',
                                                            CurrencyIsoCode = 'USD',
                                                            AccountId = testSetupAccount.Id,
                                                            StageName = '4. Proof',
                                                            RecordTypeId = OpportunityHelper.RT_ID_SALES_OPPORTUNITY,
                                                            Primary_Opportunity_Contact__c = testSetupContact.Id,
                                                            Tier_Name__c = 'Fax1000',
                                                            Brand_Name__c = 'RingCentral',
                                                            CloseDate = System.Today(),
                                                            Forecasted_Users__c = 23);
        insert finalOpportunity;
		Triggers.switchOn();
        Test.startTest();
            Map<Id, Opportunity> oldOpptyMap1 = new Map<Id, Opportunity> (opptyList);
            Queueable_DG_DFR_Class.DFR_OpportunityClosed qdfr = new Queueable_DG_DFR_Class.DFR_OpportunityClosed(opptyList, oldOpptyMap1);
            System.enqueueJob(qdfr);

            List<Opportunity> opptySet2 = new List<Opportunity> {finalOpportunity};
            Map<Id, Opportunity> oldOpptyMap2 = new Map<Id, Opportunity> (opptySet2);
            Queueable_DG_DFR_Class.DFR_OpportunityClosed qdfr2 = new Queueable_DG_DFR_Class.DFR_OpportunityClosed(opptySet2, oldOpptyMap2);
            System.enqueueJob(qdfr2);
        Test.stopTest();
    }
}