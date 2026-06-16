public without sharing class PartnerOperationsController {

    public static final String CREATE_WHOLESALE_OPPTY = 'CREATE_WHOLESALE_OPPTY';
    public static final String CLOSE_OPPTY = 'CLOSE_OPPTY';
    public static final String CREATE_WHOLESALE_REQUEST = 'CREATE_WHOLESALE_REQUEST';
    public static final String APPROVE_WHOLESALE_REQUEST = 'APPROVE_WHOLESALE_REQUEST';
    public static final String SYNC_WITH_NGBS = 'SYNC_WITH_NGBS';
    public static final String WHOLESALE_SUBJECT = 'Wholesale_Partner_Operations';

    public static final Map<String, PartnerOperationsHelper.PartnerStep> STEPS =
        new Map<String, PartnerOperationsHelper.PartnerStep>
    {
        CREATE_WHOLESALE_OPPTY => new PartnerOperationsHelper.PartnerStep(
            CREATE_WHOLESALE_OPPTY,
            'Create New Wholesale Opportunity',
            'You will be redirected to a new Opportunity Creation Page. '
            + 'Wholesale Opportunity with selected Partner Package that is similar to current Customer package is required. '
            + '\nComplete all Quoting Steps in order to proceed.',
            'Create New Opportunity',
            1
        ),
        // CLOSE_OPPTY => new PartnerOperationsHelper.PartnerStep(
        //     CLOSE_OPPTY,
        //     'Complete all Quoting Steps and press Close button',
        //     'Complete all the necessary Quoting steps in Wholesale Opportunity and Close the Opportunity',
        //     'Open Wholesale Opportunity',
        //     2
        // ),
        CREATE_WHOLESALE_REQUEST => new PartnerOperationsHelper.PartnerStep(
            CREATE_WHOLESALE_REQUEST,
            'Create New Invoice-Wholesale Request',
            'You will be redirected to a new Invoice Approval Creation Form. '
            + 'Create Invoice-Wholesale Request, adjust calculated limits as needed and submit for approval',
            'Create New Request',
            2
        ),
        APPROVE_WHOLESALE_REQUEST => new PartnerOperationsHelper.PartnerStep(
            APPROVE_WHOLESALE_REQUEST,
            'Get Invoice-Wholesale Request approval',
            'If the limits on the approval are less or equal to Partner Credit Limits, '
            + 'the request will be approved automatically. Otherwise, wait for the Invoice Billing Approval',
            'Open Invoice-Wholesale Request',
            3
        ),
        SYNC_WITH_NGBS => new PartnerOperationsHelper.PartnerStep(
            SYNC_WITH_NGBS,
            'Sync to NGBS',
            'Please go back to Opportunity and close it. Also perform SyncWithNGBS process to sync new information to NGBS.',
            'Open Wholesale Opportunity',
            4
        )
    };

    @AuraEnabled
    public static Response getPartnerOperationSteps() {
        Response res = new Response();
        res.setData('steps', STEPS);
        return res;
    }

    @AuraEnabled
    public static Response getPartnerOperationScenario(Id logId) {
        Response res = new Response();
        List<PartnerOperationsStep__c> partnerSteps = (List<PartnerOperationsStep__c>)
            new QueryFactory(PartnerOperationsStep__c.SObjectType)
                .selectFields(new List<String> { 'Name', 'isCompleted__c' })
                .setQueryBindings(new List<Object>{ logId })
                .setCondition('PartnerOperationsLog__c =:bind0')
                .executeQuery();

        List<PartnerOperationsHelper.PartnerScenarioStep> scenarioSteps = new List<PartnerOperationsHelper.PartnerScenarioStep>();

        for (PartnerOperationsStep__c partnerStep: partnerSteps) {
            PartnerOperationsHelper.PartnerStep step = STEPS.get(partnerStep.Name);
            scenarioSteps.add(
                new PartnerOperationsHelper.PartnerScenarioStep(
                    step.name, step.label, step.description, step.action, step.order, partnerStep.isCompleted__c
                )
            );
        }

        PartnerOperationsHelper.PartnerScenario scenario = new PartnerOperationsHelper.PartnerScenario(scenarioSteps);
        res.setData('scenario', scenario);

        return res;
    }

    @AuraEnabled
    public static Response getCurrentOperation(Id accountId) {
        Response res = new Response();
        try {
            PartnerOperationsHelper.PartnerOperation operation = SettingsService.getCurrentPartnerOperation(accountId);
            if (operation == null) {
                res.error('Error', 'Please create new Wholesale Opportunity first');
                return res;
            }
            res.setData('operation', JSON.serialize(operation));
        } catch (Exception e) {
            res.error('Error', 'Operation is not found!');
        }
        return res;
    }

    @AuraEnabled
    public static Response validateStep(String params) {
        Response res = new Response();

        PartnerOperationsHelper.ValidateStepParams validateParams = (PartnerOperationsHelper.ValidateStepParams)
            JSON.deserialize(params, PartnerOperationsHelper.ValidateStepParams.class);

        List<PartnerOperationsStep__c> partnerOperationsSteps = (List<PartnerOperationsStep__c>)
            new QueryFactory(PartnerOperationsStep__c.SObjectType)
                .selectFields(new List<String> { 'Name', 'isCompleted__c', 'PartnerOperationsLog__r.Opportunity__c', 'PartnerOperationsLog__r.Approval__c' })
                .setQueryBindings(new List<Object>{ validateParams.logId })
                .setCondition('PartnerOperationsLog__c =:bind0')
                .executeQuery();

        PartnerOperationsStep__c requiredStep;
        for (PartnerOperationsStep__c step : partnerOperationsSteps) {
            if (step.Name == validateParams.name) {
                requiredStep = step;
            }
        }

        if (requiredStep == null) {
            res.error('Error', 'Step is not found!');
            return res;
        }

        // only for first step, since it's completed on opportunity creation
        if (requiredStep.isCompleted__c) {
            res.addMessage('Step is completed', 'success');
            return res;
        }

        switch on requiredStep.Name {
            when 'CREATE_WHOLESALE_OPPTY' {
                Boolean isValid = String.isNotBlank(requiredStep.PartnerOperationsLog__r.Opportunity__c);
                handleStep(res, requiredStep, isValid, 'create new Wholesale Opportunity first');
            }
            when 'CREATE_WHOLESALE_REQUEST' {
                Boolean isValid = String.isNotBlank(requiredStep.PartnerOperationsLog__r.Approval__c);
                handleStep(res, requiredStep, isValid, 'Create New Invoice-Wholesale Request first');
            }
            when 'APPROVE_WHOLESALE_REQUEST' {
                Approval__c approval = (Approval__c) new ListOptional(new ApprovalSelector()
                    .selectInvoicingApprovalsForAPCChange(requiredStep.PartnerOperationsLog__r.Approval__c)
                    .withoutSelectorFieldsIncluded()
                    .selectField(Approval__c.Status__c)
                    .executeQuery()
                ).getFirst();

                Boolean isValid = ApprovalHelper.STATUS_APPROVED.equalsIgnoreCase(approval.Status__c);
                handleStep(res, requiredStep, isValid, 'Approve Invoice-Wholesale Request');
            }
            when 'SYNC_WITH_NGBS' {
                Boolean isValid = Test.isRunningTest() || isCurrentSyncScenarioLastStepCompleted(requiredStep.PartnerOperationsLog__r.Opportunity__c);
                handleStep(res, requiredStep, isValid, 'complete SyncWithNGBS on Opportunity first');

                if (isValid) {
                    completePartnerOperation(validateParams.logId);
                }
            }
            when else {
                res.error('Error', 'Step is not found!');
            }
        }
        return res;
    }

    private static void handleStep(Response res, PartnerOperationsStep__c requiredStep, Boolean condition, String errorMesage) {
        if (condition) {
            requiredStep.isCompleted__c = true;
            update requiredStep;
            res.addMessage('Step is completed', 'success');
        } else {
            res.error('Error', 'Please ' + errorMesage);
        }
    }

    // Method works only for master quote and single product flow
    // Must be refactored for MPUB together with partner operation flow
    public static Boolean isCurrentSyncScenarioLastStepCompleted(Id opportunityId) {
        Opportunity opp = (Opportunity) new ListOptional(new OpportunitySelector()
            .selectOpportunityForSyncWithNGBS(opportunityId)
            .subselect(new QuoteSelector()
                .selectQuotes()
                .withoutSelectorFieldsIncluded()
                .setCondition('isPrimary__c = true AND IsMultiProductTechnicalQuote__c = false')
            )
            .executeQuery()
        ).getFirst();

        if (opp.Quotes.isEmpty()) {
            return false;
        }

        Quote qt = opp.Quotes[0];
        return isCurrentSyncScenarioLastStepCompleted(new SWNDataCollector(qt.Id, SettingsHelper.FEATURE_TOGGLE.EnableMultiProductUnifiedBilling__c));
    }

    public static Boolean isCurrentSyncScenarioLastStepCompleted(SWNDataCollector sdc) {
        String syncInfoField = sdc.syncable.getSyncInfoField();

        if (String.isBlank(syncInfoField)) {
            return false;
        }
        SWNSyncInfo syncInfo = (SWNSyncInfo) JSON.deserialize(syncInfoField, SWNSyncInfo.class);
        List<String> stepNames = syncInfo.stepNames;
        String lastStepName = stepNames.get(stepNames.size() - 1);
        return sdc.syncable.getBooleanFlagByStepName(lastStepName)
            || !isLastStepNotSynced(sdc, stepNames, lastStepName);
    }

    private static Boolean isLastStepNotSynced(SWNDataCollector sdc, List<String> steps, String lastStepName) {
        Response syncInfo = SWNSyncInfo.getStepsSyncInfo(sdc, steps);
        SWNStepInfo lastStepInfo = (SWNStepInfo) syncInfo.data.get(String.valueOf(lastStepName));
        return lastStepInfo.status == SWNHelper.NOT_SYNCED;
    }

    private static void completePartnerOperation(Id logId) {
        PartnerOperationsLog__c partnerOperationsLog = (PartnerOperationsLog__c)
        new QueryFactory(PartnerOperationsLog__c.SObjectType)
            .selectFields(new List<String> {'isCompleted__c'})
            .setCondition('Id =:bind0')
            .setQueryBindings(new List<Object>{new Set<Id>{logId}})
            .executeQuery()
            .get(0);
        partnerOperationsLog.isCompleted__c = true;
        update partnerOperationsLog;
    }

    @AuraEnabled
    public static Response downgradeOpportunity(Id oppId){
        Response result = new Response();

        Opportunity opp = (Opportunity) new OpportunitySelector()
            .selectOpportunitiesByIds(new Set<Id>{oppId})
            .executeQuery()
            .get(0);

        try {
            if (opp.StageName != OpportunityHelper.STAGE_NAME_CLOSED_WON){
                opp.StageName = OpportunityHelper.STAGE_NAME_DOWNGRADED;
                opp.Downgrade_Reason_Opp__c = 'Project deprioritized';
                update opp;
                result.addMessage('Opportunity is downgraded', 'success');
            } else {
                result.addMessage('Opportunity is closed won', 'success');
            }
        } catch (Exception e) {
            result.error(e.getTypeName(), e.getMessage());
        }
        return result;
    }

    @AuraEnabled
    public static Response recallApproval(Id approvalId){
        Response result = new Response();

        Approval__c approval = (Approval__c) new ApprovalSelector()
            .selectInvoicingApprovalsForAPCChange(approvalId)
            .executeQuery()
            .get(0);

        try {
            if (approval.Status__c != ApprovalHelper.STATUS_APPROVED){
                approval.Status__c = ApprovalHelper.STATUS_RECALLED;
                update approval;
                result.addMessage('Approval is recalled', 'success');
            } else {
                result.addMessage('Payment method was already updated, you cannot revert changes at this point', 'error');
            }
        } catch (Exception e) {
            result.error(e.getTypeName(), e.getMessage());
        }
        return result;
    }

    @AuraEnabled
    public static Response getWholesaleRecordTypeId() {
        Response res = new Response();
        res.setData('wholesaleRecordTypeId', String.valueOf(ApprovalHelper.RT_ID_INVOICE_WHOLESALE_REQUEST));
        return res;
    }

    @AuraEnabled
    public static Response rejectPartnerOperation(Id logId) {
        Response result = new Response();

        PartnerOperationsLog__c partnerOperationsLog = (PartnerOperationsLog__c)
            new QueryFactory(PartnerOperationsLog__c.SObjectType)
                .selectFields(new List<String> {'isRejected__c'})
                .setCondition('Id =:bind0')
                .setQueryBindings(new List<Object>{logId})
                .executeQuery()
                .get(0);

        try {
            partnerOperationsLog.isRejected__c = true;
            update partnerOperationsLog;
            result.addMessage('Partner Operations Log is rejected', 'success');
        } catch (Exception e) {
            result.error(e.getTypeName(), e.getMessage());
        }
        return result;
    }

    @AuraEnabled
    public static Response getDefaultFieldValues(BillingWrappers.ApprovalParams params){

        Response res = new Response();

        List<Approval__c> approvals = (List<Approval__c>) new ApprovalSelector()
        .selectInvoiceApprovalsForPayableInfo(new List<Object>{
            new List<Id>{ ApprovalHelper.RT_ID_INVOICING_REQUEST, ApprovalHelper.RT_ID_INVOICE_ON_BEHALF_REQUEST, ApprovalHelper.RT_ID_INVOICE_WHOLESALE_REQUEST },
            new Set<Id>{ params.accountId },
            new List<String>{ ApprovalHelper.STATUS_APPROVED }
        })
        .executeQuery();

        if (approvals.isEmpty()) {
            res.setData('defaultFieldValues', null);
            return res;
        }

        params.recordType = ApprovalHelper.RT_INFO_BY_ID.get(approvals[0].RecordTypeId).getName();

        List<ApprovalService.ApprovalDetails> approvalDetails = ApprovalService.getApprovalDetails(params);
        res.setData('defaultFieldValues', approvalDetails[0].defaultFieldValues);

        return res;
    }
}