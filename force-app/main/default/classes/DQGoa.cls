public without sharing class DQGoa {

    public static final String APPROVER_NOTIFICATION_TYPE_APPROVAL = 'Approval';
    public static final String APPROVER_NOTIFICATION_TYPE_NOTIFICATION = 'Notification';
    public static final String APPROVER_NOTIFICATION_TYPE_PENDING = 'Pending';
    public static final String APPROVER_STEP_FINANCE = 'finance';
    /* DQ_approver with Approval Step 'finance' should be located between Step Oeder 2 and 3 */

    public static final String APPROVED_STATUS = 'Approved';
    public static final String CANCELLED_STATUS = 'Cancelled';
    public static final String DQ_REVISED_COMMENT = 'Deal Qualification revised.';

    public class ApproverData {
        public String step = '';
        public String approvalReason = '';
        public String approverType = '';
        public String approverName = '';
        public String notificationType = '';
        public List<String> userNamesList = new List<String>();
    }

    public static Boolean isDQGoaEnabled() {
        return Feature_Toggle__c.getInstance().EnableTPAndDQBasedGOAInQT__c
            || FeatureManagement.checkPermission(CustomPermissionHelper.PERMISSION_TARGET_PRICE_AND_DQ_GOA);
    }

    public static decimal getDiscountChangeThreshold(){
        return RC_UnifiedQuotingTool_Quantity_Threshold__c.getInstance().Threshold__c;
    }

    public static List<ApproverData> getApproversForQuote(Id quoteId) {
        if (quoteId == null) {
            return new List<DQGoa.ApproverData>();
        }
        DQDataHelper.DealQualificationData dqData = DQDataHelper.getDealQualificationDataForQuote(quoteId);
        if (dqData == null) {
            return new List<DQGoa.ApproverData>();
        }
        return getApprovers(dqData);
    }

    public static List<ApproverData> getApproversForDQ(Id dqOrOppId) {
        if (dqOrOppId == null) {
            return new List<DQGoa.ApproverData>();
        }
        DQDataHelper.DealQualificationData dqData = DQDataHelper.getDealQualificationDataForDQ(dqOrOppId);
        if (dqData == null) {
            return new List<DQGoa.ApproverData>();
        }
        return getApprovers(dqData);
    }

    private static List<ApproverData> getApprovers(DQDataHelper.DealQualificationData dqData) {
        if (dqData == null) {
            return new List<DQGoa.ApproverData>();
        }

        DQApprovalTypeHelper.ApplicableApprovalTypes applicableTypes = DQApprovalTypeHelper.getApplicableApprovalTypes(dqData);
        if (applicableTypes == null) {
            return new List<DQGoa.ApproverData>();
        }
        Map<Id, String> approvalTypeIdToReasonMap = applicableTypes.approvalTypeIdToReasonMap;

        List<DQApproverStepHelper.ApproverStepData> approverStepDataList = DQApproverStepHelper.getApproverStepData(
            approvalTypeIdToReasonMap,
            dqData,
            applicableTypes.isFirstLevelApprovalRequired
        );

        List<ApproverData> approverDataList = buildApproverData(approverStepDataList);

        return approverDataList;
    }

    public static List<DQApproverStepHelper.ApproverStepData> getApproversStepsForDQ(Id dqRecordId) {
        if (dqRecordId == null) {
            return new List<DQApproverStepHelper.ApproverStepData>();
        }

        DQDataHelper.DealQualificationData dqData = DQDataHelper.getDealQualificationDataForDQ(dqRecordId);
        if (dqData == null) {
            return new List<DQApproverStepHelper.ApproverStepData>();
        }

        DQApprovalTypeHelper.ApplicableApprovalTypes applicableTypes = DQApprovalTypeHelper.getApplicableApprovalTypes(dqData);
        if (applicableTypes == null) {
            return new List<DQApproverStepHelper.ApproverStepData>();
        }
        Map<Id, String> approvalTypeIdToReasonMap = applicableTypes.approvalTypeIdToReasonMap;

        List<DQApproverStepHelper.ApproverStepData> approverStepDataList = DQApproverStepHelper.getApproverStepData(
            approvalTypeIdToReasonMap,
            dqData,
            applicableTypes.isFirstLevelApprovalRequired
        );

        return approverStepDataList;
    }

    public static String getApproversDataJSON(List<ApproverData> approverDataList) {
        if (approverDataList == null) {
            approverDataList = new List<DQGoa.ApproverData>();
        }

        return JSON.serialize(approverDataList);
    }

    public static String updateQuoteApprovalStatus(Id quoteId, List<ApproverData> approverDataList) {
        if (quoteId == null) {
            return null;
        }

        Quote updatedQuote = setQuoteApprovalStatus(quoteId, approverDataList);
        update updatedQuote;

        return updatedQuote.Approved_Status__c;
    }

    public static Quote setQuoteApprovalStatus(Id quoteId, List<ApproverData> approverDataList) {

        Boolean isQuoteHasApprovers = false;

        if (approverDataList != null) {
            for (ApproverData approver: approverDataList) {
                if (approver.notificationType == APPROVER_NOTIFICATION_TYPE_APPROVAL) {
                    isQuoteHasApprovers = true;
                    break;
                }
            }
        }

        String approvalStatus = isQuoteHasApprovers ? QuoteHelper.APPROVAL_STATUS_REQUIRED : QuoteHelper.APPROVAL_STATUS_NOT_REQUIRED;

        return new Quote(
            Id = quoteId,
            Approved_Status__c = approvalStatus
        );
    }

    public static void updateApprovedStatusCCFSC(Quote updatedQuote) {
        List<Quote> lstQuotesToUpdate = new List<Quote>();

        if (updatedQuote != null) {
            Quote ccQuote = (Quote) new ListOptional(new QuoteSelector()
                .selectQuoteById(new List<Object> {updatedQuote.Id})
                .executeQuery()
            ).getFirst();

            if (ccQuote != null) {

                if(!QuoteHelper.isNewBusiness(ccQuote)) {
                    return;
                }

                List<Quote> lstPrimaryQuotes = new QuoteSelector()
                                                .selectPrimaryQuotes(new List<Object> {ccQuote.OpportunityId})
                                                .executeQuery();

                Quote primaryQuote = !lstPrimaryQuotes.isEmpty() ? lstPrimaryQuotes.get(0) : null;

                List<DQGoa.ApproverData> lstApprovers = DQGoa.getApproversForQuote(updatedQuote.Id);

                if (!lstApprovers.isEmpty()) {
                    if (updatedQuote.Approved_Status__c != QuoteHelper.APPROVAL_STATUS_REQUIRED) {
                        updatedQuote.Approved_Status__c = QuoteHelper.APPROVAL_STATUS_REQUIRED;
                        lstQuotesToUpdate.add(updatedQuote);
                    }
                    if (primaryQuote.Approved_Status__c != QuoteHelper.APPROVAL_STATUS_REQUIRED) {
                        primaryQuote.Approved_Status__c = QuoteHelper.APPROVAL_STATUS_REQUIRED;
                        lstQuotesToUpdate.add(primaryQuote);
                    }
                } else if (lstApprovers.isEmpty()) {
                    if (updatedQuote.Approved_Status__c != QuoteHelper.APPROVAL_STATUS_NOT_REQUIRED && updatedQuote.Approved_Status__c != QuoteHelper.APPROVAL_STATUS_APPROVED) {
                        updatedQuote.Approved_Status__c = QuoteHelper.APPROVAL_STATUS_NOT_REQUIRED;
                        lstQuotesToUpdate.add(updatedQuote);
                    }

                    List<DQGoa.ApproverData> lstApproversPrimaryQuote = DQGoa.getApproversForQuote(primaryQuote.Id);
                    if (!lstApproversPrimaryQuote.isEmpty() && primaryQuote.Approved_Status__c != QuoteHelper.APPROVAL_STATUS_REQUIRED) {
                        primaryQuote.Approved_Status__c = QuoteHelper.APPROVAL_STATUS_REQUIRED;
                        lstQuotesToUpdate.add(primaryQuote);
                    }
                    else if (lstApproversPrimaryQuote.isEmpty() && primaryQuote.Approved_Status__c != QuoteHelper.APPROVAL_STATUS_APPROVED && primaryQuote.Approved_Status__c != QuoteHelper.APPROVAL_STATUS_NOT_REQUIRED) {
                        primaryQuote.Approved_Status__c = QuoteHelper.APPROVAL_STATUS_NOT_REQUIRED;
                        lstQuotesToUpdate.add(primaryQuote);
                    }
                }
            }
        }
        if(!lstQuotesToUpdate.isEmpty()) {
            update lstQuotesToUpdate;
        }
    }

    @TestVisible
    private static List<ApproverData> buildApproverData(List<DQApproverStepHelper.ApproverStepData> approverStepDataList) {
        List<ApproverData> approverDataList = new List<ApproverData>();

        if (approverStepDataList == null || approverStepDataList.isEmpty()) {
            return approverDataList;
        }

        Map<Id, String> approvalStepIdToApprovalReasonMap = DQApproverStepHelper.buildApprovalStepIdToApprovalReasonMap(approverStepDataList);

        Set<Id> groupIdSet = buildGroupIdSet(approverStepDataList);

        UserData usersInfo = getUserInfo(groupIdSet);
        
        Map<String, Integer> stepOrderMap = DQApproverStepHelper.getMaxStepOrder(approverStepDataList);

        for (DQApproverStepHelper.ApproverStepData approverStepDataItem : approverStepDataList) {
            Integer i = 0;
            for (DQ_Approval_Step_Approver__c approvalStepApprover : approverStepDataItem.stepApproversList) {

                ApproverData data = new ApproverData();
                if (i == 0) {
                    data.step = approverStepDataItem.approvalStep.Name;
                } else {
                    data.step = '';
                }

                data.approvalReason = DQApproverStepHelper.getApprovalReason(approvalStepIdToApprovalReasonMap, approvalStepApprover, approverStepDataItem);
                if (approvalStepApprover.Name != null) {
                    data.approverType = approvalStepApprover.Name;
                } else {
                    data.approverType = 'Direct Manager';
                }

                if (approvalStepApprover.Owner.Name != null) {
                    data.approverName = approvalStepApprover.Owner.Name;
                    if (usersInfo.groupIdToUserOrGroupIdListMap.containsKey(approvalStepApprover.OwnerId)) {
                        List<String> userNamesList = new List<String>();
                        for (Id userId : usersInfo.groupIdToUserOrGroupIdListMap.get(approvalStepApprover.OwnerId)) {
                            if (usersInfo.userIdToNameMap.containsKey(userId)) {
                                userNamesList.add(usersInfo.userIdToNameMap.get(userId));
                            }
                        }
                        if (!userNamesList.isEmpty()) {
                            data.userNamesList = userNamesList;
                        }
                    }
                } else {
                    data.approverName = approverStepDataItem.managerDetail.FirstName;
                }
				String serviceKey = DQApproverStepHelper.getServiceKey(approverStepDataItem, approvalStepApprover);
                if (approverStepDataItem.approvalStep.Step_Order__c == stepOrderMap.get(serviceKey)) {
                    if (approvalStepApprover.Approval_Type__c != APPROVER_NOTIFICATION_TYPE_APPROVAL) {
                        data.notificationType = APPROVER_NOTIFICATION_TYPE_NOTIFICATION;
                    } else {
                        data.notificationType = APPROVER_NOTIFICATION_TYPE_APPROVAL;
                    }
                } else {
                    data.notificationType = APPROVER_NOTIFICATION_TYPE_NOTIFICATION;
                }

                i++;
                approverDataList.add(data);

            }
        }

        return approverDataList;
    }

    @TestVisible
    private static Set<Id> buildGroupIdSet(List<DQApproverStepHelper.ApproverStepData> approverStepDataList) {
        Set<Id> result = new Set<Id>();
        if (approverStepDataList == null || approverStepDataList.isEmpty()) {
            return result;
        }
        for (DQApproverStepHelper.ApproverStepData approverStepDataItem : approverStepDataList) {
            for (DQ_Approval_Step_Approver__c approvalStepApprover : approverStepDataItem.stepApproversList) {
                if (approvalStepApprover.OwnerId != null && Id.valueOf(approvalStepApprover.OwnerId).getSObjectType() == Group.getSObjectType()) {
                    result.add(approvalStepApprover.OwnerId);
                }
            }
        }
        return result;
    }

    public class UserData {
        public Map<Id, List<Id>> groupIdToUserOrGroupIdListMap = new Map<Id, List<Id>>();
        public Map<Id, String> userIdToNameMap = new Map<Id, String>();
    }

    public static UserData getUserInfo(Set<Id> groupIdSet) {
        UserData data = new UserData();
        if (groupIdSet == null || groupIdSet.isEmpty()) {
            return data;
        }
        List<GroupMember> groupMembers = new GroupMemberSelector()
            .selectGroupMembersByGroupIds(groupIdSet)
            .executeQuery();
        Set<Id> userIdSet = new Set<Id>();
        for (GroupMember member : groupMembers) {
            userIdSet.add(member.UserOrGroupId);
            if (!data.groupIdToUserOrGroupIdListMap.containsKey(member.GroupId)) {
                data.groupIdToUserOrGroupIdListMap.put(member.GroupId, new List<Id>{member.UserOrGroupId});
            } else {
                data.groupIdToUserOrGroupIdListMap.get(member.GroupId).add(member.UserOrGroupId);
            }
        }
        if (!userIdSet.isEmpty()) {
            List<User> userList = new UserSelector()
                .selectUsers()
                .selectField(User.name)
                .setCondition('Id IN :bind0')
                .setQueryBindings(new List<Object>{ userIdSet })
                .executeQuery();
            for (User u : userList) {
                data.userIdToNameMap.put(u.Id, u.Name);
            }
        }
        return data;
    }

    @TestVisible
    public static String getDQHistoryJSON(Id optyId) {
        DQ_Deal_Qualification__c dq = OpportunityHelper.getDealQualification(optyId);
        List<DQ_Deal_Qualification_History__c> dqHistoryList = new List<DQ_Deal_Qualification_History__c>();
        if (dq != null) {
            dqHistoryList = new DealQualificationHistorySelector()
                .selectApprovedDQHistory(dq.Id)
                .executeQuery();
        }

        return JSON.serialize(dqHistoryList);
    }
}