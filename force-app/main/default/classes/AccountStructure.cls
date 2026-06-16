public with sharing class AccountStructure{

    @AuraEnabled(cacheable=true)
    public static List<Account> findHierarchyData(string recId){
        List<Account> accList = new List<Account>();
        string queryString = 'select id, name, type, industry, parentId, RecordType.Name, RC_Account_Status__c,'
                             +'Sector__c, Segment_Name__c,Segment_Name__r.Name, SM_Employees__c, SM_Country__c,'
                             +'ZI_Company_Revenue__c, MRR__c, Ultimate_Parent_Account_Name__c,'
                             +'Domestic_Employees__c, Ultimate_Account__c, Domestic_Country__c, Owner.alias from Account ';
        //Section to get all child account details from ultimate parent starts-------------------------
        List<String> currentParent      = new List<String>{};
        Integer level               = 0;
        Boolean endOfStructure      = false;
        //method to find ultimate parent of account
        string topMostparent = GetUltimateParentId(recId );
        system.debug('*******topMostparent:'+topMostparent);
        currentParent.add(topMostparent);
        system.debug('**********topMostparent:'+ currentParent);
        //Loop though all children
        string finalQueryString = '';
        List<Account>  queryOutput = new List<Account> ();
        while ( !endOfStructure ){  
            if( level == 0 ){
                finalQueryString = queryString + ' where id IN : CurrentParent ORDER BY ParentId  Limit 1000';
            } 
            else {
                finalQueryString = queryString + ' where ParentID IN : CurrentParent ORDER BY ParentId Limit 1000';
            }
            system.debug('********finalQueryString:'+finalQueryString);
            if(finalQueryString != null && finalQueryString !=''){
                try{
                    if(Limits.getLimitQueries()-Limits.getQueries()>0){
                        queryOutput = database.query(finalQueryString);
                        system.debug('***hierarchy level:'+level);
                    }else{
                        system.debug('****endOfStructure is true as SOQL limit reaches:');
                        endOfStructure = true;
                    }
                }catch(exception ex){ 
                    endOfStructure = true;
                }
            }
            system.debug('**queryOutput size:'+queryOutput);
            if( queryOutput.size() == 0 ){
                endOfStructure = true;
            }
            else{
                currentParent.clear();
                //iterating through query output
                for ( Integer i = 0 ; i < queryOutput.size(); i++ ){
                    currentParent.add(queryOutput[i].Id);
                    if(String.isBlank(queryOutput[i].RC_Account_Status__c))
                    {
                    queryOutput[i].RC_Account_Status__c='';
                    }
                    accList.add(queryOutput[i]);
                 }
            }
            level++;
        }
        system.debug('**********accList:'+accList);
        return accList;
    }
    
    // Find the top most element in Heirarchy  
    // @return objId
    public static String GetUltimateParentId( string recId ){
        Boolean top = false;
        while ( !top ) {
            string queryString = 'select id ,name, parentId from Account where Id =:recId LIMIT 1';
            
            system.debug('Record ID : ' + recId);
            system.debug('In Get Ultimate Parent Id' + queryString);
            
            Account acc = database.query(queryString);
            
            system.debug('Account ID ' + acc.id);
            system.debug('Account Name : ' + acc.name);
            system.debug('Parent ID : ' + acc.parentId);
            
            if ( acc.parentId != null ) {
                recId = acc.parentId;
            }else {
                top = true;
            }
        }
        return recId ;
    }

}