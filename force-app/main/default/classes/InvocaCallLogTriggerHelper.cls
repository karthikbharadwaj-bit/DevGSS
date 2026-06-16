public with sharing class InvocaCallLogTriggerHelper {
        public static void populateLeadGCLID(List<INVOCA_FOR_SF__Invoca_Call_Log__c> invocaRecords) {
            Map<Id,String> leadIdInvoca = new Map<Id,String>();
            List<Lead> leadsToUpdate = new List<Lead>();

            for (INVOCA_FOR_SF__Invoca_Call_Log__c invocaRecord : invocaRecords) {
                leadIdInvoca.put(invocaRecord.INVOCA_FOR_SF__Lead__c,invocaRecord.INVOCA_FOR_SF__Customer_String_Value_8__c);
            }

            leadsToUpdate = (List<Lead>) new LeadSelector().selectLeadForConvert(new List<Object>{leadIdInvoca.keySet()}).executeQuery();
            
            for (Lead lead : leadsToUpdate) {
                lead.GCLID__c = leadIdInvoca.get(lead.id);
            }

            try {
                update leadsToUpdate;
            } catch (Exception e) {
                ExceptionHelper.createExceptionAndNotificacionHistory(e, leadsToUpdate, 'Lead Exception');
            }
        }
}