@isTest
private class Test_SystemStatusIMPBasedSelector {

    private static final String STATUS_INCIDENT_ID = '0';
    private static final String STATUS_LEVEL = SupportCommunityStatus.ServiceWarning.Information.name();
    private static final String STATUS_INCIDENT_PODS = 'POD1,POD2,POD3';
    private static final String STATUS_INCIDENT_SERVICES = 'inboundCall,outboundCall,inboundFax,glip';

    @isTest
    private static void testSelectSystemStatusesByIds() {

        Set<Id> statusIds = new Map<Id, System_Status_IMP_Based__c>(
            (List<System_Status_IMP_Based__c>) new SObjectBuilder(System_Status_IMP_Based__c.SObjectType)
                .quantity(4)
                .setFields(
                new Map<SObjectField, Object>{
                    System_Status_IMP_Based__c.IncidentId__c => STATUS_INCIDENT_ID,
                    System_Status_IMP_Based__c.Level__c => STATUS_LEVEL,
                    System_Status_IMP_Based__c.PODs_Affected__c => STATUS_INCIDENT_PODS,
                    System_Status_IMP_Based__c.Services_Affected__c => STATUS_INCIDENT_SERVICES
                })
                .create()
                .getRecords()
            )
            .keySet();

        List<System_Status_IMP_Based__c> statuses = (List<System_Status_IMP_Based__c>) new SystemStatusIMPBasedSelector()
            .selectSystemStatusesByIds(new List<Object>{statusIds})
            .executeQuery();

        System.assertEquals(4, statuses.size(), 'Statuses size does not match');
        System.assertEquals(STATUS_INCIDENT_ID, statuses[0].IncidentId__c, 'IncidentId__c does not match');
        System.assertEquals(STATUS_LEVEL, statuses[0].Level__c, 'Level__c does not match');
        System.assertEquals(STATUS_INCIDENT_PODS, statuses[0].PODs_Affected__c, 'PODs_Affected__c does not match');
        System.assertEquals(STATUS_INCIDENT_SERVICES, statuses[0].Services_Affected__c, 'Services_Affected__c does not match');
    }
}