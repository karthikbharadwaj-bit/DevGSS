public with sharing class SObjectBuilder {
    /*
    * This property is read-only and may not be set after instantiation.
    * A Boolean used to specify whether or not builder should check for CRUD and FLS 
    * accessibility to the underlying sObjType. Defaults to "false".
    */
    @TestVisible
    private final Boolean applySecurity;

    /**
    * This property is read-only and may not be set after instantiation.
    * A List<SObject> used to specify the records provided by the builder.
    */
    @TestVisible
    private final List<SObject> records;
   
    /**
    * This property is read-only and may not be set after instantiation.
    * The Schema.SObjectType token of the SObject that will be used in the {@link SObjectFactory} to build the records.
    */
    @TestVisible
    private final SObjectType sObjectType;

    /**
    * This property is read-only and may not be set after instantiation.
    * The Map<Schema.SObjectField, Object> that will be used in the {@link SObjectFactory} for the fields mapping.
    */
    @TestVisible
    private final Map<SObjectField, Object> fieldToValue;

    /*
    * The Integer used to specify how many records factory should produce.
    */
    @TestVisible
    private Integer quantity;

    /**
    * Construct a new SObjectBuilder instance with the specified SObjectType 
    * with the security consifirations enabled.
    * @param sObjectType a Schema.SObjectType token used for building the records in the {@link SObjectFactory}.
    */
    public SObjectBuilder(SObjectType sObjectType) {
        this(sObjectType, true);
    }

    /**
    * Covinience for the ability to swith off security.
    * @param sObjectType a Schema.SObjectType token used for building the records in the {@link SObjectFactory}.
    * @param applySecurity a Boolean used for specify if builder should check for CRUD and FLS. 
    *        Pass it to the {@link SObjectFactory}.
    */
    public SObjectBuilder(SObjectType sObjectType, Boolean applySecurity) {
        this.quantity = 1;
        this.applySecurity = applySecurity;
        this.sObjectType = sObjectType;
        this.records = new List<SObject>();
        this.fieldToValue = new Map<SObjectField, Object>();
    }

    /**
    * Set up the number of records returned created in the builder
    * @param   quantity a Integer reprsenting the number od records created by the builder
    * @return  this SObjectBuilder
    */
    public SObjectBuilder quantity(Integer quantity) {
        this.quantity = quantity;
        return this;
    }

    /**
    * Set up the number a new field in the factory mapping
    * @param  field a SObjectField reprsenting field added to the factory mapping
    * @param  value a Object reprsenting field value added to the factory mapping
    * @return this SObjectBuilder
    */
    public SObjectBuilder setField(SObjectField field, Object value) {
        this.fieldToValue.put(field, value);
        return this;
    }

    /**
    * Set up the number of fields in the factory mapping
    * @param  fieldToValue a Map<SObjectField, Object> reprsenting fields and values added to the factory mapping
    * @return this SObjectBuilder
    */
    public SObjectBuilder setFields(Map<SObjectField, Object> fieldToValue) {
        this.fieldToValue.putAll(fieldToValue);
        return this;
    }

    /**
    * In-memory creates a number of records for the specified SObjectType with the mapping if provided,
    * otherwise use default mapping.
    * @return this SObjectBuilder
    */
    public SObjectBuilder build() {
        this.records.clear();
        this.records.addAll(new SObjectFactory(this.applySecurity).build(sObjectType, quantity, fieldToValue));
        return this;
    }

    /**
    * Inserts a number of records for the specified SObjectType with the mapping if provided,
    * otherwise use default mapping.
    * @return this SObjectBuilder
    */
    public SObjectBuilder create() {
        this.records.clear();
        this.records.addAll(new SObjectFactory(this.applySecurity).create(sObjectType, quantity, fieldToValue));
        return this;
    }

    /**
    * Inserts a number of records for the specified SObjectType with the mapping if provided,
    * otherwise use default mapping as specified user.
    * @param user a User reprsenting records creator.
    * @return this SObjectBuilder
    */
    public SObjectBuilder createAsUser(User user) {
        System.runAs(user) { 
            this.create(); 
        }
        return this;
    }

    /**
    * Returns a single records created by the factory.
    * @return a SObject representing a single record created.
    */
    public SObject getRecord() {
        return getRecord(0);
    }

    /**
    * Returns a single records created by the factory.
    * @return a SObject representing a single record created.
    */
    public SObject getRecord(Integer position) {
        return (this.records.size() - (position + 1) >= 0 ? this.records[position] : null);
    }

    /**
    * Returns a records created by the factory.
    * @return a List<SObject> representing a records created in the factory.
    */
    public List<SObject> getRecords() { 
        return this.records; 
    }
}