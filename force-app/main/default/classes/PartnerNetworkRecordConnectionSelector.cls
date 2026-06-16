public class PartnerNetworkRecordConnectionSelector extends SObjectSelector {

    public PartnerNetworkRecordConnectionSelector() {
        super();
    }

    public PartnerNetworkRecordConnectionSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return PartnerNetworkRecordConnection.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            PartnerNetworkRecordConnection.Id,
            PartnerNetworkRecordConnection.Status,
            PartnerNetworkRecordConnection.StartDate,
            PartnerNetworkRecordConnection.SendOpenTasks,
            PartnerNetworkRecordConnection.SendEmails,
            PartnerNetworkRecordConnection.SendClosedTasks,
            PartnerNetworkRecordConnection.RelatedRecords,
            PartnerNetworkRecordConnection.PartnerRecordId,
            PartnerNetworkRecordConnection.ParentRecordId,
            PartnerNetworkRecordConnection.LocalRecordId,
            PartnerNetworkRecordConnection.EndDate,
            PartnerNetworkRecordConnection.ConnectionId
        };
    }

    public QueryFactory selectPnrcRecords() {
        return newQueryFactory()
            .setFactoryName('selectPnrcRecords')
            .selectFields(getDefaultFieldList())
            .withoutSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded();
    }

    public QueryFactory selectPnrcByLocalRecordId(Set<Id> localRecordIdSet) {
        return newQueryFactory()
            .setFactoryName('selectPnrcByLocalRecordId')
            .selectFields(getDefaultFieldList())
            .setCondition('LocalRecordId IN :bind0')
            .setQueryBindings(new List<Object>{localRecordIdSet});
    }

}