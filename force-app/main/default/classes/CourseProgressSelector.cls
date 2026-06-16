public inherited sharing class CourseProgressSelector extends SObjectSelector {

    public CourseProgressSelector() {
        super();
    }

    public override Schema.SObjectType getSObjectType()  {
        return skilljar__Course_Progress__c.SObjectType;
    }

    public CourseProgressSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            skilljar__Course_Progress__c.Id,
            skilljar__Course_Progress__c.Name,
            skilljar__Course_Progress__c.skilljar__Contact__c,
            skilljar__Course_Progress__c.skilljar__Completed_At__c,
            skilljar__Course_Progress__c.skilljar__Course__c,
            skilljar__Course_Progress__c.skilljar__Published_Course__c
        };
    }

    public QueryFactory selectCompletedCDPCourses() {
        return newQueryFactory()
            .setFactoryName('selectCourseProgressesByIds')
            .selectFields(getDefaultFieldList())
            .setCondition('CDP_Course__c = true AND skilljar__Completed_At__c != null');
    }

    public QueryFactory selectAllCDPCourses() {
        return newQueryFactory()
            .setFactoryName('selectCourseProgressesByIds')
            .selectFields(getDefaultFieldList())
            .setCondition('CDP_Course__c = true');
    }

    public QueryFactory selectCompletedCDPCoursesByContactId(Object[] bindings) {
        return newQueryFactory()
            .setFactoryName('selectCourseProgressesByIds')
            .selectFields(getDefaultFieldList())
            .selectField('skilljar__Contact__c.AccountId')
            .selectField('skilljar__Contact__r.Account.Certified_Delivery_Partner_Status__c')
            .setCondition('CDP_Course__c = true AND skilljar__Completed_At__c != null AND skilljar__Contact__c IN :bind0')
            .setQueryBindings(bindings);
    }
}