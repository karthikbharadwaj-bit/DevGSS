public with sharing class ApproversSearch {

    public static Map<Id, User> userStaticMap = new Map<Id, User>();
    public static User ryanAzus;

    public static User findRyanAzus() {

        //if (Test.isRunningTest()) return new User(Id = UserHelper.getHardcodedUser('0058000000371o2'), Hierarchy_Role__c = 'SSW');
        if (ryanAzus == null) {
            ryanAzus = [SELECT Id, Hierarchy_Role__c FROM User WHERE Id = :RingCentralVariousSettings__c.getInstance().SVP_WWS_User_ID__c];
        }

        return ryanAzus;
    }

    public static User findUserById(Id userId) {

        if (userStaticMap.get(userId) == null) {
            for (User item : [
                SELECT Id, Hierarchy_Role__c, FirstName, LastName,
                    ManagerId, Manager.Hierarchy_Role__c, Manager.FirstName, Manager.LastName,
                    Manager.ManagerId, Manager.Manager.Hierarchy_Role__c, Manager.Manager.FirstName, Manager.Manager.LastName,
                    Manager.Manager.ManagerId, Manager.Manager.Manager.Hierarchy_Role__c,
                    Manager.Manager.Manager.FirstName, Manager.Manager.Manager.LastName,
                    Manager.Manager.Manager.Manager.ManagerId, Manager.Manager.Manager.Manager.Hierarchy_Role__c,
                    Manager.Manager.Manager.Manager.FirstName, Manager.Manager.Manager.Manager.LastName
                FROM User
                WHERE Id = :userId
            ]) {

                userStaticMap.put(item.Id, item);
            }
        }

        return userStaticMap.get(userId);
    }

    public static Boolean checkIsFoundRoleHigherThanLastApprover(List<Map<Id, String>> userIdToHRMapsList, List<String> roleNames) {
        String lastApproverHRole = roleNames.get(roleNames.size() - 1);
        Integer lastApproverHRolePriority = UserHelper.hierarchyRolesNameToOrderMap.get(lastApproverHRole);
        Boolean isHigherThanLastApprover = false;

        for (Map<Id, String> item : userIdToHRMapsList) {
            for (Id userId : item.keySet()) {
                String userHierarchyRole = item.get(userId);

                if (userHierarchyRole != null) {
                    isHigherThanLastApprover = UserHelper.hierarchyRolesNameToOrderMap.get(userHierarchyRole) > lastApproverHRolePriority;

                    if (isHigherThanLastApprover) {
                        break;
                    }
                }
            }

            if (isHigherThanLastApprover) {
                break;
            }
        }

        return isHigherThanLastApprover;
    }

    // Variable added in CRM-1752 to differentiate between contexts of call of getDefaultApprover() from QuoteTriggerHelper (only needs a check of ID) and from ApproversSearch
    public static Boolean defaultApproverIsNeeded = false;
    public static User defaultApprover;

    /****************************************************************************************
     * @Description - Finds the oldest active approver from the queue 'DefaultApprovers'    *
     * @params void                                                                         *
     * @return User                                                                         *
    ****************************************************************************************/
    public static User getDefaultApprover() {

        if (defaultApprover == null) {
            // Retrieves the Ids of the members of the queue 'DefaultApprovers', ordered by date in which they were added
            List<GroupMember> queueMembersInOrder = getQueueMembers(GroupHelper.DEFAULT_APPROVERS_QUEUE);

            // From those members, we get only the active ones
            Map<Id, User> defaultApprovers = getApproverMapByQueueName(queueMembersInOrder);

            // Only in case of test, we select the last added (because GroupMember objects have SeeAllData=True by default)
            if (Test.isRunningTest()) {
                if (defaultApprovers.size() > 0) {
                    GroupMember mostRecentGroupMember = queueMembersInOrder[queueMembersInOrder.size() - 1];
                    defaultApprover = defaultApprovers.get(mostRecentGroupMember.UserOrGroupId);
                    return defaultApprover;
                } else {
                    AquivaHelper.throwAquivaException('There are no active approvers in DefaultApprovers queue');
                }
            }

            // Selects the first of those active users, determined by the list of user Ids 'queueMembersInOrder' (ordered by added date)
            for (GroupMember member : queueMembersInOrder) {
                if (defaultApprovers.keySet().contains(member.UserOrGroupId)) {
                    defaultApprover = defaultApprovers.get(member.UserOrGroupId);
                    break;
                }
            }
        }

        return defaultApprover;
    }

    public static List<User> getApproversByQueues(List<String> queuesNames) {
        Map<String, User> groupToApproverUserMap = new Map<String, User>();
        List<User> sortedApproversList = new List<User>();

        List<GroupMember> queueMembersInOrder = (List<GroupMember>) new GroupMemberSelector().newQueryFactory()
            .selectFields(new List<String>{
                'Id', 'UserOrGroupId', 'GroupId', 'Group.Name'
            })
            .setCondition('Group.Name in :bind0')
            .setQueryBindings(new List<Object>{
                queuesNames
            })
            .addOrdering('SystemModstamp', QueryFactory.SortOrder.DESCENDING)
            .setQueryCaching(false)
            .executeQuery();

        Set<Id> queueMemberIds = new Set<Id>();
        for (GroupMember member : queueMembersInOrder) {
            queueMemberIds.add(member.UserOrGroupId);
        }

        // From those members, we get only the active ones
        Map<Id, User> approversMap = new Map<Id, User>(
            (List<User>) new UserSelector().newQueryFactory()
                .selectFields(new List<String>{
                    'Id', 'Hierarchy_Role__c'
                })
                .setCondition('IsActive = True AND Id IN :bind0')
                .setQueryBindings(new List<Object>{
                    queueMemberIds
                })
                .setQueryCaching(false)
                .executeQuery()
        );

        // Selects the first of those active users, determined by the list of user Ids 'queueMembersInOrder' (ordered by added date)
        for (GroupMember member : queueMembersInOrder) {
            if (approversMap.keySet().contains(member.UserOrGroupId)) {
                groupToApproverUserMap.put(member.Group.Name, approversMap.get(member.UserOrGroupId));
            }
        }

        for (String queueName : queuesNames) {
            sortedApproversList.add(groupToApproverUserMap.get(queueName));
        }

        return sortedApproversList;
    }

    public static User getApproverByQueue(String queueName) {
        User approverUser;

        List<GroupMember> queueMembersInOrder = (List<GroupMember>) new GroupMemberSelector()
            .selectGroupMembersByGroupName(queueName)
            .addOrdering('SystemModstamp', QueryFactory.SortOrder.ASCENDING)
            .setQueryCaching(false)
            .executeQuery();

        Set<Id> queueMemberIds = new Set<Id>();
        for (GroupMember member : queueMembersInOrder) {
            queueMemberIds.add(member.UserOrGroupId);
        }

        // From those members, we get only the active ones
        Map<Id, User> approversMap = new Map<Id, User>(
            (List<User>) new UserSelector().newQueryFactory()
                .selectFields(new List<String>{
                    'Id', 'Hierarchy_Role__c'
                })
                .setCondition('IsActive = True AND Id IN :bind0')
                .setQueryBindings(new List<Object>{
                    queueMemberIds
                })
                .setQueryCaching(false)
                .executeQuery()
        );

        // Selects the first of those active users, determined by the list of user Ids 'queueMembersInOrder' (ordered by added date)
        for (GroupMember member : queueMembersInOrder) {
            if (approversMap.keySet().contains(member.UserOrGroupId)) {
                approverUser = approversMap.get(member.UserOrGroupId);
                break;
            }
        }

        return approverUser;
    }

    private static List<GroupMember> getQueueMembers(String queueName) {
        List<GroupMember> queueMembersInOrder = (List<GroupMember>) new GroupMemberSelector()
            .selectGroupMembersByGroupName(queueName)
            .addOrdering('SystemModstamp', QueryFactory.SortOrder.ASCENDING)
            .setQueryCaching(true)
            .executeQuery();
        return queueMembersInOrder;
    }

    private static Map<Id, User> getApproverMapByQueueName(List<GroupMember> queueMembersInOrder) {
        Set<Id> queueMemberIds = new Set<Id>();
        for (GroupMember member : queueMembersInOrder) {
            queueMemberIds.add(member.UserOrGroupId);
        }

        // From those members, we get only the active ones
        Map<Id, User> defaultApprovers = new Map<Id, User>(
            (List<User>) new UserSelector().newQueryFactory()
                .selectFields(new List<String>{
                    'Id', 'Hierarchy_Role__c'
                })
                .setCondition('IsActive = True AND Id IN :bind0')
                .setQueryBindings(new List<Object>{
                    queueMemberIds
                })
                .setQueryCaching(true)
                .executeQuery()
        );
        return defaultApprovers;
    }

    public static Boolean isSuitableHierarchyRole(String hierarchyRoleToCheck) {
        if (String.isBlank(hierarchyRoleToCheck)) {
            return false;
        }

        return UserHelper.hierarchyRolesNameToOrderMap.keySet().contains(hierarchyRoleToCheck);
    }

    public List<Id> findApproverIdsByHierarchyRoles(List<String> roleNames, User startedSearchUser) {
        if ((roleNames == null || roleNames.isEmpty()) || startedSearchUser == null) {
            return new List<Id>();
        }

        String userHRole = startedSearchUser.Hierarchy_Role__c;
        Boolean isSuitableRole = isSuitableHierarchyRole(userHRole);

        if (userHRole == null || !isSuitableRole) {
            userHRole = UserHelper.SALES_REP_ROLE;
        }

        Integer userHRolePriority = UserHelper.hierarchyRolesNameToOrderMap.get(userHRole);
        List<Map<Id, String>> userIdToHRMapsList = findManagersByRoleName(roleNames, startedSearchUser.Id);
        List<Id> approversIdList = buildApproversIdList(userIdToHRMapsList, roleNames, userHRole, userHRolePriority);

        return approversIdList;
    }

    public List<Map<Id, String>> findManagersByRoleName(List<String> roleNames, Id startedSearchUserId) {
        List<Map<Id, String>> userIdToHRMapsList = new List<Map<Id, String>>();
        userIdToHRMapsList = fillUserIdToHRMapList(userIdToHRMapsList, findUserById(startedSearchUserId), startedSearchUserId);
        Boolean foundManagerWithEmptyHRole = checkIsManagerWithEmptyRoleFound(userIdToHRMapsList);
        Boolean foundAllNeededRoles = checkIsAllRolesFound(userIdToHRMapsList, roleNames) || checkIsFoundRoleHigherThanLastApprover(userIdToHRMapsList, roleNames);

        if (foundManagerWithEmptyHRole) {
            if (foundAllNeededRoles) {
                userIdToHRMapsList = checkAndDeleteNulls(userIdToHRMapsList);
            }

            if (checkIsFoundRoleHigherThanLastApprover(userIdToHRMapsList, roleNames)) {
                userIdToHRMapsList = removeRolesStartedFromRoleThanHigherLastApprover(userIdToHRMapsList, roleNames);
            }

            // stop search and set "SWP WWS" as Level_#_Approver(who is "Ryan Azus")
            return userIdToHRMapsList;
        } else if (!foundManagerWithEmptyHRole && !foundAllNeededRoles) {
            Id lastManagerId;

            for (Id managerId : userIdToHRMapsList.get(userIdToHRMapsList.size() - 1).keySet()) {
                lastManagerId = managerId;
            }

            userIdToHRMapsList = fillUserIdToHRMapList(userIdToHRMapsList, findUserById(lastManagerId), startedSearchUserId);
        }

        foundManagerWithEmptyHRole = checkIsManagerWithEmptyRoleFound(userIdToHRMapsList);
        foundAllNeededRoles = checkIsAllRolesFound(userIdToHRMapsList, roleNames) || checkIsFoundRoleHigherThanLastApprover(userIdToHRMapsList, roleNames);

        if (foundManagerWithEmptyHRole && foundAllNeededRoles) {
            userIdToHRMapsList = checkAndDeleteNulls(userIdToHRMapsList);
        }

        if (checkIsFoundRoleHigherThanLastApprover(userIdToHRMapsList, roleNames)) {
            userIdToHRMapsList = removeRolesStartedFromRoleThanHigherLastApprover(userIdToHRMapsList, roleNames);
        }

        return userIdToHRMapsList;
    }

    public List<Id> buildApproversIdList(List<Map<Id, String>> userIdToHRMapsList, List<String> roleList, String startedSearchUserHRole, Integer startedSearchUserHRoleProirity) {
        Boolean svpWwsRoleAlreadyDetected = isSvpWwsDetected(userIdToHRMapsList);
        Boolean isFoundAllRoles = validateAllSuitableRolesFound(userIdToHRMapsList, roleList);
        Boolean foundSwpWwsUser = false;
        List<Id> approversIdList = new List<Id>();

        for (Map<Id, String> item : userIdToHRMapsList) {
            for (Id userId : item.keySet()) {
                String userHierarchyRole = item.get(userId);

                if (userHierarchyRole != null) {
                    Integer userHRolePriority = UserHelper.hierarchyRolesNameToOrderMap.get(userHierarchyRole);
                    if (startedSearchUserHRole == userHierarchyRole || startedSearchUserHRoleProirity > userHRolePriority) {
                        continue;
                    } else {
                        approversIdList.add(userId);
                    }
                } else {
                    // we found manager in chain with empty Hierarcy role
                    // so set Ryan Azus as approver for current level
                    if (!svpWwsRoleAlreadyDetected) {
                        defaultApproverIsNeeded = true;
                        User svpWwsUser = getDefaultApprover();
                        approversIdList.add(svpWwsUser.Id);
                    }

                    foundSwpWwsUser = true;

                    break;
                }
            }

            if (foundSwpWwsUser) {
                break;
            }
        }

        if (!isFoundAllRoles && !foundSwpWwsUser) {
            System.debug('we do not found user with null in Hierarchy role AND we do not found all needed roles in managers chain. Check approversIdList and add "Ryan Azus" as last Approver');

            if (!svpWwsRoleAlreadyDetected) {
                defaultApproverIsNeeded = true;
                User svpWwsUser = getDefaultApprover();
                approversIdList.add(svpWwsUser.Id);
            }
        }

        return approversIdList;
    }
    public List<Id> findApproverIdsByHierarchyRolesforBiz(List<String> roleNames, User startedSearchUser) {
        if ((roleNames == null || roleNames.isEmpty()) || startedSearchUser == null) {
            return new List<Id>();
        }

        String userHRole = startedSearchUser.Hierarchy_Role__c;
        Boolean isSuitableRole = isSuitableHierarchyRole(userHRole);

        if (userHRole == null || !isSuitableRole) {
            userHRole = UserHelper.SALES_REP_ROLE;
        }

        Integer userHRolePriority = UserHelper.hierarchyRolesNameToOrderMap.get(userHRole);
        List<Map<Id, String>> userIdToHRMapsList = findManagersByRoleName(roleNames, startedSearchUser.Id);
        List<Id> approversIdList = buildApproversIdListforBiz(userIdToHRMapsList, roleNames, userHRole, userHRolePriority);

        return approversIdList;
    }

    public List<Id> buildApproversIdListforBiz(List<Map<Id, String>> userIdToHRMapsList, List<String> roleList, String startedSearchUserHRole, Integer startedSearchUserHRoleProirity) {
        Boolean svpWwsRoleAlreadyDetected = isSvpWwsDetected(userIdToHRMapsList);
        Boolean isFoundAllRoles = validateAllSuitableRolesFound(userIdToHRMapsList, roleList);
        Boolean foundSwpWwsUser = false;
        List<Id> approversIdList = new List<Id>();

        for (Map<Id, String> item : userIdToHRMapsList) {
            for (Id userId : item.keySet()) {
                String userHierarchyRole = item.get(userId);
                if (userHierarchyRole != null) {
                    Integer userHRolePriority = UserHelper.hierarchyRolesNameToOrderMap.get(userHierarchyRole);
                    if (startedSearchUserHRole == userHierarchyRole || startedSearchUserHRoleProirity > userHRolePriority) {
                        continue;
                    } else {
                        approversIdList.add(userId);
                    }
                } else {
                    // we found manager in chain with empty Hierarcy role
                    // so set Ryan Azus as approver for current level
                    if (!svpWwsRoleAlreadyDetected) {
                        User svpWwsUser = findRyanAzus();
                        approversIdList.add(svpWwsUser.Id);
                    }
                    foundSwpWwsUser = true;
                    break;
                }
            }

            if (foundSwpWwsUser) {
                break;
            }
        }

        if (!isFoundAllRoles && !foundSwpWwsUser) {
            System.debug('we do not found user with null in Hierarchy role AND we do not found all needed roles in managers chain. Check approversIdList and add "Ryan Azus" as last Approver');
            if (!svpWwsRoleAlreadyDetected) {
                User svpWwsUser = findRyanAzus();
                approversIdList.add(svpWwsUser.Id);
            }
        }

        return approversIdList;
    }

    private List<Map<Id, String>> fillUserIdToHRMapList(List<Map<Id, String>> userIdToHRMapsList, User currentUser, Id startedSearchUserId) {
        if (userIdToHRMapsList == null) {
            userIdToHRMapsList = new List<Map<Id, String>>();
        }

        Id userId = currentUser.Id;
        String userHRole = currentUser.Hierarchy_Role__c;
        Boolean isUserStartedSearch = (userId == startedSearchUserId);
        Boolean isSuitableRole = UserHelper.hierarchyRolesNameToOrderMap.keySet().contains(userHRole);

        if (!isSuitableRole && !isUserStartedSearch) {
            return userIdToHRMapsList;
        }

        if (userId == startedSearchUserId && userHRole == null) {
            if (!alreadyFoundUserId(userIdToHRMapsList, userId)) {
                userIdToHRMapsList.add(new Map<Id, String>{
                    userId => UserHelper.SALES_REP_ROLE
                });
            }
        } else {
            if (!alreadyFoundUserId(userIdToHRMapsList, userId) && !alreadyFoundHRole(userIdToHRMapsList, userHRole) && isSuitableRole) {
                userIdToHRMapsList.add(new Map<Id, String>{
                    userId => userHRole
                });
            }
        }

        Id managerId = currentUser.ManagerId;
        String managerHRole = currentUser.Manager.Hierarchy_Role__c;
        userIdToHRMapsList = addInfoToMapList(userIdToHRMapsList, managerId, managerHRole);

        if (managerHRole == null) {
            return userIdToHRMapsList;
        }

        Id managerManagerId = currentUser.Manager.ManagerId;
        String managerManagerHRole = currentUser.Manager.Manager.Hierarchy_Role__c;
        userIdToHRMapsList = addInfoToMapList(userIdToHRMapsList, managerManagerId, managerManagerHRole);

        if (managerManagerHRole == null) {
            return userIdToHRMapsList;
        }

        Id managerManagerManagerId = currentUser.Manager.Manager.ManagerId;
        String managerManagerManagerHRole = currentUser.Manager.Manager.Manager.Hierarchy_Role__c;
        userIdToHRMapsList = addInfoToMapList(userIdToHRMapsList, managerManagerManagerId, managerManagerManagerHRole);

        if (managerManagerManagerHRole == null) {
            return userIdToHRMapsList;
        }

        Id managerManagerManagerManagerId = currentUser.Manager.Manager.Manager.ManagerId;
        String managerManagerManagerManagerHRole = currentUser.Manager.Manager.Manager.Manager.Hierarchy_Role__c;
        userIdToHRMapsList = addInfoToMapList(userIdToHRMapsList, managerManagerManagerManagerId, managerManagerManagerManagerHRole);

        if (managerManagerManagerManagerHRole == null) {
            return userIdToHRMapsList;
        }

        return userIdToHRMapsList;
    }

    private Boolean alreadyFoundUserId(List<Map<Id, String>> userIdToHRMapsList, Id userId) {
        Boolean result = false;

        for (Map<Id, String> item : userIdToHRMapsList) {
            if (item.keySet().contains(userId)) {
                result = true;
                break;
            }
        }

        return result;
    }

    private Boolean alreadyFoundHRole(List<Map<Id, String>> userIdToHRMapsList, String hRole) {
        Set<String> foundedHRoles = new Set<String>();

        for (Map<Id, String> item : userIdToHRMapsList) {
            foundedHRoles.addAll(item.values());
        }

        return foundedHRoles.contains(hRole);
    }

    private List<Map<Id, String>> addInfoToMapList(List<Map<Id, String>> userIdToHRMapsList, Id userId, String userHRoleName) {
        if (userIdToHRMapsList == null) {
            userIdToHRMapsList = new List<Map<Id, String>>();
        }

        if (userId == null) {
            return userIdToHRMapsList;
        }

        Boolean isSuitableRole = UserHelper.hierarchyRolesNameToOrderMap.keySet().contains(userHRoleName);

        if (userHRoleName == null) {
            if (!alreadyFoundUserId(userIdToHRMapsList, userId)) {
                userIdToHRMapsList.add(new Map<Id, String>{
                    userId => null
                });
            }

        } else {
            if (isSuitableRole && !alreadyFoundUserId(userIdToHRMapsList, userId) && !alreadyFoundHRole(userIdToHRMapsList, userHRoleName)) {
                userIdToHRMapsList.add(new Map<Id, String>{
                    userId => userHRoleName
                });
            }
        }

        return userIdToHRMapsList;
    }

    private Boolean checkIsManagerWithEmptyRoleFound(List<Map<Id, String>> userIdToHRMapsList) {
        Boolean result = false;

        for (Map<Id, String> item : userIdToHRMapsList) {
            for (Id userId : item.keySet()) {
                String userHierarchyRole = item.get(userId);

                if (userHierarchyRole == null) {
                    result = true;
                    break;
                }
            }

            if (result == true) {
                break;
            }
        }

        return result;
    }

    private Boolean checkIsAllRolesFound(List<Map<Id, String>> userIdToHRMapsList, List<String> roleList) {
        List<String> roleListWithoutSalesRepRole = new List<String>();

        for (String roleName : roleList) {
            if (roleName != UserHelper.SALES_REP_ROLE) {
                roleListWithoutSalesRepRole.add(roleName);
            }
        }

        Set<String> foundedRoles = new Set<String>();

        for (Map<Id, String> item : userIdToHRMapsList) {
            for (Id userId : item.keySet()) {
                String userHierarchyRole = item.get(userId);

                if (userHierarchyRole != null) {
                    foundedRoles.add(userHierarchyRole);
                }
            }
        }

        return foundedRoles.containsAll(roleListWithoutSalesRepRole);
    }

    private List<Map<Id, String>> checkAndDeleteNulls(List<Map<Id, String>> userIdToHRMapsList) {
        Map<Id, String> resMap = new Map<Id, String>();
        List<Map<Id, String>> resList = new List<Map<Id, String>>();

        for (Map<Id, String> hrMap : userIdToHRMapsList) {
            for (Id key : hrMap.keySet()) {
                String val = hrMap.get(key);

                if (val != null) {
                    resMap.put(key, val);
                }
            }

            if (resMap.size() > 0) {
                resList.add(resMap);
                resMap = new Map<Id, String>();
            }
        }

        return resList;
    }

    private List<Map<Id, String>> removeRolesStartedFromRoleThanHigherLastApprover(List<Map<Id, String>> userIdToHRMapsList, List<String> roleNames) {
        String lastApproverHRole = roleNames.get(roleNames.size() - 1);
        Integer lastApproverHRolePriority = UserHelper.hierarchyRolesNameToOrderMap.get(lastApproverHRole);
        List<Map<Id, String>> resultUserIdToHRMapsList = new List<Map<Id, String>>();
        Boolean isHigherThanLastApprover = false;

        for (Map<Id, String> item : userIdToHRMapsList) {
            for (Id userId : item.keySet()) {
                String userHierarchyRole = item.get(userId);

                if (userHierarchyRole != null) {
                    isHigherThanLastApprover = UserHelper.hierarchyRolesNameToOrderMap.get(userHierarchyRole) >= lastApproverHRolePriority;

                    if (isHigherThanLastApprover) {
                        resultUserIdToHRMapsList.add(new Map<Id, String>{
                            userId => userHierarchyRole
                        });
                        break;
                    } else {
                        resultUserIdToHRMapsList.add(new Map<Id, String>{
                            userId => userHierarchyRole
                        });
                    }
                }
            }

            if (isHigherThanLastApprover) {
                break;
            }
        }

        return resultUserIdToHRMapsList;
    }

    private Boolean isSvpWwsDetected(List<Map<Id, String>> userIdToHRMapsList) {

        Set<String> foundedRoles = new Set<String>();

        for (Map<Id, String> item : userIdToHRMapsList) {
            for (Id userId : item.keySet()) {
                String userHierarchyRole = item.get(userId);

                if (userHierarchyRole != null) {
                    foundedRoles.add(userHierarchyRole);
                }
            }
        }

        return foundedRoles.contains(UserHelper.SVP_WWS_ROLE);
    }

    private Boolean validateAllSuitableRolesFound(List<Map<Id, String>> userIdToHRMapsList, List<String> roleList) {
        List<String> roleListWithoutSalesRepRole = new List<String>();

        for (String roleName : roleList) {
            if (roleName != UserHelper.SALES_REP_ROLE) {
                roleListWithoutSalesRepRole.add(roleName);
            }
        }

        Set<String> foundedRoles = new Set<String>();

        for (Map<Id, String> item : userIdToHRMapsList) {
            for (Id userId : item.keySet()) {
                String userHierarchyRole = item.get(userId);

                if (userHierarchyRole != null) {
                    foundedRoles.add(userHierarchyRole);
                }
            }
        }

        Boolean missingRoleDetected = false;

        for (String roleToFind : roleListWithoutSalesRepRole) {
            Integer roleToFindPriority = UserHelper.hierarchyRolesNameToOrderMap.get(roleToFind);
            Boolean foundRoleEqualORHigher = false;

            for (String foundedRole : foundedRoles) {
                Integer foundedRolePriority = UserHelper.hierarchyRolesNameToOrderMap.get(foundedRole);

                if (foundedRolePriority >= roleToFindPriority) {
                    foundRoleEqualORHigher = true;
                }
            }

            if (!foundRoleEqualORHigher) {
                System.debug('do not found suitable role(equal or higher by priority) for role >>> ' + roleToFind);
                missingRoleDetected = true;
            }
        }

        return !missingRoleDetected;
    }
}