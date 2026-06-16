@isTest
private class Test_DQApprovalTypeHelper {

    private static DQDataHelper.ProductData buildTestProductData(String goaGroup, Decimal qty, Decimal discount) {
        return buildTestProductData(goaGroup, qty, discount, '1952', '1');
    }

    private static DQDataHelper.ProductData buildTestProductData(
        String goaGroup,
        Decimal qty,
        Decimal discount,
        String packageId,
        String packageVersion
    ) {
        QuoteLineItem testQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    QuoteLineItem.Quantity => qty,
                    QuoteLineItem.Discount => discount,
                    QuoteLineItem.Product2Id => ValueProviderBuilder.provideDummyId(Product2.SObjectType)
                }
            )
            .build()
            .getRecord();

        testQli.Quote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setField(Quote.RecordTypeId, QuoteHelper.RT_ID_BILLING)
            .build()
            .getRecord();

        testQli.Product2 = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setField(Product2.GOA_Group_V3__c, '{"regular":"' + goaGroup + '","contracted":"' + goaGroup + '"}')
            .build()
            .getRecord();

        return new DQDataHelper.ProductData(packageId, packageVersion, testQli);
    }

    @IsTest
    static void testApprovalTypeDiscount() {

        System.assertEquals(
            null,
            DQApprovalTypeHelper.getApplicableApprovalTypes(null),
            'method should return null if passed param is empty'
        );


        final String deviceContractGoaGroup = 'Device_Contract';

        DQ_Approval_Type__c testDqApprovalType = (DQ_Approval_Type__c) new SObjectBuilder(DQ_Approval_Type__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Approval_Type__c.IsActive__c => true,
                    DQ_Approval_Type__c.isUnifiedQuotingApprovalType__c => true,
                    DQ_Approval_Type__c.Approval_Type__c => DQApprovalTypeHelper.APPROVAL_TYPE_DISCOUNT,
                    DQ_Approval_Type__c.Product_Category__c => deviceContractGoaGroup,
                    DQ_Approval_Type__c.Threshold__c => 50
                }
            )
            .create()
            .getRecord();


        DQDataHelper.ProductData productDataForApproval = buildTestProductData(deviceContractGoaGroup, 100, 51);

        DQDataHelper.DealQualificationData dqData = new DQDataHelper.DealQualificationData();
        dqData.goaCategoryToProductDataMap.put(
            deviceContractGoaGroup,
            new Map<String, DQDataHelper.ProductData>{
                productDataForApproval.productGroupKey => productDataForApproval
            }
        );

        DQApprovalTypeHelper.ApplicableApprovalTypes result = DQApprovalTypeHelper.getApplicableApprovalTypes(dqData);
        Map<Id, String> approvalTypeIdToReasonMap = result.approvalTypeIdToReasonMap;

        System.assert(
            approvalTypeIdToReasonMap.containsKey(testDqApprovalType.Id),
            'approvalTypeIdToReasonMap should contain DQ_Approval_Type__c Id if the discount for a product of a ' +
                'certain category(QuoteLineItem.Product2.GOA_Group_V3__c) exceeded the threshold ' +
                'of this category(DQ_Approval_Type__c.Product_Category__c)'
        );

        String approvalReason = approvalTypeIdToReasonMap.get(testDqApprovalType.Id);
        String goaGroupPicklistLabel = DQApprovalTypeHelper.getProductCategoryPicklistMap().get(deviceContractGoaGroup);
        Boolean isReasonContainsThresholdAndGroupName = approvalReason.contains(String.valueOf(testDqApprovalType.Threshold__c)) &&
            approvalReason.contains(goaGroupPicklistLabel);
        System.assert(
            isReasonContainsThresholdAndGroupName,
            'approval reason should contain goa group name and threshold value'
        );

        DQDataHelper.ProductData productDataForApprovalWithPromotion = buildTestProductData(deviceContractGoaGroup, 100, 51);
        productDataForApprovalWithPromotion.hasPromotion = true;
        dqData.goaCategoryToProductDataMap.put(
            deviceContractGoaGroup,
            new Map<String, DQDataHelper.ProductData>{
                productDataForApprovalWithPromotion.productGroupKey => productDataForApprovalWithPromotion
            }
        );

        result = DQApprovalTypeHelper.getApplicableApprovalTypes(dqData);
        approvalTypeIdToReasonMap = result.approvalTypeIdToReasonMap;

        System.assert(
            !approvalTypeIdToReasonMap.containsKey(testDqApprovalType.Id),
            'approvalTypeIdToReasonMap should not contain DQ_Approval_Type__c Id if the discount for a product of a ' +
                'certain category(QuoteLineItem.Product2.GOA_Group_V3__c) exceeded the threshold ' +
                'of this category(DQ_Approval_Type__c.Product_Category__c) but has a Promo Code applied'
        );

        approvalReason = approvalTypeIdToReasonMap.get(testDqApprovalType.Id);
        goaGroupPicklistLabel = DQApprovalTypeHelper.getProductCategoryPicklistMap().get(deviceContractGoaGroup);
        Boolean approvalReasonIsEmpty = approvalReason == null;
        System.assert(
            approvalReasonIsEmpty,
            'approval reason should not contain goa group name and threshold value if a Promo Code was applied'
        );
    }

    @IsTest
    static void testApprovalTypeDiscountApproved() {

        final String deviceContractGoaGroup = 'Device_Contract';

        List<DQ_Approval_Type__c> testDqApprovalTypes = (List<DQ_Approval_Type__c>) new SObjectBuilder(DQ_Approval_Type__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Approval_Type__c.IsActive__c => true,
                    DQ_Approval_Type__c.isUnifiedQuotingApprovalType__c => true,
                    DQ_Approval_Type__c.Approval_Type__c => DQApprovalTypeHelper.APPROVAL_TYPE_DISCOUNT,
                    DQ_Approval_Type__c.Product_Category__c => deviceContractGoaGroup,
                    DQ_Approval_Type__c.Initial_Term_Discount__c => ValueProviderBuilder.provideList(new List<Decimal>{
                        24, null, null
                    }),
                    DQ_Approval_Type__c.Initial_Term_To_Discount__c => ValueProviderBuilder.provideList(new List<Decimal>{
                        60, null, null
                    }),
                    DQ_Approval_Type__c.Threshold__c => ValueProviderBuilder.provideList(new List<Decimal>{
                        70, 50, 70
                    })
                }
            )
            .quantity(3)
            .create()
            .getRecords();

        DQ_Approval_Type__c approvalType70;
        for (DQ_Approval_Type__c item : testDqApprovalTypes) {
            if (item.Threshold__c == 70 && item.Initial_Term_Discount__c == null) {
                approvalType70 = item;
            }
        }

        DQDataHelper.ProductData productDataForApproval = buildTestProductData(deviceContractGoaGroup, 100, 51);
        DQDataHelper.ProductData approvedProductData = buildTestProductData(deviceContractGoaGroup, 100, 60);

        DQDataHelper.DealQualificationData dqData = new DQDataHelper.DealQualificationData();
        dqData.goaCategoryToProductDataMap.put(
            deviceContractGoaGroup,
            new Map<String, DQDataHelper.ProductData>{
                productDataForApproval.productGroupKey => productDataForApproval
            }
        );
        dqData.goaCategoryToProductDataHistoryMap.put(
            deviceContractGoaGroup,
            new Map<String, DQDataHelper.ProductData>{
                approvedProductData.productGroupKey => approvedProductData
            }
        );

        DQApprovalTypeHelper.ApplicableApprovalTypes result = DQApprovalTypeHelper.getApplicableApprovalTypes(dqData);
        Map<Id, String> approvalTypeIdToReasonMap = result.approvalTypeIdToReasonMap;
        System.assert(
            approvalTypeIdToReasonMap.isEmpty(),
            'no approval should be required if current discount less than already approved discount'
        );


        // set discount that exceeds already approved discount
        productDataForApproval.discount = 71;
        dqData.goaCategoryToProductDataMap.put(
            deviceContractGoaGroup,
            new Map<String, DQDataHelper.ProductData>{
                productDataForApproval.productGroupKey => productDataForApproval
            }
        );

        result = DQApprovalTypeHelper.getApplicableApprovalTypes(dqData);
        approvalTypeIdToReasonMap = result.approvalTypeIdToReasonMap;
        System.assert(
            approvalTypeIdToReasonMap.containsKey(approvalType70.Id),
            'approvalTypeIdToReasonMap should contain DQ_Approval_Type__c Id if the discount for a product of a ' +
                'certain category(QuoteLineItem.Product2.GOA_Group_V3__c) exceeded the threshold ' +
                'of this category(DQ_Approval_Type__c.Product_Category__c)'
        );

        String approvalReason = approvalTypeIdToReasonMap.get(approvalType70.Id);
        String goaGroupPicklistLabel = DQApprovalTypeHelper.getProductCategoryPicklistMap().get(deviceContractGoaGroup);
        Boolean isReasonContainsThresholdAndGroupName = approvalReason.contains(String.valueOf(approvalType70.Threshold__c)) &&
            approvalReason.contains(goaGroupPicklistLabel);
        System.assert(
            isReasonContainsThresholdAndGroupName,
            'approval reason should contain goa group name and threshold value'
        );
    }

    @IsTest
    static void testApprovalTypeSpecialTerms() {
        List<DQ_Approval_Type__c> testDqApprovalTypes = (List<DQ_Approval_Type__c>) new SObjectBuilder(DQ_Approval_Type__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Approval_Type__c.IsActive__c => true,
                    DQ_Approval_Type__c.isUnifiedQuotingApprovalType__c => true,
                    DQ_Approval_Type__c.Approval_Type__c => DQApprovalTypeHelper.APPROVAL_TYPE_SPECIAL_TERM,
                    DQ_Approval_Type__c.Initial_Term_Discount__c => ValueProviderBuilder.provideList(new List<Decimal>{
                        null, 24
                    }),
                    DQ_Approval_Type__c.Initial_Term_To_Discount__c => ValueProviderBuilder.provideList(new List<Decimal>{
                        null, 60
                    }),
                    DQ_Approval_Type__c.Special_Terms__c => '2 Free Months of Service;3 Free Months of Service;4 Free Months of Service',
                    DQ_Approval_Type__c.ServiceName__c => QuoteHelper.NGBS_OFFICE_PRODUCT
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        DQ_Approval_Type__c approvalTypeWithoutInitialTerm;
        for (DQ_Approval_Type__c item : testDqApprovalTypes) {
            if (item.Initial_Term_Discount__c == null) {
                approvalTypeWithoutInitialTerm = item;
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
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                    Quote.AverageDiscount__c => 0,
                    Quote.Initial_Term_months__c => '12',
                    Quote.Term_months__c => '12',
                    Quote.OverallDiscretion__c => 0,
                    Quote.Total_MRR_New__c => 0,
                    Quote.ServiceName__c => QuoteHelper.NGBS_OFFICE_PRODUCT
                }
            )
            .create()
            .getRecord();

        DQDataHelper.DealQualificationData dqData = new DQDataHelper.DealQualificationData(new QuoteHelper.QuotesStorage(new List<Quote>{testQuote}), testOpportunity, null, null);
        dqData.serviceNameToQuoteDataMap.get(testQuote.ServiceName__c).specialTerms = '3 Free Months of Service';
        dqData.serviceNameToQuoteDataMap.get(testQuote.ServiceName__c).initialTerm = 12;

        DQApprovalTypeHelper.ApplicableApprovalTypes result = DQApprovalTypeHelper.getApplicableApprovalTypes(dqData);
        Map<Id, String> approvalTypeIdToReasonMap = result.approvalTypeIdToReasonMap;
        System.assert(
            approvalTypeIdToReasonMap.containsKey(approvalTypeWithoutInitialTerm.Id),
            'approvalTypeIdToReasonMap should contain DQ_Approval_Type__c Id if special terms on ' +
                'DealQualificationData and DQ_Approval_Type__c has the same value'
        );

        String approvalReason = approvalTypeIdToReasonMap.get(approvalTypeWithoutInitialTerm.Id);
        System.assert(
            approvalReason.contains(String.valueOf(dqData.serviceNameToQuoteDataMap.get(testQuote.ServiceName__c).specialTerms)),
            'approval reason should contain special terms value'
        );
    }

    @IsTest
    static void testApprovalTypeCCSpecialTerms() {
        DQ_Approval_Type__c testDqApprovalType = (DQ_Approval_Type__c) new SObjectBuilder(DQ_Approval_Type__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Approval_Type__c.IsActive__c => true,
                    DQ_Approval_Type__c.isUnifiedQuotingApprovalType__c => true,
                    DQ_Approval_Type__c.Approval_Type__c => DQApprovalTypeHelper.APPROVAL_TYPE_CC_SPECIAL_TERM,
                    DQ_Approval_Type__c.Initial_Term_Discount__c => 24,
                    DQ_Approval_Type__c.Initial_Term_To_Discount__c => 60,
                    DQ_Approval_Type__c.Special_Terms__c => '2 Free Months of Service;3 Free Months of Service;4 Free Months of Service',
                    DQ_Approval_Type__c.ServiceName__c => QuoteHelper.NGBS_RCCC_PRODUCT
                }
            )
            .create()
            .getRecord();

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
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                    Quote.AverageDiscount__c => 0,
                    Quote.Initial_Term_months__c => '12',
                    Quote.Term_months__c => '12',
                    Quote.OverallDiscretion__c => 0,
                    Quote.Total_MRR_New__c => 0,
                    Quote.ServiceName__c => QuoteHelper.NGBS_RCCC_PRODUCT
                }
            )
            .create()
            .getRecord();

        DQDataHelper.DealQualificationData dqData = new DQDataHelper.DealQualificationData(new QuoteHelper.QuotesStorage(new List<Quote>{testQuote}), testOpportunity, null, null);
        dqData.serviceNameToQuoteDataMap.get(testQuote.ServiceName__c).specialTerms = '3 Free Months of Service';
        dqData.serviceNameToQuoteDataMap.get(testQuote.ServiceName__c).initialTerm = 36;

        DQApprovalTypeHelper.ApplicableApprovalTypes result = DQApprovalTypeHelper.getApplicableApprovalTypes(dqData);
        Map<Id, String> approvalTypeIdToReasonMap = result.approvalTypeIdToReasonMap;
        String approvalReason = approvalTypeIdToReasonMap.get(testDqApprovalType.Id);
        System.assert(
            approvalReason.contains(String.valueOf(dqData.serviceNameToQuoteDataMap.get(testQuote.ServiceName__c).specialTerms)),
            'approval reason should contain special terms value'
        );
    }

    @IsTest
    static void testApprovalTypeSpecialTermsApproved() {
        DQ_Approval_Type__c testDqApprovalType = (DQ_Approval_Type__c) new SObjectBuilder(DQ_Approval_Type__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Approval_Type__c.IsActive__c => true,
                    DQ_Approval_Type__c.isUnifiedQuotingApprovalType__c => true,
                    DQ_Approval_Type__c.Approval_Type__c => DQApprovalTypeHelper.APPROVAL_TYPE_SPECIAL_TERM,
                    DQ_Approval_Type__c.Special_Terms__c => '2 Free Months of Service;3 Free Months of Service;4 Free Months of Service',
                    DQ_Approval_Type__c.ServiceName__c => QuoteHelper.NGBS_OFFICE_PRODUCT
                }
            )
            .create()
            .getRecord();

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
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                    Quote.AverageDiscount__c => 0,
                    Quote.Initial_Term_months__c => '12',
                    Quote.Term_months__c => '12',
                    Quote.OverallDiscretion__c => 0,
                    Quote.Total_MRR_New__c => 0,
                    Quote.ServiceName__c => QuoteHelper.NGBS_OFFICE_PRODUCT
                }
            )
            .create()
            .getRecord();

        DQ_Deal_Qualification__c dq =
            (DQ_Deal_Qualification__c) new SObjectBuilder(DQ_Deal_Qualification__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        DQ_Deal_Qualification__c.Start_Date__c => System.today()
                    }
                )
                .create()
                .getRecord();

        DQ_Deal_Qualification_History__c dqHistory =
            (DQ_Deal_Qualification_History__c) new SObjectBuilder(DQ_Deal_Qualification_History__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        DQ_Deal_Qualification_History__c.Start_Date__c => System.today(),
                        DQ_Deal_Qualification_History__c.Deal_Qualification__c => dq.Id
                    }
                )
                .create()
                .getRecord();

        DQ_Service_Discount_History__c dqServiceDiscountHistory = (DQ_Service_Discount_History__c) new SObjectBuilder(DQ_Service_Discount_History__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Service_Discount_History__c.FreeServiceCredit__c => '2 Free Months of Service',
                    DQ_Service_Discount_History__c.Service__c => QuoteHelper.NGBS_OFFICE_PRODUCT,
                    DQ_Service_Discount_History__c.DQ_Deal_Qualification_History__c => dqHistory.Id
                }
            )
            .create()
            .getRecord();

        DQDataHelper.DealQualificationData dqData = new DQDataHelper.DealQualificationData(new QuoteHelper.QuotesStorage(new List<Quote>{testQuote}), testOpportunity, dq, dqHistory);
        DQDataHelper.DQServiceDiscountHistoryData dqServiceDiscountHistoryData = new DQDataHelper.DQServiceDiscountHistoryData(dqServiceDiscountHistory);

        dqData.serviceNameToQuoteDataMap.get(testQuote.ServiceName__c).specialTerms = '2 Free Months of Service';

        DQApprovalTypeHelper.ApplicableApprovalTypes result = DQApprovalTypeHelper.getApplicableApprovalTypes(dqData);
        Map<Id, String> approvalTypeIdToReasonMap = result.approvalTypeIdToReasonMap;
        System.assert(
            approvalTypeIdToReasonMap.containsKey(testDqApprovalType.Id),
            'approvalTypeIdToReasonMap should contain DQ_Approval_Type__c Id if special terms on ' +
                'DealQualificationData and DQ_Approval_Type__c has the same value'
        );

        String approvalReason = approvalTypeIdToReasonMap.get(testDqApprovalType.Id);
        System.assert(
            approvalReason.contains(String.valueOf(dqData.serviceNameToQuoteDataMap.get(testQuote.ServiceName__c).specialTerms)),
            'approval reason should contain special terms value'
        );
    }

    @IsTest
    static void testApprovalTypeFreeShipping() {
        DQ_Approval_Type__c testDqApprovalType = (DQ_Approval_Type__c) new SObjectBuilder(DQ_Approval_Type__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Approval_Type__c.IsActive__c => true,
                    DQ_Approval_Type__c.isUnifiedQuotingApprovalType__c => true,
                    DQ_Approval_Type__c.Approval_Type__c => DQApprovalTypeHelper.APPROVAL_TYPE_FREE_SHIPPING,
                    DQ_Approval_Type__c.Free_Shipping_Terms_Options__c => DQServiceHelper.FREE_SHIPPING_OPTION,
                    DQ_Approval_Type__c.ServiceName__c => QuoteHelper.NGBS_OFFICE_PRODUCT
                }
            )
            .create()
            .getRecord();

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
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                    Quote.AverageDiscount__c => 0,
                    Quote.Initial_Term_months__c => '12',
                    Quote.Term_months__c => '12',
                    Quote.OverallDiscretion__c => 0,
                    Quote.Total_MRR_New__c => 0,
                    Quote.ServiceName__c => QuoteHelper.NGBS_OFFICE_PRODUCT,
                    Quote.FreeShippingTerms__c => DQServiceHelper.FREE_SHIPPING_OPTION
                }
            )
            .create()
            .getRecord();

        DQDataHelper.DealQualificationData dqData = new DQDataHelper.DealQualificationData(new QuoteHelper.QuotesStorage(new List<Quote>{testQuote}), testOpportunity, null, new DQ_Deal_Qualification_History__c());
        DQApprovalTypeHelper.ApplicableApprovalTypes result;

        // 1 case
        dqData.mainQuoteData.shippingMethodRequiresApprove = true;

        result = DQApprovalTypeHelper.getApplicableApprovalTypes(dqData);
        System.assertEquals(
            result.approvalTypeIdToReasonMap.get(testDqApprovalType.Id),
            DQApprovalTypeHelper.FREE_SHIPPING_APPROVAL_REASON,
            'Shoud be approval reason if shipping method requires approval and shipping term option is Free Shipping'
        );

        // 2 case
        dqData.mainQuoteData.shippingMethodRequiresApprove = false;
        result = DQApprovalTypeHelper.getApplicableApprovalTypes(dqData);
        System.assert(
            !result.approvalTypeIdToReasonMap.containsKey(testDqApprovalType.Id),
            'approval is not required if shipping method doesn\'t require approval'
        );
    }

    @IsTest
    static void testApprovalTypeTotalDiscount() {
        DQ_Approval_Type__c testDqApprovalType = (DQ_Approval_Type__c) new SObjectBuilder(DQ_Approval_Type__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Approval_Type__c.IsActive__c => true,
                    DQ_Approval_Type__c.isUnifiedQuotingApprovalType__c => true,
                    DQ_Approval_Type__c.Approval_Type__c => DQApprovalTypeHelper.APPROVAL_TYPE_AVERAGE_DISCOUNT,
                    DQ_Approval_Type__c.Threshold__c => 25,
                    DQ_Approval_Type__c.ServiceName__c => QuoteHelper.NGBS_OFFICE_PRODUCT
                }
            )
            .create()
            .getRecord();

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
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                    Quote.AverageDiscount__c => 100,
                    Quote.Initial_Term_months__c => '12',
                    Quote.Term_months__c => '12',
                    Quote.OverallDiscretion__c => 0,
                    Quote.Total_MRR_New__c => 0,
                    Quote.ServiceName__c => QuoteHelper.NGBS_OFFICE_PRODUCT
                }
            )
            .create()
            .getRecord();

        DQDataHelper.DealQualificationData dqData = new DQDataHelper.DealQualificationData(new QuoteHelper.QuotesStorage(new List<Quote>{testQuote}), testOpportunity, null, null);
        dqData.serviceNameToQuoteDataMap.get(testQuote.ServiceName__c).discretion = 30;

        DQApprovalTypeHelper.ApplicableApprovalTypes result = DQApprovalTypeHelper.getApplicableApprovalTypes(dqData);
        Map<Id, String> approvalTypeIdToReasonMap = result.approvalTypeIdToReasonMap;
        System.assert(
            approvalTypeIdToReasonMap.containsKey(testDqApprovalType.Id),
            'approvalTypeIdToReasonMap should contain DQ_Approval_Type__c Id if overall discount exceeds threshold'
        );

        String approvalReason = approvalTypeIdToReasonMap.get(testDqApprovalType.Id);
        System.assert(
            approvalReason.contains(String.valueOf(testDqApprovalType.Threshold__c)),
            'approval reason should contain threshold value'
        );
    }

    @IsTest
    static void testApprovalTypeTotalDiscountApproved() {
        List<DQ_Approval_Type__c> testDqApprovalTypes = (List<DQ_Approval_Type__c>) new SObjectBuilder(DQ_Approval_Type__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Approval_Type__c.IsActive__c => true,
                    DQ_Approval_Type__c.isUnifiedQuotingApprovalType__c => true,
                    DQ_Approval_Type__c.Approval_Type__c => DQApprovalTypeHelper.APPROVAL_TYPE_AVERAGE_DISCOUNT,
                    DQ_Approval_Type__c.ServiceName__c => QuoteHelper.NGBS_OFFICE_PRODUCT,
                    DQ_Approval_Type__c.Threshold__c => ValueProviderBuilder.provideList(new List<Decimal>{
                        15, 25
                    })
                }
            )
            .quantity(2)
            .create()
            .getRecords();

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
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                    Quote.AverageDiscount__c => 0,
                    Quote.Initial_Term_months__c => '12',
                    Quote.Term_months__c => '12',
                    Quote.OverallDiscretion__c => 0,
                    Quote.Total_MRR_New__c => 0,
                    Quote.ServiceName__c => QuoteHelper.NGBS_OFFICE_PRODUCT
                }
            )
            .create()
            .getRecord();

        DQ_Deal_Qualification__c dq =
            (DQ_Deal_Qualification__c) new SObjectBuilder(DQ_Deal_Qualification__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        DQ_Deal_Qualification__c.Start_Date__c => System.today()
                    }
                )
                .create()
                .getRecord();

        DQ_Deal_Qualification_History__c dqHistory =
            (DQ_Deal_Qualification_History__c) new SObjectBuilder(DQ_Deal_Qualification_History__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        DQ_Deal_Qualification_History__c.Start_Date__c => System.today(),
                        DQ_Deal_Qualification_History__c.Deal_Qualification__c => dq.Id
                    }
                )
                .create()
                .getRecord();

        DQDataHelper.DealQualificationData dqData = new DQDataHelper.DealQualificationData(new QuoteHelper.QuotesStorage(new List<Quote>{testQuote}), testOpportunity, dq, dqHistory);
        DQ_Service_Discount_History__c dqServiceDiscountHistory = (DQ_Service_Discount_History__c) new SObjectBuilder(DQ_Service_Discount_History__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Service_Discount_History__c.FreeServiceCredit__c => '2 Free Months of Service',
                    DQ_Service_Discount_History__c.Service__c => QuoteHelper.NGBS_OFFICE_PRODUCT,
                    DQ_Service_Discount_History__c.DQ_Deal_Qualification_History__c => dqHistory.Id
                }
            )
            .create()
            .getRecord();

        DQDataHelper.DQServiceDiscountHistoryData dqServiceDiscountHistoryData = new DQDataHelper.DQServiceDiscountHistoryData(dqServiceDiscountHistory);

        DQ_Approval_Type__c approvalType25;
        for (DQ_Approval_Type__c item : testDqApprovalTypes) {
            if (item.Threshold__c == 25) {
                approvalType25 = item;
            }
        }

        dqServiceDiscountHistoryData.averageDiscountHistory = 20;
        dqData.serviceNameToQuoteDataMap.get(testQuote.ServiceName__c).averageDiscount = 30;

        DQApprovalTypeHelper.ApplicableApprovalTypes result = DQApprovalTypeHelper.getApplicableApprovalTypes(dqData);
        Map<Id, String> approvalTypeIdToReasonMap = result.approvalTypeIdToReasonMap;
        System.assert(
            approvalTypeIdToReasonMap.containsKey(approvalType25.Id),
            'approvalTypeIdToReasonMap should contain DQ_Approval_Type__c Id if overall discount exceeds threshold'
        );

        String approvalReason = approvalTypeIdToReasonMap.get(approvalType25.Id);
        System.assert(
            approvalReason.contains(String.valueOf(approvalType25.Threshold__c)),
            'approval reason should contain threshold value'
        );
    }

    @IsTest
    static void testApprovalTypeAutoRenewalRemoval() {
        DQ_Approval_Type__c testDqApprovalType = (DQ_Approval_Type__c) new SObjectBuilder(DQ_Approval_Type__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Approval_Type__c.IsActive__c => true,
                    DQ_Approval_Type__c.isUnifiedQuotingApprovalType__c => true,
                    DQ_Approval_Type__c.Approval_Type__c => DQApprovalTypeHelper.APPROVAL_TYPE_AUTO_RENEW_REMOVAL,
                    DQ_Approval_Type__c.ServiceName__c => QuoteHelper.NGBS_OFFICE_PRODUCT
                }
            )
            .create()
            .getRecord();

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
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                    Quote.AverageDiscount__c => 0,
                    Quote.Initial_Term_months__c => '12',
                    Quote.Term_months__c => '12',
                    Quote.OverallDiscretion__c => 0,
                    Quote.Total_MRR_New__c => 0,
                    Quote.ServiceName__c => QuoteHelper.NGBS_OFFICE_PRODUCT
                }
            )
            .build()
            .getRecord();

        DQ_Deal_Qualification__c dq = (DQ_Deal_Qualification__c) new SObjectBuilder(DQ_Deal_Qualification__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Deal_Qualification__c.Id => '',
                    DQ_Deal_Qualification__c.Auto_Renewal__c => true
                }
            )
            .build()
            .getRecord();

        DQ_Deal_Qualification_History__c dqHistory= DealQualificationHandler.buildDqHistoryRecord(null, dq);

        DQDataHelper.DealQualificationData dqData = new DQDataHelper.DealQualificationData(new QuoteHelper.QuotesStorage(new List<Quote>{testQuote}), testOpportunity, null, dqHistory);
        DQApprovalTypeHelper.ApplicableApprovalTypes result;

        dqData.mainQuoteData.isAutoRenewal = false;
        dqData.mainQuoteData.packageInfoData.hasContract = true;
        result = DQApprovalTypeHelper.getApplicableApprovalTypes(dqData);

        System.assertEquals(
            result.approvalTypeIdToReasonMap.get(testDqApprovalType.Id),
            DQApprovalTypeHelper.AUTO_RENEW_REMOVAL_APPROVAL_REASON,
            'Shoud be approval reason in case of auto renewal is switched off and there is contract on quote'
        );

        dqData.mainQuoteData.isAutoRenewal = true;
        result = DQApprovalTypeHelper.getApplicableApprovalTypes(dqData);
        System.assert(
            !result.approvalTypeIdToReasonMap.containsKey(testDqApprovalType.Id),
            'approval is not required in case of auto renewal is switched on'
        );

        dqData.mainQuoteData.isAutoRenewal = false;
        dqData.mainQuoteData.packageInfoData.hasContract = false;
        result = DQApprovalTypeHelper.getApplicableApprovalTypes(dqData);
        System.assert(
            !result.approvalTypeIdToReasonMap.containsKey(testDqApprovalType.Id),
            'approval is not required in case of auto renewal is switched off and there is no contract on quote'
        );
    }

    @IsTest
    static void testIsDiscountExceeded() {

        System.assertEquals(
            false,
            DQApprovalTypeHelper.isDiscountExceeded(null, null, null, null),
            'isDiscountExceeded should return false if params are empty'
        );



        String testGoaGroup = 'test_goa_group';

        DQDataHelper.ProductData approvedProductData = buildTestProductData(testGoaGroup, 100, 45, '1952', '1');
        DQDataHelper.ProductData testProductData = buildTestProductData(testGoaGroup, 100, 70, '1952', '1');

        Map<String, DQDataHelper.ProductData> approvedProductDataMap = new Map<String, DQDataHelper.ProductData>{
            approvedProductData.productGroupKey => approvedProductData
        };

        DQDataHelper.DealQualificationData dqData = new DQDataHelper.DealQualificationData();
        dqData.goaCategoryToProductDataHistoryMap = new Map<String, Map<String, DQDataHelper.ProductData>>{
            testGoaGroup => approvedProductDataMap
        };

        DQ_Approval_Type__c testDqApprovalType = (DQ_Approval_Type__c) new SObjectBuilder(DQ_Approval_Type__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Approval_Type__c.IsActive__c => true,
                    DQ_Approval_Type__c.Approval_Type__c => DQApprovalTypeHelper.APPROVAL_TYPE_DISCOUNT,
                    DQ_Approval_Type__c.Product_Category__c => testGoaGroup,
                    DQ_Approval_Type__c.Threshold__c => 50
                }
            )
            .build()
            .getRecord();

        Boolean isDiscountExceeded = DQApprovalTypeHelper.isDiscountExceeded(
            dqData,
            testProductData.productGroupKey,
            testProductData,
            testDqApprovalType
        );
        System.assertEquals(
            true,
            isDiscountExceeded,
            'method should return true if new product discount exceeds approved product discount'
        );


        DQDataHelper.ProductData approvedCategoryProductData = buildTestProductData(testGoaGroup, 100, 45, null, null);
        approvedProductDataMap = new Map<String, DQDataHelper.ProductData>{
            approvedCategoryProductData.productGroupKey => approvedCategoryProductData
        };

        dqData.goaCategoryToProductDataHistoryMap = new Map<String, Map<String, DQDataHelper.ProductData>>{
            testGoaGroup => approvedProductDataMap
        };
        isDiscountExceeded = DQApprovalTypeHelper.isDiscountExceeded(
            dqData,
            testProductData.productGroupKey,
            testProductData,
            testDqApprovalType
        );
        System.assertEquals(
            true,
            isDiscountExceeded,
            'method should return true if new product discount exceeds approved category product discount'
        );

        DQDataHelper.ProductData approvedPackageCategoryData = buildTestProductData(testGoaGroup, 100, 45, '1952', '1');
        String packageCategoryDataKey = approvedPackageCategoryData.goaGroup + '-'
            + approvedPackageCategoryData.packageId + '-'
            + approvedPackageCategoryData.packageVersion + '-null';
        approvedProductDataMap = new Map<String, DQDataHelper.ProductData>{
            packageCategoryDataKey => approvedPackageCategoryData
        };
        dqData.goaCategoryToProductDataHistoryMap = new Map<String, Map<String, DQDataHelper.ProductData>>{
            testGoaGroup => approvedProductDataMap
        };
        isDiscountExceeded = DQApprovalTypeHelper.isDiscountExceeded(
            dqData,
            testProductData.productGroupKey,
            testProductData,
            testDqApprovalType
        );
        System.assertEquals(
            true,
            isDiscountExceeded,
            'method should return true if new product discount exceeds approved package category discount'
        );


        DQDataHelper.ProductData approvedCategoryData = buildTestProductData(testGoaGroup, 100, 45, null, null);
        String approvedCategoryDataKey = approvedCategoryData.goaGroup + '-null-null-null';
        approvedProductDataMap = new Map<String, DQDataHelper.ProductData>{
            approvedCategoryDataKey => approvedCategoryData
        };
        dqData.goaCategoryToProductDataHistoryMap = new Map<String, Map<String, DQDataHelper.ProductData>>{
            testGoaGroup => approvedProductDataMap
        };
        isDiscountExceeded = DQApprovalTypeHelper.isDiscountExceeded(
            dqData,
            testProductData.productGroupKey,
            testProductData,
            testDqApprovalType
        );
        System.assertEquals(
            true,
            isDiscountExceeded,
            'method should return true if new product discount exceeds approved category discount'
        );
        dqData.goaCategoryToProductDataHistoryMap = new Map<String, Map<String, DQDataHelper.ProductData>>{
            testGoaGroup => new Map<String, DQDataHelper.ProductData>()
        };
        isDiscountExceeded = DQApprovalTypeHelper.isDiscountExceeded(
            dqData,
            testProductData.productGroupKey,
            testProductData,
            testDqApprovalType
        );
        System.assertEquals(
            true,
            isDiscountExceeded,
            'method should return true for new product discount'
        );
    }

    @IsTest
    static void testValidateQuantityChange() {
        String testGoaGroup = 'test_goa_group';

        new SObjectBuilder(RC_UnifiedQuotingTool_Quantity_Threshold__c.sObjectType)
            .setField(RC_UnifiedQuotingTool_Quantity_Threshold__c.Threshold__c, 20)
            .create();

        DQDataHelper.ProductData approvedProductData = buildTestProductData(testGoaGroup, 100, 45, '1952', '1');
        DQDataHelper.ProductData testProductData = buildTestProductData(testGoaGroup, 200, 70, '1952', '1');

        Map<String, DQDataHelper.ProductData> approvedProductDataMap = new Map<String, DQDataHelper.ProductData>{
            approvedProductData.productGroupKey => approvedProductData
        };

        DQDataHelper.DealQualificationData dqData = new DQDataHelper.DealQualificationData();
        dqData.goaCategoryToProductDataHistoryMap = new Map<String, Map<String, DQDataHelper.ProductData>>{
            testGoaGroup => approvedProductDataMap
        };

        DQ_Approval_Type__c testDqApprovalType = (DQ_Approval_Type__c) new SObjectBuilder(DQ_Approval_Type__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Approval_Type__c.IsActive__c => true,
                    DQ_Approval_Type__c.Approval_Type__c => DQApprovalTypeHelper.APPROVAL_TYPE_DISCOUNT,
                    DQ_Approval_Type__c.Product_Category__c => testGoaGroup,
                    DQ_Approval_Type__c.Threshold__c => 50
                }
            )
            .build()
            .getRecord();

        Boolean isValidationFailed = DQApprovalTypeHelper.validateQuantityChange(
            dqData.goaCategoryToProductDataHistoryMap.get(testDqApprovalType.Product_Category__c),
            testProductData.productGroupKey,
            testProductData,
            testDqApprovalType,
            dqData
        );
        System.assertEquals(
            true,
            isValidationFailed,
            'method should return true if new product quantity more than approved product quantity'
        );


        DQDataHelper.ProductData approvedCategoryProductData = buildTestProductData(testGoaGroup, 100, 45, null, null);
        approvedProductDataMap = new Map<String, DQDataHelper.ProductData>{
            approvedCategoryProductData.productGroupKey => approvedCategoryProductData
        };

        dqData.goaCategoryToProductDataHistoryMap = new Map<String, Map<String, DQDataHelper.ProductData>>{
            testGoaGroup => approvedProductDataMap
        };
        isValidationFailed = DQApprovalTypeHelper.validateQuantityChange(
            dqData.goaCategoryToProductDataHistoryMap.get(testDqApprovalType.Product_Category__c),
            testProductData.productGroupKey,
            testProductData,
            testDqApprovalType,
            dqData
        );
        System.assertEquals(
            true,
            isValidationFailed,
            'method should return true if new product quantity more than approved category product quantity'
        );

        DQDataHelper.ProductData approvedPackageCategoryData = buildTestProductData(testGoaGroup, 100, 45, '1952', '1');
        String packageCategoryDataKey = approvedPackageCategoryData.goaGroup + '-'
            + approvedPackageCategoryData.packageId + '-'
            + approvedPackageCategoryData.packageVersion + '-null';
        approvedProductDataMap = new Map<String, DQDataHelper.ProductData>{
            packageCategoryDataKey => approvedPackageCategoryData
        };
        dqData.goaCategoryToProductDataHistoryMap = new Map<String, Map<String, DQDataHelper.ProductData>>{
            testGoaGroup => approvedProductDataMap
        };
        isValidationFailed = DQApprovalTypeHelper.validateQuantityChange(
            dqData.goaCategoryToProductDataHistoryMap.get(testDqApprovalType.Product_Category__c),
            testProductData.productGroupKey,
            testProductData,
            testDqApprovalType,
            dqData
        );
        System.assertEquals(
            true,
            isValidationFailed,
            'method should return true if new product quantity more than approved package category quantity'
        );


        DQDataHelper.ProductData approvedCategoryData = buildTestProductData(testGoaGroup, 100, 45, null, null);
        String approvedCategoryDataKey = approvedCategoryData.goaGroup + '-null-null-null';
        approvedProductDataMap = new Map<String, DQDataHelper.ProductData>{
            approvedCategoryDataKey => approvedCategoryData
        };
        dqData.goaCategoryToProductDataHistoryMap = new Map<String, Map<String, DQDataHelper.ProductData>>{
            testGoaGroup => approvedProductDataMap
        };
        isValidationFailed = DQApprovalTypeHelper.validateQuantityChange(
            dqData.goaCategoryToProductDataHistoryMap.get(testDqApprovalType.Product_Category__c),
            testProductData.productGroupKey,
            testProductData,
            testDqApprovalType,
            dqData
        );
        System.assertEquals(
            true,
            isValidationFailed,
            'method should return true if new product quantity more than approved category quantity'
        );
    }

    @IsTest
    static void testApprovalTypeSpecialTermsForMeeting() {
        List<DQ_Approval_Type__c> testDqApprovalTypes = (List<DQ_Approval_Type__c>) new SObjectBuilder(DQ_Approval_Type__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Approval_Type__c.IsActive__c => true,
                    DQ_Approval_Type__c.isUnifiedQuotingApprovalType__c => true,
                    DQ_Approval_Type__c.Approval_Type__c => DQApprovalTypeHelper.APPROVAL_TYPE_SPECIAL_TERM,
                    DQ_Approval_Type__c.Initial_Term_Discount__c => ValueProviderBuilder.provideList(new List<Decimal>{
                        null, 24
                    }),
                    DQ_Approval_Type__c.Initial_Term_To_Discount__c => ValueProviderBuilder.provideList(new List<Decimal>{
                        null, 60
                    }),
                    DQ_Approval_Type__c.Special_Terms__c => '2 Free Months of Service;3 Free Months of Service;4 Free Months of Service',
                    DQ_Approval_Type__c.ServiceName__c => String.format('{0};{1}', new List<String>{Product2Helper.PRODUCT_MEETINGS, QuoteHelper.NGBS_OFFICE_PRODUCT})
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        DQ_Approval_Type__c approvalTypeWithoutInitialTerm;
        for (DQ_Approval_Type__c item : testDqApprovalTypes) {
            if (item.Initial_Term_Discount__c == null) {
                approvalTypeWithoutInitialTerm = item;
            }
        }

        Opportunity testOpportunity = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity',
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                    Opportunity.Tier_Name__c => Product2Helper.PRODUCT_MEETINGS
                }
            )
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'Test Quote',
                    Quote.OpportunityId => testOpportunity.Id,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                    Quote.AverageDiscount__c => 0,
                    Quote.Initial_Term_months__c => '12',
                    Quote.Term_months__c => '12',
                    Quote.OverallDiscretion__c => 0,
                    Quote.Total_MRR_New__c => 0,
                    Quote.ServiceName__c => Product2Helper.PRODUCT_MEETINGS
                }
            )
            .create()
            .getRecord();

        DQDataHelper.DealQualificationData dqData = new DQDataHelper.DealQualificationData(new QuoteHelper.QuotesStorage(new List<Quote>{testQuote}), testOpportunity, null, null);
        dqData.serviceNameToQuoteDataMap.get(testQuote.ServiceName__c).specialTerms = '3 Free Months of Service';
        dqData.serviceNameToQuoteDataMap.get(testQuote.ServiceName__c).initialTerm = 12;

        DQApprovalTypeHelper.ApplicableApprovalTypes result = DQApprovalTypeHelper.getApplicableApprovalTypes(dqData);
        Map<Id, String> approvalTypeIdToReasonMap = result.approvalTypeIdToReasonMap;
        System.assert(
            approvalTypeIdToReasonMap.containsKey(approvalTypeWithoutInitialTerm.Id),
            'approvalTypeIdToReasonMap should contain DQ_Approval_Type__c Id if special terms on ' +
                'DealQualificationData and DQ_Approval_Type__c has the same value'
        );

        String approvalReason = approvalTypeIdToReasonMap.get(approvalTypeWithoutInitialTerm.Id);
        System.assert(
            approvalReason.contains(String.valueOf(dqData.serviceNameToQuoteDataMap.get(testQuote.ServiceName__c).specialTerms)),
            'approval reason should contain special terms value'
        );
    }

    @IsTest
    static void testApprovalTypeTotalDiscountForMeetings() {
        DQ_Approval_Type__c testDqApprovalType = (DQ_Approval_Type__c) new SObjectBuilder(DQ_Approval_Type__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Approval_Type__c.IsActive__c => true,
                    DQ_Approval_Type__c.isUnifiedQuotingApprovalType__c => true,
                    DQ_Approval_Type__c.Approval_Type__c => DQApprovalTypeHelper.APPROVAL_TYPE_AVERAGE_DISCOUNT,
                    DQ_Approval_Type__c.Threshold__c => 25,
                    DQ_Approval_Type__c.ServiceName__c => String.format('{0};{1}', new List<String>{Product2Helper.PRODUCT_MEETINGS, QuoteHelper.NGBS_OFFICE_PRODUCT})
                }
            )
            .create()
            .getRecord();

        Opportunity testOpportunity = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity',
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                    Opportunity.Tier_Name__c => Product2Helper.PRODUCT_MEETINGS
                }
            )
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'Test Quote',
                    Quote.OpportunityId => testOpportunity.Id,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                    Quote.AverageDiscount__c => 100,
                    Quote.Initial_Term_months__c => '12',
                    Quote.Term_months__c => '12',
                    Quote.OverallDiscretion__c => 0,
                    Quote.Total_MRR_New__c => 0,
                    Quote.ServiceName__c => Product2Helper.PRODUCT_MEETINGS
                }
            )
            .create()
            .getRecord();

        DQDataHelper.DealQualificationData dqData = new DQDataHelper.DealQualificationData(new QuoteHelper.QuotesStorage(new List<Quote>{testQuote}), testOpportunity, null, null);

        DQApprovalTypeHelper.ApplicableApprovalTypes result = DQApprovalTypeHelper.getApplicableApprovalTypes(dqData);
        Map<Id, String> approvalTypeIdToReasonMap = result.approvalTypeIdToReasonMap;
        System.assert(
            approvalTypeIdToReasonMap.containsKey(testDqApprovalType.Id),
            'approvalTypeIdToReasonMap should contain DQ_Approval_Type__c Id if overall discount exceeds threshold'
        );

        String approvalReason = approvalTypeIdToReasonMap.get(testDqApprovalType.Id);
        System.assert(
            approvalReason.contains(String.valueOf(testDqApprovalType.Threshold__c)),
            'approval reason should contain threshold value'
        );
    }

    @IsTest
    static void testApprovalTypeOverallDiscretionForMeetings() {
        DQ_Approval_Type__c testDqApprovalType = (DQ_Approval_Type__c) new SObjectBuilder(DQ_Approval_Type__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Approval_Type__c.IsActive__c => true,
                    DQ_Approval_Type__c.isUnifiedQuotingApprovalType__c => true,
                    DQ_Approval_Type__c.Approval_Type__c => DQApprovalTypeHelper.APPROVAL_TYPE_DISCRETION,
                    DQ_Approval_Type__c.Threshold__c => 25,
                    DQ_Approval_Type__c.ServiceName__c => String.format('{0};{1}', new List<String>{Product2Helper.PRODUCT_MEETINGS, QuoteHelper.NGBS_OFFICE_PRODUCT})
                }
            )
            .create()
            .getRecord();

        Opportunity testOpportunity = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity',
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                    Opportunity.Tier_Name__c => Product2Helper.PRODUCT_MEETINGS
                }
            )
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'Test Quote',
                    Quote.OpportunityId => testOpportunity.Id,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                    Quote.AverageDiscount__c => 100,
                    Quote.Initial_Term_months__c => '12',
                    Quote.Term_months__c => '12',
                    Quote.OverallDiscretion__c => 0,
                    Quote.Total_MRR_New__c => 0,
                    Quote.ServiceName__c => Product2Helper.PRODUCT_MEETINGS
                }
            )
            .create()
            .getRecord();

        DQDataHelper.DealQualificationData dqData = new DQDataHelper.DealQualificationData(new QuoteHelper.QuotesStorage(new List<Quote>{testQuote}), testOpportunity, null, null);
        dqData.serviceNameToQuoteDataMap.get(testQuote.ServiceName__c).discretion = 30;

        DQApprovalTypeHelper.ApplicableApprovalTypes result = DQApprovalTypeHelper.getApplicableApprovalTypes(dqData);
        Map<Id, String> approvalTypeIdToReasonMap = result.approvalTypeIdToReasonMap;
        System.assert(
            approvalTypeIdToReasonMap.containsKey(testDqApprovalType.Id),
            'approvalTypeIdToReasonMap should contain DQ_Approval_Type__c Id if overall discretion exceeds threshold'
        );

        String approvalReason = approvalTypeIdToReasonMap.get(testDqApprovalType.Id);
        System.assert(
            approvalReason.contains(String.valueOf(testDqApprovalType.Threshold__c)),
            'approval reason should contain threshold value'
        );
    }

    @IsTest
    static void testGetIsOnlyProServDiscretionApprovalTypePositive() {
        List<DQ_Approval_Type__c> testDqApprovalTypes = (List<DQ_Approval_Type__c>) new SObjectBuilder(DQ_Approval_Type__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Approval_Type__c.IsActive__c => true,
                    DQ_Approval_Type__c.isUnifiedQuotingApprovalType__c => true,
                    DQ_Approval_Type__c.Approval_Type__c => DQApprovalTypeHelper.APPROVAL_TYPE_PS_DISCRETION,
                    DQ_Approval_Type__c.Initial_Term_Discount__c => ValueProviderBuilder.provideList(new List<Decimal>{
                        24, null, null
                    }),
                    DQ_Approval_Type__c.Initial_Term_To_Discount__c => ValueProviderBuilder.provideList(new List<Decimal>{
                        60, null, null
                    }),
                    DQ_Approval_Type__c.Threshold__c => ValueProviderBuilder.provideList(new List<Decimal>{
                        70, 50, 70
                    })
                }
            )
            .quantity(3)
            .create()
            .getRecords();
        
        Set<Id> approvalTypeIds = new Set<Id>{ testDqApprovalTypes[0].Id }; 
        Set<Id> proServDiscretionApprovalTypeIds = new Set<Id>{ testDqApprovalTypes[0].Id, testDqApprovalTypes[1].Id, testDqApprovalTypes[2].Id };

        Test.startTest();
           Boolean isOnlyProServDiscretionApprovalType = DQApprovalTypeHelper.getIsOnlyProServDiscretionApprovalType(approvalTypeIds, proServDiscretionApprovalTypeIds);
        Test.stopTest();
        System.assertEquals(
            true,
            isOnlyProServDiscretionApprovalType,
            'should return true if approvalTypeIds contains only proServDiscretionApprovalTypeIds values'
        );
    }

    @IsTest
    static void testGetIsOnlyProServDiscretionApprovalTypeNegative() {
        List<DQ_Approval_Type__c> testDqApprovalTypes = (List<DQ_Approval_Type__c>) new SObjectBuilder(DQ_Approval_Type__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Approval_Type__c.IsActive__c => true,
                    DQ_Approval_Type__c.isUnifiedQuotingApprovalType__c => true,
                    DQ_Approval_Type__c.Approval_Type__c => ValueProviderBuilder.provideList(new List<String>{
                        DQApprovalTypeHelper.APPROVAL_TYPE_PS_DISCRETION, DQApprovalTypeHelper.APPROVAL_TYPE_DISCRETION, DQApprovalTypeHelper.APPROVAL_TYPE_DISCRETION
                    }),
                    DQ_Approval_Type__c.Initial_Term_Discount__c => ValueProviderBuilder.provideList(new List<Decimal>{
                        24, null, null
                    }),
                    DQ_Approval_Type__c.Initial_Term_To_Discount__c => ValueProviderBuilder.provideList(new List<Decimal>{
                        60, null, null
                    }),
                    DQ_Approval_Type__c.Threshold__c => ValueProviderBuilder.provideList(new List<Decimal>{
                        70, 50, 70
                    })
                }
            )
            .quantity(3)
            .create()
            .getRecords();
        
        Set<Id> approvalTypeIds = new Set<Id>{ testDqApprovalTypes[1].Id, testDqApprovalTypes[2].Id }; 
        Set<Id> proServDiscretionApprovalTypeIds = new Set<Id>{ testDqApprovalTypes[0].Id };
        Test.startTest();
           Boolean isOnlyProServDiscretionApprovalType = DQApprovalTypeHelper.getIsOnlyProServDiscretionApprovalType(approvalTypeIds, proServDiscretionApprovalTypeIds);
        Test.stopTest();
        System.assertEquals(
            false,
            isOnlyProServDiscretionApprovalType,
            'should return false if approvalTypeIds contains not only proServDiscretionApprovalTypeIds values'
        );
    }
}