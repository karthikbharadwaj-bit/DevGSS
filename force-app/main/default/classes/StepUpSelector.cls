public inherited sharing class StepUpSelector extends SObjectSelector {

    public StepUpSelector() {
        super();
    }

    public StepUpSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return Step_Up__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Step_Up__c.Id,
            Step_Up__c.Engage_Legal_Record__c,
            Step_Up__c.Step_Up_Date__c,
            Step_Up__c.Step_Up_DLs__c,
            Step_Up__c.Type__c
        };
    }

    public QueryFactory selectStepUps() {
        return newQueryFactory()
            .setFactoryName('selectStepUps');
    }
}