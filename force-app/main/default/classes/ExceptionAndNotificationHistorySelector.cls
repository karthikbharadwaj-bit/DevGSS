public inherited sharing class ExceptionAndNotificationHistorySelector extends sObjectSelector{

    public ExceptionAndNotificationHistorySelector() {
        super();
    }

    public ExceptionAndNotificationHistorySelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return Exception_and_Notification_history__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Exception_and_Notification_history__c.Id,
            Exception_and_Notification_history__c.RecordTypeId,
            Exception_and_Notification_history__c.RecordType.Name,
            Exception_and_Notification_history__c.OwnerId,
            Exception_and_Notification_history__c.Name
        };
    }

    public List<Schema.SObjectField> getFieldListToReprocessCM() {
        return new List<Schema.SObjectField> {
            Exception_and_Notification_history__c.Id,
            Exception_and_Notification_history__c.RecordTypeId,
            Exception_and_Notification_history__c.RecordType.Name,
            Exception_and_Notification_history__c.Object_type__c,
            Exception_and_Notification_history__c.Affected_record_ID__c,
            Exception_and_Notification_history__c.Exception__c,
            Exception_and_Notification_history__c.Exception_desc__c,
            Exception_and_Notification_history__c.attempts__c,
            Exception_and_Notification_history__c.Field_Changes__c,
            Exception_and_Notification_history__c.Record_Id__c
        };
    }

    public List<Schema.SObjectField> getOtherFieldList() {
        return new List<Schema.SObjectField> {
            Exception_and_Notification_history__c.CreatedDate,
            Exception_and_Notification_history__c.CreatedById,
            Exception_and_Notification_history__c.LastModifiedDate,
            Exception_and_Notification_history__c.LastModifiedById,
            Exception_and_Notification_history__c.BCC_Address__c,
            Exception_and_Notification_history__c.CC_Address__c,
            Exception_and_Notification_history__c.content_label_01__c,
            Exception_and_Notification_history__c.content_label_02__c,
            Exception_and_Notification_history__c.content_label_03__c,
            Exception_and_Notification_history__c.content_label_04__c,
            Exception_and_Notification_history__c.content_label_05__c,
            Exception_and_Notification_history__c.content_label_06__c,
            Exception_and_Notification_history__c.content_label_07__c,
            Exception_and_Notification_history__c.content_label_08__c,
            Exception_and_Notification_history__c.content_label_09__c,
            Exception_and_Notification_history__c.content_label_10__c,
            Exception_and_Notification_history__c.content_var_01__c,
            Exception_and_Notification_history__c.content_var_02__c,
            Exception_and_Notification_history__c.content_var_03__c,
            Exception_and_Notification_history__c.content_var_04__c,
            Exception_and_Notification_history__c.content_var_05__c,
            Exception_and_Notification_history__c.content_var_06__c,
            Exception_and_Notification_history__c.content_var_07__c,
            Exception_and_Notification_history__c.content_var_08__c,
            Exception_and_Notification_history__c.content_var_09__c,
            Exception_and_Notification_history__c.content_var_10__c,
            Exception_and_Notification_history__c.Email_Subject__c,
            Exception_and_Notification_history__c.Exception__c,
            Exception_and_Notification_history__c.Exception_Desc__c,
            Exception_and_Notification_history__c.File_Associated__c,
            Exception_and_Notification_history__c.isEmailSent__c,
            Exception_and_Notification_history__c.Line_Number__c,
            Exception_and_Notification_history__c.Modified_By__c,
            Exception_and_Notification_history__c.Object_Type__c,
            Exception_and_Notification_history__c.Record_Id__c,
            Exception_and_Notification_history__c.Reply_To__c,
            Exception_and_Notification_history__c.Sender_Display_Name__c,
            Exception_and_Notification_history__c.stackTraceString__c,
            Exception_and_Notification_history__c.To_Address_1__c,
            Exception_and_Notification_history__c.To_Address_2__c,
            Exception_and_Notification_history__c.To_Address_3__c,
            Exception_and_Notification_history__c.To_Address_4__c,
            Exception_and_Notification_history__c.To_Address_5__c,
            Exception_and_Notification_history__c.Unique_Servey_No__c,
            Exception_and_Notification_history__c.Record_Type_Name__c,
            Exception_and_Notification_history__c.ErrorType__c,
            Exception_and_Notification_history__c.Record_Owner__c,
            Exception_and_Notification_history__c.Email_Date_01__c,
            Exception_and_Notification_history__c.Email_Body__c,
            Exception_and_Notification_history__c.Attachment__c,
            Exception_and_Notification_history__c.Preferred_Language__c,
            Exception_and_Notification_history__c.Affected_record_ID__c,
            Exception_and_Notification_history__c.Field_Changes__c
        };
    }
  
    public QueryFactory selectExceptionAndNotificationHistoryById(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectExceptionAndNotificationHistoryById')
            .withSelectorFieldsIncluded()
            .selectFields(getOtherFieldList())
            .setCondition('Id = :bind0')
            .setLimit(1)
            .setQueryBindings(bindings);
    }

    public QueryFactory selectExceptionAndNotificationHistorys() {
        return newQueryFactory()
            .setFactoryName('SelectExceptionAndNotificationHistorys')
            .withSelectorFieldsIncluded()
            .withSelectFieldsSorted();
    }

    public QueryFactory selectExceptionAndNotificationHistorysByIds(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectExceptionAndNotificationHistorysByIds')
            .withSelectorFieldsIncluded()
            .selectFields(getDefaultFieldList())
            .selectFields(getOtherFieldList())
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }
    
    public QueryFactory selectExceptionAndNotificationHistorysByRecordTypeId(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectExceptionAndNotificationHistorysByRecordTypeId')
            .withSelectorFieldsIncluded()
            .selectFields(getFieldListToReprocessCM())
            .selectField(Exception_And_Notification_History__c.attempts__c)
            .selectField(Exception_And_Notification_History__c.CreatedDate)
            .setCondition('RecordTypeId IN :bindings')
            .setQueryBindings(bindings);
    }
    
    public QueryFactory selectExceptionAndNotificationHistoryByIdRecordIdOrAffectedRecordID(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectExceptionAndNotificationHistoryByIdRecordIdOrAffectedRecordID')
            .withSelectorFieldsIncluded()
            .setCondition('RecordTypeId = :bind0 AND Object_Type__c = :bind1 AND Record_Id__c IN :bind2')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectAllExceptionAndNotificationHistory() {
        return newQueryFactory()
            .setFactoryName('selectAllExceptionAndNotificationHistory')
            .selectField(Exception_And_Notification_History__c.Id);
    }


    public QueryFactory selectExceptionAndNotificationHistorysByRecordTypeIdObjecTypeAndException(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectExceptionAndNotificationHistorysByRecordTypeId')
            .withSelectorFieldsIncluded()
            .selectField(Exception_And_Notification_History__c.attempts__c)
            .setCondition('RecordTypeId IN :bind0 AND Object_Type__c = :bind1 AND Exception__c = :bind2')
            .setQueryBindings(bindings);
    }
    

    public QueryFactory selectExceptionAndNotificationHistorysByRecordTypeIdAndObject(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectExceptionAndNotificationHistorysByRecordTypeId')
            .withSelectorFieldsIncluded()
            .selectFields(getFieldListToReprocessCM())
            .selectField(Exception_And_Notification_History__c.attempts__c)
            .selectField(Exception_And_Notification_History__c.CreatedDate)
            .setCondition('RecordTypeId IN :bind0 AND Object_Type__c = :bind1')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectExceptionAndNotificationHistoryForBatchJobDelete(List<Object> bindings, String condition) {
        return newQueryFactory()
            .setFactoryName('selectExceptionAndNotificationHistoryForBatchJobDelete')
            .withSelectorFieldsIncluded()
            .setCondition(condition)
            .setQueryBindings(bindings);
    }
}