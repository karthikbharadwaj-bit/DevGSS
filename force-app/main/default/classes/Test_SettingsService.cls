@isTest
private class Test_SettingsService {

    static final Set<String> AVAILABLE_DESCRIPTION_IDS = new Set<String>{
        'LC_IBO_288', 'LC_IBO_284', 'LC_IBO_290', 'LC_IBO_292', 'LC_IBO_286',
        'LC_ILN_61', 'LC_ILN_389', 'LC_ILN_390', 'LC_ILN_392',
        'LC_ITN_62', 'LC_ITN_578', 'LC_ITN_580'
    };

    private static Opportunity attachAccountToOpportunity(Opportunity oppty, Account acc) {
        Map<String, Object> opptyMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(oppty));
        opptyMap.put('Account', acc);
        return (Opportunity) JSON.deserialize(JSON.serialize(opptyMap), Opportunity.class);
    }

    @TestSetup
    private static void setup() {

        List<NGBSHiddenLicenses__c> hiddenLicenseList = new List<NGBSHiddenLicenses__c>();
        hiddenLicenseList.add(
                new NGBSHiddenLicenses__c(
                        Name = '1', IsHidden__c = true, LicenseElementId__c = '1', ShowLicenseName__c = true,
                        AffectedPackage__c = 'All'
                ));
        hiddenLicenseList.add(
                new NGBSHiddenLicenses__c(
                        Name = '2', IsHidden__c = true, LicenseElementId__c = '2', ShowLicenseName__c = true,
                        AllowedDiscountType__c = 'All'
                ));
        hiddenLicenseList.add(
                new NGBSHiddenLicenses__c(
                        Name = '3', IsHidden__c = true, LicenseElementId__c = '3', ShowLicenseName__c = true,
                        AffectedPackage__c = '3', AllowedDiscountType__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY
                ));
        hiddenLicenseList.add(
                new NGBSHiddenLicenses__c(
                        Name = '4', NotAvailableWithRCV__c = true, LicenseElementId__c = '4;5;6'
                ));

        hiddenLicenseList.add(
                new NGBSHiddenLicenses__c(
                        Name = '5', UnAvailableForLBO__c = true, LicenseElementId__c = 'LC_VF_42;LC_T800F_41'
                ));

        hiddenLicenseList.add(
                new NGBSHiddenLicenses__c(
                        Name = '6', NotAvailableForPRM__c = true, LicenseElementId__c = 'LC_HD_522'
                ));

        insert hiddenLicenseList;

        List<NGBSOpptyPageLicenses__c> enabledOpptyLicenses = (List<NGBSOpptyPageLicenses__c>) new SObjectBuilder(NGBSOpptyPageLicenses__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                NGBSOpptyPageLicenses__c.Name => ValueProviderBuilder.provideList(new List<String>{'1','2','3'}),
                NGBSOpptyPageLicenses__c.ElementId__c => ValueProviderBuilder.provideList(new List<String>{'1;1_1','2','3'}),
                NGBSOpptyPageLicenses__c.ShowChildren__c => ValueProviderBuilder.provideList(new List<Boolean>{true,false,true}),
                NGBSOpptyPageLicenses__c.AffectedPackage__c => ValueProviderBuilder.provideList(new List<String>{'All','All','3'})
            })
            .quantity(3)
            .create()
            .getRecords();

        Funnel_Limits__c funnelLimits = (Funnel_Limits__c) new SObjectBuilder(Funnel_Limits__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Funnel_Limits__c.Name => 'Test',
                Funnel_Limits__c.Categories__c => 'DL DL-UNL',
                Funnel_Limits__c.Quantity__c => 22
            })
            .create()
            .getRecord();

        new SObjectBuilder(ICB_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                ICB_Settings__c.FormLink__c => 'https://test-form-link.com'
            })
            .create();

        Triggers.switchOff();
        Account partnerAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => ValueProviderBuilder.provideUniqueString('Test Partner Account'),
                Account.BillingCity => 'Louisville',
                Account.BillingStreet => '457 Gregory Lane',
                Account.BillingState => 'KY',
                Account.BillingCountry => 'United States',
                Account.BillingPostalCode => '40202',
                Account.CurrencyIsoCode => 'USD',
                Account.RC_User_Id__c => '',
                Account.Billing_ID__c => '',
                Account.RC_Account_Status__c => '',
                Account.Permitted_Brands__c => 'RingCentral',
                Account.Type => 'Partner',
                Account.Partner_ID__c => ValueProviderBuilder.provideUniqueString('10000'),
                Account.RC_Brand__c => 'RingCentral'
            })
            .create()
            .getRecord();

        Contact partnerAccountContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.AccountId => partnerAccount.Id,
                Contact.FirstName => ValueProviderBuilder.provideUniqueString('FirstName'),
                Contact.LastName => ValueProviderBuilder.provideUniqueString('LastName'),
                Contact.Email => ValueProviderBuilder.provideUniqueEmail('firstname.lastname', '@example.tld'),
                Contact.Phone => '(679) 643-1565',
                Contact.CurrencyIsoCode => 'USD',
                Contact.Preferred_Language__c => 'en_GB'
            })
            .create()
            .getRecord();

        List<Lead> leads = (List<Lead>) new SObjectBuilder(Lead.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                        Lead.RecordTypeId => ValueProviderBuilder.provideList(new List<Object> {
                                LeadHelper.RT_ID_SALES_LEADS,
                                LeadHelper.RT_ID_PARTNER_LEADS
                        }),
                        Lead.FirstName => ValueProviderBuilder.provideUniqueString('FirstName'),
                        Lead.LastName => ValueProviderBuilder.provideUniqueString('LastName'),
                        Lead.Company => ValueProviderBuilder.provideUniqueString('Company'),
                        Lead.CurrencyIsoCode => 'USD',
                        Lead.Industry => 'Communications',
                        Lead.Email => ValueProviderBuilder.provideList(new List<Object> {
                                'sales.lead@example.tld',
                                'partner.lead@example.tld'
                        }),
                        Lead.LeadSource => ValueProviderBuilder.provideList(new List<Object> {
                                'Inbound Call',
                                'Partner'
                        }),
                        Lead.First_Lead_Source__c => ValueProviderBuilder.provideList(new List<Object> {
                                'Inbound Call',
                                'Partner'
                        }),
                        Lead.Partner_Lead_Source__c => ValueProviderBuilder.provideList(new List<Object> {
                                'Inbound Call',
                                'Partner'
                        }),
                        Lead.RC_Record_Type__c => ValueProviderBuilder.provideList(new List<Object> {
                                'Sales',
                                'Partner'
                        }),
                        Lead.Lead_Brand_Name__c => RingCentralHelper.BRAND_RINGCENTRAL,
                        Lead.Lead_Tier_Name__c => 'Office',
                        Lead.NumberOfEmployees__c => '1-19',
                        Lead.Number_of_Locations__c => '1',
                        Lead.Estimated_Close_Date__c => Date.today(),
                        Lead.Partner_Contact__c => ValueProviderBuilder.provideList(new List<Object> {
                                null,
                                partnerAccountContact.Id
                        }),
                        Lead.Ultimate_Parent_Account_Partner_ID__c => ValueProviderBuilder.provideList(new List<Object> {
                                null,
                                partnerAccountContact.User_Id__c
                        }),
                        Lead.LeadPartnerId__c => ValueProviderBuilder.provideList(new List<Object> {
                                null,
                                partnerAccountContact.User_Id__c
                        }),
                        Lead.Partner_Account__c => ValueProviderBuilder.provideList(new List<Object> {
                                null,
                                partnerAccount.Id
                        })
                })
            .quantity(2)
            .create()
            .getRecords();

        Triggers.switchOn();

        new SObjectBuilder(NGBS_Licenses_Dependencies__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                NGBS_Licenses_Dependencies__c.Name => ValueProviderBuilder.provideList(new List<String>{'Test', 'Test1', 'Test2', 'TestIgnore'}),
                NGBS_Licenses_Dependencies__c.Affected_licenses__c => ValueProviderBuilder.provideList(new List<String>{
                    'LC_IBO-ROOMS_971;LC_DL-ROOMS_969',
                    'LC_IBO-ROOMS_971;LC_DL-ROOMS_969',
                    'LC_IBO-ROOMS_971;LC_DL-ROOMS_969',
                    'LC_TEST_CHILD'
                }),
                NGBS_Licenses_Dependencies__c.Depends_on_licenses__c => ValueProviderBuilder.provideList(new List<String>{
                    'LC_RCRM_77',
                    'LC_RCRM_78', 
                    'LC_RCRM_79',
                    'LC_PARENT_1;LC_PARENT_2'
                }),
                NGBS_Licenses_Dependencies__c.PackageIds__c => ValueProviderBuilder.provideList(new List<String>{
                    null, 
                    null, 
                    '33;35;39', 
                    null
                }),
                NGBS_Licenses_Dependencies__c.IgnoreForPackageIDs__c => ValueProviderBuilder.provideList(new List<String>{
                    null, 
                    null, 
                    null,
                    '44;45'
                })
            })
            .quantity(4)
            .create()
            .getRecords();
    }

    @isTest
    private static void getSettings() {

        Account acc = TestDataGenerator.createAccount('Test Acc');
        Opportunity opp = TestDataGenerator.createOpportunity(acc);

        RestContext.request = new RestRequest();
        RestContext.request.params.put('oppId', opp.Id);
        SettingsService.settings();

        String body = RestContext.response.responseBody.toString();
        Map<String, String> result = (Map<String, String>)JSON.deserialize(body, Map<String, String>.class);
        Set<string> settingsKeys = result.keySet();

        List<string> props = new List<string> {
            'User',
            'Profiles',
            'FeatureToggle',
            'CustomPermissions',
            'Other',
            'RecordTypes',
            'Opportunity',
            'hiddenLicenses',
            'IcbSettings',
            'purchaseRestrictionPeriod',
            'createMSAButtonName',
            'dqInitialTermsOptions',
            'dqRenewalTermsOptions',
            'dqSpecialTermsOptions',
            'dqFreeShippingTermsOptions',
            'dqChargeTermOptions',
            'dqElaInitialTermsOptions',
            'dqTrueUpTermsOptions',
            'dqProductCategoriesSalesOptions',
            'dqProductCategoriesCCOptions'
        };

        System.assertEquals(settingsKeys.containsAll(props), true);
	}

    @isTest
    private static void getSettingsWithoutAccount() {
        RestContext.request = new RestRequest();
        SettingsService.settings();

        String body = RestContext.response.responseBody.toString();
        Map<String, String> result = (Map<String, String>)JSON.deserialize(body, Map<String, String>.class);
        Set<string> settingsKeys = result.keySet();

        List<string> props = new List<string> {
            'User',
            'Profiles',
            'FeatureToggle',
            'CustomPermissions',
            'Other',
            'RecordTypes',
            'Opportunity',
            'hiddenLicenses',
            'purchaseRestrictionPeriod',
            'createMSAButtonName',
            'dqInitialTermsOptions',
            'dqRenewalTermsOptions',
            'dqSpecialTermsOptions',
            'dqFreeShippingTermsOptions',
            'dqChargeTermOptions',
            'dqElaInitialTermsOptions',
            'dqTrueUpTermsOptions',
            'dqProductCategoriesSalesOptions',
            'dqProductCategoriesCCOptions'
        };

        System.assertEquals(settingsKeys.containsAll(props), true);
    }

    @isTest
    private static void getSetting() {
        NGBS_Settings__c settings = new NGBS_Settings__c();
                        settings.BaseEndpoint__c = 'test 1';
                        settings.AccountManagerPath__c = 'test 2';
                        settings.CatalogPath__c = 'test 3';
                        settings.InvoiceEnginePath__c = 'test 4';
                        settings.Login__c = 'test 5';
                        settings.Password__c = 'test 6';

        insert settings;

        RestContext.request = new RestRequest();

        SettingsService.Params params = new SettingsService.Params();
                               params.name = 'ngbs';
        RestContext.request.requestBody = Blob.valueof(
            JSON.serialize(params)
        );
        SettingsService.setting();

        String body = RestContext.response.responseBody.toString();
        Map<String, Object> resulted_map = (Map<String, Object>) JSON.deserializeUntyped(body);
        Map<String, Object> data = (Map<String, Object>) resulted_map.get('data');
        String ngbsJson = JSON.serialize(data.get('NGBS_Settings__c'));
        NGBS_Settings__c result = (NGBS_Settings__c) JSON.deserialize(ngbsJson, NGBS_Settings__c.class);

        System.assertEquals(result.BaseEndpoint__c, 'test 1');
        System.assertEquals(result.AccountManagerPath__c, 'test 2');
        System.assertEquals(result.CatalogPath__c, 'test 3');
        System.assertEquals(result.InvoiceEnginePath__c, 'test 4');
        System.assertEquals(result.Login__c, 'test 5');
        System.assertEquals(result.Password__c, 'test 6');
	}

    @isTest
    private static void verifyHiddenLicensesSettingsIsBuiltCorrect() {
        SettingsService.LicensesSettings licenseConfig = SettingsService.getLicenseSettings(false, new List<String>());
        Map<String, Set<String>> hiddenLicensesSettings = licenseConfig.hiddenLicenseSettings;

        System.assertEquals(2, hiddenLicensesSettings.size());
        System.assert(hiddenLicensesSettings.containsKey('All'));
        System.assert(hiddenLicensesSettings.containsKey('3'));
        System.assertEquals(2, hiddenLicensesSettings.get('All').size());
        System.assert(hiddenLicensesSettings.get('All').contains('1'));
        System.assert(hiddenLicensesSettings.get('All').contains('2'));
        System.assert(hiddenLicensesSettings.get('3').contains('3'));
    }

    @isTest
    private static void verifyLicensesUnavailableSettingsIsBuiltCorrectForLBO() {
        SettingsService.LicensesSettings licenseConfig = SettingsService.getLicenseSettings(false, new List<String>());
        Map<String, Set<String>> hiddenLicensesSettings = licenseConfig.licensesUnavailableForLBO;

        System.assertEquals(1, hiddenLicensesSettings.size());
        System.assert(hiddenLicensesSettings.containsKey('All'));
        System.assertEquals(2, hiddenLicensesSettings.get('All').size());
        System.assert(hiddenLicensesSettings.get('All').contains('LC_VF_42'));
        System.assert(hiddenLicensesSettings.get('All').contains('LC_T800F_41'));
    }

    @isTest
    private static void verifyLicenseDiscountSettingsIsBuiltCorrect() {
        SettingsService.LicensesSettings licenseConfig = SettingsService.getLicenseSettings(false, new List<String>());
        Map<String, Map<String, String>> licenseDiscountSettings = licenseConfig.licenseDiscountSettings;

        System.assertEquals(2, licenseDiscountSettings.size());
        System.assert(licenseDiscountSettings.containsKey('All'));
        System.assert(licenseDiscountSettings.containsKey('3'));
        System.assertEquals(5, licenseDiscountSettings.get('All').size());
        System.assert(licenseDiscountSettings.get('All').containsKey('1'));
        System.assert(licenseDiscountSettings.get('All').get('1') == 'none');
        System.assert(licenseDiscountSettings.get('All').containsKey('2'));
        System.assert(licenseDiscountSettings.get('All').get('2') == 'all');
        System.assert(licenseDiscountSettings.get('3').containsKey('3'));
        System.assert(licenseDiscountSettings.get('3').get('3') == 'currency');
    }

    @isTest
    private static void verifyShowNameLicensesSettignsIsBuiltCorrect() {
        SettingsService.LicensesSettings licenseConfig = SettingsService.getLicenseSettings(false, new List<String>());
        Map<String, Set<String>> showNameLicensesSettigns = licenseConfig.showNameLicensesSettigns;

        System.assertEquals(2, showNameLicensesSettigns.size());
        System.assert(showNameLicensesSettigns.containsKey('All'));
        System.assert(showNameLicensesSettigns.containsKey('3'));
        System.assertEquals(2, showNameLicensesSettigns.get('All').size());
        System.assert(showNameLicensesSettigns.get('All').contains('1'));
        System.assert(showNameLicensesSettigns.get('All').contains('2'));
        System.assert(showNameLicensesSettigns.get('3').contains('3'));
    }

    @isTest
    private static void verifyOpportunityPageLicensesIsBuiltCorrect() {
        SettingsService.LicensesSettings licenseConfig = SettingsService.getLicenseSettings(false, new List<String>());
        Map<String, Map<String, Boolean>> opportunityPageLicenses = licenseConfig.opportunityPageLicenses;

        System.assertEquals(2, opportunityPageLicenses.size());
        System.assert(opportunityPageLicenses.containsKey('All'));
        System.assert(opportunityPageLicenses.containsKey('3'));
        System.assertEquals(3, opportunityPageLicenses.get('All').size());
        System.assert(opportunityPageLicenses.get('All').containsKey('1'));
        System.assert(opportunityPageLicenses.get('All').containsKey('1_1'));
        System.assertEquals(opportunityPageLicenses.get('All').get('1_1'), true);
        System.assert(opportunityPageLicenses.get('All').containsKey('2'));
        System.assertEquals(opportunityPageLicenses.get('All').get('2'), false);
        System.assert(opportunityPageLicenses.get('3').containsKey('3'));
        System.assertEquals(opportunityPageLicenses.get('3').get('3'), true);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void verifyNGBSLicensesDescriptionIsExistInLicenseSettings() {
        SettingsService.LicensesSettings licenseConfig = SettingsService.getLicenseSettings(false, new List<String>());

        /*
        System.assert(licenseConfig.licensesDescriptionSettings.keySet().containsAll(AVAILABLE_DESCRIPTION_IDS));
        for (String str : licenseConfig.licensesDescriptionSettings.get('LC_IBO_288')) {
            System.assert(String.isNotBlank(str));
        }
        */
    }

    @isTest
    static void testGetCategoryCodes() {

        Map<String, Set<String>> categoryCodesMap = SettingsService.getCategoryCodes();
        System.assertEquals(0, categoryCodesMap.size());

        // populate Category_Codes__c custom setting
        List<Category_Codes__c> categoryCodes = new List<Category_Codes__c>();

        Map<String, String> m = new Map<String, String>{
            'FAX_AREA_CODES' => 'MLFN,MTFN',
            'LOCAL_AREA_CODES' => 'ALN,HDRF,HDR,HD,MLN,MLFN,SP,EP',
            'MAIN_AREA_CODES' => 'ALN,HDRF,HDR,HD,MLN,SP,EP,ATN,MTN',
            'TOLL_FREE_AREA_CODES' => 'ATN,MTN,MTFN',
            'AREA_CODES_AVAILABLE' => 'HDRF,HDR,HD,MLN,MTN,MLFN,MTFN,ALN,ATN,SP,EP',
            'REQUIRED_AREA_CODES' => 'ALN,ATN,HDRF,HD'
        };
        for(String codeName : m.KeySet()) {
            categoryCodes.add(
                new Category_Codes__c(
                    Name = codeName,
                    Codes__c = m.get(codeName)
                )
            );
        }
        insert categoryCodes;


        categoryCodesMap = SettingsService.getCategoryCodes();
        System.assertNotEquals(0, categoryCodesMap.size());

        // verify that categoryCodesMap contains names from CustomSetting Category_Codes__c
        for(String categoryName : m.keySet()) {
            System.assert(categoryCodesMap.containsKey(categoryName));
        }
    }

    @isTest
    private static void verifyGetDefaultPackageForLeadConvertReturnDataFromCustomSettings() {
        DefaultPackagesForLeadConvert__c ringCentralPackage = new DefaultPackagesForLeadConvert__c(
            Name = 'RC_Office',
            Brand__c = 'RingCentral',
            Service__c = 'Office',
            Id__c = '18',
            Version__c = '1',
            Currency__c = 'USD'
        );
        DefaultPackagesForLeadConvert__c ringCentralCanadaPackage = new DefaultPackagesForLeadConvert__c(
            Name = 'RC_CAD_Office',
            Brand__c = 'RingCentral Canada',
            Service__c = 'Office',
            Id__c = '121',
            Version__c = '1',
            Currency__c = 'USD'
        );
        insert new List<DefaultPackagesForLeadConvert__c>{ringCentralPackage, ringCentralCanadaPackage};
        String result = SettingsService.getDefaultPackageForLeadConvert();

        List<SettingsService.DefaultPackage> packagesList =
            (List<SettingsService.DefaultPackage>)JSON.deserialize(result, List<SettingsService.DefaultPackage>.class);

        System.assertEquals('RingCentral', packagesList[0].Brand, 'Name for first package populated incorrectly');
        System.assertEquals('18', packagesList[0].Id, 'Id for first package populated incorrectly');
        System.assertEquals('1', packagesList[0].Version, 'Version for first package populated incorrectly');
        System.assertEquals('RingCentral Canada', packagesList[1].Brand, 'Name for second package populated incorrectly');
        System.assertEquals('121', packagesList[1].Id, 'Id for second package populated incorrectly');
        System.assertEquals('1', packagesList[1].Version, 'Version for second package populated incorrectly');
    }

    @isTest
    static void testTaxExemptApprovalsSortedInDescendingOrder() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .setField(Account.BillingStreet, 'Wall street')
            .setField(Account.BillingCity, 'NYC')
            .setField(Account.BillingState, 'NY')
            .setField(Account.BillingPostalCode, '123890')
            .setField(Account.BillingCountry, 'US')
            .create()
            .getRecord();

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setField(Contact.AccountId, acc.Id)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.Type, 'Syndicated - New')
            .setField(Opportunity.StageName, 'Planning')
            .setField(Opportunity.CloseDate, System.today().addMonths(1))
            .setField(Opportunity.AccountId, acc.Id)
            .create()
            .getRecord();

        Triggers.switchOff();
        Approval__c firstApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setField(Approval__c.Name, 'Tax Exemption Approval 1')
            .setField(Approval__c.RecordTypeId, ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL)
            .setField(Approval__c.Account__c, acc.Id)
            .setField(Approval__c.Contact__c, con.Id)
            .setField(Approval__c.Status__c, 'New')
            .create()
            .getRecord();

        Approval__c secondApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setField(Approval__c.Name, 'Tax Exemption Approval 2')
            .setField(Approval__c.RecordTypeId, ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL)
            .setField(Approval__c.Account__c, acc.Id)
            .setField(Approval__c.Contact__c, con.Id)
            .setField(Approval__c.Status__c, 'New')
            .create()
            .getRecord();
        Triggers.switchOn();

        Datetime yesterday = Datetime.now().addDays(-1);
        Test.setCreatedDate(secondApproval.Id, yesterday);
        Test.startTest();

        List<Approval__c> accountApprovals = SettingsService.getAccountApprovals(opp);

        List<Approval__c> sortedApprovals = SettingsService.getTaxExemptionApprovals(accountApprovals);
        Test.stopTest();

        System.assert(sortedApprovals.get(0).CreatedDate > sortedApprovals.get(1).CreatedDate,
            'Tax Exempt Approvals should be sorted by created date in descending order');
    }


    /**
     * Verify that hidden license Categories List is not empty
     * in case of Secondary DL approval is New
     */
    @IsTest
    static void verifyHiddenLicenseCategoriesIsNotEmpty() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .setField(Account.BillingStreet, 'Wall street')
            .setField(Account.BillingCity, 'NYC')
            .setField(Account.BillingState, 'NY')
            .setField(Account.BillingPostalCode, '123890')
            .setField(Account.BillingCountry, 'US')
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.Type, 'Syndicated - New')
            .setField(Opportunity.StageName, 'Planning')
            .setField(Opportunity.CloseDate, System.today().addMonths(1))
            .setField(Opportunity.AccountId, acc.Id)
            .create()
            .getRecord();

        new SObjectBuilder(Approval__c.SObjectType)
            .setField(Approval__c.Name, 'Secondary DL')
            .setField(Approval__c.RecordTypeId, ApprovalHelper.RT_ID_SECONDARY_DL)
            .setField(Approval__c.Account__c, acc.Id)
            .setField(Approval__c.Status__c, 'New')
            .create()
            .getRecord();

        NGBSCategoriesSettings__c categoriesSettings = new NGBSCategoriesSettings__c();
        categoriesSettings.Name = SettingsService.SECONDARY_DL_SETTING_NAME;
        categoriesSettings.HiddenCategories__c = 'DL-CC,IBO-CC';
        insert categoriesSettings;

        List<String> hiddenCategoriesFromService = SettingsService.getHiddenLicenseCategories(opp);
        List<String> hiddenCategoriesFromSplit = NGBSCategoriesSettings__c.getValues(SettingsService.SECONDARY_DL_SETTING_NAME).HiddenCategories__c.split(',');

        System.assertEquals(hiddenCategoriesFromService, hiddenCategoriesFromSplit, 'hidden License Categories must be equals');
    }



    /**
     * Verify that hidden license Categories List is empty in case of Secondary DL approval is approved
     */
    @IsTest
    static void verifyHiddenLicenseCategoriesIsEmpty() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .setField(Account.BillingStreet, 'Wall street')
            .setField(Account.BillingCity, 'NYC')
            .setField(Account.BillingState, 'NY')
            .setField(Account.BillingPostalCode, '123890')
            .setField(Account.BillingCountry, 'US')
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.Type, 'Syndicated - New')
            .setField(Opportunity.StageName, 'Planning')
            .setField(Opportunity.CloseDate, System.today().addMonths(1))
            .setField(Opportunity.AccountId, acc.Id)
            .create()
            .getRecord();

        new SObjectBuilder(Approval__c.SObjectType)
            .setField(Approval__c.Name, 'Secondary DL')
            .setField(Approval__c.RecordTypeId, ApprovalHelper.RT_ID_SECONDARY_DL)
            .setField(Approval__c.Account__c, acc.Id)
            .setField(Approval__c.Status__c, 'Approved')
            .create()
            .getRecord();

        List<String> hiddenCategories = SettingsService.getHiddenLicenseCategories(opp);
        System.assertEquals(hiddenCategories.size(), 0, 'hidden License Categories must be empty');
    }

    @IsTest
    static void testGetCountryCodesMethod() {

        System.assert(
            SettingsService.getCountryCodes().isEmpty(),
            'getCountryCodes method should return empty map if custom setting CountryCodes__c not populated'
        );

        final String testCountryCode = 'USA';

        List<String> testCountryNamesUpperCase = new List<String>{
            'United states',
            'United states of america',
            'Us',
            'Usa'
        };

        List<String> testCountryNamesLowerCase = new List<String>{
            'united states',
            'united states of america',
            'us',
            'usa'
        };

        new SObjectBuilder(CountryCodes__c.SObjectType)
            .setField(CountryCodes__c.Name, testCountryCode)
            .setField(CountryCodes__c.CountryName__c, String.join(testCountryNamesUpperCase, ';'))
            .create();

        Map<String, String> countryNameToCodeMap = SettingsService.getCountryCodes();

        for (String countryName : testCountryNamesLowerCase) {
            System.assert(
                countryNameToCodeMap.containsKey(countryName),
                'getCountryCodes method should return map where keys are ' +
                'semicolon-separated values from CountryCodes__c.CountryName__c field'
            );

            System.assertEquals(testCountryCode, countryNameToCodeMap.get(countryName));
        }
    }

    @isTest
    private static void verifyNotAvailableWithRCVLicensesIsBuiltCorrect() {
        SettingsService.LicensesSettings licenseConfig = SettingsService.getLicenseSettings(false, new List<String>());
        Set<String> notAvailableWithRCVLicensesSetting = licenseConfig.notAvailableWithRCVLicenses;

        System.assertEquals(
            3,
            notAvailableWithRCVLicensesSetting.size(),
            'notAvailableWithRCVLicensesSetting should have 3 values'
        );
        System.assert(
            notAvailableWithRCVLicensesSetting.contains('4'),
            'notAvailableWithRCVLicensesSetting should contain licenseId from ' +
            'custom setting with NotAvailableWithRCV__c = true'
        );
        System.assert(
            notAvailableWithRCVLicensesSetting.contains('5'),
            'notAvailableWithRCVLicensesSetting should contain licenseId from ' +
            'custom setting with NotAvailableWithRCV__c = true'
        );
        System.assert(
            notAvailableWithRCVLicensesSetting.contains('6'),
            'notAvailableWithRCVLicensesSetting should contain licenseId from ' +
            'custom setting with NotAvailableWithRCV__c = true'
        );
    }

    @isTest
    private static void testGetBusinessIdentityMappingMethod() {

        Profile currentUserProfile = (Profile) new ProfileSelector()
            .selectProfileById(new List<Object>{UserInfo.getProfileId()})
            .executeQuery()
            .get(0);

        List<PackageBusinessIdentityMapping__c> testMappingList = (List<PackageBusinessIdentityMapping__c>) new SObjectBuilder(PackageBusinessIdentityMapping__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PackageBusinessIdentityMapping__c.Name => ValueProviderBuilder.provideUniqueString('testMapping'),
                PackageBusinessIdentityMapping__c.Active__c => ValueProviderBuilder.provideList(
                    new List<Boolean>{true, true, false}
                ),
                PackageBusinessIdentityMapping__c.Profile__c => ValueProviderBuilder.provideList(
                    new List<String>{currentUserProfile.Name, 'Other Test Profile', currentUserProfile.Name}
                ),
                PackageBusinessIdentityMapping__c.BiName__c => ValueProviderBuilder.provideList(
                    new List<String>{'RingCentral Inc.', 'Unify Office France', 'Rainbow Office France'}
                ),
                PackageBusinessIdentityMapping__c.BiId__c => ValueProviderBuilder.provideList(
                    new List<String>{'4', '24', '34'}
                ),
                PackageBusinessIdentityMapping__c.Currency__c => ValueProviderBuilder.provideList(
                    new List<String>{'USD', 'EUR', 'EUR'}
                ),
                PackageBusinessIdentityMapping__c.DefaultBrand__c => ValueProviderBuilder.provideList(
                    new List<String>{'RingCentral', 'Unify Office', 'Rainbow Office'}
                ),
                PackageBusinessIdentityMapping__c.LeadRecordType__c => ValueProviderBuilder.provideList(
                    new List<String>{'', '', ''}
                )
            })
            .quantity(3)
            .create()
            .getRecords();

        List<SettingsService.PackageBusinessIdentityMapping> result = SettingsService.getBusinessIdentityMapping();
        System.assertEquals(1, result.size(), 'method should return mapping records applicable for Current User Profile');

        PackageBusinessIdentityMapping__c mappingForCurrentUser = testMappingList.get(0);
        System.assertEquals(
            mappingForCurrentUser.BiId__c,
            result.get(0).biId,
            'The field "biId" of the returned entry must match the "BiId__c" of the entry ' +
            'from the custom setting for the current user profile'
        );

        System.assertEquals(
            mappingForCurrentUser.BiName__c,
            result.get(0).biName,
            'The field "biName" of the returned entry must match the "BiName__c" of the entry ' +
            'from the custom setting for the current user profile'
        );

        System.assertEquals(
            mappingForCurrentUser.Currency__c,
            result.get(0).cur,
            'The field "cur" of the returned entry must match the "Currency__c" of the entry ' +
            'from the custom setting for the current user profile'
        );

        System.assertEquals(
            mappingForCurrentUser.DefaultBrand__c,
            result.get(0).defaultBrand,
            'The field "defaultBrand" of the returned entry must match the "DefaultBrand__c" of the entry ' +
            'from the custom setting for the current user profile'
        );

        System.assertEquals(
            JSON.serialize(result),
            SettingsService.getBusinessIdentityMappingJSON(),
            '"result" in JSON representation must match with the value returned from getBusinessIdentityMappingJSON method'
        );
    }

    @isTest
    private static void testGetBusinessIdentityMappingMethodLeadConvertPage() {

        Profile currentUserProfile = (Profile) new ProfileSelector()
            .selectProfileById(new List<Object>{
                UserInfo.getProfileId()
            })
            .executeQuery()
            .get(0);
        List<Lead> leads = (List<Lead>) new LeadSelector()
            .selectLeads()
            .executeQuery();

        Lead salesLead = null;
        Lead partnerLead = null;

        for (Lead lead : leads) {
            if (lead.RecordTypeId == LeadHelper.RT_ID_SALES_LEADS) {
                salesLead = lead;
                continue;
            }
            if (lead.RecordTypeId == LeadHelper.RT_ID_PARTNER_LEADS) {
                partnerLead = lead;
                continue;
            }
        }

        List<PackageBusinessIdentityMapping__c> testMappingList = (List<PackageBusinessIdentityMapping__c>) new SObjectBuilder(PackageBusinessIdentityMapping__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PackageBusinessIdentityMapping__c.Name => ValueProviderBuilder.provideUniqueString('testMapping'),
                PackageBusinessIdentityMapping__c.Active__c => ValueProviderBuilder.provideList(
                    new List<Boolean>{
                        true, true, true, true
                    }
                ),
                PackageBusinessIdentityMapping__c.Profile__c => ValueProviderBuilder.provideList(
                    new List<String>{
                        currentUserProfile.Name, currentUserProfile.Name, currentUserProfile.Name, currentUserProfile.Name
                    }
                ),
                PackageBusinessIdentityMapping__c.BiName__c => ValueProviderBuilder.provideList(
                    new List<String>{
                        'Empty Field', 'Sales Leads Only', 'Partner Leads Only', 'Both'
                    }
                ),
                PackageBusinessIdentityMapping__c.BiId__c => ValueProviderBuilder.provideList(
                    new List<String>{
                        '4', '4', '4', '4'
                    }
                ),
                PackageBusinessIdentityMapping__c.Currency__c => ValueProviderBuilder.provideList(
                    new List<String>{
                        'USD', 'USD', 'USD', 'USD'
                    }
                ),
                PackageBusinessIdentityMapping__c.DefaultBrand__c => ValueProviderBuilder.provideList(
                    new List<String>{
                        'RingCentral', 'RingCentral', 'RingCentral', 'RingCentral'
                    }
                ),
                PackageBusinessIdentityMapping__c.LeadRecordType__c => ValueProviderBuilder.provideList(
                    new List<String>{
                        '', 'Sales Leads', 'Partner Leads', 'Sales Leads,Partner Leads'
                    }
                )
            })
            .quantity(4)
            .create()
            .getRecords();

        Set<String> result = getMappingIdentityNames(SettingsService.getBusinessIdentityMapping());
        System.assertEquals(4, result.size(), 'method should return all mappings if no lead id was specified');
        System.assert(result.contains('Empty Field'), 'must contain mapping without lead record type specified');
        System.assert(result.contains('Sales Leads Only'), 'must contain mapping for Sales Leads only');
        System.assert(result.contains('Partner Leads Only'), 'must contain mapping for Partner Leads only');
        System.assert(result.contains('Both'), 'must contain mapping for both Lead record types');

        result = getMappingIdentityNames(SettingsService.getBusinessIdentityMapping(salesLead.Id));
        System.assertEquals(3, result.size(), 'method should return all mappings except limited for Partner Leads if Sales lead id was specified');
        System.assert(result.contains('Empty Field'), 'must contain mapping without lead record type specified');
        System.assert(result.contains('Sales Leads Only'), 'must contain mapping for Sales Leads only');
        System.assert(result.contains('Both'), 'must contain mapping for both Lead record types');

        result = getMappingIdentityNames(SettingsService.getBusinessIdentityMapping(partnerLead.Id));
        System.assertEquals(3, result.size(), 'method should return all mappings except limited for Sales Leads if Partner lead id was specified');
        System.assert(result.contains('Empty Field'), 'must contain mapping without lead record type specified');
        System.assert(result.contains('Partner Leads Only'), 'must contain mapping for Partner Leads only');
        System.assert(result.contains('Both'), 'must contain mapping for both Lead record types');
    }

    private static Set<String> getMappingIdentityNames(List<SettingsService.PackageBusinessIdentityMapping> mappings) {
        Set<String> result = new Set<String>();
        for (SettingsService.PackageBusinessIdentityMapping mapping: mappings) {
            result.add(mapping.biName);
        }
        return result;
    }

    @isTest
    private static void testGetPackageLabelsMappingMethod() {

        Profile currentUserProfile = (Profile) new ProfileSelector()
            .selectProfileById(new List<Object>{UserInfo.getProfileId()})
            .executeQuery()
            .get(0);

        List<PackageLabelsMapping__c> testMappingList = (List<PackageLabelsMapping__c>) new SObjectBuilder(PackageLabelsMapping__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PackageLabelsMapping__c.Name => ValueProviderBuilder.provideUniqueString('testMapping'),
                PackageLabelsMapping__c.Active__c => ValueProviderBuilder.provideList(
                    new List<Boolean>{true, true, true, false}
                ),
                PackageLabelsMapping__c.Profile__c => ValueProviderBuilder.provideList(
                    new List<String>{currentUserProfile.Name, currentUserProfile.Name, 'Other Test Profile', currentUserProfile.Name}
                ),
                PackageLabelsMapping__c.AccountType__c => ValueProviderBuilder.provideList(
                    new List<String>{
                        OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS,
                        OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
                        OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS,
                        OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS
                    }
                ),
                PackageLabelsMapping__c.SIGNUP_SFDC__c => ValueProviderBuilder.provideList(
                    new List<String>{'Active,Active Testing', null, 'Active', null}
                ),
                PackageLabelsMapping__c.SIGNUP_SFDCVAR__c => ValueProviderBuilder.provideList(
                    new List<String>{'Active,Active Testing', null, 'Active', null}
                ),
                PackageLabelsMapping__c.UpgradeWizardExpiration__c => ValueProviderBuilder.provideList(
                    new List<String>{null, 'Active,Active Testing', null, 'Active,Active Testing'}
                )
            })
            .quantity(3)
            .create()
            .getRecords();

        List<SettingsService.PackageLabelsMapping> result = SettingsService.getPackageLabelsMapping();
        System.assertEquals(2, result.size(), 'method should return mapping records appilcable for Current User Profile');

        SettingsService.PackageLabelsMapping resultMappingForNewBusiness;
        SettingsService.PackageLabelsMapping resultMappingForExistingBusiness;
        for (SettingsService.PackageLabelsMapping item : result) {
            if (item.accountType == OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS) {
                resultMappingForNewBusiness = item;
            } else {
                resultMappingForExistingBusiness = item;
            }
        }

        System.assert(
            resultMappingForNewBusiness.SIGNUP_SFDC.contains('Active') && resultMappingForNewBusiness.SIGNUP_SFDC.contains('Active Testing'),
            'The field "SIGNUP_SFDC" of the returned entry must match the "SIGNUP_SFDC__c" of the entry ' +
            'from the custom setting for the current user profile'
        );

        System.assert(
            resultMappingForNewBusiness.SIGNUP_SFDCVAR.contains('Active') && resultMappingForNewBusiness.SIGNUP_SFDCVAR.contains('Active Testing'),
            'The field "SIGNUP_SFDCVAR" of the returned entry must match the "SIGNUP_SFDCVAR__c" of the entry ' +
            'from the custom setting for the current user profile'
        );

        System.assertEquals(
            null,
            resultMappingForNewBusiness.UpgradeWizardExpiration,
            'The field "UpgradeWizardExpiration" of the returned entry must match the "UpgradeWizardExpiration__c" of the entry ' +
            'from the custom setting for the current user profile'
        );


        System.assertEquals(
            null,
            resultMappingForExistingBusiness.SIGNUP_SFDC,
            'The field "SIGNUP_SFDC" of the returned entry must match the "SIGNUP_SFDC__c" of the entry ' +
            'from the custom setting for the current user profile'
        );

        System.assertEquals(
            null,
            resultMappingForExistingBusiness.SIGNUP_SFDCVAR,
            'The field "SIGNUP_SFDCVAR" of the returned entry must match the "SIGNUP_SFDCVAR__c" of the entry ' +
            'from the custom setting for the current user profile'
        );

        System.assert(
            resultMappingForExistingBusiness.UpgradeWizardExpiration.contains('Active') && resultMappingForExistingBusiness.UpgradeWizardExpiration.contains('Active Testing'),
            'The field "UpgradeWizardExpiration" of the returned entry must match the "UpgradeWizardExpiration__c" of the entry ' +
            'from the custom setting for the current user profile'
        );

        System.assertEquals(
            JSON.serialize(result),
            SettingsService.getPackageLabelsMappingJSON(),
            '"result" in JSON representation must match with the value returned from getBusinessIdentityMappingJSON method'
        );
    }

    @isTest
    private static void testSortBuinessIdentityMappings() {

        PackageBusinessIdentityMapping__c item1 = new PackageBusinessIdentityMapping__c(
            Active__c = true,
            BiId__c = '4',
            BiName__c = 'RingCentral Inc.',
            DefaultBrand__c = 'RingCentral',
            Currency__c = 'USD',
            SortOrder__c = 1
        );

        PackageBusinessIdentityMapping__c item2 = new PackageBusinessIdentityMapping__c(
            Active__c = true,
            BiId__c = '24',
            BiName__c = 'Unify Office France',
            DefaultBrand__c = 'Unify Office',
            Currency__c = 'EUR',
            SortOrder__c = 2
        );

        PackageBusinessIdentityMapping__c item3 = new PackageBusinessIdentityMapping__c(
            Active__c = true,
            BiId__c = '34',
            BiName__c = 'Rainbow Office France',
            DefaultBrand__c = 'Rainbow Office',
            Currency__c = 'EUR'
        );

        PackageBusinessIdentityMapping__c item4 = new PackageBusinessIdentityMapping__c(
            Active__c = true,
            BiId__c = '20',
            BiName__c = 'Avaya Cloud Office',
            DefaultBrand__c = 'Avaya Cloud Office',
            Currency__c = 'USD'
        );

        PackageBusinessIdentityMapping__c item5 = new PackageBusinessIdentityMapping__c(
            Active__c = true,
            BiId__c = '22',
            BiName__c = 'Avaya Cloud Office AU',
            DefaultBrand__c = 'Avaya Cloud Office',
            Currency__c = 'AUD'
        );

        PackageBusinessIdentityMapping__c item6 = new PackageBusinessIdentityMapping__c(
            Active__c = true,
            BiId__c = '25',
            BiName__c = 'Unify Office Germany',
            DefaultBrand__c = 'Unify Office',
            Currency__c = 'EUR'
        );

        PackageBusinessIdentityMapping__c item7 = new PackageBusinessIdentityMapping__c(
            Active__c = true,
            BiId__c = '35',
            BiName__c = 'Rainbow Office Germany',
            DefaultBrand__c = 'Rainbow Office',
            Currency__c = 'EUR',
            SortOrder__c = 999
        );

        List<SettingsService.PackageBusinessIdentityMapping> myList = new List<SettingsService.PackageBusinessIdentityMapping>{
            new SettingsService.PackageBusinessIdentityMapping(item1),
            new SettingsService.PackageBusinessIdentityMapping(item2),
            new SettingsService.PackageBusinessIdentityMapping(item3),
            new SettingsService.PackageBusinessIdentityMapping(item4),
            new SettingsService.PackageBusinessIdentityMapping(item5),
            new SettingsService.PackageBusinessIdentityMapping(item6),
            new SettingsService.PackageBusinessIdentityMapping(item7)
        };

        myList.sort();

        System.assertEquals(
            item1.SortOrder__c.intValue(),
            myList.get(0).sortOrder,
            'item with minimal sortOrder value should be first'
        );

        System.assertEquals(
            item2.SortOrder__c.intValue(),
            myList.get(1).sortOrder,
            'items should be sorted by "sortOrder" values'
        );

        System.assertEquals(
            item7.SortOrder__c.intValue(),
            myList.get(2).sortOrder,
            'items should be sorted by "sortOrder" values'
        );

        System.assertEquals(
            item4.BiName__c,
            myList.get(3).biName,
            'items with empty "sortOrder" value should be sorted by biName'
        );

        System.assertEquals(
            item5.BiName__c,
            myList.get(4).biName,
            'items with empty "sortOrder" value should be sorted by biName'
        );

        System.assertEquals(
            item3.BiName__c,
            myList.get(5).biName,
            'items with empty "sortOrder" value should be sorted by biName'
        );

        System.assertEquals(
            item6.BiName__c,
            myList.get(6).biName,
            'items with empty "sortOrder" value should be sorted by biName'
        );
    }

    @isTest
    private static void testPackagesFiltrationForSingapore() {

        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.SelectPackagesByBusinessIdentity__c, false)
            .create();

        new SObjectBuilder(NGBSPackagesFiltration__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                NGBSPackagesFiltration__c.IsActive__c => ValueProviderBuilder.provideList(new List<Boolean>{
                    false, true
                }),
                NGBSPackagesFiltration__c.Name => ValueProviderBuilder.provideList(new List<String>{
                    'RingCentral Singapore', 'RingCentral for Government'
                }),
                NGBSPackagesFiltration__c.ListOfPackageIDs__c => ValueProviderBuilder.provideList(new List<String>{
                    '270;271', '950;951'
                }),
                NGBSPackagesFiltration__c.FilterOutForQOP__c => true,
                NGBSPackagesFiltration__c.FilterOutForLC__c => true,
                NGBSPackagesFiltration__c.FilterOutForQW__c => true
            })
            .quantity(2)
            .create();

        SettingsService.NGBSPackagesFiltration filtrationSettings = SettingsService.getPackagesFiltrationSettings();
        System.assertNotEquals(
            null,
            filtrationSettings,
            'should return not empty filtration settings'
        );

        System.assert(
            filtrationSettings.qop.contains('270') && filtrationSettings.qop.contains('271')
            && filtrationSettings.qop.contains('950') && filtrationSettings.qop.contains('951'),
            'if "SelectPackagesByBusinessIdentity__c" feature is disabled, the setting should ' +
            'contain all singapore package Ids(from setting with Name "RingCentral Singapore") regardless of the "IsActive__c" field'
        );

        System.assert(
            filtrationSettings.leadConvert.contains('270') && filtrationSettings.leadConvert.contains('271')
            && filtrationSettings.leadConvert.contains('950') && filtrationSettings.leadConvert.contains('951'),
            'if "SelectPackagesByBusinessIdentity__c" feature is disabled, the setting should ' +
            'contain all singapore package Ids regardless of the "IsActive__c" field'
        );

        System.assert(
            filtrationSettings.quotingTool.contains('270') && filtrationSettings.quotingTool.contains('271')
            && filtrationSettings.quotingTool.contains('950') && filtrationSettings.quotingTool.contains('951'),
            'if "SelectPackagesByBusinessIdentity__c" feature is disabled, the setting should ' +
            'contain all singapore package Ids regardless of the "IsActive__c" field'
        );
    }

    @isTest
    private static void testPackagesFiltrationForSingaporeWithFeatureToggle() {

        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.SelectPackagesByBusinessIdentity__c, true)
            .create();

        new SObjectBuilder(NGBSPackagesFiltration__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                NGBSPackagesFiltration__c.IsActive__c => ValueProviderBuilder.provideList(new List<Boolean>{
                    false, true
                }),
                NGBSPackagesFiltration__c.Name => ValueProviderBuilder.provideList(new List<String>{
                    'RingCentral Singapore', 'RingCentral for Government'
                }),
                NGBSPackagesFiltration__c.ListOfPackageIDs__c => ValueProviderBuilder.provideList(new List<String>{
                    '270;271', '950;951'
                }),
                NGBSPackagesFiltration__c.FilterOutForQOP__c => true,
                NGBSPackagesFiltration__c.FilterOutForLC__c => true,
                NGBSPackagesFiltration__c.FilterOutForQW__c => true
            })
            .quantity(2)
            .create();

        SettingsService.NGBSPackagesFiltration filtrationSettings = SettingsService.getPackagesFiltrationSettings();
        System.assertNotEquals(
            null,
            filtrationSettings,
            'should return not empty filtration settings'
        );

        System.assert(
            !filtrationSettings.qop.contains('270') && !filtrationSettings.qop.contains('271'),
            'if "SelectPackagesByBusinessIdentity__c" feature is enabled, the setting should not ' +
            'contain singapore package Ids'
        );

        System.assert(
            !filtrationSettings.leadConvert.contains('270') && !filtrationSettings.leadConvert.contains('271'),
            'if "SelectPackagesByBusinessIdentity__c" feature is enabled, the setting should not ' +
            'contain singapore package Ids'
        );

        System.assert(
            !filtrationSettings.quotingTool.contains('270') && !filtrationSettings.quotingTool.contains('271'),
            'if "SelectPackagesByBusinessIdentity__c" feature is enabled, the setting should not ' +
            'contain singapore package Ids'
        );
    }

    @IsTest
    private static void testGetCreateMSAButtonName() {
        Account acc;
        Opportunity opp;

        System.assertEquals(
            SettingsService.getCreateMSAButtonName(acc, opp),
            null
        );

        acc = new Account(Name='Account');
        opp = new Opportunity(Name='Opportunity');

        System.assertEquals(
            SettingsService.getCreateMSAButtonName(acc, opp),
            null
        );

        new SObjectBuilder(CreateMSAButtonURLLogic__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                CreateMSAButtonURLLogic__c.Name => 'Name 1',
                CreateMSAButtonURLLogic__c.ButtonName__c => 'Button Name 1',
                CreateMSAButtonURLLogic__c.Brand__c => 'Brand 1',
                CreateMSAButtonURLLogic__c.BillingCountry__c => 'Country 1,Country 2'
            })
            .create();

        new SObjectBuilder(CreateMSAButtonURLLogic__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                CreateMSAButtonURLLogic__c.Name => 'Name 2',
                CreateMSAButtonURLLogic__c.ButtonName__c => 'Button Name 2',
                CreateMSAButtonURLLogic__c.Brand__c => 'Brand 2',
                CreateMSAButtonURLLogic__c.BillingCountry__c => ''
            })
            .create();

        new SObjectBuilder(CreateMSAButtonURLLogic__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                CreateMSAButtonURLLogic__c.Name => 'Name 3',
                CreateMSAButtonURLLogic__c.ButtonName__c => 'Button Name 3',
                CreateMSAButtonURLLogic__c.Brand__c => 'Brand 1',
                CreateMSAButtonURLLogic__c.BillingCountry__c => 'Country 3'
            })
            .create();

        new SObjectBuilder(CreateMSAButtonURLLogic__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                CreateMSAButtonURLLogic__c.Name => 'Name 4',
                CreateMSAButtonURLLogic__c.ButtonName__c => 'Button Name 4',
                CreateMSAButtonURLLogic__c.Brand__c => 'Brand 3,Brand 4',
                CreateMSAButtonURLLogic__c.BillingCountry__c => 'Country 3'
            })
            .create();

        new SObjectBuilder(CreateMSAButtonURLLogic__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                CreateMSAButtonURLLogic__c.Name => 'Name 4 Duplicated',
                CreateMSAButtonURLLogic__c.ButtonName__c => 'Button Name 4 Duplicated',
                CreateMSAButtonURLLogic__c.Brand__c => 'Brand 3,Brand 4',
                CreateMSAButtonURLLogic__c.BillingCountry__c => 'Country 3'
            })
            .create();

        acc.BillingCountry = 'country 2';
        opp.Brand_Name__c = 'brand 1';

        System.assertEquals(
            SettingsService.getCreateMSAButtonName(acc, opp),
            'Button Name 1'
        );

        acc.BillingCountry = 'country X';
        opp.Brand_Name__c = 'brand 2';

        System.assertEquals(
            SettingsService.getCreateMSAButtonName(acc, opp),
            'Button Name 2'
        );

        acc.BillingCountry = 'country 3';
        opp.Brand_Name__c = 'brand 1';

        System.assertEquals(
            SettingsService.getCreateMSAButtonName(acc, opp),
            'Button Name 3'
        );

        acc.BillingCountry = 'country 3';
        opp.Brand_Name__c = 'brand 3';

        System.assertEquals(
            SettingsService.getCreateMSAButtonName(acc, opp),
            'Button Name 4'
        );

        acc.BillingCountry = 'country 3';
        opp.Brand_Name__c = 'brand 4';

        System.assertEquals(
            SettingsService.getCreateMSAButtonName(acc, opp),
            'Button Name 4'
        );
    }

    @isTest
    private static void verifyLicensesDependenciesSettingsIsBuiltCorrect() {
        SettingsService.LicensesSettings licenseConfig = SettingsService.getLicenseSettings(false, new List<String>());
        Map<String,Map<String, Set<String>>> licenseDependenciesSettings = licenseConfig.licenseDependenciesSettings;

        Assert.areEqual(6, licenseDependenciesSettings.size(), 'Map must contain 6 records');
        Assert.isTrue(licenseDependenciesSettings.containsKey('All'), 'Map must have key "All"');
        Assert.areEqual(2, licenseDependenciesSettings.get('All').get('LC_DL-ROOMS_969').size(), 'Map must have two records for keyValue "LC_DL-ROOMS_969"');
        Assert.areEqual(2, licenseDependenciesSettings.get('All').get('LC_IBO-ROOMS_971').size(), 'Map must have two records for keyValue "LC_IBO-ROOMS_971"');
        Assert.areEqual('LC_RCRM_77', new List<String>(licenseDependenciesSettings.get('All').get('LC_DL-ROOMS_969'))[0], 'Map must have value "LC_RCRM_77" for key "LC_DL-ROOMS_969"');
        Assert.areEqual('LC_RCRM_78', new List<String>(licenseDependenciesSettings.get('All').get('LC_DL-ROOMS_969'))[1], 'Map must have value "LC_RCRM_78" for key "LC_DL-ROOMS_969"');
        Assert.areEqual('LC_RCRM_77', new List<String>(licenseDependenciesSettings.get('All').get('LC_IBO-ROOMS_971'))[0], 'Map must have value "LC_RCRM_77" for key "LC_IBO-ROOMS_971"');
        Assert.areEqual('LC_RCRM_78', new List<String>(licenseDependenciesSettings.get('All').get('LC_IBO-ROOMS_971'))[1], 'Map must have value "LC_RCRM_78" for key "LC_IBO-ROOMS_971"');
        Assert.isTrue(licenseDependenciesSettings.containsKey('33'), 'Map must have key "33"');
        Assert.areEqual(1, licenseDependenciesSettings.get('33').get('LC_DL-ROOMS_969').size(), 'Map must have one record for keyValue "LC_DL-ROOMS_969"');
        Assert.areEqual(1, licenseDependenciesSettings.get('33').get('LC_IBO-ROOMS_971').size(), 'Map must have one record for keyValue "LC_IBO-ROOMS_971"');
        Assert.areEqual('LC_RCRM_79', new List<String>(licenseDependenciesSettings.get('33').get('LC_DL-ROOMS_969'))[0], 'Map must have value "LC_RCRM_79" for key "LC_DL-ROOMS_969"');
        Assert.areEqual('LC_RCRM_79', new List<String>(licenseDependenciesSettings.get('33').get('LC_IBO-ROOMS_971'))[0], 'Map must have value "LC_RCRM_79" for key "LC_IBO-ROOMS_971"');
        Assert.isTrue(licenseDependenciesSettings.containsKey('35'), 'Map must have key "35"');
        Assert.areEqual(1, licenseDependenciesSettings.get('35').get('LC_DL-ROOMS_969').size(), 'Map must have one record for keyValue "LC_DL-ROOMS_969"');
        Assert.areEqual(1, licenseDependenciesSettings.get('35').get('LC_IBO-ROOMS_971').size(), 'Map must have one record for keyValue "LC_IBO-ROOMS_971"');
        Assert.areEqual('LC_RCRM_79', new List<String>(licenseDependenciesSettings.get('35').get('LC_DL-ROOMS_969'))[0], 'Map must have value "LC_RCRM_79" for key "LC_DL-ROOMS_969"');
        Assert.areEqual('LC_RCRM_79', new List<String>(licenseDependenciesSettings.get('35').get('LC_IBO-ROOMS_971'))[0], 'Map must have value "LC_RCRM_79" for key "LC_IBO-ROOMS_971"');
        Assert.isTrue(licenseDependenciesSettings.containsKey('39'), 'Map must have key "39"');
        Assert.areEqual(1, licenseDependenciesSettings.get('39').get('LC_DL-ROOMS_969').size(), 'Map must have one record for keyValue "LC_DL-ROOMS_969"');
        Assert.areEqual(1, licenseDependenciesSettings.get('39').get('LC_IBO-ROOMS_971').size(), 'Map must have one record for keyValue "LC_IBO-ROOMS_971"');
        Assert.areEqual('LC_RCRM_79', new List<String>(licenseDependenciesSettings.get('39').get('LC_DL-ROOMS_969'))[0], 'Map must have value "LC_RCRM_79" for key "LC_DL-ROOMS_969"');
        Assert.areEqual('LC_RCRM_79', new List<String>(licenseDependenciesSettings.get('39').get('LC_IBO-ROOMS_971'))[0], 'Map must have value "LC_RCRM_79" for key "LC_IBO-ROOMS_971"');

        Assert.isTrue(
            licenseDependenciesSettings.get('All').containsKey('LC_TEST_CHILD'), 
            'Map for All packages must include LC_TEST_CHILD'
        );
        Assert.areEqual(
            new Set<String>{'LC_PARENT_1', 'LC_PARENT_2'}, 
            licenseDependenciesSettings.get('All').get('LC_TEST_CHILD'), 
            'Map for All packages must include parent dependencies for LC_TEST_CHILD'
        );

        for (String ignoredPackageId : new List<String>{'44', '45'}) {
            Assert.isTrue(
                licenseDependenciesSettings.containsKey(ignoredPackageId), 
                'Map must contain ignored package ' + ignoredPackageId);
            Assert.isTrue(
                licenseDependenciesSettings.get(ignoredPackageId).containsKey('LC_TEST_CHILD'), 
                'Map for ignored package id must include LC_TEST_CHILD'
            );
            Assert.areEqual(
                new Set<String>{'!LC_PARENT_1', '!LC_PARENT_2'},
                licenseDependenciesSettings.get(ignoredPackageId).get('LC_TEST_CHILD'),
                'Map for ignored package id must contain ignored dependencies with ! prefix'
            );
        }
    }

    @isTest
    private static void testGetTargetPricingKeys() {
        String initialTerm0DevName= 'InitialTerm0';
        String logACVDevName= 'LogACV';
        String publicSectorDevName= 'PublicSector';
        TargetPricingKey__c initialTerm0;
        TargetPricingKey__c logACV;
        TargetPricingKey__c publicSector;
        List<TargetPricingKey__c> targetPricingKeys;
        Map<String, TargetPricingKey__c> devNameToTargetPricingKeyMap = new Map<String, TargetPricingKey__c>();
        Test.startTest();
        targetPricingKeys = SettingsService.getTargetPricingKeys();
        for (TargetPricingKey__c tpKey: targetPricingKeys) {
            if (tpKey.Name == initialTerm0DevName) {
                initialTerm0 = tpKey;
            }
            if (tpKey.Name == logACVDevName) {
                logACV = tpKey;
            }
            if (tpKey.Name == publicSectorDevName) {
                publicSector = tpKey;
            }
            devNameToTargetPricingKeyMap.put(tpKey.Name, tpKey);
        }
        Test.stopTest();

        System.assertEquals(
            initialTerm0,
            devNameToTargetPricingKeyMap.get(initialTerm0DevName),
            'Should return InitialTerm0 record from Target Pricing Key custom metadata'
        );
        System.assertEquals(
            logACV,
            devNameToTargetPricingKeyMap.get(logACVDevName),
            'Should return LogACV record from Target Pricing Key custom metadata'
        );
        System.assertEquals(
            publicSector,
            devNameToTargetPricingKeyMap.get(publicSectorDevName),
            'Should return PublicSector record from Target Pricing Key custom metadata'
        );
    }

    @IsTest
    private static void testIsAvailableUserOrProfile() {
        String userAndProfileIds = '';

        String userId = UserInfo.getUserId();
        String profileId = UserInfo.getUserId();

        Boolean nullValue = SettingsService.isAvailableUserOrProfile(null, userId, profileId);
        System.assert(!nullValue, 'Values must be false');

        Boolean noneValue = SettingsService.isAvailableUserOrProfile(userAndProfileIds, userId, profileId);
        System.assert(!noneValue, 'Values must be false');

        userAndProfileIds += userId;
        Boolean isAvailableUserId = SettingsService.isAvailableUserOrProfile(userAndProfileIds, userId, profileId);
        System.assert(isAvailableUserId, 'Values must be true');

        userAndProfileIds = profileId;
        Boolean isAvailableProfileId = SettingsService.isAvailableUserOrProfile(userAndProfileIds, userId, profileId);
        System.assert(isAvailableProfileId, 'Values must be true');

        userAndProfileIds = userId  + ';' + profileId;
        Boolean isAvailableUserIdAndProfileId = SettingsService.isAvailableUserOrProfile(userAndProfileIds, userId, profileId);
        System.assert(isAvailableUserIdAndProfileId, 'Values must be true');
    }

    @IsTest
    private static void testIsSwitzerland() {
        List<CountryCodes__c> newCountryCodes = (List<CountryCodes__c>) new SObjectBuilder(CountryCodes__c.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                        CountryCodes__c.Name => ValueProviderBuilder.provideList(new List<String> {'CHE', 'DE'}),
                        CountryCodes__c.CountryName__c => ValueProviderBuilder.provideList(new List<String> {'che;switzerland', 'germany'}),
                        CountryCodes__c.CountryNameFull__c => ValueProviderBuilder.provideList(new List<String> {'Switzerland', 'Germany'}),
                        CountryCodes__c.CountryNameShort__c => ValueProviderBuilder.provideList(new List<String> {'CH', 'DE'})
                })
                .quantity(1)
                .create()
                .getRecords();

        System.assert(newCountryCodes.size() > 0);

        Boolean value1 = SettingsService.isSwitzerland('switzerland');
        Boolean value2 = SettingsService.isSwitzerland('CHE');
        Boolean value3 = SettingsService.isSwitzerland('SWITZERLAND');
        Boolean value4 = SettingsService.isSwitzerland('SWITzeRLAND');
        Boolean value5 = SettingsService.isSwitzerland('Che');
        Boolean value6 = SettingsService.isSwitzerland('Germany');
        String errorText = 'Check for Switzerland must be true.';
        System.assertEquals(value1, true, errorText);
        System.assertEquals(value2, true, errorText);
        System.assertEquals(value3, true, errorText);
        System.assertEquals(value4, true, errorText);
        System.assertEquals(value5, true, errorText);
        System.assertEquals(value6, false, 'Check for Switzerland must be false.');
    }

    @IsTest
    private static void testGetAlpha2CountryCodesByVatType() {

        new SObjectBuilder(CountryCodes__c.SObjectType)
                .setField(CountryCodes__c.CountryName__c, 'aus;australia')
                .setField(CountryCodes__c.CountryNameShort__c, 'AU')
                .setField(CountryCodes__c.Name, 'AUS')
                .setField(CountryCodes__c.VATNumbersByName__c, 'GST')
                .create();

        List<String> values = SettingsService.getAlpha2CountryCodesByVatType(ApprovalHelper.VAT_NAME.GST.name());

        System.assertEquals(values.get(0), 'AU', 'Country must be returned from custom settings');
    }

    @IsTest
    private static void testGetAlpha2CountryCode() {
        new SObjectBuilder(CountryCodes__c.SObjectType)
                .setField(CountryCodes__c.CountryName__c, 'aus;australia')
                .setField(CountryCodes__c.CountryNameShort__c, 'AU')
                .setField(CountryCodes__c.Name, 'AUS')
                .create();

        List<String> values = new List<String>{'AustRaliA', 'AuS', 'Au'};
        String value1 = SettingsService.getAlpha2CountryCode(values[0]);
        String value2 = SettingsService.getAlpha2CountryCode(values[1]);
        String value3 = SettingsService.getAlpha2CountryCode(values[2]);
        String value4 = SettingsService.getAlpha2CountryCode(null);
        System.assertEquals(value1, 'AU', 'Country must be returned from custom settings');
        System.assertEquals(value2, 'AU', 'Country must be returned from custom settings');
        System.assertEquals(value3, 'AU', 'Country must be returned from custom settings');
        System.assertEquals(value4, null, 'Value must be returned null');
    }

    @IsTest
    private static void testGetCountryCodeSetting() {
        List<CountryCodes__c> countryCodes = (List<CountryCodes__c>) new SObjectBuilder(CountryCodes__c.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                        CountryCodes__c.Name => ValueProviderBuilder.provideList(new List<String> {'FRA', 'USA', 'GBR', 'AUS'}),
                        CountryCodes__c.CountryName__c => ValueProviderBuilder.provideList(new List<String> {'fra;france', 'usa;united states', 'gbr;united kingdom', 'aus;australia'}),
                        CountryCodes__c.CountryNameFull__c => ValueProviderBuilder.provideList(new List<String> {'France', 'United States, United Kingdom', 'Australia'}),
                        CountryCodes__c.CountryNameShort__c => ValueProviderBuilder.provideList(new List<String> {'FR', 'US', 'GB', 'AU'}),
                        CountryCodes__c.VATNumbersByName__c => ValueProviderBuilder.provideList(new List<String> {'VAT', '', 'VAT', 'GST'})
                })
                .quantity(4)
                .create()
                .getRecords();

        System.assertEquals(countryCodes.size() > 0, true, 'Settings CountryCodes__c must be set.');
        for (CountryCodes__c codes : countryCodes) {
            System.assertEquals(codes.Name != null, true, 'Settings CountryCodes__c.Name must be set.');
            System.assertEquals(codes.CountryName__c != null, true, 'Settings CountryCodes__c.CountryName__c must be set.');
            System.assertEquals(codes.CountryNameFull__c != null, true, 'Settings CountryCodes__c.CountryNameFull__c must be set.');
            System.assertEquals(codes.CountryNameShort__c != null, true, 'Settings CountryCodes__c.CountryNameShort__c must be set.');
            System.assertEquals(codes.VATNumbersByName__c != null, true, 'Settings CountryCodes__c.VATNumbersByName__c must be set.');
        }

        List<String> values = new List<String>{'AustRaliA', 'AuS', 'Au', 'Australia'};
        CountryCodes__c value1 = SettingsService.getCountryCodeSetting(values[0]);
        CountryCodes__c value2 = SettingsService.getCountryCodeSetting(values[1]);
        CountryCodes__c value3 = SettingsService.getCountryCodeSetting(values[2]);
        CountryCodes__c value4 = SettingsService.getCountryCodeSetting(values[3]);
        CountryCodes__c value5 = SettingsService.getCountryCodeSetting(null);
        CountryCodes__c value6 = SettingsService.getCountryCodeSetting('');
        System.assertEquals(value1.CountryNameShort__c, 'AU', 'Country must be returned from custom settings');
        System.assertEquals(value2.CountryNameShort__c, 'AU', 'Country must be returned from custom settings');
        System.assertEquals(value3.CountryNameShort__c, 'AU', 'Country must be returned from custom settings');
        System.assertEquals(value4.CountryNameShort__c, 'AU', 'Country must be returned from custom settings');
        System.assertEquals(value5, null, 'Country should not be returned from user settings');
        System.assertEquals(value6, null, 'Country should not be returned from user settings');
    }

    @IsTest
    private static void testGetDqProductCategoryOptions() {
        SettingsService.DqProductCategories productCategories = SettingsService.getDqProductCategoryOptions();
        List<PicklistController.Option> salesCategories = (List<PicklistController.Option>) JSON.deserialize(
            productCategories.salesCategoriesJson,
            List<PicklistController.Option>.class
        );
        List<PicklistController.Option> ccCategories = (List<PicklistController.Option>) JSON.deserialize(
            productCategories.ccCategoriesJson,
            List<PicklistController.Option>.class
        );
        System.assertEquals(2, salesCategories.size(), 'method should return 2 test productCategories for "sales quote" record type');
        System.assertEquals(2, ccCategories.size(), 'method should return 2 test productCategories for "contact center" record type');
    }

    @IsTest
    private static void testGetAccessibleTermsMinimal() {
        Profile managerProfile = (Profile) new ProfileSelector()
            .selectProfileByName(new List<Object>{ ProfileHelper.SYSTEM_ADMIN })
            .executeQuery()
            .get(0);

        User testManager = new User(alias = 'm111', email='m111@testorg.com',
        emailencodingkey='UTF-8', lastname='MTesting11', languagelocalekey='en_US',
        localesidkey='en_US', profileid = managerProfile.Id, country='United States',
        timezonesidkey='America/Los_Angeles', username='m111@testorg.com');
        insert testManager;

        List<Schema.PicklistEntry> filteredTermsOptions;
        List<Schema.PicklistEntry> filteredRenewalTermsOptions;
        List<Schema.PicklistEntry> filteredElaTermsOptions;

        System.runAs(testManager) {
            Test.startTest();
           filteredTermsOptions = SettingsService.getAccessibleTerms(
                SFDescribeHelper.getOptions('DQ_Deal_Qualification__c', 'Initial_Term__c')
            );
            filteredRenewalTermsOptions = SettingsService.getAccessibleTerms(
                SFDescribeHelper.getOptions('DQ_Deal_Qualification__c', 'Renewal_Term__c')
            );
            filteredElaTermsOptions = SettingsService.getAccessibleTerms(
                SFDescribeHelper.getOptions('DQ_Deal_Qualification__c', 'ELA_Initial_Terms__c')
            );
        Test.stopTest();
        }

        System.assertEquals(5, filteredTermsOptions.size(), '5 values for Initial_Term__c picklist should be available');
        System.assertEquals(5, filteredRenewalTermsOptions.size(), '5 values for Renewal_Term__c picklist should be available');
        System.assertEquals(5, filteredElaTermsOptions.size(), '5 values for ELA_Initial_Terms__c picklist should be available');
    }

    @IsTest
    private static void testGetAccessibleTermsExtended() {
        Profile managerProfile = (Profile) new ProfileSelector()
            .selectProfileByName(new List<Object>{ ProfileHelper.SYSTEM_ADMIN })
            .executeQuery()
            .get(0);

        User testManager = new User(alias = 'm111', email='m111@testorg.com',
        emailencodingkey='UTF-8', lastname='MTesting11', languagelocalekey='en_US',
        localesidkey='en_US', profileid = managerProfile.Id, country='United States',
        timezonesidkey='America/Los_Angeles', username='m111@testorg.com');
        insert testManager;

        PermissionSet ps = (PermissionSet) new PermissionSetSelector()
        .selectPermissionSetByLabel(new List<Object>{ 'Extended Initial/Renewal Terms' })
        .executeQuery()
        .get(0);
        insert new PermissionSetAssignment(AssigneeId = testManager.id, PermissionSetId = ps.Id);

        List<Schema.PicklistEntry> filteredTermsOptions;
        List<Schema.PicklistEntry> filteredRenewalTermsOptions;
        List<Schema.PicklistEntry> filteredElaTermsOptions;

        System.runAs(testManager) {
            Test.startTest();
            filteredTermsOptions = SettingsService.getAccessibleTerms(
                SFDescribeHelper.getOptions('DQ_Deal_Qualification__c', 'Initial_Term__c')
            );
            filteredRenewalTermsOptions = SettingsService.getAccessibleTerms(
                SFDescribeHelper.getOptions('DQ_Deal_Qualification__c', 'Renewal_Term__c')
            );
            filteredElaTermsOptions = SettingsService.getAccessibleTerms(
                SFDescribeHelper.getOptions('DQ_Deal_Qualification__c', 'ELA_Initial_Terms__c')
            );
        Test.stopTest();
        }

        System.assertEquals(120, filteredTermsOptions.size(), '120 values for Initial_Term__c picklist should be available');
        System.assertEquals(120, filteredRenewalTermsOptions.size(), '120 values for Renewal_Term__c picklist should be available');
        System.assertEquals(120, filteredElaTermsOptions.size(), '120 values for ELA_Initial_Terms__c picklist should be available');
    }

    @IsTest
    private static void testGetAccessibleSpecialTermsMinimal() {
        User thisUser = (User) new UserSelector()
            .selectUsersByIdNoFields(new List<Object>{new List<String>{ UserInfo.getUserId() }})
            .executeQuery()
            .get(0);

        Profile managerProfile = (Profile) new ProfileSelector()
            .selectProfileByName(new List<Object>{ ProfileHelper.SYSTEM_ADMIN })
            .executeQuery()
            .get(0);

        User testManager = new User(alias = 'm111', email='m111@testorg.com',
        emailencodingkey='UTF-8', lastname='MTesting11', languagelocalekey='en_US',
        localesidkey='en_US', profileid = managerProfile.Id, country='United States',
        timezonesidkey='America/Los_Angeles', username='m111@testorg.com');
        insert testManager;

        System.runAs(thisUser) {
            NGBSExtendedSpecialTerms__c extendedSpecialTerms = new NGBSExtendedSpecialTerms__c();
            extendedSpecialTerms.PermissionSet__c = 'Extended_Special_Terms';
            extendedSpecialTerms.ExtendedValues__c = '7;8;9;10;11;12';
            extendedSpecialTerms.Name = 'Extended_Special_Terms';

            NGBSExtendedSpecialTerms__c extendedSpecialTermsTo24 = new NGBSExtendedSpecialTerms__c();
            extendedSpecialTermsTo24.PermissionSet__c = 'Extended_Special_Terms_Up_to_24';
            extendedSpecialTermsTo24.ExtendedValues__c = '13;14;15;16;17;18;19;20;21;22;23;24';
            extendedSpecialTermsTo24.Name = 'Extended_Special_Terms_Up_to_24';

            insert new List<NGBSExtendedSpecialTerms__c>{ extendedSpecialTerms, extendedSpecialTermsTo24 };
        }

        List<Schema.PicklistEntry> filteredSpecialTermsOptions;
        List<Schema.PicklistEntry> filteredSpecialTermsOptionsCC;

        System.runAs(testManager) {
            Test.startTest();
            filteredSpecialTermsOptions = SettingsService.getAccessibleSpecialTerms(
                SFDescribeHelper.getOptionsMap('DQ_Deal_Qualification__c', 'Special_Terms__c')
            );
            filteredSpecialTermsOptionsCC = SettingsService.getAccessibleSpecialTerms(
                SFDescribeHelper.getOptionsMap('DQ_Deal_Qualification__c', 'CC_Special_Terms__c')
            );
            Test.stopTest();
        }

        System.assertEquals(6, filteredSpecialTermsOptions.size(), '6 values for Special_Terms__c picklist should be available');
        System.assertEquals(6, filteredSpecialTermsOptionsCC.size(), '6 values for CC_Special_Terms__c picklist should be available');
    }

    @IsTest
    private static void testGetAccessibleSpecialTermsExtended() {
        User thisUser = (User) new UserSelector()
            .selectUsersByIdNoFields(new List<Object>{new List<String>{ UserInfo.getUserId() }})
            .executeQuery()
            .get(0);

        Profile managerProfile = (Profile) new ProfileSelector()
            .selectProfileByName(new List<Object>{ ProfileHelper.SYSTEM_ADMIN })
            .executeQuery()
            .get(0);

        User testManager = new User(alias = 'm111', email='m111@testorg.com',
        emailencodingkey='UTF-8', lastname='MTesting11', languagelocalekey='en_US',
        localesidkey='en_US', profileid = managerProfile.Id, country='United States',
        timezonesidkey='America/Los_Angeles', username='m111@testorg.com');
        insert testManager;

        System.runAs(thisUser) {
            NGBSExtendedSpecialTerms__c extendedSpecialTerms = new NGBSExtendedSpecialTerms__c();
            extendedSpecialTerms.PermissionSet__c = 'Extended_Special_Terms';
            extendedSpecialTerms.ExtendedValues__c = '7;8;9;10;11;12';
            extendedSpecialTerms.Name = 'Extended_Special_Terms';

            NGBSExtendedSpecialTerms__c extendedSpecialTermsTo24 = new NGBSExtendedSpecialTerms__c();
            extendedSpecialTermsTo24.PermissionSet__c = 'Extended_Special_Terms_Up_to_24';
            extendedSpecialTermsTo24.ExtendedValues__c = '13;14;15;16;17;18;19;20;21;22;23;24';
            extendedSpecialTermsTo24.Name = 'Extended_Special_Terms_Up_to_24';

            insert new List<NGBSExtendedSpecialTerms__c>{ extendedSpecialTerms, extendedSpecialTermsTo24 };
        }

        Set<String> psNames = new Set<String>{ 'Extended_Special_Terms', 'Extended_Special_Terms_Up_to_24' };
        List<PermissionSet> psList = (List<PermissionSet>) new PermissionSetSelector()
            .selectPermissionSetsByName(new List<Object>{ psNames })
            .executeQuery();
        List<PermissionSetAssignment> psAssignments = new List<PermissionSetAssignment>();
        for (PermissionSet ps : psList) {
            psAssignments.add(new PermissionSetAssignment(AssigneeId = testManager.id, PermissionSetId = ps.Id));
        }
        insert psAssignments;

        List<Schema.PicklistEntry> filteredSpecialTermsOptions;
        List<Schema.PicklistEntry> filteredSpecialTermsOptionsCC;

        System.runAs(testManager) {
            Test.startTest();
            filteredSpecialTermsOptions = SettingsService.getAccessibleSpecialTerms(
                SFDescribeHelper.getOptionsMap('DQ_Deal_Qualification__c', 'Special_Terms__c')
            );
            filteredSpecialTermsOptionsCC = SettingsService.getAccessibleSpecialTerms(
                SFDescribeHelper.getOptionsMap('DQ_Deal_Qualification__c', 'CC_Special_Terms__c')
            );
            Test.stopTest();
        }

        System.assertEquals(24, filteredSpecialTermsOptions.size(), '24 values for Special_Terms__c picklist should be available');
        System.assertEquals(24, filteredSpecialTermsOptionsCC.size(), '24 values for CC_Special_Terms__c picklist should be available');
    }

    @isTest
    private static void testGetNonEmptyBIPackages() {
        new SObjectBuilder(NGBSPurchaseSettingsByBI__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                NGBSPurchaseSettingsByBI__c.Name => 'Amazon',
                NGBSPurchaseSettingsByBI__c.NonEmptyBIPackages__c => '12345;67890;54321'
            })
            .quantity(1)
            .create();

        List<String> nonEmptyBIPackages = SettingsService.getNonEmptyBIPackages();

        Assert.areEqual(3, nonEmptyBIPackages.size(), 'amount of restricted packages should be 3');
        Assert.areEqual('67890', nonEmptyBIPackages.get(1), '2nd package Id should be "67890"');
    }

    @isTest
    private static void testGetTargetPriceBusinessIdentityMappingRecords() {

        new SObjectBuilder(TargetPriceBusinessIdentityMapping__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                TargetPriceBusinessIdentityMapping__c.Name => ValueProviderBuilder.provideList(new List<String>{
                    'RingCentral EU India', 'RingCentral EU Singapore'
                }),
                TargetPriceBusinessIdentityMapping__c.BrandName__c => ValueProviderBuilder.provideList(new List<String>{
                    'RingCentral EU'
                }),
                TargetPriceBusinessIdentityMapping__c.Currency__c => ValueProviderBuilder.provideList(new List<String>{
                    'inr', 'sgd'
                }),
                TargetPriceBusinessIdentityMapping__c.IsCCLegacyCanBeSold__c => false
            })
            .quantity(2)
            .create();

        List<SettingsService.TargetPriceBusinessIdentityMapping> BISettings = SettingsService.getTargetPriceBusinessIdentityMappingRecords();

        System.assertEquals(2, BISettings.size(), 'should return target price business identity settings');
    }

    @isTest
    private static void testGetSubBrandAndDefaultBI() {
        Triggers.switchOff();

        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.EnableBusinessIdentityMapping__c, true)
            .create();

        Account partnerAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => ValueProviderBuilder.provideUniqueString('Test Partner Account'),
                Account.BillingCountry => 'United States',
                Account.CurrencyIsoCode => 'USD',
                Account.ParentId => null,
                Account.Ultimate_Account__c => null,
                Account.Type => 'Partner',
                Account.Partner_ID__c => ValueProviderBuilder.provideUniqueString('10000'),
                Account.RC_Brand__c => 'RingCentral'
            })
            .create()
            .getRecord();

        new SObjectBuilder(SubBrandsMapping__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                SubBrandsMapping__c.Name => 'Test Name',
                SubBrandsMapping__c.Sub_Brand__c => '1210.AMZN',
                SubBrandsMapping__c.Brand__c => 'RingCentral',
                SubBrandsMapping__c.Country__c => 'United States',
                SubBrandsMapping__c.PartnerID__c => partnerAccount.Partner_ID__c
            })
            .create();

        Triggers.switchOn();

        String defaultBI = SettingsService.getSubBrandAndDefaultBI(null, partnerAccount.Id).get('defaultBI');
        String subBrand = SettingsService.getSubBrandAndDefaultBI(null, partnerAccount.Id).get('subBrand');
        // System.assertEquals('Amazon US', defaultBI, 'defaultBI should be Amazon US');
        System.assertEquals('1210.AMZN', subBrand, 'subBrand should be 1210.AMZN');
    }

    @isTest
    private static void testGetSubBrandAndDefaultBIFeatureToggleOff() {
        Triggers.switchOff();

        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.EnableBusinessIdentityMapping__c, false)
            .create();

        Account partnerAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => ValueProviderBuilder.provideUniqueString('Test Partner Account'),
                Account.BillingCountry => 'United States',
                Account.CurrencyIsoCode => 'USD',
                Account.ParentId => null,
                Account.Ultimate_Account__c => null,
                Account.Type => 'Partner',
                Account.Partner_ID__c => ValueProviderBuilder.provideUniqueString('10000'),
                Account.RC_Brand__c => 'RingCentral'
            })
            .create()
            .getRecord();

        new SObjectBuilder(SubBrandsMapping__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                SubBrandsMapping__c.Name => 'Test Name',
                SubBrandsMapping__c.Sub_Brand__c => '1210.AMZN',
                SubBrandsMapping__c.Brand__c => 'RingCentral',
                SubBrandsMapping__c.Country__c => 'United States',
                SubBrandsMapping__c.PartnerID__c => partnerAccount.Partner_ID__c
            })
            .create();

        Triggers.switchOn();

        String defaultBI = SettingsService.getSubBrandAndDefaultBI(null, partnerAccount.Id).get('defaultBI');
        String subBrand = SettingsService.getSubBrandAndDefaultBI(null, partnerAccount.Id).get('subBrand');
        System.assertEquals('', defaultBI, 'defaultBI should not be set');
        System.assertEquals('1210.AMZN', subBrand, 'subBrand should be 1210.AMZN');
    }

    @isTest
    private static void testGetSubBrandToDefaultBIMap() {
        List<Default_Business_Identity_Mapping__mdt> defaultBIMap = new SettingsService.NoSharing().getDefaultBusinessIdentityMapping();
        Map<String, String> firstMap = new Map<String, String>();
        for (Default_Business_Identity_Mapping__mdt record : defaultBIMap) {
            if (String.isNotBlank(record.Sub_Brand__c)) {
                firstMap.put(record.Sub_Brand__c, record.Default_Business_Identity__c);
            }
        }
        Map<String, String> resultMap = new SettingsService.NoSharing().getSubBrandToDefaultBIMap();
        System.assertEquals(firstMap.size(), resultMap.size(), 'map size should be equal');
    }

    @isTest
    private static void verifyLicensesUnavailableSettingsIsBuiltCorrectForPRM() {
        SettingsService.LicensesSettings licenseConfig = SettingsService.getLicenseSettings(false, new List<String>());
        Map<String, Set<String>> hiddenLicensesSettings = licenseConfig.licensesUnavailableForPRM;

        System.assertEquals(1, hiddenLicensesSettings.size());
        System.assert(hiddenLicensesSettings.containsKey('All'));
        System.assertEquals(1, hiddenLicensesSettings.get('All').size());
        System.assert(hiddenLicensesSettings.get('All').contains('LC_HD_522'));
    }

    @isTest
    private static void testGetAvailableBusinessIdentities() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.EnableBusinessIdentityMapping__c, true)
            .create();
        List<String> resultAvailableBIs = SettingsService.getAvailableBusinessIdentities('RingCentral Inc.', '', 'United States', 'RingCentral');

        System.assertEquals(resultAvailableBIs[0], 'RingCentral Canada');
    }

    @isTest
    private static void testGSPPartnerSetup() {
        GSP_Partner_Setup__c gspPartnerSetup = (GSP_Partner_Setup__c) new SObjectBuilder(GSP_Partner_Setup__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                GSP_Partner_Setup__c.Name => 'Apple',
                GSP_Partner_Setup__c.Validate_by_Brand__c => true,
                GSP_Partner_Setup__c.Disable_PDF__c => false,
                GSP_Partner_Setup__c.Disable_POC__c => false,
                GSP_Partner_Setup__c.Has_NGBS_Packages__c => true,
                GSP_Partner_Setup__c.Disable_ProServ__c => false,
                GSP_Partner_Setup__c.Validation_name__c => 'Apple'
            })
            .create()
            .getRecord();

        Opportunity opp = attachAccountToOpportunity(
            (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setField(Opportunity.Name, 'Test Opportunity')
                .setField(Opportunity.Brand_Name__c, 'Apple')
                .setField(Opportunity.BusinessIdentity__c, '{"currency":"USD","biId":"4"}')
                .build()
                .getRecord(),
            (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
                .setField(Account.GSP__c, true)
                .build()
                .getRecord()
        );

        Test.startTest();
        SettingsService.GSPPartnerSetup result = new SettingsService.GSPPartnerSetup(opp);
        Test.stopTest();

        System.assertEquals(result.exist(), true, 'Setup should exist for this brand');
        System.assertEquals(result.isQuotingNotSupported(), false, 'Quoting should be supported');
        System.assertEquals(result.isDisablePDF, false, 'PDF should not be disabled');
    }

    @isTest
    private static void testGSPPartnerSetupWithoutSetting() {
        Opportunity opp = attachAccountToOpportunity(
            (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setField(Opportunity.Name, 'Test Opportunity')
                .setField(Opportunity.Brand_Name__c, 'Apple')
                .setField(Opportunity.BusinessIdentity__c, '{"currency":"USD","biId":"4"}')
                .build()
                .getRecord(),
            (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
                .setField(Account.GSP__c, true)
                .build()
                .getRecord()
        );

        Test.startTest();
        SettingsService.GSPPartnerSetup result = new SettingsService.GSPPartnerSetup(opp);
        Test.stopTest();

        System.assertEquals(result.exist(), false, 'Setup should not exist for this brand/BI');
    }

    @isTest
    private static void testOnlyProServQuotesAvailable() {
        GSP_Partner_Setup__c gspPartnerSetup = (GSP_Partner_Setup__c) new SObjectBuilder(GSP_Partner_Setup__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                GSP_Partner_Setup__c.Name => 'Apple',
                GSP_Partner_Setup__c.Validate_by_Brand__c => true,
                GSP_Partner_Setup__c.Disable_PDF__c => false,
                GSP_Partner_Setup__c.Disable_POC__c => false,
                GSP_Partner_Setup__c.Has_NGBS_Packages__c => true,
                GSP_Partner_Setup__c.Disable_ProServ__c => false,
                GSP_Partner_Setup__c.Disable_Commercial_Quoting__c => true,
                GSP_Partner_Setup__c.Validation_name__c => 'Apple'
            })
            .create()
            .getRecord();

        Opportunity opp = attachAccountToOpportunity(
            (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setField(Opportunity.Name, 'Test Opportunity')
                .setField(Opportunity.Brand_Name__c, 'Apple')
                .setField(Opportunity.BusinessIdentity__c, '{"currency":"USD","biId":"4"}')
                .build()
                .getRecord(),
            (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
                .setField(Account.GSP__c, true)
                .build()
                .getRecord()
        );

        Test.startTest();
            Boolean result = SettingsService.onlyProServQuotesAvailable(opp);
        Test.stopTest();

        System.assertEquals(true, result, 'only proserv quotes should be available for this opportunity');
    }

    @isTest
    private static void testGetOppTeamMembersWithSERole() {
        Account acc = TestDataGenerator.createAccount('test Account');
        Opportunity testOpportunity = TestDataGenerator.createOpportunity(acc);
        
        Profile userProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User usr = (User) new SObjectBuilder(User.SObjectType)
            .setField(User.FirstName, 'Test')
            .setField(User.LastName, 'User')
            .setField(User.Email, 'testuser@example.com')
            .setField(User.Username, 'testuser@example.com' + System.currentTimeMillis())
            .setField(User.Alias, 'tuser')
            .setField(User.TimeZoneSidKey, 'America/Los_Angeles')
            .setField(User.LocaleSidKey, 'en_US')
            .setField(User.EmailEncodingKey, 'UTF-8')
            .setField(User.ProfileId, userProfile.Id)
            .setField(User.LanguageLocaleKey, 'en_US')
            .create()
            .getRecord();

        OpportunityTeamMember otm = (OpportunityTeamMember) new SObjectBuilder(OpportunityTeamMember.SObjectType)
            .setField(OpportunityTeamMember.OpportunityId, testOpportunity.Id)
            .setField(OpportunityTeamMember.UserId, usr.Id)
            .setField(OpportunityTeamMember.TeamMemberRole, 'Solutions Engineer (Primary)')
            .create()
            .getRecord();
        
        Test.startTest();
        Boolean hasSERole = SettingsService.oppTeamMembersWithSERole(testOpportunity.Id);
        Test.stopTest();
        
        Assert.isTrue(hasSERole, 'The method should return true when an OpportunityTeamMember with Solutions Engineer (Primary) role exists.');
        
    }
}