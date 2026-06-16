/**
 * This is helper class for Order standard object
 * Keep all static variables and helper methods related to it here
 *
 * It's might be better to keep here helper methods that do not do any SOQL
 * so they could be reused in triggers or controllers
 */
public with sharing class OrderHelper {

    // Order Describe Object
    public static Schema.DescribeSObjectResult DESCRIBE {
        get {
            if(DESCRIBE == null) {
                DESCRIBE = Order.SObjectType.getDescribe();
            }
            return DESCRIBE;
        }
        set;
    }

    // Record Types
    public static final String RT_NAME_CC_PROSERV = 'CC Professional Services';
    public static final String RT_NAME_PROSERV = 'Professional Services';
    public static final String RT_NAME_RC = 'RingCentral';
    public static final String RT_NAME_CC = 'Contact Center';
    public static final String RT_NAME_RC_CONTACT_CENTER = 'RingCentral Contact Center';
    public static final String RT_NAME_OFFICE = 'Office';
    public static final String RT_NAME_ENGAGE_VOICE_STANDALONE = 'Engage Voice';
    public static final String RT_NAME_ENGAGE_DIGITAL_STANDALONE = 'Engage Digital';
    public static final String RT_NAME_MEETING = 'Meetings';
    public static final String RT_NAME_FAX = 'Fax';
    public static final string RT_NAME_EVENT =  'Events';

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

    public static final Id RT_ID_CC_PROSERV = RT_INFO_BY_NAME.get(RT_NAME_CC_PROSERV).getRecordTypeId();
    public static final Id RT_ID_PROSERV = RT_INFO_BY_NAME.get(RT_NAME_PROSERV).getRecordTypeId();
    public static final Id RT_ID_RC = RT_INFO_BY_NAME.get(RT_NAME_RC).getRecordTypeId();
    public static final Id RT_ID_CC = RT_INFO_BY_NAME.get(RT_NAME_CC).getRecordTypeId();
    public static final Id RT_ID_RC_CONTACT_CENTER = RT_INFO_BY_NAME.get(RT_NAME_RC_CONTACT_CENTER).getRecordTypeId();
    public static final Id RT_ID_OFFICE = RT_INFO_BY_NAME.get(RT_NAME_OFFICE).getRecordTypeId();
    public static final Id RT_ID_ENGAGE_VOICE_STANDALONE = RT_INFO_BY_NAME.get(RT_NAME_ENGAGE_VOICE_STANDALONE).getRecordTypeId();
    public static final Id RT_ID_ENGAGE_DIGITAL_STANDALONE = RT_INFO_BY_NAME.get(RT_NAME_ENGAGE_DIGITAL_STANDALONE).getRecordTypeId();
    public static final Id RT_ID_MEETINGS = RT_INFO_BY_NAME.get(RT_NAME_MEETING).getRecordTypeId();
    public static final Id RT_ID_FAX = RT_INFO_BY_NAME.get(RT_NAME_FAX).getRecordTypeId();
    public static final Id RT_ID_EVENT = RT_INFO_BY_NAME.get(RT_NAME_EVENT).getRecordTypeId();


    //CC_Order_type__c
    public static final String CC_ORDER_TYPE_NEW = 'New';
    public static final String CC_ORDER_TYPE_UPSELL = 'Up-sell';
    public static final String CC_ORDER_TYPE_DOWNSELL = 'Downsell';
    public static final String CC_ORDER_TYPE_CHURN = 'Churn';

    public static final String STATUS_LOCKED = 'Locked';
    public static final String STATUS_SUBMITTED = 'Submitted';
    public static final String STATUS_SUBMITTED_PARTNERS = 'Submitted for Partners';
    public static final String STATUS_ACCEPTED = 'Accepted';
    public static final String STATUS_PROVISIONED = 'Provisioned';
    public static final String STATUS_NEW = 'New';
    public static final String STATUS_REVISED = 'Revised';
    public static final String STATUS_COMPLETED = 'Completed';
    public static final String STATUS_REQUIRES_ATTENTION = 'Requires Attention';
    public static final String STATUS_IN_PROGRESS = 'In Progress';

    public static final Set<String> STATUS_SET_SUBMITTED = new Set<String>{
        STATUS_SUBMITTED,
        STATUS_SUBMITTED_PARTNERS
    };

    //Picklsit values for Status
    public static final String STATUS_ACTIVATED = 'Activated';

    //Picklist values for Type
    public static final String TYPE_INITIAL_ORDER = 'Initial Order';
    public static final String TYPE_CHANGE_ORDER = 'Change Order';
    public static final String TYPE_NEW_ORDER = 'New Order';

    //Picklist values for Provisioning__c
    public static final String PROVISIONING_MANUAL = 'manual';
    public static final String PROVISIONING_AUTO = 'auto';

    public static final Map<String, Set<String>> PROVISIONING_TO_PRODUCT2_UPSELL_TYPES = new Map<String, Set<String>>{
        PROVISIONING_MANUAL => new Set<String>{
            Product2Helper.PRODUCT_PROVISIONING_TYPE_MANUAL
        },
        PROVISIONING_AUTO => new Set<String>{
            Product2Helper.PRODUCT_PROVISIONING_TYPE_AUTO_WITH_CASE, null
        }
    };

    public static final Map<String, Set<String>> PROVISIONING_TO_PRODUCT2_INITIAL_ORDER_TYPES = new Map<String, Set<String>>{
        PROVISIONING_MANUAL => new Set<String>{
            Product2Helper.PRODUCT_PROVISIONING_TYPE_MANUAL
        },
        PROVISIONING_AUTO => new Set<String>{
            Product2Helper.PRODUCT_PROVISIONING_TYPE_AUTO_WITH_CASE, null
        }
    };

    public static final Map<Id, Id> ORDER_RTID_TO_QUOTE_RTID_MAP = new Map<Id, Id>{
        RT_ID_PROSERV => QuoteHelper.RT_ID_PROSERV,
        RT_ID_CC_PROSERV => QuoteHelper.RT_ID_CC_PROSERV
    };

    public static final String ERROR_SUBMITTED_DATE_CHANGE = 'Only CC Desk Team can change Submitted Date';
    public static final String ERROR_SUBMITTED_DATE_CHANGE_SANDBOX = 'CC Desk Team can\'t change Submitted Date';

    public static final String PHASE_DELETION_ERROR =
        'You can not delete Order when it has completed or Pending Approval Phase';

    public static final Map<String, Id> SERVICE_NAME_TO_RT_ID = new Map<String, Id>{
        Constants.CONST_OFFICE => RT_ID_OFFICE,
        Constants.CONST_ENGAGE_VOICE => RT_ID_ENGAGE_VOICE_STANDALONE,
        Constants.CONST_ENGAGE_DIGITAL => RT_ID_ENGAGE_DIGITAL_STANDALONE,
        Constants.CONST_RCCC => RT_ID_RC_CONTACT_CENTER,
        Constants.CONST_RC_EVENT => RT_ID_EVENT,
        'Professional Services' => RT_ID_PROSERV
    };

    public static final Map<String, Id> SERVICE_NAME_TO_RT_ID_MP_UB = new Map<String, Id>{
        Constants.CONST_OFFICE => RT_ID_OFFICE,
        Constants.CONST_ENGAGE_VOICE => RT_ID_ENGAGE_VOICE_STANDALONE,
        Constants.CONST_ENGAGE_DIGITAL => RT_ID_ENGAGE_DIGITAL_STANDALONE,
        Constants.CONST_RCCC => RT_ID_RC_CONTACT_CENTER,
        Constants.CONST_MEETING => RT_ID_MEETINGS,
        Constants.CONST_FAX => RT_ID_FAX,
        Constants.CONST_RC_EVENT => RT_ID_EVENT,
        'Professional Services' => RT_ID_PROSERV
    };

    public static final String ORDERS_ARE_ACTIVATED = 'Orders are already activated';
    public static final String ORDER_IS_ACTIVATED = 'Order is already activated';

    public class OrderWrapper implements Comparable {

        public Order order;

        public OrderWrapper(Order orderObj) {
            order = orderObj;
        }

        public Integer compareTo(Object compareTo) {
            OrderWrapper compareToOrder = (OrderWrapper) compareTo;

            // The return value of 0 indicates that both elements are equal.
            Integer returnValue = 0;
            if (order.CreatedDate > compareToOrder.order.CreatedDate) {
                // Set return value to a positive value.
                returnValue = -1;
            } else if (order.CreatedDate < compareToOrder.order.CreatedDate) {
                // Set return value to a negative value.
                returnValue = 1;
            } else if ((order.CreatedDate == null) && (compareToOrder.order.CreatedDate != null)) {
                // nulls-first implementation
                returnValue = 1;
            } else if ((order.CreatedDate != null) && (compareToOrder.order.CreatedDate == null)) {
                // nulls-first implementation
                returnValue = -1;
            }
            return returnValue;
        }
    }

    public virtual class QuoteOrdersFactory {
        protected List<Quote> qtList;
        protected Boolean checkIfExistingBusiness = true;
        protected Boolean isNewService;
        protected Map<Id, Account> accountsMap {
            get {
                if (accountsMap == null) {
                    Map<Id, Account> accountMapStatic = OpportunityTriggerHelperRefactored.accountMapStatic;

                    accountsMap = new Map<Id, Account>();
                    Set<Id> accountIdsToLoad = new Set<Id>();
                    for (Quote qt : qtList) {
                        if (!accountMapStatic.containsKey(qt.AccountId)) {
                            accountIdsToLoad.add(qt.AccountId);
                        } else {
                            accountsMap.put(qt.AccountId, accountMapStatic.get(qt.AccountId));
                        }
                    }

                    if (!accountIdsToLoad.isEmpty()) {
                        List<Account> accountsLoaded = new AccountSelector()
                            .selectAccountsForOpportunityTrigger(accountIdsToLoad)
                            .executeQuery();

                        accountsMap.putAll(accountsLoaded);
                    }
                }
                return accountsMap;
            }
            private set;
        }

        protected Map<Id, Map<String, List<QuoteLineItem>>> provisioningToQLIListMap {
            get {
                if (provisioningToQLIListMap == null) {
                    provisioningToQLIListMap = new Map<Id, Map<String, List<QuoteLineItem>>>();

                    for (Quote qt : qtList) {
                        provisioningToQLIListMap.put(qt.Id, QuoteLineItemHelper.getProvisioningToQLIListMap(qt.QuoteLineItems, isNewService));
                    }
                }
                return provisioningToQLIListMap;
            }
            private set;
        }

        public QuoteOrdersFactory(List<Quote> qtList, Boolean checkIfExistingBusiness, Boolean isNewService) {
            this.qtList = qtList;
            this.isNewService = isNewService;
            this.checkIfExistingBusiness = checkIfExistingBusiness;
        }

        public OrderBuilder getBuilder(Quote qt) {
            Account acc = accountsMap.get(qt.AccountId);
            List<Account> techAccounts = acc?.Master_Accounts__r;

            if (QuoteHelper.isMPUBQuote(qt, techAccounts)) {
                return new OrderBuilderMultiProductUB(
                    qt,
                    techAccounts,
                    isNewService,
                    checkIfExistingBusiness,
                    provisioningToQLIListMap.get(qt.Id)
                );
            } else if (QuoteHelper.isQuotePackageInfoHasMultipleProducts(qt) || qt.IsMultiProductTechnicalQuote__c) {
                return new OrderBuilderMultiProduct(
                    qt,
                    checkIfExistingBusiness,
                    techAccounts
                );
            } else {
                return new OrderBuilder(qt);
            }
        }

        public Map<Id, List<Order>> buildOrdersForQuotes() {
            Map<Id, List<Order>> orders = new Map<Id, List<Order>>();
            for (Quote qt : qtList) {
                OrderBuilder builder = this.getBuilder(qt);

                if (!builder.isQuoteMatch()) {
                    continue;
                }

                List<Order> orderList = builder.buildOrders();

                if (orderList.isEmpty()) {
                    continue;
                }

                orders.put(qt.Id, orderList);

            }

            return orders;
        }
    }

    public virtual class OrderBuilder {
        protected Quote qt;

        public OrderBuilder(Quote qt) {
            this.qt = qt;
        }

        public virtual Boolean isQuoteMatch() {
            if (!OrderHelper.SERVICE_NAME_TO_RT_ID.containsKey(qt.Opportunity.Tier_Name__c)) {
                return false;
            }

            if (qt.QuoteLineItems.isEmpty()) {
                return false;
            }

            if (!qt.isPrimary__c) {
                return false;
            }

            if (qt.IsMultiProductTechnicalQuote__c) {
                return false;
            }

            if (QuoteHelper.isQuotePackageInfoHasMultipleProducts(qt)) {
                return false;
            }

            return true;
        }

        public virtual List<Order> buildOrders() {
            Order ord = new Order(
                Status = OrderHelper.STATUS_NEW,
                CurrencyIsoCode = qt.CurrencyIsoCode,
                EffectiveDate = Date.today(),
                RecordTypeId = OrderHelper.SERVICE_NAME_TO_RT_ID.get(qt.Opportunity.Tier_Name__c),
                AccountId = qt.AccountId,
                OpportunityId = qt.OpportunityId,
                QuoteId = qt.Id,
                Pricebook2Id = qt.Pricebook2Id,
                TechnicalAccountId__c = qt.AccountId,
                TechnicalOpportunityId__c = qt.OpportunityId,
                TechnicalQuoteId__c = qt.Id
            );

            return new List<Order>{
                ord
            };
        }
    }

    public virtual class OrderBuilderMultiProduct extends OrderBuilder {
        private List<Account> techAccounts = new List<Account>();
        private Boolean checkIfExistingBusiness;

        public OrderBuilderMultiProduct(Quote qt, Boolean checkIfExistingBusiness, List<Account> techAccounts) {
            super(qt);

            this.techAccounts = techAccounts;
            this.checkIfExistingBusiness = checkIfExistingBusiness;
        }

        public virtual override Boolean isQuoteMatch() {
            if (!OrderHelper.SERVICE_NAME_TO_RT_ID.containsKey(qt.ServiceName__c)) {
                return false;
            }

            if (qt.QuoteLineItems.isEmpty()) {
                return false;
            }

            if (QuoteHelper.isMPUBQuote(qt, techAccounts)) {
                return false;
            }

            if (qt.IsMultiProductTechnicalQuote__c) {
                if (qt.Status != QuoteHelper.QUOTE_STATUS_ACTIVE) {
                    return false;
                }

                if (checkIfExistingBusiness && qt.Opportunity.Type != OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS) {
                    return false;
                }
            } else {
                if (!qt.isPrimary__c) {
                    return false;
                }

                if (QuoteHelper.isQuotePackageInfoHasMultipleProducts(qt)) {
                    return false;
                }
            }

            return true;
        }

        public virtual override List<Order> buildOrders() {
            List<Order> orders = super.buildOrders();

            for (Order ord : orders) {
                if (qt.IsMultiProductTechnicalQuote__c) {
                    ord.AccountId = qt.MasterQuote__r.AccountId;
                    ord.OpportunityId = qt.MasterQuote__r.OpportunityId;
                    ord.QuoteId = qt.MasterQuote__c;
                    ord.TechnicalAccountId__c = qt.AccountId;
                    ord.TechnicalOpportunityId__c = qt.OpportunityId;
                    ord.TechnicalQuoteId__c = qt.Id;
                    ord.RecordTypeId = OrderHelper.SERVICE_NAME_TO_RT_ID.get(qt.ServiceName__c);
                }
            }

            return orders;
        }
    }

    public virtual class OrderBuilderMultiProductUB extends OrderBuilderMultiProduct {
        protected Map<String, List<QuoteLineItem>> provisioningToQLIListMap;
        protected Boolean checkIfExistingBusiness;
        protected Boolean isNewService;

        public OrderBuilderMultiProductUB(
            Quote qt,
            List<Account> techAccounts,
            Boolean isNewService,
            Boolean checkIfExistingBusiness,
            Map<String, List<QuoteLineItem>> provisioningToQLIListMap
        ) {
            super(qt, false, techAccounts);

            this.isNewService = isNewService;
            this.checkIfExistingBusiness = checkIfExistingBusiness;
            this.provisioningToQLIListMap = provisioningToQLIListMap;
        }

        public override Boolean isQuoteMatch() {
            if (!OrderHelper.SERVICE_NAME_TO_RT_ID_MP_UB.containsKey(qt.ServiceName__c)) {
                return false;
            }

            if (qt.QuoteLineItems.isEmpty()) {
                return false;
            }

            if (!QuoteHelper.isMPUBQuote(qt, techAccounts)) {
                return false;
            }

            if (qt.ServiceInfo__r.isEmpty()) {
                return false;
            }

            if (qt.ServiceInfo__r[0].IsProcessOrderSent__c) {
                return false;
            }

            if (isAllItemsDeliveredOnProServQuote(qt)) {
                return false;
            }

            if (qt.IsMultiProductTechnicalQuote__c) {
                if ((qt.Opportunity.PrimaryQuote__c != null && qt.Opportunity.PrimaryQuote__c != qt.MasterQuote__c && !QuoteHelper.isPOCQuote(qt))
                    || (QuoteHelper.isPOCQuote(qt) && !qt.MasterQuote__r.isPrimary__c)) {
                    return false;
                }

                if (checkIfExistingBusiness && (isNewService ? !String.isBlank(qt.BillingPackage__c) : String.isBlank(qt.BillingPackage__c))) {
                    return false;
                }
            } else {
                if (!qt.isPrimary__c) {
                    return false;
                }
                if (QuoteHelper.isQuotePackageInfoHasMultipleProducts(qt)) {
                    return false;
                }
            }

            return true;
        }

        public override List<Order> buildOrders() {
            List<Order> orders = new List<Order>();

            for (String provisioning : provisioningToQLIListMap.keySet()) {
                if (!provisioningToQLIListMap.get(provisioning).isEmpty()) {
                    Order ord = super.buildOrders().get(0);
                    ord.Provisioning__c = provisioning;
                    ord.RecordTypeId = OrderHelper.SERVICE_NAME_TO_RT_ID_MP_UB.get(qt.ServiceName__c);
                    if (ord.RecordTypeId == OrderHelper.RT_ID_PROSERV && String.isNotBlank(qt.MasterQuote__c) && String.isNotBlank(qt.masterQuote__r.Signed_SOW__c)) {
                        ord.Signed_SOW__c = qt.MasterQuote__r.Signed_SOW__c;
                    }
                    orders.add(ord);
                }
            }

            return orders;
        }
    }

    public static List<Order> buildOrdersForQuoteByProvisioning(Quote qt, Boolean isNewService) {
        List<Order> orders = new List<Order>();
        Map<String, List<QuoteLineItem>> provisioningToQLIListMap = QuoteLineItemHelper.getProvisioningToQLIListMap(qt.QuoteLineItems, isNewService);

        for (String provisioning : provisioningToQLIListMap.keySet()) {
            if (!provisioningToQLIListMap.get(provisioning).isEmpty()) {
                orders.add(buildOrderForQuote(qt, provisioning));
            }
        }

        return orders;
    }

    public static Order buildOrderForQuote(Quote qt) {
        return buildOrderForQuote(qt, null);
    }

    public static Order buildOrderForQuote(Quote qt, String provisioning) {
        System.assertNotEquals(null, qt, 'Quote is null');

        Order ord = createOrder(qt, provisioning);

        if (qt.IsMultiProductTechnicalQuote__c) {
            System.assertNotEquals(null, qt.MasterQuote__c, 'Master quote is null');
            ord.AccountId = qt.MasterQuote__r.AccountId;
            ord.OpportunityId = qt.MasterQuote__r.OpportunityId;
            ord.QuoteId = qt.MasterQuote__c;
            ord.TechnicalAccountId__c = qt.AccountId;
            ord.TechnicalOpportunityId__c = qt.OpportunityId;
            ord.TechnicalQuoteId__c = qt.Id;
            ord.RecordTypeId = OrderHelper.SERVICE_NAME_TO_RT_ID.get(qt.ServiceName__c);
        }

        return ord;
    }

    public static Order createOrder(Quote qt) {
        return createOrder(qt, null);
    }

    public static Order createOrder(Quote qt, String provisioning) {
        return new Order(
            Status = OrderHelper.STATUS_NEW,
            CurrencyIsoCode = qt.CurrencyIsoCode,
            EffectiveDate = Date.today(),
            RecordTypeId = OrderHelper.SERVICE_NAME_TO_RT_ID.get(qt.Opportunity.Tier_Name__c),
            AccountId = qt.AccountId,
            OpportunityId = qt.OpportunityId,
            QuoteId = qt.Id,
            Pricebook2Id = qt.Pricebook2Id,
            TechnicalAccountId__c = qt.AccountId,
            TechnicalOpportunityId__c = qt.OpportunityId,
            TechnicalQuoteId__c = qt.Id,
            Provisioning__c = provisioning
        );
    }

    @AuraEnabled
    public static Response activateOrderForOpportunity(Id quoteId) {
        Opportunity opp = (Opportunity) new ListOptional(
            new OpportunitySelector()
                .selectOpportunitiesForSyncWithNGBSByQuoteIds(new Set<Id>{
                    quoteId
                })
                .withoutSelectorFieldsIncluded()
                .selectFields(
                    new Set<SObjectField>{
                        Opportunity.Id
                    })
                .executeQuery()
        )
            .getFirst();

        if (AccountHelper.isMPUBAccount(opp.AccountId)) {
            return activateOrdersMPUB(quoteId);
        } else {
            return activateOrderForOpportunity(opp);
        }

    }

    public static Response activateOrderForOpportunity(Opportunity opp) {
        Response res = new Response();

        // Get order by opp Id
        List<Order> orders = (List<Order>) new OrderSelector()
            .selectNewOrdersByOppId(opp.Id)
            .selectFields(
                new Set<SObjectField>{
                    Order.Id,
                    Order.Status
                }
            )
            .executeQuery();

        if (orders.isEmpty()) {
            res.warning('Order is not activated', 'Not found order for activating');
            return res;
        }

        if (orders[0].Status == STATUS_ACTIVATED) {
            res.setData('message', ORDER_IS_ACTIVATED);
            return res;
        }

        Order orderToActivate = new Order(Id = orders[0].Id, Status = STATUS_ACTIVATED);

        try {
            update orderToActivate;
            String fullRecordURL = URL.getOrgDomainUrl().toExternalForm() + '/' + orderToActivate.Id;
            res.setData('message', 'Order successfully activated');
            res.setData('url', fullRecordURL);
        } catch (Exception e) {
            res.error('Error', e.getMessage());
        }

        return res;
    }

    public static Response activateOrdersMPUB(Id quoteId) {
        List<Order> orders = (List<Order>) new OrderSelector()
            .selectOrdersByTechQuoteIds(new Set<Id>{
                quoteId
            })
            .selectFields(
                new Set<SObjectField>{
                    Order.Id,
                    Order.Status
                }
            )
            .executeQuery();

        return activateOrdersList(orders);
    }

    public static Response activateOrdersList(List<Order> orders) {

        Response res = new Response();

        if (orders.isEmpty()) {
            res.warning('Orders are not activated', 'Not found orders for activating');
            return res;
        }

        List<Order> ordersToActivate = new List<Order>();
        for (Order order : orders) {
            if (order.Status != STATUS_ACTIVATED) {
                order.Status = STATUS_ACTIVATED;
                ordersToActivate.add(order);
            }
        }

        if (ordersToActivate.isEmpty()) {
            res.setData('message', ORDERS_ARE_ACTIVATED);
            return res;
        }

        try {
            update orders;
            String fullRecordURL = URL.getOrgDomainUrl().toExternalForm() + '/' + orders[0].Id;
            res.setData('message', 'Orders successfully activated');
            res.setData('url', fullRecordURL);
        } catch (Exception e) {
            res.error('Error', e.getMessage());
        }

        return res;
    }

    public static void deletePreviousOrders(Map<Id, Order> ordersToRemoveMap) {
        if (!ordersToRemoveMap.isEmpty()) {
            Map<Id, Suborder__c> subordersToRemoveMap =  new Map<Id, Suborder__c>((List<Suborder__c>)new SuborderSelector()
                .selectSubordersByOrdersIds(ordersToRemoveMap.keySet())
                .executeQuery());

            if (!subordersToRemoveMap.isEmpty()) {
                List<SuborderLineItem__c> subordersLineItemsToRemove = (List<SuborderLineItem__c>) new SuborderLineItemSelector()
                    .selectSuborderLineItemsBySuborderIds(subordersToRemoveMap.keySet())
                    .executeQuery();
                if (!subordersLineItemsToRemove.isEmpty()) {
                    delete subordersLineItemsToRemove;
                }
                delete subordersToRemoveMap.values();
            }

            List<ProServ_Project__c> proServProjectsToRemove = (List<ProServ_Project__c>) new ProServProjectSelector()
                .selectProServProjectsByOrderIds(ordersToRemoveMap.keySet())
                .executeQuery();
            if (!proServProjectsToRemove.isEmpty()) {
                delete proServProjectsToRemove;
            }

            List<PS_Integration__c> psIntegrationToRemove = (List<PS_Integration__c>) new PSIntegrationSelector()
                .selectPSIntegrationsByOrderIds(ordersToRemoveMap.keySet())
                .executeQuery();
            if (!psIntegrationToRemove.isEmpty()) {
                delete psIntegrationToRemove;
            }

            delete ordersToRemoveMap.values();
        }
    }

    public static Order getLastCreatedChangeOrder(String proservProjectId) {
        return (Order) new OrderSelector()
            .selectOrders()
            .selectFields(
                new List<String> {
                    'ProservProject__c',
                    'Type',
                    'Opportunity.Parent_Order__c',
                    'Opportunity.Name'
                }
            )
            .setCondition('(Type = \'' + OrderHelper.TYPE_INITIAL_ORDER + '\' OR Type = \'' + OrderHelper.TYPE_CHANGE_ORDER + '\') ' +
                    'AND (RecordTypeId = \'' + OrderHelper.RT_ID_PROSERV + '\' OR RecordTypeId = \'' + OrderHelper.RT_ID_CC_PROSERV + '\') ' +
                    'AND ProServProject__c = \'' + proservProjectId + '\'')
            .withoutSelectorOrderByIncluded()
            .addOrdering('CreatedDate', QueryFactory.SortOrder.DESCENDING)
            .executeQuery()
            .get(0);
    }

    public static Boolean isAllItemsDeliveredOnProServQuote(Quote quote) {
        return QuoteHelper.isProServService(quote) && OrderHelper.isAllItemsDeliveredOnQuote(quote.QuoteLineItems);
    }

    public static Boolean isAllItemsDeliveredOnQuote(List<QuoteLineItem> quoteLineItems) {
        Boolean result = true;

        for (QuoteLineItem quoteLineItem : quoteLineItems) {
            if (quoteLineItem.NewQuantity__c != quoteLineItem.DeliveredQuantity__c) {
                result = false;
                break;
            }
        }
        return result;
    }
}