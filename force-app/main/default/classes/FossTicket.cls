/*
	VF page for creating/editing Legal Request having record type 'FOSS'.
*/
public with sharing class FossTicket {
	
	//Variable Declaration
	public Legal_Requests__c fossObj {get;set;}
	public Map<String,String> fossObjectMap {get;set;}
	public Legal_Requests_Watchers__c watcherObj {get;set;}
	public Boolean isEdit {get;set;}
	public Boolean isDraft {get;set;}
	public String fossQueueId = '';	
	public Attachment attachObj{get;set;}
	
	//Constructor
	public FossTicket(ApexPages.StandardController ext){
		try{			    
			//Varibale Initializations			
			watcherObj = new Legal_Requests_Watchers__c();
			attachObj = new Attachment();
			fossObjectMap = ITHelpDeskPortal.getLegalRequestObjDetail();
			String fossId = ApexPages.currentPage().getParameters().get('id');
			String action =  ApexPages.currentPage().getParameters().get('action'); 
			
			//Fetch Invention Queue
			List<Group> lstGroup = [SELECT Id FROM Group WHERE Name = 'FOSS Queue'];
			if(lstGroup != null && lstGroup.size() > 0){
				fossQueueId = lstGroup.get(0).Id;
			} 
			
			if(String.isNotBlank(fossId)){//If FOSS Id present in URL
				List<String> lstObjFields = new List<String>();
				lstObjFields.addAll(fossObjectMap.keyset());
				Integer len = lstObjFields.size();
				String strObjFields = '';
				for(integer count = 0; count < len; count++){
					if(count == 0){
						strObjFields = strObjFields + lstObjFields.get(count);
					}else{
						strObjFields = strObjFields + ', ' + lstObjFields.get(count);
					}
				}				
				String strQuery = 'SELECT ' + strObjFields + ' FROM Legal_Requests__c Where Id = \'' + fossId + '\'';
				List<Legal_Requests__c> fossList = Database.query(strQuery);
				if(fossList != null && fossList.size() > 0){
					fossObj = fossList.get(0);
				}
			}else{//If FOSS Id not present in URL
				fossObj = new Legal_Requests__c();
				fossObj.IDF_Creation_Date__c = system.today();
				fossObj.recordTypeId = Schema.Sobjecttype.Legal_Requests__c.getRecordTypeInfosByName().get('FOSS').getRecordTypeId();
				fossObj.Status__c = 'Draft';
			}
			if(String.isNotBlank(action) && 'edit'.equalsIgnoreCase(action.trim()) && String.isNotBlank(fossObj.Status__c)  
																&& 'Draft'.equalsIgnoreCase(fossObj.Status__c.trim())){
				isEdit = true;
			}else if(String.isNotBlank(action) && 'view'.equalsIgnoreCase(action.trim())){
				isEdit = false;
			}else{
				isEdit = false;
			}
			if(String.isNotBlank(fossObj.Status__c) && !'Draft'.equalsIgnoreCase(fossObj.Status__c.trim())){
				isDraft = false;
			}else{
				isDraft = true;
			}
		}catch(Exception ex){
			system.debug('Exception == ' + ex.getMessage());
			system.debug('Exception == ' + ex.getStackTraceString());
		}
	}
	
	public PageReference cancelButton(){
		PageReference detailPage = new PageReference('/apex/fossticket?action=view&id=' + fossObj.id);
        detailPage.setRedirect(true);
        return detailPage;
	} 
	
	public Boolean getIsFossId(){
		String fossId = ApexPages.currentPage().getParameters().get('id');
		String pageAction =  ApexPages.currentPage().getParameters().get('action');
		if(String.isNotBlank(fossId) && 'edit'.equalsIgnoreCase(pageAction)){
			return true;
		}
		return false;
	}
	
	
	//Called from page for Submitting Legal Request
	public PageReference submitCase(){
		try{
			fossObj.Status__c = 'Submitted';
			fossObj.OwnerId = fossQueueId;
			update fossObj;
			
			//Pdf Attachment of VF Page Content
			PageReference pdfPage = Page.FossTicket_PDF;
		    pdfPage.getParameters().put('id',fossObj.id);
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
			att.ParentId = fossObj.Id;
			att.Name = system.today() + '_' + fossObj.Name;
			att.Body = vfPageContent;
			att.ContentType = 'application/pdf';
			insert att;
			PageReference detailPage = new PageReference('/apex/fossTicket?action=view&id=' + fossObj.id);
	        detailPage.setRedirect(true);
	        return detailPage;
		} catch(exception ex){
			//ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.ERROR,ex.getMessage()));
			return null;
		}
	}
	
	//Called from vf page for open page in edit mode
	public PageReference editData(){
		PageReference detailPage = new PageReference('/apex/fossTicket?action=edit&id=' + fossObj.id);
        detailPage.setRedirect(true);
        return detailPage;
	}	
	
	//Called from vf page for adding additional watcher to Legal Request
	public PageReference saveData(){
		try{		
			if(string.isNotBlank(fossObj.FOSS_Name__c)){
				if(fossObj.FOSS_Name__c.length() > 80){
					fossObj.Name = fossObj.FOSS_Name__c.subString(0,80);
				} else {
					fossObj.Name = fossObj.FOSS_Name__c;
				}
			}	    
			if(string.isBlank(fossObj.FOSS_Submitter__c)){
				fossObj.FOSS_Submitter_Lookup__c = null;
			}
			upsert fossObj;
			PageReference detailPage = new PageReference('/apex/fossTicket?action=view&id=' + fossObj.id);
        	detailPage.setRedirect(true);
        	return detailPage;			
		}catch(Exception ex){
			ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
			system.debug('Exception == ' + ex.getMessage());
			system.debug('Exception == ' + ex.getStackTraceString());
		}
		return null;
	}
	
	//Called from vf page for adding additional watcher to Legal Request
	public void saveWatcher(){
		//if(watcherObj.Advisor_Name__c != null){
			List<Legal_Requests_Watchers__c> requestList = [SELECT id FROM Legal_Requests_Watchers__c where Advisor_Name__c=:watcherObj.Advisor_Name__c 
															AND Legal_Requests__c=:fossObj.id];
			if(requestList!=null && requestList.size() > 0){
				ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.ERROR, 'Inventor already exsits.'));
			} else {
				watcherObj.Legal_Requests__c = fossObj.id;
				database.insert(watcherObj,false); 
				watcherObj = new Legal_Requests_Watchers__c();
			}
		/*} else {
			ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.ERROR, 'Please enter both the fields.'));
		}*/
	}
	
	//Upload Attachment to record.
    public PageReference uploadFile() {
    	attachObj.ParentId = fossObj.id;
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
}