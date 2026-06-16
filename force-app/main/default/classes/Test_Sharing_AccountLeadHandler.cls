@isTest
private class Test_Sharing_AccountLeadHandler {
    
    @isTest
    private static void testHandleAccountShare() {
        //setupData();
        PartnerRecordsUtil util = new PartnerRecordsUtil();
        List<Account> accList = [SELECT Id, Name, Avaya_Partnership_Account__c FROM Account];
        //including PCM        
        List<Contact> conList = [SELECT Id FROM Contact];        
        accList.get(0).Partner_Channel_Manager__c = conList.get(0).Id; 
         User_Account_Mapping__c userObj=new User_Account_Mapping__c();
        userObj.Name='Test User';
        userObj.Partner_Account__c=accList[0].Id;
        userObj.Partner_Contact__c=conList[0].Id;
        userObj.Partner_User__c=PartnerRecordsUtil.runAsAvayaMasterRole.Id;
         system.runAs(PartnerRecordsUtil.runAsSysAdmin){
            insert userObj;
             
        }
        
        Test.startTest();        
        Sharing_AccountLeadHandler.handleAccountShare(accList);
        Sharing_AccountLeadHandler.getContactAccount(conList.get(0).Id);
        Test.stopTest();
        
        List<AccountShare> result = [SELECT Id, AccountAccessLevel, AccountId, UserOrGroupId, OpportunityAccessLevel FROM AccountShare];
        System.assertNotEquals(null, result, 'Share record must be exist');
    }
    
    @isTest
    private static void testHandleAccountShareFuture() {
        setupData();
        
        Map<Id, Account> accMap = new Map<Id, Account>([SELECT Id, Name FROM Account]);
        Test.startTest();
        Sharing_AccountLeadHandler.handleAccountShareFuture(accMap.keySet());
        Test.stopTest();
        
        List<AccountShare> result = [SELECT Id, AccountAccessLevel, AccountId, UserOrGroupId, OpportunityAccessLevel FROM AccountShare];
        System.assertNotEquals(null, result, 'Share record must be exist');
    }
    
    @isTest
    private static void testHandleAccountSharingOnOwnerChange() {
        setupData();
        Map<Id, Account> oldMapAccount = new Map<Id, Account>([SELECT Id, OwnerId, Name, Avaya_Partnership_Account__c,Partner_Channel_Manager__c,Type FROM Account]);
        Map<Id, User> userMap = new Map<Id, User>([SELECT Id, firstName, lastName FROM User LIMIT 1]);
        Map<Id, Contact> contactMap = new Map<Id, Contact>([SELECT Id FROM Contact LIMIT 1]);//PCM
        Map<Id, Account> newMapAccount = new Map<Id, Account>();
        for (Account old : oldMapAccount.values()) {
            Account newAcc = old.clone(true, true);
            newAcc.OwnerId = new List<Id>(userMap.keySet()).get(0);
            if(old.Type=='Partner'){
                newAcc.Partner_Channel_Manager__c = new List<Id>(contactMap.keySet()).get(0);//PCM
            }
            newMapAccount.put(newAcc.Id, newAcc);
        }
        Test.startTest();
        Sharing_AccountLeadHandler.handleAccountSharingOnOwnerChange(newMapAccount, oldMapAccount);
        Test.stopTest();
        
        List<AccountShare> result = [SELECT Id, AccountAccessLevel, AccountId, UserOrGroupId, OpportunityAccessLevel FROM AccountShare];
        System.assertNotEquals(null, result, 'Share record must be exist');
    }
    
    private static void setupData() {
        String AVAYA_PARTNER_ACCOUNT_ID = System.Label.Avaya_Partner_Account_Id;
        PartnerRecordsUtil util = new PartnerRecordsUtil();
        system.runAs(PartnerRecordsUtil.runAsSysAdmin){
            List<Account> accList = [SELECT Id FROM Account Limit 1];        
            List<Contact> conList = [SELECT Id FROM Contact];  
        }
    }
    private static void setupData1() {
        String AVAYA_PARTNER_ACCOUNT_ID = System.Label.Avaya_Partner_Account_Id;
        PartnerRecordsUtil util = new PartnerRecordsUtil();
        system.runAs(PartnerRecordsUtil.runAsSysAdmin){
            List<Account> accList = [SELECT Id FROM Account Limit 1];        
            List<Contact> conList = [SELECT Id FROM Contact];  
            PortalAccessTestUtil portalAccessUtil = new PortalAccessTestUtil(accList.get(0),conList);
            
            accList.get(0).BillingCountry = 'United States';
            update accList;
        }
    }
    public static Deal_Registration__c createAvayaDeal(){
        Deal_Registration__c dealRegObj = new Deal_Registration__c();
        dealRegObj.Partner_Contact__c = PartnerRecordsUtil.partnerContact.Id;
        dealRegObj.Partner_Account__c = PartnerRecordsUtil.partnerAccount.Id;
        dealRegObj.First_Name__c = 'Test';
        dealRegObj.Last_Name__c = 'DealReg';
        dealRegObj.Business_Title__c = 'Consultant';
        dealRegObj.Company_Name__c = 'Test Company';
        dealRegObj.Email_Address__c = 'testdealreg@mail.com';
        dealRegObj.Phone_Number__c = '123456';
        dealRegObj.Address__c = 'ABC street';
        dealRegObj.City__c = 'abc city';
        dealRegObj.State__c = 'ALASKA';
        dealRegObj.Postal_Code__c = '123456';
        dealRegObj.Country__c = 'United States';
        dealRegObj.Forecasted_Users__c = 5;
        dealRegObj.Brand_Name__c = 'Avaya Cloud Office';
        dealRegObj.Tier_Name__c = 'Office';
        dealRegObj.Edition__c = 'Standard';
        dealRegObj.Term__c = 'Annual';
        dealRegObj.Number_of_Employees__c = '50-249';
        dealRegObj.Number_of_Locations__c = '5-9';
        dealRegObj.Industry__c = 'Banking';
        dealRegObj.Estimated_Close_Date__c = System.today()+90;
        dealRegObj.Website__c = 'www.testsite.com';
        dealRegObj.How_did_you_acquire_this_Lead__c = 'Testing Acquisition';
        dealRegObj.Description__c = 'Test Deal Reg description';
        dealRegObj.Budget_available_for_project__c = 'Yes'; 
        dealRegObj.Existing_Solution_Provider__c = 'Avaya';
        dealRegObj.Competitor_s__c = 'Avaya';
        dealRegObj.What_s_prompting_change__c = 'Other';
        dealRegObj.Whats_prompting_change__c = 'Other';
        dealRegObj.Decision_Maker__c = 'Other';
        dealRegObj.Currently_in_a_contract__c = 'Yes'; 
        dealRegObj.Sales_Notes__c = 'Test Sales notes';
        dealRegObj.Avaya_Partnership_Deal__c = true;
        dealRegObj.Status__c = 'Approved';
        dealRegObj.Avaya_Cloud_Specialist__c = PartnerRecordsUtil.partnerContact.Id;
        dealRegObj.RC_Overlay__c = 'test';
        system.runAs(PartnerRecordsUtil.runAsSysAdmin){
            dealRegObj.OwnerId = PartnerRecordsUtil.runAsAvayaAdmin.id;
            Database.insert(dealRegObj);  
            System.debug('** Deal '+dealRegObj);
        }        
        return dealRegObj;
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void testHandleCustomerShareFuture() {
        setupData();
        
        Map<Id, Account> accMap = new Map<Id, Account>([SELECT Id, Name FROM Account]);
        Map<Id, Lead> leadMap = new Map<Id, Lead>([SELECT Id, Name FROM Lead]);
        Test.startTest();
        Sharing_AccountLeadHandler.handleDeltaShareFuture(accMap.keySet(),'Account');
        Sharing_AccountLeadHandler.handleDeltaShareFuture(leadMap.keySet(),'Lead');
        Test.stopTest();
        
        List<AccountShare> result = [SELECT Id, AccountAccessLevel, AccountId, UserOrGroupId, OpportunityAccessLevel FROM AccountShare];
        List<LeadShare> result1 = [SELECT Id, LeadAccessLevel, LeadId FROM LeadShare];
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void testMethod2() {
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
        TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
        TriggerHandler.BY_PASS_CONTACT_ON_INSERT();
        TriggerHandler.BY_PASS_CONTACT_ON_UPDATE();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE();
        TriggerHandler.BY_PASS_LEAD_UPDATE_ON_INSERT();
        PartnerRecordsUtil util = new PartnerRecordsUtil();
        Deal_Registration__c dealObj = new Deal_Registration__c();
        Test.startTest();
        system.runAs(PartnerRecordsUtil.runAsSysAdmin){
        dealObj = createAvayaDeal();
    }
    Lead leadObj = PartnerRecordsUtil.createAvayaLead(dealObj);
        system.runAs(PartnerRecordsUtil.runAsSysAdmin){            
        Database.LeadConvert lc = new database.LeadConvert();
        lc.setConvertedStatus('2. Contacted');
        lc.setLeadId(leadObj.Id);
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        User_Account_Mapping__c uam = new User_Account_Mapping__c();
        uam.Partner_Account__c=leadObj.Partner_Account__c;
        uam.Partner_Contact__c=leadObj.Partner_Contact__c;
        uam.Partner_User__c=PartnerRecordsUtil.runAsAvayaMain.Id;
        insert uam;
        AccessControlSettings__c acs = new AccessControlSettings__c();
        acs.Brand__c = 'Avaya Cloud Office';
        acs.BusinessIdentity__c = 'Avaya Cloud Office';
        acs.CurrencyIsoCode = 'USD';
        acs.isActive__c = true;
        acs.isParent__c = true;
        acs.Name = 'Avaya Cloud Office';
        acs.Public_Group_Name__c = 'Avaya_Users';
        insert acs;
        Group newgroup = new Group();
        newgroup.name='Test Group';
        insert newgroup;
        AccountShare accShare= new AccountShare();
        accShare.UserOrGroupId=newgroup.id;
        accShare.AccountId=lcr.getAccountId();
        accShare.RowCause='Manual';
        accShare.AccountAccessLevel='Read';
        accShare.OpportunityAccessLevel='Read';
        accShare.ContactAccessLevel='Read';
        accShare.CaseAccessLevel='Read';
        insert accShare;
        Sharing_AccountLeadHandler.sharingAOCOnLeadConvertService(leadObj.Id);
        }
        Test.stopTest();
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void testmethod3(){
        Account atosaccount = new Account();
        atosaccount.name='parentpartneraccount';
        atosaccount.RC_Brand__c='Unify Office';
        atosaccount.Avaya_Partnership_Account__c = true;
        insert atosaccount;
        Account parentpartneraccount = new Account();
        parentpartneraccount.name='parentpartneraccount';
        parentpartneraccount.RC_Brand__c='Unify Office';
        parentpartneraccount.Avaya_Partnership_Account__c = true;
        parentpartneraccount.Partner_Account__c = atosaccount.Id;
        insert parentpartneraccount;
        Sharing_AccountLeadHandler.handleAccountShare(new Set<Id> {parentpartneraccount.Id});
        Account partneraccount = new Account();
        partneraccount.name='Partner Account';
        partneraccount.RC_Brand__c='Unify Office';
        partneraccount.Avaya_Partnership_Account__c = true;
        partneraccount.Parent_Partner_Account__c=parentpartneraccount.id;
        insert partneraccount;
        Lead normallead = new Lead();
        normallead.LastName ='Test Lead';
        normallead.Status = '1. New';
        normallead.Lead_Brand_Name__c ='Unify Office';
        normallead.Avaya_Partnership_Lead__c = false;
        normallead.Industry = 'Banking';
        normallead.LeadSource='Service Provider';
        normallead.Phone='9876543210'; 
        normallead.Email='test@test.com';
        normallead.Company='test company';
        normallead.NumberOfEmployees__c='20-99';
        normallead.Forecasted_RingCentral_Video_Users__c =23;
        normallead.Partner_Account__c=partneraccount.Id;
        insert normallead;
        Lead leadobj = new Lead();
         leadobj.LastName ='Test Lead 2';
        leadobj.Status = '1. New';
        leadobj.Lead_Brand_Name__c ='Unify Office';
        leadobj.Avaya_Partnership_Lead__c = true;
        leadobj.Industry = 'Banking';
        leadobj.LeadSource='Service Provider';
        leadobj.Phone='9876543210'; 
        leadobj.Email='test@test2.com';
        leadobj.Company='test company 2';
        leadobj.NumberOfEmployees__c='20-99';
        leadobj.Partner_Account__c=partneraccount.Id;
        insert leadobj;
        Sharing_AccountLeadHandler.handleLeadShare(new Set<Id> {normallead.Id});
        Sharing_AccountLeadHandler.sharingAOCOnLeadConvertService(normallead.Id);
        Sharing_AccountLeadHandler.sharingAOCOnLeadConvert(normallead.Id);
        Sharing_AccountLeadHandler.sharingAOCOnLeadConvert(leadobj.Id);
    }
    
}