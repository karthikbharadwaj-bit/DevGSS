@IsTest
public class QueryFactoryAssertBuilder {
    private enum AssertAction {
        BINDINGS,
        FIELDS,
        CONDITION,
        LIMIT_CLAUSE,
        SUBQUERIES // TODO: Implement assertion for subqueries
    }

    private final Set<AssertAction> actionsToAssert = new Set<AssertAction>();
    private final QueryFactory factory;
    private List<Object> expectedBindings;
    private String expectedCondition;
    private Set<String> expectedFields;
    private Integer expectedLimit;

    public QueryFactoryAssertBuilder(QueryFactory factory) {
        this.factory = factory;
    }

    public QueryFactoryAssertBuilder withBinding(Object expectedBinding) {
        return withBindings(new List<Object> {expectedBinding});
    }

    public QueryFactoryAssertBuilder withBindings(List<Object> expectedBindings) {
        this.actionsToAssert.add(AssertAction.BINDINGS);
        this.expectedBindings = expectedBindings;
        return this;
    }

    public QueryFactoryAssertBuilder withCondition(String expectedCondition) {
        this.actionsToAssert.add(AssertAction.CONDITION);
        this.expectedCondition = expectedCondition;
        return this;
    }

    public QueryFactoryAssertBuilder withFields(Set<String> expectedFields) {
        this.actionsToAssert.add(AssertAction.FIELDS);
        this.expectedFields = expectedFields;
        return this;
    }

    public QueryFactoryAssertBuilder withFields(Set<SObjectField> expectedFields) {
        Set<String> fieldNames = new Set<String>();
        for (SObjectField field : expectedFields) {
            fieldNames.add(field.toString());
        }
        return withFields(fieldNames);
    }

    public QueryFactoryAssertBuilder withLimit(Integer expectedLimit) {
        this.actionsToAssert.add(AssertAction.LIMIT_CLAUSE);
        this.expectedLimit = expectedLimit;
        return this;
    }

    public void assert() {
        Assert.isNotNull(factory, 'A SObjectSelector must return a factory');
        for (AssertAction actionToAssert : actionsToAssert) {
            assertAction(actionToAssert);
        }
    }

    private void assertAction(AssertAction actionToAssert) {
        switch on actionToAssert {
            when BINDINGS {
                assertBindings();
            }
            when FIELDS {
                assertFields();
            }
            when CONDITION {
                assertCondition();
            }
            when LIMIT_CLAUSE {
                assertLimit();
            }
            when SUBQUERIES {
                // TODO: Implement assertion for subqueries
                //assertSubqueries();
            }
            when else {
                Assert.fail('Unknown action to assert: ' + actionToAssert);
            }
        }
    }

    private String assertMsg(String msg) {
        return factory.getFactoryName() + ' ' + msg;
    }

    private void assertBindings() {
        Assert.areEqual(
            expectedBindings,
            factory.bindings,
            assertMsg('must have the correct bindings')
        );
    }

    private void assertFields() {
        Assert.isTrue(
            factory.fields.containsAll(expectedFields),
            assertMsg('not all expected fields are present in the query')
        );
    }

    private void assertCondition() {
        Assert.areEqual(
            expectedCondition,
            factory.getCondition(),
            assertMsg('must have the correct condition')
        );
    }

    private void assertLimit() {
        Assert.areEqual(
            expectedLimit,
            factory.getLimit(),
            assertMsg('must have the correct limit')
        );
    }
}