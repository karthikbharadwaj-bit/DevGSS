public class AccountSurveyController {
    
    public String useVideoConference {get;set;}
    public String rating{get;set;}
    public Boolean showSurveyForm{get;set;}
    public Boolean showThankYou{get;set;}
    public Boolean showError{get;set;}
    
    public AccountSurveyController(){
        this.showSurveyForm = true;
        this.showThankYou = false;
        this.showError = false;
    }
    
    public List<SelectOption> getOptions() {
        
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('Yes','Yes'));
        options.add(new SelectOption('No','No'));
        return options;
    }
    
    public void getRating(){
        system.debug('Inside rating');
        system.debug(rating);
    }
    
    public void submitSurvey(){
        String idValue = ApexPages.currentPage().getParameters().get('id');
        system.debug('Survey record Id: '+idValue);
        system.debug('boolean: '+useVideoConference);
        system.debug('Rating: '+rating);
        
        if(idValue != null){
          Id recId = Id.valueOf(idValue);
          List<Survey__c> surveyRecord = [SELECT ATT_OH_Recommendation_Rating__c,  ATT_OH_Video_Conference_used__c FROM Survey__c WHERE Id = :recId];
          if(surveyRecord.size() > 0 && rating != null && useVideoConference != null)
          {
            surveyRecord[0].ATT_OH_Recommendation_Rating__c = rating;
            surveyRecord[0].ATT_OH_Video_Conference_used__c = useVideoConference;
            update surveyRecord[0];
            this.showSurveyForm = false;
            this.showThankYou = true;
        }        
        }
        else{
            this.showThankYou = false;
            this.showSurveyForm = false;
            this.showError= true;
        }
    }

}