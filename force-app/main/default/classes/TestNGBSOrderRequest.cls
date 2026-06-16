@IsTest
private class TestNGBSOrderRequest {

    public static final String packageQLIInfoDL75 = '{"Version":"1","q":null,"Price":0,"parent":null,"lboxes":null,"Id":"18","duration":"Monthly","Discount":{"Value":0,"Type":"Percent"},"categoryPath":null,"CategoryCode":"DL"}';
    public static final String packageQLIInfoALN38 = '{"Version":"1","q":null,"Price":null,"parent":null,"lboxes":null,"Id":"18","duration":"Monthly","Discount":{"Value":0,"Type":"Money"},"categoryPath":"ALN","CategoryCode":"ALN"}';
    public static final String packageQLIInfoCRF51 = '{"Version":"1","q":33,"Price":null,"parent":null,"lboxes":null,"Id":"18","duration":"Monthly","Discount":{"Value":0,"Type":"Money"},"categoryPath":"DL:CRF","CategoryCode":"CRF"}';
    public static final String packageQLIInfoHD139 = '{"Version":"1","q":null,"Price":null,"parent":null,"lboxes":null,"Id":"18","duration":"One - Time","Discount":{"Value":0,"Type":"Money"},"categoryPath":"HD","CategoryCode":"HD"}';
    public static final String packageQLIInfoHD140 = '{"Version":"1","q":null,"Price":null,"parent":null,"lboxes":null,"Id":"18","duration":"One - Time","Discount":{"Value":0,"Type":"Money"},"categoryPath":"HD","CategoryCode":"HD"}';
    public static final String packageQLIInfoDLUNL_50 = '{"Version":"1","q":14,"Price":0,"parent":"LC_DL_75","lboxes":null,"Id":"18","duration":"Monthly","Discount":{"Value":0,"Type":"Percent"},"categoryPath":null,"CategoryCode":"DL-UNL"}';
    public static final String packageQLIInfoATN39 = '{"Version":"1","q":null,"Price":null,"parent":null,"lboxes":null,"Id":"18","duration":"Monthly","Discount":{"Value":0,"Type":"Money"},"categoryPath":"ATN","CategoryCode":"ATN"}';
    public static final String packageQLIInfoE91152 = '{"Version":"1","q":null,"Price":null,"parent":null,"lboxes":null,"Id":"18","duration":"Monthly","Discount":{"Value":0,"Type":"Money"},"categoryPath":"DL:E911","CategoryCode":"E911"}';
    public static final String packageQLIInfoDLBAS178 = '{"Version":"1","q":null,"Price":0,"parent":"LC_DL_75","lboxes":null,"Id":"18","duration":"Monthly","Discount":{"Value":0,"Type":"Percent"},"categoryPath":null,"CategoryCode":"DL-BAS"}';
    public static final String packageQLIInfoEES489 = '{"categoryCode":"EES","discount":{"value":0,"type":"Money"},"duration":"Monthly","id":"18","version":"1","q":null,"lboxes":[{"elementID":"LB_495","min":0,"max":1}],"categoryPath":"EES"}';
    public static final String packageQLIInfoEESTAM949 = '{"categoryCode":"EES-TAM","discount":{"value":0,"type":"Money"},"duration":"Monthly","id":"18","version":"1","q":null,"lboxes":[{"elementID":"LB_496","min":0,"max":1}],"categoryPath":"EES:EES-TAM"}';
    public static final String packageQLIInfoSIP3P941 = '{"categoryCode":"SIP3P","discount":{"value":0,"type":"Money"},"duration":"Monthly","id":"18","version":"1","q":null,"lboxes":null,"categoryPath":"SIP3P"}';
    public static final String LC_DL_75 = 'LC_DL_75';
    public static final String LC_ALN_38 = 'LC_ALN_38';
    public static final String LC_CRF_51 = 'LC_CRF_51';
    public static final String LC_HD_139 = 'LC_HD_139';
    public static final String LC_HD_140 = 'LC_HD_140';
    public static final String LC_DL_BAS_178 = 'LC_DL-BAS_178';
    public static final String LC_DL_UNL_50 = 'LC_DL-UNL_50';
    public static final String LC_ATN_39 = 'LC_ATN_39';
    public static final String LC_E911_52 = 'LC_E911_52';
    public static final String LC_EES_489 = 'LC_EES_489';
    public static final String LC_EES_TAM_949 = 'LC_EES-TAM_949';
    public static final String LC_SIP3P_941 = 'LC_SIP3P_941';

    private static final String BASE_ENDPOINT = 'http://test.com';
    private static final String MANAGER_PATH = 'http://test.com/test_manager';

    public static final List<String> catalogIds = new List<String>{
            LC_DL_75, LC_ALN_38, LC_CRF_51, LC_HD_139, LC_DL_BAS_178, LC_DL_UNL_50, LC_ATN_39, LC_E911_52, LC_HD_140, LC_EES_489, LC_EES_TAM_949, LC_SIP3P_941
    };

    private static String BILLING_INFO_ALL_LICENSE_RESPONSE = '{"productLine" : "RC","packageId" : "25309001","packageExpirationDate" : null,"packageDuration" : null,"packageDescription" : "RingCentral Office Standard","nextBillingDate" : "2021-04-03T07:00Z[UTC]","licenses" : ['
        + '{"topLicenseId" : "369246001","scheduledForRemoval" : false,"replacement" : null,"qty" : 12,"price" : 4.99,"licenseTypeId" : null,"licenseId" : "369246001","discount" : null,"description" : "Additional Local Number","categoryId" : "ALN","catalogId" : "LC_ALN_38","billingStartDate" : "2021-03-03","billingEndDate" : "2021-04-02","billingCycleDuration" : "Monthly","batch" : true }, {'
        + '"topLicenseId" : "369247001","scheduledForRemoval" : false,"replacement" : null,"qty" : 1,"price" : 49.0,"licenseTypeId" : "2","licenseId" : "369247001","discount" : null,"description" : "RingCentral Rooms License","categoryId" : "RCRM","catalogId" : "LC_RCRM_77","billingStartDate" : "2021-03-03","billingEndDate" : "2021-04-02","billingCycleDuration" : "Monthly","batch" : null }, {'
        + '"topLicenseId" : "369248001","scheduledForRemoval" : false,"replacement" : null,"qty" : 1,"price" : 49.0,"licenseTypeId" : "2","licenseId" : "369248001","discount" : null,"description" : "RingCentral Rooms License","categoryId" : "RCRM","catalogId" : "LC_RCRM_77","billingStartDate" : "2021-03-03","billingEndDate" : "2021-04-02","billingCycleDuration" : "Monthly","batch" : null }, {'
        + '"topLicenseId" : "369174001","scheduledForRemoval" : false,"replacement" : null,"qty" : 1,"price" : 0.5,"licenseTypeId" : null,"licenseId" : "369174001","discount" : null,"description" : "Cloud Recording Storage Overage","categoryId" : "CRO","catalogId" : "LC_CRO_574","billingStartDate" : "2021-03-03","billingEndDate" : "2021-04-02","billingCycleDuration" : "Monthly","batch" : null }, {'
        + '"topLicenseId" : "369175001","scheduledForRemoval" : false,"replacement" : null,"qty" : 1,"price" : 34.99,"licenseTypeId" : null,"licenseId" : "369175001","discount" : null,"description" : "Mobile User","categoryId" : "MU","catalogId" : "LC_MU_281","billingStartDate" : "2021-03-03","billingEndDate" : "2021-04-02","billingCycleDuration" : "Monthly","batch" : null }, {'
        + '"topLicenseId" : "369176001","scheduledForRemoval" : false,"replacement" : null,"qty" : 1,"price" : 0.0,"licenseTypeId" : null,"licenseId" : "369176001","discount" : null,"description" : "Office Standard - Subscription Fee","categoryId" : "SC","catalogId" : "LC_SC_29","billingStartDate" : "2021-03-03","billingEndDate" : "2021-04-02","billingCycleDuration" : "Monthly","batch" : null }, {'
        + '"topLicenseId" : "369177001","scheduledForRemoval" : false,"replacement" : null,"qty" : 1,"price" : 0.0,"licenseTypeId" : null,"licenseId" : "369177001","discount" : null,"description" : "Compliance and Administrative Cost Recovery Fee","categoryId" : "CRF","catalogId" : "LC_CRF_43","billingStartDate" : "2021-03-03","billingEndDate" : "2021-04-02","billingCycleDuration" : "Monthly","batch" : null }, {'
        + '"topLicenseId" : "369189001","scheduledForRemoval" : false,"replacement" : null,"qty" : 25,"price" : 4.0,"licenseTypeId" : null,"licenseId" : "369191001","discount" : null,"description" : "Compliance and Administrative Cost Recovery Fee","categoryId" : "CRF","catalogId" : "LC_CRF_51","billingStartDate" : "2021-03-03","billingEndDate" : "2021-04-02","billingCycleDuration" : "Monthly","batch" : true }, {'
        + '"topLicenseId" : "369189001","scheduledForRemoval" : false,"replacement" : null,"qty" : 25,"price" : 1.0,"licenseTypeId" : null,"licenseId" : "369192001","discount" : null,"description" : "e911 Service Fee","categoryId" : "E911","catalogId" : "LC_E911_52","billingStartDate" : "2021-03-03","billingEndDate" : "2021-04-02","billingCycleDuration" : "Monthly","batch" : true }, {'
        + '"topLicenseId" : "369189001","scheduledForRemoval" : false,"replacement" : null,"qty" : 25,"price" : 34.99,"licenseTypeId" : null,"licenseId" : "369190001","discount" : null,"description" : "DigitalLine Unlimited","categoryId" : "DL-UNL","catalogId" : "LC_DL-UNL_50","billingStartDate" : "2021-03-03","billingEndDate" : "2021-04-02","billingCycleDuration" : "Monthly","batch" : true }, {'
        + '"topLicenseId" : "369180001","scheduledForRemoval" : false,"replacement" : null,"qty" : 1,"price" : 34.99,"licenseTypeId" : null,"licenseId" : "369182001","discount" : null,"description" : "DigitalLine Unlimited","categoryId" : "DL-UNL","catalogId" : "LC_DL-UNL_50","billingStartDate" : "2021-03-03","billingEndDate" : "2021-04-02","billingCycleDuration" : "Monthly","batch" : null}, {'
        + '"topLicenseId" : "369180001","scheduledForRemoval" : false,"replacement" : null,"qty" : 1,"price" : 4.0,"licenseTypeId" : null,"licenseId" : "369183001","discount" : null,"description" : "Compliance and Administrative Cost Recovery Fee","categoryId" : "CRF","catalogId" : "LC_CRF_51","billingStartDate" : "2021-03-03","billingEndDate" : "2021-04-02","billingCycleDuration" : "Monthly","batch" : null}, {'
        + '"topLicenseId" : "369180001","scheduledForRemoval" : false,"replacement" : null,"qty" : 1,"price" : 1.0,"licenseTypeId" : null,"licenseId" : "369184001","discount" : null,"description" : "e911 Service Fee","categoryId" : "E911","catalogId" : "LC_E911_52","billingStartDate" : "2021-03-03","billingEndDate" : "2021-04-02","billingCycleDuration" : "Monthly","batch" : null }, {'
        + '"topLicenseId" : "369487001","scheduledForRemoval" : false,"replacement" : null,"qty" : 1,"price" : 10000.0,"props" : {"LicenseTypeId" : "29"},"licenseId" : "369487001","discount" : null,"description" : "Extended Enterprise Support - Platinum Tier - Office","categoryId" : "EES","catalogId" : "LC_EES_489","billingStartDate" : "2021-03-03","billingEndDate" : "2021-04-02","billingCycleDuration":"Monthly","batch":null},{'
        + '"topLicenseId" : "13186910013","scheduledForRemoval" : false,"replacement" : null,"qty" : 20,"price" : 25.0,"props" : {"LicenseTypeId" : "29"},"licenseId" : "369487001","discount" : null,"description" : "SIP Connection to 3rd Party Provider","categoryId" : "SIP3P","catalogId" : "LC_SIP3P_941","billingStartDate" : "2021-03-03","billingEndDate" : "2021-04-02","billingCycleDuration":"Monthly","batch":true},{'
        + '"topLicenseId" : "369487001","scheduledForRemoval" : false,"replacement" : null,"qty" : 1,"price" : 2000.0,"licenseTypeId" : null,"licenseId" : "369488001","discount" : null,"description" : "Extended Enterprise Support - Platinum Tier - Office - Additional TAM","categoryId" : "EES-TAM","catalogId" : "LC_EES-TAM_949","billingStartDate" : "2021-03-03","billingEndDate" : "2021-04-02","billingCycleDuration":"Monthly","batch":null}],"creditBalance" : 0,"accountId" : "25309001"}';

    private static String PACKAGE_INFO = '[{"id":"18","version":"1","packageInfo":{"id":116477002,"catalogId":"18","version":"1","name":"Office Standard 1/2/100/1000+ Lines - 5100/5101/5102/5103","displayName":"RingCentral Office Standard","oldPackageName":"RingCentral Office Standard"},"productName":"Office","productId":"2","duration":"Monthly","edition":{"id":1,"name":"Standard"},"contract":null,"offerType":"Regular","poc":null,"globalPackageLimits":[{"value":"50000","code":"MONTHLY_AMOUNT_LIMIT","name":"Monthly money amount limit","type":"Amount","scope":"BillingCycle","transactionType":"Any","target":"Global","exclusions":[{"target":"LicenseCategoryId","targetId":"AP"}],"override":false}],"permissions":null,"packageBusinessIdentities":{"selectedBi":{"name":"RingCentral Inc.","isDefault":true,"id":"4","address":{"zip":"94002","street2":"","street1":"20 Davis Dr","state":"CA","phone":"","lastName":"","label":null,"firstName":"RingCentral, Inc.","county":"","country":"USA","city":"Belmont"}},"defaultBi":{"name":"RingCentral Inc.","isDefault":true,"id":"4","address":{"zip":"94002","street2":"","street1":"20 Davis Dr","state":"CA","phone":"","lastName":"","label":null,"firstName":"RingCentral, Inc.","county":"","country":"USA","city":"Belmont"}},"approvedBi":{"name":"RingCentral Inc.","isDefault":true,"id":"4","address":{"zip":"94002","street2":"","street1":"20 Davis Dr","state":"CA","phone":"","lastName":"","label":null,"firstName":"RingCentral, Inc.","county":"","country":"USA","city":"Belmont"}}},"existingPackageInfo":{"id":"18","version":"1","offerType":"Regular","productName":"Office"}}]';

    @TestSetup
    static void testSetup() {

        Triggers.switchOff();
        new SObjectBuilder(NGBS_Order_API_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
            NGBS_Order_API_Settings__c.Batch_False_Licenses_Codes__c => 'GLP;LR;ICI;RCRM;RCON;NM;MS;EES;CC;CCES;ATN'
        })
        .create()
        .getRecord();

        NGBS_Settings__c settings = (NGBS_Settings__c) new SObjectBuilder(NGBS_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                NGBS_Settings__c.BaseEndpoint__c => BASE_ENDPOINT,
                NGBS_Settings__c.AccountManagerPath__c => MANAGER_PATH,
                NGBS_Settings__c.Login__c => ValueProviderBuilder.provideUniqueString(),
                NGBS_Settings__c.Password__c => ValueProviderBuilder.provideUniqueString()
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
                Account.BillingCountry => 'United States'
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
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => system.today().addMonths(1),
                Opportunity.Primary_Opportunity_Contact__c => cont.Id,
                Opportunity.CurrencyIsoCode => RingCentralHelper.USD
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
                Quote.Package_Info__c => PACKAGE_INFO,
                Quote.isPrimary__c => true,
                Quote.Enabled_LBO__c => true
            })
            .create()
            .getRecord();

        List<Product2> products = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => ValueProviderBuilder.provideList(new List<String> {'DigitalLine','Additional Local Number', 'Compliance and Administrative Cost Recovery Fee', 'Polycom VVX501 with 1 Expansion Module', 'DigitalLine Basic', 'DigitalLine Unlimited', 'Additional Toll-Free Number', 'e911 Service Fee', 'Polycom VVX501 with 1 Expansion Module', 'Extended Enterprise Support - Platinum Tier - Office', 'Extended Enterprise Support - Platinum Tier - Office - Additional TAM', 'SIP Connection to 3rd Party Provider'}),
                Product2.ExtID__c => ValueProviderBuilder.provideList(catalogIds),
                Product2.Charge_Term__c => ValueProviderBuilder.provideList(new List<String> {Product2Helper.CHARGE_TERM_MONTHLY, Product2Helper.CHARGE_TERM_MONTHLY, Product2Helper.CHARGE_TERM_MONTHLY, Product2Helper.CHARGE_TERM_ONE_TIME, Product2Helper.CHARGE_TERM_MONTHLY, Product2Helper.CHARGE_TERM_MONTHLY, Product2Helper.CHARGE_TERM_MONTHLY, Product2Helper.CHARGE_TERM_MONTHLY, Product2Helper.CHARGE_TERM_ONE_TIME, Product2Helper.CHARGE_TERM_MONTHLY, Product2Helper.CHARGE_TERM_MONTHLY, Product2Helper.CHARGE_TERM_MONTHLY}),
                Product2.Family => ValueProviderBuilder.provideList(new List<String>{Product2Helper.FAMILY_TECHNICAL_LICENSE, Product2Helper.FAMILY_ADDONS, Product2Helper.FAMILY_FEE, Product2Helper.FAMILY_DISCOUNTED_PHONES, null, Product2Helper.FAMILY_SERVICE, Product2Helper.FAMILY_ADDONS, Product2Helper.FAMILY_FEE, Product2Helper.FAMILY_DISCOUNTED_PHONES, null, null, null}),
                Product2.IsActive => true,
                Product2.ShippingType__c => ValueProviderBuilder.provideList(new List<String> {'', '', '', Product2Helper.SHIPPING_TYPE_AUTO, '', '', '', '', Product2Helper.SHIPPING_TYPE_MANUAL, '', '', ''})
            })
            .quantity(12)
            .create()
            .getRecords();

        List<PricebookEntry> pbe = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.SObjectType)
            .quantity(11)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => ValueProviderBuilder.provideList(new List<Id>{products[0].Id, products[1].Id, products[2].Id, products[3].Id, products[4].Id, products[5].Id, products[6].Id, products[7].Id, products[8].Id, products[9].Id, products[10].Id, products[11].Id}),
                PricebookEntry.UnitPrice => 100,
                PricebookEntry.IsActive => true
            })
            .create()
            .getRecords();

        List<Entitlement__c> ents = (List<Entitlement__c>) new SObjectBuilder(Entitlement__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Entitlement__c.Account__c => acc.Id,
                Entitlement__c.Quote__c => qt.Id,
                Entitlement__c.Active__c => true,
                Entitlement__c.ChargeTerm__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Entitlement__c.Quantity__c => ValueProviderBuilder.provideList(new List<Integer> {1,3,20}),
                Entitlement__c.Product__c => ValueProviderBuilder.provideList(new List<Id>{products[9].Id, products[10].Id, products[11].Id})
            })
            .quantity(3)
            .create()
            .getRecords();

        List<QuoteLineItem> qlis = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Product2Id => ValueProviderBuilder.provideList(new List<Id>{products[0].Id, products[1].Id, products[2].Id, products[3].Id, products[4].Id, products[5].Id, products[6].Id, products[7].Id, products[8].Id, products[9].Id, products[10].Id, products[11].Id}),
                QuoteLineItem.Quantity => ValueProviderBuilder.provideList(new List<Integer> {10,10,10,10,10,10,10,10,10,1,1,1}),
                QuoteLineItem.NewQuantity__c => ValueProviderBuilder.provideList(new List<Integer> {10,10,10,10,10,10,10,10,10,1,1,1}),
                QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideList(new List<Id> {pbe[0].Id, pbe[1].Id, pbe[2].Id, pbe[3].Id, pbe[4].Id, pbe[5].Id, pbe[6].Id, pbe[7].Id, pbe[8].Id, pbe[9].Id, pbe[10].Id}),
                QuoteLineItem.UnitPrice => 10.00,
                QuoteLineItem.PackageInfo__c =>ValueProviderBuilder.provideList(new List<String>{packageQLIInfoDL75, packageQLIInfoALN38, packageQLIInfoCRF51, packageQLIInfoHD139, packageQLIInfoDLBAS178, packageQLIInfoDLUNL_50, packageQLIInfoATN39, packageQLIInfoE91152, packageQLIInfoHD140, packageQLIInfoEES489, packageQLIInfoEESTAM949, packageQLIInfoSIP3P941}),
                QuoteLineItem.Package_Info_QLI__c =>ValueProviderBuilder.provideList(new List<String>{packageQLIInfoDL75, packageQLIInfoALN38, packageQLIInfoCRF51, packageQLIInfoHD139, packageQLIInfoDLBAS178, packageQLIInfoDLUNL_50, packageQLIInfoATN39, packageQLIInfoE91152, packageQLIInfoHD140, packageQLIInfoEES489, packageQLIInfoEESTAM949, packageQLIInfoSIP3P941})
            })
            .quantity(12)
            .create()
            .getRecords();
        Triggers.switchOn();

        for (QuoteLineItem qli : qlis) {
            if(qli.PackageInfo__c == packageQLIInfoEES489) {
                qli.Entitlement__c = ents[0].Id;
                qli.Zero_Quantity__c = true;
                qli.NewQuantity__c = 1;
                Triggers.switchOff();
                update qli;
                Triggers.switchOn();
            }
            if (qli.PackageInfo__c == packageQLIInfoEESTAM949) {
                qli.Entitlement__c = ents[1].Id;
                qli.Zero_Quantity__c = true;
                qli.NewQuantity__c = 1;
                Triggers.switchOff();
                update qli;
                Triggers.switchOn();
            }
            if (qli.PackageInfo__c == packageQLIInfoSIP3P941) {
                qli.Entitlement__c = ents[2].Id;
                qli.Zero_Quantity__c = true;
                qli.NewQuantity__c = 1;
                Triggers.switchOff();
                update qli;
                Triggers.switchOn();
            }
        }

        CustomAddress__c ca = (CustomAddress__c) new SObjectBuilder(CustomAddress__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                CustomAddress__c.AddressLine__c => '2078 Adamsville Road',
                CustomAddress__c.City__c => 'Laredo',
                CustomAddress__c.PostalCode__c => '78040',
                CustomAddress__c.State__c => 'Texas',
                CustomAddress__c.Country__c => 'United States'
            })
            .create()
            .getRecord();
    }

    @isTest static void verifyEmptyCallNGBSOrderRequest() {
        NGBSOrderRequest nor = new NGBSOrderRequest();
        String norResponse = nor.toString();
        System.assertEquals(norResponse.contains(NGBSOrderRequest.BILLING_STATE_PURCHASED), true, 'Request must return final constants');
        System.assertEquals(norResponse.contains(NGBSOrderRequest.TECHNICAL_LICENSE_DL_75), true, 'Request must return final constants');
        System.assertEquals(norResponse.contains(NGBSOrderRequest.TECHNICAL_LICENSE_FDL_401), true, 'Request must return final constants');
        System.assertEquals(norResponse.contains(NGBSOrderRequest.TECHNICAL_LICENSE_DL_CC_735), true, 'Request must return final constants');
        System.assertEquals(norResponse.contains(NGBSOrderRequest.TECHNICAL_LICENSE_CRF), true, 'Request must return final constants');
        System.assertEquals(norResponse.contains(NGBSOrderRequest.TECHNICAL_LICENSE_E911), true, 'Request must return final constants');
        System.assertEquals(norResponse.contains(NGBSOrderRequest.TECHNICAL_LICENSE_E911_CC), true, 'Request must return final constants');
        System.assertEquals(norResponse.contains(NGBSOrderRequest.TECHNICAL_LICENSE_CRF_CC), true, 'Request must return final constants');
        System.assertEquals(norResponse.contains(NGBSOrderRequest.TWO_DAYS_SHIPPING_METHOD), true, 'Request must return final constants');
        System.assertEquals(norResponse.contains(NGBSOrderRequest.BILLING_TWO_DAYS_SHIPPING_METHOD), true, 'Request must return final constants');
    }

    @isTest static void verifyOrderRequestGenerationItemsToAddWithDeviceCostCenterShippingAddress() {

        Account acc = getAccount();
        Opportunity opp = acc.Opportunities[0];
        CustomAddress__c ca = getCustomAddress(acc.BillingCountry, acc.BillingCity, acc.BillingPostalCode, acc.BillingStreet, acc.BillingState);
        Quote qt = getQuote(opp.Name);
        Triggers.switchOff();
        delete new List<QuoteLineItem> {qt.QuoteLineItems[0], qt.QuoteLineItems[1]};
        qt = getQuote(opp.Name);
        Triggers.switchOn();
        List<CustomAddressAssignments__c> addresses = (List<CustomAddressAssignments__c>) new SObjectBuilder(CustomAddressAssignments__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                CustomAddressAssignments__c.CustomAddress__c => ca.Id,
                CustomAddressAssignments__c.AttentionTo__c => 'test',
                CustomAddressAssignments__c.Quantity__c => ValueProviderBuilder.provideList(new List<Integer> {12,7}),
                CustomAddressAssignments__c.QuoteLineItem__c => ValueProviderBuilder.provideList(new List<Id> {qt.QuoteLineItems[1].Id, qt.QuoteLineItems[6].Id}),
                CustomAddressAssignments__c.Type__c => ValueProviderBuilder.provideList(new List<String> {'Ground', '2 Day'}),
                CustomAddressAssignments__c.ShippingLicenseTree__c => 'LC_SHP_86:LC_SHIP_82:LC_SHIPT_80',
                CustomAddressAssignments__c.ShippingBillingCodeId__c => ValueProviderBuilder.provideList(new List<String> {'111', null})
            })
            .quantity(2)
            .create()
            .getRecords();

        List<Cost_Center__c> costCenters = (List<Cost_Center__c>) new SObjectBuilder(Cost_Center__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Cost_Center__c.AddressId__c => 'Test',
                Cost_Center__c.Billing_Code_Path__c => 'test',
                Cost_Center__c.BillingId__c => ValueProviderBuilder.provideList(new List<String>{'111', '222', '333'}),
                Cost_Center__c.Country__c => 'Test',
                Cost_Center__c.Parent_Billing_Id__c => 'Test',
                Cost_Center__c.Quote__c => qt.Id
            })
            .quantity(3)
            .create()
            .getRecords();

        Set<Id> qliIds = new Set<Id>((new Map<Id, QuoteLineItem> (qt.QuoteLineItems)).keyset());
        List<Cost_Center_Line_Item__c> costCentersLineItems = (List<Cost_Center_Line_Item__c>) new SObjectBuilder(Cost_Center_Line_Item__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Cost_Center_Line_Item__c.Name => 'test',
                Cost_Center_Line_Item__c.Cost_Center__c => ValueProviderBuilder.provideList(new List<Id>{costCenters[0].Id, costCenters[1].Id, costCenters[2].Id}),
                Cost_Center_Line_Item__c.Quantity__c => 10,
                Cost_Center_Line_Item__c.Quote_Line_Item__c => ValueProviderBuilder.provideList(new List<Id>(qliIds))
            })
            .quantity(9)
            .create()
            .getRecords();


        Map<String, String> exceptionMap = new Map<String, String>();

        List<BillingWrappers.BillingInfoSummaryLicense> licenses = getNGBSLicenses();
        Map<String, BillingWrappers.BillingInfoSummaryLicense> licenseMap = SWNHelper.getLicenseMap(licenses);
        Test.setMock(HttpCalloutMock.class, new Mock());
        Test.startTest();

        NGBSOrderRequest.OrderRequestInfo ori = new NGBSOrderRequest.OrderRequestInfo(qt, qliIds, exceptionMap,licenseMap, '111', '222', new List<String>());

        Test.stopTest();

        System.assertEquals(opp.Id, ori.salesOrderId, 'salesOrderId must be equal quote Id');
    }

    @isTest static void verifyOrderRequestGenerationItemsToAddWODevicesAndCostCenters() {

        Map<String, String> exceptionMap = new Map<String, String>();
        Map<String, QuoteLineItem> qliMap = new Map<String, QuoteLineItem>();

        Account acc = getAccount();
        Opportunity opp = acc.Opportunities[0];
        Quote qt = getQuote(opp.Name);

        for(QuoteLineItem qli : qt.QuoteLineItems) {
            if (qli.Product_Lic_Id__c == LC_HD_139 ||
                    qli.Product_Lic_Id__c == LC_HD_140 ||
                    qli.Product_Lic_Id__c == LC_EES_TAM_949 ||
                    qli.Product_Lic_Id__c == LC_EES_489) {
                Triggers.switchOff();
                delete qli;
                Triggers.switchOn();
            }
            if (qli.Product_Lic_Id__c == LC_ALN_38) {
                exceptionMap.put(qli.Product_Lic_Id__c, 'ALN');
            }
            qliMap.put(qli.Product_Lic_Id__c, qli);
        }

        Set<Id> qliIds = new Set<Id>((new Map<Id, QuoteLineItem> (qt.QuoteLineItems)).keyset());
        List<BillingWrappers.BillingInfoSummaryLicense> licenses = getNGBSLicenses();
        Map<String, BillingWrappers.BillingInfoSummaryLicense> licenseMap = SWNHelper.getLicenseMap(licenses);
        Test.startTest();
        NGBSOrderRequest.OrderRequestInfo ori = new NGBSOrderRequest.OrderRequestInfo(qt, qliIds, exceptionMap,licenseMap, '111', '222', new List<String>());
        Test.stopTest();
        System.assertEquals(opp.Id, ori.salesOrderId, 'salesOrderId must be equal opportunity Id');
        System.assertEquals(11, ori.itemsToAdd.size(), 'ItemsToAdd must have 11 records');
        System.assertEquals(true, ori.itemsToAppend.isEmpty(), 'ItemsToAppend must be empty');

        Integer quantity = 0;
        for (NGBSOrderRequest.LicensesToAdd lta : ori.itemsToAdd) {
            if (lta.catalogId == LC_ATN_39) {
                System.assertEquals(1, lta.qty, 'Quantity for send to NGBS with batch false must be 1');
                System.assertEquals(false, lta.batch, 'Batch parameter must be false');
                quantity += lta.qty;
            }
            System.assertEquals(0, lta.billingCodeId, 'BillingCodeId must be with 0 value');
        }
        System.assertEquals(9, ori.orderinfo.orderItems.size(), 'OrderItems quantity must be equal 9 records');
        System.assertEquals(qliMap.get(LC_ATN_39).Quantity - licenseMap.get(LC_ATN_39).qty, quantity, 'Quantity for send to NGBS must consider quantity that already assigned in NGBS');
    }

    @isTest static void verifyOrderRequestGenerationWithItemsToAppend() {

        Map<String, String> exceptionMap = new Map<String, String>();

        Account acc = getAccount();
        Opportunity opp = acc.Opportunities[0];
        Quote qt = getQuote(opp.Name);

        for (QuoteLineItem qli : qt.QuoteLineItems) {
            if (qli.PackageInfo__c == packageQLIInfoEESTAM949) {
                qli.Entitlement__c = null;
                qli.Zero_Quantity__c = false;
                Triggers.switchOff();
                update qli;
                Triggers.switchOn();
            }
        }

        Set<Id> qliIds = new Set<Id>((new Map<Id, QuoteLineItem> (qt.QuoteLineItems)).keyset());
        List<BillingWrappers.BillingInfoSummaryLicense> licenses = getNGBSLicenses();
        Map<String, BillingWrappers.BillingInfoSummaryLicense> licenseMap = SWNHelper.getLicenseMap(licenses);
        Test.setMock(HttpCalloutMock.class, new Mock());
        Test.startTest();
        NGBSOrderRequest.OrderRequestInfo ori = new NGBSOrderRequest.OrderRequestInfo(qt, qliIds, exceptionMap,licenseMap, '111', '222', new List<String>());
        Test.stopTest();
        System.assertEquals(opp.Id, ori.salesOrderId, 'salesOrderId must be equal opportunity Id');
        System.assertEquals(false, ori.itemsToAdd.isEmpty(), 'ItemsToAdd must have values');
        System.assertEquals(1, ori.itemsToAppend.size(), 'ItemsToAppend must have 1 record');
    }

    @IsTest
    static void verifyCallNGBSWithPreparedOrder() {
        Account acc = getAccount();
        Opportunity opp = acc.Opportunities[0];
        Quote qt = getQuote(opp.Name);
        BillingWrappers.NGBSAccountPackage ngbsPackage = new BillingWrappers.NGBSAccountPackage();
        ngbsPackage.id = (String) ValueProviderBuilder.provideUniqueString().getValue();
        ngbsPackage.catalogId = '5';
        ngbsPackage.version = '1';

        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();
            Response res1 = NGBSOrderRequest.callNGBSWithPreparedOrder(qt, opp.Id, qt.QuoteLineItems, acc.Billing_ID__c, SWNStep.UP_SELL, ngbsPackage);
            Response res2 = NGBSOrderRequest.callNGBSWithPreparedOrder(qt, opp.Id, qt.QuoteLineItems, acc.Billing_ID__c, SWNStep.DOWN_SELL, ngbsPackage);
            Response res3 = NGBSOrderRequest.callNGBSWithPreparedOrder(qt, opp.Id, qt.QuoteLineItems, acc.Billing_ID__c, SWNStep.UPGRADE, ngbsPackage);
            Response res4 = NGBSOrderRequest.callNGBSWithPreparedOrder(qt, opp.Id, qt.QuoteLineItems, acc.Billing_ID__c, SWNStep.CHARGE_TERM_SYNC, ngbsPackage);
        Test.stopTest();

        System.assertEquals(Response.STATUS_SUCCESS, res1.getData('status'), 'Should be success');
        System.assertEquals(Response.STATUS_SUCCESS, res2.getData('status'), 'Should be success');
        System.assertEquals(Response.STATUS_SUCCESS, res3.getData('status'), 'Should be success');
        System.assertEquals(Response.STATUS_SUCCESS, res4.getData('status'), 'Should be success');
    }

    @IsTest
    static void verifyIsDeviceOrNonBatchLicense() {

        System.assertEquals(
            false,
            NGBSOrderRequest.isDeviceOrNonBatchLicense(null),
            'method isDeviceOrNonBatchLicense should return false if passed QuoteLineItem is null'
        );

        Product2 testProduct1 = new Product2(
            ShippingType__c = Product2Helper.SHIPPING_TYPE_AUTO
        );
        QuoteLineItem testQLI = new QuoteLineItem();
        System.assertEquals(
            false,
            NGBSOrderRequest.isDeviceOrNonBatchLicense(testQLI),
            'method isDeviceOrNonBatchLicense should return false if passed Product has empty ShippingType__c'
        );

        testQLI = new QuoteLineItem(
            product2 = testProduct1
        );
        System.assertEquals(
            true,
            NGBSOrderRequest.isDeviceOrNonBatchLicense(testQLI),
            'method isDeviceOrNonBatchLicense should return true Product contains ' +
            'label "shippingReq" with value "' + Product2Helper.SHIPPING_TYPE_AUTO + '"'
        );

        testProduct1 = new Product2(
            ShippingType__c = Product2Helper.SHIPPING_TYPE_MANUAL
        );
        testQLI = new QuoteLineItem(
            product2 = testProduct1
        );
        System.assertEquals(
            true,
            NGBSOrderRequest.isDeviceOrNonBatchLicense(testQLI),
            'method isDeviceOrNonBatchLicense should return true Product contains ' +
            'label "shippingReq" with value "' + Product2Helper.SHIPPING_TYPE_MANUAL + '"'
        );
    }

    private static Account getAccount() {
        return (Account) new AccountSelector()
            .selectAccounts()
            .selectFields(new Set<String> {'BillingCountry', 'BillingCity', 'BillingPostalCode', 'BillingStreet', 'BillingState'})
            .subselect(new OpportunitySelector().selectOpportunities())
            .executeQuery()
            .get(0);
    }

    private static CustomAddress__c getCustomAddress(String country, String city, String postalCode, String street, String state) {
        return (CustomAddress__c) new CustomAddressSelector()
            .selectCustomAddresses(new List<Object>{new List<String>{country}, new List<String>{city}, new List<String>{postalCode}, new List<String>{street}, new List<String>{state}})
            .executeQuery()
            .get(0);
    }

    private static Quote getQuote(String oppName) {
        return (Quote) new QuoteSelector()
            .selectQuoteForSyncWithNGBSByName(oppName)
            .executeQuery()
            .get(0);
    }

    public static List<BillingWrappers.BillingInfoSummaryLicense> getNGBSLicenses () {
        List<BillingWrappers.BillingInfoSummaryLicense> licenses = new List<BillingWrappers.BillingInfoSummaryLicense>();
        for (String catalogId : catalogIds) {
            BillingWrappers.BillingInfoSummaryLicense license = new BillingWrappers.BillingInfoSummaryLicense();
            license.catalogId = catalogId;
            license.qty = 1;
            licenses.add(license);
        }
        return licenses;
    }

    private class Mock implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();

            res.setStatus('OK');
            res.setStatusCode(200);
            res.setBody(BILLING_INFO_ALL_LICENSE_RESPONSE);

            return res;
        }
    }
}