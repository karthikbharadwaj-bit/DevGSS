public with sharing class CaseActivityTriggerHelper {

    public static void updateRelatedCaseActivitiesToCancelled(Map<Id, Case_Activity__c> oldMap, Map<Id, Case_Activity__c> newMap) {
        List<String> caseIds = new List<String>();
        List<String> assignToIds = new List<String>();

        //Key = OwnerId+CaseId, Value = new owner id
        Set<String> ownerIdAndCaseIdCombination = new Set<String>();

        for (Id idCaseActivity : newMap.keySet()) {
            Case_Activity__c oldCaseActivity = oldMap.get(idCaseActivity);
            Case_Activity__c newCaseActivity = newMap.get(idCaseActivity);

            if (newCaseActivity.Status__c == 'Succeded' && oldCaseActivity.Status__c == 'New') {
                caseIds.add(newCaseActivity.Case__c);
                assignToIds.add(oldCaseActivity.Assigned_To__c);
                String key = '' + oldCaseActivity.Assigned_To__c + newCaseActivity.Case__c;
                ownerIdAndCaseIdCombination.add(key);
            }
        }

        if (ownerIdAndCaseIdCombination.size() > 0) {
            List<Case_Activity__c> caseActivitiesToCancel = (List<Case_Activity__c>) new CaseActivitySelector()
                .selectCaseActivitiesByCaseAndAssignedToAndStatus(new Object[]{
                    caseIds,
                    assignToIds,
                    'New'
                })
                .executeQuery();
            
            if (caseActivitiesToCancel.size() > 0) {
                for (Case_Activity__c caseActivityToCancel : caseActivitiesToCancel) {
                    String key = '' + caseActivityToCancel.Assigned_To__c + caseActivityToCancel.Case__c;
                    if (ownerIdAndCaseIdCombination.contains(key)) {
                        caseActivityToCancel.Status__c = 'Cancelled';
                    }
                }
    
                update caseActivitiesToCancel;
            }
        }
    }

}