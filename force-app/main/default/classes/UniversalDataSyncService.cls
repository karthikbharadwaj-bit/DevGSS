@RestResource(urlMapping = '/universal-data-sync/v1')
global with sharing class UniversalDataSyncService {

    private static final Integer MAX_RECORDS = 200;
    private static final String DEFAULT_OPERATION = 'UPDATE';
    private static final Set<String> SUPPORTED_OPERATIONS = new Set<String>{ 'UPDATE', 'INSERT' };
    private static final List<String> DEFAULT_TRIGGER_FLAGS = new List<String>{ 'BY_PASS_BEFORE', 'BY_PASS_AFTER' };

    @HttpPost
    global static ResponseWrapper process() {
        RestRequest restRequest = RestContext.request;
        ResponseWrapper respWrapper = new ResponseWrapper();
        if (restRequest == null || restRequest.requestBody == null) {
            return respWrapper.fromException(new UniversalDataSyncException('Request body is required.'));
        }

        try {
            RequestWrapper requestWrapper = (RequestWrapper) JSON.deserialize(restRequest.requestBody.toString(), RequestWrapper.class);
            ResponseWrapper response = handleRequest(requestWrapper);
            RestContext.response.statusCode = response != null && response.success ? 200 : 207;
            return response;
        } catch (UniversalDataSyncException validationEx) {
            RestContext.response.statusCode = 400;
            return respWrapper.fromException(validationEx);
        } catch (Exception unexpectedEx) {
            RestContext.response.statusCode = 500;
            System.debug('--->>>' + unexpectedEx.getMessage());
            System.debug('--->>>' + unexpectedEx.getStackTraceString());
            return respWrapper.fromException(unexpectedEx);
        }
    }

    @TestVisible
    private static ResponseWrapper handleRequest(RequestWrapper requestWrapper) {
        validateRequest(requestWrapper);

        Type sType = Type.forName(requestWrapper.objectApiName);
        SObject obj = (SObject)sType.newInstance();
        Schema.SObjectType sobjectType = obj.getSObjectType();
        if (sobjectType == null) {
            throw new UniversalDataSyncException('Object ' + requestWrapper.objectApiName + ' is not recognized.');
        }

        Schema.DescribeSObjectResult describe = sobjectType.getDescribe();
        verifyObjectAccess(describe, requestWrapper.getOperation());

        try {
            List<SObject> records = requestWrapper.records;

            applyFieldLevelSecurity(records, requestWrapper.getOperation());

            if (requestWrapper.disableTriggers != null && requestWrapper.disableTriggers) {
                Triggers.switchOff();
                System.debug('UniversalDataSyncService :: Triggers switched off');
            }

            List<Database.SaveResult> dmlResults = performDml(records, requestWrapper);

            return buildResponse(true, null);
        } catch (UniversalDataSyncException dataSyncException) {
            RestContext.response.statusCode = 400;
            ResponseWrapper respWrapper = new ResponseWrapper();
            return respWrapper.fromException(dataSyncException);
        } finally {
            Triggers.switchOn();
        }
    }

    private static void validateRequest(RequestWrapper requestWrapper) {
        if (requestWrapper == null) {
            throw new UniversalDataSyncException('Request payload could not be parsed.');
        }

        if (String.isBlank(requestWrapper.objectApiName)) {
            throw new UniversalDataSyncException('objectApiName is required.');
        }

        String operation = requestWrapper.getOperation();
        if (!SUPPORTED_OPERATIONS.contains(operation)) {
            throw new UniversalDataSyncException('Unsupported operation ' + operation + '. Supported: ' + String.join(new List<String>(SUPPORTED_OPERATIONS), ', '));
        }

        if (requestWrapper.records == null || requestWrapper.records.isEmpty()) {
            throw new UniversalDataSyncException('At least one record payload is required.');
        }

        if (requestWrapper.records.size() > MAX_RECORDS) {
            throw new UniversalDataSyncException('A maximum of ' + MAX_RECORDS + ' records can be processed per request.');
        }
    }

    private static void verifyObjectAccess(Schema.DescribeSObjectResult describe, String operation) {
        if (!describe.isAccessible()) {
            throw new UniversalDataSyncException('You do not have access to object ' + describe.getName() + '.');
        }

        if (!describe.isUpdateable()) {
            throw new UniversalDataSyncException('You do not have update permission on ' + describe.getName() + '.');
        }

        if ('INSERT'.equals(operation) && !describe.isCreateable()) {
            throw new UniversalDataSyncException('You do not have create permission on ' + describe.getName() + ' required for INSERT.');
        }
    }

    private static void applyFieldLevelSecurity(List<SObject> records, String operation) {
        if (records == null || records.isEmpty()) {
            return;
        }

        System.Security.stripInaccessible(System.AccessType.UPDATABLE, records);

        if ('INSERT'.equals(operation)) {
            System.Security.stripInaccessible(System.AccessType.CREATABLE, records);
        }
    }

    private static List<Database.SaveResult> performDml(List<SObject> records, RequestWrapper requestWrapper) {
        Database.SaveResult[] results;
        if ('UPDATE'.equals(requestWrapper.getOperation())) {
            results = Database.update(records, requestWrapper.isAllOrNone());
        } else {
            results = Database.insert(records, requestWrapper.isAllOrNone());
        }

        return new List<Database.SaveResult>(results);
    }

    private static ResponseWrapper buildResponse(Boolean status, List<String> errors) {
        ResponseWrapper response = new ResponseWrapper();
        Boolean hasErrors = errors != null && !errors.isEmpty();
        if (hasErrors) {
            response.errors.addAll(errors);
        }
        response.success = !hasErrors;
        return response;
    }

    global class RequestWrapper {
        public String objectApiName;
        public String operation;
        public Boolean disableTriggers;
        public Boolean allOrNone;
        public List<SObject> records;

        public String getOperation() {
            return String.isBlank(operation) ? DEFAULT_OPERATION : operation.trim().toUpperCase();
        }

        public Boolean isAllOrNone() {
            return allOrNone != null && allOrNone;
        }
    }

    global class ResponseWrapper {
        public Boolean success;
        public List<String> errors = new List<String>();

        public ResponseWrapper fromException(Exception ex) {
            ResponseWrapper response = new ResponseWrapper();
            response.success = false;
            response.errors.add(ex != null ? ex.getMessage() : 'Unknown error.');
            return response;
        }
    }

    global class UniversalDataSyncException extends Exception {}
}