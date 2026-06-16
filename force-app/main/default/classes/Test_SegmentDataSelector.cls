@isTest
private class Test_SegmentDataSelector {
    @IsTest
   private static void testSelectSegmentDataByAttribute1() {
        Segment_Data__c sd = (Segment_Data__c) new SobjectBuilder(Segment_Data__c.sObjectType)
            .setField(Segment_Data__c.Attribute_1__c, 'test@test.com')
            .create()
            .getRecord();

        Segment_Data__c returnedRecord = (Segment_Data__c) new SegmentDataSelector()
            .selectSegmentDataForSmartSearch(new List<Object>{'test@test.com'})
            .executeQuery()[0];

        System.assertEquals(sd.Id, returnedRecord.id,
            'Returned Segment Data record is not correct');
    }

    @IsTest
    private static void testSelectSegmentDataByAttribute1Enforced() {
        Segment_Data__c sd = (Segment_Data__c) new SobjectBuilder(Segment_Data__c.sObjectType)
            .setField(Segment_Data__c.Attribute_1__c, 'test@test.com')
            .create()
            .getRecord();

        Segment_Data__c returnedRecord = (Segment_Data__c) new SegmentDataSelector(true,true)
            .selectSegmentDataForSmartSearch(new List<Object>{'test@test.com'})
            .executeQuery()[0];

        System.assertEquals(sd.Id, returnedRecord.id,
            'Returned Segment Data record is not correct');

     }
}