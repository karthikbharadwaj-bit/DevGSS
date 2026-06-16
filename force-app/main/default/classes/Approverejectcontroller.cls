public class Approverejectcontroller {
    
    //Method to fetch all the records which are submitted for approval
    @AuraEnabled
    public static List<SubmittedRecordsWrapper> getSubmittedRecords(Boolean viewAllFlag, Integer intLimit){
        List<SubmittedRecordsWrapper> lstSubmissionWrapper = new List<SubmittedRecordsWrapper>();
        Set<Id> approverQueues = new Set<Id>();

        for(GroupMember member: [Select Group.Name, GroupId from GroupMember where UserOrGroupId = : UserInfo.getUserId() and Group.Type = 'Queue']){
            approverQueues.add(member.GroupId);
        }
       
        if(!Boolean.valueOf(viewAllFlag)){
            
            for(ProcessInstanceWorkItem psw : [Select Id,ActorId,OriginalActor.Name,CreatedDate,CreatedBy.Name,ProcessInstance.TargetObjectId,ProcessInstance.TargetObject.Name,
                                              ProcessInstance.CreatedDate,ProcessInstance.LastActor.Name from ProcessInstanceWorkItem where 
                                              (ActorId = : UserInfo.getUserId() or ActorId = : approverQueues) and 
                                              ProcessInstance.Status = 'Pending' and 
                                              ProcessInstance.CreatedDate = LAST_N_DAYS:500 
                                              order by ProcessInstance.CreatedDate desc 
                                              LIMIT :Integer.valueOf(intLimit)]){
                
                SubmittedRecordsWrapper objSubmittedRecordsWrapper = new SubmittedRecordsWrapper();
                objSubmittedRecordsWrapper.workItemId = psw.id;
                objSubmittedRecordsWrapper.workItemName ='Approve/Reject';             
                objSubmittedRecordsWrapper.recordId = psw.ProcessInstance.TargetObjectId;
                objSubmittedRecordsWrapper.recordName = psw.ProcessInstance.TargetObject.Name;
                objSubmittedRecordsWrapper.relatedTo = getObjectName(psw.ProcessInstance.TargetObjectId);//get the object name using the record id
                DateTime submitteddate = psw.CreatedDate;
                objSubmittedRecordsWrapper.submittedDate = submitteddate.format('MM/dd/yyyy hh:mm a');
                objSubmittedRecordsWrapper.submittedBy = psw.CreatedBy.Name;
                system.debug('objSubmittedRecordsWrapper'+objSubmittedRecordsWrapper);
                lstSubmissionWrapper.add(objSubmittedRecordsWrapper);
            }
            
           
        }else{
           for(ProcessInstanceWorkItem psw : [Select Id,ActorId,OriginalActor.Name,CreatedDate,CreatedBy.Name,ProcessInstance.TargetObjectId,ProcessInstance.TargetObject.Name,
                                              ProcessInstance.CreatedDate from ProcessInstanceWorkItem where 
                                              (ActorId = : UserInfo.getUserId() or ActorId = : approverQueues) and 
                                              ProcessInstance.Status = 'Pending' and 
                                              ProcessInstance.CreatedDate = LAST_N_DAYS:500 
                                              order by ProcessInstance.CreatedDate desc]){
                
                SubmittedRecordsWrapper objSubmittedRecordsWrapper = new SubmittedRecordsWrapper();
                objSubmittedRecordsWrapper.workItemId = psw.id;
                objSubmittedRecordsWrapper.workItemName ='Approve/Reject';
                objSubmittedRecordsWrapper.recordId = psw.ProcessInstance.TargetObjectId;
                objSubmittedRecordsWrapper.recordName = psw.ProcessInstance.TargetObject.Name;
                objSubmittedRecordsWrapper.relatedTo = getObjectName(psw.ProcessInstance.TargetObjectId);//get the object name using the record id
                DateTime submitteddate = psw.CreatedDate;
                objSubmittedRecordsWrapper.submittedDate = submitteddate.format('MM/dd/yyyy hh:mm a');
                objSubmittedRecordsWrapper.submittedBy = psw.CreatedBy.Name;
                system.debug('objSubmittedRecordsWrapper'+objSubmittedRecordsWrapper);
                lstSubmissionWrapper.add(objSubmittedRecordsWrapper);
            }
        }
           
        system.debug('Before return'+lstSubmissionWrapper);
        return lstSubmissionWrapper;
    }
    
    public static String getObjectName(String recordId) {
        return ((Id) recordId)?.getSObjectType().getDescribe().getName();
    }
    
    //Method to Approve or Reject the selected records
    @AuraEnabled
    public static String processRecords(List<string> lstWorkItemIds,String processType){
        system.debug('lstWorkItemIds'+lstWorkItemIds);
        String message = '';
        Integer recordsProcessed = 0;
        String comments = processType == 'Approve' ? 'Approved' : 'Rejected';
        List<Approval.ProcessWorkitemRequest> lstWorkItemRequest = new List<Approval.ProcessWorkitemRequest>();//ProcessWorkitemRequest class has methods to programmatically process submitted records
        for(string workItemId : lstWorkItemIds){
            Approval.ProcessWorkitemRequest objWorkItemRequest = new Approval.ProcessWorkitemRequest();
            objWorkItemRequest.setComments(comments);
            objWorkItemRequest.setAction(processType);//approve or reject
            objWorkItemRequest.setWorkitemId(workItemId.removeStart('/'));
            lstWorkItemRequest.add(objWorkItemRequest);
        }
        Approval.ProcessResult[] lstProcessResult = Approval.process(lstWorkItemRequest,FALSE);//process method is used for approving/rejecting records depending on setAction attribute
        for(Approval.ProcessResult processResult : lstProcessResult){
            if(processResult.isSuccess()){
                recordsProcessed++;
            }
            else{
                for(Database.Error error : processResult.getErrors()){
                    message += error.getMessage();
                }
            }
        }
        if(recordsProcessed == lstWorkItemIds.size()){
            message = 'All records are '+comments+' successfully';
        }
        return message;
    }
    
    //Wrapper class to store the column values of data table
    public class SubmittedRecordsWrapper{
         @AuraEnabled public Id workItemId{get;set;}
         @AuraEnabled public String workItemName{get;set;}
          @AuraEnabled public String recordId{get;set;}
          @AuraEnabled public String relatedTo{get;set;}
          @AuraEnabled public String recordName{get;set;}
          @AuraEnabled public String submittedBy{get;set;}
          @AuraEnabled public String submittedDate{get;set;}
    }
    
    

}