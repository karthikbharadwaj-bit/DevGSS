@isTest
private class Test_ContractRestAPI {
    private static final Integer Q_VALUE = 1;
    private static final Integer ENT_QUANTITY = 1;
    private static final String TEST_QUOTE = 'TEST_QUOTE';
    private static final String packageInfo = '[{"packageInfo":{"productName":"Fax"}}]';
    private static final String bodyForResync = '{"id":5301002,"createdAt":"2019-06-13T14:38:28.985Z[UTC]","lastUpdated":"2019-06-13T14:42:57.296Z[UTC]","startBillingCycleNumber":0,"startDate":"2019-06-13","renewalDate":null,"description":"{\"contractExtId\":\"Office\",\"salesAgreement\":\"0Q00S0000005CeCSAU\"}","term":24,"renewalTerm":36,"autoRenewal":true,"packageVersion":"1","licenses":[{"id":1833002,"catalogId":"LC_MU_281","contractualQty":0},{"id":1834002,"catalogId":"LC_CRF_43","contractualQty":1},{"id":1835002,"catalogId":"LC_DL-UNL_50","contractualQty":2},{"id":1836002,"catalogId":"LC_CRF_51","contractualQty":1}]}';

    private class MockResyncResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatus('OK');
            res.setBody(bodyForResync);
            res.setStatusCode(200);
            return res;
        }
    }

    static List<BillingWrappers.BillingContract> createBillingContracts() {
        BillingWrappers.BillingContract bc1 = new BillingWrappers.BillingContract();
        bc1.id = '1';
        bc1.startBillingCycleNumber = -2;
        bc1.term = 1;
        bc1.startDate = Date.today();
        BillingWrappers.BillingContract bc2 = new BillingWrappers.BillingContract();
        bc1.id = '2';
        bc1.startBillingCycleNumber = -1;
        bc1.term = 1;
        bc1.startDate = Date.today();
        BillingWrappers.BillingContract bc3 = new BillingWrappers.BillingContract();
        bc1.id = '3';
        bc1.startBillingCycleNumber = 0;
        bc1.term = 1;
        bc1.startDate = Date.today();

        return new List<BillingWrappers.BillingContract> {bc1, bc2, bc3};
    }

    static Quote buildQuoteWithAccount() {
        Account acc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Test Account',
                Account.Id => ValueProviderBuilder.provideDummyId(Account.sObjectType)
            })
            .build()
            .getRecord();
        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => TEST_QUOTE,
                Quote.Initial_Term_months__c => '12',
                Quote.Term_months__c => '12',
                Quote.Auto_Renewal__c => true,
                Quote.Package_Info__c => packageInfo
            })
            .build()
            .getRecord();

        return (Quote) Test_Utils.putIntoUnwritableFields(
            testQuote,
            Quote.class,
            new Map<String, Object> {
                'Account' => acc,
                'AccountId' => acc.Id
            }
        );
    }

    static Quote selectQuote() {
        QuoteSelector s = new QuoteSelector();
        return (Quote) new ListOptional(s
            .selectQuoteByName(TEST_QUOTE)
            .subselect(new QuoteLineItemSelector().selectQuoteLineItemsForSignUp())
            .selectFields(s.getFieldsForSignUp())
            .executeQuery()
        ).getFirst();
    }

    @TestSetup
    static void makeData() {
        Triggers.switchOff();
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.sObjectType),
                Opportunity.Name => 'Test Opportunity',
                Opportunity.CloseDate => System.today().addMonths(1)
            })
            .create()
            .getRecord();

        String quotePackageInfo = NGBSTestDataGenerator.generateQuotePackageInfo(new Map<String, Object> {
            'Id' => '23',
            'Version' => '3',
            'PackageName' => 'Office',
            'ProductName' => 'Office',
            'PackageInfoId' => '1234'
        });

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Quote.OpportunityId => opp.Id,
                    Quote.Name => TEST_QUOTE,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                    Quote.Pricebook2Id => Test.getStandardPricebookId(),
                    Quote.Initial_Term_months__c => '12',
                    Quote.Term_months__c => '12',
                    Quote.Start_Date__c => System.today(),
                    Quote.Package_Info__c => quotePackageInfo
                }
            )
            .create()
            .getRecord();

        List<Product2> testProducts = new SobjectBuilder(Product2.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Product2.Name => ValueProviderBuilder.provideUniqueString(),
                    Product2.IsActive => true,
                    Product2.ExtId__c => ValueProviderBuilder.provideList(
                        new List<String> {
                            Product2Helper.DL_UNL_ELEMENT_ID,
                            'LC_DL_75'
                        }
                    ),
                    Product2.Feature__c => 17
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        List<PricebookEntry> pbes = new SobjectBuilder(PricebookEntry.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                    PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(testProducts),
                    PricebookEntry.UnitPrice => 200,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.CurrencyIsoCode => 'USD'
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        List<Entitlement__c> testEntitlements = (List<Entitlement__c>) new SObjectBuilder(Entitlement__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Entitlement__c.Account__c => opp.AccountId,
                Entitlement__c.Name => ValueProviderBuilder.provideUniqueString(),
                Entitlement__c.Active__c => true,
                Entitlement__c.Price__c => 200,
                Entitlement__c.Quantity__c => ENT_QUANTITY,
                Entitlement__c.Product__c => ValueProviderBuilder.provideParents(testProducts)
            })
            .quantity(2)
            .create()
            .getRecords();

        String packageInfoDLUnlimited = NGBSTestDataGenerator.generateQLIPackageInfo(new Map<String, Object> {
            'Id' => '23',
            'Duration' => 'Monthly',
            'CategoryCode' => 'DL-UNL',
            'CategoryPath' => 'DL:DL-UNL',
            'q' => Q_VALUE
        });

        String packageInfoDL = NGBSTestDataGenerator.generateQLIPackageInfo(new Map<String, Object> {
            'Id' => '23',
            'Duration' => 'Monthly',
            'CategoryCode' => 'DL',
            'CategoryPath' => 'DL'
        });

        new SobjectBuilder(QuoteLineItem.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    QuoteLineItem.Product2Id => ValueProviderBuilder.provideParents(testProducts),
                    QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideParents(pbes),
                    QuoteLineItem.Entitlement__c => ValueProviderBuilder.provideParents(testEntitlements),
                    QuoteLineItem.QuoteId => testQuote.Id,
                    QuoteLineItem.Quantity => Q_VALUE,
                    QuoteLineItem.UnitPrice => 100,
                    QuoteLineItem.Package_Info_QLI__c => ValueProviderBuilder.provideList(
                        new List<String> {
                            packageInfoDLUnlimited,
                            packageInfoDL
                        }
                    ),
                    QuoteLineItem.PackageInfo__c => ValueProviderBuilder.provideList(
                        new List<String> {
                            packageInfoDLUnlimited,
                            packageInfoDL
                        }
                    )
                }
            )
            .quantity(2)
            .create();

        Triggers.switchOn();
    }

    @isTest
    static void testGetContracts() {
        Contract__c testContr = (Contract__c) new SObjectBuilder(Contract__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contract__c.Name => 'testContract',
                Contract__c.Description__c => 'description',
                Contract__c.ExtId__c => 'testExternalId'
            })
            .create()
            .getRecord();

        new SObjectBuilder(Contract_Discount__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contract_Discount__c.Name => 'test',
                Contract_Discount__c.Discount__c => 50,
                Contract_Discount__c.Contract__c => testContr.Id,
                Contract_Discount__c.Duration__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Contract_Discount__c.ApplicableTo__c => 'LC_DL-UNL_50'
            })
            .create();

        Test.startTest();
            RestRequest request = new RestRequest();
            RestContext.request = request;
            RestContext.response = new RestResponse();

            ContractRestAPI.getContracts();
            Assert.isNotNull(RestContext.response.responseBody, 'Response body is null');
        Test.stopTest();
    }

    @isTest
    static void testResyncContractParamsConstructor() {
        Quote testQuote = buildQuoteWithAccount();

        Test.startTest();
            ContractRestAPI.ResyncContractParams resyncContrParams = new ContractRestAPI.ResyncContractParams(testQuote);
        Test.stopTest();

        Assert.areEqual(Integer.valueOf(testQuote.Initial_Term_months__c), resyncContrParams.term, 'term field populated incorrectly');
        Assert.areEqual(Integer.valueOf(testQuote.Term_months__c), resyncContrParams.renewalTerm, 'renewalTerm field populated incorrectly');
        Assert.areEqual(testQuote.Auto_Renewal__c, resyncContrParams.autoRenewal, 'autoRenewal field populated incorrectly');
    }

    @isTest
    static void testResyncContractParamsConstructorBlankInitialTermMonths() {
        Quote testQuote = new Quote(
            Name = 'TestQuote',
            Package_Info__c = packageInfo
        );

        Test.startTest();
            try {
                new ContractRestAPI.ResyncContractParams(testQuote);
                Assert.Fail('Should throw exception due to blank Initial_Term_months__c field on Quote');
            } catch (AquivaHelper.AquivaException ex) {
                Assert.isTrue(ex.getMessage().contains('initial term cannot be empty'), 'Wrong exception message');
            }
        Test.stopTest();
    }

    @isTest
    static void testResyncContractParamsConstructorBlankTermMonths() {
        Quote testQuote = new Quote(
            Name = 'TestQuote',
            Initial_Term_months__c = '12',
            Auto_Renewal__c = true,
            Package_Info__c = packageInfo
        );

        Test.startTest();
            try {
                new ContractRestAPI.ResyncContractParams(testQuote);
                Assert.Fail('Should throw exception due to blank Term_months__c field on Quote');
            } catch (AquivaHelper.AquivaException ex) {
                Assert.isTrue(ex.getMessage().contains('renewal term can not be empty'), 'Wrong exception message');
            }
        Test.stopTest();
    }

    @isTest
    private static void testContractParams() {
        Quote reselectedQuote = selectQuote();
        Test.startTest();
            ContractRestAPI.ContractParams params = new ContractRestAPI.ContractParams(reselectedQuote);
            ContractRestAPI.UpdateContractParams updateParams = new ContractRestAPI.UpdateContractParams(reselectedQuote);
        Test.stopTest();

        Assert.areEqual(1, params.packages.size(), 'count of packages should be 1');
        Assert.areEqual(1, updateParams.packages.size(), 'count of packages should be 1');

        ContractRestAPI.ContractualLicense[] licenses = params.packages.get(0).licenses;
        ContractRestAPI.ContractualLicense[] updateLicenses = updateParams.packages.get(0).licenses;

        Assert.areEqual(1, licenses.size(), 'count of licenses should be 1(we should send only DL Unlimited)');
        Assert.areEqual(1, updateLicenses.size(), 'count of licenses should be 1(we should send only DL Unlimited)');

        ContractRestAPI.ContractualLicense license = licenses.get(0);
        ContractRestAPI.ContractualLicense updateLicense = updateLicenses.get(0);

        Assert.areEqual(
            Product2Helper.DL_UNL_ELEMENT_ID,
            license.catalogId,
            'license.catalogId should be equals to Product2Helper.DL_UNL_ELEMENT_ID'
        );
        Assert.areEqual(
            Product2Helper.DL_UNL_ELEMENT_ID,
            updateLicense.catalogId,
            'license.catalogId should be equals to Product2Helper.DL_UNL_ELEMENT_ID'
        );

        Assert.areEqual(
            Q_VALUE,
            license.contractualQty,
            'license.contractualQty should be equals to "q" value in PackageInfo__c for DL Unlimited quoteLineItem'
        );
        Assert.areEqual(
            Q_VALUE,
            updateLicense.contractualQty,
            'license.contractualQty should be equals to "q" value in PackageInfo__c for DL Unlimited quoteLineItem'
        );
    }

    @isTest
    private static void testCreateContractParams() {
        Quote reselectedQuote = selectQuote();
        Test.startTest();
            ContractRestAPI.CreateContractParams params = new ContractRestAPI.CreateContractParams(reselectedQuote);
        Test.stopTest();

        Assert.areEqual(1, params.packages.size(), 'count of packages should be 1');

        ContractRestAPI.ContractualLicense[] licenses = params.packages.get(0).licenses;
        Assert.areEqual(1, licenses.size(), 'count of licenses should be 1(we should send only DL Unlimited)');
        ContractRestAPI.ContractualLicense license = licenses.get(0);

        Assert.areEqual(
            Product2Helper.DL_UNL_ELEMENT_ID,
            license.catalogId,
            'license.catalogId should be equals to Product2Helper.DL_UNL_ELEMENT_ID'
        );
        Assert.areEqual(
            Q_VALUE,
            license.contractualQty,
            'license.contractualQty should be equals to "q" value in PackageInfo__c for DL Unlimited quoteLineItem'
        );
    }

    @isTest
    private static void verifyActiveContractReturn() {
        List<BillingWrappers.BillingContract> billingContracts = createBillingContracts();
        BillingWrappers.BillingContract result = ContractRestAPI.getActiveContract(billingContracts);

        System.assert(result != null, 'Should be one contract');
        System.assert(result.isActiveContract(), 'Should be active');
    }

    @isTest
    private static void verifyActiveContractExist() {
        List<BillingWrappers.BillingContract> billingContracts = createBillingContracts();
        Boolean result = ContractRestAPI.hasActiveContract(billingContracts);

        System.assert(result, 'Should be one contract');
    }

    @isTest
    private static void verifyThatSelectContractReturnNull() {
        Contract__c result = ContractRestAPI.selectContract(null);
        Assert.isNull(result, 'Method should return null for null pInfo');
    }

    @isTest
    private static void verifyThatSelectContractReturnCorrectyValue() {
        Contract__c testContr = (Contract__c) new SobjectBuilder(Contract__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Contract__c.Name => 'testContract',
                    Contract__c.Description__c => 'description',
                    Contract__c.ExtId__c => 'testExternalId'
                }
            )
            .create()
            .getRecord();

        new SobjectBuilder(Contract_Discount__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Contract_Discount__c.Name => 'testContractDiscount',
                    Contract_Discount__c.Discount__c => 50,
                    Contract_Discount__c.Contract__c => testContr.Id
                }
            )
            .create();

        BillingWrappers.QuotePackageInfo pInfo = new BillingWrappers.QuotePackageInfo();
        pInfo.contract.id = testContr.Id;

        Test.startTest();
            Contract__c result = ContractRestAPI.selectContract(pInfo);
        Test.stopTest();

        Assert.areEqual(testContr.Id, result.Id, 'Method should return correct Contract');
    }

    @isTest
    private static void verifyThatMakeRequestReturnNullForEmptyURL() {
        HttpResponse result = ContractRestAPI.makeRequest(null, null, null);
        Assert.isNull(result, 'Method should return null for null URL value');
    }

    @isTest
    private static void verifyThatGetContractDescriptionReturnEmptyStringForNullContractInPInfo() {
        BillingWrappers.QuotePackageInfo pInfo = new BillingWrappers.QuotePackageInfo();
        pInfo.contract = null;
        String result = ContractRestAPI.getContractDescription(null, pInfo);
        Assert.areEqual('', result, 'Method should return empty string');
    }

    @isTest
    private static void verifyThatGetActiveContractReturnNull() {
        BillingWrappers.BillingContract result = ContractRestAPI.getActiveContract(new List<BillingWrappers.BillingContract>());
        Assert.isNull(result, 'Method should return null');
    }

    @isTest
    private static void verifyThatCreateContractParamsThrowExceptionDueToInitialTerms() {
        Quote testQuote = buildQuoteWithAccount();
        testQuote.Initial_Term_months__c = null;

        Test.startTest();
            try {
                new ContractRestAPI.CreateContractParams(testQuote);
                Assert.Fail('Exception should be thrown');
            } catch (AquivaHelper.AquivaException ex) {
                Assert.isTrue(ex.getMessage().contains('initial term can not be empty'), 'Wrong exception message');
            }
        Test.stopTest();
    }

    @isTest
    private static void verifyThatCreateContractParamsThrowExceptionDueToTermMonths() {
        Quote testQuote = buildQuoteWithAccount();
        testQuote.Term_months__c = null;

        Test.startTest();
            try {
                new ContractRestAPI.CreateContractParams(testQuote);
                Assert.Fail('Exception should be thrown');
            } catch (AquivaHelper.AquivaException ex) {
                Assert.isTrue(ex.getMessage().contains('renewal term can not be empty'), 'Wrong exception message');
            }
        Test.stopTest();
    }

    @isTest
    private static void verifyThatCreateContractParamsThrowExceptionDueToStartDate() {
        Quote testQuote = buildQuoteWithAccount();
        testQuote.Start_Date__c = null;

        Test.startTest();
            try {
                new ContractRestAPI.CreateContractParams(testQuote);
                Assert.Fail('Exception should be thrown');
            } catch (AquivaHelper.AquivaException ex) {
                Assert.isTrue(ex.getMessage().contains('start date can not be empty'), 'Wrong exception message');
            }
        Test.stopTest();
    }

    @isTest
    private static void verifyThatCreateContractParamsThrowExceptionDueToPackageInfo() {
        Quote testQuote = buildQuoteWithAccount();
        testQuote.Package_Info__c = '';
        testQuote.Start_Date__c = System.today();

        Test.startTest();
            try {
                new ContractRestAPI.CreateContractParams(testQuote);
                Assert.Fail('Exception should be thrown');
            } catch (AquivaHelper.AquivaException ex) {
                Assert.isTrue(ex.getMessage().contains('Failed to parse packagesInfo'), 'Wrong exception message');
            }
        Test.stopTest();
    }

    @isTest
    private static void verifyThatCreateNGBSContractThrowException() {
        try {
            ContractRestAPI.createNGBSContract(null, null);
            Assert.Fail('Exception should be thrown');
        } catch (AquivaHelper.AquivaException ex) {
            Assert.isTrue(ex.getMessage().contains('Create contract:'), 'Wrong exception message');
        }
    }

    @isTest
    private static void verifyThatUpdateNGBSContractThrowException() {
        try {
            ContractRestAPI.updateNGBSContract(null, null, null);
            Assert.Fail('Exception should be thrown');
        } catch (AquivaHelper.AquivaException ex) {
            Assert.isTrue(ex.getMessage().contains('Update contract:'), 'Wrong exception message');
        }
    }

    @isTest
    private static void verifyThatUpdateNGBSContractSuccess() {

        new SObjectBuilder(NGBS_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                NGBS_Settings__c.BaseEndpoint__c => 'BASE_ENDPOINT',
                NGBS_Settings__c.AccountManagerPath__c => 'MANAGER_PATH',
                NGBS_Settings__c.Login__c => ValueProviderBuilder.provideUniqueString(),
                NGBS_Settings__c.Password__c => ValueProviderBuilder.provideUniqueString()
            })
            .create();

        Test.setMock(HttpCalloutMock.class, new MockResyncResponse());

        Quote testQuote = buildQuoteWithAccount();
        Test.startTest();
            HttpResponse res = ContractRestAPI.updateNGBSContract('123', '123', testQuote);
        Test.stopTest();
        Assert.areEqual(200, res.getStatusCode(), 'Status code should be "200"');
    }

    @isTest
    static void testContractParamsZeroRenewalTerm() {
        Quote testQuote = buildQuoteWithAccount();
        testQuote.Auto_Renewal__c = false;
        testQuote.Term_months__c = null;
        testQuote.UpdateContractTerms__c = true;
        ContractRestAPI.ContractParams params = new ContractRestAPI.ContractParams(testQuote);

        Assert.areEqual(
            0,
            params.renewalTerm,
            'renewalTerm value should be 0 if Term_months__c of Quote is null'
        );
        Assert.areEqual(
            testQuote.Auto_Renewal__c,
            params.autoRenewal,
            'autoRenewal value should equal to Auto_Renewal__c of Quote'
        );
    }


    @isTest
    private static void testCreateContractParamsMPUB() {
        Quote reselectedQuote = selectQuote();
        Test.startTest();
            ContractRestAPI.CreateContractParams params = new ContractRestAPI.CreateContractParams(reselectedQuote);
        Test.stopTest();

        ContractRestAPI.ContractPackage[] packages = params.packages;
        Assert.areEqual(1, packages.size(), 'count of packages should be 1');
        ContractRestAPI.ContractPackage pkg = packages.get(0);
        Assert.areEqual(
            '1234',
            pkg.packageId,
            'package.packageId should be equals to 1234'
        );
    }
}