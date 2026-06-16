@isTest
private class Test_DQServiceHelper {

    private static User createTestUser() {
        return (User) new SObjectBuilder(User.SObjectType)
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
    }

    @isTest
    static void testGetDealQualificationWithEmptyParams() {
        String resultJson = DQServiceHelper.getDealQualificationJson(null);
        DQServiceHelper.DQResponse resp = (DQServiceHelper.DQResponse) JSON.deserialize(resultJson, DQServiceHelper.DQResponse.class);
        System.assertEquals(
            null,
            resp.dqRecord,
            'method should return structure with empty BillingWrappers.DealQualification record ' +
            'in json format if passed argument is null'
        );


        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => ValueProviderBuilder.provideUniqueString('test account')
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => acc.Id,
                Opportunity.Name => ValueProviderBuilder.provideUniqueString('test opportunity')
            })
            .create()
            .getRecord();

        resultJson = DQServiceHelper.getDealQualificationJson(opp.Id);
        resp = (DQServiceHelper.DQResponse) JSON.deserialize(resultJson, DQServiceHelper.DQResponse.class);
        System.assertEquals(
            null,
            resp.dqRecord,
            'method should return structure with empty BillingWrappers.DealQualification record ' +
            'in json format if DQ_Deal_Qualification__c is not exist for opportunity'
        );
    }

    @isTest
    static void testGetDealQualification() {

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => ValueProviderBuilder.provideUniqueString('test account')
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => acc.Id,
                Opportunity.Name => ValueProviderBuilder.provideUniqueString('test opportunity')
            })
            .create()
            .getRecord();

        DQ_Deal_Qualification__c testDqRecord = (DQ_Deal_Qualification__c) new SObjectBuilder(DQ_Deal_Qualification__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                DQ_Deal_Qualification__c.Opportunity__c => opp.Id,
                DQ_Deal_Qualification__c.Status__c => 'New',
                DQ_Deal_Qualification__c.Charge_Term__c => 'Monthly',
                DQ_Deal_Qualification__c.Renewal_Term__c => '12',
                DQ_Deal_Qualification__c.Initial_Term__c => '12',
                DQ_Deal_Qualification__c.CC_Initial_Term__c => '12',
                DQ_Deal_Qualification__c.Special_Terms__c => '2 Free Months of Service',
                DQ_Deal_Qualification__c.CC_Special_Terms__c => '2 Free Months of Service',
                DQ_Deal_Qualification__c.Deal_Size__c => 500,
                DQ_Deal_Qualification__c.New_Annual_Recurring_Charges__c => 50,
                DQ_Deal_Qualification__c.Free_Shipping_Terms_Options__c => DQServiceHelper.TWO_DAY_OPTION,
                DQ_Deal_Qualification__c.IsDQCreatedFromCPQOpp__c => false,
                DQ_Deal_Qualification__c.Overall_Discount_Recurring__c => 0.5

            })
            .create()
            .getRecord();

        Test.startTest();
            String resultJson = DQServiceHelper.getDealQualificationJson(opp.Id);
        Test.stopTest();

        DQServiceHelper.DQResponse resp = (DQServiceHelper.DQResponse) JSON.deserialize(resultJson, DQServiceHelper.DQResponse.class);
        BillingWrappers.DealQualification dqRecord = resp.dqRecord;

        System.assertEquals(
            opp.Id,
            dqRecord.opportunityId,
            'method should return DQ_Deal_Qualification__c for corresponding opportunity'
        );
        System.assertEquals(
            testDqRecord.Id,
            dqRecord.dqId,
            'BillingWrappers.DealQualification.dqId field value should be equal to DQ_Deal_Qualification__c Id'
        );
        System.assertEquals(
            testDqRecord.Charge_Term__c,
            dqRecord.chargeTerm,
            'BillingWrappers.DealQualification.chargeTerm field value should be equal to DQ_Deal_Qualification__c.Charge_Term__c'
        );
        System.assertEquals(
            testDqRecord.Deal_Size__c,
            dqRecord.dealSize,
            'BillingWrappers.DealQualification.dealSize field value should be equal to DQ_Deal_Qualification__c.Deal_Size__c'
        );
        System.assertEquals(
            testDqRecord.Free_Shipping_Terms_Options__c,
            dqRecord.freeShippingTermsOptions,
            'BillingWrappers.DealQualification.freeShippingTermsOptions field value should be equal to DQ_Deal_Qualification__c.Free_Shipping_Terms_Options__c'
        );
        System.assertEquals(
            testDqRecord.Initial_Term__c,
            dqRecord.initialTerm,
            'BillingWrappers.DealQualification.initialTerm field value should be equal to DQ_Deal_Qualification__c.Initial_Term__c'
        );
        System.assertEquals(
            testDqRecord.CC_Initial_Term__c,
            dqRecord.initialTermCC,
            'BillingWrappers.DealQualification.initialTermCC field value should be equal to DQ_Deal_Qualification__c.CC_Initial_Term__c'
        );
        System.assertEquals(
            testDqRecord.IsDQCreatedFromCPQOpp__c,
            dqRecord.isDQCreatedFromCPQ,
            'BillingWrappers.DealQualification.isDQCreatedFromCPQ field value should be equal to DQ_Deal_Qualification__c.IsDQCreatedFromCPQOpp__c'
        );
        System.assertEquals(
            testDqRecord.New_Annual_Recurring_Charges__c,
            dqRecord.newAnnualRecurringCharges,
            'BillingWrappers.DealQualification.newAnnualRecurringCharges field value should be equal to DQ_Deal_Qualification__c.New_Annual_Recurring_Charges__c'
        );
        System.assertEquals(
            testDqRecord.Renewal_Term__c,
            dqRecord.renewalTerm,
            'BillingWrappers.DealQualification.renewalTerm field value should be equal to DQ_Deal_Qualification__c.Renewal_Term__c'
        );
        System.assertEquals(
            testDqRecord.Special_Terms__c,
            dqRecord.specialTerms,
            'BillingWrappers.DealQualification.specialTerms field value should be equal to DQ_Deal_Qualification__c.Special_Terms__c'
        );
        System.assertEquals(
            testDqRecord.CC_Special_Terms__c,
            dqRecord.specialTermsCC,
            'BillingWrappers.DealQualification.specialTermsCC field value should be equal to DQ_Deal_Qualification__c.CC_Special_Terms__c'
        );
        System.assertEquals(
            testDqRecord.Status__c,
            dqRecord.status,
            'BillingWrappers.DealQualification.status field value should be equal to DQ_Deal_Qualification__c.Status__c'
        );
        System.assertEquals(
            testDqRecord.Overall_Discount_Recurring__c,
            dqRecord.overallDiscountRecurring,
            'BillingWrappers.DealQualification.overallDiscountRecurring field value should be equal to DQ_Deal_Qualification__c.Overall_Discount_Recurring__c'
        );
    }

    @isTest
    static void testSaveDealQualificationWithEmptyParams() {
        String resultJson = DQServiceHelper.saveDqRecord(null);
        DQServiceHelper.DQResponse resp = (DQServiceHelper.DQResponse) JSON.deserialize(resultJson, DQServiceHelper.DQResponse.class);
        System.assertEquals(
            null,
            resp.dqRecord,
            'method should return structure with empty BillingWrappers.DealQualification record ' +
            'in json format if passed argument is null'
        );

        resultJson = DQServiceHelper.saveDqRecord(new BillingWrappers.DQParams());
        resp = (DQServiceHelper.DQResponse) JSON.deserialize(resultJson, DQServiceHelper.DQResponse.class);
        System.assertEquals(
            null,
            resp.dqRecord,
            'method should return structure with empty BillingWrappers.DealQualification record ' +
            'in json format if dqRecord passed as argument is null '
        );
    }

    @isTest
    static void testSaveDealQualification() {

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => ValueProviderBuilder.provideUniqueString('test account')
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => acc.Id,
                Opportunity.Name => ValueProviderBuilder.provideUniqueString('test opportunity')
            })
            .create()
            .getRecord();

        DQ_Deal_Qualification__c testDqRecord = (DQ_Deal_Qualification__c) new SObjectBuilder(DQ_Deal_Qualification__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                DQ_Deal_Qualification__c.Opportunity__c => opp.Id,
                DQ_Deal_Qualification__c.Status__c => 'New',
                DQ_Deal_Qualification__c.Charge_Term__c => 'Annual',
                DQ_Deal_Qualification__c.Renewal_Term__c => '12',
                DQ_Deal_Qualification__c.Initial_Term__c => '12',
                DQ_Deal_Qualification__c.Special_Terms__c => '2 Free Months of Service',
                DQ_Deal_Qualification__c.Deal_Size__c => 500,
                DQ_Deal_Qualification__c.New_Annual_Recurring_Charges__c => 50,
                DQ_Deal_Qualification__c.IsDQCreatedFromCPQOpp__c => false
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.OpportunityId => opp.Id,
                Quote.Name => ValueProviderBuilder.provideUniqueString('test quote'),
                Quote.Payment_Plan__c => 'Monthly',
                Quote.Term_months__c => '36',
                Quote.Initial_Term_months__c => '24',
                Quote.Special_Terms__c => '5 Free Months of Service',
                Quote.Total_MRR_New__c => 1000,
                Quote.Monthly_Recurring_Revenue__c => 100
            })
            .create()
            .getRecord();

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => ValueProviderBuilder.provideUniqueString('test_product')
            })
            .create()
            .getRecord();

        BillingWrappers.DealQualification dqRecord = new BillingWrappers.DealQualification(testDqRecord);
        dqRecord.status = 'Revision Pending';
        dqRecord.chargeTerm = 'Monthly';
        dqRecord.renewalTerm = '24';
        dqRecord.initialTerm = '24';
        dqRecord.specialTerms = '4 Free Months of Service';
        dqRecord.dealSize = 700;
        dqRecord.newAnnualRecurringCharges = 100;

        BillingWrappers.DealQualificationDiscount testDiscount = new BillingWrappers.DealQualificationDiscount();
        testDiscount.product2Id = testProduct.Id;
        testDiscount.recordTypeId = DQServiceHelper.DQ_SALES_RECORD_TYPE_ID;
        testDiscount.originalPackageId = '555';
        testDiscount.originalPackageVersion = '2';
        testDiscount.originalPackageName = 'test package';
        testDiscount.packageName = 'test package';
        testDiscount.productCategory = 'GOA_RC_Office';
        testDiscount.discountType = QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE;
        testDiscount.discount = 15;
        testDiscount.quantity = 50;
        testDiscount.isDataExist = true;

        BillingWrappers.DQParams params = new BillingWrappers.DQParams();
        params.dqRecord = dqRecord;
        params.dqDiscounts.add(testDiscount);

        Test.startTest();
            String resultJson = DQServiceHelper.saveDqRecord(params);
        Test.stopTest();

        List<DQ_Deal_Qualification__c> dqList = new DealQualificationSelector()
            .selectDQForSync(opp.Id)
            .executeQuery();

        DQ_Deal_Qualification__c reselectedDQRecord = dqList.get(0);

        System.assertEquals(
            dqRecord.status,
            reselectedDQRecord.Status__c,
            'DQ_Deal_Qualification__c.Status__c field value should be updated and should match the status parameter'
        );
        System.assertEquals(
            dqRecord.chargeTerm,
            reselectedDQRecord.Charge_Term__c,
            'DQ_Deal_Qualification__c.Charge_Term__c field value should be updated and should match the chargeTerm parameter'
        );
        System.assertEquals(
            dqRecord.renewalTerm,
            reselectedDQRecord.Renewal_Term__c,
            'DQ_Deal_Qualification__c.Renewal_Term__c field value should be updated and should match the renewalTerm parameter'
        );
        System.assertEquals(
            dqRecord.initialTerm,
            reselectedDQRecord.Initial_Term__c,
            'DQ_Deal_Qualification__c.Initial_Term__c field value should be updated and should match the initialTerm parameter'
        );
        System.assertEquals(
            dqRecord.specialTerms,
            reselectedDQRecord.Special_Terms__c,
            'DQ_Deal_Qualification__c.Special_Terms__c field value should be updated and should match the specialTerms parameter'
        );
        System.assertEquals(
            dqRecord.dealSize,
            reselectedDQRecord.Deal_Size__c,
            'DQ_Deal_Qualification__c.Deal_Size__c field value should be updated and should match the dealSize parameter'
        );
        System.assertEquals(
            dqRecord.newAnnualRecurringCharges,
            reselectedDQRecord.New_Annual_Recurring_Charges__c,
            'DQ_Deal_Qualification__c.New_Annual_Recurring_Charges__c field value should be updated and should match the newAnnualRecurringCharges parameter'
        );

        List<DQ_Deal_Qualification_Discounts__c> reselectedDiscounts = reselectedDQRecord.Deal_Qualification_Discounts__r;
        System.assertEquals(1, reselectedDiscounts.size(), '1 new discount should be created');
    }

    @isTest
    static void testSyncDealQualificationWithEmptyParams() {
        String resultJson = DQServiceHelper.syncDealQualificationJson(null, null, false);
        DQServiceHelper.DQResponse resp = (DQServiceHelper.DQResponse) JSON.deserialize(resultJson, DQServiceHelper.DQResponse.class);
        System.assertEquals(
            null,
            resp.dqRecord,
            'method should return structure with empty BillingWrappers.DealQualification record ' +
            'in json format if passed arguments is empty'
        );

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Id => ValueProviderBuilder.provideDummyId(Quote.SObjectType)
            })
            .build()
            .getRecord();

        resultJson = DQServiceHelper.syncDealQualificationJson(testQuote.Id, null, false);
        resp = (DQServiceHelper.DQResponse) JSON.deserialize(resultJson, DQServiceHelper.DQResponse.class);
        System.assertEquals(
            null,
            resp.dqRecord,
            'method should return structure with empty BillingWrappers.DealQualification record ' +
            'in json format if there is no quote with such id'
        );
    }

    @isTest
    static void testSyncDealQualificationInsert() {

        User testOppOwner = createTestUser();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => ValueProviderBuilder.provideUniqueString('test account')
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => acc.Id,
                Opportunity.Name => ValueProviderBuilder.provideUniqueString('test opportunity'),
                Opportunity.OwnerId => testOppOwner.Id
            })
            .create()
            .getRecord();

        Triggers.switchOff();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.OpportunityId => opp.Id,
                Quote.Name => ValueProviderBuilder.provideUniqueString('test quote'),
                Quote.Payment_Plan__c => 'Monthly',
                Quote.Term_months__c => '12',
                Quote.Initial_Term_months__c => '12',
                Quote.Special_Terms__c => '6 Free Months of Service',
                Quote.Total_MRR_New__c => 720,
                Quote.Monthly_Recurring_Revenue__c => 47,
                Quote.Shipping_Option__c => QuoteHelper.SHIPPING_OPTION_OVERNIGHT,
                Quote.OverallDiscretion__c => 0.5,
                Quote.JustificationAndDescription__c => 'test justification and description',
                Quote.Pricebook2Id => Test.getStandardPriceBookId(),
                Quote.FreeShippingTerms__c => QuoteHelper.FREESHIPPING,
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo()
            })
            .create()
            .getRecord();

        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Feature_Toggle__c.Shipping_Tab_New_Business__c => true
            })
            .create();

        Quote qtCC = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_CC,
                Quote.Name => ValueProviderBuilder.provideUniqueString('test quote'),
                Quote.Payment_Plan__c => 'Monthly',
                Quote.Term_months__c => '24',
                Quote.Initial_Term_months__c => '24',
                Quote.Special_Terms__c => '6 Free Months of Service',
                Quote.Total_MRR_New__c => 800,
                Quote.Monthly_Recurring_Revenue__c => 50,
                Quote.Shipping_Option__c => QuoteHelper.SHIPPING_OPTION_OVERNIGHT,
                Quote.OverallDiscretion__c => 0.7
            })
            .create()
            .getRecord();

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Product2.Name => ValueProviderBuilder.provideUniqueString('test product'),
                    Product2.IsActive => true,
                    Product2.Sub_Category__c => 'Main',
                    Product2.GOA_Group_V3__c => '{"regular":"GOA_RC_Office","contracted":"GOA_RC_Office"}'
                }
            )
            .create()
            .getRecord();

        PriceBookEntry pbe = (PriceBookEntry) new SobjectBuilder(PriceBookEntry.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    PriceBookEntry.Product2Id => testProduct.Id,
                    PriceBookEntry.UnitPrice => 100,
                    PriceBookEntry.IsActive => true,
                    PriceBookEntry.Pricebook2Id => Test.getStandardPriceBookId()
                }
            )
            .create()
            .getRecord();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    QuoteLineItem.QuoteId => qt.Id,
                    QuoteLineItem.PriceBookEntryId => pbe.Id,
                    QuoteLineItem.Product2Id => testProduct.Id,
                    QuoteLineItem.UnitPrice => 100,
                    QuoteLineItem.Discount_type__c => QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE,
                    QuoteLineItem.Quantity => 10,
                    QuoteLineItem.Discount => 24
                }
            )
            .create()
            .getRecord();

        CustomAddress__c ca = (CustomAddress__c) new SObjectBuilder(CustomAddress__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                CustomAddress__c.AddressLine__c => '10 Avenue Jean Médecin',
                CustomAddress__c.City__c => 'Nice',
                CustomAddress__c.Country__c => 'France',
                CustomAddress__c.State__c => 'Nice',
                CustomAddress__c.PostalCode__c => '06000'
            })
            .create()
            .getRecord();

        CustomAddressAssignments__c caa = (CustomAddressAssignments__c) new SObjectBuilder(CustomAddressAssignments__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                CustomAddressAssignments__c.AttentionTo__c => 'Test France',
                CustomAddressAssignments__c.CustomAddress__c => ca.Id,
                CustomAddressAssignments__c.Quantity__c => 2,
                CustomAddressAssignments__c.QuoteLineItem__c => qli.Id,
                CustomAddressAssignments__c.Type__c => 'Overnight'})
            .create()
            .getRecord();

        Triggers.switchOn();

        Test.startTest();
            String testStatus = 'New';
            String resultJson = DQServiceHelper.syncDealQualificationJson(qt.Id, testStatus, false);
            List<DQ_Deal_Qualification__c> dqList = new DealQualificationSelector()
            .selectDQForSync(opp.Id)
            .executeQuery();

        System.assertEquals(
            1,
            dqList.size(),
            'new DQ_Deal_Qualification__c should be created'
        );
        DQ_Deal_Qualification__c reselectedDQRecord = dqList.get(0);
        System.assertEquals(
            qt.Id,
            reselectedDQRecord.Quote__c,
            'DQ_Deal_Qualification__c.Quote__c field value should match the quoteId parameter'
        );

        DQServiceHelper.DQResponse resp = (DQServiceHelper.DQResponse) JSON.deserialize(resultJson, DQServiceHelper.DQResponse.class);

        BillingWrappers.DealQualification dqRecord = resp.dqRecord;

        System.assertEquals(
            qt.OpportunityId,
            dqRecord.opportunityId,
            'DQ_Deal_Qualification__c record should be associated with the same Opportunity as the Quote record'
        );
        System.assertEquals(
            testStatus,
            dqRecord.status,
            'DQ_Deal_Qualification__c.Status__c field value should match the status parameter'
        );
        System.assertEquals(
            qt.Payment_Plan__c,
            dqRecord.chargeTerm,
            'DQ_Deal_Qualification__c.Charge_Term__c field value should match the Quote.Payment_Plan__c field value'
        );
        System.assertEquals(
            qt.Term_months__c,
            dqRecord.renewalTerm,
            'DQ_Deal_Qualification__c.Renewal_Term__c field value should match the Quote.Term_months__c field value'
        );
        System.assertEquals(
            qt.Initial_Term_months__c,
            dqRecord.initialTerm,
            'DQ_Deal_Qualification__c.Initial_Term__c field value should match the Quote.Initial_Term_months__c field value'
        );
        System.assertEquals(
            qtCC.Initial_Term_months__c,
            dqRecord.initialTermCC,
            'DQ_Deal_Qualification__c.CC_Initial_Term__c field value should match the CC Quote.Initial_Term_months__c field value if CC Quote exists'
        );
        System.assertEquals(
            qt.Special_Terms__c,
            dqRecord.specialTerms,
            'DQ_Deal_Qualification__c.Special_Terms__c field value should match the Quote.Special_Terms__c field value'
        );
        System.assertEquals(
            qtCC.Special_Terms__c,
            dqRecord.specialTermsCC,
            'DQ_Deal_Qualification__c.CC_Special_Terms__c field value should match the CC Quote.Special_Terms__c field value if CC Quote exists'
        );
        System.assertEquals(
            qt.Total_MRR_New__c.setScale(2),
            dqRecord.dealSize,
            'DQ_Deal_Qualification__c.Deal_Size__c field value should match the Quote.Total_MRR_New__c.setScale(2) field value'
        );
        System.assertEquals(
            qt.Monthly_Recurring_Revenue__c,
            dqRecord.newAnnualRecurringCharges,
            'DQ_Deal_Qualification__c.New_Annual_Recurring_Charges__c field value should match the Quote.Monthly_Recurring_Revenue__c field value'
        );
        System.assertEquals(
            false,
            dqRecord.isDQCreatedFromCPQ,
            'DQ_Deal_Qualification__c.IsDQCreatedFromCPQOpp__c field value should be false'
        );
        System.assert(
            testOppOwner.Email.equalsIgnoreCase(dqRecord.opportunityOwnerEmail),
            'DQ_Deal_Qualification__c.Opportunity_Owner_s_Email__c field value should match the Opportunity.Opportunity_Owner_Email__c field value'
        );
        System.assertEquals(
            qt.JustificationAndDescription__c,
            dqRecord.justification,
            'DQ_Deal_Qualification__c.Justification_Description__c field value should match the Quote.JustificationAndDescription__c field value'
        );
        System.assertEquals(
            DQServiceHelper.FREE_SHIPPING_OPTION,
            dqRecord.freeShippingTermsOptions,
            'DQ_Deal_Qualification__c.Free_Shipping_Terms_Options__c should be \'Free shipping\' when shipping method(CustomAddressAssignments__c.Type__c) = \'2 Day\' or \'Overnight\' and Quote.FreeShippingTerms__c = \'Free Shipping\''
        );

        Triggers.switchOff();
        qt.FreeShippingTerms__c = '2-day Shipping for Ground Pricing';
        update qt;
        Triggers.switchOn();

        resultJson = DQServiceHelper.syncDealQualificationJson(qt.Id, testStatus, false);
        resp = (DQServiceHelper.DQResponse) JSON.deserialize(resultJson, DQServiceHelper.DQResponse.class);
        dqRecord = resp.dqRecord;
        Boolean isFreeShippingOption = DQServiceHelper.isFreeShippingOption(qt);

        Test.stopTest();

        System.assertEquals(
            null,
            dqRecord.freeShippingTermsOptions,
            'DQ_Deal_Qualification__c.Free_Shipping_Terms_Options__c should be null when shipping method(CustomAddressAssignments__c.Type__c) != \'2 Day\' or \'Overnight\' or Quote.FreeShippingTerms__c != \'Free Shipping\''
        );

        System.assertEquals(
            true,
            isFreeShippingOption,
            'isFreeShippingOption should return true'
        );
    }

    @isTest
    static void testSyncDealQualificationInsertPrm() {

        new SObjectBuilder(Feature_Toggle__c.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Feature_Toggle__c.Shipping_Tab_New_Business__c => true
                })
                .create();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => ValueProviderBuilder.provideUniqueString('test account')
            })
            .create()
            .getRecord();

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '1234567890',
                    Contact.Technical_Certification__c => 'Certified Expert',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();

        User portalUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.Username => UserHelper.getUniqueUserName(),
                    User.LastName => ValueProviderBuilder.provideUniqueString('LastName'),
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'Internal RC Community - Partner Admin'].Id,
                    User.Email => ValueProviderBuilder.provideUniqueEmail(),
                    User.Alias => StringHelper.getRandomString(8),
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.LanguageLocaleKey => 'en_US',
                    User.Region__c => 'US',
                    User.Sub_Region__c => 'All',
                    User.ContactId => con.Id
                }
            )
            .create()
            .getRecord();

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Product2.Name => ValueProviderBuilder.provideUniqueString('test product'),
                    Product2.IsActive => true,
                    Product2.Sub_Category__c => 'Main',
                    Product2.GOA_Group_V3__c => '{"regular":"GOA_RC_Office","contracted":"GOA_RC_Office"}'
                }
            )
            .create()
            .getRecord();

        PriceBookEntry pbe = (PriceBookEntry) new SobjectBuilder(PriceBookEntry.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    PriceBookEntry.Product2Id => testProduct.Id,
                    PriceBookEntry.UnitPrice => 100,
                    PriceBookEntry.IsActive => true,
                    PriceBookEntry.Pricebook2Id => Test.getStandardPriceBookId()
                }
            )
            .create()
            .getRecord();

        System.runAs(portalUser) {

            Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    Opportunity.AccountId => acc.Id,
                    Opportunity.Name => ValueProviderBuilder.provideUniqueString('test opportunity'),
                    Opportunity.OwnerId => portalUser.Id
                })
                .create()
                .getRecord();

            Triggers.switchOff();

            Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    Quote.OpportunityId => opp.Id,
                    Quote.Name => ValueProviderBuilder.provideUniqueString('test quote'),
                    Quote.Payment_Plan__c => 'Monthly',
                    Quote.Term_months__c => '12',
                    Quote.Initial_Term_months__c => '12',
                    Quote.Special_Terms__c => '6 Free Months of Service',
                    Quote.Total_MRR_New__c => 720,
                    Quote.Monthly_Recurring_Revenue__c => 47,
                    Quote.Shipping_Option__c => QuoteHelper.SHIPPING_OPTION_OVERNIGHT,
                    Quote.OverallDiscretion__c => 0.5,
                    Quote.JustificationAndDescription__c => 'test justification and description',
                    Quote.Pricebook2Id => Test.getStandardPriceBookId(),
                    Quote.FreeShippingTerms__c => QuoteHelper.FREESHIPPING,
                    Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo()
                })
                .create()
                .getRecord();

            QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        QuoteLineItem.QuoteId => qt.Id,
                        QuoteLineItem.PriceBookEntryId => pbe.Id,
                        QuoteLineItem.Product2Id => testProduct.Id,
                        QuoteLineItem.UnitPrice => 100,
                        QuoteLineItem.Discount_type__c => QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE,
                        QuoteLineItem.Quantity => 10,
                        QuoteLineItem.Discount => 24
                    }
                )
                .create()
                .getRecord();

            Triggers.switchOn();

            Test.startTest();
                String testStatus = 'New';
                String resultJson = DQServiceHelper.syncDealQualificationJson(qt.Id, testStatus, true);
                List<DQ_Deal_Qualification__c> dqList = new DealQualificationSelector()
                    .selectDQForSync(opp.Id)
                    .executeQuery();
            Test.stopTest();

            System.assertEquals(
                1,
                dqList.size(),
                'new DQ_Deal_Qualification__c should be created'
            );
            DQ_Deal_Qualification__c reselectedDQRecord = dqList.get(0);
            System.assertEquals(
                qt.Id,
                reselectedDQRecord.Quote__c,
                'DQ_Deal_Qualification__c.Quote__c field value should match the quoteId parameter'
            );

            DQServiceHelper.DQResponse resp = (DQServiceHelper.DQResponse) JSON.deserialize(resultJson, DQServiceHelper.DQResponse.class);

            BillingWrappers.DealQualification dqRecord = resp.dqRecord;

            System.assertEquals(
                qt.OpportunityId,
                dqRecord.opportunityId,
                'DQ_Deal_Qualification__c record should be associated with the same Opportunity as the Quote record'
            );
            System.assertEquals(
                testStatus,
                dqRecord.status,
                'DQ_Deal_Qualification__c.Status__c field value should match the status parameter'
            );
            System.assertEquals(
                qt.Payment_Plan__c,
                dqRecord.chargeTerm,
                'DQ_Deal_Qualification__c.Charge_Term__c field value should match the Quote.Payment_Plan__c field value'
            );
            System.assertEquals(
                qt.Term_months__c,
                dqRecord.renewalTerm,
                'DQ_Deal_Qualification__c.Renewal_Term__c field value should match the Quote.Term_months__c field value'
            );
            System.assertEquals(
                qt.Initial_Term_months__c,
                dqRecord.initialTerm,
                'DQ_Deal_Qualification__c.Initial_Term__c field value should match the Quote.Initial_Term_months__c field value'
            );
            System.assertEquals(
                qt.Special_Terms__c,
                dqRecord.specialTerms,
                'DQ_Deal_Qualification__c.Special_Terms__c field value should match the Quote.Special_Terms__c field value'
            );
            System.assertEquals(
                qt.Total_MRR_New__c.setScale(2),
                dqRecord.dealSize,
                'DQ_Deal_Qualification__c.Deal_Size__c field value should match the Quote.Total_MRR_New__c.setScale(2) field value'
            );
            System.assertEquals(
                qt.Monthly_Recurring_Revenue__c,
                dqRecord.newAnnualRecurringCharges,
                'DQ_Deal_Qualification__c.New_Annual_Recurring_Charges__c field value should match the Quote.Monthly_Recurring_Revenue__c field value'
            );
            System.assertEquals(
                false,
                dqRecord.isDQCreatedFromCPQ,
                'DQ_Deal_Qualification__c.IsDQCreatedFromCPQOpp__c field value should be false'
            );
            System.assert(
                portalUser.Email.equalsIgnoreCase(dqRecord.opportunityOwnerEmail),
                'DQ_Deal_Qualification__c.Opportunity_Owner_s_Email__c field value should match the Opportunity.Opportunity_Owner_Email__c field value'
            );
            System.assertEquals(
                qt.JustificationAndDescription__c,
                dqRecord.justification,
                'DQ_Deal_Qualification__c.Justification_Description__c field value should match the Quote.JustificationAndDescription__c field value'
            );
        }
    }

     @isTest
    static void testSyncDealQualificationUpdate() {

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => ValueProviderBuilder.provideUniqueString('test account')
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => acc.Id,
                Opportunity.Name => ValueProviderBuilder.provideUniqueString('test opportunity')
            })
            .create()
            .getRecord();

        DQ_Deal_Qualification__c testDqRecord = (DQ_Deal_Qualification__c) new SObjectBuilder(DQ_Deal_Qualification__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                DQ_Deal_Qualification__c.Opportunity__c => opp.Id,
                DQ_Deal_Qualification__c.Status__c => 'New',
                DQ_Deal_Qualification__c.Charge_Term__c => 'Annual',
                DQ_Deal_Qualification__c.Renewal_Term__c => '12',
                DQ_Deal_Qualification__c.Initial_Term__c => '12',
                DQ_Deal_Qualification__c.Special_Terms__c => '2 Free Months of Service',
                DQ_Deal_Qualification__c.Deal_Size__c => 500,
                DQ_Deal_Qualification__c.New_Annual_Recurring_Charges__c => 50,
                DQ_Deal_Qualification__c.Justification_Description__c => 'test justification on DQ record'
            })
            .create()
            .getRecord();

            String pInfo = NGBSTestDataGenerator.generateQuotePackageInfo();

            Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    Quote.OpportunityId => opp.Id,
                    Quote.Name => ValueProviderBuilder.provideUniqueString('test quote'),
                    Quote.Payment_Plan__c => 'Monthly',
                    Quote.Term_months__c => '36',
                    Quote.Initial_Term_months__c => '24',
                    Quote.Special_Terms__c => '5 Free Months of Service',
                    Quote.Total_MRR_New__c => 1000,
                    Quote.Monthly_Recurring_Revenue__c => 100,
                    Quote.Package_Info__c => pInfo,
                    Quote.Shipping_Option__c => QuoteHelper.SHIPPING_OPTION_OVERNIGHT,
                    Quote.OverallDiscretion__c => 0.5,
                    Quote.JustificationAndDescription__c => 'test justification on Quote record',
                    Quote.FreeShippingTerms__c => QuoteHelper.FREESHIPPING
                })
                .create()
                .getRecord();

            Quote qtCC = (Quote) new SObjectBuilder(Quote.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    Quote.OpportunityId => opp.Id,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_CC,
                    Quote.Name => ValueProviderBuilder.provideUniqueString('test quote'),
                    Quote.Payment_Plan__c => 'Monthly',
                    Quote.Term_months__c => '24',
                    Quote.Initial_Term_months__c => '24',
                    Quote.Special_Terms__c => '6 Free Months of Service',
                    Quote.Total_MRR_New__c => 800,
                    Quote.Monthly_Recurring_Revenue__c => 50,
                    Quote.Shipping_Option__c => QuoteHelper.SHIPPING_OPTION_OVERNIGHT,
                    Quote.OverallDiscretion__c => 0.7
                })
                .create()
                .getRecord();

            Test.startTest();

            String testStatus = 'Pending Approval';
            String resultJson = DQServiceHelper.syncDealQualificationJson(qt.Id, testStatus, false);

            DQServiceHelper.DQResponse resp = (DQServiceHelper.DQResponse) JSON.deserialize(resultJson, DQServiceHelper.DQResponse.class);

            List<DQ_Deal_Qualification__c> dqList = new DealQualificationSelector()
                .selectDQForSync(opp.Id)
                .executeQuery();

            DQ_Deal_Qualification__c reselectedDQRecord = dqList.get(0);

            System.assertEquals(
                qt.Id,
                reselectedDQRecord.Quote__c,
                'DQ_Deal_Qualification__c.Quote__c field value should match the quoteId parameter'
            );
            System.assertEquals(
                testStatus,
                reselectedDQRecord.Status__c,
                'DQ_Deal_Qualification__c.Status__c field value should match the status parameter'
            );
            System.assertEquals(
                qt.Payment_Plan__c,
                reselectedDQRecord.Charge_Term__c,
                'DQ_Deal_Qualification__c.Charge_Term__c field value should match the Quote.Payment_Plan__c field value'
            );
            System.assertEquals(
                qt.Term_months__c,
                reselectedDQRecord.Renewal_Term__c,
                'DQ_Deal_Qualification__c.Renewal_Term__c field value should match the Quote.Term_months__c field value'
            );
            System.assertEquals(
                qt.Initial_Term_months__c,
                reselectedDQRecord.Initial_Term__c,
                'DQ_Deal_Qualification__c.Initial_Term__c field value should match the Quote.Initial_Term_months__c field value'
            );
            System.assertEquals(
                qtCC.Initial_Term_months__c,
                reselectedDQRecord.CC_Initial_Term__c,
                'DQ_Deal_Qualification__c.CC_Initial_Term__c field value should match the CC Quote.Initial_Term__c field value if CC Quote exists'
            );
            System.assertEquals(
                qt.Total_MRR_New__c.setScale(2),
                reselectedDQRecord.Deal_Size__c,
                'DQ_Deal_Qualification__c.Deal_Size__c field value should match the Quote.Total_MRR_New__c.setScale(2) field value'
            );
            System.assertEquals(
                qt.Special_Terms__c,
                reselectedDQRecord.Special_Terms__c,
                'DQ_Deal_Qualification__c.Special_Terms__c field value should match the Quote.Special_Terms__c field value'
            );
            System.assertEquals(
                qtCC.Special_Terms__c,
                reselectedDQRecord.CC_Special_Terms__c,
                'DQ_Deal_Qualification__c.CC_Special_Terms__c field value should match the CC Quote.Special_Terms__c field value if CC Quote exists'
            );
            System.assertEquals(
                qt.Monthly_Recurring_Revenue__c,
                reselectedDQRecord.New_Annual_Recurring_Charges__c,
                'DQ_Deal_Qualification__c.New_Annual_Recurring_Charges__c field value should match the Quote.Monthly_Recurring_Revenue__c field value'
            );
            System.assertEquals(
                qt.JustificationAndDescription__c,
                reselectedDQRecord.Justification_Description__c,
                'DQ_Deal_Qualification__c.Justification_Description__c field value should match the Quote.JustificationAndDescription__c field value'
            );

            System.assertEquals(
                DQServiceHelper.FREE_SHIPPING_OPTION,
                reselectedDQRecord.Free_Shipping_Terms_Options__c,
                'DQ_Deal_Qualification__c.Free_Shipping_Terms_Options__c should be \'Free shipping\' when Quote.Shipping_Option__c = \'2 Day\' or \'Overnight\' and Quote.FreeShippingTerms__c = \'Free Shipping\''
            );

            qt.FreeShippingTerms__c = '2-day Shipping for Ground Pricing';
            update qt;

            resultJson = DQServiceHelper.syncDealQualificationJson(qt.Id, testStatus, false);
            resp = (DQServiceHelper.DQResponse) JSON.deserialize(resultJson, DQServiceHelper.DQResponse.class);
            BillingWrappers.DealQualification dqRecord = resp.dqRecord;
            Boolean isFreeShippingOption = DQServiceHelper.isFreeShippingOption(qt);

            dqList = new DealQualificationSelector()
                .selectDQForSync(opp.Id)
                .executeQuery();

            reselectedDQRecord = dqList.get(0);

        Test.stopTest();

        System.assertEquals(
            null,
            reselectedDQRecord.Free_Shipping_Terms_Options__c,
            'DQ_Deal_Qualification__c.Free_Shipping_Terms_Options__c should be null when shipping method(CustomAddressAssignments__c.Type__c) != \'2 Day\' or \'Overnight\' or Quote.FreeShippingTerms__c != \'Free Shipping\''
        );

        System.assertEquals(
            true,
            isFreeShippingOption,
            'isFreeShippingOption should return true'
        );
    }

    @isTest
    static void testSyncDqDiscounts() {
        System.assertEquals(
            new List<DQ_Deal_Qualification_Discounts__c>(),
            DQServiceHelper.syncDqDiscounts(null, null, null, null),
            'method DQServiceHelper.syncDqDiscounts should return empty list if passed params are empty'
        );

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => ValueProviderBuilder.provideUniqueString('test account')
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => acc.Id,
                Opportunity.Name => ValueProviderBuilder.provideUniqueString('test opportunity')
            })
            .create()
            .getRecord();

        String testPackageId = '18';
        String testPackageVersion = '1';
        String testPackageName = 'Test package 18/1';
        String pInfo = NGBSTestDataGenerator.generateQuotePackageInfo(new Map<String, Object>{
            'Id' => testPackageId,
            'Version' => testPackageVersion,
            'PackageDisplayName' => testPackageName
        });

        List<Quote> testQuotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.OpportunityId => opp.Id,
                Quote.Name => ValueProviderBuilder.provideUniqueString('test quote'),
                Quote.Package_Info__c => ValueProviderBuilder.provideList(new List<String>{pInfo, null}),
                Quote.RecordTypeId => ValueProviderBuilder.provideList(new List<Id>{QuoteHelper.RT_ID_BILLING, QuoteHelper.RT_ID_CC}),
                Quote.Pricebook2Id => Test.getStandardPriceBookId()
            })
            .quantity(2)
            .create()
            .getRecords();

        Quote testBillingQuote;
        for (Quote qt : testQuotes) {
            if (qt.RecordTypeId == QuoteHelper.RT_ID_BILLING) {
                testBillingQuote = qt;
            }
        }


        String billingGoaGroup = 'GOA_RC_Office';
        String ccGoaGroup = 'GOA_All_Contact_Center';
        List<Product2> testProducts = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Product2.Name => ValueProviderBuilder.provideUniqueString('test product'),
                    Product2.IsActive => true,
                    Product2.Sub_Category__c => ValueProviderBuilder.provideList(new List<String>{
                        'Main', 'Contact Center'
                    }),
                    Product2.GOA_Group_V3__c => ValueProviderBuilder.provideList(new List<String>{
                        '{"regular":"' + billingGoaGroup + '","contracted":"' + billingGoaGroup + '"}', null
                    }),
                    Product2.GOA_Group_V2__c => ValueProviderBuilder.provideList(new List<String>{
                        null, ccGoaGroup
                    }),
                    Product2.Group__c => ValueProviderBuilder.provideList(new List<String>{
                        'testGroup1', 'testGroup2'
                    }),
                    Product2.Subgroup__c => ValueProviderBuilder.provideList(new List<String>{
                        'testSubGroup1', 'testSubGroup2'
                    })
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        DQ_Deal_Qualification__c testDqRecord = (DQ_Deal_Qualification__c) new SObjectBuilder(DQ_Deal_Qualification__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                DQ_Deal_Qualification__c.Opportunity__c => opp.Id
            })
            .create()
            .getRecord();

        List<DQ_Deal_Qualification_Discounts__c> dqDiscounts = (List<DQ_Deal_Qualification_Discounts__c>) new SObjectBuilder(DQ_Deal_Qualification_Discounts__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Deal_Qualification_Discounts__c.Deal_Qualification__c => testDqRecord.Id,
                    DQ_Deal_Qualification_Discounts__c.Product__c => testProducts.get(1).Id,
                    DQ_Deal_Qualification_Discounts__c.Product_Category__c => ccGoaGroup,
                    DQ_Deal_Qualification_Discounts__c.RecordTypeId => DQServiceHelper.DQ_CC_RECORD_TYPE_ID,
                    DQ_Deal_Qualification_Discounts__c.Quantity__c => 50,
                    DQ_Deal_Qualification_Discounts__c.Discount__c => 90,
                    DQ_Deal_Qualification_Discounts__c.Discount_Type__c => QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE
                }
            )
            .create()
            .getRecords();

        List<PriceBookEntry> pbeList = (List<PriceBookEntry>) new SobjectBuilder(PriceBookEntry.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    PriceBookEntry.Product2Id => ValueProviderBuilder.provideParents(testProducts),
                    PriceBookEntry.UnitPrice => 100,
                    PriceBookEntry.IsActive => true,
                    PriceBookEntry.Pricebook2Id => Test.getStandardPriceBookId()
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        Test.startTest();

            new SObjectBuilder(QuoteLineItem.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        QuoteLineItem.QuoteId => ValueProviderBuilder.provideParents(testQuotes),
                        QuoteLineItem.PriceBookEntryId => ValueProviderBuilder.provideParents(pbeList),
                        QuoteLineItem.Product2Id => ValueProviderBuilder.provideParents(testProducts),
                        QuoteLineItem.UnitPrice => 100,
                        QuoteLineItem.Discount_type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                        QuoteLineItem.Quantity => ValueProviderBuilder.provideList(new List<Decimal>{10, 20}),
                        QuoteLineItem.Discount => ValueProviderBuilder.provideList(new List<Decimal>{5, 17})
                    }
                )
                .quantity(2)
                .create();

            List<QuoteLineItem> reselectedQliList = new QuoteLineItemSelector()
                .selectQuoteLineItemsForDqSync()
                .setCondition('Quote.OpportunityId = \'' + opp.Id + '\'')
                .executeQuery();

            QuoteLineItem billingItem;
            QuoteLineItem ccItem;
            for (QuoteLineItem qli : reselectedQliList) {
                if (qli.QuoteId == testBillingQuote.Id) {
                    billingItem = qli;
                } else {
                    ccItem = qli;
                }
            }

            List<DQ_Deal_Qualification_Discounts__c> createdDqDiscounts = DQServiceHelper.syncDqDiscounts(
                testDqRecord.Id,
                dqDiscounts,
                reselectedQliList,
                new Map<Id, BillingWrappers.QuotePackageInfo>{ testBillingQuote.Id =>  new BillingWrappers.QuotePackageInfoWrapper(pInfo).getPackageInfo() }
            );
            System.assert(
                !createdDqDiscounts.isEmpty(),
                'dq discounts should be synced and exist as DQ_Deal_Qualification_Discounts__c records'
            );
            System.assertEquals(
                2,
                createdDqDiscounts.size(),
                'should be 2 DQ_Deal_Qualification_Discounts__c records'
            );

            DQ_Deal_Qualification_Discounts__c billingQuoteDiscount;
            DQ_Deal_Qualification_Discounts__c ccQuoteDiscount;
            for (DQ_Deal_Qualification_Discounts__c dqDiscount : createdDqDiscounts) {
                if (dqDiscount.Product__c == billingItem.Product2Id) {
                    billingQuoteDiscount = dqDiscount;
                } else if (dqDiscount.Product__c == ccItem.Product2Id) {
                    ccQuoteDiscount = dqDiscount;
                }
            }

            System.assertEquals(
                DQServiceHelper.DQ_SALES_RECORD_TYPE_ID,
                billingQuoteDiscount.RecordTypeId,
                'discounts created for sales quote should have "Sales Quote" recordType'
            );
            System.assertEquals(
                billingItem.Quantity,
                billingQuoteDiscount.Quantity__c,
                'quantity value should be copied from corresponding quote line item'
            );
            System.assertEquals(
                billingItem.Discount,
                billingQuoteDiscount.Discount__c,
                'discount value should be copied from corresponding quote line item'
            );
            System.assertEquals(
                billingItem.Discount_type__c,
                billingQuoteDiscount.Discount_Type__c,
                'discount type value should be copied from corresponding quote line item'
            );
            System.assertEquals(
                billingGoaGroup,
                billingQuoteDiscount.Product_Category__c,
                'Product_Category__c value should be copied from Product2.GOA_Group_V3__c for sales quotes v2'
            );

            System.assertEquals(
                testPackageId,
                billingQuoteDiscount.OriginalPackageId__c,
                'OriginalPackageId__c value should be copied from package info of sales quotes v2'
            );
            System.assertEquals(
                testPackageVersion,
                billingQuoteDiscount.OriginalPackageVersion__c,
                'OriginalPackageVersion__c value should be copied from package info of sales quotes v2'
            );
            System.assertEquals(
                testPackageName,
                billingQuoteDiscount.PackageName__c,
                'PackageName__c value should be copied from package info of sales quotes v2'
            );
            System.assertEquals(
                testPackageName,
                billingQuoteDiscount.OriginalPackageName__c,
                'OriginalPackageName__c value should be copied from package info of sales quotes v2'
            );
            System.assertEquals(
                'testGroup1',
                billingQuoteDiscount.Group__c,
                'Group__c value should be copied from package info of sales quotes v2'
            );
            System.assertEquals(
                'testSubGroup1',
                billingQuoteDiscount.Subgroup__c,
                'Subgroup__c value should be copied from package info of sales quotes v2'
            );
            System.assertEquals(
                DQServiceHelper.DQ_CC_RECORD_TYPE_ID,
                ccQuoteDiscount.RecordTypeId,
                'discounts created for contact center quote should have "Contact Center" recordType'
            );
            System.assertEquals(
                ccItem.Quantity,
                ccQuoteDiscount.Quantity__c,
                'quantity value should be copied from corresponding quote line item'
            );
            System.assertEquals(
                ccItem.Discount,
                ccQuoteDiscount.Discount__c,
                'discount value should be copied from corresponding quote line item'
            );
            System.assertEquals(
                ccItem.Discount_type__c,
                ccQuoteDiscount.Discount_Type__c,
                'discount type value should be copied from corresponding quote line item'
            );
            System.assertEquals(
                ccGoaGroup,
                ccQuoteDiscount.Product_Category__c,
                'Product_Category__c value should be copied from Product2.GOA_Group_V2__c for contact center quotes'
            );

        Test.stopTest();
    }

    @isTest
    static void testUpdateDQStatusWithEmptyParams() {
        String resultJson = DQServiceHelper.updateDQStatus(null);
        DQServiceHelper.DQResponse resp = (DQServiceHelper.DQResponse) JSON.deserialize(resultJson, DQServiceHelper.DQResponse.class);
        System.assertEquals(
            null,
            resp.dqRecord,
            'method should return structure with empty BillingWrappers.DealQualification record ' +
            'in json format if passed argument is null'
        );

        resultJson = DQServiceHelper.updateDQStatus(new BillingWrappers.DQParams());
        resp = (DQServiceHelper.DQResponse) JSON.deserialize(resultJson, DQServiceHelper.DQResponse.class);
        System.assertEquals(
            null,
            resp.dqRecord,
            'method should return structure with empty BillingWrappers.DealQualification record ' +
            'in json format if dqRecord passed as argument is null '
        );
    }

    @isTest
    static void testUpdateDQStatus() {

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => ValueProviderBuilder.provideUniqueString('test account')
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => acc.Id,
                Opportunity.Name => ValueProviderBuilder.provideUniqueString('test opportunity')
            })
            .create()
            .getRecord();

        DQ_Deal_Qualification__c testDqRecord = (DQ_Deal_Qualification__c) new SObjectBuilder(DQ_Deal_Qualification__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                DQ_Deal_Qualification__c.Opportunity__c => opp.Id,
                DQ_Deal_Qualification__c.Status__c => 'New',
                DQ_Deal_Qualification__c.Charge_Term__c => 'Annual',
                DQ_Deal_Qualification__c.Renewal_Term__c => '12',
                DQ_Deal_Qualification__c.Initial_Term__c => '12',
                DQ_Deal_Qualification__c.Special_Terms__c => '2 Free Months of Service',
                DQ_Deal_Qualification__c.Deal_Size__c => 500,
                DQ_Deal_Qualification__c.New_Annual_Recurring_Charges__c => 50
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.OpportunityId => opp.Id,
                Quote.Name => ValueProviderBuilder.provideUniqueString('test quote'),
                Quote.Payment_Plan__c => 'Monthly',
                Quote.Term_months__c => '36',
                Quote.Initial_Term_months__c => '24',
                Quote.Special_Terms__c => '5 Free Months of Service',
                Quote.Total_MRR_New__c => 1000,
                Quote.Monthly_Recurring_Revenue__c => 100
            })
            .create()
            .getRecord();

        BillingWrappers.DQParams params = new BillingWrappers.DQParams();
        params.status = 'Pending Approval';
        params.dqRecord = new BillingWrappers.DealQualification(testDqRecord);

        Test.startTest();
            String resultJson = DQServiceHelper.updateDQStatus(params);
        Test.stopTest();

        DQServiceHelper.DQResponse resp = (DQServiceHelper.DQResponse) JSON.deserialize(resultJson, DQServiceHelper.DQResponse.class);
        BillingWrappers.DealQualification dqRecord = resp.dqRecord;
        System.assertEquals(
            params.status,
            dqRecord.status,
            'DQ_Deal_Qualification__c.Status__c should be updated'
        );
    }

    @isTest
    static void testCreateDealQualificationApproverWithEmptyParams() {
        String resultJson = DQServiceHelper.createDealQualificationApprover(null, null);
        DQServiceHelper.DQResponse resp = (DQServiceHelper.DQResponse) JSON.deserialize(resultJson, DQServiceHelper.DQResponse.class);
        System.assertEquals(
            null,
            resp.dqRecord,
            'method should return structure with empty BillingWrappers.DealQualification record ' +
            'in json format if passed argument is null'
        );
    }

    @isTest
    static void testReviseDealQualificationWithEmptyParams() {
        String resultJson = DQServiceHelper.reviseDealQualification(null, null);
        DQServiceHelper.DQResponse resp = (DQServiceHelper.DQResponse) JSON.deserialize(resultJson, DQServiceHelper.DQResponse.class);
        System.assertEquals(
            null,
            resp.dqRecord,
            'method should return structure with empty BillingWrappers.DealQualification record ' +
            'in json format if passed argument is null'
        );
    }

    @isTest
    static void testPopulateDQDiscountFields() {

        System.assertEquals(
            null,
            DQServiceHelper.populateDQDiscountFields(null, null, null),
            'method DQServiceHelper.populateDQDiscountFields should return null if passed params are null'
        );

        QuoteLineItem testQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    QuoteLineItem.Discount_type__c => QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE,
                    QuoteLineItem.Quantity => 50,
                    QuoteLineItem.Discount => 42,
                    QuoteLineItem.Promotion__c => ValueProviderBuilder.provideDummyId(Promotion__c.SObjectType),
                    QuoteLineItem.Product2Id => ValueProviderBuilder.provideDummyId(Product2.SObjectType)
                }
            )
            .build()
            .getRecord();

        DQ_Deal_Qualification_Discounts__c result = DQServiceHelper.populateDQDiscountFields(
            new DQ_Deal_Qualification_Discounts__c(),
            'Main',
            testQli
        );

        System.assertEquals(
            testQli.Discount_type__c,
            result.Discount_Type__c,
            'Discount_Type__c field value should be copied from QuoteLineItem.Discount_type__c'
        );
        System.assertEquals(
            testQli.Quantity,
            result.Quantity__c,
            'Quantity__c field value should be copied from QuoteLineItem.Quantity'
        );
        System.assertEquals(
            testQli.Discount,
            result.Discount__c,
            'Discount__c field value should be copied from QuoteLineItem.Discount'
        );
        System.assertEquals(
            testQli.Promotion__c,
            result.Promo_Code__c,
            'Promo_Code__c field value should be copied from QuoteLineItem.Promotion__c'
        );
        System.assertEquals(
            testQli.Product2Id,
            result.Product__c,
            'Product__c field value should be copied from QuoteLineItem.Product2Id'
        );
        System.assertEquals(
            DQServiceHelper.DQ_SALES_RECORD_TYPE_ID,
            result.RecordTypeId,
            'RecordTypeId should be filled based on product sub category'
        );

        result = DQServiceHelper.populateDQDiscountFields(
            new DQ_Deal_Qualification_Discounts__c(),
            'Contact Center',
            testQli
        );
        System.assertEquals(
            DQServiceHelper.DQ_CC_RECORD_TYPE_ID,
            result.RecordTypeId,
            'RecordTypeId should be filled based on product sub category'
        );
    }

    @isTest
    static void testPopulateDQDiscountFieldsPOCtoPaid() {

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

        DQ_Deal_Qualification_Discounts__c resultPocToPaid = DQServiceHelper.populateDQDiscountFields(
            new DQ_Deal_Qualification_Discounts__c(),
            'Main',
            testQliPocToPaid
        );

        System.assertEquals(
            testQliPocToPaid.NewQuantity__c,
            resultPocToPaid.Quantity__c,
            'NewQuantity__c field value should be copied from QuoteLineItem.Quantity for POC-to-Paid scenario'
        );
    }

    @isTest
    static void testBuildDqDiscountsMap() {
        System.assertEquals(
            new Map<String, DQ_Deal_Qualification_Discounts__c>(),
            DQServiceHelper.buildDqDiscountsMap(null, true),
            'method should return empty map if passed argument is empty'
        );

        List<Product2> products = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => ValueProviderBuilder.provideUniqueString('test_product')
            })
            .quantity(2)
            .create()
            .getRecords();

        List<DQ_Deal_Qualification_Discounts__c> dqDiscountsList = (List<DQ_Deal_Qualification_Discounts__c>) new SObjectBuilder(DQ_Deal_Qualification_Discounts__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                DQ_Deal_Qualification_Discounts__c.Id => ValueProviderBuilder.provideDummyId(DQ_Deal_Qualification_Discounts__c.SObjectType),
                DQ_Deal_Qualification_Discounts__c.RecordTypeId => DQServiceHelper.DQ_SALES_RECORD_TYPE_ID,
                DQ_Deal_Qualification_Discounts__c.Product__c => ValueProviderBuilder.provideParents(products),
                DQ_Deal_Qualification_Discounts__c.OriginalPackageId__c => ValueProviderBuilder.provideList(new List<String>{
                    '1952', '1111', '1952', '1111'
                }),
                DQ_Deal_Qualification_Discounts__c.OriginalPackageVersion__c => ValueProviderBuilder.provideList(new List<String>{
                    '2', '1', '2', '1'
                }),
                DQ_Deal_Qualification_Discounts__c.OriginalPackageName__c => 'test_package',
                DQ_Deal_Qualification_Discounts__c.PackageName__c => 'test_package',
                DQ_Deal_Qualification_Discounts__c.Product_Category__c => ValueProviderBuilder.provideList(new List<String>{
                    'GOA_Devices', 'GOA_Devices', 'GOA_Devices', 'test_category'
                }),
                DQ_Deal_Qualification_Discounts__c.Discount_Type__c => QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE,
                DQ_Deal_Qualification_Discounts__c.Discount__c => ValueProviderBuilder.provideList(new List<Decimal>{ 1, 5, 2, 7 }),
                DQ_Deal_Qualification_Discounts__c.Quantity__c => ValueProviderBuilder.provideList(new List<Decimal>{ 10, 15, 20, 25 })
            })
            .quantity(4)
            .build()
            .getRecords();

        Map<String, DQ_Deal_Qualification_Discounts__c> discountsMap = DQServiceHelper.buildDqDiscountsMap(dqDiscountsList, true);
        System.assertEquals(4, discountsMap.size(), 'returned map should contain 4 entries');
    }

    @isTest
    static void testSaveDqDiscounts() {

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => ValueProviderBuilder.provideUniqueString('testProduct'),
                Product2.Group__c => 'testGroup1',
                Product2.Subgroup__c => 'testSubGroup1'
            })
            .create()
            .getRecord();

        DQ_Deal_Qualification__c testDqRecord = (DQ_Deal_Qualification__c) new SObjectBuilder(DQ_Deal_Qualification__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                DQ_Deal_Qualification__c.Opportunity__c => ValueProviderBuilder.provideGenericParent(Opportunity.SObjectType)
            })
            .create()
            .getRecord();

        DQ_Deal_Qualification_Discounts__c testDqDiscount = (DQ_Deal_Qualification_Discounts__c) new SObjectBuilder(DQ_Deal_Qualification_Discounts__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                DQ_Deal_Qualification_Discounts__c.Deal_Qualification__c => testDqRecord.Id,
                DQ_Deal_Qualification_Discounts__c.RecordTypeId => DQServiceHelper.DQ_SALES_RECORD_TYPE_ID,
                DQ_Deal_Qualification_Discounts__c.Product__c => testProduct.Id,
                DQ_Deal_Qualification_Discounts__c.OriginalPackageId__c => '1952',
                DQ_Deal_Qualification_Discounts__c.OriginalPackageVersion__c => '2',
                DQ_Deal_Qualification_Discounts__c.OriginalPackageName__c => 'test Package',
                DQ_Deal_Qualification_Discounts__c.PackageName__c => 'test Package',
                DQ_Deal_Qualification_Discounts__c.Product_Category__c => 'GOA_Devices',
                DQ_Deal_Qualification_Discounts__c.Discount_Type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                DQ_Deal_Qualification_Discounts__c.Discount__c => 5,
                DQ_Deal_Qualification_Discounts__c.Quantity__c => 10
            })
            .create()
            .getRecord();

        System.assertEquals(
            new List<DQ_Deal_Qualification_Discounts__c>(),
            DQServiceHelper.saveDqDiscounts(testDqRecord.Id, null, null),
            'method saveDqDiscounts should return emptyList if new and existing discounts are empty'
        );


        BillingWrappers.DealQualificationDiscount dqDiscountForCreate = new BillingWrappers.DealQualificationDiscount();
        dqDiscountForCreate.product2Id = testProduct.Id;
        dqDiscountForCreate.recordTypeId = DQServiceHelper.DQ_SALES_RECORD_TYPE_ID;
        dqDiscountForCreate.originalPackageId = '100';
        dqDiscountForCreate.originalPackageVersion = '1';
        dqDiscountForCreate.originalPackageName = 'test package';
        dqDiscountForCreate.packageName = 'test package';
        dqDiscountForCreate.productCategory = 'GOA_Devices';
        dqDiscountForCreate.discountType = QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE;
        dqDiscountForCreate.discount = 75;
        dqDiscountForCreate.quantity = 100;
        dqDiscountForCreate.isDataExist = true;

        BillingWrappers.DealQualificationDiscount dqDiscountForUpdate = new BillingWrappers.DealQualificationDiscount();
        dqDiscountForUpdate.dqDiscountId = testDqDiscount.Id;
        dqDiscountForUpdate.product2Id = testProduct.Id;
        dqDiscountForUpdate.recordTypeId = DQServiceHelper.DQ_SALES_RECORD_TYPE_ID;
        dqDiscountForUpdate.originalPackageId = '1952';
        dqDiscountForUpdate.originalPackageVersion = '2';
        dqDiscountForUpdate.originalPackageName = 'test package';
        dqDiscountForUpdate.packageName = 'test package';
        dqDiscountForUpdate.productCategory = 'GOA_Devices';
        dqDiscountForUpdate.discountType = QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE;
        dqDiscountForUpdate.discount = 90;
        dqDiscountForUpdate.quantity = 150;
        dqDiscountForUpdate.isDataExist = true;

        List<DQ_Deal_Qualification_Discounts__c> updatedDiscounts = DQServiceHelper.saveDqDiscounts(
            testDqRecord.Id,
            new List<BillingWrappers.DealQualificationDiscount>{dqDiscountForCreate, dqDiscountForUpdate},
            new List<DQ_Deal_Qualification_Discounts__c>{testDqDiscount}
        );
        System.assertEquals(2, updatedDiscounts.size(), 'existing discount should be updated and 1 new discount should be created');

        DQ_Deal_Qualification__c reselectedDQRecord =  (DQ_Deal_Qualification__c) new ListOptional(
            new DealQualificationSelector()
                .selectDQForSync(testDqRecord.Id)
                .executeQuery()
        ).getFirst();
        List<DQ_Deal_Qualification_Discounts__c> reselectedDiscounts = reselectedDQRecord.Deal_Qualification_Discounts__r;
        System.assertEquals(2, reselectedDiscounts.size(), 'existing discount should be updated and 1 new discount should be created');

        DQ_Deal_Qualification_Discounts__c createdDiscount;
        DQ_Deal_Qualification_Discounts__c updatedDiscount;
        for (DQ_Deal_Qualification_Discounts__c dqDiscount : reselectedDiscounts) {
            if (dqDiscount.Id == testDqDiscount.Id) {
                updatedDiscount = dqDiscount;
            } else {
                createdDiscount = dqDiscount;
            }
        }

        System.assertEquals(
            dqDiscountForCreate.product2Id,
            createdDiscount.Product__c,
            'DQ_Deal_Qualification_Discounts__c.Product__c should match the product2Id from discount wrapper'
        );
        System.assertEquals(
            dqDiscountForCreate.originalPackageId,
            createdDiscount.OriginalPackageId__c,
            'DQ_Deal_Qualification_Discounts__c.OriginalPackageId__c should match the originalPackageId from discount wrapper'
        );
        System.assertEquals(
            dqDiscountForCreate.originalPackageVersion,
            createdDiscount.OriginalPackageVersion__c,
            'DQ_Deal_Qualification_Discounts__c.OriginalPackageVersion__c should match the originalPackageVersion from discount wrapper'
        );
        System.assertEquals(
            dqDiscountForCreate.originalPackageName,
            createdDiscount.OriginalPackageName__c,
            'DQ_Deal_Qualification_Discounts__c.OriginalPackageName__c should match the originalPackageName from discount wrapper'
        );
        System.assertEquals(
            dqDiscountForCreate.packageName,
            createdDiscount.PackageName__c,
            'DQ_Deal_Qualification_Discounts__c.PackageName__c should match the packageName from discount wrapper'
        );
        System.assertEquals(
            dqDiscountForCreate.productCategory,
            createdDiscount.Product_Category__c,
            'DQ_Deal_Qualification_Discounts__c.Product_Category__c should match the productCategory from discount wrapper'
        );
        System.assertEquals(
            dqDiscountForCreate.discountType,
            createdDiscount.Discount_Type__c,
            'DQ_Deal_Qualification_Discounts__c.Discount_Type__c should match the discountType from discount wrapper'
        );
        System.assertEquals(
            dqDiscountForCreate.discount,
            createdDiscount.Discount__c,
            'DQ_Deal_Qualification_Discounts__c.Discount__c should match the discount from discount wrapper'
        );
        System.assertEquals(
            dqDiscountForCreate.quantity,
            createdDiscount.Quantity__c,
            'DQ_Deal_Qualification_Discounts__c.Quantity__c should match the discount from quantity wrapper'
        );

        System.assertEquals(
            dqDiscountForUpdate.discount,
            updatedDiscount.Discount__c,
            'DQ_Deal_Qualification_Discounts__c.Discount__c should be updated according to discount wrapper'
        );
        System.assertEquals(
            dqDiscountForUpdate.quantity,
            updatedDiscount.Quantity__c,
            'DQ_Deal_Qualification_Discounts__c.Quantity__c should be updated according to discount wrapper'
        );
        System.assertEquals(
            dqDiscountForUpdate.groupName,
            updatedDiscount.Group__c,
            'DQ_Deal_Qualification_Discounts__c.Group__c should be updated according to discount wrapper'
        );
        System.assertEquals(
            dqDiscountForUpdate.subGroup,
            updatedDiscount.Subgroup__c,
            'DQ_Deal_Qualification_Discounts__c.Subgroup__c should be updated according to discount wrapper'
        );
    }

    @isTest
    static void testCreateDqDiscountsWithEmptyGoaGroup() {

        DQ_Deal_Qualification__c testDqRecord = (DQ_Deal_Qualification__c) new SObjectBuilder(DQ_Deal_Qualification__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                DQ_Deal_Qualification__c.Id => ValueProviderBuilder.provideDummyId(DQ_Deal_Qualification__c.SObjectType)
            })
            .build()
            .getRecord();

        List<Quote> testQuotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.RecordTypeId => ValueProviderBuilder.provideList(new List<Id>{
                        QuoteHelper.RT_ID_BILLING, QuoteHelper.RT_ID_CC
                    })
                }
            )
            .quantity(2)
            .build()
            .getRecords();

        List<Product2> testProducts = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.GOA_Group_V3__c => null,
                Product2.GOA_Group_V2__c => null,
                Product2.Sub_Category__c => ValueProviderBuilder.provideList(new List<String>{
                    null, Product2Helper.SUBCATEGORY_CONTACT_CENTER
                })
            })
            .quantity(2)
            .build()
            .getRecords();

        List<QuoteLineItem> testQlis = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.Discount => 50
            })
            .quantity(2)
            .build()
            .getRecords();

        testQlis.get(0).Quote = testQuotes.get(0);
        testQlis.get(0).Product2 = testProducts.get(0);
        testQlis.get(1).Quote = testQuotes.get(1);
        testQlis.get(1).Product2 = testProducts.get(1);

        List<DQ_Deal_Qualification_Discounts__c> dqDiscounts = DQServiceHelper.syncDqDiscounts(
            testDqRecord.Id,
            new List<DQ_Deal_Qualification_Discounts__c>(),
            testQlis,
            new Map<Id, BillingWrappers.QuotePackageInfo>()
        );
        System.assertEquals(
            2,
            dqDiscounts.size(),
            '2 DQ_Deal_Qualification_Discounts__c should be created'
        );

        DQ_Deal_Qualification_Discounts__c salesDiscount;
        DQ_Deal_Qualification_Discounts__c ccDiscount;
        for (DQ_Deal_Qualification_Discounts__c discount : dqDiscounts) {
            if (discount.RecordTypeId == DQServiceHelper.DQ_SALES_RECORD_TYPE_ID) {
                salesDiscount = discount;
            } else if (discount.RecordTypeId == DQServiceHelper.DQ_CC_RECORD_TYPE_ID) {
                ccDiscount = discount;
            }
        }
        System.assertEquals(
            'Default',
            salesDiscount.Product_Category__c,
            'if Product2 has empty GOA_Group_V3__c created discount should have "Default" value in Product_Category__c field'
        );
        System.assertEquals(
            DQServiceHelper.DEFAULT_CC_CATEGORY,
            ccDiscount.Product_Category__c,
            'if Product2 has empty GOA_Group_V2__c and Sub_Category__c equal to "'
            + Product2Helper.SUBCATEGORY_CONTACT_CENTER + '" created discount should have "'
            + DQServiceHelper.DEFAULT_CC_CATEGORY + '" value in Product_Category__c field'
        );
    }

    @isTest
    static void testSaveDqServiceDiscounts() {

        DQ_Deal_Qualification__c testDqRecord = (DQ_Deal_Qualification__c) new SObjectBuilder(DQ_Deal_Qualification__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                DQ_Deal_Qualification__c.Opportunity__c => ValueProviderBuilder.provideGenericParent(Opportunity.SObjectType)
            })
            .create()
            .getRecord();

        List<DQ_Deal_Qualification_Service_Discount__c> listServiceDiscounts = (List<DQ_Deal_Qualification_Service_Discount__c>) new SObjectBuilder(DQ_Deal_Qualification_Service_Discount__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                DQ_Deal_Qualification_Service_Discount__c.Deal_Qualification__c => testDqRecord.Id,
                DQ_Deal_Qualification_Service_Discount__c.Service__c => ValueProviderBuilder.provideList(new List<String>{QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT, QuoteHelper.NGBS_OFFICE_PRODUCT}),
                DQ_Deal_Qualification_Service_Discount__c.Discretion__c => ValueProviderBuilder.provideList(new List<Decimal>{75, 95}),
                DQ_Deal_Qualification_Service_Discount__c.WeightedDiscount__c => ValueProviderBuilder.provideList(new List<Decimal>{1,2}),
                DQ_Deal_Qualification_Service_Discount__c.EESRemoval__c => ValueProviderBuilder.provideList(new List<Boolean>{true,false}),
                DQ_Deal_Qualification_Service_Discount__c.createdDate => Date.today()
            })
            .quantity(2)
            .create()
            .getRecords();

        BillingWrappers.DealQualificationServiceDiscount dqServiceDiscountFirst = new BillingWrappers.DealQualificationServiceDiscount();
        dqServiceDiscountFirst.dqId = testDqRecord.Id;
        dqServiceDiscountFirst.dqServiceDiscountId = listServiceDiscounts[0].Id;
        dqServiceDiscountFirst.service = QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT;
        dqServiceDiscountFirst.discretion = 15;
        dqServiceDiscountFirst.weightedDiscount = 20;
        dqServiceDiscountFirst.createdDate = Date.today();

        BillingWrappers.DealQualificationServiceDiscount dqServiceDiscountSecond = new BillingWrappers.DealQualificationServiceDiscount();
        dqServiceDiscountSecond.dqId = testDqRecord.Id;
        dqServiceDiscountSecond.dqServiceDiscountId = listServiceDiscounts[1].Id;
        dqServiceDiscountSecond.service = QuoteHelper.NGBS_OFFICE_PRODUCT;
        dqServiceDiscountSecond.discretion = 33;
        dqServiceDiscountSecond.weightedDiscount = 44;
        dqServiceDiscountSecond.createdDate = Date.today();

        List<BillingWrappers.DealQualificationServiceDiscount> dqServiceDiscountsWrapperList = new List<BillingWrappers.DealQualificationServiceDiscount>{ dqServiceDiscountFirst, dqServiceDiscountSecond };

        Test.startTest();
            DQServiceHelper.saveDqServiceDiscounts(dqServiceDiscountsWrapperList, listServiceDiscounts);
        Test.stopTest();
        List<DQ_Deal_Qualification_Service_Discount__c> reselectedDQServiceDiscountsList = (List<DQ_Deal_Qualification_Service_Discount__c>) new DealQualificationServiceDiscountSelector()
            .selectDQServiceDiscountsForSync()
            .executeQuery();

        System.assertEquals(2, reselectedDQServiceDiscountsList.size(), 'List size of reselected DQ Service discounts should be 2');
        System.assertEquals(dqServiceDiscountFirst.discretion, reselectedDQServiceDiscountsList[0].Discretion__c, 'Discretion value should be updated to dqServiceDiscountFirst Wrapper Discretion value');
        System.assertEquals(dqServiceDiscountSecond.discretion, reselectedDQServiceDiscountsList[1].Discretion__c, 'Discretion value should be updated to dqServiceDiscountSecond Wrapper Discretion value');
        System.assertEquals(dqServiceDiscountFirst.weightedDiscount, reselectedDQServiceDiscountsList[0].WeightedDiscount__c, 'Weighted Discount value should be updated to dqServiceDiscountFirst Wrapper Weighted Discount value');
        System.assertEquals(dqServiceDiscountSecond.weightedDiscount, reselectedDQServiceDiscountsList[1].WeightedDiscount__c, 'Weighted Discount value should be updated to dqServiceDiscountSecond Wrapper Weighted Discount value');
    }


    @isTest
    static void testSyncDqServiceDiscountsQuoteFieldsPopulated() {

        String pInfo = NGBSTestDataGenerator.generateQuotePackageInfo(new Map<String, Object>{
            'Id' => '333',
            'Version' => '1',
            'PackageDisplayName' => 'testPackageName'
        });

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => ValueProviderBuilder.provideUniqueString('test account')
            })
            .create()
            .getRecord();

        List<Quote> testQuotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.ServiceName__c => ValueProviderBuilder.provideList(new List<String>{
                        QuoteHelper.NGBS_OFFICE_PRODUCT, QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT, QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT
                    }),
                    Quote.OpportunityId => ValueProviderBuilder.provideGenericParent(Opportunity.SObjectType),
                    Quote.OverallDiscretion__c => ValueProviderBuilder.provideList(new List<Decimal>{11, 12, 13}),
                    Quote.AverageDiscount__c => ValueProviderBuilder.provideList(new List<Decimal>{1, 2, 3}),
                    Quote.Package_Info__c => pInfo
                }
            )
            .quantity(3)
            .build()
            .getRecords();

        DQ_Deal_Qualification__c testDqRecord = (DQ_Deal_Qualification__c) new SObjectBuilder(DQ_Deal_Qualification__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                DQ_Deal_Qualification__c.Opportunity__c => ValueProviderBuilder.provideGenericParent(Opportunity.SObjectType)
            })
            .create()
            .getRecord();

        List<DQ_Deal_Qualification_Service_Discount__c> dqServiceDiscounts = new List<DQ_Deal_Qualification_Service_Discount__c>();

        Test.startTest();
            dqServiceDiscounts = DQServiceHelper.syncDqServiceDiscounts(new List<DQ_Deal_Qualification_Service_Discount__c>(), testDqRecord.Id, testQuotes);
        Test.stopTest();

        System.assertEquals(3, dqServiceDiscounts.size(), 'Returned List should contain 3 records');
        System.assertEquals(testQuotes[0].ServiceName__c, dqServiceDiscounts[0].Service__c, 'Service value should be got from quote record');
        System.assertEquals(testQuotes[1].ServiceName__c, dqServiceDiscounts[1].Service__c, 'Service value should be got from quote record');
        System.assertEquals(testQuotes[2].ServiceName__c, dqServiceDiscounts[2].Service__c, 'Service value should be got from quote record');
        System.assertEquals(testQuotes[0].OverallDiscretion__c, dqServiceDiscounts[0].Discretion__c, 'Discretion value should be got from quote record');
        System.assertEquals(testQuotes[1].OverallDiscretion__c, dqServiceDiscounts[1].Discretion__c, 'Discretion value should be got from quote record');
        System.assertEquals(testQuotes[2].OverallDiscretion__c, dqServiceDiscounts[2].Discretion__c, 'Discretion value should be got from quote record');
        System.assertEquals(testQuotes[0].AverageDiscount__c, dqServiceDiscounts[0].WeightedDiscount__c, 'Weighted Discount value should be got from quote record Average Discount field');
        System.assertEquals(testQuotes[1].AverageDiscount__c, dqServiceDiscounts[1].WeightedDiscount__c, 'Weighted Discount value should be got from quote record Average Discount field');
        System.assertEquals(testQuotes[2].AverageDiscount__c, dqServiceDiscounts[2].WeightedDiscount__c, 'Weighted Discount value should be got from quote record Average Discount field');
        System.assertEquals(false, dqServiceDiscounts[0].EESRemoval__c, 'EES Removal value should be false');
        System.assertEquals(false, dqServiceDiscounts[1].EESRemoval__c, 'EES Removal value should be false');
        System.assertEquals(false, dqServiceDiscounts[2].EESRemoval__c, 'EES Removal value should be false');
    }

    @isTest
    static void testSyncDqServiceDiscountsQuoteFieldsNotPopulated() {

        String pInfo = NGBSTestDataGenerator.generateQuotePackageInfo(new Map<String, Object>{
            'Id' => '333',
            'Version' => '1',
            'PackageDisplayName' => 'testPackageName'
        });

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => ValueProviderBuilder.provideUniqueString('test account')
            })
            .create()
            .getRecord();

        List<Quote> testQuotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.ServiceName__c => QuoteHelper.NGBS_OFFICE_PRODUCT,
                    Quote.Package_Info__c => pInfo
                }
            )
            .build()
            .quantity(1)
            .getRecords();

        DQ_Deal_Qualification__c testDqRecord = (DQ_Deal_Qualification__c) new SObjectBuilder(DQ_Deal_Qualification__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                DQ_Deal_Qualification__c.Opportunity__c => ValueProviderBuilder.provideGenericParent(Opportunity.SObjectType)
            })
            .create()
            .getRecord();

        List<DQ_Deal_Qualification_Service_Discount__c> dqServiceDiscounts = new List<DQ_Deal_Qualification_Service_Discount__c>();

        Test.startTest();
            dqServiceDiscounts = DQServiceHelper.syncDqServiceDiscounts(new List<DQ_Deal_Qualification_Service_Discount__c>(), testDqRecord.Id, testQuotes);
        Test.stopTest();

        System.assertEquals(1, dqServiceDiscounts.size(), 'Returned List should contain 1 record');
        System.assertEquals(0, dqServiceDiscounts[0].Discretion__c, 'Discretion value should be 0');
        System.assertEquals(0, dqServiceDiscounts[0].WeightedDiscount__c, 'Weighted Discount value should be 0');
    }

    @isTest
    static void testSyncDqServiceDiscountsEESPopulated() {

        String pInfo = NGBSTestDataGenerator.generateQuotePackageInfo(new Map<String, Object>{
            'Id' => '333',
            'Version' => '1',
            'PackageDisplayName' => 'testPackageName'
        });

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => ValueProviderBuilder.provideUniqueString('test account')
            })
            .create()
            .getRecord();

        List<Quote> testQuotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.ServiceName__c => QuoteHelper.NGBS_OFFICE_PRODUCT,
                    Quote.Package_Info__c => pInfo
                }
            )
            .build()
            .quantity(1)
            .getRecords();

        DQ_Deal_Qualification__c testDqRecord = (DQ_Deal_Qualification__c) new SObjectBuilder(DQ_Deal_Qualification__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                DQ_Deal_Qualification__c.Opportunity__c => ValueProviderBuilder.provideGenericParent(Opportunity.SObjectType)
            })
            .create()
            .getRecord();

        List<DQ_Deal_Qualification_Service_Discount__c> dqServiceDiscounts = new List<DQ_Deal_Qualification_Service_Discount__c>();

        Test.startTest();
            dqServiceDiscounts = DQServiceHelper.syncDqServiceDiscounts(new List<DQ_Deal_Qualification_Service_Discount__c>(), testDqRecord.Id, testQuotes);
        Test.stopTest();

        System.assertEquals(1, dqServiceDiscounts.size(), 'Returned List should contain 1 record');
    }
}