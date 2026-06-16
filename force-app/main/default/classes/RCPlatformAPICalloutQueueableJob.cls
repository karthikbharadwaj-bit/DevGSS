public class RCPlatformAPICalloutQueueableJob implements Queueable, Finalizer, Database.AllowsCallouts {
	private List<Case> casesToProcess;
    private Integer BATCH_SIZE;
    private RC_Platform_API_setting__mdt setting;
    private List<RCPlatformAPICallout.ErrorResponseWrapper> errorResponse;
    
    public RCPlatformAPICalloutQueueableJob(List<Case> cases, RC_Platform_API_setting__mdt setting) {
        this.casesToProcess = cases;
        this.setting = setting;
        this.BATCH_SIZE = 30;
        
        if(Test.isRunningTest()){
            this.BATCH_SIZE = 1;
        }
    }
    
    public RCPlatformAPICalloutQueueableJob(List<RCPlatformAPICallout.ErrorResponseWrapper> errorResponse) {
        this.errorResponse = errorResponse;
    }
    
    public void execute(QueueableContext context) {
        List<Case> currentBatch = new List<Case>();   
        
        //Batching  list of cases
        if(casesToProcess.size() > BATCH_SIZE){
            for(Integer i=0; i < BATCH_SIZE; i++){
                currentBatch.add(casesToProcess[i]);
            }
        } else {
            currentBatch = casesToProcess;
        }
        
        if(setting != null) {
            errorResponse = RCPlatformAPICallout.makeCalloutToSCP(currentBatch, setting);
        }
        
        //Removing processed cases
        for(Integer i=0; i < currentBatch.size(); i++){
            casesToProcess.remove(i);
        }
        
        Finalizer finalizer = new RCPlatformAPICalloutQueueableJob(errorResponse);
        System.attachFinalizer(finalizer);
        
        //Chaining next job if more cases to process
        if (!casesToProcess.isEmpty() && !Test.isRunningTest()) {
            System.enqueueJob(new RCPlatformAPICalloutQueueableJob(casesToProcess, setting));
        }
    }
    
    public void execute(FinalizerContext ctx) {
        if(!errorResponse.isEmpty()){
            List<CaseComment> caseCommentToInsert = new  List<CaseComment>();
            List<PlatformLog__c> platformLogToInsert = new  List<PlatformLog__c>();
            List<Case> caseToSendEmail = new  List<Case>();

            for(RCPlatformAPICallout.ErrorResponseWrapper response : errorResponse){
                caseCommentToInsert.add(new CaseComment(
                    ParentId = response.erroredRecord.Id,
                    CommentBody = 'Unable to open access in SCP. Please provide admin with below error \n' + response.exceptionMessage,
                    IsPublished = false
                ));
                
                platformLogToInsert.add(PlatformLog.buildLog(
                    'RCPlatformAPI : Case '+response.erroredRecord.CaseNumber,
                	response.exceptionMessage,
                    response.stackTrace,
                    null, null
                ));
                
                caseToSendEmail.add(response.erroredRecord);
            }
            
            if(!caseCommentToInsert.isEmpty()){
                insert caseCommentToInsert;
            }
            
            if(!platformLogToInsert.isEmpty()){
                insert platformLogToInsert;
            }
            
            if(!caseToSendEmail.isEmpty()){
                Map <String, Object> params = new Map <String, Object> ();
            	params.put('erroredCases', caseToSendEmail);
                
                Flow.Interview.Case_Send_email_on_SCP_API_failure sendEmailFlow = new Flow.Interview.Case_Send_email_on_SCP_API_failure(params);
        	    sendEmailFlow.start();
            }
        }
    }
}