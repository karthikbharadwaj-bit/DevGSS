/*
* Name         : SignUpCustomers
* Created By   : Fedor Golovanov (fgolovanov@newmarketinc.com)
* Created Date : 06/March/2016
* Description  : Unit Tests for the B-53 (Sprint 5 Moscow). Refactor SingUp process to use new data model. B-111 (Sprint 7 Moscow) Use old functionality for Pro and Fax Service Plans and Redirect to Old Page.
* Dependencies : SignUpCustomers.cls, GWFunnelWrapper.cls
*/
@isTest
private class Test_SignUpCustomers {
    private static Opportunity opp;
    private static Quote testQuote;
    private static QuoteLineItem testServiceQuoteLineItem;
    private static QuoteLineItem testQuoteLineItem;
    private static List<QuoteLineItem> testQuoteLineItems;

    private static void createTestData() {
        Triggers.switchOff();
        new SObjectBuilder(Sign_Up_Settings__c.SObjectType)
            .setField(Sign_Up_Settings__c.Sign_Up_Link__c,  'http://devorigin101.secure.ringcentral.com/api/projects/ws/index.php')
            .create();

        schedulerConfiguration__c scc = (schedulerConfiguration__c) new SObjectBuilder(schedulerConfiguration__c.SObjectType)
            .setField(schedulerConfiguration__c.Name,  OpportunityHelper.BRAND_RINGCENTRAL)
            .create()
            .getRecord();

        new SObjectBuilder(TierTypeSetting__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                TierTypeSetting__c.Name => '1',
                TierTypeSetting__c.Safid__c => 45611784,
                TierTypeSetting__c.TierType__c => 12,
                TierTypeSetting__c.TierId__c => '999'
            })
            .create();

        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Test Account',
                Account.Number_of_DL_s__c => 10,
                Account.BillingCity => 'TestCity',
                Account.BillingStreet => 'TestStreet',
                Account.Payment_Method__c => 'Invoice',
                Account.SignupType__c => 'Direct'
            })
            .create()
            .getRecord();

        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.AccountId => testAccount.Id,
                Contact.LastName => 'Golovanov',
                Contact.FirstName => 'Fedor',
                Contact.Email => 'fgolovanov@newmarketinc.com'
            })
            .create()
            .getRecord();

        Area_Codes__c areaCode = (Area_Codes__c) new SObjectBuilder(Area_Codes__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Area_Codes__c.Name => '999',
                Area_Codes__c.Area_Code__c => 999,
                Area_Codes__c.City__c => 'TestCity',
                Area_Codes__c.State_Abbreviation__c => 'ST',
                Area_Codes__c.StateID__c => 99
            })
            .create()
            .getRecord();

        PriceBook2 testPriceBook = (PriceBook2) new SObjectBuilder(PriceBook2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PriceBook2.Name => 'Test Price Book',
                PriceBook2.Description => 'Test Price Book Products',
                PriceBook2.Tier_ID__c => '999',
                PriceBook2.Plan__c => 'Annual',
                PriceBook2.IsActive => true,
                PriceBook2.Line_Range_Min__c => 0,
                PriceBook2.Line_Range_Max__c => 10,
                PriceBook2.Service__c => 'Office',
                PriceBook2.Brand__c => scc.Id
            })
            .create()
            .getRecord();

        List<Product2> testProducts = (List<Product2>) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => ValueProviderBuilder.provideUniqueString('Connect Pro - Annual Fee'),
                Product2.IsActive => true,
                Product2.Family => ValueProviderBuilder.provideList(new List<String> {
                    Product2Helper.PRODUCT_OFFICE,
                    Product2Helper.FAMILY_SERVICE
                })
            })
            .quantity(2)
            .create()
            .getRecords();

        List<PricebookEntry> pbeList = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Product2Id => ValueProviderBuilder.provideList(new List<Id> {
                    testProducts[0].Id,
                    testProducts[0].Id,
                    testProducts[1].Id,
                    testProducts[1].Id
                }),
                PricebookEntry.Pricebook2Id => ValueProviderBuilder.provideList(new List<Id> {
                    Test.getStandardPricebookId(),
                    testPriceBook.Id,
                    Test.getStandardPricebookId(),
                    testPriceBook.Id
                }),
                PricebookEntry.UnitPrice => ValueProviderBuilder.provideList(new List<Integer> {
                    50,
                    50,
                    100,
                    100
                }),
                PricebookEntry.Min_Quantity__c => ValueProviderBuilder.provideList(new List<Integer> {
                    null,
                    1,
                    null,
                    1
                }),
                PricebookEntry.Max_Quantity__c => ValueProviderBuilder.provideList(new List<Integer> {
                    null,
                    100,
                    null,
                    100
                }),
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.Per_Line__c => false,
                PricebookEntry.CurrencyIsoCode => 'USD'
            })
            .quantity(4)
            .create()
            .getRecords();

        opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => 'Test Opportunity',
                Opportunity.Type => 'Syndicated - New',
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                Opportunity.CloseDate => system.today(),
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.PriceBook2Id => testPriceBook.Id,
                Opportunity.Primary_Opportunity_Contact__c => testContact.Id,
                Opportunity.Tier_Name__c => '999',
                Opportunity.AccountId => testAccount.Id
            })
            .create()
            .getRecord();

        OpportunityContactRole opcr = (OpportunityContactRole) new SObjectBuilder(OpportunityContactRole.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                OpportunityContactRole.OpportunityId => opp.Id,
                OpportunityContactRole.Role => 'Administrator',
                OpportunityContactRole.IsPrimary => true,
                OpportunityContactRole.ContactId => testContact.Id
            })
            .create()
            .getRecord();

        testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => 'qoutetest',
                Quote.OpportunityId => opp.id,
                Quote.Status => 'Draft',
                Quote.Pricebook2Id => testPriceBook.id,
                Quote.Total_Number_of_Digital_Lines__c => 0,
                Quote.FaxAreaCode__c => areaCode.Id,
                Quote.AreaCode__c => areaCode.Id
            })
            .create()
            .getRecord();

        Package__c testPackage = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Name => 'testPackage',
                Package__c.Account__c => testAccount.Id,
                Package__c.Service_Type__c => 'Office',
                Package__c.SignupType__c => AccountTriggerHelper.SIGN_UP_TYPE_TRIAL_30NOCC,
                Package__c.Account_Package_Id__c => '1111'
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        testQuoteLineItems = new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => testQuote.Id,
                QuoteLineItem.ServiceDate => date.today(),
                QuoteLineItem.Description => ValueProviderBuilder.provideList(new List<String> {
                    'TestLineItem',
                    'TestServiceLineItem'
                }),
                QuoteLineItem.UnitPrice => ValueProviderBuilder.provideList(new List<Decimal> {
                    pbeList[1].UnitPrice,
                    pbeList[3].UnitPrice
                }),
                QuoteLineItem.Product2Id => testProducts[0].Id,
                QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideList(new List<Id> {
                    pbeList[1].Id,
                    pbeList[3].Id
                }),
                QuoteLineItem.Quantity => 5
            })
            .quantity(2)
            .build()
            .getRecords();
    }

    @isTest
    static void testGWFunnelWrapperContactInfoConstructors() {
        GWFunnelWrapper.contactInfo constructor = new GWFunnelWrapper.contactInfo();
        Assert.areEqual(constructor.numberOfLines, 0);
        Assert.areEqual(constructor.firstName, null);
        Assert.areEqual(constructor.lastName, null);
        Assert.areEqual(constructor.email, null);
        Assert.areEqual(constructor.contactPhone, null);
        Assert.areEqual(constructor.companyName, null);
        Assert.areEqual(constructor.location, null);
        Assert.areEqual(constructor.areaCode, null);

        GWFunnelWrapper.contactInfo constructor2 = new GWFunnelWrapper.contactInfo(10, 'TestFirstName', 'TestLastName', 'Test@email.com', '+18009999999', 'TestCompany', 'TestLocation', 222);
        Assert.areEqual(constructor2.numberOfLines, 10);
        Assert.areEqual(constructor2.firstName, 'TestFirstName');
        Assert.areEqual(constructor2.lastName, 'TestLastName');
        Assert.areEqual(constructor2.email, 'Test@email.com');
        Assert.areEqual(constructor2.contactPhone, '+18009999999');
        Assert.areEqual(constructor2.companyName, 'TestCompany');
        Assert.areEqual(constructor2.location, 'TestLocation');
        Assert.areEqual(constructor2.areaCode, 222);
    }

    @isTest
    static void testGWFunnelWrapperMainNumberInfoConstructors() {
        GWFunnelWrapper.mainNumberInfo constructor = new GWFunnelWrapper.mainNumberInfo();
        Assert.areEqual(constructor.paymentType, null);
        Assert.areEqual(constructor.freePrefix, null);
        Assert.areEqual(constructor.areaCode, null);
        Assert.areEqual(constructor.country, null);
        Assert.areEqual(constructor.city, null);

        GWFunnelWrapper.mainNumberInfo constructor2 = new GWFunnelWrapper.mainNumberInfo('Toll Free', '800', 99, 'USA', 'Oakland');
        Assert.areEqual(constructor2.paymentType, 'Toll Free');
        Assert.areEqual(constructor2.freePrefix, '800');
        Assert.areEqual(constructor2.areaCode, 99);
        Assert.areEqual(constructor2.country, 'USA');
        Assert.areEqual(constructor2.city, 'Oakland');
    }

    @isTest
    static void testGWFunnelWrapperFaxNumberInfoConstructors() {
        GWFunnelWrapper.faxNumberInfo constructor = new GWFunnelWrapper.faxNumberInfo();
        Assert.areEqual(constructor.paymentType, null);
        Assert.areEqual(constructor.country, null);
        Assert.areEqual(constructor.city, null);
        Assert.areEqual(constructor.areaCode, null);
        Assert.areEqual(constructor.freePrefix, null);

        GWFunnelWrapper.faxNumberInfo constructor2 = new GWFunnelWrapper.faxNumberInfo('Toll Free', '800', 99, 'USA', 'Oakland' );
        Assert.areEqual(constructor2.paymentType, 'Toll Free');
        Assert.areEqual(constructor2.freePrefix, '800');
        Assert.areEqual(constructor2.areaCode, 99);
        Assert.areEqual(constructor2.country, 'USA');
        Assert.areEqual(constructor2.city, 'Oakland');
    }

    @isTest
    static void testGWFunnelWrapperSalesAgentInfoConstructors() {
        GWFunnelWrapper.salesAgentInfo constructor = new GWFunnelWrapper.salesAgentInfo();
        Assert.areEqual(constructor.salesAgentId, null);
        Assert.areEqual(constructor.name, null);

        GWFunnelWrapper.salesAgentInfo constructor2 = new GWFunnelWrapper.salesAgentInfo('999', 'TestName');
        Assert.areEqual(constructor2.salesAgentId, '999');
        Assert.areEqual(constructor2.name, 'TestName');
    }

    @isTest
    static void testGWFunnelWrapperLinesInfoConstructors() {
        GWFunnelWrapper.linesInfo constructor = new GWFunnelWrapper.linesInfo();
        Assert.areEqual(constructor.qty, 0);
        Assert.areEqual(constructor.phoneNumberInfo.areaCode, null);
        Assert.areEqual(constructor.phoneNumberInfo.country, null);
        Assert.areEqual(constructor.phoneNumberInfo.city, null);
        Assert.areEqual(constructor.deviceTypeInfo.id, null);
        Assert.areEqual(constructor.deviceTypeInfo.purchaseType, null);
        Assert.areEqual(constructor.digitalLineType, null);

        GWFunnelWrapper.linesInfo constructor2 = new GWFunnelWrapper.linesInfo(10, 99, 'TestCountry', 'TestCity', 'TestId', 'DirectPurchase', 'TestLineType');
        Assert.areEqual(constructor2.qty, 10);
        Assert.areEqual(constructor2.phoneNumberInfo.areaCode, 99);
        Assert.areEqual(constructor2.phoneNumberInfo.country, 'TestCountry');
        Assert.areEqual(constructor2.phoneNumberInfo.city, 'TestCity');
        Assert.areEqual(constructor2.deviceTypeInfo.id, 'TestId');
        Assert.areEqual(constructor2.deviceTypeInfo.purchaseType, 'DirectPurchase');
        Assert.areEqual(constructor2.digitalLineType, 'TestLineType');
    }

    @isTest
    static void testGWFunnelWrapperGWFunnelWrapperConstructors() {
        GWFunnelWrapper constructor = new GWFunnelWrapper();
        Assert.areEqual(constructor.contactInfo, null);
        Assert.areEqual(constructor.accountNumbers, null);
        Assert.areEqual(constructor.salesAgentInfo, null);
        Assert.areEqual(constructor.additionalNumbers, null);
        Assert.areEqual(constructor.shippingGroups, null);
        Assert.areEqual(constructor.billingCodeGroups, null);

        GWFunnelWrapper constructor2 = new GWFunnelWrapper(
            new GWFunnelWrapper.contactInfo(),
            new GWFunnelWrapper.accountNumbersInfo(),
            new GWFunnelWrapper.salesAgentInfo(),
            new List<GWFunnelWrapper.additionalNumbersInfo>(),
            new List<GWFunnelWrapper.shippingGroupInfo>(),
            new Map<String, GWFunnelWrapper.billingCodeGroupsInfo>(),
            new List<GWFunnelWrapper.linesInfo>()
        );
        Assert.areEqual(constructor2.contactInfo.numberOfLines, 0);
        Assert.areEqual(constructor2.salesAgentInfo.salesAgentId, null);
        Assert.areEqual(constructor2.additionalNumbers.size(), 0);
        Assert.areEqual(constructor2.shippingGroups.size(), 0);
        Assert.areEqual(constructor2.billingCodeGroups.size(), 0);
        Assert.areEqual(constructor2.lines.size(), 0);
    }

    @isTest
    static void testGWFunnelWrapperShippingGroupInfoConstructors() {
        GWFunnelWrapper.shippingGroupInfo constructor = new GWFunnelWrapper.shippingGroupInfo();
        Assert.areEqual(constructor.shippingAddress, null);
        Assert.areEqual(constructor.involvedLinesUids, null);

        GWFunnelWrapper.shippingGroupInfo constructor2 = new GWFunnelWrapper.shippingGroupInfo(new GWFunnelWrapper.shippingData(), new Map<String, Integer>());
        Assert.areEqual(constructor.shippingAddress, null);
        Assert.areEqual(constructor.involvedLinesUids, null);
    }

    @isTest
    static void testGWFunnelWrapperParamWrapperConstructor() {
        GWFunnelWrapper.paramWrapper constructor = new GWFunnelWrapper.paramWrapper();
        Assert.areEqual(constructor.SAFID, null);
        Assert.areEqual(constructor.SPID, null);
    }

    @isTest
    static void testGWFunnelWrapperResponseWrapperConstructors() {
        GWFunnelWrapper.ResponseWrapper constructor = new GWFunnelWrapper.ResponseWrapper();
        Assert.areEqual(constructor.URL, null);
        Assert.areEqual(constructor.OPPID, null);
        Assert.areEqual(constructor.SALESAGENTID, null);
        Assert.areEqual(constructor.GWAPISID, null);

        GWFunnelWrapper.ResponseWrapper constructor2 = new GWFunnelWrapper.ResponseWrapper('TestURL', '999', 'TestSAID', 'GWAPISID');
        Assert.areEqual(constructor2.URL, 'TestURL');
        Assert.areEqual(constructor2.OPPID, '999');
        Assert.areEqual(constructor2.SALESAGENTID, 'TestSAID');
        Assert.areEqual(constructor2.GWAPISID, 'GWAPISID');
    }

    @isTest
    static void testGWFunnelWrapperAdditionalNumbersInfoConstructors() {
        GWFunnelWrapper.additionalNumbersInfo constructor = new GWFunnelWrapper.additionalNumbersInfo();
        Assert.areEqual(constructor.paymentType, null);
        Assert.areEqual(constructor.freePrefix, null);
        Assert.areEqual(constructor.qty, 0);
        Assert.areEqual(constructor.areaCode, null);
        Assert.areEqual(constructor.city, null);
        Assert.areEqual(constructor.country, null);
        Assert.areEqual(constructor.itemUids, null);

        GWFunnelWrapper.additionalNumbersInfo constructor2 = new GWFunnelWrapper.additionalNumbersInfo('Direct', '800', 10, '99', 'TestCity', 'TestCountry', new Map<String, Integer>{'TestUiD' => 0});
        Assert.areEqual(constructor2.paymentType, 'Direct');
        Assert.areEqual(constructor2.freePrefix, '800');
        Assert.areEqual(constructor2.qty, 10);
        Assert.areEqual(constructor2.areaCode, '99');
        Assert.areEqual(constructor2.city, 'TestCity');
        Assert.areEqual(constructor2.country, 'TestCountry');
        Assert.areEqual(constructor2.itemUids, new Map<String, Integer> {'TestUiD' => 0});
    }

    @isTest
    static void testGWFunnelWrapperShippingDataConstructors() {
        GWFunnelWrapper.shippingData constructor = new GWFunnelWrapper.shippingData();
        Assert.areEqual(constructor.shippingId, null);
        Assert.areEqual(constructor.firstName, null);
        Assert.areEqual(constructor.lastName, null);
        Assert.areEqual(constructor.companyName, null);
        Assert.areEqual(constructor.addressLine1, null);
        Assert.areEqual(constructor.country, null);
        Assert.areEqual(constructor.state, null);
        Assert.areEqual(constructor.city, null);
        Assert.areEqual(constructor.zipCode, null);

        GWFunnelWrapper.shippingData constructor2 = new GWFunnelWrapper.shippingData('999', 'TestFirstName', 'TestLastName', 'TestCompanyName', 'TestAddressLine', 'TestCountry','TestState', 'TestCity', 'TestZipCode');
        Assert.areEqual(constructor2.shippingId, '999');
        Assert.areEqual(constructor2.firstName, 'TestFirstName');
        Assert.areEqual(constructor2.lastName, 'TestLastName');
        Assert.areEqual(constructor2.companyName, 'TestCompanyName');
        Assert.areEqual(constructor2.addressLine1, 'TestAddressLine');
        Assert.areEqual(constructor2.country, 'TestCountry');
        Assert.areEqual(constructor2.state, 'TestState');
        Assert.areEqual(constructor2.city, 'TestCity');
        Assert.areEqual(constructor2.zipCode, 'TestZipCode');
    }

    @isTest
    static void testGWFunnelWrapperAccountNumbersInfoConstructors() {
        GWFunnelWrapper.accountNumbersInfo constructor = new GWFunnelWrapper.accountNumbersInfo();
        Assert.areEqual(constructor.mainNumber, null);

        GWFunnelWrapper.accountNumbersInfo constructor2 = new GWFunnelWrapper.accountNumbersInfo(
            new GWFunnelWrapper.mainNumberInfo()
        );
        Assert.areEqual(constructor2.mainNumber.areaCode, null);

        // With Fax Area Code Number
        GWFunnelWrapper.accountNumbersInfoWithFax constructor3 = new GWFunnelWrapper.accountNumbersInfoWithFax();
        Assert.areEqual(constructor3.mainNumber, null);
        Assert.areEqual(constructor3.faxNumber, null);

        GWFunnelWrapper.accountNumbersInfoWithFax constructor4 = new GWFunnelWrapper.accountNumbersInfoWithFax(
            new GWFunnelWrapper.mainNumberInfo(),
            new GWFunnelWrapper.faxNumberInfo()
        );
        Assert.areEqual(constructor4.mainNumber.areaCode, null);
        Assert.areEqual(constructor4.faxNumber.areaCode, null);
    }

    @isTest
    static void testGWFunnelWrapperBillingCodeGroupsInfoConstructors() {
        GWFunnelWrapper.billingCodeGroupsInfo constructor = new GWFunnelWrapper.billingCodeGroupsInfo();
        Assert.areEqual(constructor.bcgKey, null);
        Assert.areEqual(constructor.name, null);
        Assert.areEqual(constructor.parentBCGId, null);
        Assert.areEqual(constructor.childBCGIds, null);
        Assert.areEqual(constructor.shippingGroupsItemUids, null);
        Assert.areEqual(constructor.linesItemUids, null);
        Assert.areEqual(constructor.additionalNumbersItemUids, null);

        GWFunnelWrapper.billingCodeGroupsInfo constructor2 = new GWFunnelWrapper.billingCodeGroupsInfo('TestKey', 'TestName', 'TestBCGId', new Map<String, String> {'0' => '1'},
            new Map<String, Integer> {'0' => 1}, new Map<String, Integer> {'0' => 2}, new Map<String, Integer> {'0' => 3}
        );
        Assert.areEqual(constructor2.bcgKey, 'TestKey');
        Assert.areEqual(constructor2.name, 'TestName');
        Assert.areEqual(constructor2.parentBCGId, 'TestBCGId');
        Assert.areEqual(constructor2.childBCGIds, new Map<String, String> {'0' => '1'});
        Assert.areEqual(constructor2.shippingGroupsItemUids, new Map<String, Integer> {'0' => 1});
        Assert.areEqual(constructor2.linesItemUids, new Map<String, Integer> {'0' => 2});
        Assert.areEqual(constructor2.additionalNumbersItemUids, new Map<String, Integer> {'0' => 3});
    }

    @isTest
    static void testGWFunnelWrapperCreateJSONRequest() {
        createTestData();

        Test.startTest();
        GWFunnelWrapper.paramWrapper wrapper = new GWFunnelWrapper.paramWrapper();
        wrapper.SAFID = '45611784';
        wrapper.SPID = '111';
        wrapper.PARTNERID = null;
        wrapper.OPPID = opp.Id;
        wrapper.PID = '111';
        wrapper.TIERTYPE = '14';
        wrapper.OID = '111';
        wrapper.Qty_lines = 10;
        wrapper.Sa_lines = 10;
        wrapper.billtype = 'STR_CREDITCARD';
        wrapper.firstName = 'Fedor';
        wrapper.lastName = 'Golovanov';
        wrapper.email = 'folovanov@newmarketinc.com';
        wrapper.phone = '+78001234567';
        wrapper.companyName = 'Aquivalabs';
        wrapper.numberOfLines = '10';
        wrapper.mainAreaCode = 205;
        wrapper.shouldIncludeFaxAreaCode = true;
        wrapper.faxAreaCode = 205;
        wrapper.mainAreaCodePaymentType = 'Direct';
        wrapper.faxAreaCodePaymentType = 'Direct';
        wrapper.mainAreaFreePrefix = '205';
        wrapper.faxAreaFreePrefix = '205';
        wrapper.freePrefix = '800';
        wrapper.faxAreaCity = 'Moscow';
        wrapper.tierId = '14';
        wrapper.approvalId = String.ValueOf(Quote.Id);
        wrapper.salesAgentId = null;
        wrapper.salesAgentName = null;
        wrapper.purchaseType = null;
        wrapper.qty = 1;
        wrapper.lineItemsList = testQuoteLineItems;
        wrapper.shippingZipCode = '100500';
        wrapper.shippingState = 'CA';
        wrapper.involvedLinesUids = new List<String>{'0','1','2'};
        wrapper.shippingCity = 'San Francisco';
        wrapper.shippingAddressLine1 = '100500 Adress Line 1';
        wrapper.accountName = 'Ring Central';
        GWFunnelWrapper gw = new GWFunnelWrapper();
        Assert.isTrue(gw.createJSONRequest(wrapper).length() > 0);
        Test.stopTest();
    }

    @isTest
    static void testSignUpCustomersGetOpptyRecord() {
        createTestData();

        Test.startTest();
            SignUpCustomers.proccessData(opp.Id);
            Opportunity testOpp = SignUpCustomers.opp;
            Assert.areEqual(testOpp.Id, opp.Id);
            Assert.areEqual(testOpp.Name, opp.Name);
            Assert.areEqual(testOpp.PriceBook2Id, opp.PriceBook2Id);
            Assert.areEqual(testOpp.AccountId, opp.AccountId);
            Assert.isTrue(testOpp.Quotes.size() == 1);
            Assert.areEqual(testOpp.OpportunityContactRoles.size(), 1);
        Test.stopTest();
    }

    @isTest
    static void testSignUpCustomersUpsertFunnelStatus() {
        createTestData();
        testQuote.isPrimary__c = true;
        update testQuote;
        Test.startTest();
        SignUpCustomers.proccessData(opp.Id);
        Assert.isTrue([SELECT Id FROM SalesFunnelStatus__c WHERE Opportunity__c=:opp.Id AND Sales_Agent__c =: UserInfo.getUserId()].size() > 0);
        Test.stopTest();
    }

    @isTest
    static void testSignUpCustomersFindTierTypeByTierId() {
        Test.startTest();
        new SObjectBuilder(TierTypeSetting__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                TierTypeSetting__c.Name => '1',
                TierTypeSetting__c.Safid__c => 45611784,
                TierTypeSetting__c.TierType__c => 16,
                TierTypeSetting__c.TierId__c => '4800'
            })
            .create();

        Map <String, String> map1 = SignUpCustomers.getTierTypeAndSAFIDByTierId('4800');
        Assert.areEqual(map1.get('TierType'), '16');
        Assert.areEqual(map1.get('SAFID'), '45611784');
        Test.stopTest();
    }

    @isTest
    static void testSignUpRestrictions() {
        createTestData();

        Test.startTest();

        Triggers.switchOff();

        Integer feature17FunnelLimit = 5000;

        new SObjectBuilder(Supported_In_Funnel__c.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Supported_In_Funnel__c.Name => ValueProviderBuilder.provideList(new List<String> {
                    '1', '2', '3', '4', '5', '6', '7', '8'
                }),
                Supported_In_Funnel__c.Feature__c => ValueProviderBuilder.provideList(new List<String> {
                    '2', '3', '4', '5', '17', '28', '11,34,39', '11'
                }),
                Supported_In_Funnel__c.Family__c => ValueProviderBuilder.provideList(new List<String> {
                    'any',
                    'any',
                    'any',
                    'any',
                    'Service',
                    'Service',
                    'Discounted Phones, RentalPhones, Refurbished Phones',
                    'Common Phones'
                }),
                Supported_In_Funnel__c.SubFeature__c => 'any',
                Supported_In_Funnel__c.Funnel_Limitation__c => ValueProviderBuilder.provideList(new List<String> {
                    null, null, null, null, String.valueOf(feature17FunnelLimit), null, String.valueOf(feature17FunnelLimit), '50'
                })
            })
            .quantity(8)
            .create();

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => ValueProviderBuilder.provideUniqueString('test discounted product'),
                Product2.IsActive => true,
                Product2.Feature__c => 11,
                Product2.Family => Product2Helper.FAMILY_DISCOUNTED_PHONES
            })
            .create()
            .getRecord();

        List<PricebookEntry> pbeList = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Product2Id => testProduct.Id,
                PricebookEntry.Pricebook2Id => ValueProviderBuilder.provideList(new List<Id> {
                    Test.getStandardPricebookId(),
                    testQuote.Pricebook2Id
                }),
                PricebookEntry.UnitPrice => 50,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .quantity(2)
            .create()
            .getRecords();

        // Account.Funnel_not_supported__c will be filled only if we have Quote.isPrimary__c = true && Quote.Total_Number_of_Digital_Lines__c > Funnel limit value for Fature 17 Service product(5000)
        testQuote.Total_Number_of_Digital_Lines__c = feature17FunnelLimit + 1;
        testQuote.isPrimary__c = true;
        update testQuote;

        new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => testQuote.Id,
                QuoteLineItem.UnitPrice => pbeList[1].UnitPrice,
                QuoteLineItem.Product2Id => testProduct.Id,
                QuoteLineItem.PricebookEntryId => pbeList[1].Id,
                QuoteLineItem.Quantity => feature17FunnelLimit + 1
            })
            .create();

        Triggers.switchOn();

        SignUpCustomers.proccessData(opp.Id);

        Test.stopTest();

        Account acc = [select Id, Funnel_not_supported__c from Account where Id = : opp.AccountId];

        Assert.isTrue(acc.Funnel_not_supported__c != null);
        Assert.isTrue(acc.Funnel_not_supported__c.contains(testProduct.Name));
    }

    @isTest
    static void testproductsWithEmptyFeatureAndSubFeature() {
        createTestData();

        Test.startTest();

        Triggers.switchOff();

        new SObjectBuilder(Supported_In_Funnel__c.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Supported_In_Funnel__c.Name => '1',
                Supported_In_Funnel__c.Family__c => 'any'
            })
            .create();

        List<Product2> productList = new List<Product2>();

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => ValueProviderBuilder.provideUniqueString('test discounted product'),
                Product2.IsActive => true,
                Product2.Family => Product2Helper.FAMILY_DISCOUNTED_PHONES
            })
            .create()
            .getRecord();

        List<PricebookEntry> pbeList = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Product2Id => testProduct.Id,
                PricebookEntry.Pricebook2Id => ValueProviderBuilder.provideList(new List<Id> {
                    Test.getStandardPricebookId(),
                    testQuote.Pricebook2Id
                }),
                PricebookEntry.UnitPrice => 50,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .quantity(2)
            .create()
            .getRecords();

        // Account.Funnel_not_supported__c will be filled only if we have Quote.isPrimary__c = true && Quote.Total_Number_of_Digital_Lines__c > 500
        testQuote.Total_Number_of_Digital_Lines__c = 501;
        testQuote.isPrimary__c = true;
        update testQuote;

        new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => testQuote.Id,
                QuoteLineItem.UnitPrice => pbeList[1].UnitPrice,
                QuoteLineItem.Product2Id => testProduct.Id,
                QuoteLineItem.PricebookEntryId => pbeList[1].Id,
                QuoteLineItem.Quantity => 540
            })
            .create();

        Triggers.switchOn();

        SignUpCustomers.proccessData(opp.Id);

        Test.stopTest();

        Account acc = [select Id, Funnel_not_supported__c from Account where Id = : opp.AccountId];

        Assert.isTrue(acc.Funnel_not_supported__c == null);
    }

    @isTest
    static void testHotDescingProductFunnelNotSupported() {
        createTestData();

        Test.startTest();

        Triggers.switchOff();

        Integer commonPhonesFunnelLimit = 50;
        Integer feature17FunnelLimit = 5000;

        new SObjectBuilder(Supported_In_Funnel__c.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Supported_In_Funnel__c.Name => ValueProviderBuilder.provideList(new List<String> {'1', '2'}),
                Supported_In_Funnel__c.Feature__c => ValueProviderBuilder.provideList(new List<String> {'11', '17'}),
                Supported_In_Funnel__c.Family__c => ValueProviderBuilder.provideList(new List<String> {'Common Phones', 'Service'}),
                Supported_In_Funnel__c.SubFeature__c => 'any',
                Supported_In_Funnel__c.Funnel_Limitation__c => ValueProviderBuilder.provideList(new List<String> {
                    String.valueOf(commonPhonesFunnelLimit), String.valueOf(feature17FunnelLimit)
                })
            })
            .quantity(2)
            .create();

        List<Product2> prodList =  new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => ValueProviderBuilder.provideList(new List<String> {
                    'test common phone', 'test DigitalLine Hot Desking'
                }),
                Product2.IsActive => true,
                Product2.Feature__c => ValueProviderBuilder.provideList(new List<Integer> { 11, 50 }),
                Product2.Family => ValueProviderBuilder.provideList(new List<String> {'Common Phones', 'Add - Ons'})
            })
            .quantity(2)
            .create()
            .getRecords();

        List<PricebookEntry> pbeList = new List<PricebookEntry>();
        for(Product2 product : prodList) {
            PricebookEntry standartPrice = new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = product.Id,
                UnitPrice = 50,
                IsActive = true,
                UseStandardPrice = false
            );
            pbeList.add(standartPrice);

            PricebookEntry myPrice = new PricebookEntry(
                Pricebook2Id = testQuote.Pricebook2Id,
                Product2Id = product.Id,
                UnitPrice = 50,
                IsActive = true,
                UseStandardPrice = false
            );
            pbeList.add(myPrice);
        }

        insert pbeList;

        // Account.Funnel_not_supported__c will be filled only if we have Quote.isPrimary__c = true && Quote.Total_Number_of_Digital_Lines__c > Funnel limit value for Fature 17 Service product(5000)
        testQuote.Total_Number_of_Digital_Lines__c = feature17FunnelLimit + 1;
        testQuote.isPrimary__c = true;
        update testQuote;

        Integer qliQuantity = 60;
        List<QuoteLineItem> qliList = new List<QuoteLineItem>();
        for(PricebookEntry pbe : pbeList) {
            if(pbe.Pricebook2Id == testQuote.Pricebook2Id) {
                QuoteLineItem qli = new QuoteLineItem(
                    UnitPrice = pbe.UnitPrice,
                    Product2Id = pbe.Product2Id,
                    PriceBookEntryId = pbe.Id,
                    Quantity = qliQuantity,
                    QuoteId = testQuote.Id
                );

                qliList.add(qli);
            }
        }

        insert qliList;
        Triggers.switchOn();

        SignUpCustomers.proccessData(opp.Id);

        Test.stopTest();

        Account acc = [select Id, Funnel_not_supported__c from Account where Id = : opp.AccountId];

        Assert.isTrue(acc.Funnel_not_supported__c != null);
        Assert.isTrue(acc.Funnel_not_supported__c.contains(prodList[0].Name));
        Assert.isTrue(acc.Funnel_not_supported__c.contains(prodList[1].Name));

        List<String> splitted = acc.Funnel_not_supported__c.split('\n\n\n');
        for(String item : splitted) {
            String productInfo = item.split('Product Name:')[1];
            List<String> splittedInfo = productInfo.split('\n');
            String productName = splittedInfo[0];
            String productQuantityStr = splittedInfo[3];
            Integer productQuantity = Integer.valueOf( productQuantityStr.split(':')[1].trim() );

            if(productName.contains(prodList[0].Name) || productName.contains(prodList[1].Name)) {
                Assert.isTrue(productQuantity == (qliQuantity - commonPhonesFunnelLimit));
            }
        }
    }

    @isTest
    static void testProccessDataRedirectSignUpVARFaxOrEnterprise() {
        Triggers.switchOff();
        PriceBook2 testPriceBook = (PriceBook2) new SObjectBuilder(PriceBook2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PriceBook2.Name => 'Test Price Book',
                PriceBook2.Plan__c => 'Annual',
                PriceBook2.IsActive => true,
                PriceBook2.Line_Range_Min__c => 0,
                PriceBook2.Line_Range_Max__c => 10,
                PriceBook2.Service__c => OpportunityHelper.TIER_OFFICE
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => 'Test Opportunity',
                Opportunity.CloseDate => System.today(),
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_ATOS,
                Opportunity.PriceBook2Id => testPriceBook.Id,
                Opportunity.RecordTypeId => OpportunityHelper.RT_ID_VAR_OPPORTUNITY
            })
            .create()
            .getRecord();

        new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => 'Test Quote',
                Quote.OpportunityId => opp.Id,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.Pricebook2Id => testPriceBook.Id
            })
            .create();
        Triggers.switchOn();

        Test.startTest();
            String redirectURL = SignUpCustomers.proccessData(opp.Id);
        Test.stopTest();

        final String signUpVARFaxURL = '/apex/SignUpCustomer?id=' + opp.Id + '&scontrolCaching=1';

        Assert.areEqual(signUpVARFaxURL, redirectURL, 'Redirect URL should be the same');
    }

    @isTest
    static void testProccessDataRedirectSignUpFaxOrEnterprise() {
        Triggers.switchOff();
        PriceBook2 testPriceBook = (PriceBook2) new SObjectBuilder(PriceBook2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PriceBook2.Name => 'Test Price Book',
                PriceBook2.Plan__c => 'Annual',
                PriceBook2.IsActive => true,
                PriceBook2.Line_Range_Min__c => 0,
                PriceBook2.Line_Range_Max__c => 10,
                PriceBook2.Service__c => OpportunityHelper.TIER_ENGAGE_DIGITAL_STANDALONE
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => 'Test Opportunity',
                Opportunity.CloseDate => System.today(),
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.PriceBook2Id => testPriceBook.Id,
                Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY
            })
            .create()
            .getRecord();

        new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => 'Test Quote',
                Quote.OpportunityId => opp.Id,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.Pricebook2Id => testPriceBook.Id
            })
            .create();
        Triggers.switchOn();

        Test.startTest();
            String redirectURL = SignUpCustomers.proccessData(opp.Id);
        Test.stopTest();

        final String signUpFaxURL = '/apex/SignUpLinksDemo?id=' + opp.Id + '&newModel=true&scontrolCaching=1';

        Assert.areEqual(signUpFaxURL, redirectURL, 'Redirect URL should be the same');
    }

    @isTest
    static void testSetSignUpParams() {
        User marketingUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(User.SObjectType))
            .setFields(new Map<SObjectField, Object> {
                User.UserPermissionsMarketingUser => true,
                User.UserName => 'marketingUser@user.com'
            })
            .create()
            .getRecord();

        Triggers.switchOff();
        List<Campaign> camps;
        System.runAs(marketingUser) {
            camps = (List<Campaign>) new SObjectBuilder(Campaign.sObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Campaign.IsActive => true,
                    Campaign.Name => 'Test Camp',
                    Campaign.BMID__c => ValueProviderBuilder.provideList(new List<String> {null, null, '3', '4'}),
                    Campaign.AID__c => ValueProviderBuilder.provideList(new List<String> {'1', '2', '3', '4'}),
                    Campaign.PID__c => ValueProviderBuilder.provideList(new List<String> {null, '2', '3', null})
                })
                .quantity(4)
                .create()
                .getRecords();
        }
        Triggers.switchOn();

        List<Opportunity> opps = (List<Opportunity>) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => 'Test Name',
                Opportunity.CampaignId => ValueProviderBuilder.provideList(new List<Id> {null, null, null, camps[0].Id, camps[1].Id, camps[2].Id, camps[3].Id}),
                Opportunity.CloseDate => System.today(),
                Opportunity.Partner_ID__c => ValueProviderBuilder.provideList(new List<String> {'Test Partner ID', null, null, null, null, null, null}),
                Opportunity.BMID__c => ValueProviderBuilder.provideList(new List<String> {'1', '2', null, null, null, null, null}),
                Opportunity.PID__c => ValueProviderBuilder.provideList(new List<String> {'1', null, '3', null, null, null, null}),
                Opportunity.AID__c => ValueProviderBuilder.provideList(new List<String> {'1', '2', '3', null, null, null, null})
            })
            .quantity(7)
            .build()
            .getRecords();

        SignUpCustomers.opp = opps[0];
        SignUpCustomers.setSignUpParams();
        Assert.areEqual(opps[0].Partner_ID__c, SignUpCustomers.partnerID, 'The Partner_ID__c field should have the same value');
        Assert.areEqual(opps[0].BMID__c, SignUpCustomers.BMID, 'The BMID__c field should have the same value');
        Assert.areEqual(opps[0].PID__c, SignUpCustomers.PID, 'The PID__c field should have the same value');
        Assert.areEqual(opps[0].AID__c, SignUpCustomers.AID, 'The AID__c field should have the same value');

        SignUpCustomers.opp = opps[1];
        SignUpCustomers.setSignUpParams();
        Assert.areEqual(opps[1].BMID__c, SignUpCustomers.BMID, 'The BMID__c field should have the same value');
        Assert.isTrue(String.isBlank(SignUpCustomers.PID), 'The PID__c field should be blank');
        Assert.areEqual(opps[1].AID__c, SignUpCustomers.AID, 'The AID__c field should have the same value');

        SignUpCustomers.opp = opps[2];
        SignUpCustomers.setSignUpParams();
        Assert.areEqual(opps[2].PID__c, SignUpCustomers.BMID, 'The BMID__c field should have PID value');
        Assert.isTrue(String.isBlank(SignUpCustomers.PID), 'The PID__c field should be blank');
        Assert.areEqual(opps[2].AID__c, SignUpCustomers.AID, 'The AID__c field should have the same value');

        SignUpCustomers.opp = opps[3];
        SignUpCustomers.setSignUpParams();
        Assert.isTrue(String.isBlank(SignUpCustomers.BMID), 'The BMID field should be blank');
        Assert.isTrue(String.isBlank(SignUpCustomers.PID), 'The PID field should be blank');
        Assert.areEqual(camps[0].AID__c, SignUpCustomers.AID, 'The AID field should have the same value');

        SignUpCustomers.opp = opps[4];
        SignUpCustomers.setSignUpParams();
        Assert.areEqual(camps[1].AID__c, SignUpCustomers.AID, 'The AID field should have the same value');
        Assert.areEqual(camps[1].PID__c, SignUpCustomers.BMID, 'The BMID field should have PID value');
        Assert.areEqual(camps[1].PID__c, SignUpCustomers.PID, 'The PID field should have the same value');

        SignUpCustomers.opp = opps[5];
        SignUpCustomers.setSignUpParams();
        Assert.areEqual(camps[2].AID__c, SignUpCustomers.AID, 'The AID field should have the same value');
        Assert.areEqual(camps[2].BMID__c, SignUpCustomers.BMID, 'The BMID field should have the same value');
        Assert.areEqual(camps[2].PID__c, SignUpCustomers.PID, 'The PID field should have the same value');

        SignUpCustomers.opp = opps[6];
        SignUpCustomers.setSignUpParams();
        Assert.areEqual(camps[3].AID__c, SignUpCustomers.AID, 'The AID field should have the same value');
        Assert.areEqual(camps[3].BMID__c, SignUpCustomers.BMID, 'The BMID field should have the same value');
        Assert.isTrue(String.isBlank(SignUpCustomers.PID), 'The PID field should be blank');
    }

    @isTest
    static void testPopulateSType() {
        final String trial30Type = 'trial30';
        final String trial15Type = 'trial15';
        final String buyType = 'buy';
        final String trial30NoCC = 'trial_30nocc';

        String sType1 = SignUpCustomers.populateStype('Test trial_30cc');
        Assert.areEqual(trial30Type, sType1, 'SType should have the same value');

        String sType2 = SignUpCustomers.populateStype('Test trial_30');
        Assert.areEqual(buyType, sType2, 'SType should have the same value');

        String sType3 = SignUpCustomers.populateStype('Test trial_15nocc');
        Assert.areEqual(trial15Type, sType3, 'SType should have the same value');

        String sType4 = SignUpCustomers.populateStype('Test trial_15cc');
        Assert.areEqual(trial15Type, sType4, 'SType should have the same value');

        String sType5 = SignUpCustomers.populateStype('Test trial_15');
        Assert.areEqual(buyType, sType5, 'SType should have the same value');

        String sType6 = SignUpCustomers.populateStype('Test trial_50nocc');
        Assert.areEqual(trial30NoCC, sType6, 'SType should have the same value');

        String sType7 = SignUpCustomers.populateStype('Test trial_50cc');
        Assert.areEqual(trial30Type, sType7, 'SType should have the same value');

        String sType8 = SignUpCustomers.populateStype('Test trial_50');
        Assert.areEqual(buyType, sType8, 'SType should have the same value');

        String sType9 = SignUpCustomers.populateStype(null);
        Assert.areEqual(buyType, sType9, 'SType should have the same value');
    }

    @isTest
    static void testGetPaymentType() {
        String paymentType1 = SignUpCustomers.getPaymentType('Local', true);
        Assert.areEqual('Vanity', paymentType1, 'Payment type should be Vanity');

        String paymentType2 = SignUpCustomers.getPaymentType('-Local-', false);
        Assert.areEqual('Local', paymentType2, 'Payment type should be Vanity');
    }
}