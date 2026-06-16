public inherited sharing class PdfHierarchySettingsSelector extends SObjectSelector {
    public PdfHierarchySettingsSelector() {
        super();
    }

    public PdfHierarchySettingsSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return PdfHierarchySettings__mdt.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            PdfHierarchySettings__mdt.Id,
            PdfHierarchySettings__mdt.Parent__c,
            PdfHierarchySettings__mdt.Childs__c
        };
    }

    public QueryFactory selectPdfHierarchySettings() {
        return newQueryFactory()
            .setFactoryName('selectPdfHierarchySettings')
            .withSelectorFieldsIncluded()
            .setQueryCaching(true)
            .withoutSelectorOrderByIncluded();
    }
}