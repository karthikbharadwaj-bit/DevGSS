@isTest
private with sharing class Test_DemandFunnelComponentController {
    @isTest
    private static void testGetRelatedDFRs() {
        
        
        test.startTest();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
                .setField(Contact.FirstName, 'John')
                .setField(Contact.LastName, 'Doe')
                .setField(Contact.Email, 'test@test.com')
                .setField(Contact.Phone, '1234567890')
                .setField(Contact.Preferred_Language__c, 'en_US')
                .setField(Contact.Contact_Status__c, '2. Contacted')
                .create()
                .getRecord(); 
        test.stopTest();
        System.assertEquals(1, DemandFunnelComponentController.getRelatedDFRs(con.id).size(), 'Error trying to obtain related DFRs');
    }
}