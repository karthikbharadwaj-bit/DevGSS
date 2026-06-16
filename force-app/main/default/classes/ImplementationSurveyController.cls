/* This Survey Controller Class create a survey of following
    this is a completely Dynamic generated surveys.
1.  Implementation
2.  ATT Implementation
3.  Rogers Implementation
*/

public class ImplementationSurveyController {

    /****************************************************
    properities  and variable declaration section
    ******************************************************/
    public Survey__c surveyObj{get;set;}
    @testVisible private String surveyType;
    private String caseSubject;
    public Boolean respondFlag{get;set;}
    public Boolean isEmpty{get;set;}
    public Boolean thanksFlag{get;set;}
    public Boolean rogersFooterFlag{get;set;} // for Rogers Survey
    public Boolean rogersHeaderFlag{get;set;}
    public Boolean errorFlag{get;set;}
    public Boolean caseSubjectCheck{get;set;}
    public boolean isExpired{set;get;}

    public Integer q1Value {get;set;}
    public Integer q2Value {get;set;}
    public Integer q3Value {get;set;}
    public Integer q4Value {get;set;}
    public Integer q6value {get;set;}
    public Integer q7value {get;set;}
    public Integer q71value {get;set;}
    public Integer q72value {get;set;}
    public Integer q73value {get;set;}
    public Integer q74value {get;set;}
    public String comments {get;set;}


    public Integer psquestion1 {get;set;}
    public Integer psquestion11 {get;set;}
    public Integer psquestion12 {get;set;}
    public Integer psquestion13 {get;set;}
    public Integer psquestion14 {get;set;}
    public String pscomment {get;set;}

    public Integer pndquestion1 {get;set;}
    public Integer pndquestion11 {get;set;}
    public Integer pndquestion12 {get;set;}
    public Integer pndquestion13 {get;set;}
    public String pndimprove {get;set;}
    public String pndcomment {get;set;}

    public Integer osdquestion1 {get;set;}
    public Integer osdquestion11 {get;set;}
    public Integer osdquestion12 {get;set;}
    public Integer osdquestion13 {get;set;}
    public Integer osdquestion14 {get;set;}
    public Integer osdquestion15 {get;set;}
    public String osdcomment {get;set;}
    public String brand {get;set;}
    public Map<String, Rise_Partner_CRM_Configuration__c> risePartnerSettings { get; set; }
    public Boolean isRiseBrand { get; set; }
    public Rise_Partner_CRM_Configuration__c riseBrandConfig { get; set; }

    public Component.Apex.Image getRogersFooter() {
        Component.Apex.Image rogersFooter = new  Component.Apex.Image();
        rogersFooter.expressions.url = '{!URLFOR($Resource.rogers_survey_logo)}';
        return rogersFooter;
    }
    public Component.Apex.Image getRogersHeader() {
        Component.Apex.Image rogersHeader = new  Component.Apex.Image();
        return rogersHeader;
    }

    public Component.apex.outputText getThanksMsg(){
        Component.apex.outputText msg = new Component.apex.outputText();
        msg.value = '<b>Thank you for filling out our survey.</b>';
        msg.expressions.rendered = '{!thanksFlag}';
        msg.escape = false;
        return msg;
    }

    public Component.Apex.Image getLogo(){
        Component.Apex.Image logo = new  Component.Apex.Image();
        if(SurveyType == 'Rogers Implementation'){
            rogersFooterFlag = true;
            rogersHeaderFlag = true;
            logo.expressions.url = '{!URLFOR($Resource.rogers_survey_header)}';
            return logo;
        }
        if(SurveyType == 'Implementation' || SurveyType == 'Professional Services'){
            if(isBTBrand()){
                logo.expressions.url = '{!URLFOR($Resource.BTLogo)}';
            }else if(isVodafoneBusinessWithRingCentralBrand()){
                logo.expressions.url  = '{!$Resource.VodafoneBusinesswithRingCentralBrand1}';
            }else if(isFrontierWithRingCentralBrand()){
                logo.expressions.url  = '{!$Resource.FrontierwithRingCentral}';
            } else if (isRiseBrand) {
               logo.expressions.url = '{!URLFOR($Resource.' + riseBrandConfig.Identifier__c.replaceAll('\\s+', '').replaceAll('^\\d+', '')  + 'Logo)}';
            } else{
                logo.expressions.url = '{!URLFOR($Resource.RcLogo2018)}';
            }
            return logo;
        }
        if(SurveyType == 'ATT Implementation'){
            logo.expressions.url  = '{!$Resource.ATTSurveyHeader}';
            logo.width = '646px';
            return logo;
        }
        return null;
    }

    public Component.apex.outputText getAlradyFilled() {
        if(RespondFlag != NULL && RespondFlag == true) {
            Component.apex.outputText msg = new Component.apex.outputText();
            msg.value = '<b>You have already filled this survey.</b>';
            msg.escape = false;
            return msg;
        }
        return null;
    }
/**********************************************************
                The Constructor
**********************************************************/
  public ImplementationSurveyController() {

        String surveyId;
      try{
            surveyObj = new Survey__c();
            risePartnerSettings = new Map<String, Rise_Partner_CRM_Configuration__c>();
            isRiseBrand = false;
            riseBrandConfig = new Rise_Partner_CRM_Configuration__c();
            isExpired = false;
            surveyId = ApexPages.currentPage().getParameters().get('id');
            surveyObj = [SELECT Id,Implementation__r.brand__c, Implementation__r.OnsiteDeployment__c,
                                Implementation__r.PlanningAndDesign__c, Implementation__r.ProfessionalServices__c,
                                OverallProjectManagerSatisfaction__c,ProjectManagerKnowledge__c,
                                ProjectCommunication__c, ResponseTiming__c, BestInterestActing__c,
                                ProjectManagementComments__c, OverallPlanningAndDesignSatisfaction__c,
                                PlanningAndDesignLength__c, PlanningAndDesignProfessionality__c,
                                PlanningAndDesignKnowledgeTransfer__c, PlanningAndDesignImprovements__c,
                                PlanningAndDesignComments__c, OverallOnsiteDeploymentSatisfaction__c,
                                OnsiteTeamKnowledge__c, OnsiteDeploymentInformation__c,
                                OnsiteDeploymentExecution__c, OnsiteTeamTimeSpent__c, OnsiteTraining__c,
                                OnsiteDeploymentComments__c, Name,Q1_Score__c,Q2_Score__c,
                                Implementation_Advisor_Communication__c,Case_Number__c,Case_Subject__c,
                                Q3_Score__c,Implementation_Materials_provided__c, Implementation_Porting_Satisfaction__c,
                                Implementation_Advisor_Satisfaction__c,Q4_Score__c,Average_Score__c,
                                Comments__c,Implementation_Advisor_s_ability__c,Contact__c,
                                Implementation_Experience__c, Contact__r.Name,
                                Responded__c, SurveyType__c,CreatedDate , Response_Date__c,
                                Account__r.Number_of_DL_s__c,Account__r.RC_Service_name__c,Implementation__r.Sub_brand__c
                            FROM Survey__c WHERE id=: surveyId];
            System.debug('Survey obj: ' + surveyObj.Implementation__r.ProfessionalServices__c);
            risePartnerSettings  = Rise_Partner_CRM_Configuration__c.getAll();
            if(surveyObj != null && surveyId != null){
                setResponseValue();
                brand = (String.isNotBlank(surveyObj.Implementation__r.brand__c)) ? surveyObj.Implementation__r.brand__c : 'RingCentral';
            }
            if(surveyObj != null && surveyObj.SurveyType__c != null){
                surveyType = surveyObj.SurveyType__c;
            }
            if(surveyObj != null && surveyObj.SurveyType__c == 'Implementation' || surveyObj.SurveyType__c == 'Professional Services') {
                setResponseValue();
                System.debug('========>');
            }
            if(surveyObj.Responded__c  != NULL) {
                 if(String.valueOf(ApexPages.currentPage()).contains('ImplementationSurveyPreview')){
                    respondFlag = false;
                    isEmpty = true;
                 }else{
                    respondFlag = true;
                    isEmpty = false;
                 }
            } else {
                isEmpty = true;
            }
            if(surveyObj != null && surveyObj.Implementation__c != null && string.isNotBlank(surveyObj.Implementation__r.Sub_brand__c)) {
                isRiseBrand = risePartnerSettings.containsKey(surveyObj.Implementation__r.Sub_brand__c);
                if (isRiseBrand) {
                    riseBrandConfig = risePartnerSettings.get(surveyObj.Implementation__r.Sub_brand__c);
                }
            }
        } catch (Exception ex) {
            System.debug('inavlid survey -'+ ex.getMessage());
             errorFlag = true;
        }
        checkSurveyAlreadyFilled();
        isSurveyExpired();
        Apexpages.currentPage().getHeaders().put('X-UA-Compatible', 'IE=Edge');

  }
  /**************************Contructor Ends here *************************************/


   /**************************************************************
  *@param .....: void                                            *
  *@return.....: void                                            *
  *@Discription: this method is used check that survey is        *
                 already filled                                  *
  ****************************************************************/
   public boolean checkSurveyAlreadyFilled() {
        try {
            if(surveyObj.Responded__c == 1) {
                if(isVodafoneBusinessWithRingCentralBrand()){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,'<b>Sie haben diese Umfrage bereits ausgefüllt.</b>'));
                    return true;
                }
                else{
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,'<b>You have already filled this survey.</b>'));
                    return true;
                }
            }
        } catch(Exception ex) {
            if(isVodafoneBusinessWithRingCentralBrand()){
                 ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Ausnahme aufgetreten.'));
            }
            else{
                 ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Exception Occured.'));
            }
           
        }
        return false;
    }
  /***************************************************************
  *@param .....:  void                                           *
  *@return.....: void                                            *
  *@Discription: show the value on preview page                  *
  ****************************************************************/
   public void setResponseValue() {                             // For Showing Preview. surveyObj.Implementation_Advisor_s_ability__c = q72Value;

        try {
            q1Value = Integer.valueOf(surveyObj.Q1_Score__c);
            q2Value = Integer.valueOf(surveyObj.Q2_Score__c);
            q3Value = Integer.valueOf(surveyObj.Q3_Score__c);
            q4Value = Integer.valueOf(surveyObj.Q4_Score__c);
            q6Value = Integer.valueOf(surveyObj.Implementation_Experience__c) ;
            q73Value = Integer.valueOf(surveyObj.Implementation_Advisor_Communication__c);
            q71Value = Integer.valueOf(surveyObj.Implementation_Advisor_Satisfaction__c) ;
            q72Value = Integer.valueOf(surveyObj.Implementation_Advisor_s_ability__c) ;
            q74Value = Integer.valueOf(surveyObj.Implementation_Materials_provided__c);
            comments = surveyObj.Comments__c;

            psquestion1 = Integer.valueOf(surveyObj.OverallProjectManagerSatisfaction__c);
            psquestion11 = Integer.valueOf(surveyObj.ProjectManagerKnowledge__c);
            psquestion12 = Integer.valueOf(surveyObj.ProjectCommunication__c);
            psquestion13 = Integer.valueOf(surveyObj.ResponseTiming__c);
            psquestion14 = Integer.valueOf(surveyObj.BestInterestActing__c);
            pscomment = surveyObj.ProjectManagementComments__c;

            pndquestion1 = Integer.valueOf(surveyObj.OverallPlanningAndDesignSatisfaction__c);
            pndquestion11 = Integer.valueOf(surveyObj.PlanningAndDesignLength__c);
            pndquestion12 = Integer.valueOf(surveyObj.PlanningAndDesignProfessionality__c);
            pndquestion13 = Integer.valueOf(surveyObj.PlanningAndDesignKnowledgeTransfer__c);
            pndimprove = surveyObj.PlanningAndDesignImprovements__c;
            pndcomment = surveyObj.PlanningAndDesignComments__c;

            osdquestion1 = Integer.valueOf(surveyObj.OverallOnsiteDeploymentSatisfaction__c);
            osdquestion11 = Integer.valueOf(surveyObj.OnsiteTeamKnowledge__c);
            osdquestion12 = Integer.valueOf(surveyObj.OnsiteDeploymentInformation__c);
            osdquestion13 = Integer.valueOf(surveyObj.OnsiteDeploymentExecution__c);
            osdquestion14 = Integer.valueOf(surveyObj.OnsiteTeamTimeSpent__c);
            osdquestion15 = Integer.valueOf(surveyObj.OnsiteTraining__c);
            osdcomment = surveyObj.OnsiteDeploymentComments__c;
        } catch(exception e){}
  }

    public List<SelectOption> getValues3() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('0','0'));
        options.add(new SelectOption('1','1'));
        options.add(new SelectOption('2','2'));
        options.add(new SelectOption('3','3'));
        options.add(new SelectOption('4','4'));
        options.add(new SelectOption('5','5'));
        options.add(new SelectOption('6','6'));
        options.add(new SelectOption('7','7'));
        options.add(new SelectOption('8','8'));
        options.add(new SelectOption('9','9'));
        options.add(new SelectOption('10','10'));
        return options;
    }

    public String getFooter(){
        String footer = '';
        if(isBTBrand()) {
            footer = '<br/>Thank you for taking the time to give us feedback!';
        } else if (isVodafoneBusinessWithRingCentralBrand()){
            return '<br/>Vielen Dank für Ihr Feedback.';
        } else if (isFrontierWithRingCentralBrand()){
            footer = '<br/>Thank you for your feedback. <br/><br/>For more information, check out <a href="https://business.frontier.com/unified-communications">https://business.frontier.com/unified-communications</a> today!<br/><br/>';
        } else if (isRiseBrand) {
            footer = '<br/>Thank you for your feedback.<br/><br>For more information, check out <u>success.ringcentral.com</u> today! &nbsp; <br/><br/>';
        } else {
            footer = '<br/>Thank you for taking the time to give us feedback! <br/>Did you know you can create Support cases using the Web? Checkout <a  href ="http://success.ringcentral.com/RCContactSupp" target="_blank">success.ringcentral.com</a>&nbsp; today!!  <br/><br/>';
        }
        if(String.valueOf(ApexPages.currentPage()).contains('ImplementationSurveyPreview')){
             footer = '<br/>Thank you for taking the time to give us feedback! <br/>Did you know you can create Support cases using the Web? Checkout <u>success.ringcentral.com</u> &nbsp; today!!  <br/><br/>';
        }
        return footer;
    }
    
    public String getHeader(){
        if(isBTBrand()){
            return '<p><b>We would like to thank you for taking the time to provide your feedback regarding<br/> your Technical Onboarding experience. It should take about a minute to complete.<p>';
        }else if(isVodafoneBusinessWithRingCentralBrand()){
            return '';
        }else if(isFrontierWithRingCentralBrand()){
            return '</br>We at Frontier Technical Onboarding would like to thank you for taking the time to provide your feedback regarding your Technical Onboarding experience. It should take about a minute to complete.';
        } else if (isRiseBrand) {
            return '<p>We at ' + riseBrandConfig.Identifier__c + ' with RingCentral Technical Onboarding would like to thank you for taking the time to provide your feedback regarding your Technical Onboarding experience. It should take about a minute to complete.<p>';
        } else {
            return '<p><b>We at RingCentral would like to thank you for taking the time to provide your feedback regarding<br/> your Technical Onboarding experience. It should take about a minute to complete.<p>';
        }
    }

  /***************************************************************
  *@param .....:  void                                           *
  *@return.....:   Component.apex.outputText                      *
  *@Discription: show page message on survey page                *
  ****************************************************************/
    public String getUserMsg() {
         if(isBTBrand()){
            return 'Hello,';
         }else if(isVodafoneBusinessWithRingCentralBrand()){
            return '';
        }
        else{
            return 'Hello '+ (surveyObj != NULL  && surveyObj.Contact__r != NULL ? surveyObj.Contact__r.Name : '');
         }
    }

  /***************************************************************
  *@param .....:  void                                           *
  *@return.....:  Component.apex.outputText                      *
  *@Discription: Component.apex.outputText on survey Page                  *
  ****************************************************************/
    public String getQ7(){
        if(isBTBrand()){
            return '<b><font color=black> Thinking about your experience with the BT Cloud Phone Technical Onboarding Advisor <br/> who assisted you, please rate your level of satisfaction with the following </font></b><br/>';
        }else if(isFrontierWithRingCentralBrand()){
            return '<br/>Thinking about your experience with Frontier Technical Onboarding Advisor who assisted you, please rate your level of satisfaction with the following.<br/>';
        } else if (isRiseBrand) {
            return '<p>Thinking about your experience with ' + riseBrandConfig.Identifier__c + ' with RingCentral Technical Onboarding Advisor who assisted you, please rate your level of satisfaction with the following.</p>';
        }  else{
            return '<b><font color=black> Thinking about your experience with the RingCentral Technical Onboarding Advisor <br/> who assisted you, please rate your level of satisfaction with the following </font></b><br/>';
        }
    }
   /***************************************************************
  *@param .....:  void                                           *
  *@return.....:  Component.apex.outputText                      *
  *@Discription: show Component.apex.outputText on survey Page                  *
  ****************************************************************/
  public String getQ74(){
        if(isBTBrand()){
            return '&nbsp; &nbsp;<font color=red>*</font>4. Materials provided to you during your Technical Onboarding.<br/>&nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color =#798496>(0 Not at all Satisfied and 10 extremely satisfied)</font>';
        }else if(isFrontierWithRingCentralBrand()){
            return '4. Materials provided to you during your Technical Onboarding (i.e. Frontier with Ringcentral App, etc.)';
        }else{
            return '&nbsp; &nbsp;<font color=red>*</font>4. Materials provided to you during your Technical Onboarding (i.e., Customer On-Boarding Guide, RC Meetings, etc.).<br/>&nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color =#798496>(0 Not at all Satisfied and 10 extremely satisfied)</font>';
        }
  }

  /****************************************************************
  *@param .....: void                                             *
  *@return.....: PageReference                                    *
  *@Discription: This function is used to save the survey         *
  *****************************************************************/
  public PageReference save() {
      Integer live = 0; // in the case if somehow survey is deleted recheck the survey still alive or not
      live = [SELECT count() FROM Survey__c WHERE id=:ApexPages.currentPage().getParameters().get('id')];

      if(live == 0) {
          errorFlag = true;
          respondFlag = false;
          isEmpty = false;
          thanksFlag = false;
          rogersFooterFlag = false;
          rogersHeaderFlag = false;
          return null;
      }

      if (surveyObj.Implementation__r.ProfessionalServices__c != true && (q71Value== null || q72Value == null ||  q73Value == null) ||
            (surveyObj.Implementation__r.ProfessionalServices__c == true && (psquestion1 == null ||
            (surveyObj.Implementation__r.PlanningAndDesign__c ==  true && pndquestion1 == null) ||
            (surveyObj.Implementation__r.OnsiteDeployment__c ==  true && osdquestion1 == null)
            ))){
          ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please answer all the required questions.'));
          return ApexPages.currentPage();
      } else if(isVodafoneBusinessWithRingCentralBrand()){
          surveyObj.Implementation_Advisor_s_ability__c = q72Value;
          surveyObj.Implementation_Materials_provided__c = q74Value;
          surveyObj.Implementation_Advisor_Communication__c = q73Value;
          surveyObj.Implementation_Advisor_Satisfaction__c = q71Value;
          surveyObj.Comments__c = comments;
          if(surveyObj.Account__r.Number_of_DL_s__c != null){
              surveyObj.Snapshot_Number_of_DLs__c = surveyObj.Account__r.Number_of_DL_s__c;
          }
          if(surveyObj.Account__r.RC_Service_name__c != null){
              surveyObj.Snapshot_Service_Name__c = surveyObj.Account__r.RC_Service_name__c;
          }
          surveyObj.Responded__c = 1;
          surveyObj.Response_Date__c = System.Today();
           isEmpty = false;
          thanksFlag = true;

          update surveyObj;
          ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info,'<b>Vielen Dank, dass Sie an unserer Umfrage teilgenommen haben.</b>'));
      }
      else if(isFrontierWithRingCentralBrand()){
          surveyObj.Implementation_Advisor_s_ability__c = q72Value;
          surveyObj.Implementation_Materials_provided__c = q74Value;
          surveyObj.Implementation_Advisor_Communication__c = q73Value;
          surveyObj.Implementation_Advisor_Satisfaction__c = q71Value;
          surveyObj.Comments__c = comments;
          if(surveyObj.Account__r.Number_of_DL_s__c != null){
              surveyObj.Snapshot_Number_of_DLs__c = surveyObj.Account__r.Number_of_DL_s__c;
          }
          if(surveyObj.Account__r.RC_Service_name__c != null){
              surveyObj.Snapshot_Service_Name__c = surveyObj.Account__r.RC_Service_name__c;
          }
          surveyObj.Responded__c = 1;
          surveyObj.Response_Date__c = System.Today();
           isEmpty = false;
          thanksFlag = true;

          update surveyObj;
          ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info,'<b>Thank you for filling out our survey.</b>'));
      }
      else {
          surveyObj.Implementation_Advisor_s_ability__c = q72Value;
          surveyObj.Implementation_Materials_provided__c = q74Value;
          surveyObj.Implementation_Advisor_Communication__c = q73Value;
          surveyObj.Implementation_Advisor_Satisfaction__c = q71Value;
          surveyObj.Implementation_Experience__c = q6Value;
          surveyObj.Comments__c = comments;
          if(surveyObj.Account__r.Number_of_DL_s__c != null){
              surveyObj.Snapshot_Number_of_DLs__c = surveyObj.Account__r.Number_of_DL_s__c;
          }
          if(surveyObj.Account__r.RC_Service_name__c != null){
              surveyObj.Snapshot_Service_Name__c = surveyObj.Account__r.RC_Service_name__c;
          }
          surveyObj.Responded__c = 1;
          surveyObj.Response_Date__c = System.Today();

          surveyObj.OverallProjectManagerSatisfaction__c = psquestion1;
          surveyObj.ProjectManagerKnowledge__c = psquestion11;
          surveyObj.ProjectCommunication__c = psquestion12;
          surveyObj.ResponseTiming__c = psquestion13;
          surveyObj.BestInterestActing__c = psquestion14;
          surveyObj.ProjectManagementComments__c = pscomment;

          surveyObj.OverallPlanningAndDesignSatisfaction__c = pndquestion1;
          surveyObj.PlanningAndDesignLength__c = pndquestion11;
          surveyObj.PlanningAndDesignProfessionality__c = pndquestion12;
          surveyObj.PlanningAndDesignKnowledgeTransfer__c = pndquestion13;
          surveyObj.PlanningAndDesignImprovements__c = pndimprove;
          surveyObj.PlanningAndDesignComments__c = pndcomment;

          surveyObj.OverallOnsiteDeploymentSatisfaction__c = osdquestion1;
          surveyObj.OnsiteTeamKnowledge__c = osdquestion11;
          surveyObj.OnsiteDeploymentInformation__c = osdquestion12;
          surveyObj.OnsiteDeploymentExecution__c = osdquestion13;
          surveyObj.OnsiteTeamTimeSpent__c = osdquestion14;
          surveyObj.OnsiteTraining__c = osdquestion15;
          surveyObj.OnsiteDeploymentComments__c = osdcomment;

          update surveyObj;
          isEmpty = false;
          thanksFlag = true;
          ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info,'<b>Thank you for filling out our survey.</b>'));
      }


      return null;
  }

  /****************************************************************
  *@param .....: void                                             *
  *@return.....: void                                             *
  *@Discription: if survey is created more then 30day send error  *
  *              link is expired.                                 *
  *****************************************************************/
  public void isSurveyExpired(){
        try{
        Date createdDate = surveyObj.CreatedDate.date();
        Date todaysDate = System.Today();
        Integer days = createdDate.daysBetween(todaysDate);
        if(days >=30 && surveyObj.Responded__c == NULL ){
            if(isVodafoneBusinessWithRingCentralBrand()){
                 isExpired = true;
                 ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info,'<b>Dieser Link ist abgelaufen.</b>'));
                System.debug('true');
            }
            else{
                isExpired = true;
                 ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info,'<b>This link has expired. If you need any help, '+
                                                                'please contact "Technical Onboarding Advisors"  at "(866) 737-7704".</b>'));
                System.debug('true');
            }
        }else{
            system.debug('false');
        }
        }catch(Exception e){System.debug('@@@@@@@@');
        }

  }

    public boolean isBTBrand(){
        if( surveyObj != null && surveyObj.Implementation__c != null && !string.isBlank(surveyObj.Implementation__r.brand__c) &&
            surveyObj.Implementation__r.brand__c.containsIgnoreCase('BT') ){
            return true;
        }
        return false;
    }
    public boolean isVodafoneBusinessWithRingCentralBrand(){
        if( surveyObj != null && surveyObj.Implementation__c != null && !string.isBlank(surveyObj.Implementation__r.brand__c) &&
            surveyObj.Implementation__r.brand__c.containsIgnoreCase('Vodafone Business with RingCentral') ){
            return true;
        }
        return false;
    }
    public boolean isFrontierWithRingCentralBrand(){
        if( surveyObj != null && surveyObj.Implementation__c != null && !string.isBlank(surveyObj.Implementation__r.brand__c) &&
            surveyObj.Implementation__r.brand__c.containsIgnoreCase('Frontier with RingCentral') ){
            return true;
        }
        return false;
    }

}