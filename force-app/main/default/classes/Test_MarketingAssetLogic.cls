@isTest
private class Test_MarketingAssetLogic {
  @testSetup static void setup() {
    new SObjectBuilder(Marketing_Asset__c.SObjectType)
      .setField(Marketing_Asset__c.Name, 'Office Stuff')
      .setField(Marketing_Asset__c.Type__c, 'Webinar')
      .setField(Marketing_Asset__c.Asset_ID__c, '123')
      .setField(Marketing_Asset__c.Active__c, true)
      .create();

    new SObjectBuilder(Marketing_Asset__c.SObjectType)
      .setField(Marketing_Asset__c.Name, 'Contact Center Things')
      .setField(Marketing_Asset__c.Type__c, 'Whitepaper')
      .setField(Marketing_Asset__c.Asset_ID__c, '234')
      .setField(Marketing_Asset__c.Active__c, true)
      .create();

    User marketingUser = (User) new SObjectBuilder(User.SObjectType)
     .setFields(SObjectFactoryFieldDefaults.getDefaults(User.SObjectType))
     .setField(User.UserPermissionsMarketingUser, true)
     .create()
     .getRecord();
    System.runAs(marketingUser) {
      new SObjectBuilder(Campaign.SObjectType)
        .setField(Campaign.Name, 'Good Campaign')
        .setField(Campaign.BMID__c, '1234')
        .setField(Campaign.Intended_Product__c, 'UK Glip')
        .create();
    }
  }
  
  @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
  @isTest static void testLeadDFRStamping() {
    test.startTest();
    Lead leadWithAsset = (Lead) new SObjectBuilder(Lead.SObjectType)
      .setField(Lead.FirstName, 'Testly')
      .setField(Lead.LastName, 'Testerson')
      .setField(Lead.Company, 'Tester Quizmo')
      .setField(Lead.Email, 'testly.testerson@testfake.com')
      .setField(Lead.LeadSource, 'X')
      .setField(Lead.Status, '1. New')
      .setField(Lead.Asset_ID__c, '123')
      .create()
      .getRecord();
    test.stopTest();
    
    DemandFunnelSelector dfrSelector = new DemandFunnelSelector();
    Demand_Funnel__c leadDFR = (Demand_Funnel__c) dfrSelector.selectDFRForMarketingAssetProcessing(new List<Object>{new Set<Id>{leadWithAsset.Id}, new Set<Id>(), new Set<Id>(), new Set<Id>()}).executeQuery()[0];
    MarketingAssetSelector marketingAssetSelector = new MarketingAssetSelector();
    Marketing_Asset__c ma = (Marketing_Asset__c) marketingAssetSelector.selectMarketingAssetByAssetId(new List<Object>{'123'}).executeQuery()[0];
  }

  @isTest static void testLeadCampaignMemberCreation() {
    Lead leadWithAsset = (Lead) new SObjectBuilder(Lead.SObjectType)
      .setField(Lead.FirstName, 'Test')
      .setField(Lead.LastName, 'Campaign Member')
      .setField(Lead.Company, 'Campaign Memberson')
      .setField(Lead.Email, 'tcm@testfake.com')
      .setField(Lead.LeadSource, 'X')
      .setField(Lead.Status, '1. New C')
      .setField(Lead.Asset_ID__c, '123')
      .setField(Lead.BMID__c, '1234')
      .create()
      .getRecord();


    Campaign myCampaign = (Campaign) new CampaignSelector().selectCampaignsByName(new List<String>{'Good Campaign'}).executeQuery()[0];

    List<Object> bindings = new List<Object>{new List<Id>{leadWithAsset.Id}, new List<Id>{myCampaign.Id}};
    List<CampaignMember> newCm = (List<CampaignMember>)  new CampaignMemberSelector().selectCampaignMemberByLeadAndCampaignIds(bindings).executeQuery();

    System.assert(!newCm.isEmpty(),
      'No campaign member created.');

    System.assertEquals(leadWithAsset.Id, newCm[0].LeadId,
      'New campaign member not created for lead.');

  }

  @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
  @isTest static void testContactAssetMatching() {
    Contact contactWithAsset = (Contact) new SObjectBuilder(Contact.SObjectType)
      .setField(Contact.FirstName, 'ContactPerson')
      .setField(Contact.LastName, 'ContactPersonLastName')
      .setField(Contact.Email, 'contactperson@test.com')
      .setField(Contact.Asset_ID__c, '123')
      .create()
      .getRecord();

      ContactSelector contactSelector = new ContactSelector();
      contactWithAsset = (Contact) contactSelector.selectContactById(new List<Object>{contactWithAsset.Id}).selectField(Contact.Most_Recent_Asset__c).executeQuery()[0];

      MarketingAssetSelector marketingAssetSelector = new MarketingAssetSelector();
      Marketing_Asset__c ma =  (Marketing_Asset__c) marketingAssetSelector.selectMarketingAssetByAssetId(new List<Object>{'123'}).executeQuery()[0];
      TriggerHandler.BY_PASS_CONTACT_ON_BEFORE = false;

      contactWithAsset.Asset_ID__c = '234';
      update contactWithAsset;
      contactWithAsset = (Contact) contactSelector.selectContactById(new List<Object>{contactWithAsset.Id}).selectField(Contact.Most_Recent_Asset__c).executeQuery()[0];
      Marketing_Asset__c ma2 = (Marketing_Asset__c) marketingAssetSelector.selectMarketingAssetByAssetId(new List<Object>{'234'}).executeQuery()[0];
  }

  @isTest static void testContactAssetMatchingWithBypass() {
    Feature_Toggle__c ft = new Feature_Toggle__c();
    ft.Bypass_Asset_Logic__c = true;
    insert ft;
    Contact contactWithAsset = (Contact) new SObjectBuilder(Contact.SObjectType)
      .setField(Contact.FirstName, 'ContactPerson')
      .setField(Contact.LastName, 'ContactPersonLastName')
      .setField(Contact.Email, 'contactperson@test.com')
      .setField(Contact.Asset_ID__c, '123')
      .create()
      .getRecord();


      ContactSelector contactSelector = new ContactSelector();
      contactWithAsset = (Contact) contactSelector.selectContactById(new List<Object>{contactWithAsset.Id}).selectField(Contact.Most_Recent_Asset__c).executeQuery()[0];
      System.assert(contactWithAsset.Most_Recent_Asset__c == null,
        'Asset assigned to contact despite bypass.');
  }

  @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
  @isTest static void testLeadAssetMatching() {
    Lead leadWithAsset = (Lead) new SObjectBuilder(Lead.SObjectType)
      .setField(Lead.FirstName, 'Testly')
      .setField(Lead.LastName, 'Testerson')
      .setField(Lead.Company, 'Tester Quizmo')
      .setField(Lead.Email, 'testly.testerson@testfake.com')
      .setField(Lead.LeadSource, 'X')
      .setField(Lead.Asset_ID__c, '123')
      .create()
      .getRecord();


    LeadSelector leadSelector = new LeadSelector();
    leadWithAsset = (Lead) leadSelector.selectLeadById(new List<Object>{leadWithAsset.Id}).selectField(Lead.Most_Recent_Asset__c).executeQuery()[0];

    MarketingAssetSelector marketingAssetSelector = new MarketingAssetSelector();
    Marketing_Asset__c ma =  (Marketing_Asset__c) marketingAssetSelector.selectMarketingAssetByAssetId(new List<Object>{'123'}).executeQuery()[0];
    leadWithAsset.Asset_ID__c = '234';
    update leadWithAsset;
    leadWithAsset = (Lead) leadSelector.selectLeadById(new List<Object>{leadWithAsset.Id}).selectField(Lead.Most_Recent_Asset__c).executeQuery()[0];
    Marketing_Asset__c ma2 = (Marketing_Asset__c) marketingAssetSelector.selectMarketingAssetByAssetId(new List<Object>{'234'}).executeQuery()[0];
  }

  @isTest static void testLeadAssetMatchingWithBypass() {
    Feature_Toggle__c ft = new Feature_Toggle__c();
    ft.Bypass_Asset_Logic__c = true;
    insert ft;

    Lead leadWithAsset = (Lead) new SObjectBuilder(Lead.SObjectType)
      .setField(Lead.FirstName, 'Testly')
      .setField(Lead.LastName, 'Testerson')
      .setField(Lead.Company, 'Tester Quizmo')
      .setField(Lead.Email, 'testly.testerson@testfake.com')
      .setField(Lead.LeadSource, 'X')
      .setField(Lead.Asset_ID__c, '123')
      .create()
      .getRecord();


    LeadSelector leadSelector = new LeadSelector();
    leadWithAsset = (Lead) leadSelector.selectLeadById(new List<Object>{leadWithAsset.Id}).selectField(Lead.Most_Recent_Asset__c).executeQuery()[0];
    System.assert(leadWithAsset.Most_Recent_Asset__c == null,
      'Asset assigned to lead despite bypass.');
  }
}