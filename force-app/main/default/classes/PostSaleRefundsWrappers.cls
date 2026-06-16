public with sharing class PostSaleRefundsWrappers {
    public class RefundApprovalDTO {
        public Id apprId;
        public String name;
        public Id recordTypeId;
        public RefundAccountDTO accInfo;
        public List<RefundAccountDTO> serviceAccsInfo;
        public List<MigratedAccountDTO> migratedAccsInfo;
        public Decimal totalRefundAmount;
        public Map<String, Decimal> refundAmountsTotals;
        public String currencyIsoCode;

        public String approvalId;
        public String approverEmail;
        public String approverFirstName;
        public String approverLastName;
        public String refundApprovalDate;
        public Decimal refundCategoryId;
        public String refundComment;
        public String refundRequestDate;
        public Decimal refundTypeId;
        public String userEmail;
        public String userFirstName;
        public String userLastName;
        public String actorEmail;

        public RefundApprovalDTO(Approval__c appr) {
            this.apprId = appr.Id;
            this.name = appr.Name;
            this.recordTypeId = appr.RecordTypeId;
            this.accInfo = new RefundAccountDTO(appr.Account__r);
            this.refundAmountsTotals = ApprovalHelper.getRefundDetailsTotalsMap(appr);

            this.totalRefundAmount = 0;
            for (Decimal v : refundAmountsTotals.values()) {
                totalRefundAmount += v;
            }

            this.currencyIsoCode = appr.CurrencyIsoCode;

            this.serviceAccsInfo = ApprovalHelper.getServiceAccountsByProductFamily(appr);

            this.migratedAccsInfo = ApprovalHelper.getMigratedServiceAccounts(appr);

            Map<String, Object> billingParams = ApprovalHelper.getApprovalBillingInfo(appr);

            this.approvalId = (String) billingParams.get('approvalId');
            this.approverEmail = (String) billingParams.get('approverEmail');
            this.approverFirstName = (String) billingParams.get('approverFirstName');
            this.approverLastName = (String) billingParams.get('approverLastName');
            this.refundApprovalDate = (String) billingParams.get('refundApprovalDate');
            this.refundCategoryId = (Decimal) billingParams.get('refundCategoryId');
            this.refundComment = (String) billingParams.get('refundComment');
            this.refundRequestDate = (String) billingParams.get('refundRequestDate');
            this.refundTypeId = (Decimal) billingParams.get('refundTypeId');
            this.userEmail = (String) billingParams.get('userEmail');
            this.userFirstName = (String) billingParams.get('userFirstName');
            this.userLastName = (String) billingParams.get('userLastName');
            this.actorEmail = (String) billingParams.get('actorEmail');
        }
    }

    public class MigratedAccountDTO {
        public Id sfId;
        public String name;
        public String billingId;
        public String serviceType;

        public MigratedAccountDTO(Account acc) {
            this.sfId = acc.Id;
            this.name = acc.Name;
            this.billingId = acc.Billing_Id__c;
            this.serviceType = acc.Service_Type__c;
        }
    }

    public class RefundAccountDTO {
        public Id sfId;
        public String name;
        public String rcUserId;
        public String billingId;
        public String productFamily;

        public RefundAccountDTO(Account acc) {
            this.sfId = acc.Id;
            this.name = acc.Name;
            this.rcUserId = acc.RC_User_ID__c;
            this.billingId = acc.Billing_Id__c;
        }
    }

    public class TransactionHistoryServiceParams {
        public String action {get;set;}
        public String approvalId {get;set;}
        public List<TransactionPosted> transactions {get;set;}
        public String requestRaw {get;set;}
        public String responseRaw {get;set;}
    }

    public class TransactionPosted {
        public String billingTransactionId;
        public String refundType;
        public Decimal transactionRefundAmount;
        public String transactionType;
        public String refundId;
    }
}