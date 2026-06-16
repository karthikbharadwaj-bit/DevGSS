@IsTest
private class Test_QueueSelector {
    private static final String TEST_QUEUE_NAME = 'Test Queue';
    private static final String TEST_SOBJECT_TYPE = 'TestSObjectType';

    private static void assertQueueFactory(QueryFactory factory, List<Object> expectedBindings, String expectedCondition) {
        new QueryFactoryAssertBuilder(factory)
            .withBindings(expectedBindings)
            .withCondition(expectedCondition)
            .assert();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testSelectQueuesByNames() {
        Set<String> inputNames = new Set<String> {TEST_QUEUE_NAME};

        Test.startTest();
            QueryFactory factory = new QueueSelector().selectQueuesByNames(inputNames);
        Test.stopTest();

        assertQueueFactory(
            factory,
            new List<Object> {inputNames},
            'Queue.Name IN :bind0'
        );
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testSelectQueueForDFRBySObjectType() {
        List<Object> expectedBindings = new List<Object> {TEST_SOBJECT_TYPE};

        Test.startTest();
            QueryFactory factory = new QueueSelector().selectQueueForDFRBySObjectType(expectedBindings);
        Test.stopTest();

        assertQueueFactory(
            factory,
            expectedBindings,
            'SObjectType = :bind0'
        );
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testSelectQueueByName() {
        List<Object> expectedBindings = new List<Object> {TEST_QUEUE_NAME};

        Test.startTest();
        QueryFactory factory = new QueueSelector().selectQueueByName(expectedBindings);
        Test.stopTest();

        assertQueueFactory(
            factory,
            expectedBindings,
            'Queue.Name = :bind0'
        );
    }
}