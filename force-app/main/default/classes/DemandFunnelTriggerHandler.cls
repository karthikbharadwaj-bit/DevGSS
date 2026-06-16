public with sharing class DemandFunnelTriggerHandler {
    public class BrandPartnerPopulationHandler extends BrandPartnerFieldPopulationHandler {
        public BrandPartnerPopulationHandler() {
            super(Demand_Funnel__c.sObjectType);
        }
    }

    public class DFRFieldTrackingSettings implements Comparable {
        public DFR_Field_Tracking__mdt record;

        DFRFieldTrackingSettings(DFR_Field_Tracking__mdt rec) {
            record = rec;
        }
        public Integer compareTo(Object o) {
            DFRFieldTrackingSettings s = (DFRFieldTrackingSettings) o;

            Integer orderCompared = (Integer) Math.signum(record.Field_order__c - s.record.Field_order__c);
            Integer masterLabelCompared = orderCompared != null ? orderCompared : record.MasterLabel.compareTo(s.record.MasterLabel);

            return masterLabelCompared;
        }
    }

    public class DFRFieldTracking extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Exception_And_Notification_History__c> listHistory = new List<Exception_And_Notification_History__c>();
            Id historyRTId = Schema.SObjectType.Exception_And_Notification_History__c.getRecordTypeInfosByName()
                .get('DFR Field Tracking')
                .getRecordTypeId();
            List<DFRFieldTrackingSettings> fieldTrackingSettings = new List<DFRFieldTrackingSettings>();
            for (DFR_Field_Tracking__mdt ft: DFR_Field_Tracking__mdt.getAll().values()) {
                fieldTrackingSettings.add(new DFRFieldTrackingSettings(ft));
            }

            fieldTrackingSettings.sort();

            List<DFR_Field_Tracking__mdt> listFieldTracking = new List<DFR_Field_Tracking__mdt>();
            for (DFRFieldTrackingSettings fts: fieldTrackingSettings) {
                listFieldTracking.add(fts.record);
            }

            String fieldChanges;

            for (Demand_Funnel__c dfr : (List<Demand_Funnel__c>) Trigger.new) {
                Demand_Funnel__c oldDfr = (Demand_Funnel__c) Trigger.oldMap.get(dfr.Id);

                fieldChanges = '';

                for (DFR_Field_Tracking__mdt field : listFieldTracking) {
                    try {
                        Object newValue = dfr.get(field.Field_API_Name__c);
                        Object oldValue = oldDfr.get(field.Field_API_Name__c);
                        if (newValue != oldValue) {
                            if (field.isDateTime__c) {
                                oldValue = oldValue != null ? ((Datetime) oldValue).format() : oldValue;
                                newValue = newValue != null ? ((Datetime) newValue).format() : newValue;
                            }
                            fieldChanges +=
                                '<b>' +
                                field.MasterLabel +
                                '</b> changed from <b>' +
                                oldValue +
                                '</b> to <b>' +
                                newValue +
                                '</b><br>';
                        }
                    } catch (Exception e) {
                        DG_DFR_Class.dfrSaveException(e, null, null, null, null);
                    }
                }

                if (!String.isEmpty(fieldChanges)) {
                    Exception_And_Notification_History__c newHistory = (Exception_And_Notification_History__c) new SObjectBuilder(
                            Exception_And_Notification_History__c.SObjectType
                        )
                        .setFields(
                            new Map<SObjectField, Object>{
                                Exception_And_Notification_History__c.RecordTypeId => historyRTId,
                                Exception_And_Notification_History__c.Affected_record_ID__c => dfr.Id,
                                Exception_And_Notification_History__c.Object_Type__c => 'Demand_Funnel__c',
                                Exception_And_Notification_History__c.Field_Changes__c => fieldChanges
                            }
                        )
                        .build()
                        .getRecord();
                    listHistory.add(newHistory);
                }
            }
            if (!listHistory.isEmpty()) {
                try {
                    insert listHistory;
                } catch (Exception e) {
                    DG_DFR_Class.dfrSaveException(e, null, null, null, null);
                }
            }
        }
    }
    
    public class FieldPopulation extends Triggers.TriggerHandlerBase {
        override public void handle() {
            try {
                if (Trigger.isInsert) {
                    DemandFunnelTriggerHelper.populateAccountField((List<Demand_Funnel__c>) Trigger.new);
                    DemandFunnelTriggerHelper.populateIntendedBrandField((List<Demand_Funnel__c>) Trigger.new);
                    DemandFunnelTriggerHelper.populateSMEmployeeField((List<Demand_Funnel__c>) Trigger.new);
                } else if (Trigger.isUpdate) {
                    List<Demand_Funnel__c> dfrsToUpdateIntendedBrandField = new List<Demand_Funnel__c>();
                    List<Demand_Funnel__c> dfrsToUpdateAccount = new List<Demand_Funnel__c>();
                    List<Demand_Funnel__c> dfrsForSMEmployeePopulation = new List<Demand_Funnel__c>();

                    for (Demand_Funnel__c dfr : (List<Demand_Funnel__c>) Trigger.new) {

                        dfr.Brand_Partner__c = (dfr.Brand__c == RingCentralHelper.BRAND_AVAYA) ? 'Avaya': 'None';

                        Boolean opportunityFieldHasChanged = isChangedField(dfr, Demand_Funnel__c.Opportunity__c);
                        Boolean accountFieldHasChanged = isChangedField(dfr, Demand_Funnel__c.Account__c);
                        Boolean leadFieldHasChanged = isChangedField(dfr, Demand_Funnel__c.Lead__c);
                        Boolean prospectLeadSourceFieldHasChanged = isChangedField(dfr, Demand_Funnel__c.Prospect_Lead_Source__c);
                        Boolean contactFieldHasChanged = isChangedField(dfr, Demand_Funnel__c.Contact__c);

                        if (opportunityFieldHasChanged 
                            || accountFieldHasChanged 
                            || leadFieldHasChanged 
                            || prospectLeadSourceFieldHasChanged
                        ) {
                            dfrsToUpdateIntendedBrandField.add(dfr);
                        }

                        if (opportunityFieldHasChanged || contactFieldHasChanged || leadFieldHasChanged) {
                            dfrsToUpdateAccount.add(dfr);
                        }
                        
                        if (opportunityFieldHasChanged || accountFieldHasChanged || leadFieldHasChanged) {
                            dfrsForSMEmployeePopulation.add(dfr);
                        }
                    }

                    if (!dfrsToUpdateAccount.isEmpty()) {
                        DemandFunnelTriggerHelper.populateAccountField(dfrsToUpdateAccount);
                    }

                    if (!dfrsToUpdateIntendedBrandField.isEmpty()) {
                        DemandFunnelTriggerHelper.populateIntendedBrandField(dfrsToUpdateIntendedBrandField);
                    }
                    
                    if (!dfrsForSMEmployeePopulation.isEmpty()) {
                        DemandFunnelTriggerHelper.populateSMEmployeeField(dfrsForSMEmployeePopulation);
                    }
                }
            } catch (Exception e) {
                ExceptionHelper.createExceptionAndNotificacionHistory(e, (List<Demand_Funnel__c>) Trigger.new, 'DFR Exception Log');
            }
        }
    }
}