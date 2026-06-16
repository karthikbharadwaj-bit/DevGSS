public inherited sharing class BusinessHoursSelector extends SObjectSelector {

    public BusinessHoursSelector() {
        super();
    }

    public BusinessHoursSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return BusinessHours.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            BusinessHours.Id
        };
    }
}