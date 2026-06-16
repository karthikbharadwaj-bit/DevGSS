@isTest
private class Test_SetApprovalTypeHelper {

    @TestSetup
    static void makeData() {
        Account acc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test acc'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SOBjectBuilder(Opportunity.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => acc.Id,
                Opportunity.CloseDate => System.today(),
                Opportunity.PriceBook2Id => Test.getStandardPricebookId()
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SOBjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => 'Test quote',
                Quote.OpportunityId => opp.Id,
                Quote.isPrimary__c => true,
                Quote.RecordTypeId => QuoteHelper.RT_ID_SALES,
                Quote.Pricebook2Id => Test.getStandardPricebookId()
            })
            .create()
            .getRecord();
    }

    @isTest
    static void testGetTabValuesMethod() {

        Account testAccount = (Account) new AccountSelector()
            .selectAccounts()
            .executeQuery()
            .get(0);

        Quote testQuote = (Quote) new QuoteSelector()
            .selectQuotes()
            .selectField(Quote.AccountId)
            .executeQuery()
            .get(0);

        Triggers.switchOff();
        QuoteLineItem testQli = NGBSTestDataGenerator.createQLI('testProduct', 'testExtId', 'USD', testAccount, testQuote);
        Triggers.switchOn();

        QuoteLineItem reselectedQli = (QuoteLineItem) new QuoteLineItemSelector()
            .selectQuoteLineItems()
            .selectFields(new List<String>{
                'QuoteId',
                'QuoteRecordType__c',
                'Product2.Charge_Term__c',
                'Product2.Family',
                'TotalPrice',
                'SubTotal',
                'Zero_Quantity__c',
                'Discount',
                'UnitPrice',
                'NewQuantity__c'
            })
            .executeQuery()
            .get(0);

        Test.startTest();
            Map<Id, SetApprovalTypeHelper.QuoteTabValues> result = SetApprovalTypeHelper.getTabValues(
                new List<QuoteLineItem>{
                    reselectedQli
                }
            );
            System.assert(!result.isEmpty(), 'method getTabValues should retun not empty result map');
            System.assert(result.containsKey(testQuote.Id), 'result map should contain QuoteId as a key');

            SetApprovalTypeHelper.QuoteTabValues quoteTabValue = result.get(testQuote.Id);
            System.assertEquals(50, quoteTabValue.FYCS);
            System.assertEquals(0, quoteTabValue.FYD);
            System.assertEquals(50, quoteTabValue.FYTCET);
            System.assertEquals(0, quoteTabValue.MRV);
        Test.stopTest();
    }

    @isTest
    static void testGetInitialDiscountWithoutProServMethod() {

        Account testAccount = (Account) new AccountSelector()
            .selectAccounts()
            .executeQuery()
            .get(0);

        Quote testQuote = (Quote) new QuoteSelector()
            .selectQuotes()
            .selectField(Quote.AccountId)
            .executeQuery()
            .get(0);

        Triggers.switchOff();
        QuoteLineItem testQli = NGBSTestDataGenerator.createQLI('testProduct', 'testExtId', 'USD', testAccount, testQuote);
        Triggers.switchOn();

        QuoteLineItem reselectedQli = (QuoteLineItem) new QuoteLineItemSelector()
            .selectQuoteLineItems()
            .selectFields(new List<String>{
                'QuoteId',
                'QuoteRecordType__c',
                'Product2.Charge_Term__c',
                'Product2.Family',
                'TotalPrice',
                'SubTotal',
                'Zero_Quantity__c'
            })
            .executeQuery()
            .get(0);

        Test.startTest();
            Map<Id, Decimal> result = SetApprovalTypeHelper.getInitialDiscountWithoutProServ(
                new List<QuoteLineItem>{
                    reselectedQli
                }
            );

            System.assert(!result.isEmpty(), 'method getTabValues should retun not empty result map');
            System.assert(result.containsKey(testQuote.Id), 'result map should contain QuoteId as a key');

            System.assertEquals((reselectedQli.SubTotal - reselectedQli.TotalPrice), result.get(testQuote.Id));

        Test.stopTest();
    }

    @isTest
    static void testGetProductsMapMethod() {

        Account testAccount = (Account) new AccountSelector()
            .selectAccounts()
            .executeQuery()
            .get(0);

        Quote testQuote = (Quote) new QuoteSelector()
            .selectQuotes()
            .selectField(Quote.AccountId)
            .executeQuery()
            .get(0);

        Triggers.switchOff();
        QuoteLineItem testQli = NGBSTestDataGenerator.createQLI('testProduct', 'testExtId', 'USD', testAccount, testQuote);
        Triggers.switchOn();

        QuoteLineItem reselectedQli = (QuoteLineItem) new QuoteLineItemSelector()
            .selectQuoteLineItems()
            .selectFields(new List<String>{
                'QuoteId',
                'QuoteRecordType__c',
                'Product2.Charge_Term__c',
                'Product2.Family',
                'TotalPrice',
                'SubTotal',
                'Zero_Quantity__c'
            })
            .executeQuery()
            .get(0);

        Test.startTest();
            Map<Id, String> result = SetApprovalTypeHelper.getProductsMap(
                new Map<Id, QuoteLineItem>{
                    reselectedQli.Id => reselectedQli
                }
            );

            System.assert(!result.isEmpty(), 'method getTabValues should retun not empty result map');
            System.assert(result.containsKey(testQuote.Id), 'result map should contain QuoteId as a key');

            System.assertEquals('RingCentral', result.get(testQuote.Id));

        Test.stopTest();
    }

    @isTest
    static void testIsValueNotEmptyMethod() {

        String nullString = null;

        Decimal testNullDec = null;

        System.assert(
            !SetApprovalTypeHelper.isValueNotEmpty(nullString),
            'isValueNotEmpty should return false if passed arg is null'
        );
        System.assert(
            !SetApprovalTypeHelper.isValueNotEmpty(''),
            'isValueNotEmpty should return false if passed arg is blank string'
        );
        System.assert(
            !SetApprovalTypeHelper.isValueNotEmpty('   '),
            'isValueNotEmpty should return false if passed arg is blank string'
        );
        System.assert(
            !SetApprovalTypeHelper.isValueNotEmpty('null'),
            'isValueNotEmpty should return false if passed arg is blank string'
        );

        System.assert(
            !SetApprovalTypeHelper.isValueNotEmpty(testNullDec),
            'isValueNotEmpty should return false if passed arg is null'
        );
        System.assert(
            SetApprovalTypeHelper.isValueNotEmpty(0),
            'isValueNotEmpty should return true if passed arg is decimal != null'
        );
        System.assert(
            SetApprovalTypeHelper.isValueNotEmpty(10.5),
            'isValueNotEmpty should return true if passed arg is decimal != null'
        );
    }
}