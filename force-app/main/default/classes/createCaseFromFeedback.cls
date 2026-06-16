global class createCaseFromFeedback implements Messaging.InboundEmailHandler {

    private static final String ACCOUNT_ID_KEY = 'AccountId';
    private static final String CONTACT_ID_KEY = 'ContactId';
    private static final String CONTACTS_KEY = 'Contacts';

	global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope){
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
        try {
            String errors = '';

            String[] keysAndValues = splitEmailBody(email.plainTextBody, '_*_', '\n_\\*_');

            Map<String, String> fieldValueByKeyTag = new Map<String, String>();

            errors += deserializeEmailBody(keysAndValues, fieldValueByKeyTag);

            Map<String, Object> caseFieldValueByFieldName = new Map<String, Object>();

            errors += mapDeserializedEmailBodyToCase(caseFieldValueByFieldName, fieldValueByKeyTag);
                
            // Until this moment the ContactId value was null. It will be populated properly in this method.
            errors += processSpecialFields(caseFieldValueByFieldName);
            
            CaseWrapper caseWrapper = new CaseWrapper();
            
            caseWrapper = buildCase(caseWrapper, caseFieldValueByFieldName, email);

            errors += caseWrapper.error;
            if (String.isNotBlank(errors)) {
                caseWrapper.aCase.Technical_Issues__c = errors;
            }

            insert caseWrapper.aCase;

            List<attachment> attachList = new List<attachment>();
            
            attachList.addAll(textAttachmentsToAttachments(email.textAttachments, caseWrapper.aCase));
            attachList.addAll(binaryAttachmentsToAttachments(email.binaryAttachments, caseWrapper.aCase));

            if (!attachList.isEmpty()) {
                insert attachList;
            }

            result.success = true;
        }catch(Exception e){
            result.success = false;
        }
        return result;
    }

    /**
     * Deserialize email body and map values to Map<String, String>
     * key is the key tag in email 
     * value is the value for Case's field.
     * Return: error messages.
     */
    @testVisible
    private static String deserializeEmailBody(String[] keysAndValues, Map<String, String> fieldValueByKeyTag) {
        String errors = '';
        for (String keyAndValue : keysAndValues) {
            try {
                String[] separatedKeyAndValue = keyAndValue.split(':', 2);
                fieldValueByKeyTag.put(separatedKeyAndValue[0].trim(), separatedKeyAndValue[1].trim());
            } catch (Exception e) {
                errors += 'The following value: "<b>' + keyAndValue + '</b>" doesn\'t follow the structure <key>:<value>.<br>';
            }
        }
        return errors;
    }

    /**
     * Populates caseFieldValueByFieldName using fieldValueByKeyTag and "Medallia Mapping Email to Case" MDT
     * Key will be Field API Name
     * value will be the value for that field
     * Return: error messages.
     */
    @testVisible
    private static String mapDeserializedEmailBodyToCase(Map<String, Object> caseFieldValueByFieldName, Map<String, String> fieldValueByKeyTag) {
        String errors = '';

        Map<String, Medallia_Mapping_Email_to_Case__mdt> medalliaSurveyEmailMappingToCase = MedalliaSurveyHelper.getMedalliaSurveyEmailMappingToCase(
            CaseHelper.RT_NAME_CUSTOMER_FEEDBACK
        );

        for (String keyTag : fieldValueByKeyTag.keySet()) {
            try {
                Medallia_Mapping_Email_to_Case__mdt medalliaMapping = medalliaSurveyEmailMappingToCase.get(keyTag);
                String fieldApiName = medalliaMapping.Record_API_Name_Field__c;
                String fieldValue = fieldValueByKeyTag.get(keyTag);

                ProcessingWrapper processingWrapper = getFieldValue(
                    fieldApiName, 
                    fieldValue, 
                    medalliaMapping.Special_Logic__c
                );

                caseFieldValueByFieldName.put(
                    processingWrapper.fieldApiName,
                    processingWrapper.fieldValue
                );

            } catch (Exception e) {
                errors += 'The following value: "<b>' + 
                keyTag +'</b>: <b>'+ fieldValueByKeyTag.get(keyTag) + 
                '</b>" could not be deserialized. <b>Error Message</b>: '+ e.getMessage() +'<br>';
            }
        }

        return errors;
    }

    /**
     * Deserialize email body and map values to Map<String, String>
     * key is the key tag in email 
     * value is the value for Case's field.
     * Return: error messages.
     */
    @testVisible
    private static String[] splitEmailBody(String emailBody, String startsWith, String splitBy) {
        return emailBody.substringAfter(startsWith)
            .split(splitBy);
    }


    @testVisible
    private static CaseWrapper buildCase(
        CaseWrapper caseWrapper,
        Map<String, Object> caseFieldValueByFieldName,
        Messaging.InboundEmail email
    ) {
        try {
            caseWrapper.aCase = (Case) JSON.deserializeStrict(JSON.serialize(caseFieldValueByFieldName), Case.class);
        } catch(Exception e) {
            caseWrapper.error += 'Could not be possible populate the case properly. Error: ' + e.getMessage() + '<br>';
        }

        QueueSObject owner = (QueueSObject) new QueueSelector()
        .selectQueueByName(new List<Object> {'CIA Closed Loop'})
        .executeQuery()
        .get(0);

        caseWrapper.aCase.recordTypeId = CaseHelper.RT_ID_CUSTOMER_FEEDBACK;
        caseWrapper.aCase.priority = 'Medium';
        caseWrapper.aCase.origin = 'RC App';
        caseWrapper.aCase.ownerId = owner.QueueId;
        caseWrapper.aCase.subject = email.subject;
        caseWrapper.aCase.SuppliedEmail = 'noreply@app.medallia.com';
        caseWrapper.aCase.Description += '\n\nEmail Body:\n' + email.plainTextBody.replaceAll('_\\*_', '');
        caseWrapper.aCase.medallia_xm__Medallia_internal_id__c = getSurveyId(email.plainTextBody);

        return caseWrapper;
    }

    private static String getSurveyId (String emailBody) {
        String result = null;
        Pattern surveyIdPattern = Pattern.compile('(surveyid=)([0-9]+)');
        Matcher surveyIdMatcher = surveyIdPattern.matcher(emailBody);

        if (surveyIdMatcher.find() && surveyIdMatcher.groupCount() >= 2) {
            result = surveyIdMatcher.group(2);
        }
        
        return result;
    }

    @testVisible
    private static ProcessingWrapper getFieldValue(String fieldAPIName, Object valueInEmail, String specialLogic) {
        ProcessingWrapper processingWrapper = new ProcessingWrapper(fieldApiName, valueInEmail);
        
        switch on specialLogic {
            when 'Find Account' {
                processingWrapper.fieldValue = getAccountId((String) valueInEmail);
                processingWrapper.fieldApiName = ACCOUNT_ID_KEY;
            }
            when 'Find Contact' {
                /**
                 * Returns a Contact[] because at this point we still can't tell which account the Contact should belong to. 
                 * To maintain readability, it will be filtered afterwards.
                 *  */ 
                processingWrapper.fieldApiName = CONTACTS_KEY;
                processingWrapper.fieldValue = getContacts((String) valueInEmail);
            }
        }

        return processingWrapper;
    }

    @testVisible
    private static String processSpecialFields(Map<String, Object> caseFieldValueByFieldName) {
        String errorMessage = '';

        String accountId = caseFieldValueByFieldName.containsKey(ACCOUNT_ID_KEY) ?
            (String) caseFieldValueByFieldName.get(ACCOUNT_ID_KEY) :
            null;

        if (String.isBlank(accountId)) {
            errorMessage = 'The Account could not be assigned.'+ '<br>';
        }

        if (caseFieldValueByFieldName.containsKey(CONTACTS_KEY)) {

            Contact[] contactsWithSameEmail = (Contact[]) caseFieldValueByFieldName.remove(CONTACTS_KEY); 


            if (contactsWithSameEmail.size() == 1) {
                caseFieldValueByFieldName.put(CONTACT_ID_KEY, contactsWithSameEmail[0].Id);
            } else {
                errorMessage += 'The Contact could not be assigned. <b>Contacts found</b>: '+ contactsWithSameEmail.size() +'<br>';
            }
        }

        return errorMessage;
    }

    @testVisible
    private static List<Attachment> textAttachmentsToAttachments(
        Messaging.Inboundemail.TextAttachment[] textAttachments,
        Case parentCase
    ) {
        List<Attachment> attachments = new List<Attachment>();
        if (textAttachments != null) {
            for (Messaging.Inboundemail.TextAttachment tAttachment : textAttachments) {
                attachments.add(new Attachment(
                    name = tAttachment.fileName,
                    body = Blob.valueOf(tAttachment.body),
                    parentId = parentCase.Id
                ));
            }
        }
        return attachments;
    }

    @testVisible
    private static List<Attachment> binaryAttachmentsToAttachments(
        Messaging.Inboundemail.binaryAttachment[] binaryAttachments,
        Case parentCase
    ) {
        List<Attachment> attachments = new List<Attachment>();
        if (binaryAttachments != null) {
            for (Messaging.Inboundemail.BinaryAttachment bAttachment : binaryAttachments) {
                attachments.add(new Attachment(
                    name = bAttachment.fileName,
                    body = bAttachment.body,
                    parentId = parentCase.Id
                ));
            }
        }
        return attachments;
    }

    @testVisible
    private static Id getAccountId(String uid) {
        return (Id) new AccountSelector()
            .selectAccountsByUserIds(new Object[]{new String[]{uid}})
            .executeQuery()[0].Id;
    }

    @testVisible
    private static Contact[] getContacts(String email) {
        return  (Contact[]) new ContactSelector()
            .selectContactByMail(new Object[]{email})
            .executeQuery();
    }

    public class ProcessingWrapper{
        String fieldApiName;
        Object fieldValue;

        ProcessingWrapper(String fieldApiName, Object fieldValue){
            this.fieldApiName = fieldApiName;
            this.fieldValue = fieldValue;
        }
    }

    public class CaseWrapper{
        Case aCase;
        String error;

        CaseWrapper() {
            this.aCase = new Case();
            this.error = '';
        }
    }
}