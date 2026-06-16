public without sharing class SnapInsController {
    private static final String SALES_BUCKET_BUTTON_DEVELOPER_NAME = 'US_Team_All';
    private static final String POSTFIX_DEVELOPER_NAME_AGENT_BUTTON_FOR_OMNI_CHANNEL = '_Transfer';
    private static final String LIVE_AGENT_AVAILABILITY_ERROR_MESSAGE = 'Error during parsing respose of Live Agent availability';
    private static final String SWITCH_SERVER_ERROR_MESSAGE = 'SwitchServer';

    @AuraEnabled
    public static List<SObject> searchContacts(String email) {
        List<SObject> contacts = [SELECT Id, FirstName, LastName, Company__c, NumberOfEmployees__c, Account.Name,
                                    Account.RC_Service_name__c, Account.Total_Account_DL_s__c, Account.Offer_Type__c,
                                    Account.RC_Brand__c, Account.No_of_InContact_Seats__c
                                FROM Contact
                                WHERE Email = :email ORDER BY CreatedDate DESC LIMIT 1];
        return contacts;
    }

    @AuraEnabled
    public static List<String> getPicklistValues(String objectType, String selectedField) {
        List<String> pickListValuesList = new List<String>();
        Schema.SObjectType convertToObj = ((SObject)Type.forName(objectType).newInstance()).getSObjectType();
        Schema.DescribeSObjectResult res = convertToObj.getDescribe();
        Schema.DescribeFieldResult fieldResult = res.fields.getMap().get(selectedField).getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for(Schema.PicklistEntry pickListVal : ple){
            pickListValuesList.add(pickListVal.getLabel());
        }
        return pickListValuesList;
    }

    @AuraEnabled
    public static SnapInsSettings__c getUrlPathForKA() {
        return SnapInsSettings__c.getInstance();
    }

    @AuraEnabled
    public static Boolean isOmniChannelRoutingEnable() {
        return Feature_Toggle__c.getInstance().EnableOmniChannelRouting__c;
    }
    
    @AuraEnabled
    public static String setLanguageForCoveoResultPage(String language) {
        return SnapInsSettings__c.getInstance().PathForSnapInsCoveoSearch__c + '?lang=' + language;
    }

    // get all information about contact:
    // sales, support, company name, employee number, isFreeRCMeetingCustomer based on PageType
    @AuraEnabled
    public static List<String> defineSalesAndSupportInformation(List<SObject> contacts, String pageType, String supportRouting) {
        List<String> salesAndSupportInformation = new List<String>();
        salesAndSupportInformation.add(defineSales(contacts, pageType));
        salesAndSupportInformation.add(defineSupport(contacts, supportRouting));
        salesAndSupportInformation.add(defineCompanyName(contacts));
        salesAndSupportInformation.add(defineEmployeeNumber(contacts));
        salesAndSupportInformation.add(isFreeRCMeetingCustomer(contacts));
        return salesAndSupportInformation;
    }

    // define sales, company name, employee number based on PageType
    @AuraEnabled
    public static List<String> defineSalesInformation(List<SObject> contacts, String pageType) {
        List<String> salesInformation = new List<String>();
        salesInformation.add(defineSales(contacts, pageType));
        salesInformation.add(defineCompanyName(contacts));
        salesInformation.add(defineEmployeeNumber(contacts));
        return salesInformation;
    }
     
    // define support, company name, employee number, isFreeRCMeetingCustomer
    @AuraEnabled
    public static List<String> defineSupportInformation(List<SObject> contacts, String supportRouting) {
        List<String> supportInformation = new List<String>();
        supportInformation.add(defineSupport(contacts, supportRouting));
        supportInformation.add(defineCompanyName(contacts));
        supportInformation.add(defineEmployeeNumber(contacts));
        supportInformation.add(isFreeRCMeetingCustomer(contacts));
        return supportInformation;
    }

    // define sales based on employee number based on PageType
    @AuraEnabled
    public static String defineSalesByEmployeeNumber(String employeeNumber, String pageType) {
        String routingType = SnapInsController.getRoutingType(pageType);
        if (routingType == 'none') {
            return getEnableChatButtonBasedOnDeveloperName(defineDeveloperNameSalesByEmployeeNumber(employeeNumber), 'sales');
        } else {
            return getEnableChatButtonBasedOnDeveloperName(routingType, 'sales');
        }
    }

    @TestVisible
    private static String defineCompanyName(List<SObject> contacts) {
        Contact cont = (Contact)contacts[0];
        if (cont.Account != null && !String.isBlank(cont.Account.Name)) {
            return cont.Account.Name;
        } else {
            if (String.isBlank(cont.Company__c)) {
                return '';
            } else {
                return cont.Company__c;
            }
        }
    }

    @TestVisible
    private static String defineEmployeeNumber(List<SObject> contacts) {
        Contact cont = (Contact)contacts[0];
        if (cont.Account != null) {
            return getRangeBasedOnNumberOfDLs(cont.Account.Total_Account_DL_s__c);
        } else {
            if (cont.NumberOfEmployees__c != null) {
                return cont.NumberOfEmployees__c;
            } else {
                return 'Just Me';
            }
        }
    }

    @TestVisible
    private static String defineSales(List<SObject> contacts, String pageType) {
        String routingType = SnapInsController.getRoutingType(pageType);
        if (routingType == 'none') {
            return getEnableChatButtonBasedOnDeveloperName(defineDeveloperNameChatButtonSales(contacts), 'sales');
        } else {
            return getEnableChatButtonBasedOnDeveloperName(routingType, 'sales');
        }
    }

    @TestVisible
    private static String defineDeveloperNameChatButtonSales(List<SObject> contacts) {
        Contact cont = (Contact)contacts[0];
        if(cont.Account != null) {
            if(!String.isBlank(cont.Account.RC_Service_name__c) && cont.Account.RC_Service_name__c.contains('Fax')) {
                return 'US_Fax';
            } else if(!String.isBlank(cont.Account.RC_Service_name__c) && cont.Account.RC_Service_name__c.contains('Professional')) {
                return 'US_Pro';
            } else {
                return getButtonBasedOnEmployeeNumber(getRangeBasedOnNumberOfDLs(cont.Account.Total_Account_DL_s__c));
            }
        } else {
            return getButtonBasedOnEmployeeNumber(cont.NumberOfEmployees__c);
        }
    }

    @TestVisible
    private static String defineSupport(List<SObject> contacts, String supportRouting) {
        String supportChatButtonDeveloperName = getSupportChatButton(contacts);
        if (isOmniChannelRoutingEnable() && supportRouting == 'agent') {
            supportChatButtonDeveloperName += POSTFIX_DEVELOPER_NAME_AGENT_BUTTON_FOR_OMNI_CHANNEL;
        } 
        return getEnableChatButtonBasedOnDeveloperName(supportChatButtonDeveloperName, 'support');
    }

    @TestVisible
    private static String getSupportChatButton(List<SObject> contacts) {
        Contact cont = (Contact)contacts[0];
        if (cont.Account != null){
            if (!String.isBlank(cont.Account.RC_Service_name__c) && cont.Account.RC_Service_name__c.equals('RCMeetings') &&
                 (!String.isBlank(cont.Account.Offer_Type__c) && !cont.Account.Offer_Type__c.equals('Free'))) {
                return 'Support_Inbound_Chat_Freyja';
            } else if (!String.isBlank(cont.Account.RC_Brand__c) && !String.isBlank(cont.Account.RC_Service_name__c) &&
                     cont.Account.RC_Brand__c.contains('UK') && cont.Account.RC_Service_name__c.contains('UK')) {
                return 'Support_Inbound_Chat_UK';
            } else if (!String.isBlank(cont.Account.RC_Brand__c) && !String.isBlank(cont.Account.RC_Service_name__c) &&
                    cont.Account.RC_Brand__c.contains('AU') && cont.Account.RC_Service_name__c.contains('AU')) {
                return 'Support_Inbound_Chat_AU';
            } else if (!String.isBlank(cont.Account.RC_Service_name__c) && cont.Account.RC_Service_name__c.contains('Fax')) {
                return 'Support_Inbound_Chat_Fax';
            } else if (!String.isBlank(cont.Account.RC_Service_name__c) && cont.Account.RC_Service_name__c.contains('Professional')) {
                return 'Support_Inbound_Chat_Pro';
            } else if (cont.Account.No_of_InContact_Seats__c > 0 &&
                 (cont.Account.Total_Account_DL_s__c >= 1 && cont.Account.Total_Account_DL_s__c <= 99)) {
                return 'Support_CC_Inbound_Chat_1_99';
            } else if (cont.Account.No_of_InContact_Seats__c > 0 &&
                 cont.Account.Total_Account_DL_s__c >= 100) {
                return 'Support_CC_Inbound_Chat_100';
            } else if (cont.Account.Total_Account_DL_s__c >= 0 && cont.Account.Total_Account_DL_s__c <= 1) {
                return 'Support_Inbound_Chat_0_1';
            } else if (cont.Account.Total_Account_DL_s__c >= 2 && cont.Account.Total_Account_DL_s__c <= 19) {
                return 'Support_Inbound_Chat_2_19';
            } else if (cont.Account.Total_Account_DL_s__c >= 20 && cont.Account.Total_Account_DL_s__c <= 49) {
                return 'Support_Inbound_Chat_20_49';
            } else if (cont.Account.Total_Account_DL_s__c >= 50 && cont.Account.Total_Account_DL_s__c <= 99) {
                return 'Support_Inbound_Chat_50_99';
            } else if (cont.Account.Total_Account_DL_s__c >= 100 && cont.Account.Total_Account_DL_s__c <= 999) {
                return 'Support_Inbound_Chat_100_999';
            } else if (cont.Account.Total_Account_DL_s__c >= 1000) {
                return 'Support_Inbound_Chat_1000';
            }
        }
        return 'Support_Inbound_Chat_Null'; // Support - Inbound Chat in case there is no account for contact
    }

    @TestVisible
    private static String defineDeveloperNameSalesByEmployeeNumber(String employeeNumber) {
        return getButtonBasedOnEmployeeNumber(employeeNumber);
    }

    @TestVisible
    private static String getRoutingType(String pageType) {
        if (pageType == 'fax') {
            return 'US_Fax';
        } else if (pageType == 'pro') {
            return 'US_Pro';
        }
        return 'none'; // default page type
    }
    
    @TestVisible
    private static String getButtonBasedOnEmployeeNumber(String employeeNumber) {
       if (String.isBlank(employeeNumber) || employeeNumber.equals('1-19')) {
            return 'US_SOHO';
        } else if (employeeNumber.equals('20-99')) {
            return 'US_SMB';
        } else if (employeeNumber.equals('100-399')) {
            return 'US_FIELDSALES';
        } else if (employeeNumber.equals('400-4999')) {
            return 'US_FIELDSALES';
        } else if (employeeNumber.equals('5000+')) {
            return 'US_FIELDSALES';            
        } else if (employeeNumber.equals('400-1999')) {
            return 'US_FIELDSALES';
        } else if (employeeNumber.equals('2000+')) {
            return 'US_FIELDSALES';
        } else if (employeeNumber.equals('Just Me')) {
            return 'US_Just_Me';
        } else if (employeeNumber.equals('2-4')) {
            return 'US_2_4';
        } else if (employeeNumber.equals('5-9')) {
            return 'US_5_9';
        } else if (employeeNumber.equals('10-19')) {
            return 'US_10_19';
        } else if (employeeNumber.equals('20-49')) {
            return 'US_20_49';
        } else if (employeeNumber.equals('50-99')) {
            return 'US_50_99';
        } else if (employeeNumber.equals('100-249')) {
            return 'US_100_249';
        } else if (employeeNumber.equals('250-499')) {
            return 'US_250_499';
        } else if (employeeNumber.equals('500-999')) {
            return 'US_500_999';
        } else if (employeeNumber.equals('1000+')) {
            return 'US_1000';
        }
        return 'US_Just_Me'; // undefined value
    }

    @TestVisible
    private static String getRangeBasedOnNumberOfDLs(Decimal Number_of_DL_s) {
        if (Number_of_DL_s == null ||
            (Number_of_DL_s >= 0 && Number_of_DL_s <= 1)) {
            return 'Just Me';
        } else if (Number_of_DL_s >= 2 && Number_of_DL_s <= 4) {
            return '2-4';
        } else if (Number_of_DL_s >= 5 && Number_of_DL_s <= 9) {
            return '5-9';
        } else if (Number_of_DL_s >= 10 && Number_of_DL_s <= 19) {
            return '10-19';
        } else if (Number_of_DL_s >= 20 && Number_of_DL_s <= 49) {
            return '20-49';
        } else if (Number_of_DL_s >= 50 && Number_of_DL_s <= 99) {
            return '50-99';
        } else if (Number_of_DL_s >= 100 && Number_of_DL_s <= 249) {
            return '100-249';
        } else if (Number_of_DL_s >= 250 && Number_of_DL_s <= 499) {
            return '250-499';
        } else if (Number_of_DL_s >= 500 && Number_of_DL_s <= 999) {
            return '500-999';
        } else if (Number_of_DL_s >= 1000) {
            return '1000+';
        }
        return 'Just Me'; // undefined value
    }

    public static String isFreeRCMeetingCustomer(List<SObject> contacts) {
        Contact cont = (Contact)contacts[0];
        // in case there is no account for contact we dont get access to support - is free
        if(cont.Account == null || (!String.isBlank(cont.Account.RC_Service_name__c) && cont.Account.RC_Service_name__c.equals('RCMeetings') &&
            (!String.isBlank(cont.Account.Offer_Type__c) && cont.Account.Offer_Type__c.equals('Free')))) {
            return 'free';
        }
        return 'not free';
    }

    @TestVisible
    private static String getEnableChatButtonBasedOnDeveloperName(String developerName, String salesOrSupport) {
        //support logic
        if(salesOrSupport.equals('support') && !Test.isRunningTest()) {
            List<LiveChatButton> liveChatBtn = [SELECT Id FROM LiveChatButton WHERE DeveloperName = :developerName];
            return liveChatBtn[0].Id;
        }
        
        //sales logic
        Map<String, Id> buttons = new Map<String, Id>();
        for(LiveChatButton l : [SELECT Id, DeveloperName FROM LiveChatButton WHERE DeveloperName = :developerName OR 
                                DeveloperName = :SALES_BUCKET_BUTTON_DEVELOPER_NAME]) {
            buttons.put(l.DeveloperName, l.Id);
        }
        if (!Test.isRunningTest()) {
            if (isAgentsOnlineForChatButton(developerName)) {
                return buttons.get(developerName);
            } else {
                return buttons.get(SALES_BUCKET_BUTTON_DEVELOPER_NAME);
            }
        }
        
        //return for tests return sales or support
        return salesOrSupport;
    }

    //check if Bucket Sales agents for this user are online
    @AuraEnabled
    public static String isSalesBucketAgentsOnline() {
        return isAgentsOnlineForChatButton(SALES_BUCKET_BUTTON_DEVELOPER_NAME) ? 'online' : 'offline';
    }
    
    //check if button is online
    @AuraEnabled
    public static Boolean isAgentsOnlineForChatButton(String developerName) {
        String buttonId = '';
        if (!Test.isRunningTest()) {
            LiveChatButton liveChatSalesBucketButton = [SELECT Id, DeveloperName
                                                        FROM LiveChatButton
                                                        WHERE DeveloperName = :developerName LIMIT 1];
            //All ids should be 15 digits.
            buttonId = String.valueOf(liveChatSalesBucketButton.Id).substring(0, 15);
        }       
        String availabilityURL = SnapInsSettings__c.getInstance().LiveAgentAvailabilityURL__c;
        String availabilityParams = '?Availability.prefix=Visitor&Availability.ids=['+ buttonId +']&deployment_id=' +
                                        SnapInsSettings__c.getInstance().DeploymentID__c +
                                            '&org_id=' + UserInfo.getOrganizationId().substring(0, 15);
        String url = availabilityURL + availabilityParams;
        return checkIsChatButtonAvailable(url);
    }
    
    @TestVisible
    private static Boolean checkIsChatButtonAvailable(String url) {
        Boolean isChatButtonAvailable = false;
        String response = '';
        
        try {
            response = getCalloutResponseContents(url); 
            
            Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(response);
            List<Map<String, Object>> resultMapList = new List<Map<String, Object>>();
            List<Object> messagesList = (List<Object>) resultMap.get('messages');
            for (Object obj : messagesList) {
                resultMapList.add((Map<String, Object>)obj);
            }
            
            Object message = resultMapList.get(0).get('message');
            Map<String, Object> messageMap = (Map<String, Object>)message;
            List<Object>resultsList = (List<Object>) messageMap.get('results');
            List<Map<String, Object>> resultsMapList = new List<Map<String, Object>>();
            for (Object obj : resultsList) {
                resultsMapList.add((Map<String, Object>)obj);
            }
            
            String isAvailable = JSON.serialize(resultsMapList.get(0).get('isAvailable'));
            if (!String.isBlank(isAvailable) && isAvailable.equals('true')) {
                isChatButtonAvailable = true;
            } else {
                isChatButtonAvailable = false;
            }
        } catch (Exception ex) {
            /* log every error */
            PlatformLog.logException(LIVE_AGENT_AVAILABILITY_ERROR_MESSAGE + ' ' + response, ex);
            SnapInsSettings__c snapInSetting = SnapInsSettings__c.getOrgDefaults();
            /* SnapInsSetting is defined and notification wasn't sent before and if this error is about switch server*/
            if (
                snapInSetting != null && !snapInSetting.IsErrorNotificationSent__c &&
                response.contains(SWITCH_SERVER_ERROR_MESSAGE)
            ) { // send email notification one time
                snapInSetting.IsErrorNotificationSent__c = true;
                update snapInSetting;
                
                String errorMessage = String.format(
                    Label.SnapInsErrorNotificationTextMessage,
                    new List<Object>{
                        System.URL.getOrgDomainUrl().toExternalForm(),
                        response,
                        ex.getMessage()
                    }
                );
                sendErrorNotification (snapInSetting.EmailsForErrorNotification__c, errorMessage);
            }
            
            isChatButtonAvailable = false;
        }
        return isChatButtonAvailable;
    }
    
    private static void sendErrorNotification (String emailAdresses, String errorMessage) {
        List<String> emailList = StringHelper.safeSplitStringByNewLine(emailAdresses);
        List<Messaging.SingleEmailMessage> singleEmailList  = new List<Messaging.SingleEmailMessage>();
        
        for (String emailAdress : emailList) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[] {emailAdress}; 
            mail.setToAddresses(toAddresses);
            mail.setSubject(LIVE_AGENT_AVAILABILITY_ERROR_MESSAGE);
            mail.setPlainTextBody(errorMessage);
            singleEmailList.add(mail);
        }
        
        if (singleEmailList.size() > 0) {
            try {
                Messaging.sendEmail(singleEmailList);
            } catch (Exception ex) {
                ExceptionHelper.checkIsMassEmailException(ex);
            }
        }
    }
    
    @TestVisible
    private static String getCalloutResponseContents(String url) {
        // Instantiate a new http object
        Http h = new Http();
        // Instantiate a new HTTP request, specify the method (GET) as well as the endpoint
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod('GET');
        req.setHeader('X-LIVEAGENT-API-VERSION', '43');
        req.setHeader('Content-Type', 'application/json');

       // Send the request, and return a response
       HttpResponse res = h.send(req);
       return res.getBody();
    }
}