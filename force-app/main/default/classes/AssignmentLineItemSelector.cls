public inherited sharing class AssignmentLineItemSelector extends SObjectSelector {

    public AssignmentLineItemSelector() {
        super();
    }

    public AssignmentLineItemSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType() {
        return AssignmentLineItem__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            AssignmentLineItem__c.Id
        };
    }

    public List<String> getFieldListForCloning() {
        return new List<String> {
            'AreaCode__c',
            'Parent__c',
            'Child__c',
            'Quantity__c',
            'Parent__r.IsMultiProductTechnicalQLI__c',
            'Parent__r.MasterQLI__c',
            'Child__r.IsMultiProductTechnicalQLI__c',
            'Child__r.MasterQLI__c'
        };
    }

    public List<String> getRelatedAreaCodeFields() {
        return new List<String> {
            'AreaCode__c',
            'AreaCode__r.Name',
            'AreaCode__r.Area_Code__c',
            'AreaCode__r.Type__c',
            'AreaCode__r.City__c',
            'AreaCode__r.Country__c',
            'AreaCode__r.State__c',
            'AreaCode__r.StateID__c',
            'AreaCode__r.NPA__c',
            'AreaCode__r.NXX__c'
        };
    }

    public List<String> getAllFieldsList() {
        List<String> fields = new List<String>{
            'Parent__c',
            'Parent__r.Product2.ExtID__c',
            'Parent__r.QuoteId',
            'Parent__r.Product_Lic_Id__c',
            'Child__c',
            'Child__r.QuoteId',
            'Child__c.Product2.ExtID__c',
            'Quantity__c'
        };
        fields.addAll(getRelatedAreaCodeFields());
        return fields;
    }

    public QueryFactory selectALIForRemove(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectALIForRemove')
            .selectFields(getDefaultFieldList())
            .setCondition('(Parent__c IN :bind0 OR Child__c IN :bind0) AND Parent__r.IsMultiProductTechnicalQLI__c = false')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectALIForQLI(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectALIForQLI')
            .selectFields(getAllFieldsList())
            .setCondition('Parent__c = :bind0 OR Child__c = :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectALIForQLIsRelated(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectALIForQLIsRelated')
            .selectFields(getAllFieldsList())
            .setCondition('Parent__c = :bind0 AND Child__c = :bind1')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectALIForAllRelated(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectALIForAllRelated')
            .selectFields(getAllFieldsList())
            .setCondition('Parent__c = :bind0 AND Child__c = :bind1 AND AreaCode__c = :bind2')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectALIForQuote(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectALIForQuote')
            .selectFields(getAllFieldsList())
            .setCondition('Parent__r.QuoteId = :bind0 OR Child__r.QuoteId = :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectALIForQuotes(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectALIForQuote')
            .selectFields(getAllFieldsList())
            .setCondition('Parent__r.QuoteId IN :bind0 OR Child__r.QuoteId IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectALIForSignUp(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectALIForSignUp')
            .selectFields(getAllFieldsList())
            .setCondition('Parent__c IN :bind0 OR Child__c IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectAllFieldsForCloning(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectAllFieldsForCloning')
            .selectFields(AquivaHelper.getAllFieldsForObject('AssignmentLineItem__c'))
            .setCondition('Parent__c IN :bind0 OR Child__c IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectMasterItemsAllFieldsForCloning(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectMasterItemsAllFieldsForCloning')
            .selectFields(getFieldListForCloning())
            .setCondition('Id IN :bind0 and Parent__r.IsMultiProductTechnicalQLI__c = false')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectTechnicalItemsByMasterQliId(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectTechnicalItemsByMasterQliId')
            .selectFields(getFieldListForCloning())
            .setCondition('Parent__r.MasterQLI__c IN :bind0 AND Parent__r.IsMultiProductTechnicalQLI__c = true')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectALIForMasterQuotes(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectALIForMasterQuotes')
            .selectFields(getDefaultFieldList())
            .setCondition('(Parent__r.QuoteId IN :bind0 OR Child__r.QuoteId IN :bind0) AND Parent__r.IsMultiProductTechnicalQLI__c = false')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectALIForDealDeskCaseDescription(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectALIForDealDeskCaseDescription')
            .selectFields(getAllFieldsList())
            .selectFields(new List<String>{
                'Child__r.Display_Name__c',
                'Child__r.Charge_Term__c',
                'Child__r.EffectivePriceNew__c',
                'Child__r.UnitPrice',
                'Child__r.Discount_type__c',
                'Child__r.Discount_number__c',
                'Child__r.CurrencyIsoCode'
            })
            .setCondition('Parent__c IN :bind0')
            .setQueryBindings(bindings);
    }
}