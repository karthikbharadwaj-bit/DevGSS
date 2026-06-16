public inherited sharing class CampaignMemberSelector extends SObjectSelector {

    public CampaignMemberSelector() {
        super();
    }

    public CampaignMemberSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return CampaignMember.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            CampaignMember.LeadId,
            CampaignMember.ContactId,
            CampaignMember.Id,
            CampaignMember.CampaignId,
            CampaignMember.Primary_Marketing_Asset__c,
            CampaignMember.Status
        };
    }

    public List<String> getCampaignInformation() {
        return new List<String> {
            'Campaign.Non_Attributable__c', 
            'Campaign.BMID__c'
        };
    }

    public QueryFactory selectCampaignMemberForOpportunityMethods(List<Object> bindings) {
        return newQueryFactory()
                .setFactoryName('selectCampaignMemberForOpportunityMethods')
                .withSelectorFieldsIncluded()
                .selectFields(getCampaignInformation())
                .addOrdering('LastModifiedDate', QueryFactory.SortOrder.ASCENDING)
                .setCondition('ContactId = :bind0')
                .setQueryBindings(bindings);
    }

    public QueryFactory selectCampaignMemberForLeadConvert() {
        return newQueryFactory()
                .setFactoryName('SelectCampaignMemberForLeadConvert')
                .withoutSelectorOrderByIncluded()
                .withSelectorFieldsIncluded();
    }

    public QueryFactory selectCampaignMemberByLeadAndCampaignIds(List<Object> bindings) {
        return newQueryFactory()
                .setFactoryName('selectCampaignMemberByLeadAndCampaignIds')
                .withoutSelectorOrderByIncluded()
                .withSelectorFieldsIncluded()
                .setCondition('LeadId IN :bind0 AND CampaignId IN :bind1')
                .setQueryBindings(bindings);
    }

    public QueryFactory selectCampaignMemberByContactAndCampaignIds(List<Object> bindings) {
        return newQueryFactory()
                .setFactoryName('selectCampaignMemberByContactAndCampaignIds')
                .withoutSelectorOrderByIncluded()
                .withSelectorFieldsIncluded()
                .selectField(CampaignMember.Status)
                .setCondition('ContactId IN :bind0 AND CampaignId IN :bind1')
                .setQueryBindings(bindings);
    }

    public QueryFactory selectCampaignMembersByLeadAndCampaignORByContactAndCampaign(List<Object> bindings) {
        return newQueryFactory()
                .setFactoryName('selectCampaignMembersByLeadAndCampaignORByContactAndCampaign')
                .selectField(CampaignMember.CampaignId)
                .selectField(CampaignMember.ContactId)
                .selectField(CampaignMember.LeadId)
                .selectField(CampaignMember.lastModifiedDate)
                .selectField(CampaignMember.LastModifiedById)
                .setCondition('(LeadId IN :bind0 OR ContactId IN :bind2) AND CampaignId IN :bind1')
                .setQueryBindings(bindings);
    }
}