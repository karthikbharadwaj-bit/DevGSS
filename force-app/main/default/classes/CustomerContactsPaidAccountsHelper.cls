public class CustomerContactsPaidAccountsHelper {
    static Map<Id, Contact> customerContactMap = new Map<Id, Contact>();
    static Map<Id, Id> contactIdOwnerIdMap = new Map<Id, Id>();
    static Map<Id,User> userMap = new Map<Id,User>();
    static List<Id> paidAccounts = new List<Id>();
    static List<Id> cancelAccounts = new List<Id>();
    static List<Demand_Funnel__c> dfrsToUpdate = new List<Demand_Funnel__c>();
    static String preOppCloseReason = '';

    public static void processCustomerContactsPaidAccounts(List<Customer_Contacts_Paid_Accounts__e> events) {
        try {
            if ('Customer Contacts'.Equals(events[0].Process_Type__c)) {
                setPaidAccountIds(events);
                setCustomerContactAndContactOwnersMap();
                preOppCloseReason = 'Paid Account';
            } else if ('Cancel Accounts'.Equals(events[0].Process_Type__c)) {
                setCancelAccountIds(events);
                updateContactsWithCancelAccounts();
                preOppCloseReason = 'Downgraded / Account churned';
            }
            if (!customerContactMap.isEmpty()) {
                updateCustomerContacts();
    
                userMap = DG_DFR_Class_Helper.getUsersById(new Set<Id> (contactIdOwnerIdMap.values()));
    
                updateDemandFunnelRecords();
            }
            if (!cancelAccounts.isEmpty() && !customerContactMap.isEmpty()) {
                ContactUpdatePlatformEventsHelper.accCancelledContsToSend.addAll(customerContactMap.values());
                ContactUpdatePlatformEventsHelper.addContactsForHandRaiseEmail();
            }
        } catch (Exception e) {
            ExceptionHelper.createExceptionAndNotificacionHistory(e, events, 'DFR Exception Log');
        }
    }   

    public static void processBatchJobContacts(List<Contact> contacts, String processType) { 

        if (processType == 'Customer Contacts') {
            preOppCloseReason = 'Paid Account';
            for (Contact con : contacts) {
                if (con.Contact_Status__c != '4. Customer' && 
                    con.Contact_Status__c != '3. Working Opp') {
                    con.Contact_Status__c = '4. Customer';
                    customerContactMap.put(con.Id, con);
                    contactIdOwnerIdMap.put(con.Id, con.OwnerId);
                }
            }

        } else if (processType == 'Cancel Accounts') {
            preOppCloseReason = 'Downgraded / Account churned';
            for (Contact con : contacts) {
                con.Contact_Status__c = ContactTriggerHandler.CONTACT_STATUS_DOWNGRADED;
                con.Downgrade_Reason__c = ContactUpdatePlatformEventsHelper.ACCOUNT_CHURNED;
                customerContactMap.put(con.Id, con);
                contactIdOwnerIdMap.put(con.Id, con.OwnerId);
            }

            if (!customerContactMap.isEmpty()) {
                ContactUpdatePlatformEventsHelper.accCancelledContsToSend.addAll(customerContactMap.values());
                ContactUpdatePlatformEventsHelper.sendAccCancelledNotification();
            }
        }

        if (!customerContactMap.isEmpty()) {
            updateCustomerContacts();

            userMap = DG_DFR_Class_Helper.getUsersById(new Set<Id>(contactIdOwnerIdMap.values()));

            updateDemandFunnelRecords();
        }

    }

    public static void setPaidAccountIds(List<Customer_Contacts_Paid_Accounts__e> events) {
        for (Customer_Contacts_Paid_Accounts__e cAccount : events) {
            paidAccounts.add(cAccount.AccountId__c);
        }
    }

    public static void setCustomerContactAndContactOwnersMap() {
        for (Contact con : (List<Contact>) new ContactSelector().selectContactsByAccountIds(new List<Object> {paidAccounts}).executeQuery()) {
            if (con.Contact_Status__c != '4. Customer' && 
                con.Contact_Status__c != '3. Working Opp') {
                con.Contact_Status__c = '4. Customer';
                customerContactMap.put(con.Id, con);
                contactIdOwnerIdMap.put(con.Id, con.OwnerId);
            }
        }
    }

    public static void updateCustomerContacts(){
        ContactTriggerHandler.bypassTrigger = true;
        update customerContactMap.values();
        ContactTriggerHandler.bypassTrigger = false;
    }

    public static void updateDemandFunnelRecords() {
        for (Demand_Funnel__c dfr : (List<Demand_Funnel__c>) new DemandFunnelSelector().selectActiveDFRByContactId(new List<Object>{customerContactMap.keySet()}).selectFields(new List<String>{}).executeQuery()) {
            Contact con = customerContactMap.get(dfr.Contact__c);
            User owner = userMap.get(contactIdOwnerIdMap.get(dfr.Contact__c));
            dfr.Pre_Opportunity_Close_Reason__c = preOppCloseReason;
            dfr.EOL_DateTime_Entered__c = datetime.Now();
            dfr.EOL_Entered_From__c = dfr.Pre_Opportunity_Status__c;
            dfr.EOL_Downgrade_Reason__c = con.Downgrade_Reason__c;

            if (dfr.Pre_Opportunity_Status__c == 'SAL') {
                dfr.SAL_DateTime_Exited__c = DateTime.now();
                dfr.SAL_Exited_To__c = 'EOL';
            } else if (dfr.Pre_Opportunity_Status__c == 'MQL') {
                dfr.MQL_DateTime_Exited__c = DateTime.now();
                dfr.MQL_Exited_To__c = 'EOL';
            } else if (dfr.Pre_Opportunity_Status__c == 'Prospect') {
                dfr.Prospect_DateTime_Exited__c = DateTime.now();
                dfr.Prospect_Exited_To__c = 'EOL';
            } else if (dfr.Pre_Opportunity_Status__c == 'TAL') {
                dfr.TAL_DateTime_Exited__c = DateTime.now();
                dfr.TAL_Exited_To__c = 'EOL';
            }

            dfr = DG_DFR_Class_Helper.EOLMasterMappingFromContact(dfr, con);
            dfr = DG_DFR_Class_Helper.EOLOwnerMappingFromUser(dfr, owner, owner.Name, owner.Id);
            dfrsToUpdate.add(dfr);
        }
        update dfrsToUpdate;
    }

    public static void setCancelAccountIds(List<Customer_Contacts_Paid_Accounts__e> events) {
        for (Customer_Contacts_Paid_Accounts__e cAccount : events) {
            cancelAccounts.add(cAccount.AccountId__c);
        }
    }

    public static void updateContactsWithCancelAccounts() {
        for (Contact con : (List<Contact>) new ContactSelector()
            .selectContactsByAccountAndNotWorkingOppOrDowngradeStatus(
                new List<Object>{
                    cancelAccounts,
                    new List<String>{
                        ContactTriggerHandler.CONTACT_STATUS_WORKINGOPP,
                        ContactTriggerHandler.CONTACT_STATUS_DOWNGRADED
                    }
                }
            )
            .executeQuery()) {
            con.Contact_Status__c = ContactTriggerHandler.CONTACT_STATUS_DOWNGRADED;
            con.Downgrade_Reason__c = ContactUpdatePlatformEventsHelper.ACCOUNT_CHURNED;
            customerContactMap.put(con.Id, con);
            contactIdOwnerIdMap.put(con.Id, con.OwnerId);
        }
    }
}