public inherited sharing class AreaCodeLineItemSelector extends SObjectSelector {

    public AreaCodeLineItemSelector() {
        super();
    }

    public AreaCodeLineItemSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType() {
        return Area_Code_Line_Item__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Area_Code_Line_Item__c.Id
        };
    }

    public List<Schema.SObjectField> getAllFieldsList() {
        return new List<Schema.SObjectField> {
            Area_Code_Line_Item__c.Area_Code__c,
            Area_Code_Line_Item__c.Quantity__c,
            Area_Code_Line_Item__c.Quote_Line_Item__c
        };
    }

    public List<String> getQuoteRelatedAreaCodeFields() {
        return new List<String> {
            'Quote_Line_Item__c',
            'Quote_Line_Item__r.QuoteId'
        };
    }

    public List<String> getRelatedAreaCodeFieldsList() {
        return new List<String> {
            'Area_Code__c',
            'Quantity__c',
            'Quote_Line_Item__c',
            'Area_Code__r.Name',
            'Area_Code__r.Country__c',
            'Area_Code__r.State__c',
            'Area_Code__r.City__c',
            'Area_Code__r.Area_Code__c',
            'Area_Code__r.NPA__c',
            'Area_Code__r.NXX__c'
        };
    }

    public List<String> getFieldListForCloning() {
        return new List<String> {
            'Area_Code__c',
            'Quantity__c',
            'Quote_Line_Item__c',
            'Quote_Line_Item__r.IsMultiProductTechnicalQLI__c',
            'Quote_Line_Item__r.MasterQLI__c'
        };
    }

    public QueryFactory selectACLIForSignUp(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectACLIForSignUp')
            .selectFields(getAllFieldsList())
            .selectFields(
                new List<String>{
                    'Area_Code__r.Area_Code__c',
                    'Area_Code__r.City__c',
                    'Area_Code__r.Country__c'
                }
            )
            .setCondition('Quote_Line_Item__c IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectACLIForQuotes(Object bindings) {
        return newQueryFactory()
            .setFactoryName('selectACLIForQuotes')
            .selectFields(getAllFieldsList())
            .setCondition('Quote_Line_Item__r.QuoteId = :bind0')
            .setQueryBindings(new List<Object>{ bindings });
    }

    public QueryFactory selectACLIForAllQuotes(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectACLIForAllQuotes')
            .selectFields(getAllFieldsList())
            .selectFields(getQuoteRelatedAreaCodeFields())
            .setCondition('Quote_Line_Item__r.QuoteId IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectAreaCodeLineItems(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectAreaCodeLineItems')
            .selectFields(getAllFieldsList())
            .setCondition('Quote_Line_Item__c IN (SELECT Id FROM QuoteLineItem WHERE QuoteId = :bind0)')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectAreaCodeLineItemsForCloning(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectAreaCodeLineItemsForCloning')
            .selectFields(AquivaHelper.getAllFieldsForObject('Area_Code_Line_Item__c'))
            .setCondition('Quote_Line_Item__c IN (SELECT Id FROM QuoteLineItem WHERE QuoteId = :bind0)')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectAreaCodeLineItemsWithAreaCodes() {
        return newQueryFactory()
            .setFactoryName('selectAreaCodeLineItemsWithAreaCodes')
            .selectFields(getRelatedAreaCodeFieldsList());
    }

    public QueryFactory selectMasterItemsAllFieldsForCloning(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectMasterItemsAllFieldsForCloning')
            .selectFields(getFieldListForCloning())
            .setCondition('Id IN :bind0 and Quote_Line_Item__r.IsMultiProductTechnicalQLI__c = false')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectTechnicalItemsByMasterQliId(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectTechnicalItemsByMasterQliId')
            .selectFields(getFieldListForCloning())
            .setCondition('Quote_Line_Item__r.MasterQLI__c IN :bind0 AND Quote_Line_Item__r.IsMultiProductTechnicalQLI__c = true')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectACLIForMasterQuotes(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectACLIForMasterQuotes')
            .selectFields(getAllFieldsList())
            .selectFields(getQuoteRelatedAreaCodeFields())
            .setCondition('Quote_Line_Item__r.QuoteId IN :bind0 AND Quote_Line_Item__r.IsMultiProductTechnicalQLI__c = false')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectACLIForDealDeskCaseDescription(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectACLIForDealDeskCaseDescription')
            .selectFields(getRelatedAreaCodeFieldsList())
            .setCondition('Quote_Line_Item__c IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectACLIForSync(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectACLIForSync')
            .selectFields(getAllFieldsList())
            .selectFields(getRelatedAreaCodeFieldsList())
            .selectFields(
                new List<String>{
                    'Quote_Line_Item__r.QuoteId',
                    'Quote_Line_Item__r.Product_Lic_Id__c'
                }
            )
            .setCondition('Quote_Line_Item__r.QuoteId IN :bind0')
            .setQueryBindings(bindings);
    }
}