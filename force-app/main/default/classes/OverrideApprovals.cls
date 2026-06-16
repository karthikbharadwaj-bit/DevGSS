public without sharing class OverrideApprovals {
    
    public class ApprovalWrapper{
        @InvocableVariable
        public ID targetObjectId;
        
        @InvocableVariable
        public String action;
        
        @InvocableVariable
        public String comment;
    }
    
    @InvocableMethod(label='Override approval')
    public static void overrideApproval(List<ApprovalWrapper> input){
        for(ApprovalWrapper req: input){	
            
            system.debug(req.action);
            if (req.action=='Approve' || req.action=='Reject'){
                ApprovalHelper.setApprovalAction(req.targetObjectId,req.action,req.comment); 
            }    
            
        }
    }    

}