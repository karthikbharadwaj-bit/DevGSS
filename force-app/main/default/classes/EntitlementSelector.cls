public inherited sharing class EntitlementSelector extends SObjectSelector {

    public EntitlementSelector() {
        super();
    }

    public EntitlementSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return Entitlement__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {};
    }

    public List<String> getFieldList() {
        return new List<String>{
            'Active__c',
            'Product__r.Sub_Category__c',
            'Product__r.Family',
            'Product__r.Feature__c',
            'Quote__c'
        };
    }

    public List<String> getNGBSFieldList() {
        return new List<String>{
            'Name',
            'Account__c',
            'Price__c',
            'Display_Name__c',
            'Discount_Type__c',
            'Discount__c',
            'Quantity__c',
            'Quote__c',
            'PackageCatalogId__c',
            'PackageDuration__c',
            'PackageVersion__c',
            'Product__c',
            'Product__r.ExtID__c'
        };
    }
    public List<Schema.SObjectField> getFieldListForBatchJobCheckCCEntls() {
        return new List<Schema.SObjectField>{
            Entitlement__c.Id,
            Entitlement__c.Name,
            Entitlement__c.Account__c,
            Entitlement__c.Active__c,
            Entitlement__c.Product__c,
            Entitlement__c.Quantity__c
        };
    }

    public List<String> getChildFieldListForBatchJobCheckCCEntls() {
        return new List<String>{
            'Account__r.RC_User_Id__c',
            'Product__r.Number_of_Minutes__c',
            'Product__r.Name',
            'Product__r.ExtId__c',
            'Product__r.Parent__c',
            'Product__r.Product_Type__c',
            'Product__r.Family',
            'Product__r.Sub_Category__c'
        };
    }

    public List<Schema.SObjectField> getFieldListForGetEntls() {
        return new List<Schema.SObjectField>{
            Entitlement__c.Id,
            Entitlement__c.Price__c,
            Entitlement__c.Discount__c,
            Entitlement__c.Discount_Type__c,
            Entitlement__c.Active__c,
            Entitlement__c.Quantity__c,
            Entitlement__c.EffectivePrice__c,
            Entitlement__c.CreatedDate
        };
    }

    public List<String> getChildFieldListForGetEntls() {
        return new List<String>{
            'Product__r.Feature__c',
            'Product__r.Sub_Feature__c',
            'Product__r.Dependent_on_Feature__c',
            'Product__r.ExtId__c',
            'Product__r.Name',
            'Product__r.Charge_Term__c',
            'Product__r.Family',
            'Product__r.Sub_Category__c'
        };
    }

    public List<String> getFieldsForSyncEntitlements() {
        return new List<String>{
            'Quote__c',
            'Account__c',
            'Display_Name__c',
            'Product__c',
            'Product__r.Name',
            'Product__r.Feature__c',
            'Product__r.Family'
        };
    }

    public List<String> getFieldsForViewEntitlementsPage() {
        return new List<String>{
            'Id',
            'Name',
            'Active__c',
            'Start_Date__c',
            'End_Date__c',
            'DisplayQuantity__c',
            'Price__c',
            'Discount__c',
            'Discount_Type__c',
            'CurrencyIsoCode',
            'Product__r.Charge_Term__c',
            'Product__r.Sub_Category__c',
            'Product__r.Name'
        };
    }

    public QueryFactory selectEntitlements() {
        return newQueryFactory()
            .setFactoryName('selectEntitlements')
            .withSelectorFieldsIncluded()
            .withSelectFieldsSorted();
    }

    public QueryFactory selectActiveEntitlementsForAccount(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectEntitlementsForAccount')
            .selectFields(getFieldList())
            .withoutSelectorOrderByIncluded()
            .setCondition('Account__c IN :bind0 AND Active__c = true')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectEntitlementForSyncWithNGBSByName(Object entName) {
        List<Object> bindings = new List<Object>{entName};
        return newQueryFactory()
            .setFactoryName('selectEntitlementForSyncWithNGBSByName')
            .selectFields(getNGBSFieldList())
            .withoutSelectorOrderByIncluded()
            .setCondition('Name =:bind0 AND Active__c = true')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectEntitlementForSyncQuoteLineItemsByQuoteId(Object quoteId) {
        return selectEntitlementForSyncQuoteLineItemsByQuoteId(new List<Object> {quoteId});
    }

    public QueryFactory selectEntitlementForSyncQuoteLineItemsByQuoteId(List<Object> quoteIds) {
        QueryFactory queryFactory = newQueryFactory()
            .setFactoryName('selectEntitlementForSyncQuoteLineItemsByQuoteId')
            .selectFields(getNGBSFieldList())
            .withoutSelectorOrderByIncluded();
        if (quoteIds.size() == 1) {
            queryFactory.setCondition('Quote__c = :bind0');
        } else {
            queryFactory.setCondition('Quote__c = :bind0');
        }

        queryFactory.setQueryBindings(quoteIds);

        return queryFactory;
    }

    public QueryFactory selectEntitlementsForCheckCCEntls() {
        return newQueryFactory()
            .setFactoryName('SelectEntitlementsForCheckCCEntls')
            .selectFields(getFieldListForBatchJobCheckCCEntls())
            .selectFields(getChildFieldListForBatchJobCheckCCEntls())
            .withoutSelectorOrderByIncluded()
            .setCondition('Account__r.RC_User_Id__c != null AND Active__c = true AND ' +
                'Product__r.Sub_Category__c = \'Contact Center\' AND ' +
                '(Quantity__c != 0 OR (Quantity__c = 0 AND Product__r.Name LIKE \'%Domestic%\')) AND ' +
                ' Quantity__c != null');
    }

    public QueryFactory getEntitlements(String accountId) {
        return newQueryFactory()
            .setFactoryName('getEntitlements')
            .selectFields(getFieldListForGetEntls())
            .selectFields(getChildFieldListForGetEntls())
            .addOrdering('Active__c', QueryFactory.SortOrder.DESCENDING)
            .addOrdering('CreatedDate', QueryFactory.SortOrder.DESCENDING)
            .setCondition('Account__c = :bind0 AND PackageCatalogId__c = NULL AND Active__c = true')
            .setQueryBindings(new List<Object>{ accountId });
    }

    public QueryFactory selectEntitlementsByRcUserIdForCheckCCEntls(List<Object> bindings) {

        QueryFactory factory = newQueryFactory()
            .setFactoryName('SelectEntitlementsByARcUserIdForCheckCCEntls')
            .selectFields(getFieldListForBatchJobCheckCCEntls())
            .selectFields(getChildFieldListForBatchJobCheckCCEntls())
            .withoutSelectorOrderByIncluded();

        if (bindings.size() == 1) {

            factory.setCondition('Account__r.RC_User_Id__c IN :bind0 AND Active__c = true AND ' +
                'Product__r.Sub_Category__c = \'Contact Center\' AND ' +
                '(Quantity__c != 0 OR (Quantity__c = 0 AND Product__r.Name LIKE \'%Domestic%\')) AND ' +
                ' Quantity__c != null')
            .setQueryBindings(bindings);

        } else if (bindings.size() == 2) {

            factory.setCondition('Account__r.RC_User_Id__c IN :bind0 AND Account__r.RC_User_Id__c NOT IN :bind1 AND ' +
                'Active__c = true AND ' +
                'Product__r.Sub_Category__c = \'Contact Center\' AND ' +
                '(Quantity__c != 0 OR (Quantity__c = 0 AND Product__r.Name LIKE \'%Domestic%\')) AND ' +
                ' Quantity__c != null')
            .setQueryBindings(bindings);
        }

        return factory;
    }

    public QueryFactory selectEntitlementsByIdsWithProductDetails(List<Object> entitlementIds) {
        List<Object> bindings = new List<Object>{entitlementIds};

        return newQueryFactory()
            .setFactoryName('selectEntitlementsByIdsWithProductDetails')
            .withoutSelectorFieldsIncluded()
            .selectField('Id')
            .selectField('Quantity__c')
            .subselect(
                new ProductDetailSelector()
                    .selectProductDetails()
                    .withoutSelectorFieldsIncluded()
                    .withoutSelectorOrderByIncluded()
                    .selectFields(new List<String>{
                        'Id',
                        'Name',
                        'RampUp__c',
                        'RampUpStartDate__c',
                        'QuantityOrThreshold__c'
                })
                .addOrdering('RampUpStartDate__c', QueryFactory.SortOrder.DESCENDING)
                .addOrdering('Name', QueryFactory.SortOrder.DESCENDING)
                .setCondition('isActive__c = true')
            )
            .withoutSelectorOrderByIncluded()
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectEntitlementsForCloning(Id quoteId) {
        return newQueryFactory()
            .setFactoryName('selectEntitlementsForCloning')
            .selectFields(AquivaHelper.getAllFieldsForObject('Entitlement__c'))
            .setCondition('Quote__c = :bind0')
            .setQueryBindings(new List<Object>{ quoteId });
    }

    public QueryFactory selectEntitlementsForSync(Id quoteId) {
        return newQueryFactory()
            .setFactoryName('selectEntitlementsForSync')
            .selectFields(getFieldsForSyncEntitlements())
            .setCondition('Active__c = true AND Quote__c = :bind0')
            .setQueryBindings(new List<Object>{ quoteId });
    }


    public QueryFactory selectEntitlementsForViewEntPage(Id accId) {
        return newQueryFactory()
            .setFactoryName('selectEntitlementsForViewEntPage')
            .selectFields(getFieldsForViewEntitlementsPage())
            .subselect(
                new OrderItemSelector()
                    .selectOrderItems()
                    .selectFields(new List<String>{
                        'Id',
                        'Qty__c',
                        'UnitPrice',
                        'UnitPriceWithoutDiscount__c',
                        'CurrencyIsoCode',
                        'Discount_Type__c',
                        'Discount_Number__c',
                        'Order.Id',
                        'Order.Name',
                        'Order.Submitted_Date__c',
                        'Product2.Charge_Term__c'
                    })
                .setCondition('Order.Submitted_Date__c != null')
            )
            .withoutSelectorOrderByIncluded()
            .setCondition('Account__c = :bind0 AND PackageCatalogId__c = NULL')
            .setQueryBindings(new List<Object>{ accId });
    }
}