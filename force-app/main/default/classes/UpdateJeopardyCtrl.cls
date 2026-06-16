public without sharing class UpdateJeopardyCtrl {

    public Case caseToUpdate{get; set;}
    public Case oldCase{get; set;}
    public Jeopardy_History__c oldJeopardyHist{get; set;}
    public Jeopardy_History__c jeopardyHistory{get; set;}
    public Id caseId{get; set;}
    
    public static String UITheme = UserInfo.getUIThemeDisplayed();

    public UpdateJeopardyCtrl(ApexPages.StandardController stdController) {
        caseId = (Id)ApexPages.currentPage().getParameters().get('id');
        List<Case> casesToUpdate =  [SELECT Jeopardy_Code__c, Jeopardy_Description__c, CreatedById, OwnerId, Owner.Name,
                         		     Owner.Email, CreatedBy.Name, CaseNumber
                                    FROM Case
                                    WHERE Id = :caseId];
        caseToUpdate = casesToUpdate[0];
        oldCase = caseToUpdate.clone(true, true, false, false);
        List<Jeopardy_History__c> jeopardyHistoryChildren = new List<Jeopardy_History__c>([
                                                                SELECT Jeopardy_Remark__c, Jeopardy__c,
                                                                        Cases__c, CreatedDate, CreatedBy.Name
                                                                FROM Jeopardy_History__c WHERE Cases__c = :caseId
                                                                ORDER BY CreatedDate DESC LIMIT 1]);

        if (!jeopardyHistoryChildren.isEmpty()
            && jeopardyHistoryChildren[0].Jeopardy__c != 'Closed'
            && jeopardyHistoryChildren[0].Jeopardy__c != 'Cancelled') {
            
            jeopardyHistory = jeopardyHistoryChildren[0];

        } else {
            jeopardyHistory = new Jeopardy_History__c();
            jeopardyHistory.Jeopardy_Remark__c = '';
            jeopardyHistory.Jeopardy__c = '';
            jeopardyHistory.Sub_Jeopardy__c = '';
        }
        oldJeopardyHist = jeopardyHistory.clone(true, true, false, false);
        
    }

    public PageReference updateValidation() {
        if(!setErrorMsg()) {
            if((caseToUpdate.Jeopardy_Description__c == oldCase.Jeopardy_Description__c
                && caseToUpdate.Jeopardy_Code__c == oldCase.Jeopardy_Code__c)
                && oldJeopardyHist.Jeopardy_Remark__c != jeopardyHistory.Jeopardy_Remark__c) {
                update jeopardyHistory;
                    if(UITheme == 'Theme4d'){
                        PageReference recdet = new PageReference('/lightning/r/Case/'+caseId+'/view');
                        
                        recdet.setRedirect(true);
                        return recdet;
                    }else if(UITheme == 'Theme3'){
                        
                        return new PageReference('javascript:window.close()');
                    }
                    
                } else {
                    return updateCase();
                }
        }
        return null;
    }

    public PageReference updateCase() {
        JeopardyHelper.createNewJeopardyHistory(caseToUpdate, caseToUpdate.Jeopardy_Code__c, caseToUpdate.Jeopardy_Description__c, jeopardyHistory.Jeopardy_Remark__c);
        update caseToUpdate;
                    if(UITheme == 'Theme4d'){
                        PageReference recdet = new PageReference('/lightning/r/Case/'+caseId+'/view');
                        
                        recdet.setRedirect(true);
                        return recdet;
                    }else if(UITheme == 'Theme3'){
                        
                        return new PageReference('javascript:window.close()');
                    }    
    				return null;
    }

    public Boolean setErrorMsg() {
        Boolean rtnNull = false;
        if(jeopardyHistory.Jeopardy_Remark__c == null
            ||String.isEmpty(jeopardyHistory.Jeopardy_Remark__c)
            ||String.isEmpty(jeopardyHistory.Jeopardy_Remark__c.trim())) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                                'You must enter a Remark.'));
            rtnNull = true;
        }
        if(caseToUpdate.Jeopardy_Description__c == null
            || String.isEmpty(caseToUpdate.Jeopardy_Description__c)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                                'You must add a Jeopardy Description.'));
            rtnNull = true;
        }
        if(caseToUpdate.Jeopardy_Code__c == null
            || String.isEmpty(caseToUpdate.Jeopardy_Code__c)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                                'You must add a Jeopardy Code.'));
            rtnNull = true;
        }
        if(caseToUpdate.Jeopardy_Description__c == oldCase.Jeopardy_Description__c
            && caseToUpdate.Jeopardy_Code__c == oldCase.Jeopardy_Code__c
            && oldJeopardyHist.Jeopardy_Remark__c == jeopardyHistory.Jeopardy_Remark__c) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                                'You havent changed anything.'));
            rtnNull = true;
        }
        return rtnNull;
    }

    public void wipeOffRemark() {
        jeopardyHistory.Jeopardy_Remark__c = '';
    }
    //Method added to navigate to record detail page when opened in lightning
    public PageReference navToRecforLightning(){
            if(UITheme == 'Theme4d'){
        PageReference recdet = new PageReference('/lightning/r/Case/'+caseId+'/view');
         
        recdet.setRedirect(true);
        return recdet;
            }else if(UITheme == 'Theme3'){
                
                return new PageReference('javascript:window.close()');
            }
               
            
       return null;
        
    }
}