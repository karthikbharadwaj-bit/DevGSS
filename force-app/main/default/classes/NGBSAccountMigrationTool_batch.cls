public class NGBSAccountMigrationTool_batch implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {
    
    private Set<Id> targetRecordIds;

    public NGBSAccountMigrationTool_batch(Set<Id> recordIds) {
        this.targetRecordIds = (recordIds == null) ? new Set<Id>() : new Set<Id>(recordIds);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        if (targetRecordIds != null && !targetRecordIds.isEmpty()) {
            return Database.getQueryLocator([
                SELECT Id, CCB_Callout__c, Errors__c, ICB_Callout__c, NGBS_Status__c, Package_Id__c, Package_Migration__c, 
                       Package_Revert__c, Technical_Account_Id__c, Update_Local_Records__c, Check_Migration_Status__c,
                       Check_Revert_Status__c
                FROM NGBSAccountMigrationToolData__c
                WHERE Id IN :targetRecordIds
            ]);
        }
        // Default to no-op when no Ids are provided to avoid unintended mass processing
        return Database.getQueryLocator('SELECT Id, CCB_Callout__c, Errors__c, ICB_Callout__c, NGBS_Status__c, ' +
                                        'Package_Id__c, Package_Migration__c, Package_Revert__c, Technical_Account_Id__c, ' + 
                                        'Update_Local_Records__c, Check_Migration_Status__c, Check_Revert_Status__c ' +
                                        'FROM NGBSAccountMigrationToolData__c WHERE NGBS_Status__c = null');
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        NGBSAccountMigrationToolData__c batchRecord = (NGBSAccountMigrationToolData__c)scope[0];

        try {
            NGBSAccountMigrationTool.migrateAccount(batchRecord);
        } catch (Exception ex) {
            NGBSAccountMigrationTool.logSalesforceErrors(ex.getMessage());
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('NGBSAccountMigrationTool_batch finished.');
    }

    @InvocableMethod(label='Run NGBS Account Migration Batch')
    public static List<String> run(List<Id> recordIds) {
        Set<Id> ids = (recordIds != null ? new Set<Id>(recordIds) : null);
        Id jobId = Database.executeBatch(new NGBSAccountMigrationTool_batch(ids), 1);
        return new List<String>{ String.valueOf(jobId) };
    }
}