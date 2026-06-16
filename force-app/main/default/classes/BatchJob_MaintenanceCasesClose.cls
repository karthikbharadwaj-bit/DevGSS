public class BatchJob_MaintenanceCasesClose implements Database.Batchable<SObject> {
    private final String QUERY_CONDITION =
        'Status !=:bind0 AND RecordTypeId =:bind1 AND Date_Completed__c != null AND Date_Completed__c <=:bind2';

    public Iterable<SObject> start(Database.BatchableContext bc) {
        CaseSelector selector = new CaseSelector();
        return selector
            .newQueryFactory()
            .selectFields(selector.getDetailFieldList())
            .setCondition(QUERY_CONDITION)
            .setQueryBindings(new List<Object>{
                CaseHelper.CASE_STATUS_CLOSED, CaseHelper.RT_ID_MAINTENANCE_CASE, Date.today()
            })
            .executeQueryLocator();
    }

    public void execute(Database.BatchableContext bc, List<Case> scope) {

        if (!scope.isEmpty()) {
            for (Case mCase : scope) {
                mCase.Status = CaseHelper.CASE_STATUS_CLOSED;
            }

            Database.SaveResult[] results = Database.update(scope, false);
            logFailedRecords(scope, results);
        }
    }

    public void finish(Database.BatchableContext bc) {
    }

    private void logFailedRecords(List<Case> casesToUpdate, DataBase.SaveResult[] saveResultList) {
        List<PlatformLog__c> logs = new List<PlatformLog__c>();

        for (Integer i = 0; i < saveResultList.size(); i++) {
            if (!saveResultList[i].isSuccess()) {
                for (Database.Error e : saveResultList[i].getErrors()) {
                    String error = 'Case Id = ' + casesToUpdate[i].Id + '\n' + e.getMessage();
                    logs.add(
                        PlatformLog.buildLog('BatchJob_MaintenanceCasesClose', e.getMessage(), error, null, null)
                    );
                }
            }
        }
        PlatformLog.logResults(logs);
    }

}