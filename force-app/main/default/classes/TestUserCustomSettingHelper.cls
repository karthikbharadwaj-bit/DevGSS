@isTest
private class TestUserCustomSettingHelper {
    @isTest
    static void userCustomSetting(){
        Boolean boolResult;
        String strNameOrIdOrEmail;
        Set<String> strSetNameOrId = new Set<String>();
        Map<string,RCSF_Sync__c> mapOfRCSF ;
        Map<id, User> mapUser = new Map<id, User>();
        Map<string,RCPARTNER_Sync__c> mapOfRCPartner ;
        Map<string,Specific_User__c> mapOfSpecificUser ;
        Map<String,India_Team__c> mapIndiaTeam;
        Map<String,RCSF_Sync__c> mapRCUser = new Map<String,RCSF_Sync__c>();
        Map<String,RCPARTNER_Sync__c> mapRCPARTNER = new Map<String,RCPARTNER_Sync__c>();
        Map<String,Specific_User__c> mapRCUserSpecificUser = new Map<String,Specific_User__c>();

        UserCustomSettingHelper objUserCustomSettingHelper = new UserCustomSettingHelper();

        RCSF_Sync__c objRCSFSync = new RCSF_Sync__c();
        objRCSFSync.First_Name__c = 'RCSF';
        objRCSFSync.Last_Name__c = 'Sync';
        objRCSFSync.Email__c = 'rcsfsync@ringcentral.com';
        objRCSFSync.Name ='RCSF Sync';
        insert objRCSFSync;

        System.assertEquals(false, UserCustomSettingHelper.userRCSFName('RCSF Sync'));
        objRCSFSync.Username__c = 'RCSF Sync';
        update objRCSFSync;
        System.assertEquals(true, UserCustomSettingHelper.userRCSFName('RCSF Sync'));

        RCPARTNER_Sync__c objRCPARTNERSync = new RCPARTNER_Sync__c();
        objRCPARTNERSync.First_Name__c = 'RCSF';
        objRCPARTNERSync.Last_Name__c = 'Sync';
        objRCPARTNERSync.Active__c = true;
        objRCPARTNERSync.Email__c = 'rcsfsync@ringcentral.com';
        objRCPARTNERSync.Name = 'RCPARTNER Sync';
        insert objRCPARTNERSync;

        System.assertEquals(false, UserCustomSettingHelper.userRCSFName('RCPARTNER Sync'));
        objRCPARTNERSync.Username__c = 'RCPARTNER Sync';
        update objRCPARTNERSync;
        System.assertEquals(true, UserCustomSettingHelper.userRCSFName('RCPARTNER Sync'));

        Specific_User__c objSpecificUser = new Specific_User__c();
        objSpecificUser.Name = 'Sunil Madan';
        insert objSpecificUser;

        System.assertEquals(true, UserCustomSettingHelper.userRCSFName('Sunil Madan'));

        India_Team__c objIndiaTeam = new India_Team__c();
        objIndiaTeam.Name = 'India Team';
        insert objIndiaTeam;

        Profile salesAgentProfile = [SELECT Id FROM Profile WHERE Name = 'Sales Agent SDR w Insidesales' LIMIT 1];
        User testUser = new User(alias = 'RCSFSync',FirstName='RCSF',
            email='rcsfsync@ringcentral.com',emailencodingkey='UTF-8', lastname='Sync',
            ProfileId=salesAgentProfile.Id, languagelocalekey='en_US',localesidkey='en_US',
            country='United States', timezonesidkey='America/Los_Angeles',
            username=UserHelper.getUniqueUserName(), IsActive=true);

        insert testUser;
        mapUser.put(testUser.id,testUser);

        System.assertEquals(false, UserCustomSettingHelper.userRCSFName('India Team'));
        objIndiaTeam.Username__c = 'India Team';
        update objIndiaTeam;
        System.assertEquals(true, UserCustomSettingHelper.userRCSFName('India Team'));
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void userCustomSettingId(){
        Set<String> strSetNameOrId = new Set<String>();
        Map<String,RCSF_Sync__c> mapRCUser = new Map<String,RCSF_Sync__c>();
        Map<String,RCPARTNER_Sync__c> mapRCPARTNER = new Map<String,RCPARTNER_Sync__c>();
        Map<String,Specific_User__c> mapRCUserSpecificUser = new Map<String,Specific_User__c>();

        String strNameOrIdOrEmail = 'RCSF Sync';
        RCSF_Sync__c objRCSFSync = new RCSF_Sync__c();
        objRCSFSync.First_Name__c = 'RCSF';
        objRCSFSync.Last_Name__c = 'Sync';
        objRCSFSync.Email__c = 'rcsfsync@ringcentral.com';
        objRCSFSync.Name ='RCSF Sync';
        insert objRCSFSync;
        UserCustomSettingHelper.getRCSFSync(strNameOrIdOrEmail);

        strNameOrIdOrEmail = null;
        strNameOrIdOrEmail = 'RCPARTNER Sync';
        RCPARTNER_Sync__c objRCPARTNERSync = new RCPARTNER_Sync__c();
        objRCPARTNERSync.First_Name__c = 'RCSF';
        objRCPARTNERSync.Last_Name__c = 'Sync';
        objRCPARTNERSync.Active__c = true;
        objRCPARTNERSync.Email__c = 'rcsfsync@ringcentral.com';
        objRCPARTNERSync.Name = 'RCPARTNER Sync';
        insert objRCPARTNERSync;
        UserCustomSettingHelper.getRCSFSync(strNameOrIdOrEmail);

        strNameOrIdOrEmail = null;
        strNameOrIdOrEmail = 'Sunil Madan';
        Specific_User__c objSpecificUser = new Specific_User__c();
        objSpecificUser.Name = 'Sunil Madan';
        insert objSpecificUser;
        UserCustomSettingHelper.getRCSFSync(strNameOrIdOrEmail);

        strNameOrIdOrEmail = null;
        strNameOrIdOrEmail = 'India Team';
        India_Team__c objIndiaTeam = new India_Team__c();
        objIndiaTeam.Name = 'India Team';
        insert objIndiaTeam;
        UserCustomSettingHelper.getRCSFSync(strNameOrIdOrEmail);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void userCustomEmail(){
        Set<String> strSetNameOrId = new Set<String>();
        Map<String,RCSF_Sync__c> mapRCUser = new Map<String,RCSF_Sync__c>();
        Map<String,RCPARTNER_Sync__c> mapRCPARTNER = new Map<String,RCPARTNER_Sync__c>();
        Map<String,Specific_User__c> mapRCUserSpecificUser = new Map<String,Specific_User__c>();

        String strNameOrIdOrEmail = 'rcsfsync@ringcentral.com';
        RCSF_Sync__c objRCSFSync = new RCSF_Sync__c();
        objRCSFSync.First_Name__c = 'RCSF';
        objRCSFSync.Last_Name__c = 'Sync';
        objRCSFSync.Email__c = 'rcsfsync@ringcentral.com';
        objRCSFSync.Name ='RCSF Sync';
        insert objRCSFSync;
        UserCustomSettingHelper.getRCSFSync(strNameOrIdOrEmail);

        strNameOrIdOrEmail = null;
        strNameOrIdOrEmail = 'bizserv.crm@ringcentral.com';
        RCPARTNER_Sync__c objRCPARTNERSync = new RCPARTNER_Sync__c();
        objRCPARTNERSync.First_Name__c = 'RCSF';
        objRCPARTNERSync.Last_Name__c = 'Sync';
        objRCPARTNERSync.Active__c = true;
        objRCPARTNERSync.Email__c = 'bizserv.crm@ringcentral.com';
        objRCPARTNERSync.Name = 'RCPARTNER Sync';
        insert objRCPARTNERSync;
        UserCustomSettingHelper.getRCSFSync(strNameOrIdOrEmail);

        strNameOrIdOrEmail = null;
        strNameOrIdOrEmail = 'sunilm@ringcentral.com';
        Specific_User__c objSpecificUser = new Specific_User__c();
        objSpecificUser.Email__c = 'sunilm@ringcentral.com';
        objSpecificUser.Name = 'Sunil Madan';
        insert objSpecificUser;
        UserCustomSettingHelper.getRCSFSync(strNameOrIdOrEmail);

        strNameOrIdOrEmail = null;
        strNameOrIdOrEmail = 'rcindiateam@simplion.com';
        India_Team__c objIndiaTeam = new India_Team__c();
        objIndiaTeam.Email__c = 'rcindiateam@simplion.com';
        objIndiaTeam.Name = 'India Team';
        insert objIndiaTeam;
        UserCustomSettingHelper.getRCSFSync(strNameOrIdOrEmail);
    }

    @IsTest
    static void testGetELALicenses() {
        List<String> emptyList = UserCustomSettingHelper.getELALicenses();
        new SObjectBuilder(ELA_Licenses__c.SObjectType)
            .quantity(3)
            .setFields(new Map<SObjectField, Object> {
                ELA_Licenses__c.Name => ValueProviderBuilder.provideList(
                    new List<String>{
                        'Example 1',
                        'Example 2',
                        'Example 3'
                    }),
                ELA_Licenses__c.TargetLicenses__c => ValueProviderBuilder.provideList(
                    new List<String>{
                        'a',
                        'a;b',
                        'a , b , c'
                    })
            })
            .create();
        Test.startTest();
        List<String> resultList = UserCustomSettingHelper.getELALicenses();
        Test.stopTest();
        System.assertEquals(0, emptyList.size());
        System.assertEquals(6, resultList.size());
        System.assertEquals(new List<String>{'a', 'a', 'b', 'a', 'b', 'c' }, resultList);
    }

}