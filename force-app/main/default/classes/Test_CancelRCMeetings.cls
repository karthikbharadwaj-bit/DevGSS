@IsTest
private class Test_CancelRCMeetings {

    @TestSetup
    static void createData() {
        Account acc = new Account();
        acc.Name = 'Test';
        acc.Billing_ID__c = '20001';

        Triggers.switchOff();
        insert acc;
        Triggers.switchOn();
    }

    @isTest
    static void testBehavior() {
        NGBS_Settings__c settings = NGBS_Settings__c.getInstance();
        settings.Login__c = 'salesforce';
        settings.Password__c = 'salesforce';
        settings.BaseEndpoint__c = 'test';
        settings.AccountManagerPath__c = '/test';

        insert settings;

        Account acc = [SELECT Id, Billing_ID__c FROM Account LIMIT 1];

        Map<String, String> params = new Map<String, String>();
        params.put('accountId', acc.Id);
        params.put('billingId', acc.Billing_ID__c);

        TriggerHandler.BY_PASS_QUOTE_ON_CONVERT = true;
        Test.startTest();
        CancelRCMeetings.cancelMeetings(JSON.serialize(params));
        Test.stopTest();
        TriggerHandler.BY_PASS_QUOTE_ON_CONVERT = false;
        
        Quote qt = [SELECT Id, Opportunity.RecordType.Name, (SELECT Id FROM QuoteLineItems) FROM Quote WHERE Opportunity.AccountId = :acc.Id];
        
        System.assertEquals('Cancel Opportunity', qt.Opportunity.RecordType.Name);
        System.assertEquals(3, qt.QuoteLineItems.size());
    }

    @isTest
    static void testNegative() {
        NGBS_Settings__c settings = NGBS_Settings__c.getInstance();
        settings.Login__c = 'salesforce';
        settings.Password__c = 'salesforce';

        insert settings;

        Account acc = [SELECT Id, Billing_ID__c FROM Account LIMIT 1];

        Map<String, String> params = new Map<String, String>();
        params.put('accountId', acc.Id);

        String res = CancelRCMeetings.cancelMeetings(JSON.serialize(params));

        Map<String, String> result = (Map<String, String>) JSON.deserialize(res, Map<String, String>.class);

        System.assertEquals(result.get('status'), 'error');
        System.assertEquals(result.get('message'), 'Account is not subscribed to RC Meetings');

        params.put('billingId', '12345');

        res = CancelRCMeetings.cancelMeetings(JSON.serialize(params));

        result = (Map<String, String>) JSON.deserialize(res, Map<String, String>.class);

        System.assertEquals('error', result.get('status'));
        System.assertEquals('NGBS Settings\' BaseEndpoint not set', result.get('message'));
    }
}