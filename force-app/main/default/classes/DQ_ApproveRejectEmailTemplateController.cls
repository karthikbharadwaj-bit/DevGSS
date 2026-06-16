public class DQ_ApproveRejectEmailTemplateController {
	private static final String BASE_URL = URL.getOrgDomainUrl().toExternalForm();
    private static final String PAGE_LINK = BASE_URL + '/apex/DQ_DealQualificationMain?';
    private static final String UNIFIED_LINK = BASE_URL + '/apex/QuoteWizard?';
    public String dqId {get;set;}
    public String dqApproverId {get;set;}
    public String approveLink {get;set;}
    public String rejectLink {get;set;}
    public String dqLink {get;set;}
    public String packageName {get;set;}
    public Decimal overallDiscount {get;set;}
    public Decimal annualRecurringCharges {get;set;}
    public Decimal monthlyRecurringRevenue {get;set;}
    public List<DQ_DealQualificationController.ApprovalStatusWrapper> dqApproverHistoryList {get;set;}
    public static String refPlaceHolder = '_ref::{0}::ref_';
    public String refTemplateString {get;private set;}
    public Boolean unifiedQuotingEnabled {get;private set;}  
    
    public DQ_Deal_Qualification__c dqRecord {
        get {
            if (dqRecord == null) {
                dqRecord = getDealQualification();
            }
            return dqRecord;
        }
        private set;
    }
    public List<DQ_Deal_Qualification_Discounts__c> listOfDqQualDiscount {get;private set;}
    
    public DQ_ApproveRejectEmailTemplateController() {
         this.unifiedQuotingEnabled = DQGoa.isDQGoaEnabled();         
    }
        
    public DQ_Deal_Qualification__c getDealQualification() {
        DQ_Deal_Qualification__c dealQualRecord = null;
        if (this.dqId != null) {
                dealQualRecord = 
                    [SELECT Id, IsDQCreatedFromCPQOpp__c,Is_ELA__c,Maximum_Potential__c,Additional_Info__c,Minimum_Baseline__c,Start_Date__c,
					 ELA_Initial_Terms__c,Name, Brand__c, Charge_Term__c, Deal_Size__c, Deal_Type__c, Initial_Term__c, Minimum_Package_s__c, 
                     Number_of_DLs__c, Opportunity__c, Overall_Discount__c, Region__c, Renewal_Term__c, Segment__c, Status__c,
                     Type__c, Opportunity__r.Name, Opportunity__r.Owner.Name, Opportunity__r.Partner_Account__r.Name, 
                     Opportunity__r.Account.Name, Opportunity__r.Account.Type, Cost_of_One_Time_items__c,New_Annual_Recurring_Charges__c,
                     Opportunity__r.CloseDate,  Quote__r.Monthly_Recurring_Revenue__c, Justification_Description__c
                     FROM DQ_Deal_Qualification__c 
                     WHERE Id =:dqId ]; 
            listOfDqQualDiscount = getDQDiscountListByDQId(this.dqId);
            dqApproverHistoryList = DQ_DealQualificationController.getApproverDetailListByDQId(this.dqId);
            approveLink = PAGE_LINK + 'oppId=' + dealQualRecord.Opportunity__c + '&dqapprovalId=' + this.dqApproverId + '&action=approve';
            rejectLink = PAGE_LINK  + 'oppId=' + dealQualRecord.Opportunity__c + '&dqapprovalId=' + this.dqApproverId + '&action=reject';
            overallDiscount = dealQualRecord.Overall_Discount__c != null ? dealQualRecord.Overall_Discount__c.setScale(2) : 0.00;
            annualRecurringCharges = dealQualRecord.New_Annual_Recurring_Charges__c != null ? dealQualRecord.New_Annual_Recurring_Charges__c.setScale(2) : 0.00;           
            if (dealQualRecord.Quote__c != null) {
                monthlyRecurringRevenue = dealQualRecord.Quote__r.Monthly_Recurring_Revenue__c != null ? dealQualRecord.Quote__r.Monthly_Recurring_Revenue__c.setScale(2) : 0.00;
            }
            else {
                monthlyRecurringRevenue = 0.00;
            }
            if (unifiedQuotingEnabled) {
                packageName = !listOfDqQualDiscount.isEmpty() ? listOfDqQualDiscount[0].PackageName__c : '';
                dqLink = UNIFIED_LINK + 'quoteId=' +dealQualRecord.Quote__c + '&id=' + dealQualRecord.Opportunity__c;
            } else {
                packageName = dealQualRecord.Minimum_Package_s__c != null ? dealQualRecord.Minimum_Package_s__c : '';
                dqLink = PAGE_LINK  + 'oppId=' + dealQualRecord.Opportunity__c;
            }
        }
        return dealQualRecord;
    }
    
    private List<DQ_Deal_Qualification_Discounts__c> getDQDiscountListByDQId(String dqId) {
        return [SELECT Id, Name, Product__r.Name,Product_Category__c, Discount__c, Deal_Qualification__c, Product_Sub_Categories__c, Quantity__c,
                Discount_Type__c, Product__c, Product_Family__c, Promo_Code__c,PackageName__c 
                FROM DQ_Deal_Qualification_Discounts__c 
                WHERE Deal_Qualification__c = :dqId];
    }
    
}