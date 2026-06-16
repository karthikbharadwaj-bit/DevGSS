/*************************************************
LeadCreationPartnerVAR class
/************************************************/

public class LeadCreationPartnerVAR  {

    private final String ACCOUNT_PARTNER_TYPE_ISV = 'ISV Partner';
    private final String ACCOUNT_PARTNER_TYPE_MASTER = 'Master Agent';
    private final String ACCOUNT_PARTNER_TYPE_GENERAL = 'General Partner';
    private final String ACCOUNT_PARTNER_TYPE_SALES = 'Sales Agent';
    private final String ROLE_SDR_SIA = 'SDR - SIA';
    private final String SIA_PERMISSION_SET_LABEL = 'SIA Users';

    @TestVisible
    private final String PICKLIST_NONE = '--None--';

    private final Set<Schema.SObjectField> FIELDS_TO_SKIP_ADDING_NONE = new Set<Schema.SObjectField> {
        Lead.Competitors__c,
        Lead.Prompting_Change__c
    };


    public Lead newLead {get;set;}
    public String rcUsers{get;set;}
    public String avayaTiers { get; set; }
    public String atosTiers { get; set; }
    public String rainbowTiers { get; set; }
    public Boolean needToCheckState{get;set;}
    public String tiersForOtherBrands{get;set;} //CMR-358329
    public string strSelectedBrand {get;set;} //CMR-358329
    @TestVisible
    private string PartnerAccountType {get; set; }
    public Boolean isSIAUser {
        get {
            Id userId = UserInfo.getUserId();
            return roleContainsSIA(userId) || userIsInSIAPermissionSet(userId);
        }
    }

    public Boolean ShowAdditionalQuestions
    {
        get
        {
            return
            (
                (PartnerAccountType != null) && (PartnerAccountType.equalsIgnoreCase(ACCOUNT_PARTNER_TYPE_MASTER) || PartnerAccountType.equalsIgnoreCase(ACCOUNT_PARTNER_TYPE_GENERAL) || PartnerAccountType.equalsIgnoreCase(ACCOUNT_PARTNER_TYPE_SALES))
            );
        }
    }

    public final String AVAYA_OFFICE {
        get {
            return OpportunityHelper.BRAND_AVAYA;
        }
    }

    public final String ATOS_OFFICE {
        get {
            return OpportunityHelper.BRAND_ATOS;
        }
    }

    public final String RAINBOW_OFFICE {
        get {
            return OpportunityHelper.BRAND_RAINBOW;
        }
    }

    string userLouisMastrangelo;
    public LeadCreationPartnerVAR(ApexPages.StandardController controller) {
        avayaTiers = getTiersForBrand(AVAYA_OFFICE);
        atosTiers = getTiersForBrand(ATOS_OFFICE);
        rainbowTiers = getTiersForBrand(RAINBOW_OFFICE);

        boolToShowMainSection = true;
        newLead = new Lead();
        newLead.Country__c = 'United States';
        //Relayware
        //newLead.Country = 'United States';
        newLead.Partner_Lead_Source__c = 'Partner';
        rcUsers = null;
        Default_Partner_Owner__c dfltPartOwner = Default_Partner_Owner__c.getOrgDefaults();
        if(dfltPartOwner != null ) {
          userLouisMastrangelo = dfltPartOwner.UserId__c;
        }
        updateBrandPicklist(null);
        getCheckState();
    }

    public String getTiersForBrand(String brand) {
        List<String> tiersFromPicklist = SFDescribeHelper.getDependentOptions(
            'Lead', 'Lead_Brand_Name__c', 'Lead_Tier_Name__c').get(brand);

        String tiers = '';
        if (tiersFromPicklist != null && !tiersFromPicklist.isEmpty()) {
            tiers = PICKLIST_NONE + ';' + String.join(tiersFromPicklist, ';');
        }

        return tiers;
    }

    //CMR-358329
    public void getTiersForOtherBrandsNames(){
        List<String> tiersFromPicklist = SFDescribeHelper.getDependentOptions(
        'Lead', 'Lead_Brand_Name__c', 'Lead_Tier_Name__c').get(strSelectedBrand);
        if (tiersFromPicklist != null && !tiersFromPicklist.isEmpty()) {
		tiersForOtherBrands = PICKLIST_NONE + ';' + String.join(tiersFromPicklist, ';');
        }
    }

    public Boolean roleContainsSIA(Id userId){
        List<Object> bindings = new List<Object>();
        bindings.add(userId);
        User currentUser = (User) new UserSelector().selectUserRoleById(bindings).executeQuery()[0];
        if (currentUser.UserRole == null) {
            return false;
        }
        return currentUser.UserRole.Name.contains(ROLE_SDR_SIA);
    }

    public Boolean userIsInSIAPermissionSet(Id userId){
        Boolean isSIAUser = false;
        List<Object> bindings = new List<Object>();
        bindings.add(SIA_PERMISSION_SET_LABEL);
        List<PermissionSetAssignment> psAssignments = (List<PermissionSetAssignment>) new PermissionSetAssignmentSelector()
                                                          .selectPermissionSetAssignmentByLabel(bindings).executeQuery();
        for (PermissionSetAssignment psa : psAssignments) {
            if (psa.AssigneeId == userId) {
                isSIAUser = true;
            }
        }
        return isSIAUser;
    }
    public List<SelectOption> getPartnerLeadSources() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('Partner', 'Partner'));
        options.add(new SelectOption('SIA', 'SIA'));
        options.add(new SelectOption('Strategic Marketing Partnerships', 'Strategic Marketing Partnerships'));
        return options;
    }


    public void getCheckState(){
        //Need to check if Country dependent picklist State has values.
        needToCheckState = true;
        Map<String,List<String>> stateValues = SFDescribeHelper.getDependentOptions('Lead', 'Country__c', 'State__c');
        if(newLead.Country__c == null || (stateValues.containsKey(newLead.Country__c.trim()) && stateValues.get(newLead.Country__c.trim()).size() == 0 )){
            needToCheckState = false;
        }
    }

    /*This method is used to do email validation.*/
    public Boolean isValidEmail(String InputString) {
        if(InputString != null && InputString != '') {
            String emailRegex = '([a-zA-Z0-9_\\-\\.]+)@((\\[a-z]{1,3}\\.[a-z]{1,3}\\.[a-z]{1,3}\\.)|(([a-zA-Z0-9\\-]+\\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})';
            Pattern MyPattern = Pattern.compile(emailRegex);

            // Then instantiate a new Matcher object "MyMatcher"
            Matcher MyMatcher = MyPattern.matcher(InputString);

            if (!MyMatcher.matches()) {
                return false;
            }
        }
        return true;
    }

    public void resetErrorVariables() {

    }

    public String numOfEmployees{get;set;}
    public void resetFieldValue() {

    }

    public string checkInputFieldLength() {
        return 'NoError';
    }

    /*
    Called on by search button on page.
    Checks field validations, passing errors if any fail.
    Formats different examples of phone field in case of old formating errors
    Uses any combination of the following fields that are available: LastName, Company, Email, Phone
    For each Opp found calls addOpp to determine which table on page to show in (protected or not)
    */
    public Boolean isEmpty(String value) {
        return (value == null || value.trim() == '' ? true : false);
    }

    public Boolean isEmpty(Date dtvalue) {
        return (dtvalue == null || String.valueof(dtvalue).trim() == '' ? true : false);
    }

    public Boolean isFakeEmail(String email) {
        return (!isEmpty(email) && email.trim() == Emails__c.getall().get('fake').Email_Address__c);
    }



    public Set<Id> getCurrentUser(Id ownerId) {
        Set<Id> oppOwnerIds = new Set<Id>();
        if(ownerId != null) {
            if((String.valueOf(ownerId)).startsWith('005')) {
                oppOwnerIds.add(ownerId);
            }
        }
        return oppOwnerIds;
    }

    /**
     * Get picklist values for Brand field
     * Lead.Lead_Brand_Name__c picklist values filtered by Account.Permitted_Brands__c
     * B-1479
     */
    public List<SelectOption> rcPartnerBrandItems { get; set;}
    public Void updateBrandPicklist(String permittedBrands) {
        List<SelectOption> options = new List<SelectOption>();

        // get all possible picklist values
        List<Schema.PicklistEntry> ples = SFDescribeHelper.getOptions('Lead','Lead_Brand_Name__c');

        // add empty value
        options.add(new SelectOption('', PICKLIST_NONE));

        // Filter brands by permitted
        if(permittedBrands == null) {
            permittedBrands = '';
        }
        Set <String> permittedBrandsSet = new Set <String>(permittedBrands.split(';'));
        for(Schema.PicklistEntry ple : ples) {
            if(permittedBrandsSet.contains(ple.getValue())){
                options.add(new SelectOption(ple.getValue(),ple.getLabel()));
            }
        }

        // set Picklist Options
        rcPartnerBrandItems = options;

        // if already selected brand not presented in permitted then drop it
        if(!permittedBrandsSet.contains(strSelectedBrand)) {
            strSelectedBrand = '';
        }
    }

    /*
    Make sure that latest information has been searched with and that all fields are valid.
    Insert newLead and return page reference to it
    */
    string rtnString;
    Boolean byPassDuplicateLead;
    public boolean boolToShowMainSection {get;set;}
    public partnerWrapper partnerWrapperObj;
    public Boolean websiteWarningShownAlready = false;
    public PageReference createNew()
    {
        system.debug('>>newLead.Lead_Brand_Name__c>>'+newLead.Lead_Brand_Name__c);
        system.debug('>>newLead.Lead_Tier_Name__c>>'+newLead.Lead_Tier_Name__c);
        resetErrorVariables();
        resetFieldValue();
        String warningMessage=System.Label.Website_Warning_Message;
        Boolean errorFound = false;
        String errorMessage = 'Please provide the required information.';
        newLead.Lead_Brand_Name__c = strSelectedBrand;

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
        if (isEmpty(newLead.Street)) {
            errorFound = true;
        }
        if(isEmpty(rcUsers)) {
            errorFound = true;
        }
        if(!isEmpty(rcUsers) && !rcUsers.isNumeric()) {
            errorFound = true;
            errorMessage = 'Number of RC Users is invalid number.';
        }
        if(isEmpty(newLead.Lead_Tier_Name__c) || newLead.Lead_Tier_Name__c == PICKLIST_NONE) {
            errorFound = true;
        }
        if(isEmpty(newLead.Lead_Brand_Name__c) || newLead.Lead_Brand_Name__c == PICKLIST_NONE) {
            errorFound = true;
        }

        //Relayware
        newLead.Country = (newLead.Country__c!=null ? newLead.Country__c.trim() : '');
        newLead.State = (newLead.State__c != null ? newLead.State__c.trim() : '');
        newLead.City__c = (newLead.City != null ? newLead.City.trim() : '');

        if(isEmpty(newLead.Country)) {
            errorFound = true;
        }
        if(isEmpty(newLead.State) && needToCheckState) {
            errorFound = true;
        }
        if(isEmpty(newLead.City)) {
            errorFound = true;
        }
        if(isEmpty(newLead.PostalCode)) {
            errorFound = true;
        }
        //End

        if(isEmpty(newLead.LeadPartnerID__c)) {
             errorFound = true;
        }
        //Relayware
        if(isEmpty(newLead.Partner_Contact__c)) {
             errorFound = true;
             errorMessage = 'Please provide Partner Contact.';
        }

        if (ShowAdditionalQuestions) {
            if (isEmpty(newLead.Existing_Solution_Provider__c) || newLead.Existing_Solution_Provider__c == PICKLIST_NONE) {
                errorFound = true;
            }
            if (isEmpty(newLead.Prompting_Change__c) || newLead.Prompting_Change__c == PICKLIST_NONE) {
                errorFound = true;
            }
            if (isEmpty(newLead.Competitors__c) || newLead.Competitors__c == PICKLIST_NONE) {
                errorFound = true;
            }
            if (isEmpty(newLead.Decision_Maker__c) || newLead.Decision_Maker__c == PICKLIST_NONE) {
                errorFound = true;
            }
            if (isEmpty(newLead.Currently_in_a_contract__c) || newLead.Currently_in_a_contract__c == PICKLIST_NONE) {
                errorFound = true;
            }
            if (isEmpty(newLead.Project_budget__c) || newLead.Project_budget__c == PICKLIST_NONE) {
                errorFound = true;
            }
        }
        if (String.isBlank(newLead.Website) && errorFound == false && !websiteWarningShownAlready) {
            ApexPages.Message apexWarningMsg = new ApexPages.Message(ApexPages.severity.WARNING, warningMessage);
            ApexPages.addMessage(apexWarningMsg);
            websiteWarningShownAlready = true;
            if (websiteWarningShownAlready) {
               return null;
            }
        }
        if(errorFound) {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.ERROR,
                errorMessage);
            ApexPages.addMessage(myMsg);
            return null;
        }

        if(!isValidEmail(newLead.Email.trim())) {
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.ERROR,'The email entered is not in a valid format.');
                ApexPages.addMessage(myMsg);
                return null;
        }
        if(String.isNotBlank(newLead.Website) && !LeadHelper.isValidWebsite(newLead.Website.trim())) {
        	ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.ERROR,System.Label.Invalid_Website_Error);
        	ApexPages.addMessage(myMsg);
        	return null;
        }

        /*if(!isEmpty(newLead.Phone)
            && newLead.Phone.trim().length() != 10
            && newLead.Phone.trim().length() != 12) {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.ERROR,
            'The phone number should be entered as just 10 digits or 12 for UK numbers. i.e. 6504724066 or 441138680059.');
            ApexPages.addMessage(myMsg);
            return null;
        }*/

        //Relayware
        Contact partnerContact;

        if (!string.isBlank(newLead.Partner_Contact__c)){
            //Relayware
            partnerContact = [Select id,Name,Email,AccountId,Account.Partner_id__c,Account.Signup_Link__c,Account.Name, Account.Inside_Sales_Rep__c, Account.Current_Owner__c,Account.Ultimate_Parent_Account_ID__c,Account.Current_Owner_Name__c,Account.Var_territory__c FROM Contact where Id = :newLead.Partner_Contact__c];
            if(partnerContact.Account.Partner_Id__c != newLead.LeadPartnerID__c) {
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.ERROR,'Partner Id not matches with the selected Partner Owner.');
                ApexPages.addMessage(myMsg );
                return null;
            } else {
                partnerWrapperObj = new partnerWrapper(partnerContact.id,partnerContact.AccountId,partnerContact.Account.Partner_id__c,
                                                        partnerContact.Account.Signup_Link__c,partnerContact.Account.Name,
                                                        partnerContact.Account.Inside_Sales_Rep__c,partnerContact.Account.Current_Owner__c,
                                                        partnerContact.Account.Ultimate_Parent_Account_ID__c,partnerContact.Account.Current_Owner_Name__c,
                                                        partnerContact.Account.Var_territory__c,partnerContact.id);
            }
        }

        //End

        system.debug('about to create lead');
        newLead.leadSource = newLead.Partner_Lead_Source__c;
        newLead.Number_of_Users__c = Double.valueOf(rcUsers);
        newLead.Lead_Score__c = 'A';
        newLead.Status = '1. New';
        newLead.RecordTypeId = OpportunityHelper.getOppRecordTypeMap('Partner Leads');
        newLead.OwnerId = UserInfo.getUserId();

        //Relayware Mapping
        if(partnerWrapperObj.AccountId == partnerWrapperObj.accUltimateParentAccountID){
            newLead.Ultimate_Parent_Account_ID__c = partnerWrapperObj.AccountId;
            newLead.Ultimate_Parent_Account_Name__c = partnerWrapperObj.accName;
            newLead.Ultimate_Parent_Account_Partner_ID__c = partnerWrapperObj.accPartnerId;
            //Case #03765152
            newLead.Var_territory__c = partnerWrapperObj.accVarTerritory;
            //Case #03765152
         } else {
            Account objParentAccount= [Select id,Partner_id__c,Name, Var_territory__c from Account where id=:partnerWrapperObj.accUltimateParentAccountID];
            newLead.Ultimate_Parent_Account_ID__c = objParentAccount.Id;
            newLead.Ultimate_Parent_Account_Name__c = objParentAccount.Name;
            newLead.Ultimate_Parent_Account_Partner_ID__c = objParentAccount.Partner_id__c;
            //Case #03765152
            newLead.Var_territory__c = objParentAccount.Var_territory__c;
            //Case #03765152
        }

        newLead.Current_Owner_Name__c = partnerWrapperObj.accCurrentOwnerName;
        newLead.Lead_Created_via_Smart_Search__c=true;//CMR-290675 Checking the flag true to identify smart search partner leads for gating
        if(partnerWrapperObj != null) {
            if(partnerWrapperObj.accPartnerId != null) {
                newLead.Partner_Account_Name__c = partnerWrapperObj.accName;
            }
            try {
                if(partnerWrapperObj.accCurrentOwner != null) {
                    newLead.OwnerId = partnerWrapperObj.accCurrentOwner;
                } else {
                    newLead.OwnerId = userLouisMastrangelo;
                }
                if(partnerWrapperObj.accInsideSalesRep != null) {
                    newLead.Inside_Sales_Rep__c = partnerWrapperObj.accInsideSalesRep;
                }
            } catch(Exception e){
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Exception Found= '+e.getMessage() + ', ' + e.getLineNumber());
                ApexPages.addMessage(myMsg);
                return null;
            }
        }
        byPassDuplicateLead = canPartnerBypassDuplicateCheck();
        if(!byPassDuplicateLead) {
        /******************* Case Creation *******************************/
        rtnString = checkLeadEmailAlreadyExists();
        if(rtnString == 'Contact Found' || rtnString == 'Lead Found') {
            //Relayware
            if(partnerContact != NULL){
                createCaseForPartnerLead(partnerContact);
            }
            //End
            /*ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.Info,
                                       'This Lead is in conflict with RingCentral’s existing Business. Lead is submitted for review');
            ApexPages.addMessage(myMsg);
            boolToShowMainSection = false;*/
            PageReference pgRef = new PageReference('/apex/PartnerMessagePageVAR');
            pgRef.setRedirect(true);
            return pgRef;
            //return Page.PartnerMessagePageVAR;
            //return null;
        }
        /*****************************************************************/
        }
        try {
            insert newLead;
            //Relayware
            //End
        } catch(Exception e){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO, e.getMessage());
            ApexPages.addMessage(myMsg );
            return null;
        }
        if(newLead.Id == null) {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'The lead could not be created due to error occured!');
            //ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, ex);
            ApexPages.addMessage(myMsg );
            return ApexPages.currentPage();
        }
        system.debug('==newLead.Partner_Account__c=='+newLead.Partner_Account__c);
        //PageReference leadPage = new PageReference('/00Q/e?');
        PageReference leadPage = new ApexPages.StandardController(newLead).view();
        leadPage.setRedirect(true);
        return leadPage;
    }

    private Group getPartnerQueue() {
        return [SELECT id,Name FROM Group WHERE Type='Queue' AND Name='Partner Lead Reviewer' LIMIT 1];
    }

    Contact objContact;
    public string checkLeadEmailAlreadyExists() {
        List<Lead> leadList = [select Id from Lead where email =:newLead.Email.trim() limit 1];
        if(leadList != null && leadList.size()>0) {
            return 'Lead Found';
        } else {
            List<Contact> contactList = [select Id,accountId from Contact where email = :newLead.Email.trim() limit 1];
            if(contactList != null && contactList.size()>0) {
                objContact = contactList.get(0);
                return 'Contact Found';
            }
        }
        return 'notfound';
    }
     public Boolean canPartnerBypassDuplicateCheck() {
        String partnerId = newLead.LeadPartnerID__c;
        String brandName = newLead.Lead_Brand_Name__c;
        if (String.isBlank(partnerId) && String.isBlank(brandName)) {
            return false;
        }
        List<Bypass_Lead_Review_Partners_List__c> bypassList = [
            SELECT Id
            FROM Bypass_Lead_Review_Partners_List__c
            WHERE (Partner_Id__c = :partnerId OR Brand_Name__c = :brandName)
            LIMIT 1
        ];
        if (!bypassList.isEmpty()) {
            return true;
        } else {
            return false;
        }
    }
    //Relayware
    public void createCaseForPartnerLead(Contact partnerContact) {
       try {
            RecordType  objRecordType = [SELECT id, Name FROM RecordType where SobjectType = 'Case' and Name = 'Partner Lead' limit 1];
            Group gp = [Select id, name from group where Type ='Queue' and Name = 'Partner Lead Reviewer'];
            List<Case> lstCase = [Select id from Case where RecordTypeId =:objRecordType.id and Partner_Lead_Email__c = :newLead.Email.trim()
                                    and IsClosed = false];

            if(lstCase.size() == 0) {
                system.debug('@@@@@@@@@@@ 222222222222');
                Case objCase = new Case();
                objCase.Number_of_Users__c = Double.valueOf(rcUsers);
                objCase.OwnerId = gp.id;
                if(partnerContact.Account.Inside_Sales_Rep__c != null) {
                    objCase.Inside_Sales_Rep__c = partnerContact.Account.Inside_Sales_Rep__c;
                }
                if(rtnString == 'Contact Found' && objContact !=null){
                    objCase.ContactId = objContact.id;
                    objCase.accountId = objContact.AccountId;
                } else if(rtnstring == 'Lead Found'){
                    objCase.ContactId = partnerContact.id;
                    objCase.accountId = partnerContact.AccountId;
                }
                objCase.RecordTypeId = objRecordType.id;
                objCase.Lead_Partner_ID__c = newlead.LeadPartnerID__c;
                objCase.Partner_Contact__c = partnerContact.Id;
                objCase.NumberOfEmployees__c = newLead.NumberOfEmployees__c;
                objCase.Number_of_Locations__c = newLead.Number_of_Locations__c;
                objCase.Description = partnerContact.Account.Name +' submitted a Lead which was found to already exist in SFDC.' +
                                        'Please verify if this is a valid Lead or not.';
                objCase.Partner_Lead_Description__c = checkFieldLength(newLead.Description, 32000);
                objCase.Partner_How_did_you_acquire_this_Lead__c = newLead.How_did_you_acquire_this_Lead__c;
                objCase.Subject = 'Duplicate Lead '+ newLead.Company +' from Partner '+ partnerContact.Account.Name;
                objCase.Zip__c = newLead.PostalCode;
                objCase.Address_ZIP__c = newLead.PostalCode;
                objCase.Address_Street_Name__c = newLead.Street;

                //B3028 Rework of lead to case logic
                objCase.Partner_Lead_FirstName__c = newLead.FirstName;
                objCase.Partner_Lead_LastName__c = newLead.LastName;
                objCase.Partner_Lead_Title__c = newLead.Title;
                objCase.Partner_Lead_Company__c = newLead.Company;
                objCase.Partner_Lead_Email__c = newLead.Email;
                objCase.Partner_Lead_Phone__c = newLead.Phone;
                objCase.Partner_Lead_Phone_Alternate__c  =  newLead.Phone_Alternate__c;

                //B-2577 Consolidate Partner Fields on Case Object
                objCase.Partner_Lead_Fields__c = DuplicateLeadHelper.createLeadJson(newLead, null);

                Database.SaveResult srCase = Database.insert(objCase, false);
                if (srCase.isSuccess()) {
                        // Operation was successful, so get the ID of the record that was processed
                        System.debug('Successfully inserted the case. Case ID: ' + objCase.Id);
                }else {
                    // Operation failed, so get all errors
                    for(Database.Error err : srCase.getErrors()) {
                       System.debug('The following error has occurred. ' + err.getStatusCode() + ' : ' + err.getMessage() + '. Case fields that affected by this error: ' + err.getFields());
                    }
                }

                Exception_And_Notification_History__c exeNotificationObj = new Exception_And_Notification_History__c();
                exeNotificationObj.Sender_Display_Name__c = 'SFDC Duplicate Lead';
                exeNotificationObj.Email_Subject__c = 'Duplicate Lead Notification';
                exeNotificationObj.To_Address_1__c = partnerContact.Email;
                //exeNotificationObj.Reply_To__c =  UserRC.rcsfSyncUserObj.Email__c;
                exeNotificationObj.Object_Type__c = 'Contact';
                exeNotificationObj.content_label_01__c = 'SFDC_LEAD_DUPLICTATE_NOTIFICATION';
                exeNotificationObj.content_var_01__c = partnerContact.Id;
                exeNotificationObj.content_var_02__c = objCase.Id;
                exeNotificationObj.content_label_02__c = partnerContact.Name;
                exeNotificationObj.RecordTypeId = ExceptionAndNotificationHelper.getRcId('Email Notification');

                Database.SaveResult srNotification = Database.insert(exeNotificationObj, false);
                if (srNotification.isSuccess()) {
                        // Operation was successful, so get the ID of the record that was processed
                        System.debug('Successfully inserted the notification. Notification ID: ' + exeNotificationObj.Id);
                }else {
                    // Operation failed, so get all errors
                    for(Database.Error err : srNotification.getErrors()) {
                       System.debug('The following error has occurred. ' + err.getStatusCode() + ' : ' + err.getMessage() + '. Notification fields that affected by this error: ' + err.getFields());
                    }
                }
            }
        } catch(Exception ex) {
            System.debug('ex.getMessage: ' + ex.getMessage());
        }
    }

    // Validate mandatory field length
    public String checkFieldLength(String text, Integer maxLength){
        if (text != null){
            text = text.substring(0, text.length() > maxLength ? maxLength : text.length());
        }

        //return concatenated string
        return text;
    }

    public PageReference cancel(){
        string strRtnUrl = ApexPages.currentPage().getParameters().get('rtnURL');
        PageReference leadRtnPage;
        if(strRtnUrl != null && strRtnUrl != '') {
            leadRtnPage = new PageReference(strRtnUrl);
        } else {
            leadRtnPage = new PageReference('/00Q/o');
        }
        leadRtnPage.setRedirect(true);
        return leadRtnPage;
    }

    //Relayware
    /**
     * Populate Partner Id
     * Get Brands Permitted to Sell
     */
    public void populatePartnerId(){
        List<Contact> conList = new List<Contact>();
        String permittedBrands;
        if(string.isNotBlank(newLead.Partner_Contact__c)){
            conList =
            [
                SELECT Id, AccountId, Account.Partner_ID__c, Account.Permitted_Brands__c, Account.Partner_Type__c
                FROM Contact
                WHERE id=:newLead.Partner_Contact__c
            ];
        }
        if(conList!=null && conList.size() > 0){
            system.debug('First=');
            newLead.LeadPartnerID__c = conList[0].Account.Partner_ID__c;
            newLead.Partner_Account__c = conList[0].Account.Id;
            PartnerAccountType = conList[0].Account.Partner_Type__c;
            permittedBrands = conList[0].Account.Permitted_Brands__c;
        } else {
            system.debug('Third=');
            newLead.LeadPartnerID__c = null;
            newLead.Partner_Contact__c = null;
            newLead.Partner_Account__c = null;
            PartnerAccountType = null;
        }
        updateBrandPicklist(permittedBrands);
    }
    //End

    //Relayware
    public class partnerWrapper{
        public string partnerId;
        public string AccountId;
        public string accPartnerId;
        public string accSignupLink;
        public string accName;
        public string accInsideSalesRep;
        public string accCurrentOwner;
        public string accUltimateParentAccountID;
        public string accCurrentOwnerName;
        public string accVarterritory;
        public string contactId;

        public partnerWrapper(string partnerId,string AccountId,string accPartnerId,string accSignupLink,string accName,string accInsideSalesRep,
                              string accCurrentOwner,string accUltimateParentAccountID,string accCurrentOwnerName,string accVarterritory,string contactId){
            this.partnerId = partnerId;
            this.AccountId = AccountId;
            this.accPartnerId = accPartnerId;
            this.accSignupLink = accSignupLink;
            this.accName = accName;
            this.accInsideSalesRep = accInsideSalesRep;
            this.accCurrentOwner = accCurrentOwner;
            this.accUltimateParentAccountID = accUltimateParentAccountID;
            this.accCurrentOwnerName = accCurrentOwnerName;
            this.accVarterritory = accVarterritory;
            this.contactId = contactId;
        }
    }

    public SelectOption[] getLeadExistingSolutionProvider()
    {
        return getLeadPicklistValues(Lead.Existing_Solution_Provider__c);
    }

    public SelectOption[] getLeadPromptingChange()
    {
        return getLeadPicklistValues(Lead.Prompting_Change__c);
    }

    public SelectOption[] getLeadCompetitors()
    {
        return getLeadPicklistValues(Lead.Competitors__c);
    }

    public SelectOption[] getLeadDecisionMakers()
    {
        return getLeadPicklistValues(Lead.Decision_Maker__c);
    }

    public SelectOption[] getLeadCurrentlyInContract()
    {
        return getLeadPicklistValues(Lead.Currently_in_a_contract__c);
    }

    public SelectOption[] getLeadProjectBudget()
    {
        return getLeadPicklistValues(Lead.Project_budget__c);
    }

    private SelectOption[] getLeadPicklistValues(Schema.SObjectField picklist)
    {
        List<SelectOption> result = new List<SelectOption>();
        if (!FIELDS_TO_SKIP_ADDING_NONE.contains(picklist)) {
            result.Add(new SelectOption('', PICKLIST_NONE));
        }

        List<Schema.PicklistEntry> values = picklist.getDescribe().getPicklistValues();
        for (Schema.PicklistEntry entry  : values)
        {
            if (entry.isActive())
            {
                result.add(new SelectOption(entry.getValue(), entry.getLabel()));
            }
        }

        return result;
    }
}