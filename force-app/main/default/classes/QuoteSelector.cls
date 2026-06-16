public inherited sharing class QuoteSelector extends SObjectSelector {
    public static final Set<String> FIELDS_ORDER_CREATION_PROCESS = new Set<String> {
        'Id',
        'Name',
        'AccountId',
        'Account.Id',
        'Account.IsMultiProductTechnicalAccount__c',
        'OpportunityId',
        'Opportunity.Id',
        'Opportunity.PrimaryQuote__c',
        'Pricebook2Id',
        'Pricebook2.Id',
        'Opportunity.Tier_Name__c',
        'Opportunity.Type',
        'Status',
        'ServiceName__c',
        'Package_Info__c',
        'Term_months__c',
        'CurrencyIsoCode',
        'Initial_Term_months__c',
        'IsMultiProductTechnicalQuote__c',
        'CreatedDate',
        'QuoteType__c',
        'Start_Date__c',
        'End_Date__c',
        'AreaCode__c',
        'FaxAreaCode__c',
        'ContactId',
        'Auto_Renewal__c',
        'Upsell_Status__c',
        'Enabled_LBO__c',
        'MasterQuote__c',
        'isPrimary__c',
        'PackageNameOld__c',
        'PackageNameNew__c',
        'BillingPackage__c',
        'MasterQuote__r.AccountId',
        'MasterQuote__r.OpportunityId',
        'MasterQuote__r.Status',
        'MasterQuote__r.End_Date__c',
        'MasterQuote__r.QuoteType__c',
        'MasterQuote__r.Start_Date__c',
        'MasterQuote__r.CreatedDate',
        'MasterQuote__r.Package_Info__c',
        'MasterQuote__r.Enabled_LBO__c',
        'MasterQuote__r.Term_months__c',
        'MasterQuote__r.Initial_Term_months__c',
        'MasterQuote__r.AreaCode__c',
        'MasterQuote__r.FaxAreaCode__c',
        'MasterQuote__r.ContactId',
        'MasterQuote__r.Auto_Renewal__c',
        'MasterQuote__r.Account.RC_Signup_Date__c',
        'MasterQuote__r.Upsell_Status__c',
        'MasterQuote__r.isPrimary__c',
        'MasterQuote__r.Account.IsMultiProductTechnicalAccount__c',
        'MasterQuote__r.Signed_SOW__c'
    };
    private static final Set<String> ENGAGE_SERVICES_EXCLUDED_FROM_AUTOSYNC = new Set<String> {
        QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT,
        QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT,
        QuoteHelper.NGBS_ENGAGE_VOICE_LEGACY_PRODUCT,
        QuoteHelper.NGBS_ENGAGE_DIGITAL_LEGACY_PRODUCT
    };
    private static final Set<String> SERVICES_FOR_LBO_FLAG = new Set<String> {
        'Meetings',
        QuoteHelper.NGBS_FAX_PRODUCT
    };

    public QuoteSelector() {
        super();
    }

    public QuoteSelector(String relationshipName, SObjectType relationshipBase) {
        super(relationshipName, relationshipBase);
    }

    public QuoteSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return Quote.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Quote.Id,
            Quote.AccountId,
            Quote.Account__c,
            Quote.Status,
            Quote.RecordTypeId,
            Quote.Quote_is_Invalid__c,
            Quote.Total_Number_of_Digital_Lines__c,
            Quote.IsMultiProductTechnicalQuote__c,
            Quote.Pricebook2Id,
            Quote.IsDeselected__c
        };
    }

    public List<String> getFieldList() {
        return new List<String>{
            'Id',
            'Name',
            'Account__c',
            'Account__r.Billing_ID__c',
            'Status',
            'Package_Info__c',
            'Enabled_LBO__c',
            'IsDeselected__c',
            'AverageDiscount__c',
            'RecordTypeId',
            'RecordType.Name',
            'OpportunityId',
            'Name',
            'NGBSTaxesAdded__c',
            'Initial_Term_POC__c',
            'IsSendOrderToNGBS__c',
            'Shipping_Option__c',
            'ExpirationDate',
            'Quote_is_Invalid__c',
            'QuotePosition__c',
            'IsQuoteHasErrors__c',
            'Opportunity.StageName',
            'Opportunity.Id',
            'Opportunity.Type',
            'Opportunity.Name',
            'Opportunity.Account.Id',
            'Opportunity.Account.Name',
            'Opportunity.Brand_Name__c',
            'Opportunity.CurrencyIsoCode',
            'Opportunity.Is_Billing_Opportunity__c',
            'Opportunity.Tier_Name__c',
            'Opportunity.CreatedDate',
            'Opportunity.Parent_Order__c',
            'Opportunity.RecordType.Name',
            'Opportunity.Contact_Center_MRR__c',
            'Opportunity.BusinessIdentity__c',
            'Opportunity.Parent_Order__r.QuoteId',
            'Opportunity.Parent_Order__r.Quote.ProServListPrice__c',
            'Opportunity.Parent_Order__r.Quote.ProServDiscount__c',
            'QuoteNumber',
            'QuoteType__c',
            'PackageNameOld__c',
            'BillingPackage__c',
            'ProServProjectManager__c',
            'ProServProjectManager__r.Name',
            'ProServ_Status__c',
            'Approved_Status__c',
            'Level_1_Approver__c',
            'Level_2_Approver__c',
            'Level_3_Approver__c',
            'Level_4_Approver__c',
            'Level_5_Approver__c',
            'isPrimary__c',
            'Approval_Type__c',
            'ParentQuote__c',
            'ParentQuote__r.Id',
            'ParentQuote__r.Start_Date__c',
            'Special_Terms__c',
            'Billing_Zip_Postal_Code__c',
            'Billing_City__c',
            'Billing_Country__c',
            'Billing_State_Province__c',
            'Billing_Street__c',
            'Account.Id',
            'Account.BillingPostalCode',
            'Account.BillingCity',
            'Account.BillingCountry',
            'Account.BillingState',
            'Account.BillingStreet',
            'Account.Billing_ID__c',
            'Account.Master_Account__c',
            'Account.ELA_Account_Type__c',
            'Account.NGBS_Partner_ID__c',
            'Account.Partner_ID__c',
            'Account.Partner_Type__c',
            'Account.Partner_Account__r.NGBS_Partner_ID__c',
            'Account.RC_User_ID__c',
            'LastModifiedDate',
            'Upsell_Status__c',
            'Initial_Term_months__c',
            'Auto_Renewal__c',
            'Term_months__c',
            'Start_Date__c',
            'End_Date__c',
            'UpdateContractTerms__c',
            'FreeShippingTerms__c',
            'FSC_Full_MRS_Calculation__c',
            'PaymentMethod__c',
            'Brand__c',
            'CurrencyIsoCode',
            'Total_MRR_with_Taxes__c',
            'Total_One_Time_with_Taxes__c',
            'OverallDiscretion__c',
            'AverageDiscount__c',
            'MasterQuote__c',
            'IsMultiProductTechnicalQuote__c',
            'IsTermination__c',
            'ServiceName__c',
            'Delta_ARR__c',
            'Total_One_Time__c',
            'Entitlement_Total_MRR__c',
            'Total_Initial_Payment__c',
            'DownsellApprover__c',
            'ProServ_Details__c',
            'Name',
            'BusinessIdentity__c',
            'MasterQuote__r.isPrimary__c',
            'MasterQuote__r.Name',
            'Pricebook2Id',
            'Pricebook2.Brand__c',
            'Signed_SOW__c',
            'MasterQuote__r.TotalProjectHoursQuoted__c',
            'MasterQuote__r.PSProjectComplexity__c',
            'MasterQuote__r.ProServ_Forecasted_Close_Date__c',
            'MasterQuote__r.IsQuoteHasErrors__c'
        };
    }

    public List<String> getFieldsForQuotingToolItemsSync() {
        return new List<String> {
            'Id',
            'Pricebook2.Id',
            'AccountId',
            'Account__c',
            'CurrentService__c',
            'RecordTypeId',
            'CurrencyIsoCode',
            'RecordTypeId'
        };
    }

    public List<String> getFieldsForTerminationCheck() {
        return new List<String> {
            'Id',
            'IsTermination__c'
        };
    }

    public List<String> getFieldsForShipping() {
        return new List<String> {
            'Id',
            'Enabled_LBO__c',
            'Package_Info__c',
            'IsMultiProductTechnicalQuote__c',
            'IsQuoteHasErrors__c'
        };
    }

    public List<String> getTotalAmountsForOpportunity() {
        return new List<String> {
            'OpportunityId',
            'Total_First_Year_Cost__c',
            'Total_ARR__c',
            'Total_One_Time__c',
            'Package_Info__c',
            'IsMultiProductTechnicalQuote__c',
            'MasterQuote__r.isPrimary__c',
            'isPrimary__c',
            'RecordTypeId',
            'Total_ARR__c',
            'Total_One_Time__c',
            'Delta_ARR__c',
            'Delta_CC_ARR__c',
            'LastModifiedDate',
            'ServiceName__c',
            'Account.Billing_ID__c',
            'Account.Active_Sales_Agreement__c',
            'Account.RC_Account_Status__c',
            'Account.Offer_Type__c',
            'Account.RC_User_ID__c',
            'MasterQuote__c',
            'Id'
        };
    }

    public List<String> getRelatedAreaCodeFields() {
        return new List<String>{
            'AreaCode__c',
            'AreaCode__r.Name',
            'AreaCode__r.Area_Code__c',
            'AreaCode__r.Type__c',
            'AreaCode__r.City__c',
            'AreaCode__r.Country__c',
            'AreaCode__r.State__c',
            'AreaCode__r.StateID__c',
            'AreaCode__r.NPA__c',
            'AreaCode__r.NXX__c',

            'FaxAreaCode__c',
            'FaxAreaCode__r.Name',
            'FaxAreaCode__r.Area_Code__c',
            'FaxAreaCode__r.Type__c',
            'FaxAreaCode__r.City__c',
            'FaxAreaCode__r.Country__c',
            'FaxAreaCode__r.State__c',
            'FaxAreaCode__r.StateID__c',
            'FaxAreaCode__r.NPA__c',
            'FaxAreaCode__r.NXX__c'
        };
    }

    public List<String> getFieldsForSyncWithNGBSMultiProduct() {
        return new List<String> {
            'Package_Info__c',
            'AccountId',
            'InvoiceId__c',
            'CountOfDownsellQLI__c',
            'Account.Billing_ID__c',
            'Account.RC_User_ID__c',
            'Account.Offer_Type__c',
            'Account.Name',
            'Account.ELA_Account_Type__c',
            'Account.RecordTypeId',
            'Account.Payment_Plan__c',
            'Account.Partner_Type__c',
            'Account.Partner_ID__c',
            'Account.Partner_Account__c',
            'Account.Partner_Account__r.NGBS_Partner_ID__c',
            'Account.Account_Payment_Method__c',
            'Account.EnabledLBO__c',
            'Account.Master_Account__c',
            'Account.Master_Account__r.RC_Account_Status__c',
            'Account.RC_Account_Status__c',
            'Contact.FirstName',
            'Contact.LastName',
            'Initial_Term_months__c',
            'IsMultiProductTechnicalQuote__c',
            'LBODealDeskProvision__c',
            'Term_months__c',
            'Auto_Renewal__c',
            'Start_Date__c',
            'UpdateContractTerms__c',
            'Upsell_Status__c',
            'OpportunityId',
            'Opportunity.Name',
            'Opportunity.Brand_Name__c',
            'Opportunity.Owner.Email',
            'Opportunity.IsDownsellCaseCreated__c',
            'Opportunity.Type',
            'Opportunity.isFedRamp__c',
            'Opportunity.isTermination__c',
            'Opportunity.Tier_Name__c',
            'Opportunity.Account.Billing_ID__c',
            'Opportunity.Account.RC_Account_Status__c',
            'Opportunity.Account.EnabledLBO__c',
            'Opportunity.Account.Name',
            'Opportunity.Account.BillingStreet',
            'Opportunity.Account.BillingCity',
            'Opportunity.Account.BillingState',
            'Opportunity.Account.BillingPostalCode',
            'Opportunity.Account.BillingCountry',
            'Opportunity.Account.Phone',
            'Opportunity.Account.Partner_ID__c',
            'Opportunity.Account.Partner_Type__c',
            'Opportunity.Account.RC_User_ID__c',
            'Opportunity.Account.RC_Brand__c',
            'Opportunity.Account.Active_Sales_Agreement__c',
            'Opportunity.Account.Master_Account__c',
            'Opportunity.Account.Partner_Account__c',
            'Opportunity.Account.IsMultiProductTechnicalAccount__c',
            'Opportunity.Account.Id',
            'Opportunity.AccountId',
            'Opportunity.StageName',
            'Opportunity.isContractsSynced__c',
            'Opportunity.isInvoiceStepCompleted__c',
            'Opportunity.isOrderStepCompleted__c',
            'Opportunity.isDiscountsSynced__c',
            'Opportunity.isRepriceSynced__c',
            'Opportunity.isResyncContractAllowed__c',
            'Opportunity.IsManualProvisionCaseCreated__c',
            'Opportunity.isUpsellStepCompleted__c',
            'Opportunity.isDownsellStepCompleted__c',
            'Opportunity.isUpgradeStepCompleted__c',
            'Opportunity.isLicenseLimitsSynced__c',
            'Opportunity.IsAreaCodeCaseCreated__c',
            'Opportunity.isContractCancelled__c',
            'Opportunity.isMultiproductTechnicalOpportunity__c',
            'Opportunity.isFSCSynced__c',
            'Opportunity.isChargeTermSynced__c',
            'Opportunity.IsSpendingLimitRetrieveStepCompleted__c',
            'Opportunity.OrderDate__c',
            'Opportunity.CW_Primary_Win_Reason__c',
            'Opportunity.CW_Win_Reason_Awards__c',
            'Opportunity.CW_Win_Reason_Features__c',
            'Opportunity.CW_Win_Reason_Savings__c',
            'Opportunity.CW_Win_Reason_Integrations__c',
            'Opportunity.UCaaS_Competitor_s__c',
            'Opportunity.UCaaS_Incumbent_s__c',
            'Opportunity.CC_Competitor_s__c',
            'Opportunity.CC_Incumbent_s__c',
            'Opportunity.NGBS_Sync_Executor_Info__c',
            'Opportunity.isTerminationStepCompleted__c',
            'Opportunity.SyncInfo__c',
            'Opportunity.isSyncedToICB__c',
            'Opportunity.isICBProvisioningComplete__c',
            'Opportunity.Partner_Account__r.Partner_Type__c',
            'Opportunity.MasterOpportunity__c',
            'Opportunity.MasterOpportunity__r',
            'Opportunity.MasterOpportunity__r.OwnerId',
            'Opportunity.isMultiproductTechnicalOpportunity__c',
            'Opportunity.NumberOfOfficeDLs__c',
            'Opportunity.BusinessIdentity__c',
            'QuoteNumber',
            'CurrentService__r.ChargeTerm__c',
            'CurrentService__r.PackageCatalogId__c',
            'CurrentService__r.PackageVersion__c',
            'Free_Service_Credit_Total__c',
            'isPrimary__c',
            'isTermination__c',
            'Opp_Type__c',
            'Enabled_LBO__c',
            'IsSendOrderToNGBS__c',
            'PackageNameNew__c',
            'TotalPrice',
            'FreeShippingTerms__c',
            'Shipping_Option__c',
            'ServiceName__c',
            'Approved_Status__c',
            'RecordTypeId',
            'PaymentMethod__c',
            'Total_MRR_with_Taxes__c',
            'Total_One_Time_with_Taxes__c',
            'Total_One_Time__c',
            'Entitlement_Total_ARR__c',
            'Entitlement_Total_MRR__c',
            'Monthly_Recurring_Revenue__c',
            'ProServ_Status__c',
            'PackageNameOld__c',
            'BillingPackage__c',
            'MasterQuote__c',
            'MasterQuote__r.OpportunityId',
            'MasterQuote__r.AccountId',
            'MasterQuote__r.Enabled_LBO__c',
            'MasterQuote__r.isPrimary__c',
            'BusinessIdentity__c'
        };
    }

    public List<String> getFieldsForSyncWithNGBS() {
        return new List<String>{
            'Package_Info__c',
            'AccountId',
            'InvoiceId__c',
            'CountOfDownsellQLI__c',
            'Account.Billing_ID__c',
            'Account.RC_User_ID__c',
            'Account.Offer_Type__c',
            'Account.Name',
            'Account.ELA_Account_Type__c',
            'Account.RecordTypeId',
            'Account.Payment_Plan__c',
            'Account.Partner_Type__c',
            'Account.Partner_ID__c',
            'Account.Partner_Account__c',
            'Account.Partner_Account__r.NGBS_Partner_ID__c',
            'Account.Account_Payment_Method__c',
            'Account.EnabledLBO__c',
            'Account.Master_Account__c',
            'Account.RC_Account_Status__c',
            'Contact.FirstName',
            'Contact.LastName',
            'Initial_Term_months__c',
            'IsMultiProductTechnicalQuote__c',
            'LBODealDeskProvision__c',
            'Term_months__c',
            'Auto_Renewal__c',
            'Start_Date__c',
            'UpdateContractTerms__c',
            'Upsell_Status__c',
            'OpportunityId',
            'Opportunity.Brand_Name__c',
            'Opportunity.Owner.Email',
            'Opportunity.IsDownsellCaseCreated__c',
            'Opportunity.Type',
            'Opportunity.isFedRamp__c',
            'Opportunity.isTermination__c',
            'Opportunity.Tier_Name__c',
            'Opportunity.Name',
            'QuoteNumber',
            'CurrentService__r.ChargeTerm__c',
            'CurrentService__r.PackageCatalogId__c',
            'CurrentService__r.PackageVersion__c',
            'Free_Service_Credit_Total__c',
            'isPrimary__c',
            'isTermination__c',
            'Opp_Type__c',
            'Enabled_LBO__c',
            'MasterQuote__r.Enabled_LBO__c',
            'IsMultiProductTechnicalQuote__c',
            'IsSendOrderToNGBS__c',
            'PackageNameNew__c',
            'TotalPrice',
            'FreeShippingTerms__c',
            'Shipping_Option__c',
            'ServiceName__c',
            'Approved_Status__c',
            'RecordTypeId',
            'PaymentMethod__c',
            'Total_MRR_with_Taxes__c',
            'Total_One_Time_with_Taxes__c',
            'Total_One_Time__c',
            'Entitlement_Total_ARR__c',
            'Entitlement_Total_MRR__c',
            'Monthly_Recurring_Revenue__c',
            'ProServ_Status__c',
            'PackageNameOld__c',
            'BillingPackage__c',
            'MasterQuote__c',
            'BusinessIdentity__c'
        };
    }

    public List<String> getFieldsForSignUp() {
        List<String> fields = new List<String>{
            'Id',
            'Name',
            'OpportunityId',
            'Opportunity.Brand_Name__c',
            'Opportunity.StageName',
            'Opportunity.Tier_Name__c',
            'Opportunity.Name',
            'CurrencyIsoCode',
            'LastModifiedDate',
            'LastModifiedBy.Name',
            'Approved_Status__c',
            'Status',
            'Upsell_Status__c',
            'QuoteNumber',
            'Start_Date__c',
            'UpdateContractTerms__c',
            'Special_Terms__c',
            'isPrimary__c',
            'AccountId',
            'Account.RC_User_ID__c',
            'Account.Billing_ID__c',
            'Account.Partner_Account__c',
            'Account.NGBS_Partner_ID__c',
            'Account.Partner_ID__c',
            'Account.Partner_Type__c',
            'Account.ELA_Account_Type__c',
            'Account.BillingCountry',
            'Account.RecordTypeId',
            'Initial_Term_months__c',
            'Initial_Term_POC__c',
            'Package_Info__c',
            'RecordTypeId',
            'RecordType.Name',
            'QuoteType__c',
            'Pricebook2.AllowedRecordType__c',
            'Credit_Amount__c',
            'AreaCode__c',
            'Payment_Plan__c',
            'Free_Service_Credit_Total__c',
            'ProServ_Status__c',
            'IsQuoteHasErrors__c',
            'Auto_Renewal__c',
            'Term_months__c',
            'Shipping_Option__c',
            'ServiceName__c',
            'Enabled_LBO__c',
            'Free_Service_Taxes__c',
            'FreeShippingTerms__c',
            'PaymentMethod__c',
            'Total_MRR_with_Taxes__c',
            'Total_One_Time_with_Taxes__c',
            'BusinessIdentity__c',
            'Total_ARR_with_Taxes__c',
            'Brand__c',
            'Payment_Period__c',
            'Entitlement_Total_ARR__c',
            'Entitlement_Total_MRR__c',
            'TotalProjectHoursQuoted__c',
            'PSProjectComplexity__c',
            'ProServ_Forecasted_Close_Date__c',
            'MasterQuote__c',
            'MasterQuote__r.QuoteType__c',
            'MasterQuote__r.Status',
            'MasterQuote__r.OpportunityId',
            'MasterQuote__r.TotalProjectHoursQuoted__c',
            'MasterQuote__r.PSProjectComplexity__c',
            'MasterQuote__r.ProServ_Forecasted_Close_Date__c',
            'MasterQuote__r.Package_Info__c',
            'MasterQuote__r.IsMultiProductTechnicalQuote__c',
            'IsMultiProductTechnicalQuote__c',
            'PackageNameOld__c',
            'BillingPackage__c',
            'DataRetentionDuration__c'
        };
        fields.addAll(getRelatedAreaCodeFields());
        return fields;
    }

    public List<String> getFieldsForClose() {
        return new List<String>{
            'Id',
            'isPrimary__c',
            'Approved_Status__c',
            'Enabled_LBO__c',
            'LastModifiedDate',
            'ProServSalesRep__c',
            'Package_Info__c',
            'AreaCode__c',
            'Enabled_LBO__c',
            'IsNewGOAEnabled__c',
            'IsMultiProductTechnicalQuote__c',
            'ProServ_Status__c',
            'LastModifiedBy.Id',
            'LastModifiedBy.Name',
            'Upsell_Status__c',
            'Total_Number_of_Digital_Lines__c',
            'InvalidDiscountedPhonesQuantity__c',
            'InvalidGlobalOfficePhonesQuantity__c',
            'InvalidLimitedExtensionPhonesQuantity__c',
            'IsQuoteHasErrors__c',
            'Brand__c',
            'Payment_Plan__c',
            'Initial_Term_months__c',
            'Auto_Renewal__c',
            'Term_months__c',
            'Invalid_GO_LE_Phones_Quantity__c',
            'Quote_is_Invalid__c',
            'QuoteType__c',
            'Status',
            'ServiceName__c',
            'PackageNameOld__c',
            'BillingPackage__c',
            'Products__c',
            'PriceBook2.IsActive',
            'PriceBook2.Service__c',
            'PriceBook2.Tier_ID__c',
            'PriceBook2.AllowedRecordType__c',
            'PriceBook2.Plan__c',
            'Pricebook2.Brand__c',
            'Pricebook2.Brand__r.Name',
            'AccountId',
            'Account.Payment_Method__c',
            'Account.Billing_ID__c',
            'Account.RC_User_ID__c',
            'Account.RC_Account_Status__c',
            'Account.Active_Sales_Agreement__c',
            'Account.RC_Account_Status__c',
            'Account.RC_Tier_ID__c',
            'Account.Offer_Type__c',
            'Account.RecordTypeId',
            'Opp_Type__c',
            'OpportunityId',
            'Opportunity.Brand_Name__c',
            'Opportunity.Is_Billing_Opportunity__c',
            'Opportunity.Tier_Name__c',
            'Opportunity.BusinessIdentity__c',
            'Opportunity.Type',
            'RecordTypeId',
            'RecordType.DeveloperName',
            'IsNewGOAEnabled__c',
            'PaymentMethod__c',
            'Total_MRR_with_Taxes__c',
            'Total_One_Time_with_Taxes__c',
            'CurrencyIsoCode',
            'Total_ARR_with_Taxes__c',
            'Payment_Period__c',
            'Entitlement_Total_ARR__c',
            'Entitlement_Total_MRR__c',
            'BusinessIdentity__c',
            'IsMultiProductTechnicalQuote__c',
            'TotalProjectHoursQuoted__c',
            'PSProjectComplexity__c',
            'ProServ_Forecasted_Close_Date__c',
            'MasterQuote__c',
            'Delta_MRR__c'
        };
    }

    public List<String> getFieldsWithOpportunity() {
        return new List<String>{
            'Opportunity.StageName'
        };
    }

    public List<String> getFieldsWithMasterOpportunity() {
        return new List<String>{
            'Opportunity.MasterOpportunity__c',
            'IsMultiProductTechnicalQuote__c',
            'ServiceName__c',
            'Credit_Amount__c',
            'Free_Service_Credit_Total__c',
            'MasterQuote__c',
            'Free_Service_Taxes__c',
            'Delta_MRR__c',
            'TotalQuoteSummary__c',
            'IsTermination__c'
        };
    }

    public List<String> getFieldsWithMasterOpportunityUB() {
        return new List<String>{
            'IsMultiProductTechnicalQuote__c',
            'ServiceName__c',
            'Credit_Amount__c',
            'Free_Service_Credit_Total__c',
            'MasterQuote__c',
            'Free_Service_Taxes__c',
            'Delta_MRR__c',
            'TotalQuoteSummary__c',
            'Total_First_Year_Cost__c',
            'IsTermination__c'
        };
    }

    public Set<String> getCloseWizardQuoteFieldsToSelect() {
        return new Set<String> {
            'Id', 'RecordTypeId', 'Opportunity.StageName','isPrimary__c', 'Upsell_Status__c',
            'Opportunity.Name', 'Opportunity.Parent_Order__c', 'Opportunity.Id', 'LastModifiedDate',
            'Status', 'QuoteType__c', 'Opportunity.ConfirmAndClose__c', 'Opportunity.Type', 'OpportunityId', 'Pricebook2.AllowedRecordType__c', 'Delta_MRR__c'
        };
    }

    public Set<String> getCloseWizardQliFieldsToSelect() {
        return new Set<String> {
            'Quantity', 'Zero_Quantity__c', 'NewQuantity__c',
            'Discount_type__c', 'Discount_number__c',
            'Entitlement__r.DisplayQuantity__c',
                'Entitlement__r.Discount_Type__c', 'Entitlement__r.Discount__c',
                'Delta_MRR__c'
        };
    }

    public List<String> getFieldsForPdfTemplate() {
        return new List<String>{
            'Id',
            'Approved_Status__c',
            'QuoteType__c',
            'OpportunityId',
            'InvoiceId__c',
            'isPrimary__c',
            'Brand__c',
            'Opp_Type__c',
            'IsQuoteHasErrors__c',
            'Upsell_Status__c',
            'Pricebook2.Plan__c',
            'Pricebook2.Service__c',
            'Package_Info__c',
            'Products__c',
            'Enabled_LBO__c',
            'LBODealDeskProvision__c',
            'IsSendOrderToNGBS__c',
            'LastModifiedDate',
            'Note_To_Customer__c',
            'RecordType.Name',
            'MultipleShippingLocations__c',
            'Account.Billing_ID__c',
            'Account.RC_User_ID__c',
            'Account.RC_Account_Status__c',
            'Account.Active_Sales_Agreement__c',
            'Account.Master_Account__c',
            'Account.BillingCountry',
            'Account.Offer_Type__c',
            'Account.Partner_ID__c',
            'Account.Partner_Type__c',
            'Opportunity.EstimatedProfessionalServices12Month__c',
            'Opportunity.Is_Billing_Opportunity__c',
            'Opportunity.RecordType.Name',
            'Opportunity.Brand_Name__c',
            'Opportunity.IsDocusignCLMEnabled__c',
            'Opportunity.Tier_Name__c',
            'Total_One_Time__c',
            'Total_MRR_New__c',
            'Entitlement_Total_MRR__c',
            'Opportunity.Type',
            'ProServ_Status__c',
            'RecordTypeId',
            'ServiceName__c'
        };
    }

    public List<String> getFieldsForPackageTrigger() {
        return new List<String>{
            'Id',
            'Account__c',
            'AccountId',
            'Enabled_LBO__c',
            'Account.EnabledLBO__c',
            'Account.Billing_ID__c',
            'IsShowSmokeModifiedMessage__c',
            'Status',
            'RecordTypeId',
            'Upsell_Status__c'
        };
    }

    public List<String> getFieldsForQuoteService(){
        List<String> fields = new List<String>{
            'Id',
            'Name',
            'Upsell_Status__c',
            'Opp_Type__c',
            'Approved_Status__c',
            'Approval_Type__c',
            'isPrimary__c',
            'IsPRMQuote__c',
            'IsDeselected__c',
            'AverageDiscount__c',
            'CreatedDate',
            'ParentQuote__r.Initial_Term_months__c',
            'ParentQuote__r.Auto_Renewal__c',
            'ParentQuote__r.Term_months__c',
            'ParentQuote__r.Start_Date__c',
            'ParentQuote__r.End_Date__c',
            'ParentQuote__r.Opportunity.Id',
            'Account.Id',
            'Account.Name',
            'QuotePosition__c',
            'Status',
            'Package_Info__c',
            'Account.BillingState',
            'Account.BillingCity',
            'Account.BillingCountry',
            'Account.BillingPostalCode',
            'Account.BillingStreet',
            'Account.Phone',
            'Account.Tax_Exempt__c',
            'Account.Active_Sales_Agreement__c',
            'Account.Active_Sales_Agreement__r.Initial_Term_months__c',
            'Account.Active_Sales_Agreement__r.Auto_Renewal__c',
            'Account.Active_Sales_Agreement__r.Term_months__c',
            'Account.RC_Account_Status__c',
            'Account.VideoProvider__c',
            'Account.Master_Account__c',
            'Account.Payment_Method__c',
            'Account.Active_Invoice_Approval__c',
            'Account.Billing_ID__c',
            'Account.inContact_account_ID__c',
            'Account.NumberOfEmployees',
            'Account.Master_Account__r.Billing_ID__c',
            'Account.Master_Account__r.Active_Sales_Agreement__r.Initial_Term_months__c',
            'Account.Master_Account__r.Active_Sales_Agreement__r.Auto_Renewal__c',
            'Account.Master_Account__r.Active_Sales_Agreement__r.Term_months__c',
            'Account.Master_Account__r.Active_Sales_Agreement__r.Start_Date__c',
            'Account.Master_Account__r.Active_Sales_Agreement__r.End_Date__c',
            'Account.Master_Account__r.Active_Sales_Agreement__r.Opportunity.Id',
            'Account.Master_Account__r.Active_Sales_Agreement__r.Opportunity.RecordType.Name',
            'Account.Account_Payment_Method__c',
            'Account.ELA_Account_Type__c',
            'Account.Industry',
            'Account.Segment__c',
            'Account.Sector__c',
            'Account.Service_Type__c',
            'Account.Partner_Contact__c',
            'QuoteType__c',
            'QuoteNumber',
            'ExpirationDate',
            'Initial_Term_months__c',
            'Initial_Term_POC__c',
            'Term_months__c',
            'Auto_Renewal__c',
            'Start_Date__c',
            'End_Date__c',
            'UpdateContractTerms__c',
            'Special_Terms__c',
            'JustificationandDescription__c',
            'Special_TOS_Approval__c',
            'RecordTypeId',
            'RecordType.Name',
            'ProServ_Status__c',
            'Credit_Amount__c',
            'Free_Service_Taxes__c',
            'NGBSTaxesAdded__c',
            'Delta_MRR__c',
            'Pricebook2Id',
            'Pricebook2.AllowedRecordType__c',
            'IsQuoteHasErrors__c',
            'IsNewGOAEnabled__c',
            'Level_1_Approver__r.Name',
            'Level_1_Approver__r.Hierarchy_Role__c',
            'Level_1_Approver__r.Title',
            'Level_2_Approver__r.Name',
            'Level_2_Approver__r.Hierarchy_Role__c',
            'Level_2_Approver__r.Title',
            'Level_3_Approver__r.Name',
            'Level_3_Approver__r.Hierarchy_Role__c',
            'Level_3_Approver__r.Title',
            'Level_4_Approver__r.Name',
            'Level_4_Approver__r.Hierarchy_Role__c',
            'Level_4_Approver__r.Title',
            'Level_5_Approver__r.Name',
            'Level_5_Approver__r.Hierarchy_Role__c',
            'Level_5_Approver__r.Title',
            'Level_6_Approver__r.Name',
            'Level_6_Approver__r.Hierarchy_Role__c',
            'Level_6_Approver__r.Title',
            'Level_7_Approver__r.Name',
            'Level_7_Approver__r.Hierarchy_Role__c',
            'Level_7_Approver__r.Title',
            'Level_1_Approver__c',
            'Level_2_Approver__c',
            'Level_3_Approver__c',
            'Level_4_Approver__c',
            'Level_5_Approver__c',
            'Level_6_Approver__c',
            'Level_7_Approver__c',
            'Opportunity.StageName',
            'Opportunity.OwnerId',
            'Opportunity.Owner.Name',
            'Opportunity.Owner.Email',
            'Opportunity.Owner.SegmentPicklist__c',
            'Opportunity.Special_TOS_Approval__c',
            'CreatedById',
            'Opportunity.Tier_Name__c',
            'Opportunity.IsClosed',
            'Opportunity.CurrencyIsoCode',
            'Opportunity.HasActiveAgreement__c',
            'Account.CurrencyIsoCode',
            'OwnerId',
            'Fax_Vanity_Number__c',
            'Opportunity.CustomerConfirmation__c',
            'Opportunity.ProvisioningDetails__c',
            'ServiceName__c',
            'Ship_Attention_To__c',
            'Shipping_Country__c',
            'Shipping_City__c',
            'Shipping_State__c',
            'Shipping_Address_Line__c',
            'Shipping_Postal_Code__c',
            'Shipping_Additional_Address_Line__c',
            'Shipping_Customer_Name__c',
            'Shipping_Option__c',
            'MultipleShippingLocations__c',
            'Contact.Name',
            'Free_Service_Credit_Total__c',
            'NeedTaxesReestimation__c',
            'Opportunity.Brand_Name__c',
            'Brand__c',
            'Enabled_LBO__c',
            'LBODealDeskProvision__c',
            'IsShowSmokeModifiedMessage__c',
            'IsSendOrderToNGBS__c',
            'BusinessIdentity__c',
            'Free_Service_Credit_Total__c',
            'NeedTaxesReestimation__c',
            'Opportunity.SelfProvisioned__c',
            'Opportunity.IsDocusignCLMEnabled__c',
            'Opportunity.Is_Billing_Opportunity__c',
            'Opportunity.RecordType.Name',
            'Opportunity.NumberToBeRCMainNumber__c',
            'Opportunity.NumberToBeCCNumber__c',
            'Opportunity.isTermination__c',
            'FSC_Full_MRS_Calculation__c',
            'Note_To_Customer__c',
            'FreeShippingTerms__c',
            'PaymentMethod__c',
            'BusinessIdentity__c',
            'Total_Number_of_Digital_Lines__c',
            'TargetPriceContactCenterARR__c',
            'OverallDiscretion__c',
            'IsMultiProductTechnicalQuote__c',
            'ProServ_Status__c',
            'MasterQuote__c',
            'DataRetentionDuration__c',
            'DownsellApprover__c',
            'ProServ_Details__c',
            'ProservLevelApprover__c',
            'Opportunity.Partner_Account_Name__c',
            'Opportunity.Account.Owner.Name',
            'Opportunity.Total_ARR__c',
            'Opportunity.Total_MRR__c',
            'Opportunity.Total_Contract_Value__c',
            'Opportunity.CloseDate'
        };
        fields.addAll(getRelatedAreaCodeFields());
        return fields;
    }

    public List<String> getFieldsForCopy() {
        return new List<String>{
            'Id',
            'Status',
            'ServiceName__c',
            'Package_Info__c',
            'Term_months__c',
            'Initial_Term_months__c',
            'CreatedDate',
            'QuoteType__c',
            'Start_Date__c',
            'End_Date__c',
            'AreaCode__c',
            'FaxAreaCode__c',
            'ContactId',
            'Auto_Renewal__c',
            'Upsell_Status__c',
            'Enabled_LBO__c',
            'MasterQuote__c',
            'isPrimary__c',
            'IsQuoteHasErrors__c',
            'Special_Terms__c',
            'Credit_Amount__c',
            'Free_Service_Taxes__c',
            'FreeShippingTerms__c',
            'TotalProjectHoursQuoted__c',
            'PSProjectComplexity__c',
            'ProServ_Forecasted_Close_Date__c',
            'Account.Id',
            'Account.IsMultiProductTechnicalAccount__c',
            'OpportunityId',
            'MasterQuote__r.Status',
            'MasterQuote__r.End_Date__c',
            'MasterQuote__r.QuoteType__c',
            'MasterQuote__r.Start_Date__c',
            'MasterQuote__r.CreatedDate',
            'MasterQuote__r.Package_Info__c',
            'MasterQuote__r.Enabled_LBO__c',
            'MasterQuote__r.Term_months__c',
            'MasterQuote__r.Initial_Term_months__c',
            'MasterQuote__r.AreaCode__c',
            'MasterQuote__r.FaxAreaCode__c',
            'MasterQuote__r.ContactId',
            'MasterQuote__r.Auto_Renewal__c',
            'MasterQuote__r.Account.RC_Signup_Date__c',
            'MasterQuote__r.Upsell_Status__c',
            'MasterQuote__r.isPrimary__c',
            'MasterQuote__r.IsQuoteHasErrors__c',
            'MasterQuote__r.Special_Terms__c',
            'MasterQuote__r.Credit_Amount__c',
            'MasterQuote__r.Free_Service_Taxes__c',
            'MasterQuote__r.FreeShippingTerms__c',
            'MasterQuote__r.Account.Offer_Type__c',
            'MasterQuote__r.Account.RC_Account_Status__c',
            'MasterQuote__r.Account.Billing_ID__c',
            'MasterQuote__r.TotalProjectHoursQuoted__c',
            'MasterQuote__r.PSProjectComplexity__c',
            'MasterQuote__r.ProServ_Forecasted_Close_Date__c'
        };
    }

    public List<String> getOpportunityFields() {
        return new List<String>{
            'Opportunity.BusinessIdentity__c'
        };
    }

    public List<String> getFieldsForQuoteLineItemTrigger() {
        return new List<String>{
            'Id',
            'Total_Number_of_Digital_Lines__c',
            'Entitlement_Rental_Phones_Quantity__c',
            'isPrimary__c',
            'InvalidDiscountedPhonesQuantity__c',
            'Invalid_GO_LE_Phones_Quantity__c',
            'InvalidLimitedExtensionPhonesQuantity__c',
            'Opportunity.RecordTypeId',
            'Opportunity.BusinessIdentity__c',
            'Upsell_Status__c',
            'PackageNameOld__c',
            'BillingPackage__c',
            'Pricebook2.Plan__c',
            'Pricebook2.Brand__r.Name',
            'AreaCode__c',
            'FaxAreaCode__c',
            'AreaCode__r.Name',
            'FaxAreaCode__r.Name',
            'RecordTypeId',
            'OpportunityId',
            'Invalid_Number_of_Vanity_Setups__c',
            'Invalid_Number_of_800_Setups__c',
            'Invalid_Number_of_Int_TF_Setups__c',
            'Required_Area_Codes_are_empty__c',
            'Account.Number_of_DL_s__c',
            'Approved_Status__c',
            'Special_Terms__c',
            'FreeShippingTerms__c',
            'Account.Active_Sales_Agreement__c',
            'Account_Number_of_Lines__c',
            'PriceBook2.Service__c',
            'Main_Vanity_Number__c',
            'Fax_Vanity_Number__c',
            'Package_Info__c',
            'Account.Billing_ID__c',
            'Billing_Zip_Postal_Code__c',
            'Billing_City__c',
            'Billing_Country__c',
            'Billing_State_Province__c',
            'Billing_Street__c',
            'Account.BillingPostalCode',
            'Account.BillingCity',
            'Account.BillingCountry',
            'Account.BillingState',
            'Account.BillingStreet',
            'Products__c',
            'Account.RC_Account_Status__c',
            'Account.Offer_Type__c',
            'Account.RC_User_ID__c',
            'IsNewGOAEnabled__c',
            'Entitlement_Global_Phones_Quantity__c',
            'Entitlement_Limited_Phones_Quantity__c',
            'Entitlement_Common_Phones_Quantity__c',
            'Credit_Amount__c',
            'Estimated_Taxes_Request_Failed__c',
            'ProServSalesRep__c',
            'IsMultiProductTechnicalQuote__c',
            'MasterQuote__r.Upsell_Status__c'
        };
    }

    public List<Schema.SObjectField> getFieldsForContractPopulation() {
        return new List<Schema.SObjectField> {
            Quote.Id,
            Quote.AccountId,
            Quote.Account__c,
            Quote.Status,
            Quote.Initial_Term_months__c,
            Quote.Term_months__c,
            Quote.Auto_Renewal__c,
            Quote.Start_Date__c,
            Quote.End_Date__c,
            Quote.UpdateContractTerms__c,
            Quote.Package_Info__c
        };
    }

    public List<String> getRelatedAccountFields() {
        return new List<String>{
            'Account.Name',
            'Account__r.Name',
            'Account.Master_Account__c'
        };
    }

    public List<String> getFieldsForDqGoa() {
        return new List<String>{
            'Account.Offer_Type__c',
            'Account.RC_Account_Status__c',
            'Account.Billing_ID__c',
            'Auto_Renewal__c',
            'FreeShippingTerms__c',
            'Shipping_Option__c',
            'OpportunityId',
            'Initial_Term_months__c',
            'Term_months__c',
            'Special_Terms__c',
            'Package_Info__c',
            'Opportunity.Brand_Name__c',
            'Opportunity.Segment_Name__c',
            'Opportunity.RecordType.Name',
            'Opportunity.Owner.Region__c',
            'Opportunity.Owner.SegmentPicklist__c',
            'Opportunity.Owner.Sub_Region__c',
            'AverageDiscount__c',
            'OverallDiscretion__c',
            'Total_MRR_New__c',
            'Package_Info__c',
            'Opportunity.Tier_Name__c',
            'MasterQuote__c',
            'ServiceName__c',
            'IsMultiProductTechnicalQuote__c',
            'IsPRMQuote__c'
        };
    }

    public List<Schema.SObjectField> getFieldsForDQSync() {
        return new List<Schema.SObjectField> {
            Quote.Id,
            Quote.OpportunityId,
            Quote.Payment_Plan__c,
            Quote.Term_months__c,
            Quote.Initial_Term_months__c,
            Quote.Special_Terms__c,
            Quote.Total_First_Year_Cost__c,
            Quote.Monthly_Recurring_Revenue__c,
            Quote.Package_Info__c,
            Quote.Total_One_Time__c,
            Quote.Shipping_Option__c,
            Quote.Auto_Renewal__c,
            Quote.OverallDiscretion__c,
            Quote.AverageDiscount__c,
            Quote.Total_MRR_New__c,
            Quote.JustificationandDescription__c,
            Quote.FreeShippingTerms__c,
            Quote.ServiceName__c,
            Quote.MasterQuote__c,
            Quote.IsMultiProductTechnicalQuote__c,
            Quote.IsPRMQuote__c,
            Quote.ProServ_Status__c
        };
    }

    public List<Schema.SObjectField> getFieldsForDQGoaApproval() {
        return new List<Schema.SObjectField> {
            Quote.Id,
            Quote.OpportunityId,
            Quote.Approved_Status__c,
            Quote.Package_Info__c
        };
    }

    public List<String> getRelatedObjectsFieldsForDQSync() {
        return new List<String> {
            'Opportunity.Owner.Email',
            'Opportunity.Tier_Name__c'
        };
    }

    public List<String> getTechnicalQuotesFields() {
        return new List<String> {
            'Id',
            'Name',
            'OpportunityId',
            'Opportunity.MasterOpportunity__c',
            'Opportunity.Tier_Name__c',
            'Package_Info__c',
            'Opportunity.Type',
            'Opportunity.isSyncedToICB__c',
            'Opportunity.isICBProvisioningComplete__c',
            'Opportunity.Parent_Order__c',
            'Delta_MRR__c',
            'Account.Billing_ID__c',
            'IsDeselected__c',
            'isPrimary__c',
            'IsMultiProductTechnicalQuote__c',
            'PackageNameOld__c',
            'BillingPackage__c',
            'RecordTypeId',
            'RecordType.Name',
            'ServiceName__c',
            'BillingPackage__c',
            'MasterQuote__c'
        };
    }

    public List<String> getRelatedAccountFieldsForTechQuotes() {
        return new List<String> {
            'Account.BillingState',
            'Account.BillingCity',
            'Account.BillingCountry',
            'Account.BillingPostalCode',
            'Account.BillingStreet',
            'Account.Billing_ID__c'
        };
    }

    @TestVisible
    private Set<String> getFieldsForCreateServiceInfoBatch() {
        return new Set<String> {
            'Id',
            'isTermination__c',
            'Package_Info__c',
            'RecordTypeId',
            'AccountId',
            'Account.Billing_ID__c',
            'Account__r.Billing_ID__c',
            'OpportunityId',
            'Opportunity.StageName',
            'Opportunity.NGBS_Sync_Executor_Info__c',
            'Opportunity.OrderDate__c',
            'Opportunity.isContractsSynced__c',
            'Opportunity.isDiscountsSynced__c',
            'Opportunity.isRepriceSynced__c',
            'Opportunity.isChargeTermSynced__c',
            'Opportunity.isLicenseLimitsSynced__c',
            'Opportunity.isFSCSynced__c',
            'Opportunity.isUpgradeStepCompleted__c',
            'Opportunity.isUpsellStepCompleted__c',
            'Opportunity.isDownsellStepCompleted__c',
            'Opportunity.isOrderStepCompleted__c',
            'Opportunity.isInvoiceStepCompleted__c',
            'Opportunity.isTerminationStepCompleted__c',
            'Opportunity.isSyncedToICB__c',
            'Opportunity.isICBProvisioningComplete__c',
            'Opportunity.SyncInfo__c'
        };
    }

    public List<String> getCalculatedFieldsForUQT() {
        return new List<String>{
            // required for logic
            'IsMultiProductTechnicalQuote__c',
            'ServiceName__c',

            // calculated fields on backend
            'Delta_MRR__c',
            'Delta_ARR__c',
            'Total_First_Year_Cost__c',
            'TotalQuoteSummary__c'
        };
    }

    public List<String> getFieldsForUQT() {
        List<String> fields = new List<String>{
            // Basic Quote Information
            'Id',
            'Name',
            'QuoteNumber',
            'ExpirationDate',
            'Status',
            'QuoteType__c',
            'QuotePosition__c',
            'Package_Info__c',
            'ServiceName__c',
            'BusinessIdentity__c',
            'Brand__c',
            'CreatedDate',
            'CreatedById',
            'OwnerId',
            'RecordTypeId',
            'RecordType.Name',

            // Quote Status & Flags
            'Upsell_Status__c',
            'Opp_Type__c',
            'Approved_Status__c',
            'Approval_Type__c',
            'isPrimary__c',
            'IsPRMQuote__c',
            'IsDeselected__c',
            'IsQuoteHasErrors__c',
            'IsNewGOAEnabled__c',
            'IsShowSmokeModifiedMessage__c',
            'IsSendOrderToNGBS__c',
            'IsMultiProductTechnicalQuote__c',
            'ProServ_Status__c',
            'ProServ_Details__c',
            'LBODealDeskProvision__c',
            'Enabled_LBO__c',
            'IsTermination__c',

            // Financial Information
            'AverageDiscount__c',
            'Credit_Amount__c',
            'Free_Service_Taxes__c',
            'NGBSTaxesAdded__c',
            'Delta_MRR__c',
            'Delta_ARR__c',
            'Free_Service_Credit_Total__c',
            'NeedTaxesReestimation__c',
            'TargetPriceContactCenterARR__c',
            'OverallDiscretion__c',
            'FSC_Full_MRS_Calculation__c',
            'Total_Number_of_Digital_Lines__c',
            'TotalQuoteSummary__c',

            // Terms & Conditions
            'Initial_Term_months__c',
            'Initial_Term_POC__c',
            'Term_months__c',
            'Auto_Renewal__c',
            'Start_Date__c',
            'End_Date__c',
            'UpdateContractTerms__c',
            'Special_Terms__c',
            'JustificationandDescription__c',
            'Special_TOS_Approval__c',
            'Note_To_Customer__c',
            'FreeShippingTerms__c',
            'PaymentMethod__c',
            'DataRetentionDuration__c',

            // Shipping Information
            'Ship_Attention_To__c',
            'Shipping_Country__c',
            'Shipping_City__c',
            'Shipping_State__c',
            'Shipping_Address_Line__c',
            'Shipping_Postal_Code__c',
            'Shipping_Additional_Address_Line__c',
            'Shipping_Customer_Name__c',
            'Shipping_Option__c',
            'MultipleShippingLocations__c',

            'Fax_Vanity_Number__c',

            // Approver Information
            'Level_1_Approver__c',
            'Level_1_Approver__r.Name',
            'Level_1_Approver__r.Hierarchy_Role__c',
            'Level_1_Approver__r.Title',
            'Level_2_Approver__c',
            'Level_2_Approver__r.Name',
            'Level_2_Approver__r.Hierarchy_Role__c',
            'Level_2_Approver__r.Title',
            'Level_3_Approver__c',
            'Level_3_Approver__r.Name',
            'Level_3_Approver__r.Hierarchy_Role__c',
            'Level_3_Approver__r.Title',
            'Level_4_Approver__c',
            'Level_4_Approver__r.Name',
            'Level_4_Approver__r.Hierarchy_Role__c',
            'Level_4_Approver__r.Title',
            'Level_5_Approver__c',
            'Level_5_Approver__r.Name',
            'Level_5_Approver__r.Hierarchy_Role__c',
            'Level_5_Approver__r.Title',
            'Level_6_Approver__c',
            'Level_6_Approver__r.Name',
            'Level_6_Approver__r.Hierarchy_Role__c',
            'Level_6_Approver__r.Title',
            'Level_7_Approver__c',
            'Level_7_Approver__r.Name',
            'Level_7_Approver__r.Hierarchy_Role__c',
            'Level_7_Approver__r.Title',
            'DownsellApprover__c',
            'ProservLevelApprover__c',

            // Related Records
            'Pricebook2Id',
            'Pricebook2.AllowedRecordType__c',
            'Contact.Name',
            'MasterQuote__c',

            // Parent Quote Information
            'ParentQuote__r.Initial_Term_months__c',
            'ParentQuote__r.Auto_Renewal__c',
            'ParentQuote__r.Term_months__c',
            'ParentQuote__r.Start_Date__c',
            'ParentQuote__r.End_Date__c',
            'ParentQuote__r.Opportunity.Id',

            // Account Information
            'Account.Id',
            'Account.Name',
            'Account.BillingState',
            'Account.BillingCity',
            'Account.BillingCountry',
            'Account.BillingPostalCode',
            'Account.BillingStreet',
            'Account.Phone',
            'Account.Tax_Exempt__c',
            'Account.Active_Sales_Agreement__c',
            'Account.Active_Sales_Agreement__r.Initial_Term_months__c',
            'Account.Active_Sales_Agreement__r.Auto_Renewal__c',
            'Account.Active_Sales_Agreement__r.Term_months__c',
            'Account.RC_Account_Status__c',
            'Account.VideoProvider__c',
            'Account.Master_Account__c',
            'Account.Payment_Method__c',
            'Account.Active_Invoice_Approval__c',
            'Account.Billing_ID__c',
            'Account.inContact_account_ID__c',
            'Account.NumberOfEmployees',
            'Account.CurrencyIsoCode',
            'Account.Account_Payment_Method__c',
            'Account.ELA_Account_Type__c',
            'Account.Industry',
            'Account.Segment__c',
            'Account.Sector__c',
            'Account.Service_Type__c',
            'Account.Partner_Contact__c',

            // Master Account Information
            'Account.Master_Account__r.Billing_ID__c',
            'Account.Master_Account__r.Active_Sales_Agreement__r.Initial_Term_months__c',
            'Account.Master_Account__r.Active_Sales_Agreement__r.Auto_Renewal__c',
            'Account.Master_Account__r.Active_Sales_Agreement__r.Term_months__c',
            'Account.Master_Account__r.Active_Sales_Agreement__r.Start_Date__c',
            'Account.Master_Account__r.Active_Sales_Agreement__r.End_Date__c',
            'Account.Master_Account__r.Active_Sales_Agreement__r.Opportunity.Id',
            'Account.Master_Account__r.Active_Sales_Agreement__r.Opportunity.RecordType.Name',

            // Opportunity Information
            'Opportunity.StageName',
            'Opportunity.OwnerId',
            'Opportunity.Owner.Name',
            'Opportunity.Owner.Email',
            'Opportunity.Owner.SegmentPicklist__c',
            'Opportunity.Special_TOS_Approval__c',
            'Opportunity.Tier_Name__c',
            'Opportunity.IsClosed',
            'Opportunity.CurrencyIsoCode',
            'Opportunity.HasActiveAgreement__c',
            'Opportunity.CustomerConfirmation__c',
            'Opportunity.ProvisioningDetails__c',
            'Opportunity.Brand_Name__c',
            'Opportunity.SelfProvisioned__c',
            'Opportunity.IsDocusignCLMEnabled__c',
            'Opportunity.Is_Billing_Opportunity__c',
            'Opportunity.RecordType.Name',
            'Opportunity.NumberToBeRCMainNumber__c',
            'Opportunity.NumberToBeCCNumber__c',
            'Opportunity.isTermination__c',
            'Opportunity.Contact_Center_MRR__c',
            'Opportunity.CreatedDate',
            'Opportunity.Name',
            'Opportunity.Type'
        };
        // Add related area code fields
        fields.addAll(getRelatedAreaCodeFields());
        return fields;
    }

    public List<String> getQuoteApprovalsInfoFields() {
        return new List<String>{
            'Approved_Status__c',
            'Approval_Type__c',
            'Package_Info__c',
            'DownsellApprover__c',
            'ProservLevelApprover__c',
            'Level_1_Approver__c',
            'Level_1_Approver__r.Name',
            'Level_1_Approver__r.Hierarchy_Role__c',
            'Level_1_Approver__r.Title',
            'Level_2_Approver__c',
            'Level_2_Approver__r.Name',
            'Level_2_Approver__r.Hierarchy_Role__c',
            'Level_2_Approver__r.Title',
            'Level_3_Approver__c',
            'Level_3_Approver__r.Name',
            'Level_3_Approver__r.Hierarchy_Role__c',
            'Level_3_Approver__r.Title',
            'Level_4_Approver__c',
            'Level_4_Approver__r.Name',
            'Level_4_Approver__r.Hierarchy_Role__c',
            'Level_4_Approver__r.Title',
            'Level_5_Approver__c',
            'Level_5_Approver__r.Name',
            'Level_5_Approver__r.Hierarchy_Role__c',
            'Level_5_Approver__r.Title',
            'Level_6_Approver__c',
            'Level_6_Approver__r.Name',
            'Level_6_Approver__r.Hierarchy_Role__c',
            'Level_6_Approver__r.Title',
            'Level_7_Approver__c',
            'Level_7_Approver__r.Name',
            'Level_7_Approver__r.Hierarchy_Role__c',
            'Level_7_Approver__r.Title'
        };
    }

    public List<String> getPopulateAvailableApprovalActionsFields() {
        return new List<String>{
            'Id',
            'QuoteType__c',
            'CreatedById',
            'Opportunity.StageName',
            'Opportunity.OwnerId',
            'IsPRMQuote__c'
        };
    }

    public List<String> getFieldsForOrderCreationProcess() {
        return new List<String>(FIELDS_ORDER_CREATION_PROCESS);
    }

    public QueryFactory selectQuotes() {
        return newQueryFactory()
            .setFactoryName('selectQuotes')
            .selectFields(getFieldList());
    }

    public QueryFactory selectQuotesForPrimaryProcess(Id opportunityId, Id quoteId) {
        return newQueryFactory()
            .setFactoryName('selectQuotesForPrimaryProcess')
            .selectFields(getFieldList())
            .setCondition('(OpportunityId = :bind0 AND IsMultiProductTechnicalQuote__c = false) OR MasterQuote__c = :bind1')
            .setQueryBindings(new List<Object>{opportunityId, quoteId});
    }

    public QueryFactory selectQuoteForQuotingToolItemsSync(Object binding) {
        return newQueryFactory()
            .setFactoryName('selectQuoteForQuotingToolItemsSync')
            .selectFields(getFieldsForQuotingToolItemsSync())
            .setCondition('Id = :bind0')
            .setQueryBindings(binding)
            .setLimit(1);
    }

    public QueryFactory selectorQuotesAndQlisForCloseWizardByOppId(Id oppId) {
        return selectAllQuotesForAccountByOppId(oppId)
                .withoutSelectorFieldsIncluded()
                .selectFields(getCloseWizardQuoteFieldsToSelect())
                .subselect(
                    new QuoteLineItemSelector()
                    .selectQuoteLineItems()
                    .selectFields(getCloseWizardQliFieldsToSelect())
                );
    }

    public QueryFactory selectorQuotesAndQlisForCloseWizardByOpportunityId(Id oppId) {
        return newQueryFactory()
            .setFactoryName('selectorQuotesAndQlisForCloseWizardByOpportunityId')
            .withoutSelectorFieldsIncluded()
            .selectFields(getCloseWizardQuoteFieldsToSelect())
            .subselect(
                new QuoteLineItemSelector()
                .selectQuoteLineItems()
                .selectFields(getCloseWizardQliFieldsToSelect())
            )
            .setCondition('OpportunityId = :bind0')
            .setQueryBindings(new List<Object>{ oppId });
    }
    
    public QueryFactory selectAllQuotesForAccountByOppId(Id oppId) {
        return newQueryFactory()
            .setFactoryName('selectAllQuotesForAccountByOppId')
            .selectFields(getDefaultFieldList())
            .setCondition('Account__c IN (SELECT AccountId FROM Opportunity WHERE Id = :bind0)')
            .setQueryBindings(new List<Object> {oppId});
    }

    public QueryFactory selectActiveQuotesWithCancelledAccountStatus() {
        return newQueryFactory()
            .setFactoryName('SelectActiveQuoteWithCancelledAccountStatus')
            .selectFields(getFieldList())
            .withoutSelectorOrderByIncluded()
            .setCondition('Status = \'' + QuoteHelper.QUOTE_STATUS_ACTIVE + '\' AND Account__r.RC_Account_Status__c = \'Canceled\'');
    }

    public QueryFactory selectActiveQuoteFromAccount(List<Schema.SObjectField> fieldList, Id accountId) {
        return newQueryFactory()
            .setFactoryName('SelectActiveQuoteFromAccount')
            .selectFields(fieldList)
            .withoutSelectorOrderByIncluded()
            .setCondition('Status = \'' + QuoteHelper.QUOTE_STATUS_ACTIVE + '\' AND Account__c = \'' + accountId + '\'')
            .setLimit(2);
    }

    public QueryFactory selectQuotesForAccount(Set<Id> accountIdSet) {
        return newQueryFactory()
            .setFactoryName('selectQuotesForAccount')
            .selectFields(getFieldList())
            .setCondition('AccountId IN :bind0 OR Account__c IN :bind0')
            .setQueryBindings(new List<Object> {accountIdSet});
    }

    public QueryFactory selectQuotesWithOpportunityForAccount(Set<Id> accountIdSet) {
        return newQueryFactory()
            .setFactoryName('selectQuotesWithOpportunityForAccount')
            .selectFields(getFieldsWithOpportunity())
            .setCondition('AccountId IN :bind0 OR Account__c IN :bind0')
            .setQueryBindings(new List<Object> {accountIdSet});
    }

    public QueryFactory selectQuotesWithOpportunityForAccountExcept(Set<Id> accountIdSet, Set<Id> excludeOpportunityIds) {
        return newQueryFactory()
            .setFactoryName('selectQuotesWithOpportunityForAccount')
            .selectFields(getFieldsWithOpportunity())
            .setCondition('(AccountId IN :bind0 OR Account__c IN :bind0) AND OpportunityId NOT IN :bind1')
            .setQueryBindings(new List<Object> {accountIdSet, excludeOpportunityIds});
    }

    public QueryFactory selectQuotesByAccountAndOpportunity(Set<Id> accountIdSet, Set<Id> opportunityIdSet) {
        return newQueryFactory()
            .setFactoryName('selectQuotesByAccountAndOpportunity')
            .selectFields(getFieldList())
            .setCondition(
                'OpportunityId IN :bind1 OR (AccountId IN :bind0 OR Account__c IN :bind0)'
            )
            .setQueryBindings(new List<Object>{ accountIdSet, opportunityIdSet });
    }

    public QueryFactory selectOpenBillingQuotesForAccount(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectOpenBillingQuotesForAccount')
            .selectFields(getFieldList())
            .withoutSelectorOrderByIncluded()
            .setCondition('Account__c IN :bind0 AND Opportunity.StageName != '
                + '\'' + OpportunityHelper.STAGE_NAME_CLOSED_WON + '\''
                + ' AND Opportunity.StageName != '
                + '\'' + OpportunityHelper.STAGE_NAME_DOWNGRADED + '\''
                + ' AND RecordTypeId = '
                + '\'' + QuoteHelper.RT_ID_BILLING + '\''
                + ' AND QuoteType__c != '
                + '\'' + QuoteHelper.QUOTE_TYPE_AGREEMENT + '\''
                + ' AND Quote_is_Invalid__c != true')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectQuoteForSyncWithNGBSByQuoteId(Id quoteId) {
        return newQueryFactory()
            .setFactoryName('selectQuoteForSyncWithNGBSByQuoteId')
            .selectFields(getFieldsForSyncWithNGBSMultiProduct())
            .subselect(new QuoteLineItemSelector().selectQuoteLineItemsForSyncWithNGBS())
            .subselect(new ApprovalSelector().selectCreditLimitIncreaseApproved())
            .subselect(new ServiceInfoSelector().selectServiceInfo())
            .withoutSelectorOrderByIncluded()
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object> { quoteId });
    }

    public QueryFactory selectCCLegacyQuoteByOppId(Object oppId) {
        List<Object> bindings = new List<Object>{oppId, QuoteHelper.RT_ID_CC};
        return newQueryFactory()
            .setFactoryName('selectCCLegacyQuoteByOppId')
            .selectFields(getFieldList())
            .subselect(new QuoteLineItemSelector().selectQuoteLineItemsForQuoteService())
            .withoutSelectorOrderByIncluded()
            .setCondition('OpportunityId =:bind0 AND isPrimary__c = false AND RecordTypeId =:bind1')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectProServLegacyQuotesByOppId(Object oppId) {
        return newQueryFactory()
            .setFactoryName('selectProServLegacyQuotesByOppId')
            .selectFields(getFieldList())
            .subselect(new QuoteLineItemSelector().selectQuoteLineItemsForQuoteService())
            .withoutSelectorOrderByIncluded()
            .setCondition('OpportunityId =:bind0 AND (RecordTypeId = ' + '\'' + QuoteHelper.RT_ID_CC_PROSERV + '\'' + ' OR RecordTypeId = ' + '\'' + QuoteHelper.RT_ID_PROSERV + '\'' + ')')
            .setQueryBindings(new List<Object>{oppId});
    }

    public QueryFactory selectQuotesForEndpointStatusServiceByOppId(Set<String> oppIdSet) {
        return newQueryFactory()
            .setFactoryName('selectQuotesForEndpointStatusServiceByOppId')
            .selectFields(getFieldsForSyncWithNGBS())
            .subselect(new QuoteLineItemSelector().
                selectQuoteLineItemsForSyncWithNGBS())
            .withoutSelectorOrderByIncluded()
            .setCondition('Opportunity.Id IN :bind0 AND (isPrimary__c = true OR MasterQuote__r.isPrimary__c = true)')
            .setQueryBindings(new List<Object> { oppIdSet });
    }

    public QueryFactory selectQuotesByOppIds(Object oppIds) {
        return newQueryFactory()
            .setFactoryName('selectQuotesByOppIds')
            .selectFields(getTotalAmountsForOpportunity())
            .subselect(new QuoteLineItemSelector().
                selectQuoteLineItemsForQuoteAmounts())
            .setCondition('OpportunityId IN :bind0')
            .setQueryBindings(new List<Object>{oppIds});
    }

    public QueryFactory selectBillingPrimaryQuotesByOppIds(Object oppIds) {
        return newQueryFactory()
            .setFactoryName('selectPrimaryQuotesByOppIds')
            .selectFields(getFieldList())
            .setCondition('OpportunityId IN :bind0'
            + ' AND isPrimary__c = true'
            + ' AND RecordTypeId = '
            + '\'' + QuoteHelper.RT_ID_BILLING + '\'')
            .setQueryBindings(new List<Object>{oppIds});
    }

    public QueryFactory selectPrimaryQuotesByOpportunityIds(Set<Id> oppIds) {
        return newQueryFactory()
            .setFactoryName('selectPrimaryQuotesByOpportunityIds')
            .selectFields(getDefaultFieldList())
            .setCondition('isPrimary__c = true AND OpportunityId IN :bind0')
            .setQueryBindings(new List<Object>{oppIds});
    }

    public QueryFactory selectQuoteForSyncWithNGBSByName(Object oppName) {
        List<Object> bindings = new List<Object>{oppName, QuoteHelper.RT_ID_BILLING, QuoteHelper.RT_ID_POC};
        return newQueryFactory()
            .setFactoryName('selectQuoteForSyncWithNGBSByName')
            .selectFields(getFieldsForSyncWithNGBS())
            .subselect(new QuoteLineItemSelector().
                selectQuoteLineItemsForSyncWithNGBS())
            .withoutSelectorOrderByIncluded()
            .setCondition('Opportunity.Name =:bind0 AND isPrimary__c = true AND ' +
                '(RecordTypeId =:bind1 OR RecordTypeId =:bind2)')
            .setLimit(2)
            .setQueryBindings(bindings);
    }

    public QueryFactory selectQuoteById(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectQuoteById')
            .selectFields(getFieldList())
            .withoutSelectorOrderByIncluded()
            .setCondition('Id = :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectMultiProductTechnicalQuoteByServiceName(Id masterQuoteId, String serviceName) {
        return newQueryFactory()
            .setFactoryName('selectMultiProductTechnicalQuoteByServiceName')
            .selectFields(getFieldsForTerminationCheck())
            .setCondition('MasterQuote__c = :bind0 AND IsMultiProductTechnicalQuote__c = true AND ServiceName__c = :bind1')
            .setQueryBindings(new List<Object>{masterQuoteId, serviceName});
    }

    public QueryFactory selectMultiProductTechnicalQuotesForOrderProcessByIds(List<String> quoteIds) {
        return newQueryFactory()
            .setFactoryName('selectMultiProductTechnicalQuotesForOrderProcessByIds')
            .setCondition('Id IN :bind0 AND IsMultiProductTechnicalQuote__c = true')
            .subselect(
                new QuoteLineItemSelector().
                selectNonZeroQuoteLineItems()
            )
            .setQueryBindings(new List<Object>{quoteIds});
    }

    public QueryFactory selectMultiProductTechnicalQuotesByMasterQuoteIds(Id masterQuoteId) {
        return selectMultiProductTechnicalQuotesByMasterQuoteIds(new Set<String>{masterQuoteId});
    }

    public QueryFactory selectMultiProductTechnicalQuotesByMasterQuoteIds(Set<Id> masterQuoteIds) {
        return selectMultiProductTechnicalQuotesByMasterQuoteIds(new Set<String>( (List<String>)new List<Id>(masterQuoteIds) ));
    }

    public QueryFactory selectMultiProductTechnicalQuotesByMasterQuoteIds(Set<String> masterQuoteIds) {
        return newQueryFactory()
            .setFactoryName('selectMultiProductTechnicalQuotesByMasterQuoteIds')
            .selectFields(getFieldsForCopy())
            .subselect(new ServiceInfoSelector().selectServiceInfo())
            .setCondition('MasterQuote__c IN :bind0 AND IsMultiProductTechnicalQuote__c = true')
            .setQueryBindings(new List<Object>{masterQuoteIds});
    }

    public QueryFactory selectQuoteByIdWithoutFields(Object quoteId) {
        return newQueryFactory()
            .setFactoryName('selectQuoteByIdWithoutFields')
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object>{quoteId});
    }

    public QueryFactory selectQuotesByIds(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectQuotesByIds')
            .selectFields(getFieldList())
            .withoutSelectorOrderByIncluded()
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectQuotesByIdsForUQT(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectQuotesByIdsForUQT')
            .selectFields(getFieldsForUQT())
            .withoutSelectorOrderByIncluded()
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectQuotesByIdsForUQTCalculatedOnly(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectQuotesByIdsForUQT')
            .selectFields(getCalculatedFieldsForUQT())
            .withoutSelectorOrderByIncluded()
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectQuoteByName(String quoteName) {
        List<Object> bindings = new List<Object>{quoteName};
        return newQueryFactory()
            .setFactoryName('selectQuoteByName')
            .selectFields(getDefaultFieldList())
            .setCondition('Name = :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectQuoteByIdForPOCApproval(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('SelectQuoteByIdForPOCApproval')
            .withSelectorFieldsIncluded()
            .subselect(
                new QuoteLineItemSelector().
                selectQuoteLineItemsForPOCApproval()
            )
            .withSelectFieldsSorted()
            .setCondition('Id = :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectQuoteForSignUp(Object target) {
        return newQueryFactory()
            .setFactoryName('SelectQuoteForSignUp')
            .selectFields(getFieldsForSignUp())
            .subselect(new QuoteLineItemSelector().selectQuoteLineItemsForSignUp())
            .setCondition('Id = :bind0 OR OpportunityId = :bind0')
            .setQueryBindings(new List<Object>{ target });
    }

    public QueryFactory selectQuotesForMultiSignUp(Set<Id> targetIds) {
        String queryCondition = buildQueryConditionForSignUp('Id');
        return newQueryFactory()
            .setFactoryName('selectQuotesForMultiSignUp')
            .selectFields(getFieldsForSignUp())
            .subselect(new QuoteLineItemSelector().selectQuoteLineItemsForSignUp())
            .subselect(new ServiceInfoSelector().selectServiceInfo())
            .setCondition(queryCondition)
            .setQueryBindings(new List<Object> { targetIds, QuoteHelper.RT_NAME_POC_QUOTE });
    }

    public QueryFactory selectQuotesForClose(Object target) {
        return newQueryFactory()
            .setFactoryName('selectQuotesForClose')
            .selectFields(getFieldsForClose())
            .subselect(new QuoteLineItemSelector().selectQuoteLineItemsForSignUp())
            .setCondition('OpportunityId = :bind0')
            .setQueryBindings(new List<Object>{ target });
    }

    public QueryFactory selectTechQuotesForClose(List<Object> targets) {
        List<Object> bindings = new List<Object>{
            targets.get(0),
            targets.size() > 1 ? targets.get(1) : null,
            QuoteHelper.RT_ID_PROSERV,
            QuoteHelper.RT_ID_CC_PROSERV
        };
        String condition =
            '((IsMultiProductTechnicalQuote__c = true AND MasterQuote__r.isPrimary__c = true'
            + (targets.size() > 1 ? ' AND Id = :bind1' : '')
            + ') OR (RecordTypeId =:bind2 OR RecordTypeId =:bind3)) AND OpportunityId = :bind0';
        return newQueryFactory()
            .setFactoryName('selectTechQuotesForClose')
            .selectFields(getFieldsForClose())
            .subselect(new QuoteLineItemSelector().selectQuoteLineItemsForSignUp())
            .setCondition(condition)
            .setQueryBindings(bindings);
    }

    public QueryFactory selectQuotesForWizard(Object target) {
        return newQueryFactory()
            .setFactoryName('selectQuotesForWizard')
            .selectFields(getFieldsForClose())
            .subselect(new QuoteLineItemSelector().selectQuoteLineItemsForSignUp())
            .subselect(new PromotionSelector().selectPromotions())
            .setCondition('OpportunityId = :bind0')
            .setQueryBindings(new List<Object>{ target });
    }

    public QueryFactory selectQuoteForPdfTemplates(Object target) {
        return newQueryFactory()
            .setFactoryName('SelectQuoteForPdfTemplates')
            .selectFields(getFieldsForPdfTemplate())
            .subselect(
                new QuoteLineItemSelector().selectQuoteLineItems()
            )
            .setCondition('OpportunityId = :bind0')
            .setQueryBindings(new List<Object>{ target });
    }

    public QueryFactory selectQuoteToProcessNonNGBSOppoty(Object target) {
        return newQueryFactory()
            .setFactoryName('selectQuoteToProcessNonNGBSOppoty')
            .selectFields(getFieldsForPdfTemplate())
            .subselect(
                new QuoteLineItemSelector().selectQuoteLineItems()
            )
            .setCondition('OpportunityId = :bind0 AND isPrimary__c = true')
            .setQueryBindings(new List<Object>{ target });
    }

    public QueryFactory selectPrimaryQuotes(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectPrimaryQuotes')
            .selectFields(getFieldsForPdfTemplate())
            .setCondition('OpportunityId = :bind0 AND isPrimary__c = true')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectQuotesByOppIds(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectQuotesByOppIds')
            .selectFields(getFieldsForPdfTemplate())
            .setCondition('OpportunityId = :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectQuotesByOppIdsWithServiceInfos(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectQuotesByOppIdsWithServiceInfos')
            .selectFields(getFieldList())
            .subselect(
                new ServiceInfoSelector().selectServiceInfo()
            )
            .setCondition('(OpportunityId = :bind0 OR Opportunity.MasterOpportunity__c = :bind0)'
            + ' AND RecordTypeId = ' + '\'' + QuoteHelper.RT_ID_BILLING + '\''
            + ' AND ((isPrimary__c = true AND IsMultiProductTechnicalQuote__c = false)'
            + ' OR (MasterQuote__r.isPrimary__c = true AND IsMultiProductTechnicalQuote__c = true))')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectChildQuotes(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('SelectChildQuotes')
            .selectFields(getFieldList())
            .setCondition('ParentQuote__c IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectQuotesForPackageTriggerEnabledLBO(List<Id> accountIds) {
        return newQueryFactory()
            .setFactoryName('selectQuotesForPackageTriggerEnabledLBO')
            .selectFields(getFieldsForPackageTrigger())
            .setCondition('(Account__c IN :bind0 OR AccountId IN :bind0)'
            + ' AND (ServiceName__c = null OR ServiceName__c = ' + '\'' + QuoteHelper.NGBS_OFFICE_PRODUCT + '\')'
            + ' AND Opportunity.IsClosed = FALSE')
            .setQueryBindings(new List<Object>{ accountIds});
    }

    public QueryFactory selectLboQuotesByOppIdsForAutoSyncWithNGBS(Set<Id> oppIds) {
        return newQueryFactory()
            .setFactoryName('selectLboQuotesByOppIdsForAutoSyncWithNGBS')
            .setCondition(queryConditionForLboQuotesByOppIdsForAutoSyncWithNGBS())
            .selectFields(new List<Schema.SObjectField> { Quote.Id, Quote.MasterQuote__c })
            .setQueryBindings(new List<Object> { oppIds, QuoteHelper.RT_ID_BILLING, AccountHelper.OFFER_TYPE_POC });
    }

    public QueryFactory selectQuotesForContractPopulation(Set<Id> quoteIdSet) {
        return newQueryFactory()
            .setFactoryName('selectQuotesForContractPopulation')
            .selectFields(getFieldsForContractPopulation())
            .selectFields(getRelatedAccountFields())
            .withoutSelectorOrderByIncluded()
            .setCondition('Id IN :bind0')
            .setQueryBindings(new List<Object>{ quoteIdSet });
    }

    public QueryFactory selectQuoteForCloning(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectQuoteById')
            .selectFields(AquivaHelper.getAllFieldsForObject('Quote'))
            .selectFields(new List<String>{ 'Account__c', 'Account__r.Name', 'Opportunity.Name' })
            .setCondition('Id = :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectQuoteForCloningUB(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectQuoteByIdUB')
            .selectFields(AquivaHelper.getAllFieldsForObject('Quote'))
            .selectFields(new List<String>{ 'Account__c', 'OpportunityId', 'Account.Billing_ID__c' })
            .setCondition('Id = :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectQuotesForQuoteService(Id objectId, Set<String> recordTypes, String condition){
        return this.selectQuotes()
            .subselect(new QuoteLineItemSelector()
                .selectQuoteLineItemsForQuoteService())
            .subselect(new PromotionSelector()
                .selectPromotions())
            .selectFields(getFieldsForQuoteService())
            .setCondition(condition)
            .setQueryBindings(new List<Object>{objectId, recordTypes});
    }

    public QueryFactory selectQuoteForDqGoa(Id quoteId) {
        return newQueryFactory()
            .setFactoryName('selectQuoteForDqGoa')
            .selectFields(getFieldsForDqGoa())
            .subselect(
                new QuoteLineItemSelector().selectQuoteLineItemsForDqGoa()
            )
            .setCondition('Id = :bind0 OR MasterQuote__c =: bind0')
            .setQueryBindings(new List<Object>{ quoteId });
    }

    public QueryFactory selectQuotesForDQSync(Set<Id> quoteIds) {
        return newQueryFactory()
            .setFactoryName('selectQuotesForDQSync')
            .selectFields(getFieldsForDQSync())
            .selectFields(getRelatedObjectsFieldsForDQSync())
            .subselect(
                new QuoteLineItemSelector().selectQuoteLineItemsForDqSync()
            )
            .setCondition('Id IN :bind0 OR MasterQuote__c IN :bind0')
            .setQueryBindings(new List<Object>{quoteIds});
    }

    public QueryFactory selectCCQuoteForDQSync(Id opportunityId) {
        return newQueryFactory()
            .setFactoryName('selectCCQuoteForDQSync')
            .selectFields(getFieldsForDQSync())
            .selectFields(getRelatedObjectsFieldsForDQSync())
            .subselect(
                new QuoteLineItemSelector().selectQuoteLineItemsForDqGoa()
            )
            .setCondition('OpportunityId = :bind0 AND RecordTypeId = \'' + QuoteHelper.RT_ID_CC + '\'')
            .setQueryBindings(new List<Object>{opportunityId});
    }

    public QueryFactory selectTechQuotesByOppId(Id opportunityId) {
        return newQueryFactory()
            .setFactoryName('selectTechQuotesByOppId')
            // .selectFields(getFieldList())
            // .selectFields(getFieldsWithMasterOpportunity())
            .selectFields(getFieldsForUQT())
            .setCondition('IsMultiProductTechnicalQuote__c = true'
                + ' AND (OpportunityId = :bind0 OR Opportunity.MasterOpportunity__c = :bind0)'
            )
            .setQueryBindings(new List<Object>{opportunityId});
    }

    public QueryFactory selectTechQuotesByOppIdUB(Id opportunityId) {
        return newQueryFactory()
            .setFactoryName('selectTechQuotesByOppIdUB')
            // .selectFields(getFieldList())
            // .selectFields(getFieldsWithMasterOpportunityUB())
            .selectFields(getFieldsForUQT())
            .setCondition('IsMultiProductTechnicalQuote__c = true AND OpportunityId = :bind0'
            )
            .setQueryBindings(new List<Object>{opportunityId});
    }

    public QueryFactory selectQuoteForDQGoaApproval(Set<Id> opportunityIdSet) {
        return newQueryFactory()
            .setFactoryName('selectQuoteForDQGoaApproval')
            .selectFields(getFieldsForDQGoaApproval())
            .setCondition('OpportunityId IN :bind0 AND '
                + 'Approved_Status__c = ' + '\'' + QuoteHelper.APPROVAL_STATUS_REQUIRED + '\' AND '
                + '((Account.RC_User_ID__c = null AND Account.Billing_ID__c = null) OR '
                + '(Account.Billing_ID__c != null AND '
                + '((Account.Offer_Type__c = ' + '\'' + AccountHelper.OFFER_TYPE_POC + '\' OR '
                + 'Account.Offer_Type__c LIKE ' + '\'%' + AccountHelper.OFFER_TYPE_TRIAL + '%\') OR '
                + '(Account.RC_Account_Status__c = ' + '\'' + AccountHelper.OFFER_TYPE_POC + '\' OR '
                + 'Account.RC_Account_Status__c LIKE ' + '\'%' + AccountHelper.OFFER_TYPE_TRIAL + '%\'))))'
            )
            .setQueryBindings(new List<Object>{opportunityIdSet});
    }

    public QueryFactory selectQuotesWithApprovedPOCApprovals(Id opportunityId, Set<String> recordTypes) {
        return this.selectQuotes()
            .selectFields(getFieldsForQuoteService())
            .subselect(new QuoteLineItemSelector()
                .selectQuoteLineItemsForQuoteService()
            )
            .subselect(new ApprovalSelector()
                .selectApprovals()
                .selectFields(new List<String>{ 'Id' })
                .setCondition('Status__c = \'' + ApprovalHelper.STATUS_APPROVED +
                '\' AND RecordType.Name = \'' + ApprovalHelper.RT_NAME_POC_ACCOUNT + '\'')
            )
            .setCondition('(OpportunityId = :bind0 OR Opportunity.MasterOpportunity__c = :bind0) AND RecordTypeId IN :bind1')
            .setQueryBindings(new List<Object>{opportunityId, recordTypes});
    }

    public QueryFactory selectQuotesForQuoteLineItemTrigger(Set<Id> quoteIdSet) {
        return newQueryFactory()
            .setFactoryName('selectQuotesForQuoteLineItemTrigger')
            .selectFields(getFieldsForQuoteLineItemTrigger())
            .subselect(new ServiceInfoSelector()
                .newQueryFactory()
                .selectFields(new List<String>{ 'Id', 'IsProcessOrderSent__c' })
            )
            .subselect(new OrderSelector('Orders3__r', Quote.SObjectType)
                .newQueryFactory()
                .selectFields(new List<String>{ 'Id', 'PackageId__c' })
            )
            .setCondition('Id IN :bind0')
            .setQueryBindings(new List<Object>{ quoteIdSet });
    }

    public QueryFactory selectServiceQuotesForMasterQuote(Id masterQuoteId) {
        return selectServiceQuotesForMasterQuote(masterQuoteId, new List<String>());
    }

    public QueryFactory selectServiceQuotesForMasterQuote(Id masterQuoteId, List<String> services) {
        List<Object> bindings = new List<Object>();
        List<Object> conditions = new List<Object>();

        conditions.add('MasterQuote__c = :bind0');
        bindings.add(masterQuoteId);

        if (services != null && !services.isEmpty()) {
            conditions.add('ServiceName__c IN :bind1');
            bindings.add(services);
        }

        return newQueryFactory()
            .setFactoryName('selectServiceQuotesForMasterQuote')
            .selectFields(AquivaHelper.getAllFieldsForObject('Quote'))
            .selectFields(getRelatedAccountFieldsForTechQuotes())
            .selectFields(new List<String>{
                'Opportunity.Tier_Name__c',
                'MasterQuote__c',
                'MasterQuote__r.AccountId',
                'MasterQuote__r.OpportunityId',
                'MasterQuote__r.Opportunity.Tier_Name__c'
            })
            .setCondition('MasterQuote__c = :bind0')
            .setQueryBindings(new List<Object>{masterQuoteId});
    }

    public QueryFactory selectServiceQuotesForMasterQuoteUB(Id masterQuoteId, List<String> services) {
        return newQueryFactory()
            .setFactoryName('selectServiceQuotesForMasterQuoteUB')
            .selectFields(AquivaHelper.getAllFieldsForObject('Quote'))
            .selectFields(getRelatedAccountFieldsForTechQuotes())
            .selectField(Quote.OpportunityId)
            .setCondition('MasterQuote__c = :bind0 AND ServiceName__c IN :bind1')
            .setQueryBindings(new List<Object>{masterQuoteId, services});
    }

    public QueryFactory selectQuotesForDQWidget(Set<Id> oppIds, Set<String> recordTypes) {
        return this.selectQuotes()
            .subselect(new QuoteLineItemSelector()
                .selectQuoteLineItemsForQuoteService())
            .selectFields(getFieldsForQuoteService())
            .setCondition('OpportunityId IN :bind0 AND RecordTypeId IN :bind1')
            .setQueryBindings(new List<Object>{oppIds, recordTypes});
    }

    public QueryFactory selectMasterAndTechnicalQuotes(Set<Id> objIds) {
        String queryCondition = buildQueryConditionForSignUp('Opportunity.MasterOpportunity__c');
        return newQueryFactory()
            .setFactoryName('selectMasterAndTechnicalQuotes')
            .selectFields(getTechnicalQuotesFields())
            .setCondition(queryCondition)
            .setQueryBindings(new List<Object> { objIds, QuoteHelper.RT_NAME_POC_QUOTE });
    }

    public QueryFactory selectQuotesForDeliveredProducts(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectQuotesForDeliveredProducts')
            .selectFields(getTechnicalQuotesFields())
            .setCondition('Id IN :bind0 AND Opportunity.Tier_Name__c = :bind1')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectPrimaryQuotesForDqBatchSync(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectPrimaryQuotesForDqBatchSync')
            .selectFields(getFieldsForDQSync())
            .selectFields(getRelatedObjectsFieldsForDQSync())
            .subselect(
                new QuoteLineItemSelector().selectQuoteLineItemsForDqSync()
            )
            .setCondition('OpportunityId IN :bind0 AND isPrimary__c = true')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectMultiProductTechnicalQuotesForSyncByMasterQuoteIds(Set<Id> masterQuoteIds) {
        return newQueryFactory()
            .setFactoryName('selectMultiProductTechnicalQuotesForSyncByMasterQuoteIds')
            .selectFields(getFieldsForCopy())
            .setCondition('MasterQuote__c IN :bind0 AND IsMultiProductTechnicalQuote__c = true AND Opp_Type__c = \'' + OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS + '\'')
            .setQueryBindings(new List<Object>{masterQuoteIds});
    }

    public QueryFactory selectMultiProductTechnicalQuotesForClearUp(Set<Id> masterOppIds) {
        return newQueryFactory()
            .setFactoryName('selectMultiProductTechnicalQuotesForClearUp')
            .setCondition(
                'IsMultiProductTechnicalQuote__c = true ' +
                'AND MasterQuote__c = NULL ' +
                'AND (OpportunityId IN :bind0 OR Opportunity.MasterOpportunity__c IN :bind0)')
            .setQueryBindings(new List<Object>{masterOppIds});
    }

    public QueryFactory selectQuotesByMasterQuoteIdToClearQLIs(Set<Id> masterQuoteIds, List<String> serviceNames) {
        return newQueryFactory()
            .setFactoryName('selectQuotesByMasterQuoteIdToClearQLIs')
            .selectFields(getFieldsForQuoteService())
            .subselect(new QuoteLineItemSelector('QuoteLineItems', Quote.SObjectType)
                .selectQuoteLineItems()
                .setCondition('ServiceName__c IN :bind1'))
            .setCondition('Id IN :bind0 OR (MasterQuote__c IN :bind0 AND IsMultiProductTechnicalQuote__c = true AND ServiceName__c IN :bind1)')
            .setQueryBindings(new List<Object> { masterQuoteIds, serviceNames });
    }

    public QueryFactory selectQuotesForShippingByOppIds(List<Id> oppIds) {
        List<Object> bindings = new List<Object>{oppIds, QuoteHelper.RT_ID_BILLING};
        return newQueryFactory()
            .setFactoryName('selectQuotesForShippingByOppIds')
            .selectFields(getFieldsForShipping())
            .setCondition('OpportunityId IN :bind0 AND RecordTypeId =:bind1 AND IsMultiProductTechnicalQuote__c = false')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectOpportunityFieldsByQuoteIds(Set<Id> quoteIds) {
        return newQueryFactory()
            .setFactoryName('selectOpportunityFieldsByQuoteIds')
            .selectFields(getOpportunityFields())
            .setCondition('Id IN :bind0')
            .setQueryBindings(new List<Object> { quoteIds });
    }

    public QueryFactory selectQuotesByIdsWithRecordTypes(Set<Id> quoteIds) {
        return newQueryFactory()
            .setFactoryName('selectQuotesByIdsWithRecordTypes')
            .withoutSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .selectFields(new List<SObjectField> {
                Quote.Id,
                Quote.RecordTypeId,
                Quote.ProServ_Status__c
            })
            .setCondition('Id IN :bind0')
            .setQueryBindings(new List<Object> {quoteIds});
    }

    public QueryFactory selectQuotesByMasterQuoteIdToCropQLIs(Set<Id> masterQuoteIds) {
        return newQueryFactory()
            .setFactoryName('selectQuotesByMasterQuoteIdToCropQLIs')
            .selectFields(getFieldsForQuoteService())
            .subselect(
                new QuoteLineItemSelector('QuoteLineItems', Quote.SObjectType)
                .selectQuoteLineItems()
                .selectField('Product_Lic_Id__c')
            )
            .setCondition('Id IN :bind0 OR MasterQuote__c IN :bind0')
            .setQueryBindings(new List<Object> { masterQuoteIds });
    }

    public QueryFactory selectQuotesByIdToQLIsForOrderCreationProcess(Set<Id> quoteIds) {
        return newQueryFactory()
            .setFactoryName('selectQuotesByIdToQLIsForOrderCreationProcess')
            .selectFields(getFieldsForOrderCreationProcess())
            .subselect(
                new ServiceInfoSelector().selectServiceInfo()
            )
            .subselect(
                new QuoteLineItemSelector('QuoteLineItems', Quote.SObjectType)
                    .selectQuoteLineItemsForOrderCreationProcess()
            )
            .setCondition('(Id IN :bind0 OR MasterQuote__c IN :bind0)')
            .setQueryBindings(new List<Object> { quoteIds });
    }

    public QueryFactory selectQuotesForOrderCreationByOppId(Id oppId) {
        return newQueryFactory()
            .setFactoryName('selectQuotesForOrdersCreationByOppId')
            .selectFields(getFieldsForOrderCreationProcess())
            .subselect(
                new ServiceInfoSelector().selectServiceInfo()
            )
            .subselect(
                new QuoteLineItemSelector('QuoteLineItems', Quote.SObjectType)
                    .selectQuoteLineItemsForOrderCreationProcess()
            )
            .setCondition('OpportunityId = :bind0')
            .setQueryBindings(new List<Object> { oppId });
    }

    public QueryFactory selectQuotesForOrderCreationByIds(Set<Id> quoteIds) {
        return newQueryFactory()
            .setFactoryName('selectQuotesForOrderCreationByIds')
            .selectFields(getFieldsForOrderCreationProcess())
            .subselect(
                new ServiceInfoSelector().selectServiceInfo()
            )
            .subselect(
                new QuoteLineItemSelector('QuoteLineItems', Quote.SObjectType)
                    .selectQuoteLineItemsForOrderCreationProcess()
            )
            .setCondition('Id IN :bind0')
            .setQueryBindings(new List<Object> { quoteIds });
    }

    public QueryFactory selectQuotesByIdsToServiceInfo(Set<Id> quoteIdSet) {
        return newQueryFactory()
            .setFactoryName('selectQuotesByIdsToServiceInfo')
            .selectFields(getDefaultFieldList())
            .subselect(
                new ServiceInfoSelector().selectServiceInfo()
            )
            .setCondition('Id IN :bind0')
            .setQueryBindings(new List<Object>{ quoteIdSet });
    }

    public QueryFactory selectQuotesByIdsToQLIForChangeOrder() {
        return newQueryFactory()
            .setFactoryName('selectQuotesByIdsToQLIForChangeOrder')
            .selectFields(getDefaultFieldList())
            .subselect(
                new QuoteLineItemSelector('QuoteLineItems', Quote.SObjectType)
                    .selectQuoteLineItemsForQuoteService()
            )
            .setCondition('Id IN :bind0')
            .withoutSelectorOrderByIncluded();
    }

    public QueryFactory selectQuotesForOrderActivationProcess(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectQuotesForOrderActivationProcess')
            .selectFields(getDefaultFieldList())
            .subselect(
                new ServiceInfoSelector().selectServiceInfo()
            )
            .subselect(new OrderSelector('Orders3__r', Quote.SObjectType)
                .newQueryFactory()
                .selectFields(new List<String>{ 'Id', 'Status', 'PackageId__c', 'CreatedDate', 'TechnicalQuoteId__c', 'Quote.RecordTypeId' })
                .setCondition('Status = \'' + OrderHelper.STATUS_NEW + '\'')
                .addOrdering('CreatedDate', QueryFactory.SortOrder.DESCENDING)
            )
            .setCondition('AccountId IN :bind0 AND BillingPackage__c = null AND RecordTypeId = \'' + QuoteHelper.RT_ID_BILLING + '\'')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectPocQuotesByOpportunityWithMinDLs(Set<Id> oppIds, Id recordTypeId, Integer minDigitalLines) {
        return newQueryFactory()
            .setFactoryName('selectPocQuotesByOpportunityWithMinDLs')
            .selectFields(getDefaultFieldList())
            .setCondition('OpportunityId IN :bind0 AND isPrimary__c = true AND RecordTypeId = :bind1 AND Total_Number_of_Digital_Lines__c >= :bind2')
            .setQueryBindings(new List<Object>{oppIds, recordTypeId, minDigitalLines});
    }

    public QueryFactory selectQuotesForCreateServiceInfoBatch(Set<Id> accIds) {
        QueryFactory factory = newQueryFactory()
            .setFactoryName('selectQuotesForCreateServiceInfoBatch')
            .withoutSelectorFieldsIncluded()
            .selectFields(getFieldsForCreateServiceInfoBatch())
            .setCondition(
                'CreatedDate >= LAST_N_DAYS:365 '
                + 'AND Quote_is_Invalid__c = false '
                + 'AND IsMultiProductTechnicalQuote__c = false '
                + 'AND Opportunity.IsMultiProductTechnicalOpportunity__c = false '
                + 'AND Opportunity.StageName != :bind0 '
                + 'AND (isPrimary__c = true OR Opportunity.StageName != :bind1) '
                + 'AND Id NOT IN (SELECT Quote__c FROM ServiceInfo__c)'
            )
            .withoutSelectorOrderByIncluded()
            .withoutSelectFieldsSorted();
        List<Object> bindings = new List<Object> {
            OpportunityHelper.STAGE_NAME_DOWNGRADED,
            OpportunityHelper.STAGE_NAME_CLOSED_WON
        };
        if (!accIds.isEmpty()) {
            factory.addCondition('AccountId IN :bind2');
            bindings.add(accIds);
        }
        return factory.setQueryBindings(bindings);
    }

    @TestVisible
    private String buildQueryConditionForSignUp(String fieldName) {
        String getPrimaryMainQuoteFilter = '(isPrimary__c = true AND IsMultiProductTechnicalQuote__c = false AND RecordType.Name != :bind1)';
        String getMPTechQuotesFilter = '(MasterQuote__r.isPrimary__c = true AND IsMultiProductTechnicalQuote__c = true)';
        String getProservQuotesFilter = 'ProServ_Status__c != null';
        String getPOCQuotesFilter = '(RecordType.Name = :bind1 AND isPrimary__c = true)';

        String queryTemplate = '({0} IN :bind0 OR OpportunityId IN :bind0) AND ({1} OR {2} OR {3} OR {4})';

        return String.format(
            queryTemplate,
            new List<String> {
                fieldName,
                getPrimaryMainQuoteFilter,
                getMPTechQuotesFilter,
                getProservQuotesFilter,
                getPOCQuotesFilter
            }
        );
    }

    @TestVisible
    private String queryConditionForLboQuotesByOppIdsForAutoSyncWithNGBS() {
        String targetOptyFilter = 'OpportunityId IN :bind0';
        String isBillingQuote = 'RecordTypeId = :bind1';
        String hasNoInvoiceIdFilter = 'InvoiceId__c = null';
        String isNotEngage = String.join(new List<String>(ENGAGE_SERVICES_EXCLUDED_FROM_AUTOSYNC), '\', \'');
        String isMeetingsFax=String.join(new List<String>(SERVICES_FOR_LBO_FLAG), '\', \'');
        String isEnabledLBO = '((ServiceName__c IN (\'' + isMeetingsFax + '\') AND Enabled_LBO__c = true) OR (ServiceName__c NOT IN (\'' + isNotEngage + '\') AND ServiceName__c NOT IN (\'' + isMeetingsFax + '\')))';
        String isPrimary = 'isPrimary__c = true';
        String isMasterPrimary = 'MasterQuote__r.isPrimary__c = true';
        String isExistingBusiness = 'BillingPackage__c != null';
        String isPOCSignedUp = 'Account.Offer_Type__c = :bind2';

        String queryTemplate = '{0} AND {1} AND {2} AND {3} AND ({4} OR {5}) AND ({6} OR {7})';

        return String.format(
            queryTemplate,
            new List<String> {
                targetOptyFilter,
                isBillingQuote,
                hasNoInvoiceIdFilter,
                isEnabledLBO,
                isPrimary,
                isMasterPrimary,
                isExistingBusiness,
                isPOCSignedUp
            }
        );
    }

    public QueryFactory selectTechProservQuoteForSyncDiscounts(Set<Id> oppIds) {
        return newQueryFactory()
            .setFactoryName('selectQuoteForSyncWithNGBSByQuoteId')
            .selectFields(getFieldsForSyncWithNGBSMultiProduct())
            .subselect(new QuoteLineItemSelector().selectQuoteLineItemsForSyncWithNGBS())
            .subselect(new ApprovalSelector().selectCreditLimitIncreaseApproved())
            .subselect(new ServiceInfoSelector().selectServiceInfo())
            .withoutSelectorOrderByIncluded()
            .setCondition('(isPrimary__c = true OR MasterQuote__r.isPrimary__c = true) AND OpportunityId IN :bind0 AND ServiceName__c = \'' + QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT + '\'')
            .setQueryBindings(new List<Object> { oppIds });
    }

    public QueryFactory selectQuoteApprovalsInfo(String quoteId) {
        return newQueryFactory()
            .setFactoryName('selectQuoteApprovalsInfo')
            .selectFields(getQuoteApprovalsInfoFields())
            .selectFields(getPopulateAvailableApprovalActionsFields())
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object> { quoteId });
    }
}