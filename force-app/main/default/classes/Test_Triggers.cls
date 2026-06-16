@isTest
private class Test_Triggers {
    private static final String NEW_ACCOUNT_NAME = 'New Test Account';
    private static final String OLD_ACCOUNT_NAME = 'Old Test Account';
    private static final String ANOTHER_NEW_ACCOUNT_NAME = 'Another ' + NEW_ACCOUNT_NAME;
    private static final String ANOTHER_OLD_ACCOUNT_NAME = 'Another ' + OLD_ACCOUNT_NAME;
    private static final String DIFFERENT_NEW_ACCOUNT_NAME = 'Different ' + NEW_ACCOUNT_NAME;

    private static final Integer EXPECTED_HANDLERS_COUNT = TriggerOperation.values().size() + 1; // +1 for null operation
    private static final Integer NUMBER_OF_TRIGGER_OPERATIONS = 6;

    private static final String IS_INSERT = 'isInsert';
    private static final String IS_UPDATE = 'isUpdate';
    private static final String IS_DELETE = 'isDelete';
    private static final String IS_UNDELETE = 'isUndelete';
    private static final String IS_BEFORE = 'isBefore';
    private static final String IS_AFTER = 'isAfter';
    private static final String NEW_MAP_METHOD = 'newMap';
    private static final String OLD_MAP_METHOD = 'oldMap';

    private static final String EXPECTED_RESULTS_MUST_BE_8 = 'Expected results must be given for all 7 Trigger Operations and for scenario with null as Trigger Operation.';
    private static final String EXPECTED_RESULTS_MUST_BE_GIVEN_FOR_ALL_OPERATION_METHODS = 'Expected results must be given for all Trigger Operation methods.';
    private static final String OLD_VALUE_ASSERT_MSG = 'TriggerHelper.oldValue() must return {0} during {1}';
    private static final String OLD_RECORD_ASSERT_MSG = 'TriggerHelper.oldRecord() must return the old record during {0}.';
    private static final String OLD_RECORD_ASSERT_IS_NULL_MSG = 'TriggerHelper.oldRecord() must return null during {0}.';
    private static final String OLD_RECORDS_ASSERT_MSG = 'TriggerHelper.oldRecords() must return the old records during {0}.';
    private static final String OLD_RECORDS_ASSERT_IS_NULL_MSG = 'TriggerHelper.oldRecords() must return null during {0}.';
    private static final String TRIGGER_OPERATION_ASSERT_MSG = 'TriggerHelper.{0}() must return {1} if operation is {2}.';

    private static final String ALL = 'all';
    private static final String ONE = 'one';
    private static final String NONE = 'none';
    private static final String NULL_STR = 'null';
    private static final String EMPTY_STR = '';
    private static final String NOT_STR = 'not';
    private static final String NON = 'non';

    private static final String IS_STR = 'is';
    private static final String ARE_STR = 'are';
    private static final String CHANGED_STR = 'changed';
    private static final String CASE_STR = 'case';
    private static final String CASE_INSENSITIVE = 'case insensitive';
    private static final String NEW_MAP = 'new map';
    private static final String OLD_MAP = 'old map';

    private static final String TO_ONE_OF_THE = 'to one of the';
    private static final String VALUE = 'value';
    private static final String NEW_VALUE = 'new value';
    private static final String NEW_VALUES = 'new values';
    private static final String TO_THE_EXACT = 'to the exact';
    private static final String TO_ANOTHER = 'to another';
    private static final String TO_DIFFERENT = 'to different';
    private static final String TO_NON_NULL = 'to ' + NON + ' ' + NULL_STR;

    private static final String ENDING_FORMAT = '{0} {1} {2}';
    private static final String NOT_CHANGED = String.format(ENDING_FORMAT, new List<String> {NOT_STR, CHANGED_STR});
    private static final String CHANGED_TO_EXACT_NEW_VALUE = String.format(ENDING_FORMAT, new List<String> {CHANGED_STR, TO_THE_EXACT, NEW_VALUE});
    private static final String CHANGED_TO_ANOTHER_NEW_VALUE = String.format(ENDING_FORMAT, new List<String> {CHANGED_STR, TO_ANOTHER, NEW_VALUE});
    private static final String CHANGED_TO_DIFFERENT_NEW_VALUE = String.format(ENDING_FORMAT, new List<String> {CHANGED_STR, TO_DIFFERENT, NEW_VALUE});
    private static final String CHANGED_TO_DIFFERENT_CASE = String.format(ENDING_FORMAT, new List<String> {CHANGED_STR, TO_DIFFERENT, CASE_STR});
    private static final String CHANGED_TO_ONE_OF_THE_NEW_VALUES = String.format(ENDING_FORMAT, new List<String> {CHANGED_STR, TO_ONE_OF_THE, NEW_VALUES});
    private static final String CHANGED_TO_NON_NULL_VALUE = String.format(ENDING_FORMAT, new List<String> {CHANGED_STR, TO_NON_NULL, VALUE});
    private static final String CHANGED_TO_NULL_VALUE = String.format(ENDING_FORMAT, new List<String> {CHANGED_STR, 'to ' + NULL_STR, VALUE});

    private static final String IS_CHANGED_ANY_FIELD_ASSERT_MSG = 'TriggerHelper.isChangedAnyField() must return {0} if {1} of the fields {2} changed.';
    private static final String IS_CHANGED_FIELD_TO_ANY_STRING_ASSERT_MSG = 'TriggerHelper.isChangedFieldToAnyString() must return {0} if the field is {1}.';
    private static final String IS_CHANGED_FIELD_TO_ASSERT_MSG = 'TriggerHelper.isChangedFieldTo() must return {0} if the field is {1}.';
    private static final String IS_CHANGED_FIELD_TO_ANY_STRING_CASE_INSENSITIVE_ASSERT_MSG = 'TriggerHelper.isChangedFieldToAnyStringCaseInsensitive() must return {0} if the field is {1}.';
    private static final String IS_CHANGED_FIELD_TO_NON_NULL_ASSERT_MSG = 'TriggerHelper.isChangedFieldToNonNull() must return {0} if the field is {1}.';

    // isChangedFieldFrom() assert messages
    private static final String IS_CHANGED_FIELD_FROM_ASSERT_MSG_WHEN_FIELD_NOT_CHANGED = 'TriggerHelper.isChangedFieldFrom() must return false if the field is not changed.';
    private static final String IS_CHANGED_FIELD_FROM_ASSERT_MSG_WHEN_FIELD_CHANGED_FROM_EXACT = 'TriggerHelper.isChangedFieldFrom() must return true if the field is changed from the exact old value.';
    private static final String IS_CHANGED_FIELD_FROM_ASSERT_MSG_WHEN_FIELD_CHANGED_FROM_ANOTHER = 'TriggerHelper.isChangedFieldFrom() must return false if the field is changed from another old value.';

    // isChangedField() assert messages
    private static final String POPULATED = 'populated';
    private static final String FROM_SOMETHING_TO_SOMETHING = 'from {0} to {1}';
    private static final String IS_CHANGED_FIELD_ASSERT_MSG_FOR_INSERT_DELETE_UNDELETE = 'TriggerHelper.isChangedField() must return {0} if the field is {1} during {2}.';
    private static final String IS_CHANGED_FIELD_ASSERT_MSG_FOR_UPDATE = 'TriggerHelper.isChangedField() must return {0} if the field is {1} changed {2} during {3}.';
    private static final String IS_CHANGED_FIELD_ASSERT_MSG_FOR_NULL_OPERATION = 'TriggerHelper.isChangedField() must always return false if the operation is null.';

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testTriggersContextVariablesDuringDMLOperation() {
        Account acc = (Account) new SObjectBuilder(Account.getSObjectType())
            .setField(Account.Name, NEW_ACCOUNT_NAME)
            .build()
            .getRecord();

        Test.startTest();
            insert acc;
            update acc;
            delete acc;
            undelete acc;
        Test.stopTest();
    }

    @isTest
    static void testGetOldMap() {
        Map<Id, SObject> expectedOldMap = new Map<Id, SObject>();

        Test.startTest();
            Map<Id, SObject> actualOldMap = Triggers.getOldMap();
        Test.stopTest();

        Assert.areEqual(expectedOldMap, actualOldMap, 'Triggers.getOldMap() must return a map.');
    }

    @isTest
    static void testGetNewMap() {
        Map<Id, SObject> expectedNewMap = new Map<Id, SObject>();

        Test.startTest();
            Map<Id, SObject> actualNewMap = Triggers.getNewMap();
        Test.stopTest();

        Assert.areEqual(expectedNewMap, actualNewMap, 'Triggers.getNewMap() must return a map.');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testOldValue() {
        Id dummyId = (Id) ValueProviderBuilder.provideDummyId(Account.sObjectType).getValue();

        List<Account> accs = (List<Account>) new SObjectBuilder(Account.sObjectType)
            .setField(Account.Name, ValueProviderBuilder.provideList(new List<String> {NEW_ACCOUNT_NAME, OLD_ACCOUNT_NAME}))
            .setField(Account.Id, dummyId)
            .quantity(2)
            .build()
            .getRecords();
        Account newAcc = accs[0];
        Account oldAcc = accs[1];

        Map<TestTriggerHelper, Object> helperToExpectedResultMap = getHelperToExpectedResultMap(
            new List<Account> { newAcc },
            new Map<Id, Account> { newAcc.Id => oldAcc },
            new Map<TriggerOperation, Object> {
                TriggerOperation.BEFORE_INSERT => null,
                TriggerOperation.AFTER_INSERT => null,
                TriggerOperation.BEFORE_UPDATE => OLD_ACCOUNT_NAME,
                TriggerOperation.AFTER_UPDATE => OLD_ACCOUNT_NAME,
                TriggerOperation.BEFORE_DELETE => OLD_ACCOUNT_NAME,
                TriggerOperation.AFTER_DELETE => OLD_ACCOUNT_NAME,
                TriggerOperation.AFTER_UNDELETE => null,
                null => OLD_ACCOUNT_NAME
            }
        );

        Test.startTest();
            for (TestTriggerHelper helper : helperToExpectedResultMap.keySet()) {
                assertOldValue(helper, newAcc, helperToExpectedResultMap.get(helper));
            }
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testOldRecord() {
        Id dummyId = (Id) ValueProviderBuilder.provideDummyId(Account.sObjectType).getValue();

        List<Account> accs = (List<Account>) new SObjectBuilder(Account.sObjectType)
            .setField(Account.Name, NEW_ACCOUNT_NAME)
            .setField(Account.Id, dummyId)
            .quantity(2)
            .build()
            .getRecords();
        Account newAcc = accs[0];
        Account oldAcc = accs[1];
        Map<Id, Account> oldMap = new Map<Id, Account> { newAcc.Id => oldAcc };

        Map<TestTriggerHelper, Object> helperToExpectedResultMap = getHelperToExpectedResultMap(
            new List<Account> { newAcc },
            oldMap,
            new Map<TriggerOperation, Object> {
                TriggerOperation.BEFORE_INSERT => null,
                TriggerOperation.AFTER_INSERT => null,
                TriggerOperation.BEFORE_UPDATE => oldAcc,
                TriggerOperation.AFTER_UPDATE => oldAcc,
                TriggerOperation.BEFORE_DELETE => oldAcc,
                TriggerOperation.AFTER_DELETE => oldAcc,
                TriggerOperation.AFTER_UNDELETE => null,
                null => oldAcc
            }
        );

        Test.startTest();
            for (TestTriggerHelper helper : helperToExpectedResultMap.keySet()) {
                assertOldRecord(helper, newAcc, helperToExpectedResultMap.get(helper));
            }
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testOldRecords() {
        Id dummyId = (Id) ValueProviderBuilder.provideDummyId(Account.sObjectType).getValue();

        List<Account> accs = (List<Account>) new SObjectBuilder(Account.sObjectType)
            .setField(Account.Name, ValueProviderBuilder.provideList(new List<String> {NEW_ACCOUNT_NAME, OLD_ACCOUNT_NAME}))
            .setField(Account.Id, dummyId)
            .quantity(2)
            .build()
            .getRecords();
        Account newAcc = accs[0];
        Account oldAcc = accs[1];

        Map<Id, Account> oldMap = new Map<Id, Account> { newAcc.Id => oldAcc };
        List<Account> oldRecords = oldMap.values();

        Map<TestTriggerHelper, Object> helperToExpectedResultMap = getHelperToExpectedResultMap(
            new List<Account> { newAcc },
            oldMap,
            new Map<TriggerOperation, Object> {
                TriggerOperation.BEFORE_INSERT => null,
                TriggerOperation.AFTER_INSERT => null,
                TriggerOperation.BEFORE_UPDATE => oldRecords,
                TriggerOperation.AFTER_UPDATE => oldRecords,
                TriggerOperation.BEFORE_DELETE => oldRecords,
                TriggerOperation.AFTER_DELETE => oldRecords,
                TriggerOperation.AFTER_UNDELETE => null,
                null => null
            }
        );

        Test.startTest();
            for (TestTriggerHelper helper : helperToExpectedResultMap.keySet()) {
                assertOldRecords(helper, (List<SObject>) helperToExpectedResultMap.get(helper));
            }
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testNewMap() {
        IValueProvider dummyIdProvider = ValueProviderBuilder.provideDummyId(Account.sObjectType);
        List<Account> newList = (List<Account>) new SObjectBuilder(Account.sObjectType)
            .setField(Account.Name, NEW_ACCOUNT_NAME)
            .setField(Account.Id, dummyIdProvider)
            .quantity(1)
            .build()
            .getRecords();

        Map<Id, Account> expectedNewMap = new Map<Id, Account>(newLIst);
        Map<Id, Account> oldMap = new Map<Id, Account>(newLIst);
        Map<TestTriggerHelper, Object> helperToExpectedResultMap = getHelperToExpectedResultMap(
            newList,
            oldMap,
            new Map<TriggerOperation, Object> {
                TriggerOperation.BEFORE_INSERT => null,
                TriggerOperation.AFTER_INSERT => expectedNewMap,
                TriggerOperation.BEFORE_UPDATE => expectedNewMap,
                TriggerOperation.AFTER_UPDATE => expectedNewMap,
                TriggerOperation.BEFORE_DELETE => null,
                TriggerOperation.AFTER_DELETE => null,
                TriggerOperation.AFTER_UNDELETE => expectedNewMap,
                null => null
            }
        );

        Test.startTest();
            for (TestTriggerHelper helper : helperToExpectedResultMap.keySet()) {
                assertNewOldMap(
                    helper,
                    NEW_MAP_METHOD,
                    helper.newMap(),
                    (Map<Id, SObject>) helperToExpectedResultMap.get(helper)
                );
            }
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testOldMap() {
        Id dummyId = (Id) ValueProviderBuilder.provideDummyId(Account.sObjectType).getValue();

        List<Account> accs = (List<Account>) new SObjectBuilder(Account.sObjectType)
            .setField(Account.Name, ValueProviderBuilder.provideList(new List<String> {NEW_ACCOUNT_NAME, OLD_ACCOUNT_NAME}))
            .setField(Account.Id, dummyId)
            .quantity(2)
            .build()
            .getRecords();
        Account newAcc = accs[0];
        Account oldAcc = accs[1];

        Map<Id, Account> expectedOldMap = new Map<Id, Account> { newAcc.Id => oldAcc };
        Map<TestTriggerHelper, Object> helperToExpectedResultMap = getHelperToExpectedResultMap(
            new List<Account> { newAcc },
            expectedOldMap,
            new Map<TriggerOperation, Object> {
                TriggerOperation.BEFORE_INSERT => null,
                TriggerOperation.AFTER_INSERT => null,
                TriggerOperation.BEFORE_UPDATE => expectedOldMap,
                TriggerOperation.AFTER_UPDATE => expectedOldMap,
                TriggerOperation.BEFORE_DELETE => expectedOldMap,
                TriggerOperation.AFTER_DELETE => expectedOldMap,
                TriggerOperation.AFTER_UNDELETE => null,
                null => null
            }
        );

        Test.startTest();
        for (TestTriggerHelper helper : helperToExpectedResultMap.keySet()) {
            assertNewOldMap(
                helper,
                OLD_MAP_METHOD,
                helper.oldMap(),
                (Map<Id, SObject>) helperToExpectedResultMap.get(helper)
            );
        }
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testTriggerOperation() {
        Map<TestTriggerHelper, Object> helperToExpectedResultMap = getHelperToExpectedResultMap(
            new List<Account>(),
            new Map<Id, Account>(),
            new Map<TriggerOperation, Object> {
                TriggerOperation.BEFORE_INSERT => new List<Boolean> {true, false, false, false, true, false},
                TriggerOperation.AFTER_INSERT => new List<Boolean> {true, false, false, false, false, true},
                TriggerOperation.BEFORE_UPDATE => new List<Boolean> {false, true, false, false, true, false},
                TriggerOperation.AFTER_UPDATE => new List<Boolean> {false, true, false, false, false, true},
                TriggerOperation.BEFORE_DELETE => new List<Boolean> {false, false, true, false, true, false},
                TriggerOperation.AFTER_DELETE => new List<Boolean> {false, false, true, false, false, true},
                TriggerOperation.AFTER_UNDELETE => new List<Boolean> {false, false, false, true, false, true},
                null => new List<Boolean> {false, false, false, false, false, false}
            }
        );

        Test.startTest();
            for (TestTriggerHelper helper : helperToExpectedResultMap.keySet()) {
                assertTriggerOperation(helper, (List<Boolean>) helperToExpectedResultMap.get(helper));
            }
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testIsChangedFieldOnInsert() {
        IValueProvider dummyIdProvider = ValueProviderBuilder.provideDummyId(Account.sObjectType);

        List<Account> newList = (List<Account>) new SObjectBuilder(Account.sObjectType)
            .setField(Account.Name, ValueProviderBuilder.provideList(new List<String> {NEW_ACCOUNT_NAME, null}))
            .setField(Account.Id, dummyIdProvider)
            .quantity(2)
            .build()
            .getRecords();
        Account newAccWithName = newList[0];
        Account newAccWithNullName = newList[1];

        List<TestTriggerHelper> helpers = new List<TestTriggerHelper> {
            new TestTriggerHelper(TriggerOperation.BEFORE_INSERT, newList),
            new TestTriggerHelper(TriggerOperation.AFTER_INSERT, newList)
        };

        Test.startTest();
            for (TestTriggerHelper helper : helpers) {
                assertIsChangedFieldOnInsertDeleteUndelete(helper, newAccWithName, newAccWithNullName);
            }
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testIsChangedFieldOnUpdate() {
        IValueProvider dummyIdProvider = ValueProviderBuilder.provideDummyId(Account.sObjectType);

        List<Account> newList = (List<Account>) new SObjectBuilder(Account.sObjectType)
            .setField(Account.Name, ValueProviderBuilder.provideList(new List<String> {NEW_ACCOUNT_NAME, OLD_ACCOUNT_NAME, null, null, NEW_ACCOUNT_NAME}))
            .setField(Account.Id, dummyIdProvider)
            .quantity(5)
            .build()
            .getRecords();
        Account newAccWithNewName = newList[0];
        Account newAccWithOldName = newList[1];
        Account newAccWithNullName = newList[2];
        Account newAccWithNullName2 = newList[3];
        Account newAccWithNonNullName = newList[4];

        List<Account> oldAccs = (List<Account>) new SObjectBuilder(Account.sObjectType)
            .setField(Account.Name, ValueProviderBuilder.provideList(new List<String> {OLD_ACCOUNT_NAME, null}))
            .quantity(2)
            .build()
            .getRecords();
        Account oldAccWithOldName = oldAccs[0];
        Account oldAccWithNullName = oldAccs[1];
        Map<Id, Account> oldMap = new Map<Id, Account> {
            newAccWithNewName.Id => oldAccWithOldName,
            newAccWithOldName.Id => oldAccWithOldName,
            newAccWithNullName.Id => oldAccWithOldName,
            newAccWithNullName2.Id => oldAccWithNullName,
            newAccWithNonNullName.Id => oldAccWithNullName
        };

        List<TestTriggerHelper> helpers = new List<TestTriggerHelper> {
            new TestTriggerHelper(TriggerOperation.BEFORE_UPDATE, newList, oldMap),
            new TestTriggerHelper(TriggerOperation.AFTER_UPDATE, newList, oldMap)
        };

        Map<Account, Boolean> expectedResultsByAccount = new Map<Account, Boolean> {
            newAccWithNewName => true,
            newAccWithOldName => false,
            newAccWithNullName => true,
            newAccWithNullName2 => false,
            newAccWithNonNullName => true
        };

        Test.startTest();
            for (Account newAcc : newList) {
                assertIsChangedFieldOnUpdate(
                    helpers,
                    newAcc,
                    oldMap.get(newAcc.Id).Name,
                    expectedResultsByAccount.get(newAcc)
                );
            }
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testIsChangedFieldOnDelete() {
        IValueProvider dummyIdProvider = ValueProviderBuilder.provideDummyId(Account.sObjectType);

        List<Account> oldAccs = (List<Account>) new SObjectBuilder(Account.sObjectType)
            .setField(Account.Id, dummyIdProvider)
            .setField(Account.Name, ValueProviderBuilder.provideList(new List<String> {OLD_ACCOUNT_NAME, null}))
            .quantity(2)
            .build()
            .getRecords();
        Account oldAccWithOldName = oldAccs[0];
        Account oldAccWithNullName = oldAccs[1];

        Map<Id, Account> oldMap = new Map<Id, Account> {
            oldAccWithOldName.Id => oldAccWithOldName,
            oldAccWithNullName.Id => oldAccWithNullName
        };

        List<TestTriggerHelper> helpers = new List<TestTriggerHelper> {
            new TestTriggerHelper(TriggerOperation.BEFORE_DELETE, oldMap.values(), oldMap),
            new TestTriggerHelper(TriggerOperation.AFTER_DELETE, oldMap.values(), oldMap)
        };

        Test.startTest();
            for (TestTriggerHelper helper : helpers) {
                assertIsChangedFieldOnInsertDeleteUndelete(helper, oldAccWithOldName, oldAccWithNullName);
            }
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testIsChangedFieldOnUndelete() {
        IValueProvider dummyIdProvider = ValueProviderBuilder.provideDummyId(Account.sObjectType);

        List<Account> newList = (List<Account>) new SObjectBuilder(Account.sObjectType)
            .setField(Account.Id, dummyIdProvider)
            .setField(Account.Name, ValueProviderBuilder.provideList(new List<String> {NEW_ACCOUNT_NAME, null}))
            .quantity(2)
            .build()
            .getRecords();
        Account newAccWithName = newList[0];
        Account newAccWithNullName = newList[1];

        Test.startTest();
            assertIsChangedFieldOnInsertDeleteUndelete(
                new TestTriggerHelper(TriggerOperation.AFTER_UNDELETE, newList),
                newAccWithName,
                newAccWithNullName
            );
        Test.stopTest();
    }

    @isTest
    static void testIsChangedFieldOnNullOperation() {
        IValueProvider dummyIdProvider = ValueProviderBuilder.provideDummyId(Account.sObjectType);

        List<Account> newList = (List<Account>) new SObjectBuilder(Account.sObjectType)
            .setField(Account.Id, dummyIdProvider)
            .setField(Account.Name, ValueProviderBuilder.provideList(new List<String> {
                NEW_ACCOUNT_NAME,
                null,
                OLD_ACCOUNT_NAME
            }))
            .quantity(3)
            .build()
            .getRecords();
        Account newAccWithNewName = newList[0];
        Account newAccWithNullName = newList[1];
        Account newAccWithOldName = newList[2];

        Account oldAccWithOldName = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.Name, OLD_ACCOUNT_NAME)
            .build()
            .getRecord();
        Map<Id, Account> oldMap = new Map<Id, Account> {
            newAccWithNewName.Id => oldAccWithOldName,
            newAccWithNullName.Id => oldAccWithOldName,
            newAccWithOldName.Id => oldAccWithOldName
        };

        TestTriggerHelper helperOnNullOperation = new TestTriggerHelper(null, newList, oldMap);
        TestTriggerHelper helperOnNullOperationNoOldMap = new TestTriggerHelper(null, newList);

        Test.startTest();
            for (Account newAcc : newList) {
                Assert.isFalse(
                    helperOnNullOperation.isChangedField(newAcc, Account.Name),
                    IS_CHANGED_FIELD_ASSERT_MSG_FOR_NULL_OPERATION
                );
                Assert.isFalse(
                    helperOnNullOperationNoOldMap.isChangedField(newAcc, Account.Name),
                    IS_CHANGED_FIELD_ASSERT_MSG_FOR_NULL_OPERATION
                );
            }
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testIsChangedAnyField() {
        IValueProvider dummyIdProvider = ValueProviderBuilder.provideDummyId(Account.sObjectType);
        Set<SObjectField> fieldsToCheck = new Set<SObjectField> { Account.Name, Account.Type };

        List<Account> newList = (List<Account>) new SObjectBuilder(Account.sObjectType)
            .setField(Account.Id, dummyIdProvider)
            .setField(Account.Name, ValueProviderBuilder.provideList(new List<String> {
                OLD_ACCOUNT_NAME,
                NEW_ACCOUNT_NAME,
                NEW_ACCOUNT_NAME
            }))
            .setField(Account.Type, ValueProviderBuilder.provideList(new List<String> {
                AccountHelper.TYPE_CUSTOMER,
                AccountHelper.TYPE_CUSTOMER,
                AccountHelper.TYPE_PARTNER
            }))
            .quantity(3)
            .build()
            .getRecords();
        Account newAccWithOldValues = newList[0];
        Account newAccWithNewName = newList[1];
        Account newAccWithNewValues = newList[2];

        Account oldAcc = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.Name, OLD_ACCOUNT_NAME)
            .setField(Account.Type, AccountHelper.TYPE_CUSTOMER)
            .build()
            .getRecord();
        Map<Id, Account> oldMap = new Map<Id, Account> {
            newAccWithOldValues.Id => oldAcc,
            newAccWithNewName.Id => oldAcc,
            newAccWithNewValues.Id => oldAcc
        };

        Map<Account, String> fieldsChangedByAccount = new Map<Account, String> {
            newAccWithOldValues => NONE,
            newAccWithNewName => ONE,
            newAccWithNewValues => ALL
        };
        Map<Account, Boolean> expectedResultsByAccount = new Map<Account, Boolean> {
            newAccWithOldValues => false,
            newAccWithNewName => true,
            newAccWithNewValues => true
        };

        TestTriggerHelper helperBeforeUpdate = new TestTriggerHelper(TriggerOperation.BEFORE_UPDATE, newList, oldMap);

        Test.startTest();
            for (Account newAcc : newList) {
                asserttestIsChangedAnyField(
                    helperBeforeUpdate,
                    newAcc,
                    fieldsToCheck,
                    fieldsChangedByAccount.get(newAcc),
                    expectedResultsByAccount.get(newAcc)
                );
            }
        Test.stopTest();
    }

    // TODO: Simplify this test
    @isTest
    static void testIsChangedFieldFrom() {
        IValueProvider dummyIdProvider = ValueProviderBuilder.provideDummyId(Account.sObjectType);

        List<Account> newList = (List<Account>) new SObjectBuilder(Account.sObjectType)
            .setField(Account.Id, dummyIdProvider)
            .setField(Account.Name, ValueProviderBuilder.provideList(new List<String> {
                NEW_ACCOUNT_NAME,
                OLD_ACCOUNT_NAME,
                ANOTHER_OLD_ACCOUNT_NAME
            }))
            .quantity(3)
            .build()
            .getRecords();
        Account newAccWithNewName = newList[0];
        Account newAccWithOldName = newList[1];
        Account newAccWithAnotherOldName = newList[2];

        List<Account> oldAccs = (List<Account>) new SObjectBuilder(Account.sObjectType)
            .setField(Account.Id, dummyIdProvider)
            .setField(Account.Name, ValueProviderBuilder.provideList(new List<String> {OLD_ACCOUNT_NAME, ANOTHER_OLD_ACCOUNT_NAME}))
            .quantity(2)
            .build()
            .getRecords();
        Account oldAccWithOldName = oldAccs[0];
        Account oldAccWithAnotherOldName = oldAccs[1];

        Map<Id, Account> oldMapExactOldName = new Map<Id, Account> {
            newAccWithNewName.Id => oldAccWithOldName,
            newAccWithOldName.Id => oldAccWithOldName
        };
        Map<Id, Account> oldMapAnotherOldName = new Map<Id, Account> {
            newAccWithNewName.Id => oldAccWithAnotherOldName,
            newAccWithAnotherOldName.Id => oldAccWithAnotherOldName
        };

        TestTriggerHelper helperWithExactOldName = new TestTriggerHelper(TriggerOperation.BEFORE_UPDATE, newList, oldMapExactOldName);
        TestTriggerHelper helperWithAnotherOldName = new TestTriggerHelper(TriggerOperation.BEFORE_UPDATE, newList, oldMapAnotherOldName);

        Test.startTest();
            Assert.isTrue(
                helperWithExactOldName.isChangedFieldFrom(newAccWithNewName, Account.Name, OLD_ACCOUNT_NAME),
                IS_CHANGED_FIELD_FROM_ASSERT_MSG_WHEN_FIELD_CHANGED_FROM_EXACT
            );
            Assert.isFalse(
                helperWithExactOldName.isChangedFieldFrom(newAccWithOldName, Account.Name, OLD_ACCOUNT_NAME),
                IS_CHANGED_FIELD_FROM_ASSERT_MSG_WHEN_FIELD_NOT_CHANGED
            );
            Assert.isFalse(
                helperWithAnotherOldName.isChangedFieldFrom(newAccWithNewName, Account.Name, OLD_ACCOUNT_NAME),
                IS_CHANGED_FIELD_FROM_ASSERT_MSG_WHEN_FIELD_CHANGED_FROM_ANOTHER
            );
            Assert.isFalse(
                helperWithAnotherOldName.isChangedFieldFrom(newAccWithOldName, Account.Name, OLD_ACCOUNT_NAME),
                IS_CHANGED_FIELD_FROM_ASSERT_MSG_WHEN_FIELD_NOT_CHANGED
            );
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testIsChangedFieldTo() {
        IValueProvider dummyIdProvider = ValueProviderBuilder.provideDummyId(Account.sObjectType);
        List<Account> newList = (List<Account>) new SObjectBuilder(Account.sObjectType)
            .setField(Account.Id, dummyIdProvider)
            .setField(Account.Name, ValueProviderBuilder.provideList(new List<String> {
                OLD_ACCOUNT_NAME,
                NEW_ACCOUNT_NAME,
                ANOTHER_NEW_ACCOUNT_NAME
            }))
            .quantity(3)
            .build()
            .getRecords();
        Account newAccWithOldName = newList[0];
        Account newAccWithNewExactName = newList[1];
        Account newAccWithNewAnotherName = newList[2];

        Account oldAcc = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.Name, OLD_ACCOUNT_NAME)
            .build()
            .getRecord();
        Map<Id, Account> oldMap = new Map<Id, Account> {
            newAccWithOldName.Id => oldAcc,
            newAccWithNewExactName.Id => oldAcc,
            newAccWithNewAnotherName.Id => oldAcc
        };

        Map<Account, String> accountToAssertMsgMap = new Map<Account, String> {
            newAccWithOldName => NOT_CHANGED,
            newAccWithNewExactName => CHANGED_TO_EXACT_NEW_VALUE,
            newAccWithNewAnotherName => CHANGED_TO_ANOTHER_NEW_VALUE
        };
        Map<Account, Boolean> accountToExpectedResultMap = new Map<Account, Boolean> {
            newAccWithOldName => false,
            newAccWithNewExactName => true,
            newAccWithNewAnotherName => false
        };

        TestTriggerHelper helper = new TestTriggerHelper(TriggerOperation.BEFORE_UPDATE, newList, oldMap);

        Test.startTest();
            for (Account newAcc : newList) {
                assertIsChangedFieldTo(
                    helper,
                    newAcc,
                    accountToExpectedResultMap.get(newAcc),
                    accountToAssertMsgMap.get(newAcc)
                );
            }
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testIsChangedFieldToAnyString() {
        IValueProvider dummyIdProvider = ValueProviderBuilder.provideDummyId(Account.sObjectType);
        Set<String> newNamesToCheck = new Set<String> { NEW_ACCOUNT_NAME, ANOTHER_NEW_ACCOUNT_NAME };

        List<Account> newList = (List<Account>) new SObjectBuilder(Account.sObjectType)
            .setField(Account.Id, dummyIdProvider)
            .setField(Account.Name, ValueProviderBuilder.provideList(new List<String> {
                OLD_ACCOUNT_NAME,
                NEW_ACCOUNT_NAME,
                DIFFERENT_NEW_ACCOUNT_NAME
            }))
            .quantity(3)
            .build()
            .getRecords();
        Account newAccWithOldName = newList[0];
        Account newAccWithNewName = newList[1];
        Account newAccWithDifferentNewName = newList[2];

        Account oldAcc = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.Name, OLD_ACCOUNT_NAME)
            .build()
            .getRecord();
        Map<Id, Account> oldMap = new Map<Id, Account> {
            newAccWithNewName.Id => oldAcc,
            newAccWithDifferentNewName.Id => oldAcc,
            newAccWithOldName.Id => oldAcc
        };

        Map<Account, String> accountToAssertMsgMap = new Map<Account, String> {
            newAccWithOldName => NOT_CHANGED,
            newAccWithNewName => CHANGED_TO_ONE_OF_THE_NEW_VALUES,
            newAccWithDifferentNewName => CHANGED_TO_DIFFERENT_NEW_VALUE
        };
        Map<Account, Boolean> accountToExpectedResultMap = new Map<Account, Boolean> {
            newAccWithOldName => false,
            newAccWithNewName => true,
            newAccWithDifferentNewName => false
        };

        TestTriggerHelper helper = new TestTriggerHelper(TriggerOperation.BEFORE_UPDATE, newList, oldMap);

        Test.startTest();
            for (Account newAcc : newList) {
                assertIsChangedFieldToAnyString(
                    helper,
                    newAcc,
                    newNamesToCheck,
                    accountToExpectedResultMap.get(newAcc),
                    accountToAssertMsgMap.get(newAcc)
                );
            }
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testIsChangedToAnyStringCaseInsensitive() {
        IValueProvider dummyIdProvider = ValueProviderBuilder.provideDummyId(Account.sObjectType);
        Set<String> newNamesToCheck = new Set<String> { NEW_ACCOUNT_NAME, ANOTHER_NEW_ACCOUNT_NAME };

        List<Account> newList = (List<Account>) new SObjectBuilder(Account.sObjectType)
            .setField(Account.Id, dummyIdProvider)
            .setField(Account.Name, ValueProviderBuilder.provideList(new List<String> {
                OLD_ACCOUNT_NAME,
                NEW_ACCOUNT_NAME,
                NEW_ACCOUNT_NAME.toUpperCase(),
                DIFFERENT_NEW_ACCOUNT_NAME,
                OLD_ACCOUNT_NAME.toUpperCase()
            }))
            .quantity(5)
            .build()
            .getRecords();
        Account newAccWithOldName = newList[0];
        Account newAccWithNewName = newList[1];
        Account newAccWithNewNameUpperCase = newList[2];
        Account newAccWithDifferentNewName = newList[3];
        Account newAccWithUpperCaseOldName = newList[4];

        Account oldAcc = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.Name, OLD_ACCOUNT_NAME)
            .build()
            .getRecord();
        Map<Id, Account> oldMap = new Map<Id, Account> {
            newAccWithNewName.Id => oldAcc,
            newAccWithDifferentNewName.Id => oldAcc,
            newAccWithOldName.Id => oldAcc,
            newAccWithNewNameUpperCase.Id => oldAcc,
            newAccWithUpperCaseOldName.Id => oldAcc
        };

        Map<Account, String> accountToAssertMsgMap = new Map<Account, String> {
            newAccWithOldName => NOT_CHANGED,
            newAccWithNewName => CHANGED_TO_ONE_OF_THE_NEW_VALUES,
            newAccWithNewNameUpperCase => CHANGED_TO_ONE_OF_THE_NEW_VALUES + ' ' + CASE_INSENSITIVE,
            newAccWithDifferentNewName => CHANGED_TO_DIFFERENT_NEW_VALUE,
            newAccWithUpperCaseOldName => CHANGED_TO_DIFFERENT_CASE
        };
        Map<Account, Boolean> accountToExpectedResultMap = new Map<Account, Boolean> {
            newAccWithOldName => false,
            newAccWithNewName => true,
            newAccWithNewNameUpperCase => true,
            newAccWithDifferentNewName => false,
            newAccWithUpperCaseOldName => false
        };

        TestTriggerHelper helper = new TestTriggerHelper(TriggerOperation.BEFORE_UPDATE, newList, oldMap);

        Test.startTest();
            for (Account acc : newList) {
                assertIsChangedToAnyStringCaseInsensitive(
                    helper,
                    acc,
                    newNamesToCheck,
                    accountToExpectedResultMap.get(acc),
                    accountToAssertMsgMap.get(acc)
                );
            }
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testIsChangedFieldToNonNull() {
        IValueProvider dummyIdProvider = ValueProviderBuilder.provideDummyId(Account.sObjectType);

        List<Account> newList = (List<Account>) new SObjectBuilder(Account.sObjectType)
            .setField(Account.Id, dummyIdProvider)
            .setField(Account.Name, ValueProviderBuilder.provideList(new List<String> {
                OLD_ACCOUNT_NAME,
                NEW_ACCOUNT_NAME,
                null
            }))
            .quantity(3)
            .build()
            .getRecords();
        Account newAccWithOldName = newList[0];
        Account newAccWithNewName = newList[1];
        Account newAccWithNullName = newList[2];

        Account oldAcc = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.Name, OLD_ACCOUNT_NAME)
            .build()
            .getRecord();
        Map<Id, Account> oldMap = new Map<Id, Account> {
            newAccWithNewName.Id => oldAcc,
            newAccWithNullName.Id => oldAcc,
            newAccWithOldName.Id => oldAcc
        };

        Map<Account, String> accountToAssertMsgMap = new Map<Account, String> {
            newAccWithOldName => NOT_CHANGED,
            newAccWithNewName => CHANGED_TO_NON_NULL_VALUE,
            newAccWithNullName => CHANGED_TO_NULL_VALUE
        };
        Map<Account, Boolean> accountToExpectedResultMap = new Map<Account, Boolean> {
            newAccWithOldName => false,
            newAccWithNewName => true,
            newAccWithNullName => false
        };

        TestTriggerHelper helper = new TestTriggerHelper(TriggerOperation.BEFORE_UPDATE, newList, oldMap);

        Test.startTest();
            for (Account acc : newList) {
                assertIsChangedFieldToNonNull(
                    helper,
                    acc,
                    accountToExpectedResultMap.get(acc),
                    accountToAssertMsgMap.get(acc)
                );
            }
        Test.stopTest();
    }

    private class TestTriggerHelper extends Triggers.TriggerHelper {
        public TestTriggerHelper(TriggerOperation operationType) {
            super(Trigger.isExecuting, operationType, new List<SObject>());
        }

        public TestTriggerHelper(TriggerOperation operationType, List<SObject> newRecords) {
            super(Trigger.isExecuting, operationType, newRecords, new List<SObject>(), new Map<Id, SObject>(newRecords), new Map<Id, SObject>());
        }

        public TestTriggerHelper(TriggerOperation triggerOperation, List<SObject> newRecords, Map<Id, SObject> oldMap) {
            super(Trigger.isExecuting, triggerOperation, newRecords, oldMap.values(), new Map<Id, SObject>(newRecords), oldMap);
        }
    }

    private static void putTestTriggerHelper(
        Map<TestTriggerHelper, Object> helperToExpectedResultMap,
        TestTriggerHelper helper,
        Map<TriggerOperation, Object> expectedResults
    ) {
        helperToExpectedResultMap.put(
            helper,
            expectedResults.get(helper.OPERATION_TYPE)
        );
    }

    private static Map<TestTriggerHelper, Object> getHelperToExpectedResultMap(List<Account> newList, Map<Id, Account> oldMap, Map<TriggerOperation, Object> expectedResultsByOperation) {
        Assert.areEqual(EXPECTED_HANDLERS_COUNT, expectedResultsByOperation.size(), EXPECTED_RESULTS_MUST_BE_8);

        Map<TestTriggerHelper, Object> helperToExpectedResultMap = new Map<TestTriggerHelper, Object>();
        helperToExpectedResultMap.put(new TestTriggerHelper(TriggerOperation.BEFORE_INSERT, newList), expectedResultsByOperation.get(TriggerOperation.BEFORE_INSERT));
        helperToExpectedResultMap.put(new TestTriggerHelper(TriggerOperation.AFTER_INSERT, newList), expectedResultsByOperation.get(TriggerOperation.AFTER_INSERT));
        helperToExpectedResultMap.put(new TestTriggerHelper(TriggerOperation.BEFORE_UPDATE, newList, oldMap), expectedResultsByOperation.get(TriggerOperation.BEFORE_UPDATE));
        helperToExpectedResultMap.put(new TestTriggerHelper(TriggerOperation.AFTER_UPDATE, newList, oldMap), expectedResultsByOperation.get(TriggerOperation.AFTER_UPDATE));
        helperToExpectedResultMap.put(new TestTriggerHelper(TriggerOperation.BEFORE_DELETE, oldMap.values(), oldMap), expectedResultsByOperation.get(TriggerOperation.BEFORE_DELETE));
        helperToExpectedResultMap.put(new TestTriggerHelper(TriggerOperation.AFTER_DELETE, oldMap.values(), oldMap), expectedResultsByOperation.get(TriggerOperation.AFTER_DELETE));
        helperToExpectedResultMap.put(new TestTriggerHelper(TriggerOperation.AFTER_UNDELETE, newList), expectedResultsByOperation.get(TriggerOperation.AFTER_UNDELETE));
        helperToExpectedResultMap.put(new TestTriggerHelper(null, newList, oldMap), expectedResultsByOperation.get(null));
        return helperToExpectedResultMap;
    }

    private static void assertNewOldMap(
        TestTriggerHelper helper,
        String method,
        Map<Id, SObject> resultedMap,
        Map<Id, SObject> expectedNewMap
    ) {
        String expectedForAssertMsg = expectedNewMap == null ? NULL_STR : method == OLD_MAP_METHOD ? OLD_MAP : NEW_MAP;
        String assertMsg = String.format(
            TRIGGER_OPERATION_ASSERT_MSG,
            new List<Object> {method, expectedForAssertMsg, helper.OPERATION_TYPE}
        );

        Assert.areEqual(expectedNewMap, resultedMap, assertMsg);
    }

    private static void assertOldValue(TestTriggerHelper helper, Account inputAcc, Object expectedOldValue) {
        String assertMessage = String.format(
            OLD_VALUE_ASSERT_MSG,
            new List<Object> {expectedOldValue, helper.OPERATION_TYPE}
        );
        Assert.areEqual(
            expectedOldValue,
            helper.oldValue(inputAcc, Account.Name),
            assertMessage
        );
    }

    private static void assertOldRecord(TestTriggerHelper helper, Account inputAcc, Object expectedOldRecord) {
        String assertMessage = String.format(
            expectedOldRecord == null ? OLD_RECORD_ASSERT_IS_NULL_MSG : OLD_RECORD_ASSERT_MSG,
            new List<Object> {helper.OPERATION_TYPE}
        );

        Assert.areEqual(
            expectedOldRecord,
            helper.oldRecord(inputAcc),
            assertMessage
        );
    }

    private static void assertOldRecords(TestTriggerHelper helper, List<SObject> expectedOldRecords) {
        String assertMessage = String.format(
            expectedOldRecords == null ? OLD_RECORDS_ASSERT_IS_NULL_MSG : OLD_RECORDS_ASSERT_MSG,
            new List<Object> {helper.OPERATION_TYPE}
        );

        Assert.areEqual(
            expectedOldRecords,
            helper.oldRecords(),
            assertMessage
        );
    }

    private static String getAssertMsgForTriggerOperation(TestTriggerHelper helper, String function, Boolean expectedResult) {
        return String.format(
            TRIGGER_OPERATION_ASSERT_MSG,
            new List<Object> {function, expectedResult, helper.OPERATION_TYPE}
        );
    }

    private static void assertTriggerOperation(TestTriggerHelper helper, List<Boolean> expectedResults) {
        Assert.areEqual(NUMBER_OF_TRIGGER_OPERATIONS, expectedResults.size(), EXPECTED_RESULTS_MUST_BE_GIVEN_FOR_ALL_OPERATION_METHODS);
        Assert.areEqual(
            expectedResults[0],
            helper.isInsert(),
            getAssertMsgForTriggerOperation(helper, IS_INSERT, expectedResults[0])
        );
        Assert.areEqual(
            expectedResults[1],
            helper.isUpdate(),
            getAssertMsgForTriggerOperation(helper, IS_UPDATE, expectedResults[1])
        );
        Assert.areEqual(
            expectedResults[2],
            helper.isDelete(),
            getAssertMsgForTriggerOperation(helper, IS_DELETE, expectedResults[2])
        );
        Assert.areEqual(
            expectedResults[3],
            helper.isUndelete(),
            getAssertMsgForTriggerOperation(helper, IS_UNDELETE, expectedResults[3])
        );
        Assert.areEqual(
            expectedResults[4],
            helper.isBefore(),
            getAssertMsgForTriggerOperation(helper, IS_BEFORE, expectedResults[4])
        );
        Assert.areEqual(
            expectedResults[5],
            helper.isAfter(),
            getAssertMsgForTriggerOperation(helper, IS_AFTER, expectedResults[5])
        );
    }

    private static void assertIsChangedFieldOnInsertDeleteUndelete(TestTriggerHelper helper, Account newAccWithName, Account newAccWithNullName) {
        Assert.isTrue(
            helper.isChangedField(newAccWithName, Account.Name),
            String.format(
                IS_CHANGED_FIELD_ASSERT_MSG_FOR_INSERT_DELETE_UNDELETE,
                new List<Object> { true, POPULATED, helper.OPERATION_TYPE }
            )
        );
        Assert.isFalse(
            helper.isChangedField(newAccWithNullName, Account.Name),
            String.format(
                IS_CHANGED_FIELD_ASSERT_MSG_FOR_INSERT_DELETE_UNDELETE,
                new List<Object> { false, NULL_STR, helper.OPERATION_TYPE }
            )
        );
    }

    private static String constructAssertMsgForIsChangedFieldOnUpdate(
        TriggerOperation operation,
        Boolean expectedResult,
        String newValue,
        String oldValue
    ) {
        String fromNullMsgPart = String.format(
            FROM_SOMETHING_TO_SOMETHING,
            new List<String> {
                oldValue == null ? NULL_STR : NON + NULL_STR,
                newValue == null ? NULL_STR : NON + NULL_STR
            }
        );

        return String.format(
            IS_CHANGED_FIELD_ASSERT_MSG_FOR_UPDATE,
            new List<Object> {
                expectedResult,
                expectedResult ? EMPTY_STR : NOT_STR,
                fromNullMsgPart,
                operation
            }
        );
    }

    private static void assertIsChangedFieldOnUpdate(
        List<TestTriggerHelper> helpers,
        Account newAcc,
        String oldValue,
        Boolean expectedResult
    ) {
        for (TestTriggerHelper helper : helpers) {
            Assert.areEqual(
                expectedResult,
                helper.isChangedField(newAcc, Account.Name),
                constructAssertMsgForIsChangedFieldOnUpdate(
                    helper.OPERATION_TYPE,
                    expectedResult,
                    newAcc.Name,
                    oldValue
                )
            );
        }
    }

    private static void asserttestIsChangedAnyField(
        TestTriggerHelper helper,
        Account inputAcc,
        Set<SObjectField> fieldsToCheck,
        String adjective,
        Boolean expectedResult
    ) {
        String assertMessage = String.format(
            IS_CHANGED_ANY_FIELD_ASSERT_MSG,
            new List<Object> {
                expectedResult,
                adjective,
                adjective == ONE ? IS_STR : ARE_STR,
                helper.OPERATION_TYPE
            }
        );

        Assert.areEqual(
            expectedResult,
            helper.isChangedAnyField(inputAcc, fieldsToCheck),
            assertMessage
        );
    }

    private static void assertIsChangedFieldTo(
        TestTriggerHelper helper,
        Account newAcc,
        Boolean expectedResult,
        String endingForAssertMsg
    ) {
        String assertMessage = String.format(
            IS_CHANGED_FIELD_TO_ASSERT_MSG,
            new List<Object> {expectedResult, endingForAssertMsg}
        );

        Assert.areEqual(
            expectedResult,
            helper.isChangedFieldTo(newAcc, Account.Name, NEW_ACCOUNT_NAME),
            assertMessage
        );
    }

    private static void assertIsChangedFieldToAnyString(
        TestTriggerHelper helper,
        Account newAcc,
        Set<String> newValues,
        Boolean expectedResult,
        String assertMessageEnding
    ) {
        String assertMessage = String.format(
            IS_CHANGED_FIELD_TO_ANY_STRING_ASSERT_MSG,
            new List<Object> {expectedResult, assertMessageEnding}
        );
        Assert.areEqual(
            expectedResult,
            helper.isChangedFieldToAnyString(newAcc, Account.Name, newValues),
            assertMessage
        );
    }

    private static void assertIsChangedToAnyStringCaseInsensitive(
        TestTriggerHelper helper,
        Account record,
        Set<String> newValues,
        Boolean expectedResult,
        String assertMsgEnding
    ) {
        String assertMsg = String.format(
            IS_CHANGED_FIELD_TO_ANY_STRING_CASE_INSENSITIVE_ASSERT_MSG,
            new List<Object> {expectedResult, assertMsgEnding}
        );

        Assert.areEqual(
            expectedResult,
            helper.isChangedToAnyStringCaseInsensitive(record, Account.Name, newValues),
            assertMsg
        );
    }

    private static void assertIsChangedFieldToNonNull(TestTriggerHelper helper, Account acc, Boolean expectedResult, String assertMsgEnding) {
        String assertMsg = String.format(
            IS_CHANGED_FIELD_TO_NON_NULL_ASSERT_MSG,
            new List<Object> {expectedResult, assertMsgEnding}
        );

        Assert.areEqual(
            expectedResult,
            helper.isChangedFieldToNonNull(acc, Account.Name),
            assertMsg
        );
    }
}