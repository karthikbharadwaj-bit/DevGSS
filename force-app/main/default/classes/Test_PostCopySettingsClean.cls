@isTest
private class Test_PostCopySettingsClean {
    @testSetup
    private static void createTestData() {

        PostCopyTasks__c task = new PostCopyTasks__c(
            Name = 'Clean RingCentral Various Settings',
            DeveloperName__c = 'PostCopySettingsClean',
            Active__c = true,
            OrderNumber__c = 1
        );
        insert task;

        EndpointsSettings__c endpointSettings = new EndpointsSettings__c(
            UQTServerEndpoint__c = 'Uqt_endpoint__c'
        );
        insert endpointSettings;

        RingCentralVariousSettings__c rcSettings = new RingCentralVariousSettings__c(
            Glip_Email__c = 'fake@email.com'
        );
        insert rcSettings;

        NGBS_Settings__c ngbsSettings = new NGBS_Settings__c(
            HerokuSecretKey__c = 'secret'
        );
        insert ngbsSettings;

        List<PostCopyCustomSettingsManagement__c> settings = new List<PostCopyCustomSettingsManagement__c>();

        PostCopyCustomSettingsManagement__c hierarchySettingHeroku = new PostCopyCustomSettingsManagement__c(
            Name = 'Hierarchy Setting Heroku',
            Custom_Setting_API_Name__c = 'EndpointsSettings__c',
            Field_Name__c = 'UQTServerEndpoint__c'
        );
        settings.add(hierarchySettingHeroku);

        PostCopyCustomSettingsManagement__c hierarchySettingGlipEmail = new PostCopyCustomSettingsManagement__c(
            Name = 'Hierarchy Setting Glip Email',
            Custom_Setting_API_Name__c = 'RingCentralVariousSettings__c',
            Field_Name__c = 'Glip_Email__c'
        );
        settings.add(hierarchySettingGlipEmail);

        PostCopyCustomSettingsManagement__c listSetting = new PostCopyCustomSettingsManagement__c(
            Name = 'List Setting',
            Custom_Setting_API_Name__c = 'BrandID__c'
        );
        settings.add(listSetting);

        PostCopyCustomSettingsManagement__c clearNgbsSetting = new PostCopyCustomSettingsManagement__c(
            Name = 'Clear Secret Key',
            Custom_Setting_API_Name__c = 'NGBS_Settings__c',
            Field_Name__c = 'HerokuSecretKey__c'
        );
        settings.add(clearNgbsSetting);

        insert settings;
    }

    @isTest
    private static void testSettingsClean() {
        Test.startTest();
            Test.testSandboxPostCopyScript(
                new PostCopyManager(),
                UserInfo.getOrganizationId(),
                UserInfo.getOrganizationId(),
                UserInfo.getOrganizationName()
            );
        Test.stopTest();

        RingCentralVariousSettings__c rcVariousSettings = RingCentralVariousSettings__c.getInstance();
        EndpointsSettings__c endpointsSettings = EndpointsSettings__c.getInstance();
        Map<String, BrandID__c> brands = BrandID__c.getAll();
        NGBS_Settings__c nbgsSettings = NGBS_Settings__c.getInstance();

        System.assert(String.isEmpty(endpointsSettings.UQTServerEndpoint__c));
        System.assert(String.isEmpty(rcVariousSettings.Glip_Email__c));
        System.assertEquals(0, brands.keySet().size());
        System.assert(
            String.isEmpty(nbgsSettings.HerokuSecretKey__c),
            'NGBS_Settings__c.HerokuSecretKey__c should be empty'
        );
    }
}