public without sharing class CustomUserLookupController {

   public Contact contact {get;set;} 
  public List<Contact> results{get;set;} 
  public string searchString{get;set;} 

  public CustomUserLookupController () {
    contact = new Contact();
   
    searchString = System.currentPageReference().getParameters().get('lksrch');
    runSearch();  
  }

  public PageReference search() {
    runSearch();
    return null;
  }

  private void runSearch() {    
    results = performSearch(searchString);               
  } 

  // run the search and return the records found. 
    private List<Contact> performSearch(string searchString) {
        String soql = 'SELECT Id,Account_Brand__c,Account.Name,Account_Partner_Status__c,LastName,FirstName,Email,Phone, Name FROM Contact ';
        String sCondition = '';
        if(String.isNotBlank(searchString)) {
            searchString = searchString.trim();
            sCondition = ' AND Name LIKE \'%' + searchString +'%\'';
        }
        soql = soql + ' WHERE Account.Name=\'RC Internal\' ' + sCondition +' LIMIT 1000';
        System.debug(soql);
        return database.query(soql); 
    }
 
 /* public PageReference saveAccount() {
    insert contact;
    contact = new Contact();
    return null;
  }*/
  public string getFormTag() {
    return System.currentPageReference().getParameters().get('frm');
  }

  // used by the visualforce page to send the link to the right dom element for the text box
  public string getTextBox() {
    return System.currentPageReference().getParameters().get('txt');
  }


}