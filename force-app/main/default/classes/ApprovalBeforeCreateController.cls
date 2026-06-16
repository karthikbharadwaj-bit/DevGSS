public with sharing class ApprovalBeforeCreateController {
    public static final String APPROVAL_PROCESS_NAME = 'Direct_to_VAR_V2';

    public Opportunity CurrentOpportunity {get; private set;}
    public String OpportunityId {get; private set;}
    public String ReasonForSharing {get; set;}
    public String CustomerLocation {get; set;}
    public String JustifyAndDescr {get; set;}

    public class ApprovalSubmitResult {
        public Boolean IsSuccess {get; set;}
        public String Message {get; set;}
        public String RedirectTo {get; set;}

        public ApprovalSubmitResult(Boolean isSuccess, String message, String redirectTo) {
            this.IsSuccess = isSuccess;
            this.Message = message;
            this.RedirectTo = redirectTo;
        }
    }

    public transient ApprovalSubmitResult OpResult {get; private set;}

    public ApprovalBeforeCreateController() {
        try {
            String queryParam = ApexPages.currentPage().getParameters().get('OpportunityId');
            this.OpportunityId = queryParam;
            Id opportunityId = Id.valueOf(queryParam);
            validateOpportunity(opportunityId);
        } catch(Exception ex) {
            addApexPageError('An error happened during page load: ' + ex);
        }
    }

    public void create() {
        Boolean atLeastOneError = false;
        atLeastOneError |= (String.IsNotBlank(this.ReasonForSharing) == false);
        atLeastOneError |= (String.IsNotBlank(this.CustomerLocation) == false);
        atLeastOneError |= (String.IsNotBlank(this.JustifyAndDescr) == false);

        if (atLeastOneError == false) {
            if (validateOpportunity(this.OpportunityId)) {
                Id approvalId = createApproval();
                if (submitApproval(approvalId)) {
                    this.OpResult = new ApprovalSubmitResult(true,
                        'Approval has been successfully created and submitted', '/' + this.OpportunityId);
                    this.CurrentOpportunity = null;
                } else {
                    this.OpResult = new ApprovalSubmitResult(false, 'An error happend during approval submit', null);
                }
            }
        } else {
            addApexPageError('Please, fill all required fields');
        }
    }

    private Id createApproval() {
        Approval__c approval = new Approval__c();
        approval.Account__c = this.CurrentOpportunity.AccountId;
        approval.RecordTypeId = ApprovalHelper.RT_ID_CHANNEL_CROSS_SELL;
        approval.Opportunity__c = this.CurrentOpportunity.Id;
        approval.Contact__c = this.CurrentOpportunity.Primary_Opportunity_Contact__c;
        approval.Type__c = ApprovalHelper.APPROVAL_TYPE_DIRECT_TO_VAR;
        approval.Module__c = ApprovalHelper.APPROVAL_MODULE_MANUAL;
        approval.Overlay_Segment__c = this.CurrentOpportunity.Overlay_Segment__c;
        approval.Direct_Sales_Rep__c = this.CurrentOpportunity.CreatedById;
        approval.Reason_for_Sharing__c = this.ReasonForSharing;
        approval.Customer_Location__c = this.CustomerLocation;
        approval.JustificationandDescription__c = this.JustifyAndDescr;
        approval.Status__c = ApprovalHelper.STATUS_NEW;
        insert approval;
        return approval.Id;
    }

    private Boolean submitApproval(Id approvalId) {
        Boolean result = true;
        Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
        request.setObjectId(approvalId);
        request.setSubmitterId(UserInfo.getUserId());
        request.setProcessDefinitionNameOrId(APPROVAL_PROCESS_NAME);
        Approval.ProcessResult requestResult = Approval.process(request);
        return requestResult.isSuccess();
    }

    private void addApexPageError(String message) {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, message));
    }

    private Boolean validateOpportunity(Id opportunityId) {
        Boolean result = (this.CurrentOpportunity = getOpportunityInfo(opportunityId)) != null;

        if (this.CurrentOpportunity != null) {
            if (this.CurrentOpportunity.Account.SM_Employees__c == null) {
                addApexPageError('SM Employees field on the Account is mandatory before involving Reseller - please contact tamhelp@ringcentral.com');
                result &= false;
            }

            if (OpportunityHelper.isAllForecastedUsersZero(this.CurrentOpportunity) ) {
                addApexPageError('Fill in at least one of the Forecasted Users fields on the Opportunity before involving Reseller');
                result &= false;
            }

            if (this.CurrentOpportunity.Approvals__r.size() > 0) {
                addApexPageError('Approval record with "Channel Cross Sell" Record Type already exists for this opportunity');
                result &= false;
            }
        }
        return result;
    }

    private Opportunity getOpportunityInfo(Id opportunityId) {
        Opportunity result = null;

        Opportunity[] opps = [
            SELECT Name, Account.Id, Account.Name, Primary_Opportunity_Contact__c, Account.SM_Employees__c,
                Overlay_Segment__c, CreatedById, Effective_No_of_Employees_Range__c, 
                Forecasted_Users__c, Forecast_Contact_Center_Users__c, Forecasted_Global_Office_Users__c,
                ForcastedDimeloUsers__c, Forecast_Connect_First_Users__c, Forecasted_RingCentral_Video_Users__c,
                (SELECT Id FROM Approvals__r WHERE RecordTypeId = :ApprovalHelper.RT_ID_CHANNEL_CROSS_SELL)
            FROM Opportunity
            WHERE Id = :opportunityId];

        if (opps.size() > 0) {
            result = opps[0];
        } else {
            addApexPageError('Could not find Opportunity by specified Id');
        }
        return result;
    }
}