@isTest
private class Test_BatchJobUpdateQuoteLineItemLabels {

    private static final String PACKAGE_INFO_WITH_LABELS = '{"version":"2","targetPriceCalculations":{"targetPrice":"USD 5.00","recommendedDiscount":0},"q":null,"price":null,"partnerInfo":null,"parent":null,"originalDiscount":null,"lboxes":[],"lbox":null,"labels":{"shippingReq":"auto","another_label":"test"},"isPhoneLeasingEnabled":null,"isCore":null,"id":"1231005","duration":"Monthly","discount":{"Value":0,"Type":"Money"},"categoryPath":"HDRO","categoryCode":"HDRO"}';
    private static final String PACKAGE_INFO_WITHOUT_LABELS = '{"version":"2","targetPriceCalculations":{"targetPrice":"USD 5.00","recommendedDiscount":0},"q":null,"price":null,"partnerInfo":null,"parent":null,"originalDiscount":null,"lboxes":[],"lbox":null,"isPhoneLeasingEnabled":null,"isCore":null,"id":"1231005","duration":"Monthly","discount":{"Value":0,"Type":"Money"},"categoryPath":"HDRO","categoryCode":"HDRO"}';
    private static final String PACKAGE_INFO_WITH_NULL_LABELS = '{"version":"2","targetPriceCalculations":{"targetPrice":"USD 5.00","recommendedDiscount":0},"q":null,"price":null,"partnerInfo":null,"parent":null,"originalDiscount":null,"lboxes":[],"lbox":null,"labels":null,"isPhoneLeasingEnabled":null,"isCore":null,"id":"1231005","duration":"Monthly","discount":{"Value":0,"Type":"Money"},"categoryPath":"HDRO","categoryCode":"HDRO"}';
    private static final String SHIPPING_PACKAGE_INFO = '{"version":"2","targetPriceCalculations":{"targetPrice":"USD 5.00","recommendedDiscount":0},"q":null,"price":null,"partnerInfo":null,"parent":null,"originalDiscount":null,"lboxes":[],"lbox":null,"isPhoneLeasingEnabled":null,"isCore":null,"id":"1231005","duration":"Monthly","discount":{"Value":0,"Type":"Money"},"categoryPath":"SHP:SHIP","categoryCode":"SHIP"}';
    private static final String NOT_VALID_PACKAGE_INFO = '{not_valid_JSON}}}}}4938yr5';

    @TestSetup
    static void makeData() {
        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity',
                    Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SobjectType),
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                    Opportunity.Is_Billing_Opportunity__c => true
                }
            )
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'Test Quote',
                    Quote.OpportunityId => testOpp.Id,
                    Quote.IsPrimary__c => true,
                    Quote.Pricebook2Id => Test.getStandardPricebookId()
                }
            )
            .create()
            .getRecord();

        List<Product2> products = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Product2.Name => ValueProviderBuilder.provideUniqueString('Test Product'),
                    Product2.IsActive => true,
                    Product2.ExtId__c => ValueProviderBuilder.provideList(new List<String>{
                        'LC_HDR0_1',
                        'LC_HDR0_2',
                        'LC_HDR0_3',
                        'LC_SHIP_1'
                    })
                }
            )
            .quantity(4)
            .create()
            .getRecords();

        List<PricebookEntry> pbes = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                    PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(products),
                    PricebookEntry.UnitPrice => 100,
                    PricebookEntry.IsActive => true
                }
            )
            .quantity(products.size())
            .create()
            .getRecords();

        List<QuoteLineItem> qlis = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    QuoteLineItem.QuoteId => testQuote.Id,
                    QuoteLineItem.Quantity => 10,
                    QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideParents(pbes),
                    QuoteLineItem.UnitPrice => 100,
                    QuoteLineItem.Description => ValueProviderBuilder.provideList(new List<String>{
                        'QLI_WITH_LABELS',
                        'QLI_WITHOUT_LABELS',
                        'QLI_WITH_NULL_LABELS',
                        'QLI_SHIPPING'
                    }),
                    QuoteLineItem.PackageInfo__c => ValueProviderBuilder.provideList(new List<String>{
                        PACKAGE_INFO_WITH_LABELS,
                        PACKAGE_INFO_WITHOUT_LABELS,
                        PACKAGE_INFO_WITH_NULL_LABELS,
                        SHIPPING_PACKAGE_INFO
                    }),
                    QuoteLineItem.Package_Info_QLI__c => ValueProviderBuilder.provideList(new List<String>{
                        PACKAGE_INFO_WITH_LABELS,
                        PACKAGE_INFO_WITHOUT_LABELS,
                        PACKAGE_INFO_WITH_NULL_LABELS,
                        SHIPPING_PACKAGE_INFO
                    })
                }
            )
            .quantity(products.size())
            .create()
            .getRecords();
    }

    @isTest
    private static void testAddLabelsMethod() {

        BatchJob_UpdateQuoteLineItemLabels testBatch = new BatchJob_UpdateQuoteLineItemLabels();

        String pInfoJson;

        System.assertEquals(
            null,
            testBatch.addLabels(null, pInfoJson),
            'method should return passed json String if LabelMapping is null'
        );

        String labelName = 'shippingReq';
        String labelValue = 'manual';
        Set<String> categoryCodes = new Set<String>{'HDHS', 'HDO', 'HDRO'};
        BatchJob_UpdateQuoteLineItemLabels.LabelMapping testMapping = new BatchJob_UpdateQuoteLineItemLabels.LabelMapping(
            labelName,
            labelValue,
            categoryCodes
        );
        System.assertEquals(
            null,
            testBatch.addLabels(testMapping, pInfoJson),
            'method should return passed json String if json String is null or empty'
        );

        pInfoJson = '';
        System.assertEquals(
            '',
            testBatch.addLabels(testMapping, pInfoJson),
            'method should return passed json String if json String is null or empty'
        );

        pInfoJson = '{"categoryCode":"HD"}';
        System.assertEquals(
            pInfoJson,
            testBatch.addLabels(testMapping, pInfoJson),
            'method should return passed json String if categoryCode is different from the code specified in the mapping'
        );

        pInfoJson = '{"categoryCode":"HDO"}';
        String result = testBatch.addLabels(testMapping, pInfoJson);
        Map<String, Object> deserializedResult = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.assert(
            deserializedResult.containsKey('categoryCode'),
            'returned JSON should contains "categoryCode" property'
        );
        System.assert(
            deserializedResult.containsKey('labels'),
            'returned JSON should contains "labels" property'
        );
        Map<String, Object> updatedLabels = (Map<String, Object>) deserializedResult.get('labels');
        System.assert(
            updatedLabels.containsKey(labelName),
            'updated labels should contains property with name from LabelMapping(' + labelName + ')'
        );
        System.assertEquals(
            labelValue,
            updatedLabels.get(labelName),
            'updated labels should a value with value from LabelMapping(' + labelValue + ')'
        );

        String testLabelName = 'some_label';
        pInfoJson = '{"categoryCode":"HDO", "labels": {"' + testLabelName + '": "test"}}';
        result = testBatch.addLabels(testMapping, pInfoJson);
        deserializedResult = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.assert(
            deserializedResult.containsKey('labels'),
            'returned JSON should contains "labels" property'
        );
        updatedLabels = (Map<String, Object>) deserializedResult.get('labels');
        System.assert(
            updatedLabels.containsKey(testLabelName),
            'labels that are not specified in LabelMapping should stay untoched'
        );
    }

    @isTest
    private static void testRunBatchSuccess() {

        Test.startTest();

            Database.executeBatch(new BatchJob_UpdateQuoteLineItemLabels());

        Test.stopTest();

        List<QuoteLineItem> reselectedQlis = (List<QuoteLineItem>) new QuoteLineItemSelector()
            .selectQuoteLineItems()
            .executeQuery();

        for (QuoteLineItem qli : reselectedQlis) {
            Map<String, Object> deserializedPackageInfo = (Map<String, Object>) JSON.deserializeUntyped(qli.PackageInfo__c);
            if (deserializedPackageInfo.get('categoryCode') == 'SHIP') {
                continue;
            }
            System.assert(
                deserializedPackageInfo.containsKey('labels'),
                'returned JSON should contains "labels" property'
            );
            Map<String, Object> updatedLabels = (Map<String, Object>) deserializedPackageInfo.get('labels');
            System.assert(
                updatedLabels.containsKey('shippingReq'),
                'updated labels should contains "shippingReq" property'
            );
            System.assertEquals(
                'manual',
                updatedLabels.get('shippingReq'),
                'updated "shippingReq" label should have value "manual"'
            );
        }
    }

    @isTest
    private static void testRunBatchError() {

        QuoteLineItem reselectedQli = (QuoteLineItem) new QuoteLineItemSelector()
            .selectQuoteLineItems()
            .executeQuery()
            .get(0);

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Product2.Name => ValueProviderBuilder.provideUniqueString('Test Product'),
                    Product2.IsActive => true,
                    Product2.ExtId__c => 'LC_HDR0_4'
                }
            )
            .create()
            .getRecord();

        PricebookEntry pbe = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                    PricebookEntry.Product2Id => testProduct.Id,
                    PricebookEntry.UnitPrice => 100,
                    PricebookEntry.IsActive => true
                }
            )
            .create()
            .getRecord();

        Triggers.switchOff();
        QuoteLineItem qliWithInvalidPackageInfo = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    QuoteLineItem.QuoteId => reselectedQli.QuoteId,
                    QuoteLineItem.Quantity => 10,
                    QuoteLineItem.PricebookEntryId => pbe.Id,
                    QuoteLineItem.UnitPrice => 100,
                    QuoteLineItem.PackageInfo__c => NOT_VALID_PACKAGE_INFO,
                    QuoteLineItem.Package_Info_QLI__c => NOT_VALID_PACKAGE_INFO
                }
            )
            .create()
            .getRecord();
        Triggers.switchOn();

        Test.startTest();

            Database.executeBatch(new BatchJob_UpdateQuoteLineItemLabels());

        Test.stopTest();

        PlatformLog__c log = PlatformLog.getMostRecent();
        System.assertNotEquals(
            null,
            log,
            'in case of errors an PlatformLog__c record should be created'
        );

        System.assert(
            log.Error__c.contains(qliWithInvalidPackageInfo.Id),
            'PlatformLog__c record should contain Id of failed record'
        );
    }

    @isTest
    private static void testRunBatchWithCustomLabelMapping() {

        String labelName = 'custom_label_name';
        String labelValue = 'custom_label_value';

        Test.startTest();
            String query = 'select Id, PackageInfo__c, Package_Info_QLI__c, Description from QuoteLineItem where Description = \'QLI_SHIPPING\'';
            List<BatchJob_UpdateQuoteLineItemLabels.LabelMapping> mappingsList = new List<BatchJob_UpdateQuoteLineItemLabels.LabelMapping>{
                new BatchJob_UpdateQuoteLineItemLabels.LabelMapping(
                    labelName,
                    labelValue,
                    new Set<String>{'SHIP'}
                )
            };
            Database.executeBatch(new BatchJob_UpdateQuoteLineItemLabels(query, mappingsList));

        Test.stopTest();

        QuoteLineItem shippingQli = (QuoteLineItem) new QuoteLineItemSelector()
            .selectQuoteLineItems()
            .setCondition('Description = \'QLI_SHIPPING\'')
            .executeQuery()
            .get(0);

        Map<String, Object> deserializedPackageInfo = (Map<String, Object>) JSON.deserializeUntyped(shippingQli.PackageInfo__c);
        System.assert(
            deserializedPackageInfo.containsKey('labels'),
            'updated JSON should contains "labels" property'
        );
        Map<String, Object> updatedLabels = (Map<String, Object>) deserializedPackageInfo.get('labels');
        System.assert(
            updatedLabels.containsKey(labelName),
            'updated labels should contains property specified in LabelMapping(' + labelName + ')'
        );
        System.assertEquals(
            labelValue,
            updatedLabels.get(labelName),
            'updated labels should a value with value from LabelMapping(' + labelValue + ')'
        );
    }
}