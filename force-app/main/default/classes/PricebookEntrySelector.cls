public inherited sharing class PricebookEntrySelector extends SObjectSelector {

    public PricebookEntrySelector() {
        super();
    }

    public PricebookEntrySelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return PricebookEntry.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            PricebookEntry.Id,
            PricebookEntry.Product2Id,
            PricebookEntry.UnitPrice,
            PricebookEntry.CurrencyIsoCode,
            PricebookEntry.Pricebook2Id
        };
    }

    public List<String> getQuotingToolSyncFields() {
        return new List<String> {
            'Id',
            'IsActive',
            'CurrencyIsoCode',
            'Pricebook2.Name',
            'Product2.Id',
            'Product2.ExtID__c',
            'Product2.IsActive',
            'Product2.GOA_Group_V3__c',
            'Product2.Family',
            'Product2.Feature__c',
            'Product2.Charge_Term__c',
            'Product2.Billing_Type__c',
            'Product2.Group__c',
            'Product2.Subgroup__c',
            'Product2.CategoryName__c',
            'Product2.CategoryCode__c',
            'Product2.ServiceCategory__c',
            'Product2.LicenseGroup__c',
            'Product2.UpsellType__c',
            'Product2.InitialOrderType__c',
            'Product2.ShippingType__c',
            'Product2.DownsellType__c'
        };
    }

    public List<String> getContactCenterFieldList() {
        return new List<String> {
            'Id',
            'Product2Id',
            'UnitPrice',
            'Product2.Name',
            'Product2.Family',
            'Product2.IsActive',
            'Product2.Add_Overages__c',
            'Product2.Charge_Term__c',
            'Product2.Sub_Category__c',
            'Product2.ExtID__c',
            'IsActive',
            'Product2.Edition__c',
            'Product2.Product_Type__c',
            'Product2.Parent__c',
            'Product2.Description',
            'Product2.CatID__c',
            'Pricebook2.isStandard'
        };
    }

    public QueryFactory getContactCenterPBEs(String condition) {
        return newQueryFactory()
            .setFactoryName('selectCCPbes')
            .selectFields(getContactCenterFieldList())
            .setCondition(condition);
    }

    public QueryFactory getAllPBEs() {
        return newQueryFactory()
            .setFactoryName('selectAllPbes')
            .selectFields(getDefaultFieldList());
    }

    public QueryFactory getQuotingToolSyncPBEs(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectQuotingToolSyncPBEs')
            .selectFields(getQuotingToolSyncFields())
            .setCondition(
                'Pricebook2Id = :bind0 ' +
                'AND Product2.ExtID__c IN :bind1 ' +
                'AND CurrencyIsoCode IN :bind2'
            )
            .setQueryBindings(bindings);
    }

    public QueryFactory getActivePBEsForPBId(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('getActivePBEsForPBId')
            .setCondition(
                'Pricebook2Id IN :bind0 ' +
                'AND IsActive = true ' +
                'AND Product2Id IN :bind1'
            )
            .setQueryBindings(bindings);
    }

    public QueryFactory getPBEsByExtIds(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('getPBEsByExtIds')
            .selectFields(getQuotingToolSyncFields())
            .setCondition(
                '(Product2.ExtID__c IN :bind0 ' +
                'OR Product2Id IN :bind1)' +
                'AND Pricebook2Id = :bind2'
            )
            .setQueryBindings(bindings);
    }
}