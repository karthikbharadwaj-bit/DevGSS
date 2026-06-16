global class BatchJob_UpdatePackageFromMPLAccount implements Database.Batchable<SObject> {
    @TestVisible
    String query = '';

    @TestVisible
    private Map<String, SObjectField> fieldMappingsOffice = new Map<String, SObjectField>{
        'Number_of_POC_Users__c' => Account.Number_of_POC_Users__c,
        'Total_DLs__c' => Account.Total_DLs__c,
        'Acquisition_No_of_DL__c' => Account.Acquisition_No_of_DL__c,
        'Acquisition_Service__c' => Account.Acquisition_Service__c,
        'Acquisition_Tier__c' => Account.Acquisition_Tier__c,
        'Monthly_CRF__c' => Account.Monthly_CRF__c,
        'Sales_Booking_MRS__c' => Account.Sales_Booking_MRS__c,
        'Account_POD__c' => Account.Account_POD__c,
        'Additional_Phone_s__c' => Account.Additional_Phone_s__c,
        'Purchased_DL_s__c' => Account.Purchased_DL_s__c,
        'Number_of_DL_s__c' => Account.Number_of_DL_s__c,
        'Number_of_Extensions__c' => Account.Number_of_Extensions__c,
        'Number_of_IP_Devices__c' => Account.Number_of_IP_Devices__c,
        'Number_of_Leased_Devices__c' => Account.Number_of_Leased_Devices__c,
        'EnabledLBO__c' => Account.EnabledLBO__c,
        'VideoProvider__c' => Account.VideoProvider__c
    };

    @TestVisible
    private Map<String, SObjectField> fieldMappingsCC = new Map<String, SObjectField>{
        'Service_Status__c' => Account.Service_Status__c,
        'MinuteBundle__c' => Account.Minute_Bundle__c,
        'Provision_Date__c' => Account.Provision_Date__c,
        'Contact_Center_Numbers_Location__c' => Account.Contact_Center_Numbers_Location__c,
        'inContact_account_ID__c' => Account.inContact_account_ID__c,
        'inContact_Cluster__c' => Account.inContact_Cluster__c,
        'Outbound_Transport__c' => Account.Outbound_Transport__c,
        'InContact_Service__c' => Account.InContact_Service__c,
        'Price_per_Seat__c' => Account.Price_per_Seat__c,
        'No_of_InContact_Seats__c' => Account.No_of_InContact_Seats__c
    };

    @TestVisible
    private Map<String, SObjectField> fieldMappingsED = new Map<String, SObjectField>{
        'ED_Account_ID__c' => Account.ED_Account_ID__c,
        'Engage_Domain__c' => Account.Engage_Domain__c,
        'ED_Platform__c' => Account.ED_Platform__c,
        'RC_Engage_Account_ID__c' => Account.RC_Engage_Account_ID__c
    };

    @TestVisible
    private Map<String, SObjectField> fieldMappingsEV = new Map<String, SObjectField>{
        'EV_Account_ID__c' => Account.EV_Account_ID__c,
        'EV_Shard__c' => Account.EV_Shard__c,
        'Engage_Domain__c' => Account.Engage_Domain__c,
        'EV_Platform__c' => Account.EV_Platform__c,
        'RC_Engage_Account_ID__c' => Account.RC_Engage_Account_ID__c
    };

    @TestVisible
    private Map<String, SObjectField> fieldMappingsCommon = new Map<String, SObjectField>{
        'SignupPlatform__c' => Account.SignupPlatform__c,
        'RC_Upgrade_Date__c' => Account.RC_Upgrade_Date__c,
        'RC_Activation_Date__c' => Account.RC_Activation_Date__c,
        'RC_Churn_Date__c' => Account.RC_Churn_Date__c,
        'RC_Cancel_Date__c' => Account.RC_Cancel_Date__c,
        'RC_Signup_Date__c' => Account.RC_Signup_Date__c,
        'PID__c' => Account.PID__c,
        'RC_Signup_Type__c' => Account.RC_Signup_Type__c,
        'SignupType__c' => Account.SignupType__c,
        'RC_Signup_Funnel__c' => Account.RC_Signup_Funnel__c,
        'RC_Attribution_Channel__c' => Account.RC_Attribution_Channel__c,
        'RC_Attribution_L2__c' => Account.RC_Attribution_L2__c,
        'RC_Attribution_L3__c' => Account.RC_Attribution_L3__c,
        'RC_Attribution_Campaign__c' => Account.RC_Attribution_Campaign__c,
        'BMID__c' => Account.BMID__c,
        'Attribution_partner_id__c' => Account.Attribution_partner_id__c,
        'AID__c' => Account.AID__c,
        'RC_Brand__c' => Account.RC_Brand__c,
        'RC_Tier__c' => Account.RC_Tier__c,
        'RC_Edition__c' => Account.RC_Edition__c,
        'RC_Brand_ID__c' => Account.RC_Brand_ID__c,
        'RC_Tier_ID__c' => Account.RC_Tier_ID__c,
        'Payment_Plan__c' => Account.Payment_Plan__c,
        'Package_Status__c' => Account.Package_Status__c,
        'Deferred_Activation_Date__c' => Account.Deferred_Activation_Date__c,
        //'Renewal_Date__c' => Account.RC_Plan_Renewal_Date__c, //this api name was changed to Renewal_Date__c on GCI and BISUAT, but still RC_Plan_Renewal_Date__c on Production
        //'Next_Billing_Date__c' => Account.Next_Renewal_Date__c, //this api name was changed to Next_Billing_Date__c on GCI and BISUAT, but still Next_Renewal_Date__c on Production
        //'RC_Plan_Renewal_Date__c' => Account.RC_Plan_Renewal_Date__c,
        //'Next_Renewal_Date__c' => Account.Next_Renewal_Date__c,
        'RC_Account_Number__c' => Account.RC_Account_Number__c,
        'RC_Edition_ID__c' => Account.RC_Edition_ID__c,
        'OID__c' => Account.OID__c,
        'RC_Service_ID__c' => Account.RC_Service_ID__c
    };


    public BatchJob_UpdatePackageFromMPLAccount() {
        query = 'SELECT Id, Master_Account__c FROM Account WHERE IsMultiProductTechnicalAccount__c = true '
            + 'AND Master_Account__r.Billing_ID__c != null AND Master_Account__r.RC_Account_Status__c != \'Canceled\' '
            + 'AND Master_Account__r.RC_Account_Status__c != \'Cancelled\'';
    }

    public BatchJob_UpdatePackageFromMPLAccount(Set<Id> accIds) {
        String idList = '(\'' + String.join(new List<Id>(accIds), '\',\'') + '\')';
        query = 'SELECT Id, Master_Account__c FROM Account WHERE Id IN ' + idList;
    }

    public BatchJob_UpdatePackageFromMPLAccount(String condition) {
        query = 'SELECT Id, Master_Account__c FROM Account WHERE ' + condition;
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Account> scope) {
        Set<Id> accIds = new Set<Id>();
        for (Account acc : scope) {
            if (String.isNotBlank(acc.Master_Account__c)) {
                accIds.add(acc.Master_Account__c);
            } else {
                accIds.add(acc.Id);
            }
        }

        List<Package__c> packages = new PackageSelector()
            .selectPackagesForBatchUpdate(new List<Id>(accIds))
            .executeQuery();

        for (Package__c pkg : packages) {
            if (pkg.Service_Type__c == QuoteHelper.NGBS_OFFICE_PRODUCT) {
                updateFields(pkg, fieldMappingsOffice, pkg.Account__r);
            } else if (pkg.Service_Type__c == QuoteHelper.NGBS_RCCC_PRODUCT) {
                updateFields(pkg, fieldMappingsCC, pkg.Account__r);
            } else if (pkg.Service_Type__c == QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT) {
                updateFields(pkg, fieldMappingsEV, pkg.Account__r);
            } else if (pkg.Service_Type__c == QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT) {
                updateFields(pkg, fieldMappingsED, pkg.Account__r);
            }
            updateFields(pkg, fieldMappingsCommon, pkg.Enterprise_Account_ID__r);
        }

        Triggers.switchOff();
        update packages;
        Triggers.switchOn();
    }

    @TestVisible
    private void updateFields(Package__c pkg, Map<String, SObjectField> fieldMappings, SObject source) {
        if (String.isBlank(pkg.Enterprise_Account_ID__c)) {
            return;
        }
        for (String fieldName : fieldMappings.keySet()) {
            pkg.put(fieldName, source.get(fieldMappings.get(fieldName)));
        }
    }

    global void finish(Database.BatchableContext BC) {
    }
}