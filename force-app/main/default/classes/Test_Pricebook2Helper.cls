@IsTest
private class Test_Pricebook2Helper {

    @isTest
    private static void testIsFaxService() {
        Boolean result;

        Test.startTest();
        result = Pricebook2Helper.isFaxService(Pricebook2Helper.SERVICE_FAX);
        Test.stopTest();

        System.assert(
            result,
            'Method should return true for fax service'
        );
    }

    @isTest
    private static void testIsProfessionalService() {
        Boolean result;

        Test.startTest();
        result = Pricebook2Helper.isProfessionalService(null);
        Test.stopTest();

        System.assert(
            !result,
            'Method should return false for null service'
        );
    }

    @isTest
    private static void testIsGoogleAppsEdition() {
        Boolean result;

        Test.startTest();
        result = Pricebook2Helper.isGoogleAppsEdition(Pricebook2Helper.EDITION_STANDARD);
        Test.stopTest();

        System.assert(
            !result,
            'Method should return false for standard edition'
        );
    }

    @isTest
    private static void testIsRingCentralBrandName() {
        Boolean result;

        Test.startTest();
        result = Pricebook2Helper.isRingCentralBrandName(Pricebook2Helper.BRAND_RINGCENTRAL);
        Test.stopTest();

        System.assert(
            result,
            'Method should return true for ringcentral brand'
        );
    }

    @isTest
    private static void testIsRingCentralCanadaBrand() {
        Boolean result;

        Test.startTest();
        result = Pricebook2Helper.isRingCentralCanadaBrand(Pricebook2Helper.BRAND_RINGCENTRAL_CANADA);
        Test.stopTest();

        System.assert(
            result,
            'Method should return true for ringcentral canada brand'
        );
    }

    @isTest
    private static void testStandardPricebookShouldThrowException() {

        Boolean result = false;

        try {
            Pricebook2 standardPricebook = Pricebook2Helper.standardPricebook;
        } catch (Exception e) {
            result = true;
        }

        System.assert(
            result,
            'Method should return exception'
        );
    }

    @isTest
    private static void testGetStandardPricebookId() {

        Id pbId;

        Test.startTest();
        pbId = Pricebook2Helper.getStandardPricebookId();
        Test.stopTest();

        System.assert(
            pbId != null,
            'Method should return correct Id for standard Pricebook'
        );
    }

    @isTest
    static void testGetUniversalPricebook() {

        List<Pricebook2> defaultPricebooks = (List<Pricebook2>) new SObjectBuilder(Pricebook2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Pricebook2.Name => ValueProviderBuilder.provideList(new List<String>{
                    'ProServ Universal GBP', 'CC ProServ Universal GBP'
                }),
                Pricebook2.IsActive => true,
                Pricebook2.ExtID__c => ValueProviderBuilder.provideList(new List<String>{
                    'ProServ_Universal_GBP', 'CC_ProServ_Universal_GBP'
                }),
                Pricebook2.CurrencyIsoCode => RingCentralHelper.GBP
            })
            .quantity(2)
            .create()
            .getRecords();

        Pricebook2 defaultProservPricebook;
        Pricebook2 defaultCCProservPricebook;
        for (Pricebook2 pb : defaultPricebooks) {
            if (pb.ExtID__c == 'ProServ_Universal_GBP') {
                defaultProservPricebook = pb;
            } else if (pb.ExtID__c == 'CC_ProServ_Universal_GBP') {
                defaultCCProservPricebook = pb;
            }
        }

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'TestAccount')
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_AVAYA,
                Opportunity.AccountId => acc.Id,
                Opportunity.CurrencyIsoCode => RingCentralHelper.GBP
            })
            .create()
            .getRecord();

        Test.startTest();
            Id proservPricebookId = Pricebook2Helper.findUniversalPricebookId(
                opp.Brand_Name__c,
                opp.Sub_Brand__c,
                opp.CurrencyIsoCode,
                Pricebook2Helper.PROSERV_TYPE.PROSERV
            );

            Id ccProservPricebookId = Pricebook2Helper.findUniversalPricebookId(
                opp.Brand_Name__c,
                opp.Sub_Brand__c,
                opp.CurrencyIsoCode,
                Pricebook2Helper.PROSERV_TYPE.CC_PROSERV
            );
        Test.stopTest();

        System.assertEquals(
            defaultProservPricebook.Id,
            proservPricebookId,
            'method should return default proserv pricebook with ExtID__c like \'ProServ_Universal%\' and currency specified on Opportunity record'
        );

        System.assertEquals(
            defaultCCProservPricebook.Id,
            ccProservPricebookId,
            'method should return default proserv pricebook with ExtID__c like \'CC_ProServ_Universal%\' and currency specified on Opportunity record'
        );
    }

    @isTest
    static void testGetUniversalPricebookFromCustomSetting() {

        List<Pricebook2> testPricebooks = (List<Pricebook2>) new SObjectBuilder(Pricebook2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Pricebook2.Name => ValueProviderBuilder.provideList(new List<String>{
                    'ProServ GBP', 'CC ProServ GBP', 'ProServ Universal GBP', 'CC ProServ Universal GBP'
                }),
                Pricebook2.IsActive => true,
                Pricebook2.ExtID__c => ValueProviderBuilder.provideList(new List<String>{
                    'Test_ProServ_GBP', 'Test_CC_ProServ_GBP', 'ProServ_Universal_GBP', 'CC_ProServ_Universal_GBP'
                }),
                Pricebook2.CurrencyIsoCode => RingCentralHelper.GBP
            })
            .quantity(4)
            .create()
            .getRecords();

        Pricebook2 testProservPricebook;
        Pricebook2 testCCProservPricebook;
        Pricebook2 testUniversalProservPricebook;
        Pricebook2 testUniversalCCProservPricebook;
        for (Pricebook2 pb : testPricebooks) {
            if (pb.ExtID__c == 'Test_ProServ_GBP') {
                testProservPricebook = pb;
            } else if (pb.ExtID__c == 'Test_CC_ProServ_GBP') {
                testCCProservPricebook = pb;
            } else if (pb.ExtID__c == 'ProServ_Universal_GBP') {
                testUniversalProservPricebook = pb;
            } else if (pb.ExtID__c == 'CC_ProServ_Universal_GBP') {
                testUniversalCCProservPricebook = pb;
            }
        }

        new SObjectBuilder(PriceBookAssignments__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PriceBookAssignments__c.Name => ValueProviderBuilder.provideUniqueString('test_setting_'),
                PriceBookAssignments__c.Active__c => true,
                PriceBookAssignments__c.BrandName__c => ValueProviderBuilder.provideList(new List<String>{
                    OpportunityHelper.BRAND_AVAYA, OpportunityHelper.BRAND_RINGCENTRAL
                }),
                PriceBookAssignments__c.SubBrandName__c => ValueProviderBuilder.provideList(new List<String>{
                    null, 'test_sub_brand_2'
                }),
                PriceBookAssignments__c.PSPriceBookExtID__c => ValueProviderBuilder.provideList(new List<String>{
                    testProservPricebook.ExtID__c, null
                }),
                PriceBookAssignments__c.CCPSPriceBookExtID__c => ValueProviderBuilder.provideList(new List<String>{
                    testCCProservPricebook.ExtID__c, null
                }),
                PriceBookAssignments__c.Currency__c => RingCentralHelper.GBP
            })
            .quantity(2)
            .create();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'TestAccount')
            .create()
            .getRecord();

        List<Opportunity> testOpps = (List<Opportunity>) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                Opportunity.Brand_Name__c => ValueProviderBuilder.provideList(new List<String>{
                    OpportunityHelper.BRAND_AVAYA, OpportunityHelper.BRAND_RINGCENTRAL
                }),
                Opportunity.Sub_Brand__c => ValueProviderBuilder.provideList(new List<String>{
                    'test_sub_brand_2', 'test_sub_brand_2'
                }),
                Opportunity.AccountId => acc.Id,
                Opportunity.CurrencyIsoCode => RingCentralHelper.GBP
            })
            .quantity(2)
            .create()
            .getRecords();

        Opportunity avayaOpp;
        Opportunity rcOpp;
        for (Opportunity opp : testOpps) {
            if (opp.Brand_Name__c == OpportunityHelper.BRAND_AVAYA) {
                avayaOpp = opp;
            } else if (opp.Brand_Name__c == OpportunityHelper.BRAND_RINGCENTRAL) {
                rcOpp = opp;
            }
        }

        Test.startTest();
            Id proservPricebookId = Pricebook2Helper.findUniversalPricebookId(
                avayaOpp.Brand_Name__c,
                avayaOpp.Sub_Brand__c,
                avayaOpp.CurrencyIsoCode,
                Pricebook2Helper.PROSERV_TYPE.PROSERV
            );
            Id ccProservPricebookId = Pricebook2Helper.findUniversalPricebookId(
                avayaOpp.Brand_Name__c,
                avayaOpp.Sub_Brand__c,
                avayaOpp.CurrencyIsoCode,
                Pricebook2Helper.PROSERV_TYPE.CC_PROSERV
            );
            System.assertEquals(
                testProservPricebook.Id,
                proservPricebookId,
                'method should return pricebook specified in PriceBookAssignments__c custom setting'
            );
            System.assertEquals(
                testCCProservPricebook.Id,
                ccProservPricebookId,
                'method should return pricebook specified in PriceBookAssignments__c custom setting'
            );


            proservPricebookId = Pricebook2Helper.findUniversalPricebookId(
                rcOpp.Brand_Name__c,
                rcOpp.Sub_Brand__c,
                rcOpp.CurrencyIsoCode,
                Pricebook2Helper.PROSERV_TYPE.PROSERV
            );
            ccProservPricebookId = Pricebook2Helper.findUniversalPricebookId(
                rcOpp.Brand_Name__c,
                rcOpp.Sub_Brand__c,
                rcOpp.CurrencyIsoCode,
                Pricebook2Helper.PROSERV_TYPE.CC_PROSERV
            );
            System.assertEquals(
                testUniversalProservPricebook.Id,
                proservPricebookId,
                'method should return universal pricebook if PSPriceBookExtID__c field is empty in PriceBookAssignments__c custom setting for suitable brand'
            );
            System.assertEquals(
                testUniversalCCProservPricebook.Id,
                ccProservPricebookId,
                'method should return universal pricebook if CCPSPriceBookExtID__c field is empty in PriceBookAssignments__c custom setting for suitable brand'
            );

        Test.stopTest();
    }
}