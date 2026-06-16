public inherited sharing class AccountSelector extends SObjectSelector {

    public static final Set<String> FIELDS_SERVICE_INFO = new Set<String> {
        'Id',
        'Account_Payment_Method__c',
        'Account_POD__c',
        'Acquisition_No_of_DL__c',
        'Acquisition_Service__c',
        'Acquisition_Tier__c',
        'Additional_Phone_s__c',
        'aMRR__c',
        'Licenses_Purchased__c',
        'Monthly_CRF__c',
        'MRR__c',
        'Number_of_DL_s__c',
        'Number_of_Extensions__c',
        'Number_of_IP_Devices__c',
        'Offer_Type__c',
        'OID__c',
        'Package_Name__c',
        'Package_Status__c',
        'Payment_Plan__c',
        'Price_per_DL__c',
        'Purchased_DL_s__c',
        'RC_Account_Status__c',
        'RC_Brand__c',
        'RC_Service_name__c',
        'RC_Tier__c',
        'RC_Tier_ID__c',
        'Sales_Booking_MRS__c',
        'Service_Type__c',
        'Service_Version__c',
        'Service_Version_Label__c',
        'Total_Account_DL_s__c',
        'Total_DLs__c',
        'VideoProvider__c',
        'Provision_Date__c',
        'inContact_account_ID__c',
        'InContact_Service__c',
        'Bill_As_Of_Date__c',
        'Id',
        'IsMultiProductTechnicalAccount__c',
        'Master_Account__c'
    };

    public static final Set<String> FIELDS_AGGREGATED_TOTALS = new Set<String>{
        'Id',
        'RC_Service_name__c',
        'CombinedMVPCurrentTotalMRR__c',
        'CombinedMVPAcquisitionMRR__c',
        'CombinedCCAcquisitionMRR__c',
        'inContactARPU__c',
        'CombinedEngageDigitalMRR__c',
        'CombinedEDAcquisitionMRR__c',
        'CombinedNumberOfEngageDigitalUsers__c',
        'EngageDigitalARPU__c',
        'CombinedEngageVoiceMRR__c',
        'CombinedEVAcquisitionMRR__c',
        'CombinedNumberOfEngageVoiceSeats__c',
        'EngageVoiceARPU__c',
        'CombinedEventsMRR__c',
        'CombinedEventsAcquisitionMRR__c',
        'CombinedNumberofEventsUsers__c',
        'EventsARPU__c',
        'Master_Account__c',
        'Master_Account__r.Id',
        'Master_Account__r.RC_Service_name__c',
        'Master_Account__r.CombinedMVPCurrentTotalMRR__c',
        'Master_Account__r.CombinedMVPAcquisitionMRR__c',
        'Master_Account__r.CombinedCCAcquisitionMRR__c',
        'Master_Account__r.inContactARPU__c',
        'Master_Account__r.CombinedEngageDigitalMRR__c',
        'Master_Account__r.CombinedEDAcquisitionMRR__c',
        'Master_Account__r.CombinedNumberOfEngageDigitalUsers__c',
        'Master_Account__r.EngageDigitalARPU__c',
        'Master_Account__r.CombinedEngageVoiceMRR__c',
        'Master_Account__r.CombinedEVAcquisitionMRR__c',
        'Master_Account__r.CombinedNumberOfEngageVoiceSeats__c',
        'Master_Account__r.EngageVoiceARPU__c',
        'Master_Account__r.CombinedEventsMRR__c',
        'Master_Account__r.CombinedEventsAcquisitionMRR__c',
        'Master_Account__r.CombinedNumberofEventsUsers__c',
        'Master_Account__r.EventsARPU__c'
    };

    public static final Set<String> FIELDS_REPORTED_MRS_DEPENDANTS = new Set<String> {
        'Id',
        'RC_Service_name__c',
        'CombinedEngageDigitalMRR__c',
        'CombinedEngageVoiceMRR__c'
    };

    public static final Set<String> FIELDS_FOR_COPYING = new Set<String> {
        'Id',
        'RC_User_ID__c',
        'EnabledLBO__c',
        'EnterpriseCustomerID__c',
        'BillingPostalCode',
        'BillingCountry',
        'BillingState',
        'BillingCity',
        'BillingStreet',
        'Master_Account__c',
        'VATNumber__c',
        'Tax_Exempt__c',
        'Master_Account__r.Id',
        'Master_Account__r.RC_User_ID__c',
        'Master_Account__r.EnabledLBO__c',
        'Master_Account__r.EnterpriseCustomerID__c',
        'Master_Account__r.BillingPostalCode',
        'Master_Account__r.BillingCountry',
        'Master_Account__r.BillingState',
        'Master_Account__r.BillingCity',
        'Master_Account__r.BillingStreet',
        'Master_Account__r.VATNumber__c',
        'Master_Account__r.Tax_Exempt__c'
    };

    public AccountSelector() {
        super();
    }

    public AccountSelector(String relationshipName, SObjectType relationshipBase) {
        super(relationshipName, relationshipBase);
    }

    public AccountSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return Account.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Account.Description,
            Account.Id,
            Account.AccountNumber,
            Account.Name,
            Account.Type,
            Account.AnnualRevenue,
            Account.Account__c,
            Account.Target_Account__c,
            Account.Most_Recent_Implementation_Contact__c,
            Account.CurrencyIsoCode,
            Account.Master_Account__c,
            Account.NGBS_Partner_ID__c,
            Account.Partner_Account__c,
            Account.Partner_ID__c,
            Account.Partner_Type__c,
            Account.Partner_Account_Name__c,
            Account.Partner_Contact__c,
            Account.Parent_Partner_Account__c,
            Account.Payment_Plan__c,
            Account.Ultimate_Partner_Name__c,
            Account.Ultimate_Partner_ID__c,
            Account.Settlement_Type__c,
            Account.PartnerStatus__c,
            Account.BusinessIdentity__c,
            Account.Account_Payment_Method__c,
            Account.RC_User_ID__c,
            Account.RC_Account_Status__c,
            Account.RC_Service_name__c,
            Account.RecordTypeId,
            Account.Billing_ID__c,
            Account.ELA_Account_Type__c,
            Account.isFedRamp__c,
            Account.Package_Status__c,
            Account.Service_Type__c,
            Account.BillingCountry,
            Account.BillingStreet,
            Account.BillingState,
            Account.BillingCity,
            Account.BillingLatitude,
            Account.BillingLongitude,
            Account.BillingPostalCode,
            Account.Credit_Limit__c,
            Account.Package_Status__c,
            Account.RC_Brand__c,
            Account.VATNumber__c,
            Account.IsMultiProductTechnicalAccount__c,
            Account.AccMigrationFlag__c,
            Account.IsRingCx__c,
            Account.EV_Account_ID__c,
            Account.EV_Platform__c,
            Account.EV_Shard__c,
            Account.RC_Engage_Account_ID__c,
            Account.ED_Account_ID__c,
            Account.ED_Platform__c,
            Account.Engage_Domain__c,
            Account.inContact_account_ID__c
        };
    }
    public List<Schema.SObjectField> getOtherFieldList() {
        return new List<Schema.SObjectField> {
            Account.Website,
            Account.Name
        };
    }

    public List<Schema.SObjectField> getApprovalFieldList() {
        return new List<Schema.SObjectField> {
            Account.Website,
            Account.MRR_Transfer_Effective_date__c,
            Account.Current_Owner__c,
            Account.Partner_ID__c,
            Account.Inside_Sales_Rep__c,
            Account.Ultimate_Partner_ID__c,
            Account.Ultimate_Partner_Name__c,
            Account.RC_Account_Status__c,
            Account.OwnerId,
            Account.Payment_Plan__c,
            Account.Account_Payment_Method__c
        };
    }
    public List<String> getInvoiceApprovalFieldList() {
        return new List<String> {
            'Monthly_Credit_Limit__c',
            'Sign_up_Purchase_Limit__c',
            'AH_Name__r.D_U_N_S_Number__c',
            'AH_Name__r.AH_Phone__c',
            'AH_Name__r.AH_Website__c',
            'Billing_ID__c',
            'Phone',
            'BillingCountry',
            'BillingPostalCode',
            'BillingState',
            'BillingStreet',
            'BillingCity',
            'Active_Invoice_Approval__c',
            'Payment_Method__c',
            'Payment_Terms__c',
            'Invoice_Terms__c',
            'Payment_Plan__c',
            'Account_Payment_Method__c',
            'RC_Account_Status__c',
            'OwnerId',
            'Payment_Plan__c',
            'Inside_Sales_Rep__c',
            'Most_Recent_Opportunity_Owner_Email__c',
            'VATNumber__c'
        };
    }

    public List<String> getApprovalCreationFieldList() {
        return new List<String> {
            'Account_Payment_Method__c',
            'BillingCountry',
            'BillingPostalCode',
            'BillingState',
            'BillingStreet',
            'BillingCity',
            'Id',
            'MRR__c',
            'Name',
            'Payment_Method__c',
            'Payment_Plan__c',
            'RC_Account_Status__c',
            'SegmentName__c'
        };
    }

    public List<String> getPartnerApprovalFieldList() {
        return new List<String> {
            'Id',
            'Partner_Type__c',
            'PartnerStatus__c',
            'Partner_Hierarchy_Level__c',
            'Partner_ID__c',
            'Reseller_Requests__r.Partner_First_Name__c',
            'Reseller_Requests__r.Partner_Last_Name__c',
            'Reseller_Requests__r.Partner_Email_Address__c',
            'Reseller_Requests__r.Partner_Phone__c',
            'Reseller_Requests__r.Partner_Company_Name__c',
            'Reseller_Requests__r.Partner_Address1__c',
            'Reseller_Requests__r.Partner_Address2__c',
            'Reseller_Requests__r.Partner_City__c',
            'Reseller_Requests__r.Partner_State__c',
            'Reseller_Requests__r.Partner_Zip__c',
            'Reseller_Requests__r.Partner_Country__c',
            'Reseller_Requests__r.Partner_Role__c',
            'Reseller_Requests__r.Partner_Type__c',
            'Reseller_Requests__r.Settlement_Type__c',
            'Reseller_Requests__r.Settlement_Partner_ID__c',
            'Reseller_Requests__r.Settlement_Rate_Partner_ID__c',
            'Permitted_Brands__c',
            'VAR_Territory__c',
            'Partner_Hierarchy_Level__c',
            'Parent_Account_ID__c',
            'Invoicing_Partner_ID__c',
            'Invoice_Copy_Partner_ID__c',
            'CurrencyIsoCode'
        };
    }

    public List<String> getDealDeskCaseFieldList() {
        return new List<String> {
            'Id',
            'Name',
            'Changes__c',
            'Most_Recent_Opportunity_Owner_Email__c',
            'Most_Recent_Opportunity_Owner__c',
            'Funnel_not_supported__c'
        };
    }

    public List<String> getOpportunityCloseFieldList() {
        return new List<String> {
            'RC_Account_Status__c',
            'RC_User_ID__c',
            'RC_Brand__c',
            'Master_Account__c',
            'Service_Type__c',
            'Master_Account__r.Name',
            'Master_Account__r.Active_Sales_Agreement__c',
            'Master_Account__r.Active_Sales_Agreement__r.Brand__c',
            'Master_Account__r.Active_Sales_Agreement__r.Initial_Term_months__c',
            'Master_Account__r.Active_Sales_Agreement__r.Auto_Renewal__c',
            'Master_Account__r.Active_Sales_Agreement__r.Term_months__c',
            'Master_Account__r.Active_Sales_Agreement__r.Start_Date__c',
            'Master_Account__r.Active_Sales_Agreement__r.End_Date__c',
            'Master_Account__r.Active_Sales_Agreement__r.Package_Info__c',
            'Master_Account__r.Active_Sales_Agreement__r.Opportunity.Id',
            'Master_Account__r.Active_Sales_Agreement__r.Opportunity.Tier_Name__c',
            'Billing_ID__c',
            'Account_Payment_Method__c',
            'Payment_Method__c',
            'Active_Sales_Agreement__c',
            'ELA_Account_Type__c',
            'inContact_account_ID__c',
            'Active_Sales_Agreement__r.Brand__c',
            'Active_Sales_Agreement__r.Initial_Term_months__c',
            'Active_Sales_Agreement__r.Auto_Renewal__c',
            'Active_Sales_Agreement__r.Term_months__c',
            'Active_Sales_Agreement__r.Start_Date__c',
            'Active_Sales_Agreement__r.End_Date__c',
            'Active_Sales_Agreement__r.Package_Info__c',
            'Active_Sales_Agreement__r.Opportunity.Id',
            'Active_Sales_Agreement__r.Opportunity.Tier_Name__c',
            'IsMultiProductTechnicalAccount__c'
        };
    }

    private List<String> getLeadConvertFieldList() {
        return new List<String>{
            'Name',
            'RC_Account_Status__c',
            'AccountSource',
            'Bt_Cug_Number__c',
            'Customer_City__c',
            'AH_Name__c',
            'Customer_Country__c',
            'Potential_CC_Users__c',
            'LS_Primary_NAICS__c',
            'Description_of_Your_Business__c',
            'Emp_Range_Sales_Override__c',
            'ELA_Account_Type__c',
            'I_am_a__c',
            'InContract__c',
            'Partner_ID__c',
            'LS_Country__c',
            'LS_Employees__c',
            'LS_No_of_Employees_Range__c',
            'Master_Distributor_Agent__c',
            'Most_Recent_Opportunity_Tier_Name__c',
            'Most_Recent_Opportunity_Owner__c',
            'Most_Recent_Opportunity_Owner_Email__c',
            'Most_Recent_Opportunity_Owner_FirstName__c',
            'Most_Recent_Opportunity_Owner_LastName__c',
            'Most_Recent_Opportunity_Owner_Phone__c',
            'Most_Recent_Opportunity_Forecasted_Users__c',
            'Most_Recent_Opportunity_Stage__c',
            'Next_Steps_questions__c',
            'No_of_Employees_Needing_Phones__c',
            'No_of_Employees__c',
            'NumberOfEmployees',
            'Number_Of_Locations__c',
            'Other_TextField__c',
            'Pain__c',
            'Pain_Impact__c',
            'Partner_Account_Name__c',
            'Reseller__c',
            'RC_Brand__c',
            'Sales_Agent__c',
            'Sales_Industry__c',
            'SDR_Agent__c',
            'Customer_State__c',
            'Target_Account__c',
            'Timezone__c',
            'Total_Potential_Users__c',
            'Industry',
            'Is_the_customer_interested_in_porting__c',
            'Ultimate_Partner_ID__c',
            'Ultimate_Partner_Name__c',
            'VAR_Territory__c',
            'Customer_Postal_Code__c',
            'SMB_Certified__c',
            'Assigned_CSS__c',
            'Recruited_By__c',
            'SIA_Information__c',
            'Sector__c',
            'Segment_Name__c',
            'Sub_Industry__c',
            'Company_DUNS__c',
            'LID__LinkedIn_Company_Id__c',
            'Rating',
            'Website',
            'LS_Enrichment_Date__c',
            'AnnualRevenue',
            'BillingCountry',
            'BillingPostalCode',
            'BillingState',
            'BillingStreet',
            'BillingCity'
        };
    }

    private static List<String> getCaseQueueAssignmentFieldList() {
        return new List<String> {
            'RC_Tier__c',
            'Total_Account_DL_s__c',
            'RC_Brand__c',
            'VIP_Account_Indicator__c',
            'Number_of_DL_s__c',
            'Service_Status__c',
            'Extended_Enterprise_Support_Customer__c'
        };
    }

    public List<Schema.SObjectField> getFieldsForOpportunityTrigger() {
        return new List<Schema.SObjectField> {
            Account.Partner_ID__c,
            Account.Partner_Type__c,
            Account.billingcountry,
            Account.Partner_Contact__c,
            Account.Current_Owner__c,
            Account.No_of_Employees__c,
            Account.Active_Sales_Agreement__c,
            Account.Inside_Sales_Rep__c,
            Account.MRR__c,
            Account.Engage_Digital_Account__c,
            Account.Offer_Type__c,
            Account.Billing_ID__c,
            Account.RC_Brand__c,
            Account.RC_Service_name__c,
            Account.RC_Account_Status__c,
            Account.RecordTypeId,
            Account.OwnerId,
            Account.IsMultiProductTechnicalAccount__c
        };
    }

    //Distribution Routing SubBrandId
    public List<Schema.SObjectField> getSubBrandId(){
        return new List<Schema.SObjectField>{
            Account.Id,
            Account.SubBrandID__c
        };
    }

    public List<String> getPartnerContactRelatedFields() {
        return new List<String> {
            'Partner_Contact__c',
            'Partner_Contact__r.AccountId'
        };
    }

    private List<String> getNewWizardFieldList(){
        return new List<String>{
            'Id',
            'Billing_Id__c',
            'RC_Brand__c',
            'RC_User_ID__c',
            'Target_Account__c',
            'Most_Recent_Implementation_Contact__c',
            'CurrencyIsoCode',
            'BillingCountry',
            'BillingState',
            'BillingCity',
            'BillingStreet',
            'BillingPostalCode',
            'isFedramp__c',
            'Name',
            'VATNumber__c',
            'Accoutn18DigitID__c',
            'Partner_ID__c',
            'Partner_Type__c',
            'ELA_Account_Type__c',
            'AccMigrationFlag__c',
            'Partner_Account__r.NGBS_Partner_ID__c',
            'Partner_Account__r.BillingCountry',
            'Industry',
            'Sector__c',
            'VideoProvider__c',
            'CSM__c',
            'Parent_Partner_Account__c',
            'OwnerId',
            'IsMultiProductTechnicalAccount__c',
            'NumberOfEmployees'
        };
    }
    public List<Schema.SObjectField> getCaseAPIFieldList() {
        return new List<Schema.SObjectField> {
            Account.Id,
            Account.RC_Tier__c,
            Account.Total_Account_DL_s__c,
            Account.RC_Brand__c,
            Account.VIP_Account_Indicator__c,
            Account.Number_of_DL_s__c,
            Account.Service_Status__c,
            Account.Extended_Enterprise_Support_Customer__c
        };
    }

    private List<String> getFieldsForParentAccountMap() {
        return new List<String>{
            'SignupType__c',
            'Most_Recent_Implementation_Contact__c',
            'Preferred_Language__c',
            'SignupPlatform__c',
            'Name',
            'RC_Account_Status__c',
            'AH_Name__c',
            'Company_DUNS__c',
            'RC_Account_Number__c',
            'RC_User_ID__c',
            'RC_Tier__c',
            'RC_Brand__c',
            'RC_Service_name__c',
            'RecordType.Name',
            'CreatedDate',
            'ContactMostFrequentEmail__c',
            'Most_Recent_Opportunity_Stage__c',
            'BillingCountry'
        };
    }

    public List<String> getBoundAccountsFieldList() {
        return new List<String> {
            'Description',
            'Id',
            'AccountNumber',
            'Name',
            'Type',
            'AnnualRevenue',
            'Target_Account__c',
            'Most_Recent_Implementation_Contact__c',
            'CurrencyIsoCode',
            'Master_Account__c',
            'NGBS_Partner_ID__c',
            'Partner_Account__c',
            'Partner_ID__c',
            'Partner_Type__c',
            'PartnerStatus__c',
            'BusinessIdentity__c',
            'Account_Payment_Method__c',
            'RC_User_ID__c',
            'RC_Account_Status__c',
            'RecordTypeId',
            'Billing_ID__c',
            'ELA_Account_Type__c',
            'isFedRamp__c',
            'Package_Status__c',
            'Service_Type__c',
            'BillingCountry',
            'Active_Sales_Agreement__r.Package_Info__c',
            'Monthly_Credit_Limit__c',
            'Sign_up_Purchase_Limit__c',
            'AH_Name__r.D_U_N_S_Number__c',
            'AH_Name__r.AH_Phone__c',
            'AH_Name__r.AH_Website__c',
            'Phone',
            'BillingPostalCode',
            'BillingState',
            'BillingStreet',
            'BillingCity',
            'Active_Invoice_Approval__c',
            'Payment_Method__c',
            'Payment_Terms__c',
            'Invoice_Terms__c',
            'Payment_Plan__c',
            'OwnerId',
            'Inside_Sales_Rep__c',
            'VATNumber__c',
            'SubBrandID__c'
        };
    }

    public static final Set<String> COMBINED_FIELDS_WITH_ORIGIN = new Set<String> {
        'Total_DLs__c',
        'Purchased_DL_s__c',
        'Number_of_DL_s__c',
        'Acquisition_No_of_DL__c',
        'Price_per_DL__c',
        'Additional_Phone_s__c',
        'Number_of_Extensions__c',
        'Number_of_IP_Devices__c'
    };

    public List<Schema.SObjectField> getFieldsForCustomerAccount() {
        return new List<Schema.SObjectField> {
            Account.Id,
            Account.Partner_Id__c,
            Account.Do_Not_Creation_Implementation__c,
            Account.Name,
            Account.Ultimate_Parent_Partner_ID__c,
            Account.Ultimate_Partner_ID__c,
            Account.Ultimate_Partner_Name__c,
            Account.Ultimate_Parent_Account_ID__c,
            Account.Ultimate_Parent_Account_Name__c,
            Account.Current_Owner__c,
            Account.Current_Owner_Email__c,
            Account.Current_Owner_Name__c,
            Account.VAR_Territory__c,
            Account.Signature_Rep_Partnership_Opt_Out__c,
            Account.Inside_Sales_Rep__c,
            // Fields for updateCreditCounter
            Account.Eligible_for_Refferel_Credit__c,
            Account.Partner_Sign_Up_Date__c,
            Account.RC_Signup_Date__c,
            Account.Referring_DSR__c
        };
    }

    private Set<Schema.SObjectField> getFieldsForWsBilling() {
        return new Set<Schema.SObjectField> {
            Account.Id,
            Account.Name,
            Account.AccMigrationFlag__c,
            Account.Billing_ID__c,
            Account.IsMultiProductTechnicalAccount__c,
            Account.Licenses_Purchased__c,
            Account.Master_Account__c,
            Account.Offer_Type__c,
            Account.RC_User_ID__c,
            Account.Service_Type__c,
            Account.RC_Brand__c
        };
    }

    public List<String> getFieldsForTechnicalAccount() {
        return new List<String> {
            'Id',
            'IsMultiProductTechnicalAccount__c',
            'Active_Sales_Agreement__c',
            'Active_Sales_Agreement__r.PackageNameNew__c',
            'Master_Account__c',
            'Master_Account__r.IsRingCx__c',
            'RC_Account_Status__c'
        };
    }

    public Set<SObjectField> getFieldsForEngagePackages() {
        return new Set<SObjectField> {
            Account.Id,
            Account.IsMultiProductTechnicalAccount__c,
            Account.EV_Account_ID__c,
            Account.EV_Platform__c,
            Account.EV_Account_ID__c,
            Account.RC_Engage_Account_ID__c,
            Account.ED_Account_ID__c,
            Account.ED_Platform__c,
            Account.Engage_Domain__c,
            Account.EV_Account_ID__c
        };
    }

    public static final Set<SObjectField> FIELDS_ACCOUNT_UPDATE_MARKETING_ATTRIBUTION = new Set<SObjectField> {
        Account.Id,
        Account.RC_Signup_Funnel__c,
        Account.RC_Attribution_Channel__c,
        Account.RC_Attribution_L2__c,
        Account.RC_Attribution_L3__c,
        Account.RC_Attribution_Campaign__c,
        Account.Attribution_partner_id__c,
        Account.BMID__c,
        Account.PID__c,
        Account.AID__c,
        Account.OID__c
    };

    public List<String> getDateAccountsFieldList() {
        return new List<String> {
            'Id',
            'RC_Signup_Date__c',
            'RC_Activation_Date__c',
            'RC_Upgrade_Date__c',
            'RC_Churn_Date__c',
            'RC_Cancel_Date__c'
        };
    }

    public Set<Schema.SObjectField> getFieldsForAccountWithSinglePackage() {
        return new Set<Schema.SObjectField> {
            Account.Id,
            Account.Name,
            Account.SignupPlatform__c,
            Account.Number_of_POC_Users__c,
            Account.Service_Status__c,
            Account.Minute_Bundle__c,
            Account.Transport_MRR__c,
            Account.Provision_Date__c,
            Account.Contact_Center_Numbers_Location__c,
            Account.inContact_account_ID__c,
            Account.inContact_Cluster__c,
            Account.Outbound_Transport__c,
            Account.InContact_Service__c,
            Account.Price_per_Seat__c,
            Account.EV_Account_ID__c,
            Account.ED_Account_ID__c,
            Account.EV_Shard__c,
            Account.Engage_Domain__c,
            Account.EV_Platform__c,
            Account.ED_Platform__c,
            Account.RC_Engage_Account_ID__c,
            Account.Actual_transport_MRR__c,
            Account.RC_Upgrade_Date__c,
            Account.RC_Activation_Date__c,
            Account.RC_Churn_Date__c,
            Account.RC_Cancel_Date__c,
            Account.RC_Signup_Date__c,
            Account.PID__c,
            Account.RC_Signup_Type__c,
            Account.RC_Signup_Funnel__c,
            Account.RC_Attribution_Channel__c,
            Account.RC_Attribution_L2__c,
            Account.RC_Attribution_L3__c,
            Account.RC_Attribution_Campaign__c,
            Account.BMID__c,
            Account.Attribution_partner_id__c,
            Account.AID__c,
            Account.Acquisition_No_of_DL__c,
            Account.Acquisition_Service__c,
            Account.Acquisition_Tier__c,
            Account.Monthly_CRF__c,
            Account.Sales_Booking_MRS__c,
            Account.RC_Brand__c,
            Account.RC_Tier__c,
            Account.RC_Edition__c,
            Account.Service_Type__c,
            Account.Account_POD__c,
            Account.RC_Brand_ID__c,
            Account.RC_Tier_ID__c,
            Account.Payment_Plan__c,
            Account.Package_Status__c,
            Account.Deferred_Activation_Date__c,
            Account.RC_Account_Number__c,
            Account.Additional_Phone_s__c,
            Account.Purchased_DL_s__c,
            Account.Number_of_DL_s__c,
            Account.Number_of_Extensions__c,
            Account.Number_of_IP_Devices__c,
            Account.Number_of_Leased_Devices__c,
            Account.EnabledLBO__c,
            Account.RC_Edition_ID__c,
            Account.OID__c,
            Account.RC_Service_ID__c,
            Account.SignupType__c,
            Account.Next_Renewal_Date__c,
            Account.RC_Plan_Renewal_Date__c,
            Account.VideoProvider__c,
            Account.No_of_InContact_Seats__c,
            Account.Seat_MRR__c
        };
    }

    public Set<Schema.SObjectField> getAccountServiceRelatedFields() {
        return new Set<Schema.SObjectField>{
            Account.Id,
            Account.Office_30_Day_Trial__c,
            Account.Office_Trial__c,
            Account.RC_Account_Status__c
        };
    }

    public Set<Schema.SObjectField> getPackageServiceRelatedFields() {
        return new Set<Schema.SObjectField>{
            Package__c.Id,
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
            Package__c.CreatedDate
        };
    }

    //PBC-25077
    public List<Schema.SObjectField> getIntentValue(){
        return new List<Schema.SObjectField>{
            Account.Id,
            Account.Intent__c
        };
    }

    //PBC-25077
    public QueryFactory selectIntentValue(List<Object> binding){
        return newQueryFactory()
            .setFactoryName('selectIntentValue')
            .selectFields(getIntentValue())
            .setCondition('Id IN :bind0')
            .setQueryBindings(binding);
    }

    public QueryFactory selectAccounts() {
        return newQueryFactory()
            .setFactoryName('selectAccounts')
            .selectFields(new List<String>{
                'Active_Sales_Agreement__r.Status'
            });
    }

    //Distribution Routing SubBrandId
    public QueryFactory selectSubBrandId(List<Object> binding){
        return newQueryFactory()
            .setFactoryName('selectSubBrandId')
            .selectFields(getSubBrandId())
            .setCondition('Id = :bind0')
            .setQueryBindings(binding);
    }

    public QueryFactory selectAccountForEngagePackageByAccIds(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectAccountForEngagePackageByAccIds')
            .selectFields(getFieldsForEngagePackages())
            .subselect(new AccountSelector('Master_Accounts__r', Account.SObjectType)
                .newQueryFactory()
                .selectFields(getFieldsForEngagePackages())
            )
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectAccountForNewWizard(Id accountId) {
        return newQueryFactory()
            .setFactoryName('selectAccountForNewWizard')
            .selectFields(getNewWizardFieldList())
            .subselect(new AccountSelector('Master_Accounts__r', Account.SObjectType)
                .newQueryFactory()
                .selectFields(getNewWizardFieldList())
            )
            .subselect(new PackageSelector('Service_Accounts__r', Package__c.SObjectType)
                .selectPackageForApproval()
            )
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object> { accountId });
    }

    public QueryFactory selectAccountForPartnerApproval(Id accountId) {
        return newQueryFactory()
            .setFactoryName('selectAccountForPartnerApproval')
            .selectFields(getPartnerApprovalFieldList())
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object>{new Set<Id> {accountId}});
    }

    public QueryFactory selectAccountDefault(String condition) {
        return newQueryFactory()
            .setFactoryName('selectIdOfAccount')
            .selectFields(getDefaultFieldList())
            .setCondition(condition)
            .setLimit(1);
    }

    public QueryFactory selectAccountById(Id accountId) {
        return newQueryFactory()
            .setFactoryName('selectAccountById')
            .selectFields(getDefaultFieldList())
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object>{new Set<Id> {accountId}});
    }

    public QueryFactory selectAccountsWithContacts(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('SelectAccountsWithContacts')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .withSelectFieldsSorted()
                .subselect(new ContactSelector().selectContacts()
                            .selectField(Contact.Email))
            .setCondition('Id IN :bind0')
            .addOrdering('Type', QueryFactory.SortOrder.ASCENDING)
            .setLimit(10)
            .setQueryBindings(bindings);
    }

    public QueryFactory selectAccountsWithActiveContract(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('SelectAccountsWithActiveContacts')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .withSelectFieldsSorted()
                .subselect(new ContractSelector()
                            .selectActiveContracts())
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectAccountsWithActiveSignedContract(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectAccountsWithActiveSignedContract')
            .selectFields(getDefaultFieldList())
            .withoutSelectorOrderByIncluded()
            .subselect(new ContractSelector()
                .selectActiveContractsWithOriginalSignedDate())
            .subselect(new ApprovalSelector()
                .selectKYCRequestApprovals())
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectAccountsForApproval(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectAccountsForApproval')
            .selectFields(getInvoiceApprovalFieldList())
                .subselect(new AccountContactRoleSelector()
                    .selectAccountContactRolesForOpportunityClose()
                    .setCondition('isPrimary = true'))
                .subselect(new PackageSelector().selectPackageForApproval()
                    .selectField(Package__c.Account__c))
                .subselect(new PackageSelector(AccountHelper.ACCOUNT_RELATION_TECH_ACCOUNTS_NAME, Account.SObjectType).selectPackageForApproval())
            .withoutSelectorOrderByIncluded()
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectAccountWithTaxExemptionApprovals(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectAccountWithTaxExemptionApprovals')
            .selectFields(new List<String>{'Id', 'Billing_Id__c', 'BillingCountry', 'TaxExemptionApprovals__c', 'VATNumber__c'})
            .subselect(new ApprovalSelector()
                .selectApprovedTaxExemptionApprovals())
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectAccountWithAllApprovals(String accId, Set<String> approvalTypes) {
        return newQueryFactory()
            .setFactoryName('selectAccountWithAllApprovals')
            .selectFields(getApprovalCreationFieldList())
            .subselect(new ApprovalSelector()
                .selectApprovals()
                .selectFields(new Set<String>{'Id'})
                .setCondition('IsMultiProductTechnicalApproval__c = false AND RecordTypeId in :bind1'))
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object> {accId, approvalTypes});
    }

    public QueryFactory selectOnlyAccountsByIds(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectOnlyAccountByIds')
            .selectFields(getDefaultFieldList())
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectAccountsByIds(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectAccountsByIds')
            .selectFields(getDefaultFieldList())
                .subselect(
                    new QueryFactory(new AccountRelationSelector(), AccountHelper.CHILD_ACCOUNT_JUNCTION_RELATIONSHIP)
                        .setFactoryName('selectJunctionForChildAccount')
                )
                .subselect(
                    new QueryFactory(new AccountRelationSelector(), AccountHelper.PARENT_ACCOUNT_JUNCTION_RELATIONSHIP)
                        .setFactoryName('selectJunctionForParentAccount')
                )
                .subselect(
                    new QueryFactory(new AccountSelector(), AccountHelper.MASTER_ACCOUNT_JUNCTION_RELATIONSHIP)
                        .setFactoryName('selectMasterAccount')
                )
                .subselect(
                    new AccountContactRoleSelector()
                        .selectPrimaryAccountContactRolesByAccountIds(new List<Id>())
                        .setFactoryName('selectMasterAccount')
                )
            .withoutSelectorOrderByIncluded()
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectAccountsForDFR(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectAccountsForDFR')
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectPartnerAccountsByIds(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectPartnerAccountsByIds')
            .selectFields(getDefaultFieldList())
            .withoutSelectorOrderByIncluded()
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectAccountsForDealDeskCase(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectAccountsForDealDeskCase')
            .selectFields(getDealDeskCaseFieldList())
            .subselect(
                new AccountSelector('Master_Account__r', Account.SObjectType)
                    .newQueryFactory()
                    .selectFields(getDealDeskCaseFieldList())
            )
            .withoutSelectorOrderByIncluded()
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectAccountByName(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectAccountByName')
            .selectFields(getDefaultFieldList())
            .withoutSelectorOrderByIncluded()
            .setCondition('Name = :bind0')
            .setLimit(1)
            .setQueryBindings(bindings);
    }

    public QueryFactory selectAccountForOpportunityClose(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectAccountForOpportunityClose')
            .selectFields(getOpportunityCloseFieldList())
                .subselect(new ContactSelector().selectContactsForClose())
                .subselect(new AccountContactRoleSelector().selectAccountContactRolesForOpportunityClose())
            .withoutSelectorOrderByIncluded()
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectChildAccById(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectChildAccById')
            .selectFields(getOpportunityCloseFieldList())
            .subselect(new AccountContactRoleSelector()
                .selectAccountContactRolesForOpportunityClose()
                .setCondition('isPrimary = true AND Role = \''
                    + AccountContactRoleHelper.CONTACT_ROLE_SIGNATORY + '\''))
            .subselect(new QuoteSelector()
                .selectQuotes()
                .setCondition('isPrimary__c = true'))
            .subselect(new AccountContactRelationSelector()
                .selectAccountContactRelationsForAccountLink()
                .setCondition('isPrimary__c = true AND Roles = \''
                    + AccountContactRoleHelper.CONTACT_ROLE_SIGNATORY + '\''))
            .withoutSelectorOrderByIncluded()
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectChildAccByMasterAccount(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectChildAccByMasterAccount')
            .selectFields(getOpportunityCloseFieldList())
            .subselect(new AccountContactRoleSelector()
                .selectAccountContactRolesForOpportunityClose()
                .setCondition('isPrimary = true AND Role = \''
                    + AccountContactRoleHelper.CONTACT_ROLE_SIGNATORY + '\''))
            .subselect(new QuoteSelector()
                .selectQuotes()
                .setCondition('isPrimary__c = true'))
                .subselect(new PackageSelector(AccountHelper.ACCOUNT_RELATION_TECH_ACCOUNTS_NAME, Account.SObjectType).selectPackageForApproval())
            .subselect(new AccountContactRelationSelector()
                .selectAccountContactRelationsForAccountLink()
                .setCondition('isPrimary__c = true AND Roles = \''
                    + AccountContactRoleHelper.CONTACT_ROLE_SIGNATORY + '\''))
            .withoutSelectorOrderByIncluded()
            .setCondition('Master_Account__c IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectChildAccByMasterAccountWithBindedQuotes(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectChildAccByMasterAccountWithBindedQuotes')
            .selectFields(getOpportunityCloseFieldList())
            .subselect(new QuoteSelector()
                .selectQuotes()
                .setCondition('isPrimary__c = true AND ParentQuote__c != null'))
            .withoutSelectorOrderByIncluded()
            .setCondition('Master_Account__c IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectAccWithContactByContactId(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectAccWithContactByContactId')
            .selectFields(getOpportunityCloseFieldList())
            .subselect(new AccountContactRoleSelector()
                .selectAccountContactRolesForOpportunityClose()
                .setCondition('ContactId = :bind1'))
            .subselect(new QuoteSelector()
                .selectQuotes()
                .setCondition('isPrimary__c = true'))
            .subselect(new AccountContactRelationSelector()
                .selectAccountContactRelationsForAccountLink()
                .setCondition('ContactId = :bind2'))
            .withoutSelectorOrderByIncluded()
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }


    public QueryFactory selectAccWithContactByContact(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectAccWithContactByContact')
            .selectFields(getOpportunityCloseFieldList())
            .subselect(new AccountContactRoleSelector()
                .selectAccountContactRolesForOpportunityClose()
                .setCondition('Contact.LastName IN :bind1 AND Contact.Phone IN :bind2'))
            .subselect(new QuoteSelector()
                .selectQuotes()
                .setCondition('isPrimary__c = true'))
            .subselect(new AccountContactRelationSelector()
                .selectAccountContactRelationsForAccountLink()
                .setCondition('Contact.LastName IN :bind3 AND Contact.Phone IN :bind4'))
            .withoutSelectorOrderByIncluded()
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectChildAccounts(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectChildAccounts')
            .selectFields(getDefaultFieldList())
                .subselect(new QuoteSelector()
                    .selectQuotes())
            .withoutSelectorOrderByIncluded()
            .setCondition('Master_Account__c IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectAccountWithLeadConvertFields(Id accountId) {
        return newQueryFactory()
            .setFactoryName('selectAccountWithLeadConvertFields')
            .selectFields(getLeadConvertFieldList())
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object>{accountId});
    }

    public QueryFactory selectPaidAccountWithPackage() {
        return newQueryFactory()
            .setFactoryName('selectPaidAccountsWithPackages')
            .selectField(Account.Billing_ID__c)
            .withoutSelectorOrderByIncluded()
            .subselect(new PackageSelector().selectPackageForApproval());
    }

    public QueryFactory selectAccountsWithPackagesById(List<Object> bindings) {
        return selectPaidAccountWithPackage()
            .setCondition(
                'Id IN :bind0'
            )
            .setQueryBindings(bindings);
    }

    public QueryFactory selectAccountsByUserIds(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectAccountsByRCUserIds')
            .selectFields(getDefaultFieldList())
            .withoutSelectorOrderByIncluded()
            .setCondition('RC_User_ID__c IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectAccountsForOpportunityTrigger(Set<Id> accountIdSet) {
        return newQueryFactory()
            .setFactoryName('selectAccountsForOpportunityTrigger')
            .selectFields(getFieldsForOpportunityTrigger())
            .selectFields(getPartnerContactRelatedFields())
            .withSelectFieldsSorted()
                .subselect(new AccountSelector('Master_Accounts__r', Account.SObjectType)
                    .newQueryFactory()
                    .selectFields(getFieldsForOpportunityTrigger())
                    .selectFields(getPartnerContactRelatedFields())
                )
                .subselect(new ContactSelector().selectContacts().withoutSelectorOrderByIncluded().setLimit(1))
                .subselect(new ImplementationSelector().selectImplementationForAccount())
            .withoutSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .setCondition('Id IN :bind0')
            .setQueryBindings(new List<Object>{ accountIdSet });
    }

    public static Account getAccountWithLeadConvertFields(Id accountId){
        return (Account) new AccountSelector()
            .selectAccountWithLeadConvertFields(accountId)
            .executeQuery()[0];
    }

    public QueryFactory selectAccountWithKYCApprovals(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectAccountWithKYCApprovals')
            .selectFields(new List<Schema.SObjectField>{
                Account.Id,
                Account.BillingState,
                Account.BillingCountry,
                Account.BillingCity,
                Account.BillingStreet,
                Account.BillingPostalCode
            })
            .subselect(new ApprovalSelector()
                .selectKYCApprovalsDescOrderedByStatusModifiedDate())
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectAccountsWithOrderedKYCApprovalsExcludingApprovalRecords(Set<Id> accountsIds, Set<Id> excludingApprovalsIds) {
        return newQueryFactory()
            .setFactoryName('selectAccountsWithOrderedKYCApprovalsExcludingApprovalRecords')
            .setCondition('Id IN :bind0')
            .subselect(new ApprovalSelector()
                .selectKYCRequestApprovals()
                .setCondition('RecordTypeId = \'' + ApprovalHelper.RT_ID_KYC_APPROVAL_REQUEST + '\'' +
                    ' AND StatusLastModifiedDate__c != null' +
                    ' AND Id NOT IN :bind1'
                )
                .addOrdering('StatusLastModifiedDate__c', QueryFactory.SortOrder.DESCENDING)
                .setLimit(1)
            )
            .setQueryBindings(new List<Object>{accountsIds, excludingApprovalsIds});
    }

    public QueryFactory selectAccountWithApprovedKYCApprovals(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectAccountWithApprovedKYCApprovals')
            .selectFields(new List<String>{'Id'})
            .subselect(new ApprovalSelector()
                .selectKYCApprovedApprovals())
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectAccountsForCaseAPI(Set<Id> accountIdSet){
        return newQueryFactory()
            .setFactoryName('selectAccountsForCaseAPI')
            .selectFields(getCaseAPIFieldList())
            .setCondition('Id IN :bind0')
            .setQueryBindings(new List<Object>{ accountIdSet });
    }

    public QueryFactory selectAccountWithCaseQueueAssignmentFields(Id accountId) {
        return newQueryFactory()
            .setFactoryName('selectAccountWithCaseQueueAssignmentFields')
            .selectFields(getCaseQueueAssignmentFieldList())
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object>{accountId});
    }

    public QueryFactory selectAccountsForParentAccountMap(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectAccountsForParentAccountMap')
            .selectFields(getFieldsForParentAccountMap())
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectAccountsByUltimateAccount(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectAccountsByUltimateAccount')
            .selectFields(getDefaultFieldList())
            .withoutSelectorOrderByIncluded()
            .setCondition('Ultimate_Account__c IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectBoundAccountsByIdOrMasterAccountId(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectBoundAccountsByIdOrMasterAccountId')
            .selectFields(getBoundAccountsFieldList())
            .withoutSelectorOrderByIncluded()
            .setCondition('Id IN :bind0 OR Master_Account__c IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectAccountsWithLastModifiedApprovals(List<Object> bindings, Id recordTypeId) {
        return newQueryFactory()
            .setFactoryName('selectAccountWithApprovals')
            .selectFields(getInvoiceApprovalFieldList())
            .subselect(new ApprovalSelector()
                .selectLastModifiedApprovalByRecordTypeId(recordTypeId))
            .subselect(new AccountContactRoleSelector()
                .selectPrimaryAccountContactRoles())
            .subselect(new QuoteSelector()
                .selectQuotes()
                .setCondition('OpportunityId IN :bind1'
                    + ' AND isPrimary__c = true'
                    + ' AND RecordTypeId = '
                    + '\'' + QuoteHelper.RT_ID_BILLING + '\''))
            .setCondition('Id IN :bind0 OR Master_Account__c IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectBillingAccountsForKYCApproval(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectBillingAccountsForKYCApproval')
            .selectFields(getInvoiceApprovalFieldList())
            .subselect(new AccountContactRoleSelector()
                .selectAccountContactRolesForOpportunityClose()
                .setCondition('isPrimary = true'))
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectMPTechAccountsByMasterIds(Id masterAccountId) {
        return selectMPTechAccountsByMasterIds(new List<Id> { masterAccountId });
    }

    public QueryFactory selectMPTechAccountsByMasterIds(Set<Id> masterIds) {
        return selectMPTechAccountsByMasterIds(new List<Id>(masterIds));
    }

    public QueryFactory selectMPTechAccountsByMasterIds(List<Id> masterIds) {
        return newQueryFactory()
            .setFactoryName('selectMPTechAccountsByMasterIds')
            .selectFields(AquivaHelper.getAllFieldsForObject('Account'))
            .setCondition('IsMultiProductTechnicalAccount__c = true AND Master_Account__c IN :bind0')
            .setQueryBindings(new List<Object> { masterIds });
    }

    public QueryFactory selectMPTechAccountsByMasterIdsForCopying(List<Id> masterIds) {
        return selectMPTechAccountsByMasterIds(masterIds)
            .setFactoryName('selectMPTechAccountsByMasterIdsForCopying')
            .selectFields(FIELDS_FOR_COPYING);
    }

    public QueryFactory selectMPTechAccountsByIdsForCopying(List<Id> techAccountIds) {
        return newQueryFactory()
            .setFactoryName('selectMPTechAccountsByIdsForCopying')
            .selectFields(AquivaHelper.getAllFieldsForObject('Account'))
            .setCondition('IsMultiProductTechnicalAccount__c = true AND Id IN :bind0')
            .setQueryBindings(new List<Object> { techAccountIds });
    }

    public QueryFactory selectAccountsByIdsWithBillingAccountPackages(List<Id> accountIds) {
        return selectAccountsByIdsWithServiceInfoFields(accountIds)
            .setFactoryName('selectAccountsByIdsWithServiceInfoFields')
            .subselect(
                new PackageSelector(AccountHelper.ACCOUNT_RELATION_TECH_ACCOUNTS_NAME, Account.SObjectType)
                    .selectAllPackages()
                    .selectFields(PackageSelector.FIELDS_STANDARD)
            );
    }

    public QueryFactory selectAccountsByIdsWithTechnicalAccounts(List<Id> accountIds) {
        return newQueryFactory()
            .setFactoryName('selectAccountsByIdsWithTechnicalAccounts')
            .selectFields(FIELDS_AGGREGATED_TOTALS)
            .subselect(
                new QueryFactory(new AccountSelector(), AccountHelper.MASTER_ACCOUNT_JUNCTION_RELATIONSHIP)
                    .setFactoryName('selectMasterAccount')
                    .selectFields(FIELDS_AGGREGATED_TOTALS)
            )
            .setCondition('Id IN :bind0 AND IsMultiProductTechnicalAccount__c = false')
            .setQueryBindings(new List<Object> { accountIds });
    }

    public QueryFactory selectAccountsByIdsWithBillingAccountPackagesReportedMRSDependants(List<Id> accountIds) {
        return selectAccountsByIdsWithBillingAccountPackages(accountIds)
            .setFactoryName('selectAccountsByIdsWithBillingAccountPackagesMVPDependants')
            .selectFields(FIELDS_REPORTED_MRS_DEPENDANTS);
    }

    public QueryFactory selectAccountsByIdsWithBillingAccountPackagesServiceInfo(Set<Id> accountIds) {
        return selectAccountsByIdsWithBillingAccountPackagesServiceInfo(new List<Id>(accountIds));
    }

    public QueryFactory selectAccountsByIdsWithBillingAccountPackagesServiceInfo(List<Id> accountIds) {
        return selectAccountsByIdsWithServiceInfoFields(accountIds)
            .setFactoryName('selectAccountsByIdsWithServiceInfoFields')
            .subselect(
                new PackageSelector(AccountHelper.ACCOUNT_RELATION_TECH_ACCOUNTS_NAME, Account.SObjectType)
                    .selectAllPackages()
                    .selectFields(PackageSelector.FIELDS_STANDARD)
                    .selectFields(PackageSelector.FIELDS_SERVICE_INFO)
            );
    }

    public QueryFactory selectAccountsByIdsWithServiceInfoFields(List<Id> accountIds) {
        return newQueryFactory()
            .setFactoryName('selectAccountsByIdsWithServiceInfoFields')
            .withoutSelectorFieldsIncluded()
            .selectFields(FIELDS_SERVICE_INFO)
            .setCondition('Id IN :bind0')
            .setQueryBindings(new List<Object> { accountIds });
    }

    public QueryFactory selectAccountByIdWithAllFields(Id accountId) {
        return selectAccountById(accountId)
            .setFactoryName('selectAccountByIdWithAllFields')
            .selectFields(AquivaHelper.getAllFieldsForObject('Account'));
    }

    public QueryFactory selectMPAccountsWithTechAccountsByAccountIds(Set<Id> accountIds) {
        return selectMPAccountsWithTechAccountsByAccountIds(new List<Id>(accountIds));
    }

    public QueryFactory selectMPAccountsWithTechAccountsByAccountIds(List<Id> accountIds) {
        return newQueryFactory()
            .setFactoryName('selectMPAccountsWithTechAccountsByAccountIds')
            .selectFields(new List<String>{'Id'})
            .subselect(
                new QueryFactory(new AccountSelector(), AccountHelper.MASTER_ACCOUNT_JUNCTION_RELATIONSHIP)
                    .setFactoryName('selectChildAccounts')
                    .selectFields(new List<String>{'Id', 'IsMultiProductTechnicalAccount__c', 'Master_Account__c'})
                    .setCondition('IsMultiProductTechnicalAccount__c = true')
            )
            .setCondition('IsMultiProductTechnicalAccount__c = false AND Id IN :bind0')
            .setQueryBindings(new List<Object> { accountIds });
    }

    public QueryFactory selectMPAccountsWithTechAccountsAndContactRolesByAcrIds(Set<Id> acrIds) {
        return selectMPAccountsWithTechAccountsAndContactRolesByAcrIds(new List<Id>(acrIds));
    }

    public QueryFactory selectMPAccountsWithTechAccountsAndContactRolesByAcrIds(List<Id> acrIds) {
        return newQueryFactory()
            .setFactoryName('selectMPAccountsWithTechAccountsAndContactRolesByAcrIds')
            .selectFields(new List<String>{'Id', 'Master_Account__c', 'IsMultiProductTechnicalAccount__c', 'RC_Service_name__c' })
            .subselect(
                new QueryFactory(new AccountSelector(), AccountHelper.MASTER_ACCOUNT_JUNCTION_RELATIONSHIP)
                    .setFactoryName('selectChildAccounts')
                    .selectFields(new List<String>{'Id', 'IsMultiProductTechnicalAccount__c', 'Master_Account__c', 'RC_Service_name__c' })
                    .setCondition('IsMultiProductTechnicalAccount__c = true')
                    .withoutSelectorOrderByIncluded()
                    .addOrdering('CreatedDate', QueryFactory.SortOrder.DESCENDING)
            )
            .subselect(
                new QueryFactory(new AccountContactRoleSelector(), AccountHelper.ACCOUNT_CONTACT_ROLES_RELATIONSHIP)
                    .setFactoryName('selectMasterAccountContactRoles')
                    .selectFields(new List<String>{'Id', 'AccountId', 'ContactId', 'Role', 'IsPrimary' })
                    .withoutSelectorOrderByIncluded()
                    .addOrdering('CreatedDate', QueryFactory.SortOrder.DESCENDING)
            )
            .setCondition('IsMultiProductTechnicalAccount__c = false AND Id IN (SELECT AccountId FROM AccountContactRole WHERE Id IN :bind0)')
            .withoutSelectorOrderByIncluded()
            .addOrdering('CreatedDate', QueryFactory.SortOrder.DESCENDING)
            .setQueryBindings(new List<Object> {
                acrIds
            });
    }

    public QueryFactory selectMPTechAccountsWithContactRolesByMasterAccountIds(Set<Id> accountIds) {
        return selectMPTechAccountsWithContactRolesByMasterAccountIds(new List<Id>(accountIds));
    }
    public QueryFactory selectMPTechAccountsWithContactRolesByMasterAccountIds(List<Id> accountIds) {
        return newQueryFactory()
            .setFactoryName('selectMPTechAccountsWithContactRolesByMasterAccountIds')
            .selectFields(new List<String> { 'Id', 'Master_Account__c', 'IsMultiProductTechnicalAccount__c', 'RC_Service_name__c' })
            .subselect(
                new QueryFactory(new AccountContactRoleSelector(), AccountHelper.ACCOUNT_CONTACT_ROLES_RELATIONSHIP)
                    .setFactoryName('selectMasterAccountContactRoles')
                    .selectFields(new List<String>{'Id', 'AccountId', 'ContactId', 'Role', 'IsPrimary' })
                    .withoutSelectorOrderByIncluded()
                    .addOrdering('CreatedDate', QueryFactory.SortOrder.DESCENDING)
            )
            .setCondition('IsMultiProductTechnicalAccount__c = true AND Master_Account__c IN :bind0')
            .withoutSelectorOrderByIncluded()
            .addOrdering('CreatedDate', QueryFactory.SortOrder.DESCENDING)
            .setQueryBindings(new List<Object> { accountIds });
    }

    public QueryFactory selectMPTechAccountsWithContactRolesByAcrIds(Set<Id> acrIds) {
        return selectMPTechAccountsWithContactRolesByAcrIds(new List<Id>(acrIds));
    }

    public QueryFactory selectMPTechAccountsWithContactRolesByAcrIds(List<Id> acrIds) {
        return newQueryFactory()
            .setFactoryName('selectMPTechAccountsWithContactRolesByAcrIds')
            .selectFields(new List<String> { 'Id', 'Master_Account__c', 'IsMultiProductTechnicalAccount__c', 'RC_Service_name__c' })
            .subselect(
                new QueryFactory(new AccountContactRoleSelector(), AccountHelper.ACCOUNT_CONTACT_ROLES_RELATIONSHIP)
                    .setFactoryName('selectMasterAccountContactRoles')
                    .selectFields(new List<String>{'Id', 'AccountId', 'ContactId', 'Role', 'IsPrimary' })
                    .withoutSelectorOrderByIncluded()
                    .addOrdering('CreatedDate', QueryFactory.SortOrder.DESCENDING)
            )
            .setCondition('IsMultiProductTechnicalAccount__c = true AND Master_Account__c IN (SELECT AccountId FROM AccountContactRole WHERE Id IN :bind0)')
            .withoutSelectorOrderByIncluded()
            .addOrdering('CreatedDate', QueryFactory.SortOrder.DESCENDING)
            .setQueryBindings(new List<Object> { acrIds });
    }

    public QueryFactory selectCustomerAccountsByPartnerIds(Set<String> partnerIds) {
        return selectAccountsByPartnerIdsAndByRecordTypeName(partnerIds, AccountHelper.RT_NAME_CUSTOMER_ACCOUNT);
    }

    public QueryFactory selectPartnerAccountsByPartnerIds(Set<String> partnerIds) {
        return selectAccountsByPartnerIdsAndByRecordTypeName(partnerIds, AccountHelper.RT_NAME_PARTNER_ACCOUNT);
    }

    public QueryFactory selectAccountsByPartnerIdsAndByRecordTypeName(Set<String> partnerIds, String recordTypeName) {
        return newQueryFactory()
            .setFactoryName('selectCustomerAccountsByPartnerIds')
            .selectFields(getFieldsForCustomerAccount())
            .setCondition('Partner_Id__c IN :bind0 AND RecordType.Name = :bind1 AND RC_Account_Status__c != \'Canceled\'')
            .setQueryBindings(new List<Object>{partnerIds, recordTypeName});
    }

    public QueryFactory selectAccountsByTypeAndByPartnerIds(String accountType, Set<String> partnerIds) {
        return newQueryFactory()
            .setFactoryName('selectPartnerAccountsByPartnerIds')
            .selectFields(getFieldsForCustomerAccount())
            .setCondition('Partner_Id__c IN :bind0 AND Type = :bind1')
            .setQueryBindings(new List<Object>{partnerIds, accountType});
    }

    public QueryFactory selectMPAccountsWithTaxExemptionApprovals(List<Object> bindings) {
        ApprovalSelector appSelector = new ApprovalSelector();
        return newQueryFactory()
            .setFactoryName('selectMPAccountsWithTaxExemptionApprovals')
            .subselect(appSelector.selectApprovedTaxExemptionApprovals()
                .selectFields(appSelector.getTaxExemptionFieldList()))
            .setCondition('Id IN :bind0 OR Master_Account__c IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectAccountsByIdNoFields(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectAccountsByIdNoFields')
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectAccountsByIdForNotification(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectAccountsByIdForNotification')
            .withSelectorFieldsIncluded()
            .selectFields(new List<String>{'Id', 'Owner.Email'})
            .setCondition('Id IN: bind0 AND Owner.IsActive = true')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectAccountsWithContactsAndOpptys(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectAccountsWithContactsAndOpptys')
            .selectFields(new List<String>{'Id'})
            .subselect(new ContactSelector().selectContactsForClose())
            .subselect(new OpportunitySelector().selectOpptys())
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectPartnerAccountsByIdsAndRT(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectAccountsWithContactsAndOpptys')
            .selectFields(new List<String>{
                'Id', 'RecordType.Name', 'Inside_Sales_Rep__c', 'Partner_Account__c', 'Partner_Account__r.Inside_Sales_Rep__c',
                'Partner_Account__r.Inside_Sales_Rep__r.isActive', 'Inside_Sales_Rep__r.isActive'
            })
            .subselect(new AccountTeamMemberSelector().selectAccountTeamMembers())
            .setCondition('Id IN :bind0 OR Partner_Account__c IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectCustomerAccountsByParentSnapshot(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectCustomerAccountsByParentSnapshot')
            .selectFields(new List<String> {
                'Id', 'Ultimate_Parent_Account_ID__c', 'Ultimate_Parent_Snapshot__c', 'Number_of_DL_s__c', 'Total_DLs__c'
            })
            .setCondition('Name != null ' +
                'AND RecordType.Name = \'Customer Account\' ' +
                'AND (Ultimate_Parent_Snapshot__c IN :bind0 OR Id IN :bind0)')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectPartnerAccountsByParentDetail(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectPartnerAccountsByParentDetail')
            .selectFields(new List<String>{
                'Name', 'Parent_Detail__c', 'Partner_ID__c', 'Do_Not_Creation_Implementation__c',
                'Ultimate_Parent_Partner_ID__c', 'Ultimate_Partner_ID__c', 'Ultimate_Partner_Name__c',
                'Ultimate_Parent_Account_ID__c', 'Ultimate_Parent_Account_Name__c', 'Current_Owner__c',
                'Current_Owner_Email__c', 'Current_Owner_Name__c'
            })
            .setCondition('ParentId != null ' +
                'AND Parent_Detail__c != null ' +
                'AND Parent_Detail__c LIKE :bind0 ' +
                'AND RecordType.Name = \'Partner Account\'')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectPartnerAccountsByPartnerId(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectPartnerAccountsByPartnerId')
            .selectFields(new List<String>{
                'Name', 'Parent_Detail__c', 'Partner_ID__c', 'Do_Not_Creation_Implementation__c',
                'Ultimate_Parent_Partner_ID__c', 'Ultimate_Partner_ID__c', 'Ultimate_Partner_Name__c',
                'Ultimate_Parent_Account_ID__c', 'Ultimate_Parent_Account_Name__c', 'Current_Owner__c',
                'Current_Owner_Email__c', 'Current_Owner_Name__c'
            })
            .setCondition('Partner_ID__c IN :bind0 AND RecordType.Name = \'Partner Account\'')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectCustomerAccountsByParentId(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectCustomerAccountsByParentId')
            .selectFields(new List<String> {
                'Name', 'Parent_Detail__c', 'Partner_ID__c', 'Do_Not_Creation_Implementation__c',
                'Ultimate_Parent_Partner_ID__c', 'Ultimate_Partner_ID__c', 'Ultimate_Partner_Name__c',
                'Ultimate_Parent_Account_ID__c', 'Ultimate_Parent_Account_Name__c', 'Current_Owner__c',
                'Current_Owner_Email__c', 'Current_Owner_Name__c'
            })
            .setCondition('Partner_ID__c IN :bind0 AND RecordType.Name = \'Customer Account\'')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectAccountsForOfficeTrail(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectAccountsForOfficeTrail')
            .withSelectorFieldsIncluded()
            .selectFields(new List<String>{
                'Owner.Email', 'Owner.Name', 'Owner.Team__c',
                'Owner.Manager.Name', 'Owner.Manager.Email', 'CreatedBy.Name'
            })
            .subselect(new ContactSelector()
                .selectContacts()
                .withoutSelectorOrderByIncluded()
                .withSelectorOrderByIncluded()
                .selectFields(new List<String>{
                    'Id', 'Email', 'Phone', 'FirstName', 'NumberOfEmployees__c',
                    'LastName', 'Account.Name', 'Account.No_of_Employees__c'
                })
                .addOrdering('LastModifiedDate', QueryFactory.SortOrder.DESCENDING))
            .subselect(new AccountContactRoleSelector()
                .selectAccountContactRoles()
                .withoutSelectorFieldsIncluded()
                .withoutSelectorOrderByIncluded()
                .selectFields(new List<String>{
                    'Account.Name', 'Contact.Email', 'Contact.Phone', 'Contact.LastName',
                    'Contact.NumberOfEmployees__c', 'IsPrimary', 'Account.No_of_Employees__c'
                })
                .setCondition('IsPrimary = TRUE')
                .setLimit(1))
            .subselect(new SurveySelector()
                .selectSurveys()
                .withoutSelectorFieldsIncluded()
                .withoutSelectorOrderByIncluded()
                .selectFields(new List<String>{ 'Id' })
                .setCondition('SurveyType__c = \'VAR Customer\'')
                .setLimit(1))
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectAccsForTechApprovalValidation(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectAccsForTechApprovalValidation')
            .selectFields(new List<String>{'Id', 'IsMultiProductTechnicalAccount__c'})
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectAccountsWithFinanceCases(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectAccountsWithFinanceCases')
            .withoutSelectorFieldsIncluded()
            .selectField('Id')
            .subselect(new CaseSelector()
                .selectCases()
                .selectFields(new List<String>{ 'Id' })
                .setCondition('RecordType.Name = \'COE Audit\'')
            )
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectAccsForSyncAccountWs(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectAccsForSyncAccountWs')
            .selectFields(new List<String>{'Id', 'IsMultiProductTechnicalAccount__c', 'Master_Account__c'})
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectAccountsForCase(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectAccsForSyncAccountWs')
            .selectFields(new List<String>{'Id', 'RC_Brand__c'})
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectTechnicalAccounts(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectTechnicalAccounts')
            .selectFields(getFieldsForTechnicalAccount())
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectAccountsByBillingIdOrRCUserId(String accountBillingId, String rcUserId) {
        return newQueryFactory()
            .setFactoryName('selectAccountsByBillingIdOrRCUserId')
            .selectFields(getFieldsForWsBilling())
            .setCondition('Billing_ID__c = :bind0 OR RC_User_ID__c = :bind1')
            .setQueryBindings(new List<Object> {accountBillingId, rcUserId});
    }

    public QueryFactory selectPartnerAccountsForUpdateSubBrands(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectPartnerAccountsForUpdateSubBrands')
            .selectFields(new List<String>{'Id', 'Sub_Brands_Permitted_To_Sell__c', 'Partner_ID__c'})
            .setCondition('Partner_ID__c IN :bind0 AND Type = \'Partner\'')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectIncumbentInfoForAccts(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectIncumbentInfoForAccts')
            .selectFields(new List<String>{'Id'})
            .subselect(new IncumbentInformationSelector()
                .selectIncumbentInfo()
                .withoutSelectorOrderByIncluded()
                .selectFields(new IncumbentInformationSelector().getIncumbentInfoFields())
                .addOrdering('LastModifiedDate', QueryFactory.SortOrder.DESCENDING)
                .setLimit(1)
            )
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectAccountsForConnectServiceAccountToOrder(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectAccountsForConnectServiceAccountToOrder')
            .selectFields(new List<String>{'Id'})
            .subselect(
                new OrderSelector('Orders', Account.SObjectType)
                    .newQueryFactory()
                    .selectFields(new List<String>{'Id', 'Status', 'PackageId__c', 'AccountId', 'QuoteId', 'TechnicalQuoteId__r.Package_Info__c'})
            )
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectAccountsWithOrdersForOrderActivationMPUB(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectAccountsWithOrdersForOrderActivationMPUB')
            .selectFields(new List<String>{'Id'})
            .subselect(
                new OrderSelector('Orders', Account.SObjectType)
                    .newQueryFactory()
                    .selectFields(new List<String>{'Id', 'Status', 'PackageId__c', 'CreatedDate', 'TechnicalQuoteId__c', 'Quote.RecordTypeId'})
                    .setCondition('PackageId__c IN :bind1 ' +
                        'AND Status = \'' + OrderHelper.STATUS_NEW + '\' ' +
                        'AND Quote.RecordTypeId = \'' + QuoteHelper.RT_ID_BILLING + '\'')
            )
            .subselect(
                new QueryFactory(new AccountSelector(), AccountHelper.MASTER_ACCOUNT_JUNCTION_RELATIONSHIP)
                    .setFactoryName('selectMasterAccount')
                    .selectFields(new List<String>{'Id'})
            )
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectAccountsWithSpecificRecordType(List<Object> bindings){
        return newQueryFactory()
        .setFactoryName('SelectAccountsWithSpecificRecordType')
        .selectFields(new List<String>{'Id', 'Name', 'ParentId', 'EVA_Journey__c', 'EVA_Awareness_Score__c',
        'EVA_RNG_EX_Score__c', 'EVA_RNG_CX_Score__c', 'EVA_RNG_Sense_Score__c', 'EVA_RNG_Events_Score__c',
        'EVA_RNG_RC_Intent_Score__c', 'EVA_RNG_External_Intent_Score__c', 'EVA_Journey_Classification__c', 'Is_EVA_Processed__c', 'EVA_Journey_Stage_Date__c'})
        .setCondition('RecordType.Name = :bind0 AND Is_EVA_Processed__c = false' )
        .setQueryBindings(bindings);
    }

    public QueryFactory selectAccountsWithSpecificRecordTypeAndParentId(List<Object> bindings){
        return newQueryFactory()
        .setFactoryName('SelectAccountsWithSpecificRecordType')
        .selectFields(new List<String>{'Id', 'Name', 'ParentId', 'EVA_Journey__c', 'EVA_Awareness_Score__c',
        'EVA_RNG_EX_Score__c', 'EVA_RNG_CX_Score__c', 'EVA_RNG_Sense_Score__c', 'EVA_RNG_Events_Score__c',
        'EVA_RNG_RC_Intent_Score__c', 'EVA_RNG_External_Intent_Score__c', 'EVA_Journey_Classification__c', 'Is_EVA_Processed__c', 'EVA_Journey_Stage_Date__c'})
        .setCondition('RecordType.Name = :bind0 AND ParentId IN :bind1')
        .setQueryBindings(bindings);
    }

    public QueryFactory selectAccsForMarketingAttributionUpdate(List<Object> accIds) {
        return newQueryFactory()
            .setFactoryName('selectAccsForMarketingAttributionUpdate')
            .selectFields(FIELDS_ACCOUNT_UPDATE_MARKETING_ATTRIBUTION)
            .subselect(new PackageSelector('Service_Accounts__r', Package__c.SObjectType)
                .selectPkgsForMarketingAttributionUpdate()
            )
            .setCondition('Id IN :bind0')
            .setQueryBindings(accIds);
    }

    public QueryFactory selectAccountsDateFieldsUpdateByAccountIds(List<Object> accIds) {
        return newQueryFactory()
            .setFactoryName('selectAccountsDateFieldsUpdateByAccountIds')
            .selectFields(getDateAccountsFieldList())
            .setCondition('Id IN :bind0')
            .setQueryBindings(accIds);
    }

    public QueryFactory selectAccountForSyncWS(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectAccountForSyncWS')
            .selectFields(new List<String>{
                'Id', 'Name', 'Phone', 'RC_User_ID__c', 'Bt_Cug_Number__c', 'Billing_ID__c',
                'IsMultiProductTechnicalAccount__c', 'Master_Account__c'
            })
            .setCondition('(RC_User_ID__c != NULL AND RC_User_ID__c = :bind0) OR (Internal_Enterprise_Account_ID__c != NULL AND Internal_Enterprise_Account_ID__c = :bind0)')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectAccountsWithSinglePackage(List<Id> accIds, String condition) {
        QueryFactory factory = newQueryFactory()
            .setFactoryName('SelectAccountsWithSinglePackage')
            .selectFields(getFieldsForAccountWithSinglePackage())
            .subselect(
                new PackageSelector('Service_Accounts__r', Package__c.SObjectType)
                    .newQueryFactory()
                    .selectField('Id')
            );
        List<Object> bindings = new List<Object>();
        if (!String.isBlank(condition)) {
            factory.addCondition(condition);
        }
        if (!accIds.isEmpty()) {
            factory.addCondition('Id IN :bind0');
            bindings.add(accIds);
        }
        return factory.setQueryBindings(bindings);
    }

    public QueryFactory selectAccountWithServiceRelatedFields(List<Object> accIds) {
        return newQueryFactory()
            .setFactoryName('SelectAccountWithServiceRelatedFields')
            .selectFields(getAccountServiceRelatedFields())
            .subselect(new PackageSelector('Service_Accounts__r', Package__c.SObjectType)
                .newQueryFactory()
                .selectFields(getPackageServiceRelatedFields())
            )
            .subselect(new AccountManagementSelector()
                .selectAccountManagements()
            )
            .subselect(new DealSupportSelector()
                .selectDealSupports()
            )
            .subselect(new RetentionTaskSelector()
                .selectRetentionTasks()
            )
            .subselect(new ImplementationSelector()
                .selectImplementations()
            )
            .setCondition('Id IN :bind0')
            .setQueryBindings( accIds );
    }
}