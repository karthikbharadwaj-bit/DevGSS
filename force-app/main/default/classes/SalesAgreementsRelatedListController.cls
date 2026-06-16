/**
 * Controller for Quotes Related list on Opportunity and Account
 */
public class SalesAgreementsRelatedListController {
    public List<Quote> quotes { get; set; }

    private sObject currentSobj;

    /**
     * Constructor method
     * @param stdController
     */
    public SalesAgreementsRelatedListController(ApexPages.StandardController stdController) {
        currentSobj = (sObject) stdController.getRecord();
        getQuotes();
    }

    /**
     * Get Quotes to display
     */
    public Void getQuotes(){
        quotes = new List<Quote>();
        CustomPermissionHelper cp = new CustomPermissionHelper();

        List<Quote> allQuotes = [
                SELECT Id, Name, QuoteNumber, Status, First_Year_Cost_of_Service__c, First_Year_Discount__c,
                        RecordTypeId, ProServ_Sold_Date__c
                FROM Quote
                WHERE AccountId = :currentSobj.Id
                OR OpportunityId = :currentSobj.Id
        ];

        for (Quote q : allQuotes){
            //Check if user has permission to display this type of quote
            if ( !(q.RecordTypeId == QuoteHelper.RT_ID_PROSERV && !cp.hasPermission(CustomPermissionHelper.PERMISSION_SEEPROSERVQUOTE))
              && !(q.RecordTypeId == QuoteHelper.RT_ID_CC_PROSERV && !cp.hasPermission(CustomPermissionHelper.PERMISSION_SEECCPROSERVQUOTE))) {
                quotes.add(q);
            }

        }
    }
}