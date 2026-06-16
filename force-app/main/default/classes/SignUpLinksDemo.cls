public class SignUpLinksDemo {
 String IEE = Apexpages.currentPage().getHeaders().put('X-UA-Compatible', 'IE=8');// For IE9
    public List<Id> finalList{get;set;}

    public Map<String, List<SelectOption>> currentMainServiceMap{get;set;}
    public Map<String, List<SelectOption>> retiredMainServiceMap{get;set;}
    public String ServiceValueTemp {get;set;}
    public String strUrlQueryString {get;set;}
    public String selectedMainService{get;set;}
    public Boolean newModel{get;set;}
    public String brandName{get;set;}
    public String strABT{get;set;}// 3/12/2015 Case#03409684
    String bcParam {get;set;} // Modified per case # 03802730
    public String signUpDoc {get;set;}

    List<String> serviceValue;
    Map<String, String> CurrencyMap = new Map<String, String>{ 'US' => 'US', 'UK' => 'UK','CAN'=>'CAN'};

    public String selectedValueOffering;
    private final Opportunity opp;
    private String tabName {get;set;}

    public boolean toShowSignUpPanel {get;set;}
    public string selectedPaymentMethod {get;set;}

    final string STR_CREDITCARD = 'CC';
    final string STR_INVOICE = 'INV';
    string billtype = STR_CREDITCARD;

    Campaign c;
    String BMID = '';
    String PID = '';
    String AID = '';
    String SPID;
    String promotion = '';
    String SAFID ='';
    String PartnerID ='';
    String strUrl;
    String strSignUpId;
    String strRedenderdValue;
    String taxExempt = '';
    Boolean setTaxExempt = false;

    public void setTabName(String n) {
       setSelectedValue('');
       selectPartnerOffer = null;
       selectedValueOffering = null;
       selectedValueRetired = null;
       strRedenderdValue = 'false';
       strUrl = null;
       tabName = n;
    }

    public String getTabName() {
      return tabName;
    }

   public String getSelectedValueOffering(){
       return selectedValueOffering;
   }
   public void setSelectedValueOffering(String selectedValueOffering){
       this.selectedValueOffering = selectedValueOffering;
   }

   public String selectedValueRetired;

   public String getSelectedValueRetired(){
       return selectedValueRetired;
   }
   public void setSelectedValueRetired(String selectedValueRetired){
       this.selectedValueRetired = selectedValueRetired;
   }


    public String getStrRedenderdValue() {
        return strRedenderdValue;
    }

    public void setStrRedenderdValue(String strRedenderdValue) {
        this.strRedenderdValue= strRedenderdValue;
    }
    //End Code added by India Team

    /*
    Find user SPID and information from the originatiing Opportunity.
    Determine is native Opportunity fields can be used for attribution if not then use campaignId passed from lead convert.
    */
    public SignUpLinksDemo(ApexPages.StandardController controller){
        signUpDoc = HardcodedIdsMapper.getMatchedObjectId('01580000000pYrO');
        tabName = 'US';
        toShowSignUpPanel = false;
        //	Code added by India Team
        strRedenderdValue = 'false';
        setSelectTrial('30');
        SelectedValue = '';
        //	End Code added by India Team

        try{
            newModel = Boolean.ValueOf(ApexPages.currentPage().getParameters().get('newModel'));
            system.debug('newModel: ' + newModel);
        }catch(Exception ex){
            newModel = false;
        }

        SPID = [SELECT PID__c FROM User WHERE Id =: UserInfo.getUserId()].PID__c;
        opp = [select id, name, StageName, brand_name__c, tier_name__c, pid__c,ad__c,adgrpid__c,afn__c,aid__c,bmid__c,kid__c,oid__c,
                product__c,rckw__c,rcmt__c,sid__c,CampaignId, Partner_ID__c,AccountId,Account.Payment_Method__c, Account.Number_of_POC_Users__c, Account.Tax_Exempt__c, Enable_Cost_Center_Management__c,
                (SELECT Status__c FROM Approvals__r where Status__c = 'Completed' and RecordType.Name = 'Invoicing Request' limit 1),
                (select Id, PriceBook2.Service__c from Quotes where status = 'Active' limit 1)
                from Opportunity where
                id = :ApexPages.currentPage().getParameters().get('id')];
        system.debug('this is Att from OPP: ' + opp.BMID__c + '/' + opp.PID__c + '/' + opp.AID__c);
        if(opp != null && opp.Approvals__r != null && opp.Approvals__r.size() >0 && !string.isBlank(opp.Account.Payment_Method__c)) {
            toShowSignUpPanel = true;
            selectedPaymentMethod = STR_INVOICE;
        }
        brandName = (opp.brand_name__c != null ? opp.brand_name__c : '');
        Boolean costCenter = opp.Enable_Cost_Center_Management__c;
        bcParam = ((costCenter == null || costCenter == false ? '0' : '1'));
        /*Add PartnerID*/
        if(opp.Partner_ID__c != NULL) {
            PartnerID = opp.Partner_ID__c;
        }

        taxExempt = opp.Account.Tax_Exempt__c ? 'true' : 'false';
        if (opp.Quotes != null && opp.Quotes.size() > 0) {
            Quote qt = opp.Quotes.get(0);
            if (qt.PriceBook2.Service__c == 'Office') {
                setTaxExempt = true;
            }
        }

        // Check Opp fields to see if we can use for attribution
        if((opp.BMID__c != null && opp.BMID__c != '') && (opp.PID__c != null && opp.PID__c != '')){
            // all attribution fields are filled in
            BMID = opp.BMID__c;
            PID = opp.PID__c;
            AID = opp.AID__c;
        }
        else if((opp.BMID__c != null && opp.BMID__c != '') && (opp.PID__c == null || opp.PID__c == '')){
            // only BMID field is filled in
            BMID = opp.BMID__c;
            PID = opp.PID__c;
            AID = opp.AID__c;
        }
        else if((opp.BMID__c == null || opp.BMID__c == '') && (opp.PID__c != null && opp.PID__c != '')){
            // only PID field is filled in
            BMID = opp.PID__c;
            PID = '';
            AID = opp.AID__c;
        }
        // even if AID has a value RC will not use it for attribution so skip to checking for campaign attribution
        else if(opp.CampaignId != null){
            // use campaign from primary campaign source field
            try{
                c = [SELECT Name,DNIS__c,AID__c,PID__c,BMID__c FROM Campaign WHERE id=:opp.CampaignId];
                system.debug('this is campaign name: ' + c.name + '. This is BMID/PID/AID: ' + c.BMID__c + '/' + c.PID__c + '/' + c.AID__c);

                if(c.BMID__c == null || c.BMID__c == ''){
                    if(c.PID__c == null || c.PID__c == ''){
                        BMID = '';
                        PID = '';
                    }
                    else {
                        BMID = c.PID__c;
                        PID = c.PID__c;
                    }
                }
                else{
                    BMID = c.BMID__c;

                    if(c.PID__c == null || c.PID__c == ''){
                        PID = '';
                    }
                    else{
                        PID = c.PID__c;
                    }
                }
                AID = c.AID__C;

            }
            catch(System.Exception e){
                // could not find campaign based on ID
            }
        }

        if(AID == null){
            AID = '';
        }

        if(!string.isBlank(opp.Account.Payment_Method__c) && opp.Account.Payment_Method__c == 'Invoice') {
            billtype = STR_INVOICE;
        }
    }

 	public String getBillType() {
        return billtype;
    }

    public String getPartnerID(){
        return PartnerID;
    }
    public String getBMID(){
        return BMID;
    }

    public String getAID(){
        return AID;
    }

    public String getPID(){
        return PID;
    }

    public String getSPID(){
        return (SPID == null ? '' : SPID);
    }

    public String getPromotion(){
        return promotion;
    }

    public String getOPPID(){
        return opp.Id;
    }

    public String getSAFID(){
        return SAFID;
    }

    public Boolean getIsNotAvailable(){
        if(!OpportunityHelper.isClosedOpp(opp.StageName) && !OpportunityHelper.isActiveOpp(opp.StageName)){
            return true;
        }
        return false;
    }

    //Code Added by India Team

    public String getStrUrl() {
        return strUrl;
    }

    public void setStrUrl(String strUrl) {
        this.strUrl= strUrl;
    }

    String selectTrial;
    public String getSelectTrial() {
        return selectTrial;
    }

    public void setSelectTrial(String selectTrial) {
        this.selectTrial= selectTrial;
    }

   String selectedValue;
    public String getSelectedValue() {
        return selectedValue;
    }

    public void setSelectedValue(String selectedValue) {
        this.selectedValue= selectedValue;
    }

    String strImageUrl;
    public String getStrImageUrl() {
        return strImageUrl;
    }

    public void setStrImageUrl(String strImageUrl) {
        this.strImageUrl= strImageUrl;
    }

    String selectPartnerOffer;
    public String getSelectPartnerOffer() {
        return selectPartnerOffer;
    }

    public void setSelectPartnerOffer(String selectPartnerOffer) {
        this.selectPartnerOffer= selectPartnerOffer;
    }

    Boolean blnSignUpType;
    public Boolean getBlnSignUpType() {
        return blnSignUpType;
    }

    public void setBlnSignUpType(Boolean blnSignUpType) {
        this.blnSignUpType= blnSignUpType;
    }

    public List<SelectOption> getServiceItemsOfferingUS() {
             return currentMainServiceMap.get('US');
    }

    public List<SelectOption> getServiceItemsRetiredUS() {
          return retiredMainServiceMap.get('US');
    }

    public List<SelectOption> getServiceItemsOfferingCAN() {
           return currentMainServiceMap.get('CAN');
    }

    public List<SelectOption> getServiceItemsRetiredCAN() {
          return retiredMainServiceMap.get('CAN');
    }

    public List<SelectOption> getServiceItemsOfferingUK() {
           return currentMainServiceMap.get('UK');
    }

    public List<SelectOption> getServiceItemsRetiredUK() {
           return retiredMainServiceMap.get('UK');
    }

     // Added by India Team
	public List<SelectOption>  getTrialItems(){
		List<SelectOption> options = new List<SelectOption>();
        if(opp.Account.Number_of_POC_Users__c != null && opp.Account.Number_of_POC_Users__c != 0){
			options.add(new SelectOption('trial30nocc','POC Account'));
       	}
       	options.add(new SelectOption('30','Buy Now'));
       	return options;
     }

     public List<SelectOption> getPaymentItems(){
       List<SelectOption> options = new List<SelectOption>();
       options.add(new SelectOption(STR_INVOICE,'Invoice'));
       options.add(new SelectOption(STR_CREDITCARD,'Credit Card'));
       return options;
     }

    public PageReference doSearch()
    {
        promotionsList = getPromotionItems();

        return null;
    }

    public String getStrSignUpId() {
        return strSignUpId;
    }

    public void setStrSignUpId(String strSignUpId) {
        this.strSignUpId= strSignUpId;
    }

    string strBillingFreq;
    public List<SelectOption> promotionsList{get;set;}
    public List<SelectOption> getPromotionItems() {
        List<SelectOption> options = new List<SelectOption>();
        ServiceValueTemp = '';

       if(getSelectedValue()!= null && getSelectedValue()!=''){
            ServiceValueTemp = getSelectedValue();
            blnSignUpType = true;
        } else if(getSelectPartnerOffer()!= null){
            ServiceValueTemp = getSelectPartnerOffer();
            blnSignUpType = false;
        } else if(selectedValueOffering != null){
            ServiceValueTemp = selectedValueOffering;
            blnSignUpType = true;
        } else  if(selectedValueRetired != null){
            ServiceValueTemp = selectedValueRetired;
            blnSignUpType = true;
        }

        strRedenderdValue = 'true';
        strImageUrl = '';
       return options;
    }
     public String createParam(String strUrlQueryString, String inputParam, String inputValue) {
        if((inputValue != null && inputValue.trim().length() != 0) || (inputParam == 'SPID')) {
            return (strUrlQueryString != null & strUrlQueryString.indexOf('?') != -1 ? '&' : '?') + inputParam + inputValue;
        }
        return '';
    }
   public String selectedPromotion{get;set;}

    // Added by India Team
    public PageReference doSAve() {
      	String strMainServiceUrl = getStrUrl();
   		strUrlQueryString = '';
   		if(selectTrial != null && toShowSignUpPanel == true && (selectTrial.equals('30D') || selectTrial.equals('7D'))) {
      		selectedPaymentMethod = STR_CREDITCARD;
  		}
        if(blnSignUpType != null && blnSignUpType == true) {
            if(getSelectTrial().equals('30D')){
                strUrlQueryString += '?action=trial30';
            }
            if(getSelectTrial().equals('trial30nocc')){
            	strUrlQueryString += '?action=trial30nocc';
            }
         	strUrlQueryString += createParam(strUrlQueryString, 'BMID=', getBMID());
         	strUrlQueryString += createParam(strUrlQueryString, 'PID=', getPID());
         	strUrlQueryString += createParam(strUrlQueryString, 'AID=', getAID());
         	strUrlQueryString += createParam(strUrlQueryString, 'SPID=', getSPID());
         	strUrlQueryString += createParam(strUrlQueryString, 'OPPID=', getOPPID());
         	strUrlQueryString += createParam(strUrlQueryString, 'PartnerID=', getPartnerID());
            strUrlQueryString += createParam(strUrlQueryString, 'billtype=', selectedPaymentMethod);
         	if (setTaxExempt) {
                strUrlQueryString += createParam(strUrlQueryString, 'exemptFromStateAndLocalTaxes=', taxExempt);
            }
            if(!String.isBlank(strBillingFreq) && strBillingFreq == 'Annual') {
  				strUrlQueryString += createParam(strUrlQueryString, 'annual=' ,'true');
          	}
          	if(!String.isBlank(strABT)) {
                strUrlQueryString += createParam(strUrlQueryString, 'abt=' ,strABT); // 3/12/2015 Case# 03409684
            }
        } else {
            strUrlQueryString+= createParam(strUrlQueryString,'OPPID=', getOPPID());
            strUrlQueryString+= createParam(strUrlQueryString,'SPID=', getSPID());
            strUrlQueryString+= createParam(strUrlQueryString, 'PartnerID=' ,getPartnerID());
            strUrlQueryString += createParam(strUrlQueryString, 'billtype=' ,selectedPaymentMethod);
            if(!String.isBlank(strBillingFreq) && strBillingFreq == 'Annual') {
  				 strUrlQueryString += createParam(strUrlQueryString, 'annual=' ,'true');
          	}
        }
        strUrlQueryString += createParam(strUrlQueryString, 'bc=' , bcParam);
        System.debug(' #### bcParam = ' + bcParam);
        if(getSAFID() != NULL && getSAFID() != '') {
            System.debug('----------->'+ SAFID);
            strUrlQueryString+= createParam(strUrlQueryString,'SAFID=',getSAFID());
            strUrlQueryString+= createParam(strUrlQueryString, 'PartnerID=' ,getPartnerID());
        }
        String strHardCodeUrl = 'http://www.ringcentral.com/salesforce_redirect.html?redir=';
        PageReference opptyPage = new PageReference(strHardCodeUrl+strMainServiceUrl+strUrlQueryString);

        System.debug('#############################'+strUrlQueryString);
        System.debug('############################'+opptyPage.getUrl());
        System.debug('############################'+getPartnerID());

        strUrlQueryString = strHardCodeUrl+strMainServiceUrl+strUrlQueryString;
        try {
        SignupHistory__c insertUser = new SignupHistory__c();
        String userNm = UserInfo.getUserId();
        User activeUser = [Select Email From User where id = :userNm ];
        String userEmail = '';
        if(activeUser!=null && activeUser.Email!=null) {
            userEmail = activeUser.Email;
        }
        insertUser.UserEmail__c = userEmail;
        insertUser.SignUpLink__c = strMainServiceUrl+strUrlQueryString;
        insertUser.LaunchDate__c = Date.today();
        insertUser.Opportunity__c = getOPPID();

           insert insertUser;
        } catch(Exception e) {ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getStackTraceString() )); }
   opptyPage.setRedirect(true);
  return opptyPage;
    }
   public PageReference resetAll(){
     return null;
   }
   public PageReference selectTab() {
           return null;
    }
}