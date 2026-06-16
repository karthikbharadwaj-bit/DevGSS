public inherited sharing class CustomAddressAssignmentsSelector extends SObjectSelector {

    public CustomAddressAssignmentsSelector() {
        super();
    }

    public CustomAddressAssignmentsSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return CustomAddressAssignments__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            CustomAddressAssignments__c.Id
        };
    }

    public List<String> getFieldsForShipping() {
        return new List<String>{
            'Id',
            'Name',
            'AttentionTo__c',
            'Quantity__c',
            'Type__c',
            'ShippingLicenseTree__c',
            'ShippingBillingCodeId__c',
            'DeviceId__c',
            'AssignmentLineItem__c',
            'AssignmentLineItem__r.AreaCode__r.Area_Code__c',
            'QuoteLineItem__c',
            'QuoteLineItem__r.ParentPackageName__c',
            'QuoteLineItem__r.Product_Lic_Id__c',
            'QuoteLineItem__r.ChargeTerm__c',
            'QuoteLineItem__r.PackageInfo__c',
            'QuoteLineItem__r.Quote.Account.Name',
            'QuoteLineItem__r.Product2.ShippingType__c',
            'CustomAddress__c',
            'CustomAddress__r.Name',
            'CustomAddress__r.Country__c',
            'CustomAddress__r.City__c',
            'CustomAddress__r.State__c',
            'CustomAddress__r.PostalCode__c',
            'CustomAddress__r.Street__c',
            'CustomAddress__r.AddressLine__c',
            'CustomAddress__r.AdditionalAddressLine__c',
            'AssignmentLineItem__r.AreaCode__r.Name',
            'AssignmentLineItem__r.Parent__r.Product_Lic_Id__c'
        };
    }

    public QueryFactory selectCustomAddressAssignments() {
        return newQueryFactory()
            .setFactoryName('selectCustomAddressAssignments')
            .selectFields(getFieldsForShipping());
    }

    public QueryFactory selectCAAForShipping(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectCAAForShipping')
            .selectFields(getFieldsForShipping())
            .setCondition('QuoteLineItem__c IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectAllFieldsForCloning(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectAllFieldsForCloning')
            .selectFields(AquivaHelper.getAllFieldsForObject('CustomAddressAssignments__c'))
            .setCondition('QuoteLineItem__c IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectTechnicalCAA(Set<Id> qliIds) {
        return newQueryFactory()
            .setFactoryName('selectTechnicalCAA')
            .selectFields(new List<String>{'Id', 'CustomAddress__c', 'QuoteLineItem__r.Id', 'QuoteLineItem__r.MasterQLI__c', 'DeviceId__c'})
            .setCondition('QuoteLineItem__r.MasterQLI__c IN :bind0')
            .setQueryBindings(new List<Object> { qliIds });
    }

    public QueryFactory selectCustomAddressAssignmentsByOppIds(List<Id> oppIds) {
        return newQueryFactory()
            .setFactoryName('selectCustomAddressAssignmentsByOppIds')
            .selectFields(getDefaultFieldList())
            .setCondition('QuoteLineItem__r.Quote.OpportunityId IN :bind0')
            .setQueryBindings(new List<Object> {oppIds});
    }

    public QueryFactory selectCustomAddressAssignmentsByQliIds(List<Id> qliIds) {
        return newQueryFactory()
            .setFactoryName('selectCustomAddressAssignmentsByQliIds')
            .selectFields(getDefaultFieldList())
            .setCondition('QuoteLineItem__c IN :bind0')
            .setQueryBindings(new List<Object> {qliIds});
    }

    public QueryFactory selectCustomAddressAssignmentsByQuoteIds(Set<Id> quoteIds) {
        return newQueryFactory()
            .setFactoryName('selectCustomAddressAssignmentsByQuoteIds')
            .selectFields(getDefaultFieldList())
            .setCondition('QuoteLineItem__r.QuoteId IN :bind0')
            .setQueryBindings(new List<Object> {quoteIds});
    }
}