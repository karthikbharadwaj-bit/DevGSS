@isTest
private class Test_PricebookEntrySelector {
    //Account fields defined
    private static final String ACCOUNT_NAME = 'Test';
    private static final String ACCOUNT_BILLING_ID = '12345';

    //Account fields defined
    private static final String OPPORTUNITY_NAME = 'testOpportunity';
    private static final String OPPORTUNITY_BRAND_NAME = 'RingCentral';
    private static final String OPPORTUNITY_STAGE_NAME = 'Office';
    private static final String OPPORTUNITY_TIER_NAME = '1. Qualify';
    private static final String OPPORTUNITY_CURRENCY_ISO_CODE = 'USD';

    //Account fields defined
    private static final String QUOTE_NAME = 'TestQuote';

    //Account fields defined
    private static final String PRODUCT2_NAME = 'Test product';
    private static final String PRODUCT2_EXTID = 'Test';
 
    //Account fields defined
    private static final String ORDER_NAME = 'Test';
    private static final String ORDER_STATUS = 'Requested';

    //Assert message defined
    private static final String ASSERT_MESSAGE = 'Pricebook entries should be selected';

    @testsetup
    private static void testData(){
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Account.Name => ACCOUNT_NAME,
                        Account.Billing_ID__c => ACCOUNT_BILLING_ID
                    }
                )
                .create()
                .getRecord();
            
            Opportunity testOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Opportunity.AccountId => testAcc.Id,
                        Opportunity.Name => OPPORTUNITY_NAME,
                        Opportunity.Brand_Name__c => OPPORTUNITY_BRAND_NAME,
                        Opportunity.Tier_Name__c => OPPORTUNITY_TIER_NAME,
                        Opportunity.StageName => OPPORTUNITY_STAGE_NAME,
                        Opportunity.CurrencyIsoCode => OPPORTUNITY_CURRENCY_ISO_CODE
                        }
                )
                .create()
                .getRecord();
            
            Quote testQuote = (Quote) new SobjectBuilder(Quote.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Quote.Name => QUOTE_NAME,
                        Quote.OpportunityId => testOpp.Id,
                        Quote.Account__c => testOpp.AccountId,
                        Quote.isPrimary__c => true,
                        Quote.Pricebook2Id => Test.getStandardPricebookId(),
                        Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
                    }
                )
                .create()
                .getRecord();
        
    
            Product2 prod = (Product2) new SObjectBuilder(Product2.sObjectType)
                .setFields(new Map<SObjectField, Object>{
                    Product2.Name => PRODUCT2_NAME,
                    Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                    Product2.IsActive => true,
                    Product2.ExtID__c => PRODUCT2_EXTID
                })
                .create()
                .getRecord();
    
        	Order testOrder = (Order) new SObjectBuilder(Order.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Order.AccountId => testAcc.Id,
                        Order.Name => ORDER_NAME,
                        Order.Status => ORDER_STATUS,
                        Order.OpportunityId => testOpp.Id,
                        Order.EffectiveDate => Date.newInstance(2050, 11, 11)
                    }
                )
                .create()
                .getRecord();
        
            PricebookEntry pbe = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
                .setFields(new Map<SObjectField, Object>{
                    PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                    PricebookEntry.Product2Id => prod.Id,
                    PricebookEntry.UnitPrice => 0,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false,
                    PricebookEntry.CurrencyIsoCode => OPPORTUNITY_CURRENCY_ISO_CODE
                })
                .create()
                .getRecord();
    }

    @isTest
    private static void testGetAllPBEs(){
        List<PricebookEntry> allPBEs = (List<PricebookEntry>) new PricebookEntrySelector(true, true)
            .getAllPBEs()
            .executeQuery();

        System.assert(allPBEs.size() > 0, ASSERT_MESSAGE);
    }
    
    
    @isTest
    private static void testGetContactCenterPBEs(){
        List<PricebookEntry> contactCenterPBEs = (List<PricebookEntry>) new PricebookEntrySelector()
            .getContactCenterPBEs('IsActive = true')
            .executeQuery();

        System.assert(contactCenterPBEs.size() > 0, ASSERT_MESSAGE);
    }
    @isTest
    private static void testGetQuotingToolSyncPBEs(){
        List<PricebookEntry> allPBEs = (List<PricebookEntry>) new PricebookEntrySelector()
            .getAllPBEs()
            .executeQuery();

        List<PricebookEntry> quotingToolSyncPBEs = (List<PricebookEntry>) new PricebookEntrySelector()
            .getQuotingToolSyncPBEs(new List<Object>{new Set<Id>{allPBEs[0].Pricebook2Id},
                                                     new Set<String>{PRODUCT2_EXTID},
                                                     new Set<String>{OPPORTUNITY_CURRENCY_ISO_CODE}})
            .executeQuery();

        System.assert(quotingToolSyncPBEs.size() > 0, ASSERT_MESSAGE);
    }
    
    @isTest
    private static void testSetPBEsByExtIds(){
		List<PricebookEntry> allPBEs = (List<PricebookEntry>) new PricebookEntrySelector()
            .getAllPBEs()
            .executeQuery();
        
        List<PricebookEntry> pBEsByExtIds = (List<PricebookEntry>) new PricebookEntrySelector()
            .getPBEsByExtIds(new List<Object>{new Set<String>{PRODUCT2_EXTID},
                                              new Set<Id>{allPBEs[0].Product2Id},
                                              new Set<Id>{allPBEs[0].Pricebook2Id}})
            .executeQuery();

        System.assert(pBEsByExtIds.size() > 0, ASSERT_MESSAGE);
    }
    
}