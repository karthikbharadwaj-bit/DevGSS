public abstract with sharing class PODataBuilderManager {
    @TestVisible
    private Opportunity opp;
    @TestVisible
    private PODataCollector dc;
    @TestVisible
    private Response resp = new Response();
    @TestVisible
    private List<Quote> optyQuotes {
        get {
            if ((optyQuotes != null && !optyQuotes.isEmpty()) || opp == null || dc.quotes == null) {
                return optyQuotes;
            }

            List<Quote> optyQuotes = new List<Quote>();
            for (Quote qt : dc.quotes) {
                if (qt.opportunityId == opp.Id) {
                    optyQuotes.add(qt);
                }
            }
            return optyQuotes;
        }
        set;
    }
    @TestVisible
    private Quote targetQuote {
        get {
            if (optyQuotes.isEmpty() || targetQuote != null) {
                return targetQuote;
            }

            Quote targetTechQuote;
            for (Quote qt : optyQuotes) {
                if (qt.IsMultiProductTechnicalQuote__c) {
                    targetTechQuote = qt;
                    break;
                }
            }
            Boolean isNewBilling = true;
            Quote primaryQuote = QuoteHelper.getPrimaryQuote(optyQuotes, isNewBilling);
            Quote pocQuote = QuoteHelper.getPOCQuote(optyQuotes, isNewBilling);

            targetQuote = QuoteHelper.containsOffice(optyQuotes) && pocQuote != null
                ? pocQuote
                : getTargetQuote(targetTechQuote, primaryQuote, pocQuote);

            return targetQuote;
        }
        set;
    }
    @TestVisible
    private List<QuoteLineItem> targetQuoteLineItems {
        get {
            if (targetQuoteLineItems != null && !targetQuoteLineItems.isEmpty()) {
                return targetQuoteLineItems;
            }
            if (targetQuote == null) {
                return new List<QuoteLineItem>();
            }

            List<QuoteLineItem> qlis = targetQuote.QuoteLineItems;
            if (POHelper.isAllowProcessOrderWithoutShipping) {
                Boolean isNotAllDevicesShipped = QuoteHelper.isNotAllDevicesShipped(targetQuote, dc.qlisWithCustomAddressAssignments);
                if (isNotAllDevicesShipped) {
                    qlis = SubscriberInfoBuilder.removeShippingDevices(targetQuote.QuoteLineItems);
                }
            }

            targetQuoteLineItems = getTargetQuoteLineItems(qlis);
            return targetQuoteLineItems;
        }
        set;
    }
    @TestVisible
    private List<Area_Code_Line_Item__c> areaCodeLineItemList {
        get {
            if (areaCodeLineItemList != null && !areaCodeLineItemList.isEmpty()) {
                return areaCodeLineItemList;
            }
            if (targetQuote == null) {
                return new List<Area_Code_Line_Item__c>();
            }

            areaCodeLineItemList = getAreaCodeLineItemList(
                dc.qlisWithCustomAddressAssignments,
                dc.aclis,
                targetQuote
            );

            return areaCodeLineItemList;
        }
        set;
    }
    @TestVisible
    private List<AssignmentLineItem__c> assignmentLineItemList {
        get {
            if (assignmentLineItemList != null && !assignmentLineItemList.isEmpty()) {
                return assignmentLineItemList;
            }
            if (targetQuote == null) {
                return new List<AssignmentLineItem__c>();
            }

            assignmentLineItemList = getAssignmentLineItemList(
                dc.qlisWithCustomAddressAssignments,
                dc.alis,
                targetQuote
            );

            return assignmentLineItemList;
        }
        set;
    }
    @TestVisible
    private Quote proservQuote {
        get {
            if (proservQuote != null) {
                return proservQuote;
            }

            Boolean isNewBilling = true;
            proServQuote = QuoteHelper.getProServQuote(optyQuotes, isNewBilling);

            return proServQuote;
        }
        set;
    }
    @TestVisible
    private Quote ccProServQuote {
        get {
            if (ccProServQuote != null) {
                return ccProServQuote;
            }

            Boolean isNewBilling = true;
            ccProServQuote = QuoteHelper.getCCProServQuote(optyQuotes, isNewBilling);

            return ccProServQuote;
        }
        set;
    }

    public PODataBuilderManager(PODataCollector.QuoteBasedDC dc, Opportunity opp) {
        this.opp = opp;
        this.dc = dc;
    }
    public PODataBuilderManager(PODataCollector.OrderBasedDC dc) {
        this.dc = dc;
    }
    public PODataBuilderManager() {}

    public abstract List<QuoteLineItem> getTargetQuoteLineItems(List<QuoteLineItem> qlis);
    public PODataBuilderManager build(Builder builder) {
        builder.init(this);
        resp.setData(builder.buildData());

        return this;
    }
    public Response buildResponse() {
         build(new QuoteDataBuilder())
             .build(new OpportunityDataBuilder())
             .build(new UserDataBuilder())
             .build(new PromotionDataBuilder())
             .build(new ApprovalDataBuilder())
             .build(new AccountDataBuilder())
             .build(new AccountRelationDataBuilder())
             .build(new ContactDataBuilder())
             .build(new AreaCodeLineItemDataBuilder())
             .build(new AssignmentLineItemDataBuilder())
             .build(new AreaCodeDataBuilder())
             .build(new AssignmentDataBuilder())
             .build(new ExistingBusinessBuilder());

         return resp;
    }

    @TestVisible
    private Quote getTargetQuote(Quote targetTechQuote, Quote primaryQuote, Quote pocQuote) {
        if (targetTechQuote != null) {
            return targetTechQuote;
        }
        if (primaryQuote == null && pocQuote != null) {
            return pocQuote;
        }
        return primaryQuote;
    }
    @TestVisible
    private List<Object> getLineItems(List<Object> xLineItems, List<QuoteLineItem> qlisWithCustomAddressAssignments, Quote qt) {
        if (xLineItems == null || xLineItems.isEmpty()) {
            return xLineItems;
        }

        List<QuoteLineItem> qlis = qt.QuoteLineItems;
        if (POHelper.isAllowProcessOrderWithoutShipping) {
            Boolean isNotAllDevicesShipped = QuoteHelper.isNotAllDevicesShipped(qt, qlisWithCustomAddressAssignments);
            if (isNotAllDevicesShipped) {
                qlis = SubscriberInfoBuilder.removeShippingDevices(qt.QuoteLineItems);
                Map<Id, QuoteLineItem> qlisMap = new Map<Id, QuoteLineItem>(qlis);
                xLineItems = xLineItems instanceof List<Area_Code_Line_Item__c>
                    ? (List<sObject>) SubscriberInfoBuilder.removeShippingAclis((List<Area_Code_Line_Item__c>) xLineItems, qlisMap.keySet())
                    : (List<sObject>) SubscriberInfoBuilder.removeShippingAlis((List<AssignmentLineItem__c>) xLineItems, qlisMap.keySet());
            }
        }

        return xLineItems;
    }
    @TestVisible
    private List<AssignmentLineItem__c> getAssignmentLineItemList(
        List<QuoteLineItem> qlisWithCustomAddressAssignments,
        List<AssignmentLineItem__c> alis,
        Quote qt
    ) {
        List<AssignmentLineItem__c> quoteAssignmentLineItems = filterAssignmentLineItemsByQuote(alis, qt);

        return (List<AssignmentLineItem__c>) getLineItems(
            quoteAssignmentLineItems,
            qlisWithCustomAddressAssignments,
            qt
        );
    }
    @TestVisible
    private List<Area_Code_Line_Item__c> getAreaCodeLineItemList(
        List<QuoteLineItem> qlisWithCustomAddressAssignments,
        List<Area_Code_Line_Item__c> aclis,
        Quote qt
    ) {
        List<Area_Code_Line_Item__c> quoteAreaCodeLineItems = filterAreaCodeLineItemsByQuote(aclis, qt);

        return (List<Area_Code_Line_Item__c>) getLineItems(
            quoteAreaCodeLineItems,
            qlisWithCustomAddressAssignments,
            qt
        );
    }
    @TestVisible
    private List<AssignmentLineItem__c> filterAssignmentLineItemsByQuote(
        List<AssignmentLineItem__c> alis,
        Quote qt
    ) {
        alis = (alis == null || qt == null)
            ? new List<AssignmentLineItem__c>()
            : alis;
        List<AssignmentLineItem__c> quoteAssignmentLineItems = new List<AssignmentLineItem__c>();
        for (AssignmentLineItem__c al: alis) {
            if (al.Parent__r.QuoteId == qt.Id || al.Child__r.QuoteId == qt.Id) {
                quoteAssignmentLineItems.add(al);
            }
        }

        return quoteAssignmentLineItems;
    }
    @TestVisible
    private List<Area_Code_Line_Item__c> filterAreaCodeLineItemsByQuote(
        List<Area_Code_Line_Item__c> aclis,
        Quote qt
    ) {
        aclis = (aclis == null || qt == null)
            ? new List<Area_Code_Line_Item__c>()
            : aclis;
        List<Area_Code_Line_Item__c> quoteAreaCodeLineItems = new List<Area_Code_Line_Item__c>();
        for (Area_Code_Line_Item__c acli : aclis) {
            if (acli.Quote_Line_Item__r.QuoteId == qt.Id) {
                quoteAreaCodeLineItems.add(acli);
            }
        }

        return quoteAreaCodeLineItems;
    }

    public abstract class Builder {
        private PODataBuilderManager m;
        private Response resp = new Response();

        public abstract Response buildData();

        public void init(PODataBuilderManager manager) {
            this.m = manager;
        }
    }
    public class QuoteDataBuilder extends Builder {
        @TestVisible private final String TARGET_QUOTE = 'targetQuote';
        @TestVisible private final String PRIMARY_QUOTE = 'primaryQuote';
        @TestVisible private final String CC_QUOTE = 'ccQuote';
        @TestVisible private final String POC_QUOTE = 'pocQuote';
        @TestVisible private final String PS_QUOTE = 'psQuote';
        @TestVisible private final String IS_PROSERV_QUOTE_NOT_CANCELLED = 'isProServQuotesNotCancelled';

        public override Response buildData() {
            if (m.opp == null || m.optyQuotes == null) {
                return resp;
            }

            resp.setData(TARGET_QUOTE, m.targetQuote);
            resp.setData(PRIMARY_QUOTE, getPrimaryQuote());
            resp.setData(CC_QUOTE, getCCQuote());
            resp.setData(POC_QUOTE, getPOCQuote());
            resp.setData(PS_QUOTE, getProservQuote());
            resp.setData(IS_PROSERV_QUOTE_NOT_CANCELLED, isProServQuotesNotCancelled());

            return resp;
        }
        private Boolean isProServQuotesNotCancelled() {
            return isProServQuotesNotCancelled(m.proServQuote) || isProServQuotesNotCancelled(m.ccProServQuote);
        }
        @TestVisible
        private Boolean isProServQuotesNotCancelled(Quote qt) {
            return qt != null && qt.ProServ_Status__c != QuoteHelper.PROSERVSTATUS_CANCELLED;
        }
        @TestVisible
        private Quote getPrimaryQuote() {
            Boolean isNewBilling = true;
            return QuoteHelper.getPrimaryQuote(m.optyQuotes, isNewBilling);
        }
        @TestVisible
        private Quote getCCQuote() {
            return QuoteHelper.getCCQuote(m.optyQuotes);
        }
        @TestVisible
        private Quote getPOCQuote() {
            Boolean isNewBilling = true;
            return QuoteHelper.getPOCQuote(m.optyQuotes, isNewBilling);
        }
        @TestVisible
        private Quote getProservQuote() {
            return QuoteHelper.isEngage(m.targetQuote)
                ? m.ccProServQuote
                : m.proServQuote;
        }
    }
    public class OpportunityDataBuilder extends Builder {
        @TestVisible private final String OPPORTUNITY = 'opportunity';

        public override Response buildData() {
            if (m.opp == null) {
                return resp;
            }

            resp.setData(OPPORTUNITY, m.opp);

            return resp;
        }
    }
    public class UserDataBuilder extends Builder {
        @TestVisible private final String USER = 'user';

        public override Response buildData() {
            if (m.dc?.usr == null) {
                return resp;
            }

            resp.setData('user', m.dc.usr);

            return resp;
        }
    }
    public class PromotionDataBuilder extends Builder {
        @TestVisible private final String PROMOTIONS = 'promotions';

        public override Response buildData() {
            if (m.dc == null || m.targetQuote == null) {
                return resp;
            }

            List<Promotion__c> promotionList = new List<Promotion__c>();
            for (Promotion__c promotion : m.dc.promotions) {
                //TODO: Looks like Promotions are not stored under technical quote. Thus promotionList will be empty
                if (promotion.Quote__c == m.targetQuote.Id) {
                    promotionList.add(promotion);
                }
            }
            resp.setData(PROMOTIONS, promotionList);

            return resp;
        }
    }
    public class ApprovalDataBuilder extends Builder {
        @TestVisible private final String APPROVALS = 'approvals';

        public override Response buildData() {
            if (m.dc?.approvals == null || m.opp == null) {
                return resp;
            }
            resp.setData(APPROVALS, m.dc.approvals);

            return resp;
        }
    }
    public class AccountDataBuilder extends Builder {
        @TestVisible private final String MASTER_ACC = 'masterAcc';
        @TestVisible private final String BOUND_ACCS = 'boundAccs';
        @TestVisible private final String UBRAND_ID = 'uBrandId';
        @TestVisible private final String NGBS_ACCOUNT_STATUS = 'ngbsAccountStatus';
        @TestVisible private final String PAYMENT_METHOD = 'paymentMethod';
        @TestVisible
        private BillingWrappers.NGBSAccount accountInfo {
            get {
                if (accountInfo != null) {
                    return accountInfo;
                }
                accountInfo = NGBSAPI.getNGBSAccount(m.opp.Account.Billing_ID__c);

                return accountInfo;
            }
            set;
        }

        public override Response buildData() {
            if (m.opp == null || m.dc?.accountMap == null) {
                return resp;
            }

            resp.setData(MASTER_ACC, m.dc.accountMap.get(m.opp.Account.Master_Account__c));
            resp.setData(BOUND_ACCS, m.dc.accountMap.values());
            resp.setData(UBRAND_ID, getSubBrandIdSelector());
            /* How do we need to get status for every service? */
            resp.setData(NGBS_ACCOUNT_STATUS, getAccountStatus(m.targetQuote));
            resp.setData(PAYMENT_METHOD, QuoteHelper.getPaymentMethod(
                m.opp.Account,
                m.opp,
                m.targetQuote,
                accountInfo,
                false
            ));

            return resp;
        }
        @TestVisible
        private String getSubBrandIdSelector() {
            return String.isNotBlank(m.opp.Sub_Brand__c)
                ? m.opp.Sub_Brand__c
                : m.dc.accountMap.get(m.opp.AccountId).SubBrandID__c;
        }
        @TestVisible
        private String getAccountStatus(Quote qt) {
            String packageId = QuoteHelper.getPackageId(qt.Package_Info__c);
            return accountInfo?.getPackageById(packageId)?.status;
        }
    }
    public class AccountRelationDataBuilder extends Builder {
        @TestVisible private final String ACC_RELATIONS = 'accRelations';

        public override Response buildData() {
            if (m.opp == null || m.dc?.accountsRelation == null) {
                return resp;
            }

            List<AccountRelation__c> accRelations = new List<AccountRelation__c>();
            for (AccountRelation__c relation : m.dc.accountsRelation) {
                if (relation.Child_Account__c == m.opp.AccountId || relation.Parent_Account__c == m.opp.AccountId ) {
                    accRelations.add(relation);
                }
            }
            resp.setData(ACC_RELATIONS, accRelations);

            return resp;
        }
    }
    public class ContactDataBuilder extends Builder {
        @TestVisible private final String CONTACT = 'contact';

        public override Response buildData() {
            resp.setData(CONTACT, m.dc.contact);

            return resp;
        }
    }
    public class AreaCodeLineItemDataBuilder extends Builder {
        @TestVisible private final String AREA_CODE_LINE_ITEMS = 'areaCodeLineItems';

        public override Response buildData() {
            resp.setData(AREA_CODE_LINE_ITEMS, m.areaCodeLineItemList);

            return resp;
        }
    }
    public class AssignmentLineItemDataBuilder extends Builder {
        @TestVisible private final String ASSIGNMENT_LINE_ITEM = 'assignementLineItem';

        public override Response buildData() {
            resp.setData(ASSIGNMENT_LINE_ITEM, m.assignmentLineItemList);

            return resp;
        }
    }
    public class AreaCodeDataBuilder extends Builder {
        @TestVisible private final String AREA_CODE = 'areaCodes';

        public override Response buildData() {
            List<Id> basedOnAcli = getAcIdFromAreaCodeLineItemList(m.areaCodeLineItemList);
            List<Id> basedOnQuotes = getAcIdFromQuote(m.targetQuote);

            List<Id> availableIdList = new List<Id>();
            availableIdList.addAll(basedOnAcli);
            availableIdList.addAll(basedOnQuotes);

            List<Area_Codes__c> currentAcList = getFilteredAreaCodes(m.dc.areaCodes, availableIdList);
            resp.setData(AREA_CODE, currentAcList);

            return resp;
        }

        @TestVisible
        private List<Id> getAcIdFromAreaCodeLineItemList(List<Area_Code_Line_Item__c> areaCodeLineItemList) {
            List<Id> acIdList = new List<Id>();
            for (Area_Code_Line_Item__c acli : areaCodeLineItemList) {
                acIdList.add(acli.Area_Code__c);
            }

            return acIdList;
        }
        @TestVisible
        private List<Id> getAcIdFromQuote(Quote qt) {
            List<Id> acIdList = new List<Id>();
            if (qt != null && qt.Enabled_LBO__c && qt.AreaCode__c != null) {
                acIdList.add(qt.AreaCode__c);
            }

            return acIdList;
        }
        @TestVisible
        private List<Area_Codes__c> getFilteredAreaCodes(List<Area_Codes__c> acList, List<Id> availableIdList) {
            List<Area_Codes__c> filteredAcList = new List<Area_Codes__c>();
            for (Area_Codes__c ac : acList) {
                if (availableIdList.contains(ac.Id)) {
                    filteredAcList.add(ac);
                }
            }

            return filteredAcList;
        }
    }
    public class AssignmentDataBuilder extends Builder {
        @TestVisible private final String ASSIGNMENTS_TO_SIGN_UP = 'assignmentsToSignUp';
        @TestVisible private final String ASSIGNMENTS_TO_MANUAL = 'assignmentsToManual';
        private final String AUTO = 'auto';
        private final String MANUAL = 'manual';

        public override Response buildData() {
            Map<Id, QuoteLineItem> qliMap = new Map<Id, QuoteLineItem>(m.targetQuoteLineItems);
            Map<Id, Area_Codes__c> acMap = new Map<Id, Area_Codes__c>(m.dc.areaCodes);

            Map<String, SubscriberInfoBuilder.AssignmentData[]> filtered = SubscriberInfoBuilder.getAssignmentsFilterByLimits(
                m.targetQuoteLineItems,
                m.areaCodeLineItemList,
                m.assignmentLineItemList,
                qliMap,
                acMap,
                m.targetQuote,
                m.proServQuote,
                m.ccProServQuote,
                m.opp.BusinessIdentity__c,
                m.dc.hasProServTechQuote
            );

            /* Filter products with manual signup */
            filtered.put(AUTO, POHelper.filterProductsForManualOrderType(m.targetQuote.BusinessIdentity__c, filtered.get(AUTO)));

            resp.setData(ASSIGNMENTS_TO_SIGN_UP, filtered.get(AUTO));
            resp.setData(ASSIGNMENTS_TO_MANUAL, filtered.get(MANUAL));

            return resp;
        }
    }
    public class ExistingBusinessBuilder extends Builder {
        @TestVisible
        private final String EXISTING_BUSINESS = 'isExistingBusiness';

        public override Response buildData() {
            resp.setData(EXISTING_BUSINESS, String.isNotBlank(m.targetQuote?.BillingPackage__c));
            return resp;
        }
    }
    public class OrderBasedManager extends PODataBuilderManager {
        PODataCollector.OrderBasedDC dc {
            get {
                return (PODataCollector.OrderBasedDC) super.dc;
            }
            set;
        }

        public OrderBasedManager(PODataCollector.OrderBasedDC dc, List<Quote> quotes) {
            super(dc);
            /* UB flow should be based on actual Order state */
            optyQuotes = !dc.orders.isEmpty() ? filterQuotesByOrderExistence(quotes, dc.orders) : quotes;
            opp = dc.masterOpp;
        }

        @TestVisible
        private List<Quote> filterQuotesByOrderExistence(List<Quote> quotes, List<Order> orders) {
            Set<Id> orderQuoteId = new Set<Id>();
            for (Order o : orders) {
                orderQuoteId.add(o.QuoteId);
                orderQuoteId.add(o.TechnicalQuoteId__c);
            }

            List<Quote> quotesWithOrders = new List<Quote>();
            for (Quote qt : quotes) {
                Boolean hasOrder = orderQuoteId.contains(qt.Id);
                Boolean orderNotRequired = QuoteHelper.PROSERV_QUOTE_DEVELOPER_ID_SET.contains(qt.RecordTypeId);
                if (hasOrder || orderNotRequired) {
                    quotesWithOrders.add(qt);
                }
            }

            return quotesWithOrders;
        }
        @TestVisible
        private List<QuoteLineItem> filterQuoteLineItemsByOrderItemsExistence(List<QuoteLineItem> qlis) {
            Map<Id, OrderItem> qliIdToOrderItemMap = new Map<Id, OrderItem>();
            for (OrderItem oi : dc.orderItems) {
                qliIdToOrderItemMap.put(oi.QuoteLineItemId, oi);
                if (oi.QuoteLineItem.MasterQLI__c != null) {
                    qliIdToOrderItemMap.put(oi.QuoteLineItem.MasterQLI__c, oi);
                }
            }

            List<QuoteLineItem> qlisWithOrderItems = new List<QuoteLineItem>();
            for (QuoteLineItem qli : qlis) {
                Boolean hasOrderItem = qliIdToOrderItemMap.get(qli.Id) != null;
                Boolean isParentHasOrderItem = qliIdToOrderItemMap.get(qli.MasterQLI__c) != null;

                if (hasOrderItem || isParentHasOrderItem) {
                    qlisWithOrderItems.add(qli);
                }
            }

            return qlisWithOrderItems;
        }

        public override List<QuoteLineItem> getTargetQuoteLineItems(List<QuoteLineItem> targetQlis) {
            return filterQuoteLineItemsByOrderItemsExistence(targetQlis);
        }
    }
    public class QuoteBasedManager extends PODataBuilderManager {
        PODataCollector.QuoteBasedDC dc {
            get {
                return (PODataCollector.QuoteBasedDC) super.dc;
            }
            set;
        }

        public QuoteBasedManager(PODataCollector.QuoteBasedDC dc, Opportunity opp) {
            super(dc, opp);
        }

        public override List<QuoteLineItem> getTargetQuoteLineItems(List<QuoteLineItem> targetQlis) {
            return targetQlis;
        }
    }
}