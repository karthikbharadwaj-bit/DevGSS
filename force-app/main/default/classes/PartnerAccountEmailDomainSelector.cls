public inherited sharing class PartnerAccountEmailDomainSelector extends SObjectSelector {

    public PartnerAccountEmailDomainSelector() {
        super();
    }

    public override Schema.SObjectType getSObjectType() {
        return PartnerAccountEmailDomain__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            PartnerAccountEmailDomain__c.Email_Domain__c
        };
    }

    public QueryFactory selectPartnerAccountEmailDomainRecords() {
        return newQueryFactory()
            .setFactoryName('selectPartnerAccountEmailDomainRecords')
            .selectFields(getDefaultFieldList());
    }
}