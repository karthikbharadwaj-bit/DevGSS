public with sharing class ContactTriggerHandler {
    public static Map<Id, Account> parentAccountMap = new Map<Id, Account>();
    public static Map<Id, User> userStaticMap = new Map<Id, User>();
    private static Set<Id> createdByIds = new Set<Id>();
    private static Map<Id, String> createdByContactMap = new Map<Id, String>();
    private static final String ENGAGE_CONTACT_DELETION_RESTRICTED = 'Contact can\'t be deleted until it is set as Primary Contact Role for Engage Account';
    @TestVisible
    private static final String PRIMARY_OPPORTUNITY_CONTACT_RESTRICTED = 'The Contact {0} is Primary Contact on the following Opportunities: ';
    public static Boolean bypassTrigger = false;
    public static final String CONTACT_STATUS_DOWNGRADED = '0. Downgraded';
    public static final String CONTACT_STATUS_RENEW = '.5 Re-New';
    public static final String CONTACT_STATUS_WORKINGOPP = '3. Working Opp';
    public static final String CONTACT_STATUS_CLOSED_WON_OPP = '3.5 Closed Won Opp';
    public static final String CONTACT_STATUS_CUSTOMER = '4. Customer';
    public static final String CONTACT_STATUS_UPSELL = '5. Upsell';

    public static Map<Id, String> getCreatedByContactMap() {
        if (createdByContactMap.isEmpty()) {
            for (Contact con : [
                SELECT Id, CreatedBy.Name
                FROM Contact
                WHERE Id IN :Trigger.newMap.keySet()
            ]) {

                createdByContactMap.put(con.Id, con.CreatedBy.Name);
            }
            createdByIds = new Set<Id>();
            createdByIds.addAll(Trigger.newMap.keySet());
        } else if (!createdByIds.containsAll(Trigger.newMap.keySet())) {
            createdByIds.addAll(Trigger.newMap.keySet());
            for (Contact con : [
                SELECT Id, CreatedBy.Name
                FROM Contact
                WHERE Id IN :Trigger.newMap.keySet()
            ]) {

                createdByContactMap.put(con.Id, con.CreatedBy.Name);
            }
        }
        return createdByContactMap;
    }

    public class ProcessDUNSLogic extends Triggers.TriggerHandlerBase {
        override public void handle() {

            if (TriggerHandler.BY_PASS_CONTACT_ON_INSERT) {
                System.debug('### RETURNED FROM CONTACT AFTER TRG ###');
                return;
            }

            if (!System.isBatch() && (Limits.getLimitQueueableJobs() != Limits.getQueueableJobs())
                && ConvertLead.IS_LEAD_CONVERT_PROCESSING == false
                && !SyncAccountWsBilling.isLegacyCCMigrationProcess()
            ) {
                if (Trigger.isInsert) {
                    System.enqueueJob(new ContactQueueable(Trigger.new));
                } else if (Trigger.isUpdate) {
                    System.enqueueJob(new ContactQueueable(Trigger.new, (Map<Id, Contact>) Trigger.oldMap));
                }
            } else if (!SyncAccountWsBilling.isLegacyCCMigrationProcess()) {
                Map<Id, Contact> oldMapContact = Trigger.isUpdate ? (Map<Id, Contact>) Trigger.oldMap : new Map<Id, Contact>();
                ContactTriggerHelper.updateLeadspaceAccount(Trigger.new, oldMapContact);
            }

            //Company Persons object decomissioning
            ByPassTrigger__c bypassTrigger = ByPassTrigger__c.getInstance();
            if (!bypassTrigger.Bypass_Company_Process_Logic__c && Trigger.isInsert) {

                Set<Id> accountIds = new Set<Id>();
                for (Contact contact : (List<Contact>) Trigger.new) {
                    if (!accountIds.contains(contact.AccountId)) {
                        accountIds.add(contact.AccountId);
                    }
                }

                Map<Id, Account> accIdMap = new Map<Id, Account>();
                for (Account account : [
                    SELECT SignupType__c, SignupPlatform__c, Name, RC_Account_Status__c, AH_Name__c,
                        RC_Account_Number__c, RC_User_ID__c, RC_Tier__c, RC_Brand__c, RC_Service_name__c,
                        CreatedDate, Company_DUNS__c, Most_Recent_Opportunity_Stage__c
                    FROM Account
                    WHERE Id IN :accountIds
                ]) {
                    accIdMap.put(account.Id, account);
                }
                List<Company_Persons__c> newCompanyPersons = new List<Company_Persons__c>();
                for (Contact contact : (List<Contact>) Trigger.new) {
                    if (contact.AccountId != null && String.isNotBlank(accIdMap.get(contact.AccountId).AH_Name__c)
                        && ContactTriggerHandler.getCreatedByContactMap().get(contact.Id) != 'RCESB'              // TODO: Move out of cycle
                        && contact.Marketo_Sync_Disabled__c == false) {
                        Company_Persons__c newCompanyPerson = new Company_Persons__c(
                            Contact__c = contact.Id,
                            Company__c = accIdMap.get(contact.AccountId).AH_Name__c
                        );
                        newCompanyPersons.add(newCompanyPerson);
                    }
                }

                if (newCompanyPersons.size() > 0) {
                    insert newCompanyPersons;
                }
            }
        }

    }

    public class OldContactTriggerLogicAfter extends Triggers.TriggerHandlerBase {
        override public void handle() {
            //To by pass trigger when converting lead from Relayware
            if (UserInfo.getName() == 'API User') {
                System.debug('### RETURNED FROM CONTACT AFTER TRG For Relayware###');
                return;
            }

            if (!Test.isRunningTest() && (TriggerHandler.BY_PASS_CONTACT_ON_INSERT
                || TriggerHandler.BY_PASS_CONTACT_ON_UPDATE
                || TriggerHandler.BY_PASS_CONTACT_ON_AFTER)) {
                System.debug('### RETURNED FROM CONTACT AFTER TRG ###');
                return;
            } else {
                TriggerHandler.BY_PASS_CONTACT_ON_AFTER = true;
                System.debug('### STILL CONTINUE FROM CONTACT AFTER TRG ###');
            }

            List<Contact> newContacts = (List<Contact>) Trigger.new;
            Map<Id, Contact> newContactsMap = (Map<Id, Contact>) Trigger.newMap;
            Map<Id, Contact> oldContactsMap = (Map<Id, Contact>) Trigger.oldMap;
            parentAccountMap = ContactTriggerHelper.getparentAccountMap(newContacts);

            if (Trigger.isInsert) {
                ContactTriggerHelper.leadCreation(newContacts, parentAccountMap);
                ContactTriggerHelper.campaignMemberGeneration(newContacts);
            }

            ContactTriggerHelper.updateAccountsRelated(newContacts, oldContactsMap, parentAccountMap);


            ContactTriggerHelper.generateAssetTouches(newContacts, oldContactsMap, parentAccountMap);

            /********************* DFR CODE (DemandGen) - Start ***********************************/
            if (Trigger.isUpdate && Trigger.isAfter) {
                try {
                    if (DG_DFR_Class.byPassDFRContact || ConvertLead.IS_LEAD_CONVERT_PROCESSING) {
                        return;
                    }
                    if (DG_DFR_Class.ContactAfterUpdate_FirstRun || Test.isRunningTest()) {
                        if (!Queueable_DG_DFR_Class.isQueueuableLimitsReached()) {
                            List<Contact> contactsToProcess = ContactTriggerHelper.getContactsWithStatusOrOwnerChanges(newContacts, oldContactsMap);
                            Map<Id,Contact> mapOldContactsToProcess = new Map<Id,Contact>();
                            for (Contact ct : contactsToProcess) {
                                mapOldContactsToProcess.put(ct.Id,oldContactsMap.get(ct.Id));
                            }
                            System.enqueueJob(new Queueable_DG_DFR_Class.DFR_Contacts(contactsToProcess, mapOldContactsToProcess));
                        } else {
                            DG_DFR_Class.dfrContacts(newContacts, oldContactsMap);
                            DG_DFR_Class.DFR_ChangeContactOwner(newContacts, oldContactsMap);
                        }
                        DG_DFR_Class.ContactAfterUpdate_FirstRun = false;
                    }
                } catch (Exception e) {
                    DG_DFR_Class.dfrSaveException(e, null, null, newContacts, null);
                }
            }

            if (Trigger.isInsert && Trigger.isAfter) {
                try {
                    if (DG_DFR_Class.ContactAfterUpdate_FirstRun || Test.isRunningTest()) {
                        if (!Queueable_DG_DFR_Class.isQueueuableLimitsReached()) {
                            System.enqueueJob(new Queueable_DG_DFR_Class.DFR_Contacts(newContacts, null));
                        } else {
                            DG_DFR_Class.dfrContactCreation(newContacts);
                        }
                        DG_DFR_Class.ContactAfterUpdate_FirstRun = false;
                    }
                } catch (Exception e) {
                    DG_DFR_Class.dfrSaveException(e, null, null, newContacts, null);
                }
            }

            /********************* DFR CODE (DemandGen) - End ***********************************/
        }
    }

    public class OldContactTriggerLogicBefore extends Triggers.TriggerHandlerBase {
        override public void handle() {
            //To by pass trigger when converting lead from Relayware
            if (UserInfo.getName() == 'API User') {
                System.debug('### RETURNED FROM CONTACT BEFORE TRG For Relayware###');
                return;
            }

            if (TriggerHandler.BY_PASS_CONTACT_ON_INSERT
                || TriggerHandler.BY_PASS_CONTACT_ON_UPDATE
                || TriggerHandler.BY_PASS_CONTACT_ON_BEFORE) {
                System.debug('### RETURNED FROM CONTACT BEFORE TRG ###');
                return;
            } else {
                TriggerHandler.BY_PASS_CONTACT_ON_BEFORE = true;
                System.debug('### STILL CONTINUE FROM CONTACT BEFORE TRG ###');
            }

            List<Contact> newContacts = (List<Contact>) Trigger.new;
            Map<Id, Contact> newContactsMap = (Map<Id, Contact>) Trigger.newMap;
            Map<Id, Contact> oldContactsMap = (Map<Id, Contact>) Trigger.oldMap;

            Map<Id, User> userMap = ContactTriggerHelper.getOwnerUsersMap(newContacts);

            if (Trigger.isInsert) {

                ContactTriggerHelper.assignCampaignsToContactsProcess(Trigger.new, null);
                //No_of_Employee Range Mapping
                ContactTriggerHelper.validateEmployeeRangeForNumericValues(newContacts);
                ContactTriggerHelper.getCheckForBadValue(newContacts);

                //Field Update in Contact on basis of Account Status.
                ContactTriggerHelper.updateContactOnAccount(newContacts);

                //Assign Campaign
                ContactLeadAssignmentHelper.assignCampaignToContact(newContacts);

                //Assign Asset
                AssetAssignmentHelper.assignAssets(newContacts);

                //Assign RCSF Sync owner for contact id the current owner is inactive
                ContactTriggerHelper.assignRCSFSyncOwnerForInactiveOwners(newContacts, userMap);

                /********************************************************/

                /*Added for chking duplicate mail id on Account*/
                chkContactOnAccount.areContactMailAllowedInsertUpdate(newContacts, null);

                ContactTriggerHelper.populateIndexEmailAndPhone(newContacts);
                ContactTriggerHelper.validateContactStatus(newContacts, null);
            }

            if (Trigger.isUpdate) {
                AssetAssignmentHelper.reassignAssets(newContacts, oldContactsMap);
                chkContactOnAccount.areContactMailAllowedInsertUpdate(newContacts, oldContactsMap);
                ContactTriggerHelper.populateIndexPhoneEmailAndNOfEmployees(newContacts, oldContactsMap);
                ContactTriggerHelper.validateContactStatus(newContacts, oldContactsMap);
            }
            ContactLeadAssignmentHelper.validateCampaign(newContacts);
            ContactTriggerHelper.updateFlagForMarketoBatch(newContacts);

        }
    }


     public class ValidateContactedit extends Triggers.TriggerHandlerBase {
        List<sObject> accobj = new List<sObject>();
        List<sObject> oppobj  = new List<sObject> ();
        String PERMESSIONSET_NAME_ACCOUNT = 'EditAccountContactRole';
        String PERMESSIONSET_NAME_OPP = 'EditOpportunityContact';
        Boolean hasCustomPermission = FeatureManagement.checkPermission(PERMESSIONSET_NAME_ACCOUNT) || FeatureManagement.checkPermission(PERMESSIONSET_NAME_OPP);

        Map<Id, Contact> newContactMap = (Map<Id,Contact>)Trigger.newMap;
        Map<Id, Contact> oldContactsMap = (Map<Id, Contact>) Trigger.oldMap;
        private final String CONTACT_CHANGE_RESTRICTED = 'Contact cannot be modified. Please contact Deal Desk for any questions.';
        List<Boolean> isexistingaccount = new List<Boolean>();
        override public void handle() {
            Set<Id> contsIdSet = new Set<Id>();
            for (Contact contactRecord : [SELECT Id, salutation, FirstName, LastName, Email, AccountId, Phone, Account.Active_Sales_Agreement__c, Account.RC_Account_Status__c FROM Contact WHERE Id IN :Trigger.new]) {
                contsIdSet.add(contactRecord.Id);
                Boolean exacc = false;
                Contact oldContact = oldContactsMap.get(contactRecord.Id);

                if (contactRecord.AccountId != null) {
                    if (!hasCustomPermission && (contactRecord.Account.RC_Account_Status__c != null && contactRecord.Account.RC_Account_Status__c == 'Paid' || contactRecord.Account.Active_Sales_Agreement__c != null)) {
                        if(contactRecord.salutation != oldContact.salutation || contactRecord.FirstName != oldContact.FirstName || contactRecord.LastName != oldContact.LastName || contactRecord.Email != oldContact.Email || contactRecord.Phone != oldContact.Phone){
                            exacc = true;
                        }
                    }
                }
                isexistingaccount.add(exacc);
            }
            if (contsIdSet.isEmpty()) {
                return;
            }
            if (ConvertLead.IS_LEAD_CONVERT_PROCESSING) {
                return;
            }
            System.debug('contsIdSet' + contsIdSet);
            System.debug('isexistingaccount' + isexistingaccount);
            for (Boolean isexisting : isexistingaccount) {
                if (isexisting) {
                    accobj = validateChangeContact('AccountContactRole', contsIdSet);
                    oppobj = validateChangeContact('OpportunityContactRole', contsIdSet);

                    if (!accobj.isEmpty()) {
                        System.debug('accobj' + accobj);
                        //accobj
                        for (SObject obj1 : accobj) {
                            Id contactId = (Id) obj1.get('ContactId');
                            newContactMap.get(contactId).addError(CONTACT_CHANGE_RESTRICTED);
                        }
                    }
                    if (!oppobj.isEmpty()) {
                        System.debug('oppobj' + oppobj);

                        for (SObject obj1 : oppobj) {
                            Id contactId = (Id) obj1.get('ContactId');
                            newContactMap.get(contactId).addError(CONTACT_CHANGE_RESTRICTED);
                        }
                    }
                }
            }
        }
        
        @TestVisible
        private List<SObject> validateChangeContact(String objectName, Set<Id> contactIdSet) {
            String query = 'SELECT Id, ContactId, Role, IsPrimary FROM ' + objectName +
                ' WHERE ContactId IN :contactIdSet AND (IsPrimary = true)';
            List<SObject> sobjList = Database.query(query);
            return sobjList;
        }
    }

    // Remove Company Persons if related Contact was deleted.
    public class RemoveUnnecessaryCompanyPersons extends Triggers.TriggerHandlerBase {
        override public void handle() {
            //Company Persons object decomissioning
            ByPassTrigger__c bypassTrigger = ByPassTrigger__c.getInstance();
            if (!bypassTrigger.Bypass_Company_Process_Logic__c) {

                List<Company_Persons__c> companyPersons = new List<Company_Persons__c>();
                for (Company_Persons__c person : [
                    SELECT Lead__c
                    FROM Company_Persons__c
                    WHERE Contact__c IN :Trigger.oldMap.keySet()
                ]) {
                    if (person.Lead__c == null) {
                        companyPersons.add(person);
                    }
                }
                if (!companyPersons.isEmpty()) {
                    delete companyPersons;
                }

            }//Company Persons object decomissioning ends
        }
    }

    public class CampaingAttributionAndCampaignMemberCreation extends Triggers.TriggerHandlerBase {
        public Map<Id, Contact> oldMap = (Map<Id, Contact>) Trigger.oldMap;
        override public void handle() {
            Feature_Toggle__c featureToogle = Feature_Toggle__c.getInstance();
            if (Trigger.isUpdate && !TriggerHandler.BY_PASS_CONTACT_ON_UPDATE) {
                Set<Id> campaignIds = new Set<Id>();
                List<Contact> contactsMrc = new List<Contact>();
                List<CampaignMember> campaignMemberList;
                List<Id> contactIdsBindings = new List<Id>();
                List<Id> campaignIdsBindings = new List<Id>();

                ContactTriggerHelper.assignCampaignsToContactsProcess(Trigger.new, oldMap);

                for (Contact updatedContact : (List<Contact>) Trigger.new) {
                    Id newCampaign = updatedContact.Most_Recent_Campaign__c;
                    Id oldCampaign = oldMap.get(updatedContact.Id).Most_Recent_Campaign__c;
                    if (newCampaign != null && newCampaign != oldCampaign) {
                        contactIdsBindings.add(updatedContact.Id);
                        campaignIdsBindings.add(newCampaign);
                        contactsMrc.add(updatedContact);
                        campaignIds.add(newCampaign);
                        campaignIds.add(oldCampaign);
                    }
                }
                campaignMemberList = ContactTriggerHelper.campaignAttribution(campaignIds, contactsMrc, oldMap);
                List<CampaignMember> existingCampMembs = ContactTriggerHelper.getExistingCampMembers(contactIdsBindings, campaignIdsBindings);

                for (CampaignMember cm : existingCampMembs) {
                    ((Contact) Trigger.newMap.get(cm.ContactId)).Most_Recent_Campaign_Member_Status__c = cm.Status;
                }

                campaignMemberList = ContactTriggerHelper.removeExistingCampMembers(existingCampMembs, campaignMemberList);
                if (campaignMemberList != null && !campaignMemberList.isEmpty()) {
                    try {
                        Decimal CampMemberAsyncRecordQantity = featureToogle.CampMemberAsyncRecordQantity__c != null ? featureToogle.CampMemberAsyncRecordQantity__c : 25;
                        if (Trigger.new.size() > CampMemberAsyncRecordQantity) {
                            CampaignMemberPlatEvents.campaignMemberCreationAsyncFromContact(campaignMemberList, false);
                        } else {
                            TriggerHandler.BY_PASS_CAMPAIGNMEMBER_TRIGGER_FIREPLATFORMEVENTCHECK = true;
                            TriggerHandler.BY_PASS_CAMPAIGNMEMBER_TRIGGER_CAMPAIGNATTRIBUTION = true;
                            TriggerHandler.BY_PASS_CAMPAIGNMEMBER_TRIGGER_FIREPLATFORMEVENTLOG = true;
                            insert campaignMemberList;
                            TriggerHandler.BY_PASS_CAMPAIGNMEMBER_TRIGGER_FIREPLATFORMEVENTCHECK = false;
                            TriggerHandler.BY_PASS_CAMPAIGNMEMBER_TRIGGER_CAMPAIGNATTRIBUTION = false;
                            TriggerHandler.BY_PASS_CAMPAIGNMEMBER_TRIGGER_FIREPLATFORMEVENTLOG = false;
                        }
                    } catch (Exception e) {
                        AquivaHelper.throwAquivaException(' Exception occured on Campaign member creation: ' + e.getMessage() + ' \r\n');
                        ExceptionHelper.createExceptionAndNotificacionHistory(e, campaignMemberList, 'Contact Exception');
                    }
                }
            }
        }
    }

    public class ValidateContactDeletion extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Map<Id, Contact> contactMap = (Map<Id, Contact>) Trigger.oldMap;
            List<Opportunity> opps = new List<Opportunity>();
            if (!contactMap.isEmpty()) {
            	opps = new OpportunitySelector()
                .selectOpportunitiesByPrimaryOpportunityContact(new List<Object>{
                    contactMap.keySet()
                })
                .executeQuery();
            }
            Map<Id, String> mapContactErrors = new Map<Id, String>();
            for (Opportunity opp : opps) {
                if (!mapContactErrors.containsKey(opp.Primary_Opportunity_Contact__c)) {
                    String contactFirstName = contactMap.get(opp.Primary_Opportunity_Contact__c).FirstName;
                    String contactLastName = contactMap.get(opp.Primary_Opportunity_Contact__c).LastName;
                    String contactName = !String.isBlank(contactFirstName) ? contactFirstName : '';
                    contactName += !String.isBlank(contactLastName) ? ' ' + contactLastName : '';
                    mapContactErrors.put(
                        opp.Primary_Opportunity_Contact__c,
                        String.format(PRIMARY_OPPORTUNITY_CONTACT_RESTRICTED,
                            new List<Object>{
                                contactName
                            }));
                }
                String contactError = mapContactErrors.get(opp.Primary_Opportunity_Contact__c);
                mapContactErrors.put(opp.Primary_Opportunity_Contact__c, contactError + '\'' + opp.Name + '\' , ');
            }
            for (Id conId : mapContactErrors.keySet()) {
                Contact primaryOpportunityContact = contactMap.get(conId);
                primaryOpportunityContact.addError(mapContactErrors.get(conId).removeEnd(' , '));
            }
            /* Potentially Engage Account contact roles */
            List<AccountContactRole> acRoleList = new List<AccountContactRole>();
            if (!contactMap.isEmpty()) {
            	acRoleList = new AccountContactRoleSelector()
                .selectAccountContactRolesByContactIds(new List<Object>{
                    contactMap.keySet()
                })
                .selectFields(new List<String>{
                    'AccountId'
                })
                .setCondition('ContactId IN :bind0 AND IsPrimary = true AND Role = \'' +
                    +OpportunityHelper.CONTACT_ROLE_SIGNATORY + '\'')
                .executeQuery();
            }
            Set<Id> accIds = new Set<Id>();
            for (AccountContactRole role : acRoleList) {
                accIds.add(role.AccountId);
            }
            /* Potentially Engage Accounts*/
            List<Quote> quotes = (List<Quote>) new QuoteSelector()
                .selectQuotesForAccount(accIds)
                .executeQuery();

            Set<Id> engageAccIds = getEngageAccounts(quotes);

            if (acRoleList != null && engageAccIds != null && !engageAccIds.isEmpty()){
                for (AccountContactRole role : acRoleList) {
                    if (engageAccIds.contains(role.AccountId)) {
                        Contact primarySignatoryContact = contactMap.get(role.ContactId);
                        if (primarySignatoryContact != null) {
                            primarySignatoryContact.addError(ENGAGE_CONTACT_DELETION_RESTRICTED);
                        }
                    }
                }
            }
        }

        private Set<Id> getEngageAccounts(List<Quote> quotes) {
            Set<Id> engageAccIds = new Set<Id>();
            for (Quote qt : quotes) {
                Boolean isEngageAccount = QuoteHelper.isEngageUService(qt)
                    || QuoteHelper.isEngageVService(qt)
                    || QuoteHelper.isEngageOmnichannelService(qt);
                if (isEngageAccount) {
                    engageAccIds.add(qt.AccountId);
                }
            }
            return engageAccIds;
        }
    }

    public class ValidateContactStatusChange extends Triggers.TriggerHandlerBase {
        override public void handle() {
            if (TriggerHandler.BY_PASS_CONTACT_ON_UPDATE) {
                return;
            }
            Set<Id> contactsIdWithStatusChangeToDowngraded = new Set<Id>();
            List<Contact> accCancelledContacts = new List<Contact>();
            Boolean isProcessingOneRecord = Trigger.new.size() == 1 ? true : false;

            Boolean skipContactStatusValidations = ContactTriggerHelper.skipContactStatusValidationsByProfileIdOrUserId(
                UserInfo.getProfileId(),
                UserInfo.getUserId()
            );

            Map<Id, Contact> contactWithAcc = new Map<Id, Contact>(
                (List<Contact>) new ContactSelector()
                    .selectContactsByIdsForStatusUpdate(new List<Object>{
                        Trigger.oldMap.keySet()
                    })
                    .executeQuery()
            );

            for (Contact c : (List<Contact>) Trigger.new) {
                if (isChangedField(c, Contact.Contact_Status__c)) {
                    Contact oldContact = ((Contact) Trigger.oldMap.get(c.Id));
                    if (
                        c.Contact_Status__c != CONTACT_STATUS_DOWNGRADED &&
                            ((String.isNotBlank(c.Account_Status__c) &&
                                c.Account_Status__c.startsWithIgnoreCase('Cancel')) || contactWithAcc.get(c.Id).Account.RC_Churn_Date__c != null)
                    ) {
                        if (isProcessingOneRecord) {
                            PlatformEvents.publishPlatformEvent(
                                new Notification_Toast__e(
                                    Mode__c = 'sticky',
                                    Message__c = 'The associated account has been cancelled.',
                                    Title__c = 'Please associate a new account or contact the account owner.',
                                    Variant__c = 'warning',
                                    RecordId__c = c.Id,
                                    UserId__c = c.LastModifiedById
                                ),
                                'ContactTriggerHandler'
                            );
                        }
                        accCancelledContacts.add(c);
                    } else if (
                        !skipContactStatusValidations &&
                            oldContact.Contact_Status__c == CONTACT_STATUS_CUSTOMER &&
                            c.Contact_Status__c != CONTACT_STATUS_RENEW &&
                            c.Contact_Status__c != CONTACT_STATUS_DOWNGRADED &&
                            c.Contact_Status__c != CONTACT_STATUS_UPSELL
                    ) {
                        c.addError(
                            'This contact is a customer of RingCentral. You can only change status to .5 Re-New or 0. Downgraded'
                        );
                    } else if (c.Contact_Status__c == CONTACT_STATUS_DOWNGRADED) {
                        if (c.Customer_Record__c) {
                            c.Contact_Status__c = CONTACT_STATUS_CUSTOMER;
                            if (isProcessingOneRecord) {
                                PlatformEvents.publishPlatformEvent(
                                    new Notification_Toast__e(
                                        Mode__c = 'sticky',
                                        Message__c = 'The status will be set to "4. Customer"',
                                        Title__c = 'This contact is a customer of RingCentral.',
                                        Variant__c = 'warning',
                                        RecordId__c = c.Id,
                                        UserId__c = UserInfo.getUserId())
                                    , 'ContactTriggerHandler');
                            }
                        } else if (!skipContactStatusValidations) {
                            contactsIdWithStatusChangeToDowngraded.add(String.valueOf(c.Id));
                        }
                    }
                }
            }

            if (!accCancelledContacts.isEmpty()) {
                ContactUpdatePlatformEventsHelper.accCancelledContsToSend = accCancelledContacts;
                ContactUpdatePlatformEventsHelper.addContactsForHandRaiseEmail();
            }

            Map<Id, List<Opportunity>> OpportunitiesByContactIdToAddError = new Map<Id, List<Opportunity>>();
            if (!contactsIdWithStatusChangeToDowngraded.isEmpty()) {
                for (
                    Opportunity opp : (List<Opportunity>) new OpportunitySelector()
                    .selectOpportunitiesByPrimaryOpportunityContactAndOpenOpportunity(
                        new List<Object>{
                            new List<Id>(contactsIdWithStatusChangeToDowngraded)
                        }
                    )
                    .executeQuery()
                ) {
                    if (!OpportunitiesByContactIdToAddError.containsKey(opp.Primary_Opportunity_Contact__c)) {
                        OpportunitiesByContactIdToAddError.put(
                            opp.Primary_Opportunity_Contact__c,
                            new List<Opportunity>{
                            }
                        );
                    }
                    OpportunitiesByContactIdToAddError.get(opp.Primary_Opportunity_Contact__c).add(opp);

                    //This remove is because when we will perform the query on OpportunityContactRole we won't want to repeat the same values, only the values that weren't processed the first time.
                    contactsIdWithStatusChangeToDowngraded.remove(String.valueOf(opp.Primary_Opportunity_Contact__c));
                }
            }

            if (!contactsIdWithStatusChangeToDowngraded.isEmpty()) {
                for (OpportunityContactRole ocr : (List<OpportunityContactRole>) new OpportunityContactRoleSelector()
                    .selectOCRWhereOpportunityIsOpenAndContactIdMatchesAndIsPrimary(new Object[]{
                        new List<Id>(contactsIdWithStatusChangeToDowngraded)
                    })
                    .executeQuery()
                ) {
                    if (!OpportunitiesByContactIdToAddError.containsKey(ocr.ContactId)) {
                        OpportunitiesByContactIdToAddError.put(ocr.ContactId, new List<Opportunity>{
                        });
                    }
                    OpportunitiesByContactIdToAddError.get(ocr.ContactId).add(ocr.Opportunity);
                }
            }

            if (!OpportunitiesByContactIdToAddError.isEmpty()) {
                for (String contactId : OpportunitiesByContactIdToAddError.keySet()) {
                    String oppNames = '';
                    for (Opportunity opp : OpportunitiesByContactIdToAddError.get(contactId)) {
                        oppNames += '\'' + opp.Name.toUpperCase() + '\' ';
                    }
                    Contact c = (Contact) Trigger.newMap.get(contactId);
                    c.addError('The contact ' + (c.FirstName != null ? c.FirstName.toUpperCase() + ' ' : '') + c.LastName.toUpperCase() + ' cannot be downgraded because it is primary contact on the following open opportunities: ' + oppNames);
                }
            }
        }
    }

    public class WorkflowActions extends Triggers.TriggerHandlerBase {
        override public void handle() {
            ContactTriggerHelper.AMPAdvocateEmailCreatedDateContact((List<Contact>) Trigger.new, (Map<Id, Contact>) Trigger.oldMap);
        }
    }

    public class ContactStatusValidations extends Triggers.TriggerHandlerBase {
        override public void handle() {
            if (Trigger.isInsert) {
                ContactTriggerHelper.populateContactStatusToCustomer(Trigger.new);
                ContactTriggerHelper.downgradeInactiveContactForInsert(Trigger.new);
            }

            if (Trigger.isUpdate) {
                ContactTriggerHelper.downgradeInactiveContactForUpdate((Map<Id, Contact>) Trigger.newMap, (Map<Id, Contact>) Trigger.oldMap);
            }
        }
    }

    public class ContactPhoneNumberValidations extends Triggers.TriggerHandlerBase {
        override public void handle() {
            if (Trigger.isInsert || Trigger.isUpdate) {
                ContactTriggerHelper.phoneNumberValidation(Trigger.new);
            }
        }
    }

    //CMR 267236 - SaaSquatch Contact Logic Updates
    public class PopulateSaasquatchFields extends Triggers.TriggerHandlerBase {

        override public void handle() {

            List<Contact> conList = (List<Contact>) Trigger.new;
            Map<Id, Contact> oldMap = (Map<Id, Contact>) Trigger.oldMap;
            Set<Id> saasquatchIds = new Set<Id>();
            Set<Id> saasquatchAccountIds = new Set<Id>();
            try {
                for (Contact con : conList) {
                    if (con.Email != null && con.Saasquatch_Advocate_Name__c != null && con.Saasquatch_Referral_Email_ID__c == null && oldMap != null && con.Saasquatch_Advocate_Name__c != oldMap.get(con.Id).Saasquatch_Advocate_Name__c) {
                        saasquatchAccountIds.add(con.AccountId);
                        saasquatchIds.add(con.Saasquatch_Advocate_Name__c);
                    }

                    //nullifying the values when saasquatch advocate name is made null
                    if (oldMap != null && (oldMap.get(con.Id).Saasquatch_Advocate_Name__c != con.Saasquatch_Advocate_Name__c) && con.Saasquatch_Advocate_Name__c == null) {
                        con.Saasquatch_Referral_Email_ID__c = null;
                        con.Saasquatch_Advocate_ID__c = null;
                    }
                }
                //population of saasquatch referral email Id and saasquatch Advocate Id field
                if (!saasquatchAccountIds.isEmpty() && !saasquatchIds.isEmpty()) {
                    Map<Id, Account> accMap = new Map<Id, Account>([SELECT Id, Saasquatch_Referral_Email_ID__c FROM Account WHERE Id IN :saasquatchAccountIds]);
                    Map<Id, saasquatch__SaaSquatch_User__c> saasquatchUsersMap = new Map<Id, saasquatch__SaaSquatch_User__c> ([SELECT Id, saasquatch__Referral_Code__c FROM saasquatch__SaaSquatch_User__c WHERE Id IN :saasquatchIds]);
                    if (!accMap.isEmpty() && !saasquatchUsersMap.isEmpty()) {
                        for (Contact con : conList) {
                            if (con.AccountId != null && accMap.containsKey(con.AccountId) && accMap.get(con.AccountId).Saasquatch_Referral_Email_ID__c == null && saasquatchUsersMap.containsKey(con.Saasquatch_Advocate_Name__c) && saasquatchUsersMap.get(con.Saasquatch_Advocate_Name__c).saasquatch__Referral_Code__c != null) {
                                con.Saasquatch_Referral_Email_ID__c = con.Email;
                                con.Saasquatch_Advocate_ID__c = saasquatchUsersMap.get(con.Saasquatch_Advocate_Name__c).saasquatch__Referral_Code__c;
                            }
                        }
                    }
                }
            } catch (Exception e) {
                AquivaHelper.throwAquivaException(' Exception occured on SaaS quatch fields population: ' + e.getMessage() + ' \r\n');
            }
        }
    }

    //CMR-267678 SaaSquatch Contact Logic Updates
    public class PopulateSaasquatchReferralEmailOnAccount extends Triggers.TriggerHandlerBase {

        override public void handle() {

            List<Contact> conList = (List<Contact>) Trigger.new;
            Map<Id, Contact> oldMap = (Map<Id, Contact>) Trigger.oldMap;
            Set<Id> accIds = new Set<Id>();

            try {
                for (Contact con : conList) {
                    if (con != null && con.Saasquatch_Referral_Email_ID__c != null && oldMap != null && con.Saasquatch_Referral_Email_ID__c != oldMap.get(con.Id).Saasquatch_Referral_Email_ID__c) {
                        accIds.add(con.AccountId);
                    }
                }

                if (!accIds.isEmpty()) {
                    Map<Id, Account> accMap = new Map<Id, Account>([SELECT Id, Saasquatch_Referral_Email_ID__c FROM Account WHERE Id IN :accIds]);
                    List<Account> accList = new List<Account>();

                    if (!accMap.isEmpty()) {
                        for (Contact con : conList) {
                            if (con.AccountId != null && accMap.containsKey(con.AccountId) && accMap.get(con.AccountId).Saasquatch_Referral_Email_ID__c == null) {
                                accMap.get(con.AccountId).Saasquatch_Referral_Email_ID__c = con.Saasquatch_Referral_Email_ID__c;
                                accList.add(accMap.get(con.AccountId));
                            }
                        }

                        if (!accList.isEmpty()) {
                            update accList;
                        }
                    }
                }
            } catch (Exception e) {
                AquivaHelper.throwAquivaException(' Exception occured on SaaS quatch referral email field population: ' + e.getMessage() + ' \r\n');
            }
        }
    }

    //CMR-296365 - Customer Data Updates - Contact related list to ZI Account
    public class PopulateContactZIShellAccount extends Triggers.TriggerHandlerBase {

        override public void handle() {

            Set<Id> accIdsToProcess = new Set<Id>();
            Map<Id, Id> shellAccMap = new Map<Id, Id>();
            try {
                for (Contact con : (List<Contact>) Trigger.new) {
                    if (con.AccountId != null && ((Trigger.isInsert) || ((Map<Id, Contact>) Trigger.oldMap != null && (((Contact) Trigger.oldMap.get(con.Id)).AccountId != con.AccountId)))) {
                        accIdsToProcess.add(con.AccountId);
                    }
                }

                if (!accIdsToProcess.isEmpty()) {
                    for (Account acc : [SELECT Id, ParentId, RecordType.Name, Parent.RecordType.Name FROM Account WHERE Id IN :accIdsToProcess]) {
                        if (acc.ParentId != null && acc.RecordType.Name == 'Customer Account' && acc.Parent.RecordType.Name == 'ZI Customer Shell Account') {
                            shellAccMap.put(acc.Id, acc.ParentId);
                        } else if (acc.RecordType.Name == 'ZI Customer Shell Account') {
                            shellAccMap.put(acc.Id, acc.Id);
                        }
                    }
                    if (!shellAccMap.isEmpty()) {
                        for (Contact con : (List<Contact>) Trigger.new) {
                            if (shellAccMap != null && shellAccMap.containsKey(con.AccountId)) {
                                con.ZI_Shell_Account__c = shellAccMap.get(con.AccountId);
                            }
                        }
                    }
                }
            } catch (Exception e) {
                AquivaHelper.throwAquivaException(' Exception occured on ZI Shell Account field population: ' + e.getMessage() + ' \r\n');
            }
        }
    }

    // Disable Customer Community User if Contact disabled
    // (RCService_ContactStatus__c == Inactive)
    public class disableCustomerCommunityUser extends Triggers.TriggerHandlerBase {

        override public void handle() {
            if (Trigger.isAfter && Trigger.isUpdate) {
                List<Contact> contactRecords = (List<Contact>) Trigger.new;
                Map<Id, Contact> oldContactRecords = (Map<Id, Contact>) Trigger.oldMap;
                List<Id> disabledContactsIds = new List<Id>();

                for (Contact contactRecord : contactRecords) {
                    if (contactRecord.RCService_ContactStatus__c == 'Inactive' && oldContactRecords.get(contactRecord.Id).RCService_ContactStatus__c == 'Active') {
                        disabledContactsIds.add(contactRecord.Id);
                    }
                }

                if (disabledContactsIds.size() > 0) {
                    ContactTriggerHandler.disableUsers(disabledContactsIds);
                }
            }
        }

    }

    @Future
    public static void disableUsers(List<Id> disabledContactsIds) {
        List<User> usersForDisable = [SELECT Id, IsActive FROM User WHERE ContactId IN :disabledContactsIds AND IsActive = TRUE AND Profile.UserLicense.Name = 'Customer Community Login'];
        for (User userForDisable : usersForDisable) {
            userForDisable.IsActive = false;
        }

        if (usersForDisable.size() > 0) {

            Triggers.switchOff();

            update usersForDisable;

            Triggers.switchOn();
        }
    }

    //CMR-323768
    //Migration of contact process builder to trigger code to avoid overhead
    //Send user info to saasquatch using invocable methods
    public class upsertSaasquatchReferralUser extends Triggers.TriggerHandlerBase {

        override public void handle() {

            List<SaaSquatch.ReferralSaaSquatchUpsertUserByIdReq> listUsers = new List<SaaSquatch.ReferralSaaSquatchUpsertUserByIdReq>();

            for (Contact con : (List<Contact>) Trigger.new) {

                if (con.Saasquatch_Advocate_Name__c != null && (con.Saasquatch_Advocate_Name__c != ((Map<Id, Contact>) Trigger.oldMap).get(con.Id).Saasquatch_Advocate_Name__c)) {

                    SaaSquatch.ReferralSaaSquatchUpsertUserByIdReq user = new SaaSquatch.ReferralSaaSquatchUpsertUserByIdReq();
                    user.userId = con.Saasquatch_Referral_Email_ID__c;
                    user.accountId = con.Saasquatch_Referral_Email_ID__c;
                    user.firstName = con.FirstName;
                    user.lastName = con.LastName;
                    user.email = con.Email;
                    user.immediatelyUpsertObjects = true;
                    user.referredByCodes = con.Saasquatch_Advocate_ID__c;

                    if (user != null) {
                        listUsers.add(user);
                    }
                }
            }

            if (listUsers.size() > 0) {
                SaaSquatch.ReferralSaaSquatchUpsertUserById.upsertUsers(listUsers);
            }
        }
    }

    public class UpdateRelatedDFR extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<DFR_Update_Field__e> eventList = new List<DFR_Update_Field__e>();

            for (Contact cont : (List<Contact>) Trigger.new) {
                if(cont.Account_Brand__c!=null && System.Label.BizMerge_Brand_Exclusion_List!=null && System.Label.BizMerge_Brand_Exclusion_List.contains(cont.Account_Brand__c)){
                    continue;
                }
                if(isChangedField(cont, Contact.AccountId)){
                    eventList.add(new DFR_Update_Field__e(
                        Id__c = cont.Id,
                        Fields__c = DemandFunnelPlatEvents.ACCOUNT_FIELD
                    ));
                }
            }

            if (eventList.size() > 0) {
                PlatformEvents.publishPlatformEvent(eventList, 'ContactTriggerHandler');
            }
        }
    }

    public class PopulateCustomAccountId extends Triggers.TriggerHandlerBase {
        override public void handle() {
            for (Contact cont : (List<Contact>) Trigger.new) {
                if (isChangedField(cont, Contact.AccountId)) {
                    cont.Matching_Rule_Account__c = cont.AccountId;
                }
            }
        }
    }

    //Create Contact Extensions
    //Commenting as Contact_Ext__c is no longer Used
    /*public class CreateContactExtensions extends Triggers.TriggerHandlerBase {

        override public void handle() {
            try {
                List<Contact_Ext__c> contactExtRecords = new List<Contact_Ext__c>();
                for (Contact ct : (List<Contact>) Trigger.new) {
                    Contact_Ext__c contactExt = new Contact_Ext__c();
                    contactExt.Contact__c = ct.Id;
                    contactExtRecords.add(contactExt);
                }

                if (!contactExtRecords.isEmpty()) {
                    insert contactExtRecords;
                }
            } catch (Exception ex) {
                System.debug('createContactExtensions error : ' + ex.getMessage());
            }
        }
    }*/ 

    public class PopulateDateStatusChanged extends Triggers.TriggerHandlerBase {

        override public void handle() {

            List<Contact> conList = (List<Contact>) Trigger.new;
            Map<Id, Contact> oldMap = (Map<Id, Contact>) Trigger.oldMap;
        
            for (Contact c : conList) {
                try {
                    String oldStatus = (Trigger.isInsert) ? null : oldMap.get(c.Id).Contact_Status__c;
                    String newStatus = c.Contact_Status__c;
    
                    if (oldStatus == newStatus) {
                        continue;
                    }
    
                    c.Date_Status_Changed__c = Date.today();
                } catch (Exception ex) {
                    LeadPlatEvents.leadExceptionCreationAsync(new Exception[]{
                        ex
                    }, 'PopulateDateStatusChanged');
                    throw ex;
                }
            }
        }    

    }
    
    public class RecalculateCDPDeliverStatusAccountField extends Triggers.TriggerHandlerBase {

        private Map<Account, Integer> getCompletedCDPCoursesByAccount(Set<Id> accountIds, List<Id> oldAccountIds) {
            Map<Account, Integer> completedCDPCoursesByAccount = CourseProgressHelper.getCompletedCDPCoursesByAccount(accountIds, new skilljar__Course_Progress__c[]{});
         

            if (oldAccountIds.size() > 0) {
                for (Id accId : oldAccountIds) { //In case the old accounts don't have any contact
                    Boolean doesAccountExist = false;
    
                    for (Account acc : completedCDPCoursesByAccount.keySet()) {
                        if (acc.Id == accId) {
                            doesAccountExist = true;
                            break;
                        }
                    }
    
                    if (!doesAccountExist) {
                        completedCDPCoursesByAccount.put(new Account(Id = accId), 0);
                    }
                }
            }

            return completedCDPCoursesByAccount;
        }

        override public void handle() {
            Map<Id, Id> oldAccountsToRecalculateByContactId = new Map<Id, Id>();
            Map<Id, Id> newAccountsToRecalculateByContactId = new Map<Id, Id>();

            for (Contact cont : (Contact[]) (trigger.isDelete? trigger.old : trigger.new)) {
                Contact oldCont = (Contact) trigger.oldMap.get(cont.Id);
                if (trigger.isDelete || isChangedField(cont, Contact.AccountId)) {
                    if (oldCont.AccountId != null) {
                        oldAccountsToRecalculateByContactId.put(cont.Id, oldCont.accountId);
                    }
                    if (trigger.isUpdate && cont.AccountId != null) {
                        newAccountsToRecalculateByContactId.put(cont.Id, cont.AccountId);
                    }
                }
            }

            if (oldAccountsToRecalculateByContactId.size() > 0 || newAccountsToRecalculateByContactId.size() > 0) {
                Set<Id> accountIds = new Set<Id>(oldAccountsToRecalculateByContactId.values());
                accountIds.addAll(newAccountsToRecalculateByContactId.values());

                Map<Account, Integer> completedCDPCoursesByAccount = getCompletedCDPCoursesByAccount(accountIds, oldAccountsToRecalculateByContactId.values());

                if (trigger.isDelete) {
                    for (Contact cont : [
                        SELECT AccountId, Account.Certified_Delivery_Partner_Status__c, 
                            (SELECT Id 
                                FROM skilljar__Course_Progress__r 
                                WHERE CDP_Course__c = true AND skilljar__Completed_At__c != null
                            )
                        FROM Contact WHERE Id IN :Trigger.old
                    ]) {
                        Account oldAcc = new Account(
                            Id = cont.AccountId, 
                            Certified_Delivery_Partner_Status__c = cont.Account.Certified_Delivery_Partner_Status__c
                        );

                        Integer completedAccountCDPCourses = completedCDPCoursesByAccount.get(oldAcc);

                        completedCDPCoursesByAccount.put(oldAcc, completedAccountCDPCourses - cont.skilljar__Course_Progress__r.size());
                    }
                }

                List<Account> accountsToUpdate = new List<Account>();

                for (Account acc : completedCDPCoursesByAccount.keySet()) {
                    if (acc.Certified_Delivery_Partner_Status__c != CourseProgressHelper.CDP_STATUS_PS_PRMIER_PARTNER) {
                        Integer completedAccountCDPCourses = completedCDPCoursesByAccount.get(acc);
    
                        String newCDPStatus = CourseProgressHelper.calculateCDPStatus(
                            completedAccountCDPCourses, 
                            acc.Certified_Delivery_Partner_Status__c
                        );
                        
                        if (newCDPStatus != acc.Certified_Delivery_Partner_Status__c) {
                            acc.Certified_Delivery_Partner_Status__c = newCDPStatus;
                            accountsToUpdate.add(acc);
                        }
                    }
                }

                if (accountsToUpdate.size() > 0) {
                    update accountsToUpdate;
                }
            }
        }
    }
}