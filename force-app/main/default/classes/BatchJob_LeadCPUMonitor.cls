public without sharing class BatchJob_LeadCPUMonitor implements Database.Batchable<sObject>, Database.Stateful {
    private Map<String, LeadCPUMonitorHelper.MonitorWrapper> monitorBySObject;
    private Integer amountCasesToProcess;

    public Iterable<sObject> start(Database.batchableContext batchableContext) {
        this.monitorBysObject = new Map<String, LeadCPUMonitorHelper.MonitorWrapper>();
        LeadCPUMonitorHelper.initializeMonitors(this.monitorBySObject);

        Map<String, List<sObject>> sObjectsByName = new Map<String, List<sObject>>();

        BatchjobCPUMonitorSettings__c settings = BatchjobCPUMonitorSettings__c.getOrgDefaults();
        amountCasesToProcess = (settings?.Cases_to_process__c != null) ? (Integer) settings.Cases_to_process__c : 60;

        LeadCPUMonitorHelper.initilizesObjects(sObjectsByName);
        
        return new sObjectsIterator(sObjectsByName);
    }

    public void execute(Database.BatchableContext batchableContext, List<sObject> scope) {
        Savepoint sp = Database.setSavePoint();
        LeadCPUMonitorHelper.MonitorWrapper monitor;
        try {
            String sObjectName = scope[0].getSObjectType().getDescribe().getName();
            monitor = this.monitorBySObject.get(sObjectName);
            List<sObject> newScope = new List<sObject>();
            if (sObjectName == 'Case') {
                for (Integer i = 0; i < amountCasesToProcess; i++) {
                    newScope.add(scope[i]);
                }
            } else {
                newScope = scope;
            }
            LeadCPUMonitorHelper.prepareData(sObjectName, newScope);
            Integer cpuUsageByOtherDMLs = Limits.getCPUTime();
            insert newScope;
            Integer cpuTransactionUsage = Limits.getCPUTime() - cpuUsageByOtherDmls;
            monitor.insertCpuMaxUsage = cpuTransactionUsage > monitor.insertCpuMaxUsage ? cpuTransactionUsage : monitor.insertCpuMaxUsage;
            LeadCPUMonitorHelper.prepareDataForUpdate(sObjectName, newScope);
            cpuUsageByOtherDMLs= Limits.getCPUTime();
            update newScope;
            cpuTransactionUsage = Limits.getCPUTime() - cpuUsageByOtherDMLs;
            monitor.updateCpuMaxUsage = cpuTransactionUsage > monitor.updateCpuMaxUsage ? cpuTransactionUsage : monitor.updateCpuMaxUsage;
        } catch (Exception e) {
            monitor.error = e.getMessage().abbreviate(255);
        } finally {
            Database.rollback(sp);
        }
    }

    public void finish(Database.BatchableContext batchableContext) {
        List<CPU_Monitor__c> monitorsToInsert = new List<CPU_Monitor__c>();
        for (String sObjectName : this.monitorBySObject.keySet()) {
            LeadCPUMonitorHelper.MonitorWrapper monitor = this.monitorBySObject.get(sObjectName);
            if (monitor.error == '') {
                monitor.monitorInsert.Error__c = monitor.insertCpuMaxUsage > 10000 ? 'CPU Time Limit Exceeded (> 10K ms)' : monitor.error;
                monitor.monitorUpdate.Error__c = monitor.updateCpuMaxUsage > 10000 ? 'CPU Time Limit Exceeded (> 10K ms)' : monitor.error;
            } else {
                monitor.monitorInsert.Error__c = monitor.insertCpuMaxUsage > 0 ? '' : monitor.error;
                monitor.monitorUpdate.Error__c = monitor.error;
            }
            monitor.monitorInsert.CPU_Usage__c = monitor.insertCpuMaxUsage;
            monitor.monitorUpdate.CPU_Usage__c = monitor.updateCpuMaxUsage;
            monitorsToInsert.add(monitor.monitorInsert);
            monitorsToInsert.add(monitor.monitorUpdate);
        }
        
        try {
            insert monitorsToInsert;
            LeadCPUMonitorHelper.sendEmailNotification(monitorsToInsert);
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
    }

    class sObjectsIterator implements Iterator<sObject>, Iterable<sObject> {
        private Map<String, List<sObject>> sObjectsByName;
        private String currentsObject;
        private Integer currentIndex;
        private Integer currentPosition;

        public sObjectsIterator(Map<String, List<sObject>> sObjectsByName) {
            this.sObjectsByName = sObjectsByName;
            for (String key : sObjectsByName.keySet()) {
                this.currentsObject = key;
                break;
            }
            this.currentIndex = 0;
            this.currentPosition = 0;
        }

        public boolean hasNext() {
            Boolean lastsObject = currentIndex == sObjectsByName.size() - 1;
            Boolean lastPosition = sObjectsByName.get(currentsObject).size() == currentPosition;
            return !( lastsObject && lastPosition );
        }

        public sObject next() {
            if (hasNext()) {
                Boolean lastPosition = sObjectsByName.get(currentsObject).size() == currentPosition;
                if (lastPosition) {
                    //does it work¿?
                    //String beforesObject = sObjectByName
                    //sObjectsByName.remove(beforesObject)

                    Integer nextIndex = currentIndex + 1;
                    Integer currentIndex = 0;
                    for (String key : sObjectsByName.keySet()) {
                        if (currentIndex++ == nextIndex) {
                            currentsObject = key;
                            this.currentIndex += 1;
                            this.currentPosition = 0;
                            break;
                        }
                    }
                }
                return sObjectsByName.get(currentsObject).get(currentPosition++);
            } else {
                throw new NoSuchElementException();
            }
        }

        public Iterator<sObject> Iterator() {
            return this;
        }
    }

}