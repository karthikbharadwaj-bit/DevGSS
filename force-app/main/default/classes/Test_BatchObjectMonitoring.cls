/**
 * Created by Makhmud.Shafeev on 8/31/2021.
 */
@IsTest
private class Test_BatchObjectMonitoring {

    @TestSetup
    private static void setup() {
        ObjectMonitoringHelper.createObjectMonitoring((Id) new ValueProvider.DummyIdProvider(OpportunityRenewalSettings__c.sObjectType).getValue() , Quote.class.getName(), 'Enabled_LBO__c', 'true', 'false', String.valueOf(System.UserInfo.getUserId()), 'Add new OM');
        ObjectMonitoringHelper.createObjectMonitoring((Id) new ValueProvider.DummyIdProvider(OpportunityRenewalSettings__c.sObjectType).getValue() , Quote.class.getName(), 'Enabled_LBO__c', 'false', 'true', String.valueOf(System.UserInfo.getUserId()), 'Add new OM', new DmlException().getStackTraceString());
    }

    @IsTest
    private static void testRunBatchObjectMonitoring() {
        String query = 'SELECT Id, ObjectName__c FROM ObjectMonitoring__c WHERE ObjectId__c = \'aG23K000000CbiOSAS\'';
        Test.startTest();
        Database.executeBatch(new BatchObjectMonitoring(query));
        Test.stopTest();

        List<ObjectMonitoring__c> omList = [SELECT Id FROM ObjectMonitoring__c WHERE ObjectId__c = 'aG23K000000CbiOSAS'];
        System.assert(omList.isEmpty());
    }
}