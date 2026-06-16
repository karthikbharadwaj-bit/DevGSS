@isTest
private class Test_PresignUpActions {

    @TestSetup
    static void makeData() {
        new SObjectBuilder(RCSequence__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                RCSequence__c.SubSequence__c => 134,
                RCSequence__c.SandboxNumber__c => 4
            })
            .create();
    }

    private static POWrappers.SignUpParams generateSignUpParams() {
        POWrappers.SignUpParams data = new POWrappers.SignUpParams();

        SubscriberInfoBuilder.AssignmentData ad = new SubscriberInfoBuilder.AssignmentData();
        ad.parent = new QuoteLineItem();
        ad.quantity = 1;
        data.assignmentsToManual = new List<SubscriberInfoBuilder.AssignmentData> { ad };

        data.targetQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Enabled_LBO__c => false,
                Quote.IsMultiProductTechnicalQuote__c => true,
                Quote.ServiceName__c => OpportunityHelper.TIER_OFFICE
            })
            .build()
            .getRecord();

        data.opportunity = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => ValueProviderBuilder.provideDummyId(Account.sObjectType),
                Opportunity.Id => ValueProviderBuilder.provideDummyId(Opportunity.sObjectType)
            })
            .build()
            .getRecord();

        return data;
    }
    @IsTest
    static void testGetFunnelNotSupported_Positive() {
        POWrappers.SignUpParams data = generateSignUpParams();
        Boolean isMPUB = false;

        Test.startTest();
            String result = PresignUpActions.getFunnelNotSupported(data, isMPUB);
        Test.stopTest();

        String accLink = StringHelper.createObjectLink(data.opportunity.AccountId);
        String oppLink = StringHelper.createObjectLink(data.opportunity.Id);

        Assert.isNotNull(result, 'Returned string must contain data');
        Assert.isTrue(result.contains(accLink), 'Correct account link must present in the result');
        Assert.isTrue(result.contains(oppLink), 'Correct opportunity link must present in the result');
    }

    @IsTest
    static void testGetFunnelNotSupported_Negative() {
        POWrappers.SignUpParams data = generateSignUpParams();
        Boolean isMPUB = false;

        Test.startTest();
            data.targetQuote.ServiceName__c = OpportunityHelper.TIER_RC_CONTACT_CENTER;
            String result1 = PresignUpActions.getFunnelNotSupported(data, isMPUB);

            data.targetQuote.ServiceName__c = OpportunityHelper.TIER_OFFICE;
            SubscriberInfoBuilder.AssignmentData ad = data.assignmentsToManual[0];
            data.assignmentsToManual = new List<SubscriberInfoBuilder.AssignmentData>();
            String result2 = PresignUpActions.getFunnelNotSupported(data, isMPUB);

            data.assignmentsToManual.add(ad);
            isMPUB = true;
            String result3 = PresignUpActions.getFunnelNotSupported(data, isMPUB);
        Test.stopTest();

        Assert.isNull(result1, 'result1 must be null');
        Assert.isNull(result2, 'result2 must be null');
        Assert.isNull(result3, 'result3 must be null');
    }

    @IsTest
    static void testSetEnterpriseAccountId_Positive() {
        POWrappers.SignUpParams data = generateSignUpParams();
        data.targetQuote.ServiceName__c = OpportunityHelper.TIER_RC_CONTACT_CENTER;
        Boolean isMPUB = false;

        Account testAcc = new Account();
        data.opportunity.Account = testAcc;

        Assert.isNull(testAcc.Internal_Enterprise_Account_ID__c, 'Internal_Enterprise_Account_ID__c must be empty');

        Test.startTest();
            PresignUpActions.setEnterpriseAccountId(testAcc, data, isMPUB);
        Test.stopTest();

        Assert.isNotNull(testAcc.Internal_Enterprise_Account_ID__c, 'Internal_Enterprise_Account_ID__c must be populated');
    }

    @IsTest
    static void testSetEnterpriseAccountId_Negative() {
        POWrappers.SignUpParams data = generateSignUpParams();
        Boolean isMPUB = false;

        Account testAcc = new Account();
        data.opportunity.Account = testAcc;

        Assert.isNull(testAcc.Internal_Enterprise_Account_ID__c, 'Internal_Enterprise_Account_ID__c must be empty');

        Test.startTest();
            PresignUpActions.setEnterpriseAccountId(testAcc, data, isMPUB);
            Assert.isNull(testAcc.Internal_Enterprise_Account_ID__c, 'Internal_Enterprise_Account_ID__c must be empty');

            data.targetQuote.ServiceName__c = OpportunityHelper.TIER_OFFICE;
            PresignUpActions.setEnterpriseAccountId(testAcc, data, isMPUB);
            Assert.isNull(testAcc.Internal_Enterprise_Account_ID__c, 'Internal_Enterprise_Account_ID__c must be empty');

            data.targetQuote.ServiceName__c = OpportunityHelper.TIER_RC_CONTACT_CENTER;
            isMPUB = true;
            PresignUpActions.setEnterpriseAccountId(testAcc, data, isMPUB);
            Assert.isNull(testAcc.Internal_Enterprise_Account_ID__c, 'Internal_Enterprise_Account_ID__c must be empty');
        Test.stopTest();
    }

    @IsTest
    static void testPrepopulateAccountFields_Positive() {
        POWrappers.SignUpParams data = generateSignUpParams();

        Test.startTest();
            Account testAcc = PresignUpActions.prepopulateAccountFields(data);
        Test.stopTest();

        Assert.areEqual(data.Opportunity.AccountId, testAcc.Id, 'Account ids should match');
        Assert.isNotNull(testAcc.Funnel_not_supported__c, 'Funnel_not_supported__c must be populated');
    }

    @IsTest
    static void testPrepopulateAccountFields_Negative() {
        POWrappers.SignUpParams data;

        Test.startTest();
            Account testAcc = PresignUpActions.prepopulateAccountFields(data);
        Test.stopTest();

        Assert.isNotNull(testAcc, 'Account must exist');
    }

    @IsTest
    static void testGetMasterAccountId_Positive() {
        POWrappers.SignUpParams data = generateSignUpParams();
        Id targetId = data.opportunity.AccountId;

        Test.startTest();
            Id testId1 = PresignUpActions.getMasterAccountId(new List<POWrappers.SignUpParams> { data });

            data.masterAcc = new Account(Id = targetId);
            Id testId2 = PresignUpActions.getMasterAccountId(new List<POWrappers.SignUpParams> { data });
        Test.stopTest();

        Assert.areEqual(targetId, testId1, 'Account ids should match');
        Assert.areEqual(targetId, testId2, 'Account ids should match');
    }

    @IsTest
    static void testGetMasterAccountId_Negative() {
        Test.startTest();
            Id testId = PresignUpActions.getMasterAccountId(new List<POWrappers.SignUpParams>());
        Test.stopTest();

        Assert.isNull(testId, 'Id should be null');
    }

    @IsTest
    static void testGetTechAccIdToTechOppIdMap_Positive() {
        POWrappers.SignUpParams data = generateSignUpParams();
        Id accId = data.opportunity.AccountId;
        Id oppId = data.opportunity.Id;
        data.masterAcc = new Account();

        Test.startTest();
            Map<Id, Id> techAccIdToTechOppId  = PresignUpActions.getTechAccIdToTechOppIdMap(new List<POWrappers.SignUpParams> { data });
        Test.stopTest();

        Assert.isFalse(techAccIdToTechOppId.isEmpty(), 'Map must contain value');
        Assert.isTrue(techAccIdToTechOppId.containsKey(accId), 'Map should contain account id as key');
        Assert.areEqual(oppId, techAccIdToTechOppId.get(accId), 'Opp ids should match');
    }

    @IsTest
    static void testGetTechAccIdToTechOppIdMap_Negative() {
        Test.startTest();
            Map<Id, Id> techAccIdToTechOppId  = PresignUpActions.getTechAccIdToTechOppIdMap(new List<POWrappers.SignUpParams>());
        Test.stopTest();

        Assert.isTrue(techAccIdToTechOppId.isEmpty(), 'Map should be empty');
    }

    @IsTest
    static void testGetTaxExemptsOnProcessOrder_Positive() {
        POWrappers.SignUpParams data = new POWrappers.SignUpParams();

        Triggers.switchOff();
        Account masterAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'MASTER_ACCOUNT_NAME',
                Account.BillingStreet => 'test street',
                Account.BillingCity => 'Chicago',
                Account.BillingState => 'Alabama',
                Account.BillingPostalCode => '12345',
                Account.BillingCountry => 'AUT'
            })
            .create()
            .getRecord();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'TECH_ACCOUNT_NAME',
                Account.Master_Account__c => masterAcc.Id,
                Account.IsMultiProductTechnicalAccount__c => true
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => acc.Id,
                Opportunity.CloseDate => Date.today(),
                Opportunity.Name => 'OPP_NAME',
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS
            })
            .create()
            .getRecord();

        new SObjectBuilder(Approval__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Approval__c.Account__c => masterAcc.Id,
                Approval__c.Status__c => ApprovalHelper.STATUS_APPROVED,
                Approval__c.RecordTypeId => ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL
            })
            .create();

        Triggers.switchOn();

        data.opportunity = opp;
        data.masterAcc = masterAcc;

        Test.startTest();
            List<Approval__c> approvals = PresignUpActions.getTaxExemptsOnProcessOrder(new List<POWrappers.SignUpParams> { data });
        Test.stopTest();

        Assert.isFalse(approvals.isEmpty(), 'Approval should be created');
    }

    @IsTest
    static void testGetTaxExemptsOnProcessOrder_Negative() {
        Test.startTest();
            List<Approval__c> approvals = PresignUpActions.getTaxExemptsOnProcessOrder(new List<POWrappers.SignUpParams>());
        Test.stopTest();

        Assert.isTrue(approvals.isEmpty(), 'No approvals should be created');
    }

    @IsTest
    static void testUpsertFunnelStatus_Insert() {

        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'MASTER_ACCOUNT_NAME',
                Account.BillingStreet => 'test street',
                Account.BillingCity => 'Chicago',
                Account.BillingState => 'Alabama',
                Account.BillingPostalCode => '12345',
                Account.BillingCountry => 'AUT'
            })
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test opptyMPL',
                    Opportunity.AccountId => testAcc.Id,
                    Opportunity.isMultiproductTechnicalOpportunity__c => false,
                    Opportunity.CloseDate => Date.today()
                }
            )
            .create()
            .getRecord();


        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => testOpp.Id,
                    Quote.IsMultiProductTechnicalQuote__c => false,
                    Quote.MasterQuote__c => null,
                    Quote.isPrimary__c => true
                }
            )
            .create()
            .getRecord();

        User testUser = (User) new SObjectBuilder(User.SObjectType)
            .build()
            .getRecord();

        System.runAs(testUser) {
            Test.startTest();
                PresignUpActions.upsertFunnelStatus(testOpp.Id);
            Test.stopTest();

            SalesFunnelStatus__c resultSalesFunnelStatus = (SalesFunnelStatus__c) new ListOptional(new SalesFunnelStatusSelector()
                .selectSalesFunnelStatusByOppIdAndSalesAgentId(testOpp.Id, UserInfo.getUserId())
                .executeQuery()
            ).getFirst();

            Assert.isNotNUll(resultSalesFunnelStatus, 'SalesFunnelStatus__c record must be created');
            Assert.isTrue(resultSalesFunnelStatus.IsRequestOpen__c, 'IsRequestOpen__c must be true');
        }
    }

    @IsTest
    static void testUpsertFunnelStatus_InsertUnderSalesUser() {
        Profile salesProfile = (Profile) new ProfileSelector()
        .selectProfileByName(ProfileHelper.PROFILE_NAME_SALES_REP_LIGHTNING)
        .executeQuery()
        .get(0);

    User salesUser = (User) new SObjectBuilder(User.SObjectType)
        .setField(User.ProfileId, salesProfile.Id)
        .create()
        .getRecord();

        Triggers.switchOff();

        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'MASTER_ACCOUNT_NAME',
                Account.BillingStreet => 'test street',
                Account.BillingCity => 'Chicago',
                Account.BillingState => 'Alabama',
                Account.BillingPostalCode => '12345',
                Account.BillingCountry => 'AUT'
            })
            .createAsUser(salesUser)
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test opptyMPL',
                    Opportunity.AccountId => testAcc.Id,
                    Opportunity.isMultiproductTechnicalOpportunity__c => false,
                    Opportunity.CloseDate => Date.today()
                }
            )
            .createAsUser(salesUser)
            .getRecord();


        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => testOpp.Id,
                    Quote.IsMultiProductTechnicalQuote__c => false,
                    Quote.MasterQuote__c => null,
                    Quote.isPrimary__c => true
                }
            )
            .createAsUser(salesUser)
            .getRecord();

        Triggers.switchOn();

        Test.startTest();
            System.runAs(salesUser) {
                PresignUpActions.upsertFunnelStatus(testOpp.Id);
            }
        Test.stopTest();

        SalesFunnelStatus__c resultSalesFunnelStatus = (SalesFunnelStatus__c) new ListOptional(new SalesFunnelStatusSelector()
                .selectSalesFunnelStatusByOppIdAndSalesAgentId(testOpp.Id, salesUser.Id)
                .executeQuery()
            ).getFirst();
        Assert.isNotNUll(resultSalesFunnelStatus, 'Sales user must be able to create SalesFunnelStatus__c record when Process Order is on');
        Assert.isTrue(resultSalesFunnelStatus.IsRequestOpen__c, 'IsRequestOpen__c must be true');
    }

    @IsTest
    static void testUpsertFunnelStatus_Upsert() {
        IValueProvider oppIdProvider = ValueProviderBuilder.provideGenericParent(Opportunity.SObjectType);
        Id oppId = (Id) oppIdProvider.getValue();

        User testUser = (User) new SObjectBuilder(User.SObjectType)
            .build()
            .getRecord();

        System.runAs(testUser) {
            SalesFunnelStatus__c testSalesFunnelStatus = (SalesFunnelStatus__c) new SObjectBuilder(SalesFunnelStatus__c.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    SalesFunnelStatus__c.IsRequestOpen__c => false,
                    SalesFunnelStatus__c.Opportunity__c => oppIdProvider,
                    SalesFunnelStatus__c.Sales_Agent__c => UserInfo.getUserId()
                })
                .create()
                .getRecord();

                Assert.isFalse(testSalesFunnelStatus.IsRequestOpen__c, 'IsRequestOpen__c must be false');

            Test.startTest();
                PresignUpActions.upsertFunnelStatus(oppId);
            Test.stopTest();

            testSalesFunnelStatus = (SalesFunnelStatus__c) new ListOptional(new SalesFunnelStatusSelector()
                .selectSalesFunnelStatusByOppIdAndSalesAgentId(oppId, UserInfo.getUserId())
                .executeQuery()
            ).getFirst();

            Assert.isTrue(testSalesFunnelStatus.IsRequestOpen__c, 'IsRequestOpen__c must be changed to true');
        }
    }

    @IsTest
    static void testDeleteSalesFunnelStatusRecord() {
        IValueProvider oppIdProvider = ValueProviderBuilder.provideGenericParent(Opportunity.SObjectType);
        Id oppId = (Id) oppIdProvider.getValue();

        User testUser = (User) new SObjectBuilder(User.SObjectType)
            .build()
            .getRecord();

        System.runAs(testUser) {
            new SObjectBuilder(SalesFunnelStatus__c.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    SalesFunnelStatus__c.IsRequestOpen__c => false,
                    SalesFunnelStatus__c.Opportunity__c => oppIdProvider,
                    SalesFunnelStatus__c.Sales_Agent__c => UserInfo.getUserId()
                })
                .create();

            Test.startTest();
                PresignUpActions.deleteSalesFunnelStatusRecord(oppId);
            Test.stopTest();

            SalesFunnelStatus__c testSalesFunnelStatus = (SalesFunnelStatus__c) new ListOptional(new SalesFunnelStatusSelector()
                .selectSalesFunnelStatusByOppIdAndSalesAgentId(oppId, UserInfo.getUserId())
                .executeQuery()
            ).getFirst();

            Assert.isNull(testSalesFunnelStatus, 'Record must be deleted');
        }
    }

    @IsTest
    static void testUpsertFunnelStatusWithTargetIds_Insert() {
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'MASTER_ACCOUNT_NAME',
                Account.BillingStreet => 'test street',
                Account.BillingCity => 'Chicago',
                Account.BillingState => 'Alabama',
                Account.BillingPostalCode => '12345',
                Account.BillingCountry => 'AUT'
            })
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test opptyMPUB',
                    Opportunity.AccountId => testAcc.Id,
                    Opportunity.isMultiproductTechnicalOpportunity__c => true,
                    Opportunity.CloseDate => Date.today()
                }
            )
            .create()
            .getRecord();

        Quote masterQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => testOpp.Id,
                    Quote.IsMultiProductTechnicalQuote__c => false,
                    Quote.MasterQuote__c => null,
                    Quote.isPrimary__c => true
                }
            )
            .create()
            .getRecord();

        Quote techQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => testOpp.Id,
                    Quote.IsMultiProductTechnicalQuote__c => true,
                    Quote.MasterQuote__c => masterQuote.Id,
                    Quote.isPrimary__c => false,
                    Quote.ServiceName__c => OpportunityHelper.TIER_OFFICE
                }
            )
            .create()
            .getRecord();

        User testUser = (User) new SObjectBuilder(User.SObjectType)
            .build()
            .getRecord();

        Set<Id> targetIds = new Set<Id> { masterQuote.Id, techQuote.Id };

        System.runAs(testUser) {
            Test.startTest();
                PresignUpActions.upsertFunnelStatus(targetIds, testOpp.Id);
            Test.stopTest();

            SalesFunnelStatus__c resultSalesFunnelStatus = (SalesFunnelStatus__c) new ListOptional(new SalesFunnelStatusSelector()
                .selectSalesFunnelStatusByOppIdAndSalesAgentIdAndQuoteIds(testOpp.Id, UserInfo.getUserId(), targetIds)
                .executeQuery()
            ).getFirst();

            Assert.isNotNUll(resultSalesFunnelStatus, 'SalesFunnelStatus__c record must be created');
            Assert.isTrue(resultSalesFunnelStatus.IsRequestOpen__c, 'IsRequestOpen__c must be true');            
        }
    }

    @IsTest
    static void testUpsertFunnelStatusWithTargetIds_Upsert() {
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'MASTER_ACCOUNT_NAME',
                Account.BillingStreet => 'test street',
                Account.BillingCity => 'Chicago',
                Account.BillingState => 'Alabama',
                Account.BillingPostalCode => '12345',
                Account.BillingCountry => 'AUT'
            })
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test opptyMPUB',
                    Opportunity.AccountId => testAcc.Id,
                    Opportunity.isMultiproductTechnicalOpportunity__c => true,
                    Opportunity.CloseDate => Date.today()
                }
            )
            .create()
            .getRecord();

        Quote masterQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => testOpp.Id,
                    Quote.IsMultiProductTechnicalQuote__c => false,
                    Quote.MasterQuote__c => null,
                    Quote.isPrimary__c => true
                }
            )
            .create()
            .getRecord();

        Quote techQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => testOpp.Id,
                    Quote.IsMultiProductTechnicalQuote__c => true,
                    Quote.MasterQuote__c => masterQuote.Id,
                    Quote.isPrimary__c => false,
                    Quote.ServiceName__c => OpportunityHelper.TIER_OFFICE
                }
            )
            .create()
            .getRecord();

        User testUser = (User) new SObjectBuilder(User.SObjectType)
            .build()
            .getRecord();

        Set<Id> targetIds = new Set<Id> { masterQuote.Id, techQuote.Id };

        System.runAs(testUser) {
            // Create existing SalesFunnelStatus record
            SalesFunnelStatus__c existingSFS = (SalesFunnelStatus__c) new SObjectBuilder(SalesFunnelStatus__c.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    SalesFunnelStatus__c.IsRequestOpen__c => false,
                    SalesFunnelStatus__c.Opportunity__c => testOpp.Id,
                    SalesFunnelStatus__c.Sales_Agent__c => UserInfo.getUserId(),
                    SalesFunnelStatus__c.Quote__c => techQuote.Id
                })
                .create()
                .getRecord();

            Assert.isFalse(existingSFS.IsRequestOpen__c, 'IsRequestOpen__c must be false initially');

            Test.startTest();
                PresignUpActions.upsertFunnelStatus(targetIds, testOpp.Id);
            Test.stopTest();

            SalesFunnelStatus__c resultSalesFunnelStatus = (SalesFunnelStatus__c) new ListOptional(new SalesFunnelStatusSelector()
                .selectSalesFunnelStatusByOppIdAndSalesAgentIdAndQuoteIds(testOpp.Id, UserInfo.getUserId(), targetIds)
                .executeQuery()
            ).getFirst();

            Assert.isNotNUll(resultSalesFunnelStatus, 'SalesFunnelStatus__c record must exist');
            Assert.isTrue(resultSalesFunnelStatus.IsRequestOpen__c, 'IsRequestOpen__c must be changed to true');
            Assert.areEqual(existingSFS.Id, resultSalesFunnelStatus.Id, 'Should update existing record');
        }
    }

    
}