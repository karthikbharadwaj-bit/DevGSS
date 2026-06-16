@IsTest
private class Test_ShippingService {
    static final String LC_HD_141 = 'LC_HD_141';
    static final String LC_HD_139 = 'LC_HD_139';

    @testSetup
    static void makeData() {
        Triggers.switchOff();
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Test Account'
            })
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => 'Test Opportunity',
                Opportunity.AccountId => testAcc.Id,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Tier_Name__c => 'Professional',
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today(),
                Opportunity.CurrencyIsoCode => 'USD'
            })
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => 'Quote For Tests',
                Quote.OpportunityId => testOpp.Id,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.Approved_Status__c => QuoteHelper.APPROVAL_STATUS_APPROVED,
                Quote.Start_Date__c => Date.today(),
                Quote.End_Date__c => Date.today().addDays(2),
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Pricebook2Id => Test.getStandardPricebookId()
            })
            .create()
            .getRecord();

        List<Product2> productsMonthly = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => Product2Helper.CHARGE_TERM_MONTHLY,
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Product2.Family => Product2Helper.FAMILY_PHONE,
                Product2.ExtID__c => ValueProviderBuilder.provideList(new List<String> {LC_HD_141, LC_HD_139}),
                Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN
            })
            .quantity(2)
            .create()
            .getRecords();

        List<PricebookEntry> standardPricebookEntry = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => ValueProviderBuilder.provideList(new List<String> {productsMonthly[0].Id, productsMonthly[1].Id}),
                PricebookEntry.UnitPrice => 10,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .quantity(2)
            .create()
            .getRecords();

        new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => testQuote.Id,
                QuoteLineItem.Product2Id => ValueProviderBuilder.provideList(new List<String> {productsMonthly[0].Id, productsMonthly[1].Id}),
                QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideList(new List<String> {standardPricebookEntry[0].Id, standardPricebookEntry[1].Id}),
                QuoteLineItem.Quantity => 6,
                QuoteLineItem.UnitPrice => 10
            })
            .quantity(2)
            .create()
            .getRecords();
        Triggers.switchOn();
    }

    @isTest
    static void verifyShippingServiceGetsShippingInfoOnInitialize() {
        Quote testQuote = getQuoteWithQlis();
            
        Triggers.switchOff();
        List<CustomAddress__c> ca = (List<CustomAddress__c>) new SObjectBuilder(CustomAddress__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                CustomAddress__c.AddressLine__c => ValueProviderBuilder.provideList(new List<String> {'10 Avenue Jean Médecin', 'App.723 13 Elm Street'}),
                CustomAddress__c.City__c => ValueProviderBuilder.provideList(new List<String> {'Nice', 'Foster City'}),
                CustomAddress__c.Country__c => ValueProviderBuilder.provideList(new List<String> {'France', 'USA'}),
                CustomAddress__c.State__c => ValueProviderBuilder.provideList(new List<String> {'Nice', 'CA'}),
                CustomAddress__c.PostalCode__c => ValueProviderBuilder.provideList(new List<String> {'06000', '94404'})
            })
            .quantity(2)
            .create()
            .getRecords();

        List<CustomAddressAssignments__c> caa = (List<CustomAddressAssignments__c>) new SObjectBuilder(CustomAddressAssignments__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                CustomAddressAssignments__c.AttentionTo__c => ValueProviderBuilder.provideList(new List<String> {'Test France', 'Test USA'}),
                CustomAddressAssignments__c.CustomAddress__c => ValueProviderBuilder.provideList(new List<Id> {ca[0].Id, ca[1].Id}),
                CustomAddressAssignments__c.Quantity__c => ValueProviderBuilder.provideList(new List<Integer> {2, 4}),
                CustomAddressAssignments__c.QuoteLineItem__c => ValueProviderBuilder.provideList(new List<Id> {testQuote.QuoteLineItems[0].Id, testQuote.QuoteLineItems[1].Id}),
                CustomAddressAssignments__c.Type__c => 'Ground',
                CustomAddressAssignments__c.ShippingLicenseTree__c => 'LC_SHP_86:LC_SHIP_82:LC_SHIPT_80'})
            .quantity(4)
            .create()
            .getRecords();
        Triggers.switchOn();

        BillingWrappers.ParamsShipping paramsDataShipping = new BillingWrappers.ParamsShipping();
        paramsDataShipping.action = 'getShippingInfo';
        paramsDataShipping.selectedQuoteId = testQuote.Id;

        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(paramsDataShipping));
        RestContext.request = request;

        Test.startTest();
            ShippingService.shipping();
            Map <String,List<BillingWrappers.ShippingItemsInfo>> shippingData = ShippingService.getShippingInfo(paramsDataShipping.selectedQuoteId);
        Test.stopTest();

        Assert.areEqual(2, shippingData.size(), 'Shipping data size should contain 2 records');
        Assert.areEqual(2, shippingData.get(LC_HD_141).size(), 'Shipping info data should contain 2 records');
        Assert.areEqual(2, shippingData.get(LC_HD_139).size(), 'Shipping info should contain 2 records');
        Assert.areEqual(2, shippingData.get(LC_HD_141)[0].quantity, 'Quantity value should be 2');
        Assert.areEqual(2, shippingData.get(LC_HD_141)[1].quantity, 'Quantity value should be 2');
        Assert.areEqual(4, shippingData.get(LC_HD_139)[0].quantity, 'Quantity value should be 4');
        Assert.areEqual(4, shippingData.get(LC_HD_139)[1].quantity, 'Quantity value should be 4');
    }

    @isTest
    static void verifyCreationCustomAddressAndAssignmentsOnSaveFromService() {
        Quote testQuote = getQuoteWithQlis();

        Triggers.switchOff();
        Cost_Center__c costCenter = (Cost_Center__c) new SObjectBuilder(Cost_Center__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Cost_Center__c.Name => 'Test Main Cost Center',
                Cost_Center__c.BillingId__c => '1223244',
                Cost_Center__c.Quote__c => testQuote.Id
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        BillingWrappers.ShippingAddress shippingAddress0 = new BillingWrappers.ShippingAddress();
        BillingWrappers.ShippingAddress shippingAddress1 = new BillingWrappers.ShippingAddress();
        BillingWrappers.ShippingItemsInfo shippingItem0 = new BillingWrappers.ShippingItemsInfo();
        BillingWrappers.ShippingItemsInfo shippingItem1 = new BillingWrappers.ShippingItemsInfo();
        BillingWrappers.ShippingLocation shippingLocation0 = new BillingWrappers.ShippingLocation();
        BillingWrappers.ShippingLocation shippingLocation1 = new BillingWrappers.ShippingLocation();
        BillingWrappers.ShippingItemsInfo shippingItem2 = new BillingWrappers.ShippingItemsInfo();
        BillingWrappers.ShippingItemsInfo shippingItem3 = new BillingWrappers.ShippingItemsInfo();
        BillingWrappers.ShippingLocation shippingLocation2 = new BillingWrappers.ShippingLocation();
        BillingWrappers.ShippingLocation shippingLocation3 = new BillingWrappers.ShippingLocation();

        shippingAddress0.state = 'Nice';
        shippingAddress0.additionalAddressLine = 'null';
        shippingAddress0.addressLine = '10 Avenue Jean Médecin';
        shippingAddress0.city = 'Nice';
        shippingAddress0.country = 'France';
        shippingAddress0.zipCode = '06000';

        shippingAddress1.state = 'CA';
        shippingAddress1.additionalAddressLine = 'null';
        shippingAddress1.addressLine = 'App.723 13 Elm Street';
        shippingAddress1.city = 'Foster City';
        shippingAddress1.country = 'United States';
        shippingAddress1.zipCode = '94404';

        shippingLocation0.id = 'test1';
        shippingLocation0.shippingMethod = 'Ground';
        shippingLocation0.attentionTo = 'testContactFrance';
        shippingLocation0.address = shippingAddress0;
        shippingLocation0.shippingLicensesTree = 'LC_SHP_86:LC_SHIP_244:LC_SHIPT_245';
        shippingLocation0.shippingBillingCodeId = '551600002';

        shippingItem0.location = shippingLocation0;
        shippingItem0.quoteLineItemId = testQuote.QuoteLineItems[0].Id;
        shippingItem0.quantity = 2;
        shippingItem0.locationID = 'test1';
        shippingItem0.isDeleted = false;

        shippingLocation1.id = 'test2';
        shippingLocation1.shippingMethod = 'Ground';
        shippingLocation1.attentionTo = 'testContactFrance';
        shippingLocation1.address = shippingAddress0;
        shippingLocation1.shippingLicensesTree = 'LC_SHP_86:LC_SHIP_82:LC_SHIPT_80';
        shippingLocation1.shippingBillingCodeId = '1231414';

        shippingItem1.location = shippingLocation1;
        shippingItem1.quoteLineItemId = testQuote.QuoteLineItems[1].Id;
        shippingItem1.quantity = 2;
        shippingItem1.locationID = 'test2';
        shippingItem1.isDeleted = false;

        shippingLocation2.id = 'test3';
        shippingLocation2.shippingMethod = 'Ground';
        shippingLocation2.attentionTo = 'testContactUS';
        shippingLocation2.address = shippingAddress1;
        shippingLocation2.shippingLicensesTree = 'LC_SHP_86:LC_SHIP_244:LC_SHIPT_245';
        shippingLocation2.shippingBillingCodeId = '551600002';

        shippingItem2.location = shippingLocation2;
        shippingItem2.quoteLineItemId = testQuote.QuoteLineItems[0].Id;
        shippingItem2.quantity = 4;
        shippingItem2.locationID = 'test3';
        shippingItem2.isDeleted = false;

        shippingLocation3.id = 'test3';
        shippingLocation3.shippingMethod = 'Ground';
        shippingLocation3.attentionTo = 'testContactUS';
        shippingLocation3.address = shippingAddress1;
        shippingLocation3.shippingLicensesTree = 'LC_SHP_86:LC_SHIP_244:LC_SHIPT_245';
        shippingLocation3.shippingBillingCodeId = '551600002';

        shippingItem3.location = shippingLocation3;
        shippingItem3.quoteLineItemId = testQuote.QuoteLineItems[1].Id;
        shippingItem3.quantity = 4;
        shippingItem3.locationID = 'test3';
        shippingItem3.isDeleted = false;

        BillingWrappers.ParamsShipping paramsDataShipping = new BillingWrappers.ParamsShipping();
        paramsDataShipping.action = 'saveShippingInfo';
        paramsDataShipping.selectedQuoteId = testQuote.Id;
        paramsDataShipping.shippingItemsMap = new Map<String, List<BillingWrappers.ShippingItemsInfo>> {
            LC_HD_141 => new List<BillingWrappers.ShippingItemsInfo> {shippingItem0, shippingItem2},
            LC_HD_139 => new List<BillingWrappers.ShippingItemsInfo> {shippingItem1, shippingItem3}
        };

        Test.startTest();
            Map <String,List<BillingWrappers.ShippingItemsInfo>> shippingData = ShippingService.processShippingData(paramsDataShipping);
        Test.stopTest();

        Assert.areEqual(4, [Select COUNT() FROM CustomAddressAssignments__c], 'CustomAddressAssignment list should have 4 records');
        List<CustomAddressAssignments__c> caas = (List<CustomAddressAssignments__c>) new CustomAddressAssignmentsSelector()
            .selectCustomAddressAssignments()
            .executeQuery();
        for (CustomAddressAssignments__c caa : caas) {
            if (caa.ShippingBillingCodeId__c == '551600002') {
                Assert.areEqual('551600002', caa.ShippingBillingCodeId__c, 'ShippingBillingCodeId must be equal 551600002');
            } else {
                Assert.areEqual('1231414', caa.ShippingBillingCodeId__c, 'ShippingBillingCodeId must be equal 1231414');
            }
            if (caa.ShippingLicenseTree__c == 'LC_SHP_86:LC_SHIP_82:LC_SHIPT_80') {
                Assert.areEqual('LC_SHP_86:LC_SHIP_82:LC_SHIPT_80', caa.ShippingLicenseTree__c, 'ShippingBillingCodeId must be equal "LC_SHP_86:LC_SHIP_82:LC_SHIPT_80"');
            } else {
                Assert.areEqual('LC_SHP_86:LC_SHIP_244:LC_SHIPT_245', caa.ShippingLicenseTree__c, 'ShippingBillingCodeId must be equal "LC_SHP_86:LC_SHIP_244:LC_SHIPT_245"');
            }
        }
        Assert.areEqual(2, [Select COUNT() FROM CustomAddress__c], 'CustomAddress list should have 2 records');
    }

    @isTest
    static void verifyCreationCustomAddressAndAssignmentsForTechQLIOnSaveFromService() {
        Quote testQuote = getQuoteWithQlis();

        Triggers.switchOff();
        Cost_Center__c costCenter = (Cost_Center__c) new SObjectBuilder(Cost_Center__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Cost_Center__c.Name => 'Test Main Cost Center',
                Cost_Center__c.BillingId__c => '1223244',
                Cost_Center__c.Quote__c => testQuote.Id
            })
            .create()
            .getRecord();

        Triggers.switchOn();
        Quote testTechQuote = testQuote.clone(false, false, false, false);
        testTechQuote.MasterQuote__c = testQuote.Id;
        insert testTechQuote;

        QuoteLineItem techQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => testTechQuote.Id,
                QuoteLineItem.Product2Id => testQuote.QuoteLineItems[0].Product2Id,
                QuoteLineItem.PricebookEntryId => testQuote.QuoteLineItems[0].PricebookEntryId,
                QuoteLineItem.Quantity => 6,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.MasterQLI__c => testQuote.QuoteLineItems[0].Id
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        BillingWrappers.ShippingAddress shippingAddress0 = new BillingWrappers.ShippingAddress();
        BillingWrappers.ShippingAddress shippingAddress1 = new BillingWrappers.ShippingAddress();
        BillingWrappers.ShippingItemsInfo shippingItem0 = new BillingWrappers.ShippingItemsInfo();
        BillingWrappers.ShippingItemsInfo shippingItem1 = new BillingWrappers.ShippingItemsInfo();
        BillingWrappers.ShippingLocation shippingLocation0 = new BillingWrappers.ShippingLocation();
        BillingWrappers.ShippingLocation shippingLocation1 = new BillingWrappers.ShippingLocation();

        shippingAddress0.state = 'Nice';
        shippingAddress0.additionalAddressLine = 'null';
        shippingAddress0.addressLine = '10 Avenue Jean Médecin';
        shippingAddress0.city = 'Nice';
        shippingAddress0.country = 'France';
        shippingAddress0.zipCode = '06000';

        shippingAddress1.state = 'CA';
        shippingAddress1.additionalAddressLine = 'null';
        shippingAddress1.addressLine = 'App.723 13 Elm Street';
        shippingAddress1.city = 'Foster City';
        shippingAddress1.country = 'United States';
        shippingAddress1.zipCode = '94404';

        shippingLocation0.id = 'test1';
        shippingLocation0.shippingMethod = 'Ground';
        shippingLocation0.attentionTo = 'testContactFrance';
        shippingLocation0.address = shippingAddress0;
        shippingLocation0.shippingLicensesTree = 'LC_SHP_86:LC_SHIP_244:LC_SHIPT_245';
        shippingLocation0.shippingBillingCodeId = '551600002';

        shippingItem0.location = shippingLocation0;
        shippingItem0.quoteLineItemId = testQuote.QuoteLineItems[0].Id;
        shippingItem0.quantity = 2;
        shippingItem0.locationID = 'test1';
        shippingItem0.isDeleted = false;

        shippingLocation1.id = 'test3';
        shippingLocation1.shippingMethod = 'Ground';
        shippingLocation1.attentionTo = 'testContactUS';
        shippingLocation1.address = shippingAddress1;
        shippingLocation1.shippingLicensesTree = 'LC_SHP_86:LC_SHIP_244:LC_SHIPT_245';
        shippingLocation1.shippingBillingCodeId = '551600002';

        shippingItem1.location = shippingLocation1;
        shippingItem1.quoteLineItemId = testQuote.QuoteLineItems[0].Id;
        shippingItem1.quantity = 4;
        shippingItem1.locationID = 'test3';
        shippingItem1.isDeleted = false;

        BillingWrappers.ParamsShipping paramsDataShipping = new BillingWrappers.ParamsShipping();
        paramsDataShipping.action = 'saveShippingInfo';
        paramsDataShipping.selectedQuoteId = testQuote.Id;
        paramsDataShipping.shippingItemsMap = new Map<String, List<BillingWrappers.ShippingItemsInfo>> {
            LC_HD_141 => new List<BillingWrappers.ShippingItemsInfo> {shippingItem0, shippingItem1}
        };

        Test.startTest();
            Map <String,List<BillingWrappers.ShippingItemsInfo>> shippingData = ShippingService.processShippingData(paramsDataShipping);
        Test.stopTest();

        Assert.areEqual(4, [Select COUNT() FROM CustomAddressAssignments__c], 'CustomAddressAssignment list should have 4 records');
        List<CustomAddressAssignments__c> caas = (List<CustomAddressAssignments__c>) new CustomAddressAssignmentsSelector()
            .selectCustomAddressAssignments()
            .executeQuery();
        for (CustomAddressAssignments__c caa : caas) {
            if (caa.ShippingBillingCodeId__c == '551600002') {
                Assert.areEqual('551600002', caa.ShippingBillingCodeId__c, 'ShippingBillingCodeId must be equal 551600002');
            } else {
                Assert.areEqual('1231414', caa.ShippingBillingCodeId__c, 'ShippingBillingCodeId must be equal 1231414');
            }
            if (caa.ShippingLicenseTree__c == 'LC_SHP_86:LC_SHIP_82:LC_SHIPT_80') {
                Assert.areEqual('LC_SHP_86:LC_SHIP_82:LC_SHIPT_80', caa.ShippingLicenseTree__c, 'ShippingBillingCodeId must be equal "LC_SHP_86:LC_SHIP_82:LC_SHIPT_80"');
            } else {
                Assert.areEqual('LC_SHP_86:LC_SHIP_244:LC_SHIPT_245', caa.ShippingLicenseTree__c, 'ShippingBillingCodeId must be equal "LC_SHP_86:LC_SHIP_244:LC_SHIPT_245"');
            }
        }
        Assert.areEqual(2, [Select COUNT() FROM CustomAddress__c], 'CustomAddress list should have 2 records');
        Assert.areEqual(2, [Select COUNT() FROM CustomAddressAssignments__c WHERE QuoteLineItem__c = :techQli.Id], 'CustomAddress list should have 2 records for Tech line items');
    }

    @IsTest
    private static void testDeleteCustomAddressAssignments() {
        Quote testQuote = getQuoteWithQlis();

        Triggers.switchOff();
        List<CustomAddress__c> ca = (List<CustomAddress__c>) new SObjectBuilder(CustomAddress__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                CustomAddress__c.AddressLine__c => ValueProviderBuilder.provideList(new List<String> {'10 Avenue Jean Médecin', 'App.723 13 Elm Street'}),
                CustomAddress__c.City__c => ValueProviderBuilder.provideList(new List<String> {'Nice', 'Foster City'}),
                CustomAddress__c.Country__c => ValueProviderBuilder.provideList(new List<String> {'France', 'USA'}),
                CustomAddress__c.State__c => ValueProviderBuilder.provideList(new List<String> {'Nice', 'CA'}),
                CustomAddress__c.PostalCode__c => ValueProviderBuilder.provideList(new List<String> {'06000', '94404'})
            })
            .quantity(2)
            .create()
            .getRecords();

        List<CustomAddressAssignments__c> caa = (List<CustomAddressAssignments__c>) new SObjectBuilder(CustomAddressAssignments__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                CustomAddressAssignments__c.AttentionTo__c => ValueProviderBuilder.provideList(new List<String> {'Test France', 'Test USA'}),
                CustomAddressAssignments__c.CustomAddress__c => ValueProviderBuilder.provideList(new List<Id> {ca[0].Id, ca[1].Id}),
                CustomAddressAssignments__c.Quantity__c => ValueProviderBuilder.provideList(new List<Integer> {2, 4}),
                CustomAddressAssignments__c.QuoteLineItem__c => ValueProviderBuilder.provideList(new List<Id> {testQuote.QuoteLineItems[0].Id, testQuote.QuoteLineItems[1].Id}),
                CustomAddressAssignments__c.Type__c => 'Ground',
                CustomAddressAssignments__c.ShippingLicenseTree__c => 'LC_SHP_86:LC_SHIP_82:LC_SHIPT_80'})
            .quantity(4)
            .create()
            .getRecords();
        Triggers.switchOn();

        BillingWrappers.ParamsShipping params = new BillingWrappers.ParamsShipping();
        params.opportunityId = testQuote.OpportunityId;

        Test.startTest();
            ShippingService.deleteCustomAddressAssignments(params);
        Test.stopTest();

        List<CustomAddressAssignments__c> customAddresses = new CustomAddressAssignmentsSelector()
            .selectCustomAddressAssignmentsByOppIds(new List<Id> {testQuote.OpportunityId})
            .executeQuery();

        Assert.isTrue(customAddresses.isEmpty(), 'All custom address assignment should be deleted');
    }

    @isTest
    private static void testCompareCustomAddress() {
        CustomAddress__c customAdress = getFranceCustomAddress();
        BillingWrappers.ShippingAddress equalShippingInfoCustomAddress = getFranceShippingAddress();
        BillingWrappers.ShippingAddress notEqualShippingInfoCustomAddress = getUSAShippingAddress();

        Test.startTest();
            Boolean equalResult = ShippingService.compareCustomAddress(customAdress, equalShippingInfoCustomAddress);
            Boolean notEqualResult = ShippingService.compareCustomAddress(customAdress, notEqualShippingInfoCustomAddress);
        Test.stopTest();

        System.assertEquals(true, equalResult, 'Custom address should be equal');
        System.assertEquals(false, notEqualResult, 'Custom address should not be equal');
    }

    private static CustomAddress__c getFranceCustomAddress() {
        CustomAddress__c customAdress = new CustomAddress__c();
        customAdress.AddressLine__c = '10 Avenue Jean Médecin';
        customAdress.City__c = 'Nice';
        customAdress.Country__c = 'France';
        customAdress.State__c = 'Nice';
        customAdress.PostalCode__c = '06000';
        return customAdress;
    }

    private static BillingWrappers.ShippingAddress getFranceShippingAddress() {
        BillingWrappers.ShippingAddress shippingAddress = new BillingWrappers.ShippingAddress();
        shippingAddress.addressLine = '10 Avenue Jean Médecin';
        shippingAddress.city = 'Nice';
        shippingAddress.country = 'France';
        shippingAddress.state = 'Nice';
        shippingAddress.zipCode = '06000';
        return shippingAddress;
    }

    private static BillingWrappers.ShippingAddress getUSAShippingAddress() {
        BillingWrappers.ShippingAddress shippingAddress = new BillingWrappers.ShippingAddress();
        shippingAddress.addressLine = 'App.723 13 Elm Street';
        shippingAddress.city = 'Foster City';
        shippingAddress.country = 'USA';
        shippingAddress.state = 'CA';
        shippingAddress.zipCode = '94404';
        return shippingAddress;
    }

    static Quote getQuoteWithQlis() {
        return (Quote) new ListOptional(new QuoteSelector()
            .selectQuotes()
            .withoutSelectorFieldsIncluded()
            .selectFields(new Set<SObjectField> {
                Quote.Id,
                Quote.OpportunityId,
                Quote.Name,
                Quote.OpportunityId,
                Quote.Status,
                Quote.Approved_Status__c,
                Quote.Start_Date__c,
                Quote.End_Date__c,
                Quote.RecordTypeId,
                Quote.Pricebook2Id
            })
            .subselect(new QuoteLineItemSelector()
                .selectQuoteLineItems()
                .withoutSelectorFieldsIncluded()
                .selectFields(new Set<SObjectField> {
                    QuoteLineItem.Id,
                    QuoteLineItem.PricebookEntryId,
                    QuoteLineItem.Product2Id
                })
            )
            .executeQuery()
        ).getFirst();
    }
}