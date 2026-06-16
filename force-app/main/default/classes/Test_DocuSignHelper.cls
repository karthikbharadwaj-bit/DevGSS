@IsTest
private class Test_DocuSignHelper {

    private static final String FAKE_PRIVATE_KEY = 'MIIEowIBAAKCAQEA7FBikJgR5gXkwHOvAhptmhmOTiQL+VWxNSOJrPlvCCubEk5Nm6JQv1YAoIDfASXO3JYXNPjsAlb4J+XnitsRNwNVZTBJT1DvQysBVUHfVDXPRiTzHklK7OWYdu+eRnxYdvHBVAd7eKEjNvmG6kRjUDP4d393REzu9PSJEGJlDO0i2ZIxiOMswCDmux' +
        '5H2d4ahXl1jsTyI8J2sVE6g2nI6nduZuIJK1GsxAWmmjezK4j1vMTx4+2UaF6uuwTwzJ56e7/ECQCJDJENzp6Fm3UhqYY12AqW+AE81bbw6lJ3wIoKRT0ZQGnXuOrYypgRUtnrSgZ2RBtVBa43tWZmpScoXwIDAQABAoIBADpVtZ8gCvsPZWKkrAUG5RtvR5O+jj4kizQk662JfYE00nj4X2wV63zwDAOTDHnKDYCihGQNNqV1Npk' +
        'Sxc+fOGauKfxqqQ4tWoLoMNINCsZM6jfUkzdcvGQyYSqrCBU6SNRD5YeKuU4T6Q9/FXDrJOD9k05cZuKzYyGQ4+zpfSxtO++l3lIzrBVeVreBQMZ+p7WA+2gEvz6cxSOFL0mglAfiPIAHTM/zTXYeLweeeWvZSh7V9Y+MTbUP3INPaLWGQB/qDM3+s5L8Ztj1rtYOnWSUXruqQELXu/Jc4z59IUzym4MvdRurg+5+U2NatiNd5QNP' +
        'A11ry7GEDe1HV1jzvbECgYEA/+ciRd56DJiK75VZOHl3icjd6pOTnPEJD09E/eilrFUyc8hAZhFJV32H6wzOkpOAqkrs7GAaIJwnezxDPmwkYRemH6LlLnNdDFpN/lmcH8DuGqN3GdaXm9WCarztB2CBMiWn5QLSA62+AvnuW9EbkWNufeCkL0Zf5nyHTuKwDR0CgYEA7GdZAgolTLLMXekqG4Bv9ipyUqnrHiQSLiCYRBeehPNav' +
        'yYmo9dpcC9s6M/hDnRanIZRm0fa9vTr8vpoAZvFHDyZzgv7PPMFM3fZyeFUibj3wdTDJtdLE4BdtExXjIJHb8B3KmFYaYRBiOpsOaK4XRwcHw4wBFaGDt31ZQoJHqsCgYAQ0EzuLknyneszBqsQDNsP0ITULtIaE7Q2r0ynKiwIgKiJ9vRUQHqDJxpRFUxVUR+5EKc0eLP+xIPLkxAP/+b8AiPGHFvWi3nnn99UAOtDItgCJA9lQT' +
        'ZA5OxmuvcP7wVOGC9J2r+Vwkqjw2wn2DtpeBEAcEwZVxRh/niddEOA+QKBgFrK7mJcJysn2FmQ/T0GvPlcIAAjhktTKzBQEGrGb3k8RXP4YQq35qTRchCQFi2I/mvzIlBy7mO+eQgep+dGPhO0KpX6AAnOhAbaVui0A9XJFk55OmImeY0J1fMzBsTOHEWNM7cxH9WWl9zPu7T/C7Om4h4DQunHmUEIegDOM+Z1AoGBAL+U92I27aH' +
        'if9PS2ZTwZnG5aMDocA0282vUJHPUQY1KThdwRVoFWiVPJhPJcmEpYdimARSpV5rrrzQBUEGKx6Z3OL2ptzz7WmPgOh839SR7CXcZ8Hqcu6h94pYoSDH4b/iNfniRJuABmbstoTCNK9QciDDeCq8wIes6mocheXtU====';

    private static final String USER_DS_PROFILES_BY_EMAIL_RESPONSE = '{"users": [{"id": "testid","user_name": "Test User","first_name": "Test","last_name": "User","user_status": "active",' +
        '"memberships": [' +
        '{"email": "testemail","account_id": "123456789","status": "active","product_permission_profiles": [{"product_id": "testid","product_name": "ESign","permission_profiles": [{"permission_profile_id": "testid","permission_profile_name": "Account Administrator"}]},{"product_id": "testid","permission_profiles": [{"permission_profile_id": "testid","permission_profile_name": "CLM Admin"}]}]},' +
        '{"email": "testemail","account_id": "987654321","status": "active","product_permission_profiles": [{"product_id": "testid","product_name": "ESign","permission_profiles": [{"permission_profile_id": "testid","permission_profile_name": "Account Administrator"}]},{"product_id": "testid","permission_profiles": [{"permission_profile_id": "testid","permission_profile_name": "CLM Admin"}]}]}]}]}';


    @IsTest
    static void testValidateDocusignRESTSettingsPositive() {
        Map<String, String> restSettings = new Map<String, String>{
            'RequestIntegratorKey' => 'testIntegratorKey',
            'RequestPrivateKey' => 'testRequestPrivateKey'
        };

        try {
            DocuSignHelper.validateDocusignRESTSettings(restSettings);
        } catch (Exception e) {
            System.assert(false, 'An exception should not be thrown, since all parameters are filled in');
        }
    }

    @IsTest
    static void testValidateDocusignRESTSettingsNegative() {
        Map<String, String> restSettings = new Map<String, String>{
            'RequestIntegratorKey' => 'testIntegratorKey',
            'RequestPrivateKey' => ''
        };

        try {
            DocuSignHelper.validateDocusignRESTSettings(restSettings);
            System.assert(false, 'An exception should be thrown, as parameter is empty');
        } catch (Exception e) {
            System.assert(e.getMessage().containsIgnoreCase(DocuSignHelper.EMPTY_METADATA_ERROR_MESSAGE),
                'Should be a different error message');
        }
    }

    @IsTest
    static void testHasClmLicensePositive() {
        DocuSignHelper.docusignRESTSettings = new Map<String, String>{
        'DSAccountID' => '123456789'
        };
        DocuSignHelper.PermissionProfile permissionProfileCLM = new DocuSignHelper.PermissionProfile();
        permissionProfileCLM.permission_profile_name = 'CLM Admin';

        DocuSignHelper.PermissionProfile permissionProfileESign= new DocuSignHelper.PermissionProfile();
        permissionProfileESign.permission_profile_name = 'Account Administrator';

        DocuSignHelper.ProductPermissionProfile productProfileCLM = new DocuSignHelper.ProductPermissionProfile();
        productProfileCLM.permission_profiles = new List<DocuSignHelper.PermissionProfile>{permissionProfileCLM};

        DocuSignHelper.ProductPermissionProfile productProfileESign= new DocuSignHelper.ProductPermissionProfile();
        productProfileESign.permission_profiles = new List<DocuSignHelper.PermissionProfile>{permissionProfileESign};

        DocuSignHelper.UserProductPermissionProfile userProfile = new DocuSignHelper.UserProductPermissionProfile();
        userProfile.account_id = '123456789';
        userProfile.status = 'active';
        userProfile.product_permission_profiles = new List<DocuSignHelper.ProductPermissionProfile>{
            productProfileCLM,
            productProfileESign
        };

        DocuSignHelper.UserDrillDown user= new DocuSignHelper.UserDrillDown();
        user.memberships = new List<DocuSignHelper.UserProductPermissionProfile>{userProfile};

        System.assertEquals(true, DocuSignHelper.hasClmLicense(user), 'should return true since the user has CLM license');

    }

    @IsTest
    static void testHasClmLicenseNegative() {
        DocuSignHelper.docusignRESTSettings = new Map<String, String>{
            'DSAccountID' => '123456789'
        };

        DocuSignHelper.PermissionProfile permissionProfileESign= new DocuSignHelper.PermissionProfile();
        permissionProfileESign.permission_profile_name = 'Account Administrator';

        DocuSignHelper.ProductPermissionProfile productProfileESign= new DocuSignHelper.ProductPermissionProfile();
        productProfileESign.permission_profiles = new List<DocuSignHelper.PermissionProfile>{permissionProfileESign};

        DocuSignHelper.UserProductPermissionProfile userProfile = new DocuSignHelper.UserProductPermissionProfile();
        userProfile.account_id = '123456789';
        userProfile.status = 'active';
        userProfile.product_permission_profiles = new List<DocuSignHelper.ProductPermissionProfile>{
            productProfileESign
        };

        DocuSignHelper.UserDrillDown user= new DocuSignHelper.UserDrillDown();
        user.memberships = new List<DocuSignHelper.UserProductPermissionProfile>{userProfile};

        System.assertEquals(false, DocuSignHelper.hasClmLicense(user), 'should return false since the user has no CLM license');
    }

    @IsTest
    static void testHasClmLicenseNegativeNull() {
        System.assertEquals(false, DocuSignHelper.hasClmLicense(null), 'should return false since the user is null');
    }

    @IsTest
    static void testGetClmLicenseAvailabilityPositive() {
        Test.setMock(HttpCalloutMock.class, new DocusignApiMockPositive());

        // set metadata
        DocusignHelper.docusignRESTSettings = new Map<String, String>{
            'AdminRequestIntegratorKey' => 'testIntegratorKey',
            'AdminRequestPrivateKey' => FAKE_PRIVATE_KEY,
            'RequestAuthDomain' => 'testAuthDomain',
            'DSOrganizationID' => 'testOrganizationID',
            'DSAccountID' => '123456789',
            'AdminDataCenter' => 'testDataCenter',
            'AdminApiVersion' => 'testApiVersion',
            'AdminDSUserName' => 'testUserName'
        };

        Response response = DocuSignHelper.getClmLicenseAvailability();
        Boolean hasClmLicense = (Boolean) response.getData('hasClmLicense');
        String apiErrors = (String) response.getData('errors');

        System.assertEquals(true, hasClmLicense, 'Parameter "hasClmLicense" should be true since the user has CLM license');
        System.assertEquals(true, String.isBlank(apiErrors), 'Parameter "errors" should be blank, since the user has CLM license');


    }

    @IsTest
    static void testGetClmLicenseAvailabilityNegative() {
        Test.setMock(HttpCalloutMock.class, new DocusignApiMockNegative());

        // set metadata
        DocusignHelper.docusignRESTSettings = new Map<String, String>{
            'AdminRequestIntegratorKey' => 'testIntegratorKey',
            'AdminRequestPrivateKey' => FAKE_PRIVATE_KEY,
            'RequestAuthDomain' => 'testAuthDomain',
            'DSOrganizationID' => 'testOrganizationID',
            'DSAccountID' => '123456789',
            'AdminDataCenter' => 'testDataCenter',
            'AdminApiVersion' => 'testApiVersion',
            'AdminDSUserName' => 'testUserName'
        };

        Response response = DocuSignHelper.getClmLicenseAvailability();
        Boolean hasClmLicense = (Boolean) response.getData('hasClmLicense');
        String apiErrors = (String) response.getData('errors');

        System.assertEquals(false, hasClmLicense, 'Parameter "hasClmLicense" should be false since Docusign Admin APi httpResponse status code not equal to 200 OK');
        System.assertEquals(true, String.isNotBlank(apiErrors), 'Parameter "errors" should not be blank since Docusign Admin APi httpResponse status code not equal to 200 OK');

    }

    public class DocusignApiMockPositive implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();

            String endpoint = req.getEndpoint();

            if (endpoint.endsWith('/oauth/token')) {
                res.setBody('{"alg":"RS256","Expires_In":300}');
                res.setStatus('OK');
                res.setStatusCode(200);
            } else if (endpoint.endsWith('/users/dsprofile?email=' + UserInfo.getUserEmail())) {
                res.setBody(USER_DS_PROFILES_BY_EMAIL_RESPONSE);
                res.setStatus('OK');
                res.setStatusCode(200);
            }

            return res;
        }
    }

    public class DocusignApiMockNegative implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();

            String endpoint = req.getEndpoint();

            if (endpoint.endsWith('/oauth/token')) {
                res.setBody('{"alg":"RS256","Expires_In":300}');
                res.setStatus('OK');
                res.setStatusCode(200);
            } else if (endpoint.endsWith('/users/dsprofile?email=' + UserInfo.getUserEmail())) {
                res.setBody('');
                res.setStatus('Unauthorized');
                res.setStatusCode(401);
            }

            return res;
        }
    }
}