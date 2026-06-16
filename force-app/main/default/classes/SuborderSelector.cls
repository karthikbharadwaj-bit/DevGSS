public inherited sharing class SuborderSelector extends SObjectSelector {

    public SuborderSelector() {
        super();
    }

    public SuborderSelector(String relationshipName, SObjectType relationshipBase) {
        super(relationshipName, relationshipBase);
    }

    public SuborderSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return Suborder__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Suborder__c.Id,
            Suborder__c.SuborderNumber__c,
            Suborder__c.Phase__c,
            Suborder__c.Order__c,
            Suborder__c.Status__c,
            Suborder__c.CurrencyIsoCode,
            Suborder__c.SignoffLink__c,
            Suborder__c.RevenueCategory__c,
            Suborder__c.SuborderId__c,
            Suborder__c.Name,
            Suborder__c.SumOfOneTimeItems__c,
            Suborder__c.SumOfRecurringItems__c,
            Suborder__c.Suborder_Type__c
        };
    }

    public List<String> getSuborderForProServ() {
        return new List<String> {
            'Id',
            'SuborderNumber__c',
            'CurrencyIsoCode',
            'SuborderId__c',
            'Name',
            'Status__c',
            'Order__c',
            'Order__r.OpportunityId',
            'Order__r.QuoteId',
            'Order__r.OrderNumber',
            'SignoffLink__c',
            'RevenueCategory__c',
            'Suborder_Type__c',
            'Order__r.UCSubtotal__c',
            'Order__r.CCSubtotal__c',
            'SumOfOneTimeItems__c'
        };
    }

    public QueryFactory selectSuborders() {
        return newQueryFactory()
            .setFactoryName('selectSuborders')
            .withSelectorFieldsIncluded();
    }

    public QueryFactory selectSubordersByOrdersIds(Set<Id> ordersIds) {
        return newQueryFactory()
            .setFactoryName('selectSubordersByOrdersIds')
            .selectFields(getSuborderForProServ())
            .subselect(
                new SuborderLineItemSelector().selectSuborderLineItemsForProServ()
            )
            .setCondition('Order__c IN :bind0')
            .setQueryBindings(new List<Object>{ordersIds});
    }

    public QueryFactory selectSubordersByOrderId(Id orderId) {
        return newQueryFactory()
            .setFactoryName('selectSubordersByOrderId')
            .selectFields(getSuborderForProServ())
            .subselect(
                new SuborderLineItemSelector().selectSuborderLineItemsForProServ()
            )
            .setCondition('Order__c = :bind0')
            .setQueryBindings(new List<Object>{orderId});
    }

    public QueryFactory selectSubordersByOrderIdAndStatus(Id orderId, String status) {
        return newQueryFactory()
            .setFactoryName('selectSubordersByOrderIdAndStatus')
            .selectFields(getSuborderForProServ())
            .subselect(
                new SuborderLineItemSelector().selectSuborderLineItemsForProServ()
            )
            .setCondition('Order__c = :bind0 AND Status__c = :bind1')
            .setQueryBindings(new List<Object>{orderId, status});
    }

    public QueryFactory selectSuborderByName(String suborderName) {
        return newQueryFactory()
            .setFactoryName('selectSuborderByName')
            .selectFields(getSuborderForProServ())
            .setCondition('Name = :bind0')
            .setQueryBindings(new List<Object>{suborderName});
    }

    public QueryFactory selectSuborderBySuborderId(String suborderId) {
        return newQueryFactory()
            .setFactoryName('selectSuborderBySuborderId')
            .selectFields(getSuborderForProServ())
            .setCondition('SuborderId__c = :bind0')
            .setQueryBindings(new List<Object>{suborderId});
    }

    public QueryFactory selectNotBilledSubordersByOrderId(Id orderId) {
        return newQueryFactory()
            .setFactoryName('selectNotBilledSubordersByOrderId')
            .selectFields(getSuborderForProServ())
            .subselect(
                new SuborderLineItemSelector().selectSuborderLineItemsForProServ()
            )
            .setCondition('Order__c = :bind0 AND Status__c != ' + '\'' + SuborderHelper.STATUS_BILLED + '\'')
            .setQueryBindings(new List<Object>{orderId});
    }

    public QueryFactory selectSubordersByIdAndStatus(Set<Id> suborderIds, String status) {
        return newQueryFactory()
            .setFactoryName('selectSubordersByIdAndStatus')
            .selectFields(getSuborderForProServ())
            .subselect(
                new SuborderLineItemSelector().selectSuborderLineItemsForProServ()
            )
            .setCondition('Id IN :bind0 AND Status__c = :bind1')
            .setQueryBindings(new List<Object>{suborderIds, status});
    }

    public QueryFactory selectSubordersByIds(Set<Id> suborderIds) {
        return newQueryFactory()
            .setFactoryName('selectSubordersByIds')
            .selectFields(getSuborderForProServ())
            .setCondition('Id IN :bind0')
            .setQueryBindings(new List<Object>{suborderIds});
    }

    public QueryFactory selectSubordersAndSuborderLineItemsByIds(Set<Id> suborderIds) {
        return newQueryFactory()
            .setFactoryName('selectSubordersAndSuborderLineItemsByIds')
            .selectFields(getSuborderForProServ())
            .subselect(
                new SuborderLineItemSelector().selectSuborderLineItemsForProServ()
            )
            .setCondition('Id IN :bind0')
            .setQueryBindings(new List<Object>{suborderIds});
    }
}