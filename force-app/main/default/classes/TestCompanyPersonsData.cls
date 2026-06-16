@isTest
public class TestCompanyPersonsData {

    private static List<Company_Persons__c> getAllCompanyPersons(){
        return [SELECT Id, Name
                FROM Company_Persons__c];
    }
	
    @isTest
    private static void testDeleteCompanyPersonsByLeadIdsShouldDeleteCompanyPersonsSuccessfully(){

        Lead testLead = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Lead.email => 'fake@email.com',
                    Lead.LastName => 'fakeLastName',
                    Lead.Company => 'fakeCompany'
                }
            )
            .create()
            .getRecord();
        Account_Hierarchy__c testAccountHierarchy = (Account_Hierarchy__c) new SObjectBuilder(Account_Hierarchy__c.SObjectType)
            .create()
            .getRecord();    
        Company_Persons__c testCompanyPerson = (Company_Persons__c) new SObjectBuilder(Company_Persons__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Company_Persons__c.Lead__c => testLead.Id,
                    Company_Persons__c.Company__c => testAccountHierarchy.Id
                }
            )
            .create()
            .getRecord();  

        CompanyPersonsData.ICompanyPersonsData companyPersonsData = new CompanyPersonsData();
        Set<Id> leadIds = new Set<Id>{testLead.Id};
        test.startTest();
            companyPersonsData.deleteCompanyPersonsByLeadIds(leadIds);
        test.stopTest();

        System.assertEquals(0, getAllCompanyPersons().size(), 'Company_Person should have been deleted successfully');
    }

    @isTest
    private static void testDeleteCompanyPersonsByContactIdsShouldDeleteCompanyPersonsSuccessfully(){

        Lead testLead = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Lead.email => 'fake@email.com',
                    Lead.LastName => 'fakeLastName',
                    Lead.Company => 'fakeCompany'
                }
            )
            .create()
            .getRecord();

        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc'
                }
            )
            .create()
            .getRecord();
        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => testAccount.Id,
                    Contact.Email => 'something@mostcommon.fake',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();
        Account_Hierarchy__c testAccountHierarchy = (Account_Hierarchy__c) new SObjectBuilder(Account_Hierarchy__c.SObjectType)
            .create()
            .getRecord();  

        Company_Persons__c testCompanyPerson = (Company_Persons__c) new SObjectBuilder(Company_Persons__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Company_Persons__c.Lead__c => testLead.Id,
                    Company_Persons__c.Company__c => testAccountHierarchy.Id,
                    Company_Persons__c.Contact__c => testContact.Id
                }
            )
            .create()
            .getRecord(); 

        CompanyPersonsData.ICompanyPersonsData companyPersonsData = new CompanyPersonsData();
        Set<Id> contactIds = new Set<Id>{testContact.Id};
        test.startTest();
            companyPersonsData.deleteCompanyPersonsByContactIds(contactIds);
        test.stopTest();

        System.assertEquals(0, getAllCompanyPersons().size(), 'Company_Person should have been deleted successfully');
    }

    @isTest
    private static void testCreateCompanyPersonsShouldCreateCompanyPersonsSuccessfully(){

        Lead testLead = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Lead.email => 'fake@email.com',
                    Lead.LastName => 'fakeLastName',
                    Lead.Company => 'fakeCompany'
                }
            )
            .create()
            .getRecord();

        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc'
                }
            )
            .create()
            .getRecord();
        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => testAccount.Id,
                    Contact.Email => 'something@mostcommon.fake',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();
        Account_Hierarchy__c testAccountHierarchy = (Account_Hierarchy__c) new SObjectBuilder(Account_Hierarchy__c.SObjectType)
            .create()
            .getRecord();  

        Company_Persons__c testCompanyPerson = (Company_Persons__c) new SObjectBuilder(Company_Persons__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Company_Persons__c.Lead__c => testLead.Id,
                    Company_Persons__c.Company__c => testAccountHierarchy.Id,
                    Company_Persons__c.Contact__c => testContact.Id
                }
            )
            .build()
            .getRecord(); 

        List<Company_Persons__c> companyPersonsToInsert = new List<Company_Persons__c>{testCompanyPerson};

        CompanyPersonsData.ICompanyPersonsData companyPersonsData = new CompanyPersonsData();

        test.startTest();
            companyPersonsData.createCompanyPersons(companyPersonsToInsert);
        test.stopTest();

        System.assertEquals(1, getAllCompanyPersons().size(), 'Company Person should have been inserted successfully');
    }

    @isTest
    private static void testMocksDeleteCompanyPersonsByLeadIdsShouldReturnExpectedResults() {
        Company_Persons__c companyPersonToReturn = (Company_Persons__c) new SObjectBuilder(Company_Persons__c.SObjectType)
            .build()
            .getRecord(); 

        CompanyPersonsData.CompanyPersonsDataMock companyPersonsDataMock = new CompanyPersonsData.CompanyPersonsDataMock();
        companyPersonsDataMock.companyPersonsToReturn = new List<Company_Persons__c>{companyPersonToReturn};
        
        test.startTest();
            companyPersonsDataMock.deleteCompanyPersonsByLeadIds(null);
        test.stopTest();

        System.assertEquals(0, companyPersonsDataMock.companyPersonsToReturn.size(), 
            'All company persons should be deleted');
    }

    @isTest
    private static void testMocksDeleteCompanyPersonsByContactIdsShouldReturnExpectedResults() {
        Company_Persons__c companyPersonToReturn = (Company_Persons__c) new SObjectBuilder(Company_Persons__c.SObjectType)
            .build()
            .getRecord();

        CompanyPersonsData.CompanyPersonsDataMock companyPersonsDataMock = new CompanyPersonsData.CompanyPersonsDataMock();
        companyPersonsDataMock.companyPersonsToReturn = new List<Company_Persons__c>{companyPersonToReturn};
        
        test.startTest();
            companyPersonsDataMock.deleteCompanyPersonsByContactIds(null);
        test.stopTest();

        System.assertEquals(0, companyPersonsDataMock.companyPersonsToReturn.size(), 
            'Company person should be deleted successfully');
    }

    @isTest
    private static void testMocksCreateCompanyPersonsByContactIdsShouldReturnExpectedResults() {
        Company_Persons__c companyPersonToReturn = (Company_Persons__c) new SObjectBuilder(Company_Persons__c.SObjectType)
            .build()
            .getRecord();
        List<Company_Persons__c> companyPersonsToReturn = new List<Company_Persons__c>{companyPersonToReturn};

        CompanyPersonsData.CompanyPersonsDataMock companyPersonsDataMock = new CompanyPersonsData.CompanyPersonsDataMock();
        
                
        test.startTest();
            companyPersonsDataMock.createCompanyPersons(companyPersonsToReturn);
        test.stopTest();

        System.assertEquals(1, companyPersonsDataMock.companyPersonsToReturn.size(), 
            'Company person should be created successfully');
    }
}