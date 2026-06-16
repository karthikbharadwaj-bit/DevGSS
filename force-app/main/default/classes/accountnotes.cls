/*************************************************
accountnotes class
This Class is used by accountnotes.page which is currently a button on SFDC Account object.
The page/class takes account Id from URL and finds all notes and activities (events and tasks) related to Account. 
This includes any notes/activities tied to child or details objects. 
For example a task on an implementation will automatically show in related list in Account view. But notes and events on that same 
implementation will not. With this page you can see all of these records in one place. 
/************************************************/

public with sharing class accountnotes{

    
    public String case1 { get; set; }
    public String setupPlusDoc { get; set; }
    public String setupPlusGif { get; set; }

    public String getCase() {
        return null;
    }

    public String caselist { get; set; }
    public String Account { get; set; }

    public Account acct {get; set;}   
    public List<cNote> noteList {get; set;}
    public List<cEvent> eventList {get; set;}
    public List<cTask> taskList {get; set;}
    public List<cContract> contractList {get; set;}
    public List<cCase> caseList1 {get; set;}
    public Boolean userIdFound = false;
    
 	/* Constructor */
    public accountnotes(ApexPages.StandardController controller) {
        noteList = new List<cNote>();
        eventList = new List<cEvent>();
        taskList = new List<cTask>();
        contractList = new List<cContract>();        
        caseList1 = new List<cCase>();       
        setupPlusDoc = HardcodedIdsMapper.getMatchedObjectId('01580000000pUWf');
        setupPlusGif = HardcodedIdsMapper.getMatchedObjectId('01580000000pUWV');
        
        /*
        Using account.id find all notes, events, tasks contracts, and cases related to account that the page was launched from
        */ 
        try{
                //acct = [SELECT id,name,RC_Account_Number__c,RC_User_ID__c,RC_Account_Status__c,RC_Service_name__c,RC_Brand__c,RC_Tier__c,Current_Owner_Name__c,RC_Signup_Date__c,RC_Activation_Date__c,RC_Upgrade_Date__c,RC_Cancel_Date__c,RC_Churn_Date__c,RC_Attribution_Channel__c,RC_Attribution_L2__c,RC_Attribution_L3__c,RC_Attribution_Campaign__c FROM Account WHERE RC_User_ID__c=:ApexPages.currentPage().getParameters().get('userid')];
      // acct = [SELECT id,name,RC_Account_Number__c,RC_User_ID__c,RC_Account_Status__c,RC_Service_name__c,RC_Brand__c,RC_Tier__c,Current_Owner_Name__c,RC_Signup_Date__c,RC_Activation_Date__c,RC_Upgrade_Date__c,RC_Cancel_Date__c,RC_Churn_Date__c,RC_Attribution_Channel__c,RC_Attribution_L2__c,RC_Attribution_L3__c,RC_Attribution_Campaign__c FROM Account WHERE id=:ApexPages.currentPage().getParameters().get('id')];
       
       /*tring to catch all ids for note*/
       Set<id> set_of_ids = new Set<id>();
       Set<id> imp_acc = new Set<id>();
       
       acct = [SELECT
        (select id From Contacts),
        (Select Id From Opportunities),
        (Select Id From Implementations__r) ,
        (Select Id, Subject, ActivityDate, Status, Description, CreatedById, CreatedBy.Username From Tasks),
        (SELECT id, ContractTerm, StartDate, EndDate, createdbyid, Status, Total_Number_Of_Lines__c, CreatedBy.Username FROM Contracts),
        (SELECT id,CaseNumber,Contactid,Subject,Priority,CreatedDate,Status,Description,createdById, Contact.Name, CreatedBy.Username  FROM cases),
           		id,name,RC_Account_Number__c,RC_User_ID__c,RC_Account_Status__c,RC_Service_name__c,RC_Brand__c,RC_Tier__c,
       			Current_Owner_Name__c,RC_Signup_Date__c,RC_Activation_Date__c,RC_Upgrade_Date__c,
       			RC_Cancel_Date__c,RC_Churn_Date__c,RC_Attribution_Channel__c,RC_Attribution_L2__c,RC_Attribution_L3__c, RC_Attribution_Campaign__c
         FROM Account 
         WHERE id=:ApexPages.currentPage().getParameters().get('id')];
          
           userIdFound = true;  
           
      /*Preparing Set*/ 
        if(acct != null){
        	set_of_ids.add(acct.id);
        	imp_acc.add(acct.id);
        	
        	for(Contact cont:acct.Contacts){
        	set_of_ids.add(cont.id);	
        	}
        	
        	for(Opportunity opp:acct.Opportunities){
        	set_of_ids.add(opp.id);	
        	}
        	
        	for(Implementation__c imple:acct.Implementations__r){
        	set_of_ids.add(imple.id);
        	imp_acc.add(imple.id);	
        	}
        
        }  
        
        List<Note> note_list = new List<Note>();
        
        if(set_of_ids != null){
	        try{
	       	 note_list = [SELECT id, title, body, lastmodifieddate, createdbyid, CreatedBy.Username FROM Note WHERE parentId IN: set_of_ids];
	        }catch(Exception e){ }
        }  
        
        for(Note n:note_list){
        	 noteList.add(new cNote(n,n.title,n.body,n.lastmodifieddate.format(),n.CreatedBy.Username));
        }  
    
  /*************Event********************/
  List<Event> temp_eventList = new List<Event>();
   
  temp_eventList =[SELECT id, subject, description, activitydate, createdbyid , CreatedBy.Username FROM Event WHERE whatId =:imp_acc]; 
   
   if(temp_eventList != null){
	   for(Event e:temp_eventList){
	    eventList.add(new cEvent(e,e.subject,e.description,e.activitydate.format(),e.CreatedBy.Username));
	   } 
   }       
               
   /**************Task********************/
   for(Task t: acct.Tasks){
   	if(t.activitydate != null){                    
           taskList.add(new cTask(t,t.subject,t.description, t.activitydate.format(),t.CreatedBy.Username,t.status));
           }
           else{
           taskList.add(new cTask(t,t.subject,t.description, '',t.CreatedBy.Username,t.status));
           }          
   }
   
   /*************Contract******************/
   for(Contract contract: acct.Contracts){
   	contractList.add(new cContract(contract,String.valueOf(contract.ContractTerm),contract.StartDate,contract.EndDate,contract.CreatedBy.Username,contract.Status, String.valueOf(contract.Total_Number_Of_Lines__c)));
   }
   
   /***************Case*******************/
   for(Case case1: acct.Cases){
   	  try{
   	  	 caseList1.add(new cCase(case1,case1.CaseNumber,case1.Contact.Name ,case1.Subject,case1.Priority,case1.CreatedDate,case1.Status,case1.description));
   	  }catch(Exception e){
   	  	caseList1.add(new cCase(case1,case1.CaseNumber,case1.CreatedBy.Username ,case1.Subject,case1.Priority,case1.CreatedDate,case1.Status,case1.description));
   	  }	 
   }                          
                
        }
        catch (System.QueryException e){
                userIdFound = false;
        }
    }
    
    public Boolean getAccountFound(){
        return userIdFound;
    }
    
    public Boolean getAccountNotFound(){
        return !userIdFound;
    }
    
    public String getAccountID(){
        return acct.Id;
    }

    public String getAccountName(){
        return acct.Name;
    }
    
    public Note getSelectedNote(){
        Id id = System.currentPageReference().getParameters().get('noteId');
        
        return id == null ? new Note() : [SELECT Id, title FROM Note WHERE Id = :id];
    }

    public Event getSelectedEvent(){
        Id id = System.currentPageReference().getParameters().get('eventId');
        
        return id == null ? new Event() : [SELECT Id, subject FROM Event WHERE Id = :id];
    }
    
    public Task getSelectedTask(){
        Id id = System.currentPageReference().getParameters().get('taskId');
        
        return id == null ? new Task() : [SELECT Id, subject FROM Task WHERE Id = :id];
    }
    
    public Contract getSelectedContract(){
        Id id = System.currentPageReference().getParameters().get('contractId');
        
        return id == null ? new Contract() : [SELECT Id, status FROM Contract WHERE Id = :id];
    }     
        
    public Case getSelectedCase(){
        Id id = System.currentPageReference().getParameters().get('caseId');
        
        return id == null ? new Case() : [SELECT Id, caseNumber FROM Case WHERE Id = :id];
    }    
    
    /*
    The following classes (cNote, cEvent, cTask, cContract, cCase) are container classes.
    They allow us to group together the actual objects with some descriptive fields.
    With these we can provide a link to the actual object and show columns like title or subject. 
    */    
    public class cNote {
            public Note note {get; set;}  
            public String title {get; set;}
            public String body {get; set;}
            public String modifiedDate {get; set;}
            public String createdBy {get; set;}            
        
        /* Constructor */
        public cNote(Note note, String title, String body, String modified,String creator){
            this.note = note;
            this.title = title;
            this.body = body;
            this.modifiedDate = modified;
            this.createdBy = creator;
        }
    }
    
    public class cEvent{
            public Event event {get; set;}  
            public String subject {get; set;}
            public String description {get; set;}
            public String activityDate {get; set;}
            public String createdBy {get; set;}            
        
        
        public cEvent(Event event, String subject, String description, String activityDate,String creator){
            this.event = event;
            this.subject= subject;
            this.description= description;
            this.activityDate= activityDate;
            this.createdBy = creator;
        }
    }
    
    public class cTask{
            public Task task {get; set;}  
            public String subject {get; set;}
            public String description {get; set;}
            public String activityDate {get; set;}
            public String createdBy {get; set;}            
            public String Status {get; set;}            
        
        
        public cTask(Task task, String subject, String description, String activityDate,String creator,String status){
            this.task = task;
            this.subject= subject;
            this.description= description;
            this.activityDate= activityDate;
            this.createdBy = creator;
            this.status = status;
        }
    }
    
    public class cContract{
            public Contract contract {get; set;}  
            public String term {get; set;}
            public String startDate {get; set;}
            public String endDate {get; set;}
            public String createdBy {get; set;}            
            public String Status {get; set;}
            public String nOfLines {get; set;}              
        
        
        public cContract(Contract contract, String term, Date startDate, Date endDate,String creator,String status, String lines){
            this.contract = contract;
            this.term= term;
            if(startDate != null){
                this.startDate= startDate.format();     
            }
            else{
                this.startDate = '';
            }
            if(endDate != null){
                this.endDate= endDate.format(); 
            }
            else{
                this.endDate = '';
            }            
            this.createdBy = creator;
            this.status = status;
            this.nOfLines = lines;
        }
    } 

 public class cCase {
            public Case casedata {get; set;}  
            public String title {get; set;}
            public String caseNumber {get; set;}
            public String contactName {get; set;}
            public String subject {get; set;}   
            public String priority {get; set;}        
            public Datetime dtCreateDate {get; set;}     
            public String status {get; set;}    
            public String Description {get; set;}     
        
        /* Constructor */
        public cCase (Case casedata, String caseNumber, String contactName, String subject,String priority,Datetime dtCreateDate, String status,String Description){
            this.casedata = casedata;
            this.caseNumber= caseNumber;
            this.contactName= contactName;
            this.subject= subject;
           this.priority= priority;
            this.dtCreateDate= dtCreateDate;
            this.status= status;
            this.Description= Description;
        }
    }            
}