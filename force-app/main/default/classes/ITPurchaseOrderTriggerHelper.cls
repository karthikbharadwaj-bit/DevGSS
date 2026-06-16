public with sharing class ITPurchaseOrderTriggerHelper {

    //Set 'Location' and 'Department' fields from new/changed End User
    public class SetLocationAndDepartment extends Triggers.TriggerHandlerBase {
        override public void handle(){
            try {
                Set<Id> contactIds = new Set<Id>();
                for(IT_Purchase_Order__c itpo : (list<IT_Purchase_Order__c>)trigger.new) {
                    if(!CoreObjectBase.isFieldChanged(itpo, IT_Purchase_Order__c.End_User_Contact__c)){
                        continue;
                    }

                    itpo.Location__c = null;
                    itpo.Department__c = null;
                }
            }
            catch(Exception ex){
                PlatformLog.logException(ITPurchaseOrderTriggerHelper.class.getName(), ex);
            }
        }
    }
}