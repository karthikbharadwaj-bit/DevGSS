public with sharing class ContactUpdatePlatformEventsHelper {
    static Map<Id, Set<Id>> contOppMap = new Map<Id, Set<Id>>();
    static Set<Id> oppIds = new Set<Id>();
    static Set<Id> accCancelledContacts = new Set<Id>();
    public static List<Contact> accCancelledContsToSend = new List<Contact>();
    static Map<Id, Contact> dfrOldMap = new Map<Id, Contact>();
    static List<Contact> dfrNewList = new List<Contact>();
    @testVisible
    static Set<Id> paidAccIds = new Set<Id>();
    @testVisible
    public static final String ACCOUNT_CHURNED = 'Account Churned';

    public static void updateContactStatus(List<Contact_Update_ClosedWon_Opp__e> events) {
        Map<Id, Id> primaryContacts = new Map<Id, Id>();
        for (Contact_Update_ClosedWon_Opp__e event : events) {
            if (event.Account_Cancelled__c) {
                accCancelledContacts.add(event.Contact_Id__c);
            }
            if (String.isNotBlank(event.Account_Id__c)) {
                paidAccIds.add(event.Account_Id__c);
            } else if (event.Is_Primary_Contact_Update__c) {
                primaryContacts.put(event.Contact_Id__c, event.Opportunity_Id__c);
            } else {
                oppIds.add(event.Opportunity_Id__c);
                if (event.Contact_Id__c != null) {
                    if (contOppMap.containsKey(event.Contact_Id__c)) {
                        contOppMap.get(event.Contact_Id__c).add(event.Opportunity_Id__c);
                    } else {
                        contOppMap.put(event.Contact_Id__c, new Set<Id>{ event.Opportunity_Id__c });
                    }
                }
            }
        }

        List<Contact> conToUpdate = new List<Contact>();

        if (!oppIds.isEmpty() || !primaryContacts.isEmpty()) {
            getContactsAssociatedToOpps();
            Set<Id> allContacts = new Set<Id>(contOppMap.keySet());
            allContacts.addAll(primaryContacts.keySet());
            getOppsAssociatedToContacts(allContacts);
            oppIds.addAll(primaryContacts.values());
            Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>(
                (List<Opportunity>) new OpportunitySelector()
                    .selectOpportunitiesForContactUpdate(oppIds, contOppMap.keySet())
                    .executeQuery()
            );

            for (Opportunity o : opportunityMap.values()) {
                if (contOppMap.containsKey(o.Primary_Opportunity_Contact__c)) {
                    contOppMap.get(o.Primary_Opportunity_Contact__c).add(o.Id);
                }
            }

            conToUpdate = (List<Contact>) new ContactSelector()
                .selectContactsByIdsForStatusUpdate(new List<Object>{ contOppMap.keySet() })
                .executeQuery();

            conToUpdate = updateContactStatusBasedOnOppsAssociated(conToUpdate, opportunityMap);
        }

        if (!paidAccIds.isEmpty()) {
            conToUpdate = updateContactsWithPaidAccounts();
        }

        try {
            if (!accCancelledContsToSend.isEmpty()) {
                addContactsForHandRaiseEmail();
            }
            ContactTriggerHandler.bypassTrigger = true;
            update conToUpdate;
            ContactTriggerHandler.bypassTrigger = false;
            if (!dfrNewList.isEmpty()) {
                if (!Queueable_DG_DFR_Class.isQueueuableLimitsReached()) {
                    System.enqueueJob(new Queueable_DG_DFR_Class.DFR_Contacts(dfrNewList, dfrOldMap));
                } else {
                    DG_DFR_Class.dfrContacts(dfrNewList, dfrOldMap);
                }
            }
        } catch (Exception e) {
            ExceptionHelper.createExceptionAndNotificacionHistory(e, conToUpdate, 'Contact Exception');
        }
    }

    private static void getContactsAssociatedToOpps() {
        for (
            OpportunityContactRole oppConRole : (List<OpportunityContactRole>) new OpportunityContactRoleSelector()
                .selectOpportunityContactRolesByListOppIds(new List<Object>{ oppIds })
                .executeQuery()
        ) {
            if (contOppMap.containsKey(oppConRole.ContactId)) {
                contOppMap.get(oppConRole.ContactId).add(oppConRole.OpportunityId);
            } else {
                contOppMap.put(oppConRole.ContactId, new Set<Id>{ oppConRole.OpportunityId });
            }
        }
    }

    private static void getOppsAssociatedToContacts(Set<Id> allContacts) {
        for (
            OpportunityContactRole oppConRole : (List<OpportunityContactRole>) new OpportunityContactRoleSelector()
                .selectOpportunityContactRolesByListConIds(new List<Object>{ allContacts })
                .executeQuery()
        ) {
            oppIds.add(oppConRole.OpportunityId);
            if (contOppMap.containsKey(oppConRole.ContactId)) {
                contOppMap.get(oppConRole.ContactId).add(oppConRole.OpportunityId);
            } else {
                contOppMap.put(oppConRole.ContactId, new Set<Id>{ oppConRole.OpportunityId });
            }
        }
    }

    public static String getQuotedProducts(Opportunity opp, String quotProd) {
        if (opp.Estimated_12M_Office_Pipeline__c > 0 && !quotProd.contains('Office')) {
            quotProd += ';Office';
        }
        if (opp.Estimated_12M_Contact_Center_Pipeline__c > 0 && !quotProd.contains('Contact Center')) {
            quotProd += ';Contact Center';
        }
        if (opp.Estimated_12M_Global_Office_Pipeline__c > 0 && !quotProd.contains('Global Office')) {
            quotProd += ';Global Office';
        }
        if (opp.Estimated_12M_Engage_Digital_Pipeline__c > 0 && !quotProd.contains('Engage Digital')) {
            quotProd += ';Engage Digital';
        }
        if (opp.Estimated_12M_Engage_Voice_Pipeline__c > 0 && !quotProd.contains('Engage Voice')) {
            quotProd += ';Engage Voice';
        }
        if (opp.Estimated_12M_RingCentral_Video_Pipeline__c > 0 && !quotProd.contains('RingCentral Video')) {
            quotProd += ';RingCentral Video';
        }
        if (opp.EstimatedProfessionalServices12Month__c > 0 && !quotProd.contains('Professional Services')) {
            quotProd += ';Professional Services';
        }
        return quotProd?.removeStart(';');
    }

    private static List<Contact> updateContactStatusBasedOnOppsAssociated(
        List<Contact> conToUpdate,
        Map<Id, Opportunity> opportunityMap
    ) {
        for (Contact con : conToUpdate) {
            Boolean hasCustomer = false;
            Boolean hasDowngraded = false;
            Boolean hasOpenOpps = false;
            Boolean hasAccCancel = false;
            Boolean hasClosedWonOpp = false;
            Set<Id> contOppIds = contOppMap.get(con.Id);
            if (contOppIds != null) {
                for (Id oppId : contOppIds) {
                    Opportunity opp = opportunityMap.get(oppId);
                    if (opp != null) {
                        if (opp.StageName.equals(OpportunityHelper.STAGE_NAME_CLOSED_WON)) {
                            if (isPaidOrTrial(con.Account_Status__c) || con.Account.RC_Upgrade_Date__c != null) {
                                String quotProd = con.Quoted_Products__c != null ? con.Quoted_Products__c : '';
                                con.Quoted_Products__c = getQuotedProducts(opp, quotProd);
                                hasCustomer = true;
                            } else {
                                hasClosedWonOpp = true;
                            }
                        } else if (opp.StageName == OpportunityHelper.STAGE_NAME_DOWNGRADED) {
                            hasDowngraded = true;
                        } else if (OpportunityHelper.STAGE_NAMES_OPEN.contains(opp.StageName)) {
                            hasOpenOpps = true;
                        }
                    }
                }
                if (isCustomerRecordCheck(con)) {
                    con.Customer_Record__c = true;
                } else {
                    con.Customer_Record__c = hasCustomer;
                }
                if (!hasCustomer) {
                    con.Quoted_Products__c = null;
                }
                if (
                    (String.isNotBlank(con.Account_Status__c) &&
                    con.Account_Status__c.startsWithIgnoreCase('Cancel')) || con.Account.RC_Churn_Date__c != null
                ) {
                    hasAccCancel = true;
                }
                if (hasOpenOpps) {
                    con.Contact_Status__c = ContactTriggerHandler.CONTACT_STATUS_WORKINGOPP;
                    if (hasAccCancel && conToUpdate.size() == 1) {
                        PlatformEvents.publishPlatformEvent(
                            new Notification_Toast__e(
                                Mode__c = 'sticky',
                                Message__c = 'This Contact is associated to an open opportunity. Contact status will be set to "3. Working Opp"',
                                Title__c = 'The associated account has been cancelled. Please associate a new account or contact the account owner.',
                                Variant__c = 'warning',
                                Recordid__c = con.Id,
                                UserId__c = con.LastModifiedById
                            ),
                            'ContactUpdatePlatformEventsHelper'
                        );
                    }
                } else if (hasAccCancel) {
                    dfrOldMap.put(con.Id, con.clone(true, true, true));
                    con.Contact_Status__c = ContactTriggerHandler.CONTACT_STATUS_DOWNGRADED;
                    con.Downgrade_Reason__c = ACCOUNT_CHURNED;
                    dfrNewList.add(con);
                    if (conToUpdate.size() == 1) {
                        PlatformEvents.publishPlatformEvent(
                            new Notification_Toast__e(
                                Mode__c = 'sticky',
                                Message__c = 'Contact status will be set to "0. Downgraded"',
                                Title__c = 'The associated account has been cancelled. Please associate a new account or contact the account owner.',
                                Variant__c = 'warning',
                                Recordid__c = con.Id,
                                UserId__c = con.LastModifiedById
                            ),
                            'ContactUpdatePlatformEventsHelper'
                        );
                    }
                } else if (hasCustomer) {
                    con.Contact_Status__c = ContactTriggerHandler.CONTACT_STATUS_CUSTOMER;
                } else if (hasClosedWonOpp) {
                    con.Contact_Status__c = ContactTriggerHandler.CONTACT_STATUS_CLOSED_WON_OPP;
                } else if (hasDowngraded) {
                    con.Contact_Status__c = ContactTriggerHandler.CONTACT_STATUS_DOWNGRADED;
                }
            }
            if (accCancelledContacts.contains(con.Id)) {
                accCancelledContsToSend.add(con);
            }
        }
        return conToUpdate;
    }

    public static void addContactsForHandRaiseEmail() {
        String contactIds = '';
        for (Contact con : accCancelledContsToSend) {
            if (String.isBlank(contactIds)) {
                contactIds = con.Id;
            } else {
                contactIds += ',' + con.Id;
            }
        }
        Id handRaiseRecordTypeId = Schema.SObjectType.Exception_And_Notification_History__c.getRecordTypeInfosByName()
            .get('Hand Raise Email Sending')
            .getRecordTypeId();
        Exception_And_Notification_History__c eanh = new Exception_And_Notification_History__c(
            RecordTypeId = handRaiseRecordTypeId,
            Affected_record_ID__c = contactIds
        );
        insert eanh;
    }

    @InvocableMethod(
        label='Send Hand Raise Email'
        description='Send Hand Raise Email to cancelled Accounts owner and owner\'s manager'
    )
    public static void sendAccCancelledNotification() {
        if (Feature_Toggle__c.getInstance().Hand_Raise_Email_Sending__c) {
            Report accReport;
            if (!Test.isRunningTest()) {
                accReport = [SELECT Id FROM Report WHERE DeveloperName = :'Cancelled_Account_Contacts_Esu'];
            }
            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
            List<String> excludedEmails = new List<String>();
            for (Hand_Raise_Email_Exclusion__mdt excludedUser : Hand_Raise_Email_Exclusion__mdt.getAll().values()) {
                excludedEmails.add(excludedUser.Email__c);
            }
            Id handRaiseRecordTypeId = Schema.SObjectType.Exception_And_Notification_History__c.getRecordTypeInfosByName()
                .get('Hand Raise Email Sending')
                .getRecordTypeId();
            Set<String> allContactIds = new Set<String>();
            Map<String, Map<String, List<Contact>>> accsByEmail = new Map<String, Map<String, List<Contact>>>();
            List<Exception_And_Notification_History__c> eanhRecords = (List<Exception_And_Notification_History__c>) new ExceptionAndNotificationHistorySelector()
                .selectExceptionAndNotificationHistorysByRecordTypeId(new List<Id>{ handRaiseRecordTypeId })
                .executeQuery();
            for (Exception_And_Notification_History__c eanh : eanhRecords) {
                List<String> contactIds = eanh.Affected_record_ID__c.split(',');
                allContactIds.addAll(contactIds);
            }
            for (
                Contact con : (List<Contact>) new ContactSelector()
                    .selectContactsByIdsForStatusUpdate(new List<Object>{ allContactIds })
                    .executeQuery()
            ) {
                if (excludedEmails.isEmpty() || !excludedEmails.contains(con.Account.Owner.Email)) {
                    if (accsByEmail.containsKey(con.Account.Owner.Email)) {
                        if (accsByEmail.get(con.Account.Owner.Email).containsKey(con.AccountId)) {
                            accsByEmail.get(con.Account.Owner.Email).get(con.AccountId).add(con);
                        } else {
                            accsByEmail.get(con.Account.Owner.Email).put(con.AccountId, new List<Contact>{ con });
                        }
                    } else {
                        accsByEmail.put(
                            con.Account.Owner.Email,
                            new Map<String, List<Contact>>{ con.AccountId => new List<Contact>{ con } }
                        );
                    }
                }
                if (
                    String.isNotBlank(con.Account.Account_Owner_Manager_Email__c) &&
                    (excludedEmails.isEmpty() || !excludedEmails.contains(con.Account.Account_Owner_Manager_Email__c))
                ) {
                    if (accsByEmail.containsKey(con.Account.Account_Owner_Manager_Email__c)) {
                        if (accsByEmail.get(con.Account.Account_Owner_Manager_Email__c).containsKey(con.AccountId)) {
                            accsByEmail.get(con.Account.Account_Owner_Manager_Email__c).get(con.AccountId).add(con);
                        } else {
                            accsByEmail.get(con.Account.Account_Owner_Manager_Email__c)
                                .put(con.AccountId, new List<Contact>{ con });
                        }
                    } else {
                        accsByEmail.put(
                            con.Account.Account_Owner_Manager_Email__c,
                            new Map<String, List<Contact>>{ con.AccountId => new List<Contact>{ con } }
                        );
                    }
                }
            }

            for (String emailAddress : accsByEmail.keySet()) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new List<String>{ emailAddress });
                mail.setSenderDisplayName('Salesforce application');
                mail.setSubject('Hand Raise on cancelled accounts');
                String htmlBody = '<p>The cancelled accounts listed below showed some activity in the last 24 hs. <b>Please assign contacts to an active account or change account status.</b></p><br/>';
                for (String accId : accsByEmail.get(emailAddress).keySet()) {
                    String accName = accsByEmail.get(emailAddress).get(accId).get(0).Account.Name;
                    String urlToAcc = URL.getOrgDomainUrl().toExternalForm() + '/' + accId;
                    htmlBody +=
                        '<h3>Cancelled Account: <a href="' +
                        urlToAcc +
                        '">' +
                        accName +
                        '</a></h3><p>Contacts with activity in the last 24 hs for ' +
                        accName +
                        ':</p>';
                    Integer count = 0;
                    for (Contact con : accsByEmail.get(emailAddress).get(accId)) {
                        if (count < 5) {
                            String urlToCon = URL.getOrgDomainUrl().toExternalForm() + '/' + con.Id;
                            htmlBody += '<a href="' + urlToCon + '">' + con.Name + '</a><br/>';
                        } else if (!Test.isRunningTest()) {
                            htmlBody +=
                                '<a href="' +
                                URL.getOrgDomainUrl().toExternalForm() +
                                '/lightning/r/Report/' +
                                accReport.Id +
                                '/view?fv0=' +
                                accId +
                                '">see more</a> contacts from ' +
                                accName +
                                '<br/>';
                            break;
                        }
                        count += 1;
                    }
                    htmlBody += '<br/><br/>';
                }
                mail.setHtmlBody(htmlBody);
                emails.add(mail);
            }
            if (!emails.isEmpty()) {
                Messaging.sendEmail(emails);
            }
            if (!eanhRecords.isEmpty()) {
                delete eanhRecords;
            }
        }
    }

    public static Boolean isCustomerRecordCheck(Contact con) {
        Contact_Customer_Status_Users__c ContactStatusCS = Contact_Customer_Status_Users__c.getInstance(
            con.CreatedById
        );
        return (ContactStatusCS != null &&
        ContactStatusCS.isPopulatingCustomer__c &&
        con.RCService_ContactStatus__c == 'Active' &&
        isPaidOrTrial(con.Account_Status__c));
    }

    public static Boolean isPaidOrTrial(String accStatus) {
        return String.isNotBlank(accStatus) &&
            (accStatus.equalsIgnoreCase('Paid') || accStatus.containsIgnoreCase('Trial'));
    }

    public static List<Contact> updateContactsWithPaidAccounts() {
        Map<Id, Contact> contactsToUpdate = new Map<Id, Contact>(
            (List<Contact>) new ContactSelector()
                .selectContactsByAccountAndClosedWonStatus(new List<Object>{ paidAccIds })
                .executeQuery()
        );
        Map<Id, Set<Id>> oppConIdMap = new Map<Id, Set<Id>>();
        Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>();
        for (
            OpportunityContactRole oppConRole : (List<OpportunityContactRole>) new OpportunityContactRoleSelector()
                .selectOppConRolesWithClosedWonOppbyContactsId(new List<Object>{ contactsToUpdate.keySet() })
                .executeQuery()
        ) {
            if (oppConIdMap.containsKey(oppConRole.ContactId)) {
                oppConIdMap.get(oppConRole.ContactId).add(oppConRole.OpportunityId);
            } else {
                oppConIdMap.put(oppConRole.ContactId, new Set<Id>{ oppConRole.OpportunityId });
            }
            opportunityMap.put(oppConRole.OpportunityId, oppConRole.Opportunity);
        }
        for (
            Opportunity opp : (List<Opportunity>) new OpportunitySelector()
                .selectClosedWonOppsByPrimaryConAndOppConRoles(
                    new List<Object>{ contactsToUpdate.keySet(), opportunityMap.keySet() }
                )
                .executeQuery()
        ) {
            if (oppConIdMap.containsKey(opp.Primary_Opportunity_Contact__c)) {
                oppConIdMap.get(opp.Primary_Opportunity_Contact__c).add(opp.Id);
            } else {
                oppConIdMap.put(opp.Primary_Opportunity_Contact__c, new Set<Id>{ opp.Id });
            }
            opportunityMap.put(opp.Id, opp);
        }
        for (Contact con : contactsToUpdate.values()) {
            con.Contact_Status__c = ContactTriggerHandler.CONTACT_STATUS_CUSTOMER;
            con.Customer_Record__c = true;
            if (oppConIdMap.containsKey(con.Id)) {
                for (Id oppId : oppConIdMap.get(con.Id)) {
                    String quotedProd = con.Quoted_Products__c != null ? con.Quoted_Products__c : '';
                    con.Quoted_Products__c = getQuotedProducts(opportunityMap.get(oppId), quotedProd);
                }
            }
        }
        return contactsToUpdate.values();
    }
}