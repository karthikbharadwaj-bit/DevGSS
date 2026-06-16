@isTest 
private class Test_DowngradePopUpCtrl {

    @isTest
    static void constructorSetsDowngradeStatus() {
        Lead testLead = createLead();
        insert testLead;

        ApexPages.StandardController stdController = new ApexPages.StandardController(testLead);

        Test.startTest();
        DowngradePopUpCtrl controller = new DowngradePopUpCtrl(stdController);
        Test.stopTest();

        System.assertEquals(LeadHelper.STATUS_DOWNGRADED, controller.currentLead.Status,
            'Controller should immediately downgrade the Lead status.');
    }

    @isTest
    static void saveLeadPersistsDowngradeStatus() {
        Lead testLead = createLead();
        insert testLead;

        DowngradePopUpCtrl controller = new DowngradePopUpCtrl(new ApexPages.StandardController(testLead));

        Test.startTest();
        controller.saveLead();
        Test.stopTest();

        Lead persistedLead = [SELECT Status FROM Lead WHERE Id = :testLead.Id];
        System.assertEquals(LeadHelper.STATUS_DOWNGRADED, persistedLead.Status,
            'saveLead should persist the downgraded status to the database.');
    }

    private static Lead createLead() {
        Lead leadRecord = new Lead();
        leadRecord.LastName = 'Test';
        leadRecord.Company = 'Test Co';
        leadRecord.Status = LeadHelper.STATUS_NEW;
        return leadRecord;
    }
}