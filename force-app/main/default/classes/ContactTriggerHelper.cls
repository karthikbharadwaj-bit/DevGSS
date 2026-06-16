public class ContactTriggerHelper {

	//Variable Declaration
    private static String NO_OF_EMPLOYEES = 'numberofemployees__c';
    public static final Set<String> SALES_GENERATED_SOURCES = new Set<String>{'Inbound Chat','Inbound Call','Sales Generated'};
    private static Boolean skipContactStatusValidations = null;
    public static final Set<String> MQL_CONTACT_STATUS = new Set<String>{'.5 Re-New', '1. New', '1.5 Call Out', '2. Contacted'};
    public static Boolean isMergeContact = false;

    public static final Integer MIN_PHONE_LENGTH = 7;
    public static final Integer MAX_PHONE_LENGTH = 32;

    /****************************************************************************************************
	 *@Description: getting Standard Value of No. Of Employee Range                                     *
    *@Params: no Parameters                                                                             *
    *@Returns: Set<String>																			*
    *@Coded By: India Team                                                                              *
    *****************************************************************************************************/

    public static Set<String> getEmployeeRange() {
        Set<String> range = new Set<String>();
        range.addAll(getPicklistValue());
        return range;
    }

    /****************************************************************************************************
	 *@Description: get picklist values of a field.                                    *
    *@Params: no Parameters                                                                             *
    *@Returns: Set<String>																			*
    *@Coded By: India Team                                                                              *
    *****************************************************************************************************/
    public static Set<string> getPicklistValue() {
        Set<String> ranges = new Set<String>();
        Schema.DescribeFieldResult numberOfEmployees = Contact.NumberOfEmployees__c.getDescribe();
        List<Schema.PicklistEntry> numberOfEmployeesRange = numberOfEmployees.getPicklistValues();
        for(Schema.PicklistEntry schObj : numberOfEmployeesRange) {
            ranges.add(schObj.getValue());
        }
        return ranges;
    }

    public static Map<Integer, String> rangeMapPerStartValue(Set<String> range) {
        Map<Integer, String> mapPossibleValidRange = new Map<Integer, String>();
        try {
            if(range.size() > 0) {
                for(String strRangeValue : range){
                    if(strRangeValue.indexOf('-') > -1) {
                        try {mapPossibleValidRange.put(Integer.valueOf(strRangeValue.split('-')[0].trim()), strRangeValue);} catch(Exception x) {}
                    } else if(strRangeValue.indexOf('+') > -1) {
                        try {mapPossibleValidRange.put(Integer.valueOf(strRangeValue.substring(0,strRangeValue.indexOf('+'))), strRangeValue); } catch(Exception y) {}
                    } else if(!isNumeric(strRangeValue)) {
                        mapPossibleValidRange.put(1, strRangeValue);
                    }
                }
            }
        } catch(Exception e) {}
        return mapPossibleValidRange;
    }

    /*****************************************************************************
     * @Description - method to update contact records on insertion/updation of account record      *
     * @return Map<Id,List<Contract>                                                                *
     *****************************************************************************/
    public static void updateContactOnAccount(list<Contact> lstContact) {
        try {
            List<Account> accList = new List<Account>();
            //Set of Account Ids that we will iterate through
            Set<id> Ids = new Set<id>();
            for (Contact con : lstContact) {
                if(con.accountid != null) {
                    Ids.add(con.AccountId);
                }
            }
            // Get the Account id and Event_Account_Status__c for each account
            String recordTypeName = 'Customer Account'; // <-- Change this to your record type name
            Map<id, Account> accountMap = new Map<id, Account>();
            if (!ids.isEmpty()) {
                accountMap = new Map<id, Account>([Select id,Current_Owner__c,Current_Owner__r.IsActive,Most_Recent_Opportunity_Stage__c, RC_Account_Status__c from Account Where Id in :Ids ]);
            }
            for(Contact con : lstContact) {
                if(con.AccountId != null) {
                    Account acc = accountMap.get(con.AccountId);
                    if (acc.RC_Account_Status__c != null  && 'Paid'.equalsIgnoreCase(acc.RC_Account_Status__c.trim())) {
                        con.isCustomer__c=True;
                        //con.Contact_Status__c='4. Customer';
                        //con.Contact_Funnel_Type__c='Customer';
                        con.People_Segment__c='Customer';
                        //con.OwnerId = acc.Current_Owner__c;
                    }  else if (acc.RC_Account_Status__c != null   && 'Canceled'.equalsIgnoreCase(acc.RC_Account_Status__c.trim())) {
                        con.isCustomer__c=False;
                        //con.Contact_Status__c='4. Customer';
                        //con.Contact_Funnel_Type__c=' Winback';
                        con.People_Segment__c='Former Customer';
                        //con.OwnerId = acc.Current_Owner__c;
                    }
                    if (string.isNotBlank(acc.Current_Owner__c) && acc.Current_Owner__r.IsActive) {
                        con.OwnerId = acc.Current_Owner__c;
                    }
                }
            }
        }  catch(Exception e) {
            ExceptionHelper.createExceptionAndNotificacionHistory(e, lstContact, 'Contact Exception');
        }
    }


    public static void  validateEmployeeRangeForNumericValues(List<Contact> contactList) {
        Set<String> range = new Set<String>();
        range = getEmployeeRange();
        List<Contact> nextLogicContacts = new List<Contact>();
        Map<Integer, String> mapPossibleValidRange = rangeMapPerStartValue(range);
        List<Integer> lstIntLowerValueOfValidRange = new List<Integer>(mapPossibleValidRange.keySet());
        lstIntLowerValueOfValidRange.sort();
        try {
            for(Contact contactObj : contactList) {
                String upcomingEmployeeValue = contactObj.NumberOfEmployees__c;
                if(!String.isBlank(upcomingEmployeeValue)) {
                    if(isNumeric(upcomingEmployeeValue)) {
                        Integer intNumberOfEmployeeRangeValue = Integer.valueOf(upcomingEmployeeValue);
                        for(Integer intLowerRange : lstIntLowerValueOfValidRange) {
                            if(intLowerRange <= intNumberOfEmployeeRangeValue) {
                                contactObj.Employee_Size_History__c = upcomingEmployeeValue;
                                contactObj.NumberOfEmployees__c = mapPossibleValidRange.get(intLowerRange);
                            } else {
                                break;
                            }
                        }
                    }
                }
            }
        } catch(exception ex) {
            ExceptionHelper.createExceptionAndNotificacionHistory(ex, contactList, 'Contact Exception');
        }
    }

    public static void getCheckForBadValue(List<Contact> lstContact) {
        try {
            List<Contact> filteredContacts = new List<Contact>();
            Set<String> range = new Set<String>();
            range.addAll(getPicklistValue());
            for(Contact contactObj : lstContact) {
                if(!isValidValue(range, contactObj)) {
                    filteredContacts.add(contactObj);
                }
            }
            if(filteredContacts.size() == 0){
                return;
            }
            String csvFile;
            String fileName='No_Employee_Mapping';
            String[] fileLines = new String[]{};
            Map<String,String> mapToGetGoodValueEmp = new Map<String,String>();
            Map<String,String> mapToGetGoodValueInd = new Map<String,String>();
            Map<String,String> mapToGetGoodValueJob = new Map<String,String>();
            Map<String,String> mapToGetGoodValuePur = new Map<String,String>();
            Map<String,Map<String,String>> masterMap = new Map<String,Map<String,String>>();
            List<Contact_Field_Map__c> fieldlst = Contact_Field_Map__c.getAll().Values();

            List<Document> compareDoc=getMyDocument(fileName);
            if (compareDoc.size() > 0 && compareDoc[0].body!=null) {
                csvFile= compareDoc[0].body.toString();
                fileLines=csvFile.split('#EOL#');
                for(String line : fileLines) {
                    if(!String.isBlank(line)) {
                        String[] inputvalues = line.split(',#,');
                        if(inputvalues != null && inputvalues.size() == 3) {
                            If(inputvalues[0].trim().equalsIgnoreCase(NO_OF_EMPLOYEES)) {
                                mapToGetGoodValueEmp.put(inputvalues[1].trim().tolowercase(),inputvalues[2].trim());
                            }
                        }
                    }
                }
            }
            for(Contact_Field_Map__c lfp:fieldlst) {
                if(lfp.api_name__c.trim()== NO_OF_EMPLOYEES) {
                    masterMap.put(String.valueOf(lfp.api_name__c).trim().tolowercase(),mapToGetGoodValueEmp);
                }
            }

            for(Contact contactObj : filteredContacts) {
                if(masterMap.containsKey(NO_OF_EMPLOYEES) && !String.isBlank(String.valueof(contactObj.NumberOfEmployees__c)) && mapToGetGoodValueEmp.containsKey(String.valueof(contactObj.NumberOfEmployees__c).tolowercase())) {
                        contactObj.Employee_Size_History__c = contactObj.NumberOfEmployees__c;
                        contactObj.NumberOfEmployees__c = masterMap.get(NO_OF_EMPLOYEES).get(contactObj.NumberOfEmployees__c.toLowerCase().trim());
                }
            }
        } catch(exception e) {
            ExceptionHelper.createExceptionAndNotificacionHistory(e, lstContact, 'Contact Exception');
        }
    }

    public static  boolean isNumeric( String numberOfEmployeeRange) {
        return Pattern.matches('^[0-9]{1,10}$', numberOfEmployeeRange);//^[0-9]+(\\.[0-9]+)?$
    }

    public static void phoneNumberValidation(List<Contact> contacts) {
        List<String> excludedUserIds = new List<String>();
        for (By_Pass_Phone_Number_Validation__mdt byPassPhoneMdt : By_Pass_Phone_Number_Validation__mdt.getAll().values()) {
            excludedUserIds.add(byPassPhoneMdt.UserId__c);
        }

        if (excludedUserIds.contains(UserInfo.getUserId())
            || UserInfo.getName() == UserHelper.MARKETO_USER_NAME
            || ConvertLead.IS_LEAD_CONVERT_PROCESSING
            || ContactHelper.IS_DO_NOT_CONTACT_EVENT
            || isMergeContact) {
            return;
        }
        Map<Id, Contact> idContactMap = new Map<Id, Contact>(contacts);
        List<Contact> contactsWithACR = (List<Contact>) new ContactSelector()
            .selectContactWithAccountsPayableACR(new List<Object>{ idContactMap.keySet() })
            .executeQuery();
        idContactMap = new Map<Id, Contact>(contactsWithACR);

        for (Contact contact : contacts) {
            if (String.isBlank(contact.Phone)) {
                continue;
            }
            if (!isPhoneNumeric(contact.Phone)) {
                contact.addError('Phone', 'Please use at least 7 digits and no letters in the phone number');
            } else if (!idContactMap.get(contact.Id).AccountContactRoles.isEmpty() && !isPhoneInRange(contact.Phone)) {
                contact.addError('Phone', ContactHelper.CONTACT_PHONE_NOT_IN_RANGE);
            }
        }
    }

    private static boolean isPhoneNumeric(String phoneNumber) {
        Integer countDigits = phoneNumber.replaceAll('[^0-9]+','').length();
        return (countDigits >= 7) && Pattern.matches('^[0-9-+\\(\\)\\s.,]+$', phoneNumber);
    }

    public static boolean isPhoneInRange(String phoneNumber) {
        return new QuoteApprovals.Range(ContactTriggerHelper.MIN_PHONE_LENGTH, ContactTriggerHelper.MAX_PHONE_LENGTH)
            .isInRange(phoneNumber?.length());
    }

    private static Boolean isValidValue(Set<String> range, Contact contactObj) {
        if(range.contains(contactObj.NumberOfEmployees__c)) {
            return true;
        }
        return false;
    }

    public static List<Document> getMyDocument(String docName){
        return [SELECT body, Name, bodyLength, ContentType, Url FROM Document WHERE Name = :docName];
    }
    public static Map<Id,Campaign> getCampaignMap(Set<Id> campaignIds) {
        Map<Id,Campaign> campaignMap;
        if (!campaignIds.isEmpty()) {
            campaignMap = new Map<Id,Campaign>();
            List<Object> bindings = new List<Object>();
            bindings.add(campaignIds);
            campaignMap.putAll((List<Campaign>) new CampaignSelector().selectCampaignsByIds(bindings).executeQuery());
        }
        return campaignMap;
    }

    public static List<CampaignMember> campaignAttribution(Set<Id> campaignIds, List<Contact> contactsMRC, Map<Id, Contact> oldMap) {
        Map<Id,Campaign> campaignMap = getCampaignMap(campaignIds);
        List<CampaignMember> campaignMemberList;
        if (campaignMap != null && !campaignMap.isEmpty()) {
            campaignMemberList = new List<CampaignMember>();
            for (Contact contact : contactsMRC) {
                Campaign newCampaign = campaignMap.get(contact.Most_Recent_Campaign__c);
                Campaign oldCampaign = campaignMap.get(oldMap.get(contact.Id).Most_Recent_Campaign__c);
                if (oldCampaign != null && !oldCampaign.Non_Attributable__c && newCampaign.Non_Attributable__c) {
                    contact.BMID__c = oldCampaign.BMID__c;
                    contact.Most_Recent_Campaign__c = oldCampaign.Id;
                    contact.Primary_Campaign__c = oldCampaign.Id;
                }
                Id marketingAssetId;
                if (contact.Most_Recent_Asset__c != oldMap.get(contact.Id).Most_Recent_Asset__c){
                    marketingAssetId = contact.Most_Recent_Asset__c;
                }
                if (TriggerHandler.UPDATE_CONTACT_BMID) {
                    contact.BMID__c='SOLVETHENSELL';
                    contact.AID__c='';
                    contact.PID__c='';
                }
                campaignMemberList.add(new CampaignMember(CampaignId = newCampaign.Id, ContactId = contact.Id, Primary_Marketing_Asset__c = marketingAssetId));
            }
        }
        return campaignMemberList;
    }

    public static List<CampaignMember> getExistingCampMembers(List<Id> contactIdsBindings, List<Id> campaignIdsBindings) {
        List<Object> bindings = new List<Object>();
        bindings.add(contactIdsBindings);
        bindings.add(campaignIdsBindings);
        return (List<CampaignMember>) new CampaignMemberSelector()
                                      .selectCampaignMemberByContactAndCampaignIds(bindings)
                                      .executeQuery();
    }

    public static List<CampaignMember> removeExistingCampMembers(List<CampaignMember> existingCampMembs, List<CampaignMember> campaignMemberList) {
        List<CampaignMember> campaignMembersToInsert = new List<CampaignMember>();
        Set<String> existingCampMembsKey = new Set<String>();

        if (campaignMemberList == null || campaignMemberList.isEmpty()) {
            return campaignMembersToInsert;
        }

        if (existingCampMembs != null && !existingCampMembs.isEmpty()) {
            for (CampaignMember cm : existingCampMembs) {
                existingCampMembsKey.add('' + cm.ContactId + cm.CampaignId);
            }
        }

        if (existingCampMembsKey.isEmpty()) {
            return campaignMemberList;
        }

        for (CampaignMember cm : campaignMemberList) {
            String key = '' + cm.ContactId + cm.CampaignId;
            if (!existingCampMembsKey.contains(key)) {
                campaignMembersToInsert.add(cm);
            }
        }

        return campaignMembersToInsert;
    }

    public static void assignCampaignToContacts(String campaignName, List<Contact> contactsToUpdate) {
        List<Object> bindings = new List<Object>();
        bindings.add(campaignName);
        List<Campaign> campaigns = bindings.isEmpty() ? new List<Campaign>() : (List<Campaign>) new CampaignSelector().selectCampaignsByName(bindings).executeQuery();
        Campaign campaign = !campaigns.isEmpty() ? campaigns.get(0) : null;
        if (campaign != null) {
            for (Contact contact : contactsToUpdate) {
                contact.Most_Recent_Campaign__c = campaign.Id;
                contact.Primary_Campaign__c = campaign.Id;
            }
        }
    }

    public static void assignCampaignsToContactsProcess(List<Contact> contactsForAttribution, Map<Id,Contact> oldMapContact) {
        List<Contact> contactsAttribution = new List<Contact>();
        List<CampaignWrapper> camWrapperList = new List<CampaignWrapper>();
        for (Contact updatedContact : contactsForAttribution) {
            if(updatedContact.Account_Brand__c!=null && System.Label.BizMerge_Brand_Exclusion_List!=null && System.Label.BizMerge_Brand_Exclusion_List.contains(updatedContact.Account_Brand__c)){
              continue;
            }
            if (oldMapContact != null && !oldMapContact.isEmpty()) {
                if ((updatedContact.BMID__c != oldMapContact.get(updatedContact.Id).BMID__c) ||
                (updatedContact.AID__c != oldMapContact.get(updatedContact.Id).AID__c) ||
                (updatedContact.PID__c != oldMapContact.get(updatedContact.Id).PID__c)) {
                  contactsAttribution.add(updatedContact);
                  camWrapperList.add(new CampaignWrapper(updatedContact.AID__c, updatedContact.BMID__c, updatedContact.PID__c));
                }
            } else if (contactsForAttribution != null && !contactsForAttribution.isEmpty()) {
                contactsAttribution.add(updatedContact);
                camWrapperList.add(new CampaignWrapper(updatedContact.AID__c, updatedContact.BMID__c, updatedContact.PID__c));
            }

        }
        if (!contactsAttribution.isEmpty()) {
            List<Contact> brokenContactList = new List<Contact>();
            List<Contact> trueWalkOnContactList = new List<Contact>();
            List<Contact> salesGeneratedContactList = new List<Contact>();
            Map<String, Campaign> criteriaToCamapaignMap = CampaignAssignmentHelper.findCampaingsLogic(camWrapperList);
            for (Contact con : contactsAttribution) {
                if (String.isBlank(con.AID__c) && String.isBlank(con.PID__c) && String.isBlank(con.BMID__c)) {
                    if(SALES_GENERATED_SOURCES.contains(con.LeadSource)) {
                        salesGeneratedContactList.add(con);
                    } else {
                        trueWalkOnContactList.add(con);
                    }
                } else {
                    Campaign campaignObj = CampaignAssignmentHelper.getLeadCampaignLogicWithoutDNIS(new CampaignWrapper(con.AID__c, con.BMID__c, con.PID__c), criteriaToCamapaignMap);
                    if(campaignObj != null && campaignObj.Name != 'Default Campaign' ) {
                        con.Primary_Campaign__c = campaignObj.Id;
                        con.Most_Recent_Campaign__c = campaignObj.Id;
                        con.BMID__c = campaignObj.BMID__c;
                    } else {
                        brokenContactList.add(con);
                    }
                }
            }

            if (salesGeneratedContactList !=null && salesGeneratedContactList.size() > 0) {
                ContactTriggerHelper.assignCampaignToContacts('Sales Generated', salesGeneratedContactList);
            }

            if (trueWalkOnContactList !=null && trueWalkOnContactList.size() > 0) {
                ContactTriggerHelper.assignCampaignToContacts('True_Walk_On_2024', trueWalkOnContactList);
            }

            if (brokenContactList !=null && brokenContactList.size() > 0) {
                ContactTriggerHelper.assignCampaignToContacts('Broken Attribution', brokenContactList);
            }
        }
    }

	public static Map<Id,User> getOwnerUsersMap(List<Contact> newContacts) {
        set<Id> OwnerIDSet = new set<Id>();
        Boolean doSoql = false;
        for (Contact contactObj : newContacts) {
            if(contactObj.OwnerId != null) {
                OwnerIDSet.add(contactObj.OwnerId);
            }
        }
        OwnerIDSet.add(UserInfo.getUserId());

        for (Id id : OwnerIDSet) {
            if (!ContactTriggerHandler.userStaticMap.containsKey(id)){
                doSoql = true;
            }
        }


        map<Id,User> userMap = new map<Id,User>();
        if (doSoql) {
            for (User usr : [
                    SELECT Id, FirstName, LastName, Name, Profile.Name, Email, Manager.Email, Phone,
                            Manager.Username, IsActive, ManagerId, Mkto_Reply_Email__c, ProfileId
                    FROM User
                    WHERE Id IN : OwnerIDSet
            ]) {
                userMap.put(usr.Id, usr);
                ContactTriggerHandler.userStaticMap.put(usr.Id, usr);
            }
        } else {
            userMap = ContactTriggerHandler.userStaticMap;
        }
        return userMap;
    }
    public static void assignRCSFSyncOwnerForInactiveOwners(List<Contact> newContacts, map<Id,User> userMap) {
        for (Contact contactObj : newContacts) {
            if (userMap != null
            && contactObj.OwnerId != null
            && userMap.get(contactObj.OwnerId) != null
            && userMap.get(contactObj.OwnerId).IsActive == false) {
                contactObj.OwnerId = HardcodedIdsMapper.getMatchedObjectId('005800000036sJJ'); // RCSF Sync
            }
        }
    }
    public static void populateIndexEmailAndPhone(List<Contact> newContacts) {
        for (Contact contactObj : newContacts) {
            contactObj.indexedEmail__c = contactObj.Email;
            contactObj.indexedPhone__c = contactObj.Phone;
        }
    }
    public static void populateIndexPhoneEmailAndNOfEmployees(List<Contact> newContacts, Map<Id,Contact> oldContactsMap) {
        List<Contact> numberOfEmpContactUpdatedList = new List<Contact>();

        for (Contact cont : newContacts) {
            if(cont.Phone != oldContactsMap.get(cont.Id).Phone) {
                cont.indexedPhone__c = cont.Phone;
            }

            if(cont.Email != oldContactsMap.get(cont.Id).Email) {
                cont.indexedEmail__c = cont.Email;
            }

            if(cont.NumberOfEmployees__c != null
                    && cont.NumberOfEmployees__c != oldContactsMap.get(cont.Id).NumberOfEmployees__c) {
                numberOfEmpContactUpdatedList.add(cont);
            }
        }
        //No. of Employee mapping.
        if(numberOfEmpContactUpdatedList!=null && numberOfEmpContactUpdatedList.size() > 0) {
            ContactTriggerHelper.validateEmployeeRangeForNumericValues(numberOfEmpContactUpdatedList);
            ContactTriggerHelper.getCheckForBadValue(numberOfEmpContactUpdatedList);
        }
    }
    public static void updateFlagForMarketoBatch(List<Contact> newContacts) {
        /************************** Update Flag for Marketo Batch **************************/
        if (UserInfo.getName().equalsIgnoreCase('User Marketo')) {
            Set<sObjectField> marketoFields = new Set<sObjectField>{
                Contact.Asset_Name__c, Contact.Asset_Type__c,
                Contact.Campaign_Member_Target_Segment__c,
                Contact.Campaign_Member_Type__c,
                Contact.Member_Detail__c, Contact.Promo_Code__c,
                Contact.Responded_Date__c
            };
            for (Contact cont : newContacts) {

                if (CoreObjectBase.isFieldChanged(cont, new List<sObjectField>(marketoFields))) {
                    cont.MarketoBatchJobFlag__c = true;
                }
            }
        }
    }
    /*The purpose of this work flow is to timestamp AMP_Advocate_Email_Created_Date__c everytime a rep modifies the AMP_Advocate_Email__c field.
    We do not want this code firing when User Marketo creates / converts this contact.*/
    public static void AMPAdvocateEmailCreatedDateContact(List<Contact> newContacts, Map<Id,Contact> oldContactsMap) {
        if (!UserInfo.getName().equalsIgnoreCase('User Marketo')) {
            for (Contact cont : newContacts) {
                Contact oldCont = trigger.isUpdate ? (Contact) oldContactsMap.get(cont.Id) : null;

                boolean AMPAdvocateEmailChanged = (
                    oldCont != null &&
                    cont.AMP_Advocate_Email__c != oldCont.AMP_Advocate_Email__c
                );

                boolean isInsert_IsNotConvertedFromLead_AMPAdvocateEmailIsNotNull = (
                    trigger.isInsert &&
                    !cont.isConvertedFromLead__c &&
                    String.isNotBlank(cont.AMP_Advocate_Email__c)
                );

                if (isInsert_IsNotConvertedFromLead_AMPAdvocateEmailIsNotNull  || AMPAdvocateEmailChanged) {
                    cont.AMP_Advocate_Email_Created_Date__c = Datetime.now();
                }
            }
        }
    }

    public static void updateLeadspaceAccount(List<Contact> newContacts, Map<Id,Contact> oldMapContact) {
        Set<Id> accIdsWithChangedContacts = new Set<Id>();
        List<Account> accsToUpdate = new List<Account>();
        DomainManagerSvc manager = new DomainManagerSvc();
        for (Contact con : newContacts) {
            if (oldMapContact.isEmpty()) {
                if (!manager.domainIsInIgnoredDomainList(manager.getDomainPartFromEmailAddress(con.Email))
                    && con.Email != null && con.AccountId != null) {
                    accIdsWithChangedContacts.add(con.AccountId);
                }
            } else {
                if (!manager.domainIsInIgnoredDomainList(manager.getDomainPartFromEmailAddress(con.Email))
                    && con.Email != null && con.AccountId != null && con.Email != oldMapContact.get(con.Id).Email) {
                    accIdsWithChangedContacts.add(con.AccountId);
                }
            }
        }

        for (Id accId : accIdsWithChangedContacts) {
            accsToUpdate.add(new Account(Id = accId, RunContactMostFrequentEmail__c = true));
        }

        if (!accsToUpdate.isEmpty()) {
            Triggers.switchOff();
            update accsToUpdate;
            Triggers.switchOn();
        }
    }
    public static Map<Id,Account> getparentAccountMap(List<Contact> newContacts) {
        Set<Id> accountIdSet = new Set<Id>();
        Boolean doSoql = false;
        for(Contact contactobj : newContacts) {
            if(!String.isBlank(contactObj.AccountId)) {
                accountIdSet.add(contactObj.AccountId);
                if (!ContactTriggerHandler.parentAccountMap.containsKey(contactobj.AccountId)) {
                    doSoql = true;
                }
            }
        }
        Map<Id,Account> parentAccountMap = new Map<Id,Account>();
        if (doSoql) {
            for (Account acc : (List<Account>) new AccountSelector()
                    .selectAccountsForParentAccountMap(new List<Object>{ accountIdSet })
                    .executeQuery()) {
                parentAccountMap.put(acc.Id, acc);
                ContactTriggerHandler.parentAccountMap.put(acc.Id, acc);
            }
        } else {
            parentAccountMap = ContactTriggerHandler.parentAccountMap;
        }
        return parentAccountMap;
    }
    public static void leadCreation(List<Contact> newContacts, Map<Id,Account> parentAccountMap) {
        Map<String, String> mobLeadSources
                    = new Map<String, String>{'m' => 'm', 'iphone' => 'iphone',
                    'bb' => 'bb', 'android' => 'android'};
        List<Lead> leadsToInsert = new List<Lead>();
        Set<Id> accIds = new Set<Id>();
        try {
            for(Contact contactobj : newContacts) {
                accIds.add(contactobj.AccountId);
            }
            List<Package__c> packages = new PackageSelector()
                .selectPackagesForNewReferences(new List<Object> {accIds})
                .setQueryCaching(true)
                .executeQuery();

            List<Package__c> filterPackages = PackageHelper.filterPackagesByCreatedDateAndService(packages);
            Map<Id, List<Package__c>> packageToProcessMap =  PackageHelper.mapAccountIdToPackages(filterPackages);
            for(Contact contactobj : newContacts) {
                // VARIABLE DECLARATION
                Account accountObj = !String.isBlank(contactObj.AccountId)
                        ? parentAccountMap.get(contactObj.accountId)
                        : null;
                Package__c pkg = !String.isBlank(contactObj.AccountId) && !packageToProcessMap.values().isEmpty()
                    ? packageToProcessMap.get(contactObj.AccountId)[0]
                    : null;
                String signupType;
                String accountStatus;
                String signupPlatform;
                if(accountObj != null) {
                    accountStatus = accountObj.RC_Account_Status__c;
                }
                if (pkg != null) {
                    signupType = pkg.SignupType__c;
                    signupPlatform = pkg.SignupPlatform__c;
                }
                if(parentAccountMap != null && accountObj != null && signupType != null) {
                    //create a lead and populate values from current Contact
                    Lead newLead = new Lead();
                    newLead.Phone = contactobj.Phone;
                    newLead.LastName = contactobj.LastName;
                    newLead.FirstName = contactobj.FirstName;
                    newLead.Email = contactobj.Email;
                    newLead.Company  =  accountObj.Name;
                    newLead.Status = '1. New';
                    //Populate additional field as mentioned in E-mail on 6/2/2011,while creating Lead
                    newLead.Account_Status__c = accountStatus;
                    newLead.Account_Number__c = accountObj.RC_Account_Number__c;
                    newLead.User_ID__c = accountObj.RC_User_ID__c;
                    newLead.Lead_Tier_Name__c = accountObj.RC_Tier__c;
                    newLead.RC_Service_name__c = accountObj.RC_Service_name__c;
                    newLead.Lead_Brand_Name__c = accountObj.RC_Brand__c;
                    // Trial Web leads
                    if((String.isBlank(signupPlatform) || signupPlatform.toUpperCase()=='WEB')
                            && (signupType.toUpperCase().trim().equals('TRIAL_30NOCC'))) {
                        newLead.LeadSource = 'TRIAL 30d-NO-CC-WEB';
                        if(!String.isBlank(accountStatus) && accountStatus.toUpperCase() != 'DWH SYNC PENDING'
                                && (accountStatus.toUpperCase()).trim().contains('TRIAL') ) {
                            leadsToInsert.add(newLead);
                        }
                        // Trial
                    } else if(signupPlatform != null
                            && mobLeadSources.get(signupPlatform) != null
                            && (signupType.toUpperCase().trim().equals('TRIAL_30NOCC')
                                || signupType.toUpperCase().trim().equals('TRIAL_NOCC'))) {
                        //Map mobLeadSources has these values (m, iphone, bb, android)
                        //if SignupPlatform needs to have any other value matched, it should be added to
                        //mobLeadSources map as key & value
                        newLead.LeadSource = 'TRIAL 30d-NO-CC-MOB';
                        //To check if Account status is DWH SYNC PENDING,then don't create new Lead
                        //To check if Account status Contains Trial,then create new Lead
                        if(!String.isBlank(accountStatus) &&
                                accountStatus.toUpperCase() != 'DWH SYNC PENDING' &&
                                (accountStatus.toUpperCase()).trim().contains('TRIAL') ) {
                            leadsToInsert.add(newLead);
                        }
                    }
                    else {
                        if(!String.isBlank(accountStatus)
                                && accountStatus.toUpperCase() == 'TRIAL 30 NO-CC'
                                && signupPlatform == null) {
                            //create a lead and populate values from current Contact
                            newLead.Phone = contactobj.Phone;
                            newLead.LastName = contactobj.LastName;
                            newLead.FirstName = contactobj.FirstName;
                            newLead.Email = contactobj.Email;
                            newLead.Company  =  accountObj.Name;
                            //Populate additional field as mentioned in E-mail on 6/2/2011,while creating Lead
                            newLead.Account_Status__c = accountStatus;
                            newLead.Account_Number__c = accountObj.RC_Account_Number__c;
                            newLead.User_ID__c = accountObj.RC_User_ID__c;
                            newLead.Lead_Tier_Name__c = accountObj.RC_Tier__c;
                            newLead.RC_Service_name__c = accountObj.RC_Service_name__c;
                            newLead.Lead_Brand_Name__c = accountObj.RC_Brand__c;
                            newLead.Status = 'X. Open';
                            newLead.LeadSource = 'TRIAL 30d-NO-CC-WEB';
                            leadsToInsert.add(newLead);
                        }
                    }
                }
            }
            insert leadsToInsert;
        } catch(System.Exception e) {
            sObject[] objects = new sObject[]{};
            for (Lead ld : leadsToInsert) {
                objects.add(ld);
            }
            for (Contact cnt : newContacts) {
                objects.add(cnt);
            }
            ExceptionHelper.createExceptionAndNotificacionHistory(e, objects, 'Contact Exception');
        }
    }
    public static void campaignMemberGeneration(List<Contact> newContacts) {
        List<CampaignMember> campaignMemberList = new List<CampaignMember>();
        try {
            for(Contact contactobj : newContacts) {
                //Campaign Member Assosiation
                if(contactObj.Primary_Campaign__c!=null) {
                    CampaignMember campMemberObj = new CampaignMember(
                            CampaignId = contactObj.Primary_Campaign__c,
                            contactId = contactObj.Id
                    );
                    campaignMemberList.add(campMemberObj);
                }
            }
            //Campaign Member Assosiation
            if(campaignMemberList!=null && campaignMemberList.size() > 0) {
                Feature_Toggle__c featureToogle = Feature_Toggle__c.getInstance();
                Decimal CampMemberAsyncRecordQantity = featureToogle.CampMemberAsyncRecordQantity__c != null ? featureToogle.CampMemberAsyncRecordQantity__c : 25;
                if (Trigger.new.size() > CampMemberAsyncRecordQantity) {
                    CampaignMemberPlatEvents.campaignMemberCreationAsyncFromContact(campaignMemberList, true);
                } else {
                    insert campaignMemberList;
                }
            }

        } catch(System.Exception e) {
            sObject[] objects = new sObject[]{};
            for (CampaignMember cm : campaignMemberList) {
                objects.add(cm);
            }
            for (Contact cnt : newContacts) {
                objects.add(cnt);
            }
            ExceptionHelper.createExceptionAndNotificacionHistory(e, objects, 'Contact Exception');
        }
    }
    public static void updateAccountsRelated(List<Contact> newContacts, Map<Id,Contact> oldContactsMap, Map<Id,Account> parentAccountMap) {
        Map<Id,Account> AccountsToUpdate = new Map<Id,Account>();
        try {
            Map<String, Certification__c> mcs = Certification__c.getAll();
            Set<Id> accountId = new Set<Id>();
            for (Contact contactObj : newContacts) {
                accountId.add(contactObj.AccountId);
            }
            Map<Id,Account> accountMap = parentAccountMap;
            for (Contact contactObj : newContacts) {
                Contact contactObjOld = oldContactsMap != null ? oldContactsMap.get(contactObj.id) : null;
                if (accountMap.get(contactObj.AccountId) != null) {
                    Account accObjToUpd = AccountsToUpdate.containsKey(contactObj.AccountId) ? AccountsToUpdate.get(contactObj.AccountId) : accountMap.get(contactObj.AccountId);
                    boolean isLastModifiedDate = true;
                    boolean isAccountUpdated = false;
                    if (isLastModifiedDate
                        && (accObjToUpd.Most_Recent_Implementation_Contact__c != contactObj.id
                            || (accObjToUpd.Most_Recent_Implementation_Contact__c == contactObj.id
                            && accObjToUpd.Preferred_Language__c !=  contactObj.Preferred_Language__c))
                    ) {
                        if (!SettingsService.isSwitzerland(accObjToUpd.BillingCountry) &&
                            String.isBlank(accObjToUpd.RC_User_ID__c)) {
                            accObjToUpd.Preferred_Language__c = contactObj.Preferred_Language__c;
                        }
                        accObjToUpd.Most_Recent_Implementation_Contact__c =  contactObj.id;
                        isLastModifiedDate = false;
                        isAccountUpdated = true;
                    }

                    if (!String.isBlank(contactObj.Technical_Certification__c)
                        && accObjToUpd.RecordType.Name == 'Partner Account'
                        && (contactObjOld == null || contactObj.Technical_Certification__c != contactObjOld.Technical_Certification__c)
                    ) {

                        if (accountMap != null && contactObj.AccountId != null) {
                            if (accountMap.get(contactObj.AccountId).Technical_Certification__c == null
                                || accountMap.get(contactObj.AccountId).Technical_Certification__c == 'None'
                                && accountMap.get(contactObj.AccountId) != null
                            ) {
                                accObjToUpd.Technical_Certification__c = contactObj.Technical_Certification__c;
                                isAccountUpdated = true;

                            } else if (accountMap != null && accountMap.get(contactObj.AccountId).Technical_Certification__c != null) {
                                string accountTechCerti = accountMap.get(contactObj.AccountId).Technical_Certification__c;
                                string contactTechCerti = contactObj.Technical_Certification__c;
                                Decimal accountTechCertiRank = mcs.get(accountTechCerti).Rank_in_number__c;
                                Decimal contactTechCertiRank = mcs.get(contactTechCerti).Rank_in_number__c;
                                if (accountTechCertiRank > contactTechCertiRank) {
                                    accObjToUpd.Technical_Certification__c = contactObj.Technical_Certification__c;
                                    isAccountUpdated = true;
                                }
                            }
                        }

                    }
                    if (isAccountUpdated) {
                        AccountsToUpdate.put(accObjToUpd.id, accObjToUpd);
                    }
                }
            }
            if (AccountsToUpdate != null && !AccountsToUpdate.isEmpty()) {
                Triggers.switchOff();
                update AccountsToUpdate.values();
                Triggers.switchOn();
            }
        } catch(Exception e) {
            sObject[] objects = new sObject[]{};
            for(Account acc : AccountsToUpdate.values()) {
                objects.add(acc);
            }
            for(Contact cnt : newContacts) {
                objects.add(cnt);
            }
            ExceptionHelper.createExceptionAndNotificacionHistory(e, objects, 'Contact Exception');
        }
    }
    public static void generateAssetTouches(List<Contact> newContacts, Map<Id,Contact> oldContactsMap, Map<Id,Account> parentAccountMap) {
        List<Asset_Touch__c> assetTouchesToInsert = new List<Asset_Touch__c>();
        for(Contact contactobj : newContacts) {
            if (contactobj.Most_Recent_Asset__c != null &&
            (oldContactsMap == null || ((contactobj.Most_Recent_Asset__c != oldContactsMap.get(contactobj.Id).Most_Recent_Asset__c) || (contactobj.Asset_Id__c != oldContactsMap.get(contactobj.Id).Asset_Id__c)) )) {
                assetTouchesToInsert.addAll(AssetAssignmentHelper.getAssetTouchesForRecord(contactobj));
            }
        }
        if (!assetTouchesToInsert.isEmpty()) {
            AssetAssignmentHelper.processAndUpsertAssetTouchesForInsertion(assetTouchesToInsert, 'Contact', parentAccountMap);
        }
    }


    public static void populateContactStatusToCustomer(list<Contact> lstContact) {
        Contact_Customer_Status_Users__c ContactStatusCS = Contact_Customer_Status_Users__c.getInstance();
        Boolean admitedUser = ContactStatusCS != null && ContactStatusCS.isPopulatingCustomer__c;
        for (Contact con : lstContact) {
           if (admitedUser && con.RCService_ContactStatus__c == 'Active' && con.Account_Status__c != null && (con.Account_Status__c.containsIgnoreCase('Paid') || con.Account_Status__c.containsIgnoreCase('Trial'))) {
               con.Contact_Status__c = '4. Customer';
               con.Customer_record__c = true;
           }
        }
    }

    public static void downgradeInactiveContactForUpdate(Map<Id,Contact> newMapContact, Map<Id,Contact> oldMapContact) {
        Map<Id,Contact> mapInactiveContacts = new Map<Id,Contact>();
        Map<Id,String> contactIdsUnableToDowngradeWithOppName = new Map<Id,String>();
        String opportunityNames = '';

        mapInactiveContacts = getInactiveContactsByRCServiceContactStatus(newMapContact.values(), oldMapContact);

         if (mapInactiveContacts.isEmpty()) {
             return;
         }

         List<OpportunityContactRole> crRelatedToInactiveContacts = (List<OpportunityContactRole>) new OpportunityContactRoleSelector()
                                                                            .selectOCRbyContactsId(
                                                                                new List<Object> { mapInactiveContacts.keySet() }
                                                                                                                            ).executeQuery();

        if (!crRelatedToInactiveContacts.isEmpty()) {
            contactIdsUnableToDowngradeWithOppName = getMapContactIdOpportunityNamesByContactRoles(crRelatedToInactiveContacts);
        }

        if (!contactIdsUnableToDowngradeWithOppName.isEmpty() && !skipContactStatusValidationsByProfileIdOrUserId(UserInfo.getProfileId(), UserInfo.getUserId())) {
            throwErrorMessageForContactsWithOpenOpportunities(contactIdsUnableToDowngradeWithOppName,newMapContact);
        }

        for (Contact con : mapInactiveContacts.values()) {
            if (!contactIdsUnableToDowngradeWithOppName.containsKey(con.Id)) {
                con.Contact_Status__c = '0. Downgraded';
            }
        }
    }

    public static void throwErrorMessageForContactsWithOpenOpportunities(Map<Id,String> mapContactIdOpportunityNames, Map<Id,Contact> mapContacts) {
        for (Id contactId : mapContactIdOpportunityNames.keySet()) {
            Contact c = (Contact) mapContacts.get(contactId);
            c.addError('The contact ' +  (c.FirstName !=null ? c.FirstName.toUpperCase() + ' ' : '') + c.lastName.toUpperCase()
            + ' cannot be set to inactive because it is primary on the following open Opportunities: ' + mapContactIdOpportunityNames.get(contactId));
        }
    }

    public static void downgradeInactiveContactForInsert(List<Contact> listContacts) {
        for (Contact con : listContacts) {
            if (con.RCService_ContactStatus__c  == 'Inactive') {
                con.Contact_Status__c = '0. Downgraded';
            }
         }
    }

    public static Map<Id,String> getMapContactIdOpportunityNamesByContactRoles(List<OpportunityContactRole> contactRoles) {
        Map<Id,String> contactIdsUnableToDowngradeWithOppName = new Map<Id,String>();
        String opportunityNames = '';
        for (OpportunityContactRole oppCR : contactRoles) {
            if (oppCR.Opportunity.isClosed == false && oppCR.isPrimary == true ) {
                if (!contactIdsUnableToDowngradeWithOppName.containsKey(oppCR.ContactId)) {
                    contactIdsUnableToDowngradeWithOppName.put(oppCR.ContactId, oppCR.Opportunity.Name);
                } else {
                    opportunityNames = contactIdsUnableToDowngradeWithOppName.get(oppCR.ContactId) + ', ' + oppCR.Opportunity.Name;
                    contactIdsUnableToDowngradeWithOppName.put(oppCR.ContactId, opportunityNames);
                }
            }
        }
        return contactIdsUnableToDowngradeWithOppName;
    }

    public static Map<Id,Contact> getInactiveContactsByRCServiceContactStatus(List<Contact> contacts, Map<Id, Contact> oldMapContact) {
        Map<Id,Contact> mapInactiveContacts = new Map<Id,Contact>();
        for (Contact con : contacts) {
            Boolean RCServiceContactStatusHasChanged = oldMapContact.get(con.Id).RCService_ContactStatus__c != con.RCService_ContactStatus__c;
            if (RCServiceContactStatusHasChanged && con.RCService_ContactStatus__c  == 'Inactive') {
                mapInactiveContacts.put(con.Id, con);
            }
         }
         return mapInactiveContacts;
    }

    public static void createCustomNotification(String Title, String Body, Id Recipent, String recordId) {
        CustomNotificationType notificationType =
            [SELECT Id, DeveloperName
             FROM CustomNotificationType
             WHERE DeveloperName='Notification_Toast'];

        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setTitle(Title);
        notification.setBody(Body);
        notification.setTargetId(recordId);
        notification.setNotificationTypeId(notificationType.Id);
        notification.send(new Set<String> {Recipent});
    }

    public static Boolean skipContactStatusValidationsByProfileIdOrUserId(Id profileId, Id userId){
        if (skipContactStatusValidations == null) {
            List<Excluded_profiles_for_Contact_Status__mdt> ExcludedProfilesForContactStautsValidations = Excluded_profiles_for_Contact_Status__mdt.getAll().values();

            skipContactStatusValidations = false;

            for (Excluded_profiles_for_Contact_Status__mdt profile : ExcludedProfilesForContactStautsValidations) {
                if (profile.Id__c == profileId || profile.UserId__c == userId) {
                    skipContactStatusValidations = true;
                    break;
                }
            }
        }
        return skipContactStatusValidations;
    }

    public static void validateContactStatus(List<Contact> newContacts, Map<Id,Contact> oldContactsMap){
        for(Contact con : newContacts){
            if (MQL_CONTACT_STATUS.contains(con.Contact_Status__c) &&
                    (oldContactsMap == null ||
                    (oldContactsMap != null && (!MQL_CONTACT_STATUS.contains( oldContactsMap.get(con.Id).Contact_Status__c )) ))){
                con.Most_Recent_MQL_Date__c = DateTime.now();
            }
        }
    }
    public static List<Contact> getContactsWithStatusOrOwnerChanges(List<Contact> newContacts, Map<Id,Contact> mapOld) {
        List<Contact> listOfContactsToProcess = new List<Contact>();
        for (Contact con : newContacts) {
            if ((con.Contact_Status__c != mapOld.get(con.Id).Contact_Status__c) ||
                (con.OwnerId != mapOld.get(con.Id).OwnerId)) {
                    listOfContactsToProcess.add(con);
                }
        }
        return listOfContactsToProcess;
    }
}