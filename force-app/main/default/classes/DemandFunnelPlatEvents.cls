public class DemandFunnelPlatEvents {

    public final static String ACCOUNT_FIELD = Demand_Funnel__c.Account__c.getDescribe().getName();
    public final static String INTENDED_BRAND_FIELD = Demand_Funnel__c.Intended_Brand__c.getDescribe().getName();
    public final static String SM_EMPLOYEES_FIELD = Demand_Funnel__c.SM_Employees__c.getDescribe().getName();

    public static void dfrCreateLeadTrigger(List<DFR_CreateLead__e> events) {
        Set<Id> leadIds = new Set<Id>();
        List<Object> bindings = new List<Object>();
        List<Asset_Touch__c> assetTouchList = new List<Asset_Touch__c>();
        List<Lead> leadsforDFR;
        try {
            for (DFR_CreateLead__e event : events) {
                if (!event.Is_Test__c) {
                    leadIds.add((Id) event.Leads__c);
                    if (event.Asset_Touchs__c != null) {
                        assetTouchList.addAll(
                            (List<Asset_Touch__c>) JSON.deserialize(event.Asset_Touchs__c, List<Asset_Touch__c>.class)
                        );
                    }
                }
            }
            if (leadIds.size() > 0) {
                bindings.add(leadIds);
                leadsforDFR = new LeadSelector()
                    .selectLeadsByIds(bindings)
                    .selectFields(getAllDFRLeadFields())
                    .executeQuery();
                DG_DFR_Class.CreateLeadDFR(leadsforDFR);
                if (!assetTouchList.isEmpty()) {
                    AssetAssignmentHelper.processAndUpsertAssetTouchesForInsertion(assetTouchList, 'Lead');
                }
            }
        } catch (Exception e) {
            if (EventBus.TriggerContext.currentContext().retries < 4) {
                throw new EventBus.RetryableException('DFR Create Lead process FAILED, Retrying...');
            } else {
                DG_DFR_Class.dfrSaveException(e, null, leadsforDFR, null, null);
            }
        }
    }

    public static void dfrAfterUpdateTrigger(List<DFR_AfterUpdate__e> events) {
        List<Asset_Touch__c> assetTouchList = new List<Asset_Touch__c>();
        Map<Id, Lead> mapOld = new Map<Id, Lead>();
        List<Lead> leadsforDFR;
        try {
            for (DFR_AfterUpdate__e event : events) {
                if (!event.Is_Test__c) {
                    mapOld.put(
                        event.Id__c,
                        new Lead(
                            FirstName = event.FirstName__c,
                            LastName = event.LastName__c,
                            Status = event.Status__c,
                            OwnerId = event.OwnerId__c,
                            Routing_Reason__c = event.Routing_Reason__c
                        )
                    );
                    if (event.AssetTouch__c != null) {
                        assetTouchList.addAll(
                            (List<Asset_Touch__c>) JSON.deserialize(event.AssetTouch__c, List<Asset_Touch__c>.class)
                        );
                    }
                }
            }
            if (mapOld.size() > 0) {
                List<Object> bindings = new List<Object>();
                bindings.add(mapOld.keySet());
                leadsforDFR = new LeadSelector()
                    .selectLeadsByIds(bindings)
                    .selectFields(getAllDFRLeadFields())
                    .executeQuery();

                DG_DFR_Class.DFR_UpdateTQLOnOwnerChange(leadsforDFR, mapOld);
                DG_DFR_Class.DFR_LeadStatusChange(leadsforDFR, mapOld);
                DG_DFR_Class.DFR_ChangeLeadOwner(leadsforDFR, mapOld);
                DG_DFR_Class.MQLHandOff_OnUpdate(leadsforDFR, mapOld);
                DG_DFR_Class.SALHandOff_OnUpdate(leadsforDFR, mapOld);
                DG_DFR_Class.updateMQLOwnerFieldsAfterLeanData(new Map<Id, Lead>(leadsforDFR), mapOld);
                if (!assetTouchList.isEmpty()) {
                    AssetAssignmentHelper.processAndUpsertAssetTouchesForInsertion(assetTouchList, 'Lead');
                }
            }
        } catch (Exception e) {
            if (EventBus.TriggerContext.currentContext().retries < 4) {
                throw new EventBus.RetryableException('DFR Update Lead process still fails.');
            } else {
                DG_DFR_Class.dfrSaveException(e, null, leadsforDFR, null, null);
            }
        }
    }

    public static Set<String> getAllDFRLeadFields() {
        return new Set<String>{
            'Id',
            'OwnerId',
            'RecordTypeId',
            'LeadSource',
            'Status',
            'SDR_BDR_Owned__c',
            'Duplicate_Lead__c',
            'isConverted',
            'Routing_Reason__c',
            'FirstName',
            'LastName',
            'AID__c',
            'Lead_Entry_Source__c',
            'PID__c',
            'BMID__c',
            'Demographic_Score__c',
            'Most_Recent_Campaign__c',
            'Lead_Score__c',
            'Behavior_Score__c',
            'Time_Frame__c',
            'LeadSource',
            'Most_Recent_Asset__c',
            'Form_URL__c',
            'Email',
            'ConvertedOpportunityId',
            'Assignment_Source_hidden__c'
        };
    }

    public static void updateFieldValue(List<DFR_Update_Field__e> events) {
        try {
            Map<String, Set<Id>> setDfrIdToUpdateField = new Map<String, Set<Id>>{
                ACCOUNT_FIELD => new Set<Id>(),
                INTENDED_BRAND_FIELD => new Set<Id>(),
                SM_EMPLOYEES_FIELD => new Set<Id>()
            };

            for (DFR_Update_Field__e event : events) {
                //Fields__c can be: Account__c;Intended_Brand__c;SM_Employees__c
                for (String field : event.Fields__c.split(';')) {
                    setDfrIdToUpdateField.get(field).add((Id) event.Id__c);
                }
            }

            Map<Id, Demand_Funnel__c> dfrMapWithAccountUpdated = new Map<Id, Demand_Funnel__c>(
                DG_DFR_Class.getDFRsWithUpdatedAccountField(setDfrIdToUpdateField.get(ACCOUNT_FIELD))
            );

            Map<Id, Demand_Funnel__c> dfrMapWithIntendedBrandUpdated = new Map<Id, Demand_Funnel__c>(
                DemandFunnelTriggerHelper.getDFRsWithUpdatedIntendedBrandField(setDfrIdToUpdateField.get(INTENDED_BRAND_FIELD))
            );

            Map<Id, Demand_Funnel__c> dfrMapWithSMEmployeesUpdated = new Map<Id, Demand_Funnel__c>(
                DG_DFR_Class.getDFRsWithUpdatedSMEmployeesField(setDfrIdToUpdateField.get(SM_EMPLOYEES_FIELD))
            );

            List<Demand_Funnel__c> dfrsToUpdate = getDFRListToUpdate(
                dfrMapWithAccountUpdated,
                dfrMapWithIntendedBrandUpdated,
                dfrMapWithSMEmployeesUpdated
            );

            if (!dfrsToUpdate.isEmpty()) {
                update dfrsToUpdate;
            }
        } catch (Exception e) {
            if (EventBus.TriggerContext.currentContext().retries < 4) {
                throw new EventBus.RetryableException('DFR Update Field Value still fails.');
            } else {
                ExceptionHelper.createExceptionAndNotificacionHistory(e, events, 'Exception History');
            }
        }
    }

    /**
     * - dfrMapWithAccountUpdated -> A map of DFRS with the Account field updated.
     * - dfrMapWithIntendedBrandUpdated -> A map of DFRS with the Account field updated.
     * - dfrMapWithSMEmployeesUpdated -> A map of DFRS with the Account field updated.
     * @description: agroup all the dfr with the field updated in a unique list.
     * @returns: A List<Demand_Funnel__c> where each DFR have the fields updated.
     */
    public static List<Demand_Funnel__c> getDFRListToUpdate(
        Map<Id, Demand_Funnel__c> dfrMapWithAccountUpdated,
        Map<Id, Demand_Funnel__c> dfrMapWithIntendedBrandUpdated,
        Map<Id, Demand_Funnel__c> dfrMapWithSMEmployeesUpdated
    ) {
        Map<Id, Demand_Funnel__c> dfrsToUpdate = new Map<Id, Demand_Funnel__c>();
        for (Demand_Funnel__c dfr : dfrMapWithAccountUpdated.values()) {

            if (dfrMapWithIntendedBrandUpdated.containsKey(dfr.Id)) {
                dfr.Intended_Brand__c = dfrMapWithIntendedBrandUpdated.get(dfr.Id).Intended_Brand__c;
                dfrMapWithIntendedBrandUpdated.remove(dfr.Id);
            }
            if (dfrMapWithSMEmployeesUpdated.containsKey(dfr.Id)) {
                dfr.SM_Employees__c = dfrMapWithSMEmployeesUpdated.get(dfr.Id).SM_Employees__c;
                dfrMapWithSMEmployeesUpdated.remove(dfr.Id);
            }

            dfrsToUpdate.put(dfr.Id, dfr);
        }

        for (Demand_Funnel__c dfr : dfrMapWithIntendedBrandUpdated.values()) {

            Demand_Funnel__c dfrToUpdate = dfrsToUpdate.containsKey(dfr.Id) ? dfrsToUpdate.get(dfr.Id) : dfr;

            if (dfrMapWithSMEmployeesUpdated.containsKey(dfrToUpdate.Id)) {
                dfrToUpdate.SM_Employees__c = dfrMapWithSMEmployeesUpdated.get(dfrToUpdate.Id).SM_Employees__c;
                dfrMapWithSMEmployeesUpdated.remove(dfr.Id);
            }

            dfrsToUpdate.put(dfr.Id, dfrToUpdate);
        }

        if (!dfrMapWithSMEmployeesUpdated.isEmpty()) {
            dfrsToUpdate.putAll(dfrMapWithSMEmployeesUpdated);
        }

        return dfrsToUpdate.values();
    }
}