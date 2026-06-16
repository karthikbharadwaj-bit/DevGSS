/* 
*Class Name 		: recordSearchController

*Business Purpose 	: To Get the Account, Opportunity, Contact records based on user search input
					  To Get the Account hierarchy for a particular account
					  This class is a controller class for LWC - RecordSearcher, AccountHierarchyTable

*Developer Name 	: Manovasanth Balasankar
Modification History:
*--------------------------------------------------------------------------------------------------------------------
Date              User Story#                   Developer Name                    Changes done
*-------------------------------------------------------------------------------------------------------------------
11/03/2022         CRM 4864                   Manovasanth Balasankar            New Class
*/
global Without Sharing class recordSearchController {
    /**
    * @param search name from the LWC
    * @description gets records based on the search term 
    * @return List of sObjects includes Accounts, contacts, opportunities
    */
    @AuraEnabled(cacheable=true)
    public static List<Account> getAccountsByName(String searchTerm){
        try{
        return search.query('FIND {'+searchTerm+'} IN All Fields RETURNING ACCOUNT(Id, Name ,Number_of_DL_s__c, RC_Service_name__c ,Owner.Name , RC_Account_Status__c, Current_Owner__r.name, RecordType.Name, Partner_Account__r.Name Order by lastmodifiedDate desc) LIMIT 1000')[0];
        }catch(Exception ex){ 
            System.debug('recordSearchController - getAccountsByName' + ex);
            return null;
        }
    }
    @AuraEnabled(cacheable=true)
    public static List<Contact> getContactsByName(String searchTerm){
        try{
        return search.query('FIND {'+searchTerm+'} IN All  Fields RETURNING CONTACT(Id, Name ,Account.Name Order by lastmodifiedDate desc) LIMIT 1000')[0];
        }catch(Exception ex){ 
            System.debug('recordSearchController - getContactsByName' + ex);
            return null;
        }
    }
    @AuraEnabled(cacheable=true)
    public static List<Opportunity> getOpportunitiesByName(String searchTerm){
        try{
        return search.query('FIND {'+searchTerm+'} IN All  Fields RETURNING OPPORTUNITY(Id, Name ,Account.Name , Owner.Name ,Account.Owner_Name__c,  CloseDate, StageName Order by lastmodifiedDate desc) LIMIT 1000')[0];
        }catch(Exception ex){ 
            System.debug('recordSearchController - getOpportunitiesByName' + ex);
            return null;
        }
    }

     /**
    * @param Account record Id called from from the LWC- recordSearcher
    * @description gets All the account hierarchy records 
    * List of Hierarchy based Accounts
    */
    @AuraEnabled(cacheable=true)
    public static List<Account> findHierarchyData(string recId){
        List<Account> accList = new List<Account>();
        string queryString = 'SELECT Id, Name , RC_Service_name__c , Owner.Name , RC_Account_Status__c, RecordType.Name, Partner_Account__r.Name, parentId FROM ACCOUNT ';
        //Section to get all child account details from ultimate parent starts-------------------------
        List<String> currentParent = new List<String>{};
        Integer level = 0;
        Boolean endOfStructure = false;
        //method to find top most parent of current account
        string topMostparent = GetUltimateParentId(recId );
        currentParent.add(topMostparent);
        //Loop though all children
        string finalQueryString = '';
        List<Account>  queryOutput = new List<Account> ();
        while ( !endOfStructure ){  
            if( level == 0 ){
                finalQueryString = queryString + ' WHERE id IN : CurrentParent ORDER BY ParentId  Limit 1000';
            } 
            else {
                finalQueryString = queryString + ' WHERE ParentID IN : CurrentParent ORDER BY ParentId Limit 1000';
            }

            if(finalQueryString != null && finalQueryString !=''){
                try{
                    if(Limits.getLimitQueries()-Limits.getQueries()>0){
                        queryOutput = database.query(finalQueryString);
                    }else{
                        endOfStructure = true;
                    }
                }catch(exception ex){ 
                    endOfStructure = true;
                }
            }
            if( queryOutput.size() == 0 ){
                endOfStructure = true;
            }
            else{
                currentParent.clear();
                //iterating through query output
                for ( Integer i = 0 ; i < queryOutput.size(); i++ ){
                    currentParent.add(queryOutput[i].Id);
                    accList.add(queryOutput[i]);
                 }
            }
            level++;
        }
        
        return accList;
    }
    
	/* 
	 @param account record Id 
	 @description Helper Method for findHierarchyData Find the top most account id in Heirarchy  
     @return objId */
    public static String GetUltimateParentId( string recId ){
        Boolean top = false;
        while ( !top ) {
            string queryString = 'SELECT Id ,Name, ParentId from ACCOUNT WHERE Id =:recId LIMIT 1';
            Account acc = database.query(queryString);
            if ( acc.parentId != null ) {
                recId = acc.parentId;
            }else {
                top = true;
            }
        }
        return recId ;
    }
}