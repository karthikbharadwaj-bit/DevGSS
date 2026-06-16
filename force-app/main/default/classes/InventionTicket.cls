/*
	VF page for creating/editing Legal Request having record type 'Invention'.
*/

global with sharing class InventionTicket {
	
	//Variable Declaration
	public Legal_Requests__c inventionObj {get;set;}
	public Map<String,String> inventionObjectMap {get;set;}
	public Legal_Requests_Watchers__c watcherObj {get;set;}
	public Legal_Requests_Comments__c commentObj {get;set;}
	public Attachment attachObj{get;set;}
	public Boolean isEdit {get;set;}
	public Boolean isDraft {get;set;}
	public String inventionQueueId = '';
	public string inventionId{get;set;}
	public String inventorId {get;set;}
	public boolean isPortal{get;set;}
	public string titleText{get;set;}
	public string inventorName{get;set;}
	
	//Constructor
	public InventionTicket(ApexPages.StandardController controller){
		try{
			//Varibale Initializations
    		isPortal = true;
    		if(URL.getOrgDomainUrl().toExternalForm().containsIgnoreCase('visual')){
    			isPortal = false;
    		}
			watcherObj = new Legal_Requests_Watchers__c();
			commentObj = new Legal_Requests_Comments__c();
			attachObj = new Attachment();
			inventionObj = new Legal_Requests__c();
			inventionObjectMap = ITHelpDeskPortal.getLegalRequestObjDetail();
			inventionId = ApexPages.currentPage().getParameters().get('id');
			String pageAction =  ApexPages.currentPage().getParameters().get('action');
			
			//Fetch Invention Queue
			List<Group> lstGroup = [SELECT Id FROM Group WHERE Name = 'Invention Queue'];		
			if(lstGroup != null && lstGroup.size() > 0){
				inventionQueueId = lstGroup[0].Id;
			}
					
			if(String.isNotBlank(inventionId)){//If invention Id present in URL
				List<String> lstObjFields = new List<String>();
				lstObjFields.addAll(inventionObjectMap.keyset());
				controller.addFields(lstObjFields);

				// this.inventionObj = (Legal_Requests__c) controller.getRecord(); // Disabled after Case11188611 and replaced with a SOQL query
				this.inventionObj = (Legal_Requests__c) new LegalRequestSelector()
					.selectLegalRequestById(inventionId)
					.executeQuery()
					.get(0);

				if(inventionObj.Status__c!='Submitted'){
					titleText = 'Please review the form, add additional inventor(s) or attachment(s), then edit or submit upon completion.';
				} else{
					titleText = 'Your form was successfully submitted.';
				}
			}else{//If invention Id not present in URL
				inventionObj = new Legal_Requests__c();
				inventionObj.IDF_Creation_Date__c = system.today();
				inventionObj.recordTypeId = Schema.Sobjecttype.Legal_Requests__c.getRecordTypeInfosByName().get('Invention').getRecordTypeId();
				inventionObj.Status__c = 'Draft';
				titleText = 'Please fill out the form below in order to create a Invention Case.';
			}
			if(String.isNotBlank(pageAction) && 'edit'.equalsIgnoreCase(pageAction.trim()) && String.isNotBlank(inventionObj.Status__c) 
				&& 'Draft'.equalsIgnoreCase(inventionObj.Status__c.trim())){
				isEdit = true;
			}else if(String.isNotBlank(pageAction) && 'view'.equalsIgnoreCase(pageAction.trim())){
				isEdit = false;
			}else{
				isEdit = false;
			}
			if(String.isNotBlank(inventionObj.Status__c) && !'Draft'.equalsIgnoreCase(inventionObj.Status__c.trim())){
				isDraft = false;
			}else{
				isDraft = true;
			}
		}catch(Exception ex){
			system.debug('Exception == ' + ex.getMessage()+ex.getLineNumber());
			system.debug('Exception == ' + ex.getStackTraceString());
		}
	}
	
	//Called from page for Submitting Legal Request
	public PageReference submitCase(){
		try{
			inventionObj.Status__c = 'Submitted';
			inventionObj.OwnerId = inventionQueueId;
			update inventionObj;
			
			//Pdf Attachment of VF Page Content
			PageReference pdfPage = Page.InventionTicket_PDF;
		    pdfPage.getParameters().put('id',inventionObj.id);
		    pdfPage.setRedirect(true);
		
		    //Take the PDF content
		    Blob vfPageContent;
        	if(!Test.isRunningTest()){
        		vfPageContent = pdfPage.getContent();
        	}else{
        		vfPageContent = Blob.valueOf('Test String');
        	}
        	
        	//Attach PDF with record
        	Attachment att = new Attachment();
			att.ParentId = inventionObj.Id;
			att.Name = system.today() + '_' + inventionObj.Name;
			att.Body = vfPageContent;
			att.ContentType = 'application/pdf';
			insert att;
			PageReference detailPage = new PageReference('/apex/inventionTicket?action=edit');
	        detailPage.setRedirect(true);
	        return detailPage;
		}catch(exception e){ return null; }
	}
	
	//Inventor Name Lookup Calling
	public void inventorNameFun(){
		inventionObj.Inventor_Name__c = inventorId;
	}
	
	//Called from vf page for open page in edit mode
	public PageReference editData(){
		PageReference detailPage = new PageReference('/apex/inventionTicket?action=edit&id=' + inventionObj.id);
        detailPage.setRedirect(true);
        return detailPage;
	}
	
	public PageReference cancelButton(){
		PageReference detailPage = new PageReference('/apex/inventionTicket?action=view&id=' + inventionObj.id);
        detailPage.setRedirect(true);
        return detailPage;
	} 
	
	public Boolean getIsInventionId(){
		String inventionId = ApexPages.currentPage().getParameters().get('id');
		String pageAction =  ApexPages.currentPage().getParameters().get('action');
		if(String.isNotBlank(inventionId) && 'edit'.equalsIgnoreCase(pageAction)){
			return true;
		}
		return false;
	}
	
	//Called from vf page for saving Legal Request
	public PageReference saveData(){
		system.debug('*** Data Saved ***'+inventorName);
		try{	
			if(string.isNotBlank(inventionObj.Title_of_Invention__c)){
				if(inventionObj.Title_of_Invention__c.length() > 80){
					inventionObj.Name = inventionObj.Title_of_Invention__c.subString(0,80);
				} else {
					inventionObj.Name = inventionObj.Title_of_Invention__c;
				}
			}		
			if(string.isBlank(inventionObj.Inventor_Name_Text__c)){
				inventionObj.Inventor_Name__c = null;
			}
			upsert inventionObj;
			if(string.isBlank(inventionId)){
				Legal_Requests_Watchers__c watcherObjInsert = new Legal_Requests_Watchers__c(Advisor_Name__c = userInfo.getUserId(),
																							Legal_Requests__c = inventionObj.id,
																							Advisor_Name_Text__c = userInfo.getName());
				database.insert(watcherObjInsert,false);
			}
			PageReference detailPage = new PageReference('/apex/inventionTicket?action=view&id=' + inventionObj.id);
            detailPage.setRedirect(true);
        	return detailPage;			
		}catch(Exception ex){
			ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
			system.debug('Exception == ' + ex.getMessage()+ex.getLineNumber());
			system.debug('Exception == ' + ex.getStackTraceString());
		}
		return null;
	}
	
	//Called from vf page for saving Legal request comment in Legal Request
	public void saveComment(){
		if(string.isNotBlank(commentObj.Comment__c)){
			commentObj.Legal_Requests__c = inventionObj.id;		
			insert commentObj;
			commentObj = new Legal_Requests_Comments__c();
		}else {
			ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.ERROR, 'Please enter comment.'));
		}
	}
	
	//Called from vf page for adding additional watcher to Legal Request
	public void saveWatcher(){
		try{
			List<Legal_Requests_Watchers__c> requestList = [SELECT id FROM Legal_Requests_Watchers__c where Advisor_Name__c=:watcherObj.Advisor_Name__c
															AND Legal_Requests__c=:inventionObj.id];
			if(requestList!=null && requestList.size() > 0){
				ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.ERROR, 'Inventor already exsits.'));
				watcherObj = new Legal_Requests_Watchers__c();
			}else{
				watcherObj.Legal_Requests__c = inventionObj.id;
				database.insert(watcherObj,false); 
				watcherObj = new Legal_Requests_Watchers__c();
			}
		}catch(Exception e){
			system.debug('Exception');
			ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()));
		}
	}
    
    //Upload Attachment to record.
    public PageReference uploadFile() {
    	attachObj.ParentId = inventionObj.id;
    	try {
	      insert attachObj;
	    } catch (DMLException e) {
	      ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Error uploading file'));
	      return null;
	    } finally {
	      attachObj.body = null; // clears the viewstate
	      attachObj = new Attachment();
	    }	    
    	return null;
    }
    
    //Validate Inventor before Adding Inventor.
    @RemoteAction
    global static String[] searchUser(String searchStr){
    	String filter = searchStr + '%';
    	List<String> strList = new List<String>();
    	for(User item: [SELECT id, Name from User WHERE name like : filter order by Name limit 20]){
            strList.add(item.Name);           
        }
        return strList;
    }
}