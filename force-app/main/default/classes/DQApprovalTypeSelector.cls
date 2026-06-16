public inherited sharing class DQApprovalTypeSelector extends SObjectSelector {
    public DQApprovalTypeSelector() {
        super();
    }

    public DQApprovalTypeSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return DQ_Approval_Type__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            DQ_Approval_Type__c.Id,
            DQ_Approval_Type__c.IsActive__c,
            DQ_Approval_Type__c.isUnifiedQuotingApprovalType__c
        };
    }

    private List<Schema.SObjectField> getFieldsForDqGOA() {
        return new List<Schema.SObjectField> {
            DQ_Approval_Type__c.Approval_Type__c,
            DQ_Approval_Type__c.Product_Category__c,
            DQ_Approval_Type__c.Initial_Term_Discount__c,
            DQ_Approval_Type__c.Initial_Term_To_Discount__c,
            DQ_Approval_Type__c.Threshold__c,
            DQ_Approval_Type__c.Special_Terms__c,
            DQ_Approval_Type__c.CC_Special_Terms__c,
            DQ_Approval_Type__c.Free_Shipping_Terms_Options__c,
            DQ_Approval_Type__c.ServiceName__c
        };
    }

    public QueryFactory selectApprovalTypesForDqGOA() {
        return newQueryFactory()
            .setFactoryName('selectApprovalTypesForDqGOA')
            .selectFields(getFieldsForDqGOA())
            .setCondition('IsActive__c = true AND isUnifiedQuotingApprovalType__c = true')
            .addOrdering(DQ_Approval_Type__c.Approval_Type__c, QueryFactory.SortOrder.ASCENDING);
    }
}