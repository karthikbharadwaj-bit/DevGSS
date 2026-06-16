public class SignUpCustomer {
 	String IEE = Apexpages.currentPage().getHeaders().put('X-UA-Compatible', 'IE=8');// For IE9 
    public List<Id> finalList{get;set;}
    public Map<String, List<SelectOption>> currentMainServiceMap{get;set;}
    public Map<String, List<SelectOption>> retiredMainServiceMap{get;set;}
    public String ServiceValueTemp {get;set;}
    public String strUrlQueryString {get;set;}
    public String selectedMainService{get;set;}
	String bcParam {get;set;} // Modified per case # 03802730
	
    List<String> serviceValue;
    Map<String, String> CurrencyMap = new Map<String, String>{ 'US' => 'US', 'UK' => 'UK','CAN'=>'CAN'}; 

    public String selectedValueOffering;
    private final Opportunity opp;
    private String tabName = 'US';
    
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
    String SID = '';
    String promotion = '';
    String SAFID ='';
    String PartnerID ='';
    String strUrl;
    String strSignUpId;
    String strRedenderdValue;
    
    /*
    Find user SPID and information from the originatiing Opportunity.
    Determine is native Opportunity fields can be used for attribution if not then use campaignId passed from lead convert.
    */
    public boolean isPartnerUserPro {get;set;}
    public boolean isAdminOrNonPartnerPro {get;set;}
    public string oppBrandName {get;set;}
    public SignUpCustomer(ApexPages.StandardController controller){
 		toShowSignUpPanel = false;
 		isPartnerUserPro = false;
 		isAdminOrNonPartnerPro = false;	
     	setUserProfileBasedVar();
        
        opp = [select id, name, StageName, brand_name__c, tier_name__c, pid__c,ad__c,adgrpid__c,afn__c,aid__c,bmid__c,kid__c,oid__c,
                product__c,rckw__c,rcmt__c,sid__c,CampaignId, Partner_ID__c,AccountId,Account.Payment_Method__c,Account.Number_of_POC_Users__c,Enable_Cost_Center_Management__c,
                 Account.PID__c, Account.BMID__c, Account.AID__c,Account.Sid__c,
                (SELECT Status__c FROM Approvals__r where Status__c = 'Completed' and RecordType.Name = 'Invoicing Request' limit 1),
                (select Id from Quotes where status = 'Active' limit 1)
                from Opportunity where 
                id = :ApexPages.currentPage().getParameters().get('id')];
        system.debug('this is Att from OPP: ' + opp.BMID__c + '/' + opp.PID__c + '/' + opp.AID__c);
        if(opp != null && opp.Approvals__r != null && opp.Approvals__r.size() >0 && !string.isBlank(opp.Account.Payment_Method__c)) {
       		toShowSignUpPanel = true;
       		selectedPaymentMethod = STR_INVOICE;
     	}
     	if(opp != null) {
     		oppBrandName = opp.brand_name__c == null ? 'RingCentral': opp.brand_name__c;
     	}
     	
     	if(Userinfo.getUserType() == 'PowerPartner') {
     		User userObj = [SELECT contact.Account.Partner_ID__c,contact.Account.PID__c,contact.Account.AID__c,contact.Account.SID__c,
     						contact.Account.BMID__c 	 
     						FROM User WHERE Id =: UserInfo.getUserId()];
     		if(userObj != null) {
     			PartnerID = userObj.contact.Account.Partner_ID__c;
     			PID = userObj.contact.Account.PID__c;
     			BMID = userObj.contact.Account.BMID__c;
     			AID = userObj.contact.Account.AID__c;
     			SID = userObj.contact.Account.SID__c;
     		}
     	} else if(opp.Partner_ID__c != NULL) {
     		System.Debug('>>2>23>' + opp.Partner_ID__c);
     		List<Account> partnerAccDetObj = [select PID__c,BMID__c,AID__c,SID__c from account where Partner_ID__c = :opp.Partner_ID__c
     											and RecordType.Name = 'Partner Account' limit 1];
     		if(partnerAccDetObj != null && partnerAccDetObj.size() == 1) {
     			PartnerID = opp.Partner_ID__c;
     			PID = partnerAccDetObj[0].PID__c;
     			BMID = partnerAccDetObj[0].BMID__c;
     			AID = partnerAccDetObj[0].AID__c;
     			SID = partnerAccDetObj[0].SID__c;
     		}									
     	}
     	Boolean costCenter = opp.Enable_Cost_Center_Management__c;
        bcParam = ((costCenter == null || costCenter == false ? '0' : '1'));

        if(!string.isBlank(opp.Account.Payment_Method__c) && opp.Account.Payment_Method__c == 'Invoice') {
             billtype = STR_INVOICE;
        }
        strRedenderdValue = 'false';
        setSelectTrial('30');
        SelectedValue = '';
    }
    
    public void setUserProfileBasedVar() {
    	try {
    		Profile profObj = [select Name from Profile where ID = :userInfo.getProfileId()]; 
	     	Map<string, PartnerSignUpProfile__c> customSettingPartnerProMap = PartnerSignUpProfile__c.getAll();
	     	Map<string, PartnerSignUpProfileAdmin__c> customSettingAdminProMap = PartnerSignUpProfileAdmin__c.getAll();
	     	System.Debug('>>customSettingAdminProMap>>'+ customSettingAdminProMap);
	     	System.Debug('>>profObj.Name>>'+ profObj.Name);
	     	if(customSettingPartnerProMap != null && profObj.Name != null && customSettingPartnerProMap.containskey(profObj.Name)) {
	     		isPartnerUserPro = true;
	     	} 
	     	if(customSettingAdminProMap != null && customSettingAdminProMap.containskey(profObj.Name)) {
	     		isAdminOrNonPartnerPro = true;
	     	}	
    	} catch(Exception ex) {}
    }
    
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
    
 	public String getBillType() {
        return billtype;
    }
    
    public String getPartnerID(){
        return PartnerID;
    }
    public String getBMID(){
        return BMID;
    } 
    public void setBMID(string BMID){
       this.BMID = BMID;
    }  
    
    public String getAID(){
        return AID;
    }  
    public void setAID(string AID){
       this.AID = AID;
    }       
    
    public String getPID(){
        return PID;
    }
    
    public void setPID(string PID){
       this.PID = PID;
    } 
    
    public String getSID(){
        return SID;
    }
    
    public void setSID(string SID){
       this.SID = SID;
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
       options.add(new SelectOption('7D','7D Trial')); 
       options.add(new SelectOption('30D','30D Trial'));  
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

    public PageReference doSearch() { 
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
    public string serviceValueIndex {get;set;}
    public List<SelectOption> getPromotionItems() {
    	List<SelectOption> options = new List<SelectOption>();
    	try {
	    	serviceValueIndex = '';
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
   		} catch(Exception ex) {}
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
   		if(selectTrial != null && toShowSignUpPanel == true && (selectTrial.equals('30D') || selectTrial.equals('7D'))
   				&& isAdminOrNonPartnerPro) {
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
         	strUrlQueryString += createParam(strUrlQueryString, 'PID=' , getPID());
         	strUrlQueryString += createParam(strUrlQueryString, 'AID=' , getAID());
         	strUrlQueryString += createParam(strUrlQueryString, 'SPID=' , getSPID());
         	strUrlQueryString += createParam(strUrlQueryString, 'SID=' , getSID());
         	strUrlQueryString += createParam(strUrlQueryString, 'OPPID=' ,getOPPID());
         	strUrlQueryString += createParam(strUrlQueryString, 'PartnerID=' ,getPartnerID());
         	strUrlQueryString += createParam(strUrlQueryString, 'Brand=' ,oppBrandName);
         	strUrlQueryString += createParam(strUrlQueryString, 'CID=' ,'reseller');
         	if(isAdminOrNonPartnerPro) {
         		strUrlQueryString += createParam(strUrlQueryString, 'billtype=' ,selectedPaymentMethod); 
            	if(!String.isBlank(strBillingFreq) && strBillingFreq == 'Annual') {
  					strUrlQueryString += createParam(strUrlQueryString, 'annual=' ,'true'); 
          		}
         	}
        }
        if(getSAFID() != NULL && getSAFID() != '') {
            System.debug('----------->'+ SAFID);
            strUrlQueryString+= createParam(strUrlQueryString,'SAFID=',getSAFID());
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
	        User activeUser = [Select Email From User where id = :userNm];
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