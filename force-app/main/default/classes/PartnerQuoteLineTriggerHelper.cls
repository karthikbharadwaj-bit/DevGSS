//Ankit Sharma 	12/14/2020	update total reccurring or one time payment on PartnerQuote when any quoteline insert or update..
public class PartnerQuoteLineTriggerHelper {
    public static void calculateQuoteTotalPrice(List<Partner_Quote_Line__c> partnerQuoteLineList) {
        Set<String> setOfQuoteId = new  Set<String>();
        List<Partner_Quote__c> listOfQuoteToUpdate = new  List<Partner_Quote__c>();
        for(Partner_Quote_Line__c objLine : partnerQuoteLineList) {
            if(objLine.Partner_Quote__c != null) {
                setOfQuoteId.add(objLine.Partner_Quote__c);
            }
        }
        
        for(Partner_Quote__c objQuote : [SELECT Id,One_Time_Payment__c,Total_Recurring_Payment__c,
                                         (SELECT Id,Total_Price__c,Product_Catalogue__r.Plan__c 
                                          	FROM Partner_Quote_Products__r) FROM Partner_Quote__c 
                                         	WHERE Id IN :setOfQuoteId
                                            AND Integration_Quote__c = true]) {
             decimal oneTimeTotal = 0;
             decimal recurringTotal = 0;                                  
             for(Partner_Quote_Line__c objLine : objQuote.Partner_Quote_Products__r) {
                 if(objLine.Product_Catalogue__r.Plan__c == 'One - Time' && objLine.Total_Price__c != null) {
                     oneTimeTotal += objLine.Total_Price__c;
                 } else if(objLine.Total_Price__c != null) {
                     recurringTotal += objLine.Total_Price__c;
                 }                               
             
             }                             
            
             objQuote.Total_Recurring_Payment__c = recurringTotal;
             objQuote.One_Time_Payment__c = oneTimeTotal;                                  
             listOfQuoteToUpdate.add(objQuote);                                   
        }
        
        if(!listOfQuoteToUpdate.isEmpty()) {
            update listOfQuoteToUpdate;
        }
    }
}