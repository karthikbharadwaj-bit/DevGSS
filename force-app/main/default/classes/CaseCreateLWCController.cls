public class CaseCreateLWCController {
    
    public static String readOnlyFields = System.label.Internal_Business_Service_Read_Only_Fields;
    
    /**
    * @description This method will get the form visibility & fetch the fields related to all Fieldset based on visibility
    * @author Shahanawaz Akhtar | 08/01/2025 @param String fieldSetName
    * @return Map<String, List<FieldWrapper>>
    */
    @AuraEnabled
    public static Map<String, List<FieldWrapper>> getFormVisibility(String caseOrigin){
        Boolean showForm = false;
                
        if(caseOrigin == CaseHelper.CASE_ORIGIN_CASE){
            return retrieveCaseFields();
        }
        
        Id profileId = UserInfo.getProfileId();
        String profileName = [Select Id, Name from Profile where Id =: profileId].Name;
        
        List<Case_Routing_SFDC__c> profilesList = Case_Routing_SFDC__c.getAll().values();
        for(Case_Routing_SFDC__c cr : profilesList){
            if(!String.isBlank(cr.Profile_Name__c) && !String.isBlank(profileName) && cr.Profile_Name__c.equalsIgnoreCase(profileName)){
                showForm = true;
                break;
            }
        }
        if(showForm){
            return retrieveCaseFields();
        }
        return null;
    }
    
    /**
    * @description This method will fetch the fields related to selected Fieldset for all the sections
    * @author Shahanawaz Akhtar | 08/01/2025 @param String fieldSetName
    * @return Map<String, List<FieldWrapper>>
    */
    @AuraEnabled 
    public static Map<String, List<FieldWrapper>> retrieveCaseFields() {
        Map<String, List<FieldWrapper>> fieldWrapperMap = new Map<String, List<FieldWrapper>>();
        fieldWrapperMap.put('Reference Information', getFieldSet('IBS_Reference_Information', 'Case'));
        fieldWrapperMap.put('Case Information', getFieldSet('IBS_Case_Information', 'Case'));
        fieldWrapperMap.put('Description Information', getFieldSet('IBS_Description_Information', 'Case'));
        fieldWrapperMap.put('Mandatory Information', getFieldSet('IBS_Mandatory_Fields', 'Case'));
        return fieldWrapperMap;
    }
    
    /**
    * @description This method will fetch the fields related to selected Fieldset
    * @author Shahanawaz Akhtar | 08/01/2025
    * @param String fieldSetName
    * @param String ObjectName
    * @return List<FieldWrapper>
    */
    @SuppressWarnings('PMD.GetGlobalDescribe')
    private static List<FieldWrapper> getFieldSet(String fieldSetName, String ObjectName) {
        List<FieldWrapper> lstfieldWrapper = new List<FieldWrapper>();
        if (String.isNotBlank(fieldSetName) && String.isNotBlank(ObjectName)) {
            Schema.DescribeSObjectResult describeSObjectResult = Schema.getGlobalDescribe().get(ObjectName).getDescribe();
            Map<String,Schema.SObjectField> objFieldMap = describeSObjectResult.fields.getMap();
            Schema.FieldSet fieldSetObj = describeSObjectResult.FieldSets.getMap().get(fieldSetName);
            if (fieldSetObj != null) {
                for(Schema.FieldSetMember fieldSet : fieldSetObj.getFields() ) {
                    lstfieldWrapper.add( new FieldWrapper(
                        String.ValueOf(fieldSet.getLabel()),
                        String.ValueOf(fieldSet.getFieldPath()), 
                        (fieldSet.getDBRequired() || fieldSet.getRequired())
                    ));
                }
            }
        }
        return lstfieldWrapper; 
    }
    
    /**
    * @description This method will insert the case & run assigment rules & insert files if present.
    * @author Shahanawaz Akhtar | 08/01/2025
    * @param Boolean runAssignmentRule
    * @param String caseJsonBody
    * @param String fileJsonBody
    * @return ResponseWrapper
    */
    @AuraEnabled
    public static ResponseWrapper insertCaseAndFile(Boolean runAssignmentRule, String caseJsonBody, String fileJsonBody){
        ResponseWrapper res = new ResponseWrapper();
        try{
            if(!String.isBlank(caseJsonBody)){
                Case cs = (Case)JSON.deserialize(caseJsonBody, Case.class);
                if(runAssignmentRule){
                    AssignmentRule AR = new AssignmentRule();
                    AR = [Select Id from AssignmentRule where SobjectType = 'Case' and Active = true limit 1];
                    Database.DMLOptions dmlOpts = new Database.DMLOptions();
                    dmlOpts.assignmentRuleHeader.assignmentRuleId = AR.Id;
                    cs.setOptions(dmlOpts);
                }
                insert cs;
                if(!String.isBlank(fileJsonBody)){
                    uploadFiles(cs.Id, fileJsonBody);
                }
                res.status = 'Success';
                res.msg = cs.Id;
            }
        }
        catch(Exception e){
            res.status = 'Error';
            res.msg = e.getMessage()+' '+e.getLineNumber()+'. Please contact system administrator.'; 
        }
        return res;
    }
    
    /**
    * @description This method will insert files.
    * @author Shahanawaz Akhtar | 08/01/2025
    * @param String recordId
    * @param String filedata
    */
    @AuraEnabled
    public static void uploadFiles(String recordId, String filedata) {
        List<FileDataWP> files = (List<FileDataWP>) JSON.deserialize(filedata, List<FileDataWP>.class);
        
        List<ContentVersion> cvList = new List<ContentVersion>();
        for(FileDataWP file : files) {
            ContentVersion conVer = new ContentVersion();
            conVer.ContentLocation = 'S';
            conVer.VersionData = EncodingUtil.base64Decode(file.fileContent);
            conVer.Title = file.fileName;
            conVer.PathOnClient = file.fileName;
            cvList.add(conVer);
        }
        insert cvList;
        
        List<ContentDocumentLink> cdList = new List<ContentDocumentLink>();
        for(ContentVersion cv : [SELECT ContentDocumentId FROM ContentVersion WHERE Id =: cvList]) {
            ContentDocumentLink conDocLink = New ContentDocumentLink();
            conDocLink.LinkedEntityId = recordId;
            conDocLink.ContentDocumentId = cv.ContentDocumentId;
            conDocLink.Visibility = 'AllUsers';
            conDocLink.shareType = 'V';
            cdList.add(conDocLink);
        }
        insert cdList;
    }
    
    /**
    * @description This method will desrialize string into map
    * @author Shahanawaz Akhtar | 06/02/2025
    * @param String encodedString
    * @return Map<String, String>
    */
    @AuraEnabled
    public static Map<String, String> deserializeToMap(String encodedString) {
        String decodedString = EncodingUtil.urlDecode(encodedString, 'UTF-8');
        Map<String, String> resultMap = new Map<String, String>();
        List<String> pairs = decodedString.split(',');

        for (String pair : pairs) {
            if (!String.isBlank(pair)) {
                List<String> keyValue = pair.split('=');
                if (keyValue.size() == 2) {
                    resultMap.put(keyValue[0], keyValue[1]);
                }
            }
        }
        return resultMap;
    }
    
    public class FileDataWP {
        public String fileName;
        public String fileContent;
    }
    
    public class FieldWrapper {
        @AuraEnabled public String fieldName {get;set;}
        @AuraEnabled public String fieldLabel {get;set;}
        @AuraEnabled public Boolean isRequired {get;set;}
        @AuraEnabled public Boolean isReadOnly {get;set;}
        
        public FieldWrapper(String fieldLabel,String fieldName,Boolean isRequired){
            this.fieldLabel = fieldLabel;
            this.fieldName = fieldName;
            this.isRequired = isRequired;
            if(readOnlyFields.containsIgnoreCase(fieldName)){
                this.isReadOnly  = true;
            }
            else{
                this.isReadOnly  = false;
            }
        }
    }
    
    public class ResponseWrapper {
        @AuraEnabled public String status;
        @AuraEnabled public String msg;
    }
    
}