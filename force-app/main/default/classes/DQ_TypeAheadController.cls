/**
 * @Author      :       Ankit Sharma
 * @Date        :       11-May-2020
 * @Desc        :       Controller for Lookup Lightning Component
 * */
public without sharing class DQ_TypeAheadController {

    /**
     * Returns JSON of list of ResultWrapper to Lex Components
     * @objectName - Name of SObject
     * @fld_API_Text - API name of field to display to user while searching
     * @fld_API_Val - API name of field to be returned by Lookup COmponent
     * @lim   - Total number of record to be returned
     * @fld_API_Search - API name of field to be searched
     * @searchText - text to be searched
     * */
     @AuraEnabled
    public static List < sObject > fetchLookUpValues(String searchKeyWord, String ObjectName, String productFamily, String packageId, Boolean isDQFromCPQ,String configuredProductId) {
        system.debug('ObjectName-->' + ObjectName);
        system.debug('packageId-->' + packageId);
        String searchKey = '%'+ searchKeyWord + '%';
        
        List < sObject > returnList = new List < sObject > ();
      
        String sQuery = '';
        if(isDQFromCPQ)
        {
            if(configuredProductId == null || configuredProductId == '')
            {
                List<Product_Package__c> prodPackage = [Select Id,Ext_Element_Id__c from Product_Package__c where Id = :packageId];
                if(prodPackage != null && prodPackage.size() > 0)
                {
                    String productPackageId = prodPackage[0].Ext_Element_Id__c;
                    List<Product2> lstProducts = [Select Id from Product2 where ProductCode = :productPackageId];
                    if(lstProducts != null && lstProducts.size() > 0)
                    {
                        configuredProductId = lstProducts[0].Id;
                    }
                }
            }
            sQuery =  'select id,SBQQ__OptionalSKU__c, Product_Display_Name__c, Name from ' +ObjectName + ' where Product_Display_Name__c LIKE: searchKey  and SBQQ__ConfiguredSKU__c = :configuredProductId  order by createdDate DESC LIMIT 5';
        }
        else{
			// Create a Dynamic SOQL Query For Fetch Record List with LIMIT 5   
			sQuery =  'select id,Product__c, Display_Name__c, Name from ' +ObjectName + ' where Display_Name__c LIKE: searchKey  and Product_Package__c = :packageId  order by createdDate DESC LIMIT 5';
        }
		List < sObject > lstOfRecords = Database.query(sQuery);
        
        for (sObject obj: lstOfRecords) {
           /* system.debug('>>>'+obj.get('GOA_Group_V3__c'));
            System.debug('obj>>'+obj);
            if(obj.get('GOA_Group_V3__c') != null)
            system.debug('>>>'+String.valueOf(obj.get('GOA_Group_V3__c')).contains(productFamily));
            if(obj.get('GOA_Group_V3__c') != null && String.valueOf(obj.get('GOA_Group_V3__c')).contains(productFamily) && returnList.size() < 5) 
            */
                returnList.add(obj);
            /*else if(searchKeyWord == null || searchKeyWord == '') {
                returnList.add(obj);
            }*/
        }
        return returnList;
    }
    
     @AuraEnabled
    public static sObject getSelectedRecord(String recordId, String ObjectName, Boolean isDQFromCPQ,String configuredProductId) {
        
        List < sObject > returnList = new List < sObject > ();
		String sQuery = '';
        // Create a Dynamic SOQL Query For Fetch Record List with LIMIT 5   
		if(isDQFromCPQ) 
        {
            if(configuredProductId != null)
            {
                sQuery =  'select id,Product_Display_Name__c, Name from ' +ObjectName + ' where SBQQ__OptionalSKU__c =: recordId and SBQQ__ConfiguredSKU__c = :configuredProductId limit 1';
            }            
        }
		else{
			sQuery =  'select id,Display_Name__c, Name from ' +ObjectName + ' where Product__c =: recordId  limit 1';
		}
        
        List < sObject > lstOfRecords = Database.query(sQuery);
        
        if(lstOfRecords.isEmpty() ) {
            String sQuery1 =  'select id, Name from Product2' + ' where Id =: recordId  limit 1';
            lstOfRecords = Database.query(sQuery1);
            //System.assert(false,lstOfRecords);
        }       
        
        return lstOfRecords[0];
    }
}