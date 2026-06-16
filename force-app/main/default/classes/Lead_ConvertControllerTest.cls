@isTest
private class Lead_ConvertControllerTest {

    @testSetup
    static void setup() {
        Profile currentUserProfile = (Profile) new ProfileSelector()
            .selectProfileById(new List<Object>{UserInfo.getProfileId()})
            .executeQuery()
            .get(0);

        List<PackageBusinessIdentityMapping__c> csMap = (List<PackageBusinessIdentityMapping__c>) new SObjectBuilder(PackageBusinessIdentityMapping__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PackageBusinessIdentityMapping__c.Name => ValueProviderBuilder.provideUniqueString('testMapping'),
                PackageBusinessIdentityMapping__c.Active__c => ValueProviderBuilder.provideList(
                new List<Boolean>{
                        true,
                        true,
                        false
                    }
                ),
                PackageBusinessIdentityMapping__c.Profile__c => ValueProviderBuilder.provideList(
                new List<String>{
                        currentUserProfile.Name,
                        'Other Test Profile,Other Test Profile 2',
                        currentUserProfile.Name
                    }
                ),
                PackageBusinessIdentityMapping__c.BiName__c => ValueProviderBuilder.provideList(
                new List<String>{
                        'RingCentral Inc.',
                        'Unify Office France',
                        'Rainbow Office France'
                    }
                ),
                PackageBusinessIdentityMapping__c.BiId__c => ValueProviderBuilder.provideList(
                new List<String>{
                        '4',
                        '24',
                        '34'
                    }
                ),
                PackageBusinessIdentityMapping__c.Currency__c => ValueProviderBuilder.provideList(
                new List<String>{
                        'USD',
                        'EUR',
                        'EUR'
                    }
                ),
                PackageBusinessIdentityMapping__c.DefaultBrand__c => ValueProviderBuilder.provideList(
                new List<String>{
                        'RingCentral',
                        'Unify Office',
                        'Rainbow Office'
                    }
                )
            })
            .quantity(2)
            .create()
            .getRecords();
    }

    @IsTest
    static void testIsUserProfileWithinPackageBIMappingMethod() {
        System.assertEquals(
            Lead_ConvertController.isUserProfileWithinPackageBIMapping('RingCentral'),
            true,
            'The user must have access to the package business identity for RingCentral brand'
        );

        System.assertEquals(
            Lead_ConvertController.isUserProfileWithinPackageBIMapping('Unify Office'),
            false,
            'The user must not have access to the package business identity for Unify Office brand'
        );

        System.assertEquals(
            Lead_ConvertController.isUserProfileWithinPackageBIMapping('Rainbow Office'),
            false,
            'The user must not have access to the package business identity for Rainbow Office brand'
        );

        System.assertEquals(
            Lead_ConvertController.isUserProfileWithinPackageBIMapping(null),
            true,
            'The user must have access when Brand is absent on Lead but have the profile in Custom Setting'
        );
    }

    @IsTest
    static void testValidateLeadConvertAccessWhenSelectPackagesByBusinessIdentityEnabled() {
        Lead lead = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Lead.Lead_Brand_Name__c => 'Unify Office'
                }
            )
            .create()
            .getRecord();

        new SObjectBuilder(Feature_Toggle__c.sObjectType)
            .setField(Feature_Toggle__c.SelectPackagesByBusinessIdentity__c, true)
            .create()
            .getRecord();

        System.assertEquals(
            Lead_ConvertController.validateLeadConvertAccess(lead.Id),
            false,
            'The user must not have access to the package business identity for RingCentral brand when FT is enabled'
        );
    }

    @IsTest
    static void testValidateLeadConvertAccessWhenSelectPackagesByBusinessIdentityDisabled() {
        Lead lead = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Lead.Lead_Brand_Name__c => 'Unify Office'
                }
            )
            .create()
            .getRecord();

        new SObjectBuilder(Feature_Toggle__c.sObjectType)
            .setField(Feature_Toggle__c.SelectPackagesByBusinessIdentity__c, false)
            .create()
            .getRecord();

        System.assertEquals(
            Lead_ConvertController.validateLeadConvertAccess(lead.Id),
            true,
            'The user must always have access to the package business identity for RingCentral brand when FT is disabled'
        );
    }
}