@isTest
private class Test_EntitlementSelector {
    //User fields defined
    private static final String USER_FIRST_NAME = 'TestUserFirstName';
    private static final String USER_LAST_NAME = 'TestUserLastName';
    private static final String USER_USERNAME = 'testuser123@username.com';
    private static final String USER_EMAIL = 'user@email.com';

	//Account fields defined
    private static final String ACCOUNT_NAME = 'Test';
    private static final String ACCOUNT_BILLING_ID = '12345';

    //Opportunity fields defined
    private static final String OPPORTUNITY_NAME = 'TestOpportunity';
    private static final String OPPORTUNITY_BRAND_NAME = 'RingCentral';
    private static final String OPPORTUNITY_TIER_NAME = 'Office';
    private static final String OPPORTUNITY_STAGENAME = '1. Qualify';
    private static final String OPPORTUNITY_CURRENCY_ISO_CODE = 'USD';

    //Quote fields defined
    private static final String QUOTE_NAME = 'testQuote';

    //Product2 fields defined
    private static final String PRODUCT2_NAME = 'test product';
	private static final String PRODUCT2_SUB_CATEGORY = 'Contact Center';

    //PricebookEntry fields defined
    private static final String PRICEBOOKENTRY_CURRENCY_ISO_CODE = 'USD';

    //Entitlement fields defined
    private static final String ENTITLEMENT_PACKAGE_CATALOG_ID = '7';
    private static final String ENTITLEMENT_PACKAGE_VERSION = '1';
    private static final String ENTITLEMENT_NAME = 'Test';

    //Assert messages defined
    private static final String ASSERT_MESSAGE = 'Entitlements should be selected';
    private static final String ASSERT_EQUALS_MESSAGE = 'Wrong entitlement selected';

    @testsetup
    private static void testData(){
        User testUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.FirstName => USER_FIRST_NAME,
                    User.LastName => USER_LAST_NAME,
                    User.ProfileId => System.UserInfo.getProfileId(),
                    User.UserName => USER_USERNAME,
                    User.Email => USER_EMAIL,
                    User.isActive => TRUE
                }
            )
            .create()
            .getRecord();

        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Account.Name => ACCOUNT_NAME,
                        Account.Billing_ID__c => ACCOUNT_BILLING_ID,
                       	Account.RC_User_ID__c => testUser.Id
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
                        Opportunity.StageName => OPPORTUNITY_STAGENAME,
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
                .setFields(
                    new Map<SObjectField, Object>{
                        Product2.Name => PRODUCT2_NAME,
                        Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                        Product2.IsActive => true,
                        Product2.Sub_Category__c => PRODUCT2_SUB_CATEGORY
                })
                .create()
                .getRecord();

            PricebookEntry pbe = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                        PricebookEntry.Product2Id => prod.Id,
                        PricebookEntry.UnitPrice => 0,
                        PricebookEntry.IsActive => true,
                        PricebookEntry.UseStandardPrice => false,
                        PricebookEntry.CurrencyIsoCode => PRICEBOOKENTRY_CURRENCY_ISO_CODE
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
                        Entitlement__c.PackageVersion__c => ENTITLEMENT_PACKAGE_VERSION,
                        Entitlement__c.Active__c => true,
                        Entitlement__c.Name => ENTITLEMENT_NAME
                })
                .create()
                .getRecord();
    }

    @isTest
    private static void testSelectActiveEntitlementsForAccount(){
        List<Account> accounts = (List<Account>) new AccountSelector()
            .selectAccounts()
            .executeQuery();

        List<Entitlement__c> quoteLineItemsForQuoteAmounts = (List<Entitlement__c>) new EntitlementSelector(true, true)
            .selectActiveEntitlementsForAccount(new List<Object>{new Set<Id>{accounts[0].Id}})
            .executeQuery();

        System.assert(quoteLineItemsForQuoteAmounts.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    private static void testSelectEntitlementForSyncWithNGBSByName(){
        List<Entitlement__c> entitlementForSyncWithNGBSByName = (List<Entitlement__c>) new EntitlementSelector()
            .selectEntitlementForSyncWithNGBSByName(ENTITLEMENT_NAME)
            .executeQuery();

        System.assert(entitlementForSyncWithNGBSByName.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    private static void testSelectEntitlementForSyncQuoteLineItemsByQuoteId(){
        List<Quote> quotes = (List<Quote>) new QuoteSelector()
            .selectQuotes()
            .executeQuery();

        List<Entitlement__c> entitlementForSyncQuoteLineItemsByQuoteId = (List<Entitlement__c>) new EntitlementSelector()
            .selectEntitlementForSyncQuoteLineItemsByQuoteId(quotes[0].Id)
            .executeQuery();

        System.assert(entitlementForSyncQuoteLineItemsByQuoteId.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    private static void testSelectEntitlementsForCheckCCEntls(){
        List<Entitlement__c> entitlementsForCheckCCEntls = (List<Entitlement__c>) new EntitlementSelector()
            .selectEntitlementsForCheckCCEntls()
            .executeQuery();

        System.assert(entitlementsForCheckCCEntls.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    private static void testSelectEntitlementsByRcUserIdForCheckCCEntls(){
        List<Account> accounts = (List<Account>) new AccountSelector()
            .selectAccounts()
            .executeQuery();

        List<Entitlement__c> entitlementsByRcUserIdForCheckCCEntls = (List<Entitlement__c>) new EntitlementSelector()
            .selectEntitlementsByRcUserIdForCheckCCEntls(new List<Object>{new Set<Id>{accounts[0].RC_User_ID__c}})
            .executeQuery();

		List<Entitlement__c> entitlementsByRcUserIdForCheckCCEntlsElse = (List<Entitlement__c>) new EntitlementSelector()
            .selectEntitlementsByRcUserIdForCheckCCEntls(new List<Object>{new Set<Id>{accounts[0].RC_User_ID__c},
                														  new Set<String>{}})
            .executeQuery();

        System.assert(entitlementsByRcUserIdForCheckCCEntls.size() > 0, ASSERT_MESSAGE);
        System.assert(entitlementsByRcUserIdForCheckCCEntlsElse.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(accounts[0].Id, entitlementsByRcUserIdForCheckCCEntls[0].Account__c, ASSERT_EQUALS_MESSAGE);
        System.assertEquals(accounts[0].Id, entitlementsByRcUserIdForCheckCCEntlsElse[0].Account__c, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectEntitlementsByIdsWithProductDetails(){
        List<Entitlement__c> entitlementForSyncWithNGBSByName = (List<Entitlement__c>) new EntitlementSelector()
            .selectEntitlementForSyncWithNGBSByName(ENTITLEMENT_NAME)
            .executeQuery();

        List<Entitlement__c> entitlementsByIdsWithProductDetails = (List<Entitlement__c>) new EntitlementSelector()
            .selectEntitlementsByIdsWithProductDetails(new List<Id>{entitlementForSyncWithNGBSByName[0].Id})
            .executeQuery();

        System.assert(entitlementsByIdsWithProductDetails.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(entitlementForSyncWithNGBSByName[0].Id, entitlementsByIdsWithProductDetails[0].Id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectEntitlementsForSync(){
        List<Quote> quotes = (List<Quote>) new QuoteSelector()
            .selectQuotes()
            .executeQuery();

        List<Entitlement__c> entitlementsForSync = (List<Entitlement__c>) new EntitlementSelector()
            .selectEntitlementsForSync(quotes[0].Id)
            .executeQuery();

        System.assert(entitlementsForSync.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(quotes[0].Id, entitlementsForSync[0].Quote__c, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testGetEntitlementsForAccount(){
        List<Account> accounts = (List<Account>) new AccountSelector()
            .selectAccounts()
            .executeQuery();

        List<Entitlement__c> entitlements = (List<Entitlement__c>) new EntitlementSelector()
            .getEntitlements(accounts[0].Id)
            .executeQuery();

        System.assert(entitlements.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    private static void testSelectEntitlementsForViewEntPage() {
        Id dummyAccId = (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue();

        String query = new EntitlementSelector()
            .selectEntitlementsForViewEntPage(dummyAccId)
            .setQuery()
            .getQuery();

        String expectedWhereClause = 'WHERE Account__c = :bind0 AND PackageCatalogId__c = NULL';
        String expectedFrom = 'FROM Entitlement__c';
        String expectedSubSelectFromAndWhereClose = 'FROM Order_Products__r WHERE Order.Submitted_Date__c != null';

        System.assert(query.contains(expectedFrom) && query.contains(expectedWhereClause) && query.contains(expectedSubSelectFromAndWhereClose),
            'selectEntitlementsForViewEntPage should reflect a proper query');
    }
}