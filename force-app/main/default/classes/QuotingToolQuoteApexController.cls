public without sharing class QuotingToolQuoteApexController {

    public static final String PROD_ORG_ID = HardcodedIdsMapper.getMatchedObjectId('00D80000000aRUXEA2');
    public static final String REGULAR_WIZARD_NAME = 'Regular Quoting Wizard';
    public static final String BILLING_WIZARD_NAME = 'Quote Tool 2.0';

    private static final String QUOTE_ACTIVE_STATUS_NAME = 'Active';

    private static final String SALES_QUOTE_RT_NAME = 'Sales Quote';
    private static final String PROSERV_QUOTE_RT_NAME = 'ProServ Quote';
    private static final String CC_PROSERV_QUOTE_RT_NAME = 'CC ProServ Quote';

    private static final Map<String, Schema.RecordTypeInfo> QUOTE_RT_INFO_BY_NAME =
            Quote.SObjectType.getDescribe().getRecordTypeInfosByName();

    private static final Map<Id, Schema.RecordTypeInfo> QUOTE_RT_INFO_BY_ID =
            Quote.SObjectType.getDescribe().getRecordTypeInfosById();

    private static final Id SALES_QUOTE_RT_ID = QUOTE_RT_INFO_BY_NAME.get(SALES_QUOTE_RT_NAME).getRecordTypeId();
    private static final Id PROSERV_QUOTE_RT_ID = QUOTE_RT_INFO_BY_NAME.get(PROSERV_QUOTE_RT_NAME).getRecordTypeId();
    private static final Id CC_PROSERV_QUOTE_RT_ID = QUOTE_RT_INFO_BY_NAME.get(CC_PROSERV_QUOTE_RT_NAME).getRecordTypeId();

    private static final String PROSERV_GROUP = 'Professional Services';
    private static final String CC_PROSERV_GROUP = 'CC Professional Services';

    private static final String PROSERV_PRODUCT_SUBCATEGORY = 'Professional Services';
    private static final String CC_PROSERV_PRODUCT_SUBCATEGORY = 'CC Professional Services';

    private static final String SYNCED_PROSERV_STATUS = 'Synced';
    private static final String IN_PROGRESS_PROSERV_STATUS = 'In progress';

    public static final String PROSERV_EMAILS_CUSTOM_SETTING_NAME = 'proservsow';
    public static final String CC_PROSERV_EMAILS_CUSTOM_SETTING_NAME = 'ccproserv';
    public static final String ITEM_TYPE_PROSERV = 'Proserv';
    private static final String PRODUCT_CHARGETERM_ONETIME = 'One - Time';

    private static final String FIXED_TAX = 'fixed';
    private static final String VARIABLE_TAX = 'variable';

    // Approval
    private static final Set<String> PENDING_APPROVAL_STATUSES = new Set<String>{
            'Pending L1 Approval',
            'Pending L2 Approval',
            'Pending L3 Approval',
            'Pending L4 Approval',
            'Pending L5 Approval'
    };
    private static final Set<String> PRE_APPROVAL_STATUSES = new Set<String>{
            'Required', 'Recalled', 'Rejected'
    };
    private static final Set<String> POST_APPROVAL_STATUSES = new Set<String>{
            'Approved'
    };
    private static final String APPROVED_QUOTE_STATUS = 'Approved';

    private static final Decimal DIGITALLINE_HOT_DESKING_FEATURE = 50;
    private static final String COMMON_PHONES_FAMILY = 'Common Phones';

    // (CC) ProServ Types
    public static final String PROSERV = 'ProServ';
    public static final String CC_PROSERV =  'CCProServ';

    // Fields to retrieve from Quote to QW
    public static final String QUOTE_FIELDS = 'Id, '
        + 'AccountId, Account.Name, Account.RC_Tier_ID__c, Account.BillingPostalCode, Account.BillingCity, Account.Billing_ID__c, Account.Billing_System__c, '
        + 'Account.BillingCountry, Account.BillingState, Account.BillingStreet, Account.CCOveragePremiumDiscount__c, Account.Partner_Contact__c, OpportunityId, '
        + 'Opportunity.Name, Opportunity.StageName, Opportunity.Parent_Order__c, Account.RC_User_ID__c, Opportunity.Owner.Email, Opportunity.Owner.SegmentPicklist__c, '
        + 'Name, Status, QuoteNumber, IsSyncing, ExpirationDate, Tax, ShippingHandling, Start_Date__c, '
        + 'End_Date__c, Term_months__c, Initial_Term_months__c, Billing_Zip_Postal_Code__c, '
        + 'Billing_City__c, Billing_Country__c, Billing_State_Province__c, Billing_Street__c, Taxes_Response__c, '
        + 'Pricebook2Id, Pricebook2.Tier_ID__c, Annual_Contact_Center_Fixed_Taxes__c, Annual_Contact_Center_Variable_Taxes__c, '
        + 'Pricebook2.Name, Pricebook2.Line_Range_Max__c, Pricebook2.Line_Range_Min__c, Pricebook2.Plan__c, '
        + 'Pricebook2.Service__c, Pricebook2.Edition__c, Pricebook2.IsActive, Pricebook2.Brand__r.Name, '
        + 'Total_Number_of_Digital_Lines__c, CurrencyIsoCode, LastModifiedDate, Approved_Status__c, '
        + 'Credit_Amount__c, ContactId, Contact.Name, First_Year_Cost_of_Service__c, Special_Terms__c, '
        + 'First_Year_Discount__c, TotalPrice, Totalpricewith0__c, Initial_Discount__c, '
        + 'Monthly_Recurring_Revenue__c, Auto_Renewal__c, JustificationandDescription__c, '
        + 'Upsell_Status__c, QuoteType__c, Approval_Type__c, CreatedBy.Id, LastModifiedBy.Name, '
        + 'InvalidDiscountedPhonesQuantity__c, InvalidLimitedExtensionPhonesQuantity__c, isPrimary__c, '
        + 'InvalidGlobalOfficePhonesQuantity__c, MonthlyContractDiscount__c, Opportunity_Owner__c, '
        + 'Level_1_Approver__r.Id, Level_1_Approver__r.Name, Level_1_Approver__r.Hierarchy_Role__c, '
        + 'Level_2_Approver__r.Id, Level_2_Approver__r.Name, Level_2_Approver__r.Hierarchy_Role__c, '
        + 'Level_3_Approver__r.Id, Level_3_Approver__r.Name, Level_3_Approver__r.Hierarchy_Role__c, '
        + 'Level_4_Approver__r.Id, Level_4_Approver__r.Name, Level_4_Approver__r.Hierarchy_Role__c, '
        + 'Level_5_Approver__r.Id, Level_5_Approver__r.Name, Level_5_Approver__r.Hierarchy_Role__c, '
        + 'Level_6_Approver__r.Id, Level_6_Approver__r.Name, Level_6_Approver__r.Hierarchy_Role__c, '
        + 'Level_7_Approver__r.Id, Level_7_Approver__r.Name, Level_7_Approver__r.Hierarchy_Role__c, '
        + 'First_Year_Total_Cost_excluding_Taxes__c, Initial_Payment__c, Products__c, Package_Info__c, '
        + 'RecordType.Name, RecordTypeId, Invalid_GO_LE_Phones_Quantity__c, Free_Service_Taxes__c, '
        + 'ProServ_Details__c, Quote_Description__c, ProServ_Status__c, ProServ_Type__c, Number_of_ProServ_Phases__c, '
        + 'ProServ_Forecast_Category__c, ProServ_Forecasted_Close_Date__c, ProServUsers__c, '
        + 'Number_of_Hardware_Shipment_Phases__c, FaxAreaCode__c, FaxAreaCode__r.Type__c, '
        + 'FaxAreaCode__r.Name, AreaCode__c, AreaCode__r.Type__c, AreaCode__r.Name, Errors__c, '
        + 'Main_Vanity_Number__c, Fax_Vanity_Number__c, Invalid_Number_of_800_Setups__c, '
        + 'Special_TOS_Approval__c, Special_TOS_Approval__r.Ask_By_Customer__c, '
        + 'Special_TOS_Approval__r.Accomodations__c, Special_TOS_Approval__r.Add_ons__c, '
        + 'Special_TOS_Approval__r.Feature_Add_ons__c, Special_TOS_Approval__r.Type__c,'
        + 'Special_TOS_Approval__r.Contract_Link__c, Invalid_Number_of_Int_TF_Setups__c, '
        + 'Invalid_Number_of_Vanity_Setups__c, Required_Area_Codes_are_empty__c, '
        + 'Account.Active_Sales_Agreement__c, Account.Term_months__c, Estimated_Taxes_Request_Failed__c, '
        + 'sumProServOneTime__c, ProServProjectManager__c, ProServSalesRep__c, ProServSOWDiscount__c, '
        + 'Signed_SOW__c, Pricebook2.AllowedRecordType__c, Pricebook2.ExtID__c, Address_Line__c, City__c, State__c, Postal_Code__c, Country__c, '
        + 'Address_Validated__c, Quote_is_Invalid__c, SOW_Type__c, Original_SOW_Quote_Number__c, Ship_Attention_To__c, '
        + 'Shipping_Country__c, Shipping_City__c, Shipping_State__c, Shipping_Address_Line__c, '
        + 'Shipping_Postal_Code__c, Shipping_Additional_Address_Line__c, Shipping_Customer_Name__c, '
        + 'Shipping_Option__c, Opportunity.ProvisioningDetails__c, MultipleShippingLocations__c, '
        + 'Total_First_Year_Cost__c, Total_First_Year_Discount__c, Total_Initial_Payment__c, '
        + 'Total_One_Time__c, Total_One_Time_Discount__c, PSOfferType__c, PSProjectComplexity__c, '
        + 'Total_Initial_Payment_Discount__c, Total_MRR__c, Total_MRR_New__c, OwnerId, IsNewGOAEnabled__c, IsPRMQuote__c, '
        + 'T_E__c, TotalProjectHoursQuoted__c, Opportunity.SelfProvisioned__c , ASA_Owner__c, PS_Segment__c, Signed_COD__c, JD_GOA__c, '
        + 'BusinessIdentity__c, Brand__c, UID_from_biz__c, Note_To_Customer__c, PSMonthlyRecurringServicesValueARR__c, ProservLevelApprover__c ';

    // fields to retrieve from Quote Line Item to QW
    public static final String QUOTE_LINE_ITEMS_FIELDS = 'Id, QuoteId, PricebookEntryId, Product2.Family, Product2.Cart_Tab_Availability__c, '
        + 'Approved_Quantity__c, Approved_Discount__c, Approved_Discount_Type__c, Product2.GOA_Group_V2__c, '
        + 'Last_Approved_Quantity__c, Last_Approved_Discount__c, Last_Approved_Discount_Type__c, '
        + 'Product2.Name, Product2.IsActive, Product2.Charge_Term__c, Product2.CatID__c, Discount_Value__c, '
        + 'Product2.Dependent_on_Feature__c, Product2Id, Product2.Feature__c, Product2.Sub_Feature__c, '
        + 'Quantity, UnitPrice, Description, CurrencyIsoCode, Discount, Discount_type__c,'
        + 'Discount_number__c, TotalPrice, TotalInitialPrice__c, Subtotal, Disabled__c, '
        + 'PriceBookEntry.Pricebook2Id, Product2.Sub_Category__c, Zero_Quantity__c, Deactivated__c, '
        + 'PriceFromEntitlement__c, Product_Type__c, Product2.Product_Type__c, Product2.Edition__c, '
        + 'Product2.Supported_Countries__c, Product2.Matcher_Formula__c, Entitlement__c, '
        + 'Entitlement__r.Quantity__c, Entitlement__r.Active__c, Entitlement__r.Discount_Type__c, '
        + 'Entitlement__r.Discount__c, Entitlement__r.Price__c, Entitlement__r.DisplayQuantity__c, '
        + 'DeactivatedItemsByQli__c, Provisioned_by_inContact__c, BillingStatus__c, NewQuantity__c, '
        + 'Product2.Seat_Range_Min__c, Product2.IsLimitedToQtyOne__c, Product2.Seat_Range_Max__c, Quote.RecordType.Name, '
        + 'Asset__r.Delivered_Quantity__c, Asset__r.Quantity, EffectivePrice__c, QuoteRecordType__c, '
        + 'ListPrice, Asset__r.Discount_Type__c, Asset__r.Discount_Number__c, Asset__r.Unit_Price__c, '
        + 'Quote.RecordTypeId, Qty_No_Decimal__c, Product2.ExtID__c, EffectivePriceNew__c, '
        + 'Product2.Custom_Permission_Set__c, Quote.Initial_Term_months__c, Product2.Warning_Message__c ';

    /**
     * Creates Quote
     * Applies Service Plan
     */
    @AuraEnabled
    public static String saveQuote(Map<String, String> params) {
        return saveQuote(params, true).Id;
    }

    /**
     * Get New Change Order Feature Toggle
     */
    @AuraEnabled
    public static Boolean getIsNewChangeOrder() {
        Feature_Toggle__c featureToggleSetting = Feature_Toggle__c.getInstance();
        return featureToggleSetting.NewChangeOrderFlow__c;
    }
    @AuraEnabled
    public static boolean isAllowedtoEditDiscount(){
        return System.label.Profiles_to_edit_Discount.contains(Userinfo.getProfileId());
    }

    public static Quote saveQuote(Map<String, String> params, Boolean isDMLsNeeded) {
        System.debug('params=' + params);
        Quote quote = new Quote();

        String pricebook2Id = params.get('pricebook2Id');
        String quoteId = params.get('quoteId');
        String lines = params.get('lines');
        String opportunityId = params.get('opportunityId');
        String upsellStatus = params.get('upsellStatus');
        String recordTypeId = params.get('recordTypeId');
        String proServDetails = params.get('proServDetails');
        String isCcParam = params.get('isCC');
        Boolean isCC;
        try {
            isCC = String.isNotBlank(isCcParam) && OpportunityHelper.TIER_CONTACT_CENTER.equalsIgnoreCase(isCcParam)
                   || Boolean.valueOf(isCcParam);
        } catch (Exception e) {
            isCC = false;
            System.debug('\'isCC\' param isn\'t populated correctly');
        }

        Pricebook2 tr = [
            SELECT Id, Name, CurrencyIsoCode, Brand__r.Name, Service__c, Line_Range_Min__c
            FROM Pricebook2
            WHERE Id = :pricebook2Id
        ].get(0);

        Opportunity opportunity = [
            SELECT Id, Name, Account.RC_User_ID__c, AccountId, Brand_Name__c, Tier_Name__c, (SELECT QuotePosition__c FROM Quotes)
            FROM Opportunity
            WHERE Id = :opportunityId
        ];

        List<Entitlement__c> entitlements = getEntitlements(opportunity.AccountId);

        if (String.isNotBlank(quoteId)) {
            quote.Id = quoteId;
        } else {
            // Set Quote position and Name
            String quoteNameRecordType = '';
            if (String.isBlank(recordTypeId)) {
                recordTypeId = (isCC
                               ? QuoteHelper.RT_ID_CC
                               : tr.Brand__r.Name == OpportunityHelper.BRAND_BT_BUSINESS
                                 && (String.isBlank(tr.Service__c)
                                    || OpportunityHelper.TIER_BT_OFFICE.equalsIgnoreCase(tr.Service__c))
                                       ? PROSERV_QUOTE_RT_ID
                                       : SALES_QUOTE_RT_ID);

                if (recordTypeId == QuoteHelper.RT_ID_CC) {
                    quoteNameRecordType = ' (' + QuoteHelper.RT_NAME_CONTACT_CENTER + ')';
                }
            } else {
                quoteNameRecordType = ' (' + getQuoteRecordTypeName(opportunity, recordTypeId) + ')';
            }
            Integer pos = 0;
            for (Quote eqt : opportunity.Quotes) {
                if (eqt.QuotePosition__c != null && Integer.valueOf(eqt.QuotePosition__c) > pos) {
                    pos = Integer.valueOf(eqt.QuotePosition__c);
                }
            }

            quote.QuotePosition__c = pos + 1;
            quote.Name = String.format('{0} {1}{2}', new List<String>{
                opportunity.Name,
                String.valueOf(pos + 1),
                quoteNameRecordType
            });

            // Set fields
            quote.OpportunityId = opportunity.Id;
            quote.Account__c = opportunity.AccountId;
            quote.ExpirationDate = System.today().addDays(30);
            quote.QuoteType__c = 'Quote';
            quote.RecordTypeId = recordTypeId;
            quote.Entitlement_Rental_Phones_Quantity__c = getNumberOfPhones(entitlements, 'Rental Phones');
            quote.Entitlement_Global_Phones_Quantity__c = getNumberOfPhones(entitlements, 'Global Office Rental Phones');
            quote.Entitlement_Limited_Phones_Quantity__c = getNumberOfPhones(entitlements, 'Limited Extension Rental Phones');
            quote.Entitlement_Common_Phones_Quantity__c = getNumberOfPhones(entitlements, 'Common Phones');
            quote.Entitlement_GO_LE_Phones_Quantity__c = getNumberOfPhones(entitlements, 'Global Office - Limited Extension Rental Phones');
            if (String.isNotEmpty(proServDetails)) {
                quote.ProServ_Details__c = proServDetails;
            }
            quote.AreaCode__c = params.get('mainAreaCodeId');
            quote.FaxAreaCode__c = params.get('faxAreaCodeId');
            quote.Main_Vanity_Number__c = BooleanHelper.toBoolean(params.get('isMainPhoneVanity'));
            quote.Fax_Vanity_Number__c = BooleanHelper.toBoolean(params.get('isFaxPhoneVanity'));
            quote.Ship_Attention_To__c = params.get('shippingShipAttentionTo');
            quote.Shipping_Country__c = params.get('shippingCountry');
            quote.Shipping_City__c = params.get('shippingCity');
            quote.Shipping_State__c = params.get('shippingState');
            quote.Shipping_Address_Line__c = params.get('shippingAddressLine');
            quote.Shipping_Postal_Code__c = params.get('shippingPostalCode');
            quote.Shipping_Additional_Address_Line__c = params.get('shippingAdditionalAddressLine');
            quote.Shipping_Customer_Name__c = params.get('shippingCustomerName');
            quote.Shipping_Option__c = params.get('shippingShippingOption');
            quote.MultipleShippingLocations__c = BooleanHelper.toBoolean(params.get('shippingMultipleLocations'));
        }
        quote.Total_Number_of_Digital_Lines__c = null;
        if (lines != null) {
            quote.Total_Number_of_Digital_Lines__c = Integer.valueOf(lines);
        }

        quote.Pricebook2Id = tr.Id;
        if (upsellStatus != null) {
            quote.Upsell_Status__c = upsellStatus;
        }

        if(isDMLsNeeded) {
            try {
                upsert quote;
                if (quote.RecordTypeId == PROSERV_QUOTE_RT_ID && opportunity.Brand_Name__c == OpportunityHelper.BRAND_BT_BUSINESS) {
                    sendMail(new Map<String, String>{
                        'templateApiName' => BT_BUSINESS_QUOTE_CREATED,
                        'opportunityId' => opportunityId
                    });
                }
            } catch (DMLException e) {
                System.debug(e);
                AquivaHelper.throwAuraException(e.getDmlMessage(0));
            }
        }

        return quote;
    }

    /**
     * Delete all Quote Line Items from the Quote
     *
     * @param quoteId
     */
    @AuraEnabled
    public static void deleteQuoteQlis(String quoteId) {
        if (String.isBlank(quoteId)) {
            AquivaHelper.throwAuraException('Quote Id is required');
        }
        QuoteLineItemTriggerHelper.byPassQuoteUpdate = true;
        try {
            delete [
                    SELECT Id
                    FROM QuoteLineItem
                    WHERE QuoteId = :quoteId
            ];
        } catch (DMLException e) {
            AquivaHelper.throwAuraException(e.getDmlMessage(0));
        }
    }

    /**
     * Updates quote record as is
     * @param updatedQuote Quote record with fields to update
     */
    @AuraEnabled
    public static void updateQuote(Quote updatedQuote) {
        try {
            update updatedQuote;
        } catch (DMLException e) {
            AquivaHelper.throwAuraException( e.getDmlMessage(0) );
        }
    }

    @AuraEnabled
    public static void updateCC_FSC_QuoteWithQLIs(Quote updatedQuote, String jsonResponse) {
        try {
            update updatedQuote;

            List<QuoteLineItem> quoteLineItems = new List<QuoteLineItem>();

            if (String.isEmpty(updatedQuote.Special_Terms__c)) {
                quoteLineItems = [SELECT FSC_Line_Tax_Amount__c, FSC_Line_Amount__c
                                    FROM QuoteLineItem
                                    WHERE Product2.Family != 'Overage' AND Quote.Id = :updatedQuote.Id];

                for (QuoteLineItem qLineItem : quoteLineItems) {
                    qLineItem.FSC_Line_Tax_Amount__c = 0;
                    qLineItem.FSC_Line_Amount__c = 0;
                }
            } else {
                Map<Id, Decimal> qliIdToTaxAmount = new Map<Id, Decimal>();
                TaxWrappers.TaxResponse responseWrapper = (TaxWrappers.TaxResponse) System.JSON.deserialize(jsonResponse, TaxWrappers.TaxResponse.class);

                for (TaxWrappers.TaxResponseItem responseItem : responseWrapper.responseData.itemList) {
                    Decimal lineTaxAmount = 0;
                    for (TaxWrappers.TaxResponseDataItem item : responseItem.taxData) {
                        lineTaxAmount += item.taxAmount;
                    }
                    qliIdToTaxAmount.put(responseItem.lineId, lineTaxAmount);
                }

                quoteLineItems = [SELECT FSC_Line_Tax_Amount__c, FSC_Line_Amount__c, Total_Monthly__c
                                    FROM QuoteLineItem
                                    WHERE Id IN :qliIdToTaxAmount.keySet()];

                Integer numberOfFreeTerms = QuoteHelper.getNumberFromString(updatedQuote.Special_Terms__c);
                for (QuoteLineItem qLineItem : quoteLineItems) {
                    qLineItem.FSC_Line_Tax_Amount__c = qliIdToTaxAmount.get(qLineItem.Id).setScale(2) * numberOfFreeTerms;
                    qLineItem.FSC_Line_Amount__c = qLineItem?.Total_Monthly__c != null ? qLineItem.Total_Monthly__c * numberOfFreeTerms : 0;
                }
            }

            update quoteLineItems;

            if (DQGoa.isDQGoaEnabled()) {
                DQGoa.updateApprovedStatusCCFSC(updatedQuote);
            }

        } catch (DMLException e) {
            AquivaHelper.throwAuraException( e.getDmlMessage(0) );
        }
    }

    /**
     * Updates opportunity record as is
     * @param updatedOpp Opportunity record with fields to update
     */
    @AuraEnabled
    public static void updateOpp(Opportunity updatedOpp) {
        try {
            update updatedOpp;
        } catch (DMLException e) {
            AquivaHelper.throwAuraException( e.getDmlMessage(0) );
        }
    }

    public static List<QuoteLineItem> createQuoteLineItems(String quoteId, List<Id> pricebookEntryIdsToInsert) {
        Map<Id, Decimal> pricebookEntryIdToQuantity = new Map<Id, Integer>();
        for (Id pbeId : pricebookEntryIdsToInsert) {
            pricebookEntryIdToQuantity.put(pbeId, 1);
        }
        return createQuoteLineItems(quoteId, pricebookEntryIdToQuantity, null, null);
    }

    public static List<QuoteLineItem> getItemsToInsertWithDependencies(
        String quoteId,
        Map<Id, Decimal> pricebookEntryIdToQuantity,
        Map<Decimal, Decimal> featureToQuantityMap,
        Map<String, String> qlisFromEntitlements)
    {
        List<QuoteLineItem> itemsToInsert = new List<QuoteLineItem>();
        Set<QuoteLineItem> itemsToInsertWithDependencies = new Set<QuoteLineItem>();
        List<QuoteLineItem> itemsToInsertWithQuoteId = new List<QuoteLineItem>();

        Quote quote = [
                SELECT Id, AccountId, Account.CCOveragePremiumDiscount__c, Pricebook2Id, CurrencyIsoCode, Account.Active_Sales_Agreement__c,
                (SELECT Id, Product2Id, Product_Type__c, Product2.Sub_Category__c, Product2.Feature__c, Quantity, NewQuantity__c,
                        Product2.ExtID__c, Product_Family__c, Product2.CatID__c, Product2.Family, QuoteId, Threshold__c,
                        Product2.Number_of_Minutes__c,  Product2.Add_Overages__c, Zero_Quantity__c, Product2.Parent__c,
                        Entitlement__r.Id, Deactivated__c, Product2.Dependent_on_Feature__c, Product2.Product_Type__c FROM QuoteLineItems)
                FROM Quote
                WHERE Id = :quoteId
        ];

        Map<Id,PricebookEntry> pricebookEntriesFromSFMap = new Map<Id,PricebookEntry>([
                SELECT Id, Product2Id, Product2.Name, Product2.Family, Product2.Charge_Term__c, UnitPrice, Product2.Custom_Permission_Set__c,
                        Product2.Description, Product2.Sub_Category__c, Product2.Edition__c, Product2.Seat_Range_Min__c,
                        Product2.Seat_Range_Max__c, CurrencyIsoCode, Product2.Supported_Countries__c, Product2.Parent__c,
                        Product2.Matcher_Formula__c, Product2.ExtID__c, Product2.Advanced_Matcher_Formula__c, Product2.CatID__c,
                        Product2.Product_Tab_Availability__c, Product2.Dependent_on_Feature__c, Product2.Feature__c,
                        Product2.Add_Overages__c, Product2.Product_Type__c, Product2.Number_of_Minutes__c, Pricebook2Id,
                        Pricebook2.isStandard, isActive, Product2.IsActive
                FROM PricebookEntry
                WHERE Pricebook2Id = :quote.Pricebook2Id
        ]);

        List<Entitlement__c> entitlements = [
                SELECT Id, Product__c, Discount__c, Discount_Type__c, Quantity__c,
                        Active__c, DisplayQuantity__c, Product__r.Family,
                        Product__r.Edition__c, Account__c,
                        Product__r.Product_Type__c, Product__r.Name,
                        Product__r.ExtID__c, Product__r.Number_of_Minutes__c,
                        Product__r.Charge_Term__c, Product__r.Feature__c,
                        Product__r.Sub_Category__c, Product__r.Parent__c
                FROM Entitlement__c
                WHERE Account__c = :quote.AccountId
                AND Active__c = true
                AND Quote__c = null
        ];

        for(Id priceBookEntryId : pricebookEntryIdToQuantity.keySet()){
            Decimal quantity = pricebookEntryIdToQuantity.get(priceBookEntryId);
            PricebookEntry pbe = pricebookEntriesFromSFMap.get(priceBookEntryId);

            if(pbe == null) {
                continue;
            }
            QuoteLineItem qliToAdd = QuoteLineItemHelper.createFromPBE(pbe);

            QuoteLineItemHelper.setQuantity(qliToAdd, quantity);
            Entitlement__c matchedEntitlement = matchEntitlement(entitlements, pbe.Product2);
            if (matchedEntitlement != null) {
                if (matchedEntitlement.Product__r.Product_Type__c == 'Seat') {
                    AquivaHelper.throwAuraException('Match Entitlement for '+ pbe.Product2.Name +' Failed. '
                    + 'Contact Center Seat with this edition is already in the cart. Please edit ' + matchedEntitlement.Product__r.Name + ' instead.');
                }

                qliToAdd.Entitlement__c = matchedEntitlement.Id;
                qliToAdd.NewQuantity__c = qliToAdd.Quantity + matchedEntitlement.DisplayQuantity__c;
            }

            // Salesforce can't update quote line item if quoteId is updated with the same value. That is why qli for upsert should not override quoteId
            QuoteLineItem qliToAddWithQuoteId = qliToAdd.clone();
            qliToAddWithQuoteId.QuoteId = quoteId;
            itemsToInsertWithQuoteId.add(qliToAddWithQuoteId);

            if (qlisFromEntitlements != null && qlisFromEntitlements.get(String.ValueOf(priceBookEntryId)) != null) {
                qliToAdd.Id = qlisFromEntitlements.get(String.ValueOf(priceBookEntryId));
            } else {
                qliToAdd.QuoteId = quoteId;
            }
            itemsToInsert.add(qliToAdd);
        }

        List<QuoteLineItem> overagesToAdd = QuoteLineItemHelper.getOveragesOnInsert(
                itemsToInsert,
                pricebookEntriesFromSFMap,
                entitlements,
                quote.QuoteLineItems,
                new List<Quote>{quote}
        );

        List<QuoteLineItem> additionalItemsByFeature = QuoteLineItemHelper.getQuoteLineItemsByFeature(
            pricebookEntriesFromSFMap.values(),
            featureToQuantityMap,
            quote.Id);
        itemsToInsert.addAll(additionalItemsByFeature);

        List<QuoteLineItem> dependentOnFeatureItemsToAdd = QuoteLineItemHelper.getDependentOnFeatureItemsOnInsert(
                itemsToInsertWithQuoteId,
                pricebookEntriesFromSFMap.values(),
                entitlements,
                quote.QuoteLineItems,
                new List<Quote>{quote}
        );

        // ISUS-88: Avoiding duplicates of overages using set
        itemsToInsertWithDependencies.addAll(itemsToInsert);
        itemsToInsertWithDependencies.addAll(overagesToAdd);
        itemsToInsertWithDependencies.addAll(dependentOnFeatureItemsToAdd);
        List<QuoteLineItem> itemsToInsertWithDependenciesList = new List<QuoteLineItem>(itemsToInsertWithDependencies);

        QuoteLineItemHelper.handleDigitalOveragesOnCreate(itemsToInsertWithDependenciesList, quote.QuoteLineItems, pricebookEntriesFromSFMap.values());
        QuoteLineItemHelper.handleBundleServicesOnCreate(itemsToInsertWithDependenciesList, quote.QuoteLineItems, pricebookEntriesFromSFMap.values());

        return itemsToInsertWithDependenciesList;
    }

    @AuraEnabled
    public static string fetchOriginalSOW(Id accountId) {
        List<Order> originalOrder = (List<Order>) new OrderSelector().selectOriginalSOWOrderByAccAndOppId(new List<Object>{accountId})
            .setCondition('AccountId = :bind0 AND Signed_SOW__c != null AND (NOT (Name LIKE \'%Change Order%\'))')
            .addOrdering('CreatedDate', QueryFactory.SortOrder.DESCENDING)
            .executeQuery();
        return originalOrder.size() > 0 ? originalOrder[0].Signed_SOW__c : null;
    }

    @AuraEnabled
    public static List<QuoteLineItem> createQuoteLineItems(
        String quoteId,
        Map<Id, Decimal> pricebookEntryIdToQuantity,
        Map<Decimal, Decimal> featureToQuantityMap,
        Map<String, String> qlisFromEntitlements)
    {
        List<QuoteLineItem> itemsToInsertWithDependencies = getItemsToInsertWithDependencies(quoteId,
            pricebookEntryIdToQuantity, featureToQuantityMap, qlisFromEntitlements);

        Database.UpsertResult[] resultList;
        try {
            resultList = Database.upsert(itemsToInsertWithDependencies);

        } catch (DMLException e){
            AquivaHelper.throwAuraException(e.getDmlMessage(0));
        }

        Set<Id> qliIdSet = new Set<Id>();
        if (resultList != null) {
            for(Database.UpsertResult result : resultList){
                if(result.isSuccess()){
                    qliIdSet.add(result.getId());
                }
            }
        }

        return getQuoteLineItemsById(qliIdSet);
    }

    /**
     *  Get List of products available for this quote
     *  @param quoteId
     */
    @AuraEnabled
    public static List<PricebookEntry> getProducts(String quoteId,String packageInfo){
        if (String.isBlank(quoteId)) {
            AquivaHelper.throwAuraException('Quote Id is required');
        }
        Quote quote = [
                SELECT Id, Pricebook2Id, Upsell_Status__c, Opportunity.RecordType.Name, RecordTypeId
                FROM Quote
                WHERE Id = :quoteId
        ];
        String pricebook2Id = quote.Pricebook2Id;
        Boolean isWithoutTiers = !QuoteHelper.isUpsell(quote);

        if ((quote.RecordTypeId == QuoteHelper.RT_ID_PROSERV
                || quote.RecordTypeId == QuoteHelper.RT_ID_CC_PROSERV)
             && String.isNotBlank(packageInfo)
        ) {
            List<QuoteHelper.PackageInfo> pInfo = QuoteHelper.getPackageInfo(packageInfo);
            String chargeTerm = QuoteHelper.getDurationFromPackageInfoWithoutContract(pInfo.get(0));
            List<PricebookEntry> products = getProducts(pricebook2Id, isWithoutTiers, quote.Opportunity.RecordType.Name);
            return QuoteLineItemHelper.filterProductsByChargeTerm(products, chargeTerm);
        }

        return getProducts(pricebook2Id, isWithoutTiers, quote.Opportunity.RecordType.Name);
    }

    public static List<PricebookEntry> getProducts(Id pricebook2Id, Boolean isWithoutTiers, String opportunityRecordTypeName){
        Map<String, Opportunity_Record_Type_Availability__c> opportunityRecordTypeAvailability =
                Opportunity_Record_Type_Availability__c.getAll();
        Set<Decimal> featuresToExcludeSet = Product2Helper.getFeaturesUnavailableForOpportunity(opportunityRecordTypeName);
        Set<String> familiesToExcludeSet = new Set<String>();

        // Do not include Service Plans
        if (isWithoutTiers) {
            familiesToExcludeSet.addAll( new Set<String>{ 'Tier', 'Service' });
        }
        List<PricebookEntry> products = [
            SELECT Id, Product2Id, Product2.Name, Product2.Family, Product2.Product_Type__c, Product2.Charge_Term__c, UnitPrice, Product2.Custom_Permission_Set__c,
                Product2.Description, Product2.Sub_Category__c, Product2.Edition__c, Product2.Seat_Range_Min__c,
                Product2.Seat_Range_Max__c, CurrencyIsoCode, Product2.Supported_Countries__c, Product2.Parent__c,
                Product2.Matcher_Formula__c, Product2.ExtID__c, Product2.Advanced_Matcher_Formula__c,
                Product2.Product_Tab_Availability__c, Product2.Dependent_on_Feature__c, Product2.Feature__c,
                Product2.Sub_Feature__c, Pricebook2.Brand__r.Name, Product2.Warning_Message__c
            FROM PricebookEntry
            WHERE
            isActive = true
            AND Product2.isActive = true
            AND Pricebook2Id = :pricebook2Id
            AND Product2.Family NOT IN :familiesToExcludeSet
            AND Product2.Feature__c NOT IN :featuresToExcludeSet
        ];

        CustomPermissionHelper customPermissions = new CustomPermissionHelper();
        Map<String, Boolean> userPermissions = new Map<String, Boolean>();
        for (String permission : customPermissions.getPermissionSet()){
            userPermissions.put(permission, true);
        }

        return QuoteLineItemHelper.filterProductsByPermissions(products, userPermissions);
    }

    @AuraEnabled
    public static Void deleteQuoteLineItem(QuoteLineItem deletingQli) {
        // Quote Line Item, which is deleted on Wizard
        QuoteLineItem deletedQli;
        Set<QuoteLineItem> quoteLineItemsToBeDeleted = new Set<QuoteLineItem>();
        List<QuoteLineItem> quoteLineItemsToBeUpdated = new List<QuoteLineItem>();
        Map<String, List<QuoteLineItem>> dependentOnFeatureItemsUpdate = new Map<String, List<QuoteLineItem>>();
        // universal custom settings for europe minute bundles product types
        List<String> euTransportSettings = QuoteLineItemHelper.getEuropeTransportTypes();

        Quote quote = [
            SELECT Id, AccountId, Pricebook2Id, ProServSalesRep__c, isPrimary__c, OpportunityId, Opportunity.Parent_Order__c,
                (SELECT Id, QuoteId, PricebookEntryId, Product2Id, Product2.Family, Product2.Name, BillingStatus__c,
                    Product2.Charge_Term__c, Product2.Dependent_on_Feature__c, Product2.Feature__c, Sub_Category__c, Product2.CatID__c,
                    Product2.Sub_Feature__c, Quantity, UnitPrice, Description, CurrencyIsoCode, Discount, OriginalOrderLineItem__c,
                    Discount_type__c, Discount_number__c, TotalPrice, TotalInitialPrice__c, Number_of_Minutes__c,
                    PriceBookEntry.Pricebook2Id, Product2.Sub_Category__c, Zero_Quantity__c, Deactivated__c, Product2.Product_Type__c,
                    Product_Type__c, Product2.Supported_Countries__c, Product2.Add_Overages__c, Quote.AccountId, NewQuantity__c,
                    Product2.Edition__c, Product2.Matcher_Formula__c, Product2.Advanced_Matcher_Formula__c, Asset__c,
                    Product2.ExtID__c, Entitlement__c, Entitlement__r.Quantity__c, Product2.Number_of_Minutes__c,
                    Product2.Parent__c
                FROM QuoteLineItems)
            FROM Quote
            WHERE Id = :deletingQli.QuoteId
        ];

        Map<Id, QuoteLineItem> qliToDelete = new Map<Id, QuoteLineItem>();
        Map<Id, QuoteLineItem> qliToUpdate = new Map<Id, QuoteLineItem>();
        for (QuoteLineItem existingQli : quote.QuoteLineItems) {
            if (existingQli.Id == deletingQli.Id) {
                deletedQli = existingQli;
            }
        }
        qliToDelete.put(deletedQli.Id, deletedQli);

        Feature_Toggle__c featureToggleSetting = Feature_Toggle__c.getInstance();
        if (
            featureToggleSetting.NewChangeOrderFlow__c
            && quote.Opportunity.Parent_Order__c != null
            && deletedQli.OriginalOrderLineItem__c != null
        ) {
            OrderItem parentOrderItem = new OrderItem(Id = deletedQli.OriginalOrderLineItem__c, Asset__c = deletedQli.Asset__c);
            update parentOrderItem;
        }

        if (deletedQli.Product2.Add_Overages__c) {
            Boolean isSeatDeleted = Product2Helper.isSeatProduct(deletedQli.Product2);
            Boolean isUSAorUKTransportDeleted = QuoteLineItemHelper.isUSAorUKTransportType(deletedQli.Product_Type__c);
            Boolean isPortDeleted = Product2Helper.isPortProduct(deletedQli.Product2);

            List<QuoteLineItem> contactCenterItems = getContactCenterItems(quote.QuoteLineItems);
            Map<String, QuoteLineItem> newItems = new Map<String, QuoteLineItem>();
            Map<String, QuoteLineItem> existingItems = new Map<String, QuoteLineItem>();

            for (QuoteLineItem existingQli : contactCenterItems) {
                if (QuoteLineItemHelper.isOverage(existingQli)) {
                    continue;
                }
                if (existingQli.Entitlement__c != null) {
                    existingItems.put(existingQli.Product_Type__c, existingQli);
                } else {
                    newItems.put(existingQli.Product_Type__c, existingQli);
                }
            }

            for (QuoteLineItem existingQli : contactCenterItems) {
                Boolean isSeat = Product2Helper.isSeatProduct(existingQli.Product2);
                Boolean isTransport = QuoteLineItemHelper.isUSAorUKTransportType(existingQli.Product_Type__c);
                Boolean isPort = Product2Helper.isPortProduct(existingQli.Product2);

                if (isSeatDeleted) {
                    if (!existingItems.containsKey(deletedQli.Product_Type__c)) {
                        qliToDelete.put(existingQli.Id, existingQli);
                        continue;
                    }
                    if (isSeat && existingQli.Entitlement__c != null) {
                        existingQli.Threshold__c = 0;
                        qliToUpdate.put(existingQli.Id, existingQli);
                    }
                    if (QuoteLineItemHelper.isOverage(existingQli)) {
                        if (existingQli.Entitlement__c == null) {
                            qliToDelete.put(existingQli.Id, existingQli);
                            continue;
                        }
                        if (isTransport || isPort) {
                            // new non-overage Item is added on Upsell
                            if (newItems.containsKey(existingQli.Product_Type__c)) {
                                Double valueToSubstract = existingItems.containsKey(existingQli.Product_Type__c)
                                    ? isTransport
                                        // non-overage Item with Entitlement is in Cart
                                        ? existingItems.get(existingQli.Product_Type__c).Product2.Number_of_Minutes__c
                                        // no non-overage Item with Entitlement
                                        : existingItems.get(existingQli.Product_Type__c).Entitlement__r.Quantity__c
                                    : 0;

                                existingQli.Threshold__c = (isTransport
                                    ? newItems.get(existingQli.Product_Type__c).Product2.Number_of_Minutes__c
                                    : newItems.get(existingQli.Product_Type__c).NewQuantity__c)
                                    - valueToSubstract;
                            } else {
                                //  no non-overage Item or only with Entitlement is in Cart
                                existingQli.Threshold__c = 0;
                            }
                            qliToUpdate.put(existingQli.Id, existingQli);
                        }
                    }
                }
                else if ((isUSAorUKTransportDeleted || isPortDeleted)
                    && QuoteLineItemHelper.isOverage(existingQli)
                    && String.isNotBlank(existingQli.Product_Type__c)
                    && existingQli.Product_Type__c.equalsIgnoreCase(deletedQli.Product_Type__c)
                ) {
                    // non-overage Item with Entitlement is in Cart
                    Boolean isEntitlementItemInCart = existingItems.containsKey(existingQli.Product_Type__c);
                    // set Threshold__c on existing Overage
                    if (existingQli.Entitlement__c != null) {
                        if (newItems.containsKey(Product2Helper.PRODUCT_TYPE_SEAT)) {
                            existingQli.Threshold__c = isEntitlementItemInCart
                                ? (isTransport
                                    ? - existingItems.get(deletedQli.Product_Type__c).Product2.Number_of_Minutes__c
                                    : - existingItems.get(deletedQli.Product_Type__c).Entitlement__r.Quantity__c)
                                : 0;
                        } else {
                            existingQli.Threshold__c = 0;
                        }
                    // set Threshold__c on new Overage
                    } else {
                        // we need to know, if it's a New Business or Upsell, maybe, there is a better solution?
                        if (existingItems.containsKey(Product2Helper.PRODUCT_TYPE_SEAT)) {
                            existingQli.Threshold__c = isEntitlementItemInCart
                                ? (isTransport
                                    ? existingItems.get(deletedQli.Product_Type__c).Product2.Number_of_Minutes__c
                                    : existingItems.get(deletedQli.Product_Type__c).Entitlement__r.Quantity__c)
                                : 0;
                        } else {
                            existingQli.Threshold__c = 0;
                        }
                    }
                    qliToUpdate.put(existingQli.Id, existingQli);
                }
                else if (QuoteLineItemHelper.isOverage(existingQli)
                    && existingQli.Product2.ExtID__c.equalsIgnoreCase(deletedQli.Product2.ExtID__c.replaceFirst('null', 'Overage'))
                ) {
                    if (existingQli.Entitlement__c != null) {
                        existingQli.Threshold__c = existingQli.Entitlement__r.Quantity__c;
                        qliToUpdate.put(existingQli.Id, existingQli);
                    } else if (existingQli.Product2.Parent__c == deletedQli.Product2Id) {
                        qliToDelete.put(existingQli.Id, existingQli);
                    } else {
                        existingQli.Threshold__c = 0;
                        qliToUpdate.put(existingQli.Id, existingQli);
                    }
                }
            }
            QuoteLineItemHelper.handleDigitalOveragesOnDelete(deletedQli, quote.QuoteLineItems, qliToUpdate);
            QuoteLineItemHelper.handleBundleServicesOnDelete(deletedQli, quote.QuoteLineItems, qliToUpdate);
        }

        dependentOnFeatureItemsUpdate = QuoteLineItemHelper.getDependentOnFeatureItemsOnDelete(
                qliToDelete.values(),
                quote.QuoteLineItems
        );

        quoteLineItemsToBeDeleted.addAll(qliToDelete.values());
        quoteLineItemsToBeDeleted.addAll(dependentOnFeatureItemsUpdate.get('delete'));

        Boolean isDeletingCCSeat = QuoteLineItemHelper.isContainsCCSeat(qliToDelete.values());
        if(isDeletingCCSeat) {
            List<QuoteLineItem> eesProductsToDelete = QuoteLineItemHelper.getEESProducts(quote.QuoteLineItems);
            if(!eesProductsToDelete.isEmpty()) {
                quoteLineItemsToBeDeleted.addAll(eesProductsToDelete);
            }
        }

        quoteLineItemsToBeUpdated.addAll(qliToUpdate.values());
        quoteLineItemsToBeUpdated.addAll(dependentOnFeatureItemsUpdate.get('update'));


        try {

            if (quoteLineItemsToBeUpdated.size() > 0){
                QuoteLineItemTriggerHelper.byPassQuoteUpdate = true;
            }
            delete new List<QuoteLineItem>(quoteLineItemsToBeDeleted);

            if (quoteLineItemsToBeUpdated.size() > 0){
                update quoteLineItemsToBeUpdated;
                QuoteLineItemTriggerHelper.byPassQuoteUpdate = false;
            }

        } catch (DMLException e) {
            AquivaHelper.throwAuraException(e.getDmlMessage(0));
        }
    }

    public static List<QuoteLineItem> getContactCenterItems(List<QuoteLineItem> quoteLineItems) {
        List<QuoteLineItem> result = new List<QuoteLineItem>();
        for (QuoteLineItem qli: quoteLineItems) {
            if (Product2Helper.SUBCATEGORY_CONTACT_CENTER.equalsIgnoreCase(qli.Product2.Sub_Category__c)) {
                result.add(qli);
            }
        }
        return result;
    }

    /**
     *  Update values in QuoteLineItems
     *  TODO Refactor %% $$ Cryptography
     */
    @AuraEnabled
    public static Void updateCartItems(Id quoteId , Map<String, String> params){
        List <QuoteLineItem> itemsToUpdate = new List <QuoteLineItem>();
        List <QuoteLineItem> itemsToUpdateWithDependencies = new List <QuoteLineItem>();

        List<String> euTransportSettings = QuoteLineItemHelper.getEuropeTransportTypes();

        Set<String> ids = new Set<String>();
        Boolean paramWasNotChanged = true;

        System.debug(JSON.serializePretty(params));

        for (String key : params.keySet()){
            ids.add(key.split('%%')[0]);
        }

        Quote quote = [
                SELECT Id, AccountId, Pricebook2Id, OpportunityId,
                (SELECT Id, QuoteId, PricebookEntryId, Product2.Family, Product2.Name, BillingStatus__c, Product_Family__c,
                        Product2.Charge_Term__c, Product2.Dependent_on_Feature__c, Product2.Feature__c, Product2Id,
                        Product2.CatID__c, Product2.Number_of_Minutes__c, Product2.Product_Type__c, Threshold__c,
                        Product2.Sub_Feature__c, Quantity, UnitPrice, Description, CurrencyIsoCode, Discount,
                        Discount_type__c, Discount_number__c, TotalPrice, TotalInitialPrice__c, Product2.Parent__c,
                        PriceBookEntry.Pricebook2Id, Product2.Sub_Category__c, Zero_Quantity__c, Deactivated__c,
                        Product_Type__c, Product2.Supported_Countries__c, Product2.Add_Overages__c, Quote.AccountId,
                        Product2.Edition__c, Product2.Matcher_Formula__c, Product2.Advanced_Matcher_Formula__c,
                        Product2.ExtID__c, Entitlement__c, Entitlement__r.Quantity__c FROM QuoteLineItems)
                FROM Quote
                WHERE Id = :quoteId
        ];

        Boolean multipleMinuteBundlesOnCart = false;
        Decimal newThresholdForDomesticMinutesOverage = 0;
        Id domesticMinutesOverageId = null;

        for (QuoteLineItem qli : quote.QuoteLineItems){
            if (ids.contains(qli.Id)) {
                try {
                    Integer quantity = Integer.valueOf(params.get(qli.Id + '%%quantity'));

                    Integer newQuantity = null;
                    if (String.isNotBlank(params.get(qli.Id + '%%newQuantity'))) {
                        newQuantity = Integer.valueOf(params.get(qli.Id + '%%newQuantity'));
                    }

                    if (qli.Discount_number__c != Decimal.valueOf(params.get(qli.Id + '%%discount'))
                            || qli.Discount_type__c != params.get(qli.Id + '%%discountType')
                            || qli.Quantity != quantity) {
                        paramWasNotChanged = false;
                    }

                    if (qli.Product2.Family.equalsIgnoreCase(Product2Helper.FAMILY_OVERAGE)) {
                        if (Product2Helper.getCCBundleTypeName(qli.Product2) == null) { // skip threshold update for bundles
                            qli.Threshold__c = quantity;
                            for (QuoteLineItem eQli : quote.QuoteLineItems) {
                                if (eQli.Product_Family__c != Product2Helper.FAMILY_OVERAGE &&
                                    qli.Product2.ExtID__c == eQli.Product2.ExtID__c.replaceFirst('null', 'Overage')) {
                                    if (String.isNotBlank(params.get(eQli.Id + '%%quantityForThreshold'))) {
                                        qli.Threshold__c = Integer.valueOf(params.get(eQli.Id + '%%quantityForThreshold'));
                                    }
                                }
                            }
                        }
                    } else {
                        qli.Quantity = quantity == 0 ? 1 : quantity;
                        qli.Zero_Quantity__c = quantity == 0 ? true : false;
                    }

                    qli.Discount_number__c = Decimal.valueOf(params.get(qli.Id + '%%discount'));
                    qli.Discount_type__c = params.get(qli.Id + '%%discountType');
                    qli.Deactivated__c = Boolean.valueOf(params.get(qli.Id + '%%isDeactivated'));

                    // B-2076 Contact Center ProServ Quoting
                    String provisionedByInContact = params.get(qli.Id + '%%provisionedByInContact');
                    if (String.isNotBlank(provisionedByInContact)) {
                        qli.Provisioned_by_inContact__c = Boolean.valueOf(provisionedByInContact);
                    }

                    // CPS-565 : Domestic Minutes Overage threshold should be updated when minutes bundle is removed from cart
                    if (qli.Product2.Family.equalsIgnoreCase(Product2Helper.FAMILY_MINUTES_BUNDLE)) {
                        newThresholdForDomesticMinutesOverage = qli.Product2.Number_of_Minutes__c;

                        for (QuoteLineItem newQli : quote.QuoteLineItems) {
                            if (newQli.Product2.Family.equalsIgnoreCase(Product2Helper.FAMILY_MINUTES_BUNDLE)
                                    && newQli.id != qli.id) {
                                // There are at least two minute bundles (that means, one is being removed, another is being added) - another logic already updates it
                                multipleMinuteBundlesOnCart = true;
                            }
                        }
                    } else if (qli.Product2.Family.equalsIgnoreCase(Product2Helper.FAMILY_OVERAGE)
                        && QuoteLineItemHelper.isMinutesBundleProduct(qli.Product_Type__c, euTransportSettings)) {
                        // We save the Id of the DMO to update the threshold later
                        domesticMinutesOverageId = qli.id;
                    }

                    itemsToUpdate.add(qli);
                } catch (Exception e) {
                    AquivaHelper.throwAuraException(e.getMessage());
                }
            }
        }

        // CPS-565 : Domestic Minutes Overage threshold should be updated when minutes bundle is removed from cart
        if (!multipleMinuteBundlesOnCart) {
            for (QuoteLineItem qli : itemsToUpdate) {
                if (qli.id == domesticMinutesOverageId) {
                    qli.Threshold__c = - newThresholdForDomesticMinutesOverage;
                }
            }
        }

        System.debug('itemsToUpdate before dependent=>'+itemsToUpdate);

        // Attention! itemsToUpdate List being updated by link inside this method
        QuoteLineItemHelper.getDependentOnFeatureItemsOnUpdate(
                itemsToUpdate,
                quote.QuoteLineItems
        );
        QuoteLineItemHelper.handleDigitalOveragesOnUpdate(
                itemsToUpdate,
                quote.QuoteLineItems
        );
        QuoteLineItemHelper.handleBundleServicesOnUpdate(
                itemsToUpdate,
                quote.QuoteLineItems
        );

        try {
            QuoteTriggerHelper.byPassOpportunityUpdate = true;
            QuoteTriggerHelper.paramWasNotChanged = paramWasNotChanged;

            System.debug('itemsToUpdate after dependent=>'+itemsToUpdate);
            upsert itemsToUpdate;

        } catch (DMLException e) {
            String errMessage = '';
            for (Integer i = 0; i < e.getNumDml(); i++) {
                errMessage = errMessage + '%%' + e.getDmlId(i) + '$$' + e.getDmlMessage(i);
            }
            AquivaHelper.throwAuraException(errMessage);
        }
    }

    @AuraEnabled
    public static Opportunity getOpportunity(Id oppId) {
        return (Opportunity) new OpportunitySelector()
            .selectOpportunityForQuoteWizard(oppId)
            .executeQuery()
            .get(0);
    }

    public static Opportunity getOpportunityForProServ(
        Id opportunityId,
        Map<Id, Opportunity> opps,
        String type,
        Boolean isMultiProductUBEnabled
    ) {
        if (isMultiProductUBEnabled) {
            //MP UB flow - Get Opportunity and all Quotes on this Opportunity
            Opportunity opp = (Opportunity) new OpportunitySelector()
                .selectOpportunitiesByIdsWithQuotes(new Set<Id>{opportunityId})
                .executeQuery()
                .get(0);
            return opp;
        }
        //MP Lite flow - Get Master and Technical Opportunities and all Quotes on these Opportunities
        List<Opportunity> oppsL = (List<Opportunity>) new OpportunitySelector()
            .selectMasterAndTechnicalOpportunitiesByMasterIdWithQuotes(new Set<Id>{opportunityId})
            .executeQuery();
        for (Opportunity opportunity: oppsL) {
            opps.put(opportunity.Id, opportunity);
        }
            // Additional MultiProduct flow:
            // if type == CCProServ and Opportunity is MP --> get CC or Engage technical opportunity,
            // because ProServ pricebooks for CC and Engage ProServ are the same at the moment
        Opportunity opp = opps.get(opportunityId);
        if (isCCProservType(type) && opps.values().size() > 1) {
            for (Opportunity opportunity: opps.values()) {
                BillingWrappers.QuotePackageInfo pInfo = QuoteHelper.getTechnicalQuotePackageInfo(opp.PrimaryQuote__r, opportunity.Tier_Name__c);
                if ((OpportunityHelper.isInContact(opportunity) || OpportunityHelper.isEngage(opportunity)) && String.isNotBlank(pInfo?.productName)) {
                    opp = opportunity;
                    break;
                }
            }
        }
        return opp;
    }

    public static String getEmailEngagedApiName(
        List<Quote> quotes,
        Opportunity opp,
        Map<Id, Opportunity> opps,
        Id opportunityId,
        Boolean isMultiProductUBEnabled
    ) {
        if (isMultiProductUBEnabled) {
            //MP UB flow
            Boolean isEngage = false;
            for (Quote qt: quotes) {
                if (QuoteHelper.isEngageService(qt)) {
                    isEngage = true;
                    break;
                }
            }
            String emailEngagedApiName = isEngage
                ? PROSERV_ENGAGED_ACCOUNTS_EMAIL_API_NAME
                : CC_PROSERV_ENGAGED_EMAIL_API_NAME;
            return emailEngagedApiName;
        }
        //MP Lite flow
        String emailEngagedApiName = OpportunityHelper.isEngage(opp)
            ? PROSERV_ENGAGED_ACCOUNTS_EMAIL_API_NAME
            : CC_PROSERV_ENGAGED_EMAIL_API_NAME;
        return emailEngagedApiName;
    }

    @AuraEnabled
    public static List<Quote> getQuotes(Id opportunityId){
        if (String.isEmpty(opportunityId)) {
            AquivaHelper.throwAuraException('Opportunity Id not specified');
        }

        Id billingRTId = QuoteHelper.RT_ID_BILLING;

        List<Quote> quotes = new List<Quote>();

        try {
            String query = String.format('SELECT {0}, ' +
                '(SELECT {1} FROM QuoteLineItems) ' +
                'FROM Quote ' +
                'WHERE OpportunityId = :opportunityId ' +
                'ORDER BY QuoteNumber ASC', new List<String>{
                QUOTE_FIELDS,
                QUOTE_LINE_ITEMS_FIELDS
            });

            quotes = Database.query(query);
            QuoteHelper.pullApproversFromMainQuote(quotes);

        } catch(DmlException e) {
            AquivaHelper.throwAuraException(e.getDmlMessage(0));
        }
        return quotes;
    }

    /**
     *  Mark quote as Primary
     *  If there is (CC) Professional Services Quote on Opportunity last modifier of the quote will recieve
     *  an email notification. Pro Serv Quote Status will be also changed to In Progress.
     *
     *  @param quoteId          quote id to make primary
     *  @param proServQuoteId   Professional Services Quote id to notify and update status
     *  @param ccProServQuoteId CC Professional Services Quote id to notify and update status
     */
    @AuraEnabled
    public static Quote setQuotePrimary(Id quoteId, Id proServQuoteId, Id ccProServQuoteId){
        Boolean result = false;
        Quote quote = null;

        Feature_Toggle__c featureToggle = Feature_Toggle__c.getInstance();

        try {
            List<Quote> quotesForUpdate = new List<Quote>();
            for (Quote q : [
                    SELECT Id, isPrimary__c, ProServ_Status__c, OpportunityId
                    FROM Quote
                    WHERE Id IN (:quoteId, :proServQuoteId, :ccProServQuoteId)
            ]) {

                // Mark Sales Quote as Primary
                if (q.Id == quoteId) {

                    q.isPrimary__c = true;
                    quotesForUpdate.add(q);

                }

                // Professional Services
                else if ( q.Id == proServQuoteId && (q.ProServ_Status__c == SYNCED_PROSERV_STATUS) ) {

                    // Update ProServ Quote status and send notification
                    sendMail(new Map<String, String>{
                            'templateApiName' => ANOTHER_QUOTE_PRIMARY_PROSERV,
                            'opportunityId'   => q.OpportunityId
                    });

                    q.ProServ_Status__c = IN_PROGRESS_PROSERV_STATUS;
                    quotesForUpdate.add(q);

                }

                // CC Professional Services
                else if ( q.Id == ccProServQuoteId && q.ProServ_Status__c == SYNCED_PROSERV_STATUS ) {
                    // Update CC ProServ Quote status and send notification

                    sendMail(new Map<String,String>{
                            'templateApiName' => ANOTHER_QUOTE_PRIMARY_CC_PROSERV,
                            'opportunityId'   => q.OpportunityId
                    });

                    q.ProServ_Status__c = IN_PROGRESS_PROSERV_STATUS;
                    quotesForUpdate.add(q);

                }

            }

            update quotesForUpdate;
            quote = getQuote(quoteId);

        } catch(DmlException e) {
            AquivaHelper.throwAuraException(e.getDmlMessage(0));
        }
        return quote;
    }

    @AuraEnabled
    public static Boolean deleteQuote(Map<String, String> params){
        try {
            String quoteId = params.get('quoteId');
            Quote qt = [SELECT Id FROM Quote WHERE id=:quoteId LIMIT 1];
            delete qt;
            return true;
        } catch (DMLException e) {
            AquivaHelper.throwAuraException(e.getDmlMessage(0));
            return false;
        }
    }

    @AuraEnabled
    public static List<RC_Quote_Template__c> getPdfTemplates(Map<String, String> params){
        List<RC_Quote_Template__c> result;

        try {
            Id opportunityId = params.get('opportunityId');
            Id quoteId = params.get('quoteId');
            result = PDFTemplateHelper.getPdfTemplates(opportunityId, quoteId);
        } catch (Exception e) {
            AquivaHelper.throwAuraException(e);
        }

        return result;
    }

    /**
    * Attach PDF to Opportunity when user clicks corresponding button
    * Adapted for Quoting wizard from ViewTemplateHelper.class
    */
    @AuraEnabled
    public static String AttachPdfToOpportunity(Map<String, String> params) {
        String result;

        try {
            Id opportunityId = params.get('opportunityId');
            Id quoteId = params.get('quoteId');
            Id templateId = params.get('templateId');
            result = OpportunityHelper.AttachPdfToOpportunity(opportunityId, quoteId, templateId);
        } catch (Exception e) {
            AquivaHelper.throwAuraException(e.getMessage());
        }

        return result;
    }

    /**
     *  Get Quote
     *  @param quoteId       Quote id
     *  @param opportunityId Get primary quote from opportunity
     */
    @AuraEnabled
    public static Quote getQuote(String quoteId, String opportunityId) {
        Quote quote = null;
        List<Quote> quotes = new List<Quote>();
        Boolean isByOppty = String.isNotBlank(opportunityId);

        Id billingRTId = QuoteHelper.RT_ID_BILLING;

        try {

            String w = isByOppty ? 'opportunityId = :opportunityId AND RecordTypeId != :billingRTId' : 'Id = :quoteId';

            String query = String.format('SELECT {0} ' +
                'FROM Quote ' +
                'WHERE ' + w, new List<String>{
                QUOTE_FIELDS
            });

            quotes = Database.Query(query);

            if(quotes.size() > 0){
                quote = isByOppty ? getPrimaryQuote(quotes) : quotes.get(0);
            }
        } catch (DMLException e) {
            System.debug(e);
        }
        return quote;
    }

    @AuraEnabled
    public static Quote getQuote(String quoteId){
        return getQuote(quoteId, null);
    }

    /**
     *   method used in QuotingWizard btn "ProServ is Sold"
     *
     *   Documentation:
     *   https://aquiva.atlassian.net/wiki/spaces/RC/pages/113999918/Professional+Services#ProfessionalServices-QuoteisSold
     */
    @AuraEnabled
    public static void soldProServQuote(Id quoteId) {
        if(String.isBlank(quoteId)) {
            AquivaHelper.throwAuraException('Quote Id is required');
        }

        Quote currQuote = [SELECT Id, ProServ_Status__c, RecordTypeId, OpportunityId FROM Quote WHERE Id = :quoteId];

        if (currQuote.ProServ_Status__c != QuoteHelper.PROSERVSTATUS_SOLD) {
            currQuote.ProServ_Status__c = QuoteHelper.PROSERVSTATUS_SOLD;
            currQuote.ProServ_Sold_Date__c = Datetime.now();

            try {
                update currQuote;
            } catch(DMLException e) {
                AquivaHelper.throwAuraException(e.getDmlMessage(0));
            }
        }

        String templateApiName = currQuote.RecordTypeId == QuoteHelper.RT_ID_CC_PROSERV
                ? CC_PROSERV_SOLD_EMAIL_API_NAME
                : PROSERV_SOLD_EMAIL_API_NAME;

        sendMail(new Map<String, String>{
                            'templateApiName' => templateApiName,
                            'opportunityId'   => currQuote.OpportunityId
        });

    }

    /**
     *   method used in QuotingWizard btn "ProServ is Out for Signature"
     *
     *   Documentation:
     *   https://aquiva.atlassian.net/wiki/spaces/RC/pages/113999918/Professional+Services
     */
    @AuraEnabled
    public static void outForSignatureProServQuote(Id quoteId) {
        if(String.isBlank(quoteId)) {
            AquivaHelper.throwAuraException('Quote Id is required');
        }

        Quote currQuote = [SELECT Id, ProServ_Status__c, RecordTypeId, OpportunityId FROM Quote WHERE Id = :quoteId];

        if (currQuote.ProServ_Status__c != QuoteHelper.PROSERVSTATUS_OUT_FOR_SIGNATURE) {
            currQuote.ProServ_Status__c = QuoteHelper.PROSERVSTATUS_OUT_FOR_SIGNATURE;

            try {
                update currQuote;
            } catch(DMLException e) {
                AquivaHelper.throwAuraException(e.getDmlMessage(0));
            }
        }

        String templateApiName = currQuote.RecordTypeId == QuoteHelper.RT_ID_CC_PROSERV
                ? CC_PROSERV_OUT_FOR_SIGNATURE_EMAIL_API_NAME
                : PROSERV_OUT_FOR_SIGNATURE_EMAIL_API_NAME;

        sendMail(new Map<String, String>{
                'templateApiName' => templateApiName,
                'opportunityId'   => currQuote.OpportunityId
        });

    }

    @AuraEnabled
    public static void generateQuoteDetails(Map<String, String> params){
        update new Quote(
            Id = params.get('quoteId'),
            QLI_details__c = TemplateEngine.createDoc(
                params.get('quoteId'),
                QuoteHelper.getTemplate(QuoteHelper.QUOTE_DETAILS_TEMPLATE)
            )
        );
    }

    /**
     *   Submit for approval
     */
    @AuraEnabled
    public static Quote submitApprovalRequest(Map<String, String> params) {
        String quoteId = params.get('quoteId');
        Quote quote = null;
        if (!String.isBlank(quoteId)) {
            try {
                String comment = 'Submitting request for approval from Quoting Wizard.';
                quote = getQuote(quoteId);
                Boolean isJDGOA = quote.JD_GOA__c;
                Boolean isPRM = quote.IsPRMQuote__c;
                Boolean isSalesQuoteWithNonApprovedProserv = quote.RecordTypeId == QuoteHelper.RT_ID_BILLING && quote.ProservLevelApprover__c != null;
                String approvalProcess = label.Quote_Approval_Process;
                if (isPRM) {
                    approvalProcess = ApprovalHelper.PROCESS_QUOTE_APPROVAL_PROCESS_PRM;
                } else if (isJDGOA) {
                    approvalProcess = ApprovalHelper.PROCESS_QUOTE_APPROVAL_PROCESS_JD;
                } else if (isSalesQuoteWithNonApprovedProserv) {
                    approvalProcess = ApprovalHelper.PROCESS_QUOTE_APPROVAL_PROCESS_WITH_PROSERV_V2;
                }
                System.debug(ApprovalHelper.submitApprovalRequest(quoteId, approvalProcess, comment));
                quote = getQuote(quoteId);
            } catch (DMLException e) {
                AquivaHelper.throwAuraException(e.getDmlMessage(0));
            }
        }
        return quote;
    }

    /**
     *   Recall/Approve/Reject request for approval
     */
    @AuraEnabled
    public static Quote setApprovalAction(Map<String, String> params){
        String quoteId = params.get('quoteId');
        String comment = params.get('comment');
        String action = params.get('action');
        Quote quote = null;
        if(!String.isBlank(quoteId) && !String.isBlank(action)){
            try{
                System.debug(ApprovalHelper.setApprovalAction(quoteId, action, comment));

                quote = getQuote(quoteId);
            } catch(DMLException e) {
                AquivaHelper.throwAuraException(e.getDmlMessage(0));
            }
        }
        return quote;
    }

    /**
     *  Add tax products to cart
     *  @param quoteId Quote Id
     */
    @AuraEnabled
    public static Response getTaxes(String quoteId) {
        if (String.isBlank(quoteId)) {
            AquivaHelper.throwAuraException('Quote Id is required');
        }
        EstimatedTaxesHandler.messageDTO resultMessage;
        Response resp = new Response();
        try {
            EstimatedTaxesHandler handler = new EstimatedTaxesHandler();
            resultMessage = handler.estimateTaxesAndAddQli(quoteId);
            //Update check box on Quote
            updateEstimatedTaxesRequestFailedField(quoteId, resultMessage.status);
        } catch (DMLException e) {
            AquivaHelper.throwAuraException(e.getDmlMessage(0));
        }
        resp.setData('status', resultMessage.status);
        resp.setData('message', resultMessage.message);
        resp.setData('existingTaxesStatus', resultMessage.existingTaxesStatus);
        return resp;
    }

    /**
     *  Remove tax products from cart
     *  @param quoteId
     */
    @AuraEnabled
    public static void removeTaxes(String quoteId) {
        if (String.isBlank(quoteId)) {
            AquivaHelper.throwAuraException('Quote Id is required');
        }

        try {
            EstimatedTaxesHandler.removeTaxesQli(quoteId);
        } catch (DMLException e) {
            AquivaHelper.throwAuraException(e.getDmlMessage(0));
        }
    }

    /**
     *  Get Quote Line Items (products from cart) from Quote
     *  @param quoteId
     */
    @AuraEnabled
    public static List<QuoteLineItem> getQuoteLineItems(String quoteId) {
        if (String.isBlank(quoteId)) {
            AquivaHelper.throwAuraException('Quote Id is required');
        }

        List<QuoteLineItem> quoteLineItems = new List<QuoteLineItem>();

        try {
            String query = String.format('SELECT {0} ' +
                'FROM QuoteLineItem ' +
                'WHERE QuoteId = :quoteId', new List<String>{
                QUOTE_LINE_ITEMS_FIELDS
            });

            quoteLineItems = Database.Query(query);

            for (QuoteLineItem qli : quoteLineItems) {
                if (qli.Zero_Quantity__c) {
                    qli.Quantity = 0;
                }
            }
        } catch (DMLException e) {
            System.debug(e);
            AquivaHelper.throwAuraException(e.getDmlMessage(0));
        }
        return quoteLineItems;
    }

    /**
     *   Special Terms of Service Submit for approval
     *   Project QTC: Support Enterprise Agreements (https://rc.my.salesforce.com/a1y340000007X0E)
     */
    @AuraEnabled
    public static Quote submitSpecialToSApprovalRequest(Map < String, String > params) {
        System.debug('submitSpecialToSApprovalRequest >> ' + params);

        String quoteId = params.get('quoteId');
        String approvalId = params.get('approvalId');
        String askByCustomer = params.get('askByCustomer');
        String legalEngagementType = params.get('legalEngagementType');
        String addOns = params.get('addOns');
        String accommodations = params.get('accommodations');
        String featureAddOns = params.get('featureAddOns');
        String changeOrderTypes = params.get('changeOrderTypes');
        String contractLink = params.get('contractLink');
        String legalAccountName = params.get('legalAccountName');
        Integer trialPeriod = String.isEmpty(params.get('trialPeriod')) ? null : Integer.valueOf(params.get('trialPeriod'));
        String specialTermsAndNotes = params.get('specialTermsAndNotes');

        Quote quote = null;

        if (!String.isBlank(quoteId)) {
            try {
                //Save fields
                quote = getQuote(quoteId);

                RecordType stosRt = [SELECT id FROM RecordType WHERE SObjectType = 'Approval__c' AND DeveloperName = 'Special_ToS_Approval'];
                Approval__c appr = new Approval__c(Id = approvalId,
                        Quote__c = quoteId,
                        Account__c = quote.AccountId,
                        Ask_By_Customer__c = askByCustomer,
                        Type__c = legalEngagementType,
                        RecordTypeId = stosRt.Id,
                        Opportunity__c = quote.OpportunityId,
                        Add_ons__c = addOns,
                        Accomodations__c = accommodations,
                        Feature_Add_ons__c = featureAddOns,
                        Change_Order_Types__c = changeOrderTypes,
                        Contract_Link__c = contractLink,
                        Elasticity__c = '',
                        Full_Legal_Account_Name__c = legalAccountName,
                        Special_Terms_and_Notes__c = specialTermsAndNotes,
                        Trial_Period__c = trialPeriod,
                        // Enagege Legal for Avaya
                        Status__c = params.get('approvalStatus'),
                        Commercial_MSA__c = params.get('commercialMsa'),
                        Enterprise_Agreement__c = params.get('enterpriseAgreement'),
                        Source__c = params.get('source'),
                            // "USA" if Quote.CurrencyIsoCode == USD
                        RC_Entity__c = params.get('rcEntity'),
                            // default attachments - always "Standard"
                        Order_Form__c = params.get('orderForm'),
                        Service_Attachment__c = params.get('serviceAttachment'),
                            // attachments selected
                        BAAs__c = params.get('baaAttachment'),
                        BAA__c = params.containsKey('baaAttachment'),
                        Model_Clauses__c = params.get('dpaAttachment'),
                        DPA__c = params.containsKey('dpaAttachment'),
                        ProServ_Agreement__c = params.get('proServAgreement'),
                        SLA__c = params.get('slaOffice'),
                        SLA_GSS__c = params.get('slaSupportService'),
                        SLA_Customer_Support_GSS__c = params.containsKey('slaSupportService'),
                        Security_Addendums__c = params.get('securityAddendum'),
                        Security_Addendum__c = params.containsKey('securityAddendum'),
                            //playbooks values
                        Payment_Terms__c = params.get('paymentTerms'),
                        Trial_Period_Out_clause__c = params.get('trialPeriodOutClause'),
                        Standard_Step_Up__c = params.containsKey('standardStepUp'),
                        Value_Choice_of_Law__c = params.get('valueChoiceOfLaw')
                );

                if(null == approvalId){
                    //at first let's check if quote's locked. And if it is - unlock, update and later lock.
                    Boolean isApprovalLocked = Approval.isLocked(quote.Id);
                    if (isApprovalLocked) {
                        Approval.unlock(quote.Id);
                    }
                    System.debug('Creating new Spectial TOS approval record for Quote ' + quoteId);
                    insert appr;
                    quote.Special_TOS_Approval__c = appr.Id;
                    Triggers.switchOff();
                    update quote;
                    update new Opportunity(Id = quote.OpportunityId, Special_TOS_Approval__c = appr.Id);
                    Triggers.switchOn();

                    //previously we've unlocked the opportunity, then we need to lock it back.
                    if (isApprovalLocked) {
                        Approval.lock(quote.Id);
                    }
                } else {
                    System.debug('Creating Spectial TOS approval record ' + approvalId);
                    update appr;
                }

                quote = getQuote(quoteId);

            } catch (DMLException e) {
                AquivaHelper.throwAuraException(e.getDmlMessage(0));
            }
        }
        return quote;
    }

    /**
     * Get List of Tiers (Service plans)
     * Used by:
     *     Quoting Wizard
     *     Opportunity Creation Form
     * @param  params:
     *             - CurrencyIsoCode
     *             - recordTypeName
     */
    @AuraEnabled
    public static List < PriceBookEntry > getTiers(Map < String, String > params){

        String currencyIsoCode = params.get('CurrencyIsoCode');
        String recordTypeName = params.get('recordTypeName');
        Boolean isBTBusiness = params.containsKey('isBTBusiness')
                                    ? Boolean.valueOf(params.get('isBTBusiness'))
                                    : false;
        Boolean isTelus = params.containsKey('isTelus')
                                    ? Boolean.valueOf(params.get('isTelus'))
                                    : false;
        Boolean isVodafone = params.containsKey('isVodafone')
                                    ? Boolean.valueOf(params.get('isVodafone'))
                                    : false;
        Boolean isActivePricebook = params.containsKey('isActivePricebook')
            ? Boolean.valueOf(params.get('isActivePricebook'))
            : null;

        String wherefilter = '';

        // Filter by brand
        String brand = '';
        if (currencyIsoCode == 'USD') {brand = OpportunityHelper.BRAND_RINGCENTRAL;}
        if (currencyIsoCode == 'CAD') {
            brand = (isTelus
                        ? RingCentralHelper.BRAND_TELUS_BUSINESS_CONNECT
                        : OpportunityHelper.BRAND_RINGCENTRAL_CA);
        }
        if (currencyIsoCode == 'GBP') {
            brand = (isBTBusiness
                        ? OpportunityHelper.BRAND_BT_BUSINESS
                        : OpportunityHelper.BRAND_RINGCENTRAL_UK);
        }
        if (currencyIsoCode == 'EUR') {brand = OpportunityHelper.BRAND_RINGCENTRAL_EU;}
        if (currencyIsoCode == 'AUD') {brand = OpportunityHelper.BRAND_RINGCENTRAL_AU;}
        if (isVodafone) {
            brand = RingCentralHelper.BRAND_VODAFONE;
        }
        if (brand != ''){
            wherefilter = wherefilter + '(Pricebook2.Brand__r.Name=\'' + brand + '\'' + ') AND ';
        }

        // Filter by record type
        wherefilter = wherefilter + '(Product2.Family=\'Tier\' OR Product2.Family=\'Service\' OR Product2.Family=\'Anchor\') AND Pricebook2.isStandard = false';
        if (recordTypeName != null) {
            wherefilter += ' AND Pricebook2.AllowedRecordType__c includes(\'' + recordTypeName + '\', \''+QuoteHelper.ALLOWED_RT_NAME_BILLING_PROSERV+'\')';
        }
        if (isActivePricebook != null) {
            wherefilter += ' AND Pricebook2.isActive = ' + isActivePricebook;
        }
        if (!String.isBlank(wherefilter)) {
            wherefilter = 'WHERE ' + wherefilter;
        }
        // prepare query
        String query = 'SELECT Pricebook2Id, Id, Pricebook2.Brand__r.Name, Pricebook2.Name, Pricebook2.Edition__c, '+
                +'Pricebook2.Line_Range_Min__c, Pricebook2.Line_Range_Max__c, Pricebook2.Service__c, Pricebook2.Tier_ID__c, '+
                +'Pricebook2.isActive, Product2.Charge_Term__c, Pricebook2.AllowedRecordType__c, UnitPrice, CurrencyIsoCode '+
                +'FROM PriceBookEntry ' + wherefilter + ' ORDER BY Pricebook2.Name';

        return Database.query(query);
    }

    @AuraEnabled
    public static Map<String, Decimal> getMonthlyContractDiscounts(Map<String, String> params){
        String optyCurrency = params.get('currency');
        String quoteId = params.get('quoteId');

        // B-1998
        Map<Id, QuoteLineItem> qliMap = new Map<Id, QuoteLineItem>([SELECT Product2.Feature__c, Product2.Sub_Feature__c, PriceBookEntry.Monthly_Contract_Discount__c,BillingStatus__c FROM QuoteLineItem WHERE QuoteId = :quoteId]);
        Map<String, Decimal> results = FlexibleDiscountRestApi.getDiscount(qliMap);

        return results;
    }


    // Method by Dmitry Golofaev
    @AuraEnabled
    public static List<Entitlement__c> getEntitlements(string accountId) {
        List<Entitlement__c> listEnt = new List<Entitlement__c>();

        if(!String.isBlank(accountId)) {
            try {
                listEnt = [SELECT Id, Active__c, CurrencyIsoCode, DisplayQuantity__c,
                        Product__c, Product__r.Name, Product__r.Family,
                        Product__r.Feature__c, Product__r.Sub_Category__c,
                        Product__r.Product_Type__c, Product__r.Parent__c, Product__r.Parent__r.Edition__c,
                        Product__r.Edition__c, Product__r.Charge_Term__c, Product__r.PBE_Matcher_Formula__c,
                        Product__r.Sub_Feature__c, Product__r.Dependent_on_Feature__c,
                        Discount__c, Discount_Type__c,
                        Price__c, Quantity__c, Product__r.ExtID__c, Product__r.Cart_Tab_Availability__c
                FROM Entitlement__c
                WHERE Account__c =: accountId AND Active__c = true AND Product__r.Sub_Category__c != 'Main'];
            } catch(DMLException e) {
                System.debug(e);
            }
        }

        List<Entitlement__c> entitlements = listEnt;

        return entitlements;
    }

    // Method by Dmitry Golofaev
    @AuraEnabled
    public static List<OrderItem> getOrderItems(string qliId) {
        List<OrderItem> orderItems = new List<OrderItem>();

        if(!String.isBlank(qliId)) {
            try{
                orderItems = [SELECT id, RC_Entitlement__r.Active__c, RC_Entitlement__r.Quantity__c
                FROM OrderItem
                WHERE QuoteLineItemId =: qliId];
            } catch(DMLException e) {
                System.debug(e);
            }
        }

        return orderItems;
    }

    /**
     * Get Primary or last modified quote from list
     * @param  quotes -- A list of quotes. Quotes should have fields:
     *                    Quote.isPrimary__c
     *                    Quote.LastModifiedDate
     *
     * @return        -- Primary Quote or last modified
     */
    @AuraEnabled
    public static Quote getPrimaryQuote(List<Quote> quotes) {
        return QuoteHelper.getPrimaryQuote(quotes);
    }

    /**
     * Engage Professional Service
     *
     * Documentation: https://aquiva.atlassian.net/wiki/spaces/RC/pages/113999918/Professional+Services
     *
     * @param OpportunityId Opportunity Id
     * @param details       Details
     * @param type          ProServ Type. (ProServ || CCProServ)
     *
     * @return status         done
     *         proServQuoteId Created Quote Id
     *         sharingMessage Error message if sharing was unsuccessful
     */
    @AuraEnabled
    public static Map<String, String> engageProServ(Id opportunityId, Id accountId, String details, String type, Boolean isNewBilling) {
        Map<String, String> result;

        try {
            result = engageProServProcess(opportunityId, accountId, details, type);
        } catch(Exception e) {
            if(isNewBilling) {
                throw new AquivaHelper.AquivaException(e.getMessage());
            } else {
                AquivaHelper.throwAuraException(e);
            }
        }

        return result;
    }

    public static Map<String, String> engageProServProcess(Id opportunityId, Id accountId, String details, String type) {

        // Argument validations
        if (String.isBlank(opportunityId)) {
            throw new AquivaHelper.AquivaException('Opportunity Id is required');
        }
        if (String.isBlank(type)) {
            throw new AquivaHelper.AquivaException('ProServ Type should be specified');
        }
        if (! new Set<String>{ PROSERV, CC_PROSERV }.contains(type)) {
            throw new AquivaHelper.AquivaException('Unknown ProServ Type: ' + type);
        }

        Map <String, String> result = new Map <String, String>();
        Boolean isMultiProductUBEnabled = AccountHelper.isMPUBAccount(accountId);

        try {
            Opportunity opp;
            Map<Id, Opportunity> opps = new Map<Id, Opportunity>();
            opp = getOpportunityForProServ(opportunityId, opps, type, isMultiProductUBEnabled);
            List<Quote> quotes = opp.Quotes;

            // Get Sales Primary Quote
            Quote primaryQuote = QuoteHelper.getPrimaryQuote(quotes, opp.Is_Billing_Opportunity__c);
            Quote ccLegacyQuote = QuoteHelper.getCCQuote(quotes);
            Quote mpCCQuote = QuoteHelper.getMPCCQuote(quotes);
            Quote mpEngageQuote = QuoteHelper.getMPEngageQuote(quotes);
            Boolean isBillingPrimaryQuote = QuoteHelper.isNewBillingQuote(primaryQuote);
            BillingWrappers.QuotePackageInfo packageInfo = isBillingPrimaryQuote
                ? BillingWrappers.parseQuotePackageInfo(primaryQuote.Package_Info__c)
                : null;

            Boolean isProServOnly = SettingsService.onlyProServQuotesAvailable(opp);

            Pricebook2Helper.PROSERV_TYPE proServType = ((OpportunityHelper.isEngage(opp) || OpportunityHelper.isInContact(opp))
                && (isBillingPrimaryQuote || isProServOnly))
                || isCCProservType(type)
                ? Pricebook2Helper.PROSERV_TYPE.CC_PROSERV
                : Pricebook2Helper.PROSERV_TYPE.PROSERV;

            Id universalPriceBookId = Pricebook2Helper.findUniversalPricebookId(
                opp.Brand_Name__c,
                opp.Sub_Brand__c,
                opp.CurrencyIsoCode,
                proServType
            );

            String emailEngagedApiName = PROSERV_ENGAGED_EMAIL_API_NAME;
            String recordTypeId = QuoteHelper.RT_ID_PROSERV;
            String groupName = PROSERV_GROUP;
            Quote proServQuote = QuoteHelper.getProServQuote(quotes);

            if (isCCProservType(type) || OpportunityHelper.isInContact(opp)) {
                recordTypeId = QuoteHelper.RT_ID_CC_PROSERV;
                groupName = CC_PROSERV_GROUP;
                emailEngagedApiName = getEmailEngagedApiName(quotes, opp, opps, opportunityId, isMultiProductUBEnabled);
                if (isMultiProductUBEnabled) {
                    if (mpCCQuote == null || quotes.size() > 1) {
                        proServQuote = QuoteHelper.getCCProServQuote(quotes);
                    }
                } else {
                    if (!OpportunityHelper.isInContact(opp) || opps.values().size() > 1) {
                        List<Quote> masterQuotes = opps.get(opportunityId)?.Quotes;
                        proServQuote = QuoteHelper.getCCProServQuote(masterQuotes);
                    }
                }
            }
            String emailTemplateApiName = emailEngagedApiName;

            Id pricebook2Id = primaryQuote != null ? primaryQuote.Pricebook2Id : null;

            // if no ProServ Quote create a new one
            if (proServQuote == null) {
                if (isBillingPrimaryQuote || isProServOnly || (ccLegacyQuote != null && isCCProservType(type))) {
                    pricebook2Id = universalPriceBookId;
                }

                // Create quote with params
                proServQuote = new Quote(
                        Id = saveQuote(new Map <String, String>{
                                'opportunityId' => opportunityId,
                                'pricebook2Id' => pricebook2Id,
                                'recordTypeId' => recordTypeId,
                                'proServDetails' => details
                        })
                );

            }
            // if ProServ Quote is cancelled
            else if (QuoteHelper.PROSERVSTATUS_CANCELLED.equalsIgnoreCase(proServQuote.ProServ_Status__c)) {
                Boolean isGSPCCProServQuote = isProServOnly && isCCProservType(type);

                if (!isBillingPrimaryQuote && proServQuote.pricebook2Id == universalPriceBookId && !isGSPCCProServQuote) {
                    proServQuote.pricebook2Id = primaryQuote.Pricebook2Id;
                }

                if (((isBillingPrimaryQuote || isProServOnly) && proServQuote.pricebook2Id != universalPriceBookId && !isCCProservType(type)) ||
                    isGSPCCProServQuote) {
                    proServQuote.pricebook2Id = universalPriceBookId;
                }

                List<QuoteLineItem> proServQlis = (List<QuoteLineItem>) new QuoteLineItemSelector()
                    .selectQuoteLineItemsByQuoteIds(proServQuote.Id)
                    .executeQuery();

                delete proServQlis;

                List<Phase__c> proServPhases = (List<Phase__c>) new PhaseSelector()
                    .selectPhasesByQuoteId(new List<Object>{new List<Id>{ proServQuote.Id }})
                    .executeQuery();

                delete proServPhases;

                proServQuote.ProServ_Status__c = QuoteHelper.PROSERVSTATUS_CREATED;
                proServQuote.ProServ_Details__c = details;

                update proServQuote;
            }
            else {
                String msg = proServQuote.RecordType.Name + ' has been already engaged. ProServ Status: ' + proServQuote.ProServ_Status__c;

                if( (proServQuote.pricebook2Id != primaryQuote.Pricebook2Id)
                    || (proServQuote.pricebook2Id != universalPriceBookId) ) {

                    /* Wizard where the proserv has been engaged.
                       If primaryQuote is new billing - it means we engaged proserv in old wizard
                       and vice versa */
                    String wizardName = isBillingPrimaryQuote ? REGULAR_WIZARD_NAME : BILLING_WIZARD_NAME;
                    msg = proServQuote.RecordType.Name + ' has been already engaged in ' + wizardName + ' . ProServ Status: ' + proServQuote.ProServ_Status__c;
                }

                throw new AquivaHelper.AquivaException(msg);

            }

            // Send Email notification
            if (String.isNotBlank(emailTemplateApiName)) {
                sendMail(new Map<String, String>{
                        'templateApiName' => emailTemplateApiName,
                        'opportunityId' => opportunityId
                });
            }

            // Share Account, Opportunity and Quotes with Professional Services Group
            // Get Group to share with
            if (String.isNotBlank(groupName)) {
                Group proServGroup = [
                        SELECT Id, Name
                        FROM Group
                        WHERE Name = :groupName
                        LIMIT 1
                ];


                if (proServGroup != null) {

                    Id accId = primaryQuote != null ? primaryQuote.AccountId : opp.AccountId;
                    // Share
                    AccountShare accountShr = new AccountShare(
                            AccountId = accId,
                            UserOrGroupId = proServGroup.Id,
                            AccountAccessLevel = 'Edit',
                            OpportunityAccessLevel = 'Edit'
                    );

                    // Save Result
                    Database.SaveResult accountSR = Database.insert(accountShr, false);

                    // Handle Errors
                    if (!accountSR.isSuccess()) {
                        Database.Error accountErr = accountSR.getErrors()[0];
                        if (accountErr.getStatusCode() != StatusCode.FIELD_FILTER_VALIDATION_EXCEPTION ||
                                !accountErr.getMessage().contains('AccessLevel')) {
                            result.put('sharingMessage', 'Sharing Error: ' + accountErr.getMessage() + '.\n  ' +
                                    'Please ensure that Account and Opportunity are shared with ' + proServGroup.Name + ' Public Group.');
                        }
                    }

                }
            }


            result.put('status','done');
            result.put('proServQuoteId', proServQuote.Id );

        } catch (Exception e) {
            throw new AquivaHelper.AquivaException(e.getMessage());
        }

        return result;
    }

    /**
     * Delete (CC) ProServ Quote Line Items from all sales quotes, set ProServ status to cancelled and
     * send email notification
     *
     * Documentation: https://aquiva.atlassian.net/wiki/spaces/RC/pages/113999918/Professional+Services
     *
     * @param opportunityId Opportunity Id
     * @param details       Sales Reps Details for (CC) ProServ Team
     * @param type          ProServ Type. (ProServ || CCProServ)
     */
    @AuraEnabled
    public static void cancelProServ(Id opportunityId, String details, String type, Boolean isNewBilling) {
        try {
            cancelProServProcess(opportunityId, details, type);
        } catch(Exception e) {
            if(isNewBilling) {
                throw new AquivaHelper.AquivaException(e.getMessage());
            } else {
                AquivaHelper.throwAuraException(e);
            }
        }
    }

    @AuraEnabled
    public static void cancelProServProcess(Id opportunityId, String details, String type){

        // Argument validations
        if (String.isBlank(opportunityId)) {
            throw new AquivaHelper.AquivaException('Opportunity Id is required');
        }
        if (String.isBlank(type)) {
            throw new AquivaHelper.AquivaException('ProServ Type should be specified');
        }
        if (! new Set<String>{ PROSERV, CC_PROSERV }.contains(type)) {
            throw new AquivaHelper.AquivaException('Unknown ProServ Type: ' + type);
        }

        List<Quote> quotes = new List<Quote>();
        List<QuoteLineItem> allQLIs = new List<QuoteLineItem>();
        List<QuoteLineItem> qliToDelete = new List<QuoteLineItem>();
        List<QuoteLineItem> qliToUpdate = new List<QuoteLineItem>();
        List <Quote> quotesToUpdate = new List <Quote>();
        List<QuoteLineItem> existingQLIs = new List<QuoteLineItem>();

        Id billingRTId = QuoteHelper.RT_ID_BILLING;

        try {

            // Get all Quotes on Opportunity
            quotes = [
                    SELECT Id, RecordTypeId, ProServ_Status__c, Approved_Status__c, isPrimary__c, LastModifiedDate
                    FROM Quote
                    WHERE OpportunityId = :opportunityId
            ];

            // Set variables dependent on ProServ Type
            Boolean isCCProServ = isCCProservType(type);
            String emailTemplateApiName = isCCProServ ?
                    CC_PROSERV_CANCELLED_EMAIL_API_NAME :
                    PROSERV_CANCELLED_EMAIL_API_NAME;

            Quote proServQuote = isCCProServ ?
                    QuoteHelper.getCCProServQuote(quotes) :
                    QuoteHelper.getProServQuote(quotes);

            if ( proServQuote != null ){

                // Update ProServ Quote
                proServQuote.ProServ_Status__c = QuoteHelper.PROSERVSTATUS_CANCELLED;
                proServQuote.ProServ_Details__c = details;
                quotesToUpdate.add(proServQuote);

                // Send Email notification
                if (String.isNotBlank(emailTemplateApiName)) {
                    sendMail(new Map<String, String>{
                            'templateApiName' => emailTemplateApiName,
                            'opportunityId' => opportunityId
                    });
                }

            }

            if (quotesToUpdate.size() > 0){
                update quotesToUpdate;
            }

        } catch (Exception e){
            throw new AquivaHelper.AquivaException(e.getMessage());
        }
    }

    /**
     * Sync Professional Service Quote With Sales Primary Quote and send email notification
     *
     * Documentation: https://aquiva.atlassian.net/wiki/spaces/RC/pages/113999918/Professional+Services
     *
     * @param   opportunityId       Opportunity Id
     * @param   syncOnlyAvailable   if true will sync only products available for Primary Quote Service Plan
     *                              Otherwise abort sync and return message
     * @param   type                ProServ Type. (ProServ || CCProServ)
     * @return
     *          status              'success' , 'action required'
     *          unavailableProducts Serialized list of Quote Line Items
     *          pqUser              Serialized Creator of Primary Quote
     *          pqPricebook2Name    Name of Pricebook on Primary Quote
     */
    @AuraEnabled
    public static Map<String, String> syncProServWithSales(String opportunityId, Boolean syncOnlyAvailable, String type){
        // Argument validations
        if (String.isBlank(opportunityId)) {
            AquivaHelper.throwAuraException('Opportunity Id is required');
        }
        if (String.isBlank(type)) {
            AquivaHelper.throwAuraException('ProServ Type should be specified');
        }
        if (! new Set<String>{ PROSERV, CC_PROSERV }.contains(type)) {
            AquivaHelper.throwAuraException('Unknown ProServ Type: ' + type);
        }

        Map <String, String> result = new Map <String, String>();
        result.put('status', 'success');

        List<Quote> quotes = new List<Quote>();
        Quote primaryQuote = null;

        String recordTypeId = PROSERV_QUOTE_RT_ID;
        String proServProductSubCategory = PROSERV_PRODUCT_SUBCATEGORY;
        String emailProServSyncedApiName = PROSERV_SYNCED_EMAIL_API_NAME;
        Boolean isCCProServ = false;
        if (isCCProservType(type)){
            recordTypeId = CC_PROSERV_QUOTE_RT_ID;
            proServProductSubCategory = CC_PROSERV_PRODUCT_SUBCATEGORY;
            emailProServSyncedApiName = CC_PROSERV_SYNCED_EMAIL_API_NAME;
            isCCProServ = true;
        }

        Id billingRTId = QuoteHelper.RT_ID_BILLING;

        // Get all Quotes on Opportunity
        try{
            quotes = [
                SELECT Id, Name, RecordTypeId, RecordType.Name, LastModifiedDate, isPrimary__c, Pricebook2Id, Approved_Status__c,
                    QuoteType__c, Status, LastModifiedBy.Name, LastModifiedBy.Id, LastModifiedBy.Email,
                    CreatedBy.Id, CreatedBy.Email, CreatedBy.Name, Account.Id, Account.Name, Package_Info__c,
                    Opportunity.Id, Opportunity.Name, ProServ_Status__c, Opportunity.Is_Billing_Opportunity__c,
                (SELECT Id, Product2.Name, Product2Id, TotalPrice, BillingStatus__c, Quantity, PackageInfo__c,
                    TotalInitialPrice__c, Description, UnitPrice, Discount_number__c, Discount_type__c, Discount_Value__c,
                    Product2.Charge_Term__c, Product2.ExtID__c, Product2.Sub_Category__c, Product2.Family, NewQuantity__c,
                    Provisioned_by_inContact__c, Entitlement__c, QuoteId, Zero_Quantity__c,
                    Deactivated__c
                FROM QuoteLineItems
                WHERE Product2.Sub_Category__c = :proServProductSubCategory)
                FROM Quote
                WHERE OpportunityId = :opportunityId
                //AND RecordTypeId != :billingRTId
            ];
        } catch (DMLException e) {
            AquivaHelper.throwAuraException(e.getDmlMessage(0));
        }
        if (quotes.size() > 0) {
            Boolean isBillingOpportunity = quotes[0].Opportunity.Is_Billing_Opportunity__c;
            // Get Sales Primary Quote
            primaryQuote = QuoteHelper.getPrimaryQuote(quotes, isBillingOpportunity);

            // Get (CC) ProServ Quote
            Quote proServQuote = isCCProServ ?
                QuoteHelper.getCCProServQuote(quotes) :
                QuoteHelper.getProServQuote(quotes);

            if(proServQuote == null) {
                AquivaHelper.throwAuraException('ProServ Quote not found');
            }
            if(primaryQuote == null) {
                AquivaHelper.throwAuraException('Sales Primary Quote not found');
            }
            validateProServQuote(primaryQuote, proServQuote, type);

            // Check if Primary Quote is Pending for Approval
            if (PENDING_APPROVAL_STATUSES.contains(primaryQuote.Approved_Status__c)) {
                AquivaHelper.throwAuraException('Primary Quote is in Approval Process. You need to wait until it\'s approved to add products in it');
            }
            // Check if Primary Quote is on Active Agreement
            if (QuoteHelper.QUOTE_TYPE_AGREEMENT.equalsIgnoreCase(primaryQuote.QuoteType__c)) {
                AquivaHelper.throwAuraException('Sync is not allowed. Primary Quote is on Agreement stage');
            }
            try {
                // Get QuoteLineItems from Pro Service Quote

                Map<Id, QuoteLineItem> primaryProdIdToQliMap = new Map<Id, QuoteLineItem>();
                for (QuoteLineItem qli : primaryQuote.QuoteLineItems){
                    primaryProdIdToQliMap.put(qli.Product2Id, qli);
                }

                // BZS-4982: Fix for 50001 Query Rows issue
                Set<String> extIdsSet = new Set<String>();
                Set<String> product2IdsSet = new Set<String>();
                for (QuoteLineItem proServQLI : proServQuote.QuoteLineItems){
                    extIdsSet.add(proServQLI.Product2.ExtID__c);
                    product2IdsSet.add(proServQLI.Product2Id);
                }

                Boolean isBilling = primaryQuote.RecordTypeId == billingRTId ;
                // Get primary quote PriceBookEntries
                List<PriceBookEntry> pbes = (List<PriceBookEntry>)new PricebookEntrySelector()
                    .getPBEsByExtIds(new List<Object>{
                        extIdsSet,
                        product2IdsSet,
                        primaryQuote.Pricebook2Id
                    })
                    .executeQuery();

                String pqPricebook2Name = '';
                Map<String, String> productLicencesToId = new Map<String, String>();
                Map<String, String> productExtToLicences = getProductExtToLicencesMap();

                if(pbes.size() > 0) {
                    pqPricebook2Name = pbes.get(0).Pricebook2.Name;
                }
                Map<Id,PriceBookEntry> productIdToPbe = new Map<Id,PriceBookEntry>();
                for (PriceBookEntry pbe: pbes){
                    productIdToPbe.put(pbe.Product2.Id, pbe);
                    productLicencesToId.put(pbe.Product2.ExtID__c, pbe.Product2.Id);
                }

                // insert new Pro Service products to Primary Quote
                List<QuoteLineItem> newSalesProds = new List<QuoteLineItem>();
                List<QuoteLineItem> unavailableProducts = new List<QuoteLineItem>();
                for (QuoteLineItem proServQLI : proServQuote.QuoteLineItems){
                    if(productIdToPbe.containsKey(proServQLI.Product2Id)
                        || productExtToLicences.containsKey(proServQLI.Product2.ExtID__c)
                        && productIdToPbe.get(proServQLI.Product2Id).IsActive == true) {

                        // If product's Charge Term is "One - Time" we ignore it.
                        if(Product2Helper.CHARGE_TERM_ONE_TIME.equalsIgnoreCase(productIdToPbe.get(proServQLI.Product2Id).Product2.Charge_Term__c)) {
                            continue;
                        }

                        String product2Id = productExtToLicences.containsKey(proServQLI.Product2.ExtID__c) ?
                            productLicencesToId.get(productExtToLicences.get(proServQLI.Product2.ExtID__c)) :
                            proServQLI.Product2Id;

                        BillingWrappers.QLIPackageInfo info = generatePackageInfoForQLI(primaryQuote, proServQLI);


                        QuoteLineItem newSalesProd = new QuoteLineItem(
                            Product2Id         = product2Id,
                            QuoteId            = primaryQuote.Id,
                            PriceBookEntryId   = productIdToPbe.get(product2Id).Id,
                            Description        = proServQLI.Description,
                            Quantity           = proServQLI.Quantity,
                            Zero_Quantity__c   = proServQLI.Zero_Quantity__c,
                            UnitPrice          = proServQLI.UnitPrice,
                            Discount_number__c = proServQLI.Discount_number__c,
                            Discount_type__c   = proServQLI.Discount_type__c,
                            Entitlement__c     = proServQLI.Entitlement__c,
                            NewQuantity__c     = proServQLI.NewQuantity__c,
                            Deactivated__c     = proServQLI.Deactivated__c,
                            Item_type__c       = isBilling ? ITEM_TYPE_PROSERV : '',
                            PackageInfo__c    = isBilling ? JSON.serialize(info) : '',
                            Package_Info_QLI__c = isBilling ? JSON.serialize(info) : ''
                        );

                        if (isCCProServ){
                            newSalesProd.Provisioned_by_inContact__c = proServQLI.Provisioned_by_inContact__c;
                        }

                        // If there is already product on Primary Quote just update it
                        if (primaryProdIdToQliMap.containsKey(newSalesProd.Product2Id)){
                            newSalesProd.Id = primaryProdIdToQliMap.get(newSalesProd.Product2Id).Id;
                        }

                        newSalesProds.add(newSalesProd);

                    } else {
                        // Products unavailable for this Price Book
                        unavailableProducts.add(proServQLI);
                    }
                }

                if(syncOnlyAvailable != true && unavailableProducts.size() > 0) {
                    result.put('unavailableProducts', JSON.serialize(unavailableProducts));
                    result.put('pqUser', JSON.serialize(primaryQuote.CreatedBy));
                    result.put('pqPricebook2Name', JSON.serialize(pqPricebook2Name));
                    result.put('status', 'action required');
                } else {
                    if (newSalesProds.size() > 0) {
                        upsert newSalesProds;
                    }

                    if (String.isNotBlank(emailProServSyncedApiName)){
                        sendMail(new Map<String,String>{
                            'templateApiName' => emailProServSyncedApiName,
                            'opportunityId'   => opportunityId
                        });
                    }

                    // B-1618 PS Engagement Process Improvements
                    if (proServQuote.ProServ_Status__c != QuoteHelper.PROSERVSTATUS_SYNCED) {
                        proServQuote.ProServ_Status__c = QuoteHelper.PROSERVSTATUS_SYNCED;
                        update proServQuote;
                    }


                    // Ensure that approval status has not changed
                    String currentApprovalStatus = primaryQuote.Approved_Status__c;
                    Quote reselectedPrimaryQuote = getQuote(primaryQuote.Id);
                    if( (currentApprovalStatus == APPROVED_QUOTE_STATUS)
                        && (currentApprovalStatus != reselectedPrimaryQuote.Approved_Status__c) ) {

                        reselectedPrimaryQuote.Approved_Status__c = currentApprovalStatus;
                        update reselectedPrimaryQuote;
                    }
                }

            } catch (Exception e) {
                AquivaHelper.throwAuraException(e);
            }
        }

        return result;
    }


    public static void validateProServQuote(Quote primaryQuote, Quote proservQuote, String type) {
        validateProductsHaveMatchingExtId(primaryQuote, proservQuote, type);
    }

    private static void validateProductsHaveMatchingExtId(Quote primaryQuote, Quote proservQuote, String type) {
        if (primaryQuote == null || !primaryQuote.Opportunity.Is_Billing_Opportunity__c) {
            return;
        }
        if (isCCProservType(type)) {
            return;
        }
        if (proservQuote.QuoteLineItems == null || proservQuote.QuoteLineItems.size() == 0) {
            return;
        }

        List<String> errorProductNames = getProductsHaveInvalidMatchingExtId(proservQuote.QuoteLineItems);
        if (errorProductNames.isEmpty()) {
            return;
        }

        String errorProductNamesAsString = StringHelper.convertListOfStringsToString(errorProductNames, ', ', false);

        AquivaHelper.throwAuraException('Cannot sync ProServQuote to Main Quote. Items ' +
            errorProductNamesAsString + ' are not found in NGBS_ProservProductToLicenses Custom Setting.' +
            ' Please contact SalesOps admin.');
    }

    private static List<String> getProductsHaveInvalidMatchingExtId(List<QuoteLineItem> qlis) {
        Map<String, String> productExtToLicences = getProductExtToLicencesMap();
        List<String> errorProductNamesList = new List<String>();
        for (QuoteLineItem qli : qlis) {
            // we don't think one-times to NGBS
            if(Product2Helper.CHARGE_TERM_ONE_TIME.equalsIgnoreCase(qli.Product2.Charge_Term__c)) {
                continue;
            }
            if (productExtToLicences.containsKey(qli.Product2.ExtID__c)) {
                continue;
            }
            errorProductNamesList.add(qli.Product2.Name);
        }
        return errorProductNamesList;
    }

    /**
     * Remove (CC) ProServ QuoteLineItems from Quote or All sales Quotes on Opportunity
     *
     * Documentation: https://aquiva.atlassian.net/wiki/spaces/RC/pages/113999918/Professional+Services
     *
     * @param objId Quote or Opportunity Id
     * @param qlis  List of Quote Line Items to remove proServ From. Can be used instead of objId to save SOQL
     * @param type  ProServ Type. (ProServ || CCProServ)
     * @param action    delete || update
     */

    @AuraEnabled
    public static void removeProServProds(Id objId, String type, Boolean doUpdate, Boolean doDelete, Boolean isNewBilling) {
        try {
            removeProServProdsProcess(objId, type, doUpdate, doDelete);
        } catch(Exception e) {
            if(isNewBilling) {
                throw new AquivaHelper.AquivaException(e.getMessage());
            } else {
                AquivaHelper.throwAuraException(e);
            }
        }
    }

    @AuraEnabled
    public static Void removeProServProdsProcess(Id objId, String type, Boolean doUpdate, Boolean doDelete){

        // Argument validations
        if (String.isBlank(objId)) {
            throw new AquivaHelper.AquivaException('Object Id is required');
        }
        if (String.isBlank(type)) {
            throw new AquivaHelper.AquivaException('ProServ Type should be specified');
        }
        if (! new Set<String>{ PROSERV, CC_PROSERV }.contains(type)) {
            throw new AquivaHelper.AquivaException('Unknown ProServ Type: ' + type);
        }
        List<Quote> quotes = new List<Quote>();
        List<QuoteLineItem> allQLIs = new List<QuoteLineItem>();
        List<QuoteLineItem> qliToDelete = new List<QuoteLineItem>();
        List<QuoteLineItem> qliToUpdate = new List<QuoteLineItem>();

        try {
            Boolean isCCProServ = isCCProservType(type);

            List<QuoteLineItem> salesProServProds = new List<QuoteLineItem> ();

            List<QuoteLineItem> qlis = [
                    SELECT Id, Product2.Name, Sub_Category__c,
                            Quote.RecordTypeId, QuoteRecordType__c,
                            Zero_Quantity__c,  Quantity, NewQuantity__c,
                            Discount_type__c, Discount_number__c, QuoteId,
                            Entitlement__c, Entitlement__r.Quantity__c,
                            Entitlement__r.Discount_Type__c, Item_type__c,
                            Entitlement__r.Discount__c, Entitlement__r.Price__c,
                            Entitlement__r.DisplayQuantity__c
                    FROM QuoteLineItem
                    WHERE quote.OpportunityId = :objId
                    OR quoteId = :objId
            ];
            Map<String, List<QuoteLineItem>> proServItems = isCCProServ ?
                    QuoteLineItemHelper.getCCProServItemsToRemove(qlis):
                    QuoteLineItemHelper.getProServItemsToRemove(qlis);
            qliToDelete = proServItems.get('delete');
            qliToUpdate = proServItems.get('update');

            Boolean byPassQuoteUpdate = qliToDelete.size() > 0 && qliToUpdate.size() > 0;

            if(doDelete && qliToDelete.size() > 0){
                QuoteLineItemTriggerHelper.bypassQuoteApprovedStatusChangeLogic = true;
                delete qliToDelete;
            }

            if(doUpdate && qliToUpdate.size() > 0){
                QuoteLineItemTriggerHelper.bypassQuoteApprovedStatusChangeLogic = true;
                update qliToUpdate;
            }

        } catch (Exception e) {
            throw new AquivaHelper.AquivaException(e.getMessage());
        }

    }

    @AuraEnabled
    public static Boolean isLockedInApproval(String recordId) {
        return Approval.isLocked(recordId);
    }
    public static final String PROSERV_AUTOMATED_EMAIL = 'ProServ_Automated_Email';
    public static final String CC_PROSERV_CHANGED_PRODUCT = 'ProServ_SOW';
    public static final String PROSERV_ENGAGED_EMAIL_API_NAME = 'ProServ_Engaged';
    public static final String PROSERV_ENGAGED_ACCOUNTS_EMAIL_API_NAME = 'ProServ_Engage_Account';
    public static final String PROSERV_SYNCED_EMAIL_API_NAME = 'ProServ_Prods_Synced';
    public static final String ANOTHER_QUOTE_PRIMARY_PROSERV = 'Another_Quote_became_Primary';
    public static final String PROSERV_CANCELLED_EMAIL_API_NAME = 'ProServ_Cancelled';
    public static final String PROSERV_SOLD_EMAIL_API_NAME = 'ProServ_Sold';
    public static final String BT_BUSINESS_QUOTE_CREATED = 'BT_Business_Quote_Created';
    public static final String PROSERV_OUT_FOR_SIGNATURE_EMAIL_API_NAME = 'ProServ_Out_for_Signature';

    public static final String CC_PROSERV_ENGAGED_EMAIL_API_NAME = 'CC_ProServ_Engaged';
    public static final String CC_PROSERV_SYNCED_EMAIL_API_NAME = 'CC_ProServ_Prods_Synced';
    public static final String ANOTHER_QUOTE_PRIMARY_CC_PROSERV = 'Another_Quote_became_Primary_CC_ProServ';
    public static final String CC_PROSERV_CANCELLED_EMAIL_API_NAME = 'CC_ProServ_Cancelled';
    public static final String CC_PROSERV_SOLD_EMAIL_API_NAME = 'CC_ProServ_Sold';
    public static final String CC_PROSERV_OUT_FOR_SIGNATURE_EMAIL_API_NAME = 'CC_ProServ_Out_for_Signature';




    public static final Set<String> PROSERV_EMAIL_API_NAMES_SET = new Set<String> {
            PROSERV_ENGAGED_EMAIL_API_NAME,
            PROSERV_ENGAGED_ACCOUNTS_EMAIL_API_NAME,
            PROSERV_SYNCED_EMAIL_API_NAME,
            ANOTHER_QUOTE_PRIMARY_PROSERV,
            PROSERV_CANCELLED_EMAIL_API_NAME,
            PROSERV_SOLD_EMAIL_API_NAME,
            PROSERV_OUT_FOR_SIGNATURE_EMAIL_API_NAME
    };

    public static final Set<String> CC_PROSERV_EMAIL_API_NAMES_SET = new Set<String> {
            CC_PROSERV_CHANGED_PRODUCT,
            CC_PROSERV_ENGAGED_EMAIL_API_NAME,
            CC_PROSERV_SYNCED_EMAIL_API_NAME,
            ANOTHER_QUOTE_PRIMARY_CC_PROSERV,
            CC_PROSERV_CANCELLED_EMAIL_API_NAME,
            CC_PROSERV_SOLD_EMAIL_API_NAME,
            CC_PROSERV_OUT_FOR_SIGNATURE_EMAIL_API_NAME,
            PROSERV_ENGAGED_ACCOUNTS_EMAIL_API_NAME
    };

    // needed for an ability to unit-test constructed SingleEmailMessage (without refactoring existing sendMail() method)
    @testVisible
    private static Messaging.SingleEmailMessage emailToSend;

    /**
     *  Send email
     *  @todo refactor using template engine
     */
    @future
    public static Void sendMail(Map<String, String> params) {
        String templateApiName = params.get('templateApiName');
        String opportunityId = params.get('opportunityId');
        String status = 'success';
        String message = '';
        String OpportunityBrandName = params.get('Brand_Name__c');
        Boolean disablePersonalEmailSignature = false;
        Boolean isCCProServ = CC_PROSERV_EMAIL_API_NAMES_SET.contains(templateApiName);
        Feature_Toggle__c featureToggle = Feature_Toggle__c.getInstance();
        Boolean isProServInNGBS = params.get('isProServInNGBS') != null ? true : false;

        if(String.isNotEmpty(templateApiName)) {
            EmailTemplate template = null;
            try {
                template = [
                        SELECT id, Name, DeveloperName, Body, HtmlValue, Subject
                        FROM EmailTemplate
                        WHERE IsActive = true
                        AND DeveloperName = :templateApiName
                ];
            } catch(DMLException e) {
                System.debug('exception message='+e.getDmlMessage(0));
                message += 'Failed to get Email template: '+e.getDmlMessage(0)+'\n';
                status = 'error';
            }

            if(template != null) {
                String emailSubject = '';
                String emailTextBody = '';
                String emailHtmlBody = '';
                OrgWideEmailAddress emailSender;
                Set<String> emailToAddresses = new Set<String>();
                Set<String> emailCCToAddress = new Set<String>();
                List<Quote> quotes = new List<Quote>();
                try {
                    List<Quote> allQuotes = [
                            SELECT Id, RecordTypeId, RecordType.Name, LastModifiedDate, isPrimary__c, ProServ_Details__c,
                                    Owner.Name, Owner.Email,
                                    LastModifiedBy.Id, LastModifiedBy.Name, LastModifiedBy.Email,
                                    CreatedBy.Id, CreatedBy.Email, CreatedBy.Name, CreatedBy.UserRole.Id, ServiceName__c,
                                    Opportunity.Id, Opportunity.Name,
                                    ProServSalesRep__c, Account.CSM__c,
                                    Account.Id, Account.Name, Account.Number_of_DL_s__c,
                                    (SELECT Id, LastModifiedBy.Email FROM QuoteLineItems)
                            FROM Quote
                            WHERE OpportunityId = :opportunityId
                    ];
                    if (isProServInNGBS) {
                        quotes = allQuotes;
                    } else {
                        for (Quote q: allQuotes) {
                            if (q.RecordTypeId != QuoteHelper.RT_ID_BILLING) {
                                quotes.add(q);
                            }
                        }
                    }
                } catch (DMLException e) {
                    System.debug('exception message='+e.getDmlMessage(0));
                    message += 'Failed to get Quotes: '+e.getDmlMessage(0)+'\n';
                    status = 'error';
                }

                // Get Sales Primary Quote
                Quote primaryQuote = QuoteHelper.getPrimaryQuote(quotes, isProServInNGBS);

                // Get (CC) ProServ Quote
                Quote proServQuote;
                if (isProServInNGBS) {
                    proServQuote = QuoteHelper.getProServTechQuote(quotes);
                } else {
                    proServQuote = isCCProServ ? QuoteHelper.getCCProServQuote(quotes) : QuoteHelper.getProServQuote(quotes);
                }

                emailSubject = template.Subject;
                emailTextBody = template.Body;
                emailHtmlBody = template.HtmlValue;

                //B-6108 Send Email Notification to Primary Contact
                if(isProservAutomatedTemplate(templateApiName) && !isContainsChangeOrder(opportunityId) && proServQuote != null && OpportunityBrandName != 'Avaya Cloud Office') {
                    disablePersonalEmailSignature = true;
                    String contactId = params.get('Primary_Opportunity_Contact__c');
                    String ownerId = params.get('Current_Owner__c');
                    String insideSalesRep = params.get('Inside_Sales_Rep__c');
                    Contact primaryContact;

                    if (!Test.isRunningTest()) {
                        try {
                            emailSender = [SELECT Id From OrgWideEmailAddress WHERE Address = 'rcproserv@ringcentral.com'];
                        } catch (Exception e) {
                            System.debug('exception message='+e.getMessage());
                            message += 'OrgWideEmailAddress search failed: '+e.getMessage()+'\n';
                            status = 'error';
                        }
                    }

                    if (String.isNotBlank(contactId)) {
                        try {
                            primaryContact = [SELECT Email,FirstName,LastName FROM Contact WHERE Id = :contactId];
                            emailToAddresses.add(primaryContact.Email);
                            System.debug(primaryContact.Email);

                        } catch (Exception e) {
                            System.debug('exception message='+e.getMessage());
                            message += 'No Primary Contact: '+e.getMessage()+'\n';
                            status = 'error';
                        }
                    }

                    try {
                        for (User user :[SELECT Id,Email FROM User WHERE Id =: ownerId OR Id =: insideSalesRep]) {
                            emailCCToAddress.add(user.Email);
                        }
                    } catch (Exception e) {
                        System.debug('exception message='+e.getMessage());
                        message += 'Failed to get user email address: '+e.getMessage()+'\n';
                        status = 'error';
                    }

                    if (Feature_Toggle__c.getInstance().NewCcInProservAutomatedEmail__c) {
                        if (proServQuote.ProServSalesRep__c != null) {
                            emailCCToAddress.add(proServQuote.ProServSalesRep__c);
                        }
                        if (proServQuote.Account.CSM__c != null) {
                            emailCCToAddress.add(proServQuote.Account.CSM__c);
                        }

                        for (OpportunityTeamMember oppTeamMember : (List<OpportunityTeamMember>) new OpportunityTeamMemberSelector()
                                .selectByOpportunityIdsAndRoles(
                                    new List<Object>{new Set<Id>{opportunityId}, OpportunityTeamHelper.ENGINEER_ROLES}
                                )
                                .executeQuery()) {
                            emailCCToAddress.add(oppTeamMember.UserId);
                        }
                    }

                    try {
                        String firstName = primaryContact.FirstName == null ? '' : primaryContact.FirstName;
                        String lastName = primaryContact.LastName == null ? '' : primaryContact.LastName;
                        emailHtmlBody = emailHtmlBody.replaceAll('(?i)\\$\\{ContactName\\}', firstName + ' ' + lastName);
                        emailTextBody = emailTextBody.replaceAll('(?i)\\$\\{ContactName\\}', firstName + ' ' + lastName);
                        emailHtmlBody = emailHtmlBody.replaceAll('(?i)\\$\\{AccountName\\}', proServQuote.Account.Name);
                        emailTextBody = emailTextBody.replaceAll('(?i)\\$\\{AccountName\\}', proServQuote.Account.Name);
                    } catch (Exception e) {
                        System.debug('exception message='+e.getMessage());
                        message += 'Email template merge failed: '+e.getMessage()+'\n';
                        status = 'error';
                    }
                }

                //If CC Or RC CC Product was changed
                if(templateApiName == CC_PROSERV_CHANGED_PRODUCT) {
                    String baseUrl = URL.getOrgDomainUrl().toExternalForm();
                    if(String.isNotEmpty(Emails__c.getInstance('ccproserv').Email_Address__c)) {
                        emailToAddresses.add(Emails__c.getInstance('ccproserv').Email_Address__c);
                    }
                    try {
                        emailHtmlBody = emailHtmlBody.replaceAll('(?i)\\$\\{UserName\\}', proServQuote.LastModifiedBy.Name);
                        emailHtmlBody = emailHtmlBody.replaceAll('(?i)\\$\\{UserLink\\}', baseUrl + '/' +proServQuote.LastModifiedBy.Id);
                        emailHtmlBody = emailHtmlBody.replaceAll('(?i)\\$\\{AccountName\\}', proServQuote.Account.Name);
                        emailHtmlBody = emailHtmlBody.replaceAll('(?i)\\$\\{AccountLink\\}', baseUrl + '/' +proServQuote.Account.Id);
                        emailHtmlBody = emailHtmlBody.replaceAll('(?i)\\$\\{OpportunityName\\}', proServQuote.Opportunity.Name);
                        emailHtmlBody = emailHtmlBody.replaceAll('(?i)\\$\\{OpportunityLink\\}', baseUrl + '/' +proServQuote.Opportunity.Id);

                        emailTextBody = emailTextBody.replaceAll('(?i)\\$\\{UserName\\}', proServQuote.LastModifiedBy.Name);
                        emailTextBody = emailTextBody.replaceAll('(?i)\\$\\{UserLink\\}', baseUrl + '/' +proServQuote.LastModifiedBy.Id);
                        emailTextBody = emailTextBody.replaceAll('(?i)\\$\\{AccountName\\}', proServQuote.Account.Name);
                        emailTextBody = emailTextBody.replaceAll('(?i)\\$\\{AccountLink\\}', baseUrl + '/' +proServQuote.Account.Id);
                        emailTextBody = emailTextBody.replaceAll('(?i)\\$\\{OpportunityName\\}', proServQuote.Opportunity.Name);
                        emailTextBody = emailTextBody.replaceAll('(?i)\\$\\{OpportunityLink\\}', baseUrl + '/' +proServQuote.Opportunity.Id);

                        emailSubject = emailSubject.replaceAll('(?i)\\$\\{AccountName\\}', proServQuote.Account.Name);
                    } catch (Exception e) {
                        System.debug('exception message='+e.getMessage());
                        message += 'Email template merge failed: '+e.getMessage()+'\n';
                        status = 'error';
                    }

                }

                // ProServ items were added to the Quote for Account
                if((templateApiName == PROSERV_SYNCED_EMAIL_API_NAME || isCCProServ) && proServQuote != null && primaryQuote != null) {
                    String baseUrl = URL.getOrgDomainUrl().toExternalForm();

                    if(String.isNotEmpty(primaryQuote.CreatedBy.Email)) {
                        emailToAddresses.add(primaryQuote.CreatedBy.Email);
                    }

                    try {
                        emailHtmlBody = emailHtmlBody.replaceAll('(?i)\\$\\{UserName\\}', proServQuote.LastModifiedBy.Name);
                        emailHtmlBody = emailHtmlBody.replaceAll('(?i)\\$\\{UserLink\\}', baseUrl + '/' +proServQuote.LastModifiedBy.Id);
                        emailHtmlBody = emailHtmlBody.replaceAll('(?i)\\$\\{AccountName\\}', proServQuote.Account.Name);
                        emailHtmlBody = emailHtmlBody.replaceAll('(?i)\\$\\{AccountLink\\}', baseUrl + '/' +proServQuote.Account.Id);
                        emailHtmlBody = emailHtmlBody.replaceAll('(?i)\\$\\{OpportunityName\\}', proServQuote.Opportunity.Name);
                        emailHtmlBody = emailHtmlBody.replaceAll('(?i)\\$\\{OpportunityLink\\}', baseUrl + '/' +proServQuote.Opportunity.Id);

                        emailTextBody = emailTextBody.replaceAll('(?i)\\$\\{UserName\\}', proServQuote.LastModifiedBy.Name);
                        emailTextBody = emailTextBody.replaceAll('(?i)\\$\\{UserLink\\}', baseUrl + '/' +proServQuote.LastModifiedBy.Id);
                        emailTextBody = emailTextBody.replaceAll('(?i)\\$\\{AccountName\\}', proServQuote.Account.Name);
                        emailTextBody = emailTextBody.replaceAll('(?i)\\$\\{AccountLink\\}', baseUrl + '/' +proServQuote.Account.Id);
                        emailTextBody = emailTextBody.replaceAll('(?i)\\$\\{OpportunityName\\}', proServQuote.Opportunity.Name);
                        emailTextBody = emailTextBody.replaceAll('(?i)\\$\\{OpportunityLink\\}', baseUrl + '/' +proServQuote.Opportunity.Id);

                        emailSubject = emailSubject.replaceAll('(?i)\\$\\{AccountName\\}', proServQuote.Account.Name);
                    } catch (Exception e) {
                        System.debug('exception message='+e.getMessage());
                        message += 'Email template merge failed: '+e.getMessage()+'\n';
                        status = 'error';
                    }
                }

                // Professional Service Engagement Request
                Set<String> engageEmails = new Set<String> {
                        PROSERV_ENGAGED_EMAIL_API_NAME,
                        CC_PROSERV_ENGAGED_EMAIL_API_NAME,
                        BT_BUSINESS_QUOTE_CREATED,
                        PROSERV_ENGAGED_ACCOUNTS_EMAIL_API_NAME
                };

                if (engageEmails.contains(templateApiName) && proServQuote != null) {
                    String repsRole = '';
                    if (primaryQuote != null && primaryQuote.CreatedBy.UserRole != null) {
                        List <UserRole> repsRoles = new UserRoleSelector()
                        .selectUserRoleById(new List<Object>{primaryQuote.CreatedBy.UserRole.Id})
                        .executeQuery();
                        repsRole = repsRoles.size() > 0 ? repsRoles.get(0).Name : '';
                    }

                    Opportunity opp = (Opportunity) new OpportunitySelector()
                        .selectOpportunitiesByIds(new Set<Id>{opportunityId})
                        .selectFields(new List<String>{
                            'Number_of_Employees__c',
                            'X12_Month_Booking__c',
                            'ForcastedDimeloUsers__c',
                            'Forecast_Connect_First_Users__c',
                            'Owner.Name'
                        })
                        .executeQuery()
                        .get(0);

                    Decimal dealSize = proServQuote.Account.Number_of_DL_s__c!=null
                            ?opp.Forecasted_Users__c + proServQuote.Account.Number_of_DL_s__c
                            :opp.Forecasted_Users__c;
                    String numberOfEmployees = opp.Number_of_Employees__c!=null
                            ?opp.Number_of_Employees__c
                            :'';
                    Decimal forecastedUsers = OpportunityHelper.isEngageDigital(opp)
                        ? opp.ForcastedDimeloUsers__c
                        : opp.Forecast_Connect_First_Users__c;

                    String baseUrl = URL.getOrgDomainUrl().toExternalForm();

                    emailSubject += ' [Owner: ' + opp?.Owner?.Name + ']';

                    String emailToCustomSettingName = PROSERV_EMAILS_CUSTOM_SETTING_NAME;
                    if (isCCProServ) {
                        emailToCustomSettingName = CC_PROSERV_EMAILS_CUSTOM_SETTING_NAME;
                    }
                    if (Emails__c.getall().get(emailToCustomSettingName) != null) {
                        emailToAddresses.add(Emails__c.getall().get(emailToCustomSettingName).Email_Address__c);
                    }

                    try {
                        String notes = proServQuote.ProServ_Details__c == null
                            ? 'Sales Rep hasn&apos;t left any notes.' : proServQuote.ProServ_Details__c.escapeHtml4();

                        emailHtmlBody = emailHtmlBody.replaceAll('(?i)\\$\\{UserName\\}', proServQuote.LastModifiedBy.Name);
                        emailHtmlBody = emailHtmlBody.replaceAll('(?i)\\$\\{UserLink\\}', baseUrl + '/' +proServQuote.LastModifiedBy.Id);
                        emailHtmlBody = emailHtmlBody.replaceAll('(?i)\\$\\{AccountName\\}', proServQuote.Account.Name);
                        emailHtmlBody = emailHtmlBody.replaceAll('(?i)\\$\\{AccountLink\\}', baseUrl + '/' +proServQuote.Account.Id);
                        emailHtmlBody = emailHtmlBody.replaceAll('(?i)\\$\\{OpportunityName\\}', proServQuote.Opportunity.Name);
                        emailHtmlBody = emailHtmlBody.replaceAll('(?i)\\$\\{OpportunityLink\\}', baseUrl + '/' +proServQuote.Opportunity.Id);
                        emailHtmlBody = emailHtmlBody.replaceAll('(?i)\\$\\{CreatedByName\\}', proServQuote.CreatedBy.Name);
                        emailHtmlBody = emailHtmlBody.replaceAll('(?i)\\$\\{CreatedByNameLink\\}', baseUrl + '/' + proServQuote.CreatedBy.Id);
                        emailHtmlBody = emailHtmlBody.replaceAll('(?i)\\$\\{RepsRole\\}', repsRole);
                        emailHtmlBody = dealSize != null
                            ? emailHtmlBody.replaceAll('(?i)\\$\\{DealSize\\}', String.valueOf(dealSize))
                            : emailHtmlBody;
                        emailHtmlBody = emailHtmlBody.replaceAll('(?i)\\$\\{NumberOfEmployees\\}', numberOfEmployees);
                        emailHtmlBody = emailHtmlBody.replaceAll('(?i)\\$\\{X12MonthBooking\\}',opp.CurrencyIsoCode+' '+String.valueOf(opp.X12_Month_Booking__c));
                        emailHtmlBody = forecastedUsers != null
                            ? emailHtmlBody.replaceAll('(?i)\\$\\{ForecastedUsers\\}',String.valueOf(forecastedUsers))
                            : emailHtmlBody;
                        emailHtmlBody = emailHtmlBody.replaceAll('(?i)\\$\\{Notes\\}', notes.replace('\n','<br/>'));

                        emailTextBody = emailTextBody.replaceAll('(?i)\\$\\{UserName\\}', proServQuote.LastModifiedBy.Name);
                        emailTextBody = emailTextBody.replaceAll('(?i)\\$\\{UserLink\\}', baseUrl + '/' +proServQuote.LastModifiedBy.Id);
                        emailTextBody = emailTextBody.replaceAll('(?i)\\$\\{AccountName\\}', proServQuote.Account.Name);
                        emailTextBody = emailTextBody.replaceAll('(?i)\\$\\{AccountLink\\}', baseUrl + '/' +proServQuote.Account.Id);
                        emailTextBody = emailTextBody.replaceAll('(?i)\\$\\{OpportunityName\\}', proServQuote.Opportunity.Name);
                        emailTextBody = emailTextBody.replaceAll('(?i)\\$\\{OpportunityLink\\}', baseUrl + '/' +proServQuote.Opportunity.Id);
                        emailTextBody = emailTextBody.replaceAll('(?i)\\$\\{CreatedByName\\}', proServQuote.CreatedBy.Name);
                        emailTextBody = emailTextBody.replaceAll('(?i)\\$\\{CreatedByNameLink\\}', baseUrl + '/' + proServQuote.CreatedBy.Id);
                        emailTextBody = emailTextBody.replaceAll('(?i)\\$\\{RepsRole\\}', repsRole);
                        emailTextBody = dealSize != null
                            ? emailTextBody.replaceAll('(?i)\\$\\{DealSize\\}', String.valueOf(dealSize))
                            : emailTextBody;
                        emailTextBody = emailTextBody.replaceAll('(?i)\\$\\{NumberOfEmployees\\}', numberOfEmployees);
                        emailTextBody = emailTextBody.replaceAll('(?i)\\$\\{X12MonthBooking\\}',opp.CurrencyIsoCode+' '+String.valueOf(opp.X12_Month_Booking__c));
                        emailTextBody = forecastedUsers != null
                            ? emailTextBody.replaceAll('(?i)\\$\\{ForecastedUsers\\}',String.valueOf(forecastedUsers))
                            : emailTextBody;
                        emailTextBody = emailTextBody.replaceAll('(?i)\\$\\{Notes\\}', notes);
                    } catch (Exception e) {
                        System.debug('exception message='+e.getMessage());
                        message += 'Email template merge failed: '+e.getMessage()+'\n';
                        status = 'error';
                    }
                }

                // Another Quote became Primary
                if((templateApiName == ANOTHER_QUOTE_PRIMARY_PROSERV || templateApiName == ANOTHER_QUOTE_PRIMARY_CC_PROSERV) && primaryQuote != null) {
                    String baseUrl = URL.getOrgDomainUrl().toExternalForm();
                    if(String.isNotEmpty(proServQuote.LastModifiedBy.Email)) {
                        emailToAddresses.add(proServQuote.LastModifiedBy.Email);
                    }
                    try {
                        emailHtmlBody = emailHtmlBody.replaceAll('(?i)\\$\\{UserName\\}', primaryQuote.LastModifiedBy.Name);
                        emailHtmlBody = emailHtmlBody.replaceAll('(?i)\\$\\{UserLink\\}', baseUrl + '/' +primaryQuote.LastModifiedBy.Id);
                        emailHtmlBody = emailHtmlBody.replaceAll('(?i)\\$\\{AccountName\\}', primaryQuote.Account.Name);
                        emailHtmlBody = emailHtmlBody.replaceAll('(?i)\\$\\{AccountLink\\}', baseUrl + '/' +primaryQuote.Account.Id);
                        emailHtmlBody = emailHtmlBody.replaceAll('(?i)\\$\\{OpportunityName\\}', primaryQuote.Opportunity.Name);
                        emailHtmlBody = emailHtmlBody.replaceAll('(?i)\\$\\{OpportunityLink\\}', baseUrl + '/' +primaryQuote.Opportunity.Id);

                        emailTextBody = emailTextBody.replaceAll('(?i)\\$\\{UserName\\}', primaryQuote.LastModifiedBy.Name);
                        emailTextBody = emailTextBody.replaceAll('(?i)\\$\\{UserLink\\}', baseUrl + '/' +primaryQuote.LastModifiedBy.Id);
                        emailTextBody = emailTextBody.replaceAll('(?i)\\$\\{AccountName\\}', primaryQuote.Account.Name);
                        emailTextBody = emailTextBody.replaceAll('(?i)\\$\\{AccountLink\\}', baseUrl + '/' +primaryQuote.Account.Id);
                        emailTextBody = emailTextBody.replaceAll('(?i)\\$\\{OpportunityName\\}', primaryQuote.Opportunity.Name);
                        emailTextBody = emailTextBody.replaceAll('(?i)\\$\\{OpportunityLink\\}', baseUrl + '/' +primaryQuote.Opportunity.Id);

                        emailSubject = emailSubject.replaceAll('(?i)\\$\\{AccountName\\}', primaryQuote.Account.Name);
                    } catch (Exception e) {
                        System.debug('exception message='+e.getMessage());
                        message += 'Email template merge failed: '+e.getMessage()+'\n';
                        status = 'error';
                    }
                }

                // (CC) ProServ Cancelled
                if (new Set<String>{PROSERV_CANCELLED_EMAIL_API_NAME, CC_PROSERV_CANCELLED_EMAIL_API_NAME}.contains(templateApiName)
                        && primaryQuote != null) {
                    Quote lastModifiedQuote = proServQuote != null ? proServQuote : primaryQuote;
                    if (lastModifiedQuote.QuoteLineItems.size() > 0) {
                        // Recepient: Last Modifier of any QLI on the (CC) ProServ Quote.
                        emailToAddresses.add(lastModifiedQuote.QuoteLineItems.get(0).LastModifiedBy.Email);
                    } else {
                        emailToAddresses.add(lastModifiedQuote.LastModifiedBy.Email);
                    }

                    Map<String,String> emailTemplateParams = new Map<String,String>{
                            'notes' => lastModifiedQuote.ProServ_Details__c
                    };
                    emailHtmlBody = TemplateEngine.createFromString(primaryQuote.Id, emailHtmlBody, emailTemplateParams);
                    emailTextBody = TemplateEngine.createFromString(primaryQuote.Id, emailTextBody, emailTemplateParams);
                }

                // (CC) ProServ Sold / Out for Signature
                if (new Set<String>{
                        PROSERV_SOLD_EMAIL_API_NAME,
                        CC_PROSERV_SOLD_EMAIL_API_NAME,
                        PROSERV_OUT_FOR_SIGNATURE_EMAIL_API_NAME,
                        CC_PROSERV_OUT_FOR_SIGNATURE_EMAIL_API_NAME
                }.contains(templateApiName)
                        && primaryQuote != null
                        && proServQuote != null) {
                    emailToAddresses.add(primaryQuote.Owner.Email);

                    emailSubject = TemplateEngine.createFromString(proServQuote.Id, emailSubject);

                    emailHtmlBody = TemplateEngine.createFromString(proServQuote.Id, emailHtmlBody);
                    emailTextBody = TemplateEngine.createFromString(proServQuote.Id, emailTextBody);
                }

                emailToAddresses.remove(null);

                if(emailToAddresses.size() > 0) {
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    emailToSend = mail;
                    mail.setUseSignature(!disablePersonalEmailSignature);
                    mail.setToAddresses(new List<String>(emailToAddresses));
                    mail.setSubject(emailSubject);
                    mail.setPlainTextBody(emailTextBody);
                    mail.setHtmlBody(emailHtmlBody);
                    if(emailSender != null && !Test.isRunningTest()) {
                        mail.setOrgWideEmailAddressId(emailSender.Id);
                    }
                    if(emailCCToAddress.size() > 0) {
                        mail.setCcAddresses(new List<String>(emailCCToAddress));
                    }
                    // Send the email
                    try {
                        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
                    } catch (Exception e) {
                        System.debug('exception message='+e.getMessage());
                        message += 'Failed to send email: '+e.getMessage()+'\n';
                        status = 'error';
                        System.debug(e.getMessage());
                    }
                } else {
                    message += 'Recipient email not found.\n';
                    status = 'error';
                }
            } else {
                message += 'Email template not found.\n';
                status = 'error';
            }
        }

        Map<String, String> result = new Map<String, String> {
                'status' => status
        };
        if(String.isNotEmpty(message)) {
            result.put('message', message);
        }
        system.debug(result);
    }

    @AuraEnabled
    public static Entitlement__c matchEntitlement(List<Entitlement__c> entls, Product2 prod) {
        List<Entitlement__c> matcherResult = (Entitlement__c[]) RecordsMatcher.match(entls, prod, 'Matcher_Formula__c');
        return (matcherResult.size() > 0 ? matcherResult[0] : null);
    }

    @AuraEnabled
    public static Boolean hasActiveEntitlements(List<Entitlement__c> entls, List<QuoteLineItem> qlis) {
        Boolean hasEnt = false;
        for (QuoteLineItem qli : qlis) {
            List<Entitlement__c> matcherResult = (Entitlement__c[]) RecordsMatcher.match(entls, qli.Product2, 'Matcher_Formula__c');
            if (matcherResult.size() > 0) {
                hasEnt = true;
                break;
            }
        }
        return hasEnt;
    }

    /**
     *  Get List of Area Code items for specified QLIs
     *  @param qlis -- a list of qli for which to get Area Code Line Items
     */
    @AuraEnabled
    public static List<Area_Code_Line_Item__c> getAreaCodeItems(List<QuoteLineItem> qlis) {
        Map<Id, QuoteLineItem> qliMap = new Map<Id, QuoteLineItem>(qlis);
        return [
            SELECT Id, Name, Quantity__c, Quote_Line_Item__c, Area_Code__r.Area_Code__c,
                   Area_Code__r.Country__c, Area_Code__r.City__c
            FROM Area_Code_Line_Item__c
            WHERE Quote_Line_Item__c IN :qliMap.keySet()
            ORDER BY Id
        ];
    }

    /**
     *  Updates Area Code Line Items
     *  @param areaCodesToSave -- Area Code Line Items to save/create
     */
    @AuraEnabled
    public static List <Area_Code_Line_Item__c> saveAreaCodeItems(List <Area_Code_Line_Item__c> areaCodesToSave){
        List <Area_Code_Line_Item__c> itemsToUpdate = new List <Area_Code_Line_Item__c>();

        for (Area_Code_Line_Item__c item :areaCodesToSave) {
            itemsToUpdate.add(new Area_Code_Line_Item__c(
                    Id = item.Id,
                    Quote_Line_Item__c = item.Quote_Line_Item__c,
                    Area_Code__c = item.Area_Code__c,
                    Quantity__c = item.Quantity__c));
        }

        if (itemsToUpdate.size() > 0){
            try{

                upsert itemsToUpdate;
            } catch(DMLException e){
                AquivaHelper.throwAuraException(e.getDmlMessage(0));
            }
        }

        return itemsToUpdate;
    }

    /**
     *  Delete Area Code Item
     */
    @AuraEnabled
    public static void deleteAreaCodeItem(String areaCodeItemId){
        try{
            delete [SELECT Id FROM Area_Code_Line_Item__c WHERE Id = :areaCodeItemId];
        }catch(DMLException e){
            AquivaHelper.throwAuraException(e.getDmlMessage(0));
        }
    }

    /**
     * Creates Quote Line Items From Entitlements
     * @param quoteId
     */
    @AuraEnabled
    public static void addEntitlementsAsLineItems(Id quoteId) {
        if (quoteId == null) {
            AquivaHelper.throwAuraException('Quote Id is required');
        }

        Quote quote = [
                SELECT Id, AccountId, Pricebook2Id, CurrencyIsoCode, RecordType.Name,
                (SELECT Id, Product2Id, Product_Type__c, Product2.Feature__c, Quantity,
                        Product2.Number_of_Minutes__c, QuoteId, Product2.Add_Overages__c, Zero_Quantity__c,
                        Entitlement__r.Id, Deactivated__c, Product2.Dependent_on_Feature__c FROM QuoteLineItems)
                FROM Quote
                WHERE Id = :quoteId
        ];

        List<Entitlement__c> entitlements = [
                SELECT Id, Quantity__c, DisplayQuantity__c, Price__c, Discount__c, Discount_Type__c, Account__c,
                        Product__c, Product__r.Edition__c, Product__r.Number_of_Minutes__c,
                        Product__r.Family, Product__r.Product_Type__c, Product__r.Sub_Category__c, Product__r.Feature__c,
                        Product__r.Name, Active__c, Product__r.ExtID__c, Product__r.Charge_Term__c
                FROM Entitlement__c
                WHERE Account__c = :quote.AccountId
                AND Active__c = true
                AND Product__r.Cart_Tab_Availability__c INCLUDES(:quote.RecordType.Name)
                AND Product__r.Family != '' AND  Product__r.Family != :Product2Helper.FAMILY_FEE AND Product__r.Charge_Term__c != :Product2Helper.CHARGE_TERM_ONE_TIME
        ];

        List<PricebookEntry> pricebookEntriesFromSF = [
                SELECT Id, Product2Id, Product2.Name, Product2.Family, Product2.Charge_Term__c, UnitPrice,
                        Product2.Description, Product2.Sub_Category__c, Product2.Edition__c, Product2.Seat_Range_Min__c,
                        Product2.Seat_Range_Max__c, CurrencyIsoCode, Product2.Supported_Countries__c, Product2.Parent__c,
                        Product2.Matcher_Formula__c, Product2.Upsell_Matcher_Formula__c, Product2.Advanced_Matcher_Formula__c,
                        Product2.ExtID__c, Product2.Product_Tab_Availability__c, Product2.Dependent_on_Feature__c, Product2.Feature__c,
                        Product2.Add_Overages__c, Product2.Product_Type__c, Product2.Number_of_Minutes__c, Pricebook2Id,
                        Pricebook2.isStandard, isActive
                FROM PricebookEntry
                WHERE Pricebook2Id = :quote.Pricebook2Id
                AND isActive = true
        ];

        if (entitlements.size() > 0) {
            EntitlementSync.EntitlementsParams ep = new EntitlementSync.EntitlementsParams();
            ep.pricebook2Id = quote.Pricebook2Id;
            ep.quoteId = quoteId;
            ep.entitlements = entitlements;
            ep.pricebookEntries = pricebookEntriesFromSF;

            List<QuoteLineItem> qlisToAdd = EntitlementSync.createLineItemsFromEntitlements(ep);

            qlisToAdd.addAll(QuoteLineItemHelper.getDependentOnFeatureItemsOnInsert(
                    qlisToAdd,
                    pricebookEntriesFromSF,
                    entitlements,
                    quote.QuoteLineItems,
                    new List<Quote>{quote}
            ));

            QuoteTriggerHelper.byPassProServStatusUpdate = true;
            if (qlisToAdd != null && qlisToAdd.size() > 0) {
                insert qlisToAdd;
            }
        }
    }

    /**
      * Update qli single method
      */
    @AuraEnabled
    public static Map<String,String> updateListQli(List<QuoteLineItem> listQli) {

        Map<String,String> result = new Map<String,String>();

        if(listQli != null && listQli.size() > 0) {
            try{
                QuoteLineItemHelper.handleBundleServicesOnUpdate(
                    listQli,
                    (List<QuoteLineItem>) new QuoteLineItemSelector()
                        .selectQuoteLineItemsForQLITrigger(new Set<Id>{listQli[0].QuoteId})
                        .executeQuery()
                );
                update listQli;
                result.put('status', 'success');
            }catch(DMLException e){
                AquivaHelper.throwAuraException(e.getDmlMessage(0));
            }
        } else {
            result.put('status', 'error');
            result.put('message', 'No account ID passed');
        }

        return result;
    }

    /**
      * Calculate FirstYearCostOfService, MonthlyRecurringRevenue and so on...
      */
    @AuraEnabled
    public static Quote getQuoteTotalValues(String quoteId, List<QuoteLineItem> items) {

        if( String.isBlank(quoteId) ) {
            AquivaHelper.throwAuraException('quoteId is required');
        }

        Quote q = [
            SELECT Id, Initial_Payment__c, Initial_Discount__c,
                   First_Year_Cost_of_Service__c, First_Year_Discount__c,
                   Monthly_Recurring_Revenue__c, First_Year_Total_Cost_excluding_Taxes__c,
                   SumProServOneTime__c, RecordTypeId,
                   Total_First_Year_Cost__c, Total_First_Year_Discount__c, Total_Initial_Payment__c,
                   Total_Initial_Payment_Discount__c, Total_MRR__c, Total_MRR_New__c
            FROM Quote
            WHERE Id = :quoteId
        ];

        Boolean isNeedToUpdate = false;

        // We don't want ProServ Status to be updated in this case
        QuoteTriggerHelper.byPassProServStatusUpdate = true;

        Map<Id, Decimal> quoteSumProServOneTime = new Map<Id, Decimal>();
        quoteSumProServOneTime = SetApprovalTypeHelper.getMapProServOneTime( items );

        // is need to update quote?
        q.sumProServOneTime__c = quoteSumProServOneTime.containsKey(q.Id) ? quoteSumProServOneTime.get(q.Id) : 0;

        Quote quoteBeforeSetTotals = q.clone();

        if(quoteBeforeSetTotals.ProServSOWDiscount__c != q.ProServSOWDiscount__c
                    || quoteBeforeSetTotals.First_Year_Cost_of_Service__c != q.First_Year_Cost_of_Service__c
                    || quoteBeforeSetTotals.First_Year_Discount__c != q.First_Year_Discount__c
                    || quoteBeforeSetTotals.Monthly_Recurring_Revenue__c != q.Monthly_Recurring_Revenue__c
                    || quoteBeforeSetTotals.Initial_Discount_without_ProServ__c != q.Initial_Discount_without_ProServ__c
                    || quoteBeforeSetTotals.First_Year_Total_Cost_excluding_Taxes__c != q.First_Year_Total_Cost_excluding_Taxes__c
                    || quoteBeforeSetTotals.Total_First_Year_Cost__c != q.Total_First_Year_Cost__c
                    || quoteBeforeSetTotals.Total_First_Year_Discount__c != q.Total_First_Year_Discount__c
                    || quoteBeforeSetTotals.Total_Initial_Payment__c != q.Total_Initial_Payment__c
                    || quoteBeforeSetTotals.Total_Initial_Payment_Discount__c != q.Total_Initial_Payment_Discount__c
                    || quoteBeforeSetTotals.Total_MRR__c != q.Total_MRR__c
                    || quoteBeforeSetTotals.Total_MRR_New__c != q.Total_MRR_New__c)
        {
            isNeedToUpdate = true;
        }

        if(isNeedToUpdate) {
            try {
                update q;
            } catch(DMLException e) {
                AquivaHelper.throwAuraException(e.getDmlMessage(0));
            }
        }
        return q;
    }

    /**
     *  Update all dependant items in cart
     *  This method called instead of trigger to avoid soql limits
     *  @see QuoteLineIteTriggerHelper.ApplyQuoteLineItemFees
     *  @param quoteId
     *  @param pricebook2Id
     */
    @AuraEnabled
    public static void updateDependentItems(String quoteId, String pricebook2Id) {

        List <QuoteLineItem> qlisOnQuote = [
                SELECT Id, Product2Id, CurrencyIsoCode,BillingStatus__c,
                        Quantity, Product2.Feature__c,
                        Product2.Dependent_on_Feature__c,
                        QuoteId, Quote.Pricebook2Id, Zero_Quantity__c
                FROM QuoteLineItem
                WHERE (Product2.Feature__c != null OR Product2.Dependent_on_Feature__c != null) AND QuoteId = :quoteId ];

        if (qlisOnQuote.size() == 0) {
            return;
        }

        Map<String, List<PriceBookEntry>> priceBookEntrys = new Map<String, List<PriceBookEntry>>();
        Map<Id, QuoteLineItem> featureDependentLineItemsToDelete = new Map<Id, QuoteLineItem>();
        Map<String, List<QuoteLineItem>> featureDependentLineItems = new Map<String, List<QuoteLineItem>>();
        Map<Id, QuoteLineItem> featureDependentLineItemsToUpdate = new Map<Id, QuoteLineItem>();
        List<QuoteLineItem> featureDependentLineItemsToInsert = new List<QuoteLineItem>();
        List<QuoteLineItem> productLineItems = new List<QuoteLineItem>();

        //Get dependent on feature pricebook entries
        for (PriceBookEntry pBookEntry: [
                SELECT Id, CurrencyIsoCode, Pricebook2Id, Product2Id, UnitPrice, Per_Line__c,
                        Min_Quantity__c, Product2.Description, Pricebook2.Line_Range_Min__c,
                        Product2.Dependent_on_Feature__c
                FROM PriceBookEntry
                WHERE Product2.Dependent_on_Feature__c != null AND Pricebook2Id = :pricebook2Id
        ]) {
            String key = String.ValueOf(pBookEntry.Product2.Dependent_on_Feature__c);
            if (!priceBookEntrys.containsKey(key)) {
                priceBookEntrys.put(key, new List<PriceBookEntry>());
            }
            priceBookEntrys.get(key).add(pBookEntry);
        }

        // Get Feature dependent qlis on Quote
        for (QuoteLineItem qli : qlisOnQuote){
            if (qli.Product2.Dependent_on_Feature__c != null) {
                String key = String.ValueOf(qli.Product2.Dependent_on_Feature__c);
                if (!featureDependentLineItems.containsKey(key)) {
                    featureDependentLineItems.put(key, new List<QuoteLineItem>());
                }
                featureDependentLineItems.get(key).add(qli);
            }

            if (qli.Product2.Feature__c != null){
                productLineItems.add(qli);
            }
        }

        for (QuoteLineItem qli : productLineItems) {
            String key = String.ValueOf(qli.Product2.Feature__c);

            if (featureDependentLineItems.containsKey(key)){
                for (QuoteLineItem qliToUpdate: featureDependentLineItems.get(key)) {
                    if (qli.Quantity != qliToUpdate.Quantity) {
                        qliToUpdate.Quantity = qli.Quantity;
                        qliToUpdate.Zero_Quantity__c = qli.Zero_Quantity__c;
                        featureDependentLineItemsToUpdate.put(qliToUpdate.Id, qliToUpdate);
                    }

                    if (qli.Zero_Quantity__c != qliToUpdate.Zero_Quantity__c && qli.Quantity == qliToUpdate.Quantity &&
                            qli.Zero_Quantity__c == true && qliToUpdate.Quantity == 1) {
                        qliToUpdate.Zero_Quantity__c = true;
                        featureDependentLineItemsToUpdate.put(qliToUpdate.Id, qliToUpdate);
                    }

                    if (qli.Zero_Quantity__c != qliToUpdate.Zero_Quantity__c && qli.Quantity == qliToUpdate.Quantity &&
                            qli.Zero_Quantity__c == false && qliToUpdate.Quantity == 1) {
                        qliToUpdate.Zero_Quantity__c = false;
                        featureDependentLineItemsToUpdate.put(qliToUpdate.Id, qliToUpdate);
                    }
                }
            }

        }


        if(!featureDependentLineItemsToUpdate.isEmpty()){
            update featureDependentLineItemsToUpdate.values();
        }
    }

    @AuraEnabled
    public static void commonPhonesDependencyUpdate(String quoteId){

        // is DigitalLine Hot Desking QuoteLineItem With Entitlement in Cart
        Boolean isDigiLineHotDeskWithEnt = false;
        List<QuoteLineItem> digiLineHotDeskItemsInCart = new List<QuoteLineItem>();
        List<QuoteLineItem> commonPhoneItemsInCart = new List<QuoteLineItem>();
        List<QuoteLineItem> itemsToDelete = new List<QuoteLineItem>();
        List<QuoteLineItem> itemsToUpdate = new List<QuoteLineItem>();
        List<QuoteLineItem> itemsToInsert = new List<QuoteLineItem>();
        List<PriceBookEntry> digiLineHotDeskPriceBookEntries = new List<PriceBookEntry>();
        Decimal commonPhonesQuantity = 0;

        Quote quote = [
                SELECT Id, Upsell_Status__c, AccountId, Pricebook2Id, CurrencyIsoCode,
                (SELECT Id, Product2.Name, Product2.Family, Product2.Feature__c, Product2.Dependent_on_Feature__c,
                        Zero_Quantity__c, Entitlement__c, Quantity, CurrencyIsoCode, QuoteId
                FROM QuoteLineItems)
                FROM Quote
                WHERE Id = :quoteId
        ];

        List<Entitlement__c> entitlements = [
                SELECT Id, Product__c, Discount__c, Discount_Type__c, Quantity__c, EffectivePrice__c,
                        Active__c, Product__r.Family, Product__r.Edition__c, Account__c,
                        Product__r.Product_Type__c, Product__r.Name, Product__r.ExtID__c, Product__r.Feature__c, Product__r.Sub_Category__c
                FROM Entitlement__c
                WHERE Account__c = :quote.AccountId
                AND Active__c = true
        ];

        List<PriceBookEntry> priceBookEntries = [
                SELECT Id, CurrencyIsoCode, Pricebook2Id, Product2Id, UnitPrice, Per_Line__c,
                        Min_Quantity__c, Product2.Description, Pricebook2.Line_Range_Min__c,
                        Product2.Dependent_on_Feature__c, Product2.Matcher_Formula__c,
                        Product2.Feature__c
                FROM PriceBookEntry
                WHERE Pricebook2Id = :quote.Pricebook2Id
        ];

        // Loop through PricebookEntries
        for (PriceBookEntry priceBookEntry : priceBookEntries){

            if (priceBookEntry.Product2.Feature__c == DIGITALLINE_HOT_DESKING_FEATURE){
                digiLineHotDeskPriceBookEntries.add(priceBookEntry);
            }

        }

        // Loop through QuoteLineItems On Quote
        for (QuoteLineItem qli : quote.QuoteLineItems){

            // DigitalLine Hot Desking Items
            if (qli.Product2.Feature__c == DIGITALLINE_HOT_DESKING_FEATURE){

                digiLineHotDeskItemsInCart.add(qli);

                if (String.isNotBlank(qli.Entitlement__c)){
                    isDigiLineHotDeskWithEnt = true;
                }

            }

            // Common Phones Items
            if (COMMON_PHONES_FAMILY.equalsIgnoreCase(qli.Product2.Family)){
                commonPhoneItemsInCart.add(qli);

                Decimal qliQuantity = qli.Zero_Quantity__c == true ? 0 : qli.Quantity;
                commonPhonesQuantity = commonPhonesQuantity + qliQuantity;
            }

        }

        if (commonPhoneItemsInCart.size() == 0) {
            // No common Phones in cart

            if (digiLineHotDeskItemsInCart.size() > 0){
                // There are DigitalLine Hot Desking items in cart

                if (!QuoteHelper.STATUS_NEW_CUSTOMER.equalsIgnoreCase(quote.Upsell_Status__c)
                        && isDigiLineHotDeskWithEnt){
                    // Update if upsell and there are entitlements for hot desking

                    for (QuoteLineItem digiLineHotDeskItem : digiLineHotDeskItemsInCart){
                        digiLineHotDeskItem = setQliQuantity(digiLineHotDeskItem, 0);
                    }
                    itemsToUpdate.addAll(digiLineHotDeskItemsInCart);

                } else {
                    // Delete if New Customer

                    itemsToDelete.addAll(digiLineHotDeskItemsInCart);

                }

            }

        } else {
            // There are common phones in cart

            if (digiLineHotDeskItemsInCart.size() > 0) {
                // There are DigitalLine Hot Desking items in cart. Update them

                for (QuoteLineItem digiLineHotDeskItem : digiLineHotDeskItemsInCart){
                    digiLineHotDeskItem = setQliQuantity(digiLineHotDeskItem, commonPhonesQuantity);
                    itemsToUpdate.add(digiLineHotDeskItem);
                }

            } else {
                // There are no DigitalLine Hot Desking items in cart. Insert them

                for (PricebookEntry digiLineHotDeskPriceBookEntry : digiLineHotDeskPriceBookEntries) {

                    if(quote.CurrencyIsoCode == digiLineHotDeskPriceBookEntry.CurrencyIsoCode){

                        QuoteLineItem newQ = new QuoteLineItem(
                                ServiceDate = date.today(),
                                Description = digiLineHotDeskPriceBookEntry.Product2.Description,
                                UnitPrice = digiLineHotDeskPriceBookEntry.UnitPrice,
                                QuoteId = quote.Id,
                                PriceBookEntryId = digiLineHotDeskPriceBookEntry.Id,
                                Product2Id = digiLineHotDeskPriceBookEntry.Product2Id
                        );

                        // Set Quantity
                        newQ = setQliQuantity(newQ, commonPhonesQuantity);

                        // Match Entitlement
                        if(entitlements.size() > 0) {

                            Entitlement__c matchedEntitlement = getEntitlementForProduct(entitlements, digiLineHotDeskPriceBookEntry.Product2);

                            if(matchedEntitlement != null) {
                                newQ.Entitlement__c = matchedEntitlement.Id;
                            }

                        }

                        itemsToInsert.add(newQ);

                    }

                }

            }

        }

        // Delete Items
        if (itemsToDelete.size() > 0){

            try{
                Map<String, List<QuoteLineItem>> actionToDependentItemsMap =
                    QuoteLineItemHelper.getDependentOnFeatureItemsOnDelete(itemsToDelete, quote.QuoteLineItems);

                itemsToDelete.addAll(actionToDependentItemsMap.get('delete'));
                delete itemsToDelete;
                if(actionToDependentItemsMap.get('update').size() > 0) {
                    update actionToDependentItemsMap.get('update');
                }
            } catch (DMLException e) {
                AquivaHelper.throwAuraException(e.getDmlMessage(0));
            }
        }

        // Update Items
        if (itemsToUpdate.size() > 0){
            try{
                List<QuoteLineItem> dependentItemsList =
                    QuoteLineItemHelper.getDependentOnFeatureItemsOnUpdate(itemsToUpdate, quote.QuoteLineItems);

                itemsToUpdate.addAll(dependentItemsList);
                update itemsToUpdate;
            } catch (DMLException e) {
                AquivaHelper.throwAuraException(e.getDmlMessage(0));
            }
        }

        // Insert Items
        if (itemsToInsert.size() > 0){
            try{
                List<QuoteLineItem> dependentItemsList =
                    QuoteLineItemHelper.getDependentOnFeatureItemsOnInsert(
                            itemsToInsert,
                            priceBookEntries,
                            entitlements,
                            quote.QuoteLineItems,
                            new List<Quote>{quote}
                    );

                itemsToInsert.addAll(dependentItemsList);

                upsert itemsToInsert;
            } catch (DMLException e) {
                AquivaHelper.throwAuraException(e.getDmlMessage(0));
            }
        }
    }

    public static QuoteLineItem setQliQuantity(QuoteLineItem qli, Decimal quantity){

        Boolean zeroQuantity = false;
        if (quantity == 0 ){
            zeroQuantity = true;
            quantity = 1;
        }
        qli.Quantity = quantity;
        qli.Zero_Quantity__c = zeroQuantity;

        return qli;
    }

    public static Entitlement__c getEntitlementForProduct(List<Entitlement__c> entitlements, Product2 product2) {
        List<Entitlement__c> matcherResult = (Entitlement__c[]) RecordsMatcher.match(entitlements, product2, 'Matcher_Formula__c');
        Entitlement__c matchingEntitlement = (matcherResult.size() > 0 ? matcherResult[0] : null);

        return matchingEntitlement;
    }

    private static Decimal getNumberOfPhones(List <Entitlement__c> entitlements, String family) {
        Decimal numberOfPhones = 0;
        for (Entitlement__c entl : entitlements) {
            if (entl.Product__r.Family == family) {
                numberOfPhones += entl.Quantity__c;
            }
        }
        return numberOfPhones;
    }

    private static void updateEstimatedTaxesRequestFailedField(String quoteIdString, Decimal status) {
        Id quoteId = Id.valueOf(quoteIdString);
        Quote qt = [SELECT Id, Estimated_Taxes_Request_Failed__c FROM Quote WHERE Id =:quoteId];
        qt.Estimated_Taxes_Request_Failed__c = !(new Set<Decimal>{ 200, 202 }.contains(status));
        update qt;
    }

    /**
     * Fix number of Extended Enterprise Support products according to service plan
     *
     * @see Test_ExtendedEnterpriseSupport Test Class
     * @see QuoteLineItemHelper.handleExtendedEnterpriseSupport Implementation
     *
     * @param quoteId
     */
    @AuraEnabled
    public static void handleExtendedEnterpriseSupport(Id quoteId) {
        if (String.isBlank(quoteId)) {
            AquivaHelper.throwAuraException('Quote Id is required');
        }

        try {
            Quote quote = [
                    SELECT Id, AccountId, Pricebook2Id, CurrencyIsoCode, RecordType.Name, (
                            SELECT Id, Product2Id, Product_Type__c, Product2.Feature__c, Product2.Family, Quantity,
                                    QuoteId, Quote.Package_Info__c, Zero_Quantity__c, NewQuantity__c, Product2.Seat_Range_Min__c,
                                    Product2.Seat_Range_Max__c, Entitlement__r.Id, Deactivated__c,
                                    Entitlement__r.Quantity__c, Entitlement__r.DisplayQuantity__c, Product2.Name,
                                    Product2.Charge_Term__c, Quote.RecordTypeId, Entitlement__r.Product__r.Charge_Term__c
                            FROM QuoteLineItems
                    )
                    FROM Quote
                    WHERE Id = :quoteId
            ];

            List<PricebookEntry> pricebookEntriesFromSF = [
                    SELECT Id, Product2Id, Product2.Name, Product2.Family, Product2.Charge_Term__c, UnitPrice,
                            Product2.Description, Product2.Sub_Category__c, Product2.Edition__c, Product2.Seat_Range_Min__c,
                            Product2.Seat_Range_Max__c, Product2.Feature__c, Pricebook2Id, Pricebook2.isStandard, isActive
                    FROM PricebookEntry
                    WHERE Pricebook2Id = :quote.Pricebook2Id
            ];

            Map<String, List<QuoteLineItem>> result =
                    QuoteLineItemHelper.handleExtendedEnterpriseSupport(quote.QuoteLineItems, pricebookEntriesFromSF);

            if (result.get(QuoteLineItemHelper.ACTION_DELETE).size() > 0) {

                // if we need to perform 2 operations on QuoteLineItems(delete and Upsert) - skip Totals Calculation for the first operation
                if(result.get(QuoteLineItemHelper.ACTION_UPSERT).size() > 0) {
                    OpportunityTotals.bypassOpportnuityUpdate = true;
                    QuoteLineItemTriggerHelper.bypassSalesRepErase = true;
                }

                delete result.get(QuoteLineItemHelper.ACTION_DELETE);

                OpportunityTotals.bypassOpportnuityUpdate = false;
                QuoteLineItemTriggerHelper.bypassSalesRepErase = false;
            }

            if (result.get(QuoteLineItemHelper.ACTION_UPSERT).size() > 0) {
                upsert result.get(QuoteLineItemHelper.ACTION_UPSERT);
            }

        } catch (Exception e) {
            AquivaHelper.throwAuraException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<Asset> getAssets(Id accountId) {
        return [
                SELECT Id, Name, Product2Id, Quantity, Delivered_Quantity__c,
                    Discount_Number__c, Discount_Type__c, Unit_Price__c
                FROM Asset
                WHERE AccountId = :accountId
        ];
    }

    @AuraEnabled
    public static Map<Id,Boolean> getQliPhaseMap (List<String> qlisIds) {
        return PhaseManagementController.getQliPhaseMap(qlisIds);
    }

    @AuraEnabled
    public static ProcessInstanceWorkitem getProcessInstanceWorkitem(Id legalApprovalId) {
        return [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId = :legalApprovalId LIMIT 1];
    }

    @AuraEnabled
    public static ProcessInstance getApprovalProcessStatus(Id legalApprovalId) {
        return [SELECT Id, Status FROM ProcessInstance WHERE TargetObjectId = :legalApprovalId LIMIT 1];
    }

    @AuraEnabled
    public static List<ApprovalNeededQualifiers.QuantityChangeMessage> checkNeedForApproval(Map<Id, QuoteLineItem> changedItems) {

        if(changedItems == null || changedItems.isEmpty()) {
            return new List<ApprovalNeededQualifiers.QuantityChangeMessage>();
        }

        Map<Id, QuoteLineItem> qlis = new Map<Id, QuoteLineItem>([SELECT Id, Quantity,
            NewQuantity__c, Approved_Quantity__c, Approved_Discount__c,
            Approved_Discount_Type__c, Discount, Discount_Value__c,
            Last_Approved_Quantity__c, Last_Approved_Discount__c,
            Last_Approved_Discount_Type__c, Discount_type__c,
            Quote.RecordTypeId, Product2.Name,
            Entitlement__c, Entitlement__r.Discount_Type__c,
            Entitlement__r.Discount__c, Entitlement__r.Price__c,
            Asset__c, Asset__r.Unit_Price__c, Asset__r.Discount_Type__c,
            Asset__r.Discount_Number__c, Quote.Approved_Status__c, Product2.ExtID__c
            FROM QuoteLineItem
            WHERE Id IN :changedItems.keySet()]);

        ApprovalNeededQualifiers.ApprovalNeededChecker myChecker = new ApprovalNeededQualifiers.ApprovalNeededChecker();

        ApprovalNeededQualifiers.QLIQuantityChangeQualifier qliQuantityChange = new ApprovalNeededQualifiers.QLIQuantityChangeQualifier(qlis);
        myChecker.addQualifier(
            qliQuantityChange
        );

        myChecker.addQualifier(
            new ApprovalNeededQualifiers.CurrentDiscountsQualifier()
        );

        myChecker.addQualifier(
            new ApprovalNeededQualifiers.ProServCurrentDiscountsQualifier()
        );

        // run process
        Map<Id, Boolean> qliIdToNeedApprovalMap = myChecker.process(changedItems.values());

        List<ApprovalNeededQualifiers.QuantityChangeMessage> resultList = new List<ApprovalNeededQualifiers.QuantityChangeMessage>();

        for(Id qliId : qliIdToNeedApprovalMap.keySet()) {
            Boolean isApprovalNeeded = qliIdToNeedApprovalMap.get(qliId);
            if(isApprovalNeeded) {

                ApprovalNeededQualifiers.QuantityChangeMessage mess = qliQuantityChange.messagesMap.get(qliId);
                resultList.add(mess);
            }
        }

        return resultList;
    }

    @AuraEnabled
    public static List<Entitlement__c> getEntitlementsSync(String accId) {
        List<Entitlement__c> activeEntitlementsList = new List<Entitlement__c>();

        try{
            List <Entitlement__c> entsSynched =
                (List <Entitlement__c>) EntitlementSync.syncWithDWH(accId).data.get(EntitlementSync.ENTITLEMENT_RESPONSE_DATA_KEY);
            for(Entitlement__c ent : entsSynched) {
                if(ent.Active__c) {
                    activeEntitlementsList.add(ent);
                }
            }
        } catch(Exception e) {
            System.debug('Error during sync from Data Warehouse. Using Existing Entitlements.');
        }

        if(activeEntitlementsList.isEmpty()) {
            activeEntitlementsList = getEntitlements(accId);
        }

        return activeEntitlementsList;
    }

    @AuraEnabled
    public static List <PriceBookEntry> getPriceBookEntry(List<Id> productsId) {
        return [SELECT PriceBook2.Brand__r.Name, PriceBook2.Edition__c, PriceBook2.Line_Range_Max__c, PriceBook2.Name,
                        PriceBook2.Line_Range_Min__c, PriceBook2.Plan__c, PriceBook2.Service__c, PriceBook2.Tier_ID__c,
                        Product2.Charge_Term__c, Product2.Feature__c, Product2.Id, UnitPrice, CurrencyIsoCode
                FROM PriceBookEntry
                WHERE Product2Id IN: productsId
                AND UnitPrice > 0];
    }

    @AuraEnabled
    public static Response changeProservType(Quote quote,String proservType) {
        Response result = new Response();
        try{
            if (!proservType.equalsIgnoreCase(quote.ProServ_Type__c)) {
                quote.ProServ_Type__c = proservType;
                update quote;
                Map<String,String> params = new Map<String, String>();
                params.put('templateApiName', CC_PROSERV_CHANGED_PRODUCT);
                params.put('opportunityId', quote.OpportunityId);
                sendMail(params);
            }
        } catch (DmlException e){
            result.error(e);
        } catch (NullPointerException e){
            result.error(e);
        } catch (Exception e){
            result.warning(e.getMessage());
        }
        return result;
    }

    public static List<QuoteLineItem> getQuoteLineItemsById(Set<Id> idSet) {
        if (idSet.isEmpty()) {
            AquivaHelper.throwAuraException('Provide quote line items id');
        }
        List<QuoteLineItem> quoteLineItems = new List<QuoteLineItem>();

        try {
            String query = String.format('SELECT {0} ' +
                'FROM QuoteLineItem ' +
                'WHERE Id IN :idSet', new List<String>{
                QUOTE_LINE_ITEMS_FIELDS
            });

            quoteLineItems = Database.Query(query);

            for (QuoteLineItem qli : quoteLineItems) {
                if (qli.Zero_Quantity__c) {
                    qli.Quantity = 0;
                }
            }
        } catch (DMLException e) {
            System.debug(e);
            AquivaHelper.throwAuraException(e.getDmlMessage(0));
        }
        return quoteLineItems;
    }

    public static Boolean isProservAutomatedTemplate(String templateApiName){
        Proserv_Email_Country__mdt[] countries = [SELECT Email_Template__c FROM Proserv_Email_Country__mdt];
        List<String> emailTemplates = new List<String>();
        for(Proserv_Email_Country__mdt cm : countries){
            if(!emailTemplates.contains(cm.Email_Template__c)){
                emailTemplates.add(cm.Email_Template__c);
            }
        }
        Boolean isProservTemplate = emailTemplates.contains(templateApiName);
        return isProservTemplate;
    }

    @AuraEnabled
    public static Response getWizardDataWrapper(String options) {
        return getWizardData((RefreshOptions) JSON.deserialize(options, RefreshOptions.class));
    }

    class RefreshOptions{
        @AuraEnabled public Id accountId;
        @AuraEnabled public Id opportunityId;
        @AuraEnabled public Boolean opportunityLevel = false;
        @AuraEnabled public Boolean quotesLevel = false;
    }
    @AuraEnabled
    public static Response getWizardData(RefreshOptions options) {
        Response r = new Response();

        if (options.opportunityLevel) {
            r.setData('assets', getAssets(options.accountId));
        }

        if (options.opportunityLevel || options.quotesLevel) {
            r.setData('quotes', getQuotes(options.opportunityId));
            Response dsResp = DocuSignController.getEnvelopes(options.opportunityId, null);
            r.setData('isOpportunityHasActiveEnvelopes', dsResp.data.get('isOpportunityHasActiveEnvelopes'));
        }

        if (options.opportunityLevel && String.isNotBlank(options.opportunityId)) {
            Opportunity opp = getOpportunity(options.opportunityId);
            Package__c billingPackage = getBillingPackage(opp.AccountId);
            r.setData('opportunity', opp);
            r.setData('billingPackage', billingPackage);
        }

        if (options.opportunityLevel || options.quotesLevel) {
            Map<String, String> quotesSpecialTerms = QuoteHelper.getQuotesSpecialTerms();
            r.setData('specialTerms', quotesSpecialTerms);
        }

        return r;
    }

    private static Package__c getBillingPackage(Id accountId) {
        List<Package__c> packages = new PackageSelector()
                .selectPackagesForNewReferences(new List<Object> {new Set<Id>{accountId}})
                .executeQuery();
        Map <Id, Package__c> packageToProcessMap = PackageHelper.filterPackagesByService(packages, QuoteHelper.NGBS_OFFICE_PRODUCT);
        return packageToProcessMap.get(accountId);
    }


    private static Boolean isContainsChangeOrder(String opportunityId) {
        Boolean result = false;
        Opportunity opportunity;
        try {
            opportunity = [SELECT Id, Description FROM Opportunity WHERE Id =: opportunityId];
        } catch (Exception e) {
            PlatformLog.logException('Failed to get opportunity', e);
        }
        if (opportunity != null && String.isNotBlank(opportunity.Description)) {
            result = opportunity.Description.containsIgnoreCase('Change Order');
        }

        return result;
    }

    private static Boolean isCCProservType(String type) {
        return CC_PROSERV.equalsIgnoreCase(type);
    }

    private static Map<String, String> getProductExtToLicencesMap() {
        Map<String, String> result = new Map<String, String>();
        Map<String, ProservProductToLicenses__c> cs = ProservProductToLicenses__c.getAll();
        for (ProservProductToLicenses__c c : cs.values()) {
            result.put(c.Annual__c, c.Name);
            result.put(c.Monthly__c, c.Name);
        }

        return result;
    }

    @TestVisible
    private static String getQuoteRecordTypeName(Opportunity opp, String rtId) {
        Boolean isEngageOpp = OpportunityHelper.isEngage(opp);
        Boolean isCCProServ = CC_PROSERV_QUOTE_RT_ID == rtId;
        String recordTypeId = isEngageOpp && isCCProServ ? PROSERV_QUOTE_RT_ID : rtId;

        return QUOTE_RT_INFO_BY_ID.get(recordTypeId).getName();
    }

    public static BillingWrappers.QLIPackageInfo generatePackageInfoForQLI(Quote primaryQuote, QuoteLineItem proServQLI){
        BillingWrappers.QLIPackageInfo info = new BillingWrappers.QLIPackageInfo();
        try {
            if (primaryQuote.Package_Info__c != null) {
                List<BillingWrappers.QuotePackageInfo> pInfos =
                    (List<BillingWrappers.QuotePackageInfo>)
                        JSON.deserialize(primaryQuote.Package_Info__c, List<BillingWrappers.QuotePackageInfo>.class);
                if (pInfos.size() > 0) {
                    BillingWrappers.QuotePackageInfo pInfo = pInfos[0];

                    info = new BillingWrappers.QLIPackageInfo();
                    info.duration = proServQLI.Product2.Charge_Term__c;
                    info.Discount = new BillingWrappers.QLIPackageInfoDiscount();
                    info.Discount.Type = proServQLI.Discount_type__c == QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY? 'Money' : proServQLI.Discount_type__c;
                    info.Discount.Value = proServQLI.Discount_Value__c;
                    info.Price = proServQLI.UnitPrice;
                    info.Id = pInfo.id;
                    info.Version = pInfo.version;
                }
            }
        } catch (Exception e) {
            AquivaHelper.throwAuraException(e);
        }

        return info;
    }

    @AuraEnabled
    public static void unlockOrderAndPhases(String oppToDowngrade) {
        try {
            Feature_Toggle__c featureToggleSetting = Feature_Toggle__c.getInstance();

            Opportunity oppToUpdated = [
                SELECT Id, Parent_Order__c, DGW_Downgrade_Reason__c, Downgrade_Reason_Opp__c,
                    DGW_Why_is_the_opportunity_Delayed__c
                FROM Opportunity
                WHERE Id = :oppToDowngrade
            ];
            oppToUpdated.DGW_Downgrade_Reason__c = 'Delayed Opportunity';
            oppToUpdated.Downgrade_Reason_Opp__c = 'Delayed Opportunity';
            oppToUpdated.DGW_Why_is_the_opportunity_Delayed__c = 'No Need';
            oppToUpdated.StageName = OpportunityHelper.STAGE_NAME_DOWNGRADED;
            update oppToUpdated;

            if (featureToggleSetting.NewChangeOrderFlow__c) {

                List<Quote> quoteTo = [
                    SELECT Id, (
                        SELECT Id, Asset__c, OriginalOrderLineItem__c
                        FROM QuoteLineItems
                    )
                    FROM Quote
                    WHERE OpportunityId = :oppToDowngrade
                ];

                Map<Id, Id> orderItemIdToAssetIdMap = new Map<Id, Id>();
                for (Quote quoteTot : quoteTo) {
                    for (QuoteLineItem quoteLineItem : quoteTot.QuoteLineItems) {
                        orderItemIdToAssetIdMap.put(quoteLineItem.OriginalOrderLineItem__c, quoteLineItem.Asset__c);
                    }
                }

                List<OrderItem> orderItemsToUpdate = [SELECT Id, Asset__c
                    FROM OrderItem
                    WHERE Id IN :orderItemIdToAssetIdMap.keySet()
                ];

                for (OrderItem orderItem : orderItemsToUpdate) {
                    orderItem.Asset__c = orderItemIdToAssetIdMap.get(orderItem.Id);
                }

                update orderItemsToUpdate;
            }


            List<Order> orderToUpdate = new List<Order>();
            List<Phase__c> phasesToUpdate = new List<Phase__c>();
            Set<Id> recordsToUnlock = new Set<Id>();

            for (Order anOrder : [SELECT Id, Status, RelatedChangeOpportunity__c, (SELECT Id, Status__c FROM Phases__r WHERE Status__c =: PhaseHelper.STATUS_LOCKED)
                                  FROM Order WHERE Id =: oppToUpdated.Parent_Order__c ]){

                anOrder.Status = OpportunityHelper.isVerizon(oppToUpdated)
                        ? OrderHelper.STATUS_SUBMITTED_PARTNERS
                        : OrderHelper.STATUS_SUBMITTED;
                anOrder.RelatedChangeOpportunity__c = null;
                orderToUpdate.add(anOrder);

                recordsToUnlock.add(anOrder.Id);
                phasesToUpdate.addAll(anOrder.Phases__r);
            }

            if (phasesToUpdate.size() > 0) {
                for (Phase__c aPhase : phasesToUpdate) {
                    aPhase.Status__c = PhaseHelper.STATUS_NEW;
                    recordsToUnlock.add(aPhase.Id);
                }
                update phasesToUpdate;
            }

            if (orderToUpdate.size() > 0) {
                update orderToUpdate;
            }

            if (!recordsToUnlock.isEmpty()) {
                Approval.unlock(new List<Id>(recordsToUnlock));

            }
        } catch (DmlException e) {
            AquivaHelper.throwAuraException(e.getDmlMessage(0));
        }
    }

    @AuraEnabled
    public static void updateQuoteBillingAddress(String quoteId, String accountId){
        QuoteService.copyBillingAddressFromAccountToQuote(quoteId, accountId);
    }

    @TestVisible
    private static String getPackageDuration(BillingWrappers.QuotePackageInfo packageInfo) {
        return packageInfo != null && packageInfo.duration == Pricebook2Helper.PLAN_ANNUAL
            ? Pricebook2Helper.PLAN_ANNUAL
            : Pricebook2Helper.PLAN_MONTHLY_CONTRACT;
    }

    @AuraEnabled
    public static TaxesAmountWrapper getFreeServiceTaxes(String quoteId){
        TaxWrappers.SFDCRequestTax taxRequest = getTaxRequestBody(quoteId);

        System.debug(JSON.serialize(taxRequest));

        return getTaxesCallout(taxRequest);
    }

    public static TaxesAmountWrapper getTaxesCallout(TaxWrappers.SFDCRequestTax taxRequest) {
        Contact_Center_FSC__c settings = Contact_Center_FSC__c.getInstance(UserInfo.getUserId());
        if (settings == null || String.isEmpty(settings.Taxes_Endpoint__c)) {
            settings = Contact_Center_FSC__c.getInstance();
        }
        String taxesEndpoint = settings.Taxes_Endpoint__c;

        if (String.isEmpty(taxesEndpoint)) {
            throw new AuraHandledException('CC Taxes Endpoint not found');
        }

        TaxesAmountWrapper taxesAmountWrapper;
        HTTP http = new HTTP();
        HTTPRequest request = new HTTPRequest();

        request.setEndpoint(taxesEndpoint);
        request.setMethod('POST');
        request.setHeader('Content-Type','application/json');
        request.setTimeout(20000);
        request.setBody(JSON.serialize(taxRequest));

        HTTPResponse response = http.send(request);
        System.debug('response.getStatusCode()>>>>>>>>> ' + response.getStatusCode());
        System.debug('response.getStatus()>>>>>>>>> ' + response.getStatus());
        if(response.getStatusCode() == 200) {
            TaxWrappers.TaxResponse responseWrapper = getParsedResponseWrapper(response.getBody());
            taxesAmountWrapper = getTaxesAmount(responseWrapper);
        } else {
            throw new AuraHandledException(response.getBody());
        }

        return taxesAmountWrapper;
    }

    public static TaxWrappers.SFDCRequestTax getTaxRequestBody(String quoteId) {
        List<QuoteLineItem> qlisForRequest = [SELECT
                                                Id, Quote.Id, Quote.Account.BillingCity, Quote.Account.BillingCountry,
                                                Quote.Account.BillingPostalCode, Quote.Account.BillingState,
                                                Quantity, Product2.RC_Tax_Category__c, Product2.Name,
                                                Product2.Family, Total_Monthly__c, CurrencyIsoCode, Quote.Account.RC_User_ID__c
                                            FROM QuoteLineItem
                                            WHERE Product2.Family != 'Overage' AND Quote.Id = :quoteId];

        Account quoteAccount = qlisForRequest[0].Quote.Account;

        if (String.isBlank(quoteAccount.BillingCity) || String.isBlank(quoteAccount.BillingState)
                || String.isBlank(quoteAccount.BillingPostalCode) || String.isBlank(quoteAccount.BillingCountry)) {
            throw new AuraHandledException('Incorrect Account Billing Address');
        }

        String rcUserId = String.isBlank(quoteAccount.RC_User_ID__c) ? '0' : quoteAccount.RC_User_ID__c;

        String billingCountry = getBillingCountry(quoteAccount.BillingCountry);

        TaxWrappers.SFDCRequestTax requestBody = new TaxWrappers.SFDCRequestTax();
        requestBody.SFDCTaxRequest = new TaxWrappers.TaxRequest();

        TaxWrappers.TaxRequest taxRequest = new TaxWrappers.TaxRequest();
        taxRequest.requestType = 'quote';
        taxRequest.requestTimestamp = String.valueOf(DateTime.now());

        taxRequest.RequestData = new TaxWrappers.TaxRequestData();
        taxRequest.RequestData.userId = rcUserId;
        taxRequest.RequestData.quoteId = quoteId;

        taxRequest.RequestData.itemList = new List<TaxWrappers.TaxRequestItem>();

        for (QuoteLineItem qli : qlisForRequest) {
            if (String.isBlank(qli.Product2.RC_Tax_Category__c)) {
                throw new AuraHandledException('\'' + qli.Product2.Name + '\' doesn\'t have RC Tax Category');
            }

            TaxWrappers.TaxRequestItem item = new TaxWrappers.TaxRequestItem();
            item.lineId = qli.Id;
            item.amount = qli.Total_Monthly__c;
            item.NoOfLines = Integer.valueOf(qli.Quantity);
            item.taxCategory = qli.Product2.RC_Tax_Category__c;
            item.currencyCode = qli.CurrencyIsoCode;
            item.city = quoteAccount.BillingCity;
            item.state = quoteAccount.BillingState;
            item.postalCode = quoteAccount.BillingPostalCode;
            item.countryCode = billingCountry;

            taxRequest.RequestData.itemList.add(item);
        }

        requestBody.SFDCTaxRequest = taxRequest;
        System.debug('#### Request itemList size = ' + taxRequest.RequestData.itemList.size());
        return requestBody;
    }

    public static String getBillingCountry(String accountBillingCountry) {
        Map<String, String> countryMapping = SettingsService.getCountryCodes();
        if (countryMapping.keySet().contains(accountBillingCountry.toLowerCase())) {
            return countryMapping.get(accountBillingCountry.toLowerCase());
        } else {
            throw new AuraHandledException('Account Billing Country has a non-standard format');
        }
    }

    public static TaxWrappers.TaxResponse getParsedResponseWrapper (String json) {
        TaxWrappers.TaxResponse responseWrapper = TaxWrappers.parse(json);
        return responseWrapper;
    }

    public class TaxesAmountWrapper {
        @AuraEnabled public Decimal variableTaxesAmount;
        @AuraEnabled public Decimal fixedTaxesAmount;
        @AuraEnabled public String jsonResponse;
    }

    public static TaxesAmountWrapper getTaxesAmount(TaxWrappers.TaxResponse responseWrapper) {
        TaxesAmountWrapper taxWrapper = new TaxesAmountWrapper();
        Decimal fixedTaxesAmount = 0;
        Decimal variableTaxesAmount = 0;
        System.debug('#### Response itemList size = ' + responseWrapper.responseData.itemList.size());
        if (responseWrapper.responseData.status != 'success')  {
            throw new AuraHandledException(responseWrapper.responseData.message);
        }

        for (TaxWrappers.TaxResponseItem responseItem : responseWrapper.responseData.itemList) {
            if (responseItem.lineStatus != 'success') {
                throw new AuraHandledException('Quote Line Item :' + responseItem.lineId + ' , Message: ' + responseItem.lineMessage);
            }
            for (TaxWrappers.TaxResponseDataItem item : responseItem.taxData) {
                if (responseItem.RCTaxType.toLowerCase() == FIXED_TAX) {
                    fixedTaxesAmount += item.taxAmount;
                } else if (responseItem.RCTaxType.toLowerCase() == VARIABLE_TAX){
                    variableTaxesAmount += item.taxAmount;
                } else {
                    throw new AuraHandledException('Unexpected Tax Type');
                }
            }
        }

        System.debug('##### fixedTaxesAmount >>>>>' + fixedTaxesAmount);
        System.debug('##### variableTaxesAmount >>>>>' + variableTaxesAmount);
        taxWrapper.fixedTaxesAmount = fixedTaxesAmount.setscale(2);
        taxWrapper.variableTaxesAmount = variableTaxesAmount.setscale(2);
        taxWrapper.jsonResponse = JSON.serialize(responseWrapper);

        return taxWrapper;
    }

    @AuraEnabled
    public static void updateTargetPriceContactCenterARR(Map<String, Object> ccQuoteParams){
        Quote ccQuote = parseRequestParametersToQuoteForUpdatingTargetPriceContactCenterARR(ccQuoteParams);
        if (ccQuote == null) { return; }

        List<Quote> quotesToUpdate = new List<Quote>{ccQuote};

        try {
            update quotesToUpdate;
        } catch (DMLException e) {
            AquivaHelper.throwAuraException(e.getMessage());
        }
    }

    @TestVisible
    private static Quote parseRequestParametersToQuoteForUpdatingTargetPriceContactCenterARR(Map<String, Object> params) {
        Object targetPriceContactCenterARR = params.get('targetPriceContactCenterARR');

        Quote resultQuote = null;
        try {
            resultQuote = new Quote(
                Id = (Id) params.get('id'),
                OpportunityId = (Id) params.get('opportunityId'),
                TargetPriceContactCenterARR__c = targetPriceContactCenterARR != null
                    ? Double.valueOf(targetPriceContactCenterARR)
                    : null
            );
        } catch (Exception err) {
            PlatformLog.logException('QuotingToolQuoteApexController', err);
        }

        return resultQuote;
    }

    @AuraEnabled
    public static void createPSCase(String params) {
        BillingWrappers.CaseCreateParams caseParams = (BillingWrappers.CaseCreateParams) JSON.deserialize(params, BillingWrappers.CaseCreateParams.class);
        Map<SObjectField, Object> fieldsMap = CaseHelper.prepareCaseFields(caseParams);
        Case newCase = CaseHelper.buildCase(fieldsMap);
    }

    @AuraEnabled
    public static void enableLBOForPrimaryQuote(Id opportunityId) {
        List<Quote> quotesToUpdate = new List<Quote>();
        List<Quote> primaryQuotes = (List<Quote>) new QuoteSelector()
            .selectPrimaryQuotesByOpportunityIds(new Set<Id>{opportunityId})
            .selectFields(new List<String>{'OpportunityId', 'Enabled_LBO__c'})
            .executeQuery();

        for (Quote qt : primaryQuotes) {
            if (!qt.Enabled_LBO__c) {
                qt.Enabled_LBO__c = true;
                quotesToUpdate.add(qt);
            }
        }

        if(!quotesToUpdate.isEmpty()) {
            update quotesToUpdate;
        }
    }
}