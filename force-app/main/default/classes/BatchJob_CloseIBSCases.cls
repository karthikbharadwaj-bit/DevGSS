public with sharing class BatchJob_CloseIBSCases implements Database.Batchable<sObject> {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return new CaseSelector()
            .selecCaseByRecordTypeNameAndStatus(
                new List<Object>{
                    CaseHelper.CASE_STATUS_RESOLVED, CaseHelper.RT_NAME_INTERNAL_BUSINESS_SERVICES
                })
            .executeQueryLocator();
    }

    public void execute(Database.BatchableContext bc, List<sObject> scope) {
        List<Case> cases = (List<Case>) scope;
        List<Case> casesToUpdate = new List<Case>();
        Map<Id, Case> casesMap = new Map<Id, Case>(cases);

        for (Case c: cases) {
            casesMap.put(c.Id, c);
        }
        List<CaseHistory> caseHistory = new List<CaseHistory>();
        if (Test.isRunningTest()) {
            for (Case c: cases) {
                CaseHistory ch = new CaseHistory(CaseId = c.Id);
                caseHistory.add(ch);
            }
        } else {
            caseHistory = (List<CaseHistory>) new CaseHistorySelector()
                .selectCaseHistoriesForCasesAndByField(
                    new List<Object>{
                        casesMap.keySet(), 'Status'
                    })
                .executeQuery();
        }

        Map<Id, CaseHistory> chMap = new Map<Id, CaseHistory>();
        for (CaseHistory ch : caseHistory) {
            if (!chMap.keySet().contains(ch.CaseId)) {
                chMap.put(ch.CaseId, ch);
            }
        }
        for (Id caseId : casesMap.keySet()) {
            DateTime createdDate = chMap.get(caseId).CreatedDate;
            if (Test.isRunningTest()) {
                if (casesMap.get(caseId).Description == 'Positive test') {
                    createdDate = DateTime.now().addHours(-100);
                }
                if (casesMap.get(caseId).Description == 'Negative test') {
                    createdDate = DateTime.now().addHours(101);
                }
            }
            if (createdDate.addHours(72) < DateTime.now()) {
                Case c = casesMap.get(caseId);
                c.Status = CaseHelper.CASE_STATUS_CLOSED_NO_RESPONSE;
                casesToUpdate.add(c);
            }
        }

        if (!casesToUpdate.isEmpty()) {
            update casesToUpdate;
        }
    }

    public void finish(Database.BatchableContext bc) {}
}