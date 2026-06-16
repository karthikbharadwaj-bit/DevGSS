@IsTest
private class Test_AccountManagementSelector {

    @isTest
    static void testSelectAccountManagements() {

        Test.startTest();
            QueryFactory factory = new AccountManagementSelector()
                .selectAccountManagements()
                .setQuery();
        Test.stopTest();

        String resultedQuery = factory.getQuery();
        Assert.isTrue(
            factory.getSelectedFields().containsAll(new Set<String> {
                'Id',
                'Name'
            }),
            'The selector must return default Account_Management__c fields.'
        );
        Assert.isTrue(
            resultedQuery.contains('Account_Management__c'),
            'The selector must contain correct object to select from'
        );
    }

    @isTest
    static void testConstructorWithRelationship() {
        String relationshipName = 'TestRelationship';
        SObjectType relationshipBase = Account.SObjectType;

        AccountManagementSelector selector = new AccountManagementSelector(relationshipName, relationshipBase);

        Assert.isNotNull(selector, 'Selector should not be null');
    }

    @isTest
    static void testConstructorWithCRUDandFLS() {
        Boolean enforceCRUD = true;
        Boolean enforceFLS = true;

        AccountManagementSelector selector = new AccountManagementSelector(enforceCRUD, enforceFLS);

        Assert.isNotNull(selector, 'Selector should not be null');
    }
}