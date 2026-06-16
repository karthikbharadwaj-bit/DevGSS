@isTest private class Test_ProServProjectData {

    @isTest static void testRetrieveProServByQuoteNumber() {
        String quoteNumber = '12345';
        Proserv_Project__c psProject = new Proserv_Project__c(PS_Quote_Number__c = quoteNumber);
        insert psProject;
        Test.startTest();
        ProServProjectData proservProjectData = new ProServProjectData();
        Proserv_Project__c comparePsProject = proservProjectData.retrieveProServByQuoteNumber(quoteNumber);
        Test.stopTest();
        System.assert(comparePsProject != null,
                      'There should be at least one Proserv Project with the specified Quote Number');
    }

    @isTest static void testRetrieveProservs() {
        Proserv_Project__c firstProserv = (Proserv_Project__c) new SObjectBuilder(Proserv_Project__c.SObjectType)
            .create()
            .getRecord();
        Proserv_Project__c secondtProserv = (Proserv_Project__c) new SObjectBuilder(Proserv_Project__c.SObjectType)
            .create()
            .getRecord();
        List<Proserv_Project__c> proservList = new List<Proserv_Project__c>{firstProserv, secondtProserv};
        Set<Id> idsOfProservs = new Set<Id>();
        for (Proserv_Project__c proserv : proservList) {
            idsOfProservs.add(proserv.id);
        }
        Test.startTest();
        ProServProjectData proservProjectData = new ProServProjectData();
        List<Proserv_Project__c> compareProserv = proservProjectData.retrieveProservs(idsOfProservs);
        Test.stopTest();
        System.assert(compareProserv != null, 'Proserv Projects should have been retrieved');
        System.assertEquals(2, compareProserv.size(), '2 Proserv Projects should have been retrieved');

    }
}