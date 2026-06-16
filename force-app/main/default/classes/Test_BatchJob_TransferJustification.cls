@isTest
private with sharing class Test_BatchJob_TransferJustification {
    @isTest
    static void testTransferJustificationWithoutParameter() {
        DQ_Deal_Qualification__c dq = (DQ_Deal_Qualification__c) new SObjectBuilder(DQ_Deal_Qualification__c.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                DQ_Deal_Qualification__c.Justification_For_Discount__c => 'Test Value',
                DQ_Deal_Qualification__c.Justification_Description__c => ''
            })
            .create()
            .getRecord();

        Test.startTest();
        Database.executeBatch(new BatchJob_TransferJustification());
        Test.stopTest();

        dq = (DQ_Deal_Qualification__c) new DealQualificationSelector()
            .selectDQs()
            .selectFields(
                new Set<SObjectField>{
                    DQ_Deal_Qualification__c.Justification_For_Discount__c,
                    DQ_Deal_Qualification__c.Justification_Description__c
                }
            )
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object>{ dq.Id })
            .executeQuery()
            .get(0);

        System.assertEquals(
            dq.Justification_For_Discount__c,
            dq.Justification_Description__c,
            'DQ Deal Qualification Justification_Description__c field value must be equal to Justification_For_Discount__c field value');
    }

    @isTest
    static void testTransferJustificationWithParameter() {
        DQ_Deal_Qualification__c dq = (DQ_Deal_Qualification__c) new SObjectBuilder(DQ_Deal_Qualification__c.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                DQ_Deal_Qualification__c.Justification_For_Discount__c => 'Test Value',
                DQ_Deal_Qualification__c.Justification_Description__c => '',
                DQ_Deal_Qualification__c.Renewal_Term__c => '12'
            })
            .create()
            .getRecord();

        Test.startTest();
        Database.executeBatch(new BatchJob_TransferJustification(
            'SELECT Justification_For_Discount__c, Justification_Description__c ' +
            'FROM DQ_Deal_Qualification__c ' +
            'WHERE Renewal_Term__c = \'12\''));
        Test.stopTest();

        dq = (DQ_Deal_Qualification__c) new DealQualificationSelector()
            .selectDQs()
            .selectFields(
                new Set<SObjectField>{
                    DQ_Deal_Qualification__c.Justification_For_Discount__c,
                    DQ_Deal_Qualification__c.Justification_Description__c
                }
            )
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object>{ dq.Id })
            .executeQuery()
            .get(0);

        System.assertEquals(
            dq.Justification_For_Discount__c,
            dq.Justification_Description__c,
            'DQ Deal Qualification Justification_Description__c field value must be equal to Justification_For_Discount__c field value');
    }
}