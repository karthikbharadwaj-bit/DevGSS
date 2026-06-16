public with sharing class PartnerRequestDuplicateAccountsCtrl {

    public Account[] FoundDuplicates {get; private set;}

    public PartnerRequestDuplicateAccountsCtrl(ApexPages.StandardController controller) {
        if (Test.isRunningTest() == false) {
            controller.addFields(new List<String> { Partner_Request__c.FoundDuplicateAccountIds__c.getDescribe().getName() });
        }
        Partner_Request__c requestEntity = (Partner_Request__c)controller.getRecord();
        processRequestRecord(requestEntity);
    }

    private void processRequestRecord(Partner_Request__c request) {
        this.FoundDuplicates = new List<Account>();
        if (String.IsNotBlank(request.FoundDuplicateAccountIds__c)) {
            List<String> ids = request.FoundDuplicateAccountIds__c.split(',');
            this.FoundDuplicates = [SELECT Name, Partner_ID__c FROM Account WHERE Id IN :ids];
        }
    } 
}