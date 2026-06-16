public class BatchJob_ATBC implements Database.Batchable<sObject>, Database.Stateful {
    private List<PlatformLog__c> failedUpdateLogs = new List<PlatformLog__c>();
    private String query = 'SELECT Id, User_ID__c, Name, Email, Company, Account_Renewal_Date__c, CreatedDate, LastModifiedDate '
    + 'FROM Lead ' 
    + 'WHERE (LeadSource = \'About To be Cancelled\' OR LeadSource = \'About To Be Cancelled UK\') '
        + 'AND (ATBC_Stage__c=\'New\' OR ATBC_Stage__c=\'WIP\') ' 
        + 'AND IsConverted = false '
        + 'AND User_ID__c != \'\' ' 
        + 'AND CreatedDate >= LAST_YEAR '
        + 'AND Account_Renewal_Date__c != null';

    public BatchJob_ATBC() {
    }
    
    public BatchJob_ATBC(String query) {
        this.query = query;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Lead> scope) {
        List<Lead> leadsToUpdate = new List<Lead>();

        for (Lead lead : scope) {
            if (lead.Account_Renewal_Date__c < lead.CreatedDate 
                && lead.LastModifiedDate < Datetime.now().addDays(-60)) {
                cancelLead(lead);
                leadsToUpdate.add(lead);
            } 
            
            if (lead.Account_Renewal_Date__c > lead.CreatedDate) {
                closeLead(lead);
                leadsToUpdate.add(lead);
            }
        }

        List<Database.SaveResult> updateResults = Database.update(leadsToUpdate, false);

        for (Database.SaveResult result : updateResults) {
            if (!result.isSuccess()) {
                for (Database.Error error : result.getErrors()) {
                    failedUpdateLogs.add(
                        PlatformLog.buildLog('BachJob_ATBC', 
                        error.getMessage(), 
                        String.valueOf(error.getStatusCode()), 
                        '', '')
                    );
                }
            }
        }
    }

    public void finish(Database.BatchableContext info) {
        PlatformLog.logResults(failedUpdateLogs);
    }

    static private void cancelLead(Lead lead) {
        lead.ATBC_Stage__c = LeadHelper.ATBC_STAGE_CANCELLED;
        lead.Status = LeadHelper.STATUS_DOWNGRADED;
        lead.Downgrade_Reason__c = LeadHelper.DOWNGRADE_LOW_POTENTIAL;
    }

    static private void closeLead(Lead lead) {
        lead.ATBC_Stage__c = LeadHelper.ATBC_STAGE_CLOSED;
        lead.Status = LeadHelper.STATUS_DOWNGRADED;
        lead.Downgrade_Reason__c = LeadHelper.DOWNGRADE_RETENTION_LEAD_CLOSED;
    }
}