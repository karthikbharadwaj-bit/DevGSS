public without sharing class GroupHelper {
    public static final String GROUP_SUPPORT_REFUND_APPROVAL_QUEUE = 'Support_Refund_Approval_Queue';
    public static final String GROUP_SALES_DESK_LEGAL_QUEUE = 'Sales_Desk_Legal';
    public static final String GROUP_REVENUE_OPERATIONS_TEAM_QUEUE = 'Revenue_Operations_Team';
    public static final String GROUP_TREASURER_QUEUE = 'Treasurer_Queue';
    public static final String GROUP_CREDIT_LIMIT_APPROVAL_QUEUE = 'Credit Limit Approval';
    public static final String APPROVAL_DOWNSELL_QUEUE = 'In Contract Downsell';
    public static final String APPROVAL_NGBS_PROSERV_QUEUE = 'ProServ Approval Queue';

    public static final String RESSELER_TEAM_DEV_NAME = 'Reseller Team';
    public static final String ENGAGE_DIGITAL_DEV_NAME = 'RC Engage Digital Support';

    public static final String GROUP_TYPE_QUEUE = 'Queue';
    public static final String DEFAULT_APPROVERS_QUEUE = 'DefaultApprovers';

    private static final Set<String> CACHED_GROUPS = new Set<String>{
            GROUP_SUPPORT_REFUND_APPROVAL_QUEUE,
            GROUP_SALES_DESK_LEGAL_QUEUE,
            GROUP_REVENUE_OPERATIONS_TEAM_QUEUE,
            GROUP_TREASURER_QUEUE
    };

    @TestVisible
    private static Map<String, String> mapKCSRoleAndDeveloperGroupName = new Map<String, String>{
        'KCS Candidate' => 'KCS_Candidate',
        'KCS Contributor' => 'KCS_Contributor',
        'KCS Publisher' => 'KCS_Publisher',
        'KCS Coach' => 'KCS_Coach',
        'Knowledge Domain Expert' => 'Knowledge_Domain_Expert'
    };

    private static final List<String> KCS_PERMISSION_SET_NAMES = new List<String>{'KCS_Candidate', 'KCS_Contributor',
        'KCS_Publisher', 'KCS_Coach', 'Knowledge_Domain_Expert'};

    public static Map<String, Group> groupDeveloperNameToGroup {
        get {
            if(groupDeveloperNameToGroup == null) {
                cacheGroupDeveloperNameToGroup();
            }
            return groupDeveloperNameToGroup;
        }
        set;
    }

    private static void cacheGroupDeveloperNameToGroup() {
        groupDeveloperNameToGroup = new Map<String, Group>();

        for (Group gp : [
                SELECT Id, Type, DeveloperName,
                    (SELECT Id, UserOrGroupId FROM GroupMembers)
                FROM Group
                WHERE (Type = :GROUP_TYPE_QUEUE AND DeveloperName IN:CACHED_GROUPS)
        ]) {
            groupDeveloperNameToGroup.put(gp.DeveloperName, gp);
        }
    }

    public static Boolean isUserInQueue(String groupDeveloperName){
        Group g = groupDeveloperNameToGroup.get(groupDeveloperName);

        if(g == null || g.GroupMembers == null) {
            return false;
        }

        Set<Id> userIds = new Set<Id>();
        for (GroupMember gm : g.GroupMembers) {
            userIds.add(gm.UserOrGroupId);
        }

        return userIds.contains(UserInfo.getUserId());
    }

    public static Map<String, Id> defineGroupIdsBasedOnName(Set<String> groupNames) {
        Map<String, Id> mapGroupNameAndId = new Map<String, Id>();
        List<Object> bindings = new List<Object>();
        bindings.add(groupNames);
        List<Group> groups = new GroupSelector()
            .selectGroupBasedOnDeveloperNames(bindings)
            .executeQuery();

        for (Group g : groups) {
            mapGroupNameAndId.put(g.DeveloperName, g.Id);
        }
        return mapGroupNameAndId;
    }

    public static String getGroupNameBasedOnUserKCSRole(String userKCSRole) {
        if (mapKCSRoleAndDeveloperGroupName.containsKey(userKCSRole)) {
            return mapKCSRoleAndDeveloperGroupName.get(userKCSRole);
        }
        return ''; // not defined
    }

    public static Map<String, Id> definePermissionSetIdBasedOnGroupName() {
        List<Object> bindings = new List<Object>();
        bindings.add(KCS_PERMISSION_SET_NAMES);
        List<PermissionSet> permissionSet = (List<PermissionSet>) new PermissionSetSelector()
            .selectPermissionSetsByName(bindings)
            .executeQuery();
        Map<String, String> mapDeveloperGroupNameAndPermissionSetName = new Map<String, String>();
        for (PermissionSet ps : permissionSet) {
            mapDeveloperGroupNameAndPermissionSetName.put(ps.Name, ps.Id);
        }
        return mapDeveloperGroupNameAndPermissionSetName;
    }
}