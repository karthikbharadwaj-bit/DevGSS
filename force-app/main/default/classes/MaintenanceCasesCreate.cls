public class MaintenanceCasesCreate {
    @TestVisible
    private static final String LABEL_MAP_UID_AND_ACCOUNTID = 'mapUIDAndAccountId';
    @TestVisible
    private static final String LABEL_MAP_FIELD_AND_PICKLIST_VALUES = 'picklistNameAndValues';
    private static final String LABEL_ERROR_WHILE_PROCESS_MAINTENANCE = 'Error while process Maintenance:';
    @TestVisible
    private static final String LABEL_DUBLICATE_MAINTENANCE = 'Maintenance is duplicated. Id from org is:';
    @TestVisible
    private static final String LABEL_DUBLICATE_INSERT_MAINTENANCE = 'Maintenance is duplicated';
    @TestVisible
    private static Map<String, String> fieldAPINameToObject = new Map<String, String>{
        'Priority' => 'Case',
        'Status' => 'Case',
        'Origin' => 'Case',
        'inContact_Cluster__c' => 'Account'
    };

    @TestVisible
    private static final Id MAINTENANCE_OWNER_ID = UserInfo.getUserId();
    @TestVisible
    private static final Id MAINTENANCE_RECORD_TYPE_ID = CaseHelper.RT_ID_MAINTENANCE_CASE;

    private static List<String> ACCOUNT_UID_SEARCH_FIELDS = new List<String>{'Id', 'RC_User_Id__c'};
    private static String ACCOUNT_UID_CONDITION = 'RC_User_Id__c IN :bind0';

    private static List<String> CASE_FROM_ORG_SEARCH_FIELDS = new List<String>{
        'Id',
        'Subject',
        'AccountId',
        'Date_Assigned__c'
    };
    private static String CASE_FROM_ORG_CONDITION =
        'RecordTypeId = \'' + MAINTENANCE_RECORD_TYPE_ID + '\'' +
        ' AND OwnerId = \'' + MAINTENANCE_OWNER_ID + '\'' +
        ' AND AccountId IN :bind0 AND Date_Assigned__c IN :bind1 AND Subject IN :bind2';

    @AuraEnabled(cacheable=true)
    public static Response getMapUIDAndAccountId(String request) {
        Response res = new Response();
        try {
            List<String> listOfUIDs = (List<String>) JSON.deserialize(request, List<String>.class);
            List<String> listOfValidUIDs = new List<String>();
            for (String uid : listOfUIDs) {
                if (!String.isBlank(uid)) {
                    listOfValidUIDs.add(uid);
                }
            }

            Map<String, Id> mapUIDAndAccountId = getMapUIDAndAccountIdBasedOnUID(listOfValidUIDs);
            res.setData(LABEL_MAP_UID_AND_ACCOUNTID, mapUIDAndAccountId);
        } catch (Exception e) {
            res.error(e.getMessage());
        }
        return res;
    }

    @AuraEnabled(cacheable=true)
    public static Response getPicklistValuesForFields() {
        Response res = new Response();
        try {
            Map<String, List<String>> mapFieldNameAndPicklistValues = new Map<String, List<String>>();
            for (String picklistAPIName : fieldAPINameToObject.keySet()) {
                mapFieldNameAndPicklistValues.put(
                    picklistAPIName.removeEnd('__c'), // csv name is API name without '__c'
                    AquivaHelper.getPicklistValues(fieldAPINameToObject.get(picklistAPIName), picklistAPIName)
                );
            }
            res.setData(LABEL_MAP_FIELD_AND_PICKLIST_VALUES, mapFieldNameAndPicklistValues);
        } catch (Exception e) {
            res.error(e.getMessage());
        }
        return res;
    }

    // insert not dublicated cases
    // dublicate cases are the cases with the same Subject + AccountId + DateAssigned (if accountId is not null)
    @AuraEnabled
    public static Response insertMaintenance(String request) {
        Response res = new Response();
        try {
            List<Case> caseListToInsert = (List<Case>) JSON.deserialize(request, List<Case>.class);
            Set<Id> accountIdSet = new Set<Id>();
            Set<Date> assignedDateSet = new Set<Date>();
            Set<String> subjectSet = new Set<String>();
            Map<String, Integer> caseUniqueDataToIndexCaseMap = new Map<String, Integer>();

            Id accountId;
            Date assignedDate;
            String subject;
            String caseUniqueData;

            for (Integer indexCasesToInsert = 0; indexCasesToInsert < caseListToInsert.size(); ++indexCasesToInsert) {
                if (caseListToInsert[indexCasesToInsert].accountId != null) {
                    // find dublicated cases in insert list, only for not null UID
                    accountId = caseListToInsert[indexCasesToInsert].accountId;
                    assignedDate = caseListToInsert[indexCasesToInsert].Date_Assigned__c;
                    subject = caseListToInsert[indexCasesToInsert].Subject;
                    caseUniqueData = subject + accountId + assignedDate;

                    if (caseUniqueDataToIndexCaseMap.get(caseUniqueData) == null) {
                        accountIdSet.add(accountId);
                        assignedDateSet.add(assignedDate);
                        subjectSet.add(subject);
                        caseUniqueDataToIndexCaseMap.put(caseUniqueData, indexCasesToInsert);
                    } else {
                        res.setData('' + indexCasesToInsert, LABEL_DUBLICATE_INSERT_MAINTENANCE);
                        caseListToInsert[indexCasesToInsert] = null; // remove from insert list
                    }
                }
            }

            if (!caseUniqueDataToIndexCaseMap.isEmpty()) {
                // validation on dublicate cases
                List<Case> casesFromOrg = (new CaseSelector())
                    .newQueryFactory()
                    .selectFields(CASE_FROM_ORG_SEARCH_FIELDS)
                    .setCondition(CASE_FROM_ORG_CONDITION)
                    .setQueryBindings(new List<Object>{accountIdSet, assignedDateSet, subjectSet})
                    .executeQuery();

                Map<String, Id> caseUniqueDataToCaseIdMap = new Map<String, Id>();
                for (Case caseFromOrg : casesFromOrg) {
                    caseUniqueDataToCaseIdMap.put(
                        (caseFromOrg.Subject +
                        caseFromOrg.AccountId +
                        caseFromOrg.Date_Assigned__c),
                        caseFromOrg.Id
                    );
                }

                Integer dublicateIndex;
                Id dublicateCaseId;
                for (String caseUniqueDataToInsert : caseUniqueDataToIndexCaseMap.keySet()) {
                    if (caseUniqueDataToCaseIdMap.get(caseUniqueDataToInsert) != null) {
                        // found dublicate
                        dublicateIndex = caseUniqueDataToIndexCaseMap.get(caseUniqueDataToInsert);
                        dublicateCaseId = caseUniqueDataToCaseIdMap.get(caseUniqueDataToInsert);
                        res.setData('' + dublicateIndex, LABEL_DUBLICATE_MAINTENANCE + dublicateCaseId);
                        caseListToInsert[dublicateIndex] = null; // remove from insert list
                    }
                }
            }

            Map<Integer, Integer> newToOldCaseIndexMap = new Map<Integer, Integer>();
            List<Case> caseListToInsertWithoutDublicates = new List<Case>();
            Integer newCaseIndexToInsert = 0;
            for (Integer indexCasesToInsert = 0; indexCasesToInsert < caseListToInsert.size(); ++indexCasesToInsert) {
                if (caseListToInsert[indexCasesToInsert] != null) {
                    caseListToInsert[indexCasesToInsert].OwnerId = MAINTENANCE_OWNER_ID;
                    caseListToInsert[indexCasesToInsert].RecordTypeId = MAINTENANCE_RECORD_TYPE_ID;
                    caseListToInsertWithoutDublicates.add(caseListToInsert[indexCasesToInsert]);

                    newToOldCaseIndexMap.put(newCaseIndexToInsert, indexCasesToInsert);
                    newCaseIndexToInsert++;
                }
            }

            Database.SaveResult[] saveResultForInsertedCases = Database.insert(
                caseListToInsertWithoutDublicates,
                false
            );
            Integer countInsertedFailure = 0;
            Integer countCasesToInsert = saveResultForInsertedCases.size();
            for (Integer indexOfInsertedCases = 0; indexOfInsertedCases < countCasesToInsert; indexOfInsertedCases++) {
                if (!saveResultForInsertedCases[indexOfInsertedCases].isSuccess()) {
                    //only look at failures, or not Successes
                    res.setData(
                        '' + newToOldCaseIndexMap.get(indexOfInsertedCases),
                        LABEL_ERROR_WHILE_PROCESS_MAINTENANCE +
                        saveResultForInsertedCases[indexOfInsertedCases].getErrors()
                    );
                    countInsertedFailure++;
                }
            }
        } catch (Exception e) {
            res.error(e.getMessage());
        }
        return res;
    }

    private static Map<String, Id> getMapUIDAndAccountIdBasedOnUID(List<String> listOfUIDs) {
        Map<String, Id> mapUIDAndAccountId = new Map<String, Id>();
        if (listOfUIDs.size() > 0) {
            List<Account> accWithUID = (new AccountSelector())
                .newQueryFactory()
                .selectFields(ACCOUNT_UID_SEARCH_FIELDS)
                .setCondition(ACCOUNT_UID_CONDITION)
                .setQueryBindings(new List<Object>{listOfUIDs})
                .executeQuery();

            for (Account acc : accWithUID) {
                mapUIDAndAccountId.put(acc.RC_User_Id__c, acc.Id);
            }
        }
        return mapUIDAndAccountId;
    }
}