public inherited sharing class PromotionSelector extends SObjectSelector {

    public PromotionSelector() {
        super();
    }

    public PromotionSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return Promotion__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Promotion__c.Description__c,
            Promotion__c.Name,
            Promotion__c.Start_Date__c,
            Promotion__c.End_Date__c,
            Promotion__c.Discount_Templates__c,
            Promotion__c.Promo_Code__c,
            Promotion__c.Quote__c,
            Promotion__c.Active__c,
            Promotion__c.Promo_Code_Id__c
        };
    }

    public QueryFactory selectPromotions() {
        return newQueryFactory()
            .setFactoryName('selectPromotions')
            .selectFields(getDefaultFieldList());
    }

    public QueryFactory selectPromotionById(Id promotionId) {
        return newQueryFactory()
            .setFactoryName('selectPromotionById')
            .selectFields(getDefaultFieldList())
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object>{new Set<Id> {promotionId}});
    }

    public QueryFactory selectPromotionByQuoteId(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectPromotionByQuoteId')
            .selectFields(getDefaultFieldList())
            .setCondition('Quote__c = :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectAllFieldsForCloning(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectAllFieldsForCloning')
            .selectFields(AquivaHelper.getAllFieldsForObject('Promotion__c'))
            .setCondition('Quote__c IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectPromotionByQuoteName(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectPromotionByQuoteName')
            .selectFields(getDefaultFieldList())
            .setCondition('Quote__r.Name = :bind0')
            .setQueryBindings(bindings);
    }
}