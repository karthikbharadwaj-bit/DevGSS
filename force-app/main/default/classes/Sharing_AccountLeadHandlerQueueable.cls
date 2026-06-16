public class Sharing_AccountLeadHandlerQueueable implements Queueable {
    private Id leadId;
    
    public Sharing_AccountLeadHandlerQueueable(Id leadId) {
        this.leadId = leadId;
    }
    
    public void execute(QueueableContext context) {
        Lead objLead = [SELECT Id, Avaya_Partnership_Lead__c,ConvertedAccountId,ConvertedContactId FROM Lead WHERE id =: leadId];
        if(!objLead.Avaya_Partnership_Lead__c) {
            return;
        }
        String accountId = objLead.ConvertedAccountId;
        String contactId = objLead.ConvertedContactId;
        String role = 'Business User';

        List<AccountContactRole> acrList = (List<AccountContactRole>) new AccountContactRoleSelector()
            .selectAccountContactRolesByAccountAndContactIds(
                new List<Object>{
                    new Set<Id>{objLead.ConvertedAccountId},
                    new Set<Id>{objLead.ConvertedContactId}
                })
            .executeQuery();

        try {
            if (acrList.isEmpty()) {
                insert new AccountContactRole(
                    AccountId = objLead.ConvertedAccountId,
                    ContactId = objLead.ConvertedContactId,
                    Role = role,
                    isPrimary = true
                );
            } else {
                AccountContactRole acr = acrList[0];
                acr.Role = role;
                acr.isPrimary = true;
                update acr;
            }
        } catch (Exception e) {
            insert new Exception_And_Notification_History__c(Exception__c = 'Sharing_AccountLeadHandlerQueueable ACO Exception - ' + System.Now().format(), Exception_Desc__c = e.getMessage(), stackTraceString__c = e.getStackTraceString(), Object_Type__c = 'Lead', Record_Id__c = this.leadId, RecordTypeId = Schema.SObjectType.Exception_And_Notification_History__c.getRecordTypeInfosByName().get('Lead Exception').getRecordTypeId());
        }

        try {
            Sharing_AccountLeadHandler.sharingAOCOnLeadConvert(leadId);
        } catch (Exception e) {
            insert new Exception_And_Notification_History__c(Exception__c = 'sharingAOCOnLeadConvert Exception - ' + System.Now().format(), Exception_Desc__c = e.getMessage(), stackTraceString__c = e.getStackTraceString(), Object_Type__c = 'Lead', Record_Id__c = this.leadId, RecordTypeId = Schema.SObjectType.Exception_And_Notification_History__c.getRecordTypeInfosByName().get('Lead Exception').getRecordTypeId());
        }
    }
}