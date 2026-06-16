@isTest
private class Test_DQGoa {

    @IsTest
    static void testBuildGroupIdSet() {
        System.assertEquals(
            new Set<Id>(),
            DQGoa.buildGroupIdSet(null),
            'method buildGroupIdSet should return empty set if argument is empty'
        );


        List<DQ_Approval_Step_Approver__c> groupApprovers =
            (List<DQ_Approval_Step_Approver__c>) new SObjectBuilder(DQ_Approval_Step_Approver__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Approval_Step_Approver__c.OwnerId => ValueProviderBuilder.provideDummyId(Group.SObjectType)
                }
            )
            .quantity(2)
            .build()
            .getRecords();

        List<DQ_Approval_Step_Approver__c> userApprovers =
            (List<DQ_Approval_Step_Approver__c>) new SObjectBuilder(DQ_Approval_Step_Approver__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Approval_Step_Approver__c.OwnerId => ValueProviderBuilder.provideDummyId(User.SObjectType)
                }
            )
            .quantity(2)
            .build()
            .getRecords();

        DQApproverStepHelper.ApproverStepData approverStepDataGroup = new DQApproverStepHelper.ApproverStepData();
        approverStepDataGroup.stepApproversList.addAll(groupApprovers);

        DQApproverStepHelper.ApproverStepData approverStepDataUser = new DQApproverStepHelper.ApproverStepData();
        approverStepDataUser.stepApproversList.addAll(userApprovers);

        Set<Id> groupIdSet = DQGoa.buildGroupIdSet(new List<DQApproverStepHelper.ApproverStepData>{approverStepDataGroup, approverStepDataUser});
        System.assertEquals(
            2,
            groupIdSet.size(),
            'method should return set of Group Ids'
        );

        for (Id item : groupIdSet) {
            System.assert(item.getSobjectType() == Group.getSobjectType(), 'method should return set of Group Ids');
        }
    }

    @IsTest
    static void testGetUserInfo() {

        Group testGroup = (Group) new SObjectBuilder(Group.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Group.Name => ValueProviderBuilder.provideUniqueString('testDQGoa_Group')
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

        GroupMember testGroupMember = (GroupMember) new SObjectBuilder(GroupMember.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    GroupMember.UserOrGroupId => testApprover.Id,
                    GroupMember.GroupId => testGroup.Id
                }
            )
            .create()
            .getRecord();

        DQGoa.UserData result = DQGoa.getUserInfo(new Set<Id>{testGroup.Id});

        System.assert(
            result.groupIdToUserOrGroupIdListMap.containsKey(testGroup.Id),
            'method getUserInfo should return result with a map which contains Group Ids associated to Users Id list'
        );
        System.assert(
            result.groupIdToUserOrGroupIdListMap.get(testGroup.Id).contains(testApprover.Id),
            'method getUserInfo should return result with a map which contains Group Ids associated to Users Id list'
        );

        System.assert(
            result.userIdToNameMap.containsKey(testApprover.Id),
            'method getUserInfo should return result with a map which contains User Ids associated to User Names'
        );
    }

    @IsTest
    static void testBuildApproverData() {

        System.assertEquals(
            new List<DQGoa.ApproverData>(),
            DQGoa.buildApproverData(null),
            'buildApproverData method should return empty list if passed argument is empty'
        );


        Group testGroup = (Group) new SObjectBuilder(Group.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Group.Name => ValueProviderBuilder.provideUniqueString('testDQGoa_Group'),
                    Group.Type => 'Queue'
                }
            )
            .create()
            .getRecord();

        User testApprover;

        System.runAs(new User(Id=UserInfo.getUserId())) {
            QueuesObject testQueue = new QueueSObject(QueueID = testGroup.id, SObjectType = 'DQ_Approval_Step_Approver__c');
            insert testQueue;

            testApprover = (User) new SObjectBuilder(User.SObjectType)
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

            GroupMember testGroupMember = (GroupMember) new SObjectBuilder(GroupMember.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        GroupMember.UserOrGroupId => testApprover.Id,
                        GroupMember.GroupId => testGroup.Id
                    }
                )
                .create()
                .getRecord();
        }

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
                    DQ_Approval_Type__c.IsActive__c => true,
                    DQ_Approval_Type__c.isUnifiedQuotingApprovalType__c => true,
                    DQ_Approval_Type__c.Approval_Type__c => DQApprovalTypeHelper.APPROVAL_TYPE_DISCOUNT,
                    DQ_Approval_Type__c.Product_Category__c => 'Device_Contract',
                    DQ_Approval_Type__c.Threshold__c => 50
                }
            )
            .create()
            .getRecord();

        DQ_Approval_Type_Step__c approvalTypeStep =
            (DQ_Approval_Type_Step__c) new SObjectBuilder(DQ_Approval_Type_Step__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Approval_Type_Step__c.DQ_Approval_Type__c => dqApprovalType.Id,
                    DQ_Approval_Type_Step__c.DQ_Approval_Step__c => dqApprovalStep.Id

                }
            )
            .create()
            .getRecord();

        DQ_Approval_Step_Approver__c approvalStepApprover =
            (DQ_Approval_Step_Approver__c) new SObjectBuilder(DQ_Approval_Step_Approver__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Approval_Step_Approver__c.OwnerId => testGroup.Id,
                    DQ_Approval_Step_Approver__c.DQ_Approval_Step__c => dqApprovalStep.Id
                }
            )
            .create()
            .getRecord();

        Test.startTest();

            List<DQ_Approval_Step_Approver__c> reselectedApprovalStepApprovers = [
                SELECT Id, Name, DQ_Approval_Step__c, OwnerId, Owner.Name, Approval_Type__c
                FROM DQ_Approval_Step_Approver__c];

            final String testApprovalReason = 'Discount exceeds threshold';

            DQApproverStepHelper.ApprovalTypeStepData typeStepData = new DQApproverStepHelper.ApprovalTypeStepData(
                testApprovalReason,
                approvalTypeStep
            );

            DQApproverStepHelper.ApproverStepData data = new DQApproverStepHelper.ApproverStepData();
            data.approvalStep = dqApprovalStep;
            data.stepApproversList.addAll(reselectedApprovalStepApprovers);
            data.approvalTypeStepDataList.add(typeStepData);

            List<DQGoa.ApproverData> results = DQGoa.buildApproverData(new List<DQApproverStepHelper.ApproverStepData>{data});

            System.assert(
                results != null && !results.isEmpty(),
                'buildApproverData method should return not-empty ApproverData list'
            );

            DQGoa.ApproverData result = results.get(0);
            System.assertEquals(
                testApprovalReason,
                result.approvalReason,
                'ApproverData should contain approval reason'
            );
            System.assertEquals(
                testGroup.Name,
                result.approverName,
                'ApproverData should contain approver name that matches the Group/User name'
            );
            System.assertEquals(
                reselectedApprovalStepApprovers.get(0).Name,
                result.approverType,
                'approverType should match corresponding DQ_Approval_Step_Approver__c Name'
            );
            System.assertEquals(
                dqApprovalStep.Name,
                result.step,
                'ApproverData should contain Name of corresponding DQ_Approval_Step__c'
            );
            System.assert(
                result.userNamesList != null && !result.userNamesList.isEmpty(),
                'ApproverData should contain user names list for each approval level'
            );
            System.assert(
                result.userNamesList.contains(testApprover.LastName),
                'userNamesList should contain User name of DQ_Approval_Step_Approver__c owner'
            );

        Test.stopTest();
    }

    @IsTest
    static void testGetApproversDataJSON() {
        System.assertEquals(
            '[]',
            DQGoa.getApproversDataJSON(null),
            'getApproversDataJSON method should return empty array if passed argument is null'
        );

        System.assertEquals(
            '[]',
            DQGoa.getApproversDataJSON(new List<DQGoa.ApproverData>()),
            'getApproversDataJSON method should return empty array if passed argument is empty list'
        );
    }

    @IsTest
    static void testUpdateQuoteApprovalStatus() {
        Test.startTest();
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType)
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
            new Map<SObjectField, Object>{
                Quote.Name => 'Test Quote',
                Quote.OpportunityId => opp.Id
            }
        )
            .create()
            .getRecord();

        DQGoa.ApproverData approver = new DQGoa.ApproverData();
        approver.notificationType = DQGoa.APPROVER_NOTIFICATION_TYPE_APPROVAL;

        List<DQGoa.ApproverData> approvers = new List<DQGoa.ApproverData> {
            approver
        };
        Test.stopTest();
        System.assertEquals(
            null,
            DQGoa.updateQuoteApprovalStatus(null, null),
            'updateQuoteApprovalStatus method should return null if passed arguments are null'
        );

        System.assertEquals(
            QuoteHelper.APPROVAL_STATUS_NOT_REQUIRED,
            DQGoa.updateQuoteApprovalStatus(qt.Id, null),
            'updateQuoteApprovalStatus method should return not required if approvers are null'
        );

        System.assertEquals(
            QuoteHelper.APPROVAL_STATUS_NOT_REQUIRED,
            DQGoa.updateQuoteApprovalStatus(qt.Id, new List<DQGoa.ApproverData>()),
            'updateQuoteApprovalStatus method should return not required if approvers are empty'
        );

        System.assertEquals(
            QuoteHelper.APPROVAL_STATUS_REQUIRED,
            DQGoa.updateQuoteApprovalStatus(qt.Id, approvers),
            'updateQuoteApprovalStatus method should return required if approvers are presented'
        );
    }

    @IsTest
    static void testGetApproversForDQ() {

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
                    DQ_Approval_Type__c.IsActive__c => true,
                    DQ_Approval_Type__c.isUnifiedQuotingApprovalType__c => true,
                    DQ_Approval_Type__c.Approval_Type__c => DQApprovalTypeHelper.APPROVAL_TYPE_DISCRETION,
                    DQ_Approval_Type__c.Threshold__c => 50,
                    DQ_Approval_Type__c.ServiceName__c => QuoteHelper.NGBS_OFFICE_PRODUCT
                }
            )
            .create()
            .getRecord();

        DQ_Approval_Type_Step__c approvalTypeStep =
            (DQ_Approval_Type_Step__c) new SObjectBuilder(DQ_Approval_Type_Step__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Approval_Type_Step__c.DQ_Approval_Type__c => dqApprovalType.Id,
                    DQ_Approval_Type_Step__c.DQ_Approval_Step__c => dqApprovalStep.Id,
                    DQ_Approval_Type_Step__c.Region__c => 'US',
                    DQ_Approval_Type_Step__c.Segment__c => 'Default',
                    DQ_Approval_Type_Step__c.Deal_Type__c => 'Direct',
                    DQ_Approval_Type_Step__c.Brand__c => 'Default',
                    DQ_Approval_Type_Step__c.Sub_Region__c => 'All'
                }
            )
            .create()
            .getRecord();

        DQ_Approval_Step_Approver__c approvalStepApprover =
            (DQ_Approval_Step_Approver__c) new SObjectBuilder(DQ_Approval_Step_Approver__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Approval_Step_Approver__c.Approval_Type__c => 'Approval',
                    DQ_Approval_Step_Approver__c.OwnerId => testApprover.Id,
                    DQ_Approval_Step_Approver__c.DQ_Approval_Step__c => dqApprovalStep.Id,
                    DQ_Approval_Step_Approver__c.Region__c => 'US',
                    DQ_Approval_Step_Approver__c.Segment__c => 'Default',
                    DQ_Approval_Step_Approver__c.Deal_Type__c => 'Direct',
                    DQ_Approval_Step_Approver__c.Brand__c => 'Default',
                    DQ_Approval_Step_Approver__c.Sub_Region__c => 'All'
                }
            )
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Name => 'Test Opportunity',
                Opportunity.OwnerId => testApprover.Id,
                Opportunity.Tier_Name__c => QuoteHelper.NGBS_OFFICE_PRODUCT
            })
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'Test Quote',
                    Quote.OpportunityId => testOpp.Id,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                    Quote.ServiceName__c => QuoteHelper.NGBS_OFFICE_PRODUCT,
                    Quote.OverallDiscretion__c => 80
                }
            )
            .create()
            .getRecord();

        DQ_Deal_Qualification__c testDqRecord = (DQ_Deal_Qualification__c) new SObjectBuilder(DQ_Deal_Qualification__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                DQ_Deal_Qualification__c.Opportunity__c => testOpp.Id,
                DQ_Deal_Qualification__c.Overall_Discount__c => 70
            })
            .create()
            .getRecord();

        List<DQGoa.ApproverData> dqApprovers = DQGoa.getApproversForDQ(testDqRecord.Id);
        System.assertEquals(2, dqApprovers.size(), 'method should return 1 approver');
        DQGoa.ApproverData approver = dqApprovers.get(0);
        System.assertEquals(DQGoa.APPROVER_NOTIFICATION_TYPE_APPROVAL, approver.notificationType, 'notification type should be "Approval"');
    }

    @IsTest
    static void testGetDQHistoryJSON() {
        System.assertEquals(
            '[]',
            DQGoa.getDQHistoryJSON(null),
            'getDQHistoryJSON method should return empty array if passed argument is null'
        );

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType)
            })
            .create()
            .getRecord();

        DQ_Deal_Qualification__c testDQDealQualification = (DQ_Deal_Qualification__c) new SObjectBuilder(DQ_Deal_Qualification__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                DQ_Deal_Qualification__c.Opportunity__c => testOpp.Id
            })
            .create()
            .getRecord();

        List<DQ_Deal_Qualification_History__c> testDQHistoryList =
            (List<DQ_Deal_Qualification_History__c>) new SObjectBuilder(DQ_Deal_Qualification_History__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        DQ_Deal_Qualification_History__c.Deal_Qualification__c => testDQDealQualification.Id,
                        DQ_Deal_Qualification_History__c.Status__c => ValueProviderBuilder.provideList(new List<String>{
                            'Approved', 'Rejected'
                        })
                    }
                )
                .quantity(2)
                .create()
                .getRecords();

        new SObjectBuilder(DQ_Deal_Qualification_Discount_History__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        DQ_Deal_Qualification_Discount_History__c.DQ_Deal_Qualification_History__c =>
                            ValueProviderBuilder.provideList(new List<Id>{
                                testDQHistoryList[0].Id, testDQHistoryList[1].Id
                            })
                    }
                )
                .quantity(2)
                .create();

        Test.startTest();
            String resultString = DQGoa.getDQHistoryJSON(testOpp.Id);
            List<DQ_Deal_Qualification_History__c> result =
                (List<DQ_Deal_Qualification_History__c>) JSON.deserialize(resultString, List<DQ_Deal_Qualification_History__c>.class);
        Test.stopTest();
        System.assert(!String.isBlank(resultString), 'Qualification History JSON should not be empty');
        System.assert(!result.isEmpty(), 'Approved Qualification History record should be obtained');
        System.assert(!result[0].DQ_Deal_Qualification_Discounts_History__r.isEmpty(), 'Discount History records should be obtained');
    }

    @IsTest
    static void testUpdateApprovedStatusCCFSC() {

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
                    DQ_Approval_Type__c.IsActive__c => true,
                    DQ_Approval_Type__c.IsUnifiedQuotingApprovalType__c => true,
                    DQ_Approval_Type__c.Approval_Type__c => DQApprovalTypeHelper.APPROVAL_TYPE_DISCRETION,
                    DQ_Approval_Type__c.Threshold__c => 50,
                    DQ_Approval_Type__c.ServiceName__c => Product2Helper.PRODUCT_OFFICE
                        }
            )
            .create()
            .getRecord();

        DQ_Approval_Type_Step__c approvalTypeStep =
            (DQ_Approval_Type_Step__c) new SObjectBuilder(DQ_Approval_Type_Step__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Approval_Type_Step__c.DQ_Approval_Type__c => dqApprovalType.Id,
                        DQ_Approval_Type_Step__c.DQ_Approval_Step__c => dqApprovalStep.Id,
                        DQ_Approval_Type_Step__c.Region__c => 'US',
                        DQ_Approval_Type_Step__c.Segment__c => 'Default',
                        DQ_Approval_Type_Step__c.Deal_Type__c => 'Direct',
                        DQ_Approval_Type_Step__c.Brand__c => 'Default',
                        DQ_Approval_Type_Step__c.Sub_Region__c => 'All'
                        }
            )
            .create()
            .getRecord();

        DQ_Approval_Step_Approver__c approvalStepApprover =
            (DQ_Approval_Step_Approver__c) new SObjectBuilder(DQ_Approval_Step_Approver__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Approval_Step_Approver__c.Approval_Type__c => 'Approval',
                        DQ_Approval_Step_Approver__c.OwnerId => testApprover.Id,
                        DQ_Approval_Step_Approver__c.DQ_Approval_Step__c => dqApprovalStep.Id,
                        DQ_Approval_Step_Approver__c.Region__c => 'US',
                        DQ_Approval_Step_Approver__c.Segment__c => 'Default',
                        DQ_Approval_Step_Approver__c.Deal_Type__c => 'Direct',
                        DQ_Approval_Step_Approver__c.Brand__c => 'Default',
                        DQ_Approval_Step_Approver__c.Sub_Region__c => 'All'
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
                    DQ_Deal_Qualification__c.Overall_Discount__c => 70
                    })
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'Test Quote',
                        Quote.OpportunityId => testOpp.Id
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
            Boolean isDQGoaEnabled = DQGoa.isDQGoaEnabled();
            DQGoa.updateApprovedStatusCCFSC(testQuote);
            System.assertEquals(QuoteHelper.APPROVAL_STATUS_NOT_REQUIRED,testQuote.Approved_Status__c, 'Quote approved status should be Not Required');
        Test.stopTest();
    }
}