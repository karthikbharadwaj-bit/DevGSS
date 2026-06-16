public inherited sharing class NGBSBusinessIdentityOverrideSelector extends SObjectSelector {

    public NGBSBusinessIdentityOverrideSelector() {
        super();
    }

    public override Schema.SObjectType getSObjectType() {
        return NGBS_Business_Identity_Override__mdt.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            NGBS_Business_Identity_Override__mdt.Label,
            NGBS_Business_Identity_Override__mdt.Brand__c,
            NGBS_Business_Identity_Override__mdt.Billing_Country__c,
            NGBS_Business_Identity_Override__mdt.Business_Identity_ID__c,
            NGBS_Business_Identity_Override__mdt.ListOfPackageIDs__c
        };
    }

    public QueryFactory selectActiveBusinessIdentityOverrides() {
        return newQueryFactory()
            .setFactoryName('selectActiveBusinessIdentityOverrides')
            .selectFields(this.getDefaultFieldList())
            .setCondition('Is_Active__c = true');
    }
}