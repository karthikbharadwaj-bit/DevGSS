@isTest
public with sharing class Test_PRM_Package_Creator_Helper {
  @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
  @isTest static void test_getAccountFromNGBSPartnerId() {
    PRM_Package_Creator_Helper.getAccountFromNGBSPartnerId('20');
    PRM_Package_Creator_Helper.getAccountFromNGBSPartnerId('JUNK');
  }

  @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
  @isTest static void test_getCatalogPackageData() {
    Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
    PRM_Package_Creator_Helper.getCatalogPackageData('20', '1');
  }

  @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
  @isTest static void test_getPartnerPackages() {
    Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
    PRM_Package_Creator_Helper.getPartnerPackages('20', true);
    PRM_Package_Creator_Helper.getPartnerPackages('20', false);
  }

  @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
  @isTest 
    static void test_upsertMethods() {
    Profile profile1 = [Select Id from Profile where name = 'System Administrator'];
    User userSysAdmin = new User(
        ProfileId = profile1.Id,
        Username = System.now().millisecond()+'test212testt@test.com',
        Alias = 'batndfw',
        Email='bruce.wayne@wayneenterprises2f234.com',
        EmailEncodingKey='UTF-8',
        Firstname='Bruce',
        Lastname='Wayne',
        LanguageLocaleKey='en_US',
        LocaleSidKey='en_US',
        TimeZoneSidKey='America/Chicago'
    );
    Database.insert(userSysAdmin);
  System.runAs(userSysAdmin) {
    ByPassTrigger__c bpt = new ByPassTrigger__c(SetupOwnerId= Userinfo.getUserId(), Bypass_Account_Trigger__c = true);
  insert bpt;
   Account portalAccount1 = new Account(
            Name = 'TestAccount',
            OwnerId = userSysAdmin.Id,
            RC_Brand__c ='Avaya Cloud Office',
          type = 'Partner',
          Avaya_partnership_account__c = true,
            Permitted_Brands__c = 'Avaya Cloud Office',
  Partner_Hierarchy_Level__c = 'Master',
         Partner_Role__c = 'Master Agent',
         Partner_Type__c = 'Master Agent'
        );
        Database.insert(portalAccount1);
    Product_Package__c pkg = new Product_Package__c(Ext_Element_Id__c = 'Test');
    PRM_Package_Creator_Helper.upsertProductPackageApex(pkg);

    Product2 prd = new Product2(ExtID__c = 'Test', Name = 'Test');
    PRM_Package_Creator_Helper.upsertProduct2Apex(prd);

    Product_Catalogue__c cat = new Product_Catalogue__c(ExtId__c = 'Test');
    PRM_Package_Creator_Helper.upsertProductCatalogueApex(cat);

    Product_Tier_Price__c tierPrice = new Product_Tier_Price__c(ExtID__c = 'Test');
    PRM_Package_Creator_Helper.upsertProductTierPriceApex(tierPrice);

    Product_Catalogue_Rule__c catRule = new Product_Catalogue_Rule__c(ExtID__c = 'Test');
    PRM_Package_Creator_Helper.upsertProductCatalogueRuleApex(catRule);

    Wholesale_Partner_Package__c wpp = new Wholesale_Partner_Package__c(ExtID__c = 'Test', Product_Package__c = pkg.Id, Wholesale_Partner_Account__c = portalAccount1.id);
    PRM_Package_Creator_Helper.upsertWholesalePartnerPackageApex(wpp);
  }
  }
}