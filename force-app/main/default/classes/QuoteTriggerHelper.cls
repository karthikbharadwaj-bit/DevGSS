/*
* Name         : QuoteTriggerHelper.cls
* Created By   : Fedor Golovanov (fgolovanov@aquivalabs.com)
* Created Date : 4/July/2016
* Description  : Class contains methods for Quote trigger
*
* Modified By  : eugenebasianomutya
* Modified Date: 10/03/2016
* Description  : For Case 05020800 - Payment Period field to be populated
*/

public with sharing class QuoteTriggerHelper{
    public static final String STATUS_ACTIVE = 'Active';
    public static final String STATUS_PRESENTED = 'Presented';
    public static final String STATUS_EXECUTED = 'Executed';

    public static final String TYPE_AGREEMENT = 'Agreement';

    public static boolean bypassQuoteRollupLogic = false;
    private static final String BASE_URL = URL.getOrgDomainUrl().toExternalForm();
    public static Map<Id, Opportunity> opportunityMapStatic = new Map<Id, Opportunity>();
    public static Map<Id, Pricebook2> pricebookMapStatic = new Map<Id, Pricebook2>();
    public static Map<Id, Account> accountMapStatic = new Map<Id, Account>();
    public static Set<Id> masterMultiProductAccounts = new Set<Id>();
    public static Map<Id, List<Entitlement__c>> accountIdToEntsMapStatic = new Map<Id, List<Entitlement__c>> ();
    public static Map<Id, List<Quote>> accountIdToQuotes = new Map<Id, List<Quote>>();
    public static Map<Id, List<ServiceInfo__c>> masterQuoteIdToServiceInfoMap = new Map<Id, List<ServiceInfo__c>>();
    public static Map<Id, User> userMapStatic = new Map<Id, User>();
    public static Map<Id, List<ProcessInstanceStep>> quoteToStepsListMapStatic = new Map<Id, List<ProcessInstanceStep>>();
    private static Map<String, Schema.DescribeFieldResult> quoteFieldDescribeMap = new Map<String, Schema.DescribeFieldResult>();

    public static Boolean byPassOpportunityUpdate = false;
    public static Boolean isSalesAgreementValidationExecuted = false;

    private static boolean isCLMChangeOrderFormRequiredCalled = false;

    // Use case of variable paramWasNotChanged:
    // When discount of QuoteLineItem is changed it needs to update Opportunity to display correct field values such as Total MRR ans so on.
    public static Boolean paramWasNotChanged = false;

    public static Boolean byPassProServStatusUpdate = false;

    private static final String SALES_QUOTE_DEVELOPER_RT_NAME = 'Sales_Quote';
    private static final String PROSERV_QUOTE_DEVELOPER_RT_NAME = 'ProServ_Quote';
    private static final String CC_PROSERV_QUOTE_DEVELOPER_RT_NAME = 'CC_ProServ_Quote';
    private static final String RT_NAME_BILLING = 'Sales Quote v2';

    private static final Set<String> PROSERV_QUOTE_DEVELOPER_RT_NAMES_SET = new Set<String>{
            PROSERV_QUOTE_DEVELOPER_RT_NAME, CC_PROSERV_QUOTE_DEVELOPER_RT_NAME
    };

    private static final String SALES_QUOTE_RT_NAME = 'Sales Quote';
    private static final String PROSERV_QUOTE_RT_NAME = 'ProServ Quote';
    private static final String CC_PROSERV_QUOTE_RT_NAME = 'CC ProServ Quote';
    private static final String POC_QUOTE_RT_NAME = 'POC Quote';

    private static final Map<String, Schema.RecordTypeInfo> QUOTE_RT_INFO_BY_NAME =
            Quote.SObjectType.getDescribe().getRecordTypeInfosByName();

    private static final Id SALES_QUOTE_RT_ID = QUOTE_RT_INFO_BY_NAME.get(SALES_QUOTE_RT_NAME).getRecordTypeId();
    private static final Id PROSERV_QUOTE_RT_ID = QUOTE_RT_INFO_BY_NAME.get(PROSERV_QUOTE_RT_NAME).getRecordTypeId();
    private static final Id CC_PROSERV_QUOTE_RT_ID = QUOTE_RT_INFO_BY_NAME.get(CC_PROSERV_QUOTE_RT_NAME).getRecordTypeId();
    private static final Id RT_ID_BILLING = QUOTE_RT_INFO_BY_NAME.get(RT_NAME_BILLING).getRecordTypeId();
    private static final Id POC_QUOTE_RT_ID = QUOTE_RT_INFO_BY_NAME.get(POC_QUOTE_RT_NAME).getRecordTypeId();

    private static final Set<String> PROSERV_QUOTE_DEVELOPER_ID_SET = new Set<String>{
            QuoteHelper.RT_ID_PROSERV, QuoteHelper.RT_ID_CC_PROSERV
    };

    private static final String PROSERV_PRODUCT_SUBCATEGORY = 'Professional Services';
    private static final String CC_PROSERV_PRODUCT_SUBCATEGORY = 'CC Professional Services';
    private static final String CONTACT_CENTER_PRODUCT_SUBCATEGORY = 'Contact Center';
    private static final String PRODUCT_CHARGETERM_ONETIME = 'One - Time';
    private static final String PRODUCT_CHARGETERM_MONTHLY = 'Monthly - Contract';
    private static final String PRODUCT_FAMILY_TAXES = 'Taxes';
    private static final String RENEWAL_VALIDATION_MESSAGE =
        'Please specify the correct Renewal Term if you want the agreement to be auto-renewed';

    public static Set<String> annualPlanNames = new Set<String> {
        Product2Helper.CHARGE_TERM_ANNUAL,
        Product2Helper.CHARGE_TERM_ANNUAL_CONTRACT
    };
    private static final String POC_OPPORTUNITY_SSE_LEADERSHIP_TEAM_EMAIL = 'POC_Quote_SSE_Leadership_Team_Email';
    private static final String POC_OPPORTUNITY_CESE_LEADERSHIP_TEAM_EMAIL = 'POC_RingCX_Quote_SSE_Leadership_Team_Email';
    private static final String SE_ROLE = 'Solutions Engineer (Primary)';
    private static final String CESE_ROLE = 'Customer Experience SE';
    private static final String ENGAGE_VOICE_STANDALONE_SERVICE = 'Engage Voice Standalone';
    private static Integer THRESHHOLD_DL_NO = 20;
    private static String SSE_DIRECT_LEADERSHIP = 'SSE_Direct_Leadership';

    private static final List<String> bypassProfileNames = new List<String> {
        'CRM Support Engineer',
        'CRM Support Engineer - EU Restricted',
        'System Administrator'
    };

    private static final List<String> bypassUserNames = new List<String> {
        'DocuSign Integration',
        'DocuSign Integration User'
    };

    private static final List<String> engageVoiceServiceNames = new List<String> {
        'Engage Voice Legacy',
        'Engage Digital Legacy'
    };

    public static List<String> oppFieldsToSelectForInsertUpdate = new List<String> {
        'Id',
        'EstimatedProfessionalServices12Month__c',
        'OwnerId',
        'Primary_Opportunity_Contact__c',
        'Brand_Name__c',
        'AccountId',
        'Name',
        'Type',
        'Inside_Sales_Rep__c',
        'Account.Name',
        'Account.BillingStreet',
        'Account.BillingCity',
        'Account.BillingState',
        'Account.BillingPostalCode',
        'Account.BillingCountry',
        'Account.Active_Sales_Agreement__c',
        'Account.Active_Sales_Agreement__r.Status',
        'Account.Previous_Sales_Agreement_End_Date__c',
        'Account.RC_User_ID__c'
    };

    public static void selectOppsByIdsAndPopulateMaps(Set<Id> oppIds) {
        if (oppIds == null || oppIds.isEmpty()) {
            return;
        }

        Boolean doSOQL = false;
        List<Opportunity> opps = new List<Opportunity>();
        for (Id oId : oppIds) {
            if (!opportunityMapStatic.containsKey(oId)) {
                doSOQL = true;
            } else {
                opps.add(opportunityMapStatic.get(oId));
            }
        }
        if (doSOQL) {
            opps = (List<Opportunity>) new OpportunitySelector()
                .selectOpportunitiesByIds(oppIds)
                .withoutSelectorFieldsIncluded()
                .selectFields(oppFieldsToSelectForInsertUpdate)
                .executeQuery();
        }

        for (Opportunity opp : opps) {
            opportunityMapStatic.put(opp.Id, opp);
            accountMapStatic.put(opp.AccountID, opp.Account);
        }
    }

    public static Map<Id, OpportunityTeamMember> getOpportunityTeamMembers(Set<Id> oppIdSet, String role) {
        List<OpportunityTeamMember> oppTeamMembersList = (List<OpportunityTeamMember>) new OpportunityTeamMemberSelector()
                .selectByOpportunityIdsAndRoles(new List<Object> {oppIdSet, new List<String>{role}})
                .executeQuery();
        
        Map<Id, OpportunityTeamMember> oppTeamMemberMap = new Map<Id, OpportunityTeamMember>();
        for (OpportunityTeamMember oppTeam : oppTeamMembersList) {
            oppTeamMemberMap.put(oppTeam.OpportunityId, oppTeam);
        }
        
        return oppTeamMemberMap;
    }
    
    public static List<Messaging.SingleEmailMessage> buildEmailList(Set<Id> oppIdSet, Map<Id, OpportunityTeamMember> oppTeamMemberMap, String templateDeveloperName) {
        List<EmailTemplate> templates = (List<EmailTemplate>) new EmailTemplateSelector()
                .selectEmailTemplatesByDeveloperNames(
                    new List<String>{templateDeveloperName},
                    false  
                )
                .executeQuery();
        
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        for (Id oppId : oppIdSet) {
            if (!oppTeamMemberMap.containsKey(oppId)) {
                Messaging.SingleEmailMessage email = createEmail(templates[0], oppId, Emails__c.getInstance(SSE_DIRECT_LEADERSHIP).Email_Address__c);
                emailList.add(email);
            }
        }
        
        return emailList;
    }
    
    public static Messaging.SingleEmailMessage createEmail(EmailTemplate template, Id oppId, String emailAddress) {
        ApprovalHelperCls.InternalEmail mail = new ApprovalHelperCls.InternalEmail(
            UserInfo.getUserId(),
            template.Subject, 
            template.HtmlValue
        );
        mail.addParameter('Opportunity.Name', opportunityMapStatic?.get(oppId).Name);
        mail.addParameter('Opportunity.Link', BASE_URL + '/' + oppId);
        
        Messaging.SingleEmailMessage email = mail.getMails()[0];
        email.setToAddresses(new List<String>{emailAddress});
        
        return email;
    }
    
    public static void sendEmails(List<Messaging.SingleEmailMessage> emailList) {
        if (!emailList.isEmpty()) {
            try {
                Messaging.sendEmail(emailList);
            } catch (EmailException ex) {
                throw new AquivaHelper.AquivaException(ex.getMessage());
            }
        }
    }

    public class ManageQuotesMapStatic extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Set<Id> quoteIdsToLoad = new Set<Id>();
            if (Trigger.isBefore) {
                for (Quote qt : (List<Quote>) this.TriggerRecords) {
                    if (!QuoteLineItemTriggerHelper.quotesMapStatic.containsKey(qt.Id)) {
                        quoteIdsToLoad.add(qt.Id);
                    }
                }
            }

            if (!quoteIdsToLoad.isEmpty()) {
                List<Quote> quotesList = (List<Quote>) new QuoteSelector()
                    .selectQuotesForQuoteLineItemTrigger(quoteIdsToLoad)
                    .executeQuery();

                QuoteLineItemTriggerHelper.quotesMapStatic.putAll(quotesList);
            }
        }
    }

    private abstract class QuoteStatusChangeHandler extends Triggers.TriggerHandlerBase {
        protected Map<Id, Opportunity> opptysByQuotes;
        public List<Quote> recordsToProcess = new List<Quote>();

        protected abstract Set<String> getStatusesToHandle();

        protected void setLegalRequestsStatus(final String status) {
            if (recordsToProcess.isEmpty()) {
                return;
            }

            Set<Approval__c> approvals = new Set<Approval__c>();
            for(Quote q: recordsToProcess) {
                if(!q.isPrimary__c) {
                    continue;
                }

                Opportunity o = opptysByQuotes.get(q.Id);
                if(String.isBlank(o.Special_TOS_Approval__c)) {
                    continue;
                }

                approvals.add(new Approval__c(
                    Id = o.Special_TOS_Approval__c,
                    Status__c = status
                ));
            }

            if (!approvals.isEmpty()) {
                update new List<Approval__c>(approvals);
            }
        }

        public QuoteStatusChangeHandler(){
            this(Trigger.isDelete ? Trigger.old : Trigger.new);
        }

        public QuoteStatusChangeHandler(List<sObject> recList) {
            super(recList);
            Set<String> statuses = getStatusesToHandle();
            for(Quote q : (List<Quote>) triggerRecords) {
                if(isChangedField(q, Quote.Status) && statuses.contains(q.Status)){
                    recordsToProcess.add(q);
                }
            }
        }
    }

    public class CheckIfQuotingIsAvailableForBrand extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Set<Id> oppIds = new Set<Id>();
            for (Quote q : (List<Quote>) Trigger.new) {
                oppIds.add(q.opportunityId);
            }

            if (oppIds.isEmpty()) {
                return;
            }

            selectOppsByIdsAndPopulateMaps(oppIds);

            for (Quote q : (List<Quote>) Trigger.new) {
                Opportunity o = opportunityMapStatic.get(q.OpportunityId);
                if (!QuoteHelper.isQuotingAvailableForBrand(o.Brand_Name__c, o.Type == OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS)) {
                    q.addError('Quoting is not available for current brand.');
                }
            }
        }
    }

    public class HandleAgreementPresented extends QuoteStatusChangeHandler {
        protected override Set<String> getStatusesToHandle(){
            return new Set<String>{STATUS_PRESENTED};
        }

        override public void handle(){
            // set legal requests out for signature
            setLegalRequestsStatus(ApprovalHelperCls.STATUS_OUT_FOR_SIGNATURE);
        }

        public HandleAgreementPresented() {
            super();
            opptysByQuotes = AquivaHelper.getOpportunitiesByQuotes();
        }
    }

    public class HandleAgreementActiveExecuted extends QuoteStatusChangeHandler {
        protected override Set<String> getStatusesToHandle(){
            return new Set<String>{STATUS_ACTIVE, STATUS_EXECUTED};
        }

        override public void handle(){
            // set legal requests completed
            setLegalRequestsStatus(ApprovalHelperCls.STATUS_COMPLETED);
        }

        public HandleAgreementActiveExecuted() {
            super();
            opptysByQuotes = AquivaHelper.getOpportunitiesByQuotes();
        }
    }

    public class HandlePOCQuoteStatus extends Triggers.TriggerHandlerBase {
        override public void handle() {
           for(Quote item : (List<Quote>)(Trigger.new)) {
                if (QuoteHelper.isPOCQuote(item) && item.Status != QuoteHelper.QUOTE_STATUS_DRAFT) {
                    item.Status = QuoteHelper.QUOTE_STATUS_DRAFT;
                }
           }
        }
    }

    @TestVisible
    private static Map<Id, Boolean> quoteIdToPassApprovalLogicMap = new Map<Id, Boolean>(); // Map for more convenient testing

    public class SetApprovalType extends Triggers.TriggerHandlerBase {

        override public void handle() {
            Boolean isNewContractTermFlow = Feature_Toggle__c.getInstance().Enable_new_Contract_Term_flow__c;
            Set<Id> quoteIdSet = new Set<Id>();
            Map<Id, Boolean> quoteIdToIsQuoteContainsDependentGOAProductsMap = checkIsQuoteContainsProductsDependsOnGOAInitialTerm((Map<Id, Quote>)Trigger.newMap);
            List<Quote> quotesToProceed = new List<Quote>();
            Map<Id, List<QuoteLineItem>> quoteIdToQli = new Map<Id, List<QuoteLineItem>>();
            for(Quote item : (List<Quote>)(Trigger.new)) {
                if (QuoteHelper.isPOCQuote(item)) {
                    continue;
                }

                if (QuoteHelper.isMigrationFlow(item, UserInfo.getUserId())) {
                    continue;
                }

                if (item.IsMultiProductTechnicalQuote__c) {
                    continue;
                }

                Boolean passApprovalLogic = checkIsNeedToPassApprovalLogic(item, quoteIdToIsQuoteContainsDependentGOAProductsMap);

                // save to map for more convenient testing
                // TODO: use Triggers.except to skip trigger handler
                quoteIdToPassApprovalLogicMap.put(item.Id, passApprovalLogic);
                if(passApprovalLogic) {
                    continue;
                }

                quotesToProceed.add(item);
                quoteIdToQli.put(item.Id, new List<QuoteLineItem>());
            }

            if (quotesToProceed.isEmpty()) {
                return;
            }

            List<QuoteLineItem> qlis = (List<QuoteLineItem>) new QuoteLineItemSelector()
                .selectQuoteLineItemsByQuoteIdsForShipping(new List<Object> {quoteIdToQli.keySet()})
                .executeQuery();

            if (!qlis.isEmpty()) {
                for (QuoteLineItem quoteLiteItem : qlis) {
                    quoteIdToQli.get(quoteLiteItem.QuoteId).add(quoteLiteItem);
                }
            }

            for(Quote item : quotesToProceed) {
                // Determine what the quote should pass through approval process
                // determine if free shipping not required re-request approval
                Boolean changedOnlyFreeShippingFields = !isChangedAnyField(item, new Set<SObjectField>{
                    Quote.Special_Terms__c, Quote.Auto_Renewal__c, Quote.Term_months__c, Quote.Initial_Term_months__c
                });
                Boolean freeShippingApprovalRequired = QuoteApprovals.isFreeShippingApprovalNeeded(item, quoteIdToQli.get(item.Id));
                Boolean needReCalcApprovalAfterFreeShipping =
                    item.get(Quote.Approved_Status__c) != QuoteHelper.APPROVAL_STATUS_APPROVED
                    && isChangedFieldFrom(item, Quote.FreeShippingTerms__c, QuoteHelper.FREESHIPPING);

                if (!DocuSignStatusTriggerHandler.byPassSetApprovalType
                    && (isChangedField(item, Quote.Special_Terms__c)
                        || isChangedField(item, Quote.Auto_Renewal__c)
                        || isChangedField(item, Quote.FreeShippingTerms__c)
                        || isChangedField(item, Quote.Shipping_Option__c)
                        || (isChangedField(item, Quote.Term_months__c) && isNewContractTermFlow)
                        || isChangedField(item, Quote.Initial_Term_months__c))
                    && (!changedOnlyFreeShippingFields
                        || freeShippingApprovalRequired
                        || needReCalcApprovalAfterFreeShipping)
                    || QuoteApprovals.IS_NEED_RECALCULATE_MAIN_QUOTE_APPROVALS)
                {
                    quoteIdSet.add(item.Id);
                }
            }

            List<Quote> quotesToUpdate = QuoteApprovals.handleQuotes(quoteIdSet, new Set<Id>(), (Map<Id, Quote>)Trigger.newMap);
            System.debug('updated Quotes >>>> ' + quotesToUpdate);
        }

        private Boolean checkIsNeedToPassApprovalLogic(Quote quoteToCheck, Map<Id, Boolean> quoteIdToIsQuoteContainsDependentGOAProductsMap) {
            /*
            1. Do not run Approval Logic if:
            1.1. Initial Term was changed on the Quote without Special Terms.
            OR
            1.2. Initial Term was changed on the Quote without products that have GOA rules that depend on Initial Term (GOA Group Device_Contract for example).
            */
            Boolean initialTermUpdatedWithoutSpecialTerms = checkIsInitialTermUpdatedWithoutSpecialTerms(quoteToCheck);
            Boolean isInitialTermUpdated = isChangedField(quoteToCheck, Quote.Initial_Term_months__c);
            Boolean isQuoteContainsProductsDependsOnGOAInitialTerm = false;
            if(quoteIdToIsQuoteContainsDependentGOAProductsMap.containsKey(quoteToCheck.Id)) {
                isQuoteContainsProductsDependsOnGOAInitialTerm = quoteIdToIsQuoteContainsDependentGOAProductsMap.get(quoteToCheck.Id);
            }

            Boolean isNewContractTermFlow = Feature_Toggle__c.getInstance().Enable_new_Contract_Term_flow__c;
            Boolean passApprovalLogic = false;

            if(isInitialTermUpdated) {
                if(initialTermUpdatedWithoutSpecialTerms && !isNewContractTermFlow) {
                    passApprovalLogic = true;
                }

                if(isQuoteContainsProductsDependsOnGOAInitialTerm) {
                    passApprovalLogic = false;
                }
            }

            Boolean isBillingQuote = quoteToCheck.RecordTypeId == QuoteHelper.RT_ID_BILLING;
            Boolean isSmallTermMonth = QuoteHelper.isTermsLessYear(quoteToCheck);

            if (isBillingQuote && isNewContractTermFlow && isSmallTermMonth) {
                passApprovalLogic = false;
            }

            return passApprovalLogic;
        }

        private Boolean checkIsInitialTermUpdatedWithoutSpecialTerms(Quote quoteToCheck) {
            if(quoteToCheck == null) {
                return false;
            }
            Boolean isInitialTermUpdated = isChangedField(quoteToCheck, Quote.Initial_Term_months__c);

            return isInitialTermUpdated && quoteToCheck.Special_Terms__c == null;
        }

        private Map<Id, Boolean> checkIsQuoteContainsProductsDependsOnGOAInitialTerm(Map<Id, Quote> quotesMap) {
            if(quotesMap == null || quotesMap.isEmpty()) {
                return new Map<Id, Boolean>();
            }

            // filter quoteIdSet(select only quote where Initial_Term_months__c was changed)
            Set<Id> quoteIdSet = new Set<Id>();
            for(Quote q : quotesMap.values()) {
                if(isChangedField(q, Quote.Initial_Term_months__c)) {
                    quoteIdSet.add(q.Id);
                }
            }

            if(quoteIdSet.isEmpty()) {
                return new Map<Id, Boolean>();
            }

            Map<Id, List<QuoteLineItem>> quoteIdToQliListMap = new Map<Id, List<QuoteLineItem>>();
            List<String> fieldsToQuery = new List<String> {
                'Id',
                'Quantity',
                'QuoteId',
                'Quote.Package_Info__c',
                'Product2.GOA_Group_V2__c',
                'Product2.GOA_Group_V3__c'
            };
            List<QuoteLineItem> qlisForQuotes = (List<QuoteLineItem>) new QuoteLineItemSelector()
                .selectQuoteLineItemsByQuoteIds(quoteIdSet)
                .selectFields(fieldsToQuery)
                .executeQuery();

            for (QuoteLineItem qli : qlisForQuotes) {
                if (!quoteIdToQliListMap.containsKey(qli.QuoteId)) {
                    quoteIdToQliListMap.put(qli.QuoteId, new List<QuoteLineItem>());
                }
                quoteIdToQliListMap.get(qli.QuoteId).add(qli);
            }

            Map<Id, Boolean> resultMap = new Map<Id, Boolean>();

            for (Id quoteId : quoteIdSet) {
                List<QuoteLineItem> qliForCurrentQuote = quoteIdToQliListMap.get(quoteId);
                Boolean isQuoteContainsProductsDependsOnGOAInitialTerm = checkIsQuoteContainsProductsDependsOnGOAInitialTerm(qliForCurrentQuote);
                resultMap.put(quoteId, isQuoteContainsProductsDependsOnGOAInitialTerm);
            }

            return resultMap;
        }

        public Boolean checkIsQuoteContainsProductsDependsOnGOAInitialTerm(List<QuoteLineItem> qliList) {
            if(qliList == null || qliList.isEmpty()) {
                return false;
            }

            List<GOA_V2__c> notEmptyInitialTermGoasList = new List<GOA_V2__c>();

            for(GOA_V2__c item : GOA_V2__c.getAll().values()) {
                if(item.Contract_Initial_Term_Range__c != null) {
                    notEmptyInitialTermGoasList.add(item);
                }
            }

            return checkIsQuoteContainsProductsDependsOnGOAInitialTerm(qliList, notEmptyInitialTermGoasList);
        }

        private Boolean checkIsQuoteContainsProductsDependsOnGOAInitialTerm(List<QuoteLineItem> qliList, List<GOA_V2__c> notEmptyInitialTermGoasList) {
            Boolean productDependentOnInitialTermsExistInQuote = false;

            if (qliList == null || qliList.isEmpty()) {
                return productDependentOnInitialTermsExistInQuote;
            }

            if (notEmptyInitialTermGoasList.isEmpty()) {
                return productDependentOnInitialTermsExistInQuote;
            }

            for (QuoteLineItem qli : qliList) {
                // get GOA group from QLI
                String goaGroupFromQLI;
                BillingWrappers.QuotePackageInfo pInfo;

                if (String.isBlank(qli.Product2.GOA_Group_V3__c)) {
                    goaGroupFromQLI = qli.Product2.GOA_Group_V2__c;
                } else {
                    try {
                        List<BillingWrappers.QuotePackageInfo> pInfos =
                            (List<BillingWrappers.QuotePackageInfo>)
                                JSON.deserialize(
                                    qli.Quote.Package_Info__c,
                                    List<BillingWrappers.QuotePackageInfo>.class
                                );
                        pInfo = pInfos[0];

                        try {
                            goaGroupFromQLI = QuoteLineItemHelper.parseOldFormatGOA(qli, pInfo);
                        } catch ( JSONException e) {
                            goaGroupFromQLI = QuoteLineItemHelper.parseNewFormatGOA(qli, pInfo);
                        }
                    } catch (Exception e) {
                        System.debug('Failed to parse Quote\'s package info: ' + e.getMessage());
                    }
                }

                // check only GOA_V2__c items that have Contract_Initial_Term_Range__c populated
                for (GOA_V2__c goaItem : notEmptyInitialTermGoasList) {
                    Boolean isEditionMatch = true;
                    if (pInfo != null) {
                        isEditionMatch = String.isBlank(goaItem.Edition__c)
                            ? true
                            : (pInfo.edition.name == goaItem.Edition__c);
                    }
                    // check group
                    if (goaGroupFromQLI == goaItem.Group__c && isEditionMatch) {
                        // check QuantityRange
                        QuoteApprovals.Range quantityRange = new QuoteApprovals.Range(goaItem.Quantity_Range__c, '-');

                        if (quantityRange.isInRange(qli.Quantity)) {
                            productDependentOnInitialTermsExistInQuote = true;
                        }
                    }
                }
            }

            return productDependentOnInitialTermsExistInQuote;
        }
    }


    private static final String SYNCED_PROSERV_STATUS = 'Synced';
    private static final String IN_PROGRESS_PROSERV_STATUS = 'In progress';
    public static Boolean quoteTriggerExecuted = false;

    public class SalesAgreementBefore extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Map<Id, String> priceBookPlan = new Map<Id, String>();
            quoteTriggerExecuted = true;
            Boolean doPricebookSearch = false;
            Map <Id, Quote> quoteIdtoQuoteMap = new Map <Id, Quote>();
            Boolean containProServQuote = false;

            for(Quote quoteObj: (List<Quote>)Trigger.new) {
                //FG 06.06.2016 Set Initial Terms for Monthly - Contract Qoutes
                priceBookPlan.put(quoteObj.Pricebook2Id, '');
                if (
                    Trigger.isUpdate
                    && quoteObj.Pricebook2Id != ((Quote)Trigger.oldMap.get(quoteObj.Id)).Pricebook2Id
                ) {
                    doPricebookSearch = true;
                }

                if (!containProServQuote) {
                    containProServQuote = PROSERV_QUOTE_DEVELOPER_ID_SET.contains(quoteObj.RecordTypeId);
                }
            }

            if (Trigger.isInsert) {
                doPricebookSearch = true;
            }

            Boolean doSOQL = false;
            List<Pricebook2> pricebooks = new List<Pricebook2>();

            if(!priceBookPlan.isEmpty() && doPricebookSearch){
                for (Id pId : priceBookPlan.keySet()){
                    if (!QuoteTriggerHelper.pricebookMapStatic.containsKey(pId)){
                        doSOQL = true;
                    } else {
                        pricebooks.add(QuoteTriggerHelper.pricebookMapStatic.get(pId));
                    }
                }
                if (doSOQL) {
                    pricebooks = [SELECT Id, Plan__c, IsStandard FROM Pricebook2 WHERE Id IN: priceBookPlan.keySet() AND Plan__c != null];
                }
                for(Pricebook2 pBook:pricebooks){
                    priceBookPlan.put(pBook.Id, pBook.Plan__c);
                    QuoteTriggerHelper.pricebookMapStatic.put(pBook.Id, pBook);
                }
            }

            List<Quote> quoteList = Trigger.isDelete ? (List<Quote>)Trigger.old : (List<Quote>)Trigger.new;
            updateAccStaticMapOnQuoteTriggerHelper(!Trigger.isDelete, quoteList);
            updateEntStaticMapOnQuoteTriggerHelper(!Trigger.isDelete, quoteList);

            Map<String, Decimal> psConversionRate = new Map<String, Decimal>();
            Map<String, Decimal> currencyConversionRate = new Map<String, Decimal>();

            if (containProServQuote) {
                psConversionRate = getProServConversionRate();
				currencyConversionRate = getCurrencyConversionRate();
            }

            for(Quote quoteObj: (List<Quote>)Trigger.new) {
                Account acc = accountMapStatic.get(opportunityMapStatic.get(quoteObj.opportunityId).AccountId);
                Opportunity opp = opportunityMapStatic.get(quoteObj.OpportunityId);

                quoteIdtoQuoteMap.put(quoteObj.Id, quoteObj);

                //B-918 Populate channel manager to send approval email
                quoteObj.Inside_Sales_Rep__c = (
                    opp != null
                    ? opp.Inside_Sales_Rep__c
                    : null
                );

				// CRM-5112 Changes to Include custom lable to check for quote complexity and add new formula for QuotedHours
                String proserv_ProjectComplexity =  system.Label.Proserv_Project_Complexity;
                if (PROSERV_QUOTE_DEVELOPER_ID_SET.contains(quoteObj.RecordTypeId) && quoteObj.ProServUsers__c != null) {
                    if (psConversionRate.size() == 0
                        || psConversionRate.get(quoteObj.PSProjectComplexity__c) == null) {
                        quoteObj.TotalProjectHoursQuoted__c = quoteObj.ProServUsers__c * 1;
                    } else if (psConversionRate.get(quoteObj.PSProjectComplexity__c) != null && currencyConversionRate.get(quoteObj.CurrencyIsoCode) != null){
						if(proserv_ProjectComplexity.contains(quoteObj.PSProjectComplexity__c) && quoteObj.Total_One_Time__c != null ){
                            Decimal updatedLOEConversionrate = (currencyConversionRate.get(quoteObj.CurrencyIsoCode)) * (psConversionRate.get(quoteObj.PSProjectComplexity__c));
                            Decimal totalHours_SOW = (quoteObj.Total_One_Time__c / updatedLOEConversionrate);
                            quoteObj.TotalProjectHoursQuoted__c = totalHours_SOW.round(System.RoundingMode.HALF_UP);
                        } else {
                        Decimal totalHours = quoteObj.ProServUsers__c * psConversionRate.get(quoteObj.PSProjectComplexity__c);
                        quoteObj.TotalProjectHoursQuoted__c = totalHours.round(System.RoundingMode.HALF_UP);
						}
                    }
                }

                if (Trigger.isUpdate) {
                    Quote oldQuote = (Quote)Trigger.oldMap.get(quoteObj.Id);
                    quoteObj.Account__c = opp.AccountId;

                    // B-1618 PS Engagement Process Improvements
                    // Set status to in progress when ProServ User make any changes on Quote or QLIs
                    if(!byPassProServStatusUpdate
                        && PROSERV_QUOTE_DEVELOPER_ID_SET.contains(quoteObj.RecordTypeId)
                        && quoteObj.ProServ_Status__c == oldQuote.ProServ_Status__c
                        && QuoteHelper.PROSERVSTATUS_CANCELLED != quoteObj.ProServ_Status__c) {

                        // B-1894(if ProServ_Status__c was 'Synced' and filed values updated only on this fields() we should keep status 'Synced', otherwise - drop it to 'In progress' )
                        Boolean isFieldsToPassUpdated = isChangedAnyField(
                            quoteObj,
                            new Set<SObjectField>{
                                Quote.ExpirationDate,
                                Quote.Quote_Description__c,
                                Quote.JustificationandDescription__c,
                                Quote.Number_of_Hardware_Shipment_Phases__c,
                                Quote.Number_of_ProServ_Phases__c,
                                Quote.ProServProjectManager__c,
                                Quote.ProServSalesRep__c,
                                Quote.SOW_Type__c,
                                Quote.Signed_SOW__c,
                                Quote.ProServ_Sold_Date__c,
                                Quote.QuoteNumber,
                                Quote.TotalProjectHoursQuoted__c,
                                Quote.T_E__c,
                                Quote.UID_from_biz__c
                            }
                        );

                        if(!(isFieldsToPassUpdated && QuoteHelper.PROSERVSTATUS_SET_POST.contains(oldQuote.ProServ_Status__c))) {
                            quoteObj.ProServ_Status__c = QuoteHelper.PROSERVSTATUS_IN_PROGRESS;
                        }
                    }
                }

                if(Trigger.isInsert) {
                    if(PROSERV_QUOTE_DEVELOPER_ID_SET.contains(quoteObj.RecordTypeId) && acc != null && isBillingAddressPopulated(acc)) {
                        QuoteHelper.populateAddressOnQuote(quoteObj, acc);
                    }
                }

                if(Trigger.isInsert || (Trigger.isUpdate && ((Quote)Trigger.oldMap.get(quoteObj.Id)).Pricebook2Id != ((Quote)Trigger.newMap.get(quoteObj.Id)).Pricebook2Id)){
                    if(priceBookPlan.containsKey(quoteObj.Pricebook2Id) && priceBookPlan.get(quoteObj.Pricebook2Id).deleteWhitespace() == 'Monthly-Contract' || priceBookPlan.get(quoteObj.Pricebook2Id).deleteWhitespace() == 'Annual'){
                        quoteObj.Initial_Term_months__c = '24';
                        quoteObj.Term_months__c = '24';
                    }
                }

                populatePaymentPlan(quoteObj, priceBookPlan);

                if (!QuoteHelper.isNewBillingQuote(quoteObj) && acc != null) {
                    List<Entitlement__c> ents = accountIdToEntsMapStatic.get(acc.Id) != null ?
                        accountIdToEntsMapStatic.get(acc.Id) :
                        new List<Entitlement__c>();
                    QuoteHelper.setServiceEntitlementOnQuote(quoteObj, acc.Id, ents);
                }

                if (isChangedFieldTo(quoteObj, Quote.Auto_Renewal__c, false)) {
                    quoteObj.Term_months__c = null;
                }

                if (acc != null && quoteObj.End_Date__c > acc.Previous_Sales_Agreement_End_Date__c) {
                    quoteObj.isSalesAgreementExtension__c = true;
                }

                if (isChangedFieldToNonNull(quoteObj, Quote.Note_To_Customer__c)) {
                    quoteObj.Note_To_Customer__c = quoteObj.Note_To_Customer__c.replaceAll('float:[^;"]+', '');
                }
            }

            // Sales agreement active validation
            RingCentralVariousSettings__c settings = RingCentralVariousSettings__c.getInstance();

            if (!isSalesAgreementValidationExecuted && UserInfo.getUserId() != settings.DocuSign_Integration_User_ID__c) {
                List<Quote> quotes = getQuotesUnderAccount(Trigger.new);

                Map<Id, List<Quote>> quotesByAccountIds = new Map<Id, List<Quote>>();
                for (Quote quote: quotes) {
                    if (!quotesByAccountIds.containsKey(quote.AccountId)) {
                        quotesByAccountIds.put(quote.AccountId, new List<Quote>());
                    }
                    if (!quotesByAccountIds.get(quote.AccountId).contains(quote)) {
                        quotesByAccountIds.get(quote.AccountId).add(quote);
                    }
                }

                // Checking if account is master multiproduct
                Set<Id> accountIds = quotesByAccountIds.keySet();

                List<Account> accList =(List<Account>) new AccountSelector()
                    .selectMPAccountsWithTechAccountsByAccountIds(accountIds)
                    .executeQuery();

                for (Account acc : accList) {
                    if (acc.Master_Accounts__r.size() > 0) {
                        masterMultiProductAccounts.add(acc.Id);
                    }
                }

                for (Quote quoteObj: (List<Quote>)Trigger.new) {
                    List<Quote> accountQuotes = quotesByAccountIds.get(quoteObj.AccountId);
                    Boolean isAssignedToMasterMultiproductAccount = masterMultiProductAccounts.contains(quoteObj.AccountId);

                    Integer activeTechQuotesAssignedToAcc = 0;
                    Integer activeMasterQuotesAssignedToAcc = 0;

                    if (accountQuotes != null && isChangedFieldTo(quoteObj, Quote.Status, STATUS_ACTIVE)
                            || isChangedField(quoteObj, Quote.AccountId) && quoteObj.Status == STATUS_ACTIVE) {
                        for (Quote quote : accountQuotes) {
                            if (isAssignedToMasterMultiproductAccount && (quote.Status == STATUS_ACTIVE || (quote.Id == quoteObj.Id && quoteObj.Status == STATUS_ACTIVE))) {
                                if (quote.IsMultiProductTechnicalQuote__c) {
                                    activeTechQuotesAssignedToAcc++;
                                } else {
                                    activeMasterQuotesAssignedToAcc++;
                                }
                            } else if (quote.Status == STATUS_ACTIVE && quoteObj.Id != quote.Id
                                && !isAssignedToMasterMultiproductAccount
                                && !quote.IsMultiProductTechnicalQuote__c) {
                                quoteObj.addError('Associated Account already has an active Sales Agreement');
                            }

                        }
                    }

                    if (isAssignedToMasterMultiproductAccount) {
                        if (activeTechQuotesAssignedToAcc > 1) {
                            quoteObj.addError('Associated Master Multiproduct Account already has an active Tech Sales Agreement');
                        }

                        if (activeMasterQuotesAssignedToAcc > 1) {
                            quoteObj.addError('Associated Master Multiproduct Account already has an active Master Sales Agreement');
                        }
                    }
                }
                isSalesAgreementValidationExecuted = true;
            }

            if (Trigger.isUpdate) {
                validateRenewalTerms(Trigger.new);
            }
        }


        private Boolean isBillingAddressPopulated(Account acc) {
            return !(String.isBlank(acc.BillingStreet)
            || String.isBlank(acc.BillingCity)
            || String.isBlank(acc.BillingState)
            || String.isBlank(acc.BillingPostalCode)
            || String.isBlank(acc.BillingCountry));
        }

        private List<Quote> getQuotesUnderAccount(List<Quote> quotes) {
            List<Quote> quotesUnderAccounts = new List<Quote>();
            Set<Id> accountIdsToQuery = new Set<Id>();
            for (Quote quote: quotes) {
                if (quote.AccountId == null) {
                    continue;
                }
                if (accountIdToQuotes.containsKey(quote.AccountId)) {
                    quotesUnderAccounts.addAll(accountIdToQuotes.get(quote.AccountId));
                    continue;
                }
                accountIdsToQuery.add(quote.AccountId);
            }

            if (accountIdsToQuery.isEmpty()) {
                return quotesUnderAccounts;
            }

            List<Quote> quotesQueried = [
                SELECT Id, AccountId, Account.IsMultiProductTechnicalAccount__c, IsMultiProductTechnicalQuote__c, Status
                FROM Quote
                WHERE AccountId IN :accountIdsToQuery
            ];
            for (Quote q : quotesQueried) {
                if (accountIdToQuotes.get(q.AccountId) == null) {
                    accountIdToQuotes.put(q.AccountId, new List<Quote>());
                }
                accountIdToQuotes.get(q.AccountId).add(q);
            }
            quotesUnderAccounts.addAll(quotesQueried);
            return quotesUnderAccounts;
        }

        public void populatePaymentPlan(Quote quoteObj, Map<Id, String> priceBookPlanMap) {
            String plan = '';
            if (QuoteHelper.isNewBillingQuote(quoteObj) && String.isNotBlank(quoteObj.Package_Info__c)) {
                BillingWrappers.QuotePackageInfo packageInfo =
                    BillingWrappers.parseQuotePackageInfo(quoteObj.Package_Info__c);
                plan = packageInfo.duration;

            } else if (priceBookPlanMap.containsKey(quoteObj.Pricebook2Id)) {
                plan = priceBookPlanMap.get(quoteObj.Pricebook2Id);
            }

            if (String.isNotBlank(plan)) {
                quoteObj.Payment_Plan__c = plan;
            }

            String pbPlan = StringHelper.safeString(plan).deleteWhitespace().toLowerCase();
            if (new Set<String>{'monthly-contract', 'monthly'}.contains(pbPlan)) {
                quoteObj.Payment_Period__c = QuoteHelper.MONTHLY_PAYMENT_METHOD;
            } else if (pbPlan == 'annual') {
                quoteObj.Payment_Period__c = QuoteHelper.ANNUAL_PAYMENT_METHOD;
            }
        }

        @TestVisible
        private void validateRenewalTerms(List<Quote> quotes) {
            for (Quote q : quotes) {

                Boolean isNGBS = QuoteHelper.isNGBSQuote(q);
                Boolean hasContract = QuoteHelper.isQuoteHasContract(q);
                Boolean isRenewalChanged =
                    (isChangedField(q, Quote.Auto_Renewal__c) || isChangedField(q, Quote.Term_months__c)) &&
                    (q.Auto_Renewal__c && (String.isBlank(q.Term_months__c) || q.Term_months__c == '0'));

                if (isNGBS && isRenewalChanged && hasContract) {
                    q.addError(RENEWAL_VALIDATION_MESSAGE);
                }
            }
        }
    }

    public static Map<String, Decimal> getProServConversionRate() {
        Map<String, Decimal> rates = new Map<String, Decimal>();

        List<ProServ_LOE_Conversion_Rate__mdt> proServLOEConversionRates = (List<ProServ_LOE_Conversion_Rate__mdt>) new ProServLOEConversionRateSelector()
            .selectProServLOEConversionRates()
            .executeQuery();

        for (ProServ_LOE_Conversion_Rate__mdt rate : proServLOEConversionRates) {
            rates.put(rate.Project_Complexity__c, rate.LOE_Conversion_Rate__c);
        }
        return rates;
    }

	public static Map<String, Decimal> getCurrencyConversionRate() {
        Map<String, Decimal> currencyrates = new Map<String, Decimal>();

        List<CurrencyType> currencyTypes = (List<CurrencyType>) new CurrencyTypeSelector()
            .selectActiveCurrencyTypes()
            .executeQuery();

        for (CurrencyType ctype : currencyTypes) {
            currencyrates.put(ctype.IsoCode, ctype.ConversionRate.setScale(2));
        }
        return currencyrates;
    }

    /*
    *   @param accountMapStatic – map to update
    *   @param isInsertUpdate:
    *                   true: isInsert/isUpdate;
    *                   false: isDelete.
    *   @param quoteList – edited quotes list
    */
    @TestVisible
    private static void updateAccStaticMapOnQuoteTriggerHelper(Boolean isInsertUpdate, List<Quote> quoteList) {
        Set<Id> accIdsToQuery = new Set<Id>();
        Set<Id> oppIds = new Set<Id>();
        for (Quote q : quoteList) {
            oppIds.add(q.opportunityId);
        }

        if (oppIds.isEmpty()) {
            return;
        }

        selectOppsByIdsAndPopulateMaps(oppIds);

        if(isInsertUpdate) {
            for(Quote quoteObj : quoteList) {
                Id accId = opportunityMapStatic.get(quoteObj.opportunityId).AccountId;
                if(!accountMapStatic.containsKey(accId)) {
                    accIdsToQuery.add(accId);
                }
            }

            if(accIdsToQuery.size() > 0) {
                for(Account acc : [SELECT Id, Name,
                                    BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry,
                                    Active_Sales_Agreement__c, Active_Sales_Agreement__r.Status, IsMultiProductTechnicalAccount__c,
                                    Previous_Sales_Agreement_End_Date__c, RC_User_ID__c
                                   FROM Account
                                   WHERE Id IN :accIdsToQuery]) {
                    accountMapStatic.put(acc.Id, acc);
                }
            }
        } else {
            for(Quote quoteObj : quoteList) {
                Id oppId = quoteObj.opportunityId;
                Opportunity opp = opportunityMapStatic.get(oppId);
                Id accId = opp.AccountId;
                accountMapStatic.remove(accId);
            }
        }
    }

    @TestVisible
    private static void updateEntStaticMapOnQuoteTriggerHelper(Boolean isInsertUpdate, List<Quote> quoteList) {
        Set<Id> accIDsToQuery = new Set<Id>();
        for (Id accId : accountMapStatic.keySet()) {
            if (!accountIdToEntsMapStatic.containsKey(accId)) {
                accountIdToEntsMapStatic.put(accId, new List<Entitlement__c>());
                accIDsToQuery.add(accId);
            }
        }

        if (accIDsToQuery.size() == 0) {
            return;
        }

        List <Entitlement__c> entitlements = [
            SELECT
                Id, Product__r.Name, Product__r.Family, Product__r.Feature__c, Account__c, Quote__c
            FROM Entitlement__c
            WHERE Active__c = true AND Quote__c = null
            AND Account__c IN :accIDsToQuery
        ];

        for (Entitlement__c ent : entitlements) {
            accountIdToEntsMapStatic.get(ent.Account__c).add(ent);
        }

    }

    public class SalesAgreementAfter extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Set<Id> rollupOppIds = new Set<Id>();
            List<Account> filteredAccounts = new List<Account>();

            for (Quote quoteObj : Trigger.isDelete ? (List<Quote>)Trigger.old : (List<Quote>)Trigger.new) {
                //Calculate rollups on the opportunities in case OpportunityId,
                //TotalPrice or ProServ_Status__c is changed.
                Id oppId;
                if (
                    Trigger.isUpdate
                    && (
                        isChangedField(quoteObj, Quote.OpportunityId)
                        || isChangedField(quoteObj, Quote.TotalPrice)
                        || isChangedField(quoteObj, Quote.ProServ_Status__c)
                    )
                ) {
                    rollupOppIds.add(quoteObj.OpportunityId);

                    if (isChangedField(quoteObj, Quote.OpportunityId)) {
                        rollupOppIds.add(((Quote) Trigger.oldMap.get(quoteObj.id)).OpportunityId);
                    }
                }
            }

            List<Quote> quoteList = Trigger.isDelete ? (List<Quote>)Trigger.old : (List<Quote>)Trigger.new;
            updateAccStaticMapOnQuoteTriggerHelper(!Trigger.isDelete, quoteList);

            Set<Id> masterQuoteIds = new Set<Id>();
            if (Trigger.isInsert || Trigger.isUpdate) {
                for (Quote quoteObj : (List<Quote>) Trigger.new) {
                    masterQuoteIds.add(quoteObj.IsMultiProductTechnicalQuote__c ? quoteObj.MasterQuote__c : quoteObj.Id);
                }
                masterQuoteIdToServiceInfoMap = masterQuoteIdToServiceInfoMap.size() > 0 ? masterQuoteIdToServiceInfoMap : QuoteHelper.getMasterQuoteIdToServiceInfosMap(masterQuoteIds);
            }

            Map<Id,Boolean> accountIdToIsMPUBMap = new Map<Id,Boolean>();

            if (Trigger.isInsert) {
                for (Quote quoteObj : (List<Quote>)Trigger.new) {
                    if (quoteObj.Status == STATUS_ACTIVE) {
                        Opportunity opp = opportunityMapStatic.get(quoteObj.OpportunityId);
                        Account acc = accountMapStatic.get(opp.AccountId);
                        accountIdToIsMPUBMap = AccountHelper.updateAccountIdToIsMPUBMap(accountIdToIsMPUBMap, acc);
                        Boolean isMPUBAccount = accountIdToIsMPUBMap.get(acc.Id);
                        Id quoteId = quoteObj.MasterQuote__c != null ? quoteObj.MasterQuote__c : quoteObj.Id;
                        Boolean isMPUB = isMPUBAccount
                            || masterQuoteIdToServiceInfoMap.get(quoteId) != null
                            && masterQuoteIdToServiceInfoMap.get(quoteId).size() > 0;
                        if (
                            (
                                (
                                    acc.Active_Sales_Agreement__c == null
                                    || acc.Active_Sales_Agreement__r.Status != STATUS_ACTIVE
                                )
                                && (!isMPUB || !quoteObj.IsMultiProductTechnicalQuote__c)
                            )
                            && !filteredAccounts.contains(acc)
                        ) {
                            acc.Active_Sales_Agreement__c = quoteObj.id;
                            filteredAccounts.add(acc);
                        } else if (!isMPUB || isMPUB && !quoteObj.IsMultiProductTechnicalQuote__c) {
                            quoteObj.addError('Associated Account already has an active Sales Agreement');
                        }
                    }
                }
                if (!filteredAccounts.isEmpty()) {
                    update filteredAccounts;
                }

            }

            if (Trigger.isUpdate) {
                Set<Id> accIds = new Set<Id>();
                for (Quote quoteObj : (List<Quote>)Trigger.new) {
                    Opportunity opp = opportunityMapStatic.get(quoteObj.OpportunityId);
                    Account acc = accountMapStatic.get(opp.AccountId);

                    if (isChangedFieldTo(quoteObj, Quote.Status, QuoteHelper.QUOTE_STATUS_TERMINATED) && acc?.Active_Sales_Agreement__c == quoteObj.Id) {
                        acc.Active_Sales_Agreement__c = null;
                        filteredAccounts.add(acc);
                    }

                    if (quoteObj.QuoteType__c == TYPE_AGREEMENT || String.isEmpty(quoteObj.QuoteType__c)
                            || isChangedFieldFrom(quoteObj, Quote.QuoteType__c, TYPE_AGREEMENT)) {
                        if (acc != null && !filteredAccounts.contains(acc)) {
                            Boolean isAssignedToMasterMultiproductAccount = masterMultiProductAccounts.contains(acc.Id);

                            Integer activeTechQuotesAssignedToAcc = 0;
                            Integer activeMasterQuotesAssignedToAcc = 0;

                            if (isChangedFieldTo(quoteObj, Quote.Status, STATUS_ACTIVE)) {
                                if (isAssignedToMasterMultiproductAccount) {
                                    if (quoteObj.IsMultiProductTechnicalQuote__c) {
                                        activeTechQuotesAssignedToAcc++;
                                    } else {
                                        if (acc.Active_Sales_Agreement__c == null
                                            || acc.Active_Sales_Agreement__r.Status != STATUS_ACTIVE) {
                                            acc.Active_Sales_Agreement__c = quoteObj.Id;
                                            filteredAccounts.add(acc);

                                            activeMasterQuotesAssignedToAcc++;
                                        }
                                    }

                                    if (activeTechQuotesAssignedToAcc > 1) {
                                        quoteObj.addError('Associated Master Multiproduct Account already has an active Tech Sales Agreement');
                                    }

                                    if (activeMasterQuotesAssignedToAcc > 1) {
                                        quoteObj.addError('Associated Master Multiproduct Account already has an active Master Sales Agreement');
                                    }
                                } else {
                                    RingCentralVariousSettings__c settings = RingCentralVariousSettings__c.getInstance(); // Bypass of validation only for DocuSign Integration
                                    accountIdToIsMPUBMap = AccountHelper.updateAccountIdToIsMPUBMap(accountIdToIsMPUBMap, acc);
                                    Boolean isMPUBAccount = accountIdToIsMPUBMap.get(acc.Id);
                                    Id quoteId = quoteObj.MasterQuote__c != null ? quoteObj.MasterQuote__c : quoteObj.Id;
                                    Boolean isMPUB = isMPUBAccount
                                        || masterQuoteIdToServiceInfoMap.get(quoteId) != null
                                        && masterQuoteIdToServiceInfoMap.get(quoteId).size() > 0;
                                    if ((acc.Active_Sales_Agreement__c == null
                                        || acc.Active_Sales_Agreement__r.Status != STATUS_ACTIVE
                                        || UserInfo.getUserId() == settings.DocuSign_Integration_User_ID__c)
                                        && (!isMPUB || !quoteObj.IsMultiProductTechnicalQuote__c)) {
                                            acc.Active_Sales_Agreement__c = quoteObj.Id;
                                            filteredAccounts.add(acc);
                                    } else if (!isMPUB || isMPUB && !quoteObj.IsMultiProductTechnicalQuote__c) {
                                        quoteObj.addError('Associated Account already has an active Sales Agreement');
                                    }
                                }

                            }
                            if (acc.Active_Sales_Agreement__c == quoteObj.Id && isChangedFieldFrom(quoteObj, Quote.Status, STATUS_ACTIVE)) {
                                acc.Active_Sales_Agreement__c = null;
                                acc.Previous_Sales_Agreement_End_Date__c = ((Quote) Trigger.oldMap.get(quoteObj.Id)).End_Date__c;
                                filteredAccounts.add(acc);
                            }
                        }
                    }

                    if (isChangedFieldTo(quoteObj, Quote.Status, 'Active')) {
                        if (acc?.Id != null) {
                        	accIds.add(acc.Id);
                        }
                    }
                }


                if (!accIds.isEmpty()) {
                    List<Approval__c> invoices = new List<Approval__c>([
                            SELECT Id, Status__c, Account__c, Name
                            FROM Approval__c
                            WHERE Record_Type_Name__c = 'Invoicing Request' AND Account__c IN :accIds
                            AND Status__c != 'Completed' AND Status__c != 'Approved'

                    ]);
                    if (!invoices.isEmpty()) {

                        List<Contract> contracts = new List<Contract>([
                                SELECT Id, LastModifiedDate, AccountId, Name
                                FROM  Contract
                                WHERE AccountId IN :accIds AND Status = 'Active'
                        ]);
                        Map<Id, Contract> contractToId = new Map<Id, Contract>();
                        for (Contract contract: contracts) {
                            if (contractToId.containsKey(contract.AccountId) && contractToId.get(contract.AccountId).LastModifiedDate < contract.LastModifiedDate
                                    || !contractToId.containsKey(contract.AccountId)) {
                                contractToId.put(contract.AccountId, contract);
                            }
                        }

                        Map<Id, List<Approval__c>> accIdToApprovalList = new Map<Id, List<Approval__c>>();
                        for (Approval__c appr: invoices) {
                            if (accIdToApprovalList.containsKey(appr.Account__c)){
                                accIdToApprovalList.get(appr.Account__c).add(appr);
                            } else {
                                accIdToApprovalList.put(appr.Account__c, new List<Approval__c>{appr});
                            }
                        }

                        EmailTemplate templateInvoiceRequested = ApprovalTriggerHandler.getEmailTemplate('Invoicing_Request_Quote_Activation_Notification');
                        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
                        List<User> invoiceApprovalGroup = ApprovalHelperCls.findInvoiceUsers();
                        List<Id> emails = new List<Id>();
                        for(User u: invoiceApprovalGroup) {
                            if (String.IsNotBlank(u.Email)) {
                                emails.add(u.Id);
                            }
                        }
                        for (Quote quoteObj: (List<Quote>)Trigger.new) {
                            if (accIdToApprovalList.containsKey(quoteObj.Account__c)) {
                                for (Approval__c appr: accIdToApprovalList.get(quoteObj.Account__c)) {
                                    ApprovalHelperCls.InternalEmail mail = new ApprovalHelperCls.InternalEmail(emails,
                                            templateInvoiceRequested.Subject, templateInvoiceRequested.HtmlValue);
                                    mail.addParameter('Account.URL', BASE_URL + '/' + quoteObj.Account__c);
                                    mail.addParameter('Account.Name', accountMapStatic.get(quoteObj.Account__c).Name);
                                    mail.addParameter('Approval.URL', BASE_URL + '/' + appr.Id);
                                    mail.addParameter('Approval.Name', appr.Name);
                                    mail.addParameter('Opportunity.URL', BASE_URL + '/' + quoteObj.OpportunityId);
                                    mail.addParameter('Opportunity.Name', opportunityMapStatic.get(quoteObj.OpportunityId).Name);
                                    if (contractToId.containsKey(quoteObj.Account__c)) {
                                        mail.addParameter('Contract.URL', BASE_URL + '/' + contractToId.get(quoteObj.Account__c).Id);
                                        mail.addParameter('Contract.Name', contractToId.get(quoteObj.Account__c).Name);
                                    } else {
                                        mail.addParameter('Contract.Name', 'None');
                                    }
                                    mail.addParameter('Quote.URL', BASE_URL + '/' + quoteObj.Id);
                                    mail.addParameter('Quote.Name', quoteObj.Name);
                                    mails.addAll(mail.getMails());
                                }
                            }
                        }
                        if (!mails.isEmpty()) {
                            Messaging.sendEmail(mails);
                        }
                    }
                }
                if (!filteredAccounts.isEmpty()) {
                    update filteredAccounts;
                }
            }

            if (Trigger.isDelete && !System.isFuture() && !System.isBatch()) {
                deleteTechnicalQuotes(opportunityMapStatic.keySet());
            }
        }
    }

    @future
    public static void deleteTechnicalQuotes(Set<Id> oppIds) {
        delete (List<Quote>) new QuoteSelector()
            .selectMultiProductTechnicalQuotesForClearUp(oppIds)
            .executeQuery();
    }

    private static Map<Id, PriceBook2> staticTiersMap = new Map<Id, PriceBook2>();

    private static Set<Id> diffBetweenIdSets(Set<Id> setA, Set<Id> setB) {

        // avoid params changes
        setA = setA.clone();
        setB = setB.clone();

        Set<Id> result = setA.clone();
        result.removeAll(setB);
        setB.removeAll(setA);
        result.addAll(setB);

        return result;
    }

    public class SetDefaultLineItems extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Set<Id> priceBooksIds = new Set<Id>();
            //B-75
            Set<Id> quantityUpdateQuoteLineItems = new Set<Id>();
            //B-117

            if (Trigger.isBefore) {
                Boolean doQuantityUpdate = false;
                for (Quote qt: (List<Quote>) Trigger.new) {
                    if (qt.Pricebook2Id != null) {
                        priceBooksIds.add(qt.Pricebook2Id);
                    }

                    if (qt.Total_Number_of_Digital_Lines__c == null || qt.Total_Number_of_Digital_Lines__c <= 0) {
                        doQuantityUpdate = true;
                    }
                }

                if (doQuantityUpdate && !staticTiersMap.keySet().containsAll(priceBooksIds)) {
                    Set<Id> diffSet = diffBetweenIdSets(priceBooksIds, staticTiersMap.keySet());

                    Set<Id> priceBookIdsToSelect = diffBetweenIdSets(staticTiersMap.keySet(), diffSet);
                    List<PriceBook2> tiers = new List<PriceBook2>();
                    if (!priceBookIdsToSelect.isEmpty()) {
                        tiers = [
                            SELECT Id, Line_Range_Min__c
                            FROM PriceBook2
                            WHERE Id IN (
                                SELECT Pricebook2Id
                                FROM PriceBookEntry
                                WHERE (Product2.Family = 'Tier' OR Product2.Family = 'Service')
                                AND Product2.IsActive = true
                                AND Pricebook2Id IN :priceBookIdsToSelect
                            )
                            AND IsActive = true
                        ];
                    }
                    if (!tiers.isEmpty()) {
                        for (PriceBook2 tier : tiers) {
                            staticTiersMap.put(tier.Id, tier);
                        }
                    }
                }

                Set<Id> quoteIdSet = new Set<Id>();
                for (Quote qt : (List<Quote>) Trigger.new) {
                    Boolean isNgbsQuoteWithEmptyTotalNumberOfDL = QuoteHelper.isNGBSQuote(qt)
                        && (qt.Total_Number_of_Digital_Lines__c == null || qt.Total_Number_of_Digital_Lines__c < 0);
                    if (isNgbsQuoteWithEmptyTotalNumberOfDL && Trigger.isUpdate) {
                        quoteIdSet.add(qt.Id);
                    }
                }

                List<QuoteLineItem> qliList = new List<QuoteLineItem>();

                if (!quoteIdSet.isEmpty()) {
                    qliList = new QuoteLineItemSelector()
                            .selectServiceQlisByQuoteIds(quoteIdSet)
                            .executeQuery();
                }

                Map<Id, List<QuoteLineItem>> quoteIdToQliListMap = new Map<Id, List<QuoteLineItem>>();

                for (QuoteLineItem qli : qliList) {
                    if (!quoteIdToQliListMap.containsKey(qli.QuoteId)) {
                        quoteIdToQliListMap.put(qli.QuoteId, new List<QuoteLineItem>());
                    }
                    quoteIdToQliListMap.get(qli.QuoteId).add(qli);
                }

                for (Quote qt : (List<Quote>) Trigger.new) {
                    if (Trigger.isInsert) {
                        qt.ContactId = opportunityMapStatic.get(qt.OpportunityId).Primary_Opportunity_Contact__c;
                    }

                    Decimal lineRangeMin = NumberHelper.toNumber(staticTiersMap.get(qt.Pricebook2Id)?.Line_Range_Min__c);

                    if (qt.Total_Number_of_Digital_Lines__c == null || qt.Total_Number_of_Digital_Lines__c <= 0) {
                        qt = setTotalNumberOfDL(qt, quoteIdToQliListMap, lineRangeMin, Trigger.isUpdate);
                    }
                }
                return;
            }

            if (!Trigger.isUpdate) {
                //Collect tier ids to select products
                for (Quote qt : (List<Quote>) Trigger.new) {
                    if(qt.Pricebook2Id != null) {
                        priceBooksIds.add(qt.Pricebook2Id);
                    }
                }

                DefaultLineItemsTriggerHandler.setDefaultLineItems((List<Quote>) Trigger.new, priceBooksIds);
                return;
            }

            //B-75
            Decimal minLines = 0;
            Decimal maxLines = 0;
            Quote quoteLines;
            Boolean doQuantityUpdate = false;

            for (Quote qt : (List<Quote>) Trigger.new) {
                if (qt.Total_Number_of_Digital_Lines__c != ((Quote) Trigger.oldMap.get(qt.Id)).Total_Number_of_Digital_Lines__c
                    && !QuoteHelper.isNewBillingQuote(qt)
                ) {
                    quantityUpdateQuoteLineItems.add(qt.Id);
                }
                if (qt.Pricebook2Id != ((Quote) Trigger.oldMap.get(qt.Id)).Pricebook2Id) {
                    priceBooksIds.add(qt.Pricebook2Id);
                }
                if (qt.Total_Number_of_Digital_Lines__c != ((Quote) Trigger.oldMap.get(qt.Id)).Total_Number_of_Digital_Lines__c) {
                    doQuantityUpdate = true;
                }
            }

            if (priceBooksIds.size() > 0) {
                DefaultLineItemsTriggerHandler.setDefaultLineItems(Trigger.new, priceBooksIds);
            }

            if (!doQuantityUpdate || quantityUpdateQuoteLineItems.isEmpty()) {
                return;
            }

            List<QuoteLineItem> quoteLineItems = (List<QuoteLineItem>) new QuoteLineItemSelector()
                .selectQuoteLineItemsWithTierOrServiceProductByQuoteIds(quantityUpdateQuoteLineItems)
                .executeQuery();

            List<QuoteLineItem> quoteLineItemsUpdateQuantity = new List<QuoteLineItem>();
            for (QuoteLineItem qli : quoteLineItems) {
                quoteLines = (Quote) Trigger.newMap.get(qli.QuoteId);

                if (qli.Product2.Family != Product2Helper.FAMILY_TIER
                    && qli.Product2.Family != Product2Helper.FAMILY_SERVICE
                ) {
                    if (QuoteLineItemTriggerHelper.qliIdsToBypassQuantityChange.contains(qli.Id)) {
                        continue;
                    }

                    minlines = qli.PriceBookEntry.Min_Quantity__c != null
                               ? qli.PriceBookEntry.Min_Quantity__c * quoteLines.Total_Number_of_Digital_Lines__c
                               : 0;

                    maxlines = qli.PriceBookEntry.Max_Quantity__c != null
                               ? qli.PriceBookEntry.Max_Quantity__c * quoteLines.Total_Number_of_Digital_Lines__c
                               : 999999999;

                    if (qli.Quantity > 0 && qli.Quantity < minLines) {
                        qli.Quantity = minLines;
                        quoteLineItemsUpdateQuantity.add(qli);
                    } else if (qli.Quantity > maxLines) {
                        qli.Quantity = maxLines;
                        quoteLineItemsUpdateQuantity.add(qli);
                    }
                } else if (quoteLines.Total_Number_of_Digital_Lines__c != null
                    && qli.Quantity != quoteLines.Total_Number_of_Digital_Lines__c
                ) {
                    QuoteLineItemHelper.setResultingQuantity(qli, quoteLines.Total_Number_of_Digital_Lines__c, qli.Entitlement__r);
                    quoteLineItemsUpdateQuantity.add(qli);
                }
            }

            try {
                if (!quoteLineItemsUpdateQuantity.isEmpty()) {
                    update quoteLineItemsUpdateQuantity;
                }
            } catch (DmlException e) {
                String id = e.getDmlId(0);
                for (QuoteLineItem iqli : quoteLineItemsUpdateQuantity){
                    if (iqli.Id == id) {
                        ((Quote) Trigger.newMap.get(iqli.QuoteId)).addError(e.getDmlMessage(0));
                        break;
                    }
                }
            }
        }

        @TestVisible
        private Quote setTotalNumberOfDL(
                Quote qt,
                Map<Id, List<QuoteLineItem>> quoteIdToQliListMap,
                Decimal lineRangeMin,
                Boolean isUpdate
        ) {

            if (qt == null) {
                return null;
            }

            isUpdate = BooleanHelper.toBoolean(isUpdate);

            if (lineRangeMin == null || lineRangeMin < 0) {
                lineRangeMin = 0;
            }

            if (!QuoteHelper.isNGBSQuote(qt) || !isUpdate) {
                qt.Total_Number_of_Digital_Lines__c = lineRangeMin;
                return qt;
            }

            List<QuoteLineItem> qliList = quoteIdToQliListMap.containsKey(qt.Id)
                    ? quoteIdToQliListMap.get(qt.Id)
                    : new List<QuoteLineItem>();

            QuoteLineItem serviceQLI = QuoteLineItemHelper.findActiveServicePlan(qliList);
            qt.Total_Number_of_Digital_Lines__c = serviceQLI != null
                    ? QuoteLineItemHelper.getResultingQuantity(serviceQLI)
                    : 0;

            return qt;
        }
    }

    public class SetFirstQuotePrimary extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Set<Id> oppIdSet = new Set<Id>();
            Map<String, Quote> hasPrimaryMap = new Map<String, Quote>();
            for (Quote qt : (List<Quote>) Trigger.New) {
                oppIdSet.add(qt.OpportunityId);
            }

            Map<Id, RecordTypeInfo> rtMapByIds = Quote.SObjectType.getDescribe().getRecordTypeInfosById();

            //for all Opportunites in Trigger.New quotes check that there are quotes that are old ones (not in TriggerNew)
            List<Quote> allOldQuotesToCheck = [
                SELECT Id, OpportunityId, Opportunity.Is_Billing_Opportunity__c, RecordTypeId
                FROM Quote
                WHERE OpportunityId IN :oppIdSet
            ];
            for (Quote qt : allOldQuotesToCheck) {
                String rtName = rtMapByIds.containsKey(qt.RecordTypeId) ? rtMapByIds.get(qt.RecordTypeId).getName() : '';
                String key = 'oldwizard';
                if (rtName == QuoteHelper.RT_NAME_BILLING) {
                    key = QuoteHelper.RT_NAME_BILLING;
                } else if (rtName == QuoteHelper.RT_NAME_POC_QUOTE) {
                    key = QuoteHelper.RT_NAME_POC_QUOTE;
                }
                hasPrimaryMap.put(qt.OpportunityId + key, qt);
            }
            //set for every fitting opportunity one primary quote
            for (Quote qt : (List<Quote>) Trigger.New) {
                String rtName = rtMapByIds.get(qt.RecordTypeId).getName();
                String key = 'oldwizard';
                if (rtName == QuoteHelper.RT_NAME_BILLING) {
                    key = QuoteHelper.RT_NAME_BILLING;
                } else if (rtName == QuoteHelper.RT_NAME_POC_QUOTE) {
                    key = QuoteHelper.RT_NAME_POC_QUOTE;
                }
                Boolean isBillingOpportunity = hasPrimaryMap.get(qt.OpportunityId + QuoteHelper.RT_NAME_BILLING) != null
                    && hasPrimaryMap.get(qt.OpportunityId + QuoteHelper.RT_NAME_BILLING).Opportunity.Is_Billing_Opportunity__c
                    || hasPrimaryMap.get(qt.OpportunityId + QuoteHelper.RT_NAME_POC_QUOTE) != null
                    && hasPrimaryMap.get(qt.OpportunityId + QuoteHelper.RT_NAME_POC_QUOTE).Opportunity.Is_Billing_Opportunity__c;
                if (!qt.IsMultiProductTechnicalQuote__c && hasPrimaryMap.get(qt.OpportunityId + key) == null
                    && !(isBillingOpportunity
                        && (rtName == QuoteHelper.RT_NAME_PROSERV
                            || rtName == QuoteHelper.RT_NAME_CONTACT_CENTER
                            || rtName == QuoteHelper.RT_NAME_CC_PROSERV))
                    ) {
                    qt.isPrimary__c = true;
                    hasPrimaryMap.put(qt.OpportunityId + key, qt);
                }
            }
        }
    }

    public class SetLastModifiedPrimaryOnDeletingPrimaryQuote extends Triggers.TriggerHandlerBase {
        override public void handle() {
            //for all deleted Primary Quotes we should took LastModQuote with ~OpportunityId and make it Primary
            Map<String, Boolean> OppSetNewPrimary = new Map<String, Boolean>();
            Set<Id> rtIds = new Set<Id>();
            Set<Id> opportunityIds = new Set<Id>();

            Map<Id, RecordTypeInfo> rtMapByIds = Quote.SObjectType.getDescribe().getRecordTypeInfosById();

            for (Quote q : (List<Quote>)Trigger.Old) {
                if (q.isPrimary__c == True) {
                    String rtName = rtMapByIds.get(q.RecordTypeId).getName();
                    String key = rtName == 'Sales Quote v2' ? 'billing' : 'oldwizard';
                    OppSetNewPrimary.put(q.OpportunityId + key, true);
                    rtIds.add(q.RecordTypeId);
                    opportunityIds.add(q.OpportunityId);
                }
            }
            Map<Id, Opportunity> opptyToId = new Map<Id, Opportunity>(
                    (List<Opportunity>) new OpportunitySelector()
                            .selectOpportunitiesByIds(opportunityIds)
                            .executeQuery()
            );

            List<Quote> allOldQuotesToCheck = [
                    SELECT Id, OpportunityId, RecordTypeId, Package_Info__c, Upsell_Status__c, IsMultiProductTechnicalQuote__c
                    FROM Quote
                    WHERE OpportunityId IN :opportunityIds
                    AND RecordTypeId IN :rtIds
                    AND Id NOT IN :Trigger.oldMap.keyset()
                    ORDER BY LastModifiedDate DESC
            ];
            List<Quote> primaryQuotesToUpdate = new List<Quote>();
            List<Opportunity> oppsToUpdate = new List<Opportunity>();
            Opportunity oppToUpdate;

            for (Quote q: allOldQuotesToCheck) {
                String rtName = rtMapByIds.get(q.RecordTypeId).getName();
                String key = rtName == 'Sales Quote v2' ? 'billing' : 'oldwizard';

                if (!q.IsMultiProductTechnicalQuote__c && OppSetNewPrimary.get(q.OpportunityId + key) == True) {
                    q.isPrimary__c = True;
                    primaryQuotesToUpdate.add(q);
                    OppSetNewPrimary.put(q.OpportunityId + key, False);
                    oppToUpdate = QuoteHelper.getOpportunityToUpdateTierName(opptyToId.get(q.OpportunityId), q);

                    if (oppToUpdate != null) {
                        oppsToUpdate.add(oppToUpdate);
                    }
                }
            }
            if (primaryQuotesToUpdate.size() > 0) {
                update primaryQuotesToUpdate;
            }
            if (!oppsToUpdate.isEmpty()) {
                OpportunityHelper.setOpptyCLMEnable(oppsToUpdate);

                Triggers.switchOff();
                update oppsToUpdate;
                Triggers.switchOn();
            }
        }
    }

    public class SetPrimaryQuote extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Set<Id> primaryQuoteIds = new Set<Id>();
            Set<Id> oppIds = new Set<Id>();
            Set<Id> primaryQuoteOppIds = new Set<Id>();
            Set<Id> rtIds = new Set<Id>();
            Set<Id> wasPrimaryQuotesIds = new Set<Id>();
            Map<Id, Boolean> oppHavePrimaryQuoteInTriggerNew = new Map<Id, Boolean>();

            List<Opportunity> oppToUpdate = new List<Opportunity>();

            for (Quote q : (List<Quote>) Trigger.new) {
                oppIds.add(q.OpportunityId);
                // old opps are required for some further logic
                oppIds.add(((Quote) Trigger.oldMap.get(q.Id)).OpportunityId);
            }

            selectOppsByIdsAndPopulateMaps(oppIds);

            for (Quote qt : (List<Quote>)Trigger.new) {
                if (qt.isPrimary__c && !((Quote)Trigger.oldMap.get(qt.Id)).isPrimary__c) {
                    primaryQuoteIds.add(qt.Id);
                    primaryQuoteOppIds.add(qt.OpportunityId);
                    rtIds.add(qt.RecordTypeId);

                    oppToUpdate.add(opportunityMapStatic.get(qt.OpportunityId));
                }
                if (!qt.isPrimary__c && ((Quote)Trigger.oldMap.get(qt.Id)).isPrimary__c) {
                    wasPrimaryQuotesIds.add(qt.Id);
                    oppHavePrimaryQuoteInTriggerNew.put(qt.OpportunityId, false);
                }
            }

            if (primaryQuoteIds.isEmpty() && oppHavePrimaryQuoteInTriggerNew.isEmpty()) {
                return;
            }

            Set<Id> oppIdsToWorkWith = new Set<Id>();
            Set<Id> oppHavePrimaryQuoteInTriggerNewIds = oppHavePrimaryQuoteInTriggerNew.keySet();
            oppIdsToWorkWith.addAll(primaryQuoteOppIds);
            oppIdsToWorkWith.addAll(oppHavePrimaryQuoteInTriggerNewIds);
            List<Quote> quotesOnOpportunities = (List<Quote>) new QuoteSelector()
                .selectPrimaryQuotesByOpportunityIds(oppIdsToWorkWith)
                .selectField('OpportunityId')
                .executeQuery();

            Set<Id> masterQuoteIds = new Set<Id>();
            for (Quote q : quotesOnOpportunities) {
               if (!q.IsMultiProductTechnicalQuote__c) {
                    masterQuoteIds.add(q.Id);
               }
            }

            masterQuoteIdToServiceInfoMap = QuoteHelper.getMasterQuoteIdToServiceInfosMap(masterQuoteIds);
            Map<Id,Boolean> accountIdToIsMPUBMap = new Map<Id,Boolean>();

            List<Quote> quotesToUpdate = new List<Quote>();
            List<Quote> quotesToCheck = new List<Quote>();
            for (Quote qt : quotesOnOpportunities) {
                Account acc = accountMapStatic.get(qt.AccountId);
                accountIdToIsMPUBMap = AccountHelper.updateAccountIdToIsMPUBMap(accountIdToIsMPUBMap, acc);
                Boolean isMPUBAccount = accountIdToIsMPUBMap.get(acc.Id);
                Boolean isMPUBMasterQuote = masterQuoteIdToServiceInfoMap.get(qt.Id) != null
                    && masterQuoteIdToServiceInfoMap.get(qt.Id).size() > 0;
                if (!primaryQuoteIds.contains(qt.Id)
                    && primaryQuoteOppIds.contains(qt.OpportunityId)
                    && rtIds.contains(qt.RecordTypeId)
                    && (!isMPUBAccount || !isMPUBMasterQuote)
                ) {
                    quotesToUpdate.add(qt);
                }

                if (oppHavePrimaryQuoteInTriggerNewIds.contains(qt.OpportunityId)) {
                    quotesToCheck.add(qt);
                }
            }

            if (!quotesToUpdate.isEmpty()) {
                // B-1327 (Defect) : Field Estimated 12 Month Booking on Opportunity takes Data not from primary Quote
                for (Quote uqt : quotesToUpdate) {
                    uqt.isPrimary__c = false;
                }

                update quotesToUpdate;
                update oppToUpdate;
            }

            if (oppHavePrimaryQuoteInTriggerNew.isEmpty()) {
                return;
            }

            if (quotesToCheck.size() > 0) {
                for (Quote quoteInList : quotesToCheck) {
                    oppHavePrimaryQuoteInTriggerNew.put(quoteInList.OpportunityId, true);
                }
            }
            for (Quote quoteToCheck : (List<Quote>) Trigger.new) {
                if (wasPrimaryQuotesIds.contains(quoteToCheck.Id)
                    && !oppHavePrimaryQuoteInTriggerNew.get(quoteToCheck.OpportunityId)
                    && !quoteToCheck.IsMultiProductTechnicalQuote__c
                ) {
                    quoteToCheck.addError('You should always have a Primary Quote. If you want to change it just make another Quote a Primary one');
                }
            }
        }
    }


    public class ValidateQuoteBeforeDelete extends Triggers.TriggerHandlerBase {

        public final String DELETE_QUOTE_ERROR_MESSAGE = 'Deletion of Active Sales Agreements, Quotes in Closed Won Opportunities or last Sales Quotes is not allowed';
        private final String QUOTE_ACTIVE_STATUS_NAME = 'Active';
        private final String QUOTE_UPSELL_STATUS_NAME = 'Upsell';

        override public void handle() {

            List<Quote> quotesToDelete = [SELECT Id, Name, Status, OpportunityId, Opportunity.StageName, Account.RC_User_ID__c, RecordTypeId, RecordType.DeveloperName, IsMultiProductTechnicalQuote__c FROM Quote WHERE Id IN :Trigger.old];

            // map where Opportunity id = List<Quote>, except quotes from trigger(except quotes to delete)
            Map<Id, List<Quote>> oppIdToQuoteListMap = buildOppIdToQuoteListMap(quotesToDelete);


            List<QuoteLineItem> qliToDeleteList = new List<QuoteLineItem>();

            // List of quote line items with entitlements
            // (we 'restore' these qlis from Entitlements instead of deleting them when ProServ/CCProServ Quote was deleted)
            List<QuoteLineItem> qliWithEntitlements = new List<QuoteLineItem>();

            for (Quote q : quotesToDelete) {
                Opportunity o = opportunityMapStatic.get(q.OpportunityId);

                // List of quote line items for deleting from primary quote when ProServ Quote was deleted
                List<QuoteLineItem> qliProServ = new List<QuoteLineItem>();

                // List of quote line items for deleting from primary quote when CCProServ Quote was deleted
                List<QuoteLineItem> qliCCProServ = new List<QuoteLineItem>();

                Boolean salesQuoteNotFoundOnOpp = false;
                Boolean isProServQuote = false;
                Boolean isCCProServQuote = false;

                if( q.RecordTypeId == PROSERV_QUOTE_RT_ID ) {
                    isProServQuote = true;
                }else if( q.RecordTypeId == CC_PROSERV_QUOTE_RT_ID ) {
                    isCCProServQuote = true;
                }

                if( oppIdToQuoteListMap.get(q.OpportunityId).size() == 0 ) {
                    salesQuoteNotFoundOnOpp = true;
                }else {

                    Integer salesQuoteCount = 0;
                    for(Quote item : oppIdToQuoteListMap.get(q.OpportunityId)) {
                        if((item.RecordTypeId == null
                            || item.RecordTypeId == SALES_QUOTE_RT_ID)
                            && item.IsMultiProductTechnicalQuote__c == false
                        ) {
                            salesQuoteCount += 1;

                            // if Upsell_Status__c == 'Upsell' and QLI has Entitlement - do not delete qli
                            Boolean isUpsellQuote = item.Upsell_Status__c == QUOTE_UPSELL_STATUS_NAME;

                            if (isProServQuote || isCCProServQuote) {
                                for (QuoteLineItem qli : item.QuoteLineItems) {
                                    Boolean qliHasEntitlement = qli.Entitlement__c != null;

                                    if (qli.Product2.Sub_Category__c == PROSERV_PRODUCT_SUBCATEGORY
                                        || qli.Item_type__c == QuotingToolQuoteApexController.ITEM_TYPE_PROSERV) {

                                        if(isUpsellQuote && qliHasEntitlement) {
                                            qliWithEntitlements.add(qli);
                                        }else{
                                            qliProServ.add(qli);
                                        }
                                    }else if(qli.Product2.Sub_Category__c == CC_PROSERV_PRODUCT_SUBCATEGORY
                                        || qli.Item_type__c == QuotingToolQuoteApexController.ITEM_TYPE_PROSERV) {

                                        if(isUpsellQuote && qliHasEntitlement) {
                                            qliWithEntitlements.add(qli);
                                        }else{
                                            qliCCProServ.add(qli);
                                        }
                                    }
                                }
                            }

                        }
                    }

                    salesQuoteNotFoundOnOpp = (salesQuoteCount == 0);
                }

                Boolean currentSalesQuoteIsLastOnOpportunity = (salesQuoteNotFoundOnOpp &&
                        (q.RecordTypeId == null || q.RecordTypeId == SALES_QUOTE_RT_ID));

                Boolean doNotDeleteQuote = QuoteHelper.isQuotingAvailableForBrand(o.Brand_Name__c, o.Type == OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS)
                    && q.IsMultiProductTechnicalQuote__c == false
                    && (
                        currentSalesQuoteIsLastOnOpportunity ||
                        (q.Status == QUOTE_ACTIVE_STATUS_NAME) ||
                        (OpportunityHelper.isClosed(q.Opportunity.StageName))
                    );

                if(doNotDeleteQuote) {
                    Trigger.oldMap.get(q.Id).addError(DELETE_QUOTE_ERROR_MESSAGE);
                }else {
                    // if we can delete quote - delete qli too
                    if(isProServQuote && !qliProServ.isEmpty()) {
                        qliToDeleteList.addAll(qliProServ);
                    }else if(isCCProServQuote && !qliCCProServ.isEmpty()) {
                        qliToDeleteList.addAll(qliCCProServ);
                    }
                }
            }

            if (!qliToDeleteList.isEmpty()) {
                delete qliToDeleteList;
            }

            if(!qliWithEntitlements.isEmpty()) {
                List<QuoteLineItem> restoredQlis = QuoteLineItemHelper.restoreQLIFromEntitlement(qliWithEntitlements);

                if(!restoredQlis.isEmpty()) {
                    update restoredQlis;
                }
            }

            List<Area_Code_Line_Item__c> acliToDelete = [
                SELECT Id
                FROM Area_Code_Line_Item__c
                WHERE Quote_Line_Item__r.QuoteId IN: Trigger.oldMap.keySet()
            ];
            if (!acliToDelete.isEmpty()) {
                delete acliToDelete;
            }

            List<AssignmentLineItem__c> aliToDelete = [
                SELECT Id
                FROM AssignmentLineItem__c
                WHERE Parent__r.QuoteId IN: Trigger.oldMap.keySet()
            ];
            if (!aliToDelete.isEmpty()) {
                delete aliToDelete;
            }
        }

        private Map<Id, List<Quote>> buildOppIdToQuoteListMap(List<Quote> quotesToDelete) {

            Set<Id> quoteIdToDeleteSet = new Set<Id>();

            Map<Id, List<Quote>> oppIdToQuoteListMap = new Map<Id, List<Quote>>();

            for(Quote item : quotesToDelete) {
                if(oppIdToQuoteListMap.get(item.OpportunityId) == null) {
                    oppIdToQuoteListMap.put(item.OpportunityId, new List<Quote>());
                }

                quoteIdToDeleteSet.add(item.Id);
            }


            for (Quote item : [
                    SELECT Id, Name, Status, OpportunityId, Opportunity.StageName, Account.RC_User_ID__c, RecordTypeId,
                           RecordType.DeveloperName, Upsell_Status__c, IsMultiProductTechnicalQuote__c,
                           (SELECT Id, Quantity, Discount, Discount_number__c, Discount_type__c, Deactivated__c,
                                Product2.Family, Product2.Sub_Category__c, Entitlement__c, Item_type__c,
                                Entitlement__r.Quantity__c, Entitlement__r.Discount_Type__c,
                                Entitlement__r.Discount__c FROM QuoteLineItems)
                    FROM Quote
                    WHERE OpportunityId in :oppIdToQuoteListMap.keySet() AND
                    Id NOT IN :quoteIdToDeleteSet AND
                    IsMultiProductTechnicalQuote__c = false
            ]) {
                oppIdToQuoteListMap.get(item.OpportunityId).add(item);
            }

            return oppIdToQuoteListMap;
        }

    }

    public class CollectDataBeforeDelete extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Set<Id> oppIds = new Set<Id>();
            Set<Id> masterQuoteIds = new Set<Id>();

            for (Quote q : (List<Quote>) Trigger.old) {
                oppIds.add(q.OpportunityId);
                masterQuoteIds.add(q.Id);
            }

            selectOppsByIdsAndPopulateMaps(oppIds);
        }
    }

    public class DeleteRelatedEntitlements extends Triggers.TriggerHandlerBase {
        override public void handle() {
            EntitlementHelper.DeleteRelatedEntitlements((List<Quote>)Trigger.old);
        }
    }

    public class SetInvalidNumberSetups extends Triggers.TriggerHandlerBase {
        override public void handle(){

            Set<Id> priceBook2IdSet = new Set<Id>();

            List<Quote> quotes = Trigger.new;

            List<Quote> quotesWithNewUpsellStatus = new List<Quote>();

            for(Quote item : quotes) {
                if(item.Upsell_status__c == 'New') {
                    quotesWithNewUpsellStatus.add(item);
                    priceBook2IdSet.add(item.PriceBook2Id);
                }
            }

            if(quotesWithNewUpsellStatus.size() > 0) {

                QuoteLineItemTriggerHelper.CheckNumberOfVanitySteps checker = new QuoteLineItemTriggerHelper.CheckNumberOfVanitySteps();

                List<Quote> updatedQuotesList = checker.checkInvalidNumberSetups(quotesWithNewUpsellStatus, priceBook2IdSet);
                System.debug('updatedQuotesList.size() >>> ' + updatedQuotesList.size());
            }
        }
    }


    private static Boolean verifyIdTypesIsCompatible(List<Id> sobjectIds, Set<String> compatibleTypesSet) {

        Boolean findIncompatibleId = false;

        if(sobjectIds == null || sobjectIds.isEmpty() || compatibleTypesSet == null) {
            return findIncompatibleId;
        }

        for(Id currentId : sobjectIds) {
            String currentIdSobjectTypeName = currentId.getSObjectType().getDescribe().getName();
            if(!compatibleTypesSet.contains(currentIdSobjectTypeName)) {
                findIncompatibleId = true;
            }
        }

        return findIncompatibleId;
    }

    public static Map<Id, String> generateApprovalHistoryTable(List<Id> sobjectIds) {

        Map<Id, String> historyTable = new Map<Id, String>();

        // current method working with Approval__c and Quote sobject Ids
        Set<String> compatibleTypeNamesSet = new Set<String>{
            Approval__c.sObjectType.getDescribe().getName(),
            Quote.sObjectType.getDescribe().getName()
        };

        Boolean findIncompatibleId = verifyIdTypesIsCompatible(sobjectIds, compatibleTypeNamesSet);

        if(sobjectIds == null || sobjectIds.isEmpty() || findIncompatibleId) {
            return historyTable;
        }

        Boolean isSecondTable = true;

        List<ProcessInstanceStep> historyStepsList = [
            SELECT StepStatus, CreatedDate, OriginalActor.Name, Actor.Name, Comments,
                ActorId, ProcessInstance.TargetObjectId, ProcessInstanceId
            FROM ProcessInstanceStep
            WHERE ProcessInstance.TargetObjectId IN: sobjectIds
            ORDER BY CreatedDate DESC
        ];

        Id lastInstance = null;
        if(!historyStepsList.isEmpty()){
            lastInstance = historyStepsList[0].ProcessInstanceId;
        }

        Set<Id> actorGroupIds = new Set<Id>();
        Set<Id> actorIds = new Set<Id>();

        Map<Id, List<ProcessInstanceStep>> stepsMap = new Map<Id, List<ProcessInstanceStep>>();
        for(Id sobjectId : sobjectIds) {
            stepsMap.put(sobjectId, new List<ProcessInstanceStep>());
        }
        for(ProcessInstanceStep step : historyStepsList) {
            stepsMap.get(step.ProcessInstance.TargetObjectId).add(step);
            actorIds.add(step.ActorId);

            if(step.ActorId.getSobjectType() == Group.sObjectType) {
                actorGroupIds.add(step.ActorId);
            }
        }

        Map<Id, User> userHierarchyRole = new Map<Id, User>();

        if (!userMapStatic.keySet().containsAll(actorIds)) {
            userHierarchyRole = new Map<Id, User>([SELECT Id, Hierarchy_Role__c FROM User WHERE Id IN: actorIds]);
            userMapStatic = userHierarchyRole;
        } else {
            userHierarchyRole = userMapStatic;
        }

        Map<Id, Group> groupsMap = new Map<Id, Group>();
        if(!actorGroupIds.isEmpty()) {
            groupsMap.putAll([SELECT Id, Name FROM Group WHERE Type = 'Queue' AND Id IN :actorGroupIds]);
        }

        String head = '<tr>';
        head += '<td width="70%"><p style="text-align:center;margin:0;padding:0;">Comments</p></td>';
        head += '<td width="6%"><p style="text-align:center;margin:0;padding:0;">Action</p></td>';
        head += '<td width="8%"><p style="text-align:center;margin:0;padding:0;">Assigned To</p></td>';
        head += '<td width="8%"><p style="text-align:center;margin:0;padding:0;">Actual Approver</p></td>';
        head += '<td width="8%"><p style="text-align:center;margin:0;padding:0;">Date</p></td>';
        head += '</tr>';
        for(Id sobjectId : sobjectIds) {
            if(!stepsMap.get(sobjectId).isEmpty()) {
                String table = '';
                table += '<table style="vertical-align:middle;" border="1" cellpadding="0" cellspacing="0" width="100%">';
                table += '<tr>';
                table += '<th colspan="5"><p style="text-align:center;margin:0;padding:0;font-size:120%">Current approval request history</p></th>';
                table += '</tr>';

                table += head;

                for(ProcessInstanceStep step : stepsMap.get(sobjectId)) {
                    if(step.ProcessInstanceId != lastInstance && isSecondTable) {
                        isSecondTable = false;
                        table += '</table>';

                        table += '<table style="vertical-align:middle;" border="1" cellpadding="0" cellspacing="0" width="100%">';
                        table += '<tr>';
                        table += '<th colspan="5"><p style="text-align:center;margin:0;padding:0;font-size:120%">Previous approval request history</p></th>';
                        table += '</tr>';

                        table += head;
                    }
                    String status = '';

                    String userHRole = '';

                    if(userHierarchyRole.containsKey(step.ActorId)) {
                        userHRole = userHierarchyRole.get(step.ActorId).Hierarchy_Role__c;
                    }else if(groupsMap.containsKey(step.ActorId)) {
                        // in this case ActorId has Group Type, use GroupName as userHRole
                        userHRole = groupsMap.get(step.ActorId).Name;
                    }

                    if(userHRole == null) {
                        userHRole = 'Sales Rep';
                    }

                    if (step.StepStatus == 'Started') {
                        status = userHRole + ' submitted';
                    }
                    if (step.StepStatus == 'Approved') {
                        status = userHRole + ' approved';
                    }
                    if (step.StepStatus == 'Rejected') {
                        status = userHRole + ' rejected';
                    }
                    if (step.StepStatus == 'Removed') {
                        status = userHRole + ' recalled';
                    }
                    if (step.StepStatus == 'Reassigned') {
                        status = 'Reassigned to ' + userHRole;
                    }

                    String comment = step.Comments;
                    if(comment == null) {
                        comment = '';
                    }
                    table += '<td><p style="text-align:center;margin:0;padding:0;">' + comment + '</p></td>';
                    table += '<td><p style="text-align:center;margin:0;padding:0;">' + status + '</p></td>';
                    table += '<td><p style="text-align:center;margin:0;padding:0;">' + step.OriginalActor.Name + '</p></td>';
                    table += '<td><p style="text-align:center;margin:0;padding:0;">' + step.Actor.Name + '</p></td>';
                    table += '<td><p style="text-align:center;margin:0;padding:0;">' + step.CreatedDate + '</p></td>';
                    table += '</tr>';
                }
                table += '</table>';
                historyTable.put(sobjectId, table);
            }
        }
        return historyTable;
    }


    public class PopulateApprovalHistory extends Triggers.TriggerHandlerBase {
        override public void handle() {

            List<Id> quoteIds = new List<Id>();
            for(Quote quotes : (List<Quote>)Trigger.new) {
                if(CoreObjectBase.isFieldChanged(quotes, Quote.Approved_Status__c)) {
                    quoteIds.add(quotes.Id);
                }
            }
            if (quoteIds.isEmpty()) {
                return;
            }

            Map<Id, String> quoteApprovalHistoryTable = genApprovalHistoryTable(quoteIds);

            for(Quote quotes : (List<Quote>)Trigger.new) {

                if(quoteApprovalHistoryTable.containsKey(quotes.Id)) {
                    quotes.Approval_History__c = quoteApprovalHistoryTable.get(quotes.Id);
                }
            }
        }

        private Map<Id, String> genApprovalHistoryTable(List<Id> quoteIds) {

            Map<Id, String> historyTable = generateApprovalHistoryTable(quoteIds);

            return historyTable;
        }
    }

    public class PopulateApprovedFieldsOnQli extends Triggers.TriggerHandlerBase {
        override public void handle() {

            Map<Id, Quote> approvedQuotesMap = new Map<Id, Quote>();
            Map<Id, Quote> requiredApprovalQuotesMap = new Map<Id, Quote>();

            for(Quote quoteObj : (List<Quote>) Trigger.new) {

                if(QuoteHelper.QUOTE_RTS_FOR_APPROVED_FIELDS.contains(quoteObj.RecordTypeId)) {

                    if(super.isChangedFieldTo(quoteObj, Quote.Approved_Status__c, QuoteHelper.APPROVAL_STATUS_APPROVED)) {
                        approvedQuotesMap.put(quoteObj.Id, quoteObj);
                    }else if(super.isChangedFieldTo(quoteObj, Quote.Approved_Status__c, QuoteHelper.APPROVAL_STATUS_REQUIRED)) {
                        requiredApprovalQuotesMap.put(quoteObj.Id, quoteObj);
                    }
                }
            }

            Set<Id> quoteIdsToRetrieve = new Set<Id>();
            quoteIdsToRetrieve.addAll(approvedQuotesMap.keySet());
            quoteIdsToRetrieve.addAll(requiredApprovalQuotesMap.keySet());

            if (!quoteIdsToRetrieve.isEmpty()) {

                List<QuoteLineItem> qliList = (List<QuoteLineItem>) new QuoteLineItemSelector()
                    .selectQuoteLineItemsByQuoteIdsToPopulateApprovedFields(quoteIdsToRetrieve)
                    .executeQuery();

                if (!qliList.isEmpty()) {

                    List<QuoteLineItem> qlisToProcess = excludeQuotesForDQGOAFlow(qliList);

                    List<QuoteLineItem> qliToPopulateApprovedFieldsList = new List<QuoteLineItem>();
                    List<QuoteLineItem> qliToClearApprovedFieldsList = new List<QuoteLineItem>();

                    for (QuoteLineItem qli : qlisToProcess) {
                        if (approvedQuotesMap.containsKey(qli.QuoteId)) {
                            qliToPopulateApprovedFieldsList.add(qli);
                        }

                        if (requiredApprovalQuotesMap.containsKey(qli.QuoteId)) {
                            qliToClearApprovedFieldsList.add(qli);
                        }
                    }

                    List<QuoteLineItem> qliListToUpdate = new List<QuoteLineItem>();

                    if(!qliToPopulateApprovedFieldsList.isEmpty()) {
                        qliListToUpdate.addAll(
                            populateApprovedFileds(qliToPopulateApprovedFieldsList)
                        );
                    }

                    if(!qliToClearApprovedFieldsList.isEmpty()) {
                       qliListToUpdate.addAll(
                           clearApprovedFileds(qliToClearApprovedFieldsList)
                       );
                    }

                    if(!qliListToUpdate.isEmpty()) {

                        byPassOpportunityUpdate = true;
                        paramWasNotChanged = true;

                        OpportunityTotals.bypassOpportnuityUpdate = true;

                        update qliListToUpdate;

                        OpportunityTotals.bypassOpportnuityUpdate = false;
                    }
                }
            }
        }

        private List<QuoteLineItem> populateApprovedFileds(List<QuoteLineItem> qliList) {

            List<QuoteLineItem> processedQliList = new List<QuoteLineItem>();

            for(QuoteLineItem qli : qliList) {

                qli.Approved_Quantity__c = QuoteLineItemHelper.getResultingQuantity(qli);

                Double qliDiscount = qli.Discount_type__c == QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE ?
                    qli.Discount == null ? 0 : qli.Discount
                    : qli.Discount_Value__c == null ? 0 : qli.Discount_Value__c;

                qli.Approved_Discount__c = qliDiscount;
                qli.Approved_Discount_Type__c = qli.Discount_type__c;

                // populate lastApproved.. fields
                qli.Last_Approved_Quantity__c = QuoteLineItemHelper.getResultingQuantity(qli);
                qli.Last_Approved_Discount__c = qliDiscount;
                qli.Last_Approved_Discount_Type__c = qli.Discount_type__c;

                processedQliList.add(qli);
            }

            return processedQliList;
        }

        private List<QuoteLineItem> clearApprovedFileds(List<QuoteLineItem> qliList) {

            List<QuoteLineItem> processedQliList = new List<QuoteLineItem>();

            for(QuoteLineItem qli : qliList) {

                qli.Approved_Quantity__c = null;
                qli.Approved_Discount__c = null;
                qli.Approved_Discount_Type__c = null;

                processedQliList.add(qli);
            }

            return processedQliList;
        }

        private List<QuoteLineItem> excludeQuotesForDQGOAFlow(List<QuoteLineItem> qliList) {
            List<QuoteLineItem> result = new List<QuoteLineItem>();
            if (qliList == null || qliList.isEmpty()) {
                return result;
            }
            Map<Id, List<QuoteLineItem>> quoteIdToQliListMap = new Map<Id, List<QuoteLineItem>>();
            for (QuoteLineItem qli : qliList) {
                if (!quoteIdToQliListMap.containsKey(qli.QuoteId)) {
                    quoteIdToQliListMap.put(qli.QuoteId, new List<QuoteLineItem>());
                }
                quoteIdToQliListMap.get(qli.QuoteId).add(qli);
            }
            for (Id quoteId : quoteIdToQliListMap.keySet()) {
                Quote qt = quoteIdToQliListMap.get(quoteId)[0].Quote;
                if (!QuoteHelper.isDQGoaEnabled(qt)) {
                    result.addAll(quoteIdToQliListMap.get(quoteId));
                }
            }
            return result;
        }
    }

    public class CalculateFreeValues extends Triggers.TriggerHandlerBase {
        override public void handle() {

            /* Process just that quotes, which have special terms value LIKE free months */
            Decimal freeServiceTaxes = 0;
            Map <Id,Quote> quotesMap = new Map <Id, Quote>();
            for (Quote quoteObj : (List<Quote>)Trigger.new) {
                if (super.isChangedField(quoteObj, Quote.Special_Terms__c)) {
                    if (QuoteHelper.isCCQuote(quoteObj)) {
                        freeServiceTaxes = quoteObj.Free_Service_Taxes__c;
                    }
                    if (QuoteHelper.FREE_MONTHS_TERMS.contains(quoteObj.Special_Terms__c)) {
                        quotesMap.put(quoteObj.Id,quoteObj);
                    } else {
                        quoteObj.Credit_Amount__c = null;
                        quoteObj.Free_Service_Taxes__c = null;
                    }
                }
            }

            if (!quotesMap.isEmpty()) {

                List<QuoteLineItem> qliList = (List<QuoteLineItem>) new QuoteLineItemSelector()
                    .selectQuoteLineItemsByQuoteIds(quotesMap.keyset())
                    .executeQuery();
                /* Build quote id to quote line item list map */
                Map <Id,List <QuoteLineItem>> quoteToQlisMap= new Map <Id,List <QuoteLineItem>>();
                for (QuoteLineItem qli : qliList) {
                    if (!quoteToQlisMap.keyset().contains(qli.QuoteId)){
                        quoteToQlisMap.put(qli.QuoteId,new List <QuoteLineItem>());
                    }
                    quoteToQlisMap.get(qli.QuoteId).add(qli);
                }

                Feature_Toggle__c featureToggle = Feature_Toggle__c.getInstance();
                /* Update Credit_Amount__c and Free_Service_Taxes__c fields values */
                for (Id quoteId : quoteToQlisMap.keyset()) {
                    String specialTerms = quotesMap.get(quoteId).Special_Terms__c;
                    Integer numberOfFreeTerms = QuoteHelper.getNumberFromString(specialTerms);
                    Map<String,Decimal> freeServiceValues =
                            QuoteHelper.calculateFreeValuesOnQuote(quoteToQlisMap.get(quoteId), numberOfFreeTerms);
                    if (QuoteHelper.isNewBillingQuote(quotesMap.get(quoteId))) {
                        if (!featureToggle.CalculateFSCInQW__c) {
                            quotesMap.get(quoteId).Credit_Amount__c = freeServiceValues.get('freeDiscount');
                            quotesMap.get(quoteId).Free_Service_Taxes__c = freeServiceValues.get('freeServiceTaxes');
                        }
                    } else {
                        quotesMap.get(quoteId).Credit_Amount__c = freeServiceValues.get('freeDiscount');
                        if (freeServiceTaxes > 0) {
                            quotesMap.get(quoteId).Free_Service_Taxes__c = freeServiceTaxes;
                        } else {
                            quotesMap.get(quoteId).Free_Service_Taxes__c = freeServiceValues.get('freeServiceTaxes');
                        }
                    }
                }
            }
        }
    }

    public class UpdateOpportunityAfterQuoteDelete extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Set <Id> optyIds = new Set <Id>();
            for(Quote quoteObj : (List<Quote>)Trigger.old) {
                optyIds.add(quoteObj.OpportunityId);
            }
            //Just update opportunity to fire logic that populates
            //EstimatedProfessionalServices12Month__c field on Opportunity object
            if (optyIds.isEmpty()) {
                return;
            }

            List <Opportunity> opportunityToUpdate = (List<Opportunity>) new OpportunitySelector()
                .selectOpportunitiesByIds(optyIds)
                .executeQuery();
            if (!opportunityToUpdate.isEmpty()) {
                update opportunityToUpdate;
            }
        }
    }

    public class UpdateApprovalAfterQuoteActivation extends Triggers.TriggerHandlerBase {

        override public void handle() {
            List<Quote> quotes = Trigger.new;

            Map<Id, Quote> fittingQuoteIds = new Map<Id, Quote>();
            for (Quote q: quotes) {
                if(isChangedFieldTo(q, Quote.Status, STATUS_ACTIVE) && q.isPrimary__c == true) {
                    fittingQuoteIds.put(q.Id, q);
                }
            }
            if (fittingQuoteIds.isEmpty()) {
                return;
            }

            Set<Id> quoteIds = fittingQuoteIds.keySet();
            List<Approval__c> approvals = new ApprovalSelector()
                .selectApprovalsByQuoteIdsAndRecordTypeName(quoteIds, ApprovalHelper.RT_NAME_ENGAGE_LEGAL)
                .executeQuery();
            if (approvals.isEmpty()) {
                return;
            }

            List<QuoteLineItem> quoteLineItems = new QuoteLineItemSelector()
                .selectQuoteLineItemsByQuoteIdsAndByProductFamilyName(quoteIds, Product2Helper.FAMILY_SERVICE)
                .executeQuery();
            if (quoteLineItems.isEmpty()) {
                return;
            }

            Map<Id, QuoteLineItem> quoteIdToQliMap = new Map<Id, QuoteLineItem>();
            for (QuoteLineItem qli : quoteLineItems) {
                quoteIdToQliMap.put(qli.QuoteId, qli);
            }

            for (Approval__c approval : approvals) {
                if (!quoteIdToQliMap.containsKey(approval.Quote__c)) {
                    continue;
                }

                QuoteLineItem qli = quoteIdToQliMap.get(approval.Quote__c);
                approval.Contracted_Montlhy_DL_Price__c =
                    Product2Helper.CHARGE_TERM_ANNUAL.equalsIgnoreCase(QuoteLineItemHelper.getChargeTerm(qli))
                        ? qli.EffectivePrice__c / 12
                        : qli.EffectivePrice__c;
            }
            update approvals;
        }
    }

    public class CreateProservCase extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Set<Id> optyIdSet = new Set<Id>();
            List<Quote> quotesToProcess = new List<Quote>();

            for (Quote qt : (List<Quote>)Trigger.new) {
                if (isChangedFieldTo(qt, Quote.ProServ_Status__c, QuoteHelper.PROSERVSTATUS_SOLD) &&
                    (qt.RecordTypeId == QuoteHelper.RT_ID_PROSERV || qt.RecordTypeId == QuoteHelper.RT_ID_CC_PROSERV)) {
                    quotesToProcess.add(qt);
                    optyIdSet.add(qt.OpportunityId);
                }
            }
            if (quotesToProcess.isEmpty()) {
                return;
            }

            Map<Id, Id> optyIdToContactMap = buildOptyIdToContactMap(optyIdSet);
            List<QueueSobject> qsList = [SELECT Queue.id FROM QueueSobject WHERE Queue.Name = 'Professional Services' LIMIT 1];
            Id profServiceId = !qsList.isEmpty() ? qsList[0].Queue.id : null;

            List<Case> caseList = new List<Case>();
            for (Quote qt : quotesToProcess) {
                Case csNetworking = createCase(qt,optyIdToContactMap, 'Networking', profServiceId);
                Case csPD = createCase(qt,optyIdToContactMap, 'P&D', profServiceId);
                caseList.add(csNetworking);
                caseList.add(csPD);
            }

            try {
                insert caseList;
            } catch (DmlException e) {
                PlatformLog.logException('CreateProservCase.handle', e);
                System.debug('Failed to create proserv cases ' + e.getMessage());
            }
        }

        private Case createCase(Quote quote, Map<Id, Id> optyIdToContactMap, String caseCategory, Id ownerId) {
            String caseStatus = CaseHelper.CASE_STATUS_NEW;
            if(caseCategory == 'P&D'){
                caseStatus = CaseHelper.CASE_STATUS_CLOSED;
            }
            Case newCase = new Case (
                RecordTypeId = CaseHelper.RT_ID_PROFESSIONAL_SERVICES,
                AccountId = quote.Account__c,
                ContactId = optyIdToContactMap.get(quote.OpportunityId),
                Case_Category__c = caseCategory,
                Status = caseStatus,
                Priority = '4. Medium',
                Origin = 'Email',
                OwnerId = ownerId,
                Subject = caseCategory + ' - *' + System.now().format() + '*');
            return newCase;
        }

        private Map<Id, Id> buildOptyIdToContactMap(Set<Id> optyIdSet) {
            Map<Id, Id> mapToReturn = new Map<Id, Id>();
            if (optyIdSet.isEmpty()) {
                return mapToReturn;
            }

            List<OpportunityContactRole> contactRoleList = [
                SELECT Id, ContactId, OpportunityId
                FROM OpportunityContactRole
                WHERE Role = 'Signatory'
                AND IsPrimary = true
                AND OpportunityId IN :optyIdSet
            ];
            if (contactRoleList.isEmpty()) {
                return mapToReturn;
            }

            for (OpportunityContactRole acr : contactRoleList) {
                mapToReturn.put(acr.OpportunityId, acr.ContactId);
            }
            return mapToReturn;
        }
    }

    // Mavenlink integration logic
    public class QuoteAfterUpdate extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Set<Id> quoteId = new Set<Id>();
            for(Quote q : (List<Quote>) Trigger.new) {
                if (isChangedField(q, Quote.ProServ_Sold_Date__c)
                    || isChangedFieldFrom(q, Quote.ProServSalesRep__c, null)
                    || isChangedField(q, Quote.QuoteNumber)) {
                    quoteId.add(q.Id);
                }
            }
            if (!quoteId.isEmpty()) {
                PhaseTriggerHandler.updateRelatedPhases('Quote', quoteId);
            }
        }
    }
    // End of Mavenlink integration logic

    public class UpdatePrimaryQuoteOnOpportunity extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Set<Opportunity> oppsToUpdate = new Set<Opportunity>();
            Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
            for(Quote qt : (List<Quote>) Trigger.new) {
                if (qt.RecordTypeId == QuoteHelper.RT_ID_BILLING && isChangedFieldTo(qt, Quote.IsPrimary__c, true)) {
                    Opportunity opp = new Opportunity(
                            Id = qt.OpportunityId,
                            PrimaryQuote__c = qt.Id
                    );
                    oppMap.put(qt.OpportunityId, opp);
                }
            }

            if (!oppMap.isEmpty()) {
                Triggers.switchOff();
                update oppMap.values();
                Triggers.switchOn();
            }
        }
    }

    public class SetProServQuote extends Triggers.TriggerHandlerBase {
        override public void handle() {
            if (OpportunityTriggerHelperRefactored.isChangeOrderFlow && Trigger.isUpdate && Trigger.isAfter) {
                return;
            }

            List<Quote> quotes;

            if (Trigger.isInsert) {
                quotes = Trigger.new;
            } else if (Trigger.isUpdate) {
                quotes = findProServQuotesWithChangedStatus((Map<Id, Quote>) Trigger.oldMap, (List<Quote>) Trigger.new);
            }
            List<Opportunity> opportunitiesForUpdate = prepareOpportunitiesForUpdate(quotes);

            if (!opportunitiesForUpdate.isEmpty()) {
                Triggers.switchOff();
                update opportunitiesForUpdate;
                Triggers.switchOn();
            }

        }

        private List<Quote> findProServQuotesWithChangedStatus(Map<Id, Quote> oldQuotesValues, List<Quote> newQuotesValues) {
            List<Quote> quotes = new List<Quote>();
            for (Quote qt : newQuotesValues) {
                if (oldQuotesValues.get(qt.Id).ProServ_Status__c != qt.ProServ_Status__c) {
                    quotes.add(qt);
                }
            }
            return quotes;
        }

        private List<Opportunity> prepareOpportunitiesForUpdate(List<Quote> quotes) {
            Map<Id, Opportunity> opportunitiesForUpdate = new Map<Id, Opportunity>();

            Map<String, Schema.SObjectField> qtRecordTypeIdToOppField = new Map<String, Schema.SObjectField> {
                PROSERV_QUOTE_RT_ID => Schema.Opportunity.ProServ_Quote__c,
                CC_PROSERV_QUOTE_RT_ID => Schema.Opportunity.CC_ProServ_Quote__c
            };
            System.debug('upd quotes: ' + quotes);
            for (Quote qt : quotes) {
                if (qt.ProServ_Status__c != 'Cancelled' && qtRecordTypeIdToOppField.containsKey(qt.RecordTypeId)) {
                    opportunitiesForUpdate.put(
                        qt.OpportunityId,
                        populateOpportunityLookupToQuote(qt, qtRecordTypeIdToOppField.get(qt.RecordTypeId))
                    );
                } else if (qt.ProServ_Status__c == 'Cancelled' && qtRecordTypeIdToOppField.containsKey(qt.RecordTypeId)) {
                    opportunitiesForUpdate.put(
                        qt.OpportunityId,
                        clearOpportunityLookupToQuote(qt, qtRecordTypeIdToOppField.get(qt.RecordTypeId))
                    );
                }
            }
            return opportunitiesForUpdate.values();
        }

        private Opportunity populateOpportunityLookupToQuote(Quote qt, Schema.SObjectField field) {
            Opportunity opp = prepareOpportunity(qt);
            opp.put(field, qt.Id);
            return opp;
        }

        private Opportunity clearOpportunityLookupToQuote(Quote qt, Schema.SObjectField field) {
            Opportunity opp = prepareOpportunity(qt);
            opp.put(field, null);
            return opp;
        }

        private Opportunity prepareOpportunity(Quote qt) {
            return new Opportunity(
                Id = qt.OpportunityId
            );
        }
    }

    public class SetIsCLMChangeOrderFormRequired extends Triggers.TriggerHandlerBase {
        override public void handle() {

            if (isCLMChangeOrderFormRequiredCalled) {
                return;
            }

            Map<Id, Quote> quoteMap = new Map<Id, Quote>((List<Quote>)Trigger.new);
            List<String> fieldsToQuery = new List<String> {
                    'Entitlement__r.PackageCatalogId__c',
                    'Entitlement__r.PackageDuration__c',
                    'Entitlement__r.PackageVersion__c',
                    'PackageCatalogId__c',
                    'PackageVersion__c'
            };
            List<QuoteLineItem> qlisForQuotes = (List<QuoteLineItem>) new QuoteLineItemSelector()
                    .selectQuoteLineItemsByQuoteIds(quoteMap.keySet())
                    .selectFields(fieldsToQuery)
                    .executeQuery();

            Map<Id, List<QuoteLineItem>> quoteIdToQliMap = QuoteLineItemHelper.buildQuoteIdToQliMap(qlisForQuotes);

            for (Id quoteId : quoteIdToQliMap.keySet()) {
                quoteMap.get(quoteId).IsCLMChangeOrderFormRequired__c = false;

                for (QuoteLineItem qli : quoteIdToQliMap.get(quoteId)) {
                    if (qli.Product2.Family == Product2Helper.FAMILY_TAXES) {
                        continue;
                    }

                    if (QuoteLineItemHelper.isPaymentPlanChange(qli)
                            || QuoteLineItemHelper.isPackageChange(qli)
                            || QuoteLineItemHelper.isDiscountChange(qli)
                            || QuoteLineItemHelper.isDownsell(qli)
                            ) {
                        quoteMap.get(quoteId).IsCLMChangeOrderFormRequired__c = true;
                        break;
                    }
                }
            }

            isCLMChangeOrderFormRequiredCalled = true;
        }
    }

    public class UpdateParentOpportunityFieldAfterUpdateQuote extends Triggers.TriggerHandlerBase {
        override public void handle() {
            if (OpportunityTriggerHelperRefactored.isChangeOrderFlow) {
                return;
            }

            List<Quote> quoteList = (List<Quote>) Trigger.new;

            Set<Id> parentQtIds = new Set<Id>();
            for (Quote qt : quoteList) {
                if (isChangedField(qt, Quote.ParentQuote__c)) {
                    parentQtIds.add(qt.ParentQuote__c);
                }
            }

            Map<Id, Id> parentQtMap = new Map<Id, Id>();
            if (!parentQtIds.isEmpty()) {
                for (Quote qt : (List<Quote>) new QuoteSelector()
                                                .selectQuoteById(new List<Object>{
                                                    parentQtIds
                                                })
                                                .executeQuery()) {
                    parentQtMap.put(qt.Id, qt.OpportunityId);
                }
            }


            Map<Id, Opportunity> oppToUpdate = new Map<Id, Opportunity>();
            for (Quote qt : quoteList) {
                if (isChangedField(qt, Quote.ParentQuote__c)) {
                    Opportunity opp = new Opportunity(
                        Id = qt.OpportunityId
                    );
                    oppToUpdate.put(opp.id, opp);
                }
            }

            if (!oppToUpdate.isEmpty()) {
                Triggers.switchOff();
                update oppToUpdate.values();
                Triggers.switchOn();
            }
        }
    }

    public class UpdateParentOpportunityFieldAfterDeleteQuote extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Map<Id, Quote> parentQuotes = (Map<Id, Quote>) Trigger.oldMap;
            List<Quote> childQuotes = new QuoteSelector()
                .selectChildQuotes(new List<Object>{parentQuotes.keySet()})
                .executeQuery();
            if (childQuotes.isEmpty()) {
                return;
            }

            Map<Id, Opportunity> oppToUpdate = new Map<Id, Opportunity>();
            for (Quote qt : childQuotes) {
                Opportunity opp = new Opportunity(
                    Id = qt.OpportunityId
                );
                oppToUpdate.put(opp.Id, opp);
            }

            Triggers.switchOff();
            update oppToUpdate.values();
            Triggers.switchOn();
        }
    }

    public class SyncDataFromMasterQuote extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Map<Id, Quote> updatedQuotes = (Map<Id, Quote>) Trigger.newMap;

            Map<Id, Quote> masterQuotesById = new Map<Id, Quote>();

            for (Quote quoteRecord : updatedQuotes.values()) {
                if (quoteRecord.IsMultiProductTechnicalQuote__c) {
                    continue;
                }

                if (isCommonSyncFieldsChanged(quoteRecord)
                        || isNewBusinessSyncFieldsChanged(quoteRecord)
                        || isExistingBusinessSyncFieldsChanged(quoteRecord)
                        || isProServFieldsChanged(quoteRecord)
                   ) {
                    masterQuotesById.put(quoteRecord.Id, quoteRecord);
                }
            }

            if (masterQuotesById.isEmpty()) {
                return;
            }

            List<Quote> techQuoteList = (List<Quote>) new QuoteSelector()
                .selectMultiProductTechnicalQuotesByMasterQuoteIds(masterQuotesById.keySet())
                .executeQuery();

            List<Quote> techQuoteToUpdate = new List<Quote>();
            Map<Id,Boolean> accountIdToIsMPUBMap = new Map<Id,Boolean>();

            for (Quote qt : techQuoteList) {
                accountIdToIsMPUBMap = AccountHelper.updateAccountIdToIsMPUBMap(accountIdToIsMPUBMap, qt.Account);
                Boolean isMPUBAccount = accountIdToIsMPUBMap.get(qt.Account.Id);
                Quote masterQuote = masterQuotesById.get(qt.MasterQuote__c);
                Boolean isMPUB = isMPUBAccount || !qt.ServiceInfo__r.IsEmpty();
                Quote updatedQuote = new Quote(Id = qt.Id);
                Boolean isUpdated = false;

                if (qt.Enabled_LBO__c != masterQuote.Enabled_LBO__c) {
                    updatedQuote.Enabled_LBO__c = qt.ServiceName__c == QuoteHelper.NGBS_OFFICE_PRODUCT ? masterQuote.Enabled_LBO__c : false;

                    isUpdated = true;
                }

                if (qt.AreaCode__c != masterQuote.AreaCode__c) {
                    updatedQuote.AreaCode__c = masterQuote.AreaCode__c;

                    isUpdated = true;
                }

                if (qt.isPrimary__c != masterQuote.isPrimary__c && !isMPUB) {

                    updatedQuote.isPrimary__c = qt.ServiceName__c == QuoteHelper.NGBS_OFFICE_PRODUCT ? false : masterQuote.isPrimary__c;

                    isUpdated = true;
                }

                if (qt.IsQuoteHasErrors__c != masterQuote.IsQuoteHasErrors__c) {

                    updatedQuote.IsQuoteHasErrors__c = masterQuote.IsQuoteHasErrors__c;

                    isUpdated = true;
                }

                if (qt.FaxAreaCode__c != masterQuote.FaxAreaCode__c) {
                    updatedQuote.FaxAreaCode__c = masterQuote.FaxAreaCode__c;

                    isUpdated = true;
                }

                if (qt.ContactId != masterQuote.ContactId) {
                    updatedQuote.ContactId = masterQuote.ContactId;

                    isUpdated = true;
                }

                if (masterQuote.Opp_Type__c == OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS) {
                    if (qt.Auto_Renewal__c != masterQuote.Auto_Renewal__c) {
                        updatedQuote.Auto_Renewal__c = masterQuote.Auto_Renewal__c;

                        isUpdated = true;
                    }

                    if (qt.Term_months__c != masterQuote.Term_months__c) {
                        updatedQuote.Term_months__c = masterQuote.Term_months__c;

                        isUpdated = true;
                    }

                    if (qt.Start_Date__c != masterQuote.Start_Date__c) {
                        updatedQuote.Start_Date__c = masterQuote.Start_Date__c;

                        isUpdated = true;
                    }

                    if (qt.QuoteType__c != masterQuote.QuoteType__c) {
                        updatedQuote.QuoteType__c = masterQuote.QuoteType__c;

                        isUpdated = true;
                    }

                    if (qt.End_Date__c != masterQuote.End_Date__c) {
                        updatedQuote.End_Date__c = masterQuote.End_Date__c;
                        isUpdated = true;
                    }

                    // Skip updating package info when using new partial save process since fields are already synced from frontend
                    if (!Feature_Toggle__c.getInstance().EnableIncrementalSave__c) {
                        BillingWrappers.QuotePackageInfo servicePackageInfo = QuoteHelper.getTechnicalQuotePackageInfo(masterQuote, qt.ServiceName__c);
                        String updatedPackageInfo = JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{servicePackageInfo});

                        if (updatedPackageInfo != masterQuote.Package_Info__c) {
                            updatedQuote.Package_Info__c = updatedPackageInfo;

                            isUpdated = true;
                        }
                    }
                }

                if (masterQuote.Opp_Type__c == OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS) {
                    if (qt.QuoteType__c != masterQuote.QuoteType__c) {
                        updatedQuote.QuoteType__c = masterQuote.QuoteType__c;

                        isUpdated = true;
                    }
                }

                if (qt.Status != masterQuote.Status) {
                    updatedQuote.Status = masterQuote.Status;
                    isUpdated = true;
                }

                if (qt.Special_Terms__c != masterQuote.Special_Terms__c && isChangedFieldTo(masterQuote, Quote.Special_Terms__c, null)) {
                    updatedQuote.Special_Terms__c = null;
                    isUpdated = true;
                }

                if (qt.Credit_Amount__c != masterQuote.Credit_Amount__c && isChangedFieldTo(masterQuote, Quote.Credit_Amount__c, null)) {
                    updatedQuote.Credit_Amount__c = null;
                    isUpdated = true;
                }

                if (qt.Free_Service_Taxes__c != masterQuote.Free_Service_Taxes__c && isChangedFieldTo(masterQuote, Quote.Free_Service_Taxes__c, null)) {
                    updatedQuote.Free_Service_Taxes__c = null;
                    isUpdated = true;
                }

                if (qt.FreeShippingTerms__c != masterQuote.FreeShippingTerms__c && isChangedFieldTo(masterQuote, Quote.FreeShippingTerms__c, null)) {
                    updatedQuote.FreeShippingTerms__c = null;
                    isUpdated = true;
                }

                if (QuoteHelper.isProServService(qt)) {
                    if (qt.TotalProjectHoursQuoted__c != masterQuote.TotalProjectHoursQuoted__c) {
                        updatedQuote.TotalProjectHoursQuoted__c = masterQuote.TotalProjectHoursQuoted__c;

                        isUpdated = true;
                    }

                    if (qt.PSProjectComplexity__c != masterQuote.PSProjectComplexity__c) {
                        updatedQuote.PSProjectComplexity__c = masterQuote.PSProjectComplexity__c;

                        isUpdated = true;
                    }

                    if (qt.ProServ_Forecasted_Close_Date__c != masterQuote.ProServ_Forecasted_Close_Date__c) {
                        updatedQuote.ProServ_Forecasted_Close_Date__c = masterQuote.ProServ_Forecasted_Close_Date__c;

                        isUpdated = true;
                    }
                }

                if (isUpdated) {
                    techQuoteToUpdate.add(updatedQuote);
                }
            }

            if (!techQuoteToUpdate.isEmpty()) {
                update techQuoteToUpdate;
            }
        }

        private Boolean isCommonSyncFieldsChanged(Quote q) {
            Boolean result = isChangedField(q, Quote.Enabled_LBO__c)
                    || isChangedField(q, Quote.AreaCode__c)
                    || isChangedField(q, Quote.FaxAreaCode__c)
                    || isChangedField(q, Quote.ContactId)
                    || isChangedField(q, Quote.Special_Terms__c)
                    || isChangedField(q, Quote.Credit_Amount__c)
                    || isChangedField(q, Quote.Status)
                    || isChangedField(q, Quote.Free_Service_Taxes__c);
            return result;
        }

        private Boolean isNewBusinessSyncFieldsChanged(Quote q) {
            Boolean result = false;

            if (q.Opp_Type__c == OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS) {
                result = isChangedFieldToNonNull(q, Quote.Package_Info__c)
                        || isChangedFieldToNonNull(q, Quote.QuoteType__c)
                        || isChangedFieldToNonNull(q, Quote.Start_Date__c)
                        || isChangedFieldToNonNull(q, Quote.Term_months__c)
                        || isChangedFieldToNonNull(q, Quote.Auto_Renewal__c)
                        || isChangedFieldToNonNull(q, Quote.Initial_Term_months__c)
                        || isChangedFieldToNonNull(q, Quote.IsQuoteHasErrors__c)
                        || isChangedFieldToNonNull(q, Quote.isPrimary__c);
            }
            return result;
        }

        private Boolean isExistingBusinessSyncFieldsChanged(Quote q) {
            Boolean result = false;
            if (q.Opp_Type__c == OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS) {
                result = isChangedField(q, Quote.QuoteType__c)
                        || isChangedField(q, Quote.isPrimary__c);
            }
            return result;
        }

        private Boolean isProServFieldsChanged(Quote q) {
            Boolean result = isChangedField(q, Quote.TotalProjectHoursQuoted__c)
                || isChangedField(q, Quote.PSProjectComplexity__c)
                || isChangedField(q, Quote.ProServ_Forecasted_Close_Date__c);
            return result;
        }
    }

    public class SyncTechnicalQuotesOnMasterQuoteActivation extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Map<Id, Quote> activatedMasterQuotes = new Map<Id, Quote>();
            for (Quote q : (List<Quote>) Trigger.new) {
                if (isMasterQuoteActivated(q)) {
                    activatedMasterQuotes.put(q.Id, q);
                }
            }
            
            if (activatedMasterQuotes.isEmpty()) {
                return;
            }

            List<Quote> technicalQuotes = new QuoteSelector()
                .selectMultiProductTechnicalQuotesForSyncByMasterQuoteIds(activatedMasterQuotes.keySet())
                .executeQuery();

            Map<Quote, List<Quote>> masterToTechnicalQuotes = getMasterToTechnicalQuotes(activatedMasterQuotes.values(), technicalQuotes);

            List<Quote> quotesToUpdate = new List<Quote>();

            for (Quote masterQuote : masterToTechnicalQuotes.keySet()) {
                if (masterQuote.Initial_Term_months__c == null) {
                    masterQuote.addError(Label.Quote_Error_Empty_Initial_Term_Months);
                    continue;
                }

                List<Quote> techQuotes = masterToTechnicalQuotes.get(masterQuote);

                if (techQuotes == null || techQuotes.isEmpty()) {
                    continue;
                }

                for (Quote techQuote : techQuotes) {
                    Integer techInitialTerms = Math.abs(Date.today().monthsBetween(masterQuote.End_Date__c));
                    Date techEndDate = Date.today().addMonths(techInitialTerms);

                    if (techEndDate < masterQuote.End_Date__c) {
                        techInitialTerms = techInitialTerms + 1;
                        techEndDate = techEndDate.addMonths(1);
                    }

                    Quote q = new Quote(
                        Id = techQuote.Id,
                        Term_months__c = masterQuote.Term_months__c,
                        Auto_Renewal__c = masterQuote.Auto_Renewal__c,
                        QuoteType__c = masterQuote.QuoteType__c,
                        Status = masterQuote.Status,
                        Start_Date__c = Date.today(),
                        End_Date__c = techEndDate,
                        Initial_Term_months__c = String.valueOf(techInitialTerms)
                    );

                    quotesToUpdate.add(q);
                }
            }

            if (!quotesToUpdate.isEmpty()) {
                update quotesToUpdate;
            }
        }

        private Boolean isMasterQuoteActivated(Quote q) {
            return !q.IsMultiProductTechnicalQuote__c
                && q.Opp_Type__c != OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS
                && isChangedFieldTo(q, Quote.Status, QuoteHelper.QUOTE_STATUS_ACTIVE);
        }

        private Map<Quote, List<Quote>> getMasterToTechnicalQuotes(List<Quote> masterQuotes, List<Quote> technicalQuotes) {
            Map<Quote, List<Quote>> result = new Map<Quote, List<Quote>>();

            for (Quote master : masterQuotes) {
                for (Quote tech : technicalQuotes) {
                    if (tech.MasterQuote__c == master.Id) {
                        if (result.get(master) == null) {
                            result.put(master, new List<Quote> {tech});
                        } else {
                            result.get(master).add(tech);
                        }
                    }
                }
            }

            return result;
        }
    }

    public class MoveAcceptedQuoteToActiveStatus extends Triggers.TriggerHandlerBase {
        override public void handle() {
            for (Quote q : (List<Quote>) Trigger.new) {
                if (isChangedFieldFrom(q, Quote.Status, QuoteHelper.QUOTE_STATUS_ACTIVE)
                && isChangedFieldTo(q, Quote.Status, QuoteHelper.QUOTE_STATUS_ACCEPTED)) {
                    q.Status = QuoteHelper.QUOTE_STATUS_ACTIVE;
                }
            }
        }
    }

    public class AdjustTechQuoteTermsOnMasterUpdate extends Triggers.TriggerHandlerBase {
        final Set<SObjectField> fieldsToCheck = new Set<SObjectField> {
            Quote.Term_months__c,
            Quote.Initial_Term_months__c
        };

        override public void handle() {
            Set<Id> quoteIds = new Set<Id>();
            for (Quote q : (List<Quote>) Trigger.new) {
                if (q.IsMultiProductTechnicalQuote__c) {
                    continue;
                }

                if (q.Status == QuoteHelper.QUOTE_STATUS_ACTIVE) {
                    continue;
                }

                if (isChangedFieldToNonNull(q, Quote.Term_months__c) || isChangedFieldToNonNull(q, Quote.Initial_Term_months__c)) {
                    quoteIds.add(q.Id);
                }
            }

            if (quoteIds.isEmpty()) {
                return;
            }

            List<Quote> techQuoteList = (List<Quote>) new QuoteSelector()
                .selectMultiProductTechnicalQuotesByMasterQuoteIds(quoteIds)
                .executeQuery();

            if (techQuoteList.isEmpty()) {
                return;
            }

            List<Quote> quotesToUpdate = new List<Quote>();
            for (Quote techQuote : techQuoteList) {
                Quote masterQuote = techQuote.MasterQuote__r;
                Quote oldMasterQuote = (Quote) Trigger.oldMap.get(masterQuote.Id);
                Quote q = new Quote(Id = techQuote.Id);
                Boolean isUpdated = false;

                for (SObjectField field : fieldsToCheck) {
                    if (QuoteHelper.isExistingBusiness(masterQuote) && !AccountHelper.isPOCToPaid(masterQuote.Account)) {
                        Integer initialTerm = Integer.valueOf(masterQuote.get(field)) != null
                            ? Integer.valueOf(masterQuote.get(field))
                            : 0;
                        Integer oldInitialTerm = Integer.valueOf(oldMasterQuote.get(field)) != null
                            ? Integer.valueOf(oldMasterQuote.get(field))
                            : 0;
                        Integer initialTermDiff = initialTerm - oldInitialTerm;
                        Integer resultTechInitialTerm = Integer.valueOf(techQuote.get(field)) != null
                            ? Integer.valueOf(techQuote.get(field)) + initialTermDiff
                            : initialTermDiff;

                        if (techQuote.get(field) != String.valueOf(resultTechInitialTerm)) {
                            q.put(field, String.valueOf(resultTechInitialTerm));
                            isUpdated = true;
                        }
                    } else {
                        if (techQuote.get(field) != masterQuote.get(field)) {
                            q.put(field, masterQuote.get(field));
                            isUpdated = true;
                        }
                    }
                }

                if (isUpdated) {
                    quotesToUpdate.add(q);
                }
            }

            if (!quotesToUpdate.isEmpty()) {
                update quotesToUpdate;
            }
        }
    }

    public class SendEmailsOnApprovalStatusChangeForPRM extends Triggers.TriggerHandlerBase {
        private final String EMAIL_TEMPLATE_APPROVED = 'Discounts_Approved_Ignite';
        private final String EMAIL_TEMPLATE_REJECTED = 'Discounts_Rejected_Ignite';
        private final String EMAIL_CC_RECIPIENTS_QUEUE = 'Ignite_Notification_Copy_Recipients';
        private final String EMAIL_FROM_ADDRESS = 'noreply@ringcentral.com';

        override public void handle() {
            List<Id> prmQuoteIds = new List<Id>();

            for (Quote q : (List<Quote>) Trigger.new) {
                if (!q.IsPRMQuote__c) {
                    continue;
                }

                if (
                    !(isChangedFieldTo(q, Quote.Approved_Status__c, QuoteHelper.APPROVAL_STATUS_APPROVED)
                        || isChangedFieldTo(q, Quote.Approved_Status__c, QuoteHelper.APPROVAL_STATUS_REJECTED))
                ) {
                    continue;
                }

                prmQuoteIds.add(q.Id);
            }

            if (prmQuoteIds.isEmpty()) {
                return;
            }

            List<EmailTemplate> templates = (List<EmailTemplate>) new EmailTemplateSelector()
                .selectEmailTemplatesByDeveloperNames(
                    new List<String>{
                        EMAIL_TEMPLATE_APPROVED,
                        EMAIL_TEMPLATE_REJECTED
                    },
                    true
                )
                .executeQuery();

            if (templates.isEmpty()) {
                return;
            }

            List<OrgWideEmailAddress> owea = (List<OrgWideEmailAddress>) new QueryFactory(OrgWideEmailAddress.SObjectType)
                .selectFields(new List<String>{ 'Id' })
                .setCondition('Address = :bind0')
                .setQueryBindings(new List<String>{ EMAIL_FROM_ADDRESS })
                .executeQuery();

            if (owea.isEmpty()) {
                return;
            }

            List<Quote> quotesToProcess = (List<Quote>) new QuoteSelector()
                .newQueryFactory()
                .setFactoryName('selectQuotesByIds')
                .selectFields(new List<String> {
                    'Id',
                    'QuoteNumber',
                    'Approved_Status__c',
                    'JustificationandDescription__c',
                    'AccountId',
                    'Account.Id',
                    'Account.Name',
                    'OpportunityId',
                    'Opportunity.Id',
                    'Opportunity.Name',
                    'Opportunity.Inside_Sales_Rep__c.Email',
                    'Opportunity.Owner.Name',
                    'Opportunity.Owner.Email',
                    'Opportunity.Owner.Manager.Name',
                    'Opportunity.Owner.Manager.Email'
                })
                .withoutSelectorOrderByIncluded()
                .setCondition('Id IN :bind0')
                .setQueryBindings(new List<Object> { prmQuoteIds })
                .executeQuery();

            if (quotesToProcess.isEmpty()) {
                return;
            }

            List<User> ccUsers = new UserSelector()
                .selectUsersByQueueDevName(EMAIL_CC_RECIPIENTS_QUEUE)
                .executeQuery();

            Map<String, EmailTemplate> templatesByDevName = new Map<String, EmailTemplate>();
            for (EmailTemplate template : templates) {
                templatesByDevName.put(template.DeveloperName, template);
            }

            EmailHelper.QuoteApprovalEmailBuilder emailBuilder = new EmailHelper.QuoteApprovalEmailBuilder();
            emailBuilder.setApprovedTemplate(templatesByDevName.get('Discounts_Approved_Ignite'));
            emailBuilder.setRejectedTemplate(templatesByDevName.get('Discounts_Rejected_Ignite'));
            emailBuilder.setQuotes(quotesToProcess);
            emailBuilder.setFromAddress(owea.get(0));
            emailBuilder.addCCRecipients(ccUsers);

            List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>(emailBuilder.buildEmails());

            if (!messages.isEmpty()) {
                List<Messaging.SendEmailResult> result = Messaging.sendEmail(messages, false);
            }
        }
    }

    public class SendEmailsOnIgniteQuoteCreation extends Triggers.TriggerHandlerBase {
        private final String EMAIL_TEMPLATE_QUOTE_CREATED = 'New_Quote_Ignite';
        private final Set<String> OPPORTUNITY_STAGES = new Set<String> {
            '1. Qualify',
            '2. Problem'
        };
        private final String EMAIL_FROM_ADDRESS = 'noreply@ringcentral.com';
        Set<String> ccEmailRecipients = new Set<String>();

        override public void handle() {
            Email_Configuration__c emailSetting = Email_Configuration__c.getInstance();
            if (emailSetting != null && emailSetting.CC_Emails_Ignite_Quote_Creation__c != null) {
                ccEmailRecipients.addAll(emailSetting.CC_Emails_Ignite_Quote_Creation__c.split(','));
            }

            Set<Id> quoteIdsToLoad = new Set<Id>(Trigger.newMap.keySet());

            List<Quote> quotesToProcess = (List<Quote>) new QuoteSelector()
                .newQueryFactory()
                .setFactoryName('selectQuotesByIds')
                .selectFields(new List<String> {
                    'Id',
                    'QuoteNumber',
                    'AccountId',
                    'Account.Id',
                    'Account.Name',
                    'OpportunityId',
                    'Opportunity.Id',
                    'Opportunity.AccountId',
                    'Opportunity.Name',
                    'Opportunity.Inside_Sales_Rep__c.Email',
                    'Opportunity.Owner.Name',
                    'Opportunity.Owner.Email',
                    'Opportunity.Owner.Manager.Name',
                    'Opportunity.Owner.Manager.Email',
                    'Opportunity.Name',
                    'Opportunity.Type',
                    'Opportunity.StageName',
                    'Opportunity.PartnerProgram__c'
                })
                .withoutSelectorOrderByIncluded()
                .setCondition('Id IN :bind0')
                .setQueryBindings(new List<Object> { quoteIdsToLoad })
                .executeQuery();

            if (quotesToProcess.isEmpty()) {
                return;
            }

            List<Id> accountIds = new List<Id>();
            for (Quote q : quotesToProcess) {
                accountIds.add(q.AccountId);
            }

            List<Opportunity> newBusinessOpportunities = (List<Opportunity>) new OpportunitySelector()
                .newQueryFactory()
                .setFactoryName('selectOpportunitiesByIds')
                .selectFields(new List<String> {
                    'Id',
                    'AccountId',
                    'Name',
                    'Type',
                    'StageName',
                    'PartnerProgram__c'
                })
                .withoutSelectorOrderByIncluded()
                .addOrdering('CreatedDate', QueryFactory.SortOrder.DESCENDING)
                .setCondition('AccountId IN :bind0 AND Type = :bind1 AND PartnerProgram__c = :bind2')
                .setQueryBindings(new List<Object> { accountIds, OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS, 'Ignite' })
                .executeQuery();

            Map<Id, Opportunity> accountToNewBusinessOpportunity = new Map<Id, Opportunity>();
            for (Opportunity o : newBusinessOpportunities) {
                accountToNewBusinessOpportunity.put(o.AccountId, o);
            }

            List<OrgWideEmailAddress> owea = (List<OrgWideEmailAddress>) new QueryFactory(OrgWideEmailAddress.SObjectType)
                .selectFields(new List<String>{'Id'})
                .setCondition('Address = :bind0')
                .setQueryBindings(new List<String>{ EMAIL_FROM_ADDRESS })
                .executeQuery();

            if (owea.isEmpty()) {
                return;
            }

            List<EmailTemplate> templates = (List<EmailTemplate>) new EmailTemplateSelector()
                .selectEmailTemplatesByDeveloperNames(
                    new List<String>{
                        EMAIL_TEMPLATE_QUOTE_CREATED
                    },
                    true
                )
                .executeQuery();

            if (templates.isEmpty()) {
                return;
            }

            EmailHelper.QuoteCreationEmailBuilder emailBuilder = new EmailHelper.QuoteCreationEmailBuilder();
            emailBuilder.setTemplate(templates.get(0));
            emailBuilder.setFromAddress(owea.get(0));
            emailBuilder.setQuotes(quotesToProcess);
            emailBuilder.setNewBusinessOpportunities(newBusinessOpportunities);
            emailBuilder.setOpportunityStages(OPPORTUNITY_STAGES);
            emailBuilder.addCCRecipients(ccEmailRecipients);

            List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>(emailBuilder.buildEmails());

            if (!messages.isEmpty()) {
                List<Messaging.SendEmailResult> result = Messaging.sendEmail(messages, false);
            }
        }
    }

    public class DeleteRelatedAssignments extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Set<Id> quoteIds = new Set<Id>();
            for (Quote q : (List<Quote>) Trigger.new) {
                if (q.Enabled_LBO__c && isChangedField(q, Quote.Enabled_LBO__c)) {
                    quoteIds.add(q.Id);
                }
            }
            if (!quoteIds.isEmpty()) {
                List<AssignmentLineItem__c> assignments = (List<AssignmentLineItem__c>) new AssignmentLineItemSelector()
                    .selectALIForMasterQuotes(new List<Object> { quoteIds })
                    .executeQuery();
                if(!assignments.isEmpty()) {
                    delete assignments;
                }

                List<Area_Code_Line_Item__c> aclis = new AreaCodeLineItemSelector()
                    .selectACLIForMasterQuotes(new List<Object>{ quoteIds })
                    .executeQuery();
                if(!aclis.isEmpty()) {
                    delete aclis;
                }

                List<CustomAddressAssignments__c> customAddresses = new CustomAddressAssignmentsSelector()
                    .selectCustomAddressAssignmentsByQuoteIds(quoteIds)
                    .executeQuery();
                if(!customAddresses.isEmpty()) {
                    delete customAddresses;
                }
            }
        }
    }

    public class UpdateServiceInfo extends Triggers.TriggerHandlerBase {
        override public void handle() {
            QuoteHelper.updateServiceInfo(Trigger.newMap.keySet(), QuoteLineItemTriggerHelper.quotesMapStatic);
        }
    }

    public class SendEmailToSSE extends Triggers.TriggerHandlerBase {

        override public void handle() {
            Set<Id> oppIdSet = new Set<Id>();

            for (Quote q : (List<Quote>) Trigger.new) {
                if (isValidPOCQuoteForSSE(q)) {
                    oppIdSet.add(q.opportunityId);
                }
            }
            
            if (!oppIdSet.isEmpty()) {
                sendEmailsToSSE(oppIdSet);
            }
        }
        
        private Boolean isValidPOCQuoteForSSE(Quote q) {
            Quote oldQuote = (Quote) Trigger.oldMap.get(q.Id);
            return q.RecordTypeId == POC_QUOTE_RT_ID
                && (q.Total_Number_of_Digital_Lines__c != oldQuote.Total_Number_of_Digital_Lines__c 
                || q.isPrimary__c != oldQuote.isPrimary__c)
                && q.Total_Number_of_Digital_Lines__c >= THRESHHOLD_DL_NO
                && !q.IsQuoteHasErrors__c
                && q.isPrimary__c;
        }
        
        private void sendEmailsToSSE(Set<Id> oppIdSet) {
            Map<Id, OpportunityTeamMember> oppTeamMemberMap = getOpportunityTeamMembers(oppIdSet, SE_ROLE);
            List<Messaging.SingleEmailMessage> emailList = buildEmailList(oppIdSet, oppTeamMemberMap, POC_OPPORTUNITY_SSE_LEADERSHIP_TEAM_EMAIL);
            sendEmails(emailList);
        }
    }

    public class SendEmailToCESE extends Triggers.TriggerHandlerBase {
       
       override public void handle() {
            Set<Id> oppIdSet = new Set<Id>();
            if (Trigger.isInsert) {
                oppIdSet = handleInsertScenario();
            } else if (Trigger.isUpdate) {
                oppIdSet = handleUpdateScenario();
            }
            if (!oppIdSet.isEmpty()) {
                sendEmailsToCESE(oppIdSet);
            }
        }
        
        private Set<Id> handleInsertScenario() {
            Set<Id> oppIdSet = new Set<Id>();
            Map<Id,Id> masterToOppMap = new Map<Id,Id>();

            for (Quote q : (List<Quote>) Trigger.new) {
                if (q.RecordTypeId == POC_QUOTE_RT_ID && isEngageVoiceStandalone(q.ServiceName__c)) {
                    if (q.IsMultiProductTechnicalQuote__c && q.MasterQuote__c != null) {
                        masterToOppMap.put(q.MasterQuote__c, q.OpportunityId);
                    } else if (q.isPrimary__c && !q.IsQuoteHasErrors__c) {
                        oppIdSet.add(q.OpportunityId);
                    }
                }
            }

            if (!masterToOppMap.isEmpty()) {
                oppIdSet.addAll(getOppIdsFromErrorFreeMasterQuotes(masterToOppMap));
            }

            return oppIdSet;
        }
        
        private Set<Id> handleUpdateScenario() {
            Set<Id> oppIdSet = new Set<Id>();
            Set<Id> masterQuoteIdsToCheck = new Set<Id>();

            for (Quote q : (List<Quote>) Trigger.new) {
                Boolean becamePrimary = isChangedFieldTo(q, Quote.isPrimary__c, true);
                Boolean errorsBecameFalse = isChangedFieldTo(q, Quote.IsQuoteHasErrors__c, false);

                Boolean shouldTrigger = (becamePrimary && !q.IsQuoteHasErrors__c) ||
                                       (errorsBecameFalse && q.isPrimary__c);
                if (shouldTrigger && q.RecordTypeId == POC_QUOTE_RT_ID) {
                    if (isEngageVoiceStandalone(q.ServiceName__c)) {
                        oppIdSet.add(q.OpportunityId);
                    } else {
                        masterQuoteIdsToCheck.add(q.Id);
                    }
                }
            }
            
            if (!masterQuoteIdsToCheck.isEmpty()) {
                oppIdSet.addAll(getOppIdsFromEngageVoiceTechQuotes(masterQuoteIdsToCheck));
            }
            return oppIdSet;
        }
        
        private Set<Id> getOppIdsFromEngageVoiceTechQuotes(Set<Id> masterQuoteIds) {
            List<Quote> technicalQuotes = (List<Quote>) new QuoteSelector()
                    .selectMultiProductTechnicalQuotesByMasterQuoteIds(masterQuoteIds)
                    .setCondition('MasterQuote__c IN :bind0 AND IsMultiProductTechnicalQuote__c = true AND ServiceName__c = :bind1')
                    .setQueryBindings(new List<Object>{masterQuoteIds, ENGAGE_VOICE_STANDALONE_SERVICE})
                    .executeQuery();
            
            
            Set<Id> opportunityIds = new Set<Id>();
            for (Quote technicalQuote : technicalQuotes) {
                opportunityIds.add(technicalQuote.OpportunityId);
            }
            return opportunityIds;
        }
        
        private void sendEmailsToCESE(Set<Id> oppIdSet) {
            Map<Id, OpportunityTeamMember> oppTeamMemberMap = getOpportunityTeamMembers(oppIdSet, CESE_ROLE);
            List<Messaging.SingleEmailMessage> emailList = buildEmailList(oppIdSet, oppTeamMemberMap, POC_OPPORTUNITY_CESE_LEADERSHIP_TEAM_EMAIL);
            sendEmails(emailList);
        }
        
         private Set<Id> getOppIdsFromErrorFreeMasterQuotes(Map<Id, Id> masterToOppMap) {
            List<Quote> masterQuotes = (List<Quote>) new QuoteSelector()
                    .selectQuoteById(new List<Object>{masterToOppMap.keySet()})
                    .executeQuery();
            
            Set<Id> oppIds = new Set<Id>();
            for (Quote masterQuote : masterQuotes) {
                if (masterQuote.isPrimary__c && !masterQuote.IsQuoteHasErrors__c && masterToOppMap.containsKey(masterQuote.Id)) {
                    oppIds.add(masterToOppMap.get(masterQuote.Id));
                }
            }
            return oppIds;
        }
         
        private Boolean isEngageVoiceStandalone(String serviceName) {
            return serviceName != null && serviceName.equalsIgnoreCase(ENGAGE_VOICE_STANDALONE_SERVICE);
        }
    }

    public class SalesAgreementStatusChangeValidation extends Triggers.TriggerHandlerBase {
        Set<Id> quoteIdsWithCompletedDocusignStatus = new Set<Id>();
        Map<Id, Boolean> masterQuoteOrParentOpportunityToHasProServ = new Map<Id, Boolean>();
        override public void handle() {
            // Check if validation is enabled for current user/profile
            if (isSalesAgreementStatusChangeValidationEnabled()) {
                return;
            }

            if (isBypassUser()) {
                return;
            }

            List<Quote> quotesToProcess = new List<Quote>();
            for (Quote qt : (List<Quote>) Trigger.new) {
                if (qt.RecordTypeId == PROSERV_QUOTE_RT_ID || qt.RecordTypeId == CC_PROSERV_QUOTE_RT_ID) {
                    continue; // Skip for ProServ Legacy quote
                }
                if (engageVoiceServiceNames.contains(qt.ServiceName__c)) {
                    continue; // Skip for Engage Voice service
                }
                if (qt.ServiceName__c == QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT) {
                    continue; // Skip for Professional Services service
                }
                if (QuoteHelper.isNewBillingQuote(qt) && isChangedFieldTo(qt, Quote.Status, STATUS_ACTIVE)) {
                    quotesToProcess.add(qt);
                }
            }

            // Skip execution if there are no quotes to be changed to active
            if (quotesToProcess.isEmpty()) {
                return;
            }

            Set<Id> allQuoteIds = new Set<Id>();
            for (Quote quote : quotesToProcess) {
                allQuoteIds.add(quote.Id);
                if (quote.MasterQuote__c != null) {
                    allQuoteIds.add(quote.MasterQuote__c);
                }
            }
            quoteIdsWithCompletedDocusignStatus = new DocuSignStatusSelector()
                .selectQuotesForCompletedDocuSignStatus(new List<Object>{allQuoteIds});

            masterQuoteOrParentOpportunityToHasProServ = getMasterQuoteOrParentOpportunityToHasProServ(Trigger.new);

            for (Quote quote : quotesToProcess) {
                ID quoteId = (Quote.IsPrimary__c && quote.MasterQuote__c == null) ? quote.Id : quote.MasterQuote__c;
                String errorMessage = Quote.IsPrimary__c
                    ? Label.Quote_Status_Change_To_Active_Validation_Error
                    : Label.Non_Primary_Quote_Status_Change_To_Active_Validation_Error;

                Boolean hasProserv = getHasProserv(quoteId, quote.OpportunityId);
                Boolean hasCompletedDocusignStatus = quoteIdsWithCompletedDocusignStatus.contains(quoteId);

                if (!hasCompletedDocusignStatus && !hasProserv) {
                    quote.addError(errorMessage);
                }
            }
        }

        private Boolean getHasProserv(Id quoteId, Id oppId) {
            if (Test.isRunningTest()) {
                return true;
            }
            Boolean result1 = masterQuoteOrParentOpportunityToHasProServ.containsKey(quoteId)
                ? masterQuoteOrParentOpportunityToHasProServ.get(quoteId)
                : false;
            Boolean result2 = masterQuoteOrParentOpportunityToHasProServ.containsKey(oppId)
                ? masterQuoteOrParentOpportunityToHasProServ.get(oppId)
                : false;
            return result1 || result2;
        }

        private Boolean isSalesAgreementStatusChangeValidationEnabled() {
            return Feature_Toggle__c.getInstance().SalesAgreementStatusChangeValidation__c;
        }

        private Boolean isBypassUser() {
            try {
                if (bypassUserNames?.contains(UserInfo.getName())) {
                    return true;
                } else {
                    return false;
                }
            } catch (Exception e) {
                PlatformLog.logException('QuoteTriggerHelper.isBypassUser', e);
                return false;
            }
        }

        private Map<Id, Boolean> getMasterQuoteOrParentOpportunityToHasProServ(List<Quote> quotes) {
            Map<Id, Boolean> masterQuoteOrParentOpportunityToHasProServ = new Map<Id, Boolean>();
            for (Quote quote : quotes) {
                if (QuoteHelper.isNewBillingQuote(quote)) {
                    Id masterQuoteId = quote.MasterQuote__c != null ? quote.MasterQuote__c : quote.Id;
                    masterQuoteOrParentOpportunityToHasProServ.put(masterQuoteId, false);
                    masterQuoteOrParentOpportunityToHasProServ.put(quote.OpportunityId, false);
                }
            }
            List<Quote> technicalQuotes = [
                SELECT Id, RecordTypeId, ServiceName__c, OpportunityId, MasterQuote__c
                FROM Quote
                WHERE
                (
                    MasterQuote__c IN :masterQuoteOrParentOpportunityToHasProServ.keySet() OR
                    OpportunityId IN :masterQuoteOrParentOpportunityToHasProServ.keySet()
                )
                AND (
                    RecordTypeId = :CC_PROSERV_QUOTE_RT_ID OR
                    RecordTypeId = :PROSERV_QUOTE_RT_ID OR
                    ServiceName__c = 'Professional Services'
                )
            ];
            for (Quote technicalQuote: technicalQuotes) {
                if (technicalQuote.MasterQuote__c != null) {
                    masterQuoteOrParentOpportunityToHasProServ.put(technicalQuote.MasterQuote__c, true);
                } else {
                    masterQuoteOrParentOpportunityToHasProServ.put(technicalQuote.OpportunityId, true);
                }
            }
            return masterQuoteOrParentOpportunityToHasProServ;
        }
    }
}