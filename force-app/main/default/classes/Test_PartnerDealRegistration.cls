/*       
        * Created By    : 
        * Created Date  : 24-02-2020
        * Description   : Test class for Partner_DealRegistration class
        
Change History
********************************************************************************************************************
    SCRUM/Jira          ModifiedBy      Date     Description                             Tag

********************************************************************************************************************

*/
@isTest
public class Test_PartnerDealRegistration {

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testmethod1(){
        PartnerRecordsUtil objutil = new PartnerRecordsUtil();
        Test.startTest();    
        system.runAs(PartnerRecordsUtil.runAsAvayaAdmin){    
            ByPassTrigger__c bpt = new ByPassTrigger__c(SetupOwnerId= Userinfo.getUserId(), Bypass_Deal_Registration__c = true);
            insert bpt;   
            System.debug(bpt + ' bypassTrigger Deal Reg');
            Deal_Registration__c dealRegObj = PartnerRecordsUtil.createAvayaDeal();
            
            Partner_DealRegistration.getDealRegDataController(dealRegObj.Partner_Account__c, null, 1, 10, 'Test', 'Company_Name__c');
            Partner_DealRegistration.getDealRegDataController(dealRegObj.Partner_Account__c, 'Pending Approval', 1, 10, 'Test', 'Company_Name__c');
        }
        Test.stopTest();
        List<ByPassTrigger__c> bypassTrigger = [Select Bypass_Deal_Registration__c from ByPassTrigger__c ];
        System.debug(bypassTrigger + ' bypassTrigger Deal Reg');
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testmethod2(){
        PartnerRecordsUtil objutil = new PartnerRecordsUtil();
        Test.startTest();    
        system.runAs(PartnerRecordsUtil.runAsAvayaAdmin){            
            ByPassTrigger__c bpt = new ByPassTrigger__c(SetupOwnerId= Userinfo.getUserId(), Bypass_Deal_Registration__c = true);
            insert bpt;  
            Deal_Registration__c dealRegObj = PartnerRecordsUtil.createAvayaDeal();
            Partner_DealRegistration.getDealRegDataController(dealRegObj.Partner_Account__c, 'Any', 1, 10, 'Test', 'Company_Name__c');
            Partner_DealRegistration.getDealRegDataController(null, 'Any', 1, 10, 'Test', 'Company_Name__c');
        }
        Test.stopTest();
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testmethod3(){
        PartnerRecordsUtil objutil = new PartnerRecordsUtil();
        Test.startTest();    
        system.runAs(PartnerRecordsUtil.runAsAvayaAdmin){            
            ByPassTrigger__c bpt = new ByPassTrigger__c(SetupOwnerId= Userinfo.getUserId(), Bypass_Deal_Registration__c = true);
            insert bpt;  
            Deal_Registration__c dealRegObj = PartnerRecordsUtil.createAvayaDeal();
            Partner_DealRegistration.getDealRecordList(dealRegObj.Id);
        }
        Test.stopTest();
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testmethod4(){
        PartnerRecordsUtil objutil = new PartnerRecordsUtil();
        Test.startTest();    
        system.runAs(PartnerRecordsUtil.runAsAvayaAdmin){            
            ByPassTrigger__c bpt = new ByPassTrigger__c(SetupOwnerId= Userinfo.getUserId(), Bypass_Deal_Registration__c = true);
            insert bpt;  
            Deal_Registration__c dealRegObj = PartnerRecordsUtil.createAvayaDeal();
            Partner_DealRegistration.getDataForViewAll(1, 10, 'Pending Approval', 'Test', 'Company_Name__c');
            Partner_DealRegistration.getDataForViewAll(1, 10, null, 'Test', 'Company_Name__c');
        }
        Test.stopTest();
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testmethod5(){
        PartnerRecordsUtil objutil = new PartnerRecordsUtil();
        Test.startTest();    
        system.runAs(PartnerRecordsUtil.runAsAvayaAdmin){        
            ByPassTrigger__c bpt = new ByPassTrigger__c(SetupOwnerId= Userinfo.getUserId(), Bypass_Deal_Registration__c = true);
            insert bpt;  
            Deal_Registration__c dealRegObj = PartnerRecordsUtil.createAvayaDeal();
            Partner_DealRegistration.getDataForViewAll(1, 10, 'Any', 'Test', 'Company_Name__c');
        }
        Test.stopTest();
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testmethod6(){
        PartnerRecordsUtil objutil = new PartnerRecordsUtil();
        Test.startTest();    
        system.runAs(PartnerRecordsUtil.runAsAvayaAdmin){            
            ByPassTrigger__c bpt = new ByPassTrigger__c(SetupOwnerId= Userinfo.getUserId(), Bypass_Deal_Registration__c = true);
            insert bpt;  
            Deal_Registration__c dealRegObj = PartnerRecordsUtil.createAvayaDeal();
            Partner_DealRegistration.getNDADocument();
            Partner_DealRegistration.getCountryStateMap('');
        }
        Test.stopTest();
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testmethod7(){
        Test.startTest();              
        List<Strategic_Partner_Account__c> strategicmanagers = Partner_DealRegistration.getStrategicPartnerManagers('test');
        Test.stopTest();
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testmethod8(){
        PartnerRecordsUtil objutil = new PartnerRecordsUtil();
        Test.startTest();    
        system.runAs(PartnerRecordsUtil.runAsAvayaAdmin){            
            ByPassTrigger__c bpt = new ByPassTrigger__c(SetupOwnerId= Userinfo.getUserId(), Bypass_Deal_Registration__c = true);
            insert bpt;  
            Deal_Registration__c dealRegObj = PartnerRecordsUtil.createAvayaDeal();
            dealRegObj.Status__c = 'Approved';
            update dealRegObj;
        }
        Test.stopTest();
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
     @isTest
    static void testmethod9(){
        PartnerRecordsUtil objutil = new PartnerRecordsUtil();
        Test.startTest();    
        system.runAs(PartnerRecordsUtil.runAsAvayaMasterRole){            
            Partner_DealRegistration.getAccountList();
            //Partner_DealRegistration.getBrandPackages();
            Partner_DealRegistration.PartnerAccountMasterAgtChlMgr('test');
        }
        Test.stopTest();
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testmethod10(){
        PartnerRecordsUtil objutil = new PartnerRecordsUtil();
        System.runAs(PartnerRecordsUtil.runAsAvayaAdmin) {

        List<Product2> productList = Quote_TestDataFactory.generateProducts(1);
            insert productList;
                        
            List<Product_Package__c> packageList = Quote_TestDataFactory.generateProductPackage(2);
            packageList.get(0).Name = 'Product Package Name';
            packageList.get(0).Active__c = true;
            packageList.get(0).Description__c = 'Test Description';
            
            insert packageList;
            Wholesale_Partner_Package__c wholesalePackg = new Wholesale_Partner_Package__c();
            wholesalePackg.Wholesale_Partner_Account__c = PartnerRecordsUtil.partnerAccount.Id;
            wholesalePackg.Product_Package__c = packageList.get(0).Id;
            wholesalePackg.Parent_Product_Package__c = packageList.get(1).Id;
            insert wholesalePackg;
            
        Test.startTest();    
            Partner_DealRegistration.getWholesalePartnerPackageEditions(PartnerRecordsUtil.partnerAccount.Id);
        Test.stopTest();
        }
    }
    @isTest
    static void testmethod11(){
        PartnerRecordsUtil objutil = new PartnerRecordsUtil();
        System.runAs(PartnerRecordsUtil.runAsAvayaAdmin) {            
        Test.startTest();
            List<CountryBusinessIdentityMapping__c> BICountryMapppingList = Partner_DealRegistration.getBICountriesCSList();
            System.assert(BICountryMapppingList != null);
        Test.stopTest();
        }
    }
    @isTest
    static void testGetServiceProvider() {
        Account accountComplete = new Account(Name = 'Ignite Acc 01', Number_of_DL_s__c = 11, Partner_ID__c = '123345',
                                              Current_Owner_Email__c = 'Ignite@rc.com', Avaya_Partnership_Account__c = true,
                                              Certified_Delivery_Partner_Status__c = 'Complete');
        insert accountComplete;
        
        Contact contactComplete = new Contact(AccountId = accountComplete.Id,Email ='Ignite@master.com',Phone = '5544332211',
                                              LastName = 'Master',FirstName='Ignite',
                                              Avaya_Partnership_Contact__c = true);
        insert contactComplete;
        
        Account accountNone = new Account(Name = 'Ignite Acc 02', Number_of_DL_s__c = 11, Partner_ID__c = '123445',
                                          Current_Owner_Email__c = 'IgniteN@rcc.com', Avaya_Partnership_Account__c = true);
        insert accountNone;
        
        Contact contactNone = new Contact(AccountId = accountNone.Id,Email ='Ignite@top.com',Phone = '1122334455',
                                          LastName = 'Master',FirstName='Top',
                                          Avaya_Partnership_Contact__c = true);
        insert contactNone;
        
        // Complete Delivery partner status
        List<String> resultComplete = Partner_DealRegistration.getServiceProvider(contactComplete.Id);
        System.assert(!resultComplete.contains('Enroll in CDP for Partner Install'), 'Enroll in CDP for Partner Install');
        
        // None Delivery partner status
        List<String> resultNone = Partner_DealRegistration.getServiceProvider(contactNone.Id);
        System.assert(!resultNone.contains('Partner Install, Certified Delivery Partner'), 'Partner Install, Certified Delivery Partner');
        
    }
    @isTest
    static void testGetServiceProviderByUser() {
        
        //For complete status
        Account accountComplete = new Account(Name = 'Ignite Acc 01', Number_of_DL_s__c = 11, Partner_ID__c = '123345',
                                              Current_Owner_Email__c = 'Ignite@rc.com', Avaya_Partnership_Account__c = true,
                                              Certified_Delivery_Partner_Status__c = 'Complete');
        insert accountComplete;
        
        Contact contactComplete = new Contact(AccountId = accountComplete.Id,Email ='Ignite@master.com',Phone = '5544332211',
                                              LastName = 'Master',FirstName='Ignite',
                                              Avaya_Partnership_Contact__c = true);
        insert contactComplete;
        
        User completeUser = new User(
            Lastname='Complete',
            Alias = 'compUse',
            Email = 'comp@ignite.com',
            CommunityNickname='compUse',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Partner Community - Partner Admin' LIMIT 1].Id,
            UserName = 'comp@ignite.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            PortalRole = 'Manager',
            ContactId = contactComplete.Id
        );
        insert completeUser;
        
        //For none status
        Account accountNone = new Account(Name = 'Ignite Acc 02', Number_of_DL_s__c = 11, Partner_ID__c = '123445',
                                          Current_Owner_Email__c = 'IgniteN@rcc.com', Avaya_Partnership_Account__c = true);
        insert accountNone;
        
        Contact contactNone = new Contact(AccountId = accountNone.Id,Email ='Ignite@top.com',Phone = '1122334455',
                                          LastName = 'Master',FirstName='Top',
                                          Avaya_Partnership_Contact__c = true);
        insert contactNone;
        
        User noneUser = new User(
            Lastname='None',
            Alias = 'noneUse',
            Email = 'none@ignite.com',
            CommunityNickname='noneUse',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Partner Community - Partner Admin' LIMIT 1].Id,
            UserName = 'none@ignite.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            PortalRole = 'Manager',
            TimeZoneSidKey = 'America/Los_Angeles',
            ContactId = contactNone.Id
        );
        insert noneUser;
        
        // Complete Delivery partner status
        List<String> resultComplete = Partner_DealRegistration.getServiceProviderByUser(completeUser.Id);
        System.assert(!resultComplete.contains('Enroll in CDP for Partner Install'), 'Enroll in CDP for Partner Install');
        
        // None Delivery partner status
        List<String> resultNone = Partner_DealRegistration.getServiceProviderByUser(noneUser.Id);
        System.assert(!resultNone.contains('Partner Install, Certified Delivery Partner'), 'Partner Install, Certified Delivery Partner');
        
    }
}