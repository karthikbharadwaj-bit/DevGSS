public inherited sharing class NGBSProcessOrderCaseTemplateSelector extends SObjectSelector {

    public NGBSProcessOrderCaseTemplateSelector() {
        super();
    }

    public override Schema.SObjectType getSObjectType() {
        return NGBSProcessOrderCaseTemplate__mdt.SObjectType;
    }

    public override List<Schema.SobjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            NGBSProcessOrderCaseTemplate__mdt.Id,
            NGBSProcessOrderCaseTemplate__mdt.IsActive__c,
            NGBSProcessOrderCaseTemplate__mdt.IsProServSold__c,
            NGBSProcessOrderCaseTemplate__mdt.Type__c,
            NGBSProcessOrderCaseTemplate__mdt.Owner__c,
            NGBSProcessOrderCaseTemplate__mdt.Subject__c,
            NGBSProcessOrderCaseTemplate__mdt.Description__c,
            NGBSProcessOrderCaseTemplate__mdt.Instruction__c,
            NGBSProcessOrderCaseTemplate__mdt.LicenceIdOrCategoryCode__c,
            NGBSProcessOrderCaseTemplate__mdt.ShippingReq__c,
            NGBSProcessOrderCaseTemplate__mdt.InitialOrderType__c,
            NGBSProcessOrderCaseTemplate__mdt.UpsellType__c,
            NGBSProcessOrderCaseTemplate__mdt.DownsellType__c
        };
    }

    public QueryFactory selectActiveNGBSProcessOrderCaseTemplates() {
        return newQueryFactory()
            .setFactoryName('selectActiveNGBSProcessOrderCaseTemplates')
            .selectFields(this.getDefaultFieldList())
            .setCondition('IsActive__c = true');
    }

    public QueryFactory selectSpecifiedSorterActiveNGBSProcessOrderCaseTemplates(Set<String> types) {
        return newQueryFactory()
            .setFactoryName('selectSpecifiedNGBSProcessOrderCaseTemplates')
            .selectFields(this.getDefaultFieldList())
            .setCondition('IsActive__c = true AND Type__c IN :bind0')
            .setQueryBindings(new List<Object> { types })
            .withSelectorOrderByIncluded()
            .addOrdering('LicenceIdOrCategoryCode__c', QueryFactory.SortOrder.DESCENDING, false)
            .addOrdering('Type__c', QueryFactory.SortOrder.DESCENDING);
    }
}