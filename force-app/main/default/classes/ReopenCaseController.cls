public with sharing class ReopenCaseController {
    public Boolean isReopenable {get; set;}
    public Boolean hasBeenReopened {get; set;}
    public String function {get; set;}
    public List<SelectOption> functionValues {get; set;}
    public List<String> functionValuesString {get; set;}
    public String justification {get; set;}
    public String cannotBeReopenedReason {get; set;}

    public static final String HAS_BEEN_REOPENED = 'Case has been reopened.';
    public static final String INVALID_JUSTIFICATION_LENGTH = 'Justification field must be at least 50 characters and less than 2000 characters.';
    public static final String INVALID_FUNCTION_VALUE = 'Invalid value for Function field.';
    public static final String OTHER_REASON_STRING = 'Other reason';
    public static final Integer MIN_SIZE_JUSTIFICATION_PARAMETER = 50;
    public static final Integer MAX_SIZE_JUSTIFICATION_PARAMETER = 2000;

    Case caseRecord;

    public ReopenCaseController(ApexPages.StandardController controller) {
        caseRecord = (Case) new CaseSelector()
            .selectCaseForReopening(new Object[]{controller.getId()})
            .executeQuery()[0];
        isReopenable = CaseHelper.isReopenable(caseRecord);
        if (!isReopenable) {
            cannotBeReopenedReason = CaseHelper.getReopenErrorMessage(caseRecord);
        }
        functionValues = new List<SelectOption>();
        functionValuesString = CaseHelper.getFunctionValues();
        for (String functionValue : functionValuesString) {
            functionValues.add(new SelectOption(functionValue, functionValue));
        }
    }

    public PageReference reopenCase() {
        try {
            if (!isReopenable) {
                throw new HandledException(cannotBeReopenedReason);
            }

            function = function?.trim();
            justification = justification?.trim();

            reopenACase(function, justification, caseRecord);
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.CONFIRM, HAS_BEEN_REOPENED));
            hasBeenReopened = true;
        } catch(Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, e.getMessage()));
        }
        return null;
    }

    @AuraEnabled
    public static void reopenACase(String function, String justification, Case aCase) {
        try {

            if (!isJustificationFieldValid(function, justification)) {
                throw new HandledException(INVALID_JUSTIFICATION_LENGTH);
            }

            validateFunction(function);
            String commentBody = function + '\n\n' + justification;
            insertCaseComment(commentBody, aCase.Id);
            CaseReopenAPIController.updateStatusToReopen(aCase);
        } catch (Exception e) {
            AuraHandledException exc = new AuraHandledException(e.getMessage());
            exc.setMessage(e.getMessage());
            throw exc;
        }
    }
    
    public static void insertCaseComment(String body, String caseId) {
        insert new CaseComment(
            CommentBody = body,
            ParentId = caseId,
            isPublished = true
        );
    }

    public static boolean isJustificationFieldValid(String function, String justification) {
        List<String> otherReasonValues = new List<String>();
        
        for(SC_Translation__mdt mdtTranslation : SC_Translation__mdt.getAll().values()){
            if (mdtTranslation.Field__c == 'functionValues' && mdtTranslation.Value__c.equalsIgnoreCase('Other reason')) {
                otherReasonValues.add(mdtTranslation.Label__c);
            }
        }

        Boolean functionEqualsOtherReason = otherReasonValues.contains(function) || OTHER_REASON_STRING.equals(function);

        return (
            (!functionEqualsOtherReason) || (
                functionEqualsOtherReason
                && justification.length() >= MIN_SIZE_JUSTIFICATION_PARAMETER
                && justification.length() <= MAX_SIZE_JUSTIFICATION_PARAMETER
            )
        );
    }

    public static void validateFunction(String function) {
        List<String> functionValues = CaseHelper.getFunctionValues();
        List<String> translatedFunctionValues = new List<String>();
        
        for(SC_Translation__mdt mdtTranslation : SC_Translation__mdt.getAll().values()){
            if (mdtTranslation.Field__c == 'functionValues') {
                translatedFunctionValues.add(mdtTranslation.Label__c);
            }
        }

        if (!functionValues.contains(function) && !translatedFunctionValues.contains(function)) {
            throw new HandledException(INVALID_FUNCTION_VALUE + ' Valid values:' + functionValues + ', ' + translatedFunctionValues);
        }
    }
}