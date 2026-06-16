public with sharing class ValueProviderBuilder {
    /**
     * @return ValueProvider.RandomDecimalProvider
     */
    public static IValueProvider providerRandomDecimal(
        Decimal min,
        Decimal max,
        Integer scale
    ) {
        return new ValueProvider.RandomDecimalProvider(min, max, scale);
    }

    /**
    * Provides unique number for the created records.
    * @return unique number.
    */
    public static IValueProvider provideUniqueNumber() {
        return new ValueProvider.UniqueNumberProvider();
    }

    /**
    * Provides unique number for the created records.
    * @param  start a start number from which numbers start to generate.
    * @return unique number.
    */
    public static IValueProvider provideUniqueNumber(Integer start) {
        return new ValueProvider.UniqueNumberProvider(start);
    }

    /**
    * Provides unique number for the created records.
    * @return unique number.
    */
    public static IValueProvider provideUniqueDecimal() {
        return new ValueProvider.UniqueDecimalProvider();
    }

    /**
    * Provides unique number for the created records.
    * @param  scale a start number from which numbers start to generate.
    * @return unique number.
    */
    public static IValueProvider provideUniqueDecimal(Integer scale) {
        return new ValueProvider.UniqueDecimalProvider(scale);
    }

    /**
    * Provides unique number for the created records.
    * @param scale an Integer representing the scale of the provided value.
    * @param start a Integer representing the start for the counter.
    * @return unique number
    */
    public static IValueProvider provideUniqueDecimal(Decimal start, Integer scale) {
        return new ValueProvider.UniqueDecimalProvider(start, scale);
    }

    /**
    * Provides unique Date for the created records.
    * @return unique Date
    */
    public static IValueProvider provideUniqueDate() {
        return new ValueProvider.UniqueDateProvider();
    }

    /**
    * Provides unique Date for the created records.
    * @param startDate a Date representing the start for the counter.
    * @return unique Date
    */
    public static IValueProvider provideUniqueDate(Date startDate) {
        return new ValueProvider.UniqueDateProvider(startDate);
    }

    /**
    * Provides unique Datetime for the created records.
    * @return unique Datetime
    */
    public static IValueProvider provideUniqueDatetime() {
        return new ValueProvider.UniqueDatetimeProvider();
    }

    /**
    * Provides unique Datetime for the created records.
    * @param startDatetime a Datetime representing the start for the counter.
    * @return unique Datetime
    */
    public static IValueProvider provideUniqueDatetime(Datetime startDatetime) {
        return new ValueProvider.UniqueDatetimeProvider(startDatetime);
    }

    /**
    * Provides unique Time for the created records.
    * @return unique Time
    */
    public static IValueProvider provideUniqueTime() {
        return new ValueProvider.UniqueTimeProvider();
    }

    /**
    * Provides unique Time for the created records.
    * @param  startTime a Time representing the start for the counter.
    * @return unique Time
    */
    public static IValueProvider provideUniqueTime(Time startTime) {
        return new ValueProvider.UniqueTimeProvider(startTime);
    }

    /**
    * Provides unique String for the created records.
    * @return unique String
    */
    public static IValueProvider provideUniqueString() {
        return new ValueProvider.UniqueStringProvider();
    }

    /**
    * Provides unique String for the created records.
    * @param  base a String representing the base for the counter.
    * @return unique String
    */
    public static IValueProvider provideUniqueString(String base) {
        return new ValueProvider.UniqueStringProvider(base);
    }

    /**
    * Provides unique Blob for the created records.
    * @return unique Blob.
    */
    public static IValueProvider provideUniqueBlob() {
        return new ValueProvider.UniqueBlobProvider();
    }

    /**
    * Provides unique Email.
    * @return unique Email.
    */
    public static IValueProvider provideUniqueEmail() {
        return new ValueProvider.UniqueEmailProvider();
    }

    /**
    * Provides unique Email.
    * @param  base a String representing the base for the counter.
    * @return unique Email.
    */
    public static IValueProvider provideUniqueEmail(String base) {
        return new ValueProvider.UniqueEmailProvider(base);
    }

    /**
    * Provides unique Email.
    * @param  base a String representing the base for the counter.
    * @param  domain a String representing the base for the counter.
    * @return unique Email.
    */
    public static IValueProvider provideUniqueEmail(String base, String domain) {
        return new ValueProvider.UniqueEmailProvider(base, domain);
    }

    /**
    * Provides unique Blob for the created records.
    * @param  base a Blob representing the base for the counter.
    * @return unique Blob.
    */
    public static IValueProvider provideUniqueBlob(String base) {
        return new ValueProvider.UniqueBlobProvider(base);
    }

    /**
    * Provides fixed length String provider. Adds 0 String value until fixed length will be achived.
    * @param  length an Integer representing the length of the string.
    * @return unique fixed length String.
    */
    public static IValueProvider provideUniqueFixedLengthString(Integer length) {
        return new ValueProvider.UniqueFixedLengthStringProvider(length);
    }

    /**
    * Provides fixed length string provider. Adds 0 String value until fixed length will be achived.
    * @param  base a String representing the base bofy for the counter.
    * @param  length an Integer representing the length of the string.
    * @return unique fixed length String.
    */
    public static IValueProvider provideUniqueFixedLengthString(String base, Integer length) {
        return new ValueProvider.UniqueFixedLengthStringProvider(base, length);
    }

    /**
    * Dummy Id provider. Consider to use when you dont need to create an SObject and just need a stub for the Id.
    * @param sObjectType a SObjectToken representing the SObject for which dummy id is created.
    * @return A dummy Id for the specified SObjectType. Format {SObjectPrefix} - 15 '0' characters.
    */
    public static IValueProvider provideDummyId(SObjectType sObjectType) {
        return new ValueProvider.DummyIdProvider(sObjectType);
    }

    /**
    * Dummy Id provider. Consider to use when you dont need to create an SObject and just need a stub for the Id.
    * @param sObjectType a SObjectToken representing the SObject for which dummy id is created.
    * @param length an Integer representing the dummy Id length.
    * @return A dummy Id for the specified SObjectType. Format {SObjectPrefix} - 15 '0' characters.
    */
    public static IValueProvider provideDummyId(SObjectType sObjectType, Integer length) {
        return new ValueProvider.DummyIdProvider(sObjectType, length);
    }

    /**
    * Generic Object provider from the specified collection List<Object>, consider to use when you need different values
    * in each of the created records.
    * @param  values a List<Object> representing an ordered field values.
    * @return List values for the created records.
    */
    public static IValueProvider provideList(List<Object> values) {
        return new ValueProvider.ListProvider(values);
    }

    /**
    * Generic Id provider based on the specified SObject, consider to use when you need,
    * a simple logic to create a parent or you need a default mapping to do that.
    * @param sObjectType a Schema.SObjectType token used to get the default mapping.
    * @param quantity a Integer reprsenting the number of records created by the factory.
    * @param applySecurity a Boolean used for specify if the factory should check for CRUD and FLS.
    * @return Provides parent Id for the created records. Parent Id could be different for all of the records created.
    */
    public static IValueProvider provideParents(SObjectType sObjectType, Integer quantity, Boolean applySecurity) {
        return new ValueProvider.MultiParentProvider(new SObjectFactory(applySecurity).create(sObjectType, quantity));
    }

    /**
    * Generic Id provider based on the specified SObject, consider to use when you need,
    * a simple logic to create a parent or you need a default mapping to do that.
    * @param parents a List<SObject> representing parents for the created objects.
    * @return Provides parent Id for the created records. Parent Id could be different for all of the records created.
    */
    public static IValueProvider provideParents(List<SObject> parents) {
        return new ValueProvider.MultiParentProvider(parents);
    }

    /**
    * Generic Id provider based on the specified SObject, consider to use when you need,
    * a simple logic to create a parent or you need a default mapping to do that.
    * @param parentIds a Set<Id> representing parents for the created objects.
    * @return Provides parent Id for the created records. Parent Id could be different for all of the records created.
    */
    public static IValueProvider provideParents(Set<Id> parentIds) {
        return new ValueProvider.MultiParentProvider(parentIds);
    }

    /**
    * Generic Id provider based on the specified SObject, consider to use when you need,
    * a simple logic to create a parent or you need a default mapping to do that.
    * @param  sObjectType a SObjectType token representing a type of the parent.
    * @return Id of the parent, same for all the created records.
    */
    public static IValueProvider provideGenericParent(SObjectType sObjectType) {
        return new ValueProvider.GenericParentProvider(sObjectType);
    }

    /**
    * Generic Id provider based on the specified SObject, consider to use when you need,
    * a simple logic to create a parent or you need a default mapping to do that.
    * @param  sObjectType a SObjectType token representing a type of the parent.
    * @param  field a SObjectField reprsenting field added to the parent mapping.
    * @param  value a Object reprsenting field value added to the parent mapping.
    * @return Id of the parent, same for all the created records.
    */
    public static IValueProvider provideGenericParent(SObjectType sObjectType, SObjectField field, Object value) {
        return new ValueProvider.GenericParentProvider(sObjectType, field, value);
    }

    /**
    * Generic Id provider based on the specified SObject, consider to use when you need,
    * a simple logic to create a parent or you need a default mapping to do that.
    * @param  sObjectType a SObjectType token representing a type of the parent.
    * @param  fieldToValue a Map<SObjectField, Object> reprsenting fields and values added to the parent mapping.
    * @return Id of the parent, same for all the created records.
    */
    public static IValueProvider provideGenericParent(SObjectType sObjectType, Map<SObjectField, Object> fieldToValue) {
        return new ValueProvider.GenericParentProvider(sObjectType, fieldToValue);
    }

    /**
    * The Map<SObjectType, IValueProvider> used to not recreate generic parents in the single context.
    */
    private static Map<SObjectType, IValueProvider> genericParentProviders = new Map<SObjectType, IValueProvider>();

    /**
    * Provides generic parents for the created records. The parent is single for all.
    * @param sObjectType a Schema.SObjectType token used for building the records in the {@link SObjectFactory}.
    * @return IValueProvider with the existing parents.
    */
    public static IValueProvider provideCommonParent(SObjectType sObjectType) {
        return provideCommonParent(sObjectType, null);
    }

    /**
    * Provides generic parents for the created records. The parent is single for all.
    * @param sObjectType a Schema.SObjectType token used for building the records in the {@link SObjectFactory}.
    * @param  fieldToValue a Map<SObjectField, Object> reprsenting fields and values added to the parent mapping.
    * @return IValueProvider with the existing parents.
    */
    public static IValueProvider provideCommonParent(SObjectType sObjectType, Map<SObjectField, Object> fieldToValue) {
        if (!genericParentProviders.containsKey(sObjectType)) {
            genericParentProviders.put(sObjectType, provideGenericParent(sObjectType, fieldToValue));
        }
        return genericParentProviders.get(sObjectType);
    }

    /**
    * Generic Id provider based on the specified query, consider to use when you need a complex logic to specify
    * the parent.
    * @param query a string representing the executed query.
    * @return Id of the parent, same for all the created records.
    */
    public static IValueProvider provideQueriedParent(String query) {
        return new ValueProvider.QueryParentProvider(query);
    }

    /**
    * Generic Id provider based on the specified query, consider to use when you need a complex logic to specify
    * the parent.
    * @param sObjectType an SObject token to build a simple query for the record.
    * @return Id of the parent, same for all the created records.
    */
    public static IValueProvider provideQueriedParent(SObjectType sObjectType) {
        return new ValueProvider.QueryParentProvider(sObjectType);
    }

}