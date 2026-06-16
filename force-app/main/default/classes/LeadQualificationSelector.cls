public inherited sharing class LeadQualificationSelector extends SObjectSelector {

    public LeadQualificationSelector() {
        super();
    }

    public LeadQualificationSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override SObjectType getSObjectType() {
        return Lead_Qualification__c.SObjectType;
    }

    public override List<SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Lead_Qualification__c.Id,
            Lead_Qualification__c.Name,
            Lead_Qualification__c.Lead__c,
            Lead_Qualification__c.Gain__c,
            Lead_Qualification__c.CreatedDate,
            Lead_Qualification__c.Benefits__c,
            Lead_Qualification__c.LastModifiedDate
        };
    }

    public List<SObjectField> getFieldListForLeadConverting() {
        return new List<Schema.SObjectField> {
            Lead_Qualification__c.Pain__c,
            Lead_Qualification__c.Name,
            Lead_Qualification__c.Pain_Impact__c,
            Lead_Qualification__c.Opportunity__c,
            Lead_Qualification__c.Next_Steps_questions__c,
            Lead_Qualification__c.Lead__c,
            Lead_Qualification__c.LastModifiedDate,
            Lead_Qualification__c.InContract__c,
            Lead_Qualification__c.Ideal_Solution__c,
            Lead_Qualification__c.Gain__c,
            Lead_Qualification__c.Gain_Impact__c,
            Lead_Qualification__c.CreatedDate,
            Lead_Qualification__c.CompanyInfo__c,
            Lead_Qualification__c.Benefits__c,
            Lead_Qualification__c.Account__c,
            Lead_Qualification__c.Account__r.Name,
            Lead_Qualification__c.Owner.Name,
            Lead_Qualification__c.Lead__r.Name,
            Lead_Qualification__c.Opportunity__r.Name,
            Lead_Qualification__c.Decision_Maker_Partner__c,
            Lead_Qualification__c.Decision_Maker_Phone__c,
            Lead_Qualification__c.Decision_Maker_Last_Name__c,
            Lead_Qualification__c.Decision_Maker_First_Name__c,
            Lead_Qualification__c.Decision_Maker_Email__c,
            Lead_Qualification__c.Decision_Maker_Business_Title__c,
            Lead_Qualification__c.Decision_Maker_Alternate_Phone__c,
            Lead_Qualification__c.Discovery_notes__c,
            Lead_Qualification__c.Motivations__c,
            Lead_Qualification__c.Current_Situation__c,
            Lead_Qualification__c.Problems__c,
            Lead_Qualification__c.Impact__c,
            Lead_Qualification__c.Ideal_Situation__c,
            Lead_Qualification__c.Benefits__c,
            Lead_Qualification__c.Decision_Making_Process__c,
            Lead_Qualification__c.Competitive_Landscape__c,
            Lead_Qualification__c.Relationship_Building_Extras__c,
            Lead_Qualification__c.CoachingNotes__c,
            Lead_Qualification__c.NextSteps__c
        };
    }

    public QueryFactory selectQualificationsForLeadConvert(Id leadId, Integer offset, Integer queryLimit) {
        return newQueryFactory()
                .setFactoryName('selectQualificationsForLeadConvert')
                .withSelectorFieldsIncluded()
                .setCondition('IsDeleted = false')
                .setCondition('Lead__c = \'' + leadId + '\'')
                .withoutSelectorOrderByIncluded()
                .addOrdering('LastModifiedDate', QueryFactory.SortOrder.DESCENDING, true)
                .setLimit(queryLimit)
                .setOffset(offset);
    }

    public List<Schema.SObjectField> getFieldListForBackendConvert() {
        return new List<Schema.SObjectField> {
            Lead_Qualification__c.Decision_Maker_Partner__c,
            Lead_Qualification__c.Decision_Maker_First_Name__c,
            Lead_Qualification__c.Decision_Maker_Last_Name__c,
            Lead_Qualification__c.Decision_Maker_Email__c,
            Lead_Qualification__c.Decision_Maker_Phone__c,
            Lead_Qualification__c.Decision_Maker_Business_Title__c
        };
    }

    public QueryFactory selectLeadQualificationsForBackendConvert(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectLeadQualificationsForBackendConvert')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .withSelectFieldsSorted()
            .selectFields(getFieldListForBackendConvert())
            .setCondition('Id = :bind0')
            .setQueryBindings(bindings);
    }
}