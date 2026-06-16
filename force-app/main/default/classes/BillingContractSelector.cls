public inherited sharing class BillingContractSelector extends SObjectSelector {

    public BillingContractSelector() {
        super();
    }

    public BillingContractSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType() {
        return Contract__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Contract__c.Id,
            Contract__c.ExtID__c
        };
    }

    public List<Schema.SObjectField> getFieldsForPostCopying() {
        return new List<Schema.SObjectField> {
            Contract__c.Id,
            Contract__c.Name,
            Contract__c.ExtID__c,
            Contract__c.Active__c,
            Contract__c.Available_in_packages__c,
            Contract__c.Billing_Countries__c,
            Contract__c.Business_Identities_Countries__c,
            Contract__c.CurrencyIsoCode
        };
    }

    public QueryFactory selectContractWithDiscounts() {
        return newQueryFactory()
            .setFactoryName('selectContractWithDiscounts')
            .subselect(
                new ContractDiscountSelector()
                    .selectContractDiscounts()
            );
    }

    public QueryFactory selectContracts() {
        return newQueryFactory()
            .setFactoryName('selectContracts');
    }

    public QueryFactory selectContractWithDiscountsById(Object id) {
        return newQueryFactory()
            .setFactoryName('selectContractWithDiscountsById')
            .subselect(
                new ContractDiscountSelector()
                    .selectContractDiscounts()
            )
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object>{ id });
    }

    public QueryFactory selectContractsWithDiscounts() {
        return newQueryFactory()
            .setFactoryName('selectContractsWithDiscounts')
            .selectFields(getFieldsForPostCopying())
            .subselect(
                new ContractDiscountSelector()
                    .selectContractDiscounts()
            );
    }
}