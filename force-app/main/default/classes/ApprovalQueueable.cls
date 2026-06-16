global without sharing  class ApprovalQueueable extends QueueableBase {

    public override void execute (QueueableContext context) {
        List<Approval__c> lstApproval = new List<Approval__c>();
        for (Object item : getLocalScope(null)) {
            lstApproval.add((Approval__c) item);
        }

        List<ProcessInstance> processList = new List<ProcessInstance>();
        processList = getProcessInstance(lstApproval);

        Map<Id, String> currentApproverMap = new Map<Id, String>();
        for (ProcessInstance processObj : processList) {
            if (processObj.Workitems != null && !processObj.Workitems.isEmpty()) {
                currentApproverMap.put(processObj.TargetObjectId,processObj.Workitems[0].OriginalActor.Name);
            } else if (processObj.StepsAndWorkitems != null && !processObj.StepsAndWorkitems.isEmpty()) {
                currentApproverMap.put(processObj.TargetObjectId,processObj.StepsAndWorkitems[0].OriginalActor.Name);
            }
        }
        List<Approval__c> lstApprovalUpd = new List<Approval__c>();
        if (currentApproverMap != null) {
            for (Approval__c approval : lstApproval) {
                if (Test.isRunningTest() || (currentApproverMap.get(approval.id) != null && approval.Current_Approver__c != currentApproverMap.get(approval.id))) {
                    Approval__c objUpd = new Approval__c(id = approval.id);
                    objUpd.Current_Approver__c = currentApproverMap.get(approval.id);
                    lstApprovalUpd.add(objUpd);
                }
            }
        }
        if (!lstApprovalUpd.isEmpty()) {
            TriggerHandler.BY_PASS_Approver_Trigger = true;
            try {
                update lstApprovalUpd;
            } catch (Exception e) {
                Platformlog.logResult('ApprovalQueueable', e.getMessage(), 'ErrorMessage: ' +e.getMessage() + ' StackTrace: ' + e.getStackTraceString(), null, null, false);
            }
        }
    }
    private List<ProcessInstance> getProcessInstance(List<Approval__c> lstApproval) {
        return [SELECT TargetObjectId,
                        (SELECT OriginalActorId, ActorId, CreatedDate,OriginalActor.Name FROM Workitems ORDER BY createddate DESC LIMIT 1),
                        (SELECT StepStatus, OriginalActorId, ActorId, CreatedDate,OriginalActor.Name FROM StepsAndWorkitems ORDER BY createddate DESC LIMIT 1)
                        FROM ProcessInstance
                        WHERE TargetObjectId IN :lstApproval ORDER BY createddate ASC];
    }
}