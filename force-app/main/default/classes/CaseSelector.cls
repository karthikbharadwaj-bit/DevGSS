public inherited sharing class CaseSelector extends SObjectSelector {

    public CaseSelector() {
        super();
    }

    public CaseSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return Case.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Case.Id,
            Case.OwnerId,
            Case.RecordTypeId
        };
    }

    public List<Schema.SObjectField> getDetailFieldList() {
        return new List<Schema.SObjectField> {
            Case.Subject,
            Case.Description,
            Case.Status,
            Case.AccountId,
            Case.CreatedDate,
            Case.CaseNumber,
            Case.Case_Severity__c,
            Case.Origin,
            Case.Product_Assistance__c,
            Case.Product_Assistance_Lvl2__c,
            Case.Product_Assistance_Lvl3__c,
            Case.Alternate_Email__c,
            Case.CallbackNumber__c,
            Case.Timezone__c,
            Case.RecordTypeId,
            Case.Date_Completed__c,
            Case.Communication_Preference__c,
            Case.Site__c,
            Case.IsEscalated,
            Case.CreatedDate,
            Case.isClosed,
            Case.ClosedDate,
            Case.Case_Category__c,
            Case.Support_Escalate_To__c,
            Case.RecordTypeName__c,
            Case.OpportunityMRR__c,
            Case.Opportunity_Reference__c,
            Case.Category__c,
            Case.OwnerId,
            Case.Hire_Name__c,
            Case.Partner_Case_Number__c
        };
    }
    
    public List<Schema.SObjectField> getCreateLinkJiraFieldList() {
        return new List<Schema.SObjectField> {
            Case.RecordTypeName__c,
            Case.Jira_Case__c,
            Case.Jira__c
        };
    }

   public List<Schema.SObjectField> getJiraAccessFieldList() {
        return new List<Schema.SObjectField> {
            Case.RecordTypeName__c,
            Case.Jira_Case__c,
            Case.Jira__c,
            Case.Jira_Link__c
        };
    }

    public List<Schema.SObjectField> getCreateJiraDetailFieldList() {
        return new List<Schema.SObjectField> {
            Case.Jira_Case__c,
            Case.Jira__c,
            Case.CaseNumber,
            Case.AccountId,
            Case.Subject,
            Case.Description,
            Case.CreatedDate,
            Case.Brand_Account__c,
            Case.Case_Severity__c,
            Case.CaseUID__c,
            Case.Number_of_DLs_Account__c,
            Case.Tier_Account__c,
            Case.Support_Escalate_To__c
        };
    }
    
    public List<String> getOpportunityFieldList() {
        return new List<String> {
            'OpportunityMRR__c',
            'Opportunity_Reference__c',
            'Opportunity_Reference__r.Total_MRR__c'
        };
    }

    public List<String> getCaseCreatorFieldList() {
        return new List<String> {
            'CreatedBy.Name',
            'CreatedBy.ContactId',
            'CreatedBy.Contact.AccountId',
            'CreatedBy.Contact.Email',
            'CreatedBy.Contact.Phone_Ext__c',
            'CreatedBy.Contact.Phone',
            'CreatedBy.Contact.Name',
            'CreatedBy.Contact.LastName',
            'CreatedBy.Contact.FirstName',
            'CreatedBy.Contact.Account.RC_Tier__c',
            'CreatedBy.Contact.Account.Name',
            'CreatedBy.Contact.Account.Number_of_DL_s__c',
            'CreatedBy.Contact.Account.RC_Brand__c',
            'CreatedBy.Contact.Account.Total_Account_DL_s__c',
            'CreatedBy.Contact.Account.VIP_Account_Indicator__c',
            'CreatedBy.Contact.Account.Service_Status__c',
            'CreatedBy.Contact.Account.Extended_Enterprise_Support_Customer__c'
        };
    }

    public List<String> getCaseContactFieldList() {
        return new List<String> {
            'ContactId',
            'AccountId',
            'Contact.AccountId',
            'Contact.Email',
            'Contact.Phone_Ext__c',
            'Contact.Phone',
            'Contact.Name',
            'Contact.LastName',
            'Contact.FirstName',
            'Contact.Account.RC_Tier__c',
            'Contact.Account.Name',
            'Contact.Account.Number_of_DL_s__c',
            'Contact.Account.RC_Brand__c',
            'Contact.Account.Total_Account_DL_s__c',
            'Contact.Account.VIP_Account_Indicator__c',
            'Contact.Account.Service_Status__c',
            'Contact.Account.Extended_Enterprise_Support_Customer__c'
        };
    }

    public List<String> getCaseAccountFieldList() {
        return new List<String> {
            'Account.Name'
        };
    }

    public List<String> getInContactFieldList() {
        return new List<String> {
            'ContactId',
            'CaseNumber',
            'Account.Name',
            'Account.Internal_Enterprise_Account_ID__c',
            'Account.IsMultiProductTechnicalAccount__c',
            'Account.RC_User_ID__c',
            'Order__c',
            'Opportunity_Reference__c',
            'RingCentral_UID__c',
            'RingCentral_Account_Number__c',
            'Subject',
            'OwnerId',
            'Status',
            'Default_Time_Zone__c',
            'Geo_Region__c',
            'Origin',
            'Contact_Center_Number__c',
            'inContact_BU_ID__c',
            'inContact_Cluster__c',
            'inContact_Segment__c',
            'inContact_Status__c',
            'Customer_Notification__c',
            'Contact_Email__c',
            'Contact_Name__c',
            'Implementation_Team__c',
            'IC_Case_Number__c',
            'CC_Order_Type__c',
            'Product_or_Service__c',
            'Description',
            'Provision_Date__c',
            'FirstResponseTime__c',
            'CreatedDate',
            'TimeFromCreatedToWIP__c',
            'TimeFromWIPToClosed__c',
            'TimeFromFirstResponseToClosed__c'
        };
    }

    public QueryFactory selectCases() {
        return newQueryFactory()
            .setFactoryName('selectCases')
            .withoutSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded();
    }

    public QueryFactory selectCasesForApproval(List<Object> bindings) {
        return newQueryFactory()
                .setFactoryName('selectCaseForApproval')
                .withSelectorFieldsIncluded()
                .withoutSelectorOrderByIncluded()
                .setCondition('Id IN :bind0')
                .setQueryBindings(bindings);
    }

    public QueryFactory selectCasesDefault() {
        return newQueryFactory()
            .setFactoryName('selectCasesDefault')
            .selectFields(getDefaultFieldList());
    }

    public QueryFactory selectCasesDefaultDetailed(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectCasesDefaultDetailed')
            .selectFields(getDetailFieldList())
            .setQueryBindings(bindings);
    }

    public QueryFactory selectCasesByStatus(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectCasesByStatus')
            .selectFields(getDetailFieldList())
            .setCondition('Status =:bind0')
            .setQueryBindings(bindings)
            .withoutSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded();
    }

    public QueryFactory selectCasesForSCPreview(List<Object> bindings) {
        String condition = 'Status NOT IN :bind0'
            + ' AND AccountId = :bind1 ';
        if (bindings.size() > 2) {
            condition += ' AND ContactId = :bind2';
        }
        return newQueryFactory()
            .setFactoryName('selectCasesForSCPreview')
            .withoutSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .setCondition(condition)
            .addOrdering(Case.CreatedDate, QueryFactory.SortOrder.DESCENDING)
            .setQueryBindings(bindings);
    }


    public QueryFactory selectCasesForAPI(
        CaseListAPIController.FieldAndValueToSearch fieldAndValueToSearch,
        List<Object> bindings,
        Boolean isClosedCondition
    ) {
        String condition = 'AccountId = :bind0 AND RecordType.Name IN :bind1 AND IsVisibleInSelfService = true';
        if (bindings.size() == 3) {
            condition += ' AND ContactId = :bind2';
        }
        if (fieldAndValueToSearch.hasValue()) {
            condition += ' AND ' + fieldAndValueToSearch.field + ' LIKE ' +  (bindings.size() == 3 ?
                ':bind3' :
                ':bind2'
            );
            bindings.add(fieldAndValueToSearch.value);
        }

        if (isClosedCondition != null) {
            condition += ' AND IsClosed = ' + isClosedCondition;
        }

        return newQueryFactory()
            .setFactoryName('selectCasesForAPI')
            .withoutSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .setCondition(condition)
            .setQueryBindings(bindings);
    }

    public QueryFactory selectCasesWithArticlesById(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectCasesWithArticlesById')
            .selectFields(getDefaultFieldList())
            .subselect(
                new CaseArticleSelector().selectArticlesDefault()
            )
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectCaseByIdWithCommentsAttachmentsAndContactData(List<Object> bindings) {

        return newQueryFactory()
            .setFactoryName('selectCaseByIdWithCommentsAttachmentsAndContactData')
            .withSelectorFieldsIncluded()
            .selectFields(getDetailFieldList())
            .selectFields(getCaseCreatorFieldList())
            .selectFields(getCaseContactFieldList())
            .selectFields(getCaseAccountFieldList()) // Added for PBC-25300
            .subselect(
                new AttachmentSelector().selectAttachmentsDefault()
                .withoutSelectorOrderByIncluded()
                .addOrdering(Attachment.CreatedDate, QueryFactory.SortOrder.DESCENDING)
            )
            .subselect(
                new CaseCommentSelector().selectCommentsDefault()
            )
            .setCondition('Id = :bind0 AND IsVisibleInSelfService = true')
            .setQueryBindings(bindings);

    }

    public QueryFactory selectCasesIcbByNumber(List<String> caseNumbers) {
        return newQueryFactory()
            .setFactoryName('selectCasesInContact')
            .selectFields(getInContactFieldList())
            .setCondition('CaseNumber IN :bind0')
            .setQueryBindings(new List<Object>{caseNumbers});
    }

    public QueryFactory selectInContactCasesForOpportunities(List<String> opportunityIds) {
        return newQueryFactory()
            .setFactoryName('selectInContactCasesForOpportunities')
            .selectFields(getInContactFieldList())
            .setCondition('Opportunity_Reference__c IN :bind0')
            .setQueryBindings(new List<Object>{opportunityIds});
    }

    public QueryFactory selectCasesByIds(Set<Id> caseIds) {
        return newQueryFactory()
            .setFactoryName('selectCasesByIds')
            .selectFields(getInContactFieldList())
            .withoutSelectorOrderByIncluded()
            .setCondition('Id IN :bind0')
            .setQueryBindings(new List<Object>{caseIds});
    }

    public QueryFactory selectCasesByRecordTypeAndOpportunityIds(Id recordTypeId, Set<Id> opportunityIds) {
        return newQueryFactory()
            .setFactoryName('selectCasesByRecordTypeAndOpportunityIds')
            .selectFields(getInContactFieldList())
            .withoutSelectorOrderByIncluded()
            .setCondition('RecordTypeId = :bind0 AND Opportunity_Reference__c IN :bind1')
            .setQueryBindings(new List<Object>{recordTypeId, opportunityIds});
    }

    public inherited sharing class CaseArticleSelector extends SObjectSelector {

        public CaseArticleSelector() {
            super();
        }

        public CaseArticleSelector(Boolean enforceCRUD, Boolean enforceFLS) {
            super(enforceCRUD, enforceFLS);
        }

        public override Schema.SObjectType getSObjectType()  {
            return CaseArticle.SObjectType;
        }

        public override List<Schema.SObjectField> getDefaultFieldList() {
            return new List<Schema.SObjectField> {
                CaseArticle.Id,
                CaseArticle.KnowledgeArticleId,
                CaseArticle.CaseId
            };
        }

        public QueryFactory selectArticlesDefault() {
            return newQueryFactory()
            .setFactoryName('selectArticlesDefault')
            .withSelectorFieldsIncluded();
        }
    }

    public QueryFactory selectCaseForEscalating(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectCaseForEscalating')
            .withSelectorFieldsIncluded()
            .selectField(Case.isEscalated)
            .selectField(Case.CreatedDate)
            .selectField(Case.isClosed)
            .setCondition('Id = :bind0 AND IsVisibleInSelfService = true')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectCaseForReopening(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectCaseForReopening')
            .withSelectorFieldsIncluded()
            .selectFields(new SObjectField[]{
                Case.ClosedDate,
                Case.Status,
                Case.IsClosed,
                Case.Subject
            })
            .setCondition('Id = :bind0 AND IsVisibleInSelfService = true')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectCasesByOpportunityId(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectCasesByOpportunityId')
            .selectFields(getOpportunityFieldList())
            .setCondition('Opportunity_Reference__c IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectCasesWithOpportunity(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectCasesByOpportunityId')
            .selectFields(getOpportunityFieldList())
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectCasesByIdsAndRecordTypes(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectCasesByIdsAndRecordTypes')
            .withSelectorFieldsIncluded()
            .selectFields(new SObjectField[]{
                Case.Status,
                Case.IsClosed
            })
            .setCondition('Id IN :bind0 AND RecordTypeId IN :bind1')
            .setQueryBindings(bindings);
    }

    public QueryFactory selecCaseByRecordTypeNameAndStatus(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selecCaseByRecordTypeNameAndStatus')
            .selectFields(new SObjectField[]{
                Case.Status,
                Case.Description
            })
            .setCondition('Status = :bind0 AND RecordType.Name = :bind1')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectCaseByOpportunityAndQuoteAndRecordTypeName(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selecCaseByOpportunityAndQuoteAndRecordTypeName')
            .selectFields(new List<String>{
                'Status',
                'Opportunity_Reference__c',
                'Quote_Approval_ID__c',
                'Subject',
                'CreatedDate',
                'Owner.Name',
                'Description',
                'AccountId',
                'OpportunityOwnerEmail__c',
                'Partner_Contact__c',
                'Category__c',
                'Case_Category__c',
                'Segment__c',
                'RecordTypeId'
            })
            .setCondition('Opportunity_Reference__c = :bind0 AND Quote_Approval_ID__c = :bind1 AND RecordType.Name = :bind2')
            .addOrdering('CreatedDate', QueryFactory.SortOrder.DESCENDING)
            .withoutSelectorOrderByIncluded()
            .setQueryBindings(bindings);
    }
   
     public QueryFactory selectJiraCaseById(Id caseId) {
        return newQueryFactory()
            .setFactoryName('selectJiraCaseById')
            .selectFields(getCreateLinkJiraFieldList())
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object>{caseId})
            .setLimit(1);
    }
    
    public QueryFactory selectJiraAccessCaseById(Id caseId) {
        return newQueryFactory()
            .setFactoryName('selectJiraAccessCaseById')
            .selectFields(getJiraAccessFieldList())
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object>{caseId})
            .setLimit(1);
    }
    
    public QueryFactory selectCreateJiraCaseById(Id caseId) {
        return newQueryFactory()
            .setFactoryName('selectCreateJiraCaseById')
            .selectFields(getCreateJiraDetailFieldList())
            .selectFields(new List<String>{ 'Account.Name' })
            .subselect(new CaseCommentSelector().selectIdsForCreateJiraCaseSubselect())
            .subselect(new ContentDocumentLinkSelector().selectIdsForCreateJiraCaseSubselect())
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object>{caseId})
            .setLimit(1);
    }

}