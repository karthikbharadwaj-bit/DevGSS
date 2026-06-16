public class TaskTriggerHelper {
    public static void populateDFRActivityFields(List<Task> tasks) {
        Map<Id, Task> mapCompletedTasks = new Map<Id, Task>();
        mapCompletedTasks = getCompletedTasks(tasks);
        if (!mapCompletedTasks.isEmpty()) {
            populateDFRs(mapCompletedTasks);
        }
    }

    public static Boolean dfrNeedsToBePopulated(Task task, Demand_Funnel__c dfr) {
        Boolean isPopulationNeeded = false;
        Boolean isSalDateEmpty = dfr.SAL_DateTime_Entered__c == null;
        Boolean isEolDateEmpty = dfr.EOL_DateTime_Entered__c == null;
        Boolean isMqlDateGreater = dfr.MQL_DateTime_Entered__c != null && task.CreatedDate > dfr.MQL_DateTime_Entered__c;
        Boolean isSalDateLesser = !isSalDateEmpty && task.CreatedDate < dfr.SAL_DateTime_Entered__c;
        Boolean isEolDateLesser =  !isEolDateEmpty && task.CreatedDate < dfr.EOL_DateTime_Entered__c;
        Boolean isCreatedDateGreaterThanSal = task.CreatedDate > dfr.SAL_DateTime_Entered__c;

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

    public static void populateDFRs(Map<Id, Task> mapTask) {
        List<Demand_Funnel__c> dfrsToPopulate = new List<Demand_Funnel__c>();
        for (
            Demand_Funnel__c dfr : (List<Demand_Funnel__c>) new DemandFunnelSelector()
                .selectDFRByLeadOrContact(new List<Object>{ mapTask.keySet() })
                .executeQuery()
        ) {
            if (mapTask.get(dfr.Contact__c) != null && dfrNeedsToBePopulated(mapTask.get(dfr.Contact__c), dfr)) {
                dfr.First_Activity_ID_after_MQL__c = mapTask.get(dfr.Contact__c).Id;
                dfr.First_Activity_DateTime_after_MQL__c = datetime.now();
                dfr.First_Activity_Name_after_MQL__c = mapTask.get(dfr.Contact__c).Subject;
                dfrsToPopulate.add(dfr);
            } else if (mapTask.get(dfr.Lead__c) != null && dfrNeedsToBePopulated(mapTask.get(dfr.Lead__c), dfr)) {
                dfr.First_Activity_ID_after_MQL__c = mapTask.get(dfr.Lead__c).Id;
                dfr.First_Activity_DateTime_after_MQL__c = datetime.now();
                dfr.First_Activity_Name_after_MQL__c = mapTask.get(dfr.Lead__c).Subject;
                dfrsToPopulate.add(dfr);
            }
        }
        try {
            update dfrsToPopulate;
        } catch (Exception e) {
            ExceptionHelper.createExceptionAndNotificacionHistory(e, dfrsToPopulate, 'DFR Exception Log');
        }
    }

    public static Map<Id, Task> getCompletedTasks(List<Task> tasks) {
        Map<Id, Task> mapTask = new Map<Id, Task>();
        List<String> excludedValues = getExcludedValues();
        for (Task task : tasks) {
            if ('Completed'.equalsIgnoreCase(task.Status) && !excludedValues.contains(task.Subject) && task.WhoId != null) {
                mapTask.put(task.WhoId, task);
            }
        }
        return mapTask;
    }

    public static List<String> getExcludedValues() {
        List<Excludad_Values_For_DFR_Activity__mdt> excludedValuesMdt = [
            SELECT Excluded_Value__c
            FROM Excludad_Values_For_DFR_Activity__mdt
            WHERE ObjectType__c = 'Task'
        ];
        List<String> excludedValues = new List<String>();
        for (Excludad_Values_For_DFR_Activity__mdt value : excludedValuesMdt) {
            excludedValues.add(value.Excluded_Value__c);
        }
        return excludedValues;
    }
}