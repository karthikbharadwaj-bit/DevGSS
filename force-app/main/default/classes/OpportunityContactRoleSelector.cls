public inherited sharing class OpportunityContactRoleSelector extends SObjectSelector {

    public OpportunityContactRoleSelector() {
        super();
    }

    public OpportunityContactRoleSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override SObjectType getSObjectType() {
        return OpportunityContactRole.SObjectType;
    }

    public override List<SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            OpportunityContactRole.Id,
            OpportunityContactRole.IsPrimary,
            OpportunityContactRole.OpportunityId,
            OpportunityContactRole.ContactId,
            OpportunityContactRole.Role
        };
    }

    public List<String> getCloseFieldList() {
        return new List<String> {
            'Contact.FirstName',
            'Contact.LastName',
            'Contact.Email',
            'Contact.Phone',
            'Contact.Account.RC_User_ID__c',
            'Contact.Account.RC_Account_Status__c'

        };
    }

    public List<String> getOpportunityFields() {
        return new List<String> {
            'Opportunity.isClosed',
            'Opportunity.Name'
        };
    }

    public List<String> getOppQuotedProductFields() {
        return new List<String> {
            'Opportunity.Estimated_12M_Office_Pipeline__c',
            'Opportunity.Estimated_12M_Contact_Center_Pipeline__c',
            'Opportunity.Estimated_12M_Global_Office_Pipeline__c',
            'Opportunity.Estimated_12M_Engage_Digital_Pipeline__c',
            'Opportunity.Estimated_12M_Engage_Voice_Pipeline__c',
            'Opportunity.Estimated_12M_RingCentral_Video_Pipeline__c',
            'Opportunity.EstimatedProfessionalServices12Month__c',
            'Opportunity.Primary_Opportunity_Contact__c'
        };
    }
     public List<String> getOppAndAccountFields() {
        return new List<String> {
            'OpportunityId',
            'Opportunity.Accountid',
            'Opportunity.Account.RC_Account_Status__c',
            'Opportunity.PrimaryQuote__r.Status',
            'Opportunity.CustomerConfirmation__c',
            'IsPrimary',
            'ContactId',
            'Role'
        };
    }


    public List<String> getFieldListForFixContactStatusField() {
        return new List<String> {
            'Contact.Account_Status__c',
            'Contact.Quoted_Products__c',
            'Contact.Customer_Record__c',
            'Contact.Contact_Status__c',
            'Opportunity.Estimated_12M_Office_Pipeline__c',
            'Opportunity.Estimated_12M_Contact_Center_Pipeline__c',
            'Opportunity.Estimated_12M_Global_Office_Pipeline__c',
            'Opportunity.Estimated_12M_Engage_Digital_Pipeline__c',
            'Opportunity.Estimated_12M_Engage_Voice_Pipeline__c',
            'Opportunity.Estimated_12M_RingCentral_Video_Pipeline__c',
            'Opportunity.EstimatedProfessionalServices12Month__c',
            'Opportunity.Primary_Opportunity_Contact__c'
        };
    }
    public QueryFactory selectOppConRolesWithId(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectOppConRolesWithId')
            .selectFields(getOppAndAccountFields())
            .withSelectorFieldsIncluded()
            .setQueryBindings(bindings)
            .setCondition('Id IN :bind0');
    }


    public QueryFactory selectOCRForLeadConvert(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('SelectOCRForLeadConvert')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .withSelectFieldsSorted()
            .setQueryBindings(bindings)
            .setCondition('OpportunityId = :bind0 AND ContactId = :bind1')
            .setLimit(1);
    }

    public QueryFactory selectOpportunityContactRoles() {
        return newQueryFactory()
            .setFactoryName('SelectOpportunityContactRoles')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .withSelectFieldsSorted();
    }

    public QueryFactory selectOpportunityContactRolesByOppId(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectOpportunityContactRolesByOppId')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .setQueryBindings(bindings)
            .setCondition('OpportunityId = :bind0')
            .withSelectFieldsSorted();
    }

    public QueryFactory selectPrimaryOpportunityContactRolesByOppIds(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectPrimaryOpportunityContactRolesByOppIds')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .setCondition('OpportunityId = :bind0 AND isPrimary = true')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectPrimaryOpportunityContactRolesforCLM(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectPrimaryOpportunityContactRolesforCLM')
			.selectFields(getDefaultFieldList())
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .setCondition('OpportunityId = :bind0 AND isPrimary = true')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectOCRForOpportunityClose(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('SelectOCRForOpportunityClose')
            .selectFields(getCloseFieldList())
            .withoutSelectorOrderByIncluded()
            .withSelectFieldsSorted()
            .setQueryBindings(bindings)
            .setCondition('OpportunityId = :bind0 AND Role = \'' +
                OpportunityHelper.CONTACT_ROLE_SIGNATORY + '\'' +
                ' AND isPrimary = true')
            .setLimit(1);
    }

    public QueryFactory selectOpportunityContactRolesByListOppIds(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectOpportunityContactRolesByListOppIds')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .setQueryBindings(bindings)
            .setCondition('OpportunityId IN :bind0');
    }

    public QueryFactory selectOCRWhereOpportunityIsOpenAndContactIdMatchesAndIsPrimary(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectOCRWhereOpportunityIsOpenAndContactIdMatches')
            .selectField(OpportunityContactRole.ContactId)
            .selectField(OpportunityContactRole.OpportunityId)
            .selectFields(new List<String> {
                'OpportunityId',
                'Opportunity.isClosed',
                'Opportunity.Primary_Opportunity_Contact__c',
                'Opportunity.Id',
                'Opportunity.Name',
                'ContactId'
            })
            .setCondition('ContactId IN :bind0 AND isPrimary = true AND Opportunity.isClosed = false AND Opportunity.isWon = false')
            .setQueryBindings(bindings);
    }


    public QueryFactory selectOpportunityContactRolesByListConIds(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectOpportunityContactRolesByListConIds')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .setQueryBindings(bindings)
            .setCondition('ContactId IN :bind0');
    }

    public QueryFactory selectOppConRolesByListConIdsAndListOppIds(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectOppConRolesByListConIdsAndListOppIds')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .setQueryBindings(bindings)
            .setCondition('OpportunityId IN :bind0 AND ContactId IN :bind1');
    }
    public QueryFactory selectOCRbyContactsId(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectOCRbyContactsId')
            .selectFields(getOpportunityFields())
            .withSelectorFieldsIncluded()
            .setQueryBindings(bindings)
            .setCondition('ContactId IN :bind0');
    }
    
    public QueryFactory selectOCRForFixContactStatusField(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectOCRForFixContactStatusField')
            .selectFields(getFieldListForFixContactStatusField())
            .setQueryBindings(bindings)
            .setCondition('CreatedDate > :bind0 AND CreatedDate < :bind1 AND Opportunity.isClosed = true AND Opportunity.IsWon = true AND Contact.Contact_Status__c = \'2. Contacted\'');
    }

    public QueryFactory selectOppConRolesWithClosedWonOppbyContactsId(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectOppConRolesWithClosedWonOppbyContactsId')
            .selectFields(getOppQuotedProductFields())
            .withSelectorFieldsIncluded()
            .setQueryBindings(bindings)
            .setCondition('ContactId IN :bind0 AND Opportunity.isClosed = true AND Opportunity.isWon = true');
    }
}