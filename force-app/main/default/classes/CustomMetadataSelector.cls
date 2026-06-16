public inherited sharing class CustomMetadataSelector extends SObjectSelector {

    public CustomMetadataSelector() {
        super();
    }

    public CustomMetadataSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return eu_privacy_setup__mdt.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {};
    }

    public List<String> getEUPrivacyList() {
        return new List<String> {
            'DeveloperName', 
            'Restricted__c',
            'Restrict_Based_on_Specific_Account_Brand__c'
        };
    }

    public QueryFactory selectEUPrivacyMDT() {
        return newQueryFactory()
            .setFactoryName('SelectEUPrivacyCustomMetadata')
            .selectFields(getEUPrivacyList());
    }
}