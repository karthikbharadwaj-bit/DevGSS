public class BatchJob_RemoveMavenlinkRecords implements Database.Batchable<sObject>, Schedulable, Database.Stateful {

    private String query;

    public BatchJob_RemoveMavenlinkRecords() {
        query = 'SELECT PhaseId__c ' +
                'FROM Mavenlink_Integrator__c ' +
                'WHERE PhaseId__c = null';
    }

    public BatchJob_RemoveMavenlinkRecords(String mlRecordId) {
        query = 'SELECT PhaseId__c ' +
                'FROM Mavenlink_Integrator__c ' +
                'WHERE Id = \'' + mlRecordId + '\'';
    }

    public BatchJob_RemoveMavenlinkRecords(Integer recordNumber) {
        query = 'SELECT PhaseId__c ' +
                'FROM Mavenlink_Integrator__c ' +
                'WHERE PhaseId__c = null ' +
                'LIMIT ' + recordNumber;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<sObject> scope) {
        try {
            deleteUnnecessaryRecords((List<Mavenlink_Integrator__c>) scope);
        } catch(Exception ex) {
            PlatformLog.logException('BatchJob_RemoveMavenlinkRecords: ', ex);
        }
    }

    private void deleteUnnecessaryRecords(List<Mavenlink_Integrator__c> scope) {
        if (scope != null
            && !scope.isEmpty()) {
            delete scope;
        }
    }

    public void finish(Database.BatchableContext BC) {}

    public void execute(SchedulableContext context) {
        BatchJob_RemoveMavenlinkRecords batchJob = new BatchJob_RemoveMavenlinkRecords();
        Database.executeBatch(batchJob);
    }
}