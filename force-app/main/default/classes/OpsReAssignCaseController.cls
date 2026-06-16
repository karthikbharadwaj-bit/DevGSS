public with sharing class OpsReAssignCaseController {
 public String strCaseId = ApexPages.currentPage().getParameters().get('id');
    public String strClosingComments {get; set;}    
   
    public Case objCase {get; set;}
    public String status {get; set;}  
    public List<CaseComment> objOpsReAssignCaseControllerCommentList {get; set;}
    public OpsReAssignCaseController(ApexPages.StandardController controller) {
    objCase =[Select id,ownerid from Case where id=:strCaseId];
    strClosingComments ='';
    status ='Yes';
        objOpsReAssignCaseControllerCommentList = [Select Id, ParentId, IsPublished, CommentBody, CreatedById, CreatedDate, SystemModstamp, 
                                    LastModifiedDate, LastModifiedById, IsDeleted, ConnectionReceivedId, ConnectionSentId 
                                    From CaseComment where ParentId =:strCaseId ];
       
    }
   public PageReference save()
     {
     PageReference assignPageRef;
    try {
         if(objCase.ownerid==userinfo.getUserId()){
         
           if(strClosingComments==null || strClosingComments==''){
        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.error,'Please enter the reason for reassigning the case'));
                    
        return null;
       }
        CaseComment  objLatestOpsReAssignCase = new CaseComment();
        objLatestOpsReAssignCase.ParentId = strCaseId;
        objLatestOpsReAssignCase.CommentBody= strClosingComments;
        objOpsReAssignCaseControllerCommentList.add(objLatestOpsReAssignCase);
        upsert objOpsReAssignCaseControllerCommentList;

        assignPageRef = new PageReference('/'+strCaseId);
        assignPageRef.setRedirect(TRUE);
      }
      else{
           ApexPages.addMessage(new ApexPages.message(ApexPages.severity.error,'Since you are not the assignee of the case, you are not allowed to edit this case'));
      }
      }
    catch(Exception e){
      ApexPages.addMessage(new ApexPages.message(ApexPages.severity.error,''+e.getMessage()));
     return null;
    }
  return assignPageRef ;
  }
}