public with sharing class SObjectFactory {
    /*
    * A Boolean used to specify whether or not this this factory should check for CRUD and FLS. 
    * accessibility to the underlying sObjType. Defaults to "true".
    */
    @TestVisible
    private final Boolean applySecurity;

    /* 
    * Constructs the factory with the empty records, care about security by default. 
    */
    public SObjectFactory() {
        this(true);
    }

    /**
    * Construct a new SObjectFactory instance with the ability to swith off the security.
    * @param applySecurity a Boolean used for specify if the factory should check for CRUD and FLS.
    */
    public SObjectFactory(Boolean applySecurity) {
        this.applySecurity = applySecurity;
    }

    /**
    * Constructs the single SObject for the specified type with the default mapping.
    * @param  sObjectType a Schema.SObjectType token used to get the default mapping.
    * @return in-memory constructed SObject.
    */
    public SObject build(SObjectType sObjectType) { 
        return build(sObjectType, 1)[0]; 
    }

    /**
    * Constructs the single SObject for the specified type with the default mapping, overrided with the field value.
    * @param  sObjectType a Schema.SObjectType token used to get the default mapping.
    * @param  field a SObjectField reprsenting field added to the factory mapping.
    * @param  value a Object reprsenting field value added to the factory mapping.
    * @return in-memory constructed SObject.
    */
    public SObject build(SObjectType sObjectType, SObjectField field, Object value) {
        return build(sObjectType, 1, field, value)[0];
    }

    /**
    * Constructs the factory with the empty records, convinience for the security selection. 
    * @param  sObjectType a Schema.SObjectType token used to get the default mapping.
    * @param  fieldToValue a Map<SObjectField, Object> reprsenting fields and values added to the factory mapping.
    * @return in-memory constructed SObject.
    */
    public SObject build(SObjectType sObjectType, Map<SObjectField, Object> fieldToValue) {
        return build(sObjectType, 1, fieldToValue)[0];
    }
    
    /**
    * Constructs the several SObjects for the specified type with the default mapping, overrided with the field value.
    * @param  sObjectType a Schema.SObjectType token used to get the default mapping.
    * @param  quantity a Integer reprsenting the number of records created by the factory.
    * @param  field a SObjectField reprsenting field added to the factory mapping.
    * @param  value a Object reprsenting field value added to the factory mapping.
    * @return in-memory constructed SObject.
    */
    public List<SObject> build(SObjectType sObjectType, Integer quantity, SObjectField field, Object value) {
        return build(sObjectType, quantity, new Map<SObjectField, Object> { field => value });
    }

    /**
    * Constructs the factory with the empty records, convinience for the security selection. 
    * @param  sObjectType a Schema.SObjectType token used to get the default mapping.
    * @param  quantity a Integer reprsenting the number of records created by the factory. 
    * @return in-memory constructed SObjects.
    */
    public List<SObject> build(SObjectType sObjectType, Integer quantity) {
        return build(sObjectType, quantity, null);
    }

    /**
    * Constructs the several SObjects for the specified type with the default mapping, overrided with the field value.
    * @param  sObjectType a Schema.SObjectType token used to get the default mapping.
    * @param  quantity a Integer reprsenting the number of records created by the factory.
    * @param  fieldToValue a Map<SObjectField, Object> reprsenting fields and values added to the factory mapping.
    * @return in-memory constructed SObjects.
    */
    public List<SObject> build(SObjectType sObjectType, Integer quantity, Map<SObjectField, Object> fieldToValue) {
        Map<SObjectField, Object> fields = SObjectFactoryFieldDefaults.getDefaults(sObjectType);
        if (fieldToValue != null) {
            fields.putAll(fieldToValue);
        }

        List<SObject> records = new List<SObject>();
        while (records.size() < quantity) {
            SObject record = sObjectType.newSObject();
            for (SObjectField field : fields.keySet()) {
                Object value = fields.get(field);
                if (value instanceof IValueProvider) {
                    value = ((IValueProvider)value).getValue();
                }
                record.put(field, value);
            }
            records.add(record);
        }
        return records;
    }

    /**
    * Inserts the single SObject for the specified type with the default mapping.
    * @param  sObjectType a Schema.SObjectType token used to get the default mapping.
    * @return inserted SObject.
    */
    public SObject create(SObjectType sObjectType) { 
        return create(sObjectType, 1)[0]; 
    }

    /**
    * Inserts the single SObject for the specified type with the default mapping, overrided with the field value.
    * @param  sObjectType a Schema.SObjectType token used to get the default mapping.
    * @param  field a SObjectField reprsenting field added to the factory mapping.
    * @param  value a Object reprsenting field value added to the factory mapping.
    * @return inserted SObject.
    */
    public SObject create(SObjectType sObjectType, SObjectField field, Object value) {
        return create(sObjectType, 1, field, value)[0];
    }

    /**
    * Inserts the factory with the empty records, convinience for the security selection.
    * @param  sObjectType a Schema.SObjectType token used to get the default mapping.
    * @param  fieldToValue a Map<SObjectField, Object> reprsenting fields and values added to the factory mapping.
    * @return inserted SObjects.
    */
    public SObject create(SObjectType sObjectType, Map<SObjectField, Object> fieldToValue) {
        return create(sObjectType, 1, fieldToValue)[0];
    }

    /**
    * Inserts the several SObjects for the specified type with the default mapping, overrided with the field value.
    * @param  sObjectType a Schema.SObjectType token used to get the default mapping.
    * @param  quantity a Integer reprsenting the number of records created by the factory.
    * @param  field a SObjectField reprsenting field added to the factory mapping.
    * @param  value a Object reprsenting field value added to the factory mapping.
    * @return inserted SObject
    */
    public List<SObject> create(SObjectType sObjectType, Integer quantity, SObjectField field, Object value) {
        return create(sObjectType, quantity, new Map<SObjectField, Object> { field => value });
    }

    /**
    * Inserts the factory with the empty records, convinience for the security selection.
    * @param  sObjectType a Schema.SObjectType token used to get the default mapping.
    * @param  quantity a Integer reprsenting the number of records created by the factory.
    * @return inserted SObjects.
    */
    public List<SObject> create(SObjectType sObjectType, Integer quantity) {
        return create(sObjectType, quantity, null);
    }

    /**
    * Inserts the several SObjects for the specified type with the default mapping, overrided with the field value.
    * @param  sObjectType a Schema.SObjectType token used to get the default mapping.
    * @param  quantity a Integer reprsenting the number of records created by the factory.
    * @param  fieldToValue a Map<SObjectField, Object> reprsenting fields and values added to the factory mapping.
    * @throws SObjectFactoryDmlException if the object is not creatable.
    * @return inserted constructed SObjects.
    */
    @SuppressWarnings('PMD.EmptyIfStmt')
    public List<SObject> create(Schema.SObjectType sObjectType, Integer quantity, Map<SObjectField, Object> fieldToValue) {
        List<SObject> records = build(sObjectType, quantity, fieldToValue);
        if (!sObjectType.getDescribe().isCreateable()) {
            throw new SObjectFactoryDmlException('Database.insert', sObjectType);
        }
        if (applySecurity) {
            /* TO DO: Apply your security class there, if you have one. Instead of insert records,
                      use yours 'Security.insertWithCheck(records)'.
            */
        }
        insert records;
        return records;
    }

    public class SObjectFactoryDmlException extends Exception {
        @TestVisible 
        private String dmlOperation;
        @TestVisible
        private SObjectType sObjectType;
        public SObjectFactoryDmlException(String dmlOperation, SObjectType sObjectType) {
            this.sObjectType = sObjectType;
            this.dmlOperation = dmlOperation;
            this.setMessage(dmlOperation + ' is not allowed on the \'' + sObjectType + '\'');
        }
    }
}