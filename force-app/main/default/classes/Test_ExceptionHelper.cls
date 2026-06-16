@isTest
private class Test_ExceptionHelper {

    class CustomTestException extends Exception {}

    private static final String TEST_EXCEPTION_MESSAGE = 'Test exception message';

    @isTest
    static void testCheckIsMassEmailException() {

        try{
            ExceptionHelper.checkIsMassEmailException(null);
            throw new CustomTestException(TEST_EXCEPTION_MESSAGE);
        }catch(Exception ex) {
            Boolean isExpectedExceptionThrown = ex.getMessage().contains(TEST_EXCEPTION_MESSAGE);
            System.assertEquals(true, isExpectedExceptionThrown);
        }
    }

    @isTest
    static void testCheckIsMassEmailExceptionNotMassMailExceptionsShouldRaised() {

        String exMessage = 'my other exception';
        try{
            ExceptionHelper.checkIsMassEmailException(new CustomTestException(exMessage));
        }catch(Exception ex) {
            Boolean isExpectedExceptionThrown = ex.getMessage().contains(exMessage);
            System.assertEquals(true, isExpectedExceptionThrown);
        }
    }

    @isTest
    static void testCheckIsMassEmailExceptionShouldNotRaiseMassMailException() {

        String noMassMailMessage = 'error occurred. ' + System.StatusCode.NO_MASS_MAIL_PERMISSION.name();

        CustomTestException exceptionWithNoMassMailMessage = new CustomTestException(noMassMailMessage);

        try{
            ExceptionHelper.checkIsMassEmailException(exceptionWithNoMassMailMessage);
            throw new CustomTestException(TEST_EXCEPTION_MESSAGE);
        }catch(Exception ex) {

            OrganizationSelector selector = new OrganizationSelector();
            Organization currOrg = (Organization) selector.selectOrg().executeQuery().get(0);

            String exceptionMessage = ex.getMessage();

            if(!currOrg.IsSandbox) {
                Boolean isNoMassMailExceptionThrown = exceptionMessage.contains(noMassMailMessage);
                System.assertEquals(true, isNoMassMailExceptionThrown);
            }else{
                Boolean isExpectedExceptionThrown = exceptionMessage.contains(TEST_EXCEPTION_MESSAGE);
                System.assertEquals(true, isExpectedExceptionThrown);
            }
        }
    }

    @isTest
    public static void throwException_ThreeDiferentsTypesOfsObjects_shouldCreateObjectAndSaveAllInfo(){
        Lead l = (Lead) new SObjectBuilder(Lead.SObjectType).build().getRecord();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType).build().getRecord();
        Contact cont = (Contact) new SObjectBuilder(Contact.SObjectType).setField(Contact.lastName, 'test').create().getRecord();

        sObject[] objects = new sObject[]{l, acc, cont};

        Test.startTest();
            try{
                insert objects;
            }catch(Exception e){
                ExceptionHelper.createExceptionAndNotificacionHistory(e, objects, 'Lead Exception');
            }
        Test.stopTest();
        
        Exception_and_notification_history__c obj = (Exception_and_notification_history__c) new ExceptionAndNotificationHistorySelector()
            .selectExceptionAndNotificationHistorys()
            .selectFields(new String[]{ 'object_type__c','Exception__c','stackTraceString__c', 'RecordTypeId', 'Exception_desc__c'})
            .executeQuery()[0];

        String[] exceptionDesc = new String[]{
            'Number of Leads affected: 1',
            'Number of Accounts affected: 1' ,
            'Number of Contacts affected: 1',
            'Number of sObjects without Id: 2',
            'LINE :',
            'MESSAGE : Insert failed. First exception on row 2 with id ' + cont.Id + '; first error: INVALID_FIELD_FOR_INSERT_UPDATE, cannot specify Id in an insert call: [Id]',
            'STACK TRACE : Class.Test_ExceptionHelper.throwException_ThreeDiferentsTypesOfsObjects_shouldCreateObjectAndSaveAllInfo:',
            'TYPE : System.DmlException',
            '###############################',
            'System.DmlException HAS OCCURRED ',
            '###############################',
            'NUMBER OF AFFECTED ROWS : 1 ',
            '===================================================================== ',
            'System.DmlException 1 ',
            '===================================================================== ',
            'TYPE : INVALID_FIELD_FOR_INSERT_UPDATE ',
            'MESSAGE  : cannot specify Id in an insert call ',
            'FAILED ROW POSITION : 2 ',
            'FAILED RECORD ID : '+ cont.Id,
            'FIELD NAMES : (Id) ',
            '====================================================================='
        };

        System.assert(obj.object_type__c.contains('Lead'), 'the field object_type__c should contains the value "Lead"');
        System.assert(obj.object_type__c.contains('Account'), 'the field object_type__c should contains the value "Account"');
        System.assert(obj.object_type__c.contains('Contact'), 'the field object_type__c should contains the value "Contact"');
        System.assert(obj.stackTraceString__c.contains('Class.Test_ExceptionHelper.throwException_ThreeDiferentsTypesOfsObjects_shouldCreateObjectAndSaveAllInfo'), 'It must contain the method that threw the exception.');
        System.assertEquals('System.DmlException', obj.exception__c);
        String rtId = Schema.SObjectType.Exception_And_Notification_History__c.getRecordTypeInfosByName().get('Lead Exception').getRecordTypeId();
        System.assertEquals(rtId, obj.RecordTypeId);        

    }

    @isTest
    public static void throwException_NullPointerException_shouldCreateObjectAndSaveAllInfo(){
        Lead l = (Lead) new SObjectBuilder(Lead.SObjectType).build().getRecord();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType).build().getRecord();
        Contact cont = (Contact) new SObjectBuilder(Contact.SObjectType).setField(Contact.lastName, 'test').create().getRecord();

        sObject[] objects = new sObject[]{l, acc, cont};

        Test.startTest();
            try {
                l.Id.equals(cont.Id);
            } catch(Exception e) {
                ExceptionHelper.createExceptionAndNotificacionHistory(e, objects, 'Lead Exception');
            }
        Test.stopTest();

        Exception_and_notification_history__c obj = (Exception_and_notification_history__c) new ExceptionAndNotificationHistorySelector()
            .selectExceptionAndNotificationHistorys()
            .selectFields(new String[]{ 'object_type__c','Exception__c','stackTraceString__c', 'RecordTypeId', 'Exception_desc__c'})
            .executeQuery()[0];

        String[] exceptionDesc = new String[]{
            'Number of Leads affected: 1',
            'Number of Accounts affected: 1' ,
            'Number of Contacts affected: 1',
            'Number of sObjects without Id: 2',
            'LINE :',
            'MESSAGE : Attempt to de-reference a null object',
            'STACK TRACE : Class.Test_ExceptionHelper.throwException_NullPointerException_shouldCreateObjectAndSaveAllInfo',
            'TYPE : System.NullPointerException'
        };

        System.assert(obj.object_type__c.contains('Lead'), 'the field object_type__c should contain the value "Lead"');
        System.assert(obj.object_type__c.contains('Account'), 'the field object_type__c should contain the value "Account"');
        System.assert(obj.object_type__c.contains('Contact'), 'the field object_type__c should contain the value "Contact"');
        System.assert(obj.stackTraceString__c.contains('Class.Test_ExceptionHelper.throwException_NullPointerException_shouldCreateObjectAndSaveAllInfo'), 'It must contain the method that threw the exception.');
        System.assertEquals('System.NullPointerException', obj.exception__c);
        String rtId = Schema.SObjectType.Exception_And_Notification_History__c.getRecordTypeInfosByName().get('Lead Exception').getRecordTypeId();
        System.assertEquals(rtId, obj.RecordTypeId);
        
    }

    @isTest
    public static void throwException_onlyOneObject_NullPointerException_shouldCreateObjectRTLeadExceptionAndSaveAllInfo(){
        Lead l = (Lead) new SObjectBuilder(Lead.SObjectType).build().getRecord();

        Test.startTest();
            try{
                l.Id.equals('test');
            }catch(Exception e){
                ExceptionHelper.createExceptionAndNotificacionHistory(e, l, 'Lead Exception');
            }
        Test.stopTest();

        Exception_and_notification_history__c obj = (Exception_and_notification_history__c) new ExceptionAndNotificationHistorySelector()
            .selectExceptionAndNotificationHistorys()
            .selectFields(new String[]{ 'object_type__c','Exception__c','stackTraceString__c', 'RecordTypeId', 'Exception_desc__c'})
            .executeQuery()[0];

        String[] exceptionDesc = new String[]{
            'Number of Leads affected: 1',
            'Number of sObjects without Id: 1',
            'LINE :',
            'MESSAGE : Attempt to de-reference a null object',
            'STACK TRACE : Class.Test_ExceptionHelper.throwException_onlyOneObject_NullPointerException_shouldCreateObjectRTLeadExceptionAndSaveAllInfo',
            'TYPE : System.NullPointerException'
        };

        System.assert(obj.object_type__c.contains('Lead'), 'the field object_type__c should contain the value "Lead"');
        System.assertEquals('System.NullPointerException', obj.exception__c);
        System.assert(obj.stackTraceString__c.contains('Class.Test_ExceptionHelper.throwException_onlyOneObject_NullPointerException_shouldCreateObjectRTLeadExceptionAndSaveAllInfo'), 'It must contain the method that threw the exception.');
        String rtLeadException = Schema.SObjectType.Exception_And_Notification_History__c.getRecordTypeInfosByName().get('Lead Exception').getRecordTypeId();
        System.assertEquals(rtLeadException, obj.RecordTypeId);
        for(String exDesc : exceptionDesc){
            System.assert(obj.Exception_desc__c.contains(exDesc), 'the field Exception_desc__c should contain the value: ' + exDesc);
        }

    }

    @isTest
    public static void test_selectExceptionAndNotificationHistorysByIds(){
        List<Exception_and_notification_history__c> createdsEANHs = (List<Exception_and_notification_history__c>) 
            new SObjectBuilder(Exception_and_notification_history__c.SObjectType)
            .build()
            .create()
            .quantity(2)
            .getRecords();

        List<Exception_and_notification_history__c> EANHsToRetrieve;
        List<Object> bindings = new List<Object>();
        bindings.add(createdsEANHs);

        Test.startTest();
            EANHsToRetrieve = (List<Exception_and_notification_history__c>) new ExceptionAndNotificationHistorySelector()
                .selectExceptionAndNotificationHistorysByIds(bindings)
                .selectFields(new String[]{ 'object_type__c','Exception__c','stackTraceString__c', 'RecordTypeId', 'Exception_desc__c'})
                .executeQuery();
        Test.stopTest();
        
        System.assertEquals(createdsEANHs.size(), EANHsToRetrieve.size(), 'There should be one Exception And Notification History created.');
    }

    @isTest
    public static void test_selectExceptionAndNotificationHistorysById(){
        Exception_and_notification_history__c EANH = (Exception_and_notification_history__c) new SObjectBuilder(Exception_and_notification_history__c.SObjectType)
            .build()
            .create()
            .getRecord();
        List<Exception_and_notification_history__c> EANHsToRetrieve;

        Test.startTest();
            EANHsToRetrieve = (List<Exception_and_notification_history__c>) new ExceptionAndNotificationHistorySelector(true, true)
                .selectExceptionAndNotificationHistoryById(new object[]{EANH.Id})
                .selectFields(new String[]{ 'object_type__c','Exception__c','stackTraceString__c', 'RecordTypeId', 'Exception_desc__c'})
                .executeQuery();
        Test.stopTest();
        
        System.assertEquals(1, EANHsToRetrieve.size(), 'There should be one Exception And Notification History created.');
    }

    @IsTest
    static void testCreateExceptionAndNotificacionHistoryForIntegration() {
        // Test constants
        final String TEST_RECORD_TYPE_NAME = 'Lead Exception';
        final String TEST_REQUEST_ID = 'test-request-123';
        final String TEST_RESPONSE_BODY = '{"error":"Test error message"}';
        final Integer ERROR_STATUS_CODE = 500;
        final String ERROR_STATUS = 'Internal Server Error';
    
        Test.startTest();
        
        // Create error response (500)
        HttpResponse errorResponse = new HttpResponse();
        errorResponse.setStatusCode(ERROR_STATUS_CODE);
        errorResponse.setStatus(ERROR_STATUS);
        errorResponse.setBody(TEST_RESPONSE_BODY);
        errorResponse.setHeader('X-Request-ID', TEST_REQUEST_ID);
        
        ExceptionHelper.createExceptionAndNotificacionHistoryForIntegration(errorResponse, TEST_RECORD_TYPE_NAME);
        
        Test.stopTest();
        
        // Verify created record
        List<Exception_And_Notification_History__c> records = [
            SELECT Id, object_type__c, Affected_record_ID__c, Exception__c, 
                   stackTraceString__c, Exception_desc__c, RecordTypeId
            FROM Exception_And_Notification_History__c
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        
        System.assertEquals(1, records.size(), 'Should create exactly 1 exception record');
        
        Exception_And_Notification_History__c record = records[0];
        System.assertEquals('Integration Response', record.object_type__c, 'Object type should match');
        System.assertEquals(TEST_REQUEST_ID, record.Affected_record_ID__c, 'Request ID should match');
        System.assertEquals('Integration Exception', record.Exception__c, 'Exception should match');
        System.assertEquals('Stack trace not available', record.stackTraceString__c, 'Stack trace should match');
        System.assert(record.Exception_desc__c.contains('Response Code: ' + ERROR_STATUS_CODE), 'Should contain response code');
        System.assert(record.Exception_desc__c.contains('Integration Error: ' + ERROR_STATUS_CODE + ' ' + ERROR_STATUS), 'Should contain integration error for status >= 400');
        
        // Verify Record Type
        Id expectedRecordTypeId = Schema.SObjectType.Exception_And_Notification_History__c
            .getRecordTypeInfosByName()
            .get(TEST_RECORD_TYPE_NAME)
            .getRecordTypeId();
        System.assertEquals(expectedRecordTypeId, record.RecordTypeId, 'Record type should match');
    }    
}