global with sharing class PostSaleRefundsController {

    public Approval__c approvalObj    { get; set; }
    public String billingWizardURL    { get; set; }
    public String origin              { get; set; }
    public String sId                 { get; set; }

    public String dataJSON { get; set; }

    private static final List<String> FIELDS_TO_QUERY = new List<String> {
        'Id',
        'Name',
        'Account__r.Name',
        'Account__r.Id',
        'Account__r.RC_User_ID__c',
        'Account__r.Billing_ID__c',
        'CurrencyIsoCode',
        'Category__c',
        'Refund_Type__c',
        'Total_Refund_Amount__c',
        'Amount__c',
        'TotalRCCoreRefundAmount__c',
        'TotalProServRefundAmount__c',
        'TotalCCRefundAmount__c',
        'TotalNGBSRefundAmount__c',
        'Approval_ID__c',
        'Level1Approver__c',
        'Level1Approver__r.Email',
        'Level1Approver__r.FirstName',
        'Level1Approver__r.LastName',
        'Owner.Email',
        'Owner.FirstName',
        'Owner.LastName',
        'JustificationandDescription__c',
        'Refund_Product_Family_1__c',
        'Refund_Product_Family_2__c',
        'Refund_Product_Family_3__c',
        'Refund_Product_Family_4__c',
        'Refund_Product_Family_5__c',
        'Refund_Product_Family_6__c'
    };

    /**
     * Page Controller
     * @param  stdController
     */
    public PostSaleRefundsController(ApexPages.StandardController stdController) {

        if (!Test.isRunningTest()) {
            stdController.addFields(FIELDS_TO_QUERY);
        }

        approvalObj = (Approval__c) stdController.getRecord();

        billingWizardURL = EndpointsSettingsHandler.uqtServerEndpoint;
        origin = URL.getOrgDomainUrl().toExternalForm();
        sid = SettingsService.getSessionId();

        PostSaleRefundsWrappers.RefundApprovalDTO raDTO = new PostSaleRefundsWrappers.RefundApprovalDTO(approvalObj);
        dataJSON = JSON.serialize(raDTO);
    }

}