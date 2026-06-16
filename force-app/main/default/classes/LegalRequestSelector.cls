public inherited sharing class LegalRequestSelector extends SObjectSelector {
    public LegalRequestSelector() {
        super();
    }

    public LegalRequestSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return Legal_Requests__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Legal_Requests__c.Id
        };
    }

    public List<String> getAllFields() {
        return new List<String>{
            'Id',
            'Applicable_License__c',
            'Are_alternatives_to_the_FOSS_available__c',
            'ConnectionReceivedId',
            'ConnectionSentId',
            'CreatedById',
            'CreatedDate',
            'CurrencyIsoCode',
            'Date_for_RC_Product_Integration__c',
            'Department__c',
            'Disclosed_to_outside_parties__c',
            'Disclosure_Date__c',
            'Document_Title_Plan__c',
            'Document_Title__c',
            'Draft_Date__c',
            'Existing_Publication_or_Disclosure__c',
            'FOSS_be_embeded_in_external_RC_Products__c',
            'FOSS_introduced_to_the_marketplace__c',
            'FOSS_Name__c',
            'FOSS_Submitter_Lookup__c',
            'FOSS_Submitter__c',
            'FOSS_Version__c',
            'How_is_the_problem_solved__c',
            'How_widely_is_this_FOSS_used_externally__c',
            'How_will_FOSS_be_modified__c',
            'How_will_you_link_to_FOSS__c',
            'IDF_Creation_Date__c',
            'If_no_how_important_is_the_FOSS_to_RC__c',
            'If_Other_explain__c',
            'If_Yes_to_who__c',
            'If_yes_what_are_they__c',
            'Include_attribution__c',
            'Inventor_Name_Text__c',
            'Inventor_Name__c',
            'In_what_form_will_FOSS_be_redistributed__c',
            'IsDeleted',
            'Is_attribution_required_for_use__c',
            'Is_FOSS_currently_being_used__c',
            'Keyword__c',
            'LastModifiedById',
            'LastModifiedDate',
            'LastReferencedDate',
            'LastViewedDate',
            'License_URL__c',
            'Location__c',
            'Major_RingCentral_Product_Version__c',
            'Minor_RingCentral_Product_Version__c',
            'Name',
            'Other_Field_of_Invention__c',
            'Other_RC_Product__c',
            'Other_RingCentral_Project__c',
            'OwnerId',
            'Plans_for_Commercial_Release__c',
            'Plans_for_Publication__c',
            'Provide_Practical_Example__c',
            'Publication_Date_Plan__c',
            'Publication_Date__c',
            'Publication_Plan__c',
            'Publication__c',
            'RecordTypeId',
            'RingCentral_Product_where_used__c',
            'Status__c',
            'Submitted_Date__c',
            'SystemModstamp',
            'Technical_Field_of_the_Invention__c',
            'Title_of_Invention__c',
            'Under_NDA__c',
            'What_problem_needs_to_be_solved__c',
            'What_RC_Product_is_this_related_to__c',
            'What_was_already_known__c',
            'When_did_FOSS_start_being_used__c',
            'When_will_Product_be_released__c',
            'Why_do_you_want_to_incorporate_the_FOSS__c',
            'Will_FOSS_be_modified__c',
            'Will_you_link_to_FOSS__c'
        };
    }

    public QueryFactory selectLegalRequestById(Id LegalRequestId) {
        return newQueryFactory()
            .setFactoryName('selectLegalRequestById')
            .selectFields(getAllFields())
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object>{new Set<Id> {LegalRequestId} });
    }
}