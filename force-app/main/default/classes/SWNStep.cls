public with sharing class SWNStep {
    public enum SYNC_STEP {
        DISCOUNT_SYNC,
        CONTRACT_SYNC,
        REPRICE_SYNC,
        UP_SELL,
        ORDER,
        DOWN_SELL,
        UPGRADE,
        UPDATE_LICENSE_LIMITS,
        CONTRACT_CANCELLATION,
        CONVERT_TO_PAID,
        CONVERT_TO_PAID_WHOLESALE,
        SYNC_TO_CCB_UPSELL,
        SYNC_TO_NGBS_UPSELL,
        SYNC_TO_CCB_DOWNSELL,
        SYNC_TO_NGBS_DOWNSELL,
        SYNC_TO_CCB_UPGRADE,
        SYNC_TO_NGBS_UPGRADE,
        SYNC_INVOICE,
        SYNC_TO_ICB,
        SYNC_TO_INCONTACT,
        SYNC_SPENDING_LIMIT_RETRIEVE,
        ENGAGE_ACCOUNT_TERMINATION,
        CHARGE_TERM_SYNC
    }

    public static final String DISCOUNT_SYNC = SYNC_STEP.DISCOUNT_SYNC.name();
    public static final String CONTRACT_SYNC = SYNC_STEP.CONTRACT_SYNC.name();
    public static final String REPRICE_SYNC = SYNC_STEP.REPRICE_SYNC.name();
    public static final String UP_SELL = SYNC_STEP.UP_SELL.name();
    public static final String ORDER = SYNC_STEP.ORDER.name();
    public static final String DOWN_SELL = SYNC_STEP.DOWN_SELL.name();
    public static final String UPGRADE = SYNC_STEP.UPGRADE.name();
    public static final String UPDATE_LICENSE_LIMITS = SYNC_STEP.UPDATE_LICENSE_LIMITS.name();
    public static final String CONTRACT_CANCELLATION = SYNC_STEP.CONTRACT_CANCELLATION.name();
    public static final String CONVERT_TO_PAID = SYNC_STEP.CONVERT_TO_PAID.name();
    public static final String CONVERT_TO_PAID_WHOLESALE = SYNC_STEP.CONVERT_TO_PAID_WHOLESALE.name();
    public static final String SYNC_TO_CCB_UPSELL = SYNC_STEP.SYNC_TO_CCB_UPSELL.name();
    public static final String SYNC_TO_NGBS_UPSELL = SYNC_STEP.SYNC_TO_NGBS_UPSELL.name();
    public static final String SYNC_TO_CCB_DOWNSELL = SYNC_STEP.SYNC_TO_CCB_DOWNSELL.name();
    public static final String SYNC_TO_NGBS_DOWNSELL = SYNC_STEP.SYNC_TO_NGBS_DOWNSELL.name();
    public static final String SYNC_TO_CCB_UPGRADE = SYNC_STEP.SYNC_TO_CCB_UPGRADE.name();
    public static final String SYNC_TO_NGBS_UPGRADE = SYNC_STEP.SYNC_TO_NGBS_UPGRADE.name();
    public static final String SYNC_INVOICE = SYNC_STEP.SYNC_INVOICE.name();
    public static final String SYNC_TO_ICB = SYNC_STEP.SYNC_TO_ICB.name();
    public static final String SYNC_TO_INCONTACT = SYNC_STEP.SYNC_TO_INCONTACT.name();
    public static final String SYNC_SPENDING_LIMIT_RETRIEVE = SYNC_STEP.SYNC_SPENDING_LIMIT_RETRIEVE.name();
    public static final String ENGAGE_ACCOUNT_TERMINATION = SYNC_STEP.ENGAGE_ACCOUNT_TERMINATION.name();
    public static final String CHARGE_TERM_SYNC = SYNC_STEP.CHARGE_TERM_SYNC.name();

    @AuraEnabled public String name;
    @AuraEnabled public String label;
    @AuraEnabled public String description;
    @AuraEnabled public List<String> affectedLicenses = new List<String>();
    public Boolean isStepCompletedSuccessfully = true;
    public Boolean isNeedToLogTimeStamp = true;
    public Boolean isAuto = false;
    public Map<String, Object> quoteFieldsToUpdate = new Map<String, Object>();
    public Map<String, Object> accountFieldsToUpdate = new Map<String, Object>();

    private SWNStep(String name, String label, String description, Boolean isNeedToLogTimeStamp, Boolean isAuto) {
        this.name = name;
        this.label = label;
        this.description = description;
        this.isNeedToLogTimeStamp = isNeedToLogTimeStamp;
        this.isAuto = isAuto;
    }

    @TestVisible
    class SWNStepBuilder {
        private String name;
        private String label;
        private String description = 'No description';
        private Boolean isNeedToLogTimeStamp = true;
        private Boolean isAuto = false;

        public SWNStepBuilder withName(String name) {
            this.name = name;
            return this;
        }

        public SWNStepBuilder withLabel(String label) {
            this.label = label;
            return this;
        }

        public SWNStepBuilder withDescription(String description) {
            this.description = description;
            return this;
        }

        public SWNStepBuilder doNotLogTimeStamp() {
            this.isNeedToLogTimeStamp = false;
            return this;
        }

        public SWNStepBuilder autoStep() {
            this.isAuto = true;
            return this;
        }

        public SWNStep build() {
            return new SWNStep(name, label, description, isNeedToLogTimeStamp, isAuto);
        }
    }

    public static final Map<String, SWNStep> STEPS = new Map<String, SWNStep> {
        DISCOUNT_SYNC => buildDiscountStep(),
        CONTRACT_SYNC => buildContractSyncStep(),
        REPRICE_SYNC => buildRepriceSyncStep(),
        DOWN_SELL => buildDownSellStep(),
        UP_SELL => buildUpSellStep(),
        UPGRADE => buildUpgradeStep(),
        UPDATE_LICENSE_LIMITS => buildUpdateLicenseLimitsStep(),
        CONTRACT_CANCELLATION => buildContractCancellationStep(),
        CONVERT_TO_PAID => buildConvertToPaidStep(),
        CONVERT_TO_PAID_WHOLESALE => buildConvertToPaidWholesaleStep(),
        SYNC_TO_CCB_UPSELL => buildSyncToCcbUpsellStep(),
        SYNC_TO_NGBS_UPSELL => buildSyncToNgbsUpsellStep(),
        SYNC_TO_CCB_DOWNSELL => buildSyncToCcbDownsellStep(),
        SYNC_TO_NGBS_DOWNSELL => buildSyncToNgbsDownsellStep(),
        ORDER => buildOrderSyncStep(),
        SYNC_TO_CCB_UPGRADE => buildSyncToCcbUpgradeStep(),
        SYNC_TO_NGBS_UPGRADE => buildSyncToNgbsUpgradeStep(),
        SYNC_INVOICE => buildSyncInvoiceStep(),
        ENGAGE_ACCOUNT_TERMINATION => buildEngageAccountTerminationStep(),
        CHARGE_TERM_SYNC => buildChargeTermSyncStep(),
        SYNC_TO_ICB => buildSyncToIcbStep(),
        SYNC_TO_INCONTACT => buildSyncToInContactStep(),
        SYNC_SPENDING_LIMIT_RETRIEVE => buildSyncSpendingLimitRetrieveStep()
    };

    public void addAffectedLicenses(List<String> licensesList) {
        if (licensesList == null || licensesList.isEmpty()) {
            return;
        }
        this.affectedLicenses.addAll(licensesList);
    }

    public static SWNStep buildDiscountStep() {
        return new SWNStepBuilder()
            .withName(DISCOUNT_SYNC)
            .withLabel('Discount sync')
            .withDescription('Discounts will be synced into NGBS')
            .autoStep()
            .build();
    }

    public static SWNStep buildContractSyncStep() {
        return new SWNStepBuilder()
            .withName(CONTRACT_SYNC)
            .withLabel('Contract sync')
            .withDescription('Contract Information will be synced into NGBS')
            .autoStep()
            .build();
    }

    public static SWNStep buildRepriceSyncStep() {
        return new SWNStepBuilder()
            .withName(REPRICE_SYNC)
            .withLabel('Reprice')
            .withDescription('New Pricing will be applied immediately')
            .build();
    }

    public static SWNStep buildDownSellStep() {
        return new SWNStepBuilder()
            .withName(DOWN_SELL)
            .withLabel('Down-sell (in external system)')
            .withDescription('Licenses should be deprovisioned manually in Service Web before proceeding')
            .doNotLogTimeStamp()
            .build();
    }

    public static SWNStep buildUpSellStep() {
        return new SWNStepBuilder()
            .withName(UP_SELL)
            .withLabel('Up-sell (in external system)')
            .withDescription('Licenses should be added manually in Service Web')
            .doNotLogTimeStamp()
            .build();
    }

    public static SWNStep buildUpgradeStep() {
        return new SWNStepBuilder()
            .withName(UPGRADE)
            .withLabel('Upgrade (in external system)')
            .withDescription('Package and/or Plan should be changed manually')
            .doNotLogTimeStamp()
            .build();
    }

    public static SWNStep buildUpdateLicenseLimitsStep() {
        return new SWNStepBuilder()
            .withName(UPDATE_LICENSE_LIMITS)
            .withLabel('License limits will be synced with NGBS')
            .withDescription('License limits will be synced with NGBS')
            .build();
    }

    public static SWNStep buildContractCancellationStep() {
        return new SWNStepBuilder()
            .withName(CONTRACT_CANCELLATION)
            .withLabel('Contract cancellation')
            .withDescription('Contract will be cancelled in NGBS')
            .autoStep()
            .build();
    }

    public static SWNStep buildConvertToPaidStep() {
        return new SWNStepBuilder()
            .withName(CONVERT_TO_PAID)
            .withLabel('Convert to Paid')
            .withDescription('Account should be converted to Paid in Service Web manually before proceeding')
            .build();
    }

    public static SWNStep buildConvertToPaidWholesaleStep() {
        return new SWNStepBuilder()
            .withName(CONVERT_TO_PAID_WHOLESALE)
            .withLabel('Convert to Paid')
            .withDescription('Account should be converted to Paid in Billing Admin Portal manually before proceeding')
            .build();
    }

    public static SWNStep buildSyncToCcbUpsellStep() {
        return new SWNStepBuilder()
            .withName(SYNC_TO_CCB_UPSELL)
            .withLabel('Up-sell (in external system)')
            .withDescription('License changes will be synced into CCB')
            .build();
    }

    public static SWNStep buildSyncToNgbsUpsellStep() {
        return new SWNStepBuilder()
            .withName(SYNC_TO_NGBS_UPSELL)
            .withLabel('Up-sell')
            .withDescription('License changes will be synced into NGBS')
            .build();
    }

    public static SWNStep buildSyncToCcbDownsellStep() {
        return new SWNStepBuilder()
            .withName(SYNC_TO_CCB_DOWNSELL)
            .withLabel('Down-sell (in external system)')
            .withDescription('License changes will be synced into CCB')
            .build();
    }

    public static SWNStep buildSyncToNgbsDownsellStep() {
        return new SWNStepBuilder()
            .withName(SYNC_TO_NGBS_DOWNSELL)
            .withLabel('Down-sell')
            .withDescription('License changes will be synced into NGBS')
            .build();
    }

    public static SWNStep buildOrderSyncStep() {
        return new SWNStepBuilder()
            .withName(ORDER)
            .withLabel('Order sync')
            .withDescription('Order will be synced into NGBS')
            .build();
    }

    public static SWNStep buildSyncToCcbUpgradeStep() {
        return new SWNStepBuilder()
            .withName(SYNC_TO_CCB_UPGRADE)
            .withLabel('Upgrade with Upsell and/or Downsell (in external system)')
            .withDescription('Package and/or Plan changes and License changes will be synced into CCB')
            .build();
    }

    public static SWNStep buildSyncToNgbsUpgradeStep() {
        return new SWNStepBuilder()
            .withName(SYNC_TO_NGBS_UPGRADE)
            .withLabel('Upgrade with Upsell and/or Downsell')
            .withDescription('Package and/or Plan changes and License changes will be synced into NGBS')
            .build();
    }

    public static SWNStep buildSyncInvoiceStep() {
        return new SWNStepBuilder()
            .withName(SYNC_INVOICE)
            .withLabel('Sync payment method (in external system)')
            .withDescription('Payment method will be synced into NGBS')
            .build();
    }

    public static SWNStep buildEngageAccountTerminationStep() {
        return new SWNStepBuilder()
            .withName(ENGAGE_ACCOUNT_TERMINATION)
            .withLabel('Engage Account termination')
            .withDescription('Account will be terminated in Engage and NGBS')
            .build();
    }

    public static SWNStep buildChargeTermSyncStep() {
        return new SWNStepBuilder()
            .withName(CHARGE_TERM_SYNC)
            .withLabel('Charge term sync')
            .withDescription('Charge term information will be synced into NGBS')
            .build();
    }

    public static SWNStep buildSyncToIcbStep() {
        return new SWNStepBuilder()
            .withName(SYNC_TO_ICB)
            .withLabel('ICB sync')
            .withDescription('Initiate change order process with InContact Billing Connector (ICB)')
            .build();
    }

    public static SWNStep buildSyncToInContactStep() {
        return new SWNStepBuilder()
            .withName(SYNC_TO_INCONTACT)
            .withLabel('InContact sync')
            .withDescription('Sync with NICE InContact team via case to case')
            .build();
    }

    public static SWNStep buildSyncSpendingLimitRetrieveStep() {
        return new SWNStepBuilder()
            .withName(SYNC_SPENDING_LIMIT_RETRIEVE)
            .withLabel('Spending Limit Retrieve Sync')
            .withDescription('Since the spending limit has been increased for this opportunity and the change order has one-time items, the spending limit is being reduced by the cost of one-time items.')
            .build();
    }

}