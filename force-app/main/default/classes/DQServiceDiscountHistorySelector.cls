public inherited sharing class DQServiceDiscountHistorySelector extends SObjectSelector {
    public DQServiceDiscountHistorySelector() {
        super();
    }

    public DQServiceDiscountHistorySelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return DQ_Service_Discount_History__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            DQ_Service_Discount_History__c.Id,
            DQ_Service_Discount_History__c.DQ_Deal_Qualification_History__c,
            DQ_Service_Discount_History__c.Discretion__c,
            DQ_Service_Discount_History__c.EESRemoval__c,
            DQ_Service_Discount_History__c.FreeServiceCredit__c,
            DQ_Service_Discount_History__c.Service__c,
            DQ_Service_Discount_History__c.WeightedDiscount__c
        };
    }

    public QueryFactory selectDQServiceDiscountHistory() {
        return newQueryFactory()
            .setFactoryName('selectDQServiceDiscountHistory')
            .selectFields(getDefaultFieldList())
            .withoutSelectorOrderByIncluded();
    }
}