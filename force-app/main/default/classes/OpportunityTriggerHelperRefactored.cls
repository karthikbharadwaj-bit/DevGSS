public with sharing class OpportunityTriggerHelperRefactored {

    // Confirm and Close confirmation template names
    public static final String regularTemplateName = 'CustomerNotificationOnConfirmAndClose';
    public static final String simplifiedEmailTemplateName = 'NGBS Change Order Email Confirmation';
    public static final String incrementalEmailTemplateName = 'NGBS Incremental Email Confirmation';
    public static final String simplifiedPhoenixEmailTemplateName = 'Phoenix NGBS Change Order Email';
    public static final String incrementalPhoenixEmailTemplateName = 'Phoenix NGBS Incremental Email';
    public static final String simplifiedFaxEmailTemplateName = 'Fax Change Order Email Confirmation';
    public static final String incrementalFaxEmailTemplateName = 'Fax Incremental Email Confirmation';

    public static UsersCacheHolder UsersCacheInstance = new UsersCacheHolder();
    public static Map<Id, Account> accountMapStatic = new Map<Id, Account>();
    public static Map<Id, Boolean> engageTerminationMapStatic = new Map<Id, Boolean>();
    public static Set<Id> processedForecastedAmountsOppIds = new Set<Id>();
    public static Map<String, Proserv_Email_Country__mdt> emailMapping = new Map<String, Proserv_Email_Country__mdt>();
    public static Map<Id, Entitlement__c> entitlementMapStatic = new Map<Id, Entitlement__c>();
    public static Entitlement__c accountServiceEntl = null;
    public static Map<Id, List<Quote>> accIdToQuotesOnAccountPendingApproval = new Map<Id, List<Quote>>();
    public static Map<Id, PartnerOperationsLog__c> oppIdToPartnerOperationLog = new Map<Id, PartnerOperationsLog__c>();
    public static List<Quote> createOrderQuoteList = new List<Quote>();
    private static Boolean isPartnerOperationsLogSet = false;
    public static Boolean skipAsyncDFR = false;

    public final static Set<String> DIVISIONS_SKIP_AUTOMATIC_CALCULATE_12M = new Set<String>{
        OpportunityHelper.USER_DIVISION_SALES_ENTERPRISE
    };

    public static final String SALES_QUOTE_DEVELOPER_RT_NAME = 'Sales_Quote';
    public static final String PRODUCT_CHARGETERM_ONETIME = 'One - Time';
    public static final String PRODUCT_FAMILY_TAXES = 'Taxes';
    private static final String BASE_URL = Url.getOrgDomainUrl().toExternalForm();

    private static final String EMPTY_METADATA_ERROR_MESSAGE = 'Required fields are empty(check DocuSignRESTSettings__mdt values for the records: "DSAccountID", "RequestIntegratorKey", "DSUserName", "RequestPrivateKey", "RequestAuthDomain", "DataCenter", "ApiVersion")';

    public static Set<String> closedOpportunityStges = new Set<String>{
        OpportunityHelper.STAGE_NAME_CLOSED_WON,
        OpportunityHelper.STAGE_NAME_CLOSED_SAVED,
        OpportunityHelper.STAGE_NAME_CLOSED_CHURNED
    };

    public static Set<String> activeOpportunityStages = new Set<String>{
        '.5 Re-New',
        '1. Qualify',
        '2. Problem',
        '3. Solution',
        '4. Proof',
        '5. Agreement',
        '6. Order'
    };

    public static Boolean isChangeOrderFlow = false;
    public static Boolean isAutoGenerateOrders = true;
    public static Boolean isSkipSecondRunWorkflowActions = false;
    public static Boolean skipForecastValidations = false;
    public static Boolean isDowngradedFromEarlyStage = false;
    public static Boolean skipOpportunityContactRoleValidations = false;

    class CustomException extends Exception {
    }

    public class ManageAccountMapStatic extends Triggers.TriggerHandlerBase {
        override public void handle() {
            if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
                this.handleBeforeUpsert();
            }
        }

        private void handleBeforeUpsert() {
            Set<Id> accountIdsToLoad = new Set<Id>();
            for (Opportunity opp : (List<Opportunity>) Trigger.new) {
                if (String.isNotBlank(opp.AccountId) && !accountMapStatic.containsKey(opp.AccountId)) {
                    accountIdsToLoad.add(opp.AccountId);
                }
            }

            if (!accountIdsToLoad.isEmpty()) {
                List<Account> accounts = (List<Account>) new AccountSelector()
                    .selectAccountsForOpportunityTrigger(accountIdsToLoad)
                    .executeQuery();
                Set<Id> childAccountsToLoad = new Set<Id>();
                for (Account acc : accounts) {
                    accountMapStatic.put(acc.Id, acc);
                    if (acc.Master_Accounts__r != null && acc.Master_Accounts__r.size() > 0) {
                        for (Account childAcc : acc.Master_Accounts__r) {
                            childAccountsToLoad.add(childAcc.Id);
                        }
                    }
                }
                List<Account> childAccounts = (List<Account>) new AccountSelector()
                    .selectAccountsForOpportunityTrigger(childAccountsToLoad)
                    .executeQuery();

                for (Account acc : childAccounts) {
                    accountMapStatic.put(acc.Id, acc);
                }
            }
        }
    }
    public class ManageAfterUpdateStatic extends Triggers.TriggerHandlerBase {
        override public void handle() {
            engageTerminationMapStatic = OpportunityHelper.engageOppIdToTerminationStatus((List<Opportunity>) Trigger.new);
        }
    }
    public class OpportunityBeforeUpdateInsert extends Triggers.TriggerHandlerBase {
        override public void handle() {

            if (Trigger.isUpdate && isChangeOrderFlow) {
                return;
            }

            //Cast trigger variables once
            List<Opportunity> newOpportunities = (List<Opportunity>) Trigger.new;
            Map<Id, Opportunity> newOpportunitiesByIds = (Map<Id, Opportunity>) Trigger.newMap;
            Map<Id, Opportunity> oldOpportunitiesByIds = (Map<Id, Opportunity>) Trigger.oldMap;

            //First collect all info from users and put it to static map
            //As well we merge profile info with user info
            Boolean doSoql = false;
            Set<Id> userIds = new Set<Id>();
            for (Opportunity opp : newOpportunities) {
                userIds.add(opp.OwnerId);
            }
            userIds.add(UserInfo.getUserId());

            if (!UsersCacheInstance.Users.keySet().containsAll(userIds)) {
                UsersCacheInstance.ValidateAndFill(userIds);
            }

            User rcsfUser;
            for (User usr : UsersCacheInstance.Users.values()) {
                if (usr.Name == UserHelper.RCSFSYNC_USER_NAME) {
                    rcsfUser = usr;
                }
            }

            //We need current user obj often
            User currentUser = UsersCacheInstance.Users.get(UserInfo.getUserId());

            //We will need accounts several times
            Set<Id> accountIdSet = new Set<Id>();
            for (Opportunity opp : newOpportunities) {
                if (opp.AccountId != null) {
                    accountIdSet.add(opp.AccountId);
                }
            }
            doSoql = false;
            for (Id aId : accountIdSet) {
                if (!accountMapStatic.containsKey(aId)) {
                    doSoql = true;
                }
            }
            if (doSoql) {
                List<Account> accountList = (List<Account>) new AccountSelector()
                    .selectAccountsForOpportunityTrigger(accountIdSet)
                    .executeQuery();

                for (Account acc : accountList) {
                    accountMapStatic.put(acc.Id, acc);
                }
                for (Proserv_Email_Country__mdt pe : Proserv_Email_Country__mdt.getAll().values()) {
                    String ME = (pe.Engage_Digital__c) ? '_ED' : '';
                    String key = pe.MasterLabel.toLowerCase() + ME;
                    emailMapping.put(key, pe);
                }
            }

            // We will need quotes several times so find them in case oppty update
            if (Trigger.isUpdate) {
                OpportunityHelper.populateOppRelatedStaticCollections(newOpportunitiesByIds);
                setOppToPartnerOperationLogMap();
            }

            //Also we need Opportunity record types maps
            DescribeSObjectResult oppect = Opportunity.SObjectType.getDescribe();
            Map<String, Schema.RecordTypeInfo> oppRecordTypesByNames = oppect.getRecordTypeInfosByName();

            // Start the logic
            // B-1124
            for (Opportunity currentOpp : newOpportunities) {
                if (Trigger.isInsert && !String.isEmpty(currentOpp.StageName)) {
                    // set Highest_Opp_Stage_Reached__c
                    currentOpp.Highest_Opp_Stage_Reached__c = currentOpp.StageName;
                }

                if (String.isBlank(currentOpp.Segment_Name_Oppty_Close__c) &&
                    isChangedFieldTo(currentOpp, Opportunity.StageName, OpportunityHelper.STAGE_NAME_CLOSED_WON)) {
                    currentOpp.Segment_Name_Oppty_Close__c = currentOpp.Segment_Name__c;
                }

                if (Trigger.isUpdate) {
                    Opportunity oldOpp = oldOpportunitiesByIds.get(currentOpp.Id);

                    //B-6108
                    if (!closedOpportunityStges.contains(oldOpp.StageName) &&
                        closedOpportunityStges.contains(currentOpp.StageName)) {
                        if (currentOpp.AccountId != null) {
                            String oppBrand = currentOpp.Brand_Name__c != null ? currentOpp.Brand_Name__c : '';
                            String rcBand = accountMapStatic != null && accountMapStatic.get(currentOpp.AccountId) != null && accountMapStatic.get(currentOpp.AccountId).RC_Brand__c != null ? accountMapStatic.get(currentOpp.AccountId).RC_Brand__c : '';
                            String rcServiceName = accountMapStatic != null && accountMapStatic.get(currentOpp.AccountId) != null && accountMapStatic.get(currentOpp.AccountId).RC_Service_name__c != null ? accountMapStatic.get(currentOpp.AccountId).RC_Service_name__c : '';
                            if (!rcBand.containsIgnoreCase('BT') && !rcServiceName.containsIgnoreCase('BT') && !oppBrand.containsIgnoreCase('BT')) {
                                checkProservAndSendMail(currentOpp);
                            }
                        }
                    }

                    Double oldProbabilityValue = oldOpp.Probability;
                    if (oldProbabilityValue == null) {
                        oldProbabilityValue = 0;
                    }
                    if (currentOpp.Probability > oldProbabilityValue) {
                        // set Highest_Opp_Stage_Reached__c
                        currentOpp.Highest_Opp_Stage_Reached__c = currentOpp.StageName;
                    }
                }
            }

            //Bypass for api users
            if (UserInfo.getName() == 'API User' || UserInfo.getName() == 'Xander RCSF DataLoaderUser') {
                System.debug('### RETURNED FROM OPPORTUNITY BEFORE TRG For Relayware###');
                return;
            }

            //Populate closed date for closed opps
            //Prevent unauthorized owner change
            if (Trigger.isUpdate) {
                for (Opportunity opp : newOpportunities) {
                    Opportunity oldL = oldOpportunitiesByIds.get(opp.Id);
                    if (opp.IsClosed && !oldL.IsClosed) {
                        opp.DFR_Actual_Close_DateTime__c = Datetime.now();
                    }
                    // Code for adding Validation.   New If block Case #03793086
                    if (opp.OwnerId != oldL.OwnerId
                        && oldL.OwnerId != null
                        && TriggerHandler.IsByPassedValidaionOnOppty == false
                        && (UsersCacheInstance.Users
                            .get(UserInfo.getUserId()).Profile.Name.equalsIgnoreCase('Channel Sales - Lightning') ||
                        UsersCacheInstance.Users
                            .get(UserInfo.getUserId()).Profile.Name.equalsIgnoreCase('Partner Sales Specialists - Lightning'))) {
                        opp.addError('You are not authorized to transfer this Opportunity.');
                    }
                }
            } else {
                for (Opportunity l : newOpportunities) {
                    if (l.IsClosed) {
                        l.DFR_Actual_Close_DateTime__c = Datetime.now();
                    }
                }
            }

            //Convert CR-38701 Strategic Partner RC Owner Process Builder to code
            if (Trigger.isUpdate || Trigger.isInsert) {
                List<Opportunity> oppList = new List<Opportunity>();
                Set<Id> setOfAccountIds = new Set<Id>();

                for (Opportunity opp : newOpportunities) {
                    if (opp.Strategic_Partner_RC_Owner__c == null && (opp.RecordTypeName__c == 'New Sales Opportunity' || opp.RecordTypeName__c == 'VAR Opportunity')) {
                        if (ConvertLead.byPassStrategicPartner) {
                            opp.Strategic_Partner_RC_Owner__c = opp.OwnerId;
                            continue;
                        }
                        oppList.add(opp);
                    }
                    setOfAccountIds.add(opp.AccountId);
                }

                Map<Id, Id> mapAcctoSRCO = new Map<Id, Id>();
                //Strategic RC Owner Share starts
                if (!Test.isRunningTest()) {
                    for (AccountTeamMember atm : (List<AccountTeamMember>) new AccountTeamMemberSelector()
                        .selectAccountTeamMemberByAccountId(new List<Object>{
                            setOfAccountIds
                        })
                        .setQueryCaching(true)
                        .executeQuery()
                    ) {
                        System.debug('+++++ atm' + atm);
                        if (atm.TeamMemberRole == 'Strategic Partner RC Owner') {
                            mapAcctoSRCO.put(atm.AccountId, atm.UserId);
                        }
                    }
                }

                Id leanDataId = Id.valueOf(System.Label.LeanDataUserId);

                if (!oppList.isEmpty()) {
                    for (Opportunity newOpp : oppList) {
                        if (newOpp.Brand_Name__c == 'Avaya Cloud Office') {
                            if (!mapAcctoSRCO.isEmpty() && mapAcctoSRCO != null) {
                                newOpp.Strategic_Partner_RC_Owner__c = mapAcctoSRCO.get(newOpp.AccountId);
                                System.debug('++++Strategic_Partner_RC_Owner__c 1' + mapAcctoSRCO.get(newOpp.AccountId));
                            } else {
                                newOpp.Strategic_Partner_RC_Owner__c = leanDataId;
                                System.debug('++++Strategic_Partner_RC_Owner__c 2' + leanDataId);
                            }
                        }
                    }
                }
            }

            //Partner ID change logic
            for (Opportunity opp : (List<Opportunity>) Trigger.new) {
                Account acc = accountMapStatic.get(opp.AccountId);
                if (UserInfo.getUserType().containsIgnoreCase('Partner') && Trigger.isInsert) {
                    opp.Partner_Owner__c = UserInfo.getUserId();
                }
                if (acc != null) {
                    if (Trigger.isInsert
                        || opp.RecordTypeId == oldOpportunitiesByIds.get(opp.Id).RecordTypeId
                        || (oppRecordTypesByNames.get('Sales Opportunity').getRecordTypeId() != opp.RecordTypeId
                        && oppRecordTypesByNames.get('New Sales Opportunity').getRecordTypeId()
                        != opp.RecordTypeId)) {
                        if (opp.Partner_ID__c != acc.Partner_ID__c && acc.Partner_ID__c != null && oppIdToPartnerOperationLog.get(opp.Id) == null) {
                            opp.Partner_ID__c = acc.Partner_ID__c;
                            opp.Partner_Contact__c = acc.Partner_Contact__c;
                            opp.Partner_Account__c = acc.Partner_Contact__r.AccountId;
                        }
                    }
                } else if (UserInfo.getUserType().containsIgnoreCase('Partner') && Trigger.isInsert) {
                    if (currentUser.Contact.AccountId != null) {
                        opp.AccountId = currentUser.Contact.AccountId;
                        opp.Partner_ID__c = currentUser.Contact.Account.Partner_ID__c;
                    }
                }
            }

            //Pretty much the same code as above
            if (UserInfo.getUserType().containsIgnoreCase('PowerPartner')
                || UserInfo.getUserType().containsIgnoreCase('Partner')) {
                OpportunityHelper.checkPartnerOpportunityPermittedByBrand(
                    (List<Opportunity>) Trigger.new,
                    (Trigger.isInsert ? null : (Map<Id, Opportunity>) Trigger.oldMap),
                    OpportunityHelper.getApprovedBrandList((List<Opportunity>) Trigger.new)
                );
            }

            //Another Bypasses
            if (TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT || TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE) {
                System.debug('### RETURNED FROM OPP INSERT TRG ###');
                return;
            } else {
                System.debug('### STILL CONTINUE FROM OPP INSERT TRG ###');
            }

            //All sales agents must have a Employee record with Division filled in.
            //The Division field is used when checking the activepipe limits. Different divisions have different limits
            String division;

            // EU Privacy Phase 3 IT Profile changes - START
            Set<String> profiles_who_cant_access_emp_objects = new Set<String>();
            List<EU_Component_Reference__mdt> euComp = [Select Values__c from EU_Component_Reference__mdt where Apex_Classes__c like '%OpportunityTriggerHelperRefactored%' and DeveloperName = 'ProfilesWhoCantAccessEmployeeObjects'];
            String profilesList  = (euComp.size() > 0) ? euComp[0].Values__c : '';
            if(String.isNotBlank(profilesList)) {
                profiles_who_cant_access_emp_objects.addAll(profilesList.split(','));
            }

                if (
                        !profiles_who_cant_access_emp_objects.contains(currentUser.Profile.Name) // EU Privacy Phase 3 IT Profile changes - END
                        && !ProfileHelper.PROFILE_NAME_COM_INTEGRATION_PROFILE.equalsIgnoreCase(currentUser.Profile.Name)
                        && !ProfileHelper.PROFILE_NAME_BIZ_INTEGRATION_PROFILE.equalsIgnoreCase(currentUser.Profile.Name)
                        && !UserInfo.getUserType().containsIgnoreCase('Partner')
                        && !AquivaHelper.isCurrentUserSuitableForRecallingEL()
            ) {
                try {
                    division = currentUser.Employees__r[0].Division__c;
                } catch (Exception e) {
                    for (Opportunity obj : (List<Opportunity>) Trigger.new) {
                        obj.addError('This user does not have access privilege to Employee object.');
                    }
                }
            }

            // Establish Activepipelimits for divisions
            Integer activePipeLimitGeneral = 80;
            Integer activePipeLimitVP_OB2 = 100;

            if (
                !profiles_who_cant_access_emp_objects.contains(currentUser.Profile.Name) // Added for EU Privacy Phase 3 IT Profile changes
            ) {
                //We need to check if we really need to query all opps
                Boolean queryOpps = false;
                if (Trigger.isInsert) {
                    queryOpps = true;
                } else {
                    for (Opportunity opp : newOpportunities) {
                        if (activeOpportunityStages.contains(opp.StageName)
                            && !activeOpportunityStages.contains(oldOpportunitiesByIds.get(opp.Id).StageName)) {
                            queryOpps = true;
                        }
                    }
                }

                Id rcId = oppRecordTypesByNames.get('Sales Opportunity').getRecordTypeId();
                Map<String, Integer> mapOwnerOPPCount = new Map<String, Integer>();
                if (queryOpps) {
                    Set<Id> setOwnerId = new Set<Id>();
                    for (Opportunity opp : newOpportunities) {
                        setOwnerId.add(opp.OwnerId);
                    }
                    for (AggregateResult objAggregateResult : [
                        SELECT OwnerId, COUNT(Id) cnt
                        FROM Opportunity
                        WHERE OwnerId IN :setOwnerId
                        AND StageName IN :activeOpportunityStages
                        AND (RecordTypeId = :rcId OR RecordTypeId = NULL)
                        GROUP BY OwnerId
                    ]) {
                        mapOwnerOPPCount.put(
                            String.valueOf(objAggregateResult.get('OwnerId')),
                            Integer.valueOf(objAggregateResult.get('cnt'))
                        );
                    }
                }

                //Set Last Touched/Responded fields and enforce ActivePipe limit.
                //The limit makes sure that agents do not hold activepipe opportunities
                //with the thought that eventually a order will come in and they can get "free" credit.
                Map<String, ActivePipeOpportunityExemptedProfiles__c> apo = ActivePipeOpportunityExemptedProfiles__c.getAll();
                for (Opportunity opp : newOpportunities) {

                    // set touched and responded fields
                    opp.Last_Touched_Date__c = Datetime.now();
                    opp.Last_Touched_By__c = UserInfo.getUserId();

                    if (opp.Responded_Date__c == null) {
                        opp.Responded_Date__c = Datetime.now();
                    }
                    if (opp.Responded_By__c == null) {
                        opp.Responded_By__c = UserInfo.getUserId();
                    }

                    // enforce activepipe limit
                    if (Trigger.isInsert
                        || (activeOpportunityStages.contains(opp.StageName)
                        && !activeOpportunityStages.contains(oldOpportunitiesByIds.get(opp.Id).StageName))) {
                        Integer activePipeCount = mapOwnerOPPCount.get(opp.OwnerId) == null
                            ? 0
                            : mapOwnerOPPCount.get(opp.OwnerId);

                        if ((activePipeCount >= activePipeLimitVP_OB2
                            && (division == 'VISTAPRINT OB'
                            || division == 'Sales - Fax'
                            || division.toUpperCase().equals('OUTBOUND 2- INITIALS')))
                            || (activePipeCount >= activePipeLimitGeneral
                            && (division != 'VISTAPRINT OB'
                            && division != 'Sales - Fax'
                            && !division.toUpperCase().equals('OUTBOUND 2- INITIALS')))) {
                            OpportunityMethods om = new OpportunityMethods();

                            if (division == 'VISTAPRINT OB'
                                || division == 'Sales - Fax'
                                || division.toUpperCase().equals('OUTBOUND 2- INITIALS')) {
                                if (!'Solve Then Sell'.equalsIgnoreCase(opp.LeadSource)) {
                                    if (apo.get(UserInfo.getProfileId()) == null) {
                                        om.sendActivePipeLimitEmail(opp, activePipeCount + 1, activePipeLimitVP_OB2);
                                    }
                                }
                            } else {
                                if (!'Solve Then Sell'.equalsIgnoreCase(opp.LeadSource)) {
                                    if (apo.get(UserInfo.getProfileId()) == null) {
                                        om.sendActivePipeLimitEmail(opp, activePipeCount + 1, activePipeLimitGeneral);
                                    }
                                }
                            }
                        }
                    }
                }
            }

            //MARKETO DUPLICATE CONTACT
            List<Opportunity> opptyList = new List<Opportunity>();
            for (Opportunity opp : newOpportunities) {
                User userObj = UsersCacheInstance.Users.get(opp.OwnerId);
                if (userObj == null
                    //|| !userObj.isActive      // B-4552
                    || userObj.Name.equalsIgnoreCase(UserHelper.RCSFSYNC_USER_NAME)
                    || userObj.Name.equalsIgnoreCase('India Team')
                    || userObj.Name.equalsIgnoreCase('RCPartner Sync')) {
                    opptyList.add(opp);
                }
            }

            if (opptyList.size() > 0) {
                if (Trigger.isInsert) {
                    AssetAssignmentHelper.assignAssets(opptyList);
                } else if (Trigger.isUpdate) {
                    AssetAssignmentHelper.reassignAssets(opptyList, oldOpportunitiesByIds);
                }
                OpportunityLARHelper.assignCampaignToOpportunity(opptyList);
                OpportunityLARHelper.initialOpportunities(opptyList, UsersCacheInstance.Users);
            }

            //Insert specific logic
            if (Trigger.isInsert) {
                for (Opportunity opp : newOpportunities) {
                    if (opp.CloseDate == null) {
                        opp.CloseDate = System.today();
                    }

                    User usr = UsersCacheInstance.Users.get(opp.OwnerId);
                    opp.Owner_Manager_Email__c = usr.Manager.Email;
                    opp.Owner_Manager_Name__c = usr.Manager.Name;

                    if (accountMapStatic.get(opp.AccountId) != null) {
                        opp.Original_Account_MRR__c = accountMapStatic.get(opp.AccountId).MRR__c;
                    }
                }
            } else {

                if (!currentUser.IsTmtTriggersDisabled__c) {
                    // B-1179 New Commissionable Estimated 12 Month Booking Field
                    //Estimated Pro Services SOW calculation
                    Set<Id> proservRecordTypeIds = new Set<Id>{
                        QuoteHelper.RT_ID_PROSERV,
                        QuoteHelper.RT_ID_CC_PROSERV
                    };

                    List<Quote> quotesList = new List<Quote>();
                    for (List<Quote> quoteList : OpportunityHelper.opptyToQuotesMapStatic.values()) {
                        quotesList.addAll(quoteList);
                    }

                    List<Quote> primaryQuotes = new List<Quote>();
                    List<Quote> proservQuotes = new List<Quote>();

                    for (Quote q : quotesList) {
                        if (q.isPrimary__c == true) {
                            primaryQuotes.add(q);
                        } else if (proservRecordTypeIds.contains(q.RecordTypeId)) {
                            proservQuotes.add(q);
                        }
                    }

                    //Calculate estimated proserv service cost for individual opportunities
                    Map<Id, Decimal> oppIdProServSOW = OpportunityHelper.calculateEstimatedProservServices(
                        proservQuotes,
                        QuoteLineItem.TotalPrice
                    );

                    Map< Id, Map<String, Decimal>> oppIdToFieldToValue = new Map< Id, Map<String, Decimal>>();

                    Decimal totalPriceForFeatures;
                    Decimal totalPriceAllProducts;
                    Decimal totalPriceTaxes;

                    for (Quote q : primaryQuotes) {
                        totalPriceForFeatures = 0;
                        totalPriceAllProducts = 0;
                        totalPriceTaxes = 0;

                        if (q.RecordType == null
                            || q.RecordType.DeveloperName == SALES_QUOTE_DEVELOPER_RT_NAME) {
                            for (QuoteLineItem qli : q.QuoteLineItems) {
                                totalPriceAllProducts += qli.TotalInitialPrice__c;
                                if (qli.Product2.Feature__c == 11 || qli.Product2.Feature__c == 39) {
                                    totalPriceForFeatures += qli.TotalInitialPrice__c;
                                }
                                if (qli.Product2.Family == PRODUCT_FAMILY_TAXES) {
                                    totalPriceTaxes += qli.TotalInitialPrice__c;
                                }
                            }
                        }

                        oppIdToFieldToValue.put(q.OpportunityId, new Map<String, Decimal>{
                            'First_Year_Total_Cost_excluding_Taxes__c' => q.First_Year_Total_Cost_excluding_Taxes__c == null
                                ? 0
                                : q.First_Year_Total_Cost_excluding_Taxes__c,
                            'First_Year_Cost_of_Service__c' => q.First_Year_Cost_of_Service__c == null
                                ? 0
                                : q.First_Year_Cost_of_Service__c,
                            'Monthly_Recurring_Revenue__c' => q.Monthly_Recurring_Revenue__c == null
                                ? 0
                                : q.Monthly_Recurring_Revenue__c,
                            'Initial_Payment__c' => q.Initial_Payment__c == null
                                ? 0
                                : q.Initial_Payment__c,
                            'sumProServOneTime__c' => q.sumProServOneTime__c == null
                                ? 0
                                : q.sumProServOneTime__c,
                            'TotalPrice' => q.TotalPrice,
                            'totalPriceAllProducts' => totalPriceAllProducts,
                            'totalPriceForFeatures' => totalPriceForFeatures,
                            'totalPriceProServSOW' => (oppIdProServSOW.containsKey(q.OpportunityId) ?
                                oppIdProServSOW.get(q.OpportunityId) : 0),
                            'totalPriceTaxes' => totalPriceTaxes
                        });
                    }

                    //Survey Sets for CSAT(Sales)
                    Set<Id> oppSetForCsatSurvey = new Set<Id>();

                    //Put new implementations in list to prevent dml inside loop

                    Feature_Toggle__c featureToggle = Feature_Toggle__c.getInstance();

                    for (Opportunity opp : newOpportunities) {
                        Opportunity oldOpp = oldOpportunitiesByIds.get(opp.Id);

                        // B-1179 New Commissionable Estimated 12 Month Booking Field
                        if (oppIdToFieldToValue.containsKey(opp.Id)) {
                            Map<String, Decimal> thisOppAndValuesFields = oppIdToFieldToValue.get(opp.Id);

                            Boolean allowX12MonthBookingManualUpdate = IsCurrentUserFromSalesEnterpriseDivision();
                            Boolean allowX12MonthBookingAutoUpdate = (
                                !IsCurrentUserFromSalesEnterpriseDivision()
                                    && !IsOpportunityOwnerFromSalesEnterpriseDivison(opp)
                            );

                            if (!allowX12MonthBookingManualUpdate && !allowX12MonthBookingAutoUpdate) {
                                opp.X12_Month_Booking__c = ((Opportunity) Trigger.oldMap.get(opp.Id)).X12_Month_Booking__c;
                            }
                        }

                        //Update Owner Manager fields
                        if (opp.OwnerId != oldOpp.OwnerId) {
                            if (UserInfo.getUserName() != Emails__c.getall().get('rcsfsyncuser').Email_Address__c) {
                                User usr = UsersCacheInstance.Users.get(opp.OwnerId);
                                if (usr != null) {
                                    opp.Owner_Manager_Email__c = usr.Manager.Email;
                                    opp.Owner_Manager_Name__c = usr.Manager.Name;
                                }
                            }
                        }

                        if (opp.StageName == '0. Downgraded' && oldOpp.StageName != '0. Downgraded') {
                            opp.Downgrade_Date_Opp__c = Date.today();
                        }

                        //If Opp is closed set date and send *Sales survey *Added CSAT survey
                        if (OpportunityHelper.isClosed(opp.StageName) &&
                            !OpportunityHelper.isClosed(oldOpp.StageName) &&
                            !'Channel Sales Manager'.equalsIgnoreCase(currentUser.Profile.Name) &&
                            !'Channel Sales Manager - Lightning'.equalsIgnoreCase(currentUser.Profile.Name)) {

                            if (currentUser.Profile.Name == 'System Administrator' && oldOpp.CloseDate != null) {
                                if (opp.CloseDate == oldOpp.CloseDate) {
                                    opp.CloseDate = System.today();
                                }
                            } else {
                                opp.CloseDate = Date.today();
                            }

                            if (!'System Administrator'.equalsIgnoreCase(currentUser.Profile.Name)) {
                                if (opp.RecordTypeId == oppRecordTypesByNames.get('Saves Opportunity').getRecordTypeId()
                                    && opp.Brand_Name__c.contains('RingCentral')) {
                                    oppSetForCsatSurvey.add(opp.Id);
                                }
                            }
                        }

                        //If Opp has been closed and user is trying to change closedate reset back to original closedate
                        if (OpportunityHelper.isClosed(opp.StageName) &&
                            OpportunityHelper.isClosed(oldOpp.StageName) &&
                            opp.CloseDate != oldOpp.CloseDate) {

                            if (!'System Administrator'.equalsIgnoreCase(currentUser.Profile.Name)) {
                                opp.CloseDate = oldOpp.CloseDate;
                                opp.addError('You cannot modify the Close Date of a Closed Opportunity.');
                            }
                        }

                        //If Opp is not closed and user is trying to change closedate reset back to original closedate
                        if (activeOpportunityStages.contains(opp.StageName)
                            && opp.CloseDate != oldOpp.CloseDate) {
                            Date todayDate = System.today();
                            Date oppDate = opp.CloseDate;
                            if (!'System Administrator'.equalsIgnoreCase(currentUser.Profile.Name)) {
                                if (oppDate < todayDate) {
                                    opp.addError('You cannot set the Close Date to the past');
                                }
                            }
                        }

                        if (oldOpp.Partner_Owner__c != opp.Partner_Owner__c
                            && String.isNotBlank(opp.Partner_Owner__c)) {
                            opp.Partner_Owner_Assignment_Date__c = System.today();
                        }

                        //Populate Total Contract Value (Override) - CR-38201: QW: Add TCV fields in SFDC Object
                        if (oldOpp.Total_Contract_Value__c != opp.Total_Contract_Value__c) {
                            if ((oldOpp.Total_Contract_Value_Override__c == 0 || oldOpp.Total_Contract_Value_Override__c == null) || oldOpp.Total_Contract_Value__c == oldOpp.Total_Contract_Value_Override__c) {
                                opp.Total_Contract_Value_Override__c = opp.Total_Contract_Value__c;
                            }
                        }
                    }
                }
            }

            //Populate Owner Name from Owner Id
            Set<Id> ownerIds = new Set<Id>();
            for (Opportunity opp : (List<Opportunity>) Trigger.new) {
                if (isChangedField(opp, Opportunity.OwnerId)
                    && opp.OwnerId != null) {
                    ownerIds.add(opp.OwnerId);
                }
            }
            if (!ownerIds.isEmpty()) {
                Map<Id, User> ownerNamesByIds = new Map<Id, User>([
                    SELECT Name
                    FROM User
                    WHERE Id IN :ownerIds
                ]);
                for (Opportunity opp : (List<Opportunity>) Trigger.new) {
                    if (ownerNamesByIds.containsKey(opp.OwnerId)) {
                        opp.OpportunityOwnerName__c = ownerNamesByIds.get(opp.OwnerId).Name;
                    }
                }
            }

            if (Trigger.isUpdate) {
                for (Opportunity opty : newOpportunities) {
                    if (isChangedFieldTo(opty, Opportunity.StageName, OpportunityHelper.STAGE_NAME_DOWNGRADED)) {
                        opty.ConfirmAndClose__c = false;
                    }
                }
            }

            //START ITEA-682 AAA AAE (Expansion team) assignment
            //Description: Update Opp Owners under Avaya Customer Accounts with Account Current Owner/ Owner Value

            Schema.DescribeSObjectResult result = Account.SObjectType.getDescribe();
            Map<Id, Schema.RecordTypeInfo> rtMapByName = result.getRecordTypeInfosById();

            for (Opportunity opp : (List<Opportunity>) Trigger.new) {
                if (opp.StageName != OpportunityHelper.STAGE_NAME_DOWNGRADED && opp.StageName != OpportunityHelper.STAGE_NAME_CLOSED_WON) {
                    Account acc = null;
                    if (opp.AccountId != null) {
                        acc = accountMapStatic.get(opp.AccountId);
                    }
                    if (acc != null) {
                        if (acc.RecordTypeId != null && rtMapByName.get(acc.RecordTypeId) != null) {
                            if (rtMapByName.get(acc.RecordTypeId).getName() == AccountHelper.RT_NAME_CUSTOMER_ACCOUNT && acc.RC_Brand__c == OpportunityHelper.BRAND_AVAYA) {
                                if (acc.Current_Owner__c != null) {
                                    opp.OwnerId = acc.Current_Owner__c;
                                } else {
                                    opp.OwnerId = acc.OwnerId;
                                }
                            }
                        }
                    }
                }
            }
        }

        private void setOppToPartnerOperationLogMap() {
            Set<Id> accountIds = accountMapStatic.keySet();

            if (accountIds.isEmpty() || isPartnerOperationsLogSet) {
                return;
            }

            List<PartnerOperationsLog__c> currentPartnerOperationsLogs = (List<PartnerOperationsLog__c>)
            new QueryFactory(PartnerOperationsLog__c.SObjectType)
                .selectFields(new List<String>{
                    'Id',
                    'Account__c',
                    'Opportunity__c',
                    'Approval__c',
                    'isCompleted__c',
                    'PartnerInfo__c'
                })
                .setQueryBindings(new List<Object>{ accountIds })
                .setCondition('isCompleted__c = false AND isRejected__c = false AND Account__c IN :bind0')
                .executeQuery();

            if (!currentPartnerOperationsLogs.isEmpty()) {
                for (PartnerOperationsLog__c po: currentPartnerOperationsLogs) {
                    oppIdToPartnerOperationLog.put(po.Opportunity__c, po);
                }
            }
            isPartnerOperationsLogSet = true;
        }

        private void checkProservAndSendMail(Opportunity opp) {
            if (OpportunityHelper.opptyToQuotesMapStatic.get(opp.Id) != null) {

                //CR-54801: Dynamic Proserv Email template
                String customerCountry = accountMapStatic != null && accountMapStatic.get(opp.AccountId) != null && accountMapStatic.get(opp.AccountId).BillingCountry != null ? accountMapStatic.get(opp.AccountId).BillingCountry.toLowerCase() : null;
                Boolean isEngageDigital = accountMapStatic != null && accountMapStatic.get(opp.AccountId) != null && accountMapStatic.get(opp.AccountId).Engage_Digital_Account__c != null ? accountMapStatic.get(opp.AccountId).Engage_Digital_Account__c : false;
                List<Proserv_Email_Country__mdt> countryList = emailMapping.values();
                List<String> availableCountries = new List<String>();
                for (Proserv_Email_Country__mdt pe : countryList) {
                    availableCountries.add(pe.MasterLabel.toLowerCase());
                }
                String countryName = availableCountries.contains(customerCountry) ? customerCountry : 'Default';
                String EDCustomer = (isEngageDigital) ? '_ED' : '';
                String key = countryName + EDCustomer;
                String templateName = (emailMapping.get(key) != null) ? emailMapping.get(key).Email_Template__c : '';

                for (Quote currentQuote : OpportunityHelper.opptyToQuotesMapStatic.get(opp.Id)) {
                    if (currentQuote.RecordTypeId != QuoteHelper.RT_ID_PROSERV ||
                        currentQuote.ProServ_Status__c != QuoteHelper.PROSERVSTATUS_SOLD) {
                        continue;
                    }
                    Map<String, String> params = new Map<String, String>();
                    params.put('opportunityId', opp.Id);
                    if (!String.isBlank(templateName)) {
                        params.put('templateApiName', templateName);
                    } else {
                        params.put('templateApiName', QuotingToolQuoteApexController.PROSERV_AUTOMATED_EMAIL);
                    }
                    params.put('Primary_Opportunity_Contact__c', opp.Primary_Opportunity_Contact__c);
                    params.put('Current_Owner__c', accountMapStatic.get(opp.AccountId).Current_Owner__c);
                    params.put('Inside_Sales_Rep__c', accountMapStatic.get(opp.AccountId).Inside_Sales_Rep__c);
                    params.put('Brand_Name__c', opp.Brand_Name__c);
                    QuotingToolQuoteApexController.sendMail(params);
                }
            }
        }
    }

    public class ProcessConfirmAndCloseFlow extends Triggers.TriggerHandlerBase {
        Feature_Toggle__c featureToggle = Feature_Toggle__c.getInstance();

        override public void handle() {

            if (Trigger.isUpdate && isChangeOrderFlow) {
                return;
            }

            if (!featureToggle.Approval_For_Change_Order_Process__c) {
                return;
            }

            // Get map assignement of template name to its id
            String templateId = QuoteHelper.getTemplate(regularTemplateName);
            if (templateId == null) {
                return;
            }

            Boolean containsBillingOpp = false;
            Set<Id> primaryQuoteIdSet = new Set<Id>();
            for (Opportunity opty : (List<Opportunity>) Trigger.new) {
                Quote primaryQuote = QuoteHelper.getPrimaryQuote(OpportunityHelper.opptyToQuotesMapStatic.get(opty.Id), opty.Is_Billing_Opportunity__c);
                if (primaryQuote == null) {
                    continue;
                }

                if (opty.Is_Billing_Opportunity__c) {
                    containsBillingOpp = true;
                }

                primaryQuoteIdSet.add(primaryQuote.Id);
            }

            Map<Id, Quote> reselectedPrimaryQuotesMap = new Map<Id, Quote>();

            if (containsBillingOpp && !primaryQuoteIdSet.isEmpty()) {
                reselectedPrimaryQuotesMap = new Map<Id, Quote>([
                    SELECT Id, RecordTypeId, Upsell_Status__c, Package_Info__c,
                        CurrentService__c, CurrentService__r.ChargeTerm__c,
                        CurrentService__r.Product__r.Charge_Term__c, Approved_Status__c,
                        CurrentService__r.EffectivePrice__c, CurrentService__r.Active__c,
                        CurrentService__r.Discount__c, CurrentService__r.Discount_Type__c,
                        CurrentService__r.Price__c, Opportunity.Tier_Name__c, (
                        SELECT Id, PackageInfo__c, QuoteRecordType__c, Deactivated__c, Package_Info_QLI__c,
                            Quote.RecordTypeId, UnitPrice, Discount_number__c, Quote.Package_Info__c,
                            Discount_type__c, EffectivePriceNew__c, Quantity,
                            PackageCatalogId__c, PackageVersion__c,
                            Product2Id, Product2.Feature__c, Product2.Family, Product2.ExtID__c,
                            Product2.Charge_Term__c, Entitlement__c,
                            Entitlement__r.Active__c, Entitlement__r.Discount__c,
                            Entitlement__r.Discount_Type__c, Entitlement__r.Price__c,
                            Entitlement__r.ChargeTerm__c, Entitlement__r.EffectivePrice__c,
                            Entitlement__r.PackageCatalogId__c, Entitlement__r.PackageVersion__c,
                            Entitlement__r.Product__c, Entitlement__r.Product__r.Charge_Term__c,
                            Entitlement__r.Product__r.Feature__c, Entitlement__r.Product__r.Family,
                            Entitlement__r.PackageDuration__c
                        FROM QuoteLineItems
                    )
                    FROM Quote
                    WHERE Id IN :primaryQuoteIdSet
                ]);
            }

            for (Opportunity opty : (List<Opportunity>) Trigger.new) {
                Boolean isRequestCustomerApproval = opty.ConfirmAndClose__c && isChangedFieldTo(opty, Opportunity.StageName, OpportunityHelper.STAGE_NAME_ORDER) || isChangedFieldTo(opty, Opportunity.ConfirmAndClose__c, true) && opty.StageName == OpportunityHelper.STAGE_NAME_ORDER;
                if (!isRequestCustomerApproval) {
                    return;
                }

                Quote primaryQuote = QuoteHelper.getPrimaryQuote(OpportunityHelper.opptyToQuotesMapStatic.get(opty.Id), opty.Is_Billing_Opportunity__c);
                if (primaryQuote == null) {
                    return;
                }

                if(!QuoteHelper.APPROVAL_STATUSES_NOT_REQUIRED.contains(primaryQuote?.Approved_Status__c)) {
                    opty.addError(Label.QW_Notification_Primary_quote_does_not_contains_required_approvals);
                    return;
                }

                if (opty.Is_Billing_Opportunity__c) {
                    Quote reselectedPrimaryQuote = reselectedPrimaryQuotesMap.get(primaryQuote.Id);
                    templateId = getNGBSCustomerNotificationTemplateId(reselectedPrimaryQuote);
                    if (templateId == null) {
                        return;
                    }
                }

                Uuid uuid = new Uuid();
                String optyUuid = uuid.getValue();
                opty.Uuid__c = optyUuid;
                opty.CustomerConfirmation__c = OpportunityHelper.PENDING;
                opty.Confirm_And_Close_Quote_Info__c = TemplateEngine.createDoc(primaryQuote.Id, templateId);
            }
        }

        private String getNGBSCustomerNotificationTemplateId(Quote primaryQuote) {

            if (primaryQuote == null) {
                return null;
            }

            Boolean isPlanChange = QuoteHelper.isNGBSPlanChange(primaryQuote, primaryQuote.QuoteLineItems);
            Boolean isDiscountChange = QuoteHelper.isDiscountChange(primaryQuote.QuoteLineItems);
            Boolean isRaterJump = isRaterJump(primaryQuote);
            Boolean isEditionChange = QuoteHelper.isEditionChange(primaryQuote.QuoteLineItems);

            Boolean isUpsell = QuoteHelper.isUpsell(primaryQuote);
            Boolean isDownsell = QuoteHelper.isDownsell(primaryQuote.QuoteLineItems);

            Boolean isSamePrice = QuoteHelper.isSamePrice(primaryQuote);

            if (primaryQuote.Opportunity.Tier_Name__c == QuoteHelper.NGBS_FAX_PRODUCT) {
                isSamePrice = false;
            }

            String templateName = '';

            if (
                !isDownsell &&
                    isUpsell &&
                    !isSamePrice
            ) {
                if (primaryQuote.Opportunity.Tier_Name__c == QuoteHelper.NGBS_FAX_PRODUCT) {
                    templateName = incrementalFaxEmailTemplateName;
                } else if (QuoteHelper.isPhoenix(primaryQuote)) {
                    templateName = incrementalPhoenixEmailTemplateName;
                } else {
                    templateName = incrementalEmailTemplateName;
                }
            } else if (
                isPlanChange ||
                    isDiscountChange ||
                    isRaterJump ||
                    isEditionChange ||
                    isDownsell ||
                    (isUpsell && isSamePrice)
            ) {
                if (primaryQuote.Opportunity.Tier_Name__c == QuoteHelper.NGBS_FAX_PRODUCT) {
                    templateName = simplifiedFaxEmailTemplateName;
                } else if (QuoteHelper.isPhoenix(primaryQuote)) {
                    templateName = simplifiedPhoenixEmailTemplateName;
                } else {
                    templateName = simplifiedEmailTemplateName;
                }
            }

            return QuoteHelper.getTemplate(templateName);
        }

        // TODO: replace this method to QuoteHelper.isNGBSUpgrade after removing Entitlement from PackageInfo
        private Boolean isRaterJump(Quote primaryQuote) {
            Boolean result = false;

            if (primaryQuote == null) {
                return result;
            }

            for (QuoteLineItem qli : primaryQuote.QuoteLineItems) {
                if (qli.Entitlement__c == null) {
                    continue;
                }

                Decimal qliUnitPrice = qli.UnitPrice == null ? 0 : qli.UnitPrice;
                qliUnitPrice = qliUnitPrice.setScale(2, RoundingMode.HALF_UP);

                Decimal entlUnitPrice = qli.Entitlement__r.Price__c == null ? 0 : qli.Entitlement__r.Price__c;
                entlUnitPrice = entlUnitPrice.setScale(2, RoundingMode.HALF_UP);

                if (qliUnitPrice != entlUnitPrice) {
                    result = true;
                    break;
                }
            }

            return result;
        }
    }

    public class PopulateProvisionedAndSubStageFields extends Triggers.TriggerHandlerBase {

        Map<Id, String> opIdToUserRoleNameMap = new Map<Id, String>();
        Map<Id, Opportunity> opportunityNewMap = new Map<Id, Opportunity>();
        Feature_Toggle__c featureToggle = Feature_Toggle__c.getInstance();

        override public void handle() {

            if (Trigger.isUpdate && isChangeOrderFlow) {
                return;
            }

            opportunityNewMap = (Map<Id, Opportunity>) Trigger.newMap;

            Set<Id> quoteIdSet = new Set<Id>();
            for (Opportunity op : opportunityNewMap.values()) {
                if (isChangedFieldTo(op, Opportunity.StageName, OpportunityHelper.closedStage)) {
                    if (!featureToggle.ProvisioningFlow__c && !OpportunityHelper.isRenewalOpp(op)) {
                        continue;
                    }

                    if (!OpportunityHelper.opptyToQuotesMapStatic.containsKey(op.Id)) {
                        continue;
                    }

                    for (Quote qt : OpportunityHelper.opptyToQuotesMapStatic.get(op.Id)) {
                        quoteIdSet.add(qt.Id);
                    }
                }
            }

            List<QuoteLineItem> qliList = new List<QuoteLineItem>();

            if (!quoteIdSet.isEmpty()) {
                qliList = (List<QuoteLineItem>) new QuoteLineItemSelector()
                    .selectQuoteLineItemsByQuoteIds(quoteIdSet)
                    .executeQuery();
            }

            Map<Id, List<QuoteLineItem>> oppIdToQliListMap = new Map<Id, List<QuoteLineItem>>();
            for (QuoteLineItem qli : qliList) {
                if (!oppIdToQliListMap.containsKey(qli.Quote.OpportunityId)) {
                    oppIdToQliListMap.put(qli.Quote.OpportunityId, new List<QuoteLineItem>());
                }
                oppIdToQliListMap.get(qli.Quote.OpportunityId).add(qli);
            }

            if (!oppIdToQliListMap.keySet().containsAll(opportunityNewMap.keySet())) {
                for (Id oppId : opportunityNewMap.keySet()) {
                    if (!oppIdToQliListMap.containsKey(oppId)) {
                        oppIdToQliListMap.put(oppId, new List<QuoteLineItem>());
                    }
                }
            }

            List<Opportunity> optyToProcess = new List<Opportunity>();
            for (Opportunity op : opportunityNewMap.values()) {
                Opportunity oldOpp = (Opportunity) Trigger.oldMap.get(op.Id);
                if (isChangedFieldTo(op, Opportunity.StageName, OpportunityHelper.closedStage)) {
                    if (!featureToggle.ProvisioningFlow__c && !OpportunityHelper.isRenewalOpp(op)) {
                        continue;
                    }

                    if (OpportunityHelper.isRenewalOpp(op) && oldOpp.CloseDate >= Date.today()) {
                        op.Renewed_On_Time__c = true;
                    }

                    List<Quote> opptyQuotesList = OpportunityHelper.opptyToQuotesMapStatic.containsKey(op.Id) ?
                        OpportunityHelper.opptyToQuotesMapStatic.get(op.Id) : new List<Quote>();

                    Map<Id, List<QuoteLineItem>> quoteIdToQliListMap = new Map<Id, List<QuoteLineItem>>();
                    for (Quote qt : opptyQuotesList) {
                        for (QuoteLineItem qli : oppIdToQliListMap.get(qt.OpportunityId)) {
                            if (!quoteIdToQliListMap.containsKey(qli.QuoteId)) {
                                quoteIdToQliListMap.put(qli.QuoteId, new List<QuoteLineItem>());
                            }
                            quoteIdToQliListMap.get(qli.QuoteId).add(qli);
                        }
                    }

                    Boolean isRenewalOptyWithoutChanges = OpportunityHelper.isRenewalOptyWithoutChanges(
                        op,
                        opptyQuotesList,
                        quoteIdToQliListMap
                    );

                    if (isRenewalOptyWithoutChanges) {
                        op.Sub_Stage__c = StringHelper.defaultString(op.Sub_Stage__c, OpportunityHelper.SUB_STAGE_CLOSED);
                        op.Provision_By__c = (op.SelfProvisioned__c
                            ? OpportunityHelper.PROVISION_BY_SELF
                            : OpportunityHelper.PROVISION_BY_MANUAL);
                    } else if (op.SelfProvisioned__c) {
                        op.Provision_By__c = OpportunityHelper.PROVISION_BY_SELF;
                        op.Sub_Stage__c = OpportunityHelper.SUB_STAGE_CLOSED;
                    } else {
                        optyToProcess.add(op);
                    }
                } else if (isChangedFieldFrom(op, Opportunity.StageName, OpportunityHelper.closedStage)) {
                    op.Renewed_On_Time__c = false;
                }
            }

            if (!optyToProcess.isEmpty()) {
                Map<Id, List<QuoteLineItem>> quoteIdToQliListMap = new Map<Id, List<QuoteLineItem>>();
                for (Opportunity opp : optyToProcess) {
                    for (QuoteLineItem qli : oppIdToQliListMap.get(opp.Id)) {
                        if (!quoteIdToQliListMap.containsKey(qli.QuoteId)) {
                            quoteIdToQliListMap.put(qli.QuoteId, new List<QuoteLineItem>());
                        }
                        quoteIdToQliListMap.get(qli.QuoteId).add(qli);
                    }
                }
                processRecords(optyToProcess, quoteIdToQliListMap);
            }
        }

        private void processRecords(List<Opportunity> closedOptyList, Map<Id, List<QuoteLineItem>> quoteIdToQliListMap) {

            populateOpIdToUserRoleNameMap(closedOptyList);

            List<String> provisioningRoleList = new List<String>();
            for (ProvisioningRoles__c item : ProvisioningRoles__c.getAll().values()) {
                provisioningRoleList.add(item.DeveloperName__c);
            }

            for (Id optyId : OpportunityHelper.opptyToQuotesMapStatic.keySet()) {
                Opportunity opRecord = opportunityNewMap.get(optyId) != null ? opportunityNewMap.get(optyId) : new Opportunity();

                Quote primaryQuote = QuoteHelper.getPrimaryQuote(OpportunityHelper.opptyToQuotesMapStatic.get(optyId), opRecord.Is_Billing_Opportunity__c);
                if (primaryQuote == null) {
                    continue;
                }

                List<QuoteLineItem> primaryQuoteLineItems = quoteIdToQliListMap.containsKey(primaryQuote.Id) ?
                    quoteIdToQliListMap.get(primaryQuote.Id) : new List<QuoteLineItem>();

                if (!opRecord.Is_Billing_Opportunity__c) {
                    processNonNGBSOpty(opRecord, primaryQuote, primaryQuoteLineItems, provisioningRoleList);
                } else {
                    processNGBSOpty(opRecord, primaryQuote);
                }
            }
        }

        private void processNGBSOpty(Opportunity opRecord, Quote primaryQuote) {

            if (opRecord.Opportunity_Owner_Segment__c == 'Retention') {
                opRecord.Provision_By__c = OpportunityHelper.PROVISION_BY_RETENTION_TEAM;
                opRecord.Sub_Stage__c = OpportunityHelper.SUB_STAGE_PENDING_PROVISIONING;
            } else if (primaryQuote.Enabled_LBO__c) {
                opRecord.Provision_By__c = OpportunityHelper.PROVISION_BY_PROVISIONING_TEAM;
                opRecord.Sub_Stage__c = OpportunityHelper.SUB_STAGE_PENDING_PROVISIONING;
            } else {
                opRecord.Provision_By__c = OpportunityHelper.PROVISION_BY_MANUAL;
                opRecord.Sub_Stage__c = OpportunityHelper.SUB_STAGE_CLOSED;
            }
        }

        private void processNonNGBSOpty(Opportunity opRecord, Quote primaryQuote, List<QuoteLineItem> primaryQuoteLineItems, List<String> provisioningRoleList) {
            QuoteLineItem serviceQli = QuoteLineItemHelper.getServicePlanQLI(primaryQuoteLineItems);
            if (serviceQli != null) {
                List<Entitlement__c> accountEntlList = [
                    SELECT Id, Quantity__c, DisplayQuantity__c, Active__c, Product__c, Product__r.Feature__c, Product__r.Family, Account__c
                    FROM Entitlement__c
                    WHERE Account__c = :serviceQli.Quote.Account.Id
                ];

                entitlementMapStatic.putAll(accountEntlList);

                for (Entitlement__c ent : entitlementMapStatic.values()) {
                    if (
                        ent.Active__c
                            && Product2Helper.isServicePlan(ent.Product__r)
                            && ent.Account__c == opRecord.AccountId
                    ) {
                        accountServiceEntl = ent;
                        break;
                    }
                }
            }

            if (!provisioningRoleList.contains(opIdToUserRoleNameMap.get(opRecord.Id))
                || primaryQuote.Upsell_Status__c == QuoteHelper.STATUS_NEW_CUSTOMER
                || isRcsfUser()) {
                opRecord.Provision_By__c = OpportunityHelper.PROVISION_BY_MANUAL;
                opRecord.Sub_Stage__c = String.isBlank(opRecord.GoldfingerRetention__c) ? OpportunityHelper.SUB_STAGE_CLOSED :
                    opRecord.GoldfingerRetention__c;
            } else if (isSimpleUpsell(primaryQuote, primaryQuoteLineItems) && String.isBlank(opRecord.ProvisioningDetails__c)) {
                opRecord.Provision_By__c = setProvisionedBy(primaryQuote, primaryQuoteLineItems);
                opRecord.Sub_Stage__c = OpportunityHelper.SUB_STAGE_PENDING_PROVISIONING;
            } else {
                opRecord.Provision_By__c = OpportunityHelper.PROVISION_BY_PROVISIONING_TEAM;
                opRecord.Sub_Stage__c = OpportunityHelper.SUB_STAGE_PENDING_PROVISIONING;
            }
        }

        @TestVisible
        private String setProvisionedBy(Quote qt, List<QuoteLineItem> quoteLineItems) {
            Boolean isFaxOrProService = Pricebook2Helper.isFaxService(qt.Pricebook2.Service__c)
                || Pricebook2Helper.isProfessionalService(qt.Pricebook2.Service__c);

            Boolean rpaRouting = featureToggle.RPA_Routing__c
                && !isProvisionTeamRouting(quoteLineItems)
                && validatePhonesQuantityOnUpsellUpgrade(qt, quoteLineItems)
                && isRpaBrand(qt.Opportunity.Brand_Name__c)
                && !qt.MultipleShippingLocations__c
                && !isFaxOrProService
                && !isAnyDiscountOnQliDifferentFromEntitlement(quoteLineItems);

            return (rpaRouting
                ? OpportunityHelper.PROVISION_BY_RPA
                : OpportunityHelper.PROVISION_BY_PROVISIONING_TEAM);
        }

        private Boolean isRpaBrand(String brand) {
            Boolean isRpaBrand = false;
            if (brand == null) {
                isRpaBrand = true;
            } else {
                isRpaBrand = !(brand.contains(OpportunityHelper.BRAND_ATT)
                    || brand.contains(OpportunityHelper.BRAND_TELUS)
                    || brand.contains(OpportunityHelper.BRAND_BT));
            }
            return isRpaBrand;
        }

        private Boolean isRcsfUser() {
            Boolean isRcsfUser = false;
            // Check if opportunity is closed by rcsfUser
            for (User usr : UsersCacheInstance.Users.values()) {
                if (usr.Name == UserHelper.RCSFSYNC_USER_NAME && usr.Id == UserInfo.getUserId()) {
                    isRcsfUser = true;
                }
            }
            return isRcsfUser;
        }

        private Boolean isAnyDiscountOnQliDifferentFromEntitlement(List<QuoteLineItem> qliList) {
            Boolean isNewDiscountsInCart = false;

            for (QuoteLineItem qli : qliList) {
                if (
                    qli.Entitlement__c != null
                        && (
                        (Double) NumberHelper.getNumberNullSafe(qli.Entitlement__r.Discount__c)
                            != (Double) NumberHelper.getNumberNullSafe(qli.Discount_number__c)
                            || qli.Entitlement__r.Discount_Type__c != qli.Discount_type__c
                    )
                ) {
                    isNewDiscountsInCart = true;
                }
            }

            return isNewDiscountsInCart;
        }

        private Boolean validatePhonesQuantityOnUpsellUpgrade(Quote primaryQuote, List<QuoteLineItem> primaryQuoteLineItems) {
            Decimal servicePlanItemsQuantity = 0;
            Decimal phonesAmount = 0;

            for (QuoteLineItem qli : primaryQuoteLineItems) {
                if (Product2Helper.isPhone(qli)) {
                    phonesAmount += QuoteLineItemHelper.getQuantity(qli);
                }

                if (qli.Product2.Feature__c == Product2Helper.FEATURE_SERVICE_PLAN) {
                    servicePlanItemsQuantity += QuoteLineItemHelper.getQuantity(qli);
                }
            }

            return !QuoteHelper.STATUS_UPGRADE.equalsIgnoreCase(primaryQuote.Upsell_Status__c)
                && servicePlanItemsQuantity == phonesAmount
                || (
                QuoteHelper.STATUS_UPGRADE.equalsIgnoreCase(primaryQuote.Upsell_Status__c)
                    && accountServiceEntl.Quantity__c == servicePlanItemsQuantity
                    && (phonesAmount == 0 || servicePlanItemsQuantity == phonesAmount)
            );
        }

        private Boolean isProvisionTeamRouting(List<QuoteLineItem> quoteLineItems) {
            List<GlobalOfficeNumbersNotAvailable__c> gon = GlobalOfficeNumbersNotAvailable__c.getall().values();
            List<String> countryList = new List<String>();
            for (GlobalOfficeNumbersNotAvailable__c item : gon) {
                countryList.add(item.Name);
            }

            for (QuoteLineItem qli : quoteLineItems) {
                if (
                    qli.Product2.Feature__c == Product2Helper.FEATURE_GLOBAL_OFFICE
                        && !(QuoteLineItemHelper.getQuantity(qli) == 0)
                ) {
                    List<String> splittedName = qli.Product2.Name.split(' ');
                    for (Integer i = 0; i < splittedName.size(); i++) {
                        if (countryList.contains(splittedName[i])) {
                            return true;
                        }
                    }
                }

                if (Product2Helper.NUMBER_SETUP.contains(qli.Product2.Feature__c)) {
                    return true;
                }

                if (
                    (new Set<Decimal>{
                        Product2Helper.FEATURE_IVN_LOCAL, Product2Helper.FEATURE_IVN_TOLL_FREE
                    }).contains(qli.Product2.Feature__c)
                        && !(QuoteLineItemHelper.getQuantity(qli) == 0)
                ) {
                    return true;
                }
            }

            return false;
        }

        private void populateOpIdToUserRoleNameMap(List<Opportunity> optyList) {

            Set<Id> userIdSet = new Set<Id>();
            for (Opportunity opp : optyList) {
                userIdSet.add(opp.OwnerId);
            }

            Map<Id, User> userMap = new Map<Id, User>([
                SELECT Id, UserRole.Id, UserRole.Name
                FROM User
                WHERE Id IN :userIdSet
            ]);

            for (Opportunity opty : optyList) {
                String roleName = userMap.get(opty.OwnerId).UserRole.Name;
                opIdToUserRoleNameMap.put(opty.Id, roleName);
            }
        }

        @TestVisible
        private Boolean isSimpleUpsell(Quote primaryQuote, List<QuoteLineItem> primaryQuoteLineItems) {

            // Check if number of DLs have increased inside one Service Plan
            if (QuoteHelper.STATUS_UPSELL.equalsIgnoreCase(primaryQuote.Upsell_Status__c)) {
                if (!isUpsellServicePlan(primaryQuoteLineItems)) {
                    return false;
                }
            } else if (QuoteHelper.STATUS_UPGRADE.equalsIgnoreCase(primaryQuote.Upsell_Status__c)
                && primaryQuote.Pricebook2.Plan__c != Pricebook2Helper.PLAN_MONTHLY_CONTRACT) {
                if (!isUpgradeServicePlan(primaryQuoteLineItems)) {
                    return false;
                }
            } else {
                return false;
            }
            // Check if no products were added besides "one-time" products, products with feature 2 and 3, and service products
            for (QuoteLineItem qli : primaryQuoteLineItems) {
                // "Additional numbers" products quantity can't be less then the one on entitlements if they exist
                Boolean isAdditionalNumberIncreased = false;
                if (Product2Helper.FEATURE_NUMBERS.contains(qli.Product2.Feature__c)) {
                    if (qli.Entitlement__c == null) {
                        isAdditionalNumberIncreased = true;
                    } else {
                        isAdditionalNumberIncreased = qli.NewQuantity__c >= qli.Entitlement__r.DisplayQuantity__c;
                    }
                }
                if (!isAdditionalNumberIncreased
                    && !Product2Helper.isServicePlan(qli.Product2)
                    && qli.Product2.Dependent_on_Feature__c != Product2Helper.FEATURE_SERVICE_PLAN
                    && qli.Product2.Charge_Term__c != Product2Helper.CHARGE_TERM_ONE_TIME
                    && (qli.Entitlement__c == null || qli.Entitlement__r.DisplayQuantity__c != qli.NewQuantity__c)) {
                    return false;
                }
            }
            return true;
        }

        private Boolean isUpsellServicePlan(List<QuoteLineItem> qliList) {

            for (QuoteLineItem qli : qliList) {
                if ((new Set<Decimal>{
                    Product2Helper.FEATURE_SERVICE_PLAN, Product2Helper.FEATURE_SERVICE_PLAN_FAX
                }).contains(qli.Product2.Feature__c)) {
                    if (qli.Entitlement__c != null
                        && qli.Entitlement__r.Active__c
                        && qli.NewQuantity__c >= qli.Entitlement__r.DisplayQuantity__c) {
                        return true;
                    }
                }
            }
            return false;
        }

        private Boolean isUpgradeServicePlan(List<QuoteLineItem> qliList) {
            QuoteLineItem qliService = QuoteLineItemHelper.getServicePlanQLI(qliList);

            if (qliService == null) {
                return false;
            }
            return accountServiceEntl != null
                ? qliService.NewQuantity__c >= accountServiceEntl.DisplayQuantity__c
                : qliService.NewQuantity__c >= qliList[0].Quote.Account.Number_of_DL_s__c;
        }
    }

    /*  Case #05444468 - Set Primary Campaign Source as last modified Campaign History from Contact
        Added By: Shevchenko Snizhana
        Created Date: 06 Mar 2017
    */
    public class SetOpportunityCampaign extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Set<Id> contIds = new Set<Id>();
            for (Opportunity opp : (List<Opportunity>) Trigger.new) {
                if (opp.conversion_contact__c != null) {
                    contIds.add(opp.conversion_contact__c);
                } else if (opp.Primary_Opportunity_Contact__c != null) {
                    contIds.add(opp.Primary_Opportunity_Contact__c);
                }
            }

            Feature_Toggle__c featureCS = Feature_Toggle__c.getInstance();

            if (contIds.size() > 0 && !contIds.isEmpty()) {
                Map<Id, CampaignMember> contId_campaignId = new Map<Id, CampaignMember>();
                for (CampaignMember cm : getCampaignMemberList(contIds)) {
                    if (featureCS == null || !featureCS.New_Campaign_Influence__c) {
                        contId_campaignId.put(cm.ContactId, cm);
                    } else {
                        if (!contId_campaignId.containsKey(cm.ContactId)
                            ||
                            cm.Campaign.Non_Attributable__c == false
                            ||
                            (
                                cm.Campaign.Non_Attributable__c == true
                                    &&
                                    contId_campaignId.containsKey(cm.ContactId)
                                    &&
                                    contId_campaignId.get(cm.ContactId).Campaign.Non_Attributable__c == true
                            )
                        ) {
                            contId_campaignId.put(cm.ContactId, cm);
                        }
                    }
                }

                contIds.clear();
                for (Opportunity opp : (List<Opportunity>) Trigger.new) {
                    if (opp.conversion_contact__c != null && contId_campaignId.containsKey(opp.conversion_contact__c)) {
                        opp.CampaignId = contId_campaignId.get(opp.conversion_contact__c).CampaignId;
                        opp.BMID__c = contId_campaignId.get(opp.conversion_contact__c).Campaign.BMID__c;
                        opp.Primary_Marketing_Asset__c = contId_campaignId.get(opp.conversion_contact__c).Primary_Marketing_Asset__c;  
                    } else if(opp.Primary_Opportunity_Contact__c != null && contId_campaignId.containsKey(opp.Primary_Opportunity_Contact__c)){
                            opp.CampaignId = opp.LeadSource == 'AIM Buddy' ? opp.CampaignId : contId_campaignId.get(opp.Primary_Opportunity_Contact__c).CampaignId;
                            opp.BMID__c = contId_campaignId.get(opp.Primary_Opportunity_Contact__c).Campaign.BMID__c;
                            opp.Primary_Marketing_Asset__c = contId_campaignId.get(opp.Primary_Opportunity_Contact__c).Primary_Marketing_Asset__c;  
                   }
                }
            }
        }
        public List<CampaignMember> getCampaignMemberList(Set<Id> campaignMemberIds) {
            List<CampaignMember> queryResult = new List<CampaignMember>();
            if (campaignMemberIds.isEmpty()) {
                return queryResult;
            }
            List<Object> bindings = new List<Object>();
            bindings.add(campaignMemberIds);
            CampaignMemberSelector getCampaignMemberInfo = new CampaignMemberSelector();
            queryResult.addAll((List<CampaignMember>) getCampaignMemberInfo
                .selectCampaignMemberForOpportunityMethods(bindings)
                .executeQuery());
            return queryResult;
        }
    }

    public class UpdateCloseDateCounter extends Triggers.TriggerHandlerBase {
        override public void handle() {
            for (Opportunity newOpp : (List<Opportunity>) Trigger.new) {
                Date newOppCloseDate = newOpp.CloseDate;
                Date oldOppCloseDate = (Trigger.isInsert) ? null : ((Opportunity) Trigger.oldMap.get(newOpp.Id)).CloseDate;
                Boolean newCloseDateNotNullAndMoreThanOldCloseDate =
                    ((oldOppCloseDate != newOppCloseDate)
                        && newOppCloseDate != null
                        && (oldOppCloseDate == null
                        || oldOppCloseDate < newOppCloseDate))
                        ? true
                        : false;

                //if Close_Date_Counter__c has not been set before, setting it 0;
                if (newOpp.Close_Date_Counter__c == null) {
                    newOpp.Close_Date_Counter__c = 0;
                }
                if (newCloseDateNotNullAndMoreThanOldCloseDate) {
                    newOpp.Close_Date_Counter__c++;
                }
            }
        }
    }

    public class OpportunityAfterInsert extends Triggers.TriggerHandlerBase {
        override public void handle() {
            //get current user object. It is already in static map
            User currentUser = UsersCacheInstance.Users.get(UserInfo.getUserId());

            //Also we need Opportunity record types maps
            DescribeSObjectResult oppect = Opportunity.SObjectType.getDescribe();
            Map<String, Schema.RecordTypeInfo> oppRecordTypesByNames = oppect.getRecordTypeInfosByName();
            List<Opportunity> oppsForDfr = new List<Opportunity>();
            //Cast Trigger variables once
            Map<Id, Opportunity> newOpportunities = (Map<Id, Opportunity>) Trigger.newMap;
            List<String> DFROppRType = DG_DFR_Class_Helper.getDFROppRType();
            Map<Id, String> mapRTId = new Map<Id, String>();
            for (String optyType : DFROppRType) {
                optyType = optyType.replace('_', ' ');
                if (oppRecordTypesByNames.containsKey(optyType)) {
                    mapRTId.put(
                        oppRecordTypesByNames.get(optyType).getRecordTypeId(),
                        oppRecordTypesByNames.get(optyType).getName()
                    );
                }
            }

            //Logiс execution start
            //This is a part of DFR logic
            for (Opportunity opp : (List<Opportunity>) Trigger.new) {
                if (
                    opp.Primary_Opportunity_Contact__c <> null &&
                        mapRTId.containsKey(opp.RecordTypeId) && (opp.Brand_Name__c == null
                        || (opp.Brand_Name__c != null && System.Label.BizMerge_Brand_Exclusion_List != null
                        && !System.Label.BizMerge_Brand_Exclusion_List.contains(opp.Brand_Name__c)) )
                ) {
                    oppsForDfr.add(opp);
                }
            }

            try {
                if (!Queueable_DG_DFR_Class.isQueueuableLimitsReached() && !skipAsyncDFR) {
                    System.enqueueJob(new Queueable_DG_DFR_Class.DFR_AddOpportunity(oppsForDfr, ConvertLead.IS_LEAD_CONVERT_PROCESSING));
                } else {
                    if (!ConvertLead.IS_LEAD_CONVERT_PROCESSING) {
                        DG_DFR_Class.DFR_AddOpportunity(oppsForDfr);
                    }
                }
            } catch (Exception e) {
                DG_DFR_Class.dfrSaveException(e, null, null, null, oppsForDfr);
            }

            //Bypasses
            if (TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT || TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE) {
                System.debug('### RETURNED FROM OPP INSERT-AFTER TRG ###');
                return;
            } else {
                System.debug('### STILL CONTINUE FROM OPP INSERT-AFTER TRG ###');
            }

            // Direct to VAR
            //Another Saves survey
            Set<Id> oppSetForCsatSurveyOnInsertion = new Set<Id>();
            for (Opportunity opp : newOpportunities.values()) {
                if (OpportunityHelper.isClosed(opp.StageName) &&
                    !'Channel Sales Manager - Lightning'.equalsIgnoreCase(currentUser.Profile.Name)) {
                    //Channel sales manager profile is excluded because we dont want to send those contacts surveys
                    if (!'System Administrator'.equalsIgnoreCase(currentUser.Profile.Name)) {
                        //IF RecordType Save Opportunity AND Brand contains RingCentral Then CREATE CSAT Survey*
                        if (opp.RecordTypeId == oppRecordTypesByNames.get('Saves Opportunity').getRecordTypeId()
                            && opp.Brand_Name__c.contains('RingCentral')) {
                            oppSetForCsatSurveyOnInsertion.add(opp.Id);
                        }
                    }
                }
            }

            //Update account. No queries
            OpportunityMethods objOpportunityMethods = new OpportunityMethods();
            objOpportunityMethods.updateParentAccount(newOpportunities, null);
        }
    }

    /*  Case #05444468 - Create new Contact Role in the related list on the Opportunity
        Added By: Shevchenko Snizhana
        Created Date: 06 Mar 2017
    */
    public class CreateOpportunityContactRole extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<OpportunityContactRole> newContactRoleList = new List<OpportunityContactRole>();
            if (!ConvertLead.IS_LEAD_CONVERT_PROCESSING) {
                for (Opportunity opp : (List<Opportunity>) Trigger.new) {
                    if (opp.Primary_Opportunity_Contact__c != null) {
                        newContactRoleList.add(
                            new OpportunityContactRole(
                                ContactId = opp.Primary_Opportunity_Contact__c,
                                OpportunityId = opp.Id,
                                Role = 'Signatory',
                                IsPrimary = true
                            )
                        );
                    }
                }
            }
            if (!newContactRoleList.isEmpty()) {
                DG_DFR_Class.byPassDFRContact = true;
                skipOpportunityContactRoleValidations = true;
                insert newContactRoleList;

            }
        }
    }

    public class CreateKYCApprovalForIndiaOffice extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Opportunity>listIndiaOfficeOpps = new List<Opportunity>();
            for (Opportunity opp : (List<Opportunity>) Trigger.new) {
                if (OpportunityHelper.isIndia(opp)) {
                    listIndiaOfficeOpps.add(opp);
                }
            }
            if (!listIndiaOfficeOpps.isEmpty()) {
                OpportunityHelper.createKYCApprovalsForIndiaOffice(listIndiaOfficeOpps);
            }
        }
    }

    public class CreateSalesTaxExemptionApproval extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Approval__c> approvalsToCreate = new List<Approval__c>();
            Map<Id, Approval__c> masterOppToMasterApproval = getMasterAmazonApprovalForTechApproval((List<Opportunity>) Trigger.new);

            for (Opportunity opp : (List<Opportunity>) Trigger.new) {
                if (!String.isBlank(opp.BusinessIdentity__c) && OpportunityHelper.isAmazon(opp) && OpportunityHelper.isNewBusiness(opp)) {
                    Approval__c approvalToCreate = new Approval__c();
                    TaxExemptionHelper.populateFieldsForSalesTaxExemptionApprovals(approvalToCreate, opp, masterOppToMasterApproval);
                    approvalsToCreate.add(approvalToCreate);
                    TaxExemptionHelper.isAutomaticApprovalMap.put(opp.Id, true);
                }
            }

            if (!approvalsToCreate.isEmpty()) {
                insert approvalsToCreate;
            }
        }

        private Map<Id, Approval__c> getMasterAmazonApprovalForTechApproval(List<Opportunity> opportunities) {
            Map<Id, Approval__c> result = new Map<Id, Approval__c>();
            Set<Id> masterOppIds = new Set<Id>();

            for (Opportunity opp : opportunities) {
                if (String.isNotBlank(opp.MasterOpportunity__c)
                    && !String.isBlank(opp.BusinessIdentity__c)
                    && OpportunityHelper.isAmazon(opp)
                    && OpportunityHelper.isNewBusiness(opp)
                ) {
                    masterOppIds.add(opp.MasterOpportunity__c);
                }
            }
            if (masterOppIds.isEmpty()) {
                return result;
            }

            List<Approval__c> masterApprovals = (List<Approval__c>) new ApprovalSelector()
                .selectInvoiceApprovalsForPayableInfoByOpportunityId(new List<Object>{
                    new Set<Id> { ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL },
                    masterOppIds,
                    new Set<String>{ ApprovalHelper.STATUS_APPROVED }
                })
                .executeQuery();
            if (masterApprovals.isEmpty()) {
                return result;
            }

            for (Approval__c app : masterApprovals) {
                result.put(app.Opportunity__c, app);
            }

            return result;
        }
    }

    public class OpportunityAfterUpdate extends Triggers.TriggerHandlerBase {
        override public void handle() {
            //Bypass for api users
            if (UserInfo.getName() == 'API User' || UserInfo.getName() == 'Xander RCSF DataLoaderUser') {
                System.debug('### RETURNED FROM OPPORTUNITY AFTER TRG For Relayware###');
                return;
            }

            //Cast trigger variables once
            List<Opportunity> newOpportunities = (List<Opportunity>) Trigger.new;
            Map<Id, Opportunity> newOpportunitiesByIds = (Map<Id, Opportunity>) Trigger.newMap;
            Map<Id, Opportunity> oldOpportunitiesByIds = (Map<Id, Opportunity>) Trigger.oldMap;
            Set<Id> newOppIds = newOpportunitiesByIds.keySet();

            //get current user object. It is already in static map
            User currentUser = UsersCacheInstance.Users.get(UserInfo.getUserId());

            //Also we need Opportunity record types maps
            DescribeSObjectResult oppect = Opportunity.SObjectType.getDescribe();
            Map<String, Schema.RecordTypeInfo> oppRecordTypesByNames = oppect.getRecordTypeInfosByName();

            Set<Id> usersToQuery = new Set<Id>{ UserInfo.getUserId() };

            // We will need accounts several times
            Set<Id> accountIdSet = new Set<Id>();
            for (Opportunity opp : newOpportunities) {
                if (opp.AccountId != null) {
                    accountIdSet.add(opp.AccountId);
                }
                if (oldOpportunitiesByIds.get(opp.Id).AccountId != null) {
                    accountIdSet.add(oldOpportunitiesByIds.get(opp.Id).AccountId);
                }
            }
            Boolean doSOQL = false;
            for (Id aId : accountIdSet) {
                if (!accountMapStatic.containsKey(aId)) {
                    doSOQL = true;
                }
            }
            if (doSOQL) {
                List<Account> accountList = (List<Account>) new AccountSelector()
                    .selectAccountsForOpportunityTrigger(accountIdSet)
                    .executeQuery();

                for (Account acc : accountList) {
                    accountMapStatic.put(acc.Id, acc);
                }
            }

            // We will need quotes several times
            doSOQL = false;
            Boolean isHaveDowngradedOppotunities = false;
            for (Opportunity oppty : newOpportunities) {
                usersToQuery.add(oppty.OwnerId);
                if (!OpportunityHelper.opptyToQuotesMapStatic.containsKey(oppty.Id)) {
                    doSOQL = true;
                }
                if (isChangedFieldTo(oppty, Opportunity.StageName, '0. Downgraded')) {
                    isHaveDowngradedOppotunities = true;
                }
            }
            if (doSOQL) {
                List<Quote> newQuotes = (List<Quote>) new QuoteSelector()
                    .selectQuotes()
                    .selectFields(new List<String>{
                        'Id', 'OpportunityId', 'TotalPrice', 'Monthly_Recurring_Revenue__c', 'ProServ_Status__c',
                        'First_Year_Cost_of_Service__c', 'First_Year_Total_Cost_excluding_Taxes__c', 'Status',
                        'Initial_Payment__c', 'sumProServOneTime__c', 'isPrimary__c', 'RecordType.DeveloperName'
                    })
                    .setCondition('OpportunityId IN :bind0')
                    .setQueryBindings(new List<Object>{
                        newOpportunitiesByIds.keySet()
                    })
                    .setQueryCaching(true)
                    .executeQuery();
                OpportunityHelper.populateOpptyToQuotesMapStatic(newQuotes, newOpportunitiesByIds.keySet());
            }

            for (Account acc : accountMapStatic.values()) {
                usersToQuery.add(acc.OwnerId);
            }
            AccountTriggerHelper.populateUsersStatic(usersToQuery);

            // When an opportunity changes its account, force an update on all its quotes so their LastModifiedDate reflects the account change (BZS-8270)
            List<Quote> quotesToUpdateLastModifiedDate = new List<Quote>();
            for (Id oppId : Trigger.oldMap.keySet()) {
                if (((Opportunity) Trigger.oldMap.get(oppId)).AccountId != ((Opportunity) Trigger.newMap.get(oppId)).AccountId
                    && OpportunityHelper.opptyToQuotesMapStatic.get(oppId) != null) {
                    quotesToUpdateLastModifiedDate.addAll(OpportunityHelper.opptyToQuotesMapStatic.get(oppId));
                }
            }
            if (quotesToUpdateLastModifiedDate.size() > 0) {
                Triggers.switchOff();
                TriggerHandler.BY_PASS_QUOTE_ON_UPDATE = true;
                update quotesToUpdateLastModifiedDate;  // Update without changes except for LastModified fields
                TriggerHandler.BY_PASS_QUOTE_ON_UPDATE = false;
                Triggers.switchOn();
            }

            //START Account TCV Logic
            Map<Id, Account> acctMap = new Map<Id, Account>();
            if(!accountIdSet.isEmpty()){
                acctMap = new Map<Id, Account>([SELECT Id, Total_Contract_Value_Calculated__c, Total_Contract_Value_Override__c FROM Account WHERE Id = :accountIdSet]);
            }
            Map<Id, List<Opportunity>> acctOpptyMap = new Map<Id, List<Opportunity>>();
            if(!acctMap.keySet().isEmpty()){
                for (Opportunity opp : (List<Opportunity>) new OpportunitySelector()
                    .selectOpportunities()
                    .selectFields(new List<String>{
                        'Id', 'AccountId', 'Total_Contract_Value_Override__c'
                    })
                    .setCondition('AccountId = :bind0 AND StageName = :bind1 AND Total_Contract_Value_Override__c != :bind2')
                    .setQueryBindings(new List<Object>{
                        acctMap.keySet(), OpportunityHelper.STAGE_NAME_CLOSED_WON, null
                    })
                    .setQueryCaching(true)
                    .executeQuery()) {
                    if (!acctOpptyMap.containsKey(opp.AccountId)) {
                        acctOpptyMap.put(opp.AccountId, new List<Opportunity>{
                            opp
                        });
                    } else {
                        acctOpptyMap.get(opp.AccountId).add(opp);
                    }
                }
            }
            //END Account TCV Logic

            List<DFR_Update_Field__e> eventList = new List<DFR_Update_Field__e>();

            List<Opportunity> medalliaOpptyList = new List<Opportunity>();
            List<Approval__c> approvals = new List<Approval__c>();
            if (isHaveDowngradedOppotunities) {
                approvals = [
                    SELECT Id, Status__c, Record_Type_Name__c, Opportunity__c
                    FROM Approval__c
                    WHERE Opportunity__c IN :newOppIds
                ];
            }

            // B-4893
            List<Account> accountsToUpdate = new List<Account>();
            List<Approval__c> approvalsToUpdate = new List<Approval__c>();
            for (Opportunity opp : newOpportunities) {
                if (accountsToUpdate.contains(accountMapStatic.get(opp.AccountId)) || accountsToUpdate.contains(acctMap.get(opp.AccountId))) {
                    continue;
                }
                if (isChangedField(opp, Opportunity.AccountId)) {
                    //DFR SM Employees AND Account
                    eventList.add(new DFR_Update_Field__e(
                        Id__c = opp.Id,
                        Fields__c = DemandFunnelPlatEvents.ACCOUNT_FIELD + ';' + DemandFunnelPlatEvents.SM_EMPLOYEES_FIELD
                    ));
                    Account acc = accountMapStatic.get(opp.AccountId);
                    Account oldAcc = accountMapStatic.get(oldOpportunitiesByIds.get(opp.Id).AccountId);

                    if (!OpportunityHelper.opptyToQuotesMapStatic.containsKey(opp.Id)) {
                        accountsToUpdate.add(acc);
                        continue;
                    }

                    for (Quote q : OpportunityHelper.opptyToQuotesMapStatic.get(opp.Id)) {
                        if (q.Status == 'Active') {
                            if (acc.Active_Sales_Agreement__c != null) {
                                opp.addError('It is prohibited to have more than one Active Sales Agreement for Account');
                            } else {
                                acc.Active_Sales_Agreement__c = q.Id;
                                accountsToUpdate.add(acc);
                                if (oldAcc.Active_Sales_Agreement__c == q.Id) {
                                    oldAcc.Active_Sales_Agreement__c = null;
                                    accountsToUpdate.add(oldAcc);
                                }
                            }
                            break;
                        }
                    }
                }

                //START Account TCV Logic
                if ((isChangedField(opp, Opportunity.StageName) &&
                    (opp.StageName == OpportunityHelper.STAGE_NAME_CLOSED_WON ||
                        oldOpportunitiesByIds.get(opp.Id).StageName == OpportunityHelper.STAGE_NAME_CLOSED_WON)
                )
                    ||
                    (isChangedField(opp, Opportunity.Total_Contract_Value_Override__c) &&
                        opp.StageName == OpportunityHelper.STAGE_NAME_CLOSED_WON)
                ) {

                    Decimal sumOpptysTCVOverride = 0;
                    if (acctOpptyMap != null && !acctOpptyMap.isEmpty()) {
                        sumOpptysTCVOverride = calculateOpptysTCV(acctOpptyMap, opp.AccountId);
                    }

                    Account accTCV = acctMap.get(opp.AccountId);
                    if (accTCV != null) {
                        if ((accTCV.Total_Contract_Value_Calculated__c == 0 || accTCV.Total_Contract_Value_Calculated__c == null) ||
                            accTCV.Total_Contract_Value_Calculated__c == accTCV.Total_Contract_Value_Override__c) {
                            accTCV.Total_Contract_Value_Override__c = sumOpptysTCVOverride;
                        }

                        accTCV.Total_Contract_Value_Calculated__c = sumOpptysTCVOverride;
                        accountsToUpdate.add(accTCV);
                    }

                }
                //END Account TCV Logic

                //Create Medallia Survey Record if Amount > $75
                if (HelperUtils.isMedallia &&
                    opp.Amount >= 75 &&
                    OpportunityHelper.isClosed(opp.StageName) &&
                    opp.StageName != oldOpportunitiesByIds.get(opp.Id).StageName &&
                    UserInfo.getUserType().equalsIgnoreCase('Standard') &&
                    !UserInfo.getName().containsIgnoreCase('RCSF')) {
                    medalliaOpptyList.add(opp);
                }

                if (isChangedFieldTo(opp, Opportunity.StageName, '0. Downgraded')) {
                    List<String> approvalStatusesLegalEngaged = new List<String>{
                        'new', 'in progress', 'ready for signature',
                        'out for signature', 'in negotiation', 'approved', 'pendingl1approval'
                    };
                    if (!approvals.isEmpty()) {
                        for (Approval__c approval : approvals) {
                            if (approval.Opportunity__c == opp.Id && approvalStatusesLegalEngaged.contains(approval.Status__c.toLowerCase())
                                && approval.Record_Type_Name__c.equals('Engage Legal')) {
                                approval.Status__c = 'Lost';
                                approvalsToUpdate.add(approval);
                            }
                        }
                    }
                }
            }

            if (!accountsToUpdate.isEmpty()) {
                Triggers.switchOff();
                update accountsToUpdate;
                Triggers.switchOn();
            }

            if (!medalliaOpptyList.isEmpty()) {
                ByPassTrigger__c bypassTrigger = ByPassTrigger__c.getInstance();
                //Depricate Signature Survey CR-86101
                if (!bypassTrigger.Bypass_Old_Signature_Survey__c) {
                    MedalliaSurveyHelper.insertSignatureMedalliaSurvey(medalliaOpptyList);
                }
            }

            //DFR SM Employees AND Account
            if (!eventList.isEmpty()) {
                PlatformEvents.publishPlatformEvent(eventList, 'OpportunityTriggerHelperRefactored');
            }

            //DFR Logic
            if (Trigger.new.size() == 1) {
                List<String> DFROppRType = DG_DFR_Class_Helper.getDFROppRType();

                Map<Id, String> mapRTId = new Map<Id, String>();
                for (String optyType : DFROppRType) {
                    optyType = optyType.replace('_', ' ');
                    if (oppRecordTypesByNames.containsKey(optyType)) {
                        mapRTId.put(
                            oppRecordTypesByNames.get(optyType).getRecordTypeId(),
                            oppRecordTypesByNames.get(optyType).getName()
                        );
                    }
                }

                Opportunity newOpportunity = newOpportunities[0];
            }

            if (!Queueable_DG_DFR_Class.isQueueuableLimitsReached() && !Test.IsRunningTest() && !skipAsyncDFR) {
                System.enqueueJob(new Queueable_DG_DFR_Class.DFR_OpportunityClosed(newOpportunities, oldOpportunitiesByIds));
            } else {
                DG_DFR_Class.DFR_OpportunityClosed(newOpportunities, oldOpportunitiesByIds);
                DG_DFR_Class.DFR_OpportunityOwnerChange(newOpportunities, oldOpportunitiesByIds);
            }

            //Bypasses
            if (TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT || TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE) {
                System.debug('### RETURNED FROM OPP INSERT-AFTER TRG ###');
                return;
            } else {
                System.debug('### STILL CONTINUE FROM OPP INSERT-AFTER TRG ###');
            }

            //Update parent account
            //We have 3x update accounts here. Needs to be optimized
            OpportunityMethods objOpportunityMethods = new OpportunityMethods();
            objOpportunityMethods.updateParentAccount(newOpportunitiesByIds, oldOpportunitiesByIds);
            if (OpportunityMethods.OpportunityUpdate_FirstRun) {
                objOpportunityMethods.updateAccountMostRecentContact(newOpportunitiesByIds, oldOpportunitiesByIds);
                objOpportunityMethods.updateAccountMostRecentOppTouched(newOpportunitiesByIds, oldOpportunitiesByIds);
                OpportunityMethods.OpportunityUpdate_FirstRun = false;
            }

            //update engage legals due to opportunity status changes
            if (Trigger.isUpdate) {
                if (!approvalsToUpdate.isEmpty()) {
                    List<User> legalUsers = ApprovalHelperCls.findLegals();
                    if (!legalUsers.isEmpty()) {
                        List<Id> emails = new List<Id>();
                        for (User u : legalUsers) {
                            if (String.isNotBlank(u.Email)) {
                                emails.add(u.Id);
                            }
                        }
                        EmailTemplate template = ApprovalTriggerHandler.getEmailTemplate('Legal_Approval_Status_Changes_Due_To_Opp_Changes');
                        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
                        for (Approval__c app : approvalsToUpdate) {
                            ApprovalHelperCls.InternalEmail mail = new ApprovalHelperCls.InternalEmail(emails, template.Subject, template.HtmlValue);
                            mail.addParameter('Approval__c.Name', app.Name);
                            mail.addParameter('Approval__c.Status', app.Status__c);
                            mail.addParameter('User.Name', String.format('{0} {1}', new List<String>{
                                UserInfo.getFirstName(), UserInfo.getLastName()
                            }));
                            mail.addParameter('Approval.Link', BASE_URL + '/' + app.Id);
                            mail.addParameter('Opportunity.Link', BASE_URL + '/' + app.Opportunity__c);
                            for (Opportunity opp : newOpportunities) {
                                if (opp.Id == app.Opportunity__c) {
                                    mail.addParameter('Opportunity.Name', opp.Name);
                                    mail.addParameter('Opportunity.StageName', opp.StageName.substring(2));
                                    mail.addParameter('Account.Name', opp.Account.Name);
                                }
                            }
                            mails.addAll(mail.getMails());
                        }
                        if (!mails.isEmpty()) {
                            Messaging.sendEmail(mails);
                        }
                    }
                }
                if(!approvalsToUpdate.isEmpty()){
                	update approvalsToUpdate;
                }
            }
            // Mavenlink integration logic
            Set<Id> oppsId = new Set<Id>();
            for (Opportunity opp : (List<Opportunity>) Trigger.new) {
                if (isChangedFieldFrom(opp, Opportunity.CloseDate, null)
                    || isChangedFieldFrom(opp, Opportunity.EstimatedProfessionalServices12Month__c, null)) {
                    oppsId.add(opp.Id);
                }
            }
            if (!oppsId.isEmpty()) {
                PhaseTriggerHandler.updateRelatedPhases('Opportunity', oppsId);
            }
            // End of Mavenlink integration logic
        }

        public Decimal calculateOpptysTCV(Map<Id, List<Opportunity>> acctOpptyMap, Id accId) {
            Decimal sumOppsTCVOverride = 0;
            List<Opportunity> oppsForAccount = acctOpptyMap.get(accId);

            if (oppsForAccount != null) {
                for (Opportunity opp : acctOpptyMap.get(accId)) {
                    sumOppsTCVOverride += opp.Total_Contract_Value_Override__c;
                }
            }
            return sumOppsTCVOverride;
        }
    }

    /**
    * Delete all related Quote Line Items on Quote Deletion
    */
    public class ValidateOpportunityBeforeDelete extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Map<Id, Quote> quoteMap = new Map<Id, Quote>([
                SELECT Id, RecordTypeId
                FROM Quote
                WHERE Opportunity.Id IN :Trigger.oldMap.keySet()
            ]);
            EntitlementHelper.DeleteRelatedEntitlements(quoteMap.values());
            delete [SELECT Id FROM Area_Code_Line_Item__c WHERE Quote_Line_Item__r.QuoteId IN :quoteMap.keySet() AND Quote_Line_Item__r.IsMultiProductTechnicalQLI__c = false];
        }
    }

    /*
        Contains map with User Id as a key and User object instance as value.
    */
    public class UsersCacheHolder {
        private Map<Id, User> usersMap = new Map<Id, User>();

        public Map<Id, User> Users {
            get {
                return usersMap;
            }
        }

        public void ValidateAndFill(Set<Id> userIds) {
            if (userIds == null) {
                return;
            }
            List<Id> idsToRetrieve = new List<Id>();
            for (Id userId : userIds) {
                if (this.usersMap.containsKey(userId) == false) {
                    idsToRetrieve.add(userId);
                }
            }
            User[] retrievedUsers = [
                SELECT Id, IsTmtTriggersDisabled__c, ContactId, Contact.AccountId, Division,
                    Contact.Account.Partner_ID__c, Contact.Account.Permitted_Brands__c, ManagerId,
                    Manager.Username, Manager.Name, Manager.Email, Name, Profile.Name, ProfileId,
                    Phone, IsActive, Mkto_Reply_Email__c, FirstName, LastName, Email, (SELECT Id, Division__c FROM Employees__r)
                FROM User
                WHERE Id IN :idsToRetrieve OR Name = 'RCSF Sync'
            ];

            for (User entry : retrievedUsers) {
                this.usersMap.put(entry.Id, entry);
            }
        }
    }

    public static Boolean IsCurrentUserFromSalesEnterpriseDivision() {
        Id currentUserId = UserInfo.getUserId();
        if (UsersCacheInstance.Users.containsKey(currentUserId) == false) {
            UsersCacheInstance.ValidateAndFill(new Set<Id>{
                currentUserId
            });
        }
        String currentUserDivision = UsersCacheInstance.Users.get(currentUserId).Division;
        return OpportunityHelper.USER_DIVISION_SALES_ENTERPRISE.equalsIgnoreCase(currentUserDivision);
    }

    public static Boolean IsOpportunityOwnerFromSalesEnterpriseDivison(Opportunity opty) {
        if (opty == null) {
            CustomException ex = new CustomException();
            ex.setMessage('NULL found instead of an Opportunity instance');
            PlatformLog.logException('OpportunityTriggerHelperRefactored.IsOpportunityOwnerFromSalesEnterpriseDivison', ex);
            throw ex;
        }
        if (opty.OwnerId == null) {
            CustomException ex = new CustomException();
            ex.setMessage('Opportunity must contains OwnerId');
            PlatformLog.logException('OpportunityTriggerHelperRefactored.IsOpportunityOwnerFromSalesEnterpriseDivison', ex);
            throw ex;
        }
        return IsOpportunityOwnerFromSalesEnterpriseDivison(opty.OwnerId);
    }

    public static Boolean IsOpportunityOwnerFromSalesEnterpriseDivison(Id opportunityOwnerId) {
        User optyOwner = UsersCacheInstance.Users.get(opportunityOwnerId);
        if (optyOwner != null && String.isNotBlank(optyOwner.Division)) {
            return OpportunityHelper.USER_DIVISION_SALES_ENTERPRISE.equalsIgnoreCase(optyOwner.Division);
        }
        return false;
    }

    public class StageValidation extends Triggers.TriggerHandlerBase {
        Set<Id> oppsIds;
        Boolean stcValidationv2;
        Map<Id, Id> userIdsByOppIds;
        Map<String, String> roleNames;
        Map<Id, Decimal> quotesByOppsId;
        Map<Id, String> ownerNamesByOppsId;
        Map<String, String> validationFields;
        Map<Integer, String> oppStageNames;
        String errorNullString = ' ';
        Set<String> setErrorNullFields = new Set<String>();
        String errorLengthString = ' ';
        final String LENGTH_ERROR = ' All required text fields must have at least 10 characters.';
        final String NEW_BUSINESS = 'New Business';
        final Set<Id> salesRecordTypes = new Set<Id>{
            OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
            OpportunityHelper.RT_ID_SALES_OPPORTUNITY,
            OpportunityHelper.RT_ID_VAR_OPPORTUNITY
        };
        Map<Id, Decimal> convertedARRByOppIDs;
        Boolean doesUserProfileHaveValidationRules = false;
        Map<Id, OpportunityHelper.ValidationCategory> opptyValidationCategoryMap;
        Map<Id, Account> gpaAcctDetailsMap;
        Map<Id, Id> acctIDsbyOppIDs;
        Map<Id, Id> gpaValidationOppties;
        Set<Id> acctIDswithExistingClosedOpps;
        Map<Id, List<CampaignInfluence>> opptyCampaignMap;
        Boolean doesUserProfileHasGPAValidation = false;

        override public void handle() {

            if (Trigger.isUpdate && isChangeOrderFlow) {
                return;
            }

            Feature_Toggle__c ft = Feature_Toggle__c.getInstance();
            if (ft.Opportunity_Stage_Flow_Validations__c) {
                stcValidationv2 = false;
                prepareSupportingData();
                for (Opportunity opp : (List<Opportunity>) Trigger.new) {
                    Opportunity oldOpp = (Opportunity) Trigger.oldMap.get(opp.Id);
                    if (isChangedField(opp, Opportunity.StageName)) {
                        if (opp.Type == null && salesRecordTypes.contains(opp.RecordTypeId)) {
                            opp.addError('Opportunity Type shouldn\'t be empty. Please populate it');
                            continue;
                        }
                        if (!gpaValidationOppties.isEmpty() && gpaValidationOppties.containsKey(opp.Id)) {
                            String result = OpportunityHelper.CheckIfOpportunityGPAAdherent(gpaAcctDetailsMap.get(opp.AccountId).SIA_Information__c,
                                                                                    opptyCampaignMap.get(opp.Id));
                            if (!result.equals(OpportunityHelper.SUCCESS_MSG)) {
                                opp.addError(result);
                                continue;
                            }
                        }
                        if (isOpptyEligibleForLegacySTCValidation(opp)) {
                            //ITEA-760 START New STC Validation
                            String oppOwnerRole = ownerNamesByOppsId.get(opp.Id);
                            Boolean isUK = oppOwnerRole != null && oppOwnerRole.endsWithIgnoreCase('UK');
                            Decimal oppEARR = oldOpp.Estimated_12M_Total_Pipeline__c;
                            String stageName = opp.StageName;
                            if (isNameSuitable(oppOwnerRole, new List<String>{
                                roleNames.get('MAJO')
                            })
                                || isNameSuitable(oppOwnerRole, new List<String>{
                                roleNames.get('ENTERP')
                            })
                                || isNameSuitable(oppOwnerRole, new List<String>{
                                roleNames.get('ENTERUK')
                            })
                                || isNameSuitable(oppOwnerRole, new List<String>{
                                roleNames.get('MID')
                            })) {
                                stcValidationv2 = true;
                            }
                            if (stcValidationv2) {
                                if (oppOwnerRole != null && oppEARR != null) {
                                    if ((isNameSuitable(oppOwnerRole, new List<String>{
                                        roleNames.get('MAJO')
                                    }) && oppEARR >= 75000)
                                        || (isNameSuitable(oppOwnerRole, new List<String>{
                                        roleNames.get('MAJO')
                                    }) && oppEARR >= 50000 && isUK)
                                        || (isNameSuitable(oppOwnerRole, new List<String>{
                                        roleNames.get('ENTERP')
                                    }) && oppEARR >= 50000 && isUK)
                                        || (isNameSuitable(oppOwnerRole, new List<String>{
                                        roleNames.get('ENTERUK')
                                    }) && oppEARR >= 50000)
                                        || (isNameSuitable(oppOwnerRole, new List<String>{
                                        roleNames.get('ENTERP')
                                    }) && oppEARR >= 200000)
                                        || (isNameSuitable(oppOwnerRole, new List<String>{
                                        roleNames.get('MID')
                                    }) && oppEARR >= 30000)) {
                                        if (stageName == '2. Problem') {
                                            checkAllValidations(opp, false, 2);
                                        } else if (stageName == '3. Solution') {
                                            checkAllValidations(opp, false, 3);
                                        } else if (stageName == '4. Proof') {
                                            checkAllValidations(opp, false, 4);
                                        }
                                        checkAllErrors(opp);
                                    }
                                }
                            }
                            //END New STC Validation
                            else {
                                if (ownerNamesByOppsId.get(opp.Id) != null
                                    && isNameSuitable(ownerNamesByOppsId.get(opp.Id),
                                    new List<String>{
                                        roleNames.get('ENTER')
                                    })) {
                                    if (opp.Type != null && opp.Type.equals(NEW_BUSINESS)) {
                                        checkAllValidations(opp, false, 1);
                                        checkAllErrors(opp);
                                    }
                                } else {
                                    if (quotesByOppsId.get(opp.Id) != null
                                        && quotesByOppsId.get(opp.Id) >= 1000) {
                                        if (ownerNamesByOppsId.get(opp.Id) != null
                                            && isNameSuitable(ownerNamesByOppsId.get(opp.Id),
                                            new List<String>{
                                                roleNames.get('SMALL')
                                            })
                                            && opp.Type != null && opp.Type.equals(NEW_BUSINESS)) {
                                            checkAllValidations(opp, false, 4);
                                            checkAllErrors(opp);
                                        }
                                    } else if (quotesByOppsId.get(opp.Id) != null
                                        && quotesByOppsId.get(opp.Id) >= 750) {
                                        checkAllValidations(opp, true, 2);
                                        checkAllErrors(opp);
                                    } else {
                                        if (quotesByOppsId.get(opp.Id) != null
                                            && quotesByOppsId.get(opp.Id) >= 350
                                            && ownerNamesByOppsId.get(opp.Id) != null
                                            && isNameSuitable(ownerNamesByOppsId.get(opp.Id),
                                            new List<String>{
                                                roleNames.get('SOH')
                                            })
                                            && opp.Type != null && opp.Type.equals(NEW_BUSINESS)) {
                                            checkAllValidations(opp, false, 3);
                                            checkAllErrors(opp);
                                        }
                                    }
                                }
                            }
                        }
                        validateOpportunityStagesForBGInfoWinLossFields(opp);

                        // B-7164 Restrict re-opening downgraded/closed won Opportunities
                        Boolean userCanReOpenOptys = FeatureManagement.checkPermission(CustomPermissionHelper.PERMISSION_RE_OPEN_OPPORTUNITIES);
                        if (ft.Restrict_Re_Opening_Opty__c && !userCanReOpenOptys) {
                            if (isChangedFieldFrom(opp, Opportunity.StageName, OpportunityHelper.STAGE_NAME_DOWNGRADED)) {
                                opp.addError('You can\'t reopen Downgraded Opportunity. Please create new Opportunity');
                            }
                            if (isChangedFieldFrom(opp, Opportunity.StageName, OpportunityHelper.STAGE_NAME_CLOSED_WON)) {
                                opp.addError('You can\'t reopen Closed Won Opportunity. Please create new Opportunity');
                            }
                        }
                    }
                }
            }
        }

        /**
         * As part of QTC-1057, the below validation is put in place
         **/
         private void validateOpportunityStagesForBGInfoWinLossFields(Opportunity opp) {
            OpportunityHelper.ValidationCategory valCategory = opptyValidationCategoryMap.get(opp.Id);
            if(doesUserProfileHaveValidationRules &&  valCategory != OpportunityHelper.ValidationCategory.GSP_VALIDATION) {
                List<String> missedFields = OpportunityStageValidator.getMissingFieldLabelsForGivenStage(opp, convertedARRByOppIDs.get(opp.Id), valCategory);
                if (missedFields != null && !missedFields.isEmpty()) {
                    opp.addError(generateRequiredFieldErrorMsg(missedFields));
                }
            }
        }

        private Boolean isOpptyEligibleForLegacySTCValidation(Opportunity opp) {
            Boolean isValidOppty = false;
            OpportunityHelper.ValidationCategory valCategory = opptyValidationCategoryMap.get(opp.Id);
            if (valCategory == OpportunityHelper.ValidationCategory.GSP_VALIDATION) {
                isValidOppty = true;
            } else if (!opp.Type.equals(NEW_BUSINESS)) {
                isValidOppty = true;
            }
            return isValidOppty;
        }

        private void prepareSupportingData() {
            oppsIds = new Set<Id>();
            userIdsByOppIds = new Map<Id, Id>();
            ownerNamesByOppsId = new Map<Id, String>();
            quotesByOppsId = new Map<Id, Decimal>();
            convertedARRByOppIDs = new Map<Id, Decimal>();
            opptyValidationCategoryMap = new Map<Id, OpportunityHelper.ValidationCategory>();
            acctIDsbyOppIDs = new Map<Id, Id>();
            gpaAcctDetailsMap = new Map<Id, Account>();
            opptyCampaignMap = new Map<Id, List<CampaignInfluence>>();
            gpaValidationOppties = new Map<Id, Id>();
            acctIDswithExistingClosedOpps = new Set<Id>();
            validationFields = new Map<String, String>{
                'CUR' => 'STC_Current_Situation__c',
                'MAK' => 'STC_Decision_Making__c',
                'PROB' => 'STC_Problems__c',

                'IDE' => 'STC_Ideal_Situation__c',
                'DISC' => 'Discovery_Next_Steps__c',

                'LAND' => 'STC_Competitive_Landscape__c',
                'MUT' => 'Mutual_Plan__c',
                'RCE' => 'RC_Executive_Alignment__c',
                'CCC' => 'CC_Competitor_s__c',
                'VCO' => 'Video_Competition__c',
                'UCI' => 'UCaaS_Incumbent_s__c',
                'CCI' => 'CC_Incumbent_s__c',
                'VIN' => 'Video_Incumbent__c',
                'IRI' => 'Identified_Risks__c',
                'MON' => 'Monthly_Cost_of_Delay__c',
                'KDR' => 'KDR__c',
                'RCV' => 'Reason_for_not_needing_RCV__c '
            };
            roleNames = new Map<String, String>{
                'SIGN' => 'UK - Signature',
                'FARM' => 'Farming -',
                'FMID' => 'Farming Mid Market -',
                'SMB' => 'Farming SMB -',
                'UK' => 'Farming UK -',
                'MAJ' => 'Majors -',
                'MAJO' => 'Majors',
                'MID' => 'Mid Market -',
                'SMALL' => 'Small Business -',
                'ENTER' => 'Enterprise -',
                'SOH' => 'SOHO -',
                'ENTERP' => 'Enterprise',
                'ENTERUK' => 'Enterprise UK',
                'SOH' => 'SOHO -',
                'UKK' => 'UK'
            };
            oppStageNames = new Map<Integer, String>{
                2 => '2. Problem',
                3 => '3. Solution',
                4 => '4. Proof',
                5 => '5. Agreement',
                6 => '6. Order',
                7 => '7. Closed Won'
            };

            doesUserProfileHaveValidationRules = OpportunityHelper.doesUserProfileHaveValidationRules();
            doesUserProfileHasGPAValidation = OpportunityHelper.doesUserProfileHaveGPAValidation();

            for (Opportunity opp : (List<Opportunity>) Trigger.new) {
                if (isChangedField(opp, Opportunity.StageName)) {
                    oppsIds.add(opp.Id);
                    if (opp.OwnerId != null) {
                        userIdsByOppIds.put(opp.Id, opp.OwnerId);
                    }
                    if (doesUserProfileHasGPAValidation
                         && opp.AccountId != null
                         && (OpportunityHelper.STAGE_NAMES_CLOSED.contains(opp.StageName) || opp.StageName == OpportunityHelper.STAGE_NAME_ORDER)
                         && opp.Type == NEW_BUSINESS) {
                        acctIDsbyOppIDs.put(opp.Id, opp.AccountId);
                    }
                }
            }
            opptyValidationCategoryMap = OpportunityHelper.getOpportunityValidationCategory((List<Opportunity>) Trigger.new);
            if (!oppsIds.isEmpty()) {
                for (User us : [
                    SELECT Id, UserRole.Name
                    FROM User
                    WHERE Id IN :userIdsByOppIds.values()
                ]) {
                    for (Id oppId : userIdsByOppIds.keySet()) {
                        if (userIdsByOppIds.get(oppId) == us.Id) {
                            ownerNamesByOppsId.put(oppId, us.UserRole.Name);
                        }
                    }
                }
                Id saleQuoteRecordTypeId = Schema.SObjectType.Quote
                    .getRecordTypeInfosByName()
                    .get('Sales Quote')
                    .getRecordTypeId();
                for (Quote q : [
                    SELECT OpportunityId, Monthly_Recurring_Revenue__c
                    FROM Quote
                    WHERE OpportunityId IN :oppsIds
                    AND isPrimary__c = TRUE
                    AND RecordTypeId = :saleQuoteRecordTypeId
                ]) {
                    quotesByOppsId.put(q.OpportunityId, q.Monthly_Recurring_Revenue__c);
                }

                for (AggregateResult objAggregateResult : [
                    SELECT Id OppID, SUM(Estimated_12M_Total_Pipeline__c) ConvertedARR
                    FROM opportunity
                    WHERE id = :oppsIds
                    GROUP BY Id
                ])  {
                    convertedARRByOppIDs.put((ID)objAggregateResult.get('OppID'), (Decimal)objAggregateResult.get('ConvertedARR'));
                }

                if (!acctIDsbyOppIDs.isEmpty()) {
                    for (Account acc : [
                        SELECT Id, GPA_Account__c, SIA_Information__c
                        FROM Account
                        WHERE GPA_Account__c = true AND Id IN :acctIDsbyOppIDs.values()
                    ]) {
                        gpaAcctDetailsMap.put(acc.id, acc);
                    }

                    for (ID oppID : acctIDsbyOppIDs.keySet()) {
                        if (gpaAcctDetailsMap.containsKey(acctIDsbyOppIDs.get(oppID))) {
                            gpaValidationOppties.put(oppID, acctIDsbyOppIDs.get(oppID));
                        }
                    }

                    for (Opportunity opp : [SELECT Id, Type, AccountId
                                            FROM Opportunity
                                            WHERE Account.Id = :gpaValidationOppties.values() and
                                                Type = :NEW_BUSINESS and
                                                StageName in : OpportunityHelper.STAGE_NAMES_CLOSED and
                                                Id NOT in :gpaValidationOppties.keySet()
                    ]) {
                        acctIDswithExistingClosedOpps.add(opp.AccountId);
                    }

                    Set<Id> targettedOppIDsToBeRemoved = new Set<Id>();

                    for (ID opptyID : gpaValidationOppties.keySet()) {
                        if (acctIDswithExistingClosedOpps.contains(gpaValidationOppties.get(opptyID))) {
                            targettedOppIDsToBeRemoved.add(opptyID);
                        }
                    }

                    if (!targettedOppIDsToBeRemoved.IsEmpty()) {
                        for (ID opptyID : targettedOppIDsToBeRemoved) {
                            gpaValidationOppties.remove(opptyID);
                        }
                    }

                    for (Opportunity opp : [
                        SELECT Id, (SELECT Id, OpportunityId, Campaign.Id, Campaign.Name
                                    FROM CampaignInfluences)
                        FROM Opportunity
                        WHERE Id = :gpaValidationOppties.keyset()
                    ]) {
                        opptyCampaignMap.put(opp.Id, opp.CampaignInfluences);
                    }
                }
            }
        }

        private void checkAllValidations(Opportunity opp,
            Boolean isFullValidations,
            Integer stageNumber) {
            //ITEA-760 START New STC Validation
            if (stcValidationv2) {
                switch on (String) opp.StageName {
                    when '2. Problem' {
                        System.debug('Stage 2 Validation');
                        problemStageValidation(opp,
                            isFullValidations,
                            new List<String>{
                                validationFields.get('CUR'),
                                validationFields.get('MAK'),
                                validationFields.get('PROB')
                            },
                            new List<String>()
                        );
                    }
                    when '3. Solution' {
                        System.debug('Stage 3 Validation');
                        solutionStageValidation(opp,
                            isFullValidations,
                            new List<String>{
                                validationFields.get('CUR'),
                                validationFields.get('MAK'),
                                validationFields.get('PROB'),
                                validationFields.get('IDE')

                            },
                            new List<String>(),
                            stageNumber);
                    }
                    when '4. Proof' {
                        System.debug('Stage 4 Validation');
                        List<String> stage4List = new List<String>();
                        stage4List.add(validationFields.get('RCE'));
                        //stage4List.add(validationFields.get('UCI'));
                        stage4List.add(validationFields.get('CCC'));
                        stage4List.add(validationFields.get('VCO'));
                        //stage4List.add(validationFields.get('CCI'));
                        //stage4List.add(validationFields.get('VIN'));
                        stage4List.add(validationFields.get('KDR'));
                        stage4List.add(validationFields.get('IDE'));
                        if (opp.ROI_TCO_Business_Case__c != null) {
                            stage4List.add(validationFields.get('MON'));
                        }
                        proofStageValidation(opp,
                            isFullValidations,
                            new List<String>{
                                validationFields.get('MUT'),
                                validationFields.get('IRI')
                            },
                            stage4List,
                            stageNumber);
                    }
                }
            }
            //END New STC Validation
            else {
                switch on (String) opp.StageName {
                    when '2. Problem' {
                        problemStageValidation(opp,
                            isFullValidations,
                            new List<String>{
                                validationFields.get('CUR'),
                                validationFields.get('MAK'),
                                validationFields.get('PROB')
                            },
                            new List<String>()
                        );
                    }
                    when '3. Solution' {
                        switch on stageNumber {
                            when 1, 4 {
                                solutionStageValidation(opp,
                                    isFullValidations,
                                    new List<String>{
                                        validationFields.get('DISC')
                                    },
                                    new List<String>{
                                        validationFields.get('MUT')
                                    },
                                    stageNumber);
                            }
                            when 2 {
                                solutionStageValidation(opp,
                                    isFullValidations,
                                    new List<String>{
                                        validationFields.get('DISC'),
                                        validationFields.get('LAND')
                                    },
                                    new List<String>{
                                        validationFields.get('MUT')
                                    },
                                    stageNumber);
                            }
                            when 3 {
                                solutionStageValidation(opp,
                                    isFullValidations,
                                    new List<String>{
                                        validationFields.get('DISC')
                                    },
                                    new List<String>(),
                                    stageNumber);
                            }
                        }
                    }
                    when '4. Proof' {
                        switch on stageNumber {
                            when 1 {
                                proofStageValidation(opp,
                                    isFullValidations,
                                    new List<String>{
                                        validationFields.get('PROB'),
                                        validationFields.get('IDE')

                                    },
                                    new List<String>(),
                                    stageNumber);
                            }
                            when 2, 3, 4 {
                                proofStageValidation(opp,
                                    isFullValidations,
                                    new List<String>{
                                        validationFields.get('PROB'),
                                        validationFields.get('IDE')
                                    },
                                    new List<String>(),
                                    stageNumber);
                            }
                        }
                    }
                    when '5. Agreement' {
                        switch on stageNumber {
                            when 2, 3, 4 {
                                agreementStageValidation(opp,
                                    isFullValidations,
                                    new List<String>{
                                        validationFields.get('IDE')
                                    },
                                    new List<String>(),
                                    stageNumber);
                            }
                        }
                    }
                }
            }
        }

        private Boolean isNameSuitable(String ownerName, List<String> begins) {
            if (begins.size() > 0) {
                for (String str : begins) {
                    if (ownerName != null) {
                        if (ownerName.startsWith(str)) {
                            return true;
                        }
                    }
                }
            }
            return false;
        }

        private void extraValidation(Opportunity opp,
            List<String> checkLength,
            List<String> checkNull) {
            List<String> errorLengthFields = new List<String>();
            List<String> errorNullFields = new List<String>();
            if (!checkNull.isEmpty()) {
                for (String str : checkNull) {
                    if (opp.get(str) == null) {
                        errorNullFields.add(((SObject)Type.forName('Opportunity').newInstance())
                            .getSObjectType()
                            .getDescribe()
                            .fields
                            .getMap()
                            .get(str)
                            .getDescribe()
                            .getLabel());
                    }
                }
            }
            if (!checkLength.isEmpty()) {
                for (String str : checkLength) {
                    if (opp.get(str) == null || String.valueOf(opp.get(str)).length() < 10) {
                        errorLengthFields.add(((SObject)Type.forName('Opportunity').newInstance())
                            .getSObjectType()
                            .getDescribe()
                            .fields
                            .getMap()
                            .get(str)
                            .getDescribe()
                            .getLabel());
                    }
                }
            }
            if (!errorLengthFields.isEmpty() || !errorNullFields.isEmpty()) {
                generateErrorMessage(errorLengthFields, errorNullFields);
            }
        }

        private void generateErrorMessage(
            List<String> errorLengthFields,
            List<String> errorNullFields) {
            errorNullFields.addAll(errorLengthFields);
            if (!errorNullFields.isEmpty()) {
                for (Integer i = 0; i < errorNullFields.size(); i++) {

                    setErrorNullFields.add(errorNullFields.get(i));
                }
                /* for(String s : errorNullFields){
                     errorNullString += s + ', ';
                 }*/
            }
            if (!errorLengthFields.isEmpty()) {
                for (Integer i = 0; i < errorLengthFields.size(); i++) {
                    errorLengthString += errorLengthFields.get(i) + ', ';
                }
            }
        }

        private String generateRequiredFieldErrorMsg(List<String> requiredfields) {
            String errorMsg = '';
            for (String fieldName : requiredfields) {
                errorMsg += fieldName + ', ';
            }
            errorMsg = errorMsg.left(errorMsg.length() - 2);
            errorMsg += ' fields are required. ';
            return errorMsg;
        }

        private void checkAllErrors(Opportunity opp) {
            if (!setErrorNullFields.isEmpty()) {
                for (String s : setErrorNullFields) {
                    errorNullString += s + ', ';
                }
            }
            if (errorNullString.length() > 1) {
                errorNullString = errorNullString.left(errorNullString.length() - 2);
                errorNullString += ' fields are required. ';
            }
            if (errorLengthString.length() > 1) {
                errorLengthString = errorLengthString.left(errorLengthString.length() - 2);
                errorLengthString += ' must have at least 10 characters.';
            }
            if (errorLengthString.length() > 1
                || errorNullString.length() > 1) {
                opp.addError(errorNullString + LENGTH_ERROR);
            }
        }

        private void problemStageValidation(Opportunity opp,
            Boolean isFullValidation,
            List<String> checkLength,
            List<String> checkNull
        ) {
            if (isFullValidation) {
                List<String> roleNamesList = new List<String>{
                    roleNames.get('SIGN'),
                    roleNames.get('FARM'),
                    roleNames.get('FMID'),
                    roleNames.get('SMB'),
                    roleNames.get('UK')
                };
                if (opp.Type != null && opp.Type.equals(NEW_BUSINESS)) {
                    roleNamesList.addAll(new List<String>{
                        roleNames.get('MAJ'),
                        roleNames.get('MID'),
                        roleNames.get('SMALL')
                    });
                }
                if (ownerNamesByOppsId.get(opp.Id) != null
                    && isNameSuitable(ownerNamesByOppsId.get(opp.Id), roleNamesList)) {
                    extraValidation(opp, checkLength, checkNull);
                }
            } else {
                extraValidation(opp, checkLength, checkNull);
            }
        }

        private void solutionStageValidation(Opportunity opp,
            Boolean isFullValidation,
            List<String> checkLength,
            List<String> checkNull,
            Integer stageNumber) {
            checkPreviousValidations(opp, isFullValidation, stageNumber, 2);
            if (isFullValidation) {
                List<String> roleNamesList = new List<String>{
                    roleNames.get('SIGN'),
                    roleNames.get('FARM'),
                    roleNames.get('SMB'),
                    roleNames.get('UK')
                };
                if (opp.Type != null && opp.Type.equals(NEW_BUSINESS)) {
                    roleNamesList.addAll(new List<String>{
                        roleNames.get('MAJ'),
                        roleNames.get('MID'),
                        roleNames.get('SMALL')
                    });
                }
                if (ownerNamesByOppsId.get(opp.Id) != null
                    && isNameSuitable(ownerNamesByOppsId.get(opp.Id), roleNamesList)) {
                    checkLength.remove(1);
                    extraValidation(opp, checkLength, checkNull);
                } else {
                    if (ownerNamesByOppsId.get(opp.Id) != null
                        && isNameSuitable(ownerNamesByOppsId.get(opp.Id),
                        new List<String>{
                            roleNames.get('FMID')
                        })) {
                        extraValidation(opp, checkLength, checkNull);
                    }
                }
            } else {
                extraValidation(opp, checkLength, checkNull);
            }
        }

        private void proofStageValidation(Opportunity opp,
            Boolean isFullValidation,
            List<String> checkLength,
            List<String> checkNull,
            Integer stageNumber) {
            checkPreviousValidations(opp, isFullValidation, stageNumber, 3);
            if (isFullValidation) {
                if (ownerNamesByOppsId.get(opp.Id) != null
                    && isNameSuitable(ownerNamesByOppsId.get(opp.Id), new List<String>{
                    roleNames.get('SIGN'),
                    roleNames.get('MID'),
                    roleNames.get('FARM'),
                    roleNames.get('SMB'),
                    roleNames.get('UK'),
                    roleNames.get('MAJ'),
                    roleNames.get('SMALL'),
                    roleNames.get('FMID')
                })) {
                    extraValidation(opp, checkLength, checkNull);
                }
            } else {
                extraValidation(opp, checkLength, checkNull);
            }
        }

        private void agreementStageValidation(Opportunity opp,
            Boolean isFullValidation,
            List<String> checkLength,
            List<String> checkNull,
            Integer stageNumber) {
            checkPreviousValidations(opp, isFullValidation, stageNumber, 4);
            if (isFullValidation) {
                if (opp.Type != null && opp.Type.equals(NEW_BUSINESS)
                    && ownerNamesByOppsId.get(opp.Id) != null
                    && isNameSuitable(ownerNamesByOppsId.get(opp.Id),
                    new List<String>{
                        roleNames.get('FMID'),
                        roleNames.get('MAJ'),
                        roleNames.get('MID'),
                        roleNames.get('SMALL')
                    })) {
                    extraValidation(opp, checkLength, checkNull);
                }
            } else {
                extraValidation(opp, checkLength, checkNull);
            }
        }

        private void checkPreviousValidations(Opportunity opp,
            Boolean isFullValidation,
            Integer stageNumber,
            Integer currentStage) {
            opp.StageName = oppStageNames.get(currentStage);
            checkAllValidations(opp, isFullValidation, stageNumber);
            opp.StageName = oppStageNames.get(++currentStage);
        }
    }

    public class AutoGenerateOrders extends Triggers.TriggerHandlerBase {
        override public void handle() {

            if ((Trigger.isUpdate && isChangeOrderFlow)
                || !isAutoGenerateOrders
                || !Feature_Toggle__c.getInstance().AutogenerateOrders__c
            ) {
                return;
            }

            for (Opportunity opty : (Opportunity[]) Trigger.new) {
                if (isChangedFieldTo(opty, Opportunity.StageName, OpportunityHelper.STAGE_NAME_CLOSED_WON) ||
                    isChangedFieldTo(opty, Opportunity.StageName, OpportunityHelper.STAGE_NAME_CLOSED_SAVED) ||
                    isChangedFieldTo(opty, Opportunity.StageName, OpportunityHelper.STAGE_NAME_CLOSED_WINBACK)) {
                    GenerateOrders.processDataFuture(opty.Id, opty.NumberToBeRCMainNumber__c, opty.NumberToBeCCNumber__c);
                }
            }
        }
    }

    public class PerformWorkFlowActions extends Triggers.TriggerHandlerBase {
        override public void handle() {

            if (isSkipSecondRunWorkflowActions && ConvertLead.IS_LEAD_CONVERT_PROCESSING) {
                return;
            }

            if (Trigger.isUpdate && isChangeOrderFlow) {
                return;
            }

            Boolean isAllOpsChangeOrder = true;
            for (Opportunity o : (List<Opportunity>) Trigger.new) {
                if (o.Parent_Order__c == null) {
                    isAllOpsChangeOrder = false;
                    break;
                }
            }

            if (Trigger.isInsert && isAllOpsChangeOrder) {
                return;
            }

            Feature_Toggle__c featureToggle = Feature_Toggle__c.getInstance();

            if (featureToggle == null ||
                featureToggle.OpportunityWorkflowRulesAndProcToTrigger__c == null ||
                featureToggle.OpportunityWorkflowRulesAndProcToTrigger__c == false) {
                return;
            }

            Map<Id, Account> accountMap = getAccountMap((List<Opportunity>) Trigger.new);
            Set<Id> userIdSet = new Set<Id>();
            for (Account acc : accountMap.values()) {
                if (acc.Current_Owner__c != null) {
                    userIdSet.add(acc.Current_Owner__c);
                }
            }
            Map<Id, User> userIdToUserMap = UserHelper.getORQueryUsers(userIdSet);

            for (Opportunity opty : (List<Opportunity>) Trigger.new) {
                Account ac = accountMap.get(opty.AccountId);
                if (isChangedField(opty, Opportunity.RecordTypeId)) {
                    opty.ChangedFromRecordType__c = (String) oldValue(opty, Opportunity.RecordTypeName__c);
                }

                if (opty.Partner_ID__c != null &&
                    opty.RecordTypeName__c == OpportunityHelper.RT_NAME_VAR_OPPORTUNITY &&
                    ac != null && ac.Inside_Sales_Rep__c != null) {
                    opty.Inside_Sales_Rep__c = ac.Inside_Sales_Rep__c;
                }

                if (ac != null && ac.Current_Owner__c != null &&
                    opty.RecordTypeId == OpportunityHelper.RT_ID_SAVES_OPPORTUNITY) {
                    opty.Current_Owner_Email_Opportunity__c = userIdToUserMap.get(ac.Current_Owner__c).Email;
                }
            }
            if (Trigger.isBefore && ConvertLead.IS_LEAD_CONVERT_PROCESSING) {
                isSkipSecondRunWorkflowActions = true;
            }
        }
    }

    public class RecallApprovalRequests extends Triggers.TriggerHandlerBase {
        override public void handle() {
            if (accIdToQuotesOnAccountPendingApproval.isEmpty()) {
                return;
            }

            Set<Id> accIdsToProcess = new Set<Id>();
            for (Opportunity o : (List<Opportunity>) Trigger.new) {
                if (isChangedFieldToAnyString(o, Opportunity.StageName, OpportunityHelper.closedStagesSet)) {
                    accIdsToProcess.add(o.AccountId);
                }
            }

            List<Quote> quotesPendingApproval = new List<Quote>();
            for (Id accId : accIdsToProcess) {

                for (Quote q : accIdToQuotesOnAccountPendingApproval.get(accId)) {
                    if (QuoteHelper.isNeedSetQuoteInvalid(q, (List<Opportunity>) Trigger.new)) {
                        quotesPendingApproval.add(q);
                    }
                }
            }

            QuoteHelper.recallQuotesApprovals(quotesPendingApproval);
        }
    }

    public class GenerateAssistanceCases extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Set<Id> opptyForAssistanceIds = new Set<Id>();

            for (Opportunity opp : (List<Opportunity>) Trigger.new) {
                if (isChangedFieldToAnyString(opp, Opportunity.StageName, OpportunityHelper.closedStagesSet)) {
                    if (BooleanHelper.toBoolean(engageTerminationMapStatic.get(opp.Id))) {
                        opptyForAssistanceIds.add(opp.Id);
                    }
                }
            }

            // Sales Rep is prohibited to perform Sync WithNGBS by it's own. Create Case for him for Assistance
            if (!opptyForAssistanceIds.isEmpty()) {
                OpportunityHelper.generateAssistanceCases(opptyForAssistanceIds);
            }
        }
    }

    public class UnParentChildQuotes extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Set<Quote> downgradedQuotes = new Set<Quote>();
            for (Opportunity opp : (List<Opportunity>) Trigger.new) {
                if (isChangedFieldTo(opp, Opportunity.StageName, OpportunityHelper.STAGE_NAME_DOWNGRADED)) {
                    List<Quote> optyQuotes = OpportunityHelper.opptyToQuotesMapStatic.get(opp.Id);
                    if (optyQuotes != null) {
                        downgradedQuotes.addAll(optyQuotes);
                    }
                }
            }
            if (downgradedQuotes.size() == 0) {
                return;
            }
            List<Quote> childQuotes = new QuoteSelector()
                .selectChildQuotes(new List<Object>{
                    downgradedQuotes
                })
                .executeQuery();

            if (!childQuotes.isEmpty()) {
                OpportunityHelper.unParentChildQuotes(new Map<Id, Quote>(childQuotes).keySet());
            }
        }
    }

    public class CallSyncWithNGBSForLBOAccounts extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Set<Id> closedOpptyIds = new Set<Id>();
            for (Opportunity opp : (Opportunity[]) Trigger.new) {
                if (isChangedFieldTo(opp, Opportunity.StageName, OpportunityHelper.STAGE_NAME_CLOSED_WON) && opp.Is_Billing_Opportunity__c && !OpportunityHelper.isProServChangeOrderOpportunity(opp)) {
                    closedOpptyIds.add(opp.Id);
                }
            }

            if (closedOpptyIds.isEmpty()) {
                return;
            }

            Set<Id> quoteIdsForSync = new Set<Id>();
            Set<Id> masterQuoteIds = new Set<Id>();
            List<Quote> targetQuotes = (List<Quote>) new QuoteSelector()
                .selectLboQuotesByOppIdsForAutoSyncWithNGBS(closedOpptyIds)
                .executeQuery();

            populateChildQuoteIds(quoteIdsForSync, masterQuoteIds, targetQuotes);
            populateMasterQuoteIdsWithoutChilds(quoteIdsForSync, masterQuoteIds, targetQuotes);

            // Bulkification of this queueable job call is not possible without significant refactoring to the core methods
            // of the SyncWithNGBS class which would require decoupling data collection from these methods.
            // Our workflow always involves closing a single opportunity at a time, therefore it is acceptable
            // to execute queueable jobs within a for loop for simplicity and maintainability.
            for (Id quoteId : quoteIdsForSync) {
                SyncWithNGBSQueueable.enqueueAutoSyncWithNGBS(quoteId);
            }
        }

        private void populateChildQuoteIds(
            Set<Id> quoteIdsForSync,
            Set<Id> masterQuoteIds,
            List<Quote> targetQuotes
        ) {
            for (Quote qt : targetQuotes) {
                if (qt.MasterQuote__c != null) {
                    quoteIdsForSync.add(qt.Id);
                    masterQuoteIds.add(qt.MasterQuote__c);
                }
            }
        }

        private void populateMasterQuoteIdsWithoutChilds(
            Set<Id> quoteIdsForSync,
            Set<Id> masterQuoteIds,
            List<Quote> targetQuotes
        ) {
            for (Quote qt : targetQuotes) {
                if (qt.MasterQuote__c == null && !masterQuoteIds.contains(qt.Id)) {
                    quoteIdsForSync.add(qt.Id);
                }
            }
        }
    }

    public class ValidateLBOOpportunityOnClose extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Id> closedOpptyIds = new List<Id>();
            Map<Id, Id> oppQuoteIdsMap = new Map<Id, Id>();
            Map<Id, Quote> oppQuoteMap = new Map<Id, Quote>();
            Map<Id, List<QuoteLineItem>> oppQlisMap = new Map<Id, List<QuoteLineItem>>();
            Map<Id, Boolean> oppHasDeviceMap = new Map<Id, Boolean>();
            Map<Id, Boolean> oppHasNotCancelledProServQuote = new Map<Id, Boolean>();
            Map<Id, List<Cost_Center__c>> quoteCostCentersMap = new Map<Id, List<Cost_Center__c>>();
            List<QuoteLineItem> qlis = new List<QuoteLineItem>();
            Response res = new Response();
            for (Opportunity opp : (Opportunity[]) Trigger.new) {
                if (isChangedFieldTo(opp, Opportunity.StageName, OpportunityHelper.STAGE_NAME_ORDER) &&
                    opp.Is_Billing_Opportunity__c) {
                    closedOpptyIds.add(opp.Id);
                }
            }
            if (!closedOpptyIds.isEmpty()) {
                List<Opportunity> lboOpportunities = (List<Opportunity>) new OpportunitySelector()
                    .selectOpportunitiesOnCloseValidation(new List<Object>{
                        closedOpptyIds
                    })
                    .executeQuery();
                if (!lboOpportunities.isEmpty()) {
                    for (Opportunity opp : lboOpportunities) {
                        Quote primaryQuote;
                        for (Quote qt : opp.Quotes) {
                            if (qt.IsPrimary__c) {
                                primaryQuote = qt;
                            }
                        }
                        if (
                            !opp.Quotes.isEmpty() &&
                                BooleanHelper.toBoolean(primaryQuote?.Enabled_LBO__c) &&
                                BooleanHelper.toBoolean(primaryQuote?.IsSendOrderToNGBS__c) &&
                                (opp.Type == OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS || (opp.Type == OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS && opp.Account.Offer_Type__c == AccountHelper.OFFER_TYPE_POC))) {
                            oppQuoteIdsMap.put(opp.Id, primaryQuote?.Id);
                            oppQuoteMap.put(opp.Id, primaryQuote);
                            quoteCostCentersMap.put(primaryQuote?.Id, new List<Cost_Center__c>());
                            Boolean isProServQuotesNotCancelled = QuoteHelper.hasNonCancelledProServ(opp.Quotes);
                            oppHasNotCancelledProServQuote.put(opp.Id, isProServQuotesNotCancelled);

                        }
                    }
                }
            }

            if (!oppQuoteIdsMap.values().isEmpty()) {
                qlis = (List<QuoteLineItem>) new QuoteLineItemSelector()
                    .selectQuoteLineItemsByQuoteIdsForShipping(new List<Object>{
                        oppQuoteIdsMap.values()
                    })
                    .executeQuery();

                List<Cost_Center__c> costCenters = new CostCenterSelector()
                    .selectCostCentersByQuoteId(new List<Object>{
                        oppQuoteIdsMap.values()
                    })
                    .executeQuery();
                if (!costCenters.isEmpty()) {
                    for (Cost_Center__c cc : costCenters) {
                        if (quoteCostCentersMap.get(cc.Quote__c) != null && !quoteCostCentersMap.get(cc.Quote__c).isEmpty()) {
                            quoteCostCentersMap.get(cc.Quote__c).add(cc);
                        } else {
                            quoteCostCentersMap.put(cc.Quote__c, new List<Cost_Center__c>{
                                cc
                            });
                        }
                    }
                }

                for (QuoteLineItem qli : qlis) {
                    if (oppQuoteMap.get(qli.Quote.OpportunityId) != null && oppQuoteMap.get(qli.Quote.OpportunityId).Id == qli.QuoteId) {
                        BillingWrappers.QLIPackageInfo qliPackage = new BillingWrappers.QLIPackageInfo(qli.PackageInfo__c);
                        if (oppQlisMap.get(qli.Quote.OpportunityId) != null && !oppQlisMap.get(qli.Quote.OpportunityId).isEmpty()) {
                            oppQlisMap.get(qli.Quote.OpportunityId).add(qli);
                        } else {
                            oppQlisMap.put(qli.Quote.OpportunityId, new List<QuoteLineItem>{
                                qli
                            });
                        }
                        if (Product2Helper.SHIPPING_PHONES.contains(qliPackage.categoryPath) && !qli.Zero_Quantity__c && qli.Quantity > 0) {
                            oppHasDeviceMap.put(qli.Quote.OpportunityId, true);
                        }
                    }
                }
            }

            for (Opportunity opp : (Opportunity[]) Trigger.new) {
                if (oppQuoteIdsMap.get(opp.Id) != null &&
                    oppQuoteMap.get(opp.Id) != null &&
                    oppQlisMap.get(opp.Id) != null &&
                    !oppQlisMap.get(opp.Id).isEmpty() &&
                    oppHasDeviceMap.get(opp.Id) != null) {
                    if (!Schema.SObjectType.CustomAddress__c.isAccessible() || !Schema.SObjectType.CustomAddressAssignments__c.isAccessible()) {
                        opp.addError(CaseHelper.CASE_REASON_PERMISSION, false);
                    } else {
                        Validator shippingQuantityValidator = new QuoteValidator.QuantityShippingValidator(oppQuoteMap.get(opp.Id), oppQlisMap.get(opp.Id), true, oppHasNotCancelledProServQuote.get(opp.Id));
                        if (quoteCostCentersMap.get(oppQuoteMap.get(opp.Id).Id) != null && !quoteCostCentersMap.get(oppQuoteMap.get(opp.Id).Id).isEmpty()) {
                            Validator costCenterShippingQuantityValidator = new QuoteValidator.ShippingCostCenterValidator(oppQuoteMap.get(opp.Id), oppQlisMap.get(opp.Id), quoteCostCentersMap.get(oppQuoteMap.get(opp.Id).Id), oppHasNotCancelledProServQuote.get(opp.Id));
                            shippingQuantityValidator.setNextValidator(costCenterShippingQuantityValidator);
                        }
                        res = shippingQuantityValidator.validate(res);
                        if (!res.messages.isEmpty()) {
                            String errorMessages = res.messages[0].message + '<br/>' + res.messages[0].messageDetails + '<br/>';
                            opp.addError(errorMessages, false);
                        }
                    }
                }
            }
        }
    }

    public class ForecastedAmountsHelper extends Triggers.TriggerHandlerBase {
        private final Set<String> EARLY_APPLICABLE_STAGES = new Set<String>{
            OpportunityHelper.STAGE_NAME_QUALIFY,
            OpportunityHelper.STAGE_NAME_PROBLEM
        };
        private final Set<String> LATE_APPLICABLE_STAGES = new Set<String>{
            OpportunityHelper.STAGE_NAME_ORDER,
            OpportunityHelper.STAGE_NAME_CLOSED_WON
        };

        override public void handle() {
            Map<Id, Opportunity> opportunitiesToProcessMap = OpportunityHelper.filterOpportunitiesToCalculatePipelineTotals((List<Opportunity>) Trigger.new);
            List<Opportunity> opportunitiesToProcess = opportunitiesToProcessMap.values();

            Map<Id, Opportunity> unprocessedOppsMap = new Map<Id, Opportunity>();

            for (Id opportunityId : opportunitiesToProcessMap.keySet()) {
                if (!processedForecastedAmountsOppIds.contains(opportunityId)) {
                    unprocessedOppsMap.put(opportunityId, opportunitiesToProcessMap.get(opportunityId));
                }
            }

            if (!unprocessedOppsMap.isEmpty()) {
                // 1. PERFORM VALIDATIONS
                for (Opportunity opp : unprocessedOppsMap.values()) {
                    if (skipForecastValidations || ConvertLead.isLeadBeingConverted) {
                        continue;
                    }

                    Opportunity oldOpp = Trigger.oldMap == null ? null : (Opportunity) Trigger.oldMap.get(opp.Id);
                    OpportunityPipelineHelper.validateMaxUsersNotExceeded(opp, oldOpp);

                    if (Trigger.isUpdate) {
                        if (LATE_APPLICABLE_STAGES.contains(opp.StageName) && !QuoteTriggerHelper.quoteTriggerExecuted) {
                            OpportunityPipelineHelper.validateQuoteBasedEstimatesWereNotChangedManually(opp, oldOpp);
                        }
                        OpportunityPipelineHelper.validateUsersUnchangedAfterOppClosed(opp, oldOpp);
                        OpportunityPipelineHelper.validateAdminAndSalesProfilesCannotChangeForecastedUsers(opp, oldOpp);
                    }
                    OpportunityPipelineHelper.enforceNonNullValues(opp);
                    OpportunityPipelineHelper.performBrandSpecificValidationsAndDefaults(opp, oldOpp);
                }

                // 2. SET "SOURCE" FIELDS
                for (Opportunity opp : unprocessedOppsMap.values()) {
                    Opportunity oldOpp = Trigger.oldMap == null ? null : (Opportunity) Trigger.oldMap.get(opp.Id);
                    if (opp.StageName == OpportunityHelper.STAGE_NAME_DOWNGRADED
                        && oldOpp != null
                        && oldOpp.StageName == OpportunityHelper.STAGE_NAME_DOWNGRADED) {
                        continue;
                    }
                    if (EARLY_APPLICABLE_STAGES.contains(opp.StageName)) {
                        if (Trigger.isInsert) {
                            OpportunityPipelineHelper.populateSourcesForNewOppty(opp);
                        } else if (Trigger.isUpdate) {
                            OpportunityPipelineHelper.enforceUserBasedSources(opp);
                        }
                    } else if (LATE_APPLICABLE_STAGES.contains(opp.StageName)
                                && !(OpportunityHelper.isGSPBrand(opp)
                                && OpportunityHelper.opptyToQuotesMapStatic.get(opp.Id) == null)) {
                        OpportunityPipelineHelper.enforceQuoteAmountsSources(opp, true);
                    } else if (Trigger.isUpdate && opp.StageName != OpportunityHelper.STAGE_NAME_DOWNGRADED
                                && !(OpportunityHelper.isGSPBrand(opp)
                                && OpportunityHelper.opptyToQuotesMapStatic.get(opp.Id) == null)) {
                        OpportunityPipelineHelper.enforceQuoteAmountsSources(opp, false);
                    }
                    if (Trigger.isUpdate && !ConvertLead.IS_LEAD_CONVERT_PROCESSING && !QuoteTriggerHelper.quoteTriggerExecuted) {
                        OpportunityPipelineHelper.detectOverridesAndPopulateSources(opp, oldOpp);
                    }

                }

                Set<Id> oppIds = Trigger.isInsert ? new Set<Id>() : (Set<Id>) unprocessedOppsMap.keySet();
                Map<Id, List<Quote>> quotesByOppId = OpportunityMethods.fetchOpportunityQuotes(oppIds);
                // 3. CALCULATE PIPELINES
                OpportunityPipelineHelper.performCalculations(unprocessedOppsMap.values(), quotesByOppId);
                // 4. CALCULATE OPPTY FIELDS BY QLIS
                OpportunityTotals.computeTotalFeesMRR(unprocessedOppsMap.values(), quotesByOppId);
                processedForecastedAmountsOppIds.addAll(oppIds);
            }
        }
    }
    @testVisible
    private class CLMDocumentData {
        public String attachmentId;
        public String folderId;
        public String workflowId;
        private String attachmentName;
        public Blob attachmentBody;

        public CLMDocumentData(String attachmentId, String folderId, String workflowId) {
            this.attachmentId = attachmentId;
            this.folderId = folderId;
            this.workflowId = workflowId;
        }

        public String getAttachmentName() {
            return this.attachmentName;
        }
        public void setAttachmentName(String attachmentName) {
            if (String.isBlank(attachmentName)) {
                this.attachmentName = '';
            }

            if (attachmentName.containsAny('\\/:*?')) {
                attachmentName = attachmentName
                    .replace('\\', '')
                    .replace('/', '')
                    .replace(':', '')
                    .replace('*', '')
                    .replace('?', '');
            }
            this.attachmentName = attachmentName;
        }
    }


    @TestVisible
    private static Map<String, String> docusignCLMSettingsMap {
        get {
            if (docusignCLMSettingsMap == null) {
                Organization org = (Organization) new OrganizationSelector()
                    .selectOrg()
                    .setQueryCaching(true)
                    .executeQuery()
                    .get(0);

                docusignCLMSettingsMap = new Map<String, String>();
                List<DocuSignRESTSettings__mdt> settings = DocuSignRESTSettings__mdt.getAll().values();
                for (DocuSignRESTSettings__mdt setting : settings) {
                    if (!org.IsSandbox && setting.DeveloperName.startsWithIgnoreCase('Production_')) {
                        docusignCLMSettingsMap.put(
                            setting.DeveloperName.removeStartIgnoreCase('Production_'),
                            setting.Value__c
                        );
                    } else if (org.IsSandbox && setting.DeveloperName.startsWithIgnoreCase('Sandbox_')) {
                        docusignCLMSettingsMap.put(
                            setting.DeveloperName.removeStartIgnoreCase('Sandbox_'),
                            setting.Value__c
                        );
                    }
                }
            }
            return docusignCLMSettingsMap;
        }
        set;
    }

    @Future(Callout=true)
    private static void uploadDocsToCLM(String jsonData) {

        if (String.isBlank(jsonData)) {
            return;
        }

        try {

            validateDocusignCLMMetadata();

            String apiAccountId = docusignCLMSettingsMap.get('DSAccountID');
            String iss = docusignCLMSettingsMap.get('RequestIntegratorKey');
            String sub = docusignCLMSettingsMap.get('DSUserName');
            String pKey = docusignCLMSettingsMap.get('RequestPrivateKey');
            String aud = docusignCLMSettingsMap.get('RequestAuthDomain');
            String dataCenter = docusignCLMSettingsMap.get('DataCenter');
            String version = docusignCLMSettingsMap.get('ApiVersion');
            String scope = 'signature impersonation spring_read spring_write';

            String apiEndpoint = 'https://api' + dataCenter + '.springcm.com/' + version + '/' + apiAccountId;

            DSAPIUserAuthenticator auth = new DSAPIUserAuthenticator(
                apiAccountId,
                iss,
                aud,
                sub,
                pKey,
                dataCenter,
                version,
                scope
            );

            SpringCMService svc = new SpringCMService(auth);

            List<CLMDocumentData> clmData = (List<CLMDocumentData>) JSON.deserialize(jsonData, List<CLMDocumentData>.class);

            for (CLMDocumentData data : clmData) {

                CLMFolderRequest folderReq = svc.GetFolderById(data.folderId);
                CLMFolder fld = folderReq.getFolder();

                Map<String, Blob> documentsToStore = new Map<String, Blob>{
                    data.getAttachmentName() => data.attachmentBody
                };

                CLMDocument uploadDoc = svc.UploadDocuments(fld, documentsToStore, '');

                if (uploadDoc != null) {

                    // signalWorkflow
                    CLMWorkflow wfParam = new CLMWorkflow();
                    wfParam.Href = apiEndpoint + '/workflows/' + data.workflowId;
                    wfParam.Name = 'Test Workflow';
                    wfParam.Params = '<doc><name>' + uploadDoc.Name + '</name></doc>';
                    CLMDocumentItems docs = new CLMDocumentItems();
                    docs.Items = new List<CLMDocument>{
                        uploadDoc
                    };
                    wfParam.WorkflowDocuments = docs;
                }
            }
        } catch (Exception ex) {
            PlatformLog.logException('UploadDocumentsToCLM', ex);
        }
    }

    private static void validateDocusignCLMMetadata() {

        Boolean isEmptyApiAccountId = !docusignCLMSettingsMap.containsKey('DSAccountID') ||
            String.isBlank(docusignCLMSettingsMap.get('DSAccountID'));

        Boolean isEmptyIntegrationKey = !docusignCLMSettingsMap.containsKey('RequestIntegratorKey') ||
            String.isBlank(docusignCLMSettingsMap.get('RequestIntegratorKey'));

        Boolean isEmptyUserId = !docusignCLMSettingsMap.containsKey('DSUserName') ||
            String.isBlank(docusignCLMSettingsMap.get('DSUserName'));

        Boolean isEmptyPrivateKey = !docusignCLMSettingsMap.containsKey('RequestPrivateKey') ||
            String.isBlank(docusignCLMSettingsMap.get('RequestPrivateKey'));

        Boolean isEmptyRequestAuthDomain = !docusignCLMSettingsMap.containsKey('RequestAuthDomain') ||
            String.isBlank(docusignCLMSettingsMap.get('RequestAuthDomain'));

        Boolean isEmptyDataCenter = !docusignCLMSettingsMap.containsKey('DataCenter') ||
            String.isBlank(docusignCLMSettingsMap.get('DataCenter'));

        Boolean isEmptyApiVersion = !docusignCLMSettingsMap.containsKey('ApiVersion') ||
            String.isBlank(docusignCLMSettingsMap.get('ApiVersion'));

        if (isEmptyApiAccountId || isEmptyIntegrationKey || isEmptyUserId ||
            isEmptyPrivateKey || isEmptyRequestAuthDomain || isEmptyDataCenter || isEmptyApiVersion) {
            AquivaHelper.throwAquivaException(EMPTY_METADATA_ERROR_MESSAGE);
        }
    }

    public class SetCLMAccess extends Triggers.TriggerHandlerBase {

        override public void handle() {
            OpportunityHelper.setOpptyCLMEnable((Opportunity[]) Trigger.new);
        }
    }

    public static Map<Id, Account> getAccountMap(List<Opportunity> opportunityList) {
        Map<Id, Account> accountMap = new Map<Id, Account>();

        if (opportunityList == null || opportunityList.isEmpty()) {
            return accountMap;
        }

        Set<Id> accIdSet = new Set<Id>();

        for (Opportunity opp : opportunityList) {
            accIdSet.add(opp.AccountId);
        }

        if (!accountMapStatic.keySet().containsAll(accIdSet)) {
            List<Account> accountList = (List<Account>) new AccountSelector()
                .selectAccountsForOpportunityTrigger(accIdSet)
                .executeQuery();
            accountMap = new Map<Id, Account>(accountList);
            accountMapStatic.putAll(accountMap);
        } else {
            accountMap = new Map<Id, Account>(accountMapStatic);
        }

        return accountMap;
    }

    public class SyncPaymentInfo extends Triggers.TriggerHandlerBase {
        override public void handle() {
            if (!Feature_Toggle__c.getInstance().Enable_Direct_Debit_as_a_payment_method__c) {
                return;
            }

            List<Opportunity> closedOppList = new List<Opportunity>();
            for (Opportunity opp : (List<Opportunity>) Trigger.new) {
                Boolean isSavesDownSell = OpportunityHelper.isSavesDownSellOpportunity(opp);
                Boolean isEngageTermination = BooleanHelper.toBoolean(engageTerminationMapStatic.get(opp.Id));
                Boolean isLegacyBrand = (OpportunityHelper.isBTBusinessOpportunity(opp)
                                        || OpportunityHelper.isTelusOpportunity(opp)
                                        || OpportunityHelper.BizMergeBrandExclusion(opp));
                Boolean isClosedWon = isChangedFieldTo(opp, Opportunity.StageName, OpportunityHelper.STAGE_NAME_CLOSED_WON);
                if (isClosedWon && !isEngageTermination && !isSavesDownSell && !isLegacyBrand) {
                    closedOppList.add(opp);
                }
            }

            if (closedOppList.isEmpty()) {
                return;
            }

            List<PaymentInfoSync.PaymentInfoParams> result = new List<PaymentInfoSync.PaymentInfoParams>();

            Map<Id, Account> accountMap = getAccountMap(closedOppList);
            Map<Id, Quote> primaryQuoteMap = getPrimaryQuoteMap(closedOppList);

            for (Opportunity opp : closedOppList) {
                if(!OpportunityHelper.isGSPBrand(opp)
                || (OpportunityHelper.isGSPBrand(opp) && OpportunityHelper.opptyToQuotesMapStatic.get(opp.Id) != null)){
                Account acc = accountMap.get(opp.AccountId);
                Quote qt = primaryQuoteMap.get(opp.Id);
                if (qt == null) {
                    AquivaHelper.throwAquivaException('Can not get the primary quote for SyncPaymentInfo');
                }
                if (isChangedFieldTo(opp, Opportunity.StageName, OpportunityHelper.STAGE_NAME_CLOSED_WON) && String.isNotBlank(acc.Billing_ID__c)) {
                    result.add(
                        new PaymentInfoSync.PaymentInfoParams(
                            acc.Billing_ID__c,
                            acc.Id,
                            qt.PaymentMethod__c,
                            null,
                            qt
                        ));
                }
                }
            }

            if (!result.isEmpty()) {
                QueueableBase.enqueJob('PaymentInfoSync', result);
            }
        }
    }

    private static Map<Id, Quote> getPrimaryQuoteMap(List<Opportunity> opportunityList) {
        Map<Id, Quote> result = new Map<Id, Quote>();
        for (Opportunity opp : opportunityList) {
            if(!OpportunityHelper.isGSPBrand(opp)
                || (OpportunityHelper.isGSPBrand(opp) && OpportunityHelper.opptyToQuotesMapStatic.get(opp.Id) != null)){
                if (OpportunityHelper.opptyToQuotesMapStatic.get(opp.Id) == null) {
                    AquivaHelper.throwAquivaException('Can not get the list of quotes for getPrimaryQuoteMap');
                }
                    for (Quote qt : OpportunityHelper.opptyToQuotesMapStatic.get(opp.Id)) {
                        if (qt.isPrimary__c) {
                            result.put(opp.Id, qt);
                        }
                    }
            }
        }
        return result;
    }

    public class UpdateContactLogic extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Contact_Update_ClosedWon_Opp__e> eventList = new List<Contact_Update_ClosedWon_Opp__e>();
            Map<Id, Id> newPrimaryOppCon = new Map<Id, Id>();
            Map<Id, Id> oldPrimaryOppCon = new Map<Id, Id>();
            for (Opportunity opp : (List<Opportunity>) Trigger.new) {
                if (
                    isChangedFieldTo(opp, Opportunity.StageName, OpportunityHelper.STAGE_NAME_CLOSED_WON) ||
                        isChangedFieldTo(opp, Opportunity.StageName, OpportunityHelper.STAGE_NAME_DOWNGRADED)
                ) {
                    eventList.add(
                        new Contact_Update_ClosedWon_Opp__e(
                            Opportunity_Id__c = opp.Id,
                            Contact_Id__c = opp.Primary_Opportunity_Contact__c
                        )
                    );
                }
                if (isChangedField(opp, Opportunity.Primary_Opportunity_Contact__c)) {
                    if (((Opportunity) Trigger.oldMap.get(opp.Id)).Primary_Opportunity_Contact__c != null) {
                        oldPrimaryOppCon.put(
                            opp.Id,
                            ((Opportunity) Trigger.oldMap.get(opp.Id)).Primary_Opportunity_Contact__c
                        );
                        eventList.add(
                            new Contact_Update_ClosedWon_Opp__e(
                                Contact_Id__c = ((Opportunity) Trigger.oldMap.get(opp.Id)).Primary_Opportunity_Contact__c
                            )
                        );
                    }
                    if (opp.Primary_Opportunity_Contact__c != null) {
                        newPrimaryOppCon.put(opp.Id, opp.Primary_Opportunity_Contact__c);
                        eventList.add(
                            new Contact_Update_ClosedWon_Opp__e(
                                Opportunity_Id__c = opp.Id,
                                Contact_Id__c = opp.Primary_Opportunity_Contact__c,
                                Is_Primary_Contact_Update__c = true
                            )
                        );
                    }
                }
            }
            if (!TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE && (!oldPrimaryOppCon.isEmpty() || !newPrimaryOppCon.isEmpty())) {
                updateOppConRoles(newPrimaryOppCon, oldPrimaryOppCon);
            }
            if (!eventList.isEmpty()) {
                PlatformEvents.publishPlatformEvent(eventList, 'UpdateContactLogic');
            }
        }

        private void updateOppConRoles(Map<Id, Id> newOppConMap, Map<Id, Id> oldOppConMap) {
            List<OpportunityContactRole> oppConRolesToUpsert = new List<OpportunityContactRole>();
            Set<Id> contactIds = new Set<Id>(newOppConMap.values());
            contactIds.addAll(oldOppConMap.values());
            Set<Id> opportunityIds = new Set<Id>(newOppConMap.keySet());
            opportunityIds.addAll(oldOppConMap.keySet());
            Map<String, OpportunityContactRole> oppConRoleMap = new Map<String, OpportunityContactRole>();
            for (
                OpportunityContactRole oppConRole : (List<OpportunityContactRole>) new OpportunityContactRoleSelector()
                .selectOppConRolesByListConIdsAndListOppIds(new List<Object>{
                    opportunityIds, contactIds
                })
                .executeQuery()
            ) {
                oppConRoleMap.put((String) oppConRole.OpportunityId + (String) oppConRole.ContactId, oppConRole);
            }
            for (Id oppId : opportunityIds) {
                if (oldOppConMap.containsKey(oppId)) {
                    String oldOppConKey = (String) oppId + (String) oldOppConMap.get(oppId);
                    if (oppConRoleMap.containsKey(oldOppConKey)) {
                        oppConRoleMap.get(oldOppConKey).IsPrimary = false;
                        oppConRoleMap.get(oldOppConKey).Role = 'Other';
                        oppConRolesToUpsert.add(oppConRoleMap.get(oldOppConKey));
                    }
                }
                if (newOppConMap.containsKey(oppId)) {
                    String newOppConKey = (String) oppId + (String) newOppConMap.get(oppId);
                    if (oppConRoleMap.containsKey(newOppConKey)) {
                        oppConRoleMap.get(newOppConKey).IsPrimary = true;
                        oppConRoleMap.get(newOppConKey).Role = 'Signatory';
                        oppConRolesToUpsert.add(oppConRoleMap.get(newOppConKey));
                    } else {
                        oppConRolesToUpsert.add(
                            new OpportunityContactRole(
                                OpportunityId = oppId,
                                ContactId = newOppConMap.get(oppId),
                                IsPrimary = true,
                                Role = 'Signatory'
                            )
                        );
                    }
                }
            }
            skipOpportunityContactRoleValidations = true;
            upsert oppConRolesToUpsert;
        }
    }

    //QTC-544 Add White Space to new Opportunities
    public class addWhiteSpace extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Set<Id> newOppAccIds = new Set<Id>();
            Map<Id, Competitive_Technology_Stack__c> mapOfAcctToWS = new Map<Id, Competitive_Technology_Stack__c>();
            Set<Id> setWSAccts = new Set<Id>();
            Set<Id> setNoWSAccts = new Set<Id>();

            for (Opportunity opp : (List<Opportunity>) Trigger.new) {
                if (opp.AccountId != null) {
                    newOppAccIds.add(opp.AccountId);
                }
            }

            //Get existing White spaces for accounts
            if (newOppAccIds != null && newOppAccIds.size() > 0) {
                List<Account> listAccts = (List<Account>) new AccountSelector()
                    .selectIncumbentInfoForAccts(new List<Object>{newOppAccIds})
                    .executeQuery();
                if (listAccts != null && listAccts.size() > 0) {
                    for (Account acc : listAccts) {
                        if (acc.Competitive_Technology_Stacks__r != null && acc.Competitive_Technology_Stacks__r.size() > 0) {
                            setWSAccts.add(acc.Id);
                            mapOfAcctToWS.put(acc.Id, acc.Competitive_Technology_Stacks__r);
                        } else {
                            setNoWSAccts.add(acc.Id);
                        }
                    }
                }
            }

            //New White Space creation
            List<Competitive_Technology_Stack__c> newWhiteSpaces = new List<Competitive_Technology_Stack__c>();
            if (setNoWSAccts != null && setNoWSAccts.size() > 0) {
                for (Id accId : setNoWSAccts) {
                    Competitive_Technology_Stack__c ws = new Competitive_Technology_Stack__c();
                    ws.Account__c = accId;
                    newWhiteSpaces.add(ws);
                }
            }
            if (newWhiteSpaces != null && newWhiteSpaces.size() > 0) {
                insert newWhiteSpaces;
                for (Competitive_Technology_Stack__c ws : newWhiteSpaces) {
                    if (ws.Account__c != null) {
                        mapOfAcctToWS.put(ws.Account__c, ws);
                    }
                }
            }

            //White Space mapped to Opps
            if (mapOfAcctToWS != null && mapOfAcctToWS.size() > 0) {
                for (Opportunity opp : (List<Opportunity>) Trigger.new) {
                    if (mapOfAcctToWS.containsKey(opp.AccountId)) {
                        //opp.White_Space__c = mapOfAcctToWS.get(opp.AccountId);
                        opp.Phone__c = mapOfAcctToWS.get(opp.AccountId).phone__c;
                        opp.Contact_Center__c = mapOfAcctToWS.get(opp.AccountId).Contact_Center__c;
                        opp.Meetings__c = mapOfAcctToWS.get(opp.AccountId).Meetings__c;
                        opp.Digital_Channels__c = mapOfAcctToWS.get(opp.AccountId).Digital_Channels__c;
                        opp.Message__c = mapOfAcctToWS.get(opp.AccountId).Message__c;
                        opp.Incumbent_Conversation_Intelligence__c = mapOfAcctToWS.get(opp.AccountId).Incumbent_Conversation_Intelligence__c;
                        opp.Key_Deal_Integration__c = mapOfAcctToWS.get(opp.AccountId).Key_Deal_Integration__c;
                        opp.Key_Deal_Integration_Other__c = mapOfAcctToWS.get(opp.AccountId).Key_Deal_Integration_Other__c;
                    }
                }
            }
        }
    }

    public class ValidateVerizonOpptyClose extends Triggers.TriggerHandlerBase {
        override public void handle() {
            for (Opportunity opp : (List<Opportunity>) Trigger.new) {
                if (isVerizonOpptySetTo7Closed(opp)) {
                    opp.addError(OpportunityHelper.VERIZON_CLOSE_ERROR);
                }
            }
        }

        private Boolean isVerizonOpptySetTo7Closed(Opportunity opp) {
            return OpportunityHelper.isVerizon(opp)
                && isChangedFieldTo(opp, Opportunity.StageName, OpportunityHelper.STAGE_NAME_CLOSED_WON);
        }
    }

    public class UpdateDealsDeskStage extends Triggers.TriggerHandlerBase {
        override public void handle() {
            for (Opportunity opp : (List<Opportunity>) Trigger.new) {
                if (isChangedFieldTo(opp, Opportunity.Sub_Stage__c, OpportunityHelper.SUB_STAGE_CLOSED)
                    && (opp.RecordTypeId == OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY
                        || opp.RecordTypeId == OpportunityHelper.RT_ID_SALES_OPPORTUNITY
                        || opp.RecordTypeId == OpportunityHelper.RT_ID_VAR_OPPORTUNITY)) {
                    opp.Deals_Desk_Stage__c = OpportunityHelper.DEALS_DESK_STAGE_PROVISIONING_ORDER_COMPLETE;
                }
            }
        }
    }

    /* CRM-5076 - Added as Part of EU Data Privacy Project to restrict changing the Account Owner when the Record is of EU*/
    public class CheckEUDataPrivacy extends Triggers.TriggerHandlerBase {
        override public void handle() {
            if (!CheckRecursive.isEUDataPrivacyRecurssion_Opportunity) {
                try {
                    EUPrivacy eu = new EUPrivacy();
                    Set<String> EURestrictedCountriesSet = eu.getEURestrictedCountries();
                    Set<String> EURestrictedProfileNameSet = eu.getEURestrictedProfileNames();
                    Set<String> EURestrictedAccountBrandsSet = eu.getEURestrictedAccountBrands();
                    Set<String> EUSupportRestrictedProfileSet = eu.getEUSupportRestrictedProfiles();
                    System.debug('EURestrictedCountriesSet-->' + EURestrictedCountriesSet + 'EURestrictedProfileNameSet-->' + EURestrictedProfileNameSet
                        + 'EURestrictedAccountBrandsSet-->' + 'EUSupportRestrictedProfileSet-->' + EUSupportRestrictedProfileSet);
                    Map<Id, Opportunity> oppOwneridMap = new Map<Id, Opportunity>();
                    Map<Id, Opportunity> triggerNewMap = (Map<Id, Opportunity>) Trigger.newMap;
                    Map<Id, Opportunity> triggerOldMap = (Map<Id, Opportunity>) Trigger.oldMap;
                    Map<Id, Opportunity> newOppMap = new Map<Id, Opportunity>([
                        SELECT Id, Account.BillingCountry, Account.SM_Country__c, Account.RC_Brand__c FROM Opportunity WHERE Id IN :Trigger.newMap.keySet()
                    ]);
                    for (Opportunity opp : newOppMap.values()) {
                        if (triggerOldMap.get(opp.Id).OwnerId != triggerNewMap.get(opp.Id).OwnerId && opp.Account != null &&
                            (opp.Account.BillingCountry != null && EURestrictedCountriesSet.contains(opp.Account.BillingCountry.toLowerCase()) ||
                                (opp.Account.SM_Country__c != null && EURestrictedCountriesSet.contains(opp.Account.SM_Country__c.toLowerCase())))) {
                            Opportunity o = triggerNewMap.get(opp.Id);
                            oppOwneridMap.put(o.Id, o);
                        }
                    }
                    Map<Id, Opportunity> oppidOwneridMap = new Map<Id, Opportunity>();
                    for (Opportunity o : newOppMap.values()) {
                        if (oppOwneridMap.containsKey(o.Id)) {
                            oppidOwneridMap.put(oppOwneridMap.get(o.Id).OwnerId, o);
                        }
                    }
                    if (!oppidOwneridMap.isEmpty()) {
                        Map<Id, User> userdetailMap = new Map<Id, User>([SELECT Id, ProfileId FROM User WHERE Id IN :oppidOwneridMap.keySet()]);
                        Map<Id, Opportunity> oppUserMap = new Map<Id, Opportunity>();
                        for (Opportunity o : oppidOwneridMap.values()) {
                            oppUserMap.put(userdetailMap.get(oppOwneridMap.get(o.Id).OwnerId).ProfileId, o);
                        }
                        System.debug('oppUserMap--> ' + oppUserMap);
                        Map<Id, Profile> restrictedProfileMap = new Map<Id, Profile>([SELECT Id, Name FROM Profile WHERE Name IN :EURestrictedProfileNameSet]);
                        System.debug('restrictedProfileMap--> ' + restrictedProfileMap);
                        for (Id key : oppUserMap.keySet()) {
                            if (restrictedProfileMap.containsKey(key) && eu.RestrictBasedOnSpecificAccBrands && !EURestrictedAccountBrandsSet.isEmpty() &&
                                String.isNotBlank((oppUserMap.get(key).Account.RC_Brand__c).trim()) &&
                                EURestrictedAccountBrandsSet.contains((oppUserMap.get(key).Account.RC_Brand__c).trim().toLowerCase())) {
                                oppOwneridMap.get(oppUserMap.get(key).Id).addError('Action restricted due to Account Brand restrictions');
                            } else if (restrictedProfileMap.containsKey(key) && !eu.RestrictBasedOnSpecificAccBrands) {
                                oppOwneridMap.get(oppUserMap.get(key).Id).addError('Cannot assign the owner from restricted region');
                            }
                        }
                    }
                } catch (Exception ex) {
                    System.debug('CheckEUDataPrivacy error : ' + ex.getMessage());
                }
                CheckRecursive.isEUDataPrivacyRecurssion_Opportunity = true;
            }
        }
    }

    public class CreateOrderAfterClosingOpp extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Opportunity> changedOpportunities = (List<Opportunity>) Trigger.new;

            Set<Id> primaryQuoteIds = new Set<Id>();
            List<Opportunity> proServChangeOrderOpps = new List<Opportunity>();

            for (Opportunity opp : changedOpportunities) {
                if (!isChangedFieldTo(opp, Opportunity.StageName, OpportunityHelper.STAGE_NAME_CLOSED_WON)
                    || (opp.Type != OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS && !AccountHelper.isPOCToPaid(accountMapStatic.get(opp.AccountId)))
                    || String.isBlank(opp.PrimaryQuote__c)
                ) {
                    continue;
                }
                if (opp.Parent_Order__c != null && opp.Tier_Name__c == OpportunityHelper.TIER_PROFESSIONAL_SERVICES && opp.Is_Billing_Opportunity__c) {
                    proServChangeOrderOpps.add(opp);
                }

                primaryQuoteIds.add(opp.PrimaryQuote__c);
            }

            if (primaryQuoteIds.isEmpty()) {
                return;
            }

            createOrderQuoteList = (List<Quote>) new QuoteSelector()
                .selectQuotesByIdToQLIsForOrderCreationProcess(primaryQuoteIds)
                .executeQuery();

            OrderHelper.QuoteOrdersFactory quoteOrdersFactory = new OrderHelper.QuoteOrdersFactory(createOrderQuoteList, true, false);
            Map<Id, List<Order>> quoteOrdersMap = quoteOrdersFactory.buildOrdersForQuotes();
            Set<Id> quoteIdsForDelete = new Set<Id>();
            List<Order> ordList = new List<Order>();

            for (Quote qt : createOrderQuoteList) {
                if (!quoteOrdersMap.containsKey(qt.Id)) {
                    continue;
                }

                List<Order> orders = quoteOrdersMap.get(qt.Id);
                Account quoteAccount = OpportunityTriggerHelperRefactored.accountMapStatic.get(qt.AccountId);

                if (QuoteHelper.isMPUBQuote(qt, quoteAccount?.Master_Accounts__r) && orders.size() > 0) {
                    quoteIdsForDelete.add(qt.Id);
                }

                ordList.addAll(orders);
            }

            if (!quoteIdsForDelete.isEmpty()) {
                List<Order> ordersToRemove = (List<Order>) new OrderSelector()
                    .selectOrdersByTechQuoteIds(quoteIdsForDelete)
                    .selectFields(new List<String>{
                        'Id'
                    })
                    .addCondition('Status NOT IN :bind1')
                    .addQueryBindings(new List<Object>{
                        new Set<String> { OrderHelper.STATUS_ACTIVATED }
                    })
                    .executeQuery();
                if (!ordersToRemove.isEmpty()) {
                    delete ordersToRemove;
                }
            }

            if (!ordList.isEmpty()) {
                if (!proServChangeOrderOpps.isEmpty()) {
                    System.enqueueJob(new ProcessProServRecordsOnOppClose(proServChangeOrderOpps, ordList));
                } else {
                    insert ordList;
                }
            }
        }
    }

    public class DeactivatePackageAndOrderOnClose extends Triggers.TriggerHandlerBase {
        override public void handle() {
            if (createOrderQuoteList.isEmpty()) {
                return;
            }

            List<Id> quoteIds = new List<Id>();

            for (Quote quote : createOrderQuoteList) {
                if (OrderHelper.isAllItemsDeliveredOnProServQuote(quote)) {
                    quoteIds.add(quote.Id);
                }
            }
            OpportunityHelper.processDeliveredProserv(quoteIds);
        }
    }

    public class CopyFieldsToTechnicalOppty extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Set<SObjectField> OPPORTUNITY_FIELDS_TO_COPY = new Set<SObjectField>{
                Opportunity.AreaCode__c,
                Opportunity.FaxAreaCode__c,
                Opportunity.StageName,
                Opportunity.Primary_Opportunity_Contact__c
            };

            List<Opportunity> masterOpps = new List<Opportunity>();
            List<Opportunity> techOpps = new List<Opportunity>();
            Set<Id> masterIds = new Set<Id>();

            for (Opportunity opp : (List<Opportunity>) Trigger.new) {
                if (!isChangedAnyField(opp, OPPORTUNITY_FIELDS_TO_COPY)) {
                    continue;
                }

                if (!opp.IsMultiProductTechnicalOpportunity__c) {
                    masterIds.add(opp.Id);
                }
            }

            if (masterIds.isEmpty()) {
                return;
            }

            List<Opportunity> masterAndTechOpps = new OpportunitySelector()
                .selectOpptysForCopying(new List<Object> { masterIds })
                .executeQuery();

            for (Opportunity opp : masterAndTechOpps) {
                if (!opp.IsMultiProductTechnicalOpportunity__c) {
                    masterOpps.add(opp);
                } else {
                    techOpps.add(opp);
                }
            }

            if (techOpps.isEmpty()) {
                return;
            }

            List<Opportunity> recordsToUpdate = new List<Opportunity>();
            for (Opportunity techOpp : techOpps) {
                for (Opportunity masterOpp : masterOpps) {
                    if (techOpp.MasterOpportunity__r.Id == masterOpp.Id) {
                        Boolean isUpdated = false;
                        if (techOpp.AreaCode__c != masterOpp.AreaCode__c) {
                            techOpp.AreaCode__c = masterOpp.AreaCode__c;
                            isUpdated = true;
                        }
                        if (techOpp.FaxAreaCode__c != masterOpp.FaxAreaCode__c) {
                            techOpp.FaxAreaCode__c = masterOpp.FaxAreaCode__c;
                            isUpdated = true;
                        }
                        if (techOpp.StageName != masterOpp.StageName) {
                            techOpp.StageName = masterOpp.StageName;
                            isUpdated = true;
                        }
                        if (techOpp.Primary_Opportunity_Contact__c != masterOpp.Primary_Opportunity_Contact__c) {
                            techOpp.Primary_Opportunity_Contact__c = masterOpp.Primary_Opportunity_Contact__c;
                            isUpdated = true;
                        }
                        if (isUpdated) {
                            recordsToUpdate.add(techOpp);
                        }
                        break;
                    }
                }
            }

            if (!recordsToUpdate.isEmpty()) {
                Triggers.switchOff();
                update recordsToUpdate;
                Triggers.switchOn();
            }
        }
    }

    public class SendAvisoPlatformEvents extends Triggers.TriggerHandlerBase {
        override public void handle() {
            if(Trigger.isInsert) {
                OpportunityPlatformEventHandler.triggerOpportunityCreatePlatformEvent(Trigger.new);
            } else if(Trigger.isUpdate) {
            	OpportunityPlatformEventHandler.triggerOpportunityUpdatePlatformEvent(Trigger.new, (Map<Id, Opportunity>)Trigger.oldMap);
    		}
        }
    }
    public class AdjustDFREstimatedARRPipeline extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Opportunity> oppsToProcess = new List<Opportunity>();
            for (Opportunity opp : (List<Opportunity>) Trigger.New) {
                if (opp.Estimated_12M_Total_Pipeline__c != Trigger.OldMap.get(opp.Id).get('Estimated_12M_Total_Pipeline__c') ||
                    opp.CloseDate != Trigger.OldMap.get(opp.Id).get('CloseDate') ||
                    opp.CurrencyIsoCode != Trigger.OldMap.get(opp.Id).get('CurrencyIsoCode') ||
                    opp.Amount != Trigger.OldMap.get(opp.Id).get('Amount') ||
                    opp.X12_Month_Booking__c != Trigger.OldMap.get(opp.Id).get('X12_Month_Booking__c')) {
                    oppsToProcess.add(opp);
                }
            }
            if (!oppsToProcess.isEmpty()) {
                try {
                    if (!Queueable_DG_DFR_Class.isQueueuableLimitsReached() && !Test.isRunningTest() && !skipAsyncDFR) {
                        System.enqueueJob(new Queueable_DG_DFR_Class.DFR_AddOpportunity(oppsToProcess, true));
                    } else {
                        DG_DFR_Class.DFR_OpportunityPipelineRecalculation(oppsToProcess);
                    }
                } catch (Exception e) {
                    DG_DFR_Class.dfrSaveException(e, null, null, null, oppsToProcess);
                }
            }
        }
    }
      public class PopulateSlapFiveAdvocateId extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Map<Id,Id> oppIdPrimaryContactIdMap = new Map<Id,Id>();

            for (Opportunity opp : (List<Opportunity>) Trigger.new) { 
                if (opp.Primary_Opportunity_Contact__c != null) {
                    oppIdPrimaryContactIdMap.put(opp.Id, opp.Primary_Opportunity_Contact__c);
                }
            }

            Set<Id> primaryContactIds = new Set<Id>(oppIdPrimaryContactIdMap.values());

            if (!primaryContactIds.isEmpty()) {
                Map<Id, Contact> slapFiveContactMap = new Map<Id, Contact>((List<Contact>) new ContactSelector()
                .selectContactsForSlapFiveAdvocate(primaryContactIds)
                .executeQuery());

                for (Opportunity opp : (List<Opportunity>) Trigger.new) {
                    if (oppIdPrimaryContactIdMap.containsKey(opp.Id) && !slapFiveContactMap.isEmpty()) {
                            Contact slapFiveContact = slapFiveContactMap.get(opp.Primary_Opportunity_Contact__c);
                            if (slapFiveContact != null) {
                                opp.SlapFive_Advocate_Member_Id__c = slapFiveContact.SlapFive_Advocate_Member_Id__c;
                          }
                    }
                }
            }
        }
    }

    public class IdentifyImmediateNextStepUsingAI extends Triggers.TriggerHandlerBase {
        override public void handle() {
            if (NextStepAIProcessor.isImmediateNextStepProcessed) {
                return;
            }
                
            List<NextStepAIProcessor.NextStepRequest> reqWrapperList = new List<NextStepAIProcessor.NextStepRequest>();
            Map<Id, Opportunity> oldMap = (Map<Id, Opportunity>) Trigger.oldMap;
            Boolean isInsert = (oldMap == null);
            String currentUserName = UserInfo.getName();
            
            for (Opportunity opp : (List<Opportunity>) Trigger.New) {

                String oldNextStepsVal = isInsert ? null : oldMap.get(opp.Id).Discovery_Next_Steps__c;
                String newNextStepsVal = opp.Discovery_Next_Steps__c;
                Boolean shouldProcess = isInsert 
                    ? String.isNotBlank(newNextStepsVal)
                    : (newNextStepsVal != oldNextStepsVal);
                
                if (shouldProcess) {
                    NextStepAIProcessor.NextStepRequest item = new NextStepAIProcessor.NextStepRequest();
                    
                    item.oppId = opp.Id;
                    item.oldNextStepVal = oldNextStepsVal;
                    item.newNextStepVal = newNextStepsVal;
                    item.lastImmediateNextStepVal = opp.Next_Steps_Last_Modified__c;
                    item.modifiedByUserName = currentUserName;
                    reqWrapperList.add(item);
                }
            }
            if (!reqWrapperList.isEmpty()) {
                if (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()) { 
                    System.enqueueJob(new NextStepAIProcessor(reqWrapperList));
                }
            }
        }
    }
}