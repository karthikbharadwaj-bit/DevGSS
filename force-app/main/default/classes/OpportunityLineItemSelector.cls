public inherited sharing class OpportunityLineItemSelector extends SObjectSelector {

    public OpportunityLineItemSelector() {
        super();
    }

    public OpportunityLineItemSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType() {
        return OpportunityLineItem.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField>{
            OpportunityLineItem.Id,
            OpportunityLineItem.Name,
            OpportunityLineItem.Product2Id,
            OpportunityLineItem.Quantity,
            OpportunityLineItem.UnitPrice,
            OpportunityLineItem.TotalPrice,
            OpportunityLineItem.Discount,
            OpportunityLineItem.ServiceDate,
            OpportunityLineItem.Description,
            OpportunityLineItem.OpportunityId
        };
    }

    public QueryFactory selectLineItemsByOpportunityIdForSummary(Id opportunityId) {
        return newQueryFactory()
            .setFactoryName('selectLineItemsByOpportunityIdForSummary')
            .withSelectorFieldsIncluded()
            .selectFields(new List<String>{ 'Product2.Name' })
            .withoutSelectorOrderByIncluded()
            .setCondition('OpportunityId = :bind0')
            .setQueryBindings(new List<Object>{ opportunityId });
    }

    /**
     * Line items with the product catalog fields used for enrichment.
     */
    public QueryFactory selectLineItemsWithProductContextForSummary(Id opportunityId, Integer rowLimit) {
        return selectLineItemsByOpportunityIdForSummary(opportunityId)
            .setFactoryName('selectLineItemsWithProductContextForSummary')
            .selectFields(new List<String>{
                'Product2.Family',
                'Product2.Sub_Category__c',
                'Product2.Subgroup__c',
                'Product2.Group__c',
                'Product2.Description',
                'Product2.Product_Description__c',
                'Product2.CategoryName__c',
                'Product2.LicenseGroup__c',
                'Product2.ServiceCategory__c'
            })
            .setLimit(rowLimit);
    }
}
