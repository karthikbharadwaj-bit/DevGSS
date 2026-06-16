@isTest
private class Test_HardwareLineItemSelector {
	//Common fields defined 
	private static final String CURRENCY_ISO_CODE = 'USD';
    private static final String PACKAGE_CATALOG_ID = '7';
    private static final String PACKAGE_VERSION = '1';
    
    //Account fieleds defined
    private static final String ACCOUNT_NAME = 'Test';
    private static final String ACCOUNT_BILLING_ID = '12345';
        
    //Opportunity fields defined 
    private static final String OPPORTUNITY_NAME = 'TestOpportunity';
    private static final String OPPORTUNITY_BRAND_NAME = 'RingCentral';
    private static final String OPPORTUNITY_TIER_NAME = 'Office';
    private static final String OPPORTUNITY_STAGE_NAME = '1. Qualify';
        
    //Quote fields defined
    private static final String QUOTE_NAME = 'testQuote';
        
    //Order fields defined
    private static final String ORDER_NAME = 'test';
    private static final String ORDER_STATUS = 'Requested';
        
    //Phase__c fields defined
    private static final String PHASE_NAME = 'Test';
        
    //Product2 fields defined
    private static final String PRODUCT2_NAME = 'test product';
        
    //PricebookEntry fields defined
    private static final String PRICEBOOK_ENTRY_CURRENCY_ISO_CODE = 'USD';
               
    //Hardware_Line_Item__c fields defined
    private static final String HARDWARE_LINE_ITEM_NAME = 'TestHardwareLineItem';
    
    //Assert message defined
    private static final String ASSERT_EQUALS_MESSAGE = '1 hardware line item should be selected';
    
    @testsetup
    private static void testData(){
        Triggers.SwitchOff();
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
                        Opportunity.StageName =>OPPORTUNITY_STAGE_NAME,
                        Opportunity.CurrencyIsoCode => CURRENCY_ISO_CODE,
                        Opportunity.CloseDate => Date.newInstance(2050, 11, 11)
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
    
        Order testOrder = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Order.AccountId => testAcc.Id,
                    Order.Name => ORDER_NAME,
                    Order.Status => ORDER_STATUS,
                    Order.EffectiveDate => Date.newInstance(2050, 11, 11)
                }
            )
            .create()
            .getRecord();
    
        Phase__c testPhase = (Phase__c) new SObjectBuilder(Phase__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Phase__c.Name => PHASE_NAME,
                    Phase__c.Quote__c => testQuote.Id,
                    Phase__c.Order__c => testOrder.Id,
                    Phase__c.Account__c => testAcc.Id
                }
            )
            .create()
            .getRecord();
    
        Product2 prod = (Product2) new SObjectBuilder(Product2.sObjectType)
                .setFields(new Map<SObjectField, Object>{
                    Product2.Name => PRODUCT2_NAME,
                    Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                    Product2.IsActive => true
                })
                .create()
                .getRecord();
    
		PricebookEntry pbe = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
                .setFields(new Map<SObjectField, Object>{
                    PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                    PricebookEntry.Product2Id => prod.Id,
                    PricebookEntry.UnitPrice => 0,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false,
                    PricebookEntry.CurrencyIsoCode => CURRENCY_ISO_CODE
                })
                .create()
                .getRecord();
    
		Entitlement__c ent = (Entitlement__c) new SObjectBuilder(Entitlement__c.sObjectType)
                .setFields(new Map<SObjectField, Object>{
                    Entitlement__c.Account__c => testAcc.Id,
                    Entitlement__c.Quote__c => testQuote.Id,
                    Entitlement__c.Product__c => prod.Id,
                    Entitlement__c.Quantity__c => 1,
                    Entitlement__c.Price__c => 50,
                    Entitlement__c.ChargeTerm__c => Product2Helper.CHARGE_TERM_MONTHLY,
                    Entitlement__c.Discount__c => 10,
                    Entitlement__c.Discount_Type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                    Entitlement__c.PackageCatalogId__c => PACKAGE_CATALOG_ID,
                    Entitlement__c.PackageVersion__c => PACKAGE_VERSION,
                    Entitlement__c.Active__c => true
                })
                .create()
                .getRecord();
    
		QuoteLineItem qliList = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
                .setFields(new Map<SObjectField, Object>{
                    QuoteLineItem.Product2Id => prod.Id,
                    QuoteLineItem.QuoteId => testQuote.Id,
                    QuoteLineItem.PricebookEntryId => pbe.Id,
                    QuoteLineItem.Entitlement__c => ent.Id,
                    QuoteLineItem.Quantity => 1,
                    QuoteLineItem.NewQuantity__c => 1,
                    QuoteLineItem.Zero_Quantity__c => false,
                    QuoteLineItem.UnitPrice => 50,
                    QuoteLineItem.Discount_number__c => 1,
                    QuoteLineItem.Discount_type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                    QuoteLineItem.PackageInfo__c => NGBSTestDataGenerator.generateQLIPackageInfo(),
                    QuoteLineItem.Package_Info__c => NGBSTestDataGenerator.generateQLIPackageInfo(),
                    QuoteLineItem.Package_Info_QLI__c => NGBSTestDataGenerator.generateQLIPackageInfo(),
                    QuoteLineItem.PackageCatalogId__c => PACKAGE_CATALOG_ID,
                    QuoteLineItem.PackageVersion__c => PACKAGE_VERSION
                })
                .create()
                .getRecord();
        
        Hardware_Line_Item__c testHLI = (Hardware_Line_Item__c) new SObjectBuilder(Hardware_Line_Item__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Hardware_Line_Item__c.Name => HARDWARE_LINE_ITEM_NAME,
					Hardware_Line_Item__c.RingCentral_Hardware_Phase__c => testPhase.Id,
                    Hardware_Line_Item__c.Order__c => testOrder.Id,
                    Hardware_Line_Item__c.Quote_Line_Item__c => qliList.Id
                }
            )
            .create()
            .getRecord();
        Triggers.SwitchOn();
    }
    
    @isTest
    private static void testSelectHardwareLineItems(){
        List<Hardware_Line_Item__c> hardwareLineItems = (List<Hardware_Line_Item__c>) new HardwareLineItemSelector(true, true)
            .selectHardwareLineItems()
            .executeQuery();
        
        System.assertEquals(1, hardwareLineItems.size(), ASSERT_EQUALS_MESSAGE);
    }
    
    @isTest
    private static void testSelectPhaseLineItemsForClose(){
        List<Hardware_Line_Item__c> phaseLineItemsForClose = (List<Hardware_Line_Item__c>) new HardwareLineItemSelector()
            .selectPhaseLineItemsForClose()
            .executeQuery();
        
        System.assertEquals(1, phaseLineItemsForClose.size(), ASSERT_EQUALS_MESSAGE);
    }
    
    @isTest
    private static void testSelectPhaseLineItemsByPhaseIds(){
        List<Hardware_Line_Item__c> hardwareLineItems = (List<Hardware_Line_Item__c>) new HardwareLineItemSelector(true, true)
            .selectHardwareLineItems()
            .executeQuery();
        
        List<Hardware_Line_Item__c> phaseLineItemsByPhaseIds = (List<Hardware_Line_Item__c>) new HardwareLineItemSelector()
            .selectPhaseLineItemsByPhaseIds(new List<Object>{new Set<Id>{hardwareLineItems[0].RingCentral_Hardware_Phase__c}})
            .executeQuery();
        
        System.assertEquals(1, phaseLineItemsByPhaseIds.size(), ASSERT_EQUALS_MESSAGE);
        System.assertEquals(hardwareLineItems[0].RingCentral_Hardware_Phase__c, phaseLineItemsByPhaseIds[0].RingCentral_Hardware_Phase__c, 'Wrong hardware line item selected');
    }
}