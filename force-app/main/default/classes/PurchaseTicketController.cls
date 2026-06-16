public class PurchaseTicketController{
	public PurchaseTicketController() {}

    public Case caseObj {get; set;}
    public String newPurchaseSubject {get;set;}
 	public String newPurchaseDate {get;set;}
    public String newPurchaseDescription {get;set;}
    
    /********************************************* Method to submit Purchase Ticket Cases ****************************************/
    public PageReference createNewPurchase() {
        try {
            User userObj = (User) new ListOptional(new UserSelector()
                .selectUserByIdForNewCase(new List<Object> { new Set<Id> { UserInfo.getUserId() } })
                .executeQuery()
            ).getFirst();

            User activeUserByNameAndProfile = (User) new ListOptional(new UserSelector()
                .selectActiveUserByNameAndProfile(new List<Object> {
                    new Set<String> { 'RC Support Agent' },
                    new Set<String> { ProfileHelper.SYSTEM_ADMIN }
                })
                .executeQuery()
            ).getFirst();

            caseObj = (Case) new SObjectBuilder(Case.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Case.RecordTypeId => CaseHelper.RT_ID_IT_HELPDESK,
                    Case.ContactId => userObj.ContactId,
                    Case.AccountId => userObj.Contact.AccountId,
                    Case.Status => CaseHelper.CASE_STATUS_NEW,
                    Case.Subject => newPurchaseSubject,
                    Case.Request_Type__c => 'Procurement',
                    Case.Description => newPurchaseDescription,
                    Case.OwnerId => activeUserByNameAndProfile.Id,
                    Case.Origin => CaseHelper.CASE_ORIGIN_WEB
                })
                .create()
                .getRecord();

            PageReference returnPage = new PageReference('/helpdesk/' + caseObj.Id); 
            returnPage.setRedirect(true);
            return returnPage;
         } catch (Exception e) {
            PlatformLog.logException('Error PurchaseTicketController', e);
         }
        return null;
    }
}