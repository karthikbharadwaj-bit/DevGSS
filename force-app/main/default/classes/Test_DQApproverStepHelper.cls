@isTest
private class Test_DQApproverStepHelper {

    @TestSetup
    static void setupTestData() {
        User testManager = createUserWithLastName('TestManager', null);
        User testOppOwner = createUserWithLastName('TestOppOwner', testManager.Id);
        User testApprover = createUserWithLastName('TestApprover', null);

        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test Account')
            .create()
            .getRecord();

        // Create DQ_Approval_Step__c records (Level 1, 2, 3 with Step_Order 1, 2, 3)
        List<DQ_Approval_Step__c> steps = (List<DQ_Approval_Step__c>) new SObjectBuilder(DQ_Approval_Step__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Approval_Step__c.Name => ValueProviderBuilder.provideList(new List<String>{'Level 1', 'Level 2', 'Level 3'}),
                    DQ_Approval_Step__c.Step_Order__c => ValueProviderBuilder.provideList(new List<Decimal>{1, 2, 3})
                }
            )
            .quantity(3)
            .create()
            .getRecords();

        // Create additional steps for testGetMaxStepOrder (Step_Order 1, 3, 7)
        List<DQ_Approval_Step__c> stepsForMaxOrder = (List<DQ_Approval_Step__c>) new SObjectBuilder(DQ_Approval_Step__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Approval_Step__c.Step_Order__c => ValueProviderBuilder.provideList(new List<Decimal>{1, 3, 7})
                }
            )
            .quantity(3)
            .create()
            .getRecords();

        // Create DQ_Approval_Type__c records
        DQ_Approval_Type__c commonType = (DQ_Approval_Type__c) new SObjectBuilder(DQ_Approval_Type__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Approval_Type__c.IsActive__c => true,
                    DQ_Approval_Type__c.isUnifiedQuotingApprovalType__c => true,
                    DQ_Approval_Type__c.Approval_Type__c => DQApprovalTypeHelper.APPROVAL_TYPE_DISCOUNT,
                    DQ_Approval_Type__c.Product_Category__c => 'Device_Contract',
                    DQ_Approval_Type__c.Threshold__c => 50,
                    DQ_Approval_Type__c.ServiceName__c => null
                }
            )
            .create()
            .getRecord();

        DQ_Approval_Type__c nullServiceType = (DQ_Approval_Type__c) new SObjectBuilder(DQ_Approval_Type__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Approval_Type__c.IsActive__c => true,
                    DQ_Approval_Type__c.isUnifiedQuotingApprovalType__c => true,
                    DQ_Approval_Type__c.Approval_Type__c => DQApprovalTypeHelper.APPROVAL_TYPE_DISCOUNT,
                    DQ_Approval_Type__c.ServiceName__c => null
                }
            )
            .create()
            .getRecord();

        DQ_Approval_Type__c proServType = (DQ_Approval_Type__c) new SObjectBuilder(DQ_Approval_Type__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Approval_Type__c.IsActive__c => true,
                    DQ_Approval_Type__c.isUnifiedQuotingApprovalType__c => true,
                    DQ_Approval_Type__c.Approval_Type__c => DQApprovalTypeHelper.APPROVAL_TYPE_DISCOUNT,
                    DQ_Approval_Type__c.ServiceName__c => QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT
                }
            )
            .create()
            .getRecord();
    }

    private static User createUser() {
        return createUser(null);
    }

    private static User createUser(Id managerId) {
        SObjectBuilder userBuilder = new SObjectBuilder(User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.Username => UserHelper.getUniqueUserName(),
                    User.LastName => ValueProviderBuilder.provideUniqueString('LastName'),
                    User.ProfileId => ProfileHelper.PROFILE_ID_SYSADMIN,
                    User.Email => ValueProviderBuilder.provideUniqueEmail(),
                    User.Alias => StringHelper.getRandomString(8),
                    User.CommunityNickname => ValueProviderBuilder.provideUniqueString('TestUser'),
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

    private static User createUserWithLastName(String lastName, Id managerId) {
        String nicknameBase = lastName.length() > 35 ? lastName.substring(0, 35) : lastName;
        
        SObjectBuilder userBuilder = new SObjectBuilder(User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.Username => UserHelper.getUniqueUserName(),
                    User.LastName => lastName,
                    User.ProfileId => ProfileHelper.PROFILE_ID_SYSADMIN,
                    User.Email => ValueProviderBuilder.provideUniqueEmail(),
                    User.Alias => StringHelper.getRandomString(8),
                    User.CommunityNickname => ValueProviderBuilder.provideUniqueString(nicknameBase),
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

    @IsTest
    static void testGetApproverStepData() {
        Test.startTest();
        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                Opportunity.Name => ValueProviderBuilder.provideUniqueString('test opportunity')
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

        User testApprover = createUser();

        DQ_Approval_Step__c dqApprovalStep = (DQ_Approval_Step__c) new SObjectBuilder(DQ_Approval_Step__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Approval_Step__c.Name => 'Level 1',
                    DQ_Approval_Step__c.Step_Order__c => 1
                }
            )
            .create()
            .getRecord();

        DQ_Approval_Type__c testDqApprovalType = (DQ_Approval_Type__c) new SObjectBuilder(DQ_Approval_Type__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Approval_Type__c.IsActive__c => true,
                    DQ_Approval_Type__c.isUnifiedQuotingApprovalType__c => true,
                    DQ_Approval_Type__c.Approval_Type__c => DQApprovalTypeHelper.APPROVAL_TYPE_DISCOUNT,
                    DQ_Approval_Type__c.Product_Category__c => 'Device_Contract',
                    DQ_Approval_Type__c.Threshold__c => 50
                }
            )
            .create()
            .getRecord();

        DQ_Approval_Type_Step__c dqApprovalTypeStep =
            (DQ_Approval_Type_Step__c) new SObjectBuilder(DQ_Approval_Type_Step__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Approval_Type_Step__c.DQ_Approval_Type__c => testDqApprovalType.Id,
                    DQ_Approval_Type_Step__c.DQ_Approval_Step__c => dqApprovalStep.Id

                }
            )
            .create()
            .getRecord();

        DQ_Approval_Step_Approver__c dqApprovalTypeStepApprover =
            (DQ_Approval_Step_Approver__c) new SObjectBuilder(DQ_Approval_Step_Approver__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Approval_Step_Approver__c.OwnerId => testApprover.Id,
                    DQ_Approval_Step_Approver__c.DQ_Approval_Step__c => dqApprovalStep.Id
                }
            )
            .create()
            .getRecord();


        final String testApprovalReason = 'Discount exceeds threshold';
        Map<Id, String> approvalTypeIdToReasonMap = new Map<Id, String>{
            testDqApprovalType.Id => testApprovalReason
        };
        DQDataHelper.DealQualificationData dqData = new DQDataHelper.DealQualificationData();
        dqData.mainQuoteData = new DQDataHelper.QuoteData(testQuote);

        List<DQApproverStepHelper.ApproverStepData> result = DQApproverStepHelper.getApproverStepData(approvalTypeIdToReasonMap, dqData, false);
        Test.stopTest();
        System.assert(result != null, 'method should return not empty result');
        System.assert(!result.isEmpty(), 'method should return not empty result');

        DQApproverStepHelper.ApproverStepData data = result.get(0);
        System.assertEquals(
            testApprovalReason,
            data.approvalReason,
            'ApproverStepData should contain approval reason'
        );
        System.assertEquals(
            dqApprovalStep.Id,
            data.approvalStep.Id,
            'ApproverStepData should contain DQ_Approval_Step__c associated with DQ_Approval_Type__c ' +
            'whose Id was passed in the map(approvalTypeIdToReasonMap) as argument'
        );

        System.assert(!data.stepApproversList.isEmpty(), 'ApproverStepData should contain not-empty stepApproversList');
        DQ_Approval_Step_Approver__c stepApprover = data.stepApproversList.get(0);
        System.assertEquals(
            dqApprovalTypeStepApprover.Id,
            stepApprover.Id,
            'ApproverStepData should contain DQ_Approval_Step_Approver__c associated with DQ_Approval_Type__c ' +
            'whose Id was passed in the map(approvalTypeIdToReasonMap) as argument'
        );

        System.assertEquals(
            testApprover.Id,
            stepApprover.OwnerId,
            'the owner of the DQ_Approval_Step_Approver__c record will be the actual approver for current step'
        );
    }

    @IsTest
    static void testAddOpportunityOwnerApproval() {
        System.assertEquals(
            null,
            DQApproverStepHelper.addOpportunityOwnerApproval(null, null),
            'method should return null if passed params are empty'
        );

        List<User> testManagers = [SELECT Id FROM User WHERE LastName = 'TestManager' LIMIT 1];
        List<User> testOppOwners = [SELECT Id FROM User WHERE LastName = 'TestOppOwner' LIMIT 1];
        List<Account> testAccounts = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        System.assert(!testManagers.isEmpty(), 'TestManager should exist from @testSetup');
        System.assert(!testOppOwners.isEmpty(), 'TestOppOwner should exist from @testSetup');
        System.assert(!testAccounts.isEmpty(), 'TestAccount should exist from @testSetup');
        
        User testManager = testManagers[0];
        User testOppOwner = testOppOwners[0];
        Account testAccount = testAccounts[0];

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => testAccount.Id,
                    Opportunity.Name => 'Test Opportunity',
                    Opportunity.OwnerId => testOppOwner.Id,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL
                }
            )
            .create()
            .getRecord();

        DQDataHelper.DealQualificationData dqData = new DQDataHelper.DealQualificationData();
        dqData.opportunityData.oppId = testOpp.Id;

        List<DQ_Approval_Step__c> level1Steps = [SELECT Id, Name, Step_Order__c FROM DQ_Approval_Step__c WHERE Name = 'Level 1' AND Step_Order__c = 1 LIMIT 1];
        System.assert(!level1Steps.isEmpty(), 'Level 1 step should exist from @testSetup');
        DQ_Approval_Step__c level1Step = level1Steps[0];
        DQApproverStepHelper.ApproverStepData stepData = new DQApproverStepHelper.ApproverStepData();
        stepData.approvalStep = level1Step;

        List<DQApproverStepHelper.ApproverStepData> resultList = DQApproverStepHelper.addOpportunityOwnerApproval(
            dqData,
            new List<DQApproverStepHelper.ApproverStepData>{stepData}
        );

        DQApproverStepHelper.ApproverStepData result = resultList.get(0);
        System.assert(result.managerDetail != null, 'method should populate managerDetail');
        System.assertEquals(
            testManager.Id,
            result.managerDetail.Id,
            'managerDetail user should be a manager of the opportunity owner'
        );

        System.assert(!result.stepApproversList.isEmpty(), 'method should add additional stepApprover');
        DQ_Approval_Step_Approver__c stepApprover = result.stepApproversList.get(0);
        System.assertEquals(
            testOpp.Brand_Name__c,
            stepApprover.Brand__c,
            'Brand__c on stepApprover should match the Brand_Name__c on Opportunity'
        );
        String expectedApprovalTypeMessage = 'Approval_Type__c on stepApprover should be "Approval" when Level 1 is the latest step, or "Notification" when it is not';
        System.assert(
            stepApprover.Approval_Type__c == 'Approval' || stepApprover.Approval_Type__c == 'Notification',
            expectedApprovalTypeMessage
        );
        System.assertEquals(
            testManager.Id,
            stepApprover.OwnerId,
            'OwnerId on stepApprover should be Id of Opportunity manager'
        );
    }

    @IsTest
    static void testAddOpportunityOwnerApproval2() {
        System.assertEquals(
            null,
            DQApproverStepHelper.addOpportunityOwnerApproval(null, null),
            'method should return null if passed params are empty'
        );

        List<Group> dealDeskQueues = [SELECT Id FROM Group WHERE DeveloperName = 'Deal_Desk' LIMIT 1];
        if (dealDeskQueues.isEmpty()) {
            return; // Skip test if Deal Desk queue doesn't exist
        }
        Id dealDeskQueueId = dealDeskQueues[0].Id;

        User testOppOwner = createUser(); // Create user without manager for this test
        List<Account> testAccounts = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        System.assert(!testAccounts.isEmpty(), 'TestAccount should exist from @testSetup');
        Account testAccount = testAccounts[0];

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => testAccount.Id,
                    Opportunity.Name => 'Test Opportunity',
                    Opportunity.OwnerId => testOppOwner.Id,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL
                }
            )
            .create()
            .getRecord();

        DQDataHelper.DealQualificationData dqData = new DQDataHelper.DealQualificationData();
        dqData.opportunityData.oppId = testOpp.Id;

        List<DQ_Approval_Step__c> level1Steps = [SELECT Id, Name, Step_Order__c FROM DQ_Approval_Step__c WHERE Name = 'Level 1' AND Step_Order__c = 1 LIMIT 1];
        System.assert(!level1Steps.isEmpty(), 'Level 1 step should exist from @testSetup');
        DQ_Approval_Step__c level1Step = level1Steps[0];
        DQApproverStepHelper.ApproverStepData stepData = new DQApproverStepHelper.ApproverStepData();
        stepData.approvalStep = level1Step;

        List<DQApproverStepHelper.ApproverStepData> resultList = DQApproverStepHelper.addOpportunityOwnerApproval(
            dqData,
            new List<DQApproverStepHelper.ApproverStepData>{stepData}
        );

        DQApproverStepHelper.ApproverStepData result = resultList.get(0);
        System.assert(result.dealDeskDetail != null, 'method should populate deal desk queue');
        
        System.assert(!result.stepApproversList.isEmpty(), 'method should add additional stepApprover');
        DQ_Approval_Step_Approver__c stepApprover = result.stepApproversList.get(0);
        System.assertEquals(
            testOpp.Brand_Name__c,
            stepApprover.Brand__c,
            'Brand__c on stepApprover should match the Brand_Name__c on Opportunity'
        );
        String expectedApprovalTypeMessage = 'Approval_Type__c on stepApprover should be "Approval" when Level 1 is the latest step, or "Notification" when it is not';
        System.assert(
            stepApprover.Approval_Type__c == 'Approval' || stepApprover.Approval_Type__c == 'Notification',
            expectedApprovalTypeMessage
        );
        System.assertEquals(
            dealDeskQueueId,
            stepApprover.OwnerId,
            'OwnerId on stepApprover should be Id of Deal Desk Queue'
        );
    }

    @IsTest
    static void testGetMaxStepOrder() {
        System.assertEquals(
            0,
            DQApproverStepHelper.getMaxStepOrder(null).get(DQApproverStepHelper.APPROVAL_COMMON_SERVICE),
            'getMaxStepOrder method should return 0 if argument is empty'
        );

        List<DQ_Approval_Step__c> dqApprovalSteps = [
            SELECT Id, Step_Order__c 
            FROM DQ_Approval_Step__c 
            WHERE Step_Order__c IN (1, 3, 7)
            ORDER BY Step_Order__c
        ];
        
        System.assert(dqApprovalSteps.size() >= 3, 'Should have at least 3 steps with Step_Order 1, 3, 7 from @testSetup');

        DQ_Approval_Step__c step1 = null;
        DQ_Approval_Step__c step3 = null;
        DQ_Approval_Step__c step7 = null;
        
        for (DQ_Approval_Step__c step : dqApprovalSteps) {
            if (step.Step_Order__c == 1 && step1 == null) {
                step1 = step;
            } else if (step.Step_Order__c == 3 && step3 == null) {
                step3 = step;
            } else if (step.Step_Order__c == 7 && step7 == null) {
                step7 = step;
            }
        }
        
        System.assert(step1 != null, 'Step with order 1 should exist');
        System.assert(step3 != null, 'Step with order 3 should exist');
        System.assert(step7 != null, 'Step with order 7 should exist');

        Map<Id, String> stepIdToServiceName1 = new Map<Id, String>();
        stepIdToServiceName1.put(step1.Id, 'Office');
        Map<Id, String> stepIdToServiceName2 = new Map<Id, String>();
        stepIdToServiceName2.put(step3.Id, 'Office');
        Map<Id, String> stepIdToServiceName3 = new Map<Id, String>();
        stepIdToServiceName3.put(step7.Id, 'Office');

        DQApproverStepHelper.ApproverStepData stepData1 = new DQApproverStepHelper.ApproverStepData();
        stepData1.approvalStep = step1;
        stepData1.stepApproversList.add(new DQ_Approval_Step_Approver__c());
        stepData1.stepApproversList.add(new DQ_Approval_Step_Approver__c());
        stepData1.stepIdToServiceName = stepIdToServiceName1;

        DQApproverStepHelper.ApproverStepData stepData2 = new DQApproverStepHelper.ApproverStepData();
        stepData2.approvalStep = step3;
        stepData2.stepApproversList.add(new DQ_Approval_Step_Approver__c());
        stepData2.stepApproversList.add(new DQ_Approval_Step_Approver__c());
        stepData2.stepIdToServiceName = stepIdToServiceName2;

        DQApproverStepHelper.ApproverStepData stepData3 = new DQApproverStepHelper.ApproverStepData();
        stepData3.approvalStep = step7;
        stepData3.stepApproversList.add(new DQ_Approval_Step_Approver__c());
        stepData3.stepApproversList.add(new DQ_Approval_Step_Approver__c());
        stepData3.stepIdToServiceName = stepIdToServiceName3;

        List<DQApproverStepHelper.ApproverStepData> stepDataList = new List<DQApproverStepHelper.ApproverStepData>{
            stepData1, stepData2, stepData3
        };

        System.assertEquals(
            7,
            DQApproverStepHelper.getMaxStepOrder(stepDataList).get(DQApproverStepHelper.APPROVAL_COMMON_SERVICE),
            'getMaxStepOrder method should return max Step_Order__c value'
        );
    }

    @IsTest
    static void testGetMaxStepOrderWithEmptyStepIdToServiceName() {
        List<DQ_Approval_Step__c> dqApprovalSteps = [
            SELECT Id, Step_Order__c 
            FROM DQ_Approval_Step__c 
            WHERE Name IN ('Level 1', 'Level 2', 'Level 3') AND Step_Order__c IN (1, 2, 3)
            ORDER BY Step_Order__c
        ];
        
        System.assert(dqApprovalSteps.size() >= 3, 'Should have at least 3 steps (Level 1, 2, 3) from @testSetup');

        List<DQ_Approval_Type__c> dqApprovalTypes = [
            SELECT Id 
            FROM DQ_Approval_Type__c 
            WHERE ServiceName__c = null AND isUnifiedQuotingApprovalType__c = true 
            LIMIT 1
        ];
        System.assert(!dqApprovalTypes.isEmpty(), 'DQ_Approval_Type__c with null ServiceName should exist from @testSetup');
        DQ_Approval_Type__c dqApprovalType = dqApprovalTypes[0];

        List<DQ_Approval_Type_Step__c> dqApprovalTypeSteps = (List<DQ_Approval_Type_Step__c>) new SObjectBuilder(DQ_Approval_Type_Step__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Approval_Type_Step__c.DQ_Approval_Type__c => dqApprovalType.Id,
                    DQ_Approval_Type_Step__c.DQ_Approval_Step__c => ValueProviderBuilder.provideList(new List<Id>{
                        dqApprovalSteps.get(0).Id,
                        dqApprovalSteps.get(1).Id,
                        dqApprovalSteps.get(2).Id
                    })
                }
            )
            .quantity(3)
            .create()
            .getRecords();

        List<DQ_Approval_Type_Step__c> queriedApprovalTypeSteps = [
            SELECT Id, DQ_Approval_Type__c, DQ_Approval_Type__r.ServiceName__c, DQ_Approval_Step__c
            FROM DQ_Approval_Type_Step__c
            WHERE Id IN :dqApprovalTypeSteps
        ];
        
        System.assert(queriedApprovalTypeSteps.size() >= 3, 'Should have at least 3 DQ_Approval_Type_Step__c records');

        DQApproverStepHelper.ApproverStepData stepData1 = new DQApproverStepHelper.ApproverStepData();
        stepData1.approvalStep = dqApprovalSteps.get(0);
        stepData1.stepApproversList.add(new DQ_Approval_Step_Approver__c());
        stepData1.stepIdToServiceName = new Map<Id, String>();
        stepData1.approvalTypeStepDataList.add(
            new DQApproverStepHelper.ApprovalTypeStepData('Reason 1', queriedApprovalTypeSteps.get(0))
        );

        DQApproverStepHelper.ApproverStepData stepData2 = new DQApproverStepHelper.ApproverStepData();
        stepData2.approvalStep = dqApprovalSteps.get(1);
        stepData2.stepApproversList.add(new DQ_Approval_Step_Approver__c());
        stepData2.stepIdToServiceName = new Map<Id, String>();
        stepData2.approvalTypeStepDataList.add(
            new DQApproverStepHelper.ApprovalTypeStepData('Reason 2', queriedApprovalTypeSteps.get(1))
        );

        DQApproverStepHelper.ApproverStepData stepData3 = new DQApproverStepHelper.ApproverStepData();
        stepData3.approvalStep = dqApprovalSteps.get(2);
        stepData3.stepApproversList.add(new DQ_Approval_Step_Approver__c());
        stepData3.stepIdToServiceName = new Map<Id, String>();
        stepData3.approvalTypeStepDataList.add(
            new DQApproverStepHelper.ApprovalTypeStepData('Reason 3', queriedApprovalTypeSteps.get(2))
        );

        List<DQApproverStepHelper.ApproverStepData> stepDataList = new List<DQApproverStepHelper.ApproverStepData>{
            stepData1, stepData2, stepData3
        };

        System.assertEquals(
            3,
            DQApproverStepHelper.getMaxStepOrder(stepDataList).get(DQApproverStepHelper.APPROVAL_COMMON_SERVICE),
            'getMaxStepOrder method should return max Step_Order__c value even when stepIdToServiceName is empty, using approvalTypeStepDataList fallback'
        );
    }

    @IsTest
    static void testGetMaxStepOrderWithProServ() {
        List<DQ_Approval_Step__c> dqApprovalSteps = [
            SELECT Id, Step_Order__c 
            FROM DQ_Approval_Step__c 
            WHERE Name IN ('Level 1', 'Level 2') AND Step_Order__c IN (1, 2)
            ORDER BY Step_Order__c
        ];
        
        System.assert(dqApprovalSteps.size() >= 2, 'Should have at least 2 steps (Level 1, 2) from @testSetup');

        Map<Id, String> stepIdToServiceName1 = new Map<Id, String>();
        stepIdToServiceName1.put(dqApprovalSteps.get(0).Id, QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT);
        Map<Id, String> stepIdToServiceName2 = new Map<Id, String>();
        stepIdToServiceName2.put(dqApprovalSteps.get(1).Id, 'Office');

        DQApproverStepHelper.ApproverStepData stepData1 = new DQApproverStepHelper.ApproverStepData();
        stepData1.approvalStep = dqApprovalSteps.get(0);
        stepData1.stepApproversList.add(new DQ_Approval_Step_Approver__c());
        stepData1.stepIdToServiceName = stepIdToServiceName1;

        DQApproverStepHelper.ApproverStepData stepData2 = new DQApproverStepHelper.ApproverStepData();
        stepData2.approvalStep = dqApprovalSteps.get(1);
        stepData2.stepApproversList.add(new DQ_Approval_Step_Approver__c());
        stepData2.stepIdToServiceName = stepIdToServiceName2;

        List<DQApproverStepHelper.ApproverStepData> stepDataList = new List<DQApproverStepHelper.ApproverStepData>{
            stepData1, stepData2
        };

        Map<String, Integer> result = DQApproverStepHelper.getMaxStepOrder(stepDataList);
        System.assertEquals(
            1,
            result.get(DQApproverStepHelper.APPROVAL_PROSERV_SERVICE),
            'getMaxStepOrder method should return max Step_Order__c value for ProServ service'
        );
        System.assertEquals(
            2,
            result.get(DQApproverStepHelper.APPROVAL_COMMON_SERVICE),
            'getMaxStepOrder method should return max Step_Order__c value for Common service'
        );
    }

    @IsTest
    static void testAddOpportunityOwnerApprovalWhenLevel1NotLatest() {
        List<User> testManagers = [SELECT Id FROM User WHERE LastName = 'TestManager' LIMIT 1];
        List<User> testOppOwners = [SELECT Id FROM User WHERE LastName = 'TestOppOwner' LIMIT 1];
        List<Account> testAccounts = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        System.assert(!testManagers.isEmpty(), 'TestManager should exist from @testSetup');
        System.assert(!testOppOwners.isEmpty(), 'TestOppOwner should exist from @testSetup');
        System.assert(!testAccounts.isEmpty(), 'TestAccount should exist from @testSetup');
        
        User testManager = testManagers[0];
        User testOppOwner = testOppOwners[0];
        Account testAccount = testAccounts[0];

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => testAccount.Id,
                    Opportunity.Name => 'Test Opportunity',
                    Opportunity.OwnerId => testOppOwner.Id,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                    Opportunity.CurrencyIsoCode => 'USD'
                }
            )
            .create()
            .getRecord();

        DQDataHelper.DealQualificationData dqData = new DQDataHelper.DealQualificationData();
        dqData.opportunityData.oppId = testOpp.Id;

        List<DQ_Approval_Step__c> level1Steps = [SELECT Id, Name, Step_Order__c FROM DQ_Approval_Step__c WHERE Name = 'Level 1' AND Step_Order__c = 1 LIMIT 1];
        List<DQ_Approval_Step__c> level3Steps = [SELECT Id, Name, Step_Order__c FROM DQ_Approval_Step__c WHERE Name = 'Level 3' AND Step_Order__c = 3 LIMIT 1];
        
        System.assert(!level1Steps.isEmpty(), 'Level 1 step should exist from @testSetup');
        System.assert(!level3Steps.isEmpty(), 'Level 3 step should exist from @testSetup');
        
        DQ_Approval_Step__c level1Step = level1Steps[0];
        DQ_Approval_Step__c level3Step = level3Steps[0];

        DQApproverStepHelper.ApproverStepData level1Data = new DQApproverStepHelper.ApproverStepData();
        level1Data.approvalStep = level1Step;
        level1Data.stepApproversList.add(new DQ_Approval_Step_Approver__c());
        level1Data.stepIdToServiceName = new Map<Id, String>();
        level1Data.stepIdToServiceName.put(level1Data.approvalStep.Id, 'Office');

        DQApproverStepHelper.ApproverStepData level3Data = new DQApproverStepHelper.ApproverStepData();
        level3Data.approvalStep = level3Step;
        level3Data.stepApproversList.add(new DQ_Approval_Step_Approver__c());
        level3Data.stepIdToServiceName = new Map<Id, String>();
        level3Data.stepIdToServiceName.put(level3Data.approvalStep.Id, 'Office');

        List<DQApproverStepHelper.ApproverStepData> resultList = DQApproverStepHelper.addOpportunityOwnerApproval(
            dqData,
            new List<DQApproverStepHelper.ApproverStepData>{level1Data, level3Data}
        );

        DQApproverStepHelper.ApproverStepData result = resultList.get(0);
        System.assert(!result.stepApproversList.isEmpty(), 'method should add additional stepApprover');
        DQ_Approval_Step_Approver__c stepApprover = result.stepApproversList.get(result.stepApproversList.size() - 1);
        System.assertEquals(
            'Notification',
            stepApprover.Approval_Type__c,
            'Approval_Type__c on stepApprover should be "Notification" when Level 1 is not the latest step'
        );
    }

    @IsTest
    static void testAddOpportunityOwnerApprovalWhenLevel1IsLatest() {
        List<User> testManagers = [SELECT Id FROM User WHERE LastName = 'TestManager' LIMIT 1];
        List<User> testOppOwners = [SELECT Id FROM User WHERE LastName = 'TestOppOwner' LIMIT 1];
        List<Account> testAccounts = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        System.assert(!testManagers.isEmpty(), 'TestManager should exist from @testSetup');
        System.assert(!testOppOwners.isEmpty(), 'TestOppOwner should exist from @testSetup');
        System.assert(!testAccounts.isEmpty(), 'TestAccount should exist from @testSetup');
        
        User testManager = testManagers[0];
        User testOppOwner = testOppOwners[0];
        Account testAccount = testAccounts[0];

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => testAccount.Id,
                    Opportunity.Name => 'Test Opportunity',
                    Opportunity.OwnerId => testOppOwner.Id,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                    Opportunity.CurrencyIsoCode => 'USD'
                }
            )
            .create()
            .getRecord();

        DQDataHelper.DealQualificationData dqData = new DQDataHelper.DealQualificationData();
        dqData.opportunityData.oppId = testOpp.Id;

        List<DQ_Approval_Step__c> level1Steps = [SELECT Id, Name, Step_Order__c FROM DQ_Approval_Step__c WHERE Name = 'Level 1' AND Step_Order__c = 1 LIMIT 1];
        System.assert(!level1Steps.isEmpty(), 'Level 1 step should exist from @testSetup');
        DQ_Approval_Step__c level1Step = level1Steps[0];
        DQApproverStepHelper.ApproverStepData level1Data = new DQApproverStepHelper.ApproverStepData();
        level1Data.approvalStep = level1Step;
        level1Data.stepApproversList.add(new DQ_Approval_Step_Approver__c());
        level1Data.stepIdToServiceName = new Map<Id, String>();
        level1Data.stepIdToServiceName.put(level1Data.approvalStep.Id, 'Office');

        List<DQApproverStepHelper.ApproverStepData> resultList = DQApproverStepHelper.addOpportunityOwnerApproval(
            dqData,
            new List<DQApproverStepHelper.ApproverStepData>{level1Data}
        );

        DQApproverStepHelper.ApproverStepData result = resultList.get(0);
        System.assert(!result.stepApproversList.isEmpty(), 'method should add additional stepApprover');
        DQ_Approval_Step_Approver__c stepApprover = result.stepApproversList.get(result.stepApproversList.size() - 1);
        System.assertEquals(
            'Approval',
            stepApprover.Approval_Type__c,
            'Approval_Type__c on stepApprover should be "Approval" when Level 1 is the latest step'
        );
    }

    @IsTest
    static void testBuildApprovalStepIdToApprovalReasonMap() {
        System.assertEquals(
            new Map<Id, String>(),
            DQApproverStepHelper.buildApprovalStepIdToApprovalReasonMap(null),
            'method buildApprovalStepIdToApprovalReasonMap shouldreturn empty map if argument is empty'
        );


        List<DQ_Approval_Type_Step__c> dqApprovalTypeSteps =
            (List<DQ_Approval_Type_Step__c>) new SObjectBuilder(DQ_Approval_Type_Step__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Approval_Type_Step__c.DQ_Approval_Step__c => ValueProviderBuilder.provideDummyId(DQ_Approval_Step__c.SObjectType)
                }
            )
            .quantity(2)
            .build()
            .getRecords();

        DQ_Approval_Type_Step__c dqApprovalTypeStep =
            (DQ_Approval_Type_Step__c) new SObjectBuilder(DQ_Approval_Type_Step__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Approval_Type_Step__c.DQ_Approval_Step__c => ValueProviderBuilder.provideDummyId(DQ_Approval_Step__c.SObjectType)
                }
            )
            .build()
            .getRecord();



        DQApproverStepHelper.ApproverStepData stepData = new DQApproverStepHelper.ApproverStepData();
        String approvalReason1 = 'test_approval_reason_1';
        stepData.approvalTypeStepDataList.add(
            new DQApproverStepHelper.ApprovalTypeStepData(approvalReason1, dqApprovalTypeSteps.get(0))
        );
        // next item has the same DQ_Approval_Step__c id as previous one
        String approvalReason2 = 'test_approval_reason_2';
        stepData.approvalTypeStepDataList.add(
            new DQApproverStepHelper.ApprovalTypeStepData(approvalReason2, dqApprovalTypeStep)
        );

        String approvalReason3 = 'test_approval_reason_3';
        stepData.approvalTypeStepDataList.add(
            new DQApproverStepHelper.ApprovalTypeStepData(approvalReason3, dqApprovalTypeSteps.get(1))
        );

        Map<Id, String> result = DQApproverStepHelper.buildApprovalStepIdToApprovalReasonMap(new List<DQApproverStepHelper.ApproverStepData>{stepData});
        System.assertEquals(
            2,
            result.size(),
            'method should return map with DQ_Approval_Step__c Id and approval reasons'
        );

        String approvalReasnon = result.get(dqApprovalTypeStep.DQ_Approval_Step__c);
        System.assert(
            approvalReasnon.contains(approvalReason1) && approvalReasnon.contains(approvalReason2),
            'approval reason with same DQ_Approval_Step__c Id should be concatenated'
        );
    }
}