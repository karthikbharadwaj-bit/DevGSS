/**
 * Controls Access to various feature areas in RingCentral
 * e.g for ProServ Quotes
 *
 * Usage
 *      CustomPermissionHelper customPermissions = new CustomPermissionHelper();
 *      customPermissions.hasPermission(CustomPermissionHelper.permissionName);
 */
public class CustomPermissionHelper {

    // Contains Permission Developer Names
    private static Set<String> PERMISSION_SET;

    // User Id to get permissions
    private static Id USER_ID;

    /*
     * Available Custom Permissions
     * ---------------------------- */

    // Professional Services
    public static final String PERMISSION_SEEPROSERVQUOTE = 'SeeProServQuote';
    public static final String PERMISSION_EDITPROSERVQUOTE = 'EditProServQuote';
    public static final String PERMISSION_ENGAGEPROSERV = 'EngageProServ';

    // CC Professional Services
    public static final String PERMISSION_SEECCPROSERVQUOTE = 'SeeCCProServQuote';
    public static final String PERMISSION_EDITCCPROSERVQUOTE = 'EditCCProServQuote';
    public static final String PERMISSION_ENGAGECCPROSERV = 'EngageCCProServ';

    // (CC) ProServ
    public static final String PERMISSION_EDIT_SIGNED_SOW = 'EditSignedSOW';

    // Sales Quote
    public static final String PERMISSION_EDITSALESQUOTE = 'EditSalesQuote';

    // Phase Management
    public static final String PERMISSION_COMPLETE_PHASES = 'CompletePhases';

    // Cases
    public static final String PERMISSION_ALTERNATIVE_CASE_CREATION = 'AlternativeCaseCreation';
    public static final String PERMISSION_ALTERNATIVE_CASE_ROUTING = 'AlternativeCaseRouting';
    public static final String PERMISSION_SUPPORT_AGENT_T1 = 'Support_Agent_T1_Permission';
    public static final String PERMISSION_SET_NAME_SUPPORT_AGENT_T1 = 'Support_Agent_T1';

    //Billing
    public static final String PERMISSION_START_BILLING = 'Allowed_to_Start_Billing_for_Recurring_ProServ';
    public static final String PERMISSION_CAN_TRIGGER_NGBS_REPRICE = 'Can_Trigger_NGBS_Reprice';
    public static final String PERMISSION_CAN_SYNC_WITH_NGBS = 'Can_Sync_With_NGBS';
    public static final String PERMISSION_CAN_SIGN_UP_RCCC = 'Can_Sign_Up_RCCC';
    public static final String PERMISSION_CAN_SIGN_UP_RINGCX= 'Can_Sign_Up_RingCX';
    public static final String PERMISSION_CAN_SYNC_RCCC = 'Can_Sync_RCCC';
    public static final String PERMISSION_CAN_SYNC_RINGCX = 'Can_Sync_RingCX';
    public static final String PERMISSION_CAN_TRIGGER_NGBS_RESYNC = 'Can_remediate_NGBS_contracts';

    //Refund Management
    public static final String PERMISSION_REFUND_MANAGEMENT = 'RefundManagement';

    //Edit Locations
    public static final String PERMISSION_EDIT_LOCATIONS = 'EditLocations';

    // Create Primary and Signatory contact roles
    public static final String PERMISSION_EDIT_PRIMARY_SIGNATORY_CONT_ROLES = 'EditPrimarySignatoryContactRoles';

    // Change primary signatory contact role
    public static final String PERMISSION_CHANGE_PRIMARY_SIGNATORY_CONT_ROLE = 'ContactDetailsChange';

    // Void DocuSign Envelopes in QW
    public static final String VOID_DOCUSIGN_ENVELOPE = 'VoidDocuSignEnvelope';

    // Allow user to change stage of closed won or downgraded opportunities
    public static final String PERMISSION_RE_OPEN_OPPORTUNITIES = 'Allow_re_opening_optys';

    // Allows tax team to approve or reject tax exemptions
    public static final String PERMISSION_PROCESS_TAX_EXEMPTIONS = 'ProcessTaxExemptions';

    // Engage account link
    public static final String PERMISSION_EXPANDED_ENGAGE_BINDING = 'Expanded_Engage_Binding';

    // Allows to see and select Engage Legacy Packages
    public static final String PERMISSION_PROCESS_ENGAGE_LEGACY = 'ProcessEngageLegacy';

    // Allows to see and select Engage Legacy Packages
    public static final String PERMISSION_PROCESS_ENGAGE_DIGITAL_STANDALONE = 'ProcessEngageDigitalStandalone';

    // Allows to use DoscuSign CLM flow
    public static final String PERMISSION_ENABLE_DOCUSIGN_CLM_ACCESS = 'EnableDocusignCLMAccess';

    // Allows to use DoscuSign CLM flow for EB Accounts
    public static final String PERMISSION_ENABLE_EB_DOCUSIGN_CLM_ACCESS = 'EnableEBDocuSignCLMAccess';

    // Allows to run post copy framework on sandboxes
    public static final String PERMISSION_RUN_POST_COPY_FRAMEWORK = 'RunPostCopyFramework';

    // Allows to use FedRamp brand
    public static final String PERMISSION_PROCESS_FEDRAMP_ACCOUNTS = 'Process_FedRamp_Accounts';

    // Makes visible Contact Center tab on Quoting Wizard for new business Accounts
    public static final String USE_CONTACT_CENTER_LEGACY_ON_NEW_BUSINESS = 'UseContactCenterLegacyOnNewBusiness';

    // Allows to use Target Price Calculation And DQ Based GOA
    public static final String PERMISSION_TARGET_PRICE_AND_DQ_GOA = 'AllowTargetPriceCalculationAndDQBasedGOA';

    //Allows to update estimated fields on opportunity
    public static final String PERMISSION_ESTIMATED_PIPELINE_REPORTING = 'Estimated Pipeline Reporting';

    // Allows to use MultiProduct
    public static final String PERMISSION_ENABLE_MULTI_PRODUCT = 'EnableMultiProduct';

    // Enable UQT flow for PRM
    public static final String PERMISSION_IGNITE_UQT_FLOW = 'IgniteUQTFlow';

    // Allows to skip shipping validation on Process Order
    public static final String PERMISSION_SKIP_SHIPPING_VALIDATION = 'AllowProcessOrderWithoutShipping';
    
    // Allows to change DOS Case Status
    public static final String PERMISSION_SET_LABEL_ALLOW_DOS_CASE_STATUS_CHANGE = 'Allow DOS Case status change';

    /**
     * Constructor method
     * By default new instance created for current user
     */
    public CustomPermissionHelper(){
        this(UserInfo.getUserId());
    }

    /**
     * Constructor method
     * Creates new instance for specified user
     */
    public CustomPermissionHelper(Id providedUserId){
        USER_ID = providedUserId;
    }

    /**
     * Checks if user has custom permission
     *
     * @deprecated use native salesforce custom permission check method instead:
     * @deprecated
     * @deprecated
     * @deprecated
     * @deprecated
     * @deprecated
     * @deprecated
     * @deprecated
     * @deprecated
     * @deprecated
     * @deprecated
     * @deprecated
     * @deprecated
     * @deprecated
     * @deprecated
     * @deprecated
     * @deprecated
     * FeatureManagement.checkPermission(CustomPermissionHelper.PERMISSION_FEATURE_NAME)
     *
     * @param customPermissionName
     *
     * @return true || false
     */
    public Boolean hasPermission(String customPermissionName) {
        if (PERMISSION_SET == null) {
            PERMISSION_SET = preparePermissionSet(USER_ID);
        }
        return PERMISSION_SET.contains(customPermissionName);
    }

    /**
     * Returns Set of permission names
     *
     * @return Set of Custom Permission Developer Names. Permissions from packages will be returned with prefixes
     * NamespacePrefix__CustomPermissionDeveloperName
     */
    public Set<String> getPermissionSet(){
        if (PERMISSION_SET == null) {
            PERMISSION_SET = preparePermissionSet(USER_ID);
        }
        return PERMISSION_SET;
    }

    /**
     * Permission map
     *
     * Handy to use with aura validations
     */
    public Map<String, Boolean> getPermissionMap(){
        Map<String, Boolean> userPermissions = new Map<String, Boolean>();
        for (String permission : getPermissionSet()){
            userPermissions.put(permission, true);
        }
        return userPermissions;
    }

    /**
     * Creates set of Custom Permission Names available for User
     *
     * @param userId User to get permissions for
     *
     * @return Set of Custom Permission Developer Names. Permissions from packages will be returned with prefixes
     * NamespacePrefix__CustomPermissionDeveloperName
     */
    private Set<String> preparePermissionSet(Id userId){
        List<CustomPermission> customPermissions = [
                SELECT Id, DeveloperName, NamespacePrefix, (
                        SELECT SetupEntityId
                        FROM SetupEntityAccessItems
                        WHERE SetupEntityType = 'CustomPermission'
                        AND ParentId IN (
                                SELECT PermissionSetId
                                FROM PermissionSetAssignment
                                WHERE AssigneeId = :userId
                        )
                )
                FROM CustomPermission
        ];

        Set<String> userPermissions = new Set<String>();

        for (CustomPermission cp : customPermissions){
            if (cp.SetupEntityAccessItems.size() > 0){
                String permissionName = cp.DeveloperName;
                if (String.isNotBlank(cp.NamespacePrefix)){
                    permissionName = cp.NamespacePrefix + '__' + permissionName;
                }
                userPermissions.add(permissionName);
            }
        }

        return userPermissions;
    }

    @AuraEnabled
    public static Boolean currentUserHasProfilePermission(String permissionDevName) {
        String profileId = Userinfo.getProfileId();

        List<SetupEntityAccess> parentsOfPermission = (List<SetupEntityAccess>) new SetupEntityAccessSelector()
            .selectSetupEntityAccessByCustomPermissionName(new List<Object>{permissionDevName})
            .executeQuery();

        List<Id> parentIds = new List<Id>();

        for (SetupEntityAccess p : parentsOfPermission) {
            parentIds.add(p.ParentId);
        }

        List<PermissionSet> permissionSetsForPermission = (List<PermissionSet>) new PermissionSetSelector()
            .selectPermissionSetByIds(new List<Object>{parentIds})
            .executeQuery();

        for (PermissionSet ps : permissionSetsForPermission) {
            if (profileId == ps.ProfileId) {
                return true;
            }
        }

        return false;
    }

    public static Boolean currentUserHasPermissionSet(String permissionSetLabel) {
        Id userId = UserInfo.getUserId();

        List<PermissionSetAssignment> assignments =
            (List<PermissionSetAssignment>) new PermissionSetAssignmentSelector()
            .selectPSABasedOnAssigneeAndLabel(new List<Object>{userId, permissionSetLabel})
            .executeQuery();

        return !assignments.isEmpty();
    }
}