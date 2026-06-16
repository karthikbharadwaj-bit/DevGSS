@isTest
private class RcDealHealper_Test {
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void myUnitTest() {
        // TO DO: implement unit test
        String email;
        String phone;
        RcDealHealper helperObj = new RcDealHealper();
        RcDealHealper.searchResultClass searchResult;
        
        List<Segment_Data__c> lstSegment = new List<Segment_Data__c>();
        lstSegment.add(new Segment_Data__c(Attribute_1__c = 'ringcentral.com', Type__c = 'Franchise'));
        insert lstSegment;
        
        List<Lead> lstLeads = new List<Lead>();
        lstLeads.add(new Lead(LastName = 'LName', Email = 'lead1@ringcentral.com', Company= 'Company1', Phone = '1234567890'));
        lstLeads.add(new Lead(LastName = 'LName', Email = 'lead2@simplion.com', Company= 'Company2', Phone = '1234567891'));
        insert lstLeads;
        
        List<Contact> lstContacts = new List<Contact>();
        lstContacts.add(new Contact(LastName = 'LName', Email = 'Contact1@ringcentral.com', Phone = '1234567892'));
        lstContacts.add(new Contact(LastName = 'LName', Email = 'Contact2@simplion.com', Phone = '1234567893'));
        insert lstContacts;
        
        email = 'lead@ringcentral.com';
        phone = '091000010101';
        
  		searchResult = helperObj.LeadContactSearch(email, phone);
  		
  		email = 'lead@simplion.com';
        phone = '191000010101';
        searchResult = helperObj.LeadContactSearch(email, phone);
        
        map<String,String> prOwnerMap = new map<String,String>();
        prOwnerMap.put(lstLeads.get(0).Email + lstLeads.get(0).Phone, lstLeads.get(0).OwnerId);
        prOwnerMap.put(lstLeads.get(1).Email + lstLeads.get(1).Phone, lstLeads.get(1).OwnerId);
        RcDealHealper.LeadContactSearch(lstLeads, prOwnerMap,new Map<String, Boolean>{'null_LName'=>false},new Set<string>());
    }

    @isTest
    static void testGetBTBrand() {
        // Test when not running test and all brand fields are blank
        Test.startTest();
        // Mock the Brand_List__c SObject
        Brand_List__c brand = new Brand_List__c();
        brand.Brand_Id__c = '';
        brand.Brand_Name__c = '';
        brand.Brand_Name_External__c = '';
        brand.Name = 'BT Brand';
        insert brand;

        // Mock the getAll() method
        Map<String, Brand_List__c> brandMap = new Map<String, Brand_List__c>();
        brandMap.put('BT_Brand', brand);
        String result = RcDealHealper.getBTBrand();
        System.assertEquals('BT Business', result);
        Test.stopTest();
    }

    @isTest
    static void testLeadContactSearch() {
        // Creating test data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Lead testLead1 = new Lead(LastName = 'Test1', FirstName = 'Test1', Company = 'Test Company', Email = 'test1@example.com', Phone = '1234567890', Bypass_PR__c = false, LeadSource = 'Web');
        Lead testLead2 = new Lead(LastName = 'Test2', FirstName = 'Test2', Company = 'Test Company', Email = 'test2@example.com', Phone = '0987654321', Bypass_PR__c = false, LeadSource = 'Web');
        insert new List<Lead>{testLead1, testLead2};

        Contact testContact = new Contact(LastName = 'Test', AccountId = testAccount.Id, Email = 'test1@example.com', Phone = '1234567890');
        insert testContact;

        //Input parameters
        List<Lead> newLeadList = [SELECT Id, LastName, FirstName, Company, Email, Phone, Bypass_PR__c, LeadSource, RecordTypeName__c FROM Lead];
        Map<String, String> prOwnerMap = new Map<String, String>();
        Map<String, Boolean> resultMap = new Map<String, Boolean>();
        resultMap.put('Test1_Test1', false);
        resultMap.put('Test2_Test2', false);
        Set<String> excludedPRUserIdSet = new Set<String>();

        // Call the method
        Map<String, RcDealHealper.searchResultClass> result = RcDealHealper.LeadContactSearch(newLeadList, prOwnerMap, resultMap, excludedPRUserIdSet);
        System.assertNotEquals(null, result);
        System.assert(result.size() > 0, 'Result map should not be empty');
    }
}