public inherited sharing class MarketingTestSelector extends SObjectSelector{
    public MarketingTestSelector() {
        super();
    }

    public MarketingTestSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType() {
        return Marketing_Testing__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Marketing_Testing__c.Id,
            Marketing_Testing__c.Name,
            Marketing_Testing__c.CreatedById,
            Marketing_Testing__c.Description__c,
            Marketing_Testing__c.Adobe_Target_Id__c,
            Marketing_Testing__c.Test_Date_From__c,
            Marketing_Testing__c.Test_Date_To__c,
            Marketing_Testing__c.Campaign__c
        };
    }

    public QueryFactory selectAdobeTargetIdBasedOnIdAndDates(List<Object> bindings) {
        return newQueryFactory()
                .setFactoryName('selectDFRForTQLUpdate')
                .withSelectorFieldsIncluded()
                .setCondition('Adobe_Target_Id__c = :bind0 AND Test_Date_From__c <= :bind1 AND (Test_Date_To__c >= :bind1 OR Test_Date_To__c = NULL) ')
                .setQueryBindings(bindings);
    }
}