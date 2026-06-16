public with sharing class SCRestApiError {
    public String errorMessage;
    public String errorStackTrace;
    public Integer errorLine;

    transient public Integer errorCode;

    public SCRestApiError(Exception ex) {
        this.errorMessage = ex.getMessage();
        this.errorStackTrace = ex.getStackTraceString();
        this.errorLine = ex.getLineNumber();
    }

    private String getValueByKeyContains(Map<String, Object> reqObject, String keySubstring) {
        for (String key : reqObject.keySet()) {
            if (key.toLowerCase().contains(keySubstring.toLowerCase())) {
                return String.valueOf(reqObject.get(key));
            }
        }
        return null; // Return null if no matching key is found
    }

    public String customizeExceptionMessage(Exception e) {
        String customErrMessage = '';
        String standardErrMessage = e.getMessage();
        List<SC_API_Custom_Error_Message__mdt> errorCodeMappings = SC_API_Custom_Error_Message__mdt.getAll().values();
        if (errorCodeMappings != null && !errorCodeMappings.isEmpty()) {
            for (SC_API_Custom_Error_Message__mdt mapping : errorCodeMappings) {
                if (standardErrMessage.contains(mapping.SF_Error_Code__c)) {
                    customErrMessage = mapping.Custom_Error_Message__c;
                    this.errorCode = Integer.valueOf(mapping.HTTP_Status_Code__c);
                    break;
                }
            }
        }
        if (this.errorCode == null) {
            this.errorCode = CaseAPIUtil.getHTTPErrorCode(standardErrMessage);
        }
        return customErrMessage;
    }

    private String applyErrorLogMessage(Exception ex, RestRequest req) {
        String standardErrMessage = ex.getMessage();
        String customErrMessage = customizeExceptionMessage(ex);
        this.errorMessage = customErrMessage != '' ? customErrMessage : standardErrMessage;
        this.errorMessage += (req.requestBody == null || req.requestBody.toString() == '')
            ? '. Params: ' + String.valueOf(req.params)
            : '. Body: ' + req.requestBody.toString();
        this.errorStackTrace = ex.getStackTraceString();
        this.errorLine = ex.getLineNumber();

        String logMessage = (customErrMessage == '') ?
         'Salesforce Error Message: ' + this.errorMessage 
         : this.errorMessage + ' \n Salesforce Error Message: ' + standardErrMessage;

         return logMessage;
    }
    
    public SCRestApiError(Exception ex, RestRequest req) {
        String uid =  '';
        String email = '';
        
        // GET Request
        if ((req.requestBody == null || req.requestBody.toString() == '') && req.params != null) {
            uid =  req.params.get('uid');
            email = req.params.get('email');
        } else { // POST Request
            Map<String, Object> reqBody ;
            try{
            reqBody = CaseAPIUtil.deserializeRequest(req.requestBody.toString());
            } catch (Exception e) {
                // Handle the case where the request body is not a valid JSON
                System.debug('Error parsing request body: ' + e.getMessage());               
            }
            if (reqBody != null) {
                // Extract value for keys containing "email"
                uid = getValueByKeyContains(reqBody, 'uid');
                email = reqBody.get('userEmail') != null ? (String)reqBody.get('userEmail') : getValueByKeyContains(reqBody, 'email');
            }
        }
        String logMessage = applyErrorLogMessage(ex, req);
        Exception_And_Notification_History__c exceptionObj = new Exception_And_Notification_History__c();
            exceptionObj.Object_Type__c = 'Exception';
            exceptionObj.content_label_01__c = 'File Associated';
            exceptionObj.content_label_02__c = 'Line Number';
            exceptionObj.content_label_03__c = 'Exception';
            exceptionObj.content_label_04__c = 'Get Stack Trace String';
            exceptionObj.content_label_05__c = 'Details';
            exceptionObj.content_label_06__c = 'UID';
            exceptionObj.content_label_07__c = 'Email';
            exceptionObj.content_var_01__c = req.requestURI;
            exceptionObj.content_var_06__c = uid;
            exceptionObj.content_var_07__c = email;
            exceptionObj.File_Associated__c = 'SCRestApiError';
            exceptionObj.Exception_Desc__c = logMessage;
            ExceptionAndNotificationHelper.trackExceptions(exceptionObj, ex, ExceptionAndNotificationHelper.SCRESTAPIEXCEPTION_RECORD_TYPE);
    }

    public SCRestApiError(String errorMessage) {
        this.errorMessage = errorMessage;
    }

}