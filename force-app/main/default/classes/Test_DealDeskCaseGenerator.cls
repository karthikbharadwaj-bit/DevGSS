@IsTest
private class Test_DealDeskCaseGenerator {

    private static final String PACKAGE_INFO = '[{"id":"231","version":"1"}]';

    @IsTest
    static void verifyCaseGenerationForLBOAccountsForDownsellAndUpgrade() {
        Triggers.switchOff();

        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Feature_Toggle__c.EnableMultiProductUnifiedBilling__c => false,
                Feature_Toggle__c.EnableSimplifiedLBODownsell__c  => false
            })
            .create();

        NGBSLBOBillingLimits__c billingLimits = (NGBSLBOBillingLimits__c) new SObjectBuilder(NGBSLBOBillingLimits__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                NGBSLBOBillingLimits__c.Name => 'IBO-BAS',
                NGBSLBOBillingLimits__c.Categories__c => 'IBO-BAS',
                NGBSLBOBillingLimits__c.Quantity__c => 0,
                NGBSLBOBillingLimits__c.Manual_Upsell__c => true,
                NGBSLBOBillingLimits__c.Only_LBO__c => true
            })
            .create()
            .getRecord();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test acc',
                Account.Billing_ID__c => ValueProviderBuilder.provideUniqueString(),
                Account.RC_User_ID__c => ValueProviderBuilder.provideUniqueString(),
                Account.BillingStreet => '2078 Adamsville Road',
                Account.BillingCity => 'Laredo',
                Account.BillingPostalCode => '78040',
                Account.BillingState => 'Texas',
                Account.BillingCountry => 'United States',
                Account.EnabledLBO__c => true
            })
            .create()
            .getRecord();

        Contact cont = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.FirstName => 'Test2',
                Contact.LastName => 'Test2',
                Contact.AccountId => acc.Id,
                Contact.Email => 'test@test.com',
                Contact.Phone => '1234567890',
                Contact.Preferred_Language__c => 'en_US'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Name => 'Test1',
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
                Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                Opportunity.AccountId => acc.Id,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                Opportunity.CloseDate => system.today().addMonths(1),
                Opportunity.Primary_Opportunity_Contact__c => cont.Id,
                Opportunity.CurrencyIsoCode => RingCentralHelper.USD,
                Opportunity.IsAreaCodeCaseCreated__c => false,
                Opportunity.IsManualProvisionCaseCreated__c => false
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => ValueProviderBuilder.provideUniqueString('Test Billing Quote'),
                Quote.OpportunityId => opp.Id,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.Approved_Status__c => QuoteHelper.APPROVAL_STATUS_NOT_REQUIRED,
                Quote.Total_Number_of_Digital_Lines__c => 1,
                Quote.Start_Date__c => Date.today(),
                Quote.End_Date__c => Date.today().addDays(2),
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.Enabled_LBO__c => true,
                Quote.PackageNameNew__c => 'Test',
                Quote.LBODealDeskProvision__c => false,
                Quote.isPrimary__c => true
            })
            .create()
            .getRecord();

        List<Product2> products = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => ValueProviderBuilder.provideList(new List<String> {'DigitalLine','Additional Local Number', 'Compliance and Administrative Cost Recovery Fee', 'Polycom VVX501 with 1 Expansion Module', 'DigitalLine Basic', 'DigitalLine Unlimited','Additional Toll-Free Number', 'e911 Service Fee'}),
                Product2.ExtID__c => ValueProviderBuilder.provideList(new List<String> {'LC_DL_75','LC_ALN_38', 'LC_CRF_51', 'LC_HD_139', 'LC_DL-BAS_178', 'LC_DL-UNL_50','LC_ATN_39', 'LC_IBO-BAS_496'}),
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Product2.Family => ValueProviderBuilder.provideList(new List<String>{Product2Helper.FAMILY_TECHNICAL_LICENSE, Product2Helper.FAMILY_ADDONS, Product2Helper.FAMILY_FEE, Product2Helper.FAMILY_DISCOUNTED_PHONES, null}),
                Product2.IsActive => true
            })
            .quantity(8)
            .create()
            .getRecords();

        List<PricebookEntry> pbe = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.SObjectType)
            .quantity(8)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => ValueProviderBuilder.provideList(new List<Id>{products[0].Id, products[1].Id, products[2].Id, products[3].Id, products[4].Id, products[5].Id, products[6].Id, products[7].Id}),
                PricebookEntry.UnitPrice => 100,
                PricebookEntry.IsActive => true
            })
            .create()
            .getRecords();

        List<QuoteLineItem> qlis = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Product2Id => ValueProviderBuilder.provideList(new List<Id>{products[0].Id, products[1].Id, products[2].Id, products[3].Id, products[4].Id, products[5].Id, products[6].Id, products[7].Id}),
                QuoteLineItem.Quantity => ValueProviderBuilder.provideList(new List<Integer> {2, 5, 3, 10, 4, -3, 5, 6}),
                QuoteLineItem.NewQuantity__c => 10,
                QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideList(new List<Id> {pbe[0].Id, pbe[1].Id, pbe[2].Id, pbe[3].Id, pbe[4].Id, pbe[5].Id, pbe[6].Id, pbe[7].Id}),
                QuoteLineItem.UnitPrice => 10.00,
                QuoteLineItem.PackageInfo__c => ValueProviderBuilder.provideList(new List<String> {'{"categoryCode":"DL"}','{"categoryCode":"ALN"}', '{"categoryCode":"CRF"}', '{"categoryCode":"HD"}', '{"categoryCode":"DL-BAS"}', '{"categoryCode":"DL-UNL"}','{"categoryCode":"ATN"}', '{"categoryCode":"IBO-BAS"}'}),
                QuoteLineItem.Package_Info__c => ValueProviderBuilder.provideList(new List<String> {'{"categoryCode":"DL"}','{"categoryCode":"ALN"}', '{"categoryCode":"CRF"}', '{"categoryCode":"HD"}', '{"categoryCode":"DL-BAS"}', '{"categoryCode":"DL-UNL"}','{"categoryCode":"ATN"}', '{"categoryCode":"IBO-BAS"}'})
            })
            .quantity(8)
            .create()
            .getRecords();

        Area_Codes__c testAreaCode = (Area_Codes__c) new SObjectBuilder(Area_Codes__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Area_Codes__c.Country__c => 'United States',
                    Area_Codes__c.State__c => 'Texas',
                    Area_Codes__c.Area_Code__c => 100
                }
            )
            .create()
            .getRecord();

        List<Area_Code_Line_Item__c> areaCodeLineItems = new SObjectBuilder(Area_Code_Line_Item__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Area_Code_Line_Item__c.Quote_Line_Item__c => ValueProviderBuilder.provideList(
                    new List<Id>{qlis[0].Id, qlis[1].Id, qlis[2].Id, qlis[4].Id, qlis[5].Id, qlis[6].Id, qlis[7].Id}
                ),
                Area_Code_Line_Item__c.Area_Code__c => testAreaCode.Id,
                Area_Code_Line_Item__c.Quantity__c => ValueProviderBuilder.provideList(
                    new List<Decimal>{1,5,6}
                )
            }
            )
            .quantity(8)
            .create()
            .getRecords();

        NGBSSyncables.ISyncable syncable = NGBSSyncables.getSyncable(false, qt.Id, opp);

        Triggers.switchOn();
        Test.startTest();
        List<Quote> reselectQuote = new QuoteSelector()
            .selectQuoteForSyncWithNGBSByQuoteId(qt.Id).executeQuery();

        List<Opportunity> reselectOpp = new OpportunitySelector().selectOpportunityForSyncWithNGBS(opp.Id)
            .executeQuery();

        DealDeskCaseGenerator.createCase(reselectQuote[0], reselectOpp[0], false, CaseHelper.CASE_REASON_DOWNSELL, syncable);
        DealDeskCaseGenerator.createCase(reselectQuote[0], new Opportunity(), false, CaseHelper.CASE_REASON_CONVERTED_TO_PAID, syncable);
        DealDeskCaseGenerator.createCase(reselectQuote[0], new Opportunity(), true, CaseHelper.CASE_REASON_EXCEPTION, syncable);
        Test.stopTest();

        List<Opportunity> reselectOppAfterTest = new OpportunitySelector().selectOpportunityForSyncWithNGBS(opp.Id)
            .executeQuery();

        Assert.isFalse(reselectOppAfterTest[0].IsAreaCodeCaseCreated__c, 'IsAreaCodeCaseCreated must be false');
        Assert.isFalse(reselectOppAfterTest[0].IsManualProvisionCaseCreated__c, 'IsManualProvisionCaseCreated must be false');

        List<Case> cases = (List<Case>) new CaseSelector()
            .selectCases()
            .selectFields(new CaseSelector().getDetailFieldList())
            .executeQuery();

        System.assertEquals(3, cases.size(), 'List cases size must be 3');
        for (Case c : cases) {
            System.assertEquals(CaseHelper.RT_ID_DEALDESK_CASE, c.RecordTypeId, 'Case must be with "Sales Order Except Desk" record type');
            System.assertNotEquals(null, c.Description, 'Case must have description');
            if (c.Subject == DealDeskCaseGenerator.CASE_SUBJECT_AREA_CODES) {
                System.assertEquals(true, c.Description.contains('License: '), 'Case must have area codes in description');
                System.assertEquals(DealDeskCaseGenerator.CASE_SUBJECT_AREA_CODES, c.Subject, 'Case should have "LBO: Products for area code assignment" subject');
            }
            if (c.Subject == DealDeskCaseGenerator.CASE_SUBJECT_MANUAL_PROVISION) {
                System.assertNotEquals(null, c.Description, 'Case must have description');
                System.assertEquals(true, c.Description.contains('Product Name:'), 'Case must have product name in description');
                System.assertEquals(DealDeskCaseGenerator.CASE_SUBJECT_MANUAL_PROVISION + acc.Name, c.Subject, 'Incorrect Case subject');
            }
            if (c.Subject == DealDeskCaseGenerator.CASE_SUBJECT_UPGRADE_DOWNGRADE_PLANCHANGE_EXCEPTION) {
                System.assertNotEquals(null, c.Description, 'Case must have description');
                System.assertEquals(DealDeskCaseGenerator.CASE_SUBJECT_UPGRADE_DOWNGRADE_PLANCHANGE_EXCEPTION, c.Subject, 'Case should have "LBO : Manual Order Required for Quote" subject');
                if (c.Description.contains(CaseHelper.CASE_REASON_EXCEPTION)) {
                    System.assertEquals(true, c.Description.contains(CaseHelper.CASE_REASON_EXCEPTION), 'Case must have "Exception on Quote occurred" in description');
                }
                if (c.Description.contains(CaseHelper.CASE_REASON_CONVERTED_TO_PAID)) {
                    System.assertEquals(true, c.Description.contains(CaseHelper.CASE_REASON_CONVERTED_TO_PAID), 'Case must have "Quote is Converted to Paid" in description');
                }
                if (c.Description.contains(CaseHelper.CASE_REASON_DOWNSELL)) {
                    System.assertEquals(true, c.Description.contains(CaseHelper.CASE_REASON_DOWNSELL), 'Case must have "Quote contains Downsell" in description');
                }
            }
        }
    }

    @IsTest
    static void verifyCaseGenerationForLBOAccountsForManualProvisionAndAreaCodes() {
        Triggers.switchOff();
        NGBSLBOBillingLimits__c billingLimits = (NGBSLBOBillingLimits__c) new SObjectBuilder(NGBSLBOBillingLimits__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                NGBSLBOBillingLimits__c.Name => 'IBO-BAS',
                NGBSLBOBillingLimits__c.Categories__c => 'IBO-BAS',
                NGBSLBOBillingLimits__c.Quantity__c => 0,
                NGBSLBOBillingLimits__c.Manual_Upsell__c => true,
                NGBSLBOBillingLimits__c.Only_LBO__c => true
            })
            .create()
            .getRecord();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test acc',
                Account.Billing_ID__c => ValueProviderBuilder.provideUniqueString(),
                Account.RC_User_ID__c => ValueProviderBuilder.provideUniqueString(),
                Account.BillingStreet => '2078 Adamsville Road',
                Account.BillingCity => 'Laredo',
                Account.BillingPostalCode => '78040',
                Account.BillingState => 'Texas',
                Account.BillingCountry => 'United States',
                Account.EnabledLBO__c => true
            })
            .create()
            .getRecord();

        Contact cont = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.FirstName => 'Test2',
                Contact.LastName => 'Test2',
                Contact.AccountId => acc.Id,
                Contact.Email => 'test@test.com',
                Contact.Phone => '1234567890',
                Contact.Preferred_Language__c => 'en_US'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Name => 'Test1',
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
                Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                Opportunity.AccountId => acc.Id,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                Opportunity.CloseDate => system.today().addMonths(1),
                Opportunity.Primary_Opportunity_Contact__c => cont.Id,
                Opportunity.CurrencyIsoCode => RingCentralHelper.USD,
                Opportunity.IsAreaCodeCaseCreated__c => false,
                Opportunity.IsManualProvisionCaseCreated__c => false
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => ValueProviderBuilder.provideUniqueString('Test Billing Quote'),
                Quote.OpportunityId => opp.Id,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.Approved_Status__c => QuoteHelper.APPROVAL_STATUS_NOT_REQUIRED,
                Quote.Total_Number_of_Digital_Lines__c => 1,
                Quote.Start_Date__c => Date.today(),
                Quote.End_Date__c => Date.today().addDays(2),
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.Enabled_LBO__c => true,
                Quote.PackageNameNew__c => 'Test',
                Quote.LBODealDeskProvision__c => true,
                Quote.isPrimary__c => true
            })
            .create()
            .getRecord();

        List<Product2> products = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => ValueProviderBuilder.provideList(new List<String> {'DigitalLine','Additional Local Number', 'Compliance and Administrative Cost Recovery Fee', 'Polycom VVX501 with 1 Expansion Module', 'DigitalLine Basic', 'DigitalLine Unlimited','Additional Toll-Free Number', 'e911 Service Fee'}),
                Product2.ExtID__c => ValueProviderBuilder.provideList(new List<String> {'LC_DL_75','LC_ALN_38', 'LC_CRF_51', 'LC_HD_139', 'LC_DL-BAS_178', 'LC_DL-UNL_50','LC_ATN_39', 'LC_IBO-BAS_496'}),
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Product2.Family => ValueProviderBuilder.provideList(new List<String>{Product2Helper.FAMILY_TECHNICAL_LICENSE, Product2Helper.FAMILY_ADDONS, Product2Helper.FAMILY_FEE, Product2Helper.FAMILY_DISCOUNTED_PHONES, null}),
                Product2.IsActive => true
            })
            .quantity(8)
            .create()
            .getRecords();

        List<PricebookEntry> pbe = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.SObjectType)
            .quantity(8)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => ValueProviderBuilder.provideList(new List<Id>{products[0].Id, products[1].Id, products[2].Id, products[3].Id, products[4].Id, products[5].Id, products[6].Id, products[7].Id}),
                PricebookEntry.UnitPrice => 100,
                PricebookEntry.IsActive => true
            })
            .create()
            .getRecords();

        List<QuoteLineItem> qlis = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Product2Id => ValueProviderBuilder.provideList(new List<Id>{products[0].Id, products[1].Id, products[2].Id, products[3].Id, products[4].Id, products[5].Id, products[6].Id, products[7].Id}),
                QuoteLineItem.Quantity => ValueProviderBuilder.provideList(new List<Integer> {2, 5, 3, 10, 4, -3, 5, 6}),
                QuoteLineItem.NewQuantity__c => 10,
                QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideList(new List<Id> {pbe[0].Id, pbe[1].Id, pbe[2].Id, pbe[3].Id, pbe[4].Id, pbe[5].Id, pbe[6].Id, pbe[7].Id}),
                QuoteLineItem.UnitPrice => 10.00,
                QuoteLineItem.Package_Info_QLI__c => ValueProviderBuilder.provideList(new List<String> {'{"categoryCode":"DL"}','{"categoryCode":"ALN"}', '{"categoryCode":"CRF"}', '{"categoryCode":"HD"}', '{"categoryCode":"DL-BAS"}', '{"categoryCode":"DL-UNL"}','{"categoryCode":"ATN"}', '{"categoryCode":"IBO-BAS"}'}),
                QuoteLineItem.PackageInfo__c => ValueProviderBuilder.provideList(new List<String> {'{"categoryCode":"DL"}','{"categoryCode":"ALN"}', '{"categoryCode":"CRF"}', '{"categoryCode":"HD"}', '{"categoryCode":"DL-BAS"}', '{"categoryCode":"DL-UNL"}','{"categoryCode":"ATN"}', '{"categoryCode":"IBO-BAS"}'})
            })
            .quantity(8)
            .create()
            .getRecords();

        Area_Codes__c testAreaCode = (Area_Codes__c) new SObjectBuilder(Area_Codes__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Area_Codes__c.Country__c => 'United States',
                    Area_Codes__c.State__c => 'Texas',
                    Area_Codes__c.Area_Code__c => 100
                }
            )
            .create()
            .getRecord();

        List<Area_Code_Line_Item__c> areaCodeLineItems = new SObjectBuilder(Area_Code_Line_Item__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Area_Code_Line_Item__c.Quote_Line_Item__c => ValueProviderBuilder.provideList(
                    new List<Id>{qlis[0].Id, qlis[1].Id, qlis[2].Id, qlis[4].Id, qlis[5].Id, qlis[6].Id, qlis[7].Id}
                ),
                Area_Code_Line_Item__c.Area_Code__c => testAreaCode.Id,
                Area_Code_Line_Item__c.Quantity__c => ValueProviderBuilder.provideList(
                    new List<Decimal>{1,5,6}
                )
            }
            )
            .quantity(8)
            .create()
            .getRecords();

        NGBSSyncables.ISyncable syncable = NGBSSyncables.getSyncable(false, qt.Id, opp);

        Triggers.switchOn();
        Test.startTest();
            List<Quote> reselectQuote = new QuoteSelector()
                .selectQuoteForSyncWithNGBSByQuoteId(qt.Id).executeQuery();

            List<Opportunity> reselectOpp = new OpportunitySelector().selectOpportunityForSyncWithNGBS(opp.Id)
                .executeQuery();

            DealDeskCaseGenerator.createCase(reselectQuote[0], reselectOpp[0], false, null, syncable);
            DealDeskCaseGenerator.createCase(reselectQuote[0], new Opportunity(), true, CaseHelper.CASE_REASON_EXCEPTION, syncable);
        Test.stopTest();

        List<Opportunity> reselectOppAfterTest = new OpportunitySelector().selectOpportunityForSyncWithNGBS(opp.Id)
            .executeQuery();

        Assert.isTrue(reselectOppAfterTest[0].IsAreaCodeCaseCreated__c, 'IsAreaCodeCaseCreated must be true');
        Assert.isTrue(reselectOppAfterTest[0].IsManualProvisionCaseCreated__c, 'IsManualProvisionCaseCreated must be true');

        List<Case> cases = (List<Case>) new CaseSelector()
            .selectCases()
            .selectFields(new CaseSelector().getDetailFieldList())
            .executeQuery();

        System.assertEquals(3, cases.size(), 'List cases size must be 3');
        for (Case c : cases) {
            System.assertEquals(CaseHelper.RT_ID_DEALDESK_CASE, c.RecordTypeId, 'Case must be with "Sales Order Except Desk" record type');
            System.assertNotEquals(null, c.Description, 'Case must have description');
            if (c.Subject == DealDeskCaseGenerator.CASE_SUBJECT_AREA_CODES) {
                System.assertEquals(true, c.Description.contains('License: '), 'Case must have area codes in description');
                System.assertEquals(DealDeskCaseGenerator.CASE_SUBJECT_AREA_CODES, c.Subject, 'Case should have "LBO: Products for area code assignment" subject');
            }
            if (c.Subject == DealDeskCaseGenerator.CASE_SUBJECT_MANUAL_PROVISION) {
                System.assertNotEquals(null, c.Description, 'Case must have description');
                System.assertEquals(true, c.Description.contains('Product Name:'), 'Case must have product name in description');
                System.assertEquals(DealDeskCaseGenerator.CASE_SUBJECT_MANUAL_PROVISION + acc.Name, c.Subject, 'Incorrect Case subject');
            }
            if (c.Subject == DealDeskCaseGenerator.CASE_SUBJECT_UPGRADE_DOWNGRADE_PLANCHANGE_EXCEPTION) {
                System.assertNotEquals(null, c.Description, 'Case must have description');
                System.assertEquals(DealDeskCaseGenerator.CASE_SUBJECT_UPGRADE_DOWNGRADE_PLANCHANGE_EXCEPTION, c.Subject, 'Case should have "LBO : Manual Order Required for Quote" subject');
                if (c.Description.contains(CaseHelper.CASE_REASON_EXCEPTION)) {
                    System.assertEquals(true, c.Description.contains(CaseHelper.CASE_REASON_EXCEPTION), 'Case must have "Exception on Quote occurred" in description');
                }
                if (c.Description.contains(CaseHelper.CASE_REASON_CONVERTED_TO_PAID)) {
                    System.assertEquals(true, c.Description.contains(CaseHelper.CASE_REASON_CONVERTED_TO_PAID), 'Case must have "Quote is Converted to Paid" in description');
                }
                if (c.Description.contains(CaseHelper.CASE_REASON_DOWNSELL)) {
                    System.assertEquals(true, c.Description.contains(CaseHelper.CASE_REASON_DOWNSELL), 'Case must have "Quote contains Downsell" in description');
                }
            }
        }
    }

    @IsTest
    static void verifyCaseGenerationForPhoenixAccounts() {
        NGBS_Phoenix_Settings__c phoenixSettings = (NGBS_Phoenix_Settings__c) new SObjectBuilder(NGBS_Phoenix_Settings__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                NGBS_Phoenix_Settings__c.NGBSPhoenixAvailableBrands__c => 'RingCentral;RingCentral Canada;RingCentral AU;RingCentral UK;RingCentral EU; Unify Office;',
                NGBS_Phoenix_Settings__c.NGBSPhoenixAvailablePackageIDs__c => '666;210;260;220;230;231;240;241;250;251;510;',
                NGBS_Phoenix_Settings__c.NGBSPhoenixAvailableProducts__c => 'RC Meetings;Meetings;'
            })
            .create()
            .getRecord();

        Triggers.switchOff();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test acc',
                Account.Billing_ID__c => ValueProviderBuilder.provideUniqueString(),
                Account.RC_User_ID__c => ValueProviderBuilder.provideUniqueString(),
                Account.BillingStreet => '2078 Adamsville Road',
                Account.BillingCity => 'Laredo',
                Account.BillingPostalCode => '78040',
                Account.BillingState => 'Texas',
                Account.BillingCountry => 'United States'
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        Contact cont = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.FirstName => 'Test2',
                Contact.LastName => 'Test2',
                Contact.AccountId => acc.Id,
                Contact.Email => 'test@test.com',
                Contact.Phone => '1234567890',
                Contact.Preferred_Language__c => 'en_US'
            })
            .create()
            .getRecord();

        Opportunity opportunity = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Name => 'Test1',
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
                Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                Opportunity.AccountId => acc.Id,
                Opportunity.Tier_Name__c => OpportunityHelper.TIER_RC_MEETINGS,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                Opportunity.CloseDate => system.today().addMonths(1),
                Opportunity.Primary_Opportunity_Contact__c => cont.Id,
                Opportunity.CurrencyIsoCode => RingCentralHelper.USD
            })
            .create()
            .getRecord();

        Quote quote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => ValueProviderBuilder.provideUniqueString('Test Billing Quote'),
                Quote.OpportunityId => opportunity.Id,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.Approved_Status__c => QuoteHelper.APPROVAL_STATUS_NOT_REQUIRED,
                Quote.Total_Number_of_Digital_Lines__c => 1,
                Quote.Start_Date__c => Date.today(),
                Quote.End_Date__c => Date.today().addDays(2),
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Package_Info__c => PACKAGE_INFO,
                Quote.PackageNameNew__c => 'Test',
                Quote.Pricebook2Id => Test.getStandardPricebookId()
            })
            .create()
            .getRecord();

        List<Quote> reselectQuote = new QuoteSelector().selectQuoteForSyncWithNGBSByQuoteId(quote.Id)
                .executeQuery();
        List<Opportunity> reselectOpp = new OpportunitySelector().selectOpportunityForSyncWithNGBS(opportunity.Id)
                .executeQuery();

        NGBSSyncables.ISyncable syncable = NGBSSyncables.getSyncable(false, reselectQuote[0].Id, reselectOpp[0]);
        Test.startTest();
        DealDeskCaseGenerator.createCase(reselectQuote[0], reselectOpp[0], false, CaseHelper.CASE_REASON_CONVERTED_TO_PAID, syncable);
        Test.stopTest();

        List<Case> cases = (List<Case>) new CaseSelector()
                .selectCases()
                .selectFields(new CaseSelector().getDetailFieldList())
                .executeQuery();

        System.assertEquals(1, cases.size(), 'List cases size must be 1');
        System.assertEquals(CaseHelper.RT_ID_DEALDESK_CASE, cases[0].RecordTypeId, 'Case must be with ' + CaseHelper.RT_NAME_DEALDESK + ' record type');
        System.assertNotEquals(null, cases[0].Description, 'Case must have description');
        String urlToAccount = String.format(DealDeskCaseGenerator.URL_TO_ACCOUNT_TEMPLATE, new List<String>{acc.Id});
        System.assert(cases[0].Description.contains(urlToAccount), 'Case description should contain url to account record');
        String urlToOpportunity = String.format(DealDeskCaseGenerator.URL_TO_OPPORTUNITY_TEMPLATE, new List<String>{opportunity.Id});
        System.assert(cases[0].Description.contains(urlToOpportunity), 'Case description should contain url to opportunity record');
        System.assertEquals('RingCentral Video: ' + DealDeskCaseGenerator.CASE_SUBJECT_UPGRADE_DOWNGRADE_PLANCHANGE_EXCEPTION, cases[0].Subject, 'Case should have "Phoenix: Manual Order Required for Quote" subject');
    }

    @isTest
    private static void testCreateCaseForManualProvisioningMPUB() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Feature_Toggle__c.EnableMultiProductUnifiedBilling__c => true
            })
            .create();

        DealDeskCaseGenerator.sortedMPUBProvisioningCaseTemplateConfigList = new SObjectBuilder(NGBSProcessOrderCaseTemplate__mdt.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                NGBSProcessOrderCaseTemplate__mdt.Id => ValueProviderBuilder.provideDummyId(NGBSProcessOrderCaseTemplate__mdt.SObjectType),
                NGBSProcessOrderCaseTemplate__mdt.IsActive__c => true,
                NGBSProcessOrderCaseTemplate__mdt.Type__c => DealDeskCaseGenerator.PROVISIONING_CASE_TEMPLATE_TYPE,
                NGBSProcessOrderCaseTemplate__mdt.Instruction__c => ValueProviderBuilder.provideList(new List<String>{
                    'default provisioning',
                    'specific provisioning'
                }),
                NGBSProcessOrderCaseTemplate__mdt.LicenceIdOrCategoryCode__c => ValueProviderBuilder.provideList(
                    new List<String>{
                        '',
                        'license_1;license_2'
                    }
                )
            })
            .quantity(2)
            .build()
            .getRecords();

        Triggers.switchOff();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Manual Provisioning Case Test Account')
            .quantity(1)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Manual Provisioning Case Test Opportunity')
            .setField(Opportunity.AccountId, acc.Id)
            .setField(Opportunity.Tier_Name__c, QuoteHelper.NGBS_OFFICE_PRODUCT)
            .setField(Opportunity.Brand_Name__c, OpportunityHelper.BRAND_RINGCENTRAL)
            .setField(Opportunity.Type, OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS)
            .setField(Opportunity.RecordTypeId, OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY)
            .setField(Opportunity.StageName, OpportunityHelper.STAGE_NAME_QUALIFY)
            .setField(Opportunity.CloseDate, System.today())
            .setField(Opportunity.CurrencyIsoCode, RingCentralHelper.USD)
            .quantity(1)
            .create()
            .getRecord();

        Package__c pkg = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Package__c.Account__c => acc.Id,
                    Package__c.Account_Package_Id__c => '1231231231'
                }
            )
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setField(Quote.Name, 'Manual Provisioning Case Test Quote')
            .setField(Quote.OpportunityId, opp.Id)
            .setField(Quote.CurrencyIsoCode, RingCentralHelper.USD)
            .setField(Quote.Pricebook2Id, Test.getStandardPricebookId())
            .setField(Quote.isPrimary__c, true)
            .setField(Quote.Upsell_Status__c, QuoteHelper.STATUS_UPSELL)
            .setField(Quote.BillingPackage__c, pkg.Id)
            .setField(Quote.IsMultiProductTechnicalQuote__c, false)
            .setField(Quote.Package_Info__c, NGBSTestDataGenerator.generateQuotePackageInfo())
            .quantity(1)
            .create()
            .getRecord();

        List<Product2> prodList = (List<Product2>) new SObjectBuilder(Product2.sObjectType)
            .setField(Product2.Name, ValueProviderBuilder.provideList(new List<String>{'Product_1', 'Product_2', 'Product_3', 'Product_4'}))
            .setField(Product2.ExtID__c, ValueProviderBuilder.provideList(new List<String>{'license_1', 'TEST_2', 'TEST_3', 'TEST_4'}))
            .setField(Product2.Sub_Category__c, Product2Helper.SUBCATEGORY_RINGCENTRAL)
            .setField(Product2.IsActive, true)
            .setField(Product2.Charge_Term__c, Product2Helper.CHARGE_TERM_MONTHLY)
            .setField(Product2.UpsellType__c, ValueProviderBuilder.provideList(
                new List<String>{
                    Product2Helper.PRODUCT_PROVISIONING_TYPE_AUTO_WITH_CASE,
                    'manual',
                    'testUpsellType',
                    null
                }
            ))
            .quantity(4)
            .create()
            .getRecords();

        List<PricebookEntry> pbeList = new SObjectBuilder(PricebookEntry.SObjectType)
            .setField(PricebookEntry.Pricebook2Id, Test.getStandardPricebookId())
            .setField(PricebookEntry.Product2Id, ValueProviderBuilder.provideParents(prodList))
            .setField(PricebookEntry.UnitPrice, 10)
            .setField(PricebookEntry.IsActive, true)
            .setField(PricebookEntry.UseStandardPrice, false)
            .setField(PricebookEntry.CurrencyIsoCode, 'USD')
            .quantity(4)
            .create()
            .getRecords();

        List<QuoteLineItem> qliList = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setField(QuoteLineItem.QuoteId, qt.Id)
            .setField(QuoteLineItem.Display_Name__c, ValueProviderBuilder.provideUniqueString())
            .setField(QuoteLineItem.Product2Id, ValueProviderBuilder.provideParents(prodList))
            .setField(QuoteLineItem.PricebookEntryId, ValueProviderBuilder.provideParents(pbeList))
            .setField(QuoteLineItem.Quantity, 5)
            .setField(QuoteLineItem.ChargeTerm__c, QuoteLineItemHelper.CHARGE_TERM_MONTHLY)
            .setField(QuoteLineItem.UnitPrice, 10)
            .setField(QuoteLineItem.IsMultiProductTechnicalQLI__c, false)
            .setField(QuoteLineItem.Zero_Quantity__c, false)
            .quantity(4)
            .create()
            .getRecords();

        List<Order> orderList = (List<Order> ) new SObjectBuilder(Order.SObjectType)
            .setField(Order.AccountId, acc.Id)
            .setField(Order.QuoteId, qt.Id)
            .setField(Order.OpportunityId, opp.Id)
            .setField(Order.Pricebook2Id, Test.getStandardPricebookId())
            .setField(Order.EffectiveDate, System.today())
            .setField(Order.Status, OrderHelper.STATUS_NEW)
            .setField(Order.NumberOfMainLicenses__c, 25)
            .setField(Order.TechnicalAccountId__c, acc.Id)
            .setField(Order.TechnicalOpportunityId__c, opp.Id)
            .setField(Order.TechnicalQuoteId__c, qt.Id)
            .setField(Order.Provisioning__c, ValueProviderBuilder.provideList(
                new List<String>{
                    OrderHelper.PROVISIONING_AUTO,
                    OrderHelper.PROVISIONING_MANUAL
                }
            ))
            .quantity(2)
            .create()
            .getRecords();

        List<OrderItem> orderItemList = (List<OrderItem>) new SObjectBuilder(OrderItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                OrderItem.OrderId => ValueProviderBuilder.provideParents(orderList),
                OrderItem.PricebookEntryId => ValueProviderBuilder.provideParents(pbeList),
                OrderItem.Quantity => ValueProviderBuilder.providerRandomDecimal(1, 10, 0),
                OrderItem.UnitPrice => ValueProviderBuilder.providerRandomDecimal(1, 1000, 2),
                OrderItem.QuoteLineItemId => ValueProviderBuilder.provideParents(qliList)
            })
            .quantity(4)
            .create()
            .getRecords();
        Triggers.switchOn();

        List<Order> reselectedOrders = (List<Order>) new OrderSelector()
            .selectOrdersByTechQuoteIdsForManualProvisioningCaseCreationProcessMPUB(new Set<Id>{qt.Id})
            .executeQuery();

        Test.startTest();
        DealDeskCaseGenerator.createCaseForManualProvisioningMPUB(reselectedOrders);
        Test.stopTest();

        List<Case> caseList = (List<Case>) new CaseSelector()
            .newQueryFactory()
            .selectFields(new List<String>{ 'Id', 'Subject', 'Description' })
            .setCondition('Subject = :bind0')
            .setQueryBindings(new List<Object>{ DealDeskCaseGenerator.CASE_SUBJECT_MANUAL_PROVISION_MPUB })
            .executeQuery();

        Assert.areEqual(1, caseList.size(), 'createCaseForManualProvisioningMPUB method should properly create manual provisioning case');
        Assert.areEqual(true, caseList[0].Description.contains('default provisioning'), 'the case should contain the default provisioning instruction');
        Assert.areEqual(true, caseList[0].Description.contains('specific provisioning'), 'the case should contain the specific provisioning instruction');
        Assert.areEqual(true, caseList[0].Description.contains('Product_1'), 'Product_1 should be in the case description as it has AutoWithCase upsell type');
        Assert.areEqual(true, caseList[0].Description.contains('Product_2'), 'Product_2 should be in the case description as it has manual upsell type');
        Assert.areEqual(true, caseList[0].Description.contains('Product_3'), 'Product_3 should be in the case description as it has another populated upsell type');
        Assert.areEqual(false, caseList[0].Description.contains('Product_4'), 'Product_4 should NOT be in the case description as it has empty upsell type');
    }

    @isTest
    private static void testCreateSimplifiedLBODownsellCaseFromQuote() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Feature_Toggle__c.EnableMultiProductUnifiedBilling__c => true
            })
            .create();

        DealDeskCaseGenerator.sortedSimplifiedLBODownsellCaseTemplateConfigList = new SObjectBuilder(NGBSProcessOrderCaseTemplate__mdt.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                NGBSProcessOrderCaseTemplate__mdt.Id => ValueProviderBuilder.provideDummyId(NGBSProcessOrderCaseTemplate__mdt.SObjectType),
                NGBSProcessOrderCaseTemplate__mdt.IsActive__c => true,
                NGBSProcessOrderCaseTemplate__mdt.Type__c => ValueProviderBuilder.provideList(new List<String>{
                    DealDeskCaseGenerator.DOWNSELL_CASE_TEMPLATE_TYPE,
                    DealDeskCaseGenerator.DOWNSELL_CASE_TEMPLATE_TYPE,
                    DealDeskCaseGenerator.DEPROVISIONING_CASE_TEMPLATE_TYPE,
                    DealDeskCaseGenerator.DEPROVISIONING_CASE_TEMPLATE_TYPE
                }),
                NGBSProcessOrderCaseTemplate__mdt.Instruction__c => ValueProviderBuilder.provideList(new List<String>{
                    'default downsell',
                    'specific downsell',
                    'default deprovisioning',
                    'specific deprovisioning'
                }),
                NGBSProcessOrderCaseTemplate__mdt.LicenceIdOrCategoryCode__c => ValueProviderBuilder.provideList(
                    new List<String>{
                        '',
                        'license_1;license_2;license_4;license_5;license_6;license_7',
                        '',
                        'license_1;license_2;license_4;license_5;license_6;license_7'
                    }
                )
            })
            .quantity(4)
            .build()
            .getRecords();

        Triggers.switchOff();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test acc',
                Account.Billing_ID__c => ValueProviderBuilder.provideUniqueString(),
                Account.RC_User_ID__c => ValueProviderBuilder.provideUniqueString(),
                Account.BillingStreet => '2078 Adamsville Road',
                Account.BillingCity => 'Laredo',
                Account.BillingPostalCode => '78040',
                Account.BillingState => 'Texas',
                Account.BillingCountry => 'United States',
                Account.EnabledLBO__c => true
            })
            .create()
            .getRecord();

        Contact cont = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.FirstName => 'Test2',
                Contact.LastName => 'Test2',
                Contact.AccountId => acc.Id,
                Contact.Email => 'test@test.com',
                Contact.Phone => '1234567890',
                Contact.Preferred_Language__c => 'en_US'
            })
            .create()
            .getRecord();

        Opportunity opportunity = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Name => 'Test1',
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
                Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                Opportunity.AccountId => acc.Id,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                Opportunity.CloseDate => system.today().addMonths(1),
                Opportunity.Primary_Opportunity_Contact__c => cont.Id,
                Opportunity.CurrencyIsoCode => RingCentralHelper.USD,
                Opportunity.IsAreaCodeCaseCreated__c => false,
                Opportunity.IsManualProvisionCaseCreated__c => false
            })
            .create()
            .getRecord();

        Quote quote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => ValueProviderBuilder.provideUniqueString('Test Billing Quote'),
                Quote.OpportunityId => opportunity.Id,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.Approved_Status__c => QuoteHelper.APPROVAL_STATUS_NOT_REQUIRED,
                Quote.Total_Number_of_Digital_Lines__c => 1,
                Quote.Start_Date__c => Date.today(),
                Quote.End_Date__c => Date.today().addDays(2),
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.Enabled_LBO__c => true,
                Quote.PackageNameNew__c => 'Test',
                Quote.LBODealDeskProvision__c => true,
                Quote.isPrimary__c => true
            })
            .create()
            .getRecord();

        List<Product2> products = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => ValueProviderBuilder.provideList(new List<String> {'Product_1', 'Product_2', 'Product_3', 'Product_4', 'Product_5', 'Product_6','Product_7', 'Product_8'}),
                Product2.ExtID__c => ValueProviderBuilder.provideList(new List<String> {'license_1','license_2', 'license_3', 'license_4', 'license_5', 'license_6','license_7', 'license_8'}),
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Product2.Family => ValueProviderBuilder.provideList(new List<String>{Product2Helper.FAMILY_TECHNICAL_LICENSE, Product2Helper.FAMILY_ADDONS, Product2Helper.FAMILY_FEE, Product2Helper.FAMILY_DISCOUNTED_PHONES, null}),
                Product2.IsActive => true
            })
            .quantity(8)
            .create()
            .getRecords();

        List<PricebookEntry> pbe = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => ValueProviderBuilder.provideList(new List<Id>{products[0].Id, products[1].Id, products[2].Id, products[3].Id, products[4].Id, products[5].Id, products[6].Id, products[7].Id}),
                PricebookEntry.UnitPrice => 100,
                PricebookEntry.IsActive => true
            })
            .quantity(8)
            .create()
            .getRecords();

        List<QuoteLineItem> qlis = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => quote.Id,
                QuoteLineItem.Product2Id => ValueProviderBuilder.provideList(new List<Id>{products[0].Id, products[1].Id, products[2].Id, products[3].Id, products[4].Id, products[5].Id, products[6].Id, products[7].Id}),
                QuoteLineItem.Quantity => ValueProviderBuilder.provideList(new List<Integer> {-2, -5, -3, 10, -4, -3, -5, -6}),
                QuoteLineItem.Discount => ValueProviderBuilder.provideList(new List<Decimal> {20.123, 50.321, 3.555, 10.6, 4, 3, 5.55, 6}),
                QuoteLineItem.Discount_type__c => ValueProviderBuilder.provideList(new List<String> {'Currency', 'Currency', 'Currency', 'Currency', 'Percentage', 'Percentage', 'Percentage', 'Percentage'}),
                QuoteLineItem.Discount_number__c => ValueProviderBuilder.provideList(new List<Decimal> {1.234, 2.345, 3.456, 4.567, 5.678, 6.789, 7.899, 8.999}),
                QuoteLineItem.NewQuantity__c => 10,
                QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideList(new List<Id> {pbe[0].Id, pbe[1].Id, pbe[2].Id, pbe[3].Id, pbe[4].Id, pbe[5].Id, pbe[6].Id, pbe[7].Id}),
                QuoteLineItem.UnitPrice => 10.00,
                QuoteLineItem.Package_Info_QLI__c => ValueProviderBuilder.provideList(new List<String> {'{"categoryCode":"DL"}','{"categoryCode":"ALN"}', '{"categoryCode":"CRF"}', '{"categoryCode":"HD"}', '{"categoryCode":"DL-BAS"}', '{"categoryCode":"DL-UNL"}','{"categoryCode":"ATN"}', '{"categoryCode":"IBO-BAS"}'}),
                QuoteLineItem.PackageInfo__c => ValueProviderBuilder.provideList(new List<String> {'{"categoryCode":"DL"}','{"categoryCode":"ALN"}', '{"categoryCode":"CRF"}', '{"categoryCode":"HD"}', '{"categoryCode":"DL-BAS"}', '{"categoryCode":"DL-UNL"}','{"categoryCode":"ATN"}', '{"categoryCode":"IBO-BAS"}'})
            })
            .quantity(8)
            .create()
            .getRecords();

        Area_Codes__c testAreaCode = (Area_Codes__c) new SObjectBuilder(Area_Codes__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Area_Codes__c.Country__c => 'United States',
                    Area_Codes__c.State__c => 'Texas',
                    Area_Codes__c.Area_Code__c => 100
                }
            )
            .create()
            .getRecord();

        List<Area_Code_Line_Item__c> areaCodeLineItems = new SObjectBuilder(Area_Code_Line_Item__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Area_Code_Line_Item__c.Quote_Line_Item__c => ValueProviderBuilder.provideList(
                    new List<Id>{qlis[0].Id, qlis[1].Id, qlis[2].Id, qlis[4].Id, qlis[5].Id, qlis[6].Id, qlis[7].Id}
                ),
                Area_Code_Line_Item__c.Area_Code__c => testAreaCode.Id,
                Area_Code_Line_Item__c.Quantity__c => ValueProviderBuilder.provideList(
                    new List<Decimal>{1,5,6}
                )
            }
            )
            .quantity(8)
            .create()
            .getRecords();

        Triggers.switchOn();

        Test.startTest();
            List<Quote> reselectQuote = new QuoteSelector()
                .selectQuoteForSyncWithNGBSByQuoteId(quote.Id).executeQuery();
            Map<String, QuoteLineItem> licenseIdToQli = new Map<String, QuoteLineItem>();
            for (QuoteLineItem qli : reselectQuote[0].QuoteLineItems) {
                licenseIdToQli.put(qli.Product2.ExtID__c, qli);
            }

            Map<String, List<QuoteLineItem>> qlisForCaseCreationMap = new Map<String, List<QuoteLineItem>>{
                SWNHelper.DOWNSELL_TYPE_AUTO => new List<QuoteLineItem>{licenseIdToQli.get('license_1'), licenseIdToQli.get('license_2')},
                SWNHelper.DOWNSELL_TYPE_AUTO_WITH_CASE => new List<QuoteLineItem>{licenseIdToQli.get('license_3'), licenseIdToQli.get('license_4')},
                SWNHelper.DOWNSELL_TYPE_MANUAL => new List<QuoteLineItem>{licenseIdToQli.get('license_5'), licenseIdToQli.get('license_6')},
                SWNHelper.DOWNSELL_TYPE_EXCEPTION => new List<QuoteLineItem>{licenseIdToQli.get('license_7'), licenseIdToQli.get('license_8')}
            };

            DealDeskCaseGenerator.createSimplifiedLBODownsellCaseFromQuote(reselectQuote[0], qlisForCaseCreationMap);
        Test.stopTest();

        List<Case> caseList = (List<Case>) new CaseSelector()
            .newQueryFactory()
            .selectFields(new List<String>{ 'Id', 'Subject', 'Description' })
            .setCondition('Subject = :bind0')
            .setQueryBindings(new List<Object>{ DealDeskCaseGenerator.CASE_SUBJECT_DOWNSELL_SIMPLIFIED_LBO })
            .executeQuery();

        Assert.areEqual(1, caseList.size(), 'createSimplifiedLBODownsellCaseFromQuote method should properly create simplified LBO downsell case');
        Assert.areEqual(true, caseList[0].Description.contains('default downsell'), 'the case should contain the default downsell instruction');
        Assert.areEqual(true, caseList[0].Description.contains('specific downsell'), 'the case should contain the specific downsell instruction');
        Assert.areEqual(true, caseList[0].Description.contains('default deprovisioning'), 'the case should contain the default deprovisioning instruction');
        Assert.areEqual(true, caseList[0].Description.contains('specific deprovisioning'), 'the case should contain the specific deprovisioning instruction');

        Assert.areEqual(false, caseList[0].Description.contains('Product_1'), 'Product_1 should NOT be in the case description as it is in Auto type');
        Assert.areEqual(false, caseList[0].Description.contains('Product_2'), 'Product_2 should NOT be in the case description as it is in Auto type');

        Assert.areEqual(true, caseList[0].Description.contains('Product_3'), 'Product_3 should be in the case description');
        Assert.areEqual(true, caseList[0].Description.contains('Product_5'), 'Product_5 should be in the case description');
        Assert.areEqual(true, caseList[0].Description.contains('Product_7'), 'Product_7 should be in the case description');
    }
}