/* This class is aimed to serve snProcessOrder component.
 * Thus should contain only @auraEnabled methods
 * */
public with sharing class ProcessOrder {
    @TestVisible
    private static final String ERROR_ACTION = 'Cannot find action';

    @AuraEnabled
    public static POWrappers.OppDetailWrapper getOppBillingDetail(String OppId) {
        POWrappers.OppDetailWrapper oppWrapper = new POWrappers.OppDetailWrapper();
        Set<Id> oppIds = new Set<Id> { OppId };
        try {
            oppWrapper.opportunity = (Opportunity) new ListOptional(new OpportunitySelector()
                .selectOpportunitiesByIds(oppIds)
                .selectFields(new List<String> {
                    'Account.Internal_Enterprise_Account_ID__c',
                    'Account.Billing_ID__c',
                    'Account.Name',
                    'Account.RC_Account_Status__c',
                    'Account.RC_User_ID__c',
                    'Account.CSM__c',
                    'Account.Parent_Partner_Account__c',
                    'Account.IsMultiProductTechnicalAccount__c',
                    'Account.Id',
                    'Account.OwnerId',
                    'Parent_Order__c'
                })
                .executeQuery()
            ).getFirst();

            if (oppWrapper.opportunity.Parent_Order__c == null) {
                oppWrapper.masterAndTechQuotes = new QuoteSelector()
                    .selectMasterAndTechnicalQuotes(oppIds)
                    .executeQuery();

                oppWrapper.isMultiProductFTEnabled = POHelper.isMultiproductEnabled;
                oppWrapper.isSimplifiedLboDownsellEnabled = POHelper.isSimplifiedLboDownsellEnabled;
                BillingWrappers.NGBSAccount accountInfo = NGBSAPI.getNGBSAccount(oppWrapper.opportunity.Account.Billing_ID__c);
                oppWrapper.ngbsAccountStatus = accountInfo?.status;

                oppWrapper.isMPUB = AccountHelper.isMPUBAccount(oppWrapper.opportunity.Account);
                oppWrapper.productNameToPackageIsActiveStatusMap = POHelper.buildProductNameToPackageIsActiveStatusMap(oppWrapper, accountInfo);
                oppWrapper.qtIdToSyncInfoMap = POHelper.buildQtIdToSyncInfo(oppWrapper);
            }

        } catch (Exception ex) {
            oppWrapper.message = 'Error: ' + ex.getMessage();
            System.debug('Error:' + ex.getMessage() + ' ' + ex.getStackTraceString());
        }

        return oppWrapper;
    }

    @AuraEnabled
    public static String handleSignUp(String params) {
        Response resp = new Response();

        POWrappers.ActionRequestParams requestParams = (POWrappers.ActionRequestParams)
            JSON.deserialize(params, POWrappers.ActionRequestParams.class);

        switch on requestParams.action {
            when QUERY_DATA {
                resp.setData(
                    POHelper.queryData(
                        requestParams.targetIds
                    )
                );
            }
            when VALIDATE_DATA {
                resp.setData(
                    POHelper.validateData(
                        requestParams.dataArr
                    )
                );
            }
            when CREATE_DEAL_DESK_CASE_DESCRIPTION {
                resp.setData(
                    POHelper.createDealDeskCaseDescriptions(
                        requestParams.dataArr
                    )
                );
            }
            when EXECUTE_PRESIGNUP_ACTIONS {
                resp.setData(
                    POHelper.executePreSignUpActions(
                        requestParams.dataArr
                    )
                );
            }
            when VALIDATE_PROCESS_ORDER {
                resp.setData(
                    POHelper.validateProcessOrder(
                        requestParams.data
                    )
                );
            }
            when SIGNUP {
                resp.setData(
                    POHelper.signUpNGBS(
                        requestParams.data
                    )
                );
            }
            when BODY_PREVIEW {
                resp.setData(
                    POHelper.previewSignUpBody(
                        requestParams.data
                    )
                );
            }
            when UPDATE_PROCESS_ORDER_CC_SYNC_STATUS {
                resp.setData(
                    POHelper.updateMasterOpportunityRCCCSyncStatus(
                        requestParams
                    )
                );
            }
            when else {
                resp.setData('error', ERROR_ACTION);
            }
        }
        return JSON.serialize(resp);
    }

    @AuraEnabled
    public static String handleSubmit(String params) {
        Response resp = new Response();

        BillingWrappers.RequestSubmitParams requestParams =
            (BillingWrappers.RequestSubmitParams) JSON.deserialize(params, BillingWrappers.RequestSubmitParams.class);
        switch on requestParams.action.toLowerCase() {
            when 'submit contact center' {
                resp.setData(
                    ICBAPI.submitRCCCPatchRequest(requestParams)
                );
            }

            when 'submit post contact center' {
                resp.setData(
                    ICBAPI.submitRCCCPostRequest(requestParams)
                );
            }

            when 'submit engage digital' {
                resp.setData(
                    CCBAPI.submitEngage(requestParams)
                );
            }

            when 'submit engage voice' {
                resp.setData(
                    CCBAPI.submitEngage(requestParams)
                );
            }

            when 'request order to vendor' {
                resp.setData(ICBAPI.requestOrderToVendor(requestParams));
            }

            when 'get dictionaries' {
                resp.setData(ICBAPI.getDictionaries());
            }

            when 'validate address' {
                resp.setData(POHelper.validateBillingAddress(requestParams));
            }

            when 'request engage platforms' {
                resp.setData(
                    CCBAPI.getEngagePlatforms(requestParams.isEngageVoice)
                );
            }

            when else {
                resp.setData('error', ERROR_ACTION);
            }
        }
        return JSON.serialize(resp);
    }

    @AuraEnabled
    public static String createOrders(String OppId, List<String> targetIds) {
        Response res = new Response();

        try {
            Opportunity opp = (Opportunity) new OpportunitySelector()
                .selectOpportunitiesByIds(new Set<Id> {OppId})
                .selectFields(new List<String> {
                    'PrimaryQuote__c',
                    'Account.Id',
                    'Account.IsMultiProductTechnicalAccount__c'
                })
                .subselect(new QuoteSelector()
                    .selectQuotes()
                    .withoutSelectorFieldsIncluded()
                    .setCondition('isPrimary__c = true AND IsMultiProductTechnicalQuote__c = false')
                )
                .executeQuery()
                .get(0);

            if (!AccountHelper.isMPUBAccount(opp.Account)
                || opp.Quotes.isEmpty() // no primary quote
                || !OrderHelper.SERVICE_NAME_TO_RT_ID_MP_UB.containsKey(opp.Tier_Name__c)) {

                res.addMessage('Success', 'Orders creation is skipped', Response.STATUS_SUCCESS);
                return JSON.serialize(res);
            }

            Set<Id> targetIdSet = new Set<Id>();
            for (String targetId : targetIds) {
                targetIdSet.add(Id.valueOf(targetId));
            }
            
            List<Quote> allQuotes = (List<Quote>) new QuoteSelector()
                .selectQuotesForOrderCreationByIds(targetIdSet)
                .executeQuery();

            Map<Id, Quote> notAcquiredServiceQuotes = new Map<Id, Quote>();
            for (Quote qt : allQuotes) {
                if (qt.ServiceInfo__r.isEmpty()) {
                    continue;
                }

                if (!qt.ServiceInfo__r[0].IsProcessOrderSent__c && String.isBlank(qt.BillingPackage__c)) {
                    notAcquiredServiceQuotes.put(qt.Id, qt);
                }
            }

            List<Quote> quotesForOrderCreation = new List<Quote>();
            for (Quote qt : notAcquiredServiceQuotes.values()) {
                if (qt.isPrimary__c || qt.masterQuote__r.isPrimary__c) {
                    quotesForOrderCreation.add(qt);
                }
            }

            OrderHelper.QuoteOrdersFactory qof = new OrderHelper.QuoteOrdersFactory(quotesForOrderCreation, true, true);
            Map<Id, List<Order>> ordersByQuoteId = qof.buildOrdersForQuotes();

            List<Order> ordList = new List<Order>();
            for (Id quoteId : ordersByQuoteId.keySet()) {
                ordList.addAll(ordersByQuoteId.get(quoteId));
            }

            Map<Id, Order> ordersToRemoveMap = new Map<Id, Order>((List<Order>) new OrderSelector()
                .selectOrdersByTechQuoteIds(notAcquiredServiceQuotes.keySet())
                .selectFields(new List<String>{'Id'})
                .executeQuery());

            OrderHelper.deletePreviousOrders(ordersToRemoveMap);

            if (!ordList.isEmpty()) {
                insert ordList;
            }

            List<Order> proServOrders = new List<Order>();
            for (Order order : ordList) {
                if (order.RecordTypeId == OrderHelper.RT_ID_PROSERV) {
                    proServOrders.add(order);
                }
            }

            if (!proServOrders.isEmpty()) {
                Map<Id, Phase__c> phasesMap =  new Map<Id, Phase__c>((List<Phase__c>)new PhaseSelector()
                    .selectPhasesByQuoteIds(new List<Object>{new Set<Id> { opp.PrimaryQuote__c }})
                    .selectFields(new List<String>{'Order__r.orderNumber'})  
                    .executeQuery());
                List<Suborder__c> suborders = SuborderHelper.createSuborders(proServOrders, phasesMap);
                SuborderLineItemHelper.createSuborderLineItems(suborders, phasesMap);
            }
        } catch(Exception e) {
            AquivaHelper.throwAquivaException(e);
        }

        res.addMessage('Success', 'Orders creation processed successfully', Response.STATUS_SUCCESS);
        return JSON.serialize(res);
    }

    @AuraEnabled
    public static void updateSyncInfoAfterSyncICB(Id quoteId, String userName) {
        SWNDataCollector sdc = new SWNDataCollector(quoteId);
        Response res = SWNScenarioHelper.getSyncScenario(sdc);
        SWNScenarioHelper.Scenario sc = (SWNScenarioHelper.Scenario) res.data.get(SWNScenarioHelper.SCENARIO);
        String scenarioName = (String) res.data.get(SWNScenarioHelper.SCENARIO_KEY);

        sdc.syncable.setSyncInfo(
            SWNSyncInfo.updateSyncInfoJson(
                scenarioName,
                sdc.syncable.getSyncInfoField(),
                SWNStep.SYNC_TO_ICB,
                userName,
                sc.stepNames
            )
        );
        sdc.syncable.updateSObject();
    }

    @AuraEnabled
    public static String checkIsMainCostCenterExist(String params) {
        Response resp = new Response();
        POWrappers.CostCenterParams requestParams = (POWrappers.CostCenterParams)
            JSON.deserialize(params, POWrappers.CostCenterParams.class);

        resp.setData(
            POHelper.checkIsMainCostCenterExist(
                requestParams.billingId
            )
        );
        return JSON.serialize(resp);
    }

    @AuraEnabled
    public static String createMainCostCenter(String params) {
        Response resp = new Response();
        POWrappers.CostCenterParams requestParams = (POWrappers.CostCenterParams)
            JSON.deserialize(params, POWrappers.CostCenterParams.class);

        resp.setData(
            POHelper.createMainCostCenter(
                requestParams.billingId
            )
        );
        return JSON.serialize(resp);
    }
}