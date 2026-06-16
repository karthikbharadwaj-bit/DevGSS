@isTest
class Test_SWNConvertToPaidRunner {

    @isTest
    static void testConvertToPaidSkipped() {
        SWNConvertToPaidRunner runner = new SWNConvertToPaidRunner(null, SWNStep.CONVERT_TO_PAID);
        runner.sdc = new SWNDataCollector();
        runner.sdc.ngbsPackage = new BillingWrappers.NGBSAccountPackage();
        runner.sdc.ngbsPackage.offerType = 'regular';

        Test.startTest();
            runner.convertToPaid();
        Test.stopTest();
        
        Assert.areEqual(0, runner.res.messages.size(), 'No error messages should be created');
        Assert.isTrue(runner.isSkipFinalize, 'Finalize step should be skipped');
    }

    @isTest
    static void testConvertToPaid() {
        SWNConvertToPaidRunner runner = new SWNConvertToPaidRunner(null, SWNStep.CONVERT_TO_PAID);
        runner.sdc = new SWNDataCollector();
        runner.sdc.syncable = new NGBSSyncables.OpportunitySync(new Opportunity());
        runner.sdc.ngbsPackage = new BillingWrappers.NGBSAccountPackage();
        runner.sdc.ngbsPackage.offerType = 'some type';
        runner.sdc.qt = (Quote) Test_Utils.putIntoUnwritableField(
            new Quote(),
            Quote.class,
            'ServiceInfo__r',
            new List<ServiceInfo__c>()
        );

        Test.startTest();
            runner.convertToPaid();
        Test.stopTest();
        
        Assert.areEqual(1, runner.res.messages.size(), 'Error message should be created');
        Assert.areEqual(SWNConvertToPaidRunner.PACKAGE_IS_NOT_CONVERTED, runner.res.messages[0].messageDetails, 'Error message should be created');
        Assert.isTrue(runner.isSkipFinalize, 'Finalize step should be skipped');
    }
}