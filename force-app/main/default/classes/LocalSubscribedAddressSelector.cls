public inherited sharing class LocalSubscribedAddressSelector extends SObjectSelector {
    public LocalSubscribedAddressSelector() {
        super();
    }

    public LocalSubscribedAddressSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return LocalSubscribedAddress__c.SObjectType;
    }

    public override List<SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField>{
            LocalSubscribedAddress__c.Id,
            LocalSubscribedAddress__c.Approval__c,
            LocalSubscribedAddress__c.Area__c,
            LocalSubscribedAddress__c.City__c,
            LocalSubscribedAddress__c.District__c,
            LocalSubscribedAddress__c.HouseNo__c,
            LocalSubscribedAddress__c.InspectionDate__c,
            LocalSubscribedAddress__c.Landmark__c,
            LocalSubscribedAddress__c.LatitudeLongitude__c,
            LocalSubscribedAddress__c.LatitudeLongitudeEvery6Months__c,
            LocalSubscribedAddress__c.Name,
            LocalSubscribedAddress__c.PinCode__c,
            LocalSubscribedAddress__c.RecordTypeId,
            LocalSubscribedAddress__c.RevisionDate__c,
            LocalSubscribedAddress__c.State__c,
            LocalSubscribedAddress__c.StreetAddress__c
        };
    }

    public List<SObjectField> getBillingAddressFields() {
        return new List<Schema.SObjectField>{
            LocalSubscribedAddress__c.Approval__c,
            LocalSubscribedAddress__c.City__c,
            LocalSubscribedAddress__c.District__c,
            LocalSubscribedAddress__c.PinCode__c,
            LocalSubscribedAddress__c.RecordTypeId,
            LocalSubscribedAddress__c.State__c,
            LocalSubscribedAddress__c.StreetAddress__c
        };
    }

    public QueryFactory selectLocalSubscribedAddresses() {
        return newQueryFactory()
            .setFactoryName('selectLocalSubscribedAddresses');
    }

    public QueryFactory selectLocalSubscribedAddressesByApprovals(Id recordTypeId, List<Object> bindings) {
        return selectLocalSubscribedAddresses()
            .setFactoryName('selectLocalSubscribedAddressesByApprovals')
            .withSelectorFieldsIncluded()
            .selectFields(getDefaultFieldList())
            .withoutSelectorOrderByIncluded()
            .setCondition('RecordTypeId = \'' + recordTypeId + '\' AND Approval__c IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectLocalSubscribedAddressByApprovalId(List<Object> approvalIds) {
        return selectLocalSubscribedAddresses()
            .setFactoryName('selectLocalSubscribedAddressByApprovalId')
            .selectFields(getDefaultFieldList())
            .setCondition('Approval__c IN :bind0')
            .setQueryBindings(approvalIds);
    }

    public QueryFactory selectLocalSubscribedAddressesBillingAddressByApprovals(List<Object> approvalIds) {
        return newQueryFactory()
            .setFactoryName('selectLocalSubscribedAddressesBillingAddress')
            .selectFields(getBillingAddressFields())
            .setCondition('Approval__c IN :bind0 AND ' +
                'RecordTypeId = \'' + LocalSubscribedAddressHelper.RT_ID_BILLING_ADDRESS + '\'')
            .setQueryBindings(approvalIds);
    }
}