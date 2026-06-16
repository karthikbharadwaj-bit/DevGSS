@IsTest
private class Test_PackageTriggerHandler {
    static final String INCONTACT_ID = '123123123';
    static final String EXISTING_INCONTACT_ID = '123456789';
    static final Date PROVISION_DATE = System.today().addMonths(1);
    static final String SERVICE_STATUS = 'Test Status';
    static final Set<SObjectField> ED_FIELDS = new Set<SObjectField> {
        Package__c.RC_Engage_Account_ID__c, Package__c.ED_Account_ID__c, Package__c.ED_Platform__c, Package__c.Engage_Domain__c
    };

    static void assertInContactPackages(List<Package__c> pkgs) {
        Assert.areEqual(EXISTING_INCONTACT_ID, pkgs[0].inContact_account_ID__c, 'InContact Id should not be changed when if package already has it');
        Assert.areEqual(INCONTACT_ID, pkgs[1].inContact_account_ID__c, 'InContact Id should be populated from account');
        Assert.isNull(pkgs[2].inContact_account_ID__c, 'InContact Id should not be populated from account for non RCCC services');

        Assert.areEqual('B34', pkgs[0].inContact_Cluster__c, 'inContact_Cluster__c should not be changed when if package already has it');
        Assert.areEqual('A34', pkgs[1].inContact_Cluster__c, 'inContact_Cluster__c should be populated from account');
        Assert.isNull(pkgs[2].inContact_Cluster__c, 'inContact_Cluster__c should not be populated from account for non RCCC services');

        Assert.areEqual('Contact Center Configured Station', pkgs[0].InContact_Service__c, 'InContact_Service__c should not be changed when if package already has it');
        Assert.areEqual('Contact Center Basic', pkgs[1].InContact_Service__c, 'InContact_Service__c should be populated from account');
        Assert.isNull(pkgs[2].InContact_Service__c, 'InContact_Service__c should not be populated from account for non RCCC services');

        Assert.areEqual(PROVISION_DATE, pkgs[0].Provision_Date__c, 'Provision Date should not be changed when if package already has it');
        Assert.areEqual(System.today(), pkgs[1].Provision_Date__c, 'Provision Date should be populated from account');
        Assert.isNull(pkgs[2].Provision_Date__c, 'Provision Date should not be populated from account for non RCCC services');

        Assert.areEqual(AccountHelper.SERVICE_STATUS_CONTRACT_COMPLETE, pkgs[0].Service_Status__c, 'Service Status should be populated for CC Account Package');
        Assert.areEqual(SERVICE_STATUS, pkgs[1].Service_Status__c, 'Service Status field should not be changed if it populated on package');
        Assert.isNull(pkgs[2].Service_Status__c, 'Service Status should be populated only for CC Service');
    }

    static void assertCollectedData(Set<Id> accIds, List<Package__c> targetPkgs, String message) {
        Assert.areEqual(0, accIds.size(), 'Account Ids size should be 0 ' + message);
        Assert.areEqual(0, targetPkgs.size(), 'Target Packages size should be 0' + message);
    }

    @isTest static void testConnectServiceAccountToOrder() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Feature_Toggle__c.EnableMultiProductUnifiedBilling__c => true
            })
            .create();
        Triggers.switchOff();
        Triggers.except('PackageTriggerHandler.ConnectServiceAccountToOrder');
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'ConnectServiceAccountToOrder Test Account')
            .quantity(1)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'ConnectServiceAccountToOrder Test Opportunity')
            .setField(Opportunity.AccountId, acc.Id)
            .setField(Opportunity.Tier_Name__c, QuoteHelper.NGBS_OFFICE_PRODUCT)
            .setField(Opportunity.Brand_Name__c, OpportunityHelper.BRAND_RINGCENTRAL)
            .setField(Opportunity.Type, OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS)
            .setField(Opportunity.RecordTypeId, OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY)
            .setField(Opportunity.StageName, OpportunityHelper.STAGE_NAME_QUALIFY)
            .setField(Opportunity.CloseDate, System.today())
            .setField(Opportunity.CurrencyIsoCode, RingCentralHelper.USD)
            .quantity(1)
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setField(Quote.Name, 'ConnectServiceAccountToOrder Test Quote')
            .setField(Quote.OpportunityId, opp.Id)
            .setField(Quote.CurrencyIsoCode, RingCentralHelper.USD)
            .setField(Quote.Pricebook2Id, Test.getStandardPricebookId())
            .setField(Quote.isPrimary__c, true)
            .setField(Quote.Upsell_Status__c, QuoteHelper.STATUS_NEW_CUSTOMER)
            .setField(Quote.IsMultiProductTechnicalQuote__c, false)
            .setField(Quote.Package_Info__c, NGBSTestDataGenerator.generateQuotePackageInfo())
            .quantity(1)
            .create()
            .getRecord();

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

        BillingWrappers.QuotePackageInfo pInfo = QuoteHelper.getPackageInfo(qt);
        String catalogId = pInfo?.packageInfo?.catalogId;

        Test.startTest();
        Package__c testPackage = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Package__c.Name => 'test Package 1',
                Package__c.Account_Package_Id__c => '1111',
                Package__c.Offer_Type__c => '',
                Package__c.Account__c => acc.Id,
                Package__c.Enterprise_Account_ID__c => acc.Id,
                Package__c.Package_Catalog_Id__c => catalogId,
                Package__c.Service_Type__c => QuoteHelper.NGBS_OFFICE_PRODUCT
            })
            .create()
            .getRecord();
        Test.stopTest();
        Triggers.switchOn();

        List<Order> reselectedOrders = (List<Order>) new OrderSelector()
            .selectOrdersByIds(new List<Object>{new Set<Id> {orderList[0].Id, orderList[1].Id}})
            .selectFields(new List<String>{'Id', 'Status', 'PackageId__c'})
            .executeQuery();

        for (Order order : reselectedOrders) {
            Assert.areEqual(testPackage.Id, order.PackageId__c, 'Orders should be connected to Package__c with the same Product Name');
        }
    }

    @IsTest
    static void testUpdateServiceMRRFieldsOnAccount() {
        Triggers.switchOff();
        Triggers.except('PackageTriggerHandler.UpdateServiceMRRFieldsOnAccount');

        Account masterAccount = TestDataGenerator.createAccount('Master');

        String[] serviceNames = new List<String> {
            QuoteHelper.NGBS_OFFICE_PRODUCT,
            QuoteHelper.NGBS_RCCC_PRODUCT,
            QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT,
            QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT
        };

        Map<String, Account> accounts = AccountHelper.createTechnicalAccounts(masterAccount.Id, serviceNames);

        Account ccAccount = accounts.get(QuoteHelper.NGBS_RCCC_PRODUCT);
        Account edAccount = accounts.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT);
        Account evAccount = accounts.get(QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT);
        Account evntAccount = TestDataGenerator.createAccount('Test '+QuoteHelper.NGBS_RCEVENTS_PRODUCT, QuoteHelper.NGBS_RCEVENTS_PRODUCT);


        Package__c bapOffice = TestDataGenerator.createBillingAccountPackage(masterAccount);
        Package__c bapCC = TestDataGenerator.createBillingAccountPackage(ccAccount, masterAccount);
        Package__c bapED = TestDataGenerator.createBillingAccountPackage(edAccount, masterAccount);
        Package__c bapEV = TestDataGenerator.createBillingAccountPackage(evAccount, masterAccount);
        Package__c bapEVNT = TestDataGenerator.createBillingAccountPackage(evntAccount);

        Test.startTest();

        update new List<Package__c>{
            new Package__c(Id = bapOffice.Id),
            new Package__c(Id = bapCC.Id, ARPU__c = 11),
            new Package__c(Id = bapED.Id, ARPU__c = 22),
            new Package__c(Id = bapEV.Id, ARPU__c = 33),
            new Package__c(Id = bapEVNT.Id, ARPU__c = 44)
        };

        Test.stopTest();
        Triggers.switchOn();

        masterAccount = (Account) new AccountSelector()
            .selectAccountById(masterAccount.Id)
            .selectFields(AccountSelector.FIELDS_AGGREGATED_TOTALS)
            .executeQuery()
            .get(0);
        accounts = AccountHelper.getTechnicalAccountsByMasterId(masterAccount.Id);

        List<Package__c> billingAccountPackages = new PackageSelector()
            .selectPackagesByEnterpriseAccountIds(new List<Id> {masterAccount.Id, ccAccount.Id, edAccount.Id, evAccount.Id, evntAccount.Id })
            .executeQuery();

        Map<String, Package__c> result = new Map<String, Package__c>();
        for (Package__c billingAccountPackage: billingAccountPackages) {
            result.put(billingAccountPackage.Service_Type__c, billingAccountPackage);
        }
        bapOffice = result.get(QuoteHelper.NGBS_OFFICE_PRODUCT);
        bapCC = result.get(QuoteHelper.NGBS_RCCC_PRODUCT);
        bapED = result.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT);
        bapEV = result.get(QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT);
        bapEVNT = result.get(QuoteHelper.NGBS_RCEVENTS_PRODUCT);

        System.assertEquals(bapOffice.AcquisitionMRR__c, masterAccount.CombinedMVPAcquisitionMRR__c);

        ccAccount = accounts.get(QuoteHelper.NGBS_RCCC_PRODUCT);
        System.assertEquals(bapCC.ARPU__c, ccAccount.inContactARPU__c);

        edAccount = accounts.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT);
        System.assertEquals(bapED.ARPU__c, edAccount.EngageDigitalARPU__c);

        evAccount = accounts.get(QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT);
        System.assertEquals(bapEV.ARPU__c, evAccount.EngageVoiceARPU__c);
    }

    @IsTest
    static void testUpdateServiceMRRFieldsOnAccountMPUB() {
        Triggers.switchOff();
        Triggers.except('PackageTriggerHandler.UpdateServiceMRRFieldsOnAccount');

        Account masterAccount = TestDataGenerator.createAccount('Master');

        List<Package__c> billingAccountPackages = (List<Package__c>) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Enterprise_Account_ID__c => masterAccount.Id,
                Package__c.Account__c => masterAccount.Id,
                Package__c.Account_Package_Id__c => ValueProviderBuilder.provideList(new List<String>{'18','19', '20', '21', '22'}),
                Package__c.Service_Type__c => ValueProviderBuilder.provideList(new List<String>{
                    QuoteHelper.NGBS_OFFICE_PRODUCT,
                    QuoteHelper.NGBS_RCCC_PRODUCT,
                    QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT,
                    QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT,
                    QuoteHelper.NGBS_RCEVENTS_PRODUCT}),
                Package__c.Reported_MRS__c => 0
            })
            .quantity(5)
            .create()
            .getRecords();

        Package__c bapOffice = billingAccountPackages[0];
        Package__c bapCC = billingAccountPackages[1];
        Package__c bapED = billingAccountPackages[2];
        Package__c bapEV = billingAccountPackages[3];
        Package__c bapEvnt = billingAccountPackages[4];

        Test.startTest();

        update new List<Package__c>{
            new Package__c(Id = bapOffice.Id),
            new Package__c(Id = bapCC.Id, ARPU__c = 11),
            new Package__c(Id = bapED.Id, ARPU__c = 22),
            new Package__c(Id = bapEV.Id, ARPU__c = 33),
            new Package__c(Id = bapEvnt.Id, ARPU__c = 44)
        };

        Test.stopTest();
        Triggers.switchOn();

        masterAccount = (Account) new AccountSelector()
            .selectAccountById(masterAccount.Id)
            .selectFields(AccountSelector.FIELDS_AGGREGATED_TOTALS)
            .executeQuery()
            .get(0);

        List<Package__c> billingAccountPackagesReselected = new PackageSelector()
            .selectPackagesByEnterpriseAccountIds(new List<Id> {masterAccount.Id})
            .executeQuery();

        Map<String, Package__c> result = new Map<String, Package__c>();
        for (Package__c billingAccountPackage: billingAccountPackagesReselected) {
            result.put(billingAccountPackage.Service_Type__c, billingAccountPackage);
        }
        bapOffice = result.get(QuoteHelper.NGBS_OFFICE_PRODUCT);
        bapCC = result.get(QuoteHelper.NGBS_RCCC_PRODUCT);
        bapED = result.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT);
        bapEV = result.get(QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT);
        bapEVNT = result.get(QuoteHelper.NGBS_RCEVENTS_PRODUCT);


        System.assertEquals(bapCC.ARPU__c, masterAccount.inContactARPU__c,
            'inContactARPU__c on account should be equal to ARPU__c on Contact Center package');

        System.assertEquals(bapED.ARPU__c, masterAccount.EngageDigitalARPU__c,
            'EngageDigitalARPU__c on account should be equal to ARPU__c on Engage Digital package');

        System.assertEquals(bapEV.ARPU__c, masterAccount.EngageVoiceARPU__c,
            'CombinedMVPAcqEngageVoiceARPU__cuisitionMRR__c on account should be equal to ARPU__c on Engage Voice package');
        
        System.assertEquals(bapEVNT.ARPU__c, masterAccount.EventsARPU__c,
            'EventsARPU__c on account should be equal to ARPU__c on Events package');
    }

    @IsTest
    public static void testUpdateReportedMRSOnTechnicalPackages() {
        Triggers.switchOff();
        Triggers.except('PackageTriggerHandler.UpdateReportedMRSOnTechnicalPackages');
        Account masterAccount = TestDataGenerator.createAccount('Master');

        String[] serviceNames = new List<String> {
            QuoteHelper.NGBS_OFFICE_PRODUCT,
            QuoteHelper.NGBS_RCCC_PRODUCT,
            QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT,
            QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT
        };

        Map<String, Account> accounts = AccountHelper.createTechnicalAccounts(masterAccount.Id, serviceNames);

        Account ccAccount = accounts.get(QuoteHelper.NGBS_RCCC_PRODUCT);
        Account edAccount = accounts.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT);
        Account evAccount = accounts.get(QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT);
        Account evntAccount = TestDataGenerator.createAccount('Test '+QuoteHelper.NGBS_RCEVENTS_PRODUCT, QuoteHelper.NGBS_RCEVENTS_PRODUCT);

        Test.startTest();
        Package__c bapOffice = TestDataGenerator.createBillingAccountPackage(masterAccount);
        Package__c bapCC = TestDataGenerator.createBillingAccountPackage(ccAccount, masterAccount);
        Package__c bapED = TestDataGenerator.createBillingAccountPackage(edAccount, masterAccount);
        Package__c bapEV = TestDataGenerator.createBillingAccountPackage(evAccount, masterAccount);
        Package__c bapEVNT = TestDataGenerator.createBillingAccountPackage(evntAccount);

        update new List<Package__c> {
            new Package__c(Id = bapOffice.Id, Sales_Order_MRS__c = 100),
            new Package__c(Id = bapCC.Id, Sales_Order_MRS__c = 200),
            new Package__c(Id = bapED.Id, Sales_Order_MRS__c = 300),
            new Package__c(Id = bapEV.Id, Sales_Order_MRS__c = 400),
            new Package__c(Id = bapEVNT.Id, Sales_Order_MRS__c = 500)
        };

        List<Package__c> billingAccountPackages = new PackageSelector()
            .selectPackagesByEnterpriseAccountIds(new List<Id> {masterAccount.Id, ccAccount.Id, edAccount.Id, evAccount.Id, evntAccount.Id})
            .executeQuery();

        Map<String, Package__c> result = new Map<String, Package__c>();
        for (Package__c billingAccountPackage: billingAccountPackages) {
            result.put(billingAccountPackage.Service_Type__c, billingAccountPackage);
        }

        bapOffice = result.get(QuoteHelper.NGBS_OFFICE_PRODUCT);
        bapCC = result.get(QuoteHelper.NGBS_RCCC_PRODUCT);
        bapED = result.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT);
        bapEV = result.get(QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT);
        bapEVNT = result.get(QuoteHelper.NGBS_RCEVENTS_PRODUCT);

        Test.stopTest();
        Triggers.switchOn();

        System.assertEquals(0, bapOffice.Reported_MRS__c);
        System.assertEquals(bapCC.Sales_Order_MRS__c, bapCC.Reported_MRS__c);
        System.assertEquals(bapED.Sales_Order_MRS__c, bapED.Reported_MRS__c);
        System.assertEquals(bapEV.Sales_Order_MRS__c, bapEV.Reported_MRS__c);
        System.assertEquals(bapEVNT.Sales_Order_MRS__c, bapEVNT.Reported_MRS__c);
    }

    @IsTest
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    public static void testCopyFieldsFromAccount() {
        Triggers.switchOff();
        Triggers.except('PackageTriggerHandler.CopyFieldsFromAccount');

        Account masterAccount = TestDataGenerator.createAccount('Master');

        String[] serviceNames = new List<String> {
            QuoteHelper.NGBS_OFFICE_PRODUCT,
            QuoteHelper.NGBS_RCCC_PRODUCT,
            QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT,
            QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT
        };

        Map<String, Account> accounts = AccountHelper.createTechnicalAccounts(masterAccount.Id, serviceNames);

        Account ccAccount = accounts.get(QuoteHelper.NGBS_RCCC_PRODUCT);
        Account edAccount = accounts.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT);
        Account evAccount = accounts.get(QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT);

        Test.startTest();

        update new List<Account> {
            new Account(Id = masterAccount.Id, RC_Account_Status__c = 'Paid'),
            new Account(Id = ccAccount.Id, RC_Account_Status__c = 'Canceled'),
            new Account(Id = edAccount.Id, RC_Account_Status__c = 'Canceled'),
            new Account(Id = evAccount.Id, RC_Account_Status__c = 'Paid')
        };

        Package__c bapOffice = TestDataGenerator.createBillingAccountPackage(masterAccount);
        Package__c bapCC = TestDataGenerator.createBillingAccountPackage(ccAccount, masterAccount);
        Package__c bapED = TestDataGenerator.createBillingAccountPackage(edAccount, masterAccount);
        Package__c bapEV = TestDataGenerator.createBillingAccountPackage(evAccount, masterAccount);

        List<Package__c> billingAccountPackages = new PackageSelector()
            .selectPackagesByEnterpriseAccountIdsWithServiceFields(new List<Id> {masterAccount.Id, ccAccount.Id, edAccount.Id, evAccount.Id})
            .executeQuery();

        Map<String, Package__c> result = new Map<String, Package__c>();
        for (Package__c billingAccountPackage: billingAccountPackages) {
            result.put(billingAccountPackage.Service_Type__c, billingAccountPackage);
        }

        Test.stopTest();
        Triggers.switchOn();

        masterAccount = (Account) new AccountSelector()
            .selectAccountsByIdsWithServiceInfoFields(new List<Id> {masterAccount.Id})
            .executeQuery()
            .get(0);
        accounts = AccountHelper.getTechnicalAccountsByMasterId(masterAccount.Id);
        ccAccount = accounts.get(QuoteHelper.NGBS_RCCC_PRODUCT);
        edAccount = accounts.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT);
        evAccount = accounts.get(QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT);

        bapOffice = result.get(QuoteHelper.NGBS_OFFICE_PRODUCT);
        bapCC = result.get(QuoteHelper.NGBS_RCCC_PRODUCT);
        bapED = result.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT);
        bapEV = result.get(QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT);

        // System.assertEquals(masterAccount.RC_Account_Status__c, bapOffice.RC_Account_Status__c);
        // System.assertEquals(QuoteHelper.NGBS_OFFICE_PRODUCT, bapOffice.Service_Type__c);
        // System.assertEquals(ccAccount.RC_Account_Status__c, bapCC.RC_Account_Status__c);
        // System.assertEquals(edAccount.RC_Account_Status__c, bapED.RC_Account_Status__c);
        // System.assertEquals(evAccount.RC_Account_Status__c, bapEV.RC_Account_Status__c);
    }

    @IsTest
    private static void testSyncEnabledLBOOnNewQuote() {
        Triggers.switchOff();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test acc',
                Account.Billing_ID__c => ValueProviderBuilder.provideUniqueString(),
                Account.RC_User_ID__c => ValueProviderBuilder.provideUniqueString()
            })
            .create()
            .getRecord();

        List <Package__c> billingAccountPackages = (List <Package__c>) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Enterprise_Account_ID__c => acc.Id,
                Package__c.Account__c => acc.Id,
                Package__c.Name => ValueProviderBuilder.provideList(new List<String>{ 'Test pckg1', 'Test pckg2' }),
                Package__c.Account_Package_Id__c => ValueProviderBuilder.provideList(new List<String>{ '1234', '4321' }),
                Package__c.EnabledLBO__c => ValueProviderBuilder.provideList(new List<Boolean>{ false, false })
            })
            .quantity(2)
            .create()
            .getRecords();

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

        Test.startTest();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Name => 'Test1',
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS,
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
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.isPrimary__c => true,
                Quote.Account__c => acc.Id,
                Quote.Enabled_LBO__c => false
            })
            .create()
            .getRecord();

        Package__c billingAccountPackage1 = billingAccountPackages.get(0);
        billingAccountPackage1.EnabledLBO__c = true;
        update billingAccountPackage1;

        Test.stopTest();

        Quote qtCheck = (Quote) new QuoteSelector()
            .selectPrimaryQuotes(new List<Id>{opp.Id})
            .executeQuery()
            .get(0);

        Assert.areEqual(false, qtCheck.Enabled_LBO__c, 'EnabledLBO__c should not be true on new quote');
        Triggers.switchOn();
    }

    @IsTest
    private static void testSyncEnabledLBOOnUpsellQuoteToTrue() {
        Triggers.switchOff();
        Triggers.except('PackageTriggerHandler.SyncEnabledLBOOnQuote');
        Triggers.switchOn();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test acc',
                Account.Billing_ID__c => ValueProviderBuilder.provideUniqueString(),
                Account.RC_User_ID__c => ValueProviderBuilder.provideUniqueString()
            })
            .create()
            .getRecord();

        List <Package__c> billingAccountPackages = (List <Package__c>) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Enterprise_Account_ID__c => acc.Id,
                Package__c.Account__c => acc.Id,
                Package__c.Name => ValueProviderBuilder.provideList(new List<String>{ 'Test pckg1', 'Test pckg2' }),
                Package__c.Account_Package_Id__c => ValueProviderBuilder.provideList(new List<String>{ '1234', '4321' }),
                Package__c.EnabledLBO__c => false
            })
            .quantity(2)
            .create()
            .getRecords();

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

        Test.startTest();

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
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.isPrimary__c => true,
                Quote.Account__c => acc.Id,
                Quote.Enabled_LBO__c => false,
                Quote.Upsell_Status__c => QuoteHelper.STATUS_UPSELL
            })
            .create()
            .getRecord();

        Package__c billingAccountPackage1 = billingAccountPackages.get(0);
        billingAccountPackage1.EnabledLBO__c = true;
        update billingAccountPackage1;

        Test.stopTest();

        Quote qtCheck = (Quote) new QuoteSelector()
            .selectPrimaryQuotes(new List<Id>{opp.Id})
            .executeQuery()
            .get(0);

        Assert.areEqual(true, qtCheck.Enabled_LBO__c, 'EnabledLBO__c on quote must be true if at least one package has EnabledLBO__c true');
        Triggers.switchOn();
    }

    @IsTest
    private static void testSyncEnabledLBOOnUpsellQuoteToFalse() {
        Triggers.switchOff();
        Triggers.except('PackageTriggerHandler.SyncEnabledLBOOnQuote');
        Triggers.switchOn();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test acc',
                Account.Billing_ID__c => ValueProviderBuilder.provideUniqueString(),
                Account.RC_User_ID__c => ValueProviderBuilder.provideUniqueString()
            })
            .create()
            .getRecord();

        List <Package__c> billingAccountPackages = (List <Package__c>) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Enterprise_Account_ID__c => acc.Id,
                Package__c.Account__c => acc.Id,
                Package__c.Name => ValueProviderBuilder.provideList(new List<String>{ 'Test pckg1', 'Test pckg2' }),
                Package__c.Account_Package_Id__c => ValueProviderBuilder.provideList(new List<String>{ '1234', '4321' }),
                Package__c.EnabledLBO__c => ValueProviderBuilder.provideList(new List<Boolean>{ true, false })
            })
            .quantity(2)
            .create()
            .getRecords();

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

        Test.startTest();

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
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.isPrimary__c => true,
                Quote.Account__c => acc.Id,
                Quote.Enabled_LBO__c => true,
                Quote.Upsell_Status__c => QuoteHelper.STATUS_UPSELL
            })
            .create()
            .getRecord();

        Package__c billingAccountPackage1 = billingAccountPackages.get(0);
        billingAccountPackage1.EnabledLBO__c = false;
        update billingAccountPackage1;

        Test.stopTest();

        Quote qtCheck = (Quote) new QuoteSelector()
            .selectPrimaryQuotes(new List<Id>{opp.Id})
            .executeQuery()
            .get(0);

        Assert.areEqual(false, qtCheck.Enabled_LBO__c, 'EnabledLBO__c on quote must be false if all packages have EnabledLBO__c false');
        Triggers.switchOn();
    }

    @IsTest
    private static void testSyncEnabledLBOOnPOCToPaid() {
        Triggers.switchOff();
        Triggers.except('PackageTriggerHandler.SyncEnabledLBOOnQuote');
        Triggers.switchOn();
        Account acc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'POC-to-Paid acc',
                Account.Offer_Type__c => AccountHelper.OFFER_TYPE_POC,
                Account.RC_Account_Status__c => AccountHelper.OFFER_TYPE_POC,
                Account.Billing_ID__c => ValueProviderBuilder.provideUniqueString()
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

        Test.startTest();

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
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.isPrimary__c => true,
                Quote.Account__c => acc.Id,
                Quote.Enabled_LBO__c => false,
                Quote.Upsell_Status__c => QuoteHelper.STATUS_UPSELL
            })
            .create()
            .getRecord();

        Package__c testPackage = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Account__c => acc.Id,
                Package__c.Account_Package_Id__c => '11111111111',
                Package__c.Service_Type__c => AccountHelper.SERVICE_TYPE_OFFICE,
                Package__c.Enterprise_Account_ID__c => acc.Id,
                Package__c.EnabledLBO__c => false
            })
            .create()
            .getRecord();

        Test.stopTest();

        Quote qtCheck = (Quote) new QuoteSelector()
            .selectPrimaryQuotes(new List<Id>{opp.Id})
            .executeQuery()
            .get(0);

        Assert.areEqual(true, qtCheck.Enabled_LBO__c, 'EnabledLBO__c on quote must be true if account is POC');
        Triggers.switchOn();
    }

    @IsTest
    public static void testUpdateARPUOnTechnicalPackages() {
        Triggers.switchOff();
        Triggers.except('PackageTriggerHandler.UpdateARPUOnTechnicalPackages');
        Account masterAccount = TestDataGenerator.createAccount('Master');

        String[] serviceNames = new List<String> {
                QuoteHelper.NGBS_OFFICE_PRODUCT,
                QuoteHelper.NGBS_RCCC_PRODUCT,
                QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT,
                QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT
        };
        Map<String, Account> accounts = AccountHelper.createTechnicalAccounts(masterAccount.Id, serviceNames);

        Account ccAccount = accounts.get(QuoteHelper.NGBS_RCCC_PRODUCT);
        Account edAccount = accounts.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT);
        Account evAccount = accounts.get(QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT);
        Account evntAccount = TestDataGenerator.createAccount('Test '+QuoteHelper.NGBS_RCEVENTS_PRODUCT, QuoteHelper.NGBS_RCEVENTS_PRODUCT);

        Test.startTest();
        Package__c bapOffice = TestDataGenerator.createBillingAccountPackage(masterAccount);
        Package__c bapCC = TestDataGenerator.createBillingAccountPackage(ccAccount, masterAccount);
        Package__c bapED = TestDataGenerator.createBillingAccountPackage(edAccount, masterAccount);
        Package__c bapEV = TestDataGenerator.createBillingAccountPackage(evAccount, masterAccount);
        Package__c bapEVNT = TestDataGenerator.createBillingAccountPackage(evntAccount);

        update new List<Package__c> {
                new Package__c(Id = bapOffice.Id, Sales_Order_MRS__c = 100, NumberOfMainLicenses__c = 10),
                new Package__c(Id = bapCC.Id, Sales_Order_MRS__c = 200, NumberOfMainLicenses__c = 10),
                new Package__c(Id = bapED.Id, Sales_Order_MRS__c = 300, NumberOfMainLicenses__c = 10),
                new Package__c(Id = bapEV.Id, Sales_Order_MRS__c = 400, NumberOfMainLicenses__c = 10),
                new Package__c(Id = bapEVNT.Id, Sales_Order_MRS__c = 500, NumberOfMainLicenses__c = 10)
        };

        List<Package__c> billingAccountPackages = new PackageSelector()
                .selectPackagesByEnterpriseAccountIds(new List<Id> {masterAccount.Id, ccAccount.Id, edAccount.Id, evAccount.Id, evntAccount.Id})
                .executeQuery();

        Map<String, Package__c> result = new Map<String, Package__c>();
        for(Package__c billingAccountPackage: billingAccountPackages) {
            result.put(billingAccountPackage.Service_Type__c, billingAccountPackage);
        }

        bapOffice = result.get(QuoteHelper.NGBS_OFFICE_PRODUCT);
        bapCC = result.get(QuoteHelper.NGBS_RCCC_PRODUCT);
        bapED = result.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT);
        bapEV = result.get(QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT);
        bapEVNT = result.get(QuoteHelper.NGBS_RCEVENTS_PRODUCT);
        Test.stopTest();
        Triggers.switchOn();

        System.assertEquals(bapOffice.Sales_Order_MRS__c / bapOffice.NumberOfMainLicenses__c, bapOffice.ARPU__c);
        System.assertEquals(bapCC.Sales_Order_MRS__c / bapCC.NumberOfMainLicenses__c, bapCC.ARPU__c);
        System.assertEquals(bapED.Sales_Order_MRS__c / bapED.NumberOfMainLicenses__c, bapED.ARPU__c);
        System.assertEquals(bapEV.Sales_Order_MRS__c / bapEV.NumberOfMainLicenses__c, bapEV.ARPU__c);
        System.assertEquals(bapEVNT.Sales_Order_MRS__c / bapEVNT.NumberOfMainLicenses__c, bapEVNT.ARPU__c);
    }

    @IsTest
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    public static void testCopyContactCenterServiceFieldsToMasterAccount() {
        Account masterAccount = TestDataGenerator.createAccount('Master');

        String[] serviceNames = new List<String> {
            QuoteHelper.NGBS_OFFICE_PRODUCT,
            QuoteHelper.NGBS_RCCC_PRODUCT,
            QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT,
            QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT
        };

        Map<String, Account> accounts = AccountHelper.createTechnicalAccounts(masterAccount.Id, serviceNames);

        Account ccAccount = accounts.get(QuoteHelper.NGBS_RCCC_PRODUCT);
        Account edAccount = accounts.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT);
        Account evAccount = accounts.get(QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT);

        Triggers.switchOff();
        Triggers.except('PackageTriggerHandler.CopyContactCenterServiceFieldsToMasterAccount');

        Package__c bapCC = TestDataGenerator.createBillingAccountPackage(ccAccount, masterAccount);
        Package__c bapED = TestDataGenerator.createBillingAccountPackage(edAccount, masterAccount);
        Package__c bapEV = TestDataGenerator.createBillingAccountPackage(evAccount, masterAccount);

        Test.startTest();
        update new Package__c(
            Id = bapCC.Id,
            NumberOfMainLicenses__c = 5,
            MinuteBundle__c = 7,
            TransportMRR__c = 9,
            SeatMRR__c = 13,
            Provision_Date__c = Date.today(),
            InContact_Service__c = 'inContactAccountName',
            Bill_As_Of_Date__c = Date.today()
        );
        Test.stopTest();
        Triggers.switchOff();

        Account masterAccountToCheck = [SELECT
            Id,
            No_of_InContact_Seats__c,
            Minute_Bundle__c,
            Actual_transport_MRR__c,
            Provision_Date__c,
            inContact_account_ID__c,
            InContact_Service__c,
            Bill_As_Of_Date__c
        FROM Account WHERE Id =: masterAccount.Id LIMIT 1];

        List<Package__c> billingAccountPackages = new PackageSelector()
            .selectPackagesById(new List<Id> {bapCC.Id, bapED.Id, bapEV.Id})
            .executeQuery();

        Map<String, Package__c> result = new Map<String, Package__c>();
        for(Package__c billingAccountPackage: billingAccountPackages) {
            result.put(billingAccountPackage.Service_Type__c, billingAccountPackage);
        }

        // for (Package__c bap: result.values()) {
        //     if (bap.Service_Type__c == QuoteHelper.NGBS_RCCC_PRODUCT) {
        //         System.assertEquals(bap.MinuteBundle__c, masterAccountToCheck.Minute_Bundle__c,
        //             'Master account should get Minute_Bundle__c from linked Package__c'
        //         );
        //         System.assertEquals(bap.TransportMRR__c, masterAccountToCheck.Actual_transport_MRR__c,
        //             'Master account should get Actual_transport_MRR__c from linked Package__c'
        //         );
        //         Assert.areEqual(bap.SeatMRR__c / bap.NumberOfMainLicenses__c, bap.Price_per_Seat__c,
        //             'Package__c should get Price_per_Seat__c from SeatMRR__c / NumberOfMainLicenses__c'
        //         );
        //         System.assertEquals(bap.Bill_As_Of_Date__c, masterAccountToCheck.Bill_As_Of_Date__c,
        //             'Master account should get Bill_As_Of_Date__c from linked Package__c'
        //         );
        //     } else {
        //         System.assertEquals(null, bap.NumberOfMainLicenses__c,
        //             'Non Contact Center Package__c should not have NumberOfMainLicenses__c'
        //         );
        //         System.assertEquals(null, bap.MinuteBundle__c,
        //             'Non Contact Center Package__c should not have MinuteBundle__c'
        //         );
        //         System.assertEquals(null, bap.TransportMRR__c,
        //             'Non Contact Center Package__c should not have TransportMRR__c'
        //         );
        //         System.assertEquals(null, bap.AdditionalProductsMRR__c,
        //             'Non Contact Center Package__c should not have AdditionalProductsMRR__c'
        //         );
        //         System.assertEquals(0, bap.ARPU__c,
        //             'Non Contact Center Package__c should not have ARPU__c'
        //         );
        //         System.assertEquals(null, bap.Bill_As_Of_Date__c,
        //             'Non Contact Center Package__c should not have Bill_As_Of_Date__c'
        //         );
        //     }
        // }
    }

    @IsTest
    public static void testUpdateAccountFieldsFromBAPOnInsert() {
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'test account')
            .create()
            .getRecord();

        Triggers.switchOff();
        Triggers.except('PackageTriggerHandler.UpdateAccountFieldsFromBAP');
        Test.startTest();
        insert new List<Package__c> {
            new Package__c(
                Name = 'test package 1',
                Account_Package_Id__c = '1234',
                Package_Status__c = PackageHelper.PACKAGE_STATUS_ACTIVE,
                Account__c = testAcc.Id,
                EngageDigitalMRR__c = 10,
                EngageDigitalUserMRR__c = 20,
                EDAcquisitionMRR__c = 200,
                Total_DLs__c = 5,
                Licenses_Purchased__c = 5
            ),
            new Package__c(
                Name = 'test package 2',
                Account_Package_Id__c = '4312',
                Package_Status__c = PackageHelper.PACKAGE_STATUS_ACTIVE,
                Account__c = testAcc.Id,
                EngageDigitalMRR__c = 55,
                EDAcquisitionMRR__c = 100,
                Total_DLs__c = 10,
                Licenses_Purchased__c = 15
            )
        };
        Test.stopTest();
        Triggers.switchOn();

        Account resultAcc = [SELECT Licenses_Purchased__c, Total_DLs__c FROM Account WHERE Id =: testAcc.Id];
        Assert.areEqual(15, resultAcc.Total_DLs__c, 'Total_DLs__c should be 15');
        Assert.areEqual(20, resultAcc.Licenses_Purchased__c, 'Licenses_Purchased__c should be 20');
    }

    @IsTest
    public static void testUpdateAccountFieldsFromBAPOnUpdate() {
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'test account')
            .setField(Account.CombinedEngageDigitalMRR__c, 300)
            .setField(Account.CombinedEDAcquisitionMRR__c, 50)
            .create()
            .getRecord();

        Triggers.switchOff();
        Triggers.except('PackageTriggerHandler.UpdateAccountFieldsFromBAP');
        Package__c testPkg1 = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Package__c.Name => 'test Package 1',
                Package__c.Account_Package_Id__c => '1111',
                Package__c.Package_Status__c => PackageHelper.PACKAGE_STATUS_ACTIVE,
                Package__c.Account__c => testAcc.Id,
                Package__c.EngageDigitalMRR__c => 100,
                Package__c.EDAcquisitionMRR__c => 20,
                Package__c.Number_of_DL_s__c => 5
            })
            .create()
            .getRecord();

        Package__c testPkg2 = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Package__c.Name => 'test Package 2',
                Package__c.Account_Package_Id__c => '1112',
                Package__c.Package_Status__c => PackageHelper.PACKAGE_STATUS_ACTIVE,
                Package__c.Account__c => testAcc.Id,
                Package__c.EngageDigitalMRR__c => 200,
                Package__c.EDAcquisitionMRR__c => 30,
                Package__c.Number_of_DL_s__c => 10
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        Account resultAcc = [SELECT Number_of_DL_s__c FROM Account WHERE Id =: testAcc.Id];
        Assert.areEqual(15, resultAcc.Number_of_DL_s__c, 'Number_of_DL_s__c should be 15');

        Triggers.switchOff();
        Triggers.except('PackageTriggerHandler.UpdateAccountFieldsFromBAP');
        Test.startTest();
        update new List<Package__c> {
            new Package__c(Id = testPkg1.Id, Number_of_DL_s__c = 45),
            new Package__c(Id = testPkg2.Id, Number_of_DL_s__c = 110)
        };
        Test.stopTest();
        Triggers.switchOn();

        Account resultAcc1 = [SELECT Number_of_DL_s__c FROM Account WHERE Id =: testAcc.Id];
        Assert.areEqual(155, resultAcc1.Number_of_DL_s__c, 'Number_of_DL_s__c should be 155');
    }

    @IsTest
    public static void testActivateNewestOrders_ServiceInfoExist() {
        Triggers.switchOff();
        Triggers.except('PackageTriggerHandler.ActivateNewestOrders');

        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test Account')
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Name => 'Test Opportunity',
                Opportunity.AccountId => testAcc.Id,
                Opportunity.Tier_Name__c => QuoteHelper.NGBS_OFFICE_PRODUCT,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS,
                Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today(),
                Opportunity.CurrencyIsoCode => RingCentralHelper.USD
            })
            .create()
            .getRecord();

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => 'Test Product2',
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                Product2.IsActive => true,
                Product2.Charge_Term__c => 'Monthly'
            })
            .create()
            .getRecord();

        PricebookEntry testPBE = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => testProduct.Id,
                PricebookEntry.UnitPrice => 0,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.CurrencyIsoCode => RingCentralHelper.USD
            })
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => 'Test Quote',
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.OpportunityId => testOpp.Id,
                Quote.CurrencyIsoCode => RingCentralHelper.USD,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.isPrimary__c => true,
                Quote.Upsell_Status__c => QuoteHelper.STATUS_NEW_CUSTOMER,
                Quote.IsMultiProductTechnicalQuote__c => false,
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo()
            })
            .create()
            .getRecord();

        new SObjectBuilder(ServiceInfo__c.SObjectType)
            .setField(ServiceInfo__c.Quote__c, testQuote.Id)
            .create()
            .getRecord();

        Package__c testPackage = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Package__c.Name => 'test Package 1',
                Package__c.Account_Package_Id__c => '1111',
                Package__c.Offer_Type__c => '',
                Package__c.Package_Status__c => '',
                Package__c.Account__c => testAcc.Id,
                Package__c.Enterprise_Account_ID__c => testAcc.Id
            })
            .create()
            .getRecord();

        List<Order> testOrders = (List<Order>) new SObjectBuilder(Order.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Order.Status => OrderHelper.STATUS_NEW,
                    Order.Pricebook2Id => Test.getStandardPricebookId(),
                    Order.AccountId => testAcc.Id,
                    Order.TechnicalQuoteId__c => testQuote.Id,
                    Order.PackageId__c => testPackage.Id,
                    Order.EffectiveDate => System.today(),
                    Order.Provisioning__c => ValueProviderBuilder.provideList(
                        new List<String>{
                            OrderHelper.PROVISIONING_AUTO,
                            OrderHelper.PROVISIONING_MANUAL
                        }
                    )
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        new SObjectBuilder(OrderItem.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    OrderItem.OrderId => ValueProviderBuilder.provideParents(testOrders),
                    OrderItem.Product2Id => testProduct.Id,
                    OrderItem.PricebookEntryId => testPBE.Id,
                    OrderItem.UnitPrice => 10,
                    OrderItem.Quantity => 1
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        Test.startTest();
        update new Package__c(Id = testPackage.Id, Package_Status__c = PackageHelper.PACKAGE_STATUS_ACTIVE);
        Test.stopTest();
        Triggers.switchOn();

        List<Order> reselectedOrders = (List<Order>) new OrderSelector()
            .selectOrdersByIds(new List<Object>{new Set<Id> {testOrders[0].Id, testOrders[1].Id}})
            .selectFields(
                new List<String>{
                    'Id',
                    'Status'
                }
            )
            .executeQuery();

        for (Order order : reselectedOrders) {
            Assert.areEqual(OrderHelper.STATUS_ACTIVATED, order.Status, 'MPUB Orders should be activated after Package__c received Package_Status__c = Active if Service Info Exist');
        }
    }

    @IsTest
    public static void testActivateNewestOrders_ServiceInfoNotExist() {
        Triggers.switchOff();
        Triggers.except('PackageTriggerHandler.ActivateNewestOrders');

        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test Account')
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Name => 'Test Opportunity',
                Opportunity.AccountId => testAcc.Id,
                Opportunity.Tier_Name__c => QuoteHelper.NGBS_OFFICE_PRODUCT,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS,
                Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today(),
                Opportunity.CurrencyIsoCode => RingCentralHelper.USD
            })
            .create()
            .getRecord();

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => 'Test Product2',
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                Product2.IsActive => true,
                Product2.Charge_Term__c => 'Monthly'
            })
            .create()
            .getRecord();

        PricebookEntry testPBE = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => testProduct.Id,
                PricebookEntry.UnitPrice => 0,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.CurrencyIsoCode => RingCentralHelper.USD
            })
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => 'Test Quote',
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.OpportunityId => testOpp.Id,
                Quote.CurrencyIsoCode => RingCentralHelper.USD,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.isPrimary__c => true,
                Quote.Upsell_Status__c => QuoteHelper.STATUS_NEW_CUSTOMER,
                Quote.IsMultiProductTechnicalQuote__c => false,
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo()
            })
            .create()
            .getRecord();

        Package__c testPackage = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Package__c.Name => 'test Package 1',
                Package__c.Account_Package_Id__c => '1111',
                Package__c.Offer_Type__c => '',
                Package__c.Package_Status__c => '',
                Package__c.Account__c => testAcc.Id,
                Package__c.Enterprise_Account_ID__c => testAcc.Id
            })
            .create()
            .getRecord();

        List<Order> testOrders = (List<Order>) new SObjectBuilder(Order.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Order.Status => OrderHelper.STATUS_NEW,
                    Order.Pricebook2Id => Test.getStandardPricebookId(),
                    Order.AccountId => testAcc.Id,
                    Order.TechnicalQuoteId__c => testQuote.Id,
                    Order.PackageId__c => testPackage.Id,
                    Order.EffectiveDate => System.today(),
                    Order.Provisioning__c => ValueProviderBuilder.provideList(
                        new List<String>{
                            OrderHelper.PROVISIONING_AUTO,
                            OrderHelper.PROVISIONING_MANUAL
                        }
                    )
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        new SObjectBuilder(OrderItem.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    OrderItem.OrderId => ValueProviderBuilder.provideParents(testOrders),
                    OrderItem.Product2Id => testProduct.Id,
                    OrderItem.PricebookEntryId => testPBE.Id,
                    OrderItem.UnitPrice => 10,
                    OrderItem.Quantity => 1
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        Test.startTest();
        update new Package__c(Id = testPackage.Id, Package_Status__c = PackageHelper.PACKAGE_STATUS_ACTIVE);
        Test.stopTest();
        Triggers.switchOn();

        List<Order> reselectedOrders = (List<Order>) new OrderSelector()
            .selectOrdersByIds(new List<Object>{new Set<Id> {testOrders[0].Id, testOrders[1].Id}})
            .selectFields(
                new List<String>{
                    'Id',
                    'Status'
                }
            )
            .executeQuery();

        for (Order order : reselectedOrders) {
            Assert.areEqual(OrderHelper.STATUS_NEW, order.Status, 'MPUB Orders should NOT be activated after Package__c received Package_Status__c = Active if Service Info NOT Exists');
        }
    }

    @isTest static void testCreateCaseForManualProvisioningMPUB() {
        Triggers.switchOff();
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Feature_Toggle__c.EnableMultiProductUnifiedBilling__c => true
            })
            .create();
        Triggers.except('PackageTriggerHandler.ConnectServiceAccountToOrder');
        Triggers.except('PackageTriggerHandler.CreateCaseForManualProvisioningMPUB');
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'CreateCaseForManualProvisioningMPUB Test Account')
            .quantity(1)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'CreateCaseForManualProvisioningMPUB Test Opportunity')
            .setField(Opportunity.AccountId, acc.Id)
            .setField(Opportunity.Tier_Name__c, QuoteHelper.NGBS_OFFICE_PRODUCT)
            .setField(Opportunity.Brand_Name__c, OpportunityHelper.BRAND_RINGCENTRAL)
            .setField(Opportunity.Type, OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS)
            .setField(Opportunity.RecordTypeId, OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY)
            .setField(Opportunity.StageName, OpportunityHelper.STAGE_NAME_QUALIFY)
            .setField(Opportunity.CloseDate, System.today())
            .setField(Opportunity.CurrencyIsoCode, RingCentralHelper.USD)
            .quantity(1)
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setField(Quote.Name, 'CreateCaseForManualProvisioningMPUB Test Quote')
            .setField(Quote.RecordTypeId, QuoteHelper.RT_ID_BILLING)
            .setField(Quote.OpportunityId, opp.Id)
            .setField(Quote.CurrencyIsoCode, RingCentralHelper.USD)
            .setField(Quote.Pricebook2Id, Test.getStandardPricebookId())
            .setField(Quote.isPrimary__c, true)
            .setField(Quote.Upsell_Status__c, QuoteHelper.STATUS_NEW_CUSTOMER)
            .setField(Quote.IsMultiProductTechnicalQuote__c, false)
            .setField(Quote.Package_Info__c, NGBSTestDataGenerator.generateQuotePackageInfo())
            .quantity(1)
            .create()
            .getRecord();

        new SObjectBuilder(ServiceInfo__c.SObjectType)
            .setField(ServiceInfo__c.Quote__c, qt.Id)
            .create()
            .getRecord();

        List<Product2> prodList = (List<Product2>) new SObjectBuilder(Product2.sObjectType)
            .setField(Product2.Name, 'CreateCaseForManualProvisioningMPUB Test product')
            .setField(Product2.ExtID__c, ValueProviderBuilder.provideList(new List<String>{'TEST', 'TEST_1', 'TEST_2', null}))
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
            .setField(Product2.InitialOrderType__c, ValueProviderBuilder.provideList(
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

        BillingWrappers.QuotePackageInfo pInfo = QuoteHelper.getPackageInfo(qt);
        String catalogId = pInfo?.packageInfo?.catalogId;

        Test.startTest();
        Package__c testPackage = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Package__c.Name => 'test Package 1',
                Package__c.Account_Package_Id__c => '1111',
                Package__c.Offer_Type__c => '',
                Package__c.Account__c => acc.Id,
                Package__c.Enterprise_Account_ID__c => acc.Id,
                Package__c.Package_Catalog_Id__c => catalogId,
                Package__c.Service_Type__c => QuoteHelper.NGBS_OFFICE_PRODUCT
            })
            .create()
            .getRecord();
        Test.stopTest();
        Triggers.switchOn();

        List<Case> caseList = (List<Case>) new CaseSelector()
            .selectCases()
            .executeQuery();

        Assert.areEqual(1, caseList.size(), 'CreateCaseForManualProvisioningMPUB should create manual provisioning cases for New Business Quotes');
    }

    @isTest
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    static void testCopyEngageVoiceFieldsFromAccount() {
        final Set<SObjectField> evFields = new Set<SObjectField> {
            Package__c.RC_Engage_Account_ID__c, Package__c.EV_Account_ID__c, Package__c.EV_Platform__c
        };

        Triggers.switchOff();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'TestAcc',
                Account.IsMultiProductTechnicalAccount__c => false,
                Account.RC_Engage_Account_ID__c => '1111',
                Account.EV_Account_ID__c => '2222',
                Account.EV_Platform__c => 'test engage platform'
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        Package__c testPackage = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Account_Package_Id__c => '1111',
                Package__c.Account__c => acc.Id,
                Package__c.Enterprise_Account_ID__c => acc.Id,
                Package__c.Service_Type__c => QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT
            })
            .build()
            .getRecord();

        PackageTriggerHandler.CopyEngageFieldsFromAccount triggerHandler = new PackageTriggerHandler.CopyEngageFieldsFromAccount(TriggerOperation.BEFORE_INSERT, new List<Package__c> {testPackage});
        Test.startTest();
            triggerHandler.handle();
        Test.stopTest();

        assertPackageFieldCopiedFromAcc(evFields, acc, testPackage);
    }

    @isTest
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    static void testCopyEngageDigitalFieldsFromAccount() {
        Triggers.switchOff();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'TestAcc',
                Account.IsMultiProductTechnicalAccount__c => false,
                Account.RC_Engage_Account_ID__c => '1111',
                Account.ED_Account_ID__c => '2222',
                Account.ED_Platform__c => 'test engage platform',
                Account.Engage_Domain__c => 'test engage domain'
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        Package__c testPackage = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Account_Package_Id__c => '1111',
                Package__c.Account__c => acc.Id,
                Package__c.Enterprise_Account_ID__c => acc.Id,
                Package__c.Service_Type__c => QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT
            })
            .build()
            .getRecord();

        PackageTriggerHandler.CopyEngageFieldsFromAccount triggerHandler = new PackageTriggerHandler.CopyEngageFieldsFromAccount(TriggerOperation.BEFORE_INSERT, new List<Package__c> {testPackage});
        Test.startTest();
            triggerHandler.handle();
        Test.stopTest();

        assertPackageFieldCopiedFromAcc(ED_FIELDS, acc, testPackage);
    }

    @isTest
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    static void testCopyEngageDigitalFieldsFromAccountMPL() {
        Triggers.switchOff();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'TestAcc',
                Account.IsMultiProductTechnicalAccount__c => false
            })
            .create()
            .getRecord();

        Account childAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'TestChildAcc',
                Account.Master_Account__c => acc.Id,
                Account.IsMultiProductTechnicalAccount__c => true,
                Account.RC_Engage_Account_ID__c => '1111',
                Account.ED_Account_ID__c => '2222',
                Account.ED_Platform__c => 'test engage platform',
                Account.Engage_Domain__c => 'test engage domain'
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        Package__c testPackage = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Account_Package_Id__c => '1111',
                Package__c.Account__c => acc.Id,
                Package__c.Enterprise_Account_ID__c => childAcc.Id,
                Package__c.Service_Type__c => QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT
            })
            .build()
            .getRecord();

        PackageTriggerHandler.CopyEngageFieldsFromAccount triggerHandler = new PackageTriggerHandler.CopyEngageFieldsFromAccount(TriggerOperation.BEFORE_INSERT, new List<Package__c> {testPackage});

        Test.startTest();
            triggerHandler.handle();
        Test.stopTest();

        assertPackageFieldCopiedFromAcc(ED_FIELDS, childAcc, testPackage);
    }

    private static void assertPackageFieldCopiedFromAcc(Set<SObjectField> fields, Account acc, Package__c bap) {
        for (SObjectField field : fields) {
            String fieldName = field.toString();
            Assert.areEqual(acc.get(fieldName), bap.get(fieldName), String.format(
                'The {0} field should be coppied from Account',
                new List<Object> {fieldName}
            ));
        }
    }

    @isTest
    static void testPopulateIsRingCxFieldOnMasterAccount() {
        Triggers.switchOff();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'TestAcc',
                Account.IsMultiProductTechnicalAccount__c => false,
                Account.IsRingCx__c => false
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        Package__c testPackage = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Account_Package_Id__c => '1111',
                Package__c.Account__c => acc.Id,
                Package__c.Enterprise_Account_ID__c => acc.Id,
                Package__c.Package_Status__c => PackageHelper.PACKAGE_STATUS_ACTIVE,
                Package__c.Package_Name__c => 'RingCX IVR Only (USD)'
            })
            .build()
            .getRecord();

        PackageTriggerHandler.PopulateIsRingCxFieldOnMasterAccount triggerHandler = new PackageTriggerHandler.PopulateIsRingCxFieldOnMasterAccount(TriggerOperation.BEFORE_INSERT, new List<Package__c> {testPackage});
        Test.startTest();
            triggerHandler.handle();
        Test.stopTest();

        Account reselectedAcc = (Account) new AccountSelector()
            .selectAccounts()
            .selectFields(new List<Schema.SObjectField> {
                Account.IsRingCx__c
            })
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object>{ acc.Id })
            .executeQuery()
            .get(0);

        Assert.isTrue(reselectedAcc.IsRingCx__c, 'Account should be marked as ringCX');
    }

    @IsTest
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    static void testPopulateInContactFieldsFromParentAccountMPUB() {
        Triggers.switchOff();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'TestAcc',
                Account.inContact_account_ID__c => INCONTACT_ID,
                Account.Provision_Date__c => PROVISION_DATE,
                Account.Service_Status__c => AccountHelper.SERVICE_STATUS_CONTRACT_COMPLETE,
                Account.inContact_Cluster__c => 'A34',
                Account.InContact_Service__c => 'Contact Center Basic',
                Account.IsMultiProductTechnicalAccount__c => false
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        List<Package__c> testPackages = (List<Package__c>) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.inContact_account_ID__c => new ValueProvider.ListProvider(new List<String> { EXISTING_INCONTACT_ID, null, null }),
                Package__c.Provision_Date__c => new ValueProvider.ListProvider(new List<Date> { null, System.today(), null }),
                Package__c.Service_Status__c => new ValueProvider.ListProvider(new List<String> { null, SERVICE_STATUS, null }),
                Package__c.inContact_Cluster__c => new ValueProvider.ListProvider(new List<String> { 'B34', null, null }),
                Package__c.InContact_Service__c => new ValueProvider.ListProvider(new List<String> { 'Contact Center Configured Station', null, null }),
                Package__c.Account__c => acc.Id,
                Package__c.Service_Type__c => new ValueProvider.ListProvider(new List<String> { QuoteHelper.NGBS_RCCC_PRODUCT, QuoteHelper.NGBS_RCCC_PRODUCT, null }),
                Package__c.Enterprise_Account_ID__c => acc.Id
            })
            .quantity(3)
            .build()
            .getRecords();

        PackageTriggerHandler.PopulateInContactFieldsFromParentAccount triggerHandler = new PackageTriggerHandler.PopulateInContactFieldsFromParentAccount(
            TriggerOperation.BEFORE_INSERT, testPackages
        );
        Test.startTest();
            triggerHandler.handle();
        Test.stopTest();

        assertInContactPackages(testPackages);
    }

    @IsTest
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    static void testPopulateInContactFieldsFromParentAccountMPL() {
        Triggers.switchOff();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'TestAcc',
                Account.inContact_account_ID__c => INCONTACT_ID,
                Account.Provision_Date__c => PROVISION_DATE,
                Account.inContact_Cluster__c => 'A34',
                Account.InContact_Service__c => 'Contact Center Basic',
                Account.IsMultiProductTechnicalAccount__c => false
            })
            .create()
            .getRecord();

        Account childAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'TestChildAcc',
                Account.Master_Account__c => acc.Id,
                Account.inContact_account_ID__c => '000000',
                Account.Provision_Date__c => System.today().addMonths(2),
                Account.IsMultiProductTechnicalAccount__c => true,
                Account.Service_Status__c => AccountHelper.SERVICE_STATUS_CONTRACT_COMPLETE
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        List<Package__c> testPackages = (List<Package__c>) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.inContact_account_ID__c => new ValueProvider.ListProvider(new List<String> { EXISTING_INCONTACT_ID, null, null }),
                Package__c.Provision_Date__c => new ValueProvider.ListProvider(new List<Date> { null, System.today(), null }),
                Package__c.Service_Status__c => new ValueProvider.ListProvider(new List<String> { null, SERVICE_STATUS, null }),
                Package__c.inContact_Cluster__c => new ValueProvider.ListProvider(new List<String> { 'B34', null, null }),
                Package__c.InContact_Service__c => new ValueProvider.ListProvider(new List<String> { 'Contact Center Configured Station', null, null }),
                Package__c.Account__c => acc.Id,
                Package__c.Service_Type__c => new ValueProvider.ListProvider(new List<String> { QuoteHelper.NGBS_RCCC_PRODUCT, QuoteHelper.NGBS_RCCC_PRODUCT, null }),
                Package__c.Enterprise_Account_ID__c => childAcc.Id
            })
            .quantity(3)
            .build()
            .getRecords();

        PackageTriggerHandler.PopulateInContactFieldsFromParentAccount triggerHandler = new PackageTriggerHandler.PopulateInContactFieldsFromParentAccount(
            TriggerOperation.BEFORE_INSERT, testPackages
        );
        Test.startTest();
            triggerHandler.handle();
        Test.stopTest();

        assertInContactPackages(testPackages);
    }

    @IsTest
    static void testUpdateMarketingAttributionFields() {
        Triggers.switchOff();
        Triggers.except('PackageTriggerHandler.UpdateMarketingAttributionFields');
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'TestAcc'
            })
            .create()
            .getRecord();

        Test.startTest();

        Package__c testPackage = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Account_Package_Id__c => '1111',
                Package__c.Account__c => testAcc.Id,
                Package__c.Package_Name__c => 'RingCX IVR Only (USD)',
                Package__c.Service_Type__c => 'Engage Digital Standalone',
                Package__c.CreatedDate => DateTime.now(),
                Package__c.AID__c => 'AID1',
                Package__c.BMID__c => 'BMID1',
                Package__c.IsUsedForAccountAttribution__c => false,
                Package__c.RC_Signup_Funnel__c => 'SIGNUP_FUNNEL'
            })
            .create()
            .getRecord();

        Test.stopTest();
        Triggers.switchOn();

        Account reselectedAcc = (Account) new AccountSelector()
            .selectAccounts()
            .selectFields(new List<Schema.SObjectField> {
                Account.AID__c,
                Account.BMID__c,
                Account.RC_Signup_Funnel__c
            })
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object> {testAcc.Id})
            .executeQuery()
            .get(0);

        Assert.areEqual(testPackage.AID__c, reselectedAcc.AID__c, 'Wrong AID__c value');
        Assert.areEqual(testPackage.BMID__c, reselectedAcc.BMID__c, 'Wrong BMID__c value');
        Assert.areEqual(testPackage.RC_Signup_Funnel__c, reselectedAcc.RC_Signup_Funnel__c, 'Wrong RC_Signup_Funnel__c value');

        Package__c reselectedPkg = (Package__c) new ListOptional(new PackageSelector()
            .selectPackagesById(new List<Id>{ testPackage.Id })
            .selectFields(new List<Schema.SObjectField> {
                Package__c.IsUsedForAccountAttribution__c
            })
            .executeQuery()
        ).getFirst();
        Assert.isTrue(reselectedPkg.IsUsedForAccountAttribution__c, 'Marketing field should be true');
    }

    @isTest
    static void testUpdateMarketingAttributionFieldsPopulatedExistingPackages() {
        List<Account> accounts = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Id, ValueProviderBuilder.provideDummyId(Account.SObjectType))
            .quantity(2)
            .build()
            .getRecords();

        List<Package__c> packages = (List<Package__c>) new SObjectBuilder(Package__c.SObjectType)
            .setField(Package__c.Id, ValueProviderBuilder.provideDummyId(Package__c.SObjectType))
            .quantity(3)
            .build()
            .getRecords();

        Map<Id, Account> accountsMap = new Map<Id, Account>();
        Map<Id, List<Package__c>> accIdToPackagesMap = new Map<Id, List<Package__c>>();

        accounts[0] = (Account) Test_Utils.putIntoUnwritableField(
            accounts[0],
            Account.class,
            'Service_Accounts__r',
            new List<Package__c> { packages[2] }
        );

        for (Integer i = 0; i < accounts.size(); i++) {
            accountsMap.put(accounts[i].Id, accounts[i]);
            accIdToPackagesMap.put(accounts[i].Id, new List<Package__c> { packages[i] });
        }

        PackageTriggerHandler.UpdateMarketingAttributionFields handler = new PackageTriggerHandler.UpdateMarketingAttributionFields();
        for (List<Package__c> pkgs : accIdToPackagesMap.values()) {
            Assert.areEqual(1, pkgs.size(), 'Should have only 1 package');
        }

        Test.startTest();
            handler.populatedExistingPackages(accountsMap, accIdToPackagesMap);
        Test.stopTest();

        Assert.areEqual(2, accIdToPackagesMap.get(accounts[0].Id).size(), 'Package should be added to the list of packages related to the Account');
        Assert.areEqual(1, accIdToPackagesMap.get(accounts[1].Id).size(), 'Package should not be added to the list');
    }

    @isTest
    static void testUpdateMarketingAttributionFieldsCollectData() {
        Set<Id> accIds = new Set<Id>();
        List<Package__c> targetPkgs = new List<Package__c>();

        List<Package__c> testPackages = (List<Package__c>) new SObjectBuilder(Package__c.SObjectType)
            .setField(Package__c.Id, ValueProviderBuilder.provideDummyId(Package__c.SObjectType))
            .quantity(1)
            .build()
            .getRecords();

        Test.startTest();
            PackageTriggerHandler.UpdateMarketingAttributionFields handler = new PackageTriggerHandler.UpdateMarketingAttributionFields(TriggerOperation.AFTER_INSERT, testPackages);
            handler.collectData(accIds, targetPkgs);
            assertCollectedData(accIds, targetPkgs, 'if package without Account__c and Service_Type__c');

            testPackages[0].Service_Type__c = QuoteHelper.NGBS_OFFICE_PRODUCT;
            handler = new PackageTriggerHandler.UpdateMarketingAttributionFields(TriggerOperation.AFTER_INSERT, testPackages);
            handler.collectData(accIds, targetPkgs);
            assertCollectedData(accIds, targetPkgs, 'if package without Account__c');

            testPackages[0].Account__c = (Id) ValueProviderBuilder.provideDummyId(Account.SObjectType).getValue();
            handler = new PackageTriggerHandler.UpdateMarketingAttributionFields(TriggerOperation.AFTER_UPDATE, testPackages);
            handler.collectData(accIds, targetPkgs);
            assertCollectedData(accIds, targetPkgs, 'if update and no marketing field changes');

            testPackages[0].OID__c = '123';
            handler = new PackageTriggerHandler.UpdateMarketingAttributionFields(TriggerOperation.AFTER_UPDATE, testPackages);
            handler.collectData(accIds, targetPkgs);
            Assert.areEqual(1, accIds.size(), 'Account Ids size should be 1');
            Assert.areEqual(1, targetPkgs.size(), 'Target Packages size should be 1');
        Test.stopTest();
    }

    @IsTest
    static void testPopulatePackageMRRFields() {
        Triggers.switchOff();
        Triggers.except('PackageTriggerHandler.PopulatePackageMRRFields');
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'TestAcc'
            })
            .create()
            .getRecord();

        Test.startTest();

        Package__c testPackage = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Account_Package_Id__c => '1111',
                Package__c.Account__c => testAcc.Id,
                Package__c.Enterprise_Account_ID__c => testAcc.Id,
                Package__c.Package_Name__c => 'RingCX IVR Only (USD)',
                Package__c.Service_Type__c => 'Engage Digital Standalone',
                Package__c.MRR__c => 1111,
                Package__c.aMRR__c => 2222
            })
            .create()
            .getRecord();

        Test.stopTest();
        Triggers.switchOn();

        Package__c reselectedPkg = (Package__c) new PackageSelector()
            .selectPackagesById(new List<Id>{ testPackage.Id })
            .selectFields(new List<Schema.SObjectField> {
                Package__c.EngageDigitalMRR__c,
                Package__c.EDAcquisitionMRR__c
            })
            .executeQuery()
            .get(0);

        Assert.areEqual(testPackage.MRR__c, reselectedPkg.EngageDigitalMRR__c, 'EngageDigitalMRR__c should be the same as MRR__c');
        Assert.areEqual(testPackage.aMRR__c, reselectedPkg.EDAcquisitionMRR__c, 'EDAcquisitionMRR__c should be the same as aMRR__c');
    }

    @IsTest
    static void testUpdateAccountDateFields() {
        Triggers.switchOff();
        Triggers.except('PackageTriggerHandler.UpdateAccountDateFields');
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'TestAcc'
            })
            .create()
            .getRecord();

        Test.startTest();

        Package__c testPackage1 = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Account_Package_Id__c => '1111',
                Package__c.Account__c => testAcc.Id,
                Package__c.Enterprise_Account_ID__c => testAcc.Id,
                Package__c.Package_Name__c => 'RingCX IVR Only (USD)',
                Package__c.Service_Type__c => 'Engage Digital Standalone',
                Package__c.RC_Churn_Date__c => DateTime.now(),
                Package__c.RC_Cancel_Date__c => DateTime.now().addDays(2)
            })
            .create()
            .getRecord();

        Package__c testPackage2 = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Account_Package_Id__c => '2222',
                Package__c.Account__c => testAcc.Id,
                Package__c.Enterprise_Account_ID__c => testAcc.Id,
                Package__c.Package_Name__c => 'RingCX IVR Only (USD)',
                Package__c.Service_Type__c => 'Engage Digital Standalone',
                Package__c.RC_Churn_Date__c => DateTime.now().addDays(2),
                Package__c.RC_Cancel_Date__c => DateTime.now()
            })
            .create()
            .getRecord();

        Test.stopTest();
        Triggers.switchOn();

        Account reselectedAcc = (Account) new AccountSelector()
            .selectAccounts()
            .selectFields(new List<Schema.SObjectField> {
                Account.RC_Churn_Date__c,
                Account.RC_Cancel_Date__c
            })
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object>{ testAcc.Id })
            .executeQuery()
            .get(0);

        Assert.areEqual(testPackage1.RC_Cancel_Date__c, reselectedAcc.RC_Cancel_Date__c, 'RC_Cancel_Date__c should be the same as RC_Cancel_Date__c from testPackage1');
        Assert.areEqual(testPackage2.RC_Churn_Date__c.addDays(90), reselectedAcc.RC_Churn_Date__c, 'RC_Churn_Date__c should be 90 days later than RC_Churn_Date__c from testPackage2');
    }

    @IsTest
    static void testPopulateServiceRelatedFields_RCServiceName() {
        Triggers.switchOff();
        Triggers.except('PackageTriggerHandler.PopulateServiceRelatedFields');

        Test.startTest();
        List<Account> testAccounts = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => ValueProviderBuilder.provideList(new List<String>{'TestAcc1', 'TestAcc2'}),
                Account.RC_Brand__c => ValueProviderBuilder.provideList(new List<String>{'RingCentral', 'RingCentral'}),
                Account.RC_Service_name__c => ValueProviderBuilder.provideList(new List<String>{'Test', null})
            })
            .quantity(2)
            .create()
            .getRecords();

        List<Package__c> testPackages = (List<Package__c>) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Account__c => ValueProviderBuilder.provideList(new List<Id>{testAccounts[0].Id, testAccounts[1].Id, testAccounts[1].Id}),
                Package__c.Enterprise_Account_ID__c => ValueProviderBuilder.provideList(new List<Id>{testAccounts[0].Id, testAccounts[1].Id, testAccounts[1].Id}),
                Package__c.Account_Package_Id__c => ValueProviderBuilder.provideList(new List<String>{'1111', '2222', '3333'}),
                Package__c.Service_Type__c => ValueProviderBuilder.provideList(new List<String>{'Office', 'Professional', 'Office'})
            })
            .quantity(3)
            .create()
            .getRecords();
        List<Account> reselectedAccounts = (List<Account>) new AccountSelector()
            .selectAccountsByIds(new List<Object>{ new List<Id>{ testAccounts[0].Id, testAccounts[1].Id } })
            .executeQuery();

        Test.stopTest();

        Assert.areEqual('RC Office', reselectedAccounts[0].RC_Service_name__c, 'Account 1 should have populated RC_Service_name__c with RC Office ');
        Assert.areEqual('RC Office', reselectedAccounts[1].RC_Service_name__c, 'Account 2 should have populated RC_Service_name__c with RC Office');

        testPackages[1].Service_Type__c = 'Updated Service Type';
        update testPackages[1];
        Triggers.switchOn();

        Account reselectedAcc2 = (Account) new AccountSelector()
            .selectAccountsByIds(new List<Object>{ new List<Id>{ testAccounts[1].Id } })
            .executeQuery()
            .get(0);
        Assert.areEqual('RC Office', reselectedAcc2.RC_Service_name__c, 'Account 2 should not change RC_Service_name__c because the updated package is not primary');
    }

    @IsTest
    static void testPopulateServiceRelatedFields_SignupType() {
        Triggers.switchOff();

        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Feature_Toggle__c.AccountWorkflowRulesAndProcToTrigger__c => true
            })
            .create();

        Triggers.except('PackageTriggerHandler.PopulateServiceRelatedFields');
        Account testAcc1 = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'TestAcc1',
                Account.Office_30_Day_Trial__c => false,
                Account.Office_Trial__c => null
            })
            .create()
            .getRecord();

        Account testAcc2 = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'TestAcc2',
                Account.Office_30_Day_Trial__c => true,
                Account.Office_Trial__c => AccountTriggerHelper.OFFICE_TRIAL_30DAYS
            })
            .create()
            .getRecord();

        Test.startTest();

        Package__c testPackage1 = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Account_Package_Id__c => '1111',
                Package__c.Account__c => testAcc1.Id,
                Package__c.Enterprise_Account_ID__c => testAcc1.Id,
                Package__c.Package_Name__c => 'RingCX IVR Only (USD)',
                Package__c.Service_Type__c => 'Engage Digital Standalone',
                Package__c.Number_of_POC_Users__c => 5,
                Package__c.SignupType__c => null
            })
            .create()
            .getRecord();

        Package__c testPackage2 = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Account_Package_Id__c => '2222',
                Package__c.Account__c => testAcc2.Id,
                Package__c.Enterprise_Account_ID__c => testAcc2.Id,
                Package__c.Package_Name__c => 'RingCX IVR Only (USD)',
                Package__c.Service_Type__c => 'Engage Digital Standalone',
                Package__c.Number_of_POC_Users__c => 0,
                Package__c.SignupType__c => null
            })
            .create()
            .getRecord();

        Test.stopTest();
        Triggers.switchOn();

        Package__c reselectedPkg1 = (Package__c) new PackageSelector()
            .selectPackagesById(new List<Id>{ testPackage1.Id })
            .selectFields(new List<Schema.SObjectField> {
                Package__c.SignupType__c
            })
            .executeQuery()
            .get(0);

        Package__c reselectedPkg2 = (Package__c) new PackageSelector()
            .selectPackagesById(new List<Id>{ testPackage2.Id })
            .selectFields(new List<Schema.SObjectField> {
                Package__c.SignupType__c
            })
            .executeQuery()
            .get(0);

        Assert.areEqual(AccountTriggerHelper.SIGN_UP_TYPE_TRIAL_30NOCC, reselectedPkg1.SignupType__c, 'Package 1 should have SignupType__c = TRIAL_30NOCC');
        Assert.areEqual(AccountTriggerHelper.SIGN_UP_TYPE_TRIAL_30CC, reselectedPkg2.SignupType__c, 'Package 2 should have SignupType__c = trial_30CC');
    }

    @IsTest
    static void testPopulateServiceRelatedFields_ServiceVersionLabel() {
        Triggers.switchOff();
        Id CaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('CERT').getRecordTypeId();
        Triggers.except('PackageTriggerHandler.PopulateServiceRelatedFields');
        Account testAcc1 = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'TestAcc1'
            })
            .create()
            .getRecord();

        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.AccountId => testAcc1.Id,
                Contact.Email => 'fake@email.com',
                Contact.LastName => 'TestLast',
                Contact.Phone => '9910106804'
            })
            .create()
            .getRecord();

        Case testCase = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Case.Status => 'New',
                Case.RecordTypeId => CaseRecordTypeId,
                Case.AccountId => testAcc1.Id,
                Case.ContactId => testContact.Id
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        Implementation__c implRecord = (Implementation__c) new SObjectBuilder(Implementation__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Implementation__c.Account__c => testAcc1.Id
            })
            .create()
            .getRecord();

        Test.startTest();

        Package__c testPackage1 = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Account_Package_Id__c => '1111',
                Package__c.Account__c => testAcc1.Id,
                Package__c.Service_Version__c => '1',
                Package__c.Enterprise_Account_ID__c => testAcc1.Id,
                Package__c.Package_Name__c => 'RingCX IVR Only (USD)',
                Package__c.Service_Type__c => QuoteHelper.NGBS_OFFICE_PRODUCT
            })
            .create()
            .getRecord();

        Test.stopTest();
        Triggers.switchOn();

        Account reselectedAcc = (Account) new AccountSelector()
            .selectAccounts()
            .selectFields(new List<Schema.SObjectField> {
                Account.ID
            })
            .subselect(new CaseSelector()
                .selectCases()
                .selectFields(new List<Schema.SObjectField>{
                    Case.Service_Version_Name__c
                })
            )
            .subselect(new ImplementationSelector()
                .selectImplementations()
                .selectFields(new List<Schema.SObjectField>{
                    Implementation__c.Service_Version_Name__c
                })
            )
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object>{ testAcc1.Id })
            .executeQuery()
            .get(0);

         Package__c resultPackage = (Package__c) new PackageSelector()
            .selectPackagesForNewReferences(new List<Object> {new Set<Id>{testAcc1.Id}})
            .executeQuery()
            .get(0);

        Assert.areEqual(resultPackage.Service_Version_Label__c, reselectedAcc.Implementations__r[0].Service_Version_Name__c, 'Implementation__c.Service_Version_Name__c should be the same as Package__c.Service_Version_Label__c');
    }

    @IsTest
    static void testPopulatePackageMRRFields_Events() {
        Triggers.switchOff();
        Triggers.except('PackageTriggerHandler.PopulatePackageMRRFields');
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'TestAcc'
            })
            .create()
            .getRecord();

        Test.startTest();

        Package__c testPackage = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Account_Package_Id__c => '1111',
                Package__c.Account__c => testAcc.Id,
                Package__c.Enterprise_Account_ID__c => testAcc.Id,
                Package__c.Package_Name__c => 'Events 100 Attendee',
                Package__c.Service_Type__c =>  QuoteHelper.NGBS_RCEVENTS_PRODUCT,
                Package__c.MRR__c => 1010,
                Package__c.aMRR__c => 999
            })
            .create()
            .getRecord();

        Test.stopTest();
        Triggers.switchOn();

        Package__c reselectedPkg = (Package__c) new PackageSelector()
            .selectPackagesById(new List<Id>{ testPackage.Id })
            .selectFields(new List<Schema.SObjectField> {
                Package__c.Events_MRR__c,
                Package__c.Events_Acquisition_MRR__c
            })
            .executeQuery()
            .get(0);

        Assert.areEqual(testPackage.MRR__c, reselectedPkg.Events_MRR__c, 'Events_MRR__c should be the same as MRR__c');
        Assert.areEqual(testPackage.aMRR__c, reselectedPkg.Events_Acquisition_MRR__c, 'Events_Acquisition_MRR__c should be the same as aMRR__c');
    }

    @IsTest
    static void testCreateProservProject() {
        Triggers.switchOff();
        
        Account testAccount = TestDataGenerator.createAccount('Test Account');
        Opportunity testOpp = TestDataGenerator.createOpportunity(testAccount);
        Quote testQuote = TestDataGenerator.createQuote(testOpp);
        testQuote.RecordTypeId = QuoteHelper.RT_ID_BILLING;
        update testQuote;  

        Order testOrder = (Order) new SObjectBuilder(Order.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Order.Name => 'Test Order',
                Order.AccountId => testAccount.Id,
                Order.Status => 'New',
                Order.Type => OrderHelper.TYPE_INITIAL_ORDER,
                Order.EffectiveDate => System.today(),
                Order.Pricebook2Id => Test.getStandardPricebookId(),
                Order.RecordTypeId => OrderHelper.RT_ID_PROSERV,
                Order.QuoteId => testQuote.Id,
                Order.CurrencyIsoCode => 'USD',
                Order.OpportunityId => testOpp.Id
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        Test.startTest();
        
        Package__c testPackage = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Package__c.Name => 'Test ProServ Package',
                Package__c.Account_Package_Id__c => '12345',
                Package__c.Account__c => testAccount.Id,
                Package__c.Enterprise_Account_ID__c => testAccount.Id,
                Package__c.Package_Catalog_Id__c => '12345',
                Package__c.Service_Type__c => PackageHelper.PROSERV_SERVICE_TYPE,
                Package__c.Opportunity__c => testOpp.Id
            })
            .create()
            .getRecord();

        Test.stopTest();

        List<ProServ_Project__c> createdProservProjects = new ProServProjectSelector()
            .selectProServProjectsByOrderIds(new Set<Id>{testOrder.Id})
            .executeQuery();

        Assert.areEqual(1, createdProservProjects.size(), 'One Proserv Project record should be created');
    }

    @IsTest
    static void testCreatePSIntegrationRecords() {
        Triggers.switchOff();
        
        Account testAccount = TestDataGenerator.createAccount('Test Account');
        Opportunity testOpp = TestDataGenerator.createOpportunity(testAccount);
        Quote testQuote = TestDataGenerator.createQuote(testOpp);

        ProServ_Project__c testProject = (ProServ_Project__c) new SObjectBuilder(ProServ_Project__c.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                ProServ_Project__c.Account__c => testAccount.Id,
                ProServ_Project__c.Quote__c => testQuote.Id,
                ProServ_Project__c.Opportunity__c => testOpp.Id
            })
            .create()
            .getRecord();

        Order testOrder = (Order) new SObjectBuilder(Order.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Order.Name => 'Test Order',
                Order.AccountId => testAccount.Id,
                Order.Status => 'New',
                Order.Type => OrderHelper.TYPE_INITIAL_ORDER,
                Order.EffectiveDate => System.today(),
                Order.Pricebook2Id => Test.getStandardPricebookId(),
                Order.RecordTypeId => OrderHelper.RT_ID_PROSERV,
                Order.ProServProject__c => testProject.Id,
                Order.CurrencyIsoCode => 'USD',
                Order.OpportunityId => testOpp.Id
            })
            .create()
            .getRecord();

        Phase__c testPhase = (Phase__c) new SObjectBuilder(Phase__c.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Phase__c.Order__c => testOrder.Id,
                Phase__c.Phase_Number__c => 1,
                Phase__c.Phase_Type__c => 'UC',
                Phase__c.Status__c => 'Active'
            })
            .create()
            .getRecord();

        Suborder__c testSuborder = (Suborder__c) new SObjectBuilder(Suborder__c.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Suborder__c.Order__c => testOrder.Id,
                Suborder__c.Phase__c => testPhase.Id,
                Suborder__c.Status__c => SuborderHelper.STATUS_NEW,
                Suborder__c.SuborderNumber__c => 1,
                Suborder__c.Suborder_Type__c => 'UC'
            })
            .create()
            .getRecord();

        Triggers.switchOn();

        Test.startTest();
        
        Package__c testPackage = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Package__c.Name => 'Test ProServ Package',
                Package__c.Account_Package_Id__c => '12345',
                Package__c.Account__c => testAccount.Id,
                Package__c.Enterprise_Account_ID__c => testAccount.Id,
                Package__c.Package_Catalog_Id__c => '12345',
                Package__c.Service_Type__c => PackageHelper.PROSERV_SERVICE_TYPE,
                Package__c.Opportunity__c => testOpp.Id
            })
            .create()
            .getRecord();

        Test.stopTest();

        List<PS_Integration__c> createdPSIntegrations = new PSIntegrationSelector()
            .selectPSIntegrationsBySubOrderIds(new List<Object> { new List<Id> { testSuborder.Id } })
            .executeQuery();

        Assert.areEqual(1, createdPSIntegrations.size(), 'One PS Integration record should be created');
        
        PS_Integration__c psIntegration = createdPSIntegrations[0];
        Assert.areEqual(testSuborder.Id, psIntegration.MostRecentSuborder__c, 'MostRecentSuborder__c should be the test suborder');
        Assert.areEqual(testOrder.Id, psIntegration.Order__c, 'Order__c should be the test order');
        Assert.areEqual(testPhase.Id, psIntegration.Phase__c, 'Phase__c should be the test phase');
        Assert.areEqual(PSIntegrationHelper.STATUS_NEW, psIntegration.Status__c, 'Status should be New');
    }
}