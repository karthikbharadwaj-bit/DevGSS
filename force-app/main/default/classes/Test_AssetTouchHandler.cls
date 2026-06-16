@isTest
private class Test_AssetTouchHandler {
  @testSetup static void setup() {
  	new SObjectBuilder(Marketing_Asset__c.SObjectType)
      .setField(Marketing_Asset__c.Name, 'Office Stuff')
      .setField(Marketing_Asset__c.Type__c, 'Webinar')
      .setField(Marketing_Asset__c.Asset_ID__c, '123')
      .setField(Marketing_Asset__c.Active__c, true)
      .create();

    new SObjectBuilder(Lead.SObjectType)
      .setField(Lead.FirstName, 'Test')
      .setField(Lead.LastName, 'Campaign Member')
      .setField(Lead.Company, 'Campaign Memberson')
      .setField(Lead.Email, 'tcm@testfake.com')
      .setField(Lead.LeadSource, 'X')
      .setField(Lead.Status, '1. New C')
      .create();

    new SObjectBuilder(Contact.SObjectType)
      .setField(Contact.FirstName, 'ContactPerson')
      .setField(Contact.LastName, 'ContactPersonLastName')
      .setField(Contact.Email, 'contactperson@test.com')
      .create();
  }

  @isTest static void testAssetTouchInsertionWithoutRecalculation() {
  	LeadSelector leadSelector = new LeadSelector();
    Lead oneLead = (Lead) leadSelector.selectLeads().executeQuery()[0];
  	MarketingAssetSelector marketingAssetSelector = new MarketingAssetSelector();
  	Marketing_Asset__c ma =  (Marketing_Asset__c) marketingAssetSelector.selectMarketingAssetByAssetId(new List<Object>{'123'}).executeQuery()[0];
  	new SObjectBuilder(Asset_Touch__c.SObjectType)
      .setField(Asset_Touch__c.Lead__c, oneLead.Id)
      .setField(Asset_Touch__c.Marketing_Asset__c, ma.Id)
      .setField(Asset_Touch__c.Unique_Name__c, 'xyz.abc')
      .setField(Asset_Touch__c.Trigger_Recalculation__c, false)
      .setField(Asset_Touch__c.Asset_Touch_DateTime__c, Datetime.now())
      .create();
    oneLead = (Lead) leadSelector.selectLeads().selectField(Lead.Most_Recent_Asset__c).executeQuery()[0];
  	System.assert(oneLead.Most_Recent_Asset__c == null,
  		'Asset mistakenly assigned');
  }

  @isTest static void testAssetTouchInsertionWithRecalculation() {
  	LeadSelector leadSelector = new LeadSelector();
    Lead oneLead = (Lead) leadSelector.selectLeads().executeQuery()[0];
  	MarketingAssetSelector marketingAssetSelector = new MarketingAssetSelector();
  	Marketing_Asset__c ma =  (Marketing_Asset__c) marketingAssetSelector.selectMarketingAssetByAssetId(new List<Object>{'123'}).executeQuery()[0];
  	new SObjectBuilder(Asset_Touch__c.SObjectType)
      .setField(Asset_Touch__c.Lead__c, oneLead.Id)
      .setField(Asset_Touch__c.Marketing_Asset__c, ma.Id)
      .setField(Asset_Touch__c.Unique_Name__c, 'xyz.abc')
      .setField(Asset_Touch__c.Trigger_Recalculation__c, true)
      .setField(Asset_Touch__c.Asset_Touch_DateTime__c, Datetime.now())
      .create();
    oneLead = (Lead) leadSelector.selectLeads().selectField(Lead.Most_Recent_Asset__c).executeQuery()[0];
  	System.assert(oneLead.Most_Recent_Asset__c != null,
  		'Asset not assigned');
  }

  @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
  @isTest static void testAssetTouchInsertionWithRecalculationForContact() {
  	ContactSelector contactSelector = new ContactSelector();
    Contact oneContact = (Contact) contactSelector.selectContacts().executeQuery()[0];
  	MarketingAssetSelector marketingAssetSelector = new MarketingAssetSelector();
  	Marketing_Asset__c ma =  (Marketing_Asset__c) marketingAssetSelector.selectMarketingAssetByAssetId(new List<Object>{'123'}).executeQuery()[0];
  	new SObjectBuilder(Asset_Touch__c.SObjectType)
      .setField(Asset_Touch__c.Contact__c, oneContact.Id)
      .setField(Asset_Touch__c.Marketing_Asset__c, ma.Id)
      .setField(Asset_Touch__c.Unique_Name__c, 'xyz.abc')
      .setField(Asset_Touch__c.Trigger_Recalculation__c, true)
      .setField(Asset_Touch__c.Asset_Touch_DateTime__c, Datetime.now())
      .create();
    oneContact = (Contact) contactSelector.selectContacts().selectField(Contact.Most_Recent_Asset__c).executeQuery()[0];
//  	System.assert(oneContact.Most_Recent_Asset__c != null,
//  		'Asset not assigned');
  }
}