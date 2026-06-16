public inherited sharing class DealQualificationDiscountHistorySelector extends SObjectSelector {
    public DealQualificationDiscountHistorySelector() {
        super();
    }

    public DealQualificationDiscountHistorySelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return DQ_Deal_Qualification_Discount_History__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            DQ_Deal_Qualification_Discount_History__c.Id,
            DQ_Deal_Qualification_Discount_History__c.DQ_Deal_Qualification_History__c,
            DQ_Deal_Qualification_Discount_History__c.Product__c,
            DQ_Deal_Qualification_Discount_History__c.Discount__c,
            DQ_Deal_Qualification_Discount_History__c.Quantity__c,
            DQ_Deal_Qualification_Discount_History__c.PackageName__c,
            DQ_Deal_Qualification_Discount_History__c.PackageId__c,
            DQ_Deal_Qualification_Discount_History__c.PackageVersion__c,
            DQ_Deal_Qualification_Discount_History__c.Group__c,
            DQ_Deal_Qualification_Discount_History__c.Subgroup__c,
            DQ_Deal_Qualification_Discount_History__c.Service__c
        };
    }

    private List<String> getFieldsForDqGOA() {
        return new List<String> {
            'Product_Category__c',
            'Product_Package__c',
            'Product__r.Name',
            'Product__r.Group__c',
            'Product__r.Subgroup__c',
            'Product__c',
            'Quantity__c',
            'Discount__c',
            'DQ_Deal_Qualification_History__r.Initial_Term__c',
            'DQ_Deal_Qualification_History__r.Renewal_Term__c',
            'DQ_Deal_Qualification_History__r.Overall_Discount__c',
            'PackageId__c',
            'PackageVersion__c',
            'PackageName__c',
            'Group__c',
            'Subgroup__c',
            'Service__c'
        };
    }

    public QueryFactory selectDQDiscountHistory() {
        return newQueryFactory()
            .setFactoryName('selectDQDiscountHistory')
            .selectFields(getFieldsForDqGOA())
            .withoutSelectorOrderByIncluded();
    }
}