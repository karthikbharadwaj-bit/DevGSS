global class EscalateERTTeam {
    @TestVisible
    final static String ERT_TEAM = 'Case is successfully escalated to ERT Team.';
    
    webService static String escalateToERT(Id caseId) {
    string strMessage;	
        Case caseObj = new Case();
        try {
            caseObj = [select Support_ERT_Esc_Count__c,RecordTypeId,RecordType.Name,OwnerId,Owner.Name,status 
                        from case where Id = :caseId];
            System.Debug('>>33>>'+ caseObj.RecordType.Name);	
            System.Debug('>>44>>'+ caseObj.Owner.Name);
            if(caseObj != null && caseObj.status != null && caseObj.Status == 'Closed') {
                strMessage = 'Closed Case can not be escalated to ERT Team.';
            } else if(caseObj.RecordType.Name != null && caseObj.RecordType.Name == CaseHelper.RT_NAME_SUPPORT_EXECUTIVE_RESPONSE_TEAM &&
                    caseObj.OwnerId != null && caseObj.Owner.Name == 'ERT Team') {
                strMessage = 'Case is already escalated to ERT Team.';	
            } else {
                List<Group> groupERT = [select Id from Group where DeveloperName = 'ERT_Team'];
                if(groupERT != null && groupERT.size()>0) {
                    caseObj.RecordTypeId = CaseHelper.RT_ID_SUPPORT_EXECUTIVE_RESPONSE_TEAM;
                    caseObj.OwnerId = groupERT[0].Id;
                    caseObj.Support_ERT_Esc_Count__c = caseObj.Support_ERT_Esc_Count__c == null?0:caseObj.Support_ERT_Esc_Count__c;	
                    caseObj.Support_ERT_Esc_Count__c = caseObj.Support_ERT_Esc_Count__c + 1;
                    caseObj.Support_Escalate_To__c = 'Support - Executive Response Team';
                    update 	caseObj;
                    strMessage = EscalateERTTeam.ERT_TEAM; 
                }
            }
        } catch(Exception ex) {
            strMessage = 'Case cannot be escalated to ERT Team due to some problem occured.';
        } 
        return strMessage ;
    }
}