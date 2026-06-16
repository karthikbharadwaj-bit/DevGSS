public class Batchjob_DFRUpdateFields implements Database.Batchable<sObject>, 
   Database.RaisesPlatformEvents {
    private static final String CUSTOM_EXCEPTION_MESSAGE = 'Custom Exception for testing purposes';
    Datetime fromDate;
    Datetime toDate;
    boolean forceFailure = false;
    class CustomDFRUpdateFieldsException extends Exception {}
    public Batchjob_DFRUpdateFields(Datetime startDate, Datetime stopDate) {
        fromDate = startDate;
        toDate = stopDate;
    }
    public Batchjob_DFRUpdateFields(boolean failure) {
        forceFailure = failure;
    }

    public Batchjob_DFRUpdateFields() {
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        if(forceFailure){
            throw new CustomDFRUpdateFieldsException(CUSTOM_EXCEPTION_MESSAGE);
        } 
        RingCentralVariousSettings__c settings = RingCentralVariousSettings__c.getOrgDefaults();
        Boolean isDFRIncluded = settings.DFRUpdateFields_isDFRIncluded__c != null ? settings.DFRUpdateFields_isDFRIncluded__c : true;
        Boolean isLeadIncluded = settings.DFRUpdateFields_isLeadIncluded__c != null ? settings.DFRUpdateFields_isLeadIncluded__c : false;
        Boolean isContactIncluded = settings.DFRUpdateFields_isContactIncluded__c != null ? settings.DFRUpdateFields_isContactIncluded__c : false;
        Boolean isAccountIncluded = settings.DFRUpdateFields_isAccountIncluded__c != null ? settings.DFRUpdateFields_isAccountIncluded__c : false;
        if (fromDate != null && toDate != null) {
            return new DemandFunnelSelector()
                .selectDFRForUpdateFieldsBetweenDates(new List<Object>{ fromDate, toDate },
                                    isDFRIncluded,
                                    isLeadIncluded,
                                    isContactIncluded,
                                    isAccountIncluded)
                .executeQueryLocator();
        } else {   
            Integer daysToSubstract = (Integer) ((settings != null && settings.Number_of_days_to_update_DFR_fields__c > 0) ? settings.Number_of_days_to_update_DFR_fields__c * -1 : -1);

            Datetime fromDate = Datetime.newInstance(Date.today().addDays(daysToSubstract), Time.newInstance(0, 0, 0, 0));

            return new DemandFunnelSelector()
                .selectDFRForUpdateFields(new List<Object>{ fromDate },
                                    isDFRIncluded,
                                    isLeadIncluded,
                                    isContactIncluded,
                                    isAccountIncluded)
                .executeQueryLocator();
        }
    }

    public void execute(Database.BatchableContext ctx, List<sObject> dfrs) {
        Map<Id, Demand_Funnel__c> dfrsWithSMEmployeesUpdated = new Map<Id, Demand_Funnel__c>(DG_DFR_Class.getDFRsWithUpdatedSMEmployeesField((List<Demand_Funnel__c>) dfrs));
        Map<Id, Demand_Funnel__c> dfrsWithIntendedBrandUpdated = new Map<Id, Demand_Funnel__c>(DemandFunnelTriggerHelper.getDFRsWithUpdatedIntendedBrandField((List<Demand_Funnel__c>) dfrs));
        Map<Id, Demand_Funnel__c> dfrsWithAccountUpdated = new Map<Id, Demand_Funnel__c>(DG_DFR_Class.getDFRsWithupdatedAccountField((List<Demand_Funnel__c>) dfrs));

        List<Demand_Funnel__c> dfrsToUpdate = DemandFunnelPlatEvents.getDFRListToUpdate(
            dfrsWithAccountUpdated, 
            dfrsWithIntendedBrandUpdated, 
            dfrsWithSMEmployeesUpdated
        );

        if (!dfrsToUpdate.isEmpty()) {
            update dfrsToUpdate;
        }
    }

    public void finish(Database.BatchableContext BC) {
        RingCentralVariousSettings__c settings = RingCentralVariousSettings__c.getOrgDefaults();
        Boolean useCustomSetting = settings.DFRUpdateFields_useCustomSetting__c != null ? settings.DFRUpdateFields_useCustomSetting__c : false;
        if(!useCustomSetting){            
            Batchjob_DFRUpdateFields nextBatchjob_DFRUpdateFields;
            if (fromDate != null && toDate != null) {
                nextBatchjob_DFRUpdateFields = new Batchjob_DFRUpdateFields(fromDate,toDate);
            } else {
                nextBatchjob_DFRUpdateFields = new Batchjob_DFRUpdateFields();
            }
            
            
            if(settings.DFRUpdateFields_isDFRIncluded__c) {
                settings.DFRUpdateFields_isDFRIncluded__c = false;
                settings.DFRUpdateFields_isLeadIncluded__c = true;
                settings.DFRUpdateFields_isContactIncluded__c = false;
                settings.DFRUpdateFields_isAccountIncluded__c = false;
                update settings;
                Database.executeBatch(nextBatchjob_DFRUpdateFields);
            } else if(settings.DFRUpdateFields_isLeadIncluded__c) {
                settings.DFRUpdateFields_isDFRIncluded__c = false;
                settings.DFRUpdateFields_isLeadIncluded__c = false;
                settings.DFRUpdateFields_isContactIncluded__c = true;
                settings.DFRUpdateFields_isAccountIncluded__c = false;
                update settings;
                Database.executeBatch(nextBatchjob_DFRUpdateFields);
            } else if(settings.DFRUpdateFields_isContactIncluded__c) {
                settings.DFRUpdateFields_isDFRIncluded__c = false;
                settings.DFRUpdateFields_isLeadIncluded__c = false;
                settings.DFRUpdateFields_isContactIncluded__c = false;
                settings.DFRUpdateFields_isAccountIncluded__c = true;
                update settings;
                Database.executeBatch(nextBatchjob_DFRUpdateFields);
            } else if(settings.DFRUpdateFields_isAccountIncluded__c) {
                settings.DFRUpdateFields_isDFRIncluded__c = true;
                settings.DFRUpdateFields_isLeadIncluded__c = false;
                settings.DFRUpdateFields_isContactIncluded__c = false;
                settings.DFRUpdateFields_isAccountIncluded__c = false;
                update settings;
            }   
        }
    }
}