@isTest
private class Test_QueryFactory {
    private static final String EXPR0 = 'expr0';
    private static final String EXPR1 = 'expr1';
    private static final String EXPR2 = 'expr2';
    private static final String EXPR3 = 'expr3';
    private static final String EXCEPTION_THROWN = 'An exception should be thrown';

    class TestContactSelector extends SObjectSelector {
        public TestContactSelector() {
            super();
        }
    
        public TestContactSelector(Boolean enforceCRUD, Boolean enforceFLS) {
            super(enforceCRUD, enforceFLS);
        }
        public override Schema.SObjectType getSObjectType() {
            return Contact.SObjectType;
        }

        public override List<Schema.SObjectField> getDefaultFieldList() {
            return new List<Schema.SObjectField> {
                Contact.Id
            };
        }
    }

    class TestAccountSelector extends SObjectSelector {
        public override Schema.SObjectType getSObjectType() {
            return Account.SObjectType;
        }

        public override List<Schema.SObjectField> getDefaultFieldList() {
            return new List<Schema.SObjectField> {
                Account.Id
            };
        }
    }

    @isTest
    static void verifyQueryFactorySelectFields() {
        SObjectSelector selector = new TestContactSelector();
        QueryFactory factory = new QueryFactory(selector)
            .selectField('FirstName')
            .selectField(Contact.LastName)
            .selectFields(new Set<String>{'AccountId', 'Account.name'})
            .selectFields(new List<String>{'Department', 'Description'})
            .selectFields(new Set<SObjectField>{Contact.Phone, Contact.Fax})
            .selectFields(new List<SObjectField>{Contact.Email, Contact.Title});
        System.assertEquals(
            new Set<String>{
                'FirstName',
                'LastName',
                'AccountId',
                'Account.Name',
                'Department',
                'Description',
                'Phone',
                'Fax',
                'Email',
                'Title'
            },
            factory.getSelectedFields(),
            'Expected to select another set of fields'
        );
    }

    @isTest
    static void verifyQueryFactoryFieldsSelection() {
        SObjectSelector selector = new TestContactSelector();
        QueryFactory factory = new QueryFactory(selector).selectFields(new Set<String>{'Name', 'Email'}).setQuery();
        String query = factory.getQuery();
        System.assert(Pattern.matches('SELECT.*Name.*FROM.*', query), 'Expected Name field in query, got ' + query);
        System.assert(Pattern.matches('SELECT.*Email.*FROM.*', query), 'Expected Email field in query, got ' + query);
    }

    @isTest
    static void verifyQueryFactoryApplyingName() {
        SObjectSelector selector = new TestContactSelector();
        QueryFactory factory = new QueryFactory(selector).setFactoryName('Test');
        System.assertEquals('Test', factory.getFactoryName(), 'Incorrect factory name assigned');
    }

    @isTest
    static void verifyQueryFactoryApplyingSecurity() {
        SObjectSelector selector = new TestContactSelector();
        QueryFactory factory = new QueryFactory(selector);
        /* Security disabled by default and enherited from the selecor class */
        System.assert(!factory.enforceFLS, 'Expected fields security to be disabled');
        System.assert(!factory.assertCRUD, 'Expected object security to be disabled');
        /* Enable factory security */
        factory.withFLSEnforcement();
        factory.withCRUDAssertion();
        System.assert(factory.enforceFLS, 'Expected fields security to be enabled');
        System.assert(factory.assertCRUD, 'Expected object security to be enabled');

        /* Security is enherited from the selector */
        SObjectSelector secureSelector = new TestContactSelector(true, true);
        QueryFactory secureFactory = new QueryFactory(secureSelector);
        System.assert(secureFactory.enforceFLS, 'Expected fields security to be enabled');
        System.assert(secureFactory.assertCRUD, 'Expected object security to be enabled');
    }

    @isTest
    static void verifyQueryFactoryApplyingLimits() {
        final Integer QUERY_RECORDS_LIMIT = 100;
        SObjectSelector selector = new TestContactSelector();
        QueryFactory factory = new QueryFactory(selector).setLimit(QUERY_RECORDS_LIMIT).setQuery();
        System.assertEquals(QUERY_RECORDS_LIMIT, factory.getLimit(),
                            'Expected the query records limits ' + QUERY_RECORDS_LIMIT + ' got ' + factory.getLimit());
        System.assert(
            factory.getQuery().endsWithIgnoreCase('LIMIT ' + factory.getLimit()),
            'Failed to respect limit clause:' + factory.getQuery()
        );
    }

    @isTest
    static void verifyQueryFactoryApplyingOffset() {
        final Integer QUERY_OFFSET = 1;
        SObjectSelector selector = new TestContactSelector();
        QueryFactory factory = new QueryFactory(selector).setOffset(QUERY_OFFSET).setQuery();
        System.assertEquals(QUERY_OFFSET, factory.getOffset(),
                            'Expected the query offset ' + QUERY_OFFSET + ' got ' + factory.getOffset());
        System.assert(
            factory.getQuery().endsWithIgnoreCase('OFFSET ' + factory.getOffset()),
            'Failed to respect offset clause:' + factory.getQuery()
        );
    }

    @isTest
    static void verifyQueryFactoryApplyingSimpleCondition() {
        final String WHERE_CLAUSE = 'Name = \'test\'';
        SObjectSelector selector = new TestContactSelector();
        QueryFactory factory = new QueryFactory(selector)
            .withoutSelectorOrderByIncluded()
            .selectField('Name')
            .setCondition(WHERE_CLAUSE)
            .setQuery();
        System.assertEquals(WHERE_CLAUSE, factory.getCondition(),
                            'Expected the query condition ' + WHERE_CLAUSE + ' got ' + factory.getCondition());
        String query = factory.getQuery();
        System.assert(
            query.endsWith('WHERE Name = \'test\''),
            'Query should have ended with a filter on Name, got: ' + query
        );
    }

    @isTest
    static void verifyQueryFactoryDuplicateFieldSelection() {
        SObjectSelector selector = new TestContactSelector();
        QueryFactory factory = new QueryFactory(selector)
            .withoutSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .selectField(Contact.Name)
            .selectFields(new Set<String>{'Name', 'Email'})
            .setQuery();
        String query = factory.getQuery();
        System.assertEquals(1, query.countMatches('Name'), 'Expected one name field in query: ' + query);
    }

    @isTest
    static void verifyQueryFactoryEquality() {
        SObjectSelector selector = new TestContactSelector();
        /* Compare empty factories, they should equal */

        QueryFactory factory = new QueryFactory(selector)
                                .withoutSelectorFieldsIncluded()
                                .selectFields(new Set<String>{'Name', 'Email'});
        QueryFactory anotherFactory = factory.deepClone();
        System.assert(factory.equals(anotherFactory), 'Expected factories to be equal');

        /* Add 2 more fields to the first factory, so they become different */
        factory.selectFields(new Set<String>{'FirstName', 'LastName'});
        System.assert(
            !factory.equals(anotherFactory),
            'Expected factories to be different, as first factory has 2 more fields'
        );

        /* Add 2 more fields to the second factory, different fields sequence, so they should become equal */
        anotherFactory.selectFields(new Set<SObjectField>{Contact.FirstName, Contact.LastName});
        System.assert(
            factory.equals(anotherFactory),
            'Expected factories to be equal, as fields selected are the same'
        );

        /* Set different conditions on factories, expect them to be different */
        factory.setCondition('Name = \'test\'').setQuery();
        anotherFactory.setCondition('Name = \'anotherTest\'').setQuery();
        System.assert(
            !factory.equals(anotherFactory),
            'Expected factories to be different as they have different conditions'
        );
    }

    @isTest
    static void verifyQueryFactoryThrowsReferenceFieldException() {
        SObjectSelector selector = new TestContactSelector();
        QueryFactory factory = new QueryFactory(selector);
        QueryFactory.NonReferenceFieldException e;
        try {
            factory.selectField('Name.Title');
        } catch (QueryFactory.NonReferenceFieldException ex) {
            e = ex;
        }
        System.assertNotEquals(
            null,
            e,
            'Cross-object notation on a non-reference field should throw NonReferenceFieldException'
        );
    }

    @isTest
    static void verifyQueryFactoryThrowsInvalidFieldException() {
        List<QueryFactory.InvalidFieldException> exceptions = new List<QueryFactory.InvalidFieldException>();
        SObjectSelector selector = new TestContactSelector();
        QueryFactory factory = new QueryFactory(selector);
        try {
            SObjectField nullField;
            factory.selectField(nullField);
        } catch (QueryFactory.InvalidFieldException e) {
            exceptions.add(e);
        }
        try {
            factory.selectField('Not_a_field');
        } catch (QueryFactory.InvalidFieldException e) {
            exceptions.add(e);
        }
        try {
            factory.selectFields(new Set<String>{'Not_a_field', 'alsoNotreal'});
        } catch (QueryFactory.InvalidFieldException e) {
            exceptions.add(e);
        }
        try {
            factory.selectFields(new Set<SObjectField>{null});
        } catch (QueryFactory.InvalidFieldException e) {
            exceptions.add(e);
        }
        try {
            factory.selectFields(new List<SObjectField>{null, Contact.title});
        } catch (QueryFactory.InvalidFieldException e) {
            exceptions.add(e);
        }
        System.assertEquals(
            5,
            exceptions.size(),
            'Invalid cross-object field reference should throw InvalidFieldException 4 times'
        );
    }

    @isTest
    static void verifyQueryFactoryAddsOrdering() {
        SObjectSelector selector = new TestContactSelector();
        QueryFactory factory = new QueryFactory(selector)
            .withoutSelectorOrderByIncluded()
            .selectFields(new Set<String>{'Name', 'Email'})
            .setCondition('Name = \'test\'')
            .addOrdering('Name', QueryFactory.SortOrder.ASCENDING)
            .addOrdering(Contact.CreatedDate, QueryFactory.SortOrder.DESCENDING)
            .setQuery();
        String query = factory.getQuery();

        System.assertEquals(2, factory.getOrderings().size(), 'Expected other ordering fields size');
        System.assertEquals('Name', factory.getOrderings()[0].getField(), 'Expected Name as the ordering field');
        System.assertEquals(QueryFactory.SortOrder.ASCENDING, factory.getOrderings()[0].getOrder(),
                            'Expected another ordering direction for Name field');
        System.assertEquals('CreatedDate', factory.getOrderings()[1].getField(), 'Expected CreatedDate as the ordering field');
        System.assertEquals(QueryFactory.SortOrder.DESCENDING, factory.getOrderings()[1].getOrder(),
                            'Expected another ordering direction for CreatedDate field');
    }

    @isTest
    static void verifyQueryFactoryReplacesPreviousOrderingsWithExpectedOrdering() {
        SObjectSelector selector = new TestContactSelector();
        QueryFactory factory = new QueryFactory(selector)
            .withoutSelectorOrderByIncluded()
            .selectFields(new Set<String>{'Name', 'Email'})
            .setCondition('Name = \'test\'');

        //test base method with ordeting by OwnerId Descending
        factory.addOrdering(new QueryFactory.Ordering('Contact', 'OwnerId', QueryFactory.SortOrder.DESCENDING));

        System.assertEquals(
            1,
            factory.getOrderings().size(),
            'Unexpected order size - setOrder should replace default Orderings'
        );
        System.assertEquals(
            Contact.OwnerId.getDescribe().getName(),
            factory.getOrderings()[0].getField(),
            'Unexpected order field - should have been resolved from the field OwnerId'
        );
        System.assertEquals(
            QueryFactory.SortOrder.DESCENDING,
            factory.getOrderings()[0].getOrder(),
            'Unexpected order direction.'
        );

        //test method overload with ordering by LastModifiedDate Ascending
        factory.addOrdering('LastModifiedDate', QueryFactory.SortOrder.ASCENDING, true);

        System.assertEquals(
            2,
            factory.getOrderings().size(),
            'Unexpected order size - setOrder should replace previous Orderings'
        );
        System.assertEquals(
            Contact.LastModifiedDate.getDescribe().getName(),
            factory.getOrderings()[1].getField(),
            'Unexpected order field - should have been resolved from the field LastModifiedDate'
        );
        System.assertEquals(
            QueryFactory.SortOrder.ASCENDING,
            factory.getOrderings()[1].getOrder(),
            'Unexpected order direction.'
        );

        //test method overload with ordering by CreatedDate Descending
        factory.addOrdering(Contact.CreatedDate, QueryFactory.SortOrder.DESCENDING, true);

        System.assertEquals(
            3,
            factory.getOrderings().size(),
            'Unexpected order size - setOrder should replace previous Orderings'
        );
        System.assertEquals(
            Contact.CreatedDate.getDescribe().getName(),
            factory.getOrderings()[2].getField(),
            'Unexpected order field - should have been resolved from the field CreatedDate'
        );
        System.assertEquals(
            QueryFactory.SortOrder.DESCENDING,
            factory.getOrderings()[2].getOrder(),
            'Unexpected order direction.'
        );

        //test method overload with ordering by CreatedBy.Name Descending
        factory.addOrdering('CreatedBy.Name', QueryFactory.SortOrder.DESCENDING);

        System.assertEquals(
            4,
            factory.getOrderings().size(),
            'Unexpected order size - setOrder should replace previous Orderings'
        );
        System.assertEquals(
            QueryFactory.SortOrder.DESCENDING,
            factory.getOrderings()[3].getOrder(),
            'Unexpected order direction.'
        );

        //test method overload with ordering by Birthdate Ascending
        factory.addOrdering(Contact.Birthdate, QueryFactory.SortOrder.ASCENDING, true);

        System.assertEquals(
            5,
            factory.getOrderings().size(),
            'Unexpected order size - setOrder should replace previous Orderings'
        );
        System.assertEquals(
            Contact.Birthdate.getDescribe().getName(),
            factory.getOrderings()[4].getField(),
            'Unexpected order field - should have been resolved from the field Birthdate'
        );
        System.assertEquals(
            QueryFactory.SortOrder.ASCENDING,
            factory.getOrderings()[4].getOrder(),
            'Unexpected order direction.'
        );
    }

    @isTest
    static void verifyQueryFactoryReturnsRecordsAsList() {
        final Integer RECORDS_NUMBER = 5;
        final Map<SObjectField, Object> fields = new Map<SObjectField, Object>{
            Contact.FirstName => 'Aquiva',
            Contact.LastName => 'Tester',
            Contact.Email => 'tester@aquiva.com'
        };
        SObjectBuilder builder = new SObjectBuilder(Contact.SObjectType)
            .setFields(fields)
            .quantity(RECORDS_NUMBER)
            .create();

        SObjectSelector selector = new TestContactSelector();
        QueryFactory factory = new QueryFactory(selector)
            .withoutSelectorOrderByIncluded()
            .selectFields(new Set<String>{'FirstName', 'LastName', 'Email'});

        List<SObject> contacts = factory.executeQuery();
        System.assertEquals(contacts.size(), RECORDS_NUMBER, 'Unexpected number of records returned');
        System.assert(contacts instanceof List<Contact>, 'Unexpected type of records is returned');
        for (SObject c : contacts) {
            System.assertEquals(c.get(Contact.FirstName), 'Aquiva', 'Unexpected first name field value is returned');
            System.assertEquals(c.get(Contact.LastName), 'Tester', 'Unexpected last name field value is returned');
            System.assertEquals(c.get(Contact.Email), 'tester@aquiva.com', 'Unexpected email field value is returned');
        }
    }

    @isTest
    static void verifyQueryFactoryReturnsRecordsRelatedParentFields() {
        final Integer RECORDS_NUMBER = 5;
        final Map<SObjectField, Object> fields = new Map<SObjectField, Object>{
            Contact.FirstName => 'Aquiva',
            Contact.LastName => 'Tester',
            Contact.Email => 'tester@aquiva.com'
        };
        SObjectBuilder builder = new SObjectBuilder(Contact.SObjectType)
            .setFields(fields)
            .quantity(RECORDS_NUMBER)
            .create();

        SObjectSelector selector = new TestContactSelector();
        QueryFactory factory = new QueryFactory(selector)
            .withoutSelectorOrderByIncluded()
            .selectRelatedFields(new TestAccountSelector(), 'Account');

        List<Contact> contacts = factory.executeQuery();
        System.assertEquals(contacts.size(), RECORDS_NUMBER, 'Unexpected number of records returned');
        /* Account fields were added with the @selectRelatedFields no exception occured */
        for (Contact c : contacts) {
            System.assertEquals(c.Account.Id, null, 'Expected account fields to be selected');
        }
    }

    @isTest
    static void verifyQueryFactorySelectsUsingDynamicBinding() {
        final Integer RECORDS_NUMBER = 5;
        final String contactFirstName = 'Aquiva';
        final String contactLastName = 'Tester';
        final String contactEmail = 'tester@aquiva.com';
        final String contactDepartment = 'Developer';
        final Date contactBirthaday = Date.newInstance(1989, 8, 16);
        final String assertMessage = 'Unexpected {0} field value is returned';
        final String queryCondition = 'FirstName = :bind0 AND LastName = :bind1 AND Email = :bind2 AND Department = :bind3 AND Birthdate = :bind4';
        List<Object> bindings = new List<Object>{
            contactFirstName,
            contactLastName,
            contactEmail,
            contactDepartment,
            contactBirthaday
        };
        final Map<SObjectField, Object> fields = new Map<SObjectField, Object>{
            Contact.FirstName => contactFirstName,
            Contact.LastName => contactLastName,
            Contact.Email => contactEmail,
            Contact.Department => contactDepartment,
            Contact.Birthdate => contactBirthaday
        };
        SObjectBuilder builder = new SObjectBuilder(Contact.SObjectType)
            .setFields(fields)
            .quantity(RECORDS_NUMBER)
            .create();

        SObjectSelector selector = new TestContactSelector();
        QueryFactory factory = new QueryFactory(selector)
            .withoutSelectorOrderByIncluded()
            .selectFields(new Set<String>{'FirstName', 'LastName', 'Email', 'Department', 'Birthdate'})
            .setCondition(queryCondition)
            .setQueryBindings(bindings);

        List<SObject> contacts = factory.executeQuery();
        System.assertEquals(contacts.size(), RECORDS_NUMBER, 'Unexpected number of records returned');
        System.assert(contacts instanceof List<Contact>, 'Unexpected type of records is returned');
        for (SObject c : contacts) {
            System.assertEquals(
                c.get(Contact.FirstName),
                contactFirstName,
                String.format(assertMessage, new List<Object>{'first name'})
            );
            System.assertEquals(
                c.get(Contact.LastName),
                contactLastName,
                String.format(assertMessage, new List<Object>{'last name'})
            );
            System.assertEquals(
                c.get(Contact.Email),
                contactEmail,
                String.format(assertMessage, new List<Object>{'email'})
            );
            System.assertEquals(
                c.get(Contact.Department),
                contactDepartment,
                String.format(assertMessage, new List<Object>{'department'})
            );
            System.assertEquals(
                c.get(Contact.Birthdate),
                contactBirthaday,
                String.format(assertMessage, new List<Object>{'birthdate'})
            );
        }
    }

    @isTest
    static void verifyQueryFactorySetSingleQueryBinding() {
        final String queryBinding0 = '123';
        final Integer queryBinding1 = 345;
        final Decimal queryBinding2 = 567.88;
        final Date queryBinding3 = Date.newInstance(2018, 1, 1);
        final DateTime queryBinding4 = DateTime.newInstance(2018, 1, 1, 1, 1, 1);
        final String queryBinding5 = '456';
        final List<Object> queryBindings = new List<Object>{
            queryBinding0,
            queryBinding1,
            queryBinding2,
            queryBinding3,
            queryBinding4,
            queryBinding5
        };
        SObjectSelector selector = new TestContactSelector();
        QueryFactory factory = new QueryFactory(selector);
        System.assertEquals(factory.bindings.size(), 0, 'Bindings must be empty before testing');

        factory.setQueryBindings(queryBinding0);
        System.assertEquals(factory.bindings.get(0), queryBinding0, 'First binding is not set');
    }

    @isTest
    static void verifyQueryFactorySetQueryBindingThrowsError() {
        final String queryBinding0 = '123';
        final Integer queryBinding1 = 345;
        final Decimal queryBinding2 = 567.88;
        final Date queryBinding3 = Date.newInstance(2018, 1, 1);
        final DateTime queryBinding4 = DateTime.newInstance(2018, 1, 1, 1, 1, 1);
        final String queryBinding5 = '456';
        final List<Object> queryBindings = new List<Object>{
            queryBinding0,
            queryBinding1,
            queryBinding2,
            queryBinding3,
            queryBinding4,
            queryBinding5
        };
        SObjectSelector selector = new TestContactSelector();
        QueryFactory factory = new QueryFactory(selector);
        System.assertEquals(factory.bindings.size(), 0, 'Bindings must be empty before testing');

        try {
            factory.setQueryBindings(queryBindings);
            System.assert(false, 'Exception was not thrown on adding a new query binding when more than expected number of bindings passed');
        } catch (QueryFactory.InvalidBindingException e) {
            System.assertEquals(e.getMessage(), 'No more than 5 bindings is allowed. You passed 6 bindings: (123, 345, 567.88, 2018-01-01 00:00:00, 2018-01-01 09:01:01, 456)');
        }

        try {
            // null List object is required to bypass compiler validation. You cannot directly pass null to method.
            List<Object> nullObjList;
            factory.setQueryBindings(nullObjList);
            System.assert(false, 'Exception was not thrown on adding a new query binding when unexpected parameter null provided');
        } catch (QueryFactory.InvalidBindingException e) {
            System.assertEquals(e.getMessage(), 'Bindings parameter should not be null');
        }
    }

    @isTest
    static void verifyQueryFactoryReturnsRecordsAsQueryLocator() {
        final Integer RECORDS_NUMBER = 5;
        final Map<SObjectField, Object> fields = new Map<SObjectField, Object>{
            Contact.FirstName => 'Aquiva',
            Contact.LastName => 'Tester',
            Contact.Email => 'tester@aquiva.com'
        };
        SObjectBuilder builder = new SObjectBuilder(Contact.SObjectType)
            .setFields(fields)
            .quantity(RECORDS_NUMBER)
            .create();

        SObjectSelector selector = new TestContactSelector();
        QueryFactory factory = new QueryFactory(selector)
            .withoutSelectorOrderByIncluded()
            .selectFields(new Set<String>{'FirstName', 'LastName', 'Email'});

        Database.QueryLocator locator = factory.executeQueryLocator();
        System.assert(locator.getQuery() == factory.getQuery(), 'Unexpected query was executed');

        Database.QueryLocatorIterator iterator = locator.iterator();
        while (iterator.hasNext()) {
            Contact c = (Contact) iterator.next();
            System.assertEquals(c.get(Contact.FirstName), 'Aquiva', 'Unexpected first name field value is returned');
            System.assertEquals(c.get(Contact.LastName), 'Tester', 'Unexpected last name field value is returned');
            System.assertEquals(c.get(Contact.Email), 'tester@aquiva.com', 'Unexpected email field value is returned');
        }
    }

    @isTest
    static void verifyQueryFactoryReturnRecordWithChildRecords() {
        final Integer ACCOUNT_RECORDS_NUMBER = 1;
        SObject account = new SObjectBuilder(Account.SObjectType).quantity(ACCOUNT_RECORDS_NUMBER).create().getRecord();

        final Integer CONTACT_RECORDS_NUMBER = 5;
        final Map<SObjectField, Object> fields = new Map<SObjectField, Object>{
            Contact.FirstName => 'Aquiva',
            Contact.LastName => 'Tester',
            Contact.Email => 'tester@aquiva.com',
            Contact.AccountId => account.Id
        };
        SObjectBuilder builder = new SObjectBuilder(Contact.SObjectType)
            .setFields(fields)
            .quantity(CONTACT_RECORDS_NUMBER)
            .create();

        SObjectSelector accSelector = new TestAccountSelector();
        SObjectSelector conSelector = new TestContactSelector();
        QueryFactory factory = new QueryFactory(accSelector)
            .withoutSelectorOrderByIncluded()
            .subselect(
                new QueryFactory(conSelector)
                    .selectFields(new Set<String>{'FirstName', 'LastName', 'Email', 'AccountId'})
            );

        System.assertEquals(factory.getSubselectQueries().size(), 1, 'Expected only one subselect query');
        List<Account> accounts = factory.executeQuery();
        System.assertEquals(accounts.size(), ACCOUNT_RECORDS_NUMBER, 'Unexpected number of records returned');

        List<Contact> contacts = accounts[0].contacts;
        for (SObject c : contacts) {
            System.assertEquals(c.get(Contact.FirstName), 'Aquiva', 'Unexpected first name field value is returned');
            System.assertEquals(c.get(Contact.LastName), 'Tester', 'Unexpected last name field value is returned');
            System.assertEquals(c.get(Contact.Email), 'tester@aquiva.com', 'Unexpected email field value is returned');
            System.assertEquals(c.get(Contact.AccountId), account.Id, 'Unexpected Account Id field value is returned');
        }
    }

    @isTest
    static void verifyQueryFactoryReturnRecordWithDuplicateChildRecordsNotOverrided() {
        final Integer ACCOUNT_RECORDS_NUMBER = 1;
        SObject account = new SObjectBuilder(Account.SObjectType).quantity(ACCOUNT_RECORDS_NUMBER).create().getRecord();

        final Integer CONTACT_RECORDS_NUMBER = 5;
        final Map<SObjectField, Object> fields = new Map<SObjectField, Object>{
            Contact.FirstName => 'Aquiva',
            Contact.LastName => 'Tester',
            Contact.Email => 'tester@aquiva.com',
            Contact.AccountId => account.Id
        };
        SObjectBuilder builder = new SObjectBuilder(Contact.SObjectType)
            .setFields(fields)
            .quantity(CONTACT_RECORDS_NUMBER)
            .create();

        SObjectSelector accSelector = new TestAccountSelector();
        SObjectSelector conSelector = new TestContactSelector();
        /* Subselect on the same object will not be executed second time */
        QueryFactory factory = new QueryFactory(accSelector)
            .withoutSelectorOrderByIncluded()
            .subselect(
                new QueryFactory(conSelector)
                    .selectFields(new Set<String>{'FirstName', 'LastName', 'Email', 'AccountId'})
            )
            .subselect(new QueryFactory(conSelector).selectFields(new Set<String>{'FirstName'}));

        List<Account> accounts = factory.executeQuery();
        System.assertEquals(accounts.size(), ACCOUNT_RECORDS_NUMBER, 'Unexpected number of records returned');
        List<Contact> contacts = accounts[0].contacts;
        for (SObject c : contacts) {
            System.assertEquals(c.get(Contact.FirstName), 'Aquiva', 'Unexpected first name field value is returned');
            System.assertEquals(c.get(Contact.LastName), 'Tester', 'Unexpected last name field value is returned');
            System.assertEquals(c.get(Contact.Email), 'tester@aquiva.com', 'Unexpected email field value is returned');
            System.assertEquals(c.get(Contact.AccountId), account.Id, 'Unexpected Account Id field value is returned');
        }
    }

    @isTest
    static void verifyQueryFactoryCanCloneFactory() {
        final String cloneMessage = 'Cloned factory {0} should be the same as the original one';
        String whereClause = 'Name = \'test\'';
        SObjectSelector selector = new TestContactSelector();
        QueryFactory factory = new QueryFactory(selector)
            .withoutSelectorOrderByIncluded()
            .setCondition(whereClause)
            .selectField(Contact.Name)
            .addOrdering('Name', QueryFactory.SortOrder.ASCENDING)
            .setLimit(100)
            .setQuery();

        QueryFactory clonedFactory = factory.deepClone();

        System.assert(factory.equals(clonedFactory), 'Cloned factory should be the same as the original one');

        System.assertEquals(
            factory.getLimit(),
            clonedFactory.getLimit(),
            String.format(cloneMessage, new List<Object>{'limit'})
        );
        System.assertEquals(
            factory.getCondition(),
            clonedFactory.getCondition(),
            String.format(cloneMessage, new List<Object>{'condition'})
        );
        System.assertEquals(
            factory.getQuery(),
            clonedFactory.getQuery(),
            String.format(cloneMessage, new List<Object>{'query'})
        );
        System.assertEquals(
            factory.getOrderings(),
            clonedFactory.getOrderings(),
            String.format(cloneMessage, new List<Object>{'orderings'})
        );
    }

    @isTest
    static void verifyQueryFactoryPerformCachingWhenQueryAreEquals() {
        SObjectSelector selector = new TestContactSelector();
        QueryFactory factory = new QueryFactory(selector)
            .setFactoryName('Test')
            .withoutSelectorOrderByIncluded()
            .selectField(Contact.Name)
            .setQueryCaching(true)
            .setQuery();
        System.assert(factory.getQueryCaching(), 'Expected query caching enabled');
        System.assertEquals(Limits.getQueries(), 0, 'Expected no query has to be executed');
        factory.executeQuery();
        System.assertEquals(Limits.getQueries(), 1, ' Expected query has to be executed once');
        factory.executeQuery();
        System.assertEquals(
            Limits.getQueries(),
            1,
            'Expected query results are in cache and has to be executed only once'
        );
    }

    @isTest
    static void verifyMultipleQueryFactoriesPerformCachingWithSelectorOrder() {
        SObjectSelector selector = new TestContactSelector();
        QueryFactory factory = new QueryFactory(selector)
            .setFactoryName('Test')
            .selectField(Contact.Name)
            .setQueryCaching(true)
            .setQuery();
        QueryFactory anotherFactory = new QueryFactory(selector)
            .setFactoryName('Test')
            .selectField(Contact.Name)
            .setQueryCaching(true)
            .setQuery();
        QueryFactory yetAnotherFactory = new QueryFactory(selector)
            .setFactoryName('Test')
            .selectField(Contact.Name)
            .setQueryCaching(true)
            .setQuery();

        System.assert(factory.getQueryCaching(), 'Expected query caching enabled');
        System.assertEquals(Limits.getQueries(), 0, 'Expected no query has to be executed');
        factory.executeQuery();
        System.assertEquals(Limits.getQueries(), 1, ' Expected query has to be executed once');
        anotherFactory.executeQuery();
        yetAnotherFactory.executeQuery();
        System.assertEquals(
            Limits.getQueries(),
            1,
            'Expected query results are in cache and has to be executed only once'
        );
    }

    @isTest
    static void verifyQueryFactoryNotPerformCachingWhenDisabled() {
        SObjectSelector selector = new TestContactSelector();
        QueryFactory factory = new QueryFactory(selector)
            .setFactoryName('Test')
            .withoutSelectorOrderByIncluded()
            .selectField(Contact.Name)
            .setQuery();
        System.assert(!factory.getQueryCaching(), 'Expected query caching disabled by default');
        System.assertEquals(Limits.getQueries(), 0, 'Expected query is not executed yet');
        factory.executeQuery();
        System.assertEquals(Limits.getQueries(), 1, 'Expected query has to be executed once');
        factory.executeQuery();
        System.assertEquals(Limits.getQueries(), 2, 'Expected query has to be executed twice as caching is disabled');
    }

    @isTest
    static void verifyQueryFactoryNotPerformCachingWhenQueryHasChanged() {
        SObjectSelector selector = new TestContactSelector();
        QueryFactory factory = new QueryFactory(selector)
            .setFactoryName('Test')
            .withoutSelectorOrderByIncluded()
            .selectField(Contact.Name)
            .setQueryCaching(false)
            .setQuery();
        System.assertEquals(Limits.getQueries(), 0, 'Expected query is not executed yet');
        factory.executeQuery();
        System.assertEquals(Limits.getQueries(), 1, 'Expected query has to be executed once');
        factory.selectField(Contact.Email);
        factory.executeQuery();
        System.assertEquals(
            Limits.getQueries(),
            2,
            'Expected query has to be executed twice as query factory was changed'
        );
    }

    @isTest
    static void testExecuteCountQuery() {
        final Integer RECORDS_NUMBER = 5;
        final Map<SObjectField, Object> fields = new Map<SObjectField, Object> {
            Contact.FirstName => 'Aquiva',
            Contact.LastName => 'Tester',
            Contact.Email => 'tester@aquiva.com'
        };

        new SObjectBuilder(Contact.SObjectType)
            .setFields(fields)
            .quantity(RECORDS_NUMBER)
            .create();

        SObjectSelector selector = new TestContactSelector();
        QueryFactory factory = new QueryFactory(selector)
            .setFactoryName('selectContactsAmount')
            .setCountAggregateFunction();

        Integer count = factory.executeCountQuery();
        Assert.isTrue(factory.isAggregateFunction, 'Aggregate function should be executed');
        Assert.areEqual(count, RECORDS_NUMBER, 'Unexpected number of records returned');
    }

    @isTest
    static void testExecuteCountQueryWithCaching() {
        SObjectSelector selector = new TestContactSelector();
        QueryFactory factory = new QueryFactory(selector)
            .setFactoryName('selectContactsAmount')
            .setCountAggregateFunction()
            .setQueryCaching(true)
            .setQuery();

        QueryFactory anotherFactory = new QueryFactory(selector)
            .setFactoryName('selectContactsAmount')
            .setCountAggregateFunction()
            .setQueryCaching(true)
            .setQuery();

        Assert.isTrue(factory.getQueryCaching(), 'Expected query caching enabled');
        Assert.areEqual(Limits.getQueries(), 0, 'Expected no query has to be executed');
        factory.executeCountQuery();
        Assert.areEqual(Limits.getQueries(), 1, 'Expected query has to be executed once');
        anotherFactory.executeCountQuery();
        Assert.areEqual(Limits.getQueries(), 1, 'Expected query results are in cache and has to be executed only once');
    }

    @isTest
    static void testSetGroupBySObjectFieldAttribute() {
        SObjectSelector selector = new TestContactSelector();
        QueryFactory factory = new QueryFactory(selector)
            .setFactoryName('selectContactsAmount')
            .setAggregateFunction(QueryFactory.AggregateFunction.COUNT, Contact.Id)
            .setGroupBy(Contact.FirstName);

        Assert.isTrue(factory.fields.size() > 0, 'Fields for further grouping should be set');
        Assert.isTrue(factory.groupByFields.size() > 0, 'The grouped field should be set');
        Assert.isTrue(factory.isAggregateFunction, 'Aggregate function should be executed');
    }

    @isTest
    static void testSetGroupBySObjectFieldAttributeWithError() {
        SObjectSelector selector = new TestContactSelector();
        QueryFactory factory = new QueryFactory(selector)
            .setFactoryName('selectContactsAmount')
            .setAggregateFunction(QueryFactory.AggregateFunction.COUNT, Contact.Id);
        try {
            factory.setGroupBy((SObjectField) null);
            Assert.fail(EXCEPTION_THROWN);
        } catch (Exception ex) {
            Assert.areEqual(ex.getMessage(), QueryFactory.INVALID_NULL_FIELD, 'Error message should be displayed');
        }
    }

    @isTest
    static void testSetGroupByStringAttribute() {
        SObjectSelector selector = new TestContactSelector();
        QueryFactory factory = new QueryFactory(selector)
            .setFactoryName('selectContactsAmount')
            .setAggregateFunction(QueryFactory.AggregateFunction.COUNT, Contact.Id)
            .setGroupBy('Name');

        Assert.isTrue(factory.fields.size() > 0, 'Fields for further grouping should be set');
        Assert.isTrue(factory.groupByFields.size() > 0, 'The grouped field should be set');
        Assert.isTrue(factory.isAggregateFunction, 'Aggregate function should be executed');
    }

    @isTest
    static void testSetGroupByStringAttributeWithError() {
        SObjectSelector selector = new TestContactSelector();
        QueryFactory factory = new QueryFactory(selector)
            .setFactoryName('selectContactsAmount')
            .setAggregateFunction(QueryFactory.AggregateFunction.COUNT, Contact.Id);
        try {
            factory.setGroupBy((String) null);
            Assert.fail(EXCEPTION_THROWN);
        } catch (Exception ex) {
            Assert.areEqual(ex.getMessage(), QueryFactory.INVALID_FIELD_GROUP_BY_CLAUSE_ERROR_MSG, 'Error message should be displayed');
        }
    }

    @isTest
    static void testSetGroupBySetSObjectFieldsAttribute() {
        SObjectSelector selector = new TestContactSelector();
        QueryFactory factory = new QueryFactory(selector)
            .setFactoryName('selectContactsAmount')
            .setAggregateFunction(QueryFactory.AggregateFunction.COUNT, Contact.Id)
            .setGroupBy(new Set<SObjectField> {Contact.Name, Contact.Email});

        Assert.isTrue(factory.fields.size() > 0, 'Fields for further grouping should be set');
        Assert.isTrue(factory.groupByFields.size() > 0, 'The grouped fields should be set');
        Assert.isTrue(factory.isAggregateFunction, 'Aggregate function should be executed');
    }

    @isTest
    static void testSetGroupBySetStringsAttribute() {
        SObjectSelector selector = new TestContactSelector();
        QueryFactory factory = new QueryFactory(selector)
            .setFactoryName('selectContactsAmount')
            .setAggregateFunction(QueryFactory.AggregateFunction.COUNT, Contact.Id)
            .setGroupBy(new Set<String> {'Name', 'Email'});

        Assert.isTrue(factory.fields.size() > 0, 'Fields for further grouping should be set');
        Assert.isTrue(factory.groupByFields.size() > 0, 'The grouped fields should be set');
        Assert.isTrue(factory.isAggregateFunction, 'Aggregate function should be executed');
    }

    @isTest
    static void testSetCountAggregateFunction() {
        SObjectSelector selector = new TestContactSelector();
        QueryFactory factory = new QueryFactory(selector)
            .setFactoryName('selectContactsAmount')
            .setCountAggregateFunction();
        
        Assert.isTrue(factory.fields.size() > 0, 'Fields for further grouping should be set');
        Assert.isTrue(factory.isAggregateFunction, 'Aggregate function should be executed');
        Assert.isFalse(factory.includeSelectorFields, 'Should be executed via Database countQuery() method');
    }

    @isTest
    static void testSetCountAggregateFunctionWithAttribute() {
        SObjectSelector selector = new TestContactSelector();
        QueryFactory factory = new QueryFactory(selector)
            .setFactoryName('selectContactsAmount')
            .setAggregateFunction(QueryFactory.AggregateFunction.COUNT, Contact.Id);
        
        Assert.isTrue(factory.fields.size() > 0, 'Fields for further grouping should be set');
        Assert.isTrue(factory.isAggregateFunction, 'Aggregate function should be executed');
        Assert.isFalse(factory.includeSelectorFields, 'Should be executed via Database countQuery() method');
        Assert.isTrue(factory.fields.contains('COUNT(Id)'), 'The COUNT function should contain attribute');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testSetMaxAggregateFunctionWithAttribute() {
        createTestContacts(new List<Integer> {500, 300}, 2);

        SObjectSelector selector = new TestContactSelector();
        List<AggregateResult> results = (List<AggregateResult>) new QueryFactory(selector)
            .setFactoryName('selectContactsAmount')
            .setAggregateFunction(QueryFactory.AggregateFunction.MAX, Contact.Forecasted_Office_Users__c)
            .executeQuery();

        assertAggregateFunctions(results, 500);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testAggregateFunctionWithAttributeWithoutGroupBy() {
        final Integer RECORDS_NUMBER = 5;
        final Map<SObjectField, Object> fields = new Map<SObjectField, Object> {
            Contact.FirstName => 'Aquiva',
            Contact.LastName => 'Tester',
            Contact.Email => 'tester@aquiva.com'
        };

        new SObjectBuilder(Contact.SObjectType)
            .setFields(fields)
            .quantity(RECORDS_NUMBER)
            .create();

        SObjectSelector selector =  new TestContactSelector();
        List<AggregateResult> results = (List<AggregateResult>) new QueryFactory(selector)
            .setFactoryName('selectContactsAmount')
            .setAggregateFunction(QueryFactory.AggregateFunction.COUNT, Contact.Id)
            .executeQuery();

        assertAggregateFunctions(results, RECORDS_NUMBER);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testSetMinAggregateFunction() {
        createTestContacts(new List<Integer> {500, 300}, 2);
            
        SObjectSelector selector = new TestContactSelector();
        List<AggregateResult> results = (List<AggregateResult>) new QueryFactory(selector)
            .setFactoryName('selectContactsAmount')
            .setAggregateFunction(QueryFactory.AggregateFunction.MIN, Contact.Forecasted_Office_Users__c)
            .executeQuery();

        assertAggregateFunctions(results, 300);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testSetAvgAggregateFunction() {
        createTestContacts(new List<Integer> {500, 300}, 2);
            
        SObjectSelector selector = new TestContactSelector();
        List<AggregateResult> results = (List<AggregateResult>) new QueryFactory(selector)
            .setFactoryName('selectContactsAmount')
            .setAggregateFunction(QueryFactory.AggregateFunction.AVG, Contact.Forecasted_Office_Users__c)
            .executeQuery();

        assertAggregateFunctions(results, 400);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testSetSumAggregateFunction() {
        createTestContacts(new List<Integer> {500, 300}, 2);
            
        SObjectSelector selector = new TestContactSelector();
        List<AggregateResult> results = (List<AggregateResult>) new QueryFactory(selector)
            .setFactoryName('selectContactsAmount')
            .setAggregateFunction(QueryFactory.AggregateFunction.SUM, Contact.Forecasted_Office_Users__c)
            .executeQuery();

        assertAggregateFunctions(results, 800);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testSetCountDistinctAggregateFunction() {
        final Map<SObjectField, Object> fields = new Map<SObjectField, Object> {
            Contact.FirstName => ValueProviderBuilder.provideList(new List<String> {'Aquiva', null}),
            Contact.LastName => 'Tester',
            Contact.Email => 'tester@aquiva.com'
        };

        new SObjectBuilder(Contact.SObjectType)
            .setFields(fields)
            .quantity(2)
            .create();

        SObjectSelector selector = new TestContactSelector();
        List<AggregateResult> results = (List<AggregateResult>) new QueryFactory(selector)
            .setFactoryName('selectContactsAmount')
            .setAggregateFunction(QueryFactory.AggregateFunction.COUNT_DISTINCT, Contact.FirstName)
            .executeQuery();

        assertAggregateFunctions(results, 1);
    }

    @isTest
    static void testSetMultipleAggregateFunction() {
        createTestContacts(new List<Integer> {500, 300}, 2);

        SObjectSelector selector = new TestContactSelector();
        List<AggregateResult> results = (List<AggregateResult>) new QueryFactory(selector)
            .setFactoryName('selectContactsAmount')
            .setAggregateFunction(new Map<QueryFactory.AggregateFunction, SObjectField> {
                QueryFactory.AggregateFunction.COUNT => Contact.Id,
                QueryFactory.AggregateFunction.MAX => Contact.Forecasted_Office_Users__c,
                QueryFactory.AggregateFunction.MIN => Contact.Forecasted_Office_Users__c,
                QueryFactory.AggregateFunction.AVG => Contact.Forecasted_Office_Users__c
            })
            .executeQuery();
        
        AggregateResult result = results.get(0);
        Decimal expr0 = (Decimal) result.get(EXPR0);
        Decimal expr1 = (Decimal) result.get(EXPR1);
        Decimal expr2 = (Decimal) result.get(EXPR2);
        Decimal expr3 = (Decimal) result.get(EXPR3);

        Assert.isFalse(result == null, 'Aggregate result should not be empty');
        Assert.areEqual(expr0, 400, 'Unexpected COUNT field value returned');
        Assert.areEqual(expr1, 2, 'Unexpected MAX field value returned');
        Assert.areEqual(expr2, 500, 'Unexpected MIN field value returned');
        Assert.areEqual(expr3, 300, 'Unexpected AVG field value returned');
    }

    private static void createTestContacts(List<Integer> values, Integer count) {
        final Map<SObjectField, Object> fields = new Map<SObjectField, Object> {
            Contact.Forecasted_Office_Users__c => ValueProviderBuilder.provideList(values),
            Contact.LastName => 'Tester',
            Contact.Email => 'tester@aquiva.com'
        };

        new SObjectBuilder(Contact.SObjectType)
            .setFields(fields)
            .quantity(count)
            .create();
    }


    private static void assertAggregateFunctions(List<AggregateResult> results, Decimal actual) {
        Decimal value = (Decimal) results.get(0).get(EXPR0);
        Assert.isFalse(results.isEmpty(), 'Aggregate result should not be empty');
        Assert.areEqual(value, actual, 'Unexpected field value returned');
    }
}