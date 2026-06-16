@IsTest
private class Test_EventSelector {
    private static final String TEST_ACCOUNT_NAME = 'Test Account for EventSelector';
    private static final Integer TEST_EVENTS_QUANTITY = 5;

    @TestSetup
    static void setup() {
        Account acc = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.Name, TEST_ACCOUNT_NAME)
            .quantity(1)
            .create()
            .getRecord();

        Map<SObjectField, Object> fieldMap = new Map<SObjectField, Object> {
            Event.WhatId => acc.Id,
            Event.DurationInMinutes => 1,
            Event.ActivityDateTime => Datetime.now()
        };
        new SObjectBuilder(Event.SObjectType)
            .quantity(TEST_EVENTS_QUANTITY)
            .setFields(fieldMap)
            .create();
    }

    @isTest
    static void testSelectEventsByWhatIds() {
        Id testAccId = new AccountSelector()
            .selectAccountByName(new List<Object>{TEST_ACCOUNT_NAME})
            .executeQuery()
            .get(0).Id;

        Test.startTest();
            List<Event> selectedEvents = new EventSelector()
                .selectEventsByWhatIds(new Set<Id> {testAccId})
                .executeQuery();
        Test.stopTest();

        System.assertEquals(
            TEST_EVENTS_QUANTITY,
            selectedEvents.size(),
            'Incorrect amount of Events were retrieved'
        );
    }

    @isTest
    static void testSelectEventsByWhatIdsNoEventReturned() {
        Id notExistingAccountId = (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue();

        Test.startTest();
            List<Event> selectedEvents = new EventSelector()
                .selectEventsByWhatIds(new Set<Id> {notExistingAccountId})
                .executeQuery();
        Test.stopTest();

        System.assertEquals(
            0,
            selectedEvents.size(),
            'Expected zero Events to be returned.'
        );
    }
}