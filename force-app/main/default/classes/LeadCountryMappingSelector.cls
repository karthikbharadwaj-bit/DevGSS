public inherited sharing class LeadCountryMappingSelector extends SObjectSelector {

    public LeadCountryMappingSelector() {
        super();
    }

    public override Schema.SObjectType getSObjectType() {
        return Lead_Country_Mapping__mdt.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Lead_Country_Mapping__mdt.Label,
            Lead_Country_Mapping__mdt.Country_Name__c,
            Lead_Country_Mapping__mdt.Currency__c,
            Lead_Country_Mapping__mdt.Is_Active__c
        };
    }

    public QueryFactory selectActiveCountryMappings() {
        return newQueryFactory()
            .setFactoryName('selectActiveLeadCountryMappings')
            .selectFields(this.getDefaultFieldList())
            .setCondition('Is_Active__c = true');
    }
}