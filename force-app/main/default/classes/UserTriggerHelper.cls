public with sharing class UserTriggerHelper {

    //Set 'Manager' Portal Role for 'PowerPartner' User Type (UserTrg.trigger copy)
    public class SetPortalRole extends Triggers.TriggerHandlerBase {
        override public void handle(){
            try {
                set<Id> contactIdSet = new set<Id>();
                for(User u : (List<User>) triggerRecords){
                    if((u.UserType == 'PowerPartner' && !string.isBlank(u.ContactId)) || Test.isRunningTest()){
                        contactIdSet.add(u.ContactId);
                    }
                }

                map<Id,Id> mapContactToAccount = new map<Id,Id>();
                if (!contactIdSet.isEmpty()) {
                    for(Contact c :
                    [
                        SELECT AccountId
                        FROM Contact
                        WHERE Id IN :contactIdSet
                    ]){
                        mapContactToAccount.put(c.Id, c.AccountId);
                    }
                }

                map<Id,Id> mapAccountToUser = new map<Id,Id>();
                if(!mapContactToAccount.isEmpty()){
                    for(User u :
                    [
                        SELECT Id, AccountId
                        FROM User
                        WHERE AccountId IN :mapContactToAccount.values()
                            AND UserType = 'PowerPartner'
                    ]){
                        mapAccountToUser.put(u.AccountId, u.Id);
                    }
                }

                for(User u : (List<User>) triggerRecords){
                    if(!mapAccountToUser.isEmpty()
                        && !mapContactToAccount.isEmpty()
                        && u.ContactId != null
                        && u.UserType == 'PowerPartner'){

                        if(!mapContactToAccount.containsKey(u.ContactId)
                            && !mapAccountToUser.containsKey(mapContactToAccount.get(u.ContactId))){
                            u.PortalRole = 'Manager';
                        }
                    }
                }
            }
            catch(Exception ex){
                PlatformLog.logException(UserTriggerHelper.class.getName(), ex);
            }
        }
    }

    public class SetDeactivationDate extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Date todaysDate = Date.today();
            for (User u : (List<User>)trigger.new) {
                if (isChangedFieldTo(u, User.IsActive, false)) {
                    u.DeactivationDate__c = todaysDate;
                } else if (isChangedFieldTo(u, User.IsActive, true)) {
                    u.DeactivationDate__c = null;
                }
            }
        }
    }

	//Reaasign cases from inactive user to his manager
	public class AutomatedCaseAssignment extends Triggers.TriggerHandlerBase {
		override public void handle(){
			Set<Id> userIds = new Set<Id>();
			for(User u : (List<User>) triggerRecords){
				if(!isChangedFieldTo(u, User.IsActive, false) ||
					!UserHelper.EMPLOYEE_LOCATION_MANILA.contains(u.Employee_Location__c)){
                    continue;
                }
                userIds.add(u.Id);
			}

			if(userIds.isEmpty()){
			   return;
			}
			Map<Id,Id> userIdTomanagerId = findNearestActiveUserManagerId(3, userIds);

			if(userIdTomanagerId.isEmpty()){
				return;
			}
			UserTriggerHelper.reassignCasesFromInactiveUserToHisManager(userIdTomanagerId);
		}
	}

	private static Map<Id,Id> findNearestActiveUserManagerId(Integer nesting, Set<Id> userIds){
		String query = ''+
			'SELECT Id '+getNestingManagerFields(nesting)+' '+
			'FROM User '+
			'WHERE Id IN :userIds';

		Map<Id,Id> userIdTomanagerId = new Map<Id,Id>();
		for(User u : database.query(query)){
			userIdTomanagerId.put(u.Id, getNearestActiveManagerId(nesting, u));
		}
		return userIdTomanagerId;
	}

	private static String getNestingManagerFields(Integer nesting){
		String fields = '';
		String nestingManager = '';
		for(Integer i=0; i<nesting; i++){
			nestingManager += 'Manager.';
			fields += ', '+nestingManager+'Id, '+nestingManager+'IsActive';
		}
		return fields;
	}

	private static Id getNearestActiveManagerId(Integer nesting, User u){
        Id managerId;
		for(Integer i=0; i<nesting; i++){
			managerId = getManagerId(i, u);
			if(managerId == null){
				continue;
			}
			return managerId;
		}
		return null;
	}

    private static Id getManagerId(Integer nesting, User u){
        SObject sobj = u.getSObject('Manager');
        Boolean isManagerActive;
        Id managerId;
        try{
            for(Integer i=0; i<nesting; i++){
                sobj = sobj.getSObject('Manager');
            }
            managerId = (Id)sobj.get('Id');
            isManagerActive = (Boolean)sobj.get('IsActive');
        }
        catch(Exception ex){
        	PlatformLog.logException(UserTriggerHelper.class.getName(), ex);
        }
        return (managerId != null && isManagerActive) ? managerId : null;
    }

	@future
	public static void reassignCasesFromInactiveUserToHisManager(Map<Id,Id> userIdTomanagerId){
		List<Case> cases = new List<Case>();
        if (userIdTomanagerId.isEmpty()) {
            return;
        }

		for(Case c :
		[
			SELECT Id, OwnerId
			FROM Case
			WHERE OwnerId IN :userIdTomanagerId.keySet()
				AND Status NOT IN :CaseHelper.CASE_STATUSES_TO_REASSIGN_ON_CASE_OWNER_INACTIVE
				AND RecordType.Name IN :CaseHelper.CASE_RTS_TO_REASSIGN_ON_CASE_OWNER_INACTIVE
		]){

			if(!userIdTomanagerId.containsKey(c.OwnerId) || userIdTomanagerId.get(c.OwnerId) == null){
				continue;
			}
			c.OwnerId = userIdTomanagerId.get(c.OwnerId);
			cases.add(c);
		}

		if(cases.isEmpty()){
			return;
		}
		update cases;
	}

    public class DefineKCSGroupMembers extends Triggers.TriggerHandlerBase {
        override public void handle() {
            KCSSettings__c featureToggle = KCSSettings__c.getInstance();
            Boolean isEnableTriggerDefineGroupMembers =
                featureToggle != null && featureToggle.EnableTriggerDefineGroupMembers__c;

            if (isEnableTriggerDefineGroupMembers && Trigger.isInsert) {
                List<PermissionSetAssignment> permissionSetListToInsert = new List<PermissionSetAssignment>();

                Map<Id, String> mapUserIdAndGroupNamesToInsert = new Map<Id, String>();
                Set<String> usedGroupNames = new Set<String>();
                String nameGroupToInsertGroupMember;

                for (User u : (List<User>) Trigger.new) {
                    if (u.KCS_Role__c != null) {
                        nameGroupToInsertGroupMember = GroupHelper.getGroupNameBasedOnUserKCSRole(u.KCS_Role__c);
                        if (String.isNotBlank(nameGroupToInsertGroupMember)) {
                            mapUserIdAndGroupNamesToInsert.put(u.Id, nameGroupToInsertGroupMember);
                            usedGroupNames.add(nameGroupToInsertGroupMember);
                        }
                    }
                }

                permissionSetListToInsert = definePSAAndInsertGroupMembers(
                    GroupHelper.defineGroupIdsBasedOnName(usedGroupNames),
                    GroupHelper.definePermissionSetIdBasedOnGroupName(),
                    mapUserIdAndGroupNamesToInsert
                );
                Database.insert(permissionSetListToInsert, false);
            }

            if (isEnableTriggerDefineGroupMembers && Trigger.isUpdate) {
                List<PermissionSetAssignment> permissionSetListToInsert = new List<PermissionSetAssignment>();
                Map<Id, String> mapAssigneeIdAndPermissionSetId = new Map<Id, String>();
                List<PermissionSetAssignment> permissionSetListToDelete = new List<PermissionSetAssignment>();

                Map<Id, User> oldCompaniesMap = (Map<Id, User>) Trigger.oldMap;
                Map<Id, String> mapUserIdAndGroupNamesToInsert = new Map<Id, String>();
                Map<Id, String> mapUserIdAndGroupNamesToDelete = new Map<Id, String>();

                Set<String> usedGroupNames = new Set<String>();
                String nameGroupToInsertGroupMember;
                String nameGroupToDeleteGroupMember;
                for (User u : (List<User>) Trigger.new) {
                    if (!isChangedFieldTo(u, User.IsActive, false) && isChangedField(u, User.KCS_Role__c)) {
                        nameGroupToInsertGroupMember = GroupHelper.getGroupNameBasedOnUserKCSRole(u.KCS_Role__c);
                        if (String.isNotBlank(nameGroupToInsertGroupMember)) {
                            mapUserIdAndGroupNamesToInsert.put(u.Id, nameGroupToInsertGroupMember);
                            usedGroupNames.add(nameGroupToInsertGroupMember);
                        }

                        nameGroupToDeleteGroupMember = GroupHelper.getGroupNameBasedOnUserKCSRole(
                            oldCompaniesMap.get(u.Id).KCS_Role__c
                        );
                        if (String.isNotBlank(nameGroupToDeleteGroupMember)) {
                            mapUserIdAndGroupNamesToDelete.put(u.Id, nameGroupToDeleteGroupMember);
                            usedGroupNames.add(nameGroupToDeleteGroupMember);
                        }
                    }
                }

                Map<String, Id> mapGroupNameAndGroupId = GroupHelper.defineGroupIdsBasedOnName(usedGroupNames);
                Map<String, Id> mapGroupNameAndPermissionSetId = GroupHelper.definePermissionSetIdBasedOnGroupName();
                permissionSetListToInsert = definePSAAndInsertGroupMembers(
                    mapGroupNameAndGroupId,
                    mapGroupNameAndPermissionSetId,
                    mapUserIdAndGroupNamesToInsert
                );

                String groupId;
                String groupName;
                Map<Id, Id> mapUserIdAndGroupIdToDelete = new Map<Id, Id>();
                if (!mapUserIdAndGroupNamesToDelete.isEmpty()) {
                    for (Id userId : mapUserIdAndGroupNamesToDelete.keySet()) {
                        groupName = mapUserIdAndGroupNamesToDelete.get(userId);
                        groupId = mapGroupNameAndGroupId.get(groupName);
                        mapUserIdAndGroupIdToDelete.put(userId, groupId);

                        mapAssigneeIdAndPermissionSetId.put(userId, mapGroupNameAndPermissionSetId.get(groupName));
                    }
                    List<Object> bindings = new List<Object>();
                    bindings.add(mapUserIdAndGroupIdToDelete.keySet());
                    bindings.add(mapUserIdAndGroupIdToDelete.values());
                    List<GroupMember> listGM = new GroupMemberSelector()
                        .selectExistGroupMembersBasedOnUserIdAndGroupId(bindings)
                        .executeQuery();
                    /* some persons can be in few groups - we should not delete from another groups */
                    List<GroupMember> groupMembersToDelete = new List<GroupMember>();
                    for (GroupMember gm : listGM) {
                        if (gm.GroupId == mapUserIdAndGroupIdToDelete.get(gm.UserOrGroupId)) {
                            groupMembersToDelete.add(gm);
                        }
                    }
                    Database.DeleteResult[] drList = Database.delete(groupMembersToDelete, false);
                    logKCSGroupMemberDelete(groupMembersToDelete, drList);
                }
                /* same process for PermissionSetAssignment*/
                if (!mapAssigneeIdAndPermissionSetId.isEmpty()) {
                    List<Object> bindings = new List<Object>();
                    bindings.add(mapAssigneeIdAndPermissionSetId.keySet());
                    bindings.add(mapAssigneeIdAndPermissionSetId.values());
                    List<PermissionSetAssignment> listPSA = new PermissionSetAssignmentSelector()
                        .selectPSABasedOnAssigneeAndPermissionSet(bindings)
                        .executeQuery();

                    for (PermissionSetAssignment psa : listPSA) {
                        if (psa.PermissionSetId == mapAssigneeIdAndPermissionSetId.get(psa.AssigneeId)) {
                            permissionSetListToDelete.add(psa);
                        }
                    }
                }

                Database.delete(permissionSetListToDelete, false);
                Database.insert(permissionSetListToInsert, false);
            }
        }

        private void logKCSGroupMemberInsert(
            List<GroupMember> groupMembersToInsert,
            DataBase.SaveResult[] saveResultList
        ) {
            List<PlatformLog__c> logs = new List<PlatformLog__c>();

            for (Integer i = 0; i < saveResultList.size(); i++) {
                if (!saveResultList[i].isSuccess()) {
                    for (Database.Error e : saveResultList[i].getErrors()) {
                        String error = 'GroupMember Id = ' + groupMembersToInsert[i].Id + '\n' + e.getMessage();
                        logs.add(
                            PlatformLog.buildLog('UserTrigger.DefineKCSGroupMembers', e.getMessage(), error, null, null)
                        );
                    }
                }
            }
            PlatformLog.logResults(logs);
        }

        private void logKCSGroupMemberDelete(
            List<GroupMember> groupMembersToDelete,
            DataBase.DeleteResult[] deleteResultList
        ) {
            List<PlatformLog__c> logs = new List<PlatformLog__c>();

            for (Integer i = 0; i < deleteResultList.size(); i++) {
                if (!deleteResultList[i].isSuccess()) {
                    for (Database.Error e : deleteResultList[i].getErrors()) {
                        String error = 'GroupMember Id = ' + groupMembersToDelete[i].Id + '\n' + e.getMessage();
                        logs.add(
                            PlatformLog.buildLog('UserTrigger.DefineKCSGroupMembers', e.getMessage(), error, null, null)
                        );
                    }
                }
            }
            PlatformLog.logResults(logs);
        }

        private List<PermissionSetAssignment> definePSAAndInsertGroupMembers(
            Map<String, Id> mapGroupNameAndGroupId,
            Map<String, Id> mapGroupNameAndPermissionSetId,
            Map<Id, String> mapUserIdAndGroupNamesToInsert
        ) {
            List<PermissionSetAssignment> permissionSetListToInsert = new List<PermissionSetAssignment>();
            String groupId;
            String groupName;
            if (!mapUserIdAndGroupNamesToInsert.isEmpty()) {
                List<GroupMember> groupMembersToInsert = new List<GroupMember>();
                for (Id userId : mapUserIdAndGroupNamesToInsert.keySet()) {
                    groupName = mapUserIdAndGroupNamesToInsert.get(userId);
                    groupId = mapGroupNameAndGroupId.get(groupName);
                    groupMembersToInsert.add(new GroupMember(GroupId = groupId, UserOrGroupId = userId));

                    permissionSetListToInsert.add(
                        new PermissionSetAssignment(
                            PermissionSetId = mapGroupNameAndPermissionSetId.get(groupName),
                            AssigneeId = userId
                        )
                    );
                }
                Database.SaveResult[] srList = Database.insert(groupMembersToInsert, false);
                logKCSGroupMemberInsert(groupMembersToInsert, srList);
            }
            return permissionSetListToInsert;
        }
    }
    // Added for PRM-82 -start
    public class AssignCLMPermissionForPartnerUsers extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Set<Id> userIds = new Set<Id>();
            for (User u : (List<User>) Trigger.new) {
                if (u.UserType == 'PowerPartner' && (u.User_Profile_License__c == 'Partner Community' || u.User_Profile_License__c == 'Partner Community Login') && u.isActive && isChangedFieldTo(u, User.IsPortalEnabled, true)) {
                    userIds.add(u.Id);
                }
            }
            System.debug(userIds + ' userIds to assign Docusign CLM');
            if (userIds.size() > 0) {
                if(System.isBatch() || System.isFuture()) {
                    UserTriggerHelper.assignCLMPermissionToPartnerUsers(userIds);
                } else {
                    UserTriggerHelper.assignCLMPermissionToPartnerUsersFuture(userIds);
                }
            }
        }
    }
    @future
        public static void assignCLMPermissionToPartnerUsersFuture(Set<Id> userIds) {
            UserTriggerHelper.assignCLMPermissionToPartnerUsers(userIds);
        }

        public static void assignCLMPermissionToPartnerUsers(Set<Id> userIds) {
            List<PermissionSet> permissionSet = (List<PermissionSet>) new PermissionSetSelector()
            .selectPermissionSetsByName(new List<Object>{new List<String>{'EnableDocuSignCLMAccess'}})
            .executeQuery();

            List<PermissionSetAssignment> permissionSetAssignments = new List<PermissionSetAssignment>();
            if (permissionSet.size() > 0) {
                for (Id partnerUserId : userIds) {
                    permissionSetAssignments.add(new PermissionSetAssignment(
                        AssigneeId = partnerUserId,
                        PermissionSetId = permissionSet[0].Id
                    ));
                }
                insert permissionSetAssignments;
            }
        }
    // Added for PRM-82 - end

     public class EURestricted_Validation extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Map<id,User> userIdOwnerIdMap = new Map<id,User>();
            Map<String, EU_Privacy_Setup__mdt> EUPrivacymap = new Map<String, EU_Privacy_Setup__mdt>();
            Set<String> EURestrictedCountriesSet = new Set<String>();
            Set<String> EURestrictedProfileNameSet = new Set<String>();
            Set<String> EURestrictedAccountBrandsSet = new Set<String>();
            Set<String> EUSupportRestrictedProfileSet = new Set<String>();
            Set<String> EURestrictedCompletelyCountriesSet = new Set<String>();
            Set<String> validCountriesSet = new Set<String>();
            List<EU_Privacy_Setup__mdt> EUPrivacyList = (List<EU_Privacy_Setup__mdt>) new CustomMetadataSelector()
                .selectEUPrivacyMDT()
                .setQueryCaching(true)
                .executeQuery();
            
            for(EU_Privacy_Setup__mdt eu : EUPrivacyList){
                if(eu.DeveloperName == 'Restricted_Country_Setup'){
                    for(String s : eu.Restricted__c.Split(',')){
                        EURestrictedCountriesSet.add(s.trim().toLowercase());
                    }
                }else if(eu.DeveloperName == 'Restricted_Profile_Setup'){
                    for(String s : eu.Restricted__c.Split(',')){
                        EURestrictedProfileNameSet.add(s.trim());
                    }
                }else if(eu.DeveloperName == 'Restricted_Account_Brands'){
                    for(String s : eu.Restricted__c.Split(',')){
                        EURestrictedAccountBrandsSet.add(s.trim().toLowercase());
                    }
                }else if(eu.DeveloperName == 'Restricted_Support_Profile_Setup'){
                    for(String s : eu.Restricted__c.Split(',')){
                        EUSupportRestrictedProfileSet.add(s.trim());
                    }  
                } else if(eu.DeveloperName == 'Completely_Restricted_Countries'){
                    for(String s : eu.Restricted__c.Split(',')){
                        EURestrictedCompletelyCountriesSet.add(s.trim().toLowercase());
                    }  
                } else if(eu.DeveloperName == 'Valid_Countries_List'){
                    for(String s : eu.Restricted__c.Split(',')){
                        validCountriesSet.add(s.trim().toLowercase());
                    }  
                }
            }
            Map<Id, User> triggerNewMap = (Map<Id, User>)Trigger.newMap;
            Map<id,Profile> restrictedProfileMap = new Map<id,Profile>([Select id from Profile where Name in : EURestrictedProfileNameSet]);
            
            for(String userId: triggerNewMap.keySet()) {
                User usr = triggerNewMap.get(userId);
                //if country is not valid, return error
                if(usr.country__c!= null && usr.isActive == true) {
                    if(!validCountriesSet.contains(usr.country__c.toLowercase())) {
                        usr.addError('County is not valid');
                    }
                    //User from EU region can not be assigned restricted profile
                    if(restrictedProfileMap.keyset().contains(usr.ProfileId) && EURestrictedCountriesSet.contains(usr.country__c.toLowercase())){
                        usr.addError('Users from EU country can not be assigned as restricted profile');
                    }
                    //User from totally restricted EU region can have only EU restricted profile
                    if(!restrictedProfileMap.keyset().contains(usr.ProfileId) && EURestrictedCompletelyCountriesSet.contains(usr.country__c.toLowercase())){
                        usr.addError('User from totally restricted EU region can have only EU restricted profile');
                    } 
                }                
            }
        }
    }
    
    // Added for PBC-20541. Update CSM Name of Relationship Survey eligible Accounts whenever Name of the User is changed. 
    public class TrackUserNameChangesForCSM extends Triggers.TriggerHandlerBase {
        private final String ACCOUNT_STATUS_CANCELED = 'Canceled';
        override public void handle() {
            if (Trigger.isUpdate) {
                
                Map<Id,User> userNameChangesMap = new Map<Id,User>();
                List<Account> CSMNameChangedlist = new List<Account>();
                List<Account_CSM_Profiles__c> CSMProfiles = Account_CSM_Profiles__c.getAll().values();
                List<String> allowedCSMProfileList = new List<String>();

                List<Medallia_Invitation__mdt> medList = Medallia_Invitation__mdt.getAll().values();
                List<String> rcServiceList = new List<String>();
                List<String> rcBrandList = new List<String>();
                List<String> segmentList = new List<String>();

                if (CSMProfiles != null) {
                    for (Account_CSM_Profiles__c profileList: CSMProfiles) {
                        if (profileList.Profile_Name__c != null) {
                            allowedCSMProfileList.add(profileList.Profile_Name__c);
                        }
                    }
                }

                Map<Id,User> userMap = new Map<Id,User>([SELECT Id, ProfileId, Profile.Name from User where Id in :Trigger.newMap.keyset() AND profile.name IN :allowedCSMProfileList]);                
               
                for (User usr : (List<User>)Trigger.new) {
                    User userRec = userMap.get(usr.Id);
                    if (userRec!= null && allowedCSMProfileList.contains(userRec.Profile?.Name) 
                    && ((usr.FirstName != null && isChangedField(usr, User.FirstName)) 
                    || (usr.LastName != null && isChangedField(usr, User.LastName))) ) {
                        userNameChangesMap.put(usr.Id, usr);
                    }
                }

                if (!userNameChangesMap.isEmpty()){
                    if (medList != null && medList.size() > 0){
                        for(Medallia_Invitation__mdt med : medList){
                            if(med.DeveloperName == 'Relationship_Survey'){
                                rcServiceList = med.Exclude_RC_Service__c != null ? med.Exclude_RC_Service__c.split(',') : new List<String>();
                                rcBrandList = med.Exclude_RC_Brand__c != null ? med.Exclude_RC_Brand__c.split(',') : new List<String>();
                                segmentList = med.Segment_Name__c != null ? med.Segment_Name__c.split(','): new List<String>();
                                break;
                            }
                        }
                    }
                    // LTR-1496. User Story - PBC-20541  We're considering only the Accounts eligible for Relationship Survey for updating the CSM Name 
                    List<Account> accountsWithCSM = [SELECT Id,RC_Brand__c, CSM__c, CSM_Name__c FROM Account WHERE CSM__c IN :userNameChangesMap.keySet() AND RC_Account_Status__c != :ACCOUNT_STATUS_CANCELED and RC_Service_Name__c NOT IN :rcServiceList AND SegmentName__c IN :segmentList];
                    
                    for (Account acc : accountsWithCSM) {
                        Boolean isAccBrandExcluded = false;
                            for(String brand : rcBrandList) {
                                if (acc.RC_Brand__c!= null && acc.RC_Brand__c.contains(brand)) {
                                    isAccBrandExcluded = true;
                                    break;
                                }
                            }
                        if (isAccBrandExcluded) {
                            continue;
                        }
                        User usr = userNameChangesMap.get(acc.CSM__c);
                        acc.CSM_Name__c = usr.FirstName != null ? usr.FirstName + ' ' + usr.LastName : usr.LastName;
                        CSMNameChangedlist.add(acc);
                    }
                    if (!CSMNameChangedlist.isEmpty()) {
                        try {
                            Triggers.switchOff();
                            update CSMNameChangedlist;
                            Triggers.switchOn();
                        } catch (Exception e) {
                            Triggers.switchOn();
                            List<Exception_And_Notification_History__c> exceptionList = new List<Exception_And_Notification_History__c>();
                            for (Account acc : CSMNameChangedlist) {
                                Exception_And_Notification_History__c exceptionObj = new Exception_And_Notification_History__c();
                                exceptionObj.Object_Type__c = 'Exception';
                                exceptionObj.content_var_01__c = 'LTR-1496 Account CSM Name update';
                                exceptionObj.Affected_record_ID__c = acc.Id;
                                exceptionList.add(exceptionObj);
                            }
                            ExceptionAndNotificationHelper.trackExceptions(exceptionList, e);
                        }
                    }
                }
            }
        }
    }

    //Added for PBC-26526. Update CSM Manager on Account whenever Manager of the User is changed.
    public class TrackManagerChangesForCSM extends Triggers.TriggerHandlerBase {
        
        override public void handle() {
            if (Trigger.isUpdate) {
                
                Map<Id,User> userManagerChangesMap = new Map<Id,User>();
                List<Account> CSMManagerChangeAccountList = new List<Account>();

                Map<Id,User> userMap = new Map<Id,User>([SELECT Id, ManagerId, User_Manager_Name__c from User where Id in :Trigger.newMap.keyset()]);
               
                for (User usr : (List<User>)Trigger.new) {
                    User userRec = userMap.get(usr.Id);
                    if (userRec!= null && isChangedField(usr, User.ManagerId) ) {
                        userManagerChangesMap.put(usr.Id, usr);
                    }
                }

                if (!userManagerChangesMap.isEmpty()){
                    List<Account> accountsWithCSM = [SELECT Id, CSM__c, CSM_Manager__c FROM Account WHERE CSM__c IN :userManagerChangesMap.keySet()];
                    
                    for (Account acc : accountsWithCSM) {
                        User usr = userManagerChangesMap.get(acc.CSM__c);
                        acc.CSM_Manager__c = usr.User_Manager_Name__c;
                        CSMManagerChangeAccountList.add(acc);
                    }
                    if (!CSMManagerChangeAccountList.isEmpty()) {
                        try {
                            Triggers.switchOff();
                            update CSMManagerChangeAccountList;
                            Triggers.switchOn();
                        } catch (Exception e) {
                            Triggers.switchOn();
                        }
                    }
                }
            }
        }
    }
}