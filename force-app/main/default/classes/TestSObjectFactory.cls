@isTest
private class TestSObjectFactory {
    /** 
    * Verify that SObjectFactory set up a security settings in the class constructor.
    * By default security setting is set up to "true", you have to explictly specify "false"
    * if you need it during your unit test.  
    */
    @isTest static void factorySetupSecurity() {
        SObjectFactory secureFactory = new SObjectFactory();
        System.assert(secureFactory.applySecurity);
        SObjectFactory nonSecureFactory = new SObjectFactory(false);
        System.assert(!nonSecureFactory.applySecurity);
    }
    
    /** 
    * Verify that SObjectFactory can build a record according to the required type.
    * Verify that the record is only created in the memory. Verify the fields.
    */
    @isTest static void factoryCanBuildRecord() {
        SObjectFactory factory = new SObjectFactory();
        SObject record = factory.build(Contact.SObjectType);
        System.assertEquals(record.getSObjectType(), Contact.SObjectType);
        System.assert(String.isEmpty(record.Id));
        verifySObjectsFieldDefaults(record);
    }

    /** 
    * Verify that SObjectFactory can build a record according to the required type 
    * and map of manually defined record fields to be populated.
    * Verify that the record is created with user-defined fields.
    */
    @isTest static void factoryCanBuildRecordWithManuallyDefinedFieldsMap() {
        SObjectFactory factory = new SObjectFactory();
        SObject record = factory.build(
            Opportunity.SObjectType,
            new Map<SObjectField, Object> {
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_DOWNGRADED
            }
        );
        System.assertEquals(record.getSObjectType(), Opportunity.SObjectType);
        System.assertEquals(OpportunityHelper.STAGE_NAME_DOWNGRADED, record.get('StageName'));
    }

    /** 
    * Verify that SObjectFactory can build a records according to the required type.
    * Verify that the size of created recods corresponds to required number. 
    */
    @isTest static void factoryCanBuildRecords() {
        final Integer RECORDS_NUMBER = 5; 
        SObjectFactory factory = new SObjectFactory();
        List<SObject> records = factory.build(Contact.SObjectType, RECORDS_NUMBER);
        System.assertEquals(records.size(), RECORDS_NUMBER);
        System.assertEquals(records[0].getSObjectType(), Contact.SObjectType);
        verifySObjectsFieldDefaults(records);
    }

    /** 
    * Verify that SObjectFactory can build a record and override default fields.
    * Verify that the specified field has correct value.
    */
    @isTest static void factoryCanBuildRecordAndSetUpField() {
        final String FIRST_NAME_OVERRIDE = 'Y2Cm8wDePtLY';
        SObjectFactory factory = new SObjectFactory();
        SObjectField field = Contact.FirstName;
        SObject record = factory.build(Contact.SObjectType, field, FIRST_NAME_OVERRIDE);
        System.assertEquals(record.get(field), FIRST_NAME_OVERRIDE);
    }

    /** 
    * Verify that SObjectFactory can create a record according to the required type.
    * Verify that the record is inserted in the database. Verify the fields.
    */
    @isTest static void factoryCanCreateRecord() {
        SObjectFactory factory = new SObjectFactory();
        SObject record = factory.create(Contact.SObjectType);
        System.assertEquals(record.getSObjectType(), Contact.SObjectType);
        System.assert(!String.isEmpty(record.Id));
        verifySObjectsFieldDefaults(record);
    }

    /** 
    * Verify that SObjectFactory can create a record according to the required type 
    * and map of manually defined record fields to be populated.
    * Verify that the record is inserted in the database with user-defined fields.
    */
    @isTest static void factoryCanCreateRecordWithManuallyDefinedFieldsMap() {
        SObjectFactory factory = new SObjectFactory();
        SObject record = factory.create(
            Opportunity.SObjectType,
            new Map<SObjectField, Object> {
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_DOWNGRADED,
                Opportunity.Downgrade_Reason_Opp__c => 'Test'
            }
        );
        System.assertEquals(record.getSObjectType(), Opportunity.SObjectType);
        System.assert(String.isNotEmpty(record.Id));
        System.assertEquals(OpportunityHelper.STAGE_NAME_DOWNGRADED, record.get('StageName'));
        System.assertEquals('Test', record.get('Downgrade_Reason_Opp__c'));
    }

    /** 
    * Verify that SObjectFactory can create a records according to the required type.
    * Verify that the size of created recods corresponds to required number. 
    */
    @isTest static void factoryCanCreateRecords() {
        final Integer RECORDS_NUMBER = 5; 
        SObjectFactory factory = new SObjectFactory();
        List<SObject> records = factory.create(Contact.SObjectType, RECORDS_NUMBER);
        System.assertEquals(records.size(), RECORDS_NUMBER);
        System.assertEquals(records[0].getSObjectType(), Contact.SObjectType);
        verifySObjectsFieldDefaults(records);
    }

    /** 
    * Verify that SObjectFactory can create a record and override default fields.
    * Verify that the specified field has correct value.
    */
    @isTest static void factoryCanCreateRecordsAndSetUpField() {
        final String LAST_NAME_OVERRIDE = 'Y3y1+AvMOdzY';
        SObjectFactory factory = new SObjectFactory();
        SObjectField field = Contact.FirstName;
        SObject record = factory.create(Contact.SObjectType, field, LAST_NAME_OVERRIDE);
        System.assertEquals(record.get(field), LAST_NAME_OVERRIDE);
    }

    /** 
    * Verify that SObjectFactory can build a records and override default values.
    * Apex class could not be inserted with the dml operation.
    */
    @isTest static void factoryThrowTheExceptionWhenSObjectIsNotCreateable() {
        SObjectFactory factory = new SObjectFactory();
        SObjectType type = ApexClass.SObjectType;
        SObjectFactory.SObjectFactoryDmlException factoryDmlException;
        try {
            SObject record = factory.create(type);
        } catch (SObjectFactory.SObjectFactoryDmlException ex) {
            factoryDmlException = ex;
        }
        System.assert(!String.isEmpty(factoryDmlException.dmlOperation));
        System.assert(!String.isEmpty(factoryDmlException.getMessage()));
        System.assertEquals(factoryDmlException.sObjectType, type);
    }

    /**
    * Using the default mappings that are set up in the {@link SObjectFactoryFieldDefaults}.
    * Verify the fields in the safe way as it could be changed.
    */
    private static void verifySObjectsFieldDefaults(SObject record) {
        verifySObjectsFieldDefaults(new List<SObject>{ record });
    }
    
    /**
    * Convenience for the list of records.
    */ 
    private static void verifySObjectsFieldDefaults(List<SObject> records) {
        Map<SObjectField, Object> fieldDefaults = SObjectFactoryFieldDefaults.getDefaults(records[0].getSObjectType());
        for (SObject record : records) {
            for (SObjectField field : fieldDefaults.keySet()) {
                Object value = fieldDefaults.get(field);
                if (value instanceof IValueProvider) {
                    value = ((IValueProvider)value).getValue();
                }
                System.assertEquals(record.get(field), value);
            }
        }    
    }
}