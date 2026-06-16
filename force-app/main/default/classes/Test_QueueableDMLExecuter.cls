@isTest
private with sharing class Test_QueueableDMLExecuter {

    @isTest
    static void testQueableExecuter_forInsert() {

        List<Account> accs = new List<Account>([SELECT Id FROM Account]);
        System.assertEquals(0, accs.size());

        List<SObject> accToInsert = new SObjectBuilder(Account.SObjectType)
            .quantity(10)
            .build()
            .getRecords();
        
        Test.startTest();
            QueueableDMLExecuter.enqueueJob(accToInsert, QueueableDMLExecuter.DMLType.DML_INSERT);
        Test.stopTest();

        accs = new List<Account>([SELECT Id FROM Account]);
        System.assertEquals(10, accs.size());
    }

    @isTest
    static void testQueableExecuter_forUpdate() {
        List<SObject> accsList = new SObjectBuilder(Account.SObjectType)
            .quantity(10)
            .create()
            .getRecords();

        for (Account acc : (List<Account>)accsList) {
            acc.Name = 'WahWahWah';
        }
        
        QueueableDMLExecuter executer = new QueueableDMLExecuter(accsList, QueueableDMLExecuter.DMLType.DML_UPDATE)
            .withScopeLimit(5)
            .bypassTriggers(new List<String>{'BY_PASS_ACCOUNT_ON_UPDATE'});

        Test.startTest();
            executer.execute(null);
        Test.stopTest();

        List<Account> accs = new List<Account>([SELECT Id, Name FROM Account]);
        System.assertEquals(10, accs.size());
        for (Account acc : accs) {
            System.assertEquals('WahWahWah', acc.Name);
        }
    }

    @isTest
    static void testQueableExecuter_forDelete() {
        List<SObject> accsList = new SObjectBuilder(Account.SObjectType)
            .quantity(10)
            .create()
            .getRecords();
        
        List<Account> accs = new List<Account>([SELECT Id, Name FROM Account]);
        System.assertEquals(10, accs.size());

        Test.startTest();
            QueueableDMLExecuter.enqueueJob(
                accsList, 
                QueueableDMLExecuter.DMLType.DML_DELETE
            );
        Test.stopTest();

        accs = new List<Account>([SELECT Id, Name FROM Account]);
        System.assertEquals(0, accs.size());
    }

    @isTest
    static void testTriggerHandler_bypassTrigger() {
        List<String> allTriggersToBypass = new List<String> {
            'BY_PASS_BEFORE', 'BY_PASS_AFTER',
            'BY_PASS_ACCOUNT_ON_AFTER', 'BY_PASS_ACCOUNT_ON_BEFORE',
            'BY_PASS_IMPLEMENTATION_ON_AFTER', 'BY_PASS_IMPLEMENTATION_ON_BEFORE',
            'BY_PASS_EVENT_ON_BEFORE', 'BY_PASS_EVENT_ON_AFTER',
            'BY_PASS_PARTNER_ACCOUNT_ON_AFTER', 'BY_PASS_PARTNER_ACCOUNT_ON_BEFORE',
            'BY_PASS_CONTACT_ON_AFTER', 'BY_PASS_CONTACT_ON_BEFORE',
            'BY_PASS_ACCOUNT_ON_UPDATE', 'BY_PASS_ACCOUNT_ON_INSERT',
            'BY_PASS_CONTACT_ON_UPDATE', 'BY_PASS_CONTACT_ON_INSERT',
            'BY_PASS_OPPORTUNITY_ON_UPDATE', 'BY_PASS_OPPORTUNITY_ON_INSERT',
            'BY_PASS_CASE_ON_UPDATE', 'BY_PASS_CASE_ON_INSERT',
            'BY_PASS_LINEITEM_ON_UPDATE', 'BY_PASS_LINEITEM_ON_INSERT',
            'BY_PASS_RCQUOTE_ON_UPDATE', 'BY_PASS_RCQUOTE_ON_INSERT',
            'BY_PASS_Approver_Trigger', 'ALLOW_TRIGGER_REQUEST_ONCE',
            'BY_PASS_CARRIERDATA_ON_INSERT', 'BY_PASS_CARRIERDATA_ON_UPDATE',
            'BY_PASS_CASE_Trigger', 'UPDATE_CONTACT_BMID', 'BY_PASS_LEAD_UPDATE',
            'BY_PASS_CASECOMMENT_ON_UPDATE', 'BY_PASS_CASECOMMENT_ON_INSERT',
            'BY_PASS_PARTNERCOMM_ON_UPDATE', 'BY_PASS_PARTNERCOMM_ON_INSERT',
            'BY_PASS_EVENT_ON_INSERT', 'BY_PASS_EVENT_ON_UPDATE', 'BY_PASS_TOTAL_ESTIMATE_CALCULATION'
        };

        TriggerHandler.bypassTrigger(allTriggersToBypass, true);

        System.assert(TriggerHandler.BY_PASS_BEFORE);
        System.assert(TriggerHandler.BY_PASS_AFTER);
        System.assert(TriggerHandler.BY_PASS_ACCOUNT_ON_AFTER);
        System.assert(TriggerHandler.BY_PASS_ACCOUNT_ON_BEFORE);
        System.assert(TriggerHandler.BY_PASS_IMPLEMENTATION_ON_AFTER);
        System.assert(TriggerHandler.BY_PASS_IMPLEMENTATION_ON_BEFORE);
        System.assert(TriggerHandler.BY_PASS_EVENT_ON_BEFORE);
        System.assert(TriggerHandler.BY_PASS_EVENT_ON_AFTER);
        System.assert(TriggerHandler.BY_PASS_PARTNER_ACCOUNT_ON_AFTER);
        System.assert(TriggerHandler.BY_PASS_PARTNER_ACCOUNT_ON_BEFORE);
        System.assert(TriggerHandler.BY_PASS_CONTACT_ON_AFTER);
        System.assert(TriggerHandler.BY_PASS_CONTACT_ON_BEFORE);
        System.assert(TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE);
        System.assert(TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT);
        System.assert(TriggerHandler.BY_PASS_CONTACT_ON_UPDATE);
        System.assert(TriggerHandler.BY_PASS_CONTACT_ON_INSERT);
        System.assert(TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE);
        System.assert(TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT);
        System.assert(TriggerHandler.BY_PASS_CASE_ON_UPDATE);
        System.assert(TriggerHandler.BY_PASS_CASE_ON_INSERT);
        System.assert(TriggerHandler.BY_PASS_LINEITEM_ON_UPDATE);
        System.assert(TriggerHandler.BY_PASS_LINEITEM_ON_INSERT);
        System.assert(TriggerHandler.BY_PASS_RCQUOTE_ON_UPDATE);
        System.assert(TriggerHandler.BY_PASS_RCQUOTE_ON_INSERT);
        System.assert(TriggerHandler.BY_PASS_Approver_Trigger); 
        System.assert(TriggerHandler.BY_PASS_CARRIERDATA_ON_INSERT);
        System.assert(TriggerHandler.BY_PASS_CARRIERDATA_ON_UPDATE);
        System.assert(TriggerHandler.BY_PASS_CASE_Trigger);
        System.assert(TriggerHandler.UPDATE_CONTACT_BMID);
        System.assert(TriggerHandler.BY_PASS_LEAD_UPDATE);
        System.assert(TriggerHandler.BY_PASS_CASECOMMENT_ON_UPDATE);
        System.assert(TriggerHandler.BY_PASS_CASECOMMENT_ON_INSERT);
        System.assert(TriggerHandler.BY_PASS_PARTNERCOMM_ON_UPDATE);
        System.assert(TriggerHandler.BY_PASS_PARTNERCOMM_ON_INSERT);
        System.assert(TriggerHandler.BY_PASS_EVENT_ON_INSERT);
        System.assert(TriggerHandler.BY_PASS_EVENT_ON_UPDATE);
        System.assert(TriggerHandler.BY_PASS_TOTAL_ESTIMATE_CALCULATION);
    }
}