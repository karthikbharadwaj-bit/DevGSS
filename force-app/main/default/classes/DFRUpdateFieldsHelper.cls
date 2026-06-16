public class DFRUpdateFieldsHelper {
	@Testvisible
    static final String START_STRING = 'START';
	@Testvisible	
    static final String RECORDTYPENAME = 'DFRUpdateFields Exception';
    public static final String BATCHJOB_DFRUPDATEFIELDS = 'Batchjob_DFRUpdateFields';

	public static void handleBatchError(BatchApexErrorEvent evt) {
        if(evt.Phase == START_STRING) {
            Id rtId = Schema.SObjectType.Exception_And_Notification_History__c.getRecordTypeInfosByName()
                .get(RECORDTYPENAME)
                .getRecordTypeId();
            RingCentralVariousSettings__c settings = RingCentralVariousSettings__c.getOrgDefaults();
            DFRUpdateFieldsInstance jobData = new DFRUpdateFieldsInstance(
				Date.today(),
				settings.DFRUpdateFields_isDFRIncluded__c,
				settings.DFRUpdateFields_isLeadIncluded__c,
				settings.DFRUpdateFields_isContactIncluded__c,
				settings.DFRUpdateFields_isAccountIncluded__c,
				settings.DFRUpdateFields_useCustomSetting__c
			);
            List<Exception_And_Notification_History__c> existingException = (List<Exception_And_Notification_History__c>) new ExceptionAndNotificationHistorySelector()
            .selectExceptionAndNotificationHistorysByRecordTypeIdObjecTypeAndException(new List<Object>{new List<String>{rtId}, BATCHJOB_DFRUPDATEFIELDS, JSON.serialize(jobData)})
            .executeQuery();
            if (existingException != null && !existingException.isEmpty()) { 
                existingException[0].Attempts__c = existingException[0].Attempts__c + 1;
                update existingException[0];
                fireJobToNextObject(jobData);
            } else {
                Exception_And_Notification_History__c excep = new Exception_And_Notification_History__c(
                    RecordTypeId = rtId,
                    Object_Type__c = BATCHJOB_DFRUPDATEFIELDS,
                    Exception__c = JSON.serialize(jobData),
                    Exception_desc__c = evt.ExceptionType + ' - ' + evt.Message,
                    stackTraceString__c = evt.StackTrace,
                    Attempts__c = 1
                );
                insert excep;
                Database.executeBatch(new Batchjob_DFRUpdateFields());
            }            
        }
    }
    public static void fireJobToNextObject(DFRUpdateFieldsInstance jobData) {
        RingCentralVariousSettings__c settings = RingCentralVariousSettings__c.getOrgDefaults();
        if(!jobData.useCustomSetting){            
            Batchjob_DFRUpdateFields nextBatchjob_DFRUpdateFields;
            nextBatchjob_DFRUpdateFields = new Batchjob_DFRUpdateFields();    
            if(jobData.isDFRIncluded) {
                settings.DFRUpdateFields_isDFRIncluded__c = false;
                settings.DFRUpdateFields_isLeadIncluded__c = true;
                settings.DFRUpdateFields_isContactIncluded__c = false;
                settings.DFRUpdateFields_isAccountIncluded__c = false;
                update settings;
                Database.executeBatch(nextBatchjob_DFRUpdateFields);
            } else if(jobData.isLeadIncluded) {
                settings.DFRUpdateFields_isDFRIncluded__c = false;
                settings.DFRUpdateFields_isLeadIncluded__c = false;
                settings.DFRUpdateFields_isContactIncluded__c = true;
                settings.DFRUpdateFields_isAccountIncluded__c = false;
                update settings;
                Database.executeBatch(nextBatchjob_DFRUpdateFields);
            } else if(jobData.isContactIncluded) {
                settings.DFRUpdateFields_isDFRIncluded__c = false;
                settings.DFRUpdateFields_isLeadIncluded__c = false;
                settings.DFRUpdateFields_isContactIncluded__c = false;
                settings.DFRUpdateFields_isAccountIncluded__c = true;
                update settings;
                Database.executeBatch(nextBatchjob_DFRUpdateFields);
            } else if(jobData.isAccountIncluded) {
                settings.DFRUpdateFields_isDFRIncluded__c = true;
                settings.DFRUpdateFields_isLeadIncluded__c = false;
                settings.DFRUpdateFields_isContactIncluded__c = false;
                settings.DFRUpdateFields_isAccountIncluded__c = false;
                update settings;
            }   
        }
    }


    public class DFRUpdateFieldsInstance {
		Date execution_day;
		boolean isDFRIncluded;
		boolean isLeadIncluded;
		boolean isContactIncluded;
		boolean isAccountIncluded;
        boolean useCustomSetting;

		public DFRUpdateFieldsInstance(Date execution_day, boolean isDFRIncluded, 
                                        boolean isLeadIncluded, boolean isContactIncluded, 
                                        boolean isAccountIncluded, boolean useCustomSetting) {
			this.execution_day = execution_day;
			this.isDFRIncluded = isDFRIncluded;
			this.isLeadIncluded = isLeadIncluded;
			this.isContactIncluded = isContactIncluded;
			this.isAccountIncluded = isAccountIncluded;
            this.useCustomSetting = useCustomSetting;
		}
	}
}