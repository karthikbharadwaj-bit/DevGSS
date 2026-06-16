/***************************
 @Name : LeadCreationPartnerExpressCls
 @Date : Feburary 24, 2014
 @Description : Holds Lead Creation code for "Partner Express" Profile  
 @Revision History : 
***************************/

public class LeadCreationPartnerExpressCls {
    
    public Lead newLead {get;set;}
    public Lead_Qualification__c newLeadQualification {get;set;}
    public String rcUsers {get;set;}
    public Boolean showContinueBtn {get;set;}
    public String insertStatus {get;set;}
    string userLouisMastrangelo;
	/***************************
	 Constructor for Extension
	 @param Expect Standard Controller parameter (ApexPages.StandardController controller)
	 @return void
	 @see
	***************************/
    
    public LeadCreationPartnerExpressCls(ApexPages.StandardController controller) {
        showContinueBtn = false;
        if('created'.equalsIgnoreCase(insertStatus)){
        	showContinueBtn = true;
        }
        newLead = new Lead();
        newLeadQualification = new Lead_Qualification__c();
        newLead.Country__c = 'United States';
        //Relayware
        //newLead.Country = 'United States';
        rcUsers = null;
        Default_Partner_Owner__c dfltPartOwner = Default_Partner_Owner__c.getOrgDefaults();
        if(dfltPartOwner != null ) {
        	userLouisMastrangelo = dfltPartOwner.UserId__c;
        } 
    }
    
	/***************************
	 Get all picklist values of "Decision Maker" Field of "Lead Qualification"
	 @param No Parameter
	 @return List of SelectOption
	 @see
	***************************/

    public List<SelectOption> getDecisionMaker() {
        List<SelectOption> options = new List<SelectOption>();
        Schema.DescribeFieldResult fieldResult = Lead_Qualification__c.Decision_Maker_Partner__c.getDescribe();
        options = processSchemaResult(fieldResult);
        return options; 
    }
 
	/***************************
	 Get all picklist values of "Have Copy of Current Bill" Field of "Lead Qualification"
	 @param No Parameter
	 @return List of SelectOption
	 @see
	***************************/   
    public List<SelectOption> getHavePhoneBill() {
        List<SelectOption> options = new List<SelectOption>();
        Schema.DescribeFieldResult fieldResult = Lead_Qualification__c.Have_copy_of_current_phone_bill__c.getDescribe();
        options = processSchemaResult(fieldResult);
        return options; 
    }

	/***************************
	 Get all picklist values of "Current Under Contract" Field of "Lead Qualification"
	 @param No Parameter
	 @return List of SelectOption
	 @see
	***************************/
    
    public List<SelectOption> getIsUnderContract() {
        List<SelectOption> options = new List<SelectOption>();
        Schema.DescribeFieldResult fieldResult = Lead_Qualification__c.Currently_under_contract__c.getDescribe();
        options = processSchemaResult(fieldResult);
        return options; 
    }
  
	/***************************
	 Get all picklist values of "Has Purchased Service Before" Field of "Lead Qualification"
	 @param No Parameter
	 @return List of SelectOption
	 @see
	***************************/  
    public List<SelectOption> getHasPurchasedBefore() {
        List<SelectOption> options = new List<SelectOption>();
        Schema.DescribeFieldResult fieldResult = Lead_Qualification__c.Has_this_Lead_purchased_services_before__c.getDescribe();
        options = processSchemaResult(fieldResult);
        return options; 
    }


	/***************************
	 Process the Schema Result.
	 @param Schema.DescribeFieldResult fieldResult
	 @return List of SelectOption
	 @see
	***************************/
    
    public List<SelectOption> processSchemaResult(Schema.DescribeFieldResult fieldResult){
        List<SelectOption> options = new List<SelectOption>();
        List<Schema.PicklistEntry> listDecisionMaker = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry schemaEntry : listDecisionMaker){
          options.add(new SelectOption(schemaEntry.getValue(),schemaEntry.getLabel()));
        }       
        return options;
    }
    
    List<string> approvedBrandList = new List<string>();
    public LeadCreationPartnerExpressCls() {}


	/***************************
	 Process the data field in Form and create new lead.
	 @param No Paramter
	 @return PageReference
	 @see
	***************************/   
    public PageReference createNew() {
        //try {
            Boolean errorFound = false;
            String errorMessage = 'Please provide the required information.';
            if(isEmpty(newLead.FirstName)) {
                errorFound = true;
            }
            if(isEmpty(newLead.LastName)) {
                errorFound = true;
            }
            if(isEmpty(newLead.Company)) {
                errorFound = true;
            }
            if(isEmpty(newLead.Email)) {
                errorFound = true;
            }
            if(isEmpty(newLead.Phone)) {
                errorFound = true;
            }
            if(isEmpty(rcUsers)) { 
                errorFound = true;
            }
            if(!isEmpty(rcUsers) && !rcUsers.isNumeric()) {
                errorFound = true;
                errorMessage = 'Number of RC Users is invalid number.';
            }
            if(isEmpty(newLead.NumberOfEmployees__c)) {
                errorFound = true;
            }
            if(isEmpty(newLead.Number_of_Locations__c)) {
                errorFound = true;
            }
            if(isEmpty(newLead.Industry)) {
                errorFound = true;
            }
            if(isEmpty(newLead.Description)) {
                errorFound = true;
            }
            if(isEmpty(newLead.Lead_Tier_Name__c)) {
                errorFound = true;
            }
            if(isEmpty(newLead.Lead_Brand_Name__c)) {
                errorFound = true;
            }
            
            //Relayware
            newLead.Country = (newLead.Country__c!=null ? newLead.Country__c.trim() : '');
        	newLead.State = (newLead.State__c != null ? newLead.State__c.trim() : '');
            
            if(isEmpty(newLead.Country)) {
                errorFound = true;
            }
            if(isEmpty(newLead.State)) {
                errorFound = true;
            }
            if(isEmpty(newLead.City)) {
                errorFound = true;
            }
            if(isEmpty(newLead.postalCode)) {
               errorFound = true;
            }
            //End
            
            if(isEmpty(newLead.How_did_you_acquire_this_Lead__c)) {
                errorFound = true;
            }
            if(isEmpty(newLead.Estimated_Close_Date__c)) {
                errorFound = true;
            }
            
            if(isEmpty(newLeadQualification.Decision_Maker_Partner__c)) {
                errorFound = true;
            }
            if(!isEmpty(newLeadQualification.Decision_Maker_Partner__c) && !'Unknown'.equalsIgnoreCase(newLeadQualification.Decision_Maker_Partner__c)) {
                if(isEmpty(newLeadQualification.Decision_Maker_First_Name__c)){
                    errorFound = true;
                }
                if(isEmpty(newLeadQualification.Decision_Maker_Last_Name__c)){
                    errorFound = true;
                }
                if(isEmpty(newLeadQualification.Decision_Maker_Email__c)){
                    errorFound = true;
                }
                if(isEmpty(newLeadQualification.Decision_Maker_Phone__c)){
                    errorFound = true;
                }
            }
            
            if(!isEmpty(newLeadQualification.Decision_Maker_Partner__c) && 'Details Below'.equalsIgnoreCase(newLeadQualification.Decision_Maker_Partner__c)) {
            	if(!isEmpty(newLeadQualification.Decision_Maker_Email__c) && !isEmpty(newLead.Email) 
            											&& (newLead.Email).equalsIgnoreCase(newLeadQualification.Decision_Maker_Email__c)){
                    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.ERROR,
                    			'You have indicated that the Decision Maker is different than the Lead contact. The email addresses cannot be the same. Please update the email address and submit again.'); 
                    ApexPages.addMessage(myMsg);
                    return ApexPages.currentPage();
                }
            }
            
            if(isEmpty(newLeadQualification.Explain_the_Lead_s_Need__c)){
                errorFound = true;
            }
            
            if(!isEmpty(newLeadQualification.Explain_the_Lead_s_Need__c) && 
            							newLeadQualification.Explain_the_Lead_s_Need__c.containsIgnoreCase('Other (Please specify)') 
                                        && isEmpty(newLeadQualification.Lead_s_Need_Other__c)){
                errorFound = true;
            }
            
            if(isEmpty(newLeadQualification.Budget_per_Month__c)){
                errorFound = true;
            }
            if(isEmpty(newLeadQualification.Have_copy_of_current_phone_bill__c)){
                errorFound = true;
            }
            if(isEmpty(newLeadQualification.How_many_phones_are_needed__c)){
                errorFound = true;
            }
            if(isEmpty(newLeadQualification.Currently_under_contract__c)){
                errorFound = true;
            }
            if(!isEmpty(newLeadQualification.Currently_under_contract__c) && 'yes'.equalsIgnoreCase(newLeadQualification.Currently_under_contract__c) 
                && isEmpty(newLeadQualification.When_will_contract_expire__c)){
                errorFound = true;
            }
            
            if(isEmpty(newLeadQualification.Has_this_Lead_purchased_services_before__c)){
                errorFound = true;
            }
            
            if(!isEmpty(newLeadQualification.Has_this_Lead_purchased_services_before__c) && 
            		'yes'.equalsIgnoreCase(newLeadQualification.Has_this_Lead_purchased_services_before__c) 
                    && isEmpty(newLeadQualification.What_type_of_services_has_Lead_purchased__c)){
                errorFound = true;
            }
            
            if(!isEmpty(newLeadQualification.What_type_of_services_has_Lead_purchased__c) && 
            		newLeadQualification.What_type_of_services_has_Lead_purchased__c.containsIgnoreCase('Other (Please specify)') 
                    && isEmpty(newLeadQualification.Other_purchased_services__c)){
                errorFound = true;
            }
            
            if(isEmpty(newLeadQualification.Timeframe__c)) {
                errorFound = true;
            }
            
            if(errorFound) {
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.ERROR,
                    errorMessage);
                ApexPages.addMessage(myMsg);
                return ApexPages.currentPage();
            }
            //system.debug('-------------------------------------->'+ newLead.Email);//remove it
            if(!isValidEmail(newLead.Email.trim()) || !isValidEmail(newLeadQualification.Decision_Maker_Email__c.trim()) ){
                    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.ERROR,
                    'The email entered is not in a valid format.'); 
                    ApexPages.addMessage(myMsg );
                    return ApexPages.currentPage();
            }
        
        newLead.leadSource = 'Partner';
        string rtnstring = checkLeadEmailAlreadyExists();
       
        User objUserDetail=[Select id,Contact.AccountId,Contact.Account.Partner_id__c,Contact.Account.Signup_Link__c ,Contact.Account.Name, 
        					 Contact.Account.Inside_Sales_Rep__c, Contact.Account.Current_Owner__c,
                             Contact.Account.Ultimate_Parent_Account_ID__c,Contact.Account.Current_Owner_Name__c,ContactId 
                             FROM User where Id=:UserInfo.getUserId()];
        if(rtnstring == 'Contact Found' || rtnstring=='Lead Found') {
            createLeadApprovalRecord(rtnstring,objUserDetail);
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.Info,
                                       'This Lead is in conflict with RingCentral’s existing Business. You will be contacted by a Sales Agent soon.'); 
            ApexPages.addMessage(myMsg);
            insertStatus = 'conflict';
            if('created'.equalsIgnoreCase(insertStatus)){
        		showContinueBtn = true;
        	}
            return Page.PartnerExpressMessage;
            //return null;
        }
        newLead.Number_of_Users__c = Double.valueOf(rcUsers);
        newLead.Lead_Score__c = 'A';
        newLead.Status = '1. New';
        newLead.RecordTypeId = OpportunityHelper.getOppRecordTypeMap('Partner Leads');
        if(objUserDetail.Contact.AccountId==objUserDetail.Contact.Account.Ultimate_Parent_Account_ID__c ){
            newLead.Ultimate_Parent_Account_ID__c=objUserDetail.Contact.AccountId;
            newLead.Ultimate_Parent_Account_Name__c=objUserDetail.Contact.Account.Name;
            newLead.Ultimate_Parent_Account_Partner_ID__c=objUserDetail.Contact.Account.Partner_id__c;
     	} else { 
            Account objParentAccount=[Select id,Partner_id__c,Name from Account where id=:objUserDetail.Contact.Account.Ultimate_Parent_Account_ID__c ];
            newLead.Ultimate_Parent_Account_ID__c=objParentAccount.Id;
            newLead.Ultimate_Parent_Account_Name__c=objParentAccount.Name;
            newLead.Ultimate_Parent_Account_Partner_ID__c=objParentAccount.Partner_id__c;
     	} 
		newLead.Current_Owner_Name__c = objUserDetail.Contact.Account.Current_Owner_Name__c;
        try {        
            if(objUserDetail != null) {
                if(objUserDetail.Contact.Account.Partner_id__c != null) {
                    newLead.LeadPartnerID__c= objUserDetail.Contact.Account.Partner_id__c;
                    newLead.Partner_Account_Name__c = objUserDetail.Contact.Account.Name;
                }
                try {   

                    if(objUserDetail.Contact.Account.Current_Owner__c != null) {
                    	newLead.OwnerId = objUserDetail.Contact.Account.Current_Owner__c;
                    } else {
                    	newLead.OwnerId = userLouisMastrangelo;
                    }
                    if(objUserDetail.Contact.Account.Inside_Sales_Rep__c != null) {
                    	newLead.Inside_Sales_Rep__c = objUserDetail.Contact.Account.Inside_Sales_Rep__c;
                    }
                } catch(Exception e){
                    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Exception Found= '+e.getMessage() + ', ' + e.getLineNumber());
                    ApexPages.addMessage(myMsg);
                    return null;
                }
            }
            newLead.Partner_Lead_Owner__c = UserInfo.getUserId();
            insert newLead;
            if(newLead.Id != null) {
            	if(!Test.isRunningTest()) {
            		ShareUtil.shareLeadToPartner(newLead.id,UserInfo.getUserId());
	                newLeadQualification.Lead__c = newLead.Id;
	                newLeadQualification.RecordTypeId = getRecordTypeIdByName();
	                newLeadQualification.OwnerId = newLead.OwnerId;
	            	insert newLeadQualification;
	            	ShareUtil.shareLeadQualificationToPartner(newLeadQualification.id, UserInfo.getUserId());     
            	}
            }
        } catch(Exception e){
          ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Exception Found '+e.getMessage()+',  ' +e.getLineNumber());
          ApexPages.addMessage(myMsg);
          return null;
        }
        if(newLead.Id == null) {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'The lead could not be created due to error occured!');
            ApexPages.addMessage(myMsg );
            return ApexPages.currentPage();
        }   
        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.Info,'Lead submitted successfully. If you wish to be compensated for this Lead, you must schedule an appointment.'); 
        ApexPages.addMessage(myMsg);
        insertStatus = 'created';
        if('created'.equalsIgnoreCase(insertStatus)){
        	showContinueBtn = true;
        }
        return Page.PartnerExpressMessage;
    }
    
    public PageReference redirectNewLead() {
    	PageReference leadPage = new ApexPages.StandardController(newLead).view();
        leadPage.setRedirect(true);
        return leadPage;
    }
    
    public PageReference clearPickListValue(){
    	newLeadQualification.What_type_of_services_has_Lead_purchased__c = null;
    	return null;
    }
   

	/***************************
	 If lead is already exist then create a case and send it for approval.
	 @param String [Where Contact Found or Lead Found] and Detail of Current Login User
	 @return void
	 @see
	***************************/
   
    public void createLeadApprovalRecord(String rtnstring,User objUser) {
    	try {
            RecordType  objRecordType = [SELECT id,Name FROM RecordType where SobjectType='Case' and  Name='Partner Lead' limit 1];
            Group gp = [Select id,name from group where Type='Queue' and Name='Partner Lead Reviewer'];
            List<Case> lstCase= [Select id from Case where RecordTypeId=:objRecordType.id and Partner_Lead_Email__c=:newLead.Email and IsClosed = false];
       		system.debug('@@@@@@@@@@@ 111111111');
        	if(lstCase.size()==0){
	         	system.debug('@@@@@@@@@@@ 222222222222');
	            Case objCase=new Case();
	            objCase.Number_of_Users__c = Double.valueOf(rcUsers);
	            objCase.OwnerId = gp.id;
	            if(objUser.Contact.Account.Inside_Sales_Rep__c != null) {
            		objCase.Inside_Sales_Rep__c = objUser.Contact.Account.Inside_Sales_Rep__c;
            	}
	            if(rtnstring == 'Contact Found' && objContact != null){
	                objCase.ContactId = objContact.id;
                 	objCase.accountId = objContact.AccountId;
	            } else if(rtnstring == 'Lead Found'){
	            	objCase.ContactId = objUser.ContactId;
	                objCase.accountId = objUser.Contact.AccountId;
            	}
	            objCase.RecordTypeId=objRecordType.id;
	            objCase.Lead_Partner_ID__c= (objUser==null?null:objUser.Contact.Account.Partner_id__c);
	            objCase.NumberOfEmployees__c=newLead.NumberOfEmployees__c;
	            objCase.Number_of_Locations__c=newLead.Number_of_Locations__c;
	            objCase.Description=objUser.Contact.Account.Name+' submitted a Lead which was found to already exist in SFDC.  Please verify if this is a valid Lead or not.';
	            objCase.Partner_Lead_Description__c=newLead.Description;
	            objCase.Partner_Estimated_Close_Date__c = newLead.Estimated_Close_Date__c;
	            objCase.Partner_How_did_you_acquire_this_Lead__c = newLead.How_did_you_acquire_this_Lead__c;
	            objCase.Subject='Duplicate Lead '+newLead.Company+' from Partner '+objUser.Contact.Account.Name;

                //B3028 Rework of lead to case logic
                objCase.Partner_Lead_FirstName__c = newLead.FirstName;
                objCase.Partner_Lead_LastName__c = newLead.LastName;
                objCase.Partner_Lead_Title__c = newLead.Title;
                objCase.Partner_Lead_Company__c = newLead.Company;
                objCase.Partner_Lead_Email__c = newLead.Email;
                objCase.Partner_Lead_Phone__c = newLead.Phone;
                objCase.Partner_Lead_Phone_Alternate__c  =  newLead.Phone_Alternate__c;

                //B-2577 Consolidate Partner Fields on Case Object
                objCase.Partner_Lead_Fields__c = DuplicateLeadHelper.createLeadJson(newLead, objUser);
                
	            insert objCase; 
	            if(objCase.Id != null) {
	                newLeadQualification.Case__c = objCase.Id;
	                newLeadQualification.RecordTypeId = getRecordTypeIdByName();
	                newLeadQualification.OwnerId = objCase.OwnerId;
	                insert newLeadQualification;
	            }
        	}
        } catch(Exception ex) {}
    }
    
    Contact objContact;
    public string checkLeadEmailAlreadyExists() {
        List<Lead> leadList = [select Id from Lead where email= :newLead.Email.trim() limit 1];
        if(leadList != null && leadList.size()>0) {
            return 'Lead Found';
        } else {
            List<Contact> contactList = [select Id,accountId from Contact where email = :newLead.Email.trim() limit 1];
            if(contactList != null && contactList.size()>0) {
                 objContact=contactList.get(0);
                return 'Contact Found';
            }
        }
        return 'notfound';
    }
    
    public Boolean isEmpty(String value) {
        return (value == null || value.trim() == '' ? true : false);
    }
    
    public Boolean isEmpty(Date dtvalue) {
        return (dtvalue == null || String.valueof(dtvalue).trim() == '' ? true : false);
    }
    
    public Boolean isFakeEmail(String email) {
        return (!isEmpty(email) && email.trim() == Emails__c.getall().get('fake').Email_Address__c);
    }
    
    public Boolean isValidEmail(String InputString) {
        if(InputString != null && InputString != '') {
            String emailRegex = '([a-zA-Z0-9_\\-\\.]+)@((\\[a-z]{1,3}\\.[a-z]{1,3}\\.[a-z]{1,3}\\.)|(([a-zA-Z0-9\\-]+\\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})';
            Pattern MyPattern = Pattern.compile(emailRegex);
            Matcher MyMatcher = MyPattern.matcher(InputString);
            if (!MyMatcher.matches()) {
                return false;
            }
        }
        return true;
    }
    
    public PageReference cancelLead() {
        PageReference pg = new PageReference('/apex/PartnersLeadView?sfdc.tabName=01r80000000UJTG');
        pg.setRedirect(true);
        return pg;
    }
    
    public Id getRecordTypeIdByName(){
        Schema.SObjectType s = ((SObject)Type.forName('Lead_Qualification__c').newInstance()).getSObjectType() ; // getting Sobject Type
        Schema.DescribeSObjectResult resSchema = s.getDescribe() ;
        Map<String,Schema.RecordTypeInfo> recordTypeInfo = resSchema.getRecordTypeInfosByName(); //getting all Recordtype for the Sobject
        Id rtId = recordTypeInfo.get('Partner').getRecordTypeId();//particular RecordId by  Name
        return rtId;
    }
}