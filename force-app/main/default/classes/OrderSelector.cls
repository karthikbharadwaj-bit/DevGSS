public inherited sharing class OrderSelector extends SObjectSelector {
    public static final Set<String> FIELDS_MANUAL_PROVISIONING_CASE_CREATION_PROCESS_MPUB = new Set<String> {
        'Id',
        'RecordTypeId',
        'QuoteId',
        'OpportunityId',
        'Opportunity.Owner.Email',
        'AccountId',
        'TechnicalQuoteId__c',
        'TechnicalQuoteId__r.PackageNameOld__c',
        'TechnicalQuoteId__r.Upsell_Status__c',
        'TechnicalOpportunityId__c',
        'TechnicalOpportunityId__r.Owner.Email',
        'TechnicalAccountId__c'
    };

    public OrderSelector() {
        super();
    }

    public OrderSelector(String relationshipName, SObjectType relationshipBase) {
        super(relationshipName, relationshipBase);
    }

    public OrderSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return Order.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Order.Id,
            Order.MaxPhaseNumber__c,
            Order.Booked_ProServ_OTP__c,
            Order.Status,
            Order.Booked_ProServ_OTP__c,
            Order.Estimated_ProServ_OTP__c,
            Order.hasProServ__c,
            Order.RecordTypeId,
            Order.CurrencyIsoCode,
            Order.AccountId,
            Order.OpportunityId,
            Order.OrderNumber,
            Order.RelatedChangeOpportunity__c,
            Order.Type
        };
    }

    public List<SObjectField> getFieldListToCheckOrderAmount() {
        return new List<Schema.SObjectField> {
            Order.Incremental_Order_Amount__c,
            Order.Completed_Phases_OTP_Summary__c
        };
    }

    public List<SObjectField> getFieldListToCheckSOWLink() {
        return new List<Schema.SObjectField> {
            Order.Signed_SOW__c
        };
    }

    public List<String> getFieldsForSuborderManagement() {
        return new List<String> {
            'Id',
            'Status',
            'PackageId__r.Account_Package_Id__c',
            'ProServProject__r.Order__r.CreatedDate',
            'UCSubtotal__c',
            'CCSubtotal__c',
            'OrderNumber',
            'Opportunity.Parent_Order__c',
            'Type',
            'MaxPhaseNumber__c',
            'CurrencyIsoCode'
        };
    }

    public List<String> getFieldsForPhaseManagement() {
        return new List<String> {
            'Id',
            'Name',
            'OrderNumber',
            'MainPointOfContact__r.Name',
            'EffectiveDate',
            'Status',
            'OpportunityId',
            'Opportunity.Name',
            'Opportunity.RecordTypeId',
            'Opportunity.Type',
            'Opportunity.Tier_Name__c',
            'QuoteId',
            'Quote.Opportunity.Parent_Order__c',
            'RecordTypeId',
            'Type'
        };
    }

    public List<String> getFieldsWithPackage() {
        return new List<String> {
            'Id',
            'Name',
            'Status',
            'Account.Billing_ID__c',
            'PackageId__r.Id',
            'PackageId__r.Account_Package_Id__c',
            'OpportunityId',
            'TechnicalQuoteId__c'
        };
    }

    public List<String> getPSIntegrationFields() {
        return new List<String> {
            'ProServProject__r.Id',
            'ProServProject__r.Name',
            'ProServProject__r.Quote__r.QuoteNumber',
            'ProServProject__r.Opportunity__c'
        };
    }

    public List<String> getFieldsForProservProjectCreation() {
        return new List<String> {
            'Id',
            'RecordTypeId',
            'AccountId',
            'OpportunityId',
            'QuoteId',
            'CurrencyIsoCode',
            'Quote.RecordTypeId',
            'Quote.PSProjectComplexity__c',
            'Account.Timezone__c'
        };
    }

    public List<String> getFieldsForManualProvisioningCaseCreationProcessMPUB() {
        return new List<String>(FIELDS_MANUAL_PROVISIONING_CASE_CREATION_PROCESS_MPUB);
    }

    public QueryFactory selectOrders() {
        return newQueryFactory()
            .setFactoryName('selectOrders')
            .withSelectorFieldsIncluded();
    }

    public QueryFactory selectOrderWithPhases(List<Object> bindings) {
        return newQueryFactory()
                .setFactoryName('SelectOrderWithPhases')
                .withSelectorFieldsIncluded()
                .withoutSelectorOrderByIncluded()
                    .subselect(new PhaseSelector().selectPhases()
                               .selectField(Phase__c.Phase_Number__c)
                               .setCondition('Id NOT IN :bind1'))
                .setCondition('Id IN :bind0')
                .setQueryBindings(bindings);
    }

    public QueryFactory selectOrdersByIds(List<Object> bindings) {
        return newQueryFactory()
                .setFactoryName('SelectOrdersByIds')
                .withSelectorFieldsIncluded()
                .withoutSelectorOrderByIncluded()
                .setCondition('Id IN :bind0')
                .setQueryBindings(bindings);
    }

    public QueryFactory selectOrdersByIdsWithAmounts(List<Object> bindings) {
        return newQueryFactory()
                .setFactoryName('selectOrdersByIdsWithAmounts')
                .withSelectorFieldsIncluded()
                .selectFields(getFieldListToCheckOrderAmount())
                .setCondition('Id IN :bind0')
                .setQueryBindings(bindings);
    }

    public QueryFactory selectOrderByOrderNumber(List<Object> bindings) {
        return newQueryFactory()
                .setFactoryName('selectOrderByOrderNumber')
                .withSelectorFieldsIncluded()
                .withoutSelectorOrderByIncluded()
                .setCondition('OrderNumber = :bind0')
                .setQueryBindings(bindings)
                .setLimit(1);
    }

    public QueryFactory selectOriginalSOWOrderByAccAndOppId(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectOriginalSOWOrderByAccAndOppId')
            .selectFields(getFieldListToCheckSOWLink())
            .setCondition('AccountId = :bind0 AND OpportunityId = :bind1')
            .setLimit(1)
            .setQueryBindings(bindings);
    }

    public QueryFactory selectNewOrdersByAccountIds(Set<Id> accountIds) {
        return newQueryFactory()
            .setFactoryName('selectNewOrdersByAccountIds')
            .setCondition('TechnicalAccountId__c IN :bind0 AND Status = \'' + OrderHelper.STATUS_NEW + '\'')
            .setQueryBindings(new List<Object>{accountIds});
    }

    public QueryFactory selectOrdersByAccountIds(Set<Id> accountIds) {
        return newQueryFactory()
            .setFactoryName('selectOrdersByAccountIds')
            .setCondition('TechnicalAccountId__c IN :bind0')
            .setQueryBindings(new List<Object>{accountIds});
    }

    public QueryFactory selectMigratedOrdersByAccountIds(Id accountId) {
        return newQueryFactory()
            .setFactoryName('selectMigratedOrdersByAccountIds')
            .selectFields(new List<Schema.SObjectField> {
                Order.Id,
                Order.Status
            })
            .setCondition('AccountId IN :bind0')
            .setQueryBindings(new List<Object>{ new List<Id> { accountId } });
    }

    public QueryFactory selectNewOrdersByOppId(String oppId) {
        return newQueryFactory()
            .setFactoryName('selectNewOrdersByOppId')
            .setCondition('TechnicalOpportunityId__c = :bind0')
            .addOrdering('CreatedDate', QueryFactory.SortOrder.DESCENDING)
            .setQueryBindings(new List<Object>{oppId});
    }

    public QueryFactory selectOrdersByTechQuoteIds(Set<Id> techQuoteIds) {
        return newQueryFactory()
            .setFactoryName('selectOrdersByTechQuoteIds')
            .selectFields(new List<Schema.SObjectField> {
                Order.Id,
                Order.TechnicalQuoteId__c,
                Order.QuoteId
            })
            .setCondition('TechnicalQuoteId__c IN :bind0')
            .setQueryBindings(new List<Object>{techQuoteIds});
    }

    public QueryFactory selectOrdersByTechQuoteIdsForManualProvisioningCaseCreationProcessMPUB(Set<Id> techQuoteIds) {
        return newQueryFactory()
            .setFactoryName('selectOrdersByTechQuoteIdsForManualProvisioningCaseCreationProcessMPUB')
            .selectFields(getFieldsForManualProvisioningCaseCreationProcessMPUB())
            .subselect(
                new OrderItemSelector()
                .selectOrderItemsForManualProvisioningCaseCreationProcessMPUB()
            )
            .setCondition('TechnicalQuoteId__c IN :bind0')
            .setQueryBindings(new List<Object>{techQuoteIds});

    }

    public QueryFactory selectOrdersByIdsForManualProvisioningCaseCreationProcessMPUB(Set<Id> orderIds) {
        return newQueryFactory()
            .setFactoryName('selectOrdersByIdsForManualProvisioningCaseCreationProcessMPUB')
            .selectFields(getFieldsForManualProvisioningCaseCreationProcessMPUB())
            .subselect(
                new OrderItemSelector()
                    .selectOrderItemsForManualProvisioningCaseCreationProcessMPUB()
            )
            .setCondition('Id IN :bind0')
            .setQueryBindings(new List<Object>{orderIds});
    }

    public QueryFactory selectOrdersByIdAndStatus(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectLockedOrdersByIds')
            .selectFields(new List<String>{ 'Id', 'Status' })
            .subselect(
                new SuborderSelector()
                    .selectSuborders()
            )
            .setCondition('Id IN :bind0 AND Status = :bind1')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectOrdersByIdsForPhaseManagement(Set<Id> orderIds) {
        return newQueryFactory()
            .setFactoryName('selectOrdersByIdsForPhaseManagement')
            .selectFields(getFieldsForPhaseManagement())
            .subselect(
                new OrderItemSelector()
                    .selectOrderItemsForPhaseManagement()
            )
            .subselect(
                new SuborderSelector()
                .selectSuborders()
            )
            .setCondition('Id IN :bind0')
            .setQueryBindings(new List<Object>{orderIds});
    }

    public QueryFactory selectOrdersWithPackage(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectOrdersWithPackage')
            .selectFields(getFieldsWithPackage())
            .subselect(
                new SuborderSelector()
                    .selectSuborders()
            )
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectProServOrderByPackageIdsUB(Set<Id> packageIds) {
        return newQueryFactory()
            .setFactoryName('selectProServOrdersByPackageIds')
            .selectFields(getFieldsWithPackage())
            .setCondition('PackageId__c IN :bind0 AND TechnicalQuoteId__c != null AND RecordTypeId = ' + '\'' + OrderHelper.RT_ID_PROSERV + '\'')
            .setQueryBindings(packageIds);
    }

    public QueryFactory selectOrdersForSuborderManagement(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectOrdersForSuborderManagement')
            .selectFields(getFieldsForSuborderManagement())
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectOrdersForPSIntegrationManagement(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectOrdersForPSIntegrationManagement')
            .withSelectorFieldsIncluded()
            .selectFields(getPSIntegrationFields())
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectOrdersByOpportunityIds(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectOrdersByOpportunityIds')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .selectFields(getPSIntegrationFields())
            .selectFields(getFieldsForProservProjectCreation())
            .setCondition('OpportunityId IN :bind0 AND Type IN :bind1 AND RecordTypeId = ' + '\'' + OrderHelper.RT_ID_PROSERV + '\'')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectOrdersWithSuborders(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectOrdersWithSuborders')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .subselect(
                new SuborderSelector()
                    .selectSuborders()
                    .selectField(Suborder__c.SuborderNumber__c)
                    .setCondition('Id NOT IN :bind1')
            )
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }
}