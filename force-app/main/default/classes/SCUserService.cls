public with sharing class SCUserService {

    public static final String PROFILE_NAME_ADMIN = 'RC Admin User';
    public static final String ERROR_USER_ID_IS_EMPTY = 'Enterprise Account Id is empty';
    public static final String ERROR_NO_USER_WAS_FOUND = 'No user was found';
    public static final String ERROR_CONTACT_EMAIL_IS_EMPTY = 'Contact Email is empty';
    public static final String ERROR_NO_USER_TO_FILTER_BY = 'There is no user to filter cases by';
    public static final String CUSTOM_PERMISSION_NAME = 'Can_see_community_billing_info';
    private static List<String> USER_FIELDS = new List<String> {
        'Id', 'Name', 'FirstName', 'LastName', 'Address', 'PostalCode', 'Street', 'City', 'State', 'Country', 'Email',
        'ProfileId', 'ContactId', 'Contact.AccountId', 'Contact.Name', 'Contact.Title', 'Contact.Email', 'Contact.Phone',
        'Contact.FirstName', 'Contact.LastName', 'Contact.Phone_Ext__c', 'Contact.Job_Role__c', 'Contact.Account_Tier__c',
        'Contact.Account_Brand__c', 'Contact.Package_Name__c', 'Contact.Implementation_Status__c',
        'Contact.Account_Number_of_DLs__c', 'Contact.Owner.Name', 'Contact.Account.BillingAddress', 'Contact.Account.Name',
        'Contact.Account.CSM_Name__c', 'FullPhotoUrl', 'Contact.Account.CSM_Email__c', 'Contact.Account.CSM__r.SmallPhotoUrl',
        'Contact.Account.CSM__r.FullPhotoUrl','Contact.Account.CSM__r.Phone','Contact.Account.Account_POD__c','Contact.Account.RC_User_ID__c',
        'Contact.Account.Invoice_Terms__c', 'Contact.Account.Next_Renewal_Date__c', 'Contact.Account.Payment_Plan__c',
        'Contact.Account.Segment_Name__r.Name', 'Contact.Account.RC_Account_Status__c', 'Contact.Account.RC_Tier__c',
        'Contact.Account.Total_Account_DL_s__c', 'Contact.Account.RC_Brand__c', 'Contact.Account.VIP_Account_Indicator__c',
        'Contact.Account.Number_of_DL_s__c', 'Contact.Account.Service_Status__c',
        'Contact.Account.Extended_Enterprise_Support_Customer__c', 'Contact.Account.Package_Status__c',
        'Contact.Account.Sales_Agreement_End_Date__c', 'Contact.Account.VideoProvider__c', 'Contact.Account.CreatedDate',
        'Contact.Account.Total_Account_DL_s__c', 'Contact.Account.Current_Owner__r.Name',
        'Contact.Account.Current_Owner__r.Email', 'Contact.Account.Current_Owner__r.Phone',
        'Contact.Account.inContact_Cluster__c', 'Contact.Account.Account_POD__c'
    };

    public static User currentUser {
        get {
            if (currentUser == null) {
                List<User> users = (List<User>) new UserSelector()
                    .selectUsersByIdWithContactInfo(new List<Object>{new List<String>{UserInfo.getUserId()}})
                    .executeQuery();
                if (!users.isEmpty()) {
                    currentUser = users[0];
                }
            }
            return currentUser;
        }
        private set;
    }

    public static List<Package__c> accountPackages {
        get {
            if (accountPackages == null) {
                accountPackages = new PackageSelector()
                    .selectPackagesForNewReferences(new List<Object> {new Set<Id>{currentUser.Contact.AccountId}})
                    .executeQuery();
            }
            return accountPackages;
        }
        private set;
    }

    public static String accountPOD {
        get {

            if (accountPOD == null) {
                Map<Id, Package__c> officePackageToProcessMap = PackageHelper.filterPackagesByService(accountPackages, AccountHelper.SERVICE_TYPE_OFFICE);
                Package__c officePackageToProcess = officePackageToProcessMap.get(currentUser.Contact.AccountId);
                accountPOD = officePackageToProcess != null && !String.isEmpty(officePackageToProcess.Account_POD__c)
                    ? officePackageToProcess.Account_POD__c.trim().replace('ADB', 'POD')
                    : '';
            }
            return accountPOD;
        }
        private set;
    }

    public static String accountCluster {
        get {
            if (accountCluster == null) {
                accountCluster = String.isEmpty(currentUser.Contact.Account.inContact_Cluster__c)
                    ? ''
                    : currentUser.Contact.Account.inContact_Cluster__c.trim();
            }
            return accountCluster;
        }
        private set;
    }

    public static List<User> getRCAdminsForUserAccount(String userId) {

        Map<Id, Set<Id>> result = new Map<Id, Set<Id>>();

        List<User> users = (List<User>) new UserSelector()
            .selectUsersByIdWithContactInfo(new List<Object>{new List<String>{userId}})
            .executeQuery();

        if (users.isEmpty()) {
            AquivaHelper.throwAquivaException('User does not exist');
        }

        return getRCAdminsForAccount(new Set<String>{users[0].AccountId});
    }

    public static List<User> getRCAdminsForAccount(Set<String> accIds) {

        if (accIds == null || accIds.isEmpty()) {
            return new List<User>();
        }

        return new UserSelector()
            .selectUsersByAccountIdsAndProfileName(
                new List<Object>{
                    accIds,
                    new List<String>{PROFILE_NAME_ADMIN}
                }
            )
            .executeQuery();
    }

    public static Boolean isCurrentUserSCAdmin {
        get {
            if (isCurrentUserSCAdmin == null) {
                if (currentUser == null) {
                    isCurrentUserSCAdmin = false;
                } else {
                    isCurrentUserSCAdmin = isUserSCAdmin(currentUser.Id);
                }
            }
            return isCurrentUserSCAdmin;
        }
        private set;
    }

    public static Boolean isUserSCAdmin(String userId) {

        if (String.isBlank(userId)) {
            AquivaHelper.throwAquivaException(ERROR_USER_ID_IS_EMPTY);
        }

        List<CustomPermission> customPermissions = (List<CustomPermission>) new CustomPermissionSelector()
            .selectCustomPermissionsByDeveloperName(new List<Object> {CUSTOM_PERMISSION_NAME})
            .executeQuery();

        if (customPermissions.isEmpty()) {
            return false;
        }

        List<PermissionSetAssignment> psa = (List<PermissionSetAssignment>) new PermissionSetAssignmentSelector()
            .selectPSABasedOnAssignee(new List<Object> {userId})
            .executeQuery();

        if (psa.isEmpty()) {
            return false;
        }

        Set<Id> permissionSetIds = new Set<Id>();
        for (PermissionSetAssignment permissionSetAssignment : psa) {
            permissionSetIds.add(permissionSetAssignment.PermissionSetId);
        }

        List<SetupEntityAccess> userSetupEntities = (List<SetupEntityAccess>) new SetupEntityAccessSelector()
            .selectSetupEntityAccessByParentId(new List<Object> {customPermissions.get(0).Id, permissionSetIds})
            .executeQuery();

        return userSetupEntities.size() > 0;
    }

    public static User getUserInfoByUidAndContactEmail(String uid, String email) {
        if (String.isBlank(uid)) {
            AquivaHelper.throwAquivaException(ERROR_USER_ID_IS_EMPTY);
        }

        if (String.isBlank(email)) {
            AquivaHelper.throwAquivaException(ERROR_CONTACT_EMAIL_IS_EMPTY);
        }

        List<User> users = (List<User>) new UserSelector().selectUsers()
            .selectFields(USER_FIELDS)
            .setQueryBindings(new List<Object> {uid, email})
            .setCondition('Contact.Account.RC_User_ID__c =:bind0 AND Contact.Email =:bind1 AND isPortalEnabled = TRUE')
            .setLimit(1)
            .executeQuery();

        if (users.isEmpty()) {
            AquivaHelper.throwAquivaException(ERROR_NO_USER_WAS_FOUND);
        }

        return users.get(0);
    }
}