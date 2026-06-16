public inherited sharing class MedalliaSurveySelector extends SObjectSelector {
    public override SObjectType getSObjectType() {
        return Medallia_Survey__c.SObjectType;
    }

    public override List<SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Medallia_Survey__c.Id
        };
    }

    public QueryFactory selectMedalliaSurveysByCaseId(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectMedalliaSurveysByCaseId')
            .selectFields(new List<Schema.SObjectField> {
                Medallia_Survey__c.Id,
                Medallia_Survey__c.Case_SFDC_ID__c,
                Medallia_Survey__c.Support_Contact_ID__c
            })
            .setCondition('Case_SFDC_ID__c IN :bind0')
            .setQueryBindings(bindings);
    }
}