public with sharing class BatchJob_SObjectCPUMonitor implements Database.Batchable<SObject>, Database.Stateful {
    private Integer insertCpuMaxUsage;
    private Integer updateCpuMaxUsage;
    private Integer numberOfRecords;
    private String error;
    private String monitoringMode;
    private String objectName;
    private CPU_Monitor__c sObjectMonitorInsert;
    private CPU_Monitor__c sObjectMonitorUpdate;

    public BatchJob_SObjectCPUMonitor(String objName) {
        objectName=objName;
        insertCpuMaxUsage = 0;
        updateCpuMaxUsage = 0;
        numberOfRecords=0;
        error = '';
        sObjectMonitorInsert = new CPU_Monitor__c(
            Name = 'Monitor '+ objName+ ' Creation ' + Date.today().month() + '-' + Date.today().day(),
            Transaction_Type__c = objName+ ' Creation'
        );
        sObjectMonitorUpdate = new CPU_Monitor__c(
            Name = 'Monitor '+ objName+ ' Update ' + Date.today().month() + '-' + Date.today().day(),
            Transaction_Type__c = objName+ ' Update'
        );
    }

    public Iterable<SObject> start(Database.batchableContext batchableContext) {
        String csvData;
        List<SObject> recordsToProcess = new List<SObject>();
        List<StaticResource> sr;
        if(!Test.isRunningTest()){
            sr = (List<StaticResource>) new StaticResourceSelector()
            .selectStaticResourceByName(new List<String>{ objectName+'TestCSV' })
            .executeQuery();
         }else{
             sr = (List<StaticResource>) new StaticResourceSelector()
            .selectStaticResourceByName(new List<String>{ objectName+'TestCSV1' })
            .executeQuery();
         }
        if (sr != null && !sr.isEmpty()) {
            csvData = sr[0].Body.toString();
            //recordsToProcess = LeadCPUMonitorHelper.csvToLeadList(LeadCPUMonitorHelper.parseCSV(csvData, false));
            recordsToProcess = LeadCPUMonitorHelper.csvToSObjectList(LeadCPUMonitorHelper.parseCSV(csvData, false),objectName);
            numberOfRecords=numberOfRecords+(Integer)recordsToProcess.size();
            
        }
        return new SObjectCSVIterator(recordsToProcess);
    }

    public void execute(Database.BatchableContext batchableContext, List<SObject> scope) {
        Integer cpuTransactionUsage;
        Savepoint sp = Database.setSavePoint();
        try {
            LeadCPUMonitorHelper.prepareData();
        	Integer cpuUsageStart = Limits.getCPUTime();
            insert scope;
            cpuTransactionUsage = Limits.getCPUTime() - cpuUsageStart;
            insertCpuMaxUsage = cpuTransactionUsage > insertCpuMaxUsage ? cpuTransactionUsage : insertCpuMaxUsage;
            //for (SObject ld : scope) {
                //ld.Status = '2. Contacted';
            //}
            cpuUsageStart = Limits.getCPUTime();
            update scope;
            cpuTransactionUsage = Limits.getCPUTime() - cpuUsageStart;
            updateCpuMaxUsage = cpuTransactionUsage > updateCpuMaxUsage ? cpuTransactionUsage : updateCpuMaxUsage;
        } catch (Exception e) {
            error = e.getMessage();
        }finally {
            Database.rollback(sp);
        }
    }

    public void finish(Database.BatchableContext batchableContext) {
        if (error == '') {
            sObjectMonitorInsert.Error__c = insertCpuMaxUsage > 10000 ? 'CPU Time Limit Exceeded' : error;
            sObjectMonitorUpdate.Error__c = updateCpuMaxUsage > 10000 ? 'CPU Time Limit Exceeded' : error;
        } else {
            sObjectMonitorInsert.Error__c = insertCpuMaxUsage > 0 ? '' : error;
            sObjectMonitorUpdate.Error__c = error;
        }
        sObjectMonitorInsert.CPU_Usage__c = insertCpuMaxUsage;
        sObjectMonitorUpdate.CPU_Usage__c = updateCpuMaxUsage;
        sObjectMonitorInsert.Number_of_Records__c = numberOfRecords;
        sObjectMonitorUpdate.Number_of_Records__c = numberOfRecords;
        try {
            insert new List<CPU_Monitor__c>{ sObjectMonitorInsert, sObjectMonitorUpdate };
            LeadCPUMonitorHelper.sendEmailNotification(
                insertCpuMaxUsage,
                updateCpuMaxUsage,
                sObjectMonitorInsert.Error__c,
                sObjectMonitorUpdate.Error__c
            );
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
    }

    class SObjectCSVIterator implements Iterator<SObject>, Iterable<SObject> {
        private List<SObject> sObjectList;
        private Integer currentIndex;
    
        public SObjectCSVIterator(List<SObject> sObjectList) {
            this.sObjectList = sObjectList;
            this.currentIndex = 0;
        }
    
        public boolean hasNext() {
            return currentIndex < sObjectList.size() - 1;
        }
    
        public SObject next() {
            if (hasNext()) {
                currentIndex++;
                return sObjectList[currentIndex];
            } else {
                throw new NoSuchElementException();
            }
        }
    
        public Iterator<SObject> Iterator() {
            return this;
        }
    }
}