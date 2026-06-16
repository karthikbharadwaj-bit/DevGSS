public without sharing class CaseAPIUtil {

    //Labels used in scCaseCreateLabel
    public static final String CORRECT = 'The below contact information is correct';
    public static final String ERROR_MESSAGE = 'Something goes wrong!';
    public static final String FIRST_NAME = 'First Name';
    public static final String LAST_NAME = 'Last Name';
    public static final String EMAIL = 'Email Address';
    public static final String PHONE = 'Phone';
    public static final String EXTENSION = 'Extension';
    public static final String CALLBACK_NUMBER_IS = 'Callback number is the same as Phone number?';
    public static final String CALLBACK_PHONE = 'Callback Number';
    public static final String YES = 'Yes';
    public static final String NO = 'No';
    public static final String SUBMIT_NOT_VALID = 'Some field is not filled.';
    public static final String SUBMIT_NOT_VALID_MESSAGE = 'Check that all fields are filled in correctly.';
    public static final String USER_REQUIRING_PA = 'User Requiring Privacy Action';
    public static final String EMAIL_PA = 'Email of user requiring privacy action';
    public static final String PHONE_PA = 'RC Phone number (if applicable) of user requiring privacy action';
    public static final String CITIZEN_EU = 'Is this user a Citizen or legal resident within the EU (including UK)?';
    public static final String DESCRIBE = 'Describe Nature of Data Request';
    public static final String VIEW = 'View';
    public static final String DOWNLOAD = 'Download';
    public static final String CHANGE = 'Change';
    public static final String DEL = 'Delete';
    public static final String ANALYTICS = 'Retain Analytics Data';
    public static final String GLIP = 'Retain Glip Messages';
    public static final String COMMENTS = 'Comments (Please list examples)';
    public static final String ATTACHMENTS = 'You can add attachments after the case has been created.';
    public static final String PRODUCT_PLACEHOLDER = 'Please select product area';
    public static final String ISSUE_PLACEHOLDER = 'Please select product issue';
    public static final String NEED_ASSISTS = 'I Need Assistance With';
    public static final String NEED_ASSISTS_BOLD = '(Privacy Requester: Please select GDPR Request here)';
    public static final String NOTE = '** Note: This Developer Platform category specifically caters to Developers working with Platform APIs and Sandbox environment **';
    public static final String SEVERITY_DEFINITIONS = 'Severity Definitions';
    public static final String SEVERITY_PLACEHOLDER = 'Please select severity level';
    public static final String SEVERITY = 'Severity Level';
    public static final String SEVERITY_HELP = 'For Severity 1 cases, please call RingCentral directly. The support number can be found';
    public static final String SEVERITY_HELP_LINK = 'Here';
    public static final String SUBJECT = 'Subject';
    public static final String DESCRIPTION = 'Description';
    public static final String SUBMIT = 'Submit';
    public static final String EMPTY_QUERY = 'Please enter Subject first';
    public static final String EMPTY_RESULTS = 'Related articles are not found';
    public static final String UPDATE_INFO = 'The update on the case that you have created will be sent to this email address:';
    public static final String SECOND_EMAIL = 'If the above email address will not reach the person managing this case, please provide an alternate email address:';
    public static final String EMAIL_HELP = 'To update your email address, go to http://service.ringcentral.com and click ‘My Settings’ on the menu bar, then on your name and extension on the left. Update your email in the middle column, and click save.';
    public static final String COPY_TO_CLIPBOARD = 'Copy to clipboard';
    public static final String COPY_SUCCESSFUL = 'Copying email to clipboard was successful!';
    public static final String COPY_NOT_SUPPORT = 'Copy to clipboard is not supported in your browser';
    public static final String SUBMITTING_CASE = 'Submitting the case...';
    public static final String MISSING_CORRECT = 'Please indicate if your contact information is correct or not.';
    public static final String MISSING_NUMBERS = 'Only numbers';
    public static final String MISSING_NUMBERS_FIVE = 'Only numbers, no longer than 5 characters';
    public static final String MISSING_DEFAULT = 'Please enter a value';
    public static final String MISSING_SUBJECT = 'Please enter a subject';
    public static final String MISSING_DESCRIPTION = 'Please enter a description';
    public static final String MISSING_EMAIL = 'Please enter an email in the format of name@domain.name';
    public static final String MISSING_CITIZEN = 'This checkbox is required';
    public static final String MISSING_SECOND_EMAIL = 'You did not confirm the contact email or entered it incorrectly';
    public static final String MISSING_SECOND_EMAIL_TITLE = 'Wrong contact email';
    public static final String TYPE_STRING = 'String';
    public static final String TYPE_BOOLEAN = 'Boolean';
    public static final String MESSAGE_FIELD_NAME = 'message';
    public static final String SUCCESS_FIELD_NAME = 'success';
    public static final String BAD_REQUEST_MESSAGE = 'HTTP error - Bad request';
    public static final String NOT_FOUND_MESSAGE = 'HTTP error - Not Found';
    public static final String ERROR_MESSAGE_INVALID_USERID_OR_EMAIL = NOT_FOUND_MESSAGE + ': User ID or email does not exist in Salesforce or there is a sync issue between Salesforce and Portal';
    public static final String ERROR_MESSAGE_MORE_THAN_ONE_CONTACT_FOUND = BAD_REQUEST_MESSAGE + ': More than one contact was found.';
    public static final String ERROR_MESSAGE_UID_EMAIL_ARE_REQUIRED = BAD_REQUEST_MESSAGE + ': User ID and Email are required.';
    public static final String ERROR_MESSAGE_INVALID_BRAND_PARAMETER = BAD_REQUEST_MESSAGE + ': Invalid brand parameter.';
    public static final String ERROR_MESSAGE_INVALID_LANGUAGE_PARAMETER = BAD_REQUEST_MESSAGE + ': Invalid language parameter.';
    public static final String ERROR_MESSAGE_ARTICLE_NOT_BELONG_TO_BRAND = BAD_REQUEST_MESSAGE + ': The urlName doesn\'t belong to the specified Brand parameter.';
    
    // RC Events
    public static final String ERROR_MESSAGE_RC_EVENTS_CONTACT_NOT_CONFIGURED = 'Default Contact settings are not configured for RC Events in Salesforce';
    public static final String ERROR_MESSAGE_RC_EVENTS_CONTACT_NOT_FOUND = NOT_FOUND_MESSAGE + ': The configured default Contact for RC Events could not be found in Salesforce';

    //Messages
    public static final String DOWNGRADE_MESSAGE = 'Thank you for contacting RingCentral. Our hours of operation '+
    'are Monday-Friday 6:00am - 6:00pm PT. Please contact us at the number below during these hours or leave a '+
    'message or agent will get back to you the next business day: 866-733-0810 (U.S. and Canada) '+
    '925-271-7320 (International)';
    public static final String SALES_MESSAGE = ' Thank you for your interest in obtaining RingCentral service for '+
    'your business. Please contact us at: 800-574-5290 (U.S. and Canada) 925-301-8209 (International)'+
    'Hours of operation are Monday-Friday 8:00am - 10:00pm ET. A customer sales agent will be happy to assist '+
    'you with your business needs';

    //Static values used in Support Community New Case
    public static final String[] SEVERITY_OPTIONS = new String[]{'Level 2 - Urgent','Level 3 - High','Level 4 - Medium'};
    public static final String GDPR_PICKLIST_VALUE = 'GDPR Request';
    public static final String SALES_PICKLIST_VALUE = 'Sales Inquiry or Upgrade';
    public static final String SERVICE_PICKLIST_VALUE = 'Service Downgrade or Cancellation';

    public static Boolean isGDPR(String option) {
        return option.equalsIgnoreCase(GDPR_PICKLIST_VALUE);
    }

    public static Boolean isSales(String option) {
        return option.equalsIgnoreCase(SALES_PICKLIST_VALUE);
    }

    public static Boolean hasSeverityOptions(String option) {
        return (!option.equalsIgnoreCase(GDPR_PICKLIST_VALUE) &&
                !option.equalsIgnoreCase(SALES_PICKLIST_VALUE) &&
                !option.equalsIgnoreCase(SERVICE_PICKLIST_VALUE));
    }

    public static Boolean hasMessageOption(String option) {
        return (option.equalsIgnoreCase(SALES_PICKLIST_VALUE) ||
                option.equalsIgnoreCase(SERVICE_PICKLIST_VALUE));
    }

    public static List<SCWrappers.GdprOption> getGdprOptionsList(String lang) {
        List<SCWrappers.GdprOption> gdprOptions = new List<SCWrappers.GdprOption>();

        SCWrappers.GdprOption firstNameOpt = new SCWrappers.GdprOption(TYPE_STRING, FIRST_NAME);
        gdprOptions.add(firstNameOpt);
        SCWrappers.GdprOption lastNameOpt = new SCWrappers.GdprOption(TYPE_STRING, LAST_NAME);
        gdprOptions.add(lastNameOpt);
        SCWrappers.GdprOption emailOpt = new SCWrappers.GdprOption(TYPE_STRING, EMAIL_PA);
        gdprOptions.add(emailOpt);
        SCWrappers.GdprOption phoneOpt = new SCWrappers.GdprOption(TYPE_STRING, PHONE_PA);
        gdprOptions.add(phoneOpt);
        SCWrappers.GdprOption euOpt = new SCWrappers.GdprOption(TYPE_BOOLEAN, CITIZEN_EU);
        gdprOptions.add(euOpt);
        SCWrappers.GdprOption viewOpt = new SCWrappers.GdprOption(TYPE_BOOLEAN, VIEW);
        gdprOptions.add(viewOpt);
        SCWrappers.GdprOption downloadOpt = new SCWrappers.GdprOption(TYPE_BOOLEAN, DOWNLOAD);
        gdprOptions.add(downloadOpt);
        SCWrappers.GdprOption changeOpt = new SCWrappers.GdprOption(TYPE_BOOLEAN, CHANGE);
        gdprOptions.add(changeOpt);
        SCWrappers.GdprOption deleteOpt = new SCWrappers.GdprOption(TYPE_BOOLEAN, DEL);
        gdprOptions.add(deleteOpt);
        SCWrappers.GdprOption analyticsOpt = new SCWrappers.GdprOption(TYPE_BOOLEAN, ANALYTICS);
        gdprOptions.add(analyticsOpt);
        SCWrappers.GdprOption glipOpt = new SCWrappers.GdprOption(TYPE_BOOLEAN, GLIP);
        gdprOptions.add(glipOpt);
        SCWrappers.GdprOption commentOpt = new SCWrappers.GdprOption(TYPE_STRING, COMMENTS);
        gdprOptions.add(commentOpt);

        Map<String, String> translatedLabelByValue = CaseHelper.getTranslatedLabelByValue(new String[]{'gdprOptions'}, lang);

        for (SCWrappers.GdprOption gdprOption : gdprOptions) {
            gdprOption.label = CaseHelper.getTranslatedLabel(translatedLabelByValue, gdprOption.label);
        }

        return gdprOptions;
    }

    public static Map<String, Object> addErrorMessage(Map<String, Object> res, String messageValue) {
        res.put(MESSAGE_FIELD_NAME, messageValue);
        res.put(SUCCESS_FIELD_NAME, false);
        return res;
    }
    
    public static Boolean hasBlankString(String[] values) {
        Boolean atLeastOneBlankString = false;
        for (String value : values) {
            if (String.isBlank(value)) {
                atLeastOneBlankString = true;
                break;
            }
        }
        return atLeastOneBlankString;
    }

    public static Contact getContact(String uid, String email, List<String> fields) {

        if (hasBlankString(new String[]{uid, email})) {
            throw new HandledException(ERROR_MESSAGE_UID_EMAIL_ARE_REQUIRED);
        }

        List<Contact> contacts = new ContactSelector()
            .selectContactForAPI(new List<Object>{uid, email}, fields)
            .executeQuery();

        verifyThereIsOnlyOneContact(contacts);

        return contacts[0];
    }

    public static Contact getDefaultContactForOpenRCEvents() {
        // If zero or more than one contact is found, we fetch the configured default contact.
        List<RC_Events_Setting__mdt> settings = [SELECT Setting_Type__c, Default_Contact_Email__c, Default_Contact_UID__c 
        FROM RC_Events_Setting__mdt WHERE Setting_Type__c = 'Default Contact' LIMIT 1];

        if (settings.isEmpty() || String.isBlank(settings[0].Default_Contact_Email__c) || String.isBlank(settings[0].Default_Contact_UID__c)) {
            throw new HandledException(ERROR_MESSAGE_RC_EVENTS_CONTACT_NOT_CONFIGURED);
        }

        String defaultEmail = settings[0].Default_Contact_Email__c;
        String defaultUid = settings[0].Default_Contact_UID__c;

        // Now, find the default contact based on the configured criteria.
        List<Contact> defaultContacts = new ContactSelector().selectContactForAPI(new List<Object>{
            defaultUid, defaultEmail
        }).executeQuery();

        if (defaultContacts.isEmpty()) {
            throw new HandledException(ERROR_MESSAGE_RC_EVENTS_CONTACT_NOT_FOUND);
        }

        return defaultContacts[0];
    }

    public static Contact getContactForOpenRCEvents(String firstName, String lastName, String email) {

        if (hasBlankString(new String[]{lastName, email})) {
            throw new HandledException(CaseCreateAPIController.ERROR_MESSAGE_NAME_EMAIL_ARE_REQUIRED);
        }

        List<Contact> contacts = (List<Contact>) new ContactSelector()
            .selectContactsByEmail(new List<Object>{new List<String>{firstName},
                                                    new List<String>{lastName},
                                                    new List<String>{email}})
            .executeQuery();

        if (contacts != null && contacts.size() == 1) {
            return contacts[0];
        }

        return null;
    }

    public static Contact getContact(String uid, String email) {

        if (hasBlankString(new String[]{uid, email})) {
            throw new HandledException(ERROR_MESSAGE_UID_EMAIL_ARE_REQUIRED);
        }

        List<Contact> contacts = new ContactSelector().selectContactForAPI(new List<Object>{
            uid, email
        }).executeQuery();

        verifyThereIsOnlyOneContact(contacts);

        return contacts[0];
    }

    public static void verifyThereIsOnlyOneContact(List<Contact> contacts){
        if (contacts.isEmpty()) {
            throw new HandledException(ERROR_MESSAGE_INVALID_USERID_OR_EMAIL);
        }

        if (contacts.size() > 1) {
            throw new HandledException(ERROR_MESSAGE_MORE_THAN_ONE_CONTACT_FOUND);
        }
    }

    public static RestResponse initRestResponse(RestResponse restResponse) {
        RestResponse res = restResponse == null ? new RestResponse() : restResponse;
        RestContext.response = res;
        res.statusCode = 200;
        return res;
    }
    
    public static Map<String, Object> deserializeRequest(String request) {
        Map<String, Object> req;

        try {
            // Deserialize JSON string into a map
            req = (String.isNotBlank(request)) ? (Map<String, Object>) JSON.deserializeUntyped(request) : new Map<String, Object>();
            
            // Add query string parameters from RestContext.request.params
            if (RestContext.request != null && RestContext.request.params != null) {
                for (String key : RestContext.request.params.keySet()) {
                    req.put(key, RestContext.request.params.get(key));
                }
            }
        } catch (Exception e) {
            throw new HandledException(CaseAPIUtil.BAD_REQUEST_MESSAGE);
        }

        return req;
    }

    public static void throwException(RestResponse res, Integer status, String message) {
        res.statusCode = status;
        AquivaHelper.throwAquivaException(message);
    }

    public static void throwException(RestResponse res, String message) {
        AquivaHelper.throwAquivaException(message);
    }

    public static void validateMessageField(RestResponse restResponse, Map<String, Object> response, String successMessage) {
        String message = (String) response.get(MESSAGE_FIELD_NAME);
        if (!message.equalsIgnoreCase(successMessage)) {
            throwException(restResponse, message);
        }
    }

    public static Integer getHTTPErrorCode(String message) {
        Integer httpStatusCode = 500; // Default to Internal Server Error
        if (message == null || message == '') {
            return httpStatusCode;
        }
        List<SC_API_HTTP_Error_Status_Code__mdt> httpStatusCodesList = SC_API_HTTP_Error_Status_Code__mdt.getAll().values();
        if (httpStatusCodesList != null && !httpStatusCodesList.isEmpty()) {
            for (SC_API_HTTP_Error_Status_Code__mdt statusCodeMdt : httpStatusCodesList) {
                if (message.toLowerCase().contains(statusCodeMdt.HTTP_Status_Message__c.toLowerCase())) {
                    httpStatusCode = Integer.valueOf(statusCodeMdt.HTTP_Status_Code__c);
                }
            }
        }
        return httpStatusCode;
    }
    
    public static void validateSuccessField(RestResponse restResponse, Map<String, Object> response) {
        Boolean successValue = (Boolean) response.get(SUCCESS_FIELD_NAME);
        String message = (String) response.get(MESSAGE_FIELD_NAME);
        if (!successValue) {
            throwException(restResponse, message);
        }
    }

    public static void constructErrorResponse(Exception e, RestRequest restRequest,RestResponse restResponse) {
        SCRestApiError scApiErr = new SCRestApiError(e, restRequest);
        restResponse.responseBody = Blob.valueOf(JSON.serialize(scApiErr));
        restResponse.statusCode = scApiErr.errorCode;
    }
}