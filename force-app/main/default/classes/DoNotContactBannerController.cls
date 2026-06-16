public class DoNotContactBannerController {
   
    @AuraEnabled(cacheable=true)
    public static Account getAccount(String recordId) {
        return [
            SELECT Partner_Account__c, Partner_Account__r.Name,PartnerAccountDoNotContact__c
            FROM Account 
            WHERE Id = :recordId
            LIMIT 1
        ];
    }
}