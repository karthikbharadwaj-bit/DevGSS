@IsTest
private class Test_PackageHelper {
    @IsTest
    static void testGetReportedMRS() {
        Account acc = new Account(CombinedEngageDigitalMRR__c = 100, CombinedEngageVoiceMRR__c = 50);
        Package__c bap = new Package__c(Service_Type__c = QuoteHelper.NGBS_OFFICE_PRODUCT);
        Assert.areEqual(50, PackageHelper.getReportedMRS(bap, acc), 'The Reported MRS should be 50');
    }

    @IsTest
    static void testGetReportedMRSWithNullAccount() {
        Package__c bap = new Package__c(Service_Type__c = QuoteHelper.NGBS_OFFICE_PRODUCT);
        Assert.areEqual(null, PackageHelper.getReportedMRS(bap, null), 'The Reported MRS should be null');
    }

    @IsTest
    static void testGetReportedMRSWithNullBap() {
        Account acc = new Account(CombinedEngageDigitalMRR__c = 100, CombinedEngageVoiceMRR__c = 50);
        Assert.areEqual(null, PackageHelper.getReportedMRS(null, acc), 'The Reported MRS should be null');
    }

    @IsTest
    static void testGetReportedMRSWithSalesOrderMRS() {
        Account acc = new Account(CombinedEngageDigitalMRR__c = 100, CombinedEngageVoiceMRR__c = 50);
        Package__c bap = new Package__c(Sales_Order_MRS__c = 100);
        Assert.areEqual(100, PackageHelper.getReportedMRS(bap, acc), 'The Reported MRS should be 100');
    }

    @IsTest
    static void testFilterPackagesByCreatedDateAndService() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                    Account.Name => 'test Acc'
            })
            .build()
            .getRecord();

        // Filter by service
        Package__c testPkg1 = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Package__c.Name => 'Package 1',
                Package__c.Account__c => testAccount.Id,
                Package__c.Service_Type__c => 'Office',
                Package__c.CreatedDate => DateTime.now()
            })
            .build()
            .getRecord();

        Package__c testPkg2 = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Package__c.Name => 'Package 2',
                Package__c.Account__c => testAccount.Id,
                Package__c.Service_Type__c => 'Engage Digital Standalone',
                Package__c.CreatedDate => DateTime.now()
            })
            .build()
            .getRecord();

        List<Package__c> result1 = PackageHelper.filterPackagesByCreatedDateAndService(new List<Package__c> {testPkg1, testPkg2});
        Assert.isNotNull(result1, 'Result should not be null');
        Assert.areEqual('Package 1', result1[0].Name, 'The oldest package should be selected');

        // Filter by date
        Package__c testPkg3 = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Package__c.Name => 'Package 3',
                Package__c.Account__c => testAccount.Id,
                Package__c.Service_Type__c => 'Office',
                Package__c.CreatedDate => DateTime.now()
            })
            .build()
            .getRecord();

        Package__c testPkg4 = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Package__c.Name => 'Package 4',
                Package__c.Account__c => testAccount.Id,
                Package__c.Service_Type__c => 'Engage Digital Standalone',
                Package__c.CreatedDate => DateTime.now().addDays(-1)
            })
            .build()
            .getRecord();


        List<Package__c> result2 = PackageHelper.filterPackagesByCreatedDateAndService(new List<Package__c> {testPkg3, testPkg4});
        Assert.isNotNull(result2, 'Result should not be null');
        Assert.areEqual('Package 4', result2[0].Name, 'The oldest package should be selected');
    }

    @isTest
    static void testfilterPackagesByService() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                    Account.Name => 'test Acc'
            })
            .build()
            .getRecord();


        Package__c testPkg1 = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Package__c.Name => 'Package 1',
                Package__c.Account__c => testAccount.Id,
                Package__c.Service_Type__c => 'Office',
                Package__c.SignupType__c => AccountTriggerHelper.SIGN_UP_TYPE_TRIAL_30NOCC
            })
            .build()
            .getRecord();

        Package__c testPkg2 = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Package__c.Name => 'Package 2',
                Package__c.Account__c => testAccount.Id,
                Package__c.Service_Type__c => 'Engage Digital Standalone',
                Package__c.SignupType__c => null
            })
            .build()
            .getRecord();

        Package__c testPkg3 = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Name => 'Package 2',
                Package__c.Account__c => testAccount.Id,
                Package__c.Service_Type__c => 'Fax',
                Package__c.SignupType__c => null
            })
            .build()
            .getRecord();

        Map<Id, Package__c> result = PackageHelper.filterPackagesByService(
            new List<Package__c>{testPkg1, testPkg2},
            AccountHelper.SERVICE_TYPE_OFFICE
        );

        Assert.areEqual(1, result.size(), 'There should be one package in the result');
        Assert.areEqual(testPkg1.Id, result.get(testAccount.Id).Id, 'The package should be package1');

        Map<Id, Package__c> result2 = PackageHelper.filterPackagesByService(new List<Package__c>{testPkg1, testPkg2});

        Assert.areEqual(1, result2.size(), 'There should be one package in the result');
        Assert.areEqual(testPkg1.Id, result2.get(testAccount.Id).Id, 'The package should be Office');

        Map<Id, Package__c> result3 = PackageHelper.filterPackagesByService(
            new List<Package__c>{testPkg1, testPkg2},
            AccountHelper.SERVICE_TYPE_RCCC
        );

        Assert.areEqual(0, result3.size(), 'There should be no packages in the result');

        Map<Id, Package__c> result4 = PackageHelper.filterPackagesByService(
            new List<Package__c> { testPkg3 }
        );

        Assert.areEqual(1, result4.size(), 'There should be one package in the result');
    }

    @isTest
    static void testMapAccountIdToPackages() {
        Triggers.switchOff();
        Account testAccount1 = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'test Acc'
            })
            .create()
            .getRecord();

        Account testAccount2 = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'test Acc'
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        Package__c testPkg1 = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Package__c.Name => 'Package 1',
                Package__c.Account__c => testAccount1.Id,
                Package__c.Service_Type__c => 'Office'
            })
            .build()
            .getRecord();

        Package__c testPkg2 = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Package__c.Name => 'Package 2',
                Package__c.Account__c => testAccount1.Id,
                Package__c.Service_Type__c => 'Engage Digital Standalone'
            })
            .build()
            .getRecord();

        Package__c testPkg3 = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Package__c.Name => 'Package 3',
                Package__c.Account__c => testAccount2.Id,
                Package__c.Service_Type__c => 'Engage Digital Standalone'
            })
            .build()
            .getRecord();

        Map<Id, List<Package__c>> result = PackageHelper.mapAccountIdToPackages(
            new List<Package__c>{testPkg1, testPkg2, testPkg3}
        );

        Assert.areEqual(2, result.keySet().size(), 'There should be two account IDs in the result');
        Assert.areEqual(2, result.get(testAccount1.Id).size(), 'Account 1 should have two packages');
        Assert.areEqual(1, result.get(testAccount2.Id).size(), 'Account 2 should have one package');
    }


    @isTest
    static void testMapServiceToPackages() {
        List<Package__c> packages = (List<Package__c>) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Service_Type__c => ValueProviderBuilder.provideList(new List<String> {
                    QuoteHelper.NGBS_OFFICE_PRODUCT,
                    QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT,
                    QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT
                })
            })
            .quantity(3)
            .build()
            .getRecords();

        Map<String, List<Package__c>> result = PackageHelper.mapServiceToPackages(packages);

        Assert.areEqual(2, result.keySet().size(), 'There should be two services in the result');
        Assert.areEqual(1, result.get(QuoteHelper.NGBS_OFFICE_PRODUCT).size(), 'Office service should have one package');
        Assert.areEqual(2, result.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT).size(), 'Engage Digital Standalone service should have two packages');
    }

    @isTest
    static void testMarkPackagesAsMarketing() {
        Triggers.switchOff();
        Package__c testPkg1 = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Name => 'Package 1',
                Package__c.Account__c => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                Package__c.Account_Package_Id__c => '123123',
                Package__c.IsUsedForAccountAttribution__c => false,
                Package__c.Service_Type__c => 'Office'
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        Set<Id> packageIds = new Set<Id> { testPkg1.Id, null };
        Assert.areEqual(2, packageIds.size(), 'Set should have 2 items');
        Assert.isFalse(testPkg1.IsUsedForAccountAttribution__c, 'Marketing field should be false');

        Test.startTest();
            PackageHelper.markPackagesAsMarketing(packageIds);
        Test.stopTest();

        Assert.areEqual(1, packageIds.size(), 'Set should have 1 item');
        Assert.isTrue(packageIds.contains(testPkg1.Id), 'Set should have correct package Id');


        for (Package__c pkg : [SELECT IsUsedForAccountAttribution__c FROM Package__c WHERE Id IN :packageIds]) {
            Assert.isTrue(pkg.IsUsedForAccountAttribution__c, 'Package should be marked for account attribution');
        }
    }

    @isTest
    static void testUpdateMarketingAttributionFieldsCollectAccIdToPackageMap() {
        final String signUpFunnelOffice = 'Test Office';
        final String signUpFunnelRCCC = 'Test RCCC';
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Id, ValueProviderBuilder.provideDummyId(Account.SObjectType))
            .build()
            .getRecord();

        List<Package__c> testPackages = (List<Package__c>) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Account__c => testAcc.Id,
                Package__c.Id => ValueProviderBuilder.provideDummyId(Package__c.SObjectType),
                Package__c.RC_Signup_Funnel__c => ValueProviderBuilder.provideList(new List<String> {signUpFunnelOffice, signUpFunnelRCCC}),
                Package__c.Service_Type__c => ValueProviderBuilder.provideList(new List<String> {
                    QuoteHelper.NGBS_OFFICE_PRODUCT,
                    QuoteHelper.NGBS_RCCC_PRODUCT
                })
            })
            .quantity(2)
            .build()
            .getRecords();

        Map<Id, List<Package__c>> accIdToPackages = new Map<Id, List<Package__c>> {
            testAcc.Id => testPackages
        };

        Test.startTest();
            Map<Id, Package__c> accIdToPackageMap = PackageHelper.collectAccIdToPackageMap(accIdToPackages);
            Package__c resultPackage = accIdToPackageMap.get(testAcc.Id);
            Assert.areEqual(signUpFunnelOffice, resultPackage.RC_Signup_Funnel__c, 'The highest priority has Office service');


            testPackages[1].IsUsedForAccountAttribution__c = true;
            accIdToPackageMap = PackageHelper.collectAccIdToPackageMap(accIdToPackages);
            resultPackage = accIdToPackageMap.get(testAcc.Id);
            Assert.areEqual(signUpFunnelRCCC, resultPackage.RC_Signup_Funnel__c, 'The highest priority has RCCC service since it is marked as marketing');

            testPackages[0] = (Package__c) Test_Utils.putIntoUnwritableField(
                testPackages[0],
                Package__c.class,
                'CreatedDate',
                System.today()
            );

            testPackages[1] = (Package__c) Test_Utils.putIntoUnwritableFields(
                testPackages[1],
                Package__c.class,
                new Map<String, Object> {
                    'IsUsedForAccountAttribution__c' => false,
                    'CreatedDate' => System.today().addDays(-1)
                }
            );


            PackageHelper.collectAccIdToPackageMap(accIdToPackages);
        Test.stopTest();

        accIdToPackageMap.get(testAcc.Id);
        Assert.areEqual(signUpFunnelRCCC, resultPackage.RC_Signup_Funnel__c, 'The highest priority has RCCC service since it is older package');
    }

    @IsTest
    static void testBuildPackage() {
        // Create test data
        Triggers.switchOff();
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test Account')
            .create()
            .getRecord();

        Opportunity testOpportunity = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.AccountId, testAccount.Id)
            .setField(Opportunity.StageName, 'Prospecting')
            .setField(Opportunity.CloseDate, System.today())
            .create()
            .getRecord();
        Triggers.switchOn();

        String billingPackageId = '12345';
        String productName = 'Office';
        
        Test.startTest();
            Package__c pkg = PackageHelper.buildPackage(
                testOpportunity.Id,
                testAccount.Id,
                billingPackageId,
                productName
            );
        Test.stopTest();
        
        // Verify the package was built correctly
        Assert.areEqual(testOpportunity.Id, pkg.Opportunity__c, 'Opportunity ID should match');
        Assert.areEqual(testAccount.Id, pkg.Account__c, 'Account ID should match');
        Assert.areEqual(billingPackageId, pkg.Account_Package_Id__c, 'Billing package ID should match');
        Assert.areEqual(productName, pkg.Service_Type__c, 'Product name should match');
    }

    @IsTest
    static void testPackageComparator() {
        // Create test packages with different services and creation dates
        Package__c officePackage = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setField(Package__c.Service_Type__c, 'Office')
            .build()
            .getRecord();
            
        Package__c engageDigitalPackage = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setField(Package__c.Service_Type__c, 'Engage Digital Standalone')
            .build()
            .getRecord();
            
        Package__c rcccPackage = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setField(Package__c.Service_Type__c, 'RingCentral Contact Center')
            .build()
            .getRecord();
            
        Package__c engageVoicePackage = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setField(Package__c.Service_Type__c, 'Engage Voice Standalone')
            .build()
            .getRecord();
            
        Package__c unknownServicePackage = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setField(Package__c.Service_Type__c, 'Unknown Service')
            .build()
            .getRecord();
        
        // Test creation date comparison
        DateTime now = DateTime.now();
        officePackage = (Package__c)Test_Utils.putIntoUnwritableField(
            officePackage,
            Package__c.class,
            'CreatedDate',
            now
        );
        
        engageDigitalPackage = (Package__c)Test_Utils.putIntoUnwritableField(
            engageDigitalPackage,
            Package__c.class,
            'CreatedDate',
            now.addDays(-1)
        );
        
        // Create instance of comparator
        PackageHelper.PackageComparator comparator = new PackageHelper.PackageComparator();
        
        Test.startTest();
            // Test date comparison (engageDigital is older so should come first)
            Integer dateComparisonResult = comparator.compare(engageDigitalPackage, officePackage);
            
            // Test service type comparison (when dates are same)
            rcccPackage = (Package__c)Test_Utils.putIntoUnwritableField(
                rcccPackage,
                Package__c.class,
                'CreatedDate',
                now
            );
            engageVoicePackage = (Package__c)Test_Utils.putIntoUnwritableField(
                engageVoicePackage,
                Package__c.class,
                'CreatedDate',
                now
            );
            
            Integer serviceComparisonResult1 = comparator.compare(officePackage, rcccPackage);
            Integer serviceComparisonResult2 = comparator.compare(rcccPackage, engageVoicePackage);
            Integer serviceComparisonResult3 = comparator.compare(officePackage, unknownServicePackage);
        Test.stopTest();
        
        // Verify results
        Assert.areEqual(-1, dateComparisonResult, 'Older package should be ranked higher (negative result)');
        Assert.isTrue(serviceComparisonResult1 < 0, 'Office should be ranked higher than RingCentral Contact Center');
        Assert.isTrue(serviceComparisonResult2 < 0, 'RingCentral Contact Center should be ranked higher than Engage Voice');
        Assert.isTrue(serviceComparisonResult3 < 0, 'Known service should be ranked higher than unknown service');
    }
}