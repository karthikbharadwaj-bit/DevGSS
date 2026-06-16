public class Quote_TestDataFactory {
    public static List<Account> generateAccounts(Integer numberOfAccounts) {
        List<Account> accountList = new List<Account>();
        
        for(Integer i = 0; i < numberOfAccounts; i++) {
            accountList.add(new Account(Name = 'Test Account ' + i+1));
        }
        
        return accountList;
    }
    
    public static List<Contact> generateContactsForAccounts(List<Account> accountList, Integer numberOfContactsPerAccount) {
        List<Contact> contactList = new List<Contact>();
        
        for(Account acct : accountList) {
            for(Integer i = 0; i < numberOfContactsPerAccount; i++) {
                contactList.add(new Contact(FirstName = 'Test',
                                            LastName = 'Contact ' + i+1,
                                            AccountId = acct.Id));
            }
        }
        
        return contactList;
    }
    
    public void createUsersWithAyavaE2ECustomerProfile(Integer numOfUsers) {
        List<Id> contactIdSet = new List<Id>();
        List<Account> accountList = generateAccounts(numOfUsers);
        accountList[0].Type = 'partner';
        insert accountList;
        
        List<Contact> contactList = generateContactsForAccounts(accountList, 1);
        insert contactList;
        
        for(Contact con : contactList) {
            contactIdSet.add(con.Id);
        }
        //System.assert(false,contactList);
        Profile communityUserProfile = [SELECT Id FROM Profile WHERE Name = 'Partner Community - Partner Admin'];
        createUsers(numOfUsers, communityUserProfile.Id, contactIdSet);
    }
    
    @Future
    private static void createUsers(Integer numOfUsers, Id profileId, List<Id> contactIdList) {
        List<User> userList = new List<User>();
        //WHERE DeveloperName = 'AvayaMasterPartnerExecutive'
        UserRole userRole_1 = [SELECT Id FROM UserRole  LIMIT 1];
        
        for(Integer i = 0; i < numOfUsers; i++) {
            User u = new User(Alias = 'user' + i, 
                              Email = 'testUser' + i + '@ringcentral.com',
                              EmailEncodingKey = 'UTF-8', 
                              Country = 'United States',
                              LastName = 'Testing' + i, 
                              LanguageLocaleKey = 'en_US', 
                              LocaleSidKey = 'en_US', 
                              ProfileId = profileId, 
                              TimeZoneSidKey = 'America/Los_Angeles',
                              ContactId = contactIdList[i],
                              IsActive = true,
                              //UserRoleId = userRole_1.Id ,
                              UserName = 'testUser' + i + '@ringcentral.com');
            
            if(contactIdList != null) {
                //u.UserName = contactIdList[i];
                u.ContactId = contactIdList[i];
            }
            
            userList.add(u);
        }
        insert userList;
    }
    
    public static List<Opportunity> generateOpportunities(Id accountId,String stageName, Date closeDate ,Integer numberOfOpportunities) {
        List<Opportunity> oppList = new  List<Opportunity>();
        for(integer i=0; i < numberOfOpportunities ; i++){
            Opportunity opp = new Opportunity();
            opp.AccountId = accountId;
            opp.StageName = stageName;
            opp.CloseDate =  closeDate ;
            opp.Amount = 10;
            opp.Name = 'Test Opportunity' + i;
            oppList.add(opp);
        }
        return oppList;
    }
    
    public static Opportunity generateOpportunity(String strOpptyName, Id accountId, Date closeDate, String strStageName, Date subscriptionStartDate, Date subscriptionEndDate) {
        Opportunity objOpportunity = new Opportunity(Name = strOpptyName, AccountId = accountId, CloseDate = closeDate, Amount = 10, StageName = strStageName);
        return objOpportunity;
    }
    
    public static List<Partner_Quote__c> generateQuotes(Integer noOfRecords) {
        List<Partner_Quote__c> QuoteList = new  List<Partner_Quote__c>();
        for(integer i=0; i < noOfRecords ; i++){
            Partner_Quote__c obj = new Partner_Quote__c();
            QuoteList.add(obj);
        }
        
        return QuoteList;
    }
    
    public static List<Partner_Quote_Line__c> generateQuoteLines(Integer noOfRecords, Id quoteId) {
        List<Partner_Quote_Line__c> quoteLineList = new  List<Partner_Quote_Line__c>();
        for(integer i=0; i < noOfRecords ; i++){
            Partner_Quote_Line__c obj = new Partner_Quote_Line__c();
            obj.Partner_Quote__c = quoteId;
            obj.Discount__c = 10.0;
            obj.Quantity__c = 10;
            quoteLineList.add(obj);
        }
        
        return quoteLineList;
    }
    
    public static List<Product_Package__c> generateProductPackage(Integer noOfRecords) {
        List<Product_Package__c> productPackageList = new  List<Product_Package__c>();
        for(integer i=0; i < noOfRecords ; i++){
            Product_Package__c obj = new Product_Package__c();
            obj.Ext_Element_Id__c = 'TESTID' + Integer.valueof((Math.random() * 100)) + 'ID' + i;
            productPackageList.add(obj);
        }
        
        return productPackageList;
    }
    
    public static List<Subscription__c> generateSubscription(Integer noOfRecords, Id accountId, Id oppId, Id productPackageId) {
        List<Subscription__c> subscriptionList = new  List<Subscription__c>();
        for(integer i=0; i < noOfRecords ; i++){
            Subscription__c obj = new Subscription__c();
            if (accountId != null) {
                obj.Account__c = accountId;
            }
            
            if (oppId != null) {
                obj.Opportunity__c = oppId;
            }
            
            if (productPackageId != null) {
                obj.Package__c = productPackageId;
            }
            
            subscriptionList.add(obj);
        }
        
        return subscriptionList;
    }
    
    public static List<Product2> generateProducts(Integer noOfRecords) {
        List<Product2> productList = new  List<Product2>();
        for(integer i=0; i < noOfRecords ; i++){
            Product2 obj = new Product2();
            obj.Name = 'Product ' + i;
            productList.add(obj);
        }
        
        return productList;
    }
    
    public static List<Product_Catalogue__c> generateProductCatalouge(Integer noOfRecords) {
        List<Product_Catalogue__c> productCatalougeList = new  List<Product_Catalogue__c>();
        for(integer i=0; i < noOfRecords ; i++){
            Product_Catalogue__c obj = new Product_Catalogue__c();
            productCatalougeList.add(obj);
        }
        return productCatalougeList;
    }
    
    public static List<Product_Catalogue_Rule__c> generateProductCatalougeRule(Integer noOfRecords) {
        List<Product_Catalogue_Rule__c> productCatalougeRuleList = new  List<Product_Catalogue_Rule__c>();
        for(integer i=0; i < noOfRecords ; i++){
            Product_Catalogue_Rule__c obj = new Product_Catalogue_Rule__c();
            productCatalougeRuleList.add(obj);
        }
        return productCatalougeRuleList;
    }
        
    public static List<Deal_Registration__c> generateDealRegistration(Integer noOfRecords,String accId,String ConId) {
        List<Deal_Registration__c> dealRegistrationList = new  List<Deal_Registration__c>();
        for(integer i=0; i < noOfRecords ; i++){
            Deal_Registration__c obj = new Deal_Registration__c();
            obj.Partner_Account__c = accId;
            obj.Is_Pending_Due_to_Domain__c = true;
            obj.Partner_Contact__c = ConId;
            obj.First_Name__c = 'test';
            obj.Last_Name__c = 'test';
            obj.Business_Title__c = 'ER';
            obj.Company_Name__c = 'test';
            obj.Email_Address__c  =  'test@ringcentral.com';
            obj.Phone_Number__c = '12344';
            obj.Address__c = 'Test';
            obj.City__c = 'cal';
            obj.State__c = 'CALIFORNIA';
            obj.Postal_Code__c = '2344';
            obj.Country__c = 'United States';
            obj.Forecasted_Users__c = 4;
            obj.Brand_Name__c = 'Avaya Cloud Office';
            obj.Tier_Name__c = 'Office';
            obj.Edition__c = 'Essentials';
            obj.Term__c =  'Monthly';
            obj.Number_of_Employees__c = '2-9';
            obj.Number_of_Locations__c = '2-4';
            obj.Industry__c = 'Education';
            obj.Estimated_Close_Date__c = System.today();
            obj.Website__c = 'test.com';
            obj.How_did_you_acquire_this_Lead__c = 'tes';
            obj.Description__c = 'test';
            obj.Existing_Solution_Provider__c = 'On-Prem PBX';
            obj.Existing_Solution_Provider_Others__c = 'test';
            obj.What_s_prompting_change__c = 'Reliability issues:outages or voice quality';  
            obj.Whats_prompting_change__c = 'Reliability issues:outages or voice quality';
            obj.What_s_prompting_change_Other__c = 'test';
            obj.Competitor_s__c = 'On-Prem PBX';
            obj.Competitors_Other__c = 'test';
            obj.Decision_Maker__c = 'Chief Executive Officer (CEO)';
            obj.Decision_Maker_Other__c = 'test';
            obj.Currently_in_a_contract__c = 'Yes';
            obj.Budget_available_for_project__c = 'Yes';
            obj.Status__c = 'Approved';
            obj.Deal_Rejection_Reason__c = 'test';
            obj.Sales_Notes__c  = 'tes';
            dealRegistrationList.add(obj);
        }
        return dealRegistrationList;
    }
    
    public static List<Account_Checklist__c > generateAccountCheckList (Integer noOfRecords, Id accId) {
        List<Account_Checklist__c> accCheckList = new  List<Account_Checklist__c>();
        for(integer i=0; i < noOfRecords ; i++){
            Account_Checklist__c obj = new Account_Checklist__c();
            obj.Type__c = 'Credit Check';
            obj.Status__c = 'In Progress';
            obj.Account__c = accId; 
            accCheckList.add(obj);
        }
        return accCheckList;
    }
    
    public static List<Lead > generateLead (Integer noOfRecords) {
        List<Lead> leadList = new  List<Lead>();
        for(integer i=0; i < noOfRecords ; i++){
            Lead obj = new Lead();
            obj.Company = 'Test';
            obj.LastName = 'Test';
            obj.Status = 'Open' ;
            obj.Email = 'fake@email.com';
            obj.FirstName='TestFirst';
            obj.Partner_Account__c = System.Label.Avaya_Partner_Account_Id;
            leadList.add(obj);
        }
        return leadList;
    }
    
    public static List<Attachment > generateAttachment (Integer noOfRecords, Id parentId) {
        List<Attachment> attachmentList = new  List<Attachment>();
        for(integer i=0; i < noOfRecords ; i++){
            Attachment obj = new Attachment();
            obj.Name = 'Test' + i;
			obj.Description = 'This is description';
            obj.body = Blob.valueOf('TEST');
            obj.parentId = parentId;
            attachmentList.add(obj);
        }
        return attachmentList;
    }
    
    public static List<Partner_Contract__c> generatePartnerContract(Integer noOfRecords, String quoteId) {
        List<Partner_Contract__c> listOfPartnerQuote = new List<Partner_Contract__c>();
        for(integer i=0; i < noOfRecords ; i++){
            Partner_Contract__c objContract = new Partner_Contract__c();
            objContract.Partner_Quote__c = quoteId;
            objContract.Status__c = 'Approved';
            listOfPartnerQuote.add(objContract);
        }
       return listOfPartnerQuote;
    }
    
    public static List<Partner_Contract_Service__c> getPartnerContractService(Integer noOfRecords, String partnerContractId) {
        Partner_Contract_Detail__c obj = new Partner_Contract_Detail__c();
        obj.Partner_Contract__c = partnerContractId;
        insert obj;
        
        List<Partner_Contract_Service__c> listOfPartnercontractService = new List<Partner_Contract_Service__c>();
        for(integer i=0; i < noOfRecords ; i++){
            Partner_Contract_Service__c objContract = new Partner_Contract_Service__c();
            objContract.Partner_Contract_Detail__c = obj.Id;
            //objContract.Status__c = 'Approved';
            listOfPartnercontractService.add(objContract);
        }
       return listOfPartnercontractService;
    }
    
    public static List<Account_Change_Request__c> generateAccountChangeRequest(Integer noOfRecords, String accId) {
        List<Account_Change_Request__c> listOfAccChangeRequest = new List<Account_Change_Request__c>();
        for(integer i=0; i < noOfRecords ; i++){
            Account_Change_Request__c objAccChangeRequest = new Account_Change_Request__c();
            objAccChangeRequest.Account__c = accId;
           	listOfAccChangeRequest.add(objAccChangeRequest);
        }
       return listOfAccChangeRequest;
    }
    
     public static List<Product_Tier_Price__c> generateProductTierPrice(Integer noOfRecords, String productCatalougeId) {
        List<Product_Tier_Price__c> listOfProductTire = new List<Product_Tier_Price__c>();
        for(integer i=0; i < noOfRecords ; i++){
            Product_Tier_Price__c obj = new Product_Tier_Price__c();
            obj.Product_Catalogue__c = productCatalougeId;
           	listOfProductTire.add(obj);
        }
       return listOfProductTire;
    }
}