public class CaseJeopardyCtrl {

    public String caseId {get; set;}
    public String jeopardyHistoryId {get; set;}

    public Case jeopardyCase {get{
        if (jeopardyCase == null) {
            List<Case> jeopardyCases = new List<Case>([ SELECT Id, CreatedBy.Name, CaseNumber, Owner.Name, Case_Owner_Email__c
                                                        FROM Case
                                                        WHERE Id =: caseId
                                                        LIMIT 1]);
            if (!jeopardyCases.isEmpty() ){
                jeopardyCase = jeopardyCases[0];
            }
        }
        return jeopardyCase;
    } set;}

    public Jeopardy_History__c jeopardyHistory {get{
        if (jeopardyHistory == null){
            List<Jeopardy_History__c> jeopardyHistories = new List<Jeopardy_History__c>([   
                    SELECT Id, Jeopardy__c, Jeopardy_Age_Business_Days__c, Sub_Jeopardy__c, Jeopardy_Remark__c
                    FROM Jeopardy_History__c
                    WHERE Id=: jeopardyHistoryId
                    LIMIT 1]);
            if (!jeopardyHistories.isEmpty() ){
                jeopardyHistory = jeopardyHistories[0];
            }
        }
        return jeopardyHistory;
    } set;}

    public CaseJeopardyCtrl() {}

}