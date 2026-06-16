@isTest
private class TestSObjectBuilder {
    
    /**
    * Verify that SObjectBuilder set up a security, SObjectType, records and default mappings on creation.
    * By default security setting is set up to "true", you have to explictly specify "false"
    * if you need it during your unit test.
    */
    @isTest static void builderSetupDefaults() {
        SObjectBuilder builder = new SObjectBuilder(Contact.SObjectType);
        System.assert(builder.applySecurity);
        System.assert(builder.records.isEmpty());
        System.assert(builder.fieldToValue.isEmpty());
        System.assertEquals(builder.quantity, 1);
    }
    
    /**
    * Verify that SObjectBuilder can set up number of records.
    */
    @isTest static void builderCanSetupCount() {
        final Integer RECORDS_NUMBER = 5;
        SObjectBuilder builder = new SObjectBuilder(Contact.SObjectType)
                                     .quantity(RECORDS_NUMBER);
        System.assertEquals(builder.quantity, 5);
    }

    /**
    * Verify that SObjectBuilder can set a field mapping.
    */
    @isTest static void builderCanSetupField() {
        final String LAST_NAME_OVERRIDE = 'fmG17hzBJtLANR8=';
        SObjectField field = Contact.LastName;
        SObjectBuilder builder = new SObjectBuilder(Contact.SObjectType)
                                     .setField(field, LAST_NAME_OVERRIDE);
        System.assertEquals(builder.fieldToValue.get(field), LAST_NAME_OVERRIDE);
    }

    
    /**
    * Verify that SObjectBuilder can set a fields mappings.
    */
    @isTest static void builderCanSetupFields() {
        final String LAST_NAME_OVERRIDE = 'fmG17hzBJtLANR8=';
        SObjectField field = Contact.LastName;
        Map<SObjectField, Object> fields = new Map<SObjectField, Object> { Contact.LastName => LAST_NAME_OVERRIDE };
        SObjectBuilder builder = new SObjectBuilder(Contact.SObjectType)
                                     .setFields(fields);
        System.assertEquals(builder.fieldToValue.get(field), LAST_NAME_OVERRIDE);
    }

    /**
    * Verify that SObjectBuilder can build records in memory.
    */
    @isTest static void builderCanBuildRecords() {
        final Integer RECORDS_NUMBER = 5;
        SObjectBuilder builder = new SObjectBuilder(Contact.SObjectType)
                                     .quantity(RECORDS_NUMBER)
                                     .build();
        System.assertEquals(builder.getRecords().size(), RECORDS_NUMBER);
        System.assertEquals(builder.getRecord().get(Contact.Id), null);
    }

    /**
    * Verify that SObjectBuilder can create records and insert them into database.
    */
    @isTest static void builderCanCreateRecords() {
        final Integer RECORDS_NUMBER = 5;
        SObjectBuilder builder = new SObjectBuilder(Contact.SObjectType)
                                     .quantity(RECORDS_NUMBER)
                                     .create();
        System.assertEquals(builder.getRecords().size(), RECORDS_NUMBER);
        System.assertNotEquals(builder.getRecord().get(Contact.Id), null);
    }

    /**
    * Verify that SObjectBuilder can get specified records from its instance.
    */
    @isTest static void builderCanGetSpecifiedRecords() {
        final Integer RECORDS_NUMBER = 5;
        final Integer RECORD_INDEX = 1;
        SObjectBuilder builder = new SObjectBuilder(Contact.SObjectType)
                                     .quantity(RECORDS_NUMBER)
                                     .create();
        System.assertEquals(builder.getRecords().size(), RECORDS_NUMBER);
        System.assertEquals(builder.getRecord(), builder.getRecords()[0]);
        System.assertEquals(builder.getRecord(RECORD_INDEX), builder.getRecords()[RECORD_INDEX]);
    }

    /**
    * Verify that SObjectBuilder can create records as specified user.
    * We have to implement user default mapping and use it in this test. 
    * As it may differs for various projects, leave it as current user.
    */
    @isTest static void builderCanCreateRecordsAsUser() {
        SObjectField field = Contact.CreatedById;
        SObjectBuilder builder = new SObjectBuilder(Contact.SObjectType)
                                     .createAsUser([SELECT Id FROM User WHERE Id = :UserInfo.getUserId()]);
        Id recordId = (Id) builder.getRecord().get(Contact.Id);                             
        System.assertEquals([SELECT CreatedById FROM Contact WHERE Id = :recordId].CreatedById, UserInfo.getUserId());
    }
}