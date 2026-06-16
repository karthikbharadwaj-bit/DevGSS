/*
* invoice-engine doc: http://stg01-jenkins01.lab.nordigy.ru:8080/view/EDI-ATT-SV7/job/edi-att-sv7-billing-invoice-build/API_documentation/
* account-manager doc: http://stg01-jenkins01.lab.nordigy.ru:8080/view/EDI-ATT-SV7/job/edi-att-sv7-billing-account-build/API_documentation/
*/
public with sharing class NGBSAPI {
    public class NGBSAPIException extends Exception {}

    public class NGBSSettings {
        public String AccountManagerPath;
        public String BaseEndpoint;
        public String CatalogPath;
        public String InvoiceEnginePath;
        public String Login;
        public String Password;

        void initSettings(SObject instance) {
            BaseEndpoint = (String) instance.get('BaseEndpoint__c');
            AccountManagerPath = (String) instance.get('AccountManagerPath__c');
            CatalogPath = (String) instance.get('CatalogPath__c');
            InvoiceEnginePath = (String) instance.get('InvoiceEnginePath__c');
            Login = (String) instance.get('Login__c');
            Password = (String) instance.get('Password__c');
        }
    }

    public static final String ITEM_TYPE_FEATURE_CHARGE = 'FeatureCharge';
    public static final String ITEM_TYPE_CANCELLATION_CREDIT = 'CancellationCredit';
    public static final String ITEM_TYPE_ADJUSTMENT_CREDIT = 'AdjustmentCredit';
    public static final String ITEM_TYPE_TAX_CHARGE = 'Tax Charge';
    public static final String ITEM_TYPE_TAX_CREDIT = 'Tax Credit';
    public static final String ITEM_TYPE_PRORATION_CREDIT = 'ProrationCredit';
    public static final Set<String> NGBS_ITEM_TYPES_TO_NOT_PROCESS = new Set<String> {
        ITEM_TYPE_TAX_CHARGE
    };

    private static final Set<Integer> API_SUCCESS_CODES = new Set<Integer>{200, 201, 204};
    private static final Set<String> NGBS_BILL_STATE_TO_NOT_PROCESS = new Set<String> {'Unpaid', 'Failed'};
    private static final String UNEXPECTED_PARAMETER_EMPTY_EXCEPTION_MESSAGE = 'Not expected: parameter empty. Parameter name: ';
    private static final String REQUEST_NGBS_EXCEPTION_MESSAGE = 'Failed to make NGBS request. Got status: ';
    public static final String REQUEST_BILLING_INFO_SUMMARY_NGBS_EXCEPTION_MESSAGE = 'Error occurred during retrieving billing info summary from NGBS';
    public static final String REQUEST_FSC_EXCEPTION_MESSAGE = 'Error occurred during retrieving Free Service Credit amount from NGBS';
    public static final String UPDATE_FSC_EXCEPTION_MESSAGE = 'Error occurred during updating free service credit in NGBS';
    public static final String BILLING_ID_AND_PACKAGE_ID_EMPTY_EXCEPTION_MESSAGE = 'Parameters billingId and packageId are required';
    public static final String BILLING_ID_AND_NEW_AMOUNT_EMPTY_EXCEPTION_MESSAGE = 'Parameters "billingId" and "newAmount" are required';
    public static final String TRANSACTION_TYPE_NGBS = 'NGBS';
    public static final String MONTHLY_AMOUNT_LIMIT = 'MONTHLY_AMOUNT_LIMIT';
    public static final String STATUS_SUCCESS = 'Success';
    public static final String INVOICEONBEHALF_PAYMENTMETHOD_NICKNAME = 'InvoiceOnBehalf';
    public static final String INVOICEWHOLESALE_PAYMENTMETHOD_NICKNAME = 'InvoiceWholesale';

    public static final String NGBS_PACKAGE_JSON_EMTPY_EXCEPTION_MESSAGE = 'package JSON string is empty';
    public static final String NOT_FOUND_LABELS_JSON_PROPERTY_EXCEPTION_MESSAGE = 'Cannot find "labels" property in JSON';

    public static NGBSSettings settings;
    private static final SObject NGBS_SETTINGS_INSTANCE = NGBS_Settings__c.getInstance();
    private static final SObject NGBS_SETTINGS_FEDRAMP_INSTANCE = NGBS_Settings_FedRamp__c.getInstance();

    private static Boolean isFedRamp;

    public static String NGBS_ACCOUNT_MANAGER;
    public static String NGBS_INVOICE_ENGINE;
    public static String NGBS_CATALOG_PATH;

    public static String NGBS_PACKAGES;
    public static final Map<String, String> COUNTRY_MAPPING = SettingsService.getCountryCodes();

    public static final Map<String, String> PAYMENT_TYPE_PURCHASE_TO_PAYMENT_TYPE_APPLY = new Map<String, String> {
        'Invoice' => 'AccountCredit',
        'CreditCard' => 'OriginalPaymentMethod'
    };

    //GET/POST
    public static String NGBS_DISCOUNT_GROUP;
    //GET/POST /restapi/account-manager/v1.0/account/{accountId}/paymentMethod
    public static String NGBS_PAYMENT_METHOD_FORMAT;
    //GET/POST /restapi/account-manager/v1.0/account/{accountId}/paymentMethod/type
    public static String NGBS_PAYMENT_METHOD_TYPE_FORMAT;
    //GET/POST /restapi/account-manager/v1.0/account/{accountId}/contactInfo
    public static String NGBS_PAYMENT_CONTACT_FORMAT;
    //GET /restapi/account-manager/v1.0/account/{accountId}/package/{packageId}/limits
    public static String NGBS_PACKAGE_LIMITS_F0RMAT;
    //POST /restapi/account-manager/v1.0/account/{accountId}/package/{packageId}/limits
    public static String NGBS_PACKAGE_LIMITS_OVERRIDE_FORMAT;
    //POST /restapi/account-manager/v1.0/account/{accountId}/package/{packageId}/limits/update
    public static String NGBS_PACKAGE_LIMITS_UPDATE_FORMAT;
    //GET /restapi/invoice-engine/v1.0/account/{accountId}/history
    public static String NGBS_BILLING_ACCOUNT_HISTORY_FORMAT;
    //POST /restapi/account-manager/v1.0/account/{accountId}/package/{packageId}/elaSettings
    public static String NGBS_PACKAGE_ELA_SETTINGS_UPDATE;
    //GET /restapi/account-manager/v1.0/account/{accountId}/purchase/bill/{billId}
    public static String NGBS_BILLING_API_URL_FOR_BILL_DETAIL;
    //GET /restapi/invoice-engine/v1.0/account/{accountId}/bill/{billId}/refund
    public static String NGBS_BILLING_API_URL_FOR_TRANSACION_REFUNDS;
    //GET /restapi/account-manager/v1.0/account/{accountId}/purchase/invoice/{invoiceId}
    public static String NGBS_BILLING_API_URL_FOR_INVOICE_DETAIL;
    //POST /restapi/account-manager/v1.0/account/{accountId}/bill/{billId}/refund/calculate
    public static String NGBS_BILL_API_FOR_CALCULATED_REFUNDS;
    //POST /restapi/invoice-engine/v1.0/account/{accountId}/invoice/adjustment/calculate
    public static String NGBS_INVOICE_API_FOR_CALCULATED_REFUNDS;
    //POST /restapi/account-manager/v1.0/account/{accountId}/invoice/adjustment/apply
    public static String NGBS_INVOICE_APPLY_REFUND;
    //POST /restapi/account-manager/v1.0/account/{accountId}/bill/{billId}/refund/apply
    public static String NGBS_BILL_APPLY_REFUND;
    //GET/POST /restapi/account-manager/v1.0/account/{accountId}/tax-settings
    public static String NGBS_ACCOUNT_TAX_EXEMPTION_SETTINGS;
    //GET/POST /restapi/account-manager/v1.0/account/{accountId}/summary
    public static String NGBS_ACCOUNT_SUMMARY;
    //GET/POST /restapi/account-manager/v1.0/account/{accountId}/summary?shortView=true
    public static String NGBS_ACCOUNT_SUMMARY_SHORT_VIEW;
    //GET /restapi/v1.0/account-manager/account/{accountId}/package/{packageId}/lboxes
    public static String NGBS_LBOX_LIMITS;
    //POST /restapi/account-manager/v1.0/account/{accountId}/package/{packageId}/lboxes/override
    public static String NGBS_LBOX_LIMITS_OVERRIDE;
    //GET /restapi/account-manager/v1.0/account/{accountId}/package/{packageId}/billinginfo/summary
    public static String NGBS_BILLING_INFO_SUMMARY;
    //GET /restapi/account-manager/v1.0/account/{accountId}/package/{packageId}/billinginfo/summary/license
    public static String NGBS_BILLING_INFO_SUMMARY_LICENSE;
    //POST /restapi/account-manager/v1.0/account/{accountId}/package/{packageId}/license/info/categories
    public static String NGBS_ACCOUNT_LICENSE_INFO_CATEGORIES;
    //PUT /restapi/account-manager/v1.0/account/{accountId}/freeServiceCredit
    public static String NGBS_FSC;
    //PUT //GET /restapi/account-manager/v1.0/account/{accountId}/package/{packageId}/freeServiceCredit
    public static String NGBS_PACKAGE_FSC;
    //CREATE / UPDATE
    public static String NGBS_CONTRACT;
    //CREATE / UPDATE
    public static String NGBS_CONTRACT_MPUB;
    //DELETE /restapi/account-manager/v1.0/account/{accountId}/package/{packageId}/contract/{contractId}
    public static String NGBS_CONTRACT_CANCELLATION;
    //DELETE /restapi/account-manager/v1.0/account/{accountId}/contract/{contractId}
    public static String NGBS_CONTRACT_CANCELLATION_MPUB;
    //GET/POST/PUT
    public static String NGBS_PACKAGE_PARAMETERS;
    // GET /restapi/catalog/v1.0/dictionaries/countries/{countryCode}/states
    public static String NGBS_STATES;
    //PUT //restapi/account-manager/v1.0/account/{accountId}/address?type=Billing
    public static String NGBS_BILLING_ADDRESS;
    //GET/PUT /restapi/account-manager/v1.0/account/{accountId}/fields
    public static String NGBS_ACCOUNT_FIELDS_FORMAT;
    //GET /restapi/account-manager/v1.0/account/:id/paymentMethod/type
    public static String NGBS_PAYMENT_METHOD_TYPE;
    //GET /restapi/account-manager/v1.0/account/{accountId}/package/{packageId}/recurringCharges
    public static String NGBS_ACCOUNT_RECURRING_CHARGES;
    //GET/POST/DELETE /restapi/account-manager/v1.0/account/{accountId}/packageConsolidationSettings
    public static String NGBS_PACKAGE_CONSOLIDATION_SETTINGS;
    //GET/ /restapi/account-manager/v1.0/account/accountId/billingCodes
    public static String NGBS_BILLING_CODES;
    //POST/ /restapi/account-manager/v1.0/account/accountId/billingCodes/main
    public static String NGBS_BILLING_CODES_MAIN_CREATION;
    //POST /restapi/account-manager/v1.0/account/billingId/billingCodes/status?enabled=false
    public static String NGBS_BILLING_CODES_STATUS_UPDATE;
    //POST/ /restapi/account-manager/v1.0/account/accountId/purchase/packageId/order/v2
    public static String NGBS_PAYMENT_INFORMATION;
    //POST /restapi/account-manager/v1.0/account/{accountId}/package/{packageId}/status
    public static String NGBS_PACKAGE_STATUS;


    public static final String DISTRIBUTE_CANCALLATION_CREDIT_PARAMETER = 'creditApplication=AutoDistribute';

    private static final String UNEXPECTED_FILTER_BY_PARAMETER = 'Unexpected FILTER_BY parameter';

    private static final String TO_SKIP_PROCESSING = 'TO_SKIP_PROCESSING_RECALCULATION';

    static {
        isFedRamp = false;
        settings = new NGBSSettings();
        initEndpoints();
    }

    private static void initEndpoints() {
        if (!isFedRamp) {
            settings.initSettings(NGBS_SETTINGS_INSTANCE);
        } else {
            settings.initSettings(NGBS_SETTINGS_FEDRAMP_INSTANCE);
        }

        NGBS_ACCOUNT_MANAGER = settings.BaseEndpoint + settings.AccountManagerPath + '/account';
        NGBS_INVOICE_ENGINE = settings.BaseEndpoint + settings.InvoiceEnginePath + '/account';
        NGBS_CATALOG_PATH = settings.BaseEndpoint + settings.CatalogPath;

        NGBS_PACKAGES = NGBS_CATALOG_PATH + '/packages';
        NGBS_DISCOUNT_GROUP = NGBS_CATALOG_PATH + '/discountGroups';
        NGBS_STATES = NGBS_CATALOG_PATH + '/dictionaries/countries/{0}/states';
        NGBS_PAYMENT_METHOD_FORMAT = NGBS_ACCOUNT_MANAGER + '/{0}/paymentMethod';
        NGBS_PAYMENT_METHOD_TYPE_FORMAT = NGBS_ACCOUNT_MANAGER + '/{0}/paymentMethod/type';
        NGBS_PAYMENT_CONTACT_FORMAT = NGBS_ACCOUNT_MANAGER + '/{0}/contactInfo';
        NGBS_PACKAGE_LIMITS_F0RMAT = NGBS_ACCOUNT_MANAGER + '/{0}/package/{1}/limits';
        NGBS_PACKAGE_LIMITS_OVERRIDE_FORMAT = NGBS_ACCOUNT_MANAGER + '/{0}/package/{1}/limits/override';
        NGBS_PACKAGE_LIMITS_UPDATE_FORMAT = NGBS_ACCOUNT_MANAGER + '/{0}/package/{1}/limits/update';
        NGBS_BILLING_ACCOUNT_HISTORY_FORMAT = NGBS_INVOICE_ENGINE + '/{0}/history';
        NGBS_PACKAGE_ELA_SETTINGS_UPDATE = NGBS_ACCOUNT_MANAGER + '/{0}/package/{1}/elaSettings';
        NGBS_BILLING_API_URL_FOR_BILL_DETAIL = NGBS_ACCOUNT_MANAGER + '/{0}/purchase/bill/{1}';
        NGBS_BILLING_API_URL_FOR_TRANSACION_REFUNDS = NGBS_ACCOUNT_MANAGER + '/{0}/bill/{1}/refund';
        NGBS_BILLING_API_URL_FOR_INVOICE_DETAIL = NGBS_ACCOUNT_MANAGER + '/{0}/purchase/invoice/{1}';
        NGBS_BILL_API_FOR_CALCULATED_REFUNDS = NGBS_ACCOUNT_MANAGER + '/{0}/bill/{1}/refund/calculate';
        NGBS_INVOICE_API_FOR_CALCULATED_REFUNDS = NGBS_INVOICE_ENGINE + '/{0}/invoice/adjustment/calculate';
        NGBS_INVOICE_APPLY_REFUND = NGBS_ACCOUNT_MANAGER + '/{0}/invoice/adjustment/apply';
        NGBS_BILL_APPLY_REFUND = NGBS_ACCOUNT_MANAGER + '/{0}/bill/{1}/refund/apply';
        NGBS_ACCOUNT_TAX_EXEMPTION_SETTINGS = NGBS_ACCOUNT_MANAGER + '/{0}/tax-settings';
        NGBS_ACCOUNT_SUMMARY = NGBS_ACCOUNT_MANAGER + '/{0}/summary';
        NGBS_ACCOUNT_SUMMARY_SHORT_VIEW = NGBS_ACCOUNT_MANAGER + '/{0}/summary?shortView=true';
        NGBS_LBOX_LIMITS = NGBS_ACCOUNT_MANAGER + '/{0}/package/{1}/lboxes';
        NGBS_LBOX_LIMITS_OVERRIDE = NGBS_ACCOUNT_MANAGER + '/{0}/package/{1}/lboxes/override';
        NGBS_BILLING_INFO_SUMMARY = NGBS_ACCOUNT_MANAGER + '/{0}/package/{1}/billinginfo/summary';
        NGBS_BILLING_INFO_SUMMARY_LICENSE = NGBS_ACCOUNT_MANAGER + '/{0}/package/{1}/billinginfo/summary/license';
        NGBS_ACCOUNT_LICENSE_INFO_CATEGORIES = NGBS_ACCOUNT_MANAGER + '/{0}/package/{1}/license/info/categories';
        NGBS_FSC = NGBS_ACCOUNT_MANAGER + '/{0}/freeServiceCredit';
        NGBS_PACKAGE_FSC = NGBS_ACCOUNT_MANAGER + '/{0}/package/{1}/freeServiceCredit';
        NGBS_CONTRACT = NGBS_ACCOUNT_MANAGER + '/{0}/package/{1}/contract';
        NGBS_CONTRACT_MPUB = NGBS_ACCOUNT_MANAGER + '/{0}/contract';
        NGBS_CONTRACT_CANCELLATION = NGBS_ACCOUNT_MANAGER + '/{0}/package/{1}/contract/{2}';
        NGBS_PACKAGE_PARAMETERS = NGBS_ACCOUNT_MANAGER + '/{0}/package/{1}/parameters';
        NGBS_BILLING_ADDRESS = NGBS_ACCOUNT_MANAGER + '/{0}/address?type=Billing';
        NGBS_ACCOUNT_FIELDS_FORMAT = NGBS_ACCOUNT_MANAGER + '/{0}/fields';
        NGBS_PAYMENT_METHOD_TYPE = NGBS_ACCOUNT_MANAGER + '/{0}/paymentMethod/type';
        NGBS_ACCOUNT_RECURRING_CHARGES = NGBS_ACCOUNT_MANAGER + '/{0}/package/{1}/recurringCharges';
        NGBS_CONTRACT_CANCELLATION_MPUB = NGBS_ACCOUNT_MANAGER + '/{0}/contract/{1}';
        NGBS_PACKAGE_CONSOLIDATION_SETTINGS = NGBS_ACCOUNT_MANAGER + '/{0}/packageConsolidationSettings';
        NGBS_BILLING_CODES = NGBS_ACCOUNT_MANAGER + '/{0}/billingCodes';
        NGBS_BILLING_CODES_MAIN_CREATION = NGBS_ACCOUNT_MANAGER + '/{0}/billingCodes/main';
        NGBS_BILLING_CODES_STATUS_UPDATE = NGBS_ACCOUNT_MANAGER + '/{0}/billingCodes/status?enabled={1}';
        NGBS_PAYMENT_INFORMATION = NGBS_ACCOUNT_MANAGER + '/{0}/purchase/{1}/order/v2';
        NGBS_PACKAGE_STATUS = NGBS_ACCOUNT_MANAGER + '/{0}/package/{1}/status?newStatus={2}';
    }

    public static Boolean getIsFedRampState() {
        return isFedRamp;
    }
    public static void initNgbsEndpoints(Boolean state) {
        if (isFedRamp != state) {
            isFedRamp = state;
            initEndpoints();
        }
    }

    // ------------------------------------------------------------------
    // Models
    // ------------------------------------------------------------------
    //TODO write description
    @TestVisible
    private class RecalculationWrapper {
        public Decimal negativeUnassignedValue;
        public List<TransactionsRefundsAPI.ProductItemDTO> productItems;
        public RecalculationWrapper(
            Decimal negativeUnassignedValue,
            List<TransactionsRefundsAPI.ProductItemDTO> productItems
        ) {
            this.negativeUnassignedValue = negativeUnassignedValue;
            this.productItems = productItems;
        }
    }

    @TestVisible
    private enum FILTER_BY {COMBINED_CATALOG_ID, CATEGORY_ID, NONE}

    public enum TRANSACTION_TYPE {BILL, INVOICE}

    /*
    * NGBSObjectName: BillingHistory
    * documentation: http://stg01-jenkins01.lab.nordigy.ru:8080/view/EDI-ATT-SV7/job/edi-att-sv7-billing-invoice-build/API_documentation/
    */
    public class AccountHistoryResponse {
        public List<PendingInvoice> pendingInvoices;
        public List<AccountHistoryBill> bills;
        public AccountHistoryResponse(List<PendingInvoice> pendingInvoices, List<AccountHistoryBill> bills) {
            this.pendingInvoices = pendingInvoices;
            this.bills = bills;
        }

        public List<TransactionsRefundsAPI.TransactionsDTO> convertToListOfTransactions() {
            return getTransactions();
        }

        private List<TransactionsRefundsAPI.TransactionsDTO> getTransactions() {
            List<TransactionsRefundsAPI.TransactionsDTO> transactions = new List<TransactionsRefundsAPI.TransactionsDTO>();

            if (bills == null || bills.isEmpty()) {
                bills = new List<AccountHistoryBill>();
            }
            for (AccountHistoryBill b : bills) {
                if (NGBS_BILL_STATE_TO_NOT_PROCESS.contains(b.state)) {
                    continue;
                }
                //don't process bills that don't have a positive transaction amount
                if (b.newBalance <= 0) {
                    continue;
                }
                String transactionId = String.valueOf(b.Id);
                String transactionDate = NGBSAPI.normalizeTransactionDate(b.billDate);
                       transactionDate = NGBSAPI.convertToLocal(transactionDate);
                TransactionsRefundsAPI.TransactionsDTO tr =
                    new TransactionsRefundsAPI.TransactionsDTO(
                        transactionId, transactionDate, null, null, null, null, null, null
                    );
                tr.ngbsType = TransactionsRefundsAPI.TRANSACTION_NGBS_TYPE_BILL;
                transactions.add(tr);
            }

            if (pendingInvoices == null || pendingInvoices.isEmpty()) {
                pendingInvoices = new List<PendingInvoice>();
            }
            for (PendingInvoice pi : pendingInvoices) {

                //don't process pendingInvoices that don't have a positive transaction amount
                if (pi.totalAmount <= 0) {
                    continue;
                }
                String transactionId = String.valueOf(pi.Id);
                String transactionDate = NGBSAPI.normalizeTransactionDate(pi.created);
                       transactionDate = NGBSAPI.convertToLocal(transactionDate);
                TransactionsRefundsAPI.TransactionsDTO tr =
                    new TransactionsRefundsAPI.TransactionsDTO(
                        transactionId, transactionDate, null, null, null, null, null, null
                    );
                tr.ngbsType = TransactionsRefundsAPI.TRANSACTION_NGBS_TYPE_INVOICE;
                transactions.add(tr);
            }
            return transactions;
        }
    }

    /*
    * NGBSObjectName: InvoiceInfo
    * documentation: http://stg01-jenkins01.lab.nordigy.ru:8080/view/EDI-ATT-SV7/job/edi-att-sv7-billing-invoice-build/API_documentation/
    */
    public class PendingInvoice {
        public Long id;
        public String created;
        public Decimal totalAmount;

        public PendingInvoice(Integer id, String created, Decimal totalAmount) {
            this.id = id;
            this.created = created;
            this.totalAmount = totalAmount;
        }
    }

    /*
    * NGBSObjectName: BillInfo
    * documentation: http://stg01-jenkins01.lab.nordigy.ru:8080/view/EDI-ATT-SV7/job/edi-att-sv7-billing-invoice-build/API_documentation/
    */
    public class AccountHistoryBill {
        public Long id;
        public String billDate;
        public String state;
        public Decimal newBalance;
        public AccountHistoryBill(Long id, String billDate, String state, Decimal newBalance) {
            this.id = id;
            this.billDate = billDate;
            this.state = state;
            this.newBalance = newBalance;
        }
    }

    /*
    * NGBSObjectName: BillResult
    * documentation: http://stg01-jenkins01.lab.nordigy.ru:8080/view/EDI-ATT-SV7/job/edi-att-sv7-billing-account-build/API_documentation/
    */
    public class BillDetail {
        public BillDetailBill bill {get;set;}
        public List<DetailPayments> payments {get;set;}

        public BillDetail(BillDetailBill bill, List<DetailPayments> payments) {
            this.bill = bill;
            this.payments = payments;
        }

        public List<TransactionsRefundsAPI.ProductItemDTO> convertToProductItem(String ngbsType) {
            if (bill == null) {
                bill = new BillDetailBill(new List<BillDetailBillInvoice>(), 0);
            }
            return bill.convertToProductItem(ngbsType);
        }

        public String getPaymentType() {
            String paymentType = null;
            if (this.payments == null || this.payments.isEmpty()) {
                return paymentType;
            }

            DetailPayments payment = this.payments[0];
            if (payment.paymentMethod != null) {
                paymentType = payment.paymentMethod.type;
            }
            return paymentType;
        }

    }

    public class DetailPayments {
        public DetailPaymentMethod paymentMethod;
        public DetailPayments(DetailPaymentMethod paymentMethod) {
            this.paymentMethod = paymentMethod;
        }
    }

    public class DetailPaymentMethod {
        public String type;
        public String id;
        public DetailPaymentMethod(String id, String type) {
            this.id = id;
            this.type = type;
        }
    }

    /*
    * NGBSObjectName: ProcessedBill
    * documentation: http://stg01-jenkins01.lab.nordigy.ru:8080/view/EDI-ATT-SV7/job/edi-att-sv7-billing-account-build/API_documentation/
    */
    public class BillDetailBill {
        public List<BillDetailBillInvoice> invoices {get;set;}
        public Decimal appliedCredit {get;set;}

        public BillDetailBill(List<BillDetailBillInvoice> invoices, Decimal appliedCredit) {
            this.invoices = invoices;
            this.appliedCredit = (appliedCredit != null) ? appliedCredit : 0;
        }

        public List<TransactionsRefundsAPI.ProductItemDTO> convertToProductItem(String ngbsType) {
            List<TransactionsRefundsAPI.ProductItemDTO> productItems =
                new List<TransactionsRefundsAPI.ProductItemDTO>();
            if (invoices == null) {
                invoices = new List<BillDetailBillInvoice>();
            }
            for (BillDetailBillInvoice invoice : invoices) {
                List<TransactionsRefundsAPI.ProductItemDTO> productItemsForInvoice = invoice.convertToProductItem(ngbsType);
                productItems.addAll(productItemsForInvoice);
            }
            return productItems;
        }
    }

    /*
    * NGBSObjectName: ProcessedInvoice
    * documentation: http://stg01-jenkins01.lab.nordigy.ru:8080/view/EDI-ATT-SV7/job/edi-att-sv7-billing-account-build/API_documentation/
    */
    public class BillDetailBillInvoice {
        public List<BillDetailBillInvoiceItem> items {get;set;}
        public Decimal controlSum {get;set;}
        public String currencyType {get;set;}
        public String Id {get;set;}
        public FreeServiceCreditApplicationInfo freeServiceCredit {get;set;}

        public BillDetailBillInvoice(
            List<BillDetailBillInvoiceItem> items,
            Decimal controlSum,
            String currencyType,
            String id,
            FreeServiceCreditApplicationInfo freeServiceCredit
        ) {
            this.items = items;
            this.controlSum = controlSum;
            this.currencyType = currencyType;
            this.id = id;
            this.freeServiceCredit =
                (freeServiceCredit != null) ? freeServiceCredit : new FreeServiceCreditApplicationInfo(0);
        }

        public List<TransactionsRefundsAPI.ProductItemDTO> convertToProductItem(String ngbsType) {
            List<TransactionsRefundsAPI.ProductItemDTO> productItems =
                new List<TransactionsRefundsAPI.ProductItemDTO>();
            if (items == null) {
                items = new List<BillDetailBillInvoiceItem>();
            }
//            if (this.controlSum <= 0) {
//                return productItems;
//            }

            for (BillDetailBillInvoiceItem invoiceItem : items) {
                if (NGBS_ITEM_TYPES_TO_NOT_PROCESS.contains(invoiceItem.itemType)) {
                    continue;
                }
                TransactionsRefundsAPI.ProductItemDTO productItem =
                    new TransactionsRefundsAPI.ProductItemDTO(
                        invoiceItem.licenseId,
                        invoiceItem.description,
                        invoiceItem.amount,
                        null,
                        currencyType,
                        ngbsType,
                        null
                    );
                if (this.Id != null) {
                    productItem.billId = this.Id;
                }
                productItem.lineNo = invoiceItem.lineNo;
                productItem.itemGroupId = invoiceItem.itemGroupId;
                productItem.categoryId = invoiceItem.categoryId;
                productItem.billingCodeId = invoiceItem.billingCodeId;

                List<TransactionsRefundsAPI.ItemsDTO> itemDTO = new List<TransactionsRefundsAPI.ItemsDTO>();
                itemDTO.add(new TransactionsRefundsAPI.ItemsDTO(
                    invoiceItem.licenseId,
                    invoiceItem.description,
                    invoiceItem.amount,
                    ngbsType,
                    invoiceItem.itemType,
                    invoiceItem.categoryId,
                    invoiceItem.combinedCatalogId,
                    invoiceItem.properties.taxItemId,
                    invoiceItem.properties.taxLevel,
                    new List<TransactionsRefundsAPI.ItemDetailsDTO>()
                ));

                productItem.items = itemDTO;

                productItems.add(productItem);
            }
            return productItems;
        }

    }

    /*
    * NGBSObjectName: Item
    * documentation: http://stg01-jenkins01.lab.nordigy.ru:8080/view/EDI-ATT-SV7/job/edi-att-sv7-billing-account-build/API_documentation/
    */
    public class BillDetailBillInvoiceItem {
        public String lineNo {get;set;}
        public String licenseId {get;set;}
        public String description {get;set;}
        public String categoryId {get;set;}
        public String billingCodeId {get;set;}
        public String combinedCatalogId {get;set;}
        public String itemType {get;set;}
        public String itemGroupId {get;set;}
        public Decimal amount {get;set;}
        public BillDetailBillInvoiceItemProperties properties {get;set;}

        public BillDetailBillInvoiceItem() {}

        public BillDetailBillInvoiceItem(
            String lineNo,
            String licenseId,
            String description,
            String categoryId,
            String billingCodeId,
            String combinedCatalogId,
            String itemType,
            String itemGroupId,
            Decimal amount,
            BillDetailBillInvoiceItemProperties properties
        ) {
            this.lineNo = lineNo;
            this.licenseId = licenseId;
            this.description = description;
            this.categoryId = categoryId;
            this.billingCodeId = billingCodeId;
            this.combinedCatalogId = combinedCatalogId;
            this.itemType = itemType;
            this.itemGroupId = itemGroupId;
            this.amount = amount;
            this.properties = properties;
        }
    }

    /*
    * NGBSObjectName: ...
    * documentation: http://stg01-jenkins01.lab.nordigy.ru:8080/view/EDI-ATT-SV7/job/edi-att-sv7-billing-account-build/API_documentation/
    */
    public class BillDetailBillInvoiceItemProperties {
        public String taxItemId {get;set;}
        public String taxLevel {get;set;}

        public BillDetailBillInvoiceItemProperties(
            String taxItemId,
            String taxLevel
        ) {
            this.taxItemId = taxItemId;
            this.taxLevel = taxLevel;
        }
    }

    public class FreeServiceCreditApplicationInfo {
        public Decimal appliedCredit {get;set;}

        public FreeServiceCreditApplicationInfo(
            Decimal appliedCredit
        ) {
            this.appliedCredit = (appliedCredit != null) ? appliedCredit : 0;
        }
    }

    /*
    * NGBSObjectName: ContactInfo
    * documentation: http://billing-dev.lab.nordigy.ru:8080/docs/ACM/s/21.3.0-DEV-SNAPSHOT#//restapi/account-manager/v1.0/account/updateAccountContactInfo
    */
    public class ContactInfoRequest {
        public String firstName;
        public String lastName;
        public String email;
        public String phone;
        public String companyName;

        public ContactInfoRequest(Account acc, Contact c) {
            this.firstName = c.FirstName;
            this.lastName = c.LastName;
            this.email = c.Email;
            this.phone = c.Phone;
            this.companyName = acc.Name;
        }
    }

    public class RefundApplicationMapWrapper {
        @AuraEnabled public List<CalculatedRefundItemGroup> refundItemGroups {get;set;}
        @AuraEnabled public List<CalculatedRefundTaxItem> refundTaxItems {get;set;}
        @AuraEnabled public String transactionId {get;set;}
        public RefundApplicationMapWrapper() {}
    }

    public class CalculatedRefundItemGroup {
        @AuraEnabled public List<CalculatedRefundItem> refundItems {get;set;}
        public CalculatedRefundItemGroup() {}
    }

    public class CalculatedRefundItem {
        @AuraEnabled public String invoiceId {get;set;}
        @AuraEnabled public String itemGroupId {get;set;}
        @AuraEnabled public Decimal amount {get;set;}
        public CalculatedRefundItem() {}
    }

    public class CalculatedRefundTaxItem {
        @AuraEnabled public String itemGroupId {get;set;}
        @AuraEnabled public String invoiceId {get;set;}
        @AuraEnabled public String taxItemId {get;set;}
        @AuraEnabled public String description {get;set;}
        @AuraEnabled public Decimal amount {get;set;}
        public Decimal initialAmount {get;set;}
        public CalculatedRefundTaxItem() {}
    }

    public class NGBSTransaction {
        /* bill id */
        public String id;
        public String paymentType;
        public NGBSItemGroup[] itemGroups;
    }

    public class NGBSItemGroup {
        public String id;
        public String invoiceId;
        public NGBSItem[] items;
    }

    public class NGBSItem {
        public String id;
        public String type;
        public String description;
        public Decimal amount;
    }

    public class NGBSResponse {
        public String status;
        public String message;

        public NGBSResponse(String status, String message) {
            this.status = status;
            this.message = message;
        }
    }

    public class TransactionRefundResponse {
        public List<TransactionRefund> refunds;
        public TransactionRefundResponse(List<TransactionRefund> refunds) {
            this.refunds = refunds;
        }

        public Map<String, Decimal> getNGBSRefundsMap() {
            Map<String, Decimal> refundsMap = new Map<String, Decimal>();
            for (NGBSAPI.TransactionRefund ref : this.refunds) {
                if (ref.applicationsByInvoice == null) {
                    continue;
                }
                for (NGBSAPI.ApplicationsByInvoice appByInv : ref.applicationsByInvoice) {
                    refundsMap = appByInv.updateRefundsMap(refundsMap);
                }
            }
            return refundsMap;
        }
    }

    public class TransactionRefund {
        public List<ApplicationsByInvoice> applicationsByInvoice;
        public String id;
        public TransactionRefund(List<ApplicationsByInvoice> applicationsByInvoice, String id) {
            this.applicationsByInvoice = applicationsByInvoice;
            this.id = id;
        }
    }

    public class ApplicationsByInvoice {
        public String invoiceId;
        public List<RefundInvoiceApplication> applications;
        public List<RefundTaxInfo> taxInfo;
        public ApplicationsByInvoice(String invoiceId, List<RefundInvoiceApplication> applications, List<RefundTaxInfo> taxInfo) {
            this.invoiceId = invoiceId;
            this.applications = applications;
            this.taxInfo = taxInfo;
        }

        public Map<String, Decimal> updateRefundsMap(Map<String, Decimal> refundsMap) {
            String invoiceId = this.invoiceId;
            if (this.applications != null) {
                for (NGBSAPI.RefundInvoiceApplication refInvAppl : this.applications) {
                    String key = TransactionsRefundsAPI.getKey(invoiceId, refInvAppl.invoiceItemGroupId);
                    refundsMap = updateRefundMapByItem(refundsMap, key, refInvAppl.amount);
                }
            }
            if (this.taxInfo != null) {
                for (NGBSAPI.RefundTaxInfo taxInfo : this.taxInfo) {
                    String key = TransactionsRefundsAPI.getKey(invoiceId, taxInfo.itemGroupId, taxInfo.description);
                    refundsMap = updateRefundMapByItem(refundsMap, key, taxInfo.amount);
                }
            }
            return refundsMap;
        }

        private Map<String, Decimal> updateRefundMapByItem(Map<String, Decimal> refundsMap, String key, Decimal amountToAdd) {
            Decimal currentRefund = refundsMap.get(key);
            Decimal updatedRefund = (currentRefund != null) ? currentRefund + amountToAdd : amountToAdd;
            refundsMap.put(key, updatedRefund);
            return refundsMap;
        }

    }

    public class RefundInvoiceApplication {
        public String invoiceItemGroupId;
        public String invoiceItemId;
        public Decimal amount;
        public RefundInvoiceApplication(String invoiceItemGroupId, String invoiceItemId, Decimal amount) {
            this.invoiceItemGroupId = invoiceItemGroupId;
            this.invoiceItemId = invoiceItemId;
            this.amount = amount;
        }
    }

    public class RefundTaxInfo {
        public String itemGroupId;
        public RefundTaxInfoProperties properties;
        public Decimal amount;
        public String description;

        public RefundTaxInfo(String itemGroupId, RefundTaxInfoProperties properties, Decimal amount, String description) {
            this.itemGroupId = itemGroupId;
            this.properties = properties;
            this.amount = amount;
            this.description = description;
        }

        public String getTaxItemId() {
            return (this.properties != null) ? this.properties.taxItemId : null;
        }

        public String getTaxLevel() {
            return (this.properties != null) ? this.properties.taxLevel : null;
        }
    }

    public class RefundTaxInfoProperties {
        public String taxItemId;
        public String taxLevel;
        public RefundTaxInfoProperties(String taxItemId, String taxLevel) {
            this.taxItemId = taxItemId;
            this.taxLevel = taxLevel;
        }
    }

    public virtual class NGBSRequest {
        Integer categoryId = 1;

        /* required */
        RefundApplicationMap applicationMap;

        public NGBSRequest(NGBSTransaction tr) {
            this.applicationMap = this.createApplicationMap(tr);
        }

        private RefundApplicationMap createApplicationMap(NGBSTransaction tr) {
            RefundApplicationMap result = new RefundApplicationMap();

            for (NGBSItemGroup itemGroup : tr.itemGroups) {
                if (String.isBlank(itemGroup.id)) {
                    continue;
                }
                /*
                 For tax items create list
                 for other calc total amount
                */
                Long invoiceId;
                Long groupId;
                try {
                    invoiceId = Long.valueOf(itemGroup.invoiceId);
                    groupId = Long.valueOf(itemGroup.id);
                } catch(Exception e) {
                    AquivaHelper.throwAquivaException(e);
                }

                result = setItemsForRefundApplMap(invoiceId, groupId, itemGroup.items, result);
                result = setTaxesForRefundApplMap(invoiceId, groupId, itemGroup.items, result);
            }

            return result;
        }

         private RefundApplicationMap setItemsForRefundApplMap(
            Long invoiceId,
            Long groupId,
            List<NGBSItem> items,
            RefundApplicationMap result
        ) {
            Map<Long, Decimal> itemsMap = new Map<Long, Decimal>();
            Decimal totalAmount = 0;

            for (NGBSItem item : items) {
                if (item.amount == 0) {
                    continue;
                }
                if(item.type == 'tax') {
                    continue;
                }
                totalAmount += item.amount;
            }

            if (totalAmount == 0) {
                return result;
            }

            itemsMap.put(groupId, totalAmount);
            if (result.applications.get(invoiceId) == null) {
                result.applications.put(invoiceId, new Map<Long, Decimal>());
            }
            result.applications.get(invoiceId).putAll(itemsMap);
            return result;
        }

        private RefundApplicationMap setTaxesForRefundApplMap(
            Long invoiceId,
            Long groupId,
            List<NGBSItem> items,
            RefundApplicationMap result
        ) {
            Map<Long, TaxRefund[]> taxesMap = new Map<Long, TaxRefund[]>();
            TaxRefund[] taxes = new List<TaxRefund>();

            for (NGBSItem item : items) {
                if (item.amount == 0) {
                    continue;
                }
                if(item.type != 'tax') {
                    continue;
                }
                taxes.add(new TaxRefund(item));
            }

            if (taxes.isEmpty()) {
                return result;
            }

            if (result.taxes.get(invoiceId) != null) {
                taxesMap = result.taxes.get(invoiceId);
            }

            taxesMap.put(groupId, taxes);
            result.taxes.put(invoiceId, taxesMap);
            return result;
        }

    }

    public class InvoiceRequest extends NGBSRequest {
        public InvoiceRequest(NGBSTransaction tr) {
            super(tr);
        }
    }

    public class RefundRequest extends NGBSRequest {
        RefundDestination destination;

        public RefundRequest(NGBSTransaction tr) {
            super(tr);
            this.destination = new RefundDestination(tr.paymentType);
        }
    }

    public class RefundApplicationMap {
        /* Invoice id: {ItemGroup id: Amount} */
        public Map<Long, Map<Long, Decimal>> applications = new Map<Long, Map<Long, Decimal>>();
        /* Invoice id: {ItemGroup id: [TaxRefund...]} */
        public Map<Long, Map<Long, TaxRefund[]>> taxes = new Map<Long, Map<Long, TaxRefund[]>>();
    }

    public class RefundDestination {
        /* AccountCredit, OriginalPaymentMethod */
        public String type;
        public RefundDestination() {
            this.type = 'AccountCredit';
        }
        public RefundDestination(String paymentType) {
            this.type = PAYMENT_TYPE_PURCHASE_TO_PAYMENT_TYPE_APPLY.get(paymentType);
        }
    }

    public class TaxRefund {
        public String taxItemId;
        public Decimal amount;
        public String description;

        public TaxRefund(NGBSItem item) {
            this.taxItemId   = item.id;
            this.amount      = item.amount;
            this.description = item.description;
        }
    }

    // we send only Invoice info for now, so rest of the request omitted to not include
    public class PaymentMethod {
        public String id;
        // public String accountId;
        public String nickname;
        // public Datetime addedAt;
        public InvoicePaymentMethod invoiceInfo;
        public CreditCardPaymentMethod creditCardInfo;
        public InvoiceOnBehalfPaymentMethod invoiceOnBehalfInfo;
        public InvoiceWholesalePaymentMethod invoiceWholesaleInfo;
        public boolean isDefault;
    }

    public class InvoicePaymentMethod extends AddressInfo {
        public Integer terms;

        public InvoicePaymentMethod (CreditCardPaymentMethod ccPayment) {
            super(ccPayment.address);
            setTerms();
        }

        public InvoicePaymentMethod (Account acc) {
            super(acc);
            setTerms();
        }

        public InvoicePaymentMethod (Account acc, AccountContactRole cr) {
            setTerms();

            this.address = new Address();
            this.address.firstName = cr.Contact.FirstName;
            this.address.lastName = cr.Contact.LastName;
            this.address.street1 = acc.BillingStreet;
            this.address.city = acc.BillingCity;
            this.address.state = acc.BillingState;
            this.address.zip = acc.BillingPostalCode;
            this.address.country = setCountry(acc.BillingCountry);
            this.address.phone = acc.Phone;
        }

        private void setTerms() {
            this.terms = 0;
        }

        public override Boolean isValid() {
            if (super.address == null
                    || super.address.firstName == null
                    || super.address.lastName == null
                    || super.address.street1 == null
                    || super.address.city == null
                    || !AccountTriggerHelper.isValidBillingState(super.address.state, super.address.country)
                    || super.address.zip == null
                    || super.address.country == null
                ) {
                    return false;
            }

            return true;
        }
    }

    public class CreditCardPaymentMethod extends AddressInfo {

        public CreditCardPaymentMethod() {
            super();
        }
    }

    public class InvoiceOnBehalfPaymentMethod {
        public Decimal partnerId;
        public Address address;

        public InvoiceOnBehalfPaymentMethod(Account acc, AccountContactRole cr, Decimal partnerId) {
            this.address = new Address();
            this.address.firstName = cr.Contact.FirstName;
            this.address.lastName = cr.Contact.LastName;
            this.address.street1 = acc.BillingStreet;
            this.address.city = acc.BillingCity;
            this.address.state = acc.BillingState;
            this.address.zip = acc.BillingPostalCode;
            this.address.country = setCountry(acc.BillingCountry);
            this.address.phone = acc.Phone;
            this.partnerId = partnerId;
        }

        private String setCountry(String initialCountry) {
            if (String.isBlank(initialCountry)) {
                return initialCountry;
            }
            String foundCountry = COUNTRY_MAPPING.get(initialCountry.toLowerCase());
            return String.isNotBlank(foundCountry) ? foundCountry : initialCountry;
        }

        public boolean isValid() {
            if (this.partnerId == null || this.address == null || this.address.firstName == null || this.address.lastName == null
                || this.address.street1 == null || this.address.city == null || !AccountTriggerHelper.isValidBillingState(this.address.state, this.address.country)
                || this.address.zip == null || this.address.country == null) {
                return false;
            }

            return true;
        }
    }


    public class InvoiceWholesalePaymentMethod {
        public Decimal partnerId;
        public String partnerCatalogId;
        public String applicableCatalogPackage;
        public Address address;

        public InvoiceWholesalePaymentMethod(Account acc, AccountContactRole cr, Account partner, Quote primaryQuote) {
            this.address = new Address();
            this.address.firstName = cr.Contact.FirstName;
            this.address.lastName = cr.Contact.LastName;
            this.address.street1 = acc.BillingStreet;
            this.address.city = acc.BillingCity;
            this.address.state = acc.BillingState;
            this.address.zip = acc.BillingPostalCode;
            this.address.country = setCountry(acc.BillingCountry);
            this.address.phone = acc.Phone;
            this.partnerId = partner.NGBS_Partner_ID__c;
            BillingWrappers.QuotePackageInfo quotePackage = QuoteHelper.getQuotePackage(primaryQuote);
            this.partnerCatalogId = QuoteHelper.getPartnerCatalogId(quotePackage);
            this.applicableCatalogPackage = QuoteHelper.getCatalogId(quotePackage);
        }

        private String setCountry(String initialCountry) {
            if (String.isBlank(initialCountry)) {
                return initialCountry;
            }
            String foundCountry = COUNTRY_MAPPING.get(initialCountry.toLowerCase());
            return String.isNotBlank(foundCountry) ? foundCountry : initialCountry;
        }

        public boolean isValid() {
            if (this.partnerId == null || this.address == null || this.address.firstName == null || this.address.lastName == null
                || this.address.street1 == null || this.address.city == null || !AccountTriggerHelper.isValidBillingState(this.address.state, this.address.country)
                || this.address.zip == null || this.address.country == null) {
                return false;
            }

            return true;
        }

        public boolean compareWith(InvoiceWholesalePaymentMethod anotherPaymentMethod) {
            // Note: partnerCatalogId here is in the format 'Id.Version'
            return this.partnerCatalogId == anotherPaymentMethod?.partnerCatalogId
                && this.applicableCatalogPackage == anotherPaymentMethod?.applicableCatalogPackage
                && this.partnerId == anotherPaymentMethod?.partnerId;
        }
    }

    public class Address {
        public String label;
        public String firstName;
        public String lastName;
        public String phone;
        public String street1;
        public String street2;
        public String city;
        public String county;
        public String state;
        public String zip;
        public String country;
    }

    public class PaymentMethodTypeHistory {
        public String currentType;
        public List<String> formerTypes;
    }

    public class PackageLimitOverride {
        public String code;
        public integer value;

        public PackageLimitOverride (String c, Integer i) {
            this.code = c;
            this.value = i;
        }
    }

    public class PackageLimitUpdate {
        public String packageLimitCode;
        public Integer value;
        public Integer overrideParam;

        public PackageLimitUpdate (String packageLimitCode, Integer value, integer overrideParam) {
            this.packageLimitCode = packageLimitCode;
            this.value = value;
            this.overrideParam = overrideParam;
        }
    }

    public class LBoxLimitOverride {
        public Long id;
        public List<LBoxLimitBrief> lboxLimits;

        public LBoxLimitOverride (Long id, List<LBoxLimitBrief> lboxLimits) {
            this.id = id;
            this.lboxLimits = lboxLimits;
        }
    }

    public class LBoxLimitBrief {
        public String type;
        public Integer value;

        public LBoxLimitBrief (String type, Integer value) {
            this.type = type;
            this.value = value;
        }
    }

    public class LBox {
        public Long id;
        public String description;
        public String lboxCatalogId;
        public List<LBoxLimit> lboxLimits;
        public List<LBoxItem> lboxItems;
    }

    public class LBoxLimit {
        public String type;
        public Integer value;
        public Boolean defaultLimit;

        public LBoxLimit(String type, Integer value, Boolean defaultLimit) {
            this.type = type;
            this.value = value;
            this.defaultLimit = defaultLimit;
        }
    }

    public class LBoxItem {
        public Long id;
        public String catalogId;
        public String description;

        public LBoxItem(Long id, String catalogId, String description) {
            this.id = id;
            this.catalogId = catalogId;
            this.description = description;
        }
    }

    public class TaxExemption {
        private Boolean federalTaxExemption;
        private Boolean stateTaxExemption;
        private Boolean countyTaxExemption;
        private Boolean localTaxExemption;
        private Boolean salesTaxExemption;
        private Boolean vatExemption;
        private Boolean SEZWOPExemption;
        private String vatNumber;
        private String vatCountry;
        private String gstNumber;

        public TaxExemption() {
            this(false, false, false, false, false, false, false, null, null, null);
        }

        public TaxExemption(Boolean federalTaxExemption,
                            Boolean stateTaxExemption,
                            Boolean countyTaxExemption,
                            Boolean localTaxExemption,
                            Boolean salesTaxExemption,
                            Boolean vatExemption,
                            Boolean SEZWOPExemption,
                            String vatNumber,
                            String vatCountry,
                            String gstNumber) {
            this.federalTaxExemption = federalTaxExemption;
            this.stateTaxExemption = stateTaxExemption;
            this.countyTaxExemption = countyTaxExemption;
            this.localTaxExemption = localTaxExemption;
            this.salesTaxExemption = salesTaxExemption;
            this.vatExemption = vatExemption;
            this.SEZWOPExemption = SEZWOPExemption;
            this.vatNumber = vatNumber;
            this.vatCountry = vatCountry;
            this.gstNumber = gstNumber;
        }

        public Boolean getFederalTaxExemption() {
            return this.federalTaxExemption;
        }

        public Boolean getStateTaxExemption() {
            return this.stateTaxExemption;
        }

        public Boolean getCountyTaxExemption() {
            return this.countyTaxExemption;
        }

        public Boolean getLocalTaxExemption() {
            return this.localTaxExemption;
        }

        public Boolean getSalesTaxExemption() {
            return this.salesTaxExemption;
        }

        public Boolean getVatExemption() {
            return this.vatExemption;
        }

        public Boolean getSEZWOPExemption() {
            return this.SEZWOPExemption != null ? this.SEZWOPExemption : false;
        }

        public String getVatNumber() {
            return this.vatNumber;
        }

        public String getVatCountry() {
           return this.vatCountry;
        }

        public String getGSTNumber() {
            return this.gstNumber;
        }

        public void setFederalTaxExemption(Boolean federalTaxExemption) {
            this.federalTaxExemption = federalTaxExemption;
        }

        public void setStateTaxExemption(Boolean stateTaxExemption) {
            this.stateTaxExemption = stateTaxExemption;
        }

        public void setCountyTaxExemption(Boolean countyTaxExemption) {
            this.countyTaxExemption = countyTaxExemption;
        }

        public void setLocalTaxExemption(Boolean localTaxExemption) {
            this.localTaxExemption = localTaxExemption;
        }

        public void setSalesTaxExemption(Boolean salesTaxExemption) {
            this.salesTaxExemption = salesTaxExemption;
        }

        public void setVatExemption(Boolean vatExemption) {
            this.vatExemption = vatExemption;
        }

        public void setSEZWOPExemption(Boolean SEZWOPExemption) {
            this.SEZWOPExemption = SEZWOPExemption;
        }

        public void setVatNumber(String vatNumber){
            this.vatNumber = vatNumber;
        }

        public void setVatCountry(String vatCountry){
            this.vatCountry = vatCountry;
        }

        public void setGSTNumber(String gstNumber){
            this.gstNumber = gstNumber;
        }
    }

    public abstract class AddressInfo {
        public Address address;

        public AddressInfo() {
            this.address = new Address();
        }

        public AddressInfo(Address adrInfo) {
            this.address = adrInfo;
        }

        public AddressInfo(Account acc) {
            /* There can be only one primary contact role for account */
            AccountContactRole cr = acc.AccountContactRoles[0];

            this.address = new Address();
            this.address.firstName = cr.Contact.FirstName;
            this.address.lastName = cr.Contact.LastName;
            this.address.street1 = acc.BillingStreet;
            this.address.city = acc.BillingCity;
            this.address.state = acc.BillingState;
            this.address.zip = acc.BillingPostalCode;
            this.address.country = setCountry(acc.BillingCountry);
            this.address.phone = acc.Phone;
        }

        public virtual Boolean isValid() {
            if (this.address == null
                    || this.address.lastName == null
                    || this.address.street1 == null
                    || this.address.city == null
                    || this.address.state == null
                    || this.address.country == null
                    || this.address.zip == null
                ) {
                    return false;
            }
            return true;
        }
    }

    public class BillingAddress extends AddressInfo{
        BillingAddress(Account acc) {
            super(acc);
        }
    }

    public class ExclusionAccountPackageLimits {
        public String target;
        public String targetId;

        public ExclusionAccountPackageLimits(String target, String targetId) {
            this.target = target;
            this.targetId = targetId;
        }
    }

    public class AccountPackageLimitDuration {
        public String unit;
        public Decimal value;
    }

    public class AccountPackageLimitOverride {
        public Decimal value;
        public String paymentType;
        public String startDate;
        public AccountPackageLimitDuration limitDuration;
    }

    public class AccountPackageLimitOverrideData {
        public Decimal value;
        public String paymentType;
        public String limitStartDate;
        public AccountPackageLimitDuration limitDuration;

        public AccountPackageLimitOverrideData(AccountPackageLimitOverride data) {
            this.value = data.value;
            this.paymentType = data.paymentType;
            this.limitStartDate = data.startDate;
            this.limitDuration = data.limitDuration;
        }
    }

    public class AccountPackageLimit {
        public String code;
        public Decimal value;
        public List<ExclusionAccountPackageLimits> exclusions;
        public AccountPackageLimitOverride limitOverride;
        public String paymentType;
    }

    public class UpdateAccountPackageLimitData {
        public String packageLimitCode;
        public Decimal value;
        public List<ExclusionAccountPackageLimits> exclusions;
        public AccountPackageLimitOverrideData overrideData;

        public UpdateAccountPackageLimitData(String packageLimitCode, Decimal value, List<ExclusionAccountPackageLimits> exclusions) {
            this.packageLimitCode = packageLimitCode;
            this.value = value;
            this.exclusions = exclusions;
        }
    }

    // ------------------------------------------------------------------
    // Publics
    // ------------------------------------------------------------------

    /*
    * @description: makes request to NGBS with given method
     */
    public static HttpResponse requestNGBS(String endpoint, String method) {
        return requestNGBS(endpoint, method, null);
    }

    /*
    * @description: makes request to NGBS with given method and body
     */
    public static HttpResponse requestNGBS(String endpoint, String method, String body) {
        return requestNGBS(endpoint, method, body, null);
    }

    /*
    * @description: makes request to NGBS with given method, body and Content Type
     */
    public static HttpResponse requestNGBS(String endpoint, String method, String body, String contentTypeValue) {
        return requestNGBS(endpoint, method, body, null, null);
    }

    /*
    * @description: makes request to NGBS with given method, body, Content Type and headers
     */
    public static HttpResponse requestNGBS(String endpoint, String method, String body, String contentTypeValue, String headers) {
        StringHelper.validateStrict(endpoint, UNEXPECTED_PARAMETER_EMPTY_EXCEPTION_MESSAGE + ' endpoint');
        StringHelper.validateStrict(method, UNEXPECTED_PARAMETER_EMPTY_EXCEPTION_MESSAGE + ' method');
        if (method == HttpHelper.METHOD_GET && String.isNotBlank(body)) {
            throw new HttpHelper.HttpHelperException('GET method should have no body on Http request');
        }

        String authorizationHeader = String.isNotBlank(headers) ? headers : prepareNGBSHeader();

        HttpRequest request = HttpHelper.prepareBasicAuthRequest(endpoint, method, authorizationHeader, body, contentTypeValue);
        request.setHeader('X-TokenId', HttpHelper.formXTokenId());
        request.setHeader('Referer', URL.getOrgDomainUrl().toExternalForm());
        request.setTimeout(HttpHelper.MAX_TIMEOUT_MS);
        System.debug('NGBS request endpoint: ' + endpoint + '\n' + 'NGBS request body: ' + body);
        HttpResponse response;
        try {
            response = new Http().send(request);
        } catch(Exception e) {
            if (e.getMessage().contains('Authorization token is invalid')) {
                throw new NGBSAPIException('Authorization token is invalid - make sure that credentials are correct');
            }
            throw new NGBSAPIException(e.getMessage());
        }
        if (!API_SUCCESS_CODES.contains(response.getStatusCode())) {
            throw new NGBSAPIException(
                JSON.serialize(new NGBSAPIExceptionHelper.ExceptionMessage(
                    request.getEndpoint(),
                    response.getStatus(),
                    response.getBody()
                ))
            );
        }

        return response;
    }

    public static List<BillingWrappers.BillingContract> requestContractsFromBilling(String billingId, String packageId) {
        List<BillingWrappers.BillingContract> contracts = new List<BillingWrappers.BillingContract>();
        if (String.isBlank(billingId) || String.isBlank(packageId)) {
            return contracts;
        }
        String endpoint = getContractsBillingEndpoint(billingId, packageId);
        HttpResponse response;
        try {
            response = NGBSAPI.requestNGBS(endpoint, HttpHelper.METHOD_GET);
            contracts = (List<BillingWrappers.BillingContract>)
                JSON.deserialize(response.getBody(), List<BillingWrappers.BillingContract>.class);
        } catch(NGBSAPI.NGBSAPIException ex) {
            return contracts;
        }
        return contracts;
    }

    // returns null if Account payment method is already "Invoice"(has invoiceInfo) or Response if it was updated to "Invoice"
    public static HttpResponse updateAccountPaymentMethod(
        Account acc,
        AccountContactRole primaryContactRole,
        Account partnerAcc,
        Quote primaryQuote,
        List<QuoteLineItem> qlis
    ) {
        if (String.isBlank(acc.Billing_ID__c)) {
            throw new NGBSAPIException('Biiling Id is missed on the Account');
        }
        if (primaryContactRole == null) {
            throw new NGBSAPIException('Primary Contact Role does not exist on the Account');
        }
        String paymentMethodGetEndpoint = String.format(NGBSAPI.NGBS_PAYMENT_METHOD_FORMAT, new List<String>{acc.Billing_ID__c});

        PaymentMethod currentNgbsPaymentMethod = getDefaultPaymentMethodFromBillingAccount(acc.Billing_ID__c);
        PaymentMethod currentSalesforcePaymentMethod;
        Boolean isNgbsPaymentMethodCorrect;
        String ngbsPaymentMethodId;
        if (currentNgbsPaymentMethod != null) {
            ngbsPaymentMethodId = currentNgbsPaymentMethod.id;
            currentNgbsPaymentMethod.id = null;
        }

        if (primaryQuote != null && qlis != null && !qlis.isEmpty() && QuoteHelper.isNGBSPartnerPackageChange(primaryQuote, qlis)) { // Wholesale main and change partner flow
            currentSalesforcePaymentMethod = getWholesalePaymentInfo(acc, primaryContactRole, partnerAcc, primaryQuote);
            System.debug('Salesforce payment method: ' + currentSalesforcePaymentMethod);
            System.debug('Ngbs payment method:       ' + currentNgbsPaymentMethod);
            isNgbsPaymentMethodCorrect = currentSalesforcePaymentMethod.invoiceWholesaleInfo.compareWith(
                currentNgbsPaymentMethod?.invoiceWholesaleInfo
            );
        } else if (AccountHelper.isInvoiceOnBehalfAccount(acc)) {
            currentSalesforcePaymentMethod = getInvoiceOnBehalfPaymentInfo(acc, primaryContactRole, partnerAcc);
            String salesforcePaymentMethodJson = JSON.serialize(currentSalesforcePaymentMethod);
            String ngbsPaymentMethodJson = JSON.serialize(currentNgbsPaymentMethod);
            isNgbsPaymentMethodCorrect =
                currentNgbsPaymentMethod?.invoiceOnBehalfInfo != null &&
                salesforcePaymentMethodJson == ngbsPaymentMethodJson;
            System.debug('Salesforce payment method: ' + salesforcePaymentMethodJson);
            System.debug('Ngbs payment method:       ' + ngbsPaymentMethodJson);
        } else {
            currentSalesforcePaymentMethod = convertNGBSCardPaymentToInvoice(currentNgbsPaymentMethod, acc, primaryContactRole);
            // only do callout when it is not Invoice already
            isNgbsPaymentMethodCorrect = currentNgbsPaymentMethod?.invoiceInfo != null;
        }

        Boolean needToUpdatePaymentMethod =
            currentNgbsPaymentMethod == null ||
            !isNgbsPaymentMethodCorrect;

        if(needToUpdatePaymentMethod) {
            String paymentMethodPOSTEndpoint = ngbsPaymentMethodId == null
                ? paymentMethodGetEndpoint
                : paymentMethodGetEndpoint + '/' + ngbsPaymentMethodId;
            return requestNGBS(paymentMethodPOSTEndpoint, 'POST', JSON.serialize(currentSalesforcePaymentMethod));
        }
        return null;
    }

    public static HttpResponse updateAccountPaymentContact(Account acc, Contact payableContact) {

        HttpResponse paymentContactResp = new HttpResponse();
        if (String.isBlank(acc.Billing_ID__c)) {
            throw new NGBSAPIException('Biiling Id is missed on the Acount');
        }
        String paymentContactEndpoint = String.format(
            NGBS_PAYMENT_CONTACT_FORMAT, new List<String>{acc.Billing_ID__c}
        );

        if (payableContact != null) {
            ContactInfoRequest paymentContactToPOST = new ContactInfoRequest(acc, payableContact);

            paymentContactResp
                = requestNGBS(paymentContactEndpoint, 'PUT', JSON.serialize(paymentContactToPOST));

        }
        else {
            System.debug('Error: there is none Account Payable Role on the Account');
        }
        return paymentContactResp;
    }

    public static HttpResponse updateAccountPackageLimits(Account acc, Package__c pack) {
        return updateAccountPackageLimits(acc, pack, null);
    }

    public static HttpResponse updateAccountPackageLimits(Account acc, Package__c pack, Decimal monthlyCreditLimit) {
        Integer monthlyCreditLimitAcc = acc.Monthly_Credit_Limit__c != null ? acc.Monthly_Credit_Limit__c.intvalue() : null;
        Integer monthlyCreditLimitInt = monthlyCreditLimit != null ? monthlyCreditLimit.intvalue() : monthlyCreditLimitAcc;

        if (String.isBlank(acc.Billing_ID__c)) {
            throw new NGBSAPIException('Biiling Id is missed on the Acount');
        }

        if (String.isBlank(pack.Account_Package_Id__c)) {
            throw new NGBSAPIException('No packages exists for Account');
        }

        String limitsUpdateEndpoint = String.format(
            NGBS_PACKAGE_LIMITS_UPDATE_FORMAT, new List<String>{acc.Billing_ID__c, pack.Account_Package_Id__c}
        );

        List<PackageLimitUpdate> limitToUpdate = new List<PackageLimitUpdate>{
            new PackageLimitUpdate(
                MONTHLY_AMOUNT_LIMIT,
                monthlyCreditLimitInt,
                1)
        };

        String body = JSON.serialize(limitToUpdate).replaceAll('overrideParam', 'override');

        return requestNGBS(
            limitsUpdateEndpoint, HttpHelper.METHOD_PUT, body, 'application/json'
        );
    }

    public static List<AccountPackageLimit> getAccountPackageLimits(String billingId, String packageId) {
        if (String.isBlank(billingId)) {
            throw new NGBSAPIException('Biiling Id is missed on the Acount');
        }

        if (String.isBlank(packageId)) {
            throw new NGBSAPIException('No packages exists for Account');
        }

        String limitsEndpoint = String.format(
            NGBS_PACKAGE_LIMITS_F0RMAT, new List<String>{billingId, packageId}
        );

        HttpResponse resp = requestNGBS(
            limitsEndpoint, HttpHelper.METHOD_GET
        );

        if (resp.getStatusCode() == 200) {
            return (List<AccountPackageLimit>) JSON.deserialize(resp.getBody(), List<AccountPackageLimit>.class);
        } else {
            throw new NGBSAPIException('Error: NGBSAPI error with StatusCode = ' + resp.getStatusCode());
        }
    }

    public static PaymentMethodTypeHistory getAccountPaymentType(String billingId) {
        if (String.isBlank(billingId)) {
            throw new NGBSAPIException('Biiling Id is missed on the Account');
        }

        String endpoint = String.format(
            NGBS_PAYMENT_METHOD_TYPE_FORMAT, new List<String>{billingId}
        );

        HttpResponse resp = requestNGBS(
            endpoint, HttpHelper.METHOD_GET
        );

        if (resp.getStatusCode() == 200) {
            return (PaymentMethodTypeHistory) JSON.deserialize(resp.getBody(), PaymentMethodTypeHistory.class);
        } else {
            throw new NGBSAPIException('Error: NGBSAPI error with StatusCode = ' + resp.getStatusCode());
        }
    }

    public static HttpResponse accountPackageLimitsIncrease(String billingId, String packageId, List<UpdateAccountPackageLimitData> newLimits) {
        if (String.isBlank(billingId)) {
            throw new NGBSAPIException('Biiling Id is missed on the Acount');
        }

        if (String.isBlank(packageId)) {
            throw new NGBSAPIException('No packages exists for Account');
        }

        String limitsEndpoint = String.format(
            NGBS_PACKAGE_LIMITS_UPDATE_FORMAT, new List<String>{billingId, packageId}
        );

        String body = JSON.serialize(newLimits);

        return requestNGBS(
            limitsEndpoint, HttpHelper.METHOD_PUT, body
        );
    }

    public static Transaction_History__c createTransactionHistory(
        NGBSTransaction tr,
        Response res,
        Id approvalId
    ) {

        Decimal totalAmount = 0;
        for (NGBSItemGroup itemGroup : tr.itemGroups) {
            for (NGBSItem item : itemGroup.items) {
                totalAmount += item.amount;
            }
        }

        Transaction_History__c trHistory = new Transaction_History__c(
            Approval__c = approvalId,
            Name = tr.id,
            RefundAmount__c = totalAmount,
            TransactionId__c = tr.id,
            Type__c = TRANSACTION_TYPE_NGBS,
            // Message__c = res.message,
            Status__c = res.status.toLowerCase()
        );

        if(res.isSuccess()) {
            try {
                insert trHistory;
            } catch(Exception e) {
                PlatformLog.logException('Create Transaction History', e);
            }
        }

        return trHistory;
    }

    public static List<TransactionsRefundsAPI.ProductItemDTO> recalculateMaxRefunds(
        List<TransactionsRefundsAPI.ProductItemDTO> productItems
    ) {
        return recalculateMaxRefunds(productItems, 0);
    }

    public static List<TransactionsRefundsAPI.ProductItemDTO> recalculateMaxRefunds(
        List<TransactionsRefundsAPI.ProductItemDTO> productItems,
        Decimal appliedCredit
    ) {
        Map<String, List<TransactionsRefundsAPI.ProductItemDTO>> costCentersToProducts = splitByCostCenters(productItems);
        List<TransactionsRefundsAPI.ProductItemDTO> resultItems = new List<TransactionsRefundsAPI.ProductItemDTO>();
        Decimal unspreadNegative = 0;
        for (String costCenter : costCentersToProducts.keySet()) {
            RecalculationWrapper processedByCombId =
                processProductsByFilterId(costCentersToProducts.get(costCenter), FILTER_BY.COMBINED_CATALOG_ID);
            RecalculationWrapper processedByCategoryId =
                processProductsByFilterId(processedByCombId.productItems, FILTER_BY.CATEGORY_ID);
            RecalculationWrapper processedNegatives =
                distributeNegatives(
                    processedByCategoryId.productItems,
                    processedByCombId.negativeUnassignedValue + processedByCategoryId.negativeUnassignedValue
                );
            resultItems.addAll(processedNegatives.productItems);
            unspreadNegative += processedNegatives.negativeUnassignedValue;
        }


        resultItems = distributeNegatives(
            resultItems,
            -appliedCredit + unspreadNegative
        ).productItems;
        return resultItems;
    }

    private static Map<String, List<TransactionsRefundsAPI.ProductItemDTO>> splitByCostCenters(
        List<TransactionsRefundsAPI.ProductItemDTO> products
    ) {
        Map<String, List<TransactionsRefundsAPI.ProductItemDTO>> costCentersToProducts =
            new Map<String, List<TransactionsRefundsAPI.ProductItemDTO>>();
        for (TransactionsRefundsAPI.ProductItemDTO product : products) {
            if (costCentersToProducts.get(product.billingCodeId) == null) {
                costCentersToProducts.put(product.billingCodeId, new List<TransactionsRefundsAPI.ProductItemDTO>());
            }
            costCentersToProducts.get(product.billingCodeId).add(product);
        }
        return costCentersToProducts;
    }

    public static RefundApplicationMapWrapper convertTaxResponseToWrappers(String jsonToConvert) {
        RefundApplicationMapWrapper calculatedBillRefund = new RefundApplicationMapWrapper();
        List<CalculatedRefundItemGroup> refundItemGroups = new List<CalculatedRefundItemGroup>();
        List<CalculatedRefundTaxItem> refundTaxItems = new List<CalculatedRefundTaxItem>();

        Map<String, Object> startMapping = (Map<String, Object>) JSON.deserializeUntyped(jsonToConvert);
        //Map<String, Object> refundApplicationMap = (Map<String, Object>) startMapping.get('refundApplicationMap');
        Map<String, Object> refundApplicationMap =
            (Map<String, Object>) ((startMapping.get('refundApplicationMap') != null)
                ? startMapping.get('refundApplicationMap')
                : startMapping.get('applicationMap'));
        Map<String, Object> applications = (Map<String, Object>) refundApplicationMap.get('applications');
        for (String invoiceId : applications.keySet()) {
            CalculatedRefundItemGroup refundItemGroup = new CalculatedRefundItemGroup();
            refundItemGroup.refundItems = new List<CalculatedRefundItem>();
            Map<String, Object> itemGroups = (Map<String, Object>) applications.get(invoiceId);
            for (String itemGroupId : itemGroups.keySet()) {
                CalculatedRefundItem cri = new CalculatedRefundItem();
                cri.invoiceId = invoiceId;
                cri.amount = (Decimal)itemGroups.get(itemGroupId);
                cri.itemGroupId = itemGroupId;
                refundItemGroup.refundItems.add(cri);
            }
            refundItemGroups.add(refundItemGroup);
        }

        Map<String, Object> taxes = (Map<String, Object>) refundApplicationMap.get('taxes');
        for (String invoiceId : taxes.keySet()) {
            Map<String, Object> itemGroups = (Map<String, Object>)taxes.get(invoiceId);
            for (String itemGroupId : itemGroups.keySet()) {
                List<Object> itemGroupArray = (List<Object>)itemGroups.get(itemGroupId);
                for (Object itemGroupElement : itemGroupArray) {
                    Map<String, Object> elementParamsMap = (Map<String, Object>) itemGroupElement;
                    CalculatedRefundTaxItem refundTaxItem = new CalculatedRefundTaxItem();
                    refundTaxItem.itemGroupId = itemGroupId;
                    refundTaxItem.invoiceId = invoiceId;
                    refundTaxItem.taxItemId = String.valueOf(elementParamsMap.get('taxItemId'));
                    refundTaxItem.description = (String)elementParamsMap.get('description');
                    refundTaxItem.amount = (Decimal)elementParamsMap.get('amount');
                    refundTaxItem.initialAmount = (Decimal)elementParamsMap.get('initialAmount');
                    refundTaxItems.add(refundTaxItem);
                }
            }
        }
        calculatedBillRefund.refundItemGroups = refundItemGroups;
        calculatedBillRefund.refundTaxItems = refundTaxItems;
        return calculatedBillRefund;
    }

    // ------------------------------------------------------------------
    // Private
    // ------------------------------------------------------------------

    public static PaymentMethod convertNGBSCardPaymentToInvoice(PaymentMethod cardPaymentMethod, Account acc, AccountContactRole primaryContactRole) {
        PaymentMethod paymentMethod = new PaymentMethod();
        CreditCardPaymentMethod ccPayment = cardPaymentMethod != null ? cardPaymentMethod.creditCardInfo : null;
        if (ccPayment != null) {
            paymentMethod.nickname = cardPaymentMethod.nickname;
            paymentMethod.invoiceInfo = new InvoicePaymentMethod(ccPayment);
        } else {
            paymentMethod.invoiceInfo = new InvoicePaymentMethod(acc, primaryContactRole);
        }
        if (!paymentMethod.invoiceInfo.isValid()) {
            throw new NGBSAPIException('Address information not valid for the Invoice Payment Update');
        }
        return paymentMethod;
    }

    public static PaymentMethod getInvoiceOnBehalfPaymentInfo(Account acc, AccountContactRole primaryContactRole, Account partnerAcc) {
        PaymentMethod paymentMethod = new PaymentMethod();
        paymentMethod.nickname = INVOICEONBEHALF_PAYMENTMETHOD_NICKNAME;
        paymentMethod.invoiceOnBehalfInfo = new InvoiceOnBehalfPaymentMethod(acc, primaryContactRole, partnerAcc?.NGBS_Partner_ID__c);
        if (!paymentMethod.invoiceOnBehalfInfo.isValid()) {
            throw new NGBSAPIException('Address information not valid for the Invoice On Behalf Payment Update');
        }
        return paymentMethod;
    }

    public static PaymentMethod getWholesalePaymentInfo(Account acc, AccountContactRole primaryContactRole, Account partnerAcc, Quote primaryQuote) {
        PaymentMethod paymentMethod = new PaymentMethod();
        paymentMethod.nickname = INVOICEWHOLESALE_PAYMENTMETHOD_NICKNAME;
        paymentMethod.invoiceWholesaleInfo = new InvoiceWholesalePaymentMethod(acc, primaryContactRole, partnerAcc, primaryQuote);
        if (!paymentMethod.invoiceWholesaleInfo.isValid()) {
            throw new NGBSAPIException('Address information not valid for the Invoice Wholesale Payment Update');
        }
        return paymentMethod;
    }

    /**
    * Get Payment Method from Billing Account
    * */
    public static PaymentMethod getDefaultPaymentMethodFromBillingAccount(String BillingAccountId) {
        String paymentMethodGetEndpoint = String.format(NGBSAPI.NGBS_PAYMENT_METHOD_FORMAT, new List<String>{BillingAccountId});
        PaymentMethod currentPaymentMethod;
        try {
            HttpResponse paymentMethodResp = NGBSAPI.requestNGBS(paymentMethodGetEndpoint, 'GET');
            String respBodyStr = paymentMethodResp.getBody();
            respBodyStr = respBodyStr.replaceAll('default', 'isDefault');
            List<PaymentMethod> paymentMethodRespParsed = (List<PaymentMethod>) JSON.deserialize(respBodyStr, List<PaymentMethod>.class);
            if (paymentMethodRespParsed != null && !paymentMethodRespParsed.isEmpty()) {
                for (PaymentMethod pm : paymentMethodRespParsed) {
                    if (pm.isDefault) {
                        currentPaymentMethod = pm;
                        currentPaymentMethod.isDefault = null;
                        break;
                    }
                }
            }
        } catch (Exception e) {
            currentPaymentMethod = null;
        }
        return currentPaymentMethod;
    }

    /*
    * @description: method transfers string from "2018-07-23T08:01:51.177Z[UTC]" to "2018-07-23T00:00:00".
     */
    public static String normalizeTransactionDate(String dateStr) {
        return dateStr.replace('[UTC]', '');
    }

    public static String convertToLocal(String dateUtcStr) {
        String result = dateUtcStr;

        try {
            String timeZone = getOrgTimeZone();
            Datetime dt = convertStringToDatetime(result);
            result = dt.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'', timeZone);
        } catch (Exception e) {
            AquivaHelper.throwAuraException('Convert to local date failed');
        }

        return result;
    }

    public static String convertLocalDateToUTC(Date d, String format) {
        String result = '';

        try {
            Time t = Time.newInstance(0, 0, 0, 0);

            Datetime dt = Datetime.newInstanceGMT(d, t);

            String orgTimeZone = getOrgTimeZone();
            Timezone tz = Timezone.getTimeZone(orgTimeZone);
            Integer offset = -tz.getOffset(dt) / 1000;

            dt = dt.addSeconds(offset);

            result = dt.formatGMT(format);
        } catch(Exception e) {
            AquivaHelper.throwAuraException('Convert to utc date failed');
        }

        return result;
    }

    public static Datetime convertStringToDatetime(String dataStr) {
        /* need for correct deserializing */
        String result =  '"'+dataStr+'"';
        Datetime dt = (DateTime) JSON.deserialize(result, DateTime.class);

        return dt;
    }

    public static String getOrgTimeZone() {
        Organization org = [select TimeZoneSidKey from Organization];
        return org.TimeZoneSidKey;
    }

    public static String setCountry(String initialCountry) {
        if (String.isBlank(initialCountry)) {
            return initialCountry;
        }
        String foundCountry = COUNTRY_MAPPING.get(initialCountry.toLowerCase());
        return String.isNotBlank(foundCountry) ? foundCountry : initialCountry;
    }

    /*
    * @description: for bills, refundApplicationMap is retrieved by "refundApplicationMap" word. For invoices by
    * "applicationMap" word.
     */
    @TestVisible
    private static Map<String, Object> getRefundApplicationMap(Map<String, Object> jsonMapping) {
        Map<String, Object> refundApplicationMap = (Map<String, Object>) jsonMapping.get('refundApplicationMap');
        if (refundApplicationMap == null) {
            refundApplicationMap = (Map<String, Object>) jsonMapping.get('applicationMap');
        }
        if (refundApplicationMap == null) {
            AquivaHelper.throwAuraException('unexpected JSON received, cannot parse refunds map.');
        }
        return refundApplicationMap;
    }

    private static String prepareNGBSHeader() {
        String username = settings.Login;
        String password = settings.Password;
        if (String.isBlank(username) || String.isBlank(password)) {
            throw new NGBSAPIException('Credentials for billing are not set. Please set Login__c and Password__c');
        }

        return HttpHelper.prepareBasicAuthHeader(username, password);
    }

    private static RecalculationWrapper processProductsByFilterId(
        List<TransactionsRefundsAPI.ProductItemDTO> products,
        FILTER_BY filter
    ) {
        Map<String, List<TransactionsRefundsAPI.ProductItemDTO>> filteredIdToItems =
            prepareProductsByFilter(products, null, filter);
        Map<String, Decimal> filterIdToSumOfPositive = getFilterIdToSumOfPositive(filteredIdToItems, filter);
        Map<String, Decimal> filterIdToSumOfNegative = getFilterIdToSumOfNegative(filteredIdToItems, filter);
        return calculateByFilterId(
            filteredIdToItems, filterIdToSumOfPositive, filterIdToSumOfNegative, filter
        );
    }

    private static Map<String, Decimal> getFilterIdToSumOfPositive(
        Map<String, List<TransactionsRefundsAPI.ProductItemDTO>> filteredIdToProducts,
        FILTER_BY filter
    ) {
        Map<String, Decimal> filterIdToSumOfPositive = new Map<String, Decimal>();
        for (String filterId : filteredIdToProducts.keySet()) {
            if (filterId == TO_SKIP_PROCESSING) {
                continue;
            }
            for (TransactionsRefundsAPI.ProductItemDTO pi : filteredIdToProducts.get(filterId)) {
                TransactionsRefundsAPI.ItemsDTO item = pi.items[0];
                if (filterIdToSumOfPositive.get(filterId) == null) {
                    filterIdToSumOfPositive.put(filterId, 0);
                }

                if (item.transactionAmount > 0 ) {
                    Decimal currentPositive = filterIdToSumOfPositive.get(filterId);
                    filterIdToSumOfPositive.put(filterId, item.maxRefundAmount + currentPositive);
                }
            }
        }
        return filterIdToSumOfPositive;
    }

    private static Map<String, Decimal> getFilterIdToSumOfNegative(
        Map<String, List<TransactionsRefundsAPI.ProductItemDTO>> filteredIdToProducts,
        FILTER_BY filter
    ) {
        Map<String, Decimal> filterIdToSumOfNegative = new Map<String, Decimal>();
        for (String filterId : filteredIdToProducts.keySet()) {
            if (filterId == TO_SKIP_PROCESSING) {
                continue;
            }
            for (TransactionsRefundsAPI.ProductItemDTO pi : filteredIdToProducts.get(filterId)) {
                TransactionsRefundsAPI.ItemsDTO item = pi.items[0];
                if (filterIdToSumOfNegative.get(filterId) == null) {
                    filterIdToSumOfNegative.put(filterId, 0);
                }

                if (item.transactionAmount < 0) {
                    Decimal currentNegative = filterIdToSumOfNegative.get(filterId);
                    filterIdToSumOfNegative.put(filterId, item.transactionAmount + currentNegative);
                }
            }
        }
        return filterIdToSumOfNegative;
    }

    private static RecalculationWrapper calculateByFilterId(
        Map<String, List<TransactionsRefundsAPI.ProductItemDTO>> filteredIdToProducts,
        Map<String, Decimal> filterIdToSumOfPositive,
        Map<String, Decimal> filterIdToSumOfNegative,
        FILTER_BY filter
    ) {
        List<TransactionsRefundsAPI.ProductItemDTO> processedProducts = new List<TransactionsRefundsAPI.ProductItemDTO>();
        Decimal sumOfUnassignedNegative = 0;
        for (String filterId : filteredIdToProducts.keySet()) {
            List<TransactionsRefundsAPI.ProductItemDTO> productsForCombinedId = filteredIdToProducts.get(filterId);
            if (filterId == TO_SKIP_PROCESSING) {
                processedProducts.addAll(productsForCombinedId);
                continue;
            }
            Decimal sumOfPositive = filterIdToSumOfPositive.get(filterId);
            Decimal sumOfNegative = filterIdToSumOfNegative.get(filterId);
            RecalculationWrapper recalculatedLicense = recalculateMaxRefundsForLicense(
                productsForCombinedId,
                sumOfPositive,
                sumOfNegative
            );
            sumOfUnassignedNegative += recalculatedLicense.negativeUnassignedValue;
            processedProducts.addAll(recalculatedLicense.productItems);
        }
        RecalculationWrapper wrapperToReturn = new RecalculationWrapper(sumOfUnassignedNegative, processedProducts);
        return wrapperToReturn;
    }

    @TestVisible
    private static RecalculationWrapper recalculateMaxRefundsForLicense(
        List<TransactionsRefundsAPI.ProductItemDTO> products,
        Decimal sumOfPositive,
        Decimal sumOfNegative
    ) {
        Decimal difference = sumOfPositive + sumOfNegative;
        Decimal sumOfRefunded = 0;
        RecalculationWrapper wrap = new RecalculationWrapper(0, new List<TransactionsRefundsAPI.ProductItemDTO>());
        List<TransactionsRefundsAPI.ProductItemDTO> productsNegative = new List<TransactionsRefundsAPI.ProductItemDTO>();
        List<TransactionsRefundsAPI.ProductItemDTO> productsWithoutNegative = new List<TransactionsRefundsAPI.ProductItemDTO>();
        for (TransactionsRefundsAPI.ProductItemDTO pi : products) {
            if (pi.items[0].transactionAmount > 0) {
                productsNegative.add(pi);
            } else {
                productsWithoutNegative.add(pi);
            }
        }
        if (productsNegative.isEmpty()) {
            for (TransactionsRefundsAPI.ProductItemDTO pi : productsWithoutNegative) {
                wrap.productItems.add(pi);
            }
            return wrap;
        }
        if (difference <= 0) {
            for (TransactionsRefundsAPI.ProductItemDTO pi : productsNegative) {
                pi.items[0].maxRefundAmount = 0;
                wrap.productItems.add(pi);
            }
            wrap.negativeUnassignedValue += difference;
        } else {
            //round all items except of last
            for (Integer i = 0; i < productsNegative.size() - 1; i ++ ) {
                TransactionsRefundsAPI.ProductItemDTO pi = productsNegative[i];
                TransactionsRefundsAPI.ItemsDTO item = pi.items[0];
                wrap.productItems.add(pi);

                Decimal currentMaxRefund = (item.maxRefundAmount != null) ? item.maxRefundAmount : 0;
                Decimal updatedMaxRefund = currentMaxRefund + currentMaxRefund/sumOfPositive*sumOfNegative;
                item.maxRefundAmount = (updatedMaxRefund < 0) ? 0 : updatedMaxRefund;
                sumOfRefunded += updatedMaxRefund;
            }
            TransactionsRefundsAPI.ProductItemDTO lastPI = productsNegative[productsNegative.size() - 1];
            TransactionsRefundsAPI.ItemsDTO itemOfLastPI = lastPI.items[0];
            wrap.productItems.add(lastPI);
            if (itemOfLastPI.transactionAmount >= 0) {
                Decimal updatedMaxRefund = sumOfPositive + sumOfNegative - sumOfRefunded;
                itemOfLastPI.maxRefundAmount = updatedMaxRefund;
            }

        }
        return wrap;
    }

    private static Map<String, List<TransactionsRefundsAPI.ProductItemDTO>> prepareProductsByFilter(
        List<TransactionsRefundsAPI.ProductItemDTO> products,
        List<TransactionsRefundsAPI.ProductItemDTO> unprocessedItems,
        FILTER_BY filter
    ) {
        Map<String, List<TransactionsRefundsAPI.ProductItemDTO>> filteredIdsToProducts =
            new Map<String, List<TransactionsRefundsAPI.ProductItemDTO>>();
        filteredIdsToProducts.put(TO_SKIP_PROCESSING, new List<TransactionsRefundsAPI.ProductItemDTO>());
        if (unprocessedItems == null) {
            unprocessedItems = new List<TransactionsRefundsAPI.ProductItemDTO>();
        }
        for (TransactionsRefundsAPI.ProductItemDTO pi : products) {
            TransactionsRefundsAPI.ItemsDTO item = pi.items[0];

            String filterId = getFilterId(item, filter);
            if (filterId == null) {
                filteredIdsToProducts.get(TO_SKIP_PROCESSING).add(pi);
                continue;
            }
            if (filteredIdsToProducts.get(filterId) == null) {
                filteredIdsToProducts.put(filterId, new List<TransactionsRefundsAPI.ProductItemDTO>());
            }
            filteredIdsToProducts.get(filterId).add(pi);
        }
        return filteredIdsToProducts;
    }

    private static RecalculationWrapper distributeNegatives(
        List<TransactionsRefundsAPI.ProductItemDTO> products,
        Decimal sumOfNegative
    ) {
        if (sumOfNegative >= 0) {
            return new RecalculationWrapper(0, products);
        }
        List<TransactionsRefundsAPI.ProductItemDTO> productsWithoutNegative = new List<TransactionsRefundsAPI.ProductItemDTO>();
        List<TransactionsRefundsAPI.ProductItemDTO> productsToReturn = new List<TransactionsRefundsAPI.ProductItemDTO>();
        for (TransactionsRefundsAPI.ProductItemDTO pi : products) {
            if (pi.items[0].transactionAmount <= 0) {
                productsToReturn.add(pi);
            } else {
                productsWithoutNegative.add(pi);
            }
        }
        Decimal sumOfPositive = 0;
        Decimal sumOfDistributed = 0;
        for (TransactionsRefundsAPI.ProductItemDTO pi: productsWithoutNegative) {
            TransactionsRefundsAPI.ItemsDTO item = pi.items[0];
            if (item.transactionAmount <= 0) {
                continue;
            }
            sumOfPositive += item.maxRefundAmount;
        }
        //TODO rewrite
        Decimal difference = sumOfPositive + sumOfNegative;
        if (difference <= 0) {
            for (TransactionsRefundsAPI.ProductItemDTO pi : productsWithoutNegative) {
                pi.items[0].maxRefundAmount = 0;
                productsToReturn.add(pi);
            }
        } else if (productsWithoutNegative.size() != 0) {
            for (Integer i = 0; i < productsWithoutNegative.size() - 1; i++) {
                TransactionsRefundsAPI.ProductItemDTO pi = productsWithoutNegative[i];
                TransactionsRefundsAPI.ItemsDTO item = pi.items[0];
                Decimal currentMaxRefund = (item.maxRefundAmount != null) ? item.maxRefundAmount : 0;
                Decimal updatedMaxRefund = currentMaxRefund + currentMaxRefund / sumOfPositive * sumOfNegative;
                item.maxRefundAmount = updatedMaxRefund;
                sumOfDistributed += currentMaxRefund - updatedMaxRefund;
                productsToReturn.add(pi);
            }
            TransactionsRefundsAPI.ProductItemDTO piwLast = productsWithoutNegative[productsWithoutNegative.size() - 1];
            TransactionsRefundsAPI.ItemsDTO itemLast = piwLast.items[0];
            if (itemLast.maxRefundAmount > 0) {
                Decimal updatedMaxRefund = itemLast.maxRefundAmount + sumOfNegative + sumOfDistributed;
                itemLast.maxRefundAmount = updatedMaxRefund;
            }
            productsToReturn.add(piwLast);
        }
        Decimal unspreadNegative = difference <= 0 ? difference : 0;
        return new RecalculationWrapper(unspreadNegative, productsToReturn);
    }


    private static String getFilterId(TransactionsRefundsAPI.ItemsDTO item, FILTER_BY filter) {
        String filterId;
        if (filter == FILTER_BY.COMBINED_CATALOG_ID) {
            filterId = item.combinedCatalogId;
        } else if (filter == FILTER_BY.CATEGORY_ID) {
            filterId = item.categoryId;
        } else {
            throw new NGBSAPIException(UNEXPECTED_FILTER_BY_PARAMETER);
        }
        return filterId;
    }

    public static String getPackageExpirationInfo(String catalogId, String catalogVersion) {
        BillingWrappers.NGBSPackage pkg = getPackage(catalogId,catalogVersion);
        return extractExpirationInfo(pkg);
    }

    public static BillingWrappers.NGBSPackage getPackage(String catalogId, String catalogVersion) {
        BillingWrappers.NGBSPackage bPackage;
        if(String.isBlank(catalogId) && String.isBlank(catalogVersion)) {
            throw new AquivaHelper.AquivaException(UNEXPECTED_PARAMETER_EMPTY_EXCEPTION_MESSAGE + 'catalogId, catalogVersion.');
        }

        String packagesUrl = NGBS_PACKAGES + '/' + catalogId + '/' + catalogVersion + '/summary?withlboxes=false';

        String requestBody = NGBSAPI.requestNGBS(packagesUrl, HttpHelper.METHOD_GET).getBody();

        try{
            bPackage = (BillingWrappers.NGBSPackage) JSON.deserialize(requestBody, BillingWrappers.NGBSPackage.class);
        }catch(Exception ex) {
            throw new AquivaHelper.AquivaException('Error during JSON deserialization: ' + ex.getMessage());
        }

        return bPackage;
    }

    public static List<BillingWrappers.NGBSPackage> getSearchPackages(BillingWrappers.SearchPackagesParams params) {
        HttpResponse response;
        List<BillingWrappers.NGBSPackage> bPackages;

        String packagesUrl = NGBS_PACKAGES + '/search';
        String packagesBody = JSON.serialize(params);

        response = requestNGBS(packagesUrl, HttpHelper.METHOD_POST, packagesBody, HTTPHelper.CONTENT_TYPE_APPLICATION_JSON);
        system.debug(response.getBody());

        try{
            bPackages = (List<BillingWrappers.NGBSPackage>) JSON.deserialize(response.getBody(), List<BillingWrappers.NGBSPackage>.class);
        }catch(Exception ex) {
            throw new AquivaHelper.AquivaException('Error during JSON deserialization: ' + ex.getMessage());
        }

        return bPackages;
    }

    @TestVisible
    public static String extractExpirationInfo(BillingWrappers.NGBSPackage pkg) {
        Boolean isLabelsInfoExist = pkg != null && pkg.labels != null;
        if(!isLabelsInfoExist) {
            throw new AquivaHelper.AquivaException(NOT_FOUND_LABELS_JSON_PROPERTY_EXCEPTION_MESSAGE);
        }
        return pkg.labels.upgradeWizardExpiration?.get(0);
    }


    @TestVisible
    private static String getContractsBillingEndpoint(String billingId, String packageId) {
        if (String.isBlank(settings.BaseEndpoint) && String.isBlank(settings.AccountManagerPath)) {
            throw new AquivaHelper.AquivaException('Endpoint for Billing in NGBS_Settings__c is not set');
        }

        return settings.BaseEndpoint + settings.AccountManagerPath + '/account/' + billingId + '/contract';
    }

    public static String getBillingInfoSummary(String accountId, String packageId) {
        if (String.isBlank(accountId) || String.isBlank(packageId)) {
            AquivaHelper.throwAquivaException(BILLING_ID_AND_PACKAGE_ID_EMPTY_EXCEPTION_MESSAGE);
        }

        String responseBody;
        try {
            responseBody = NGBSAPI.requestNGBS(
                String.format(
                    NGBS_BILLING_INFO_SUMMARY,
                    new List<String> {accountId, packageId}
                ),
                HttpHelper.METHOD_GET
            ).getBody();
        } catch (Exception ex) {
            AquivaHelper.throwAquivaException(REQUEST_BILLING_INFO_SUMMARY_NGBS_EXCEPTION_MESSAGE);
        }

        return responseBody;
    }

    public static Decimal getFreeServiceCreditValue(String accountId, String packageId) {
        final String amountKey = 'amount';
        Decimal result = 0;

        try {
            HttpResponse response = NGBSAPI.requestNGBS(
                String.format(
                    NGBS_PACKAGE_FSC,
                    new List<String> {accountId, packageId}
                ),
                HttpHelper.METHOD_GET
            );

            String responseBody = response.getBody();

            if (String.isBlank(responseBody)
                && response.getStatus().equalsIgnoreCase(HttpHelper.STATUS_NAME_NO_CONTENT)
                && response.getStatusCode() == HttpHelper.STATUS_CODE_NO_CONTENT
            ) {
                return result;
            }

            Map<String, Object> deserializedInfo = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

            if (!deserializedInfo.isEmpty() && deserializedInfo.containsKey(amountKey)) {
                result = (Decimal) deserializedInfo.get(amountKey);
            }
        } catch (Exception ex) {
            AquivaHelper.throwAquivaException(REQUEST_FSC_EXCEPTION_MESSAGE, ex);
        }
        return result;
    }

    public static void updateFreeServiceCredit(String accountId, String packageId, Decimal newAmount) {
        try {
            String jsonBody = JSON.serialize(new Map<String, Decimal>{'newAmount' => newAmount});
            NGBSAPI.requestNGBS(
                String.format(NGBS_PACKAGE_FSC, new List<String>{ accountId, packageId }),
                HttpHelper.METHOD_PUT,
                jsonBody
            )
            .getBody();
        } catch (Exception ex) {
            AquivaHelper.throwAquivaException(UPDATE_FSC_EXCEPTION_MESSAGE);
        }
    }

    public static BillingWrappers.NGBSAccount getNGBSAccount(String accountId) {
        if (accountId == null) {
            return null;
        }
        BillingWrappers.NGBSAccount acc;
        try {
            acc = (BillingWrappers.NGBSAccount) JSON.deserialize(getNGBSAccountSummary(accountId), BillingWrappers.NGBSAccount.class);
        } catch (Exception e) {
            AquivaHelper.throwAquivaException(
                'Unexpected error occurred while retrieving account from NGBS.' +
                ' Please contact administrator', e.getCause());
        }
        return acc;
    }

    public static String getNGBSAccountSummary(String accountId) {
        HttpResponse res;
        try {
            res = getAccountSummary(accountId);
        } catch (Exception ex) {
            AquivaHelper.throwAquivaException('An error occurred while receiving the entitlements. ('
                + ex.getMessage() + ')', ex);
        }
        return res.getBody();
    }

    public static String getNGBSAccountSummaryWithLicenses(String accountId) {
        HttpResponse res;
        try {
            String endpoint = String.format(
                NGBS_ACCOUNT_SUMMARY,
                new List<String> {accountId}
            );
            res = NGBSAPI.requestNGBS(endpoint, HttpHelper.METHOD_GET);
        } catch (Exception ex) {
            AquivaHelper.throwAquivaException('An error occurred while receiving the entitlements. ('
                + ex.getMessage() + ')', ex);
        }
        return res.getBody();
    }

    public static List<BillingWrappers.BillingInfoSummaryLicense> getNGBSBillingInfoSummaryLicenses(
        String accountId,
        String packageId
    ) {
        return getNGBSBillingInfoSummaryLicenses(accountId, packageId, true);
    }

    public static List<BillingWrappers.BillingInfoSummaryLicense> getNGBSBillingInfoSummaryLicenses(
        String accountId,
        String packageId,
        Boolean mergeDiscountsParam
    ) {
        if (String.isBlank(accountId) || String.isBlank(packageId)) {
            AquivaHelper.throwAquivaException(BILLING_ID_AND_PACKAGE_ID_EMPTY_EXCEPTION_MESSAGE);
        }
        List<BillingWrappers.BillingInfoSummaryLicense> licenses;
        try {
            licenses = (List<BillingWrappers.BillingInfoSummaryLicense>) JSON.deserialize(
                getNGBSBillingInfoSummaryLicensesString(accountId, packageId, mergeDiscountsParam),
                List<BillingWrappers.BillingInfoSummaryLicense>.class
            );
        } catch (Exception e) {
            AquivaHelper.throwAquivaException(
                'Unexpected error occurred while retrieving billing info from NGBS.' +
                ' Please contact administrator');
        }
        return licenses;
    }

    public static String getNGBSBillingInfoSummaryLicensesString(
        String accountId,
        String packageId,
        Boolean mergeDiscountsParam
    ) {
        if (String.isBlank(accountId) || String.isBlank(packageId)) {
            AquivaHelper.throwAquivaException(BILLING_ID_AND_PACKAGE_ID_EMPTY_EXCEPTION_MESSAGE);
        }
        HttpResponse res;
        try {
            String endpoint = String.format(
                NGBS_BILLING_INFO_SUMMARY_LICENSE,
                new List<String>{ accountId, packageId }
            );
            // mergeDiscountsParam is true by default in NGBS
            if (mergeDiscountsParam != null && !mergeDiscountsParam) {
                endpoint += '?mergeDiscounts=false';
            }
            res = NGBSAPI.requestNGBS(endpoint, 'GET');
        } catch (Exception ex) {
            AquivaHelper.throwAquivaException('An error occurred while receiving the entitlements. (' + ex.getMessage() + ')');
        }
        return res.getBody();
    }

    // POST-capable variant: if requestBody is present, uses POST; otherwise falls back to GET with mergeDiscountsParam
    public static List<BillingWrappers.BillingInfoSummaryLicense> getNGBSBillingInfoSummaryLicenses(
        String accountId,
        String packageId,
        Boolean mergeDiscountsParam,
        String requestBody
    ) {
        if (String.isBlank(accountId) || String.isBlank(packageId)) {
            AquivaHelper.throwAquivaException(BILLING_ID_AND_PACKAGE_ID_EMPTY_EXCEPTION_MESSAGE);
        }

        String responseBody;
        if (!String.isBlank(requestBody)) {
            try {
                String endpoint = String.format(
                    NGBS_BILLING_INFO_SUMMARY_LICENSE,
                    new List<String>{ accountId, packageId }
                );
                HttpResponse res = NGBSAPI.requestNGBS(endpoint, HttpHelper.METHOD_POST, requestBody);
                responseBody = res.getBody();
            } catch (Exception ex) {
                AquivaHelper.throwAquivaException('An error occurred while receiving the entitlements. (' + ex.getMessage() + ')');
                return new List<BillingWrappers.BillingInfoSummaryLicense>();
            }
        } else {
            responseBody = getNGBSBillingInfoSummaryLicensesString(accountId, packageId, mergeDiscountsParam);
        }

        try {
            return (List<BillingWrappers.BillingInfoSummaryLicense>) JSON.deserialize(
                responseBody,
                List<BillingWrappers.BillingInfoSummaryLicense>.class
            );
        } catch (Exception e) {
            AquivaHelper.throwAquivaException(
                'Unexpected error occurred while retrieving billing info from NGBS.' +
                ' Please contact administrator'
            );
        }
        return new List<BillingWrappers.BillingInfoSummaryLicense>();
    }

    public static List<BillingWrappers.NGBSLicense> getNGBSAccountLicenseInfoCategories(String accountId, String packageId, List<String> categories) {
        if (String.isBlank(accountId) || String.isBlank(packageId)) {
            AquivaHelper.throwAquivaException(BILLING_ID_AND_PACKAGE_ID_EMPTY_EXCEPTION_MESSAGE);
        }
        HttpResponse res;
        try {
            String endpoint = String.format(
                NGBS_ACCOUNT_LICENSE_INFO_CATEGORIES,
                new List<String>{accountId, packageId}
            );
            res = NGBSAPI.requestNGBS(
                endpoint,
                HttpHelper.METHOD_POST,
                JSON.serialize(categories)
            );
        } catch (Exception ex) {
            AquivaHelper.throwAquivaException('An error occurred while receiving the account license info categories. (' + ex.getMessage() + ')');
        }

        return (List<BillingWrappers.NGBSLicense>) JSON.deserialize(res.getBody(), List<BillingWrappers.NGBSLicense>.class);
    }

    public static Response getLicenseCounters(String billingId, String packageId, BillingWrappers.LicensesRequestBody[] licensesRequestBody) {
        HttpResponse response;
        Response res = new Response();
        List<BillingWrappers.LicensesCounterResponse> licensesCounter = new List<BillingWrappers.LicensesCounterResponse>();
        String urlLicensesCounter = NGBS_ACCOUNT_MANAGER + '/' + billingId +'/package/'+ packageId+'/billinginfo/licenses/counters';
        String lisensesBody = JSON.serialize(licensesRequestBody);
        response = requestNGBS(urlLicensesCounter, HttpHelper.METHOD_POST, lisensesBody,
            HTTPHelper.CONTENT_TYPE_APPLICATION_JSON);
        if (response.getStatusCode() != 200) {
            res.info('An error occurred during request batch licenses');
        } else {
            licensesCounter = (List<BillingWrappers.LicensesCounterResponse>) JSON.deserialize(response.getBody(), List<BillingWrappers.LicensesCounterResponse>.class);
            res.setData('licenseCounter', licensesCounter);
        }
        return res;
    }

    public static Response createNGBSContract(String accountId, Object params) {
        if (String.isBlank(accountId)) {
            AquivaHelper.throwAquivaException('Account ID is required for creating contract');
        }
        Response res = new Response();
        try {
            String endpoint = String.format(NGBS_CONTRACT_MPUB, new List<String>{accountId});
            HttpResponse response = NGBSAPI.requestNGBS(endpoint, HttpHelper.METHOD_POST, JSON.serialize(params));

            if (HttpHelper.isSuccess(response)) {
                res.setData('body', response.getBody());
            } else {
                res.error('An error occurred while creating the contract.');
            }
        } catch (Exception ex) {
            AquivaHelper.throwAquivaException('An error occurred while creating the contract. (' + ex.getMessage() + ')');
        }

        return res;
    }

    public class NBGSPackageParameters {
        public Integer id;
        public String name;
        public Integer value;
    }

    public static Response getPackageParams(String accountId, String packageId) {
        if (String.isBlank(accountId) || String.isBlank(packageId)) {
            AquivaHelper.throwAquivaException(BILLING_ID_AND_PACKAGE_ID_EMPTY_EXCEPTION_MESSAGE);
        }
        Response res = new Response();
        try {
            String endpoint = String.format(NGBS_PACKAGE_PARAMETERS, new List<String>{accountId, packageId});
            HttpResponse response = NGBSAPI.requestNGBS(endpoint, HttpHelper.METHOD_GET);

            if (HttpHelper.isSuccess(response)) {
                res.setData('body', response.getBody());
            } else {
                res.error('Failed to get package parameters.');
            }
        } catch (Exception ex) {
            AquivaHelper.throwAquivaException('Failed to get package parameters. (' + ex.getMessage() + ')');
        }

        return res;
    }

    public static Response updatePackageParams(String accountId, String packageId, NBGSPackageParameters[] params) {
        if (String.isBlank(accountId) || String.isBlank(packageId)) {
            AquivaHelper.throwAquivaException(BILLING_ID_AND_PACKAGE_ID_EMPTY_EXCEPTION_MESSAGE);
        }
        Response res = new Response();
        try {
            String endpoint = String.format(NGBS_PACKAGE_PARAMETERS, new List<String>{accountId, packageId});
            HttpResponse response = NGBSAPI.requestNGBS(endpoint, HttpHelper.METHOD_PUT, JSON.serialize(params));

            if (HttpHelper.isSuccess(response)) {
                res.setData('body', response.getBody());
            } else {
                res.error('Failed to update package parameters.');
            }
        } catch (Exception ex) {
            AquivaHelper.throwAquivaException('Failed to update package parameters. (' + ex.getMessage() + ')');
        }

        return res;
    }

    public static BillingWrappers.BillingInfoLicenses getAllLicenses(String billingId, String packageId, String catalogId) {
        String urlLicenses = NGBS_ACCOUNT_MANAGER + '/' + billingId +'/package/'+ packageId +'/billinginfo/?filterCatalogId=' + catalogId;
        String allLicenses = requestNGBS(urlLicenses, HttpHelper.METHOD_GET).getBody();
        Map<String, Object> deserializedData = (Map<String, Object>) JSON.deserializeUntyped(allLicenses);
        BillingWrappers.BillingInfoLicenses bInfo = new BillingWrappers.BillingInfoLicenses(deserializedData);
        return bInfo;
    }

    public static Map<String,BillingWrappers.NGBSShippingLicense> getShippingLicenses(String catalogId, String version) {
        String urlLicenses = NGBS_PACKAGES + '/' + catalogId +'/'+ version +'/licenses?path=SHP=0:SHIP=0:SHIPT=1';
        Map<String,BillingWrappers.NGBSShippingLicense> shippingLicenseMap = new Map<String,BillingWrappers.NGBSShippingLicense>();
        try {
            HttpResponse response = requestNGBS(urlLicenses, HttpHelper.METHOD_GET);
            List<BillingWrappers.NGBSShippingLicense> shippingLicenses = (List<BillingWrappers.NGBSShippingLicense>)
                    JSON.deserialize(response.getBody(), List<BillingWrappers.NGBSShippingLicense>.class);
            for (BillingWrappers.NGBSShippingLicense shippingLicense : shippingLicenses) {
                shippingLicenseMap.put(shippingLicense.elementID, shippingLicense);
            }
        } catch (Exception ex) {
            AquivaHelper.throwAquivaException('Failed to get Shipping licences. (' + ex.getMessage() + ')');
        }

        return shippingLicenseMap;
    }

    public static String getIntendedPaymentMethod(String billingAccountId) {

        if (String.isBlank(billingAccountId)) {
            throw new NGBSAPIException('BillingId is required for getting intended payment method from NGBS');
        }

        String billingAccountFieldsEndpoint = String.format(
            NGBSAPI.NGBS_ACCOUNT_FIELDS_FORMAT,
            new List<String>{billingAccountId}
        );

        String intendedPaymentMethod;
        try {
            HttpResponse billingAccountFieldsResp = NGBSAPI.requestNGBS(billingAccountFieldsEndpoint, 'GET');
            String respBodyStr = billingAccountFieldsResp.getBody();
            Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(respBodyStr);
            intendedPaymentMethod = (String) result.get('intendedPaymentMethod');

        } catch (Exception ex) {
            throw new NGBSAPIException('Error occurred during getting intended payment method from NGBS', ex);
        }
        return intendedPaymentMethod;
    }

    public static Boolean setIntendedPaymentMethod(String billingAccountId, String intendedPaymentMethod) {

        if (String.isBlank(billingAccountId)) {
            throw new NGBSAPIException('BillingId is required for set intended payment method');
        }

        final List<String> availablePaymentMethods = new List<String>{
            QuoteHelper.PAYMENT_METHOD_CREDIT_CARD,
            QuoteHelper.PAYMENT_METHOD_DIRECT_DEBIT
        };

        if (!availablePaymentMethods.contains(intendedPaymentMethod)) {
            throw new NGBSAPIException('Intended payment method "' + intendedPaymentMethod + '" is not available');
        }

        Boolean result = false;

        String billingAccountFieldsEndpoint = String.format(
            NGBSAPI.NGBS_ACCOUNT_FIELDS_FORMAT,
            new List<String>{billingAccountId}
        );

        try {
            String jsonBody = JSON.serialize(new Map<String, String>{'intendedPaymentMethod' => intendedPaymentMethod});

            HttpResponse resp = NGBSAPI.requestNGBS(
                billingAccountFieldsEndpoint,
                HttpHelper.METHOD_PUT,
                jsonBody
            );

            result = HttpHelper.isSuccess(resp);

        } catch (Exception ex) {
            throw new NGBSAPIException('Error occurred during updating intended payment method in NGBS', ex);
        }

        return result;
    }

    public static Boolean updatePaymentLimits(String billingAccountId, String packageId, Decimal limitValue) {

        if (String.isBlank(billingAccountId)) {
            throw new NGBSAPIException('BillingId is required for update payment limits');
        }

        if (String.isBlank(packageId)) {
            throw new NGBSAPIException('PackageId is required for update payment limits');
        }

        Boolean result = false;

        try {

            String updateLimitsEndpoint = String.format(
                NGBS_PACKAGE_LIMITS_UPDATE_FORMAT, new List<String>{billingAccountId, packageId}
            );

            List<PackageLimitUpdate> limitToUpdate = new List<PackageLimitUpdate>{
                new PackageLimitUpdate(
                    MONTHLY_AMOUNT_LIMIT,
                    limitValue != null ? limitValue.intvalue() : null,
                    1
                )
            };

            String body = JSON.serialize(limitToUpdate);

            HttpResponse resp = requestNGBS(
                updateLimitsEndpoint, HttpHelper.METHOD_PUT, body
            );

            result = HttpHelper.isSuccess(resp);

        } catch (Exception ex) {
            throw new NGBSAPIException('Error occurred during updating intended payment limit in NGBS', ex);
        }

        return result;
    }

    class PaymentMethodInfo {
        public String id;
        public Boolean isDefault;
        public DirectDebitInfo directDebitInfo;
        public InvoiceInfo invoiceInfo;
        public CreditCardInfo creditCardInfo;
        public InvoiceOnBehalfInfo invoiceOnBehalfInfo;
    }

    class DirectDebitInfo {
        public String token;
        public String countryCode;
        public String accountNumber;
    }

    class InvoiceInfo {
        public Integer terms;
    }

    class CreditCardInfo {
        public String cardType;
        public String token;
    }

    class InvoiceOnBehalfInfo {
        public Integer partnerId;
    }

    public static String getBillingAccountPaymentMethod(String billingAccountId) {

        if (String.isBlank(billingAccountId)) {
            throw new NGBSAPIException('BillingId is required for update payment limits');
        }

        String defaultPaymentMethod;

        try {
            String paymentMethodGetEndpoint = String.format(
                NGBS_PAYMENT_METHOD_FORMAT, new List<String>{billingAccountId}
            );

            HttpResponse resp = requestNGBS(paymentMethodGetEndpoint, 'GET');
            String respBodyStr = resp.getBody();

            String preparedJson = respBodyStr.replaceAll('default', 'isDefault');

            List<PaymentMethodInfo> paymentMethods = (List<PaymentMethodInfo>) JSON.deserialize(
                preparedJson,
                List<PaymentMethodInfo>.class
            );

            defaultPaymentMethod = findDefaultPaymentMethod(paymentMethods);

        } catch (Exception ex) {
            throw new NGBSAPIException('Error occurred during retrieving default payment method from NGBS', ex);
        }

        return defaultPaymentMethod;
    }

    private static String findDefaultPaymentMethod(List<PaymentMethodInfo> paymentMethods) {

        String defaultPaymentMethod;

        if (paymentMethods == null || paymentMethods.isEmpty()) {
            return defaultPaymentMethod;
        }

        try {
            for (PaymentMethodInfo item : paymentMethods) {
                if (!item.isDefault) {
                    continue;
                }
                if (item.directDebitInfo != null) {
                    defaultPaymentMethod = QuoteHelper.PAYMENT_METHOD_DIRECT_DEBIT;
                } else if (item.invoiceInfo != null) {
                    defaultPaymentMethod = QuoteHelper.PAYMENT_METHOD_INVOICE;
                } else if (item.creditCardInfo != null) {
                    defaultPaymentMethod = QuoteHelper.PAYMENT_METHOD_CREDIT_CARD;
                } else if (item.invoiceOnBehalfInfo != null) {
                    defaultPaymentMethod = QuoteHelper.PAYMENT_METHOD_INVOICE_ON_BEHALF;
                }
            }
        } catch (Exception ex) {
            throw new NGBSAPIException('Error occurred during retrieving default payment method from NGBS', ex);
        }

        return defaultPaymentMethod;
    }

    public static Response getPackageLimits(String accountId, String packageId) {
        if (String.isBlank(accountId) || String.isBlank(packageId)) {
            AquivaHelper.throwAquivaException(BILLING_ID_AND_PACKAGE_ID_EMPTY_EXCEPTION_MESSAGE);
        }
        Response res = new Response();
        try {
            String endpoint = String.format(NGBS_PACKAGE_LIMITS_F0RMAT, new List<String>{accountId, packageId});
            HttpResponse response = NGBSAPI.requestNGBS(endpoint, HttpHelper.METHOD_GET);
            if (HttpHelper.isSuccess(response)) {
                String respBodyStr = response.getBody();
                List<BillingWrappers.GlobalPackageLimits> packageLimits = (List<BillingWrappers.GlobalPackageLimits>) JSON.deserialize(respBodyStr, List<BillingWrappers.GlobalPackageLimits>.class);
                res.setData('packageLimits', packageLimits);
            } else {
                res.error('Failed to get package limits');
            }
        } catch (Exception ex) {
            AquivaHelper.throwAquivaException('Failed to get package limits. (' + ex.getMessage() + ')');
        }

        return res;
    }

    public static String getPaymentMethodType(String accountBillingId) {
        String paymentMethodType;
        if (String.isEmpty(accountBillingId)) {
            throw new NGBSAPIException('BillingId is required for getting Payment type');
        }
        try {
            String paymentMethodTypeGetEndpoint = String.format(NGBSAPI.NGBS_PAYMENT_METHOD_TYPE, new List<String>{
                accountBillingId
            });
            HttpResponse resp = requestNGBS(paymentMethodTypeGetEndpoint, 'GET');
            String respBodyStr = resp.getBody();
            PaymentMethodTypeHistory paymentMethod = (PaymentMethodTypeHistory) JSON.deserialize(
                respBodyStr,
                PaymentMethodTypeHistory.class
            );
            paymentMethodType = paymentMethod.currentType;
        } catch (Exception e) {
            throw new NGBSAPIException('Error occurred during retrieving payment method type from NGBS', e);
        }

        return paymentMethodType;
    }

    public static HttpResponse updateAccountBillingAddress(Account acc) {

        if (String.isBlank(acc.Billing_ID__c)) {
            throw new NGBSAPIException('Billing Id is missed on the Account');
        }
        String billingAddressPutEndpoint = String.format(
            NGBS_BILLING_ADDRESS, new List<String>{acc.Billing_ID__c}
        );

        BillingAddress billingAddressInfo = new BillingAddress(acc);
        if (!billingAddressInfo.isValid()) {
            throw new NGBSAPIException('Address information not valid for updating Billing Address');
        }

        try {
            HttpResponse updateBillingAddressResp = requestNGBS(
                billingAddressPutEndpoint,
                HttpHelper.METHOD_PUT,
                JSON.serialize(billingAddressInfo.address)
            );
            return updateBillingAddressResp;
        } catch (Exception ex) {
            throw new NGBSAPIException('Error during sync Billing Account ' + ex.getMessage());
        }
    }

    public static BillingWrappers.BillingInfo2 getBillingInfo(String billingId, String packageId) {
        try {
            String urlLicenses = NGBS_ACCOUNT_MANAGER + '/' + billingId +'/package/'+ packageId + '/billinginfo';
            BillingWrappers.BillingInfo2 bInfo =
                    (BillingWrappers.BillingInfo2) JSON.deserialize(
                            requestNGBS(urlLicenses, HttpHelper.METHOD_GET).getBody(),
                            BillingWrappers.BillingInfo2.class
                    );
            return bInfo;
        } catch (Exception ex) {
            throw new NGBSAPIException('Error during getting billingInfo ' + ex.getMessage());
        }

    }

    public static BillingWrappers.BillingLicense getLicense(String catalogId, String version, String elementId) {
        String url = NGBS_CATALOG_PATH + '/packages/'+ catalogId + '/' + version + '/licenses/' + elementId;
        HttpResponse res = requestNGBS(url, HttpHelper.METHOD_GET);
        return (BillingWrappers.BillingLicense) JSON.deserialize(res.getBody(), BillingWrappers.BillingLicense.class);
    }

    public static HttpResponse getAccountSummary(String accountId) {
        String endpoint = String.format(NGBS_ACCOUNT_SUMMARY_SHORT_VIEW, new List<String>{ accountId });
        return NGBSAPI.requestNGBS(endpoint, 'GET');
    }

    public static BillingWrappers.PackageConsolidationSettings getPackageConsolidationSettings(String accountId) {
        String endpoint = String.format(NGBS_PACKAGE_CONSOLIDATION_SETTINGS, new List<String>{ accountId });
        return (BillingWrappers.PackageConsolidationSettings) JSON.deserialize(NGBSAPI.requestNGBS(endpoint, HttpHelper.METHOD_GET).getBody(), BillingWrappers.PackageConsolidationSettings.class);
    }

    public static HttpResponse updatePackageConsolidationSettings(String accountId, String settings) {
        String endpoint = String.format(NGBS_PACKAGE_CONSOLIDATION_SETTINGS, new List<String>{ accountId });
        return NGBSAPI.requestNGBS(endpoint, HttpHelper.METHOD_POST, settings);
    }

    public static HttpResponse checkCostCenterRequest(String accountId) {
        String endpoint = String.format(NGBS_BILLING_CODES, new List<String>{ accountId });
        try {
            return NGBSAPI.requestNGBS(endpoint, HttpHelper.METHOD_GET);
        } catch (Exception ex) {
            throw new NGBSAPIException('Error during check Main Cost Center: ' + ex.getMessage());
        }
    }

    public static HttpResponse createMainCostCenterRequest(String accountId, String body) {
        String endpoint = String.format(NGBS_BILLING_CODES_MAIN_CREATION, new List<String>{ accountId });
        try {
            return NGBSAPI.requestNGBS(endpoint, HttpHelper.METHOD_POST, body);
        } catch (Exception ex) {
            throw new NGBSAPIException('Error during create Main Cost Center: ' + ex.getMessage());
        }
    }

    public static HttpResponse sendPaymentInfoRequest(String accountId, String packageId, String body) {
        String endpoint = String.format(NGBS_PAYMENT_INFORMATION, new List<String>{ accountId, packageId });
        try {
            return NGBSAPI.requestNGBS(endpoint, HttpHelper.METHOD_POST, body);
        } catch (Exception ex) {
            throw new NGBSAPIException('Error during create Main Cost Center: ' + ex.getMessage());
        }
    }

    public static HttpResponse syncPackageConsolidationSettings(Account acc, Boolean isSingleProduct) {
        return syncPackageConsolidationSettings(acc, isSingleProduct, AccountHelper.isMPUBAccount(acc.Id));
    }

    public static HttpResponse syncPackageConsolidationSettings(Account acc, Boolean isSingleProduct, Boolean isMPUB) {
        if (!isMPUB || isSingleProduct) {
            return null;
        }
        BillingWrappers.PackageConsolidationSettings settings = NGBSAPI.getPackageConsolidationSettings(acc.Billing_ID__c);
        //TODO: change this check if settings are null or they are the same as the ones in the account/opportunity/quote or wherever they are stored
        if (settings == null || (Boolean.valueOf(settings.billingAlignmentEnabled) && Boolean.valueOf(settings.invoiceConsolidationEnabled))) {
            return null;
        }

        settings.billingAlignmentEnabled = true;
        settings.invoiceConsolidationEnabled = true;
        return NGBSAPI.updatePackageConsolidationSettings(acc.Billing_ID__c, JSON.serialize(settings));
    }

    public static String getDiscountTemplateGroupEndpoint(String billingId, String accountPackageId) {

        if (String.isBlank(settings.BaseEndpoint) && String.isBlank(settings.AccountManagerPath)) {
            throw new AquivaHelper.AquivaException('Endpoint for Billing in NGBS_Settings__c is not set');
        }

        return settings.BaseEndpoint + settings.AccountManagerPath + '/account/' + billingId
            + '/package/' + accountPackageId + '/discountTemplateGroup';
    }

    public static String getContractCancellationEndpointMPLite(String billingId, String packageId, String contractId) {
        return String.format(
            NGBS_CONTRACT_CANCELLATION,
            new List<String> {billingId, packageId, contractId}
        );
    }

    public static String getContractCancellationEndpointMPUB(String billingId, String contractId) {
        return String.format(
            NGBS_CONTRACT_CANCELLATION_MPUB,
            new List<String> {billingId, contractId}
        );
    }

    @TestVisible
    public static HttpResponse checkIsMainCostCenterExist(String billingId) {
        return NGBSAPI.checkCostCenterRequest(billingId);
    }

    @TestVisible
    public static HttpResponse createMainCostCenter(String billingId) {
        String body = JSON.serialize(
            new Map<String, String> {
                'name' => 'Main',
                'defaultPackageStatus' => 'Disabled'
            }
        );

        return NGBSAPI.createMainCostCenterRequest(billingId, body);
    }

    public static HttpResponse sendPaymentInfo(String opportunityId, String billingAccountId, String billingPackageId, List<BillingWrappers.PaymentOrderItem> paymentOrderItems, String suborderId, String quoteNumber) {
        BillingWrappers.PaymentParams params = new BillingWrappers.PaymentParams();
        BillingWrappers.OrderMetadata orderMetadata = new BillingWrappers.OrderMetadata();
        params.salesOrderId = opportunityId;
        params.itemsToAdd = paymentOrderItems;
        orderMetadata.sowNumber = quoteNumber;
        orderMetadata.subOrderNumber = suborderId;
        params.orderMetadata = orderMetadata;
        String body = JSON.serialize(params);
        return NGBSAPI.sendPaymentInfoRequest(billingAccountId, billingPackageId, body);
    }

    public static HttpResponse updatePackageStatus(String billingAccountId, String billingPackageId, String status) {
        return NGBSAPI.updatePackageStatusRequest(billingAccountId, billingPackageId, status);
    }

    public static HttpResponse updatePackageStatusRequest(String accountId, String packageId, String status) {
        String endpoint = String.format(NGBS_PACKAGE_STATUS, new List<String>{ accountId, packageId, status });
        try {
            return NGBSAPI.requestNGBS(endpoint, HttpHelper.METHOD_POST);
        } catch (Exception ex) {
            throw new NGBSAPIException('Error during create Main Cost Center: ' + ex.getMessage());
        }
    }
}