global class LegalRequestPDFController {
    public Legal_Requests__c requestObj {get;set;}
    public Map<String,String> requestObjectMap {get;set;}
    
    public LegalRequestPDFController(){}
    
    // Standard Controller Extension
    public LegalRequestPDFController(ApexPages.StandardController controller){
        try{
            String requestId = ApexPages.currentPage().getParameters().get('id');
            if(String.isNotBlank(requestId)){//If invention Id present in URL
                List<String> lstObjFields = new List<String>();
                requestObjectMap = ITHelpDeskPortal.getLegalRequestObjDetail();
                lstObjFields.addAll(requestObjectMap.keyset());
                // controller.addFields(lstObjFields);
                // this.requestObj = (Legal_Requests__c) controller.getRecord();
                this.requestObj = (Legal_Requests__c) new LegalRequestSelector()
					.selectLegalRequestById(requestId)
					.executeQuery()
					.get(0);
            }
        }catch(Exception ex){
            system.debug('Exception == ' + ex.getStackTraceString());
        }   
    }
    
  	@RemoteAction
    global static String[] searchUser(String searchStr){
    	String filter = searchStr + '%';
    	String output= '';
    	List<String> strList = new List<String>();
    	for(User item: [SELECT id, Name from User WHERE name like :filter order by Name limit 20]){
            strList.add(item.Name);           
        }
        return strList;
    }
}