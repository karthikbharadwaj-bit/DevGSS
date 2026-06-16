public inherited sharing class UserSelector extends SObjectSelector {

    public UserSelector() {
        super();
    }

    public UserSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType() {
        return User.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            User.Id,
            User.Name,
            User.ManagerId,
            User.Email,
            User.FirstName,
            User.LastName,
            User.Phone,
            User.Username,
            User.ProfileId,
            User.PID__c,
            User.IsActive
        };
    }

    public List<Schema.SObjectField> getManagerInfo() {
        return new List<Schema.SObjectField> {
            User.Manager_Id__c,
            User.Manager_Manager_ID__c,
            User.Hierarchy_Role__c
        };
    }

    public Set<String> getDFRFields() {
        return new Set<String> {
            'Team__c',
            'Division',
            'SegmentPicklist__c',
            'Upmarket_Territory__c',
            'UserRoleName__c',
            'Name',
            'UserRole.Name',
            'Manager.ManagerId',
            'Profile.Name',
            'Division',
            'SegmentPicklist__c',
            'Team__c',
            'Upmarket_Territory__c'
        };
    }

    public List<String> getRoleInfo() {
        return new List<String> {
            'UserRoleId',
            'UserRole.Name'
        };
    }

    public List<String> getContactInfo() {
        return new List<String> {
            'FullPhotoUrl',
            'ContactId',
            'AccountId',
            'Contact.AccountId',
            'Contact.Email',
            'Contact.Phone_Ext__c',
            'Contact.Phone',
            'Contact.LastName',
            'Contact.FirstName',
            'Contact.Name',
            'Contact.Account.Account_POD__c',
            'Contact.Account.inContact_Cluster__c',
            'Contact.Account.RC_Tier__c',
            'Contact.Account.Number_of_DL_s__c',
            'Contact.Account.RC_Brand__c',
            'Contact.Account.Total_Account_DL_s__c',
            'Contact.Account.VIP_Account_Indicator__c',
            'Contact.Account.Service_Status__c',
            'Contact.Account.Extended_Enterprise_Support_Customer__c',
            'Contact.Account.CSM__r.FullPhotoUrl',
            'Contact.Account.Account_POD__c'
        };
    }

    public List<String> getUserFieldsForCaseDetail() {
        return new List<String> {
            'FullPhotoUrl',
            'ContactId',
            'AccountId',
            'Contact.AccountId',
            'Contact.Email',
            'Contact.Phone_Ext__c',
            'Contact.Phone',
            'Contact.LastName',
            'Contact.FirstName',
            'Contact.Name',
            'Contact.Account.Account_POD__c',
            'Contact.Account.inContact_Cluster__c',
            'Contact.Account.RC_Tier__c',
            'Contact.Account.Number_of_DL_s__c',
            'Contact.Account.RC_Brand__c',
            'Contact.Account.Total_Account_DL_s__c',
            'Contact.Account.VIP_Account_Indicator__c',
            'Contact.Account.Service_Status__c',
            'Contact.Account.Extended_Enterprise_Support_Customer__c',
            'Contact.Account.CSM__r.FullPhotoUrl',
            'Contact.Account.Account_POD__c',
            'Profile.Name'
        };
    }

    public List<String> getUserFieldsForSignUp() {
        return new List<String> {
            'Id',
            'Name',
            'PID__c',
            'Profile.Name'
        };
    }

    public List<String> getUserFieldsForLeadConvert() {
        return new List<String> {
            'Id',
            'Contact.AccountId',
            'Contact.Account.Partner_id__c',
            'Contact.Account.Partner_Type__c'
        };
    }

    public List<String> getManagerEmail() {
        return new List<String> {
            'Id',
            'Manager.Email'
        };
    }

    public List<String> getFieldsForCachedUsers() {
        return new List<String> {
            'Id',
            'FirstName',
            'Lastname',
            'Name',
            'Email',
            'Phone',
            'ProfileId',
            'IsTmtTriggersDisabled__c',
            'Profile.Name',
            'Systems_Integration_Users__c'
        };
    }

    public List<String> getFieldsForSettingsService() {
        return new List<String> {
            'Contact.Name',
            'ContactId',
            'Hierarchy_Role__c',
            'Id',
            'Name',
            'Profile.Id',
            'Profile.Name',
            'SegmentPicklist__c',
            'UserRoleId',
            'UserRoleName__c'
        };
    }

    public List<String> getCacheableUserFields() {
        return new List<String> {
            'Id',
            'GSP_User__c',
            'Mkto_Reply_Email__c',
            'Manager.Email',
            'Manager.Name',
            'Email',
            'FirstName',
            'Hold_Out_List__c',
            'IsActive',
            'LastName',
            'ManagerId',
            'Name',
            'PID__c',
            'Phone',
            'Profile.Id',
            'Profile.Name',
            'Title',
            'UserRole.Name',
            'Username',
            'Division',
            'Manager.ManagerId',
            'SegmentPicklist__c',
            'Team__c',
            'Upmarket_Territory__c',
            'UserRoleName__c'
        };
    }

    public QueryFactory selectUsers() {
        return newQueryFactory()
            .setFactoryName('selectUsers')
            .withoutSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded();
    }

    public QueryFactory selectUsersByIdNoFields(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectUsersByIdNoFields')
            .withoutSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectUserForApproval(List<Object> bindings) {
        return newQueryFactory()
                .setFactoryName('selectUserForApproval')
                .withSelectorFieldsIncluded()
                .selectFields(getManagerInfo())
                .withoutSelectorOrderByIncluded()
                .setCondition('Id IN :bind0')
                .setQueryBindings(bindings);
    }

    public QueryFactory selectUserForOpportunities(List<Object> bindings) {
        return newQueryFactory()
                .setFactoryName('selectUserForOpportunities')
                .withSelectorFieldsIncluded()
                .setCondition('Id IN :bind0')
                .setQueryBindings(bindings);
    }

    public QueryFactory selectUserByLastName(List<Object> bindings) {
       return newQueryFactory()
               .setFactoryName('selectUserByLastName')
               .withSelectorFieldsIncluded()
               .setCondition('LastName = :bind0')
               .setQueryBindings(bindings);
    }

    public QueryFactory selectUserByName(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectUserByName')
            .withSelectorFieldsIncluded()
            .selectFields(getManagerInfo())
            .withoutSelectorOrderByIncluded()
            .setCondition('Name IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectUserByUsername(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectUserByUsername')
            .withSelectorFieldsIncluded()
            .selectFields(getDefaultFieldList())
            .setCondition('UserName IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectActiveUserByNameAndProfile(List<Object> bindings) {
        return newQueryFactory()
                .setFactoryName('selectActiveUserByNameAndProfile')
                .withSelectorFieldsIncluded()
                .withSelectorOrderByIncluded()
                .addOrdering(User.CreatedDate, QueryFactory.SortOrder.DESCENDING)
                .setCondition('IsActive=TRUE AND Name IN :bind0 AND Profile.Name IN :bind1')
                .setQueryBindings(bindings)
                .setLimit(1);
    }

    public QueryFactory selectUserByIdForLeadConvert(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('SelectUserByIdForLeadConvert')
            .withSelectorFieldsIncluded()
            .selectFields(getUserFieldsForLeadConvert())
            .withoutSelectorOrderByIncluded()
            .setCondition('Id = :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectUserForDFRList(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectUserForDFRList')
            .withSelectorFieldsIncluded()
            .selectFields(getDFRFields())
            .setQueryCaching(false)
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectUserForDFRSingle(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectUserForDFRListSingle')
            .withSelectorFieldsIncluded()
            .selectFields(getDFRFields())
            .setQueryCaching(false)
            .setCondition('Id = :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectUserRoleById(List<Object> bindings) {
        return newQueryFactory()
                .setFactoryName('selectUserRoleById')
                .withSelectorFieldsIncluded()
                .selectFields(getRoleInfo())
                .setCondition('Id = :bind0')
                .setQueryBindings(bindings);
    }

    public QueryFactory selectUsersRolesByIds(List<Object> bindings) {
        return newQueryFactory()
                .setFactoryName('selectUsersRolesByIds')
                .withSelectorFieldsIncluded()
                .selectFields(getManagerInfo())
                .setCondition('Id in :bind0')
                .setQueryBindings(bindings);
    }

    public QueryFactory selectUserByIdForNewCase(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectUserByIdForNewCase')
            .withSelectorFieldsIncluded()
            .selectFields(getContactInfo())
            .withoutSelectorOrderByIncluded()
            .setCondition('Id = :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectMarketoUser() {
        return newQueryFactory()
            .setFactoryName('selectMarketoUser')
            .withSelectorFieldsIncluded()
            .selectFields(getManagerInfo())
            .withoutSelectorOrderByIncluded()
            .setCondition('Name = :bind0')
            .setQueryBindings(new List<Object>{UserHelper.MARKETO_USER_NAME});
    }

    public QueryFactory selectUsersByContactId(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectUsersByContactId')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .setCondition('ContactId IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectUsersByIdWithContactInfo(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectUsersByIdWithContactInfo')
            .withSelectorFieldsIncluded()
            .selectFields(getContactInfo())
            .withoutSelectorOrderByIncluded()
            .setCondition('Id IN :bind0 AND IsPortalEnabled = True')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectUsersByIdWithContactInfoForAPI(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectUsersByIdWithContactInfoForAPI')
            .withSelectorFieldsIncluded()
            .selectFields(getUserFieldsForCaseDetail())
            .withoutSelectorOrderByIncluded()
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectUsersByAccountIdsAndProfileName(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectUsersByAccountIdsAndProfileName')
            .withSelectorFieldsIncluded()
            .selectFields(getContactInfo())
            .withoutSelectorOrderByIncluded()
            .setCondition('Contact.AccountId IN :bind0 AND Profile.Name IN :bind1')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectActiveUserByName(List<Object> bindings) {
        return newQueryFactory()
                .setFactoryName('selectActiveUserByName')
                .withSelectorFieldsIncluded()
                .withSelectorOrderByIncluded()
                .addOrdering(User.CreatedDate, QueryFactory.SortOrder.DESCENDING)
                .setCondition('IsActive=TRUE AND Name IN :bind0')
                .setQueryBindings(bindings)
                .setLimit(1);
    }

    public QueryFactory selectUserForSignUp(Object userId) {
        return newQueryFactory()
            .setFactoryName('SelectUserForSignUp')
            .selectFields(getUserFieldsForSignUp())
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object>{userId});
    }

    public QueryFactory selectUserByNameAndEmail(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('SelectUserForSignUp')
            .selectFields(new List<String> {
                'Id', 'Name', 'Email'
            })
            .setCondition('Name IN :bind0 AND Email IN :bind1 AND isActive = true AND ContactId = null')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectManagerEmailByIds(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectManagerEmailByIds')
            .selectFields(getManagerEmail())
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectUserByIdForGlip(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectUserByIdForGlip')
            .withSelectorFieldsIncluded()
            .setCondition('Id = :bind0')
            .setQueryBindings(bindings)
            .setLimit(1);
    }

    public QueryFactory selectRelaywareApiUser() {
        return newQueryFactory()
            .setFactoryName('selectRelaywareApiUser')
            .selectFields(getDefaultFieldList())
            .setCondition(
                'Name = \'' + UserHelper.API_USER_NAME + '\' AND ' +
                'Profile.Name = \'' + ProfileHelper.PROFILE_NAME_RELAYWARE + '\''
            )
            .setLimit(1);
    }

    public QueryFactory selectCachedUsers() {
        return newQueryFactory()
            .setFactoryName('selectCachedUsers')
            .selectFields(getFieldsForCachedUsers())
            .setCondition(
                'UserType= \'Standard\' '
                + 'AND IsActive = true '
                + 'AND (Id = \'' + UserInfo.getUserId() + '\' '
                    + 'OR Name = \'LAR System User\' '
                    + 'OR Name = \'DO NOT CONTACT - VAR\' '
                    + 'OR Name = \'LeanData Queue\' '
                    + 'OR Name = \'User Marketo\' '
                    + 'OR Profile.Name = \'System Administrator\')')
            .setQueryCaching(true)
            .withoutSelectorOrderByIncluded();
    }

    public QueryFactory selectCurrentUserForSettingsService() {
        Id currentUserId = UserInfo.getUserId();
        return newQueryFactory()
            .setFactoryName('selectCurrentUser')
            .withSelectorFieldsIncluded()
            .selectFields(getFieldsForSettingsService())
            .withoutSelectorOrderByIncluded()
            .setQueryCaching(true)
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object>{currentUserId});
    }

    public QueryFactory selectUsersByProfileIds(Set<Id> profileIds) {
        return newQueryFactory()
            .setFactoryName('selectUsersByProfileIds')
            .setCondition('ProfileId IN :bind0')
            .setQueryBindings(new List<Object>{profileIds});
    }

    public QueryFactory selectUsersByIds(Set<Id> userIds) {
        return newQueryFactory()
            .setFactoryName('selectUsersByIds')
            .setCondition('Id IN :bind0')
            .setQueryBindings(new List<Object>{userIds});
    }

    public QueryFactory selectUserById(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectUserById')
            .selectFields(getDefaultFieldList())
            .setCondition('Id = :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectUsersWithDelegatedApproversByIds(Set<Id> userIds) {
        return newQueryFactory()
            .setFactoryName('selectUsersWithDelegatedApproversByIds')
            .selectFields(new List<String> {
                'Id', 'DelegatedApproverId'
            })
            .setCondition('Id IN :bind0 AND DelegatedApproverId != null')
            .setQueryBindings(new List<Object>{userIds});
    }

    public QueryFactory selectUsersByQueueDevName(String queueDevName) {
        return newQueryFactory()
            .setFactoryName('selectUsersByQueueDevName')
            .selectFields(new List<String> {
                'Id', 'Name', 'Email'
            })
            .setCondition('Id IN (SELECT UserOrGroupId FROM GroupMember WHERE Group.DeveloperName = :bind0 AND Group.Type = \'Queue\')')
            .setQueryBindings(new List<Object>{queueDevName});
    }
}