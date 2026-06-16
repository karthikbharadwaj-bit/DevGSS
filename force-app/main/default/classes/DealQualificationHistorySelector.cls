public inherited sharing class DealQualificationHistorySelector extends SObjectSelector {
    public DealQualificationHistorySelector() {
        super();
    }

    public DealQualificationHistorySelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return DQ_Deal_Qualification_History__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            DQ_Deal_Qualification_History__c.Id,
            DQ_Deal_Qualification_History__c.Deal_Qualification__c,
            DQ_Deal_Qualification_History__c.Status__c
        };
    }

    private List<Schema.SObjectField> getFieldsForDqGOA() {
        return new List<Schema.SObjectField> {
            DQ_Deal_Qualification_History__c.Id,
            DQ_Deal_Qualification_History__c.Auto_Renewal__c,
            DQ_Deal_Qualification_History__c.Initial_Term__c,
            DQ_Deal_Qualification_History__c.Renewal_Term__c,
            DQ_Deal_Qualification_History__c.Special_Terms__c,
            DQ_Deal_Qualification_History__c.CC_Special_Terms__c,
            DQ_Deal_Qualification_History__c.Free_Shipping_Terms_Options__c,
            DQ_Deal_Qualification_History__c.Overall_Discount__c,
            DQ_Deal_Qualification_History__c.Overall_Discount_One_Time__c,
            DQ_Deal_Qualification_History__c.Overall_Discount_Recurring__c,
            DQ_Deal_Qualification_History__c.Overall_Discount_Contact_Center__c,
            DQ_Deal_Qualification_History__c.Is_ELA__c,
            DQ_Deal_Qualification_History__c.Maximum_Potential__c,
            DQ_Deal_Qualification_History__c.Charge_Term__c,
            DQ_Deal_Qualification_History__c.ELA_Initial_Terms__c,
            DQ_Deal_Qualification_History__c.Deal_Size__c,
            DQ_Deal_Qualification_History__c.Family_Discount__c
        };
    }

    private List<Schema.SObjectField> getFieldsForDqStatusUpdate() {
        return new List<Schema.SObjectField> {
            DQ_Deal_Qualification_History__c.Brand__c,
            DQ_Deal_Qualification_History__c.Deal_Size__c,
            DQ_Deal_Qualification_History__c.Deal_Type__c,
            DQ_Deal_Qualification_History__c.Deal_Qualification__c,
            DQ_Deal_Qualification_History__c.Minimum_Package_s__c,
            DQ_Deal_Qualification_History__c.Number_of_DLs__c,
            DQ_Deal_Qualification_History__c.Overall_Discount__c,
            DQ_Deal_Qualification_History__c.Overall_Discount_One_Time__c,
            DQ_Deal_Qualification_History__c.Overall_Discount_Recurring__c,
            DQ_Deal_Qualification_History__c.CC_Special_Terms__c,
            DQ_Deal_Qualification_History__c.Overall_Discount_Contact_Center__c,
            DQ_Deal_Qualification_History__c.Initial_Term__c,
            DQ_Deal_Qualification_History__c.Region__c,
            DQ_Deal_Qualification_History__c.Status__c,
            DQ_Deal_Qualification_History__c.Segment__c,
            DQ_Deal_Qualification_History__c.Charge_Term__c,
            DQ_Deal_Qualification_History__c.Special_Terms__c,
            DQ_Deal_Qualification_History__c.Free_Shipping_Terms_Options__c,
            DQ_Deal_Qualification_History__c.CC_Initial_Term__c,
            DQ_Deal_Qualification_History__c.Is_ELA__c,
            DQ_Deal_Qualification_History__c.Roll_Out_Plan__c,
            DQ_Deal_Qualification_History__c.Start_Date__c,
            DQ_Deal_Qualification_History__c.True_Up_Terms__c,
            DQ_Deal_Qualification_History__c.Maximum_Potential__c,
            DQ_Deal_Qualification_History__c.Minimum_Baseline__c,
            DQ_Deal_Qualification_History__c.ELA_Initial_Terms__c,
            DQ_Deal_Qualification_History__c.Additional_Info__c,
            DQ_Deal_Qualification_History__c.IsDQCreatedFromCPQOpp__c,
            DQ_Deal_Qualification_History__c.Family_Discount__c
        };
    }

    public QueryFactory selectApprovedDQHistory(Id dealQualificationId) {
        return newQueryFactory()
            .setFactoryName('selectApprovedDQHistory')
            .selectFields(getFieldsForDqGOA())
            .subselect(new DealQualificationDiscountHistorySelector().selectDQDiscountHistory())
            .subselect(new DQServiceDiscountHistorySelector().selectDQServiceDiscountHistory())
            .setCondition('Status__c = \'Approved\' AND Deal_Qualification__c = :bind0')
            .setQueryBindings(new List<Object>{dealQualificationId});
    }

    public QueryFactory selectAllFieldsForCloning(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectAllFieldsForCloning')
            .selectFields(AquivaHelper.getAllFieldsForObject('DQ_Deal_Qualification_History__c'))
            .setCondition('Deal_Qualification__c IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectDQHistoryOnDQStatusUpdate(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectDQHistoryOnDQStatusUpdate')
            .selectFields(getFieldsForDqStatusUpdate())
            .subselect(new DealQualificationDiscountHistorySelector().selectDQDiscountHistory())
            .subselect(new DQServiceDiscountHistorySelector().selectDQServiceDiscountHistory())
            .setCondition('Deal_Qualification__c IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectDQHistory() {
        return newQueryFactory()
            .setFactoryName('selectDQHistory')
            .selectFields(getDefaultFieldList())
            .subselect(new DQServiceDiscountHistorySelector().selectDQServiceDiscountHistory());
    }
}