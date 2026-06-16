@IsTest
public class GCPFeatureToggleTest {

    @TestSetup
    static void setupData() {
        GCP_Feature_Toggle__c setting = new GCP_Feature_Toggle__c(
            Enable_Switch__c = true
        );
        insert setting;
    }

    @IsTest
    static void testFeatureEnabledTrue() {
        GCP_Feature_Toggle__c setting = [SELECT Id, Enable_Switch__c FROM GCP_Feature_Toggle__c LIMIT 1];
        setting.Enable_Switch__c = true;
        update setting;

        Test.startTest();
        Boolean result = GCPFeatureToggle.isFeatureEnabled();
        Test.stopTest();

        System.assertEquals(true, result, 'Feature toggle should return TRUE when enabled.');
    }

    @IsTest
    static void testFeatureEnabledFalse() {
        GCP_Feature_Toggle__c setting = [SELECT Id, Enable_Switch__c FROM GCP_Feature_Toggle__c LIMIT 1];
        setting.Enable_Switch__c = false;
        update setting;

        Test.startTest();
        Boolean result = GCPFeatureToggle.isFeatureEnabled();
        Test.stopTest();

        System.assertEquals(false, result, 'Feature toggle should return FALSE when disabled.');
    }


}