public abstract with sharing class SObjectSelector {
    /**
    * An abstract method to that needs to be implemented to inform the base class of the SObject (custom or standard) to be queried
    * @return  a Schema.SObjectType object representing the underlying SObject of this selector
    */
    public abstract Schema.SObjectType getSObjectType();

    /**
    * An abstract method that needs to be implemented to inform the base class of the common fields to be queried or listed by
    * the base class methods
    * @return  a List<Schema.SobjectField> object containing the fields to be queried
    **/
    public abstract List<Schema.SObjectField> getDefaultFieldList();

    public String relationshipName;
    public SObjectType relationshipBase;

    /** Enforce FLS Security **/
    public Boolean enforceFLS;

    /** Enforce CRUD Security **/
    public Boolean assertCRUD;

    /**
    * A String used to keep the default "order by" associated with this selector.  If this field is NULL, the default
    * ORDER BY is set to the "Name" field in ascending order with NULLS first. If the "Name" field does not exist, the
    * default is set to the "CreatedDate" field in ascending order with NULLS first.
    **/
    protected String defaultOrder;

    /**
    * Sort the query fields in the select statement (defaults to true, at the expense of performance).
    * Switch this off if you need more performant queries.
    **/
    private Boolean sortSelectFields;

    /** Describe helper instance for the current sObjectType **/
    private SObjectDescribeHelper sObjectDescribe {
        get {
            if (sObjectDescribe == null) {
                sObjectDescribe = SObjectDescribeHelper.getDescribe(getSObjectType());
            }
            return sObjectDescribe;
        }
        set;
    }

    /**
    * Indicates whether the sObject has the currency ISO code field for organisations which have multi-currency
    * enabled.
    **/
    public Boolean currencyIsoCodeEnabled {
        get {
            if (currencyIsoCodeEnabled == null) {
                currencyIsoCodeEnabled = sObjectDescribe.getFieldsMap().keySet().contains('currencyisocode') &&
                    UserInfo.isMultiCurrencyOrganization();
            }
            return currencyIsoCodeEnabled;
        }
        set;
    }


    /**
    * Return the default ORDER BY associated with this selector.  Override this method to control the default ordering
    * of records returned by the base queries, defaults to the "Name" field of the object, or the "CreatedDate", if the
    * name field does not exist
    * @return a String representing the default ORDER BY associated with this selector
    **/
    public virtual String getOrderBy() {
        if (defaultOrder == null) {
            defaultOrder = 'CreatedDate';
            if (sObjectDescribe.getNameField() != null) {
                defaultOrder = sObjectDescribe.getNameField().getDescribe().getName();
            }
        }
        return defaultOrder;
    }

    /* Constructs the selector by default do not care about the security */
    public SObjectSelector() {
        this(false, false, null, null);
    }

    public SObjectSelector(String relationshipName, SObjectType relationshipBase) {
        this(false, false, relationshipName, relationshipBase);
    }

    public SObjectSelector(Boolean assertCRUD, Boolean enforceFLS) {
        this(assertCRUD, enforceFLS, null, null);
    }

    /*
    * Constructs the Selector
    * Convenience for the security enforcement.
    */
    public SObjectSelector(Boolean assertCRUD, Boolean enforceFLS, String relationshipName, SObjectType relationshipBase) {
        this.assertCRUD = assertCRUD;
        this.enforceFLS = enforceFLS;
        this.relationshipName = relationshipName;
        this.relationshipBase = relationshipBase;
    }

    /**
    * An abstract method to that needs to be implemented to inform the base class of the SObject (custom or standard) to be queried
    * @return  a Schema.SObjectType object representing the underlying SObject of this selector
    */
    public String getSObjectName() {
        return sObjectDescribe.getSObjectType().getDescribe().getName();
    }

    /**
    * Returns a QueryFactory configured with the Selectors object, CRUD assertion and FLS check.
    */
    public QueryFactory newQueryFactory() {
        return new QueryFactory(this);
    }
}