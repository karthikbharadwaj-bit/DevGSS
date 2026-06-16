public abstract with sharing class PODataCollector {
    public List<Quote> quotes {
        get {
            if (quotes != null && !quotes.isEmpty()) {
                return quotes;
            }

            if (!targetIds.isEmpty()) {
                //TODO: Potentially proserv quote is missed here, because {targetIds} contains only primary and tech quotes
                quotes = new QuoteSelector()
                    .selectQuotesForMultiSignUp(targetIds)
                    .executeQuery();
            }


            return quotes != null ? quotes : new List<Quote>();
        }
        set;
    }
    public List<Area_Code_Line_Item__c> aclis {
        get {
            if (aclis != null && !aclis.isEmpty()) {
                return aclis;
            }

            if (!targetQuoteIds.isEmpty()) {
                aclis = new AreaCodeLineItemSelector()
                    .selectACLIForAllQuotes(new List<Object> { targetQuoteIds })
                    .executeQuery();
            }

            return aclis != null ? aclis : new List<Area_Code_Line_Item__c>();
        }
        set;
    }
    public Opportunity masterOpp {
        get {
            if (masterOpp != null) {
                return masterOpp;
            }

            for (Opportunity opty : opportunities) {
                if (opty.Id == masterQuote?.opportunityId) {
                    masterOpp = opty;
                    break;
                }
            }

            return masterOpp;
        }
        set;
    }

    public Boolean hasProServTechQuote {
        get {
            if (hasProServTechQuote == null) {
                hasProServTechQuote = false;
                for (Quote qt : quotes) { 
                    if (QuoteHelper.isProServService(qt)) {
                        hasProServTechQuote = true;
                        break;
                    }
                }
            }
            return hasProServTechQuote;
        }
        set;
    }

    public User usr;
    public List<Promotion__c> promotions = new List<Promotion__c>();
    public List<Approval__c> approvals = new List<Approval__c>();
    public Map<Id, Account> accountMap = new Map<Id, Account>();
    public List<AccountRelation__c> accountsRelation = new List<AccountRelation__c>();
    public Contact contact;
    public List<AssignmentLineItem__c> alis = new List<AssignmentLineItem__c>();
    public List<Area_Codes__c> areaCodes = new List<Area_Codes__c>();
    public List<QuoteLineItem> qlisWithCustomAddressAssignments = new List<QuoteLineItem>();

    @TestVisible
    private Set<Id> targetIds = new Set<Id>();
    @TestVisible
    private List<Opportunity> opportunities {
        get {
            if (opportunities != null && !opportunities.isEmpty()) {
                return opportunities;
            }

            Set<Id> oppIds = collectOppIds(quotes);
            oppIds.addAll(collectOppIds(targetIds));

            if (!oppIds.isEmpty()) {
                opportunities = new OpportunitySelector()
                    .selectOpportunitiesForSignUp(new List<Object> {
                        oppIds
                    })
                    .executeQuery();
            }

            return opportunities != null ? opportunities : new List<Opportunity>();
        }
        set;
    }
    @TestVisible
    private Set<Id> accIdSet {
        get {
            if (accIdSet != null && !accIdSet.isEmpty()) {
                return accIdSet;
            }

            accIdSet = new Set<Id>();
            for (Opportunity opty : opportunities) {
                accIdSet.add(opty.AccountId);
                if (opty.Account.Master_Account__c != null) {
                    accIdSet.add(opty.Account.Master_Account__c);
                }
            }

            return accIdSet;
        }
        set;
    }
    @TestVisible
    private Quote masterQuote {
        get {
            if (masterQuote != null) {
                return masterQuote;
            }

            for (Quote qt : quotes) {
                /* Proserv quotes don't have MasterQuote reference and shouldn't be treated as master quote */
                Boolean isProservQuote = QuoteHelper.isProServOrCCProServ(qt);
                if (qt.MasterQuote__c == null && !isProservQuote) {
                    masterQuote = qt;
                    break;
                }
            }

            return masterQuote;
        }
        set;
    }
    @TestVisible
    private Set<Id> targetQuoteIds {
        get {
            if (targetQuoteIds != null && !targetQuoteIds.isEmpty()) {
                return targetQuoteIds;
            }
            targetQuoteIds = new Map<Id, Quote>(quotes).keySet();

            return targetQuoteIds;
        }
        set;
    }

    public PODataCollector(Set<Id> targetIds) {
        this.targetIds = targetIds;
    }

    abstract public PODataCollector collectData();
    public PODataCollector collectBaseData() {
        return queryQuotes()
            .queryOpportunities()
            .queryUser()
            .queryPromotions()
            .queryApprovals()
            .queryAccounts()
            .queryAccountsRelations()
            .queryContact()
            .queryAreaCodeLineItems()
            .queryAssignmentLineItems()
            .queryAreaCodes()
            .queryQuoteLineItems();
    }

    public List<Response> transformData() {
        return isTransformer()
            ? getTransformer().prepareData().transformPreparedData()
            : new List<Response>();
    }

    @TestVisible
    private List<Quote> filterProservQuotes() {
        List<Quote> quotesWithoutProserv = new List<Quote>();
        for (Quote qt: quotes) {
            if (QuoteHelper.isProServOrCCProServ(qt)) {
                continue;
            }
            quotesWithoutProserv.add(qt);
        }

        return quotesWithoutProserv;
    }

    protected Boolean isOfficeNotSignedUp() {
        // skip for single product
        List<Quote> quotesWithoutProserv = filterProservQuotes();
        if (quotesWithoutProserv.size() == 1) {
            return true;
        }

        for (Quote qt : quotesWithoutProserv) {
            // In case when MVP is not signed up we pass id of technical MVP quote in targetIds from PO
            // Therefore we have technical MVP quote in quotes list that can be used to check if MVP is signed up
            if (QuoteHelper.isOffice(qt) && qt.IsMultiProductTechnicalQuote__c) {
                return true;
            }
        }
        return false;
    }

    private Boolean isTransformer() {
        return this instanceof IPODataTransformer;
    }

    private IPODataTransformer getTransformer() {
        return (IPODataTransformer) this;
    }

    @TestVisible
    private PODataCollector queryQuotes() {
        quotes = quotes;

        return this;
    }
    @TestVisible
    private PODataCollector queryOpportunities() {
        opportunities = opportunities;

        return this;
    }
    @TestVisible
    private PODataCollector queryUser() {
        usr = (User) new ListOptional(
            new UserSelector()
                .selectUserForSignUp(UserInfo.getUserId())
                .executeQuery()
        ).getFirst();

        return this;
    }
    @TestVisible
    private PODataCollector queryPromotions() {
        if (!targetQuoteIds.isEmpty()) {
            promotions = (List<Promotion__c>) new PromotionSelector()
                .selectPromotionByQuoteId(new List<Object> { targetQuoteIds })
                .executeQuery();
        }

        return this;
    }
    @TestVisible
    private PODataCollector queryApprovals() {
        if (!accIdSet.isEmpty()) {
            approvals = new ApprovalSelector()
                .selectApprovalsForAccount(new List<Object> { accIdSet })
                .executeQuery();
        }

        return this;
    }
    @TestVisible
    private PODataCollector queryAccounts() {
        if (!accIdSet.isEmpty()) {
            accountMap = new Map<Id, Account>(
                (List<Account>) new AccountSelector()
                    .selectBoundAccountsByIdOrMasterAccountId(new List<Object> { accIdSet })
                    .executeQuery()
            );
        }

        return this;
    }
    @TestVisible
    private PODataCollector queryAccountsRelations() {
        if (!accIdSet.isEmpty()) {
            accountsRelation = (List<AccountRelation__c>) new AccountRelationSelector()
                .selectAccountRelationsByParentAndChildIds(new List<Object> { accIdSet })
                .executeQuery();
        }

        return this;
    }
    @TestVisible
    private PODataCollector queryContact() {
        if (masterOpp == null) {
            return this;
        }

        Id contactId;
        for (OpportunityContactRole roleObj : masterOpp.OpportunityContactRoles) {
            contactId = roleObj.ContactId;
            if (roleObj.Role == 'Administrator') {
                break;
            }
        }

        if (contactId != null) {
            contact = (Contact) new ListOptional(new ContactSelector()
                .selectContactById(new List<Object> {contactId})
                .executeQuery()
            ).getFirst();
        }

        return this;
    }
    @TestVisible
    private PODataCollector queryAreaCodeLineItems() {
        aclis = aclis;

        return this;
    }
    @TestVisible
    private PODataCollector queryAssignmentLineItems() {
        if (!targetQuoteIds.isEmpty()) {
            alis = new AssignmentLineItemSelector()
                .selectALIForQuote(new List<Object> { targetQuoteIds })
                .executeQuery();
        }

        return this;
    }
    @TestVisible
    private PODataCollector queryAreaCodes() {
        Set<Id> acIds = new Set<Id>();
        for (Area_Code_Line_Item__c acli : aclis) {
            acIds.add(acli.area_code__c);
        }
        for (Quote q : quotes) {
            acIds.add(q.AreaCode__c);
        }

        if (!acIds.isEmpty()) {
            areaCodes = new AreaCodesSelector()
                .selectAreaCodesByIds(acIds)
                .executeQuery();
        }

        return this;
    }
    @TestVisible
    private PODataCollector queryQuoteLineItems() {
        if (POHelper.isAllowProcessOrderWithoutShipping) {
            qlisWithCustomAddressAssignments = (List<QuoteLineItem>) new QuoteLineItemSelector()
                .selectQuoteLineItemsWithCustomAddressAssignments(new List<Object> {new Set<Id> { masterQuote.Id }})
                .executeQuery();
        }

        return this;
    }
    @TestVisible
    private Set<Id> collectOppIds(List<Quote> qts) {
        Set<Id> result = new Set<Id>();
        for (Quote q : qts) {
            result.add(q.OpportunityId);
        }
        result.remove(null);

        return result;
    }
    // For now we are expecting to have both Opportunity and Quote ids in the request, because Terminate flow might not have quotes.
    // TODO: remove this method when Terminate flow is guaranteed to have quotes.
    @TestVisible
    private Set<Id> collectOppIds(Set<Id> targetIds) {
        Set<Id> result = new Set<Id>();
        for (Id targetId : targetIds) {
            if (targetId != null && targetId.getSobjectType() == Opportunity.SObjectType) {
                result.add(targetId);
            }
        }

        return result;
    }

    public class OrderBasedDC extends PODataCollector implements IPODataTransformer {
        public List<Order> orders {
            get {
                if (orders != null && !orders.isEmpty()) {
                    return orders;
                }

                if (!targetQuoteIds.isEmpty()) {
                    orders = new OrderSelector()
                        .selectOrdersByTechQuoteIds( targetQuoteIds )
                        .executeQuery();
                }

                return orders != null ? orders : new List<Order>();
            }
            set;
        }
        public List<OrderItem> orderItems = new List<OrderItem>();
        @TestVisible
        private List<Quote> preparedQuotes = new List<Quote>();

        public OrderBasedDC(Set<Id> targetQuoteIds) {
            super(targetQuoteIds);
        }

        public override PODataCollector collectData() {
            return queryOrders()
                .queryOrderItems()
                .collectBaseData();
        }

        public IPODataTransformer prepareData() {
            preparedQuotes = filterQuotes();

            return this;
        }

        public List<Response> transformPreparedData() {
            List<Response> responseList = new List<Response>();
            Map<String, List<Quote>> serviceToQuoteListMap = groupQuotesByServices(preparedQuotes);
            for (List<Quote> quotesGroupedByService : serviceToQuoteListMap.values()) {
                PODataBuilderManager manager = new PODataBuilderManager.OrderBasedManager(this, quotesGroupedByService);
                responseList.add(manager.buildResponse());
            }

            return responseList;
        }

        @TestVisible
        private OrderBasedDC queryOrders() {
            orders = orders;

            return this;
        }
        @TestVisible
        private OrderBasedDC queryOrderItems() {
            Set<Id> ordersId = new Map<Id, Order>(orders).keySet();
            if (!ordersId.isEmpty()) {
                orderItems = new OrderItemSelector()
                    .selectOrderItemsByOrderIds(new List<Object> { ordersId })
                    .executeQuery();
            }

            return this;
        }
        @TestVisible
        private Map<String, List<Quote>> groupQuotesByServices(List<Quote> quotes) {
            Map<String, List<Quote>> serviceToQuoteListMap = new Map<String, List<Quote>>();

            List<Quote> proservQuotes = new List<Quote>();
            for (Quote qt : quotes) {
                if (QuoteHelper.isProServOrCCProServ(qt)) {
                    proservQuotes.add(qt);
                }

                if (String.isBlank(qt.ServiceName__c)) {
                    continue;
                }

                if (!serviceToQuoteListMap.containsKey(qt.ServiceName__c)) {
                    serviceToQuoteListMap.put(qt.ServiceName__c, new List<Quote>());
                }
                serviceToQuoteListMap.get(qt.ServiceName__c).add(qt);
            }

            String targetServiceName = getProServServiceName(serviceToQuoteListMap.keySet());
            if (serviceToQuoteListMap.containsKey(targetServiceName) && !proservQuotes.isEmpty()) {
                serviceToQuoteListMap.get(targetServiceName).addAll(proservQuotes);
            }

            return serviceToQuoteListMap;
        }

        private String getProServServiceName(Set<String> serviceNames) {
            // Proserv quotes should be stored in the main service bundle.
            // For multi-product, it is always Office.
            // For single product, it can be Engage as well.
            return serviceNames.size() == 1
                ? new List<String>(serviceNames)[0]
                : QuoteHelper.NGBS_OFFICE_PRODUCT;
        }

        private List<Quote> filterQuotes() {
            if (isOfficeNotSignedUp()) {
                return quotes;
            }

            List<Quote> result = new List<Quote>();
            for (Quote qt : quotes) {
                if (masterQuote?.Id != qt.Id) {
                    result.add(qt);
                }
            }

            return result;
        }
    }
    public class QuoteBasedDC extends PODataCollector implements IPODataTransformer {
        @TestVisible
        private List<Opportunity> preparedOpportunities = new List<Opportunity>();

        public QuoteBasedDC(Set<Id> targetIds) {
            super(targetIds);
        }

        public override PODataCollector collectData() {
            return collectBaseData();
        }

        public IPODataTransformer prepareData() {
            preparedOpportunities = filterOpportunities();

            return this;
        }

        public List<Response> transformPreparedData() {
            List<Response> responseList = new List<Response>();
            for (Opportunity opp : preparedOpportunities) {
                PODataBuilderManager.QuoteBasedManager manager = new PODataBuilderManager.QuoteBasedManager(this, opp);
                responseList.add(manager.buildResponse());
            }

            return responseList;
        }

        private List<Opportunity> filterOpportunities() {
            if (isOfficeNotSignedUp()) {
                return opportunities;
            }
            List<Opportunity> result = new List<Opportunity>();
            for (Opportunity opp : opportunities) {
                if (masterOpp?.Id != opp.Id) {
                    result.add(opp);
                }
            }

            return result;
        }
    }
}