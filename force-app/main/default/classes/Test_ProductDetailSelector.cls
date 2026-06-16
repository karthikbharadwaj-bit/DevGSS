@isTest
private class Test_ProductDetailSelector {
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
    private static final String ASSERT_MESSAGE = 'Product details should be selected';

    @testsetup
    private static void testData(){
        Triggers.SwitchOff();
        
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Account.Name => 'Test',
                        Account.Billing_ID__c => '12345'
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
                        Opportunity.CurrencyIsoCode => OPPORTUNITY_CURRENCY_ISO_CODE,
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
        	
        	Product2 prod = (Product2) new SObjectBuilder(Product2.sObjectType)
                .setFields(new Map<SObjectField, Object>{
                    Product2.Name => PRODUCT2_NAME,
                    Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                    Product2.IsActive => true,
                    Product2.Charge_Term__c => 'Monthly'
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
                    PricebookEntry.CurrencyIsoCode => OPPORTUNITY_CURRENCY_ISO_CODE
                })
                .create()
                .getRecord();	
               
        	Entitlement__c ent = (Entitlement__c) new SObjectBuilder(Entitlement__c.sObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                    Entitlement__c.Account__c => testAcc.Id,
                    Entitlement__c.Quote__c => testQuote.Id,
                    Entitlement__c.Product__c => prod.Id,
                    Entitlement__c.Quantity__c => 1,
                    Entitlement__c.Price__c => 50,
                    Entitlement__c.ChargeTerm__c => Product2Helper.CHARGE_TERM_MONTHLY,
                    Entitlement__c.Discount__c => 10,
                    Entitlement__c.Discount_Type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                    Entitlement__c.PackageCatalogId__c => '7',
                    Entitlement__c.PackageVersion__c => '1',
                    Entitlement__c.Active__c => true
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
                        Order.Pricebook2Id => pbe.Pricebook2Id,
                        Order.EffectiveDate => Date.newInstance(2050, 11, 11)
                    }
                )
                .create()
                .getRecord();
        
            OrderItem testOrderItem = (OrderItem) new SObjectBuilder(OrderItem.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        OrderItem.OrderId => testOrder.Id,
                        OrderItem.Product2Id => prod.Id,
                        OrderItem.PricebookEntryId => pbe.Id,
                        OrderItem.UnitPrice => 10,
                        OrderItem.Quantity => 1
                    }
                )
                .create()
                .getRecord();
        
       		ProductDetail__c pd = (ProductDetail__c) new SObjectBuilder(ProductDetail__c.sObjectType)
                .setFields(new Map<SObjectField, Object>{
                    ProductDetail__c.Entitlement__c => ent.Id,
                    ProductDetail__c.OrderItem__c => testOrderItem.Id
                })
                .create()
                .getRecord();
        
        Triggers.SwitchOn();
    }
    
    @isTest
    private static void testSelectProductDetails(){
        List<ProductDetail__c> productDetails = (List<ProductDetail__c>) new ProductDetailSelector(true, true)
            .selectProductDetails()
            .executeQuery();

        System.assert(productDetails.size() > 0, ASSERT_MESSAGE);
    }
    
    @isTest
    private static void testSelectEntitlementProductDetailsByAccountIds(){
        List<Account> accounts = (List<Account>) new AccountSelector()
            .selectAccounts()
            .executeQuery();
        
        List<ProductDetail__c> entitlementProductDetailsByAccountIds = (List<ProductDetail__c>) new ProductDetailSelector()
            .selectEntitlementProductDetailsByAccountIds(new List<Object>{new Set<Id>{accounts[0].Id}})
            .executeQuery();
        
        System.assert(entitlementProductDetailsByAccountIds.size() > 0, ASSERT_MESSAGE);
    }
    
    @isTest
    private static void testSelectOrderProductDetailsByOrderIds(){
        List<Order> orders = (List<Order>) new OrderSelector()
            .selectOrders()
            .executeQuery();
        
        List<ProductDetail__c> orderProductDetailsByOrderIds = (List<ProductDetail__c>) new ProductDetailSelector()
            .selectOrderProductDetailsByOrderIds(new List<Object>{new Set<Id>{orders[0].Id}})
            .executeQuery();

        System.assert(orderProductDetailsByOrderIds.size() > 0, ASSERT_MESSAGE);    
    }
    
    @isTest
    private static void testGetFieldList(){
    	List<String> fieldList = (List<String>) new ProductDetailSelector().getFieldList();
        
        System.assert(fieldList.size() > 0);   
    }
}