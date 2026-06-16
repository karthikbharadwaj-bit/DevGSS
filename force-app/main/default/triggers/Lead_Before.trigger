/*************************************************
Trigger on Lead object
Before Insert: Evaluate company size.
               Adjust LeadSource as needed.
               Set Primary_Campaign__c field for use in Lead_After.
               Assign lead using Protection Rules or Lead Assignment Rules.
Before Update: Set Downgrade Date.
               Update indexed fields.
               Update owner manager name and email fields.
               Update Last Touched and Responded fields.
/************************************************/

trigger Lead_Before on Lead (before insert, before update, before delete) {


    ByPassTrigger__c bypassTrigger = ByPassTrigger__c.getInstance();
    if (bypassTrigger != null && bypassTrigger.Bypass_Lead_Trigger__c == true) {
        System.debug('$$$ ByPassTrigger__c Active For Lead $$$');
        return;
    }

    if(trigger.isInsert){

    new Triggers()
            .bind(Triggers.Evt.beforeinsert, new LeadTriggerHandler.populateSystemProcessStageCreated())
            .manage();
    }

    new Triggers()
        .bind(Triggers.Evt.beforeinsert, new LeadTriggerHandler.PerformLeadCreateUpdateWorkflows())
        .bind(Triggers.Evt.beforeupdate, new LeadTriggerHandler.PerformLeadCreateUpdateWorkflows())
        .bind(Triggers.Evt.beforeinsert, new LeadTriggerHandler.populateSystemProcessStageBypassed())
        .bind(Triggers.Evt.beforeupdate, new LeadTriggerHandler.populateSystemProcessStageBypassed())
        .bind(Triggers.Evt.beforeupdate, new LeadTriggerHandler.populateSystemProcessStageEnriched())
        .bind(Triggers.Evt.beforeupdate, new LeadTriggerHandler.stampedAsSLED())
        .bind(Triggers.Evt.beforeupdate, new LeadTriggerHandler.populateSystemProcessStageUpdated())
        .bind(Triggers.Evt.beforeinsert, new LeadTriggerHandler.populateLeadEnrichmentExclusion())
        .bind(Triggers.Evt.beforeupdate, new LeadTriggerHandler.populateLeadEnrichmentExclusion())
        .bind(Triggers.Evt.beforeinsert, new LeadTriggerHandler.PopulateLSEnrichmentDate())
        .bind(Triggers.Evt.beforeupdate, new LeadTriggerHandler.PopulateLSEnrichmentDate())
        .bind(Triggers.Evt.beforeinsert, new LeadTriggerHandler.populateZICDPMatch())
        .bind(Triggers.Evt.beforeupdate, new LeadTriggerHandler.populateZICDPMatch())
        .bind(Triggers.Evt.beforeinsert, new LeadTriggerHandler.PopulateSegmentName())
        .bind(Triggers.Evt.beforeupdate, new LeadTriggerHandler.PopulateSegmentName())
        .bind(Triggers.Evt.beforeinsert, new LeadTriggerHandler.PopulateUltimateSMCountryEmp())
        .bind(Triggers.Evt.beforeupdate, new LeadTriggerHandler.PopulateUltimateSMCountryEmp())
        .bind(Triggers.Evt.beforeinsert, new LeadTriggerHandler.PerformWorkFlowActions())
        .bind(Triggers.Evt.beforeupdate, new LeadTriggerHandler.PerformWorkFlowActions())
        .bind(Triggers.Evt.beforeinsert, new LeadTriggerHandler.SetLeadCreationDate())
        .bind(Triggers.Evt.beforeinsert, new LeadTriggerHandler.populateSaaSquatchReferralEmailIdOnLead())
        .bind(Triggers.Evt.beforeupdate, new LeadTriggerHandler.populateSaaSquatchReferralEmailIdOnLead())
        .bind(Triggers.Evt.beforeinsert, new LeadTriggerHandler.populateSaaSquatchAdvocateFieldsOnlead())
        .bind(Triggers.Evt.beforeupdate, new LeadTriggerHandler.populateSaaSquatchAdvocateFieldsOnlead())
        .bind(Triggers.Evt.beforeinsert, new LeadTriggerHandler.populateBMIDBasedOnLeadSource())
        .bind(Triggers.Evt.beforeupdate, new LeadTriggerHandler.populateBMIDBasedOnLeadSource())
        .bind(Triggers.Evt.beforeupdate, new LeadTriggerHandler.RemoveDowngradeValuesForNonDowngradedLeads())
        .bind(Triggers.Evt.beforeinsert, new LeadTriggerHandler.MarketoSync())//Marketo Sync off
        .bind(Triggers.Evt.beforeinsert, new LeadTriggerHandler.PopulateIntentFlow())
        .bind(Triggers.Evt.beforeupdate, new LeadTriggerHandler.PopulateIntentFlow())
        .bind(Triggers.Evt.beforeupdate, new LeadTriggerHandler.LeadWebsiteValidation())
        .manage();


    if (Trigger.isInsert || Trigger.isUpdate) {
        if (LeadTriggerHelper.skipLeadTriggerOnUpdateFromCompanyPersonBatch) {
            return;
        }

    if(Trigger.isInsert && relaywareDuplicateLeadHelper.settings != null){
        if(relaywareDuplicateLeadHelper.settings.Users__c != null && relaywareDuplicateLeadHelper.settings.Users__c.contains(UserInfo.getName())){
            new Triggers()
                .bind(Triggers.Evt.beforeinsert, new relaywareDuplicateLeadHelper.CheckDuplicates())
            .manage();
        }
    }

     new Triggers()
            .bind(Triggers.Evt.beforeinsert, new LeadTriggerHandler.PopulateDateStatusChanged())
            .bind(Triggers.Evt.beforeupdate, new LeadTriggerHandler.PopulateDateStatusChanged())
            .bind(Triggers.Evt.beforeinsert, new LeadTriggerHandler.PopulateZipCustomFields())
            .bind(Triggers.Evt.beforeupdate, new LeadTriggerHandler.PopulateZipCustomFields())
            .manage();

    /*********BY PASS for Desired Behaviour of Campaign Case**************/
    if(TriggerHandler.BY_PASS_LEAD_UPDATE){
        System.debug('### RETURNED FROM LEAD-BEFORE TRG ###');
        return;
    }
    new Triggers()
            .bind(Triggers.Evt.beforeinsert, new LeadTriggerHandler.GetLeadUltimatePartnerId())
            .bind(Triggers.Evt.beforeupdate, new LeadTriggerHandler.GetLeadUltimatePartnerId())
            .manage();

	bypassTrigger = ByPassTrigger__c.getInstance();
    if(!byPassTrigger.Bypass_Lead_Before__c){
        new Triggers()
            .bind(Triggers.Evt.beforeinsert, new LeadTriggerHandler.checkPartnerLeadPermittedByBrand())
            .bind(Triggers.Evt.beforeupdate, new LeadTriggerHandler.checkPartnerLeadPermittedByBrand())
            .bind(Triggers.Evt.beforeinsert, new LeadTriggerHandler.updatePartnerLeadCurrentOwnerEmail())
            .bind(Triggers.Evt.beforeupdate, new LeadTriggerHandler.updatePartnerLeadCurrentOwnerEmail())
            .manage();
    }
    /******CODE TO IGNORE SYSTEM GENERATED EMAIL*********/
    Database.DMLOptions dmo = new Database.DMLOptions();
    dmo.EmailHeader.triggerUserEmail = false;
    dmo.EmailHeader.triggerAutoResponseEmail = false;
    dmo.EmailHeader.triggerOtherEmail = false;
    /***************************************************/

    /*******************************System User Profile Map and Invalid Lead Status Map*****************************/
    Map<String,ProtectionLeadUsers__c> systemUserMapAll = ProtectionLeadUsers__c.getAll();
    Map<string,boolean> systemUserMap = new Map<string,boolean>();
    for(String userName : systemUserMapAll.keySet()){
        String userId = (systemUserMapAll.get(userName).UserId__c).subString(0,15);
        systemUserMap.put(userId,true);
    }
    Map<String,boolean> invalidStatusMap = new Map<String,Boolean>{'0. Downgraded'=>true,'X. Open'=>true,'X. Suspect'=>true};
    //EU phase 3 Changes - START
    Set<String> validProfileSet = new Set<String>{'System Administrator','API Only','Channel Sales Manager - Lightning','GW API','Marketo Integration Profile','Jigsaw'};
    //EU Phase 3 Changes - END
    Set<String> leadRoutingSkipUsers = SkipLeadRoutingLogicUsers__c.getAll().keySet();
    /************************************************ LeanData *****************************************************/
    LeadRoutingSettings__c leadRoutingSettings = LeadRoutingSettings__c.getOrgDefaults();

    String routingSystemReason          = leadRoutingSettings.RoutingSystemReason__c;
    String routingSystemUser            = leadRoutingSettings.RoutingSystemUserId__c;
    Boolean bypassProtectionRouting = leadRoutingSettings.IsbypassProtectionRouting__c;
    /*****************************************User Select Query*********************************************************************/
    User loggedInUser = new User();
    User VarContactUser = new User();
    User leanDataUser = new User();

    Set<String> adminUsers = new set<String>();
    List<User> cachedListOfUsers = UserHelper.getCachedUsers();

    for(User users : cachedListOfUsers) {
        if(users.Id == UserInfo.getUserId()){
            loggedInUser = users;
        }else if(users.Name == 'DO NOT CONTACT - VAR'){
            VarContactUser = users;
        }
        if(users.Profile.Name == 'System Administrator'){
            adminUsers.add(string.valueOf(users.Id).subString(0,15));
        }
        if(users.Name == 'LeanData Queue'){
            leanDataUser = users;
        }
    }

    if(trigger.isInsert){

        /******************** VARIABLE DECLARATION ****************************/
        ProtectionRuleExceptions pre;
        String prResult = 'not found';
        Campaign campaignObj = null;
        String customerSize;
        List<Partner_Request__c> PRMObj = new Partner_Request__c[]{};
        /**********************************************************************/

        /********************************** DUPLICATE VALIDATION ***************************************/
        if(loggedInUser.Systems_Integration_Users__c) {
            List<Lead> returningLeads = ValidateLeadDuplicacy.validatePerToday(Trigger.new);
        }
        new Triggers()
            .bind(Triggers.Evt.beforeinsert, new LeadTriggerHandler.assignCampaigns())
            .bind(Triggers.Evt.beforeinsert, new LeadTriggerHandler.assignAssets())
            .bind(Triggers.Evt.beforeinsert, new LeadTriggerHandler.findAccountMap())
            .manage();

        /*****************************Custom label for PR*********************************************/
        List<string> excludedUserList = new List<String>();
        excludedUserList = Label.Excluded_PR_User_IDs.split(';');
        Set<string> excludedPRUserIdSet = new set<string>();
        for(String str : excludedUserList){
            excludedPRUserIdSet.add(str.trim());
        }

        /**************PR Owner Detail Maps**************************/
        Map<String,String> prOwnerMap = new Map<String,String>();
        Map<String,PRAssignmentLogic.prRuleWrapper> prOwnerDetailMap = new Map<String,PRAssignmentLogic.prRuleWrapper>();
        Map<String,RcDealHealper.searchResultClass> leadContactSearchMap = new Map<String,RcDealHealper.searchResultClass>();
        Map<String,User> userEmailOwnerMap = new Map<String,User>();
        Map<String,Contact> contactEmailOwnerMap = new Map<String,Contact>();//Relayware
        Map<String, Boolean> resultMap = LeadTriggerHelper.getLeadOwnerRCSFsync(trigger.new);

        Map<String,Campaign_Subtype_Mapping__c> campaignSubTypeQueueMap = new Map<String,Campaign_Subtype_Mapping__c>();

        if(validProfileSet.contains(loggedInUser.Profile.Name) && !leadRoutingSkipUsers.contains(UserInfo.getUserId().left(15)) ){

            for(String campaignType : Campaign_Subtype_Mapping__c.getAll().keySet()){
                campaignSubTypeQueueMap.put(campaignType.toUpperCase(),Campaign_Subtype_Mapping__c.getAll().get(campaignType));
            }
        }
        /***********************************************************************************************/

        /************************Validating Employee Ranges*********************************************/
        LeadTriggerHelperExt.getCheckForBadValue(Trigger.new);
        /**********************************************************************************************/

        /****************************Custom Labels for Geo Territory***********************************/
        List<string> employeeSizeList = new List<String>();
        employeeSizeList = Label.Territory_Employee_Size.split(';');
        Set<string> employeeSizeSet = new set<string>();
        for(String str : employeeSizeList){
            employeeSizeSet.add(str.trim());
        }

        List<string> leadSourceList = new List<String>();
        leadSourceList = Label.Territory_Lead_Source.split(';');
        Set<string> leadSourceSet = new set<string>();
        for(String str : leadSourceList){
            leadSourceSet.add(str.trim());
        }
        /**********************************************************************************************/

        List<Lead> leadToNewRoute = new List<Lead>();

        for(Lead leadObj : Trigger.new){

            // Case 04835970 - SFDC Clone Lead Button Change - START
            if(leadObj.isClone()){
                LeadTriggerHelperExt.ClearLeadSpaceFields(leadObj);
            }
            // Case 04835970 - SFDC Clone Lead Button Change - END

            String uniqueKey = ( !string.isBlank(leadObj.Email) ? leadObj.Email : '') + ( !string.isBlank(leadObj.Phone) ? leadObj.Phone : '');
            leadObj.Assignment_Source_hidden__c = 'No Rules';

            /*********************LEADSOURCE ASSIGNMENT *****************/
            LeadTriggerHelper.assignLeadSource(leadObj);
            /***********************************************************/

            /************************SETTING LEAD CURRENCY***********************************/
            LeadTriggerHelperExt.populateCurrencyBasedOnBrand(leadObj);
            /*******************************************************************************/
			//Avaya Lead country change starts
            Map<String,String> countryCurrencyMapForCommunity = CountryCurrencyCode.getCountryCurrencyMap();
            if(leadObj.Avaya_Partnership_Lead__c == true){
                String currencyForCntry = countryCurrencyMapForCommunity.get(String.valueof(leadObj.Country__c));
                if(leadObj.Lead_Brand_Name__c != 'Vodafone Business with RingCentral'){
                    if(currencyForCntry != null && currencyForCntry != ''){
                        leadObj.CurrencyIsoCode = currencyForCntry;
                    }else{
                        leadObj.CurrencyIsoCode = 'USD';
                    }
                }
            }
			//Added for PRM-41
            if(leadObj.RecordTypeId != null){
                if(leadObj.RecordTypeId == Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Partner Leads').getRecordTypeId() &&
                    leadObj.Avaya_Partnership_Lead__c == false && leadObj.Portal_Lead__c == true){
                    leadObj.Avaya_Partnership_Lead__c=true;
                }
            }
            bypassTrigger = ByPassTrigger__c.getInstance();
    		if(!byPassTrigger.Bypass_Lead_Before__c){
            //Avaya Lead country change ends
            /*******Code added for associating Account id to lead coming for SolveThenSell through RN*******/
            if(leadObj.LeadSource == 'Solve then Sell' || leadObj.BMID__c == 'SOLVETHENSELL') {
                try{
                    leadObj.Account__c = (LeadTriggerHandler.userAccMap != null ? LeadTriggerHandler.userAccMap.get(leadObj.User_ID__c).Id : null);
                } catch(Exception ex){
                    System.debug('Exception at Line : '+ex.getLineNumber()+' Message :'+ex.getMessage());
                }
            }
            /*********************************************************************************************/
            }
            /*************************UPDATE LEAD SCORE*********************************/
            if(leadObj.Primary_Campaign__c != null) {
                campaignObj = LeadTriggerHandler.campaignMap.get((String)leadObj.Primary_Campaign__c);
            }
            if(campaignObj != null){ // code-FIXED
                if(!String.isBlank(campaignObj.Lead_Score__c)){
                    leadObj.Lead_Score__c = campaignObj.Lead_Score__c;
                }
            }
            /*************************************************************************/

            /***************************Update LeadSource ****************************/
            if(campaignObj != null && campaignObj.Name != null && leadObj.LeadSource != null) {
                if(leadObj.LeadSource == 'Initial' && campaignObj.Name.startsWith('Vista')){
                    leadObj.LeadSource = 'VistaPrint Initial';
                }
                if(leadObj.LeadSource == 'Initial UK' && campaignObj.Name.startsWith('Vista')){
                    leadObj.LeadSource = 'VistaPrint Initial UK ';
                }
            }
            /************************************************************************/

            /***********************Phone Number Assignment*************************/
            if(leadobj.Phone!=null){
                leadobj.Original_Phone_Number__c = leadobj.Phone;
            }
            /***********************************************************************/

            Boolean ownerFoundBasedOnPreProtection = false;
            Boolean territoryUserFound = false;

            if((!(leadObj.FirstName == 'Something' && leadObj.LastName == 'New') && !(leadObj.FirstName == 'rctu' && leadObj.LastName == '2calls4me'))
                && (
                        validProfileSet.contains(loggedInUser.Profile.Name)
                        || (leadObj.RecordTypeId!=null && LeadTriggerHandler.rtMapByName.get(leadObj.RecordTypeId).getName() == 'Partner Leads')
                        || (leadObj.LeadSource != null && (leadObj.LeadSource).trim().equalsIgnoreCase('Solve then Sell') )
                        || (leadObj.LeadSource != null && (leadObj.LeadSource).trim().equalsIgnoreCase('Lead Initial Chat') )
                    )
                && (leadObj.Duplicate_Lead__c==null || leadObj.Duplicate_Lead__c == false)
                && (!resultMap.get(leadObj.FirstName + '_' + leadObj.LastName))
                && !leadRoutingSkipUsers.contains(UserInfo.getUserId().left(15))
            ){

                if(!leadObj.Bypass_Routing__c) {
                    // use OLD ROUTING

                    /*************************Pre Protection Routing**********************************************/
                    if(leadObj.Primary_Campaign__c != null
                        && LeadTriggerHandler.campaignMap != null
                        && LeadTriggerHandler.campaignMap.containsKey(leadObj.Primary_Campaign__c)
                        && LeadTriggerHandler.campaignMap.get(leadObj.Primary_Campaign__c) != null
                        && LeadTriggerHandler.campaignMap.get(leadObj.Primary_Campaign__c).type != null
                        && LeadTriggerHandler.campaignMap.get(leadObj.Primary_Campaign__c).type.containsIgnoreCase('CPL')){

                        String campaignSubType = LeadTriggerHandler.campaignMap.get(leadObj.Primary_Campaign__c).type.toUpperCase();
                        if(campaignSubTypeQueueMap.get(campaignSubType) != null){
                            if(!string.isBlank(campaignSubTypeQueueMap.get(campaignSubType).Queue_Id__c)){
                                leadObj.ownerId = campaignSubTypeQueueMap.get(campaignSubType).Queue_Id__c;
                                ownerFoundBasedOnPreProtection = true;
                                leadObj.Assignment_Source_hidden__c = 'PRE-PROTECTION RULE';
                            }
                        }
                    }
                    /**********************************************************************************************/

                    if(ownerFoundBasedOnPreProtection == false){
                        /************RUN PR RULES LOGIC****************************/
                        if ((leadObj.Bypass_PR__c == false || leadObj.Bypass_PR__c == NULL) && leadObj.LeadSource != 'Other' && leadObj.RecordTypeName__c != 'Partner_Leads'){
                            boolean prUserFound = false;
                            if(!prUserFound && routingSystemUser != null){
                                //BizMerge-Added Brand Name check to exclude LDQ assignment for ATT Leads
                                Boolean isBizMergeBrand = System.Label.BizMerge_Brand_Exclusion_List != null && leadObj.Lead_Brand_Name__c != null && System.Label.BizMerge_Brand_Exclusion_List.contains(leadObj.Lead_Brand_Name__c);
                                if (leadObj.Lead_Brand_Name__c == null || !isBizMergeBrand) {
                                    leadObj.OwnerId = routingSystemUser;
                                    leadObj.Assignment_Source_hidden__c = routingSystemReason;
                                    leadObj.Routing_Reason__c = LeadTriggerHelper.ROUTINGREASONNETNEWLEAD;
                                }
                                leadObj.Lead_Submitter_Id__c = UserInfo.getUserId();

                            }
                        } else {
                            //BizMerge-Added Brand Name check to exclude LDQ assignment for ATT Leads
                            Boolean isBizMergeBrand = System.Label.BizMerge_Brand_Exclusion_List != null && leadObj.Lead_Brand_Name__c != null && System.Label.BizMerge_Brand_Exclusion_List.contains(leadObj.Lead_Brand_Name__c);
                            if (leadObj.Lead_Brand_Name__c == null || !isBizMergeBrand) {
                                leadObj.OwnerId = routingSystemUser;
                                leadObj.Assignment_Source_hidden__c = routingSystemReason;
                            	leadObj.Routing_Reason__c = LeadTriggerHelper.ROUTINGREASONNETNEWLEAD;
                            }
                        }
                    }
                } else {
                    leadObj.Assignment_Source_hidden__c = 'Routing Bypass';
                }
            } else if((resultMap.get(leadObj.FirstName + '_' + leadObj.LastName))) {
                leadObj.Assignment_Source_hidden__c = 'Custom Settings';
            }

            // Start Code By India Team
            if (!'System Administrator'.equalsIgnoreCase(loggedInUser.Profile.Name)) {
                leadObj.Last_Touched_Date__c = Datetime.now();
                leadObj.Last_Touched_By__c = UserInfo.getUserId();
                leadObj.Responded_Date__c = Datetime.now();
                leadObj.Responded_By__c = UserInfo.getUserId();
            }

            /****************************Eligible Protected Date************************/
            if(Test.isRunningTest() && leadObj.OwnerId==null){
                leadObj.OwnerId = UserInfo.getUserId(); //For Test Class Owner Id Null Issue
            }
            if((systemUserMap == null || (leadObj.OwnerId!=null && systemUserMap.get(string.valueOf(leadObj.OwnerId).subString(0,15)) == Null)) //Other then 'LAR System User' & not System User
                && (adminUsers == null || (leadObj.OwnerId!=null && !adminUsers.contains(string.valueOf(leadObj.OwnerId).subString(0,15))))//Not System Administrator User
                && (invalidStatusMap == null || (leadObj.Status!=null && invalidStatusMap.get(leadObj.Status) == Null))//Not a Invalid Status
              ){
                leadObj.Eligible_Protection_Period__c = system.today() + 30;
            }
            /**************************************************************************/

            LeadHelper.updateLeadSystemSource(leadObj, leadObj);
        }

        new Triggers()
            .bind(Triggers.Evt.beforeinsert, new LeadTriggerHandler.updateLeadActiveDate())
            .bind(Triggers.Evt.beforeinsert, new LeadTriggerHandler.getLeadOwnerManager())
            .bind(Triggers.Evt.beforeinsert, new LeadTriggerHandler.assignBrand())
            .manage();
    }


    /*********************************************************LEAD UPDATE *********************************************************/
    if(trigger.isUpdate){

        /**************** TO BY PASS TRIGGER*****************************/
        if(TriggerHandler.BY_PASS_LEAD_UPDATE_ON_INSERT) {
            System.debug('### RETURNED FROM LEAD-BEFORE TRG ###');
            return;
        }
        /***************************************************************/

        new Triggers()
                .bind(Triggers.Evt.beforeupdate, new LeadTriggerHandler.setLeadFields())
                .bind(Triggers.Evt.beforeupdate, new LeadTriggerHandler.updateMostRecentCampaign())
                .bind(Triggers.Evt.beforeupdate, new LeadTriggerHandler.reassignAssets())
                .bind(Triggers.Evt.beforeupdate, new LeadTriggerHandler.campaignAtrributionLogic())
                .manage();

        /********************************** PR DATA INITIALIZED **************************************/
        Map<String,String> prOwnerMap = new Map<String,String>();
        Map<String,PRAssignmentLogic.prRuleWrapper> prOwnerDetailMap = new Map<String,PRAssignmentLogic.prRuleWrapper>();
        List<Lead> prLeadList = new List<Lead>();
        /************************************************************************************************/

        /*****************************Custom label for PR*********************************************/
        List<string> excludedUserList = new List<String>();
        excludedUserList = Label.Excluded_PR_User_IDs.split(';');
        Set<string> excludedPRUserIdSet = new set<string>();
        for(String str : excludedUserList){
            excludedPRUserIdSet.add(str.trim().subString(0,15));
        }
        /*********************************************************************************************/

        /*************************** INITIAL MARKETO ATTOH STARTS**********************************/
        try {
            if ('Marketo Integration Profile'.equalsIgnoreCase(loggedInUser.Profile.Name)) {
                Map<String, Campaign> campaignMap = new Map <String, Campaign>([SELECT Id, type,Lead_Creation_Score__c, Lead_Entry_Source__c, AID__c, PID__c, BMID__c, DNIS__c, /*Team__c,*/
                                             NumberOfLeads, Lead_Score__c, Name from Campaign where Id in: LeadTriggerHandler.campaignIdSet]);
                Map<String,User> userEmailOwnerMap = new Map<String,User>();
                Map<String,Contact> contactEmailOwnerMap = new Map<String,Contact>();//Relayware
                userEmailOwnerMap = PRAssignmentLogic.createEmailOwnerMap(trigger.new);
                contactEmailOwnerMap = PRAssignmentLogic.createEmailContactMap(trigger.new);//Relayware
                for(Lead leadObj : trigger.new) {
                    /****************************Eligible Protected Date************************/
                    PRAssignmentLogic.calculateProtectionPeriod(leadObj,trigger.oldMap.get(leadObj.id),systemUserMap,invalidStatusMap,adminUsers);
                    /*************************************************************************/
                    if(!leadObj.Bypass_Routing__c){
                        if(
                            (
                                leadObj.OwnerId != trigger.oldMap.get(leadObj.id).ownerId && // Owner Changes
                                leadObj.OwnerId != null && string.valueOf(leadObj.OwnerId).startsWith('005') && //Current Owner is User
                                LeadTriggerHandler.userDetailMap.get(leadObj.OwnerId)!=null && LeadTriggerHandler.userDetailMap.get(leadObj.OwnerId).isActive==false//Current owner is InActive
                            )
                            ||
                            leadObj.OwnerId == trigger.oldMap.get(leadObj.id).ownerId){ //Owner Not Changed

                            //Check Is Lead Protectd or Not
                            boolean isProtectedLead = false;
                            if(leadObj.Eligible_Protection_Period__c!=null && leadObj.Eligible_Protection_Period__c >= system.today()
                                    && leadObj.status!=null && leadObj.status == '2. Contacted'){
                                isProtectedLead = true;
                            }

                            if(
                                (
                                    //Check if campaign Changes from a NON CPL type to CPL Type
                                    leadObj.Most_Recent_Campaign__c != null
                                    && leadObj.Most_Recent_Campaign__c != trigger.oldMap.get(leadObj.Id).Most_Recent_Campaign__c
                                    && campaignMap.get(leadObj.Most_Recent_Campaign__c) != null
                                    && campaignMap.get(leadObj.Most_Recent_Campaign__c).type != null
                                    && campaignMap.get(leadObj.Most_Recent_Campaign__c).type.containsIgnoreCase('CPL')
                                    && campaignMap.get(trigger.oldMap.get(leadObj.Id).Most_Recent_Campaign__c) != null
                                    && (campaignMap.get(trigger.oldMap.get(leadObj.Id).Most_Recent_Campaign__c).type == null ||
                                        !campaignMap.get(trigger.oldMap.get(leadObj.Id).Most_Recent_Campaign__c).type.containsIgnoreCase('CPL'))
                                    && (!isProtectedLead)
                                )
                                ||
                                (
                                    //Check if status changing from Invalid to Valid
                                    leadObj.Status != trigger.oldMap.get(leadObj.id).status //Status Changed
                                    && (invalidStatusMap != null && invalidStatusMap.get(trigger.oldMap.get(leadObj.id).status) != Null) //Old Status Invalid
                                    && (invalidStatusMap == null || invalidStatusMap.get(leadObj.Status) == Null) //New Status is Valid
                                )
                            ){
                                if(leadObj.OwnerId != null && string.valueOf(leadObj.OwnerId).startsWith('005')){//Current Owner Is a 'User'



                                    // USE OLD ROUTING

                                    //Check if Marketo providing Email Fields for owner assignment.
                                    if(
                                        (
                                            leadObj.Lead_Owner_Email_Address__c!=null &&
                                                (
                                                    //Relayware
                                                    (userEmailOwnerMap!=null && userEmailOwnerMap.get(leadObj.Lead_Owner_Email_Address__c)!=null) ||
                                                    (contactEmailOwnerMap!=null && contactEmailOwnerMap.get(leadObj.Lead_Owner_Email_Address__c)!=null)
                                                )
                                        ) ||
                                            (Test.isRunningTest())
                                    ){
                                        system.debug('Marketo Updating Lead Owner Email Field');
                                        User userObj;
                                        userObj =   userEmailOwnerMap.get(leadObj.Lead_Owner_Email_Address__c);
                                        Contact conObj;
                                        conObj = contactEmailOwnerMap.get(leadObj.Lead_Owner_Email_Address__c);
                                        String uniqueKey = ( !string.isBlank(leadObj.Email) ? leadObj.Email : '') + ( !string.isBlank(leadObj.Phone) ? leadObj.Phone : '');
                                        PRAssignmentLogic.checkVARReferalLead(leadObj,uniqueKey,prOwnerMap,userObj,conObj,VarContactUser);
                                    }else if(
                                        (
                                            leadObj.Sales_Agent_Email__c!=null &&
                                                (
                                                    //Relayware
                                                    (userEmailOwnerMap!=null && userEmailOwnerMap.get(leadObj.Sales_Agent_Email__c)!=null) ||
                                                    (contactEmailOwnerMap!=null && contactEmailOwnerMap.get(leadObj.Sales_Agent_Email__c)!=null)
                                                )
                                        ) ||
                                            (Test.isRunningTest())
                                    ){
                                        system.debug('Marketo Updating Sales Agent Email Field');
                                        User userObj;
                                        userObj =   userEmailOwnerMap.get(leadObj.Sales_Agent_Email__c);
                                        Contact conObj;
                                        conObj = contactEmailOwnerMap.get(leadObj.Sales_Agent_Email__c);
                                        String uniqueKey = ( !string.isBlank(leadObj.Email) ? leadObj.Email : '') + ( !string.isBlank(leadObj.Phone) ? leadObj.Phone : '');
                                        PRAssignmentLogic.checkVARReferalLead(leadObj,uniqueKey,prOwnerMap,userObj,conObj,VarContactUser);
                                    } else {

                                    }



                                }
                            } else {
                                if(leadObj.Bypass_PR__c==true){
                                    if(leadObj.OwnerId != null && string.valueOf(leadObj.OwnerId).startsWith('005') &&
                                        LeadTriggerHandler.userDetailMap.get(leadObj.OwnerId)!=null && LeadTriggerHandler.userDetailMap.get(leadObj.OwnerId).isActive==false){
                                        //BizMerge-Added Brand Name check to exclude LDQ assignment for ATT Leads
                                        Boolean isBizMergeBrand = System.Label.BizMerge_Brand_Exclusion_List != null && leadObj.Lead_Brand_Name__c != null && System.Label.BizMerge_Brand_Exclusion_List.contains(leadObj.Lead_Brand_Name__c);
                                        if (leadObj.Lead_Brand_Name__c == null || !isBizMergeBrand) {
                                            leadObj.OwnerId = routingSystemUser;
                                            leadObj.Assignment_Source_hidden__c = routingSystemReason;
                                        	leadObj.Routing_Reason__c = LeadTriggerHelper.ROUTINGREASONINACTIVEOWNER;
                                        }
                                    }
                                } else {
                                    if(leadObj.LeadSource != 'Other' && leadObj.RecordTypeName__c != 'Partner_Leads' &&
                                        leadObj.OwnerId != null && string.valueOf(leadObj.OwnerId).startsWith('005') && LeadTriggerHandler.userDetailMap.get(leadObj.OwnerId).isActive==false){
                                        prLeadList.add(leadObj);
                                    }
                                }
                            }
                        }
                    } else {
                        leadObj.Assignment_Source_hidden__c = 'Routing Bypass';
                    }

                }

                if(prLeadList!=null && prLeadList.size() > 0) {

                    Map<String,RcDealHealper.searchResultClass> leadContactSearchMap = new Map<String,RcDealHealper.searchResultClass>();
                    Map<String, Boolean> resultMap = LeadTriggerHelper.getLeadOwnerRCSFsync(trigger.new);

                        // USE OLD ROUTING
                    for(Lead leadObj : prLeadList){
                        String uniqueKey = ( !string.isBlank(leadObj.Email) ? leadObj.Email : '') + ( !string.isBlank(leadObj.Phone) ? leadObj.Phone : '');
                        if (!(leadObj.Bypass_PR__c == false || leadObj.Bypass_PR__c == null) && leadObj.OwnerId != null &&
                        String.valueOf(leadObj.OwnerId).startsWith('005') &&
                        LeadTriggerHandler.userDetailMap.get(leadObj.OwnerId).isActive == false) {
                            //BizMerge-Added Brand Name check to exclude LDQ assignment for ATT Leads
                            Boolean isBizMergeBrand = System.Label.BizMerge_Brand_Exclusion_List != null && leadObj.Lead_Brand_Name__c != null && System.Label.BizMerge_Brand_Exclusion_List.contains(leadObj.Lead_Brand_Name__c);
                            if (leadObj.Lead_Brand_Name__c == null || !isBizMergeBrand) {
                                leadObj.OwnerId = routingSystemUser;
                                leadObj.Assignment_Source_hidden__c = routingSystemReason;
                            	leadObj.Routing_Reason__c = LeadTriggerHelper.ROUTINGREASONINACTIVEOWNER;
                            }
                        }
                    }

                }
            }
        } catch(Exception ex) {
            trigger.new[0].addError(ex.getMessage());
            System.debug('Exception at Line : '+ex.getLineNumber()+' Message :'+ex.getMessage());
        }

        for(Lead leadObj:trigger.new){
		//Added for PRM-41
            if(leadObj.RecordTypeId == Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Partner Leads').getRecordTypeId() &&
               (leadObj.Avaya_Partnership_Lead__c == false || trigger.oldmap.get(leadObj.Id).Avaya_Partnership_Lead__c == false) &&
               leadObj.Portal_Lead__c == true){
                    leadObj.Avaya_Partnership_Lead__c = true;
            }
            /*Code For original Owner functionality.Old Lead Owner = 'LAR System User' and New lead owner!='LAR System User'and Original Lead owner=Blank*/
            if(LeadTriggerHandler.userDetailMap!=null && LeadTriggerHandler.userDetailMap.get(leadObj.OwnerId)!=null
                && !LeadHelper.SYSTEM_USERS.contains(LeadTriggerHandler.userDetailMap.get(leadObj.OwnerId).Name.toLowerCase())
                && string.isBlank(leadObj.Original_Lead_Owner_Name__c)
                && trigger.OldMap.get(leadObj.id)!=null
                && LeadTriggerHandler.userDetailMap.get(trigger.OldMap.get(leadObj.id).ownerId)!=null
                && LeadHelper.SYSTEM_USERS.contains(LeadTriggerHandler.userDetailMap.get(trigger.OldMap.get(leadObj.id).ownerId).Name.toLowerCase())
            ){
                    leadObj.Original_Lead_Owner_Id__c = leadObj.OwnerId;
                    leadObj.Original_Lead_Owner_Name__c = LeadTriggerHandler.userDetailMap.get(leadObj.OwnerId).Name;
            }
            /**********************************************************************************************************************************/

            /****************************To Set Lead_Owner_Phone_Number__c and Mkto_Reply_Email__c************************/
            User userObj = LeadTriggerHandler.userDetailMap.get(leadObj.OwnerId);
            if(userObj != null) {
                leadObj.Lead_Owner_Phone_Number__c = userObj.Phone;
                if(trigger.oldMap.get(leadObj.Id).OwnerId != leadObj.OwnerId) {
                    leadObj.Mkto_Reply_Email__c = userObj.Mkto_Reply_Email__c;
                }
            }
            /************************************************************************************************************/

            /**************Update indexed fields********************/
            if(leadObj.Phone != trigger.oldMap.get(leadObj.Id).Phone){
                leadObj.indexedPhone__c = leadObj.Phone;
            }

            if(leadObj.email != trigger.oldMap.get(leadObj.Id).email){
                leadObj.indexedEmail__c = leadObj.email;
            }
            /******************************************************/
            /******************* Update Owner Manager fields appropriatly. Dave Demink should be listed as his own manager.***************/
            if(leadObj.OwnerId != trigger.oldMap.get(leadObj.Id).OwnerId && !Test.isRunningTest()){
                if(leadObj.OwnerId == HardcodedIdsMapper.getMatchedObjectId('005800000037xj5')) {
                    leadObj.Owner_Manager_Email__c = Emails__c.getall().get('davedowner') != null ? Emails__c.getall().get('davedowner').Email_Address__c : '';
                    leadObj.Owner_Manager_Name__c = 'Dave Demink';
                }
                else{
                    if(!(UserInfo.getUserName()).equalsIgnoreCase(Emails__c.getall().get('rcsfsyncuser').Email_Address__c) &&
                        (!(UserInfo.getUserName()).equalsIgnoreCase(Emails__c.getall().get('suniluser').Email_Address__c))){
                    try{
                        User u = LeadTriggerHandler.userDetailMap.get(leadObj.OwnerId);
                        if(u != null &&  u.Managerid!= null  &&  u.Manager.Email !=null  &&  u.Manager.Name != null ){
                            leadObj.Owner_Manager_Email__c = u.Manager.Email;
                            leadObj.Owner_Manager_Name__c = u.Manager.Name;
                        }
                    }catch(System.QueryException ex){
                        System.debug('Exception at Line : '+ex.getLineNumber()+' Message :'+ex.getMessage());
                    }
                        /*The following block of code was added to try continue to bulkify lead insertion.
                        Instead of queriing for each user details for every lead use a master list of users to find matching data
                        This code would allow bulk lead transfers by sales managers while keeping Owner Manager fields up to date*/
                    }
                }
            }
            /*******************************************************************************************************************************/

            /****************************Set Last Response Date and Last Touched Date Data*****************************/
            if (!'System Administrator'.equalsIgnoreCase(loggedInUser.Profile.Name)) {
                if(leadObj.Responded_Date__c==null){
                    leadObj.Responded_Date__c = Datetime.now();
                    leadObj.Responded_By__c = UserInfo.getUserId();
                }
                leadObj.Last_Touched_Date__c  = Datetime.now();
                leadObj.Last_Touched_By__c = UserInfo.getUserId();
            }
            /**********************************************************************************************************/

            /************************Assign Partner Owner Assign Date on Partner Owner change*************************/
            if(trigger.OldMap.get(leadObj.id).Partner_Lead_Owner__c != leadObj.Partner_Lead_Owner__c
                    && !string.isBlank(leadObj.Partner_Lead_Owner__c)){
               leadObj.Partner_Owner_Assignment_Date__c = System.today();
            }
            /********************************************************************************************************/
        }

        /*****************UPDATE Lead Owner Active Date************************/
        LeadTriggerHelper.updateLeadActiveDate(Trigger.New, Trigger.oldMap);
        /*********************************************************************/
    }


    /********************* DFR CODE (DemandGen) - Start ***********************************/
    if(trigger.isInsert && trigger.isBefore){
        DG_DFR_Class.FirstHandRaise_OnInsert(trigger.New);
    }
    /********************* DFR CODE (DemandGen) - End ***********************************/
	bypassTrigger = ByPassTrigger__c.getInstance();
    if(!byPassTrigger.Bypass_Lead_Before__c){
    if (Trigger.isUpdate) {
        LeadTriggerHelper.populatePartnerAccount(Trigger.new, Trigger.oldMap);
    }
    }

        Set<Id> ownerIds = new Set<Id>();
        Map<Id, User> ownerNamesByIds;
        for (Lead ld : (List<Lead>)Trigger.new) {
            if ((Trigger.isInsert && ld.OwnerId != null)
                || (Trigger.isUpdate && (ld.OwnerId != Trigger.oldMap.get(ld.Id).OwnerId))) {
                ownerIds.add(ld.OwnerId);
            }
        }
        if (Trigger.isInsert) {
            if (!ownerIds.isEmpty()) {
                ownerNamesByIds = new Map<Id, User>([
                                                    SELECT Name
                                                    FROM User
                                                    WHERE Id IN : ownerIds
                                                    ]);
            }
        } else if(LeadTriggerHandler.userDetailMap != null) {
            ownerNamesByIds = new Map<Id, User>(LeadTriggerHandler.userDetailMap);
        }
        if (ownerNamesByIds != null && !ownerNamesByIds.isEmpty()) {
            for (Lead ld : (List<Lead>)Trigger.new) {
                if (ownerNamesByIds.get(ld.OwnerId) != null &&
                    ownerIds.contains(ld.OwnerId) &&
                    ((String)ld.OwnerId).startsWith('005') ){

                    ld.LeadOwnerName__c = ownerNamesByIds.get(ld.OwnerId).Name;
                }
            }
        }

        /************************** Update Flag for Marketo Batch **************************/
        if (UserInfo.getName().equalsIgnoreCase('User Marketo')) {
            Set<sObjectField> marketoFields = new Set<sObjectField>{
                Lead.Asset_Name__c, Lead.Asset_Type__c,
                Lead.Campaign_Member_Target_Segment__c,
                Lead.Member_Detail__c,
                Lead.Responded_DateMKTO__c
            };
            for (Lead ld : (List<Lead>) Trigger.new) {
                for (sObjectField leadField : marketoFields) {
                    if ((Trigger.isInsert && ld.get(leadField) != null)
                        || (Trigger.isUpdate && ld.get(leadField) != Trigger.oldMap.get(ld.Id).get(leadField))) {
                        ld.MarketoBatchJobFlag__c = true;
                        break;
                    }
                }
            }
        }
		new Triggers()
                .bind(Triggers.Evt.beforeinsert, new LeadTriggerHandler.updateRecruitedByField())
                .bind(Triggers.Evt.beforeupdate, new LeadTriggerHandler.updateRecruitedByField())
                .bind(Triggers.Evt.beforeinsert, new LeadTriggerHandler.populateAssignedCSS())
                .bind(Triggers.Evt.beforeupdate, new LeadTriggerHandler.populateAssignedCSS())
                .manage();
    }

    //Company Persons object decomissioning
    bypassTrigger = ByPassTrigger__c.getInstance();
    if(!byPassTrigger.Bypass_Company_Process_Logic__c){
    system.debug('Limits before Bypassing company processing logic '+PRAssignmentLogic.calculateLimits());
    // Remove Company Persons if related Lead was deleted.
    if (Trigger.isDelete) {
        List<Company_Persons__c> companyPersons = new List<Company_Persons__c>();
        for (Company_Persons__c person : [SELECT Contact__c FROM Company_Persons__c
                                            WHERE Lead__c IN : Trigger.oldMap.keySet()]) {
            if (person.Contact__c == null) {
                companyPersons.add(person);
            }
        }
        if (!companyPersons.isEmpty()) {
            delete companyPersons;
        }
    }
    system.debug('Limits after Bypassing company processing logic '+PRAssignmentLogic.calculateLimits());
    }//Company Persons object decomissioning ends

}