@isTest
private class Test_SyncMobileUserDiscounts {

    @isTest
    private static void verifyErrorIsThrownForTooMuchAccountsSync() {

        List<SyncMobileUserDiscounts.SyncDiscountsParam> syncDiscountsParams =
            new List<SyncMobileUserDiscounts.SyncDiscountsParam>();

        for (Integer i = 0; i < 21; i ++) {
            syncDiscountsParams.add(
                new SyncMobileUserDiscounts.SyncDiscountsParam(
                    StringHelper.getRandomString(7),
                    new NGBS_Discount.DiscountItemWrapper()
                )
            );
        }

        try {
            new SyncMobileUserDiscounts(syncDiscountsParams);
            System.assert(false, 'Exception should be thrown');
        } catch (Exception ex) {
            System.assert(
                ex.getMessage().contains('You cannot process more than 20 accounts'),
                'Unexpected exception message: ' + ex.getMessage()
            );
        }
    }

    @isTest
    private static void testCheckParametersMethod() {

        SyncMobileUserDiscounts jobInstance = new SyncMobileUserDiscounts(
            new List<SyncMobileUserDiscounts.SyncDiscountsParam>{
                new SyncMobileUserDiscounts.SyncDiscountsParam(
                    StringHelper.getRandomString(7),
                    new NGBS_Discount.DiscountItemWrapper()
                )
            }
        );

        System.assertEquals(
            new List<SyncMobileUserDiscounts.SyncDiscountsParam>(),
            jobInstance.checkParameters(null),
            'checkParameters method should return empty List if passed argument is null'
        );


        List<SyncMobileUserDiscounts.SyncDiscountsParam> syncDiscountsParams =
            new List<SyncMobileUserDiscounts.SyncDiscountsParam>();
        syncDiscountsParams.add(
            new SyncMobileUserDiscounts.SyncDiscountsParam(null, null)
        );
        syncDiscountsParams.add(
            new SyncMobileUserDiscounts.SyncDiscountsParam(
                '',
                new NGBS_Discount.DiscountItemWrapper()
            )
        );
        syncDiscountsParams.add(
            new SyncMobileUserDiscounts.SyncDiscountsParam(
                StringHelper.getRandomString(7),
                new NGBS_Discount.DiscountItemWrapper()
            )
        );

        List<SyncMobileUserDiscounts.SyncDiscountsParam> result = jobInstance.checkParameters(syncDiscountsParams);
        System.assertEquals(
            1,
            result.size(),
            'checkParameters method should return List containing params with not empty billing id and not null QuoteLineItem'
        );
    }

    @isTest
    private static void testGetBillingInfoMethod() {

        SyncMobileUserDiscounts jobInstance = new SyncMobileUserDiscounts(
            new List<SyncMobileUserDiscounts.SyncDiscountsParam>{
                new SyncMobileUserDiscounts.SyncDiscountsParam(
                    StringHelper.getRandomString(7),
                    new NGBS_Discount.DiscountItemWrapper()
                )
            }
        );

        try {
            jobInstance.getBillingInfo(null);
            System.assert(false, 'Exception should be thrown');
        } catch (Exception ex) {
            System.assert(
                ex.getMessage().contains('Billing id is empty'),
                'Unexpected exception message: ' + ex.getMessage()
            );
        }

        Account testAcc = (Account) new SobjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test account',
                Account.Billing_Id__c => 'some_billing_id'
            })
            .create()
            .getRecord();

        try {
            jobInstance.getBillingInfo(testAcc.Billing_Id__c);
            System.assert(false, 'Exception should be thrown');
        } catch (Exception ex) {
            System.assert(
                ex.getMessage().contains('Cannot find find a Package__c for account with BillingId = "' + testAcc.Billing_Id__c + '"'),
                'Unexpected exception message: ' + ex.getMessage()
            );
        }


        Package__c pkg = (Package__c) new SobjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Package__c.Account__c => testAcc.Id,
                Package__c.Enterprise_Account_ID__c => testAcc.Id,
                Package__c.Account_Package_ID__c => '00000001',
                Package__c.Package_Catalog_Id__c => '18',
                Package__c.Package_Version__c => '3'
            })
            .create()
            .getRecord();

        Package__c billingInfo = jobInstance.getBillingInfo(testAcc.Billing_Id__c);
        System.assertEquals(
            pkg.Id,
            billingInfo.Id,
            'getBillingInfo method should found Package__c associated with Account'
        );
    }

    @isTest
    private static void testBuildMobileUserDTGMethod() {
        Account testAccount = (Account) new SobjectBuilder(Account.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    Account.Name => 'Test account'
                })
                .create()
                .getRecord();

        Opportunity opp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Name => 'Test Singapore Opportunity',
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL_EU,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today(),
                Opportunity.CurrencyIsoCode => 'SGD'
            })
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.isPrimary__c => true,
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo(),
                Quote.PaymentMethod__c => QuoteHelper.PAYMENT_METHOD_INVOICE,
                Quote.Pricebook2Id => Test.getStandardPricebookId()
            })
            .create()
            .getRecord();

        new SobjectBuilder(NGBS_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                NGBS_Settings__c.BaseEndpoint__c => 'https://testapi/',
                NGBS_Settings__c.AccountManagerPath__c => '/restapi/account-manager/v1.0',
                NGBS_Settings__c.Login__c => '0001',
                NGBS_Settings__c.Password__c => '0001'
            })
            .create();

        SyncMobileUserDiscounts jobInstance = new SyncMobileUserDiscounts(
            new List<SyncMobileUserDiscounts.SyncDiscountsParam>{
                new SyncMobileUserDiscounts.SyncDiscountsParam(
                    StringHelper.getRandomString(7),
                    new NGBS_Discount.DiscountItemWrapper()
                )
            }
        );

        Package__c pkg = (Package__c) new SobjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Package__c.Account__c => testAccount.Id,
                Package__c.Account_Package_ID__c => '00000001',
                Package__c.Package_Catalog_Id__c => '18',
                Package__c.Package_Version__c => '3'
            })
            .build()
            .getRecord();

        QuoteLineItem dlUnlimited = (QuoteLineItem) new SobjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.QuoteId => testQuote.Id,
                QuoteLineItem.Discount_Number__c => 10,
                QuoteLineItem.Discount_type__c => QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE,
                QuoteLineItem.ChargeTerm__c => Product2helper.CHARGE_TERM_MONTHLY
            })
            .build()
            .getRecord();
        dlUnlimited.Product2 = new Product2(
            ExtID__c = Product2Helper.DL_UNL_ELEMENT_ID,
            Billing_Type__c = Product2Helper.BILLING_TYPE_RECURRING
        );

        Contract__c accountContract = null;
        NGBS_Discount.DiscountItemWrapper mobileUser = NGBS_Discount.getMobileUser(testQuote, new List<QuoteLineItem>{ dlUnlimited }, 'Monthly', accountContract);

        BillingHttpRequestMock testMock = new BillingHttpRequestMock();
        testMock.endpointToBodyMap = new Map<String, BillingHttpRequestMock.MockInfo>{
            '/contract' => new BillingHttpRequestMock.MockInfo('[]')
        };

        Test.setMock(HttpCalloutMock.class, testMock);

        Test.startTest();
            NGBS_Discount.DiscountTemplateGroup muDTG = jobInstance.buildMobileUserDTG(
                'test_billing_id',
                pkg,
                'A',
                mobileUser
            );

            System.assert(
                muDTG != null,
                'buildMobileUserDTG method should build discount template group for Mobile User'
            );

            System.assertEquals(
                NGBS_Discount.MU_ELA,
                muDTG.description,
                'built discount template group must have description equal to "' + NGBS_Discount.MU_ELA + '"'
            );
            System.assertEquals(
                pkg.Package_Catalog_Id__c,
                muDTG.target.catalogId,
                'built discount template group must have the same id target.catalogId as in the associated Package__c'
            );
            System.assertEquals(
                pkg.Package_Version__c,
                muDTG.target.version,
                'built discount template group must have the same id target.version as in the associated Package__c'
            );

            List<NGBS_Discount.DiscountTemplate> discountTemplates = muDTG.discountTemplates;
            System.assert(!discountTemplates.isEmpty(), 'discount template group must have at least 1 discount template');

            NGBS_Discount.DiscountTemplate dt = discountTemplates.get(0);
            Map<String, NGBS_Discount.DiscountValue> values = dt.values;
            NGBS_Discount.DiscountValue discountValue = values.get('Monthly');
            System.assertEquals(
                dlUnlimited.Discount_Number__c,
                discountValue.value,
                'discount value should be taken from Discount_Number__c of the corresponding QuoteLineItem'
            );
            System.assertEquals(
                NGBS_Discount.BILLING_DISCOUNT_TYPE_PERCENTAGE,
                discountValue.unit,
                'discount type should be taken from Discount_type__c of the corresponding QuoteLineItem'
            );

        Test.stopTest();
    }

    @isTest
    private static void testGetDiscountsIdsForRemoveMethod() {

        SyncMobileUserDiscounts jobInstance = new SyncMobileUserDiscounts(
            new List<SyncMobileUserDiscounts.SyncDiscountsParam>{
                new SyncMobileUserDiscounts.SyncDiscountsParam(
                    StringHelper.getRandomString(7),
                    new NGBS_Discount.DiscountItemWrapper()
                )
            }
        );

        System.assertEquals(
            new Set<String>(),
            jobInstance.getDiscountsIdsForRemove(null),
            'mthod should return empty set if passed argument is null or empty list'
        );

        NGBS_Discount.DiscountTemplateGroup dtg1 = new NGBS_Discount.DiscountTemplateGroup();
        dtg1.description = NGBS_Discount.MU_ELA;
        dtg1.id = '0001';

        NGBS_Discount.DiscountTemplateGroup dtg2 = new NGBS_Discount.DiscountTemplateGroup();
        dtg2.description = 'some other description';
        dtg2.id = '0002';

        List<NGBS_Discount.DiscountTemplateGroup> dtgList = new List<NGBS_Discount.DiscountTemplateGroup>();
        dtgList.add(dtg1);
        dtgList.add(dtg2);

        Set<String> result = jobInstance.getDiscountsIdsForRemove(dtgList);
        System.assert(
            result.size() == 1,
            'the method should return a set of ids to remove based on the "description" field'
        );
    }

    @isTest
    static void testSyncDiscountForMobileUser() {
        Triggers.switchOff();
        new SobjectBuilder(NGBS_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                NGBS_Settings__c.BaseEndpoint__c => 'https://testapi/',
                NGBS_Settings__c.AccountManagerPath__c => '/restapi/account-manager/v1.0',
                NGBS_Settings__c.Login__c => '0001',
                NGBS_Settings__c.Password__c => '0001'
            })
            .create();

        Account billingAccount = (Account) new SobjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test billable account',
                Account.ELA_Account_Type__c => AccountHelper.ACCOUNT_TYPE_ELA_BILLING
            })
            .create()
            .getRecord();

        Account serviceAccount = (Account) new SobjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test service account',
                Account.ELA_Account_Type__c => AccountHelper.ACCOUNT_TYPE_ELA_SERVICE,
                Account.Billing_Id__c => 'some_billing_id'
            })
            .create()
            .getRecord();

        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.FirstName => 'test first name',
                Contact.LastName => 'test last name',
                Contact.AccountId => billingAccount.Id,
                Contact.Email => 'test1@test.com',
                Contact.Preferred_Language__c => 'en_US'
            })
            .create()
            .getRecord();

        new SobjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Package__c.Account__c => serviceAccount.Id,
                Package__c.Enterprise_Account_ID__c => serviceAccount.Id,
                Package__c.Account_Package_ID__c => '00000001',
                Package__c.Package_Catalog_Id__c => '18',
                Package__c.Package_Version__c => '3'
            })
            .create();

        new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                AccountContactRole.AccountId => ValueProviderBuilder.provideList(
                    new List<Id>{ billingAccount.Id, serviceAccount.Id }
                ),
                AccountContactRole.ContactId => testContact.Id
            })
            .quantity(2)
            .create();

        new SobjectBuilder(AccountRelation__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                AccountRelation__c.Parent_Account__c => billingAccount.Id,
                AccountRelation__c.Child_Account__c => serviceAccount.Id,
                AccountRelation__c.Relation_Type__c => 'ELA'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => billingAccount.Id,
                Opportunity.CloseDate => System.today(),
                Opportunity.Name => 'TestOpportunity'
            })
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SobjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.OpportunityId => opp.Id,
                Quote.Name => 'test quote',
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo()
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        QuoteLineItem dlUnlimited = (QuoteLineItem) new SobjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.QuoteId => testQuote.Id,
                QuoteLineItem.Discount_Number__c => 10,
                QuoteLineItem.Discount_type__c => QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE,
                QuoteLineItem.ChargeTerm__c => Product2helper.CHARGE_TERM_MONTHLY
            })
            .build()
            .getRecord();
        dlUnlimited.Product2 = new Product2(
            ExtID__c = Product2Helper.DL_UNL_ELEMENT_ID,
            Billing_Type__c = Product2Helper.BILLING_TYPE_RECURRING
        );

        Contract__c accountContract = null;
        NGBS_Discount.DiscountItemWrapper mobileUser = NGBS_Discount.getMobileUser(testQuote, new List<QuoteLineItem>{ dlUnlimited }, 'Monthly', accountContract);

        BillingHttpRequestMock testMock = new BillingHttpRequestMock();
        testMock.endpointToBodyMap = new Map<String, BillingHttpRequestMock.MockInfo>{
            '/discountTemplateGroup' => new BillingHttpRequestMock.MockInfo('[{"id":77867005,"packageId":125410005,"contractId":null,"description":"MU ELA","priority":"A","addedAt":"2021-10-29T06:08:44.495837Z[UTC]","promoCode":null,"promoType":null,"target":{"catalogId":"18","version":"3"},"discountTemplates":[{"id":168608005,"description":"Mobile User","applicableTo":{"type":"CatalogId","id":"LC_MU_281"},"applicationTerms":{"startDate":"2021-10-26T07:00Z[UTC]","endDate":null,"maxLicenses":0,"licenseScope":"All"},"values":{"Monthly":{"unit":"Percent","value":11}},"valueTerm":"PackageMasterDuration"}],"visible":true}]')
        };

        Test.setMock(HttpCalloutMock.class, testMock);

        Test.startTest();
            System.enqueueJob(
                new SyncMobileUserDiscounts(
                    new List<SyncMobileUserDiscounts.SyncDiscountsParam>{
                        new SyncMobileUserDiscounts.SyncDiscountsParam(
                            serviceAccount.Billing_Id__c,
                            mobileUser
                        )
                    }
                )
            );
        Test.stopTest();

        List<PlatformLog__c> logs = new List<PlatformLog__c>([SELECT Id, Error__c, StackTrace__c FROM PlatformLog__c WHERE Source__c = 'SyncMobileUserDiscounts']);
        System.assertEquals(
            0,
            logs.size(),
            'there should be no errors during the synchronization of discounts'
        );
    }

    @isTest
    private static void testGetBillingContractsEmpty() {
        Test.startTest();
            List<BillingWrappers.BillingContract> contracts = new SyncMobileUserDiscounts(null).getBillingContracts(null, null, null);
        Test.stopTest();

        Assert.isTrue(contracts.isEmpty(), 'There are no contracts extracted');
    }

    @isTest
    private static void testGetBillingContractsError() {
        NGBSAPI.settings.BaseEndpoint = null;
        NGBSAPI.settings.AccountManagerPath = null;

        Test.startTest();
            try {
                List<BillingWrappers.BillingContract> contracts = new SyncMobileUserDiscounts(null).getBillingContracts('test', 'test', 'test');
                Assert.fail('An error should be thrown');
            } catch (Exception ex) {
                Assert.areEqual('Invalid id: test', ex.getMessage(), 'Messages are equal');
            }
        Test.stopTest();
    }
}