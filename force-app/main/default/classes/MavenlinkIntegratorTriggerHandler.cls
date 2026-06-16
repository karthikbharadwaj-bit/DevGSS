public with sharing class MavenlinkIntegratorTriggerHandler {

    //Avoid double ML Trigger firing
    public static Boolean updateFromPhaseTrigger = false;

    public class MavenlinkIntegratorBefore extends Triggers.TriggerHandlerBase {
        List<Phase__c> phases = new List<Phase__c>();
        override public void handle() {
            //Checking Feature Toggle Integration checkbox
            if (!Feature_Toggle__c.getInstance().Mavenlink_Integration__c || updateFromPhaseTrigger) {
                return;
            }
            PhaseTriggerHandler.updateFromMavenlink = true;
            for (Mavenlink_Integrator__c mlRecord : (List<Mavenlink_Integrator__c>)Trigger.new) {
                //Handling error transactions
                 if (!(mlRecord.ProcessStatus__c != null &&
                    mlRecord.ProcessStatus__c.equalsIgnoreCase('E'))) {
                    mlRecord.ProcessStatus__c = 'C';
                    DateTime dateNow = System.now();
                    mlRecord.ProcessedDate__c = Date.newInstance(dateNow.year(), dateNow.month(), dateNow.day());
                }
            }
        }
    }

    public class MavenlinkIntegratorAfter extends Triggers.TriggerHandlerBase {
        override public void handle() {
            if (!Feature_Toggle__c.getInstance().Mavenlink_Integration__c
                || !MavenlinkIntegratorTriggerHandler.updateFromPhaseTrigger) {
                return;
            }
            if (Trigger.isInsert) {
                List<Mavenlink_Integrator__c> mlRecords = [SELECT Id
                                                            FROM Mavenlink_Integrator__c
                                                            WHERE Id IN :Trigger.newMap.keySet()];
                if (!mlRecords.isEmpty()) {
                    for (Mavenlink_Integrator__c mlRecord : mlRecords) {
                        mlRecord.record_id__c = 'SFDC-' + mlRecord.Id;
                    }
                    updateFromPhaseTrigger = true;
                    update mlRecords;
                }
            }
        }
    }
}