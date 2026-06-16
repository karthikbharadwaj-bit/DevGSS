public without sharing class DQApproverHelper {

    public static final String DQ_APPROVER_OBJECT_NAME = 'DQ_Deal_Qualification_Approver__c';
    public static final Decimal APPROVER_STEP_FINANCE_ORDER = 2.5;
    public static final String APPROVER_STEP_FINANCE = 'finance';
    public static final String APPROVE_REJECT_ACTION = 'approveReject';

    public static void createDealQualificationApprover(DQ_Deal_Qualification__c dqRecord){
        if(dqRecord != null) {

            List<DQApproverStepHelper.ApproverStepData> approverlistData = DQGoa.getApproversStepsForDQ(dqRecord.Id);
            Map<Id, String> approvalStepIdToApprovalReasonMap = DQApproverStepHelper.buildApprovalStepIdToApprovalReasonMap(approverlistData);

            List<DQ_Deal_Qualification_Approver__c> listOfDealQualificationRecord = new List<DQ_Deal_Qualification_Approver__c>();
            Integer submitOrder = getDealQualficationApproverSubmitOrder(dqRecord.Id);

            if (!approverlistData.isEmpty()) {
                Map<String, Integer> stepOrderMap = DQApproverStepHelper.getMaxStepOrder(approverlistData);

                for(DQApproverStepHelper.ApproverStepData eachRecord: approverlistData) {
                    for (DQ_Approval_Step_Approver__c eachApproverRecord : eachRecord.stepApproversList) {

                        String approvalReason = DQApproverStepHelper.getApprovalReason(approvalStepIdToApprovalReasonMap, eachApproverRecord, eachRecord);

                        if (eachApproverRecord == null) {
                            continue;
                        }

                        DQ_Deal_Qualification_Approver__c dealQualificationRecord = new DQ_Deal_Qualification_Approver__c (
                                                                                        Deal_Qualification__c = dqRecord.Id,
                                                                                        Approval_Step__c = eachRecord.approvalStep.Id,
                                                                                        Approval_Step_Approver__c = eachApproverRecord.Id,
                                                                                        Approval_Reason__c = approvalReason,
                                                                                        Step_Order__c = eachRecord.approvalStep.Step_Order__c,
                                                                                        Submitted_Order__c = submitOrder,
                                                                                        OwnerId = eachApproverRecord.OwnerId
                                                                                    );

                        String serviceKey = DQApproverStepHelper.getServiceKey(eachRecord, eachApproverRecord);

                        if (eachRecord.approvalStep.Step_Order__c == stepOrderMap.get(serviceKey)) {
                            if (eachApproverRecord.Approval_Type__c == DQGoa.APPROVER_NOTIFICATION_TYPE_APPROVAL) {
                                dealQualificationRecord.Status__c =  DQGoa.APPROVER_NOTIFICATION_TYPE_PENDING;
                            } else {
                                dealQualificationRecord.Status__c =  DQGoa.APPROVER_NOTIFICATION_TYPE_NOTIFICATION;
                            }

                            dealQualificationRecord.Submitted_Date__c = DateTime.now();
                        }
                        else
                        {
                            dealQualificationRecord.Status__c =  DQGoa.APPROVER_NOTIFICATION_TYPE_NOTIFICATION;
                        }


                        listOfDealQualificationRecord.add(dealQualificationRecord);
                    }
                }
                insert listOfDealQualificationRecord;

                if (listOfDealQualificationRecord.size () == 0) {
                    updateDealQualificationStatus(dqRecord.Id, DQGoa.APPROVED_STATUS);
                }
            }
        }
    }

    private static List<DQ_Deal_Qualification_Approver__c> getCurrentApproverRecordForDQ(Id dqId) {
        Integer submitOrder = getDealQualficationApproverSubmitOrder(dqId) - 1;
        return new DealQualificationApproverSelector()
            .selectDQApproversSubmitOrder(dqId,submitOrder)
            .executeQuery();
    }

    private static Integer getDealQualficationApproverSubmitOrder (Id dqId) {
        List<DQ_Deal_Qualification_Approver__c> listOfDealQualificationApprover =  new DealQualificationApproverSelector()
                                                                                    .selectDQApproversOrder(dqId)
                                                                                    .executeQuery();

        return (!listOfDealQualificationApprover.isEmpty() && listOfDealQualificationApprover.get(0).Submitted_Order__c != null) ? Integer.valueOf(listOfDealQualificationApprover.get(0).Submitted_Order__c) + 1 : 1;

    }

    public static void reviseDealQualification(DQ_Deal_Qualification__c dqRecord) {

        if (dqRecord != null) {
            List<DQ_Deal_Qualification_Approver__c> listOfDQApprover = getCurrentApproverRecordForDQ(dqRecord.Id);
            for (DQ_Deal_Qualification_Approver__c eachRecord: listOfDQApprover) {
                eachRecord.Status__c = DQGoa.CANCELLED_STATUS;
                eachRecord.Comments__c = DQGoa.DQ_REVISED_COMMENT;
                eachRecord.Submitted_Date__c = Datetime.now();
            }
            update listOfDQApprover;

        }
    }

    private static void updateDealQualificationStatus(Id dqId, String status) {
        update (new DQ_Deal_Qualification__c(Id = dqId, Status__c = status));
    }

    public class ApprovalData {
        public String approverId;
        public Decimal submittedOrder;
        public Decimal stepOrder;
        public String submitDate;
        public String status;
        public String ownerName;
        public String ownerId;
        public String approverName;
        public String desicionDate;
        public Decimal SLA;
        public String approvalReason;
        public String comments;
        public String createdByName;
        public List<String> userNamesList;
        public Boolean isOwnerQueue;
        public String createdDate;
        public String delegatedApproverId;
        public String approvalStepName;
        public String approverStepApproverName;

        public ApprovalData() {}

        public ApprovalData(DQ_Deal_Qualification_Approver__c record) {
            if (record == null) {
                return;
            }
            this.approverId = record.Id;
            this.submittedOrder = record?.Submitted_Order__c;
            this.stepOrder = record.Step_Order__c == 3 && record.Approval_Step__r?.Name?.equalsIgnoreCase(APPROVER_STEP_FINANCE)
                ? APPROVER_STEP_FINANCE_ORDER
                : record.Step_Order__c;
            this.submitDate = record.Submitted_Date__c?.format();
            this.status = record.Status__c;
            this.ownerName = record.Owner?.Name;
            this.approverName = record.Approved_By__r?.Name;
            this.desicionDate = record.Approve_Reject_Date__c?.format();
            if (record.Status__c != DQGoa.APPROVER_NOTIFICATION_TYPE_NOTIFICATION) {
                this.SLA = DQ_DealQualificationController.getSLAInHours(record.Approve_Reject_Date__c, record?.Submitted_Date__c);
            }
            this.approvalReason = record.Approval_Reason__c;
            this.comments = record.Comments__c;
            this.createdByName = record.CreatedBy.Name;
            this.ownerId = record.OwnerId;
            this.createdDate = record.CreatedDate?.format();
            if (record.Owner instanceOf User) {
                    User u = record.Owner;
                    this.delegatedApproverId = u.DelegatedApproverId;
            }
            this.approvalStepName = record.Approval_Step_name__c;
            this.approverStepApproverName = record.Approval_Step_Approver__r?.Name;
        }

        public void setUserNamesList(DQGoa.UserData usersInfo) {
            if (usersInfo?.groupIdToUserOrGroupIdListMap?.containsKey(this.ownerId)) {
                List<String> userNamesList = new List<String>();
                for (Id userId : usersInfo.groupIdToUserOrGroupIdListMap.get(this.ownerId)) {
                    if (usersInfo.userIdToNameMap.containsKey(userId)) {
                        userNamesList.add(usersInfo.userIdToNameMap.get(userId));
                    }
                }
                if (!userNamesList.isEmpty()) {
                    this.userNamesList = userNamesList;
                }
            }
        }

        public void setIsOwnerQueue(DQ_Deal_Qualification_Approver__c dqApproval) {
            this.isOwnerQueue = dqApproval?.OwnerId != null && Id.valueOf(dqApproval?.OwnerId).getSObjectType() == Group.getSObjectType();
        }
    }

    public static String getDQApprovalsJSON(Id optyId) {
        DQ_Deal_Qualification__c dq = OpportunityHelper.getDealQualification(optyId);
        List<DQ_Deal_Qualification_Approver__c> dqApproverList = new List<DQ_Deal_Qualification_Approver__c>();
        List<ApprovalData> approvalDataList = new List<ApprovalData>();
        if (dq != null) {
            dqApproverList = [SELECT Id, Submitted_Order__c, Step_Order__c,
                                     Approval_Step__r.Name,Submitted_Date__c,
                                     Status__c, Approved_By__r.Name, Comments__c,
                                     Approve_Reject_Date__c, Approval_Reason__c,
                                     CreatedBy.Name, OwnerId, CreatedDate, Approval_Step_name__c,
                                     Approval_Step_Approver__r.Name,
                                TYPEOF Owner
                                    WHEN User THEN DelegatedApproverId, Name
                                END
                                FROM DQ_Deal_Qualification_Approver__c
                                WHERE Deal_Qualification__c = :dq.Id
                             ];
            Set<Id> groupIds = new Set<Id>();
            for (DQ_Deal_Qualification_Approver__c dqApproval : dqApproverList) {
                if (dqApproval.OwnerId != null && Id.valueOf(dqApproval.OwnerId).getSObjectType() == Group.getSObjectType()) {
                    groupIds.add(dqApproval.OwnerId);
                }
            }
            DQGoa.UserData usersInfo = DQGoa.getUserInfo(groupIds);
            for (DQ_Deal_Qualification_Approver__c dqApproval : dqApproverList) {
                ApprovalData approvalData = new ApprovalData(dqApproval);
                approvalData.setUserNamesList(usersInfo);
                approvalData.setIsOwnerQueue(dqApproval);
                approvalDataList.add(approvalData);
            }
        }
        return JSON.serialize(approvalDataList);
    }

    public static DQ_Deal_Qualification_Approver__c updateDQApproval(BillingWrappers.DQApprover paramsData, String dqAction) {
        DQ_Deal_Qualification_Approver__c dqApprover = new DQ_Deal_Qualification_Approver__c(
            Id = paramsData.approverId,
            Status__c = paramsData.status,
            Comments__c = paramsData.comments,
            OwnerId = paramsData.ownerId
        );
        if (dqAction.contains(APPROVE_REJECT_ACTION)) {
            dqApprover.Approve_Reject_Date__c = System.now();
            dqApprover.Approved_By__c = UserInfo.getUserId();
        }
        update dqApprover;

        return dqApprover;
    }
}