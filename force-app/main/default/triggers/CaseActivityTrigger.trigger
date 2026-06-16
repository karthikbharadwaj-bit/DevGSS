trigger CaseActivityTrigger on Case_Activity__c (after insert, before update, after update) {
    if (Trigger.isAfter && trigger.isUpdate) {
        CaseActivityTriggerHelper.updateRelatedCaseActivitiesToCancelled(trigger.oldMap, trigger.newMap);
    }
}