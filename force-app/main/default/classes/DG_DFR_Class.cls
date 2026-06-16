public without sharing class DG_DFR_Class {
    public static boolean firstRun = true;
    public static boolean isLeadInsert = false;
    public static boolean LeadAfterUpdate_FirstRun = true;
    public static boolean byPassDFRContact = false;
    public static boolean LeadAfterConvert_FirstRun = true;
    public static boolean ContactAfterUpdate_FirstRun = true;
    public static Boolean isContactCreatedByConversion = true;
    public static Boolean isOpportunityCreatedByConversion = true;
    private static String dfrExceptionMessage = '';
    private static String dfrExceptionRecords = '';
    private static String dfrExceptionObject = '';
    public static final String REROUTED_MARKETO_MQL_STATUS_UPDATE = '[ReRouted] Due to Marketo MQL status update';
    public static final String DFRSQL = 'SQL';
    public static final String DFRSAL = 'SAL';
    public static final String DFRTAL = 'TAL';
    public static final String DFRTQL = 'TQL';
    public static final String DFRMQL = 'MQL';
    public static final String DFRSDR = 'SDR';
    public static final String DFRBDR = 'BDR';
    public static final String DFRPROSPECT = 'Prospect';
    public static final String DFRRENEW = 'Re-New';
    public static final String DFRDOWNGRADED = 'Downgraded';
    public static final String STATUS_CUSTOMER = '4. Customer';
    public static final String STATUS_DOWNGRADED = '0. Downgraded';
    public static final String STATUS_CALLOUT = '1.5 Call Out';
    public static final String STATUS_CONTACTED = '2. Contacted';
    public static final String STATUS_RENEW = '.5 Re-New';
    public static final String STATUS_NEW = '1. New';
    public static final String STATUS_CALL_OUT = '1.5 Call Out';
    public static final String STATUS_OPEN = 'X. Open';

    public static Map<String, String> mapDFRSystemUsers = DG_DFR_Class_Helper.getDFRSystemUsers();
    public static List<String> dfrLeadRType = DG_DFR_Class_Helper.getDFRLeadRType();
    public static List<String> dfrOppRType = DG_DFR_Class_Helper.getDFROppRType();
    public static Set<String> excludedLS = DG_DFR_Class_Helper.getExcludedLeadSources();
    public static Map<Id, String> mapRTId = DG_DFR_Class_Helper.getMapOfRecordTypes(dfrLeadRType);
    public static Map<String, String> mapStatusToStage = DG_DFR_Class_Helper.getDFRStatusToStage();
    public static Map<String, String> mapContactStatusToStage = DG_DFR_Class_Helper.getDFRContactStatusToStage();
    public static Map<String, String> mapContactTypeToFunnelType = DG_DFR_Class_Helper.getContactTypeToFunnelType();

    public static void createLeadDFR(List<Lead> lds) {
        createLeadDFR(lds, new Map<Id, String>());
    }
    public static void createLeadDFR(List<Lead> lds, Map<Id, String> oldStagesMap) {
        Map<Lead, String> mapLeadToStage = new Map<Lead, String>();
        for (Lead ld : lds) {
            if (
                ld.Lead_Brand_Name__c != null &&
                System.Label.BizMerge_Brand_Exclusion_List != null &&
                System.Label.BizMerge_Brand_Exclusion_List.contains(ld.Lead_Brand_Name__c)
            ) {
                continue;
            }

            if (mapRTId.containsKey(ld.RecordTypeId) && !ld.Duplicate_Lead__c && !excludedLS.contains(ld.LeadSource)) {
                String stage;
                if (ld.SDR_BDR_Owned__c == false || mapStatusToStage.get(ld.Status) <> DG_DFR_Class.DFRSAL) {
                    if (mapStatusToStage.containsKey(ld.Status)) {
                        stage = mapStatusToStage.get(ld.Status);
                    }
                } else {
                    stage = DG_DFR_Class.DFRTAL;
                }
                if (stage <> null) {
                    mapLeadToStage.put(ld, stage);
                }
            }
        }
        List<Lead> leadList = new List<Lead>();
        Set<Id> ownerIds = new Set<Id>();
        try {
            for (Lead ld : mapLeadToStage.keySet()) {
                leadList.add(ld);
                ownerIds.add(ld.OwnerId);
            }
            if (!mapLeadToStage.isEmpty()) {
                List<Demand_Funnel__c> dfrsToInsert = new List<Demand_Funnel__c>();
                Map<Id, User> mapUsers = DG_DFR_Class_Helper.getUsersById(ownerIds);
                Map<Id, QueueSobject> mapQueue = DG_DFR_Class_Helper.getMapOfQueues(ownerIds, 'Lead');

                for (Lead newLead : mapLeadToStage.keySet()) {
                    String stage = mapLeadToStage.get(newLead);
                    Demand_Funnel__c dfr = new Demand_Funnel__c();
                    String leadOwnerId = newLead.OwnerId;
                    String leadOwnerName;
                    User leadOwner = new User();
                    if (mapUsers.containsKey(newLead.OwnerId)) {
                        leadOwnerName = mapUsers.get(newLead.OwnerId).Name;
                        leadOwner = mapUsers.get(newLead.OwnerId);
                    } else if (mapQueue.containsKey(newLead.OwnerId)) {
                        leadOwnerName = mapQueue.get(newLead.OwnerId).Queue.Name;
                    }
                    dfr.DFR_Funnel_Type__c = 'Acquisition';
                    if (stage == DFRPROSPECT) {
                        dfr = DG_DFR_Class_Helper.prospectOnCreationForLead(
                            dfr,
                            newLead,
                            leadOwner,
                            leadOwnerName,
                            leadOwnerId
                        );
                        dfr.Pre_Opportunity_Status__c = 'Prospect';
                        dfrsToInsert.add(dfr);
                    } else if (stage == DFRMQL || stage == DFRRENEW) {
                        dfr = DG_DFR_Class_Helper.prospectBackfillForLead(
                            dfr,
                            newLead,
                            leadOwner,
                            leadOwnerName,
                            leadOwnerId
                        );
                        dfr = DG_DFR_Class_Helper.mqlOnCreationForLead(
                            dfr,
                            newLead,
                            leadOwner,
                            leadOwnerName,
                            leadOwnerId
                        );
                        dfr.Pre_Opportunity_Status__c = 'MQL';
                        if (mapQueue.containsKey(newLead.OwnerId)) {
                            dfr.MQL_Queue_Name__c = mapQueue.get(newLead.OwnerId).Queue.Name;
                        }
                        if (
                            stage == DFRRENEW ||
                            (oldStagesMap.get(newLead.Id) != null &&
                            oldStagesMap.get(newLead.Id).equals(STATUS_DOWNGRADED))
                        ) {
                            dfr.MQL_Type__c = 'Re-New';
                        } else {
                            dfr.MQL_Type__c = 'New';
                        }
                        dfrsToInsert.add(dfr);
                    } else if (stage == DFRSAL || stage == DFRTAL) {
                        dfr = DG_DFR_Class_Helper.prospectBackfillForLead(
                            dfr,
                            newLead,
                            leadOwner,
                            leadOwnerName,
                            leadOwnerId
                        );
                        dfr = DG_DFR_Class_Helper.mqlBackfillForLead(
                            dfr,
                            newLead,
                            leadOwner,
                            leadOwnerName,
                            leadOwnerId
                        );
                        if (
                            oldStagesMap.get(newLead.Id) != null &&
                            oldStagesMap.get(newLead.Id).equals(STATUS_DOWNGRADED)
                        ) {
                            dfr.MQL_Type__c = 'Re-New';
                        } else {
                            dfr.MQL_Type__c = 'New';
                        }
                        if (mapQueue.containsKey(newLead.OwnerId)) {
                            DFR.MQL_Queue_Name__c = mapQueue.get(newLead.OwnerId).Queue.Name;
                        }
                        if (stage == DFRSAL && DG_DFR_Class_Helper.backfillTALTQLCheck(dfr) || stage == DFRTAL) {
                            dfr = DG_DFR_Class_Helper.talOnCreationForLead(
                                dfr,
                                newLead,
                                leadOwner,
                                leadOwnerName,
                                leadOwnerId
                            );
                            DFR.Pre_Opportunity_Status__c = 'TAL';
                        } else {
                            dfr = DG_DFR_Class_Helper.salOnCreationForLead(
                                dfr,
                                newLead,
                                leadOwner,
                                leadOwnerName,
                                leadOwnerId
                            );
                            dfr.Pre_Opportunity_Status__c = 'SAL';
                            if (
                                leadOwner != null &&
                                (leadOwner.Profile.Name != null && !leadOwner.Profile.Name.contains('SDR') ||
                                leadOwner.Profile.Name == null)
                            ) {
                                DFR.SAL_Handoff_Date__c = datetime.now();
                                DFR.SAL_Handoff_Owner__c = leadOwnerName;
                                DFR.SAL_Handoff_Owner_Role__c = leadOwner.UserRoleName__c;
                            }
                        }
                        dfrsToInsert.add(dfr);
                    }
                }
                if (!dfrsToInsert.isEmpty()) {
                    insert dfrsToInsert;
                }
            }
        } catch (Exception e) {
            if (lds != null && lds.size() > 25) {
                throw e;
            } else {
                dfrSaveException(e, null, lds, null, null);
            }
        }
    }

    public static void dfr_LeadStatusChange(List<Lead> newLeads, Map<Id, Lead> mapOldLeads) {
        List<Lead> listLead = new List<Lead>();
        Set<Id> newLeadIds = new Set<Id>();
        Set<Id> newLeadOwnerIds = new Set<Id>();
        Map<Id, String> mapLeadIdToStage = new Map<Id, String>();
        Map<Id, Demand_Funnel__c> dfrList = DG_DFR_Class_Helper.getDFRMap(new Map<Id, Lead>(newLeads).keyset());
        try {
            List<Demand_Funnel__c> dfrUpdate = new List<Demand_Funnel__c>();
            List<Demand_Funnel__c> dfrInsert = new List<Demand_Funnel__c>();
            List<Lead> leadsToCallCreateNewDFR = new List<Lead>();
            for (Lead newLead : newLeads) {
                Lead oldLead = mapOldLeads.get(newLead.Id);
                if (
                    mapRTId.containsKey(newLead.RecordTypeId) &&
                    !newLead.Duplicate_Lead__c &&
                    !newLead.isConverted &&
                    newLead.Status != oldLead.Status
                ) {
                    String stage;
                    if (DG_DFR_Class_Helper.isLeadGoingToTALTQL(newLead, dfrList)) {
                        stage = DFRTAL;
                    } else if (
                        mapStatusToStage.containsKey(newLead.Status) && mapStatusToStage.containsKey(oldLead.Status)
                    ) {
                        String oldStage = mapStatusToStage.get(oldLead.Status);
                        String newStage = mapStatusToStage.get(newLead.Status);
                        if (oldStage != newStage) {
                            stage = newStage;
                        }
                    }
                    if (!String.IsBlank(stage)) {
                        listLead.add(newLead);
                        newLeadIds.add(newLead.id);
                        newLeadOwnerIds.add(newLead.OwnerId);
                        mapLeadIdToStage.put(newLead.Id, stage);
                    }
                }
            }
            if (!newLeadIds.isEmpty()) {
                Map<Id, User> mapUsers = DG_DFR_Class_Helper.getUsersById(newLeadOwnerIds);
                Map<Id, QueueSobject> mapQueue = DG_DFR_Class_Helper.getMapOfQueues(newLeadOwnerIds, 'Lead');
                Map<Id, Demand_Funnel__c> mapLeadIdToDFR = DG_DFR_Class_Helper.getDFRMapForLeadStatusChange(newLeadIds);
                for (Lead newLead : listLead) {
                    String newStage = mapLeadIdToStage.get(newLead.Id);
                    Lead oldLead = mapOldLeads.get(newLead.id);

                    String leadOwnerName;
                    String leadOwnerId = newLead.OwnerId;
                    User owner = new User();

                    if (mapUsers.containsKey(newLead.OwnerId)) {
                        leadOwnerName = mapUsers.get(newLead.OwnerId).Name;
                        owner = mapUsers.get(newLead.OwnerId);
                    } else if (mapQueue.containsKey(newLead.OwnerId)) {
                        leadOwnerName = mapQueue.get(newLead.OwnerId).Queue.Name;
                    }
                    String oldStatus = String.isBlank(oldLead.Status) ? '' : oldLead.Status;
                    if (mapLeadIdToDFR.containsKey(newLead.id)) {
                        Demand_Funnel__c dfr = mapLeadIdToDFR.get(newLead.id);
                        String oldStageName = dfr.Pre_Opportunity_Status__c != null ? dfr.Pre_Opportunity_Status__c : null;

                        if (oldStatus.equals(STATUS_OPEN)) {
                            if (newStage.equals(DFRDOWNGRADED)) {
                                dfr = DG_DFR_Class_Helper.eolStatusChangeForLead(
                                    dfr,
                                    newLead,
                                    owner,
                                    oldStageName,
                                    leadOwnerName,
                                    leadOwnerId
                                );
                                dfr.Prospect_DateTime_Exited__c = Datetime.now();
                                dfr.Prospect_Exited_To__c = 'Downgraded';
                            } else if (newStage.equals(DFRMQL) || newStage.equals(DFRRENEW)) {
                                dfr = DG_DFR_Class_Helper.mqlStatusChangeForLead(
                                    dfr,
                                    newLead,
                                    owner,
                                    oldStageName,
                                    leadOwnerName,
                                    leadOwnerId
                                );
                                dfr.Prospect_Exited_To__c = 'MQL';
                                dfr.Prospect_DateTime_Exited__c = Datetime.now();
                                dfr.Pre_Opportunity_Status__c = 'MQL';
                                if (newStage.equals(DFRRENEW)) {
                                    dfr.MQL_Type__c = 'Re-New';
                                } else {
                                    dfr.MQL_Type__c = 'New';
                                }
                            } else if (newStage.equals(DFRSAL)) {
                                dfr = DG_DFR_Class_Helper.mqlBackfillForLead(
                                    dfr,
                                    newLead,
                                    owner,
                                    leadOwnerName,
                                    leadOwnerId
                                );
                                if (DG_DFR_Class_Helper.backfillTALTQLCheck(dfr)) {
                                    dfr = DG_DFR_Class_Helper.talStatusChangeForLead(
                                        dfr,
                                        newLead,
                                        owner,
                                        oldStageName,
                                        leadOwnerName,
                                        leadOwnerId
                                    );
                                    dfr.Prospect_Exited_To__c = 'TAL';
                                    dfr.Prospect_DateTime_Exited__c = Datetime.now();
                                    dfr.Pre_Opportunity_Status__c = 'TAL';
                                } else {
                                    dfr = DG_DFR_Class_Helper.salStatusChangeForLead(
                                        dfr,
                                        newLead,
                                        owner,
                                        oldStageName,
                                        leadOwnerName,
                                        leadOwnerId
                                    );
                                    dfr.Prospect_Exited_To__c = 'SAL';
                                    dfr.Prospect_DateTime_Exited__c = Datetime.now();
                                    dfr.Pre_Opportunity_Status__c = 'SAL';
                                    if (owner != null && owner.profile.Name.containsIgnoreCase('SDR')) {
                                        dfr.SAL_Handoff_Date__c = Datetime.now();
                                        dfr.SAL_Handoff_Owner__c = leadOwnerName;
                                        dfr.SAL_Handoff_Owner_Role__c = owner.UserRoleName__c;
                                    }
                                }
                            }
                        } else if (oldStatus.equals(STATUS_CALL_OUT) || oldStatus.equals(STATUS_CONTACTED)) {
                            if (newStage.equals(DFRDOWNGRADED)) {
                                dfr = DG_DFR_Class_Helper.eolStatusChangeForLead(
                                    dfr,
                                    newLead,
                                    owner,
                                    oldStageName,
                                    leadOwnerName,
                                    leadOwnerId
                                );
                                if (oldStageName.equals(DFRTAL)) {
                                    dfr.EOL_Entered_From__c = 'TAL';
                                    dfr.TAL_DateTime_Exited__c = Datetime.now();
                                    dfr.TAL_Exited_To__c = 'Downgraded';
                                } else {
                                    dfr.EOL_Entered_From__c = 'SAL';
                                    dfr.SAL_DateTime_Exited__c = Datetime.now();
                                    dfr.SAL_Exited_To__c = 'Downgraded';
                                }
                            }
                        } else if (oldStatus.equals(STATUS_RENEW) || oldStatus.equals(STATUS_NEW)) {
                            if (newStage.equals(DFRDOWNGRADED)) {
                                dfr = DG_DFR_Class_Helper.eolStatusChangeForLead(
                                    dfr,
                                    newLead,
                                    owner,
                                    oldStageName,
                                    leadOwnerName,
                                    leadOwnerId
                                );
                                dfr.MQL_DateTime_Exited__c = Datetime.now();
                                dfr.MQL_Exited_To__c = 'Downgraded';
                            } else if (newStage.equals(DFRSAL) || newStage.equals(DFRTAL)) {
                                if (DG_DFR_Class_Helper.backfillTALTQLCheck(dfr)) {
                                    dfr = DG_DFR_Class_Helper.talStatusChangeForLead(
                                        dfr,
                                        newLead,
                                        owner,
                                        oldStageName,
                                        leadOwnerName,
                                        leadOwnerId
                                    );
                                    dfr.MQL_Exited_To__c = 'TAL';
                                    dfr.MQL_DateTime_Exited__c = Datetime.now();
                                    dfr.Pre_Opportunity_Status__c = 'TAL';
                                } else {
                                    dfr = DG_DFR_Class_Helper.salStatusChangeForLead(
                                        dfr,
                                        newLead,
                                        owner,
                                        oldStageName,
                                        leadOwnerName,
                                        leadOwnerId
                                    );
                                    dfr.MQL_Exited_To__c = 'SAL';
                                    dfr.MQL_DateTime_Exited__c = Datetime.now();
                                    dfr.Pre_Opportunity_Status__c = 'SAL';
                                    if (owner != null && owner.profile.Name.containsIgnoreCase('SDR')) {
                                        dfr.SAL_Handoff_Date__c = Datetime.now();
                                        dfr.SAL_Handoff_Owner__c = leadOwnerName;
                                        dfr.SAL_Handoff_Owner_Role__c = owner.UserRoleName__c;
                                    }
                                }
                            }
                        }
                        dfrUpdate.add(dfr);
                    } else {
                        if (!excludedLS.contains(newLead.LeadSource)) {
                            Demand_Funnel__c dfr = new Demand_Funnel__c();
                            if (
                                oldStatus.equals(LeadTriggerHelper.LEADSTATUSDOWNGRADED) &&
                                newLead.Status.equals('.5 Re-New')
                            ) {
                                dfr = DG_DFR_Class_Helper.prospectBackfillForLead(
                                    dfr,
                                    newLead,
                                    owner,
                                    leadOwnerName,
                                    leadOwnerId
                                );
                                dfr = DG_DFR_Class_Helper.mqlOnCreationForLead(
                                    dfr,
                                    newLead,
                                    owner,
                                    leadOwnerName,
                                    leadOwnerId
                                );
                                dfr.Pre_Opportunity_Status__c = DFRMQL;
                                dfr.MQL_Type__c = DFRRENEW;
                                dfrInsert.add(dfr);
                            } else {
                                leadsToCallCreateNewDFR.add(newLead);
                            }
                        }
                    }
                }
            }
            if (!DFRInsert.isEmpty()) {
                insert DFRInsert;
            }
            if (!leadsToCallCreateNewDFR.isEmpty()) {
                Map<Id, String> oldStagesMap = DG_DFR_Class_Helper.populateOldStagesMap(
                    leadsToCallCreateNewDFR,
                    mapOldLeads
                );
                createLeadDFR(leadsToCallCreateNewDFR, oldStagesMap);
            }
            if (!dfrUpdate.isEmpty()) {
                update dfrUpdate;
            }
        } catch (Exception e) {
            if (newLeads != null && newLeads.size() > 25) {
                throw e;
            } else {
                dfrSaveException(e, null, newLeads, null, null);
            }
        }
    }

    public static void DFR_ConvertLead(Lead convertedLead) {
        try {
            if (
                mapRTId.containsKey(convertedLead.RecordTypeId) &&
                !convertedLead.Duplicate_Lead__c &&
                (convertedLead.Lead_Brand_Name__c == null ||
                (convertedLead.Lead_Brand_Name__c != null &&
                System.Label.BizMerge_Brand_Exclusion_List != null &&
                !System.Label.BizMerge_Brand_Exclusion_List.contains(convertedLead.Lead_Brand_Name__c)))
            ) {
                List<Demand_Funnel__c> activeDFRS = new DemandFunnelSelector()
                    .selectActiveDFRForConvertLead(new List<Object>{ convertedLead.Id })
                    .executeQuery();
                Opportunity o = new Opportunity();
                Demand_Funnel__c activeDFR = !activeDFRS.isEmpty() ? activeDFRS.get(0) : null;
                String oldStatus;
                String ownerName;
                String ownerId;
                User owner = new User();
                User oppOwner = new User();
                String SQLOwnerName;
                String SQLOwnerId;
                User previousOwner;
                String previousOwnerName;
                String previousOwnerId;

                if (String.isNotBlank(activeDFR?.TAL_Owner_Id__c)) {
                    previousOwnerId = activeDFR.TAL_Owner_Id__c;
                    previousOwnerName = activeDFR.TAL_Owner_Name__c;
                } else if (String.isNotBlank(activeDFR?.MQL_Owner_Id__c)) {
                    previousOwnerId = activeDFR.MQL_Owner_Id__c;
                    previousOwnerName = activeDFR.MQL_Owner_Name__c;
                }
                Set<Id> ownerIdSet = new Set<Id>{ convertedLead.OwnerId };
                if (String.isNotBlank(previousOwnerId)) {
                    ownerIdSet.add(previousOwnerId);
                }

                Map<Id, User> mapUsers = DG_DFR_Class_Helper.getUsersById(ownerIdSet);
                Map<Id, QueueSobject> mapQueue = DG_DFR_Class_Helper.getMapOfQueues(ownerIdSet, 'Lead');

                if (mapUsers.containsKey(convertedLead.OwnerId)) {
                    ownerName = mapUsers.get(convertedLead.OwnerId).Name;
                    ownerId = convertedLead.OwnerId;
                    owner = mapUsers.get(convertedLead.OwnerId);
                } else if (mapQueue.containsKey(convertedLead.OwnerId)) {
                    ownerName = mapQueue.get(convertedLead.OwnerId).Queue.Name;
                    ownerId = mapQueue.get(convertedLead.OwnerId).QueueId;
                }

                if (mapUsers.containsKey(previousOwnerId)) {
                    previousOwner = mapUsers.get(previousOwnerId);
                } else {
                    previousOwner = owner;
                    previousOwnerId = ownerId;
                    previousOwnerName = ownerName;
                }

                if (convertedLead.ConvertedOpportunityId <> null) {
                    o = (Opportunity) new OpportunitySelector()
                        .selectOpportunitiesByIds(new Set<Id>{ convertedLead.ConvertedOpportunityId })
                        .selectFields(
                            new List<String>{ 'Primary_Opportunity_Contact__c', 'OwnerId', 'CreatedDate', 'AccountId' }
                        )
                        .executeQuery()[0];
                    if (UserHelper.isUser(o.OwnerId)) {
                        if(ConvertLead.IS_LEAD_CONVERT_PROCESSING && SettingsHelper.FEATURE_TOGGLE.EnableLeadConversionUsingCache__c){
                            List<User> userList = new List<User>();
                            userList = UserHelper.retrieveUsersWithCache(new Set<Id>{o.OwnerId});
                            oppOwner = userList.isEmpty() ? null : userList[0];
                        }
                        else {
                            oppOwner = (User) new UserSelector()
                            .selectUserForDFRSingle(new List<Object>{ o.OwnerId })
                            .executeQuery()[0];   
                        }
                        SQLOwnerName = oppOwner.Name;
                        SQLOwnerId = oppOwner.Id;
                    } else {
                        for (
                            QueueSobject q : (List<QueueSObject>) new QueueSelector()
                                .selectQueueForDFRBySObjectType(new List<Object>{ 'Opportunities' })
                                .executeQuery()
                        ) {
                            if (o.OwnerId == q.QueueId) {
                                ownerName = q.Queue.Name;
                                ownerId = q.QueueId;
                                break;
                            }
                        }
                    }
                }

                Contact c;
                if (convertedLead.ConvertedContactId <> null) {
                    c = (Contact) new ContactSelector()
                        .selectContactForDFRConvertedLead(new List<String>{ convertedLead.ConvertedContactId })
                        .executeQuery()[0];
                }

                Map<Id, OpportunityContactRole> mapOCR = new Map<Id, OpportunityContactRole>();

                if (convertedLead.RecordTypeId != LeadHelper.RT_ID_SALES_LEADS) {
                    if (convertedLead.ConvertedContactId != null && convertedLead.ConvertedOpportunityId != null) {
                        Set<Id> setOpportunityId = new Set<Id>();
                        setOpportunityId.add(convertedLead.ConvertedOpportunityId);
                        Map<String, Id> mapOpportunityIdContactId = DG_DFR_Class_Helper.getMapOpportunityContactRole(
                            setOpportunityId
                        );
                        if (
                            mapOpportunityIdContactId.containsKey(
                                convertedLead.ConvertedOpportunityId + '~' + convertedLead.ConvertedContactId
                            )
                        ) {
                            Id OCRId = mapOpportunityIdContactId.get(
                                convertedLead.ConvertedOpportunityId + '~' + convertedLead.ConvertedContactId
                            );
                            mapOCR.put(OCRId, new OpportunityContactRole(Id = OCRId, IsPrimary = true));
                        }

                        if (!mapOCR.isEmpty()) {
                            update mapOCR.values();
                        }
                    }
                }

                if (activeDFR != null) {
                    Demand_Funnel__c dfr = activeDFR;

                    if (o?.AccountId != null) {
                        dfr.Account__c = o.AccountId;
                    } else if (c?.AccountId != null) {
                        dfr.Account__c = c.AccountId;
                    } else {
                        dfr.Account__c = convertedLead.ZI_CDP_Account_Id__c;
                    }

                    if (convertedLead.ConvertedContactId != null) {
                        dfr.Contact__c = convertedLead.ConvertedContactId;
                        c.DFR_Status__c = convertedLead.Status;
                        update c;

                        if (String.IsNotBlank(c.Contact_Funnel_Type__c)) {
                            if (mapContactTypeToFunnelType.containsKey(c.Contact_Funnel_Type__c.ToLowerCase())) {
                                dfr.DFR_Funnel_Type__c = mapContactTypeToFunnelType.get(
                                    c.Contact_Funnel_Type__c.ToLowerCase()
                                );
                            }
                        }

                        dfr.isConverted__c = true;
                        dfr.isCustomer__c = c.Customer_Record__c;
                        dfr.IsContactMerge__c = !isContactCreatedByConversion;

                        oldStatus = dfr.Pre_Opportunity_Status__c;

                        if (oldStatus == 'Prospect') {
                            if (dfr.Prospect_Exited_To__c == null) {
                                dfr.Prospect_DateTime_Exited__c = datetime.now();
                                dfr.Prospect_Exited_To__c = 'MQL';
                            }

                            dfr = DG_DFR_Class_Helper.mqlBackfillForLead(dfr, convertedLead, owner, ownerName, ownerId);
                            dfr.MQL_Type__c = convertedLead.Status == '.5 Re-New' ? 'Re-New' : 'New';
                            dfr.MQL_Form_URL__c = c.Form_URL__c;
                            dfr.Prospect_Form_URL__c = c.Form_URL__c;
                        }

                        if (oldStatus == 'Prospect' || oldStatus == 'MQL' || oldStatus == 'Re-New') {
                            dfr.MQL_DateTime_Exited__c = datetime.now();
                            if (DG_DFR_Class_Helper.isBDRSDRNullUserByTeam(dfr.MQL_Owner_Team__c)) {
                                DG_DFR_Class_Helper.TALMasterMappingFromLead(dfr, convertedLead);
                                if (
                                    String.isNotEmpty(convertedLead.ConvertedOpportunityId) &&
                                    DG_DFR_Class_Helper.isBDRSDRNullUserByTeam(oppOwner.Team__c)
                                ) {
                                    dfr = DG_DFR_Class_Helper.TALOwnerMappingFromUser(
                                        dfr,
                                        oppOwner,
                                        SQLOwnerName,
                                        SQLOwnerId
                                    );
                                } else {
                                    dfr = DG_DFR_Class_Helper.TALOwnerMappingFromUser(
                                        dfr,
                                        previousOwner,
                                        previousOwnerName,
                                        previousOwnerId
                                    );
                                }

                                if (dfr.MQL_Exited_To__c == null) {
                                    dfr.MQL_Exited_To__c = 'TAL';
                                    dfr.TAL_Entered_From__c = 'MQL';
                                } else {
                                    dfr.Prospect_Exited_To__c = 'TAL';
                                    dfr.TAL_Entered_From__c = 'Prospect';
                                }
                            } else {
                                if (dfr.MQL_Exited_To__c == null) {
                                    dfr.MQL_Exited_To__c = 'SAL';
                                    dfr.SAL_Entered_From__c = 'MQL';
                                } else {
                                    dfr.Prospect_Exited_To__c = 'SAL';
                                    dfr.SAL_Entered_From__c = 'Prospect';
                                }
                            }
                        }

                        if (
                            oldStatus == 'TAL' ||
                            ((oldStatus == 'Prospect' || oldStatus == 'MQL' || oldStatus == 'Re-New') &&
                            DG_DFR_Class_Helper.isBDRSDRNullUserByTeam(dfr.MQL_Owner_Team__c))
                        ) {
                            DG_DFR_Class_Helper.TQLMasterMappingFromLead(dfr, convertedLead);
                            if (
                                String.isNotEmpty(convertedLead.ConvertedOpportunityId) &&
                                DG_DFR_Class_Helper.isBDRSDRNullUserByTeam(oppOwner.Team__c)
                            ) {
                                dfr = DG_DFR_Class_Helper.TQLOwnerMappingFromUser(
                                    dfr,
                                    oppOwner,
                                    SQLOwnerName,
                                    SQLOwnerId
                                );
                            } else {
                                dfr = DG_DFR_Class_Helper.TQLOwnerMappingFromUser(
                                    dfr,
                                    previousOwner,
                                    previousOwnerName,
                                    previousOwnerId
                                );
                            }
                            dfr.TAL_DateTime_Exited__c = Datetime.now();
                            dfr.TAL_Exited_To__c = 'TQL';
                            dfr.TQL_Exited_To__c = 'SAL';
                            dfr.SAL_Entered_From__c = 'TQL';
                        }

                        if (
                            oldStatus == 'Prospect' ||
                            oldStatus == 'MQL' ||
                            oldStatus == 'Re-New' ||
                            oldStatus == 'TAL'
                        ) {
                            DG_DFR_Class_Helper.SALMasterMappingFromLead(dfr, convertedLead);
                            dfr.SAL_DateTime_Exited__c = Datetime.now();
                            if (String.isNotEmpty(convertedLead.ConvertedOpportunityId)) {
                                dfr = DG_DFR_Class_Helper.SALOwnerMappingFromUser(
                                    dfr,
                                    oppOwner,
                                    SQLOwnerName,
                                    SQLOwnerId
                                );
                            } else {
                                dfr = DG_DFR_Class_Helper.SALOwnerMappingFromUser(dfr, owner, ownerName, ownerId);
                            }
                        } else if (
                            oldStatus == 'SAL' &&
                            DG_DFR_Class_Helper.isBDRSDRNullUserByTeam(dfr.SAL_Owner_Team__c) &&
                            !DG_DFR_Class_Helper.isBDRSDRNullUserByTeam(oppOwner.Team__c)
                        ) {
                            dfr = DG_DFR_Class_Helper.SALOwnerMappingFromUser(dfr, oppOwner, SQLOwnerName, SQLOwnerId);
                        }

                        if (convertedLead.ConvertedOpportunityId != null) {
                            dfr.isPrimary__c = isOpportunityCreatedByConversion;
                            dfr.DFR_Primary_Role__c = true;
                            dfr.Opportunity_Owner_Id__c = ownerId;
                            dfr.Opportunity_Owner_Segment__c = owner.SegmentPicklist__c;
                            dfr.Opportunity_Owner_Territory__c = owner.Upmarket_Territory__c;
                            dfr = DG_DFR_Class_Helper.SQLMasterMappingFromLead(dfr, convertedLead);
                            dfr = DG_DFR_Class_Helper.SQLOwnerMappingFromUser(dfr, oppOwner, SQLOwnerName, SQLOwnerId);

                            if (!isOpportunityCreatedByConversion) {
                                dfr.SQL_Entered_From__c = 'Existing Opportunity';
                            } else {
                                dfr.SQL_Entered_From__c = 'SAL';
                            }
                            dfr.SAL_Exited_To__c = 'SQL';
                            dfr.SAL_DateTime_Exited__c = DateTime.now();
                        } else {
                            dfr = DG_DFR_Class_Helper.EOLMasterMappingFromLead(dfr, convertedLead);
                            dfr = DG_DFR_Class_Helper.EOLOwnerMappingFromUser(dfr, owner, ownerName, ownerId);
                            dfr.SAL_isContact__c = true;
                            dfr.EOL_Entered_From__c = 'SAL';
                            dfr.Pre_Opportunity_Status__c = 'EOL';
                            dfr.SAL_Exited_To__c = 'EOL';
                            dfr.SAL_DateTime_Exited__c = DateTime.now();
                        }
                    }
                    update dfr;
                } else if (convertedLead.ConvertedContactId != null && !ExcludedLS.contains(convertedLead.LeadSource)) {
                    Demand_Funnel__c dfr = new Demand_Funnel__c();
                    dfr.DFR_Funnel_Type__c = 'Acquisition';
                    dfr.isCustomer__c = c.Customer_Record__c;

                    if (o?.AccountId != null) {
                        dfr.Account__c = o.AccountId;
                    } else if (c?.AccountId != null) {
                        dfr.Account__c = c.AccountId;
                    } else {
                        dfr.Account__c = convertedLead.ZI_CDP_Account_Id__c;
                    }

                    dfr.Contact__c = convertedLead.ConvertedContactId;
                    c.DFR_Status__c = convertedLead.Status;
                    update c;

                    if (String.IsNotBlank(c.Contact_Funnel_Type__c)) {
                        if (mapContactTypeToFunnelType.containsKey(c.Contact_Funnel_Type__c.ToLowerCase())) {
                            dfr.DFR_Funnel_Type__c = mapContactTypeToFunnelType.get(
                                c.Contact_Funnel_Type__c.ToLowerCase()
                            );
                        }
                    }

                    dfr = DG_DFR_Class_Helper.prospectBackfillForLead(dfr, convertedLead, owner, ownerName, ownerId);
                    dfr = DG_DFR_Class_Helper.mqlBackfillForLead(dfr, convertedLead, owner, ownerName, ownerId);
                    dfr = DG_DFR_Class_Helper.SALMasterMappingFromLead(dfr, convertedLead);
                    dfr = DG_DFR_Class_Helper.onCreationMapping(dfr, convertedLead);
                    dfr.Lead_Name_on_Creation__c =
                        (convertedLead.FirstName != null ? convertedLead.FirstName + ' ' : '') + convertedLead.LastName;
                    dfr.DFR_Primary_Role__c = true;
                    dfr.isConverted__c = true;
                    dfr.MQL_Type__c = convertedLead.Status == '.5 Re-New' ? 'Re-New' : 'New';
                    dfr.IsContactMerge__c = isContactCreatedByConversion ? false : true;
                    dfr.MQL_Form_URL__c = c.Form_URL__c;
                    dfr.Prospect_Form_URL__c = c.Form_URL__c;

                    if (convertedLead.ConvertedOpportunityId != null) {
                        dfr.isPrimary__c = isOpportunityCreatedByConversion ? true : false;
                        dfr.Opportunity_Owner_Segment__c = owner.SegmentPicklist__c;
                        dfr.Opportunity_Owner_Territory__c = owner.Upmarket_Territory__c;
                        dfr = DG_DFR_Class_Helper.SQLMasterMappingFromLead(dfr, convertedLead);
                        dfr = DG_DFR_Class_Helper.salBackfillForLead(
                            dfr,
                            convertedLead,
                            oppOwner,
                            SQLOwnerName,
                            SQLOwnerId
                        );
                        dfr = DG_DFR_Class_Helper.SQLOwnerMappingFromUser(dfr, oppOwner, SQLOwnerName, SQLOwnerId);

                        if (DG_DFR_Class_Helper.isBDRSDRNullUserByTeam(owner.Team__c)) {
                            dfr = DG_DFR_Class_Helper.talBackfillForLead(
                                dfr,
                                convertedLead,
                                oppOwner,
                                SQLOwnerName,
                                SQLOwnerId
                            );
                            dfr = DG_DFR_Class_Helper.TQLMasterMappingFromLead(dfr, convertedLead);
                            dfr = DG_DFR_Class_Helper.TQLBackfillMapping(dfr);

                            if (DG_DFR_Class_Helper.isBDRSDRNullUserByTeam(oppOwner.Team__c)) {
                                dfr = DG_DFR_Class_Helper.TALOwnerMappingFromUser(
                                    dfr,
                                    oppOwner,
                                    SQLOwnerName,
                                    SQLOwnerId
                                );
                                dfr = DG_DFR_Class_Helper.TQLOwnerMappingFromUser(
                                    dfr,
                                    oppOwner,
                                    SQLOwnerName,
                                    SQLOwnerId
                                );
                            } else {
                                dfr = DG_DFR_Class_Helper.TALOwnerMappingFromUser(dfr, owner, ownerName, ownerId);
                                dfr = DG_DFR_Class_Helper.TQLOwnerMappingFromUser(dfr, owner, ownerName, ownerId);
                            }
                            dfr.TAL_DateTime_Exited__c = Datetime.now();
                        }
                        dfr.SQL_Entered_From__c = isOpportunityCreatedByConversion ? 'Created' : 'Existing Opportunity';
                    } else {
                        dfr = DG_DFR_Class_Helper.SALOwnerMappingFromUser(dfr, owner, ownerName, ownerId);
                        dfr = DG_DFR_Class_Helper.EOLMasterMappingFromLead(dfr, convertedLead);
                        dfr = DG_DFR_Class_Helper.EOLOwnerMappingFromUser(dfr, owner, ownerName, ownerId);
                        dfr.SAL_isContact__c = true;
                        dfr.Pre_Opportunity_Status__c = 'EOL';
                        dfr.EOL_Entered_From__c = 'SAL';
                        dfr.SAL_Exited_to__c = 'EOL';
                        dfr.SAL_DateTime_Exited__c = DateTime.now();

                        if (dfr.TAL_Entered_From__c != null) {
                            dfr.SAL_Entered_From__c = 'TAL';
                        } else if (dfr.SAL_DateTime_Entered__c == null && dfr.MQL_Entered_From__c != null) {
                            dfr.SAL_Entered_From__c = 'MQL';
                        } else if (dfr.SAL_DateTime_Entered__c == null && dfr.Prospect_Entered_From__c != null) {
                            dfr.SAL_Entered_From__c = 'Prospect';
                        } else if (dfr.SAL_DateTime_Entered__c == null) {
                            dfr.SAL_Entered_From__c = 'Created';
                        }
                    }
                    insert dfr;
                }
            }
        } catch (Exception e) {
            dfrSaveException(e, convertedLead.Id, null, null, null);
        }
    }

    public static void SALHandOff_OnUpdate(List<Lead> listNew, Map<Id, Lead> mapOld) {
        try {
            Set<Id> listOwnerId = new Set<Id>();
            for (Lead newLead : ListNew) {
                Lead oldLead = mapOld.get(newLead.Id);
                if (oldLead.OwnerId <> newLead.OwnerId) {
                    listOwnerId.add(oldLead.OwnerId);
                    listOwnerId.add(newLead.OwnerId);
                }
            }
            if (!listOwnerId.isEmpty()) {
                Map<Id, User> mapUser = DG_DFR_Class_Helper.getUsersById(listOwnerId);
                Map<Id, QueueSobject> mapQueue = DG_DFR_Class_Helper.getMapOfQueues(listOwnerId, 'Lead');
                Map<Id, Lead> mapLead = DG_DFR_Class_Helper.filterLeadsByOwnerProfileSALHandOff(
                    listNew,
                    mapOld,
                    mapUser
                );

                if (!mapLead.isEmpty()) {
                    Set<Id> leadSet = new Set<Id>(mapLead.keySet());
                    Map<Id, Demand_Funnel__c> mapDFR = DG_DFR_Class_Helper.populateDFRMapSALHandOff(leadSet);
                    List<Demand_Funnel__c> dfrsToUpdate = new List<Demand_Funnel__c>();
                    for (Demand_Funnel__c dfr : mapDFR.values()) {
                        Id ownerId = mapLead.get(dfr.Lead__c).OwnerId;
                        if (mapUser.containsKey(ownerId)) {
                            dfr.SAL_Handoff_Date__c = datetime.now();
                            dfr.SAL_Handoff_Owner__c = mapUser.get(ownerId).Name;
                            dfr.SAL_Handoff_Owner_Role__c = mapUser.get(ownerId).UserRole.Name;
                            dfrsToUpdate.add(dfr);
                        } else if (mapQueue.containsKey(ownerId)) {
                            QueueSobject q = mapQueue.get(ownerId);
                            dfr.SAL_Handoff_Date__c = datetime.now();
                            dfr.SAL_Handoff_Owner__c = q.Queue.Name;
                            dfrsToUpdate.add(dfr);
                        }
                    }
                    if (!dfrsToUpdate.isEmpty()) {
                        update dfrsToUpdate;
                    }
                }
            }
        } catch (Exception e) {
            if (listNew != null && listNew.size() > 25) {
                throw e;
            } else {
                dfrSaveException(e, null, listNew, null, null);
            }
        }
    }

    public static void DFR_ChangeLeadOwner(List<Lead> listNew, Map<Id, Lead> mapOld) {
        try {
            Set<Id> listOwnerId = new Set<Id>();
            Map<Id, Id> mapLeadIdOpportunityId = new Map<Id, Id>();

            for (Lead lead : listNew) {
                Lead leadOld = mapOld.get(lead.Id);
                if (mapDFRSystemUsers.containsKey(leadOld.OwnerId) && !mapDFRSystemUsers.containsKey(lead.OwnerId)) {
                    if (lead.isConverted == false) {
                        listOwnerId.add(lead.OwnerId);
                        mapLeadIdOpportunityId.put(lead.id, lead.OwnerId);
                    }
                }
            }
            if (!mapLeadIdOpportunityId.isEmpty()) {
                List<Demand_Funnel__c> listDFR = new List<Demand_Funnel__c>();

                Set<Id> leadSet = new Set<Id>(mapLeadIdOpportunityId.keySet());

                listDFR = DG_DFR_Class_Helper.populateActiveDFRsLeadOwnerChange(leadSet);

                if (!listDFR.isEmpty()) {
                    Map<String, String> mapSysFullName = new Map<String, String>();
                    for (String o : mapDFRSystemUsers.keySet()) {
                        String sysOwner = mapDFRSystemUsers.get(o);
                        mapSysFullName.put(sysOwner, sysOwner);
                    }
                    Map<Id, User> mapUsers = DG_DFR_Class_Helper.getUsersById(listOwnerId);
                    Map<Id, Lead> mapLeadNew = new Map<Id, Lead>(listNew);
                    Map<Id, QueueSobject> mapQueue = DG_DFR_Class_Helper.getMapOfQueues(listOwnerId, 'Lead');

                    for (Demand_Funnel__c dfr : listDFR) {
                        String ownerName;
                        String ownerId;
                        User owner = new User();

                        if (mapLeadIdOpportunityId.containsKey(dfr.Lead__c)) {
                            Id leadOwnerId = mapLeadIdOpportunityId.get(dfr.Lead__c);
                            if (mapUsers.containsKey(leadOwnerId)) {
                                ownerName = mapUsers.get(leadOwnerId).Name;
                                ownerId = leadOwnerId;
                                owner = mapUsers.get(leadOwnerId);
                            } else if (mapQueue.containsKey(leadOwnerId)) {
                                QueueSobject q = mapQueue.get(leadOwnerId);
                                ownerName = q.Queue.Name;
                                ownerId = q.QueueId;
                            }
                        }
                        String leadDFRStage = mapStatusToStage.get(mapLeadNew.get(dfr.Lead__c).Status);
                        if (dfr.SAL_DateTime_Entered__c != null && mapSysFullName.containsKey(dfr.SAL_Owner_Name__c)) {
                            dfr = DG_DFR_Class_Helper.SALOwnerMappingFromUser(dfr, owner, ownerName, ownerId);
                        }
                        if (dfr.MQL_DateTime_Entered__c != null && mapSysFullName.containsKey(dfr.MQL_Owner_Name__c)) {
                            dfr = DG_DFR_Class_Helper.MQLOwnerMappingFromUser(dfr, owner, ownerName, ownerId);
                            if (
                                DG_DFR_Class_Helper.backfillTALTQLCheck(dfr) &&
                                (leadDFRStage == DFRTAL ||
                                leadDFRStage == DFRSAL)
                            ) {
                                dfr = DG_DFR_Class_Helper.talOnChangeOwnerForLeadFromUser(
                                    dfr,
                                    owner,
                                    ownerName,
                                    ownerId
                                );

                                if (dfr.TAL_DateTime_Entered__c == null) {
                                    dfr = DG_DFR_Class_Helper.talOnChangeOwnerForLead(dfr, mapLeadNew.get(dfr.Lead__c));
                                    if (DG_DFR_Class_Helper.isBDRSDRNullUserByTeam(owner.Team__c)) {
                                        DG_DFR_Class_Helper.setSALStampingToNull(dfr);
                                    }
                                }
                            } else {
                                DG_DFR_Class_Helper.setTALStampingToNull(dfr);

                                if (leadDFRStage == DFRSAL) {
                                    dfr = DG_DFR_Class_Helper.stageSalOnChangeOwnerForLead(
                                        dfr,
                                        mapLeadNew.get(dfr.Lead__c),
                                        owner,
                                        ownerName,
                                        ownerId
                                    );
                                } else if (leadDFRStage == DFRMQL) {
                                    dfr = DG_DFR_Class_Helper.stageMqlOnChangeOwnerForLead(
                                        dfr,
                                        mapLeadNew.get(dfr.Lead__c),
                                        owner,
                                        ownerName,
                                        ownerId
                                    );
                                }
                            }
                        }
                        if (
                            dfr.Prospect_DateTime_Entered__c != null &&
                            mapSysFullName.containsKey(dfr.Prospect_Owner_Name__c)
                        ) {
                            dfr = DG_DFR_Class_Helper.prospectOnChangeOwnerForLead(
                                dfr,
                                owner,
                                ownerName,
                                ownerId,
                                leadDFRStage
                            );
                        }
                    }
                }
                if (!listDFR.isEmpty()) {
                    update listDFR;
                }
            }
        } catch (Exception e) {
            if (listNew != null && listNew.size() > 25) {
                throw e;
            } else {
                dfrSaveException(e, null, listNew, null, null);
            }
        }
    }

    public static void DFR_OpportunityClosed(
        List<Opportunity> newOpportunities,
        Map<Id, Opportunity> oldOpportunitiesMap
    ) {
        try {
            Set<Id> listOppId = new Set<Id>();
            Set<Id> listOwnerId = new Set<Id>();
            Set<Id> setLostOppId = new Set<Id>();
            Map<Id, Opportunity> mapOpp = new Map<Id, Opportunity>();
            List<Demand_Funnel__c> dfrsForUpdate = new List<Demand_Funnel__c>();
            List<Demand_Funnel__c> dfrsForUpdateUnified = new List<Demand_Funnel__c>();
            List<Demand_Funnel__c> listDFR = new List<Demand_Funnel__c>();
            List<Demand_Funnel__c> dfrsFromOpportunities = new List<Demand_Funnel__c>();
            List<Opportunity> opportunitiesForPipelineRecalculation = new List<Opportunity>();
            Set<Id> oppIdToUpdateDFRPreOppCloseReason = new Set<Id>();
            Map<Id, String> oppMapRTId = new Map<Id, String>();
            Map<String, Schema.RecordTypeInfo> optyRTs = Opportunity.SObjectType.getDescribe()
                .getRecordTypeInfosByName();
            
            dfrsFromOpportunities = (List<Demand_Funnel__c>) new DemandFunnelSelector()
                .selectDFRByOpportunityID(new List<Object>{ newOpportunities })
                .executeQuery();

            for (String optyType : dfrOppRType) {
                optyType = optyType.replace('_', ' ');
                if (optyRTs.containsKey(optyType)) {
                    oppMapRTId.put(optyRTs.get(optyType).getRecordTypeId(), optyRTs.get(optyType).getName());
                }
            }

            for (Opportunity opp : newOpportunities) {
                Opportunity oldOpp = oldOpportunitiesMap.get(opp.Id);
                if (oppMapRTId.containsKey(opp.RecordTypeId)) {
                    if (
                        opp.IsClosed &&
                        opp.IsClosed <> oldOpp.IsClosed &&
                        (opp.Brand_Name__c == null ||
                        (opp.Brand_Name__c != null &&
                        System.Label.BizMerge_Brand_Exclusion_List != null &&
                        !System.Label.BizMerge_Brand_Exclusion_List.contains(opp.Brand_Name__c)))
                    ) {
                        listOppId.add(opp.Id);
                        listOwnerId.add(opp.OwnerId);
                        listOwnerId.add(oldOpp.OwnerId);
                        mapOpp.put(opp.id, opp);
                        if (!opp.IsWon) {
                            setLostOppId.add(opp.Id);
                        }
                    }

                    if (
                        opp.stageName != STATUS_DOWNGRADED &&
                        oldOpp.stageName == STATUS_DOWNGRADED &&
                        (opp.Brand_Name__c == null ||
                        (opp.Brand_Name__c != null &&
                        System.Label.BizMerge_Brand_Exclusion_List != null &&
                        !System.Label.BizMerge_Brand_Exclusion_List.contains(opp.Brand_Name__c)))
                    ) {
                        oppIdToUpdateDFRPreOppCloseReason.add(opp.Id);
                    }
                }
            }

            if (!listOppId.isEmpty()) {
                Map<Id, User> mapUsers = DG_DFR_Class_Helper.getUsersById(listOwnerId);
                Map<Id, QueueSobject> mapQueue = DG_DFR_Class_Helper.getMapOfQueues(listOwnerId, 'Lead');
                Map<Id, Contact> mapCon = new Map<Id, Contact>();
                Set<Id> listConId = new Set<Id>();

                for (Demand_Funnel__c dfr : dfrsFromOpportunities) {
                    if (listOppId.contains(dfr.Opportunity__c)) {
                        listDFR.add(dfr);
                    }
                }

                for (Demand_Funnel__c dfr : listDFR) {
                    listConId.add(dfr.Contact__c);
                }

                mapCon.putAll(
                    (List<Contact>) new ContactSelector()
                        .selectContactsForDFRById(new List<Object>{ listConId })
                        .executeQuery()
                );

                for (Demand_Funnel__c dfr : listDFR) {
                    Contact con = mapCon.get(DFR.Contact__c);
                    String ownerName;
                    String ownerId;
                    User owner = new User();

                    if (mapUsers.containsKey(dfr.Opportunity__r.OwnerId)) {
                        ownerName = mapUsers.get(dfr.Opportunity__r.OwnerId).Name;
                        ownerId = dfr.Opportunity__r.OwnerId;
                        owner = mapUsers.get(dfr.Opportunity__r.OwnerId);
                    } else if (mapQueue.containsKey(dfr.Opportunity__r.OwnerId)) {
                        ownerName = mapQueue.get(dfr.Opportunity__r.OwnerId).Queue.Name;
                        ownerId = mapQueue.get(dfr.Opportunity__r.OwnerId).Queue.Id;
                    }

                    if (con != null) {
                        dfr = DG_DFR_Class_Helper.EOLMasterMappingFromContact(dfr, con);
                    }

                    if (mapOpp.containsKey(dfr.Opportunity__c)) {
                        dfr.EOL_DateTime_Entered__c = mapOpp.get(dfr.Opportunity__c).DFR_Actual_Close_DateTime__c;
                    }

                    dfr = DG_DFR_Class_Helper.EOLOwnerMappingFromUser(dfr, owner, ownerName, ownerId);
                    dfr.EOL_Entered_From__c = 'SQL';

                    if (setLostOppId.contains(dfr.Opportunity__c)) {
                        if (mapOpp.containsKey(dfr.Opportunity__c)) {
                            dfr.EOL_Downgrade_Reason__c = mapOpp.get(DFR.Opportunity__c).Downgrade_Reason_Opp__c;
                            dfr.EOL_Sub_Downgrade_Reason__c = mapOpp.get(DFR.Opportunity__c).Sub_Downgrade_Reason__c;
                        }
                    }
                    dfrsForUpdate.add(dfr);
                }
            }

            if (!oppIdToUpdateDFRPreOppCloseReason.isEmpty()) {
                List<Demand_Funnel__c> dfrsToNullCloseReason = new List<Demand_Funnel__c>();
                for (
                    Demand_Funnel__c dfr : (List<Demand_Funnel__c>) new DemandFunnelSelector()
                        .selectDFRByOpportunittiesIdAndPreOpportunityReasonNull(
                            new List<Object>{ oppIdToUpdateDFRPreOppCloseReason }
                        )
                        .executeQuery()
                ) {
                    dfr.Pre_Opportunity_Close_Reason__c = null;
                    dfrsToNullCloseReason.add(dfr);
                }
                update dfrsToNullCloseReason;
            }

            opportunitiesForPipelineRecalculation = DG_DFR_Class_Helper.checkOpportunitiesForPipelineRecalculation(oldOpportunitiesMap, newOpportunities);
            if (!dfrsForUpdate.isEmpty() || !opportunitiesForPipelineRecalculation.isEmpty()) {
                dfrsForUpdateUnified = getProcessedOrOriginalDFR(dfrsForUpdate, DG_DFR_Class_Helper.DFRPipelineRecalculation(dfrsFromOpportunities, opportunitiesForPipelineRecalculation));
                update dfrsForUpdateUnified;
            }
        } catch (Exception e) {
            dfrSaveException(e, null, null, null, newOpportunities);
        }
    }

    public static void MQLHandOff_OnUpdate(List<Lead> listNew, Map<Id, Lead> mapOld) {
        try {
            Set<Id> setOwnerIds = new Set<Id>();
            for (Lead newLead : listNew) {
                Lead oldLead = mapOld.get(newLead.Id);
                if (oldLead.OwnerId <> newLead.OwnerId) {
                    setOwnerIds.add(newLead.OwnerId);
                    setOwnerIds.add(oldLead.OwnerId);
                }
            }
            if (!setOwnerIds.isEmpty()) {
                Map<Id, User> mapUser = DG_DFR_Class_Helper.getUsersById(setOwnerIds);
                Map<Id, QueueSobject> mapQueue = DG_DFR_Class_Helper.getMapOfQueues(setOwnerIds, 'Lead');
                Map<Id, Lead> mapLead = DG_DFR_Class_Helper.getLeadsWithOwnerChangesFromQueueToUser(
                    listNew,
                    mapOld,
                    mapUser,
                    mapQueue
                );

                if (!mapLead.isEmpty()) {
                    Map<Id, Demand_Funnel__c> mapDFR = DG_DFR_Class_Helper.getDFRMapMQLHandOff(mapLead.keySet());
                    List<Demand_Funnel__c> dfrsToUpdate = new List<Demand_Funnel__c>();
                    for (Demand_Funnel__c dfr : mapDFR.values()) {
                        Id ownerId = mapLead.get(dfr.Lead__c).OwnerId;
                        User owner = mapUser.get(ownerId);

                        dfr.MQL_Handoff_Date__c = datetime.now();
                        dfr.MQL_Owner_Name__c = mapUser.get(ownerId).Name;
                        dfr.MQL_Owner_Id__c = ownerId;
                        dfr = DG_DFR_Class_Helper.mqlOwnerMappingFromUser(dfr, owner, owner.Name, ownerId);

                        dfrsToUpdate.add(dfr);
                    }
                    if (!dfrsToUpdate.isEmpty()) {
                        update dfrsToUpdate;
                    }
                }
            }
        } catch (Exception e) {
            if (listNew != null && listNew.size() > 25) {
                throw e;
            } else {
                dfrSaveException(e, null, listNew, null, null);
            }
        }
    }

    public static void DFR_UpdateTQLOnOwnerChange(List<Lead> triggerNew, Map<Id, Lead> triggerOldMap) {
        List<Demand_Funnel__c> dfrsToUpdate = new List<Demand_Funnel__c>();
        Set<Id> idForQuery = new Set<Id>();
        Set<Id> listOwnerId = new Set<Id>();
        List<Lead> leadsToProcess = new List<Lead>();
        try {
            String ownerName;
            String ownerId;
            String newOwnerName;
            String newOwnerId;
            User oldOwner = new User();
            User newOwner = new User();

            for (Lead newlead : triggerNew) {
                if (newLead.OwnerId != (triggerOldMap.get(newLead.Id)).OwnerId) {
                    listOwnerId.add(newLead.OwnerId);
                    listOwnerId.add(triggerOldMap.get(newLead.Id).OwnerId);
                    idForQuery.add(newLead.Id);
                    leadsToProcess.add(newLead);
                }
            }
            Map<Id, Demand_Funnel__c> leadDFRMap = DG_DFR_Class_Helper.getDFRMap(idForQuery);
            Map<Id, QueueSobject> mapQueue = DG_DFR_Class_Helper.getMapOfQueues(listOwnerId, 'Lead');
            Map<Id, User> mapUsers = DG_DFR_Class_Helper.getUsersById(listOwnerId);

            for (Lead newLead : leadsToProcess) {
                Lead oldLead = triggerOldMap.get(newLead.Id);
                if (mapUsers.containsKey(oldLead.OwnerId)) {
                    ownerId = oldLead.OwnerId;
                    ownerName = mapUsers.get(oldLead.OwnerId).Name;
                    oldOwner = mapUsers.get(oldLead.OwnerId);
                } else if (mapQueue.containsKey(oldLead.OwnerId)) {
                    ownerName = mapQueue.get(oldLead.OwnerId).Queue.Name;
                    ownerId = oldLead.OwnerId;
                }
                if (mapUsers.containsKey(newLead.OwnerId)) {
                    newOwnerName = mapUsers.get(newLead.OwnerId).Name;
                    newOwnerId = newLead.OwnerId;
                    newOwner = mapUsers.get(newLead.OwnerId);
                } else if (mapQueue.containsKey(newLead.OwnerId)) {
                    newOwnerName = mapQueue.get(newLead.OwnerId).Queue.Name;
                    newOwnerId = newLead.OwnerId;
                }

                Demand_Funnel__c DFR = leadDFRMap.get(newLead.Id);

                if (
                    DG_DFR_Class_Helper.changeLeadOwnerShouldUpdateDFR(
                        DFR,
                        newLead,
                        oldLead,
                        mapUsers,
                        mapDFRSystemUsers
                    )
                ) {
                    DFR = DG_DFR_Class_Helper.tqlOnChangeOwnerForLead(DFR, oldLead, oldOwner, ownerName, ownerId);

                    if (DFR.TQL_DateTime_Entered__c != null) {
                        DFR = DG_DFR_Class_Helper.salOnChangeOwnerForLead(
                            DFR,
                            oldLead,
                            oldOwner,
                            newOwnerName,
                            newOwnerId
                        );
                    }
                    dfrsToUpdate.add(DFR);
                }
            }
            if (!dfrsToUpdate.isEmpty()) {
                update dfrsToUpdate;
            }
        } catch (Exception e) {
            if (triggerNew != null && triggerNew.size() > 25) {
                throw e;
            } else {
                dfrSaveException(e, null, triggerNew, null, null);
            }
        }
    }

    public static void updateMQLOwnerFieldsAfterLeanData(Map<Id, Lead> newLeads, Map<Id, Lead> oldLeads) {
        try {
            Set<Id> leadOwnerIds = new Set<Id>();
            Set<Id> leadIdsToUpdate = new Set<Id>();
            String leadIdToCompare = '';
            for (Lead newLead : newLeads.values()) {
                if (DG_DFR_Class_Helper.meetsLeadRoutingCriteria(newLead, oldLeads.get(newLead.Id))) {
                    leadOwnerIds.add(newLead.OwnerId);
                    leadIdsToUpdate.add(newLead.Id);
                }
            }

            if (!leadIdsToUpdate.isEmpty()) {
                Map<Id, Employee__c> ownerIdToEmployee = new Map<Id, Employee__c>();
                Map<Id, User> ownerIdToUser = new Map<Id, User>();
                Map<Id, QueueSObject> ownerIdToQueue = new Map<Id, QueueSObject>();

                for (
                    User user : (List<User>) new UserSelector()
                        .selectUserForDFRList(new List<Object>{ leadOwnerIds })
                        .executeQuery()
                ) {
                    ownerIdToUser.put(user.Id, user);
                }

                for (
                    Employee__c emp : (List<Employee__c>) new EmployeeSelector()
                        .selectEmployeeForDFR(new List<Object>{ leadOwnerIds })
                        .executeQuery()
                ) {
                    ownerIdToEmployee.put(emp.User__c, emp);
                }

                for (
                    QueueSObject queue : (List<QueueSObject>) new QueueSelector()
                        .selectQueueForDFRBySObjectType(new List<Object>{ 'Lead' })
                        .executeQuery()
                ) {
                    if (leadOwnerIds.contains(queue.QueueId)) {
                        ownerIdToQueue.put(queue.QueueId, queue);
                    }
                }

                List<Demand_Funnel__c> DFRToUpdate = new DemandFunnelSelector()
                    .selectMQLOwnersByLeadID(new List<Object>{ leadIdsToUpdate })
                    .executeQuery();

                String ownerName;
                for (Demand_Funnel__c dfr : DFRToUpdate) {
                    if (leadIdToCompare != (String) dfr.Lead__c) {
                        leadIdToCompare = dfr.Lead__c;
                        String leadOwnerID = newLeads.get(leadIdToCompare).OwnerId;
                        if (ownerIdToUser.containsKey(leadOwnerID)) {
                            ownerName = ownerIdToUser.get(leadOwnerID).Name;
                        } else if (ownerIdToQueue.containsKey(leadOwnerID)) {
                            ownerName = ownerIdToQueue.get(leadOwnerID).Queue.Name;
                        }

                        dfr = DG_DFR_Class_Helper.setDFRMQLOwnerFields(dfr, leadOwnerID, ownerIdToUser, ownerIdToQueue);

                        if (
                            newLeads.get(leadIdToCompare).Status == LeadTriggerHelper.LEADSTATUSCALLOUT ||
                            newLeads.get(leadIdToCompare).Status == LeadTriggerHelper.LEADSTATUSCONTACTED
                        ) {
                            if (DG_DFR_Class_Helper.isBDRSDRNullUserByTeam(dfr.MQL_Owner_Team__c)) {
                                DG_DFR_Class_Helper.setSALStampingToNull(dfr);
                                dfr = DG_DFR_Class_Helper.talOnChangeOwnerForLead_updateMQL(
                                    dfr,
                                    newLeads.get(leadIdToCompare),
                                    ownerName,
                                    leadOwnerID
                                );
                                dfr = DG_DFR_Class_Helper.setDFRTALOwnerFields(dfr, ownerIdToUser, leadOwnerID);
                            } else {
                                DG_DFR_Class_Helper.setTALStampingToNull(dfr);
                                dfr = DG_DFR_Class_Helper.salOnChangeOwnerForLead_updateMQL(
                                    dfr,
                                    newLeads.get(leadIdToCompare),
                                    ownerName,
                                    leadOwnerID
                                );
                                dfr = DG_DFR_Class_Helper.setDFRSALOwnerFields(dfr, ownerIdToUser, leadOwnerID);
                            }
                            if (dfr.TQL_DateTime_Entered__c != null) {
                                DG_DFR_Class_Helper.setTQLStampingToNull(dfr);
                            }
                        }
                    }
                }
                update DFRToUpdate;
            }
        } catch (Exception e) {
            if (newLeads.values() != null && newLeads.values().size() > 25) {
                throw e;
            } else {
                dfrSaveException(e, null, newLeads.values(), null, null);
            }
        }
    }

    public static void DFR_AddOpportunity(List<Opportunity> opps) {
        try {
            Set<Id> ownerIds = new Set<Id>();
            String ownerName;
            String ownerId;
            User owner = new User();
            String previousOwnerName;
            User previousOwner = new User();
            String previousOwnerId;
            String status;
            List<Demand_Funnel__c> dfrs = new List<Demand_Funnel__c>();
            Map<Id, Contact> mapContacts = new Map<Id, Contact>();
            Map<Id, Demand_Funnel__c> mapContactIdDfr = new Map<Id, Demand_Funnel__c>();
            Set<Id> contactIds = new Set<Id>();
            List<Demand_Funnel__c> dfrsToUpsert = new List<Demand_Funnel__c>();
            List<Opportunity> oppsForPipelineRecalculation = new List<Opportunity>();
            List<Demand_Funnel__c>  dfrsToUpsertPipeline = new List<Demand_Funnel__c>();

            for (Opportunity opp : opps) {
                if (opp.Conversion_Contact__c != null && !contactIds.contains(opp.Conversion_Contact__c)) {
                    contactIds.add(opp.Conversion_Contact__c);
                } else if (opp.Primary_Opportunity_Contact__c != null && !contactIds.contains(opp.Primary_Opportunity_Contact__c)) {
                    contactIds.add(opp.Primary_Opportunity_Contact__c);
                }
                ownerIds.add(opp.OwnerId);
            }
            
            dfrs = (List<Demand_Funnel__c>) new DemandFunnelSelector()
                .selectDFRsForAddOpportunity(contactIds)
                .executeQuery();

            mapContacts = new Map<Id, Contact>(
                (List<Contact>) new ContactSelector()
                    .selectContactsForDFRById(new List<Object>{ contactIds })
                    .executeQuery()
            );

            for (Demand_Funnel__c dfr : dfrs) {
                mapContactIdDfr.put(dfr.Contact__c, dfr);

                if (String.isNotBlank(dfr.TAL_Owner_Id__c)) {
                    ownerIds.add(dfr.TAL_Owner_Id__c);
                } else if (String.isNotBlank(dfr.MQL_Owner_Id__c)) {
                    ownerIds.add(dfr.MQL_Owner_Id__c);
                } else {
                    ownerIds.add(dfr.Contact__r.OwnerId);
                }
            }
            for (Contact con : mapContacts.values()) {
                ownerIds.add(con.OwnerId);
            }
            for (Opportunity opp : opps) {
                ownerIds.add(opp.OwnerId);
            }

            Map<Id, User> mapUsers = DG_DFR_Class_Helper.getUsersById(ownerIds);
            Map<Id, QueueSobject> mapQueue = DG_DFR_Class_Helper.getMapOfQueues(ownerIds, 'Lead');
            for (Opportunity opp : opps) {
                if (mapUsers.containsKey(opp.OwnerId)) {
                    ownerName = mapUsers.get(opp.OwnerId).Name;
                    ownerId = opp.OwnerId;
                    owner = mapUsers.get(opp.OwnerId);
                } else if (mapQueue.containsKey(opp.OwnerId)) {
                    ownerName = mapQueue.get(opp.OwnerId).Queue.Name;
                    ownerId = mapQueue.get(opp.OwnerId).Queue.Id;
                }

                Id getPrimaryOrConversionContact = opp.Conversion_Contact__c != null && 
                mapContacts.get(opp.Conversion_Contact__c) != null ? opp.Conversion_Contact__c : opp.Primary_Opportunity_Contact__c;

                Contact con = mapContacts.get(getPrimaryOrConversionContact);

                if (mapContactIdDfr.containsKey(getPrimaryOrConversionContact) &&
                !dfrsToUpsert.contains(mapContactIdDfr.get(getPrimaryOrConversionContact))){

                    Demand_Funnel__c dfr = mapContactIdDfr.get(getPrimaryOrConversionContact);

                    if (String.isNotBlank(dfr.TAL_Owner_Id__c)) {
                        previousOwnerId = dfr.TAL_Owner_Id__c;
                    } else if (String.isNotBlank(dfr.MQL_Owner_Id__c)) {
                        previousOwnerId = dfr.MQL_Owner_Id__c;
                    } else {
                        previousOwnerId = con.OwnerId;
                    }
                    if (mapUsers.containsKey(previousOwnerId)) {
                        previousOwnerName = mapUsers.get(previousOwnerId).Name;
                        previousOwner = mapUsers.get(previousOwnerId);
                    }

                    status = dfr.Pre_Opportunity_Status__c;
                    dfr.Opportunity_Owner_Id__c = ownerId;
                    dfr.Opportunity_Owner_Segment__c = owner.SegmentPicklist__c;
                    dfr.Opportunity_Owner_Territory__c = owner.Upmarket_Territory__c;

                    if (status == DFRPROSPECT) {
                        dfr = DG_DFR_Class_Helper.mqlBackfillForContact(
                            dfr,
                            con,
                            previousOwner,
                            previousOwnerName,
                            previousOwnerId
                        );
                    }

                    if (
                        (status == DFRPROSPECT || status == DFRMQL || status == DFRRENEW || status == DFRTAL) &&
                        DG_DFR_Class_Helper.isBDRSDRNullUserByTeam(dfr.MQL_Owner_Team__c)
                    ) {
                        if (status != DFRTAL) {
                            dfr = DG_DFR_Class_Helper.TALMasterMappingFromContact(dfr, con);
                            dfr = DG_DFR_Class_Helper.TALBackfillMapping(dfr);
                        }
                        if (status != DFRTQL) {
                            dfr = DG_DFR_Class_Helper.TQLMasterMappingFromContact(dfr, con);
                            dfr = DG_DFR_Class_Helper.TQLBackfillMapping(dfr);
                        }
                        if (DG_DFR_Class_Helper.isBDRSDRNullUserByTeam(owner.Team__c)) {
                            if (status != DFRTAL) {
                                dfr = DG_DFR_Class_Helper.TALOwnerMappingFromUser(dfr, owner, ownerName, ownerId);
                            }
                            if (status != DFRTQL) {
                                dfr = DG_DFR_Class_Helper.TQLOwnerMappingFromUser(dfr, owner, ownerName, ownerId);
                            }
                        } else {
                            if (status != DFRTAL) {
                                dfr = DG_DFR_Class_Helper.TALOwnerMappingFromUser(
                                    dfr,
                                    previousOwner,
                                    previousOwnerName,
                                    previousOwnerId
                                );
                            }
                            if (status != DFRTQL) {
                                dfr = DG_DFR_Class_Helper.TQLOwnerMappingFromUser(
                                    dfr,
                                    previousOwner,
                                    previousOwnerName,
                                    previousOwnerId
                                );
                            }
                        }
                    }

                    if (
                        (status == DFRPROSPECT ||
                        status == DFRMQL ||
                        status == DFRRENEW ||
                        status == DFRTAL ||
                        status == DFRTQL) && status != DFRSAL
                    ) {
                        dfr = DG_DFR_Class_Helper.salBackfillForContact(dfr, con, owner, ownerName, ownerId);
                    } else if (
                        status == DFRSAL &&
                        DG_DFR_Class_Helper.isBDRSDRNullUserByTeam(dfr.SAL_Owner_Team__c) &&
                        !DG_DFR_Class_Helper.isBDRSDRNullUserByTeam(owner.Team__c)
                    ) {
                        dfr = DG_DFR_Class_Helper.SALOwnerMappingFromUser(dfr, owner, ownerName, ownerId);
                    }

                    dfr = DG_DFR_Class_Helper.SQLMasterMappingFromContact(dfr, con);

                    dfr = DG_DFR_Class_Helper.SQLOwnerMappingFromUser(dfr, owner, ownerName, ownerId);

                    dfr.isPrimary__c = true;
                    dfr.Account__c = opp.AccountId;
                    dfr.Opportunity__c = opp.Id;

                    if (String.IsNotBlank(con.Contact_Funnel_Type__c)) {
                        if (mapContactTypeToFunnelType.containsKey(con.Contact_Funnel_Type__c.ToLowerCase())) {
                            dfr.DFR_Funnel_Type__c = mapContactTypeToFunnelType.get(
                                con.Contact_Funnel_Type__c.ToLowerCase()
                            );
                        }
                    }

                    if (status == DFRSAL) {
                        dfr.SAL_DateTime_Exited__c = datetime.now();
                        dfr.SAL_Exited_To__c = DFRSQL;
                        dfr.SQL_Entered_From__c = DFRSAL;
                    } else if (status == DFRTQL) {
                        dfr.TQL_DateTime_Exited__c = datetime.now();
                        dfr.TQL_Exited_To__c = DFRSQL;
                        dfr.SQL_Entered_From__c = DFRTQL;
                    } else if (status == DFRTAL) {
                        dfr.TAL_DateTime_Exited__c = datetime.now();
                        dfr.TAL_Exited_To__c = DFRSQL;
                        dfr.SQL_Entered_From__c = DFRTAL;
                    } else if (status == DFRMQL) {
                        dfr.MQL_DateTime_Exited__c = datetime.now();
                        dfr.MQL_Exited_To__c = DFRSQL;
                        dfr.SQL_Entered_From__c = DFRMQL;
                    } else if (status == DFRPROSPECT) {
                        dfr.Prospect_DateTime_Exited__c = datetime.Now();
                        dfr.Prospect_Exited_To__c = DFRSQL;
                        dfr.SQL_Entered_From__c = DFRPROSPECT;
                    }

                    dfr.Pre_Opportunity_Status__c = DFRSQL;
                    dfrsToUpsert.add(dfr);
                } else {
                    Demand_Funnel__c dfr = new Demand_Funnel__c();
                    previousOwnerId = con.OwnerId;
                    if (mapUsers.containsKey(previousOwnerId)) {
                        previousOwnerName = mapUsers.get(previousOwnerId).Name;
                        previousOwner = mapUsers.get(previousOwnerId);
                    }

                    dfr = DG_DFR_Class_Helper.sqlOnCreationForContact(dfr, con, opp, owner, ownerName, ownerId);

                    dfr.Pre_Opportunity_Status__c = DFRSQL;
                    dfr.DFR_Primary_Role__c = true;
                    dfr.MQL_Type__c = (con.Contact_Status__c == STATUS_CUSTOMER ||
                        con.Contact_Status__c == STATUS_DOWNGRADED)
                        ? 'Re-New'
                        : 'New';
                    dfr.isPrimary__c = true;
                    dfr.isCustomer__c = con.Customer_Record__c;
                    dfr = DG_DFR_Class_Helper.prospectBackfillForContact(
                        dfr,
                        con,
                        previousOwner,
                        previousOwnerName,
                        previousOwnerId
                    );
                    dfr = DG_DFR_Class_Helper.mqlBackfillForContact(
                        dfr,
                        con,
                        previousOwner,
                        previousOwnerName,
                        previousOwnerId
                    );

                    if (DG_DFR_Class_Helper.isBDRSDRNullUserByTeam(dfr.MQL_Owner_Team__c)) {
                        dfr = DG_DFR_Class_Helper.TALMasterMappingFromContact(dfr, con);
                        dfr = DG_DFR_Class_Helper.TALBackfillMapping(dfr);
                        dfr = DG_DFR_Class_Helper.TQLMasterMappingFromContact(dfr, con);
                        dfr = DG_DFR_Class_Helper.TQLBackfillMapping(dfr);
                        if (DG_DFR_Class_Helper.isBDRSDRNullUserByTeam(dfr.SQL_Owner_Team__c)) {
                            dfr = DG_DFR_Class_Helper.TALOwnerMappingFromUser(dfr, owner, ownerName, ownerId);
                            dfr = DG_DFR_Class_Helper.TQLOwnerMappingFromUser(dfr, owner, ownerName, ownerId);
                        } else {
                            dfr = DG_DFR_Class_Helper.TALOwnerMappingFromUser(
                                dfr,
                                previousOwner,
                                previousOwnerName,
                                previousOwnerId
                            );
                            dfr = DG_DFR_Class_Helper.TQLOwnerMappingFromUser(
                                dfr,
                                previousOwner,
                                previousOwnerName,
                                previousOwnerId
                            );
                        }
                    }
                    dfr = DG_DFR_Class_Helper.salBackfillForContact(dfr, con, owner, ownerName, ownerId);

                    if (String.IsNotBlank(con.Contact_Funnel_Type__c)) {
                        if (mapContactTypeToFunnelType.containsKey(con.Contact_Funnel_Type__c.ToLowerCase())) {
                            dfr.DFR_Funnel_Type__c = mapContactTypeToFunnelType.get(
                                con.Contact_Funnel_Type__c.ToLowerCase()
                            );
                        }
                    }


                    dfrsToUpsert.add(dfr);

                }
                if(opp.Estimated_12M_Total_Pipeline__c != null && opp.CloseDate != null){
                    oppsForPipelineRecalculation.add(opp);
                }
            }
            dfrsToUpsertPipeline = DG_DFR_Class_Helper.DFRPipelineRecalculation(dfrsToUpsert, oppsForPipelineRecalculation);
            dfrsToUpsert = getProcessedOrOriginalDFR(dfrsToUpsert, dfrsToUpsertPipeline);        
            upsert dfrsToUpsert;
        } catch (Exception e) {
            dfrSaveException(e, null, null, null, opps);
        }
    }

    public static List<Demand_Funnel__c>  getProcessedOrOriginalDFR(List<Demand_Funnel__c> originalList, List<Demand_Funnel__c> pipelineProcessed) {
        List<Demand_Funnel__c> result = new List<Demand_Funnel__c>();        
        Map<Id,Demand_Funnel__c> originalListMap = new Map<Id,Demand_Funnel__c>();
        Map<Id,Demand_Funnel__c> pipelineProcessedMap = new Map<Id,Demand_Funnel__c>(); 
        for (Demand_Funnel__c dfr : originalList) {
            originalListMap.put(dfr.Id,dfr);
        }
        for (Demand_Funnel__c dfr : pipelineProcessed) {
            pipelineProcessedMap.put(dfr.Id,dfr);
        }
        
        if (originalList.isEmpty()) {
            return pipelineProcessed;
        }

        for (Demand_Funnel__c dfr : originalList) {
            if (pipelineProcessedMap.containsKey(dfr.Id)) {
                result.add(pipelineProcessedMap.get(dfr.Id));
            } else {
                result.add(originalListMap.get(dfr.Id));
            }
        }
        
        return result;
    }


    public static void dfrContactCreation(List<Contact> listNew) {
        try {
            List<Demand_Funnel__c> dfrInsert = new List<Demand_Funnel__c>();
            Set<Id> listOwnerId = DG_DFR_Class_Helper.getListOwnerId(listNew);
            Map<Id, User> mapUsers = DG_DFR_Class_Helper.getUsersById(listOwnerId);
            Map<Id, QueueSobject> mapQueue = DG_DFR_Class_Helper.getMapOfQueues(listOwnerId, 'Contact');
            List<Contact> listExcludingBizContacts = DG_DFR_Class_Helper.excludeBizContacts(listNew);
            for (Contact con : listExcludingBizContacts) {
                String ownerName;
                User owner;
                String ownerId = con.OwnerId;
                String stage = mapContactStatusToStage.get(con.Contact_Status__c);
                Demand_Funnel__c dfr = new Demand_Funnel__c(
                    Contact__c = con.Id,
                    isCustomer__c = con.Customer_Record__c
                );
                dfr.DFR_Funnel_Type__c = 'Acquisition';
                dfr.Contact_Email_on_Creation__c = con.Email;
                dfr.Contact_Name_on_Creation__c = (con.FirstName != null ? con.FirstName + ' ' : '') + con.LastName;
                if (mapUsers.containsKey(con.OwnerId)) {
                    ownerName = mapUsers.get(con.OwnerId).Name;
                    owner = mapUsers.get(con.OwnerId);
                } else if (mapQueue.containsKey(con.OwnerId)) {
                    ownerName = mapQueue.get(con.OwnerId).Queue.Name;
                }
                if (stage != null && stage.equals(DFRPROSPECT)) {
                    dfr = DG_DFR_Class_Helper.prospectOnCreationForContact(dfr, con, owner, ownerName, ownerId);
                    dfr.Pre_Opportunity_Status__c = 'Prospect';
                    dfr.Prospect_Entered_From__c = 'Created';
                    dfrInsert.add(dfr);
                } else if (stage != null && stage.equals(DFRMQL)) {
                    dfr = DG_DFR_Class_Helper.prospectBackfillForContact(dfr, con, owner, ownerName, ownerId);
                    dfr = DG_DFR_Class_Helper.mqlOnCreationForContact(dfr, con, owner, ownerName, ownerId);
                    dfr.Pre_Opportunity_Status__c = 'MQL';
                    dfr.MQL_Type__c = con.Contact_Status__c == '1. New' ? 'New' : 'Re-New';
                    dfrInsert.add(dfr);
                } else if (stage != null && stage.equals(DFRSAL)) {
                    dfr = DG_DFR_Class_Helper.prospectBackfillForContact(dfr, con, owner, ownerName, ownerId);
                    dfr = DG_DFR_Class_Helper.mqlBackfillForContact(dfr, con, owner, ownerName, ownerId);
                    dfr.MQL_Type__c = 'New';
                    dfrInsert.add(dfr);
                    if (DG_DFR_Class_Helper.isBDRSDRNullUserByTeam(dfr.MQL_Owner_Team__c)) {
                        dfr = DG_DFR_Class_Helper.talOnCreationForContact(dfr, con, owner, ownerName, ownerId);
                        dfr.Pre_Opportunity_Status__c = 'TAL';
                    } else {
                        dfr = DG_DFR_Class_Helper.salOnCreationForContact(dfr, con, owner, ownerName, ownerId);
                        dfr.Pre_Opportunity_Status__c = 'SAL';
                        if (
                            owner != null &&
                            (owner.Profile.Name != null && !owner.Profile.Name.contains('SDR') ||
                            owner.Profile.Name == null)
                        ) {
                            dfr.SAL_Handoff_Date__c = DateTime.now();
                            dfr.SAL_Handoff_Owner__c = owner.Name;
                            dfr.SAL_Handoff_Owner_Role__c = owner.UserRoleName__c;
                        }
                    }
                }
            }
            if (!dfrInsert.isEmpty()) {
                insert dfrInsert;
            }
        } catch (Exception e) {
            DG_DFR_Class.dfrSaveException(e, null, null, listNew, null);
        }
    }

    public static void dfrContacts(List<Contact> listNew, Map<Id, Contact> mapOld) {
        try {
            Map<id, Demand_Funnel__c> mapContactDFR = new Map<Id, Demand_Funnel__c>();
            Map<id, Demand_Funnel__c> mapDFRUpdate = new Map<Id, Demand_Funnel__c>();
            List<Demand_Funnel__c> dfrInsert = new List<Demand_Funnel__c>();
            List<Demand_Funnel__c> dfrUpdate = new List<Demand_Funnel__c>();
            List<Contact> contactsToInsertDFR = new List<Contact>();
            Map<Id, User> mapUsers = new Map<Id, User>();
            Set<Id> listOwnerId = new Set<Id>();
            Map<Id, QueueSobject> mapQueue = new Map<Id, QueueSobject>();
            String ownerName;
            String ownerId;
            User owner = new User();
            String newStage;
            String oldStage;

            for (Contact con : listNew) {
                listOwnerId.add(con.OwnerId);
                if (mapOld != null && mapOld.get(con.Id) != null) {
                    listOwnerId.add(mapOld.get(con.Id).OwnerId);
                }
            }
            mapUsers = DG_DFR_Class_Helper.getUsersById(listOwnerId);
            mapQueue = DG_DFR_Class_Helper.getMapOfQueues(listOwnerId, 'Contact');
            Map<Id, Contact> mapContactsToProcess = DG_DFR_Class_Helper.getMapContactsWithStatusOrOwnerChanges(
                listNew,
                mapOld,
                mapUsers
            );
            mapContactDFR = DG_DFR_Class_Helper.getActiveDFRsForContacts(mapContactsToProcess.keySet());
            for (Contact con : mapContactsToProcess.values()) {
                ownerId = con.OwnerId;
                if (mapUsers.containsKey(con.OwnerId)) {
                    ownerName = mapUsers.get(con.OwnerId).Name;
                    owner = mapUsers.get(con.OwnerId);
                } else if (mapQueue.containsKey(con.OwnerId)) {
                    ownerName = mapQueue.get(con.OwnerId).Queue.Name;
                }
                newStage = mapContactStatusToStage.get(con.Contact_Status__c);
                oldStage = mapContactStatusToStage.get(mapOld.get(con.Id).Contact_Status__c);
                String oldStatus = mapOld.get(con.Id).Contact_Status__c;

                if (mapContactDFR.containsKey(con.Id)) {
                    Demand_Funnel__c dfr = mapContactDFR.get(con.Id);
                    oldStage = dfr.Pre_Opportunity_Status__c != null ? dfr.Pre_Opportunity_Status__c : oldStage;
                    if (oldStage.equals(DFRPROSPECT)) {
                        if (newStage.equals(DFRDOWNGRADED)) {
                            dfr = DG_DFR_Class_Helper.eolStatusChangeForContact(
                                dfr,
                                con,
                                owner,
                                ownerName,
                                OwnerId,
                                oldStage
                            );
                            dfr.Prospect_DateTime_Exited__c = DateTime.now();
                            dfr.Prospect_Exited_To__c = 'Downgraded';
                            dfrUpdate.add(dfr);
                        } else if (newStage.equals(DFRMQL)) {
                            dfr = DG_DFR_Class_Helper.mqlStatusChangeForContact(
                                dfr,
                                con,
                                owner,
                                ownerName,
                                OwnerId,
                                oldStage
                            );
                            dfr.Prospect_DateTime_Exited__c = DateTime.now();
                            dfr.Prospect_Exited_To__c = 'MQL';
                            dfr.Pre_Opportunity_Status__c = 'MQL';
                            dfr.MQL_Type__c = 'New';
                            dfrUpdate.add(dfr);
                        } else if (newStage.equals(DFRSAL)) {
                            dfr = DG_DFR_Class_Helper.mqlBackfillForContact(dfr, con, owner, ownerName, OwnerId);
                            dfrUpdate.add(dfr);
                            if (DG_DFR_Class_Helper.isBDRSDRNullUserByTeam(dfr.MQL_Owner_Team__c)) {
                                dfr = DG_DFR_Class_Helper.talStatusChangeForContact(
                                    dfr,
                                    con,
                                    owner,
                                    ownerName,
                                    OwnerId,
                                    oldStage
                                );
                                dfr.Prospect_Exited_To__c = 'TAL';
                                dfr.Prospect_DateTime_Exited__c = DateTime.now();
                                dfr.Pre_Opportunity_Status__c = 'TAL';
                            } else {
                                dfr = DG_DFR_Class_Helper.salStatusChangeForContact(
                                    dfr,
                                    con,
                                    owner,
                                    ownerName,
                                    OwnerId,
                                    oldStage
                                );
                                dfr.Prospect_Exited_To__c = 'SAL';
                                dfr.Prospect_DateTime_Exited__c = DateTime.now();
                                dfr.Pre_Opportunity_Status__c = 'SAL';
                                if (
                                    owner != null &&
                                    (owner.Profile.Name != null && !owner.Profile.Name.contains('SDR') ||
                                    owner.Profile.Name == null)
                                ) {
                                    dfr.SAL_Handoff_Date__c = Datetime.now();
                                    dfr.SAL_Handoff_Owner__c = owner.Name;
                                    dfr.SAL_Handoff_Owner_Role__c = owner.UserRoleName__c;
                                }
                            }
                        }
                    } else if (oldStage.equals(DFRMQL)) {
                        if (newStage.equals(DFRDOWNGRADED)) {
                            dfr = DG_DFR_Class_Helper.eolStatusChangeForContact(
                                dfr,
                                con,
                                owner,
                                ownerName,
                                OwnerId,
                                oldStage
                            );
                            dfr.MQL_DateTime_Exited__c = DateTime.now();
                            dfr.MQL_Exited_To__c = 'Downgraded';
                            dfrUpdate.add(dfr);
                        } else if (newStage.equals(DFRSAL)) {
                            dfrUpdate.add(dfr);
                            if (owner != null && DG_DFR_Class_Helper.isBDRSDRNullUserByTeam(owner.Team__c)) {
                                dfr = DG_DFR_Class_Helper.talStatusChangeForContact(
                                    dfr,
                                    con,
                                    owner,
                                    ownerName,
                                    OwnerId,
                                    oldStage
                                );
                                dfr.MQL_Exited_To__c = 'TAL';
                                dfr.MQL_DateTime_Exited__c = DateTime.now();
                                dfr.Pre_Opportunity_Status__c = 'TAL';
                            } else {
                                dfr = DG_DFR_Class_Helper.salStatusChangeForContact(
                                    dfr,
                                    con,
                                    owner,
                                    ownerName,
                                    OwnerId,
                                    oldStage
                                );
                                dfr.MQL_Exited_To__c = 'SAL';
                                dfr.MQL_DateTime_Exited__c = DateTime.now();
                                dfr.Pre_Opportunity_Status__c = 'SAL';
                                if (
                                    owner != null &&
                                    (owner.Profile.Name != null && !owner.Profile.Name.contains('SDR') ||
                                    owner.Profile.Name == null)
                                ) {
                                    dfr.SAL_Handoff_Date__c = Datetime.now();
                                    dfr.SAL_Handoff_Owner__c = owner.Name;
                                    dfr.SAL_Handoff_Owner_Role__c = owner.UserRoleName__c;
                                }
                            }
                        }
                    } else if (oldStage.equals(DFRSAL) || oldStage.equals(DFRTAL)) {
                        if (newStage.equals(DFRDOWNGRADED)) {
                            dfr = DG_DFR_Class_Helper.eolStatusChangeForContact(
                                dfr,
                                con,
                                owner,
                                ownerName,
                                OwnerId,
                                oldStage
                            );
                            if (oldStage.equals(DFRTAL)) {
                                dfr.TAL_DateTime_Exited__c = DateTime.now();
                                dfr.TAL_Exited_To__c = 'Downgraded';
                            } else {
                                dfr.SAL_DateTime_Exited__c = DateTime.now();
                                dfr.SAL_Exited_To__c = 'Downgraded';
                            }
                            dfrUpdate.add(dfr);
                        }
                    }
                } else {
                    Demand_Funnel__c dfr = new Demand_Funnel__c(
                        Contact__c = con.Id,
                        isCustomer__c = con.Customer_Record__c
                    );
                    dfr.DFR_Funnel_Type__c = 'Acquisition';
                    if (String.IsNotBlank(con.Contact_Funnel_Type__c)) {
                        if (mapContactTypeToFunnelType.containsKey(con.Contact_Funnel_Type__c.ToLowerCase())) {
                            dfr.DFR_Funnel_Type__c = mapContactTypeToFunnelType.get(
                                con.Contact_Funnel_Type__c.ToLowerCase()
                            );
                        }
                    }
                    if (newStage != null && newStage.equals(DFRPROSPECT)) {
                        dfr = DG_DFR_Class_Helper.prospectOnCreationForContact(dfr, con, owner, ownerName, ownerId);
                        dfr.Pre_Opportunity_Status__c = 'Prospect';
                        dfr.Prospect_Entered_From__c = 'Created';
                        dfrInsert.add(dfr);
                    } else if (newStage != null && newStage.equals(DFRMQL)) {
                        dfr = DG_DFR_Class_Helper.prospectBackfillForContact(dfr, con, owner, ownerName, ownerId);
                        dfr = DG_DFR_Class_Helper.mqlOnCreationForContact(dfr, con, owner, ownerName, ownerId);
                        dfr.Pre_Opportunity_Status__c = 'MQL';
                        dfr.MQL_Type__c = con.Contact_Status__c.equals(STATUS_RENEW) ||
                            (oldStatus != null &&
                            (oldStatus.equals(STATUS_DOWNGRADED) || oldStatus.equals(STATUS_CUSTOMER)))
                            ? 'Re-New'
                            : 'New';
                        if (mapQueue.containsKey(con.OwnerId)) {
                            dfr.MQL_Queue_Name__c = ownerName;
                        }
                        dfrInsert.add(dfr);
                    } else if (newStage != null && newStage.equals(DFRSAL)) {
                        dfr = DG_DFR_Class_Helper.prospectBackfillForContact(dfr, con, owner, ownerName, ownerId);
                        dfr = DG_DFR_Class_Helper.mqlBackfillForContact(dfr, con, owner, ownerName, ownerId);
                        dfr.MQL_Type__c = 'New';
                        if (mapQueue.containsKey(con.OwnerId)) {
                            dfr.MQL_Queue_Name__c = ownerName;
                        }

                        dfr.MQL_Type__c = (con.Contact_Status__c.equals(STATUS_RENEW) ||
                            (oldStatus != null &&
                            (oldStatus.equals(STATUS_DOWNGRADED) || oldStatus.equals(STATUS_CUSTOMER))))
                            ? 'Re-New'
                            : 'New';

                        if (DG_DFR_Class_Helper.isBDRSDRNullUserByTeam(dfr.MQL_Owner_Team__c)) {
                            dfr = DG_DFR_Class_Helper.talOnCreationForContact(dfr, con, owner, ownerName, ownerId);
                            dfr.Pre_Opportunity_Status__c = 'TAL';
                        } else {
                            dfr = DG_DFR_Class_Helper.salOnCreationForContact(dfr, con, owner, ownerName, ownerId);
                            dfr.Pre_Opportunity_Status__c = 'SAL';
                        }
                        dfrInsert.add(dfr);
                    }
                }
            }
            if (!dfrInsert.isEmpty()) {
                insert dfrInsert;
            }
            if (!dfrUpdate.isEmpty()) {
                update dfrUpdate;
            }
        } catch (Exception e) {
            DG_DFR_Class.dfrSaveException(e, null, null, listNew, null);
        }
    }

    public static void DFR_ChangeContactOwner(List<Contact> listNew, Map<Id, Contact> mapOld) {
        try {
            List<Demand_Funnel__c> dfrsToUpdate = new List<Demand_Funnel__c>();
            List<Demand_Funnel__c> dfrsToInsert = new List<Demand_Funnel__c>();
            List<Contact> contactsWithOwnerChanges = new List<Contact>();
            Set<Id> listOwnerId = new Set<Id>();
            Map<Id, Id> mapContactIdOpportunityId = new Map<Id, Id>();
            for (Contact con : listNew) {
                if (
                    con.Account_Brand__c != null &&
                    System.Label.BizMerge_Brand_Exclusion_List != null &&
                    System.Label.BizMerge_Brand_Exclusion_List.contains(con.Account_Brand__c)
                ) {
                    continue;
                }

                Contact oldCon = mapOld.get(con.Id);
                if (oldCon.OwnerId != con.OwnerId) {
                    listOwnerId.add(con.OwnerId);
                    mapContactIdOpportunityId.put(con.id, con.OwnerId);
                    contactsWithOwnerChanges.add(con);
                }
            }
            if (!contactsWithOwnerChanges.isEmpty()) {
                Map<Id, Demand_Funnel__c> mapDFR = DG_DFR_Class_Helper.getActiveDFRsForContacts(
                    mapContactIdOpportunityId.keySet()
                );
                Map<String, String> mapSysFullName = new Map<String, String>();

                for (String o : mapDFRSystemUsers.keySet()) {
                    String sysOwner = mapDFRSystemUsers.get(o);
                    mapSysFullName.put(sysOwner, sysOwner);
                }

                Map<Id, User> mapUsers = DG_DFR_Class_Helper.getUsersById(listOwnerId);
                Map<Id, QueueSobject> mapQueue = DG_DFR_Class_Helper.getMapOfQueues(listOwnerId, 'Contact');

                Map<Id, Contact> mapContactNew = new Map<Id, Contact>(contactsWithOwnerChanges);
                for (Contact con : contactsWithOwnerChanges) {
                    String stage = mapContactStatusToStage.get(con.Contact_Status__c);
                    Contact oldCon = mapOld.get(con.Id);
                    String ownerName;
                    String ownerId = con.OwnerId;
                    String oldConOwnerName;
                    String oldConOwnerId = oldCon.OwnerId;
                    User owner = new User();
                    if (mapUsers.containsKey(con.OwnerId)) {
                        ownerName = mapUsers.get(con.OwnerId).Name;
                        owner = mapUsers.get(con.OwnerId);
                    } else if (mapQueue.containsKey(con.OwnerId)) {
                        ownerName = mapQueue.get(con.OwnerId).Queue.Name;
                    }
                    Contact oldContact = mapOld.get(con.Id);
                    if (mapDFR.containsKey(con.Id)) {
                        Demand_Funnel__c dfr = mapDFR.get(con.Id);
                        if (
                            mapDFRSystemUsers.containsKey(oldContact.OwnerId) &&
                            !mapDFRSystemUsers.containsKey(con.OwnerId)
                        ) {
                            if (
                                dfr.SAL_DateTime_Entered__c != null && mapSysFullName.containsKey(dfr.SAL_Owner_Name__c)
                            ) {
                                dfr = DG_DFR_Class_Helper.SALOwnerMappingFromUser(dfr, owner, ownerName, ownerId);
                            }
                            if (
                                dfr.MQL_DateTime_Entered__c != null && mapSysFullName.containsKey(dfr.MQL_Owner_Name__c)
                            ) {
                                dfr = DG_DFR_Class_Helper.MQLOwnerMappingFromUser(dfr, owner, ownerName, ownerId);
                                if (
                                    DG_DFR_Class_Helper.isBDRSDRNullUserByTeam(dfr.MQL_Owner_Team__c) && stage == DFRSAL
                                ) {
                                    dfr = DG_DFR_Class_Helper.TALOwnerMappingFromUser(dfr, owner, ownerName, ownerId);
                                    dfr.Pre_Opportunity_Status__c = 'TAL';
                                    if (dfr.TAL_DateTime_Entered__c == null) {
                                        dfr = DG_DFR_Class_Helper.TALMasterMappingFromContact(dfr, con);
                                        dfr.Contact_Name_on_Creation__c =
                                            (con.FirstName != null && !String.isBlank(con.FirstName)
                                                ? con.FirstName + ' '
                                                : '') + con.LastName;
                                        dfr.Contact_Email_on_Creation__c = con.Email;
                                        if (dfr.SAL_Entered_From__c == DFRPROSPECT) {
                                            dfr.Prospect_Exited_To__c = DFRTAL;
                                        }
                                        if (dfr.SAL_Entered_From__c == DFRMQL) {
                                            dfr.MQL_Exited_To__c = DFRTAL;
                                        }
                                        if (dfr.TAL_Entered_From__c == null) {
                                            dfr.TAL_Entered_From__c = dfr.SAL_Entered_From__c;
                                        }
                                        if (DG_DFR_Class_Helper.isBDRSDRNullUserByTeam(owner.Team__c)) {
                                            dfr = DG_DFR_Class_Helper.setSALStampingToNull(dfr);
                                        }
                                    }
                                } else {
                                    dfr = DG_DFR_Class_Helper.setTALStampingToNull(dfr);
                                    if (stage.equals(DFRSAL)) {
                                        dfr = DG_DFR_Class_Helper.salOnCreationForContact(
                                            dfr,
                                            con,
                                            owner,
                                            ownerName,
                                            ownerId
                                        );
                                        dfr.Pre_Opportunity_Status__c = 'SAL';
                                        if (dfr.MQL_Exited_To__c != 'Backfilled') {
                                            dfr.MQL_Exited_To__c = DFRSAL;
                                            dfr.SAL_Entered_From__c = DFRMQL;
                                        }
                                    } else if (stage.equals(DFRMQL)) {
                                        dfr = DG_DFR_Class_Helper.mqlOnCreationForContact(
                                            dfr,
                                            con,
                                            owner,
                                            ownerName,
                                            ownerId
                                        );
                                        dfr.Pre_Opportunity_Status__c = 'MQL';
                                    }
                                }
                            }
                            if (
                                dfr.Prospect_DateTime_Entered__c != null &&
                                mapSysFullName.containsKey(dfr.Prospect_Owner_Name__c)
                            ) {
                                dfr = DG_DFR_Class_Helper.prospectOwnerMappingFromUser(dfr, owner, ownerName, ownerId);
                                if (
                                    stage.equals(DFRSAL) &&
                                    dfr.Prospect_Exited_To__c != 'Backfilled' &&
                                    dfr.TAL_Entered_From__c != DFRPROSPECT
                                ) {
                                    dfr.Prospect_Exited_To__c = DFRSAL;
                                }
                            }
                        }
                        if (
                            !mapDFRSystemUsers.containsKey(oldContact.OwnerId) &&
                            stage.equals(DFRSAL) &&
                            owner != null &&
                            !DG_DFR_Class_Helper.isBDRSDRNullUserByTeam(owner.Team__c)
                        ) {
                            if (
                                dfr.Pre_Opportunity_Status__c.equals(DFRPROSPECT) ||
                                dfr.Pre_Opportunity_Status__c.equals(DFRDOWNGRADED)
                            ) {
                                dfr = DG_DFR_Class_Helper.mqlBackfillForContact(dfr, con, owner, ownerName, ownerId);
                                if (mapQueue.containsKey(con.OwnerId)) {
                                    dfr.MQL_Queue_Name__c = mapQueue.get(con.OwnerId).Queue.Name;
                                }
                                dfr.MQL_Type__c = 'New';
                            }
                            if (
                                !dfr.Pre_Opportunity_Status__c.equals(DFRTAL) &&
                                DG_DFR_Class_Helper.isBDRSDRNullUserByTeam(dfr.MQL_Owner_Team__c)
                            ) {
                                if (
                                    dfr.Pre_Opportunity_Status__c.equals(DFRRENEW) ||
                                    dfr.Pre_Opportunity_Status__c.equals(DFRMQL) ||
                                    dfr.Pre_Opportunity_Status__c.equals(DFRPROSPECT) ||
                                    dfr.Pre_Opportunity_Status__c.equals(DFRDOWNGRADED)
                                ) {
                                    dfr = DG_DFR_Class_Helper.talMasterMappingFromContact(dfr, con);
                                    dfr = DG_DFR_Class_Helper.talOwnerMappingFromUser(dfr, owner, ownerName, ownerId);
                                    if (dfr.Pre_Opportunity_Status__c.equals(DFRMQL)) {
                                        dfr.MQL_DateTime_Exited__c = DateTime.now();
                                        dfr.MQL_Exited_To__c = 'TAL';
                                        dfr.TAL_Entered_From__c = 'MQL';
                                    } else if (dfr.Pre_Opportunity_Status__c.equals(DFRPROSPECT)) {
                                        dfr.Prospect_DateTime_Exited__c = DateTime.now();
                                        dfr.Prospect_Exited_To__c = 'TAL';
                                        dfr.TAL_Entered_From__c = 'Prospect';
                                    } else {
                                        dfr.Pre_Opportunity_Status__c = 'TAL';
                                    }
                                }
                            } else if (
                                dfr.Pre_Opportunity_Status__c.equals(DFRRENEW) ||
                                dfr.Pre_Opportunity_Status__c.equals(DFRMQL) ||
                                dfr.Pre_Opportunity_Status__c.equals(DFRPROSPECT) ||
                                dfr.Pre_Opportunity_Status__c.equals(DFRDOWNGRADED) ||
                                dfr.Pre_Opportunity_Status__c.equals(DFRTAL) ||
                                dfr.Pre_Opportunity_Status__c.equals(DFRTQL)
                            ) {
                                if (
                                    dfr.Pre_Opportunity_Status__c.equals(DFRTAL) &&
                                    dfr.TAL_DateTime_Entered__c != null &&
                                    ((!String.isEmpty(dfr.MQL_Owner_Team__c) &&
                                    (dfr.MQL_Owner_Team__c.contains(DFRSDR) ||
                                    dfr.MQL_Owner_Team__c.contains(DFRBDR))) ||
                                    (String.isEmpty(dfr.MQL_Owner_Team__c) && dfr.MQL_DateTime_Entered__c != null))
                                ) {
                                    dfr = DG_DFR_Class_Helper.tqlMasterMappingFromContact(dfr, con);
                                    dfr = DG_DFR_Class_Helper.tqlOwnerMappingFromUser(dfr, owner, ownerName, ownerId);
                                    dfr.TQL_DateTime_Exited__c = DateTime.now();
                                    dfr.TQL_Entered_From__c = 'TAL';
                                    dfr.TQL_Exited_To__c = 'SAL';
                                    dfr.TAL_DateTime_Exited__c = DateTime.now();
                                    dfr.TAL_Exited_To__c = 'TQL';
                                    dfr.SAL_Entered_From__c = 'TQL';
                                    dfr.TQL_Owner_Name__c = oldConOwnerName;
                                    dfr.TQL_Owner_Id__c = oldConOwnerId;
                                } else if (dfr.Pre_Opportunity_Status__c.equals(DFRMQL)) {
                                    dfr.MQL_DateTime_Exited__c = DateTime.now();
                                    dfr.MQL_Exited_To__c = 'SAL';
                                    dfr.SAL_Entered_From__c = 'MQL';
                                } else if (dfr.Pre_Opportunity_Status__c.equals(DFRPROSPECT)) {
                                    dfr.Prospect_DateTime_Exited__c = DateTime.now();
                                    dfr.Prospect_Exited_To__c = 'SAL';
                                    dfr.SAL_Entered_From__c = 'Prospect';
                                }
                                if (
                                    dfr.Pre_Opportunity_Status__c.equals(DFRTAL) && dfr.TQL_Exited_To__c.equals(DFRSAL)
                                ) {
                                    dfr = DG_DFR_Class_Helper.salMasterMappingFromContact(dfr, con);
                                    dfr = DG_DFR_Class_Helper.salOwnerMappingFromUser(dfr, owner, ownerName, ownerId);
                                    dfr.Pre_Opportunity_Status__c = 'SAL';
                                }
                            }
                        }
                        dfrsToUpdate.add(dfr);
                    } else if (
                        !mapDFRSystemUsers.containsKey(oldContact.OwnerId) &&
                        stage.equals(DFRSAL) &&
                        owner != null &&
                        !DG_DFR_Class_Helper.isBDRSDRNullUserByTeam(owner.Team__c)
                    ) {
                        Demand_Funnel__c dfr = new Demand_Funnel__c(
                            Contact__c = con.Id,
                            isCustomer__c = con.Customer_Record__c
                        );
                        if (String.IsNotBlank(con.Contact_Funnel_Type__c)) {
                            if (mapContactTypeToFunnelType.containsKey(con.Contact_Funnel_Type__c.ToLowerCase())) {
                                dfr.DFR_Funnel_Type__c = mapContactTypeToFunnelType.get(
                                    con.Contact_Funnel_Type__c.ToLowerCase()
                                );
                            }
                        }
                        dfr = DG_DFR_Class_Helper.prospectBackfillForContact(dfr, con, owner, ownerName, ownerId);
                        dfr = DG_DFR_Class_Helper.mqlBackfillForContact(dfr, con, owner, ownerName, ownerId);
                        dfr.MQL_Type__c = 'New';
                        if (DG_DFR_Class_Helper.isBDRSDRNullUserByTeam(dfr.MQL_Owner_team__c)) {
                            dfr = DG_DFR_Class_Helper.salOnCreationForContact(dfr, con, owner, ownerName, ownerId);
                            dfr.Pre_Opportunity_Status__c = 'SAL';
                        } else {
                            dfr = DG_DFR_Class_Helper.talOnCreationForContact(dfr, con, owner, ownerName, ownerId);
                            dfr.Pre_Opportunity_Status__c = 'TAL';
                        }
                        dfrsToInsert.add(dfr);
                    }
                }
                if (!dfrsToInsert.isEmpty()) {
                    insert dfrsToInsert;
                }
                if (!dfrsToUpdate.isEmpty()) {
                    update dfrsToUpdate;
                }
            }
        } catch (Exception e) {
            if (listNew != null && listNew.size() > 25) {
                throw e;
            } else {
                dfrSaveException(e, null, null, listNew, null);
            }
        }
    }

    public static void DFR_OpportunityOwnerChange(List<Opportunity> newOpps, Map<Id, Opportunity> mapOldOpps) {
        Set<Id> listOwnerId = new Set<Id>();
        Map<Id, Id> mapOppIDOwnerID = new Map<Id, Id>();
        Map<Id, Demand_Funnel__c> dfrsToUpdate = new Map<Id, Demand_Funnel__c>();
        try {
            for (Opportunity opp : newOpps) {
                if (
                    opp.Brand_Name__c != null &&
                    System.Label.BizMerge_Brand_Exclusion_List != null &&
                    System.Label.BizMerge_Brand_Exclusion_List.contains(opp.Brand_Name__c)
                ) {
                    continue;
                }
                Opportunity oldOpp = mapOldOpps.get(opp.Id);
                if (oldOpp.OwnerId != opp.OwnerId) {
                    listOwnerId.add(opp.OwnerId);
                    mapOppIDOwnerID.put(opp.id, opp.OwnerId);
                }
            }

            if (!mapOppIDOwnerID.isEmpty()) {
                List<Demand_Funnel__c> listDFR = (List<Demand_Funnel__c>) new DemandFunnelSelector()
                    .selectActiveDFRByOpportunitiesId(new List<Object>{ mapOppIDOwnerID.keySet() })
                    .executeQuery();

                if (!listDFR.isEmpty()) {
                    Map<Id, User> mapUsers = DG_DFR_Class_Helper.getUsersById(listOwnerId);
                    Map<Id, QueueSobject> mapQueue = DG_DFR_Class_Helper.getMapOfQueues(listOwnerId, 'Opportunity');

                    for (Demand_Funnel__c dfr : listDFR) {
                        String ownerName;
                        String ownerId;
                        User owner = new User();
                        if (mapOppIDOwnerID.containsKey(dfr.Opportunity__c)) {
                            Id oppOwnerId = mapOppIDOwnerID.get(dfr.Opportunity__c);
                            if (mapUsers.containsKey(oppOwnerId)) {
                                ownerName = mapUsers.get(oppOwnerId).Name;
                                ownerId = oppOwnerId;
                                owner = mapUsers.get(oppOwnerId);
                            } else if (mapQueue.containsKey(oppOwnerId)) {
                                ownerName = mapQueue.get(oppOwnerId).Queue.Name;
                                ownerId = mapQueue.get(oppOwnerId).QueueId;
                            }
                            if (
                                DG_DFR_Class_Helper.isBDRSDRNullUserByTeam(dfr.SQL_Owner_Team__c) &&
                                !DG_DFR_Class_Helper.isBDRSDRNullUserByTeam(owner.Team__c)
                            ) {
                                DG_DFR_Class_Helper.SQLOwnerMappingFromUser(dfr, owner, ownerName, ownerId);
                                dfrsToUpdate.put(dfr.id, dfr);
                            }
                            if (
                                DG_DFR_Class_Helper.isBDRSDRNullUserByTeam(dfr.SAL_Owner_Team__c) &&
                                !DG_DFR_Class_Helper.isBDRSDRNullUserByTeam(owner.Team__c)
                            ) {
                                DG_DFR_Class_Helper.SALOwnerMappingFromUser(dfr, owner, ownerName, ownerId);
                                dfrsToUpdate.put(dfr.id, dfr);
                            }
                        }
                    }
                    if (!dfrsToUpdate.isEmpty()) {
                        update dfrsToUpdate.values();
                    }
                }
            }
        } catch (Exception e) {
            dfrSaveException(e, null, null, null, newOpps);
        }
    }

    public static void DFR_OpportunityPipelineRecalculation(List<Opportunity> oppsToProcess) {
        List<Demand_Funnel__c> dfrsToUpdate = New List<Demand_Funnel__c>();        
        Set<Id> oppsToQuery = new Set<Id>();
        for (Opportunity opp : oppsToProcess) {
            oppsToQuery.add(opp.Id);
        }
        List<Demand_Funnel__c> dfrs = (List<Demand_Funnel__c>) new DemandFunnelSelector()
                    .selectDFRByOpportunitiesId(new List<Object>{oppsToQuery})
                    .selectField('CurrencyIsoCode')
                    .executeQuery();
        if (!dfrs.isEmpty()) {
            dfrsToUpdate = DG_DFR_Class_Helper.DFRPipelineRecalculation(dfrs, oppsToProcess);
            update dfrsToUpdate;
        }    
    }

    public static void SMEmployeesUpdate(Set<Id> idSet) {
        try {
            List<Demand_Funnel__c> dfrsToUpdate = getDFRsWithUpdatedSMEmployeesField(idSet);

            if (!dfrsToUpdate.isEmpty()) {
                update dfrsToUpdate;
            }
        } catch (Exception e) {
            DG_DFR_Class.dfrSaveException(e, null, null, null, null);
        }
    }

    public static List<Demand_Funnel__c> getDFRsWithUpdatedSMEmployeesField(List<Demand_Funnel__c> dfrs) {
        List<Demand_Funnel__c> dfrsToUpdate = new List<Demand_Funnel__c>();

        for (Demand_Funnel__c dfr : dfrs) {
            Decimal oldSmEmployees = dfr.SM_Employees__c;

            if (dfr.Opportunity__r?.Account?.SM_Employees__c != null) {
                dfr.SM_Employees__c = dfr.Opportunity__r.Account.SM_Employees__c;
            } else if (dfr.Contact__r?.Account?.SM_Employees__c != null) {
                dfr.SM_Employees__c = dfr.Contact__r.Account.SM_Employees__c;
            } else if (dfr.Lead__c != null) {
                if (dfr.Lead__r.ZI_CDP_Account_Id__r != null) {
                    dfr.SM_Employees__c = dfr.Lead__r.ZI_CDP_Account_Id__r.SM_Employees__c;
                } else {
                    dfr.SM_Employees__c = dfr.Lead__r.SM_Employees__c;
                }
            }

            if (oldSmEmployees != dfr.SM_Employees__c) {
                dfrsToUpdate.add(dfr);
            }
        }

        return dfrsToUpdate;
    }

    public static List<Demand_Funnel__c> getDFRsWithUpdatedSMEmployeesField(Set<Id> ids) {
        List<Demand_Funnel__c> dfrsToCheckSMEmployees = new DemandFunnelSelector()
            .selectDFRByLeadAccountOrOpportunity(new List<Object>{ ids })
            .selectField('Contact__r.Account.SM_Employees__c')
            .selectField('Lead__r.ZI_CDP_Account_Id__r.SM_Employees__c')
            .executeQuery();

        return getDFRsWithUpdatedSMEmployeesField(dfrsToCheckSMEmployees);
    }

    public static List<Demand_Funnel__c> getDFRsWithupdatedAccountField(List<Demand_Funnel__c> dfrs) {
        List<Demand_Funnel__c> dfrsToUpdate = new List<Demand_Funnel__c>();

        for (Demand_Funnel__c dfr : dfrs) {
            Id oldAccountId = dfr.Account__c;

            if (dfr.Opportunity__r?.AccountId != null) {
                dfr.Account__c = dfr.Opportunity__r.AccountId;
            } else if (dfr.Contact__r?.AccountId != null) {
                dfr.Account__c = dfr.Contact__r.AccountId;
            } else {
                dfr.Account__c = dfr.Lead__r?.ZI_CDP_Account_Id__c;
            }

            if (oldAccountId != dfr.Account__c) {
                dfrsToUpdate.add(dfr);
            }
        }

        return dfrsToUpdate;
    }

    public static List<Demand_Funnel__c> getDFRsWithUpdatedAccountField(Set<Id> ids) {
        List<Demand_Funnel__c> dfrToCheckAccountField = new DemandFunnelSelector()
            .selectDFRForAccountUpdate(new List<Object>{ ids })
            .executeQuery();

        return getDFRsWithupdatedAccountField(dfrToCheckAccountField);
    }

    private static Map<String, CohortFieldmapping__c> getCohortCS() {
        Map<String, CohortFieldmapping__c> mapCohortCS = new Map<String, CohortFieldmapping__c>();
        if (!test.isRunningTest()) {
            mapCohortCS = CohortFieldmapping__c.getAll();
        } else {
            mapCohortCS.put(
                '1',
                new CohortFieldmapping__c(name = '1', Source_Field__c = 'LeadSource', Target_Field__c = 'Description')
            );
        }

        return mapCohortCS;
    }

    private static Map<String, String> CohortFieldmapping() {
        Map<String, Schema.SObjectField> mapLSchema = Schema.SObjectType.Lead.fields.getmap();
        Map<String, CohortFieldmapping__c> mapCohortFieldmapping = getCohortCS();
        Map<String, String> mapFieldmapping = new Map<String, String>();

        for (String k : mapCohortFieldmapping.keySet()) {
            String sourceField = mapCohortFieldmapping.get(k).Source_Field__c;
            String targetField = mapCohortFieldmapping.get(k).Target_Field__c;

            if (sourceField <> null && sourceField <> null) {
                sourceField = sourceField.trim();
                targetField = targetField.trim();
                if (mapLSchema.containsKey(sourceField) && mapLSchema.containsKey(targetField)) {
                    Schema.DescribeFieldResult TargetDescribe = mapLSchema.get(targetField).getDescribe();
                    if (TargetDescribe.isUpdateable()) {
                        mapFieldmapping.put(sourceField, targetField);
                    }
                }
            }
        }
        return mapFieldmapping;
    }

    private static void populateCohortData(List<Lead> lds) {
        Map<String, String> mapCohortFieldmapping = CohortFieldmapping();

        for (Lead l : lds) {
            for (String k : mapCohortFieldmapping.keySet()) {
                l.put(mapCohortFieldmapping.get(k), l.get(k));
            }
        }
    }

    public static void FirstHandRaise_OnInsert(List<Lead> tn) {
        List<Lead> listLead = new List<Lead>();
        for (integer i = 0; i < tn.size(); i++) {
            listLead.add(tn[i]);
        }

        if (!listLead.isEmpty()) {
            populateCohortData(listLead);
        }
    }

    public void DowngradeContactsAndDFRs() {
        map<Id, Contact> mapCon = new Map<Id, Contact>();
        try {
            Datetime dateFilter = datetime.now() - getDFRAutoDeactivationDays();
            Set<Id> setConId = new Set<Id>();
            map<Id, Demand_Funnel__c> mapDFR = new Map<Id, Demand_Funnel__c>();

            for (Demand_Funnel__c d : 
                (List<Demand_Funnel__c>) new DemandFunnelSelector()
                    .selectDFRsForDowngrade(new List<Object>{ dateFilter })
                    .executeQuery()
            ) {
                setConId.add(d.Contact__c);
                mapDFR.put(d.id, new Demand_Funnel__c(Id = d.Id, EOL_Downgrade_Reason__c = 'No Sales Response'));
            }

            if (setConId.size() > 0) {
                for (Id CId : setConId) {
                    mapCon.put(CId, new Contact(Id = CId, Contact_Status__c = 'Downgraded'));
                }

                if (mapCon.size() > 0) {
                    update mapCon.values();
                }

                if (mapDFR.size() > 0) {
                    update mapDFR.values();
                }
            }
        } catch (Exception e) {
            dfrSaveException(e, null, null, mapCon.values(), null);
        }
    }

    public static integer getDFRAutoDeactivationDays() {
        integer Days;

        if (!test.isRunningTest()) {
            try {
                Days = Integer.valueOf(System.Label.DFR_Auto_Deactivation_Days);
            } catch (exception e) {
                Days = 21;
            }
        } else {
            Days = 0;
        }

        return Days;
    }

    public static void dfrSaveException(
        Exception dfrException,
        Id LeadId,
        List<Lead> Leads,
        List<Contact> Contacts,
        List<Opportunity> Opportunities
    ) {
        Id dfrExceptionRecordType = Schema.SObjectType.Exception_And_Notification_History__c
            .getRecordTypeInfosByName()
            .get('DFR Exception Log')
            .getRecordTypeId();
        String ExceptionType = dfrException.getTypeName();

        if (Contacts != null) {
            dfrExceptionObject = 'Contact';
            for (Contact con : Contacts) {
                dfrExceptionRecords += con.Id + ' \r\n';
            }
        } else if (Opportunities != null) {
            dfrExceptionObject = 'Opportunity';
            for (Opportunity opp : Opportunities) {
                dfrExceptionRecords += opp.Id + ' \r\n';
            }
        }

        if (LeadId != null) {
            dfrExceptionObject = 'Lead';
            dfrExceptionRecords += LeadId;
        } else if (Leads != null) {
            dfrExceptionObject = 'Lead';
            for (Lead ld : Leads) {
                dfrExceptionRecords += ld.Id + ' \r\n';
            }
        }

        dfrExceptionRecords = dfrExceptionRecords.removeEnd(',');
        dfrExceptionMessage +=
            'MODULE : DFR ' +
            ' \r\n' +
            'LINE : ' +
            dfrException.getLineNumber() +
            ' \r\n' +
            'MESSAGE : ' +
            dfrException.getMessage() +
            ' \r\n' +
            'STACK TRACE : ' +
            dfrException.getStackTraceString() +
            ' \r\n' +
            'TYPE : ' +
            dfrException.getTypeName() +
            ' \r\n';

        if (dfrException.getTypeName() == 'System.DmlException') {
            ExceptionType = 'Error on Insert or Update';
            dfrExceptionMessage +=
                '#################### DML EXCEPTION HAS OCCURRED #####################' +
                ' \r\n' +
                'NUMBER OF AFFECTED ROWS : ' +
                dfrException.getNumDml() +
                ' \r\n' +
                '=====================================================================' +
                ' \r\n';

            for (Integer i = 0; i < dfrException.getNumDml(); i++) {
                dfrExceptionMessage +=
                    'DML EXCEPTION : ' +
                    (i + 1) +
                    ' \r\n' +
                    '=====================================================================' +
                    ' \r\n' +
                    'TYPE : ' +
                    dfrException.getDmlType(i) +
                    ' \r\n' +
                    'MESSAGE  : ' +
                    dfrException.getDmlMessage(i) +
                    ' \r\n' +
                    'FAILED ROW POSITION : ' +
                    dfrException.getDmlIndex(i) +
                    ' \r\n' +
                    'FAILED RECORD ID : ' +
                    dfrException.getDmlId(i) +
                    ' \r\n' +
                    'FIELD NAMES : ' +
                    dfrException.getDmlFieldNames(i) +
                    ' \r\n' +
                    '=====================================================================' +
                    ' \r\n';
            }
        }
        insert new Exception_And_Notification_History__c(
            Exception__c = ExceptionType,
            Exception_Desc__c = dfrExceptionMessage,
            RecordTypeId = dfrExceptionRecordType,
            Object_Type__c = dfrExceptionObject,
            Affected_record_ID__c = dfrExceptionRecords
        );
    }
}