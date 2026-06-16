@IsTest
private class Test_PDFTemplateHelper {

    private static final String PHOENIX_PACKAGE = '[{"id":"210","version":"1","packageInfo":{"catalogId":"210","version":"1","name":"RingCentral Video Pro","displayName":"RingCentral Video Pro"},"productName":"Meetings","duration":"Annual","edition":{"id":3,"name":"Essentials"},"contract":null,"offerType":"Regular","poc":null,"globalPackageLimits":[{"value":"2000","code":"MONTHLY_AMOUNT_LIMIT","name":"Monthly money amount limit","type":"Amount","scope":"BillingCycle","transactionType":"Any","target":"Global","override":false}],"permissions":null,"packageBusinessIdentities":{}}]';

    @TestSetup
    private static void test_generateData() {

        new SObjectBuilder(Feature_Toggle__c.sObjectType)
            .setField(Feature_Toggle__c.PDF_Engine_1_0__c, true)
            .setField(Feature_Toggle__c.PDF_Engine_2_0__c, true)
            .create();

        new SObjectBuilder(RingCentralVariousSettings__c.sObjectType)
            .setField(RingCentralVariousSettings__c.TemplatePreselectedDLThreshold__c, 249)
            .create();
    }
    @IsTest
    static void testActiveAgreeementRequirement() {
        List<RC_Quote_Template__c> templates;
        Account acc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Opty test account',
                Account.RC_User_ID__c => '12345'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => acc.Id,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today(),
                Opportunity.Name => 'Test Opportunity'
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => 'qoutetest',
                Quote.OpportunityId => opp.Id,
                Quote.Approved_Status__c => QuoteHelper.APPROVAL_STATUS_APPROVED,
                Quote.Products__c => 'RingCentral;',
                Quote.QuoteType__c => QuoteHelper.QUOTE_TYPE_AGREEMENT,
                Quote.Status => QuoteHelper.QUOTE_STATUS_ACTIVE,
                Quote.Start_Date__c => System.today(),
                Quote.End_Date__c => System.today(),
                Quote.RecordTypeId => QuoteHelper.RT_ID_SALES
            })
            .create()
            .getRecord();

        RC_Quote_Template__c temp = (RC_Quote_Template__c) new SObjectBuilder(RC_Quote_Template__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                RC_Quote_Template__c.Name => 'Quote',
                RC_Quote_Template__c.Sorting_Order__c => 1.0,
                RC_Quote_Template__c.Description__c => 'Quote',
                RC_Quote_Template__c.Brand__c => 'RingCentral;',
                RC_Quote_Template__c.Opportunity_Record_Type__c => 'Sales Opportunity;New Sales Opportunity',
                RC_Quote_Template__c.Type__c => QuoteHelper.QUOTE_TYPE_AGREEMENT,
                RC_Quote_Template__c.Active__c => true,
                RC_Quote_Template__c.Order_Type__c => 'Change Order',
                RC_Quote_Template__c.Products__c => 'RingCentral',
                RC_Quote_Template__c.Quote_Record_Type__c => 'Sales Quote',
                RC_Quote_Template__c.Requirements__c => 'Has Active Sales Agreement'
            })
            .create()
            .getRecord();

        Test.startTest();
        templates = PDFTemplateHelper.getPdfTemplates(opp.Id, qt.Id);
        Test.stopTest();

        System.assertEquals(1, templates.size());
    }

    @IsTest
    static void testIsProServEngagedRequirement() {
        List<RC_Quote_Template__c> templates;
        Account acc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Opty test account',
                Account.RC_User_ID__c => '12345'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => acc.Id,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today(),
                Opportunity.Name => 'Test Opportunity'
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => 'qoutetest',
                Quote.OpportunityId => opp.Id,
                Quote.Approved_Status__c => QuoteHelper.APPROVAL_STATUS_APPROVED,
                Quote.Products__c => 'RingCentral;',
                Quote.QuoteType__c => QuoteHelper.QUOTE_TYPE_AGREEMENT,
                Quote.Status => QuoteHelper.QUOTE_STATUS_ACTIVE,
                Quote.Start_Date__c => System.today(),
                Quote.End_Date__c => System.today(),
                Quote.RecordTypeId => QuoteHelper.RT_ID_SALES
            })
            .create()
            .getRecord();

        List<RC_Quote_Template__c> templatesList = (List<RC_Quote_Template__c>) new SObjectBuilder(RC_Quote_Template__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                RC_Quote_Template__c.Name => 'Quote',
                RC_Quote_Template__c.Sorting_Order__c => 1.0,
                RC_Quote_Template__c.Description__c => 'Quote',
                RC_Quote_Template__c.Brand__c => 'RingCentral;',
                RC_Quote_Template__c.Opportunity_Record_Type__c => 'Sales Opportunity;New Sales Opportunity',
                RC_Quote_Template__c.Type__c => QuoteHelper.QUOTE_TYPE_AGREEMENT,
                RC_Quote_Template__c.Active__c => true,
                RC_Quote_Template__c.Order_Type__c => 'Change Order',
                RC_Quote_Template__c.Products__c => 'RingCentral',
                RC_Quote_Template__c.Quote_Record_Type__c => 'Sales Quote',
                RC_Quote_Template__c.Requirements__c => ValueProviderBuilder.provideList(new List<String>{'Has ProServ Engaged', 'Has No ProServ Engaged'})
            })
            .quantity(2)
            .create()
            .getRecords();

        Test.startTest();
        templates = PDFTemplateHelper.getPdfTemplates(opp.Id, qt.Id);
        Test.stopTest();

        System.assertEquals(1, templates.size());
        System.assertEquals(templatesList[1].Id, templates.get(0).Id);
    }

    @IsTest
    static void testHasContactCenterRequirement() {
        List<RC_Quote_Template__c> templates;
        Account acc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Opty test account',
                Account.RC_User_ID__c => '12345'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => acc.Id,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today(),
                Opportunity.Name => 'Test Opportunity'
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => 'qoutetest',
                Quote.OpportunityId => opp.Id,
                Quote.Approved_Status__c => QuoteHelper.APPROVAL_STATUS_APPROVED,
                Quote.Products__c => 'Contact Center;',
                Quote.QuoteType__c => QuoteHelper.QUOTE_TYPE_AGREEMENT,
                Quote.Status => QuoteHelper.QUOTE_STATUS_ACTIVE,
                Quote.Start_Date__c => System.today(),
                Quote.End_Date__c => System.today(),
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.RecordTypeId => QuoteHelper.RT_ID_SALES
            })
            .create()
            .getRecord();

        Product2 serviceCCSubTypeSecond = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => 'serviceCCSubTypeSecond',
                Product2.IsActive => true,
                Product2.Family => Product2Helper.FAMILY_SERVICE,
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_CONTACT_CENTER,
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ANNUAL
            })
            .create()
            .getRecord();

        PricebookEntry pbe = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => serviceCCSubTypeSecond.Id,
                PricebookEntry.UnitPrice => 200,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.CurrencyIsoCode => 'USD'
            })
            .create()
            .getRecord();

        Test.startTest();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Product2Id => serviceCCSubTypeSecond.Id,
                QuoteLineItem.Quantity => 800,
                QuoteLineItem.NewQuantity__c => 1800,
                QuoteLineItem.UnitPrice => pbe.UnitPrice,
                QuoteLineItem.PricebookEntryId => pbe.Id
            })
            .create()
            .getRecord();

        List<RC_Quote_Template__c> templatesList = (List<RC_Quote_Template__c>) new SObjectBuilder(RC_Quote_Template__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                RC_Quote_Template__c.Name => 'Quote',
                RC_Quote_Template__c.Sorting_Order__c => 1.0,
                RC_Quote_Template__c.Description__c => 'Quote',
                RC_Quote_Template__c.Brand__c => 'RingCentral;',
                RC_Quote_Template__c.Opportunity_Record_Type__c => 'Sales Opportunity;New Sales Opportunity',
                RC_Quote_Template__c.Type__c => QuoteHelper.QUOTE_TYPE_AGREEMENT,
                RC_Quote_Template__c.Active__c => true,
                RC_Quote_Template__c.Order_Type__c => 'Change Order',
                RC_Quote_Template__c.Products__c => 'RingCentral;Contact Center',
                RC_Quote_Template__c.Quote_Record_Type__c => 'Sales Quote',
                RC_Quote_Template__c.Requirements__c => ValueProviderBuilder.provideList(new List<String>{'Has Contact Center Products', 'Has No Contact Center Products', PDFTemplateHelper.REQUIREMENT_SHOW_IF_MORE_THAN_DLS, PDFTemplateHelper.REQUIREMENT_SHOW_IF_LESS_THAN_DLS})
            })
            .quantity(4)
            .create()
            .getRecords();

        templates = PDFTemplateHelper.getPdfTemplates(opp.Id, qt.Id);

        Test.stopTest();

        System.assertEquals(2, templates.size());
        System.assertEquals(templatesList[0].Id, templates.get(0).Id);
    }

    @IsTest
    static void testTemplatesFilteredByBillingCountry() {

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'ACME Inc.',
                Account.RC_User_ID__c => '12345',
                Account.BillingCountry => 'United Kingdom'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => 'ACME Inc. Opportunity',
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => acc.Id
            })
            .create()
            .getRecord();

        Quote quote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => 'ACME Inc. Quote',
                Quote.OpportunityId => opp.Id,
                Quote.Approved_Status__c => QuoteHelper.APPROVAL_STATUS_APPROVED,
                Quote.Products__c => 'RingCentral',
                Quote.QuoteType__c => QuoteHelper.QUOTE_TYPE_AGREEMENT,
                Quote.Status => QuoteHelper.QUOTE_STATUS_ACTIVE,
                Quote.Start_Date__c => System.today(),
                Quote.End_Date__c => System.today(),
                Quote.RecordTypeId => QuoteHelper.RT_ID_SALES
            })
            .create()
            .getRecord();

        new SObjectBuilder(RC_Quote_Template__c.SObjectType)
            .quantity(3)
            .setFields(new Map<SObjectField, Object> {
                RC_Quote_Template__c.Active__c => true,
                RC_Quote_Template__c.Name => ValueProviderBuilder.provideList(new List<String> { 'TPL_MATCH', 'TPL_NON_MATCH', 'TPL_EMPTY'}),
                RC_Quote_Template__c.Description__c => ValueProviderBuilder.provideUniqueString(),
                RC_Quote_Template__c.Sorting_Order__c => 1.0,
                RC_Quote_Template__c.Brand__c => RingCentralHelper.BRAND_RINGCENTRAL,
                RC_Quote_Template__c.Type__c => QuoteHelper.QUOTE_TYPE_AGREEMENT,
                RC_Quote_Template__c.Opportunity_Record_Type__c => 'Sales Opportunity;New Sales Opportunity',
                RC_Quote_Template__c.Order_Type__c => 'Change Order',
                RC_Quote_Template__c.Quote_Record_Type__c => 'Sales Quote',
                RC_Quote_Template__c.Products__c => 'RingCentral',
                RC_Quote_Template__c.Available_For_Billing_Countries__c => ValueProviderBuilder.provideList(new List<String> { 'United Kingdom', 'United States', null})
            })
            .create()
            .getRecords();

        Test.startTest();
        List<RC_Quote_Template__c> templates = PDFTemplateHelper.getPdfTemplates(opp.Id, quote.Id);

        RC_Quote_Template__c templateEmpty = null;
        RC_Quote_Template__c templateMatch = null;
        RC_Quote_Template__c templateNonMatch = null;

        for(RC_Quote_Template__c tpl: templates) {
            switch on tpl.Name {
                when 'TPL_MATCH' {
                    templateMatch = tpl;
                }
                when 'TPL_NON_MATCH' {
                    templateNonMatch = tpl;
                }
                when 'TPL_EMPTY' {
                    templateEmpty = tpl;
                }
            }
        }

        Test.stopTest();

        System.assertEquals(2, templates.size());

        System.assertNotEquals(null, templateEmpty);
        System.assert(new Set<String>(StringHelper.safeSplit(templateEmpty.Available_For_Billing_Countries__c, ';')).isEmpty());

        System.assertNotEquals(null, templateMatch);
        System.assert(new Set<String>(StringHelper.safeSplit(templateMatch.Available_For_Billing_Countries__c, ';')).contains(acc.BillingCountry));

        System.assertEquals(null, templateNonMatch);
    }

    @IsTest
    static void verifyOrderTypeReturnCorrectValue() {
        List<Account> testAccounts = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => ValueProviderBuilder.provideList(new List<String>{
                    'trialAcc', 'regularAcc', 'newAcc', null, 'PocToPaidAcc', 'PocToPaidTrialAcc'
                }),
                Account.RC_User_ID__c => ValueProviderBuilder.provideList(new List<String>{
                    '123', '123', null, null, null, null
                }),
                Account.Billing_ID__c => ValueProviderBuilder.provideList(new List<String>{
                    null, null, null, null, '123', '123'
                }),
                Account.Offer_Type__c => ValueProviderBuilder.provideList(new List<String>{
                    null, null, null, null, AccountHelper.OFFER_TYPE_POC, AccountHelper.OFFER_TYPE_TRIAL
                }),
                Account.RC_Account_Status__c => ValueProviderBuilder.provideList(new List<String>{
                    'Free Trial', 'Regular', 'Free Trial', null, AccountHelper.OFFER_TYPE_POC, AccountHelper.OFFER_TYPE_TRIAL
                })
            })
            .quantity(6)
            .build()
            .getRecords();

        System.assertEquals(OrderHelper.TYPE_NEW_ORDER, PDFTemplateHelper.getOrderType(testAccounts[0]));
        System.assertEquals('Change Order', PDFTemplateHelper.getOrderType(testAccounts[1]));
        System.assertEquals(OrderHelper.TYPE_NEW_ORDER, PDFTemplateHelper.getOrderType(testAccounts[2]));
        System.assertEquals(OrderHelper.TYPE_NEW_ORDER, PDFTemplateHelper.getOrderType(testAccounts[3]));
        System.assertEquals(OrderHelper.TYPE_NEW_ORDER, PDFTemplateHelper.getOrderType(testAccounts[4]));
        System.assertEquals(OrderHelper.TYPE_NEW_ORDER, PDFTemplateHelper.getOrderType(testAccounts[5]));
    }

    @isTest
    static void testGetIsTemplateAvailableForBICountry() {
        final String testCountryCode = 'USA';

        List<String> testCountryNames = new List<String>{
            'united states',
            'united states of america',
            'us',
            'usa'
        };

        new SObjectBuilder(CountryCodes__c.SObjectType)
            .setField(CountryCodes__c.Name, testCountryCode)
            .setField(CountryCodes__c.CountryName__c, String.join(testCountryNames, ';'))
            .create();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.Package_Info__c, NGBSTestDataGenerator.generateQuotePackageInfo())
            .build()
            .getRecord();

        String biCountry = QuoteHelper.getApprovedBICountryFromQuote(testQuote);

        final String availableForCountries = String.join(
            new List<String> {
                PDFTemplateHelper.AVAILABILITY_COUNTRY_USA,
                PDFTemplateHelper.AVAILABILITY_COUNTRY_CANADA
            },
            ';'
        );

        final String availableForCountriesBlank = null;

        Test.startTest();
            Boolean res = PDFTemplateHelper.getIsTemplateAvailableForBICountry(biCountry, availableForCountries, null);
            Boolean resBlank = PDFTemplateHelper.getIsTemplateAvailableForBICountry(biCountry, availableForCountriesBlank, null);
        Test.stopTest();

        System.assert(res, 'Template should be available for United States');
        System.assert(resBlank, 'Template should be available when Available_For_Countries__c template filter is blank');
    }

    @isTest
    static void testAvailableForBICountriesFilter() {
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
        .setFields(new Map<SObjectField, Object>{
            Opportunity.AccountId => ValueProviderBuilder.provideCommonParent(Account.sObjectType)
        })
        .create()
        .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.sObjectType)
        .setFields(new Map<SObjectField, Object>{
            Quote.OpportunityId => opp.id,
            Quote.Products__c => 'RingCentral;',
            Quote.QuoteType__c => QuoteHelper.QUOTE_TYPE_QUOTE,
            Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
            Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo(),
            Quote.RecordTypeId => QuoteHelper.RT_ID_SALES
        })
        .create()
        .getRecord();

        final String testCountryCode = 'USA';
        List<String> testCountryNames = new List<String>{
            'united states',
            'united states of america',
            'us',
            'usa'
        };

        new SObjectBuilder(CountryCodes__c.SObjectType)
            .setField(CountryCodes__c.Name, testCountryCode)
            .setField(CountryCodes__c.CountryName__c, String.join(testCountryNames, ';'))
            .create();

        final String availableForCountries = String.join(
            new List<String> {
                PDFTemplateHelper.AVAILABILITY_COUNTRY_USA,
                PDFTemplateHelper.AVAILABILITY_COUNTRY_CANADA
            },
            ';'
        );

        RC_Quote_Template__c temp = (RC_Quote_Template__c) new SObjectBuilder(RC_Quote_Template__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                RC_Quote_Template__c.Name => 'Quote',
                RC_Quote_Template__c.Sorting_Order__c => 1.0,
                RC_Quote_Template__c.Description__c => 'Quote',
                RC_Quote_Template__c.Brand__c => 'RingCentral',
                RC_Quote_Template__c.Opportunity_Record_Type__c => 'Sales Opportunity;New Sales Opportunity',
                RC_Quote_Template__c.Type__c => 'Quote',
                RC_Quote_Template__c.Active__c => true,
                RC_Quote_Template__c.Order_Type__c => OrderHelper.TYPE_NEW_ORDER,
                RC_Quote_Template__c.Quote_Record_Type__c => 'Sales Quote',
                RC_Quote_Template__c.Products__c => 'RingCentral',
                RC_Quote_Template__c.Available_For_Countries__c => availableForCountries,
                RC_Quote_Template__c.NotAvailableForBICountries__c => null
            })
            .create()
            .getRecord();

        Test.startTest();
            List<RC_Quote_Template__c> templates = PDFTemplateHelper.getPdfTemplates(opp.Id, qt.Id);
        Test.stopTest();

        System.assertEquals(1, templates.size(), 'Template not found');
        System.assertEquals(temp.Id, templates[0].Id, 'Found template is different from the predefined one\'s');
    }

    @isTest
    static void testNotAvailableForBICountriesFilter() {
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
        .setFields(new Map<SObjectField, Object>{
            Opportunity.AccountId => ValueProviderBuilder.provideCommonParent(Account.sObjectType)
        })
        .create()
        .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.sObjectType)
        .setFields(new Map<SObjectField, Object>{
            Quote.OpportunityId => opp.id,
            Quote.Products__c => 'RingCentral;',
            Quote.QuoteType__c => QuoteHelper.QUOTE_TYPE_QUOTE,
            Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
            Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo(),
            Quote.RecordTypeId => QuoteHelper.RT_ID_SALES
        })
        .create()
        .getRecord();

        final String testCountryCode = 'USA';
        List<String> testCountryNames = new List<String>{
            'united states',
            'united states of america',
            'us',
            'usa'
        };

        new SObjectBuilder(CountryCodes__c.SObjectType)
            .setField(CountryCodes__c.Name, testCountryCode)
            .setField(CountryCodes__c.CountryName__c, String.join(testCountryNames, ';'))
            .create();

        final String notAvailableForCountries = String.join(
            new List<String> {
                PDFTemplateHelper.AVAILABILITY_COUNTRY_USA,
                PDFTemplateHelper.AVAILABILITY_COUNTRY_CANADA
            },
            ';'
        );

        RC_Quote_Template__c templateToStay = (RC_Quote_Template__c) new SObjectBuilder(RC_Quote_Template__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                RC_Quote_Template__c.Name => 'T1',
                RC_Quote_Template__c.Sorting_Order__c => 1.0,
                RC_Quote_Template__c.Brand__c => 'RingCentral',
                RC_Quote_Template__c.Opportunity_Record_Type__c => 'Sales Opportunity;New Sales Opportunity',
                RC_Quote_Template__c.Type__c => 'Quote',
                RC_Quote_Template__c.Active__c => true,
                RC_Quote_Template__c.Order_Type__c => OrderHelper.TYPE_NEW_ORDER,
                RC_Quote_Template__c.Quote_Record_Type__c => 'Sales Quote',
                RC_Quote_Template__c.Products__c => 'RingCentral',
                RC_Quote_Template__c.Available_For_Countries__c => null,
                RC_Quote_Template__c.NotAvailableForBICountries__c => null
            })
            .create()
            .getRecord();

        RC_Quote_Template__c templateToFilterOut = (RC_Quote_Template__c) new SObjectBuilder(RC_Quote_Template__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                RC_Quote_Template__c.Name => 'T1',
                RC_Quote_Template__c.Sorting_Order__c => 1.0,
                RC_Quote_Template__c.Brand__c => 'RingCentral',
                RC_Quote_Template__c.Opportunity_Record_Type__c => 'Sales Opportunity;New Sales Opportunity',
                RC_Quote_Template__c.Type__c => 'Quote',
                RC_Quote_Template__c.Active__c => true,
                RC_Quote_Template__c.Order_Type__c => OrderHelper.TYPE_NEW_ORDER,
                RC_Quote_Template__c.Quote_Record_Type__c => 'Sales Quote',
                RC_Quote_Template__c.Products__c => 'RingCentral',
                RC_Quote_Template__c.Available_For_Countries__c => null,
                RC_Quote_Template__c.NotAvailableForBICountries__c => null
            })
            .create()
            .getRecord();

        List<RC_Quote_Template__c> templates = PDFTemplateHelper.getPdfTemplates(opp.Id, qt.Id);

        System.assertEquals(2, templates.size(), 'Should return 2 templates because there are no BI Countries filters');

        Test.startTest();
            templateToFilterOut.NotAvailableForBICountries__c = notAvailableForCountries;
            update templateToFilterOut;

            templates = PDFTemplateHelper.getPdfTemplates(opp.Id, qt.Id);
        Test.stopTest();

        System.assertEquals(1, templates.size(), 'Should return "templateToStay"');
        System.assertEquals(templateToStay.Id, templates[0].Id, 'Found template is different from the expected one');
    }

    //
    @isTest
    static void testNotAvailableForBICountriesFilter_noQuoteBI() {
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
        .setFields(new Map<SObjectField, Object>{
            Opportunity.AccountId => ValueProviderBuilder.provideCommonParent(Account.sObjectType)
        })
        .create()
        .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.sObjectType)
        .setFields(new Map<SObjectField, Object>{
            Quote.OpportunityId => opp.id,
            Quote.Products__c => 'RingCentral;',
            Quote.QuoteType__c => QuoteHelper.QUOTE_TYPE_QUOTE,
            Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
            Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfoNoBI(),
            Quote.RecordTypeId => QuoteHelper.RT_ID_SALES
        })
        .create()
        .getRecord();

        final String testCountryCode = 'USA';
        List<String> testCountryNames = new List<String>{
            'united states',
            'united states of america',
            'us',
            'usa'
        };

        new SObjectBuilder(CountryCodes__c.SObjectType)
            .setField(CountryCodes__c.Name, testCountryCode)
            .setField(CountryCodes__c.CountryName__c, String.join(testCountryNames, ';'))
            .create();

        final String notAvailableForCountries = String.join(
            new List<String> {
                PDFTemplateHelper.AVAILABILITY_COUNTRY_USA,
                PDFTemplateHelper.AVAILABILITY_COUNTRY_CANADA
            },
            ';'
        );

        RC_Quote_Template__c templateToStay1 = (RC_Quote_Template__c) new SObjectBuilder(RC_Quote_Template__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                RC_Quote_Template__c.Name => 'T1',
                RC_Quote_Template__c.Sorting_Order__c => 1.0,
                RC_Quote_Template__c.Brand__c => 'RingCentral',
                RC_Quote_Template__c.Opportunity_Record_Type__c => 'Sales Opportunity;New Sales Opportunity',
                RC_Quote_Template__c.Type__c => 'Quote',
                RC_Quote_Template__c.Active__c => true,
                RC_Quote_Template__c.Order_Type__c => OrderHelper.TYPE_NEW_ORDER,
                RC_Quote_Template__c.Quote_Record_Type__c => 'Sales Quote',
                RC_Quote_Template__c.Products__c => 'RingCentral',
                RC_Quote_Template__c.Available_For_Countries__c => null,
                RC_Quote_Template__c.NotAvailableForBICountries__c => null
            })
            .create()
            .getRecord();

        RC_Quote_Template__c templateToStay2 = (RC_Quote_Template__c) new SObjectBuilder(RC_Quote_Template__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                RC_Quote_Template__c.Name => 'T1',
                RC_Quote_Template__c.Sorting_Order__c => 1.0,
                RC_Quote_Template__c.Brand__c => 'RingCentral',
                RC_Quote_Template__c.Opportunity_Record_Type__c => 'Sales Opportunity;New Sales Opportunity',
                RC_Quote_Template__c.Type__c => 'Quote',
                RC_Quote_Template__c.Active__c => true,
                RC_Quote_Template__c.Order_Type__c => OrderHelper.TYPE_NEW_ORDER,
                RC_Quote_Template__c.Quote_Record_Type__c => 'Sales Quote',
                RC_Quote_Template__c.Products__c => 'RingCentral',
                RC_Quote_Template__c.Available_For_Countries__c => null,
                RC_Quote_Template__c.NotAvailableForBICountries__c => null
            })
            .create()
            .getRecord();

        List<RC_Quote_Template__c> templates = PDFTemplateHelper.getPdfTemplates(opp.Id, qt.Id);

        System.assertEquals(2, templates.size(), 'Should return 2 templates because there are no BI Countries filters');

        Test.startTest();
            templateToStay2.NotAvailableForBICountries__c = notAvailableForCountries;
            update templateToStay2;

            templates = PDFTemplateHelper.getPdfTemplates(opp.Id, qt.Id);
        Test.stopTest();

        System.assertEquals(2, templates.size(), 'Should return both templates');
    }

    @isTest
    static void testNotAvailableForBICountriesFilter_quoteBIisDifferentFromFilter() {
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
        .setFields(new Map<SObjectField, Object>{
            Opportunity.AccountId => ValueProviderBuilder.provideCommonParent(Account.sObjectType)
        })
        .create()
        .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.sObjectType)
        .setFields(new Map<SObjectField, Object>{
            Quote.OpportunityId => opp.id,
            Quote.Products__c => 'RingCentral;',
            Quote.QuoteType__c => QuoteHelper.QUOTE_TYPE_QUOTE,
            Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
            Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo(),
            Quote.RecordTypeId => QuoteHelper.RT_ID_SALES
        })
        .create()
        .getRecord();

        final String testCountryCode = 'USA';
        List<String> testCountryNames = new List<String>{
            'united states',
            'united states of america',
            'us',
            'usa'
        };

        new SObjectBuilder(CountryCodes__c.SObjectType)
            .setField(CountryCodes__c.Name, testCountryCode)
            .setField(CountryCodes__c.CountryName__c, String.join(testCountryNames, ';'))
            .create();

        final String notAvailableForCountries = PDFTemplateHelper.AVAILABILITY_COUNTRY_AUSTRALIA;

        RC_Quote_Template__c templateToStay1 = (RC_Quote_Template__c) new SObjectBuilder(RC_Quote_Template__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                RC_Quote_Template__c.Name => 'T1',
                RC_Quote_Template__c.Sorting_Order__c => 1.0,
                RC_Quote_Template__c.Brand__c => 'RingCentral',
                RC_Quote_Template__c.Opportunity_Record_Type__c => 'Sales Opportunity;New Sales Opportunity',
                RC_Quote_Template__c.Type__c => 'Quote',
                RC_Quote_Template__c.Active__c => true,
                RC_Quote_Template__c.Order_Type__c => OrderHelper.TYPE_NEW_ORDER,
                RC_Quote_Template__c.Quote_Record_Type__c => 'Sales Quote',
                RC_Quote_Template__c.Products__c => 'RingCentral',
                RC_Quote_Template__c.Available_For_Countries__c => null,
                RC_Quote_Template__c.NotAvailableForBICountries__c => null
            })
            .create()
            .getRecord();

        RC_Quote_Template__c templateToStay2 = (RC_Quote_Template__c) new SObjectBuilder(RC_Quote_Template__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                RC_Quote_Template__c.Name => 'T1',
                RC_Quote_Template__c.Sorting_Order__c => 1.0,
                RC_Quote_Template__c.Brand__c => 'RingCentral',
                RC_Quote_Template__c.Opportunity_Record_Type__c => 'Sales Opportunity;New Sales Opportunity',
                RC_Quote_Template__c.Type__c => 'Quote',
                RC_Quote_Template__c.Active__c => true,
                RC_Quote_Template__c.Order_Type__c => OrderHelper.TYPE_NEW_ORDER,
                RC_Quote_Template__c.Quote_Record_Type__c => 'Sales Quote',
                RC_Quote_Template__c.Products__c => 'RingCentral',
                RC_Quote_Template__c.Available_For_Countries__c => null,
                RC_Quote_Template__c.NotAvailableForBICountries__c => null
            })
            .create()
            .getRecord();

        List<RC_Quote_Template__c> templates = PDFTemplateHelper.getPdfTemplates(opp.Id, qt.Id);

        System.assertEquals(2, templates.size(), 'Should return 2 templates because there are no BI Countries filters');

        Test.startTest();
            templateToStay2.NotAvailableForBICountries__c = notAvailableForCountries;
            update templateToStay2;

            templates = PDFTemplateHelper.getPdfTemplates(opp.Id, qt.Id);
        Test.stopTest();

        System.assertEquals(
            2,
            templates.size(),
            'Should return both templates because NotAvailableForBICountries__c is Australia and Quote BI Country is USA'
        );
    }

    @isTest
    static void testAvailableForPhoenixFilter() {
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => ValueProviderBuilder.provideCommonParent(Account.sObjectType)
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.OpportunityId => opp.id,
                Quote.Products__c => 'RingCentral;',
                Quote.QuoteType__c => QuoteHelper.QUOTE_TYPE_QUOTE,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.Package_Info__c => PHOENIX_PACKAGE,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
            })
            .create()
            .getRecord();

        List<RC_Quote_Template__c> templates = (List<RC_Quote_Template__c>) new SObjectBuilder(RC_Quote_Template__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                RC_Quote_Template__c.Name => 'Phoenix - Quote',
                RC_Quote_Template__c.ProductLabels__c => ValueProviderBuilder.provideList(new List<String>{'Phoenix','Freyja'}),
                RC_Quote_Template__c.Sorting_Order__c => 1.0,
                RC_Quote_Template__c.Brand__c => 'RingCentral',
                RC_Quote_Template__c.Opportunity_Record_Type__c => 'New Sales Opportunity',
                RC_Quote_Template__c.Type__c => 'Quote',
                RC_Quote_Template__c.Active__c => true,
                RC_Quote_Template__c.Order_Type__c => OrderHelper.TYPE_NEW_ORDER,
                RC_Quote_Template__c.Quote_Record_Type__c => 'Sales Quote v2',
                RC_Quote_Template__c.Service__c => 'Meetings',
                RC_Quote_Template__c.Template_Engine__c => 'PDF Engine 2.0'
            })
            .quantity(2)
            .create()
            .getRecords();

        Test.startTest();
        List<RC_Quote_Template__c> foundTemplates = PDFTemplateHelper.getPdfTemplates(opp.Id, qt.Id);
        Test.stopTest();

        System.assertEquals(1, foundTemplates.size(), 'Must be found one template');
        System.assertEquals(foundTemplates[0].Id, templates[0].Id, 'Found template is different from the predefined one\'s');
    }

    @isTest
    static void testMSAOfficeForDocusignCLM() {

        Profile sysAdminProfile = (Profile) new ProfileSelector()
            .selectProfileByName(new List<String>{ProfileHelper.SYSTEM_ADMIN})
            .executeQuery()
            .get(0);

        User testUser = (User) new SObjectBuilder(User.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                User.Username => 'testDocusignCLM!user@gmail.com',
                User.LastName => 'testUser',
                User.Email => 'testUser@gmail.com',
                User.Alias => 'testUser',
                User.TimeZoneSidKey => 'America/Los_Angeles',
                User.LocaleSidKey => 'en_US',
                User.EmailEncodingKey => 'UTF-8',
                User.ProfileId => sysAdminProfile.Id,
                User.LanguageLocaleKey => 'en_US'
            })
            .create()
            .getRecord();

        PermissionSet testPermissionSet = (PermissionSet) new SObjectBuilder(PermissionSet.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PermissionSet.Name => 'Test_EnableDocusignCLMAccess',
                PermissionSet.Label => 'EnableDocusignCLMAccess'
            })
            .create()
            .getRecord();

        CustomPermission docusignCLMAccessCustomPermission = (CustomPermission) new CustomPermissionSelector()
            .selectCustomPermissionsByDeveloperName(new List<Object>{CustomPermissionHelper.PERMISSION_ENABLE_DOCUSIGN_CLM_ACCESS})
            .executeQuery()
            .get(0);

        SetupEntityAccess testEntityAccess = (SetupEntityAccess) new SObjectBuilder(SetupEntityAccess.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                SetupEntityAccess.ParentId => testPermissionSet.Id,
                SetupEntityAccess.SetupEntityId => docusignCLMAccessCustomPermission.Id
            })
            .create()
            .getRecord();

        //Assign permission set to user
        PermissionSetAssignment testPermissionSetAssignment = (PermissionSetAssignment) new SObjectBuilder(PermissionSetAssignment.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PermissionSetAssignment.AssigneeId => testUser.Id,
                PermissionSetAssignment.PermissionSetId => testPermissionSet.Id
            })
            .create()
            .getRecord();

        System.runAs(testUser) {

            new SObjectBuilder(Docusign_CLM_Brands__c.SObjectType)
                    .setFields(new Map<SObjectField, Object> {
                    Docusign_CLM_Brands__c.Name => ValueProviderBuilder.provideUniqueString('TestSetting_'),
                    Docusign_CLM_Brands__c.Enable_DocuSign_CLM_Access__c => ValueProviderBuilder.provideList(
                            new List<Boolean>{ true, false }
                    ),
                    Docusign_CLM_Brands__c.Brand__c => ValueProviderBuilder.provideList(
                            new List<String>{ 'RingCentral', 'RingCentral EU' }
                    )
                    })
                    .quantity(2)
                    .create();

            Account acc = (Account) new SObjectBuilder(Account.sObjectType)
                .setFields(new Map<SObjectField, Object>{
                    Account.Name => ValueProviderBuilder.provideUniqueString('testAccount')
                })
                .create()
                .getRecord();

            List<Opportunity> oppList = (List<Opportunity>) new SObjectBuilder(Opportunity.sObjectType)
                .setFields(new Map<SObjectField, Object>{
                    Opportunity.AccountId => acc.Id,
                    Opportunity.Brand_Name__c => ValueProviderBuilder.provideList(
                            new List<String>{ 'RingCentral', 'RingCentral EU' }
                    ),
                    Opportunity.Tier_Name__c => 'Office',
                    Opportunity.IsDocusignCLMEnabled__c => ValueProviderBuilder.provideList(
                        new List<Boolean>{ true, false }
                    )
                })
                .quantity(2)
                .create()
                .getRecords();

            List<Quote> quotesList = (List<Quote>) new SObjectBuilder(Quote.sObjectType)
                .setFields(new Map<SObjectField, Object>{
                    Quote.OpportunityId => ValueProviderBuilder.provideParents(oppList),
                    Quote.Products__c => 'RingCentral;',
                    Quote.QuoteType__c => QuoteHelper.QUOTE_TYPE_AGREEMENT,
                    Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                    Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo(),
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
                })
                .quantity(2)
                .create()
                .getRecords();

            RC_Quote_Template__c temp = (RC_Quote_Template__c) new SObjectBuilder(RC_Quote_Template__c.sObjectType)
                .setFields(new Map<SObjectField, Object>{
                    RC_Quote_Template__c.Name => 'MSA - Office',
                    RC_Quote_Template__c.Description__c => 'MSA - Office',
                    RC_Quote_Template__c.Sorting_Order__c => 1.0,
                    RC_Quote_Template__c.Brand__c => ValueProviderBuilder.provideList(
                            new List<String>{ 'RingCentral', 'RingCentral EU' }
                    ),
                    RC_Quote_Template__c.Opportunity_Record_Type__c => 'New Sales Opportunity',
                    RC_Quote_Template__c.Type__c => 'Agreement',
                    RC_Quote_Template__c.Active__c => true,
                    RC_Quote_Template__c.Order_Type__c => OrderHelper.TYPE_NEW_ORDER,
                    RC_Quote_Template__c.Quote_Record_Type__c => 'Sales Quote v2',
                    RC_Quote_Template__c.Service__c => 'Office',
                    RC_Quote_Template__c.Template_Engine__c => 'PDF Engine 2.0',
                    RC_Quote_Template__c.Requirements__c => PDFTemplateHelper.REQUIREMENT_HAS_DOCUSIGN_CLM_ACCESS
                })
                .quantity(2)
                .create()
                .getRecord();

            Test.startTest();

                Opportunity clmOpportunity = oppList.get(0);
                Quote quoteForClmOpportunity = quotesList.get(0);

                Opportunity notClmOpportunity = oppList.get(1);
                Quote quoteForNotClmOpportunity = quotesList.get(1);

                System.assertEquals(
                    0,
                    PDFTemplateHelper.getPdfTemplates(clmOpportunity.Id, quoteForClmOpportunity.Id).size(),
                    'Template "MSA - Office" should not be available for user with "DocusignCLMAccess" permision ' +
                    'on Opportunity with IsDocusignCLMEnabled__c flag'
                );

                System.assertEquals(
                    1,
                    PDFTemplateHelper.getPdfTemplates(notClmOpportunity.Id, quoteForNotClmOpportunity.Id).size(),
                    'Template "MSA - Office" should not be available for user with "DocusignCLMAccess" permision ' +
                    'on Opportunity without IsDocusignCLMEnabled__c flag'
                );
            Test.stopTest();
        }
    }

    @isTest
    static void testAvailableForBobFilter() {
        Account acc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Opty test account',
                Account.Partner_ID__c => '12345',
                Account.Partner_Type__c => AccountHelper.ACCOUNT_PARTNER_BILL_ON_BEHALF
            })
            .create()
            .getRecord();
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => acc.Id,
                Opportunity.Tier_Name__c => OpportunityHelper.TIER_ENGAGE_DIGITAL_STANDALONE
            })
            .create()
            .getRecord();
        Quote qt = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.OpportunityId => opp.id,
                Quote.Products__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Quote.QuoteType__c => QuoteHelper.QUOTE_TYPE_QUOTE,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfoEngage(),
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
            })
            .create()
            .getRecord();
        RC_Quote_Template__c template = (RC_Quote_Template__c) new SObjectBuilder(RC_Quote_Template__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                RC_Quote_Template__c.Name => 'BoB',
                RC_Quote_Template__c.Products__c => OpportunityHelper.BRAND_RINGCENTRAL,
                RC_Quote_Template__c.Sorting_Order__c => 108,
                RC_Quote_Template__c.Brand__c => OpportunityHelper.BRAND_RINGCENTRAL,
                RC_Quote_Template__c.Opportunity_Record_Type__c => OpportunityHelper.RT_NAME_NEW_SALES_OPPORTUNITY,
                RC_Quote_Template__c.Type__c => QuoteHelper.QUOTE_TYPE_QUOTE,
                RC_Quote_Template__c.Active__c => true,
                RC_Quote_Template__c.Order_Type__c => PDFTemplateHelper.NEW_ORDER,
                RC_Quote_Template__c.Quote_Record_Type__c => QuoteHelper.RT_NAME_BILLING,
                RC_Quote_Template__c.Service__c => OpportunityHelper.TIER_ENGAGE_DIGITAL_STANDALONE,
                RC_Quote_Template__c.Template_Engine__c => TemplateEngine.PDF_ENGINE_2_0,
                RC_Quote_Template__c.Requirements__c => PDFTemplateHelper.REQUIREMENT_HAS_BOB_ACCOUNT
            })
            .create()
            .getRecord();
        Test.startTest();
        List<RC_Quote_Template__c> foundTemplates = PDFTemplateHelper.getPdfTemplates(opp.Id, qt.Id);
        Test.stopTest();
        System.assertEquals(1, foundTemplates.size(), 'Must be found one template');
        System.assertEquals(foundTemplates[0].Id, template.Id, 'Found template is different from the predefined one\'s');
    }


    @isTest
    static void testAvailableForWholesaleFilterOnChangePartnerFromBobToWholesale() {
        Account acc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Opty test account',
                Account.Partner_ID__c => '12345',
                Account.Partner_Type__c => AccountHelper.ACCOUNT_PARTNER_BILL_ON_BEHALF
            })
            .create()
            .getRecord();
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => acc.Id,
                Opportunity.Tier_Name__c => OpportunityHelper.TIER_ENGAGE_DIGITAL_STANDALONE
            })
            .create()
            .getRecord();

        PartnerOperationsLog__c partnerOperationsLog = (PartnerOperationsLog__c) new SObjectBuilder(PartnerOperationsLog__c.sObjectType)
        .setFields(new Map<SObjectField, Object>{
            PartnerOperationsLog__c.Opportunity__c => opp.Id,
            PartnerOperationsLog__c.isRejected__c => false,
            PartnerOperationsLog__c.isCompleted__c => false
        })
        .create()
        .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.OpportunityId => opp.id,
                Quote.Products__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Quote.QuoteType__c => QuoteHelper.QUOTE_TYPE_QUOTE,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfoEngage(),
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
            })
            .create()
            .getRecord();
        RC_Quote_Template__c template = (RC_Quote_Template__c) new SObjectBuilder(RC_Quote_Template__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                RC_Quote_Template__c.Name => 'BoB',
                RC_Quote_Template__c.Products__c => OpportunityHelper.BRAND_RINGCENTRAL,
                RC_Quote_Template__c.Sorting_Order__c => 108,
                RC_Quote_Template__c.Brand__c => OpportunityHelper.BRAND_RINGCENTRAL,
                RC_Quote_Template__c.Opportunity_Record_Type__c => OpportunityHelper.RT_NAME_NEW_SALES_OPPORTUNITY,
                RC_Quote_Template__c.Type__c => QuoteHelper.QUOTE_TYPE_QUOTE,
                RC_Quote_Template__c.Active__c => true,
                RC_Quote_Template__c.Order_Type__c => PDFTemplateHelper.NEW_ORDER,
                RC_Quote_Template__c.Quote_Record_Type__c => QuoteHelper.RT_NAME_BILLING,
                RC_Quote_Template__c.Service__c => OpportunityHelper.TIER_ENGAGE_DIGITAL_STANDALONE,
                RC_Quote_Template__c.Template_Engine__c => TemplateEngine.PDF_ENGINE_2_0,
                RC_Quote_Template__c.Requirements__c => PDFTemplateHelper.REQUIREMENT_HAS_WHOLESALE_ACCOUNT
            })
            .create()
            .getRecord();

        Test.startTest();
        List<RC_Quote_Template__c> foundTemplates = PDFTemplateHelper.getPdfTemplates(opp.Id, qt.Id);
        Test.stopTest();
        System.assertEquals(1, foundTemplates.size(), 'Must be found one template');
        System.assertEquals(foundTemplates[0].Id, template.Id, 'Found template is different from the predefined one\'s');
    }

    @isTest
    static void testAvailableForProServ() {
        Account acc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Opty test account'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => acc.Id,
                Opportunity.Tier_Name__c => OpportunityHelper.TIER_OFFICE
            })
            .create()
            .getRecord();

        Quote testMasterQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Quote.IsPrimary__c => true,
                    Quote.OpportunityId => opp.Id,
                    Quote.IsMultiProductTechnicalQuote__c => false,
                    Quote.Products__c => OpportunityHelper.BRAND_RINGCENTRAL,
                    Quote.QuoteType__c => QuoteHelper.QUOTE_TYPE_QUOTE,
                    Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                    Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo()
                }
            )
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Quote.IsPrimary__c => false,
                    Quote.OpportunityId => opp.Id,
                    Quote.MasterQuote__c => testMasterQuote.Id,
                    Quote.IsMultiProductTechnicalQuote__c => true,
                    Quote.ServiceName__c => QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT
                }
            )
            .create()
            .getRecord();
        
        RC_Quote_Template__c template = (RC_Quote_Template__c) new SObjectBuilder(RC_Quote_Template__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                RC_Quote_Template__c.Name => 'ProServ SOW Pricing Block',
                RC_Quote_Template__c.Sorting_Order__c => 201,
                RC_Quote_Template__c.Brand__c => OpportunityHelper.BRAND_RINGCENTRAL,
                RC_Quote_Template__c.Opportunity_Record_Type__c => OpportunityHelper.RT_NAME_NEW_SALES_OPPORTUNITY,
                RC_Quote_Template__c.Type__c => QuoteHelper.QUOTE_TYPE_QUOTE,
                RC_Quote_Template__c.Active__c => true,
                RC_Quote_Template__c.Order_Type__c => PDFTemplateHelper.NEW_ORDER,
                RC_Quote_Template__c.Quote_Record_Type__c => QuoteHelper.RT_NAME_BILLING,
                RC_Quote_Template__c.Service__c => OpportunityHelper.TIER_OFFICE,
                RC_Quote_Template__c.Template_Engine__c => TemplateEngine.PDF_ENGINE_2_0,
                RC_Quote_Template__c.Requirements__c => PDFTemplateHelper.REQUIREMENT_HAS_MULTIPRODUCT_ACCOUNT + ';' + PDFTemplateHelper.REQUIREMENT_HAS_PROFESSIONAL_SERVICES
            })
            .create()
            .getRecord();

        Test.startTest();
            List<RC_Quote_Template__c> foundTemplates = PDFTemplateHelper.getPdfTemplates(opp.Id, testMasterQuote.Id);
        Test.stopTest();
        System.assertEquals(1, foundTemplates.size(), 'Must be found one template');
        System.assertEquals(foundTemplates[0].Id, template.Id, 'Found template is different from the predefined one\'s');
    }
}