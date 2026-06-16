@isTest
public class DealQualificationHandler_Test {

    private static User createUser(Id managerId) {
        SObjectBuilder userBuilder = new SObjectBuilder(User.SObjectType)
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
            );

        if (managerId != null) {
            userBuilder.setField(User.ManagerId, managerId);
        }

        return (User) userBuilder.create().getRecord();
    }

    private static void createDQApprovalObjects(Integer discountThreshold, Id approverId) {
        DQ_Approval_Step__c dqApprovalStep = (DQ_Approval_Step__c) new SObjectBuilder(DQ_Approval_Step__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                DQ_Approval_Step__c.Name => 'Level 1'
            })
            .create()
            .getRecord();

        DQ_Approval_Type__c dqApprovalType = (DQ_Approval_Type__c) new SObjectBuilder(DQ_Approval_Type__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                DQ_Approval_Type__c.Product_Category__c => 'GOA_RC_Office',
                DQ_Approval_Type__c.Approval_Type__c => 'Discount',
                DQ_Approval_Type__c.Threshold__c => discountThreshold,
                DQ_Approval_Type__c.IsActive__c => true,
                DQ_Approval_Type__c.isUnifiedQuotingApprovalType__c => true
            })
            .create()
            .getRecord();

        DQ_Approval_Type_Step__c dqApprovalTypeStep = (DQ_Approval_Type_Step__c) new SObjectBuilder(DQ_Approval_Type_Step__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                DQ_Approval_Type_Step__c.DQ_Approval_Step__c => dqApprovalStep.Id,
                DQ_Approval_Type_Step__c.DQ_Approval_Type__c => dqApprovalType.Id,
                DQ_Approval_Type_Step__c.Region__c => 'US',
                DQ_Approval_Type_Step__c.Segment__c => 'Default',
                DQ_Approval_Type_Step__c.Deal_Type__c => 'Direct',
                DQ_Approval_Type_Step__c.Brand__c => 'Default',
                DQ_Approval_Type_Step__c.Sub_Region__c => 'All'
            })
            .create()
            .getRecord();

        new SObjectBuilder(DQ_Approval_Step_Approver__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                DQ_Approval_Step_Approver__c.Approval_Type__c => 'Approval',
                DQ_Approval_Step_Approver__c.DQ_Approval_Step__c => dqApprovalStep.Id,
                DQ_Approval_Step_Approver__c.Brand__c => 'Default',
                DQ_Approval_Step_Approver__c.Deal_Type__c => 'Direct',
                DQ_Approval_Step_Approver__c.Region__c => 'US',
                DQ_Approval_Step_Approver__c.Segment__c => 'Default',
                DQ_Approval_Step_Approver__c.Sub_Region__c => 'All',
                DQ_Approval_Step_Approver__c.OwnerId => approverId
            })
            .create();
    }

    @isTest
    public static void testGetQuotesForStatusUpdate() {
        DealQualificationHandler.QuoteApprovalStatusHandler triggerHandler = new DealQualificationHandler.QuoteApprovalStatusHandler(
            new List<SObject>()
        );
        System.assertEquals(
            new List<Quote>(),
            triggerHandler.getQuotesForStatusUpdate(null),
            'method getQuotesForStatusUpdate should return empty list if passed params are empty'
        );


        List<Account> testAccounts = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => ValueProviderBuilder.provideUniqueString('test account'),
                Account.Billing_ID__c => ValueProviderBuilder.provideList(new List<String>{
                    '1122334455', null, null, null, null
                })
            })
            .quantity(5)
            .create()
            .getRecords();

        List<Opportunity> testOpportunities = (List<Opportunity>) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => ValueProviderBuilder.provideParents(testAccounts),
                Opportunity.Name => ValueProviderBuilder.provideUniqueString('test opportunity')
            })
            .quantity(5)
            .create()
            .getRecords();

        List<Quote> testQuotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.OpportunityId => ValueProviderBuilder.provideParents(testOpportunities),
                Quote.Package_Info__c => ValueProviderBuilder.provideList(new List<String>{
                    NGBSTestDataGenerator.generateQuotePackageInfo(),
                    NGBSTestDataGenerator.generateQuotePackageInfo(new Map<String, Object>{
                        'ProductName' => 'Not Office'
                    }),
                    NGBSTestDataGenerator.generateQuotePackageInfo(new Map<String, Object>{
                        'ProductName' => QuoteHelper.NGBS_FAX_PRODUCT
                    }),
                    NGBSTestDataGenerator.generateQuotePackageInfo(new Map<String, Object>{
                        'ProductName' => QuoteHelper.NGBS_ENGAGE_VOICE_LEGACY_PRODUCT
                    }),
                    null
                }),
                Quote.RecordTypeId => ValueProviderBuilder.provideList(new List<Id>{
                    QuoteHelper.RT_ID_BILLING,
                    QuoteHelper.RT_ID_BILLING,
                    QuoteHelper.RT_ID_BILLING,
                    QuoteHelper.RT_ID_BILLING,
                    QuoteHelper.RT_ID_CC
                }),
                Quote.Approved_Status__c => ValueProviderBuilder.provideList(new List<String>{
                    QuoteHelper.APPROVAL_STATUS_REQUIRED,
                    QuoteHelper.APPROVAL_STATUS_REQUIRED,
                    QuoteHelper.APPROVAL_STATUS_NOT_REQUIRED,
                    QuoteHelper.APPROVAL_STATUS_REQUIRED,
                    QuoteHelper.APPROVAL_STATUS_REQUIRED
                })
            })
            .quantity(5)
            .create()
            .getRecords();

        Test.startTest();
            Set<Id> opportunityIdSet = new Set<Id>();
            for (Opportunity opp : testOpportunities) {
                opportunityIdSet.add(opp.Id);
            }

            List<Quote> quotesForApprove = triggerHandler.getQuotesForStatusUpdate(opportunityIdSet);
            System.assertEquals(
                3,
                quotesForApprove.size(),
                'method should return only 3 quotes for approve'
            );
        Test.stopTest();
    }

    @isTest
    public static void testUpdateQuoteOnDqApprove() {

        new SObjectBuilder(Feature_Toggle__c.sObjectType)
            .setField(Feature_Toggle__c.EnableTPAndDQBasedGOAInQT__c, true)
            .create();

        User testApprover = createUser(null);
        User testUser = createUser(testApprover.Id);

        createDQApprovalObjects(25, testApprover.Id);

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                Opportunity.Name => ValueProviderBuilder.provideUniqueString('test opportunity'),
                Opportunity.OwnerId => testUser.Id
            })
            .create()
            .getRecord();

        Test.startTest();

            Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    Quote.OpportunityId => testOpp.Id,
                    Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo(),
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                    Quote.Approved_Status__c => QuoteHelper.APPROVAL_STATUS_REQUIRED,
                    Quote.Pricebook2Id => Test.getStandardPriceBookId()
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

            QuoteLineItem testQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        QuoteLineItem.QuoteId => testQuote.Id,
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

            DQ_Deal_Qualification__c testDqRecord = (DQ_Deal_Qualification__c) new SObjectBuilder(DQ_Deal_Qualification__c.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    DQ_Deal_Qualification__c.Opportunity__c => testOpp.Id,
                    DQ_Deal_Qualification__c.Status__c => 'Pending Approval'
                })
                .create()
                .getRecord();

            new SObjectBuilder(DQ_Deal_Qualification_Discounts__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        DQ_Deal_Qualification_Discounts__c.Deal_Qualification__c => testDqRecord.Id,
                        DQ_Deal_Qualification_Discounts__c.Product__c => testProduct.Id,
                        DQ_Deal_Qualification_Discounts__c.Product_Category__c => 'GOA_RC_Office',
                        DQ_Deal_Qualification_Discounts__c.RecordTypeId => DQServiceHelper.DQ_SALES_RECORD_TYPE_ID,
                        DQ_Deal_Qualification_Discounts__c.Quantity__c => 10,
                        DQ_Deal_Qualification_Discounts__c.Discount__c => 20,
                        DQ_Deal_Qualification_Discounts__c.Discount_Type__c => QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE
                    }
                )
                .create();

            testDqRecord.Status__c = DealQualificationHandler.DQ_APPROVE_STATUS;
            update testDqRecord;

            Quote reselectedQuote = (Quote) new QuoteSelector()
                .selectQuotes()
                .selectField('Approved_Status__c')
                .setCondition('Id = :bind0')
                .setQueryBindings(new List<Object>{ testQuote.Id })
                .executeQuery()
                .get(0);

            System.assertEquals(
                QuoteHelper.APPROVAL_STATUS_APPROVED,
                reselectedQuote.Approved_Status__c,
                'quote should have status "Approved" if the list of approvers (returned by method DQGoa.getApproversForQuote) are empty'
            );

        Test.stopTest();
    }

    @isTest
    public static void testUpdateQuoteOnDqReject() {

        new SObjectBuilder(Feature_Toggle__c.sObjectType)
            .setField(Feature_Toggle__c.EnableTPAndDQBasedGOAInQT__c, true)
            .create();

        User testApprover = createUser(null);
        User testUser = createUser(testApprover.Id);

        createDQApprovalObjects(25, testApprover.Id);

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                Opportunity.Name => ValueProviderBuilder.provideUniqueString('test opportunity'),
                Opportunity.OwnerId => testUser.Id
            })
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.OpportunityId => testOpp.Id,
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo(),
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Approved_Status__c => QuoteHelper.APPROVAL_STATUS_REQUIRED,
                Quote.Pricebook2Id => Test.getStandardPriceBookId()
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

        QuoteLineItem testQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    QuoteLineItem.QuoteId => testQuote.Id,
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

        Test.startTest();

            DQ_Deal_Qualification__c testDqRecord = (DQ_Deal_Qualification__c) new SObjectBuilder(DQ_Deal_Qualification__c.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    DQ_Deal_Qualification__c.Opportunity__c => testOpp.Id,
                    DQ_Deal_Qualification__c.Status__c => 'Pending Approval'
                })
                .create()
                .getRecord();

            new SObjectBuilder(DQ_Deal_Qualification_Discounts__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        DQ_Deal_Qualification_Discounts__c.Deal_Qualification__c => testDqRecord.Id,
                        DQ_Deal_Qualification_Discounts__c.Product__c => testProduct.Id,
                        DQ_Deal_Qualification_Discounts__c.Product_Category__c => 'GOA_RC_Office',
                        DQ_Deal_Qualification_Discounts__c.RecordTypeId => DQServiceHelper.DQ_SALES_RECORD_TYPE_ID,
                        DQ_Deal_Qualification_Discounts__c.Quantity__c => 10,
                        DQ_Deal_Qualification_Discounts__c.Discount__c => 20,
                        DQ_Deal_Qualification_Discounts__c.Discount_Type__c => QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE
                    }
                )
                .create();

            testDqRecord.Status__c = DealQualificationHandler.DQ_REJECT_STATUS;
            update testDqRecord;

            Quote reselectedQuote = (Quote) new QuoteSelector()
                .selectQuotes()
                .selectField('Approved_Status__c')
                .setCondition('Id = :bind0')
                .setQueryBindings(new List<Object>{ testQuote.Id })
                .executeQuery()
                .get(0);

            System.assertEquals(
                QuoteHelper.APPROVAL_STATUS_NOT_REQUIRED,
                reselectedQuote.Approved_Status__c,
                'quote should have status "Approved" if the list of approvers (returned by method DQGoa.getApproversForQuote) are empty'
            );

        Test.stopTest();
    }

    @IsTest
    public static void testBuildDqHistoryRecordFromDq() {
        DQ_Deal_Qualification__c dq =
            (DQ_Deal_Qualification__c) new SObjectBuilder(DQ_Deal_Qualification__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        DQ_Deal_Qualification__c.Id => '',
                        DQ_Deal_Qualification__c.Deal_Size__c => 10,
                        DQ_Deal_Qualification__c.Minimum_Package_s__c => '',
                        DQ_Deal_Qualification__c.Number_of_DLs__c => 10,
                        DQ_Deal_Qualification__c.Overall_Discount__c => 10,
                        DQ_Deal_Qualification__c.Overall_Discount_One_Time__c => 10,
                        DQ_Deal_Qualification__c.Overall_Discount_Recurring__c => 10,
                        DQ_Deal_Qualification__c.Overall_Discount_Contact_Center__c => 10,
                        DQ_Deal_Qualification__c.Initial_Term__c => '',
                        DQ_Deal_Qualification__c.Status__c => '',
                        DQ_Deal_Qualification__c.Charge_Term__c => '',
                        DQ_Deal_Qualification__c.Special_Terms__c => '',
                        DQ_Deal_Qualification__c.Free_Shipping_Terms_Options__c => '',
                        DQ_Deal_Qualification__c.CC_Special_Terms__c => '',
                        DQ_Deal_Qualification__c.CC_Initial_Term__c => '',
                        DQ_Deal_Qualification__c.Is_ELA__c => '',
                        DQ_Deal_Qualification__c.Roll_Out_Plan__c => '',
                        DQ_Deal_Qualification__c.Start_Date__c => System.today(),
                        DQ_Deal_Qualification__c.True_Up_Terms__c => '',
                        DQ_Deal_Qualification__c.Maximum_Potential__c => 10,
                        DQ_Deal_Qualification__c.Minimum_Baseline__c => 10,
                        DQ_Deal_Qualification__c.ELA_Initial_Terms__c => '',
                        DQ_Deal_Qualification__c.Additional_Info__c => '',
                        DQ_Deal_Qualification__c.IsDQCreatedFromCPQOpp__c => true,
                        DQ_Deal_Qualification__c.Family_Discount__c => 10
                    }
                )
                .build()
                .getRecord();
        Test.startTest();
            DQ_Deal_Qualification_History__c historyToInsert = DealQualificationHandler.buildDqHistoryRecord(null, dq);
        Test.stopTest();
        System.assertEquals(null, historyToInsert.Id, 'Newly built dq history should not have Id');
        for (String field : DealQualificationHandler.dqHistoryFieldsToCopyFromDq) {
            System.assertEquals(
                historyToInsert.get(field),
                dq.get(field),
                'dq history field value should match dq field value'
            );
        }

    }

    @IsTest
    public static void testBuildDqHistoryRecordFromDqHistory() {
        DQ_Deal_Qualification_History__c existingDq =
            (DQ_Deal_Qualification_History__c) new SObjectBuilder(DQ_Deal_Qualification_History__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        DQ_Deal_Qualification_History__c.Id => (Id) new ValueProvider.DummyIdProvider(DQ_Deal_Qualification_History__c.sObjectType).getValue(),
                        DQ_Deal_Qualification_History__c.Brand__c => '',
                        DQ_Deal_Qualification_History__c.Deal_Size__c => 10,
                        DQ_Deal_Qualification_History__c.Deal_Type__c => '',
                        DQ_Deal_Qualification_History__c.Minimum_Package_s__c => '',
                        DQ_Deal_Qualification_History__c.Number_of_DLs__c => 10,
                        DQ_Deal_Qualification_History__c.Overall_Discount__c => 10,
                        DQ_Deal_Qualification_History__c.Overall_Discount_One_Time__c => 10,
                        DQ_Deal_Qualification_History__c.Overall_Discount_Recurring__c => 10,
                        DQ_Deal_Qualification_History__c.Overall_Discount_Contact_Center__c => 10,
                        DQ_Deal_Qualification_History__c.Initial_Term__c => '',
                        DQ_Deal_Qualification_History__c.Region__c => '',
                        DQ_Deal_Qualification_History__c.Status__c => '',
                        DQ_Deal_Qualification_History__c.Segment__c => '',
                        DQ_Deal_Qualification_History__c.Charge_Term__c => '',
                        DQ_Deal_Qualification_History__c.Special_Terms__c => '',
                        DQ_Deal_Qualification_History__c.Free_Shipping_Terms_Options__c => '',
                        DQ_Deal_Qualification_History__c.CC_Special_Terms__c => '',
                        DQ_Deal_Qualification_History__c.CC_Initial_Term__c => '',
                        DQ_Deal_Qualification_History__c.Is_ELA__c => '',
                        DQ_Deal_Qualification_History__c.Roll_Out_Plan__c => '',
                        DQ_Deal_Qualification_History__c.Start_Date__c => System.today(),
                        DQ_Deal_Qualification_History__c.True_Up_Terms__c => '',
                        DQ_Deal_Qualification_History__c.Maximum_Potential__c => 10,
                        DQ_Deal_Qualification_History__c.Minimum_Baseline__c => 10,
                        DQ_Deal_Qualification_History__c.ELA_Initial_Terms__c => '',
                        DQ_Deal_Qualification_History__c.Additional_Info__c => '',
                        DQ_Deal_Qualification_History__c.IsDQCreatedFromCPQOpp__c => true,
                        DQ_Deal_Qualification_History__c.Family_Discount__c => 10
                    }
                )
                .build()
                .getRecord();

        DQ_Deal_Qualification__c dq =
            (DQ_Deal_Qualification__c) new SObjectBuilder(DQ_Deal_Qualification__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        DQ_Deal_Qualification__c.Id => '',
                        DQ_Deal_Qualification__c.Deal_Size__c => 10,
                        DQ_Deal_Qualification__c.Minimum_Package_s__c => '',
                        DQ_Deal_Qualification__c.Number_of_DLs__c => 10,
                        DQ_Deal_Qualification__c.Overall_Discount__c => 10,
                        DQ_Deal_Qualification__c.Overall_Discount_One_Time__c => 10,
                        DQ_Deal_Qualification__c.Overall_Discount_Recurring__c => 10,
                        DQ_Deal_Qualification__c.Overall_Discount_Contact_Center__c => 10,
                        DQ_Deal_Qualification__c.Initial_Term__c => '',
                        DQ_Deal_Qualification__c.Status__c => '',
                        DQ_Deal_Qualification__c.Charge_Term__c => '',
                        DQ_Deal_Qualification__c.Special_Terms__c => '',
                        DQ_Deal_Qualification__c.Free_Shipping_Terms_Options__c => '',
                        DQ_Deal_Qualification__c.CC_Special_Terms__c => '',
                        DQ_Deal_Qualification__c.CC_Initial_Term__c => '',
                        DQ_Deal_Qualification__c.Is_ELA__c => '',
                        DQ_Deal_Qualification__c.Roll_Out_Plan__c => '',
                        DQ_Deal_Qualification__c.Start_Date__c => System.today(),
                        DQ_Deal_Qualification__c.True_Up_Terms__c => '',
                        DQ_Deal_Qualification__c.Maximum_Potential__c => 10,
                        DQ_Deal_Qualification__c.Minimum_Baseline__c => 10,
                        DQ_Deal_Qualification__c.ELA_Initial_Terms__c => '',
                        DQ_Deal_Qualification__c.Additional_Info__c => '',
                        DQ_Deal_Qualification__c.IsDQCreatedFromCPQOpp__c => true,
                        DQ_Deal_Qualification__c.Family_Discount__c => 10
                    }
                )
                .build()
                .getRecord();
        Test.startTest();
        DQ_Deal_Qualification_History__c historyToInsert = DealQualificationHandler.buildDqHistoryRecord(existingDq, dq);
        Test.stopTest();
        System.assertEquals(existingDq.Id, historyToInsert.Id, 'Record that is updated should not have Id');
        for (String field : DealQualificationHandler.dqHistoryFieldsToCopyFromDq) {
            System.assertEquals(
                historyToInsert.get(field),
                dq.get(field),
                'dq history Field value should match dq field value'
            );
        }
    }

    @IsTest
    public static void testBuildDqIdToDQHistoryListMap() {
        List<String> dealQualificationIdsList = new List<String>(); 
        dealQualificationIdsList.add((String) new ValueProvider.DummyIdProvider(DQ_Deal_Qualification_History__c.sObjectType).getValue()); 
        for (Integer i = 0; i < 4; i++) {
            dealQualificationIdsList.add((String) new ValueProvider.DummyIdProvider(DQ_Deal_Qualification_History__c.SObjectType.getDescribe().getKeyPrefix() + String.ValueOf(i), 18).getValue()); 
        }

        List<DQ_Deal_Qualification_History__c> dqList =
            (List<DQ_Deal_Qualification_History__c>) new SObjectBuilder(DQ_Deal_Qualification_History__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        DQ_Deal_Qualification_History__c.Deal_Qualification__c => ValueProviderBuilder.provideList(dealQualificationIdsList)
                    }
                )
                .quantity(5)
                .build()
                .getRecords();

        Test.startTest();
            Map<Id, List<DQ_Deal_Qualification_History__c>> dqIdToHistoryList = DealQualificationHandler.buildDqIdToDQHistoryListMap(dqList);
        Test.stopTest();
        System.assertEquals(4, dqIdToHistoryList.keyset().size(), 'Wrong map was built');
        System.assertEquals(
            2,
            dqIdToHistoryList.get(dealQualificationIdsList[0]).size(),
            'Deal qualification should have 2 discount histories assigned'
        );
    }

    @IsTest
    public static void testGetDQHistoryByStatus() {
        List<DQ_Deal_Qualification_History__c> dqList =
            (List<DQ_Deal_Qualification_History__c>) new SObjectBuilder(DQ_Deal_Qualification_History__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        DQ_Deal_Qualification_History__c.Status__c => ValueProviderBuilder.provideList(
                            new List<String> {
                                DealQualificationHandler.DQ_PENDING_STATUS,
                                DealQualificationHandler.DQ_APPROVE_STATUS
                            })
                    }
                )
                .quantity(2)
                .build()
                .getRecords();

        Test.startTest();
            DQ_Deal_Qualification_History__c choosenHistory = DealQualificationHandler.getDQHistoryByStatus(
                dqList,
                DealQualificationHandler.DQ_PENDING_STATUS
            );
        Test.stopTest();
        System.assertEquals(
            DealQualificationHandler.DQ_PENDING_STATUS,
            choosenHistory.Status__c,
            'Wrong record was returned'
        );
    }

    @IsTest
    private static void testBuildDqDiscountHistory() {
        DQ_Deal_Qualification_Discount_History__c dqDiscountHistory =
            (DQ_Deal_Qualification_Discount_History__c) new SObjectBuilder(DQ_Deal_Qualification_Discount_History__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        DQ_Deal_Qualification_Discount_History__c.Id => (Id) new ValueProvider.DummyIdProvider(DQ_Deal_Qualification_Discount_History__c.sObjectType).getValue()
                    }
                )
                .build()
                .getRecord();

        DQ_Deal_Qualification_Discounts__c dqDiscount = (DQ_Deal_Qualification_Discounts__c) new SObjectBuilder(DQ_Deal_Qualification_Discounts__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Deal_Qualification_Discounts__c.Discount__c => 5,
                    DQ_Deal_Qualification_Discounts__c.Discount_Type__c => QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE,
                    DQ_Deal_Qualification_Discounts__c.Product__c => QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE,
                    DQ_Deal_Qualification_Discounts__c.Product_Category__c => '',
                    DQ_Deal_Qualification_Discounts__c.Product_Family__c => '',
                    DQ_Deal_Qualification_Discounts__c.Product_Sub_Categories__c => '',
                    DQ_Deal_Qualification_Discounts__c.Quantity__c => 1,
                    DQ_Deal_Qualification_Discounts__c.Product_Package__c => '',
                    DQ_Deal_Qualification_Discounts__c.PackageName__c => '',
                    DQ_Deal_Qualification_Discounts__c.CPQ_Configured_Product__c => ''
                }
            )
            .build()
            .getRecord();

        DQ_Deal_Qualification_History__c dqHistory =
            (DQ_Deal_Qualification_History__c) new SObjectBuilder(DQ_Deal_Qualification_History__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        DQ_Deal_Qualification_History__c.Id => (Id) new ValueProvider.DummyIdProvider(DQ_Deal_Qualification_History__c.sObjectType).getValue()
                    }
                )
                .build()
                .getRecord();

        Test.startTest();
            DQ_Deal_Qualification_Discount_History__c discountHistory = DealQualificationHandler.buildDqDiscountHistory(
                dqDiscountHistory,
                dqDiscount,
                dqHistory
            );
        Test.stopTest();

        for (String field : DealQualificationHandler.dqDiscountHistoryFieldsToCopyFromDiscount) {
            System.assertEquals(
                dqDiscount.get(field),
                discountHistory.get(field),
                'dq discount history field value should match dq discount field value'
            );
        }
        System.assertEquals(
            dqDiscountHistory.Id,
            discountHistory.Id,
            'Id value is expected to be copied from existing discount history'
        );
    }

    @IsTest
    private static void testHistoryCreateOnDqApprove() {
        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType)
            })
            .create()
            .getRecord();

        DQ_Deal_Qualification__c dq = (DQ_Deal_Qualification__c) new SObjectBuilder(DQ_Deal_Qualification__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                DQ_Deal_Qualification__c.Opportunity__c => testOpp.Id
            })
            .create()
            .getRecord();

        Test.startTest();
            dq.Status__c = DealQualificationHandler.DQ_APPROVE_STATUS;
            update dq;
        Test.stopTest();
        List<DQ_Deal_Qualification_History__c> createdDQHistory = (List<DQ_Deal_Qualification_History__c>) new DealQualificationHistorySelector()
            .selectDQHistory()
            .executeQuery();

        System.assertEquals(1, createdDQHistory.size(), 'Single approved dq history record should exist');
        System.assertEquals(DealQualificationHandler.DQ_APPROVE_STATUS, createdDQHistory.get(0).Status__c, 'Approved status is expected');
        System.assertEquals(dq.Id, createdDQHistory.get(0).Deal_Qualification__c, 'Approved status is expected');
    }

    @IsTest
    private static void testHistoryCreateOnDqCreate() {
        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType)
            })
            .create()
            .getRecord();

        Test.startTest();
            DQ_Deal_Qualification__c dq = (DQ_Deal_Qualification__c) new SObjectBuilder(DQ_Deal_Qualification__c.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    DQ_Deal_Qualification__c.Opportunity__c => testOpp.Id,
                    DQ_Deal_Qualification__c.Status__c => DealQualificationHandler.DQ_PENDING_STATUS
                })
                .create()
                .getRecord();
        Test.stopTest();

        List<DQ_Deal_Qualification_History__c> createdDQHistory = (List<DQ_Deal_Qualification_History__c>) new DealQualificationHistorySelector()
            .selectDQHistory()
            .executeQuery();

        System.assertEquals(1, createdDQHistory.size(), 'Single dq history record should exist');
        System.assertEquals(DealQualificationHandler.DQ_PENDING_STATUS, createdDQHistory.get(0).Status__c, 'Approved status is expected');
        System.assertEquals(dq.Id, createdDQHistory.get(0).Deal_Qualification__c, 'Deal_Qualification__c field on DQ History should relates to assigned DQ object');
    }

    @IsTest
    private static void testHistoryUpdateOnDqApprove() {
        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType)
            })
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.OpportunityId => testOpp.Id,
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo(),
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Approved_Status__c => QuoteHelper.APPROVAL_STATUS_REQUIRED
            })
            .create()
            .getRecord();

        DQ_Deal_Qualification__c dq = (DQ_Deal_Qualification__c) new SObjectBuilder(DQ_Deal_Qualification__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                DQ_Deal_Qualification__c.Opportunity__c => testOpp.Id
            })
            .create()
            .getRecord();

        DQ_Deal_Qualification_History__c existingDQHistory =
            (DQ_Deal_Qualification_History__c) new SObjectBuilder(DQ_Deal_Qualification_History__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        DQ_Deal_Qualification_History__c.Deal_Qualification__c => dq.Id,
                        DQ_Deal_Qualification_History__c.Status__c => DealQualificationHandler.DQ_APPROVE_STATUS
                    }
                )
                .create()
                .getRecord();

        Test.startTest();
        dq.Status__c = DealQualificationHandler.DQ_APPROVE_STATUS;
        update dq;
        Test.stopTest();
        List<DQ_Deal_Qualification_History__c> updatedDQHistory = (List<DQ_Deal_Qualification_History__c>) new DealQualificationHistorySelector()
            .selectDQHistory()
            .executeQuery();

        System.assertEquals(1, updatedDQHistory.size(), 'Single approved dq history record should be created');
        System.assertEquals(DealQualificationHandler.DQ_APPROVE_STATUS, updatedDQHistory.get(0).Status__c, 'Approved status is expected');
        System.assertEquals(dq.Id, updatedDQHistory.get(0).Deal_Qualification__c, 'Approved status is expected');
        System.assertEquals(existingDQHistory.Id, updatedDQHistory.get(0).Id, 'Approved status is expected');
    }

    @IsTest
    private static void testDiscountHistoryCreateOnDqApprove() {
        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType)
            })
            .create()
            .getRecord();

        DQ_Deal_Qualification__c dq = (DQ_Deal_Qualification__c) new SObjectBuilder(DQ_Deal_Qualification__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                DQ_Deal_Qualification__c.Opportunity__c => testOpp.Id
            })
            .create()
            .getRecord();

        new SObjectBuilder(DQ_Deal_Qualification_Discounts__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Deal_Qualification_Discounts__c.Deal_Qualification__c => dq.Id,
                    DQ_Deal_Qualification_Discounts__c.OriginalPackageId__c => ValueProviderBuilder.provideList(
                        new List<String> {'1', '2', '3', '4', '5'}
                    )
                }
            )
            .quantity(5)
            .create();

        Test.startTest();
            dq.Status__c = DealQualificationHandler.DQ_APPROVE_STATUS;
            update dq;
        Test.stopTest();
        List<DQ_Deal_Qualification_Discount_History__c> createdDQDiscountHistory = (List<DQ_Deal_Qualification_Discount_History__c>) new DealQualificationDiscountHistorySelector()
            .selectDQDiscountHistory()
            .executeQuery();

        System.assertEquals(5, createdDQDiscountHistory.size(), 'For every discount item discount history should be created');
    }

    @IsTest
    private static void testDiscountHistoryUpdateOnDqApprove() {
        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType)
            })
            .create()
            .getRecord();

        DQ_Deal_Qualification__c dq = (DQ_Deal_Qualification__c) new SObjectBuilder(DQ_Deal_Qualification__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                DQ_Deal_Qualification__c.Opportunity__c => testOpp.Id
            })
            .create()
            .getRecord();

        DQ_Deal_Qualification_History__c dqHistory =
            (DQ_Deal_Qualification_History__c) new SObjectBuilder(DQ_Deal_Qualification_History__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        DQ_Deal_Qualification_History__c.Deal_Qualification__c => dq.Id,
                        DQ_Deal_Qualification_History__c.Status__c => DealQualificationHandler.DQ_APPROVE_STATUS
                    }
                )
                .create()
                .getRecord();

        new SObjectBuilder(DQ_Deal_Qualification_Discounts__c.SObjectType)
            .setFields(
            new Map<SObjectField, Object>{
                DQ_Deal_Qualification_Discounts__c.Deal_Qualification__c => dq.Id,
                DQ_Deal_Qualification_Discounts__c.PackageName__c => ValueProviderBuilder.provideList(new List<String>{
                    'Package1', 'Package2', 'Package3', 'Package4', 'Package5'
                }),
                DQ_Deal_Qualification_Discounts__c.Product_Category__c => ValueProviderBuilder.provideList(new List<String>{
                    'GOA_All_Contact_Center', 'GOA_Additional_Local_number', 'Device_Contract', 'GOA_Global_Office', 'GOA_IVN_and_GLIP'
                })
            })
            .quantity(5)
            .create();

        new SObjectBuilder(DQ_Deal_Qualification_Discount_History__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Deal_Qualification_Discount_History__c.DQ_Deal_Qualification_History__c => dqHistory.Id,
                    DQ_Deal_Qualification_Discount_History__c.PackageName__c => ValueProviderBuilder.provideList(new List<String>{
                        'Package1', 'Package2', 'Package3', 'Package4'
                    }),
                    DQ_Deal_Qualification_Discount_History__c.Product_Category__c => ValueProviderBuilder.provideList(new List<String>{
                        'GOA_All_Contact_Center', 'GOA_Additional_Local_number', 'Device_Contract', 'GOA_Global_Office'
                    })
                }
            )
            .quantity(4)
            .create();

        Test.startTest();
            dq.Status__c = DealQualificationHandler.DQ_APPROVE_STATUS;
            update dq;
        Test.stopTest();
        List<DQ_Deal_Qualification_Discount_History__c> upsertedDQDiscountHistory = (List<DQ_Deal_Qualification_Discount_History__c>) new DealQualificationDiscountHistorySelector()
            .selectDQDiscountHistory()
            .executeQuery();
        System.assertEquals(5, upsertedDQDiscountHistory.size(), 'Only single discount history record should be created (4 + 1)');
    }

    @IsTest
    private static void testServiceDiscountHistoryCreateOnDqApprove() {
        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType)
            })
            .create()
            .getRecord();

        DQ_Deal_Qualification__c dq = (DQ_Deal_Qualification__c) new SObjectBuilder(DQ_Deal_Qualification__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                DQ_Deal_Qualification__c.Opportunity__c => testOpp.Id,
                DQ_Deal_Qualification__c.Status__c => DealQualificationHandler.DQ_PENDING_STATUS
            })
            .create()
            .getRecord();

        DQ_Deal_Qualification_Service_Discount__c dqSerivceDiscount=
            (DQ_Deal_Qualification_Service_Discount__c) new SObjectBuilder(DQ_Deal_Qualification_Service_Discount__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Deal_Qualification_Service_Discount__c.Deal_Qualification__c => dq.Id,
                    DQ_Deal_Qualification_Service_Discount__c.Service__c => 'test service',
                    DQ_Deal_Qualification_Service_Discount__c.Discretion__c => 10,
                    DQ_Deal_Qualification_Service_Discount__c.WeightedDiscount__c => 5
                }
            )
            .create()
            .getRecord();

        Test.startTest();
            dq.Status__c = DealQualificationHandler.DQ_APPROVE_STATUS;
            update dq;
        Test.stopTest();

        List<DQ_Service_Discount_History__c> dqServiceDiscountHistoryList = new DQServiceDiscountHistorySelector()
            .selectDQServiceDiscountHistory()
            .executeQuery();

        System.assertEquals(1, dqServiceDiscountHistoryList.size(), 'We should have 1 DQ_Service_Discount_History__c record after DQ approve');
        System.assertEquals('test service', dqServiceDiscountHistoryList[0].Service__c, 'Service in DQ Service Discount history should be same as in DQ Service Discount');
    }

    @IsTest
    private static void testServiceDiscountHistoryUpdateOnDqApprove() {
        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType)
            })
            .create()
            .getRecord();

        DQ_Deal_Qualification__c dq = (DQ_Deal_Qualification__c) new SObjectBuilder(DQ_Deal_Qualification__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                DQ_Deal_Qualification__c.Opportunity__c => testOpp.Id,
                DQ_Deal_Qualification__c.Status__c => DealQualificationHandler.DQ_PENDING_STATUS
            })
            .create()
            .getRecord();

        DQ_Deal_Qualification_History__c dqHistory =
            (DQ_Deal_Qualification_History__c) new SObjectBuilder(DQ_Deal_Qualification_History__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        DQ_Deal_Qualification_History__c.Deal_Qualification__c => dq.Id,
                        DQ_Deal_Qualification_History__c.Status__c => DealQualificationHandler.DQ_APPROVE_STATUS
                    }
                )
                .create()
                .getRecord();

        DQ_Deal_Qualification_Service_Discount__c dqServiceDiscount = (DQ_Deal_Qualification_Service_Discount__c) new SObjectBuilder(DQ_Deal_Qualification_Service_Discount__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Deal_Qualification_Service_Discount__c.Deal_Qualification__c => dq.Id,
                    DQ_Deal_Qualification_Service_Discount__c.Service__c => 'test service',
                    DQ_Deal_Qualification_Service_Discount__c.Discretion__c => 10,
                    DQ_Deal_Qualification_Service_Discount__c.WeightedDiscount__c => 5
                }
            )
            .create()
            .getRecord();

        DQ_Service_Discount_History__c dqSerivceDiscountHistory =
            (DQ_Service_Discount_History__c) new SObjectBuilder(DQ_Service_Discount_History__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Service_Discount_History__c.DQ_Deal_Qualification_History__c => dqHistory.Id,
                    DQ_Service_Discount_History__c.Service__c => 'test service',
                    DQ_Service_Discount_History__c.Discretion__c => 10,
                    DQ_Service_Discount_History__c.WeightedDiscount__c => 5
                }
            )
            .create()
            .getRecord();

        Test.startTest();
            dqServiceDiscount.Discretion__c = 15;
            update dqServiceDiscount;
            dq.Status__c = DealQualificationHandler.DQ_APPROVE_STATUS;
            update dq;
        Test.stopTest();

        List<DQ_Service_Discount_History__c> dqServiceDiscountHistoryList = new DQServiceDiscountHistorySelector()
            .selectDQServiceDiscountHistory()
            .executeQuery();

        System.assertEquals(1, dqServiceDiscountHistoryList.size(), 'We should have 1 DQ_Service_Discount_History__c record after DQ approve');
        System.assertEquals(15, dqServiceDiscountHistoryList[0].Discretion__c, 'Discretion should update in DQ Service Discount History after changing in DQ Service Discount');
    }

    @isTest
    static void testSetClosedDateTime() {
        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
        .setFields(new Map<SObjectField, Object> {
            Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
            Opportunity.CloseDate => System.today(),
            Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType)
        })
        .create()
        .getRecord();

        DQ_Deal_Qualification__c dq = (DQ_Deal_Qualification__c) new SObjectBuilder(DQ_Deal_Qualification__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                DQ_Deal_Qualification__c.Opportunity__c => testOpp.Id,
                DQ_Deal_Qualification__c.Status__c => DealQualificationHandler.DQ_PENDING_STATUS
            })
            .create()
            .getRecord();

        dq.Status__c = DQDataHelper.STATUS_REJECTED;
        update dq;

        List<DQ_Deal_Qualification__c> dqList = new DealQualificationSelector()
            .selectDQs()
            .selectFields(new List<Schema.SObjectField> {DQ_Deal_Qualification__c.ClosedDateTime__c})
            .executeQuery();

        System.assertNotEquals(null, dqList.get(0).ClosedDateTime__c, 'Closed DateTime should be populated on DQ Qualification');
    }
}