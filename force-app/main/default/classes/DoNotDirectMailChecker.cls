// Apex class that checks the "Do_Not_Direct_Mail__c" field on any record dynamically
public with sharing class DoNotDirectMailChecker {

    // Inner class used to return results to Lightning components (LWC/Aura)
    public class Result {
        @AuraEnabled public Boolean doNotDirectMail; // Holds the value of the Do_Not_Direct_Mail__c field
        @AuraEnabled public String objectApiName;   // Holds the API name of the SObject (e.g., Lead, Contact)
        
        // Constructor that initializes both variables
        public Result(Boolean v, String n) { 
            doNotDirectMail = v; 
            objectApiName = n; 
        }
    }

    // Exposed to LWC/Aura components to fetch the "Do_Not_Direct_Mail__c" value for a given record
    @AuraEnabled(cacheable=false) // Not cacheable because it queries live record data
    public static Result getDoNotDirectMail(Id recordId) {
        // Ensure the recordId parameter is provided, otherwise throw an error to the UI
        if (recordId == null){ 
            throw new AuraHandledException('recordId is required');
        }
        // Determine the SObject type (e.g., Lead, Contact) based on the given recordId
        Schema.SObjectType sType = recordId.getSObjectType();
        String apiName = String.valueOf(sType);

        // Get metadata description of the SObject to check if field exists
        Schema.DescribeSObjectResult d = sType.getDescribe();

        // If the object does not have "Do_Not_Direct_Mail__c" field, return null result
        if (!d.fields.getMap().containsKey('Do_Not_Direct_Mail__c')) {
            return new Result(null, apiName);
        }
        // Query the record dynamically to get the Do_Not_Direct_Mail__c field value
        SObject sobj = Database.query('SELECT Do_Not_Direct_Mail__c FROM ' + apiName + ' WHERE Id = :recordId');

        // Return the field value and object API name as a Result object
        return new Result((Boolean)sobj.get('Do_Not_Direct_Mail__c'), apiName);
    }
}