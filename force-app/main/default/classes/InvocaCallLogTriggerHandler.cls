public with sharing class InvocaCallLogTriggerHandler {

    public class afterUpdateInvocaCallLog extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<INVOCA_FOR_SF__Invoca_Call_Log__c> invocaRecordsForLeadUpdate = new List<INVOCA_FOR_SF__Invoca_Call_Log__c>();
            for (INVOCA_FOR_SF__Invoca_Call_Log__c invocaRecord : (List<INVOCA_FOR_SF__Invoca_Call_Log__c>)Trigger.new) {
                if (isChangedField(invocaRecord, INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__Customer_String_Value_8__c) &&
                invocaRecord.INVOCA_FOR_SF__Lead__c != null) {
                    invocaRecordsForLeadUpdate.add(invocaRecord);
                }
            }
            InvocaCallLogTriggerHelper.populateLeadGCLID(invocaRecordsForLeadUpdate);
        }
    }
}