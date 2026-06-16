public inherited sharing class DealDeskCaseDescriptionSelector extends SObjectSelector {

    public DealDeskCaseDescriptionSelector() {
        super();
    }

    public DealDeskCaseDescriptionSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType() {
        return DealDeskCaseDescription__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            DealDeskCaseDescription__c.Id,
            DealDeskCaseDescription__c.CaseOwner__c,
            DealDeskCaseDescription__c.CaseDescription__c,
            DealDeskCaseDescription__c.Account__c,
            DealDeskCaseDescription__c.Subject__c
        };
    }

    public QueryFactory selectDealDeskCaseDescriptionsForAccounts(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectDealDeskCaseDescriptionsForAccounts')
            .selectFields(getDefaultFieldList())
            .selectFields(new List<String> {'Account__r.Most_Recent_Opportunity_Owner__c'})
            .setCondition('Account__c IN :bind0')
            .setQueryBindings(bindings);
    }
}