public class LwcLookupController {
	@AuraEnabled(cacheable=true)  
	public static List<sobject> findRecords(String searchKey, String objectName, String fields) {  
	  string searchText = '\'' + String.escapeSingleQuotes(searchKey) + '%\'';  
	  string query = 'SELECT Id, Name ' + (String.isNotEmpty(fields) ? ',' + fields : '') + ' FROM ' +objectName+ ' WHERE Name LIKE '+searchText+' LIMIT 6';  
	  return Database.query(query);  
	}  
}