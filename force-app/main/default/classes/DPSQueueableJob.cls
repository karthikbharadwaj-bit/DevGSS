public class DPSQueueableJob implements Queueable {
    public List<String> lstPartnerAccountIds = new List<String>();
    public Map<Id,Account> newMapAccount = new Map<Id,Account>();
    public Map<Id,Account> oldMapAccount = new Map<Id,Account>();
    public Boolean isFromBatch = false;
    public DPSQueueableJob(List<String> lstPartnerIds,Map<Id,Account> newMap,Map<Id,Account> oldMap,Boolean isBatch)
    {
        this.lstPartnerAccountIds = lstPartnerIds;
        this.newMapAccount = newMap;
        this.oldMapAccount = oldMap;
        this.isFromBatch = isBatch;
    }
    @SuppressWarnings('PMD.EmptyWhileStmt')
    public void execute(QueueableContext context) {    
            if(!isFromBatch)
        {
            DateTime startTime = System.now();
            while(System.Now() < startTime.addSeconds(30)){}
        }          
        for(String accId : lstPartnerAccountIds)
        {
            if(isFromBatch || (!isFromBatch && descartesdps.DescartesDPSTriggerManager.ProceedWithScreening(accId, oldMapAccount, newMapAccount)))
            {
                descartesdps.DescartesDPSTriggerManager.triggerOnDemandSearchDPS(accId);
            }
        }        
    }
}