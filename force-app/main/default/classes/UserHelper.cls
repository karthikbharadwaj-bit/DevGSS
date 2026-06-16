/**
 * This is helper class for User standard object
 * Keep all static variables and helper methods related to it here
 *
 * It's might be better to keep here helper methods that do not do any SOQL
 * so they could be reused in triggers or controllers
 */
public with sharing class UserHelper {
    public static String LEANDATAUSERID {
        get {
            if(LEANDATAUSERID == null) {
                LEANDATAUSERID = 
                    (LeadRoutingSettings__c.getOrgDefaults().LeanDataUserId__c != null ?
                    LeadRoutingSettings__c.getOrgDefaults().LeanDataUserId__c.left(15) :
                    HardcodedIdsMapper.getMatchedObjectId('0053400000C176u'));
            }
            return LEANDATAUSERID;
        }
        set;
    }

    public static final String SALES_REP_ROLE = 'Sales Rep';
    public static final String DIRECT_MANAGER_ROLE = 'Direct Manager';
    public static final String SEGMENT_LEADER_ROLE = 'Segment Leader';
    public static final String SVP_WWS_DIRECTS_ROLE = 'SVP WWS Directs';
    public static final String SVP_WWS_ROLE = 'SVP WWS';
    public static final String COO_ROLE = 'COO';

    public static final String RCSFSYNC_USER_NAME = 'RCSF Sync';
    public static final String MARKETO_USER_NAME = 'User Marketo';
    public static final String API_USER_NAME = 'API User';
    public static final String LEANDATA_USER_NAME = 'LeanData Queue';
    public static final String MIGRATION_AGENT = 'Migration Agent';

    // SegmentPicklist__c
    public static final String SEGMENT_SOHO = 'SOHO';
    public static final String SEGMENT_MID_MARKET = 'Mid Market';
    public static final String SEGMENT_MAJORS = 'Majors';
    public static final String SEGMENT_ENTERPRISE = 'Enterprise';
    public static final String SEGMENT_OTHER = 'Other';
    public static final String SEGMENT_EXPANSION_ENTERPRISE = 'Expansion Enterprise';
    public static final String SEGMENT_EXPANSION_MAJORS = 'Expansion Majors';
    public static final String SEGMENT_SIGNATURE = 'Signature';
    public static final String SEGMENT_SMALL_BUSINESS = 'Small Business';
    public static final String SEGMENT_SMB = 'SMB';

    public static final Set<String> SMALL_BUSINESS_SEGMENTS = new Set<String> {
        SEGMENT_SMALL_BUSINESS,
        SEGMENT_SOHO,
        SEGMENT_SMB
    };

    private static final String MULTIPRODUCT_TECHNICAL_USER_NAME = 'Multiproduct Technical User';
    private static User multiproductUser;

    public static Map<String, Integer> hierarchyRolesNameToOrderMap = new Map<String, Integer> {
        SALES_REP_ROLE => 1,
        DIRECT_MANAGER_ROLE => 2,
        SEGMENT_LEADER_ROLE => 3,
        SVP_WWS_DIRECTS_ROLE => 4,
        SVP_WWS_ROLE => 5
    };

    public static Map<Integer, String> hierarchyRolesOrderToNameMap = new Map<Integer, String>{
        1 => SALES_REP_ROLE,
        2 => DIRECT_MANAGER_ROLE,
        3 => SEGMENT_LEADER_ROLE,
        4 => SVP_WWS_DIRECTS_ROLE,
        5 => SVP_WWS_ROLE
    };

    public static final String EMPLOYEE_LOCATION_MANILA_PHILIPPINES = 'Manila, Philippines';
    public static final Set<String> EMPLOYEE_LOCATION_MANILA = new Set<String>{
        'Manila (CSS), Philippines',
        EMPLOYEE_LOCATION_MANILA_PHILIPPINES
    };

    public static Map<Id, User> userStaticMap = new Map<Id, User>();

    private static String userPrefix {
        get {
            if(userPrefix == null) {
                userPrefix = Schema.SObjectType.User.getKeyPrefix();
            }
            return userPrefix;
        }
        set;
    }

    public static Boolean isUser(Id passedId) {
        String passedIdStr = (String) passedId;
        return passedIdStr.startsWith(userPrefix);
    }

    public static Map<Id, User> getActiveUsers(Map<Id, User> users) {
        Map<Id, User> activeUsers = new Map<Id, User>();
        if (users == null || users.size() == 0) {
            return activeUsers;
        }
        for (User u : users.values()) {
            if (u.isActive == false) {
                continue;
            }
            activeUsers.put(u.Id, u);
        }
        return activeUsers;
    }

    /**
    * @description Checks if users with passed ids were queried before. If they were - return from static map
    * if they weren't - query them, add to static map and return.
    * @param  Set<Id> - user ids.
    * @return Map<Id, User> - Users related to user ids.
    */
    public static Map<Id, User> getORQueryUsers(Set<Id> userIdsToGet) {
        if (userIdsToGet == null ) {
            throw new AquivaHelper.AquivaException('userIdsToGet in method "getORQueryUsers" is empty');
        }
        if (userIdsToGet.size() == 0) {
            return new Map<Id, User>();
        }
        if (userStaticMap.keySet().containsAll(userIdsToGet) == true) {
            return getCertainUsersFromStaticMap(userIdsToGet);
        }
        Set<Id> userIdsToQuery = getUserIdsToQuery(userIdsToGet);
        userStaticMap.putAll([
                SELECT Id, FirstName, LastName, Name, Email, Phone, Division, UserRole.Name, PID__c, Team__c, isActive,
                        ManagerId, Manager.Email, Manager.FirstName, Manager.LastName, Manager.ManagerId,
                        Manager.Manager.ManagerId, ContactId, Contact.Account.Inside_Sales_Rep__c, Profile.Name,
                        Contact.Account.Inside_Sales_Rep__r.ManagerId,
                        Contact.Account.Inside_Sales_Rep__r.Manager.ManagerId, Contact.Account.Current_Owner__c,
                        Contact.Account.Current_Owner__r.ManagerId, Contact.Account.Current_Owner__r.Manager.ManagerId
                FROM User
                WHERE Id IN: userIdsToQuery
        ]);
        return getCertainUsersFromStaticMap(userIdsToGet);
    }

    /**
    * @description executes getORQueryuserStaticMap(...) for single user.
    */
    public static User getORQueryUser(Id userId) {
        Map<Id, User> queriedUsers = getORQueryUsers(new Set<Id>{userId});
        for (User u : queriedUsers.values()) {
            return u;
        }
        return null;
    }

    private static Map<Id, User> getCertainUsersFromStaticMap(Set<Id> userIdsToGet) {
        Map<Id, User> usersToReturn = new Map<Id, User>();
        for (Id userId : userIdsToGet) {
            User u = userStaticMap.get(userId);
            if (u == null) {
                continue;
            }
            usersToReturn.put(userId, u);
        }
        return usersToReturn;
    }

    private static Set<Id> getUserIdsToQuery(Set<Id> userIds) {
        Set<Id> userIdsToQuery = new Set<Id>();
        userIdsToQuery.addAll(userIds);
        //removing users that were queried and set to userStaticMap before.
        userIdsToQuery.removeAll(userStaticMap.keySet());
        return userIdsToQuery;
    }

    public static Integer getUserTZOffset() {
        return UserInfo.getTimezone().getOffset(System.now());
    }

    public static List<User> getCachedUsers() {
        List<User> cachedUsers = (List<User>) new UserSelector()
            .selectCachedUsers()
            .executeQuery();

        return cachedUsers;
    }

    public static User getCachedCurrentUser() {
        User currentUser;

        List<User> cachedUsers = getCachedUsers();

        for (User user : cachedUsers) {
            if (user.Id == UserInfo.getUserId()) {
                currentUser = user;
                break;
            }
        }

        return currentUser;
    }

    public static String getUniqueUserName() {
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        return orgId + dateString + '_' + randomInt + '@RingCentralTest.tld';
    }

    public static Set<Id> getUsersByPermissionSetAssignees(String permissionName) {
        Set<Id> usersIdsSet = new Set<Id>();
        List<PermissionSetAssignment> psAssignments = (List<PermissionSetAssignment>) new PermissionSetAssignmentSelector()
            .selectPermissionSetAssignmentByName(new List<String>{permissionName}).executeQuery();
        for(PermissionSetAssignment psAssignment : psAssignments) {
            usersIdsSet.add(psAssignment.AssigneeId);
        }
        return usersIdsSet;
    }

    public static User getMultiproductTechnicalUser() {
        if (multiproductUser != null) {
            return multiproductUser;
        }

        List<User> userList = (List<User>) new UserSelector()
            .selectUserByName(new List<Object> {new List<String> {MULTIPRODUCT_TECHNICAL_USER_NAME}})
            .executeQuery();

        if (!userList.isEmpty()) {
            multiproductUser = userList.get(0);
        }

        return multiproductUser;
    }

    public static Boolean isSegmentEnterprise(User u) {
        String segment = u?.SegmentPicklist__c;
        return segment == UserHelper.SEGMENT_ENTERPRISE
            || segment == UserHelper.SEGMENT_EXPANSION_ENTERPRISE;
    }
    
    /**
   * Retrieves user details using cache
   * @param userIds Set of user IDs to retrieve
   * @return Map of user ID to User record
   */
    public static Map<Id, User> retrieveUserMapWithCache(Set<Id> userIds) {
        Map<Id, User> userDetailMap = new Map<Id, User>();
        
        if(userIds.isEmpty()) {
            return userDetailMap;
        }
        
        Set<Id> userIdsNotInCache = new Set<Id>();
        
        // Check cache for existing users
        for(Id userId : userIds) {
            if(PlatformCacheUtility.contains(PlatformCacheUtility.SESSION_CACHE, userId, PlatformCacheUtility.CURRENT_USER_SESSION_DATA)) {
                User cachedUser = (User) PlatformCacheUtility.getDynamicRecord(
                PlatformCacheUtility.SESSION_CACHE, userId, PlatformCacheUtility.CURRENT_USER_SESSION_DATA, Constants.CONST_USER);
                userDetailMap.put(userId, cachedUser);
            } else {
                userIdsNotInCache.add(userId);
            }
        }
        
        // Query and cache users not found in cache
        if(!userIdsNotInCache.isEmpty()) {
            List<User> userList = queryUsersWithSelectorForPlatformCache(userIdsNotInCache);
            for(User user : userList) {
                PlatformCacheUtility.put(PlatformCacheUtility.SESSION_CACHE, user.Id, user, PlatformCacheUtility.CURRENT_USER_SESSION_DATA);
                userDetailMap.put(user.Id, user);
            }
        }
        return userDetailMap;
    }

    /**
     * Retrieves users using cache
     * @param userIds Set of user IDs to retrieve
     * @return List of User records
     */
    public static List<User> retrieveUsersWithCache(Set<Id> userIds) {
        List<User> userList = new List<User>();
        
        if(userIds.isEmpty()) {
            return userList;
        }
        
        Set<Id> userIdsNotInCache = new Set<Id>();
        
        // Check cache for existing users
        for(Id userId : userIds) {
            if(PlatformCacheUtility.contains(PlatformCacheUtility.SESSION_CACHE, userId, PlatformCacheUtility.CURRENT_USER_SESSION_DATA)) {
                User cachedUser = (User) PlatformCacheUtility.getDynamicRecord(
                PlatformCacheUtility.SESSION_CACHE, userId, PlatformCacheUtility.CURRENT_USER_SESSION_DATA, Constants.CONST_USER);
                userList.add(cachedUser);
            } else {
                userIdsNotInCache.add(userId);
            }
        }
        
        // Query and cache users not found in cache
        if(!userIdsNotInCache.isEmpty()) {
            List<User> userListToAdd = queryUsersWithSelectorForPlatformCache(userIdsNotInCache);
            for(User user : userListToAdd) {
                PlatformCacheUtility.put(PlatformCacheUtility.SESSION_CACHE, user.Id, user, PlatformCacheUtility.CURRENT_USER_SESSION_DATA);
                userList.add(user);
            }
        }
        return userList;
    }

    public static List<User> queryUsersWithSelectorForPlatformCache(Set<Id> userIds) {
        List<String> userFields = new UserSelector().getCacheableUserFields();
        
        return (List<User>) new UserSelector()
            .selectUsersByIds(userIds)
            .selectFields(userFields)
            .executeQuery();
    }
}