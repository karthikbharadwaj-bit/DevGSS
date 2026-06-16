@IsTest
private class Test_BatchObjectMonitoringForCustSett {

    @TestSetup
    private static void setup() {
        // 1 set ObjectMonitoringSettings__c
        new SObjectBuilder(ObjectMonitoringSettings__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                ObjectMonitoringSettings__c.Name => ValueProviderBuilder.provideList(new List<String>{'1','2'}),
                ObjectMonitoringSettings__c.ObjectName__c => ValueProviderBuilder.provideList(new List<String>{'NGBS_LBO_Settings__c', 'NGBS_LBO_Settings__c'}),
                ObjectMonitoringSettings__c.ObjectFields__c => ValueProviderBuilder.provideList(
                    new List<String>{'LBOAutoOnThreshold__c','CategoriesForSaveAreaCodesAssignment__c;LBOAvailableProducts__c'}
                )
            })
            .quantity(2)
            .create()
            .getRecords();

        // 2 set OrgDefaults for NGBS_LBO_Settings__c
        new SObjectBuilder(NGBS_LBO_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                NGBS_LBO_Settings__c.LBOAvailableBrands__c => 'RingCentral',
                NGBS_LBO_Settings__c.ExcludeAdminDLByPackageId__c => '5',
                NGBS_LBO_Settings__c.LBOAvailableProducts__c => 'Office;RC Office',
                NGBS_LBO_Settings__c.CategoriesLBODealDeskProvision__c => 'DL-UNL;DL-HDSK;DL-BAS;ALN;ATN;ITN;ILN;IVN;IBO;IBO-BAS;DL-UNL-CC',
                NGBS_LBO_Settings__c.CategoriesForSaveAreaCodesAssignment__c => ';',
                NGBS_LBO_Settings__c.LBOAutoOnThreshold__c => 500
            })
            .create()
            .getRecord();

        // 3 set existing monitoring objets:
        Id objSettingId = NGBS_LBO_Settings__c.getOrgDefaults().Id;
        // it will be saved after batch
        ObjectMonitoringHelper.createObjectMonitoring(objSettingId, 'NGBS_LBO_Settings__c', 'LBOAutoOnThreshold__c', String.valueOf(500), '', String.valueOf(System.UserInfo.getUserId()), '');
        // it will be deleted after batch, because lifetime is off
        ObjectMonitoring__c om1 = ObjectMonitoringHelper.createMonitoringObject(ObjectMonitoringHelper.createObjectMonitoringMap(
            objSettingId,
            'NGBS_LBO_Settings__c',
            'CategoriesForSaveAreaCodesAssignment__c',
            String.valueOf('DL-UNL'),
            '',
            String.valueOf(System.UserInfo.getUserId()),
            '',
            ''
        ));
        insert om1;
        Datetime yearAgo = Datetime.now().addYears(-1);
        Test.setCreatedDate(om1.Id, yearAgo);
    }

    @IsTest
    private static void testRunBatchObjectMonitoringForCustomSetting() {

        NGBS_LBO_Settings__c setting = NGBS_LBO_Settings__c.getOrgDefaults();
        setting.LBOAutoOnThreshold__c = 502;
        update setting;

        Test.startTest();
        Database.executeBatch(new BatchObjectMonitoringForCustomSettings());
        Test.stopTest();

        List<ObjectMonitoring__c> oml1 = [SELECT Id, ObjectName__c, FieldName__c, FieldNewValue__c
            FROM ObjectMonitoring__c WHERE FieldName__c = 'LBOAutoOnThreshold__c'];
        System.assertEquals(2, oml1.size(), 'New record is created, old record isnt deleted');

        List<ObjectMonitoring__c> oml2 = [SELECT Id, ObjectName__c, FieldName__c, FieldNewValue__c
            FROM ObjectMonitoring__c WHERE FieldName__c = 'CategoriesForSaveAreaCodesAssignment__c'];
        System.assertEquals(1, oml2.size(), 'New record is created, old record is deleted');
        System.assertEquals(setting.CategoriesForSaveAreaCodesAssignment__c, oml2.get(0).FieldNewValue__c, 'Check new value field');
    }
}