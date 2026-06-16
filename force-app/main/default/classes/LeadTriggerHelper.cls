/*
  This is a Helper Class which is used for following purposes :
    UDPATE LEAD ACTIVE DATE BASED ON OWNER AND STATUS
    Check LeadName Custom Setting for Test Leads
    Returns List of LARs
    Returns Map of Skills corresponding to its User List
    Return Account Maps if Lead is SOLVE THEN SELL
    Return Number OF Employee Picklist Values of Lead
    Returns Employee Size Map
    ASSIGN LEAD SOURCE BASED ON CONDITIONS
    Return USER SKILL List Based on LEAD ENTRY SOURCE from LARs
    Return USER SKILL List Based on CAMPAIGN from LARs
    Return USER SKILL List Based on LEAD SOURCE from LARs
    Assign Lead owner and update Skill Counter Based on Skill found by LARs
    Format Phone Number as per New Format Logic
    Update Lead Owner Manager Fields
    UPDATE ULIMATE PARTNER ACCOUNT INTO LEAD ON 2567INSERT-UPDATE
    Returns map of Approved Brand List based on Account PartnerId
    Check Partner Lead Permitted By Brand
    UPDATE Partner_Account_Current_Owner_Email__c Field of Lead
    Update Most Recent Campaign on Lead
    Assign Brand UK if Owner Role contains UK
*/

public class LeadTriggerHelper {

    /**************************************************STATIC VARIABLE DECLARATION*********************************************************/
    public static final Id RCSF_SYNC = Id.valueOf(HardcodedIdsMapper.getMatchedObjectId('005800000036sJJ'));
    public static final Id PARTNER_LEAD_RECORD_TYPE = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Partner Leads').getRecordTypeId();
    public static final Set<String> LEAD_STATUSES_TO_SKIP_UPDATE_SYSTEM_USER_MODIFIED_DATA_FIELD = new Set<String>{
        '0. Downgraded'
    };
    public static final Map<Id, String> PROFILE_TO_SKIP_UPDATE_SYSTEM_USER_MODIFIED_DATA_FIELD = new Map<Id, String>{
        Id.valueOf(HardcodedIdsMapper.getMatchedObjectId('00e80000000l1hKAAQ')) => 'System Administrator'
    };
    public static final Map<Id, String> USERS_TO_SKIP_UPDATE_SYSTEM_USER_MODIFIED_DATA_FIELD = new Map<Id, String>{
        Id.valueOf(HardcodedIdsMapper.getMatchedObjectId('00580000003to4F')) => 'User Marketo',
        Id.valueOf(HardcodedIdsMapper.getMatchedObjectId('005800000086myw')) => 'BT API User'
    };
    public static Boolean triggerToByPassConvertLead = false;
    public static Boolean isRealUser = false;
    public static final Set<String> sales_Generated_Source_Types = new Set<String>{
        'Inbound Chat', 'Inbound Call', 'Sales Generated'
    };
    public static Boolean canUpdateActiveDate = false;
    public static Map<String, Boolean> invalidStatusMap = new Map<String, Boolean>{
        '0. Downgraded' => true, 'X. Open' => true, 'X. Suspect' => true
    };
    private static final String BT_BUSINESS;
    public static final Feature_Toggle__c featureToggle = Feature_Toggle__c.getInstance();

    public static final String LEADSTATUSOPEN = 'X. Open';
    public static final String LEADSTATUSSUSPECT = 'X. Suspect';
    public static final String LEADSTATUSDOWNGRADED = '0. Downgraded';
    public static final String LEADSTATUSRENEW = '.5 Re-New';
    public static final String LEADSTATUSCALLOUT = '1.5 Call Out';
    public static final String LEADSTATUSNEW = '1. New';
    public static final String LEADSTATUSCONTACTED = '2. Contacted';

    public static final String ROUTINGREASONNETNEWLEAD = '[Trigger] Net New Lead Assigned to LeanData';
    public static final String ROUTINGREASONINACTIVEOWNER = '[Trigger] Existing Lead Reassigned to LeanData via Inactive Owner Code';
    public static final String PREROUTINGREASONNETNEWLEAD = '[PreRouting] Lead Queued for LeanData via New Lead Code';
    public static final String PREROUTINGREASONINACTIVEOWNER = '[PreRouting] Lead Queued for LeanData via Inactive Owner Code';

    public static final LeadRoutingSettings__c leadRoutingSettings = LeadRoutingSettings__c.getOrgDefaults();

    public static Set<Id> LeadsToBeDeleted { get; set; }
    public static Boolean skipLeadTriggerOnUpdateFromCompanyPersonBatch = false;

    static {
        if (!Test.isRunningTest()) {
            BT_BUSINESS = RcDealHealper.getBTBrand();
        } else {
            BT_BUSINESS = 'BT Business';
        }
    }
    public static void byPassTrgrsAtConvertLead() {
        triggerToByPassConvertLead = true;
    }
    public static String PARTNER_CAMPAIGN_NAME = 'Partner Lead Campaign';
      private static final SObjectCache LOCAL_CACHE = new SObjectCache();
      public static SObjectCache.ICacheStorage USER_CACHE;
      static {
          if (Trigger.isExecuting) {
              USER_CACHE = (SObjectCache.UserCacheStorage) Triggers.getCacheStorage(User.getSObjectType());
          } else {
              LOCAL_CACHE.addStorage(new SObjectCache.UserCacheStorage()).initStorage();
              USER_CACHE = LOCAL_CACHE.getStorage(User.getSObjectType());
          }
      }

    public static final String SAASQUATCH_DEFAULT_PROGRAM = 'US and Canada Referral Program (external)';
    /**************************************************************************************************************************************/

    /**********************************UDPATE LEAD ACTIVE DATE BASED ON OWNER AND STATUS****************************************************/
    public static void updateLeadActiveDate(List<Lead> newLeadList, Map<Id, Lead> leadOldMap) {
        try {
            map<string, string> mapCSProtectionLeadUser = new map<string, string>();
            for (ProtectionLeadUsers__c csObj : ProtectionLeadUsers__c.getAll().values()) {
                if (csObj.UserId__c.length() > 15) {
                    mapCSProtectionLeadUser.put(csObj.UserId__c.subString(0, 15), csObj.UserId__c.subString(0, 15));
                } else {
                    mapCSProtectionLeadUser.put(csObj.UserId__c, csObj.UserId__c);
                }
            }

            for (Lead newLeadObj : newLeadList) {
                Lead oldLeadObj = leadOldMap != null ? leadOldMap.get(newLeadObj.id) : null;
                isRealUser = false;
                canUpdateActiveDate = false;
                String ownerId18Dig = newLeadObj.OwnerId;
                String ownerId15Dig = '';
                if (ownerId18Dig != '' && ownerId18Dig.length() > 15) {
                    ownerId15Dig = ownerId18Dig.subString(0, 15);
                }
                if (mapCSProtectionLeadUser != null && mapCSProtectionLeadUser.get(ownerId15Dig) == null) {
                    isRealUser = true;
                }
                Boolean invalidNewStatus = (invalidStatusMap.get(newLeadObj.status) == null ? false : true);
                Boolean invalidOldStatus = (oldLeadObj != null && invalidStatusMap.get(oldLeadObj.status) == null ? false : true);
                Boolean isOwnerChanged = (oldLeadObj == null || oldLeadObj.ownerId == newLeadObj.ownerId) ? false : true;

                String newStatus = newLeadObj.status;
                String oldStatus = (oldLeadObj == null ? null : oldLeadObj.status);

                if (oldLeadObj == null) { // Insert
                    if (!isRealUser && !invalidNewStatus) { // Owner [System User] and Status [Valid]
                        canUpdateActiveDate = false;
                    } else if (!isRealUser && invalidNewStatus) { // Owner [System User] and Status [Invalid]
                        canUpdateActiveDate = false;
                    } else if (isRealUser && !invalidNewStatus) { // Owner [Real User] and Status [Valid]
                        canUpdateActiveDate = true;
                    } else if (isRealUser && invalidNewStatus) { // Owner [Real User] and Status [Invalid]
                        canUpdateActiveDate = false;
                    }
                } else { // Update
                    if (isRealUser && !isOwnerChanged && !invalidOldStatus && !invalidNewStatus && (newStatus != oldStatus)) {// Owner Unchanged [Real User] and Status Changed [Valid -> Valid]
                        canUpdateActiveDate = false;
                    } else if (isRealUser && isOwnerChanged && !invalidOldStatus && !invalidNewStatus && (newStatus != oldStatus)) {// Owner Changed [Real to Real] and Status Changed [Valid -> Valid]
                        canUpdateActiveDate = true;
                    } else if (isRealUser && !isOwnerChanged && !invalidNewStatus && (newStatus == oldStatus)) {//Owner Changed [Real to Real] and Status Unchanged [Valid]
                        canUpdateActiveDate = true;
                    } else if (!isRealUser && !isOwnerChanged && invalidOldStatus && !invalidNewStatus) { // Owner Unchanged [System User] and Status Changed [InValid -> Valid]
                        canUpdateActiveDate = false;
                    } else if (!isRealUser && !isOwnerChanged && invalidOldStatus && invalidNewStatus) { // Owner Unchanged [System User] and Status Changed [InValid -> Invalid]
                        canUpdateActiveDate = false;
                    } else if (!isRealUser && !isOwnerChanged && !invalidOldStatus && invalidNewStatus) { // Owner Unchanged [System User] and Status Changed [Valid -> InValid]
                        canUpdateActiveDate = false;
                    } else if (!isRealUser && !isOwnerChanged && !invalidOldStatus && !invalidNewStatus) {// Owner Unchanged [System User] and Status Changed [Valid -> Valid]
                        canUpdateActiveDate = false;
                    } else if (isRealUser && isOwnerChanged && invalidNewStatus && (newStatus == oldStatus)) {// Owner Changed [Real User] and Status Unchanged [InValid]
                        canUpdateActiveDate = false;
                    } else if (isRealUser && isOwnerChanged && !invalidNewStatus && (newStatus == oldStatus)) {// Owner Changed [Real User] and Status Unchanged [Valid]
                        canUpdateActiveDate = true;
                    } else if (isRealUser && isOwnerChanged && !invalidNewStatus && invalidOldStatus
                        && (newStatus != oldStatus)) {// Owner Changed [Real User] and Status Changed [InValid -> Valid]
                        canUpdateActiveDate = true;
                    } else if (isRealUser && isOwnerChanged && invalidNewStatus && invalidOldStatus
                        && (newStatus != oldStatus)) {// Owner Changed [Real User] and Status Changed [Invalid -> InValid]
                        canUpdateActiveDate = false;
                    } else if (isRealUser && isOwnerChanged && invalidNewStatus && !invalidOldStatus
                        && (newStatus != oldStatus)) {// Owner Changed [Real User] and Status Changed [Valid -> InValid]
                        canUpdateActiveDate = false;
                    } else if (isRealUser && isOwnerChanged && !invalidNewStatus && !invalidOldStatus
                        && (newStatus != oldStatus)) {// Owner Changed [Real User] and Status Changed [Valid -> Valid]
                        canUpdateActiveDate = true;
                    } else if (!isRealUser && isOwnerChanged && invalidNewStatus && !invalidOldStatus
                        && (newStatus != oldStatus)) {// Owner Changed [System User] and Status Changed [Valid -> InValid]
                        canUpdateActiveDate = false;
                    } else if (!isRealUser && isOwnerChanged && !invalidNewStatus && invalidOldStatus
                        && (newStatus != oldStatus)) {// Owner Changed [System User] and Status Changed [InValid -> Valid]
                        canUpdateActiveDate = false;
                    } else if (!isOwnerChanged && (newStatus == oldStatus)) { // Owner Unchaged and Status Unchanged
                        canUpdateActiveDate = false;
                    } else if (isRealUser && !isOwnerChanged && invalidOldStatus && !invalidNewStatus && (newStatus != oldStatus)) {// Owner Unchanged [Real User] and Status Changed [Invalid -> Valid]
                        canUpdateActiveDate = true;
                    }
                }
                if (canUpdateActiveDate == true) {
                    newLeadObj.Lead_Active_Date__c = System.now();
                }
            }
        } catch (Exception ex) {
            ExceptionHelper.createExceptionAndNotificacionHistory(ex, newLeadList, 'Lead Exception');
        }
    }
    /**********************************************************************************************************************************/

    /*******************************************Check LeadName Custom Setting for Test Leads*****************************************/
    public static Map<String, Boolean> getLeadOwnerRCSFsync(List<Lead> leadList) {
        Map<String, Boolean> resultMap = new Map<String, Boolean>();
        try {
            List<LeadName__C> lstLeadName = LeadName__C.getAll().values();
            for (Lead leadObj : leadList) {
                resultMap.put(leadObj.FirstName + '_' + leadObj.LastName, false);
                for (LeadName__C objLeadName : lstLeadName) {
                    if (!string.isBlank(leadObj.FirstName) && !string.isBlank(leadObj.LastName) &&
                        ((leadObj.FirstName).equalsIgnoreCase(objLeadName.First_Name__c)
                            && (leadObj.LastName).equalsIgnoreCase(objLeadName.Last_Name__c))) {
                        leadObj.OwnerId = RCSF_SYNC;
                        //leadObj.Assignment_Source_hidden__c = 'Custom Settings';
                        resultMap.put(leadObj.FirstName + '_' + leadObj.LastName, true);
                    }
                }
            }
        } catch (Exception ex) {
            ExceptionHelper.createExceptionAndNotificacionHistory(ex, leadList, 'Lead Exception');
        }
        return resultMap;
    }
    /********************************************************************************************************************************/

    /**************************************Return Account Maps if Lead is SOLVE THEN SELL************************************************/
    public static Map<String, Account> findAccountMap(List<Lead> leadList) {
        Map<String, Account> userToAccountMap = new Map<String, Account>();
        try {
            List<String> userIds = new List<String>();
            for (Lead leadObj : leadList) {
                if (leadObj.User_ID__c != null
                    && leadObj.LeadSource == 'Solve then Sell'
                    || leadObj.BMID__c == 'SOLVETHENSELL') {
                    userIds.add(leadObj.User_ID__c);
                }
            }
            for (Account accObj : [SELECT Id, RC_User_ID__c FROM Account WHERE RC_User_ID__c IN :userIds AND RC_User_ID__c != '']) {
                userToAccountMap.put(accObj.RC_User_ID__c, accObj);
            }
        } catch (Exception ex) {
            LeadPlatEvents.leadExceptionCreationAsync(new Exception[]{
                ex
            }, 'findAccountMap');
            throw ex;
        }
        return userToAccountMap;
    }
    /************************************************************************************************************************************/

    /************************************Return Number OF Employee Picklist Values of Lead**********************************************/
    public static Set<string> getPicklistValue() {
        Set<String> ranges = new Set<String>();
        Schema.DescribeFieldResult numberOfEmployees = Lead.NumberOfEmployees__c.getDescribe();
        List<Schema.PicklistEntry> numberOfEmployeesRange = numberOfEmployees.getPicklistValues();
        for (Schema.PicklistEntry schObj : numberOfEmployeesRange) {
            ranges.add(schObj.getValue());
        }
        return ranges;
    }
    /**********************************************************************************************************************************/

    /***************************************Returns Employee Size Map*****************************************************************/
    public static Map<String, String> getCustomerSize(List<Lead> leadList) {
        Map<String, String> empToCustomerSizeMap = new Map<String, String>();

        Set<String> ranges = new Set<String>();
        Schema.DescribeFieldResult numberOfEmployees = Lead.NumberOfEmployees__c.getDescribe();
        List<Schema.PicklistEntry> numberOfEmployeesRange = numberOfEmployees.getPicklistValues();
        for (Schema.PicklistEntry schObj : numberOfEmployeesRange) {
            ranges.add(schObj.getValue());
        }
        for (Lead leadObj : leadList) {
            String customerSize = '2-9';
            if (!String.isBlank(leadObj.Effective_No_of_Employees_Range__c) && ranges.contains(leadObj.Effective_No_of_Employees_Range__c)) {
                customerSize = leadObj.Effective_No_of_Employees_Range__c;
            }

            empToCustomerSizeMap.put((String.isBlank(leadObj.Effective_No_of_Employees_Range__c) ? 'DEFAULT' : leadObj.Effective_No_of_Employees_Range__c), customerSize);
        }
        return empToCustomerSizeMap;
    }
    /*************************************************************************************************************************************/

    /*******************************************ASSIGN LEAD SOURCE BASED ON CONDITIONS****************************************************/
    public static void assignLeadSource(Lead leadObj) {
        try {
            set<String> validLeadSourceSet = new Set<String>{
                'Initial', 'About To Be Cancelled', 'Vista Print'
            };
            set<String> validBrandNameSet = new Set<String>{
                BT_BUSINESS, 'BT', 'RingCentral UK'
            };
            set<string> validPromotionSet = new Set<String>{
                'British Telecom', 'BT RingCentral', 'RC Partner Program Vista Print UK Studio',
                'Vista Print UK Telemarkeing', 'Vista Print UK', 'Vista UK', 'Voicemail - UK', 'Call Management - UK',
                '2009 UKRC Campaign', 'Fax - UK '
            };
            set<string> validTimeZoneSet = new Set<String>{
                'British Summer Time', 'Greenwich Mean Time', 'GMT', 'CET'
            };
            if (validLeadSourceSet.contains(leadObj.LeadSource)) {
                if ((leadObj.Email != null && leadObj.Email.endsWith('.co.uk'))
                    || leadObj.Country == 'UK'
                    || ((leadObj.phone != null) && (leadObj.phone.contains('+44') || leadObj.phone.contains('+353')))
                    || validBrandNameSet.contains(leadObj.Lead_Brand_Name__c)
                    || validTimeZoneSet.contains(leadObj.Timezone__c)) {

                    if (leadObj.LeadSource == 'Initial') {
                        leadObj.LeadSource = 'Initial UK';
                    } else if (leadObj.LeadSource == 'About To Be Cancelled') {
                        leadObj.LeadSource = 'About To Be Cancelled UK';
                    } else if (leadObj.LeadSource == 'Vista Print') {
                        leadObj.LeadSource = 'Vista Print UK';
                    }
                }
            }
        } catch (Exception ex) {
            LeadPlatEvents.leadExceptionCreationAsync(new Exception[]{
                ex
            }, 'assignLeadSource');
            throw ex;
        }
    }
    /*************************************************************************************************************************************/

    /*********************************************Update Lead Owner Manager Fields********************************************************/
    public static void getLeadOwnerManager(List<Lead> leadList) {
        try {
            Set<Id> ownerIds = new Set<Id>();
            Id hardcodedUser = HardcodedIdsMapper.getMatchedObjectId('005800000037xj5');
            for (Lead leadObj : leadList) {
                if (leadObj.OwnerId != hardcodedUser) {
                    ownerIds.add(leadObj.OwnerId);
                }
            }
            Set<String> managerIds = new Set<String>();
            Map<Id, User> managerMap = new Map<Id, User>();
            Map<id, User> userToManagerMap = new Map<id, User>();
            if (ownerIds.size() != 0) {
                userToManagerMap = new Map<id, User>((List<User>) USER_CACHE.retrieveList(ownerIds));
            }

            for (Lead leadObj : leadList) {
                if (leadObj.OwnerId == hardcodedUser) {
                    leadObj.Owner_Manager_Email__c = Emails__c.getall().get('davedowner') != null ? Emails__c.getall().get('davedowner').Email_Address__c : '';
                    leadObj.Owner_Manager_Name__c = 'Dave Demink';
                } else {
                    User userObj = userToManagerMap.get(leadObj.OwnerId);
                    if (userObj != null) {
                        leadObj.Owner_Manager_Email__c = userObj.Manager.email;
                        leadObj.Owner_Manager_Name__c = userObj.Manager.name;
                        leadObj.Lead_Owner_Phone_Number__c = userObj.Phone;
                        leadObj.Mkto_Reply_Email__c = userObj.Mkto_Reply_Email__c;
                    }
                }
            }
        } catch (System.Exception e) {
            ExceptionHelper.createExceptionAndNotificacionHistory(e, leadList, 'Lead Exception');
        }
    }
    /******************************************************************************************************************************************/

    /******************************** UPDATE ULIMATE PARTNER ACCOUNT INTO LEAD ON INSERT-UPDATE ***********************************************/
    public static void getLeadUltimatePartnerId(List<Lead> leadList, Map<Id, Lead> oldMap, Map<ID, Schema.RecordTypeInfo> rtMapByName) {
        try {
            Map<String, Account> mapPartnerIdToAccount = new Map<String, Account>(); // Partner Id to Account Object Map
            Map<String, id> mapPartnerIdToUltAccId = new Map<String, Id>(); // Ultimate Partner Id to Account Object Map
            Set<Id> ultimateParentAccIdSet = new Set<Id>(); // Ultimate Partner Id Set
            Map<Id, Account> mapAccountUltParentAccdet = new Map<Id, Account>(); // Partner Id to Ultimate Partner Id Map

            Set<String> partnerIds = new Set<String>();
            for (Lead leadObj : leadList) {
                if (leadObj.recordTypeId != null && rtMapByName.get(leadObj.RecordTypeId).getName() == 'Partner Leads') {
                    Lead oldLeadObj = (oldMap == null ? null : oldMap.get(leadObj.Id));
                    if (String.isBlank(leadObj.Ultimate_Parent_Account_ID__c) || (oldLeadObj != null && leadObj.LeadPartnerID__c != oldLeadObj.LeadPartnerID__c)) {
                        if (!String.isBlank(leadObj.LeadPartnerID__c)) {
                            partnerIds.add(leadObj.LeadPartnerID__c);
                        } else {
                            leadObj.Ultimate_Parent_Account_ID__c = null;
                            leadObj.Ultimate_Parent_Account_Name__c = null;
                            leadObj.Ultimate_Parent_Account_Partner_ID__c = null;
                            leadObj.Partner_Account_Name__c = null;
                            leadObj.Current_Owner_Name__c = null;
                            leadObj.Inside_Sales_Rep__c = null;
                        }
                    }
                }
            }

            if (partnerIds.size() != 0) {
                List<Account> accountList = [
                    SELECT Id, Inside_Sales_Rep__c, Inside_Sales_Rep__r.isActive, Name, Current_Owner_Name__c, Ultimate_Parent_Account_ID__c, Partner_Id__c, Var_territory__c
                    FROM Account
                    WHERE Partner_Id__c IN :partnerIds AND RecordType.Name = 'Partner Account'
                    ORDER BY LastModifiedDate ASC
                ]; // Most recent will replace the old account thats why chose ASC
                for (Account accObj : accountList) {
                    mapPartnerIdToAccount.put(accObj.Partner_Id__c, accObj);
                    ultimateParentAccIdSet.add(accObj.Ultimate_Parent_Account_ID__c);
                    mapPartnerIdToUltAccId.put(accObj.Partner_Id__c, accObj.Ultimate_Parent_Account_ID__c);
                }
                mapAccountUltParentAccdet = new Map<Id, Account>([
                    SELECT Id, Name, Current_Owner_Name__c, Partner_Id__c, Inside_Sales_Rep__c, Inside_Sales_Rep__r.isActive
                    FROM Account
                    WHERE
                        Id IN :ultimateParentAccIdSet
                ]);
                for (Lead leadObj : leadList) {
                    Lead oldLeadObj = (oldMap == null ? null : oldMap.get(leadObj.Id));
                    if (String.isBlank(leadObj.Ultimate_Parent_Account_ID__c) || (oldLeadObj != null && leadObj.LeadPartnerID__c != oldLeadObj.LeadPartnerID__c)) {
                        if (!String.isBlank(leadObj.LeadPartnerID__c)) {
                            if (mapPartnerIdToAccount != null && mapPartnerIdToAccount.get(leadObj.LeadPartnerID__c) != null) {
                                leadObj.Partner_Account_Name__c = mapPartnerIdToAccount.get(leadObj.LeadPartnerID__c).Name;
                                leadObj.Current_Owner_Name__c = mapPartnerIdToAccount.get(leadObj.LeadPartnerID__c).Current_Owner_Name__c;
                                //Case # 04179680
                                if (mapPartnerIdToAccount.get(leadObj.LeadPartnerID__c).Inside_Sales_Rep__c != null &&
                                    mapPartnerIdToAccount.get(leadObj.LeadPartnerID__c).Inside_Sales_Rep__r.isActive) {
                                    leadObj.Inside_Sales_Rep__c = mapPartnerIdToAccount.get(leadObj.LeadPartnerID__c).Inside_Sales_Rep__c;
                                } else {
                                    leadObj.Inside_Sales_Rep__c = null;
                                }
                                //Case #03765152
                                leadObj.Var_territory__c = mapPartnerIdToAccount.get(leadObj.LeadPartnerID__c).Var_territory__c;
                                //Case #03765152

                                if (mapAccountUltParentAccdet != null && mapPartnerIdToAccount.get(leadObj.LeadPartnerID__c).Ultimate_Parent_Account_ID__c != null &&
                                    mapAccountUltParentAccdet.get(mapPartnerIdToAccount.get(leadObj.LeadPartnerID__c).Ultimate_Parent_Account_ID__c) != null) {
                                    leadObj.Ultimate_Parent_Account_ID__c = mapAccountUltParentAccdet.get(mapPartnerIdToAccount.get(leadObj.LeadPartnerID__c).Ultimate_Parent_Account_ID__c).Id;
                                    leadObj.Ultimate_Parent_Account_Name__c = mapAccountUltParentAccdet.get(mapPartnerIdToAccount.get(leadObj.LeadPartnerID__c).Ultimate_Parent_Account_ID__c).Name;
                                    leadObj.Ultimate_Parent_Account_Partner_ID__c = mapAccountUltParentAccdet.get(mapPartnerIdToAccount.get(leadObj.LeadPartnerID__c).Ultimate_Parent_Account_ID__c).Partner_id__c;
                                }
                            }
                        }
                    }
                }
            }
        } catch (Exception ex) {
            LeadPlatEvents.leadExceptionCreationAsync(new Exception[]{
                ex
            }, 'getLeadUltimatePartnerId');
            throw ex;
        }
    }
    /**********************************************************************************************************************/

    /***************************Returns map of Approved Brand List based on Account PartnerId******************************/
    public static map<string, List<string>> getApprovedBrandList(List<Lead> newLeadList) {
        map<string, List<string>> approvedBrandListMap = new map<string, List<string>>();
        try {
            if (UserInfo.getUserType() == 'PowerPartner') {
                User userObjDetails = ((SObjectCache.UserCacheStorage) USER_CACHE).getCurrentUser();
                if (userObjDetails != null && userObjDetails.Contact.Account.Permitted_Brands__c != null &&
                    userObjDetails.Contact.Account.Partner_ID__c != null) {
                    approvedBrandListMap.put(userObjDetails.Contact.Account.Partner_ID__c,
                        userObjDetails.Contact.Account.Permitted_Brands__c.split(';'));
                }
            } else {
                set<string> partnerIdSet = new set<string>();
                for (Lead leadObj : newLeadList) {
                    if (!string.isBlank(leadObj.LeadPartnerID__c)) {
                        partnerIdSet.add(leadObj.LeadPartnerID__c);
                    }
                }
                for (Account accObj : [
                    select Permitted_Brands__c, Partner_ID__c
                    from Account
                    where RecordType.Name = 'Partner Account'
                    and Partner_ID__c IN :partnerIdSet
                ]) {
                    if (accObj.Permitted_Brands__c != null) {
                        approvedBrandListMap.put(accObj.Partner_ID__c, accObj.Permitted_Brands__c.split(';'));
                    }
                }
            }

        } catch (Exception ex) {
            ExceptionHelper.createExceptionAndNotificacionHistory(ex, newLeadList, 'Lead Exception');
        }
        return approvedBrandListMap;
    }
    /**********************************************************************************************************************/

    /******************************************Check Partner Lead Permitted By Brand***************************************/
    public static void checkPartnerLeadPermittedByBrand(List<Lead> newLeadList, map<Id, Lead> leadoldMap, map<string, List<string>> approvedBrandListMap,
        Map<ID, Schema.RecordTypeInfo> rtMapByName) {
        boolean isBrandPermitted = false;
        try {
            if (newLeadList != null) { //&& newLeadList.size() == 1
                for (Lead newLead : newLeadList) {
                    isBrandPermitted = false;
                    if (newLead.RecordTypeId != null && rtMapByName != null && rtMapByName.get(newLead.RecordTypeId).getName() == 'Partner Leads' &&
                        approvedBrandListMap != null && newLead.LeadPartnerID__c != null &&
                        approvedBrandListMap.get(newLead.LeadPartnerID__c) != null && newLead.Lead_Brand_Name__c != null &&
                        (leadoldMap == null || leadoldMap.get(newLead.id).Lead_Brand_Name__c != newLead.Lead_Brand_Name__c)) {
                        for (string strBrand : approvedBrandListMap.get(newLead.LeadPartnerID__c)) {
                            if (strBrand.trim() == newLead.Lead_Brand_Name__c) {
                                isBrandPermitted = true;
                                break;
                            }
                        }
                        if (isBrandPermitted == false) {
                            String address = Emails__c.getall().get('resellers') != null ? Emails__c.getall().get('resellers').Email_Address__c : 'your manager';
                            newLead.AddError('You are not permitted to sell this Brand. ' +
                                'Please contact <a style="font-size:12px;" ' +
                                'href=mailto:' + address + '>' + address + '</a> to gain access to this Brand.');
                        }
                    }
                }
            }
        } catch (Exception ex) {
            ExceptionHelper.createExceptionAndNotificacionHistory(ex, newLeadList, 'Lead Exception');
        }
    }
    /**********************************************************************************************************************/

    /************************************UPDATE Partner_Account_Current_Owner_Email__c Field of Lead**********************/
    public static void updatePartnerLeadCurrentOwnerEmail(List<Lead> newleadList, map<Id, Lead> newLeadMap, map<Id, Lead> oldLeadMap,
        Map<ID, Schema.RecordTypeInfo> rtMapByName) {
        try {
            set<Id> partnerOwnerIdSet = new set<Id>();
            set<Id> partnerContactIdSet = new set<Id>();//Relayware
            for (Lead leadObj : newleadList) {
                if (leadObj.recordTypeId != null && rtMapByName.get(leadObj.recordTypeId).getName() == 'Partner Leads'
                    && leadObj.Partner_Lead_Owner__c != null && (oldLeadMap == null ||
                    oldLeadMap.get(leadObj.id).Partner_Lead_Owner__c != newLeadMap.get(leadObj.id).Partner_Lead_Owner__c)) {
                    partnerOwnerIdSet.add(leadObj.Partner_Lead_Owner__c);
                }
                //Relayware
                if (leadObj.Partner_Contact__c != null && (oldLeadMap == null ||
                    oldLeadMap.get(leadObj.id).Partner_Contact__c != newLeadMap.get(leadObj.id).Partner_Contact__c)) {
                    partnerContactIdSet.add(leadObj.Partner_Contact__c);
                } else if (string.isBlank(leadObj.Partner_Contact__c) && oldLeadMap != NULL &&
                    oldLeadMap.get(leadObj.id).Partner_Contact__c != newLeadMap.get(leadObj.id).Partner_Contact__c) {
                    leadObj.Partner_Account__c = NULL;
                }
                //End
            }
            map<Id, User> userIdToAccountMap = new map<Id, User>();
            if (partnerOwnerIdSet.size() > 0) {
                userIdToAccountMap = new map<Id, User>((List<User>) USER_CACHE.retrieveList(partnerOwnerIdSet));
                for (Lead leadObj : newleadList) {
                    if (userIdToAccountMap != null && rtMapByName.get(leadObj.recordTypeId).getName() == 'Partner Leads'
                        && leadObj.Partner_Lead_Owner__c != null && userIdToAccountMap.get(leadObj.Partner_Lead_Owner__c) != null) {
                        leadObj.Partner_Account_Current_Owner_Email__c = userIdToAccountMap.get(leadObj.Partner_Lead_Owner__c).contact.Account.Current_Owner_Email__c;
                    } else {
                        leadObj.Partner_Account_Current_Owner_Email__c = null;
                    }
                }
            }
            //Relayware
            map<Id, Contact> contactIdToAccountMap = new map<Id, Contact>();
            if (partnerContactIdSet != NULL && partnerContactIdSet.size() > 0) {
                contactIdToAccountMap = new map<Id, Contact>([SELECT id, AccountID FROM Contact WHERE Id IN :partnerContactIdSet]);
                for (Lead leadObj : newleadList) {
                    if (leadObj.Partner_Contact__c != null && (oldLeadMap == null ||
                        oldLeadMap.get(leadObj.id).Partner_Contact__c != newLeadMap.get(leadObj.id).Partner_Contact__c)) {
                        leadObj.Partner_Account__c = contactIdToAccountMap.get(leadObj.Partner_Contact__c).AccountId;
                    }
                }
            }
            //End
        } catch (Exception ex) {
            ExceptionHelper.createExceptionAndNotificacionHistory(ex, newleadList, 'Lead Exception');
        }
    }
    /**********************************************************************************************************************/

    /*******************************************Update Most Recent Campaign on Lead****************************************/
    public static set<String> updateMostRecentCampaign(List<Lead> newLeadList, map<id, lead> oldLeadMap, Map<ID, Schema.RecordTypeInfo> rtMapByName) {
        Set<string> UniqueCombinationSet = new Set<string>();
        List<Lead> updatedLeadList = new List<Lead>();
        Set<String> campaignIdSet = new Set<String>();
        List<CampaignWrapper> camWrapperList = new List<CampaignWrapper>();
        try {
            for (Lead leadObj : newLeadList) {
                if(leadObj.Lead_Brand_Name__c!=null && System.Label.BizMerge_Brand_Exclusion_List!=null 
                && System.Label.BizMerge_Brand_Exclusion_List.contains(leadObj.Lead_Brand_Name__c))//BizMerge-Added Brand Name check to exclude Campaign Attribution logic for ATT Leads
                {
                    continue;
                }
              		
                if ((leadObj.BMID__c != null && leadObj.BMID__c != oldLeadMap.get(leadObj.Id).BMID__c) ||
                    (leadObj.AID__c != null && leadObj.AID__c != oldLeadMap.get(leadObj.Id).AID__c) ||
                    (leadObj.PID__c != null && leadObj.PID__c != oldLeadMap.get(leadObj.Id).PID__c) ||
                    (leadObj.Five9_DNIS__c != null && leadObj.Five9_DNIS__c != oldLeadMap.get(leadObj.Id).Five9_DNIS__c)) {

                    updatedLeadList.add(leadObj);
                    campaignIdSet.add(leadObj.Most_Recent_Campaign__c);
                    boolean isPartnerLead = false;
                    if ((leadObj.RecordTypeId != null && rtMapByName.get(leadObj.RecordTypeId).getName() == 'Partner Leads')) {
                        isPartnerLead = true;
                    }
                    camWrapperList.add(new CampaignWrapper(leadObj.AID__c, leadObj.BMID__c, leadObj.PID__c, leadObj.Five9_DNIS__c,
                        leadObj.Primary_Campaign__c, isPartnerLead));

                } else if ((leadObj.BMID__c != oldLeadMap.get(leadObj.Id).BMID__c) ||
                    (leadObj.AID__c != oldLeadMap.get(leadObj.Id).AID__c) ||
                    (leadObj.PID__c != oldLeadMap.get(leadObj.Id).PID__c) ||
                    (leadObj.Five9_DNIS__c != oldLeadMap.get(leadObj.Id).Five9_DNIS__c)) {
                    updatedLeadList.add(leadObj);
                    boolean isPartnerLead = false;
                    if ((leadObj.RecordTypeId != null && rtMapByName.get(leadObj.RecordTypeId).getName() == 'Partner Leads')) {
                        isPartnerLead = true;
                    }
                    campaignIdSet.add(leadObj.Most_Recent_Campaign__c);
                    camWrapperList.add(new CampaignWrapper(leadObj.AID__c, leadObj.BMID__c, leadObj.PID__c, leadObj.Five9_DNIS__c,
                        leadObj.Primary_Campaign__c, isPartnerLead));
                } else {
                    campaignIdSet.add(leadObj.Most_Recent_Campaign__c);
                }
            }

            if (updatedLeadList != null && updatedLeadList.size() > 0) {
                List<Lead> brokenLeadList = new List<Lead>();
                List<Lead> trueWalkOnLeadList = new List<Lead>();
                List<Lead> salesGeneratedList = new List<Lead>();
                Map<String, Campaign> criteriaToCamapaignMap = CampaignAssignmentHelper.findCampaingsLogic(camWrapperList);
                for (Lead leadObj : updatedLeadList) {
                    if (String.isBlank(leadObj.AID__c) && String.isBlank(leadObj.PID__c) && String.isBlank(leadObj.BMID__c) && String.isBlank(leadObj.Five9_DNIS__c)) {
                        if (sales_Generated_Source_Types.contains(leadObj.LeadSource)) {
                            salesGeneratedList.add(leadObj);
                        } else {
                            trueWalkOnLeadList.add(leadObj);
                        }
                    } else {
                        Campaign campaignObj = CampaignAssignmentHelper.getLeadCampaignLogicWithoutDNIS(new CampaignWrapper(leadObj.AID__c, leadObj.BMID__c, leadObj.PID__c, leadObj.Five9_DNIS__c, leadObj.Primary_Campaign__c, (leadObj.RecordTypeId == OpportunityHelper.getOppRecordTypeMap('Partner Leads'))), criteriaToCamapaignMap);
                        if (campaignObj != null && campaignObj.Name != 'Default Campaign') {
                            leadObj.Primary_Campaign__c = campaignObj.Id;
                            leadObj.Most_Recent_Campaign__c = campaignObj.Id;
                            leadObj.BMID__c = campaignObj.BMID__c;
                            campaignIdSet.add(leadObj.Most_Recent_Campaign__c);

                        } else {
                            brokenLeadList.add(leadObj);
                        }
                    }
                }

                Map<String, Campaign> campaignMap = new Map<String, Campaign>();

                if (trueWalkOnLeadList != null && trueWalkOnLeadList.size() > 0) {
                    LeadTriggerHelperExt.assignCampaignToList('True_Walk_On_2024', trueWalkOnLeadList, campaignMap);
                    for (String campaignId : campaignMap.keySet()) {
                        campaignIdSet.add(campaignId);
                    }
                }

                if (salesGeneratedList != null && salesGeneratedList.size() > 0) {
                    LeadTriggerHelperExt.assignCampaignToList('Sales Generated', salesGeneratedList, campaignMap);
                    for (String campaignId : campaignMap.keySet()) {
                        campaignIdSet.add(campaignId);
                    }
                }

                if (brokenLeadList != null && brokenLeadList.size() > 0) {
                    campaignMap = new Map<String, Campaign>();
                    LeadTriggerHelperExt.assignCampaignToList('Broken Attribution', brokenLeadList, campaignMap);
                    for (String campaignId : campaignMap.keySet()) {
                        campaignIdSet.add(campaignId);
                    }
                }
            }
        } catch (exception e) {
            ExceptionHelper.createExceptionAndNotificacionHistory(e, newLeadList, 'Lead Exception');
        }

        return campaignIdSet;
    }
    /**************************************************End of Update Most Recent Campaign on Lead**************************************/

    /*****************************Helper Method Called from "updateMostRecentCampaign" Method*****************************************/
    public static string createUniqueCombination(String BMID, String AID, String PID, String DNIS) {
        String strUniqueCombination = '';
        if (BMID != null && BMID != '') {
            strUniqueCombination += BMID;
        } else {
            strUniqueCombination += 'NULL';
        }
        if (AID != null && AID != '') {
            strUniqueCombination += '-' + AID;
        } else {
            strUniqueCombination += '-NULL';
        }
        if (PID != null && PID != '') {
            strUniqueCombination += '-' + PID;
        } else {
            strUniqueCombination += '-NULL';
        }
        if (DNIS != null && DNIS != '') {
            strUniqueCombination += '-' + DNIS;
        } else {
            strUniqueCombination += '-NULL';
        }
        return strUniqueCombination;
    }
    /***********************************************************************************************************************************/

    /***********************************Assign Brand UK if Owner Role contains UK ******************************************************/
    public static void assignBrand(List<Lead> leadList) {
        try {
            Set<Id> setOwnerId = new Set<Id>();
            for (Lead leadObj : leadList) {
                setOwnerId.add(leadObj.ownerID);
            }
            Map<Id, User> userRoleMap = new Map<Id, User>((List<User>) USER_CACHE.retrieveList(setOwnerId));
            for (Lead leadObj : leadList) {
                //New Updation as per Original Owner Detail requirement.
                if (userRoleMap != null && leadObj.OwnerId != null && userRoleMap.get(leadObj.OwnerId) != null) {
                    //For Storing Original Owner Details.
                    if (!LeadHelper.SYSTEM_USERS.contains(userRoleMap.get(leadObj.OwnerId).Name.toLowerCase())) {
                        leadObj.Original_Lead_Owner_Id__c = leadObj.OwnerId;
                        leadObj.Original_Lead_Owner_Name__c = userRoleMap.get(leadObj.OwnerId).Name;
                    }
                    if (userRoleMap.get(leadObj.OwnerId).UserRole.Name != null) {
                        String[] strRoleSplit = userRoleMap.get(leadObj.OwnerId).UserRole.Name.split(' ');
                        if (strRoleSplit != null && strRoleSplit.size() > 0) {
                            for (string strBrand : strRoleSplit) {
                                if (strBrand.equalsIgnoreCase('UK')) {
                                    leadObj.Lead_Brand_Name__c = 'RingCentral UK';
                                    break;
                                }
                            }
                        }
                    }
                }
            }
        } catch (Exception ex) {
            LeadPlatEvents.leadExceptionCreationAsync(new Exception[]{
                ex
            }, 'assignBrand');
            throw ex;
        }
    }
    /*******************************************************************************************************************/

    /*************************** eoc ************************************************************************************************************/

    //This code is called from Lead_After. Logic cannot be moved inside LeadCompanyProcessor
    public static void createCompanyPersons(Map<Id, Lead> leads, Map<Id, Lead> oldLeads) {
        try {
            List<Company_Persons__c> persons = new List<Company_Persons__c>();

            Boolean leadIdNotNull = (LeadsToBeDeleted == null || LeadsToBeDeleted.size() == 0);

            for (Lead ld : leads.values()) {
                if (ld.AH_Name__c != null
                    && (oldLeads == null
                    || ld.AH_Name__c != oldLeads.get(ld.Id).AH_Name__c)) {
                    Company_Persons__c cp = new Company_Persons__c(
                        Company__c = ld.AH_Name__c,
                        Lead__c = leadIdNotNull ? ld.Id : (LeadsToBeDeleted.contains(ld.Id) ? null : ld.Id)
                    );
                    persons.add(cp);
                }
            }

            if (persons.size() > 0) {
                insert persons;
            }
        } catch (Exception ex) {
            LeadPlatEvents.leadExceptionCreationAsync(new Exception[]{
                ex
            }, 'createCompanyPersons');
            throw ex;
        }
    }

    public static void populateDateStatusChanged(List<Lead> newLeads, Map<Id, Lead> oldLeadsMap) {
        system.debug('PopulateDateStatusChanged start time - ' + limits.getCpuTime());
        for (Lead l : newLeads) {
            try {
                String oldStatus = (Trigger.isInsert) ? null : oldLeadsMap.get(l.Id).Status;
                String newStatus = l.Status;

                if (oldStatus == newStatus) {
                    continue;
                }

                l.Date_Status_Changed__c = Date.today();
            } catch (Exception ex) {
                LeadPlatEvents.leadExceptionCreationAsync(new Exception[]{
                    ex
                }, 'PopulateDateStatusChanged');
                throw ex;
            }
        }
        system.debug('PopulateDateStatusChanged end time - ' + limits.getCpuTime());
    }

    public static void populateZipCustomFields(List<Lead> newLeads, Map<Id, Lead> oldLeadsMap) {
        system.debug('populateZipCustomFields start time - ' + limits.getCpuTime());
        for (Lead l : newLeads) {
            try {
                String oldPostalZip = (Trigger.isInsert) ? null : oldLeadsMap.get(l.Id).PostalCode;
                String newPostalZip = l.PostalCode;

                if (String.isBlank(newPostalZip)) {
                    continue;
                }

                if (oldPostalZip == newPostalZip) {
                    continue;
                }

                if (String.isNotBlank(l.Zip_Code__c)) {
                    continue;
                }

                //Zip_Code__c is blank, need to populate it from Postal Code, if it's not empty
                l.Zip_Code__c = l.PostalCode;
            } catch (Exception e) {
                ExceptionHelper.createExceptionAndNotificacionHistory(e, newLeads, 'Lead Exception');
            }
        }
        system.debug('populateZipCustomFields end time - ' + limits.getCpuTime());
    }

    public static void populatePartnerAccount(List<Lead> newLeads, Map<Id, Lead> oldLeadsMap) {
        if (Trigger.isUpdate) {
            Boolean isLookupUpdate = false;
            List<String> accNames = new List<String>();
            List<Id> accIds = new List<Id>();
            for (Lead l : newLeads) {
                if (l.Partner_Account_Name__c != null && l.Partner_Account_Name__c != oldLeadsMap.get(l.Id).Partner_Account_Name__c) {
                    accNames.add(l.Partner_Account_Name__c);
                } else if (l.Partner_Account__c != null && !(l.Partner_Account__c.equals(oldLeadsMap.get(l.Id).Partner_Account__c))) {
                    isLookupUpdate = true;
                    accIds.add(l.Partner_Account__c);
                } else if (CoreObjectBase.isFieldChangedTo(l, Lead.Partner_Account_Name__c, null)) {
                    l.Partner_Account__c = null;
                } else if (CoreObjectBase.isFieldChangedTo(l, Lead.Partner_Account__c, null)) {
                    l.Partner_Account_Name__c = null;
                }
            }
            if (!isLookupUpdate) {
                List<Account> accounts = new List<Account>([
                    SELECT Id, Name, Partner_ID__c
                    FROM Account
                    WHERE Name IN :accNames AND RecordType.Name = 'Partner Account'
                ]);
                Map<String, List<Account>> nameToAccounts = new Map<String, List<Account>>();
                for (Account acc : accounts) {
                    if (nameToAccounts.containsKey(acc.Name)) {
                        List<Account> listOfAccs = nameToAccounts.get(acc.Name);
                        listOfAccs.add(acc);
                        nameToAccounts.put(acc.Name, listOfAccs);
                    } else {
                        nameToAccounts.put(acc.Name, new List<Account>{
                            acc
                        });
                    }
                }
                if (!nameToAccounts.isEmpty()) {
                    for (Lead l : newLeads) {
                        List<Account> partnerAccountsWithAppropriateName = nameToAccounts.get(l.Partner_Account_Name__c);
                        if (partnerAccountsWithAppropriateName != null) {
                            for (Account partnerAccount : partnerAccountsWithAppropriateName) {
                                if (partnerAccount != null && partnerAccount.Partner_ID__c == l.LeadPartnerID__c) {
                                    l.Partner_Account__c = partnerAccount.Id;
                                }
                            }
                        }
                    }
                }
            } else {
                List<Account> accounts = new List<Account>([
                    SELECT Id, Name
                    FROM Account
                    WHERE Id IN :accIds
                ]);
                Map<Id, String> IdsToNames = new Map<Id, String>();
                for (Account acc : accounts) {
                    IdsToNames.put(acc.Id, acc.Name);
                }
                for (Lead l : newLeads) {
                    if (l.Partner_Account__c != null && l.Partner_Account__c != oldLeadsMap.get(l.Id).Partner_Account__c) {
                        l.Partner_Account_Name__c = IdsToNames.get(l.Partner_Account__c);
                    }
                }
            }
        }
    }


    public static List<LeanData__CC_Inserted_Object__c> createCCIOForLeanDataRouting(Map<Id, Lead> newLeadsMap,
        Map<Id, Lead> oldLeadsMap) {
        Set<String> routingReasons = new Set<String>{
            ROUTINGREASONNETNEWLEAD, ROUTINGREASONINACTIVEOWNER
        };
        // LeanData routing deployment initialization
        List<LeanData__CC_Inserted_Object__c> cciosToInsert = new List<LeanData__CC_Inserted_Object__c>();
        try {
            List<LeanData__Routing_Deployment__c> routingDeployments = [
                SELECT Id
                FROM LeanData__Routing_Deployment__c
                WHERE LeanData__Object_Type__c = 'Lead'
                AND LeanData__Type__c = null
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];

            if (routingDeployments.isEmpty()) {
                return null;
            }
            Id routingDeploymentId = routingDeployments[0].Id;

            for (Lead currentLead : newLeadsMap.values()) {
                if (oldLeadsMap != null) {
                    if (oldLeadsMap.get(currentLead.Id).OwnerId != newLeadsMap.get(currentLead.Id).OwnerId &&
                        newLeadsMap.get(currentLead.Id).OwnerId == UserHelper.LEANDATAUSERID &&
                        routingReasons.contains(newLeadsMap.get(currentLead.Id).Routing_Reason__c)) {

                        cciosToInsert.add(LeadTriggerHelper.createCCIOforLeanData(currentLead, routingDeploymentId));
                    }
                } else {
                    if (newLeadsMap.get(currentLead.Id).OwnerId == UserHelper.LEANDATAUSERID &&
                        routingReasons.contains(newLeadsMap.get(currentLead.Id).Routing_Reason__c)) {

                        cciosToInsert.add(LeadTriggerHelper.createCCIOforLeanData(currentLead, routingDeploymentId));
                    }
                }
            }

            if (!cciosToInsert.isEmpty()) {
                Database.insert(cciosToInsert, false);
            }
        } catch (Exception ex) {
            LeadPlatEvents.leadExceptionCreationAsync(new Exception[]{
                ex
            }, 'createCCIOForLeanDataRouting');
            throw ex;
        }
        return cciosToInsert;
    }

    public static LeanData__CC_Inserted_Object__c createCCIOForLeanData(Lead leadObj, Id routingDeploymentId) {

        if (leadRoutingSettings.LeanDataCreateCCIOToggle__c && leadRoutingSettings.RoutingSystemUserId__c != ''
            && routingDeploymentId != null) {
            //This is based off CCIOs as of 11/16/2018
            Integer processingPriority = 0;

            String lSource = leadObj.LeadSource != null ? leadObj.LeadSource.toLowerCase() : '';

            if (lSource.equalsIgnoreCase('partner')) {
                processingPriority = -3;
            } else if (lSource.equalsIgnoreCase('About To Be Cancelled') || lSource.equalsIgnoreCase('About To Be Cancelled UK')) {
                processingPriority = -1;
            } else if (leadObj.Status == LEADSTATUSNEW) {
                processingPriority = -4;
            } else if (leadObj.Status == LEADSTATUSRENEW || leadObj.Status == LEADSTATUSCALLOUT || leadObj.Status == LEADSTATUSCONTACTED) {
                processingPriority = -3;
            } else if (leadObj.Status == LEADSTATUSOPEN || leadObj.Status == LEADSTATUSDOWNGRADED) {
                processingPriority = -2;
            } else if (leadObj.Status == LEADSTATUSSUSPECT) {
                processingPriority = -1;
            }

            LeanData__CC_Inserted_Object__c ccio = new LeanData__CC_Inserted_Object__c(
                LeanData__Lead__c = leadObj.Id,
                LeanData__Processing_Priority__c = processingPriority,
                LeanData__Trigger_Edge_Label__c = 'Updated Lead',
                LeanData__Routing_Deployment__c = routingDeploymentId,
                LeanData__Pending_Action__c = 'routing',
                LeanData__Update_Status__c = 'update',
                LeanData__Object_Type__c = 'Lead',
                LeanData__Order_Timestamp__c = DateTime.now(),
                LeanData__Is_Processed__c = 0);
            return ccio;
        } else {
            return null;
        }

    }

    public class LeadQualificationRecordsProcessing {
        public void process(Map<Id, Lead> oldRecords, Map<Id, Lead> newRecords) {
            try {
                if (oldRecords == null || oldRecords.size() == 0 || newRecords == null || newRecords.size() == 0) {
                    return;
                }

                List<Lead> leadsToProcess = new List<Lead>();
                for (Id oldLeadId : oldRecords.keyset()) {
                    if (newRecords.containsKey(oldLeadId)) {
                        if (oldRecords.get(oldLeadId).IsConverted == false && newRecords.get(oldLeadId).IsConverted) {
                            leadsToProcess.add(newRecords.get(oldLeadId));
                        }
                    }
                }

                if (leadsToProcess.size() == 0) {
                    return;
                }

                List<Lead_Qualification__c> leadsQualifications = [
                    SELECT Id, Lead__c, Account__c, Contact__c, Opportunity__c, LastModifiedDate
                    FROM Lead_Qualification__c
                    WHERE IsDeleted = false AND Lead__c IN :leadsToProcess
                    ORDER BY Lead__c, LastModifiedDate DESC
                ];

                Set<Lead_Qualification__c> recordsForUpdate = updateMostRecentLeadQualifications(leadsQualifications, newRecords);
                List<Lead_Qualification__c> recordsForDelete = getLeadQualificationsForDelete(leadsQualifications, recordsForUpdate);

                update new List<Lead_Qualification__c>(recordsForUpdate);
                delete recordsForDelete;
            } catch (Exception ex) {
                LeadPlatEvents.leadExceptionCreationAsync(new Exception[]{
                    ex
                }, 'LeadQualificationRecordsProcessing.process');
                throw ex;
            }
        }

        private Set<Lead_Qualification__c> updateMostRecentLeadQualifications(List<Lead_Qualification__c> records, Map<Id, Lead> leadsMap) {
            Set<Lead_Qualification__c> result = new Set<Lead_Qualification__c>();
            Set<Id> processedLeadIds = new Set<Id>();
            for (Lead_Qualification__c leadQualif : records) {
                if (processedLeadIds.contains(leadQualif.Lead__c) == false) {
                    Lead l = leadsMap.get(leadQualif.Lead__c);
                    leadQualif.Lead__c = null;
                    leadQualif.Account__c = l.ConvertedAccountId;
                    leadQualif.Contact__c = l.ConvertedContactId;
                    leadQualif.Opportunity__c = l.ConvertedOpportunityId;
                    result.add(leadQualif);
                    processedLeadIds.add(l.Id);
                }
            }
            return result;
        }

        private List<Lead_Qualification__c> getLeadQualificationsForDelete(List<Lead_Qualification__c> records, Set<Lead_Qualification__c> recordsToKeep) {
            List<Lead_Qualification__c> result = new List<Lead_Qualification__c>();
            for (Lead_Qualification__c leadQualif : records) {
                if (recordsToKeep.contains(leadQualif)) {
                    continue;
                }
                if (leadQualif.Account__c == null && leadQualif.Contact__c == null && leadQualif.Opportunity__c == null) {
                    result.add(leadQualif);
                }
            }
            return result;
        }
    }

    private static Map<Id, Campaign> getCampaignMap(Set<Id> campaignIds) {
        Map<Id, Campaign> campaignMap;
        if (!campaignIds.isEmpty()) {
            campaignMap = new Map<Id, Campaign>();
            List<Object> bindings = new List<Object>();
            bindings.add(campaignIds);
            campaignMap.putAll((List<Campaign>) new CampaignSelector().selectCampaignsByIds(bindings).executeQuery());
        }
        return campaignMap;
    }

    public static List<CampaignMember> campaignAttribution(Set<Id> campaignIds, List<Lead> leadsMRC, Map<Id, Lead> oldMap) {
        Map<Id, Campaign> campaignMap = getCampaignMap(campaignIds);
        List<CampaignMember> campaignMemberList;
        if (campaignMap != null && !campaignMap.isEmpty()) {
            campaignMemberList = new List<CampaignMember>();
            for (Lead lead : leadsMRC) {
                Campaign newCampaign = campaignMap.get(lead.Most_Recent_Campaign__c);
                Campaign oldCampaign = campaignMap.get(oldMap.get(lead.Id).Most_Recent_Campaign__c);
                if (oldCampaign != null && !oldCampaign.Non_Attributable__c && newCampaign.Non_Attributable__c) {
                    lead.Most_Recent_Campaign__c = oldCampaign.Id;
                    lead.Primary_Campaign__c = oldCampaign.Id;
                }
                Id assetId;
                if (lead.Most_Recent_Asset__c != oldMap.get(lead.Id).Most_Recent_Asset__c || lead.Asset_Id__c != oldMap.get(lead.Id).Asset_Id__c) {
                    assetId = lead.Most_Recent_Asset__c;
                }
                if (newCampaign.Shared_Lead_Campaign__c) {
                    Integer counter = Integer.valueOf(lead.Shared_Lead_Counter__c == null ? 0 : lead.Shared_Lead_Counter__c);
                    lead.Shared_Lead_Counter__c = counter + 1;
                }
                campaignMemberList.add(new CampaignMember(CampaignId = newCampaign.Id, LeadId = lead.Id, Primary_Marketing_Asset__c = assetId));
            }
        }
        return campaignMemberList;
    }

    public static List<CampaignMember> getExistingCampMembers(List<Id> leadIdsBindings, List<Id> campaignIdsBindings) {
        List<Object> bindings = new List<Object>();
        bindings.add(leadIdsBindings);
        bindings.add(campaignIdsBindings);
        return (List<CampaignMember>) new CampaignMemberSelector()
            .selectCampaignMemberByLeadAndCampaignIds(bindings)
            .selectField(CampaignMember.Status)
            .executeQuery();
    }

    public static List<CampaignMember> removeExistingCampMembers(List<CampaignMember> existingCampMembs, List<CampaignMember> campaignMemberList) {
        List <CampaignMember> campaignMembersToInsert = new List<CampaignMember>();
        Set<String> existingCampMembsKey = new Set<String>();

        if (campaignMemberList == null || campaignMemberList.isEmpty()) {
            return campaignMembersToInsert;
        }

        if (existingCampMembs != null && !existingCampMembs.isEmpty()) {
            for (CampaignMember cm : existingCampMembs) {
                existingCampMembsKey.add('' + cm.LeadId + cm.CampaignId);
            }
        }

        if (existingCampMembsKey.isEmpty()) {
            return campaignMemberList;
        }

        for (CampaignMember cm : campaignMemberList) {
            String key = '' + cm.LeadId + cm.CampaignId;
            if (!existingCampMembsKey.contains(key)) {
                campaignMembersToInsert.add(cm);
            }
        }

        return campaignMembersToInsert;
    }

    public static void updateRecruitedByField(List<Lead> leads) {
        try {
            List<Id> leadParentAccountIds = new List<Id>();
            Map<Id, Account> leadParentAccounts = new Map<Id, Account>();

            for (Lead l : leads) {
                leadParentAccountIds.add(l.Partner_Account__c);
            }

            if (leadParentAccountIds.size() > 0) {
                AccountSelector selector = new AccountSelector();

                leadParentAccounts = new Map<Id, Account>((List<Account>)
                    selector.selectAccounts()
                        .selectFields(new List<String>{
                            'Id', 'Recruited_By__c'
                        })
                        .setCondition('Id IN :bind0')
                        .setQueryBindings(new List<Object>{
                            leadParentAccountIds
                        })
                        .executeQuery()
                );
            }

            for (Lead currentLead : leads) {
                Account partnerAcc = leadParentAccounts.get(currentLead.Partner_Account__c);

                if (currentLead.recordTypeId != null
                    && currentLead.RecordTypeId == LeadHelper.RT_ID_PARTNER_LEADS
                    && !currentLead.isConverted
                    && currentLead.Partner_Account_Name__c != null
                    && partnerAcc != null
                    && partnerAcc.Recruited_By__c != null
                    && currentLead.Recruited_By__c != partnerAcc.Recruited_By__c) {

                    currentLead.Recruited_By__c = partnerAcc.Recruited_By__c;
                }
            }
        } catch (Exception ex) {
            LeadPlatEvents.leadExceptionCreationAsync(new Exception[]{
                ex
            }, 'updateRecruitedByField');
            throw ex;
        }
    }

    /***************************** Populate Assigned CSS from Account to the same field ********************************/
    public static void populateAssignedCSS(List<Lead> leadList) {
        try {
            Map<String, Account> mapPartnerIdToAccount = new Map<String, Account>(); // Partner Id to Account Object Map
            Set<String> partnerIds = new Set<String>();

            for (Lead leadObj : leadList) {
                if (leadObj.LeadPartnerID__c != null) {
                    partnerIds.add(leadObj.LeadPartnerID__c);
                }
            }

            if (partnerIds.size() != 0) {
                List<Account> accountList = [
                    SELECT Id, Partner_Id__c, Assigned_CSS__c
                    FROM Account
                    WHERE Partner_Id__c IN :partnerIds
                    ORDER BY LastModifiedDate ASC
                ]; // Most recent will replace the old account thats why chose ASC

                for (Account accObj : accountList) {
                    mapPartnerIdToAccount.put(accObj.Partner_Id__c, accObj);
                }

                for (Lead leadObj : leadList) {
                    if (mapPartnerIdToAccount != null && mapPartnerIdToAccount.get(leadObj.LeadPartnerID__c) != null && CoreObjectBase.isFieldChangedFrom(leadObj, Lead.LeadPartnerID__c, null)) {
                        leadObj.Assigned_CSS__c = mapPartnerIdToAccount.get(leadObj.LeadPartnerID__c).Assigned_CSS__c;
                    }
                }
            }
        } catch (Exception ex) {
            LeadPlatEvents.leadExceptionCreationAsync(new Exception[]{
                ex
            }, 'populateAssignedCSS');
            throw ex;
        }
    }

    //Logic to populate SystemProcessStageCreated on Lead //CMR-306098 9/9/2021 Starts from populateSystemProcessStageCreated
    public static void populateSystemProcessStageCreated(List<Lead> lstLead, Map<Id,Lead> oldMap)
    {
        String nonAvayaUsers = System.Label.Non_Avaya_Users;
        String [] listUsers = nonAvayaUsers.split(';');
        DateTime fakeMarketoDate = DateTime.newInstance(1900,1,1);
        Gating_Process_Stage__c processStage = Gating_Process_Stage__c.getInstance();
        for(Lead l: lstLead){
            l.isConvertedFromLead__c = true;
        }

        if(processStage != null && processStage.Bypass_Gating_Process_Stage__c == true){
            return;
        }
        try {
            for(Lead l : lstLead)
            {
                if(l.Lead_Brand_Name__c!=null && System.Label.BizMerge_Brand_Exclusion_List!=null 
                && System.Label.BizMerge_Brand_Exclusion_List.contains(l.Lead_Brand_Name__c))//BizMerge-Added Brand Name check to exclude Gating Logic for ATT Leads
                {
                    continue;
                }
              		
                if(((l.CreatedById != null && l.CreatedById!=listUsers[0]) || (UserInfo.getUserId()!=listUsers[0]))  && Trigger.isInsert && l.Systems_Process_Stage__c ==null)
                {
                    l.Systems_Process_Stage__c = 'SFDC created';
                }
                else if(((l.CreatedById != null && l.CreatedById==listUsers[0]) || (UserInfo.getUserId()==listUsers[0])) && Trigger.isInsert)
                {
                    if(l.Marketo_enriched_date_time__c == null || (l.Marketo_enriched_date_time__c != null && fakeMarketoDate != null && l.Marketo_enriched_date_time__c.date() == fakeMarketoDate.date() )) {
                    	l.Systems_Process_Stage__c = 'Marketo created';
                    } else if(l.Marketo_enriched_date_time__c != null && l.Marketo_enriched_date_time__c != fakeMarketoDate) {
                        l.Systems_Process_Stage__c = 'Marketo enriched';
                    }
                }
            }
        } catch (Exception ex) {
            LeadPlatEvents.leadExceptionCreationAsync(new Exception[]{ex},'populateSystemProcessStageCreated');
            throw ex;
        }
    }

    public static void removeDowngradeValuesForNonDowngradedLeads(List<Lead> newLeads) {
        for (Lead l : newLeads) {
            if (CoreObjectBase.isFieldChangedFrom(l, Lead.Status, LeadHelper.STATUS_DOWNGRADED)) {
                l.Downgrade_Reason__c = null;
                l.Downgrade_Reason_Other__c = null;
                l.Sub_Downgrade_Reason__c = null;
                l.Sub_Downgrade_Reason_Other__c = null;
                l.Downgrade_Other_Reason_for_Loss__c = null;
                l.Downgrade_Date__c = null;
            }
        }
    }

    public static void MarketoSync(List<Lead> lstLead) {
        for (Lead l : lstLead) {
            Marketo_Sync__c MarketoSync = Marketo_Sync__c.getInstance();
            try{
                if (((MarketoSync != null && MarketoSync.Marketo_Sync_Disabled__c == true)
                 || (l.Lead_Brand_Name__c!=null && System.Label.BizMerge_Brand_Exclusion_List!=null 
                 && System.Label.BizMerge_Brand_Exclusion_List.contains(l.Lead_Brand_Name__c)) ) && trigger.isInsert)//BizMerge-Added Brand Name check to make Marketo Sync Disabled True
                 {
                    l.Marketo_Sync_Disabled__c = true;
                 }
                
            }
            catch(Exception ex){
            LeadPlatEvents.leadExceptionCreationAsync(new Exception[]{ex},'MarketoSync');
            throw ex;
            }
        }
    }

    //Logic to populate SystemProcessStageBypassed on Lead
    public static void populateSystemProcessStageBypassed(List<Lead> lstLead, Map<Id,Lead> oldMap)
    {
        system.debug('populateSystemProcessStageBypassed start time - ' + limits.getCpuTime());
        String nonAvayaUsers = System.Label.Non_Avaya_Users;
        String [] listUsers = nonAvayaUsers.split(';');
        Map<Id, String> mapLeadProfiles = new Map<Id, String>();
        Set<Id> leadCreatedIds = new Set<Id>();
        Gating_Process_Stage__c processStage = Gating_Process_Stage__c.getInstance();
        if(processStage != null && processStage.Bypass_Gating_Process_Stage__c == true){
            return;
        }
        try {
            for(Lead l : lstLead)
            {
                leadCreatedIds.add(l.CreatedById);
            }
            if (leadCreatedIds.size() > 0) {
                List<User> userList = (List<User>) USER_CACHE.retrieveList(leadCreatedIds);
                for (User u : userList) {
                    mapLeadProfiles.put(u.id, u.profile.name);
                }
            }
            for(Lead l : lstLead)
            {
                if(l.Lead_Brand_Name__c!=null && System.Label.BizMerge_Brand_Exclusion_List!=null 
                && System.Label.BizMerge_Brand_Exclusion_List.contains(l.Lead_Brand_Name__c))//BizMerge-Added Brand Name check to exclude Gating Logic for ATT Leads
                {
                    continue;
               
                }
              		 if(processStage != null && processStage.Bypass_Enrichment_Process__c == true && (Trigger.isInsert || (oldMap!=null && ((oldMap.get(l.Id)).Website!= l.Website || (oldMap.get(l.Id)).Company != l.Company || (oldMap.get(l.Id)).Email != l.Email || (oldMap.get(l.Id)).Country != l.Country))))
                {
                    l.SystemsProcessBypass__c = 'Bypass Enrichment';
                    l.Systems_process_enrichment_bypass__c = 'Custom Setting Bypass';
                }
                if(processStage != null && processStage.Bypass_Segmentation_Process__c == true && (Trigger.isInsert || (oldMap!=null && ((oldMap.get(l.Id)).ZI_Company_Country__c!= l.ZI_Company_Country__c || (oldMap.get(l.Id)).VD_Country__c != l.VD_Country__c || (oldMap.get(l.Id)).Employees_Override__c != l.Employees_Override__c || ((oldMap.get(l.Id)).Country != l.Country && processStage != null && processStage.Bypass_Gating_Process_Stage__c==true) || ((oldMap.get(l.Id)).Country__c != l.Country__c && processStage != null && processStage.Bypass_Gating_Process_Stage__c==true) || (oldMap.get(l.Id)).Emp_Range_Sales_Override__c!= l.Emp_Range_Sales_Override__c || (oldMap.get(l.Id)).ZI_Employees__c!= l.ZI_Employees__c || (oldMap.get(l.Id)).LS_Company_Size__c!= l.LS_Company_Size__c || (oldMap.get(l.Id)).NumberOfEmployees!= l.NumberOfEmployees || (oldMap.get(l.Id)).NumberOfEmployees__c!= l.NumberOfEmployees__c || (oldMap.get(l.Id)).ZI_CDP_Account_Id__c!= l.ZI_CDP_Account_Id__c || (oldMap.get(l.Id)).Ultimate_SM_Country__c!= l.Ultimate_SM_Country__c || (oldMap.get(l.Id)).Ultimate_SM_Employees__c!= l.Ultimate_SM_Employees__c))))
                {
                    l.SystemsProcessBypass__c = 'Bypass Segmentation';
                    l.Systems_process_segmentation_bypass__c = 'Custom Setting Bypass';
                }
                if(processStage != null && (processStage.Bypass_Routing_Process__c == true || (processStage.Bypass_Segmentation_Process__c == true && l.Lead_Created_via_Smart_Search__c==true && l.RecordType.Name!='Partner Leads' && mapLeadProfiles != null && mapLeadProfiles.containsKey(l.CreatedById) && mapLeadProfiles.get(l.CreatedById) !='System Administrator')))
                {
                    l.SystemsProcessBypass__c = 'Bypass Routing';
                    l.Systems_process_routing_bypass__c = 'Custom Setting Bypass';
                }
            }
        } catch (Exception ex) {
            LeadPlatEvents.leadExceptionCreationAsync(new Exception[]{ex},'populateSystemProcessStageBypassed');
            throw ex;
        }
        system.debug('populateSystemProcessStageBypassed end time - ' + limits.getCpuTime());
    }

    //Logic to populate SystemProcessStageEnriched on Lead
    public static void populateSystemProcessStageEnriched(List<Lead> lstLead, Map<Id,Lead> oldMap)
    {
        system.debug('populateSystemProcessStageEnriched start time - ' + limits.getCpuTime());
        String nonAvayaUsers = System.Label.Non_Avaya_Users;
        String [] listUsers = nonAvayaUsers.split(';');
        DateTime fakeMarketoDate = DateTime.newInstance(1900,1,1);
        Gating_Process_Stage__c processStage = Gating_Process_Stage__c.getInstance();
        Leadspace_field_bypass__c LSField = Leadspace_field_bypass__c.getInstance();
        try {
            for(Lead l : lstLead)
            {
                if(l.Lead_Brand_Name__c!=null && System.Label.BizMerge_Brand_Exclusion_List!=null
                 && System.Label.BizMerge_Brand_Exclusion_List.contains(l.Lead_Brand_Name__c))//BizMerge-Added Brand Name check to exclude Gating Logic for ATT Leads
                 {
                    continue;
                 }
              		
                if(((l.Enrichment_Last_Processed_Date__c!=null && LSField.Bypass_Lead_Fields__c==true)) &&
                   ((l.LS_Status__c=='Success' && LSField.Bypass_Lead_Fields__c==true)) &&
                   l.isConverted == false && l.SystemsProcessBypass__c != 'Bypass Enrichment' && ((oldMap!=null && (oldMap.get(l.Id)).LS_Status__c!= l.LS_Status__c)))
                {
                    if(processStage != null && processStage.Bypass_Gating_Process_Stage__c == false && processStage.Bypass_Enrichment_Process__c == false)
                    {
                    	l.Systems_Process_Stage__c = 'SFDC enriched';
                    }
                    if(processStage != null && processStage.Bypass_Enrichment_Process__c == true)
                    {
                    	l.SystemsProcessBypass__c = 'Bypass Enrichment';
                        l.Systems_process_enrichment_bypass__c = 'Custom setting bypass';
                    }
                    l.SFDC_enriched_date_time__c = System.now();
                }
                else if(l.Marketo_enriched_date_time__c != null && l.Marketo_enriched_date_time__c != fakeMarketoDate && l.isConverted == false && l.SystemsProcessBypass__c != 'Bypass Enrichment' && ((oldMap!=null && ((oldMap.get(l.Id)).Marketo_enriched_date_time__c!= l.Marketo_enriched_date_time__c))))
                {
                    if(processStage != null && processStage.Bypass_Gating_Process_Stage__c == false && processStage.Bypass_Enrichment_Process__c == false)
                    {
                    	l.Systems_Process_Stage__c = 'Marketo enriched';
                    }
                }
                 else if(l.Marketo_enriched_date_time__c != null && fakeMarketoDate != null && l.Marketo_enriched_date_time__c.date() == fakeMarketoDate.date() && l.isConverted == false && l.SystemsProcessBypass__c != 'Bypass Enrichment' && ((oldMap!=null && ((oldMap.get(l.Id)).Marketo_enriched_date_time__c!= l.Marketo_enriched_date_time__c))))
                {
                    if(processStage != null && processStage.Bypass_Gating_Process_Stage__c == false && processStage.Bypass_Enrichment_Process__c == false)
                    {
                    	l.SystemsProcessBypass__c = 'Bypass Enrichment';
                        l.Systems_process_enrichment_bypass__c = 'Exclusions';
                    }
                }
            }
        } catch (Exception ex) {
            LeadPlatEvents.leadExceptionCreationAsync(new Exception[]{ex},'populateSystemProcessStageEnriched');
            throw ex;
        }
        system.debug('populateSystemProcessStageEnriched end time - ' + limits.getCpuTime());
    }

    //Logic to call SLEDWebServiceCallout and populate Sector,Industry,SubIndustry,SectorSource
    public static void stampedAsSLED(List<Lead> lstLead, Map<Id, Lead> oldMap) {
        List<Lead> leadsToProcess = new List<Lead>();
        Map<Id, String> mapSMCountriesToLeads = new Map<Id, String>();

        Set<Id> leadIds = new Set<Id>();
        for(Lead l : lstLead) {
            leadIds.add(l.Id);
        }

        Map<Id, Lead> leadWithAccountCountryMap = getLeadSMCountries(leadIds);

        for (Lead lead : lstLead) {
            if (lead.Systems_Process_Stage__c == 'SFDC enriched' && oldMap != null && (oldMap.get(lead.Id)).Systems_Process_Stage__c != lead.Systems_Process_Stage__c) {
                    leadsToProcess.add(lead);
                    mapSMCountriesToLeads.put(lead.Id, getSMCountry(lead, leadWithAccountCountryMap.get(lead.Id)));
            }
        }
    
        if (!leadsToProcess.isEmpty()) {
            System.enqueueJob(new SLEDWebServiceCallout(leadsToProcess, mapSMCountriesToLeads));

        }
    }

    private static Map<Id, Lead> getLeadSMCountries(Set<Id> leadIds) {
        Map<Id, Lead> leadById = new Map<Id, Lead>();

        if (!leadIds.isEmpty()) {
            leadById.putAll((List<Lead>) new LeadSelector()
                .selectLeadsByIds(new Object[]{ leadIds })
                .selectField('ZI_CDP_Account_Id__r.ZI_Company_Country__c')
                .executeQuery()
            );
        }

        return leadById;
    }

    private static String getSMCountry(Lead l, Lead lWithAccountCountry) {
        String country;

        if(lWithAccountCountry.ZI_CDP_Account_Id__r != null && !String.isBlank(lWithAccountCountry.ZI_CDP_Account_Id__r.ZI_Company_Country__c)) {
            country = lWithAccountCountry.ZI_CDP_Account_Id__r.ZI_Company_Country__c;
        } else if(!String.isBlank(l.ZI_Company_Country__c)) {
            country = l.ZI_Company_Country__c;
        } else if(!String.isBlank(l.Country)) {
            country = l.Country;
        } else if(!String.isBlank(l.VD_Country__c)) {
            country = l.VD_Country__c;
        } else if(!String.isBlank(l.Country__c)) {
            country = String.valueOf(l.Country__c);
        } else {
            country = 'United States';
        }

        return country;
    }

    //Logic to populate SystemProcessStageUpdated on Lead
    public static void populateSystemProcessStageUpdated(List<Lead> lstLead, Map<Id,Lead> oldMap)
    {
        system.debug('populateSystemProcessStageUpdated start time - ' + limits.getCpuTime());
        String nonAvayaUsers = System.Label.Non_Avaya_Users;
        String [] listUsers = nonAvayaUsers.split(';');
        String BTAPIuser= System.Label.BT_API_User_id;
        Gating_Process_Stage__c processStage = Gating_Process_Stage__c.getInstance();

        Boolean IsBTLead=False;
        try {
            for(Lead l : lstLead)
            {
                if(l.Lead_Brand_Name__c!=null && System.Label.BizMerge_Brand_Exclusion_List!=null
                 && System.Label.BizMerge_Brand_Exclusion_List.contains(l.Lead_Brand_Name__c))//BizMerge-Added Brand Name check to exclude Gating Logic for ATT Leads
                 {
                    continue;
                 }
              	
                 if(l.Lead_Brand_Name__c == 'BT Business' && l.CreatedById == BTAPIuser)
                  {
                  IsBTLead = True;
                  }
                if(l.isConverted == false && (l.Systems_Process_Stage__c != 'SFDC enriched' && l.Systems_Process_Stage__c != 'Marketo enriched') && (oldMap!=null && (oldMap.get(l.Id)).SystemsProcessBypass__c == l.SystemsProcessBypass__c) && ((oldMap!=null && ((oldMap.get(l.Id)).Website!= l.Website || (oldMap.get(l.Id)).Company != l.Company || (oldMap.get(l.Id)).Email != l.Email || (oldMap.get(l.Id)).Country != l.Country))))
                {
                    if(processStage != null && processStage.Bypass_Gating_Process_Stage__c == false && processStage.Bypass_Enrichment_Process__c == false)
                    {
                        l.Systems_Process_Stage__c = 'SFDC updated';
                        l.SFDC_updated_via_Enrichment__c = true;
                        l.SystemsProcessBypass__c = null;
                        l.Systems_process_enrichment_bypass__c = null;
                        l.Systems_process_segmentation_bypass__c = null;
                        l.Systems_process_routing_bypass__c = null;
                        if(processStage != null && processStage.Bypass_Gating_Nullifying_Datetime__c == true)
                        {
                            l.ZI_CDP_Account_Id__c = null;
                            l.ZI_CDP_Match__c = null;
                            l.ZI_Id__c = null;
                            l.ZI_CDP_AccountId_From_LS4SF__c = null;
                            l.ZI_Employees__c = null;
                            l.ZI_Company_Name__c = null;
                            l.ZI_Company_Street__c = null;
                            l.ZI_Company_City__c = null;
                            l.ZI_Company_State__c = null;
                            l.ZI_Company_Postal_Code__c = null;
                            l.ZI_Company_Country__c = null;
                            if(IsBTLead == False) {
                            l.Sector__c = null;
                            }
                            l.Industry = null;
                            l.Sub_Industry__c = null;
                            l.ZI_NAIC__c = null;
                            l.ZI_SIC__c = null;
                            l.ZI_Immediate_Parent_Id__c = null;
                            l.ZI_Ultimate_Parent_Id__c = null;
                            l.ZI_Relationship__c = null;
                            l.Ultimate_SM_Country__c = null;
                            l.Ultimate_SM_Employees__c = null;
                        }
                        l.LS_Status__c = null;
                        l.LS_Enrichment_Date__c = null;
                        //Nullification of ZI leads before re-enrichment logic after SFDC updated on enrichment fields starts
                    }

                    l.SFDC_updated_date_time__c = System.now();
                }
                if(l.Systems_Process_Stage__c=='Manual SFDC updated' && ((oldMap!=null && ((oldMap.get(l.Id)).Systems_Process_Stage__c!= l.Systems_Process_Stage__c))))
                {
                    l.LS_Status__c = null;
                    l.LS_Enrichment_Date__c = null;
                    l.SystemsProcessBypass__c = null;
                    l.Systems_process_enrichment_bypass__c = null;
                    l.Systems_process_segmentation_bypass__c = null;
                    l.Systems_process_routing_bypass__c = null;
                    l.SFDC_updated_date_time__c = System.now();
                }
            }
        } catch (Exception ex) {
            LeadPlatEvents.leadExceptionCreationAsync(new Exception[]{ex},'populateSystemProcessStageUpdated');
            throw ex;
        }
        system.debug('populateSystemProcessStageUpdated end time - ' + limits.getCpuTime());
    }

    //Lead Enrichment Exclusion Logic for Gating
    public static void populateLeadEnrichmentExclusion(List<lead> lstLead,Map<Id,Lead>oldMap){
        system.debug('populateLeadEnrichmentExclusion start time - ' + limits.getCpuTime());
        Gating_Process_Stage__c processStage = Gating_Process_Stage__c.getInstance();
        DateTime fakeMarketoDate = DateTime.newInstance(1900,1,1);
        List<String> excludedDomains;
        List<String> excludedWebsites;
        List<String> excludedLeadEntrySources;
        List<String> excludedCompanies;
        if(processStage != null && processStage.Bypass_Gating_Process_Stage__c == true){
            return;
        }
        if(processStage != null && processStage.Gating_Excluded_Domains__c != null && processStage.Gating_eCommerce_Batch__c != null && processStage.Gating_Enrichment_New_Company__c != null)
        {
            excludedDomains = processStage.Gating_Excluded_Domains__c.split(',');
            excludedLeadEntrySources = processStage.Gating_eCommerce_Batch__c.split(',');
            excludedCompanies = processStage.Gating_Enrichment_New_Company__c.split(',');
        }
        try {
        for(Lead ld : lstLead)
        {
            if(ld.Lead_Brand_Name__c!=null && System.Label.BizMerge_Brand_Exclusion_List!=null 
            && System.Label.BizMerge_Brand_Exclusion_List.contains(ld.Lead_Brand_Name__c))//BizMerge-Added Brand Name check to exclude Gating Logic for ATT Leads
            {
                continue;
            }
              	
            if(ld.isConverted == false && ((Trigger.isInsert) ||(oldMap!=null && ((oldMap.get(ld.Id)).Website!= ld.Website || (oldMap.get(ld.Id)).Company != ld.Company || (oldMap.get(ld.Id)).Email != ld.Email || (oldMap.get(ld.Id)).Country != ld.Country))))
            {
                if(processStage != null && processStage.Bypass_Enrichment_Process__c == true)
                {
                    ld.SystemsProcessBypass__c = 'Bypass Enrichment';
                    ld.Systems_process_enrichment_bypass__c = 'Custom Setting Bypass';
                }
                else  if(((ld.CreatedById != null && ld.CreatedById == processStage.Gating_Type_BT_API_Lead__c) || UserInfo.getUserId() == processStage.Gating_Type_BT_API_Lead__c))
                {
                    ld.SystemsProcessBypass__c = 'Bypass Enrichment';
                    ld.Systems_process_enrichment_bypass__c = 'Business Rule';
                }
                else if(Trigger.isInsert && (ld.Marketo_enriched_date_time__c != null && fakeMarketoDate != null && ld.Marketo_enriched_date_time__c.date() == fakeMarketoDate.date())){
                    ld.SystemsProcessBypass__c = 'Bypass Enrichment';
                    ld.Systems_process_enrichment_bypass__c = 'Exclusions';
                }

                //Enrichment Exclusion - Lead source & company
                if(processStage != null && ld.LeadSource != null && processStage.Gating_Excluded_Lead_Sources__c != null && processStage.Gating_Excluded_Lead_Sources__c.containsIgnoreCase(ld.LeadSource))
                {
                    ld.SystemsProcessBypass__c = 'Bypass Enrichment';
                    ld.Systems_process_enrichment_bypass__c = 'Exclusions';
                }

                if(processStage != null && ld.Company != null && excludedCompanies != null)
                {
                    for(String company:excludedCompanies) {
                        if(ld.Company.containsIgnoreCase(company)){
                            ld.SystemsProcessBypass__c = 'Bypass Enrichment';
                            ld.Systems_process_enrichment_bypass__c = 'Exclusions';
                            break;
                        }
                    }
                }

                if(processStage != null && ld.Lead_Entry_Source__c != null && excludedLeadEntrySources != null)
                {
                    for(String leadEntrySource:excludedLeadEntrySources) {
                        if(ld.Lead_Entry_Source__c.containsIgnoreCase(leadEntrySource)){
                            ld.SystemsProcessBypass__c = 'Bypass Enrichment';
                            ld.Systems_process_enrichment_bypass__c = 'Exclusions';
                            break;
                        }
                    }
                }

                //Enrichment Exclusion - Domains
                if(processStage != null && ld.Email != null && excludedDomains != null)
                {
                    for(String domain:excludedDomains)
                    {
                        if(ld.Email.containsIgnoreCase(domain))
                        {
                            ld.SystemsProcessBypass__c = 'Bypass Enrichment';
                            ld.Systems_process_enrichment_bypass__c = 'Exclusions';
                            break;
                        }
                    }
                }
        	}
        }
        } catch (Exception ex) {
            LeadPlatEvents.leadExceptionCreationAsync(new Exception[]{ex},'populateLeadEnrichmentExclusion');
            throw ex;
        }
        system.debug('populateLeadEnrichmentExclusion end time - ' + limits.getCpuTime());
    }
    //Logic to populate Last Leadspace Activity Date on leads to LS Enrichment Date
    public static void populateLSEnrichmentDate(List<Lead> lstLead, Map<Id, Lead> oldMap) {
        system.debug('populateLSEnrichmentDate start time - ' + limits.getCpuTime());
        Leadspace_field_bypass__c LSField = Leadspace_field_bypass__c.getInstance();
        try {
            for (Lead l : lstLead) {
                if (((l.Enrichment_Last_Processed_Date__c != null && LSField.Bypass_Lead_Fields__c == true)) && ((Trigger.isInsert) || (oldMap.get(l.Id).Enrichment_Last_Processed_Date__c != l.Enrichment_Last_Processed_Date__c))) {
                    l.LS_Enrichment_Date__c = l.Enrichment_Last_Processed_Date__c.date();
                }
            }
        } catch (Exception ex) {
            LeadPlatEvents.leadExceptionCreationAsync(new Exception[]{
                ex
            }, 'populateLSEnrichmentDate');
            throw ex;
        }
        system.debug('populateLSEnrichmentDate end time - ' + limits.getCpuTime());
    }

    //Logic to populate ZI CPD Match
    public static void populateZICDPMatch(List<Lead> lstLead, Map<Id, Lead> oldMap) {
    system.debug('populateZICDPMatch start time - ' + limits.getCpuTime());
        Set<String> setZIIds = new Set<String>();
        Set<String> setZICDPMatchIds = new Set<String>();
        Map<String, Id> mapLeadAccountIds = new Map<String, Id>();
        Map<String, Id> mapLeadCDPAccountIds = new Map<String, Id>();
        Leadspace_field_bypass__c LSField = Leadspace_field_bypass__c.getInstance();
        if (LSField != null && LSField.Bypass_ZIId_Fallback__c == true) {
            return;
        }
        try {
            for (Lead l : lstLead) {
                if (l.ZI_Id__c != null && ((oldMap != null && (oldMap.get(l.Id).ZI_Id__c != l.ZI_Id__c)) || (Trigger.isInsert))) {
                    setZIIds.add(l.ZI_Id__c);
                }
                if (l.ZI_CDP_Match__c != null && ((oldMap != null && (oldMap.get(l.Id).ZI_CDP_Match__c != l.ZI_CDP_Match__c)) || (Trigger.isInsert))) {
                    setZICDPMatchIds.add(l.ZI_CDP_Match__c);
                }
            }

            if (setZIIds.size() > 0) {

                for (Account acc : [select id, ZI_CDP_Match__c, ZI_Id__c, ParentId from account where ZI_Id__c in :setZIIds AND RecordType.Name = 'ZI Customer Shell Account']) {
                    if (acc.ZI_Id__c != null) {
                        mapLeadAccountIds.put(acc.ZI_Id__c, acc.Id);
                    }
                }
                for (Lead l : lstLead) {
                    if (mapLeadAccountIds != null && mapLeadAccountIds.containsKey(l.ZI_Id__c)) {
                        l.ZI_CDP_Match__c = l.ZI_Id__c;
                        l.ZI_CDP_Account_Id__c = mapLeadAccountIds.get(l.ZI_Id__c);
                    }
                }
            }

            if (setZICDPMatchIds.size() > 0) {
                for (Account acc : [select id, ZI_CDP_Match__c, ZI_Id__c, ParentId from account where ZI_Id__c in :setZICDPMatchIds AND RecordType.Name = 'ZI Customer Shell Account']) {
                    if (acc.ZI_Id__c != null) {
                        mapLeadCDPAccountIds.put(acc.ZI_Id__c, acc.Id);
                    }
                }
                for (Lead l : lstLead) {
                    if (mapLeadCDPAccountIds != null && mapLeadCDPAccountIds.containsKey(l.ZI_CDP_Match__c)) {
                        l.ZI_Id__c = l.ZI_CDP_Match__c;
                        l.ZI_CDP_Account_Id__c = mapLeadCDPAccountIds.get(l.ZI_CDP_Match__c);
                    }
                }
            }
        } catch (Exception ex) {
            LeadPlatEvents.leadExceptionCreationAsync(new Exception[]{
                ex
            }, 'populateZIFieldsOnLead');
        }
    system.debug('populateZICDPMatch end time - ' + limits.getCpuTime());
    }

    //Logic to populate Segment Name on Lead
    public static void populateSegmentName(List<Lead> lstLead, Map<Id, Lead> oldMap) {
             system.debug('populateSegmentName start time - ' + limits.getCpuTime());
         try {
             Set<String> setCountryNames = new Set<String>();
             Set<Id> leadIds = new Set<Id>();
             Map<Id, Account> mapAccountIdNAccount = new Map<Id, Account>();
             Set<Decimal> setEmployeeNumbers = new Set<Decimal>();
             Map<String, List<Segment_Master__c>> mapCountryNameNLstSegmentMasters = new Map<String, List<Segment_Master__c>>();
             String ROWCountryName = 'ROW';
             String SMCountryName = '';
             String bypassValue = '';
             Decimal SMEmployees;
             String nonAvayaUsers = System.Label.Non_Avaya_Users;
             String [] listUsers = nonAvayaUsers.split(';');
             Gating_Process_Stage__c processStage = Gating_Process_Stage__c.getInstance();
             Boolean isUserMarketo = false;
             Boolean isZICDPUpdate = false;
             Map<Id, String> mapLeadProfiles = new Map<Id, String>();
             Set<Id> leadCreatedIds = new Set<Id>();
             ByPassTrigger__c bypassTrigger = ByPassTrigger__c.getInstance();
             if (bypassTrigger != null && bypassTrigger.Bypass_Resegmentation_Trigger_Logic__c == true) {
                 return;
             }
             Leadspace_field_bypass__c LSField = Leadspace_field_bypass__c.getInstance();

             for (Lead ld : lstLead) {
                 if(ld.Lead_Brand_Name__c!=null && System.Label.BizMerge_Brand_Exclusion_List!=null 
                 && System.Label.BizMerge_Brand_Exclusion_List.contains(ld.Lead_Brand_Name__c))//BizMerge-Added Brand Name check to exclude Gating Logic for ATT Leads
                 {
                    continue;
                 }
              		
                 if (processStage != null && (processStage.Bypass_Gating_Process_Stage__c == false || processStage.Bypass_Segmentation_Process__c == true) && (Trigger.isInsert && processStage.Bypass_Segmentation_Process__c == true)) {//Bypassing Segmentation logic while insertion in Gating scenarios
                     return;
                 }//Emp_Range_Sales_Override__c will sometimes have null or 0. So always use ld.Emp_Range_Sales_Override__c>0 check if for not null and !(ld.Emp_Range_Sales_Override__c>0) for null
                     if(ld.SM_Country__c != null && ld.SM_Employees__c != null && (ld.ZI_CDP_Account_Id__c==null || (ld.ZI_CDP_Account_Id__c!=null && ld.Emp_Range_Sales_Override__c>0)) && ld.isConverted == false && ((Trigger.isInsert) || (oldMap!=null && ((oldMap.get(ld.Id)).ZI_Company_Country__c!= ld.ZI_Company_Country__c || (oldMap.get(ld.Id)).VD_Country__c != ld.VD_Country__c || (oldMap.get(ld.Id)).Employees_Override__c != ld.Employees_Override__c || ((oldMap.get(ld.Id)).Country != ld.Country && processStage != null && processStage.Bypass_Gating_Process_Stage__c==true) || ((oldMap.get(ld.Id)).Country__c != ld.Country__c) || (oldMap.get(ld.Id)).Emp_Range_Sales_Override__c!= ld.Emp_Range_Sales_Override__c || (oldMap.get(ld.Id)).ZI_Employees__c!= ld.ZI_Employees__c || (oldMap.get(ld.Id)).LS_Company_Size__c!= ld.LS_Company_Size__c || (oldMap.get(ld.Id)).NumberOfEmployees!= ld.NumberOfEmployees || (oldMap.get(ld.Id)).NumberOfEmployees__c!= ld.NumberOfEmployees__c || (oldMap.get(ld.Id)).ZI_CDP_Account_Id__c!= ld.ZI_CDP_Account_Id__c || ((oldMap.get(ld.Id)).Systems_Process_Stage__c!= ld.Systems_Process_Stage__c && ((ld.Systems_Process_Stage__c == 'SFDC enriched' || ld.Systems_Process_Stage__c == 'Marketo enriched') || ((ld.Systems_Process_Stage__c == 'SFDC Updated' || ld.Systems_Process_Stage__c == 'Manual SFDC updated') && ld.Systems_process_enrichment_bypass__c == 'Exclusions')) && (ld.Systems_Process_Stage__c!='SFDC Created' || ld.Systems_Process_Stage__c!='Marketo Created') && processStage.Bypass_Gating_Process_Stage__c == false) || ((oldMap.get(ld.Id)).SystemsProcessBypass__c!= ld.SystemsProcessBypass__c && ld.SystemsProcessBypass__c == 'Bypass Enrichment' && processStage.Bypass_Gating_Process_Stage__c == false)))))//Triggering Segmentation logic when updating key fields and also after SFDC enriched or Bypass Enrichment
                     {
                         ld.Segment_Request_Time__c = System.now();
                         if(ld.ZI_CDP_Account_Id__c!=null && !(ld.Emp_Range_Sales_Override__c>0))//Resegmentation should not happen when updating ZI CDP Account and it should update when emp sales override gets updated even when zi cdp value is there
                         {
                             isZICDPUpdate=true;
                         }
                         else
                         {
                             isZICDPUpdate=false;
                         }
                         if(ld.ZI_CDP_Account_Id__c!=null && ld.Ultimate_SM_Country__c != null)
                         {
                             setCountryNames.add(ld.Ultimate_SM_Country__c);
                         }
                         else if(ld.ZI_CDP_Account_Id__c==null)
                         {
                             setCountryNames.add(ld.SM_Country__c);
                         }
                         if(ld.ZI_CDP_Account_Id__c!=null && ld.Ultimate_SM_Employees__c!=null && ld.Ultimate_SM_Employees__c > 1 && !(ld.Emp_Range_Sales_Override__c>0))
                         {
                             setEmployeeNumbers.add(ld.Ultimate_SM_Employees__c);
                         }
                         else if(ld.ZI_CDP_Account_Id__c==null || (ld.Emp_Range_Sales_Override__c>0))//Emp_Range_Sales_Override__c will sometimes have null or 0. So always use ld.Emp_Range_Sales_Override__c>0 check if for not null and !(ld.Emp_Range_Sales_Override__c>0) for null
                         {
                             if(oldMap!=null && (ld.Emp_Range_Sales_Override__c>0) && (oldMap.get(ld.Id)).Emp_Range_Sales_Override__c!= ld.Emp_Range_Sales_Override__c)
                             {
                                 setEmployeeNumbers.add(ld.Emp_Range_Sales_Override__c);
                             }
                             else if(oldMap!=null && !(ld.Emp_Range_Sales_Override__c>0) && ld.Ultimate_SM_Employees__c!=null && (oldMap.get(ld.Id)).Ultimate_SM_Employees__c!= ld.Ultimate_SM_Employees__c)
                             {
                                 setEmployeeNumbers.add(ld.Ultimate_SM_Employees__c);
                             }
                             else if(oldMap!=null && !(ld.Emp_Range_Sales_Override__c>0) && ld.Ultimate_SM_Employees__c==null && ld.ZI_Employees__c!=null && (oldMap.get(ld.Id)).ZI_Employees__c!= ld.ZI_Employees__c)
                             {
                                 setEmployeeNumbers.add(ld.ZI_Employees__c);
                             }
                             else if(oldMap!=null && !(ld.Emp_Range_Sales_Override__c>0) && ld.Ultimate_SM_Employees__c==null && ld.ZI_Employees__c==null && ld.LS_Company_Size__c!=null && (oldMap.get(ld.Id)).LS_Company_Size__c!= ld.LS_Company_Size__c)
                             {
                                 setEmployeeNumbers.add(ld.LS_Company_Size__c);
                             }
                             else if(oldMap!=null && !(ld.Emp_Range_Sales_Override__c>0) && ld.Ultimate_SM_Employees__c==null && ld.ZI_Employees__c==null && ld.LS_Company_Size__c==null && ld.NumberOfEmployees!=null && (oldMap.get(ld.Id)).NumberOfEmployees!= ld.NumberOfEmployees)
                             {
                                 setEmployeeNumbers.add(ld.NumberOfEmployees);
                             }
                             else
                             {
                                 setEmployeeNumbers.add(ld.SM_Employees__c);
                             }
                         }
                         if(Trigger.isUpdate && processStage != null && processStage.Bypass_Gating_Process_Stage__c == false && processStage.Bypass_Segmentation_Process__c == false && (ld.Systems_Process_Stage__c != 'SFDC enriched' && ld.Systems_Process_Stage__c != 'Marketo enriched') && (ld.Systems_Process_Stage__c!='SFDC created' && ld.Systems_Process_Stage__c!='Marketo created') && (ld.Systems_Process_Stage__c!='SFDC updated' && ld.Systems_Process_Stage__c!='Manual SFDC updated') && ((oldMap.get(ld.Id)).SystemsProcessBypass__c == ld.SystemsProcessBypass__c) && (ld.ZI_CDP_Account_Id__c==null || ld.Emp_Range_Sales_Override__c != null) && isZICDPUpdate==false)//Updating to SFDC Updated only when key fields and SFDC stage is not immediately after created are updated and also updated time
                         {
                             ld.Systems_Process_Stage__c = 'SFDC updated';
                             ld.SFDC_updated_via_Enrichment__c = false;
                             ld.SystemsProcessBypass__c = null;
                             ld.Systems_process_segmentation_bypass__c = null;
                             ld.Systems_process_routing_bypass__c = null;
                             if(processStage != null && processStage.Bypass_Gating_Nullifying_Datetime__c == true)
                             {
                                 ld.Segment_complete_date_time__c = null;
                                 ld.Route_complete_date_time__c = null;
                             }
                             ld.SFDC_updated_date_time__c = System.now();
                         }
                         if(Trigger.isUpdate && processStage.Bypass_Gating_Process_Stage__c == true && (ld.Systems_Process_Stage__c != 'SFDC enriched' && ld.Systems_Process_Stage__c != 'Marketo enriched') && ld.SystemsProcessBypass__c != 'Bypass Enrichment' && (ld.ZI_CDP_Account_Id__c==null || ld.Emp_Range_Sales_Override__c != null) && UserInfo.getUserId()!=listUsers[0] &&
                            (oldMap!=null && ((((oldMap.get(ld.Id)).LS_Status__c!= ld.LS_Status__c && ld.LS_Status__c!='Success') || (oldMap.get(ld.Id)).LS_Status__c== ld.LS_Status__c && LSField.Bypass_Lead_Fields__c==true))))//Updating SFDC updated time when key fields are updated for normal/non-gating scenario. Added check for Leadspace success because sfdc updated time need not be updated after enrichment
                         {
                             ld.SFDC_updated_date_time__c = System.now();
                         }
                         if((processStage != null && processStage.Bypass_Gating_Process_Stage__c == true) || (processStage.Bypass_Enrichment_Process__c == true && processStage.Bypass_Segmentation_Process__c == false) || (Trigger.isInsert && ld.Marketo_enriched_date_time__c != null && ld.Systems_Process_Stage__c == 'Marketo enriched') || (Trigger.isInsert && (ld.Lead_Created_via_Smart_Search__c || (ld.SystemsProcessBypass__c=='Bypass Enrichment' && (ld.Systems_process_enrichment_bypass__c=='Exclusions' || ld.Systems_process_enrichment_bypass__c=='Business Rule' || ld.Systems_process_enrichment_bypass__c=='Custom Setting Bypass')))))//Updating isMarketoUser flag to true to skip async call and calculate segment name immediately
                         {
                             isUserMarketo=true;
                         }
                         if(isZICDPUpdate==false)
                         {
                         	leadIds.add(ld.Id);
                         }
                         leadCreatedIds.add(UserInfo.getUserId());
                     }
                 }
                 if(setCountryNames.size()>0 && setEmployeeNumbers.size()>0)
                 {
                     if((Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()) && isUserMarketo==false && leadIds.size()>0 && setCountryNames.size()>0 && setEmployeeNumbers.size()>0 && oldMap!=null)//LeadSegmentNameQueuable will be only called for Gating scenario where SegmentName will be calculated asynchronously so that SFDC enriched State will updated explicitly and can be seen in Field Tracking History
                     {
                         System.enqueueJob(new LeadSegmentNameQueuable(leadIds,setCountryNames,setEmployeeNumbers,oldMap));
                     }
                     else//Else block is for synchronous segmentation calcuation for non-gating leads
                     {
                         List<Segment_Master__c> segmentMasterList = [SELECT Id, Country__c, Max__c, Min__c, Name FROM Segment_Master__c where (Country__c in :setCountryNames or Country__c =: ROWCountryName) AND Min__c <= :setEmployeeNumbers AND Max__c >= :setEmployeeNumbers AND Active__c = true];
                         for(Segment_Master__c sm:segmentMasterList)
                         {
                             if(mapCountryNameNLstSegmentMasters.containskey(sm.country__c))
                             {
                                 mapCountryNameNLstSegmentMasters.get(sm.country__c).add(sm);
                             }
                             else
                             {
                                 mapCountryNameNLstSegmentMasters.put(sm.country__c,new List<Segment_Master__c> {sm});
                             }
                         }
                         if (leadCreatedIds.size() > 0) {
                             List<User> userList = (List<User>) USER_CACHE.retrieveList(leadCreatedIds);
                             for (User u : userList) {
                                 mapLeadProfiles.put(u.id, u.profile.name);
                             }
                         }
                         for (Lead ld : lstLead)
                         {
                             if(ld.SM_Country__c != null && ld.SM_Employees__c != null && ld.isConverted == false)
                             {
                                 if(ld.ZI_CDP_Account_Id__c!=null && mapCountryNameNLstSegmentMasters.containskey(ld.Ultimate_SM_Country__c))
                                 {
                                     SMCountryName = ld.Ultimate_SM_Country__c;
                                 }
                                 else if(mapCountryNameNLstSegmentMasters.containskey(ld.SM_Country__c))
                                 {
                                     SMCountryName = ld.SM_Country__c;
                                 }
                                 else
                                 {
                                     SMCountryName = ROWCountryName;
                                 }
                                 if(ld.ZI_CDP_Account_Id__c!=null && ld.Ultimate_SM_Employees__c!=null && ld.Ultimate_SM_Employees__c > 1 && ld.Emp_Range_Sales_Override__c == null)//Emp_Range_Sales_Override__c will sometimes have null or 0. So always use ld.Emp_Range_Sales_Override__c>0 check if for not null and !(ld.Emp_Range_Sales_Override__c>0) for null
                                 {
                                     SMEmployees=ld.Ultimate_SM_Employees__c;
                                 }
                                 else
                                 {
                                     if(oldMap!=null && (ld.Emp_Range_Sales_Override__c>0) && (oldMap.get(ld.Id)).Emp_Range_Sales_Override__c!= ld.Emp_Range_Sales_Override__c)
                                     {
                                         SMEmployees=ld.Emp_Range_Sales_Override__c;
                                     }
                                     else if(oldMap!=null && !(ld.Emp_Range_Sales_Override__c>0) && ld.Ultimate_SM_Employees__c!=null && (oldMap.get(ld.Id)).Ultimate_SM_Employees__c!= ld.Ultimate_SM_Employees__c)
                                     {
                                         SMEmployees=ld.Ultimate_SM_Employees__c;
                                     }
                                     else if(oldMap!=null && !(ld.Emp_Range_Sales_Override__c>0) && ld.Ultimate_SM_Employees__c==null && ld.ZI_Employees__c!=null && (oldMap.get(ld.Id)).ZI_Employees__c!= ld.ZI_Employees__c)
                                     {
                                         SMEmployees=ld.ZI_Employees__c;
                                     }
                                     else if(oldMap!=null && !(ld.Emp_Range_Sales_Override__c>0) && ld.Ultimate_SM_Employees__c==null && ld.ZI_Employees__c==null && ld.LS_Company_Size__c!=null && (oldMap.get(ld.Id)).LS_Company_Size__c!= ld.LS_Company_Size__c)
                                     {
                                         SMEmployees=ld.LS_Company_Size__c;
                                     }
                                     else if(oldMap!=null && !(ld.Emp_Range_Sales_Override__c>0) && ld.Ultimate_SM_Employees__c==null && ld.ZI_Employees__c==null && ld.LS_Company_Size__c==null && ld.NumberOfEmployees!=null && (oldMap.get(ld.Id)).NumberOfEmployees!= ld.NumberOfEmployees)
                                     {
                                         SMEmployees=ld.NumberOfEmployees;
                                     }
                                     else
                                     {
                                         SMEmployees=ld.SM_Employees__c;
                                     }
                                 }
                                 if(mapCountryNameNLstSegmentMasters.containskey(SMCountryName))
                                 {
                                     for(Segment_Master__c sm : (List<Segment_Master__c>) mapCountryNameNLstSegmentMasters.get(SMCountryName))
                                     {
                                         if(((Trigger.isInsert && (ld.Lead_Created_via_Smart_Search__c || (ld.SystemsProcessBypass__c=='Bypass Enrichment' && (ld.Systems_process_enrichment_bypass__c=='Exclusions' || ld.Systems_process_enrichment_bypass__c=='Business Rule' || ld.Systems_process_enrichment_bypass__c=='Custom Setting Bypass')))) || (processStage != null && processStage.Bypass_Gating_Process_Stage__c == true) || (Trigger.isInsert && ld.Marketo_enriched_date_time__c != null && ld.Systems_Process_Stage__c == 'Marketo enriched') || (Trigger.isUpdate && ld.Systems_Process_Stage__c == 'SFDC enriched')) && sm.Country__c != null && sm.Min__c != null && sm.Max__c!= null && SMEmployees != null && sm.Max__c >= SMEmployees && sm.Min__c <= SMEmployees)
                                         {
                                             if(ld.SegmentName__c != sm.Id)
                                             {
                                                 ld.SegmentName__c = sm.Id;
                                             }
                                             if(ld.Marketo_Segment_Name__c != sm.Name)
                                             {
                                                 ld.Marketo_Segment_Name__c = sm.Name;
                                             }
                                             if((Trigger.isInsert && processStage != null && processStage.Bypass_Gating_Process_Stage__c == false && (!ld.Lead_Created_via_Smart_Search__c || (ld.SystemsProcessBypass__c=='Bypass Enrichment' && (ld.Systems_process_enrichment_bypass__c=='Exclusions' || ld.Systems_process_enrichment_bypass__c=='Business Rule' || ld.Systems_process_enrichment_bypass__c=='Custom Setting Bypass')))) || (Trigger.isUpdate && processStage != null && processStage.Bypass_Gating_Process_Stage__c == false && processStage.Bypass_Segmentation_Process__c == false && ld.Systems_Process_Stage__c!='Route complete') || (Trigger.isInsert && processStage != null && processStage.Bypass_Gating_Process_Stage__c == false && processStage.Bypass_Enrichment_Process__c == true && processStage.Bypass_Segmentation_Process__c == false && ld.Systems_Process_Stage__c!='Route complete') || (Trigger.isInsert && ld.Marketo_enriched_date_time__c != null && ld.Systems_Process_Stage__c=='Marketo enriched')){/*CMR-347884: Production CDI Gating Phase 2 Additional CR's*/
                                             ld.Systems_Process_Stage__c='Segment complete';
                                             ld.Segment_complete_date_time__c=System.now();
                                             if(Trigger.isInsert && UserInfo.getUserId()==listUsers[0] && ld.Bypass_Routing__c)
                                             {
                                                 ld.SystemsProcessBypass__c='Bypass Routing';
                                                 ld.Systems_process_routing_bypass__c = 'Non LDQ Owner';
                                             }
                                             }
                                             if(processStage != null && processStage.Bypass_Gating_Process_Stage__c == false && (ld.Systems_Process_Stage__c=='Segment complete' || ld.SystemsProcessBypass__c=='Bypass Segmentation') && (processStage.Bypass_Enrichment_Process__c == true || (ld.SystemsProcessBypass__c=='Bypass Enrichment' && (ld.Systems_process_enrichment_bypass__c=='Exclusions' || ld.Systems_process_enrichment_bypass__c=='Business Rule' || ld.Systems_process_enrichment_bypass__c=='Custom Setting Bypass'))) && processStage.Bypass_Segmentation_Process__c == false && ((ld.Lead_Created_via_Smart_Search__c && mapLeadProfiles != null && ( (mapLeadProfiles.containsKey(ld.CreatedById) && mapLeadProfiles.get(ld.CreatedById) !='System Administrator') ||  (mapLeadProfiles.containsKey(UserInfo.getUserId()) && mapLeadProfiles.get(UserInfo.getUserId()) !='System Administrator') ))))
                                             {
                                                 ld.SystemsProcessBypass__c='Bypass Routing';
                                                 if(ld.SystemsProcessBypass__c=='Bypass Enrichment' && (ld.Systems_process_enrichment_bypass__c=='Exclusions' || ld.Systems_process_enrichment_bypass__c=='Business Rule' || ld.Systems_process_enrichment_bypass__c=='Custom Setting Bypass')) {
                                                     ld.Systems_process_routing_bypass__c = 'Non LDQ Owner';
                                                 } else {
                                                     ld.Systems_process_routing_bypass__c = 'Business Rule';
                                                 }
                                             }
                                         }
                                     }
                                 }
                             }
                         }
                     }
                 }
         } catch(Exception ex) {
             LeadPlatEvents.leadExceptionCreationAsync(new Exception[]{ex},'populateSegmentName');
             throw ex;
         }
         system.debug('populateSegmentName end time - ' + limits.getCpuTime());
    }
      //Logic to populate Ultimate SM Country and Employee on Lead
        public static void populateUltimateSMCountryEmp(List<Lead> lstLead, Map<Id,Lead> oldMap) {
            system.debug('populateUltimateSMCountryEmp start time - ' + limits.getCpuTime());
            try {
                Set<Id> accountIds = new Set<Id>();
                Set<Id> leadIds = new Set<Id>();
                Map<Id,String> mapUltimateSMCountry = new Map<Id,String>();
                Map<Id,Double> mapUltimateSMEmp = new Map<Id,Double>();
                /*CMR-224923:E2EStaging - Lead Refactoring & Customer Data Updates*/
                Map<Id,String> mapUltimateSegmentName = new Map<Id,String>();
                Map<Id,String> mapUltimateMarketoSegmentName = new Map<Id,String>();
                String nonAvayaUsers = System.Label.Non_Avaya_Users;
        		String [] listUsers = nonAvayaUsers.split(';');
                Boolean isUserMarketo = false;
                Gating_Process_Stage__c processStage = Gating_Process_Stage__c.getInstance();
                if (processStage != null && processStage.Bypass_Gating_Process_Stage__c == true) {
                    isUserMarketo=true;
                }
                ByPassTrigger__c bypassTrigger = ByPassTrigger__c.getInstance();
                if (bypassTrigger != null && bypassTrigger.Bypass_Resegmentation_Trigger_Logic__c == true) {
                    return;
                }
                Leadspace_field_bypass__c LSField = Leadspace_field_bypass__c.getInstance();
                for(Lead ld : lstLead)
                {
                    if(ld.Lead_Brand_Name__c!=null && System.Label.BizMerge_Brand_Exclusion_List!=null
                     && System.Label.BizMerge_Brand_Exclusion_List.contains(ld.Lead_Brand_Name__c))//BizMerge-Added Brand Name check to exclude Gating Logic for ATT Leads
                     {
                        continue;
                     }
              		
                    if(processStage != null && (processStage.Bypass_Gating_Process_Stage__c == false || processStage.Bypass_Segmentation_Process__c == true) && (Trigger.isInsert && processStage.Bypass_Segmentation_Process__c == true)) {//Bypassing Segmentation logic while insertion in Gating scenarios
                    return;
                	}
                    if(ld.ZI_CDP_Account_Id__c != null && !(ld.Emp_Range_Sales_Override__c>0) && ld.isConverted == false && ((Trigger.isInsert) || (oldMap!=null && ((oldMap.get(ld.Id)).ZI_Company_Country__c!= ld.ZI_Company_Country__c || (oldMap.get(ld.Id)).VD_Country__c != ld.VD_Country__c || (oldMap.get(ld.Id)).Employees_Override__c != ld.Employees_Override__c || ((oldMap.get(ld.Id)).Country != ld.Country && processStage != null && processStage.Bypass_Gating_Process_Stage__c==true) || ((oldMap.get(ld.Id)).Country__c != ld.Country__c && processStage != null && processStage.Bypass_Gating_Process_Stage__c==true) || (oldMap.get(ld.Id)).Emp_Range_Sales_Override__c!= ld.Emp_Range_Sales_Override__c || (oldMap.get(ld.Id)).ZI_Employees__c!= ld.ZI_Employees__c || (oldMap.get(ld.Id)).LS_Company_Size__c!= ld.LS_Company_Size__c || (oldMap.get(ld.Id)).NumberOfEmployees!= ld.NumberOfEmployees || (oldMap.get(ld.Id)).NumberOfEmployees__c!= ld.NumberOfEmployees__c || (oldMap.get(ld.Id)).ZI_CDP_Account_Id__c!= ld.ZI_CDP_Account_Id__c || ((oldMap.get(ld.Id)).Systems_Process_Stage__c!= ld.Systems_Process_Stage__c && ((ld.Systems_Process_Stage__c == 'SFDC enriched' || ld.Systems_Process_Stage__c == 'Marketo enriched') || ((ld.Systems_Process_Stage__c == 'SFDC Updated' || ld.Systems_Process_Stage__c == 'Manual SFDC updated') && ld.Systems_process_enrichment_bypass__c == 'Exclusions')) &&  (ld.Systems_Process_Stage__c!='SFDC Created' || ld.Systems_Process_Stage__c!='Marketo Created') && processStage.Bypass_Gating_Process_Stage__c == false) || ((oldMap.get(ld.Id)).SystemsProcessBypass__c!= ld.SystemsProcessBypass__c && ld.SystemsProcessBypass__c == 'Bypass Enrichment' && processStage.Bypass_Gating_Process_Stage__c == false)))))
                    {
                        ld.Segment_Request_Time__c = System.now();
                        accountIds.add(ld.ZI_CDP_Account_Id__c);
                        leadIds.add(ld.Id);
                    }
                    else if(ld.ZI_CDP_Account_Id__c == null && ld.isConverted == false && ((Trigger.isInsert) || (oldMap!=null && ((oldMap.get(ld.Id)).ZI_CDP_Account_Id__c!= ld.ZI_CDP_Account_Id__c))))
                    {
                        ld.Ultimate_SM_Country__c=null;
                        ld.Ultimate_SM_Employees__c=null;
                    }
                    if(Trigger.isUpdate && ld.ZI_CDP_Account_Id__c != null && leadIds.size()>0 && accountIds.size()>0 && processStage != null && processStage.Bypass_Gating_Process_Stage__c == false && processStage.Bypass_Segmentation_Process__c == false && (ld.Systems_Process_Stage__c != 'SFDC enriched' && ld.Systems_Process_Stage__c != 'Marketo enriched') && (ld.Systems_Process_Stage__c!='SFDC created' && ld.Systems_Process_Stage__c!='Marketo created') && (ld.Systems_Process_Stage__c!='SFDC updated' && ld.Systems_Process_Stage__c!='Manual SFDC updated') && ((oldMap.get(ld.Id)).SystemsProcessBypass__c == ld.SystemsProcessBypass__c))//Updating to SFDC Updated only when key fields are updated and also updated time
                    {
                        ld.Systems_Process_Stage__c = 'SFDC updated';
                        ld.SFDC_updated_via_Enrichment__c = false;
                        ld.SystemsProcessBypass__c = null;
                        ld.Systems_process_segmentation_bypass__c = null;
                        ld.Systems_process_routing_bypass__c = null;
                        if(processStage != null && processStage.Bypass_Gating_Nullifying_Datetime__c == true)
                        {
                            ld.Segment_complete_date_time__c = null;
                            ld.Route_complete_date_time__c = null;
                        }
                        ld.SFDC_updated_date_time__c = System.now();
                    }
                    if(Trigger.isUpdate && processStage.Bypass_Gating_Process_Stage__c == true && leadIds.size()>0 && accountIds.size()>0 && (ld.Systems_Process_Stage__c != 'SFDC enriched' && ld.Systems_Process_Stage__c != 'Marketo enriched') && ld.SystemsProcessBypass__c != 'Bypass Enrichment' &&
                       (oldMap!=null && ((((oldMap.get(ld.Id)).LS_Status__c!= ld.LS_Status__c && ld.LS_Status__c!='Success') || (oldMap.get(ld.Id)).LS_Status__c== ld.LS_Status__c && LSField.Bypass_Lead_Fields__c==true))))//Updating SFDC updated time when key fields are updated for normal/non-gating scenario. Added check for Leadspace success because sfdc updated time need not be updated after enrichment
                    {
                        ld.SFDC_updated_date_time__c = System.now();
                    }
                    if((processStage != null && processStage.Bypass_Gating_Process_Stage__c == true) || (processStage.Bypass_Enrichment_Process__c == true && processStage.Bypass_Segmentation_Process__c == false) || (Trigger.isInsert && ld.Marketo_enriched_date_time__c != null && ld.Systems_Process_Stage__c == 'Marketo enriched') || (Trigger.isInsert && (ld.Lead_Created_via_Smart_Search__c || (ld.SystemsProcessBypass__c=='Bypass Enrichment' && (ld.Systems_process_enrichment_bypass__c=='Exclusions' || ld.Systems_process_enrichment_bypass__c=='Business Rule' || ld.Systems_process_enrichment_bypass__c=='Custom Setting Bypass'))) ))//Updating isMarketoUser flag to true to skip async call and calculate segment name immediately
                    {
                        isUserMarketo=true;
                    }
                }
                if(accountIds.size()>0)
                {
                    for(Account acc : [select id,Name,Ultimate_Account__c,Ultimate_Account__r.SM_Country__c,Ultimate_Account__r.SM_Employees__c,Ultimate_Account__r.Segment_Name__c,Ultimate_Account__r.Marketo_Segment_Name__c,SM_Country__c,SM_Employees__c,Segment_Name__c,Marketo_Segment_Name__c from account where Id in:accountIds])
                    {
                        if(acc.Ultimate_Account__c != null)
                        {
                            mapUltimateSMCountry.put(acc.Id,acc.Ultimate_Account__r.SM_Country__c);
                            mapUltimateSMEmp.put(acc.Id,acc.Ultimate_Account__r.SM_Employees__c);
                            mapUltimateSegmentName.put(acc.Id,acc.Ultimate_Account__r.Segment_Name__c);
                            mapUltimateMarketoSegmentName.put(acc.Id,acc.Ultimate_Account__r.Marketo_Segment_Name__c);
                        }
                        else
                        {
                            mapUltimateSMCountry.put(acc.Id,acc.SM_Country__c);
                            mapUltimateSMEmp.put(acc.Id,acc.SM_Employees__c);
                            mapUltimateSegmentName.put(acc.Id,acc.Segment_Name__c);
                            mapUltimateMarketoSegmentName.put(acc.Id,acc.Marketo_Segment_Name__c);
                        }
                    }
                }
                if(mapUltimateSMCountry!=null && mapUltimateSMEmp!=null && mapUltimateSegmentName!=null && mapUltimateMarketoSegmentName!=null)
                {
                if((Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()) && isUserMarketo==false && leadIds.size()>0 && mapUltimateSMCountry!=null && mapUltimateSMEmp!=null && mapUltimateSegmentName!=null && mapUltimateMarketoSegmentName!=null && oldMap!=null)//LeadSegmentNameQueuable will be only called for Gating scenario where SegmentName will be calculated asynchronously so that SFDC enriched State will updated explicitly and can be seen in Field Tracking History
                {
                    System.enqueueJob(new UltimateLeadSegmentQueuable(leadIds,mapUltimateSMCountry,mapUltimateSMEmp,mapUltimateSegmentName,mapUltimateMarketoSegmentName,oldMap));
                }
                else
                {
                    for (Lead ld : (List<Lead>) Trigger.new)
                    {
                        if(((Trigger.isInsert && (ld.Lead_Created_via_Smart_Search__c || (ld.SystemsProcessBypass__c=='Bypass Enrichment' && (ld.Systems_process_enrichment_bypass__c=='Exclusions' || ld.Systems_process_enrichment_bypass__c=='Business Rule' || ld.Systems_process_enrichment_bypass__c=='Custom Setting Bypass')))) || (processStage != null && processStage.Bypass_Gating_Process_Stage__c == true) || (Trigger.isInsert && ld.Marketo_enriched_date_time__c != null && ld.Systems_Process_Stage__c == 'Marketo enriched') || (Trigger.isUpdate && ld.Systems_Process_Stage__c == 'SFDC enriched')) && ld.ZI_CDP_Account_Id__c != null)
                        {
                            if(mapUltimateSMCountry!=null && mapUltimateSMCountry.containskey(ld.ZI_CDP_Account_Id__c))
                            {
                                ld.Ultimate_SM_Country__c = mapUltimateSMCountry.get(ld.ZI_CDP_Account_Id__c);
                            }
                            if(mapUltimateSMEmp!=null && mapUltimateSMEmp.containskey(ld.ZI_CDP_Account_Id__c))
                            {
                                ld.Ultimate_SM_Employees__c = mapUltimateSMEmp.get(ld.ZI_CDP_Account_Id__c);
                            }
                            if(mapUltimateSegmentName!=null && mapUltimateSegmentName.containskey(ld.ZI_CDP_Account_Id__c))
                            {
                                ld.SegmentName__c = mapUltimateSegmentName.get(ld.ZI_CDP_Account_Id__c);
                            }
                            if(mapUltimateMarketoSegmentName!=null && mapUltimateMarketoSegmentName.containskey(ld.ZI_CDP_Account_Id__c))
                            {
                                ld.Marketo_Segment_Name__c = mapUltimateMarketoSegmentName.get(ld.ZI_CDP_Account_Id__c);
                            }//CMR-224923:E2EStaging - Lead Refactoring & Customer Data Updates ends
                            if((Trigger.isInsert && processStage != null && processStage.Bypass_Gating_Process_Stage__c == false && (!ld.Lead_Created_via_Smart_Search__c || (ld.SystemsProcessBypass__c=='Bypass Enrichment' && (ld.Systems_process_enrichment_bypass__c=='Exclusions' || ld.Systems_process_enrichment_bypass__c=='Business Rule' || ld.Systems_process_enrichment_bypass__c=='Custom Setting Bypass')))) || (Trigger.isUpdate && processStage != null && processStage.Bypass_Gating_Process_Stage__c == false && processStage.Bypass_Segmentation_Process__c == false && ld.Systems_Process_Stage__c!='Route complete') || (Trigger.isInsert && processStage != null && processStage.Bypass_Gating_Process_Stage__c == false && processStage.Bypass_Enrichment_Process__c == true && processStage.Bypass_Segmentation_Process__c == false && ld.Systems_Process_Stage__c!='Route complete') || (Trigger.isInsert && ld.Marketo_enriched_date_time__c != null && ld.Systems_Process_Stage__c=='Marketo enriched') ){
                            ld.Systems_Process_Stage__c='Segment complete';
                            ld.Segment_complete_date_time__c=System.now();
                                if(Trigger.isInsert && UserInfo.getUserId()==listUsers[0] && ld.Bypass_Routing__c)
                                {
                                    ld.SystemsProcessBypass__c='Bypass Routing';
                                    ld.Systems_process_routing_bypass__c = 'Non LDQ Owner';
                                }
                            }
                        }
                    }
                }
                }
            } catch(Exception ex) {
                LeadPlatEvents.leadExceptionCreationAsync(new Exception[]{ex},'populateUltimateSMCountryEmp');
                throw ex;
            }
            system.debug('populateUltimateSMCountryEmp end time - ' + limits.getCpuTime());
    }

    //Start of SaaSquatch Logic
    //Logic to populate SaaSquatch Referral Email Id on lead
    public static void populateSaaSquatchReferralEmailIdOnLead(List<lead> lstLead, Map<Id, Lead>oldMap) {
        system.debug('populateSaaSquatchReferralEmailIdOnLead start time - ' + limits.getCpuTime());
        try {

            for (lead l : lstLead) {

                if ((l.Email != null && (l.Saasquatch_Advocate_Name__c != null || l.Saasquatch_Advocate_ID__c != null)) && ((Trigger.isInsert) || (oldMap != null && (oldMap.get(l.Id).Saasquatch_Advocate_Name__c == null || oldMap.get(l.Id).Saasquatch_Advocate_ID__c == null || l.Email != oldMap.get(l.Id).Email)))) {
                    l.Saasquatch_Referral_Email_ID__c = l.Email;
                }

                if (oldMap != null && ((oldMap.get(l.Id).Saasquatch_Advocate_Name__c != l.Saasquatch_Advocate_Name__c && l.Saasquatch_Advocate_Name__c == null) || (oldMap.get(l.Id).Saasquatch_Advocate_ID__c != l.Saasquatch_Advocate_ID__c && l.Saasquatch_Advocate_ID__c == null))) {
                    l.Saasquatch_Referral_Email_ID__c = null;
                }

            }
        } catch (Exception e) {
            ExceptionHelper.createExceptionAndNotificacionHistory(e, lstLead, 'Lead Exception');
        }
        system.debug('populateSaaSquatchReferralEmailIdOnLead end time - ' + limits.getCpuTime());
    }

    //CMR-237659
    //Logic to populate SaaSquatch Advocate Email Id and Advocate Id on lead
    public static void populateSaaSquatchAdvocateFieldsOnlead(List<lead> lstLead, Map<Id, Lead>oldMap) {
        system.debug('populateSaaSquatchAdvocateFieldsOnlead start time - ' + limits.getCpuTime());
        List<String> saasquatchAdvocateNameIds = new List<String>();
        List<Lead> leadsToMatch = new List<Lead>();
        try {

            for (lead l : lstLead) {

                if (l.Saasquatch_Advocate_Name__c != null && (Trigger.isInsert || (oldMap != null && l.Saasquatch_Advocate_Name__c != oldMap.get(l.Id).Saasquatch_Advocate_Name__c) || (oldMap != null && l.saasquatch_program_selector__c != oldMap.get(l.Id).saasquatch_program_selector__c))) {
                    saasquatchAdvocateNameIds.add(l.Saasquatch_Advocate_Name__c);
                }

                else if (l.Saasquatch_Advocate_Id__c != null && (Trigger.isInsert || (oldMap != null && (l.Saasquatch_Advocate_Id__c != oldMap.get(l.Id).Saasquatch_Advocate_Id__c || l.saasquatch_program_selector__c != oldMap.get(l.Id).saasquatch_program_selector__c)))) {
                    leadsToMatch.add(l);
                }
                if (l.Saasquatch_Advocate_Name__c == null && (oldMap != null && l.Saasquatch_Advocate_Name__c != oldMap.get(l.Id).Saasquatch_Advocate_Name__c)) {
                    l.Saasquatch_Advocate_ID__c = null;
                }

                else if (l.Saasquatch_Advocate_ID__c == null && (oldMap != null && l.Saasquatch_Advocate_ID__c != oldMap.get(l.Id).Saasquatch_Advocate_ID__c)) {
                    l.Saasquatch_Advocate_Name__c = null;
                }
            }

            if (saasquatchAdvocateNameIds.size() > 0) {
                
                List<ReferralProgramFieldMapping__mdt> programs = ReferralProgramFieldMapping__mdt.getAll().values();
                Map<String, ReferralProgramFieldMapping__mdt> programByPicklistValue = new Map<String, ReferralProgramFieldMapping__mdt>();

                for (ReferralProgramFieldMapping__mdt program: programs) {
                    programByPicklistValue.put(program.PicklistValueToMap__c, program);
                }

                List<saasquatch__SaaSquatch_User__c> users = (List<saasquatch__SaaSquatch_User__c>) new SaasquatchUserSelector()
                .selectUsersById(new List<Object> {saasquatchAdvocateNameIds})
                .executeQuery();

                Map<ID, saasquatch__SaaSquatch_User__c> userMap = new Map<ID, saasquatch__SaaSquatch_User__c>();

                if (users.size() > 0) {
                    for (saasquatch__SaaSquatch_User__c user : users) {
                        userMap.put(user.Id, user);
                    }
                }

                List<Lead> leadsWithSaasqCodeInUser = new List<Lead>();
                List<Lead> leadsWithSaasqCodeInContact = new List<Lead>();
                List<Id> leadsWithoutSaasqCode = new List<String>();

                List<String> contactsFromSaasqUserIds = new List<String>();
                for (lead l : lstLead) {
                    
                    boolean isSaasqCodeMapedToContact = false;
                    
                    if(!String.isBlank(l.saasquatch_program_selector__c)){
                        isSaasqCodeMapedToContact = programByPicklistValue.get(l.saasquatch_program_selector__c).isMapedToContact__c;
                    }

                    if(String.isBlank(l.saasquatch_program_selector__c) || !isSaasqCodeMapedToContact){
                        leadsWithSaasqCodeInUser.add(l);
                    }

                    else if(isSaasqCodeMapedToContact){
                        leadsWithSaasqCodeInContact.add(l);
                        contactsFromSaasqUserIds.add(userMap.get(l.Saasquatch_Advocate_Name__c).saasquatch__Contact__c);
                    }
                }
                for(lead l: leadsWithSaasqCodeInUser){
                    if(userMap.get(l.Saasquatch_Advocate_Name__c) != null){
                        String leadCode = userMap.get(l.Saasquatch_Advocate_Name__c).saasquatch__Referral_Code__c;
                        l.Saasquatch_Advocate_ID__c = leadCode;
                        if(leadCode == null){
                            leadsWithoutSaasqCode.add(l.id);
                        }
                    }
                }

                List<String> contactIds;
                String contactFieldWithSaasqCode;
                Saasquatch__SaaSquatch_User__c saasqUserFromContact = new Saasquatch__SaaSquatch_User__c();
                for(lead l: leadsWithSaasqCodeInContact){

                    List<Contact> contactsWithSaasqCode = (List<Contact>) new ContactSelector()
                    .selectContactsByIdsForSaasquatchReferralCode(new List<Object> {contactsFromSaasqUserIds})
                    .executeQuery();

                    Map<Id, Contact> contactsWithSaasqCodeMap = new Map<Id, Contact>();

                    if (contactsWithSaasqCode.size() > 0) {
                        for (Contact contact : contactsWithSaasqCode) {
                            contactsWithSaasqCodeMap.put(contact.Id, contact);
                        }
                    }

                    contactFieldWithSaasqCode = programByPicklistValue.get(l.saasquatch_program_selector__c).FieldAPIName__c;
                    
                    Id contactFromSaasqUser = userMap.get(l.Saasquatch_Advocate_Name__c).saasquatch__Contact__c;
                    
                    if(contactsWithSaasqCodeMap.get(contactFromSaasqUser) != null){
                        String leadCode = (String)(contactsWithSaasqCodeMap.get(contactFromSaasqUser)).get(contactFieldWithSaasqCode);
                        l.Saasquatch_Advocate_ID__c = leadCode;
                        
                        if(leadCode == null){
                            leadsWithoutSaasqCode.add(l.id);
                        }
                    }
                    else{
                        l.Saasquatch_Advocate_ID__c = null;
                        leadsWithoutSaasqCode.add(l.id);
                    }

                }
                if (!leadsWithoutSaasqCode.isEmpty()) {
                    sendEmailsSaasquatch(leadsWithoutSaasqCode, false);
                }
            }

            if (leadsToMatch.size() > 0) {
                List<Lead> leadsToMatchByUser = new List<Lead>();
                List<String> advocateIdsToMatchByUser = new List<String>();
                List<ReferralProgramFieldMapping__mdt> programs = ReferralProgramFieldMapping__mdt.getAll().values();
                Map<String, List<Lead>> programToLeadsMap = new Map<String, List<Lead>>();
                Map<String, ReferralProgramFieldMapping__mdt> programByPicklistValue = new Map<String, ReferralProgramFieldMapping__mdt>();

                for (ReferralProgramFieldMapping__mdt program: programs) {
                    if (program.isMapedToContact__c) {
                        programToLeadsMap.put(program.PicklistValueToMap__c, new List<Lead>());
                        programByPicklistValue.put(program.PicklistValueToMap__c, program);    
                    }
                }

                for (Lead ld : leadsToMatch) {
                    if (String.isBlank(ld.saasquatch_program_selector__c) ||
                        ld.saasquatch_program_selector__c == SAASQUATCH_DEFAULT_PROGRAM) {
                            leadsToMatchByUser.add(ld);
                            advocateIdsToMatchByUser.add(ld.Saasquatch_Advocate_ID__c);
                    } else {
                        List<Lead> leads = programToLeadsMap.get(ld.saasquatch_program_selector__c);
                        leads.add(ld);
                        programToLeadsMap.put(ld.saasquatch_program_selector__c, leads);
                    }
                }

                //Main and No Program 
                List<saasquatch__SaaSquatch_User__c> users = (List<saasquatch__SaaSquatch_User__c>) new SaasquatchUserSelector()
                    .selectUsersByReferralCode(new List<Object> {advocateIdsToMatchByUser})
                    .executeQuery();
                Map<String, saasquatch__SaaSquatch_User__c> userMap = new Map<String, saasquatch__SaaSquatch_User__c>();
                if (users.size() > 0) {
                    for (saasquatch__SaaSquatch_User__c user : users) {
                        userMap.put(user.saasquatch__Referral_Code__c, user);
                    }
                }
                for (Lead l : leadsToMatchByUser) {
                    if (userMap.containsKey(l.Saasquatch_Advocate_ID__c)) {
                        l.Saasquatch_Advocate_Name__c = userMap.get(l.Saasquatch_Advocate_ID__c).Id;
                    } else {
                        l.Saasquatch_Advocate_Name__c = null;
                    }

                }

                //Query based on Metadata
                List<String> leadsUnmatched = new List<String>();
                users = new List<saasquatch__SaaSquatch_User__c>();
                userMap = new Map<String, saasquatch__SaaSquatch_User__c>();
                for (String program : programToLeadsMap.keySet()) {
                    ReferralProgramFieldMapping__mdt mapping = programByPicklistValue.get(program);
                    List<String> advocateIdsToMatchByContact = new List<String>();
                    List<Lead> leadsToMatchByContact = programToLeadsMap.get(program);
                    for (Lead ld : leadsToMatchByContact) {
                        advocateIdsToMatchByContact.add(ld.Saasquatch_Advocate_ID__c);
                    }
                    String condition = 'saasquatch__Contact__r.'  + mapping.FieldAPIName__c + ' IN :bind0';
                    users = (List<saasquatch__SaaSquatch_User__c>) new SaasquatchUserSelector()
                        .selectUsersByContactCode(new List<Object> {advocateIdsToMatchByContact}, condition)
                        .executeQuery();
                    if (!users.isEmpty()) {
                        for (saasquatch__SaaSquatch_User__c user : users) {
                            String key = (String) user.saasquatch__Contact__r.get(mapping.FieldAPIName__c);
                            userMap.put(key, user);
                        }
                    }
                    for (Lead ld : leadsToMatchByContact) {
                        if (userMap.containsKey(ld.Saasquatch_Advocate_ID__c)) {
                            ld.Saasquatch_Advocate_Name__c = userMap.get(ld.Saasquatch_Advocate_ID__c).Id;
                        } else {
                            ld.Saasquatch_Advocate_Name__c = null;
                            leadsUnmatched.add(ld.Id);
                        }
                    }                 
                }
                if (!leadsUnmatched.isEmpty()) {
                    sendEmailsSaasquatch(leadsUnmatched, true);
                }            
            }
        } catch (Exception e) {
            ExceptionHelper.createExceptionAndNotificacionHistory(e, lstLead, 'Lead Exception');
        }
        system.debug('populateSaaSquatchAdvocateFieldsOnlead end time - ' + limits.getCpuTime());
    }

    @future
    public static void sendEmailsSaasquatch(List<String> leadsIds, Boolean leadsMatchedByContact) {
        List<Lead> leadsToEmail = (List<Lead>) new LeadSelector()
        .selectLeadsByIdsForSaasquatchEmailing(new List<Object> {leadsIds})
        .executeQuery();

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        // Get the email address from the custom setting
        SaasquatchEmailConfig__c emailReceiver = SaasquatchEmailConfig__c.getInstance();
        String receiverEmail = emailReceiver.SaaSquatchEmail__c;

        for (Lead l : leadsToEmail) {
            String programSelector = (l.saasquatch_program_selector__c != null ? l.saasquatch_program_selector__c : SAASQUATCH_DEFAULT_PROGRAM);
            String leadName = (l.FirstName != null ? l.FirstName : '') + ' ' + (l.LastName != null ? l.LastName : '');
            String saasqUserName = (l.Saasquatch_Advocate_Name__r.saasquatch__First_Name__c != null ? l.Saasquatch_Advocate_Name__r.saasquatch__First_Name__c : '') 
            + ' ' + (l.Saasquatch_Advocate_Name__r.saasquatch__Last_Name__c != null ? l.Saasquatch_Advocate_Name__r.saasquatch__Last_Name__c : '');
            String leadUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/' + l.Id;

            String subject;
            String body;
            if (leadsMatchedByContact) {
                subject = 'SaaSquatch User not found for code ' + l.Saasquatch_Advocate_ID__c;  
                body = 'Lead: ' + '<a href="' + leadUrl + '">' + leadName + '</a>' +  ' was assigned to the referral code '
                + '<b>' + l.Saasquatch_Advocate_ID__c + '</b> and program <i>' + l.saasquatch_program_selector__c + '</i><br>'
                + 'We weren\'t able to find any users with this information. Please verify';
            } else {
                subject = 'SaaSquatch Referral Code was not found for User ' + saasqUserName;  
                body = 'Lead: ' + '<a href="' + leadUrl + '">' + leadName + '</a>' +  ' was assigned to the User '
                + '<b>' + saasqUserName + '</b> and program <i>' + l.saasquatch_program_selector__c + '</i><br>'
                + 'We weren\'t able to find any SaaSquatch Referral code with this information. Please verify.';
            }            
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[]{receiverEmail});
            email.setSubject(subject);
            email.setHtmlBody(body);
            emails.add(email);
        }
        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }

    public static void SaasquatchSendEmailsForUnmatchedId(List<Lead> leads){
        List<Id> leadsToSendEmail = new List<String>();
        for (lead l : leads) {   
            if (l.Saasquatch_Advocate_ID__c != null && l.Saasquatch_Advocate_Name__c == null && 
            !String.isBlank(l.saasquatch_program_selector__c) && l.saasquatch_program_selector__c != SAASQUATCH_DEFAULT_PROGRAM) {
                leadsToSendEmail.add(l.id);
            }        
        }
        if (!leadsToSendEmail.isEmpty()) {
            sendEmailsSaasquatch(leadsToSendEmail, true);
        }         
    }
    
    //End of SaaSquatch Logic
    
    //Logic to populate BMID based on lead source.
    //Mapping between lead source and BMID values is done in custom settings.
    public static void populateBMIDBasedOnLeadSource(List<lead> lstLead, Map<Id, Lead>oldMap) {

        system.debug('populateBMIDBasedOnLeadSource start time - ' + limits.getCpuTime());

        Map<String, Saasquatch_Settings__c> leadSourceBMIDMap = new Map<String, Saasquatch_Settings__c>();

        try {
            List<Saasquatch_Settings__c> settingsMap = Saasquatch_Settings__c.getAll().values();

            if (settingsMap.size() > 0) {
                for (Saasquatch_Settings__c setting : settingsMap) {
                    leadSourceBMIDMap.put(setting.Lead_Source__c, setting);
                }
            }

            for (lead l : lstLead) {
                if (l.BMID__c == null && l.LeadSource != null && leadSourceBMIDMap != null && leadSourceBMIDMap.containsKey(l.LeadSource) && leadSourceBMIDMap.get(l.LeadSource).Campaign_ID__c != null && (Trigger.isInsert || (oldMap != null && (l.LeadSource != oldMap.get(l.id).LeadSource)))) {
                    l.BMID__c = leadSourceBMIDMap.get(l.LeadSource).BMID_Value__c;
                    l.Primary_Campaign__c = leadSourceBMIDMap.get(l.LeadSource).Campaign_ID__c;
                    l.Most_Recent_Campaign__c = leadSourceBMIDMap.get(l.LeadSource).Campaign_ID__c;
                }
            }

        } catch (Exception e) {
            ExceptionHelper.createExceptionAndNotificacionHistory(e, lstLead, 'Lead Exception');
        }
        system.debug('populateBMIDBasedOnLeadSource end time - ' + limits.getCpuTime());
    }

    public static void PerformWorkFlowActions(List<Lead> leads) {
        system.debug('PerformWorkFlowActions start time - ' + limits.getCpuTime());
        try {
            Feature_Toggle__c featureToggle = Feature_Toggle__c.getInstance();

            if (featureToggle == null ||
                featureToggle.LeadWorkflowRulesAndProcToTrigger__c == null ||
                featureToggle.LeadWorkflowRulesAndProcToTrigger__c == false) {
                return;
            }

            Set<Id> userIdSet = new Set<Id>();
            Set<Id> queueIdSet = new Set<Id>();
            for (Lead item : leads) {
                if (item.OwnerId.getsobjecttype() == User.sobjecttype) {
                    userIdSet.add(item.OwnerId);
                }
            }
            userIdSet.add(UserInfo.getUserId());
            Map<Id, User> userIdToUserMap = UserHelper.getORQueryUsers(userIdSet);

            for (Lead item : leads) {

                casAutoDowngrade(item);

                resetCallAttempts(item);
            }
        } catch (Exception ex) {
            LeadPlatEvents.leadExceptionCreationAsync(new Exception[]{
                ex
            }, 'PerformWorkFlowActions');
            throw ex;
        }
        system.debug('PerformWorkFlowActions end time - ' + limits.getCpuTime());
    }

    private static void casAutoDowngrade(Lead item) {

        if (item != null && item.OwnerId == HardcodedIdsMapper.getMatchedObjectId(QueueHelper.SHARED_LEADS_ID) &&
            item.cas__NumberAttempts__c >= 30 &&
            item.Status == LeadHelper.STATUS_CALL_OUT) {

            item.Status = LeadHelper.STATUS_DOWNGRADED;
            item.Downgrade_Reason__c = 'No Response';
        }
    }

    private static void resetCallAttempts(Lead item) {
        if (CoreObjectBase.isFieldChangedTo(item, Lead.Status, LeadHelper.STATUS_RENEW) &&
            LeadHelper.RT_ID_SALES_LEADS == item.RecordTypeId) {

            item.Activity_First_Attempt__c = null;
            item.Call_Attempts__c = 0;
            item.InContact_Dial_Attempt__c = 0;
            item.cas__FirstAttempt__c = null;
            item.cas__NumberAttempts__c = 0;
        }
    }

    public static void PerformLeadCreateUpdateWorkflows(List<Lead> leads, Map<Id, Lead> oldLeads) {
        system.debug('PerformLeadCreateUpdateWorkflows start time - ' + limits.getCpuTime());
        try {
            // Case 11653779: 101 SQOL query in Lead Convert
            // Moving workflow rules to trigger =>

            for (Lead leadRecord : leads) {
                // 'Active Sequence Date stamped' workflow moved
                if (CoreObjectBase.isFieldChanged(leadRecord, Lead.Actively_Being_Sequenced__c) && leadRecord.Actively_Being_Sequenced__c == true) {
                    leadRecord.Active_Sequence_Date__c = Date.today();
                }
                // 'Update 'Ignite' lead checkbox' workflow moved
                if (leadRecord.Certified_Ignite_partner_contact__c && Trigger.isInsert) {
                    leadRecord.Ignite_Partner_Program_Contact__c = true;
                }
                // 'B-10571 MQL Date Stamp' workflow moved
                Boolean needToUpdateMQL = false;
                if (Trigger.isInsert && isLeadMeetWFCriteria(leadRecord)) {
                    needToUpdateMQL = true;
                }
                if (Trigger.isUpdate) {
                    Lead oldRecord = oldLeads.get(leadRecord.Id);
                    if (isLeadMeetWFCriteria(leadRecord) && !isLeadMeetWFCriteria(oldRecord)) {
                        needToUpdateMQL = true;
                    }
                }
                if (needToUpdateMQL) {
                    leadRecord.Most_Recent_MQL_Date__c = DateTime.now();
                }
            }
        } catch (Exception ex) {
            LeadPlatEvents.leadExceptionCreationAsync(new Exception[]{
                ex
            }, 'PerformLeadCreateUpdateWorkflows');
            throw ex;
        }
        system.debug('PerformLeadCreateUpdateWorkflows end time - ' + limits.getCpuTime());
    }
    private static Boolean isLeadMeetWFCriteria(Lead leadRecord) {
        system.debug('isLeadMeetWFCriteria start time - ' + limits.getCpuTime());
        Boolean res = false;
        Set<String> leadStatusSet = new Set<String>{
            '.5 Re-New',
            '1. New',
            '1.5 Call Out',
            '2. Contacted'
        };
        Set<String> leadSourceSet = new Set<String>{
            'About To Be Cancelled',
            'About To Be Cancelled UK'
        };
        Set<String> excludedNamesSet = new Set<String>{
            'faxtest',
            'test',
            'ringcentral'
        };
        Boolean isStatusInSet = false;
        if (leadStatusSet.contains(leadRecord.Status)) {
            isStatusInSet = true;
        }
        Boolean isLeadSourceSetContainValue = false;
        for (String val : leadSourceSet) {
            if (String.isNotEmpty(leadRecord.LeadSource) && leadRecord.LeadSource.contains(val)) {
                isLeadSourceSetContainValue = true;
                break;
            }
        }
        Boolean isExcludedNamesSetContainValue = false;
        for (String val : excludedNamesSet) {
            if (String.isNotEmpty(leadRecord.FirstName) && leadRecord.FirstName.toLowerCase().contains(val)) {
                isExcludedNamesSetContainValue = true;
                break;
            }
            if (String.isNotEmpty(leadRecord.LastName) && leadRecord.LastName.toLowerCase().contains(val)) {
                isExcludedNamesSetContainValue = true;
                break;
            }
        }
        Boolean isEmailExcluded = false;
        if (String.isNotEmpty(leadRecord.Email) && leadRecord.Email.contains('ab.soft.net')) {
            isEmailExcluded = true;
        }
        if (isStatusInSet && !isLeadSourceSetContainValue && !isEmailExcluded && !isExcludedNamesSetContainValue) {
            res = true;
        }
        system.debug('isLeadMeetWFCriteria end time - ' + limits.getCpuTime());
        return res;
    }
    public static void SetLeadCreationDate(List<Lead> leads) {
        system.debug('SetLeadCreationDate start time - ' + limits.getCpuTime());
        try {
            Feature_Toggle__c featureToggle = Feature_Toggle__c.getInstance();

            if (featureToggle == null ||
                featureToggle.LeadWorkflowRulesAndProcToTrigger__c == null ||
                featureToggle.LeadWorkflowRulesAndProcToTrigger__c == false) {
                return;
            }

            for (Lead ld : leads) {
                if (ld.Lead_Creation_Date__c == null) {
                    ld.Lead_Creation_Date__c = System.now();
                }
            }
        } catch (Exception ex) {
            LeadPlatEvents.leadExceptionCreationAsync(new Exception[]{
                ex
            }, 'SetLeadCreationDate');
            throw ex;
        }
        system.debug('SetLeadCreationDate end time - ' + limits.getCpuTime());
    }
    public static void campaignAtrributionLogic(List<Lead> newLeadList, Map<Id, Lead> oldMap) {
        try {
            Feature_Toggle__c featureToogle = Feature_Toggle__c.getInstance();
            if (!TriggerHandler.BY_PASS_LEAD_UPDATE) {
                Set<Id> campaignIds = new Set<Id>();
                List<Lead> leadsMRC = new List<Lead>();
                List<CampaignMember> campaignMemberList;
                List<Id> leadIdsBindings = new List<Id>();
                List<Id> campaignIdsBindings = new List<Id>();

                for (Lead updatedLead : (List<Lead>) newLeadList) {
                    if(updatedLead.Lead_Brand_Name__c!=null && System.Label.BizMerge_Brand_Exclusion_List!=null
                     && System.Label.BizMerge_Brand_Exclusion_List.contains(updatedLead.Lead_Brand_Name__c))//BizMerge-Added Brand Name check to exclude Campaign Attribution logic for ATT Leads
                     {  
                        continue;
                     }
              		
                    Id newCampaign = updatedLead.Most_Recent_Campaign__c;
                    Id oldCampaign = oldMap.get(updatedLead.Id).Most_Recent_Campaign__c;
                    if (newCampaign != null && newCampaign != oldCampaign) {
                        leadIdsBindings.add(updatedLead.id);
                        campaignIdsBindings.add(newCampaign);
                        leadsMrc.add(updatedLead);
                        campaignIds.add(newCampaign);
                        campaignIds.add(oldCampaign);
                    }
                }
                campaignMemberList = LeadTriggerHelper.campaignAttribution(campaignIds, leadsMrc, (Map<Id, Lead>) Trigger.oldMap);
                List<CampaignMember> existingCampMembs = LeadTriggerHelper.getExistingCampMembers(leadIdsBindings, campaignIdsBindings);

                for (CampaignMember cm : existingCampMembs) {
                    ((Lead) trigger.newMap.get(cm.LeadId)).Most_Recent_Campaign_Member_Status__c = cm.Status;
                }

                campaignMemberList = LeadTriggerHelper.removeExistingCampMembers(existingCampMembs, campaignMemberList);
                if (campaignMemberList != null && !campaignMemberList.isEmpty()) {
                    TriggerHandler.BY_PASS_CAMPAIGNMEMBER_TRIGGER_CAMPAIGNATTRIBUTION = true;
                    LeadTriggerHelperExt.insertCampaignMember(campaignMemberList, false);
                }
            }
        } catch (Exception ex) {
            LeadPlatEvents.leadExceptionCreationAsync(new Exception[]{
                ex
            }, 'campaignAtrributionLogic');
            throw ex;
        }
    }
    public static void ProcessDFRAfterUpdate(List<Lead> newLeads, Map<Id, Lead> mapOld) {
        try {
            if (newLeads.size() > 25) {
                List<DFR_AfterUpdate__e> eventList = new List<DFR_AfterUpdate__e>();
                for (Lead ld : newLeads) {
                    if (ld.Lead_Brand_Name__c != null && System.Label.BizMerge_Brand_Exclusion_List != null 
                        && System.Label.BizMerge_Brand_Exclusion_List.contains(ld.Lead_Brand_Name__c))//BizMerge-Added Brand Name check to exclude DFR logic for ATT Leads
                    {
                        continue;
                    }
                    String assetTouch;
                    if (
                        ld.Most_Recent_Asset__c != null &&
                            (ld.Most_Recent_Asset__c != mapOld.get(ld.Id).Most_Recent_Asset__c ||
                                ld.Asset_Id__c != mapOld.get(ld.Id).Asset_Id__c)
                    ) {
                        assetTouch = JSON.serialize(AssetAssignmentHelper.getAssetTouchesForRecord(ld));
                    }
                    eventList.add(
                        new DFR_AfterUpdate__e(
                            Id__c = ld.Id,
                            FirstName__c = mapOld.get(ld.Id).FirstName,
                            LastName__c = mapOld.get(ld.Id).LastName,
                            Status__c = mapOld.get(ld.Id).Status,
                            OwnerId__c = mapOld.get(ld.Id).OwnerId,
                            Routing_Reason__c = mapOld.get(ld.Id).Routing_Reason__c,
                            AssetTouch__c = assetTouch,
                            Is_Test__c = System.isBatch()
                        )
                    );
                }
                PlatformEvents.publishPlatformEvent(eventList, 'LeadTriggerHandler');
            } else {
                List<Asset_Touch__c> assetTouchList = new List<Asset_Touch__c>();
                for (Lead ld : newLeads) {
                    if (ld.Lead_Brand_Name__c != null && System.Label.BizMerge_Brand_Exclusion_List != null
                        && System.Label.BizMerge_Brand_Exclusion_List.contains(ld.Lead_Brand_Name__c))///BizMerge-Added Brand Name check to exclude DFR logic for ATT Leads
                    {
                        continue;
                    }
                      
                    if (
                        ld.Most_Recent_Asset__c != null &&
                            (ld.Most_Recent_Asset__c != mapOld.get(ld.Id).Most_Recent_Asset__c ||
                                ld.Asset_Id__c != mapOld.get(ld.Id).Asset_Id__c)
                    ) {
                        assetTouchList.addAll(AssetAssignmentHelper.getAssetTouchesForRecord(ld));
                    }
                }
                List<Lead> newNormalLeads = new List<Lead>();
                for (Lead ld : newLeads) {
                    if(ld.Lead_Brand_Name__c==null || (ld.Lead_Brand_Name__c!=null && System.Label.BizMerge_Brand_Exclusion_List!=null
                       && !System.Label.BizMerge_Brand_Exclusion_List.contains(ld.Lead_Brand_Name__c)) ){//BizMerge-Added Brand Name check to exclude DFR logic for ATT Leads
                           newNormalLeads.add(ld);
                       }
                }
                DG_DFR_Class.DFR_UpdateTQLOnOwnerChange(newNormalLeads, mapOld);
                DG_DFR_Class.DFR_LeadStatusChange(newNormalLeads, mapOld);
                DG_DFR_Class.DFR_ChangeLeadOwner(newNormalLeads, mapOld);
                DG_DFR_Class.MQLHandOff_OnUpdate(newNormalLeads, mapOld);
                DG_DFR_Class.SALHandOff_OnUpdate(newNormalLeads, mapOld);
                DG_DFR_Class.updateMQLOwnerFieldsAfterLeanData(new Map<Id, Lead>(newNormalLeads), mapOld);
                if (!assetTouchList.isEmpty()) {
                    AssetAssignmentHelper.processAndUpsertAssetTouchesForInsertion(assetTouchList, 'Lead');
                }
            }
        } catch (Exception ex) {
            LeadPlatEvents.leadExceptionCreationAsync(new Exception[]{
                ex
            }, 'ProcessDFRAfterUpdate');
            throw ex;
        }
    }

    //Create Lead Extensions
    //Commenting as Lead_Ext__c is no longer Used
    /*public static void CreateLeadExtensions(List<Lead> insertedLeads) {
        try {
            List<Lead_Ext__c> leadExtRecords = new List<Lead_Ext__c>();
            for (Lead ld : insertedLeads) {
                Lead_Ext__c leadExt = new Lead_Ext__c();
                leadExt.Lead__c = ld.Id;
                leadExtRecords.add(leadExt);
            }

            if (!leadExtRecords.isEmpty()) {
                insert leadExtRecords;
            }
        } catch (Exception ex) {
            System.debug('CreateLeadExtensions error : ' + ex.getMessage());
        }
    }*/
    
    
    public static void PopulateIntentFlow(List<Lead> leads) {
        System.debug('PopulateIntentFlow start time - ' + Limits.getCpuTime());

        if (leads == null || leads.isEmpty()) {
            return;
        }

        try {
            Set<Id> accountIds = new Set<Id>();
            for (Lead lead : leads) {
                if (lead.ZI_CDP_Account_Id__c != null) {
                    accountIds.add(lead.ZI_CDP_Account_Id__c);
                }
            }

            if (accountIds.isEmpty()) {
                return;
            }

            Map<Id, String> accountIntentMap = new Map<Id, String>();
            List<Account> accountIntentList = (List<Account>) new AccountSelector()
                    .selectIntentValue(new List<Object>{accountIds})
                    .executeQuery();
            
            if (accountIntentList != null) {
                for (Account acc : accountIntentList) {
                    accountIntentMap.put(acc.Id, acc.Intent__c);
                }
            }

            for (Lead lead : leads) {
                if (lead.ZI_CDP_Account_Id__c != null) {
                    lead.Intent__c = accountIntentMap.get(lead.ZI_CDP_Account_Id__c);
                }
            }
        } catch (Exception ex) {
            System.debug('Intent Field update error: ' + ex.getMessage());
        }
    }

    public static void SendDatatoClayforEnrichment(List<Lead> leadlst) {
        List<Lead> resultLeads = new List<Lead>();
        for (Lead lead : leadlst) {
            if (lead.Systems_Process_Stage__c != NULL &&
                (lead.Systems_Process_Stage__c.equalsIgnoreCase('SFDC created') || 
                lead.Systems_Process_Stage__c.equalsIgnoreCase('Marketo created')) &&
                lead.SFDC_Enriched_Date_time__c == NULL && 
                String.isBlank(lead.Systems_process_enrichment_bypass__c)
            ) {
                resultLeads.add(lead);
            }
        }
        if (!resultLeads.isEmpty()) {
            System.enqueueJob(new ClayLeadWebHookHandler(resultLeads));
        }
    }
}