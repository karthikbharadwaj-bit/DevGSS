public class SyncWithNGBSQueueable implements Queueable, Database.AllowsCallouts {
    private static final String ERROR_UPON_ORDER_ACTIVATION = 'An error has occurred upon activating order for Opportunity';
    private static final String ERROR_UPON_SERVICE_INFO_UPDATING = 'An error has occurred upon updating Service Info';
    private static final String ERROR_UPON_CREARING_CASE_DESCRIPTION = 'An error has occured upon creating case description';
    @TestVisible
    private static final String ERROR_UPON_GETTING_SYNC_SCENARIO = 'An error has occured upon getting Sync scenarios';
    @TestVisible
    private static final String ERROR_UPON_SYNCING_ENTITLEMENTS = 'An error has occured upon syncing Entitlements';
    private static final String ERROR_UPON_SYNCING_WITH_NGBS = 'An error has occured upon syncing with NGBS';
    private static final String ERROR_UPON_SYNCING_STEP = 'An error has occured upon syncing the following step with NGBS: {0}';
    private static final String ERROR_UPON_SYNC_VALIDATION = 'An error has occured upon Process Order validation';
    private static final String ERROR_UPON_SYNC_PREPARATION = 'An error has occured upon preparation for Process Order';
    private static final String NO_STEPS_FOUND = 'No steps found for Quote Id - {0}';

    private Id quoteId;
    @TestVisible
    private List<String> stepNames;
    @TestVisible
    private static String error;
    @TestVisible
    private static List<String> notSyncedStepNames;
    @TestVisible
    private static Response res = new Response();

    private static String step {
        get {
            if (notSyncedStepNames.isEmpty()) {
                return null;
            }
            return notSyncedStepNames.get(0);
        }
    }

    @TestVisible
    private SyncWithNGBSQueueable(Id quoteId, List<String> stepNames) {
        this.stepNames = stepNames;
        this.quoteId = quoteId;
    }

    public void execute(QueueableContext context) {
        try {
            initializeSyncScenario(quoteId, stepNames);
            if (res.isError()) {
                return;
            }

            getNotSyncedStepNames(quoteId, stepNames);

            if (step == null) {
                return;
            }

            res = SyncWithNGBS.syncWithNGBS_v3(quoteId, step);

            if (!Test.isRunningTest()) {
                enqueueNextStep(quoteId);
            }

            if (res.isError()) {
                return;
            }

            if (step == null) {
                updateServiceInfoAfterSync(quoteId);
                activateOrderForOpportunity(quoteId);
            }
        } catch (Exception ex) {
            String errorDetails = ex.getMessage() + ' ' + ex.getStackTraceString();
            logErrorsIntoMultipleSources(quoteId, ERROR_UPON_SYNCING_WITH_NGBS, errorDetails);
        }
    }

    // The inner Queueable class to handle async execution of SyncWithNGBS.validateSyncWithNGBS method from Case trigger which has callouts inside.
    // Avoid adding any logic related with DML operations here.
    public class ValidateAndProceedSyncQueueable implements Queueable, Database.AllowsCallouts {
        private Id quoteId;

        private ValidateAndProceedSyncQueueable(Id quoteId) {
            this.quoteId = quoteId;
        }

        public void execute(QueueableContext context) {
            try {
                validateAndProceedSync(quoteId);
            } catch (Exception ex) {
                String errorDetails = ex.getMessage() + ' ' + ex.getStackTraceString();
                logErrorsIntoMultipleSources(quoteId, ERROR_UPON_SYNC_PREPARATION, errorDetails);
            }
        }

        private void validateAndProceedSync(Id quoteId) {
            error = SWNHelper.validateSyncWithNGBS(quoteId, true).remove('[]');
            if (String.isNotBlank(error)) {
                handleValidationErrors(quoteId, error);
                return;
            }

            if (!Test.isRunningTest()) {
                System.enqueueJob(new CreateDealDeskCaseDescriptionAndProceedSyncQueueable(quoteId));
            }
        }

        private void handleValidationErrors(Id quoteId, String errors) {
            List<Response.ResponseMessage> errorMessages = (List<Response.ResponseMessage>) JSON.deserialize(errors, List<Response.ResponseMessage>.class);

            logErrorsIntoMultipleSources(
                quoteId,
                ERROR_UPON_SYNC_VALIDATION,
                parseErrorMessages(errorMessages)
            );
        }
    }

    public class CreateDealDeskCaseDescriptionAndProceedSyncQueueable implements Queueable, Database.AllowsCallouts {
        private Id quoteId;
        @TestVisible
        private CreateDealDeskCaseDescriptionAndProceedSyncQueueable(Id quoteId) {
            this.quoteId = quoteId;
        }

        public void execute(QueueableContext context) {
            try {
                createDealDeskCaseDescriptionAndProceedSync(quoteId);
            } catch (Exception ex) {
                String errorDetails = ex.getMessage() + ' ' + ex.getStackTraceString();
                logErrorsIntoMultipleSources(quoteId, ERROR_UPON_CREARING_CASE_DESCRIPTION, errorDetails);
            }
        }

        private void createDealDeskCaseDescriptionAndProceedSync(Id quoteId) {
            res = SyncWithNGBS.createDealDeskCaseDescriptions(quoteId);
            if (res.isError()) {
                logErrorsIntoMultipleSources(
                    quoteId,
                    ERROR_UPON_CREARING_CASE_DESCRIPTION,
                    parseErrorMessages(res.messages)
                );
                return;
            }

            if (!Test.isRunningTest()) {
                System.enqueueJob(new SyncEntitlementsAndProceedSyncQueueable(quoteId));
            }
        }
    }

    // The inner Queueable class was added to handle async execution of SyncWithNGBS.syncEntitlements method which has callouts inside.
    // Avoid adding any logic related with DML operations here.
    public class SyncEntitlementsAndProceedSyncQueueable implements Queueable, Database.AllowsCallouts {
        private Id quoteId;
        @TestVisible
        private SyncEntitlementsAndProceedSyncQueueable(Id quoteId) {
            this.quoteId = quoteId;
        }

        public void execute(QueueableContext context) {
            try {
                syncEntitlementsAndProceedSync(quoteId);
            } catch (Exception ex) {
                String errorDetails = ex.getMessage() + ' ' + ex.getStackTraceString();
                logErrorsIntoMultipleSources(quoteId, ERROR_UPON_SYNCING_ENTITLEMENTS, errorDetails);
            }
        }

        private void syncEntitlementsAndProceedSync(Id quoteId) {
            res = SyncWithNGBS.syncEntitlements(quoteId);
            if (res.isError()) {
                logErrorsIntoMultipleSources(
                    quoteId,
                    ERROR_UPON_SYNCING_ENTITLEMENTS,
                    parseErrorMessages(res.messages)
                );
                return;
            }

            if (!Test.isRunningTest()) {
                System.enqueueJob(new SyncWithNGBSQueueable(quoteId, new List<String>()));
            }
        }
    }

    // SyncWithNGBSQueueable class can be executed only via this method
    public static void enqueueAutoSyncWithNGBS(Id quoteId) {
        System.enqueueJob(new ValidateAndProceedSyncQueueable(quoteId));
    }

    @TestVisible
    private static void enqueueNextStep(Id quoteId) {
        if (res.isSuccess()) {
            notSyncedStepNames.remove(0);
            if (step != null) {
                System.enqueueJob(new SyncWithNGBSQueueable(quoteId, notSyncedStepNames));
            }
        } else {
            logErrorsIntoMultipleSources(
                quoteId,
                String.format(ERROR_UPON_SYNCING_STEP, new List<Object> {step}),
                parseErrorMessages(res.messages)
            );
            res.error();
        }
    }

    @TestVisible
    private static void initializeSyncScenario(Id quoteId, List<String> stepNames) {
        if (stepNames != null && !stepNames.isEmpty()) {
            return;
        }

        res = SyncWithNGBS.getSyncScenario(quoteId);
        if (res.isError()) {
            logErrorsIntoMultipleSources(
                quoteId,
                ERROR_UPON_GETTING_SYNC_SCENARIO,
                parseErrorMessages(res.messages)
            );
            return;
        }

        SWNScenarioHelper.Scenario sc = (SWNScenarioHelper.Scenario) res.data.get(SWNScenarioHelper.SCENARIO);
        if (sc.stepNames.isEmpty()) {
            String errorDetails = String.format(NO_STEPS_FOUND, new List<Object> {quoteId});
            logErrorsIntoMultipleSources(quoteId, ERROR_UPON_GETTING_SYNC_SCENARIO, errorDetails);
            res.error();
        }

        stepNames.addAll(sc.stepNames);
    }

    private static void createChatterPost(Id quoteId, String message, String additionalDetails) {
        if (String.isBlank(quoteId)) {
            return;
        }
        Opportunity opportunity = getOpportunityByQuoteId(quoteId);
        Opportunity masterOpp = opportunity.isMultiproductTechnicalOpportunity__c ? opportunity.MasterOpportunity__r : opportunity;
        Id userIdToNotify = !String.isEmpty(masterOpp.Order_Management_Owner__c)
            ? masterOpp.Order_Management_Owner__c
            : masterOpp.OwnerId;
        ChatterHelper.createChatterPost(
            userIdToNotify,
            masterOpp.Id,
            message,
            additionalDetails
        );
    }

    private static void logResult(String errorDetails, String message) {
        PlatformLog.logResult(SyncWithNGBSQueueable.class.getName(), message, errorDetails, null, null, false);
    }

    @TestVisible
    private static void getNotSyncedStepNames(Id quoteId, List<String> stepNames) {
        Response syncInfoResponse = SyncWithNGBS.getSyncInfo(quoteId, stepNames);
        notSyncedStepNames = new List<String>();
        for (String stepName : stepNames) {
            SWNStepInfo syncInfo = (SWNStepInfo) syncInfoResponse.data.get(String.valueOf(stepName));
            if (SWNHelper.NOT_SYNCED.equalsIgnoreCase(syncInfo.status)) {
                notSyncedStepNames.add(stepName);
            }
        }
    }

    private static Opportunity getOpportunityByQuoteId(Id quoteId) {
        return (Opportunity) new ListOptional(new OpportunitySelector()
                .selectOpportunitiesForSyncWithNGBSByQuoteIds(new Set<Id> {quoteId})
                .withoutSelectorFieldsIncluded()
                .selectFields(new List<String> {
                    'Id',
                    'OwnerId',
                    'isMultiproductTechnicalOpportunity__c',
                    'MasterOpportunity__c',
                    'MasterOpportunity__r.OwnerId',
                    'MasterOpportunity__r.Order_Management_Owner__c',
                    'Order_Management_Owner__c'
                })
                .setQueryCaching(true)
                .executeQuery()
            )
            .getFirst();
    }

    private static void updateServiceInfoAfterSync(Id quoteId) {
        try {
            QuoteHelper.updateServiceInfoAfterSync(quoteId);
        } catch (Exception ex) {
            String errorDetails = ex.getMessage() + ' ' + ex.getStackTraceString();
            logErrorsIntoMultipleSources(quoteId, ERROR_UPON_SERVICE_INFO_UPDATING, errorDetails);
        }
    }

    private static void activateOrderForOpportunity(Id quoteId) {
        try {
            OrderHelper.activateOrderForOpportunity(quoteId);
        } catch (Exception ex) {
            String errorDetails = ex.getMessage() + ' ' + ex.getStackTraceString();
            logErrorsIntoMultipleSources(quoteId, ERROR_UPON_ORDER_ACTIVATION, errorDetails);
        }
    }

    private static void logErrorsIntoMultipleSources(Id quoteId, String message, String errorDetails) {
        logResult(errorDetails, message);
        createChatterPost(quoteId, message, errorDetails);
    }

    private static String parseErrorMessages(List<Response.ResponseMessage> errorMessages) {
        List<String> errorDetails = new List<String>();
        for (Response.ResponseMessage error : errorMessages) {
            errorDetails.add(error.messageDetails);
        }
        return String.join(errorDetails, ', ');
    }
}