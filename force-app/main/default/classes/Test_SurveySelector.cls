@isTest
private class Test_SurveySelector {
    private static String basePattern = '(^SELECT){1}(\\s[A-z0-9.]+,?\\s?)+';

    @isTest
    private static void testSurveySelector() {
        User systemUser = (User) new UserSelector().selectUsers().withoutSelectorFieldsIncluded()
            .selectFields(new List<String>{'Id'})
            .setQueryBindings(new List<Object>{UserInfo.getUserId()})
            .setCondition('Id = :bind0').setLimit(1).executeQuery().get(0);

        Account accTest = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'TestAcc',
                Account.BillingStreet => '20 Davis Drive',
                Account.BillingCity => 'Belmont',
                Account.BillingState => 'CA',
                Account.BillingPostalCode => '94002',
                Account.BillingCountry => 'United States',
                Account.EnabledLBO__c => true,
                Account.Offer_Type__c => 'PoC'
            })
            .create()
            .getRecord();

        System.assert(accTest.Id != null);

        Survey__c servey = (Survey__c) new SObjectBuilder(Survey__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Survey__c.Account__c => accTest.Id,
                    Survey__c.OwnerId => systemUser.Id
                }
            )
            .create()
            .getRecord();

        System.assert(servey.Id != null);

        Survey__c surveyResult = (Survey__c) new SurveySelector().selectSurveys().withoutSelectorOrderByIncluded()
            .withoutSelectorFieldsIncluded()
            .selectFields(new List<String> {'Id', 'OwnerId'})
            .executeQuery().get(0);

        System.assert(surveyResult != null);
        System.assert(surveyResult.Id != null);
    }

    @isTest
    static void testSelectSurveysByContactIdAndSurveyType() {
        QueryFactory queryFactory = new SurveySelector()
            .selectSurveysByContactIdAndSurveyType(new List<Object> {new Set<Id>(), new Set<String>(), new Set<String>(), new Set<String>()})
            .setQuery();
        String last = '(FROM Survey__c WHERE Contact__c IN :bind0 AND ((CreatedDate = LAST_N_DAYS:7 AND SurveyType__c IN :bind1) ' + 
            'OR (CreatedDate = LAST_N_DAYS:14 AND SurveyType__c IN :bind2) ' +
            'OR (CreatedDate = LAST_N_DAYS:14 AND SurveyType__c IN :bind3))';
        String pattern = basePattern + last;
		Assert.isFalse(queryFactory.fields.isEmpty(), 'Query does not contain fields');
        Assert.isFalse(String.isBlank(queryFactory.getQuery()), 'Query is empty');
    }
}