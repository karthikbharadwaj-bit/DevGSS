public without sharing class JeopardyHelper {

    public static void createNewJeopardyHistory(Case caseOfJeopardy, String code, String description, String remark){
        Jeopardy_History__c newJeop = new Jeopardy_History__c();
        newJeop.Cases__c = caseOfJeopardy.Id;
        newJeop.Jeopardy__c = code;
        if(code != 'Completed' && code != 'Cancelled'){
            newJeop.Sub_Jeopardy__c = description;
        } else {
            newJeop.Sub_Jeopardy__c = null;
            newJeop.Date_Closed__c = Date.today();

            List<Jeopardy_History__c> jHistQuery = [SELECT Id, Date_Closed__c
                                                    FROM Jeopardy_History__c
                                                    WHERE Cases__c =: newJeop.Cases__c
                                                    ORDER BY CreatedDate ASC];
            Jeopardy_History__c closeLastOpenjeopardy;
            if (jHistQuery.size() > 1 ){
                closeLastOpenjeopardy = jHistQuery[jHistQuery.size()-1];
            } else if (jHistQuery.size() == 1) {
                closeLastOpenjeopardy = jHistQuery[0];
            }
            if (!jHistQuery.isEmpty() ){
                closeLastOpenjeopardy.Date_Closed__c = Date.today();
                update closeLastOpenjeopardy;
            }
        }
        newJeop.Jeopardy_Remark__c = remark;
        newJeop.Date_Start__c = Date.today();
        newJeop.Name = System.Now() + ' - ' + newJeop.Jeopardy__c;
        User creatorUser = [SELECT Email, Name FROM User WHERE Id = :caseOfJeopardy.CreatedById];
        newJeop.Jeopardy1_4Mail__c = creatorUser.Email;
        String ownerId = (String)caseOfJeopardy.OwnerId;
        if (ownerId.startsWith('005')) {
            User ownerUser = [SELECT Id, Email, Name FROM User WHERE Id = :ownerId][0];
            newJeop.Jeopardy5Email__c = ownerUser.Email;
            newJeop.Owner_Name__c = ownerUser.Name;
        } else {
            Group ownerQueue = [SELECT Id, Email, Name FROM Group WHERE Type = 'Queue' AND Id = :ownerId][0];
            newJeop.Jeopardy5Email__c = ownerQueue.Email;
            newJeop.Owner_Name__c = ownerQueue.Name;
        }
        try{
            newJeop.CasesCase_Owner_Email__c = caseOfJeopardy.Owner.Email;
            newJeop.CasesCaseNumber__c = caseOfJeopardy.CaseNumber;
            newJeop.CasesCreatedByName__c = caseOfJeopardy.CreatedBy.Name;
            newJeop.CasesOwnerId__c = caseOfJeopardy.Owner.Name;
            newJeop.CreatedByName__c = UserInfo.getFirstName()+' '+UserInfo.getLastName();
            insert newJeop;
        } catch(DmlException e){
            throw e;
        }
        
    }

    public static void updateDescriptionCodeForCompletedCase(Map<Id, Case> newCasesMap) {
        for (Case c : newCasesMap.values()) {
            if (c.Jeopardy_Code__c == 'Completed' || c.Jeopardy_Code__c == 'Cancelled') {
                c.Jeopardy_Description__c = null;
            }
        }
    }

}