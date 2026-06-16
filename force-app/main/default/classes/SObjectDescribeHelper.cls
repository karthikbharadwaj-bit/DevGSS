public class SObjectDescribeHelper {
    /*
    * A type token, used to get describe or the name of the Schema.SObjectType
    */
    private Schema.SObjectType token;

    /*
    * A field token, representing a name field on the SObject
    */
    private Schema.SObjectField nameField {
        get {
            if (nameField == null) {
                for (Schema.SObjectField field : fields.values()) {
                    if (field.getDescribe().isNameField()) {
                        nameField = field;
                        break;
                    }
                }
            }
            return nameField;
        }
        set;
    }

    /*
    * A SObject describe result, conatins methods for describing SObjects
    */
    private Schema.DescribeSObjectResult describe {
        get {
            if (describe == null) {
                describe = token.getDescribe();
            }
            return describe;
        }
        set;
    }

    /**
    * A Map<String, Schema.SObjectField> with the SObject fields describe
    */
    private Map<String, Schema.SObjectField> fields {
        get {
            if (fields == null) {
                fields = describe.fields.getMap();
            }
            return fields;
        }
        set;
    }

    /*
    * A FieldsMap map wrapper, contains SObject fields describe
    * Provides usefull methods to work with the map collection
    */
    private FieldsMap wrappedFields {
        get {
            if (wrappedFields == null) {
                wrappedFields = new FieldsMap(this.fields);
            }
            return wrappedFields;
        }
        set;
    }

    private Map<String, Schema.ChildRelationship> childRelationshipsCache = new Map<String, Schema.ChildRelationship>();

    /*
    * Accessing all sObjects on the org
    * Provides cache to the describe of the various objects, during execution context.
    */
    private static Map<String, SObjectDescribeHelper> describeCache {
        get {
            if (describeCache == null) {
                describeCache = new Map<String, SObjectDescribeHelper>();
            }
            return describeCache;
        }
        set;
    }

    /*
    * Costructs the Sobject describe based on the SObjectType token
    * Puts created describe in the cache map
    */
    private SObjectDescribeHelper(Schema.SObjectType token) {
        if (token == null) {
            throw new InvalidDescribeException('Invalid SObject type: null');
        }
        this.token = token;
        describeCache.put(String.valueOf(token).toLowerCase(), this);
    }

    /**
    * This method returns the raw data and provides no namespace handling
    * @return a Map<String, Schema.SObjectField> representing the describe fields
    */
    public Map<String, Schema.SObjectField> getFieldsMap() {
        return fields;
    }

    /**
    * This method returns the name of the Sobject, if exists, else returns null
    * @return a Schema.SObjectField token of the name field
    */
    public Schema.SObjectField getNameField() {
        return nameField;
    }

    /**
    * @return a Schema.SObjectField token of the SObject type
    */
    public Schema.SObjectType getSObjectType() {
        return token;
    }

    public List<Schema.ChildRelationship> getChildRelationships() {
        return this.getDescribe().getChildRelationships();
    }

    public Schema.ChildRelationship getChildRelationship(String relationshipName) {
        if (this.childRelationshipsCache.containsKey(relationshipName)) {
            return this.childRelationshipsCache.get(relationshipName);
        }

        for (Schema.ChildRelationship childRelationship : this.getChildRelationships()) {
            if (childRelationship.getRelationshipName().equalsIgnoreCase(relationshipName)) {
                this.childRelationshipsCache.put(relationshipName, childRelationship);
                return childRelationship;
            }
        }

        return null;
    }

    /**
    * @return Schema.DescribeSObjectResult, conatins methods for describing SObjects
    */
    public Schema.DescribeSObjectResult getDescribe() {
        return describe;
    }

    public static Schema.ChildRelationship getChildRelationship(Schema.SObjectType token, String relationshipName) {
        return getDescribe(token).getChildRelationship(relationshipName);
    }

    /**
    * This is used to cache SObjectDescribeHelper instances as they're consutrcted
    * to prevent repeatedly re-constructing the same type
    * These instances are not guaranteed to be, but typically will be, unique per sObject type due to the presence of flushCache
    * @param sObjectName a String object containing the SObject name to describe
    * @return SObjectDescribeHelper, wrapped SObject describe with useful methods
    */
    public static SObjectDescribeHelper getDescribe(String sObjectName) {
        if (String.isBlank(sObjectName)) {
            return null;
        }
        SObjectDescribeHelper result = describeCache.get(sObjectName.toLowerCase());
        if (result == null) {
            Schema.SObjectType token = ((SObject) (Type.forName(sObjectName.toLowerCase()))?.newInstance())?.getSObjectType();
            if (token != null) {
                result = new SObjectDescribeHelper(token);
            }
        }
        return result;
    }

    /**
    * Convinince of the {@link #getDescribe(String sObjectName)} for the SObject
    * @param instance a SObject object containing the SObject to describe
    */
    public static SObjectDescribeHelper getDescribe(SObject instance) {
        if (instance == null) {
            return null;
        }
        return getDescribe(instance.getSobjectType());
    }

    /**
    * Convinince of the {@link #getDescribe(String sObjectName)} for the Schema.SObjectType
    * @param instance a Schema.SObjectType object containing the Schema.SObjectType to describe
    */
    public static SObjectDescribeHelper getDescribe(Schema.SObjectType token) {
        if (token == null) {
            return null;
        }
        SObjectDescribeHelper result = describeCache.get(String.valueOf(token).toLowerCase());
        if (result == null) {
            result = new SObjectDescribeHelper(token);
        }

        return result;
    }
    /**
    * This method is a convenient shorthand for calling {@link #getDescribe(name, true)}
    * @param fieldName a String object containing the field name
    * @return Schema.SObjectField, field describe token.
    **/
    public Schema.SObjectField getField(String fieldName) {
        return this.getField(fieldName, true);
    }

    /**
    * This method provides a simplified shorthand for calling #getFields and getting the provided field.
    * Additionally it handles finding the correct SObjectField for relationship notation,
    * e.g. getting the Account field on Contact would fail without being referenced as AccountId - both work here.
    * @param fieldName a String object containing the field name
    * @param implyNamespace a Boolean object specifies that this is a SObject from the managed package
    * @return Schema.SObjectField, field describe token.
    **/
    public Schema.SObjectField getField(String fieldName, boolean implyNamespace) {
        Schema.SObjectField result = wrappedFields.get(
            (fieldName.endsWithIgnoreCase('__r') ? //resolve custom field cross-object (__r) syntax
            (fieldName.removeEndIgnoreCase('__r') + '__c') :
            fieldName),
            implyNamespace
        );
        if (result == null) {
            result = wrappedFields.get(fieldName + 'Id', implyNamespace); //in case it's a standard lookup in cross-object format
        }
        return result;
    }

    /**
     * Returns a list of unique fields on the SObject
     * @return Set<Schema.SObjectField>, list of unique fields on the SObject
     */
    public Set<Schema.SObjectField> getUniqueFields() {
        Set<Schema.SObjectField> result = new Set<Schema.SObjectField>();
        Map<String, SObjectField> f = this.getFieldsMap();
        for (String fieldName : f.keySet()) {
            SObjectField field = f.get(fieldName);
            DescribeFieldResult fieldDescribe = field.getDescribe();
            if (fieldDescribe.isUnique()) {
                result.add(field);
            }
        }
        return result;
    }

    /**
     * Returns a list of unique field names on the SObject
     * @return Set<String>, list of unique field names on the SObject
     */
    public Set<String> getUniqueFieldNames() {
        Set<String> result = new Set<String>();
        Set<Schema.SObjectField> uniqueFields = this.getUniqueFields();
        for (Schema.SObjectField field : uniqueFields) {
            result.add(field.getDescribe().getName());
        }
        return result;
    }

    /*
    * Due to the lack of language support for covariant return types sublasses are responsible for implementing the get methods.
    * A minimal implementation of these would be a cast and returning getObject's result.
    */
    private abstract class NamespacedAttributeMap {
        @testVisible
        protected String currentNamespace;
        protected Map<String, Object> values;

        protected NamespacedAttributeMap(Map<String, Object> values) {
            currentNamespace = SObjectDescribeHelper.class.getName().substringBefore('SObjectDescribeHelper').removeEnd('.').toLowerCase();
            this.values = values;
        }
        /* A no-args constructor to allow subclasses with different contructor signatures */
        protected NamespacedAttributeMap() {
            this(new Map<String, Object>());
        }
        /* A convenient shortcut for invoking #getObject(name, true) */
        protected virtual Object getObject(String name) {
            return this.getObject(name, true);
        }
        /* Convenience for the namespace */
        protected virtual Object getObject(String name, Boolean implyNamespace) {
            /* Short-circuit lookup logic since null can't possibly be a valid field name, and it saves us null checking */
            if (name == null) {
                return null;
            }
            String preferredValue = (
                (implyNamespace 
                ? currentNamespace + '__' 
                : '') + name).toLowerCase();
            if (values.containsKey(preferredValue)) {
                return values.get(preferredValue);
            } else if (implyNamespace) {
                return values.get(name.toLowerCase());
            } else {
                return null;
            }
        }

        public virtual Boolean containsKey(String name) {
            return this.containsKey(name, true);
        }

        public virtual Boolean containsKey(String name, Boolean implyNamespace) {
            /* Short-circuit lookup logic since null can't possibly be a valid field name, and it saves us null checking */
            if (name == null) {
                return null;
            }
            String preferredValue = ((implyNamespace ? currentNamespace + '__' : '') + name).toLowerCase();
            return (values.containsKey(preferredValue) || implyNamespace && values.containsKey(name.toLowerCase()));
        }

        public virtual Integer size() {
            return values.size();
        }

        /*
        * Returns the key set of the map.
        * Note: unlike other NamespacedAttributeMap methods keySet defaults implyNamespace to false if not specified.
        */
        public virtual Set<String> keySet() {
            return this.keySet(false);
        }

        public virtual Set<String> keySet(Boolean implyNamespace) {
            if (implyNamespace) {
                Set<String> result = new Set<String>();
                for(String key:values.keySet()) {
                    result.add(key.removeStartIgnoreCase(currentNamespace + '__'));
                }
                return result;
            } else {
                return values.keySet();
            }
        }
    }

    /* A subclass of NamespacedAttributeMap for handling the data returned by #Schema.DescribeSObjectResult.fields.getMap */
    public class FieldsMap extends NamespacedAttributeMap {
        @testVisible
        private FieldsMap(Map<String,Schema.SObjectField> values) {
            super(values);
        }
        public Schema.SObjectField get(String name) {
            return this.get(name, true);
        }
        public Schema.SObjectField get(String name, Boolean implyNamespace) {
            return (Schema.SObjectField) this.getObject(name, implyNamespace);
        }
        public List<Schema.SObjectField> values() {
            return (List<Schema.SObjectField>) values.values();
        }

    }

    public class InvalidDescribeException extends Exception {}
}