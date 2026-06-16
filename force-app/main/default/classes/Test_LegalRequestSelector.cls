@isTest
private class Test_LegalRequestSelector {
    @isTest
    static void testSelectLegalRequestById() {
        Legal_Requests__c legalReq = (Legal_Requests__c) new SObjectBuilder(Legal_Requests__c.SObjectType)
            .setField(Legal_Requests__c.Title_of_Invention__c, 'Test Invention')
            .create()
            .getRecord();

        List<Legal_Requests__c> insertedInvention = (List<Legal_Requests__c>) new LegalRequestSelector()
            .selectLegalRequestById(legalReq.Id)
            .executeQuery();

        System.assertEquals(1, insertedInvention.size());
        System.assertEquals(legalReq.Id, insertedInvention.get(0).Id);
    }
}