public with sharing class SupportCommunityStatus {

    public enum ServiceWarning {
        Good,
        Information,
        Warning,
        Error
    }

    public static Map<String, ServiceWarning> SERVICE_WARNING_BY_LABEL = new Map<String, ServiceWarning>{
        'Good' => ServiceWarning.Good,
        'Warning' => ServiceWarning.Warning,
        'Error' => ServiceWarning.Error,
        'Information' => ServiceWarning.Information
    };

    private static final SObjectField INCIDENT_PODS = System_Status_IMP_Based__c.PODs_Affected__c;
    private static final SObjectField INCIDENT_CLUSTERS = System_Status_IMP_Based__c.inContact_Cluster__c;

    private static Map<String, SObjectField> FIELD_BY_SERVICE = new Map<String, SObjectField>{
        'inboundCall' => INCIDENT_PODS,
        'outboundCall' => INCIDENT_PODS,
        'inboundFax' => INCIDENT_PODS,
        'outboundFax' => INCIDENT_PODS,
        'spRegistration' => INCIDENT_PODS,
        'registration' => INCIDENT_PODS,
        'inboundSms' => INCIDENT_PODS,
        'outboundSms' => INCIDENT_PODS,
        'meetings' => INCIDENT_PODS,
        'glip' => INCIDENT_PODS,
        'serviceWeb' => INCIDENT_PODS,
        'platform' => INCIDENT_PODS,
        'devSandbox' => INCIDENT_PODS,
        'contactCenter' => INCIDENT_CLUSTERS
    };

    public class ServiceInfo {

        public String serviceWarning;
        public List<System_Status_IMP_Based__c> incidentList;

        // "region" means either POD or Cluster depending on service
        private transient String userRegionValue;
        private transient SObjectField regionField;
        private transient ServiceWarning overallLevel;
        private transient List<IncidentWrapper> incidentWrappers;

        public ServiceInfo(String service) {
            this.overallLevel = SupportCommunityStatus.ServiceWarning.Good;
            this.incidentList = new List<System_Status_IMP_Based__c>();
            this.incidentWrappers = new List<IncidentWrapper>();
            this.regionField = FIELD_BY_SERVICE.get(service);
            this.userRegionValue = this.regionField == INCIDENT_CLUSTERS 
                ? SCUserService.accountCluster
                : SCUserService.accountPOD;
        }

        public void processIncident(System_Status_IMP_Based__c incident) {
            String regions = (String) incident.get(this.regionField);
            if (String.isNotBlank(regions) && regions.split(',').contains(this.userRegionValue)) {
                this.incidentWrappers.add(new IncidentWrapper(incident));
            }
        }

        public void finalize() {
            this.incidentWrappers.sort();
            for (IncidentWrapper incidentWr : this.incidentWrappers) {
                this.incidentList.add(incidentWr.sObj);
            }
            calculateOverallLevel();
        }

        private void calculateOverallLevel() {
            for (IncidentWrapper incidentWr : this.incidentWrappers) {
                if (incidentWr.level.ordinal() > this.overallLevel.ordinal()) {
                    this.overallLevel = incidentWr.level;
                }
            }
            this.serviceWarning = this.overallLevel.name();
        }
    }

    private class IncidentWrapper implements Comparable {
        public System_Status_IMP_Based__c sObj;
        public DateTime createdDate;
        public ServiceWarning level;

        public IncidentWrapper(System_Status_IMP_Based__c sObj) {
            this.sObj = sObj;
            this.createdDate = String.isBlank(sObj.Date__c)
                ? DateTime.Valueof('1900-05-29 00:00:00')
                : DateTime.Valueof(sObj.Date__c.replace('T', ' '));
            this.level = SERVICE_WARNING_BY_LABEL.get(sObj.Level__c);
        }

        public Integer compareTo(Object otherObject) {
            IncidentWrapper otherIncident = (IncidentWrapper) otherObject;
            if (this.createdDate < otherIncident.createdDate) {
                return 1;
            }
            if (this.createdDate == otherIncident.createdDate) {
                return 0;
            }
            return -1;
        }
    }

    @AuraEnabled(cacheable=true)
    public static String getSystemStatus() {
        Set<Id> latestIncidentIds = new Set<Id>();
        Map<String, System_Status_IMP_Based__c> incidentToRecord = new Map<String, System_Status_IMP_Based__c>();
        for (System_Status_IMP_Based__c incident : (List<System_Status_IMP_Based__c>) new SystemStatusIMPBasedSelector()
                .selectSystemStatuses()
                .executeQuery()) {
            if (!incidentToRecord.containsKey(incident.IncidentId__c)) {
                incidentToRecord.put(incident.IncidentId__c, incident);
            } else if (incidentToRecord.get(incident.IncidentId__c).CreatedDate < incident.CreatedDate) {
                incidentToRecord.put(incident.IncidentId__c, incident);
            }
        }
        for (System_Status_IMP_Based__c incident : incidentToRecord.values()) {
            latestIncidentIds.add(incident.id);
        }
        
        Map<String, ServiceInfo> result = new Map<String, ServiceInfo>();
        for (String service : FIELD_BY_SERVICE.keySet()) {
            result.put(service, new ServiceInfo(service));
        }
        for (System_Status_IMP_Based__c incident : (List<System_Status_IMP_Based__c>) new SystemStatusIMPBasedSelector()
                .selectSystemStatusesByIds(new List<Object>{latestIncidentIds})
                .executeQuery()) {

            if (String.isBlank(incident.Services_Affected__c)) {
                continue;
            }
            for (String service : incident.Services_Affected__c.split(',')) {
                if (FIELD_BY_SERVICE.containsKey(service)) {
                    result.get(service).processIncident(incident);
                }
            }
        }
        for (String service : result.keySet()) {
            result.get(service).finalize();
        }
        return JSON.serialize(result);
    }
}