@isTest
private class Test_CompanyPersonSelector {

    //Account fields defined
    private static final String ACCOUNT_NAME = 'Test';
    private static final String ACCOUNT_BILLING_ID = '12345';

    //Lead fields defined
    private static final String LEAD_FIRST_NAME = 'Test';
    private static final String LEAD_LAST_NAME = 'Test';
    private static final String LEAD_EMAIL = 'testlead@test.com';
    private static final String LEAD_COMPANY = 'Test_Company';

    //Account hierarchy fields defined
    private static final String ACCOUNT_HIERARCHY_NAME = 'Test'; 
    private static final String ACCOUNT_HIERARCHY_COMPANY_STATUS = 'Status 1';

    //Contact fields defined
    private static final String CONTACT_FIRST_NAME = 'Test1';
    private static final String CONTACT_LAST_NAME = 'Test1';
    private static final String CONTACT_EMAIL = 'test@test.com';
    private static final String CONTACT_PHONE = '1234567890';
    private static final String CONTACT_PREFFERED_LANGUAGE = 'en_US';

    //Company persons fields defined
    private static final String COMPANY_PERSONS_LS_PERSONA = 'Test';
	
    //Assert message defined
    private static final String ASSERT_MESSAGE = 'Company persons should be selected';
    private static final String ASSERT_EQUALS_MESSAGE = 'Wrong company person selected';
    
    @testSetup
    private static void testData(){
        Account_Hierarchy__c company = (Account_Hierarchy__c) new SObjectBuilder(Account_Hierarchy__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account_Hierarchy__c.Name => ACCOUNT_HIERARCHY_NAME,
                    Account_Hierarchy__c.Company_Status__c => ACCOUNT_HIERARCHY_COMPANY_STATUS
                	}
            )
            .create()
            .getRecord();
        
        Lead testLead = (Lead) new SObjectBuilder(Lead.SobjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Lead.FirstName => LEAD_FIRST_NAME,
                    Lead.LastName => LEAD_LAST_NAME,
                    Lead.Email => LEAD_EMAIL,
                    Lead.Company => LEAD_COMPANY
                }
            )
            .create()
            .getRecord();
        
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ACCOUNT_NAME,
                    Account.Billing_ID__c => ACCOUNT_BILLING_ID
                }
            )
            .create()
            .getRecord();

        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => CONTACT_FIRST_NAME,
                    Contact.LastName => CONTACT_LAST_NAME,
                    Contact.AccountId => testAcc.Id,
                    Contact.Email => CONTACT_EMAIL,
                    Contact.Phone => CONTACT_PHONE,
                    Contact.Preferred_Language__c => CONTACT_PREFFERED_LANGUAGE,
                    Contact.Company__c => company.Id
                }
            )
            .create()
            .getRecord();
        
        Company_Persons__c testCompanyPerson = (Company_Persons__c) new SObjectBuilder(Company_Persons__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Company_Persons__c.Company__c => company.Id,
                    Company_Persons__c.Lead__c => testLead.Id,
                    Company_Persons__c.Contact__c => testContact.Id,
                    Company_Persons__c.LS_Persona__c => COMPANY_PERSONS_LS_PERSONA
                }
            )
            .create()
            .getRecord();
    }

    @isTest
    private static void testSelectCountCompanyPersonsByLeadAndCompanyId(){
        List<Contact> contacts = (List<Contact>) new ContactSelector()
            .selectContacts()
            .executeQuery();
        
        List<Contact> contactsForLeadConversion = (List<Contact>) new ContactSelector()
            .selectContactsForLeadConversion(new List<Object>{new Set<Id>{contacts[0].Id}, 
                											  new Set<Id>{contacts[0].AccountId}},
                						     5, 0, 'Id = :bind0 AND AccountId = :bind1')
            .executeQuery();
		
        List<Lead> leads = (List<Lead>) new LeadSelector()
            .selectLeads()
            .executeQuery();
        
        List<Company_Persons__c> countCompanyPersonsByLeadAndCompanyId = (List<Company_Persons__c>) new CompanyPersonSelector()
            .selectCountCompanyPersonsByLeadAndCompanyId(new List<Object>{new Set<Id>{leads[0].Id},
                														  new Set<Id>{contactsForLeadConversion[0].Company__c}})
            .executeQuery();
        
        System.assert(countCompanyPersonsByLeadAndCompanyId.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(leads[0].Id, countCompanyPersonsByLeadAndCompanyId[0].Lead__c, ASSERT_EQUALS_MESSAGE);
    }
    
    @isTest
    private static void testSelectCountCompanyPersonsByAccountContactsAndCompanyId(){
        List<Contact> contacts = (List<Contact>) new ContactSelector()
            .selectContacts()
            .executeQuery();
        
        List<Contact> contactsForLeadConversion = (List<Contact>) new ContactSelector()
            .selectContactsForLeadConversion(new List<Object>{new Set<Id>{contacts[0].Id}, 
                											  new Set<Id>{contacts[0].AccountId}},
                						     5, 0, 'Id = :bind0 AND AccountId = :bind1')
            .executeQuery();
            
        List<Company_Persons__c> countCompanyPersonsByAccountContactsAndCompanyId = (List<Company_Persons__c>) new CompanyPersonSelector()
            .selectCountCompanyPersonsByAccountContactsAndCompanyId(new List<Object>{new Set<Id>{contactsForLeadConversion[0].Company__c},
                														  			 new Set<Id>{contacts[0].Id}})
            .executeQuery();
        
        System.assert(countCompanyPersonsByAccountContactsAndCompanyId.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(contacts[0].Id, countCompanyPersonsByAccountContactsAndCompanyId[0].Contact__c, ASSERT_EQUALS_MESSAGE);
    }
    
    @isTest
    private static void testSelectCountCompanyPersonsForCompanyMatching(){
		List<Lead> leads = (List<Lead>) new LeadSelector()
            .selectLeads()
            .executeQuery();
        
        List<Company_Persons__c> countCompanyPersonsForCompanyMatching = (List<Company_Persons__c>) new CompanyPersonSelector(true, true)
            .selectCountCompanyPersonsForCompanyMatching(new List<Object>{new Set<Id>{leads[0].Id}})
            .executeQuery();
        
        System.assert(countCompanyPersonsForCompanyMatching.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(leads[0].Id, countCompanyPersonsForCompanyMatching[0].Lead__c, ASSERT_EQUALS_MESSAGE);
    }
    
    
}