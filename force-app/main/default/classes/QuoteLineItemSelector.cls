public inherited sharing class QuoteLineItemSelector extends SObjectSelector {
    public static final Set<String> FIELDS_ID = new Set<String> {
        'Id'
    };

    public static final Set<String> FIELDS_STANDARD = new Set<String> {
        'Id',
        'QuoteId',
        'Product2Id',
        'PricebookEntryId',
        'IsDeleted',
        'SortOrder',
        'Description',
        'LineNumber',
        'CurrencyIsoCode',
        'Quantity',
        'DeliveredQuantity__c',
        'UnitPrice',
        'ListPrice',
        'Discount',
        'TotalPrice',
        'Subtotal',
        'ServiceName__c',
        'NewQuantity__c'
    };

    public static final Set<String> FIELDS_PRODUCT = new Set<String> {
        'Product2Id',
        'Product2.Id',
        'Product2.Name',
        'Product2.ExtID__c',
        'Product2.Feature__c',
        'Product2.Dependent_on_Feature__c',
        'Product2.Charge_Term__c',
        'Product2.Family',
        'Product2.Product_Type__c',
        'Product2.Matcher_Formula__c',
        'Product2.Sub_Category__c',
        'Product2.Billing_Type__c',
        'Product2.CatID__c',
        'Product2.Goa_Group_V2__c',
        'Product2.Goa_Group_V3__c',
        'Product2.Group__c',
        'Product2.Subgroup__c'
    };

    public static final Set<String> FIELDS_QUOTE = new Set<String> {
        'QuoteId',
        'Quote.Id',
        'Quote.RecordTypeId',
        'Quote.AreaCode__c',
        'Quote.Package_Info__c',
        'Quote.Delta_ARR__c',
        'Quote.Delta_CC_ARR__c',
        'Quote.Delta_CC_MRR__c',
        'Quote.Delta_MRR__c',
        'Quote.Estimated_Hardware__c',
        'Quote.IsMultiProductTechnicalQuote__c',
        'Quote.isPrimary__c',
        'Quote.FSC_Full_MRS_Calculation__c',
        'Quote.Products__c',
        'Quote.Special_Terms__c',
        'Quote.Upsell_Status__c'
    };

    public static final Set<String> FIELDS_QUOTE_ACCOUNT = new Set<String> {
        'Quote.AccountId',
        'Quote.Account.Id',
        'Quote.Account.Number_of_DL_s__c',
        'Quote.Account.RC_Account_Status__c'
    };

    public static final Set<String> FIELDS_QUOTE_OPPORTUNITY = new Set<String> {
        'Quote.OpportunityId',
        'Quote.Opportunity.Id',
        'Quote.Opportunity.Tier_Name__c',
        'Quote.Opportunity.Is_Billing_Opportunity__c',
        'Quote.Opportunity.Brand_Name__c',
        'Quote.Opportunity.AccountId'
    };

    public static final Set<String> FIELDS_QUOTE_ENTITLEMENT_TOTALS = new Set<String> {
        'QuoteId',
        'Quote.Id',
        'Quote.Entitlement_Common_Phones_Quantity__c',
        'Quote.Entitlement_Global_Phones_Quantity__c',
        'Quote.Entitlement_GO_LE_Phones_Quantity__c',
        'Quote.Entitlement_Limited_Phones_Quantity__c',
        'Quote.Entitlement_Rental_Phones_Quantity__c',
        'Quote.Entitlement_Total_ARR__c',
        'Quote.Entitlement_Total_MRR__c'
    };

    public static final Set<String> FIELDS_QUOTE_CONTACT_CENTER_TOTALS = new Set<String> {
        'QuoteId',
        'Quote.Id',
        'Quote.Contact_Center_Entitlement_Total_ARR__c',
        'Quote.Contact_Center_Entitlement_Total_MRR__c',
        'Quote.Contact_Center_Total_ARR__c',
        'Quote.Contact_Center_Total_ARR_Discount__c',
        'Quote.Contact_Center_Total_First_Year_Cost__c',
        'Quote.Contact_Center_Total_First_Year_Discount__c',
        'Quote.Contact_Center_Total_Initial_Payment__c',
        'Quote.Contact_Center_Total_MRR__c',
        'Quote.Contact_Center_Total_MRR_Discount__c',
        'Quote.Contact_Center_Total_One_Time__c',
        'Quote.Contact_Center_Total_One_Time_Discount__c',
        'Quote.ContactCenterTotalInitialPaymentDiscount__c'
    };

    public static final Set<String> FIELDS_QUOTE_TOTALS = new Set<String> {
        'QuoteId',
        'Quote.Id',
        'Quote.Total_ARR__c',
        'Quote.Total_ARR_Discount__c',
        'Quote.Total_ARR_with_Taxes__c',
        'Quote.Total_First_Year_Cost__c',
        'Quote.Total_First_Year_Cost_with_Taxes__c',
        'Quote.Total_First_Year_Discount__c',
        'Quote.Total_Initial_Payment__c',
        'Quote.Total_Initial_Payment_Discount__c',
        'Quote.Total_Initial_Payment_with_Taxes__c',
        'Quote.Total_MRR_Discount__c',
        'Quote.Total_MRR_New__c',
        'Quote.Total_MRR_with_Taxes__c',
        'Quote.Total_Number_of_Digital_Lines__c',
        'Quote.Total_One_Time__c',
        'Quote.Total_One_Time_Discount__c',
        'Quote.Total_One_Time_with_Taxes__c',
        'Quote.TotalQuoteSummary__c'
    };

    public static final Set<String> FIELDS_ENTITLEMENTS = new Set<String> {
        'Entitlement__c',
        'Entitlement__r.Id',
        'Entitlement__r.EffectivePrice__c',
        'Entitlement__r.EffectivePricePrecise__c',
        'Entitlement__r.Quantity__c',
        'Entitlement__r.DisplayQuantity__c',
        'Entitlement__r.Active__c',
        'Entitlement__r.Price__c',
        'Entitlement__r.Discount__c',
        'Entitlement__r.Discount_Type__c',
        'Entitlement__r.Product__c',
        'Entitlement__r.PackageOfferType__c',
        'Entitlement__r.ChargeTerm__c',
        'Entitlement__r.PackageVersion__c',
        'Entitlement__r.PackageCatalogId__c',
        'Entitlement__r.PackageDuration__c',
        'Entitlement__r.PartnerConfig__c',
        'Entitlement__r.Product__r.Name',
        'Entitlement__r.Product__r.Family',
        'Entitlement__r.Product__r.Feature__c',
        'Entitlement__r.Product__r.Charge_Term__c'
    };

    public static final Set<String> FIELDS_PROMOTION = new Set<String> {
        'Promotion__c',
        'Promotion__r.Promo_Code_Id__c'
    };

    public static final Set<String> FIELDS_MULTI_PRODUCT = new Set<String> {
        'Id',
        'QuoteId',
        'Order__c',
        'MasterQLI__c',
        'IsMultiProductTechnicalQLI__c'
    };

    public static final Set<String> FIELDS_NGBS = new Set<String> {
        'Id',
        'Entitlement__c',
        'Promotion__c',
        'Order__c',
        'Deactivated__c',
        'NewQuantity__c',
        'DeliveredQuantity__c',
        'PackageInfo__c',
        'PackageCatalogId__c',
        'PackageVersion__c',
        'ChargeTerm__c',
        'ServiceName__c',
        'EffectivePrice__c',
        'EffectivePriceNew__c',
        'IsHiddenLicense__c',
        'DiscountValueNew__c',
        'TotalInitialPrice__c',
        'QuoteRecordType__c',
        'isDownsell__c',
        'SalesEndDate__c',
        'BillingStatus__c',
        'Threshold__c',
        'Total12MonthPrice__c',
        'TotalInitialPrice__c',
        'TotalSummary__c'
    };

    public static final Set<String> FIELDS_LEGACY = new Set<String> {
        'Approved_Discount__c',
        'Approved_Discount_Type__c',
        'Last_Approved_Quantity__c',
        'Last_Approved_Discount__c',
        'Package_Info_QLI__c',
        'Charge_Term__c',
        'Discount_number__c',
        'Discount_type__c',
        'Item_type__c',
        'Billing_Cycle_Duration__c',
        'Zero_Quantity__c',
        'Total_Annual__c',
        'Total_One_Time__c',
        'Package_Info__c',
        'Product_Lic_Id__c',
        'Display_Name__c',
        'Matcher_Fields__c',
        'Quantity_or_Threshold__c',
        'Delta_ARR__c',
        'Delta_MRR__c',
        'Sort_Order__c',
        'Fixed_Taxes_Amount__c',
        'Total_Annual__c',
        'Total_Monthly__c',
        'Total_One_Time__c'
    };

    public static final Set<String> FIELDS_SYNC = new Set<String> {
        'Id',
        'Quantity',
        'Product2Id',
        'Package_Info_QLI__c',
        'Package_Info__c',
        'Charge_Term__c',
        'Product_Lic_Id__c',
        'Item_type__c',
        'Discount',
        'Discount_Value__c',
        'EffectivePrice__c',
        'PackageInfo__c',
        'Discount_Number__c',
        'Discount_Type__c',
        'ChargeTerm__c',
        'CurrencyIsoCode',
        'UnitPrice',
        'EffectivePriceNew__c',
        'Product_Family__c',
        'Zero_Quantity__c',
        'Display_Name__c',
        'Matcher_Fields__c',
        'Quantity_or_Threshold__c',
        'IsHiddenLicense__c',
        'QuoteRecordType__c',
        'QuoteId',
        'Quote.Opportunity.Is_Billing_Opportunity__c',
        'Quote.Opportunity.Brand_Name__c',
        'Quote.OpportunityId',
        'Quote.AreaCode__c',
        'Quote.Package_Info__c',
        'Quote.Account.Payment_Plan__c',
        'Deactivated__c',
        'NewQuantity__c',
        'DeliveredQuantity__c',
        'isDownsell__c',
        'SalesEndDate__c',
        'IsHiddenLicense__c',
        'Entitlement__c',
        'Entitlement__r.EffectivePrice__c',
        'Entitlement__r.EffectivePricePrecise__c',
        'Entitlement__r.Quantity__c',
        'Entitlement__r.DisplayQuantity__c',
        'Entitlement__r.Active__c',
        'Entitlement__r.Price__c',
        'Entitlement__r.Discount__c',
        'Entitlement__r.Discount_Type__c',
        'Entitlement__r.Product__c',
        'Entitlement__r.PackageOfferType__c',
        'Entitlement__r.ChargeTerm__c',
        'Entitlement__r.PackageVersion__c',
        'Entitlement__r.PackageCatalogId__c',
        'Entitlement__r.PackageDuration__c',
        'Entitlement__r.PartnerConfig__c',
        'Product2.Name',
        'Product2.ExtID__c',
        'Product2.Feature__c',
        'Product2.Charge_Term__c',
        'Product2.Family',
        'Product2.Product_Type__c',
        'Product2.Matcher_Formula__c',
        'Product2.Sub_Category__c',
        'Product2.Billing_Type__c',
        'Product2.InitialOrderType__c',
        'Product2.UpsellType__c',
        'Product2.ShippingType__c',
        'Product2.DownsellType__c',
        'Product2.Description',
        'Product2.Product_Description__c',
        'Product2.CategoryCode__c',
        'Product2.GOA_Group_V3__c',
        'Promotion__c',
        'MasterQLI__c',
        'ServiceName__c'
    };

    public static final Set<String> FIELDS_SIGNUP = new Set<String> {
        'Id',
        'Quantity',
        'PackageInfo__c',
        'Package_Info_QLI__c',
        'Discount_number__c',
        'Discount_type__c',
        'Item_type__c',
        'UnitPrice',
        'EffectivePrice__c',
        'Product2.ExtID__c',
        'Product2.Name',
        'Product2.Family'
    };

    public static final Set<String> FIELDS_QLI_BY_QUOTE = new Set<String> {
        'Id',
        'PricebookEntryId',
        'Approved_Discount__c',
        'Approved_Discount_Type__c',
        'Last_Approved_Quantity__c',
        'Last_Approved_Discount__c',
        'Package_Info_QLI__c',
        'Charge_Term__c',
        'Quantity',
        'NewQuantity__c',
        'DeliveredQuantity__c',
        'PackageInfo__c',
        'Discount_number__c',
        'Discount_type__c',
        'DiscountValueNew__c',
        'ChargeTerm__c',
        'Item_type__c',
        'UnitPrice',
        'EffectivePrice__c',
        'TotalPrice',
        'TotalInitialPrice__c',
        'Deactivated__c',
        'QuoteRecordType__c',
        'Fixed_Taxes_Amount__c',
        'Billing_Cycle_Duration__c',
        'Zero_Quantity__c',
        'EffectivePriceNew__c',
        'IsHiddenLicense__c',
        'QuoteId',
        'Quote',
        'Quote.OpportunityId',
        'Quote.RecordTypeId',
        'Quote.Package_Info__c',
        'Quote.Account.Id',
        'Quote.Account.Number_of_DL_s__c',
        'Quote.Account.RC_Account_Status__c',
        'Total_Annual__c',
        'Total_One_Time__c',
        'Product2Id',
        'Product2.ExtID__c',
        'Product2.Name',
        'Product2.Family',
        'Product2.Charge_Term__c',
        'Product2.Sub_Category__c',
        'Product2.Feature__c',
        'Product2.Sub_Feature__c',
        'Product2.Dependent_on_Feature__c',
        'Product2.CatID__c',
        'Product2.Billing_Type__c',
        'Product_Lic_Id__c',
        'Product2.GOA_Group_V3__c',
        'Product2.GOA_Group_V2__c',
        'Product2.Group__c',
        'Entitlement__c',
        'Entitlement__r.Active__c',
        'Entitlement__r.Quote__c',
        'Entitlement__r.Account__c',
        'Entitlement__r.Name',
        'Entitlement__r.Quantity__c',
        'Entitlement__r.Discount_Type__c',
        'Entitlement__r.Discount__c',
        'Entitlement__r.EffectivePrice__c',
        'Entitlement__r.EffectivePricePrecise__c',
        'Entitlement__r.ChargeTerm__c',
        'Entitlement__r.Price__c',
        'Entitlement__r.Display_Name__c',
        'Entitlement__r.PackageCatalogId__c',
        'Entitlement__r.PackageDuration__c',
        'Entitlement__r.PackageVersion__c',
        'Entitlement__r.DisplayQuantity__c',
        'Entitlement__r.Product__r.Feature__c',
        'Entitlement__r.Product__r.Charge_Term__c',
        'Entitlement__r.Product__r.Family',
        'Entitlement__c.PartnerConfig__c',
        'Package_Info__c',
        'ServiceName__c',
        'CurrencyIsoCode'
    };

    public static final Set<String> FIELDS_POC_APPROVAL = new Set<String> {
        'Id',
        'Quantity'
    };

    public static final Set<String> FIELDS_SHIPPING = new Set<String> {
        'Id',
        'Product_Lic_Id__c',
        'Product_Family__c',
        'QuoteId',
        'Package_Info_QLI__c',
        'Quote.OpportunityId',
        'Quote.AccountId',
        'Product2.Name',
        'NewQuantity__c',
        'DeliveredQuantity__c',
        'PackageInfo__c',
        'Quantity',
        'Zero_Quantity__c',
        'MasterQLI__c',
        'Product2.ShippingType__c',
        'Product2.Family',
        'Product2.ExtID__c'
    };

    public static final Set<String> FIELDS_SERVICE_QLI = new Set<String> {
        'Id',
        'QuoteId',
        'Quantity',
        'Deactivated__c',
        'Product2Id',
        'Product2.Family',
        'Product2.Feature__c',
        'Entitlement__c',
        'NewQuantity__c',
        'DeliveredQuantity__c'
    };

    public static final Set<String> FIELDS_QUOTE_SERVICE = new Set<String> {
        'Id',
        'Product2Id',
        'TotalPrice',
        'Item_type__c',
        'UnitPrice',
        'Quantity',
        'PackageInfo__c',
        'Discount_number__c',
        'Discount_type__c',
        'Display_Name__c',
        'Zero_Quantity__c',
        'CurrencyIsoCode',
        'PackageCatalogId__c',
        'PackageVersion__c',
        'EffectivePriceNew__c',
        'NewQuantity__c',
        'DeliveredQuantity__c',
        'Product2.Name',
        'Product2.ExtID__c',
        'Product2.GOA_Group_V3__c',
        'Product2.Group__c',
        'Product2.Family',
        'Product2.Feature__c',
        'Product2.Product_Type__c',
        'Product2.Billing_Type__c',
        'Product2.Subgroup__c',
        'Entitlement__r.Name',
        'Entitlement__r.Quantity__c',
        'Entitlement__r.Price__c',
        'Entitlement__r.Discount__c',
        'Entitlement__r.Discount_Type__c',
        'Entitlement__r.ChargeTerm__c',
        'Entitlement__r.PackageCatalogId__c',
        'Entitlement__r.PackageVersion__c',
        'Entitlement__r.Sort_Order__c',
        'Promotion__c',
        'Promotion__r.Promo_Code_Id__c',
        'Package_Info__c',
        'Package_Info_QLI__c',
        'ServiceName__c',
        'ParentPackageName__c',
        'Discount',
        'EffectivePrice__c'
    };

    public static final Set<String> FIELDS_SYNC_COST_CENTER = new Set<String> {
        'Product2.Name',
        'Product2.ExtID__c'
    };

    public static final Set<String> FIELDS_UPDATE_SORT_ORDER = new Set<String> {
        'Id',
        'Sort_Order__c'
    };

    public static final Set<String> FIELDS_QUOTE_AMOUNTS = new Set<String> {
        'Product_Type__c',
        'Product_Family__c',
        'Total12MonthPrice__c',
        'Product2.GOA_Group_V2__c',
        'Product2.GOA_Group_V3__c',
        'Product2.Charge_Term__c',
        'Product2.Name',
        'Product2.ExtID__c',
        'Product2.Family',
        'Product2.Billing_Type__c',
        'Product2.Group__c',
        'ServiceName__c',
        'Zero_Quantity__c',
        'ChargeTerm__c',
        'Product2Id',
        'Quantity',
        'NewQuantity__c',
        'DeliveredQuantity__c',
        'TotalPrice',
        'Charge_Term__c',
        'Delta_ARR__c',
        'Delta_MRR__c',
        'Total_One_Time__c'
    };

    public static final Set<String> FIELDS_QLI_TRIGGER = new Set<String> {
        'Billing_Cycle_Duration__c',
        'Deactivated__c',
        'Delta_ARR__c',
        'Delta_MRR__c',
        'DiscountValueNew__c',
        'Discount_number__c',
        'Discount',
        'Discount_type__c',
        'EffectivePrice__c',
        'EffectivePriceNew__c',
        'Entitlement__c',
        'Entitlement__r.ChargeTerm__c',
        'Entitlement__r.DisplayQuantity__c',
        'Entitlement__r.EffectivePrice__c',
        'Entitlement__r.EffectivePricePrecise__c',
        'Entitlement__r.Id',
        'Entitlement__r.Price__c',
        'Entitlement__r.Product__r.Charge_Term__c',
        'Entitlement__r.Quantity__c',
        'Entitlement__r.Discount_Type__c',
        'Fixed_Taxes_Amount__c',
        'Id',
        'IsHiddenLicense__c',
        'NewQuantity__c',
        'DeliveredQuantity__c',
        'Package_Info__c',
        'Package_Info_QLI__c',
        'PackageInfo__c',
        'Product2.Billing_Type__c',
        'Product2.CatId__c',
        'Product2.Charge_Term__c',
        'Product2.Family',
        'Product2.Feature__c',
        'Product2.Sub_Feature__c',
        'Product2.Name',
        'Product2.Product_Type__c',
        'Product2.Sub_Category__c',
        'Product2.CategoryName__c',
        'Product2.Group__c',
        'Product2.GOA_Group_V3__c',
        'Product2Id',
        'Quantity',
        'Quote.Account.RC_Account_Status__c',
        'Quote.Account.Active_Sales_Agreement__c',
        'Quote.Contact_Center_Entitlement_Total_ARR__c',
        'Quote.Contact_Center_Entitlement_Total_MRR__c',
        'Quote.Contact_Center_Total_ARR__c',
        'Quote.Contact_Center_Total_ARR_Discount__c',
        'Quote.Contact_Center_Total_First_Year_Cost__c',
        'Quote.Contact_Center_Total_First_Year_Discount__c',
        'Quote.Contact_Center_Total_Initial_Payment__c',
        'Quote.Contact_Center_Total_MRR__c',
        'Quote.Contact_Center_Total_MRR_Discount__c',
        'Quote.Contact_Center_Total_One_Time__c',
        'Quote.Contact_Center_Total_One_Time_Discount__c',
        'Quote.ContactCenterTotalInitialPaymentDiscount__c',
        'Quote.Delta_ARR__c',
        'Quote.Delta_CC_ARR__c',
        'Quote.Delta_CC_MRR__c',
        'Quote.Delta_MRR__c',
        'Quote.Entitlement_Common_Phones_Quantity__c',
        'Quote.Entitlement_Global_Phones_Quantity__c',
        'Quote.Entitlement_GO_LE_Phones_Quantity__c',
        'Quote.Entitlement_Limited_Phones_Quantity__c',
        'Quote.Entitlement_Rental_Phones_Quantity__c',
        'Quote.Entitlement_Total_ARR__c',
        'Quote.Entitlement_Total_MRR__c',
        'Quote.Estimated_Hardware__c',
        'Quote.IsMultiProductTechnicalQuote__c',
        'Quote.isPrimary__c',
        'Quote.OpportunityId',
        'Quote.Package_Info__c',
        'Quote.Products__c',
        'Quote.RecordTypeId',
        'Quote.Special_Terms__c',
        'Quote.Total_ARR__c',
        'Quote.Total_ARR_Discount__c',
        'Quote.Total_ARR_with_Taxes__c',
        'Quote.Total_First_Year_Cost__c',
        'Quote.Total_First_Year_Cost_with_Taxes__c',
        'Quote.Total_First_Year_Discount__c',
        'Quote.Total_Initial_Payment__c',
        'Quote.Total_Initial_Payment_Discount__c',
        'Quote.Total_Initial_Payment_with_Taxes__c',
        'Quote.Total_MRR_Discount__c',
        'Quote.Total_MRR_New__c',
        'Quote.Total_MRR_with_Taxes__c',
        'Quote.Total_Number_of_Digital_Lines__c',
        'Quote.Total_One_Time__c',
        'Quote.Total_One_Time_Discount__c',
        'Quote.Total_One_Time_with_Taxes__c',
        'Quote.CLM_Total_Initial_Payment__c',
        'Quote.TotalInitialPaymentWithoutProServ__c',
        'Quote.ProServListPrice__c',
        'Quote.ProServDiscount__c',
        'Quote.TotalQuoteSummary__c',
        'Quote.Upsell_Status__c',
        'QuoteId',
        'QuoteRecordType__c',
        'ServiceName__c',
        'Subtotal',
        'Threshold__c',
        'Total_Annual__c',
        'Total_Monthly__c',
        'Total_One_Time__c',
        'TotalInitialPrice__c',
        'TotalPrice',
        'TotalSummary__c',
        'Variable_Taxes_Amount__c',
        'Zero_Quantity__c',
        'UnitPrice',
        'Discount_Value__c',
        'Product2.Subgroup__c'
    };

    public static final Set<String> FIELDS_DQ_GOA = new Set<String> {
        'Quantity',
        'NewQuantity__c',
        'Discount',
        'Discount_type__c',
        'Discount_Value__c',
        'TotalPrice',
        'UnitPrice',
        'Promotion__c',
        'Product2Id',
        'ServiceName__c',
        'Quote.RecordTypeId',
        'Quote.IsMultiProductTechnicalQuote__c',
        'Quote.Account.Offer_Type__c',
        'Quote.Account.RC_Account_Status__c',
        'Quote.Account.Billing_ID__c',
        'Product2.Sub_Category__c',
        'Product2.GOA_Group_V2__c',
        'Product2.GOA_Group_V3__c',
        'Product2.Name',
        'Product2.Group__c',
        'Product2.Subgroup__c'
    };

    public static final Set<String> FIELDS_DQ_SYNC = new Set<String> {
        'UnitPrice',
        'Discount',
        'Promotion__c',
        'Product2Id',
        'Quantity',
        'NewQuantity__c',
        'Discount',
        'Discount_type__c',
        'QuoteId',
        'ServiceName__c',
        'Quote.RecordTypeId',
        'Quote.Account.Offer_Type__c',
        'Quote.Account.RC_Account_Status__c',
        'Quote.Account.Billing_ID__c',
        'Quote.IsMultiProductTechnicalQuote__c',
        'Product2.Sub_Category__c',
        'Product2.Goa_Group_V2__c',
        'Product2.Goa_Group_V3__c',
        'Product2.Group__c',
        'Product2.Subgroup__c',
        'Product2.Name'
    };

    public static final Set<String> FIELDS_PRICE_BOOK_ENTRY = new Set<String> {
        'PriceBookEntry.Per_Line__c',
        'PriceBookEntry.Min_Quantity__c',
        'PriceBookEntry.Max_Quantity__c'
    };

    public static final Set<String> FIELDS_ORDER_CREATION_PROCESS = new Set<String> {
        'Id',
        'Product2Id',
        'Product2.Product_Type__c',
        'Product2.UpsellType__c',
        'Product2.InitialOrderType__c',
        'PricebookEntryId',
        'PricebookEntry.Id',
        'Quantity',
        'NewQuantity__c',
        'DeliveredQuantity__c',
        'QuoteId',
        'UnitPrice',
        'EffectivePrice__c',
        'TotalPrice',
        'ChargeTerm__c',
        'Product_Lic_Id__c',
        'TotalSummary__c',
        'MasterQLI__c',
        'IsMultiProductTechnicalQLI__c',
        'Zero_Quantity__c',
        'Discount_type__c',
        'Discount_number__c',
        'Quote.Opportunity.Parent_Order__c',
        'Quote.Opportunity.Tier_Name__c',
        'Product2.Family'
    };

    public static final Set<String> FIELDS_FOR_APPROVED_FIELDS_POPULATION = new Set<String> {
        'Quantity',
        'NewQuantity__c',
        'Discount',
        'Discount_type__c',
        'Approved_Quantity__c',
        'Approved_Discount__c',
        'Approved_Discount_Type__c',
        'Discount_Value__c',
        'Entitlement__c',
        'Last_Approved_Quantity__c',
        'Last_Approved_Discount__c',
        'Last_Approved_Discount_Type__c',
        'QuoteId',
        'Quote.Approved_Status__c',
        'Quote.RecordTypeId',
        'Quote.Account.RC_User_ID__c',
        'Quote.BillingPackage__c',
        'Quote.Account.Billing_ID__c',
        'Quote.Account.Offer_Type__c',
        'Quote.Account.RC_Account_Status__c',
        'Quote.IsPRMQuote__c',
        'Quote.IsMultiProductTechnicalQuote__c',
        'Quote.PackageNameOld__c',
        'Quote.Upsell_Status__c'
    };

    private static final Set<String> FIELDS_FOR_HANDLE_BILLING_QUOTES = new Set<String> {
        'Id',
        'CurrencyIsoCode',
        'Discount',
        'ListPrice',
        'Quantity',
        'Subtotal',
        'TotalPrice',
        'UnitPrice',
        'Approved_Discount_Type__c',
        'Approved_Discount__c',
        'Approved_Quantity__c',
        'ChargeTerm__c',
        'Charge_Term__c',
        'Discount_Value__c',
        'Discount_number__c',
        'Discount_type__c',
        'EffectivePrice__c',
        'Last_Approved_Discount_Type__c',
        'Last_Approved_Discount__c',
        'Last_Approved_Quantity__c',
        'NewQuantity__c',
        'DeliveredQuantity__c',
        'PackageCatalogId__c',
        'PackageInfo__c',
        'PackageVersion__c',
        'Package_Info_QLI__c',
        'Product_Lic_Id__c',
        'Promotion__c',
        'QuoteRecordType__c',
        'ServiceName__c',
        'TotalInitialPrice__c',
        'Zero_Quantity__c',
        'Asset__c',
        'Asset__r.Discount_Number__c',
        'Asset__r.Discount_Type__c',
        'Asset__r.Unit_Price__c',
        'Entitlement__c',
        'Entitlement__r.ChargeTerm__c',
        'Entitlement__r.Discount_Type__c',
        'Entitlement__r.Discount__c',
        'Entitlement__r.PackageCatalogId__c',
        'Entitlement__r.PackageVersion__c',
        'Entitlement__r.Price__c',
        'Entitlement__r.Quantity__c',
        'Entitlement__r.Total_Annual_Price__c',
        'Entitlement__r.Total_Monthly_Price__c',
        'PriceBookEntry.Monthly_Contract_Discount__c',
        'PriceBookEntry.PriceBook2.Edition__c',
        'PriceBookEntryId',
        'Product2Id',
        'Product2.Charge_Term__c',
        'Product2.CurrencyIsoCode',
        'Product2.ExtID__c',
        'Product2.Family',
        'Product2.Feature__c',
        'Product2.GOA_Group_V2__c',
        'Product2.GOA_Group_V3__c',
        'Product2.Group__c',
        'Product2.Name',
        'Product2.Sub_Category__c',
        'Product2.Sub_Feature__c',
        'QuoteId',
        'Quote.Account_Number_of_Lines__c',
        'Quote.ActiveAgreementYears__c',
        'Quote.Approved_Status__c',
        'Quote.CurrencyIsoCode',
        'Quote.Delta_MRR__c',
        'Quote.Enabled_LBO__c',
        'Quote.FreeShippingTerms__c',
        'Quote.Initial_Term_months__c',
        'Quote.IsMultiProductTechnicalQuote__c',
        'Quote.isPrimary__c',
        'Quote.IsPRMQuote__c',
        'Quote.LastModifiedDate',
        'Quote.Level_1_Approver__c',
        'Quote.Level_2_Approver__c',
        'Quote.Level_3_Approver__c',
        'Quote.Level_4_Approver__c',
        'Quote.Level_5_Approver__c',
        'Quote.Level_6_Approver__c',
        'Quote.Level_7_Approver__c',
        'Quote.OwnerId',
        'Quote.Package_Info__c',
        'Quote.PackageNameOld__c',
        'Quote.Payment_Plan__c',
        'Quote.Pricebook2.Plan__c',
        'Quote.Pricebook2Id',
        'Quote.Products__c',
        'Quote.RecordType.DeveloperName',
        'Quote.RecordTypeId',
        'Quote.Shipping_Option__c',
        'Quote.Special_Terms__c',
        'Quote.Status',
        'Quote.Term_months__c',
        'Quote.Upsell_Status__c',
        'Quote.AccountId',
        'Quote.Account.BillingCountry',
        'Quote.Account.Billing_ID__c',
        'Quote.Account.ELA_Account_Type__c',
        'Quote.Account.Offer_Type__c',
        'Quote.Account.RC_Account_Status__c',
        'Quote.Account.RC_User_ID__c',
        'Quote.OpportunityId',
        'Quote.Opportunity.Account.Active_Sales_Agreement__c',
        'Quote.Opportunity.Account.Active_Sales_Agreement__r.Status',
        'Quote.Opportunity.Brand_Name__c',
        'Quote.Opportunity.Owner.SegmentPicklist__c',
        'Quote.Opportunity.OwnerId',
        'Quote.Opportunity.Type',
        'Quote.Opportunity.Parent_Order__c',
        'Quote.Opportunity.Tier_Name__c',
        'Quote.BillingPackage__c'
    };

    public QuoteLineItemSelector() {
        super();
    }

    public QuoteLineItemSelector(String relationshipName, SObjectType relationshipBase) {
        super(relationshipName, relationshipBase);
    }

    public QuoteLineItemSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return QuoteLineItem.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            QuoteLineItem.Id
        };
    }

    public List<String> getParentFields() {
        return new List<String>{
            'Product2.Sub_Category__c',
            'Product2.Feature__c',
            'Product2.Family',
            'Entitlement__c',
            'Quantity',
            'QuoteId',
            'Quote.Account.Number_of_DL_s__c',
            'Entitlement__r.Active__c',
            'Product2.Dependent_on_Feature__c',
            'Product2.Charge_Term__c',
            'Entitlement__r.DisplayQuantity__c',
            'Entitlement__r.Discount__c',
            'Entitlement__r.Discount_Type__c',
            'Discount_number__c',
            'Discount_type__c',
            'Zero_Quantity__c',
            'NewQuantity__c',
            'DeliveredQuantity__c',
            'ChargeTerm__c',
            'Charge_Term__c',
            'PackageInfo__c',
            'Package_Info__c',
            'Package_Info_QLI__c'
        };
    }

    public List<String> getFieldsForSync() {
        return new List<String>(FIELDS_SYNC);
    }

    public List<String> getFieldsForQLIsByQuote() {
        return new List<String>(FIELDS_QLI_BY_QUOTE);
    }

    public List<String> getFieldsForPOCApproval() {
        return new List<String>(FIELDS_POC_APPROVAL);
    }

    public List<String> getFieldsForShipping() {
        return new List<String>(FIELDS_SHIPPING);
    }

    public List<String> getServiceQliFields() {
        return new List<String>(FIELDS_SERVICE_QLI);
    }

    public List<String> getFieldsForQuoteService() {
        return new List<String>(FIELDS_QUOTE_SERVICE);
    }

    public List<String> getFieldsForSyncCostCenterLineItems() {
        return new List<String>(FIELDS_SYNC_COST_CENTER);
    }

    public List<String> getFieldsForUpdateSortOrder() {
        return new List<String>(FIELDS_UPDATE_SORT_ORDER);
    }

    public List<String> getFieldsForQuoteAmounts() {
        return new List<String>(FIELDS_QUOTE_AMOUNTS);
    }

    public List<String> getFieldsForDqGoa() {
        return new List<String>(FIELDS_DQ_GOA);
    }

    public List<String> getFieldsForDqSync() {
        return new List<String>(FIELDS_DQ_SYNC);
    }

    public List<String> getFieldsForOrderCreationProcess() {
        return new List<String>(FIELDS_ORDER_CREATION_PROCESS);
    }

    public QueryFactory selectQuoteLineItemsForQuoteAmounts() {
        return newQueryFactory()
            .setFactoryName('selectQuoteLineItemsForQuoteAmounts')
            .selectFields(getFieldsForQuoteAmounts())
            .withoutSelectorOrderByIncluded();
    }

    public QueryFactory selectQuoteLineItemsForSyncWithNGBS() {
        return newQueryFactory()
            .setFactoryName('selectQuoteLineItemsForSyncWithNGBS')
            .selectFields(getFieldsForSync())
            .withoutSelectorOrderByIncluded();
    }

    public QueryFactory selectQuoteLineItemsForSyncPaymentMethod(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectQuoteLineItemsForSyncPaymentMethod')
            .selectFields(getFieldsForSync())
            .withoutSelectorOrderByIncluded()
            .setCondition('QuoteId = :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectQuoteLineItems() {
        return newQueryFactory()
            .setFactoryName('selectQuoteLineItems')
            .selectFields(getParentFields());
    }

    public QueryFactory selectQuoteLineItemsForSignUp() {
        return newQueryFactory()
            .setFactoryName('selectQuoteLineItemsForSignUp')
            .selectFields(getFieldsForSync());
    }

    public QueryFactory selectQuoteLineItemsForPOCApproval() {
        return newQueryFactory()
            .setFactoryName('selectQuoteLineItemsForPOCApproval')
            .selectFields(getFieldsForPOCApproval())
            .setCondition('Product_Family__c LIKE \'%Phone%\'');
    }

    public QueryFactory selectNonZeroQuoteLineItems() {
        return newQueryFactory()
            .setFactoryName('selectNonZeroQuoteLineItems')
            .selectFields(new List<String>{
                'Id',
                'Product2Id',
                'Product2.Product_Type__c',
                'PricebookEntryId',
                'PricebookEntry.Id',
                'Quantity',
                'NewQuantity__c',
                'DeliveredQuantity__c',
                'QuoteId',
                'UnitPrice',
                'TotalPrice',
                'ChargeTerm__c',
                'Product_Lic_Id__c',
                'TotalSummary__c',
                'MasterQLI__c',
                'IsMultiProductTechnicalQLI__c'
            })
            .setCondition('Zero_Quantity__c = false');
    }

    public QueryFactory selectQuoteLineItems(
        Id quoteId,
        List<Id> qliIds
    ) {
        return selectQuoteLineItems(new List<Id> { quoteId }, qliIds);
    }

    public QueryFactory selectQuoteLineItems(
        List<Id> quoteIds,
        List<Id> qliIds
    ) {
        List<String> conditions = new List<String>();
        List<Object> bindings = new List<Object>();

        if (quoteIds != null && !quoteIds.isEmpty()) {
            if (quoteIds.size() == 1) {
                conditions.add('QuoteId = :bind0');
                bindings.add(quoteIds.get(0));
            } else {
                conditions.add('QuoteId IN :bind0');
                bindings.add(quoteIds);
            }
        }

        if (qliIds != null && !qliIds.isEmpty()) {
            conditions.add('Id IN :bind0');
            bindings.add(qliIds);
        }


        return newQueryFactory()
            .setFactoryName('selectQuoteLineItemsByQuoteIdsQliIds')
            .selectFields(AquivaHelper.getAllFieldsForObject('QuoteLineItem'))
            .selectFields(FIELDS_QUOTE)
            .selectFields(FIELDS_QUOTE_OPPORTUNITY)
            .selectFields(FIELDS_PRODUCT)
            .selectFields(FIELDS_ENTITLEMENTS)
            .setCondition(String.join(conditions, ' AND '))
            .setQueryBindings(bindings);
    }

    public QueryFactory selectQuoteLineItemsByIds(
        List<Id> qliIds
    ) {
        return newQueryFactory()
            .setFactoryName('selectQuoteLineItemsByIds')
            .selectFields(AquivaHelper.getAllFieldsForObject('QuoteLineItem'))
            .selectFields(FIELDS_STANDARD)
            .selectFields(FIELDS_QUOTE)
            .selectFields(FIELDS_QUOTE_OPPORTUNITY)
            .selectFields(FIELDS_PRODUCT)
            .selectFields(FIELDS_NGBS)
            .selectFields(FIELDS_MULTI_PRODUCT)
            .selectFields(FIELDS_ENTITLEMENTS)
            .setCondition('Id IN :bind0')
            .setQueryBindings(new List<Object> { qliIds });

    }
    public QueryFactory selectQuoteLineItemsByQuoteIdsForShipping(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectQuoteLineItemsByQuoteIdsForShipping')
            .selectFields(getFieldsForShipping())
            .subselect(
                new CustomAddressAssignmentsSelector()
                    .selectCustomAddressAssignments()
            )
            .subselect(
                new CostCenterLineItemSelector()
                    .selectCostCentersLineItemsData()
            )
            .subselect(
                new AreaCodeLineItemSelector()
                    .selectAreaCodeLineItemsWithAreaCodes()
            )
            .setCondition('(Id IN :bind0 OR QuoteId IN :bind0) AND Zero_Quantity__c = false')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectQuoteLineItemsForSyncCostCenterLineItems(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectQuoteLineItemsForSyncCostCenterLineItems')
            .selectFields(getFieldsForSyncCostCenterLineItems())
            .setCondition('QuoteId = :bind0 AND Product2.ExtID__c IN :bind1')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectQuoteLineItemsByIdWithAreaCodes(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectQuoteLineItemsByIdWithAreaCodes')
            .selectFields(getFieldsForShipping())
            .subselect(
                new AreaCodeLineItemSelector()
                    .selectAreaCodeLineItemsWithAreaCodes()
            )
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectQuoteLineItemsWithCostCenterLineItems(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectQuoteLineItemsWithCostCenterLineItems')
            .selectFields(getFieldsForSync())
            .subselect(
                new CostCenterLineItemSelector()
                    .selectCostCentersLineItemsData()
            )
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectQuoteLineItemsForUpdateSortOrder(Set<Id> bindings) {
        return newQueryFactory()
            .setFactoryName('selectQuoteLineItemsForUpdateSortOrder')
            .selectFields(getFieldsForUpdateSortOrder())
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectServiceQlisByQuoteIds(Set<Id> quoteIdSet) {
        Set<Decimal> featureSet = new Set<Decimal>{
            Product2Helper.FEATURE_SERVICE_PLAN,
            Product2Helper.FEATURE_SERVICE_PLAN_FAX
        };
        return newQueryFactory()
            .setFactoryName('selectServiceQlisByQuoteIds')
            .selectFields(getServiceQliFields())
            .setCondition('QuoteId IN :bind0 AND (Product2.Feature__c IN :bind1) AND Product2.Family = :bind2')
            .setQueryBindings(new List<Object>{
                quoteIdSet,
                featureSet,
                Product2Helper.FAMILY_SERVICE
            });
    }

    public QueryFactory selectQuoteLineItemsByOrderId(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectQuoteLineItemsByOrderId')
            .selectFields(new List<String>{
                'Id',
                'Product2Id',
                'UnitPrice',
                'EffectivePrice__c',
                'Discount_Type__c',
                'Discount_Number__c',
                'Entitlement__c',
                'PricebookEntryId',
                'BillingStatus__c',
                'Deactivated__c',
                'Threshold__c'
            })
            .setCondition('QuoteId IN (SELECT QuoteId FROM Order WHERE Id = :bind0)')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectQuoteLineItemsForQuoteService(){
        return this.selectQuoteLineItems()
            .setFactoryName('selectQuoteLineItemsForQuoteService')
            .selectFields(getFieldsForQuoteService());
    }

    public QueryFactory selectQuoteLineItemsForCloning(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectQuoteLineItemsForCloning')
            .selectFields(AquivaHelper.getAllFieldsForObject('QuoteLineItem'))
            .setCondition('QuoteId = :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectQuoteLineItemsByQuoteIdsForCloning(Id quoteId) {
        return selectQuoteLineItemsByQuoteIdsForCloning(new List<Id> { quoteId });
    }

    public QueryFactory selectQuoteLineItemsByQuoteIdsForCloning(List<Id> quoteIds) {
        return newQueryFactory()
            .setFactoryName('selectQuoteLineItemsByQuoteIdsForCloning')
            .selectFields(AquivaHelper.getAllFieldsForObject('QuoteLineItem'))
            .selectFields(FIELDS_QUOTE)
            .selectFields(FIELDS_QUOTE_OPPORTUNITY)
            .selectFields(FIELDS_PRODUCT)
            .setCondition('QuoteId IN :bind0')
            .setQueryBindings(new List<Object> { quoteIds });
    }

    public QueryFactory selectQuoteLineItemsByQuoteIds(Id quoteId) {
        return selectQuoteLineItemsByQuoteIds(new List<Id> { quoteId });
    }

    public QueryFactory selectQuoteLineItemsByQuoteIds(Set<Id> quoteIds) {
        return selectQuoteLineItemsByQuoteIds(new List<Id>(quoteIds));
    }

    public QueryFactory selectQuoteLineItemsByQuoteIds(List<Id> quoteIds) {
        return newQueryFactory()
            .setQueryBindings('selectQuoteLineItemsByQuoteId')
            .selectFields(FIELDS_ID)
            .selectFields(FIELDS_QLI_BY_QUOTE)
            .setCondition('QuoteId IN :bind0')
            .setQueryBindings(new List<Object> { quoteIds });
    }

    public QueryFactory selectQuoteLineItemsByQuoteIdsToPopulateApprovedFields(Set<Id> quoteIds) {
        return selectQuoteLineItemsByQuoteIdsToPopulateApprovedFields(new List<Id>(quoteIds));
    }

    public QueryFactory selectQuoteLineItemsByQuoteIdsToPopulateApprovedFields(List<Id> quoteIds) {
        return newQueryFactory()
            .setQueryBindings('selectQuoteLineItemsByQuoteIdsToPopulateApprovedFields')
            .selectFields(FIELDS_ID)
            .selectFields(FIELDS_FOR_APPROVED_FIELDS_POPULATION)
            .setCondition('QuoteId IN :bind0')
            .setQueryBindings(new List<Object> { quoteIds });
    }

    public QueryFactory selectQuoteLineItemsByQuoteIdsForBilling(Id quoteId) {
        return selectQuoteLineItemsByQuoteIdsForBilling(new List<Id> { quoteId });
    }

    public QueryFactory selectQuoteLineItemsByQuoteIdsForBilling(List<Id> quoteIds) {
        return selectQuoteLineItemsByQuoteIds(quoteIds)
            .setFactoryName('selectQuoteLineItemsByQuoteIdsForBilling')
            .selectFields(FIELDS_NGBS)
            .selectFields(FIELDS_MULTI_PRODUCT)
            .selectFields(FIELDS_PRODUCT)
            .selectFields(FIELDS_STANDARD);
    }

    public QueryFactory selectQuoteLineItemsForQLITrigger(Set<Id> bindings) {
        return newQueryFactory()
            .setFactoryName('selectQuoteLineItemsForQLITrigger')
            .selectFields(FIELDS_QLI_TRIGGER)
            .setCondition('QuoteId IN :bind0')
            .setQueryBindings(new List<Object>{ bindings });
    }

    public QueryFactory selectQuoteLineItemsForDqGoa() {
        return newQueryFactory()
            .setFactoryName('selectQuoteLineItemsForDqGoa')
            .setCondition('Discount > 0 AND IsHiddenLicense__c = false')
            .selectFields(getFieldsForDqGoa());
    }

    public QueryFactory selectQuoteLineItemsForDqSync() {
        return newQueryFactory()
            .setFactoryName('selectQuoteLineItemsForDqSync')
            .setCondition('IsHiddenLicense__c = false')
            .selectFields(getFieldsForDqSync());
    }

    public QueryFactory selectQuoteLineItemsByMasterQliIds(Set<Id> masterIds) {
        return newQueryFactory()
            .setQueryBindings('selectQuoteLineItemsByMasterQliIds')
            .selectFields(FIELDS_MULTI_PRODUCT)
            .setCondition('MasterQLI__c IN :bind0')
            .setQueryBindings(new List<Object> { masterIds });
    }

    public QueryFactory selectTechQuoteLineItemsByMasterQuoteIdsForShipping(Set<Id> qliIds) {
        return newQueryFactory()
            .setFactoryName('selectTechQuoteLineItemsByMasterQuoteIdsForShipping')
            .selectFields(new List<String>{'Id', 'MasterQLI__c'})
            .subselect(
                new CustomAddressAssignmentsSelector()
                    .selectCustomAddressAssignments()
            )
            .setCondition('MasterQLI__c IN :bind0')
            .setQueryBindings(new List<Object> { qliIds });
    }

    public QueryFactory selectQuoteLineItemsByQuoteIdsAndByProductFamilyName(Set<Id> quoteIds, String productFamilyName) {
        return newQueryFactory()
            .setFactoryName('selectQuoteLineItemsByQuoteIdsAndByProductName')
            .selectFields(new List<String> {
                'Id',
                'NewQuantity__c',
                'DeliveredQuantity__c',
                'Quantity',
                'Product2Id',
                'QuoteId',
                'EffectivePrice__c',
                'QuoteRecordType__c',
                'PackageInfo__c',
                'Quote.RecordTypeId',
                'Product2.Charge_Term__c'
            })
            .setCondition('QuoteId IN :bind0 AND Product2.Family = :bind1')
            .setQueryBindings(new List<Object> {quoteIds,  productFamilyName});
    }

    public QueryFactory selectQuoteLineItemsWithTierOrServiceProductByQuoteIds(Set<Id> quoteIds) {
        return newQueryFactory()
            .setFactoryName('selectQuoteLineItemsByQuoteIdsAndByProductName')
            .selectFields(FIELDS_QLI_BY_QUOTE)
            .selectFields(FIELDS_PRICE_BOOK_ENTRY)
            .setCondition(
                'QuoteId IN :bind0 AND (Product2.Family = \''
                + Product2Helper.FAMILY_TIER + '\' OR Product2.Family = \''
                + Product2Helper.FAMILY_SERVICE + '\' OR PriceBookEntry.Per_Line__c = true)'
            )
            .setQueryBindings(new List<Object> {quoteIds});
    }

    public QueryFactory selectQuoteLineItemsWithCustomAddressAssignments(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectQuoteLineItemsWithCustomAddressAssignments')
            .selectFields(getFieldsForShipping())
            .subselect(
                new CustomAddressAssignmentsSelector()
                    .selectCustomAddressAssignments()
            )
            .setCondition('QuoteId IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectQuoteLineItemsForOrderCreationProcess() {
        return newQueryFactory()
            .setFactoryName('selectQuoteLineItemsForOrderCreationProcess')
            .selectFields(getFieldsForOrderCreationProcess());
    }

    public QueryFactory selectQuoteLineItemsByQuoteIdAndProductLic(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectQuoteLineItemsQuoteAndProductLic')
            .selectFields(FIELDS_QLI_BY_QUOTE)
            .setCondition('QuoteId IN :bind0 AND Product_Lic_Id__c IN :bind1')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectQuoteLineItemsByQuoteIdAndServiceName(Set<Id> quoteIds, String serviceName) {
        return newQueryFactory()
            .setFactoryName('selectQuoteLineItemsByQuoteIdAndServiceName')
            .selectFields(FIELDS_STANDARD)
            .setCondition('QuoteId IN :bind0 AND ServiceName__c = :bind1 AND Item_Type__c != \'Tax\'')
            .setQueryBindings(new List<Object> {quoteIds, serviceName});
    }

    public QueryFactory selectQuoteLineItemsForQuoteApprovals() {
        return newQueryFactory()
            .setFactoryName('selectQuoteLineItemsForQuoteApprovals')
            .selectFields(FIELDS_FOR_HANDLE_BILLING_QUOTES)
            .subselect(
                new CustomAddressAssignmentsSelector()
                    .newQueryFactory()
                    .withoutSelectorFieldsIncluded()
                    .selectFields(new List<SObjectField> {
                        CustomAddressAssignments__c.Id,
                        CustomAddressAssignments__c.ShippingLicenseTree__c,
                        CustomAddressAssignments__c.Type__c
                    })
            )
            .withoutSelectorOrderByIncluded();
    }

    public QueryFactory selectQuoteLineItemsForHandleBillingQuotes(Set<Id> oppIdSet, Set<Id> qliToDeleteIdSet) {
        Boolean isFilterByQliToDelete = qliToDeleteIdSet != null && !qliToDeleteIdSet.isEmpty();
        List<Object> bindings = new List<Object> {
            oppIdSet,
            new Set<Id> { QuoteHelper.RT_ID_BILLING, QuoteHelper.RT_ID_CC }
        };
        QueryFactory factory = selectQuoteLineItemsForQuoteApprovals()
            .setCondition('Quote.OpportunityId IN :bind0 AND Quote.RecordTypeId IN :bind1');
        if (isFilterByQliToDelete) {
            factory.addCondition('Id NOT IN :bind2');
            bindings.add(qliToDeleteIdSet);
        }
        return factory.setQueryBindings(bindings);
    }

    public QueryFactory selectQuoteLineItemsForHandleQuotes(Set<Id> quoteIdSet, Set<Id> qliToDeleteIdSet) {
        Boolean isFilterByQliToDelete = qliToDeleteIdSet != null && !qliToDeleteIdSet.isEmpty();
        List<Object> bindings = new List<Object> {quoteIdSet};
        QueryFactory factory = selectQuoteLineItemsForQuoteApprovals()
            .setCondition('QuoteId IN :bind0');
        if (isFilterByQliToDelete) {
            factory.addCondition('Id NOT IN :bind1');
            bindings.add(qliToDeleteIdSet);
        }
        return factory.setQueryBindings(bindings);
    }

    public QueryFactory selectQuoteLineItemsByExtIdAndQuoteId(Set<String> catalogIds, Id quoteId) {
        return newQueryFactory()
            .setFactoryName('selectQuoteLineItemsByExtIdAndQuoteId')
            .selectFields(new List<String>{
                'Id',
                'Product2.ExtID__c',
                'QuoteId'
            })
            .setCondition('Product2.ExtID__c IN :bind0 AND QuoteId = :bind1')
            .setQueryBindings(new List<Object>{catalogIds, quoteId});
    }

    public QueryFactory selectQuoteLineItemsForAreaCodeSync(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectQuoteLineItemsForAreaCodeSync')
            .selectFields(new List<String>{
                'Id',
                'QuoteId',
                'Product_Lic_Id__c'
            })
            .setCondition('QuoteId IN :bind0 AND Product_Lic_Id__c != null')
            .setQueryBindings(bindings);
    }
}