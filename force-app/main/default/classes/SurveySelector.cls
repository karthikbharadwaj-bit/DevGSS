public inherited sharing class SurveySelector extends SObjectSelector {

    public override SObjectType getSObjectType() {
        return Survey__c.SObjectType;
    }

    public override List<SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Survey__c.Id
        };
    }

    public QueryFactory selectSurveys() {
        return newQueryFactory()
            .setFactoryName('selectSurveys');
    }

    public QueryFactory selectSurveysByContactIdAndSurveyType(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectSurveysByContactIdAndSurveyType')
            .withSelectorFieldsIncluded()
            .selectFields(new List<Schema.SObjectField> {
                Survey__c.Id,
                Survey__c.Contact__c,
                Survey__c.SurveyType__c
            })
            .setCondition('Contact__c IN :bind0 AND ((CreatedDate = LAST_N_DAYS:7 AND SurveyType__c IN :bind1) ' + 
                'OR (CreatedDate = LAST_N_DAYS:14 AND SurveyType__c IN :bind2) ' +
                'OR (CreatedDate = LAST_N_DAYS:14 AND SurveyType__c IN :bind3))')
            .setQueryBindings(bindings);
    }
}