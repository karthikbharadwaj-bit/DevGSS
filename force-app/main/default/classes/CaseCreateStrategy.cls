public with sharing class CaseCreateStrategy {

    private static final Map<String, ICaseCreateStrategy> STRATEGY_BY_RT_ID = new Map<String, ICaseCreateStrategy>{
        CaseHelper.RT_ID_DEVELOPER_PORTAL => new CaseCreateDeveloperPortal(),
        CaseHelper.RT_ID_SALES_CUST_FORM => new CaseCreateSalesCustForm(),
        CaseHelper.RT_ID_GDPR_REQUEST => new CaseCreateGDPR()
    };

    private static final Map<String, ICaseCreateStrategy> STRATEGY_BY_RT_NAME = new Map<String, ICaseCreateStrategy>{
        CaseHelper.RT_NAME_DEVELOPER_PLATFORM => new CaseCreateDeveloperPortal(),
        CaseHelper.RT_NAME_SALES_CUST_FORM => new CaseCreateSalesCustForm(),
        CaseHelper.RT_NAME_GDPR_REQUEST => new CaseCreateGDPR()
    };

    private static final String INVALID_RECORDTYPE = CaseAPIUtil.BAD_REQUEST_MESSAGE + ': Invalid recordType parameter. Valid values: ' + STRATEGY_BY_RT_NAME.keySet();
    private static final String INVALID_RECORDTYPE_ID = CaseAPIUtil.BAD_REQUEST_MESSAGE + ': Invalid recordTypeId parameter. Valid values: ' + STRATEGY_BY_RT_ID.keySet();
    
    private static final String ENTREPRISE_QUEUE_DEVELOPER_NAME = 'Support_US_20';

    private static final String RC_EVENTS_DEFAULT_SEVERITY_MEDIUM = 'Level 3-Medium';
    private static final String RC_EVENTS_QUEUE = 'RC_Events';
    private static final String RC_EVENTS_PRODUCT_VALUE = 'Events';
    private static final String OPEN_WEB_CASE_RC_EVENTS_ORIGIN = 'RC Events';

    public static String caseNumber { get; private set; }

    public interface ICaseCreateStrategy {
        void validate(Map<String,Object> req);
        String create(Map<String,Object> req);
    }

    public static Case populateAccountContactInfoRCEvents(Map<String,Object> requestMap) {
        // Populate the Account and Contact information for the RC Events case. Assign to Default values if not found
        
        String firstName = (String) requestMap.get('firstName');
        String lastName = (String) requestMap.get('lastName');
        String email = (String) requestMap.get('email');
        Boolean isDefaultContact = false;

        Contact contactInfo = CaseAPIUtil.getContactForOpenRCEvents(
            firstName, lastName, email
        );

        if (contactInfo == null) {
            // get default contact
            isDefaultContact = true;
            contactInfo = CaseAPIUtil.getDefaultContactForOpenRCEvents();
        }
        
        SCWrappers.CaseRequestAPI createCaseRequest = (SCWrappers.CaseRequestAPI) JSON.deserialize(
            JSON.serialize(requestMap),
            SCWrappers.CaseRequestAPI.class
        );
        
        Case caseObj = new Case(
            ContactId = contactInfo.Id,
            AccountId = contactInfo.AccountId,
            Account = (Account) new AccountSelector().selectAccountsForCaseAPI(new Set<Id>{contactInfo.AccountId}).executeQuery()[0],
            IsVisibleInSelfService = true
        );

        // retaining exising logic to populate case info from CaseCreateDefault
        createCaseRequest.populateCaseInfo(caseObj);
        caseObj.Origin = OPEN_WEB_CASE_RC_EVENTS_ORIGIN;

        // if default contact is used, paid support logic will not be applied
        CaseCreateStrategy.populateCaseInfoRCEvents(caseObj);

        if (isDefaultContact) {
            String description = 'First Name : ' + firstName
                + '\nLast Name : ' + lastName
                + '\nEmail : ' + email
                + '\n';
            caseObj.description = description + caseObj.description;
            caseObj.Customer_contact_email__c = email; // Storing temp contact email in custom field for sending ack email
        }

        return caseObj;
    }

    public static Case populateCaseInfoRCEvents(Case buildedCase) {
        buildedCase.ownerId = new GroupSelector().selectQueueByDeveloperName(RC_EVENTS_QUEUE)
            .executeQuery()[0].Id;
        buildedCase.Case_Severity__c = RC_EVENTS_DEFAULT_SEVERITY_MEDIUM;

        // To bypass any logic that might override the OwnerId or Record Type set above
        CaseTriggerHandler.bypassForRCEvents = true;

        return buildedCase;
    }

    public static Case buildCase(Map<String,Object> req) {
        String uid = StringHelper.safeString(req.get('uid'));
        String userEmail = StringHelper.safeString(req.get('userEmail'));

        Contact contact = CaseAPIUtil.getContact(uid, userEmail, new String[]{'Id', 'AccountId'});
        
        SCWrappers.CaseRequestAPI createCaseRequest = (SCWrappers.CaseRequestAPI) JSON.deserialize(
            JSON.serialize(req),
            SCWrappers.CaseRequestAPI.class
        );

        Case caseObj = new Case(
            ContactId = contact.Id,
            AccountId = contact.AccountId,
            Account = (Account) new AccountSelector().selectAccountsForCaseAPI(new Set<Id>{contact.AccountId}).executeQuery()[0],
            IsVisibleInSelfService = true
        );

        createCaseRequest.populateCaseInfo(caseObj);

        return caseObj;
    }

    public static ICaseCreateStrategy getStrategy(Map<String,Object> req) {
        
        String rtId = StringHelper.safeString(req.get('recordTypeId'));
        String rtName = StringHelper.safeString(req.get('recordType'));
        Boolean isDataSubjectRequest = BooleanHelper.toBoolean(req.get('isDataSubjectRequest'));
        Boolean isOpenRCEventsRequest = BooleanHelper.toBoolean(req.get('isRingCentralOpenEventsAccount'));

        ICaseCreateStrategy selectedStrategy = null;

        if (isDataSubjectRequest) {
            selectedStrategy = new CaseCreateDataSubjectRequest();
        } else if (isOpenRCEventsRequest) {
            selectedStrategy = new CaseCreateOpenRCEventsRequest();
        } else if (String.isBlank(rtId) && String.isBlank(rtName)) {
            selectedStrategy = new CaseCreateDefault();
        } else {
            
            String errorMessage = INVALID_RECORDTYPE;

            if (String.isBlank(rtId)) {
                selectedStrategy = STRATEGY_BY_RT_NAME.get(rtName);
            } else {
                selectedStrategy = STRATEGY_BY_RT_ID.get(rtId);
                errorMessage = INVALID_RECORDTYPE_ID;
            }

            if (selectedStrategy == null) {
                throw new HandledException(errorMessage);
            }
        }

        return selectedStrategy;
    }

    public with sharing class CaseCreateSalesCustForm implements ICaseCreateStrategy {
        private final String GENERAL_SUPPORT_QUEUE = 'General_Support_Queue';

        public void validate(Map<String,Object> req) {
            String subject = StringHelper.safeString(req.get('subject'));
            String description = StringHelper.safeString(req.get('description'));
            String uid = StringHelper.safeString(req.get('uid'));
            String userEmail = StringHelper.safeString(req.get('userEmail'));
            String caseCategory = StringHelper.safeString(req.get('caseCategory'));
            String escalateTo = StringHelper.safeString(req.get('escalateTo'));
    
            if(CaseAPIUtil.hasBlankString(new String[]{caseCategory, escalateTo, subject, description})) {
                throw new HandledException(CaseCreateAPIController.ERROR_MESSAGE_SALES_CUST_FORM);
            }
    
            if(CaseAPIUtil.hasBlankString(new String[]{uid, userEmail})) {
                throw new HandledException(CaseCreateAPIController.ERROR_MESSAGE_UID_EMAIL_ARE_REQUIRED);
            }
        }
        
        public String create(Map<String,Object> req) {
            if (req.containsKey('isGdpr')) {
                req.remove('isGdpr'); //The isGdpr key will be removed in the future and this validation will no longer be required.
            }
            
            Case buildedCase = CaseCreateStrategy.buildCase(req);

            String caseCategory = StringHelper.safeString(req.get('caseCategory'));
            String escalateTo = StringHelper.safeString(req.get('escalateTo'));
            String timezone = StringHelper.safeString(req.get('timezone'));

            if (String.isNotBlank(timezone)) {
                List<String> validTimezoneValues = AquivaHelper.getPicklistValues('Case', 'Timezone__c');
                if (!validTimezoneValues.contains(timezone)) {
                    throw new HandledException(CaseCreateAPIController.ERROR_MESSAGE_INVALID_TIMEZONE_VALUE);
                }
            }

            buildedCase.recordTypeId = CaseHelper.RT_ID_SALES_CUST_FORM;
            buildedCase.Case_Category__c = caseCategory;
            buildedCase.Support_Escalate_To__c = escalateTo;
            buildedCase.Timezone__c = timezone;
            buildedCase.ownerId = getOwnerId(req);

            insert buildedCase;

            return String.valueOf(buildedCase.Id);
        }

        private Id getOwnerId(Map<String,Object> req) {
            
            String uid = StringHelper.safeString(req.get('uid'));
            String userEmail = StringHelper.safeString(req.get('userEmail'));
    
            Contact contact = CaseAPIUtil.getContact(uid, userEmail, new String[]{
                'Account.RC_Brand__c',
                'Account.Enterprise_Support_Start_Date__c',
                'Account.Enterprise_Support_End_Date__c',
                'Account.Total_MRR__c'
            });

            Boolean isPartnerSoldEnterpriseSupport = ContactHelper.isPartnerSoldEnterpriseSupport(contact);

            return new GroupSelector()
                .selectGroupBasedOnDeveloperNames(new Object[]{new String[]{
                    isPartnerSoldEnterpriseSupport ? ENTREPRISE_QUEUE_DEVELOPER_NAME : GENERAL_SUPPORT_QUEUE}
                })
                .executeQuery()[0].Id;
        }
    }
    
    public with sharing class CaseCreateDeveloperPortal implements ICaseCreateStrategy {
        
        public void validate(Map<String,Object> req) {
            String origin = StringHelper.safeString(req.get('origin'));
            String useCaseType = StringHelper.safeString(req.get('useCaseType'));
            String priority = StringHelper.safeString(req.get('priority'));
            String uid = StringHelper.safeString(req.get('uid'));
            String subject = StringHelper.safeString(req.get('subject'));
            String type = StringHelper.safeString(req.get('type'));
            String ownerId = StringHelper.safeString(req.get('ownerId'));
            String description = StringHelper.safeString(req.get('description'));
            String extensionNumber = StringHelper.safeString(req.get('extensionNumber'));

            if (CaseAPIUtil.hasBlankString(new String[]{
                origin, useCaseType, priority, uid, subject, type, ownerId, description
            })) {
                throw new HandledException(CaseCreateAPIController.ERROR_MESSAGE_DEVELOPER_PORTAL);
            }
            // Validate extensionNumber - if provided, it cannot be null or empty
            if (req.containsKey('extensionNumber')) {
                Object extRaw = req.get('extensionNumber');
                if (extRaw == null || String.valueOf(extRaw).trim() == '' || String.isBlank(extensionNumber)) {
                    throw new HandledException(CaseCreateAPIController.ERROR_MESSAGE_INVALID_EXTENSION_NUMBER);
                }
            }
        }
        
        public String create(Map<String,Object> req) {
            String origin = StringHelper.safeString(req.get('origin'));
            String useCaseType = StringHelper.safeString(req.get('useCaseType'));
            String description = StringHelper.safeString(req.get('description'));
            String priority = StringHelper.safeString(req.get('priority'));
            String uid = StringHelper.safeString(req.get('uid'));
            String subject = StringHelper.safeString(req.get('subject'));
            String type = StringHelper.safeString(req.get('type'));
            String ownerId = StringHelper.safeString(req.get('ownerId'));

            String email = StringHelper.safeString(req.get('email'));
            String contactPhone = StringHelper.safeString(req.get('contactPhone'));
            String application = StringHelper.safeString(req.get('application'));
            Boolean forProduction = (Boolean) req.get('forProduction');

            Decimal extensionNumber = null;
            if (req.containsKey('extensionNumber')) {
                extensionNumber = Decimal.valueOf(String.valueOf(req.get('extensionNumber')));
            }

            Contact cont = null;
            Account acc = null;
            Boolean isOrphanCase = false;
            try {
                acc = (Account) new AccountSelector()
                    .selectAccountsByUserIds(new Object[]{new String[]{
                        uid
                    }})
                    .executeQuery()[0];

                cont = CaseAPIUtil.getContact(uid, email, new String[]{'Id'});
            } catch(Exception e) {
                acc = getAccountForOrphanCases();
                isOrphanCase = true;
            }

            Case buildedCase = new Case(
                ContactId = cont?.Id,
                AccountId = acc.Id,
                Type = type,
                subject = subject,
                ownerId = ownerId,
                origin = origin,
                priority = priority,
                Use_Case_Type__c = useCaseType,
                Case_Contact_Phone__c = contactPhone,
                Case_Contact_Email__c = email,
                Case_Account_Number__c = uid,
                Application__c = application,
                For_Production__c = forProduction != null && forProduction,
                Description = description,
                recordTypeId = CaseHelper.RT_ID_DEVELOPER_PORTAL,
                BizServ_Developer_Comments__c =  isOrphanCase ?
                    'enterprise user id : ' +  uid + '\nContact email: ' + email : 
                    '',
                IsVisibleInSelfService = true,
                Extension_number__c = extensionNumber
            );

            insert buildedCase;

            buildedCase = (Case) new CaseSelector()
                .selectCasesByIds(new Set<Id>{buildedCase.Id})
                .selectField(Case.CaseNumber)
                .executeQuery()[0];

            if (isOrphanCase) {
                Task taskReminder = new Task(
                    OwnerId = Id.valueOf(ownerId),
                    Subject = 'The account for case #' + buildedCase.CaseNumber + ' has not been found, please reassign.',
                    Description = 'Enterprise User ID and Contact Email are also stored in the "Developer / QA Comments" case field.' +
                        '\nEnterprise User Id: ' + uid + 
                        '\nContact Email: ' + email,
                    ActivityDate = Date.today(),
                    WhatId = buildedCase.Id,
                    Type = 'Other',
                    IsReminderSet = true,
                    ReminderDateTime = Datetime.now(),
                    SE_Stage__c = null
                );

                insert taskReminder;
            }

            return String.valueOf(buildedCase.Id);
        }

        private Account getAccountForOrphanCases(){
            String idAccountForOrphanCases = SnapInsSettings__c.getInstance().IdAccountForOrphanCases__c;

            List<Account> accs = (List<Account>) new AccountSelector()
                .selectAccountById(idAccountForOrphanCases)
                .executeQuery();

            if (accs.isEmpty()) {
                throw new HandledException(CaseCreateAPIController.ERROR_MESSAGE_UID_INVALID);
            }

            return accs[0];
        }
    }
    
    public with sharing class CaseCreateDefault implements ICaseCreateStrategy {
        public void validate(Map<String,Object> req) {
            String subject = StringHelper.safeString(req.get('subject'));
            String description = StringHelper.safeString(req.get('description'));
            String selectedProduct = StringHelper.safeString(req.get('selectedProduct'));
            String severityLevel = StringHelper.safeString(req.get('severityLevel'));
            String timezone = StringHelper.safeString(req.get('timezone'));
            String firstName = StringHelper.safeString(req.get('firstName'));
            String lastName = StringHelper.safeString(req.get('lastName'));
            String gdprEmail = StringHelper.safeString(req.get('gdprEmail'));
            String uid = StringHelper.safeString(req.get('uid'));
            String userEmail = StringHelper.safeString(req.get('userEmail'));
            Boolean euCitizen = (Boolean) req.get('euCitizen');
            Boolean isGdpr = (Boolean) req.get('isGdpr');
            String extensionNumber = StringHelper.safeString(req.get('extensionNumber'));
    
            if (isGdpr == null) {
                throw new HandledException(
                    CaseCreateAPIController.ERROR_MESSAGE_GDPR_REQUIRED
                );
            }

            if (isGdpr && (CaseAPIUtil.hasBlankString(new String[]{firstName, lastName, gdprEmail}) || euCitizen == null)) {
                throw new HandledException(
                    CaseCreateAPIController.ERROR_MESSAGE_ISGDPR
                );
            }
    
            if( isGdpr && !selectedProduct.equalsIgnoreCase(HelperCaseDispatch.PRODUCT_ASSISTANCE_GDPR)) {
                throw new HandledException(
                    CaseCreateAPIController.ERROR_MESSAGE_INVALID_SELECTED_PRODUCT
                );
            }

            if(!isGdpr && CaseAPIUtil.hasBlankString(new String[]{subject, description, selectedProduct, timezone, severityLevel})) {
                throw new HandledException(
                    CaseCreateAPIController.ERROR_MESSAGE_NOT_GDPR
                );
            }
    
            if(!isGdpr && CaseAPIUtil.hasBlankString(new String[]{uid, userEmail})) {
                throw new HandledException(
                    CaseCreateAPIController.ERROR_MESSAGE_UID_EMAIL_ARE_REQUIRED
                );
            }

            // Validate extensionNumber - if provided, it cannot be null or empty
            if (req.containsKey('extensionNumber') && String.isBlank(extensionNumber)) {
                throw new HandledException(
                    CaseCreateAPIController.ERROR_MESSAGE_INVALID_EXTENSION_NUMBER
                );
            }
        }

        public String create(Map<String,Object> req) {
            Case buildedCase = CaseCreateStrategy.buildCase(req);
        
            HelperCaseDispatch.assignQueue(buildedCase, null);
            
            // LTR-2556 
            if (buildedCase.Product_Assistance__c == RC_EVENTS_PRODUCT_VALUE) {
                CaseCreateStrategy.populateCaseInfoRCEvents(buildedCase);
            } else {
                //PBC-19650
                if (buildedCase.Product_Assistance__c == 'Phone' 
                    && buildedCase.Product_Assistance_Lvl2__c == 'Porting/Number transfer'
                ) {
                    buildedCase.RecordTypeId = CaseHelper.RT_ID_PORTING_PHONE;
                }

                String uid = StringHelper.safeString(req.get('uid'));
                String userEmail = StringHelper.safeString(req.get('userEmail'));
        
                Contact contact = CaseAPIUtil.getContact(uid, userEmail, new String[]{
                    'Account.RC_Brand__c',
                    'Account.Sub_Brand__c',
                    'Account.Enterprise_Support_Start_Date__c',
                    'Account.Enterprise_Support_End_Date__c',
                    'Account.Total_MRR__c',
                    'Account.Service_Status__c',
                    'Account.IsRingCx__c'
                });

                if (contact != null && contact.Account != null) {
                    String accountBrand = contact.Account.RC_Brand__c;
                    String accountSubBrand = contact.Account.Sub_Brand__c;
                    
                    //  New Logic for Contact center case Routing
                    if (buildedCase.Origin == CaseHelper.CASE_ORIGIN_WEB
                        && buildedCase.RecordTypeId == CaseHelper.RT_ID_SUPPORT_CASE
                        && (contact.Account.Service_Status__c == AccountHelper.SERVICE_STATUS_CONTRACT_COMPLETE || contact.Account.IsRingCx__c == True)) {

                        Id contractQueueId = getQueueId(System.Label.Contact_Center_Queue);
                        if (contractQueueId != null) {
                            buildedCase.OwnerId = contractQueueId;
                            insert buildedCase;
                            return String.valueOf(buildedCase.Id);
                        } else {
                            throw new HandledException(CaseCreateAPIController.CONTACT_CENTER_QUEUE_NAME_NOT_FOUND);
                        }
                    }
                
                    // Fetch all custom settings records
                    Map<String, Rise_Partner_CRM_Configuration__c> risePartnerSettings = Rise_Partner_CRM_Configuration__c.getAll();
                    
                    if (risePartnerSettings != null && !risePartnerSettings.isEmpty()) {
                        for (Rise_Partner_CRM_Configuration__c setting : risePartnerSettings.values()) {
                            //Check if IsCaseReRouting is true and brand & sub-brand match
                            if (setting != null 
                                && setting.Is_Case_ReRouting__c 
                                && accountBrand != null && accountBrand.equalsIgnoreCase(setting.Brand__c) 
                                && ((String.isNotBlank(accountSubBrand) && accountSubBrand.equalsIgnoreCase(setting.Name)) 
                                    || (String.isBlank(accountSubBrand) && accountBrand.equalsIgnoreCase(setting.Name))))
                                    {
                                    
                                    //Assign to the corresponding queue dynamically
                                    Id queueId = getQueueId(setting.Queue_Name__c);
                                    if (queueId != null) {
                                        buildedCase.OwnerId = queueId;
                                    } else {
                                        throw new HandledException(CaseCreateAPIController.RISE_ERROR_MESSAGE_QUEUE_NAME_NOT_FOUND);
                                    }
                                    if (String.isNotBlank(setting.Record_Type_Name__c)) {
                                        Id recordTypeId = getRecordTypeId(setting.Record_Type_Name__c);
                                        if (recordTypeId != null) {
                                            buildedCase.RecordTypeId = recordTypeId;
                                        } else {
                                            throw new HandledException(CaseCreateAPIController.RISE_ERROR_MESSAGE_RECORD_TYPE_NAME_NOT_FOUND);
                                        }
                                    }
                                    break;
                                }
                        }
                    } else {
                        throw new HandledException(CaseCreateAPIController.RISE_ERROR_MESSAGE_CUSTOM_SETTING_NOT_FOUND);
                    }
                    
                }

                if (ContactHelper.isPartnerSoldEnterpriseSupport(contact) && buildedCase.Product_Assistance__c != 'Billing') {
                    buildedCase.OwnerId = new GroupSelector()
                        .selectGroupBasedOnDeveloperNames(new Object[]{new String[]{ENTREPRISE_QUEUE_DEVELOPER_NAME}})
                        .executeQuery()[0].Id;
                }

                if (buildedCase.Product_Assistance__c == 'Billing' && buildedCase.Product_Assistance_Lvl2__c == 'Monthly Credit Limit Increase') {
                    buildedCase.Case_Subcategory__c = 'Others';
                }
            }

            insert buildedCase;

            return String.valueOf(buildedCase.Id);
        }

        private Id getQueueId(String queueName) {
            if (String.isNotBlank(queueName)) {
                List<Group> queueList = [SELECT Id FROM Group WHERE DeveloperName = :queueName LIMIT 1];
                return (!queueList.isEmpty()) ? queueList[0].Id : null;
            }
            return null;
        }                        
        private Id getRecordTypeId(String recordTypeName) {
            if (String.isNotBlank(recordTypeName)) {
                List<RecordType> rtList  = [SELECT Id FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = :recordTypeName LIMIT 1];
                return (!rtList.isEmpty()) ? rtList[0].Id : null;
            }
            return null;
        }  

    }

    public with sharing class CaseCreateDataSubjectRequest implements ICaseCreateStrategy {

        public void validate(Map<String, Object> req) {

            String firstName = StringHelper.safeString(req.get('firstName'));
            String lastName = StringHelper.safeString(req.get('lastName'));
            String email = StringHelper.safeString(req.get('email'));
            String privacyFirstName = StringHelper.safeString(req.get('privacyFirstName'));
            String privacyLastName = StringHelper.safeString(req.get('privacyLastName'));
            String privacyEmail = StringHelper.safeString(req.get('privacyEmail'));
            String action = StringHelper.safeString(req.get('action'));
            String changeAdditionalInformation = StringHelper.safeString(req.get('changeAdditionalInformation'));
            String country = StringHelper.safeString(req.get('country'));
            String state = StringHelper.safeString(req.get('state'));
            String additionalInformation = StringHelper.safeString(req.get('additionalInformation'));
            String roleName = StringHelper.safeString(req.get('roleName'));
            String relation = StringHelper.safeString(req.get('relation'));
            //Added as a part of new req for PBC-22325     
            String isRingCentralEventAccount = StringHelper.safeString(req.get('isRingCentralEventsAccount'));
            String isNiceContactCenterAccount = StringHelper.safeString(req.get('isNiceContactCenterAccount'));
            String niceCCContactIds = StringHelper.safeString(req.get('niceCCContactIds'));
            String niceCCAdditionalInfo = StringHelper.safeString(req.get('niceCCAdditionalInfo'));
        }

        public String create(Map<String, Object> req) {

            String firstName = StringHelper.safeString(req.get('firstName'));
            String lastName = StringHelper.safeString(req.get('lastName'));
            String email = StringHelper.safeString(req.get('email'));
            String privacyFirstName = StringHelper.safeString(req.get('privacyFirstName'));
            String privacyLastName = StringHelper.safeString(req.get('privacyLastName'));
            String privacyEmail = StringHelper.safeString(req.get('privacyEmail'));
            String action = StringHelper.safeString(req.get('action'));
            String changeAdditionalInformation = StringHelper.safeString(req.get('ChangeAdditionalInformation'));
            String country = StringHelper.safeString(req.get('country'));
            String state = StringHelper.safeString(req.get('state'));
            String additionalInformation = StringHelper.safeString(req.get('additionalInformation'));
            String roleName = StringHelper.safeString(req.get('roleName'));
            String relation = StringHelper.safeString(req.get('relation'));
            //Added as a part of new req for PBC-22325
            String isRingCentralEventAccount = StringHelper.safeString(req.get('isRingCentralEventsAccount'));
            String isNiceContactCenterAccount = StringHelper.safeString(req.get('isNiceContactCenterAccount'));
            String niceCCContactIds = StringHelper.safeString(req.get('niceCCContactIds'));
            String niceCCAdditionalInfo = StringHelper.safeString(req.get('niceCCAdditionalInfo'));
            
            // Fetch fixed DSR Account UID and Contact Email from Custom Metadata
            DSR_Fixed_Records__mdt fixedRecord = [
                SELECT Fixed_Account_UID__c, Fixed_Contact_Email__c 
                FROM DSR_Fixed_Records__mdt 
                LIMIT 1
            ];
            
            // Null check for custom metadata
            if (fixedRecord == null || String.isBlank(fixedRecord.Fixed_Account_UID__c) || String.isBlank(fixedRecord.Fixed_Contact_Email__c)) {
                throw new HandledException(CaseCreateAPIController.DSR_ERROR_MESSAGE_CUSTOM_METADATA_NOT_FOUND);
            }
            
            String fixedAccountUID = fixedRecord.Fixed_Account_UID__c;
            String fixedContactEmail = fixedRecord.Fixed_Contact_Email__c;
            
            
            // Step 1: Query the fixed account using AccountSelector
            List<Account> accounts = new AccountSelector()
                .selectAccountsByUserIds(new List<Object>{ new String[]{ fixedAccountUID } })
                .executeQuery();
            
            if (accounts.isEmpty()) {
                throw new HandledException(CaseCreateAPIController.DSR_ERROR_MESSAGE_UID_INVALID);
            }
                       
            
            Account fixedAccount = accounts[0];
            
            // Step 2: Query the fixed contact using ContactSelector
            List<Contact> contacts = new ContactSelector()
                .selectContactForAPI(new List<Object>{ fixedAccountUID, fixedContactEmail }, new String[]{ 'Id' })
                .executeQuery();

            if (contacts.isEmpty()) {
                throw new HandledException(CaseCreateAPIController.DSR_ERROR_MESSAGE_CONTACT_NOT_FOUND);
            }
            
            Contact fixedContact = contacts[0];

            String description = 'Relation : ' + relation
                + '\nFirst Name : ' + firstName
                + '\nLast Name : ' + lastName
                + '\nEmail : ' + email
                + '\nPrivacy First Name : ' + privacyFirstName
                + '\nPrivacy Last Name : ' + privacyLastName
                + '\nPrivacy Email : ' + privacyEmail
                + '\nRole Name: ' + roleName
                + '\nAction : ' + action
                + '\nRingCentral Events Account: ' + (String.isNotBlank(isRingCentralEventAccount) ? isRingCentralEventAccount : 'No');
            
            // Include Change Additional Information only if action is "Change personal information"
            if (String.isNotBlank(action) && action.contains('Change personal information')) {
                description += '\nChange Details : ' + (String.isNotBlank(changeAdditionalInformation) ? changeAdditionalInformation : 'Not provided');
            }
            
            
            // Include NICE Contact Center fields explicitly
            description += '\nNICE Contact Center account : ' + 
                (String.isNotBlank(isNiceContactCenterAccount) ? isNiceContactCenterAccount : 'No');
            
            if (String.isNotBlank(isNiceContactCenterAccount) && isNiceContactCenterAccount.equalsIgnoreCase('Yes')) {
                description += '\nNICE Contact Center account contact IDs : ' + 
                    (String.isNotBlank(niceCCContactIds) ? niceCCContactIds : 'Not provided') +
                    '\nNICE Contact Center account additional information : ' + 
                    (String.isNotBlank(niceCCAdditionalInfo) ? niceCCAdditionalInfo : 'Not provided');
            }
            
            description += '\nCountry : ' + country
                + '\nState : ' + state
                + '\nAdditional Information : ' + additionalInformation;
            
            Id queueId = HelperCaseDispatch.getGdprQueue();

            Case dsrCaseRecord = new Case(
                ContactId = fixedContact.Id,
                AccountId = fixedAccount.Id,
                Subject = 'Data Subject Request by ' + email + ' requesting ' + roleName,
                OwnerId = HelperCaseDispatch.getGdprQueue(),
                Priority = 'Medium',
                Origin = 'Portal',
                Case_Contact_Email__c = email,
                Description = description,
                RecordTypeId = CaseHelper.RT_ID_GDPR_REQUEST,
                IsVisibleInSelfService = true
            );

            insert dsrCaseRecord;

            return String.valueOf(dsrCaseRecord.Id);
        }
   
    }
    public with sharing class CaseCreateGDPR implements ICaseCreateStrategy {
        public void validate(Map<String,Object> req) {
            String uid = StringHelper.safeString(req.get('uid'));
            String email = StringHelper.safeString(req.get('userEmail'));
            String firstName = StringHelper.safeString(req.get('firstName'));
            String lastName = StringHelper.safeString(req.get('lastName'));
            String gdprEmail = StringHelper.safeString(req.get('gdprEmail'));
            Boolean euCitizen = (Boolean) req.get('euCitizen');
            String selectedProduct = StringHelper.safeString(req.get('selectedProduct'));

            if (CaseAPIUtil.hasBlankString(new String[]{firstName, lastName, gdprEmail}) || euCitizen == null) {
                throw new HandledException(
                    CaseCreateAPIController.ERROR_MESSAGE_ISGDPR
                );
            }

            if(!selectedProduct.equalsIgnoreCase(HelperCaseDispatch.PRODUCT_ASSISTANCE_GDPR)) {
                throw new HandledException(
                    CaseCreateAPIController.ERROR_MESSAGE_INVALID_SELECTED_PRODUCT
                );
            }

            if(CaseAPIUtil.hasBlankString(new String[]{uid, email})) {
                throw new HandledException(
                    CaseCreateAPIController.ERROR_MESSAGE_UID_EMAIL_ARE_REQUIRED
                );
            }
        }

        public String create(Map<String,Object> req) {

            req.put('isGdpr', true); //Will be removed when old logic is removed.

            Case buildedCase = CaseCreateStrategy.buildCase(req);
        
            HelperCaseDispatch.assignQueue(buildedCase, null);

            String uid = StringHelper.safeString(req.get('uid'));
            String userEmail = StringHelper.safeString(req.get('userEmail'));
    
            Contact contact = CaseAPIUtil.getContact(uid, userEmail, new String[]{
                'Account.RC_Brand__c',
                'Account.Enterprise_Support_Start_Date__c',
                'Account.Enterprise_Support_End_Date__c',
                'Account.Total_MRR__c'
            });

            if (ContactHelper.isPartnerSoldEnterpriseSupport(contact)) {
                buildedCase.OwnerId = new GroupSelector()
                    .selectGroupBasedOnDeveloperNames(new Object[]{new String[]{ENTREPRISE_QUEUE_DEVELOPER_NAME}})
                    .executeQuery()[0].Id;
            }

            insert buildedCase;

            return String.valueOf(buildedCase.Id);
        }
        
    }

    public with sharing class CaseCreateOpenRCEventsRequest implements ICaseCreateStrategy {

        public void validate(Map<String,Object> requestMap) {
            String firstName = (String) requestMap.get('firstName');
            String lastName = (String) requestMap.get('lastName');
            String email = (String) requestMap.get('email');
    
            if(CaseAPIUtil.hasBlankString(new String[]{lastName, email})) {
                throw new HandledException(CaseCreateAPIController.ERROR_MESSAGE_NAME_EMAIL_ARE_REQUIRED);
            }
        }
        
        public String create(Map<String,Object> req) {
            Case buildedCase = CaseCreateStrategy.populateAccountContactInfoRCEvents(req);
            
            insert buildedCase;
            buildedCase = (Case) new CaseSelector()
            .selectCasesByIds(new Set<Id>{buildedCase.Id})
            .selectField(Case.CaseNumber)
            .executeQuery()[0];

            caseNumber = buildedCase.CaseNumber;

            return String.valueOf(buildedCase.Id);
        }

    }
}