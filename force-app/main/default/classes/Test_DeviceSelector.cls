@isTest
private class Test_DeviceSelector {
    private static final String CASE_TYPE = 'VoIP Device Back Order';
    private static final String CASE_SUBJECT = 'testSubject';

    private static final String DEVICE_SERIAL_NUMBER = '123';
    private static final String DEVICE_TYPE = 'IP';
    private static final String DEVICE_INSTANCE_ID = '1234gh456';
    private static final String DEVICE_STATUS = 'Deployed';
    private static final String DEVICE_CONNECTION_ID_OF_PARTNER = 'TELUSID';
    
    private static final String ERROR_MESSAGE_FIELD_IS_NOT_RETURNER_CORRECT = 'field is not returned correct';
    private static final String ERROR_MESSAGE_SHOULD_BE_EXCEPTION = 'Should throw an SObjectException';
    private static final String ERROR_MESSAGE_SOBJECT_EXCEPTION =
        'SObject row was retrieved via SOQL without querying the requested field: ';
    private static final String ERROR_MESSAGE_SHOULD_BE_DIFFERENT_EXCEPTION_MESSAGE =
        'Error message should be different';
    
    @testSetup
    private static void createTestData() {
        Case testCase = (Case) new SObjectBuilder(Case.SObjectType)
            .setField(Case.RecordTypeId, CaseHelper.RT_ID_PORTING_OUT)
            .setField(Case.Type, CASE_TYPE)
            .setField(Case.Subject, ValueProviderBuilder.provideUniqueString(CASE_SUBJECT))
            .create()
            .getRecord();
        
        new SObjectBuilder(Device__c.SObjectType)
            .setField(Device__c.Serial_Number__c, DEVICE_SERIAL_NUMBER)
            .setField(Device__c.Device_Type__c, DEVICE_TYPE)
            .setField(Device__c.Instance_ID__c, DEVICE_INSTANCE_ID)
            .setField(Device__c.Case__c, testCase.Id)
            .setField(Device__c.Local_Parent_Id__c, testCase.Id)
            .setField(Device__c.Status__c, DEVICE_STATUS)
            .setField(Device__c.ConnectionIdOfPartner__c, DEVICE_CONNECTION_ID_OF_PARTNER)
            .create();
    }
    
   @isTest
   private static void testSelectDevicesByCaseReturnDefaultFieldList() {
        Case testCase = (Case) new CaseSelector(false, false)
           .selectCasesDefault().executeQuery()[0];

        List<Object> bindings = new List<Object>();
        bindings.add(testCase.Id);
        List<Device__c> deviceList = (List<Device__c>) new DeviceSelector(false, false)
            .selectDevicesByCase(bindings).executeQuery();
       
        System.assertEquals(DEVICE_SERIAL_NUMBER, deviceList[0].Serial_Number__c,
            'Serial_Number__c ' + ERROR_MESSAGE_FIELD_IS_NOT_RETURNER_CORRECT);
        System.assertEquals(DEVICE_TYPE, deviceList[0].Device_Type__c,
            'Device_Type__c ' + ERROR_MESSAGE_FIELD_IS_NOT_RETURNER_CORRECT);
        System.assertEquals(DEVICE_INSTANCE_ID, deviceList[0].Instance_ID__c,
            'Instance_ID__c ' + ERROR_MESSAGE_FIELD_IS_NOT_RETURNER_CORRECT);
        System.assertEquals(testCase.Id, deviceList[0].Case__c,
            'Case__c ' + ERROR_MESSAGE_FIELD_IS_NOT_RETURNER_CORRECT);
        System.assertEquals(testCase.Id, deviceList[0].Local_Parent_Id__c,
            'Local_Parent_Id__c ' + ERROR_MESSAGE_FIELD_IS_NOT_RETURNER_CORRECT);
        System.assertEquals(DEVICE_STATUS, deviceList[0].Status__c,
            'Status__c ' + ERROR_MESSAGE_FIELD_IS_NOT_RETURNER_CORRECT);
    }
    
   @isTest
   private static void testSelectDevicesByCaseNotReturnNotDefaultFieldList() {
        Case testCase = (Case) new CaseSelector(false, false)
           .selectCasesDefault().executeQuery()[0];

        List<Object> bindings = new List<Object>();
        bindings.add(testCase.Id);
        List<Device__c> deviceList = (List<Device__c>) new DeviceSelector(false, false)
            .selectDevicesByCase(bindings).executeQuery();
       
       try {
            String connectionIdOfPartnerDevice = deviceList[0].ConnectionIdOfPartner__c;
            System.assert(false, ERROR_MESSAGE_SHOULD_BE_EXCEPTION);
       } catch (SObjectException ex) {
        System.assertEquals(ERROR_MESSAGE_SOBJECT_EXCEPTION + 'Device__c.ConnectionIdOfPartner__c',
            ex.getMessage(), ERROR_MESSAGE_SHOULD_BE_DIFFERENT_EXCEPTION_MESSAGE);
       }
    }
    
}