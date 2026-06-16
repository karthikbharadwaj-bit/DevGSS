@isTest
public class Test_DFRUpdateFieldsHelper {
    @isTest
    public static void test_handleBatchErrorExceptionCreationForDfr() {
        Id rtId = Schema.SObjectType.Exception_And_Notification_History__c.getRecordTypeInfosByName()
                .get(DFRUpdateFieldsHelper.RECORDTYPENAME)
                .getRecordTypeId();
        RingCentralVariousSettings__c settings = (RingCentralVariousSettings__c) new SObjectBuilder(RingCentralVariousSettings__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                        RingCentralVariousSettings__c.DFRUpdateFields_useCustomSetting__c => false,
                        RingCentralVariousSettings__c.DFRUpdateFields_isDFRIncluded__c => true,
                        RingCentralVariousSettings__c.DFRUpdateFields_isLeadIncluded__c => false,
                        RingCentralVariousSettings__c.DFRUpdateFields_isContactIncluded__c => false,
                        RingCentralVariousSettings__c.DFRUpdateFields_isAccountIncluded__c => false
                        }
            )
            .create()
            .getRecord();
        try {
            Test.startTest();
            Database.executeBatch(new Batchjob_DFRUpdateFields(true));
            Test.stopTest();
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Custom Exception for testing purposes'));
        }
        Test.getEventBus().deliver();
        DFRUpdateFieldsHelper.DFRUpdateFieldsInstance jobData = new DFRUpdateFieldsHelper.DFRUpdateFieldsInstance(
				Date.today(),
				settings.DFRUpdateFields_isDFRIncluded__c,
				settings.DFRUpdateFields_isLeadIncluded__c,
				settings.DFRUpdateFields_isContactIncluded__c,
				settings.DFRUpdateFields_isAccountIncluded__c,
				settings.DFRUpdateFields_useCustomSetting__c
			);
        List<Exception_And_Notification_History__c> existingException = (List<Exception_And_Notification_History__c>) new ExceptionAndNotificationHistorySelector()
            .selectExceptionAndNotificationHistorysByRecordTypeIdObjecTypeAndException(new List<Object>{new List<String>{rtId}, DFRUpdateFieldsHelper.BATCHJOB_DFRUPDATEFIELDS, JSON.serialize(jobData)})
            .executeQuery();
        System.assertEquals(1,existingException[0].Attempts__c,'Exception log generated incorrectly');
    }

    @isTest
    public static void test_handleBatchErrorExceptionCreationForLead() {
        Id rtId = Schema.SObjectType.Exception_And_Notification_History__c.getRecordTypeInfosByName()
                .get(DFRUpdateFieldsHelper.RECORDTYPENAME)
                .getRecordTypeId();
        RingCentralVariousSettings__c settings = (RingCentralVariousSettings__c) new SObjectBuilder(RingCentralVariousSettings__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                        RingCentralVariousSettings__c.DFRUpdateFields_useCustomSetting__c => false,
                        RingCentralVariousSettings__c.DFRUpdateFields_isDFRIncluded__c => false,
                        RingCentralVariousSettings__c.DFRUpdateFields_isLeadIncluded__c => true,
                        RingCentralVariousSettings__c.DFRUpdateFields_isContactIncluded__c => false,
                        RingCentralVariousSettings__c.DFRUpdateFields_isAccountIncluded__c => false
                        }
            )
            .create()
            .getRecord();
        try {
            Test.startTest();
            Database.executeBatch(new Batchjob_DFRUpdateFields(true));
            Test.stopTest();
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Custom Exception for testing purposes'));
        }
        Test.getEventBus().deliver();
        DFRUpdateFieldsHelper.DFRUpdateFieldsInstance jobData = new DFRUpdateFieldsHelper.DFRUpdateFieldsInstance(
				Date.today(),
				settings.DFRUpdateFields_isDFRIncluded__c,
				settings.DFRUpdateFields_isLeadIncluded__c,
				settings.DFRUpdateFields_isContactIncluded__c,
				settings.DFRUpdateFields_isAccountIncluded__c,
				settings.DFRUpdateFields_useCustomSetting__c
			);
        List<Exception_And_Notification_History__c> existingException = (List<Exception_And_Notification_History__c>) new ExceptionAndNotificationHistorySelector()
            .selectExceptionAndNotificationHistorysByRecordTypeIdObjecTypeAndException(new List<Object>{new List<String>{rtId}, DFRUpdateFieldsHelper.BATCHJOB_DFRUPDATEFIELDS, JSON.serialize(jobData)})
            .executeQuery();
        System.assertEquals(1,existingException[0].Attempts__c,'Exception log generated incorrectly');
    }
    @isTest
    public static void test_handleBatchErrorExceptionCreationForContact() {
        Id rtId = Schema.SObjectType.Exception_And_Notification_History__c.getRecordTypeInfosByName()
                .get(DFRUpdateFieldsHelper.RECORDTYPENAME)
                .getRecordTypeId();
        RingCentralVariousSettings__c settings = (RingCentralVariousSettings__c) new SObjectBuilder(RingCentralVariousSettings__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                        RingCentralVariousSettings__c.DFRUpdateFields_useCustomSetting__c => false,
                        RingCentralVariousSettings__c.DFRUpdateFields_isDFRIncluded__c => false,
                        RingCentralVariousSettings__c.DFRUpdateFields_isLeadIncluded__c => false,
                        RingCentralVariousSettings__c.DFRUpdateFields_isContactIncluded__c => true,
                        RingCentralVariousSettings__c.DFRUpdateFields_isAccountIncluded__c => false
                        }
            )
            .create()
            .getRecord();
        try {
            Test.startTest();
            Database.executeBatch(new Batchjob_DFRUpdateFields(true));
            Test.stopTest();
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Custom Exception for testing purposes'));
        }
        Test.getEventBus().deliver();
        DFRUpdateFieldsHelper.DFRUpdateFieldsInstance jobData = new DFRUpdateFieldsHelper.DFRUpdateFieldsInstance(
				Date.today(),
				settings.DFRUpdateFields_isDFRIncluded__c,
				settings.DFRUpdateFields_isLeadIncluded__c,
				settings.DFRUpdateFields_isContactIncluded__c,
				settings.DFRUpdateFields_isAccountIncluded__c,
				settings.DFRUpdateFields_useCustomSetting__c
			);
        List<Exception_And_Notification_History__c> existingException = (List<Exception_And_Notification_History__c>) new ExceptionAndNotificationHistorySelector()
            .selectExceptionAndNotificationHistorysByRecordTypeIdObjecTypeAndException(new List<Object>{new List<String>{rtId}, DFRUpdateFieldsHelper.BATCHJOB_DFRUPDATEFIELDS, JSON.serialize(jobData)})
            .executeQuery();
        System.assertEquals(1,existingException[0].Attempts__c,'Exception log generated incorrectly');
    }
    @isTest
    public static void test_handleBatchErrorExceptionCreationForAccount() {
        Id rtId = Schema.SObjectType.Exception_And_Notification_History__c.getRecordTypeInfosByName()
                .get(DFRUpdateFieldsHelper.RECORDTYPENAME)
                .getRecordTypeId();
        RingCentralVariousSettings__c settings = (RingCentralVariousSettings__c) new SObjectBuilder(RingCentralVariousSettings__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                        RingCentralVariousSettings__c.DFRUpdateFields_useCustomSetting__c => false,
                        RingCentralVariousSettings__c.DFRUpdateFields_isDFRIncluded__c => false,
                        RingCentralVariousSettings__c.DFRUpdateFields_isLeadIncluded__c => false,
                        RingCentralVariousSettings__c.DFRUpdateFields_isContactIncluded__c => false,
                        RingCentralVariousSettings__c.DFRUpdateFields_isAccountIncluded__c => true
                        }
            )
            .create()
            .getRecord();
        try {
            Test.startTest();
            Database.executeBatch(new Batchjob_DFRUpdateFields(true));
            Test.stopTest();
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Custom Exception for testing purposes'));
        }
        Test.getEventBus().deliver();
        DFRUpdateFieldsHelper.DFRUpdateFieldsInstance jobData = new DFRUpdateFieldsHelper.DFRUpdateFieldsInstance(
				Date.today(),
				settings.DFRUpdateFields_isDFRIncluded__c,
				settings.DFRUpdateFields_isLeadIncluded__c,
				settings.DFRUpdateFields_isContactIncluded__c,
				settings.DFRUpdateFields_isAccountIncluded__c,
				settings.DFRUpdateFields_useCustomSetting__c
			);
        List<Exception_And_Notification_History__c> existingException = (List<Exception_And_Notification_History__c>) new ExceptionAndNotificationHistorySelector()
            .selectExceptionAndNotificationHistorysByRecordTypeIdObjecTypeAndException(new List<Object>{new List<String>{rtId}, DFRUpdateFieldsHelper.BATCHJOB_DFRUPDATEFIELDS, JSON.serialize(jobData)})
            .executeQuery();
        System.assertEquals(1,existingException[0].Attempts__c,'Exception log generated incorrectly');
    }
    @isTest
    public static void test_handleBatchErrorExceptionUpdateForDfr() {
        Id rtId = Schema.SObjectType.Exception_And_Notification_History__c.getRecordTypeInfosByName()
                .get(DFRUpdateFieldsHelper.RECORDTYPENAME)
                .getRecordTypeId();

        RingCentralVariousSettings__c settings = (RingCentralVariousSettings__c) new SObjectBuilder(RingCentralVariousSettings__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                        RingCentralVariousSettings__c.DFRUpdateFields_useCustomSetting__c => false,
                        RingCentralVariousSettings__c.DFRUpdateFields_isDFRIncluded__c => true,
                        RingCentralVariousSettings__c.DFRUpdateFields_isLeadIncluded__c => false,
                        RingCentralVariousSettings__c.DFRUpdateFields_isContactIncluded__c => false,
                        RingCentralVariousSettings__c.DFRUpdateFields_isAccountIncluded__c => false
                        }
            )
            .create()
            .getRecord();

        DFRUpdateFieldsHelper.DFRUpdateFieldsInstance jobData = new DFRUpdateFieldsHelper.DFRUpdateFieldsInstance(
				Date.today(),
				settings.DFRUpdateFields_isDFRIncluded__c,
				settings.DFRUpdateFields_isLeadIncluded__c,
				settings.DFRUpdateFields_isContactIncluded__c,
				settings.DFRUpdateFields_isAccountIncluded__c,
				settings.DFRUpdateFields_useCustomSetting__c
		);

        Exception_And_Notification_History__c excep = new Exception_And_Notification_History__c(
                    RecordTypeId = rtId,
                    Object_Type__c = DFRUpdateFieldsHelper.BATCHJOB_DFRUPDATEFIELDS,
                    Exception__c = JSON.serialize(jobData),
                    Exception_desc__c = ' Test ExceptionType - Test Message',
                    stackTraceString__c = ' Test StackTrace ',
                    Attempts__c = 1
                );
        insert excep;

        try {
            Test.startTest();
            Database.executeBatch(new Batchjob_DFRUpdateFields(true));
            Test.stopTest();
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Custom Exception for testing purposes'));
        }
        Test.getEventBus().deliver();
        
        List<Exception_And_Notification_History__c> existingException = (List<Exception_And_Notification_History__c>) new ExceptionAndNotificationHistorySelector()
            .selectExceptionAndNotificationHistorysByRecordTypeIdObjecTypeAndException(new List<Object>{new List<String>{rtId}, DFRUpdateFieldsHelper.BATCHJOB_DFRUPDATEFIELDS, JSON.serialize(jobData)})
            .executeQuery();
        System.assertEquals(2,existingException[0].Attempts__c,'Exception log generated incorrectly');
    }
    @isTest
    public static void test_handleBatchErrorExceptionUpdateForLead() {
        Id rtId = Schema.SObjectType.Exception_And_Notification_History__c.getRecordTypeInfosByName()
                .get(DFRUpdateFieldsHelper.RECORDTYPENAME)
                .getRecordTypeId();

        RingCentralVariousSettings__c settings = (RingCentralVariousSettings__c) new SObjectBuilder(RingCentralVariousSettings__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                        RingCentralVariousSettings__c.DFRUpdateFields_useCustomSetting__c => false,
                        RingCentralVariousSettings__c.DFRUpdateFields_isDFRIncluded__c => false,
                        RingCentralVariousSettings__c.DFRUpdateFields_isLeadIncluded__c => true,
                        RingCentralVariousSettings__c.DFRUpdateFields_isContactIncluded__c => false,
                        RingCentralVariousSettings__c.DFRUpdateFields_isAccountIncluded__c => false
                        }
            )
            .create()
            .getRecord();

        DFRUpdateFieldsHelper.DFRUpdateFieldsInstance jobData = new DFRUpdateFieldsHelper.DFRUpdateFieldsInstance(
				Date.today(),
				settings.DFRUpdateFields_isDFRIncluded__c,
				settings.DFRUpdateFields_isLeadIncluded__c,
				settings.DFRUpdateFields_isContactIncluded__c,
				settings.DFRUpdateFields_isAccountIncluded__c,
				settings.DFRUpdateFields_useCustomSetting__c
		);

        Exception_And_Notification_History__c excep = new Exception_And_Notification_History__c(
                    RecordTypeId = rtId,
                    Object_Type__c = DFRUpdateFieldsHelper.BATCHJOB_DFRUPDATEFIELDS,
                    Exception__c = JSON.serialize(jobData),
                    Exception_desc__c = ' Test ExceptionType - Test Message',
                    stackTraceString__c = ' Test StackTrace ',
                    Attempts__c = 1
                );
        insert excep;

        try {
            Test.startTest();
            Database.executeBatch(new Batchjob_DFRUpdateFields(true));
            Test.stopTest();
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Custom Exception for testing purposes'));
        }
        Test.getEventBus().deliver();
        
        List<Exception_And_Notification_History__c> existingException = (List<Exception_And_Notification_History__c>) new ExceptionAndNotificationHistorySelector()
            .selectExceptionAndNotificationHistorysByRecordTypeIdObjecTypeAndException(new List<Object>{new List<String>{rtId}, DFRUpdateFieldsHelper.BATCHJOB_DFRUPDATEFIELDS, JSON.serialize(jobData)})
            .executeQuery();
        System.assertEquals(2,existingException[0].Attempts__c,'Exception log generated incorrectly');
    }
    @isTest
    public static void test_handleBatchErrorExceptionUpdateForContact() {
        Id rtId = Schema.SObjectType.Exception_And_Notification_History__c.getRecordTypeInfosByName()
                .get(DFRUpdateFieldsHelper.RECORDTYPENAME)
                .getRecordTypeId();

        RingCentralVariousSettings__c settings = (RingCentralVariousSettings__c) new SObjectBuilder(RingCentralVariousSettings__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                        RingCentralVariousSettings__c.DFRUpdateFields_useCustomSetting__c => false,
                        RingCentralVariousSettings__c.DFRUpdateFields_isDFRIncluded__c => false,
                        RingCentralVariousSettings__c.DFRUpdateFields_isLeadIncluded__c => false,
                        RingCentralVariousSettings__c.DFRUpdateFields_isContactIncluded__c => true,
                        RingCentralVariousSettings__c.DFRUpdateFields_isAccountIncluded__c => false
                        }
            )
            .create()
            .getRecord();

        DFRUpdateFieldsHelper.DFRUpdateFieldsInstance jobData = new DFRUpdateFieldsHelper.DFRUpdateFieldsInstance(
				Date.today(),
				settings.DFRUpdateFields_isDFRIncluded__c,
				settings.DFRUpdateFields_isLeadIncluded__c,
				settings.DFRUpdateFields_isContactIncluded__c,
				settings.DFRUpdateFields_isAccountIncluded__c,
				settings.DFRUpdateFields_useCustomSetting__c
		);

        Exception_And_Notification_History__c excep = new Exception_And_Notification_History__c(
                    RecordTypeId = rtId,
                    Object_Type__c = DFRUpdateFieldsHelper.BATCHJOB_DFRUPDATEFIELDS,
                    Exception__c = JSON.serialize(jobData),
                    Exception_desc__c = ' Test ExceptionType - Test Message',
                    stackTraceString__c = ' Test StackTrace ',
                    Attempts__c = 1
                );
        insert excep;

        try {
            Test.startTest();
            Database.executeBatch(new Batchjob_DFRUpdateFields(true));
            Test.stopTest();
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Custom Exception for testing purposes'));
        }
        Test.getEventBus().deliver();
        
        List<Exception_And_Notification_History__c> existingException = (List<Exception_And_Notification_History__c>) new ExceptionAndNotificationHistorySelector()
            .selectExceptionAndNotificationHistorysByRecordTypeIdObjecTypeAndException(new List<Object>{new List<String>{rtId}, DFRUpdateFieldsHelper.BATCHJOB_DFRUPDATEFIELDS, JSON.serialize(jobData)})
            .executeQuery();
        System.assertEquals(2,existingException[0].Attempts__c,'Exception log generated incorrectly');
    }
    @isTest
    public static void test_handleBatchErrorExceptionUpdateForAccount() {
        Id rtId = Schema.SObjectType.Exception_And_Notification_History__c.getRecordTypeInfosByName()
                .get(DFRUpdateFieldsHelper.RECORDTYPENAME)
                .getRecordTypeId();

        RingCentralVariousSettings__c settings = (RingCentralVariousSettings__c) new SObjectBuilder(RingCentralVariousSettings__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                        RingCentralVariousSettings__c.DFRUpdateFields_useCustomSetting__c => false,
                        RingCentralVariousSettings__c.DFRUpdateFields_isDFRIncluded__c => false,
                        RingCentralVariousSettings__c.DFRUpdateFields_isLeadIncluded__c => false,
                        RingCentralVariousSettings__c.DFRUpdateFields_isContactIncluded__c => false,
                        RingCentralVariousSettings__c.DFRUpdateFields_isAccountIncluded__c => true
                        }
            )
            .create()
            .getRecord();

        DFRUpdateFieldsHelper.DFRUpdateFieldsInstance jobData = new DFRUpdateFieldsHelper.DFRUpdateFieldsInstance(
				Date.today(),
				settings.DFRUpdateFields_isDFRIncluded__c,
				settings.DFRUpdateFields_isLeadIncluded__c,
				settings.DFRUpdateFields_isContactIncluded__c,
				settings.DFRUpdateFields_isAccountIncluded__c,
				settings.DFRUpdateFields_useCustomSetting__c
		);

        Exception_And_Notification_History__c excep = new Exception_And_Notification_History__c(
                    RecordTypeId = rtId,
                    Object_Type__c = DFRUpdateFieldsHelper.BATCHJOB_DFRUPDATEFIELDS,
                    Exception__c = JSON.serialize(jobData),
                    Exception_desc__c = ' Test ExceptionType - Test Message',
                    stackTraceString__c = ' Test StackTrace ',
                    Attempts__c = 1
                );
        insert excep;

        try {
            Test.startTest();
            Database.executeBatch(new Batchjob_DFRUpdateFields(true));
            Test.stopTest();
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Custom Exception for testing purposes'));
        }
        Test.getEventBus().deliver();
        
        List<Exception_And_Notification_History__c> existingException = (List<Exception_And_Notification_History__c>) new ExceptionAndNotificationHistorySelector()
            .selectExceptionAndNotificationHistorysByRecordTypeIdObjecTypeAndException(new List<Object>{new List<String>{rtId}, DFRUpdateFieldsHelper.BATCHJOB_DFRUPDATEFIELDS, JSON.serialize(jobData)})
            .executeQuery();
        System.assertEquals(2,existingException[0].Attempts__c,'Exception log generated incorrectly');
    }
}