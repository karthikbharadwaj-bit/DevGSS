public inherited sharing class PackageSelector extends SObjectSelector {

    public static final Set<String> FIELDS_STANDARD = new Set<String> {
        'Id',
        'Name',
        'Service_Type__c',
        'Reported_MRS__c',
        'Sales_Order_MRS__c',
        'AcquisitionMRR__c',
        'NumberOfMainLicenses__c',
        'ARPU__c',
        'Enterprise_Account_ID__c',
        'AdditionalProductsMRR__c',
        'TransportMRR__c',
        'SeatMRR__c'
    };

    public static final Set<String> FIELDS_OPPORTUNITY = new Set<String> {
        'Opportunity__c',
        'Opportunity__r.Id',
        'Opportunity__r.Type'
    };

    public static final Set<String> FIELDS_ACCOUNT = new Set<String>{
        'Opportunity__c',
        'Opportunity__r.Id',
        'Opportunity__r.Type'
    };

    public static final Set<String> FIELDS_MASTER_ACCOUNT = new Set<String>{
        'Account__c',
        'Account__r.Id',
        'Account__r.Name'
    };

    public static final Set<String> FIELDS_SERVICE_INFO = new Set<String> {
        'Account_Payment_Method__c',
        'Enterprise_Account_ID__c',
        'RC_Account_Status__c',
        'RC_Brand__c',
        'RC_Service_name__c',
        'RC_Tier_ID__c',
        'RC_Tier__c',
        'Service_Type__c',
        'Service_Version__c',
        'Service_Version_Label__c',
        'Package_ID__c',
        'Package_Name__c',
        'Package_Status__c',
        'Marketing_Category__c',
        'OID__c',
        'Account_POD__c',
        'Payment_Plan__c',
        'Offer_Type__c',
        'Quality_Alert__c',
        'Licenses_Purchased__c',
        'Number_of_DL_s__c',
        'Purchased_DL_s__c',
        'Price_per_DL__c',
        'Total_DLs__c',
        'Total_Account_DL_s__c',
        'Number_of_Extensions__c',
        'Number_of_IP_Devices__c',
        'Additional_Phone_s__c',
        'MRR__c',
        'Sales_Booking_MRS__c',
        'Monthly_CRF__c',
        'Initial_Monthly_Amount__c',
        'aMRR__c',
        'Acquisition_Service__c',
        'Acquisition_Marketing_Category__c',
        'Acquisition_Tier__c',
        'Acquisition_No_of_DL__c',
        'VideoProvider__c',
        'Provision_Date__c',
        'inContact_account_ID__c',
        'InContact_Service__c',
        'Price_per_Seat__c',
        'Bill_As_Of_Date__c',
        'MinuteBundle__c'
    };

    public static final Set<String> FIELDS_ACCOUNT_SERVICE_INFO = new Set<String> {
        'Enterprise_Account_ID__c',
        'Enterprise_Account_ID__r.Id',
        'Enterprise_Account_ID__r.Account_Payment_Method__c',
        'Enterprise_Account_ID__r.RC_Account_Status__c',
        'Enterprise_Account_ID__r.RC_Brand__c',
        'Enterprise_Account_ID__r.RC_Service_name__c',
        'Enterprise_Account_ID__r.RC_Tier_ID__c',
        'Enterprise_Account_ID__r.RC_Tier__c',
        'Enterprise_Account_ID__r.Service_Type__c',
        'Enterprise_Account_ID__r.Service_Version__c',
        'Enterprise_Account_ID__r.Service_Version_Label__c',
        // 'Enterprise_Account_ID__r.Package_ID__c',
        'Enterprise_Account_ID__r.Package_Name__c',
        'Enterprise_Account_ID__r.Package_Status__c',
        'Enterprise_Account_ID__r.OID__c',
        'Enterprise_Account_ID__r.Account_POD__c',
        'Enterprise_Account_ID__r.Payment_Plan__c',
        'Enterprise_Account_ID__r.Offer_Type__c',
        'Enterprise_Account_ID__r.Licenses_Purchased__c',
        'Enterprise_Account_ID__r.Number_of_DL_s__c',
        'Enterprise_Account_ID__r.Purchased_DL_s__c',
        'Enterprise_Account_ID__r.Price_per_DL__c',
        'Enterprise_Account_ID__r.Total_DLs__c',
        'Enterprise_Account_ID__r.Total_Account_DL_s__c',
        'Enterprise_Account_ID__r.Number_of_Extensions__c',
        'Enterprise_Account_ID__r.Number_of_IP_Devices__c',
        'Enterprise_Account_ID__r.Additional_Phone_s__c',
        'Enterprise_Account_ID__r.MRR__c',
        'Enterprise_Account_ID__r.Minute_Bundle__c',
        'Enterprise_Account_ID__r.Sales_Booking_MRS__c',
        'Enterprise_Account_ID__r.Monthly_CRF__c',
        'Enterprise_Account_ID__r.aMRR__c',
        'Enterprise_Account_ID__r.Acquisition_Service__c',
        'Enterprise_Account_ID__r.Acquisition_Tier__c',
        'Enterprise_Account_ID__r.Acquisition_No_of_DL__c',
        'Enterprise_Account_ID__r.VideoProvider__c',
        'Enterprise_Account_ID__r.Provision_Date__c',
        'Enterprise_Account_ID__r.inContact_account_ID__c',
        'Enterprise_Account_ID__r.InContact_Service__c',
        'Enterprise_Account_ID__r.Bill_As_Of_Date__c'
    };

    public static final Set<String> FIELDS_ACCOUNT_AGGREGATED_TOTALS = new Set<String> {
        'Enterprise_Account_ID__c',
        'Enterprise_Account_ID__r.Id',
        'Enterprise_Account_ID__r.Service_Type__c',
        'Enterprise_Account_ID__r.CombinedMVPCurrentTotalMRR__c',
        'Enterprise_Account_ID__r.CombinedMVPAcquisitionMRR__c',
        'Enterprise_Account_ID__r.CombinedCCAcquisitionMRR__c',
        'Enterprise_Account_ID__r.CombinedEngageDigitalMRR__c',
        'Enterprise_Account_ID__r.CombinedEDAcquisitionMRR__c',
        'Enterprise_Account_ID__r.CombinedEngageVoiceMRR__c',
        'Enterprise_Account_ID__r.CombinedEVAcquisitionMRR__c',
        'Enterprise_Account_ID__r.CombinedNumberOfEngageDigitalUsers__c',
        'Enterprise_Account_ID__r.CombinedNumberOfEngageVoiceSeats__c',
        'Enterprise_Account_ID__r.inContactARPU__c',
        'Enterprise_Account_ID__r.EngageDigitalARPU__c',
        'Enterprise_Account_ID__r.EngageVoiceARPU__c',
        'Enterprise_Account_ID__r.CombinedEventsMRR__c',
        'Enterprise_Account_ID__r.CombinedEventsAcquisitionMRR__c',
        'Enterprise_Account_ID__r.CombinedNumberofEventsUsers__c',
        'Enterprise_Account_ID__r.EventsARPU__c'
    };

    public static final Set<String> FIELDS_ACCOUNT_UPDATE = new Set<String> {
        'Offer_Type__c',
        'Account__c',
        'Enterprise_Account_ID__c',
        'NumberOfEngageDigitalUsers__c',
        'NumberOfEngageVoiceSeats__c',
        'EDAcquisitionMRR__c',
        'EDAdditionalProductsMRR__c',
        'EnabledLBO__c',
        'EngageDigitalMRR__c',
        'EngageDigitalUserMRR__c',
        'EVAdditionalProductsMRR__c',
        'EngageVoiceMRR__c',
        'EngageVoiceUserMRR__c',
        'EVAcquisitionMRR__c',
        'CCAcquisitionMRR__c',
        'AdditionalProductsMRR__c',
        'No_of_InContact_Seats__c',
        'SeatMRR__c',
        'MRR__c',
        'Total_DLs__c',
        'Total_MRR__c',
        'Acquisition_No_of_DL__c',
        'Additional_Phone_s__c',
        'Purchased_DL_s__c',
        'Number_of_DL_s__c',
        'Number_of_Extensions__c',
        'Number_of_IP_Devices__c',
        'Package_Name__c',
        'Licenses_Purchased__c',
        'MVPAcquisitionMRR__c',
        'MVPCurrentTotalMRR__c',
        'Package_Status__c',
        'Service_Type__c',
        'Number_of_Leased_Devices__c',
        'Events_MRR__c',
        'Events_Acquisition_MRR__c',
        'Number_of_Events_Users__c',
        'Events_User_MRR__c',
        'Events_Additional_Products_MRR__c'
    };

    public static final Set<String> FIELDS_ACCOUNT_UPDATE_DATE = new Set<String> {
        'Account__c',
        'Service_Type__c',
        'CreatedDate',
        'RC_Signup_Date__c',
        'RC_Activation_Date__c',
        'RC_Upgrade_Date__c',
        'RC_Churn_Date__c',
        'RC_Cancel_Date__c'
    };

    public PackageSelector() {
        super();
    }

    public PackageSelector(String relationshipName, SObjectType relationshipBase) {
        super(relationshipName, relationshipBase);
    }

    public PackageSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return Package__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Package__c.Id,
            Package__c.Name,
            Package__c.Account_Package_ID__c,
            Package__c.Account__c,
            Package__c.Package_Catalog_Id__c,
            Package__c.EnabledLBO__c,
            Package__c.Enterprise_Account_ID__c
        };
    }

    public List<String> getPackageInfoFields() {
        return new List<String>{
            'Account__c',
            'Account_Package_ID__c',
            'Package_Version__c',
            'Package_Catalog_Id__c'
        };
    }

    private Set<Schema.SObjectField> getFieldsForSyncAccountWithBilling() {
        return new Set<Schema.SObjectField> {
            Package__c.Id,
            Package__c.Licenses_Purchased__c,
            Package__c.Account_Package_Id__c,
            Package__c.Service_Type__c,
            Package__c.Account__c,
            Package__c.IsUsedForAccountAttribution__c,
            Package__c.Offer_Type__c
        };
    }

    public List<Schema.SObjectField> getFieldsForNewPackageReferences() {
        return new List<Schema.SObjectField> {
            Package__c.Account__c,
            Package__c.Account_POD__c,
            Package__c.Contact_Center_Numbers_Location__c,
            Package__c.inContact_Cluster__c,
            Package__c.InContact_Service__c,
            Package__c.MinuteBundle__c,
            Package__c.Number_of_POC_Users__c,
            Package__c.Offer_Type__c,
            Package__c.Outbound_Transport__c,
            Package__c.Package_Name__c,
            Package__c.Package_Status__c,
            Package__c.Payment_Plan__c,
            Package__c.Price_per_Seat__c,
            Package__c.RC_Account_Number__c,
            Package__c.RC_Signup_Funnel__c,
            Package__c.RC_Signup_Type__c,
            Package__c.RC_Tier_ID__c,
            Package__c.RC_Tier__c,
            Package__c.Sales_Booking_MRS__c,
            Package__c.Service_Type__c,
            Package__c.Service_Version__c,
            Package__c.SignupPlatform__c,
            Package__c.SignupType__c,
            Package__c.TransportMRR__c,
            Package__c.VideoProvider__c,
            Package__c.Service_Version_Label__c,
            Package__c.CreatedDate
        };
    }

    public static final Set<SObjectField> FIELDS_PACKAGE_REMEDIATION_MARKETING_ATTRIBUTION = new Set<SObjectField> {
        Package__c.RC_Signup_Funnel__c,
        Package__c.RC_Attribution_Channel__c,
        Package__c.RC_Attribution_L2__c,
        Package__c.RC_Attribution_L3__c,
        Package__c.RC_Attribution_Campaign__c,
        Package__c.Attribution_partner_id__c,
        Package__c.BMID__c,
        Package__c.PID__c,
        Package__c.AID__c,
        Package__c.OID__c
    };

    public static final Set<SObjectField> FIELDS_PACKAGE_UPDATE_MARKETING_ATTRIBUTION = new Set<SObjectField> {
        Package__c.RC_Signup_Funnel__c,
        Package__c.RC_Attribution_Channel__c,
        Package__c.RC_Attribution_L2__c,
        Package__c.RC_Attribution_L3__c,
        Package__c.RC_Attribution_Campaign__c,
        Package__c.Attribution_partner_id__c,
        Package__c.BMID__c,
        Package__c.PID__c,
        Package__c.AID__c,
        Package__c.OID__c,
        Package__c.CreatedDate,
        Package__c.Service_Type__c,
        Package__c.IsUsedForAccountAttribution__c
    };

    public List<String> getFieldsForBatchUpdate() {
        return new List<String> {
            'Id',
            'Account__c',
            'Service_Type__c',
            'Enterprise_Account_ID__r.SignupPlatform__c',
            'Enterprise_Account_ID__r.RC_Upgrade_Date__c',
            'Enterprise_Account_ID__r.RC_Activation_Date__c',
            'Enterprise_Account_ID__r.RC_Churn_Date__c',
            'Enterprise_Account_ID__r.RC_Cancel_Date__c',
            'Enterprise_Account_ID__r.RC_Signup_Date__c',
            'Enterprise_Account_ID__r.PID__c',
            'Enterprise_Account_ID__r.RC_Signup_Type__c',
            'Enterprise_Account_ID__r.SignupType__c',
            'Enterprise_Account_ID__r.RC_Signup_Funnel__c',
            'Enterprise_Account_ID__r.RC_Attribution_Channel__c',
            'Enterprise_Account_ID__r.RC_Attribution_L2__c',
            'Enterprise_Account_ID__r.RC_Attribution_L3__c',
            'Enterprise_Account_ID__r.RC_Attribution_Campaign__c',
            'Enterprise_Account_ID__r.BMID__c',
            'Enterprise_Account_ID__r.Attribution_partner_id__c',
            'Enterprise_Account_ID__r.AID__c',
            'Enterprise_Account_ID__r.RC_Brand__c',
            'Enterprise_Account_ID__r.RC_Tier__c',
            'Enterprise_Account_ID__r.RC_Edition__c',
            'Enterprise_Account_ID__r.Service_Type__c',
            'Enterprise_Account_ID__r.RC_Brand_ID__c',
            'Enterprise_Account_ID__r.RC_Tier_ID__c',
            'Enterprise_Account_ID__r.Payment_Plan__c',
            'Enterprise_Account_ID__r.Package_Status__c',
            'Enterprise_Account_ID__r.Deferred_Activation_Date__c',
            'Enterprise_Account_ID__r.RC_Plan_Renewal_Date__c',
            'Enterprise_Account_ID__r.Next_Renewal_Date__c',
            'Enterprise_Account_ID__r.RC_Account_Number__c',
            'Enterprise_Account_ID__r.RC_Edition_ID__c',
            'Enterprise_Account_ID__r.OID__c',
            'Enterprise_Account_ID__r.RC_Service_ID__c',
            'Account__r.Number_of_POC_Users__c',
            'Account__r.Total_DLs__c',
            'Account__r.Acquisition_No_of_DL__c',
            'Account__r.Acquisition_Service__c',
            'Account__r.Acquisition_Tier__c',
            'Account__r.Monthly_CRF__c',
            'Account__r.Sales_Booking_MRS__c',
            'Account__r.Account_POD__c',
            'Account__r.Additional_Phone_s__c',
            'Account__r.Purchased_DL_s__c',
            'Account__r.Number_of_DL_s__c',
            'Account__r.Number_of_Extensions__c',
            'Account__r.Number_of_IP_Devices__c',
            'Account__r.Number_of_Leased_Devices__c',
            'Account__r.EnabledLBO__c',
            'Account__r.VideoProvider__c',
            'Account__r.Service_Status__c',
            'Account__r.Minute_Bundle__c',
            'Account__r.Provision_Date__c',
            'Account__r.Contact_Center_Numbers_Location__c',
            'Account__r.inContact_account_ID__c',
            'Account__r.inContact_Cluster__c',
            'Account__r.Outbound_Transport__c',
            'Account__r.InContact_Service__c',
            'Account__r.Price_per_Seat__c',
            'Account__r.No_of_InContact_Seats__c',
            'Account__r.ED_Account_ID__c',
            'Account__r.Engage_Domain__c',
            'Account__r.ED_Platform__c',
            'Account__r.RC_Engage_Account_ID__c',
            'Account__r.EV_Account_ID__c',
            'Account__r.EV_Shard__c',
            'Account__r.Engage_Domain__c',
            'Account__r.EV_Platform__c'
        };
    }

    public QueryFactory selectPackageForApproval() {
        return newQueryFactory()
                .setFactoryName('selectPackageForApproval')
                .withSelectorFieldsIncluded()
                .withoutSelectorOrderByIncluded()
                .selectFields(getDefaultFieldList())
                .selectField(Package__c.RC_Cancel_Date__c)
                .selectFields(getFieldsForNewPackageReferences());
    }

    public QueryFactory selectPackageByAccountBillingId(String billingId) {
        return newQueryFactory()
            .setFactoryName('selectPackageByAccountId')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .selectFields(getPackageInfoFields())
            .setCondition('Account__r.Billing_ID__c = :bind0')
            .setQueryBindings(new List<Object>{billingId});
    }

    public QueryFactory selectPackagesByEnterpriseAccountIds(List<Id> accountIds) {
        return newQueryFactory()
            .setFactoryName('selectPackagesByEnterpriseAccountIds')
            .selectFields(FIELDS_STANDARD)
            .setCondition('Enterprise_Account_ID__c IN :bind0')
            .setQueryBindings(new List<Object> {
                accountIds
            });
    }
    public QueryFactory selectPackagesByEnterpriseAccountIdsWithAccountTotals(List<Id> accountIds) {
        return selectPackagesByEnterpriseAccountIds(accountIds)
            .setFactoryName('selectPackagesByEnterpriseAccountIdsWithAccountTotals')
            .selectFields(FIELDS_ACCOUNT_AGGREGATED_TOTALS);
    }

    public QueryFactory selectPackagesByEnterpriseAccountIdsWithServiceFields(List<Id> accountIds) {
        return selectPackagesByEnterpriseAccountIds(accountIds)
            .setFactoryName('selectPackageByAccountIdsWithServiceFields')
            .selectFields(FIELDS_SERVICE_INFO)
            .selectFields(FIELDS_ACCOUNT_SERVICE_INFO);
    }

    public QueryFactory selectPackagesById(Set<Id> bapIds) {
        return selectPackagesById(new List<Id>(bapIds));
    }

    public QueryFactory selectPackagesById(List<Id> bapIds) {
        return newQueryFactory()
            .setFactoryName('selectPackageByIds')
            .selectFields(FIELDS_STANDARD)
            .selectFields(FIELDS_SERVICE_INFO)
            .selectFields(FIELDS_ACCOUNT_SERVICE_INFO)
            .setCondition('Id IN :bind0')
            .setQueryBindings(new List<Object> { bapIds });
    }

    public QueryFactory selectAllPackages() {
        return newQueryFactory()
            .setFactoryName('selectAllPackages')
            .withoutSelectorFieldsIncluded()
            .selectFields(FIELDS_STANDARD);
    }

    public QueryFactory selectPackagesByIdForSyncAccountWsTest(List<Id> Ids) {
        return newQueryFactory()
            .setFactoryName('selectPackagesByIdForSyncAccountWsTest')
            .selectFields(new List<String>{'Account__c', 'Enterprise_Account_ID__c'})
            .setCondition('Id IN :bind0')
            .setQueryBindings(new List<Object> { Ids });
    }

    public QueryFactory selectPackagesForCasesById(List<Id> bapIds) {
        return newQueryFactory()
            .setFactoryName('selectPackagesForCasesById')
            .selectFields(new List<String> {'Account__r.Id', 'Account__r.Master_Account__c'})
            .setCondition('Id IN :bind0')
            .setQueryBindings(new List<Object> { bapIds });
    }

    public QueryFactory selectPackagesByAccountId(Id accountId) {
        return newQueryFactory()
            .setFactoryName('selectPackagesByAccountId')
            .selectFields(getFieldsForSyncAccountWithBilling())
            .setCondition('Account__c = :bind0')
            .setQueryBindings(new List<Object> { accountId });
    }

    public QueryFactory selectPackagesByAccountIds(List<Id> accountIds) {
        return newQueryFactory()
            .setFactoryName('selectPackagesByAccountIds')
            .selectFields(getFieldsForSyncAccountWithBilling())
            .setCondition('Account__c IN :bind0')
            .setQueryBindings(new List<Object> { accountIds });
    }

    public QueryFactory selectPackagesByAccountIdForPOC(Id accountId) {
        List<String> fieldsList = new List<String>();
        fieldsList.addAll(FIELDS_STANDARD);
        fieldsList.add('Account__r.RC_Account_Status__c');
        return newQueryFactory()
            .setFactoryName('selectPackagesByAccountIdForPOC')
            .selectFields(fieldsList)
            .setCondition('Account__c = :bind0 AND Package_Status__c = \'' + PackageHelper.PACKAGE_STATUS_ACTIVE + '\' AND Account__r.RC_Account_Status__c = \'' + AccountHelper.PAID_STATUS + '\'')
            .setQueryBindings(new List<Object> { accountId });
    }

    public QueryFactory selectPackagesForAccountUpdateByAccountIds(List<Id> accIds) {
        return newQueryFactory()
            .setFactoryName('selectPackagesForAccountUpdateByAccountIds')
            .selectFields(FIELDS_ACCOUNT_UPDATE)
            .setCondition('Account__c IN :bind0')
            .setQueryBindings(new List<Object> { accIds });
    }

    public QueryFactory selectPackagesByActivatedOrderIds(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectPackagesByActivatedOrderIds')
            .selectFields(new List<String>{
                'Id',
                'Sales_Order_MRS__c',
                'AcquisitionMRR__c',
                'Service_Type__c'
            })
            .subselect(
                new OrderSelector('Orders', Package__c.SObjectType)
                    .newQueryFactory()
                    .selectFields(
                        new List<String>{
                            'Id',
                            'AccountId',
                            'Quote.Upsell_Status__c',
                            'Quote.Payment_Plan__c',
                            'Recurring_total__c',
                            'PackageId__c',
                            'SeatMRR__c',
                            'TransportMRR__c',
                            'MinuteBundle__c',
                            'NumberOfMainLicenses__c'
                        })
                    .setCondition('QuoteId IN :bind1 AND Status = \'' + OrderHelper.STATUS_ACTIVATED + '\'')
            )
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectPackagesByOpportunityIdAndServiceName(Set<Id> opportunityIds, String serviceName) {
        return newQueryFactory()
            .setFactoryName('selectPackagesByAccountId')
            .selectFields(new List<String>{
                'Id',
                'Account_Package_Id__c',
                'Service_Type__c',
                'Opportunity__c'
            })
            .setCondition('Opportunity__c IN :bind0 AND Service_Type__c =: bind1')
            .setQueryBindings(new List<Object> { opportunityIds, serviceName });
    }

    public QueryFactory selectPackagesForDateFieldsUpdateByAccountIds(List<Object> accIds) {
        return newQueryFactory()
            .setFactoryName('selectPackagesForDateFieldsUpdateByAccountIds')
            .selectFields(FIELDS_ACCOUNT_UPDATE_DATE)
            .setCondition('Account__c IN :bind0')
            .setQueryBindings(accIds);
    }

    public QueryFactory selectPackagesForNewReferences(List<Object> accIds) {
        return newQueryFactory()
            .setFactoryName('selectPackagesForNewReferences')
            .selectFields(getFieldsForNewPackageReferences())
            .setCondition('Account__c IN :bind0')
            .setQueryBindings(accIds);
    }

    public QueryFactory selectPackagesForBatchUpdate(List<Id> accIds) {
        return newQueryFactory()
            .setFactoryName('selectPackagesForBatchUpdate')
            .selectFields(getFieldsForBatchUpdate())
            .setCondition('Account__c IN :bind0')
            .setQueryBindings(new List<Object>{accIds});
    }

    public QueryFactory selectPkgsForMarketingAttributionUpdate() {
        return newQueryFactory()
            .setFactoryName('selectPkgsForMarketingAttributionUpdate')
            .selectFields(FIELDS_PACKAGE_UPDATE_MARKETING_ATTRIBUTION)
            .setCondition('IsUsedForAccountAttribution__c = true');
    }
}