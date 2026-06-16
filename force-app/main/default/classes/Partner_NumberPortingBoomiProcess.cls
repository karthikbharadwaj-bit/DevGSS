/*
 * @Created By : Ratul Saha
 * @Created Date : 10/August/2020
 * @Purpose : Number Porting Integration - Boomi Process version
 * @Test Class : Test_Partner_NumberPorting
 * */
public with sharing class Partner_NumberPortingBoomiProcess{
  /**LERGERATOR US Specific constants*/
  private final static String LergUS_numberbrand = 'number_brand';

  /**GPFS specific constants*/
  private final static String GPFS_number = 'number';
  private final static String GPFS_brand = 'brand';
  private final static String GPFS_countryabbr = 'country_abbr';
  private final static String GPFS_yes = 'YES';
  private final static String GPFS_message = 'message';
    
    /*Miscellaneous constants*/
    private final static String SYSADMIN_PROFILE = 'System Administrator';
  private final static String REQUEST_FILE_KEY = 'APIRequest';
  private final static String REQUEST_BULK_FILE_KEY = '-Bulk-';
  private final static String RESULTS_FILE_KEY = 'Result';
  private final static String Lergerator_UK = 'Lergerator_UK';
  private final static String Lergerator_US = 'Lergerator_US';
  private final static String GPFS = 'GPFS';
  private final static String BOOMI = 'BOOMI';
  private final static String callout = 'callout:';
  private final static String HTTP_POST = 'POST';
    private final static String RESPONSE_CODE_SUCCESS = 'Success';
    private final static String RESPONSE_CODE_ERROR = 'Error';
    private final static String REQUEST_TYPE_BULK = 'Bulk CSV';
    private final static String REQUEST_TYPE_MANUAL = 'Manual Input';
    private final static String PORTABLE_YES = 'Yes';
    private final static String PORTABLE_NO = 'No';
    private final static String TOLL_FREE_STRING = 'Toll-Free';
  private final static String NON_TOLL_FREE_STRING = 'Non Toll-Free';
  private final static String EU = 'EU';
  private final static String Success = 'Success';
  private final static String Failure = 'Failure';
  private final static String Others = 'Others';
  private final static String genericExceptionMessage = 'An internal error has occured. Please contact the administrator.';

  @AuraEnabled
  public static List<NumberPortingMappingWrapper> getNumberPortingMappingDetails(){
    List<NumberPortingMappingWrapper> npmList = new List<NumberPortingMappingWrapper>();
    List<Number_Porting_Mapping__mdt> mappingList = [Select Country__c, Country_Code__c, Country_ISO_Code__c, Brand_Code__c, Example_Numbers__c
                                                     from Number_Porting_Mapping__mdt where Is_Active__c = true
                             order by Country__c ASC];
    List<Number_Porting_API_Mapping__mdt> numberPortingApiMapping = [
      Select Country_ISO_Codes__c, API_Request_Limit__c from Number_Porting_API_Mapping__mdt];
    Map<String, Integer> countryApiLimitMap = new Map<String, Integer>();
    for(Number_Porting_API_Mapping__mdt mapping: numberPortingApiMapping) {
      countryApiLimitMap.put(mapping.Country_ISO_Codes__c, Integer.valueOf(mapping.API_Request_Limit__c));
    }

    System.debug(countryApiLimitMap);
    Integer gpfsApiLimit = countryApiLimitMap.get(Others);
    for (Number_Porting_Mapping__mdt npm : mappingList){
      NumberPortingMappingWrapper np = new NumberPortingMappingWrapper(npm.Country__c, npm.Country_Code__c, npm.Country_ISO_Code__c, npm.Brand_Code__c, npm.Example_Numbers__c, !countryApiLimitMap.containsKey(npm.Country_ISO_Code__c) ? gpfsApiLimit : countryApiLimitMap.get(npm.Country_ISO_Code__c));
      npmList.add(np);
    }
    return npmList;
  }

  @AuraEnabled
  public static StageOneResponseWrapper generateNumberPortingRequest(String countryName, String countryIsoCode, String brandCode, Integer requestSize, Boolean isBulk, String uploadCSV, String csvFileName, List<String> numberList) {
    Integer responseCode = 500;
    String responseMessage = 'Checking portability....';
        DateTime requestDateTime = Datetime.now();
        
        //Retrieve API identifier and Brand Name
    Map<String, String> apiIdentifierAndBrandName = getAPIIdentifierAndBrandName(countryIsoCode);
    String apiIdentifier = new List<String>(apiIdentifierAndBrandName.keySet())[0];
    String brandName = apiIdentifierAndBrandName.get(apiIdentifier);

    //Create Request Body/Query String in x-www-form-urlencoded format
    List<String> requestBodies = constructRequestBodies(apiIdentifier, brandCode, numberList);

    //Create request history object
    Id portingRequestId;
    Map<String, String> portingRequestResultMap = insertPortabilityRequestData(
      brandCode,
      brandName,
      countryIsoCode,
            countryName,
      requestDateTime, 
      requestSize,
      isBulk, 
      uploadCSV,
      csvFileName, 
      requestBodies
    );
    if(portingRequestResultMap.containsKey('error')) {
      //responseMessage = genericExceptionMessage;
      responseMessage = portingRequestResultMap.get('error');
      responseCode = 400;
    }
    else {
      responseCode = -1;
      portingRequestId = Id.valueOf(portingRequestResultMap.get('success'));
    }

    //Get expectedFileCount
    Integer expectedResponseFileCount = 0;
    if(apiIdentifier == Lergerator_US) {
      expectedResponseFileCount += (requestBodies[0] == null || requestBodies[0] == '' ? 0 : 1);
      expectedResponseFileCount += (requestBodies[1] == null || requestBodies[1] == '' ? 0 : 1);
    }
    else {
      expectedResponseFileCount = 1;
    }
    return new StageOneResponseWrapper(apiIdentifier, brandName, brandCode, String.valueOf(portingRequestId), responseCode, responseMessage, expectedResponseFileCount);
  }

  @AuraEnabled
  public static StageTwoResponseWrapper checkPortability(String brandCode, String brandName, String apiIdentifier, String portingRequestId){
    List<String> jsonResponseBodies = new List<String>();
    Integer responseCode = 500; //Add logic to set based on HTTPResponse
    String responseMessage = 'Porting check request failed'; //Add logic to set based on HTTPResponse
    List<Integer> failCodes = new List<Integer>{400, 401, 402, 403, 404, 429, 500, 501, 502, 503, 504, 505}; //Some common HTTP error codes

    if(portingRequestId != null) {
      //Call Boomi process
      try {
                boomiApiCallout(brandName, apiIdentifier, Id.valueOf(portingRequestId));
        responseCode = -1; //Set as -1 to keep FE spinner spinning
        responseMessage = 'Processing results....';
      }
      catch (Exception excp) {
                responseMessage = excp.getMessage();
        for(Integer i: failCodes) {                    
          if(responseMessage.contains(String.valueOf(i))) {
            responseCode = i;                        
            break;
                    }
        }
      }
    }

    return new StageTwoResponseWrapper(responseCode, responseMessage);
  }
  
  //Translation Start
    @AuraEnabled
    public static CommunityInfo.Translationswrap getTranslations(String objNames)
    {        
        return CommunityInfo.getTranslations(objNames);
    }    
    //Translation End

  @AuraEnabled
  public static string getProcessExecutionStatus(String portingRequestId) {
    String httpMethod = HTTP_POST;
    String endpoint = callout + 'BOOMI_Process_Status';
    Map<String, String> headerDetails = new Map<String, String>();
    headerDetails.put('Content-Type', 'application/json;charset=UTF-8');
    headerDetails.put('Accept', 'application/json;charset=UTF-8');

    Number_Portability_Request__c portingRequest = [Select API_Response_Raw_Text__c from Number_Portability_Request__c where Id =: portingRequestId];
    //Generate Request
    JSONGenerator generator = JSON.createGenerator(true);
    generator.writeStartObject();
    generator.writeFieldName('QueryFilter');
    generator.writeStartObject();
    generator.writeFieldName('expression');
    generator.writeStartObject();
    generator.writeFieldName('argument');
    generator.writeStartArray();
    generator.writeString(portingRequest.API_Response_Raw_Text__c == null ? '' : portingRequest.API_Response_Raw_Text__c);
    generator.writeEndArray();
    generator.writeStringField('operator', 'EQUALS');
    generator.writeStringField('property', 'executionId');
    generator.writeEndObject();
    generator.writeEndObject();
    generator.writeEndObject();

    try {
      HttpResponse response = APIUtility.makeHTTPRequest(endpoint, httpMethod, headerDetails, generator.getAsString());
      return response.getBody();
    }
    catch(Exception excp) {
      return excp.getMessage();
    }
  }
  
    @AuraEnabled
    public static Integer getContentDocumentCount(String portingRequestId){
        List<ContentDocumentLink> contentLinks = [SELECT Id FROM ContentDocumentLink where LinkedEntityId =: Id.valueOf(portingRequestId)];
        return contentLinks.size();
    }
    
    @AuraEnabled
    public static StageThreeResponseWrapper getPortabilityCheckResults(String apiIdentifier, String brandName, String countryName, String portingRequestId, Boolean isBulk) {
        List<NumberPortingResponse> responseList = new List<NumberPortingResponse>();
        List<String> jsonResponseBodies = new List<String>();
        Integer responseCode = 200; //Add logic to set based on HTTPResponse
    String responseMessage = RESPONSE_CODE_SUCCESS; //Add logic to set based on HTTPResponse
    
    try {
      if (apiIdentifier.equals(Lergerator_US)){
        jsonResponseBodies.add('');
        jsonResponseBodies.add('');
        List<ContentDocumentLink> contentDocumentLinks = [SELECT ContentDocumentId FROM ContentDocumentLink where LinkedEntityId =: Id.valueOf(portingRequestId)];
        Set<Id> documentIds = new Set<Id>();
        for(ContentDocumentLink documentLink: contentDocumentLinks) {
          documentIds.add(documentLink.ContentDocumentId);
        }
        List<ContentVersion> contentVersions = [SELECT VersionData, Title FROM ContentVersion WHERE ContentDocumentId in :documentIds AND IsLatest = true];
        for(ContentVersion contentVersion: contentVersions) {
          if(contentVersion.Title.contains('V1.JSON')) { //Toll-Free goes here
            jsonResponseBodies[0] = contentVersion.VersionData.toString();
          }
          if(contentVersion.Title.contains('V2.JSON')) { //Non Toll-Free goes here
            jsonResponseBodies[1] = contentVersion.VersionData.toString();
          }
        }
      } else{ //GPFS & Lergerator UK
        List<ContentDocumentLink> contentLinks = [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink where LinkedEntityId =: Id.valueOf(portingRequestId)];
        ContentVersion contentVersion = [SELECT VersionData FROM ContentVersion WHERE ContentDocumentId =: contentLinks[(isBulk) ? 2 : 1].ContentDocumentId AND IsLatest = true];
        jsonResponseBodies.add(contentVersion.VersionData.toString());
      }
      responseList = parseResponseBodies(apiIdentifier, brandName, countryName, jsonResponseBodies);
      updatePortabilityRequestData(Id.valueOf(portingRequestId), responseCode, responseMessage, responseList);
    }
    catch (Exception excp) {
      responseCode = 500;
      //responseMessage = genericExceptionMessage;
      responseMessage = excp.getStackTraceString();
    }

        return new StageThreeResponseWrapper(responseList, responseCode, responseMessage);
    }

  @AuraEnabled
  public static NumberPortingHistoryWrapper getPortabilityHistory(Integer pageNumber, Integer pageSize) {
    //Add logic to retrieve data from Number_Portability_Request__c and convert into NumberPortingHistoryWrapper
    NumberPortingHistoryWrapper nphw = new NumberPortingHistoryWrapper();        
        
        List<NumberPortingHistory> nphList = new List<NumberPortingHistory>();
    List<Number_Portability_Request__c> nprList = new List<Number_Portability_Request__c>();
    try{
      Profile sysAdminProfile = [Select Id from Profile where name =:Label.System_Administrator];
          
      User loggedInUser = [Select Id, Contact.AccountId, Contact.Account.Partner_Role__c, Contact.Partner_Portal_View__c from User where Id = :UserInfo.getUserId()];
      String partnerAccId = loggedInUser.Contact.AccountId;
      String partnerRole = loggedInUser.Contact.Account.Partner_Role__c;   
      String partnerPortalView = loggedInUser.Contact.Partner_Portal_View__c;
      Boolean isMaster = false;
      Boolean showRequestingUser = true;
      
      Community_Details__mdt comDetail = CommunityInfo.getCommunityDetails();      
      
      if(partnerAccId == comDetail.Portal_Top_Master_Account_Id__c || partnerRole == 'Master Agent'){
        isMaster = true;              
      }
      else if(String.isBlank(partnerPortalView)){
        showRequestingUser = false;
      }
      else if(String.isNotBlank(partnerPortalView) && partnerPortalView.equals('Limited')){
        showRequestingUser = false;          
      }
      
      String nprQuery = 'Select Id, createdBy.Name, Partner_Account__r.Name, Country_ISO_Code__c, Country_Name__c,'+
              'Brand_Code__c, Request_Date_Time__c, Request_Type__c, Request_Size__c, Response_Code__c from  Number_Portability_Request__c'+
              ' where (Partner_Account__c = \''+ partnerAccId + '\' or  Partner_Account__r.Partner_Account__c = \''+ partnerAccId + '\' or'+
              ' Partner_Account__r.Parent_Partner_Account__c = \''+ partnerAccId + '\') order by Request_Date_Time__c DESC LIMIT ' + String.valueOf(pageSize) + ' OFFSET ' + String.valueOf(pageNumber * pageSize);
      
      nphw.isError = false;  
      nphw.isMaster = isMaster;  
      nphw.showRequestingUser = showRequestingUser;
      
      nprList = Database.query(nprQuery);
      
      Set<Id> nprIds = new Set<Id>();
      for(Number_Portability_Request__c nprc : nprList){
        nprIds.add(nprc.Id);
      }
      
      Map<Id,List<FileData>> nprFilesMap = getFileData(nprIds);
      
      for(Number_Portability_Request__c nprc : nprList) {
        NumberPortingHistory nph = new NumberPortingHistory();
        nph.countryISOCode = nprc.Country_ISO_Code__c;
                nph.countryName = nprc.Country_Name__c;
        nph.brandCode = nprc.Brand_Code__c;
        nph.requestDateTime = String.valueOf(nprc.Request_Date_Time__c);
        nph.requestType = nprc.Request_Type__c;
        nph.requestSize = Integer.valueOf(nprc.Request_Size__c);
        nph.responseCode = nprc.Response_Code__c;
        
        nph.requestingUser = nprc.createdBy.Name;
        nph.partnerAccount = nprc.Partner_Account__r!=null? nprc.Partner_Account__r.Name : '';
                              
        
        if(nprFilesMap.containsKey(nprc.Id) && !nprFilesMap.get(nprc.Id).isEmpty()){
          for(FileData file : nprFilesMap.get(nprc.Id)){
            if(file.Title.contains(REQUEST_BULK_FILE_KEY)){
              nph.requestFileName = file.Title;
              nph.requestFileContent = file.Content;
              nph.requestFileContentType = file.ContentType;
            }
            else if(file.Title.contains(RESULTS_FILE_KEY)){
              nph.resultsFileName = file.Title;
              nph.resultsFileContent = file.Content;
              nph.resultsFileContentType = file.ContentType;
            }else{
              nph.uploadFileName = file.Title;
              nph.uploadFileContent = file.Content;
              nph.uploadFileContentType = file.ContentType;
            }
          }
        }
        nphList.add(nph);
      }
    }
    catch(Exception e) {
      nphw.isError = true;
            nphw.errorMessage = e.getMessage();
    }
        nphw.portingHistoryList = nphList;          
        return nphw;
  }
    
    @TestVisible private static Map<Id,List<FileData>> getFileData(Set<Id> nprIds){
        Map<Id,List<FileData>> nprFilesMap = new Map<Id,List<FileData>>();
        List<ContentDocumentLink> links = [SELECT ContentDocumentId,LinkedEntityId FROM ContentDocumentLink where LinkedEntityId in :nprIds];
        Map<Id,List<Id>> nprCDMap = new Map<Id,List<Id>>();
        Set<Id> cdlIds = new Set<Id>();
        for(ContentDocumentLink cdl : links){
            cdlIds.add(cdl.ContentDocumentId);
            if(nprCDMap.containsKey(cdl.LinkedEntityId)){
                List<Id> cdlList = nprCDMap.get(cdl.LinkedEntityId);
                cdlList.add(cdl.ContentDocumentId);
                nprCDMap.put(cdl.LinkedEntityId,cdlList);
            }else{
                nprCDMap.put(cdl.LinkedEntityId,new List<Id>{cdl.ContentDocumentId});
            }
        }        
        
        List<ContentVersion> versions = [SELECT VersionData,Title,ContentDocumentId,FileExtension FROM ContentVersion WHERE ContentDocumentId in :cdlIds AND IsLatest = true];
        Map<Id,ContentVersion> docVersionMap = new Map<Id,ContentVersion>();
        for(ContentVersion cv : versions){
            docVersionMap.put(cv.ContentDocumentId,cv);
        }
        
        for(Id nprId : nprCDMap.keySet()){
            List<FileData> files = new List<FileData>();
            for(Id cdId : nprCDMap.get(nprId)){
                if(docVersionMap.containsKey(cdId)){
                    FileData data = new FileData();
                    data.Content = docVersionMap.get(cdId).VersionData.toString();
                    data.ContentType = ApexFileUpload.getContentType(docVersionMap.get(cdId).FileExtension);
                    data.Title = docVersionMap.get(cdId).Title;
                    files.add(data);
                }                    
            }
            nprFilesMap.put(nprId,files);
        }
        return nprFilesMap;
    }

  private static Map<String, String> getAPIIdentifierAndBrandName(String countryIsoCode){
    Map<String, String> apiIdentifier = new Map<String, String>();
    List<Number_Porting_API_Mapping__mdt> numberPortingApiMapping = [Select DeveloperName, Brand_Name__c, API_Identifier__c, Country_ISO_Codes__c from Number_Porting_API_Mapping__mdt];
    String identifier = '';
    String brandName = '';

    for (Number_Porting_API_Mapping__mdt mapping : numberPortingApiMapping){
      if (mapping.API_Identifier__c.contains(GPFS)){
        //Select GPFS as default apiIdentifier
        identifier = mapping.API_Identifier__c;
      }
    }

    for (Number_Porting_API_Mapping__mdt mapping : numberPortingApiMapping){
      if (mapping.Brand_Name__c.contains(EU)){
        //Select Ringcentral EU as default brand name
        brandName = mapping.Brand_Name__c;
      }
    }
    
    for (Number_Porting_API_Mapping__mdt mapping : numberPortingApiMapping){
      if (mapping.Country_ISO_Codes__c.contains(countryIsoCode)){
        identifier = mapping.API_Identifier__c;
        brandName = mapping.Brand_Name__c;
      }
    }

    apiIdentifier.put(identifier, brandName);
    return apiIdentifier;
  }

  private static List<String> constructRequestBodies(String apiIdentifier, String brandCode, List<String> numberList){
    List<String> requestStrings = new List<String>();
    Integer VODAFONE_UK_LOOSING_ID = 145;
    if (apiIdentifier.equals(Lergerator_UK)){
      JSONGenerator generator = JSON.createGenerator(true);
      /*//OLD API
      generator.writeStartObject();
      generator.writeFieldName('bulk_tns');
      generator.writeStartArray();
      for(String phoneNumber : numberList) {
        phoneNumber = phoneNumber.contains('+') ? phoneNumber.replace('+', '') : phoneNumber;
        generator.writeStartObject();
        generator.writeNumberField('tn', Long.valueOf(phoneNumber));
        generator.writeNumberField('brand_id', Integer.valueOf(brandCode));
        generator.writeNumberField('loosing_provider_id_code', VODAFONE_UK_LOOSING_ID);
        generator.writeEndObject();
      }
      generator.writeEndArray();
      generator.writeFieldName('account');
      generator.writeStartObject();
      generator.writeStringField('username', 'prmapiuser');
      generator.writeStringField('password', 'fakepassword');
      generator.writeEndObject();
      generator.writeEndObject();
      */

      //NEW UK API
      generator.writeStartObject();
      generator.writeFieldName('phoneNumbers');
      generator.writeStartArray();
      for(String phoneNumber : numberList) {
        phoneNumber = phoneNumber.contains('+') ? phoneNumber.replace('+', '') : phoneNumber;
        generator.writeStartObject();
        generator.writeNumberField('phoneNumber', Long.valueOf(phoneNumber));
        generator.writeNumberField('brandId', Integer.valueOf(brandCode));
        generator.writeNumberField('loosingProviderId', VODAFONE_UK_LOOSING_ID);
        generator.writeEndObject();
      }
      generator.writeEndArray();
      generator.writeEndObject();
      //NEW UK API Ends

      requestStrings.add(generator.getAsString());
    } else if (apiIdentifier.equals(Lergerator_US)){
      //Separate Toll Free and Non-Toll free numbers based on regex
      Pattern tollFreePattern = Pattern.compile('^(\\+?1)?(8(00|33|44|55|66|77|88)[2-9]\\d{6})$');
      List<String> nonTollFreeNumbers = new List<String>();
      List<String> tollFreeNumbers = new List<String>();

      for(String phoneNumber: numberList) {
        if(tollFreePattern.matcher(phoneNumber).matches()) {
          tollFreeNumbers.add(phoneNumber);
        }
        else {
          nonTollFreeNumbers.add(phoneNumber);
        }
      }

      //Create request body for non toll free numbers
      if(nonTollFreeNumbers.size() > 0) {
        String requestString = LergUS_numberbrand + '=';
        JSONGenerator generator = JSON.createGenerator(true);
        
        generator.writeStartObject();
        for (String phoneNumber : nonTollFreeNumbers){
          generator.writeStringField(phoneNumber, brandCode);
        }
        generator.writeEndObject();
        requestString += EncodingUtil.urlEncode(generator.getAsString(), 'UTF-8');
        requestStrings.add(requestString);
      } else {
        requestStrings.add('');
      }
      
      //Create request body for toll free numbers
      if(tollFreeNumbers.size() > 0) {
        String requestString = LergUS_numberbrand + '=';
        JSONGenerator generator = JSON.createGenerator(true);

        generator.writeStartObject();
        for (String phoneNumber : tollFreeNumbers){
          generator.writeStringField(phoneNumber, brandCode);
        }
        generator.writeEndObject();
        requestString += EncodingUtil.urlEncode(generator.getAsString(), 'UTF-8');
        requestStrings.add(requestString);
      } else {
        requestStrings.add('');
      }
    } else{
      //GPFS
      String numberString = '';
      String requestString = '';
      for (String phoneNumber : numberList){
        phoneNumber = phoneNumber.contains('+') ? phoneNumber : ('+' + phoneNumber);
        numberString += (phoneNumber + ',');
      }
      numberString = numberString.removeEnd(',');
      requestString = GPFS_number + '=' + EncodingUtil.urlEncode(numberString, 'UTF-8') + '&' + GPFS_brand + '=' + brandCode;
      requestStrings.add(requestString);
    }

    return requestStrings;
  }

    public static void boomiApiCallout(String brandName, String apiIdentifier, Id portingRequestId) {
    Number_Porting_API_Mapping__mdt numberPortingApiMapping = [Select Atom_Id__c, Process_Id__c from Number_Porting_API_Mapping__mdt where API_Identifier__c =: apiIdentifier][0];

    Map<String, String> headerDetails = new Map<String, String>();
    JSONGenerator gen = JSON.createGenerator(true);
    String httpMethod = HTTP_POST;
    String endpoint = callout + BOOMI;

    //Generate Request Body
    gen.writeStartObject();
        gen.writeFieldName('ProcessProperties');
        gen.writeStartObject();
        gen.writeStringField('@type', 'ProcessProperties');
        gen.writeFieldName('ProcessProperty');
        gen.writeStartArray();
        gen.writeStartObject();
        gen.writeStringField('Name', 'RC_SFDC_PORT_REQUEST_ID');
        gen.writeStringField('Value', String.valueOf(portingRequestId));
        gen.writeEndObject();
        gen.writeEndArray();
        gen.writeEndObject();
        gen.writeStringField('processId', numberPortingApiMapping.Process_Id__c);
        gen.writeStringField('atomId', numberPortingApiMapping.Atom_Id__c);
    gen.writeEndObject();
    
    //Create Request
    headerDetails.put('Content-Type', 'application/json;charset=UTF-8');
    headerDetails.put('Accept', '*/*');

        //Call Boomi process API
        APIUtility.makeHTTPRequest(endpoint, httpMethod, headerDetails, gen.getAsString());
  }

  public static List<NumberPortingResponse> parseResponseBodies(String apiIdentifier, String brandName, String countryName, List<String> jsonResponseBodies){
    List<NumberPortingResponse> responseList = new List<NumberPortingResponse>();
    //Logic for parsing JSON response based on apiIdentifier and converting it to NumberPortingResponse
    if (apiIdentifier.equals(Lergerator_UK)){
      for(String jsonResponseBody : jsonResponseBodies) {
        LergeratorUKResponse lergUkResponse = LergeratorUKResponse.parse(jsonResponseBody);
        for(LergeratorUKResponse.Data data: lergUkResponse.data) {
          responseList.add(new NumberPortingResponse(data, countryName));
        }
      }
    } else if (apiIdentifier.equals(Lergerator_US)){
      if(jsonResponseBodies[0] != '') {
        LergeratorUSTollFreeResponse tollFreeResponses = LergeratorUSTollFreeResponse.parse(jsonResponseBodies[0]);
        for(LergeratorUSTollFreeResponse.Data tollFreeResponse : tollFreeResponses.data) {
          responseList.add(new NumberPortingResponse(tollFreeResponse, countryName));
        }
        for(LergeratorUSTollFreeResponse.Errors tollFreeResponseError : tollFreeResponses.errors) {
          responseList.add(new NumberPortingResponse(tollFreeResponseError, countryName));
        }
      }
      if(jsonResponseBodies[1] != '') {
        LergeratorUSNonTollFreeResponse nonTollFreeResponses = LergeratorUSNonTollFreeResponse.parse(jsonResponseBodies[1]);
        for(LergeratorUSNonTollFreeResponse.Data nonTollFreeResponse : nonTollFreeResponses.data) {
          responseList.add(new NumberPortingResponse(nonTollFreeResponse, countryName));
        }
        for(LergeratorUSNonTollFreeResponse.Errors nonTollFreeResponseError : nonTollFreeResponses.errors) {
          responseList.add(new NumberPortingResponse(nonTollFreeResponseError, countryName));
        }
      }
    } else{ //GPFS
      for(String jsonResponseBody : jsonResponseBodies) {
        List<GPFSResponse> gpfsResponses = GPFSResponse.parse(jsonResponseBody);
        for(GPFSResponse gpfsResponse : gpfsResponses) {
          responseList.add(new NumberPortingResponse(gpfsResponse, countryName));
        }
      }
    }
    return responseList;
  }

  private static Map<String, String> insertPortabilityRequestData(
    String brandCode, 
    String brandName,
    String countryCode,
        String countryName,
    DateTime requestDateTime, 
    Integer requestSize, 
    Boolean isBulk, 
    String uploadCSV, 
    String csvFileName,
    List<String> requestBodies
  ) {
    User currentUser = [Select Id, ContactId, Contact.AccountId, Partner_Account_Id__c from User where Id =: UserInfo.getUserId()];
    Number_Portability_Request__c portingRequest = new Number_Portability_Request__c();
    portingRequest.Brand_Code__c = brandCode;
    portingRequest.Brand_Name__c = brandName;
    portingRequest.Country_ISO_Code__c = countryCode;
        portingRequest.Country_Name__c = countryName;
    portingRequest.Partner_Account__c = currentUser.Contact.AccountId;
    portingRequest.Partner_Contact__c = currentUser.ContactId;
    portingRequest.Request_Date_Time__c = requestDateTime;
        portingRequest.Request_Size__c = requestSize;
    portingRequest.API_Request_Raw_Text__c = requestBodies[0];
    portingRequest.API_Toll_Free_Request_Raw_Text__c = ((countryCode == 'US' || countryCode == 'CA') && requestBodies.size() == 2) ? requestBodies[1] : '';
    portingRequest.Request_Type__c = isBulk ? REQUEST_TYPE_BULK : REQUEST_TYPE_MANUAL;
        
    Boolean isDataInsertSuccess = true;
    String errorMessage = '';
    Map<String, String> retMap = new Map<String, String>();
        Number_Portability_Request__c portingRequestRecord = new Number_Portability_Request__c();
    try {
      insert portingRequest;
            portingRequestRecord = [Select Id, Name, API_Request_Raw_Text__c, API_Toll_Free_Request_Raw_Text__c from Number_Portability_Request__c where id = :portingRequest.Id];
    } catch(Exception excp) {
      errorMessage = excp.getMessage();
      isDataInsertSuccess = false;
    }
    if(isDataInsertSuccess) {
      //Generate Files after request insert
      //Uploaded CSV File
            if(isBulk){
                ApexFileUpload.uploadFile(uploadCSV, (portingRequestRecord.Name + REQUEST_BULK_FILE_KEY + csvFileName), portingRequest.Id);
            }
            
            //Raw Text Request File
      ApexFileUpload.uploadFile((portingRequestRecord.API_Request_Raw_Text__c + (portingRequestRecord.API_Toll_Free_Request_Raw_Text__c != null ? ('\n\n' + portingRequestRecord.API_Toll_Free_Request_Raw_Text__c) : '')), (portingRequestRecord.Name + '-' + REQUEST_FILE_KEY + '.txt'), portingRequestRecord.Id);
      retMap.put('success', String.valueOf(portingRequest.Id));
    }
    else {
      retMap.put('error', errorMessage);
    }
    return retMap;
  }

  @TestVisible private static Boolean updatePortabilityRequestData(
    Id portingRequestId, 
    Integer responseCode, 
    String responseMessage, 
    List<NumberPortingResponse> responseList
  ) {
    Number_Portability_Request__c portingRequest = [Select Id, Name, Error_Message__c, Response_Code__c from Number_Portability_Request__c where Id =: portingRequestId];
    portingRequest.Error_Message__c = responseMessage;
    portingRequest.Response_Code__c = (responseCode < 300) ? RESPONSE_CODE_SUCCESS : RESPONSE_CODE_ERROR;

    Boolean isDataUpdateSuccess = true;
    try {
      update portingRequest;
    } catch(Exception excp) {
      isDataUpdateSuccess = false;
    }

    //Generate Result CSV
    if(!responseList.isEmpty()) {
      String resultCSV = responseList[0].generateCsvHeader();
      for(NumberPortingResponse response : responseList) {
        resultCSV += ('\n' + response.generateCsvRowData());
      }
      ApexFileUpload.uploadFile(resultCSV, (portingRequest.Name + '-' + RESULTS_FILE_KEY + '.csv'), portingRequestId);
    }

    return isDataUpdateSuccess;
    }

  //Dropdown data
  public class NumberPortingMappingWrapper{
    @AuraEnabled
    public String countryName{get;set;}
    @AuraEnabled
    public String countryCode{get;set;}
    @AuraEnabled
    public String countryISOCode{get;set;}
    @AuraEnabled
    public String brandCode{get;set;}
    @AuraEnabled
    public string exampleNumbers{get;set;}
    @AuraEnabled
    public Integer apiRequestLimit{get;set;}

    public NumberPortingMappingWrapper(String cName, String cCode, String cISOCode, String bCode, String exampleNumbers, Integer apiRequestLimit){
      this.countryName = cName;
      this.countryCode = '+' + cCode;
      this.countryISOCode = cISOCode;
      this.brandCode = bCode;
      this.exampleNumbers = exampleNumbers;
      this.apiRequestLimit = apiRequestLimit;
    }
  }
  
  //API Response wrapper
  public class NumberPortingResponse{
    @AuraEnabled
    public String phoneNumber{get;set;}
    @AuraEnabled
    public String country{get;set;}
    @AuraEnabled
    public String status{get;set;}
    @AuraEnabled
    public String numberType{get;set;}
    @AuraEnabled
    public String isPortable{get;set;}
    @AuraEnabled
    public String failureReason{get;set;}

    public NumberPortingResponse(GPFSResponse gpfsResponse, String countryName) {
      this.phoneNumber = gpfsResponse.number_Z;
      this.country = countryName;
      this.status = gpfsResponse.error != null ? Failure : Success;
      this.numberType = gpfsResponse.number_type != null ? (gpfsResponse.number_type == 2 ? TOLL_FREE_STRING : NON_TOLL_FREE_STRING) : '';
      this.isPortable = gpfsResponse.support_porting != null ? (gpfsResponse.support_porting == GPFS_yes ? PORTABLE_YES : PORTABLE_NO) : '';
      this.failureReason = gpfsResponse.error != null ? (gpfsResponse.error.message == 'result not exist' ? 'No result found' : gpfsResponse.error.message) : '';
    }

    public NumberPortingResponse(LergeratorUSTollFreeResponse.Data tollFreeResponse, String countryName) {
      this.phoneNumber = tollFreeResponse.TN;
      this.country = countryName;
      this.status = Success;
      this.numberType = TOLL_FREE_STRING;
      this.isPortable = (tollFreeResponse.Number_Type != 'notValid' && tollFreeResponse.Provider_Name != '') ? PORTABLE_YES : PORTABLE_NO;
      this.failureReason = '';
    }

    public NumberPortingResponse(LergeratorUSTollFreeResponse.Errors tollFreeResponseError, String countryName) {
      this.phoneNumber = tollFreeResponseError.phone_number;
      this.country = countryName;
      this.status = Failure;
      this.failureReason = tollFreeResponseError.error_message;
    }

    public NumberPortingResponse(LergeratorUSNonTollFreeResponse.Data nonTollFreeResponse, String countryName) {
      this.phoneNumber = nonTollFreeResponse.TN;
      this.country = countryName;
      this.status = Success;
      this.numberType = NON_TOLL_FREE_STRING;
      this.isPortable = (nonTollFreeResponse.Preferred_Provider_For_Porting != 'Not Supported' && nonTollFreeResponse.Preferred_Provider_For_Porting != '') ? PORTABLE_YES : PORTABLE_NO;
      this.failureReason = '';
    }

    public NumberPortingResponse(LergeratorUSNonTollFreeResponse.Errors nonTollFreeResponseError, String countryName) {
      this.phoneNumber = nonTollFreeResponseError.phone_number;
      this.country = countryName;
      this.status = Failure;
      this.failureReason = nonTollFreeResponseError.error_message;
    }

    public NumberPortingResponse(LergeratorUKResponse.data data, String countryName) {
      this.phoneNumber = String.valueOf(data.tn);
      this.country = countryName;
      this.status = data.errorCode != null ? Failure : Success;
      this.numberType = data.errorCode != null ? '' : (data.type == 'nongeofree' ? TOLL_FREE_STRING : NON_TOLL_FREE_STRING);
      this.isPortable = data.rcSupported == 'YES' ? PORTABLE_YES : PORTABLE_NO;
      this.failureReason =  data.errorCode != null ? data.message : '';
    }

    public NumberPortingResponse() {

    }

    public string generateCsvHeader() {
      return 'Number,Country,Status,Type,Is Portable,Failure Reason';
    }

    public string generateCsvRowData() {
      return
        (this.phoneNumber + ',' + 
        this.country + ',' + 
        this.status + ',' +
        this.numberType + ',' +
        this.isPortable + ',' +
        this.failureReason);
    }
  }

  //Stage 1 API Response wrapper FE
  public class StageOneResponseWrapper {
    @AuraEnabled
    public String apiIdentifier {get; set;}
    @AuraEnabled
    public String brandName {get; set;}
    @AuraEnabled
    public String brandCode {get; set;}
    @AuraEnabled
    public String portingRequestId {get; set;}
    @AuraEnabled
    public Integer responseCode{get;set;}
    @AuraEnabled
    public String responseMessage {get; set;}
    @AuraEnabled
    public Integer expectedResponseFileCount {get; set;}

    public StageOneResponseWrapper(String apiIdentifier, String brandName, String brandCode, String portingRequestId, Integer responseCode, String responseMessage, Integer expectedResponseFileCount) {
      this.apiIdentifier = apiIdentifier;
      this.brandName = brandName;
      this.brandCode = brandCode;
      this.portingRequestId = portingRequestId;
      this.responseCode = responseCode;
      this.responseMessage = responseMessage;
      this.expectedResponseFileCount = expectedResponseFileCount;
    }
  }

  //Stage 2 API Response wrapper FE
  public class StageTwoResponseWrapper{
    @AuraEnabled
    public Integer responseCode{get;set;}
    @AuraEnabled
    public String responseMessage{get;set;}

    public StageTwoResponseWrapper(Integer responseCode, String responseMessage){
      this.responseCode = responseCode;
      this.responseMessage = responseMessage;
    }
    }
    
    //Stage 3 API Response wrapper FE
  public class StageThreeResponseWrapper{
    @AuraEnabled
    public List<NumberPortingResponse> responseList{get;set;}
    @AuraEnabled
    public String responseCsv{get;set;}
    @AuraEnabled
    public Integer responseCode{get;set;}
    @AuraEnabled
    public String responseMessage{get;set;}

    public StageThreeResponseWrapper(List<NumberPortingResponse> responseList, Integer responseCode, String responseMessage){
      this.responseList = responseList;
      if(!responseList.isEmpty()) {
        String resultCSV = responseList[0].generateCsvHeader();
        for(NumberPortingResponse response : responseList) {
          resultCSV += ('\n' + response.generateCsvRowData());
        }
        this.responseCsv = resultCSV;
      }
      else {
        this.responseCsv = '';
      }
      
      this.responseCode = responseCode;
      this.responseMessage = responseMessage;
    }
  }

  public class NumberPortingHistoryWrapper{
        @AuraEnabled
        public List<NumberPortingHistory> portingHistoryList{get;set;}
        @AuraEnabled
        public boolean isError{get;set;}
        @AuraEnabled
        public String errorMessage{get;set;}
        @AuraEnabled
        public boolean isMaster{get;set;}
        @AuraEnabled
        public boolean showRequestingUser{get;set;}
  }
    
    public class NumberPortingHistory{
        @AuraEnabled
        public List<FileData> fileList{get;set;}
        @AuraEnabled
        public String countryISOCode{get;set;}
        @AuraEnabled
        public String countryName{get;set;}
        @AuraEnabled
        public String brandCode{get;set;}
        @AuraEnabled
        public String requestDateTime{get;set;}
        @AuraEnabled
        public String requestType{get;set;}
        @AuraEnabled
        public String requestingUser{get;set;}
        @AuraEnabled
        public Integer requestSize{get;set;}
        @AuraEnabled
        public String responseCode{get;set;}            
        @AuraEnabled
        public String partnerAccount{get;set;}
        @AuraEnabled
        public String uploadFileName{get;set;}
        @AuraEnabled
        public String uploadFileContent{get;set;}
        @AuraEnabled
        public String uploadFileContentType{get;set;}
        @AuraEnabled
        public String requestFileName{get;set;}
        @AuraEnabled
        public String requestFileContent{get;set;}
        @AuraEnabled
        public String requestFileContentType{get;set;}        
        @AuraEnabled
        public String resultsFileName{get;set;}
        @AuraEnabled
        public String resultsFileContent{get;set;}
        @AuraEnabled
        public String resultsFileContentType{get;set;}
    }
    
    public class FileData 
    {
        @AuraEnabled
        public string Content{get;set;}
        @AuraEnabled
        public string ContentType{get;set;}
        @AuraEnabled
        public string FileUrl{get;set;}
        @AuraEnabled
        public string DownloadUrl{get;set;}
        @AuraEnabled
        public string Title{get;set;}
  }
}