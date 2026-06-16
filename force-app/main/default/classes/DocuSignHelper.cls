public class DocuSignHelper {
    public static final String ENVELOPE_STATUS_SENT = 'Sent';
    public static final String ENVELOPE_STATUS_COMPLETED = 'Completed';

    public static final String CONTRACT_STATUS_ACTIVE = 'Active';
    public static final String CONTRACT_STATUS_INACTIVE = 'Inactive';

    public static final String DOCUSIGN_USER_STATUS_ACTIVE = 'Active';

    public static final String PERMISSION_PROFILE_NAME_CLM_ADMIN = 'CLM Admin';
    public static final String PERMISSION_PROFILE_NAME_CLM_USER = 'CLM User';
    public static final String PERMISSION_PROFILE_NAME_CLM_VIEWER = 'CLM Viewer';
    public static final String PERMISSION_PROFILE_NAME_ADMIN = 'Admin';
    public static final String PERMISSION_PROFILE_NAME_USER = 'User';
    public static final String PERMISSION_PROFILE_NAME_VIEWER = 'Viewer';

    public static final List<String> PERMISSION_PROFILE_NAMES_CLM = new List<String>{
        PERMISSION_PROFILE_NAME_CLM_ADMIN,
        PERMISSION_PROFILE_NAME_CLM_USER,
        PERMISSION_PROFILE_NAME_CLM_VIEWER,
        PERMISSION_PROFILE_NAME_ADMIN,
        PERMISSION_PROFILE_NAME_USER,
        PERMISSION_PROFILE_NAME_VIEWER
    };

    public static final String EMPTY_METADATA_ERROR_MESSAGE = 'Required fields for requesting Docusign data are empty.';
    public static final String CLM_LICENSE_AVAILABILITY_ERROR_MESSAGE = 'Failed to get CLM license availability.';
    public static final String GETTING_DOCUSIGN_DATA_ERROR_MESSAGE = 'An error occurred during getting Docusign data.';


    @TestVisible
    private static Map<String, String> docusignRESTSettings {
        get {
            if (docusignRESTSettings == null) {
                Boolean isProduction = SettingsService.isProduction();
                docusignRESTSettings = new Map<String, String>();

                for (DocuSignRESTSettings__mdt setting : [SELECT Id, DeveloperName, Value__c FROM DocuSignRESTSettings__mdt]) {
                    if (isProduction && setting.DeveloperName.startsWithIgnoreCase('Production_')) {
                        docusignRESTSettings.put(
                            setting.DeveloperName.removeStartIgnoreCase('Production_'),
                            setting.Value__c
                        );
                    } else if (!isProduction && setting.DeveloperName.startsWithIgnoreCase('Sandbox_')) {
                        docusignRESTSettings.put(
                            setting.DeveloperName.removeStartIgnoreCase('Sandbox_'),
                            setting.Value__c
                        );
                    }
                }
            }
            return docusignRESTSettings;
        }
        set;
    }

    public static Response getClmLicenseAvailability() {
        Response response = new Response();
        Boolean hasClmLicense = false;
        try {
            HttpResponse httpResponse = getUserDSProfilesByEmail();

            if (HttpHelper.isSuccess(httpResponse)) {
                String respBodyStr = httpResponse.getBody();
                UserDrillDownResponse userDrillDownResponse = (UserDrillDownResponse) JSON.deserialize(respBodyStr, UserDrillDownResponse.class);

                if (userDrillDownResponse.users != null) {
                    for (UserDrillDown user : userDrillDownResponse.users){
                        hasClmLicense = hasClmLicense(user);
                        if (hasClmLicense) {
                            break;
                        }
                    }
                }
            } else {
                response.setData('errors',GETTING_DOCUSIGN_DATA_ERROR_MESSAGE + ' (' + httpResponse + ')');
            }

            response.setData('hasClmLicense', hasClmLicense);
        } catch (Exception ex) {
            response.setData('errors',CLM_LICENSE_AVAILABILITY_ERROR_MESSAGE + ' (' + ex.getMessage() + ')');
            response.setData('hasClmLicense', hasClmLicense);
        }

        return response;
    }

    private static HttpResponse getUserDSProfilesByEmail() {
        Map<String, String> sendRequestRequiredSettings = new Map<String, String>{
            'RequestIntegratorKey' => docusignRESTSettings.get('AdminRequestIntegratorKey'),
            'RequestPrivateKey' => docusignRESTSettings.get('AdminRequestPrivateKey'),
            'RequestAuthDomain' => docusignRESTSettings.get('RequestAuthDomain'),
            'DSOrganizationID' => docusignRESTSettings.get('DSOrganizationID'),
            'DSAccountID' => docusignRESTSettings.get('DSAccountID'),
            'DataCenter' => docusignRESTSettings.get('AdminDataCenter'),
            'ApiVersion' => docusignRESTSettings.get('AdminApiVersion'),
            'DSUserName' => docusignRESTSettings.get('AdminDSUserName'),
            'Scope' => 'impersonation user_read'
        };

        String endpoint = 'https://' + sendRequestRequiredSettings.get('DataCenter')
            + '/Management/' + sendRequestRequiredSettings.get('ApiVersion')
            + '/organizations/' + sendRequestRequiredSettings.get('DSOrganizationID')
            + '/users/dsprofile?email=' + UserInfo.getUserEmail();
        HttpResponse httpResponse = requestDocusignData(endpoint, HttpHelper.METHOD_GET, sendRequestRequiredSettings, null);

        return httpResponse;
    }

    private static HttpResponse requestDocusignData(String endpoint, String method, Map<String, String> params, String body) {
        validateDocusignRESTSettings(params);

        DSAPIUserAuthenticator auth = new DSAPIUserAuthenticator(
            params.get('DSAccountID'),
            params.get('RequestIntegratorKey'),
            params.get('RequestAuthDomain'),
            params.get('DSUserName'),
            params.get('RequestPrivateKey'),
            params.get('DataCenter'),
            params.get('ApiVersion'),
            params.get('Scope')
        );
        String accessToken = auth.AccessToken();

        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod(method);
        request.setHeader('grant_type', 'Bearer');
        request.setHeader('Authorization', 'Bearer ' + accessToken);
        request.setHeader('Accept', 'application/json');
        request.setHeader('Content-type', 'application/json');
        if (body != null) {
            request.setBody(body);
        }
        Http http = new Http();
        HttpResponse httpResponse = http.send(request);

        return httpResponse;
    }

    public static Boolean hasClmLicense(UserDrillDown user) {
        Boolean hasClmLicense = false;

        if (user?.memberships != null) {
            for (UserProductPermissionProfile userProfile : user.memberships) {
                if (userProfile.product_permission_profiles != null && userProfile.account_id == docusignRESTSettings.get('DSAccountID') && DOCUSIGN_USER_STATUS_ACTIVE.equalsIgnoreCase(userProfile.status)) {

                    for (ProductPermissionProfile productProfile : userProfile.product_permission_profiles) {
                        if (productProfile.permission_profiles != null) {

                            for (PermissionProfile permissionProfile : productProfile.permission_profiles) {
                                if (PERMISSION_PROFILE_NAMES_CLM.contains(permissionProfile.permission_profile_name)) {
                                    hasClmLicense = true;
                                    return hasClmLicense;
                                }
                            }
                        }
                    }
                }
            }
        }

        return hasClmLicense;
    }

    public static void validateDocusignRESTSettings(Map<String, String> settingsToValidate) {
        for (String setting : settingsToValidate.keySet()) {
            if (String.isBlank(settingsToValidate.get(setting))) {
                AquivaHelper.throwAquivaException(EMPTY_METADATA_ERROR_MESSAGE);
                break;
            }
        }
    }

    public class UserDrillDownResponse{
        public List<UserDrillDown> users {get;set;}
    }
    public class UserDrillDown{
        public String id {get;set;}
        public String user_name {get;set;}
        public String first_name {get;set;}
        public String last_name {get;set;}
        public String user_status {get;set;}
        public List<UserProductPermissionProfile> memberships {get;set;}
    }

    public class UserProductPermissionProfile{
        public String email {get;set;}
        public String account_id {get;set;}
        public String status {get;set;}
        public List<ProductPermissionProfile> product_permission_profiles {get;set;}
    }

    public class ProductPermissionProfile{
        public String product_id {get;set;}
        public String product_name {get;set;}
        public List<PermissionProfile> permission_profiles {get;set;}
    }

    public class PermissionProfile{
        public String permission_profile_id {get;set;}
        public String permission_profile_name {get;set;}
    }
}