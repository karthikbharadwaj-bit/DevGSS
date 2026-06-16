@isTest
public with sharing class Test_NGBSSyncables {
    private final static String TEST_SYNC_INFO = 'Test Sync Info';
    @isTest
    static void testOpportunitySync() {
        Triggers.switchOff();
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.CloseDate, Date.today())
            .create()
            .getRecord();
        Triggers.switchOn();

        NGBSSyncables.ISyncable syncable = NGBSSyncables.getSyncable(false, null, opp);

        Test.startTest();
        syncable.setFSCSynced();
        syncable.setICBSynced();
        syncable.setICBProvisioning();
        syncable.setOrderDate(Date.today());
        syncable.setSyncInfo(TEST_SYNC_INFO);
        syncable.setIsDownsellCaseCreated();
        syncable.setFlagSynced(Opportunity.isResyncContractAllowed__c);
        for (SObjectField field : new Set<SObjectField>(syncable.getNameToSObjectFieldMap().values())) {
            syncable.setFlagSynced(field);
        }
        syncable.updateSObject();
        Test.stopTest();

        Assert.areEqual(syncable.getSObjectToUpdate().Id, opp.Id, 'The Opportunity Id should match the test Opportunity Id');

        opp = (Opportunity) new OpportunitySelector()
            .selectOpportunityForSyncWithNGBS(opp.Id)
            .executeQuery()
            .get(0);

        assertSyncable(NGBSSyncables.getSyncable(false, null, opp));
    }

    @isTest
    static void testServiceInfoSync() {
        Triggers.switchOff();
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.CloseDate, Date.today())
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setField(Quote.OpportunityId, opp.Id)
            .create()
            .getRecord();

        ServiceInfo__c serviceInfo = (ServiceInfo__c) new SObjectBuilder(ServiceInfo__c.SObjectType)
            .setField(ServiceInfo__c.Quote__c, qt.Id)
            .create()
            .getRecord();
        Triggers.switchOn();

        NGBSSyncables.ISyncable syncable = NGBSSyncables.getSyncable(true, qt.Id, null);

        Test.startTest();
        syncable.setFSCSynced();
        syncable.setICBSynced();
        syncable.setICBProvisioning();
        syncable.setOrderDate(Date.today());
        syncable.setSyncInfo(TEST_SYNC_INFO);
        syncable.setIsDownsellCaseCreated();
        syncable.setFlagSynced(ServiceInfo__c.IsResyncContractAllowed__c);
        for (SObjectField field : new Set<SObjectField>(syncable.getNameToSObjectFieldMap().values())) {
            syncable.setFlagSynced(field);
        }
        syncable.updateSObject();
        Test.stopTest();

        Assert.areEqual(syncable.getSObjectToUpdate().Id, serviceInfo.Id, 'The Service Info Id should match the test Service Info Id');

        serviceInfo = (ServiceInfo__c) new ListOptional(
            new ServiceInfoSelector()
                .selectServiceInfoForNGBSSyncablesById(serviceInfo.Id)
                .executeQuery())
            .getFirst();

        assertSyncable(NGBSSyncables.getSyncable(true, qt.Id, null));
    }

    private static void assertSyncable(NGBSSyncables.ISyncable syncable) {
        Assert.areEqual(syncable.getSyncInfoField(), TEST_SYNC_INFO, 'The SyncInfo__c field should be set to Test Sync Info');
        Assert.isTrue(syncable.isFSCSynced(), 'The isFSCSynced method should return true');
        Assert.isTrue(syncable.isDiscountsSynced(), 'The isDiscountsSynced method should return true');
        Assert.isTrue(syncable.isContractsSynced(), 'The isContractsSynced method should return true');
        Assert.isTrue(syncable.isResyncContractAllowed(), 'The isResyncContractAllowed method should return true');
        Assert.isTrue(syncable.isRepriceSynced(), 'The isRepriceSynced method should return true');
        Assert.isTrue(syncable.isUpsellStepCompleted(), 'The isUpsellStepCompleted method should return true');
        Assert.isTrue(syncable.getBooleanFlagByStepName(SWNStep.UP_SELL), 'The getBooleanFlagByStepName method with UP_SELL passed value should return true');
        Assert.isTrue(syncable.isDownsellStepCompleted(), 'The isDownsellStepCompleted method should return true');
        Assert.isTrue(syncable.isUpgradeStepCompleted(), 'The isUpgradeStepCompleted method should return true');
        Assert.isTrue(syncable.isLicenseLimitsSynced(), 'The isLicenseLimitsSynced method should return true');
        Assert.isTrue(syncable.isContractCancelled(), 'The isContractCancelled method should return true');
        Assert.isTrue(syncable.isOrderStepCompleted(), 'The isOrderStepCompleted method should return true');
        Assert.isTrue(syncable.isInvoiceStepCompleted(), 'The isInvoiceStepCompleted method should return true');
        Assert.isTrue(syncable.isSpendingLimitRetrieveStepCompleted(), 'The isSpendingLimitRetrieveStepCompleted method should return true');
        Assert.isTrue(syncable.isTerminationStepCompleted(), 'The isTerminationStepCompleted method should return true');
        Assert.isTrue(syncable.isSyncedToICB(), 'The isSyncedToICB method should return true');
        Assert.isTrue(syncable.isICBProvisioningComplete(), 'The isICBProvisioningComplete method should return true');
        Assert.isTrue(syncable.isChargeTermSynced(), 'The isChargeTermSynced method should return true');
        Assert.isTrue(syncable.isDownsellCaseCreated(), 'The isDownsellCaseCreated method should return true');
    }
}