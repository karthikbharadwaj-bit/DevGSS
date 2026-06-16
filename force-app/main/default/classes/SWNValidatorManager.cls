public with sharing class SWNValidatorManager {
    @TestVisible
    private List<Validator> validators;
    @TestVisible
    private SWNDataCollector sdc;
    private Boolean isAutoSync = false;

    @TestVisible
    private SWNValidatorManager() {}

    public SWNValidatorManager(SWNDataCollector sdc, Boolean isAutoSync) {
        this.sdc = sdc;
        this.isAutoSync = isAutoSync;
        initializeValidators();
        chainValidators();
    }

    public Response validate() {
        Response resp = new Response();
        try {
            resp = this.validators[0].validate(resp);
        } catch (Exception e) {
            handleException(resp, e.getMessage());
        }
        return resp;
    }

    @TestVisible
    private void initializeValidators() {
        this.validators = new List<Validator> {
            new OpportunityValidator.SyncWithNGBS_NoOpportunityValidator(Validator.SEVERITY_CRITICAL, this.sdc.opp),
            new OpportunityValidator.SyncWithNGBS_SyncInContactFailedValidator(this.sdc.syncable),
            new QuoteValidator.SyncWithNGBS_ProfileValidator(this.sdc.qt, this.isAutoSync || QuoteHelper.isRCCC(this.sdc.qt)),
            new OpportunityValidator.UnsupportedBrandValidator(Validator.SEVERITY_CRITICAL, this.sdc.opp, POHelper.UNSUPPORTED_BRANDS, QuoteValidator.BillingProcessType.SYNC_WITH_NGBS),
            new AccountValidator.SyncWithNGBS_TerminatedAccountValidator(this.sdc.acc),
            new AccountValidator.SyncWithNGBS_TerminatedAccountValidator(this.sdc.acc, true),
            new QuoteValidator.SyncWithNGBS_DuplicatedQLIsValidator(this.sdc.qt),
            new OpportunityValidator.SyncWithNGBS_ClosedOpportunityValidator(Validator.SEVERITY_CRITICAL, this.sdc.opp)
        };

        if (isNotEngageTermination()) {
            addAdditionalValidators();
        }
    }

    @TestVisible
    private void chainValidators() {
        for (Integer i = 0; i < this.validators.size() - 1; i++) {
            this.validators[i].setNextValidator(this.validators[i + 1]);
        }
    }

    private Boolean isNotEngageTermination() {
        return !BooleanHelper.toBoolean(OpportunityHelper.engageOppIdToTerminationStatus(new List<Opportunity> {this.sdc.opp})?.get(this.sdc.opp.Id));
    }

    @TestVisible
    private void addAdditionalValidators() {
        this.validators.addAll(new List<Validator> {
            new QuoteValidator.BillingPackageExpirationValidator(this.sdc.qt, QuoteValidator.BillingProcessType.SYNC_WITH_NGBS, this.sdc.ngbsAcc),
            new QuoteValidator.SyncWithNGBS_EmptyBillingIdValidator(this.sdc.qt)
        });
    }

    @TestVisible
    private void handleException(Response resp, String errorMessage) {
        SWNMessageHelper.ErrorMessagesBuilder builder = new SWNMessageHelper.ErrorMessagesBuilder();
        resp.addMessage(builder.buildSWNMessage(Label.IsNotAvailableToSyncWithNGBS, errorMessage, null));
    }
}