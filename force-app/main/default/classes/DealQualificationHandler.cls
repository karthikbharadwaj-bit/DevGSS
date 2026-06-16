public with sharing class DealQualificationHandler {
    public static final String DQ_APPROVE_STATUS = 'Approved';
    public static final String DQ_REJECT_STATUS = 'Rejected';
    public static final String DQ_PENDING_STATUS = 'Pending Approval';
    private static final String DQ_APPROVER_STATUS_PENDING = 'Pending';
    private static final String DQ_REMOVAL_APPROVAL_APPROVED = 'Approved';
    private static final String DQ_REMOVAL_APPROVAL_REQUIRED = 'Required';
    private static final String DQ_REJECTED_PRM_TEMPLATE_NAME = 'DQ_Rejected_PRM_Email_Template';
    private static final String DQ_APPROVED_PRM_TEMPLATE_NAME = 'DQ_Approved_PRM_Email_Template';

    public static final List<String> dqHistoryFieldsToCopyFromDq = new List<String> {
        'Auto_Renewal__c',
        'Brand__c',
        'Deal_Size__c',
        'Deal_Type__c',
        'Minimum_Package_s__c',
        'Number_of_DLs__c',
        'Overall_Discount__c',
        'Overall_Discount_One_Time__c',
        'Overall_Discount_Recurring__c',
        'CC_Special_Terms__c',
        'Overall_Discount_Contact_Center__c',
        'Initial_Term__c',
        'Region__c',
        'Status__c',
        'Segment__c',
        'Charge_Term__c',
        'Special_Terms__c',
        'Free_Shipping_Terms_Options__c',
        'CC_Initial_Term__c',
        'Is_ELA__c',
        'Roll_Out_Plan__c',
        'Start_Date__c',
        'True_Up_Terms__c',
        'Maximum_Potential__c',
        'Minimum_Baseline__c',
        'ELA_Initial_Terms__c',
        'Additional_Info__c',
        'IsDQCreatedFromCPQOpp__c',
        'Family_Discount__c',
        'Renewal_Term__c'
    };

    public static final List<String> dqDiscountHistoryFieldsToCopyFromDiscount = new List<String> {
        'Discount__c',
        'Discount_Type__c',
        'Product__c',
        'Product_Category__c',
        'Product_Family__c',
        'Product_Sub_Categories__c',
        'Quantity__c',
        'Product_Package__c',
        'PackageName__c',
        'CPQ_Configured_Product__c',
        'Group__c',
        'Subgroup__c',
        'Service__c'
    };

    public static final List<String> dqServiceDiscountHistoryFieldsToCopyFromServiceDiscount = new List<String> {
        'Service__c',
        'FreeServiceCredit__c',
        'Discretion__c',
        'EESRemoval__c',
        'WeightedDiscount__c'
    };

    public class AutoApprovedOpportunityQuoteHandler extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<DQ_Deal_Qualification__c> triggeredRecords = (List<DQ_Deal_Qualification__c>) Trigger.new;
            Map<Id, DQ_Deal_Qualification__c> oldMap = (Map<Id, DQ_Deal_Qualification__c>) Trigger.oldMap;
            //Calling method for approving Quote on DQ Approval.
            for(DQ_Deal_Qualification__c objDQRec : triggeredRecords) {
                if(isChangedFieldTo(objDQRec, DQ_Deal_Qualification__c.Status__c, DQ_APPROVE_STATUS)) {
                    DQ_SubmitQuoteForApproval1.autoApprovedOpportunityQuoteWithNoApproval(objDQRec.Opportunity__c);
                }
            }
        }

        public override Boolean bypass() {
            return Test.isRunningTest();
        }
    }


    public class DQHistoryHandler extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<DQ_Deal_Qualification__c> triggeredRecords = (List<DQ_Deal_Qualification__c>) Trigger.new;
            Map<Id, DQ_Deal_Qualification_History__c> dqHistoryMap = new Map<Id, DQ_Deal_Qualification_History__c>(
                (List<DQ_Deal_Qualification_History__c>)
                    new DealQualificationHistorySelector()
                        .selectDQHistoryOnDQStatusUpdate(new List<Object>{
                            new Map<Id, DQ_Deal_Qualification__c>(triggeredRecords).keySet()
                        })
                        .executeQuery()
            );
            /* Process Deal Qualification History records */
            List<DQ_Deal_Qualification_History__c> dqHistoryToUpsert = getDQHistory(triggeredRecords, dqHistoryMap.values());
            upsert dqHistoryToUpsert;
            Map<Id, DQ_Deal_Qualification__c> dqMap = new Map<Id, DQ_Deal_Qualification__c>((List<DQ_Deal_Qualification__c>)
                new DealQualificationSelector()
                    .selectDQOnStatusUpdate(new List<Object>{
                        new Map<Id, DQ_Deal_Qualification__c>(triggeredRecords).keySet()
                    })
                    .executeQuery()
                );
            /* Process Deal Qualification Discount History records */
            List<DQ_Deal_Qualification_Discount_History__c> dqDiscountHistoryToUpsert = DealQualificationHandler.getDQDiscountHistory(
                triggeredRecords,
                dqHistoryMap,
                dqHistoryToUpsert,
                dqMap
            );
            upsert dqDiscountHistoryToUpsert;
            List<DQ_Service_Discount_History__c> dqServiceDiscountHistoryToUpsert = DealQualificationHandler.getDQServiceDiscountHistory(
                triggeredRecords,
                dqHistoryMap,
                dqHistoryToUpsert,
                dqMap
            );
            upsert dqServiceDiscountHistoryToUpsert;
        }

        @TestVisible
        private List<DQ_Deal_Qualification_History__c> getDQHistory(
            List<DQ_Deal_Qualification__c> triggeredRecords,
            List<DQ_Deal_Qualification_History__c> existingDqHistoryList
        ) {
            List<DQ_Deal_Qualification_History__c> result = new List<DQ_Deal_Qualification_History__c>();
            Map<Id, List<DQ_Deal_Qualification_History__c>> dqIdToDQHistoryListMap = buildDqIdToDQHistoryListMap(existingDqHistoryList);

            for (DQ_Deal_Qualification__c dq : triggeredRecords) {
                if (!isChangedFieldTo(dq, DQ_Deal_Qualification__c.Status__c, DQ_PENDING_STATUS)
                    && !isChangedFieldTo(dq, DQ_Deal_Qualification__c.Status__c, DQ_APPROVE_STATUS)) {
                    continue;
                }

                List<DQ_Deal_Qualification_History__c> dqHistoryList = dqIdToDQHistoryListMap.get(dq.Id) != null
                    ? dqIdToDQHistoryListMap.get(dq.Id)
                    : new List<DQ_Deal_Qualification_History__c>();
                DQ_Deal_Qualification_History__c existingDqHistory = isChangedFieldTo(dq, DQ_Deal_Qualification__c.Status__c, DQ_PENDING_STATUS)
                    ? getDQHistoryByStatus(dqHistoryList, DQ_PENDING_STATUS)
                    : getDQHistoryByStatus(dqHistoryList, DQ_APPROVE_STATUS);
                DQ_Deal_Qualification_History__c dqHistoryToUpsert = buildDqHistoryRecord(existingDqHistory, dq);
                result.add(dqHistoryToUpsert);
            }
            return result;
        }
    }

    @TestVisible
    private static List<DQ_Deal_Qualification_Discount_History__c> getDQDiscountHistory(
        List<DQ_Deal_Qualification__c> triggeredRecords,
        Map<Id, DQ_Deal_Qualification_History__c> existingDqHistoryMap,
        List<DQ_Deal_Qualification_History__c> updatedDqHistoryList,
        Map<Id, DQ_Deal_Qualification__c> dqMap
    ) {
        Map<String, DQ_Deal_Qualification_Discount_History__c> result = new Map<String, DQ_Deal_Qualification_Discount_History__c>();
        Map<String, DQ_Deal_Qualification_Discount_History__c> keyToDQDiscountHistory = new Map<String, DQ_Deal_Qualification_Discount_History__c>();
        for (DQ_Deal_Qualification_History__c dqHistory : updatedDqHistoryList) {
            DQ_Deal_Qualification_History__c existingDqHistory = existingDqHistoryMap.get(dqHistory.Id);
            if (existingDqHistory != null && !existingDqHistory.DQ_Deal_Qualification_Discounts_History__r.isEmpty()) {
                for (DQ_Deal_Qualification_Discount_History__c dqDiscountHistory : existingDqHistory.DQ_Deal_Qualification_Discounts_History__r) {
                    String dqDiscountHistoryKey = dqHistory.Deal_Qualification__c
                        + dqDiscountHistory.PackageName__c
                        + dqDiscountHistory.Product_Category__c
                        + dqDiscountHistory.Product__c
                        + dqDiscountHistory.PackageId__c
                        + dqDiscountHistory.PackageVersion__c;
                    keyToDQDiscountHistory.put(dqDiscountHistoryKey, dqDiscountHistory);
                }
            }
        }

        for (DQ_Deal_Qualification_History__c dqHistory : updatedDqHistoryList) {
            DQ_Deal_Qualification__c dq = dqMap.get(dqHistory.Deal_Qualification__c);
            for (DQ_Deal_Qualification_Discounts__c dqDiscount : dq.Deal_Qualification_Discounts__r) {
                String dqDiscountKey = dq.Id
                    + dqDiscount.PackageName__c
                    + dqDiscount.Product_Category__c
                    + dqDiscount.Product__c
                    + dqDiscount.OriginalPackageId__c
                    + dqDiscount.OriginalPackageVersion__c;
                DQ_Deal_Qualification_Discount_History__c existingDqDiscountHistory = keyToDQDiscountHistory.get(dqDiscountKey);
                DQ_Deal_Qualification_Discount_History__c dqDiscountHistoryToUpsert = buildDqDiscountHistory(
                    existingDqDiscountHistory,
                    dqDiscount,
                    dqHistory
                );

                result.put(dqDiscountKey, dqDiscountHistoryToUpsert);
            }
        }

        return result.values();
    }

    @TestVisible
    private static DQ_Deal_Qualification_Discount_History__c buildDqDiscountHistory(
        DQ_Deal_Qualification_Discount_History__c existingDqDiscountHistory,
        DQ_Deal_Qualification_Discounts__c dqDiscount,
        DQ_Deal_Qualification_History__c dqHistory
    ) {
        DQ_Deal_Qualification_Discount_History__c dqDiscountHistory = new DQ_Deal_Qualification_Discount_History__c (
            DQ_Deal_Qualification_History__c = dqHistory.Id
        );

        for (String field : dqDiscountHistoryFieldsToCopyFromDiscount) {
            dqDiscountHistory.put(field, dqDiscount.get(field));
        }

        if(dqDiscount.PackageName__c != null) {
            dqDiscountHistory.PackageId__c = dqDiscount.OriginalPackageId__c;
            dqDiscountHistory.PackageVersion__c = dqDiscount.OriginalPackageVersion__c;
        }
        if (existingDqDiscountHistory != null) {
            dqDiscountHistory.Id = existingDqDiscountHistory.Id;
        }
        return dqDiscountHistory;
    }

    @TestVisible
    private static List<DQ_Service_Discount_History__c> getDQServiceDiscountHistory(
        List<DQ_Deal_Qualification__c> triggeredRecords,
        Map<Id, DQ_Deal_Qualification_History__c> existingDqHistoryMap,
        List<DQ_Deal_Qualification_History__c> updatedDqHistoryList,
        Map<Id, DQ_Deal_Qualification__c> dqMap
    ) {
        Map<String, DQ_Service_Discount_History__c> result = new Map<String, DQ_Service_Discount_History__c>();
        Map<String, DQ_Service_Discount_History__c> keyToDQServiceDiscountHistory = new Map<String, DQ_Service_Discount_History__c>();
        for (DQ_Deal_Qualification_History__c dqHistory : updatedDqHistoryList) {
            DQ_Deal_Qualification_History__c existingDqHistory = existingDqHistoryMap.get(dqHistory.Id);
            if (existingDqHistory != null && !existingDqHistory.DQ_Service_Discounts_History__r.isEmpty()) {
                for (DQ_Service_Discount_History__c dqServiceDiscountHistory : existingDqHistory.DQ_Service_Discounts_History__r) {
                    String dqServiceDiscountHistoryKey = dqHistory.Deal_Qualification__c
                        + dqServiceDiscountHistory.Service__c;
                    keyToDQServiceDiscountHistory.put(dqServiceDiscountHistoryKey, dqServiceDiscountHistory);
                }
            }
        }

        for (DQ_Deal_Qualification_History__c dqHistory : updatedDqHistoryList) {
            DQ_Deal_Qualification__c dq = dqMap.get(dqHistory.Deal_Qualification__c);
            for (DQ_Deal_Qualification_Service_Discount__c dqServiceDiscount : dq.DQ_Deal_Qualification_Service_Discounts__r) {
                String dqServiceDiscountKey = dq.Id
                    + dqServiceDiscount.Service__c;
                DQ_Service_Discount_History__c existingDqServiceDiscountHistory = keyToDQServiceDiscountHistory.get(dqServiceDiscountKey);
                DQ_Service_Discount_History__c dqServiceDiscountHistoryToUpsert = buildDqServiceDiscountHistory(
                    existingDqServiceDiscountHistory,
                    dqServiceDiscount,
                    dqHistory
                );

                result.put(dqServiceDiscountKey, dqServiceDiscountHistoryToUpsert);
            }
        }

        return result.values();
    }

    @TestVisible
    private static DQ_Service_Discount_History__c buildDqServiceDiscountHistory(
        DQ_Service_Discount_History__c existingDqServiceDiscountHistory,
        DQ_Deal_Qualification_Service_Discount__c dqServiceDiscount,
        DQ_Deal_Qualification_History__c dqHistory
    ) {
        DQ_Service_Discount_History__c dqServiceDiscountHistory = new DQ_Service_Discount_History__c (
            DQ_Deal_Qualification_History__c = dqHistory.Id
        );

        for (String field : dqServiceDiscountHistoryFieldsToCopyFromServiceDiscount) {
            if (field == DQDataHelper.EES_REMOVAL_FIELD_APINAME && existingDqServiceDiscountHistory != null && existingDqServiceDiscountHistory.get(field) == true) {
                dqServiceDiscountHistory.put(field, true);
            } else {
                dqServiceDiscountHistory.put(field, dqServiceDiscount.get(field));
            }
        }

        if (existingDqServiceDiscountHistory != null) {
            dqServiceDiscountHistory.Id = existingDqServiceDiscountHistory.Id;
        }
        return dqServiceDiscountHistory;
    }

    @TestVisible
    private static DQ_Deal_Qualification_History__c getDQHistoryByStatus(
        List<DQ_Deal_Qualification_History__c> dqHistoryList,
        String status
    ) {
        DQ_Deal_Qualification_History__c targetRecord;
        for (DQ_Deal_Qualification_History__c dqHistory : dqHistoryList) {
            if (dqHistory.Status__c == status) {
                targetRecord = dqHistory;
                break;
            }
        }
        return targetRecord;
    }

    @TestVisible
    private static Map<Id, List<DQ_Deal_Qualification_History__c>> buildDqIdToDQHistoryListMap(List<DQ_Deal_Qualification_History__c> dqHistoryList) {
        Map<Id, List<DQ_Deal_Qualification_History__c>> dqIdToDQHistoryListMap = new Map<Id, List<DQ_Deal_Qualification_History__c>>();
        for (DQ_Deal_Qualification_History__c dqHistory : dqHistoryList) {
            if (!dqIdToDQHistoryListMap.containsKey(dqHistory.Deal_Qualification__c)) {
                dqIdToDQHistoryListMap.put(dqHistory.Deal_Qualification__c, new List<DQ_Deal_Qualification_History__c>());
            }
            dqIdToDQHistoryListMap.get(dqHistory.Deal_Qualification__c).add(dqHistory);
        }
        return dqIdToDQHistoryListMap;
    }

    @TestVisible
    private static DQ_Deal_Qualification_History__c buildDqHistoryRecord(
        DQ_Deal_Qualification_History__c existingDQHistory,
        DQ_Deal_Qualification__c dq
    ) {
        DQ_Deal_Qualification_History__c dqHistory = new DQ_Deal_Qualification_History__c (
            Deal_Qualification__c = dq.Id
        );

        for (String field : dqHistoryFieldsToCopyFromDq) {
            dqHistory.put(field, dq.get(field));
        }

        if (existingDQHistory != null) {
            dqHistory.Id = existingDQHistory.Id;
        }

        return dqHistory;
    }

    public class QuoteApprovalStatusHandler extends Triggers.TriggerHandlerBase {

        public QuoteApprovalStatusHandler() {}

        @TestVisible
        private QuoteApprovalStatusHandler(List<DQ_Deal_Qualification__c> dqList) {super(dqList);}

        override public void handle() {
            if (!DQGoa.isDQGoaEnabled() || System.isBatch()) {
                return;
            }
            List<DQ_Deal_Qualification__c> dqList = (List<DQ_Deal_Qualification__c>) Trigger.new;
            Set<Id> approvedIdSet = new Set<Id>();
            Set<Id> rejectedIdSet = new Set<Id>();
            for (DQ_Deal_Qualification__c dqRecord : dqList) {
                Boolean isApprovedDq = isChangedFieldTo(dqRecord, DQ_Deal_Qualification__c.Status__c, DQ_APPROVE_STATUS);
                Boolean isRejectedDq = isChangedFieldTo(dqRecord, DQ_Deal_Qualification__c.Status__c, DQ_REJECT_STATUS);
                if (isApprovedDq) {
                    approvedIdSet.add(dqRecord.Opportunity__c);
                }
                if (isRejectedDq) {
                    rejectedIdSet.add(dqRecord.Opportunity__c);
                }
            }
            if (approvedIdSet.isEmpty() && rejectedIdSet.isEmpty()) {
                return;
            }
            List<Quote> updatedQuotes = updateQuoteStatus(approvedIdSet, rejectedIdSet);
            update updatedQuotes;
        }

        private List<Quote> updateQuoteStatus(Set<Id> approvedIdSet, Set<Id> rejectedIdSet) {
            List<Quote> updatedQuotes = new List<Quote>();
            if ((approvedIdSet == null || approvedIdSet.isEmpty()) && (rejectedIdSet == null || rejectedIdSet.isEmpty())) {
                return updatedQuotes;
            }
            Set<Id> opportunityIdSet = new Set<Id>(approvedIdSet);
            opportunityIdSet.addAll(rejectedIdSet);
            List<Quote> quotesForStatusUpdate = getQuotesForStatusUpdate(opportunityIdSet);
            
            Set<Id> quoteIdSet = new Set<Id>();
            for (Quote qt : quotesForStatusUpdate) {
                quoteIdSet.add(qt.Id);
            }
            Map<Id, Id> quoteIdToDQIdMap = getQuoteIdToDQIdMap(quoteIdSet);
            Set<Id> allDQIds = new Set<Id>(quoteIdToDQIdMap.values());
            
            Set<Id> dqIdsWithPendingApprovals = getDQIdsWithPendingApprovals(allDQIds);
            
            // Get current DQ status to detect manual updates
            Map<Id, String> dqIdToStatusMap = getDQStatusMap(allDQIds);
            
            for (Quote qt : quotesForStatusUpdate) {

                Id dqId = quoteIdToDQIdMap.get(qt.Id);
                Boolean hasPendingApprovals = dqId != null && dqIdsWithPendingApprovals.contains(dqId);
                Boolean isDQApproved = dqId != null && dqIdToStatusMap.get(dqId) == DQ_APPROVE_STATUS;
                //DO NOT REMOVE - This is for Automation Tests and handles the case where DQ is manually set to "Approved"
                Boolean isManualOverride = isDQApproved && hasPendingApprovals;
                
                if (dqId == null || !hasPendingApprovals || isManualOverride) {
                    String updatedStatus;
                    if (approvedIdSet.contains(qt.OpportunityId)) {
                        updatedStatus = QuoteHelper.APPROVAL_STATUS_APPROVED;
                    } else if (rejectedIdSet.contains(qt.OpportunityId)) {
                        updatedStatus = QuoteHelper.APPROVAL_STATUS_NOT_REQUIRED;
                    }
                    if (updatedStatus != null) {
                        qt.Approved_Status__c = updatedStatus;
                        updatedQuotes.add(qt);
                    }
                }
            }
            return updatedQuotes;
        }
        
        @TestVisible
        private Map<Id, Id> getQuoteIdToDQIdMap(Set<Id> quoteIdSet) {
            if (quoteIdSet == null || quoteIdSet.isEmpty()) {
                return new Map<Id, Id>();
            }
            Map<Id, Id> quoteIdToDQIdMap = new Map<Id, Id>();
            List<DQ_Deal_Qualification__c> dqList = new DealQualificationSelector()
                .selectDQByQuoteIds(quoteIdSet)
                .executeQuery();
            for (DQ_Deal_Qualification__c dq : dqList) {
                quoteIdToDQIdMap.put(dq.Quote__c, dq.Id);
            }
            return quoteIdToDQIdMap;
        }
        
        @TestVisible
        private Set<Id> getDQIdsWithPendingApprovals(Set<Id> dqIds) {
            Set<Id> dqIdsWithPendingApprovals = new Set<Id>();
            if (dqIds == null || dqIds.isEmpty()) {
                return dqIdsWithPendingApprovals;
            }
            List<DQ_Deal_Qualification_Approver__c> pendingApprovers = new DealQualificationApproverSelector()
                .selectPendingApproversByDQIds(dqIds, DQ_APPROVER_STATUS_PENDING)
                .executeQuery();
            for (DQ_Deal_Qualification_Approver__c approver : pendingApprovers) {
                dqIdsWithPendingApprovals.add(approver.Deal_Qualification__c);
            }
            return dqIdsWithPendingApprovals;
        }
        
        @TestVisible
        private Map<Id, String> getDQStatusMap(Set<Id> dqIds) {
            Map<Id, String> dqIdToStatusMap = new Map<Id, String>();
            if (dqIds == null || dqIds.isEmpty()) {
                return dqIdToStatusMap;
            }
            List<DQ_Deal_Qualification__c> dqList = new DealQualificationSelector()
                .selectDQStatusByIds(dqIds)
                .executeQuery();
            for (DQ_Deal_Qualification__c dq : dqList) {
                dqIdToStatusMap.put(dq.Id, dq.Status__c);
            }
            return dqIdToStatusMap;
        }

        @TestVisible
        private List<Quote> getQuotesForStatusUpdate(Set<Id> opportunityIdSet) {
            List<Quote> quotesForApprove = new List<Quote>();
            if (opportunityIdSet == null || opportunityIdSet.isEmpty()) {
                return quotesForApprove;
            }
            List<Quote> quotesList = new QuoteSelector()
                .selectQuoteForDQGoaApproval(opportunityIdSet)
                .executeQuery();
            for (Quote qt : quotesList) {
                if (QuoteHelper.isCCQuote(qt)) {
                    quotesForApprove.add(qt);
                } else {
                    if (String.isBlank(qt.Package_Info__c)) {
                        continue;
                    }
                    quotesForApprove.add(qt);
                }
            }
            return quotesForApprove;
        }
    }

    public class SendEmailsOnStatusChangeForPRM extends Triggers.TriggerHandlerBase {

        public SendEmailsOnStatusChangeForPRM() {}

        override public void handle() {
            List<DQ_Deal_Qualification__c> dqList = (List<DQ_Deal_Qualification__c>) Trigger.new;
            Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>();
            Map<String, EmailTemplate> templateMap = new Map<String, EmailTemplate>();
            Set<Id> dqIds = new Set<Id>();
            for (DQ_Deal_Qualification__c dqRecord : dqList) {
                Boolean isApprovedDq = isChangedFieldTo(dqRecord, DQ_Deal_Qualification__c.Status__c, DQ_APPROVE_STATUS);
                Boolean isRejectedDq = isChangedFieldTo(dqRecord, DQ_Deal_Qualification__c.Status__c, DQ_REJECT_STATUS);
                if (isApprovedDq || isRejectedDq) {
                    dqIds.add(dqRecord.Id);
                }
            }

            if (!dqIds.isEmpty()) {
                List<DQ_Deal_Qualification__c> dealQualifications = new DealQualificationSelector()
                    .selectDQForPRMSendEmail(new List<Object>{dqIds})
                    .executeQuery();
                               
                List<EmailTemplate> templates = (List<EmailTemplate>) new EmailTemplateSelector()
                    .selectEmailTemplatesByDeveloperNames(
                        new List<String> {
                            DQ_REJECTED_PRM_TEMPLATE_NAME,
                            DQ_APPROVED_PRM_TEMPLATE_NAME
                        },
                        false
                    )
                    .executeQuery();
                for (EmailTemplate template : templates) {
                    templateMap.put(template.DeveloperName, template);
                }
                for (DQ_Deal_Qualification__c dq : dealQualifications) {
                    if (!dq.Quote__r.IsPRMQuote__c) {
                        continue;
                    }
                    EmailTemplate emailTemplate = dq.Status__c == DQ_APPROVE_STATUS 
                        ? templateMap.get(DQ_APPROVED_PRM_TEMPLATE_NAME) 
                        : templateMap.get(DQ_REJECTED_PRM_TEMPLATE_NAME);
                    messages.add(buildEmail(emailTemplate, dq));
                }
                if (!messages.isEmpty()) {
                    Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
                }
            }
        }

        private Messaging.SingleEmailMessage buildEmail(EmailTemplate template, DQ_Deal_Qualification__c dqRecord) {
            String subject = template.Subject;
            String htmlBody = template.HtmlValue;
            htmlBody = htmlBody.replace('{!Name}', dqRecord.Opportunity__r.Owner.Name);
            htmlBody = htmlBody.replace('{!QuoteNumber}', dqRecord.Quote__r.QuoteNumber);
            htmlBody = htmlBody.replace('{!AccountName}', dqRecord.Opportunity__r.Account.Name);
            subject = subject.replace('{!AccountName}', dqRecord.Opportunity__r.Account.Name);
            if (template.DeveloperName == DQ_REJECTED_PRM_TEMPLATE_NAME) {
                htmlBody = htmlBody.replace('{!JustificationAndDescription}', dqRecord.Quote__r.JustificationandDescription__c);
            }
           
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            List<String> toEmailAddress = new List<String>{dqRecord.Opportunity__r.Owner.Email};
            List<String> toCCEmailAddress = new List<String>();
            if (dqRecord.Opportunity__r.Inside_Sales_Rep__r?.Email != null) {
                toEmailAddress.add(dqRecord.Opportunity__r.Inside_Sales_Rep__r?.Email);
            }
            List<User> userForCc = getUserforCc();
            if (!userForCc.isEmpty()) {
                toCCEmailAddress.add(userForCc[0].Email);
            }

            message.setUseSignature(false);
            message.setBccSender(false);
            message.setSaveAsActivity(false);
            message.setTemplateId(template.Id);
            message.setSubject(subject);
            message.setHtmlBody(htmlBody);
            message.setToAddresses(toEmailAddress);
            message.setCcAddresses(toCCEmailAddress);
            return message;
        }

        private List<User> getUserforCc() {
            List<User> users = (List<User>) new UserSelector()
                .selectUsersByIds(new Set<Id>{PrmVariousSettings__c.getInstance().UserIdForDqCcEmail__c})
                .selectFields(new List<String>{
                    'Id', 'Email'
                })
                .executeQuery();
            return users;
        }
    }

    public class SetClosedDateTime extends Triggers.TriggerHandlerBase {
        override public void handle() {
            for (DQ_Deal_Qualification__c dq : (List<DQ_Deal_Qualification__c>) Trigger.new) {
                if (dq.Status__c == DQDataHelper.STATUS_APPROVED 
                    || dq.Status__c == DQDataHelper.STATUS_REJECTED) {
                    dq.ClosedDateTime__c = DateTime.now();
                }
            }
        }
    }
}