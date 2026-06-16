@isTest
private class Test_DealQualificationSelector {

    @isTest
    private static void testSelectDQByOppId() {

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                Opportunity.Name => ValueProviderBuilder.provideUniqueString('test opportunity')
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.OpportunityId => opp.Id,
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo(),
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Approved_Status__c => QuoteHelper.APPROVAL_STATUS_REQUIRED,
                Quote.Pricebook2Id => Test.getStandardPriceBookId()
            })
            .create()
            .getRecord();

        DQ_Deal_Qualification__c testDqRecord = (DQ_Deal_Qualification__c) new SObjectBuilder(DQ_Deal_Qualification__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                DQ_Deal_Qualification__c.Opportunity__c => opp.Id,
                DQ_Deal_Qualification__c.Quote__c => qt.Id,
                DQ_Deal_Qualification__c.Status__c => 'New',
                DQ_Deal_Qualification__c.Charge_Term__c => 'Annual',
                DQ_Deal_Qualification__c.Renewal_Term__c => '12',
                DQ_Deal_Qualification__c.Initial_Term__c => '12',
                DQ_Deal_Qualification__c.Special_Terms__c => '2 Free Months of Service',
                DQ_Deal_Qualification__c.Deal_Size__c => 500,
                DQ_Deal_Qualification__c.New_Annual_Recurring_Charges__c => 50,
                DQ_Deal_Qualification__c.Free_Shipping_Terms_Options__c => 'Overnight',
                DQ_Deal_Qualification__c.IsDQCreatedFromCPQOpp__c => false
            })
            .create()
            .getRecord();

        DealQualificationSelector dqSelector = new DealQualificationSelector();

        List<Schema.SObjectField> fieldsForSync = new List<Schema.SObjectField>(dqSelector.getDefaultFieldList());
        fieldsForSync.addAll(dqSelector.getFieldsForSync());
        List<String> fieldNameList = new List<String>();
        for (Schema.SObjectField field : fieldsForSync) {
            fieldNameList.add(field.getDescribe().getName());
        }

        List<DQ_Deal_Qualification__c> dqList = dqSelector
            .selectDQForSync(opp.Id)
            .executeQuery();

        DQ_Deal_Qualification__c dqRecord = dqList.get(0);

        Map<String, Object> fieldNameToValueMap = dqRecord.getPopulatedFieldsAsMap();
        for (String populatedField : fieldNameToValueMap.keySet()) {
            System.assert(
                fieldNameList.contains(populatedField),
                'required field are not populated: "' + populatedField + '"'
            );
        }
    }

    @isTest
    private static void verifySelectDQForSyncReturnCorrectQuery() {
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                Opportunity.Name => ValueProviderBuilder.provideUniqueString('test opportunity')
            })
            .create()
            .getRecord();

        String basePattern = '(^SELECT){1}(\\s[A-z0-9.]+,?\\s?)+';
        String subPattern = '(\\(SELECT(\\s[A-z0-9.]+,?)+\\s)';
        QueryFactory qf = new DealQualificationSelector()
            .selectDQForSync(opp.Id)
            .setQuery();

        String discountSubSelect = subPattern + '(FROM Deal_Qualification_Discounts__r\\) , )';
        String serviceDiscountSubSelect = subPattern + '(FROM DQ_Deal_Qualification_Service_Discounts__r\\)  )';
        String selectFilters = '(FROM DQ_Deal_Qualification__c WHERE Opportunity__c = :bind0 ORDER BY Name ASC NULLS FIRST )';
        String pattern = basePattern + discountSubSelect + serviceDiscountSubSelect + selectFilters;
        System.assert(System.Pattern.matches(pattern, qf.getQuery()));
    }

    @isTest
    private static void verifyselectDQForDqGOAReturnCorrectQuery() {
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                Opportunity.Name => ValueProviderBuilder.provideUniqueString('test opportunity')
            })
            .create()
            .getRecord();

        String basePattern = '(^SELECT){1}(\\s[A-z0-9.]+,?\\s?)+';
        String subPattern = '(\\(SELECT(\\s[A-z0-9.]+,?)+\\s)';
        QueryFactory qf = new DealQualificationSelector()
            .selectDQForDQGOA(opp.Id)
            .setQuery();
        String discountSubSelect = subPattern + '(FROM Deal_Qualification_Discounts__r\\) , )';
        String serviceDiscountSubSelect = subPattern + '(FROM DQ_Deal_Qualification_Service_Discounts__r\\)  )';
        String selectFilters = '(FROM DQ_Deal_Qualification__c WHERE Opportunity__c = :bind0 ORDER BY Name ASC NULLS FIRST )';
        String pattern = basePattern + discountSubSelect + serviceDiscountSubSelect + selectFilters;
        System.assert(System.Pattern.matches(pattern, qf.getQuery()));
    }

    @isTest
    static void testSelectAllFieldsForCloning() {
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

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                    Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                    Opportunity.Name => ValueProviderBuilder.provideUniqueString('test opportunity')
                })
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'Test Quote',
                    Quote.OpportunityId => opp.Id
                }
            )
            .create()
            .getRecord();

        DQ_Deal_Qualification__c testDqRecord = (DQ_Deal_Qualification__c) new SObjectBuilder(DQ_Deal_Qualification__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                    DQ_Deal_Qualification__c.Opportunity__c => opp.Id,
                    DQ_Deal_Qualification__c.Status__c => QuoteHelper.STATUS_NEW_CUSTOMER,
                    DQ_Deal_Qualification__c.Charge_Term__c => 'Annual',
                    DQ_Deal_Qualification__c.Renewal_Term__c => '12',
                    DQ_Deal_Qualification__c.Initial_Term__c => '12',
                    DQ_Deal_Qualification__c.Special_Terms__c => QuoteHelper.FREE_MONTH_2,
                    DQ_Deal_Qualification__c.Deal_Size__c => 500,
                    DQ_Deal_Qualification__c.New_Annual_Recurring_Charges__c => 50,
                    DQ_Deal_Qualification__c.Free_Shipping_Terms_Options__c => QuoteHelper.SHIPPING_OPTION_OVERNIGHT,
                    DQ_Deal_Qualification__c.IsDQCreatedFromCPQOpp__c => false,
                    DQ_Deal_Qualification__c.Quote__c => testQuote.Id
                })
            .quantity(2)
            .create()
            .getRecord();

        List<DQ_Deal_Qualification_History__c> testDqHistoryRecords =
            (List<DQ_Deal_Qualification_History__c>) new SObjectBuilder(DQ_Deal_Qualification_History__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Deal_Qualification_History__c.Deal_Qualification__c => testDqRecord.Id,
                    DQ_Deal_Qualification_History__c.Status__c => QuoteHelper.APPROVAL_STATUS_APPROVED
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

        Map<Id, Id> oldToNewDQIds = new Map<Id, Id>();
        oldToNewDQIds.put(testDqRecord.Id, testDqRecord.Id);

        Test.startTest();
            List<DQ_Deal_Qualification_History__c> allFieldsForCloning = new DealQualificationHistorySelector()
                .selectAllFieldsForCloning(new List<Object>{ oldToNewDQIds.keyset() })
                .executeQuery();

            List<DQ_Deal_Qualification__c> originalDQs = new DealQualificationSelector()
                .selectAllFieldsForCloning(new List<Object>{ new Set<Id>{testQuote.Id} })
                .executeQuery();

            System.assertEquals(1,allFieldsForCloning.size(), 'method should return 1 Deal Qualification History');
            System.assertEquals(2,originalDQs.size(), 'method should return 2 Deal Qualifications');
        Test.stopTest();
    }

    @isTest
    static void testSelectApprovedDQHistory() {

        final String deviceContractGoaGroup = 'Device_Contract';
        Product2 testProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Product2.Name => 'test product 1',
                    Product2.GOA_Group_V3__c => '{"regular":"' + deviceContractGoaGroup + '","contracted":"' + deviceContractGoaGroup + '"}'
                }
            )
            .create()
            .getRecord();
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                Opportunity.Name => ValueProviderBuilder.provideUniqueString('test opportunity 1')
            })
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'Test Quote 1',
                    Quote.OpportunityId => opp.Id
                }
            )
            .create()
            .getRecord();

        DQ_Deal_Qualification__c testDqRecord = (DQ_Deal_Qualification__c) new SObjectBuilder(DQ_Deal_Qualification__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                DQ_Deal_Qualification__c.Opportunity__c => opp.Id,
                DQ_Deal_Qualification__c.Status__c => QuoteHelper.STATUS_NEW_CUSTOMER,
                DQ_Deal_Qualification__c.Charge_Term__c => 'Annual',
                DQ_Deal_Qualification__c.Renewal_Term__c => '12',
                DQ_Deal_Qualification__c.Initial_Term__c => '12',
                DQ_Deal_Qualification__c.Special_Terms__c => QuoteHelper.FREE_MONTH_2,
                DQ_Deal_Qualification__c.Deal_Size__c => 500,
                DQ_Deal_Qualification__c.New_Annual_Recurring_Charges__c => 50,
                DQ_Deal_Qualification__c.Free_Shipping_Terms_Options__c => QuoteHelper.SHIPPING_OPTION_OVERNIGHT,
                DQ_Deal_Qualification__c.IsDQCreatedFromCPQOpp__c => false,
                DQ_Deal_Qualification__c.Quote__c => testQuote.Id
            })
            .quantity(2)
            .create()
            .getRecord();

        List<DQ_Deal_Qualification_History__c> testDqHistoryRecords =
            (List<DQ_Deal_Qualification_History__c>) new SObjectBuilder(DQ_Deal_Qualification_History__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Deal_Qualification_History__c.Deal_Qualification__c => testDqRecord.Id,
                    DQ_Deal_Qualification_History__c.Status__c => QuoteHelper.APPROVAL_STATUS_APPROVED
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

        Test.startTest();
            List<DQ_Deal_Qualification_History__c> ApprovedDQHistory = new DealQualificationHistorySelector()
                .selectApprovedDQHistory( testDqRecord.Id )
                .executeQuery();
            System.assertEquals(1,ApprovedDQHistory.size(), 'method should return 1 DQ History');
        Test.stopTest();
    }

    @isTest
    private static void testSelectDQs() {
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                Opportunity.Name => ValueProviderBuilder.provideUniqueString('test opportunity')
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Pricebook2Id => Test.getStandardPriceBookId()
            })
            .create()
            .getRecord();

        DQ_Deal_Qualification__c testDqRecord = (DQ_Deal_Qualification__c) new SObjectBuilder(DQ_Deal_Qualification__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                DQ_Deal_Qualification__c.Opportunity__c => opp.Id,
                DQ_Deal_Qualification__c.Quote__c => qt.Id,
                DQ_Deal_Qualification__c.Status__c => 'New'
            })
            .create()
            .getRecord();

        Test.startTest();
            DQ_Deal_Qualification__c dq = (DQ_Deal_Qualification__c)  new ListOptional(new DealQualificationSelector()
                .selectDQs()
                .executeQuery()
            ).getFirst();
        Test.stopTest();

        System.assertNotEquals(null, dq, 'Record should be returned');
    }
}