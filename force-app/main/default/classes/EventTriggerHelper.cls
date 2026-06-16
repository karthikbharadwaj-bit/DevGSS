public class EventTriggerHelper {
    public static Schema.describeSObjectResult DESCRIBE {
        get {
            if(DESCRIBE == null) {
                DESCRIBE = Event.SObjectType.getDescribe();
            }
            return DESCRIBE;
        }
        set;
    }

    public static Map<String, Schema.RecordTypeInfo> RT_INFO_BY_NAME {
        get {
            if(RT_INFO_BY_NAME == null) {
                RT_INFO_BY_NAME = DESCRIBE.getRecordTypeInfosByName();
            }
            return RT_INFO_BY_NAME;
        }
        set;
    }

    public static final String RT_NAME_SE_EVENT = 'SE Event';
    public static final String RT_NAME_VIP_EVENT = 'VIP Event';
    public static final String RT_NAME_ENT_MAJ_MM_EVENT = 'Ent/Maj/MM';
    public static final String RT_NAME_CE_EVENT = 'CE';
    public static final String RT_NAME_SECURITY_EVENT = 'Security';
    public static final String RT_NAME_CX_EVENT = 'CX';
    public static final String RT_NAME_AU_EMEA_EVENT = 'AU/EMEA';
    public static final String RT_NAME_ASE_COE_EVENT = 'ASE/CoE';
    public static final String RT_NAME_APPS_EVENT = 'APPS';
    public static final String RT_NAME_RCV_EVENT = 'RCV';
    public static final String RT_NAME_SB_EVENT = 'SB';
    public static final String RT_NAME_MITEL_EVENT = 'Mitel';
    public static final String RT_NAME_CHANNEL_EVENT = 'Channel';
    public static final String RT_NAME_EXPANSION_EVENT = 'Expansion';

    public static final Id RT_ID_SE_EVENT = RT_INFO_BY_NAME.get(RT_NAME_SE_EVENT).getRecordTypeId();
    public static final Id RT_ID_VIP_EVENT = RT_INFO_BY_NAME.get(RT_NAME_VIP_EVENT).getRecordTypeId();
    public static final Id RT_ID_ENT_MAJ_MM_EVENT = RT_INFO_BY_NAME.get(RT_NAME_ENT_MAJ_MM_EVENT).getRecordTypeId();
    public static final Id RT_ID_CE_EVENT = RT_INFO_BY_NAME.get(RT_NAME_CE_EVENT).getRecordTypeId();
    public static final Id RT_ID_SB_EVENT = RT_INFO_BY_NAME.get(RT_NAME_SB_EVENT).getRecordTypeId();
    public static final Id RT_ID_SECURITY_EVENT = RT_INFO_BY_NAME.get(RT_NAME_SECURITY_EVENT).getRecordTypeId();
    public static final Id RT_ID_CX_EVENT = RT_INFO_BY_NAME.get(RT_NAME_CX_EVENT).getRecordTypeId();
    public static final Id RT_ID_MITEL_EVENT = RT_INFO_BY_NAME.get(RT_NAME_MITEL_EVENT).getRecordTypeId();
    public static final Id RT_ID_AU_EMEA_EVENT = RT_INFO_BY_NAME.get(RT_NAME_AU_EMEA_EVENT).getRecordTypeId();
    public static final Id RT_ID_ASE_COE_EVENT = RT_INFO_BY_NAME.get(RT_NAME_ASE_COE_EVENT).getRecordTypeId();
    public static final Id RT_ID_APPS_EVENT = RT_INFO_BY_NAME.get(RT_NAME_APPS_EVENT).getRecordTypeId();
    public static final Id RT_ID_RCV_EVENT = RT_INFO_BY_NAME.get(RT_NAME_RCV_EVENT).getRecordTypeId();
    public static final Id RT_ID_CHANNEL_EVENT = RT_INFO_BY_NAME.get(RT_NAME_CHANNEL_EVENT).getRecordTypeId();
    public static final Id RT_ID_EXPANSION_EVENT = RT_INFO_BY_NAME.get(RT_NAME_EXPANSION_EVENT).getRecordTypeId();

    public static final List<Id> RT_IDS_EVENT = new List<Id> {
        RT_ID_SE_EVENT,
        RT_ID_VIP_EVENT,
        RT_ID_ENT_MAJ_MM_EVENT,
        RT_ID_CE_EVENT,
        RT_ID_SB_EVENT,
        RT_ID_SECURITY_EVENT,
        RT_ID_CX_EVENT,
        RT_ID_MITEL_EVENT,
        RT_ID_AU_EMEA_EVENT,
        RT_ID_ASE_COE_EVENT,
        RT_ID_APPS_EVENT,
        RT_ID_RCV_EVENT,
        RT_ID_CHANNEL_EVENT,
        RT_ID_EXPANSION_EVENT
    };

    public static void populateDFRActivityFields(List<Event> events) {
        Map<Id, Event> mapEvents = new Map<Id, Event>();
        mapEvents = getNotExcludadEvents(events);
        if (!mapEvents.isEmpty()) {
            populateDFRs(mapEvents);
        }
    }

    public static Boolean dfrNeedsToBePopulated(Event event, Demand_Funnel__c dfr) {
        Boolean isPopulationNeeded = false;
        Boolean isSalDateEmpty = dfr.SAL_DateTime_Entered__c == null;
        Boolean isEolDateEmpty = dfr.EOL_DateTime_Entered__c == null;
        Boolean isMqlDateGreater = dfr.MQL_DateTime_Entered__c != null && event.CreatedDate > dfr.MQL_DateTime_Entered__c;
        Boolean isSalDateLesser = !isSalDateEmpty && event.CreatedDate < dfr.SAL_DateTime_Entered__c;
        Boolean isEolDateLesser =  !isEolDateEmpty && event.CreatedDate < dfr.EOL_DateTime_Entered__c;
        Boolean isCreatedDateGreaterThanSal = event.CreatedDate > dfr.SAL_DateTime_Entered__c;

        if (isMqlDateGreater && isEolDateEmpty && isSalDateEmpty) {
            isPopulationNeeded = true;
        }
        if (isMqlDateGreater && isSalDateLesser && isEolDateLesser) {
            isPopulationNeeded = true;
        }
        if (isMqlDateGreater && isSalDateLesser && isEolDateEmpty) {
            isPopulationNeeded = true;
        }
        if (isMqlDateGreater && isEolDateLesser && isSalDateEmpty) {
            isPopulationNeeded = true;
        }
        if (isMqlDateGreater && isCreatedDateGreaterThanSal && isEolDateEmpty) {
            isPopulationNeeded = true;
        }

        return isPopulationNeeded;
    }

    public static void populateDFRs(Map<Id, Event> mapEvent) {
        List<Demand_Funnel__c> dfrsToPopulate = new List<Demand_Funnel__c>();
        for (
            Demand_Funnel__c dfr : (List<Demand_Funnel__c>) new DemandFunnelSelector()
                .selectDFRByLeadOrContact(new List<Object>{ mapEvent.keySet() })
                .executeQuery()
        ) {
            if (mapEvent.get(dfr.Contact__c) != null && dfrNeedsToBePopulated(mapEvent.get(dfr.Contact__c), dfr)) {
                dfr.First_Activity_ID_after_MQL__c = mapEvent.get(dfr.Contact__c).Id;
                dfr.First_Activity_DateTime_after_MQL__c = datetime.now();
                dfr.First_Activity_Name_after_MQL__c = mapEvent.get(dfr.Contact__c).Subject;
                dfrsToPopulate.add(dfr);
            } else if (mapEvent.get(dfr.Lead__c) != null && dfrNeedsToBePopulated(mapEvent.get(dfr.Lead__c), dfr)) {
                dfr.First_Activity_ID_after_MQL__c = mapEvent.get(dfr.Lead__c).Id;
                dfr.First_Activity_DateTime_after_MQL__c = datetime.now();
                dfr.First_Activity_Name_after_MQL__c = mapEvent.get(dfr.Lead__c).Subject;
                dfrsToPopulate.add(dfr);
            }
        }
        try {
            update dfrsToPopulate;
        } catch (Exception e) {
            ExceptionHelper.createExceptionAndNotificacionHistory(e, dfrsToPopulate, 'DFR Exception Log');
        }
    }

    public static Map<Id, Event> getNotExcludadEvents(List<Event> events) {
        Map<Id, Event> mapEvent = new Map<Id, Event>();
        List<String> excludedValues = getExcludedValues();
        for (Event event : events) {
            if (!excludedValues.contains(event.Subject) && event.WhoId != null) {
                mapEvent.put(event.WhoId, event);
            }
        }
        return mapEvent;
    }

    public static List<String> getExcludedValues() {
        List<Excludad_Values_For_DFR_Activity__mdt> excludedValuesMdt = [
            SELECT Excluded_Value__c
            FROM Excludad_Values_For_DFR_Activity__mdt
            WHERE ObjectType__c = 'Event'
        ];
        List<String> excludedValues = new List<String>();
        for (Excludad_Values_For_DFR_Activity__mdt value : excludedValuesMdt) {
            excludedValues.add(value.Excluded_Value__c);
        }
        return excludedValues;
    }
}