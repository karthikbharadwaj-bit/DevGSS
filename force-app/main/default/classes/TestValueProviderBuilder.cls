@isTest
private class TestValueProviderBuilder {

    /**
    * Verify that value builder can provide unique number value starting from 0 by default.
    * Uniquie number can start with some predefined base value.
    */
    @isTest static void valueBuilderCanProvideUniqueNumber() {
        Object value = ValueProviderBuilder.provideUniqueNumber().getValue();
        System.assert(value instanceof Integer);
        System.assertEquals(value, 0);
        final Integer BASE_VALUE = 10;
        value = ValueProviderBuilder.provideUniqueNumber(BASE_VALUE).getValue();
        System.assertEquals(value, BASE_VALUE);
    }

    /**
    * Verify that value builder can provide unique decimal value starting from 0 by default.
    * Uniquie decimal can start with some predefined base value.
    * Also you can specify the scale.
    */
    @isTest static void valueBuilderCanProvideUniqueDecimal() {
        final Integer SCALE = 2;
        final Decimal BASE_VALUE = 10;
        Object value = ValueProviderBuilder.provideUniqueDecimal().getValue();
        System.assert(value instanceof Decimal);
        System.assertEquals(value, 0);
        value = ValueProviderBuilder.provideUniqueDecimal(SCALE).getValue();
        System.assertEquals(String.valueOf(value).length(), 4);
        value = ValueProviderBuilder.provideUniqueDecimal(BASE_VALUE, SCALE).getValue();
        System.assertEquals(value, BASE_VALUE);
    }

    /**
    * Verify that value builder can provide unique date value starting from todays date by default.
    * Uniquie date can start with some predefined base value.
    */
    @isTest static void valueBuilderCanProvideUniqueDate() {
        final Date BASE_VALUE = Date.today().addDays(1);
        Object value = ValueProviderBuilder.provideUniqueDate().getValue();
        System.assert(value instanceof Date);
        System.assertEquals(value, Date.today());
        value = ValueProviderBuilder.provideUniqueDate(BASE_VALUE).getValue();
        System.assertEquals(value, BASE_VALUE);
    }

    /**
    * Verify that value builder can provide unique datetime value starting from current datetime by default.
    * Uniquie datetime can start with some predefined base value.
    */
    @isTest static void valueBuilderCanProvideUniqueDatetime() {
        final Datetime BASE_VALUE = Datetime.now().addDays(1);
        Object value = ValueProviderBuilder.provideUniqueDatetime().getValue();
        System.assert(value instanceof Datetime);
        value = ValueProviderBuilder.provideUniqueDatetime(BASE_VALUE).getValue();
        System.assertEquals(value, BASE_VALUE);
    }

    /**
    * Verify that value builder can provide unique time value starting from current time based on a GMT calendar by default.
    * Uniquie time can start with some predefined base value.
    */
    @isTest static void valueBuilderCanProvideUniqueTime() {
        final Time BASE_VALUE = Datetime.now().timeGMT().addHours(1);
        Object value = ValueProviderBuilder.provideUniqueTime().getValue();
        System.assert(value instanceof Time);
        value = ValueProviderBuilder.provideUniqueTime(BASE_VALUE).getValue();
        System.assertEquals(value, BASE_VALUE);
    }

    /**
    * Verify that value builder can provide unique string '0' by default.
    * Uniquie string can start with some predefined base value.
    */
    @isTest static void valueBuilderCanProvideUniqueString() {
        final String PREFIX = 'Testing';
        Object value = ValueProviderBuilder.provideUniqueString().getValue();
        System.assert(value instanceof String);
        System.assertEquals(value, String.valueOf(0));
        value = ValueProviderBuilder.provideUniqueString(PREFIX).getValue();
        System.assert(((String) value).startsWith(PREFIX));
    }

    /**
    * Verify that value builder can provide unique blob with '0' body by default.
    * Uniquie blob body can start with some predefined base value.
    */
    @isTest static void valueBuilderCanProvideUniqueBlob() {
        final String PREFIX = 'Testing';
        Object value = ValueProviderBuilder.provideUniqueBlob().getValue();
        System.assert(value instanceof Blob);
        System.assertEquals(value, Blob.valueof(String.valueOf(0)));
        value = ValueProviderBuilder.provideUniqueBlob(PREFIX).getValue();
        System.assert((((Blob) value)).toString().startsWith(PREFIX));
    }

    /**
    * Verify that value builder can provide unique email with '0' base by default and '@mockDomain.com' by default.
    * Uniquie Email body can start with some predefined base and domain value.
    */
    @isTest static void valueBuilderCanProvideUniqueEmail() {
        final String PREFIX = 'Testing';
        final String DEFAULT_EMAIL_PART = 'rc_';
        Object value = ValueProviderBuilder.provideUniqueEmail().getValue();
        System.assert(value instanceof String);
        System.assertEquals(true, ((String) value).startsWith('rc_'));
        System.assertEquals(true, ((String) value).contains('@rcmockDomain.com'));
        value = ValueProviderBuilder.provideUniqueEmail(PREFIX + DEFAULT_EMAIL_PART).getValue();
        System.assert(((String) value).startsWith(PREFIX));
    }

    /**
    * Verify that value builder can provide unique string with predefined size.
    * By default body is '0' multiplied by size value.
    * Uniquie string body can start with some predefined base value.
    * Can throw the exeption if the base string is bigger that the size.
    */
    @isTest static void valueBuilderCanProvideUniqueFixedLengthString() {
        final String PREFIX = 'Testing';
        Object value = ValueProviderBuilder.provideUniqueFixedLengthString(1).getValue();
        System.assert(value instanceof String);
        System.assertEquals(value, String.valueOf(0));
        value = ValueProviderBuilder.provideUniqueFixedLengthString(PREFIX, 8).getValue();
        System.assertEquals(((String) value).length(), PREFIX.length() + 1);
        ValueProvider.CountException valueProviderCountException;
        try {
            value = ValueProviderBuilder.provideUniqueFixedLengthString(PREFIX, 1).getValue();
        } catch (ValueProvider.CountException ex) {
            valueProviderCountException = ex;
        }
        System.assert(!String.isEmpty(valueProviderCountException.getMessage()));
    }

    /**
    * Verify that value builder can provide dummy Id stub for the an Id.
    * Verify that it can return Ids of 15 and 18 character sizes.
    */
    @isTest static void valueBuilderCanProvideDummyIds() {
        SObjectType type = Contact.SObjectType;
        final Integer LENGTH = 15;
        Object value = ValueProviderBuilder.provideDummyId(type).getValue();
        System.assert(value instanceof String);
        System.assert(((String) value).startsWith(type.getDescribe().getKeyPrefix()));
        value = ValueProviderBuilder.provideDummyId(type, LENGTH).getValue();
        System.assertEquals(((String) value).length(), LENGTH);
    }

    /**
    * Verify that value builder can provide List to assign for the new records.
    * Verify that it can return Ids of 15 and 18 character sizes.
    */
    @isTest static void valueBuilderCanProvideList() {
        final List<Object> LAST_NAMES_OVERRIDE = new List<Object>{'cW6u8BPFM93BLA==', 'Y3y1+AvMOdzY', 'ZHG38RDMOdzY'};
        final Integer RECORDS_NUMBER = 3;
        SObjectField field = Contact.LastName;
        SObjectFactory factory = new SObjectFactory();
        List<SObject> records = factory.build(Contact.SObjectType, RECORDS_NUMBER,
                                               field, ValueProviderBuilder.provideList(LAST_NAMES_OVERRIDE));
        for(Integer i = 0; i < records.size(); i++) {
            SObject record = records[i];
            System.assertEquals(record.get(field), LAST_NAMES_OVERRIDE[i]);
        }
    }


    /**
    * Verify that value builder can provide generic parent Id provider based on the specified SObject.
    * Verify that parents ids are populated and they are different.
    */
    @isTest static void valueBuilderCanProvideParents() {
        final Integer RECORDS_NUMBER = 3;
        SObjectType type = Account.SObjectType;
        SObjectField field = Contact.AccountId;
        SObjectFactory factory = new SObjectFactory();
        Set<Object> parentIds = new Set<Object>();
        List<SObject> records = factory.build(Contact.SObjectType, RECORDS_NUMBER,
                                              field, ValueProviderBuilder.provideParents(type, RECORDS_NUMBER, true));
        for(SObject record : records) {
            parentIds.add(record.get(field));
        }
        System.assertEquals(parentIds.size(), RECORDS_NUMBER);

        parentIds.clear();
        records.clear();

        List<SObject> parents = factory.create(Account.SObjectType, RECORDS_NUMBER);
        records = factory.build(Contact.SObjectType, RECORDS_NUMBER,
                                field, ValueProviderBuilder.provideParents(parents));
        for(SObject record : records) {
            parentIds.add(record.get(field));
        }
        System.assertEquals(parentIds.size(), RECORDS_NUMBER);

        parentIds.clear();
        records.clear();

        records = factory.build(Contact.SObjectType, RECORDS_NUMBER,
                                field, ValueProviderBuilder.provideParents(new Map<Id, SObject>(parents).keySet()));
        for(SObject record : records) {
            parentIds.add(record.get(field));
        }
        System.assertEquals(parentIds.size(), RECORDS_NUMBER);
    }

    /**
    * Verify that value builder can provide generic parent Id provider based on the specified SObject.
    */
    @isTest static void valueBuilderCanProvideGenericParents() {
        SObjectType type = Account.SObjectType;
        SObjectField field = Contact.AccountId;
        SObjectFactory factory = new SObjectFactory();
        SObject record = factory.build(Contact.SObjectType, field,
                                       ValueProviderBuilder.provideGenericParent(Account.SObjectType));
        System.assertNotEquals(record.get(field), null);
    }

    /**
    * Verify that value builder can provide generic parent Id provider based on the specified SObject.
    */
    @isTest static void valueBuilderCanProvideGenericParentsAndPopulateParentField() {
        SObjectType type = Account.SObjectType;
        SObjectField field = Contact.AccountId;
        SObjectField parentField = Account.Name;
        final String ACCOUNT_NAME = 'Aquiva Labs Inc.';
        SObjectFactory factory = new SObjectFactory();
        SObject record = factory.create(Contact.SObjectType, field,
                                        ValueProviderBuilder.provideGenericParent(Account.SObjectType, parentField, ACCOUNT_NAME));
        System.assertNotEquals(record.get(field), null);
        System.assertEquals([SELECT Id, Account.Name
                             FROM Contact
                             WHERE Id = :record.Id].Account.Name, ACCOUNT_NAME);
    }

    /**
    * Verify that value builder can provide generic parent Id provider based on the specified SObject.
    */
    @isTest static void valueBuilderCanProvideGenericParentsAndPopulateParentFields() {
        SObjectType type = Account.SObjectType;
        SObjectField field = Contact.AccountId;
        SObjectField parentField = Account.Name;
        final String ACCOUNT_NAME = 'Aquiva Labs Inc.';
        SObjectFactory factory = new SObjectFactory();
        SObject record = factory.create(Contact.SObjectType, field,
                                        ValueProviderBuilder.provideGenericParent(Account.SObjectType,
                                        new Map<SObjectField, Object> { parentField => ACCOUNT_NAME }));
        System.assertNotEquals(record.get(field), null);
        System.assertEquals([SELECT Id, Account.Name
                             FROM Contact
                             WHERE Id = :record.Id].Account.Name, ACCOUNT_NAME);
    }

    /**
    * Verify that value builder can provide generic parent Id provider based on the specified SObject.
    */
    @isTest static void valueBuilderCanProvideCommonParents() {
        SObjectType type = Account.SObjectType;
        SObjectField field = Contact.AccountId;
        SObjectFactory factory = new SObjectFactory();
        SObject record = factory.build(Contact.SObjectType, field,
                                       ValueProviderBuilder.provideCommonParent(Account.SObjectType));
        System.assertNotEquals(record.get(field), null);
    }

    /**
    * Verify that value builder can provide generic parent Id provider based on the specified SObject.
    */
    @isTest static void valueBuilderCanProvideCommonParentsAndPopulateParentFields() {
        SObjectType type = Account.SObjectType;
        SObjectField field = Contact.AccountId;
        SObjectField parentField = Account.Name;
        final String ACCOUNT_NAME = 'Aquiva Labs Inc.';
        SObjectFactory factory = new SObjectFactory();
        SObject record = factory.create(Contact.SObjectType, field,
                                        ValueProviderBuilder.provideCommonParent(Account.SObjectType,
                                        new Map<SObjectField, Object> { parentField => ACCOUNT_NAME }));
        System.assertNotEquals(record.get(field), null);
        System.assertEquals([SELECT Id, Account.Name
                             FROM Contact
                             WHERE Id = :record.Id].Account.Name, ACCOUNT_NAME);
    }

    /**
    * Verify that value builder can provide generic parent Id provider based on the specified query or just an SObjectType.
    * Verify that it cant throw the EmptyQueryException if the query is empty
    */
    @isTest static void valueBuilderCanProvideQueriedParent() {
        SObjectType type = Account.SObjectType;
        SObjectField field = Contact.AccountId;
        SObjectFactory factory = new SObjectFactory();
        SObject parent = factory.create(type);
        final String PARENT_QUERY = 'SELECT Id FROM ' + String.escapeSingleQuotes(String.valueOf(type)) + ' LIMIT 1';
        SObject record = factory.build(Contact.SObjectType, field,
                                       ValueProviderBuilder.provideQueriedParent(PARENT_QUERY));
        System.assertNotEquals(record.get(field), null);
        record = factory.build(Contact.SObjectType, field,
                                       ValueProviderBuilder.provideQueriedParent(type));
        System.assertNotEquals(record.get(field), null);
        ValueProvider.EmptyQueryException valueProviderEmptyQueryException;
        try {
            Object value = ValueProviderBuilder.provideQueriedParent(Contact.SObjectType).getValue();
        } catch (ValueProvider.EmptyQueryException ex) {
            valueProviderEmptyQueryException = ex;
        }
        System.assert(!String.isEmpty(valueProviderEmptyQueryException.getMessage()));
    }

}