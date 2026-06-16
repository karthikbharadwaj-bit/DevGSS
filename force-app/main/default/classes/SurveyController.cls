public class SurveyController {
    private String emailid;
    private String uid ;
    private String rid;
    private String exceptionObjId;
    public List<Integer> logoList {get;set;}
    public Integer logoPosition {get;set;}
    public Integer submitButtonPosition {get;set;}
    public boolean toshowErrorOrInfoMsg {get;set;}
    public boolean toshowFilledMsg {get;set;}
    
    public SurveyController () { 
        if(ApexPages.currentPage().getParameters().get('id') != null && ApexPages.currentPage().getParameters().get('id') != '') {
        	exceptionObjId = ApexPages.currentPage().getParameters().get('id');
        	getSurveyDetails();
        	checkAlreadyFilled();
        	isFilled = false;
        	logoList = new List<Integer>();
        	for(Integer i=0;i<3;i++) {
            	Integer a = 1; 
            	logoList.add(a++);
        	}
        } else {
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Invalid Id.'));
        }
   }
   
   public void getSurveyDetails() {
   		try {
   			List<Exception_And_Notification_History__c> emailNotificationList = [select Id, To_Address_1__c,content_label_01__c,Unique_Servey_No__c,
   																				content_label_02__c 
   																				from Exception_And_Notification_History__c 
   																				where Id=:exceptionObjId];
   			if(emailNotificationList != null && emailNotificationList.size()>0) {
   				emailid = emailNotificationList[0].To_Address_1__c;
        		uid = emailNotificationList[0].Unique_Servey_No__c;
        		rid = emailNotificationList[0].content_label_01__c;
   			}																	
   		} catch(Exception ex) {
   			
   		}
   }
    
   public boolean isAlreadyfilled { get; set;}
    
   public void checkAlreadyFilled() {
        isAlreadyfilled = false;
    }
    
    Set<Id> existingQuestionId = new Set<Id>();
    public List<WrapperQuestionList> wQesList{get;set;}  
 /*
 * the Submit action
 */ 
    public Boolean getIsFilled(){
        return isFilled;
    }
    
    public Boolean isFilled ;
    
    public PageReference saveSurvey(){
        String answers ='';
        boolean filled = true;
        for(WrapperQuestionList responses : wQesList){
            if( responses.IsMandatory ){
                     if ( ( responses.theTextValue == '' || responses.theTextValue == null ) ) {
                        filled = false;
                     } else  if ( ( responses.theRadioValue == '' || responses.theRadioValue == null )) {
                        filled = false;
                     } else if ( responses.getTheCheckBoxValue().size() == 0  ) {
                        filled = false;
                     } else if ( ( responses.theLongTextValue == '' || responses.theLongTextValue == null )) {
                        filled = false;
                     }
                }
        }   
        if( !filled ){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please fill all the mandatory questions.'));
            toshowErrorOrInfoMsg = true;
        } 
        if( filled ){ 
            saveResponse( wQesList ); 
        }
        return null;
    }

    
    public void saveResponse(List<WrapperQuestionList> responses){
        try {
        toshowFilledMsg = true;
        isFilled = true;
        } catch(Exception e) {
            isFilled = true;
            toshowFilledMsg = false;
            toshowErrorOrInfoMsg = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,'Thank you for your interest in our survey. Our team will contact you soon.'));
        }
    }

/*
    * WrapperQuestionList class take care of all question and its response.
*/
    public class WrapperQuestionList {
        public Boolean IsMandatory  { get;set; }
        public List<String> answers { get; set; }
        public String theRadioValue { get; set; }
        public String[] theCheckBoxValue = new String[]{};
        public String theTextValue { get; set;}
        public String theLongTextValue { get; set;}
        
        public WrapperQuestionList ( List<String> answers1 , Boolean IsMandatory) {
                if(answers1 == null) {
                    answers1 = new List<String>();
                }
                answers = answers1;
                this.IsMandatory = IsMandatory;
        }

        /*
        * returns option list accordind to answers type radio/chackbox
        */
        public List<SelectOption> getValues() {
            List<SelectOption> options = new List<SelectOption>(); 
            for(String temp: answers ) {
                 options.add(new SelectOption( temp ,temp)); 
            }   
         return options; 
       }  
       
        public String[] getTheCheckBoxValue() {
            return theCheckBoxValue;
        }
          
        public void setTheCheckBoxValue(String[] theCheckBoxValue) {
            this.theCheckBoxValue = TheCheckBoxValue;
        }
    }
}