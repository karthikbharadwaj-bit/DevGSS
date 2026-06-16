public inherited sharing class ContractDiscountSelector extends SObjectSelector {

    public ContractDiscountSelector() {
        super();
    }

    public ContractDiscountSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType() {
        return Contract_Discount__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Contract_Discount__c.Id,
            Contract_Discount__c.Name,
            Contract_Discount__c.ApplicableTo__c,
            Contract_Discount__c.Contract__c,
            Contract_Discount__c.Duration__c,
            Contract_Discount__c.Discount__c,
            Contract_Discount__c.CurrencyIsoCode
        };
    }

    public QueryFactory selectContractDiscounts() {
        return newQueryFactory()
            .setFactoryName('selectContractDiscounts');
    }
}