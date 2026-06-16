/**************************************************************************************************
* Project Name..........: Entitlement                                                             *
* File..................: EntitlementHelper.class                                                 *
* Version...............: 1.0                                                                     *
* Created by............: Simplion Technologies                                                   *
* Created Date..........: 26-06-2014                                                              *
* Last Modified by......: Simplion Technologies                                                   *
* Last Modified Date....: 26-06-2014                                                              *
* Description...........: Entitlement Helper Class, contains logic for entitlement creation,      *
*                         case assignment.                                                        *
**************************************************************************************************/

public class EntitlementHelper {

    // Declaring Variable & Constants
    private static final String SLA_WEB_SUPPORT_CASES = 'Web Support - Support Cases';
    private static final String EXPIRED = 'Expired';
    private static final String GENERAL_SUPPORT_QUEUE = 'General Support Queue';
    private static final String SUPPORT_CASE = 'Support-Case';
    private static final String CASE_ASSIGNED = 'Case Assigned';
    private static final String DEFAULT_ENTITLEMENT = 'Default';

    public static Map<Id, SlaProcess> slaMapStatic = new Map<Id, SlaProcess>();
    public static Map<Id, BusinessHours> businessHoursMapStatic = new Map<Id, BusinessHours>();

    /******************************************************************************
    * @Description : Check if the user is Portal User or not.                     *
    * @Params      : void                                                         *
    * @Return      : Boolean                                                      *
    ******************************************************************************/
    public static Boolean isPortalUser() {
        return UserInfo.getProfileId() == ProfileHelper.PROFILE_ID_CUSTOMER_PORTAL_USER;
    }

    /******************************************************************************
    * @Description : Check if the entitlement enabled or not.                     *
    * @Params      : void                                                         *
    * @Return      : Boolean                                                      *
    ******************************************************************************/
    public static Boolean IsEntitlementsEnabled() {
        Map<String, Boolean> statusMap = new Map<String, Boolean>();
        try {
            for( String status : EntitlementEnable__c.getAll().keySet()) {
                EntitlementEnable__c entitlementEnabled = EntitlementEnable__c.getAll().get(status);
                statusMap.put(entitlementEnabled.Name, entitlementEnabled.IsEntitlementsEnabled__c);
            }
        } catch(Exception ex) {
            System.debug('Exception============'+ex.getMessage());
            System.debug('Exception============'+ex.getStackTraceString());
            return false;
        }
        return (statusMap.get('IsEntitlementsEnabled') == null ? false : statusMap.get('IsEntitlementsEnabled'));
    }

    /******************************************************************************
    * @Description : Method to create Entitlements for new Account.               *
    * @Params      : List<Account>, Map<Id, Account>                              *
    * @Return      : List<Entitlement>                                            *
    ******************************************************************************/
    public static List<Entitlement> createEntitlements(List<Account> accountList, Map<Id, Account> oldMap) {

        // Fetching map of all configured SLA Process.
        Map<Id, SlaProcess> slaProcessMap = getSLAProcessMap();
        // Fetching map of all configured Business hours.
        Map<Id, BusinessHours> businessHrsMap = getBusinessHoursMap();
        // Map to contain Account, No.of Entitlement attached to it.
        Map<Id, Integer> entOnAccount = new Map<Id, Integer>();
        // Map to contain AccountId, Entitlement.
        Map<Id, Entitlement> accountToEntitlementMap = new Map<Id, Entitlement>();
        // Map to contain AccountId, List<Entitlements>.
        Map<Id, List<Entitlement>> accountToEntitlementListMap = new Map<Id, List<Entitlement>>();
        Set<Id> accountIds = new Set<Id>();
        List<Entitlement> entitlements = new List<Entitlement>();
        Account oldAccountObj = null;
        List<String> entNames = new List<String>();

        // Fetching map of Account, related entitlement.
        Map<String, List<Entitlement_Account_Configuration__c>> entitlmentAccountConfig = fetchEntitlementConfiguration();
        Map<Id,Id> accountSLAIdMap =  new Map<Id,Id>();

        system.debug('#### entitlmentAccountConfig - '+entitlmentAccountConfig);
        for(Account accObj : accountList) {
            accountIds.add(accObj.Id);
            if(!String.isBlank(accObj.RC_Brand__c) && entitlmentAccountConfig != null && entitlmentAccountConfig.get(accObj.RC_Brand__c) != null){
                for(Entitlement_Account_Configuration__c thisRecord : entitlmentAccountConfig.get(accObj.RC_Brand__c)){
                    if( !String.isBlank(accObj.RC_Service_name__c) && accObj.RC_Brand__c == thisRecord.RC_Brand__c && accObj.RC_Service_name__c == thisRecord.Service_Name__c){

                        if(isNumberOfDLsNullOrLessEqualOne(accObj.Number_of_DL_s__c,thisRecord.Number_of_DLs__c) ){
                            system.debug('#### low range');
                            accountSLAIdMap.put(accObj.Id, thisRecord.SLA_Process__c);
                        }
                        if(isNumberOfDLsMidRange(accObj.Number_of_DL_s__c,thisRecord.Number_of_DLs__c) ){
                            system.debug('#### mid range');
                            accountSLAIdMap.put(accObj.Id, thisRecord.SLA_Process__c);
                        }
                        if(isNumberOfDLsHighRange(accObj.Number_of_DL_s__c,thisRecord.Number_of_DLs__c) ){
                            system.debug('#### high range');
                            accountSLAIdMap.put(accObj.Id, thisRecord.SLA_Process__c);
                        }
                    }
                }
            }

            if (accountSLAIdMap.get(accObj.Id) != null && slaProcessMap.get(accountSLAIdMap.get(accObj.Id)) != null) {
                entNames.add(accObj.Name + ' - ' + slaProcessMap.get(accountSLAIdMap.get(accObj.Id)).Name);
            }
        }

        List<Entitlement> entlts = (List<Entitlement>) new StdEntitlementSelector()
            .selectStdEntitlements()
            .setQueryBindings(new List<Object>{accountIds, entNames})
            .setCondition('AccountId IN :bind0 AND Name IN :bind1 AND Status != \'Expired\'')
            .executeQuery();

        if (!entlts.isEmpty()) {
            for (Entitlement entObj : entlts) {
                List<Entitlement> entList = new List<Entitlement>();
                if (accountToEntitlementListMap.get(entObj.AccountId) != null) {
                    entList = accountToEntitlementListMap.get(entObj.AccountId);
                }
                entList.add(entObj);
                accountToEntitlementListMap.put(entObj.AccountId, entList);
            }
        }

        for(Account accObj : accountList) {
            if(accountToEntitlementListMap != null && accountToEntitlementListMap.size() != 0 && accountToEntitlementListMap.get(accObj.Id) != null) {
                for(Entitlement entObj : accountToEntitlementListMap.get(accObj.Id)) {
                    String entName = '';
                    if(accountSLAIdMap.get(accObj.Id)!=null && slaProcessMap.get(accountSLAIdMap.get(accObj.Id))!=null){
                        entName = accObj.Name + ' - '+slaProcessMap.get(accountSLAIdMap.get(accObj.Id)).Name;
                    }
                    if(entObj.Name.EqualsIgnoreCase(entName) && (entObj.Status != EXPIRED)) {
                        accountToEntitlementMap.put(accObj.Id, entObj);
                        Integer counter = entOnAccount.get(accObj.Id);
                        if(counter == null){
                            counter = 0;
                        }
                        entOnAccount.put(accObj.Id, ++counter);
                    }
                }
            }
        }

        entitlements = createAccountEntitlement(accountList, oldMap, accountToEntitlementMap);
        if(entitlements.size() != 0) {
            List<Entitlement> createList = new List<Entitlement>();
            List<Entitlement> updateList = new List<Entitlement>();
            for(Entitlement entObj : entitlements) {
                if(entObj.id != null){
                    updateList.add(entObj);
                } else{
                    createList.add(entObj);
                }
            }
        }
        return entitlements;
    }
    // Web Support - Support Cases
    /******************************************************************************
    * @Description : Fetch all Active SLA Process.                                *
    * @Params      : void                                                         *
    * @Return      : List<SlaProcess>                                             *
    ******************************************************************************/
    public static List<SlaProcess> getSLAProcess() {
        if (slaMapStatic.isEmpty()){
            slaMapStatic = new Map<Id, SlaProcess>([SELECT Id, Name FROM SlaProcess WHERE IsActive=true]);
        }
        return slaMapStatic.values();
    }

    /******************************************************************************
    * @Description : Create SLA Process Map      .                                *
    * @Params      : void                                                         *
    * @Return      : Map<String, SlaProcess>                                      *
    ******************************************************************************/
    public static Map<Id, SlaProcess> getSLAProcessMap() {
        Map<Id, SlaProcess> slaProcessMap = new Map<Id, SlaProcess>();
        for(SlaProcess slaProcess : getSLAProcess()) {
            slaProcessMap.put(slaProcess.Id, slaProcess);
        }
        return slaProcessMap;
    }

    /******************************************************************************
    * @Description : Fetch all Active Business Hours.                             *
    * @Params      : void                                                         *
    * @Return      : List<BusinessHours>                                          *
    ******************************************************************************/
    public static List<BusinessHours> getBusinessHours() {
        if (businessHoursMapStatic.isEmpty()){
            businessHoursMapStatic = new Map<Id, BusinessHours>([SELECT Id, Name FROM BusinessHours WHERE IsActive=true]);
        }
        return businessHoursMapStatic.values();
    }

    /******************************************************************************
    * @Description : Create Business Hours Map   .                                *
    * @Params      : void                                                         *
    * @Return      : Map<String, BusinessHours>                                   *
    ******************************************************************************/
    public static Map<Id, BusinessHours> getBusinessHoursMap() {
        Map<Id, BusinessHours> nameToHoursMap = new Map<Id, BusinessHours>();
        for(BusinessHours businessHrs : getBusinessHours()) {
            nameToHoursMap.put(businessHrs.Id, businessHrs);
        }
        return nameToHoursMap;
    }


    /******************************************************************************
    * @Description : Get attached entitlement for the provided Account Id.        *
    * @Params      : Id                                                           *
    * @Return      : List<Entitlement>                                            *
    ******************************************************************************/
    public static List<Entitlement> getEntitlement(Id accountId) {
        try{
            if(accountId != null) {
                Account accountObj = [SELECT Id, Name, RC_Service_name__c, RC_Brand__c, Number_of_DL_s__c,
                                             (SELECT Id, Name, Type, AccountId, SlaProcessId, StartDate, Status, BusinessHoursId FROM Entitlements)
                                      FROM Account
                                      WHERE Id =: accountId];
                if(accountObj != null) {
                    String expectedEntitleName = accountObj.Name + ' - ' + SLA_WEB_SUPPORT_CASES;
                    Boolean alreadyAssociated = false;
                    for(Entitlement entObj : accountObj.Entitlements) {
                        if(entObj.Name.containsIgnoreCase(expectedEntitleName) && (entObj.Status != 'Expired')) {
                            return new List<Entitlement>{entObj};
                        }
                    }
                    return createEntitlements(new List<Account>{accountObj}, null);
                }
            }
        }catch(Exception ex){
            System.debug('Exception============'+ex.getMessage());
            System.debug('Exception============'+ex.getStackTraceString());
        }
        return null;
    }

    /******************************************************************************
    * @Description : Close Milestone attached to the Case.                        *
    * @Params      : List<Case>, Map<Id, Case>                                    *
    * @Return      : void                                                         *
    ******************************************************************************/
    public static void closeCaseAssignedMilestone(List<Case> caseList, Map<Id, Case> oldCaseMap) {

        List<Id> updateCases = new List<Id>();
        Set<Id> accountIds = new Set<Id>();
        List<Group> queues = (List<Group>) new GroupSelector()
            .selectGroups()
            .setCondition('Name = :bind0')
            .setQueryBindings(new List<Object>{GENERAL_SUPPORT_QUEUE})
            .setLimit(1)
            .setQueryCaching(true)
            .executeQuery();

        for (Case caseObj : caseList) {
            accountIds.add(caseObj.AccountId);
        }

        for (Case caseObj : caseList) {
           if (OpportunityHelper.getOppRecordTypeMap(SUPPORT_CASE) == caseObj.RecordTypeId
               && caseObj.Case_Assignment_Timestamp__c == null) {
                Case oldCaseObj = oldCaseMap.get(caseObj.Id);
                if (queues.size() > 0 && oldCaseObj.OwnerId  == queues[0].Id && oldCaseObj.OwnerId != caseObj.OwnerId) {
                    updateCases.add(caseObj.Id);
                }
           }
        }

        if (!updateCases.isEmpty()) {
            MilestoneUtils.completeMilestone(updateCases, CASE_ASSIGNED , System.now());
        }
    }

    /******************************************************************************
    * @Description : Fetch Entitlement parameters from Custom Setting.            *
    * @Params      : void                                                         *
    * @Return      : Map<String, List<Entitlement_Account_Configuration__c>>      *
    ******************************************************************************/
    public static Map<String, List<Entitlement_Account_Configuration__c>> fetchEntitlementConfiguration(){

        Map<String, List<Entitlement_Account_Configuration__c>> entitlmentAccountConfig =  new Map<String, List<Entitlement_Account_Configuration__c>>();


        for(Entitlement_Account_Configuration__c thisRecord : Entitlement_Account_Configuration__c.getAll().values()){
            if(entitlmentAccountConfig.get(thisRecord.RC_Brand__c) != null){
                entitlmentAccountConfig.get(thisRecord.RC_Brand__c).add(thisRecord);
            }else{
                entitlmentAccountConfig.put(thisRecord.RC_Brand__c, new List<Entitlement_Account_Configuration__c>{thisRecord});
            }
        }
        return entitlmentAccountConfig;
    }

    /******************************************************************************
    * @Description : Create entitlement from different config filters.            *
    * @Params      : List<Account>, Map<Id, Account>, Map<Id, Entitlement>        *
    * @Return      : List<Entitlement>                                            *
    ******************************************************************************/
    public static List<Entitlement> createAccountEntitlement(List<Account> accountList, Map<Id, Account> oldMap, Map<Id, Entitlement> accountToEntitlementMap){

        List<Entitlement> entitlements = new List<Entitlement>();
        try{
            // Fetching map of all configured SLA Process.
            Map<Id, SlaProcess> slaProcessMap = getSLAProcessMap();
            // Fetching map of all configured Business Hours.
            Map<Id, BusinessHours> businessHrsMap = getBusinessHoursMap();
            // Fetching map of Account, related entitlement.
            Map<String, List<Entitlement_Account_Configuration__c>> entitlmentAccountConfig = fetchEntitlementConfiguration();

            Account oldAccountObj = null;

            for(Account accountObj : accountList) {
                oldAccountObj = (oldMap == null ? null : oldMap.get(accountObj.Id));

                if(!String.isBlank(accountObj.RC_Brand__c) &&
                    entitlmentAccountConfig.containsKey(accountObj.RC_Brand__c) &&
                    entitlmentAccountConfig.get(accountObj.RC_Brand__c) != null){

                        // Creating Entitlement object and assigning values to the fields.
                        Entitlement entitlement = new Entitlement();
                        entitlement.AccountId = accountObj.Id;
                        entitlement.StartDate = System.today();
                        entitlement.EndDate = null;
                        if(accountToEntitlementMap.get(accountObj.Id) != null) {
                            entitlement = accountToEntitlementMap.get(accountObj.Id);
                        }

                        Boolean hasDefault = true;
                        for(Entitlement_Account_Configuration__c thisRecord : entitlmentAccountConfig.get(accountObj.RC_Brand__c)){
                            entitlement.Type = thisRecord.Type__c;
                            system.debug('#### SLa Process Id - '+thisRecord.SLA_Process__c);
                            system.debug('#### SLA Process selected - '+slaProcessMap.get(thisRecord.SLA_Process__c));

                            if(!String.isBlank(accountObj.RC_Service_name__c) && accountObj.RC_Service_name__c.containsIgnoreCase(thisRecord.Service_Name__c)){
                                System.debug('#### isNumberOfDLsNullOrLessEqualOne - '+isNumberOfDLsNullOrLessEqualOne(accountObj.Number_of_DL_s__c,thisRecord.Number_of_DLs__c) );
                                if(isNumberOfDLsNullOrLessEqualOne(accountObj.Number_of_DL_s__c,thisRecord.Number_of_DLs__c) ){
                                    system.debug('#### Low Range Value');
                                    entitlement.SlaProcessId = (slaProcessMap.get(thisRecord.SLA_Process__c) != null ? slaProcessMap.get(thisRecord.SLA_Process__c).Id : null);
                                    entitlement.BusinessHoursId = ( businessHrsMap.get(thisRecord.Business_Hours__c) != null ?  businessHrsMap.get(thisRecord.Business_Hours__c).Id : null);
                                    hasDefault = false;
                                    entitlement.Name = accountObj.Name + ' - ' + (slaProcessMap.get(thisRecord.SLA_Process__c) != null ?
                                                                          slaProcessMap.get(thisRecord.SLA_Process__c).Name : '');
                                }

                                System.debug('#### isNumberOfDLsMidRange - '+isNumberOfDLsMidRange(accountObj.Number_of_DL_s__c,thisRecord.Number_of_DLs__c) );
                                if(isNumberOfDLsMidRange(accountObj.Number_of_DL_s__c,thisRecord.Number_of_DLs__c) ){
                                    system.debug('#### Mid Range Value');
                                    entitlement.SlaProcessId = (slaProcessMap.get(thisRecord.SLA_Process__c) != null ? slaProcessMap.get(thisRecord.SLA_Process__c).Id : null);
                                    entitlement.BusinessHoursId = ( businessHrsMap.get(thisRecord.Business_Hours__c) != null ?  businessHrsMap.get(thisRecord.Business_Hours__c).Id : null);
                                    hasDefault = false;
                                    entitlement.Name = accountObj.Name + ' - ' + (slaProcessMap.get(thisRecord.SLA_Process__c) != null ?
                                                                          slaProcessMap.get(thisRecord.SLA_Process__c).Name : '');
                                }

                                System.debug('#### isNumberOfDLsHighRange - '+isNumberOfDLsHighRange(accountObj.Number_of_DL_s__c,thisRecord.Number_of_DLs__c) );
                                if(isNumberOfDLsHighRange(accountObj.Number_of_DL_s__c,thisRecord.Number_of_DLs__c) ){
                                    system.debug('#### High Range Value');
                                    entitlement.SlaProcessId = (slaProcessMap.get(thisRecord.SLA_Process__c) != null ? slaProcessMap.get(thisRecord.SLA_Process__c).Id : null);
                                    entitlement.BusinessHoursId = ( businessHrsMap.get(thisRecord.Business_Hours__c) != null ?  businessHrsMap.get(thisRecord.Business_Hours__c).Id : null);
                                    hasDefault = false;
                                    entitlement.Name = accountObj.Name + ' - ' + (slaProcessMap.get(thisRecord.SLA_Process__c) != null ?
                                                                          slaProcessMap.get(thisRecord.SLA_Process__c).Name : '');
                                }

                                if(hasDefault){
                                    Entitlement_Account_Configuration__c defaultSetting =  new Entitlement_Account_Configuration__c();
                                    defaultSetting = Entitlement_Account_Configuration__c.getValues(DEFAULT_ENTITLEMENT);
                                    if(defaultSetting != null){
                                        entitlement.BusinessHoursId = (businessHrsMap.get(defaultSetting.Business_Hours__c) != null ?
                                                                       businessHrsMap.get(defaultSetting.Business_Hours__c).Id : null);
                                        entitlement.SlaProcessId = (slaProcessMap.get(defaultSetting.SLA_Process__c) != null ?
                                                                    slaProcessMap.get(defaultSetting.SLA_Process__c).Id : null);
                                        entitlement.Name = accountObj.Name + ' - ' + (slaProcessMap.get(thisRecord.SLA_Process__c) != null ?
                                                                          slaProcessMap.get(thisRecord.SLA_Process__c).Name : '');
                                    }
                                }
                            }
                        }
                        entitlements.add(entitlement);
                    }
                }
        }catch(Exception ex){
            System.debug('Exception============'+ex.getMessage());
            System.debug('Exception============'+ex.getStackTraceString());
        }
        System.debug('Entitlements to be inserted ------>'+entitlements);
        return entitlements;
    }

    /******************************************************************************
    * @Description : Method to determine the range of DL's (Lowest range),        *
    *                based on the configuration set in Custom Settings.           *
    * @Params      : Decimal, String                                              *
    * @Return      : Boolean                                                      *
    ******************************************************************************/
    public static Boolean  isNumberOfDLsNullOrLessEqualOne(Decimal intNumberOfDL, String strNumberOfDls){

        if( intNumberOfDL == null){
            return true;
        }
        System.debug('isNumberOfDLsNullOrLessEqualOne--->'+ strNumberOfDls.split('-'));
        if(!String.isBlank(strNumberOfDls) && intNumberOfDL != null && !strNumberOfDls.contains('+')){
            List<String> arrayNumberOfDL = strNumberOfDls.split('-');
            if(intNumberOfDL >= Decimal.valueOf(arrayNumberOfDL.get(0)) && intNumberOfDL <= Decimal.valueOf(arrayNumberOfDL.get(1))){
                return true;
            }
        }
        return false;
    }

    /******************************************************************************
    * @Description : Method to determine the range of DL's (Mid range),           *
    *                based on the configuration set in Custom Settings.           *
    * @Params      : Decimal, String                                              *
    * @Return      : Boolean                                                      *
    ******************************************************************************/
    public static Boolean  isNumberOfDLsMidRange(Decimal intNumberOfDL, String strNumberOfDls){
        System.debug('isNumberOfDLsMidRange--->'+ strNumberOfDls.split('-'));
        if(!String.isBlank(strNumberOfDls) && intNumberOfDL != null && !strNumberOfDls.contains('+')){
            List<String> arrayNumberOfDL = strNumberOfDls.split('-');
            if(intNumberOfDL>=Decimal.valueOf(arrayNumberOfDL.get(0)) && intNumberOfDL <= Decimal.valueOf(arrayNumberOfDL.get(1))){
                return true;
            }
        }
        return false;
    }

    /******************************************************************************
    * @Description : Method to determine the range of DL's (High range),          *
    *                based on the configuration set in Custom Settings.           *
    * @Params      : Decimal, String                                              *
    * @Return      : Boolean                                                      *
    ******************************************************************************/
    public static Boolean  isNumberOfDLsHighRange(Decimal intNumberOfDL, String strNumberOfDls){
        System.debug('isNumberOfDLsHighRange--->'+ strNumberOfDls.split('-'));
        if(!String.isBlank(strNumberOfDls) && intNumberOfDL != null && strNumberOfDls.contains('+')){
            String strNumberOfDL = strNumberOfDls.substring(0, strNumberOfDls.indexOf('+'));
            if(intNumberOfDL >= Decimal.valueOf(strNumberOfDL)){
                return true;
            }
        }
        return false;
    }

    /******************************************************************************
    * @Description : Create Map of Account.                                       *
    * @Params      : Set<String>                                                  *
    * @Return      : Map<Id, Account>                                             *
    ******************************************************************************/
    public static Map<Id, Account> getCaseAccountsMap(set<String> accountIds) {
        Map<Id, Account> mapAccounts = new Map<Id, Account>();
        if(accountIds != null) {
            mapAccounts = new Map<Id, Account>([SELECT Id, Name, RC_Service_name__c, RC_Brand__c, Number_of_DL_s__c
                                                FROM Account
                                                WHERE Id IN:accountIds]);
        }
        return mapAccounts;
    }

    /*******************************************************************************************************
    * @Description : Method to Assign created Entitlement on Cases based on the <record type , business hours>
    *                Contained in Custom Setting.                                                          *
    *                     - If Entitlement with Business Hours <-> CaseRecordType found,                     *
    *                       assign that the case to that Entitlement.                                        *
    *                     - If no Entitlement found, create a new Entitlement of that Business Hours,        *
    *                       SLA Process and attached it to the Account & Case.                               *
    *                     - If case escalated i.e., record type changed, find entitlement of                 *
    *                       new business hours, if found attach the case to that entitlement.                *
    *                     - If no entitlement found above, create a new Entitlement of that Business Hours,  *
    *                       SLA Process and attached it to the Account & Case.                               *
    * @Params      : List<Case>, String                                                                    *
    * @Return      : void                                                                                  *
    *******************************************************************************************************/
    public static void entitleAssignmentOncase(List<Case> caseList, String caseTiggerType){

        Entitlement entitleObj =  null;
        Set<String> setAccountIds = new Set<String>();
        Set<String> setCaseRecordTypeNames = new Set<String>();
        Map<Integer, Case> mapIntegerToCase = new Map<Integer, Case>();
        Map<Integer, Entitlement> mapIntegerToEntitle = new Map<Integer, Entitlement>();
        Map<Id, SlaProcess> slaProcessMap = getSLAProcessMap();
        Map<Id,Schema.RecordTypeInfo> rtMapById = Schema.SObjectType.Case.getRecordTypeInfosById();

        try{
            for (Case caseObj : caseList) {
                setAccountIds.add(caseObj.AccountId);
                setCaseRecordTypeNames.add(String.valueOf(rtMapById.get(caseObj.RecordTypeId).name));
            }

            Map<Id, Account> mapAccounts = getCaseAccountsMap(setAccountIds);

            Map<String,Entitlement_Case_ReType_Configuration__c> caseTypeEntitleConfigs =
                (Map<String, Entitlement_Case_ReType_Configuration__c>) Entitlement_Case_ReType_Configuration__c.getAll();
            Integer counter = 0;

            List<String> slaProcessIds = new List<String>();
            for (Entitlement_Case_ReType_Configuration__c config : caseTypeEntitleConfigs.values()) {
                if(setCaseRecordTypeNames.contains(config.Name)) {
                    slaProcessIds.add(config.SLAProcessId__c);
                }
            }

            List<Entitlement> slaEntitlementsList = (List<Entitlement>) new StdEntitlementSelector()
                .selectStdEntitlements()
                .setQueryBindings(new List<Object>{slaProcessIds,setAccountIds})
                .setCondition('SlaProcessId IN :bind0 AND AccountId IN :bind1 AND Status != \'Expired\'')
                .executeQuery();

            Map<String, List<Entitlement>> slaEntitlementsAccMap = new Map<String, List<Entitlement>>();
            for (Entitlement entitlement : slaEntitlementsList) {
                if (slaEntitlementsAccMap.get(entitlement.AccountId) == null) {
                    slaEntitlementsAccMap.put(entitlement.AccountId, new List<Entitlement>());
                }
                slaEntitlementsAccMap.get(entitlement.AccountId).add(entitlement);
            }


            for (Case caseObject : caseList) {
                entitleObj = new Entitlement();
                String caseRecordTypeName = String.valueOf(rtMapById.get(caseObject.RecordTypeId).name);
                Entitlement_Case_ReType_Configuration__c caseTypeEntitleConfig =
                    caseTypeEntitleConfigs.get(caseRecordTypeName);

                String accountName;
                if (mapAccounts != null && mapAccounts.get(caseObject.AccountId) != null) {
                    accountName = mapAccounts.get(caseObject.AccountId).Name;
                } else {
                    accountName = '';
                }

                if (caseTypeEntitleConfig != null) {
                    Boolean isNewEntitle = true;
                    String entName = accountName + ' - ' + slaProcessMap.get(caseTypeEntitleConfig.SLAProcessId__c).Name;
                    if (slaEntitlementsAccMap.get(caseObject.AccountId) != null) {
                        for(Entitlement objEntitlement : slaEntitlementsAccMap.get(caseObject.AccountId)) {
                            if (objEntitlement.SlaProcessId == caseTypeEntitleConfig.SLAProcessId__c) {
                                caseObject.EntitlementId = objEntitlement.Id;
                                isNewEntitle = false;
                            }
                        }

                        if (isNewEntitle && slaProcessMap.get(caseTypeEntitleConfig.SLAProcessId__c) != null) {
                            entitleObj.Name = entName;
                            entitleObj.AccountId = caseObject.AccountId;
                            entitleObj.StartDate = System.today();
                            entitleObj.EndDate = null;
                            entitleObj.BusinessHoursId = caseTypeEntitleConfig.Business_Hours_Id__c;
                            entitleObj.SlaProcessId = caseTypeEntitleConfig.SLAProcessId__c;
                            mapIntegerToCase.put(counter, caseObject);
                            mapIntegerToEntitle.put(counter, entitleObj);
                            counter++;
                        }
                    } else {
                        if (slaProcessMap.get(caseTypeEntitleConfig.SLAProcessId__c) != null) {
                            entitleObj.Name = entName;
                            entitleObj.AccountId = caseObject.AccountId;
                            entitleObj.StartDate = System.today();
                            entitleObj.EndDate = null;
                            entitleObj.BusinessHoursId = caseTypeEntitleConfig.Business_Hours_Id__c;
                            entitleObj.SlaProcessId = caseTypeEntitleConfig.SLAProcessId__c;
                            mapIntegerToCase.put(counter, caseObject);
                            mapIntegerToEntitle.put(counter, entitleObj);
                            counter++;
                        }
                    }
                }
            }
            //Insert Entitlement and attach it to the case.
            if (mapIntegerToEntitle != null && !mapIntegerToEntitle.isEmpty()) {
                upsert mapIntegerToEntitle.values();
                Integer position = 0;
                for (Case caseObject : caseList) {
                    if (mapIntegerToEntitle.get(position) != null && mapIntegerToCase.get(position) != null &&
                       mapIntegerToCase.get(position).AccountId == mapIntegerToEntitle.get(position).AccountId) {

                        caseObject.EntitlementId = mapIntegerToEntitle.get(position).Id;
                    }
                    position++;
                }
            }
        } catch(Exception ex) {
            System.debug('Exception============'+ex.getMessage());
            System.debug('Exception============'+ex.getStackTraceString());
            System.debug('Exception============'+ex.getLineNumber());
        }
    } /* End Of Entitlement assignment on case*/


    public static Decimal getDiscountValue(Entitlement__c ent) {
        Decimal discountValue = 0;
        Decimal discountNumber = ent.Discount__c == null ? 0 : ent.Discount__c;

        if (QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY.equalsIgnoreCase(ent.Discount_Type__c)) {
            discountValue = discountNumber;

        } else if (QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE.equalsIgnoreCase(ent.Discount_Type__c)) {
            discountValue = (ent.Price__c / 100) * discountNumber;

        }

        return discountValue;
    }

    public static List<Entitlement__c> filterEntitlementsByChargeTerm(List<Entitlement__c> entList) {
        List<Entitlement__c> resultList = new List<Entitlement__c>();

        for(Entitlement__c e : entList) {
            if (e.Product__r.Charge_Term__c == null
                || !e.Product__r.Charge_Term__c.equals(Product2Helper.CHARGE_TERM_ONE_TIME)) {
                    resultList.add(e);
                }
        }

        return resultList;
    }

    public static String getChargeTerm(Entitlement__c ent) {
        return String.isNotBlank(ent.ChargeTerm__c) ?
            ent.ChargeTerm__c :
            ent.Product__r.Charge_Term__c;
    }

    public static Entitlement__c getServiceEntitlement(Id quoteRtId, List<Entitlement__c> entitlements) {
        if(QuoteHelper.PROSERV_QUOTE_DEVELOPER_ID_SET.contains(quoteRtId)) {
            return null;
        }

        for (Entitlement__c ent : entitlements) {
            if (quoteRtId == QuoteHelper.RT_ID_SALES || quoteRtId == QuoteHelper.RT_ID_BILLING) {
                if (Product2Helper.isServicePlan(ent.Product__r)) {
                    return ent;
                }
            } else if (quoteRtId == QuoteHelper.RT_ID_CC) {
                if (Product2Helper.isCcService(ent.Product__r)) {
                    return ent;
                }
            }
        }
        return null;
    }

    public static List<Entitlement__c> getEntitlementsForQuote(List<Entitlement__c> entitlements, Quote qt, Id accountId) {
        List<Entitlement__c> result = new List<Entitlement__c>();
        Id quoteIdClause = QuoteHelper.isNewBillingQuote(qt) ? qt.Id : null;
        for (Entitlement__c ent : entitlements) {
            if (ent.Account__c == accountId &&
                ent.Quote__c == quoteIdClause) {
                result.add(ent);
            }
        }
        return result;
    }

    public static Boolean isNGBSEntitlement(Entitlement__c ent) {
        return ent.Quote__c != null;
    }

    public static void DeleteRelatedEntitlements(List<Quote> quotes) {
        Set<Id> quoteV2ToDelete = new Set<Id>();
        for (Quote quoteObj : quotes) {
            if (quoteObj.RecordTypeId == QuoteHelper.RT_ID_BILLING) {
                quoteV2ToDelete.add(quoteObj.Id);
            }
        }
        List<Entitlement__c> entsToDelete = [SELECT Id FROM Entitlement__c WHERE Quote__c IN :quoteV2ToDelete];
        try {
            if (entsToDelete.size() > 0) {
                delete entsToDelete;
            }
        } catch (DmlException e) {
            AquivaHelper.throwAquivaException('DeleteRelatedEntitlements.handle', e);
            System.debug('Failed to delete realted to quote entitlements ' + e.getMessage());
        }

    }

    public static Decimal getEntitlementEffectivePrice(Entitlement__c entl) {
        Decimal entlEffectivePrice = 0;
        Decimal discount = (entl.Discount__c == null) ? 0 : entl.Discount__c; // Case11297754: null check added because of SFDC exception with operator's argument
        if (entl.Discount_Type__c == QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY) {
            entlEffectivePrice = entl.Price__c - discount;
        } else if (entl.Discount_Type__c == QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE) {
            entlEffectivePrice = entl.Price__c * (100 - discount) / 100;
        }
        return entlEffectivePrice.setScale(2);
    }

    public static Decimal getEffectivePricePrecise(Decimal unitPrice, Decimal discount, String discountType, Boolean isCCService) {
        discount = discount == null ? 0 : discount;
        discountType = discountType == null ? '' : discountType;
        unitPrice = unitPrice == null ? 0 : unitPrice;
        if (isCCService) {
            return discountType == QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY ? unitPrice - discount : unitPrice * (100 - discount) / 100;
        } else {
            return discountType == QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY ? (unitPrice - discount).setScale(2) : (unitPrice * (100 - discount) / 100).setScale(2);
        }
    }

    /**
      * Create Entitlements
      * @param entitlementsMap map by Product2.ExtID__c
      * @param qt Quote object
      */
    public static void createEntitlements(Map<String, Entitlement__c> entitlementsMap, Quote qt) {
        if (!entitlementsMap.isEmpty()) {
            return;
        }

        NGBSAPI.initNgbsEndpoints(qt.Opportunity.isFedRamp__c);
        String billingId = qt.Account.Billing_ID__c;
        BillingWrappers.NGBSAccount ngbsAcc = NGBSAPI.getNGBSAccount(billingId);
        String packageId = QuoteHelper.getPackageId(qt.Package_Info__c);
        BillingWrappers.NGBSAccountPackage pkg = ngbsAcc.getPackageById(packageId);
        List<BillingWrappers.BillingInfoSummaryLicense> licenses = NGBSAPI.getNGBSBillingInfoSummaryLicenses(
            billingId,
            pkg.id
        );

        Map<String, BillingWrappers.BillingInfoSummaryLicense> licenseMap = SWNHelper.getLicenseMap(licenses);
        for (QuoteLineItem qli : qt.QuoteLineItems) {
            if (qli.Entitlement__c != null || licenseMap.get(qli.Product2.ExtID__c) == null) {
                continue;
            }
            Entitlement__c ent = getEntitlement(
                qt,
                qli.Product2.Id,
                licenseMap.get(qli.Product2.ExtID__c),
                pkg
            );
            entitlementsMap.put(qli.Product2.ExtID__c, ent);
        }
        insert entitlementsMap.values();
    }

    private static Entitlement__c getEntitlement(
        Quote qt,
        String productId,
        BillingWrappers.BillingInfoSummaryLicense license,
        BillingWrappers.NGBSAccountPackage pkg
        ) {
        return QuoteLineItemService.createBillingEntitlement(
            qt.AccountId,
            qt,
            productId,
            getBillingEnt(license, pkg)
        );
    }

    private static BillingWrappers.BillingEntitlement getBillingEnt(
        BillingWrappers.BillingInfoSummaryLicense license,
        BillingWrappers.NGBSAccountPackage pkg
    ) {
        /* case when package on account is POC or Trial */
        Decimal price = 0;

        /* qty of 'usage' licenses should always be 0 */
        Integer qty = license.qty;
        if (license.billingType == Product2Helper.BILLING_TYPE_USAGE) {
            qty = 0;
        }

        BillingWrappers.NGBSAccountPackage billingPkg = new BillingWrappers.NGBSAccountPackage();
        billingPkg.catalogId = pkg.catalogId;
        billingPkg.version = pkg.version;
        billingPkg.offerType = pkg.offerType;
        billingPkg.masterDuration = pkg.masterDuration;

        BillingWrappers.BillingDiscount discount = new BillingWrappers.BillingDiscount();
        discount.value = 0;

        BillingWrappers.BillingEntitlement result = new BillingWrappers.BillingEntitlement();
        result.elementId = license.catalogId;
        result.name = license.description;
        result.displayName = license.description;
        result.quantity = qty;
        result.unitPrice = price;
        result.duration = license.billingCycleDuration;
        result.billingPackage = billingPkg;
        result.discount = discount;

        return result;
    }

    public static void deleteEntitlementsByQuoteLineItems(Id quoteId, List<QuoteLineItem> qlisToDelete) {
        List<Entitlement__c> entlsToDelete = new List<Entitlement__c>();
        Map<Id, Entitlement__c> entlMap = new Map<Id, Entitlement__c>((List<Entitlement__c>) new EntitlementSelector()
            .selectEntitlementForSyncQuoteLineItemsByQuoteId(quoteId)
            .executeQuery());

        for (QuoteLineItem qli: qlisToDelete) {
            Entitlement__c entl = entlMap.get(qli.Entitlement__c);
            if (entl != null) {
            	entlsToDelete.add(entl);
            }
        }
        if (!entlsToDelete.isEmpty()) {
            delete entlsToDelete;
        }
    }
} // End of Class