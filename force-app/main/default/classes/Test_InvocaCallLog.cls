@isTest
public with sharing class Test_InvocaCallLog {
    @TestSetup
    static void setupData(){
        Lead lead = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSOPEN)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .create()
            .getRecord();

        new SObjectBuilder(INVOCA_FOR_SF__Invoca_Call_Log__c.SObjectType)
            .setField(INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__Customer_String_Value_8__c, 'Test')
            .setField(INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__Lead__c, lead.Id)
            .setField(INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__transaction_id__c, '321')
            .create();

        new SObjectBuilder(INVOCA_FOR_SF__Invoca_Call_Log__c.SObjectType)
            .setField(INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__Customer_String_Value_8__c, 'Test')
            .setField(INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__transaction_id__c, '123')
            .create();
    }

    @isTest 
    static void testInvocaUpdateCustomerStringValueWithLead() {
        test.startTest();
        INVOCA_FOR_SF__Invoca_Call_Log__c invocaRecord = (INVOCA_FOR_SF__Invoca_Call_Log__c) 
            new InvocaSelector()
                .selectInvocaRecordById('321')
                .executeQuery()[0];

        invocaRecord.INVOCA_FOR_SF__Customer_String_Value_8__c = 'Value in Lead';
        update invocaRecord;
        test.stopTest();
        Lead invocaLead = (Lead) new LeadSelector().selectLeadByLastName(new List<Object>{Test_DemandFunnelHelper.LEADLASTNAME}).selectField(Lead.GCLID__c).executeQuery()[0];
        System.assertEquals(invocaLead.GCLID__c, invocaRecord.INVOCA_FOR_SF__Customer_String_Value_8__c, 'GCLID__c was not populated in Lead');
    }

    @isTest 
    static void testInvocaUpdateCustomerStringValueWithoutLead() {
        test.startTest();
        INVOCA_FOR_SF__Invoca_Call_Log__c invocaRecord = (INVOCA_FOR_SF__Invoca_Call_Log__c) 
            new InvocaSelector()
                .selectInvocaRecordById('123')
                .executeQuery()[0];

        invocaRecord.INVOCA_FOR_SF__Customer_String_Value_8__c = 'Value in Lead';
        update invocaRecord;
        test.stopTest();
        Lead invocaLead = (Lead) new LeadSelector().selectLeadByLastName(new List<Object>{Test_DemandFunnelHelper.LEADLASTNAME}).selectField(Lead.GCLID__c).executeQuery()[0];
        System.assertNotEquals(invocaLead.GCLID__c, invocaRecord.INVOCA_FOR_SF__Customer_String_Value_8__c, 'GCLID__c was populated in Lead');
    }
}