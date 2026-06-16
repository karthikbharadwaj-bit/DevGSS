public without sharing class SupportCommunityUsers {
    private static final List<String> UNWANTED_CASE_STATUSES = new List<String> {
        'Duplicate','Invalid','Cancelled','Closed - Endorsed','Closed',
        'Closed - No Response','Closed - No Contact','Closed - No Issue','Requirement Not Met','Unsupported'};
    private static final String CustomPermissionName = 'Can_see_community_billing_info';
    private static final List<String> casesRecordTypeNamesForFeed = new List<String> {
        'Incident', 'Maintenance'};
    public static final String LABEL_USER_FULL_INFO = 'userFullInfo';
    public static final String LABEL_CASES = 'casesInfo';
    private static final List<String> CASES_PREVIEW_FIELDS = new List<String>{
        'Id',
        'CaseNumber',
        'Contact.Name',
        'Contact.Email',
        'Subject',
        'Case_Severity__c',
        'CreatedDate',
        'Status'
    };

    private static final List<String> USER_INFO_FIELDS = new List<String>{
        'Id',
        'Name',
        'FirstName',
        'LastName',
        'ContactId',
        'Contact.AccountId',
        'Email'
    };

    private static final List<String> USER_FULL_INFO_FIELDS = new List<String>{
        'Name',
        'FirstName',
        'LastName',
        'Contact.AccountId',
        'Contact.Name',
        'Contact.Title',
        'Email',
        'Contact.Email',
        'Contact.Phone',
        'Contact.Owner.Name',
        'Contact.Job_Role__c',
        'Contact.Phone_Ext__c',
        'Contact.Account.BillingAddress',
        'Contact.Account.Name',
        'Contact.Account.RC_User_ID__c',
        'Contact.Account.CSM_Name__c',
        'Contact.Account.CSM_Email__c',
        'Contact.Account.Account_POD__c',
        'Contact.Account.inContact_Cluster__c',
        'Contact.Account.CSM__r.SmallPhotoUrl',
        'Contact.Account.CSM__r.FullPhotoUrl'
    };

    private static final List<String> ADMIN_USER_FULL_INFO_FIELDS = new List<String>{
        'Name',
        'FirstName',
        'LastName',
        'Contact.AccountId',
        'Contact.Name',
        'Contact.Title',
        'Email',
        'Contact.Email',
        'Contact.Phone',
        'Contact.Owner.Name',
        'Contact.Job_Role__c',
        'Contact.Phone_Ext__c',
        'Contact.Account.BillingAddress',
        'Contact.Account.Name',
        'Contact.Account.RC_User_ID__c',
        'Contact.Account.CSM_Name__c',
        'Contact.Account.CSM_Email__c',
        'Contact.Account.Account_POD__c',
        'Contact.Account.inContact_Cluster__c',
        'Contact.Account.CSM__r.SmallPhotoUrl',
        'Contact.Account.CSM__r.FullPhotoUrl',
        'Contact.Account.Invoice_Terms__c',
        'Contact.Account.Next_Renewal_Date__c',
        'Contact.Account.Payment_Plan__c',
        'Contact.Account_Tier__c',
        'Contact.Account_Number_of_DLs__c'
    };

    @TestVisible
    private static final Integer MAX_VALID_OFFSET = 2000;
    @TestVisible
    private static final Integer MIN_VALID_OFFSET = 0;
    private static final Integer DEFAULT_OFFSET = MIN_VALID_OFFSET;
    @TestVisible
    private static Integer DEFAULT_LIMIT_COUNT = 50; // not final for tests

    public class UserInfo {

        @AuraEnabled
        public User user;

        @AuraEnabled
        public Boolean isAdmin;

        public UserInfo() {
            this.user = null;
            this.isAdmin = false;
            List<User> users = (List<User>) new UserSelector()
                .selectUsers()
                .selectFields(USER_INFO_FIELDS)
                .setCondition('Id = \'' + System.UserInfo.getUserId() + '\' AND isPortalEnabled = True')
                .setLimit(1)
                .executeQuery();
            if (!users.isEmpty()) {
                this.user = users[0];
                this.isAdmin = SCUserService.isUserSCAdmin(this.user.Id);
            }
        }
    }

    public class Filter{
        String type;
        Boolean isOpen;
        Integer offset = DEFAULT_OFFSET;

        public Filter () {
        }

        public Filter (String caseType, Boolean isCaseOpen) {
            type = caseType;
            isOpen = isCaseOpen;
        }
    }

    @AuraEnabled
    public static Response getUserFullInfo() {
        Response res = new Response();
        try {
            res.setData(LABEL_USER_FULL_INFO, null);
            if (SCUserService.currentUser != null) {
                List<User> users = (List<User>) new UserSelector()
                    .selectUsers()
                    .selectFields(SCUserService.isCurrentUserSCAdmin ? ADMIN_USER_FULL_INFO_FIELDS : USER_FULL_INFO_FIELDS)
                    .setCondition('Id = \'' + SCUserService.currentUser.Id + '\' AND isPortalEnabled = True')
                    .setLimit(1)
                    .executeQuery();
                if (!users.isEmpty()) {
                    res.setData(LABEL_USER_FULL_INFO, users[0]);
                }
            }
        } catch (Exception e) {
            res.error(e.getMessage());
        }
        return res;
    }

    @AuraEnabled
    public static UserInfo getUserInfo() {
        return new UserInfo();
    }

    @AuraEnabled
    public static Response getCasesInfo() {

        Response res = new Response();
        try {
            List<Object> bindings = new List<Object>{
                UNWANTED_CASE_STATUSES,
                SCUserService.currentUser.Contact.AccountId
            };
            if (!SCUserService.isCurrentUserSCAdmin) {
                bindings.add(SCUserService.currentUser.ContactId);
            }
            List<Case> cases = (List<Case>) new CaseSelector()
                .selectCasesForSCPreview(bindings)
                .selectFields(CASES_PREVIEW_FIELDS)
                .setLimit(5)
                .executeQuery();
            res.setData(LABEL_CASES, cases);
        } catch (Exception e) {
            res.error(e.getMessage());
        }
        return res;

    }
    @AuraEnabled(cacheable=true)
    public static List<Object> getLanguages() {
        List <Object> langList = new List <Object>();
        for (SupportCommunityLanguages__c lang : SupportCommunityLanguages__c.getAll().values()) {
            langList.add(new Map<String, Object> {
                'title' => lang.Title__c,
                'shortTitle' => lang.Language__c,
                'code' => lang.Code__c,
                'language' => lang.Country__c,
                'domain' => lang.Domain__c,
                'isCommunity' => lang.isCommunity__c
            });
        }
        return langList;
    }
    @AuraEnabled(cacheable=true)
    public static List<Object> getCasesFeed(String filters) {
        Map<String, String> mapParametersForCaseCondition = new Map<String, String>();
        Map<String, String> mapParametersForMaintenanceCondition = new Map<String, String>();

        User curVaUser = SCUserService.currentUser;
        String contactId = curVaUser.ContactId;
        mapParametersForCaseCondition.put('ContactId', contactId);

        String accountId = curVaUser.Contact.AccountId;
        mapParametersForCaseCondition.put('AccountId', accountId);

        String query =
            'SELECT Id, CaseNumber, Contact.Name, Contact.Email, Subject, Case_Severity__c, CreatedDate, Status, Description, LastModifiedDate, RecordType.Name' +
            ' FROM Case';

        List<Filter> conditions;
        if (!String.isEmpty(filters)) {
            conditions = (List<Filter>) JSON.deserialize(filters, List<Filter>.class);
        } else {
            conditions = new List<Filter>();
            conditions.add(new Filter()); // add default filter
        }

        String pod;
        String uid;
        try {
            Account accountUser = (Account) new AccountSelector()
                .selectAccountsWithPackagesById(new List<Object>{new Set<Id> {accountId}})
                .selectFields(new List<String>{'RC_User_ID__c', 'inContact_Cluster__c'})
                .executeQuery()
			    .get(0);

            Map<Id, Package__c> officePackageToProcessMap = PackageHelper.filterPackagesByService(accountUser.Service_Accounts__r, AccountHelper.SERVICE_TYPE_OFFICE);
            Package__c officePackageToProcess = officePackageToProcessMap.get(accountId);

            if (officePackageToProcess != null && !String.isBlank(officePackageToProcess.Account_POD__c)) {
                mapParametersForMaintenanceCondition.put('Account_POD__c', officePackageToProcess.Account_POD__c);
            }

            if (!String.isBlank(accountUser.RC_User_ID__c)) {
                mapParametersForMaintenanceCondition.put('RC_User_ID__c', accountUser.RC_User_ID__c);
            }

            if (!String.isBlank(accountUser.inContact_Cluster__c)) {
                mapParametersForMaintenanceCondition.put('inContact_Cluster__c', accountUser.inContact_Cluster__c);
            }
        } catch (Exception ex) {
            // if no contact or account - do not add parameters for condition in mapParametersForMaintenanceCondition
        }

        List<Case> casesFeed;
        switch on conditions.size() {
            when 1 {
                if (isValidOffset(conditions[0].offset)) {
                    Map<String, String> mapParametersForCondition = (conditions[0].type == 'Maintenance')
                        ? mapParametersForMaintenanceCondition
                        : mapParametersForCaseCondition;
                    casesFeed = Database.query(processFilter(query, conditions[0], mapParametersForCondition));
                } else {
                    casesFeed = new List<Case>();
                }
            }
            when 2 {
                if (isValidOffset(conditions[0].offset) && isValidOffset(conditions[1].offset)) {
                    List<Case> casesList = Database.query(
                        processFilter(query, conditions[0], mapParametersForCaseCondition)
                    );
                    List<Case> maintenanceList = Database.query(
                        processFilter(query, conditions[1], mapParametersForMaintenanceCondition)
                    );
                    casesFeed = processCasesAndMaintenanceTypes(casesList, maintenanceList);
                } else {
                    casesFeed = new List<Case>();
                }
            }
            when else {
                casesFeed = new List<Case>();
            }
        }

        List<Object> casesWrapperList = new List<Object>();
        for (Case c : casesFeed) {
            Map<String, Object> casesWrapper = new Map<String, Object>();
            casesWrapper.put('Case', c);
            casesWrapper.put('isOpen', c.Status == null ? true : !UNWANTED_CASE_STATUSES.contains(c.Status));
            casesWrapper.put(
                'RecordTypeName',
                casesRecordTypeNamesForFeed.contains(c.RecordType.Name) ? c.RecordType.Name : 'Case'
            );
            casesWrapperList.add(casesWrapper);
        }
        return casesWrapperList;
    }

    private static Boolean isValidOffset(Integer offset) {
        if (offset == null || offset > MAX_VALID_OFFSET || offset < MIN_VALID_OFFSET) {
            return false;
        }
        return true;
    }

    @TestVisible
    private static List<Case> processCasesAndMaintenanceTypes(List<Case> casesList, List<Case> maintenanceList) {
        List<Case> casesFeed = new List<Case>();
        Integer indexCasesFeed = 0;
        Integer indexCasesList = 0;
        Integer indexMaintenanceList = 0;

        for (; indexCasesFeed < DEFAULT_LIMIT_COUNT; ++indexCasesFeed) {
            if (indexCasesList == casesList.size() || indexMaintenanceList == maintenanceList.size()) {
                break; // iterate until one list has elements
            }
            if (casesList[indexCasesList].LastModifiedDate >= maintenanceList[indexMaintenanceList].CreatedDate) {
                casesFeed.add(casesList[indexCasesList]);
                indexCasesList++;
            } else {
                casesFeed.add(maintenanceList[indexMaintenanceList]);
                indexMaintenanceList++;
            }
        }

        for (Integer index = indexCasesFeed; index < DEFAULT_LIMIT_COUNT; ++index) {
            if (indexCasesList == casesList.size() && indexMaintenanceList == maintenanceList.size()) {
                break; // if we got all elements from 2 lists - break
            }
            if (indexCasesList < casesList.size()) {
                casesFeed.add(casesList[indexCasesList]);
                indexCasesList++;
            }
            if (indexMaintenanceList < maintenanceList.size()) {
                casesFeed.add(maintenanceList[indexMaintenanceList]);
                indexMaintenanceList++;
            }
        }

        return casesFeed;
    }

    @TestVisible
    private static String processFilter(String query, Filter condition, Map<String, String> mapParametersForCondition) {
        switch on condition.type {
            when 'Maintenance' {
                String queryCondition = getQueryConditionForMaintenance(mapParametersForCondition);
                if (String.isBlank(queryCondition)) {
                    query += ' LIMIT ' + 0; // no info about Maintenance
                    return query;
                } else {
                    query += queryCondition;
                }
            }
            when else {
                String contactId = mapParametersForCondition.get('ContactId');
                String accountId = mapParametersForCondition.get('AccountId');
                query += (' WHERE AccountId = \'' + accountId + '\'');
                if (!String.isEmpty(contactId) && !SCUserService.isCurrentUserSCAdmin) {
                    query += (' AND ContactId = \'' + contactId + '\'');
                }
            }
        }

        if (condition.isOpen == true) {
            query += ' AND Status NOT IN :UNWANTED_CASE_STATUSES';
        }

        switch on condition.type {
            when 'Case' {
                query += ' AND RecordType.Name NOT IN :casesRecordTypeNamesForFeed'; // not 'Incident' or 'Maintenance'
                query += ' ORDER BY LastModifiedDate DESC';
            }
            when 'Maintenance' {
                query += ' AND RecordType.Name = \'Maintenance\'';
                query += ' ORDER BY CreatedDate DESC';
            }
            when else {
                query += ' ORDER BY LastModifiedDate DESC';
            }
        }

        query += ' LIMIT ' + DEFAULT_LIMIT_COUNT;

        Integer offset = (condition.offset == null) ? DEFAULT_OFFSET : condition.offset;
        query += ' OFFSET ' + offset;

        return query;
    }

    @TestVisible
    private static String getQueryConditionForMaintenance(Map<String, String> mapParametersForMaintenanceCondition) {
        String queryCondition = '';
        if (mapParametersForMaintenanceCondition.isEmpty()) {
            return queryCondition; // no info about Maintenance
        }

        if (mapParametersForMaintenanceCondition.size() == 1) {
            queryCondition += (' WHERE ' + combineConditionsFromMapByOR(mapParametersForMaintenanceCondition));
        } else { // more than 1 parameter - need '(' conditions ')''
            queryCondition += (' WHERE (' + combineConditionsFromMapByOR(mapParametersForMaintenanceCondition) + ')');
        }
        return queryCondition;
    }

    private static String combineConditionsFromMapByOR(Map<String, String> mapParametersForMaintenanceCondition) {
        String condition = '';
        String parameterValue;
        for (String parameterName : mapParametersForMaintenanceCondition.keySet()) {
            parameterValue = mapParametersForMaintenanceCondition.get(parameterName);
            condition += (parameterName + ' = \'' + parameterValue + '\' OR ');
        }
        condition = condition.removeEnd(' OR ');
        return condition;
    }

    @AuraEnabled
    public static List<List<SObject>> getTopicsInfo(String langCode) {
        List<List<SObject>> res = new List<List<SObject>>();
        if(langCode == null
            || String.isEmpty(langCode)) {
            langCode = 'en_US';
        }
        List<SupportCommunityTopicRating__c> existingTopics = [
            SELECT Id, Place__c, Active__c, Name,
                Position__c, Url__c, TopicId__c
            FROM SupportCommunityTopicRating__c
            WHERE Active__c = false
            AND Language__c = :langCode
            AND Place__c = 'Trending'
            ORDER BY Position__c
        ];
        Map<String, SupportCommunityTopicRating__c> existsArticle = new Map<String, SupportCommunityTopicRating__c>();
        List<SupportCommunityTopicRating__c> topicsToUpdate = new List<SupportCommunityTopicRating__c>();

        for (SupportCommunityTopicRating__c tredVal : existingTopics) {
            existsArticle.put(tredVal.Url__c, tredVal);
        }

        for (SupportCommunityTopicRating__c curVaTrend : [
            SELECT Id, Position__c, Place__c, Name,
                TopicId__c, Active__c, Url__c
            FROM SupportCommunityTopicRating__c
            WHERE Active__c = true
            AND Language__c = :langCode
            AND Place__c = 'Trending'
            ORDER by Position__c
            LIMIT 5
        ]) {
            if(existsArticle.containsKey(curVaTrend.Url__c)) {
                existingTopics.remove(existingTopics.indexOf(existsArticle.get(curVaTrend.Url__c)));
            }
            if (curVaTrend.Position__c > existingTopics.size()) {
                existingTopics.add(curVaTrend);
            } else {
                existingTopics.add(Integer.valueOf(curVaTrend.Position__c) - 1, curVaTrend);
            }
            existsArticle.put(curVaTrend.Url__c, curVaTrend);
        }
        for (Integer i = 0; i < existingTopics.size(); i++) {
            if (existingTopics.get(i).Position__c != (i + 1)) {
                existingTopics.get(i).Position__c = (i + 1);
                topicsToUpdate.add(existingTopics.get(i));
            }
        }
        res.add(existingTopics);
        return res;
    }

    public class CommunityUsersException extends Exception {}
}