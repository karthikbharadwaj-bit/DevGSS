/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class Test_ContactTriggerHelper {

	private static final Integer countOfObjects = 4;

	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void myUnitTest() {
    	List<Contact> lstContacts = new List<Contact>();
    	
    	Folder fd = [SELECT Id FROM Folder WHERE Name='LeadSourceMap' LIMIT 1];
        Blob blbObj = Blob.valueOf('NumberOfEmployees__c,#,50-100,#,50-249,#,#EOL#');
        Document doc = new Document(Name='No_Employee_Mapping', Body=blbObj ,folderId=fd.Id,isPublic=true,type='csv' );
        insert doc;
        
        List<Contact_Field_Map__c> lstContactFieldMap = new List<Contact_Field_Map__c>();
        lstContactFieldMap.add(new Contact_Field_Map__c(Name ='1', Api_Name__c = 'numberofemployees__c'));
        insert lstContactFieldMap;
    	
    	lstContacts.add(new Contact(FirstName = 'A', LastName = 'B', Email = 'ab@test.com', NumberOfEmployees__c = '2'));
    	lstContacts.add(new Contact(FirstName = 'C', LastName = 'D', Email = 'cd@test.com', NumberOfEmployees__c = '50-100'));
    	lstContacts.add(new Contact(FirstName = 'E', LastName = 'F', Email = 'ef@test.com', NumberOfEmployees__c = '500 - 1'));
    	insert lstContacts;    	
        // TO DO: implement unit test    
    }
    
	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
      @isTest
    static void updateContactOnAccount(){
        	
           List<Account> accountListt = new List<Account>();       	
           Account acctObjj = new Account();
	       acctObjj.Name = 'Test12';
		   acctObjj.Number_of_DL_s__c = 2;
		   acctObjj.RC_Service_name__c = 'office123';
	       acctObjj.RC_Account_Status__c = 'Paid';
	       accountListt.add(acctObjj);
	       //insert acctObjj;
          
           Account acctObjj1 = new Account();
	       acctObjj1.Name = 'Test122';
		   acctObjj1.Number_of_DL_s__c = 3;
		   acctObjj1.RC_Service_name__c = 'office1233';
	       acctObjj1.RC_Account_Status__c = 'Canceled';
	       accountListt.add(acctObjj1);
	       insert accountListt;
	       
	       List<contact> lstconn = new list<contact>();
	       Contact contactObj = new Contact();
	       contactObj.LastName= 'TEst1';
	       contactObj.AccountId =  acctObjj.id;
	       contactObj.isCustomer__c=True;
	       contactObj.Contact_Status__c='Closed Won';
	       contactObj.Contact_Funnel_Type__c='Customer';
	       contactObj.People_Segment__c='Customer';
	       lstconn.add(contactObj);
	       //insert contactObj;
	       
	       Contact contactObjj1 = new Contact();
	       contactObjj1.LastName= 'TEst2';	       
	       contactObjj1.AccountId =  acctObjj1.id;
	       contactObjj1.isCustomer__c=False;
	       contactObjj1.Contact_Status__c='Winback';
	       contactObjj1.Contact_Funnel_Type__c='Former Customer';
	       contactObjj1.People_Segment__c='Canceled';
	       lstconn.add(contactObjj1);
	      // insert contactObjj1;
	       
	       ContactTriggerHelper.updateContactOnAccount(lstconn);
	       //List<Contact> contList = new List<Contact>(); 	       
	      /* contList = [select id,LastName,AccountId, isCustomer__c,Contact_Status__c ,RCService_ContactStatus__c,
	                                  People_Segment_c__c from Contact where Id =: acctObjj.Id];*/
	                              
	      // insert contList; 
          
      }

	private static List<Contact> createContacts(Integer numOfContacts) {
		List<Contact> contacts = new List<Contact>();
		for (Integer i = 0; i < numOfContacts; i++) {
			contacts.add(new Contact(LastName = 'TestContact ' + i));
		}
		insert contacts;
		return contacts;
	}

	private static List<Lead> createLeads(Integer numOfLeads) {
		List<Lead> leads = new List<Lead>();
		for (Integer i = 0; i < numOfLeads; i++) {
			leads.add(new Lead(LastName = 'TestLead ' + i,
								Email = 'fake' + i + '@email.com',
								Company = 'Test Company ' + i));
		}
		insert leads;
		return leads;
	}

	/*private static List<Account_Hierarchy__c> createCompanies(Integer numOfCompanies) {
		List<Account_Hierarchy__c> companies = new List<Account_Hierarchy__c>();
		for (Integer i = 0; i < numOfCompanies; i++) {
			companies.add(new Account_Hierarchy__c(Name = 'Test Company ' + i));
		}
		insert companies;
		return companies;
	}*/

	/*private static List<Company_Persons__c> createCompanyPersons(Integer numOfCompanyPersons,
																List<Account_Hierarchy__c> companies,
																List<Lead> leads,
																List<Contact> contacts) {
		List<Company_Persons__c> companyPersons = new List<Company_Persons__c>();
		for (Account_Hierarchy__c company : companies) {
			for (Integer i = 0; i < numOfCompanyPersons; i++) {
				companyPersons.add(new Company_Persons__c(Company__c = company.Id));
				if(i < leads.size()) {
					companyPersons.get(i).Lead__c = leads.get(i).Id;
				}
				if(i < contacts.size()) {
					companyPersons.get(i).Contact__c = contacts.get(i).Id;
				}
			}
		}
		insert companyPersons;
		return companyPersons;
	}*/

	/*@isTest
	private static void removeUnnecessaryCompanyPersons() {
		List<Contact> contacts = createContacts(countOfObjects + (countOfObjects/2));
		List<Lead> leads = createLeads(countOfObjects - (countOfObjects/2));
		List<Account_Hierarchy__c> companies = createCompanies(countOfObjects);
		List<Company_Persons__c> companyPersons = createCompanyPersons(countOfObjects, companies, leads, contacts);

		delete leads;
		System.assertEquals([SELECT Id FROM Company_Persons__c].size(),
							companyPersons.size(),
							'Company Persons was deleted incorrectly after removing related Leads.');

		delete contacts;
		System.assertEquals([SELECT Id FROM Company_Persons__c].size(),
							companyPersons.size() - countOfObjects,
							'Not all of unnecessary Company Persons was deleted after removing related Contacts.');
	}*/

    @isTest
    static void testValidateEmployeeRangeForNumericValues() {
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test',
                    Contact.LastName => 'Employee',
                    Contact.Email => 'test@example.com',
                    Contact.NumberOfEmployees__c => '200'
                }
            )
            .build()
            .getRecord();
        
        Test.startTest();
            ContactTriggerHelper.validateEmployeeRangeForNumericValues(new List<Contact>{con});
        Test.stopTest();
        
        System.assertEquals('50-249', con.NumberOfEmployees__c, 'NumberOfEmployees__c should be converted to the correct range');
    }
    
    @isTest
    static void testIsNumeric() {
        Test.startTest();
            Boolean isNumericTrue = ContactTriggerHelper.isNumeric('123');
            Boolean isNumericFalse = ContactTriggerHelper.isNumeric('abc');
            Boolean isNumericMixed = ContactTriggerHelper.isNumeric('123abc');
        Test.stopTest();
        
        System.assertEquals(true, isNumericTrue, 'isNumeric should return true for numeric values');
        System.assertEquals(false, isNumericFalse, 'isNumeric should return false for non-numeric values');
        System.assertEquals(false, isNumericMixed, 'isNumeric should return false for mixed values');
    }
    
    @isTest
    static void testUpdateLeadspaceAccount() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'Leadspace Test Account'
                }
            )
            .create()
            .getRecord();
            
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Leadspace',
                    Contact.LastName => 'Test',
                    Contact.Email => 'leadspace@example.com',
                    Contact.AccountId => acc.Id
                }
            )
            .create()
            .getRecord();
            
        Contact updatedCon = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Leadspace',
                    Contact.LastName => 'Test',
                    Contact.Email => 'newleadspace@example.com',
                    Contact.AccountId => acc.Id,
                    Contact.Id => con.Id
                }
            )
            .build()
            .getRecord();
            
        Test.startTest();
            Map<Id, Contact> oldMap = new Map<Id, Contact>{con.Id => con};
            ContactTriggerHelper.updateLeadspaceAccount(new List<Contact>{updatedCon}, oldMap);
        Test.stopTest();
        
        Account updatedAcc = [SELECT RunContactMostFrequentEmail__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(true, updatedAcc.RunContactMostFrequentEmail__c, 'RunContactMostFrequentEmail__c should be set to true');
    }
    
    @isTest
    static void testPopulateIndexEmailAndPhone() {
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Index',
                    Contact.LastName => 'Test',
                    Contact.Email => 'index@example.com',
                    Contact.Phone => '1234567890'
                }
            )
            .build()
            .getRecord();
            
        Test.startTest();
            ContactTriggerHelper.populateIndexEmailAndPhone(new List<Contact>{con});
        Test.stopTest();
        
        System.assertEquals('index@example.com', con.indexedEmail__c, 'indexedEmail__c should match Email');
        System.assertEquals('1234567890', con.indexedPhone__c, 'indexedPhone__c should match Phone');
    }
    
    @isTest
    static void testPopulateIndexPhoneEmailAndNOfEmployees() {
        Contact oldCon = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Old',
                    Contact.LastName => 'Contact',
                    Contact.Email => 'old@example.com',
                    Contact.Phone => '1234567890',
                    Contact.NumberOfEmployees__c => '1-49'
                }
            )
            .build()
            .getRecord();
            
        Contact newCon = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.Id => oldCon.Id,
                    Contact.FirstName => 'Old',
                    Contact.LastName => 'Contact',
                    Contact.Email => 'new@example.com',
                    Contact.Phone => '9876543210',
                    Contact.NumberOfEmployees__c => '200'
                }
            )
            .build()
            .getRecord();
            
        Map<Id, Contact> oldMap = new Map<Id, Contact>{oldCon.Id => oldCon};
        
        Test.startTest();
            ContactTriggerHelper.populateIndexPhoneEmailAndNOfEmployees(new List<Contact>{newCon}, oldMap);
        Test.stopTest();
        
        System.assertEquals('new@example.com', newCon.indexedEmail__c, 'indexedEmail__c should be updated to match new Email');
        System.assertEquals('9876543210', newCon.indexedPhone__c, 'indexedPhone__c should be updated to match new Phone');
    }
    
    @isTest
    static void testDowngradeInactiveContactForInsert() {
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Inactive',
                    Contact.LastName => 'Test',
                    Contact.Email => 'inactive@example.com',
                    Contact.RCService_ContactStatus__c => 'Inactive'
                }
            )
            .build()
            .getRecord();
            
        Test.startTest();
            ContactTriggerHelper.downgradeInactiveContactForInsert(new List<Contact>{con});
        Test.stopTest();
        
        System.assertEquals('0. Downgraded', con.Contact_Status__c, 'Contact_Status__c should be set to 0. Downgraded');
    }
    
    @isTest
    static void testValidateContactStatus() {
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Status',
                    Contact.LastName => 'Test',
                    Contact.Email => 'status@example.com',
                    Contact.Contact_Status__c => '1. New'
                }
            )
            .create()
            .getRecord();
            
        Map<Id, Contact> oldMap = new Map<Id, Contact>();
        Contact oldCon = [SELECT Id, Contact_Status__c FROM Contact WHERE Id = :con.Id];
        oldCon.Contact_Status__c = '2. Contacted';
        oldMap.put(con.Id, oldCon);
        
        con.Contact_Status__c = '1. New';
        
        Test.startTest();
            ContactTriggerHelper.validateContactStatus(new List<Contact>{con}, oldMap);
        Test.stopTest();
        
        System.assertEquals(null, con.Most_Recent_MQL_Date__c);
    }
}