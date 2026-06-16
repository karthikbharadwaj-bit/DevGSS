public with sharing class SmartSearchForLwc {
    
    static User currentUser; 
    static Lead_Qualification__c leadQualificationObj;

    static List<ListResult> opportunityList = new List<ListResult>();
    static List<ListResult> opportunityNoCOList = new List<ListResult>();
    static List<ListResult> unprotectedOpportunityList = new List<ListResult>();
    static List<ListResult> leadList = new List<ListResult>();
    static List<ListResult> unprotectedLeadList = new List<ListResult>();
    static List<ListResult> protectedLeadList = new List<ListResult>();
    static List<ListResult> matchedContactList = new List<ListResult>();
    static List<Lead> leadListTemp = new List<Lead>();
    static Set<Id> oppListIdSet = new Set<Id>();
    static Set<Id> oppNoCOListIdSet = new Set<Id>();
    static Set<Id> oppUnProtectedListIdSet = new Set<Id>();
    static Set<Id> contactIdSet = new Set<Id>();
    static Set<Id> leadOwnerIdSet = new Set<Id>();
    static Set<Id> oppAndAccountOwnerId = new Set<Id>();
    static Map<Id, List<CampaignMember>> contactCampaignMap = new Map<Id, List<CampaignMember>>();
    static Map<Id, List<CampaignMember>> leadCampaignMemMap = new Map<Id, List<CampaignMember>>();

    public static String USER_LOCALE = UserInfo.getTimeZone().toString();
    public static String US_DATE_FORMAT = 'MM/dd/y';

    
    public static final String RT_NAME_PARTNER_LEAD = 'Partner Leads';
    public static final String RT_NAME_SALES_LEAD = 'Sales Leads';
    public static Schema.DescribeSObjectResult DESCRIBE {
        get {
            if(DESCRIBE == null) {
                DESCRIBE = Lead.SObjectType.getDescribe();
            }
            return DESCRIBE;
        }
        set;
    }
    public static Map<String, Schema.RecordTypeInfo> RT_INFO_BY_NAME {
        get {
            if(RT_INFO_BY_NAME == null) {
                RT_INFO_BY_NAME = DESCRIBE.getRecordTypeInfosByName();
            }
            return RT_INFO_BY_NAME;
        }
        set;
    }
    public static final Id RT_ID_PARTNER_LEAD = RT_INFO_BY_NAME.get(RT_NAME_PARTNER_LEAD).getRecordTypeId();
    public static final Id RT_ID_SALES_LEAD = RT_INFO_BY_NAME.get(RT_NAME_SALES_LEAD).getRecordTypeId();
    public static final String USER_ROLE_NAME_VISTA_PRINT_US = 'Vista Print US';

    static INVOCA_FOR_SF__Invoca_Call_Log__c invocaCallRecord;
    static Account rcAccount;
    @TestVisible
    static Lead newLead;
    static Campaign campObj;

    @AuraEnabled(cacheable=true)
    public static User getUserInfo(String userId){
        User matchedUser;
        List<User> matchedUsers = (List<User>) new UserSelector()
            .selectUserById(new List<Object> {userId})
            .setLimit(1)
            .executeQuery();
        if (!matchedUsers.isEmpty()) {
            matchedUser = matchedUsers[0];
        }
        return matchedUser;
    }

    @AuraEnabled(cacheable=true)
    public static Id getSalesManagerProfileId(){
        Profile matchedProfile;
        String profileName = ProfileHelper.PROFILE_NAME_SALES_MANAGER_WITH_INSIDESALES;
        List<Profile> matchedProfiles = (List<Profile>) new ProfileSelector()
            .selectProfileByName(new List<Object> {profileName})
            .setLimit(1)
            .executeQuery();
        if (!matchedProfiles.isEmpty()) {
            matchedProfile = matchedProfiles[0];
        }
        return matchedProfile?.Id;
    }

    @AuraEnabled(cacheable=true)
    public static Id getSalesAgentProfileId(){
        Profile matchedProfile;
        String profileName = ProfileHelper.PROFILE_NAME_SALES_AGENT_SDR_W_INSIDESALES;
        List<Profile> matchedProfiles = (List<Profile>) new ProfileSelector()
            .selectProfileByName(new List<Object> {profileName})
            .setLimit(1)
            .executeQuery();
        if (!matchedProfiles.isEmpty()) {
            matchedProfile = matchedProfiles[0];
        }
        return matchedProfile?.Id;
    }

    public static Account getRCAccount(String userIdFromLead, String userIdFromURL) {
        if (String.isNotBlank(userIdFromLead)) {
            List<Account> accounts = (List<Account>) new AccountSelector()
                .selectAccountsByUserIds(new Object[]{new String[]{userIdFromLead}})
                .selectFields(new List<Schema.SObjectField>{
                    Account.Name,
                    Account.RC_User_Id__c,
                    Account.CreatedDate,
                    Account.RC_Account_Status__c,
                    /*Ultimate parent id population on lead*/
                    Account.Ultimate_Parent_Account_ID__c
                })
                .selectField('Recordtype.Name')
                .setLimit(1)
                .executeQuery();

            if (!accounts.isEmpty()) {
                rcAccount = accounts[0];
                newLead.ZI_CDP_Account_Id__c = rcAccount.Id;
                /*Ultimate parent id population on lead*/
                newLead.Ultimate_Parent_Account_ID__c = rcAccount.Ultimate_Parent_Account_ID__c;
            } else {
                populateRCAccountFromURL(newLead, userIdFromURL);
            }
        } else {
            populateRCAccountFromURL(newLead, userIdFromURL);
        }
        return rcAccount;
    }

    public static void populateRCAccountFromURL(Lead ld, String userIdFromURL) {
        if (String.isNotBlank(userIdFromURL)) {
            List<Account> accounts = (List<Account>) new AccountSelector()
                .selectAccountsByUserIds(new Object[]{new String[]{userIdFromURL}})
                .selectFields(new List<Schema.SObjectField>{
                    Account.Name,
                    Account.RC_User_Id__c,
                    Account.CreatedDate,
                    Account.RC_Account_Status__c,
                    Account.Ultimate_Parent_Account_ID__c
                })
                .selectField('Recordtype.Name')
                .setLimit(1)
                .executeQuery();

            if (!accounts.isEmpty()) {
                rcAccount = accounts[0];
                ld.ZI_CDP_Account_Id__c = rcAccount.Id;
                ld.Ultimate_Parent_Account_ID__c = rcAccount.Ultimate_Parent_Account_ID__c;
                ld.User_Id__c = accounts[0].RC_User_Id__c;
            } else {
                rcAccount = null;
            }
        }
    }

    @AuraEnabled
    public static Map<String, SObject> getCampaign(String jsonParams){
        try {
            Map<String, Object> deserializedJSON = (Map<String, Object>) JSON.deserializeUntyped(jsonParams); 
            /* URL Parameters*/
            Map<String, Object> deserializedParams = (Map<String, Object>) deserializedJSON.get('params');
            deserializedParams = keysToUpper(deserializedParams);
            String leadSysSourceUrl = deserializedParams.get('SOURCE') != null ? 
                (String) deserializedParams.get('SOURCE') : '';
            String invocaTransactionId = (String) deserializedParams.get('INVOCAID');
            String dnis = (String) deserializedParams.get('DNIS');
            String userId = (String) deserializedParams.get('USERID');
            String inContactId = (String) deserializedParams.get('CID'); 
            String skillName = (String) deserializedParams.get('SKILL');  
            String ani = (String) deserializedParams.get('ANI');
            String strRange = (String) deserializedParams.get('RANGE');
            String url = (String) deserializedJSON.get('url');
            /*populate newLead and rcAccount from JSON 
            populate newLead*/
            Map<String, Object> newLeadMap = deserializedJSON.get('newLead') != null ? 
                (Map<String, Object>) deserializedJSON.get('newLead') : new Map<String, Object>();
            if (newLeadMap.isEmpty()) {
                newLead = new Lead();
            } else {
                String newLeadJSON = (String)JSON.serialize(newLeadMap);
                newLead = (Lead) JSON.deserialize(newLeadJSON, Lead.class);   
            }
            /*populate rcAccount*/
            Map<String, Object> rcAccountMap = deserializedJSON.get('rcAccount') != null ? 
                (Map<String, Object>) deserializedJSON.get('rcAccount') : new Map<String, Object>();
            if (rcAccountMap.isEmpty()) {
                rcAccount = null;
            } else {
                String rcAccountJSON = (String)JSON.serialize(rcAccountMap);
                rcAccount = (Account) JSON.deserialize(rcAccountJSON, Account.class);
            }
            /*set newLead Fields based on parameters*/
            newLead.SmartSearchURL__c = (String.isBlank(url) ? '' : url);
            String phoneNumber = (String.isBlank(ani) ? '' : ani);
            newLead.inContact_Contact_ID__c = (String.isBlank(inContactId) ? '' : inContactId);
            newLead.inContact_Skill__c = (String.isBlank(skillName) ? '' : skillName);
            newLead.Lead_System_Source__c = (String.isBlank(leadSysSourceUrl) ? '' : leadSysSourceUrl.trim());
            newLead.Five9_DNIS__c = (String.isBlank(dnis) ? '' : dnis.trim());
            Set<String> range = LeadTriggerHelperExt.getEmployeeRange();
            Boolean isValidValue = false;
            if (!String.isBlank(strRange)) {
                if (range.contains(strRange.trim())) {
                    isValidValue = true;
                }
            }
            /****************Effectve Number of employee change****************/
            if (isValidValue) {
                newLead.Employees_Override__c = strRange.trim();
            }
            
            if ((!String.isBlank(dnis)) 
            || (!String.isBlank(inContactId)) 
            || (!String.isBlank(skillName))) {
                newLead.LeadSource = 'Inbound Call';
            }
            
            Campaign campObj;
            List<Campaign> campaignList = new List<Campaign>();

            Map<String, sObject> res = new Map<String, sObject>();
            
            if (leadSysSourceUrl.equalsIgnoreCase(LeadHelper.INVOCA)) {
                if (String.isNotBlank(invocaTransactionId)) {
                    InvocaSelector invocaSelectorInstance = new InvocaSelector();
                    List<INVOCA_FOR_SF__Invoca_Call_Log__c> invocaRecordsList = 
                        (List<INVOCA_FOR_SF__Invoca_Call_Log__c>) invocaSelectorInstance
                        .selectInvocaRecordById(invocaTransactionId)
                        .executeQuery();
                    invocaCallRecord  = !invocaRecordsList.isEmpty() ? invocaRecordsList[0] : null;
                    if (invocaCallRecord != null) {
                        newLead = (Lead) assignInvocaValues(newLead, invocaCallRecord, 'assignInvocaValues', rcAccount);
                        rcAccount = getRCAccount(newLead.User_ID__c, userId);
                        if (String.isNotBlank(invocaCallRecord.INVOCA_FOR_SF__Customer_Business_Object_Value_3__c)) {
                            campObj = getCampaignFromInvocaCall(invocaCallRecord);
                            if (String.isNotBlank(campObj.Id)) {
                                newLead.Most_Recent_Campaign__c = campObj.Id;
                            } else {
                                campObj = fetchCampaignByName(LeadHelper.CAMPAIGNBROKENATTRIBUTION);
                                newLead.Most_Recent_Campaign__c = campObj.Id;
                            }
                        } else {
                            campObj = fetchCampaignByName(LeadHelper.CAMPAIGNINVOCAWALKON);
                            newLead.Most_Recent_Campaign__c = campObj.Id;
                        }
                    } else {
                        campObj = fetchCampaignByName(LeadHelper.CAMPAIGNINVOCAMISSINGATTRIBUTION);
                        newLead.Most_Recent_Campaign__c = campObj.Id;
                    }
                } else {
                    campObj = setCampaignByDNISOrderedByCreatedDate(dnis, leadSysSourceUrl);
                    newLead.Most_Recent_Campaign__c = campObj.Id;
                }
            } else if (leadSysSourceUrl.equalsIgnoreCase('drift')) {
                newLead.FirstName = String.isNotBlank((String)deserializedParams.get('FNAME')) ? 
                    (String) deserializedParams.get('FNAME') : newLead.FirstName;
                newLead.LastName = String.isNotBlank((String)deserializedParams.get('LNAME')) ? 
                    (String) deserializedParams.get('LNAME') : newLead.LastName;
                newLead.Email = String.isNotBlank((String)deserializedParams.get('EMAIL')) ? 
                    (String) deserializedParams.get('EMAIL') : newLead.Email;
                newLead.Phone = String.isNotBlank((String)deserializedParams.get('PHONE')) ? 
                    (String) deserializedParams.get('PHONE') : newLead.Phone;
                newLead.BMID__c = String.isNotBlank((String)deserializedParams.get('BMID')) ? 
                    (String) deserializedParams.get('BMID') : newLead.BMID__c;
                newLead.RC_Visitor_ID__c = String.isNotBlank((String)deserializedParams.get('RCVID')) ? 
                    (String) deserializedParams.get('RCVID') : newLead.RC_Visitor_ID__c;
                newLead.Adobe_Target_Id__c = String.isNotBlank((String)deserializedParams.get('ATID')) ? 
                    (String) deserializedParams.get('ATID') : newLead.Adobe_Target_Id__c;
                newLead.Adobe_Target_Id_History__c = String.isNotBlank((String)deserializedParams.get('ATID_HISTORY')) ? 
                    (String) deserializedParams.get('ATID_HISTORY') : newLead.Adobe_Target_Id_History__c;
                newLead.AID__c = String.isNotBlank((String)deserializedParams.get('AID')) ? 
                    (String) deserializedParams.get('AID') : newLead.AID__c;
                newLead.PID__c = String.isNotBlank((String)deserializedParams.get('PID')) ? 
                    (String) deserializedParams.get('PID') : newLead.PID__c;
                newLead.KCID__c = String.isNotBlank((String)deserializedParams.get('KCID')) ?  
                    (String) deserializedParams.get('KCID') : newLead.KCID__c;
                newLead.GCLID__c = String.isNotBlank((String)deserializedParams.get('GCLID')) ? 
                    (String) deserializedParams.get('GCLID') : newLead.GCLID__c;
                newLead.ECID__c = String.isNotBlank((String)deserializedParams.get('ECID')) ? 
                    (String) deserializedParams.get('ECID') : newLead.ECID__c;
                newLead.LeadSource = 'Online Chat';
                newLead.Lead_Entry_Source__c = 'RingBot Office';
                if (String.isNotBlank(newLead.BMID__c)) {
                    List<Campaign> campaigns = (List<Campaign>) new CampaignSelector()
                        .selectCampaignByBMID(new List<Object> {newLead.BMID__c})
                        .setLimit(1)
                        .executeQuery();
                    if (!campaigns.isEmpty()) {
                        campObj = campaigns[0];
                    } else {
                        campObj = fetchCampaignByName(LeadHelper.CAMPAIGNBROKENATTRIBUTION);
                    }
                } else {
                    campObj = fetchCampaignByName(LeadHelper.CAMPAIGNSALESGENERATED);
                }
            } else if (dnis != null) {
                if(!String.isBlank(dnis)) {
                    campaignList = (List<Campaign>) new CampaignSelector()
                        .selectCampaignByDNIS(new List<Object> {dnis})
                        .executeQuery();
                    if (campaignList!=null && campaignList.size() > 0) {
                        campObj = campaignList[0];
                    } else {
                        campObj = fetchCampaignByName(LeadHelper.CAMPAIGNBROKENATTRIBUTION);
                    }
                } else {
                    campObj = fetchCampaignByName('Inbound Call/Chat');
                }
            } else {
                campObj = fetchCampaignByName(LeadHelper.CAMPAIGNSALESGENERATED);
            }
            if (campObj != null) {
                newLead.Primary_Campaign__c = campObj.Id;
                if (!campObj.Non_Attributable__c
                    && (!leadSysSourceUrl.equalsIgnoreCase(LeadHelper.INVOCA)) 
                    && (!leadSysSourceUrl.equalsIgnoreCase('drift'))
                    && (String.isNotBlank(dnis) || (String.isNotBlank(userId) || String.isNotBlank(skillName))) ){
    
                    newLead.AID__c = (String.isNotBlank(campObj.AID__c) ? campObj.AID__c : newLead.AID__c);
                    newLead.BMID__c = (String.isNotBlank(campObj.BMID__c) ? campObj.BMID__c : newLead.BMID__c);
                    newLead.PID__c = (String.isNotBlank(campObj.PID__c) ? campObj.PID__c : newLead.PID__c);
                }
            }

            if (invocaCallRecord != null && String.isNotBlank(invocaCallRecord.INVOCA_FOR_SF__calling_phone_number__c)) {
                phoneNumber = invocaCallRecord.INVOCA_FOR_SF__calling_phone_number__c;
            }

            if ((!leadSysSourceUrl.equalsIgnoreCase('drift')) && (phoneNumber!=null && phoneNumber!='')) {
                newLead.Phone = phoneNumber.trim();
                newLead.FirstName='';
                newLead.LastName='';
                newLead.Company ='';
                newLead.Email='';
            }
            
            res.put('Lead', (sObject) newLead);
            res.put('Campaign', (sObject) campObj);
            res.put('Account', (sObject) rcAccount);
            return res;
        } catch (Exception e) {
            AuraHandledException exc = new AuraHandledException('ERROR ' + e.getMessage());
            exc.setMessage('ERROR ' + e.getMessage());
            throw exc;
        }
    }

    static sObject assignInvocaValues(sObject sObj, INVOCA_FOR_SF__Invoca_Call_Log__c invocaCall, String process, Account rcAcc) {
        if (invocaCall.Id != null) {
            FieldMappingEngine assignInvoca = new FieldMappingEngine(process, invocaCall, sObj);
            assignInvoca.processFieldsMappings();
            String objName = sObj.getSObjectType().getDescribe().getName();
            if (
                'Lead'.Equals(objName) &&
                String.isNotBlank(sObj.Id) &&
                String.isBlank(invocaCall.INVOCA_FOR_SF__Lead__c)
            ) { 
                invocaCall.INVOCA_FOR_SF__Lead__c = sObj.Id;
                Lead sObjLead = (Lead) sObj;
                if (rcAcc != null) {
                    invocaCall.INVOCA_FOR_SF__Account__c = rcAcc.Id;
                } else if (String.isNotBlank(sObjLead.ZI_CDP_Account_Id__c)) {
                    invocaCall.INVOCA_FOR_SF__Account__c = sObjLead.ZI_CDP_Account_Id__c;
                }
                update invocaCall;
            } else if (
                'Contact'.Equals(objName) &&
                String.isNotBlank(sObj.Id) &&
                String.isBlank(invocaCall.INVOCA_FOR_SF__Contact__c)
            ) {
                invocaCall.INVOCA_FOR_SF__Contact__c = sObj.Id;
                if (rcAcc != null) {
                    invocaCall.INVOCA_FOR_SF__Account__c = rcAcc.Id;
                }
                update invocaCall;
            }
        }
        return sObj;
    }

    static Campaign getCampaignFromInvocaCall(INVOCA_FOR_SF__Invoca_Call_Log__c invocaCallFromInvocaID) {
        /* AID, BMID, PID, dnis, Primary Campaign, isPartnerLead, criteriaToCamapaignMap*/
        CampaignWrapper campaignWrapperDT = new CampaignWrapper(null, 
            invocaCallFromInvocaID.INVOCA_FOR_SF__Customer_Business_Object_Value_3__c, null, null, null, false); 
        Campaign campaignObj = CampaignAssignmentHelper.getLeadCampaignLogic(campaignWrapperDT,
            CampaignAssignmentHelper.findCampaingsLogic(new List<CampaignWrapper> {campaignWrapperDT}) );
        return (campaignObj != null ? campaignObj : new Campaign());
    }

    static Campaign fetchCampaignByName(String campName) {
        List<Campaign> campaignList = (List<Campaign>) new CampaignSelector()
            .selectCampaignsByName(new List<Object> {campName})
            .withoutSelectorOrderByIncluded()
            .addOrdering('LastModifiedDate', QueryFactory.SortOrder.DESCENDING)
            .setLimit(1)
            .executeQuery();
        if (campaignList != null && campaignList.size() > 0) {
            return campaignList[0];
        } else {
            return null;
        }
    } 

    static Campaign setCampaignByDNISOrderedByCreatedDate(String dnis, String leadSysSourceUrl) {
        CampaignSelector campaignSelector = new CampaignSelector();
        Campaign campObj = new Campaign();
        List<Campaign> campaignList = new List<Campaign>();
        if (leadSysSourceUrl.equalsIgnoreCase(LeadHelper.INVOCA)) {
            if (!String.isBlank(dnis)) {
                campaignList = campaignSelector.selectCampaignForLeadSearch_ByCreatedDate(new List<Object> {
                    dnis
                })
                    .executeQuery();
                if (campaignList.isEmpty()) {
                    campObj = fetchCampaignByName(LeadHelper.CAMPAIGNINVOCAMISSINGATTRIBUTION);
                } else {
                    campObj = campaignList[0];
                }
            } else {
                campObj = fetchCampaignByName(LeadHelper.CAMPAIGNINVOCAMISSINGATTRIBUTION);
            }
        }
        return campObj;
    }

    @AuraEnabled(cacheable = true)
    public static List<String> getLeadSourceValuesForNewLead() {
        List<String> result = new List<String>();
        Set<String> leadSourceNames = LeadSourceValuesForNewLead__c.getAll().keyset();
        if (!leadSourceNames.isEmpty()) {
            for (String leadSource : leadSourceNames) {
                result.add(leadSource);
            }
        }
        return result;
    }

    static Boolean isValidEmail(String inputString ) {
        if(String.isNotBlank(inputString)) {

            String emailRegex = 
            '([a-zA-Z0-9_\\-\\.]+)@((\\[a-z]{1,3}\\.[a-z]{1,3}\\.[a-z]{1,3}\\.)|(([a-zA-Z0-9\\-]+\\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})';
            Pattern myPattern = Pattern.compile(emailRegex);

            /* Then instantiate a new Matcher object "MyMatcher"*/
            Matcher myMatcher = myPattern.matcher(inputString);

            if (!myMatcher.matches()) {
                return false;
            }
        }
        return true;
    }

    static Boolean isEmpty(String value) {
        return (value == null || value.trim() == '');
    }

    static Boolean isFakeEmail(String email) {
        return (!isEmpty(email) && email.trim() == Emails__c.getall().get('fake')?.Email_Address__c);
    }
    
    public static List<Contact> findContactList(String conditionalStr) {
        String queryStr = 'SELECT Id, Name, AccountId, Email, Phone, Contact.Account.Name, ' +
            '(SELECT CampaignId,Campaign.Protected_Campaign__c, ContactId From CampaignMembers ' + 
            'where Campaign.Protected_Campaign__c = true limit 1) FROM Contact ' +
            (conditionalStr != '' ? ' WHERE ' + conditionalStr : '')+' ORDER BY LastModifiedDate DESC LIMIT 400 ';
        try {
            return Database.query(queryStr);
        } catch (Exception e) {
            AuraHandledException exc = new AuraHandledException('ERROR ' + e.getMessage());
            exc.setMessage('ERROR ' + e.getMessage());
            throw exc;        
        }
    }

    static void loadMatchedContactList(String leadSysSourceUrl, String formattedNumber, String plusOnePhoneFormat) {
        if (leadSysSourceUrl.equalsIgnoreCase('drift')) {
            List<String> distinctPhoneFormats;
            if (String.isBlank(newLead.Phone)) {
                distinctPhoneFormats = new List<String>();
            } else {
                distinctPhoneFormats = String.isBlank(formattedNumber) ? new List<String> {newLead.Phone, plusOnePhoneFormat} 
                    : new List<String> {formattedNumber, newLead.Phone, plusOnePhoneFormat};
            }
            List<String> emailList = String.isBlank(newLead.Email) ? new List<String>() : new List<String> {newLead.Email};
            for (Contact cont : (List<Contact>) new ContactSelector()
                .selectContactsMatchedBySearch(new List<Object> {emailList, distinctPhoneFormats})
                .executeQuery()) {
                matchedContactList.add(new ListResult(cont.Name, cont.Email, cont.Phone, null, cont.Contact_Status__c,
                    cont.CreatedDate, cont.LastModifiedDate, null, cont.Id, null, null, null, null,
                    String.isBlank(cont.AccountId) ? null : cont.Account.Name, null, null, 
                    null, String.isBlank(cont.AccountId) ? null : cont.Account.RecordType.Name, '/' + cont.Id));
            }
        } else if (rcAccount != null && String.isNotBlank(rcAccount.RC_Account_Status__c)
            && (rcAccount.RC_Account_Status__c.EqualsIgnoreCase('Paid') 
            || rcAccount.RC_Account_Status__c.containsIgnoreCase('trial'))) {
            for (Contact cont : (List<Contact>) new ContactSelector()
                .selectContactsByAccountIdAndEmailOrPhone(new object[]{rcAccount.Id, newLead.Email, newLead.Phone})
                .selectFields(new List<String>{
                    'Name',
                    'Email',
                    'Phone',
                    'Contact_Status__c',
                    'CreatedDate',
                    'LastModifiedDate'
                })
                .executeQuery()
            ) {
                matchedContactList.add(new ListResult(cont.Name, cont.Email, cont.Phone, null, cont.Contact_Status__c, 
                    cont.CreatedDate, cont.LastModifiedDate, null, cont.Id, null, null, null, null, rcAccount.Name, 
                    null, null, null, rcAccount.RecordType.Name, '/' + cont.Id));
            }
        }
    }

    static Map<Id, Contact> findContactToAccountMap(List<Contact> contactList) {
        Map<Id, Contact> contAccMap = new Map<Id, Contact>();
        if (contactList == null) {
            return contAccMap;
        }
        for (Contact contactObj :contactList) {
            if (contactObj.AccountId != null) {
                contAccMap.put(contactObj.AccountId, contactObj);
            }
        }
        return contAccMap;
    }

    public static List<Opportunity> findOpportunitiesPerAccounts(String conditionalStr, Set<Id> accountIds) {
        String queryStr = 'SELECT Id, Name, CreatedDate, LastModifiedDate, StageName, ' +
                            'Opportunity.Account.Current_Owner__c, Opportunity.OwnerId, AccountId, ' +
                            'Opportunity.Owner.Name, Opportunity.Owner.UserRoleId, CampaignId, Campaign.Protected_Campaign__c, ' +
                            'CloseDate, Opportunity.RecordType.Name, Opportunity.Owner.UserRole.Name, ' +
                            'Account.Current_Owner__r.UserRole.Name, Account.Current_Owner__r.Name, ' +
                            'Account.RecordType.Name, '+ /*CMR-221256 : Add account record type to smart search*/
                            'Account.Name,Opportunity.RecordTypeName__c '+
                            'FROM Opportunity ' + (conditionalStr != '' ? ' WHERE ' + conditionalStr : '') +
                            ' ORDER BY LastModifiedDate DESC LIMIT 400';
            try {
                return Database.query(queryStr);
            } catch (Exception e) {
                AuraHandledException exc = new AuraHandledException('ERROR ' + e.getMessage());
                exc.setMessage('ERROR ' + e.getMessage());
                throw exc;            
            }
    }

    static Map<Id, List<Opportunity>> findOppPerAccountId(List<Opportunity> oppList) {
        Map<Id, List<Opportunity>> accountToOppMap = new Map<Id, List<Opportunity>>();
        if (oppList == null) {
            return accountToOppMap;
        }
        for (Opportunity oppObj : oppList) {
            if (oppObj.AccountId != null) {
                List<Opportunity> oppPerAccounts = new List<Opportunity>();
                if (accountToOppMap.get(oppObj.AccountId) != null
                    && accountToOppMap.get(oppObj.AccountId).size() != 0) {
                    oppPerAccounts = accountToOppMap.get(oppObj.AccountId);
                }
                oppPerAccounts.add(oppObj);
                accountToOppMap.put(oppObj.AccountId, oppPerAccounts);
            }
        }
        return accountToOppMap;
    }

    static void addOpp(Opportunity oppObj, Contact contactObj) {

        if (!contactIdSet.contains(contactObj.Id)) {
            contactCampaignMap.put(contactObj.Id, contactObj.CampaignMembers);
            contactIdSet.add(contactObj.Id);
        }
        list<CampaignMember> campaignMemList = contactCampaignMap.get(contactObj.Id);

        if (oppObj.RecordTypeName__c == 'VAR Opportunity') {
            if (oppObj.StageName == '0. Downgraded') {
                if (unprotectedOpportunityList.size() < 50) {
                    unprotectedOpportunityList.add(new ListResult(contactObj.Name, contactObj.Email, contactObj.Phone,
                    contactObj.Account?.Name, oppObj.StageName, oppObj.CreatedDate, oppObj.LastModifiedDate,
                    oppObj.Owner.Name, oppObj.id, oppObj.OwnerId, '', '', '',
                    oppObj.Account?.Name, oppObj.CloseDate, null, null,oppObj.Account?.Recordtype.Name, '/' + oppObj.id));
                    oppUnProtectedListIdSet.add(oppObj.Id);
                }

            } else if (opportunityNoCOList.size() < 50) {
                opportunityNoCOList.add(new ListResult(contactObj.Name, contactObj.Email, contactObj.Phone,
                    contactObj.Account?.Name, oppObj.StageName, oppObj.CreatedDate, oppObj.LastModifiedDate,
                    oppObj.Owner.Name, oppObj.id, oppObj.OwnerId, '', '', '',
                    oppObj.Account?.Name, oppObj.CloseDate, null, null, oppObj.Account?.Recordtype.Name, '/' + oppObj.id));
                oppNoCOListIdSet.add(oppObj.Id);
            }
        } else if ((oppObj.AccountId != null && oppObj.Account.Current_Owner__c != null) || (oppObj.CampaignId != null &&
            oppObj.Campaign.Protected_Campaign__c == true) || (campaignMemList != NULL && campaignMemList.size() > 0)) {
                if (!oppListIdSet.contains(oppObj.Id) && opportunityList.size() < 50) {
                    opportunityList.add(new ListResult(contactObj.Name, contactObj.Email, contactObj.Phone,
                        contactObj.Account?.Name, oppObj.StageName, oppObj.CreatedDate, oppObj.LastModifiedDate,
                        oppObj.Account?.Current_Owner__r.Name, oppObj.id, oppObj.Account?.Current_Owner__c,
                        '', '', '',
                        oppObj.Account?.Name, oppObj.CloseDate, null, null,oppObj.Account?.Recordtype.Name, '/' + oppObj.id));
                    oppListIdSet.add(oppObj.Id);
                }
        } else if (OpportunityHelper.isActiveOpp(oppObj.StageName) || (OpportunityHelper.isClosedOpp(oppObj.StageName)
                    && oppObj.CloseDate > Date.today().addDays(-4))) {
            if (!oppNoCOListIdSet .contains(oppObj.Id)) {
                if (opportunityNoCOList.size() < 50) {
                    opportunityNoCOList.add(new ListResult(contactObj.Name, contactObj.Email, contactObj.Phone,
                        contactObj.Account?.Name, oppObj.StageName, oppObj.CreatedDate, oppObj.LastModifiedDate,
                        oppObj.Owner.Name, oppObj.id, oppObj.OwnerId, '', '', '',
                        oppObj.Account?.Name, oppObj.CloseDate, null, null,oppObj.Account?.Recordtype.Name, '/' + oppObj.id));
                    oppNoCOListIdSet.add(oppObj.Id);
                }
            }
        } else {
            if (!oppUnProtectedListIdSet.contains(oppObj.Id)) {
                if (unprotectedOpportunityList.size() < 50) {
                    unprotectedOpportunityList.add(new ListResult(contactObj.Name, contactObj.Email, contactObj.Phone,
                        contactObj.Account?.Name, oppObj.StageName, oppObj.CreatedDate, oppObj.LastModifiedDate,
                        oppObj.Owner.Name, oppObj.id, oppObj.OwnerId, '', '', '',
                        oppObj.Account?.Name, oppObj.CloseDate, null, null,oppObj.Account?.Recordtype.Name, '/' + oppObj.id));
                    oppUnProtectedListIdSet.add(oppObj.Id);
                }
            }
        }
    }

    static Set<Id> getCurrentUser(Id ownerId) {
        Set<Id> oppOwnerIds = new Set<Id>();
        if (ownerId != null) {
            if ((String.valueOf(ownerId)).startsWith('005')) {
                oppOwnerIds.add(ownerId);
            }
        }
        return oppOwnerIds;
    }

    static void oppPerContacts(List<Contact> contactList) {
        Map<Id, Contact> accIdContactMap = findContactToAccountMap(contactList);
        Set<Id> accountIds = accIdContactMap.keySet();
        if (accountIds.size() != 0) {
            String conditionalStr = ' AccountId IN:accountIds '
                            + ' AND ((Opportunity.RecordType.Name = \'Sales Opportunity\' OR Opportunity.RecordType.Name' 
                            + ' = \'Sales Opportunity zQuote\' OR Opportunity.RecordType.Name = \'New Sales Opportunity\')'
                            + ' OR RecordTypeId = NULL)';
            List<Opportunity> oppPerAccounts = findOpportunitiesPerAccounts(conditionalStr, accountIds);
            if (oppPerAccounts != null) {
                for (Opportunity opp : oppPerAccounts) {
                    Contact con = accIdContactMap.get(opp.AccountId);
                    addOpp(opp,con);
                }
                Map<Id, List<Opportunity>> accountToOppMap = findOppPerAccountId(oppPerAccounts);
                if (accountToOppMap != null) {
                    for (Contact contactObj : contactList) {
                        List<Opportunity> oppObjList = accountToOppMap.get(contactObj.AccountId);
                        if (oppObjList != null) {
                            for (Opportunity oppObj : oppObjList) {
                                oppAndAccountOwnerId.addAll(getCurrentUser(oppObj.OwnerId));
                                oppAndAccountOwnerId.addAll(getCurrentUser(oppObj.Account.Current_Owner__c));
                            }
                        }
                    }
                }
            }
        }
    }

    public static List<Opportunity> findOpportunitiesPerCompanyName(String conditionalStr) {
        String queryStr = 'SELECT Id, Name, CreatedDate, LastModifiedDate, StageName, ' +
                    'Opportunity.Account.Current_Owner__c, Opportunity.Account.Name, Opportunity.Owner.Name, ' +
                    'Opportunity.OwnerId, Opportunity.Owner.UserRoleId, AccountId, CloseDate, ' +
                    'Account.RC_Account_Status__c, Opportunity.Owner.UserRole.Name, ' +
                    'Account.Current_Owner__r.UserRole.Name, Account.Current_Owner__r.Name, ' +
                    'Opportunity.RecordType.Name, CampaignId, Campaign.Protected_Campaign__c, ' +
                    'RecordTypeName__c, ' +
            	    'Account.RecordType.Name, '+ /*CMR-221256 : Add account record type to smart search*/
                    '(SELECT Id, Contact.Name, Contact.Email, Contact.Phone, Contact.Account.Name ' +
                        'FROM OpportunityContactRoles LIMIT 1) ' +
                    'FROM Opportunity' + (conditionalStr != '' ? ' WHERE ' + conditionalStr : '') +
                    ' ORDER BY LastModifiedDate DESC LIMIT 400';
            try {
                return Database.query(queryStr);
            } catch(Exception e) {
                AuraHandledException exc = new AuraHandledException('ERROR ' + e.getMessage());
                exc.setMessage('ERROR ' + e.getMessage());
                throw exc;            
            }
    }

    public static List<Contact> findContactPerOppRoles(String conditionalStr, List<Id> oppContactRoleIds) {
        String queryStr = 'SELECT Id, Name, AccountId, Email, Phone, Contact.Account.Name, Account.RecordType.Name, '
                            + '(SELECT CampaignId,Campaign.Protected_Campaign__c, ContactId From CampaignMembers where '
                            + 'Campaign.Protected_Campaign__c = true limit 1) FROM Contact'
                            + (conditionalStr != '' ? ' WHERE ' + conditionalStr : '')+' ORDER BY LastModifiedDate DESC LIMIT 400';
            try {
                return Database.query(queryStr);
            } catch (Exception e) {
                AuraHandledException exc = new AuraHandledException('ERROR ' + e.getMessage());
                exc.setMessage('ERROR ' + e.getMessage());
                throw exc;            
            }
    }

    static void addOppNoContact(Opportunity oppObj, Contact cont) {
        if (cont != null && cont.Id != null) {
            if (!contactIdSet.contains(cont.Id)) {
                contactCampaignMap.put(cont.Id,cont.CampaignMembers);
                contactIdSet.add(cont.Id);
            }
            if (cont != null && cont.Id != null) {
                addOpp(oppObj, cont);
            }
        }
    }

    static void oppPerContactRoles() {
        Map<Id, Opportunity> oppIdMap = new Map<Id, Opportunity>();
        Map<Id, Id> oppContactRoles = new Map<Id, Id>();
        String conditionalStr = ' (Opportunity.Account.Name=\'' +
            String.escapeSingleQuotes(newLead.Company.trim()) +
            '\' OR Name=\''+String.escapeSingleQuotes(newLead.Company.trim())+'\') ' +
            ' AND ((Opportunity.RecordType.Name = \'Sales Opportunity\' ' +
                'OR Opportunity.RecordType.Name = \'Sales Opportunity zQuote\' ' +
                'OR Opportunity.RecordType.Name = \'New Sales Opportunity\' ' +
                'OR Opportunity.RecordType.Name = \'VAR Opportunity\') ' +
                'OR RecordTypeId = NULL) ';
        List<Opportunity> oppList = findOpportunitiesPerCompanyName(conditionalStr);
        for (Opportunity oppObj : oppList) {
            oppIdMap.put(oppObj.Id, oppObj);
            if (oppObj.OpportunityContactRoles != null && oppObj.OpportunityContactRoles.size() != 0) {
                if (oppObj.OpportunityContactRoles.get(0).Contact.Id != null) {
                    oppContactRoles.put(oppObj.Id, oppObj.OpportunityContactRoles.get(0).Contact.Id);
                }
            }
            oppAndAccountOwnerId.addAll(getCurrentUser(oppObj.OwnerId));
            oppAndAccountOwnerId.addAll(getCurrentUser(oppObj.Account?.Current_Owner__c));
        }
        if (oppContactRoles.size() != 0) {
            List<Id> oppContactRoleIds = oppContactRoles.values();
            conditionalStr = ' Id IN: oppContactRoleIds';
            List<Contact> contactList = findContactPerOppRoles(conditionalStr,oppContactRoleIds);
            if (contactList != null) {
            Map<Id, Contact> contactMap = new Map<Id, Contact>(contactList);
                for (Opportunity oppObj : oppList) {
                    Id contactId = oppContactRoles.get(oppObj.Id);
                    if (contactId != null && contactMap != null)  {
                        addOppNoContact(oppObj, contactMap.get(contactId));
                    }
                }
            }
        }
    }

    public static List<Lead> findExistingProtectedLeads(String conditionalStr) {
        Datetime dt = System.now().addDays(-30);
        String lastMonth = dt.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
        dt = System.now().addDays(-180);
        String lastSixMonth = dt.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');

        if (conditionalStr != null && conditionalStr != '') {
            conditionalStr += ' AND Status = \'2. Contacted\'' +
                          ' AND ((CreatedDate > ' + lastMonth +
                          ' AND RecordTypeId != \'' + RT_ID_PARTNER_LEAD +'\')' +
                          ' OR (RecordTypeId = \'' + RT_ID_PARTNER_LEAD + '\' ' +
                          ' AND CreatedDate > ' + lastSixMonth + '))';
        }

        /*CMR-233088 - account record type name added.*/
        String queryStr = 'SELECT Id, Name, Email,Domain__c, Phone, Company, Status, CreatedDate, LastModifiedDate, ' +
            'Lead.Owner.Name, LeadSource, Primary_Campaign__c, isOwnership_Claimed__c, Five9_DNIS__c, NumberOfEmployees__c, ' +
            'Account__r.Name,Account__r.RecordType.Name ,Effective_No_of_Employees_Range__c, RecordTypeId, ' +
                '(SELECT Id, IsDeleted, CampaignId, Campaign.Protected_Campaign__c, LeadId ' +
                'FROM CampaignMembers ' +
                'WHERE Campaign.Protected_Campaign__c = true LIMIT 1)' +
            'FROM Lead ' +
            (conditionalStr != '' ? ' WHERE ' + conditionalStr : '') +
            ' ORDER BY isOwnership_Claimed__c, LastModifiedDate DESC ' +
            'LIMIT 50';
        try {
            return Database.query(queryStr);
        } catch (Exception e) {
            AuraHandledException exc = new AuraHandledException('ERROR ' + e.getMessage());
            exc.setMessage('ERROR ' + e.getMessage());
            throw exc;
        }
    }

    public static List<Lead> findExistingUnprotectedLeads(String conditionalStr) {
        Datetime dt = System.now().addDays(-30);
        String lastMonth = dt.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');

        if (conditionalStr != null && conditionalStr != '') {
            conditionalStr += ' AND Status != \'2. Contacted\' ' +
                          ' AND (CreatedDate < ' + lastMonth +
                          ' AND RecordTypeId = \'' + RT_ID_SALES_LEAD +'\')';
        }

        /*CMR-233088 account record type name added*/
        String queryStr = 'SELECT Id, Name, Email,Domain__c, Phone, Company, Status, CreatedDate, LastModifiedDate, ' +
            'Lead.Owner.Name, LeadSource, Primary_Campaign__c, isOwnership_Claimed__c, Five9_DNIS__c, NumberOfEmployees__c, ' +
            'Account__r.Name,Account__r.RecordType.Name, Effective_No_of_Employees_Range__c, RecordTypeId, ' +
                '(SELECT Id, IsDeleted, CampaignId, Campaign.Protected_Campaign__c, LeadId ' +
                'FROM CampaignMembers ' +
                'WHERE Campaign.Protected_Campaign__c = true LIMIT 1)' +
            'FROM Lead ' +
            (conditionalStr != '' ? ' WHERE ' + conditionalStr : '') +
            ' ORDER BY isOwnership_Claimed__c, LastModifiedDate DESC ' +
            'LIMIT 50';
        try {
            return Database.query(queryStr);
        } catch (Exception e) {
            AuraHandledException exc = new AuraHandledException('ERROR ' + e.getMessage());
            exc.setMessage('ERROR ' + e.getMessage());
            throw exc;        
        }
    }

    public static void prepareLeadList(String conditionalStr) {
        try {
            List<Lead> leadFinalList = findExistingProtectedLeads(conditionalStr);
            leadFinalList.addAll(findExistingUnprotectedLeads(conditionalStr));
            Integer counter = 0;
            for (Lead leadObj : leadFinalList) {
                leadCampaignMemMap.put(leadObj.Id,leadObj.CampaignMembers);
                leadListTemp.add(leadObj);
                leadOwnerIdSet.addAll(getCurrentUser(leadObj.OwnerId));
             }
         } catch (Exception e) {
            AuraHandledException exc = new AuraHandledException('ERROR ' + e.getMessage());
            exc.setMessage('ERROR ' + e.getMessage());
            throw exc;       
        }
    }

    static Boolean isProtectedLead(Lead leadObj) {
        Boolean rtn = false;
        if (leadObj.status != null
            && leadObj.recordTypeId != null
            && Schema.SObjectType.Lead.getRecordTypeInfosById()
            .get(leadObj.recordTypeId).getName() != null) {
            if (((leadObj.status == '2. Contacted')
                && (leadObj.CreatedDate.Date() > Date.Today().addDays(-30))
                && Schema.SObjectType.Lead.getRecordTypeInfosById()
                    .get(leadObj.recordtypeid).getname() != 'Partner Leads')
                || (Schema.SObjectType.Lead.getRecordTypeInfosById()
                    .get(leadObj.recordtypeid).getname() == 'Partner Leads'
                    && leadObj.CreatedDate.Date() > Date.Today().addDays(-180))) {
                rtn = true;
            }
        }
        return rtn;
    }

    static Map<String, Object> keysToUpper(Map<String, Object> mapToModify) {
        Map<String, Object> result = new Map<String, Object>();
        for (String str : mapToModify.keySet()) {
            result.put(str.toUpperCase(), mapToModify.get(str));
        }
        return result;
    }
    
    @AuraEnabled
    public static Map<String, List<ListResult>> search(String jsonParams) {
        Map<String, Object> deserializedJSON = (Map<String, Object>) JSON.deserializeUntyped(jsonParams); 
        /* URL Parameters */
        Map<String, Object> deserializedParams = (Map<String, Object>) deserializedJSON.get('params');
        deserializedParams = keysToUpper(deserializedParams);
        String leadSysSourceUrl = deserializedParams.get('SOURCE') != null ? (String) deserializedParams.get('SOURCE') : '';
        String invocaTransactionId = (String) deserializedParams.get('INVOCAID');
        String dnis = (String) deserializedParams.get('DNIS');
        String userId = (String) deserializedParams.get('USERID');
        String inContactId = (String) deserializedParams.get('CID'); 
        String skillName = (String) deserializedParams.get('SKILL');  

        /*populate newLead*/
        Map<String, Object> newLeadMap = deserializedJSON.get('newLead') != null ? 
            (Map<String, Object>) deserializedJSON.get('newLead') : new Map<String, Object>();
        if (newLeadMap.isEmpty()) {
            newLead = new Lead();
        } else {
            String newLeadJSON = (String)JSON.serialize(newLeadMap);
            newLead = (Lead) JSON.deserialize(newLeadJSON, Lead.class);   
        }
        /* populate rcAccount */
        Map<String, Object> rcAccountMap = deserializedJSON.get('rcAccount') != null ? 
            (Map<String, Object>) deserializedJSON.get('rcAccount') : new Map<String, Object>();
        if (rcAccountMap.isEmpty()) {
            rcAccount = null;
        } else {
            String rcAccountJSON = (String)JSON.serialize(rcAccountMap);
            rcAccount = (Account) JSON.deserialize(rcAccountJSON, Account.class);
        }
        
        Id rcId = OpportunityHelper.getOppRecordTypeMap('Sales Opportunity');
        String domain;
        String formattedNumber;
        String phoneNumber;
        String plusOnePhoneFormat;
        Boolean isFreeDomain = false;

        if (!isEmpty(newLead.Email) && isValidEmail(newLead.Email.trim())) {
            String emailTrimmed = newLead.Email.trim();
            domain = emailTrimmed.subString(emailTrimmed.lastIndexOf('@')+1, emailTrimmed.length());
        }
        List<Segment_Data__c> domainList = (List<Segment_Data__c>) new SegmentDataSelector()
                .selectSegmentDataForSmartSearch(new List<Object> {domain})
                .executeQuery();
            if (!domainList.isEmpty()) {
                isFreeDomain = true;
            }
        
        if ((isEmpty(newLead.LastName))
        && (isEmpty(newLead.Company))
        && (isEmpty(newLead.Email))
        && (isEmpty(newLead.Phone))) {
            AuraHandledException e = new AuraHandledException('INFO  You must enter at least one of these fields to '+ 
            'search: Last Name, Company Name, Email Address, Contact Phone Number.');
            e.setMessage('INFO  You must enter at least one of these fields to search: Last Name, Company Name, '+ 
            'Email Address, Contact Phone Number.');
            throw e;
        } else {
            if (!isValidEmail(newLead.Email.trim())) {
                AuraHandledException e = new AuraHandledException('ERROR ' + 'The email entered is not in a valid format.');
                e.setMessage('ERROR ' + 'The email entered is not in a valid format.');
                throw e;
            }else if (String.isNotBlank(newLead.Website) && !LeadHelper.isValidWebsite(newLead.Website.trim())) {
                AuraHandledException e = new AuraHandledException('ERROR ' + System.Label.Invalid_Website_Error);
                e.setMessage('ERROR ' + System.Label.Invalid_Website_Error);
                throw e;
            } else {
                opportunityList = new List<ListResult>();
                opportunityNoCOList = new List<ListResult>();
                unprotectedOpportunityList = new List<ListResult>();
                leadList = new List<ListResult>();
                unprotectedLeadList = new List<ListResult>();
                protectedLeadList = new List<ListResult>();
                matchedContactList = new List<ListResult>();
                leadListTemp = new List<Lead>();
                oppListIdSet = new Set<Id>();
                oppNoCOListIdSet = new Set<Id>();
                oppUnProtectedListIdSet = new Set<Id>();
                contactIdSet = new Set<Id>();
                leadOwnerIdSet = new Set<Id>();
                oppAndAccountOwnerId = new Set<Id>();
                contactCampaignMap = new Map<Id,list<CampaignMember>>();


                /*As per New Phone Number Format Logic*/
                if (!isEmpty(newLead.Phone)){
                    phoneNumber = newLead.Phone.trim();
                    formattedNumber = newLead.Phone.trim();
                    plusOnePhoneFormat = newLead.Phone.trim();
                    String strPhoneValue = phoneNumber;
                    if (strPhoneValue!='') {
                        if (strPhoneValue.trim().startsWith('+44') 
                        || strPhoneValue.trim().startsWith('44') 
                        || strPhoneValue.trim().startsWith('0')) {
                            formattedNumber = ValidationUtility.validatePhoneNumber(strPhoneValue,'UK');
                        } else {
                            formattedNumber = ValidationUtility.commonUSandCAPhoneFormat(strPhoneValue);
                        }
                        if (!strPhoneValue.trim().startsWith('+44') 
                        && !strPhoneValue.trim().startsWith('44') 
                        && !strPhoneValue.trim().startsWith('0')) {
                            plusOnePhoneFormat= '1' + strPhoneValue.trim();
                        }
                    }
                }
                /****************Domain check**********************/
                String emailSearchStr='';
                if (isFreeDomain) {
                    emailSearchStr = ' email=\''+newLead.Email.trim()+'\' ';
                } else {
                    emailSearchStr = ' Domain__c=\''+domain+'\' ';
                }
                /**************************************************/

                if (!isEmpty(newLead.phone) || !isEmpty(newLead.Email)) {
                    loadMatchedContactList(leadSysSourceUrl,formattedNumber,plusOnePhoneFormat);
                }

                /* search for match with email, phone, company and last */
                if (!isEmpty(newLead.FirstName)
                        && !isEmpty(newLead.LastName)
                        && !isEmpty(newLead.Company)
                        && !isEmpty(newLead.Email)
                        && !isFakeEmail(newLead.Email)
                        && !isEmpty(newLead.Phone)) {
                        /*search over contact table
                        Code modifed for 101 Error__________*/
                        String conditionalStr = ' AccountId != null'
                                        + ' AND ((firstName=\''+String.escapeSingleQuotes(newLead.FirstName.trim())+'\''
                                        + ' AND lastName=\''+String.escapeSingleQuotes(newLead.LastName.trim())+'\')'
                                        + ' OR ' +emailSearchStr
                                        + ' OR phone=\''+phoneNumber+'\''
                                        + ' OR phone=\''+plusOnePhoneFormat+'\''
                                        + (String.isBlank(formattedNumber) ? ')' : ' OR phone=\''+formattedNumber+'\')');
                        Contact[] contactList = findContactList(conditionalStr);
                        oppPerContacts(contactList);
                        /* search for matching company name as Account/Opportunity name*/
                        oppPerContactRoles();
                        conditionalStr = ' ((firstName=\''+String.escapeSingleQuotes(newLead.FirstName.trim())+'\''
                                            + ' AND lastName=\''+String.escapeSingleQuotes(newLead.LastName.trim())+'\')'
                                            + ' OR '+emailSearchStr
                                            + ' OR phone=\''+phoneNumber+'\''
                                            + ' OR phone=\''+plusOnePhoneFormat+'\''
                                            + (String.isBlank(formattedNumber) ? '' : ' OR phone=\''+formattedNumber+'\'')
                                            + ' OR company=\''+String.escapeSingleQuotes(newLead.Company.trim())+'\')'
                                            + ' AND isConverted= false '
                                            + ' AND LeadSource !=\'Prospect List\'';
                        prepareLeadList(conditionalStr);
                }
                /* search for match with email, phone and company */
                else if ((isEmpty(newLead.FirstName)
                        || isEmpty(newLead.LastName))
                        && !isEmpty(newLead.Company)
                        && (!isEmpty(newLead.Email)
                        && !isFakeEmail(newLead.Email))
                        && !isEmpty(newLead.Phone)) {

                    String conditionalStr = ' AccountId != null '
                                        + ' AND ('+emailSearchStr
                                        + ' OR phone=\''+phoneNumber+'\''
                                        + ' OR phone=\''+plusOnePhoneFormat+'\''
                                        + (String.isBlank(formattedNumber) ? ')' : ' OR phone=\''+formattedNumber+'\')');
                    Contact[] contactList = findContactList(conditionalStr);
                    oppPerContacts(contactList);
                    oppPerContactRoles();
                    conditionalStr = '('+emailSearchStr
                                        + ' OR phone=\''+phoneNumber+'\''
                                        + ' OR phone=\''+plusOnePhoneFormat+'\''
                                        + (String.isBlank(formattedNumber) ? '' : ' OR phone=\''+formattedNumber+'\'')
                                        + ' OR company=\''+String.escapeSingleQuotes(newLead.Company.trim())+'\')'
                                        + ' AND isConverted= false '
                                        + ' AND LeadSource !=\'Prospect List\'';
                    prepareLeadList(conditionalStr);
                    
                }
                /* search for match with email, phone and lastname */
                else if (!isEmpty(newLead.FirstName)
                        && !isEmpty(newLead.LastName)
                        && isEmpty(newLead.Company)
                        && !isEmpty(newLead.Email)
                        && !isFakeEmail(newLead.Email)
                        && !isEmpty(newLead.Phone)) {
                    /*search over contact table
                    /Code modifed for 101 Error__________*/
                    String conditionalStr = ' AccountId != null '
                                        + ' AND ((firstName=\''+String.escapeSingleQuotes(newLead.FirstName.trim())+'\''
                                        + ' AND lastName=\''+String.escapeSingleQuotes(newLead.LastName.trim())+'\')'
                                        + ' OR '+emailSearchStr
                                        + ' OR phone=\''+phoneNumber+'\''
                                        + ' OR phone=\''+plusOnePhoneFormat+'\''
                                        + (String.isBlank(formattedNumber) ? ')' : ' OR phone=\''+formattedNumber+'\')');
                    Contact[] contactList = findContactList(conditionalStr);
                    oppPerContacts(contactList);
                    conditionalStr ='((firstName=\''+String.escapeSingleQuotes(newLead.FirstName.trim())+'\''
                                        + ' AND lastName=\''+String.escapeSingleQuotes(newLead.LastName.trim())+'\')'
                                        + ' OR ('+emailSearchStr
                                        + ' OR phone=\''+phoneNumber+'\''
                                        + ' OR phone=\''+plusOnePhoneFormat+'\''
                                        + (String.isBlank(formattedNumber) ? '))' : ' OR phone=\''+formattedNumber+'\'))')
                                        + ' AND isConverted= false '
                                        + ' AND LeadSource !=\'Prospect List\'';
                    prepareLeadList(conditionalStr);
                }
                /* search for match with email, company and last */
                else if ((!isEmpty(newLead.FirstName)
                        && !isEmpty(newLead.LastName))
                        && !isEmpty(newLead.Company)
                        && (!isEmpty(newLead.Email) && !isFakeEmail(newLead.Email))
                        && isEmpty(newLead.Phone)) {
                    String conditionalStr = ' AccountId != null '
                                        + ' AND ((firstName=\''+String.escapeSingleQuotes(newLead.FirstName.trim())+'\''
                                        + ' AND lastName=\''+String.escapeSingleQuotes(newLead.LastName.trim())+'\')'
                                        + ' OR '+emailSearchStr + ')';
                    Contact[] contactList = findContactList(conditionalStr);
                    oppPerContacts(contactList);
                    oppPerContactRoles();
                    
                    conditionalStr ='((firstName=\''+String.escapeSingleQuotes(newLead.FirstName.trim())+'\''
                                        + ' AND lastName=\''+String.escapeSingleQuotes(newLead.LastName.trim())+'\')'
                                        + ' OR '+emailSearchStr
                                        + ' OR company=\''+String.escapeSingleQuotes(newLead.Company.trim())+'\')'
                                        + ' AND isConverted= false '
                                        + ' AND LeadSource !=\'Prospect List\'';
                    prepareLeadList(conditionalStr);
                    

                }
                /*search for match with phone, company and lastname*/
                else if ((!isEmpty(newLead.FirstName)
                        && !isEmpty(newLead.LastName))
                        && !isEmpty(newLead.Company)
                        && (isEmpty(newLead.Email) || isFakeEmail(newLead.Email))
                        && !isEmpty(newLead.Phone)) {
                    String conditionalStr = ' AccountId != null '
                                        + ' AND ((firstName=\''+String.escapeSingleQuotes(newLead.FirstName.trim())+'\''
                                        + ' AND lastName=\''+String.escapeSingleQuotes(newLead.LastName.trim())+'\')'
                                        + (String.isBlank(formattedNumber) ? '' : ' OR phone=\''+formattedNumber+'\'')
                                        + ' OR phone=\''+plusOnePhoneFormat+'\''
                                        + ' OR phone=\''+phoneNumber+'\')';
                    Contact[] contactList = findContactList(conditionalStr);
                    oppPerContacts(contactList);
                    oppPerContactRoles();
                
                    conditionalStr ='((firstName=\''+String.escapeSingleQuotes(newLead.FirstName.trim())+'\''
                                        + ' AND lastName=\''+String.escapeSingleQuotes(newLead.LastName.trim())+'\')'
                                        + ' OR company=\''+String.escapeSingleQuotes(newLead.Company.trim())+'\''
                                        + ' OR phone=\''+phoneNumber+'\''
                                        + ' OR phone=\''+plusOnePhoneFormat+'\''
                                        + (String.isBlank(formattedNumber) ? ')' : ' OR phone=\''+formattedNumber+'\')')
                                        + ' AND isConverted= false '
                                        + ' AND LeadSource !=\'Prospect List\'';
                    prepareLeadList(conditionalStr);
                

                }
                /* search for match with email and phone */
                else if ((isEmpty(newLead.FirstName)
                    || isEmpty(newLead.LastName))
                    && isEmpty(newLead.Company)
                    && !isEmpty(newLead.Email)
                    && !isFakeEmail(newLead.Email)
                    && !isEmpty(newLead.Phone)) {
                    /* search over contact table */
                    String conditionalStr = ' AccountId != null '
                                        + ' AND ('+emailSearchStr
                                        + (String.isBlank(formattedNumber) ? '' : ' OR phone=\''+formattedNumber+'\'')
                                        + ' OR phone=\''+plusOnePhoneFormat+'\''
                                        + ' OR phone=\''+phoneNumber+'\')';
                    Contact[] contactList = findContactList(conditionalStr);
                    oppPerContacts(contactList);
                    
                    conditionalStr = '('+emailSearchStr
                                        + ' OR phone=\''+phoneNumber+'\''
                                        + ' OR phone=\''+plusOnePhoneFormat+'\''
                                        + (String.isBlank(formattedNumber) ? ')' : ' OR phone=\''+formattedNumber+'\')')
                                        + ' AND isConverted= false '
                                        + ' AND LeadSource !=\'Prospect List\'';
                    prepareLeadList(conditionalStr);
                    
                }
                /* search for match with email and company */
                else if ((isEmpty(newLead.FirstName)
                    || isEmpty(newLead.LastName))
                    && !isEmpty(newLead.Company)
                    && !isEmpty(newLead.Email)
                    && !isFakeEmail(newLead.Email)
                    && isEmpty(newLead.Phone)) {
                    String conditionalStr = ' AccountId != null '
                                        + ' AND '+emailSearchStr;
                    Contact[] contactList = findContactList(conditionalStr);
                    oppPerContacts(contactList);
                    oppPerContactRoles();
                    
                    conditionalStr = '('+emailSearchStr
                                        + ' OR company=\''+String.escapeSingleQuotes(newLead.Company.trim())+'\')'
                                        + ' AND isConverted= false '
                                        + ' AND LeadSource !=\'Prospect List\'';
                    prepareLeadList(conditionalStr);
                    
                }
                /* search for match with email and last */
                else if ((!isEmpty(newLead.FirstName)
                    && !isEmpty(newLead.LastName))
                    && isEmpty(newLead.Company)
                    && !isEmpty(newLead.Email) && !isFakeEmail(newLead.Email.trim())
                    && isEmpty(newLead.Phone)) {
                    String conditionalStr =' AccountId != null'
                                        + ' AND ((firstName=\''+String.escapeSingleQuotes(newLead.FirstName.trim())+'\''
                                        + ' AND lastName=\''+String.escapeSingleQuotes(newLead.LastName.trim())+'\')'
                                        + ' OR '+emailSearchStr + ')';
                    Contact[] contactList = findContactList(conditionalStr);
                    oppPerContacts(contactList);
                    
                    conditionalStr =' ((firstName=\''+String.escapeSingleQuotes(newLead.FirstName.trim())+'\''
                                        + ' AND lastName=\''+String.escapeSingleQuotes(newLead.LastName.trim())+'\')'
                                        + ' OR '+emailSearchStr +')'
                                        + ' AND isConverted= false '
                                        + ' AND LeadSource !=\'Prospect List\'';
                    prepareLeadList(conditionalStr);
                    
                }
                /* search for match with phone and company */
                else if ((isEmpty( newLead.FirstName)
                    || isEmpty(newLead.LastName))
                    && !isEmpty(newLead.Company)
                    && (isEmpty(newLead.Email) || isFakeEmail(newLead.Email))
                    && !isEmpty(newLead.Phone)) {
                    String conditionalStr =' AccountId != null'
                                        + ' AND (Phone=\''+phoneNumber+'\''
                                        + ' OR Phone=\''+plusOnePhoneFormat+'\''
                                        + (String.isBlank(formattedNumber) ? ')' : ' OR Phone=\''+formattedNumber+'\')');
                    Contact[] contactList = findContactList(conditionalStr);
                    oppPerContacts(contactList);
                    oppPerContactRoles();
                    
                    conditionalStr =' (Phone=\''+phoneNumber+'\''
                                        + (String.isBlank(formattedNumber) ? '' : ' OR Phone=\''+formattedNumber+'\'')
                                        + ' OR Phone=\''+plusOnePhoneFormat+'\''
                                        + ' OR company=\''+String.escapeSingleQuotes(newLead.Company.trim())+'\')'
                                        + ' AND isConverted= false '
                                        + ' AND LeadSource !=\'Prospect List\'';
                    prepareLeadList(conditionalStr);
                    
                }
                /* search for match with phone and lastname */
                else if ((!isEmpty(newLead.FirstName)
                    && !isEmpty(newLead.LastName))
                    && isEmpty(newLead.Company)
                    && (isEmpty(newLead.Email)
                    || isFakeEmail(newLead.Email))
                    && !isEmpty(newLead.Phone)) {
                    /* search over contact table
                    Code modifed for 101 Error__________ */
                    String conditionalStr =' AccountId != null '
                                        + ' AND ((firstName=\''+String.escapeSingleQuotes(newLead.FirstName.trim())+'\''
                                        + ' AND lastName=\''+String.escapeSingleQuotes(newLead.LastName.trim())+'\')'
                                        + ' OR Phone=\''+phoneNumber+'\''
                                        + ' OR Phone=\''+plusOnePhoneFormat+'\''
                                        + (String.isBlank(formattedNumber) ? ')' : ' OR Phone=\''+formattedNumber+'\')');
                    Contact[] contactList = findContactList(conditionalStr);
                    oppPerContacts(contactList);
                    conditionalStr =' ((firstName=\''+String.escapeSingleQuotes(newLead.FirstName.trim())+'\''
                                        + ' AND lastName=\''+String.escapeSingleQuotes(newLead.LastName.trim())+'\')'
                                        + ' OR Phone=\''+phoneNumber+'\''
                                        + ' OR Phone=\''+plusOnePhoneFormat+'\''
                                        + (String.isBlank(formattedNumber) ? ')' : ' OR Phone=\''+formattedNumber+'\')')
                                        + ' AND isConverted= false '
                                        + ' AND LeadSource !=\'Prospect List\'';
                    prepareLeadList(conditionalStr);
                }
                /* search for match with company and lastname */
                else if (!isEmpty(newLead.FirstName)
                    && !isEmpty(newLead.LastName)
                    && !isEmpty(newLead.Company)
                    && (isEmpty(newLead.Email)
                    || isFakeEmail(newLead.Email))
                    && isEmpty(newLead.Phone)) {
                    String conditionalStr =' AccountId != null '
                                        + ' AND (firstName=\''+String.escapeSingleQuotes(newLead.FirstName.trim())+'\''
                                        + ' AND lastName=\''+String.escapeSingleQuotes(newLead.LastName.trim())+'\')' ;
                    Contact[] contactList = findContactList(conditionalStr);
                    oppPerContacts(contactList);
                    oppPerContactRoles();
                    
                    conditionalStr =' ((firstName=\''+String.escapeSingleQuotes(newLead.FirstName.trim())+'\''
                                        + ' AND lastName=\''+String.escapeSingleQuotes(newLead.LastName.trim())+'\')'
                                        + ' OR Company=\''+String.escapeSingleQuotes(newLead.Company.trim())+'\')'
                                        + ' AND isConverted= false '
                                        + ' AND LeadSource !=\'Prospect List\'';
                    prepareLeadList(conditionalStr);
                }
                /* search for match with just email */
                else if ((isEmpty(newLead.FirstName)
                    || isEmpty(newLead.LastName))
                    && isEmpty(newLead.Company)
                    && (!isEmpty(newLead.Email) && !isFakeEmail(newLead.Email))
                    && isEmpty(newLead.Phone)) {
                        String conditionalStr =' AccountId != null '
                                            + ' AND '+emailSearchStr;
                        Contact[] contactList = findContactList(conditionalStr);
                        oppPerContacts(contactList);
                    
                        conditionalStr = emailSearchStr
                                            + ' AND isConverted= false '
                                            + ' AND LeadSource !=\'Prospect List\'';
                        prepareLeadList(conditionalStr);
                    
                }
                /* search for match with just phone */
                else if ((isEmpty(newLead.FirstName)
                    || isEmpty(newLead.LastName))
                    && isEmpty(newLead.Company)
                    && (isEmpty(newLead.Email) || isFakeEmail(newLead.Email))
                    && !isEmpty(newLead.Phone)) {
                        String conditionalStr = ' AccountId != null '
                                                + ' AND (phone=\''+phoneNumber+'\''
                                                + ' OR phone=\''+plusOnePhoneFormat+'\''
                                                + (String.isBlank(formattedNumber) ? ')' : ' OR phone=\''+formattedNumber+'\')');
                        Contact[] contactList = findContactList(conditionalStr);
                        oppPerContacts(contactList);
                        
                        conditionalStr = ' (phone=\''+phoneNumber+'\''
                                    + ' OR phone=\''+plusOnePhoneFormat+'\''
                                    + (String.isBlank(formattedNumber) ? ')' : ' OR phone=\''+formattedNumber+'\')')
                                    + ' AND isConverted= false '
                                    + ' AND LeadSource !=\'Prospect List\'';
                        prepareLeadList(conditionalStr);
                    
                }
                /* search for match with company */
                else if ((isEmpty(newLead.FirstName)
                    || isEmpty(newLead.LastName))
                    && !isEmpty(newLead.Company)
                    && (isEmpty(newLead.Email)
                    || isFakeEmail(newLead.Email))
                    && isEmpty(newLead.Phone)) {
                        oppPerContactRoles();
                        /* search for matching company name as Account/Opportunity name */
                        String conditionalStr = ' Company=\''+String.escapeSingleQuotes(newLead.Company.trim())+'\''
                                + ' AND isConverted= false '
                                + ' AND LeadSource !=\'Prospect List\'';
                        prepareLeadList(conditionalStr);
                    
                }

                /* search for match with lastname */
                else if ((!isEmpty(newLead.FirstName)
                    && !isEmpty(newLead.LastName))
                    && isEmpty(newLead.Company)
                    && (isEmpty(newLead.Email) || isFakeEmail(newLead.Email))
                    && isEmpty(newLead.Phone)) {
                        String conditionalStr ='AccountId != null'
                                            + ' AND (firstName=\''+String.escapeSingleQuotes(newLead.FirstName.trim())+'\''
                                            + ' AND lastName=\''+String.escapeSingleQuotes(newLead.LastName.trim())+'\')';
                        Contact[] contactList = findContactList(conditionalStr);
                        oppPerContacts(contactList);
                        conditionalStr =' (firstName=\''+String.escapeSingleQuotes(newLead.FirstName.trim())+'\''
                                            + ' AND lastName=\''+String.escapeSingleQuotes(newLead.LastName.trim())+'\')'
                                            + ' AND isConverted= false '
                                            + ' AND LeadSource !=\'Prospect List\'';
                        prepareLeadList(conditionalStr);
                }
                if (leadListTemp != null && leadListTemp.size() > 0) {
                    for (Lead leadObj : leadListTemp) {
                        List<CampaignMember> campaignMemList = leadCampaignMemMap.get(leadObj.Id);
                        if (isProtectedLead(leadObj)) {
                                if (protectedLeadList.size() < 50) {
                                    protectedLeadList.add(new ListResult(leadObj.Name, leadObj.Email, leadObj.Phone,
                                        leadObj.Company, leadObj.Status, leadObj.CreatedDate, leadObj.LastModifiedDate,
                                        leadObj.Owner.Name, leadObj.id, leadObj.ownerId,
                                        leadObj.Five9_DNIS__c, leadObj.Effective_No_of_Employees_Range__c,
                                        leadObj.Company,leadObj.Account__r.Name, null, null, leadObj.LeadSource,
                                        leadObj.Account__r.RecordType.Name, '/' + leadObj.id));
                                }/*CMR-233088 -  added account name and account  record type name*/
                        } else {
                            if (unprotectedLeadList.size() < 50) {
                                unprotectedLeadList.add(new ListResult(leadObj.Name, leadObj.Email, leadObj.Phone,
                                    leadObj.Company, leadObj.Status, leadObj.CreatedDate, leadObj.LastModifiedDate,
                                    leadObj.Owner.Name, leadObj.id, leadObj.ownerId,
                                    leadObj.Five9_DNIS__c, leadObj.Effective_No_of_Employees_Range__c,
                                    leadObj.Company,leadObj.Account__r.Name, null, null, 
                                    leadObj.LeadSource,leadObj.Account__r.RecordType.Name,'/' + leadObj.id));
                            }/*CMR 233088 - added account name and account record type name*/
                        }
                    }
                }
            }
        }
        leadCampaignMemMap.clear();
        opportunityList.sort();
        opportunityNoCOList.sort();
        unprotectedOpportunityList.sort();

        Map<String, List<ListResult>> listMap = new Map<String, List<ListResult>>();
        listMap.put('unprotectedLeadsData', unprotectedLeadList);
        listMap.put('protectedLeadData', protectedLeadList);
        listMap.put('unprotectedOppsData', unprotectedOpportunityList); /* Unprotected Opportunities */
        listMap.put('protectedOppsActivePipeData', opportunityNoCOList); /*Protected Opportunities (ActivePipe and 3 Days Closed) */
        listMap.put('protectedOppsCurrentOwnersData', opportunityList); /* Protected Opps w current owners */
        listMap.put('matchedContactData', matchedContactList);
        return listMap;
    } 

    static Contact copyLeadToContactFields(Lead leadObj, Contact conObj) {
        conObj.firstName = (String.isNotBlank(leadObj.firstName)) ?  leadObj.firstName : conObj.firstName;
        conObj.lastName  = (String.isNotBlank(leadObj.lastName)) ?  leadObj.lastName : conObj.lastName;
        conObj.title     = (String.isNotBlank(leadObj.title)) ?  leadObj.title : conObj.title;
        conObj.email     = (String.isNotBlank(leadObj.email)) ?  leadObj.email : conObj.email;
        conObj.phone     = (String.isNotBlank(leadObj.phone)) ?  leadObj.phone : conObj.phone;
        return conObj;
    }
    
    static Contact calculateContactStatus(Contact cont) {
        if (String.isBlank(cont.Contact_Status__c) ||
            (cont.Contact_Status__c != '1.5 Call Out' 
            && LeadHelper.listOfStatusLessThan2Contacted.contains(cont.Contact_Status__c))
        ) {
            cont.Contact_Status__c = '2. Contacted';
        }
        return cont;
    }

    @AuraEnabled
    public static void mergeToContact(String contactId, String jsonParams) {
        ContactTriggerHelper.isMergeContact = true;
        try {
            Map<String, Object> deserializedJSON = (Map<String, Object>) JSON.deserializeUntyped(jsonParams); 
            /* URL Parameters */
            Map<String, Object> deserializedParams = (Map<String, Object>) deserializedJSON.get('params');
            deserializedParams = keysToUpper(deserializedParams);
            String leadSysSourceUrl = deserializedParams.get('SOURCE') != null ? (String) deserializedParams.get('SOURCE') : '';
            String invocaTransactionId = (String) deserializedParams.get('INVOCAID');
            String dnis = (String) deserializedParams.get('DNIS');
            String userId = (String) deserializedParams.get('USERID');
            String inContactId = (String) deserializedParams.get('CID'); 
            String skillName = (String) deserializedParams.get('SKILL');  
            String ani = (String) deserializedParams.get('ANI');
            Map<String, Object> newLeadMap = deserializedJSON.get('newLead') != null ? 
                (Map<String, Object>) deserializedJSON.get('newLead') : new Map<String, Object>();
            if (!newLeadMap.isEmpty()) {
                String newLeadJSON = (String)JSON.serialize(newLeadMap);
                newLead = (Lead) JSON.deserialize(newLeadJSON, Lead.class);   
            }
            /* populate rcAccount */
            Map<String, Object> rcAccountMap = deserializedJSON.get('rcAccount') != null ? 
                (Map<String, Object>) deserializedJSON.get('rcAccount') : new Map<String, Object>();
            if (rcAccountMap.isEmpty()) {
                rcAccount = null;
            } else {
                String rcAccountJSON = (String)JSON.serialize(rcAccountMap);
                rcAccount = (Account) JSON.deserialize(rcAccountJSON, Account.class);
            }
            
            Contact cont = (Contact) new ContactSelector()
            .selectContactByIdForMergeToContactInLeadSearchExtension(new Object[]{contactId})
            .executeQuery()[0];

            if (leadSysSourceUrl.equalsIgnoreCase('drift')) {
                cont.FirstName = String.isBlank(newLead.FirstName) ? 
                    cont.FirstName :  newLead.FirstName;
                cont.LastName = String.isBlank(newLead.LastName) ? 
                    cont.LastName :  newLead.LastName;
                cont.Email = String.isBlank(newLead.Email) || !isValidEmail(newLead.Email) ? 
                    cont.Email :  newLead.Email;
                cont.Phone = String.isBlank(newLead.Phone) ?
                    cont.Phone :  newLead.Phone;
                cont.NumberOfEmployees__c = (String.isBlank(newLead.Employees_Override__c) 
                    || newLead.Employees_Override__c.equalsIgnoreCase('--None--')) ? 
                    cont.NumberOfEmployees__c :  newLead.Employees_Override__c;
                cont.LeadSource = 'Online Chat';
                cont.Lead_Entry_Source__c = 'RingBot Office';
                cont.RC_Visitor_ID__c = String.isNotBlank((String)deserializedParams.get('RCVID')) ? 
                    (String) deserializedParams.get('RCVID') : cont.RC_Visitor_ID__c;
                cont.Adobe_Target_Id__c = String.isNotBlank((String)deserializedParams.get('ATID')) ? 
                    (String) deserializedParams.get('ATID') : cont.Adobe_Target_Id__c;
                cont.Adobe_Target_Id_History__c = String.isNotBlank((String)deserializedParams.get('ATID_HISTORY')) ? 
                    (String) deserializedParams.get('ATID_HISTORY') : cont.Adobe_Target_Id_History__c;
                cont.AID__c = String.isNotBlank((String)deserializedParams.get('AID')) ? 
                    (String) deserializedParams.get('AID') : cont.AID__c;
                cont.PID__c = String.isNotBlank((String)deserializedParams.get('PID')) ? 
                    (String) deserializedParams.get('PID') : cont.PID__c;
                cont.GCLID__c = String.isNotBlank((String)deserializedParams.get('GCLID')) ? 
                    (String) deserializedParams.get('GCLID') : cont.GCLID__c;
                cont.ECID__c = String.isNotBlank((String)deserializedParams.get('ECID')) ? 
                    (String) deserializedParams.get('ECID') : cont.ECID__c;    
                String bmid = (String) deserializedParams.get('BMID');
                if (String.isNotBlank(bmid)) {
                    List<Campaign> campaigns = (List<Campaign>) new CampaignSelector()
                        .selectCampaignByBMID(new List<Object> {bmid})
                        .setLimit(1)
                        .executeQuery();
                    if (!campaigns.isEmpty()) {
                        cont.BMID__c = bmid;
                    }
                }
            } else {
                List<INVOCA_FOR_SF__Invoca_Call_Log__c> invocaRecordsList = String.isBlank(invocaTransactionId) ?
                    (List<INVOCA_FOR_SF__Invoca_Call_Log__c>)  new InvocaSelector()
                        .selectInvocaRecordByCallerId(ani)
                        .executeQuery() :
                    (List<INVOCA_FOR_SF__Invoca_Call_Log__c>) new InvocaSelector()
                        .selectInvocaRecordById(invocaTransactionId)
                        .executeQuery();

                invocaCallRecord = invocaRecordsList[0];

                cont = (Contact) assignInvocaValues(cont, invocaCallRecord, 'assignInvocaValuesToContact', rcAccount);
                cont = copyLeadToContactFields(newLead, cont);
            }
            cont = calculateContactStatus(cont);
            update cont;
        } catch (Exception e) {
            AuraHandledException ex = new AuraHandledException('ERROR ' + 
                LeadHelper.ERROR_MESSAGE_MERGE_TO_CONTACT_PROCESS + '\n' + e.getMessage());
            ex.setMessage('ERROR ' + 
                LeadHelper.ERROR_MESSAGE_MERGE_TO_CONTACT_PROCESS + '\n' + e.getMessage());
            throw ex;
        }
        ContactTriggerHelper.isMergeContact = false;
    }

    public static void populateRCAccount(Lead ld, String userIdFromUrl) {
        if (ld != null && String.isNotBlank(ld.User_Id__c)) {
            List<Account> accounts = (List<Account>) new AccountSelector()
                .selectAccountsByUserIds(new Object[]{new String[]{ld.User_Id__c}})
                .selectFields(new List<Schema.SObjectField>{
                    Account.Name,
                    Account.RC_User_Id__c,
                    Account.CreatedDate,
                    Account.RC_Account_Status__c,
                    /*Ultimate parent id population on lead*/
                    Account.Ultimate_Parent_Account_ID__c
                })
                .selectField('Recordtype.Name')
                .setLimit(1)
                .executeQuery();

            if (!accounts.isEmpty()) {
                rcAccount = accounts[0];
                ld.ZI_CDP_Account_Id__c = rcAccount.Id;
                /*Ultimate parent id population on lead*/
                ld.Ultimate_Parent_Account_ID__c = rcAccount.Ultimate_Parent_Account_ID__c;
            } else {
                populateRCAccountFromURL(ld, userIdFromUrl);
            }
        } else {
            populateRCAccountFromURL(ld, userIdFromUrl);
        }
    }
    @AuraEnabled
    public static void claimUnprotectedLeadOwnership(String leadId, String jsonParams) {
        Map<String, Object> deserializedJSON = (Map<String, Object>) JSON.deserializeUntyped(jsonParams); 
        /* URL Parameters */
        Map<String, Object> deserializedParams = (Map<String, Object>) deserializedJSON.get('params');
        deserializedParams = keysToUpper(deserializedParams);
        String leadSysSourceUrl = deserializedParams.get('SOURCE') != null ? (String) deserializedParams.get('SOURCE') : '';
        String invocaTransactionId = (String) deserializedParams.get('INVOCAID');
        String dnis = (String) deserializedParams.get('DNIS');
        String userId = (String) deserializedParams.get('USERID');
        
        Map<String, Object> newLeadMap = deserializedJSON.get('newLead') != null ? 
            (Map<String, Object>) deserializedJSON.get('newLead') : new Map<String, Object>();
        if (!newLeadMap.isEmpty()) {
            String newLeadJSON = (String) JSON.serialize(newLeadMap);
            newLead = (Lead) JSON.deserialize(newLeadJSON, Lead.class);   
        }

        /* populate rcAccount */
        Map<String, Object> rcAccountMap = deserializedJSON.get('rcAccount') != null ? 
            (Map<String, Object>) deserializedJSON.get('rcAccount') : new Map<String, Object>();
        if (rcAccountMap.isEmpty()) {
            rcAccount = null;
        } else {
            String rcAccountJSON = (String)JSON.serialize(rcAccountMap);
            rcAccount = (Account) JSON.deserialize(rcAccountJSON, Account.class);
        }
        /* populate campObj */
        Map<String, Object> campObjMap = deserializedJSON.get('campObj') != null ? 
            (Map<String, Object>) deserializedJSON.get('campObj') : new Map<String, Object>();
        if (campObjMap.isEmpty()) {
            campObj = new Campaign();
        } else {
            String campObjJSON = (String)JSON.serialize(campObjMap);
            campObj = (Campaign) JSON.deserialize(campObjJSON, Campaign.class);
        }
        String inboundChatParams = (String) deserializedJSON.get('chatParams');
        String campaignName = String.isBlank(campObj.Name) ? 'Campaign not found.' : campObj.Name;
        String phoneNumber = newLead.Phone;
        Campaign campObj;

        Boolean flagForDTRecordWithNullBMID = false;
        Lead leadToUpdate = (Lead) new LeadSelector()
            .selectLeadWithCampaignFields(new List<Object> {leadId})
            .executeQuery()
            .get(0);
        if (leadSysSourceUrl.equalsIgnoreCase(LeadHelper.INVOCA) ){
            InvocaSelector invocaSelectorInstance = new InvocaSelector();
            List<INVOCA_FOR_SF__Invoca_Call_Log__c> invocaRecordsList = new List<INVOCA_FOR_SF__Invoca_Call_Log__c>();
            if (String.isNotBlank(invocaTransactionId)) {
                invocaRecordsList = (List<INVOCA_FOR_SF__Invoca_Call_Log__c>) invocaSelectorInstance
                    .selectInvocaRecordById(invocaTransactionId)
                    .executeQuery();
            } else {
                invocaRecordsList = (List<INVOCA_FOR_SF__Invoca_Call_Log__c>) invocaSelectorInstance
                    .selectInvocaRecordByCallerId(phoneNumber)
                    .executeQuery();
            }
            invocaCallRecord = !invocaRecordsList.isEmpty()
                    ? invocaRecordsList[0]
                    : null;
            if (invocaCallRecord != null) {
                if (String.isNotBlank(invocaCallRecord.INVOCA_FOR_SF__Customer_Business_Object_Value_3__c)) {
                    campObj = getCampaignFromInvocaCall(invocaCallRecord);
                    if (String.isBlank(campObj.Id)) {
                        campObj = fetchCampaignByName(LeadHelper.CAMPAIGNBROKENATTRIBUTION);
                    }
                } else {
                    campObj = fetchCampaignByName(LeadHelper.CAMPAIGNINVOCAWALKON);
                    flagForDTRecordWithNullBMID = true;
                }
            } else {
                campObj = setCampaignByDNISOrderedByCreatedDate(dnis, leadSysSourceUrl);
            }
            if(String.isBlank(campObj.Id) ){
                AuraHandledException e = new AuraHandledException('ERROR ' + 
                    'Error taking ownership, campaign not found for InvocaId: '+ invocaTransactionId);
                e.setMessage('ERROR ' + 
                    'Error taking ownership, campaign not found for InvocaId: '+ invocaTransactionId);
                throw e;
            }

            List<CampaignMember> cms = (List<CampaignMember>) new CampaignMemberSelector()
                .selectCampaignMemberByLeadAndCampaignIds(new List<Object> {new List<Id> {leadToUpdate.Id}, new List<Id> {campObj.Id}})
                .executeQuery();
        
            if (cms.isEmpty()) {
                CampaignMember cm = new CampaignMember();
                cm.CampaignId = campObj.Id;
                cm.LeadId = leadToUpdate.Id;
                insert cm;
            }

            if (invocaCallRecord!= null) {
                leadToUpdate = (Lead) assignInvocaValues(leadToUpdate, invocaCallRecord, 'assignInvocaValues', rcAccount);
                populateRCAccount(leadToUpdate, userId);
            }

            leadToUpdate.OwnerId = UserInfo.getUserId();

            if (!flagForDTRecordWithNullBMID || (flagForDTRecordWithNullBMID && String.isBlank(leadToUpdate.BMID__c))) {
                leadToUpdate.Most_Recent_Campaign__c = campObj.Id;
                leadToUpdate.Primary_Campaign__c = campObj.Id;
            }

            if (String.IsNotBlank(dnis)) {
                leadToUpdate.Five9_DNIS__c = dnis;
            }
            update leadToUpdate;
        } else if (String.isNotBlank(dnis) && newLead.LeadSource == 'Inbound Call') {
            List<Campaign> campaigns = (List<Campaign>) new CampaignSelector()
                .selectCampaignByDNIS(new List<Object> {dnis})
                .executeQuery();

            if (campaigns.isEmpty()) {
                AuraHandledException e = new AuraHandledException('ERROR ' +'Error taking ownership, campaign not found for dnis:' + dnis);
                e.setMessage('ERROR ' + 'Error taking ownership, campaign not found for dnis:' + dnis);
                throw e;
            }

            Campaign cmp = campaigns.get(0);
            leadToUpdate.Five9_DNIS__c = cmp.DNIS__c;
            leadToUpdate.AID__c = cmp.AID__c;
            leadToUpdate.BMID__c = cmp.BMID__c;
            leadToUpdate.PID__c = cmp.PID__c;
            leadToUpdate.Most_Recent_Campaign__c = cmp.Id;
            leadToUpdate.LeadSource = 'Inbound Call';
            leadToUpdate.OwnerId = UserInfo.getUserId();

            List<CampaignMember> cms = (List<CampaignMember>) new CampaignMemberSelector()
                .selectCampaignMemberByLeadAndCampaignIds(new List<Object> {new List<Id> {leadToUpdate.Id},new List<Id> {cmp.Id}})
                .executeQuery();
            if (cms.isEmpty()) {
                CampaignMember cm = new CampaignMember();
                cm.CampaignId = cmp.Id;
                cm.LeadId = leadToUpdate.Id;
                insert cm;
            }

            update leadToUpdate;
        } else {
            AuraHandledException e = new AuraHandledException('ERROR ' + 'Error taking ownership, not applicable: LeadSource:' 
            + newLead.LeadSource + ' ,dnis:' + dnis + ' ,leadId:' + leadId);
            e.setMessage('ERROR ' + 'Error taking ownership, not applicable: LeadSource:' + newLead.LeadSource +
            ' ,dnis:' + dnis + ' ,leadId:' + leadId);
            throw e;
        }
    }
    

    public static void populateBMIDValueOnLead(String leadSysSourceUrl, String strDnis, String strSalesgenerated){

        String strCustomlabel = System.label.Sales_Generated_Source;
        List<String> lstCustomlabel = strCustomlabel.split(';');

        for (String strBMIDValue : lstCustomlabel) {
            if (strSalesgenerated != NULL && (strBMIDValue.subString(0, strSalesgenerated.length())).equalsIgnoreCase(strSalesgenerated)) {
                newLead.BMID__c = strBMIDValue.subString(strSalesgenerated.length()+1,strBMIDValue.length());
                break;
            }

        }
        if (newlead.LeadSource == LeadHelper.CAMPAIGNSALESGENERATED
            && !String.isBlank(newLead.BMID__c)
            && !leadSysSourceUrl.equalsIgnoreCase(LeadHelper.INVOCA) 
            && !leadSysSourceUrl.equalsIgnoreCase('drift')){

            if (strDnis == null) {
                List <Campaign> campaignList = (List<Campaign>) new CampaignSelector()
                    .selectActiveCampaignByBMID(new List<Object> {newLead.BMID__c})
                    .executeQuery();
                if (campaignList != null && !campaignList.isEmpty()) {
                    campObj = campaignList[0];
                } else {
                    campObj = fetchCampaignByName(LeadHelper.CAMPAIGNBROKENATTRIBUTION);
                }
            }
        }
        if (campObj != null) {
            newLead.Primary_Campaign__c = campObj.Id;
        }
    }
    
    public static Boolean checkLeadQualificationNotEmpty(Boolean verifyOnlyNextSteps) {
        Boolean result = true;
        if (verifyOnlyNextSteps == false) {
            result &= String.IsNotBlank(leadQualificationObj.Current_Situation__c);
            result &= String.IsNotBlank(leadQualificationObj.Problems__c);
            result &= String.IsNotBlank(leadQualificationObj.Decision_Making_Process__c);
        }
        result &= String.IsNotBlank(leadQualificationObj.NextSteps__c);

        if (!result) {
            AuraHandledException e = new AuraHandledException('ERROR One of the required(*) fields has not been filled in.');
            e.setMessage('ERROR One of the required(*) fields has not been filled in.');
            throw e;
        }
        return result;
    }

    public static Boolean getIsSalesManagerInsideProfile() {
        String currentUserProfileId = currentUser.Profile.Id;
        return currentUserProfileId == getSalesManagerProfileId();
    }

    public static Boolean getIsSaleAgentInsideProfile() {
        String currentUserProfileId = currentUser.Profile.Id;
        return currentUserProfileId == getSalesAgentProfileId();
    }

    public static String checkInputFieldLength() {
        if (leadQualificationObj.Current_Situation__c != null && leadQualificationObj.Current_Situation__c != ''
                && ((leadQualificationObj.Current_Situation__c).length() > 32000)) {
            return 'CurrentSituation';
        }
        if (leadQualificationObj.Benefits__c != null && leadQualificationObj.Benefits__c != '' &&
            ((leadQualificationObj.Benefits__c).length() > 32000)) {
            return 'Benefits';
        }
        if (leadQualificationObj.Problems__c != null && leadQualificationObj.Problems__c != '' &&
                    ((leadQualificationObj.Problems__c).length() > 32000)) {
            return 'Problems';
        }
        if (leadQualificationObj.Decision_Making_Process__c != null && leadQualificationObj.Decision_Making_Process__c != '' &&
                ((leadQualificationObj.Decision_Making_Process__c).length() > 32000)) {
            return 'DecisionMaking';
        }
        if (leadQualificationObj.Impact__c != null && leadQualificationObj.Impact__c != ''
            && ((leadQualificationObj.Impact__c).length() > 32000)) {
            return 'Impact';
        }
        if(leadQualificationObj.Competitive_Landscape__c != null 
            && leadQualificationObj.Competitive_Landscape__c != '' && 
                ((leadQualificationObj.Competitive_Landscape__c).length() > 32000)) {
            return 'CompetitiveLandscape';
        }
        if(leadQualificationObj.Ideal_Situation__c != null && leadQualificationObj.Ideal_Situation__c != ''
            && ((leadQualificationObj.Ideal_Situation__c).length() > 32000)) {
            return 'IdealSituation';
        }
        if(leadQualificationObj.Relationship_Building_Extras__c != null 
            && leadQualificationObj.Relationship_Building_Extras__c != '' &&
            ((leadQualificationObj.Relationship_Building_Extras__c).length() > 32000)) {
            return 'RelationshipBuilding';
        }
        if(leadQualificationObj.NextSteps__c != null && leadQualificationObj.NextSteps__c != ''
                && ((leadQualificationObj.NextSteps__c).length() > 32000)) {
            return 'NextSteps';
        }
        if(leadQualificationObj.CoachingNotes__c != null && leadQualificationObj.CoachingNotes__c != ''
                && ((leadQualificationObj.CoachingNotes__c).length() > 32000)) {
            return 'CoachingNotes';
        }
        if(leadQualificationObj.ContractAdditionalInfo__c != null 
            && leadQualificationObj.ContractAdditionalInfo__c != '' &&
            ((leadQualificationObj.ContractAdditionalInfo__c).length() > 32000)) {
            return 'ContractAdditionalInfo';
        }
        if(leadQualificationObj.Decision_makers_Additional_Information__c != null 
            && leadQualificationObj.Decision_makers_Additional_Information__c != '' &&
            ((leadQualificationObj.Decision_makers_Additional_Information__c).length() > 32000)) {
            return 'DecisionMakersAdditionalInfo';
        }
        if(leadQualificationObj.TimeframeAdditionalInfo__c != null && leadQualificationObj.TimeframeAdditionalInfo__c != '' &&
            ((leadQualificationObj.TimeframeAdditionalInfo__c).length() > 32000)) {
            return 'TimeFrameAdditionalInfo';
        }
        return 'NoError';
    }

    @AuraEnabled
    public static String createNew(String jsonParams){
        Map<String, Object> deserializedJSON = (Map<String, Object>) JSON.deserializeUntyped(jsonParams); 
        /* URL Parameters */
        Map<String, Object> deserializedParams = (Map<String, Object>) deserializedJSON.get('params');
        deserializedParams = keysToUpper(deserializedParams);
        String leadSysSourceUrl = deserializedParams.get('SOURCE') != null ? (String) deserializedParams.get('SOURCE') : '';
        String invocaTransactionId = (String) deserializedParams.get('INVOCAID');
        String dnis = (String) deserializedParams.get('DNIS');
        String userId = (String) deserializedParams.get('USERID');
        String ani  = (String) deserializedParams.get('ANI');
        
        Map<String, Object> newLeadMap = deserializedJSON.get('newLead') != null ? (Map<String, Object>) deserializedJSON.get('newLead') : new Map<String, Object>();
        if (!newLeadMap.isEmpty()) {
            String newLeadJSON = (String) JSON.serialize(newLeadMap);
            newLead = (Lead) JSON.deserialize(newLeadJSON, Lead.class);   
        }

        /* populate rcAccount */
        Map<String, Object> rcAccountMap = deserializedJSON.get('rcAccount') != null ? (Map<String, Object>) deserializedJSON.get('rcAccount') : new Map<String, Object>();
        if (rcAccountMap.isEmpty()) {
            rcAccount = null;
        } else {
            String rcAccountJSON = (String)JSON.serialize(rcAccountMap);
            rcAccount = (Account) JSON.deserialize(rcAccountJSON, Account.class);
        }
        /*Populate leadQualification*/
        Map<String, Object> leadQualificationObjMap = deserializedJSON.get('leadQualificationObj') != null ? (Map<String, Object>) deserializedJSON.get('leadQualificationObj') : new Map<String, Object>();
        if (leadQualificationObjMap.isEmpty()) {
            leadQualificationObj = new Lead_Qualification__c();
        } else {
            String leadQualificationObjJSON = (String)JSON.serialize(leadQualificationObjMap);
            leadQualificationObj = (Lead_Qualification__c) JSON.deserialize(leadQualificationObjJSON, Lead_Qualification__c.class);
        }

        String strSalesgenerated = (String) deserializedJSON.get('salesGeneratedStr') != '' 
            ? (String) deserializedJSON.get('salesGeneratedStr') : null; 
        Boolean searched = (Boolean) deserializedJSON.get('searched');
        String searchedem = (String) deserializedJSON.get('searchedem');
        String searchedph = (String) deserializedJSON.get('searchedph');
        String searchedcomp = (String) deserializedJSON.get('searchedcomp');
        String searchedfirst = (String) deserializedJSON.get('searchedfirst');
        String searchedlast = (String) deserializedJSON.get('searchedlast');
        String searchedLeadSource = (String) deserializedJSON.get('searchedLeadSource');
        List<User> currentUsers = new UserSelector()
            .selectCurrentUserForSettingsService()
            .executeQuery();
        if (!currentUsers.isEmpty()) {
            currentUser = currentUsers[0];
        }

        Boolean emptyField = false;
        Boolean isSalesAgent = getIsSaleAgentInsideProfile();

        if (!leadSysSourceUrl.equalsIgnoreCase(LeadHelper.INVOCA)
            && !leadSysSourceUrl.equalsIgnoreCase('drift')) {
            populateBMIDValueOnLead(leadSysSourceUrl, dnis, strSalesgenerated);
        }
        if (getIsSalesManagerInsideProfile() || isSalesAgent)  {
            try {
                checkLeadQualificationNotEmpty(isSalesAgent);
            } catch(Exception e) {
                AuraHandledException ex = new AuraHandledException(e.getMessage());
                ex.setMessage(e.getMessage());
                throw ex;
            }
        }

        if ((newlead.LeadSource == LeadHelper.CAMPAIGNSALESGENERATED) && 
            (strSalesgenerated == null || String.isBlank(strSalesgenerated) || strSalesgenerated == 'None')) {
            AuraHandledException ex = new AuraHandledException('ERROR You must select Sales Generated Source.');
            ex.setMessage('ERROR You must select Sales Generated Source.');
            throw ex;
        }
        if (isEmpty(newLead.Email)
            || isEmpty(newLead.Company)
            || isEmpty(newLead.LastName)
            || isEmpty(newLead.LeadSource)
            || isEmpty(newLead.Employees_Override__c)
            || newLead.Employees_Override__c == '--None--'
            || isEmpty(newlead.Industry)) {
                AuraHandledException e = new AuraHandledException('ERROR Please fill all Last Name, Company Name, ' +
                'Email, Lead Source, No. of Employees (Range) and Industry to create a new lead.');
                e.setMessage('ERROR Please fill all Last Name, Company Name, ' +
                'Email, Lead Source, No. of Employees (Range) and Industry to create a new lead.');
                throw e;
        }
        /*************************************end************************************************************************/
        
        if (!isValidEmail(newLead.Email.trim())) {
            AuraHandledException e = new AuraHandledException('ERROR The email entered is not in a valid format.');
            e.setMessage('ERROR The email entered is not in a valid format.' );
                throw e;
        }

        
        if (String.isNotBlank(newLead.Website) && !LeadHelper.isValidWebsite(newLead.Website.trim())) {
            AuraHandledException e = new AuraHandledException('ERROR ' + System.Label.Invalid_Website_Error);
            e.setMessage('ERROR ' + System.Label.Invalid_Website_Error);
            throw e;
        }
        /*Check for SolveThenSell if dnis is coming in URL*/
        if (dnis == '8775843307' && isEmpty(newLead.Agent_Email_Address__c)) {
            String myMsg = 'INFO  Support Agent Email Address is required when a call ' + 
            'is transferred into this phone #=8775843307.';
            AuraHandledException e = new AuraHandledException(myMsg);
            e.setMessage(myMsg);
            throw e;
        }

        emptyField = false;
        if (searched != true) {
            String myMsg = 'ERROR You must search with valid inputs first before creating a new lead.';
            AuraHandledException e = new AuraHandledException(myMsg);
            e.setMessage(myMsg);
            throw e;
        }

        if (newLead.Email.trim() != searchedem.trim()
                || newLead.Phone.trim() != searchedph.trim()
                || newLead.Company.trim() != searchedcomp.trim()
                || newLead.FirstName.trim() != searchedfirst.trim()
                || newLead.LastName.trim() != searchedlast.trim()
                || newLead.LeadSource.trim() != searchedLeadSource.trim()) {
            String myMsg = 'INFO  You must search again as fields have changed after your previous search attempt.';
            AuraHandledException e = new AuraHandledException(myMsg);
            e.setMessage(myMsg);
            throw e;
        }

        String errorMsg = checkInputFieldLength();

        if(errorMsg != null && errorMsg != 'NoError') {
            String myMsg;
            if (errorMsg == 'CurrentSituation') {
                myMsg = 'ERROR ' +'Please enter only upto 32000 characters on Current Situation Information.';
            } else if (errorMsg == 'Benefits') {
                myMsg = 'ERROR ' +'Please enter only upto 32000 characters on Benefits Information.';
            } else if (errorMsg == 'Problems') {
                 myMsg = 'ERROR ' +'Please enter only upto 32000 characters on Problems Information.';
            } else if (errorMsg == 'DecisionMaking') {
                myMsg = 'ERROR ' +'Please enter only upto 32000 characters on Decision Making Information.';
            } else if (errorMsg == 'Impact') {
                myMsg = 'ERROR ' +'Please enter only upto 32000 characters on Impact Information.';
            } else if (errorMsg == 'CompetitiveLandscape') {
                myMsg = 'ERROR ' +'Please enter only upto 32000 characters on Competitive Landscape Information.';
            } else if (errorMsg == 'IdealSituation') {
                myMsg = 'ERROR ' +'Please enter only upto 32000 characters on Ideal Situation Information.';
            } else if (errorMsg == 'RelationshipBuilding') {
                myMsg = 'ERROR ' +'Please enter only upto 32000 characters on Relationship Building Extras Information.';
            } else if (errorMsg == 'NextSteps') {
                myMsg = 'ERROR ' +'Please enter only upto 32000 characters on Next Steps Information.';
            } else if (errorMsg == 'CoachingNotes') {
                myMsg = 'ERROR ' +'Please enter only upto 32000 characters on Coaching Notes Information.';
            } else if (errorMsg == 'ContractAdditionalInfo') {
                myMsg = 'ERROR ' +'Please enter only upto 32000 characters on Contract Additional Information.';
            } else if (errorMsg == 'DecisionMakersAdditionalInfo') {
                myMsg = 'ERROR ' +'Please enter only upto 32000 characters on Decision Makers Additional Information.';
            } else if (errorMsg == 'TimeFrameAdditionalInfo') {
                myMsg = 'ERROR ' +'Please enter only upto 32000 characters on Timeframe Additional Information.';
            }
            AuraHandledException e = new AuraHandledException(myMsg);
            e.setMessage(myMsg);
            throw e;
        }

        newLead.Lead_Score__c = 'A';
        newLead.ownerId = UserInfo.getUserId();
        newLead.Status = '2. Contacted';
        newLead.Time_Frame__c = leadQualificationObj.Timeframe__c;

        try {
            if (leadSysSourceUrl.equalsIgnoreCase(LeadHelper.INVOCA)) {
                /* scenario where Invoca record is created after the screenpop*/
                if (String.isBlank(invocaTransactionId)) {
                    Campaign doubleCheckCampaign = new Campaign();
                    InvocaSelector invocaSelectorInstance = new InvocaSelector();
                    List<INVOCA_FOR_SF__Invoca_Call_Log__c> invocaRecordsList = 
                    (List<INVOCA_FOR_SF__Invoca_Call_Log__c>) invocaSelectorInstance
                        .selectInvocaRecordByCallerId(ani)
                        .executeQuery();
                    invocaCallRecord = !invocaRecordsList.isEmpty()
                        ? invocaRecordsList[0]
                        : null;
                    if (invocaCallRecord != null) {
                        /* this is almost the same as the constructor logic, as an improvemente move it to a method*/
                        newLead = (Lead) assignInvocaValues(newLead, invocaCallRecord, 'assignInvocaValues', rcAccount);
                        populateRCAccount(newLead, userId);
                        if (String.isNotBlank(invocaCallRecord.INVOCA_FOR_SF__Customer_Business_Object_Value_3__c)) {
                            doubleCheckCampaign = getCampaignFromInvocaCall(invocaCallRecord);
                            if (doubleCheckCampaign.Id != null) {
                                campObj = doubleCheckCampaign;
                                newLead.Most_Recent_Campaign__c = campObj.Id;
                            } else {
                                campObj = fetchCampaignByName(LeadHelper.CAMPAIGNBROKENATTRIBUTION);
                                newLead.Most_Recent_Campaign__c = campObj.Id;
                            }
                        } else {
                            campObj = fetchCampaignByName(LeadHelper.CAMPAIGNINVOCAWALKON);
                            newLead.Most_Recent_Campaign__c = campObj.Id;
                        }
                    } else {
                        campObj = setCampaignByDNISOrderedByCreatedDate(dnis, leadSysSourceUrl);
                        newLead.Most_Recent_Campaign__c = campObj.Id;
                    }
                } else {
                    InvocaSelector invocaSelectorInstance = new InvocaSelector();
                    List<INVOCA_FOR_SF__Invoca_Call_Log__c> invocaRecordsList = 
                        (List<INVOCA_FOR_SF__Invoca_Call_Log__c>) invocaSelectorInstance
                            .selectInvocaRecordById(invocaTransactionId)
                            .executeQuery();
                    invocaCallRecord = !invocaRecordsList.isEmpty()
                        ? invocaRecordsList[0]
                        : null;
                }
            }
            String phoneNumber;
            if (leadSysSourceUrl.equalsIgnoreCase(LeadHelper.INVOCA) && invocaCallRecord != null) {
                phoneNumber = String.isBlank(invocaCallRecord.INVOCA_FOR_SF__calling_phone_number__c) ?
                            null : invocaCallRecord.INVOCA_FOR_SF__calling_phone_number__c;
            }
            newLead.Phone = phoneNumber != null ? phoneNumber : newLead.Phone;
            newLead.Five9_DNIS__c = String.isNotBlank(dnis) ? dnis : newLead.Five9_DNIS__c;
            if (campObj != null && String.isNotBlank(campObj.Id)) {
                newLead.Primary_Campaign__c = campObj.Id;
            }
            newLead.Lead_Created_via_Smart_Search__c = true;
            insert newLead;
            CompanyProcessorSvc leadCompanyProcessorSvcInstance = new LeadCompanyProcessorSvc();
            leadCompanyProcessorSvcInstance.processAccountHierarchy(new List<Lead> {newLead}, null);
            if (invocaCallRecord != null) {
                invocaCallRecord.INVOCA_FOR_SF__Lead__c = newLead.Id;
                update invocaCallRecord;
            }
        } catch(Exception e) {
            AuraHandledException ex = new AuraHandledException('Exception on Lead Insert '+e.getMessage()
            +'='+e.getLineNumber());
            ex.setMessage('Exception on Lead Insert '+e.getMessage()
            +'='+e.getLineNumber());
            throw ex;
        }
        try {
            leadQualificationObj.lead__c = newLead.Id;
            insert leadQualificationObj;
        } catch(Exception ex) {    
            String myMsg = 'ERROR the STC record could not be created due to error ocurred!';
            AuraHandledException e = new AuraHandledException(myMsg);
            e.setMessage(myMsg);
            throw e;
        }
        return newLead.id;
    }

    @AuraEnabled
    public static void mergeToLead(String leadToUpdateId, String jsonParams, Boolean takeOwnership){
        try {
            Map<String, Object> deserializedJSON = (Map<String, Object>) JSON.deserializeUntyped(jsonParams); 
            /* URL Parameters */
            Map<String, Object> deserializedParams = (Map<String, Object>) deserializedJSON.get('params');
            deserializedParams = keysToUpper(deserializedParams);
            
            Map<String, Object> newLeadMap = deserializedJSON.get('newLead') != null ?
                (Map<String, Object>) deserializedJSON.get('newLead') : new Map<String, Object>();
            if (!newLeadMap.isEmpty()) {
                String newLeadJSON = (String) JSON.serialize(newLeadMap);
                newLead = (Lead) JSON.deserialize(newLeadJSON, Lead.class);   
            }

            Lead leadToUpdate = (Lead) new LeadSelector()
                .selectLeadWithCampaignFields(new List<Object> {leadToUpdateId})
                .executeQuery()
                .get(0);
            leadToUpdate.FirstName = String.isBlank(newLead.FirstName) ? leadToUpdate.FirstName :  newLead.FirstName;
            leadToUpdate.LastName = String.isBlank(newLead.LastName) ? leadToUpdate.LastName :  newLead.LastName;
            leadToUpdate.Email = String.isBlank(newLead.Email) || !isValidEmail(newLead.Email) ? 
                leadToUpdate.Email :  newLead.Email;
            leadToUpdate.Phone = String.isBlank(newLead.Phone) ? leadToUpdate.Phone :  newLead.Phone;
            leadToUpdate.Employees_Override__c = String.isBlank(newLead.Employees_Override__c) ?
                leadToUpdate.Employees_Override__c :  newLead.Employees_Override__c;
            leadToUpdate.LeadSource = 'Online Chat';
            leadToUpdate.Lead_Entry_Source__c = 'RingBot Office';
            leadToUpdate.RC_Visitor_ID__c = String.isNotBlank((String)deserializedParams.get('RCVID')) ? 
                (String) deserializedParams.get('RCVID') : leadToUpdate.RC_Visitor_ID__c;
            leadToUpdate.Adobe_Target_Id__c = String.isNotBlank((String)deserializedParams.get('ATID')) ? 
                (String) deserializedParams.get('ATID') : leadToUpdate.Adobe_Target_Id__c;
            leadToUpdate.Adobe_Target_Id_History__c = String.isNotBlank((String)deserializedParams.get('ATID_HISTORY')) ?
                (String) deserializedParams.get('ATID_HISTORY') : leadToUpdate.Adobe_Target_Id_History__c;
            leadToUpdate.AID__c = String.isNotBlank((String)deserializedParams.get('AID')) ? 
                (String) deserializedParams.get('AID') : leadToUpdate.AID__c;
            leadToUpdate.PID__c = String.isNotBlank((String)deserializedParams.get('PID')) ? 
                (String) deserializedParams.get('PID') : leadToUpdate.PID__c;
            leadToUpdate.KCID__c = String.isNotBlank((String)deserializedParams.get('KCID')) ? 
                (String) deserializedParams.get('KCID') : leadToUpdate.KCID__c;
            leadToUpdate.GCLID__c = String.isNotBlank((String)deserializedParams.get('GCLID')) ? 
                (String) deserializedParams.get('GCLID') : leadToUpdate.GCLID__c;
            leadToUpdate.ECID__c = String.isNotBlank((String)deserializedParams.get('ECID')) ? 
                (String) deserializedParams.get('ECID') : leadToUpdate.ECID__c;
            String bmid = (String) deserializedParams.get('BMID');
            if (String.isNotBlank(bmid)) {
                List<Campaign> campaigns = (List<Campaign>) new CampaignSelector()
                    .selectCampaignByBMID(new List<Object> {bmid})
                    .setLimit(1)
                    .executeQuery();
                if (!campaigns.isEmpty()) {
                    leadToUpdate.BMID__c = bmid;
                }
            }
            leadToUpdate.OwnerId = takeOwnership ? UserInfo.getUserId() : leadToUpdate.OwnerId;
            update leadToUpdate;
        } catch (Exception e) {
            AuraHandledException ex = new AuraHandledException(e.getMessage());
            ex.setMessage(e.getMessage());
            throw ex;
        }
    }

    public class ListResult implements Comparable {
        @AuraEnabled 
        public String name {get; set;}
        @AuraEnabled 
        public String email {get; set;}
        @AuraEnabled 
        public String phone {get; set;}
        @AuraEnabled 
        public String company {get; set;}
        @AuraEnabled 
        public String stage {get; set;}
        @AuraEnabled  
        public String dateCreated {get; set;}
        @AuraEnabled 
        public String dateModified {get; set;}
        @AuraEnabled 
        public String ownerName {get; set;}
        @AuraEnabled 
        public String id {get; set;}
        @AuraEnabled 
        public String ownerId {get;set;}
        @AuraEnabled 
        public String dnis {get; set;}
        @AuraEnabled 
        public String companySize {get; set;}
        @AuraEnabled 
        public String companyName {get; set;}
        @AuraEnabled 
        public String accountName {get; set;}
        @AuraEnabled 
        public String accountRecordType {get; set;} /*CMR-221256 : Add account record type to smart search*/
        @AuraEnabled 
        public String closedDate {get; set;}
        @AuraEnabled 
        public String companyGrade {get; set;}
        @AuraEnabled 
        public String leadSource {get; set;}
        @AuraEnabled     
        public Integer modifiedYear {get; set;}
        @AuraEnabled     
        public Integer modifiedMonth {get; set;}
        @AuraEnabled     
        public Integer modifiedDay {get; set;}
        @AuraEnabled
        public String urlToRedirect;

        public ListResult(String contact, String email, String phone, String company, String stage, DateTime created,
            DateTime modified, String owner, String id, String ownerId, String dnis,
            String companySize, String companyName, String accountName, DateTime closedDate, String companyGrade,
             String leadSource, String accountRecordType, String urlToRedirect) {/*CMR-221256*/
            this.modifiedYear = (modified == null ? (Datetime.now()).year() : modified.year());
            this.modifiedMonth = (modified == null ? (Datetime.now()).month() : modified.month());
            this.modifiedDay = (modified == null ? (Datetime.now()).day() : modified.day());
            this.name = contact;
            this.email = email;
            this.phone = phone;
            this.company = company;
            this.stage = stage;
            this.dateCreated = (created == null ?  Datetime.now().format(US_DATE_FORMAT, USER_LOCALE) : created.format(US_DATE_FORMAT, USER_LOCALE));
            this.dateModified = (modified == null ? Datetime.now().format(US_DATE_FORMAT, USER_LOCALE) : modified.format(US_DATE_FORMAT, USER_LOCALE));
            this.ownerName = owner;
            this.id = id;
            this.ownerId = ownerId;
            this.dnis = dnis;
            this.companySize = companySize;
            this.companyName = companyName;
            this.accountName = accountName;
            this.accountRecordType = accountRecordType; /*CMR-221256 : Add account record type to smart search*/
            this.closedDate = (closedDate == null ? '' : closedDate.format(US_DATE_FORMAT));
            this.companyGrade = companyGrade;
            this.leadSource = leadSource;
            this.urlToRedirect = urlToRedirect;
        }

        public Integer compareTo(Object compareTo) {
            ListResult compareToOppy = (ListResult) compareTo;
            Integer returnValue = 0;
            Date dateModif;
            Date dateToCompare;
            dateModif =  Date.valueOf(this.modifiedYear + '-' + this.modifiedMonth + '-' + this.modifiedDay);
            dateToCompare =  Date.valueOf(compareToOppy.modifiedYear + '-' + compareToOppy.modifiedMonth + '-' + compareToOppy.modifiedDay);
            if (dateModif < dateToCompare) {
                returnValue = 1;
            } else if (dateModif > dateToCompare) {
                returnValue = -1;
            }
            return returnValue;
        }
    }
}