public class QueryFactory {
    @TestVisible
    private static final String FUNCTION_WITH_ATTRIBUTE_ERROR_MSG = 'The aggregate functions other than COUNT() should be used with a field in an attribute';

    @TestVisible
    private static final String INVALID_FIELD_GROUP_BY_CLAUSE_ERROR_MSG = 'The GROUP BY clause should contain a valid field';

    @TestVisible
    private static final String INVALID_NULL_FIELD = 'Invalid field: null';

    @TestVisible
    private static final String LIMIT_WITHOUT_GROUP_BY_CLAUSE_ERROR_MSG = 'You cannot use a LIMIT clause in a query that uses an aggregate function, but does not use a GROUP BY clause';

    /*
    * An enumeration for specifing the sort order used in an ORDER BY clause (i.e. ASC or DESC)
    */
    public enum SortOrder {ASCENDING, DESCENDING}

    /*
    * The enum represents aggregate functions that can be used in SOQL queries
    */
    public enum AggregateFunction {COUNT, SUM, AVG, MIN, MAX, COUNT_DISTINCT}

    /*
    * This property is read-only and may not be set after instantiation.
    * The {@link Schema.SObjectType} token of the SObject that will be used in the FROM clause of the resultant query.
    */
    public Schema.SObjectType sObjType {get; private set;}

    public SObjectDescribeHelper sObjectSchema {
        get {
            if (sObjectSchema == null) {
                sObjectSchema = SObjectDescribeHelper.getDescribe(sObjType);
            }
            return sObjectSchema;
        }
        private set;
    }

    /*
    * A String representing the name of the query that will be stored in the cache
    */
    private String factoryName;

    /*
    * A String representing the query after you finished query factory configuration
    */
    private String query;

    /*
    * A Set<String> object containing the select fields used to the build the SOQL query
    */
    @TestVisible
    private Set<String> fields;

    /*
    * A Set<String> object contains fields for the GROUP BY clause in SOQL query
    */
    @TestVisible
    private Set<String> groupByFields;

    /*
    * Indicates whether it's an aggregate function query or not
    */
    @TestVisible
    private Boolean isAggregateFunction = false;

    /*
    * A String representing the condition expression that will be used to build the WHERE clause of the SOQL query
    */
    private String conditionExpression;

    /*
    * An Integer representing the maximum number of records to return in a SOQL query, and is used to build
    * the LIMIT clause of the SOQL query
    */
    private Integer limitCount;

    /*
    * An Integer representing the representing the number of records that will be skiped in a SOQL query, and it used to build
    * the OFFSET clause of the SOQL query
    */
    private Integer offsetCount;

    /**
    * A List<Ordering> object containing the fields to be used to build the ORDER BY clause of the SOQL query
    */
    private List<Ordering> order;

    /*
    * An SobjectSelector object representing the selector associated with this query factory
    */
    private SObjectSelector selector {
        get;
        set {
            this.selector = value;
            if (this.selector != null) {
                this.enforceFLS = this.selector.enforceFLS;
                this.assertCRUD = this.selector.assertCRUD;
                this.selectorFields = this.selector.getDefaultFieldList();
                this.selectorOrderBy = this.selector.getOrderBy();
                this.sObjType = this.selector.getSObjectType();

                if (this.selector.relationshipName != null) {
                    Schema.ChildRelationship[] childRelationships = this.selector.relationshipBase.getDescribe().getChildRelationships();
                    for (Schema.ChildRelationship childRelationship : childRelationships) {
                        if (childRelationship.getRelationshipName() == this.selector.relationshipName) {
                            this.sObjType = childRelationship.getChildSObject();
                            this.childRelationship = childRelationship;
                            break;
                        }
                    }
                }
            }
        }
    }

    /**
    * A List<Schema.SObjectField> object containing the fields specified in the selector associated with this
    * query factory
    */
    private List<Schema.SObjectField> selectorFields;

    /*
    * A String representing the "order by" fields from the selector associated with this query factory
    */
    private String selectorOrderBy;

    /*
    * A Boolean used to specify whether or not field-level security should be enforced. Defaults to "false".
    */
    @TestVisible
    private Boolean enforceFLS = false;

    /*
    * A Boolean used to specify whether or not this query factory should check for CRUD accessibility to the
    * underlying sObjType before building the SOQL query.  Defaults to "false".
    */
    @TestVisible
    private Boolean assertCRUD = false;

    /*
    * A Boolean used to specify whether or not the select fields should be sorted in the generated SOQL query
    * (i.e. To ease finding a specific field in a large set of select fields).  Defaults to "true".
    */
    private Boolean sortSelectFields = true;

    /*
    * A Boolean used to specify whether or not the fields from the selector associated with this query factory
    * should be included as part of the SOQL select fields. Defaults to "true".
    */
    @TestVisible
    private Boolean includeSelectorFields = true;

    /*
    * A Boolean used to specify whether or not the "order by" of the selector associated with this query factory
    * should be include as part of the SOQL ORDER BY.  Defaults to "true".
    */
    private Boolean includeSelectorOrderBy = true;

    /*
    * A Boolean used to specify whether or not the query factory result will be stored in the @ObjectCache.
    */
    private Boolean enableQueryCaching = false;

    /*
    * Add ALL ROWS clause to query
    */
    private Boolean queryAllRows = false;

    /*
    * A Schema.ChildRelationship object used to support subselect queries Subselects can be added to a query,
    * as long as it isn't a subselect query itself
    */
    private Schema.ChildRelationship childRelationship {
        get;
        set {
            if (value != null) {
                this.childRelationship = value;
                this.sObjType = this.childRelationship.getChildSObject();
            }
        }
    }

    /*
    * A Map<Schema.ChildRelationship, QueryFactory> object used to hold all of the  subselect queries
    * added to this query factory
    */
    private Map<Schema.ChildRelationship, QueryFactory> subselectQueryMap;

    /*
    * Query binding count
    */
    private final Integer MAX_BINDINGS_COUNT = 5;
    private final String BIND_0 = ':bind0';
    private final String BIND_1 = ':bind1';
    private final String BIND_2 = ':bind2';
    private final String BIND_3 = ':bind3';
    private final String BIND_4 = ':bind4';
    private final Set<String> BIND_STRINGS = new Set<String> {
        BIND_0, BIND_1, BIND_2, BIND_3, BIND_4
    };

    /*
    * Query params for the dynamic bindings
    */
    @TestVisible
    private List<Object> bindings = new List<Object>();

    /*
    * Individual params for the dynamic bindings
    * Possible to get out of bounds error, fix it later
    */
    private Object bind0 {
        get {
            if (bind0 == null) {
                bind0 = bindings[0];
            }
            return bind0;
        }
        set;
    }

    private Object bind1 {
        get {
            if (bind1 == null) {
                bind1 = bindings[1];
            }
            return bind1;
        }
        set;
    }

    private Object bind2 {
        get {
            if (bind2 == null) {
                bind2 = bindings[2];
            }
            return bind2;
        }
        set;
    }

    private Object bind3 {
        get {
            if (bind3 == null) {
                bind3 = bindings[3];
            }
            return bind3;
        }
        set;
    }

    private Object bind4 {
        get {
            if (bind4 == null) {
                bind4 = bindings[4];
            }
            return bind4;
        }
        set;
    }

    public QueryFactory(Schema.SObjectType sObjectType) {
        this(new GeneralSelector(sObjectType), null);
    }

    /**
    * Construct a new QueryFactory instance with the specified SObjectSelector.  The Schema.SObjectType
    * of the selector is used for construction
    * @param selector the SObjectSelector to be used for this query factory
    */
    public QueryFactory(SObjectSelector selector) {
        this(selector, null);
    }

    /**
    * Construct a new QueryFactory instance with the specified SObjectSelector and
    * Schema.SObjectType objects
    * @param selector the SObjectSelector to be used for this query factory
    * @param sObjectType a Schema.SObjectType object used for building the SOQL query
    * @param relationship a Schema.ChildRelationship object used for a building a subselect part of a SOQL query
    */
    public QueryFactory(SObjectSelector selector, Schema.ChildRelationship relationship) {
        this.selector = selector;
        this.childRelationship = relationship;

        this.fields = new Set<String>();
        this.order = new List<Ordering>();
        this.groupByFields = new Set<String>();
    }

    /**
    * Return the fully qualified field string for the specified field name
    * @param  fieldName a String reprsenting the field name to build a path for
    * @return  a String representing the fully qualified field name
    * @throws  CrudException if the field is not readable, and FLS is enforced
    * @throws  InvalidFieldException if the field is not found on the sObjType
    * @throws  NonReferenceFieldException if the field is used in a cross-object query but is not
    *          a lookup or master-detail field
    */
    @SuppressWarnings('PMD.EmptyIfStmt')
    private String getFieldPath(String fieldName) {
        if (!fieldName.contains('.')) { // handle single field
            Schema.SObjectField token = SObjectDescribeHelper.getDescribe(sObjType).getField(fieldName.toLowerCase());
            if (token == null) {
                throw new InvalidFieldException(fieldName,this.sObjType);
            }
            if (enforceFLS) {
                /* TO DO: Security class checks. */
            }
            return token.getDescribe().getName();
        }

        // traverse FK relationship(s)
        List<String> fieldPath = new List<String>();
        Schema.sObjectType lastSObjectType = sObjType;
        Iterator<String> i = fieldName.split('\\.').iterator();
        while (i.hasNext()) {
            String field = i.next();
            Schema.SObjectField token = SObjectDescribeHelper.getDescribe(lastSObjectType).getField(field.toLowerCase());
            DescribeFieldResult tokenDescribe = token != null ? token.getDescribe() : null;
            if (token != null && enforceFLS) {
                /* TO DO: Security class checks. */
            }

            if (token != null && i.hasNext() && tokenDescribe.getSOAPType() == Schema.SOAPType.ID) {
                List<Schema.SObjectType> references = tokenDescribe.getReferenceTo();
                if (!references.isEmpty()) {
                    lastSObjectType = references.get(0); // If it's polymorphic, it doesn't matter which one we get
                }
                fieldPath.add(tokenDescribe.getRelationshipName());
            } else if (token != null && !i.hasNext()) {
                fieldPath.add(tokenDescribe.getName());
            } else {
                if (token == null) {
                    throw new InvalidFieldException(field,lastSObjectType);
                } else {
                    throw new NonReferenceFieldException(lastSObjectType + '.' + field + ' is not a lookup or master-detail field but is used in a cross-object query field.');
                }
            }
        }

        return String.join(fieldPath,'.');
    }

    /**
    * Return the field name from the specified Schema.SObjectfield object
    * @param  field a Schema.SObjectField object from which the field name will be retrieved
    * @return a String representing the name of the field
    * @throws InvalidFieldException if the field passed in is NULL
    */
    @TestVisible
    private static String getFieldTokenPath(Schema.SObjectField field) {
        if (field == null) {
            throw new InvalidFieldException(INVALID_NULL_FIELD);
        }
        return field.getDescribe().getName();
    }

    /**
    * Return true if the passed in object is equal to this object. Instances of QueryFactory will be considered equal
    * if they produce the same SOQL query.  A faster comparison will first be attempted to check if they apply to the same
    * table, and contain the same number of fields selected. This method will never return true if the provided object is
    * not an instance of QueryFactory.
    * @param obj an Object to compare with this object to determine if they are equal to each other
    * @return  a Boolean indicating whether or not the passed in object is equal to this object
    */
    public Boolean equals(Object obj) {
        if (!(obj instanceof QueryFactory) || ((QueryFactory)obj).sObjType != this.sObjType || ((QueryFactory)obj).fields.size() != this.fields.size()) {
            return false;
        }
        return ((QueryFactory)obj).setQuery().query == this.setQuery().query;
    }

    /**
    * Determine if the User has read access on the {@link #sObjType}.
    * Asserts true if User has access.
    * @return this QueryFactory
    * @throws  CrudException if the object associated with the {@link #sObjType} is not readable
    */
    public QueryFactory assertIsAccessible() {
        /* TO DO: Security class checks. */
        return this;
    }

    /**
    * Add the specified field to the select fields of the query
    * @param fieldName a String representing the field name to add to the select statement
    * @return  this QueryFactory
    */
    public QueryFactory selectField(String fieldName) {
        fields.add(getFieldPath(fieldName));
        return this;
    }

    /**
    * Add the specified field to the select fields of the query
    * @param field a Schema.SObjectField object to representing the field to add to the select statement
    * @return  this QueryFactory
    * @throws InvalidFieldException if the field is null
    */
    @SuppressWarnings('PMD.EmptyIfStmt')
    public QueryFactory selectField(Schema.SObjectField field) {
        if(field == null) {
            throw new InvalidFieldException(null,this.sObjType);
        }
        if (enforceFLS) {
            /* TO DO: Security class checks. */
        }
        fields.add(getFieldTokenPath(field));
        return this;
    }

    /**
    * Add all of the fields from the specified set of field names to the select fields of the query
    * @param fields a Set<String> object containing the field names to select.
    * @return  this QueryFactory
    */
    public QueryFactory selectFields(Set<String> fieldNames) {
        for(String fieldName : fieldNames) {
            fields.add(getFieldPath(fieldName));
        }
        return this;
    }

    /**
    * Selects multiple fields. This acts the same as calling {@link #selectField(String)} multiple times.
    * @param fieldNames the List of field API names to select.
    */
    public QueryFactory selectFields(List<String> fieldNames) {
        for(String fieldName:fieldNames) {
            fields.add(getFieldPath(fieldName));
        }
        return this;
    }

    /**
    * Add all of the fields from the specified set of Schema.SObjectField objects to the select fields of the query
    * @param fields a Set<Schema.SObjectField> object containing the {@link Schema.SObjectField} objects to select.
    * @return  this QueryFactory
    * @throws InvalidFieldException if any of the {@code fields} are null .
    **/
    @SuppressWarnings('PMD.EmptyIfStmt')
    public QueryFactory selectFields(Set<Schema.SObjectField> fields) {
        for(Schema.SObjectField token:fields) {
            if(token == null) {
                throw new InvalidFieldException();
            }
            if (enforceFLS) {
                /* TO DO: Security class checks. */
            }
            this.fields.add(getFieldTokenPath(token));
        }
        return this;
    }

    /**
    * Add all of the fields from the specified list of Schema.SObjectField objects to the select fields of the query
    * @param fields a List<Schema.SObjectField> object containing the {@link Schema.SObjectField} objects to select.
    * @return  this QueryFactory
    * @throws InvalidFieldException if any of the {@code fields} are null.
    */
    @SuppressWarnings('PMD.EmptyIfStmt')
    public QueryFactory selectFields(List<Schema.SObjectField> fields) {
        for(Schema.SObjectField token : fields) {
            if(token == null) {
                throw new InvalidFieldException();
            }
            if (enforceFLS) {
                /* TO DO: Security class checks. */
            }
            this.fields.add(getFieldTokenPath(token));
        }
        return this;
    }

    /**
    * Add the condition expression to be used by this query factory to build the WHERE clause
    * @param conditionExpression a String representing the condition expression to be used in the WHERE clause
    * @return  this QueryFactory
    */
    public QueryFactory setCondition(String conditionExpression) {
        this.conditionExpression = conditionExpression;
        return this;
    }

    /**
    * Return a condition expression to be used by this query factory to build the WHERE clause
    * @return a String representing the value of the WHERE clause, if any, as set by {@link #setCondition}
    */
    public String getCondition() {
        return this.conditionExpression;
    }

    public QueryFactory addCondition(String conditionExpression) {
        if (String.isBlank(this.conditionExpression)) {
            this.conditionExpression = conditionExpression;
        } else {
            this.conditionExpression = String.format('{0} AND {1}', new List<Object>{
                this.conditionExpression, conditionExpression
            });
        }
        return this;
    }

    public QueryFactory altCondition(String conditionExpression) {
        if (String.isBlank(this.conditionExpression)) {
            this.conditionExpression = conditionExpression;
        } else {
            this.conditionExpression = String.format('{0} OR {1}', new List<Object>{
                this.conditionExpression, conditionExpression
            });
        }
        return this;
    }

    public QueryFactory negateCondition() {
        this.conditionExpression = String.format('NOT {0}', new List<Object> { this.conditionExpression });
        return this;
    }

    public QueryFactory addQueryBindings(List<Object> bindings) {
        List<Object> currentBindings = new List<Object>(this.bindings);

        if (bindings != null) {
            currentBindings.addAll(bindings);
        }

        return this.setQueryBindings(currentBindings);
    }

    public String nextBindingPlaceholder() {
        Integer nextFreeIndex = this.bindings.size();

        return String.format(':bind{0}', new List<Object> { nextFreeIndex });
    }

    /**
    * Add the name to the query factory that will be used in the ObjectCahce
    * @param factoryName a String representing the cfactory name
    * @return  this QueryFactory
    */
    public QueryFactory setFactoryName(String factoryName) {
        this.factoryName = factoryName;
        return this;
    }

    /**
    * Return a the query factory name that will be used in the ObjectCahce
    * @return a String representing the value of query factory name, if any, as set by {@link #setFactoryName}
    */
    public String getFactoryName() {
        return this.factoryName;
    }

    /**
    * Setup the query bindings based on the values provided in the selector, up to 5
    * @return a QueryFactory with the query bindings saved
    */
    public QueryFactory setQueryBindings(List<Object> bindings) {
        if (bindings == null) {
            throw new InvalidBindingException('Bindings parameter should not be null');
        }
        if (bindings.size() > MAX_BINDINGS_COUNT) {
            throw new InvalidBindingException('No more than 5 bindings is allowed. You passed ' + bindings.size() + ' bindings: ' + bindings);
        }
        this.bindings = bindings;
        return this;
    }

    /**
    * Add a single query binding based on the values provided in the selector
    * @return a QueryFactory with the query bindings saved
    */
    public QueryFactory setQueryBindings(Object binding) {
        this.setQueryBindings(new List<Object>{binding});
        return this;
    }

    public static Object get(Object struct, String field){
        return ((Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(struct))).get(field);
    }

    /**
    * Convert the values provided to this instance into a full SOQL string for use with Database.query
    * Check to see if subqueries queries need to be added after the field list.
    * @return  a QueryFactory with the SOQL query to be executed
    */
    @SuppressWarnings('PMD.EmptyIfStmt')
    public QueryFactory setQuery() {
        if (includeSelectorFields) {
            addSelectorFields(selectorFields);
        }

        if (includeSelectorOrderBy) {
            addSelectorOrderBy(selectorOrderBy);
        }

        String result = 'SELECT ';

        //if no fields have been added, just add the Id field so that the query or subquery will not just fail
        if (fields.isEmpty() && !isAggregateFunction) {
            if (enforceFLS) {
                /* TO DO: Security class checks. */
            }
            result += 'Id';
        } else {
            List<String> fieldsToQuery = new List<String>(fields);
            if (sortSelectFields) {
                fieldsToQuery.sort();
            }
            result += String.join(fieldsToQuery,', ');
        }

        if (subselectQueryMap != null && !subselectQueryMap.isEmpty()) {
            for (QueryFactory childRow : subselectQueryMap.values()) {
                result += ', (' + childRow.setQuery().query + ') ';
            }
        }

        result += ' FROM ' + (childRelationship != null ? childRelationship.getRelationshipName() : sObjType.getDescribe().getName());

        if (conditionExpression != null) {
            result += ' WHERE '+ conditionExpression;
        }

        if (!groupByFields.isEmpty()) {
            result += ' GROUP BY ' + String.join(new List<String>(groupByFields),', ');
        }

        if (order.size() > 0) {
            result += ' ORDER BY ';
            for(Ordering o:order) {
                result += o.setQuery() + ', ';
            }
            result = result.substring(0,result.length() - 2);
        }

        if (limitCount != null) {
            result += ' LIMIT ' + limitCount;
        }

        if (offsetCount != null) {
            result += ' OFFSET ' + offsetCount;
        }

        if (queryAllRows != null && queryAllRows == true) {
            result += ' ALL ROWS';
        }

        this.query = result;
        return this;
    }

    /**
    * Return a String representing the query factory name that will be used in the ObjectCahce
    * @return a String representing the value of query factory name, if any, as set by {@link #setQuery}
    */
    public String getQuery() {
        return this.query;
    }

    /**
    * Set the limit count used by this query factory to build the LIMIT clause. If the limit count is not null,
    * it causes a LIMIT clause to be added to the resulting query.
    * @param limitCount an Integer representing the maximum number or records to be returned by the SOQL query.
    * @return  this QueryFactory or throws an exception if it's an aggregate function
    */
    public QueryFactory setLimit(Integer limitCount) {
        if (isAggregateFunction && groupByFields.isEmpty()) {
            throw new InvalidAggregateFunctionException(LIMIT_WITHOUT_GROUP_BY_CLAUSE_ERROR_MSG);
        }
        this.limitCount = limitCount;
        return this;
    }

    /**
    * Return the limit count to be used by this query factory to the build the LIMIT clause
    * @return the current value of the LIMIT clause, if any, as set by {@link #setLimit}
    **/
    public Integer getLimit() {
        return this.limitCount;
    }

    /**
    * Set the offset used by this query factory to build the OFFSET clause
    * @param offsetCount if not null causes a OFFSET caluse to be added to the resulting query.
    */
    public QueryFactory setOffset(Integer offsetCount) {
        this.offsetCount = offsetCount;
        return this;
    }

    /**
    * Return the offset to be used by this query factory to the build the OFFSET clause
    * @return's the current value of the OFFSET clause, as set by {@link #setOffset}.
    */
    public Integer getOffset() {
        return this.offsetCount;
    }

    /**
    * Set the query caching identifying that query results are stored in the @ObjectCache
    * @param queryCaching enables/disables the query caching.
    */
    public QueryFactory setQueryCaching(Boolean queryCaching) {
        this.enableQueryCaching = queryCaching;
        return this;
    }

    /**
    * Return the query cahcing is enabled identifying that query results are stored in the @ObjectCache
    */
    public Boolean getQueryCaching() {
        return this.enableQueryCaching;
    }

    /**
    * Add an Ordering object to be used by this query factory to build the ORDER BY clause
    * @param ordering an instance of {@link QueryFactory.Ordering} to be added to the query's ORDER BY clause.
    * @return  this QueryFactory
    */
    public QueryFactory addOrdering(Ordering ordering) {
        this.order.add(ordering);
        return this;
    }

    /**
    * Return a list of Ordering objects to be used by this query factory to build the ORDER BY clause
    * @return a List<Ordering> object representing the orderings that will be used as the query's ORDER BY clause
    */
    public List<Ordering> getOrderings() {
        return this.order;
    }

    /**
    * Return a set of the selected fields for this query factory
    * @return a Set<String> object representing the selected fields for this query factory
    */
    public Set<String> getSelectedFields() {
        return this.fields;
    }

    /**
    * Add a subselect query to this query factory.  A subselect can be added to a query, as long as it isn't a
    * subselect query itself.  You may have many subselects inside of a query, but they may only be 1 level deep
    * (i.e. No subselects inside of a subselect).
    * @param  subselectQueryFactory an QueryFactory object representing the subselect query factory to be used to build the subselect part
    *         of the SOQL query
    * @return this QueryFactory
    */
    public QueryFactory subselect(QueryFactory subselectQueryFactory) {
        if (subselectQueryFactory.childRelationship == null) {
            subselectQueryFactory.childRelationship = getChildRelationship(subselectQueryFactory.selector.getSObjectType());
        }
        this.setSubSelectQuery(subselectQueryFactory);
        return this;
    }

    /**
    * Add a subquery query to this query.  If a subquery for this relationship already exists, it will be returned.
    * If not, a new one will be created and returned.
    * @param  subselectQueryFactory an QueryFactory representing the subselect query factory
    * @throws InvalidSubqueryRelationshipException If this method is called on a subselectQuery or with an invalid relationship
    **/
    private QueryFactory setSubselectQuery(QueryFactory subselectQueryFactory) {
        if (this.childRelationship != null) {
            throw new InvalidSubqueryRelationshipException('Invalid call to subselectQuery. You may not add a subselect query to a subselect query.');
        }
        if (subselectQueryMap == null) {
            subselectQueryMap = new Map<ChildRelationship, QueryFactory>();
        }
        if (subselectQueryMap.containsKey(subselectQueryFactory.childRelationship)) {
            return subselectQueryMap.get(subselectQueryFactory.childRelationship);
        }
        if (assertCRUD) {
            subSelectQueryFactory.assertIsAccessible();
        }
        subselectQueryMap.put(subselectQueryFactory.childRelationship, subselectQueryFactory);
        return subSelectQueryFactory;
    }

    /**
    * Add the related fields from the specified selector using the relationship field path as a qualifier
    * @param  selector an SObjectSelector object representing the selector containing the related fields
    * @param  relationshipFieldPath a String representing the qualifier to use for the fields in the selector
    * @return this QueryFactory
    */
    public QueryFactory selectRelatedFields(SObjectSelector selector, String relationshipFieldPath)
    {
        // Add fields from selector prefixing the relationship path
        for(SObjectField field : selector.getDefaultFieldList()) {
            selectField(relationshipFieldPath + '.' + field.getDescribe().getName());
        }
        // Automatically select the CurrencyIsoCode for MC orgs (unless the object is a known exception to the rule)
        if(Userinfo.isMultiCurrencyOrganization() && selector.currencyIsoCodeEnabled) {
            selectField(relationshipFieldPath+'.CurrencyIsoCode');
        }
        return this;
    }

    /**
    * Return a list of subselect query factory objects associated with this query factory
    * @return a List<QueryFactory> object representing the subselect queries associated with this query factory
    **/
    public List<QueryFactory> getSubselectQueries() {
        if (subselectQueryMap != null) {
            return subselectQueryMap.values();
        }
        return null;
    }

    /**
    * Get the ChildRelationship from the sObjType for the object type passed in.
    * @param objType The object type of the child relationship to get
    * @return  a Schema.ChildRelationship object representing the relationship for the
    *          passed in SObjectType
    */
    private Schema.ChildRelationship getChildRelationship(SObjectType objType) {
        for (Schema.ChildRelationship childRow : sObjType.getDescribe().getChildRelationships()) {
            /* Occasionally on some standard objects (Like Contact child of Contact) do not have a relationship name.
            if there is no relationship name, we cannot query on it, so throw an exception. */
            if (childRow.getChildSObject() == objType && childRow.getRelationshipName() != null) {
                return childRow;
            }
        }
        throw new InvalidSubqueryRelationshipException('Invalid call to subselectQuery. Invalid relationship for table ' + sObjType + ' and objtype=' + objType);
    }

    /**
    * Get the ChildRelationship from the table for the relationship name passed in.
    * @param relationshipName The name of the object's ChildRelationship on get
    * @return  a Schema.ChildRelationship object representing the relationship for the
    *          passed in relationship name
     */
    private Schema.ChildRelationship getChildRelationship(String relationshipName) {
        for (Schema.ChildRelationship childRow : sObjType.getDescribe().getChildRelationships()) {
            if (childRow.getRelationshipName() == relationshipName) {
                return childRow;
            }
        }
        return null;
    }

    /**
    * Add a field to be sorted on.  This may be a direct field or a field
    * related through an object lookup or master-detail relationship.
    * Use the set to store unique field names, since we only want to sort
    * by the same field one time.  The sort expressions are stored in a list
    * so that they are applied to the SOQL in the same order that they
    * were added in.
    * @param fieldName The string value of the field to be sorted on
    * @param SortOrder the direction to be sorted on (ASCENDING or DESCENDING)
    * @param nullsLast whether to sort null values last (NULLS LAST keyword included).
    * @return  this QueryFactory
    */
    public QueryFactory addOrdering(String fieldName, SortOrder direction, Boolean nullsLast) {
        order.add(new Ordering(getFieldPath(fieldName), direction, nullsLast));
        return this;
    }

    /**
    * Add a field to be sorted on.  This may be a direct field or a field
    * related through an object lookup or master-detail relationship.
    * Use the set to store unique field names, since we only want to sort
    * by the same field one time.  The sort expressions are stored in a list
    * so that they are applied to the SOQL in the same order that they
    * were added in.
    * @param field The SObjectfield to sort.  This can only be a direct reference.
    * @param SortOrder the direction to be sorted on (ASCENDING or DESCENDING)
    * @param nullsLast whether to sort null values last (NULLS LAST keyword included).
    * @return  this QueryFactory
    */
    public QueryFactory addOrdering(SObjectField field, SortOrder direction, Boolean nullsLast) {
        order.add(new Ordering(getFieldTokenPath(field), direction, nullsLast));
        return this;
    }

    /**
    * Add a field to be sorted on.  This may be a direct field or a field
    * related through an object lookup or master-detail relationship.
    * Use the set to store unique field names, since we only want to sort
    * by the same field one time.  The sort expressions are stored in a list
    * so that they are applied to the SOQL in the same order that they
    * were added in.
    * The "NULLS FIRST" keywords will be included by default.  If "NULLS LAST"
    * is required, use one of the overloaded addOrdering methods which include this parameter.
    * @param fieldName The string value of the field to be sorted on
    * @param SortOrder the direction to be sorted on (ASCENDING or DESCENDING)
    * @return  this QueryFactory
    */
    public QueryFactory addOrdering(String fieldName, SortOrder direction) {
        order.add(new Ordering(getFieldPath(fieldName), direction));
        return this;
    }

    /**
    * Add a field to be sorted on.  This may be a direct field or a field
    * related through an object lookup or master-detail relationship.
    * Use the set to store unique field names, since we only want to sort
    * by the same field one time.  The sort expressions are stored in a list
    * so that they are applied to the SOQL in the same order that they
    * were added in.
    * The "NULLS FIRST" keywords will be included by default.  If "NULLS LAST"
    * is required, use one of the overloaded addOrdering methods which include this parameter.
    * @param field The SObjectfield to sort.  This can only be a direct reference.
    * @param SortOrder the direction to be sorted on (ASCENDING or DESCENDING)
    * @return this QueyFactory
    */
    public QueryFactory addOrdering(SObjectField field, SortOrder direction) {
        order.add(new Ordering(getFieldTokenPath(field), direction));
        return this;
    }

    /**
    * Add all of the selector fields to list of fields to be included in the query
    * @param selectorFields a List<Schema.SObjectField> object containing the selector fields to be included in the query
    */
    private void addSelectorFields(List<Schema.SObjectField> selectorFields) {
        if (selectorFields != null) {
            for (Schema.SObjectField selectorField : selectorFields) {
                fields.add(selectorField.getDescribe().getLocalName());
            }
        }
    }

    /**
    * Add all of the selector "order by" fields to the list of orderings to be included in the query.  The selector "order by"
    * fields are always pre-pended to the orders list for the query factory.
    * @param selectorOrderBy a String representing the
    */
    private void addSelectorOrderBy(String selectorOrderBy) {
        if (selectorOrderBy != null) {
            List<Ordering> selectorOrderings = new List<Ordering>();
            for (String orderBy : selectorOrderBy.split(','))
            {
                // TODO: Handle NULLS FIRST and NULLS LAST, http://www.salesforce.com/us/developer/docs/soql_sosl/Content/sforce_api_calls_soql_select_orderby.htm
                List<String> orderByParts = orderBy.trim().split(' ');
                String fieldNamePart = orderByParts[0];
                String fieldSortOrderPart = orderByParts.size() > 1 ? orderByParts[1] : null;
                QueryFactory.SortOrder fieldSortOrder = QueryFactory.SortOrder.ASCENDING;
                if (fieldSortOrderPart == null) {
                    fieldSortOrder = QueryFactory.SortOrder.ASCENDING;
                }
                else if (fieldSortOrderPart.equalsIgnoreCase('DESC')) {
                    fieldSortOrder = QueryFactory.SortOrder.DESCENDING;
                }
                else if (fieldSortOrderPart.equalsIgnoreCase('ASC')) {
                    fieldSortOrder = QueryFactory.SortOrder.ASCENDING;
                }
                // Build a new list of the selector order by fields
                selectorOrderings.add(new Ordering(fieldNamePart, fieldSortOrder));
            }
            /* Add the "order" list (except of already added default Orderings for selector)
            *  of the QueryFactory to the end of the selector orderings, making the selector order by fields first in the list)
            */
            for (Ordering ordering : order) {
                if (!selectorOrderings.contains(ordering)) {
                    selectorOrderings.add(ordering);
                }
            }

            // Replace the "order" list with the new one created by pre-pending the selector orderings to the list
            order = selectorOrderings;
        }
    }

    /**
    * Include FLS enforcement for this query factory
    * @return this QueryFactory
    */
    public QueryFactory withFLSEnforcement() {
        enforceFLS = true;
        return this;
    }

    /**
    * Exclude FLS Enforcement from this query factory
    * @return this QueryFactory
    */
    public QueryFactory withoutFLSEnforcement() {
        enforceFLS = false;
        return this;
    }

    /**
    * Include the selector fields for this query factory
    * @return this QueryFactory
    */
    public QueryFactory withSelectorFieldsIncluded() {
        includeSelectorFields = true;
        return this;
    }

    /**
    * Exclude the selector fields from this query factory
    * @return this QueryFactory
    */
    public QueryFactory withoutSelectorFieldsIncluded() {
        includeSelectorFields = false;
        return this;
    }

    /**
    * Include selector order by fields for this query factory
    * @return this QueryFactory
    */
    public QueryFactory withSelectorOrderByIncluded() {
        includeSelectorOrderBy = true;
        return this;
    }

    /**
    * Exclude selector order by fields from this query factory
    * @return this QueryFactory
    */
    public QueryFactory withoutSelectorOrderByIncluded() {
        includeSelectorOrderBy = false;
        return this;
    }

    /**
    * Include CRUD assertion for this query factory
    * @return this QueryFactory
    */
    public QueryFactory withCRUDAssertion() {
        assertCRUD = true;
        return this;
    }

    /**
    * Exclude CRUD assertion from this query factory
    * @return this QueryFactory
    */
    public QueryFactory withoutCRUDAssertion() {
        assertCRUD = false;
        return this;
    }

    /**
    * Include sorting of the select fields for this query factory
    * @return this QueryFactory
    */
    public QueryFactory withSelectFieldsSorted() {
        sortSelectFields = true;
        return this;
    }

    /**
    * Exclude sorting of the select fields for this query factory
    * @return this QueryFactory
    */
    public QueryFactory withoutSelectFieldsSorted() {
        sortSelectFields = false;
        return this;
    }

    public QueryFactory withAllRows() {
        queryAllRows = true;
        return this;
    }

    /**
    * Execute the query factory query.
    * @return List<SObject>
    */
    public List<SObject> executeQuery() {
        if(String.isEmpty(this.query)) {
            this.setQuery();
        }

        if (this.enableQueryCaching) {
            if (!this.equals((QueryFactory) ObjectCache.get(ObjectCache.Partition.FACTORIES, this.getFactoryName()))) {
                ObjectCache.set(ObjectCache.Partition.FACTORIES, this.getFactoryName(), this);
                ObjectCache.set(ObjectCache.Partition.QUERIES, this.getFactoryName(), Database.query(this.getQuery()));
            }
            return (List<SObject>) ObjectCache.get(ObjectCache.Partition.QUERIES, this.getFactoryName());
        } else {
            return Database.query(this.getQuery());
        }
    }

    /**
     * Executes the Database.countQuery() method to return the number of records that meet the query criteria
     */
    public Integer executeCountQuery() {
        if (String.isEmpty(this.query)) {
            this.setQuery();
        }

        if (this.enableQueryCaching) {
            if (!this.equals((QueryFactory) ObjectCache.get(ObjectCache.Partition.FACTORIES, this.getFactoryName()))) {
                ObjectCache.set(ObjectCache.Partition.FACTORIES, this.getFactoryName(), this);
                ObjectCache.set(ObjectCache.Partition.QUERIES, this.getFactoryName(), Database.countQuery(this.getQuery()));
            }
            return (Integer) ObjectCache.get(ObjectCache.Partition.QUERIES, this.getFactoryName());
        } else {
            return Database.countQuery(this.getQuery());
        }
    }

    /**
     * Adds GROUP BY clause to the query with the SObjectField attribute
     */
    public QueryFactory setGroupBy(SObjectField field) {
        String fieldName = getFieldTokenPath(field);
        setGroupBy(fieldName);
        return this;
    }

    /**
     * Adds GROUP BY clause to the query with String attribute
     */
    public QueryFactory setGroupBy(String field) {
        if (field == null) {
            throw new InvalidAggregateFunctionException(INVALID_FIELD_GROUP_BY_CLAUSE_ERROR_MSG);
        }
        fields.add(getFieldPath(field));
        groupByFields.add(getFieldPath(field));
        return this;
    }

    /**
     * Adds GROUP BY clause to the query with the Set<SObjectField> attributes
     */
    public QueryFactory setGroupBy(Set<SObjectField> fields) {
        for (SObjectField field : fields) {
            setGroupBy(field);
        }
        return this;
    }

    /**
     * Adds GROUP BY clause to the query with the Set<String> attributes
     */
    public QueryFactory setGroupBy(Set<String> fields) {
        for (String field : fields) {
            setGroupBy(field);
        }
        return this;
    }

    /**
     * Adds the COUNT, SUM, AVG, MIN, MAX, COUNT_DISTINCT aggregate functions to the query in shape of a field
     */
    public QueryFactory setAggregateFunction(Map<AggregateFunction, SObjectField> functionToFieldMap) {
        isAggregateFunction = true;
        includeSelectorFields = false;
        includeSelectorOrderBy = false;
        addAggregateFunctionToFields(functionToFieldMap);
        return this;
    }

    public QueryFactory setAggregateFunction(AggregateFunction aggregateFunction, SObjectField field) {
        setAggregateFunction(new Map<AggregateFunction, SObjectField> {aggregateFunction => field});
        return this;
    }

    private void addAggregateFunctionToFields(Map<AggregateFunction, SObjectField> functionToFieldMap) {
        for (AggregateFunction aggregateFunction : functionToFieldMap.keySet()) {
            switch on aggregateFunction {
                when COUNT {
                    if (functionToFieldMap.get(aggregateFunction) == null) {
                        fields.add(String.valueOf(QueryFactory.AggregateFunction.COUNT) + '()');
                    } else {
                        String aggregateFunc = String.valueOf(QueryFactory.AggregateFunction.COUNT) + '(' + getFieldTokenPath(functionToFieldMap.get(aggregateFunction)) + ')';
                        fields.add(aggregateFunc);
                    }
                }
                when SUM, AVG, MIN, MAX, COUNT_DISTINCT {
                    String aggregateFunc = String.valueOf(aggregateFunction) + '(' + getFieldTokenPath(functionToFieldMap.get(aggregateFunction)) + ')';
                    fields.add(aggregateFunc);
                }
                when else {
                    throw new InvalidAggregateFunctionException('Aggregate function ' + String.valueOf(aggregateFunction) + ' is not supported');
                }
            }
        }
    }

    /**
     * Adds COUNT aggregate function without field attribute to the query
     */
    public QueryFactory setCountAggregateFunction() {
        setAggregateFunction(
            new Map<AggregateFunction, SObjectField> {QueryFactory.AggregateFunction.COUNT => null}
        );
        return this;
    }

    /**
    * Execute the query factory.
    * Convenience for the query locator, batch jobs.
    * @return Database.QueryLocator
    */
    public Database.QueryLocator executeQueryLocator() {
        if(String.isEmpty(this.query)) {
            this.setQuery();
        }

        if (this.enableQueryCaching) {
            if (!this.equals((QueryFactory) ObjectCache.get(ObjectCache.Partition.FACTORIES, this.getFactoryName()))) {
                ObjectCache.set(ObjectCache.Partition.FACTORIES, this.getFactoryName(), this);
                ObjectCache.set(ObjectCache.Partition.QUERIES, this.getFactoryName(), Database.getQueryLocator(this.getQuery()));
            }
            return (Database.QueryLocator) ObjectCache.get(ObjectCache.Partition.QUERIES, this.getFactoryName());
        } else {
            return Database.getQueryLocator(this.getQuery());
        }
    }

    /**
    * Create a "deep" clone of this object that can be safely mutated without affecting the cloned instance
    * @return a deep clone of this QueryFactory
    */
    public QueryFactory deepClone() {

        QueryFactory clone = new QueryFactory(selector)
            .setLimit(this.limitCount)
            .setCondition(this.conditionExpression)
            .setQueryBindings(this.bindings);

        clone = this.enforceFLS ? clone.withFLSEnforcement() : clone.withoutFLSEnforcement();
        clone = this.assertCRUD ? clone.withCRUDAssertion() : clone.withoutCRUDAssertion();
        clone = this.includeSelectorFields ? clone.withSelectorFieldsIncluded() : clone.withoutSelectorFieldsIncluded();
        clone = this.includeSelectorOrderBy ? clone.withSelectorOrderByIncluded() : clone.withoutSelectorOrderByIncluded();
        clone = this.sortSelectFields ? clone.withSelectFieldsSorted() : clone.withoutSelectFieldsSorted();

        Map<Schema.ChildRelationship, QueryFactory> subqueries = this.subselectQueryMap;
        if (subqueries != null) {
            Map<Schema.ChildRelationship, QueryFactory> clonedSubqueries = new Map<Schema.ChildRelationship, QueryFactory>();
            for (Schema.ChildRelationship key : subqueries.keySet()) {
                clonedSubqueries.put(key, subqueries.get(key).deepClone());
            }
            clone.subselectQueryMap = clonedSubqueries;
        }

        clone.childRelationship = this.childRelationship;
        clone.order = this.order.clone();
        clone.fields = this.fields.clone();

        return clone;
    }

    /**
    * This class is a representation of a sort order field in an "ORDER BY" statement.  It handles
    * the field name, the sort order direction (ASC or DESC), and whether NULL field values are sorted
    * first or last.
    */
    public class Ordering {
        private SortOrder direction;
        private Boolean nullsLast;
        private String field;

        /**
        * Construct a new Ordering object for use with {@link QueryFactory#addOrdering}
        *
        * @param sobjType  a String representing the SObject type associated with the field
        * @param fieldName a String representing the name of the field to sort on
        * @param direction a SortOrder enum value representing the direction of the sort order (ASC or DESC)
         */
        public Ordering(String sobjType, String fieldName, SortOrder direction) {
            this(
                SObjectDescribeHelper.getDescribe(sobjType).getField(fieldName),
                direction
            );
        }

        /**
        * Construct a new Ordering object for use with {@link QueryFactory#addOrdering}, defaulting
        * NULL field values first in the sort order
        * @param field  a Schema.SObjectField object representing the field to sort on
        * @param direction a SortOrder enum value representing the direction of the sort order (ASC or DESC)
         */
        public Ordering(Schema.SObjectField field, SortOrder order) {
            this(QueryFactory.getFieldTokenPath(field), order, false);
        }

        /**
        * Construct a new Ordering object for use with {@link QueryFactory#addOrdering}
        * @param field  a Schema.SObjectField object representing the field to sort on
        * @param direction a SortOrder enum value representing the direction of the sort order (ASC or DESC)
        * @param nullsLast a Boolean indicating whether or not NULL field values should be sorted last
        *        in the sort order
        */
        public Ordering(Schema.SObjectField field, SortOrder direction, Boolean nullsLast) {
            this(QueryFactory.getFieldTokenPath(field), direction, nullsLast);
        }

        /**
        * Construct a new Ordering object for use with {@link QueryFactory#addOrdering}, defaulting
        * NULL field values first in the sort order
        * @param field a String representing the name of the field to sort on
        * @param direction a SortOrder enum value representing the direction of the sort order (ASC or DESC)
        */
        @TestVisible
        private Ordering(String field, SortOrder direction) {
            this(field, direction, false);
        }

        /**
        * Construct a new Ordering object for use with {@link QueryFactory#addOrdering}, defaulting
        * NULL field values first in the sort order
        * @param field a String representing the name of the field to sort on
        * @param direction a SortOrder enum value representing the direction of the sort order (ASC or DESC)
        * @param nullsLast a Boolean indicating whether or not NULL field values should be sorted last
        *         in the sort order
        */
        @TestVisible
        private Ordering(String field, SortOrder direction, Boolean nullsLast) {
            this.direction = direction;
            this.field = field;
            this.nullsLast = nullsLast;
        }

        /**
        * Return the sort field included in this Ordering object
        * @return a String representing the sort field included in this Ordering object
        */
        public String getField() {
            return this.field;
        }

        /**
        * Return the sort order order included in this Ordering object
        * @return a SortOrder enum value representing the the sort order order included
        *         in this Ordering object
        */
        public SortOrder getOrder() {
            return direction;
        }

        /**
         * Return the Boolean which is used to specify if nulls should be ordered last or first
         * @return a Boolean value, if it is true - orders null records at the end, if false - at the beginning
         */
        public Boolean isNullsLast() {
            return nullsLast;
        }

        /**
        * Return the SOQL string associated with this Ordering object
        * @return a String representing the SOQL associated with this ordering object
        */
        public String setQuery() {
            return field + ' ' + (direction == SortOrder.ASCENDING ? 'ASC' : 'DESC') + (nullsLast ? ' NULLS LAST ' : ' NULLS FIRST ');
        }

        /** This method is implemented to allow correct equality checks for the instances of this object
        * e.g. usage of the instances of this class in List.сontains(...) method
        * @return true if objects are equal, false if not
        */
        public Boolean equals(Object o) {
            if (this === o) {
                return true;
            }

            if (o == null || !(o instanceOf Ordering)) {
                return false;
            }

            Ordering obj = (Ordering) o;

            if (this.direction == obj.getOrder()
                && this.field == obj.getField()
                && this.nullsLast == obj.isNullsLast()) {
                return true;
            }

            return false;
        }

        /* This method is implemented to provide correct usage of this object in hash-based collections
        * and to keep the equals/hashcode contract
        * @return Integer hashcode for the object
        */
        public Integer hashCode() {
            return 31 * (this.direction.hashCode() + this.field.hashCode() + String.valueOf(this.nullsLast).hashCode());
        }
    }

    public class InvalidFieldException extends Exception {
        private String fieldName;
        private Schema.SObjectType objectType;
        public InvalidFieldException(String fieldname, Schema.SObjectType objectType) {
            this.objectType = objectType;
            this.fieldName = fieldName;
            this.setMessage( 'Invalid field \'' + fieldName + '\' for object \'' + objectType + '\'' );
        }
    }

    public class InvalidFieldSetException extends Exception{}
    public class NonReferenceFieldException extends Exception{}
    public class InvalidSubqueryRelationshipException extends Exception{}
    public class InvalidBindingException extends Exception{}
    public class InvalidAggregateFunctionException extends Exception {}
}