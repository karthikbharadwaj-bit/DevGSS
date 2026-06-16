public without sharing class CompleteJeopardyPopupCtrl {

    public String resultText{get; set;}
    public Id caseId{get; set;}
    public Case caseOfJeopardy{get; set;}

    public static final String JEOPARDYCODECOMPLETED= 'Completed';
    public static final String JEOPARDYCODECANCELLED= 'Cancelled';
    
    public static String UITheme = UserInfo.getUIThemeDisplayed();

    public CompleteJeopardyPopupCtrl(ApexPages.StandardController stdController) {
        caseId = ApexPages.currentPage().getParameters().get('id');
    }

    public PageReference ResolveComp(){
        ResolveJeopardy(JEOPARDYCODECOMPLETED);
        if(UITheme == 'Theme4d' ){
            PageReference recdet = new PageReference('/lightning/r/Case/'+caseId+'/view');
                        
                        recdet.setRedirect(true);
                        return recdet;
        }
        return null;
    }
    public PageReference ResolveCanc(){
        ResolveJeopardy(JEOPARDYCODECANCELLED);
        if(UITheme  == 'Theme4d' ){
            PageReference recdet = new PageReference('/lightning/r/Case/'+caseId+'/view');
                        
                        recdet.setRedirect(true);
                        return recdet;
        }
        return null;
    }

    public void ResolveJeopardy(String clickedButtonValue){
        caseOfJeopardy = [SELECT Jeopardy_Code__c, Jeopardy_Description__c, CreatedById, OwnerId, Case_Owner_Email__c,
                          Owner.Name, CaseNumber, CreatedBy.Name, Owner.Email
                          FROM Case WHERE Id = :caseId];
        JeopardyHelper.createNewJeopardyHistory(caseOfJeopardy, clickedButtonValue, null, null);
        caseOfJeopardy.Jeopardy_Code__c = clickedButtonValue;
        caseOfJeopardy.Jeopardy_Description__c = null;
        update caseOfJeopardy;
        

    }

}