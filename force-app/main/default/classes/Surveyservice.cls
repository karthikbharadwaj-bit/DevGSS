/*************************************************
Survey class
Along with SalesCSat.page and SEcSat.page used in public sites allows customers to fill in cSat surveys
There are Sales and Implementations Surveys. When created the customer is emailed a link to survey.page with survey record Id.
Find survey record and records answers entered through page.
/************************************************/

public class Surveyservice {
  
    private final Survey__c s;
    private final Contact c;
    private final Opportunity o;
    private final Account a;    
    PageReference pageRef = new PageReference('http://www.ringcentral.com');
    public Boolean submitted = false;
    public Boolean allAnswered = false;  
    Integer q1Value = Null;
    Integer q2Value = Null;
    Integer q3Value = Null;
    Integer q4Value = Null;     
    Integer q5Value = Null; 
    Integer q6Value = Null;     
    String comment;
    
    /*
    Take Id from URL and finds survey record. If record's fields(answers) are not blank then show them on page 
    */
    public Surveyservice() {
      try{
          s = [SELECT Id,Name,Porting_Q1_timely__c,porting_Q2_accurately__c,porting_Q3_submission__c,Porting_Q4_Satisfaction__c,Average_Score__c,Porting_Comments__c,
          SurveyType__c,Account__c,Contact__c,Opportunity__c,Agent__c,Responded__c,Response_Date__c  
          FROM Survey__c WHERE id=:ApexPages.currentPage().getParameters().get('id')];
          
          c = [SELECT Id,Name,Email FROM Contact WHERE id=:s.Contact__c];
          if(s.Porting_Q1_timely__c != Null){
              q1Value = s.Porting_Q1_timely__c.intValue();
          }
          if(s.porting_Q2_accurately__c != Null){
              q2Value = s.porting_Q2_accurately__c.intValue();
          }
          if(s.porting_Q3_submission__c != Null){
              q3Value = s.porting_Q3_submission__c.intValue(); 
          }
          if(s.Porting_Q4_Satisfaction__c != Null){
              q4Value = s.Porting_Q4_Satisfaction__c.intValue(); 
          }   
          
          comment = s.Porting_Comments__c;
      }
      catch(System.QueryException e){}
        
    }    
    
    
    public Boolean getAnswered(){
        if(allAnswered == false && submitted == true){
            return true;
        }
        return false;
    }
           
    public Boolean getIsEmpty() {
      if(s.SurveyType__c=='Porting'){
          //if(q1Value == NULL || q2Value == NULL || q3Value == NULL || q4Value == NULL  || q5Value == NULL || q6Value == NULL){
          if(q1Value == NULL || q2Value == NULL || q3Value == NULL || q4Value == NULL ){
              return true;
          }
      }
      return false;
    }
    
    public Boolean getIsFilled() {
       if(s.SurveyType__c == 'Porting'){
         if(s.Porting_Q1_timely__c != NULL && s.porting_Q2_accurately__c != NULL && s.porting_Q3_submission__c!=NULL && s.Porting_Q4_Satisfaction__c!=NULL ){
             return true;
          }
        }
        return false;        
    }
     
    
    public String getComments(){
        return comment;
    }

    public void setComments(String c){
        this.comment = c;
        s.Porting_Comments__c = c;
    }
    
    public Integer getQ1Value(){
        return q1Value;
    }

    public void setQ1Value(Integer value){
        this.q1Value = value;
        s.Porting_Q1_timely__c = value;
    }
    
    public Integer getQ2Value(){
        return q2Value;
    }

    public void setQ2Value(Integer value){
        this.q2Value = value;
        s.porting_Q2_accurately__c = value;
    }
    
    public Integer getQ3Value(){
        return q3Value;
    }

    public void setQ3Value(Integer value){
        this.q3Value = value;
        s.porting_Q3_submission__c = value;
    }        
    
    public Integer getQ4Value(){
        return q4Value;
    }

    public void setQ4Value(Integer value){
        this.q4Value = value;
        s.Porting_Q4_Satisfaction__c = value;
    }        
     
    public List<SelectOption> getValues() {
        List<SelectOption> options = new List<SelectOption>(); 
        options.add(new SelectOption('5','Strongly Agree')); 
        options.add(new SelectOption('4','Somewhat Agree')); 
        options.add(new SelectOption('3','Neither Agree nor Disagree')); 
        options.add(new SelectOption('2','Somewhat Disagree'));
        options.add(new SelectOption('1','Strongly Disagree'));  
        return options; 
    }    
	/* changes done for question no 4*/
	  public List<SelectOption> getValues1() {
	        List<SelectOption> options = new List<SelectOption>(); 
	        options.add(new SelectOption('5','Completely Satisfied')); 
	        options.add(new SelectOption('4','Somewhat Satisfied')); 
	        options.add(new SelectOption('3','Neutral')); 
	        options.add(new SelectOption('2','Somewhat Dissatisfied'));
	        options.add(new SelectOption('1','Completely Dissatisfied'));  
	        return options; 
	    }    
	 
	 
	 /* end of code*/
 
 

    public Survey__c getSurvey() {
            return s;
    }
  
  /*
  Validate and save entered answers to survey record.
  Set responded fields and calculate average score based on type of survey.
  */
    public PageReference save() {
        submitted = true;
        if(s.SurveyType__c=='Porting'){
        if(s.Porting_Q1_timely__c == NULL || s.porting_Q2_accurately__c == NULL || s.porting_Q3_submission__c ==NULL || s.Porting_Q4_Satisfaction__c ==NULL ){
            allAnswered = false;
             return ApexPages.currentPage();
        }
          allAnswered = true;
          s.Responded__c = 1;
          s.Response_Date__c = Date.today();
          s.Average_Score__c =  (s.Porting_Q1_timely__c+s.porting_Q2_accurately__c+s.porting_Q3_submission__c+s.Porting_Q4_Satisfaction__c)/4;
        }
        s.Porting_Comments__c = comment;
        update s;
        return ApexPages.currentPage();
    }
    
    public string getContactName(){
        return c.name;
    }
   
}