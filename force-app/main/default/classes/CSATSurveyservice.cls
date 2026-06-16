/*************************************************
Survey class
Along with SupportCSATSurvey.page and SupportCSATSurvey.page used in public sites allows customers to fill in CSAT surveys
There are Support CSAT Surveys. When created the customer is emailed a link to survey.page with survey record Id.
Find survey record and records answers entered through page.
/************************************************/

public class CSATSurveyservice{

Boolean commentLength1 = false;

   public Boolean getCommentLength() {
       if(comment!=NULL){
       {
        if(comment.length()>2000){
            commentLength1=true;
            return commentLength1;
        }
       
    }
   }return commentLength1; }  
  
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
    String comment;
    public String repEmail { get; set; }
    public Boolean alreadyFilled {get;set;}
    public Boolean IsFilled {get;set;}  
    
    /*
    Take Id from URL and finds survey record. If record's fields(answers) are not blank then show them on page 
    */
    public CSATSurveyservice() {
      try{
          s = [SELECT Id,Name,Q1_Score__c,Q2_Score__c,Q3_Score__c,Q4_Score__c,Q5_Score__c,Average_Score__c,Comments__c,SurveyType__c,
          				Account__c,Contact__c,Opportunity__c,Agent__c,Responded__c,Response_Date__c , Agent_Email__c 
          		FROM Survey__c 
          		WHERE id=:ApexPages.currentPage().getParameters().get('id')];
          
          repEmail = s.Agent_Email__c;
          		
          c = [SELECT Id,Name,Email FROM Contact WHERE id=:s.Contact__c];
          if(s.Q1_Score__c != Null){
              q1Value = s.Q1_Score__c.intValue();
          }
          if(s.Q2_Score__c != Null){
              q2Value = s.Q2_Score__c.intValue();
          }
          if(s.Q3_Score__c != Null){
              q3Value = s.Q3_Score__c.intValue(); 
          }
          if(s.Q4_Score__c != Null){
              q4Value = s.Q4_Score__c.intValue(); 
          }        
       if(s.Q5_Score__c != Null){
              q5Value = s.Q5_Score__c.intValue(); 
          }  
          comment = s.Comments__c;
          
           if(s.SurveyType__c=='Support CSAT' || s.SurveyType__c=='VAR Support CSAT'){
		           String strCommentlength=comment==null?'':comment;
		          if(s.Q1_Score__c != NULL && s.Q2_Score__c != NULL && s.Q3_Score__c != NULL && s.Q4_Score__c != NULL && s.Q5_Score__c != NULL && (strCommentlength.length() < 2000||comment == NULL)){
		          alreadyFilled = true;
		         }
		     }
      }
    catch(Exception e) {
	      if( e.getMessage().contains('List has no rows for assignment to SObject')){  
	        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Required parameters are missing.'));
          }
      }
        
    }
    
    public Boolean getAnswered(){
        if(allAnswered == false && submitted == true){
            return true;
        }
               return false;
    }
           
    public Boolean getIsEmpty() {
    if(s != null){	
      if(s.SurveyType__c=='Support CSAT' || s.SurveyType__c=='VAR Support CSAT'){
         if(s.Q1_Score__c == NULL || s.Q2_Score__c == NULL || s.Q3_Score__c == NULL || s.Q4_Score__c == NULL || s.Q5_Score__c == NULL){
              return true;
          }
          if(comment!=null && comment!='' && comment.length()>2000){
            return true;
          }
      }
    }
        return false;
    }
    
     public Boolean getIsFilled(){
    	return IsFilled;
    }
    
    public String getComments(){
        return comment;
    }

    public void setComments(String c){
        this.comment = c;
        if(comment.length()<2000){
            s.Comments__c = c;
        }
    }
    
    public Integer getQ1Value(){
        return q1Value;
    }

    public void setQ1Value(Integer value){
        this.q1Value = value;
        s.Q1_Score__c = value;
    }
    
    public Integer getQ2Value(){
        return q2Value;
    }

    public void setQ2Value(Integer value){
        this.q2Value = value;
        s.Q2_Score__c = value;
    }
    
    public Integer getQ3Value(){
        return q3Value;
    }

    public void setQ3Value(Integer value){
        this.q3Value = value;
        s.Q3_Score__c = value;
    }        
    
    public Integer getQ4Value(){
        return q4Value;
    }

    public void setQ4Value(Integer value){
        this.q4Value = value;
        s.Q4_Score__c = value;
    }        
        
         public Integer getQ5Value(){
        return q5Value;
    }

    public void setQ5Value(Integer value){
        this.q5Value = value;
        s.Q5_Score__c = value;
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

    public List<SelectOption> getValues2() {
        List<SelectOption> options = new List<SelectOption>(); 
        options.add(new SelectOption('10','10 Extremely Likely')); 
        options.add(new SelectOption('9','9')); 
        options.add(new SelectOption('8','8')); 
        options.add(new SelectOption('7','7'));
        options.add(new SelectOption('6','6')); 
        
        options.add(new SelectOption('5','5 Neutral')); 
        options.add(new SelectOption('4','4')); 
        options.add(new SelectOption('3','3')); 
        options.add(new SelectOption('2','2'));
        options.add(new SelectOption('1','1')); 
        options.add(new SelectOption('0','0 Extremely Unlikely'));     
        return options; 
    }    
    
     public List<SelectOption> getValues3() {
        List<SelectOption> options = new List<SelectOption>(); 
        options.add(new SelectOption('1','Yes')); 
        options.add(new SelectOption('0','No')); 
        
        return options; 
    }    

    public Survey__c getSurvey() {
            return s;
    }
  
  /*
  Validate and save entered answers to survey record.
  Set responded fields and calculate average score based on type of survey.
  */
    public PageReference save() {
        submitted = true;
      if(s.SurveyType__c=='Support CSAT' || s.SurveyType__c=='VAR Support CSAT'){
      if(s.Q1_Score__c == NULL || s.Q2_Score__c == NULL || s.Q3_Score__c == NULL || s.Q4_Score__c == NULL ||  s.Q5_Score__c == NULL ){
         allAnswered = false;
         return ApexPages.currentPage();
       }
       if(comment!=null && comment.length()>2000){
           allAnswered = true;
          return null;
       }
       s.Comments__c = comment;
      allAnswered = true;
      IsFilled = true;
      s.Responded__c = 1;
      s.Response_Date__c = Date.today();
      s.Average_Score__c = s.Q3_Score__c;
        }
        else if(s.SurveyType__c=='Implementation'){
          if(s.Q1_Score__c == NULL || s.Q2_Score__c == NULL || s.Q3_Score__c == NULL || s.Q4_Score__c == NULL ||  s.Q5_Score__c == NULL){
              allAnswered = false;
              return ApexPages.currentPage();
          }            
      allAnswered = true;
      IsFilled = true;
      s.Responded__c = 1;
      s.Response_Date__c = Date.today(); 
      s.Average_Score__c = s.Q3_Score__c;         
        }
        update s;
        return ApexPages.currentPage();
    }
   
    public string getContactName(){
        return c.name;
    }
}