public with sharing class CaseCommentSelector extends SObjectSelector {

    public CaseCommentSelector() {
        super();
    }

    public CaseCommentSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            CaseComment.Id,
            CaseComment.IsPublished,
            CaseComment.CommentBody,
            CaseComment.CreatedDate,
            CaseComment.CreatedById,
            CaseComment.LastModifiedDate,
            CaseComment.LastModifiedById
        };
    }

    public List<String> getCaseCommentForAPI() {
        return new List<String> {
            'Id',
            'ParentId',
            'CommentBody',
            'IsPublished',
            'CreatedDate',
            'CreatedById'
        };
    }

    public override Schema.SObjectType getSObjectType()  {
        return CaseComment.SObjectType;
    }

    public QueryFactory selectCaseCommentsByCreatedDate(List<Object> bindings) {
		return newQueryFactory()
				.setFactoryName('selectCaseCommentsByCreatedDate')
                .withSelectorFieldsIncluded()
				.withoutSelectorOrderByIncluded()
                .setCondition('Parent.RecordType.Name in :bind0 AND CreatedDate > :bind1')
                .setQueryBindings(bindings);
    }

    public QueryFactory selectCaseCommentsByIdForAPI(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectCaseCommentsByIdForAPI')
            .selectFields(getCaseCommentForAPI())
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectCommentsDefault() {
        return newQueryFactory()
        .setFactoryName('selectCommentsDefault')
        .withSelectorFieldsIncluded()
        .withoutSelectorOrderByIncluded()
        .addOrdering(CaseComment.CreatedDate, QueryFactory.SortOrder.DESCENDING)
        .setCondition('IsPublished = TRUE AND IsDeleted = FALSE');
    }

    public QueryFactory selectCaseCommentsByCaseId(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectCaseCommentsByCaseId')
            .selectFields(getCaseCommentForAPI())
            .setCondition('ParentId = :bind0')
            .setQueryBindings(bindings);
    }
    
    /** Subselect from Case for Create Jira payload (matches prior inline SOQL: SELECT Id FROM CaseComments). */
    public QueryFactory selectIdsForCreateJiraCaseSubselect() {
        return newQueryFactory()
            .setFactoryName('selectIdsForCreateJiraCaseSubselect')
            .selectField(CaseComment.Id)
            .withoutSelectorOrderByIncluded();
    }
}