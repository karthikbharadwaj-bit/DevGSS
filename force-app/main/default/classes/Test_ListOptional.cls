@IsTest
public with sharing class Test_ListOptional {

    @IsTest
    static void testGetItemFromPopulatedList() {
        final Integer index = 1;
        final Object defaultValue = null;
        final Object obj = new Account();

        List<Object> objects = new List<Object>{
            new Account(),
            obj,
            new Account()
        };

        Test.startTest();
            Object returnedObj = new ListOptional(objects).get(index, defaultValue);
        Test.stopTest();

        System.assertEquals(obj, returnedObj, 'The second object from populated list should be returned');
    }

    @IsTest
    static void testGetDefaultItemFromPopulatedList() {
        final String defaultValue = 'default value';
        List<Object> objects = new List<Object>{new Account()};

        Test.startTest();
            String returnedObj = (String) new ListOptional(objects).get(objects.size(), defaultValue);
        Test.stopTest();

        System.assertEquals(defaultValue, returnedObj, 'Default value should be returned because index is incorrect');
    }

    @IsTest
    static void testGetDefaultItemFromEmptyList() {
        final String defaultValue = 'default value';

        Test.startTest();
            String returnedObj = (String) new ListOptional(new List<Object>()).get(10, defaultValue);
        Test.stopTest();

        System.assertEquals(defaultValue, returnedObj, 'Default value should be returned because list is empty');
    }

    @IsTest
    static void testGetFirst() {
        final Object obj = new Account();

        List<Object> objects = new List<Object>{
            obj,
            new Account(),
            new Account()
        };

        Test.startTest();
            Object returnedObj = new ListOptional(objects).getFirst();
        Test.stopTest();

        System.assertEquals(obj, returnedObj, 'The first object from populated list should be returned');
    }

    @IsTest
    static void testGetFirstNull() {
        Test.startTest();
            Object returnedObj = new ListOptional(new List<Object>()).getFirst();
        Test.stopTest();

        System.assertEquals(null, returnedObj, 'Null should be returned because list is empty');
    }

    @IsTest
    static void testGetLast() {
        final Object obj = new Account();

        List<Object> objects = new List<Object>{
            new Account(),
            new Account(),
            obj
        };

        Test.startTest();
            Object returnedObj = new ListOptional(objects).getLast();
        Test.stopTest();

        System.assertEquals(obj, returnedObj, 'The first object from populated list should be returned');
    }

    @IsTest
    static void testGetLastNull() {
        Test.startTest();
            Object returnedObj = new ListOptional(new List<Object>()).getLast();
        Test.stopTest();

        System.assertEquals(null, returnedObj, 'Null should be returned because list is empty');
    }
}