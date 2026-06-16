public inherited sharing class DealQualificationDiscountSelector extends SObjectSelector {
    public DealQualificationDiscountSelector() {
        super();
    }

    public DealQualificationDiscountSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return DQ_Deal_Qualification_Discounts__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            DQ_Deal_Qualification_Discounts__c.Id,
            DQ_Deal_Qualification_Discounts__c.Deal_Qualification__c,
            DQ_Deal_Qualification_Discounts__c.Product__c,
            DQ_Deal_Qualification_Discounts__c.Discount__c,
            DQ_Deal_Qualification_Discounts__c.Quantity__c,
            DQ_Deal_Qualification_Discounts__c.CreatedDate,
            DQ_Deal_Qualification_Discounts__c.Promo_Code__c
        };
    }

    public List<Schema.SObjectField> getFieldsForDqSync() {
        return new List<Schema.SObjectField> {
            DQ_Deal_Qualification_Discounts__c.RecordTypeId,
            DQ_Deal_Qualification_Discounts__c.Discount_Type__c,
            DQ_Deal_Qualification_Discounts__c.Product_Category__c,
            DQ_Deal_Qualification_Discounts__c.OriginalPackageId__c,
            DQ_Deal_Qualification_Discounts__c.OriginalPackageVersion__c,
            DQ_Deal_Qualification_Discounts__c.OriginalPackageName__c,
            DQ_Deal_Qualification_Discounts__c.PackageName__c,
            DQ_Deal_Qualification_Discounts__c.Group__c,
            DQ_Deal_Qualification_Discounts__c.Service__c,
            DQ_Deal_Qualification_Discounts__c.Subgroup__c
        };
    }

    public List<Schema.SObjectField> getFieldsForDqStatusUpdate() {
        return new List<Schema.SObjectField> {
            DQ_Deal_Qualification_Discounts__c.Discount__c,
            DQ_Deal_Qualification_Discounts__c.Discount_Type__c,
            DQ_Deal_Qualification_Discounts__c.Product__c,
            DQ_Deal_Qualification_Discounts__c.Product_Category__c,
            DQ_Deal_Qualification_Discounts__c.Product_Family__c,
            DQ_Deal_Qualification_Discounts__c.Product_Sub_Categories__c,
            DQ_Deal_Qualification_Discounts__c.Quantity__c,
            DQ_Deal_Qualification_Discounts__c.Product_Package__c,
            DQ_Deal_Qualification_Discounts__c.PackageName__c,
            DQ_Deal_Qualification_Discounts__c.OriginalPackageId__c,
            DQ_Deal_Qualification_Discounts__c.OriginalPackageVersion__c,
            DQ_Deal_Qualification_Discounts__c.CPQ_Configured_Product__c,
            DQ_Deal_Qualification_Discounts__c.Group__c,
            DQ_Deal_Qualification_Discounts__c.Service__c,
            DQ_Deal_Qualification_Discounts__c.Subgroup__c
        };
    }

    private List<String> getProductFields() {
        return new List<String>{
            'Product__r.Name',
            'Product__r.Group__c',
            'Product__r.Subgroup__c'
        };
    }

    public QueryFactory selectDQDiscountsForSync() {
        return newQueryFactory()
            .setFactoryName('selectDQDiscountsForSync')
            .selectFields(getFieldsForDqSync())
            .selectFields(getProductFields())
            .withoutSelectorOrderByIncluded();
    }

    public QueryFactory selectDQDiscountsForDQStatusUpdate() {
        return newQueryFactory()
            .setFactoryName('selectDQDiscountsForDQStatusUpdate')
            .selectFields(getFieldsForDqStatusUpdate())
            .selectFields(getProductFields())
            .withoutSelectorOrderByIncluded();
    }

    public QueryFactory selectAllFieldsForCloning(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectAllFieldsForCloning')
            .selectFields(AquivaHelper.getAllFieldsForObject('DQ_Deal_Qualification_Discounts__c'))
            .selectFields(getProductFields())
            .setCondition('Deal_Qualification__c IN :bind0')
            .setQueryBindings(bindings);
    }
}