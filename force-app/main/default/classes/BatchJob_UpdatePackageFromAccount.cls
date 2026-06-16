global class BatchJob_UpdatePackageFromAccount implements Database.Batchable<SObject> {
    @TestVisible
    String query = '';

    @TestVisible
    private Map<String, SObjectField> fieldMappings = new Map<String, SObjectField>{
        'SignupPlatform__c' => Account.SignupPlatform__c,
        'Number_of_POC_Users__c' => Account.Number_of_POC_Users__c,
        'Service_Status__c' => Account.Service_Status__c,
        'MinuteBundle__c' => Account.Minute_Bundle__c,
        'TransportMRR__c' => Account.Transport_MRR__c,
        'Provision_Date__c' => Account.Provision_Date__c,
        'Contact_Center_Numbers_Location__c' => Account.Contact_Center_Numbers_Location__c,
        'inContact_account_ID__c' => Account.inContact_account_ID__c,
        'inContact_Cluster__c' => Account.inContact_Cluster__c,
        'Outbound_Transport__c' => Account.Outbound_Transport__c,
        'InContact_Service__c' => Account.InContact_Service__c,
        'Price_per_Seat__c' => Account.Price_per_Seat__c,
        'EV_Account_ID__c' => Account.EV_Account_ID__c,
        'ED_Account_ID__c' => Account.ED_Account_ID__c,
        'EV_Shard__c' => Account.EV_Shard__c,
        'Engage_Domain__c' => Account.Engage_Domain__c,
        'EV_Platform__c' => Account.EV_Platform__c,
        'ED_Platform__c' => Account.ED_Platform__c,
        'RC_Engage_Account_ID__c' => Account.RC_Engage_Account_ID__c,
        'Actual_transport_MRR__c' => Account.Actual_transport_MRR__c,
        'RC_Upgrade_Date__c' => Account.RC_Upgrade_Date__c,
        'RC_Activation_Date__c' => Account.RC_Activation_Date__c,
        'RC_Churn_Date__c' => Account.RC_Churn_Date__c,
        'RC_Cancel_Date__c' => Account.RC_Cancel_Date__c,
        'RC_Signup_Date__c' => Account.RC_Signup_Date__c,
        'PID__c' => Account.PID__c,
        'RC_Signup_Type__c' => Account.RC_Signup_Type__c,
        'RC_Signup_Funnel__c' => Account.RC_Signup_Funnel__c,
        'RC_Attribution_Channel__c' => Account.RC_Attribution_Channel__c,
        'RC_Attribution_L2__c' => Account.RC_Attribution_L2__c,
        'RC_Attribution_L3__c' => Account.RC_Attribution_L3__c,
        'RC_Attribution_Campaign__c' => Account.RC_Attribution_Campaign__c,
        'BMID__c' => Account.BMID__c,
        'Attribution_partner_id__c' => Account.Attribution_partner_id__c,
        'AID__c' => Account.AID__c,
        'Acquisition_No_of_DL__c' => Account.Acquisition_No_of_DL__c,
        'Acquisition_Service__c' => Account.Acquisition_Service__c,
        'Acquisition_Tier__c' => Account.Acquisition_Tier__c,
        'Monthly_CRF__c' => Account.Monthly_CRF__c,
        'Sales_Booking_MRS__c' => Account.Sales_Booking_MRS__c,
        'RC_Brand__c' => Account.RC_Brand__c,
        'RC_Tier__c' => Account.RC_Tier__c,
        'RC_Edition__c' => Account.RC_Edition__c,
        'Service_Type__c' => Account.Service_Type__c,
        'Account_POD__c' => Account.Account_POD__c,
        'RC_Brand_ID__c' => Account.RC_Brand_ID__c,
        'RC_Tier_ID__c' => Account.RC_Tier_ID__c,
        'Payment_Plan__c' => Account.Payment_Plan__c,
        'Package_Status__c' => Account.Package_Status__c,
        'Deferred_Activation_Date__c' => Account.Deferred_Activation_Date__c,
        'RC_Account_Number__c' => Account.RC_Account_Number__c,
        'Additional_Phone_s__c' => Account.Additional_Phone_s__c,
        'Purchased_DL_s__c' => Account.Purchased_DL_s__c,
        'Number_of_DL_s__c' => Account.Number_of_DL_s__c,
        'Number_of_Extensions__c' => Account.Number_of_Extensions__c,
        'Number_of_IP_Devices__c' => Account.Number_of_IP_Devices__c,
        'Number_of_Leased_Devices__c' => Account.Number_of_Leased_Devices__c,
        'EnabledLBO__c' => Account.EnabledLBO__c,
        'RC_Edition_ID__c' => Account.RC_Edition_ID__c,
        'OID__c' => Account.OID__c,
        'RC_Service_ID__c' => Account.RC_Service_ID__c,
        'SignupType__c' => Account.SignupType__c,
        'Next_Renewal_Date__c' => Account.Next_Renewal_Date__c,
        'RC_Plan_Renewal_Date__c' => Account.RC_Plan_Renewal_Date__c,
        'VideoProvider__c' => Account.VideoProvider__c,
        'No_of_InContact_Seats__c' => Account.No_of_InContact_Seats__c,
        'SeatMRR__c' => Account.Seat_MRR__c
    };

    public BatchJob_UpdatePackageFromAccount() {
        query = 'SELECT Id FROM Account WHERE RC_Account_Status__c != \'Canceled\' AND RC_Account_Status__c != \'Cancelled\' AND Billing_ID__c != null';
    }

    public BatchJob_UpdatePackageFromAccount(Set<Id> accIds) {
        String idList = '(\'' + String.join(new List<Id>(accIds), '\',\'') + '\')';
        query = 'SELECT Id FROM Account WHERE Id IN ' + idList;
    }

    public BatchJob_UpdatePackageFromAccount(String condition) {
        query = 'SELECT Id FROM Account WHERE ' + condition;
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Account> scope) {
        List<Id> accIds = new List<Id>();
        for (Account acc : scope) {
            accIds.add(acc.Id);
        }
        List<Account> accounts = new AccountSelector()
            .selectAccountsWithSinglePackage(accIds, null)
            .executeQuery();

        List<Package__c> packagesToUpdate = new List<Package__c>();

        for (Account acc : accounts) {
            if (acc.Service_Accounts__r.size() != 1) {
                continue;
            }
            Package__c pkg = acc.Service_Accounts__r[0];
            for (String fieldName : fieldMappings.keySet()) {
                if (acc.get(fieldMappings.get(fieldName)) == null) {
                    continue;
                }
                pkg.put(fieldName, acc.get(fieldMappings.get(fieldName)));
            }
            packagesToUpdate.add(pkg);
        }

        if (!packagesToUpdate.isEmpty()) {
            Triggers.switchOff();
            update packagesToUpdate;
            Triggers.switchOn();
        }
    }

    global void finish(Database.BatchableContext BC) {
    }
}