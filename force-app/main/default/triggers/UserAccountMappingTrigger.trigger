trigger UserAccountMappingTrigger on User_Account_Mapping__c (before insert, after insert, before update, after update, before delete) {
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)){
        UserAccountMappingTriggerHandler.beforeInsertUpdateMethod(Trigger.new);
    }
    
    if(Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)){
       	UserAccountMappingTriggerHandler.afterInsertUpdateMethod(Trigger.new, Trigger.oldMap, Trigger.newMap);
    }
    
    if(Trigger.isBefore && Trigger.isDelete){
        UserAccountMappingTriggerHandler.beforeDelete(Trigger.old);     
    }
}