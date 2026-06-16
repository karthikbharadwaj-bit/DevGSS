public inherited sharing class PackageMainLicensesSelector extends SObjectSelector {

    public PackageMainLicensesSelector() {
        super();
    }

    public override Schema.SObjectType getSObjectType() {
        return Package_Main_Licenses__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Package_Main_Licenses__c.Package_ID__c,
            Package_Main_Licenses__c.Package_Group__c,
            Package_Main_Licenses__c.Main_License__c
        };
    }

    public QueryFactory selectPackageMainLicensesRecords() {
        return newQueryFactory()
            .setFactoryName('selectPackageMainLicensesRecords')
            .selectFields(this.getDefaultFieldList());
    }
}