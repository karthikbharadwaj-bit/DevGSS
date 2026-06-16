public abstract class SWNStepInfo {
    @AuraEnabled public String status;
    @AuraEnabled public Boolean skip;
    @AuraEnabled public Boolean auto;

    @TestVisible
    private SWNStepInfo(SWNDataCollector sdc, Boolean skip, Boolean auto) {
        this.status = getSyncStatus(sdc);
        this.skip = skip;
        this.auto = auto;
    }
    @TestVisible
    private SWNStepInfo(SWNDataCollector sdc) {
        this(sdc, false, false);
    }

    public static SWNStepInfo getStepInfo(String stepName, SWNDataCollector sdc) {
        SWNStepInfo stepInfo;
        switch on SWNStep.SYNC_STEP.valueOf(stepName) {
            when DISCOUNT_SYNC {
                stepInfo = new DiscountSyncInfo(sdc);
            }
            when CONTRACT_SYNC {
                stepInfo = new ContractSyncInfo(sdc);
            }
            when REPRICE_SYNC {
                stepInfo = new RepriceSyncInfo(sdc);
            }
            when DOWN_SELL, SYNC_TO_NGBS_DOWNSELL {
                stepInfo = new DownsellStepInfo(sdc);
            }
            when UP_SELL, SYNC_TO_NGBS_UPSELL {
                stepInfo = new UpsellStepInfo(sdc);
            }
            when ORDER {
                stepInfo = new OrderStepInfo(sdc);
            }
            when UPGRADE {
                stepInfo = new UpgradeStepInfo(sdc);
            }
            when UPDATE_LICENSE_LIMITS {
                stepInfo = new UpdateLicenseLimitsStepInfo(sdc);
            }
            when CONTRACT_CANCELLATION {
                stepInfo = new CancelContractStepInfo(sdc);
            }
            when CONVERT_TO_PAID, CONVERT_TO_PAID_WHOLESALE {
                stepInfo = new ConvertToPaidStepInfo(sdc);
            }
            when SYNC_TO_CCB_UPSELL {
                stepInfo = new SyncToCCBUpsellInfo(sdc);
            }
            when SYNC_TO_CCB_DOWNSELL {
                stepInfo = new SyncToCCBDownSellInfo(sdc);
            }
            when SYNC_TO_CCB_UPGRADE {
                stepInfo = new UpgradeCCBInfo(sdc);
            }
            when SYNC_TO_NGBS_UPGRADE {
                stepInfo = new UpgradeICBInfo(sdc);
            }
            when SYNC_INVOICE {
                stepInfo = new InvoiceStepInfo(sdc);
            }
            when SYNC_SPENDING_LIMIT_RETRIEVE {
                stepInfo = new SpendingLimitRetrieveStepInfo(sdc);
            }
            when ENGAGE_ACCOUNT_TERMINATION {
                stepInfo = new AccountTerminationCCBInfo(sdc);
            }
            when CHARGE_TERM_SYNC {
                stepInfo = new ChargeTermICBInfo(sdc);
            }
            when SYNC_TO_ICB {
                stepInfo = new SyncToICBInfo(sdc);
            }
            when SYNC_TO_INCONTACT {
                stepInfo = new SyncToInContactInfo(sdc);
            }
        }
        return stepInfo;
    }

    protected abstract String getSyncStatus(SWNDataCollector sdc);
    @TestVisible
    protected String getSyncStatus(Boolean isSynced) {
        return isSynced ? SWNHelper.SYNCED : SWNHelper.NOT_SYNCED;
    }

    @TestVisible
    private class AccountTerminationCCBInfo extends SWNStepInfo {
        public AccountTerminationCCBInfo(SWNDataCollector sdc) {
            super(sdc);
        }

        protected override String getSyncStatus(SWNDataCollector sdc) {
            return getSyncStatus(sdc.syncable.isTerminationStepCompleted());
        }
    }
    @TestVisible
    private class CancelContractStepInfo extends SWNStepInfo {
        public CancelContractStepInfo(SWNDataCollector sdc) {
            super(sdc, false, true);
        }

        protected override String getSyncStatus(SWNDataCollector sdc) {
            return getSyncStatus(sdc.syncable.isContractCancelled());
        }
    }
    @TestVisible
    private class ChargeTermICBInfo extends SWNStepInfo {
        public ChargeTermICBInfo(SWNDataCollector sdc) {
            super(sdc);
        }

        protected override String getSyncStatus(SWNDataCollector sdc) {
            Boolean isSynced = sdc.syncable.isChargeTermSynced()
                || SWNHelper.isPackagePlanEqual(sdc.ngbsAcc, sdc.qt);
            return getSyncStatus(isSynced);
        }
    }
    @TestVisible
    private class ContractSyncInfo extends SWNStepInfo {
        public ContractSyncInfo(SWNDataCollector sdc) {
            super(sdc, false, true);
        }

        protected override String getSyncStatus(SWNDataCollector sdc) {
            return SWNHelper.getContractSyncStatus(sdc.syncable, sdc.qt);
        }
    }
    @TestVisible
    private class ConvertToPaidStepInfo extends SWNStepInfo {
        public ConvertToPaidStepInfo(SWNDataCollector sdc) {
            super(sdc);
        }

        protected override String getSyncStatus(SWNDataCollector sdc) {
            String packageId = QuoteHelper.getPackageId(sdc.qt.Package_Info__c);
            return getSyncStatus(SWNHelper.checkPaidStatus(sdc.ngbsAcc.getPackageById(packageId)));
        }
    }
    @TestVisible
    private class DiscountSyncInfo extends SWNStepInfo {
        public DiscountSyncInfo(SWNDataCollector sdc) {
            super(sdc, false, true);
        }

        protected override String getSyncStatus(SWNDataCollector sdc) {
            return getSyncStatus(sdc.syncable.isDiscountsSynced());
        }
    }
    @TestVisible
    private class DownsellStepInfo extends SWNStepInfo {
        public DownsellStepInfo(SWNDataCollector sdc) {
            super(sdc);
        }

        protected override String getSyncStatus(SWNDataCollector sdc) {
            return getSyncStatus(sdc.syncable.isDownsellStepCompleted());
        }
    }
    @TestVisible
    private class InvoiceStepInfo extends SWNStepInfo {
        public InvoiceStepInfo(SWNDataCollector sdc) {
            super(sdc);
        }

        protected override String getSyncStatus(SWNDataCollector sdc) {
            return getSyncStatus(sdc.syncable.isInvoiceStepCompleted());
        }
    }
    @TestVisible
    private class OrderStepInfo extends SWNStepInfo {
        public OrderStepInfo(SWNDataCollector sdc) {
            super(sdc);
        }

        protected override String getSyncStatus(SWNDataCollector sdc) {
            return getSyncStatus(sdc.syncable.isOrderStepCompleted());
        }
    }
    @TestVisible
    private class RepriceSyncInfo extends SWNStepInfo {
        public RepriceSyncInfo(SWNDataCollector sdc) {
            super(sdc);
        }

        protected override String getSyncStatus(SWNDataCollector sdc) {
            return getSyncStatus(sdc.syncable.isRepriceSynced());
        }
    }
    @TestVisible
    private class SpendingLimitRetrieveStepInfo extends SWNStepInfo {
        public SpendingLimitRetrieveStepInfo(SWNDataCollector sdc) {
            super(sdc);
        }

        protected override String getSyncStatus(SWNDataCollector sdc) {
            return getSyncStatus(sdc.syncable.isSpendingLimitRetrieveStepCompleted());
        }
    }
    @TestVisible
    private abstract class SyncToCCBInfo extends SWNStepInfo {
        public SyncToCCBInfo(SWNDataCollector sdc) {
            super(sdc);
        }

        protected abstract Boolean isStepCompleted(NGBSSyncables.ISyncable syncable);
        protected abstract List<QuoteLineItem> getFilteredQliList(List<QuoteLineItem> qlis);
        protected override String getSyncStatus(SWNDataCollector sdc) {
            Boolean isSynced = isStepCompleted(sdc.syncable)
                || SWNHelper.checkSyncQtyStatus(sdc.billingId, sdc.packageId, getFilteredQliList(sdc.qlis));
            return getSyncStatus(isSynced);
        }
    }
    @TestVisible
    private class SyncToCCBDownSellInfo extends SyncToCCBInfo {
        public SyncToCCBDownSellInfo(SWNDataCollector sdc) {
            super(sdc);
        }

        protected override Boolean isStepCompleted(NGBSSyncables.ISyncable syncable) {
            return syncable.isDownsellStepCompleted();
        }
        protected override List<QuoteLineItem> getFilteredQliList(List<QuoteLineItem> qlis) {
            return SWNHelper.getDownsellQliList(qlis);
        }
    }
    @TestVisible
    private class SyncToCCBUpsellInfo extends SyncToCCBInfo {
        public SyncToCCBUpsellInfo(SWNDataCollector sdc) {
            super(sdc);
        }

        protected override Boolean isStepCompleted(NGBSSyncables.ISyncable syncable) {
            return syncable.isUpsellStepCompleted();
        }
        protected override List<QuoteLineItem> getFilteredQliList(List<QuoteLineItem> qlis) {
            return SWNHelper.getUpsellQliList(qlis);
        }
    }
    @TestVisible
    private class SyncToICBInfo extends SWNStepInfo {
        public SyncToICBInfo(SWNDataCollector sdc) {
            super(sdc);
        }

        protected override String getSyncStatus(SWNDataCollector sdc) {
            return getSyncStatus(sdc.syncable.isSyncedToICB());
        }
    }
    @TestVisible
    private class SyncToInContactInfo extends SWNStepInfo {
        public SyncToInContactInfo(SWNDataCollector sdc) {
            super(sdc);
        }

        protected override String getSyncStatus(SWNDataCollector sdc) {
            return getSyncStatus(sdc.syncable.isICBProvisioningComplete());
        }
    }
    @TestVisible
    private class UpgradeCCBInfo extends SWNStepInfo {
        public UpgradeCCBInfo(SWNDataCollector sdc) {
            super(sdc);
        }

        protected override String getSyncStatus(SWNDataCollector sdc) {
            Boolean isSynced = sdc.syncable.isUpgradeStepCompleted()
                || SWNHelper.checkUpgradeCCBStatus(sdc.qt, sdc.ngbsAcc);
            return getSyncStatus(isSynced);
        }
    }
    @TestVisible
    private class UpgradeICBInfo extends SWNStepInfo {
        public UpgradeICBInfo(SWNDataCollector sdc) {
            super(sdc);
        }

        protected override String getSyncStatus(SWNDataCollector sdc) {
            Boolean isSynced = sdc.syncable.isUpgradeStepCompleted()
                || SWNHelper.isPackageEqual(sdc.ngbsAcc, sdc.qt);
            return getSyncStatus(isSynced);
        }
    }
    @TestVisible
    private class UpgradeStepInfo extends SWNStepInfo {
        public UpgradeStepInfo(SWNDataCollector sdc) {
            super(sdc);
        }

        protected override String getSyncStatus(SWNDataCollector sdc) {
            return getSyncStatus(sdc.syncable.isUpgradeStepCompleted());
        }
    }
    @TestVisible
    private class UpdateLicenseLimitsStepInfo extends SWNStepInfo {
        public UpdateLicenseLimitsStepInfo(SWNDataCollector sdc) {
            super(sdc);
        }

        protected override String getSyncStatus(SWNDataCollector sdc) {
            return getSyncStatus(sdc.syncable.isLicenseLimitsSynced());
        }
    }
    @TestVisible
    private class UpsellStepInfo extends SWNStepInfo {
        public UpsellStepInfo(SWNDataCollector sdc) {
            super(sdc);
        }

        protected override String getSyncStatus(SWNDataCollector sdc) {
            return getSyncStatus(sdc.syncable.isUpsellStepCompleted());
        }
    }
}