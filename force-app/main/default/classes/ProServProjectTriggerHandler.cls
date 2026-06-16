public with sharing class ProServProjectTriggerHandler {

    public class ProServProjectAfter extends Triggers.TriggerHandlerBase {
        
        override public void handle() {

            ProServProjectObj proServHandler = new ProServProjectObj();
            Feature_Toggle__c featureToogleSetting = Feature_Toggle__c.getInstance();
            
            if(featureToogleSetting.NewProServObjectRelatedData__c) {
                if (Trigger.isInsert) {                
                    proServHandler.populateOrderProServId(Trigger.new);
                    proServHandler.populatePhaseProServId(Trigger.new);
                }

                if(Trigger.isUpdate) {
                    proServHandler.populateOrderProServId(Trigger.new);
                    proServHandler.populatePhaseProServId(Trigger.new);
                }
            }
        }
    }

}