public with sharing class EscalateCaseController {
    public Boolean isEscalatable {get; set;}
    public Boolean hasBeenEscalated {get; set;}
    public String justification {get; set;}
    public String cannotBeEscalatedReason {get; set;}

    Case caseRecord;

    public static final Integer MIN_SIZE_JUSTIFICATION = 50;
    public static final Integer MAX_SIZE_JUSTIFICATION = 2000;

    public static final String JUSTIFICATION_TOO_SHORT = 'Justification must be at least ' + 
        MIN_SIZE_JUSTIFICATION + ' characters.';
    public static final String JUSTIFICATION_TOO_LONG = 'Justification must be less than ' + 
        MAX_SIZE_JUSTIFICATION +' characters.';
    public static final String CASE_HAS_BEEN_ESCALATED = 'Case has been escalated.';

    private Pagereference viewPageReference;

    public EscalateCaseController(ApexPages.StandardController controller) {
        viewPageReference = controller.view();
        caseRecord = (Case) new CaseSelector()
            .selectCaseForEscalating(new Object[]{controller.getId()})
            .executeQuery()[0];
        isEscalatable = CaseHelper.isEscalatable(caseRecord);
        if(!isEscalatable) {
            cannotBeEscalatedReason = CaseHelper.getEscalateErrorMessage(caseRecord);
        }
    }

    public PageReference escalateCase() {
        try {
            justification = justification?.trim();

            if (!isEscalatable) {
                throw new HandledException(cannotBeEscalatedReason);
            }

            escalateACase(justification, caseRecord);

            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.CONFIRM, CASE_HAS_BEEN_ESCALATED));
            hasBeenEscalated = true;
        } catch(Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, e.getMessage()));
        }
        return null;
    }

    @AuraEnabled
    public static void escalateACase(String justification, Case caseRecord){
        try {
            validateJustification(justification);

            insert new CaseComment (
                ParentId = caseRecord.Id,
                CommentBody = justification,
                isPublished = true
            );
            caseRecord.isEscalated = true;
            update caseRecord;
        } catch (Exception e) {
            AuraHandledException exc = new AuraHandledException(e.getMessage());
            exc.setMessage(e.getMessage());
            throw exc;
        }
    }

    public static void validateJustification(String justification) {
        if (justification.length() < MIN_SIZE_JUSTIFICATION) {
            throw new HandledException(JUSTIFICATION_TOO_SHORT);
        } 
        if (justification.length() > MAX_SIZE_JUSTIFICATION) {
            throw new HandledException(JUSTIFICATION_TOO_LONG);
        }
    }
}