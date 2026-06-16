public inherited sharing class GeneralSelector extends SObjectSelector  {

    public Schema.SObjectType sObjType {get; private set{
        if (value == null) {
            throw new IllegalArgumentException('SObjectType should not be null.');
        }
        this.sObjType = value;
    }}

    public GeneralSelector(Schema.SObjectType sObjType) {
        super();
        this.sObjType = sObjType;
    }

    public GeneralSelector(Schema.SObjectType sObjType, Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
        this.sObjType = sObjType;
    }

    public override Schema.SObjectType getSObjectType()  {
        return this.sObjType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField>();
    }

}