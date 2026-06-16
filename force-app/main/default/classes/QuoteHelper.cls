/**
 * This is helper class for Quote standard object
 * Keep all static variables and helper methods related to it here
 *
 * It's might be better to keep here helper methods that do not do any SOQL
 * so they could be reused in triggers or controllers
 */
public with sharing class QuoteHelper {
    @TestVisible
    private static final String CAN_NOT_PACKAGE_INFO_ERROR = 'Can not get Package_Info__c from Quote';
    // Quote Payment Method
    public static final String ANNUAL_PAYMENT_METHOD = 'Annual Payment Period';
    public static final String MONTHLY_PAYMENT_METHOD = 'Monthly Payment Period';

    // Quote Describe Object
    public static Schema.DescribeSObjectResult DESCRIBE {
        get {
            if(DESCRIBE == null) {
                DESCRIBE = Quote.SObjectType.getDescribe();
            }
            return DESCRIBE;
        }
        set;
    }
    public static final Map<String, SObjectField> FIELDS_MAP = DESCRIBE?.fields.getMap();
    private static Set<String> QUOTE_UNIQUE_FIELDS = SObjectDescribeHelper.getDescribe(Quote.SObjectType).getUniqueFieldNames();

    // Record Types
    public static final String RT_NAME_SALES = 'Sales Quote';
    public static final String RT_NAME_PROSERV = 'ProServ Quote';
    public static final String RT_NAME_CC_PROSERV = 'CC ProServ Quote';
    public static final String RT_NAME_BILLING = 'Sales Quote v2';
    public static final String RT_NAME_CONTACT_CENTER = 'Contact Center Quote';
    public static final String RT_NAME_POC_QUOTE = 'POC Quote';

    public static final String ALLOWED_RT_NAME_BILLING_PROSERV = 'Service Billing ProServ';
    public static final String TOTAL_CHANGES_TEMPLATE = 'TotalChangesTemplate';
    public static final String CHANGED_DETAILS_TEMPLATE = 'ChangedDetailsTemplate';
    public static final String QUOTE_DETAILS_TEMPLATE = 'QuoteDetailsTemplate';
    public static final String RC_EVENT_SERVICES_PRODUCT = Constants.CONST_RC_EVENT;
    public static Map<String, Schema.RecordTypeInfo> RT_INFO_BY_NAME {
        get {
            if(RT_INFO_BY_NAME == null) {
                RT_INFO_BY_NAME = DESCRIBE.getRecordTypeInfosByName();
            }
            return RT_INFO_BY_NAME;
        }
        set;
    }

    public static Map<Id, Schema.RecordTypeInfo> RT_INFO_BY_ID {
        get {
            if(RT_INFO_BY_ID == null) {
                RT_INFO_BY_ID = DESCRIBE.getRecordTypeInfosById();
            }
            return RT_INFO_BY_ID;
        }
        set;
    }

    public static final Id RT_ID_SALES = RT_INFO_BY_NAME.get(RT_NAME_SALES).getRecordTypeId();
    public static final Id RT_ID_PROSERV = RT_INFO_BY_NAME.get(RT_NAME_PROSERV).getRecordTypeId();
    public static final Id RT_ID_CC_PROSERV = RT_INFO_BY_NAME.get(RT_NAME_CC_PROSERV).getRecordTypeId();
    public static final Id RT_ID_BILLING = RT_INFO_BY_NAME.get(RT_NAME_BILLING).getRecordTypeId();
    public static final Id RT_ID_CC = RT_INFO_BY_NAME.get(RT_NAME_CONTACT_CENTER).getRecordTypeId();
    public static final Id RT_ID_POC = RT_INFO_BY_NAME.get(RT_NAME_POC_QUOTE).getRecordTypeId();

    public static final String SHIPPING_OPTION_GROUND = 'Ground';
    public static final String SHIPPING_OPTION_OVERNIGHT = 'Overnight';
    public static final String SHIPPING_OPTION_2_DAY = '2 Day';
    public static final String FREESHIPPING = 'Free shipping';

    public static Set<String> NGBS_QUOTES_RT_IDS = new Set<String>{
        RT_ID_BILLING,
        RT_ID_CC
    };

    public static Set<String> PRIMARY_QUOTES_RT_IDS = new Set<String>{
        RT_ID_BILLING,
        RT_ID_POC
    };

    public static final Set<String> PROSERV_QUOTE_DEVELOPER_ID_SET = new Set<String>{
        QuoteHelper.RT_ID_PROSERV, QuoteHelper.RT_ID_CC_PROSERV
    };

    public static final Set<Id> QUOTE_RTS_FOR_APPROVED_FIELDS = new Set<Id>{
        RT_ID_SALES,
        RT_ID_BILLING,
        RT_ID_PROSERV,
        RT_ID_CC_PROSERV,
        RT_ID_CC
    };

    // Upsell_Status__c
    public static final String STATUS_UPSELL = 'Upsell';
    public static final String STATUS_UPGRADE = 'Upgrade';
    public static final String STATUS_NEW_CUSTOMER = 'New';

    public static final Set<String> QUOTE_UPSELL_STATUSES = new Set<String>{
        STATUS_UPSELL,
        STATUS_UPGRADE,
        STATUS_NEW_CUSTOMER
    };

    public static final Set<String> QUOTE_EB_UPSELL_STATUSES = new Set<String>{
        STATUS_UPSELL,
        STATUS_UPGRADE
    };

    public static final List<String> APPROVAL_STATUSES_PENDING = new List<String> {
            'Pending ProServ Approval',
            'Pending L1 Approval',
            'Pending L2 Approval',
            'Pending L3 Approval',
            'Pending L4 Approval',
            'Pending L5 Approval',
            'Pending Downsell Approval',
            'Pending Finance Approval'
    };

    // Approved_Status__c
    public static final String APPROVAL_STATUS_APPROVED = 'Approved';
    public static final String APPROVAL_STATUS_REJECTED = 'Rejected';
    public static final String APPROVAL_STATUS_NOT_REQUIRED = 'Not Required';
    public static final String APPROVAL_STATUS_REQUIRED = 'Required';
    public static final String APPROVAL_STATUS_RECALLED = 'Recalled';

    public static final Set<String> APPROVAL_STATUSES_NOT_REQUIRED = new Set<String> {
            APPROVAL_STATUS_APPROVED,
            APPROVAL_STATUS_NOT_REQUIRED,
            null
    };

    public static final List<String> APPROVAL_STATUSES_PRE =  new List<String> { APPROVAL_STATUS_REQUIRED, 'Recalled', 'Rejected' };
    public static final List<String> APPROVAL_STATUSES_POST = new List<String> { APPROVAL_STATUS_APPROVED };

    // Approval_Type__c
    public static final string FINANCE_QUEUE_APPROVAL_TYPE = 'Finance Queue';
    public static final String DOWNSELL_QUEUE_APPORVAL_TYPE = 'In Contract Downsell';

    // ProServ_Status__c
    public static final String PROSERVSTATUS_CANCELLED = 'Cancelled';
    public static final String PROSERVSTATUS_CREATED = 'Created';
    public static final String PROSERVSTATUS_SYNCED = 'Synced';
    public static final String PROSERVSTATUS_SOLD = 'Sold';
    public static final String PROSERVSTATUS_OUT_FOR_SIGNATURE = 'Out for Signature';
    public static final String PROSERVSTATUS_IN_PROGRESS = 'In progress';

    public static final Set<String> PROSERVSTATUS_SET_POST = new Set<String>{
            PROSERVSTATUS_SOLD, PROSERVSTATUS_SYNCED, PROSERVSTATUS_OUT_FOR_SIGNATURE
    };

    // Quote.Payment_Plan__c
    public static final String PAYMENT_PLAN_ANNUAL = 'Annual';

    // NGBS Product Types
    public static final String NGBS_OFFICE_PRODUCT = Constants.CONST_OFFICE;
    public static final String NGBS_RCCC_PRODUCT = Constants.CONST_RCCC;
    public static final String NGBS_ENGAGE_DIGITAL_PRODUCT = Constants.CONST_ENGAGE_DIGITAL;
    public static final String NGBS_ENGAGE_VOICE_PRODUCT = Constants.CONST_ENGAGE_VOICE;
    public static final String NGBS_ENGAGE_VOICE_LEGACY_PRODUCT = Constants.CONST_ENGAGE_VOICE_LEGACY;
    public static final String NGBS_ENGAGE_DIGITAL_LEGACY_PRODUCT = Constants.CONST_ENGAGE_DIGITAL_LEGACY;
    public static final String NGBS_FAX_PRODUCT = Constants.CONST_FAX;
    public static final String NGBS_RCCC_LEGACY_PRODUCT = Constants.CONST_RCCC_LEGACY;
    public static final String NGBS_RCEVENTS_PRODUCT = Constants.CONST_RC_EVENT;
    public static final String NGBS_PROFESSIONAL_SERVICES_PRODUCT = 'Professional Services';
    //Package_Name__c
    public static final String RINGCX_PACKAGE_NAME = 'RingCX';

    public static final Set<String> NGBS_ENGAGES_STANDALONE = new Set<String> {
        NGBS_ENGAGE_DIGITAL_PRODUCT,
        NGBS_ENGAGE_VOICE_PRODUCT
    };

    public static final Set<String> CREATE_TECHNICAL_ACCOUNT_FOR_SERVICES = new Set<String> {
        QuoteHelper.NGBS_RCCC_PRODUCT,
        QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT,
        QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT
    };

    public static final String QUOTE_TYPE_AGREEMENT = 'Agreement';
    public static final String QUOTE_TYPE_QUOTE = 'Quote';

    // count of Quote.Level_#_Approver__c fields
    public static final Integer MAX_APPROVER_LEVELS = 5;

    // Quote.Special_Terms__c values for
    public static final Set <String> FREE_WEEKS_TERMS = new Set<String>{ '1 Free Week of Service',
                                                                         '2 Free Weeks of Service',
                                                                         '3 Free Weeks of Service',
                                                                         '4 Free Weeks of Service',
                                                                         '5 Free Weeks of Service',
                                                                         '6 Free Weeks of Service',
                                                                         '7 Free Weeks of Service',
                                                                         '8 Free Weeks of Service',
                                                                         '10 Free Weeks of Service',
                                                                         '12 Free Weeks of Service' };
    // Quote.Special_Terms__c values
    public static final String FREE_MONTH_1 = '1 Free Month of Service';
    public static final String FREE_MONTH_2 = '2 Free Months of Service';
    public static final String FREE_MONTH_3 = '3 Free Months of Service';
    public static final String FREE_MONTH_4 = '4 Free Months of Service';
    public static final String FREE_MONTH_5 = '5 Free Months of Service';
    public static final String FREE_MONTH_6 = '6 Free Months of Service';
    public static final Set <String> FREE_MONTHS_TERMS = new Set<String>{
        '1 Free Month of Service',
        '2 Free Months of Service',
        '3 Free Months of Service',
        '4 Free Months of Service',
        '5 Free Months of Service',
        '6 Free Months of Service',
        '7 Free Months of Service',
        '8 Free Months of Service',
        '9 Free Months of Service',
        '10 Free Months of Service',
        '11 Free Months of Service',
        '12 Free Months of Service',
        '13 Free Months of Service',
        '14 Free Months of Service',
        '15 Free Months of Service',
        '16 Free Months of Service',
        '17 Free Months of Service',
        '18 Free Months of Service',
        '19 Free Months of Service',
        '20 Free Months of Service',
        '21 Free Months of Service',
        '22 Free Months of Service',
        '23 Free Months of Service',
        '24 Free Months of Service'
    };

    public static final List<Schema.PicklistEntry> specialTermsList =
        SFDescribeHelper.getOptions('Quote','Special_Terms__c');

    public static final List<Schema.PicklistEntry> freeShippingTermsList =
        SFDescribeHelper.getOptions('Quote','FreeShippingTerms__c');

    public static final List<String> existingCustomerTerms = new List<String> {
        '2-day Shipping for Ground Pricing',
        'Free shipping'
    };

    // Quote.Status
    public static final String QUOTE_STATUS_ACTIVE = 'Active';
    public static final String QUOTE_STATUS_PRESENTED = 'Presented';
    public static final String QUOTE_STATUS_DRAFT = 'Draft';
    public static final String QUOTE_STATUS_TERMINATED = 'Terminated';
    public static final String QUOTE_STATUS_ACCEPTED = 'Accepted';
    public static final String QUOTE_STATUS_EXECUTED = 'Executed';

    // Quote.PaymentMethod__c
    public static final String PAYMENT_METHOD_INVOICE = 'Invoice';
    public static final String PAYMENT_METHOD_CREDIT_CARD = 'CreditCard';
    public static final String PAYMENT_METHOD_INVOICE_ON_BEHALF = 'InvoiceOnBehalf';
    public static final String PAYMENT_METHOD_DIRECT_DEBIT = 'DirectDebit';
    public static final String PAYMENT_METHOD_WHOLESALE = 'InvoiceWholesale';

    /* NGBS Package offer type */
    public static final String PACKAGE_OFFER_TYPE_FREE = 'Free';
    public static final String PACKAGE_OFFER_TYPE_TRIAL = 'Trial';
    public static final String PACKAGE_OFFER_TYPE_POC = 'ProofOfConcept';

    public final static String OFFER_TYPE_BUY = 'Buy';
    public final static String OFFER_TYPE_REGULAR = 'Regular';
    public final static String OFFER_TYPE_TRIAL = 'Trial';
    public final static String OFFER_TYPE_POC = 'POC';
    public final static String OFFER_TYPE_FREE = 'Free';

    /* NGBS Package edition */
    public static final String PACKAGE_EDITION_ESSENTIALS = 'Essentials';

    public static final String QUOTE_NOT_FOUND = 'Quote not found';

    /* ProServ Ignite Statuses */
    public static final String STATUS_PRO_SERV_IGNITE_INITIATED = 'Initiated ProServ from PRM Portal';
    public static final String STATUS_PRO_SERV_IGNITE_CANCELLED = 'Cancelled ProServ from PRM Portal';

    public static final Set<sObjectField> QUOTE_TOTALS_FIELDS = new Set<sObjectField>{
        Quote.Total_One_Time__c,
        Quote.Total_MRR_New__c,
        Quote.Total_ARR__c,
        Quote.Total_Initial_Payment__c,
        Quote.Total_First_Year_Cost__c,
        Quote.Total_One_Time_Discount__c,
        Quote.Total_MRR_Discount__c,
        Quote.Total_ARR_Discount__c,
        Quote.Total_Initial_Payment_Discount__c,
        Quote.Total_First_Year_Discount__c,
        Quote.Total_One_Time_with_Taxes__c,
        Quote.Total_MRR_with_Taxes__c,
        Quote.Total_ARR_with_Taxes__c,
        Quote.Total_Initial_Payment_with_Taxes__c,
        Quote.Total_First_Year_Cost_with_Taxes__c,
        Quote.Contact_Center_Total_One_Time__c,
        Quote.Contact_Center_Total_MRR__c,
        Quote.Contact_Center_Total_ARR__c,
        Quote.Contact_Center_Total_Initial_Payment__c,
        Quote.Contact_Center_Total_First_Year_Cost__c,
        Quote.Contact_Center_Total_One_Time_Discount__c,
        Quote.Contact_Center_Total_MRR_Discount__c,
        Quote.Contact_Center_Total_ARR_Discount__c,
        Quote.ContactCenterTotalInitialPaymentDiscount__c,
        Quote.Contact_Center_Total_First_Year_Discount__c,
        Quote.Delta_MRR__c,
        Quote.Delta_ARR__c,
        Quote.Delta_CC_MRR__c,
        Quote.Delta_CC_ARR__c,
        Quote.Entitlement_Total_ARR__c,
        Quote.Entitlement_Total_MRR__c,
        Quote.Contact_Center_Entitlement_Total_ARR__c,
        Quote.Contact_Center_Entitlement_Total_MRR__c,
        Quote.Credit_Amount__c,
        Quote.Initial_Term_months__c,
        Quote.Term_months__c,
        Quote.Special_Terms__c,
        Quote.Estimated_Hardware__c,
        Quote.IsPrimary__c,
        Quote.ProServ_Status__c
    };

    public class QuotesStorage {
        public List<Quote> technicalQuotes;
        public Quote masterQuote;

        public QuotesStorage(List<Quote> quotes) {
            List<Quote> technicalQuotes = new List<Quote>();
            Quote masterQuote = new Quote();
            for (Quote quote: quotes) {
                if (quote.MasterQuote__c != null) {
                    technicalQuotes.add(quote);
                } else {
                    masterQuote = quote;
                }
            }

            this.technicalQuotes = technicalQuotes;
            this.masterQuote = masterQuote;
        }
    }

    /**
    * Get Primary or last modified quote from list
    * @param  quotes A list of quotes. Quotes should have fields:
    *                 Quote.isPrimary__c
    *                 Quote.LastModifiedDate
    *
    * @return        Primary Quote or last modified
    */
    public static Quote getPrimaryQuote(List<Quote> quotes) {
        return getPrimaryQuote(quotes, false);
    }
    public static Quote getPrimaryQuote(List<Quote> quotes, Boolean isNewBilling) {
        if (quotes == null
            || quotes.isEmpty()
            || (quotes.size() == 1 && quotes.contains(null))) {
            return null;
        }

        if(isNewBilling == null) {
            isNewBilling = false;
        }

        Quote primaryQuote = null;

        for (Quote qt: quotes) {

            Boolean isBillingQuote = (qt.RecordTypeId == RT_ID_BILLING);
            if(isNewBilling == isBillingQuote) {
                if (qt.isPrimary__c){
                    primaryQuote = qt;
                    break;
                }
                if (primaryQuote == null){
                    primaryQuote = qt;
                    continue;
                }
                if (primaryQuote.LastModifiedDate < qt.LastModifiedDate){
                    primaryQuote = qt;
                }
            }

        }

        return primaryQuote;
    }

    /**
     * Get Quote with ProServ Record Type
     * @param quotes A list of quotes. Quotes should have fields:
     *                   Quote.RecordTypeId
     *
     * @return Quote Object with ProServ Record Type
     */
    public static Quote getProServQuote(List<Quote> quotes) {
        return getProServQuote(quotes, false);
    }

    public static Quote getProServQuote(List<Quote> quotes, Boolean isBillingOpportunity) {
        if (quotes == null
            || quotes.isEmpty()
            || (quotes.size() == 1 && quotes.contains(null))) {
        return null;
    }

        Quote proservQuote;
        for (Quote qt : quotes) {
            if (qt.RecordTypeId != RT_ID_PROSERV) {
                continue;
            }
            if (isBillingOpportunity) {
                if (isBillingProServPricebook(qt)) {
                    proservQuote = qt;
                }
            } else {
                proservQuote = qt;
            }
        }
        return proservQuote;
    }


    /**
     * Get Quote with CC ProServ Record Type
     * @param quotes A list of quotes. Quotes should have fields:
     *                   Quote.RecordTypeId
     *
     * @return Quote Object with CC ProServ Record Type
     */
    public static Quote getCCProServQuote(List<Quote> quotes) {
        return getCCProServQuote(quotes, false);
    }

    public static Quote getCCProServQuote(List<Quote> quotes, Boolean isBillingOpportunity) {
        // To do: if required, billing filtration should be here
        for (Quote qt : quotes) {
            if (isCCProservQuote(qt)) {
                return qt;
            }
        }
        return null;
    }

    public static Quote getCCQuote(List<Quote> quotes) {
        if (quotes == null || quotes.isEmpty()) {
            return null;
        }

        Quote ccQuote = null;
        for (Quote qt : quotes) {

            if(qt.RecordTypeId == RT_ID_CC) {
                ccQuote = qt;
                break;
            }
        }
        return ccQuote;
    }

    public static Quote getMPCCQuote(List<Quote> quotes) {
        if (quotes == null || quotes.isEmpty()) {
            return null;
        }

        Quote ccMPQuote = null;
        for (Quote qt : quotes) {

            if(qt.ServiceName__c == NGBS_RCCC_PRODUCT) {
                ccMPQuote = qt;
                break;
            }
        }
        return ccMPQuote;
    }

    public static Quote getMPEngageQuote(List<Quote> quotes) {
        if (quotes == null || quotes.isEmpty()) {
            return null;
        }

        Quote engageMPQuote = null;
        for (Quote qt : quotes) {

            if(OpportunityHelper.ENGAGE_TIERS.contains(qt.ServiceName__c)) {
                engageMPQuote = qt;
                break;
            }
        }
        return engageMPQuote;
    }

    public static Boolean isNGBSQuote(Quote qt) {
        return isNewBillingQuote(qt) || isPOCQuote(qt);
    }

    public static Boolean isNGBSQuote(QuoteLineItem qli) {
        return isNewBillingQuote(qli) || isPOCQuote(qli);
    }

    public static Quote getPOCQuote(List<Quote> quotes, Boolean isBillingOpportunity) {
        // To do: if required, billing filtration should be here
        for (Quote qt : quotes) {
            if (isPOCQuote(qt) && qt.isPrimary__c) {
                return qt;
            }
        }
        return null;
    }
    /**
     * Calculate ProServ SOW Discount total for list of quoteLineItems
     *
     * Documentation:
     * https://aquiva.atlassian.net/wiki/spaces/RC/pages/192446527/Quote+Totals#QuoteTotals-TotalProServSOWDiscount
     *
     * @see Test_QuoteLineItemTriggerHelper.test_calcTotalProServSOWDiscount Test method
     *
     * Require fields
     * QuoteLineItem.Product2.Sub_Category__c, QuoteLineItem.Product2.Sub_Category__c, QuoteLineItem.Product2.Discount
     *
     * @param quoteQLIList
     *
     * @return
     */
    public static Decimal calcTotalProServSOWDiscount(List<QuoteLineItem> quoteQLIList){
        Decimal sumProServOneTime = 0;

        for( QuoteLineItem qli : quoteQLIList ) {
            if ( Product2Helper.SUBCATEGORY_PROSERV.equalsIgnoreCase(qli.Product2.Sub_Category__c)
                    && Product2Helper.CHARGE_TERM_ONE_TIME.equalsIgnoreCase(qli.Product2.Charge_Term__c)){
                sumProServOneTime += QuoteLineItemHelper.getDiscountValue(qli) * QuoteLineItemHelper.getResultingQuantity(qli);
            }
        }

        return sumProServOneTime;
    }

    /**
     * Depending on opp.Is_Billing_Opportunity__c filter out NGBS or non-NGBS quotes
     *
     * @param quotes
     * @param opp
     *
     * @return
     */
    public static List<Quote> filterBillingQuotes(List<Quote> quotes, Opportunity opp){
        List<Quote> filteredQuotes = new List<Quote>();

        Boolean isTelusOrBT = (OpportunityHelper.BRAND_BT_BUSINESS.equalsIgnoreCase(opp.Brand_Name__c)
            || RingCentralHelper.BRAND_TELUS_BUSINESS_CONNECT.equalsIgnoreCase(opp.Brand_Name__c));

        for (Quote quote : quotes) {
            Boolean isBillingQuote = (
                quote.RecordTypeId == QuoteHelper.RT_ID_BILLING ||
                quote.RecordTypeId == QuoteHelper.RT_ID_POC ||
                quote.RecordTypeId == QuoteHelper.RT_ID_CC &&
                    (
                        String.isBlank(opp.Brand_Name__c)
                        || !isTelusOrBT
                    )
            );
            if ((opp.Is_Billing_Opportunity__c && isBillingQuote) || (!opp.Is_Billing_Opportunity__c && !isBillingQuote)) {
                filteredQuotes.add(quote);
            }
        }

        return filteredQuotes;
    }

    /**
     * [filterProservQuotes description]
     * @param  quotes    [List of quotes]
     * @param  isProserv [toggle boolean]
     * @return           [Depending on isProserv filter out proserv or non proserv quotes]
     */
    public static List<Quote> filterProservQuotes(List<Quote> quotes, Boolean isProserv){
        List<Quote> filteredQuotes = new List<Quote>();

        for (Quote quote : quotes) {
            if (isProserv && (quote.RecordTypeId == RT_ID_PROSERV || quote.RecordTypeId == RT_ID_CC_PROSERV)
                || !isProserv && quote.RecordTypeId != RT_ID_PROSERV && quote.RecordTypeId != RT_ID_CC_PROSERV) {
                filteredQuotes.add(quote);
            }
        }

        return filteredQuotes;
    }

    public static Map<String, Decimal> calculateFreeValuesOnQuote(List<QuoteLineItem> qlis, Integer numberOfFreeTerms) {

        Feature_Toggle__c featureToggle = Feature_Toggle__c.getInstance();

        numberOfFreeTerms = numberOfFreeTerms != null ? numberOfFreeTerms : 0;
        Decimal creditAmount = 0;
        Decimal freeServiceTaxes = 0;

        for (QuoteLineItem qli : qlis) {
            /* Contact center and Technical licenses should not participate in free service credit values calculation */
            if (qli.Product2.Family == Product2Helper.FAMILY_TECHNICAL_LICENSE
                || QuoteLineItemHelper.isUsageLicense(qli)) {
                continue;
            }
            /* Process sales quote */
            if (isSalesQuote(qli)) {
                /* For sales quote fixed taxes are stored on qli itself (Fixed_Taxes_Amount__c field)*/
                if (!Product2Helper.isTaxes(qli.Product2)) {
                    Double fixedTaxesAmount = qli.Fixed_Taxes_Amount__c == null ? 0 : qli.Fixed_Taxes_Amount__c;
                    /* When annual service plan is chosen */
                    if (QuoteLineItemHelper.isAnnual(qli)) {
                        creditAmount += qli.TotalPrice * numberOfFreeTerms / 12;
                        freeServiceTaxes += fixedTaxesAmount * numberOfFreeTerms / 12;
                    /* When monthly service plan is chosen */
                    } else if (QuoteLineItemHelper.isMonthly(qli) || QuoteLineItemHelper.isMonthlyContract(qli)) {
                        creditAmount += qli.TotalPrice * numberOfFreeTerms;
                        freeServiceTaxes += fixedTaxesAmount * numberOfFreeTerms;
                    }
                }
            /* Process billing quote */
            } else if (!featureToggle.CalculateFSCInQW__c &&
                isNewBillingQuote(qli)
                && BillingWrappers.parseQuotePackageInfo(qli.Quote.Package_Info__c).contract != null) {
                /* Taxes are calculated based qli taxes qli */
                if (!Product2Helper.isTaxes(qli.Product2)) {
                    if (AccountHelper.isTrial(qli.Quote.Account)) {
                        if (!qli.IsHiddenLicense__c) {
                            creditAmount += calculateCreditAmountForTrial(qli, numberOfFreeTerms);
                        }
                    } else {
                        creditAmount += calculateCreditAmountForNewBusiness(qli, numberOfFreeTerms);
                    }
                } else {
                    freeServiceTaxes += calculateFreeServiceTaxes(qli, numberOfFreeTerms);
                }
            } else if (isCCQuote(qli) && qli.Product2.Family != Product2Helper.FAMILY_OVERAGE) {
                if (QuoteLineItemHelper.isAnnual(qli)) {
                    creditAmount += qli.TotalPrice * numberOfFreeTerms / 12;
                /* When monthly service plan is chosen */
                } else if (QuoteLineItemHelper.isMonthly(qli) || QuoteLineItemHelper.isMonthlyContract(qli)) {
                    creditAmount += qli.TotalPrice * numberOfFreeTerms;
                }
            }
        }
        creditAmount = creditAmount != 0 ? creditAmount : null;
        freeServiceTaxes = freeServiceTaxes != 0 ? freeServiceTaxes : null;

        Map<String, Decimal> valuesMapToReturn = new Map<String, Decimal>{
            'freeDiscount' => creditAmount,
            'freeServiceTaxes' => freeServiceTaxes
        };
        return valuesMapToReturn;
    }

    private static Decimal calculateCreditAmountForTrial(QuoteLineItem qli, Integer numberOfFreeTerms) {
        Decimal creditAmountForQli = 0;

        if (QuoteLineItemHelper.isAnnual(qli)) {
            creditAmountForQli = qli.EffectivePriceNew__c * qli.NewQuantity__c * numberOfFreeTerms / 12;
        } else if (QuoteLineItemHelper.isMonthly(qli) || QuoteLineItemHelper.isMonthlyContract(qli)) {
            creditAmountForQli = qli.EffectivePriceNew__c * qli.NewQuantity__c * numberOfFreeTerms;
        }

        return creditAmountForQli;
    }

    private static Decimal calculateCreditAmountForNewBusiness(QuoteLineItem qli, Integer numberOfFreeTerms) {
        Decimal creditAmountForQli = 0;

        if (QuoteLineItemHelper.isAnnual(qli)) {
            creditAmountForQli = qli.TotalPrice * numberOfFreeTerms / 12;
        } else if (QuoteLineItemHelper.isMonthly(qli) || QuoteLineItemHelper.isMonthlyContract(qli)) {
            creditAmountForQli = qli.TotalPrice * numberOfFreeTerms;
        }

        return creditAmountForQli;
    }

    private static Decimal calculateFreeServiceTaxes(QuoteLineItem qli, Integer numberOfFreeTerms) {
        Decimal freeServiceTaxesForQli = 0;

        if (QuoteLineItemHelper.isAnnualBillingCycle(qli)) {

            freeServiceTaxesForQli = qli.TotalPrice * numberOfFreeTerms / 12;
        } else if (QuoteLineItemHelper.isMonthlyBillingCycle(qli)) {
            freeServiceTaxesForQli = qli.TotalPrice * numberOfFreeTerms;
        }

        return freeServiceTaxesForQli;
    }

    /**
     * Gets numbers from string
     * @param String value
     *
     * @return Integer value
     */
    public static Integer getNumberFromString(String str) {
        String numericString = '';
        for(Integer i = 0; i < str.length(); i++) {
            String s = str.mid(i,1);
            if(s.isNumeric()) {
                numericString += s;
            }
        }
        return (numericString == '' ? null : Integer.valueOf(numericString));
    }

    /**
     * Check if quote is Sales
     * Old Sales quotes does not have record type
     * @param quote              Quote to check
     * @param quote.RecordTypeId Record Type Id
     *
     * @return true || false
     */
    public static Boolean isSalesQuote(Quote quote) {
        return quote.RecordTypeId == null || quote.RecordTypeId == RT_ID_SALES;
    }

    public static Boolean isSalesQuote(QuoteLineItem qli) {
      return qli.QuoteRecordType__c == RT_NAME_SALES;
    }

    /**
     * Determine quote for new billing by RecordTypeId
     */
    public static Boolean isNewBillingQuote(Quote qt) {
        return qt != null && qt.RecordTypeId == RT_ID_BILLING;
    }
    public static Boolean isNewBillingQuote(QuoteLineItem qli) {
        return qli != null && qli.QuoteRecordType__c == RT_NAME_BILLING;
    }

    public static Boolean isCCQuote(Quote qt) {
        return qt != null && qt.RecordTypeId == RT_ID_CC;
    }

    public static Boolean isCCQuote(QuoteLineItem qli) {
        return qli != null && qli.QuoteRecordType__c == RT_NAME_CONTACT_CENTER;
    }


    public static Boolean isPOCQuote(Quote qt) {
        return qt != null && qt.RecordTypeId == RT_ID_POC;
    }

    public static Boolean isPOCQuote(QuoteLineItem qli) {
        return qli != null && qli.QuoteRecordType__c == RT_NAME_POC_QUOTE;
    }

    public static Boolean isBillingProServPricebook(Quote qt) {
        return (qt!=null && qt.Pricebook2.AllowedRecordType__c!=null && (qt.Pricebook2.AllowedRecordType__c.containsIgnoreCase(ALLOWED_RT_NAME_BILLING_PROSERV)) && (qt.RecordTypeId == RT_ID_PROSERV));
    }

    public static Boolean isAnnual(Quote qt) {
        return qt?.Payment_Plan__c == PAYMENT_PLAN_ANNUAL;
    }

    /*
     * For right determing of plan in quote (New Billing and Old)
     *
     * RecordTypeId, Pricebook2.Plan__c, Package_Info__c
     */
    public static String getPlan(Quote qt) {
        String result;

        if (qt == null) {
            return result;
        }

        if (isNewBillingQuote(qt) || isPOCQuote(qt)) {
            List<PackageInfo> pInfoList = getPackageInfo(qt.Package_Info__c);
            PackageInfo pInfo = (pInfoList.size() != 0) ? pInfoList[0] : null;

            result = getDurationFromPackageInfo(pInfo);
        } else {
            result = qt.Pricebook2.Plan__c;
        }

        if(result == null) {
            result = qt.Payment_Plan__c;
        }

        return result;
    }

    public static Boolean isMultiProductQuoteHasServicePackage(Quote primaryQuote, String serviceName) {
        return isMultiProductQuoteHasServicePackage(primaryQuote, new List<String>{serviceName});
    }

    public static Boolean isMultiProductQuoteHasServicePackage(Quote primaryQuote, List<String> serviceNames) {
        PackageInfo pInfo = new PackageInfo();
        Boolean isServiceExist = false;
        if (primaryQuote != null && !primaryQuote.IsMultiProductTechnicalQuote__c) {
            List<PackageInfo> pInfoList = getPackageInfo(primaryQuote.Package_Info__c);
            for (String serviceName: serviceNames) {
                pInfo = getPackageInfoByServiceName(serviceName, pInfoList);
                if (pInfo?.ProductName != null) {
                    isServiceExist = true;
                    break;
                }
            }
        }
        return isServiceExist;
    }

    public static String getBillingQuoteProductName(Quote qt) {
        String result = '';

        if (isNewBillingQuote(qt)) {
            List<PackageInfo> pInfoList = getPackageInfo(qt.Package_Info__c);

            PackageInfo pInfo = (pInfoList.size() != 0)
                ? (pInfoList.size() > 1)
                    ? getPackageInfoByServiceName(NGBS_OFFICE_PRODUCT, pInfoList)
                    : pInfoList[0]
                : null;

            if (pInfo != null && String.isNotBlank(pInfo.ProductName)) {
                result = pInfo.ProductName;
            }
        }

        return result;
    }

    public static Boolean isQuotePackageInfoHasMultipleProducts(Quote qt) {
        if (qt == null || String.isBlank(qt.Package_Info__c)) {
            return false;
        }

        List<BillingWrappers.QuotePackageInfo> pInfo = new BillingWrappers.QuotePackageInfoWrapper().parseQuotePackageInfo(qt.Package_Info__c);

        return pInfo.size() > 1;
    }

    private static PackageInfo getPackageInfoByServiceName(String serviceName, List<PackageInfo> pInfoList) {
        PackageInfo pInfo = new PackageInfo();
        for (PackageInfo pkgInfo: pInfoList) {
            if (pkgInfo.ProductName == serviceName) {
                pInfo = pkgInfo;
            }
        }
        return pInfo;
    }

    public class PackageInfo {
        public String Id;
        public String Version;
        public String ProductName;
        public String Duration;
        public String OfferType;

        public PackageInfo_Contract Contract;
        public PackageInfo_GlobalPackageLimits[] GlobalPackageLimits;
    }
    public class PackageInfo_GlobalPackageLimits {

    }
    public class PackageInfo_Contract {
        public String Id;
    }

    public static String getDurationFromPackageInfo(PackageInfo pInfo) {

        if(pInfo == null) {
            return null;
        }

        String result = pInfo.Duration;

        if(pInfo.Contract != null) {
            if(result == Product2Helper.CHARGE_TERM_ANNUAL) {
                result = Product2Helper.CHARGE_TERM_ANNUAL_CONTRACT;
            }
            if(result == Product2Helper.CHARGE_TERM_MONTHLY) {
                result = Product2Helper.CHARGE_TERM_MONTHLY_CONTRACT;
            }
        }

        return result;
    }

    public static String getDurationFromPackageInfoWithoutContract(PackageInfo pInfo) {
        return pInfo == null ? null : pInfo.Duration;
    }

    public static List<PackageInfo> getPackageInfo(String packageInfo) {
        List<PackageInfo> result = new List<PackageInfo>();

        if (packageInfo == null) {
            return result;
        }

        try {
            result = (List<PackageInfo>) JSON.deserialize(packageInfo, List<PackageInfo>.class);
        } catch(Exception e) {
            System.debug('Need to handle');
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
        }

        return result;
    }

    public static String getPackageId(String quotePackageInfo) {
        String packageId;
        if (String.isNotBlank(quotePackageInfo)) {
            List<BillingWrappers.QuotePackageInfo> pInfoList = (List<BillingWrappers.QuotePackageInfo>) JSON.deserialize(quotePackageInfo, List<BillingWrappers.QuotePackageInfo>.class);

            if (!pInfoList.isEmpty()) {
                BillingWrappers.QuotePackageInfo pInfo = pInfoList[0];
                packageId = pInfo.packageInfo.id;
            }
        }

        return packageId;
    }

    public static Boolean isCorrectBillingAddress(Quote qt) {
        return qt.Billing_Zip_Postal_Code__c == qt.Account.BillingPostalCode
                && qt.Billing_City__c == qt.Account.BillingCity
                && qt.Billing_Country__c == qt.Account.BillingCountry
                && qt.Billing_State_Province__c == qt.Account.BillingState
                && qt.Billing_Street__c == qt.Account.BillingStreet;
    }

    public static void populateAddressOnQuote(Quote q, Account acc) {
        q.Address_Line__c = acc.BillingStreet;
        q.City__c = acc.BillingCity;
        q.State__c = acc.BillingState;
        q.Postal_Code__c = acc.BillingPostalCode;
        q.Country__c = acc.BillingCountry;
    }

    public static Boolean isHasErrors(Quote q) {
        return q != null
            && (q.InvalidDiscountedPhonesQuantity__c
            || q.InvalidGlobalOfficePhonesQuantity__c
            || q.InvalidLimitedExtensionPhonesQuantity__c
            || q.Invalid_Number_of_800_Setups__c
            || q.Invalid_Number_of_Int_TF_Setups__c
            || q.Invalid_Number_of_Vanity_Setups__c
            || q.Required_Area_Codes_are_empty__c
            || q.Invalid_GO_LE_Phones_Quantity__c);
    }
    /**
     * [isChangeOrderQuote description]
     * @param  qt          [Quote to validate]
     * @param  proservType [Expectations:
     *                        'proserv'   => check if proserv change order quote
     *                        'proservCC' => check if cc proserv change order quote
     *                         null       => check if proserv or cc proserv change oreder ]
     * @return             [Is change order quote]
     */
    public static Boolean isChangeOrderQuote(Quote qt, String proservType) {
        List<Quote> quotes = new List<Quote>{ qt };

        Quote primaryQuote = QuoteHelper.getPrimaryQuote(quotes);
        Quote proServQuote = QuoteHelper.getProServQuote(quotes);
        Quote ccProServQuote = QuoteHelper.getCCProServQuote(quotes);

        Quote ccOrProServQuote = proServQuote != null ? proServQuote : ccProServQuote;

        switch on proservType {
            when 'proserv' {
                ccOrProServQuote = proServQuote;
            }
            when 'proservCC' {
                ccOrProServQuote = ccProServQuote;
            }
            when else {
                ccOrProServQuote = proServQuote != null ? proServQuote : ccProServQuote;
            }
        }

        return ccOrProServQuote != null && primaryQuote != null
                && ccOrProServQuote.Upsell_Status__c == QuoteHelper.STATUS_UPSELL;
    }

    public static Boolean isProServSyncRequired(Quote proservQuote) {
        return proservQuote != null
            && !isCancelled(proservQuote)
            && !isSynced(proservQuote)
            && !isOutForSignature(proservQuote)
            && !isSold(proservQuote);
    }

    public static Boolean isCancelled(Quote proservQuote) {
        return proservQuote != null
            && proservQuote.ProServ_Status__c == PROSERVSTATUS_CANCELLED;
    }

    public static Boolean isSynced(Quote proservQuote) {
        return proservQuote != null
            && proservQuote.ProServ_Status__c == PROSERVSTATUS_SYNCED;
    }

    public static Boolean isOutForSignature(Quote proservQuote) {
        return proservQuote != null
            && proservQuote.ProServ_Status__c == PROSERVSTATUS_OUT_FOR_SIGNATURE;
    }

    public static Boolean isSold(Quote proservQuote) {
        return proservQuote != null
            && proservQuote.ProServ_Status__c == PROSERVSTATUS_SOLD;
    }

    public static Boolean isProservQuote(Quote proservQuote) {
        return proservQuote != null && proservQuote.RecordTypeId == RT_ID_PROSERV;
    }

    public static Boolean isCCProservQuote(Quote proservQuote) {
        return proservQuote != null && proservQuote.RecordTypeId == RT_ID_CC_PROSERV;
    }

    public static Boolean isProServOrCCProServ(Quote qt) {
        return PROSERV_QUOTE_DEVELOPER_ID_SET.contains(qt?.RecordTypeId);
    }

    public static Boolean isProservSoldRequired(Quote proservQuote) {
        return (isProservQuote(proservQuote) || isCCProservQuote(proservQuote))
            && !isCancelled(proservQuote) && !isSold(proservQuote);
    }

    public static Boolean isUpgrade(Quote qt) {
        return qt != null && isUpgrade(qt.Upsell_Status__c);
    }

    public static Boolean isUpsell(Quote qt) {
        return qt != null && isUpsell(qt.Upsell_Status__c);
    }

    public static Boolean isNew(Quote qt) {
        return qt != null && isNew(qt.Upsell_Status__c);
    }

    public static Boolean isExistingBusiness(Quote qt) {
        return qt != null && isExistingBusiness(qt.Upsell_Status__c);
    }

    public static Boolean isNewBusiness(Quote qt) {
        if (qt == null) {
            return false;
        }
        return qt.IsMultiProductTechnicalQuote__c
           ? String.isBlank(qt.BillingPackage__c)
           : String.isBlank(qt.Account.RC_User_ID__c) && String.isBlank(qt.Account.Billing_ID__c);
    }


    public static Boolean isBillingNotSynced(Quote qt) {
        return qt != null && String.isNotBlank(qt.Account.RC_User_ID__c) && String.isBlank(qt.Account.Billing_ID__c);
    }

    public static Boolean isUpgrade(String upsellStatus) {
        return upsellStatus == STATUS_UPGRADE;
    }

    public static Boolean isUpsell(String upsellStatus) {
        return upsellStatus == STATUS_UPSELL;
    }

    public static Boolean isNew(String upsellStatus) {
        return upsellStatus == STATUS_NEW_CUSTOMER;
    }

    public static Boolean isExistingBusiness(String upsellStatus) {
        return isUpsell(upsellStatus) || isUpgrade(upsellStatus);
    }

    public static Boolean isCCProServEngagementRequired(Quote primaryQuote, Quote ccProservQuote) {
        if (primaryQuote == null) {
            return false;
        }
        Boolean hasNotBypassedCCItems = false;
        Boolean hasCCEntitlements = false;
        Boolean hasBypassedCCFamilies = false;
        Boolean hasItemsWithChangedQuantity = false;
        Boolean hasContactCenterProductsInCart = isHasContactCenterProductsInCart(new List<Quote>{primaryQuote}, primaryQuote);
        Boolean isUpsellUpgrade = isExistingBusiness(primaryQuote);

        Set<String> familySetToByPass = new Set<String>{Product2Helper.FAMILY_MINUTES_BUNDLE, Product2Helper.FAMILY_SUPPORT_PACKAGE};
        for (QuoteLineItem qli : primaryQuote.QuoteLineItems) {

            if (isUpsellUpgrade) {
                if (!hasContactCenterProductsInCart) {
                    continue;
                }

                Boolean isBypassFamily = familySetToByPass.contains(qli.Product2.Family);

                if (QuoteLineItemHelper.getQuantity(qli) != 0
                    && !qli.Deactivated__c
                    && !isBypassFamily) {
                    hasItemsWithChangedQuantity = true;
                }

                if (qli.Entitlement__c != null) {
                    hasCCEntitlements = true;

                    if (isBypassFamily) {
                        hasBypassedCCFamilies = true;
                    }

                    if(isBypassFamily) {
                        hasBypassedCCFamilies = true;
                    } else {
                        hasNotBypassedCCItems = true;
                    }
                }
            }
        }

        Boolean bypassEngagementRequire = isUpsellUpgrade
            && !hasItemsWithChangedQuantity
            && (!hasBypassedCCFamilies || (hasCCEntitlements && hasBypassedCCFamilies))
            && !hasNotBypassedCCItems;

        return hasContactCenterProductsInCart // Primary Quote has Contact Center Products in cart
        // CC Quote not exist
        && ccProservQuote == null
        // Bypass requirement (B-3556) not met
        && !bypassEngagementRequire;
    }

    public static Boolean isCCQuoteRequiresCCProserv(Quote ccQuote, Quote ccProservQuote) {
        return ccQuote != null & ccProServQuote == null;
    }

    public static String getCCCategory(List<QuoteLineItem> qliList) {
        Map<String,String> ccCategories = new Map<String,String>{
            'Contact Center' => 'Contact Center',
            'RingCentral Contact Center' => 'RC Contact Center'
        };
        String quoteMainSubCategory;
        for (QuoteLineItem qli : qliList) {
            if (ccCategories.containsKey(qli.Product2.Sub_Category__c)) {
                quoteMainSubCategory = ccCategories.get(qli.Product2.Sub_Category__c);
                break;
            }
        }
        return quoteMainSubCategory;
    }

    public static Boolean isHasContactCenterProductsInCart(List<Quote> quoteList, Quote currentQuote) {
        if (quoteList == null || quoteList.isEmpty() || currentQuote == null) {
            return false;
        }

        Boolean hasContactCenterProduct = false;
        Quote ccQuote = getCCQuote(quoteList);
        if(ccQuote != null && !ccQuote.QuoteLineItems.isEmpty()) {
            hasContactCenterProduct = true;
        } else {
            Quote qt = getQuoteById(quoteList, currentQuote.Id);
            if (qt.QuoteLineItems.isEmpty()) {
                return false;
            }
            for (QuoteLineItem qli : qt.QuoteLineItems) {
                if (Product2Helper.CONTACT_CENTER_SUBCATEGORIES.contains(qli.Product2.Sub_Category__c)) {
                    hasContactCenterProduct = true;
                    break;
                }
            }
        }
        return hasContactCenterProduct;
    }

    public static Boolean isQuoteHasChangesOnUpsell(Quote q) {
        if (q.QuoteLineItems == null) {
            AquivaHelper.throwAquivaException('No QuoteLineItems passed for upsell primary quote');
        }
        return isQuoteHasChangesOnUpsell(q.QuoteLineItems);
    }

    public static Boolean isQuoteHasChangesOnUpsell(List<QuoteLineItem> qliList) {
        if (qliList == null || qliList.isEmpty()) {
            AquivaHelper.throwAquivaException('No QuoteLineItems passed for upsell primary quote');
        }

        for (QuoteLineItem qli : qliList) {
            if (QuoteLineItemHelper.isQliDifferentFromEntitlement(qli)) {
                return true;
            }
        }
        return false;
    }


    public static List<Schema.PicklistEntry> quoteBasedSpecialTerms(String quoteStatus) {
        if (quoteStatus != STATUS_NEW_CUSTOMER) {
            return SFDescribeHelper.getFilteredPicklist(existingCustomerTerms, specialTermsList);
        } else {
            return specialTermsList;
        }
    }

    public static Map <String, String> getQuotesSpecialTerms() {
        Map<String, String> quotesSpecialTerms = new Map<String, String>();
        for (String status : QUOTE_UPSELL_STATUSES) {
            quotesSpecialTerms.put(status, JSON.serialize(quoteBasedSpecialTerms(status)));
        }
        return quotesSpecialTerms;
    }

    public static String getTemplate(String templateName) {
        String customerQuoteTemplateId;
        List<RC_Quote_Templates__c> quoteTemplates = RC_Quote_Templates__c.getAll().values();

        if (quoteTemplates.isEmpty() || String.isBlank(templateName)) {
            return customerQuoteTemplateId;
        }

        for (RC_Quote_Templates__c qTemplate : quoteTemplates) {
            if (qTemplate.Name == templateName) {
                customerQuoteTemplateId = qTemplate.TemplateId__c;
            }
        }
        return customerQuoteTemplateId;
    }

    public static Quote getQuoteById(List<Quote> quoteList, Id quoteId) {
        if(quoteList == null || quoteList.isEmpty() || quoteId == null) {
            return null;
        } else {
            return new Map<Id, Quote>(ListHelper.filterOutNulls(quoteList)).get(quoteId);
        }
    }

    public static Opportunity getOpportunityToUpdateTierName(Opportunity opp, Quote quote) {
        Opportunity oppToUpdate;
        String productName = getProductName(quote.Package_Info__c);

        if (String.isNotBlank(productName) && productName != opp?.Tier_Name__c) {
            oppToUpdate = opp;
            oppToUpdate.Tier_Name__c = productName;
        }
        return oppToUpdate;
    }

    @TestVisible
    private static String getProductName(String packageInfo) {
        String productName;
        List<BillingWrappers.QuotePackageInfo> pInfo = new List<BillingWrappers.QuotePackageInfo>();
        if (String.isNotBlank(packageInfo)) {
            pInfo = (List<BillingWrappers.QuotePackageInfo>) JSON.deserialize(packageInfo, List<BillingWrappers.QuotePackageInfo>.class);
        }
        if (!pInfo.isEmpty()) {
            productName = pInfo.size() > 1 ? NGBS_OFFICE_PRODUCT : pInfo[0].productName;
        }
        return productName;
    }

    public static List<String> getProductNames(String packageInfo) {
        List<String> productNames = new List<String>();
        List<PackageInfo> pInfos = new List<PackageInfo>();
        if (String.isNotBlank(packageInfo)) {
            pInfos = (List<PackageInfo>) JSON.deserialize(packageInfo, List<PackageInfo>.class);
        }
        if (!pInfos.isEmpty()) {
            for (PackageInfo pi : pInfos) {
                productNames.add(pi.ProductName);
            }
        }
        return productNames;
    }

    public static Boolean isDownsell(List<QuoteLineItem> qliList) {
        Boolean result = false;
        for (QuoteLineItem qli : qliList) {
            if (qli.Quantity < 0) {
                result = true;
                break;
            }
        }

        return result;
    }

    public static Boolean isNGBSUpgrade(List<QuoteLineItem> qliList) {
        Boolean result = false;
        for (QuoteLineItem qli : qliList) {
            if (qli.Entitlement__r != null && qli.Entitlement__r.Price__c != qli.UnitPrice) {
                result = true;
                break;
            }
        }

        return result;
    }

    public static Boolean isUnitPriceOrEffectivePriceChanged(Quote primaryQuote) {
        Boolean isPriceChanged = false;
        if (primaryQuote == null || primaryQuote.QuoteLineItems == null) {
            return isPriceChanged;
        }
        for (QuoteLineItem qli : primaryQuote.QuoteLineItems) {
            if (qli.Product2.Family == Product2Helper.FAMILY_TAXES) {
                continue;
            }
            Decimal qliEffPrice = NumberHelper.roundCurrency(qli.EffectivePrice__c, 2, RoundingMode.HALF_UP);
            Decimal entEffPrice = 0;
            Decimal qliUnitPrice = NumberHelper.roundCurrency(qli.UnitPrice, 2, RoundingMode.HALF_UP);
            Decimal entUnitPrice = 0;

            if (qli.Entitlement__c != null) {
                entEffPrice = NumberHelper.roundCurrency(qli.Entitlement__r.EffectivePrice__c, 2, RoundingMode.HALF_UP);
                entUnitPrice = NumberHelper.roundCurrency(qli.Entitlement__r.Price__c, 2, RoundingMode.HALF_UP);
            } else {
                continue;
            }
            if ((qliEffPrice != entEffPrice) || (qliUnitPrice) != entUnitPrice) {
                isPriceChanged = true;
                break;
            }
        }
        return isPriceChanged;
    }

    public static Boolean isNGBSPlanChange(Quote primaryQuote, List<QuoteLineItem> qlis) {
        Boolean result = false;

        try {
            if (primaryQuote == null) {
                AquivaHelper.throwAquivaException('Primary quote not found');
            }

            Boolean isCrossUpgrade = isCrossUpgrade(primaryQuote);
            if (!isCrossUpgrade && (qlis == null || qlis.isEmpty())) {
                AquivaHelper.throwAquivaException('Quote line items not found');
            }

            QuoteLineItem qli = QuoteLineItemHelper.getAnyQuoteLineItemWithEntitlement(qlis);
            if (qli == null && !isCrossUpgrade) {
                AquivaHelper.throwAquivaException('QLI not found');
            }

            Entitlement__c ent = qli != null ? qli.Entitlement__r : null;
            if (ent == null && !isCrossUpgrade) {
                AquivaHelper.throwAquivaException('Entitlement not found');
            }

            BillingWrappers.QuotePackageInfo pInfo = getPackageInfo(primaryQuote);
            if (ent != null && !isCrossUpgrade) {
                if (ent.PackageDuration__c == null) {
                    AquivaHelper.throwAquivaException('Entitlement package duration not found (' + ent.Id + ')');
                }
            }
            if (pInfo == null && !isCrossUpgrade) {
                if (pInfo == null || pInfo.packageInfo == null) {
                    AquivaHelper.throwAquivaException('Quote package info not found');
                }

                if (pInfo.duration == null) {
                    AquivaHelper.throwAquivaException('Quote package info duration not found');
                }
            }
            result = ((ent == null && isCrossUpgrade) ? true : (ent.PackageDuration__c != pInfo.duration));
        } catch (Exception e) {
            AquivaHelper.throwAquivaException('Can not get information for "isNGBSPlanChange" ('+e.getMessage()+')');
        }

        return result;
    }

    public static Boolean isNGBSPackageChange(Quote primaryQuote, List<QuoteLineItem> qlis) {
        Boolean result = false;

        try {
            if (primaryQuote == null) {
                AquivaHelper.throwAquivaException('Primary quote not found');
            }

            if (qlis == null || qlis.isEmpty()) {
                AquivaHelper.throwAquivaException('Quote line items not found');
            }

            Boolean isCrossUpgrade = isCrossUpgrade(primaryQuote);
            if (isCrossUpgrade) {
                return true;
            }

            // For office flow
            // QuoteLineItem qli = QuoteLineItemHelper.findActiveServicePlan(qlis);
            // if (qli == null) {
            //     // For engage flow (possible work for Office also)
            //     qli = QuoteLineItemHelper.getAnyQuoteLineItemWithEntitlement(qlis);
            // }
            QuoteLineItem qli = QuoteLineItemHelper.getAnyQuoteLineItemWithEntitlement(qlis);

            if (qli == null) {
                AquivaHelper.throwAquivaException('QLI not found');
            }

            Entitlement__c ent = qli.Entitlement__r;

            if (ent == null) {
                AquivaHelper.throwAquivaException('Entitlement not found');
            }

            if (ent.PackageCatalogId__c == null || ent.PackageVersion__c == null) {
                AquivaHelper.throwAquivaException('Entitlement package catalog id or version not found');
            }

            BillingWrappers.QuotePackageInfo pInfo = getPackageInfo(primaryQuote);

            if (pInfo == null || pInfo.packageInfo == null) {
                AquivaHelper.throwAquivaException('Quote package info not found');
            }

            if (pInfo.packageInfo.catalogId == null || pInfo.packageInfo.version == null) {
                AquivaHelper.throwAquivaException('Quote package info details not found');
            }

            result = ent.PackageCatalogId__c != pInfo.packageInfo.catalogId
                || ent.PackageVersion__c != pInfo.packageInfo.version;
        } catch (Exception e) {
            AquivaHelper.throwAquivaException('Can not get information for "isNGBSPackageChange" ('+e.getMessage()+')');
        }

        return result;
    }

    public static Boolean isNGBSPartnerPackageChange(Quote primaryQuote, List<QuoteLineItem> qlis) {
        Boolean result = false;

        try {
            if (primaryQuote == null) {
                AquivaHelper.throwAquivaException('Primary quote not found');
            }

            if (qlis == null || qlis.isEmpty()) {
                AquivaHelper.throwAquivaException('Quote line items not found');
            }

            BillingWrappers.QuotePackageInfo pInfo = getPackageInfo(primaryQuote);

            if (pInfo == null || pInfo.packageInfo == null) {
                AquivaHelper.throwAquivaException('Quote package info not found');
            }

            QuoteLineItem qli = QuoteLineItemHelper.getAnyQuoteLineItemWithPartnerEntitlement(qlis);

            if (qli == null) {
                if (pInfo.partnerPackage?.id != null) {
                    // This means we do not have any PartnerConfig__c on the Entitlement so the partner package is changed
                    return true;
                }
                else {
                    // No partner package anywhere - nor on the Entitlement, nor on the Quote. Thus partnerPackage not changed.
                    return false;
                }
            }

            Entitlement__c ent = qli.Entitlement__r;

            if (ent == null) {
                AquivaHelper.throwAquivaException('Entitlement not found');
            }

            BillingWrappers.PartnerPackageConfig partnerConfig;
            if (ent.PartnerConfig__c != null) {
                partnerConfig = (BillingWrappers.PartnerPackageConfig)
                    JSON.deserialize(ent.PartnerConfig__c, BillingWrappers.PartnerPackageConfig.class);
            }

            result = isPartnerOperationsLogExists(primaryQuote)
                || partnerConfig?.ngbsPartnerId != primaryQuote.Account?.Partner_Account__r?.NGBS_Partner_ID__c
                || partnerConfig?.partnerPackageId != pInfo.partnerPackage?.id
                || partnerConfig?.partnerPackageVersion != pInfo.partnerPackage?.version;
        } catch (Exception e) {
            AquivaHelper.throwAquivaException('Can not get information for "isNGBSPartnerPackageChange" ('+e.getMessage()+')');
        }

        return result;
    }


    public static Boolean isDiscountChange(List<QuoteLineItem> qliList) {
        Boolean result = false;

        if(qliList == null || qliList.isEmpty()) {
            return result;
        }

        for(QuoteLineItem qli : qliList) {
            if (Product2Helper.isMobileUser(qli)) {
                continue;
            }

            if(qli.Entitlement__c == null) {
                continue;
            }

            Decimal qliDiscount = qli.Discount_Number__c == null ? 0 : qli.Discount_Number__c;
            qliDiscount = qliDiscount.setScale(2, RoundingMode.HALF_UP);

            Decimal entlDiscount = qli.Entitlement__r.Discount__c == null ? 0 : qli.Entitlement__r.Discount__c;
            entlDiscount = entlDiscount.setScale(2, RoundingMode.HALF_UP);

            String qliDiscountType = qli.Discount_type__c == null ?
                QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY : qli.Discount_type__c;

            String entlDiscountType = qli.Entitlement__r.Discount_Type__c == null ?
                QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY : qli.Entitlement__r.Discount_Type__c;

            Boolean isDiscountChanged = qliDiscount != entlDiscount;
            Boolean isDiscountTypeChanged = qliDiscountType != entlDiscountType;

            if(isDiscountChanged || isDiscountTypeChanged) {
                result = true;
                break;
            }
        }

        return result;
    }

    public static Boolean isEditionChange(List<QuoteLineItem> qliList) {
        Boolean result = false;

        if(qliList == null || qliList.isEmpty()) {
            return result;
        }

        for(QuoteLineItem qli : qliList) {
            if(qli.Entitlement__c == null) {
                continue;
            }

            String qliPackageId = qli.PackageCatalogId__c == null ? '' : qli.PackageCatalogId__c;
            String qliPackageVersion = qli.PackageVersion__c == null ? '' : qli.PackageVersion__c;

            String entlPackageId = qli.Entitlement__r.PackageCatalogId__c == null ? '' : qli.Entitlement__r.PackageCatalogId__c;
            String entlPackageVersion = qli.Entitlement__r.PackageVersion__c == null ? '' : qli.Entitlement__r.PackageVersion__c;

            if((qliPackageId + qliPackageVersion) != (entlPackageId + entlPackageVersion)) {
                result = true;
                break;
            }
        }

        return result;
    }

    /*
    method detect diffrence in UnitPrice/EffectivePrice between service product and related entaitlement
    used in Confirm and close flow for NGBS opportunities
    */
    public static Boolean isSamePrice(Quote primaryQuote) {

        Boolean result = true;

        if(primaryQuote == null) {
            return result;
        }

        QuoteLineItem serviceQli = QuoteLineItemHelper.findActiveServicePlan(primaryQuote.QuoteLineItems);

        if(primaryQuote.CurrentService__c == null && (serviceQli == null || serviceQli.Entitlement__c == null)) {
            return result;
        }

        Entitlement__c serviceEntl;

        if(primaryQuote.CurrentService__c != null) {
            serviceEntl = primaryQuote.CurrentService__r;
        }else if(serviceQli.Entitlement__c != null) {
            serviceEntl = serviceQli.Entitlement__r;
        }

        Decimal qliUnitPrice = NumberHelper.toNumber(serviceQli?.UnitPrice);
        qliUnitPrice = qliUnitPrice.setScale(2, RoundingMode.HALF_UP);

        Decimal entlUnitPrice = NumberHelper.toNumber(serviceEntl?.Price__c);
        entlUnitPrice = entlUnitPrice.setScale(2, RoundingMode.HALF_UP);

        Decimal qliEffectivePrice = NumberHelper.toNumber(serviceQli?.EffectivePriceNew__c);
        qliEffectivePrice = qliEffectivePrice.setScale(2, RoundingMode.HALF_UP);

        Decimal entlEffectivePrice = NumberHelper.toNumber(serviceEntl?.EffectivePrice__c);
        entlEffectivePrice = entlEffectivePrice.setScale(2, RoundingMode.HALF_UP);

        Boolean isSameUnitPrice = qliUnitPrice == entlUnitPrice;
        Boolean isSameEffectivePrice = qliEffectivePrice == entlEffectivePrice;

        result = isSameUnitPrice && isSameEffectivePrice;

        return result;
    }

    public static Boolean setServiceEntitlementOnQuote(Quote qt, Id accountId,  List<Entitlement__c> entitlements) {
        Boolean isNewServiceEntSet = false;
        List<Entitlement__c> relatedEntitlements = EntitlementHelper.getEntitlementsForQuote(entitlements, qt, accountId);
        Entitlement__c serviceEnt = EntitlementHelper.getServiceEntitlement(qt.RecordTypeId, relatedEntitlements);
        if (serviceEnt != null &&
            qt.CurrentService__c != serviceEnt.Id) {
            qt.CurrentService__c = serviceEnt.Id;
            isNewServiceEntSet = true;
        }
        return isNewServiceEntSet;
    }

    public static Boolean isRentalPhonesUpsellInCart(Quote quote) {
        Boolean isRentalPhonesUpsell = false;
        if (quote == null || quote.QuoteLineItems == null || quote.QuoteLineItems.isEmpty()) {
            return isRentalPhonesUpsell;
        }
        for (QuoteLineItem qli : quote.QuoteLineItems) {
            Boolean isUpsell = qli.Entitlement__c == null || qli.NewQuantity__c > qli.Entitlement__r.Quantity__c;
            if (Product2Helper.isRentalPhone(qli) && isUpsell) {
                isRentalPhonesUpsell = true;
                break;
            }
        }
        return isRentalPhonesUpsell;
    }

    public static BillingWrappers.QuotePackageInfo getPackageInfo(Quote quote) {
        BillingWrappers.QuotePackageInfo pInfo;
        if (quote != null && String.isNotBlank(quote.Package_Info__c)) {
            List<BillingWrappers.QuotePackageInfo> pInfoList = (List<BillingWrappers.QuotePackageInfo>) JSON.deserialize(quote.Package_Info__c, List<BillingWrappers.QuotePackageInfo>.class);

            pInfo = !pInfoList.isEmpty() ? pInfoList[0] : null;
        }

        return pInfo;
    }

    public static List<BillingWrappers.QuotePackageInfo> getPackageInfoList(Quote quote) {
        List<BillingWrappers.QuotePackageInfo> pInfoList;
        if (quote != null && String.isNotBlank(quote.Package_Info__c)) {
            pInfoList = (List<BillingWrappers.QuotePackageInfo>) JSON.deserialize(quote.Package_Info__c, List<BillingWrappers.QuotePackageInfo>.class);
        }

        return pInfoList;
    }

    public static BillingWrappers.Contract getNGBSContract(Quote qt) {
        BillingWrappers.Contract result = null;

        try {
            BillingWrappers.QuotePackageInfo pInfo = getPackageInfo(qt);
            result = pInfo.contract;
        } catch (Exception e) {
            AquivaHelper.throwAquivaException('Can\'t get contract for ngbs quote');
        }

        return result;
    }

    public static Boolean isQuotePendingApproval(Quote q) {
        return APPROVAL_STATUSES_PENDING.contains(q.Approved_Status__c);
    }

    public static Boolean isNeedSetQuoteInvalid(Quote q, List<Opportunity> oppsTriggeredInvalidation) {
        List<String> allowedStageNamesList = new List<String>{ OpportunityHelper.STAGE_NAME_DOWNGRADED };
                     allowedStageNamesList.addAll(OpportunityHelper.STAGE_NAMES_CLOSED);
        Set<Id> oppIdsToCheck = new Set<Id>();
        for(Opportunity o : oppsTriggeredInvalidation) {
            oppIdsToCheck.add(o.Id);
        }
        return !OpportunityHelper.checkIsChangeOrderOrMigrationOpty(
                    q.Opportunity.Name,
                    q.Opportunity.Parent_Order__c
                )
                && !allowedStageNamesList.contains(q.Opportunity.StageName)
                && !oppIdsToCheck.contains(q.Opportunity.Id)
                && (new Set<Id>{QuoteHelper.RT_ID_SALES, QuoteHelper.RT_ID_BILLING}).contains(q.RecordTypeId);
    }

    public static void recallQuotesApprovals(List<Quote> quotesToProcess) {
        if(quotesToProcess.isEmpty()) {
            return;
        }

        Set<Id> quotesIds = new Set<Id>();
        for(Quote q : quotesToProcess) {
            quotesIds.add(q.Id);
        }

        List<ProcessInstanceWorkitem> workItemsList = new ProcessInstanceWorkitemSelector()
            .selectProcessInstanceWorkitems(new List<Object>{quotesIds})
            .selectFields(new List<String>{'ProcessInstance.TargetObjectId', 'ProcessInstanceId'})
            .setCondition('ProcessInstance.TargetObjectId IN :bind0')
            .executeQuery();

        Map<Id, List<ProcessInstanceWorkitem>> ProcessInstanceIdToProcessInstanceWorkItemsMap = new Map<Id, List<ProcessInstanceWorkitem>>();

        for (ProcessInstanceWorkitem wi: workItemsList) {
            if (!ProcessInstanceIdToProcessInstanceWorkItemsMap.containsKey(wi.ProcessInstanceId)) {
                ProcessInstanceIdToProcessInstanceWorkItemsMap.put(wi.ProcessInstanceId, new List<ProcessInstanceWorkitem>());
            }
            ProcessInstanceIdToProcessInstanceWorkItemsMap.get(wi.ProcessInstanceId).add(wi);
        }

        for(Id piId : ProcessInstanceIdToProcessInstanceWorkItemsMap.keySet()) {
            Approval.ProcessWorkItemRequest req = new Approval.ProcessWorkItemRequest();
            req.setWorkItemId(ProcessInstanceIdToProcessInstanceWorkItemsMap.get(piId)[0].Id);
            req.setAction('Removed'); // This means to remove/recall Approval Request
            req.setComments('Recall Approval due to quote invalidation.');
            Approval.ProcessResult result = Approval.process(req);
        }
    }

    public static List<Quote> getAllQuotes(BillingWrappers.Params paramsData) {
        String condition = '(OpportunityId = :bind0 OR Opportunity.MasterOpportunity__c = :bind0)';

        return  (List<Quote>) new QuoteSelector()
            .selectQuotesForQuoteService(paramsData.opportunityId,new Set<String>{QuoteHelper.RT_ID_BILLING}, condition)
            .executeQuery();
    }

    public static Boolean isActiveAgreement(Quote primaryQuote) {
        return (
            primaryQuote.Status == QuoteHelper.QUOTE_STATUS_ACTIVE &&
            primaryQuote.QuoteType__c == QuoteHelper.QUOTE_TYPE_AGREEMENT
        );
    }

    public static Boolean isBillingQuoteHasErrors(Quote qt) {
        return qt != null
            && (qt.RecordTypeId == QuoteHelper.RT_ID_BILLING || qt.RecordTypeId == QuoteHelper.RT_ID_POC)
            && qt.IsQuoteHasErrors__c;
    }

    private static Map<Id, List<Area_Code_Line_Item__c>> getAreaCodeLineItemsMap(List<Area_Code_Line_Item__c> areaCodeLineItems) {
        Map<Id, List<Area_Code_Line_Item__c>> qliIdToAcliListMap = new Map<Id, List<Area_Code_Line_Item__c>>();
        if (areaCodeLineItems != null) {
            for (Area_Code_Line_Item__c acli : areaCodeLineItems) {
                if (!qliIdToAcliListMap.containsKey(acli.Quote_Line_Item__c)) {
                    qliIdToAcliListMap.put(acli.Quote_Line_Item__c, new List<Area_Code_Line_Item__c>());
                }
                qliIdToAcliListMap.get(acli.Quote_Line_Item__c).add(acli);
            }
        }
        return qliIdToAcliListMap;
    }

    public static Boolean isAreaCodeLineItemsMissed(List<QuoteLineItem> quoteLineItems, List<Area_Code_Line_Item__c> areaCodeLineItems) {
        Boolean isAreaCodeLineItemsMissed = false;

        Map<Id, List<Area_Code_Line_Item__c>> qliIdToAcliListMap = getAreaCodeLineItemsMap(areaCodeLineItems);

        for (QuoteLineItem qli : quoteLineItems) {
            Boolean isGlobalOfficeLimitedExtensionProduct = (new Set<Decimal>{
                Product2Helper.FEATURE_GLOBAL_OFFICE_LIMITED_EXTENSION,
                Product2Helper.FEATURE_GLOBAL_OFFICE,
                Product2Helper.FEATURE_LIMITED_EXTENSION}).contains(qli.Product2.Feature__c);

            Boolean isAdditionalNumber = Product2Helper.FEATURE_NUMBERS.contains(qli.Product2.Feature__c);
            Boolean isDiscountedPhone = qli.Product2.Family == Product2Helper.FAMILY_DISCOUNTED_PHONES;
            Boolean isRefurbishedPhone = qli.Product2.Family == Product2Helper.FAMILY_REFURBISHED_PHONES;

            if (!isGlobalOfficeLimitedExtensionProduct
                && (isAdditionalNumber || isDiscountedPhone || isRefurbishedPhone)
                && !qli.Zero_Quantity__c
                && qli.Quantity > 0
                && qli.NewQuantity__c != 0
                && qliIdToAcliListMap.get(qli.Id) == null) {

                isAreaCodeLineItemsMissed = true;
                break;
            }
        }
        return isAreaCodeLineItemsMissed;
    }

    public static Boolean isAreaCodeLineItemsMissedBilling(List<QuoteLineItem> quoteLineItems, List<Area_Code_Line_Item__c> areaCodeLineItems) {
        Boolean isAreaCodeLineItemsMissed = false;

        Map<Id, List<Area_Code_Line_Item__c>> qliIdToAcliListMap = getAreaCodeLineItemsMap(areaCodeLineItems);
        Set<String> codes = new Set<String>(Category_Codes__c.getvalues('REQUIRED_AREA_CODES').Codes__c.deleteWhitespace().split(','));

        for (QuoteLineItem qli : quoteLineItems) {
            BillingWrappers.QLIPackageInfo pInfo = new BillingWrappers.QLIPackageInfo(qli.PackageInfo__c);
            if (codes.contains(pInfo.CategoryCode)
                && !qli.Zero_Quantity__c
                && qli.Quantity > 0
                && qli.NewQuantity__c != 0
                && qliIdToAcliListMap.get(qli.Id) == null) {

                isAreaCodeLineItemsMissed = true;
                break;
            }
        }
        return isAreaCodeLineItemsMissed;
    }

    public static Boolean isOfficeService(Quote qt) {
        if (qt == null || String.isBlank(qt.Package_Info__c)) {
            AquivaHelper.throwAquivaException(CAN_NOT_PACKAGE_INFO_ERROR);
        }

        String productName = BillingWrappers.parseQuotePackageInfo(qt.Package_Info__c).productName;

        return Product2Helper.PRODUCT_OFFICE.equalsIgnoreCase(productName);
    }

    public static Boolean isEventsService(Quote qt) {
        if (qt == null || String.isBlank(qt.Package_Info__c)) {
            AquivaHelper.throwAquivaException(CAN_NOT_PACKAGE_INFO_ERROR);
        }

        String productName = BillingWrappers.parseQuotePackageInfo(qt.Package_Info__c).productName;

        return Constants.CONST_RC_EVENT.equalsIgnoreCase(productName);
    }

    public static Boolean isMeetingsService(Quote qt) {
        if (qt == null || String.isBlank(qt.Package_Info__c)) {
            AquivaHelper.throwAquivaException(CAN_NOT_PACKAGE_INFO_ERROR);
        }

        String productName = BillingWrappers.parseQuotePackageInfo(qt.Package_Info__c).productName;

        return Product2Helper.PRODUCT_MEETINGS.equalsIgnoreCase(productName);
    }

    public static Boolean isFaxService(Quote qt) {
        if (String.isBlank(qt?.Package_Info__c)) {
            AquivaHelper.throwAquivaException(CAN_NOT_PACKAGE_INFO_ERROR);
        }

        String productName = new BillingWrappers.QuotePackageInfoWrapper(qt.Package_Info__c).getPackageInfo().productName;

        return Product2Helper.PRODUCT_FAX.equalsIgnoreCase(productName);
    }

    public static Boolean isEngageService(Quote qt) {
        return isEngageService(qt, Product2Helper.PRODUCT_ID_ENGAGE);
    }

    public static Boolean isCCService(Quote qt) {
        if (qt == null || String.isBlank(qt.Package_Info__c)) {
            return false;
        }

        return Product2Helper.PRODUCT_ID_CONTACT_CENTER ==
            BillingWrappers.parseQuotePackageInfo(qt.Package_Info__c).productId;
    }

    public static Boolean isEngageVService(Quote qt) {
        return isEngageService(qt, new Set<String>{
            Product2Helper.PRODUCT_ID_ENGAGE_VOICE_LEGACY,
            Product2Helper.PRODUCT_ID_ENGAGE_VOICE_STANDALONE
        });
    }

    public static Boolean isEngageDService(Quote qt) {
        return isEngageService(qt, new Set<String>{
            Product2Helper.PRODUCT_ID_ENGAGE_DIGITAL_LEGACY,
            Product2Helper.PRODUCT_ID_ENGAGE_DIGITAL_STANDALONE
        });
    }

    public static Boolean isEngageUService(Quote qt) {
        return isEngageService(qt, new Set<String>{
            Product2Helper.PRODUCT_ID_ENGAGE_UNIFIED
        });
    }

    public static Boolean isEngageOmnichannelService(Quote qt) {
        return isEngageService(qt, new Set<String> {
            Product2Helper.PRODUCT_ID_ENGAGE_OMNICHANNEL
        });
    }

    public static Boolean isEngageService(Quote qt, Set<String> ids) {
        if (qt == null || String.isBlank(qt.Package_Info__c)) {
            return false;
        }

        String productId = BillingWrappers.parseQuotePackageInfo(qt.Package_Info__c).productId;

        return ids.contains(productId);
    }

    public static Boolean isEngageLegacyService(Quote qt) {
        return isEngageService(qt, new Set<String>{
            Product2Helper.PRODUCT_ID_ENGAGE_VOICE_LEGACY,
            Product2Helper.PRODUCT_ID_ENGAGE_DIGITAL_LEGACY
        });
    }

    /* Contract availability methods */
    public static Boolean isContractSelected(Quote oldQuote, Quote newQuote) {
        Boolean isContractSelected = false;

        if (
            oldQuote != null &&
            newQuote != null &&
            String.isNotBlank(newQuote.Package_Info__c)
        ) {
            BillingWrappers.QuotePackageInfo newPackage = BillingWrappers.parseQuotePackageInfo(
                newQuote.Package_Info__c
            );
            BillingWrappers.QuotePackageInfo oldPackage =
                String.isNotBlank(oldQuote.Package_Info__c)
                    ? BillingWrappers.parseQuotePackageInfo(oldQuote.Package_Info__c)
                    : null;

            isContractSelected =
                newPackage != null &&
                newPackage.contract != null &&
                (oldPackage == null || oldPackage.contract == null);
        }

        return isContractSelected;
    }

    public static Boolean isContractDeselected(Quote oldQuote, Quote newQuote) {
        Boolean isContractDeselected = false;

        if (
            oldQuote != null &&
            newQuote != null &&
            String.isNotBlank(oldQuote.Package_Info__c)
        ) {
            BillingWrappers.QuotePackageInfo oldPackage = BillingWrappers.parseQuotePackageInfo(
                oldQuote.Package_Info__c
            );
            BillingWrappers.QuotePackageInfo newPackage =
                String.isNotBlank(newQuote.Package_Info__c)
                    ? BillingWrappers.parseQuotePackageInfo(newQuote.Package_Info__c)
                    : null;

            isContractDeselected =
                oldPackage != null &&
                oldPackage.contract != null &&
                (newPackage == null || newPackage.contract == null);
        }

        return isContractDeselected;
    }

    public static Boolean isContractChanged(Quote oldQuote, Quote newQuote) {
        Boolean isContractChanged = false;

        if (
            oldQuote != null &&
            newQuote != null &&
            String.isNotBlank(oldQuote.Package_Info__c) &&
            String.isNotBlank(newQuote.Package_Info__c)
        ) {
            BillingWrappers.QuotePackageInfo oldPackage = BillingWrappers.parseQuotePackageInfo(
                oldQuote.Package_Info__c
            );
            BillingWrappers.QuotePackageInfo newPackage = BillingWrappers.parseQuotePackageInfo(
                newQuote.Package_Info__c
            );

            String oldExtId =
                oldPackage != null && oldPackage.contract != null
                    ? oldPackage.contract.extId
                    : null;
            String newExtId =
                newPackage != null && newPackage.contract != null
                    ? newPackage.contract.extId
                    : null;

            isContractChanged =
                String.isNotBlank(oldExtId) &&
                String.isNotBlank(newExtId) &&
                oldExtId != newExtId;
        }

        return isContractChanged;
    }

    public static Boolean isQuoteHasContract(Quote qt) {
        Boolean isQuoteHasContract = false;

        if (qt != null && String.isNotBlank(qt.Package_Info__c)) {
            BillingWrappers.QuotePackageInfo quotePackage = BillingWrappers.parseQuotePackageInfo(
                qt.Package_Info__c
            );
            isQuoteHasContract = quotePackage != null && quotePackage.contract != null;
        }

        return isQuoteHasContract;
    }

    public static Boolean isDocuSignStatusCompleted(Quote qt) {
        List<dsfs__DocuSign_Status__c> docuSignStatusList =
            new DocuSignStatusSelector().selectDocuSignStatusForSignUp(qt.Id).executeQuery();
        if (docuSignStatusList.isEmpty()) {
            return false;
        }
        if (docuSignStatusList[0].dsfs__Envelope_Status__c == ApprovalHelper.STATUS_COMPLETED) {
            return true;
        }
        return false;
    }

    public static Entitlement__c getOneEntitlementFromQuote(Quote qt) {
        Entitlement__c ent;
        for (QuoteLineItem qli : qt.QuoteLineItems) {
            if (qli.Entitlement__r != null) {
                ent = qli.Entitlement__r;
                break;
            }
        }
        return ent;
    }

    /* ngbs package offer type */
    public static Boolean isOfferTypeFree(String offerType) {
        return String.isNotBlank(offerType) && offerType.equalsIgnoreCase(PACKAGE_OFFER_TYPE_FREE);
    }
    public static Boolean isOfferTypeTrial(String offerType) {
        return String.isNotBlank(offerType) && offerType.equalsIgnoreCase(PACKAGE_OFFER_TYPE_TRIAL);
    }
    public static Boolean isOfferTypePOC(String offerType) {
        return String.isNotBlank(offerType) && offerType.equalsIgnoreCase(PACKAGE_OFFER_TYPE_POC);
    }

    /* free to office */
    public static Boolean isExistingPackageOfferTypeFree(Quote qt) {
        List<BillingWrappers.QuotePackageInfo> pInfos =
            (List<BillingWrappers.QuotePackageInfo>)
                JSON.deserialize(qt.Package_Info__c, List<BillingWrappers.QuotePackageInfo>.class);
        BillingWrappers.QuotePackageInfo pInfo = pInfos[0];
        if (pInfo != null && pInfo.existingPackageInfo != null) {
            return isOfferTypeFree(pInfo.existingPackageInfo.offerType);
        }
        return false;
    }
    /* ent */
    /* free */
    public static Boolean isEntitlementPackageOfferTypeFree(Quote qt) {
        Entitlement__c ent = getOneEntitlementFromQuote(qt);
        return isEntitlementPackageOfferTypeFree(ent);
    }
    public static Boolean isEntitlementPackageOfferTypeFree(Entitlement__c ent) {
        return ent != null && isOfferTypeFree(ent.PackageOfferType__c);
    }
    /* trial */
    public static Boolean isEntitlementPackageOfferTypeTrial(Quote qt) {
        Entitlement__c ent = getOneEntitlementFromQuote(qt);
        return isEntitlementPackageOfferTypeTrial(ent);
    }
    public static Boolean isEntitlementPackageOfferTypeTrial(Entitlement__c ent) {
        return ent != null && isOfferTypeTrial(ent.PackageOfferType__c);
    }
    /* poc */
    public static Boolean isEntitlementPackageOfferTypePOC(Quote qt) {
        Entitlement__c ent = getOneEntitlementFromQuote(qt);
        return isEntitlementPackageOfferTypePOC(ent);
    }
    public static Boolean isEntitlementPackageOfferTypePOC(Entitlement__c ent) {
        return ent != null &&  isOfferTypePOC(ent.PackageOfferType__c);
    }

    public static Boolean isCrossUpgrade(Quote qt) {
        if (qt != null && qt.Package_Info__c != null) {
            List<BillingWrappers.QuotePackageInfo> pInfos =
                (List<BillingWrappers.QuotePackageInfo>)
                    JSON.deserialize(qt.Package_Info__c, List<BillingWrappers.QuotePackageInfo>.class);
            BillingWrappers.QuotePackageInfo pInfo = pInfos[0];
            if (pInfo != null
                && pInfo.productName != null
                && pInfo.packageInfo != null
                && pInfo.existingPackageInfo != null
                && pInfo.existingPackageInfo.productName != null
                && pInfo.productName != pInfo.existingPackageInfo.productName) {
                return true;
            }
        }
        return false;
    }

    // Country from approved business identity (approvedBi) on Package_Info__c
    public static String getApprovedBICountryFromQuote(Quote q) {
        String res = '';

        if (String.isBlank(q.Package_Info__c)) {
            return res;
        }

        List<BillingWrappers.QuotePackageInfo> pInfo = (List<BillingWrappers.QuotePackageInfo>) JSON.deserialize(
            q.Package_Info__c,
            List<BillingWrappers.QuotePackageInfo>.class
        );

        try {
            res = pInfo[0].packageBusinessIdentities.approvedBi.address.country;
        } catch(Exception e) {
            System.debug('NO APPROVED BI COUNTRY ON PACKAGE INFO');
        }

        return res;
    }

    // Business Identity Id from approved business identity (approvedBi) on Package_Info__c
    public static String getApprovedBiIdFromQuote(Quote q) {
        String biId;

        if (String.isNotBlank(q?.Package_Info__c)) {
            BillingWrappers.QuotePackageInfo pInfo = new BillingWrappers.QuotePackageInfoWrapper(q.Package_Info__c).getPackageInfo();
            biId = pInfo?.packageBusinessIdentities?.approvedBi?.id;
        }
        return String.isNotBlank(biId) ? biId : '';
    }

    public static String getOldPackageNameFromQuote(Quote q) {
        String res = '';

        if (String.isBlank(q.Package_Info__c)) {
            return res;
        }

        List<BillingWrappers.QuotePackageInfo> pInfo = (List<BillingWrappers.QuotePackageInfo>) JSON.deserialize(
            q.Package_Info__c,
            List<BillingWrappers.QuotePackageInfo>.class
        );

        try {
            res = pInfo[0].packageInfo.oldPackageName;
        } catch(Exception e) {
            System.debug('NO PACKAGE INFO');
        }

        return res;
    }

    public static String getPackageIdFromQuote(Quote q) {
        String res = '';

        if (String.isBlank(q.Package_Info__c)) {
            return res;
        }

        List<BillingWrappers.QuotePackageInfo> pInfo = (List<BillingWrappers.QuotePackageInfo>) JSON.deserialize(
            q.Package_Info__c,
            List<BillingWrappers.QuotePackageInfo>.class
        );

        try {
            res = pInfo[0].packageInfo.catalogId;
        } catch(Exception e) {
            System.debug('NO PACKAGE INFO');
        }

        return res;
    }

    public static String getNewPackageNameFromQuote(Quote q) {
        String res = '';

        if (String.isBlank(q.Package_Info__c)) {
            return res;
        }

        List<BillingWrappers.QuotePackageInfo> pInfo = (List<BillingWrappers.QuotePackageInfo>) JSON.deserialize(
            q.Package_Info__c,
            List<BillingWrappers.QuotePackageInfo>.class
        );

        try {
            res = pInfo[0].packageInfo.displayName;
        } catch(Exception e) {
            System.debug('NO PACKAGE INFO');
        }

        return res;
    }

    public static Boolean isMigrationFlow(Quote qt, Id userId) {
        CustomPermissionHelper customhelper = new CustomPermissionHelper();
        return isEngageLegacyService(qt) &&
            UserHelper.MIGRATION_AGENT.equalsIgnoreCase(ApprovalTriggerHandler.getUserHierarchyRole(userId)) &&
            customhelper.hasPermission(CustomPermissionHelper.PERMISSION_PROCESS_ENGAGE_LEGACY);
    }

    public static Boolean isTermsLessYear(Quote qt) {

        Boolean result = false;

        if (qt == null) {
            return result;
        }

        Integer renewalTerm = 0;
        Integer initialTerm = 0;

        if (qt.Term_months__c != null) {
            renewalTerm = QuoteHelper.getNumberFromString(qt.Term_months__c);
        }

        if (qt.Initial_Term_months__c != null) {
            initialTerm = QuoteHelper.getNumberFromString(qt.Initial_Term_months__c);
        }

        result = (renewalTerm > 0 && renewalTerm < 12) || (initialTerm > 0 && initialTerm < 12);

        return result;
    }

    public static Boolean isQuoteOutOfContract(Quote q) {
        Boolean isOutOfContract = false;
        BillingWrappers.QuotePackageInfo pInfo = getPackageInfo(q);

        if (q?.Opportunity.Type == OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS
                && q?.Opportunity.Account.Active_Sales_Agreement__c != null
                && q?.Opportunity.Account.Active_Sales_Agreement__r?.Status != QUOTE_STATUS_TERMINATED
                && pInfo != null
                && pInfo?.contract?.id == null
                ) {
            isOutOfContract = true;
        }

        return isOutOfContract;
    }

    public static Boolean isPhoenix (Quote qt) {

        NGBS_Phoenix_Settings__c phoenixSettings = NGBS_Phoenix_Settings__c.getInstance();
        if (qt != null && qt.Id != null) {
            List<QuoteHelper.PackageInfo> pInfoList = QuoteHelper.getPackageInfo(qt.Package_Info__c);
            QuoteHelper.PackageInfo pInfo = (pInfoList.size() != 0) ? pInfoList[0] : null;
            Map<String,String> availablePackagesMap = new Map<String, String>();
            if (phoenixSettings.NGBSPhoenixAvailablePackageIDs__c != null) {
                for (String availablePackage : phoenixSettings.NGBSPhoenixAvailablePackageIDs__c.split(';')) {
                    availablePackagesMap.put(availablePackage, availablePackage);
                }
            }
            if (pInfo != null && availablePackagesMap.containsKey(pInfo.Id)) {
                return availablePackagesMap.get(pInfo.Id) != null;
            }
        }

        return false;
    }

    public static Boolean isPhoneLeasingEnabled(Boolean isPhoenixQuote, Boolean isIndiaOpp, List<QuoteLineItem> qliList) {
        Boolean result = false;

        if (isPhoenixQuote == null) {
            isPhoenixQuote = false;
        }
        if (isIndiaOpp == null) {
            isIndiaOpp = false;
        }

        if (isPhoenixQuote || isIndiaOpp) {
            result = false;
        } else {
            result = true;
        }

        if (qliList == null || qliList.isEmpty()) {
            return result;
        }

        QuoteLineItem subscription = getSubscription(qliList);
        if (subscription == null || String.isBlank(subscription.PackageInfo__c)) {
            return result;
        }

        BillingWrappers.QLIPackageInfo pInfo = BillingWrappers.parseQLIPackageInfo(subscription.PackageInfo__c);
        if (pInfo.isPhoneLeasingEnabled == null) {
            return result;
        } else if (pInfo.isPhoneLeasingEnabled == 1) {
            result = true;
        }
        return result;
    }

    @TestVisible
    private static QuoteLineItem getSubscription(List<QuoteLineItem> qliList) {
        QuoteLineItem subscriptionLicense;
        if (qliList == null || qliList.isEmpty()) {
            return subscriptionLicense;
        }
        for (QuoteLineItem qli : qliList) {
            if (qli.Product_Lic_Id__c == Product2Helper.SUBSCRIPTION_LICENSE) {
                subscriptionLicense = qli;
                break;
            }
        }
        return subscriptionLicense;
    }

    public static void pullApproversFromMainQuote(List<Quote> quotes) {
        Quote mainQuote;
        for (Quote quote : quotes) {
            if (quote.IsPrimary__c == true) {
                mainQuote = quote;
            }
        }
        if (mainQuote != null && quotes.size() > 1) {
            for (Quote quote : quotes) {
                if (quote.Id == mainQuote.Id || !isCCQuote(quote)) {
                    continue;
                }
                quote.Approved_Status__c = mainQuote.Approved_Status__c;
                quote.Level_1_Approver__r = mainQuote.Level_1_Approver__r;
                quote.Level_2_Approver__r = mainQuote.Level_2_Approver__r;
                quote.Level_3_Approver__r = mainQuote.Level_3_Approver__r;
                quote.Level_4_Approver__r = mainQuote.Level_4_Approver__r;
                quote.Level_5_Approver__r = mainQuote.Level_5_Approver__r;
                quote.Level_6_Approver__r = mainQuote.Level_6_Approver__r;
                quote.Level_7_Approver__r = mainQuote.Level_7_Approver__r;
            }
        }
    }

    public static Boolean isSingapore(Quote qt) {
        Boolean result = false;
        if (qt != null && String.isNotBlank(qt.BusinessIdentity__c)) {
            BillingWrappers.QuoteBusinessIdentity bi = (BillingWrappers.QuoteBusinessIdentity)
                JSON.deserialize(
                    qt.BusinessIdentity__c.replace('currency', 'biCurrency'),
                    BillingWrappers.QuoteBusinessIdentity.class
                );
            result = bi.biId == RingCentralHelper.BUSINESS_IDENTITY_SINGAPORE && bi.biCurrency == RingCentralHelper.SGD;
        }
        return result;
    }

    public static BillingWrappers.QuoteBusinessIdentity getBusinessIdentity(String businessIdentity) {
        if (String.isBlank(businessIdentity)) {
            return null;
        }
        return (BillingWrappers.QuoteBusinessIdentity)
            JSON.deserialize(
                businessIdentity.replace('currency', 'biCurrency'),
                BillingWrappers.QuoteBusinessIdentity.class
            );
    }

    public static Boolean isInvoice(String paymentMethod) {
        return paymentMethod == PAYMENT_METHOD_INVOICE;
    }

    public static Boolean isInvoiceOnBehalf(String paymentMethod) {
        return paymentMethod == PAYMENT_METHOD_INVOICE_ON_BEHALF;
    }

    public static Boolean isDirectDebit(Quote qt) {
        return qt != null && isDirectDebit(qt.PaymentMethod__c);
    }

    public static Boolean isDirectDebit(String paymentMethod) {
        return paymentMethod == QuoteHelper.PAYMENT_METHOD_DIRECT_DEBIT;
    }

    public static Boolean isCreditCard(String paymentMethod) {
        return paymentMethod == QuoteHelper.PAYMENT_METHOD_CREDIT_CARD;
    }

    public static String getPaymentMethod(Quote qt, BillingWrappers.NGBSAccount accountInfo, Boolean isPOC) {
        String result = qt?.PaymentMethod__c;
        if (accountInfo != null && !isPOC) {
            result = NGBSAPI.getBillingAccountPaymentMethod(accountInfo.id);
        }
        return result;
    }

    public static Boolean hasBillOnBehalfAccount(Quote qt) {
        return (String.isNotBlank(qt.Account.Partner_ID__c) &&
        AccountHelper.ACCOUNT_BILL_ON_BEHALF_PARTNERS.contains(qt.Account.Partner_Type__c));
    }

    public static String getPaymentMethod(Account acc, Opportunity opp, Quote qt, BillingWrappers.NGBSAccount accountInfo, Boolean isClosed) {
        if (OpportunityHelper.isSearchPackagesEnabledWithValidOppBI(opp)) {
            Boolean isPOC = BooleanHelper.toBoolean(accountInfo?.getPackage()?.isPOC());
            return getPaymentMethod(qt, accountInfo, isPOC);
        }

        // old logic from AccountValidator
        String result = acc?.Payment_Method__c;
        Boolean paymentMethodFromAccount = acc.Billing_ID__c != null && acc.Account_Payment_Method__c != null;
        if (isClosed && paymentMethodFromAccount) {
            result = acc.Account_Payment_Method__c;
        }

        return result;
    }

    public static String getPaymentMethod(Account acc, Opportunity opp, Quote qt, BillingWrappers.NGBSAccount accountInfo) {
        if (OpportunityHelper.isSearchPackagesEnabledWithValidOppBI(opp)) {
            BillingWrappers.NGBSAccountPackage ngbsPackage = accountInfo?.getPackageById(getPackageId(qt.Package_Info__c));
            Boolean isPOC = BooleanHelper.toBoolean(ngbsPackage?.isPOC());
            return getPaymentMethod(qt, accountInfo, isPOC);
        }
        return acc?.Payment_Method__c;
    }

    public static BillingWrappers.QuotePackageInfo getQuotePackage(Quote qt) {
        BillingWrappers.QuotePackageInfo quotePackage;
        if (qt.Package_Info__c == null) {
            return null;
        }

        List<BillingWrappers.QuotePackageInfo> pInfos =
            (List<BillingWrappers.QuotePackageInfo>)
                JSON.deserialize(qt.Package_Info__c,
                    List<BillingWrappers.QuotePackageInfo>.class
                );

        if (pInfos.size() > 0) {
            for (BillingWrappers.QuotePackageInfo pInfo : pInfos) {
                quotePackage = pInfo;
            }
        }
        return quotePackage;
    }

    public static String getPartnerCatalogId(BillingWrappers.QuotePackageInfo quotePackage) {
        if (quotePackage?.partnerPackage == null) {
            return '';
        }
        return String.valueOf(quotePackage?.partnerPackage?.id) + '.' + String.valueOf(quotePackage?.partnerPackage?.version);
    }

    public static String getCatalogId(BillingWrappers.QuotePackageInfo quotePackage) {
        return quotePackage == null ? '' : String.valueOf(quotePackage?.id) + '.' + String.valueOf(quotePackage?.version);
    }

    // If there is no config for the brand – the quoting is enabled for it by default
    public static Boolean isQuotingAvailableForBrand (String brand, Boolean isNewBusiness) {
        LeadConversionConfiguration__c config = LeadConversionConfiguration__c.getAll().get(brand);
        if (config != null) {
            return isNewBusiness
                    ? config.IsQuotingAvailableNewBusiness__c
                    : config.IsQuotingAvailableExistingBusiness__c;
        } else {
            return true;
        }
    }

    public static Boolean isBillingCountryMatchBI(Quote qt) {
        Boolean result = true;
        String chBillingCountry = 'Switzerland';
        List<String> deRcEuBillingCountries = new List<String>{
                'Germany', 'Austria'
        };
        String biId = getApprovedBiIdFromQuote(qt);

        if (String.isNotBlank(biId)) {

            if (biId == RingCentralHelper.BUSINESS_IDENTITY_RC_EU_DE) {
                result = deRcEuBillingCountries.contains(qt.Account?.BillingCountry);

            } else if (biId == RingCentralHelper.BUSINESS_IDENTITY_RC_EU_FR) {
                result = !deRcEuBillingCountries.contains(qt.Account?.BillingCountry)
                        && String.isNotBlank(qt.Account?.BillingCountry);

            } else if (biId == RingCentralHelper.BUSINESS_IDENTITY_RC_EU_CH
                        || biId == RingCentralHelper.BUSINESS_IDENTITY_UO_CH
                        || biId == RingCentralHelper.BUSINESS_IDENTITY_ACO_CH
            ) {
                result = String.isNotBlank(qt.Account?.BillingCountry) && chBillingCountry == (qt.Account?.BillingCountry);
            }
        }

        return result;
    }

    public static Boolean isPartnerOperationsLogExists(Quote primaryQuote) {
        return !getPartnerOperationLog(primaryQuote?.OpportunityId).isEmpty();
    }

    public static List<PartnerOperationsLog__c> getPartnerOperationLog(Id oppId) {
        return (List<PartnerOperationsLog__c>) new QueryFactory(PartnerOperationsLog__c.SObjectType)
            .selectFields(new List<String> { 'Id', 'PartnerInfo__c' })
            .setCondition('Opportunity__c =:bind0 AND isRejected__c=false AND isCompleted__c=false')
            .setQueryBindings(new List<Object>{ new Set<Id>{ oppId } })
            .executeQuery();
    }

    public static Boolean hasProfessionalServicesInPackageInfo(Quote primaryQuote) {
        if (primaryQuote == null) {
            return false;
        }
        
        List<BillingWrappers.QuotePackageInfo> primaryQuotePackageInfoList = QuoteHelper.getPackageInfoList(primaryQuote.MasterQuote__r);
        
        if (primaryQuotePackageInfoList == null) {
            return false;
        }
        
        for (BillingWrappers.QuotePackageInfo pkgInfo : primaryQuotePackageInfoList) {
            if (pkgInfo != null && pkgInfo.productName == QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT) {
                return true;
            }
        }
        
        return false;
    }

    public static Boolean isVerizon(Quote q) {
        return q?.Brand__c == RingCentralHelper.BRAND_VERIZON;
    }

    public static Boolean isQuoteTermsChanged(Quote primaryQuote, Opportunity oppty) {
        Quote activeAgreement = oppty.Account.Active_Sales_Agreement__r;
            return primaryQuote != null && activeAgreement != null
                    && !isActiveAgreement(primaryQuote)
                    && (isOfficeService(primaryQuote) || isPhoenix(primaryQuote))
                    && !isPOCQuote(primaryQuote)
                    && isQuoteHasContract(primaryQuote)
                    && OpportunityHelper.isExistingBusinessBilling(primaryQuote)
                    && oppty.Account.Master_Account__c == null
                    && (activeAgreement.Initial_Term_months__c != primaryQuote.Initial_Term_months__c
                        || activeAgreement.Auto_Renewal__c != primaryQuote.Auto_Renewal__c
                        || activeAgreement.Term_months__c != primaryQuote.Term_months__c);
    }

    public static Boolean isDQGoaEnabled(Quote qt) {
        return !qt.IsPRMQuote__c && isDQGoaEnabledForAllAccountTypes(qt) && (isNewBusiness(qt) || AccountHelper.isPOCtoPaid(qt.Account));
    }

    public static Boolean isDQGoaEnabledForAllAccountTypes(Quote qt) {
        return isDQAndTPAvailable() && (isCCQuote(qt) || isNewBillingQuote(qt));
    }

    public static Boolean isDQAndTPAvailable() {
        Boolean hasPermission = FeatureManagement.checkPermission(CustomPermissionHelper.PERMISSION_TARGET_PRICE_AND_DQ_GOA);
        return (Feature_Toggle__c.getInstance().EnableTPAndDQBasedGOAInQT__c || hasPermission);
    }

    public static Boolean isServiceTerminated(Id masterQtId, String serviceName) {
        List<Quote> techQuotes = (List<Quote>) new QuoteSelector()
            .selectMultiProductTechnicalQuoteByServiceName(masterQtId, serviceName)
            .executeQuery();

        if (!techQuotes.isEmpty()) {
            if (techQuotes.get(0).IsTermination__c) {
                return true;
            }
            List<ServiceInfo__c> serviceInfos = (List<ServiceInfo__c>) new ServiceInfoSelector()
                .selectServiceInfoForClear(new List<Object>{ techQuotes.get(0).Id })
                .executeQuery();

            return !serviceInfos.isEmpty() && serviceInfos.get(0).IsTermination__c;
        }
        return false;
    }

    public static Map<String, Quote> getTechnicalQuotesByMasterId(
        Id masterQuoteId,
        String[] serviceName
    ) {
        Quote masterQuote = (Quote) new QuoteSelector()
            .selectQuoteForCloning(new List<Object> { masterQuoteId })
            .executeQuery()
            .get(0);
        Map<String, Opportunity> technicalOpportunities = OpportunityHelper.getTechnicalOpportunitiesByMasterId(masterQuote.OpportunityId);

        return getTechnicalQuotesByMasterId(masterQuote, serviceName, technicalOpportunities);
    }

    public static Map<String, Quote> getTechnicalQuotesByMasterId(
        Id masterQuoteId,
        String[] serviceName,
        Map<String, Opportunity> technicalOpportunities
    ) {
        Quote masterQuote = (Quote) new QuoteSelector()
            .selectQuoteForCloning(new List<Object> { masterQuoteId })
            .executeQuery()
            .get(0);

        return getTechnicalQuotesByMasterId(masterQuote, serviceName, technicalOpportunities);
    }

    public static Map<String, Quote> getTechnicalQuotesByMasterId(
        Quote masterQuote,
        String[] serviceNames,
        Map<String, Opportunity> serviceOpportunities
    ) {
        List<Quote> technicalQuotes = new QuoteSelector()
            .selectServiceQuotesForMasterQuote(masterQuote.Id)
            .executeQuery();
        Map<String, Quote> quotesByServiceMap = new Map<String, Quote>();

        for (String s: serviceNames) {
            if (CREATE_TECHNICAL_ACCOUNT_FOR_SERVICES.contains(s)) {
                Opportunity o = serviceOpportunities.get(s);
                for (Quote q: technicalQuotes) {
                    if (q.OpportunityId == o.Id) {
                        quotesByServiceMap.put(s, q);
                    }
                }
            } else {
                for (Quote q: technicalQuotes) {
                    if (q.OpportunityId == masterQuote.OpportunityId) {
                        quotesByServiceMap.put(s, q);
                    }
                }
            }
        }

        return quotesByServiceMap;
    }

    public static Map<String, Quote> getTechnicalQuotesByMasterIdUB(
        Id masterQuoteId,
        String[] serviceNames
    ) {
        Quote masterQuote = (Quote) new QuoteSelector()
            .selectQuoteForCloningUB(new List<Object> { masterQuoteId })
            .executeQuery()
            .get(0);

        return getTechnicalQuotesByMasterIdUB(masterQuote, serviceNames);
    }


    public static Map<String, Quote> getTechnicalQuotesByMasterIdUB(
        Quote masterQuote,
        String[] serviceNames
    ) {
        List<Quote> technicalQuotes = new QuoteSelector()
            .selectServiceQuotesForMasterQuoteUB(masterQuote.Id, serviceNames)
            .executeQuery();
        Map<String, Quote> quotesByServiceMap = new Map<String, Quote>();

        for (String s: serviceNames) {
            for (Quote q: technicalQuotes) {
                if (q.ServiceName__c == s) {
                    quotesByServiceMap.put(s, q);
                }
            }
        }

        return quotesByServiceMap;
    }

    public static Map<String, Quote> upsertTechnicalQuotes(
        Id masterQuoteId,
        Map<String, BillingWrappers.QuoteWrapper> quotesByServiceMap
    ) {
        Quote masterQuote = (Quote) new QuoteSelector()
            .selectQuoteForCloning(new List<Object> { masterQuoteId })
            .executeQuery()
            .get(0);
        Map<String, Account> technicalAccounts = AccountHelper.getTechnicalAccountsByMasterId(masterQuote.AccountId);
        Map<String, Opportunity> technicalOpportunities = OpportunityHelper.getTechnicalOpportunitiesByMasterId(masterQuote.OpportunityId, technicalAccounts);

        return upsertTechnicalQuotes(masterQuote, quotesByServiceMap, technicalOpportunities);
    }

    public static Map<String, Quote> upsertTechnicalQuotes(
        Quote masterQuote,
        Map<String, BillingWrappers.QuoteWrapper> quotesByServiceMap,
        Map<String, Opportunity> technicalOpportunities
    ) {
        List<String> servicesList = new List<String>(quotesByServiceMap.keySet());
        Map<String, Quote> technicalQuotes = getTechnicalQuotesByMasterId(
            masterQuote,
            servicesList,
            technicalOpportunities
        );

        List<Package__c> accountPackages = (List<Package__c>) new PackageSelector()
            .selectPackagesByAccountId(masterQuote.Account__c)
            .executeQuery();

        User technicalUser = UserHelper.getMultiproductTechnicalUser();
        List<Quote> quotesToUpsert = new List<Quote>();

        for (String service: quotesByServiceMap.keySet()) {
            BillingWrappers.QuoteWrapper qw = quotesByServiceMap.get(service);

            Opportunity opp = technicalOpportunities.get(service);

            Id oppId = CREATE_TECHNICAL_ACCOUNT_FOR_SERVICES.contains(service)
                ? opp.Id
                : masterQuote.OpportunityId;

            Quote initialTechQuote = technicalQuotes.containsKey(service)
                ? new Quote(Id = technicalQuotes.get(service).Id)
                : masterQuote.clone(false, true, false, false);

            Quote q = buildTechnicalQuote(qw, oppId, service, masterQuote, initialTechQuote, accountPackages, technicalUser, false);

            quotesToUpsert.add(q);
        }

        if (!quotesToUpsert.isEmpty()) {
            TriggerHandler.BY_PASS_QUOTE_ON_INSERT = true;
            upsert quotesToUpsert;
            TriggerHandler.BY_PASS_QUOTE_ON_INSERT = false;
        }

        return getTechnicalQuotesByMasterId(masterQuote.Id, servicesList, technicalOpportunities);
    }

    public static Map<String, Quote> upsertTechnicalQuotesUB(
        Id masterQuoteId,
        Map<String, BillingWrappers.QuoteWrapper> quotesByServiceMap
    ) {
        Quote masterQuote = (Quote) new QuoteSelector()
            .selectQuoteForCloningUB(new List<Object> { masterQuoteId })
            .executeQuery()
            .get(0);
        return upsertTechnicalQuotesUB(masterQuote, quotesByServiceMap);
    }

    public static Map<String, Quote> upsertTechnicalQuotesUB(
        Quote masterQuote,
        Map<String, BillingWrappers.QuoteWrapper> quotesByServiceMap
    ) {
        List<String> servicesList = new List<String>(quotesByServiceMap.keySet());
        Map<String, Quote> technicalQuotes = getTechnicalQuotesByMasterIdUB(
            masterQuote,
            servicesList
        );

        List<Package__c> accountPackages = (List<Package__c>) new PackageSelector()
            .selectPackagesByAccountId(masterQuote.Account__c)
            .executeQuery();

        User technicalUser = UserHelper.getMultiproductTechnicalUser();
        List<Quote> quotesToUpsert = new List<Quote>();

        for (String service: quotesByServiceMap.keySet()) {
            BillingWrappers.QuoteWrapper qw = quotesByServiceMap.get(service);

            Quote initialTechQuote = masterQuote.clone(false, true, false, false);
            initialTechQuote.Id = technicalQuotes.containsKey(service)
                ? technicalQuotes.get(service).Id
                : null;

            Quote q = buildTechnicalQuote(qw, masterQuote.OpportunityId, service, masterQuote, initialTechQuote, accountPackages, technicalUser, true);

            quotesToUpsert.add(q);
        }

        if (!quotesToUpsert.isEmpty()) {
            TriggerHandler.BY_PASS_QUOTE_ON_INSERT = true;
            upsert quotesToUpsert;
            TriggerHandler.BY_PASS_QUOTE_ON_INSERT = false;
        }

        return getTechnicalQuotesByMasterIdUB(masterQuote, servicesList);
    }

    @TestVisible
    private static Quote buildTechnicalQuote(
        BillingWrappers.QuoteWrapper qw,
        Id oppId,
        String service,
        Quote masterQuote,
        Quote q,
        List<Package__c> accountPackages,
        User technicalUser,
        Boolean isMPUB
    ) {
        for (String field: QUOTE_UNIQUE_FIELDS) {
            q.put(field, null);
        }
        q.ServiceName__c = service;
        q.Name = String.format('{0} [system: {1}]', new List<Object> { masterQuote.Name, service });
        q.isPrimary__c = service == QuoteHelper.NGBS_OFFICE_PRODUCT || isMPUB ? false : masterQuote.isPrimary__c;
        q.IsShowSmokeModifiedMessage__c = false;
        q.IsMultiProductTechnicalQuote__c = true;
        q.MasterQuote__c = masterQuote.Id;
        q.OpportunityId = oppId;
        q.Enabled_LBO__c = service == QuoteHelper.NGBS_OFFICE_PRODUCT ? masterQuote.Enabled_LBO__c : false;
        q.Approved_Status__c = APPROVAL_STATUS_NOT_REQUIRED;

        if (technicalUser != null) {
            q.OwnerId = technicalUser.Id;
        }

        BillingWrappers.QuotePackageInfo technicalQuotePackageInfo = getTechnicalQuotePackageInfo(masterQuote, service);

        q.PackageNameNew__c = technicalQuotePackageInfo.packageInfo.displayName;
        q.PackageNameOld__c = technicalQuotePackageInfo.packageInfo.oldPackageName;
        q.Package_Info__c = JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{technicalQuotePackageInfo});

        if (String.isNotBlank(technicalQuotePackageInfo?.packageInfo?.id)) {
            for (Package__c accountPackage : accountPackages) {
                if (accountPackage.Account_Package_Id__c == technicalQuotePackageInfo.packageInfo.id) {
                    q.BillingPackage__c = accountPackage.Id;
                }
            }
        }

        if (String.isNotBlank(qw.name)) {
            q.Name = qw.name;
        }

        if (qw.autoRenewal != null) {
            q.Auto_Renewal__c = BooleanHelper.toBoolean(qw.autoRenewal);
        }

        if (String.isNotBlank(qw.initialTerm)) {
            q.Initial_Term_months__c = qw.initialTerm;
        }

        if (String.isNotBlank(qw.initialTermPOC)) {
            q.Initial_Term_POC__c = qw.initialTermPOC;
        }

        if (String.isNotBlank(qw.renewalTerm)) {
            q.Term_months__c = qw.renewalTerm;
        }

        q.Special_Terms__c = qw.specialTerms;

        if (String.isNotBlank(qw.status)) {
            q.Status = qw.status;
        }

        if (String.isNotBlank(qw.quoteType)) {
            q.QuoteType__c = qw.quoteType;
        }

        if (String.isNotBlank(qw.expirationDate)) {
            q.ExpirationDate = Date.valueOf(qw.expirationDate);
        }

        if (String.isNotBlank(qw.paymentMethod)) {
            q.PaymentMethod__c = qw.paymentMethod;
        }

        q.DataRetentionDuration__c = qw.dataRetentionDuration;

        q.FreeShippingTerms__c = qw.freeShippingTerms;

        if (Feature_Toggle__c.getInstance().CalculateFSCInQW__c) {
            q.Credit_Amount__c = qw.creditAmount;
            q.Free_Service_Taxes__c = qw.freeServiceTaxes;
        }

        if (qw.isWizardHasErrors != null) {
            q.IsQuoteHasErrors__c = BooleanHelper.toBoolean(qw.isWizardHasErrors);
        }

        if (String.isNotBlank(qw.justification)) {
            q.JustificationandDescription__c = qw.justification;
        }

        if (String.isNotBlank(qw.startDate)) {
            q.Start_Date__c = Date.valueOf(qw.startDate);
        }

        if (String.isNotBlank(qw.endDate)) {
            q.End_Date__c = Date.valueOf(qw.endDate);
        }

        if (qw.updateContractTerms != null) {
            q.UpdateContractTerms__c = BooleanHelper.toBoolean(qw.updateContractTerms);
        }

        if (String.isNotBlank(qw.upsellStatus)) {
            q.Upsell_Status__c = qw.upsellStatus;
        }

        if (String.isNotBlank(qw.shippingShipAttentionTo)) {
            q.Ship_Attention_To__c = qw.shippingShipAttentionTo;
        }

        if (String.isNotBlank(qw.shippingCountry)) {
            q.Shipping_Country__c = qw.shippingCountry;
        }

        if (String.isNotBlank(qw.shippingCity)) {
            q.Shipping_City__c = qw.shippingCity;
        }

        if (String.isNotBlank(qw.shippingState)) {
            q.Shipping_State__c = qw.shippingState;
        }

        if (String.isNotBlank(qw.shippingAddressLine)) {
            q.Shipping_Address_Line__c = qw.shippingAddressLine;
        }

        if (String.isNotBlank(qw.shippingPostalCode)) {
            q.Shipping_Postal_Code__c = qw.shippingPostalCode;
        }

        if (String.isNotBlank(qw.shippingAdditionalAddressLine)) {
            q.Shipping_Additional_Address_Line__c = qw.shippingAdditionalAddressLine;
        }

        if (String.isNotBlank(qw.shippingCustomerName)) {
            q.Shipping_Customer_Name__c = qw.shippingCustomerName;
        }

        if (String.isNotBlank(qw.shippingShippingOption)) {
            q.Shipping_Option__c = qw.shippingShippingOption;
        }

        if (qw.shippingMultipleLocations != null) {
            q.MultipleShippingLocations__c = BooleanHelper.toBoolean(qw.shippingMultipleLocations);
        }

        if (qw.isTaxesAdded != null) {
            q.NGBSTaxesAdded__c = BooleanHelper.toBoolean(qw.isTaxesAdded);
        }

        if (qw.enabledLBO != null) {
            q.Enabled_LBO__c = QuoteHelper.NGBS_OFFICE_PRODUCT == service ? BooleanHelper.toBoolean(qw.enabledLBO) : false;

            if (qw.enabledLBO == true) {
                q.InvalidDiscountedPhonesQuantity__c = false;
            }
        }

        if (qw.isLBODealDeskProvision != null) {
            q.LBODealDeskProvision__c = BooleanHelper.toBoolean(qw.isLBODealDeskProvision);
        }

        if (qw.doNotSendOrderToNGBS != null) {
            q.IsSendOrderToNGBS__c = !BooleanHelper.toBoolean(qw.doNotSendOrderToNGBS);
        }

        if (qw.isFullCalculationFSC != null) {
            q.FSC_Full_MRS_Calculation__c = BooleanHelper.toBoolean(qw.isFullCalculationFSC);
        }

        if (String.isNotBlank(qw.noteToCustomer)) {
            q.Note_To_Customer__c = qw.noteToCustomer;
        }

        if (qw.overallDiscretion != null) {
            q.OverallDiscretion__c = qw.overallDiscretion;
        }

        if (qw.averageDiscount != null) {
            q.AverageDiscount__c = qw.averageDiscount;
        }

        if (qw.mainAreaCodeId != null) {
            q.AreaCode__c = qw.mainAreaCodeId;
        }

        if (qw.totalQuoteSummary != null) {
            q.TotalQuoteSummary__c = qw.totalQuoteSummary;
        }

        if (qw.deltaMRR != null) {
            q.Delta_MRR__c = qw.deltaMRR;
        }

        if (qw.deltaARR != null) {
            q.Delta_ARR__c = qw.deltaARR;
        }

        if (qw.faxAreaCodeId != null) {
            q.FaxAreaCode__c = qw.faxAreaCodeId;
        }

        if (qw.isTermination != null) {
            q.IsTermination__c = qw.isTermination;
        }

        q.IsDeselected__c = BooleanHelper.toBoolean(qw.isDeselected);

        if (qw.totalFirstYearCost != null) {
            q.Total_First_Year_Cost__c = qw.totalFirstYearCost;
        }

        return q;
    }

    public static Map<Id, List<ServiceInfo__c>> getMasterQuoteIdToServiceInfosMap(Set<Id> masterQuoteIds) {
        Map<Id, List<ServiceInfo__c>> masterQuoteIdToServiceInfoMap = new Map<Id, List<ServiceInfo__c>>();

        List<ServiceInfo__c> serviceInfos = (List<ServiceInfo__c>) new ServiceInfoSelector()
            .selectServiceInfoForClone( new List<Object>{ masterQuoteIds })
            .executeQuery();

        if (serviceInfos.isEmpty()) {
            return masterQuoteIdToServiceInfoMap;
        }

        for (ServiceInfo__c serviceInfo : serviceInfos) {
            Id masterQuoteId = serviceInfo.Quote__r.MasterQuote__c != null ? serviceInfo.Quote__r.MasterQuote__c : serviceInfo.Quote__c;
            if (!masterQuoteIdToServiceInfoMap.containsKey(masterQuoteId)) {
                masterQuoteIdToServiceInfoMap.put(masterQuoteId, new List<ServiceInfo__c>());
            }
            masterQuoteIdToServiceInfoMap.get(masterQuoteId).add(serviceInfo);
        }
        return masterQuoteIdToServiceInfoMap;
    }

    public static List<ServiceInfo__c> syncServiceInfo(Id masterQuoteId, Map<String, Boolean> terminationMap) {
        return new NoSharing().syncServiceInfo(masterQuoteId, terminationMap);
    }

    public static List<ServiceInfo__c> getServiceInfo(Id masterQuoteId) {
        return (List<ServiceInfo__c>) new ServiceInfoSelector()
            .selectServiceInfoForClear(new List<Object>{ masterQuoteId })
            .executeQuery();
    }

    public static BillingWrappers.QuotePackageInfo getTechnicalQuotePackageInfo(
        Quote masterQuote,
        String service
    ) {
        List<BillingWrappers.QuotePackageInfo> masterQuotePackageInfo = getPackageInfoList(masterQuote);
        BillingWrappers.QuotePackageInfo technicalQuotePackageInfo = new BillingWrappers.QuotePackageInfo();

        for (BillingWrappers.QuotePackageInfo pInfo : masterQuotePackageInfo) {
            if (pInfo.productName == service) {
                technicalQuotePackageInfo = pInfo;
            }
        }

        return technicalQuotePackageInfo;
    }

    public static Boolean isMultiProductEBMasterQuote(Quote masterQuote) {
        return masterQuote.Master_Quotes__r.size() > 0 && masterQuote.Opp_Type__c == OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS;
    }

    public static List<Quote> makePrimaryQuote(Opportunity opp, Id quoteId, List<Quote> quoteList) {
        List<Quote> quotes = new List<Quote>();
        List<Quote> techQuotes =  new List<Quote>();

        for (Quote quote : quoteList) {
            if (!quote.IsMultiProductTechnicalQuote__c) {
                quotes.add(quote);
            } else {
                techQuotes.add(quote);
            }
        }

        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        List<Quote> quoteListToUpdate = new List<Quote>();

        quotes = getFilteredQuoteList(quotes, quoteId);
        Quote primaryQuote = QuoteHelper.getPrimaryQuote(quotes, true);
        Id parentQuoteId = primaryQuote != null ? primaryQuote.ParentQuote__c : null;
        for (Quote q : quotes) {
            if (q.Id == quoteId) {
                q.isPrimary__c = true;
                q.ParentQuote__c = parentQuoteId;
                Opportunity oppToUpdate = QuoteHelper.getOpportunityToUpdateTierName(opp, q);
                if (oppToUpdate != null) {
                    opportunitiesToUpdate.add(oppToUpdate);
                }
            } else {
                q.isPrimary__c = false;
                q.ParentQuote__c = null;
            }

            quoteListToUpdate.add(q);
        }

        if (!opportunitiesToUpdate.isEmpty()) {
            OpportunityHelper.setOpptyCLMEnable(opportunitiesToUpdate);
        }

        Boolean isMPUBAccount = AccountHelper.isMPUBAccount(opp.AccountId);
        Map<String, BillingWrappers.QuoteWrapper> quotesByService = new Map<String, BillingWrappers.QuoteWrapper>();
        for (Quote techQuote : techQuotes) {
            BillingWrappers.QuoteWrapper quoteWrapper = new BillingWrappers.QuoteWrapper();
            if (!isMPUBAccount) {
                quoteWrapper.isTermination = techQuote.IsTermination__c;
            }
            quotesByService.put(techQuote.ServiceName__c, quoteWrapper);
        }
        opportunitiesToUpdate.addAll(OpportunityHelper.getTechnicalQuotesForUpdate(opp.Id, quotesByService));

        update quoteListToUpdate;
        if (!opportunitiesToUpdate.isEmpty()) {
            Triggers.switchOff();
            update opportunitiesToUpdate;
            Triggers.switchOn();
        }

        return quoteListToUpdate;
    }

    private static List<Quote> getFilteredQuoteList(List<Quote> initQuoteList, Id quoteId) {
        List<Quote> filteredList = new List<Quote>();
        Map<Id, Quote> quoteMap = new Map<Id, Quote>();

        quoteMap.putAll(initQuoteList);
        Quote quotetoPrimary = quoteMap.get(quoteId);
        for (Quote qt : quoteMap.values()) {
            if (qt.RecordTypeId == quotetoPrimary.RecordTypeId) {
                filteredList.add(qt);
            }
        }
        return filteredList;
    }

    public static Quote clearQuotes(Id masterQuoteId, List<String> serviceNames) {
        List<Quote> qts = clearQuotes(new Set<Id>{masterQuoteId}, serviceNames);
        return qts.isEmpty() ? null : qts.get(0);
    }

    public static List<Quote> clearQuotes(Set<Id> masterQuoteIds, List<String> serviceNames) {
        List<QuoteLineItem> quoteItemsToDelete = new List<QuoteLineItem>();
        List<Quote> quotesToUpdate = new List<Quote>();

        if (masterQuoteIds.isEmpty()) {
            return new List<Quote>();
        }

        List<Quote> quotes = (List<Quote>) new QuoteSelector()
            .selectQuotesByMasterQuoteIdToClearQLIs(masterQuoteIds, serviceNames)
            .executeQuery();

        if (quotes.isEmpty()) {
            return new List<Quote>();
        }

        for (Quote qt : quotes) {
            Quote updatedQuote = new Quote(Id = qt.Id);

            updatedQuote.OverallDiscretion__c = 0;
            updatedQuote.AverageDiscount__c = 0;

            if (qt.QuoteLineItems != null) {
                quoteItemsToDelete.addAll(qt.QuoteLineItems);
            }

            if (qt.IsMultiProductTechnicalQuote__c && serviceNames.contains(qt.ServiceName__c)) {
                updatedQuote.IsDeselected__c = true;
            }

            quotesToUpdate.add(updatedQuote);
        }

        if (quoteItemsToDelete.size() > 0) {
            delete quoteItemsToDelete;
        }

        if (quotesToUpdate.size() > 0) {
            Triggers.switchOff();
            update quotesToUpdate;
            Triggers.switchOn();
        }

        return (List<Quote>) new QuoteSelector()
            .selectQuotesByMasterQuoteIdToClearQLIs(masterQuoteIds, serviceNames)
            .executeQuery();
    }

    public static Boolean isQuoteDeselected(Quote qt) {
        return qt != null && qt.isDeselected__c;
    }

    public static Boolean isNotAllDevicesShipped(Quote quote, List<QuoteLineItem> qlis) {
        return QuoteValidator.getSignUpShippingValidations(quote, qlis, 'SignUp_QuantityShippingValidator');
    }

    public static Boolean isEngage(Quote qt) {
        if (BooleanHelper.toBoolean(qt?.IsMultiProductTechnicalQuote__c)) {
            return OpportunityHelper.ENGAGE_TIERS.contains(qt?.ServiceName__c);
        } else {
            return isEngageService(qt);
        }
    }

    public static Boolean isRCCC(Quote qt) {
        if (BooleanHelper.toBoolean(qt?.IsMultiProductTechnicalQuote__c)) {
            return OpportunityHelper.TIER_RC_CONTACT_CENTER.equalsIgnoreCase(qt?.ServiceName__c);
        } else {
            return isCCService(qt);
        }
    }

    public static Boolean isOffice(Quote qt) {
        if (BooleanHelper.toBoolean(qt?.IsMultiProductTechnicalQuote__c)) {
            return OpportunityHelper.TIER_OFFICE.equalsIgnoreCase(qt?.ServiceName__c);
        } else {
            return isOfficeService(qt);
        }
    }

    public static Boolean containsOffice(List<Quote> quotes) {
        for (Quote qt : quotes) {
            if (!isProServOrCCProServ(qt) && isOffice(qt)) {
                return true;
            }
        }
        return false;
    }

    public static Boolean isEngageOrInContact(Quote qt) {
        return isEngage(qt) || isRCCC(qt);
    }

    public static Boolean isEngageTerminationQuote(Quote qt) {
        if (!isEngage(qt)) {
            return false;
        }
        if (BooleanHelper.toBoolean(qt?.IsTermination__c)) {
            return true;
        }

        List<ServiceInfo__c> serviceInfos = (List<ServiceInfo__c>) new ServiceInfoSelector()
            .selectServiceInfoForClear(new List<Object>{ qt.Id })
            .executeQuery();

        return !serviceInfos.isEmpty() && serviceInfos.get(0).IsTermination__c;
    }

    public static Boolean isEvents(Quote qt) {
        if (BooleanHelper.toBoolean(qt?.IsMultiProductTechnicalQuote__c)) {
            return Constants.CONST_RC_EVENT.equalsIgnoreCase(qt?.ServiceName__c);
        } else {
            return isEventsService(qt);
        }
    }

    public static Boolean isMeetings(Quote qt) {
        if (BooleanHelper.toBoolean(qt?.IsMultiProductTechnicalQuote__c)) {
            return OpportunityHelper.TIER_MEETINGS.equalsIgnoreCase(qt?.ServiceName__c);
        } else {
            return isMeetingsService(qt);
        }
    }

    public static Boolean isFax(Quote qt) {
        if (BooleanHelper.toBoolean(qt?.IsMultiProductTechnicalQuote__c)) {
            return OpportunityHelper.TIER_FAX.equalsIgnoreCase(qt?.ServiceName__c);
        } else {
            return isFaxService(qt);
        }
    }

    public static Boolean isProServService(Quote qt) {
        return NGBS_PROFESSIONAL_SERVICES_PRODUCT.equalsIgnoreCase(qt?.ServiceName__c);
    }

    public static Boolean isMPUBQuote(Quote qt) {
        if (String.isBlank(qt?.Id)) {
            return false;
        }

        Feature_Toggle__c ft = Feature_Toggle__c.getInstance();
        if (!ft?.EnableMultiProductUnifiedBilling__c) {
            return false;
        }

        return isMPUBQuote(qt, AccountHelper.getTechnicalAccounts(qt.AccountId));
    }

    public static Boolean isMPUBQuote(Quote qt, List<Account> techAccounts) {
        if (String.isBlank(qt?.Id)) {
            return false;
        }

        Feature_Toggle__c ft = Feature_Toggle__c.getInstance();
        if (!ft?.EnableMultiProductUnifiedBilling__c) {
            return false;
        }

        if (qt?.Account?.IsMultiProductTechnicalAccount__c) {
            return false;
        } else {
            return techAccounts.isEmpty();
        }
    }

    public static void updateServiceInfo(Set<Id> quoteIds, Map<Id, Quote> quotesMapStatic) {
        // uncheck IsProcessOrderSent__c after quote/qli update
        List<ServiceInfo__c> serviceInfosToUpdate = new List<ServiceInfo__c>();
        for (Id quoteId : quoteIds) {
            Quote staticQuote = quotesMapStatic.get(quoteId);

            if (staticQuote.ServiceInfo__r.isEmpty()) {
                continue;
            }

            ServiceInfo__c serviceInfo = staticQuote.ServiceInfo__r[0];
            if (!serviceInfo.IsProcessOrderSent__c) {
                continue;
            }

            Boolean isBillingPackageCreatedForQuoteService = false;
            for (Order order : staticQuote.Orders3__r) {
                if (order.PackageId__c != null) {
                    isBillingPackageCreatedForQuoteService = true;
                    break;
                }
            }
            if (isBillingPackageCreatedForQuoteService) {
                continue;
            }

            serviceInfo.IsProcessOrderSent__c = false;
            serviceInfosToUpdate.add(serviceInfo);

        }

        if (!serviceInfosToUpdate.isEmpty()) {
            update serviceInfosToUpdate;
        }
    }

    @AuraEnabled
    public static void updateServiceInfoAfterSignUp(Id quoteId) {
        if (quoteId == null) {
            return;
        }

        try {
            updateServiceInfoAfterProcessOrder(quoteId);
        } catch (Exception e) {
            PlatformLog.logException('updateServiceInfo: ' + quoteId, e);
        }
    }

    @AuraEnabled
    public static Response updateServiceInfoAfterSync(Id quoteId) {
        Response res = new Response();
        if (quoteId == null) {
            return res;
        }

        try {
            updateServiceInfoAfterProcessOrder(quoteId);
        } catch (Exception e) {
            res.error('Error', e.getMessage() + ': ' + e.getStackTraceString());
        }
        return res;
    }

    public static void updateServiceInfoAfterProcessOrder(Id quoteId) {
        Quote qt = (Quote) new QuoteSelector()
            .selectQuotesByIdsToServiceInfo(new Set<Id>{quoteId})
            .executeQuery()
            .get(0);

        if (!qt.ServiceInfo__r.isEmpty()) {
            ServiceInfo__c serviceInfo = qt.ServiceInfo__r[0];

            if (!serviceInfo.IsProcessOrderSent__c) {
                serviceInfo.IsProcessOrderSent__c = true;
                update serviceInfo;
            }
        }
    }

    public static Boolean isLBOEnabled(Quote qt) {
      if (qt.isMultiProductTechnicalQuote__c) {
         return qt.MasterQuote__r.Enabled_LBO__c;
      }
      return qt.Enabled_LBO__c;
    }

    public static Quote getProServTechQuote(List<Quote> quotes) {
        Quote proServTechQuote;
        for (Quote qt : quotes) {
            if (isProServService(qt)) {
                proServTechQuote = qt;
            }
        }
        return proServTechQuote;
    }

    public without sharing class NoSharing {
        public List<ServiceInfo__c> syncServiceInfo(Id masterQuoteId, Map<String, Boolean> terminationMap) {
            Quote masterQuote = (Quote) new QuoteSelector()
                .selectQuoteForCloningUB(new List<Object> { masterQuoteId })
                .executeQuery()
                .get(0);

            List<ServiceInfo__c> oldServiceInfos = getServiceInfoForClone(masterQuoteId);
            Map<String, ServiceInfo__c> clonedServiceInfoMap = new Map<String, ServiceInfo__c>();
            for (ServiceInfo__c sInfo : oldServiceInfos) {
                clonedServiceInfoMap.put(sInfo.Quote__c, sInfo.clone(false, true, false, false));
            }

            delete oldServiceInfos;

            List<BillingWrappers.QuotePackageInfo> pInfoList = QuoteHelper.getPackageInfoList(masterQuote);

            List<Package__c> accountPackages = new List<Package__c>(); 
            if (String.isNotBlank(masterQuote.Account.Billing_ID__c)) {
                accountPackages = (List<Package__c>) new PackageSelector()
                    .selectPackageByAccountBillingId(masterQuote?.Account?.Billing_ID__c)
                    .executeQuery();
            }

            if (pInfoList?.size() == 1) {
                return createServiceInfo(new List<Quote>{ masterQuote }, accountPackages, terminationMap, clonedServiceInfoMap, masterQuoteId);
            }

            List<String> productNames = new List<String>();

            for (BillingWrappers.QuotePackageInfo pInfo : pInfoList) {
                productNames.add(pInfo.productName);
            }

            Map<String, Quote> technicalQuotes = QuoteHelper.getTechnicalQuotesByMasterIdUB(masterQuote, productNames);

            return createServiceInfo(technicalQuotes.values(), accountPackages, terminationMap, clonedServiceInfoMap, masterQuoteId);
        }

        private List<ServiceInfo__c> createServiceInfo(
            List<Quote> quotes,
            List<Package__c> accountPackages,
            Map<String, Boolean> terminationMap,
            Map<String, ServiceInfo__c> clonedServiceInfoMap,
            Id masterQuoteId
        ) {
            List<ServiceInfo__c> serviceInfoList = new List<ServiceInfo__c>();
            List<Id> quoteIds = new List<Id>();
            for (Quote q : quotes) {
                ServiceInfo__c serviceInfo = buildServiceInfo(q, accountPackages, terminationMap, clonedServiceInfoMap);

                serviceInfoList.add(serviceInfo);

                quoteIds.add(q.Id);
            }
            insert serviceInfoList;

            return (List<ServiceInfo__c>) new ServiceInfoSelector()
                .selectServiceInfoForClear(new List<Object>{ masterQuoteId })
                .executeQuery();
        }

        @TestVisible
        private ServiceInfo__c buildServiceInfo(
            Quote quote,
            List<Package__c> accountPackages,
            Map<String, Boolean> terminationMap,
            Map<String, ServiceInfo__c> clonedServiceInfoMap
        ) {
            ServiceInfo__c serviceInfo = clonedServiceInfoMap?.get(quote.Id);
            if (serviceInfo == null) {
                serviceInfo = new ServiceInfo__c();
                serviceInfo.Quote__c = quote.Id;
            }
            serviceInfo.Opportunity__c = quote.OpportunityId;
            serviceInfo.isTermination__c = quote.IsTermination__c;

            BillingWrappers.QuotePackageInfo pInfo = QuoteHelper.getPackageInfo(quote);
            if (String.isNotBlank(pInfo?.packageInfo?.id) && !accountPackages.isEmpty()) {
                for (Package__c pkg : accountPackages) {
                    if (pkg.Account_Package_Id__c == pInfo.packageInfo.id) {
                        serviceInfo.BillingPackage__c = pkg.Id;

                        Boolean isTermination = terminationMap.get(pInfo.productName);
                        if (isTermination != null) {
                            serviceInfo.IsTermination__c = isTermination;
                        }
                        break;
                    }
                }
            }
            return serviceInfo;
        }

        public List<ServiceInfo__c> getServiceInfoForClone(Id masterQuoteId) {
            return (List<ServiceInfo__c>) new ServiceInfoSelector()
                .selectServiceInfoForClone(new List<Object>{ masterQuoteId })
                .executeQuery();
        }
    }

    public static Boolean hasNonCancelledProServ(List<Quote> opportunityQuotes) {
        Quote primaryQuote;
        for (Quote qt : opportunityQuotes) {
            if (qt == null) {
                continue;
            }
            if (qt.IsPrimary__c) {
                primaryQuote = qt;
            } else if (QuoteHelper.isProservQuote(qt) || QuoteHelper.isCCProservQuote(qt)) {
                return qt.ProServ_Status__c != QuoteHelper.PROSERVSTATUS_CANCELLED;
            }
        }
        List<QuoteHelper.PackageInfo> pInfos = QuoteHelper.getPackageInfo(primaryQuote?.Package_Info__c);
        for (QuoteHelper.PackageInfo pi : pInfos) {
            if (pi.ProductName == QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT) {
                return true;
            }
        }
        return false;
    }
    
    public static Boolean isNewBusinessPO(Quote qt) {
        if (qt == null) {
            return false;
        }
        Boolean isEngagePOC = QuoteHelper.isEngage(qt) && QuoteHelper.isPOCQuote(qt) && !qt.IsMultiProductTechnicalQuote__c;
        Boolean isMultiProductTech = qt.IsMultiProductTechnicalQuote__c;
        
        if (isEngagePOC || isMultiProductTech) {
            return String.isBlank(qt.PackageNameOld__c);
        } else {
            return String.isBlank(qt.Account?.RC_User_ID__c) && String.isBlank(qt.Account?.Billing_ID__c);
        }
    }
}