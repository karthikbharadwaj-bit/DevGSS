public class PortingESBHelper {
    public static final String PortingInNeuStar = 'Porting - In (NeuStar)';
    public static final String PortingInRC = 'Porting - In (RC)';
    public static final String PortingInTelus = 'Porting - In (TELUS)';
    public static final String PortingInRCUK = 'Porting - In (RC UK)';
    public static final String PortingIn  = 'Porting - In';
    public static final String PortingVanity  = 'Porting - Vanity';
    public static final String PortingInRCCA = 'Porting - In (RC CA)';
    public static final String PortingInATT  = 'Porting - In (ATT)';
    public static final String PortingInBTCloud  = 'Porting - In (BT Cloud)';
    public static final String SystemOperations = 'System Operations';
    public static final String PORTING_IN_RC_AU = 'Porting - In (RC AU)';
    public static final String PORTING_IN_RC_EU = 'Porting - In (RC EU)';
    public static final String PORTING_IN_RC_IVN = 'Porting - In IVN/Global Office';
    public static final String PORTING_IN_INTELIQUENT = 'Porting - In (Inteliquent)';

    @TestVisible
    private static final String PORTING_CASE_TYPE_IS_NULL = 'Porting case type is null.';

    public static final Set<String> RT_PORTING_CASES = new Set<String> {
        PortingIn,
        PortingInNeuStar,
        PortingInRC,
        PortingInRCUK,
        PortingInRCCA,
        PortingInBTCloud,
        PortingInATT,
        PortingInTelus,
        SystemOperations,
        PORTING_IN_RC_AU,
        PORTING_IN_RC_EU,
        PORTING_IN_RC_IVN,
        PORTING_IN_INTELIQUENT
    };

    private static final List<String> acceptedCaseTypesForESbSend = new List<String> {
        PortingInNeuStar,
        PortingInRC,
        PortingInTelus,
        PortingInRCUK,
        PortingInRCCA,
        PortingInATT,
        PortingInBTCloud,
        SystemOperations
    };
    private static final Set<String> RT_FOR_CONTACT_UPDATE = new Set<String>{
        PORTING_IN_RC_AU,
        PORTING_IN_RC_EU,
        PORTING_IN_RC_IVN
    };
    private static final Set<String> STATUSES_FOR_ESB = new Set<String>{
        CaseHelper.CASE_STATUS_REJECT,
        CaseHelper.CASE_STATUS_SUBMIT,
        CaseHelper.CASE_STATUS_TRANSFER_DATE,
        CaseHelper.CASE_STATUS_WAITING_ON_LOA,
        CaseHelper.CASE_STATUS_ADDITIONAL_INFO,
        CaseHelper.CASE_STATUS_PORT_VALIDATION,
        CaseHelper.CASE_STATUS_CANCELLED,
        CaseHelper.CASE_STATUS_CLOSED
    };
    public static final String integrationUserName = 'RCESB';
    private static final String bizIntegrationUserName = 'RCESB Biz';
    public static final String defaultEscalateToValue = 'Telco Ops Numbers';
    private static final String teleporterUserName = 'Teleporter';
    private static final String teleporterBizUserName = 'Teleporter Biz';

    //List of unique service user names that can be used
    private static final List<String> serviceUserNames = new List<String>{
        integrationUserName, bizIntegrationUserName
    };
    private static final List<String> caseTypeForContactBinding = new List<String>{
        SystemOperations
    };
    private static final Map<Id, RecordTypeInfo> caseRecordTypesByIds = CaseHelper.RT_INFO_BY_ID;
    private static final Map<String, Id> serviceUsers = getServiceUserIds();

    /**************************
    *This method is used to validate the input accepting for RCESB user only.
    *@param caseList(trigger.new)
    *@param rtMapByName(schema describe)
    **************************/
    public static void validateOnBeforeInsertEvent(List<Case> caseList, Map<ID,Schema.RecordTypeInfo> rtMapByName) {
    for(Case caseObj : caseList) {
          caseObj.IsUpdatePermitted__c = true;
            Boolean isNeuStarCase = (caseObj.RecordTypeId != null && rtMapByName.get(caseObj.RecordTypeId ).getName() == 'Porting - In (NeuStar)' ? true : false);
      Boolean isPortingRcCase = (caseObj.RecordTypeId != null &&  rtMapByName.get(caseObj.RecordTypeId ).getName() == 'Porting - In (RC)' ? true : false);
      Boolean isPortingTelusCase = (caseObj.RecordTypeId != null &&  rtMapByName.get(caseObj.RecordTypeId ).getName() == 'Porting - In (TELUS)' ? true : false);
      Boolean isPortingRcUKCase = (caseObj.RecordTypeId != null &&  rtMapByName.get(caseObj.RecordTypeId ).getName() == 'Porting - In (RC UK)' ? true : false);
      Boolean isPortingRcCaCase = (caseObj.RecordTypeId != null &&  rtMapByName.get(caseObj.RecordTypeId ).getName() == PortingInRCCA ? true : false);
      Boolean isPortingBtCloudCase = (caseObj.RecordTypeId != null &&  rtMapByName.get(caseObj.RecordTypeId ).getName() == PortingInBTCloud ? true : false);
      Boolean isPortingAttCase = (caseObj.RecordTypeId != null &&  rtMapByName.get(caseObj.RecordTypeId ).getName() == PortingInATT ? true : false);
            Boolean RCESB_USER = ((UserInfo.getName() == integrationUserName || UserInfo.getName() == bizIntegrationUserName) ? true : false);
            Boolean TELEPORTER_USER = ((UserInfo.getName() == teleporterUserName || UserInfo.getName() == teleporterBizUserName) ? true : false);
            if(isNeuStarCase || isPortingRcCase || isPortingTelusCase || isPortingRcUKCase || isPortingRcCaCase || isPortingBtCloudCase || isPortingAttCase) {
                if(!RCESB_USER && !TELEPORTER_USER) {
                    caseObj.IsUpdatePermitted__c = false;
                }
            }
        }
    }
    /**************************
    * This method is used to validate the input accepting for RCESB/Support Manager Parting, Support Agent Porting users only.
    *@param caseList(trigger.new)
    *@param oldCaseMap(trigger.oldMap)
    *@param rtMapById(schema for care record type ids)
    *@param rtMapByName(schema describe for case record type names)
    *@param prof(user profile)
    **************************/
    public static void validateOnBeforeUpdateEvent(List<Case> caseList, Map<Id, Case> oldCaseMap, Profile prof) {
        for(Case caseObj : caseList) {
            if(caseObj.RecordTypeId == null) {
                caseObj.RecordTypeId.addError(PORTING_CASE_TYPE_IS_NULL);
            }

            String currCaseTypeName = caseRecordTypesByIds.get(caseObj.RecordTypeId).Name;
            Boolean isNeuStarCase = currCaseTypeName == PortingInNeuStar;
            caseObj.IsUpdatePermitted__c = true;
            Case oldCaseObj = oldCaseMap.get(caseObj.Id);

            Boolean SYSTEM_ADMIN = prof.Name == 'System Administrator';
            //Boolean SUPPORT_PREMIUM_PORTING = prof.Name == 'Support Porting Shipping';
            //Start of Addition for EU Phase 3
            List<String> SPSList = new List<String>();
            List<EU_Component_reference__mdt> profileList = [Select DeveloperName, Values__c from EU_Component_reference__mdt where Apex_Classes__c like '%PortingESBHelper%'];
            for(EU_Component_reference__mdt profRec:profileList){
            SPSList.addall(profRec.Values__c.contains(',')?profRec.Values__c.split(','):new List<String>{profRec.Values__c});
            }
            //End of Addition for EU Phase 3
            Boolean RCESB_USER = (UserInfo.getName() == integrationUserName || UserInfo.getName() == bizIntegrationUserName);
            Boolean TELEPORTER_USER = ((UserInfo.getName() == teleporterUserName || UserInfo.getName() == teleporterBizUserName) ? true : false);

            Boolean hasCustomPermissionAgentPorting = FeatureManagement.checkPermission('Support_Agent_Porting_Permission');
            Boolean hasCustomPermissionManagerPorting = FeatureManagement.checkPermission('Support_Manager_Porting_Permission');

            TelusIntegrationSettings__c settings = TelusIntegrationSettings__c.getOrgDefaults();
            if(settings == null || settings.Connection_User_Safe_Id__c == null){
            settings.Connection_User_Safe_Id__c = HardcodedIdsMapper.getMatchedObjectId('00580000003S04QAAS');
        }
            /**************************** Change of Status, Reject Reason or Estimated completion date ***************************/

        if(
            caseObj.Status != oldCaseObj.Status
            || caseObj.Porting_Reject_Reason__c !=  oldCaseObj.Porting_Reject_Reason__c
            || caseObj.Porting_Estimated_Completion_Date__c != oldCaseObj.Porting_Estimated_Completion_Date__c
        ) {
            if(acceptedCaseTypesForESbSend.contains(currCaseTypeName) || RT_FOR_CONTACT_UPDATE.contains(currCaseTypeName))
            {
                if(!isNeuStarCase) {
                    if(RCESB_USER || SYSTEM_ADMIN || TELEPORTER_USER || hasCustomPermissionAgentPorting || hasCustomPermissionManagerPorting || UserInfo.getUserId() == settings.Connection_User_Safe_Id__c) {
                        caseObj.Porting_last_status_change_date__c = System.now();
                    } else {
                        caseObj.IsUpdatePermitted__c = false;
                    }
                } else {
                    if(!RCESB_USER && !TELEPORTER_USER) {
                        caseObj.IsUpdatePermitted__c = false;
                    }
                }
            }
        }
            /**************************** ********************************************************************** ***************************/
            if(isNeuStarCase
              && (oldCaseObj.Convert_to_Internal_Porting__c != caseObj.Convert_to_Internal_Porting__c)) {
              if(RCESB_USER || TELEPORTER_USER || SYSTEM_ADMIN || hasCustomPermissionAgentPorting || hasCustomPermissionManagerPorting) {
                  if(caseObj.Convert_to_Internal_Porting__c != null
                    && (caseObj.Convert_to_Internal_Porting__c == 'Porting - In (RC)')) {
                          caseObj.RecordTypeId = CaseHelper.RT_ID_PORTING_RC;
                      }

                    caseObj.IsUpdatePermitted__c = true;
              } else {
                caseObj.IsUpdatePermitted__c = false;
              }
            }

            /**************************** ********************************************************************** ***************************/

            if(isNeuStarCase
               && (oldCaseObj.isLastCaseCommentPublic__c != caseObj.isLastCaseCommentPublic__c
                 || oldCaseObj.Last_Case_Comment__c != caseObj.Last_Case_Comment__c
                 || oldCaseObj.Last_Public_Comment_Timestamp__c != caseObj.Last_Public_Comment_Timestamp__c) &&
                (!RCESB_USER && !SYSTEM_ADMIN && !hasCustomPermissionAgentPorting && !hasCustomPermissionManagerPorting && !TELEPORTER_USER)) {
                    caseObj.IsUpdatePermitted__c = false;
            }
        }
    }
    /**************************
    *This method is used to validate the fields for creating NeuStar/Porting - In RC/Prting - RC UK cases.
    *@param caseList(trigger.new)
    *@param rtMapByName(schema describe)
    *@param oldCaseMap(trigger.oldMap)
    **************************/
    public static void validateOnAfterUpdateEvent(List<Case> caseList,  Map<Id, Case> oldCaseMap, Map<ID,Schema.RecordTypeInfo> rtMapByName) {
        for(Case newCaseObj : caseList) {
            Case oldCaseObj = oldCaseMap.get(newCaseObj.Id);
            Boolean isNeuStarCase = (rtMapByName.get(newCaseObj.RecordTypeId ).getName() == 'Porting - In (NeuStar)' ? true : false);
            Boolean RCESB_USER = (UserInfo.getName() == integrationUserName || UserInfo.getName() == bizIntegrationUserName);

            String currCaseTypeName = caseRecordTypesByIds.get(newCaseObj.RecordTypeId).Name;

            //Will bypass all SystemOperation cases if they doesn't have filled RC_Porting_Order_ID__c
            //Case 08236630 Cannot Edit SF Cases in Our Queue https://rc.my.salesforce.com/5003400001833Ub
            if (newCaseObj.RecordTypeId == CaseHelper.RT_ID_SYSTEM_OPERATIONS && newCaseObj.RC_Porting_Order_ID__c == null) {
                continue;
            }

            if(acceptedCaseTypesForESbSend.contains(currCaseTypeName)
                || (isCaseForEsb(newCaseObj, oldCaseMap.get(newCaseObj.Id), currCaseTypeName)
                    && Feature_Toggle__c.getInstance().ESBPortingNewFlow__c)) {
                Boolean errorOccured = false;
                if(newCaseObj.RC_Porting_Order_ID__c == null) {
                    newCaseObj.RC_Porting_Order_ID__c.addError('Porting Order Id must not be blank.');
                    errorOccured = true;
                }
                if(String.isBlank(newCaseObj.RC_User_Id__c)) {
                    newCaseObj.RC_User_Id__c.addError('Enterprise Account Id must not be blank in associate Account.');
                    errorOccured = true;
                }
                if(newCaseObj.Status == null) {
                    newCaseObj.Status.addError('Status can not be none.');
                    errorOccured = true;
                }
                if(newCaseObj.Porting_last_status_change_date__c == null) {
                    newCaseObj.Porting_last_status_change_date__c.addError('Porting last status change date can not be empty');
                    errorOccured = true;
                }

                if(currCaseTypeName != PortingInNeuStar) {
                    if(
                        newCaseObj.Status == 'Rejected'
                        && newCaseObj.Porting_Reject_Reason__c == null
                    ) {
                        newCaseObj.Porting_Reject_Reason__c.addError('Porting Reason is missing.');
                        errorOccured = true;
                    }

                    if(
                        newCaseObj.Status == 'Transfer Date Confirmed'
                        && newCaseObj.Porting_Estimated_Completion_Date__c == null
                    ) {
                        newCaseObj.Porting_Estimated_Completion_Date__c.addError('Porting Estimated Completion Date is Missing.');
                        errorOccured = true;
                    }
                } else {
                    if(newCaseObj.Porting_last_status_change_date__c < oldCaseObj.Porting_last_status_change_date__c) {
                        newCaseObj.Porting_last_status_change_date__c.addError('Porting Last Status can not be past date.');
                        errorOccured = true;
                    }
                }

                if(
                    !RCESB_USER
                    && !errorOccured
                    && !isNeuStarCase
                    && !Test.isRunningTest()
                ) {
                    RC_ESB_PortingOrderHelper.updatePortingOrder(newCaseObj.id);
                } else if (isCaseForEsb(newCaseObj, oldCaseMap.get(newCaseObj.Id), currCaseTypeName)
                    && Feature_Toggle__c.getInstance().ESBPortingNewFlow__c) {
                    RC_ESB_PortingOrderHelper.updatePortingOrder(newCaseObj.id);
                }
            }
        }
    }

    /********************************************************************************************************
    * @Description : Method to fill Porting Case contact if on case insert/Update its empty                 *
    * @Params      : List of Case(Trigger.new)                                                              *
    * @param       : rtMapByName(schema describe)                                                           *
    * @Return      : void                                                                                   *
    * @Added By    : Simplion Technologies                                                                  *
    ********************************************************************************************************/
    public static void populatePrimaryContactForPortingCase(List<Case> caseList, Map<ID,Schema.RecordTypeInfo> rtMapByName){
        Map<Id,Id> accountToContactMap = new Map<Id,Id>();


        // --------------------------------------------------------------
        // check ConnectionReceivedId and RecordTypeId for Cases
        // if found (not empty ConnectionReceivedId AND (it connection is 'In contact' or 'RingCentral') ) and EmptyRecordType
        // set 'inContact order' RecordType
        Boolean doCheckConnectionIdAndRTs = false;

        for(Case item : caseList) {
          if(item.ConnectionReceivedId != null && item.RecordTypeId == null) {
            doCheckConnectionIdAndRTs = true;
          }
        }

        if(doCheckConnectionIdAndRTs) {

          List<PartnerNetworkConnection> connectionList = [select id, ConnectionName from PartnerNetworkConnection where (ConnectionName = 'RingCentral' OR ConnectionName = 'inContact, Inc.') AND ConnectionStatus = 'Accepted'];

          Set<Id> connectionIds = new Set<Id>();

          for(PartnerNetworkConnection item : connectionList) {
            connectionIds.add(item.Id);
          }

          if( connectionIds.size() > 0 ) {

            Id inContactRTId = CaseHelper.RT_ID_INCONTACT_ORDER;

            for(Case item : caseList) {
              if( (item.ConnectionReceivedId != null && item.RecordTypeId == null) && connectionIds.contains(item.ConnectionReceivedId) ) {
                item.RecordTypeId = inContactRTId;
              }
            }

          }

        }
        // --------------------------------------------------------------

        Set<Id> accountIdSet = getAccountIdsFromPortingCases(caseList, rtMapByName);
        List<AccountContactRole> accountContactRoleList = [SELECT AccountId, Contact.Name,Contact.FirstName,Contact.LastName,isPrimary,Role,Contact.Email,
                                                Contact.Phone,ContactId FROM AccountContactRole WHERE AccountId IN: accountIdSet AND IsPrimary = true];
        for(AccountContactRole acr : accountContactRoleList){
            accountToContactMap.put(acr.AccountId,acr.ContactId);
        }

        for(Case caseObj : caseList){
            if(caseObj.AccountId != NULL && accountToContactMap != NULL && accountToContactMap.containsKey(caseObj.AccountId) && accountToContactMap.get(caseObj.AccountId) != NULL){
                caseObj.ContactId = accountToContactMap.get(caseObj.AccountId);
            }
        }
    }

    @TestVisible
    private static Set<Id> getAccountIdsFromPortingCases(List<Case> caseList, Map<ID,Schema.RecordTypeInfo> rtMapByName) {

        Set<Id> accountIds = new Set<Id>();
        for(Case caseObj : caseList){
            if (caseObj.AccountId == NULL) {
                continue;
            }
            if (caseObj.ContactId != NULL) {
                continue;
            }
            String recordTypeName = rtMapByName.get(caseObj.RecordTypeId).getName();
            if (RT_PORTING_CASES.contains(recordTypeName) == false) {
                continue;
            }
            accountIds.add(caseObj.AccountId);
        }
        return accountIds;
    }

    public static void updateCaseContact(List<Case> triggerIncome) {
        List<Case> chosenCases = new List<Case>();
        List<String> accsForCheck = new  List<String>();
        List<String> emailsForCheck = new  List<String>();
        String serviceUserId;
        if(UserInfo.getName() == integrationUserName){
            serviceUserId = serviceUsers.get(integrationUserName);
        } else if (UserInfo.getName() == bizIntegrationUserName){
            serviceUserId = serviceUsers.get(bizIntegrationUserName);
        }

        for(Case curCase : triggerIncome) {
            RecordTypeInfo curRecType = caseRecordTypesByIds.get(curCase.RecordTypeId);
            if(
                curRecType == null
                || !caseTypeForContactBinding.contains(curRecType.name)
                || UserInfo.getUserId() != serviceUserId
            ) {
                continue;
            } else {
                setCaseDefaultValues(curCase);
                if(
                    String.isEmpty(curCase.AccountId)
                    || String.isEmpty(curCase.Contact_Email__c)
                ) {
                    continue;
                }
            }
            chosenCases.add(curCase);
            accsForCheck.add(curCase.AccountId);
            emailsForCheck.add(curCase.Contact_Email__c);
        }
        if(chosenCases.size() == 0) {
            return;
        }
        Map<String, Map<String, String>> relatedEmailsToAccounts =
            mapContactsByAccountAndEmail(accsForCheck, emailsForCheck);

        for(Case cuCase : chosenCases) {
            String accId = cuCase.AccountId;
            if(!String.isEmpty(accId)) {
                Map<String, String> accEmails = relatedEmailsToAccounts.get(accId);
                if(accEmails == null) {
                    continue;
                }
                String contactId = accEmails.get(cuCase.Contact_Email__c);
                if(!String.isEmpty(contactId)) {
                    cuCase.ContactId = contactId;
                }
            }
        }
    }

    public static void updateContactName(List<Case> casesToUpdate) {
        Set<Id> accountIds = new Set<Id>();
        Set<String> contactIds = new Set<String>();
        Map<String, List<Contact>> contactsByEmail = new Map<String, List<Contact>>();

        for (Case cs : casesToUpdate) {
            if (isContactForUpdate(cs)) {
                if (cs.AccountId != null) {
                    accountIds.add(cs.AccountId);
                }
                if (cs.Contact_Email__c != null) {
                    contactIds.add(cs.Contact_Email__c);
                }
            }
        }
        if (!accountIds.isEmpty()
            && !contactIds.isEmpty()) {
            for (Contact cont : [
                SELECT Id, AccountId, Email
                FROM Contact
                WHERE AccountId IN :accountIds
                AND Email IN :contactIds
            ]) {
                String contactPass = cont.AccountId + ':' + cont.Email;
                if (contactsByEmail.get(contactPass) != null) {
                    contactsByEmail.get(contactPass).add(cont);
                } else {
                    contactsByEmail.put(contactPass, new List<Contact>{ cont });
                }
            }
            for (Case cs : casesToUpdate) {
                if (isContactForUpdate(cs)) {
                    String casePass = cs.AccountId + ':' + (cs.Contact_Email__c == null
                                                            ? 'null'
                                                            : cs.Contact_Email__c);
                    cs.Subject = 'Port-In Case for ' + cs.Account_Name__c;
                    cs.Priority = 'Medium';
                    cs.OwnerId = UserInfo.getUserId();
                    if (contactsByEmail.get(casePass) != null
                        && contactsByEmail.get(casePass).size() == 1) {
                        cs.ContactId = contactsByEmail.get(casePass).get(0).Id;
                    }
                    if (!Test.isRunningTest()) {
                        RC_ESB_PortingOrderHelper.updatePortingOrder(cs.Id);
                    }
                }
            }
        }
    }

    private static Boolean isContactForUpdate(Case cs) {
        return ((UserInfo.getName() == integrationUserName || UserInfo.getName() == bizIntegrationUserName)
                && RT_FOR_CONTACT_UPDATE.contains(caseRecordTypesByIds.get(cs.RecordTypeId).Name)
                && cs.Contact_Email__c != null
                && cs.AccountId != null);
    }

    private static Boolean isCaseForEsb(Case cs, Case oldCase, String caseRt) {
        return (RT_FOR_CONTACT_UPDATE.contains(caseRt)
                && cs.get(Case.Status) != oldCase.get(Case.Status)
                && STATUSES_FOR_ESB.contains(cs.Status)
                && (HardcodedIdsMapper.getMatchedObjectId('00580000005RAeeAAG')
                                .left(15)
                                .equals(String.valueOf(cs.CreatedById).left(15))
                ||	HardcodedIdsMapper.getMatchedObjectId('005Hr00000CBxD7IAL')
                                .left(15)
                                .equals(String.valueOf(cs.CreatedById).left(15))));
    }

    private static Map<String, Map<String, String>> mapContactsByAccountAndEmail(List<String> relatedAccs, List<String> Emails) {
        List<Contact> relatedContacts = getRelatedContacts(relatedAccs, Emails);
        Map<String, Map<String, String>> res = new Map<String, Map<String, String>>();
        Map<String, List<String>> duplicates = new Map<String, List<String>>();
        for(Contact cont : relatedContacts) {
            String accId = cont.AccountId;
            String contEmail = cont.Email;
            Map<String, String> curAccMap = res.get(accId);
            if(curAccMap == null) {
                curAccMap =  new Map<String, String>();
            }
            List<String> dupsList = duplicates.get(accId);
            if(
                String.isEmpty(curAccMap.get(contEmail))
                    && (
                    dupsList == null
                        || !dupsList.contains(contEmail)
                )
                ) {
                curAccMap.put(contEmail, cont.Id);
            } else {
                if(dupsList == null) {
                    duplicates.put(accId, new List<String>{
                        contEmail
                    });
                } else {
                    dupsList.add(contEmail);
                }
                curAccMap.remove(contEmail);
            }
            res.put(accId, curAccMap);
        }
        return res;
    }

    private static List<Contact> getRelatedContacts(List<String> accList, List<String> emails) {
        return [
            SELECT Name, AccountId, Email
            FROM Contact
            WHERE AccountId IN :accList
            AND Email IN :emails
            AND Email != NULL
            AND AccountId != NULL
        ];
    }

    private static Map<String, Id> getServiceUserIds() {
        return getUserIdsByNames(serviceUserNames);
    }

    private static Map<String, Id> getUserIdsByNames(List<String> userNames) {
        Map<String, Id> res = new Map<String, Id>();
        List<User> users = [
            SELECT Id, Name
            FROM User
            WHERE Name IN :userNames
        ];
        for(User u : users) {
            res.put(u.Name, u.Id);
        }
        return res;
    }

    private static void setCaseDefaultValues(Case curCase) {
        curCase.Support_Escalate_To__c = defaultEscalateToValue;
        Id owner = getCaseOwnerByName(defaultEscalateToValue);
        curCase.OwnerId = String.isEmpty(owner)? curCase.OwnerId : owner;
    }

    private static Id getCaseOwnerByName(String Name) {
        String escalateToOwner = getUserGroupByName(Name).Id;
        if(String.isEmpty(escalateToOwner)) {
            escalateToOwner = serviceUsers.get(Name);
        }
        return escalateToOwner;
    }

    private static Group getUserGroupByName(String name) {
        List<Group> groups = [
            SELECT  Id, Name
            FROM Group
            WHERE Name = :name
            And Type = 'Queue'
        ];

        if(groups.size() != 1) {
            return null;
        }
        return groups[0];
    }

}