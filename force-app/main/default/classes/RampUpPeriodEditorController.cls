global without sharing class RampUpPeriodEditorController {
    class OrderDTO {
        public Id orderId;
        public String orderNumber;
        public String status;
        public String recordTypeName;
        public String currencyIsoCode;
        public Id accountId;
        public Id opportunityId;

        public OrderDTO(Order orderRecord) {
            this.orderId = orderRecord.Id;
            this.orderNumber = orderRecord.OrderNumber;
            this.status = orderRecord.Status;
            this.recordTypeName = orderRecord.RecordType.Name;
            this.currencyIsoCode = orderRecord.CurrencyIsoCode;
            this.accountId = orderRecord.AccountId;
            this.opportunityId = orderRecord.OpportunityId;
        }
    }
    public String billingWizardUrl { get; set; }
    public String origin { get; set; }
    public String sId { get; set; }
    public String orderRecordJSON { get; set; }

    public static final List<String> FIELDS_TO_QUERY = new List<String> {
        'Id',
        'MaxPhaseNumber__c',
        'Booked_ProServ_OTP__c',
        'Status',
        'Booked_ProServ_OTP__c',
        'Estimated_ProServ_OTP__c',
        'hasProServ__c',
        'RecordTypeId',
        'RecordType.Name',
        'CurrencyIsoCode',
        'AccountId',
        'OpportunityId',
        'OrderNumber'
    };

    public RampUpPeriodEditorController(ApexPages.StandardController stdController) {

        if (!Test.isRunningTest()) {
            stdController.addFields(FIELDS_TO_QUERY);
        }
        Order orderRecord = (Order) stdController.getRecord();
        billingWizardUrl = EndpointsSettingsHandler.uqtServerEndpoint;
        origin = Url.getOrgDomainUrl().toExternalForm();
        sid = SettingsService.getSessionId();
        orderRecordJSON = JSON.serialize(new OrderDTO(orderRecord));
    }
}