public inherited sharing class DealQualificationApproverSelector extends SObjectSelector {
    public DealQualificationApproverSelector() {
        super();
    }

    public DealQualificationApproverSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return DQ_Deal_Qualification_Approver__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            DQ_Deal_Qualification_Approver__c.Id,
            DQ_Deal_Qualification_Approver__c.Deal_Qualification__c,
            DQ_Deal_Qualification_Approver__c.Status__c
        };
    }

    public List<String> getFieldsForDqGOA() {
        return new List<String> {
            'Id',
            'Submitted_Order__c',
            'Step_Order__c',
            'Approval_Step__r.Name',
            'Submitted_Date__c',
            'Status__c',
            'Owner.Name',
            'OwnerId',
            'Approved_By__r.Name',
            'Approve_Reject_Date__c',
            'Approval_Reason__c',
            'Comments__c',
            'CreatedBy.Name',
            'Deal_Qualification__c',
            'CreatedDate'
        };
    }

    public List<String> getFieldsForDqWidget() {
        return new List<String> {
            'Id',
            'Submitted_Date__c',
            'Status__c',
            'Approved_By__r.Name',
            'Approve_Reject_Date__c',
            'Approval_Reason__c',
            'Comments__c',
            'Deal_Qualification__c',
            'Deal_Qualification__r.Opportunity__c',
            'Deal_Qualification__r.Quote__c'
        };
    }

    public QueryFactory selectDQApprovers() {
        return newQueryFactory()
            .setFactoryName('selectDQApprovers')
            .selectFields(getFieldsForDqGOA());
    }

    public QueryFactory selectDQApprovers(Id dealQualificationId) {
        return newQueryFactory()
            .setFactoryName('selectDQApprover')
            .selectFields(getFieldsForDqGOA())
            .setCondition('Deal_Qualification__c = :bind0')
            .setQueryBindings(new List<Object>{dealQualificationId});
    }

    public QueryFactory selectDQApproverById(Id dealQualificationApproverId) {
        return newQueryFactory()
            .setFactoryName('selectDQApproversByIds')
            .selectFields(getFieldsForDqGOA())
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object>{dealQualificationApproverId});
    }

    public QueryFactory selectDQApproversSubmitOrder(Id dealQualificationId, Decimal submittedOrder) {
        return newQueryFactory()
            .setFactoryName('selectDQApproversSubmitOrder')
            .selectFields(getFieldsForDqGOA())
            .setCondition('Deal_Qualification__c = :bind0 AND Submitted_Order__c = :bind1 AND Status__c NOT IN (:bind2,:bind3)')
            .setQueryBindings(new List<Object>{dealQualificationId,submittedOrder,DQGoa.APPROVED_STATUS,DQGoa.APPROVER_NOTIFICATION_TYPE_NOTIFICATION});
    }

    public QueryFactory selectDQApproversOrder(Id dealQualificationId) {
        return newQueryFactory()
            .setFactoryName('selectDQApproversOrder')
            .selectFields(getFieldsForDqGOA())
            .withoutSelectorOrderByIncluded()
            .setCondition('Deal_Qualification__c = :bind0')
            .addOrdering(DQ_Deal_Qualification_Approver__c.Submitted_Order__c, QueryFactory.SortOrder.DESCENDING)
            .setQueryBindings(new List<Object>{dealQualificationId});
    }

    public QueryFactory selectDQApproversForDQWidget(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectDQApproverDQWidget')
            .selectFields(getFieldsForDqWidget())
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectPendingApproversByDQIds(Set<Id> dqIds, String status) {
        return newQueryFactory()
            .setFactoryName('selectPendingApproversByDQIds')
            .selectFields(new List<Schema.SObjectField> {
                DQ_Deal_Qualification_Approver__c.Deal_Qualification__c
            })
            .setCondition('Deal_Qualification__c IN :bind0 AND Status__c = :bind1')
            .setQueryBindings(new List<Object>{dqIds, status});
    }
}