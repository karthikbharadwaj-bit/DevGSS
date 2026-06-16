public inherited sharing class DealQualificationServiceDiscountSelector extends SObjectSelector {
    public DealQualificationServiceDiscountSelector() {
        super();
    }

    public DealQualificationServiceDiscountSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return DQ_Deal_Qualification_Service_Discount__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            DQ_Deal_Qualification_Service_Discount__c.Id,
            DQ_Deal_Qualification_Service_Discount__c.Deal_Qualification__c,
            DQ_Deal_Qualification_Service_Discount__c.Service__c,
            DQ_Deal_Qualification_Service_Discount__c.Discretion__c,
            DQ_Deal_Qualification_Service_Discount__c.WeightedDiscount__c,
            DQ_Deal_Qualification_Service_Discount__c.EESRemoval__c,
            DQ_Deal_Qualification_Service_Discount__c.FreeServiceCredit__c,
            DQ_Deal_Qualification_Service_Discount__c.CreatedDate
        };
    }

    public QueryFactory selectDQServiceDiscountsForSync() {
        return newQueryFactory()
            .setFactoryName('selectDQServiceDiscountsForSync')
            .selectFields(getDefaultFieldList())
            .withoutSelectorOrderByIncluded();
    }
}