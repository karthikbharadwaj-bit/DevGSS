trigger TaskAfter on Task (after insert, after update, after delete, after undelete) {
    
    if (TriggerHandler.BY_PASS_AFTER) {
        System.debug('### RETURNED FROM TASK TRIGGER AFTER TRG FOR STANDARD LAYOUT ###');
        return;
    }

    new Triggers()
        .bind(Triggers.Evt.afterinsert, new TaskTriggerHandler.RcActivityInfoCreation())
        .bind(Triggers.Evt.afterupdate, new TaskTriggerHandler.RcActivityInfoCreation())
        .manage();
        
    Map<Id, Lead> leadsToUpdate = new Map<Id, Lead>();
    rollUpLogic(leadsToUpdate);
    if(!leadsToUpdate.isEmpty() ){
        try {
            Triggers.switchOff();
            Database.update(leadsToUpdate.values(), false);
            Triggers.switchOn();
        } catch(DmlException ex) {
            throw ex;
        }
        
    }
    
    public static void rollUpLogic(Map<Id, Lead> leadUpdate){
    task[] triggerRecords;
    if(Trigger.isDelete){
        triggerRecords = Trigger.old;
    } else {
        triggerRecords = Trigger.new;
    }

    Set<id> whoIds = new Set<id>();
    for(Task task_obj:triggerRecords){
        whoIds.add(task_obj.WhoId);
    }

    Integer iVal;
    if(!whoIds.isEmpty() ){
        Map<id,Lead> Lead_map = new Map<id,Lead>([SELECT Id, Call_Attempts__c,
                                                  Activity_First_Attempt__c
                                                  FROM Lead
                                                  WHERE Id IN :whoids]);
        for(Task taskObj: triggerRecords) {
             Lead leadObj =  Lead_map.get(taskObj.WhoId);   
             if(leadObj != null) {    
                 boolean bChange = false;
                 if(trigger.isInsert){
                     if(leadObj.Activity_First_Attempt__c == null){
                            leadObj .Activity_First_Attempt__c = Date.today();
                            bChange = true;
                        }
                        if(taskObj.Subject == 'Call'){
                            leadObj.Call_Attempts__c = Integer.valueOf((leadObj.Call_Attempts__c == null ? 0 : leadObj.Call_Attempts__c)) + 1;
                            bChange = true;
                        }
                    } else if(trigger.isUpdate){
                        if(taskObj.Subject != 'Call' && trigger.oldMap.get(taskObj.Id).Subject == 'Call'){
                            if(taskObj.Reset_OnCallAttemp__c  == False){
                                leadObj.Call_Attempts__c = Integer.valueOf((leadObj.Call_Attempts__c == null ? 0 : leadObj.Call_Attempts__c)) - 1;
                                bChange = true;
                            }
                        } else if(taskObj.Subject == 'Call' && taskObj.Subject != trigger.oldMap.get(taskObj.Id).Subject){       
                            if(taskObj.Reset_OnCallAttemp__c == False){
                                leadObj.Call_Attempts__c = Integer.valueOf((leadObj.Call_Attempts__c == null ? 0 : leadObj.Call_Attempts__c)) + 1;
                                bChange = true;
                            }
                        }
                    } else if(trigger.isDelete){
                        if(taskObj.Subject == 'Call'){
                            if(taskObj.Reset_OnCallAttemp__c == False){
                                leadObj.Call_Attempts__c = Integer.valueOf((leadObj.Call_Attempts__c == null ? 0 : leadObj.Call_Attempts__c)) - 1;
                                bChange = true;
                            }
                        }
                    }else if(trigger.isUndelete){
                        if(taskObj.Subject == 'Call'){       
                            if(taskObj.Reset_OnCallAttemp__c == False){
                                leadObj.Call_Attempts__c = Integer.valueOf((leadObj.Call_Attempts__c == null ? 0 : leadObj.Call_Attempts__c)) + 1;	                       
                                bChange = true;
                            }
                        }
                    }
                    
                    if(bChange){
                        if(leadUpdate.get(leadObj.id) != null){
                            leadUpdate.get(leadObj.id).Call_Attempts__c = leadObj.Call_Attempts__c;
                        } else {
                            leadUpdate.put(leadObj.id, leadObj);
                        }
                        
                    }
                }        
                
            }
        }
    }
}