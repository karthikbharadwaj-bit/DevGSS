public class DQ_PendingApprovalController {
    public static final String REJECTED_STATUS = 'Rejected';
    public static final String APPROVE_QUOTE = 'Approve';
    public static final String EES_PRODUCT = 'EES';

    @AuraEnabled
    public static List<DataTableWrapper> loadPendingApproval() {
        Set<Id> setOfCurrentUserGroupId = getQueueIdBelongsToCurrentUser();
        List<DQ_Deal_Qualification_Approver__c> listOfPendingApproval;

        if(FeatureManagement.checkPermission('DQ_Super_User')) {
            listOfPendingApproval =
            [SELECT Id, Deal_Qualification__r.Name, Approval_Step__r.Name, Status__c, Step_Order__c,
             Submitted_Date__c, Submitted_Order__c, Approval_Reason__c, Deal_Qualification__r.Opportunity__c,
             Deal_Qualification__r.Cost_of_One_Time_items__c, Deal_Qualification__r.New_Annual_Recurring_Charges__c,
             Deal_Qualification__r.Overall_Discount__c, Deal_Qualification__r.Initial_Term__c, Comments__c, Deal_Qualification__r.Quote__c,
             Deal_Qualification__r.Opportunity__r.Name, Deal_Qualification__r.CC_Initial_Term__c,Deal_Qualification__r.Special_Terms__c,Deal_Qualification__r.CC_Special_Terms__c,Deal_Qualification__r.Brand__c,
             Deal_Qualification__r.Segment__c, Deal_Qualification__r.Quote__r.Monthly_Recurring_Revenue__c
             FROM DQ_Deal_Qualification_Approver__c
             WHERE Status__c = 'Pending' AND Deal_Qualification__r.Opportunity__c != null ORDER BY Deal_Qualification__r.Name ASC];
        }
        else {
            listOfPendingApproval =
            [SELECT Id, Deal_Qualification__r.Name, Approval_Step__r.Name, Status__c, Step_Order__c,
             Submitted_Date__c, Submitted_Order__c, Approval_Reason__c, Deal_Qualification__r.Opportunity__c,
             Deal_Qualification__r.Cost_of_One_Time_items__c, Deal_Qualification__r.New_Annual_Recurring_Charges__c,
             Deal_Qualification__r.Overall_Discount__c, Deal_Qualification__r.Initial_Term__c, Comments__c, Deal_Qualification__r.Quote__c,
             Deal_Qualification__r.Opportunity__r.Name, Deal_Qualification__r.Special_Terms__c,Deal_Qualification__r.CC_Initial_Term__c,Deal_Qualification__r.CC_Special_Terms__c,Deal_Qualification__r.Brand__c,
             Deal_Qualification__r.Segment__c, Deal_Qualification__r.Quote__r.Monthly_Recurring_Revenue__c
             FROM DQ_Deal_Qualification_Approver__c
             WHERE (OwnerId =: UserInfo.getUserId() OR OwnerId IN :setOfCurrentUserGroupId)
             AND Status__c = 'Pending' AND Deal_Qualification__r.Opportunity__c != null];
        }

        List<DataTableWrapper> listOfWrapper = new List<DataTableWrapper>();

        if (!listOfPendingApproval.isEmpty()) {

            for(DQ_Deal_Qualification_Approver__c eachRecord :listOfPendingApproval) {
                listOfWrapper.add(new DataTableWrapper(eachRecord));

            }
        }
        return listOfWrapper;
    }

    private static Set<Id> getQueueIdBelongsToCurrentUser() {
        Set<Id> setOfGroupId = new Set<Id>();
        for(GroupMember eachGroupId : [SELECT GroupId FROM GroupMember where UserOrGroupId = :UserInfo.getUserId() and Group.Type = 'Queue']){
            setOfGroupId.add(eachGroupId.GroupId);
        }
        return setOfGroupId;
    }

    @AuraEnabled
    public static List<DataTableWrapper> rejectApproveAction(List<String> listOfDQApproverIds, String action, String comments) {

        List<DQ_Deal_Qualification_Approver__c> listOfDealQualificationApprover = new DealQualificationApproverSelector()
            .selectDQApproversForDQWidget(
                new List<Object>{
                        listOfDQApproverIds
                })
            .executeQuery();
        List<DQ_Deal_Qualification_Approver__c> listOfDQApproverToUpdate = new List<DQ_Deal_Qualification_Approver__c>();
        Map<Id, DQ_Deal_Qualification_Approver__c> mapOfDQAToRecord = new Map<Id, DQ_Deal_Qualification_Approver__c>();
        Set<Id> oppIdsForEESDelete = new Set<Id>();
        List<DQ_Deal_Qualification__c> listOfDQsFromOpps = new List<DQ_Deal_Qualification__c>();
        for (DQ_Deal_Qualification_Approver__c dqAppr: listOfDealQualificationApprover) {
            DQ_Deal_Qualification_Approver__c eachDQARecord = new DQ_Deal_Qualification_Approver__c();
            eachDQARecord.Id = dqAppr.Id;
            eachDQARecord.Status__c = action == APPROVE_QUOTE ? DQGoa.APPROVED_STATUS: REJECTED_STATUS;
            eachDQARecord.Comments__c = comments;
            eachDQARecord.Approved_By__c = UserInfo.getUserId();
            eachDQARecord.Approve_Reject_Date__c = System.Now();
            listOfDQApproverToUpdate.add(eachDQARecord);
            if (dqAppr.Approval_Reason__c.contains(EES_PRODUCT) && eachDQARecord.Status__c == DQGoa.APPROVED_STATUS) {
                mapOfDQAToRecord.put(dqAppr.Id, dqAppr);
            }
        }

        if (!listOfDQApproverToUpdate.isEmpty()) {
            update listOfDQApproverToUpdate;
        }

        if (!mapOfDQAToRecord.isEmpty()) {
            for (Id dqApproverId : mapOfDQAToRecord.keySet()) {
                oppIdsForEESDelete.add(mapOfDQAToRecord.get(dqApproverId).Deal_Qualification__r.Opportunity__c);
            }

            if (!oppIdsForEESDelete.isEmpty()) {
                listOfDQsFromOpps = (List<DQ_Deal_Qualification__c>) new DealQualificationSelector()
                    .selectListDQsForSync(oppIdsForEESDelete)
                    .executeQuery();
            }
        }
        return loadPendingApproval();
    }

    public class DataTableWrapper
    {
        @AuraEnabled
        public String id {get;set;}
        @AuraEnabled
        public String oppId {get;set;}
        @AuraEnabled
        public String dealQualId {get;set;}
        @AuraEnabled
        public String dqName {get;set;}
        @AuraEnabled
        public String level {get;set;}
        @AuraEnabled
        public String status {get;set;}
        @AuraEnabled
        public DateTime submittedDate {get;set;}
        @AuraEnabled
        public String reason {get;set;}
        @AuraEnabled
        public String reasonText {get;set;}
        @AuraEnabled
        public String specialTerm {get;set;}
        @AuraEnabled
        public String brand {get;set;}
        @AuraEnabled
        public String segment {get;set;}
        @AuraEnabled
        public String minimumInitialTerm {get;set;}
        @AuraEnabled
        public Decimal totalQuote {get;set;}
        @AuraEnabled
        public Decimal costOfOneTimeItems {get;set;}
        @AuraEnabled
        public Decimal newAnnualRecurringCharges {get;set;}
        @AuraEnabled
        public Decimal overallDiscount {get;set;}
        @AuraEnabled
        public Decimal monthlyRecurringCharge {get;set;}
        @AuraEnabled
        public String quoteId {get;set;}

        public DataTableWrapper(DQ_Deal_Qualification_Approver__c record) {
            this.id = record.Id;
            this.dqName = record.Deal_Qualification__r.Name + ' [' +  record.Deal_Qualification__r.Opportunity__r.Name + ']';
            this.level = record.Approval_Step__r.Name;
            this.status = record.Status__c;
            this.submittedDate = record.Submitted_Date__c;
            this.reason = record.Approval_Reason__c != null ? record.Approval_Reason__c.replaceAll(',','\n') : '';
            this.oppId = record.Deal_Qualification__r.Opportunity__c;
            this.dealQualId = record.Deal_Qualification__c;
            this.reasonText = record.Approval_Reason__c;
            this.minimumInitialTerm = record.Deal_Qualification__r.Initial_Term__c;
            this.costOfOneTimeItems = record.Deal_Qualification__r.Cost_of_One_Time_items__c;
            this.overallDiscount = record.Deal_Qualification__r.Overall_Discount__c;
            this.newAnnualRecurringCharges = record.Deal_Qualification__r.New_Annual_Recurring_Charges__c;
            this.brand = record.Deal_Qualification__r.brand__c;
            this.segment = record.Deal_Qualification__r.Segment__c;
            this.totalQuote = record.Deal_Qualification__r.New_Annual_Recurring_Charges__c;
            this.specialTerm = record.Deal_Qualification__r.Special_Terms__c;
            this.monthlyRecurringCharge = record.Deal_Qualification__r.Quote__r.Monthly_Recurring_Revenue__c;
            this.quoteId = record.Deal_Qualification__r.Quote__c;
        }
    }
}