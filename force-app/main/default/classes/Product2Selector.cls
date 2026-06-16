public inherited sharing class Product2Selector extends SObjectSelector {
    public Product2Selector() {
        super();
    }

    public Product2Selector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return Product2.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Product2.Id,
            Product2.Name,
            Product2.Feature__c,
            Product2.ExtID__c
        };
    }

    public List<String> getFieldsForSyncWithNGBS() {
        return new List<String>{
            'Id',
            'Name'
        };
    }

    public List<String> getFieldsForQLITrigger(){
        return new List<String>{
            'Id',
            'Name',
            'Family',
            'Feature__c',
            'Sub_Feature__c',
            'Sub_Category__c',
            'Charge_Term__c',
            'ExtID__c'
        };
    }

    public QueryFactory selectProductsForQLITrigger(Object productsIdSet){
        List<Object> bindings = new List<Object>{productsIdSet};
        return newQueryFactory()
            .setFactoryName('selectProductsForQLITrigger')
            .selectFields(getFieldsForQLITrigger())
            .withoutSelectorOrderByIncluded()
            .setCondition('Id IN: bind0')
            .setQueryBindings(bindings);

    }

    public List<String> getFieldsForQLICaseDescription(){
        return new List<String>{
            'Id',
            'Name',
            'DownsellType__c',
            'Charge_Term__c',
            'ExtID__c'
        };
    }

    public QueryFactory selectProducts() {
        return newQueryFactory()
            .setFactoryName('SelectProducts')
            .withSelectorFieldsIncluded();
    }

    public QueryFactory selectProductsForSortOrderUpdates(Object productsIdSet) {
        List<Object> bindings = new List<Object>{productsIdSet};
        return newQueryFactory()
            .setFactoryName('selectProductsForSortOrderUpdates')
            .selectFields(getFieldsForSyncWithNGBS())
            .setCondition('Id IN: bind0')
            .setQueryBindings(bindings);
    }
}