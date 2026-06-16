@isTest
private class Test_BatchJob_RecalculateMRR {
    private static final String TEST_ACCOUNT_NAME = 'Test Account';
    private static final String TEST_OPPORTUNITY_NAME = 'Test Opportunity';
    private static final String TEST_QUOTE_NAME = 'Test Quote';

    //Product2 fields defined
    private static final String PRODUCT2_NAME = 'test product';
    private static final String PRODUCT2_SUB_CATEGORY = 'Contact Center';

    //Entitlement fields defined
    private static final String ENTITLEMENT_PACKAGE_VERSION = '1';
    private static final String ENTITLEMENT_NAME = 'Seat';

    @isTest
    static void testRecalculateMRR() {
        Triggers.switchOff();
        Account testAcc = (Account) new SobjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => TEST_ACCOUNT_NAME
            })
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => TEST_OPPORTUNITY_NAME,
                Opportunity.AccountId => testAcc.Id,
                Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                Opportunity.CloseDate => Date.Today() + 10,
                Opportunity.CurrencyIsoCode => OpportunityHelper.CURRENCY_ISO_CODE_USD,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL
            })
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Quote.OpportunityId => testOpp.Id,
                    Quote.Name => TEST_QUOTE_NAME,
                    Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                    Quote.QuoteType__c => QuoteHelper.QUOTE_TYPE_QUOTE,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
                }
            )
            .create()
            .getRecord();

        Product2 prod1 = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Product2.Name => PRODUCT2_NAME,
                    Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                    Product2.IsActive => true,
                    Product2.Sub_Category__c => PRODUCT2_SUB_CATEGORY,
                    Product2.Family => Product2Helper.FAMILY_CCSERVICE
                })
            .build()
            .getRecord();

        Product2 prod2 = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Product2.Name => PRODUCT2_NAME,
                    Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                    Product2.IsActive => true,
                    Product2.Sub_Category__c => PRODUCT2_SUB_CATEGORY,
                    Product2.Family => Product2Helper.FAMILY_MINUTES_BUNDLE,
                    Product2.Number_of_Minutes__c => 4
                })
            .build()
            .getRecord();

        Product2 prod3 = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Product2.Name => PRODUCT2_NAME,
                    Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                    Product2.IsActive => true,
                    Product2.Sub_Category__c => PRODUCT2_SUB_CATEGORY,
                    Product2.Family => Product2Helper.FAMILY_TAXES
                })
            .build()
            .getRecord();

        insert new List<Product2> {prod1, prod2, prod3};

        Entitlement__c ent1 = (Entitlement__c) new SObjectBuilder(Entitlement__c.sObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Entitlement__c.Account__c => testAcc.Id,
                    Entitlement__c.Quote__c => testQuote.Id,
                    Entitlement__c.Product__c => prod1.Id,
                    Entitlement__c.Quantity__c => 1,
                    Entitlement__c.Price__c => 50,
                    Entitlement__c.ChargeTerm__c => Product2Helper.CHARGE_TERM_MONTHLY,
                    Entitlement__c.Discount__c => 10,
                    Entitlement__c.Discount_Type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                    Entitlement__c.PackageVersion__c => ENTITLEMENT_PACKAGE_VERSION,
                    Entitlement__c.Active__c => true,
                    Entitlement__c.Name => ENTITLEMENT_NAME
                })
            .build()
            .getRecord();

        Entitlement__c ent2 = (Entitlement__c) new SObjectBuilder(Entitlement__c.sObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Entitlement__c.Account__c => testAcc.Id,
                    Entitlement__c.Quote__c => testQuote.Id,
                    Entitlement__c.Product__c => prod2.Id,
                    Entitlement__c.Quantity__c => 1,
                    Entitlement__c.Price__c => 30,
                    Entitlement__c.ChargeTerm__c => Product2Helper.CHARGE_TERM_MONTHLY,
                    Entitlement__c.PackageVersion__c => ENTITLEMENT_PACKAGE_VERSION,
                    Entitlement__c.Active__c => true,
                    Entitlement__c.Name => 'Test Int'
                })
            .build()
            .getRecord();

        Entitlement__c ent3 = (Entitlement__c) new SObjectBuilder(Entitlement__c.sObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Entitlement__c.Account__c => testAcc.Id,
                    Entitlement__c.Quote__c => testQuote.Id,
                    Entitlement__c.Product__c => prod2.Id,
                    Entitlement__c.Quantity__c => 1,
                    Entitlement__c.Price__c => 20,
                    Entitlement__c.ChargeTerm__c => Product2Helper.CHARGE_TERM_MONTHLY,
                    Entitlement__c.PackageVersion__c => ENTITLEMENT_PACKAGE_VERSION,
                    Entitlement__c.Active__c => true,
                    Entitlement__c.Name => 'Additional Port'
                })
            .build()
            .getRecord();

        Entitlement__c ent4 = (Entitlement__c) new SObjectBuilder(Entitlement__c.sObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Entitlement__c.Account__c => testAcc.Id,
                    Entitlement__c.Quote__c => testQuote.Id,
                    Entitlement__c.Product__c => prod3.Id,
                    Entitlement__c.Quantity__c => 1,
                    Entitlement__c.Price__c => 10,
                    Entitlement__c.ChargeTerm__c => Product2Helper.CHARGE_TERM_MONTHLY,
                    Entitlement__c.PackageVersion__c => ENTITLEMENT_PACKAGE_VERSION,
                    Entitlement__c.Active__c => true,
                    Entitlement__c.Name => 'Test'
                })
            .build()
            .getRecord();

        Triggers.switchOn();
        Package__c bap = (Package__c) new SobjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Name => 'test Package 1',
                Package__c.Account_Package_Id__c => '1111',
                Package__c.Package_Status__c => PackageHelper.PACKAGE_STATUS_ACTIVE,
                Package__c.Account__c => testAcc.Id,
                Package__c.Enterprise_Account_ID__c => testAcc.Id,
                Package__c.AdditionalProductsMRR__c => 50.0,
                Package__c.No_of_InContact_Seats__c => 1.0,
                Package__c.Total_MRR__c => 100
            })
            .create()
            .getRecord();

        insert new List<Entitlement__c> {ent1, ent2, ent3, ent4};

        Test.startTest();
            Database.executeBatch(new BatchJob_RecalculateMRR(new Set<Id> {testAcc.Id}, true));
        Test.stopTest();

        testAcc = (Account) new AccountSelector()
            .selectAccountById(testAcc.Id)
            .selectField(Account.Total_MRR__c)
            .executeQuery()
            .get(0);

        Assert.areEqual(100, testAcc.Total_MRR__c, 'Total_MRR__c is incorrect');
    }
}