@isTest
private class Test_ListHelper {

    @isTest
    static void testUnshift() {
        Test.startTest();

        // Empty
        List<String> strList = new List<String>();
        ListHelper.unshift(strList, '0');

        System.assertEquals(1, strList.size());
        System.assertEquals('0', strList.get(0));

        // With elements
        strList = new List<String>{'1', '2'};
        ListHelper.unshift(strList, '0');

        System.assertEquals(3, strList.size());
        System.assertEquals('0', strList.get(0));
        System.assertEquals('1', strList.get(1));
        System.assertEquals('2', strList.get(2));

        Test.stopTest();
    }

    @isTest
    static void testsplitSObjectList() {
        List<SObject> accs = new SObjectBuilder(Account.SObjectType)
            .quantity(11)
            .build()
            .getRecords();

        List<List<SObject>> accsSplitted = ListHelper.splitSObjectList(accs, 3);

        System.assertEquals(4, accsSplitted.size(), 'Not enough records\' lists');
        System.assertEquals(2, accsSplitted[accsSplitted.size()-1].size(), 'Wrong records quantity in last list');

        accs.remove(0);
        accs.remove(0);

        accsSplitted = ListHelper.splitSObjectList(accs, 3);

        System.assertEquals(3, accsSplitted.size(), 'Not enough records\' lists');
        System.assertEquals(3, accsSplitted[accsSplitted.size()-1].size(), 'Wrong records quantity in last list');
    }

    @isTest
    static void testsplitSObjectList_listToSplit_null() {
        String res = '';
        try{
            ListHelper.splitSObjectList(null, 1);
        } catch (Exception e) {
            res = e.getMessage();
        }

        System.assertEquals('List to split can\'t be null', res, 'Should throw an exception if first argument is null');
    }

    @isTest
    static void testsplitSObjectList_splitSize_lessThan1() {
        String res = '';
        try{
            ListHelper.splitSObjectList(new List<SObject>(), null);
        } catch (Exception e) {
            res = e.getMessage();
        }

        System.assertEquals('Split size can\'t be less than 1', res, 'Should throw an exception if second argument is less than 1');
    }

    @isTest
    static void testConvertToString() {
        Test.startTest();
            String resultList = ListHelper.convertToString(new List<String>{'1','2','3'});
            String resultSet = ListHelper.convertToString(new Set<String>{'1','2','3'});
        Test.stopTest();

        String expectedResult = '(' + '\'' + '1' + '\',' + '\'' + '2' + '\',' + '\'' + '3' + '\'' + ')';
        System.assertEquals(expectedResult, resultList, 'Error in string value composition from List');
        System.assertEquals(expectedResult, resultSet, 'Error in string value composition from Set');
    }
}