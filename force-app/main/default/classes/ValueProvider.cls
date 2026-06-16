public with sharing class ValueProvider {
    public class RandomDecimalProvider implements IValueProvider {
        Decimal min {
            get {
                if (this.min == null) {
                    this.min = 0;
                }
                return this.min;
            }
            set {
                Decimal rangeMin = (Decimal) NumberHelper.getNumberNullSafe(value);
                Decimal rangeMax = (Decimal) NumberHelper.getNumberNullSafe(this.max);

                if (rangeMin > rangeMax) {
                    rangeMin = rangeMax;
                    this.max = rangeMin;
                }

                this.min = rangeMin;
            }
        }
        Decimal max {
            get {
                if (this.max == null) {
                    this.max = 1;
                }
                return this.max;
            }
            set {
                Decimal rangeMin = (Decimal) NumberHelper.getNumberNullSafe(this.min);
                Decimal rangeMax = (Decimal) NumberHelper.getNumberNullSafe(value);

                if (rangeMin > rangeMax) {
                    rangeMax = rangeMin;
                    this.min = rangeMax;
                }

                this.max = rangeMax;
            }
        }

        Integer scale = 2;

        /* Constructs the provider for random number from range 0-1 and scale 2. */
        public RandomDecimalProvider() {
            this(0, 1, 2);
        }

        /**
        * @param min a Decimal representing the minimum value of the provided value.
        * @param max a Decimal representing the maximum value of the provided value.
        * @param scale an Integer representing the scale of the provided value.
        */
        public RandomDecimalProvider(Decimal min, Decimal max, Integer scale) {
            this.max = max;
            this.min = min;
            this.scale = scale;
        }

        /**
        * @return Random decimal number of given scale within given range boundaries.
        */
        public Object getValue() {
            return (Math.random() * (max - min) + min).setScale(scale);
        }
    }

    /** Constructs data primitives objects.
    * https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/langCon_apex_primitives.htm
    * Used in the in the {@link SObjectFactory} for the default values.
    */

    /**
    * Uniquie integer number provider. Adds +1 to the next record.
    */
    public class UniqueNumberProvider implements IValueProvider {
        Integer counter;

        /* Sets the start number to 0. */
        public UniqueNumberProvider() {
            this(0);
        }

        /**
        * Convinience to set up the number from the desired position.
        * @param start a Integer representing the start for the counter.
        */
        public UniqueNumberProvider(Integer start) {
            this.counter = start;
        }

        /**
        * @return Number different from previous number on the counter value.
        */
        public Object getValue() {
            return counter++;
        }
    }

    /**
    * Uniquie decimal number provider. Adds +1 to the next record.
    */
    public class UniqueDecimalProvider implements IValueProvider {
        Decimal counter;
        Integer scale;

        /* Sets the start decimal to 0. */
        public UniqueDecimalProvider() {
            this(0, 2);
        }

        /**
        * Convinience to set up the decimal with desired scale.
        * @param scale an Integer representing the scale of the provided value.
        */
        public UniqueDecimalProvider(Integer scale) {
            this(0, scale);
        }

        /**
        * Convinience to set up the decimal from the desired position and scale.
        * @param scale an Integer representing the scale of the provided value.
        * @param start an Integer representing the start for the counter.
        */
        public UniqueDecimalProvider(Decimal start, Integer scale) {
            this.scale = scale;
            this.counter = start;
        }

        /**
        * @return Number different from previous decimal on the counter value.
        */
        public Object getValue() {
            return (counter++).setScale(scale);
        }
    }

    /**
    * Uniquie date provider. Adds +1 day to the next date.
    */
    public class UniqueDateProvider implements IValueProvider {
        final Date startDate;
        Integer counter;

        /* Sets the start date to todays date. */
        public UniqueDateProvider() {
            this(Date.today());
        }

        /**
        * Convinience to set up the date from the desired value.
        * @param startDate a Date representing the start for the counter.
        */
        public UniqueDateProvider(Date startDate) {
            this.counter = 0;
            this.startDate = startDate;
        }

        /**
        * @return Date different from previous date on the counter value.
        */
        public Object getValue() {
            return startDate.addDays(counter++);
        }
    }

    /**
    * Uniquie Datetime provider. Adds +1 day to the next Datetime.
    */
    public class UniqueDatetimeProvider implements IValueProvider {
        final Datetime startDatetime;
        Integer counter;

        /* Sets the start datetime current Datetime based on a GMT calendar. */
        public UniqueDatetimeProvider() {
            this(Datetime.now());
        }

        /**
        * Convinience to set up the datetime from the desired value.
        * @param startDate a Date representing the start for the counter.
        */
        public UniqueDatetimeProvider(Datetime startDatetime) {
            this.counter = 0;
            this.startDatetime = startDatetime;
        }

        /**
        * @return Datetime different from previous datetime on the counter value.
        */
        public Object getValue() {
            return startDatetime.addDays(counter++);
        }
    }

    /**
    * Uniquie Time provider. Adds +1 hour to the next Time.
    */
    public class UniqueTimeProvider implements IValueProvider {
        final Time startTime;
        Integer counter;

        /* Sets the start time to the current time based on a GMT calendar. */
        public UniqueTimeProvider() {
            this(Datetime.now().timeGMT());
        }

        /**
        * Convinience to set up the time from the desired value.
        * @param startDate a Date representing the start for the counter.
        */
        public UniqueTimeProvider(Time startTime) {
            this.counter = 0;
            this.startTime = startTime;
        }

        /**
        * @return Datetime different from previous datetime on the counter value.
        */
        public Object getValue() {
            return startTime.addHours(counter++);
        }
    }

    /**
    * Uniquie string provider. Adds +1 string value to the next string.
    */
    public class UniqueStringProvider implements IValueProvider {
        final String base;
        Integer counter;

        /* Sets the start string to the counter value. */
        public UniqueStringProvider() {
            this('');
        }

        /**
        * Convinience to set up the string with the desired base value.
        * @param base a String representing the base for the counter.
        */
        public UniqueStringProvider(String base) {
            this.counter = 0;
            this.base = base;
        }

        /**
        * @return String different from previous string on the counter value.
        */
        public Object getValue() {
            return base + counter++;
        }
    }

    /**
    * Uniquie blob provider. Adds +1 String value to the next string.
    */
    public class UniqueBlobProvider implements IValueProvider {
        final String base;
        Integer counter;

        /* Sets the start blob to the counter value. */
        public UniqueBlobProvider() {
            this('');
        }

        /**
        * Convinience to set up the blob with the desired base body value.
        * @param base a String representing the base body for the counter.
        */
        public UniqueBlobProvider(String base) {
            this.counter = 0;
            this.base = base;
        }

        /**
        * @return Blob different from previous blob on the counter value.
        */
        public Object getValue() {
            return Blob.ValueOf(base + counter++);
        }
    }

    /**
    * Uniquie email provider. Adds +1 String value to the next string.
    */
    public class UniqueEmailProvider implements IValueProvider {
        final String base;
        final String domain;
        Integer counter;

        /* Sets the start email to the counter value. */
        public UniqueEmailProvider() {
            this('');
        }

        /**
        * Convinience to set up the email with the desired base and domain start part of email value.
        * @param base a String representing the base part of email for the counter.
        */
        public UniqueEmailProvider(String base) {
            this(base, '');
        }

        /**
        * Convinience to set up the email with the desired base and domain of email value.
        * @param base a String representing the base part of email for the counter.
        * @param domain a String representing the domain part of email for the counter.
        */
        public UniqueEmailProvider(String base, String domain) {
            this.counter = 0;
            this.base = String.isNotBlank(base) ? base : 'rc_' + String.valueOf(DateTime.now().getTime());
            this.domain = String.isNotBlank(domain) ? domain : '@rcmockDomain.com';
        }

        /**
        * @return Blob different from previous blob on the counter value.
        */
        public Object getValue() {
            return String.valueOf(base + (counter++) + domain);
        }
    }

    /** Construct complex data objects. */
    public class CountException extends Exception { }
    public class EmptyQueryException extends Exception { }

    /**
    * Uniquie fixed length string provider. Adds 0 String value until fixed length will be achived.
    */
    public virtual class UniqueFixedLengthStringProvider implements IValueProvider {
        final String base;
        final Integer remainingLength;
        Integer counter;

        /**
        * Sets up the string to the desired lenght.
        * @param length an Integer representing the length of the string.
        */
        public UniqueFixedLengthStringProvider(Integer length) {
            this('', length);
        }

        /**
        * Convinience to set up the string with the desired base value.
        * @param base a String representing the base body for the counter.
        */
        public UniqueFixedLengthStringProvider(String base, Integer length) {
            this.base = base;
            this.remainingLength = length - base.length();
            this.counter = 0;
        }

        /**
        * @return Uniquie fixed length string. Remaining length will be replaced with the 0.
        * @throws CountException if the base string is bigger that length.
        */
        public Object getValue() {
            String counterValue = String.valueOf(counter++);
            Integer counterLength = counterValue.length();
            if (counterLength < remainingLength) {
                counterValue = counterValue.leftPad(remainingLength).replace(' ', '0');
            } else if (counterLength > remainingLength) {
                throw new CountException('Too many fixed length strings.');
            }
            return base + counterValue;
        }
    }

    /**
    * Uniquie Id provider. Consider to use when you dont need to create an SObject and just need a stub for the Id.
    */
    public class DummyIdProvider extends UniqueFixedLengthStringProvider implements IValueProvider {

        /**
        * Convinience foe the the concrete SObject.
        * @param prefix a String representing the SObject for which dummy id is created.
        * Prefix will be applied as the base value.
        * @param length an Integer representing the dummy Id length.
        */
        public DummyIdProvider(String prefix, Integer length) {
            super(prefix, length);
        }

        /**
        * Convinience foe the the concrete SObject.
        * @param sObjectType a SObjectToken representing the SObject for which dummy id is created.
        * Prefix will be applied as the base value.
        */
        public DummyIdProvider(SObjectType sObjectType) {
            this(sObjectType, 18);
        }

        /**
        * Convinience for the the concrete SObject with the desired lenght.
        * Consider to use when you need 15 character Id.
        * @param sObjectType a SObjectToken representing the SObject for which dummy id is created.
        * Prefix will be applied as the base value.
        * @param length an Integer representing the dummy Id length.
        */
        public DummyIdProvider(SObjectType sObjectType, Integer length) {
            this(sObjectType.getDescribe().getKeyPrefix(), length);
        }
    }

    /**
    * Generic Object provider from the specified collection List<Object>, consider to use when you need different values
    * in each of the created records.
    */
    public virtual class ListProvider implements IValueProvider {
        final Integer size;
        final List<Object> values;
        Integer index;

        /**
        * Provides a values from the collection for the created records.
        * Values could be different for all of the records created.
        * @param values a List<Object> representing an ordered field values.
        */
        public ListProvider(List<Object> values) {
            this.values = values;
            this.size = values.size();
            this.index = 0;
        }

        /**
        * @return Field value for the created record.
        */
        public Object getValue() {
            Object value = values[index];
            index = Math.mod(index + 1, size);
            return value;
        }
    }

    /**
    * Generic Id provider based on the specified SObject, consider to use when you need,
    * a simple logic to create a parent or you need a default mapping to do that.
    */
    public class MultiParentProvider extends ListProvider implements IValueProvider {
        /**
        * Provides parent Id for the created records. Parent Id could be different for all of the records created.
        * @param parentIds a Set<Id> representing parents for the created objects.
        */
        public MultiParentProvider(Set<Id> parentIds) {
            super(new List<Id>(parentIds));
        }
        /**
        * Provides parent Id for the created records. Parent Id could be different for all of the records created.
        * @param parents a List<SObject> representing parents for the created objects.
        */
        public MultiParentProvider(List<SObject> parents) {
            this(getParentsIds(parents));
        }
    }

    /**
    * Generic Id provider based on the specified SObject, consider to use when you need,
    * a simple logic to create a parent or you need a default mapping to do that.
    */
    public class GenericParentProvider implements IValueProvider {
        final SObjectBuilder builder;
        Id genericParentId;

        /**
        * Provides parent Id for the created records. Parent Id will be the same for all of the records created.
        * @param sObjectType a SObjectType token representing a type of the parent.
        */
        public GenericParentProvider(SObjectType sObjectType) {
            this.builder = new SObjectBuilder(sObjectType);
        }

        /**
        * Provides parent Id for the created records. Parent Id will be the same for all of the records created.
        * @param  sObjectType a SObjectType token representing a type of the parent.
        * @param  field a SObjectField reprsenting field added to the parent mapping.
        * @param  value a Object reprsenting field value added to the parent mapping.
        */
        public GenericParentProvider(SObjectType sObjectType, SObjectField field, Object value) {
            this.builder = new SObjectBuilder(sObjectType).setField(field, value);
        }

        /**
        * Provides parent Id for the created records. Parent Id will be the same for all of the records created.
        * @param  sObjectType a SObjectType token representing a type of the parent.
        * @param  fieldToValue a Map<SObjectField, Object> reprsenting fields and values added to the parent mapping.
        */
        public GenericParentProvider(SObjectType sObjectType, Map<SObjectField, Object> fieldToValue) {
            this.builder = new SObjectBuilder(sObjectType);
            if (fieldToValue != null) {
                this.builder.setFields(fieldToValue);
            }
        }

        /**
        * @return Id of the parent, same for all the created records.
        */
        public Object getValue() {
            if (genericParentId == null) {
                genericParentId = builder.create().getRecord().Id;
            }
            return genericParentId;
        }
    }

    /**
    * Generic Id provider based on the specified query, consider to use when you need a complex logic to specify
    * the parent.
    */
    public class QueryParentProvider implements IValueProvider {
        final String query;
        Id queriedParentId;

        /**
        * Provides parent Id for the created records.
        * @param query a string representing the executed query.
        */
        public QueryParentProvider(String query) {
            this.query = String.escapeSingleQuotes(query);
        }

        /**
        * Provides parent Id for the created records.
        * @param sObjectType an SObject token to build a simple query for the record.
        */
        public QueryParentProvider(SObjectType sObjectType) {
            this.query = 'SELECT Id FROM ' + String.escapeSingleQuotes(String.valueOf(sObjectType)) + ' LIMIT 1';
        }

        /**
        * @return Id of the parent, same for all the created records.
        * @throws EmptyQueryException if the record is not found.
        */
        public Object getValue() {
            if (queriedParentId == null) {
                List<SObject> candidates = Database.query(query);
                if (candidates.isEmpty()) {
                    throw new EmptyQueryException();
                }
                queriedParentId = candidates[0].Id;
            }
            return queriedParentId;
        }
    }

    /**
    * Provides parent Id for the created records.
    * @param  records a List<SObject>, collection from which we need to obtain the Ids.
    * @return Ids of the provided records.
    */
    private static Set<Id> getParentsIds(List<SObject> records) {
        Map<Id, SObject> recordMap = new Map<Id, SObject>();
        recordMap.putAll(records);
        return recordMap.keySet();
    }
}