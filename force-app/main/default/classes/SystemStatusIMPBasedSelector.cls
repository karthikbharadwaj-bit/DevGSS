public inherited sharing class SystemStatusIMPBasedSelector extends SObjectSelector {

    public SystemStatusIMPBasedSelector() {
        super();
    }

    public SystemStatusIMPBasedSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType() {
        return System_Status_IMP_Based__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            System_Status_IMP_Based__c.Id,
            System_Status_IMP_Based__c.Level__c,
            System_Status_IMP_Based__c.IncidentId__c,
            System_Status_IMP_Based__c.Date__c,
            System_Status_IMP_Based__c.Description__c,
            System_Status_IMP_Based__c.PODs_Affected__c,
            System_Status_IMP_Based__c.Services_Affected__c,
            System_Status_IMP_Based__c.Categories__c,
            System_Status_IMP_Based__c.Brands__c,
            System_Status_IMP_Based__c.Message__c,
            System_Status_IMP_Based__c.inContact_Cluster__c,
            System_Status_IMP_Based__c.Regions__c,
            System_Status_IMP_Based__c.Status__c,
            System_Status_IMP_Based__c.CreatedDate
        };
    }

    public List<Schema.SObjectField> getInitFieldsList() {
        return new List<Schema.SObjectField> {
            System_Status_IMP_Based__c.Id,
            System_Status_IMP_Based__c.IncidentId__c,
            System_Status_IMP_Based__c.CreatedDate
        };
    }

    public QueryFactory selectSystemStatusesByIds(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectSystemStatusesByIds')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectSystemStatuses() {
        return newQueryFactory()
            .setFactoryName('selectSystemStatuses')
            .selectFields(getInitFieldsList());
    }

}