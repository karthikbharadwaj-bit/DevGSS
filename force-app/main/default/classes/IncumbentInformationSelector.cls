public inherited sharing class IncumbentInformationSelector extends SObjectSelector {

    public IncumbentInformationSelector() {
        super();
    }

    public IncumbentInformationSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return Competitive_Technology_Stack__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Competitive_Technology_Stack__c.Id,
            Competitive_Technology_Stack__c.Phone__c,
            Competitive_Technology_Stack__c.Contact_Center__c,
            Competitive_Technology_Stack__c.Meetings__c,
            Competitive_Technology_Stack__c.Digital_Channels__c,
            Competitive_Technology_Stack__c.Message__c,
            Competitive_Technology_Stack__c.Incumbent_Conversation_Intelligence__c,
            Competitive_Technology_Stack__c.Key_Deal_Integration__c,
            Competitive_Technology_Stack__c.Key_Deal_Integration_Other__c
        };
    }

    public List<String> getIncumbentInfoFields() {
        return new List<String> {
            'Id',
            'Phone__c',
            'Contact_Center__c',
            'Meetings__c',
            'Digital_Channels__c',
            'Message__c',
            'Incumbent_Conversation_Intelligence__c',
            'Key_Deal_Integration__c',
            'Key_Deal_Integration_Other__c'
        };
    }

    public QueryFactory selectIncumbentInfo() {
        return newQueryFactory()
            .setFactoryName('selectIncumbentInfo');
    }
}