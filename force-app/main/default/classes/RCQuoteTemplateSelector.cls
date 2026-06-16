public inherited sharing class RCQuoteTemplateSelector extends SObjectSelector {
    public RCQuoteTemplateSelector() {
        super();
    }

    public RCQuoteTemplateSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return RC_Quote_Template__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            RC_Quote_Template__c.Id,
            RC_Quote_Template__c.Name
        };
    }
    
    public List<String> getNdaFieldList() {
        return new List<String> {
            'Id', 
            'Name',
            'LastModifiedDate',
            'Sorting_Order__c',
            'Description__c',
            'Brand__c',
            'Attachment_Name__c',
            'Opportunity_Record_Type__c',
            'Type__c',
            'Active__c',
            'Version__c',
            'Template_Engine__c'
        };
    }
    
    public QueryFactory selectRCQuoteTemplates() {
        return newQueryFactory()
            .setFactoryName('selectRCQuoteTemplate')
            .selectFields(getDefaultFieldList());
    }

    public QueryFactory selectNdaTemplatesByBillingCountry(List<Object> bindings) {
        return newQueryFactory()
        .selectFields(this.getNdaFieldList())
        .setFactoryName('selectNdaTemplatesByBillingCountry')
        .withoutSelectorOrderByIncluded()
        .setCondition('ObjectName__c = \'Account\' AND Available_For_Billing_Countries__c INCLUDES (:bind0)')
        .addOrdering(RC_Quote_Template__c.Sorting_Order__c, QueryFactory.SortOrder.ASCENDING)
        .setQueryBindings(bindings);
    }

    public QueryFactory selectNdaTemplatesById(List<Object> bindings) {
        return newQueryFactory()
        .selectFields(this.getNdaFieldList())
        .setFactoryName('selectNdaTemplatesById')
        .setCondition('ObjectName__c = \'Account\' AND Id = :bind0')
        .setQueryBindings(bindings);
    }

    public QueryFactory selectNdaTemplatesByBrand(List<Object> bindings) {
        return newQueryFactory()
        .selectFields(this.getNdaFieldList())
        .setFactoryName('selectNdaTemplatesByBrand')
        .withoutSelectorOrderByIncluded()
        .setCondition('ObjectName__c = \'Account\' AND Brand__c = :bind0')
        .addOrdering(RC_Quote_Template__c.Sorting_Order__c, QueryFactory.SortOrder.ASCENDING)
        .setQueryBindings(bindings);
    }

    public QueryFactory selectNdaTemplatesByBillingCountryAndBrand(List<Object> bindings) {
        return newQueryFactory()
        .selectFields(this.getNdaFieldList())
        .setFactoryName('selectNdaTemplatesByBrand')
        .withoutSelectorOrderByIncluded()
        .setCondition('ObjectName__c = \'Account\' AND Available_For_Billing_Countries__c INCLUDES (:bind0) AND Brand__c = :bind1')
        .addOrdering(RC_Quote_Template__c.Sorting_Order__c, QueryFactory.SortOrder.ASCENDING)
        .setQueryBindings(bindings);
    }
}