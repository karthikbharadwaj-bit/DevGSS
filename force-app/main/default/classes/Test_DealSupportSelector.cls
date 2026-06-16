@IsTest
private class Test_DealSupportSelector {

    @isTest
    static void testSelectDealSupports() {

        Test.startTest();
            QueryFactory factory = new DealSupportSelector()
                .selectDealSupports()
                .setQuery();
        Test.stopTest();

        String resultedQuery = factory.getQuery();
        Assert.isTrue(
            factory.getSelectedFields().containsAll(new Set<String> {
                'Id',
                'Name'
            }),
            'The selector must return default Deal_Support__c fields.'
        );
        Assert.isTrue(
            resultedQuery.contains('Deal_Support__c'),
            'The selector must contain correct object to select from'
        );
    }

    @isTest
    static void testConstructorWithRelationship() {
        String relationshipName = 'TestRelationship';
        SObjectType relationshipBase = Account.SObjectType;

        DealSupportSelector selector = new DealSupportSelector(relationshipName, relationshipBase);

        Assert.isNotNull(selector, 'Selector should not be null');
    }

    @isTest
    static void testConstructorWithCRUDandFLS() {
        Boolean enforceCRUD = true;
        Boolean enforceFLS = true;

        DealSupportSelector selector = new DealSupportSelector(enforceCRUD, enforceFLS);

        Assert.isNotNull(selector, 'Selector should not be null');
    }
}