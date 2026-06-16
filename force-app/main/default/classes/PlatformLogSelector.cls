@IsTest
public class PlatformLogSelector extends SObjectSelector {
    public override SObjectType getSObjectType()  {
        return PlatformLog__c.SObjectType;
    }

    public override List<SObjectField> getDefaultFieldList() {
        return new List<SObjectField> {
            PlatformLog__c.Id,
            PlatformLog__c.Source__c
        };
    }

    public QueryFactory selectLogsByLikeSource(String source) {
        return newQueryFactory()
            .setFactoryName('selectLogsBySource')
            .setCondition('Source__c LIKE :bind0')
            .setQueryBindings(new List<Object> {source});
    }
}