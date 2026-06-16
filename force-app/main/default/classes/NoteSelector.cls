public inherited sharing class NoteSelector extends SObjectSelector {

    public NoteSelector() {
        super();
    }

    public NoteSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override SObjectType getSObjectType() {
        return Note.SObjectType;
    }

    public override List<SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Note.Id,
            Note.Title,
            Note.IsPrivate,
            Note.Body,
            Note.ParentId
        };
    }

    public QueryFactory selectNotes() {
        return newQueryFactory()
            .setFactoryName('selectNotes');
    }

    public QueryFactory selectNotesForLeadConvert(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('SelectNotesForLeadConvert')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .withSelectFieldsSorted()
            .setQueryBindings(bindings)
            .setCondition('ParentId = :bind0');
    }
}