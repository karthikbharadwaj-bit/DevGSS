public without sharing class EuprivacyFieldsetControllerNew {
    public static DescribeSObjectResult sObjectResult;
    public static String objectName;
    
    @AuraEnabled(Cacheable=true)
    public static MetadataResponse getFieldSetMetadata(Id recordId, String fieldSet) {
        String fieldsetName;
        if(fieldSet != null && fieldSet != '') {
            fieldsetName = fieldSet;
        } else {
            fieldsetName = 'CustomerInfo';
        }
        
        // Setup response object
        MetadataResponse response = new MetadataResponse();
        try {
            // Get the SObject
            response = getObjectMetadata(recordId);
            response.sObjectName = sObjectResult.getName();
            // Handle Errors
            if (String.isBlank(fieldsetName)) {
                newException('Fieldset Name required to get Field Metadata', null);
            }
            // Get the FieldSets
            Map<String, FieldSet> fieldSets = sObjectResult.fieldSets.getMap();
            // Check if we have a fieldset with that name
            if (fieldSets.containsKey(fieldSetName)) {
                // Get the Object fields
                Map<String, SObjectField> fields = sObjectResult.fields.getMap();
                // For each field in the FieldSet
                response.fieldNamesMap = new Map<String, List<String>>();
                response.fieldTypeMap = new Map<String, Schema.DisplayType>();
                Map<String, Boolean> isFormattedMap = new Map<String, Boolean>();
                for (FieldSetMember fieldSetMember : fieldSets.get(fieldSetName).getFields()) {
                    // Get the path
                    String fieldName = fieldSetMember.getFieldPath();
                    
                    // We can't handle Relationship fields
                    if (!fieldName.contains('.') ) {
                        // Get the field describe
                        DescribeFieldResult fd = fields.get(fieldName).getDescribe();
                        
                        if(fd.getType()!= null && String.valueOf(fd.getType())=='REFERENCE') {
                            String fieldLabelIdString = fd.getLabel() + ' Id';
                            response.fieldNamesMap.put(fd.getName(), new List<String>{fieldLabelIdString});
                            response.fieldTypeMap.put(fd.getName(), fd.getType());
                            isFormattedMap.put(fd.getName(), fd.isHtmlFormatted());
                            string fieldAPIName = fd.getRelationshipName() + '.Name';
                            response.fieldNamesMap.put(fieldAPIName, new List<String>{fd.getLabel()});
                            response.fieldTypeMap.put(fd.getName(), fd.getType());   
                            isFormattedMap.put(fd.getName(), fd.isHtmlFormatted());
                        } else {
                            response.fieldNamesMap.put(fd.getName(), new List<String>{fd.getLabel()});
                            response.fieldTypeMap.put(fd.getName(), fd.getType());
                            isFormattedMap.put(fd.getName(), fd.isHtmlFormatted());
                        }
                    } else {
                        newException('Relationship Fields not supported FieldSet: "'+fieldSetName+'" Field Name: "'+fieldName+'"', null);
                    }                    
                }
                 response = getRecordDetails(response.fieldNamesMap, response.fieldTypeMap,isFormattedMap, recordId);
                
            } else {
                newException('Fieldset "'+fieldSetName+'" not found for SObject "'+sObjectResult.getName()+'"', null);
            }
        } catch (Exception ex) {
            newException(ex.getMessage(), ex.getStackTraceString());
        }
        return response;
    }
    
    @AuraEnabled(Cacheable=true)
    public static MetadataResponse getRecordDetails(Map<String, List<String>> fieldMap, Map<String, Schema.DisplayType> fieldTypeMap,Map<String,Boolean> isFormattedMap, String recordId) {
        MetadataResponse response = new MetadataResponse();
        response.fieldNamesMap = new Map<String, List<String>>();
        String qryString = 'SELECT Id ';
        if(!fieldMap.isEmpty()) {
            for(String str : fieldMap.keySet()) {
                qryString+= ','+str;
            }
            
            if(objectName == 'Account') {
                qryString += ','+'BillingCountry, SM_Country__c, RC_Brand__c, RC_Account_Status__c';
            } else if(objectName == 'Contact' || objectName == 'Case') {
                qryString += ','+'Account.BillingCountry, Account.SM_Country__c, Account.RC_Brand__c, Account.RC_Account_Status__c';
            } else if(objectName == 'Opportunity') {
                qryString += ','+'Account.BillingCountry,Account.SM_Country__c,Account.RC_Brand__c,Account.RC_Account_Status__c,Primary_Opportunity_Contact__r.Account.BillingCountry, Primary_Opportunity_Contact__r.Account.SM_Country__c, Primary_Opportunity_Contact__r.Account.RC_Brand__c, Primary_Opportunity_Contact__r.Account.RC_Account_Status__c';
            } else if(objectName == 'LiveChatTranscript') {
                qryString += ','+'Case.Account.BillingCountry, Case.Account.SM_Country__c, Case.Account.RC_Brand__c, Case.Account.RC_Account_Status__c';
            }
        }
        qryString += ' FROM '+objectName+' where Id='+'\''+recordId+'\''+' LIMIT 1';
        List<FieldDefinition> FieldDefLst = new List<FieldDefinition>();
        List<SObject> dataResults = Database.query(qryString);
        for(String fld : fieldMap.keySet()) {
            response.fieldNamesMap.put(fld, fieldMap.get(fld));
            for(Sobject sObj : dataResults) {
                String fValue = '';
                if(!fld.contains('.')) {
                    fValue = String.valueOf(sObj.get(fld));
                    response.fieldNamesMap.get(fld).add(fValue);
                } else {
                    //reference field
                    List<String> fieldsString = fld.split('\\.');
                    for(integer i; i<fieldsString.size() ; i++){
                        
                    }
                    for(String s: fld.split('.')) {
                        
                    }
                    if(sObj.getSObject(fieldsString[0]) != null) {
                        fValue = String.valueOf(sObj.getSObject(fieldsString[0]).get(fieldsString[1]));    
                    }
                    
                    response.fieldNamesMap.get(fld).add(fValue);
                }
                
                
                FieldDefinition fieldDef = new FieldDefinition();
                fieldDef.fieldAPIName = fld;
                fieldDef.fieldLabel = fieldMap.get(fld)[0];
                fieldDef.fieldValue = String.valueOf(fValue);
                if(fieldTypeMap.get(fld) == Schema.DisplayType.Reference) {
                    fieldDef.fieldType = 'string';
                }
                if(fieldTypeMap.get(fld) == Schema.DisplayType.String) {
                    fieldDef.fieldType = 'string';
                } else if(fieldTypeMap.get(fld) == Schema.DisplayType.Email) {
                    fieldDef.fieldType = 'email';
                } else if(fieldTypeMap.get(fld) == Schema.DisplayType.Phone) {
                    fieldDef.fieldType = 'Phone';
                }
                
                if (!fld.contains('.') ) {
                    fieldDef.isEditable = isFieldEditable(fld);
                }else{
                    fieldDef.isEditable = false;
                }
                if(isFormattedMap != null && isFormattedMap.get(fld) != null)
                {
                    fieldDef.isHTMLFormatted = isFormattedMap.get(fld);
                }
                else
                {
                    fieldDef.isHTMLFormatted = false;
                }
                FieldDefLst.add(fieldDef);
            }
        }
        response.fieldDefinitionsLst = FieldDefLst;
        response.fieldTypeMap = fieldTypeMap;
        
        EUPrivacy eu = new EUPrivacy();
        response.showComponent = String.isNotBlank(recordId) ? eu.showComponent(Id.valueOf(recordId), 'EuprivacyFieldsetControllerNew'): false;
        System.debug('::: Final Map - '+response);
        return response;
    }
    
    @AuraEnabled(Cacheable=true)
    public static MetadataResponse getObjectMetadata(Id recordId) {
        // Setup response object
        MetadataResponse response = new MetadataResponse();
        try {
            // Handle Errors
            if (String.isBlank(recordId)) {
                newException('Record Id required to identify SObjectType', null);
            }
            // Get the SObject
            sObjectResult = recordId.getSobjectType().getDescribe();
            objectName = sObjectResult.getName();
        } catch (Exception ex) {
            newException(ex.getMessage(), ex.getStackTraceString());
        }
        // Return metadata
        return response;
    }
    
    @AuraEnabled
    public static void savePIIUpdates(Id recordId, String inputString) {
        try{
            List<Object> fieldList = (List<Object>)JSON.deserializeUntyped(inputString);
            sObjectResult = recordId.getSobjectType().getDescribe();
            String objName = sObjectResult.getName();     
            sObject sObj = ((SObject)Type.forName(objName).newInstance()).getSObjectType().newSObject();
            sObj.put('Id', recordId);
            
            for(Object fld : fieldList){
                Map<String,Object> data = (Map<String,Object>)fld;
                if(!String.valueOf(data.get('key')).contains('.')){    
                    String FieldName = String.valueOf(data.get('key'));
                    if(isFieldEditable(FieldName)){
                        Object fieldValue = getValueInCorrectDataType(objName,FieldName,String.valueOf(data.get('value')));
                        sObj.put(FieldName, fieldValue);
                    }        
                }
            }
            
            Update sObj;
        }catch(Exception ex){
            system.debug('savePIIUpdates - ex: '+ex);
            String errorMsg = ex.getMessage();
            String pureErrorMsg = errorMsg.substringAfter('_EXCEPTION,');
            throw new AuraHandledException(pureErrorMsg);
        }
    }
    
    @AuraEnabled
    public static Boolean isFieldEditable(String FieldName){
        Boolean retVal = false;
        //try {
        String objName = sObjectResult.getName();
        Schema.SObjectField fld = sObjectResult.fields.getMap().get(FieldName);
        List<String> standardContactFields= new List<String>();
        if(objName.toLowerCase() == 'case') {
            standardContactFields.add('ContactEmail');
            standardContactFields.add('ContactPhone');
            standardContactFields.add('ContactMobile');
            standardContactFields.add('ContactFax');
        }
        system.debug('fld :'+fld);
        system.debug('Field Name :'+FieldName);
        Boolean isUpdateable = fld.getDescribe().isUpdateable();
        Boolean isCreateable = fld.getDescribe().isCreateable();
        Boolean isAccessible = fld.getDescribe().isAccessible();
        Boolean isCalculated = fld.getDescribe().isCalculated();
        
        if(isCalculated){
            retVal=false;
        }else{
            retVal=true;
        } 
        //only for case we are returning values as false because they are standard and can not be modified
        if(standardContactFields.contains(FieldName)) {
            retVal=false;
        }
        return retVal;
    }
    
    private static Object getValueInCorrectDataType(String sOb, String sField, String sValue)
    {
        // Convert value from a string to the correct data type of the field
        // and return the new data type
        
        Object retOb = sValue;
        if(sValue==''){
            return retOb = null;
        }
        Schema.Displaytype fieldType = ((SObject)Type.forName(sOb).newInstance()).getSObjectType().getDescribe().Fields.getMap().get(sField).getDescribe().getType();
        
        if (fieldType==Schema.Displaytype.Id)
        {
            Id retObBool = Id.valueOf(sValue);
            retOb = retObBool;
        }
        if (fieldType==Schema.Displaytype.Boolean)
        {
            Boolean retObBool = Boolean.valueOf(sValue);
            retOb = retObBool;
        }
        if (fieldType==Schema.Displaytype.Date)
        {
            Date retObDate = Date.valueOf(sValue);
            retOb = retObDate;
        }
        if (fieldType==Schema.Displaytype.DateTime)
        {
            DateTime retObDateTime = DateTime.valueOf(sValue);
            retOb = retObDateTime;
        }
        if (fieldType==Schema.Displaytype.Double)
        {     
            Double retObDouble = Double.valueOf(sValue);
            retOb = retObDouble;        
        }
        if (fieldType==Schema.Displaytype.Currency)
        {
            Double retObDouble = Double.valueOf(sValue);
            retOb = retObDouble;
        }
        if (fieldType==Schema.Displaytype.Integer)
        {
            Integer retObInteger = Integer.valueOf(sValue);
            retOb = retObInteger;        
        }
        
        return retOb;
    }
    
    private static void newException(String exceptionMessage, String stackTraceString) {
        AuraHandledException ex = new AuraHandledException(exceptionMessage);
        ex.setMessage(exceptionMessage + (String.isNotBlank(stackTraceString) ? ' ' + stackTraceString : ''));
        throw ex;
    }
    
    public class MetadataResponse {
        @AuraEnabled public String sObjectName;
        @AuraEnabled public Boolean showComponent;
        @AuraEnabled public Map<String, List<String>> fieldNamesMap{get;set;}
        @AuraEnabled public Map<String, Schema.DisplayType> fieldTypeMap{get;set;}
        @AuraEnabled public List<FieldDefinition> fieldDefinitionsLst{get;set;}
    }
    
    public class FieldDefinition {
        @AuraEnabled
        public String fieldLabel {get;set;}
        @AuraEnabled
        public String fieldAPIName {get;set;}
        @AuraEnabled
        public String fieldType {get;set;}
        @AuraEnabled
        public String fieldValue {get;set;}
        @AuraEnabled
        public Boolean isEditable {get;set;}
        @AuraEnabled
        public Boolean isHTMLFormatted {get;set;}
    }
    
}