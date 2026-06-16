@isTest
private class Test_DQDataHelper {

    @IsTest
    static void testProductDataNullInit() {
        QuoteLineItem testQli;
        String packageId;
        String packageVersion;
        DQDataHelper.ProductData pData = new DQDataHelper.ProductData(packageId, packageVersion, testQli);
        System.assertEquals(0, pData.discount, 'discount should be 0 if argument is null');
        System.assertEquals(0, pData.quantity, 'quantity should be 0 if argument is null');
        System.assertEquals(null, pData.hasPromotion, 'hasPromotion should be null if argument is null');
        System.assertEquals('', pData.goaGroup, 'goaGroup should be empty string if argument is null');
        System.assertEquals('', pData.productGroupKey, 'productGroupKey should be empty string if argument is null');

        DQ_Deal_Qualification_Discounts__c testDQDiscount;
        pData = new DQDataHelper.ProductData(testDQDiscount);
        System.assertEquals(0, pData.discount, 'discount should be 0 if argument is null');
        System.assertEquals(0, pData.quantity, 'quantity should be 0 if argument is null');
        System.assertEquals(null, pData.hasPromotion, 'hasPromotion should be null if argument is null');
        System.assertEquals('', pData.goaGroup, 'goaGroup should be empty string if argument is null');
        System.assertEquals('', pData.productGroupKey, 'productGroupKey should be empty string if argument is null');

        DQ_Deal_Qualification_Discount_History__c testDQHistory;
        pData = new DQDataHelper.ProductData(testDQHistory);
        System.assertEquals(0, pData.discount, 'discount should be 0 if argument is null');
        System.assertEquals(0, pData.quantity, 'quantity should be 0 if argument is null');
        System.assertEquals('', pData.goaGroup, 'goaGroup should be empty string if argument is null');
        System.assertEquals('', pData.productGroupKey, 'productGroupKey should be empty string if argument is null');
    }

    @IsTest
    static void testProductDataQLIInit() {

        final String testPackageId = '1952';
        final String testPackageVersion = '1';

        QuoteLineItem testQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    QuoteLineItem.Quantity => 100,
                    QuoteLineItem.Discount => 10,
                    QuoteLineItem.Product2Id => ValueProviderBuilder.provideDummyId(Product2.SObjectType),
                    QuoteLineItem.Promotion__c => ValueProviderBuilder.provideDummyId(Promotion__c.SObjectType)
                }
            )
            .build()
            .getRecord();

        testQli.Quote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
                }
            )
            .build()
            .getRecord();

        final String goaGroupName = 'Device_Contract';

        testQli.Product2 = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setField(Product2.GOA_Group_V3__c, '{"regular":"' + goaGroupName + '","contracted":"' + goaGroupName + '"}')
            .build()
            .getRecord();

        DQDataHelper.ProductData pData = new DQDataHelper.ProductData(testPackageId, testPackageVersion, testQli);

        System.assertEquals(testQli.Discount, pData.discount, 'ProductData.discount should match the Discount on QuoteLineItem');
        System.assertEquals(true, pData.hasPromotion, 'ProductData.discount should be true if Promotion__c is not null on QuoteLineItem');
        System.assertEquals(testQli.Quantity, pData.quantity, 'ProductData.quantity should match the Quantity on QuoteLineItem');
        System.assertEquals(goaGroupName, pData.goaGroup, 'ProductData.goaGroup should match the value for regular type on Product2.GOA_Group_V3__c');

        String expectedProductGroupKey = goaGroupName + '-' + testPackageId + '-' + testPackageVersion + '-' + testQli.Product2Id;
        System.assertEquals(
            expectedProductGroupKey,
            pData.productGroupKey,
            'ProductData.productGroupKey should contain goaGroup and productId separated with "-". ' +
                'Expected: "' + expectedProductGroupKey + '", Actual: "' + pData.productGroupKey + '"'
        );
    }

    @isTest
    static void testProductDataQLIInitPOCtoPaid() {

        Triggers.switchOff();

        Account testAccPoc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc',
                    Account.Billing_Id__c => '43243423',
                    Account.Offer_Type__c => AccountHelper.OFFER_TYPE_POC
                }
            )
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => testAccPoc.Id
            })
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.OpportunityId => testOpp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_SALES,
                Quote.CurrencyIsoCode => 'USD'
            })
            .create()
            .getRecord();

        QuoteLineItem testQliPocToPaid = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    QuoteLineItem.Discount_type__c => QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE,
                    QuoteLineItem.Discount => 42,
                    QuoteLineItem.Quantity => 50,
                    QuoteLineItem.NewQuantity__c => 50,
                    QuoteLineItem.Product2Id => ValueProviderBuilder.provideDummyId(Product2.SObjectType)
                }
            )
            .build()
            .getRecord();

        Triggers.switchOn();

        DQDataHelper.ProductData pData = new DQDataHelper.ProductData(null, null, testQliPocToPaid);

        System.assertEquals(
            testQliPocToPaid.NewQuantity__c,
            pData.quantity,
            'ProductData.quantity should match the NewQuantity__c on QuoteLineItem for POC-to-Paid scenario'
        );
    }

    @IsTest
    static void testProductDataDQDiscountInit() {

        DQ_Deal_Qualification_Discounts__c testDqDiscount =
            (DQ_Deal_Qualification_Discounts__c) new SObjectBuilder(DQ_Deal_Qualification_Discounts__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        DQ_Deal_Qualification_Discounts__c.Quantity__c => 100,
                        DQ_Deal_Qualification_Discounts__c.Discount__c => 10,
                        DQ_Deal_Qualification_Discounts__c.Promo_Code__c =>  ValueProviderBuilder.provideDummyId(Promotion__c.SObjectType),
                        DQ_Deal_Qualification_Discounts__c.Product_Category__c => 'Device_Contract',
                        DQ_Deal_Qualification_Discounts__c.Product__c => ValueProviderBuilder.provideDummyId(Product2.SObjectType),
                        DQ_Deal_Qualification_Discounts__c.PackageName__c => 'test_package',
                        DQ_Deal_Qualification_Discounts__c.OriginalPackageId__c => '1952',
                        DQ_Deal_Qualification_Discounts__c.OriginalPackageVersion__c => '1'
                    }
                )
                .build()
                .getRecord();

        DQDataHelper.ProductData pData = new DQDataHelper.ProductData(testDqDiscount);

        System.assertEquals(testDqDiscount.Discount__c, pData.discount, 'ProductData.discount should match the Discount__c on DQ_Deal_Qualification_Discounts__c');
        System.assertEquals(true, pData.hasPromotion, 'ProductData.hasPromotion should be true if Promotion__c is not null on DQ_Deal_Qualification_Discounts__c');
        System.assertEquals(testDqDiscount.Quantity__c, pData.quantity, 'ProductData.quantity should match the Quantity__c on DQ_Deal_Qualification_Discounts__c');
        System.assertEquals(testDqDiscount.Product_Category__c, pData.goaGroup, 'ProductData.goaGroup should match the Product_Category__c on DQ_Deal_Qualification_Discounts__c');

        String expectedProductGroupKey = testDqDiscount.Product_Category__c + '-' +
            testDqDiscount.OriginalPackageId__c + '-' +
            testDqDiscount.OriginalPackageVersion__c + '-' +
            testDqDiscount.Product__c;

        System.assertEquals(
            expectedProductGroupKey,
            pData.productGroupKey,
            'ProductData.productGroupKey should contain goaGroup and productId separated with "-". ' +
                'Expected: "' + expectedProductGroupKey + '", Actual: "' + pData.productGroupKey + '"'
        );
    }

    @IsTest
    static void testProductDataDQHistoryInit() {

        DQ_Deal_Qualification_Discount_History__c testDqDiscountHistory =
            (DQ_Deal_Qualification_Discount_History__c) new SObjectBuilder(DQ_Deal_Qualification_Discount_History__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        DQ_Deal_Qualification_Discount_History__c.Quantity__c => 100,
                        DQ_Deal_Qualification_Discount_History__c.Discount__c => 10,
                        DQ_Deal_Qualification_Discount_History__c.Product_Category__c => 'Device_Contract',
                        DQ_Deal_Qualification_Discount_History__c.Product__c => ValueProviderBuilder.provideDummyId(Product2.SObjectType),
                        DQ_Deal_Qualification_Discount_History__c.PackageId__c => '18',
                        DQ_Deal_Qualification_Discount_History__c.PackageVersion__c => '2'
                    }
                )
                .build()
                .getRecord();

        DQDataHelper.ProductData pData = new DQDataHelper.ProductData(testDqDiscountHistory);

        System.assertEquals(testDqDiscountHistory.Discount__c, pData.discount, 'ProductData.discount should match the Discount__c on DQ_Deal_Qualification_Discount_History__c');
        System.assertEquals(testDqDiscountHistory.Quantity__c, pData.quantity, 'ProductData.quantity should match the Quantity__c on DQ_Deal_Qualification_Discount_History__c');
        System.assertEquals(testDqDiscountHistory.Product_Category__c, pData.goaGroup, 'ProductData.goaGroup should match the Product_Category__c on DQ_Deal_Qualification_Discount_History__c');

        String expectedProductGroupKey = testDqDiscountHistory.Product_Category__c + '-' +
            testDqDiscountHistory.PackageId__c + '-' +
            testDqDiscountHistory.PackageVersion__c + '-' +
            testDqDiscountHistory.Product__c;

        System.assertEquals(
            expectedProductGroupKey,
            pData.productGroupKey,
            'ProductData.productGroupKey should contain goaGroup and productId separated with "-". ' +
                'Expected: "' + expectedProductGroupKey + '", Actual: "' + pData.productGroupKey + '"'
        );
    }

    @IsTest
    static void testGetDiscountFromQli() {
        String packageId;
        String packageVersion;
        QuoteLineItem testQli;
        DQDataHelper.ProductData pData = new DQDataHelper.ProductData(packageId, packageVersion, testQli);
        System.assertEquals(0, pData.getDiscount(null), 'method getDiscount should return 0 if passed argument is null');
        System.assertEquals(
            0,
            pData.getDiscount(new QuoteLineItem()),
            'method getDiscount should return 0 if QuoteLineItem has no specified discount'
        );
        System.assertEquals(
            5,
            pData.getDiscount(new QuoteLineItem(Discount = 5)),
            'method getDiscount should return value from Discount field'
        );
    }

    @IsTest
    static void testGetCategoryHistoryDiscount() {
        String testGoaGroup = 'testGoaGroup';
        DQDataHelper.DealQualificationData dqData = new DQDataHelper.DealQualificationData();

        System.assertEquals(
            0,
            dqData.getCategoryHistoryData(null, null),
            'method should return 0 if passed arguments is null'
        );

        System.assertEquals(
            0,
            dqData.getCategoryHistoryData(testGoaGroup, DQDataHelper.PRODUCT_DATA_DISCOUNT),
            'method should return 0 if map doesn\'t contain specified group'
        );


        DQDataHelper.ProductData productData = new DQDataHelper.ProductData('18', '2', new QuoteLineItem(Discount = 50));
        Map<String, DQDataHelper.ProductData> goaGroupToProductDataMap = new Map<String, DQDataHelper.ProductData>{
            'testGoaGroup-null-null-null' => productData
        };
        dqData.goaCategoryToProductDataHistoryMap = new Map<String, Map<String, DQDataHelper.ProductData>>{
            testGoaGroup => goaGroupToProductDataMap
        };
        System.assertEquals(
            50,
            dqData.getCategoryHistoryData(testGoaGroup, DQDataHelper.PRODUCT_DATA_DISCOUNT),
            'method should return category discount for specified goaGroup'
        );
    }

    @IsTest
    static void testGetPackageCategoryHistoryDiscount() {
        String testGoaGroup = 'testGoaGroup';
        DQDataHelper.DealQualificationData dqData = new DQDataHelper.DealQualificationData();

        System.assertEquals(
            0,
            dqData.getPackageCategoryHistoryData(null, null, null),
            'method should return 0 if passed arguments is null'
        );


        final String testPackageId = '18';
        final String testPackageVersion = '2';

        QuoteLineItem testQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    QuoteLineItem.Quantity => 100,
                    QuoteLineItem.Discount => 10,
                    QuoteLineItem.Product2Id => ValueProviderBuilder.provideDummyId(Product2.SObjectType)
                }
            )
            .build()
            .getRecord();

        testQli.Quote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.RecordTypeId => QuoteHelper.RT_ID_CC
                }
            )
            .build()
            .getRecord();

        testQli.Product2 = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setField(Product2.GOA_Group_V2__c, testGoaGroup)
            .build()
            .getRecord();


        DQDataHelper.ProductData testProductData = new DQDataHelper.ProductData(testPackageId, testPackageVersion, testQli);
        System.assertEquals(
            0,
            dqData.getPackageCategoryHistoryData(testGoaGroup, testProductData, DQDataHelper.PRODUCT_DATA_DISCOUNT),
            'method should return 0 if map doesn\'t contains specified group'
        );


        Map<String, DQDataHelper.ProductData> goaGroupToProductDataMap = new Map<String, DQDataHelper.ProductData>{
            'testGoaGroup-18-2-null' => testProductData
        };
        dqData.goaCategoryToProductDataHistoryMap = new Map<String, Map<String, DQDataHelper.ProductData>>{
            testGoaGroup => goaGroupToProductDataMap
        };
        System.assertEquals(
            10,
            dqData.getPackageCategoryHistoryData(testGoaGroup, testProductData, DQDataHelper.PRODUCT_DATA_DISCOUNT),
            'method should return package category discount for specified goaGroup'
        );
    }

    @IsTest
    static void testGetCategoryProductHistoryDiscount() {
        String testGoaGroup = 'testGoaGroup';
        DQDataHelper.DealQualificationData dqData = new DQDataHelper.DealQualificationData();

        System.assertEquals(
            0,
            dqData.getCategoryProductHistoryData(null, null, null),
            'method should return 0 if passed arguments is null'
        );


        QuoteLineItem testQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    QuoteLineItem.Quantity => 100,
                    QuoteLineItem.Discount => 15,
                    QuoteLineItem.Product2Id => ValueProviderBuilder.provideDummyId(Product2.SObjectType)
                }
            )
            .build()
            .getRecord();

        testQli.Quote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.RecordTypeId => QuoteHelper.RT_ID_CC
                }
            )
            .build()
            .getRecord();

        testQli.Product2 = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setField(Product2.GOA_Group_V2__c, testGoaGroup)
            .build()
            .getRecord();


        DQDataHelper.ProductData testProductData = new DQDataHelper.ProductData(null, null, testQli);
        System.assertEquals(
            0,
            dqData.getCategoryProductHistoryData(testGoaGroup, testProductData, DQDataHelper.PRODUCT_DATA_DISCOUNT),
            'method should return 0 if map doesn\'t contains specified group'
        );

        String kategoryProductDiscountKey = 'testGoaGroup-null-null-' + testQli.Product2Id;
        Map<String, DQDataHelper.ProductData> goaGroupToProductDataMap = new Map<String, DQDataHelper.ProductData>{
            kategoryProductDiscountKey => testProductData
        };
        dqData.goaCategoryToProductDataHistoryMap = new Map<String, Map<String, DQDataHelper.ProductData>>{
            testGoaGroup => goaGroupToProductDataMap
        };
        System.assertEquals(
            15,
            dqData.getCategoryProductHistoryData(testGoaGroup, testProductData, DQDataHelper.PRODUCT_DATA_DISCOUNT),
            'method should return category product discount for specified goaGroup'
        );
    }

    @IsTest
    static void testGetApprovalTypeSteps() {

        System.assertEquals(
            new List<DQ_Approval_Type_Step__c>(),
            DQDataHelper.getApprovalTypeSteps(null, null),
            'method should return empty list if passed args are empty'
        );


        DQ_Approval_Step__c dqApprovalStep = (DQ_Approval_Step__c) new SObjectBuilder(DQ_Approval_Step__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Approval_Step__c.Name => 'Level 1',
                    DQ_Approval_Step__c.Step_Order__c => 1
                }
            )
            .create()
            .getRecord();

        DQ_Approval_Type__c dqApprovalType = (DQ_Approval_Type__c) new SObjectBuilder(DQ_Approval_Type__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Approval_Type__c.Approval_Type__c => DQApprovalTypeHelper.APPROVAL_TYPE_DISCOUNT,
                    DQ_Approval_Type__c.Product_Category__c => 'Device_Contract'
                }
            )
            .create()
            .getRecord();

        List<DQ_Approval_Type_Step__c> dqApprovalTypeSteps =
            (List<DQ_Approval_Type_Step__c>) new SObjectBuilder(DQ_Approval_Type_Step__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        DQ_Approval_Type_Step__c.DQ_Approval_Type__c => dqApprovalType.Id,
                        DQ_Approval_Type_Step__c.DQ_Approval_Step__c => dqApprovalStep.Id,
                        DQ_Approval_Type_Step__c.Region__c => ValueProviderBuilder.provideList(new List<String>{
                            'MNL;AU;EU;UK;CA;US',
                            'EU;Default'
                        }),
                        DQ_Approval_Type_Step__c.Segment__c => 'SOHO;Small Business;Mid Market;Majors;Enterprise;Default',
                        DQ_Approval_Type_Step__c.Deal_Type__c => 'Direct;Indirect',
                        DQ_Approval_Type_Step__c.Brand__c => 'RingCentral;RingCentral Canada;RingCentral UK;RingCentral EU;Default',
                        DQ_Approval_Type_Step__c.Sub_Region__c => 'North;South;Central;East;West;All;Default'

                    }
                )
                .quantity(2)
                .create()
                .getRecords();

        DQ_Approval_Type_Step__c approvalTypeStepUS;
        DQ_Approval_Type_Step__c approvalTypeStepDefault;
        for (DQ_Approval_Type_Step__c item : dqApprovalTypeSteps) {
            if (item.Region__c.contains('US')) {
                approvalTypeStepUS = item;
            }
            if (item.Region__c.contains('Default')) {
                approvalTypeStepDefault = item;
            }
        }

        Opportunity testOpportunity = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity',
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                    Opportunity.Tier_Name__c => QuoteHelper.NGBS_OFFICE_PRODUCT
                }
            )
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'Test Quote',
                    Quote.OpportunityId => testOpportunity.Id,
                    Quote.Initial_Term_months__c => '12',
                    Quote.Term_months__c => '24',
                    Quote.Special_Terms__c => '2 Free weeks of service',
                    Quote.OverallDiscretion__c => 150,
                    Quote.Total_MRR_New__c => 500,
                    Quote.ServiceName__c => 'Office'
                }
            )
            .build()
            .getRecord();

        QuoteHelper.QuotesStorage quotesStorage = new QuoteHelper.QuotesStorage(new List<Quote>{testQuote});
        DQDataHelper.DealQualificationData dqData = new DQDataHelper.DealQualificationData(quotesStorage, testOpportunity, null, null);
        dqData.opportunityData.opportunityOwnerRegion = 'US';
        dqData.opportunityData.opportunitySegment = 'Small Business';
        dqData.opportunityData.dealType = 'Direct';
        dqData.opportunityData.opportunityBrand = 'RingCentral';

        List<DQ_Approval_Type_Step__c> result = DQDataHelper.getApprovalTypeSteps(new Set<Id>{dqApprovalType.Id}, dqData);
        System.assertEquals(1, result.size(), 'method should return 1 record');
        DQ_Approval_Type_Step__c approvalTypeStep = result.get(0);
        System.assertEquals(approvalTypeStepUS.Id, approvalTypeStep.Id, 'found record should contain "US" in Region__c field');

        dqData.opportunityData.opportunityOwnerRegion = 'Default';
        dqData.opportunityData.opportunitySegment = 'Small Business';
        dqData.opportunityData.dealType = 'Direct';
        dqData.opportunityData.opportunityBrand = 'RingCentral';
        dqData.opportunityData.subRegion = 'North';

        result = DQDataHelper.getApprovalTypeSteps(new Set<Id>{dqApprovalType.Id}, dqData);
        System.assertEquals(1, result.size(), 'method should return 1 record');
        approvalTypeStep = result.get(0);
        System.assertEquals(approvalTypeStepDefault.Id, approvalTypeStep.Id, 'found record should contain "Default" in Region__c field');
    }

    @IsTest
    static void testGetApprovalTypeStepApprovers() {

        System.assertEquals(
            new List<DQ_Approval_Step_Approver__c>(),
            DQDataHelper.getApprovalStepApprovers(null, null),
            'method should return empty list if passed args are empty'
        );


        DQ_Approval_Step__c dqApprovalStep = (DQ_Approval_Step__c) new SObjectBuilder(DQ_Approval_Step__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Approval_Step__c.Name => 'Level 1',
                    DQ_Approval_Step__c.Step_Order__c => 1
                }
            )
            .create()
            .getRecord();

        List<DQ_Approval_Step_Approver__c> dqApprovalTypeStepApprovers =
            (List<DQ_Approval_Step_Approver__c>) new SObjectBuilder(DQ_Approval_Step_Approver__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        // DQ_Approval_Step_Approver__c.DQ_Approval_Type__c => dqApprovalType.Id,
                        DQ_Approval_Step_Approver__c.DQ_Approval_Step__c => dqApprovalStep.Id,
                        DQ_Approval_Step_Approver__c.Region__c => ValueProviderBuilder.provideList(new List<String>{
                            'MNL;AU;EU;UK;CA;US',
                            'EU;Default'
                        }),
                        DQ_Approval_Step_Approver__c.Segment__c => 'SOHO;Small Business;Mid Market;Majors;Enterprise;Default',
                        DQ_Approval_Step_Approver__c.Deal_Type__c => 'Direct;Indirect',
                        DQ_Approval_Step_Approver__c.Brand__c => 'RingCentral;RingCentral Canada;RingCentral UK;RingCentral EU;Default',
                        DQ_Approval_Step_Approver__c.Sub_Region__c => 'North;South;Central;East;West;All;Default'

                    }
                )
                .quantity(2)
                .create()
                .getRecords();

        DQ_Approval_Step_Approver__c approvalTypeStepApproverUS;
        DQ_Approval_Step_Approver__c approvalTypeStepApproverDefault;
        for (DQ_Approval_Step_Approver__c item : dqApprovalTypeStepApprovers) {
            if (item.Region__c.contains('US')) {
                approvalTypeStepApproverUS = item;
            }
            if (item.Region__c.contains('Default')) {
                approvalTypeStepApproverDefault = item;
            }
        }

        Opportunity testOpportunity = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity',
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                    Opportunity.Tier_Name__c => QuoteHelper.NGBS_OFFICE_PRODUCT
                }
            )
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'Test Quote',
                    Quote.OpportunityId => testOpportunity.Id,
                    Quote.Initial_Term_months__c => '12',
                    Quote.Term_months__c => '24',
                    Quote.Special_Terms__c => '2 Free weeks of service',
                    Quote.OverallDiscretion__c => 150,
                    Quote.Total_MRR_New__c => 500,
                    Quote.ServiceName__c => 'Office'
                }
            )
            .build()
            .getRecord();

        QuoteHelper.QuotesStorage quotesStorage = new QuoteHelper.QuotesStorage(new List<Quote>{testQuote});
        DQDataHelper.DealQualificationData dqData = new DQDataHelper.DealQualificationData(quotesStorage, testOpportunity, null, null);
        dqData.opportunityData.opportunityOwnerRegion = 'US';
        dqData.opportunityData.opportunitySegment = 'Small Business';
        dqData.opportunityData.dealType = 'Direct';
        dqData.opportunityData.opportunityBrand = 'RingCentral';

        List<DQ_Approval_Step_Approver__c> result = DQDataHelper.getApprovalStepApprovers(new Set<Id>{dqApprovalStep.Id}, dqData);
        System.assertEquals(1, result.size(), 'method should return 1 record');
        DQ_Approval_Step_Approver__c approvalTypeStepApprover = result.get(0);
        System.assertEquals(approvalTypeStepApproverUS.Id, approvalTypeStepApprover.Id, 'found record should contain "US" in Region__c field');

        dqData.opportunityData.opportunityOwnerRegion = 'Default';
        dqData.opportunityData.opportunitySegment = 'Small Business';
        dqData.opportunityData.dealType = 'Direct';
        dqData.opportunityData.opportunityBrand = 'RingCentral';
        dqData.opportunityData.subRegion = 'North';

        result = DQDataHelper.getApprovalStepApprovers(new Set<Id>{dqApprovalStep.Id}, dqData);
        System.assertEquals(1, result.size(), 'method should return 1 record');
        approvalTypeStepApprover = result.get(0);
        System.assertEquals(approvalTypeStepApproverDefault.Id, approvalTypeStepApprover.Id, 'found record should contain "Default" in Region__c field');
    }

    @IsTest
    static void testDqDataInitForQuote() {

        String quotePackageInfo = NGBSTestDataGenerator.generateQuotePackageInfo(new Map<String, Object>{
            'Id' => '18',
            'Version' => '2'
        });

        Opportunity testOpportunity = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity',
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                    Opportunity.Tier_Name__c => QuoteHelper.NGBS_OFFICE_PRODUCT
                }
            )
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'Test Quote',
                    Quote.OpportunityId => testOpportunity.Id,
                    Quote.Initial_Term_months__c => '12',
                    Quote.Term_months__c => '24',
                    Quote.Special_Terms__c => '2 Free weeks of service',
                    Quote.FreeShippingTerms__c => QuoteHelper.FREESHIPPING,
                    Quote.Package_Info__c => quotePackageInfo,
                    Quote.OverallDiscretion__c => 150,
                    Quote.Total_MRR_New__c => 500,
                    Quote.ServiceName__c => 'Office'
                }
            )
            .build()
            .getRecord();

        User oppOwner = (User) new SObjectBuilder(User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.Region__c => 'US',
                    User.Sub_Region__c => 'North',
                    User.SegmentPicklist__c => 'Enterprise'
                }
            )
            .build()
            .getRecord();

        testOpportunity.Owner = oppOwner;
        testQuote.Opportunity = testOpportunity;

        QuoteHelper.QuotesStorage quotesStorage = new QuoteHelper.QuotesStorage(new List<Quote>{testQuote});
        DQDataHelper.DealQualificationData dqData = new DQDataHelper.DealQualificationData(quotesStorage, testOpportunity, null, null);

        System.assertEquals(testQuote.OpportunityId, dqData.opportunityData.oppId, 'OpportunityId from Quote should be copied into oppId field');
        System.assertEquals(
            testQuote.Initial_Term_months__c,
            String.valueOf(dqData.serviceNameToQuoteDataMap.get(testQuote.ServiceName__c).initialTerm),
            'Initial_Term_months__c from Quote should be copied into dqInitialTerm field'
        );
        System.assertEquals(
            testQuote.Term_months__c,
            String.valueOf(dqData.serviceNameToQuoteDataMap.get(testQuote.ServiceName__c).renewalTerm),
            'Term_months__c from Quote should be copied into dqRenewalTerm field'
        );
        System.assertEquals(
            testQuote.Special_Terms__c,
            dqData.serviceNameToQuoteDataMap.get(testQuote.ServiceName__c).specialTerms,
            'Special_Terms__c from Quote should be copied into dqSpecialTerms field'
        );
        System.assertEquals(
            testQuote.FreeShippingTerms__c,
            dqData.serviceNameToQuoteDataMap.get(testQuote.ServiceName__c).freeShippingTermsOption,
            'FreeShippingTerms__c from Quote should be copied into dqFreeShippingTermsOptions field'
        );
        System.assertEquals(
            oppOwner.Region__c,
            dqData.opportunityData.opportunityOwnerRegion,
            'Region__c from Opportunity Owner should be copied into opportunityOwnerRegion field'
        );
        System.assertEquals(
            'Direct',
            dqData.opportunityData.dealType,
            'dealType should have value "Direct" for non VAR opportunities'
        );
        System.assertEquals(
            testOpportunity.Brand_Name__c,
            dqData.opportunityData.opportunityBrand,
            'Brand_Name__c from Opportunity should be copied into opportunityBrand field'
        );
        System.assertEquals(
            testOpportunity.Tier_Name__c,
            dqData.opportunityData.oppTierName,
            'Tier_Name__c from Opportunity should be copied into oppTierName field'
        );
        System.assertEquals(
            oppOwner.Sub_Region__c,
            dqData.opportunityData.subRegion,
            'Sub_Region__c from Opportunity Owner should be copied into subRegion field'
        );
        System.assertEquals(
            oppOwner.SegmentPicklist__c,
            dqData.opportunityData.opportunitySegment,
            'SegmentPicklist__c from Opportunity Owner should be copied into opportunitySegment field'
        );
        System.assertEquals(
            testQuote.OverallDiscretion__c,
            dqData.serviceNameToQuoteDataMap.get(testQuote.ServiceName__c).discretion,
            'OverallDiscretion__c from Quote should be copied into overallDiscountRecurring field'
        );
    }

    @IsTest
    static void testShippingMethodRequiresApprove() {

        String quotePackageInfo = NGBSTestDataGenerator.generateQuotePackageInfo(new Map<String, Object>{
            'Id' => '18',
            'Version' => '2'
        });

        Opportunity testOpportunity = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity',
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                    Opportunity.Tier_Name__c => QuoteHelper.NGBS_OFFICE_PRODUCT
                }
            )
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'Test Quote',
                    Quote.OpportunityId => testOpportunity.Id,
                    Quote.Initial_Term_months__c => '12',
                    Quote.Term_months__c => '24',
                    Quote.Special_Terms__c => '2 Free weeks of service',
                    Quote.FreeShippingTerms__c => QuoteHelper.FREESHIPPING,
                    Quote.Package_Info__c => quotePackageInfo,
                    Quote.OverallDiscretion__c => 150,
                    Quote.Total_MRR_New__c => 500,
                    Quote.ServiceName__c => 'Office'
                }
            )
            .build()
            .getRecord();

        CustomAddress__c testCustomAddress = (CustomAddress__c) new SObjectBuilder(CustomAddress__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    CustomAddress__c.Name => 'Test Custom Address',
                    CustomAddress__c.AddressLine__c => 'Test Address Line',
                    CustomAddress__c.City__c => 'New York',
                    CustomAddress__c.Country__c => 'United States',
                    CustomAddress__c.CurrencyIsoCode => 'USD',
                    CustomAddress__c.PostalCode__c => '123456'
                }
            )
            .create()
            .getRecord();

        new SObjectBuilder(CustomAddressAssignments__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    CustomAddressAssignments__c.CustomAddress__c => testCustomAddress.Id,
                    CustomAddressAssignments__c.AttentionTo__c => 'Test',
                    CustomAddressAssignments__c.CurrencyIsoCode => 'USD',
                    CustomAddressAssignments__c.Type__c => '2 Day'
                }
            )
            .create();

        User oppOwner = (User) new SObjectBuilder(User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.Region__c => 'US',
                    User.Sub_Region__c => 'North',
                    User.SegmentPicklist__c => 'Enterprise'
                }
            )
            .build()
            .getRecord();

        testOpportunity.Owner = oppOwner;
        testQuote.Opportunity = testOpportunity;

        QuoteHelper.QuotesStorage quotesStorage = new QuoteHelper.QuotesStorage(new List<Quote>{testQuote});
        DQDataHelper.DealQualificationData dqDataFalse = new DQDataHelper.DealQualificationData(quotesStorage, testOpportunity, null, null);

        System.assertEquals(false, dqDataFalse.serviceNameToQuoteDataMap.get(testQuote.ServiceName__c).shippingMethodRequiresApprove, 'shippingMethodRequiresApprove field must be false if user have Shipping_Tab_New_Business__c disabled in Feature Toggle');

        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Feature_Toggle__c.Shipping_Tab_New_Business__c => true
            })
            .create();

        QuoteHelper.QuotesStorage updatedQuotesStorage = new QuoteHelper.QuotesStorage(new List<Quote>{testQuote});
        DQDataHelper.DealQualificationData dqDataTrue = new DQDataHelper.DealQualificationData(updatedQuotesStorage, testOpportunity, null, null);

        System.assertEquals(true, dqDataTrue.serviceNameToQuoteDataMap.get(testQuote.ServiceName__c).shippingMethodRequiresApprove, 'shippingMethodRequiresApprove field must be true if there\'s matching CustomAddressAssignments__c found');
    }

    @IsTest
    static void testDqDataInitForQuoteWithQuoteLineItems() {

        final String deviceContractGoaGroup = 'Device_Contract';
        final String rcOfficeGoaGroup = 'GOA_RC_Office';
        final String testPackageId = '1952';
        final String testPackageVersion = '1';
        final String ccGoaGroup = 'All Contact Center';

        List<Product2> testProducts = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Product2.Name => ValueProviderBuilder.provideUniqueString('test product'),
                    Product2.GOA_Group_V3__c => ValueProviderBuilder.provideList(new List<String>{
                        '{"regular":"' + deviceContractGoaGroup + '","contracted":"' + deviceContractGoaGroup + '"}',
                        '{"regular":"' + rcOfficeGoaGroup + '","contracted":"' + rcOfficeGoaGroup + '"}'
                    })
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        String quotePackageInfo = NGBSTestDataGenerator.generateQuotePackageInfo(new Map<String, Object>{
            'Id' => testPackageId,
            'Version' => testPackageVersion
        });

        Triggers.switchOff();
        User oppOwner = (User) new SObjectBuilder(User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.Username => UserHelper.getUniqueUserName(),
                    User.LastName => ValueProviderBuilder.provideUniqueString('LastName'),
                    User.ProfileId => ProfileHelper.PROFILE_ID_SYSADMIN,
                    User.Email => ValueProviderBuilder.provideUniqueEmail(),
                    User.Alias => StringHelper.getRandomString(8),
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.LanguageLocaleKey => 'en_US',
                    User.Region__c => 'US',
                    User.Sub_Region__c => 'All',
                    User.SegmentPicklist__c => 'Enterprise'
                }
            )
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                Opportunity.Name => 'Test Opportunity',
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.RecordType.Name => 'New Sales Opportunity',
                Opportunity.OwnerId => oppOwner.Id
            })
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                    Quote.Package_Info__c=> quotePackageInfo,
                    Quote.Name => 'Test Quote',
                    Quote.OpportunityId => opp.Id,
                    Quote.AverageDiscount__c => 15,
                    Quote.Initial_Term_months__c => '12',
                    Quote.Term_months__c => '12',
                    Quote.Special_Terms__c => QuoteHelper.FREE_MONTH_6,
                    Quote.OverallDiscretion__c => 32,
                    Quote.Total_MRR_New__c => 30,
                    Quote.ServiceName__c => 'Office',
                    Quote.Pricebook2Id => Test.getStandardPricebookId()
                }
            )
            .create()
            .getRecord();

        Triggers.switchOn();
        List<PricebookEntry> pbes = new List<PricebookEntry>();
        for (Product2 product : testProducts) {
            pbes.addAll(
                (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.SObjectType)
                    .setFields(new Map<SObjectField, Object>{
                        PricebookEntry.Pricebook2Id => testQuote.Pricebook2Id,
                        PricebookEntry.Product2Id => product.Id,
                        PricebookEntry.IsActive => true,
                        PricebookEntry.CurrencyIsoCode => ValueProviderBuilder.provideList(new List<String>{'USD'}),
                        PricebookEntry.UnitPrice => 0,
                        PricebookEntry.UseStandardPrice => false
                    })
                    .create()
                    .quantity(2)
                    .getRecords()
            );
        }

        List<QuoteLineItem> testQlis = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    QuoteLineItem.Quantity => ValueProviderBuilder.provideList(new List<Decimal>{
                        45, 100
                    }),
                    QuoteLineItem.Discount => ValueProviderBuilder.provideList(new List<Decimal>{
                        10, 20
                    }),
                    QuoteLineItem.Product2Id => ValueProviderBuilder.provideList(new List<Id>{
                        testProducts.get(0).Id, testProducts.get(1).Id
                    }),
                    QuoteLineItem.UnitPrice => 30,
                    QuoteLineItem.QuoteId => testQuote.Id,
                    QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideList(new List<Id>{
                        pbes.get(0).Id, pbes.get(1).Id
                    })
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        Test.startTest();
        List<Quote> quoteList = new QuoteSelector()
            .selectQuoteForDqGoa(testQuote.Id)
            .executeQuery();
        QuoteHelper.QuotesStorage quotesStorage = new QuoteHelper.QuotesStorage(quoteList);
        DQDataHelper.DealQualificationData dqData = new DQDataHelper.DealQualificationData(quotesStorage, opp, null, null);
        Map<String, Map<String, DQDataHelper.ProductData>> goaCategoryToProductDataMap = dqData.buildGoaCategoryToProductDataMap(dqData.serviceNameToQuoteDataMap);
        Test.stopTest();

        System.assertEquals(15, dqData.serviceNameToQuoteDataMap.get(testQuote.ServiceName__c).averageDiscount, 'DealQualificationData should contain info about overall discount');
        System.assert(!goaCategoryToProductDataMap.isEmpty(), 'goaCategoryToProductDataMap should not be empty');
        System.assert(
            goaCategoryToProductDataMap.containsKey(deviceContractGoaGroup),
            'goaCategoryToProductDataMap should contain all goa groups for all qlis with discounts'
        );
        System.assert(
            goaCategoryToProductDataMap.containsKey(rcOfficeGoaGroup),
            'goaCategoryToProductDataMap should contain all goa groups for all qlis with discounts'
        );

        Map<String, DQDataHelper.ProductData> deviceContractDataMap = goaCategoryToProductDataMap.get(deviceContractGoaGroup);
        String deviceContractProductKey = deviceContractGoaGroup + '-' +
            testPackageId + '-' +
            testPackageVersion + '-' +
            testQlis.get(0).Product2Id;

        System.assert(
            deviceContractDataMap.containsKey(deviceContractProductKey),
            'a map for a specific goa group must contain information about each discounted product'
        );
        DQDataHelper.ProductData deviceContractProductData = deviceContractDataMap.get(deviceContractProductKey);
        System.assertEquals(
            testQlis.get(0).Discount,
            deviceContractProductData.discount,
            'Discount should be copied from associated QuoteLineItem'
        );
        System.assertEquals(
            testQlis.get(0).Quantity,
            deviceContractProductData.quantity,
            'Quantity should be copied from associated QuoteLineItem'
        );

        Map<String, DQDataHelper.ProductData> rcOfficeDataMap = goaCategoryToProductDataMap.get(rcOfficeGoaGroup);
        String rcOfficeProductKey = rcOfficeGoaGroup + '-' +
            testPackageId + '-' +
            testPackageVersion + '-' +
            testQlis.get(1).Product2Id;

        System.assert(
            rcOfficeDataMap.containsKey(rcOfficeProductKey),
            'a map for a specific goa group must contain information about each discounted product'
        );
        DQDataHelper.ProductData rcOfficeProductData = rcOfficeDataMap.get(rcOfficeProductKey);
        System.assertEquals(
            testQlis.get(1).Discount,
            rcOfficeProductData.discount,
            'Discount should be copied from associated QuoteLineItem'
        );
        System.assertEquals(
            testQlis.get(1).Quantity,
            rcOfficeProductData.quantity,
            'Quantity should be copied from associated QuoteLineItem'
        );
    }

    @IsTest
    static void testInitDqHistoryFields() {

        DQ_Deal_Qualification_History__c testDqHistoryRecord =
            (DQ_Deal_Qualification_History__c) new SObjectBuilder(DQ_Deal_Qualification_History__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Deal_Qualification_History__c.Free_Shipping_Terms_Options__c => DQServiceHelper.OVERNIGHT_OPTION,
                    DQ_Deal_Qualification_History__c.Auto_Renewal__c => true
                }
            )
            .build()
            .getRecord();

        DQDataHelper.DealQualificationHistoryData dqDataHistory = new DQDataHelper.DealQualificationHistoryData(testDqHistoryRecord);

        System.assertEquals(
            testDqHistoryRecord.Free_Shipping_Terms_Options__c,
            dqDataHistory.dqFreeShippingTermsOptionsHistory,
            'dqFreeShippingTermsOptionsHistory should be filled with value from the field Free_Shipping_Terms_Options__c ' +
            'from the last DQ_Deal_Qualification_History__c record'
        );
        System.assertEquals(
            testDqHistoryRecord.Auto_Renewal__c,
            dqDataHistory.isAutoRenewalHistory,
            'isAutoRenewalHistory should be filled with value from the field Auto_Renewal__c ' +
            'from the last DQ_Deal_Qualification_History__c record'
        );
    }

    @IsTest
    static void testDqDataInitForDQ() {

        Opportunity testOpportunity = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity',
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                    Opportunity.Tier_Name__c => QuoteHelper.NGBS_OFFICE_PRODUCT
                }
            )
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                    Quote.Name => 'Test Quote',
                    Quote.OpportunityId => testOpportunity.Id,
                    Quote.AverageDiscount__c => 20.5,
                    Quote.Initial_Term_months__c => '12',
                    Quote.Term_months__c => '12',
                    Quote.Special_Terms__c => QuoteHelper.FREE_MONTH_6,
                    Quote.OverallDiscretion__c => 32,
                    Quote.Total_MRR_New__c => 30,
                    Quote.ServiceName__c => 'Office'
                }
            )
            .create()
            .getRecord();

        DQ_Deal_Qualification__c testDQRecord =
            (DQ_Deal_Qualification__c) new SObjectBuilder(DQ_Deal_Qualification__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        DQ_Deal_Qualification__c.Opportunity__c => testOpportunity.Id,
                        DQ_Deal_Qualification__c.Quote__c => testQuote.Id,
                        DQ_Deal_Qualification__c.Free_Shipping_Terms_Options__c => DQServiceHelper.FREE_SHIPPING_OPTION
                    }
                )
                .create()
                .getRecord();

        Test.startTest();
            DQ_Deal_Qualification__c reseletedDqRecord = (DQ_Deal_Qualification__c) new ListOptional(new DealQualificationSelector()
                .selectDQForDQGOA(testDQRecord.Id)
                .executeQuery()
            ).getFirst();
            DQDataHelper.DealQualificationData dqData = new DQDataHelper.DealQualificationData(reseletedDqRecord, null);
        Test.stopTest();

        System.assertEquals(
            testDQRecord.Opportunity__c,
            dqData.opportunityData.oppId,
            'DealQualificationData.oppId should match the Opportunity__c on DQ_Deal_Qualification__c'
        );
        System.assertEquals(
            testQuote.Special_Terms__c,
            dqData.serviceNameToQuoteDataMap.get(testQuote.ServiceName__c).specialTerms,
            'DealQualificationData.dqSpecialTerms should match the Special_Terms__c on DQ_Deal_Qualification__c'
        );
        System.assertEquals(
            testQuote.AverageDiscount__c,
            dqData.serviceNameToQuoteDataMap.get(testQuote.ServiceName__c).averageDiscount,
            'DealQualificationData.overallDiscount should match the Overall_Discount__c on DQ_Deal_Qualification__c'
        );
    }

    @IsTest
    static void testBuildGoaCategoryToProductDataHistoryMap() {

        final String deviceContractGoaGroup = 'Device_Contract';
        final String testPackageId = '18';
        final String testPackageVersion = '2';

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Product2.Name => 'test product',
                    Product2.GOA_Group_V3__c => '{"regular":"' + deviceContractGoaGroup + '","contracted":"' + deviceContractGoaGroup + '"}'
                }
            )
            .create()
            .getRecord();

        List<DQ_Deal_Qualification_History__c> testDqHistoryRecords =
            (List<DQ_Deal_Qualification_History__c>) new SObjectBuilder(DQ_Deal_Qualification_History__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        DQ_Deal_Qualification_History__c.Deal_Qualification__c => ValueProviderBuilder.provideGenericParent(DQ_Deal_Qualification__c.SObjectType),
                        DQ_Deal_Qualification_History__c.Status__c => 'Approved'
                    }
                )
                .create()
                .getRecords();

        DQ_Deal_Qualification_Discount_History__c testDqDiscountHistoryList =
            (DQ_Deal_Qualification_Discount_History__c) new SObjectBuilder(DQ_Deal_Qualification_Discount_History__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        DQ_Deal_Qualification_Discount_History__c.DQ_Deal_Qualification_History__c => ValueProviderBuilder.provideParents(testDqHistoryRecords),
                        DQ_Deal_Qualification_Discount_History__c.Quantity__c => ValueProviderBuilder.provideList(new List<Decimal>{
                            10, 15
                        }),
                        DQ_Deal_Qualification_Discount_History__c.Discount__c => ValueProviderBuilder.provideList(new List<Decimal>{
                            10, 20
                        }),
                        DQ_Deal_Qualification_Discount_History__c.Product_Category__c => deviceContractGoaGroup,
                        DQ_Deal_Qualification_Discount_History__c.Product__c => testProduct.Id,
                        DQ_Deal_Qualification_Discount_History__c.PackageId__c => testPackageId,
                        DQ_Deal_Qualification_Discount_History__c.PackageVersion__c=> testPackageVersion
                    }
                )
                .quantity(2)
                .create()
                .getRecord();

        List<DQ_Deal_Qualification_History__c> reselectedDQHistory = new DealQualificationHistorySelector()
            .selectApprovedDQHistory(testDqHistoryRecords.get(0).Deal_Qualification__c)
            .executeQuery();

        Map<String, Map<String, DQDataHelper.ProductData>> goaCategoryToProductDataHistoryMap = new DQDataHelper.DealQualificationData()
            .buildGoaCategoryToProductDataHistoryMap(reselectedDQHistory.get(0));

        System.assert(
            goaCategoryToProductDataHistoryMap.containsKey(deviceContractGoaGroup),
            'goaCategoryToProductDataHistoryMap should contain all goa groups for all approved discounts'
        );

        Map<String, DQDataHelper.ProductData> deviceContractDataMap = goaCategoryToProductDataHistoryMap.get(deviceContractGoaGroup);

        String deviceContractProductKey = deviceContractGoaGroup + '-' + testPackageId + '-' + testPackageVersion + '-' + testProduct.Id;
        System.assert(
            deviceContractDataMap.containsKey(deviceContractProductKey),
            'a map for a specific goa group must contain information about each discounted product'
        );
        DQDataHelper.ProductData deviceContractProductData = deviceContractDataMap.get(deviceContractProductKey);
        System.assertEquals(
            20,
            deviceContractProductData.discount,
            'product data should contain max approved discount for product'
        );
        System.assertEquals(
            15,
            deviceContractProductData.quantity,
            'product data should contain max approved quantity for product'
        );
    }

    @IsTest
    static void testGetDealQualificationForQuote() {

        final String deviceContractGoaGroup = 'Device_Contract';

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Product2.Name => 'test product',
                    Product2.GOA_Group_V3__c => '{"regular":"' + deviceContractGoaGroup + '","contracted":"' + deviceContractGoaGroup + '"}'
                }
            )
            .create()
            .getRecord();

        User testApprover = (User) new SObjectBuilder(User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.Username => UserHelper.getUniqueUserName(),
                    User.LastName => ValueProviderBuilder.provideUniqueString('LastName'),
                    User.ProfileId => ProfileHelper.PROFILE_ID_SYSADMIN,
                    User.Email => ValueProviderBuilder.provideUniqueEmail(),
                    User.Alias => StringHelper.getRandomString(8),
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.LanguageLocaleKey => 'en_US',
                    User.Region__c => 'US',
                    User.Sub_Region__c => 'All'
                }
            )
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Name => 'Test Opportunity',
                Opportunity.OwnerId => testApprover.Id
            })
            .create()
            .getRecord();

        DQ_Deal_Qualification__c testDqRecord = (DQ_Deal_Qualification__c) new SObjectBuilder(DQ_Deal_Qualification__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                DQ_Deal_Qualification__c.Opportunity__c => testOpp.Id,
                DQ_Deal_Qualification__c.Overall_Discount__c => 70,
                DQ_Deal_Qualification__c.Overall_Discount_Recurring__c => 60
            })
            .create()
            .getRecord();

        List<DQ_Deal_Qualification_History__c> testDqHistoryRecords =
            (List<DQ_Deal_Qualification_History__c>) new SObjectBuilder(DQ_Deal_Qualification_History__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        DQ_Deal_Qualification_History__c.Deal_Qualification__c => testDqRecord.Id,
                        DQ_Deal_Qualification_History__c.Status__c => 'Approved'
                    }
                )
                .create()
                .getRecords();

        DQ_Deal_Qualification_Discount_History__c testDqDiscountHistoryList =
            (DQ_Deal_Qualification_Discount_History__c) new SObjectBuilder(DQ_Deal_Qualification_Discount_History__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        DQ_Deal_Qualification_Discount_History__c.DQ_Deal_Qualification_History__c => ValueProviderBuilder.provideParents(testDqHistoryRecords),
                        DQ_Deal_Qualification_Discount_History__c.Quantity__c => ValueProviderBuilder.provideList(new List<Decimal>{
                            10, 15
                        }),
                        DQ_Deal_Qualification_Discount_History__c.Discount__c => ValueProviderBuilder.provideList(new List<Decimal>{
                            10, 20
                        }),
                        DQ_Deal_Qualification_Discount_History__c.Product_Category__c => deviceContractGoaGroup,
                        DQ_Deal_Qualification_Discount_History__c.Product__c => testProduct.Id
                    }
                )
                .quantity(2)
                .create()
                .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'Test Quote',
                    Quote.OpportunityId => testOpp.Id,
                    Quote.OverallDiscretion__c => 60,
                    Quote.ServiceName__c => 'Office'
                }
            )
            .create()
            .getRecord();

        QuoteLineItem testQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    QuoteLineItem.Quantity => 10,
                    QuoteLineItem.Discount => 55,
                    QuoteLineItem.Product2Id => ValueProviderBuilder.provideDummyId(Product2.SObjectType),
                    QuoteLineItem.UnitPrice => 500,
                    QuoteLineItem.QuoteId => testQuote.Id
                }
            )
            .build()
            .getRecord();

        Test.startTest();
        DQDataHelper.DealQualificationData dqData = DQDataHelper.getDealQualificationDataForQuote(testQuote.Id);
        System.assertEquals(testQuote.OverallDiscretion__c, dqData.serviceNameToQuoteDataMap.get(testQuote.ServiceName__c).discretion, 'DQData should match DQ record');
        Test.stopTest();

    }

    @IsTest
    static void testPackageInfoData() {
        final String testPackageId = '1952';
        final String testPackageVersion = '1';
        final String requiredStatus = 'Required';

        String quotePackageInfo = NGBSTestDataGenerator.generateQuotePackageInfo(new Map<String, Object>{
            'Id' => testPackageId,
            'Version' => testPackageVersion,
            'ProductName' => Product2Helper.PRODUCT_OFFICE
        });

        DQDataHelper.PackageInfoData pInfoData = new DQDataHelper.PackageInfoData(quotePackageInfo);
        System.assertEquals(
            testPackageId,
            pInfoData.packageId,
            '"packageId" field value should be extracted from packageInfo json'
        );
        System.assertEquals(
            testPackageVersion,
            pInfoData.packageVersion,
            '"packageVersion" field value should be extracted from packageInfo json'
        );
        System.assertEquals(
            false,
            pInfoData.isFaxService,
            '"isFaxService" field value should be true if "productName" in packageInfo has "Fax" value'
        );
    }

    @IsTest
    static void testGetCategoryHistoryQuantity() {
        String testGoaGroup = 'testGoaGroup';
        DQDataHelper.DealQualificationData dqData = new DQDataHelper.DealQualificationData();

        System.assertEquals(
            0,
            dqData.getCategoryHistoryData(null, null),
            'method should return 0 if passed arguments is null'
        );

        System.assertEquals(
            0,
            dqData.getCategoryHistoryData(testGoaGroup, DQDataHelper.PRODUCT_DATA_QUANTITY),
            'method should return 0 if map doesn\'t contain specified group'
        );


        DQDataHelper.ProductData productData = new DQDataHelper.ProductData('18', '2', new QuoteLineItem(Quantity = 50));
        Map<String, DQDataHelper.ProductData> goaGroupToProductDataMap = new Map<String, DQDataHelper.ProductData>{
            'testGoaGroup-null-null-null' => productData
        };
        dqData.goaCategoryToProductDataHistoryMap = new Map<String, Map<String, DQDataHelper.ProductData>>{
            testGoaGroup => goaGroupToProductDataMap
        };
        System.assertEquals(
            50,
            dqData.getCategoryHistoryData(testGoaGroup, DQDataHelper.PRODUCT_DATA_QUANTITY),
            'method should return category quantity for specified goaGroup'
        );
    }

    @IsTest
    static void testGetPackageCategoryHistoryQuantity() {
        String testGoaGroup = 'testGoaGroup';
        DQDataHelper.DealQualificationData dqData = new DQDataHelper.DealQualificationData();

        System.assertEquals(
            0,
            dqData.getPackageCategoryHistoryData(null, null, null),
            'method should return 0 if passed arguments is null'
        );


        final String testPackageId = '18';
        final String testPackageVersion = '2';

        QuoteLineItem testQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    QuoteLineItem.Quantity => 100,
                    QuoteLineItem.Product2Id => ValueProviderBuilder.provideDummyId(Product2.SObjectType)
                }
            )
            .build()
            .getRecord();

        testQli.Quote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
                }
            )
            .build()
            .getRecord();

        testQli.Product2 = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setField(Product2.GOA_Group_V2__c, testGoaGroup)
            .build()
            .getRecord();


        DQDataHelper.ProductData testProductData = new DQDataHelper.ProductData(testPackageId, testPackageVersion, testQli);
        System.assertEquals(
            0,
            dqData.getPackageCategoryHistoryData(testGoaGroup, testProductData, DQDataHelper.PRODUCT_DATA_QUANTITY),
            'method should return 0 if map doesn\'t contains specified group'
        );


        Map<String, DQDataHelper.ProductData> goaGroupToProductDataMap = new Map<String, DQDataHelper.ProductData>{
            'testGoaGroup-18-2-null' => testProductData
        };
        dqData.goaCategoryToProductDataHistoryMap = new Map<String, Map<String, DQDataHelper.ProductData>>{
            testGoaGroup => goaGroupToProductDataMap
        };
        System.assertEquals(
            100,
            dqData.getPackageCategoryHistoryData(testGoaGroup, testProductData, DQDataHelper.PRODUCT_DATA_QUANTITY),
            'method should return package category quantity for specified goaGroup'
        );
    }

    @IsTest
    static void testGetCategoryProductHistoryQuantity() {
        String testGoaGroup = 'testGoaGroup';
        DQDataHelper.DealQualificationData dqData = new DQDataHelper.DealQualificationData();

        System.assertEquals(
            0,
            dqData.getCategoryProductHistoryData(null, null, null),
            'method should return 0 if passed arguments is null'
        );


        QuoteLineItem testQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    QuoteLineItem.Quantity => 100,
                    QuoteLineItem.Product2Id => ValueProviderBuilder.provideDummyId(Product2.SObjectType)
                }
            )
            .build()
            .getRecord();

        testQli.Quote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
                }
            )
            .build()
            .getRecord();

        testQli.Product2 = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setField(Product2.GOA_Group_V2__c, testGoaGroup)
            .build()
            .getRecord();


        DQDataHelper.ProductData testProductData = new DQDataHelper.ProductData(null, null, testQli);
        System.assertEquals(
            0,
            dqData.getCategoryProductHistoryData(testGoaGroup, testProductData, DQDataHelper.PRODUCT_DATA_QUANTITY),
            'method should return 0 if map doesn\'t contains specified group'
        );

        String categoryProductDiscountKey = 'testGoaGroup-null-null-' + testQli.Product2Id;
        Map<String, DQDataHelper.ProductData> goaGroupToProductDataMap = new Map<String, DQDataHelper.ProductData>{
            categoryProductDiscountKey => testProductData
        };
        dqData.goaCategoryToProductDataHistoryMap = new Map<String, Map<String, DQDataHelper.ProductData>>{
            testGoaGroup => goaGroupToProductDataMap
        };
        System.assertEquals(
            100,
            dqData.getCategoryProductHistoryData(testGoaGroup, testProductData, DQDataHelper.PRODUCT_DATA_QUANTITY),
            'method should return category product quantity for specified goaGroup'
        );
    }
}