/*************************************************
ConvertLeadOptimize class
This Class is used by convertLeadVFPage.page which over-rides Convert button for Lead object in SFDC.
Using details of lead this class searches for possible contact matches based on phone and email.
Then it looks at the Accounts associated to those contacts to see if there are any ActivePipe Opportunities.
The page shows agent that there already exists an Account which has the same contact information and if it is protected at all.
Agent can choose to select the matching Account, search for an account they know matchs or create a brand new account.
If merging only a new Opportunity is made which is tied to the existing Account and Contact.
/************************************************/

public with sharing class ConvertLeadOptimize {
    // Constructor - this only really matters if the autoRun function doesn't work right
    public Lead leadObj{get;set;}
    List<Account> a = new List<Account>();
    List<Contact> c = new List<Contact>();
    List <PriceBook2> brandPriceBooks = new List <PriceBook2>();
    public Boolean matchFound = false;
    public Boolean matchNotFound = true;
    public Boolean notAnswered = false;
    public Boolean showMandatoryFieldPanel{get;set;}// ConvertLead Mandatory field popup Project. Added on 4th April,14
    public String impErrorMsg {get; set;} // Variable to contain error message-Added on 4th April,14
    //code by indiateam
    public Boolean agni = false;
    public Boolean Lead_Source;
    public Boolean Initial_Category=Null;
    public Boolean Initial;
    public Boolean submit=true;
    public Boolean Initial_CategoryFlag = false;    //India Team-Sep02
    public String strDebug = '';

    Account selectedAcc;

    Account acc;
    Contact con;
    Opportunity opp;

    List<SelectOption> options = new List<SelectOption>();
    public List<cAccount> accountList {get; set;}
    // code added by India team on 23 July 2010
    public List<cOpportunity> opportunityList {get; set;}
    public List<Opportunity> oppList = new List<Opportunity>();
    //code ended India team on 23 July 2010

    Boolean multiple=false;
    public Boolean createNew = false;

    public partnerDetailWrapper partnerDetailObj;

    public static final String OFFICE_STR = 'office';
    public static final String BRAND_STR = 'RingCentral';
    public static final String BRAND_BT = 'BT Business';
    public static final String BRAND_OTHER_STR = 'RingCentral US';
    public static final string ACCOUNT_TYPE_CUSTOMER = 'Customer';


    public boolean newModel {get; private set;}
    public Quote createdQuote;
    public Id createdOpportunityId;
    //contain picklists values
    public String brand {get; set;}
    public String product {get; set;}
    public String edition {get; set;}
    public String term {get; set;}
    //contain picklists options
    public String brandValues {get; set;}
    public String productValues {get; set;}
    public String editionValues {get; set;}
    public String termValues {get; set;}

    public Boolean isProductDisabled {get; set;}
    public Boolean isEditionDisabled {get; set;}
    public Boolean isTermDisabled {get; set;}
    public Boolean isForecastedUsersDisabled {get; set;}

    //B-3780 set this flag true if RC Meetings service is chosen
    private Boolean isBillingOpty = false;

    //Start of Case 04932320 SDR Scheduled Appointment Task Tweaks
    Map<Id,task> mTaskToUpdate = new Map<Id,task>();
    //End of Case 04932320 SDR Scheduled Appointment Task Tweaks

    public ConvertLeadOptimize() {
        showMandatoryFieldPanel = false; // ConvertLead Mandatory field popup Project. Added on 4th April,14
        Boolean isLeadDeleted = false;

        newModel = false;
        //Set default value for RC Brand picklist
        brand = BRAND_STR;

        //B-681 Relayware Lead Conversion.
        //Constructor now may be called from REST request.
        ConvertLeadParameters requestParams;
        if (UserInfo.getName() == 'API User'){
            System.debug('request body: ' + RestContext.request.requestBody.toString());
            requestParams = (ConvertLeadParameters)JSON.deserialize(RestContext.request.requestBody.toString(),
                    ConvertLeadParameters.class);
            if (requestParams.newmodel){
                newmodel = true;
            }
        }else{
            if(ApexPages.currentPage().getParameters().get('newmodel') == '1') {
                newModel = true;
            }
        }


        try {
            if(accountList == null) {
                accountList = new List<cAccount>();
            }
            // code added by India team on 23 July 2010
            if(opportunityList == null) {
                opportunityList = new List<cOpportunity>();
            }
            // code ended by India team on 23 July 2010
            // New LeadPartnerID__c field is use for seting Partner Id in Account & Opportunity
            try {
                //B-681
                String leadId;
                if (UserInfo.getName() == 'API User') {
                    leadId = requestParams.leadId;
                } else {
                    leadId = ApexPages.currentPage().getParameters().get('id');
                }
                //B-681
                leadObj = new Lead();
                leadObj = [
                        SELECT Id,Partner_Contact__c,Partner_Account__c,City__c,State__c,Country__c,Zip_Code__c,
                                RC_Edition__c, RC_Term__c,CurrencyIsoCode, City,Country,PostalCode,State,Street,
                                Company,Description,Email,FirstName,LastName,Number_of_Users__c, LeadSource, Name,
                                NumberOfEmployees,OwnerId,Phone,Title,Account_Number__c, Timezone__c, Street_2__c,
                                website,Lead_Brand_Name__c, industry,phone_ext__c,isconverted,Notes__c, Account__c,
                                Initial_Category__c, User_ID__c, Agent_Email_Address__c,Lead_Tier_Name__c,
                                Referrer_FName__c,Referrer_LName__c,Referrer_Email__c  , NumberOfEmployees__c ,
                                Number_of_Locations__c,Partner_ID__c, Estimated_Close_Date__c, LeadPartnerID__c,
                                InContract__c , Pain__c, Pain_Impact__c, Gain__c, Gain_Impact__c, Ideal_Solution__c,
                                Effective_No_of_Employees_Range__c, Benefits__c, Next_Steps_questions__c,
                                RecordTypeName__c, Partner_Lead_Owner__c, Inside_Sales_Rep__c,
                                Employees_Override__c, Forecasted_Contact_Center_Users__c, Company_DUNS__c,
                                Lead_Entry_Source__c, Bt_Cug_Number__c, Installation_Service_Provider__c
                        FROM Lead
                        WHERE id=:leadId
                ];

            } catch(Exception e) {
                isLeadDeleted = true;
            }

            if(leadObj.email != null && leadObj.email != Emails__c.getall().get('fake').Email_Address__c && leadObj.phone != null) {   // Condition 1
                try {
                    /* Fetching Contacts and related account */
                    Map<Id, Contact> cMap = new Map<id, Contact>([
                            SELECT Id, Name,Email, AccountId,Phone, Account.Name, Account.RC_User_ID__c,
                                    Account.RC_Account_Number__c,
                                    Account.RC_Account_Status__c, Account.Website, Account.NumberOfEmployees,
                                    Account.Industry, Account.No_of_Employees__c, Account.Number_Of_Locations__c
                            FROM Contact
                            WHERE
                            (Email = :leadObj.email OR Phone = :leadObj.phone
                            OR (Account.RC_User_ID__c =: leadObj.User_ID__c AND Account.RC_User_ID__c != '' ))
                            AND Account.Type = :ACCOUNT_TYPE_CUSTOMER
                            LIMIT 1000]);

                    System.debug('Contact Map '+cMap);
                    Set<Id> accountids = new Set<Id>();
                    if(cMap != null) {
                        for(Id contactid: cMap.keySet()) {
                            Contact conObj = cMap.get(contactid);
                            /*Code for Customer prpfile*/
                            if(conObj.Account != null) {
                                if(leadObj.Website != NULL) {
                                    conObj.Account.Website = leadObj.Website;
                                }
                                if(leadObj.NumberOfEmployees != NULL){
                                    conObj.Account.NumberOfEmployees = leadObj.NumberOfEmployees;
                                }
                                if(leadObj.Industry != NULL){
                                    conObj.Account.Industry = leadObj.Industry;
                                }
                                /*****New Employee Override Field Update*****/
                                if(leadObj.Effective_No_of_Employees_Range__c != NULL){
                                    conObj.Account.No_of_Employees__c = leadObj.Effective_No_of_Employees_Range__c;
                                }
                                /*******************************************/
                                if(leadObj.Number_of_Locations__c != NULL){
                                    conObj.Account.Number_Of_Locations__c = leadObj.Number_of_Locations__c;
                                }
                                accountList.add(new cAccount(conObj.Account,conObj.Account.RC_User_ID__c,conObj.Account.RC_Account_Number__c,
                                        conObj.Account.RC_Account_Status__c, contactid)); // add conObj.Id by Moskvin A.A. at 03.10.2016 (reason: optimization of the number of requests)
                                accountids.add(conObj.AccountId);
                                System.debug('add new cAcc. contactid >> ' + contactid);
                            }
                        }
                    }

                    if(accountids.size() > 0) {
                        /*fetching related Opportunity*/
                        /*RecordType.Name should be add on sand box*/
                        Map<id, Opportunity> oMap = new Map<id, Opportunity>([Select StageName, Opportunity.Owner.Name, Name,Opportunity.Account.Name,
                                CreatedDate,Last_Touched_Date__c From Opportunity where
                        AccountId IN :accountids AND StageName IN : OpportunityHelper.alteredStages
                        AND RecordType.Name ='Sales Opportunity']);
                        if(oMap != null) {
                            for(Id oppid: oMap.keySet()) {
                                Opportunity oppObj =   oMap.get(oppid);
                                opportunityList.add(new cOpportunity(oppObj,oppObj.Name,oppObj.Owner.Name,oppObj.Account.Name,oppObj.StageName,
                                        oppObj.CreatedDate,oppObj.Last_Touched_Date__c));
                            }
                        }
                    }
                } catch(Exception e){
                    /* handle here your exception */
                }
            } else if(leadObj.email != null && leadObj.email != Emails__c.getall().get('fake').Email_Address__c && leadObj.phone == null) {        // Condition 2
                /*New Opt Code*/
                try {
                    /* Fetching Contacts and related account */
                    Map<Id, Contact> cMap = new Map<id, Contact>([
                            SELECT Id, Name,Email, AccountId,Phone, Account.Name, Account.RC_User_ID__c,
                                    Account.RC_Account_Number__c, Account.RC_Account_Status__c, Account.Website,
                                    Account.NumberOfEmployees, Account.Industry, Account.No_of_Employees__c,
                                    Account.Number_Of_Locations__c
                            FROM Contact
                            WHERE
                            (Email = :leadObj.email
                            OR (Account.RC_User_ID__c = :leadObj.User_ID__c AND Account.RC_User_ID__c != ''))
                            AND Account.Type = :ACCOUNT_TYPE_CUSTOMER
                            LIMIT 1000]);

                    System.debug('Contact Map '+cMap);
                    Set<Id> accountids = new Set<Id>();
                    if(cMap != null) {
                        for(Id contactid: cMap.keySet()) {
                            Contact conObj = cMap.get(contactid);
                            /*Code for Customer prpfile*/
                            if(conObj.Account != null) {
                                if(leadObj.Website != NULL){
                                    conObj.Account.Website = leadObj.Website;
                                }
                                if(leadObj.NumberOfEmployees != NULL){
                                    conObj.Account.NumberOfEmployees = leadObj.NumberOfEmployees;
                                }
                                if(leadObj.Industry != NULL){
                                    conObj.Account.Industry = leadObj.Industry;
                                }
                                /*****New Employee Override Field Update*****/
                                if(leadObj.Effective_No_of_Employees_Range__c != NULL){
                                    conObj.Account.No_of_Employees__c = leadObj.Effective_No_of_Employees_Range__c;
                                }
                                /*******************************************/
                                if(leadObj.Number_of_Locations__c != NULL){
                                    conObj.Account.Number_Of_Locations__c = leadObj.Number_of_Locations__c;
                                }
                                accountList.add(new cAccount(conObj.Account,conObj.Account.RC_User_ID__c,conObj.Account.RC_Account_Number__c,
                                        conObj.Account.RC_Account_Status__c, contactid)); // add conObj.Id by Moskvin A.A. at 03.10.2016 (reason: optimization of the number of requests)
                                accountids.add(conObj.AccountId);
                            }
                        }
                    }

                    if(accountids.size() > 0) {
                        /*fetching related Opportunity*/
                        /*RecordType.Name should be add on sand box*/
                        Map<id, Opportunity> oMap = new Map<id, Opportunity>([Select StageName, Opportunity.Owner.Name, Name,Opportunity.Account.Name,
                                CreatedDate,Last_Touched_Date__c, Partner_ID__c
                        From Opportunity where AccountId IN :accountids AND
                        StageName IN : OpportunityHelper.alteredStages AND (RecordType.Name ='Sales Opportunity'
                        OR RecordTypeId = NULL)]);
                        if(oMap != null) {
                            for(Id oppid: oMap.keySet()) {
                                Opportunity oppObj =   oMap.get(oppid);
                                opportunityList.add(new cOpportunity(oppObj,oppObj.Name,oppObj.Owner.Name,oppObj.Account.Name,oppObj.StageName,
                                        oppObj.CreatedDate,oppObj.Last_Touched_Date__c));
                            }
                        }
                    }
                } catch(Exception e) {
                    /* handle here your exception */
                }
                /*End Here*/
            } else if((leadObj.email == null || leadObj.email == Emails__c.getall().get('fake').Email_Address__c) && leadObj.phone != null) {      // Condition 3
                /*New Opt Code Start here*/
                try {
                    /* Fetching Contacts and related account */
                    Map<Id, Contact> cMap = new Map<id, Contact>([
                            SELECT Id, Name,Email, AccountId,Phone, Account.Name, Account.RC_User_ID__c,
                                    Account.RC_Account_Number__c, Account.RC_Account_Status__c, Account.Website,
                                    Account.NumberOfEmployees, Account.Industry, Account.No_of_Employees__c,
                                    Account.Number_Of_Locations__c
                            FROM Contact
                            WHERE
                            (Phone = :leadObj.phone
                            OR (Account.RC_User_ID__c =: leadObj.User_ID__c AND Account.RC_User_ID__c != '' ))
                            AND Account.Type = :ACCOUNT_TYPE_CUSTOMER
                            LIMIT 1000]);

                    System.debug('Contact Map '+cMap);
                    Set<Id> accountids = new Set<Id>();
                    if(cMap != null) {
                        for(Id contactid: cMap.keySet()) {
                            Contact conObj = cMap.get(contactid);
                            /*Code for Customer prpfile*/
                            if(conObj.Account != null) {
                                if(leadObj.Website != NULL) {
                                    conObj.Account.Website = leadObj.Website;
                                }
                                if(leadObj.NumberOfEmployees != NULL) {
                                    conObj.Account.NumberOfEmployees = leadObj.NumberOfEmployees;
                                }
                                if(leadObj.Industry != NULL) {
                                    conObj.Account.Industry = leadObj.Industry;
                                }
                                /*****New Employee Override Field Update*****/
                                if(leadObj.Effective_No_of_Employees_Range__c != NULL) {
                                    conObj.Account.No_of_Employees__c = leadObj.Effective_No_of_Employees_Range__c;
                                }
                                /*******************************************/
                                if(leadObj.Number_of_Locations__c != NULL) {
                                    conObj.Account.Number_Of_Locations__c = leadObj.Number_of_Locations__c;
                                }
                                accountList.add(new cAccount(conObj.Account,conObj.Account.RC_User_ID__c,conObj.Account.RC_Account_Number__c,
                                        conObj.Account.RC_Account_Status__c, contactid)); // add conObj.Id by Moskvin A.A. at 03.10.2016 (reason: optimization of the number of requests)
                                accountids.add(conObj.AccountId);
                            }
                        }
                    }
                    if(accountids.size() > 0) {
                        /*fetching related Opportunity*/
                        /*RecordType.Name should be add on sand box*/
                        Map<Id, Opportunity> oMap = new Map<id, Opportunity>([Select StageName, Opportunity.Owner.Name, Name,Opportunity.Account.Name,
                                CreatedDate,Last_Touched_Date__c, Partner_ID__c
                        From Opportunity where AccountId IN :accountids AND
                        StageName IN : OpportunityHelper.alteredStages AND (RecordType.Name ='Sales Opportunity'
                        OR RecordTypeId = NULL )]);
                        if(oMap != null) {
                            for(Id oppid: oMap.keySet()) {
                                Opportunity oppObj =   oMap.get(oppid);
                                /*Inserting Partner ID*/
                                oppObj.Partner_ID__c = leadObj.LeadPartnerID__c;
                                opportunityList.add(new cOpportunity(oppObj,oppObj.Name,oppObj.Owner.Name,oppObj.Account.Name,oppObj.StageName,
                                        oppObj.CreatedDate,oppObj.Last_Touched_Date__c));
                            }
                        }
                    }
                } catch(Exception e) {
                    /* handle here your exception */
                }
                /*End Here*/
            } //code by indiateam - Sep 02
            strDebug = leadObj.LeadSource + '----' + leadObj.Initial_Category__c;
            if(leadObj.LeadSource == 'Initial' && leadObj.Initial_Category__c == null) {
                Initial_CategoryFlag = true;
            }
            if(!accountList.isEmpty()) {
                matchFound = true;
                matchNotFound = false;
            }else {
                matchFound = false;
                matchNotFound = true;
            }
            if (UserInfo.getName() == 'API User'){
                strId = requestParams.leadId;
            } else {
                strId = ApexPages.currentPage().getParameters().get('Id');
            }
            if(!String.isBlank(strId)) {
                toShowViewMode = false;

                loadLeadQualBasicDet();
                loadLeadBasicInfo();
            }
        } catch(Exception ex) {
            String msg = ex.getMessage();
            msg = 'This lead is already removed or referenced to other lead!';
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, msg));
        }
    }

    /*Code Added by India Team 02 Sep */
    List<String> listInitialCategory;
    // code for Initial Category, added by India Team
    public List<String>  getListInitialCategoryValues() {
        List<String> options = new List<String>();
        Schema.DescribeFieldResult fieldResult = Lead.Initial_Category__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry f : ple) {
            options.add(f.getValue());
        }
        listInitialCategory = options;
        return listInitialCategory;
    }

    String initialCategory;
    public List<SelectOption> getListInitialCategoryItems() {
        List<SelectOption> options = new List<SelectOption>();
        listInitialCategory =  getListInitialCategoryValues();
        if(listInitialCategory != null) {
            for(Integer counter=0; counter<listInitialCategory.size(); counter++) {
                options.add(new SelectOption(listInitialCategory.get(counter), listInitialCategory.get(counter)));
            }
        }
        return options;
    }

    public String getInitialCategory() {
        return initialCategory;
    }

    public void setInitialCategory(String initialCategory) {
        this.initialCategory = initialCategory;
    }

    public PageReference updateLeadCategory() {
        try {
            leadObj.Initial_Category__c = getInitialCategory();
            update leadObj;
        } catch (Exception ex){}
        PageReference pageRef = ApexPages.currentPage();
        pageRef.setRedirect(true);
        return pageRef;
    }

    public PageReference GoBack() {
        String previousPage = System.currentPageReference().getParameters().get('retURL');
        PageReference newPage = new PageReference(previousPage);
        newPage.setRedirect(true);
        return newPage;
    }
    /*End */

    /*
    convertAndMerge() takes the selection by user and compelts the action.
    First some error checking takes place to make sure only one option was selection and that a selection was made.
    If a account was found by the agent then we convert the lead into that account using the Database.LeadConvert operations.
    If the agent selected on of the accounts we found we convert the lead into that account again with Database.LeadConvert.
    If neither of those options were used then we call the convert() method which creates an new set of Account/Contact/Opporunity.
    */
    List<Note> noteList = new List<Note>();
    public PageReference convertAndMerge() {
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
        TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
        if (String.isBlank(leadObj.Company_DUNS__c)){
            TriggerHandler.BY_PASS_CONTACT_ON_INSERT();
        }
        TriggerHandler.BY_PASS_CONTACT_ON_UPDATE();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE();

        Savepoint sp = null;

        PageReference pageRef2 = null;

        try {
            sp = Database.setSavepoint();

            if((leadObj.Company != null && (leadObj.Company).equalsIgnoreCase('PhoneOnly'))
                    && (leadObj.Name != null && (leadObj.Name).equalsIgnoreCase('Phone Only'))
                    && (leadObj.Email != null && (leadObj.Email).equalsIgnoreCase(Emails__c.getall().get('fake').Email_Address__c)) ) {

                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,
                        'Please update the contact details on Company Name, Contact Name, or Email to the appropriate information.'));
                return ApexPages.currentPage();
            }

            List<Account> selectedAccounts = new List<Account>();
            Map<Id, Id> selectedAccToContactId = new Map<Id, Id>(); // added 03.10.2016 by Moskvin A.A. (reason: optimization of the number of requests)
            // Go through the list of Accounts we listed and add the selected ones to a seperate List
            for(cAccount cAcc : getAccounts()) {
                if(cAcc.selected == true) {
                    selectedAccounts.add(cAcc.acc);
                    selectedAccToContactId.put(cAcc.acc.Id, cAcc.contactId); // added 03.10.2016 by Moskvin A.A. (reason: optimization of the number of requests)
                }
            }

            // Make sure there has not been more than 1 selection from all three options, return with error
            if((selectedAccounts.size() > 1) || (selectedAccounts.size() >= 1 && createNew == true) || (selectedAccounts.size() >= 1 &&
                    leadObj.Account__c != null) || (createNew == true && leadObj.Account__c != null)) {
                multiple = true;
                notAnswered = false;
                System.debug('multiple accounts were selected');
                return ApexPages.currentPage();
            }
            multiple = false;
            System.debug('multiple accounts were not selected');

            // If there have been no selections made return with error
            if(selectedAccounts.isEmpty() && createNew != true && leadObj.Account__c == null) {

                notAnswered = true;
                //India Team 02 Sep
                if(leadObj.LeadSource == 'Initial' && leadObj.Initial_Category__c == null) {
                    Initial_CategoryFlag = true;
                    return ApexPages.currentPage();
                }
                System.debug('before adding message');
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,'Choose existing account or check "Create new Account"'));
                return null;
            }

            notAnswered = false;

            //India Team 02 Sep
            if(leadObj.LeadSource == 'Initial' && leadObj.Initial_Category__c == null) {
                Initial_CategoryFlag = true;
                return ApexPages.currentPage();
            }

            //Start of Case 04932320 SDR Scheduled Appointment Task Tweaks
            if(leadObj.RecordTypeName__c == 'Sales_Leads'){
                Id taskRecordType = Schema.SObjectType.Task.getRecordTypeInfosByName().get('SDR Scheduled Appointment').getRecordTypeId();
                mTaskToUpdate = new map<Id,task>([select Id, SDR_Meeting_Status__c from Task where recordtypeid =: taskRecordType AND WhoId =:leadObj.Id]);
            }
            //End of Case 04932320 SDR Scheduled Appointment Task Tweaks

            //B-2781 ABM&S logic
            if (String.isNotBlank(leadObj.Company_DUNS__c)) {
                delete [SELECT Id FROM Company_Persons__c WHERE Lead__c = :leadObj.Id];
            }

            // /*
            // If user browsed for an account themseleves
            if(leadObj.Account__c != null) {
                //Get list of Notes before Lead is converted, else this list is gone after lead has been converted
                System.debug('Lead notes size= : ' + leadNotes.size() + 'timezone= '+ strLeadTimeZone);
                System.debug('this is leadObj.account: ' + leadObj.Account__c);

                Database.LeadConvert lc = new database.LeadConvert();
                lc.setLeadId(leadObj.id);
                lc.setOwnerId(UserInfo.getUserId());
                lc.setAccountId(leadObj.account__c);

                try {
                    Contact c = [SELECT id FROM Contact WHERE AccountId =: leadObj.account__c LIMIT 1];
                    lc.setContactId(c.Id);
                }catch(System.QueryException e) {
                    System.debug('there was no contact on the account');
                }

                if (String.isNotBlank(leadObj.Bt_Cug_number__c)) {
                    List<Account> accForCheckCug = [SELECT Id, Name from Account WHERE Bt_Cug_Number__c = :leadObj.Bt_Cug_Number__c LIMIT 1];
                    if (accForCheckCug.size() > 0 && accForCheckCug[0].Id != leadObj.Account__c) {
                        String link = '<a href ="'
                                + URL.getOrgDomainUrl().toExternalForm() + '/' + accForCheckCug[0].Id + '">' + accForCheckCug[0].Name + '</a>';
                        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, ('CUG Number is already in use by' + link)));
                        return null;
                    }
                }

                lc.setConvertedStatus(convertStatus.MasterLabel);

                if(leadObj.RecordTypeName__c == 'Partner_Leads') {
                    PartnerLeadConvertResult cres = convertPartnerLead(lc);
                    if (cres.VFresult != null){
                        return cres.VFresult;
                    }
                }

                Database.LeadConvertResult lcr = Database.convertLead(lc);
                System.assert(lcr.isSuccess());

                updateExOpportunityContactRole(lcr);

                //Added for passing Support Agent e-mail to Account

                try {
                    Account agentMailAcc = new Account(Id = lc.getAccountId());
                    agentMailAcc = mapLeadToAccountFields(agentMailAcc);    // updateQualificationVal(leadObj,lc.getAccountId());
                    update agentMailAcc;
                }catch(System.QueryException e) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error,'6'+e.getMessage()));
                    System.debug('there was an error while passing the Agnet email to Account');
                }

                Opportunity newOpp = new Opportunity (
                        id = lcr.getOpportunityId()
                );
                newOpp = prepareOpportunity(newOpp,'Existing Business');

                // set RecordType to Opportunity
                Id newOppRtId = populateOppRecordType(leadObj.RecordTypeName__c);
                if( newOppRtId != null ) {
                    newOpp.RecordTypeId = newOppRtId;
                }

                if(noteList != null && noteList.size()>0) {
                    insert noteList;
                }

                TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE();
                setCampaignInfluence(leadObj, newOpp);

                update newOpp;

                // send user to newly create Opportunity
                if(newModel){
                    //createQuote(newOpp, leadObj);
                    createdOpportunityId = newOpp.Id;
                }

                if(!newModel) {
                    PageReference pageRef = new ApexPages.StandardController(newOpp).view();
                    pageRef.setRedirect(true);
                    TriggerHandler.RESET_VARIABLES();
                    return pageRef;
                }

            } else if(selectedAccounts.size() == 1) {
                System.debug('Lead notes size= : ' + leadNotes.size());
                // user has selected one of the accounts we found for them
                Account selectedAcc = selectedAccounts.get(0);
                Database.LeadConvert lc = new database.LeadConvert();

                lc.setLeadId(leadObj.id);
                lc.setOwnerId(UserInfo.getUserId());
                lc.setAccountId(selectedAcc.Id);

                Id contactId = selectedAccToContactId.get(selectedAcc.Id); // added 03.10.2016 by Moskvin A.A. (reason: optimization of the number of requests)
                lc.setContactId(contactId);

                lc.setConvertedStatus(convertStatus.MasterLabel);

                if (String.isNotBlank(leadObj.Bt_Cug_number__c)) {
                    List<Account> accForCheckCug = [SELECT Id, Name from Account WHERE Bt_Cug_Number__c = :leadObj.Bt_Cug_Number__c LIMIT 1];
                    if (accForCheckCug.size() > 0 && accForCheckCug[0].Id != selectedAccounts[0].Id) {
                        String link = '<a href ="'
                                + URL.getOrgDomainUrl().toExternalForm() + '/' + accForCheckCug[0].Id + '">' + accForCheckCug[0].Name + '</a>';
                        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, ('CUG Number is already in use by' + link)));
                        return null;
                    }
                }

                if(leadObj.RecordTypeName__c == 'Partner_Leads') {
                    PartnerLeadConvertResult cres = convertPartnerLead(lc);
                    if (cres.VFresult != null){
                        return cres.VFresult;
                    }
                }

                Database.LeadConvertResult lcr = Database.ConvertLead(lc);
                System.assert(lcr.isSuccess());

                updateExOpportunityContactRole(lcr);

                //  Added for passing Support Agent e-mail to Account
                try {
                    Account agentMailAcc = new Account(Id = lc.getAccountId());
                    agentMailAcc = mapLeadToAccountFields(agentMailAcc);
                    upsert agentMailAcc;
                }catch(System.QueryException e) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error,'8'+e.getMessage()));
                    System.debug('there was an error while passing the Agnet email to Account');
                }

                Opportunity newOpp = new Opportunity(
                        id = lcr.getOpportunityId()
                );
                newOpp = prepareOpportunity(newOpp,'Existing Business');

                // set RecordType to Opportunity
                Id newOppRtId = populateOppRecordType(leadObj.RecordTypeName__c);
                if( newOppRtId != null ) {
                    newOpp.RecordTypeId = newOppRtId;
                }

                if(noteList != null && noteList.size()>0) {
                    insert noteList;
                }

                Triggerhandler.BY_PASS_OPPORTUNITY_ON_UPDATE();
                setCampaignInfluence(leadObj, newOpp);

                update newOpp;

                if(newModel) {
                    createdOpportunityId = newOpp.Id;
                }
                if(!newModel) {
                    // send user to newly create Opportunity
                    PageReference pageRef = new ApexPages.StandardController(newOpp).view();
                    pageRef.setRedirect(true);
                    TriggerHandler.RESET_VARIABLES();
                    return pageRef;
                }
            }

            System.debug('before convert call');
            pageRef2 = convert();

        }
        //Azimzhanov Evgenii
        catch (CustomException ce) {
            //for custom exception we do nothing, because apexMessage's already shown in code, so we don't add any message.
        }
        catch(Exception ex) {
            if (ex.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error,ex.getDmlMessage(0)));
            }else{
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            }
            Database.rollback(sp);


            TriggerHandler.RESET_VARIABLES();
            return null;

        }
        TriggerHandler.RESET_VARIABLES();
        return pageRef2;
    }

    /*
    convert() uses the standard convert database method to create a new set of data.
    Some fields on the contact/opportunity and account that are not currently used are cleared out.
    */
    public PageReference convert() {
        System.debug('in convert method');
        try{
            Datetime myDT = Datetime.now();
            Date mydate = date.today();

            Boolean currentLeadAlreadyConverted = [select Id, IsConverted from Lead where Id = :leadObj.Id].IsConverted;

            if(currentLeadAlreadyConverted == false) {
                System.debug('THIS IS LEAD ID TO CONVERT: ' + leadObj.Id);
                System.debug('THIS IS LEAD ISCONVERTED: ' + leadObj.isconverted);

                Database.LeadConvert lc = new database.LeadConvert();
                lc.setLeadId(leadObj.Id);
                lc.setConvertedStatus(convertStatus.MasterLabel);

                if (String.isNotBlank(leadObj.Bt_Cug_number__c)) {
                    List<Account> accForCheckCug = [SELECT Id, Name from Account WHERE Bt_Cug_Number__c = :leadObj.Bt_Cug_Number__c LIMIT 1];
                    if (accForCheckCug.size() > 0) {
                        String link = '<a href ="'
                                + URL.getOrgDomainUrl().toExternalForm() + '/' + accForCheckCug[0].Id + '">' + accForCheckCug[0].Name + '</a>';
                        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, ('CUG Number is already in use by' + link)));
                        return null;
                    }
                }

                if(leadObj.RecordTypeName__c == 'Partner_Leads') {
                    PartnerLeadConvertResult cres = convertPartnerLead(lc);
                    if (cres.VFresult != null){
                        return cres.VFresult;
                    }
                }

                Database.LeadConvertResult lcr = Database.convertLead(lc);
                System.assert(lcr.isSuccess());

                updateExOpportunityContactRole(lcr);

                acc = new Account(Id = lcr.getAccountId());
                con = new contact(Id = lcr.getContactId());
                opp = new  Opportunity(
                        Id = lcr.getOpportunityId()
                );

                // Set fields on Contact/Opp/Account to what we want them to be.
                con.Description = leadObj.Description;
                con.Email = leadObj.Email;
                con.FirstName = leadObj.FirstName;
                con.LastName = leadObj.LastName;
                con.LeadSource = leadObj.LeadSource;
                con.MailingCity = leadObj.City;
                con.MailingCountry = leadObj.Country;
                con.MailingPostalCode = leadObj.PostalCode;
                con.MailingState = leadObj.State;
                con.MailingStreet = leadObj.Street;
                con.Street_2__c = leadObj.Street_2__c;
                con.OwnerId = leadObj.OwnerId;
                con.Phone = leadObj.Phone;
                con.Phone_Ext__c = leadObj.Phone_Ext__c;
                con.Title = leadObj.Title;
                con.indexedPhone__c =  leadObj.Phone;
                con.indexedEmail__c = leadObj.email;
                con.Lead_Entry_Source__c = leadObj.Lead_Entry_Source__c;

                opp.Website__c = leadObj.Website;
                opp = prepareOpportunity(opp,'New Business');

                // set RecordType to Opportunity
                Id newOppRtId = populateOppRecordType(leadObj.RecordTypeName__c);
                if( newOppRtId != null ) {
                    opp.RecordTypeId = newOppRtId;
                }

                if(noteList != null && noteList.size()>0) {
                    insert noteList;
                }

                // Account fields are being set to null because in the beigining we were not using them. This should be reviewed.
                acc.Phone = acc.Industry = acc.Description = acc.BillingStreet = null;
                acc.BillingCity = acc.BillingCountry = acc.BillingPostalCode = acc.BillingState = acc.ShippingCity = null;
                acc.ShippingCountry= acc.ShippingPostalCode = acc.ShippingState = acc.ShippingStreet =acc.Website = null;
                acc.NumberOfEmployees = null;

                //Relayware
                acc.BillingStreet = leadObj.Street;
                acc.BillingCountry = ( leadObj.Country != null ? leadObj.Country : leadObj.Country__c);
                acc.BillingState = (leadObj.State !=null ? leadObj.State : leadObj.State__c);
                acc.BillingCity = (leadObj.City != null ? leadObj.City : leadObj.City__c);
                acc.BillingPostalCode = (leadObj.PostalCode != null ? leadObj.PostalCode : leadObj.Zip_Code__c);
                //End

                //Relayware
                if(string.isBlank(acc.BillingCountry)){
                    if(leadObj.Lead_Brand_Name__c != NULL &&
                            (leadObj.Lead_Brand_Name__c.equalsIgnoreCase('RingCentral UK') || leadObj.Lead_Brand_Name__c.equalsIgnoreCase('BT Business'))){
                        acc.BillingCountry = 'United Kingdom';
                    } else if(leadObj.Lead_Brand_Name__c != NULL && leadObj.Lead_Brand_Name__c.equalsIgnoreCase('RingCentral Canada')){
                        acc.BillingCountry = 'Canada';
                    } else {
                        acc.BillingCountry = 'United States';
                    }
                }
                //End

                acc.RC_Sync_Status__c = 'Pending';

                /*  Update Customer profile new request  */

                acc = mapLeadToAccountFields(acc);

                /*****New Employee Override Field Update*****/
                if(leadObj.Website != NULL || leadObj.NumberOfEmployees != NULL || leadObj.Industry != NULL || leadObj.Effective_No_of_Employees_Range__c != NULL
                        || leadObj.Number_of_Locations__c != NULL) {
                    acc.Customer_Profile_Last_modified_Date__c = System.now();
                }
                /*******************************************/

                //Start of Case 04932320 SDR Scheduled Appointment Task Tweaks
                if(mTaskToUpdate.size()>0){
                    list<task>  lTask = new list<task>();
                    for(task t: mTaskToUpdate.values()){
                        if(t.SDR_Meeting_Status__c != 'Accepted'){
                            t.SDR_Meeting_Status__c = 'Accepted';
                            lTask.add(t);
                        }
                    }
                    if(lTask.size()>0){update lTask;}
                }
                //End of Case 04932320 SDR Scheduled Appointment Task Tweaks

                setCampaignInfluence(leadObj, opp);

                update con;
                update acc;
                update opp;


                /************************ Add DEFAULT PRODUCT case # 04504707 ******************/
                if(newModel) {
                    createdOpportunityId = opp.Id;
                } else {
                    // send user to newly create Opportunity
                    PageReference pageRef = new ApexPages.StandardController(opp).view();
                    pageRef.setRedirect(true);
                    return pageRef;
                }
            }
        } catch(Exception ex) {
            if (ex.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error,ex.getDmlMessage(0)));
            }else{
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            }

            System.debug('lead convert error >> ' + ex.getMessage());

            throw new CustomException(ex.getMessage());

        }
        return ApexPages.currentPage();
    }

    public PartnerLeadConvertResult convertPartnerLead(Database.LeadConvert leadConvertObj) {
        Datetime myDT = Datetime.now();
        Date mydate = date.today();
        Id partnerOwnerId = null;
        //B-681
        PartnerLeadConvertResult result = new PartnerLeadConvertResult();
        if(leadObj.isconverted == false) {
            TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
            TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
            TriggerHandler.BY_PASS_CONTACT_ON_INSERT();
            TriggerHandler.BY_PASS_CONTACT_ON_UPDATE();
            TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT();
            TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE();
            System.debug('THIS IS LEAD ID TO CONVERT: ' + leadObj.Id);
            System.debug('THIS IS LEAD ISCONVERTED: ' + leadObj.isconverted);

            partnerOwnerId = (leadObj.Partner_Lead_Owner__c != null ? leadObj.Partner_Lead_Owner__c : null);

            System.debug('#### PARTNER LEAD OWNER = : ' + partnerOwnerId);

            Id leadOwner = leadObj.ownerId;
            Group groupObj = getPartnerQueue();

            if(groupObj != null && leadObj.OwnerId == groupObj.Id) {
                //B-681
                result.status = 'failure';
                if (UserInfo.getName() != 'API User'){
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,
                            'This lead is not owned by a user, you must specify a user for the Owner field.'));
                    result.VFresult = ApexPages.currentPage();
                    return result;
                } else {
                    if (result.rwErrors == null){
                        result.rwErrors = new List<String>();
                    }
                    result.rwErrors.add('This lead is not owned by a user, you must specify a user for the Owner field.');
                }
            }

            List<String> lst= System.Label.Skip_PartnerId.subString(1).split(';');
            Set<String> tempSet = new Set<String>();
            tempSet.addAll(lst);

            if(!Test.isRunningTest() && tempSet != null && !tempSet.contains(leadObj.LeadPartnerId__c)) {
                if(String.isNotBlank(leadObj.Partner_Contact__c)) {
                    partnerDetailObj = fetchPartnerContact();
                } else if (String.isNotBlank(leadObj.Partner_Lead_Owner__c)) {
                    partnerDetailObj = fetchPartnerOwner();
                }
                if(partnerDetailObj==NULL) {
                    //B-681

                    String errorMessage = 'Please provide valid Partner Contact or Partner Lead Owner before conversion.';

                    result.status = 'failure';
                    if (UserInfo.getName() != 'API User'){
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
                        result.VFresult = ApexPages.currentPage();

                        throw new CustomException(errorMessage);

                        return result;
                    } else {
                        if (result.rwErrors == null){
                            result.rwErrors = new List<String>();
                        }
                        result.rwErrors.add(errorMessage);
                    }

                }
            }

            //B-681
            if (result.status == 'failure'){
                return result;
            }

            // Id userId =
            Database.LeadConvert lc = new database.LeadConvert();
            lc = leadConvertObj;
            lc.setLeadId(leadObj.id);
            lc.setOwnerId(leadOwner);
            lc.setConvertedStatus(convertStatus.MasterLabel);
            try {
                Database.LeadConvertResult lcr = Database.convertLead(lc);

                updateExOpportunityContactRole(lcr);
                mapOpportunityContactRole(lcr,leadQualificationObj);

                System.assert(lcr.isSuccess());

                acc = new Account(Id = lcr.getAccountId());
                con = new Contact(Id = lcr.getContactId());
                opp = new Opportunity(
                        Id = lcr.getOpportunityId()
                );

                System.debug('#### PARTNER LEAD OWNER 1 = : ' + acc.OwnerId);
            } catch(Exception e) {
                System.debug(' partner lead owner,EXCEPTION AT 9 = '+ e.getMessage());
                //B-681
                result.status = 'failure';
                String address = Emails__c.getall().get('resellers') != null ? Emails__c.getall().get('resellers').Email_Address__c : 'your manager';
                if (UserInfo.getName() != 'API User'){
                    if (e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
                        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error,e.getDmlMessage(0)));
                    }else if(e.getMessage().containsIgnoreCase('This Lead has expired')) {
                        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,
                                'This Lead has expired. It cannot be edited. Please contact <a style="font-size:12px;" href=mailto:' + address + '>' + address + '</a> if you have any questions.'));
                    }else{
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
                    }
                    result.VFresult = ApexPages.currentPage();
                } else {
                    if (result.rwErrors == null){
                        result.rwErrors = new List<String>();
                    }
                    if (e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
                        result.rwErrors.add(e.getDmlMessage(0));
                    }else if(e.getMessage().containsIgnoreCase('This Lead has expired')) {
                        result.rwErrors.add('This Lead has expired. It cannot be edited. Please contact '+ address + ' if you have any questions.');
                    }else{
                        result.rwErrors.add(e.getMessage());
                    }
                }
                return result;
            }
            // Set fields on Contact/Opp/Account to what we want them to be.
            con.Description = leadObj.Description;
            con.Email = leadObj.Email;
            con.FirstName = leadObj.FirstName;
            con.LastName = leadObj.LastName;
            con.LeadSource = leadObj.LeadSource;
            con.MailingCity = leadObj.City;
            con.MailingCountry = leadObj.Country;
            con.MailingPostalCode = leadObj.PostalCode;
            con.MailingState = leadObj.State;
            con.MailingStreet = leadObj.Street;
            con.Street_2__c = leadObj.Street_2__c;

            System.debug('#### PARTNER LEAD OWNER = 2 : ' + acc.OwnerId);
            con.Phone = leadObj.Phone;
            con.Phone_Ext__c = leadObj.Phone_Ext__c;
            con.Title = leadObj.Title;
            con.indexedPhone__c =  leadObj.Phone;
            con.indexedEmail__c = leadObj.email;

            opp.Website__c = leadObj.Website;

            opp = prepareOpportunity(opp,'New Business');
            System.debug('#### PARTNER LEAD OWNER = :3 ' + acc.OwnerId);

            if(noteList != null && noteList.size()>0) {
                insert noteList;
            }

            // Account fields are being set to null because in the beigining we were not using them. This should be reviewed.
            acc.Phone = acc.Industry = acc.Description = acc.BillingStreet = null;
            acc.BillingCity = acc.BillingCountry = acc.BillingPostalCode = acc.BillingState = acc.ShippingCity = null;
            acc.ShippingCountry= acc.ShippingPostalCode = acc.ShippingState = acc.ShippingStreet =acc.Website = null;
            acc.NumberOfEmployees = null;

            //For Relayware
            acc.BillingStreet = leadObj.Street;
            acc.BillingCountry = ( leadObj.Country != null ? leadObj.Country : leadObj.Country__c);
            acc.BillingState = (leadObj.State !=null ? leadObj.State : leadObj.State__c);
            acc.BillingCity = (leadObj.City != null ? leadObj.City : leadObj.City__c);
            acc.BillingPostalCode = (leadObj.PostalCode != null ? leadObj.PostalCode : leadObj.Zip_Code__c);

            if(leadObj.Inside_Sales_Rep__c != null) {
                acc.Inside_Sales_Rep__c = leadObj.Inside_Sales_Rep__c;
            }
            if(acc.Signup_Link__c == null && partnerDetailObj!=null) {
                acc.Signup_Link__c = partnerDetailObj.signUpLink;
            }

            //B-3302 set Pending status only if we create new account
            if (this.createNew){
                acc.RC_Sync_Status__c = 'Pending';
            }
            System.debug('#### PARTNER LEAD OWNER = : 4 ' + partnerOwnerId);

            if(partnerDetailObj != null) {
                if(String.isNotBlank(partnerDetailObj.currentOwner)) {
                    acc.Current_Owner__c =  partnerDetailObj.currentOwner;
                    acc.Current_Owner_Name__c  = partnerDetailObj.currentOwnerName;
                    acc.Current_Owner_Email__c = partnerDetailObj.currentOwnerEmail;
                }
            }

            acc = mapLeadToAccountFields(acc);

            /*****New Employee Override Field Update*****/
            if(leadObj.Website != NULL || leadObj.NumberOfEmployees != NULL || leadObj.Industry != NULL || leadObj.Effective_No_of_Employees_Range__c != NULL
                    || leadObj.Number_of_Locations__c != NULL) {
                acc.Customer_Profile_Last_modified_Date__c = System.now();
            }
            /*******************************************/

            //Relayware
            opp.Partner_Owner__c = leadObj.Partner_Lead_Owner__c;
            opp.Partner_ID__c = leadObj.LeadPartnerID__c;
            opp.Partner_Account__c = leadObj.Partner_Account__c;
            opp.Partner_Contact__c = leadObj.Partner_Contact__c;
            acc.Partner_Contact__c = leadObj.Partner_Contact__c;
            //End

            acc.RecordTypeId = OpportunityHelper.getOppRecordTypeMap('Customer Account');
            acc.Partner_ID__c = leadObj.LeadPartnerID__c;
            acc.Partner_Account__c = leadObj.Partner_Account__c;
            acc.partner_owner__c = con.partner_owner__c = opp.partner_owner__c = leadObj.Partner_Lead_Owner__c;

            update acc;

            if(partnerOwnerId != null) {
                System.Debug('partnerOwnerId >>> "' + partnerOwnerId + '"; acc.Id >>> "' + acc.Id + '"');
                if(userAccountIdIsNotNull(partnerOwnerId)) {
                    ShareUtil.shareAccountToPartner(partnerOwnerId, acc.Id);
                }else{
                    String exceptionMessage = 'Share Account To Partner Error. Reference between Lead.Partner_Lead_Owner__c User and Contact not found. Convert Lead operation is cancelled.';
                    System.debug('empty reference. shareAccountToPartner operation cancelled' + exceptionMessage);
                }
            }

            con.RecordTypeId = OpportunityHelper.getOppRecordTypeMap('VAR Visible');

            update con;

            Id newOppRtId = populateOppRecordType(leadObj.RecordTypeName__c);
            if( newOppRtId != null ) {
                opp.RecordTypeId = newOppRtId;
            }else{
                opp.RecordTypeId = OpportunityHelper.getOppRecordTypeMap('VAR Opportunity');
            }

            setCampaignInfluence(leadObj, opp);

            update opp;

            if(newModel) {
                createdOpportunityId = opp.Id;
            }
            if(!newModel) {
                //B-681
                result.status = 'success';
                if (UserInfo.getName() != 'API User'){
                    TriggerHandler.RESET_VARIABLES();
                    // send user to newly create Opportunity
                    PageReference pageRef = new ApexPages.StandardController(opp).view();
                    pageRef.setRedirect(true);
                    result.VFresult = pageRef;
                } else {

                }
                return result;

            }
        }

        //B-681
        result.status = 'quote';
        if (UserInfo.getName() != 'API User'){
            result.VFresult = ApexPages.currentPage();
        } else {

        }
        return result;
    }

    private Id populateOppRecordType(String leadRecordTypeDevName) {

        System.debug('in populateOppRecordType. leadRecordTypeDevName >> ' + leadRecordTypeDevName);

        Id oppRtId = null;

        if(leadRecordTypeDevName == 'Partner_Leads') {

            oppRtId = OpportunityHelper.getOppRecordTypeMap('VAR Opportunity');

        }else if(leadRecordTypeDevName == 'Sales_Leads') {

            oppRtId = OpportunityHelper.getOppRecordTypeMap('New Sales Opportunity');

        }

        System.debug('oppRtId >> ' + oppRtId);

        return oppRtId;

    }

    private Boolean userAccountIdIsNotNull(String objUserId) {

        User objUserDetail = [Select id,Contact.AccountId,Contact.Account.Partner_id__c from User where Id=:objUserId];
        String strUserAccountId = objUserDetail.Contact.AccountId;

        return !String.isEmpty(strUserAccountId);

    }

    public class CustomException extends Exception {}

    public PageReference createQuote() {

        System.debug('createQuote called');
        String brand = leadObj.Lead_Brand_Name__c;
        String service = leadObj.Lead_Tier_Name__c;
        String term = leadObj.RC_Term__c;
        String edition = leadObj.RC_Edition__c;
        Decimal forecastedUsers = leadObj.Number_of_Users__c;

        if (String.isNotBlank(brand) && brand == OpportunityHelper.BRAND_BT_BUSINESS && createdOpportunityId != null) {
            Opportunity op = [SELECT Id, Name, Account.RC_User_ID__c, Account.Number_of_DL_s__c FROM Opportunity WHERE Id = :createdOpportunityId];

            Pricebook2 applicablePricebook;
            service = OpportunityHelper.TIER_BT_OFFICE;
            for (Pricebook2 pb: [SELECT Id, Name, Plan__c, Service__c FROM Pricebook2 WHERE Brand__r.Name = :brand AND Service__c = :service AND IsActive = TRUE LIMIT 1]) {
                applicablePricebook = pb;
            }
            System.debug('brand:' + brand + '   :service:' + applicablePricebook.Service__c + '  :plan:' + applicablePricebook.Plan__c + '  ');

            if (applicablePricebook != null) {
                if(op.Account.RC_User_ID__c != null) {
                    if (UserInfo.getName() != 'API User') {
                        PageReference pageRef = new ApexPages.StandardController(op).view();
                        pageRef.setRedirect(true);
                        TriggerHandler.RESET_VARIABLES();
                        return pageRef;
                    } else {
                        return null;
                    }
                }
            }

            createdQuote = new Quote();
            createdQuote.OpportunityId = op.Id;
            createdQuote.Name = op.Name;
            createdQuote.QuoteType__c = 'Quote';
            createdQuote.Pricebook2Id = applicablePricebook.Id;
            createdQuote.Upsell_Status__c = 'New';
            createdQuote.ExpirationDate = Date.today();
            createdQuote.RecordTypeId = QuoteHelper.RT_ID_PROSERV;

            System.debug(createdQuote);

            insert createdQuote;

            createdOpportunityId = op.Id;
        }  else if(!String.isBlank(brand) && !String.isBlank(service) && !String.isBlank(term) && !String.isBlank(edition) && forecastedUsers > 0 && createdOpportunityId != null){
            Set<String> plans = new Set<String>();
            if(term == 'Monthly - Contract' || term == 'Monthly-Contract'){
                plans.add('Monthly - Contract');
                plans.add('Monthly-Contract');
            }else{
                plans.add(term);
            }

            Opportunity op = [SELECT Id, Name, Account.RC_User_ID__c, Account.Number_of_DL_s__c FROM Opportunity WHERE Id = :createdOpportunityId];

            Pricebook2 applicablePriceBook;

            System.debug('brand: ' + brand + '  :service:  ' + service + '  :plans:  ' + plans + '  :edition:  ' + edition + '  :forecastedUsers:  ' + forecastedUsers);
            for(Pricebook2 pb:[SELECT Id, Name
            FROM Pricebook2
            WHERE Brand__r.Name = :brand
            AND Service__c = :service
            AND Edition__c = :edition
            AND Plan__c IN :plans
            AND IsActive = TRUE
            AND Line_Range_Min__c <= :forecastedUsers AND Line_Range_Max__c >= :forecastedUsers
            LIMIT 1]){
                applicablePriceBook = pb;
            }

            if(applicablePriceBook != null){
                // if Upsell quote and account num of DL`s is greater that forcastedUsers skip quote creation
                if(op.Account.RC_User_ID__c != null){
                    if (UserInfo.getName() != 'API User'){
                        PageReference pageRef = new ApexPages.StandardController(op).view();
                        pageRef.setRedirect(true);
                        TriggerHandler.RESET_VARIABLES();
                        return pageRef;
                    } else {
                        return null;
                    }
                }

                createdQuote = new Quote();
                createdQuote.OpportunityId = op.Id;
                createdQuote.Name = op.Name;
                createdQuote.QuoteType__c = 'Quote';
                createdQuote.Total_Number_of_Digital_Lines__c = op.Account.RC_User_ID__c == null ? forecastedUsers : forecastedUsers - (op.Account.Number_of_DL_s__c != null ? op.Account.Number_of_DL_s__c : 0);
                createdQuote.Pricebook2Id = applicablePriceBook.Id;
                createdQuote.Upsell_Status__c = op.Account.RC_User_ID__c == null ? 'New' : 'Upsell';
                createdQuote.ExpirationDate = Date.today();

                insert createdQuote;

                createdOpportunityId = op.Id;
            }
        }
        return null;
    }

    private static final String DISCOUNTED_PHONES = 'Discounted Phones';

    public PageReference createAdditionalQuoteLineItems(){

        if(createdQuote != null){
            Id priceBookId;

            List<QuoteLineItem> itemsToInsert = new List<QuoteLineItem>();
            for(PriceBookEntry pBookEntry:[SELECT Id, Name, CurrencyIsoCode, Pricebook2Id, Product2Id, UnitPrice, Per_Line__c, Min_Quantity__c, Product2.Description, Pricebook2.Line_Range_Min__c
            FROM PriceBookEntry
            WHERE Pricebook2Id = :createdQuote.Pricebook2Id
            AND Product2.Feature__c = 11
            AND Product2.Sub_Feature__c = -1
            AND Product2.Family = :DISCOUNTED_PHONES]){
                QuoteLineItem newQ = new QuoteLineItem();
                newQ.ServiceDate = date.today();
                newQ.Description = pBookEntry.Product2.Description;
                newQ.UnitPrice = pBookEntry.UnitPrice;
                newQ.Quantity = createdQuote.Total_Number_of_Digital_Lines__c;
                newQ.QuoteId = createdQuote.Id;
                newQ.PriceBookEntryId = pBookEntry.Id;
                newQ.Product2Id = pBookEntry.Product2Id;
                itemsToInsert.add(newQ);
            }

            if(itemsToInsert.size() > 0){
                insert itemsToInsert;
            }
        }

        if(createdOpportunityId != null){
            if (UserInfo.getName() != 'API User'){
                Opportunity o = new Opportunity(
                        Id = createdOpportunityId
                );

                PageReference pageRef = new ApexPages.StandardController(o).view();
                pageRef.setRedirect(true);
                TriggerHandler.RESET_VARIABLES();
                return pageRef;
            }
        }

        return null;
    }

    private Group getPartnerQueue() {
        return [SELECT id,Name, (SELECT Id, UserOrGroupId FROM GroupMembers LIMIT 1) FROM Group WHERE Type='Queue'
        AND Name='Partner Lead Reviewer' LIMIT 1];
    }

    public List<Note> prepareNoteList(List<Note> noteList,Id parentId) {
        List<Note> rtnNoteList = new List<Note>();
        for(Note noteToInsert : noteList) {
            Note objNote=new Note();
            objNote.Title = noteToInsert.Title;
            objNote.Body = noteToInsert.Body;
            objNote.ParentId = parentId;
            objNote.IsPrivate = noteToInsert.IsPrivate;
            System.debug('Anuj, \n' + 'new note parent opp id= '+ objNote.ParentId);
            rtnNoteList.add(objNote);
        }
        return rtnNoteList;
    }

    public List<Note> prepareNoteList(string notebody,Id parentId) {
        List<Note> rtnNoteList = new List<Note>();

        Note noteObj = new Note(Body= notebody, ParentId = parentId, Title= 'Original note from lead');
        rtnNoteList.add(noteObj);

        return rtnNoteList;
    }

    public Opportunity prepareOpportunity(Opportunity oppObj,string businessType) {
        Opportunity opp = new Opportunity(Id =oppObj.Id);
        try {
            opp.closedate = (leadObj.Estimated_Close_Date__c == null) ? Date.today() : leadObj.Estimated_Close_Date__c;
            opp.Type = businessType;
            opp.Partner_ID__c = leadObj.LeadPartnerID__c;
            system.debug('description: ' + leadObj.Description);
            system.debug('notes: ' + leadObj.Notes__c);
            if(leadObj.Referrer_FName__c!=null || leadObj.Referrer_LName__c !=null || leadObj.Referrer_Email__c!=null){
                opp.Description =' Referrer FName: ' + (leadObj.Referrer_FName__c == null ? '' : leadObj.Referrer_FName__c)
                        + '\n Referrer LName: ' + (leadObj.Referrer_LName__c == null ? '' : leadObj.Referrer_LName__c)
                        + '\n Referrer Email: ' + (leadObj.Referrer_Email__c == null ? '' : leadObj.Referrer_Email__c)
                        + '\n\n' + (leadObj.Description == null ? '' : leadObj.Description);
            } else {
                opp.Description = leadObj.Description;
            }
            opp.StageName = OpportunityHelper.defaultOpportunityStage;
            opp.Timezone__c = strLeadTimeZone;  //Populate oppirtunity timezone from Lead
            opp.Installation_Service_Provider__c = leadObj.Installation_Service_Provider__c;  //Added for LTR-673 PS Deal Reg
            if(leadObj.Agent_Email_Address__c != null){
                opp.Agent_Email_Address__c = leadObj.Agent_Email_Address__c; //Added for passing Support Agent e-mail to Opp
            }
            if(leadObj.Notes__c != '' && leadObj.Notes__c != null) {
                noteList.addALL(prepareNoteList(leadObj.Notes__c,opp.Id));
            }
            if(leadNotes != null && leadNotes.size() >0) {
                noteList.addALL(prepareNoteList(leadNotes,opp.Id));
            }
            opp.Lead_Entry_Source__c = leadObj.Lead_Entry_Source__c;
            setOpportunityCurrency(opp,leadObj);
        } catch(Exception ex) {}
        System.debug(JSON.serializePretty(opp));
        return  opp;
    }

    List<Note> leadNotes = new List<Note>();
    String strLeadTimeZone;
    public LeadStatus convertStatus = new LeadStatus();
    public void loadLeadBasicInfo() {
        if(leadObj != null) {
            leadNotes = [Select  n.Id, n.Title, n.IsPrivate, n.Body From Note n where n.ParentId =:leadObj.Id ];
            strLeadTimeZone = leadObj.Timezone__c; // added 03.10.2016 by Moskvin A.A. (reason: optimization of the number of requests)
            System.debug('timezone from currentLead >> ' + leadObj.Timezone__c);
            convertStatus = [Select Id, MasterLabel from LeadStatus where IsConverted= true limit 1];
        }
    }

    public void updateExOpportunityContactRole(Database.LeadConvertResult leadConvertResult) {
        try {
            if(leadConvertResult.getOpportunityId()!=null && leadConvertResult.getContactId()!=null){
                OpportunityContactRole oppContactRoleObj = [select id,IsPrimary from OpportunityContactRole where
                opportunityId = :leadConvertResult.getOpportunityId() and
                contactId = :leadConvertResult.getContactId()
                order by isPrimary DESC limit 1];
                if(oppContactRoleObj != null && oppContactRoleObj.id != null) {
                    if(!oppContactRoleObj.IsPrimary){
                        oppContactRoleObj.isPrimary = true;
                        update oppContactRoleObj;
                    }
                }else{
                    OpportunityContactRole oppConRoleObj = new OpportunityContactRole(ContactId=leadConvertResult.getContactId(),
                            OpportunityId=leadConvertResult.getOpportunityId(),
                            isPrimary=true);
                    insert oppConRoleObj;
                }
            }
        } catch(Exception ex) {}
    }

    public void mapOpportunityContactRole(Database.LeadConvertResult leadConvertResult, Lead_Qualification__c leadQualObj) {
        try {
            if(leadQualObj != null && leadQualObj.Id != null) {
                if(leadQualObj.Decision_Maker_Partner__c == 'Details Below') {
                    Contact contactObj = new Contact();
                    contactObj.AccountId = leadConvertResult.getAccountId();
                    contactObj.FirstName = leadQualObj.Decision_Maker_First_Name__c;
                    contactObj.LastName = leadQualObj.Decision_Maker_Last_Name__c;
                    contactObj.Email = leadQualObj.Decision_Maker_Email__c;
                    contactObj.Phone = leadQualObj.Decision_Maker_Phone__c;
                    contactObj.Title = leadQualObj.Decision_Maker_Business_Title__c;
                    contactObj.RecordTypeId = OpportunityHelper.getOppRecordTypeMap('VAR Visible');
                    insert contactObj;
                    if(contactObj != null && contactObj.id != null) {
                        OpportunityContactRole oppContactRoleObj = new OpportunityContactRole();
                        oppContactRoleObj.OpportunityId = leadConvertResult.getOpportunityId();
                        oppContactRoleObj.ContactId = contactObj.id;
                        oppContactRoleObj.Role = 'Decision Maker';
                        insert oppContactRoleObj;
                    }
                } else if(leadQualObj.Decision_Maker_Partner__c == 'Same as Contact') {
                    OpportunityContactRole oppContactRoleObj = [select id from OpportunityContactRole where
                    opportunityId = :leadConvertResult.getOpportunityId() and
                    contactId = :leadConvertResult.getContactId() limit 1];
                    if(oppContactRoleObj != null && oppContactRoleObj.id != null) {
                        oppContactRoleObj.Role = 'Decision Maker';
                        oppContactRoleObj.isPrimary = true;
                        update oppContactRoleObj;
                    }
                }
            }
        } catch(exception ex) {}
    }

    public Account mapLeadToAccountFields(Account accountObj) {
        try {
            if(!String.isBlank(leadObj.Website)){
                accountObj.Website = leadObj.Website;
            }
            if(leadObj.NumberOfEmployees != null){
                accountObj.NumberOfEmployees = leadObj.NumberOfEmployees;
            }
            if(!String.isBlank(leadObj.Industry)){
                accountObj.Industry = leadObj.Industry;
            }
            /*****New Employee Override Field Update*****/
            if(!String.isBlank(leadObj.Effective_No_of_Employees_Range__c)) {
                accountObj.No_of_Employees__c = leadObj.Effective_No_of_Employees_Range__c;
            }
            /*******************************************/
            if(!String.isBlank(leadObj.Number_of_Locations__c)) {
                accountObj.Number_Of_Locations__c = leadObj.Number_of_Locations__c;
            }
        } catch(Exception ex) {}
        return accountObj;
    }

    public Lead getl() {
        return leadObj;
    }

    public void setL(Lead value) {
        this.leadObj = value;
    }

    public Boolean getCreateNew(){
        return createNew;
    }

    public void setCreateNew(Boolean value){
        this.createNew = value;
    }


    public Boolean getMultipleSelected(){
        return multiple;
    }

    public Boolean getMatchFound(){
        return matchFound;
    }

    public Boolean getMatchNotFound(){
        return matchNotFound;
    }

    public Boolean getnotAnswered(){
        return notAnswered;
    }

    //Team India - Sep 02
    public Boolean getInitial_CategoryFlag(){
        return Initial_CategoryFlag;
    }

    public String getstrDebug (){
        return strDebug ;
    }
    //


    /* This is the wrapper/container class*/
    public class cAccount {
        public Account acc {get; set;}
        public String userID {get; set;}
        public String primaryNumber {get; set;}
        public String acctStatus {get; set;}
        public Boolean selected {get; set;}
        public Id contactId {get; set;} // added 03.10.2016 Moskvin A.A. (reason: optimization of the number of requests)

        /* Constructor */
        public cAccount(Account a, String uID, String priNum, String accStat, Id cntctId){
            acc = a;
            userId = uID;
            primaryNumber = priNum;
            acctStatus = accStat;
            contactId = cntctId;
            selected = false;
        }
    }

    // code added by India team

    public class cOpportunity {
        public Opportunity opportunity {get; set;}
        public String oppName{get; set;}
        public String  owner{get; set;}
        public String  accountName {get; set;}
        public String  status{get; set;}
        public Datetime lastTouchedDate{get; set;}
        public Datetime createdDate{get; set;}

        /* Constructor */
        public cOpportunity(Opportunity o, String oppNm, String own, String accNm, String stat, Datetime createdDt, Datetime lastTouchedDt) {
            opportunity  = o;
            oppName = oppNm;
            owner = own;
            accountName  = accNm;
            status = stat;
            lastTouchedDate = lastTouchedDt;
            createdDate = createdDt;
        }
    }
    // code ended by India team



    // code added by India team
    public List<cOpportunity> getOpportunities(){
        return OpportunityList;
    }
    // code ended by India team

    public List<cAccount> getAccounts(){
        return accountList;
    }

    public List<WrapperLeadQualification> wrLeadQualList {get;set;}
    public Lead_Qualification__c leadQualificationObj {get;set;}
    map<Id,Lead_Qualification__c> mapLeadQual = new map<Id,Lead_Qualification__c>();
    public string selectedLeadQual {get;set;}
    public boolean toShowViewMode {get;set;}
    string strId;
    public void loadLeadQualBasicDet() {
        try {
            List<Lead_Qualification__c> leadQualList = new List<Lead_Qualification__c>();
            leadQualList = getLeadQualList();
            if(leadQualList != null && leadQualList.size() >0) {
                toShowViewMode = true;
                boolean isALreadySelectedMark = false;
                mapLeadQual = new map<Id,Lead_Qualification__c>();


                for(Lead_Qualification__c leadQualObj : leadQualList) {
                    WrapperLeadQualification wrLeadQualObj = new WrapperLeadQualification();
                    if(!isALreadySelectedMark) {
                        wrLeadQualObj.isSelected = true;
                    }
                    wrLeadQualObj.leadQualObj = leadQualObj;
                    DateTime dtMod = leadQualObj.LastModifiedDate;
                    wrLeadQualObj.strformatDT = dtMod.format('dd/MM/yyyy h:mm:ss a');
                    wrLeadQualList.add(wrLeadQualObj);
                    mapLeadQual.put(leadQualObj.Id,leadQualObj);
                    isALreadySelectedMark = true;
                }


                for(WrapperLeadQualification wrLeadQualObj :wrLeadQualList) {
                    if(wrLeadQualObj.isSelected) {
                        leadQualificationObj = wrLeadQualObj.leadQualObj;
                        selectedLeadQual = wrLeadQualObj.leadQualObj.id;
                    }
                }
            } else {
            }
        } catch(Exception ex) {}
    }

    public List<Lead_Qualification__c> getLeadQualList() {
        wrLeadQualList = new List<WrapperLeadQualification>();
        leadQualificationObj = new Lead_Qualification__c();
        List<Lead_Qualification__c> leadQualList = new List<Lead_Qualification__c>();
        try {
            if(strId.startsWith('00Q')) {
                leadQualList = [Select Pain__c, Name ,Pain_Impact__c, Opportunity__c, Next_Steps_questions__c, Lead__c, LastModifiedDate,
                        InContract__c, Ideal_Solution__c, Id, Gain__c, Gain_Impact__c, CreatedDate, CompanyInfo__c, Benefits__c,
                        Account__c, Account__r.Name,Owner.Name,Lead__r.Name,Opportunity__r.Name, Decision_Maker_Partner__c,
                        Decision_Maker_Phone__c, Decision_Maker_Last_Name__c, Decision_Maker_First_Name__c,
                        Decision_Maker_Email__c, Decision_Maker_Business_Title__c, Decision_Maker_Alternate_Phone__c
                From Lead_Qualification__c where IsDeleted  = false and  Lead__c =:strId
                order by lastModifiedDate desc];

            }
        } catch(Exception ex) {}
        return leadQualList;
    }

    public PageReference loadLeadQualDet() {
        selectedLeadQual =  Apexpages.currentPage().getParameters().get('param1');
        if(selectedLeadQual != null && mapLeadQual != null && mapLeadQual.get(selectedLeadQual) != null) {
            leadQualificationObj = mapLeadQual.get(selectedLeadQual);
        }
        toShowViewMode = true;
        return null;
    }

    public class WrapperLeadQualification {
        public boolean isSelected {get;set;}
        public Lead_Qualification__c leadQualObj {get;set;}
        public string strformatDT {get;set;}
        public WrapperLeadQualification() {
            isSelected = false;
            leadQualObj = new Lead_Qualification__c();
            strformatDT = null;
        }
    }
    /******************************* Mandatory Fields PopUp for 12M Calculation. Added 24th April,14 By Simplion Technologies - Start**********************************/

    /********************************************************************************************************************************************
    * @Description : This method saves the Lead mandatory fields which were filled just before lead conversion. Fields are Forecasted Users,RC -*
    *                Tier, RC Brand.                                                                                                            *
    * @Params      : void                                                                                                                       *
    * @Return      : pageReference                                                                                                              *
    ********************************************************************************************************************************************/
    public pageReference saveLeadBeforeConversion(){
        try{
            if (leadObj != null) {
                leadObj.Lead_Brand_Name__c = this.brand;
                leadObj.RC_Edition__c = this.edition;
                leadObj.Lead_Tier_Name__c = this.product;
                leadObj.RC_Term__c = this.term;
                leadObj.Is_Billing__c = this.isBillingOpty;
                update leadObj;
                showMandatoryFieldPanel = false;
            }
            PageReference pgRef = new pageReference('/apex/convertLeadVFPage?id='+leadObj.Id + (newModel ? '&newmodel=1' : ''));
            pgRef.setRedirect(true);
            return pgRef;
        }catch(Exception e ){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
        }
    }
    /********************************************************************************************************************************************
    * @Description : This method validates Lead before conversion. Its checks if Forecasted Users,RC Tier, RC Brand field are not empty. If they*
    *                are empty then the method makes showMandatoryFieldPanel boolean to true and popup is shown to user to fill those nullfields*
    * @Params      : void                                                                                                                       *
    * @Return      : pageReference                                                                                                              *
    ********************************************************************************************************************************************/
    public pageReference validateLeadBeforeConversion() {

        showMandatoryFieldPanel = (showMandatoryFieldPanel==false || showMandatoryFieldPanel==null ? false : true); // ConvertLead Mandatory field popup Project. Added on 4th April,14
        if (leadObj != null) {
            String foreCastedUsers = String.valueOf(leadObj.Number_of_Users__c);
            String rcBrand = String.valueOf(leadObj.Lead_Brand_Name__c);
            String rcTier = String.valueOf(leadObj.Lead_Tier_Name__c);
            String edition = leadObj.RC_Edition__c;
            String term = leadObj.RC_Term__c;
            if(leadObj.Lead_Brand_Name__c == NULL || leadObj.Lead_Brand_Name__c==''){
                leadObj.Lead_Brand_Name__c = 'RingCentral';
                leadObj.Lead_Tier_Name__c = 'Office';
                leadObj.RC_Edition__c = 'Standard';
                leadObj.RC_Term__c = 'Monthly';
            }
            if (String.isNotBlank(rcBrand) && rcBrand == 'BT Business') {
                //Not opening pop-up if Brand is BT Business
                showMandatoryFieldPanel = false;
            } else if(String.isBlank(foreCastedUsers) || String.isBlank(rcBrand) || String.isBlank(rcTier) || String.isBlank(edition) || String.isBlank(term) ){
                showMandatoryFieldPanel = true;
                impErrorMsg = 'Required field(s) missing.';
            }
        }
        return null;
    }

    /***********************************************FOR RELAYWARE*******************************************************************/
    public class partnerDetailWrapper{

        public string signUpLink;
        public string currentOwner;
        public string currentOwnerName;
        public string currentOwnerEmail;

        public partnerDetailWrapper(string signUpLink,string currentOwner,string currentOwnerName,string currentOwnerEmail){
            this.signUpLink=signUpLink;
            this.currentOwner=currentOwner;
            this.currentOwnerName=currentOwnerName;
            this.currentOwnerEmail=currentOwnerEmail;
        }
    }

    public partnerDetailWrapper fetchPartnerContact(){
        List<Contact> contactList = [SELECT id,Account.Signup_Link__c,Account.Current_Owner__c,Account.Current_Owner_Name__c,Account.Current_Owner_Email__c
        FROM Contact WHERE Id = :leadObj.Partner_Contact__c];
        if(contactList!=null && contactList.size() > 0){
            Contact conObj = contactList[0];
            partnerDetailObj = new partnerDetailWrapper(conObj.Account.Signup_Link__c,conObj.Account.Current_Owner__c,conObj.Account.Current_Owner_Name__c,
                    conObj.Account.Current_Owner_Email__c);
            return partnerDetailObj;
        }else{
            return null;
        }
    }

    public partnerDetailWrapper fetchPartnerOwner() {
        List<User> userList = [SELECT id,Contact.Account.Signup_Link__c, Contact.Account.Inside_Sales_Rep__c,
                Contact.Account.Current_Owner__c, Contact.Account.Current_Owner_Name__c, Contact.Account.Current_Owner_Email__c
        FROM User WHERE Id = :leadObj.Partner_Lead_Owner__c];
        if(userList!=null && userList.size() > 0){
            User userObj = userList[0];
            partnerDetailObj = new partnerDetailWrapper(userObj.Contact.Account.Signup_Link__c,userObj.Contact.Account.Current_Owner__c,
                    userObj.Contact.Account.Current_Owner_Name__c,userObj.Contact.Account.Current_Owner_Email__c);
            return partnerDetailObj;
        }else{
            return null;
        }
    }

    //B-681 Inner class for Partner Lead Convert relult
    public class PartnerLeadConvertResult{
        public String status {get;set;}
        public PageReference VFresult {get;set;}
        public List<String> rwErrors {get;set;}
    }

    public class ConvertLeadParameters {
        public String leadId {get;set;}
        public Boolean newmodel {get;set;}
    }

    //B-2775 Non-attributable campaign logic
    public void setCampaignInfluence(Lead leadObj, Opportunity opp) {
        Feature_Toggle__c featureCS = Feature_Toggle__c.getInstance();
        if(featureCS==null || !featureCS.New_Campaign_Influence__c){
            return;
        }

        List<Campaign> attCampaigns = [SELECT Id, BMID__c, Non_Attributable__c,
                                            (SELECT Id, CampaignId, CreatedDate
                                            FROM CampaignMembers
                                            WHERE LeadID = :leadObj.Id)
                                      FROM Campaign
                                      WHERE Non_Attributable__c = false
                                      AND Id IN (SELECT CampaignId FROM CampaignMember WHERE LeadID = :leadObj.Id)];
        CampaignMember latestCampMember = new CampaignMember();
        String BMIDtoUpdate = '';
        List<Campaign> attCampaignsWithBMID = new List<Campaign>();

        if(attCampaigns.size() > 0) {
            for(Campaign c : attCampaigns) {
                if(String.isNotBlank(c.BMID__c)) {
                    attCampaignsWithBMID.add(c);
                }
            }
            Datetime latest = DateTime.newInstance(0);
            if (attCampaignsWithBMID.size() > 0) {
                for(Campaign c : attCampaignsWithBMID) {
                    for(CampaignMember m : c.CampaignMembers) {
                        if(m.CreatedDate > latest) {
                            latestCampMember = m;
                            BMIDtoUpdate = c.BMID__c;
                            latest = m.CreatedDate;
                        }
                    }
                }
            } else {
                for(Campaign c : attCampaigns) {
                    for(CampaignMember m : c.CampaignMembers) {
                        if(m.CreatedDate > latest) {
                            latestCampMember = m;
                            BMIDtoUpdate = c.BMID__c;
                            latest = m.CreatedDate;
                        }
                    }
                }
            }
            opp.CampaignId = latestCampMember.CampaignId;
            opp.BMID__c = BMIDtoUpdate;
        }
    }

    //B-3576
    public PageReference setParams() {
        return null;
    }

    public List <SelectOption> getBrandNames() {
        Map <String, String> brandValuesParsed = new Map <String, String>();
        List <SelectOption> brandOptions  = new List<SelectOption>();
        brandValuesParsed = parseItems(brandValues);

        for (String option : brandValuesParsed.keyset()) {
            brandOptions.add(new SelectOption(option,option));
        }
        return brandOptions;
    }



    public List <SelectOption> getProductNames() {
        //Clear priceBook list to populate it with new values later
        brandPriceBooks.clear();
        List <SelectOption> productOptions  = new List<SelectOption>();
        productOptions.add(new SelectOption ('--None--','--None--'));
        //RC roduct field is Enabled
        isProductDisabled = false;

        Id currentBrandId;
        try {
            currentBrandId = [SELECT Id, Name FROM schedulerConfiguration__c WHERE Name =:brand LIMIT 1].Id;
        } catch( QueryException e ) {
            System.debug( e.getMessage() );
        }

        //Get allowed picklist values according to record type
        Map <String, String> productValuesParsed = parseItems(productValues);

        List <String> productsToShow = new List <String>();
        if (currentBrandId != null) {
            //Get all available services for current brand
            Set <String> products = new Set <String>();
            for (PriceBook2 pb : [SELECT Id, Brand__c, Service__c, Edition__c, IsActive, IsStandard
            FROM PriceBook2
            WHERE Brand__c =: currentBrandId]) {
                products.add(pb.Service__c);
                brandPriceBooks.add(pb);
            }
            //Check if all priceBook service__c values for current brand are available according to the current Lead record type
            for (String product : products) {
                if (productValuesParsed.get(product) != null){
                    productsToShow.add(product);
                }
            }
        }

        //Make exceptions for 'RingCentral UK', 'AT&T Office@Hand'
        if ((new Set <String> {'RingCentral UK', 'AT&T Office@Hand'}).contains(brand)) {
            if (productValuesParsed.get('Office') != null) {
                productOptions.add(new SelectOption ('Office','Office'));
            }
        } else {
            for (String productName : productsToShow) {
                productOptions.add(new SelectOption(productName,productName));
            }
        }
        if (brand == 'BT Business') {
            isProductDisabled = true;
        }
        if (brand == 'RingCentral' || brand == 'RingCentral Canada') {
            productOptions.add(new SelectOption ('RC Meetings','RC Meetings'));
        }
        return productOptions;
    }


    public List <SelectOption> getEditionNames() {
        List <SelectOption> editionOptions  = new List<SelectOption>();
        editionOptions.add(new SelectOption ('--None--','--None--'));

        isBillingOpty = false;
        isEditionDisabled = false;

        //Get allowed picklist values according to record type
        Map <String, String> editionValuesParsed = parseItems(editionValues);

        Set <String> editions = new Set <String>();

        //Get all available editions for current service
        for (PriceBook2 p : brandPriceBooks) {
            if (p.Service__c == product && p.IsActive == true && p.IsStandard == false){
                editions.add(p.Edition__c);
            }
        }

        //Check if all priceBook editions values for current service__c are available according to the current Lead record type
        List <String> editionsToShow = new List <String>();
        for (String edition : editions) {
            if (editionValuesParsed.get(edition) != null){
                editionsToShow.add(edition);
            }
        }
        for (String option : editionsToShow) {
            editionOptions.add(new SelectOption(option, option));
        }

        if (brand == 'BT Business') {
            isEditionDisabled = true;
        }

        //Set default value for edition
        if (product == 'Office'){
            edition = 'Standard';
        }
        //Make exception for AT&T Office@Hand brand
        if ((new Set <String> {'AT&T Office@Hand', 'BT Business'}).contains(brand)) {
            editionOptions.addall(getPermanentOptions(new List <String> {'Standard', 'Premium','Ultimate'}));
        }
        //Make exception for fax service__c
        if (product == 'Fax') {
            editionOptions.add(new SelectOption('Fax', 'Fax'));
        }
        //Make exception for professional service__c
        if (product == 'Professional') {
            editionOptions.add(new SelectOption('Professional', 'Professional'));
        }
        //Make exception for RC Meetings service__c
        if (product == 'RC Meetings') {
            isBillingOpty = true;
            editionOptions.add(new SelectOption('RC Meetings', 'RC Meetings'));
        }
        return editionOptions;
    }


    public List <SelectOption> getTermNames() {
        List <SelectOption> termOptions  = new List<SelectOption>();
        Map <String, String> termValuesParsed = parseItems(termValues);

        isTermDisabled = false;

        termOptions.add(new SelectOption ('--None--','--None--'));

        for (String option : termValuesParsed.keyset()) {
            termOptions.add(new SelectOption(option,option));
        }
        if (product == 'Office') {
            term = termValuesParsed.get('Monthly');
        }

        if (isProductDisabled == true) {
            isTermDisabled = true;
        }
        return termOptions;
    }


    //Get picklist values allowed by lead record type
    public Map <String, String> parseItems(String values) {
        Map <String, String> parsedValues = new Map <String, String>();
        if (values !=  null) {
            String regexString = Pattern.quote('value":"') + '(.*?)' + Pattern.quote('"}');
            Pattern patternObj = Pattern.compile(regexString);
            Matcher matcherObj = patternObj.matcher(values);
            while (matcherObj.find()) {
                parsedValues.put(matcherObj.group(1), matcherObj.group(1));
            }
        }
        return parsedValues;
    }

    public List <SelectOption> getPermanentOptions(List <String> options) {
        List <SelectOption> permanentOptions  = new List<SelectOption>();
        for (String option : options) {
            permanentOptions.add(new SelectOption (option,option));
        }
        return permanentOptions;
    }

    public Opportunity setOpportunityCurrency(Opportunity oppptyToProcess,Lead sourceLead) {
        if(sourceLead.Lead_Brand_Name__c == OpportunityHelper.BRAND_BT_BUSINESS) {
            oppptyToProcess.CurrencyIsoCode = 'GBP';
        }

        return oppptyToProcess;
    }
}