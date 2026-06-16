@RestResource(UrlMapping='/rccc/nic/account/migrate')
global with sharing class CCMigrationAccountSvc {
    public static final String BAD_REQUEST_MESSAGE = 'HTTP error - Bad request';
    public static final String INCORRECT_REQUEST_BODY = 'Incorrect request body';
    public static final String ACCOUNT_NOT_MARKED_AS_MIGRATION = 'This Account is not marked for migration';
    public static final String ACCOUNT_HAS_BEEN_MIGRATED = 'This Account has already been migrated';
    public static final String NOT_MIGRATION_ACCOUNT_STATUS = 'Account not in Migration status';
    public static final String MIGRATE_TYPE = 'MIGRATE';
    public static final String ROLLBACK_TYPE = 'ROLLBACK';
    public static final String FINISH_TYPE = 'FINISH';
    public static final List<String> PARAM_TYPES = new List<String> {MIGRATE_TYPE, ROLLBACK_TYPE, FINISH_TYPE};

    @TestVisible
    private static final String ACCOUNT_MIGRATION_SERVICE_CLASS_NAME = 'CCMigrationAccountSvc';

    class CCMigrationAccountException extends Exception {
        List<ResponseMessage> messages;

        public CCMigrationAccountException(List<ResponseMessage> messages) {
            this.messages = messages;
        }

        override public String getMessage() {
            return generateErrorMessage(this.messages[0].message, this.messages[0].messageDetails);
        }
    }

    public class RequestParams {
        public String type;
        public String rcEnterpriseAccountId;
    }

    public class ResponseParams {
        public String status;
        public List<ResponseMessage> messages;
        public ResponseData data;

        public ResponseParams() {
            this.status = Response.STATUS_SUCCESS;
        }

        public ResponseParams(ResponseData data) {
            this.status = Response.STATUS_SUCCESS;
            this.data = data;
        }

        public ResponseParams(String status, List<ResponseMessage> messages) {
            this.status = status;
            this.messages = messages;
        }
    }

    public class ResponseMessage {
        public String severity;
        public String message;
        public String messageDetails;

        public ResponseMessage(String severity, String message, String messageDetails) {
            this.severity = severity;
            this.message = message;
            this.messageDetails = messageDetails;
        }
    }

    public class ResponseData {
        public String rcccEnterpriseAccountId;
        public String rcccSFDCAccountId;

        public ResponseData(String rcccEnterpriseAccountId, String rcccSFDCAccountId) {
            this.rcccEnterpriseAccountId = rcccEnterpriseAccountId;
            this.rcccSFDCAccountId = rcccSFDCAccountId;
        }
    }

    public class ValidationResult {
        public Account masterAccount;
        public ResponseMessage responseMessage;

        public ValidationResult() {
            this.responseMessage = new ResponseMessage(
                Response.SEVERITY_ERROR,
                BAD_REQUEST_MESSAGE,
                INCORRECT_REQUEST_BODY
            );
        }

        public ValidationResult(Account masterAccount) {
            this.masterAccount = masterAccount;
        }
    }

    @HttpPost
    global static void doPost() {
        String body = RestContext.request.requestBody.toString();

        if (RestContext.response == null) {
            RestContext.response = new RestResponse();
        }
        Savepoint savePoint = Database.setSavepoint();
        try {
            RequestParams params = (RequestParams) JSON.deserialize(body, RequestParams.class);
            setResponseBody(handleRequest(params));
        } catch (CCMigrationAccountException ex) {
            handleException(ex, ex.messages);
        } catch (JSONException ex) {
            handleException(ex, createErrorResponse(IcbHelper.WRONG_JSON_FORMAT, ex.getMessage() + ex.getStackTraceString()));
        } catch (Exception ex) {
            Database.rollback(savePoint);
            handleException(ex, createErrorResponse(ex.getMessage(), ex.getStackTraceString()));
        }
    }

    private static List<Account> getAccounts(String rcUserId) {
        return (List<Account>) new AccountSelector()
            .selectAccountsByUserIds(new List<Object>{new List<String>{rcUserId}})
            .executeQuery();
    }

    private static void setResponseBody(ResponseParams params) {
        System.debug('Response body: ' + params);
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(params, true));
    }

    private static List<ResponseMessage> createErrorResponse(String message, String messageDetails) {
        return new List<ResponseMessage>{
            new ResponseMessage(
                Response.SEVERITY_ERROR,
                message,
                messageDetails
            )
        };
    }

    private static List<ResponseMessage> createErrorResponse() {
        return new List<ResponseMessage>{
            new ResponseMessage(
                Response.SEVERITY_ERROR,
                BAD_REQUEST_MESSAGE,
                NOT_MIGRATION_ACCOUNT_STATUS
            )
        };
    }

    public static ResponseParams handleRequest(RequestParams params) {
        ValidationResult result = validateRequest(params);
        if (result.responseMessage != null) {
            throw new CCMigrationAccountException(new List<ResponseMessage> {result.responseMessage});
        }

        Account masterAccount = result.masterAccount;

        return getResponse(params, masterAccount);
    }

    private static ValidationResult validateRequest(RequestParams params) {
        if (!PARAM_TYPES.contains(params.type) || String.isBlank(params.rcEnterpriseAccountId)) {
            return new ValidationResult();
        }

        List<Account> accounts = getAccounts(params.rcEnterpriseAccountId);
        return accounts.isEmpty() ? new ValidationResult() : new ValidationResult(accounts.get(0));
    }

    @TestVisible
    private static ResponseParams handleMigrate(Account masterAccount) {
        Account existingCCTechnicalAccount = getTechAccount(masterAccount);
        if (existingCCTechnicalAccount != null && AccountHelper.ACCOUNT_MIGRATION_IN_PROGRESS_TYPES.contains(masterAccount.AccMigrationFlag__c)) {
            return new ResponseParams(new ResponseData(existingCCTechnicalAccount.RC_User_ID__c, existingCCTechnicalAccount.Id));
        } else if (existingCCTechnicalAccount == null && AccountHelper.ACCOUNT_MIGRATION_SCHEDULED_TYPES.contains(masterAccount.AccMigrationFlag__c)) {
            Map<String, Account> technicalAccountsMap = AccountHelper.createTechnicalAccounts(
                masterAccount,
                new List<String>{AccountHelper.SERVICE_TYPE_RCCC}
            );

            String enterpriseAccId = AccountHelper.generateEnterpriseAccountId();
            Account technicalAccount = technicalAccountsMap.values().get(0);
            technicalAccount.Internal_Enterprise_Account_ID__c = technicalAccount.RC_User_ID__c = enterpriseAccId;

            final String migrationStatus = isUpsellAllowedDuringMigration(masterAccount)
                                     ? AccountHelper.ACCOUNT_MIGRATION_TYPE_IN_PROGRESS
                                     : AccountHelper.ACCOUNT_MIGRATION_TYPE_IN_PROGRESS_BLOCKED;
            masterAccount.AccMigrationFlag__c = technicalAccount.AccMigrationFlag__c = migrationStatus;
            updateAccounts(masterAccount, technicalAccount);

            return new ResponseParams(new ResponseData(enterpriseAccId, technicalAccount.Id));
        } else {
            throw new CCMigrationAccountException(
                createErrorResponse(
                    BAD_REQUEST_MESSAGE,
                    ACCOUNT_NOT_MARKED_AS_MIGRATION
                )
            );
        }
    }

    private static ResponseParams handleRollback(Account masterAccount) {
        if (String.isBlank(masterAccount.AccMigrationFlag__c)) {
            return new ResponseParams();
        }

        Account techAccount = getTechAccount(masterAccount);
        if (techAccount == null) {
            return new ResponseParams();
        }

        if (isAccountNotMigrating(masterAccount, techAccount)) {
            throw new CCMigrationAccountException(
                createErrorResponse()
            );
        }

        techAccount.AccMigrationFlag__c = AccountHelper.ACCOUNT_MIGRATION_TYPE_ROLLBACKED;
        masterAccount.AccMigrationFlag__c = null;
        techAccount.Master_Account__c = null;
        updateAccounts(techAccount, masterAccount);

        List<SObject> instancesToDelete = new List<SObject>();
        for (Opportunity opp : (List<Opportunity>) new OpportunitySelector()
                .selectOpportunityByAccountIdForCCMigration(techAccount.Id)
                .executeQuery())
        {
            instancesToDelete.add(opp);
            instancesToDelete.addAll(opp.Orders);
            instancesToDelete.addAll(opp.Approvals__r);
        }

        if (instancesToDelete.size() > 0) {
            delete instancesToDelete;
        }

        return new ResponseParams();
    }

    private static ResponseParams handleFinish(Account masterAccount) {
        Account technicalAccount = getTechAccount(masterAccount);
        if (technicalAccount == null) {
            throw new CCMigrationAccountException(
                createErrorResponse()
            );
        }
        if (AccountHelper.ACCOUNT_MIGRATION_TYPE_MIGRATED.equalsIgnoreCase(masterAccount.AccMigrationFlag__c)
            && AccountHelper.ACCOUNT_MIGRATION_TYPE_MIGRATED.equalsIgnoreCase(technicalAccount.AccMigrationFlag__c)
        ) {
            return new ResponseParams();
        }

        if (isAccountNotMigrating(masterAccount, technicalAccount)) {
            throw new CCMigrationAccountException(
                createErrorResponse()
            );
        }
        masterAccount.AccMigrationFlag__c = technicalAccount.AccMigrationFlag__c = AccountHelper.ACCOUNT_MIGRATION_TYPE_MIGRATED;
        List<SObject> instancesToUpdate = new List<SObject>();
        instancesToUpdate.addAll(new List<SObject> {technicalAccount, masterAccount});

        for (Opportunity opp : (List<Opportunity>) new OpportunitySelector()
                .selectRenewalOpportunitiesDowngradedByMigration(new List<String> {masterAccount.Id, technicalAccount.Id})
                .executeQuery()
        ) {
            instancesToUpdate.add(OpportunityHelper.createRenewalOppty(opp.Account, getRenewalOpptyOwnerId(opp.Account)));
        }

        for (Order order : (List<Order>) new OrderSelector()
                .selectMigratedOrdersByAccountIds(technicalAccount.Id)
                .executeQuery()) {
            order.Status = OrderHelper.STATUS_ACTIVATED;
            instancesToUpdate.add(order);
        }

        upsert instancesToUpdate;

        return new ResponseParams();
    }

    private static Account getTechAccount(Account masterAccount) {
        return (Account) new ListOptional(
            new AccountSelector()
                .newQueryFactory()
                .setFactoryName('getTechAccount')
                .setQueryBindings(new List<Object> { masterAccount.Id, AccountHelper.SERVICE_TYPE_ENGAGE_VOICE })
                .withoutSelectorFieldsIncluded()
                .selectFields(
                    new Set<SObjectField> {
                        Account.Id,
                        Account.AccMigrationFlag__c,
                        Account.RC_User_ID__c
                    }
                )
                .setCondition('IsMultiProductTechnicalAccount__c = true AND Master_Account__c = :bind0 AND Service_Type__c != :bind1')
                .executeQuery()
        ).getFirst();
    }

    private static ResponseParams getResponse(RequestParams params, Account masterAccount) {
        switch on params.type {
            when 'MIGRATE' {
                return handleMigrate(masterAccount);
            }
            when 'ROLLBACK' {
                return handleRollback(masterAccount);
            }
            when 'FINISH' {
                return handleFinish(masterAccount);
            }
            when else {
                throw new CCMigrationAccountException(
                    createErrorResponse(
                        BAD_REQUEST_MESSAGE,
                        INCORRECT_REQUEST_BODY
                    )
                );
            }
        }
    }

    private static void updateAccounts(Account accFirst, Account accSecond) {
        Triggers.switchOff();
        update new List<Account> {accFirst, accSecond};
        Triggers.switchOn();
    }

    private static Boolean isAccountNotMigrating(Account masterAccount, Account technicalAccount) {
        return !AccountHelper.ACCOUNT_MIGRATION_IN_PROGRESS_TYPES.contains(masterAccount.AccMigrationFlag__c)
            || !AccountHelper.ACCOUNT_MIGRATION_IN_PROGRESS_TYPES.contains(technicalAccount.AccMigrationFlag__c);
    }

    private static Boolean isUpsellAllowedDuringMigration(Account masterAccount) {
        return AccountHelper.ACCOUNT_MIGRATION_TYPE_SCHEDULED.equalsIgnoreCase(masterAccount.AccMigrationFlag__c);
    }

    private static void handleException(Exception ex, List<ResponseMessage> messages) {
        PlatformLog.logException(ACCOUNT_MIGRATION_SERVICE_CLASS_NAME, ex);
        setResponseBody(new ResponseParams(Response.STATUS_ERROR, messages));
    }

    @TestVisible
    private static String generateErrorMessage(String message, String details) {
        return String.format('Message: {0} - Details: {1}', new List<String> {message, details});
    }

    private static String getRenewalOpptyOwnerId(Account acc) {
        List<OpportunityRenewalSettings__c> settings = OpportunityRenewalSettings__c.getall().values();
        for (OpportunityRenewalSettings__c settingRecord : settings) {

            List<String> recordBrands = settingRecord.BrandsForRenewal__c.split(';');
            if (recordBrands.contains(acc.RC_Brand__c)) {
               return settingRecord.DefaultOwnerId__c;
            }
        }

        return settings[0].DefaultOwnerId__c;
    }
}