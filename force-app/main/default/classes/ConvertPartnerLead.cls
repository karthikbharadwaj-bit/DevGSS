/*************************************************
ConvertPartnerLead class
This Class is used by convertLeadVFPage.page which over-rides Convert button for Lead object in SFDC.
Using details of lead this class searches for possible contact matches based on phone and email.
Then it looks at the Accounts associated to those contacts to see if there are any ActivePipe Opportunities.
The page shows agent that there already exists an Account which has the same contact information and if it is protected at all.
Agent can choose to select the matching Account, search for an account they know matchs or create a brand new account.
If merging only a new Opportunity is made which is tied to the existing Account and Contact.
/************************************************/
public class ConvertPartnerLead {
    // Constructor - this only really matters if the autoRun function doesn't work right
    public Lead leadObj{get;set;}
    public Account rcAccountObj{get;set;}
    List<Account> a = new List<Account>();
    List<Contact> c = new List<Contact>();
    public Boolean matchFound = false;
    public Boolean matchNotFound = true;
    public Boolean notAnswered = false;

    public Boolean isPartnerUser{get;set;}
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
    public Boolean createNew{get;set;}

    public partnerDetailWrapper partnerDetailObj;

    public ConvertPartnerLead() {
    }
    public ConvertPartnerLead(ApexPages.StandardController controller) {
        createNew = false;
        isPartnerUser = (UserInfo.getUserType().containsIgnoreCase('Partner') ? true : false);
        rcAccountObj = new Account();
        Boolean isLeadDeleted = false;
        try {
            system.debug('Begining. Tis is lead id: ' + ApexPages.currentPage().getParameters().get('id'));
            if(accountList == null) {
                accountList = new List<cAccount>();
            }
            // code added by India team on 23 July 2010
            if(opportunityList == null) {
                opportunityList = new List<cOpportunity>();
            }
            try {
                leadObj = [SELECT Id,Partner_Lead_Owner__c,Partner_Contact__c,Partner_Account__c,City,Country,PostalCode,State,Street,Company,Description,Email,FirstName,LastName,
                            LeadSource,Name,NumberOfEmployees,OwnerId,Phone,Title,Account_Number__c,Timezone__c, Street_2__c,website,
                            industry,phone_ext__c,isconverted,Notes__c, Account__c,Initial_Category__c,User_ID__c, Agent_Email_Address__c,
                            Referrer_FName__c,Referrer_LName__c,Referrer_Email__c  , NumberOfEmployees__c , Number_of_Locations__c,Partner_ID__c,
                            LeadPartnerID__c,InContract__c , Pain__c, Pain_Impact__c, Gain__c, Gain_Impact__c, Ideal_Solution__c,
                            Benefits__c, Next_Steps_questions__c,Estimated_Close_Date__c,Lead_Brand_Name__c,Inside_Sales_Rep__c,Employees_Override__c,Effective_No_of_Employees_Range__c,
                            Installation_Service_Provider__c FROM Lead WHERE id=:controller.getId()];

            } catch(Exception e) {
                isLeadDeleted = true;
                String msg = e.getMessage();
                msg = 'This lead is already converted.';
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, msg));
            }

            strDebug = leadObj.LeadSource + '----' + leadObj.Initial_Category__c;
            if(leadObj.LeadSource == 'Initial' && leadObj.Initial_Category__c == null) {
                Initial_CategoryFlag = true;
            }
            if(!accountList.isEmpty()) {
                matchFound = true;
                matchNotFound = false;
            } else {
                matchFound = false;
                matchNotFound = true;
            }
            if(!String.isBlank(ApexPages.currentPage().getParameters().get('Id'))) {
                try {
                    strId = ApexPages.currentPage().getParameters().get('Id');
                    rtrl = Apexpages.currentPage().getParameters().get('retURL');
                    loadLeadBasicInfo();
                } catch(Exception ex) {}
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
           for(Integer counter=0;counter<listInitialCategory.size();counter++) {
              options.add(new SelectOption(listInitialCategory.get(counter),listInitialCategory.get(counter)));
           }
       }
       return options;
    }

    public String getInitialCategory() {
        return initialCategory;
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
        Savepoint sp = null;
        PageReference pageRef2 = null;
        try {
            sp = Database.setSavepoint();
            try {
                if((leadObj.Company != null && (leadObj.Company).equalsIgnoreCase('PhoneOnly'))
                    && (leadObj.Name != null && (leadObj.Name).equalsIgnoreCase('Phone Only'))
                    && (leadObj.Email != null && (leadObj.Email).equalsIgnoreCase(Emails__c.getall().get('fake').Email_Address__c)) ) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,
                                        'Please update the contact details on Company Name, Contact Name, or Email to the appropriate information.'));
                    return ApexPages.currentPage();
                }
            } catch(Exception e) {}
            List<Account> selectedAccounts = new List<Account>();
            // Go through the list of Accounts we listed and add the selected ones to a seperate List
            for(cAccount cAcc : getAccounts()) {
                if(cAcc.selected == true) {
                    selectedAccounts.add(cAcc.acc);
                }
            }

            // Make sure there has not been more than 1 selection from all three options, return with error
            if((selectedAccounts.size() > 1) || (selectedAccounts.size() >= 1 && createNew == true) || (selectedAccounts.size() >= 1 &&
                    leadObj.Account__c != null) || (createNew == true && leadObj.Account__c != null)){
                multiple = true;
                notAnswered = false;
                system.debug('multiple accounts were selected');
                return ApexPages.currentPage();
            }
            multiple = false;
            system.debug('multiple accounts were not selected');

            // If there have been no selections made return with error
            if(selectedAccounts.isEmpty() && createNew != true && leadObj.Account__c == null) {
                notAnswered = true;
                 //India Team 02 Sep
                if(leadObj.LeadSource == 'Initial' && leadObj.Initial_Category__c == null) {
                    Initial_CategoryFlag = true;
                    return ApexPages.currentPage();
                }
                //
                return ApexPages.currentPage();
            }

            notAnswered = false;

            //India Team 02 Sep
            if(leadObj.LeadSource == 'Initial' && leadObj.Initial_Category__c == null) {
                Initial_CategoryFlag = true;
                return ApexPages.currentPage();
            }
            //
            if(createNew) {
                leadObj.Account__c = null;
            }

            // If user browsed for an account themseleves
            if(leadObj.Account__c != null) {
                Id leadOwner = leadObj.ownerId;
                Group groupObj = getPartnerQueue();
                if(groupObj != null && leadObj.OwnerId == groupObj.Id) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,
                                            'This lead is not owned by a user, you must specify a user for the Owner field.'));
                    return ApexPages.currentPage();
                }
                //Get list of Notes before Lead is converted, else this list is gone after lead has been converted
                system.debug('Lead notes size= : ' + leadNotes.size() + 'timezone= '+ strLeadTimeZone);
                system.debug('this is leadObj.account: ' + leadObj.Account__c);

                List<String> lst= System.Label.Skip_PartnerId.subString(1).split(';');
                set<String> tempSet = new Set<String>();
                tempSet.addAll(lst);

                if(!tempSet.contains(leadObj.LeadPartnerId__c)){
                      if(string.isNotBlank(leadObj.Partner_Contact__c)){
                          partnerDetailObj = fetchPartnerContact();
                      } else if (string.isNotBlank(leadObj.Partner_Lead_Owner__c)){
                          partnerDetailObj = fetchPartnerOwner();
                      }
                      if(partnerDetailObj==NULL){
                          ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please provide valid Partner Lead Owner before conversion.'));
                          return ApexPages.currentPage();
                      }
                }

                Database.LeadConvert lc = new database.LeadConvert();
                lc.setLeadId(leadObj.id);
                lc.setOwnerId(leadOwner);
                lc.setAccountId(leadObj.account__c);
                lc.setConvertedStatus(convertStatus.MasterLabel);
                Database.LeadConvertResult lcr = Database.convertLead(lc);
                System.assert(lcr.isSuccess());
                try {
                    Contact contObj = new Contact(id = lcr.getContactId());
                    contObj.RecordTypeId = OpportunityHelper.getOppRecordTypeMap('VAR Visible');
                    contObj.partner_owner__c = leadObj.Partner_Lead_Owner__c;
                    update contObj;
                } catch(Exception e) {system.debug('there was no contact on the account');}
                try {
                    Account accObj = new Account(Id = lc.getAccountId());
                    accObj = mapLeadToAccountFields(accObj);
                    accObj.partner_owner__c = leadObj.Partner_Lead_Owner__c;
                    if(accObj.Signup_Link__c == null && partnerDetailObj!=null){
                        accObj.Signup_Link__c = partnerDetailObj.signUpLink;
                    }
                    update accObj;
                    Id partnerOwnerId = (leadObj.Partner_Lead_Owner__c != null ? leadObj.Partner_Lead_Owner__c : null);
                    if(partnerOwnerId != null) {
                        ShareUtil.shareAccountToPartner(partnerOwnerId, accObj.Id);
                    }
                } catch(System.Exception e) {
                     ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error,'6'+e.getMessage()));
                    system.debug('there was an error while passing the Agnet email to Account');
                }
                Opportunity newOpp = new Opportunity (id = lcr.getOpportunityId());
                newOpp = prepareOpportunity(newOpp,'Existing Business');
                newOpp.partner_owner__c = leadObj.Partner_Lead_Owner__c;
                if(noteList != null && noteList.size()>0) {
                    insert noteList;
                }
                setCampaignInfluence(leadObj, newOpp);
                update newOpp;
                // send user to newly create Opportunity
                PageReference pageRef = new ApexPages.StandardController(newOpp).view();
                pageRef.setRedirect(true);
                return pageRef;
            }
            pageRef2 = convert();
        } catch(Exception ex) {
           ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Please check the converting lead again, as it causes the problem in lead conversion.'));
           System.debug('## ERROR OCCURED AT CONVERSION = '+ex.getMessage() + ', = ' + ex.getLineNumber());
           Database.rollback(sp);
           return ApexPages.currentPage();
        }
        return pageRef2;
    }
    private Group getPartnerQueue() {
        return [SELECT id,Name, (SELECT Id, UserOrGroupId FROM GroupMembers LIMIT 1) FROM Group WHERE Type='Queue' AND Name='Partner Lead Reviewer' LIMIT 1];
    }
    /*
    convert() uses the standard convert database method to create a new set of data.
    Some fields on the contact/opportunity and account that are not currently used are cleared out.
    */
    public PageReference convert() {
        datetime myDT = Datetime.now();
        date mydate = date.today();
        Id partnerOwnerId = null;
        if(leadObj.isconverted == false) {
            TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
            TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
            TriggerHandler.BY_PASS_CONTACT_ON_INSERT();
            TriggerHandler.BY_PASS_CONTACT_ON_UPDATE();
            TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT();
            TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE();
            system.debug('THIS IS LEAD ID TO CONVERT: ' + leadObj.Id);
            system.debug('THIS IS LEAD ISCONVERTED: ' + leadObj.isconverted);
            partnerOwnerId = (leadObj.Partner_Lead_Owner__c != null ? leadObj.Partner_Lead_Owner__c : null);
            system.debug('#### PARTNER LEAD OWNER = : ' + partnerOwnerId);
            Id leadOwner = leadObj.ownerId;
            Group groupObj = getPartnerQueue();
            if(groupObj != null && leadObj.OwnerId == groupObj.Id) {
                 ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,
                                            'This lead is not owned by a user, you must specify a user for the Owner field.'));
                    return ApexPages.currentPage();
            }

            List<String> lst= System.Label.Skip_PartnerId.subString(1).split(';');
            set<String> tempSet = new Set<String>();
            tempSet.addAll(lst);

            if(!tempSet.contains(leadObj.LeadPartnerId__c)){
                  if(string.isNotBlank(leadObj.Partner_Contact__c)){
                      partnerDetailObj = fetchPartnerContact();
                  } else if (string.isNotBlank(leadObj.Partner_Lead_Owner__c)){
                      partnerDetailObj = fetchPartnerOwner();
                  }
                  if(partnerDetailObj==NULL){
                      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please provide valid Partner Lead Owner before conversion.'));
                      return ApexPages.currentPage();
                  }
            }

            Database.LeadConvert lc = new database.LeadConvert();
            lc.setLeadId(leadObj.id);
            lc.setOwnerId(leadOwner);
            lc.setConvertedStatus(convertStatus.MasterLabel);
            String address = Emails__c.getall().get('resellers') != null ? Emails__c.getall().get('resellers').Email_Address__c : 'your manager';
            try {
                Database.LeadConvertResult lcr = Database.convertLead(lc);
                System.assert(lcr.isSuccess());
                acc = new Account(Id = lcr.getAccountId());
                con = new contact(Id = lcr.getContactId());
                opp = new  Opportunity(Id = lcr.getOpportunityId());
                system.debug('#### PARTNER LEAD OWNER 1 = : ' + acc.OwnerId);
            } catch(Exception e) {
                system.debug(' partner lead owner,EXCEPTION AT 9 = '+ e.getMessage());
                if(e.getMessage().containsIgnoreCase('This Lead has expired')) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,
                                            'This Lead has expired. It cannot be edited. Please contact <a style="font-size:12px;" href=mailto:' + address + '>' + address + '</a> if you have any questions.'));
                }
                return null;
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
            system.debug('#### PARTNER LEAD OWNER = 2 : ' + acc.OwnerId);
            con.Phone = leadObj.Phone;
            con.Phone_Ext__c = leadObj.Phone_Ext__c;
            con.Title = leadObj.Title;
            con.indexedPhone__c =  leadObj.Phone;
            con.indexedEmail__c = leadObj.email;

            opp.Website__c = leadObj.Website;
            opp.Installation_Service_Provider__c = leadObj.Installation_Service_Provider__c; //Added for LTR-673 PS Deal Reg
            opp = prepareOpportunity(opp,'New Business');
            system.debug('#### PARTNER LEAD OWNER = :3 ' + acc.OwnerId);

            if(noteList != null && noteList.size()>0) {
                insert noteList;
            }

            // Account fields are being set to null because in the beigining we were not using them. This should be reviewed.
            acc.Phone = acc.Industry = acc.Description = acc.BillingStreet = null;
            acc.BillingCity = acc.BillingCountry = acc.BillingPostalCode = acc.BillingState = acc.ShippingCity = null;
            acc.ShippingCountry= acc.ShippingPostalCode = acc.ShippingState = acc.ShippingStreet =acc.Website = null;
            acc.NumberOfEmployees = null;
            if(acc.Signup_Link__c == null && partnerDetailObj!=null){
                acc.Signup_Link__c = partnerDetailObj.signUpLink;
            }
            acc.RC_Sync_Status__c = 'Pending';
            system.debug('#### PARTNER LEAD OWNER = : 4 ' + partnerOwnerId);

            if(partnerDetailObj != null) {
                if(string.isNotBlank(partnerDetailObj.currentOwner)) {
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
            try {
                if(leadObj.Inside_Sales_Rep__c != null) {
                    acc.Inside_Sales_Rep__c = leadObj.Inside_Sales_Rep__c;
                }

                //Relayware
                opp.Partner_Owner__c = leadObj.Partner_Lead_Owner__c;
                opp.Partner_ID__c = leadObj.LeadPartnerID__c;
                opp.Partner_Account__c = leadObj.Partner_Account__c;
                opp.Partner_Contact__c = leadObj.Partner_Contact__c;
                acc.Partner_Contact__c = leadObj.Partner_Contact__c;
                //End


                acc.RecordTypeId = OpportunityHelper.getOppRecordTypeMap('Customer Account');
                acc.Partner_ID__c = leadObj.LeadPartnerID__c;
                acc.partner_owner__c = con.partner_owner__c = opp.partner_owner__c = leadObj.Partner_Lead_Owner__c;
                update acc;
                if(partnerOwnerId != null) {
                    ShareUtil.shareAccountToPartner(partnerOwnerId, acc.Id);
                }
                con.RecordTypeId = OpportunityHelper.getOppRecordTypeMap('VAR Visible');
                update con;
                opp.RecordTypeId = OpportunityHelper.getOppRecordTypeMap('VAR Opportunity');
                setCampaignInfluence(leadObj, opp);
                update opp;
            }  catch(Exception ex) {
                system.debug('#### PARTNER LEAD OWNER 88 = : ' + acc.OwnerId + ' = ' + ex.getMessage());
            }
            TriggerHandler.RESET_VARIABLES();
            // send user to newly create Opportunity
            PageReference pageRef = new ApexPages.StandardController(opp).view();
            pageRef.setRedirect(true);
            return pageRef;
        }
        return ApexPages.currentPage();
    }

    public List<Note> prepareNoteList(List<Note> noteList,Id parentId) {
        List<Note> rtnNoteList = new List<Note>();
        try {
            for(Note noteToInsert : noteList) {
                Note objNote=new Note();
                objNote.Title = noteToInsert.Title;
                objNote.Body = noteToInsert.Body;
                objNote.ParentId = parentId;
                objNote.IsPrivate = noteToInsert.IsPrivate;
                System.debug('Anuj, \n' + 'new note parent opp id= '+ objNote.ParentId);
                rtnNoteList.add(objNote);
            }
        } catch(Exception ex) {}
        return rtnNoteList;
    }

    public List<Note> prepareNoteList(string notebody,Id parentId) {
        List<Note> rtnNoteList = new List<Note>();
        try {
            Note noteObj = new Note(Body= notebody, ParentId = parentId, Title= 'Original note from lead');
            rtnNoteList.add(noteObj);
        } catch(Exception ex) {}
        return rtnNoteList;
    }

    public Opportunity prepareOpportunity(Opportunity oppObj,string businessType) {
        Opportunity opp = new Opportunity(Id =oppObj.Id);
        try {
            opp.closedate = Date.today();
            opp.Type = businessType;
            opp.Partner_ID__c = leadObj.LeadPartnerID__c;
            opp.CloseDate = leadObj.Estimated_Close_Date__c;
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
            opp.StageName = '1. Qualify'; //'3. Qualified';
            opp.Timezone__c = strLeadTimeZone;//Populate oppirtunity timezone from Lead
            opp.Installation_Service_Provider__c = leadObj.Installation_Service_Provider__c; //Added for LTR-673 PS Deal Reg
            if(leadObj.Agent_Email_Address__c != null){
                opp.Agent_Email_Address__c = leadObj.Agent_Email_Address__c; //Added for passing Support Agent e-mail to Opp
            }
            if(leadObj.Notes__c != '' && leadObj.Notes__c != null) {
                noteList.addALL(prepareNoteList(leadObj.Notes__c,opp.Id));
            }
            if(leadNotes != null && leadNotes.size() >0) {
                noteList.addALL(prepareNoteList(leadNotes,opp.Id));
            }
        } catch(Exception ex) {}
        return  opp;
    }

    List<Note> leadNotes = new List<Note>();
    String strLeadTimeZone;
    LeadStatus convertStatus = new LeadStatus();
    public void loadLeadBasicInfo() {
        try {
            if(leadObj != null) {
                leadNotes = [Select  n.Id, n.Title, n.IsPrivate, n.Body From Note n where n.ParentId =:leadObj.Id ];
                strLeadTimeZone = [Select Timezone__c From Lead where Id =:leadObj.Id].Timezone__c;
                convertStatus = [Select Id, MasterLabel from LeadStatus where IsConverted= true limit 1];
            }
        } catch(Exception ex) {}
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


    /* This is the wrapper/container class*/
    public class cAccount {
        public Account acc {get; set;}
        public String userID {get; set;}
        public String primaryNumber {get; set;}
        public String acctStatus {get; set;}
        public Boolean selected {get; set;}
        public Contact associatedContact {get;set;}
        /* Constructor */
        public cAccount(Account a, String uID, String priNum, String accStat, Contact associatedContact){
            acc = a;
            userId = uID;
            primaryNumber = priNum;
            acctStatus = accStat;
            associatedContact = associatedContact;
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

    string strId;
    string rtrl;

    /****************************************************FOR RELAYWARE******************************************************************/
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
            FROM User WHERE Id =: userinfo.getuserId()];
        if(userList!=null && userList.size() > 0){
            User userObj = userList[0];
            partnerDetailObj = new partnerDetailWrapper(userObj.Contact.Account.Signup_Link__c,userObj.Contact.Account.Current_Owner__c,
                                                    userObj.Contact.Account.Current_Owner_Name__c,userObj.Contact.Account.Current_Owner_Email__c);
            return partnerDetailObj;
        }else{
            return null;
        }
    }

    public void setCampaignInfluence(Lead leadObj, Opportunity opp) {
        Feature_Toggle__c featureCS = Feature_Toggle__c.getInstance();
        if(featureCS==null || !featureCS.New_Campaign_Influence__c){
            return;
        }

        List<Campaign> allCampaigns = [SELECT Id, BMID__c, Non_Attributable__c, (SELECT Id, CampaignId, CreatedDate FROM CampaignMembers WHERE LeadID = :leadObj.Id) FROM Campaign];
        List<Campaign> attCampaigns = new List<Campaign>();
        CampaignMember latestCampMember;
        String BMIDtoUpdate = '';

        for(Campaign c : allCampaigns) {
            if(c.Non_Attributable__c == false && c.CampaignMembers.size() > 0) {
                attCampaigns.add(c);
            }
        }

        if(attCampaigns.size() > 0) {
            Datetime latest = DateTime.newInstance(0);

            for(Campaign c : attCampaigns) {
                for(CampaignMember m : c.CampaignMembers) {
                    if(m.CreatedDate > latest) {
                        latestCampMember = m;
                        BMIDtoUpdate = c.BMID__c;
                        latest = m.CreatedDate;
                    }
                }
            }
            opp.CampaignId = latestCampMember.CampaignId;
            opp.BMID__c = BMIDtoUpdate;
        }
    }
}