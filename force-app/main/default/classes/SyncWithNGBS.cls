global class SyncWithNGBS {
    @TestVisible
    private static final String STEPS = 'steps';
    
    @AuraEnabled
    public static Opportunity getOppBillingDetail(String OppId){
        Opportunity Opp;
        try{
            Opp = (Opportunity) new OpportunitySelector()
                .selectOpportunitiesByIds(new Set<Id> {OppId})
                .selectFields(new Set<String> {'Is_Billing_Opportunity__c', 'Id'})
                .withoutSelectorFieldsIncluded()
                .executeQuery()
                .get(0);
        }
        catch(Exception ex){
            system.debug('Error:'+ex.getmessage());
        }
        return Opp;
    }

    @AuraEnabled
    webservice static String validateSyncWithNGBS(Id quoteId) {
        return SWNHelper.validateSyncWithNGBS(quoteId, false);
    }

    @AuraEnabled
    public static Response createDealDeskCaseDescriptions(Id quoteId) {
        Response res = new Response();
        try {
            SWNDataCollector sdc = new SWNDataCollector(quoteId);
            Boolean isSyncCompleted = sdc.isMPUB
                ? sdc.qt.ServiceInfo__r[0].IsProcessOrderSent__c
                : PartnerOperationsController.isCurrentSyncScenarioLastStepCompleted(sdc.qt.OpportunityId);

            if (!isSyncCompleted && sdc.qt != null && QuoteHelper.isLBOEnabled(sdc.qt)) {
                List<DealDeskCaseDescription__c> dealDeskDescriptionsToInsert = DealDeskCaseDescriptionHelper.handleDealDeskCaseDescriptionsForSyncWithNGBS(sdc.qt);
                if (!dealDeskDescriptionsToInsert.isEmpty()) {
                    insert dealDeskDescriptionsToInsert;
                }
            }
        } catch (Exception e) {
            res.error(
                Label.IsNotAvailableToSyncWithNGBS,
                e.getMessage() + ': ' + e.getStackTraceString()
            );
        }

        return res;
    }

    @AuraEnabled
    public static String customRulesValidation(Id opportunityId) {
        Response resp = new Response();
        String vaildationRuleText = '';
        try {
            Triggers.switchOff();
            update new Opportunity(Id = opportunityId);
            Triggers.switchOn();
        } catch (Exception e) {
            vaildationRuleText = SWNHelper.getCustomValidationMessage(e.getMessage());
            SWNMessageHelper.ErrorMessagesBuilder errorMessagesBuilder = new SWNMessageHelper.ErrorMessagesBuilder();
            resp.addMessage(errorMessagesBuilder.buildSWNMessage(Label.IsNotAvailableToSyncWithNGBS, Label.FailedCustomValidationRule + vaildationRuleText, null));
        }
        return JSON.serialize(resp.messages);
    }

    @AuraEnabled
    public static Response postValidationAction(Id quoteId) {
        Response res = new Response();

        try {
            Quote qt = SWNHelper.selectQuoteByIdWithExactField(quoteId, Quote.OpportunityId);
            PresignUpActions.upsertFunnelStatus(qt.OpportunityId);
        } catch (Exception e) {
            res.error('Error', e.getMessage() + ': ' + e.getStackTraceString());
        }

        return res;
    }

    @AuraEnabled
    public static Response isMultiproductFTEnabled() {
        Response res = new Response();
        try {
            res.setData('isMultiproductEnabled', POHelper.isMultiproductEnabled);
        } catch (Exception e) {
            res.error('Error', e.getMessage() + ': ' + e.getStackTraceString());
        }
        return res;
    }

    @AuraEnabled
    public static Response syncWithNGBS_v3(Id quoteId, String action) {
        SWNActionRunner runner = SWNHelper.getRunner(quoteId, action);
        return runner.sync();
    }

    @AuraEnabled
    public static Response getSyncInfo(Id quoteId, List<String> steps) {
        SWNDataCollector sdc = new SWNDataCollector(quoteId);
        return SWNSyncInfo.getStepsSyncInfo(sdc, steps);
    }

    @AuraEnabled
    public static Response syncEntitlements(Id quoteId) {
        if (quoteId == null) {
            throw new AquivaHelper.AquivaException(QuoteHelper.QUOTE_NOT_FOUND);
        }

        Response res = new Response();
        try {
            SWNHelper.syncEntitlements(quoteId);
        } catch (Exception e) {
            res.error('Error', e.getMessage() + ': ' + e.getStackTraceString());
        }

        return res;
    }

    @AuraEnabled
    public static Response getSyncScenario(Id quoteId) {
        SWNDataCollector sdc = new SWNDataCollector(quoteId);
        return SWNScenarioHelper.getSyncScenario(sdc);
    }

    @AuraEnabled
    public static Response getSyncSteps() {
        Response res = new Response();
        res.setData(STEPS, SWNStep.STEPS);
        return res;
    }

    @AuraEnabled
    public static void updateRCCCSyncStatus(Id quoteId) {
        Quote qt = SWNHelper.selectQuoteById(quoteId);
        if (!QuoteHelper.isRCCC(qt)) {
            return;
        }
        Opportunity opp = qt.Opportunity;
        IcbHelper.updateRCCCSyncStatus(opp.MasterOpportunity__c ?? opp.Id, IcbHelper.DEFAULT_SYNC_ERROR);
    }
}