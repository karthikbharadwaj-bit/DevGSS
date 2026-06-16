public inherited sharing class DealQualificationSelector extends SObjectSelector {
    public DealQualificationSelector() {
        super();
    }

    public DealQualificationSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return DQ_Deal_Qualification__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            DQ_Deal_Qualification__c.Id,
            DQ_Deal_Qualification__c.Opportunity__c,
            DQ_Deal_Qualification__c.Name,
            DQ_Deal_Qualification__c.Status__c,
            DQ_Deal_Qualification__c.Opportunity_Owner_s_Email__c
        };
    }

    @TestVisible
    private List<Schema.SObjectField> getFieldsForSync() {
        return new List<Schema.SObjectField> {
            DQ_Deal_Qualification__c.Additional_Info__c,
            DQ_Deal_Qualification__c.Auto_Renewal__c,
            DQ_Deal_Qualification__c.CC_Initial_Term__c,
            DQ_Deal_Qualification__c.CC_Special_Terms__c,
            DQ_Deal_Qualification__c.Charge_Term__c,
            DQ_Deal_Qualification__c.Cost_of_One_Time_items__c,
            DQ_Deal_Qualification__c.Deal_Size__c,
            DQ_Deal_Qualification__c.ELA_Initial_Terms__c,
            DQ_Deal_Qualification__c.Free_Shipping_Terms_Options__c,
            DQ_Deal_Qualification__c.Global_Office_Location__c,
            DQ_Deal_Qualification__c.Initial_Term__c,
            DQ_Deal_Qualification__c.Is_ELA__c,
            DQ_Deal_Qualification__c.IsDQCreatedFromCPQOpp__c,
            DQ_Deal_Qualification__c.Justification_Description__c,
            DQ_Deal_Qualification__c.Maximum_Potential__c,
            DQ_Deal_Qualification__c.Minimum_Baseline__c,
            DQ_Deal_Qualification__c.New_Annual_Recurring_Charges__c,
            DQ_Deal_Qualification__c.Overall_Discount__c,
            DQ_Deal_Qualification__c.Overall_Discount_One_Time__c,
            DQ_Deal_Qualification__c.Overall_Discount_Recurring__c,
            DQ_Deal_Qualification__c.Quote__c,
            DQ_Deal_Qualification__c.Renewal_Term__c,
            DQ_Deal_Qualification__c.Special_Terms__c,
            DQ_Deal_Qualification__c.Start_Date__c,
            DQ_Deal_Qualification__c.True_Up_Terms__c,
            DQ_Deal_Qualification__c.Family_Discount__c
        };
    }

    private List<Schema.SObjectField> getFieldsForDQGOA() {
        return new List<Schema.SObjectField> {
            DQ_Deal_Qualification__c.Auto_Renewal__c,
            DQ_Deal_Qualification__c.CC_Special_Terms__c,
            DQ_Deal_Qualification__c.Charge_Term__c,
            DQ_Deal_Qualification__c.Deal_Size__c,
            DQ_Deal_Qualification__c.ELA_Initial_Terms__c,
            DQ_Deal_Qualification__c.Free_Shipping_Terms_Options__c,
            DQ_Deal_Qualification__c.Initial_Term__c,
            DQ_Deal_Qualification__c.is_ELA__c,
            DQ_Deal_Qualification__c.Maximum_Potential__c,
            DQ_Deal_Qualification__c.Overall_Discount__c,
            DQ_Deal_Qualification__c.Overall_Discount_Contact_Center__c,
            DQ_Deal_Qualification__c.Overall_Discount_One_Time__c,
            DQ_Deal_Qualification__c.Overall_Discount_Recurring__c,
            DQ_Deal_Qualification__c.Quote__c,
            DQ_Deal_Qualification__c.Renewal_Term__c,
            DQ_Deal_Qualification__c.Special_Terms__c,
            DQ_Deal_Qualification__c.CC_Initial_Term__c,
            DQ_Deal_Qualification__c.Family_Discount__c
        };
    }

    private List<String> getOpportunityFields() {
        return new List<String>{
            'Opportunity__r.Owner.Region__c',
            'Opportunity__r.Owner.Sub_Region__c',
            'Opportunity__r.Owner.SegmentPicklist__c',
            'Opportunity__r.RecordType.Name',
            'Opportunity__r.Brand_Name__c',
            'Opportunity__r.Segment_Name__c',
            'Opportunity__r.Tier_Name__c'
        };
    }

    @TestVisible
    private List<Schema.SObjectField> getFieldsForStatusUpdate() {
        return new List<Schema.SObjectField> {
            DQ_Deal_Qualification__c.Brand__c,
            DQ_Deal_Qualification__c.Deal_Size__c,
            DQ_Deal_Qualification__c.Deal_Type__c,
            DQ_Deal_Qualification__c.Minimum_Package_s__c,
            DQ_Deal_Qualification__c.Number_of_DLs__c,
            DQ_Deal_Qualification__c.Overall_Discount__c,
            DQ_Deal_Qualification__c.Overall_Discount_One_Time__c,
            DQ_Deal_Qualification__c.Overall_Discount_Recurring__c,
            DQ_Deal_Qualification__c.CC_Special_Terms__c,
            DQ_Deal_Qualification__c.Overall_Discount_Contact_Center__c,
            DQ_Deal_Qualification__c.Initial_Term__c,
            DQ_Deal_Qualification__c.Region__c,
            DQ_Deal_Qualification__c.Status__c,
            DQ_Deal_Qualification__c.Segment__c,
            DQ_Deal_Qualification__c.Charge_Term__c,
            DQ_Deal_Qualification__c.Special_Terms__c,
            DQ_Deal_Qualification__c.Free_Shipping_Terms_Options__c,
            DQ_Deal_Qualification__c.CC_Initial_Term__c,
            DQ_Deal_Qualification__c.Is_ELA__c,
            DQ_Deal_Qualification__c.Roll_Out_Plan__c,
            DQ_Deal_Qualification__c.Start_Date__c,
            DQ_Deal_Qualification__c.True_Up_Terms__c,
            DQ_Deal_Qualification__c.Maximum_Potential__c,
            DQ_Deal_Qualification__c.Minimum_Baseline__c,
            DQ_Deal_Qualification__c.ELA_Initial_Terms__c,
            DQ_Deal_Qualification__c.Additional_Info__c,
            DQ_Deal_Qualification__c.IsDQCreatedFromCPQOpp__c,
            DQ_Deal_Qualification__c.Family_Discount__c
        };
    }

    private List<String> getFieldsForPRMSendEmails() {
        return new List<String>{
            'Opportunity__r.Account.Name', 
            'Opportunity__r.Owner.Email',
            'Opportunity__r.Owner.Name',
            'Opportunity__r.Owner.Manager.Email',
            'Opportunity__r.Inside_Sales_Rep__r.Email',
            'Quote__r.IsPRMQuote__c',
            'Quote__r.QuoteNumber',
            'Quote__r.JustificationandDescription__c'
        };
    }

    public QueryFactory selectDQs() {
        return newQueryFactory()
            .setFactoryName('selectDQs')
            .selectFields(getDefaultFieldList());
    }

    public QueryFactory selectDQForSync(Id oppOrDqId) {
        String condition;
        if (oppOrDqId.getSObjectType() == Opportunity.SObjectType) {
            condition = 'Opportunity__c = :bind0';
        } else if (oppOrDqId.getSObjectType() == DQ_Deal_Qualification__c.SObjectType) {
            condition = 'Id = :bind0';
        }
        return newQueryFactory()
            .setFactoryName('selectDQForSync')
            .selectFields(getFieldsForSync())
            .subselect(
                new DealQualificationDiscountSelector().selectDQDiscountsForSync()
            )
            .subselect(
                new DealQualificationServiceDiscountSelector().selectDQServiceDiscountsForSync()
            )
            .setCondition(condition)
            .setQueryBindings(new List<Object>{oppOrDqId});
    }

    public QueryFactory selectListDQsForSync(Set<Id> oppIds) {
        String condition;
        condition = 'Opportunity__c IN :bind0';
        return newQueryFactory()
            .setFactoryName('selectDQsForSync')
            .selectFields(getFieldsForSync())
            .subselect(
                new DealQualificationServiceDiscountSelector().selectDQServiceDiscountsForSync()
            )
            .setCondition(condition)
            .setQueryBindings(new List<Object>{oppIds});
    }

    public QueryFactory selectDQForDQGOA(Id oppOrDqId) {
        String condition;
        if (oppOrDqId.getSObjectType() == Opportunity.SObjectType) {
            condition = 'Opportunity__c = :bind0';
        } else if (oppOrDqId.getSObjectType() == DQ_Deal_Qualification__c.SObjectType) {
            condition = 'Id = :bind0';
        }
        return newQueryFactory()
            .setFactoryName('selectDQForDQGOA')
            .selectFields(getFieldsForDQGOA())
            .selectFields(getOpportunityFields())
            .subselect(
                new DealQualificationDiscountSelector().selectDQDiscountsForSync()
            )
            .subselect(
                new DealQualificationServiceDiscountSelector().selectDQServiceDiscountsForSync()
            )
            .setCondition(condition)
            .setQueryBindings(new List<Object>{oppOrDqId});
    }

    public QueryFactory selectAllFieldsForCloning(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectAllFieldsForCloning')
            .selectFields(AquivaHelper.getAllFieldsForObject('DQ_Deal_Qualification__c'))
            .setCondition('Quote__c IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectDQOnStatusUpdate(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectDQOnStatusUpdate')
            .selectFields(getFieldsForStatusUpdate())
            .subselect(new DealQualificationDiscountSelector().selectDQDiscountsForDQStatusUpdate())
            .subselect(new DealQualificationServiceDiscountSelector().selectDQServiceDiscountsForSync())
            .setCondition('Id = :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectDQForPRMSendEmail(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectDQForPRMSendEmail')
            .selectFields(getFieldsForPRMSendEmails())
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectDQByQuoteIds(Set<Id> quoteIds) {
        return newQueryFactory()
            .setFactoryName('selectDQByQuoteIds')
            .selectFields(new List<Schema.SObjectField> {
                DQ_Deal_Qualification__c.Id,
                DQ_Deal_Qualification__c.Quote__c
            })
            .setCondition('Quote__c IN :bind0')
            .setQueryBindings(new List<Object>{quoteIds});
    }
    
    public QueryFactory selectDQStatusByIds(Set<Id> dqIds) {
        return newQueryFactory()
            .setFactoryName('selectDQStatusByIds')
            .selectFields(new List<Schema.SObjectField> {
                DQ_Deal_Qualification__c.Id,
                DQ_Deal_Qualification__c.Status__c
            })
            .setCondition('Id IN :bind0')
            .setQueryBindings(new List<Object>{dqIds});
    }
}