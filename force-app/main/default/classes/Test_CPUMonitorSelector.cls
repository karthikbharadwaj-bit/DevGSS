@isTest
private class Test_CPUMonitorSelector {
	//Lead fields defined
    private static final String LEAD_FIRST_NAME = 'Test';
    private static final String LEAD_LAST_NAME = 'Test';
    private static final String LEAD_EMAIL = 'testlead@test.com';
    
    //CPU monitor fields defined 
    private static final String CPU_MONITOR_TRANSACTION_TYPE = 'Lead Conversion'; 
    private static final String CPU_MONITOR_ERROR = 'Some error';
    
    //Assert messages defined 
    private static final String ASSERT_MESSAGE = 'Expected 1 CPU monitor';
    private static final String ASSERT_EQUALS_MESSAGE = 'Wrong CPU monitors selected';
    
    @testSetup
    private static void testData() {

        Lead testLead = (Lead) new SObjectBuilder(Lead.SobjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Lead.FirstName => LEAD_FIRST_NAME,
                    Lead.LastName => LEAD_LAST_NAME,
                    Lead.Email => LEAD_EMAIL
                }
            )
            .create()
            .getRecord();
        
        CPU_Monitor__c testCPUM = (CPU_Monitor__c) new SObjectBuilder(CPU_Monitor__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    CPU_Monitor__c.Lead__c => testLead.Id,    
                    CPU_Monitor__c.Transaction_Type__c => CPU_MONITOR_TRANSACTION_TYPE,
                    CPU_Monitor__c.Error__c => CPU_MONITOR_ERROR
                }
            )
            .create()
            .getRecord(); 
    }
    
    @isTest
    private static void testSelectLastErrorLeadConversionCPUMonitor(){
        List<CPU_Monitor__c> lastErrorLeadConversionCPUMonitor = (List<CPU_Monitor__c>) new CPUMonitorSelector()
            .selectLastErrorLeadConversionCPUMonitor()
            .executeQuery();
        
        System.assert(lastErrorLeadConversionCPUMonitor.size() == 1, ASSERT_MESSAGE);
    }
    
    @isTest
    private static void testSelectCPUMonitorByTransactionType(){
        List<CPU_Monitor__c> cPUMonitorByTransactionType = (List<CPU_Monitor__c>) new CPUMonitorSelector()
            .selectCPUMonitorByTransactionType(new List<Object>{new Set<String>{CPU_MONITOR_TRANSACTION_TYPE}})
            .executeQuery();
        
        System.assert(cPUMonitorByTransactionType.size() == 1, ASSERT_MESSAGE);
        System.assertEquals(CPU_MONITOR_TRANSACTION_TYPE, cPUMonitorByTransactionType[0].Transaction_Type__c, ASSERT_EQUALS_MESSAGE);
    }
    
    @isTest
    private static void testSelectCPUMonitorForSendingEmail(){
        List<CPU_Monitor__c> cPUMonitorForSendingEmail = (List<CPU_Monitor__c>) new CPUMonitorSelector()
            .selectCPUMonitorForSendingEmail(new List<Object>{new Set<String>{CPU_MONITOR_TRANSACTION_TYPE}})
            .executeQuery();
        
        System.assert(cPUMonitorForSendingEmail.size() == 1, ASSERT_MESSAGE);
    }
    
    @isTest
    private static void testSelectCPUMonitorForLeadConversionMonitor(){
        List<Lead> leadByLastName = (List<Lead>) new LeadSelector()
            .selectLeadByLastName(new List<Object>{new Set<String>{LEAD_LAST_NAME}})
            .executeQuery();
        
        List<CPU_Monitor__c> cPUMonitorForLeadConversionMonitor = (List<CPU_Monitor__c>) new CPUMonitorSelector()
            .selectCPUMonitorForLeadConversionMonitor(new List<Object>{new Set<Id>{leadByLastName[0].Id}})
            .executeQuery();
        
        System.assert(cPUMonitorForLeadConversionMonitor.size() == 1, ASSERT_MESSAGE);
    }

    @isTest
    private static void testSelectCPUMonitorById(){
        List<CPU_Monitor__c> lastErrorLeadConversionCPUMonitor = (List<CPU_Monitor__c>) new CPUMonitorSelector()
            .selectLastErrorLeadConversionCPUMonitor()
            .executeQuery();
        
        List<CPU_Monitor__c> cPUMonitorById = (List<CPU_Monitor__c>) new CPUMonitorSelector()
            .selectCPUMonitorById(new List<Object>{new Set<Id>{lastErrorLeadConversionCPUMonitor[0].Id}})
            .executeQuery();
        
        System.assert(cPUMonitorById.size() == 1, ASSERT_MESSAGE);
        System.assertEquals(lastErrorLeadConversionCPUMonitor[0].Id, cPUMonitorById[0].Id, ASSERT_EQUALS_MESSAGE);
    }
     
}