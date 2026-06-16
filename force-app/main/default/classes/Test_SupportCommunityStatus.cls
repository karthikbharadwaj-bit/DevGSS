@isTest
public class Test_SupportCommunityStatus {
    private static final String USER_LANGUAGE = 'en_US';

    private static final String ADMIN_USER_USERNAME = 'RC_SupportCommunityNewCaseTestUserAdmin@nvx.zn';
    private static final String ADMIN_USER_EMAIL = 'testerinoadmin@rc.com';
    private static final String ADMIN_USER_FIRST_NAME = 'Admeeeno';
    private static final String ADMIN_USER_LAST_NAME = 'McAdmin';
    private static final String ADMIN_USER_EMAIL_ENCODING = 'UTF-8';
    private static final String ADMIN_USER_TIMEZONE = 'GMT';
    private static final String ADMIN_USER_ALIAS = 'steupped';

    private static final String ADMIN_ACCOUNT_POD = 'ADB1';
    private static final String ADMIN_ACCOUNT_CLUSTER = 'E1';
    
    private static final String ADMIN_CONTACT_FIRST_NAME = 'Admin';
    private static final String ADMIN_CONTACT_LAST_NAME = 'McToast';
    private static final String ADMIN_CONTACT_EMAIL = 'admin@tes.to';
    private static final String ADMIN_CONTACT_PHONE = '77777777';
    private static final Decimal ADMIN_CONTACT_PHONE_EXT = 777;

    private static final String ADMIN_USER_PROFILE_NAME = 'RC Admin User';

    private static User adminTestUser {
        get {
            if (adminTestUser == null) {
                adminTestUser = (User) new UserSelector()
                    .selectUserByUsername(new List<Object>{new List<String>{ADMIN_USER_USERNAME}})
                    .selectFields(new List<String>{'ContactId', 'AccountId'})
                    .executeQuery()
                    .get(0);
            }
            return adminTestUser;
        }
        private set;
    }
    @testSetup
    static void setup() {
        Profile adminProfile = (Profile) new ProfileSelector()
            .selectProfileByName(new List<String>{ADMIN_USER_PROFILE_NAME})
            .executeQuery()
            .get(0);

        Account portalAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .setField(Account.inContact_Cluster__c, ADMIN_ACCOUNT_CLUSTER)
            .create()
            .getRecord();

        Package__c testPackage = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Package__c.Account__c => portalAccount.Id,
                Package__c.Service_Type__c => 'Office',
                Package__c.Account_Package_Id__c => '11111111111',
                Package__c.Account_POD__c => ADMIN_ACCOUNT_POD
            })
            .create()
            .getRecord();

        Contact portalContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => ADMIN_CONTACT_FIRST_NAME,
                    Contact.LastName => ADMIN_CONTACT_LAST_NAME,
                    Contact.Email => ADMIN_CONTACT_EMAIL,
                    Contact.Phone => ADMIN_CONTACT_PHONE,
                    Contact.Phone_Ext__c => ADMIN_CONTACT_PHONE_EXT,
                    Contact.AccountId => portalAccount.Id
                }
            )
            .create()
            .getRecord();

        new SObjectBuilder(User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.ContactId => portalContact.Id,
                    User.LastName => ADMIN_USER_LAST_NAME,
                    User.FirstName => ADMIN_USER_FIRST_NAME,
                    User.CommunityNickname => ADMIN_USER_LAST_NAME,
                    User.Email => ADMIN_USER_EMAIL,
                    User.EmailEncodingKey => ADMIN_USER_EMAIL_ENCODING,
                    User.TimeZoneSidKey => ADMIN_USER_TIMEZONE,
                    User.Alias => ADMIN_USER_ALIAS,
                    User.Username => ADMIN_USER_USERNAME,
                    User.LanguageLocaleKey => USER_LANGUAGE,
                    User.ProfileId => adminProfile.Id
                }
            )
            .create();
    }

    @isTest
    static void test_getSystemStatusByPods() {
        new SObjectBuilder(System_Status_IMP_Based__c.SObjectType)
            .quantity(4)
            .setFields(
            new Map<SObjectField, Object>{
                System_Status_IMP_Based__c.IncidentId__c => ValueProviderBuilder.provideList(
                    new List<String>{'0', '1', '2', '3'}),
                System_Status_IMP_Based__c.Level__c => ValueProviderBuilder.provideList(new List<String>{
                        SupportCommunityStatus.ServiceWarning.Information.name(),
                        SupportCommunityStatus.ServiceWarning.Warning.name(),
                        SupportCommunityStatus.ServiceWarning.Error.name(),
                        SupportCommunityStatus.ServiceWarning.Error.name()
                }),
                System_Status_IMP_Based__c.PODs_Affected__c => ValueProviderBuilder.provideList(
                    new List<String>{'POD1,POD2,POD3', 'POD1,POD2,POD3', 'POD1,POD2,POD3','POD3'}),
                System_Status_IMP_Based__c.Services_Affected__c => ValueProviderBuilder.provideList(
                    new List<String>{
                        'inboundCall,outboundCall,inboundFax,glip,outboundFax,spRegistration,registration,',
                        'inboundCall,outboundCall,inboundFax,outboundFax,spRegistration,registration,',
                        'inboundCall,inboundSms,outboundSms,meetings,serviceWeb,contactCenter,platform',
                        'inboundSms,outboundSms,meetings,serviceWeb,contactCenter,platform'
                    })
            }
        ).create();
        System.runAs(adminTestUser) {
            String systemStatusInfoJson = SupportCommunityStatus.getSystemStatus();
            Map<String, SupportCommunityStatus.ServiceInfo> systemStatusInfo = (Map<String, SupportCommunityStatus.ServiceInfo>) JSON.deserialize(
                systemStatusInfoJson,
                Map<String, SupportCommunityStatus.ServiceInfo>.class
            );

            SupportCommunityStatus.ServiceInfo inboundCallServiceInfo = systemStatusInfo.get('inboundCall');
            System.assertEquals(3, inboundCallServiceInfo.incidentList.size(), 'Not all IMP records have been added');
            System.assertEquals(
                'Error',
                inboundCallServiceInfo.serviceWarning,
                'The status of the "inboundCall" service is not as expected'
            );

            SupportCommunityStatus.ServiceInfo inboundSmsServiceInfo = systemStatusInfo.get('inboundSms');
            System.assertEquals(
                'Error',
                inboundSmsServiceInfo.serviceWarning,
                'The status of the "inboundSms" service is not as expected'
            );

            SupportCommunityStatus.ServiceInfo outboundCallServiceInfo = systemStatusInfo.get('outboundCall');
            System.assertEquals(
                'Warning',
                outboundCallServiceInfo.serviceWarning,
                'The status of the "outboundCall" service is not as expected'
            );

            SupportCommunityStatus.ServiceInfo glipServiceInfo = systemStatusInfo.get('glip');
            System.assertEquals(
                'Information',
                glipServiceInfo.serviceWarning,
                'The status of the "glip" service is not as expected'
            );

            SupportCommunityStatus.ServiceInfo devSandboxServiceInfo = systemStatusInfo.get('devSandbox');
            System.assertEquals(
                'Good',
                devSandboxServiceInfo.serviceWarning,
                'The status of the "devSandbox" service is not as expected'
            );
        }
    }
    
    @isTest
    static void test_getSystemStatusByClusters() {
        new SObjectBuilder(System_Status_IMP_Based__c.SObjectType)
            .quantity(2)
            .setFields(
            new Map<SObjectField, Object>{
                System_Status_IMP_Based__c.IncidentId__c => ValueProviderBuilder.provideList(
                    new List<String>{'0', '1'}),
                System_Status_IMP_Based__c.Level__c => ValueProviderBuilder.provideList(new List<String>{
                    SupportCommunityStatus.ServiceWarning.Information.name(),
                    SupportCommunityStatus.ServiceWarning.Warning.name()
                }),
                System_Status_IMP_Based__c.inContact_Cluster__c => ValueProviderBuilder.provideList(
                    new List<String>{'E1', 'E2,E1'}),
                System_Status_IMP_Based__c.Services_Affected__c => ValueProviderBuilder.provideList(
                    new List<String>{
                        'contactCenter',
                        'contactCenter,outboundCall'
                    })
            }
        ).create();
        
        System.runAs(adminTestUser) {
            String systemStatusInfoJson = SupportCommunityStatus.getSystemStatus();
            Map<String, SupportCommunityStatus.ServiceInfo> systemStatusInfo = (Map<String, SupportCommunityStatus.ServiceInfo>) JSON.deserialize(
                systemStatusInfoJson,
                Map<String, SupportCommunityStatus.ServiceInfo>.class
            );

            SupportCommunityStatus.ServiceInfo contactCenterServiceInfo = systemStatusInfo.get('contactCenter');
            System.assertEquals(2, contactCenterServiceInfo.incidentList.size(), 'Not all IMP records have been added');
            System.assertEquals(
                'Warning',
                contactCenterServiceInfo.serviceWarning,
                'The status of the "contactCenter" service is not as expected'
            );
            
            SupportCommunityStatus.ServiceInfo outboundCallServiceInfo = systemStatusInfo.get('outboundCall');
            System.assertEquals(0, outboundCallServiceInfo.incidentList.size(), 'outboundCall should not mapped by clusters');
        }
    }
}