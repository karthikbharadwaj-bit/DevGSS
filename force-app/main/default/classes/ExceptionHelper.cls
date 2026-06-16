public with sharing class ExceptionHelper {

    public static void checkIsMassEmailException(Exception ex) {

        if(ex == null) {
            return;
        }

        Boolean isNoMassMailPermission = ex.getMessage().contains(System.StatusCode.NO_MASS_MAIL_PERMISSION.name());

        if(isNoMassMailPermission) {
            OrganizationSelector selector = new OrganizationSelector();
            Organization currOrg = (Organization) selector.selectOrg().executeQuery().get(0);
            // if it sandbox - bypass test(in sandbox environments Deliverability access level
                // set to "System Email Only" and sending emails will cause NO_MASS_MAIL_PERMISSION exception)
            // in other case - throw catched exception
            if(!currOrg.IsSandbox) {
                System.debug('it not a sandbox environment. throw catched email exception.');
                throw ex;
            }
        }else{
            throw ex;
        }
    }
    /**
     * @description This method creates a sObject "Exception and Notification History" in order to save the valuable information about what happened.
     * @param e the exception to save.
     * @param sobjects sObjects affected for this exception.
     * @param recordTypeName the name of sObject recordtype, this parameter is mandatory. 
     */
    public static void createExceptionAndNotificacionHistory(Exception e, SObject[] objects, String recordTypeName){

        if(!Schema.SObjectType.Exception_And_Notification_History__c.getRecordTypeInfosByName().containsKey(recordTypeName)){
            return;
        }
        
        Id rtId = Schema.SObjectType.Exception_And_Notification_History__c.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();

        Map<String, sObject[]> sObjectByTypeName = new Map<String, sObject[]>();
        Map<String, String[]>  objectsIdByTypeName = new Map<String, String[]>();

        Integer sObjectsWithoutId = 0;
        String idsObjects = '';
        String sObjectTypes = '';

        if (objects != null){
            for(sObject obj : objects){

                string typeName = obj.getSObjectType().getDescribe().getName();
    
                if (String.isNotBlank(obj.Id)){
                    if (!objectsIdByTypeName.containsKey(typeName)) {
                        objectsIdByTypeName.put(typeName, new String[]{});
                    }
                    objectsIdByTypeName.get(typeName).add(obj.Id);
                }else{
                    sObjectsWithoutId++;
                }
    
    
                if(!sObjectByTypeName.containsKey(typeName)){
                    sObjectTypes += typeName + ' ';
                    sObjectByTypeName.put(typeName, new sObject[]{});
                }
                sObjectByTypeName.get(typeName).add(obj);
            }
        }

        String exceptionDesc = '';

        for (String typeName : sObjectByTypeName.keySet()){
            exceptionDesc += 'Number of ' + typeName + 's affected: ' + sObjectByTypeName.get(typeName).size() + ' \r\n';
            // for(sObject obj : sObjectByTypeName.get(typeName)){
            //      Here do something with sobjects separated with typename, if you want to...
            // }
            System.debug('typeName actual: ' + typeName);
            if (objectsIdByTypeName.containsKey(typeName)){
                idsObjects += typeName + ': \r\n';
                for (String idAffected : objectsIdByTypeName.get(typeName)){
                    System.debug('idAffected: ' + idAffected);
                    idsObjects += idAffected + ' - ';
                }
                idsObjects = idsObjects.removeEnd(' - ');
                idsObjects += '\r\n=====================================================================\r\n';
            }
        }
        idsObjects = idsObjects.removeEnd('\r\n=====================================================================\r\n');
        exceptionDesc += objects != null && !objects.isEmpty() ? 'Number of sObjects without Id: ' + sObjectsWithoutId + ' \r\n' : '';

        exceptionDesc +=
            'LINE : ' + e.getLineNumber() + ' \r\n' +
            'MESSAGE : ' + e.getMessage() + ' \r\n' +
            'STACK TRACE : ' + e.getStackTraceString() + ' \r\n' +
            'TYPE : ' +  e.getTypeName() +  ' \r\n';
            
        //if it's a DmlException or EmailException, more info about that is loaded
        if (e.getTypeName().equalsIgnoreCase('System.DmlException') 
            || e.getTypeName().equalsIgnoreCase('System.EmailException')
        ) {
            exceptionDesc += exceptionInformationSOQLOrEmail(e);
        }

        insert new Exception_And_Notification_History__c(
            object_type__c = sObjectTypes,
            Affected_record_ID__c = idsObjects,
            Exception__c = e.getTypeName(),
            stackTraceString__c = e.getStackTraceString(),
            RecordTypeId = rtId,
            Exception_desc__c = exceptionDesc
        );
    }
    
    public static void createExceptionAndNotificacionHistoryForIntegration(
    HttpResponse response,
    String recordTypeName
  ) {
    if (response == null) {
      return;
    }

    String exceptionDesc =
      'Response Code: ' +
      response.getStatusCode() +
      '\r\n' +
      'Response Body: ' +
      response.getBody() +
      '\r\n';

    exceptionDesc += 'Exception Occurred at: ' + System.now() + '\r\n';
    if (response.getStatusCode() >= 400) {
      exceptionDesc +=
        'Integration Error: ' +
        response.getStatusCode() +
        ' ' +
        response.getStatus() +
        '\r\n';
    }

    insert new Exception_And_Notification_History__c(
      object_type__c = 'Integration Response',
      Affected_record_ID__c = response.getHeader('X-Request-ID'),
      Exception__c = 'Integration Exception',
      stackTraceString__c = 'Stack trace not available',
      RecordTypeId = Schema.SObjectType.Exception_And_Notification_History__c.getRecordTypeInfosByName()
        .get(recordTypeName)
        .getRecordTypeId(),
      Exception_desc__c = exceptionDesc
    );
  }
  
    public static void createExceptionAndNotificacionHistory(Exception e, sObject obj, String recordTypeName){
        createExceptionAndNotificacionHistory(e, new sObject[]{obj}, recordTypeName);
    }

    public static String exceptionInformationSOQLOrEmail(Exception e){
        String message =
            '###############################\r\n' + 
            e.getTypeName() + ' HAS OCCURRED \r\n' + 
            '###############################\r\n' +
            'NUMBER OF AFFECTED ROWS : ' + e.getNumDml() + ' \r\n' +
            '=====================================================================' + ' \r\n';
        for (Integer i = 0; i < e.getNumDml(); i++) {
            message +=
                e.getTypeName() + ' ' + (i + 1) + ' \r\n' +
                '=====================================================================' + ' \r\n' +
                'TYPE : ' + e.getDmlType(i) +' \r\n' +
                'MESSAGE  : ' + e.getDmlMessage(i) +' \r\n' +
                'FAILED ROW POSITION : ' + e.getDmlIndex(i) + ' \r\n' +
                'FAILED RECORD ID : ' + e.getDmlId(i) + ' \r\n' +
                'FIELD NAMES : ' + e.getDmlFieldNames(i) + ' \r\n' +
                '=====================================================================' + ' \r\n';
        }
        return message;
    }
}