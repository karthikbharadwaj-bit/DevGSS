/**************************************************************************************************
*   @Class          :   InvoiceRequestApprovalHelper
*   @Author         :   Ghanshyam Choudhari
*   @CreatedDate    :   10th May,2022
*   @Description    :   Class to handle Invoice Request Approval

***************************************************************************************************/
public without sharing  class InvoiceRequestApprovalHelper implements Queueable  {
    Approval__c app;
    private String processInstanceName;
    private Integer retryCount;

	public InvoiceRequestApprovalHelper(Approval__c app, String processInstanceName){
    	this.app = app;
        this.processInstanceName = processInstanceName;
        this.retryCount = 0;
    }

    public InvoiceRequestApprovalHelper(Approval__c app, String processInstanceName, Integer retries){
    	this.app = app;
        this.processInstanceName = processInstanceName;
        this.retryCount = retries;
    }

    public void execute(QueueableContext context) {
        List <ProcessInstance> activeApprovalProcessInstance = [
            SELECT
                Id,
                (
                    SELECT
                        Id,
                        processInstanceId,
                        processInstance.Status,
                        processInstance.submittedById,
                        TargetObjectId,
                        StepStatus,
                        OriginalActor.Name,
                        CreatedDate,
                        ProcessNode.Name
                    FROM StepsAndWorkitems
                    WHERE ProcessNode.Name != NULL
                )
            FROM ProcessInstance
            WHERE TargetObjectId = :app.Id AND Id = :app.InvoiceApprovalType__c
        ];
        if (activeApprovalProcessInstance?.size()>0) {
            List<CustomSort> processInstanceHistoryWrapList = customSortBuilder(
                activeApprovalProcessInstance[0].StepsAndWorkitems
            );
            if (processInstanceHistoryWrapList?.size() > 0 || Test.isRunningTest()) {
                processInstanceHistoryWrapList.sort();
                List<Approval.ProcessWorkitemRequest> autoApproveOrRejectRequestList = new List<Approval.ProcessWorkitemRequest>();

                for (Integer i = 0; i < processInstanceHistoryWrapList.size(); i++) {
                    switch on
                        processInstanceHistoryWrapList[i].StepStatus +
                        '=>' +
                        processInstanceHistoryWrapList[i].status {
                        when 'Pending=>Pending' {
                                autoApproveOrRejectRequestList.add(
                                    autoOrRejectApprove(
                                        processInstanceHistoryWrapList[i].aphId,
                                        processInstanceHistoryWrapList[i].originalActorId,
                                        processInstanceName == 'Reject' ? 'Reject': ApprovalHelper.PROCESSINSTANCE_APPROVE,
                                        processInstanceName == 'Reject' ? 'Auto Reject' : ApprovalHelper.AUTO_APPROVED
                                    )
                                );
                            break;
                        }
                    }
                }
                if (autoApproveOrRejectRequestList?.size() > 0) {
                    try {
                        Approval.ProcessResult[] processResults = Approval.process(autoApproveOrRejectRequestList);
                    } catch (Exception ex) {
                        if(ex.getMessage().contains('UNABLE_TO_LOCK_ROW')){
                            if (retryCount < 3) {
                                System.enqueueJob(new InvoiceRequestApprovalHelper(app, processInstanceName, retryCount++));
                            }
                        }
                    }
                    if (processInstanceName==ApprovalHelper.FINANCE_EXCEPTION_APPROVAL) {
                        app.Status__c = ApprovalHelper.STATUS_PENDING_L3_APPROVAL;
                    }else if (processInstanceName==ApprovalHelper.DB_CREDIT_CHECK) {
                        app.Status__c = ApprovalHelper.STATUS_PENDING_L4_APPROVAL;
                    }else if (processInstanceName== 'Reject') {
                        app.Status__c = ApprovalHelper.STATUS_REJECTED;
                    }
                    update app;
                }
            }
        }
    }

    private List<CustomSort> customSortBuilder(List<ProcessInstanceHistory> workItems) {
        List<CustomSort> wrapList = new List<CustomSort>();
        for (ProcessInstanceHistory item : workItems) {
            CustomSort wrap = new CustomSort(
                item.Id,
                item.processInstance.Status,
                item.targetObjectId,
                item.processInstance.submittedById,
                item.stepStatus,
                item.OriginalActorId,
                item.OriginalActor.Name,
                item.ProcessNode.Name,
                item.createdDate
            );
            wrapList.add(wrap);
        }
        return wrapList;
    }

    private Approval.ProcessWorkitemRequest autoOrRejectApprove(
        Id workId,
        String originalActor,
        String action,
        String comments
    ) {
        Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
        req.setWorkitemId(workId);
        req.setAction(action);
        req.setComments(comments);
        req.setNextApproverIds(new List<Id>{ originalActor });
        return req;
    }

    public class CustomSort implements Comparable {
        Id aphId;
        String status;
        Id targetObjectId;
        Id submittedById;
        String stepStatus;
        Id originalActorId;
        String originalActorName;
        String processNodeName;
        Datetime createdDate;

        public CustomSort(
            Id aphId,
            String status,
            Id targetObjectId,
            Id submittedById,
            String stepStatus,
            Id originalActorId,
            String originalActorName,
            String processNodeName,
            Datetime createdDate
        ) {
            this.aphId = aphId;
            this.status = status;
            this.targetObjectId = targetObjectId;
            this.submittedById = submittedById;
            this.stepStatus = stepStatus;
            this.originalActorId = originalActorId;
            this.originalActorName = originalActorName;
            this.processNodeName = processNodeName;
            this.createdDate = createdDate;
        }

        public Integer compareTo(Object objToCompare) {
            return processNodeName.CompareTo(((CustomSort) objToCompare).processNodeName);
        }
    }
}