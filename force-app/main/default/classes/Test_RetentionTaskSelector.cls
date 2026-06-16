@IsTest
private class Test_RetentionTaskSelector {

    @isTest
    static void testSelectRetentionTasks() {

        Test.startTest();
            QueryFactory factory = new RetentionTaskSelector()
                .selectRetentionTasks()
                .setQuery();
        Test.stopTest();

        String resultedQuery = factory.getQuery();
        Assert.isTrue(
            factory.getSelectedFields().containsAll(new Set<String> {
                'Id'
            }),
            'The selector must return default Retention_Task__c fields.'
        );
        Assert.isTrue(
            resultedQuery.contains('Retention_Task__c'),
            'The selector must contain correct object to select from'
        );
    }

    @isTest
    static void testConstructorWithRelationship() {
        String relationshipName = 'TestRelationship';
        SObjectType relationshipBase = Account.SObjectType;

        RetentionTaskSelector selector = new RetentionTaskSelector(relationshipName, relationshipBase);

        Assert.isNotNull(selector, 'Selector should not be null');
    }

    @isTest
    static void testConstructorWithCRUDandFLS() {
        Boolean enforceCRUD = true;
        Boolean enforceFLS = true;

        RetentionTaskSelector selector = new RetentionTaskSelector(enforceCRUD, enforceFLS);

        Assert.isNotNull(selector, 'Selector should not be null');
    }
}