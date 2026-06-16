@IsTest
private class Test_DQApproverHelper {

    @IsTest
    static void testCreateDealQualificationApprover() {

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
                    DQ_Approval_Type__c.Threshold__c => 20,
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
                    Quote.OpportunityId => testOpp.Id,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                    Quote.ServiceName__c => QuoteHelper.NGBS_OFFICE_PRODUCT,
                    Quote.OverallDiscretion__c => 80
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
            DQApproverHelper.createDealQualificationApprover(testDqRecord);
            DQApproverHelper.reviseDealQualification(testDqRecord);
            List<DQ_Deal_Qualification_Approver__c> dqApprovers =  new DealQualificationApproverSelector()
                    .selectDQApproversOrder(testDqRecord.Id)
                    .executeQuery();
            System.assertEquals(1,dqApprovers.size(), 'method should return 1 approver');
        Test.stopTest();
    }

    @IsTest
    static void testUpdateDealQualificationStatus() {

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
                        DQ_Approval_Type__c.ServiceName__c => 'Office;Fax;Meetings'
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
            DQApproverHelper.createDealQualificationApprover(testDqRecord);
            List<DQ_Deal_Qualification_Approver__c> dqApprovers =  new DealQualificationApproverSelector()
                    .selectDQApproversOrder(testDqRecord.Id)
                    .executeQuery();
            System.assertEquals(0,dqApprovers.size(), 'method should return 0 approver');
        Test.stopTest();
    }

    @IsTest
    static void testUpdateDQApproval() {
        User testUser = (User) new SObjectBuilder(User.SObjectType)
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
        Group testQueue = (Group) new SObjectBuilder(Group.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Group.Name => ValueProviderBuilder.provideUniqueString('testDQGoa_Group'),
                    Group.Type => 'Queue'
                }
            )
            .create()
            .getRecord();
        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today()
            })
            .create()
            .getRecord();
        DQ_Deal_Qualification__c testDqRecord = (DQ_Deal_Qualification__c) new SObjectBuilder(DQ_Deal_Qualification__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                DQ_Deal_Qualification__c.Opportunity__c => testOpp.Id
            })
            .create()
            .getRecord();
        DQ_Approval_Step__c testDqApprovalStepRecord = (DQ_Approval_Step__c) new SObjectBuilder(DQ_Approval_Step__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                DQ_Approval_Step__c.Name => 'Step 1'
            })
            .create()
            .getRecord();
        DQ_Deal_Qualification_Approver__c testDqApproverRecord = (DQ_Deal_Qualification_Approver__c) new SObjectBuilder(DQ_Deal_Qualification_Approver__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                DQ_Deal_Qualification_Approver__c.Status__c => ApprovalHelper.STATUS_PENDING,
                DQ_Deal_Qualification_Approver__c.Approval_Step__c => testDqApprovalStepRecord.Id,
                DQ_Deal_Qualification_Approver__c.Deal_Qualification__c => testDqRecord.Id,
                DQ_Deal_Qualification_Approver__c.OwnerId => testUser.Id
            })
            .create()
            .getRecord();
        System.runAs(testUser) {
            QueuesObject testQueueSObject = (QueueSObject) new SObjectBuilder(QueueSObject.getSObjectType())
                .setFields(
                    new Map<SObjectField, Object>{
                        QueueSObject.QueueID => testQueue.id,
                        QueueSObject.SObjectType => DQApproverHelper.DQ_APPROVER_OBJECT_NAME
                    }
                )
                .create()
                .getRecord();
        }

        BillingWrappers.DQApprover dqApproverWrapper = new BillingWrappers.DQApprover();
        dqApproverWrapper.approverId = testDqApproverRecord.Id;
        dqApproverWrapper.status = ApprovalHelper.STATUS_APPROVED;
        dqApproverWrapper.comments =  'testComments';
        dqApproverWrapper.ownerId =  testQueue.Id;
        Test.startTest();
        DQApproverHelper.updateDQApproval(dqApproverWrapper, DQApproverHelper.APPROVE_REJECT_ACTION);
        Test.stopTest();
        List<DQ_Deal_Qualification_Approver__c> dqApproverList = new DealQualificationApproverSelector()
            .selectDQApproverById(testDqApproverRecord.Id)
            .executeQuery();
        System.assertEquals(
            dqApproverList[0].Status__c,
            dqApproverWrapper.status,
            'method UpdateDQApproval should update Status field in DQ Approver'
        );
        System.assertEquals(
            dqApproverList[0].Comments__c,
            dqApproverWrapper.comments,
            'method UpdateDQApproval should update Comments field in DQ Approver'
        );
        System.assertEquals(
            dqApproverList[0].OwnerId,
            dqApproverWrapper.ownerId,
            'method UpdateDQApproval should update OwnerId field in DQ Approver'
        );
    }

    @IsTest
    static void testGetDQApprovalsJSON() {
        System.assertEquals(
            '[]',
            DQApproverHelper.getDQApprovalsJSON(null),
            'getDQApprovalsJSON method should return empty array if passed argument is null'
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

        System.runAs(new User(Id = UserInfo.getUserId())) {
            QueuesObject testQueue = (QueueSObject) new SObjectBuilder(QueueSObject.getSObjectType())
                .setFields(
                    new Map<SObjectField, Object>{
                        QueueSObject.QueueID => testGroup.id,
                        QueueSObject.SObjectType => DQApproverHelper.DQ_APPROVER_OBJECT_NAME
                    }
                )
                .create()
                .getRecord();

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

         Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType)
            })
            .create()
            .getRecord();

        DQ_Deal_Qualification__c testDqRecord = (DQ_Deal_Qualification__c) new SObjectBuilder(DQ_Deal_Qualification__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                DQ_Deal_Qualification__c.Opportunity__c => testOpp.Id
            })
            .create()
            .getRecord();

        DQ_Approval_Step__c testDqApprovalStepRecord = (DQ_Approval_Step__c) new SObjectBuilder(DQ_Approval_Step__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                DQ_Approval_Step__c.Name => 'Step 3'
            })
            .create()
            .getRecord();

        DQ_Deal_Qualification_Approver__c testDqApproverRecord = (DQ_Deal_Qualification_Approver__c) new SObjectBuilder(DQ_Deal_Qualification_Approver__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                DQ_Deal_Qualification_Approver__c.Deal_Qualification__c => testDqRecord.Id,
                DQ_Deal_Qualification_Approver__c.Approval_Step__c  => testDqApprovalStepRecord.Id,
                DQ_Deal_Qualification_Approver__c.OwnerId  => testGroup.Id
            })
            .create()
            .getRecord();

        Test.startTest();
            String resultString = DQApproverHelper.getDQApprovalsJSON(testOpp.Id);
            List<DQApproverHelper.ApprovalData> result =
                (List<DQApproverHelper.ApprovalData>) JSON.deserialize(resultString, List<DQApproverHelper.ApprovalData>.class);
        Test.stopTest();

        System.assert(!String.isBlank(resultString), 'Deal Qualification Approver JSON should not be empty');
        System.assert(!result.isEmpty(), 'Approval data object should be obtained');
        System.assert(!result[0].userNamesList.isEmpty(), 'User name list of Approval data object should not be empty');
    }
}