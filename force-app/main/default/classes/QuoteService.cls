@RestResource(UrlMapping='/QuoteService/*')
global with sharing class QuoteService {

    @HttpPost
    global static void quote() {
        String result = '';
        String body = RestContext.request.requestBody.toString();
        BillingWrappers.Params paramsData = (BillingWrappers.Params)JSON.deserialize(body, BillingWrappers.Params.class);
        RestResponse res = RestContext.response;
        if (res == null) {
            res = new RestResponse();
            RestContext.response = res;
        }
        try {
            if (paramsData.action == 'check') {
                result = JSON.serialize(UserInfo.getUserId());
            }

            else if (paramsData.action == 'getCCLegacyQuotes') {
                result = JSON.serializePretty(getCCLegacyQuotes(paramsData));
            }

            else if (paramsData.action == 'getProServLegacyQuotes') {
                result = JSON.serializePretty(getProServLegacyQuotes(paramsData));
            }

            // TODO: move to data from leadConvert
            else if (paramsData.action == 'getAccount') {
                result = JSON.serializePretty(getAccount(paramsData.accountId));
            }

            /* Create Quote */
            else if (paramsData.action == 'createSalesQuote') {
                Quote quote = createSalesQuote(paramsData);
                result = JSON.serializePretty(quote);
            }
            else if (paramsData.action == 'createTerminationSalesQuote') {
                Quote quote = createTerminationSalesQuote(paramsData);
                result = JSON.serializePretty(quote);
            }

            else if (paramsData.action == 'createTechnicalQuotes' || paramsData.action == 'updateTechnicalQuotes') {
                Map<String, Quote> serviceQuotes = new Map<String, Quote>();
                if (paramsData.quotesByService != null) {
                    serviceQuotes = upsertTechnicalQuotes(paramsData.quoteId, paramsData.quotesByService);
                } else if (paramsData.serviceNames != null) {
                    serviceQuotes = upsertTechnicalQuotes(paramsData.quoteId, paramsData.serviceNames);
                }
                result = JSON.serializePretty(serviceQuotes);
            }
            else if (paramsData.action == 'createTechnicalQuotesUB' || paramsData.action == 'updateTechnicalQuotesUB') {
                Map<String, Quote> serviceQuotes = new Map<String, Quote>();
                if (paramsData.quotesByService != null) {
                    serviceQuotes = upsertTechnicalQuotesUB(paramsData.quoteId, paramsData.quotesByService);
                } else if (paramsData.serviceNames != null) {
                    serviceQuotes = upsertTechnicalQuotesUB(paramsData.quoteId, paramsData.serviceNames);
                }
                result = JSON.serializePretty(serviceQuotes);
            }
            else if (paramsData.action == 'getServiceInfo') {
                List<ServiceInfo__c> serviceInfo = getServiceInfo(paramsData.quoteId);
                result = JSON.serialize(serviceInfo);
            }
            else if (paramsData.action == 'syncServiceInfo') {
                List<ServiceInfo__c> serviceInfo = syncServiceInfo(paramsData);
                result = JSON.serialize(serviceInfo);
            }
            else if (paramsData.action == 'getTechnicalQuotes') {
                if (paramsData.serviceNames != null && paramsData.quoteId != null) {
                    Map<String, Quote> serviceQuotes = getTechnicalQuotes(paramsData.quoteId, paramsData.serviceNames);
                    result = JSON.serializePretty(serviceQuotes);
                } else if (paramsData.opportunityId != null ) {
               	 	result = JSON.serializePretty(getTechnicalQuotes(paramsData));
                }
            }
            else if (paramsData.action == 'getTechnicalQuotesUB') {
                if (paramsData.serviceNames != null && paramsData.quoteId != null) {
                    Map<String, Quote> serviceQuotes = getTechnicalQuotesUB(paramsData.quoteId, paramsData.serviceNames);
                    result = JSON.serializePretty(serviceQuotes);
                } else if (paramsData.opportunityId != null ) {
               	 	result = JSON.serializePretty(getTechnicalQuotesUB(paramsData));
                }
            }
            else if (paramsData.action == 'createPOCQuote') {
                Quote quote = createPOCQuote(paramsData);
                result = JSON.serializePretty(quote);
            }

            else if (paramsData.action == 'updatePackage') {
                List<Quote> newQuoteList = updatePackage(paramsData);
                result = JSON.serialize(newQuoteList);
            }

            /* Update Quote  */
            else if (paramsData.action == 'update') {
                List<Quote> newQuoteList = updateQuote(paramsData);
                result = JSON.serialize(newQuoteList);
            }

            /* Update Quotes LBO  */
            else if (paramsData.action == 'updateLBOForQuotes') {
                List<Quote> newQuoteList = updateLBOForQuotes(paramsData);
                result = JSON.serialize(newQuoteList);
            }

            /* Upgrade Quote */
            else if (paramsData.action == 'upgrade') {
                List<Quote> newQuoteList = upgradeQuote(paramsData);
                result = JSON.serialize(newQuoteList);
            }

            /* Delete Quote */
            else if (paramsData.action == 'delete') {
                List<Quote> newQuoteList = deleteQuotes(paramsData);
                result = JSON.serialize(newQuoteList);
            }

            /* Make Primary */
            else if (paramsData.action == 'primary') {
                List<Quote> newQuoteList = makePrimaryQuote(paramsData);
                result = JSON.serialize(newQuoteList);
            }

            /* Recalculate Quote Approvals */
            else if (paramsData.action == 'recalculateApprovals') {
                List<Quote> newQuoteList = recalculateApprovals(paramsData);
                result = JSON.serialize(newQuoteList);
            }

            /* Clear Quote (delete qlis) */
            else if (paramsData.action == 'clear') {
                Quote qt = clearQuote(paramsData);
                result = JSON.serialize(qt);
            }

            /* Run Approval Process */
            else if (paramsData.action == 'approval') {
                List<Quote> newQuoteList = processApproval(paramsData);
                result = JSON.serialize(newQuoteList);
            }

            /* Engage Legal */
            else if (paramsData.action == 'engageLeagal') {
                List<Quote> newQuoteList = processEngageLegal(paramsData);
                result = JSON.serialize(newQuoteList);
            }

            /* Get Engage Legal Options */
            else if (paramsData.action == 'getEngageLeagalOptions') {
                result = getEngageLegalOptions();
            }

            /* Get PDF Templates */
            else if (paramsData.action == 'templates') {
                List<RC_Quote_Template__c> templates = PDFTemplateHelper.getPdfTemplates(
                        paramsData.opportunityId,
                        paramsData.quoteId
                    );
                result = JSON.serialize(templates);
            }

            /* Attach PDF Templates */
            else if (paramsData.action == 'attach') {
                String attachmentId = OpportunityHelper.AttachPdfToOpportunity(
                    paramsData.opportunityId, paramsData.quoteId, paramsData.templateId, paramsData.templateParameters);
                result = JSON.serialize(attachmentId);
            }

            /* Engage ProServ */
            else if (paramsData.action == 'engageProServ') {
                String details = paramsData.data.get('details');
                String type = paramsData.data.get('type');
                QuotingToolQuoteApexController.engageProServ(paramsData.opportunityId, paramsData.accountId, details, type, true);

                List<Quote> currentQuoteList = getUpdatedQuoteList(paramsData);
                result = JSON.serialize(currentQuoteList);
            }

            /* Engage ProServ Ignite */
            else if (paramsData.action == 'engageProServIgnite') {
                Id selectedQuoteId = paramsData.data.get('selectedQuoteId');
                String proServCaseReasons = paramsData.data.get('proServCaseReasons');
                proServIgnite(selectedQuoteId, proServCaseReasons, 'engageProServIgnite');
                List<Quote> currentQuoteList = getUpdatedQuoteList(paramsData);
                result = JSON.serialize(currentQuoteList);
            }

            /* Remove/Update ProServ Prods */
            else if (paramsData.action == 'removeProServProds') {
                String details = paramsData.data.get('details');
                String type = paramsData.data.get('type');
                Boolean doDelete = Boolean.valueOf(paramsData.data.get('doDelete'));
                Boolean doUpdate = Boolean.valueOf(paramsData.data.get('doUpdate'));
                QuotingToolQuoteApexController.removeProServProds(paramsData.opportunityId, type, doDelete, doUpdate, true);

                List<Quote> currentQuoteList = getUpdatedQuoteList(paramsData);
                result = JSON.serialize(currentQuoteList);
            }

            /* Cancel Proserv engagement */
            else if (paramsData.action == 'cancelEngageProServ') {
                String details = paramsData.data.get('details');
                String type = paramsData.data.get('type');
                QuotingToolQuoteApexController.cancelProServ(paramsData.opportunityId, details, type, true);

                List<Quote> currentQuoteList = getUpdatedQuoteList(paramsData);
                result = JSON.serialize(currentQuoteList);
            }

            /* Cancel ProServ Ignite */
            else if (paramsData.action == 'cancelProServIgnite') {
                Id selectedQuoteId = paramsData.data.get('selectedQuoteId');
                proServIgnite(selectedQuoteId, null, 'cancelProServIgnite');
                List<Quote> currentQuoteList = getUpdatedQuoteList(paramsData);
                result = JSON.serialize(currentQuoteList);
            }

            else if (paramsData.action == 'syncAreaCodeLineItems') {
                AreaCodeService.syncAreaCodeItems(paramsData);

                List<Quote> newQuoteList = getUpdatedQuoteList(paramsData);
                result = JSON.serialize(newQuoteList);
            }

            /* matchBillingCodesFromBillingApi */
            else if (paramsData.action == 'matchBillingCodesFromBillingApi') {
                result = JSON.serialize(matchBillingCodesFromBillingApi(paramsData.quoteId, paramsData.billingCodes, paramsData.taxLocations.addresses));
            }

            /* Get Cost Center Items */
            else if (paramsData.action == 'getCostCenterItems') {
                String quoteId = paramsData.quoteId;
                result = JSON.serialize(getBillingCodes(quoteId));
            }

            /* Sync Cost Center Items */
            else if (paramsData.action == 'syncCostCenterItems') {
                String quoteId = paramsData.quoteId;
                List<Cost_Center__c> costCenters = getCostCenters(quoteId);
                if (costCenters.size() > 0) {
                    syncCostCenterItems(costCenters, paramsData);
                } else {
                    createCostCenters(quoteId, paramsData.billingCodes);
                }

                List<BillingWrappers.BillingCode> billingCodes = new List<BillingWrappers.BillingCode>();
                billingCodes = getBillingCodes(quoteId);
                result = JSON.serialize(billingCodes);

            }else if (paramsData.action == 'refreshEnvelopes') {

                Id opportuintyId = paramsData.opportunityId;
                Id quoteId = paramsData.quoteId;

                result = JSON.serialize(DocuSignController.getEnvelopes(opportuintyId, quoteId));

            }else if (paramsData.action == 'refreshDocuments') {

                Id quoteId = paramsData.quoteId;

                result = JSON.serialize(DocuSignController.getLinkedOpportunityList(quoteId));

            }else if (paramsData.action == 'refreshRecipients') {

                Id opportuintyId = paramsData.opportunityId;

                result = JSON.serialize(DocuSignController.getRecipients(opportuintyId));

            }else if (paramsData.action == 'validateDocusignBeforeStart') {

                Id opportuintyId = paramsData.opportunityId;
                Id selectedQuoteId = paramsData.selectedQuoteId;

                result = JSON.serialize(DocuSignController.validateBeforeStart(opportuintyId, selectedQuoteId));

            }else if (paramsData.action == 'getDocuSignData') {

                Id opportuintyId = paramsData.opportunityId;
                Id quoteId = paramsData.quoteId;

                result = JSON.serialize(DocuSignController.getDataOnInit(opportuintyId, quoteId));

            }else if (paramsData.action == 'DocuSignSend') {

                Id quoteId = paramsData.quoteId;

                List<Id> selectedDocsIds = paramsData.selectedDocsIds;

                result = JSON.serialize(DocuSignController.send(quoteId, selectedDocsIds));

            }else if (paramsData.action == 'completeEnvelope') {

                Id envelopeId = paramsData.envelopeId;

                result = JSON.serialize(DocuSignController.completeEnvelope(envelopeId));

            }else if (paramsData.action == 'getClmLicenseAvailability') {
                result = JSON.serialize(DocuSignHelper.getClmLicenseAvailability());

            }else if (paramsData.action == 'createPOCApproval') {

                Approval__c pocApproval = createPOCApproval(paramsData);

                if (DQGoa.isDQGoaEnabled()) {
                    submitPocApproval(pocApproval.Id);
                }

                result = JSON.serialize(pocApproval.Id);

            }else if (paramsData.action == 'updateQuoteBillingAddress') {
                Quote q = copyBillingAddressFromAccountToQuote(paramsData.quoteId, paramsData.accountId);
                result = JSON.serialize(q);

            }else if (paramsData.action == 'cloneQuote') {
                Quote q = cloneQuote(paramsData.quoteId, paramsData.masterQuoteId);
                result = JSON.serialize(q);

            }else if (paramsData.action == 'taxesReestimated' && TaxExemptionHelper.isEnabled) {
                Id quoteId = paramsData.quoteId;
                Quote q = new Quote(
                    Id = quoteId,
                    NeedTaxesReestimation__c = false
                );
                update q;

                result = JSON.serialize(q);

            } else if (paramsData.action == 'getApproversForQuote') {
                Id quoteId = paramsData.quoteId;

                if (DQGoa.isDQGoaEnabled()) {
                    result = DQGoa.getApproversDataJSON(DQGoa.getApproversForQuote(quoteId));
                } else {
                    result = JSON.serialize(new List<String>());
                }
            } else if (paramsData.action == 'updateQuoteApprovalStatus') {
                Id quoteId = paramsData.quoteId;
                String status = null;

                if (DQGoa.isDQGoaEnabled()) {
                    status = DQGoa.updateQuoteApprovalStatus(quoteId, DQGoa.getApproversForQuote(quoteId));
                }

                result = JSON.serialize(status);
            } else if (paramsData.action == 'getDQHistory') {
                if (DQGoa.isDQGoaEnabled()) {
                    result = DQGoa.getDQHistoryJSON(paramsData.opportunityId);
                } else {
                    result = JSON.serialize(new List<DQ_Deal_Qualification_History__c>());
                }
            } else if (paramsData.action == 'getDQApprovals') {
                if (DQGoa.isDQGoaEnabled()) {
                    result = DQApproverHelper.getDQApprovalsJSON(paramsData.opportunityId);
                } else {
                    result = JSON.serialize(new List<DQApproverHelper.ApprovalData>());
                }
            } else if (paramsData.action == 'updateDQApproval') {
                DQ_Deal_Qualification_Approver__c updatedDQApprover =  DQApproverHelper.updateDQApproval(paramsData.dqApprover, paramsData.dqAction);
                List<Quote> updatedQuotes = QuoteHelper.getAllQuotes(paramsData);
                result = JSON.serialize(updatedQuotes);
            } else if (paramsData.action == 'getProservDetail') {
                Id opptyId = paramsData.opportunityId;
                BillingWrappers.ProservParam proservParam = getProservDetail(opptyId);
                result = JSON.serialize(proservParam);
            } else {
                List<Quote> currentQuoteList = getUpdatedQuoteList(paramsData);
                result = JSON.serialize(currentQuoteList);
            }
            res.responseBody = Blob.valueOf(result);
        } catch(Exception e) {
            Map<String,String> errMsg = new Map<String,String>();
            errMsg.put('error', e.getMessage());
            errMsg.put('stackTrace', e.getStackTraceString());
            res.responseBody = Blob.valueOf( JSON.serialize(errMsg) );
            // res.statusCode = 200;
        }
    }

    /*
        Helper methods
    */
    public static List<Quote> populateAvailableApprovalActions(List<Quote> existingQuotes, Boolean isUserCanApprove) {
        Set<String> requiresApprovalStatuses = new Set<String> {'Required','Recalled','Rejected'};

        String result;
        Boolean isInApproval = false;
        Boolean isAdmin = AquivaHelper.isAdmin();

        Set<Id> requireApprovalIdSet = getRequireApprovalIdSet(existingQuotes);
        Map<Id, List<Custom_GOA__c>> quoteIdToCustomGOA = QuoteApprovals.getMatchingGOAs(existingQuotes);
        Map<Id, List<Id>> queueIdsByQuoteIds = QuoteApprovals.collectQueueIdsByQuoteIds(quoteIdToCustomGOA);
        Map<Id, List<Id>> userIdsByQueueIds = QuoteApprovals.fetchQueueMembers(queueIdsByQuoteIds);

        for(Quote currentQuote:existingQuotes) {
            result = '';

            Boolean isFinanceApproval = currentQuote.Approved_Status__c == 'Pending Finance Approval' ||
                (currentQuote.Approved_Status__c == 'Pending L1 Approval' &&
                currentQuote.Approval_Type__c == 'Finance Queue' &&
                currentQuote.Level_1_Approver__c == null);

            Boolean isDownsellApproval = currentQuote.Approved_Status__c == ApprovalHelper.STATUS_PENDING_DOWNSELL_APPROVAL ||
                    (currentQuote.Approved_Status__c == 'Pending L1 Approval'
                    && currentQuote.DownsellApprover__c == GroupHelper.APPROVAL_DOWNSELL_QUEUE
                    && currentQuote.Level_1_Approver__c == null);

            Boolean isProservApproval = currentQuote.Approved_Status__c == ApprovalHelper.STATUS_PENDING_PROSERV_APPROVAL ||
                (currentQuote.Approved_Status__c == ApprovalHelper.STATUS_PENDING_PROSERV_APPROVAL &&
                currentQuote.Approval_Type__c == GroupHelper.APPROVAL_NGBS_PROSERV_QUEUE);

            isInApproval = currentQuote.Approved_Status__c != null
                ? Pattern.matches('Pending L[0-9]+ Approval', currentQuote.Approved_Status__c) || isFinanceApproval || isDownsellApproval || isProservApproval
                : false;


            if (currentQuote.QuoteType__c != 'Agreement' && !OpportunityHelper.isClosed(currentQuote.Opportunity.StageName)) {
                if (currentQuote.Opportunity.OwnerId == UserInfo.getUserId()
                    || currentQuote.CreatedById == UserInfo.getUserId()
                    || isUserCanApprove
                    || isAdmin) {
                    if (requiresApprovalStatuses.contains(currentQuote.Approved_Status__c) && !isFinanceApproval && !isDownsellApproval && !isProservApproval) {
                        result += 'Submit;';
                    } else if (isInApproval) {
                        result += 'Recall;';
                    }
                }

                Map<SObjectField, Set<Id>> approversByField = new Map<SObjectField, Set<Id>> {
                    Custom_GOA__c.L1_Approver__c => new Set<Id>(),
                    Custom_GOA__c.L2_Approver__c => new Set<Id>(),
                    Custom_GOA__c.L3_Approver__c => new Set<Id>(),
                    Custom_GOA__c.L4_Approver__c => new Set<Id>()
                };

                Boolean isL1Approver = currentQuote.Approved_Status__c == 'Pending L1 Approval' && currentQuote.Level_1_Approver__c == UserInfo.getUserId();
                Boolean isL2Approver = currentQuote.Approved_Status__c == 'Pending L2 Approval' && currentQuote.Level_2_Approver__c == UserInfo.getUserId();
                Boolean isL3Approver = currentQuote.Approved_Status__c == 'Pending L3 Approval' && currentQuote.Level_3_Approver__c == UserInfo.getUserId();
                Boolean isL4Approver = currentQuote.Approved_Status__c == 'Pending L4 Approval' && currentQuote.Level_4_Approver__c == UserInfo.getUserId();
                Boolean isL5Approver = currentQuote.Approved_Status__c == 'Pending L5 Approval' && currentQuote.Level_5_Approver__c == UserInfo.getUserId();

                if (queueIdsByQuoteIds.containsKey(currentQuote.Id)) {
                    for (Custom_GOA__c goa : quoteIdToCustomGOA.get(currentQuote.Id)) {
                        for (SObjectField f : approversByField.keySet()) {
                            Id approverId = (Id) goa.get(f);

                            if (String.isBlank(approverId)) {
                                continue;
                            }

                            if (userIdsByQueueIds.containsKey(approverId)) {
                                approversByField.get(f).addAll(userIdsByQueueIds.get(approverId));
                            }
                        }
                    }

                    if (!approversByField.get(Custom_GOA__c.L1_Approver__c).isEmpty()) {
                        isL1Approver = currentQuote.Approved_Status__c == 'Pending L1 Approval' && approversByField.get(Custom_GOA__c.L1_Approver__c).contains(UserInfo.getUserId());
                    }
                    if (!approversByField.get(Custom_GOA__c.L2_Approver__c).isEmpty()) {
                        isL2Approver = currentQuote.Approved_Status__c == 'Pending L2 Approval' && approversByField.get(Custom_GOA__c.L2_Approver__c).contains(UserInfo.getUserId());
                    }
                    if (!approversByField.get(Custom_GOA__c.L3_Approver__c).isEmpty()) {
                        isL3Approver = currentQuote.Approved_Status__c == 'Pending L3 Approval' && approversByField.get(Custom_GOA__c.L3_Approver__c).contains(UserInfo.getUserId());
                    }
                    if (!approversByField.get(Custom_GOA__c.L4_Approver__c).isEmpty()) {
                        isL4Approver = currentQuote.Approved_Status__c == 'Pending L4 Approval' && approversByField.get(Custom_GOA__c.L4_Approver__c).contains(UserInfo.getUserId());
                    }
                }

                if (isL1Approver || isL2Approver || isL3Approver || isL4Approver || isL5Approver
                        || (isFinanceApproval && requireApprovalIdSet.contains(UserInfo.getUserId()))
                        || (isDownsellApproval && requireApprovalIdSet.contains(UserInfo.getUserId()))
                        || (isProservApproval && requireApprovalIdSet.contains(UserInfo.getUserId()))
                        || (isAdmin && isInApproval)) {
                    result += 'Reject;';
                }
            }

            if (currentQuote.Package_Info__c != null) {
                List<BillingWrappers.QuotePackageInfo> pInfo =
                    (List<BillingWrappers.QuotePackageInfo>)
                        JSON.deserialize(currentQuote.Package_Info__c, List<BillingWrappers.QuotePackageInfo>.class);
                pInfo[0].permissions = result;
                currentQuote.Package_Info__c = JSON.serialize(pInfo);
            }
        }

        return existingQuotes;
    }

    private static Set<Id> getRequireApprovalIdSet(List<Quote> qtList) {
        Set<Id> quoteIdSet = new Set<Id>();
        for(Quote currentQuote : qtList) {
            quoteIdSet.add(currentQuote.Id);
        }

        List<ProcessInstance> piList = (List<ProcessInstance>) new ProcessInstanceSelector()
            .selectProcessInstanceByQuoteIds(quoteIdSet)
            .executeQuery();

        Set<Id> requireApprovalIdSet = new Set<Id>();

        for (ProcessInstance pi : piList) {
            for (ProcessInstanceHistory step : pi.StepsAndWorkitems) {
                requireApprovalIdSet.add(step.ActorId);
            }
        }

        return requireApprovalIdSet;
    }

    private static List<Quote> processApproval(BillingWrappers.Params paramsData) {
        if (paramsData.subAction == 'Submit') {
            QuotingToolQuoteApexController.submitApprovalRequest(
                new Map<String, String> {
                    'quoteId' => paramsData.quoteId,
                    'RestCall' => 'true'
                }
            );
        } else if (paramsData.subAction == 'GenerateQLIdetails') {
            QuotingToolQuoteApexController.generateQuoteDetails(
                new Map<String, String> {
                    'quoteId' => paramsData.quoteId,
                    'RestCall' => 'true'
                }
            );
        } else {
            QuotingToolQuoteApexController.setApprovalAction(
                new Map<String, String> {
                    'quoteId' => paramsData.quoteId,
                    'comment' => paramsData.actionComment,
                    'action' => paramsData.subAction,
                    'RestCall' => 'true'
                }
            );
        }
        return getUpdatedQuoteList(paramsData);
    }

    private static Quote createSalesQuote(BillingWrappers.Params paramsData) {
        return createQuote(paramsData, QuoteHelper.RT_ID_BILLING);
    }

    private static Quote createPOCQuote(BillingWrappers.Params paramsData) {
        return createQuote(paramsData, QuoteHelper.RT_ID_POC);
    }

    private static List<Quote> getCCLegacyQuotes(BillingWrappers.Params paramsData) {
        return ((List<Quote>) new QuoteSelector()
        .selectCCLegacyQuoteByOppId(paramsData.opportunityId)
        .executeQuery());
    }

    private static List<Quote> getProServLegacyQuotes(BillingWrappers.Params paramsData) {
        return ((List<Quote>) new QuoteSelector()
            .selectProServLegacyQuotesByOppId(paramsData.opportunityId)
            .executeQuery());
    }

    private static List<Quote> getTechnicalQuotes(BillingWrappers.Params paramsData) {
        return ((List<Quote>) new QuoteSelector()
            .selectTechQuotesByOppId(paramsData.opportunityId)
            .executeQuery());
    }

    private static List<Quote> getTechnicalQuotesUB(BillingWrappers.Params paramsData) {
        return ((List<Quote>) new QuoteSelector()
            .selectTechQuotesByOppIdUB(paramsData.opportunityId)
            .executeQuery());
    }

    @TestVisible
    private static Quote createTerminationSalesQuote(BillingWrappers.Params paramsData) {

        Opportunity opp = (Opportunity) new OpportunitySelector()
            .selectOpportunitiesByIds(new Set<Id>{paramsData.opportunityId})
            .selectFields(new Set<String>{'BusinessIdentity__c',
                'Account.Active_Sales_Agreement__r.Status'})
            .subselect(
                new QuoteSelector()
                    .selectQuotes()
            )
            .executeQuery()
            .get(0);

        if (opp.Account.Active_Sales_Agreement__r != null) {
            Quote activeSalesAgreement = opp.Account.Active_Sales_Agreement__r;
            activeSalesAgreement.Status = QuoteHelper.QUOTE_STATUS_EXECUTED;
            Triggers.switchOff();
                update activeSalesAgreement;
            Triggers.switchOn();
        }

        Integer pos = 0;
        for (Quote eqt : opp.Quotes) {
            if (eqt.QuotePosition__c != null
                && Integer.valueOf(eqt.QuotePosition__c) > pos) {
                pos = Integer.valueOf(eqt.QuotePosition__c);
            }
        }

        Quote record = new Quote(
            Name = opp.Name + ' ' + String.valueOf(pos + 1),
            QuotePosition__c = pos + 1,
            OpportunityId = paramsData.opportunityId,
            Pricebook2Id = Pricebook2Helper.getStandardPricebookId(),
            RecordTypeId = QuoteHelper.RT_ID_BILLING,
            Package_Info__c = paramsData.packageInfo,
            Upsell_Status__c = QuoteHelper.STATUS_UPSELL,
            Approved_Status__c = QuoteHelper.APPROVAL_STATUS_NOT_REQUIRED,
            ExpirationDate = System.today().addDays(30),
            IsQuoteHasErrors__c = false,
            Start_Date__c = System.today(),
            End_Date__c = System.today().addMonths(24),
            Initial_Term_months__c = '24',
            Term_months__c = '24',
            Auto_Renewal__c = true,
            IsPRMQuote__c = false,
            QuoteType__c = QuoteHelper.QUOTE_TYPE_AGREEMENT,
            Status = QuoteHelper.QUOTE_STATUS_ACTIVE,
            Enabled_LBO__c = false,
            PaymentMethod__c = null,
            DataRetentionDuration__c = null,
            isTermination__c = true
        );

        record = updatePackageReferencesOnQuote(record, paramsData);

        if (String.isNotBlank(opp.BusinessIdentity__c)) {
            record.BusinessIdentity__c = opp.BusinessIdentity__c;
        }

        insert record;

        return ((List<Quote>) new QuoteSelector()
            .selectQuoteById(new List<Object>{ record.Id })
            .selectField(Quote.Package_Info__c)
            .executeQuery()).get(0);
    }

    private static Quote createQuote(BillingWrappers.Params paramsData, Id recordTypeId) {
        String upsellStatus = String.isNotBlank(paramsData.status)
            ? paramsData.status
            : paramsData.packageInfo != null
                ? QuoteHelper.STATUS_UPSELL
                : QuoteHelper.STATUS_NEW_CUSTOMER;

        Opportunity opp = (Opportunity) new OpportunitySelector()
            .selectOpportunitiesByIds(new Set<Id>{paramsData.opportunityId})
            .selectFields(new Set<String>{'BusinessIdentity__c','Account.Active_Sales_Agreement__r.Start_Date__c',
                'Account.Active_Sales_Agreement__r.End_Date__c',
                'Account.Active_Sales_Agreement__r.Initial_Term_months__c',
                'Account.Active_Sales_Agreement__r.Term_months__c',
                'Account.Active_Sales_Agreement__r.Auto_Renewal__c'})
            .subselect(
                new QuoteSelector()
                    .selectQuotes()
            )
            .executeQuery()
            .get(0);

        Integer pos = 0;
        for (Quote eqt : opp.Quotes) {
            if (eqt.QuotePosition__c != null
                && Integer.valueOf(eqt.QuotePosition__c) > pos) {
                pos = Integer.valueOf(eqt.QuotePosition__c);
            }
        }

        Quote record = new Quote(
            Name = opp.Name + ' ' + String.valueOf(pos + 1),
            QuotePosition__c = pos + 1,
            QuoteType__c = QuoteHelper.QUOTE_TYPE_QUOTE,
            OpportunityId = paramsData.opportunityId,
            Pricebook2Id = Pricebook2Helper.getStandardPricebookId(),
            RecordTypeId = recordTypeId,
            Package_Info__c = paramsData.packageInfo,
            Upsell_Status__c = upsellStatus,
            Approved_Status__c = QuoteHelper.APPROVAL_STATUS_NOT_REQUIRED,
            ExpirationDate = System.today().addDays(30),
            IsQuoteHasErrors__c = paramsData.isWizardHasErrors == null ? false : paramsData.isWizardHasErrors,
            IsPRMQuote__c = paramsData.isPRMQuote
        );

        record = updatePackageReferencesOnQuote(record, paramsData);

        if (paramsData.quote != null) {
            enrichQuoteData(record, paramsData.quote, paramsData.isWizardHasErrors, false);
        }

        if (paramsData.paymentMethod != null) {
            record.PaymentMethod__c = paramsData.paymentMethod;
        }

        if (paramsData.enabledLBO != null) {
            record.Enabled_LBO__c = paramsData.enabledLBO;
        }

        if (opp.Tier_Name__c == QuoteHelper.NGBS_FAX_PRODUCT){
            record.Start_Date__c = System.today();
        }

        setRenewalConditions(record, QuoteHelper.isQuoteHasContract(record));

        if (String.isNotBlank(opp.BusinessIdentity__c)) {
            record.BusinessIdentity__c = opp.BusinessIdentity__c;
        }

        if (String.isNotBlank(paramsData.initialTerm)) {
            record.Initial_Term_months__c = paramsData.initialTerm;
        }

        if (QuoteHelper.isQuoteHasContract(record)) {
            if (opp.Account.Active_Sales_Agreement__r != null) {
                record.Start_Date__c = opp.Account.Active_Sales_Agreement__r.Start_Date__c;
                record.End_Date__c = opp.Account.Active_Sales_Agreement__r.End_Date__c;
                record.Initial_Term_months__c = opp.Account.Active_Sales_Agreement__r.Initial_Term_months__c;
                record.Term_months__c = opp.Account.Active_Sales_Agreement__r.Term_months__c;
                record.Auto_Renewal__c = opp.Account.Active_Sales_Agreement__r.Auto_Renewal__c;
            } else {
                record.Initial_Term_months__c = String.isNotBlank(paramsData.initialTerm) ? paramsData.initialTerm : '24';
                record.Term_months__c = String.isNotBlank(paramsData.renewalTerm) ? paramsData.renewalTerm : '24';
            }
        }

        if (String.isNotBlank(paramsData.dataRetentionDuration)) {
            record.DataRetentionDuration__c = paramsData.dataRetentionDuration;
        }

        insert record;

        if (opp?.Quotes?.size() == 0 && recordTypeId == QuoteHelper.RT_ID_BILLING && record.Package_Info__c != null) {
            Opportunity oppToUpdate = QuoteHelper.getOpportunityToUpdateTierName(opp, record);

            if (oppToUpdate != null) {
                OpportunityHelper.setOpptyCLMEnable(new List<Opportunity>{oppToUpdate});

                Triggers.switchOff();
                update oppToUpdate;
                Triggers.switchOn();
            }
        }

        return ((List<Quote>) new QuoteSelector()
            .selectQuoteById(new List<Object>{ record.Id })
            .selectField(Quote.Package_Info__c)
            .executeQuery()).get(0);
    }

    private static List<Quote> updateQuote(BillingWrappers.Params paramsData) {
        BillingWrappers.QuoteWrapper q = paramsData.quote;
        List<Opportunity> oppToUpdate = new List<Opportunity>();
        Quote oldQuote =
            ((List<Quote>) new QuoteSelector()
                .selectQuoteById(new List<Object>{ q.Id })
                .selectFields(new List<SObjectField> {
                    Quote.Package_Info__c,
                    Quote.isPrimary__c
                })
                .selectFields(new List<String> {
                    'Opportunity.ProvisioningDetails__c',
                    'Opportunity.SelfProvisioned__c',
                    'Opportunity.NumberToBeRCMainNumber__c',
                    'Opportunity.NumberToBeCCNumber__c',
                    'Opportunity.RCCCSyncStatus__c',
                    'Opportunity.isTermination__c',
                    'Opportunity.Id'
                })
                .executeQuery()).get(0);

        Quote newQuote = new Quote(Package_Info__c = paramsData.packageInfo);

        Quote quoteRecord = new Quote();
        enrichQuoteData(quoteRecord, q, paramsData.isWizardHasErrors, true);

        if (String.isNotBlank(paramsData.packageInfo)) {
            checkRenewalConditions(oldQuote, newQuote, quoteRecord);
        }

        update quoteRecord;

        checkAndUpdateOpportunity(oldQuote, q, paramsData.hasRCCC);

        return getUpdatedQuoteList(paramsData);
    }

    @TestVisible
    private static List<Quote> updateLBOForQuotes(BillingWrappers.Params paramsData) {
        List<Quote> quotes = (List<Quote>) new QuoteSelector()
            .selectQuotesForShippingByOppIds(new List<Id>{ paramsData.opportunityId })
            .executeQuery();

        for (Quote qt : quotes) {
            if (QuoteHelper.getBillingQuoteProductName(qt) == QuoteHelper.NGBS_OFFICE_PRODUCT) {
                qt.Enabled_LBO__c = true;
                qt.IsQuoteHasErrors__c = paramsData.isWizardHasErrors;
            }
        }

        update quotes;

        return getUpdatedQuoteList(paramsData);
    }

    private static List<Quote> updatePackage(BillingWrappers.Params paramsData) {
        Opportunity opp = (Opportunity) new OpportunitySelector()
                .selectOpportunitiesByIds(new Set<Id>{paramsData.opportunityId})
                .executeQuery()
                .get(0);
        Quote oldQuote =
            ((List<Quote>) new QuoteSelector()
                .selectQuoteById(new List<Object>{ paramsData.quoteId })
                .selectField(Quote.Package_Info__c)
                .executeQuery()).get(0);
        Quote newQuote = new Quote(Package_Info__c = paramsData.packageInfo);
        Quote qt = new Quote(
            Id = paramsData.quoteId,
            Package_Info__c = paramsData.packageInfo,
            Upsell_Status__c = paramsData.status,
            IsQuoteHasErrors__c = BooleanHelper.toBoolean(paramsData.isWizardHasErrors),
            NGBSTaxesAdded__c = false,
            Special_Terms__c = paramsData.specialTerms,
            FreeShippingTerms__c = paramsData.freeShippingTerms,
            PaymentMethod__c = paramsData.paymentMethod,
            DataRetentionDuration__c = paramsData.dataRetentionDuration
        );
        if (String.isNotBlank(paramsData.initialTerm)) {
            qt.Initial_Term_months__c = paramsData.initialTerm;
        }
        if (String.isNotBlank(paramsData.renewalTerm)) {
            qt.Term_months__c = paramsData.renewalTerm;
        }

        qt = updatePackageReferencesOnQuote(qt, paramsData);

        if (Feature_Toggle__c.getInstance().CalculateFSCInQW__c) {
            qt.Special_Terms__c = null;
            qt.Credit_Amount__c = null;
            qt.Free_Service_Taxes__c = null;
        }

        checkRenewalConditions(oldQuote, newQuote, qt);
        update qt;

        if (paramsData.isPrimaryQuote != null && paramsData.isPrimaryQuote) {
            Opportunity oppToUpdate = QuoteHelper.getOpportunityToUpdateTierName(opp, qt);

            if (oppToUpdate != null) {
                OpportunityHelper.setOpptyCLMEnable(new List<Opportunity>{oppToUpdate});

                Triggers.switchOff();
                update oppToUpdate;
                Triggers.switchOn();
            }
        }

        return getUpdatedQuoteList(paramsData);
    }

    private static List<Quote> upgradeQuote(BillingWrappers.Params paramsData) {
        Opportunity opp = (Opportunity) new OpportunitySelector()
                .selectOpportunitiesByIds(new Set<Id>{paramsData.opportunityId})
                .executeQuery()
                .get(0);
        Quote oldQuote =
            ((List<Quote>) new QuoteSelector()
                .selectQuoteById(new List<Object>{ paramsData.quoteId })
                .selectField(Quote.Package_Info__c)
                .executeQuery()).get(0);
        Quote newQuote = new Quote(Package_Info__c = paramsData.packageInfo);

        Quote qt = new Quote(
            Id = paramsData.quoteId,
            Package_Info__c = paramsData.packageInfo,
            Upsell_Status__c = paramsData.status,
            NGBSTaxesAdded__c = false,
            Special_Terms__c = paramsData.specialTerms,
            FreeShippingTerms__c = paramsData.freeShippingTerms,
            Enabled_LBO__c = paramsData.enabledLBO == null ? oldQuote.Enabled_LBO__c : paramsData.enabledLBO
        );
        if (paramsData.enabledLBO != null && paramsData.enabledLBO) {
            qt.InvalidDiscountedPhonesQuantity__c = false;
        }

        if (paramsData.paymentMethod != null) {
            qt.PaymentMethod__c = paramsData.paymentMethod;
        }

        if (paramsData.isRemoveAreaCodes) {
            qt.AreaCode__c = null;
            qt.FaxAreaCode__c = null;
        }

        qt = updatePackageReferencesOnQuote(qt, paramsData);

        if (!Feature_Toggle__c.getInstance().EnableSpinnerless__c // TODO move this logic to non-spinnerless frontend
            && Feature_Toggle__c.getInstance().CalculateFSCInQW__c) {
            qt.Special_Terms__c = null;
            qt.Credit_Amount__c = null;
            qt.Free_Service_Taxes__c = null;
        }

        if (String.isNotBlank(paramsData.dataRetentionDuration)) {
            qt.DataRetentionDuration__c = paramsData.dataRetentionDuration;
        }

        checkRenewalConditions(oldQuote, newQuote, qt);
        update qt;

        if (paramsData.isPrimaryQuote) {
            Opportunity oppToUpdate = QuoteHelper.getOpportunityToUpdateTierName(opp, qt);

            if (oppToUpdate != null) {
                OpportunityHelper.setOpptyCLMEnable(new List<Opportunity>{oppToUpdate});

                Triggers.switchOff();
                update oppToUpdate;
                Triggers.switchOn();
            }
        }

        return getUpdatedQuoteList(paramsData);
    }

    private static List<Quote> deleteQuotes(BillingWrappers.Params paramsData) {
        final String DELETE_QUOTE_ERROR_MESSAGE = 'Deletion of Active Sales Agreements,'
            + ' Quotes in Closed Won Opportunities or last Sales Quotes is not allowed';

        List<Quote> records = new List<Quote>();
        for (String recordId : paramsData.quoteIdSet) {
            records.add(new Quote(Id = recordId));
        }
        try {
            delete records;
        } catch(Exception e) {
            if (e.getTypeName() == 'System.DmlException' && e.getMessage().contains(DELETE_QUOTE_ERROR_MESSAGE)) {
                throw new DmlException(DELETE_QUOTE_ERROR_MESSAGE);
            } else {
                throw e;
            }
        }
        return getUpdatedQuoteList(paramsData);
    }

    @TestVisible
    private static List<Quote> recalculateApprovals(BillingWrappers.Params paramsData) {
        Set<Id> quoteIdSet = new Set<Id>{paramsData.quoteId};

        List<Quote> quotesToUpdate = QuoteApprovals.handleQuotes(quoteIdSet, new Set<Id>(), null);

        Triggers.switchOff();
            update quotesToUpdate;
        Triggers.switchOn();

        return getUpdatedQuoteList(paramsData);
    }

    @TestVisible
    private static List<Quote> makePrimaryQuote(BillingWrappers.Params paramsData) {
        Opportunity opp = (Opportunity) new OpportunitySelector()
            .selectOpportunitiesByIds(new Set<Id>{paramsData.opportunityId})
            .executeQuery()
            .get(0);
        List<Quote> quoteList = (List<Quote>) new QuoteSelector()
            .selectQuotesForPrimaryProcess(paramsData.opportunityId, paramsData.quoteId)
            .executeQuery();

        QuoteHelper.makePrimaryQuote(opp, paramsData.quoteId, quoteList);

        return getUpdatedQuoteList(paramsData);
    }

    public static List<Quote> getQuoteList(Id oppId) {
        Set<String> recordTypes = new Set<String>{
            QuoteHelper.RT_ID_BILLING,
            QuoteHelper.RT_ID_PROSERV,
            QuoteHelper.RT_ID_CC,
            QuoteHelper.RT_ID_CC_PROSERV,
            QuoteHelper.RT_ID_POC
        };

        String condition = 'OpportunityId = :bind0 AND RecordTypeId IN :bind1 AND IsMultiProductTechnicalQuote__c = false';

        return (List<Quote>) new QuoteSelector()
            .selectQuotesForQuoteService(oppId, recordTypes, condition)
            .executeQuery();
    }

    public static Quote clearQuote(BillingWrappers.Params paramsData) {
        Id masterQuoteId = (Id) paramsData.quoteId;
        List<String> serviceNames = new List<String>(paramsData.serviceNames != null ? paramsData.serviceNames : new List<String>());

        return QuoteHelper.clearQuotes(masterQuoteId, serviceNames);
    }

    @TestVisible
    private static List<Quote> processEngageLegal(BillingWrappers.Params paramsData) {
        Map<String,String> data = paramsData.data;
            data.put('quoteId', paramsData.quoteId);
        Quote q = QuotingToolQuoteApexController.submitSpecialToSApprovalRequest(data);
        createStepUps(paramsData.stepUps, q.Special_TOS_Approval__c);

        return getUpdatedQuoteList(paramsData);
    }

    private static void createStepUps(List<BillingWrappers.StepUp> stepUps, Id engageLegalId) {
        if (stepUps != null && !stepUps.isEmpty()) {
            List<Step_Up__c> stepUpsToInsert = new List<Step_Up__c>();
            for (BillingWrappers.StepUp stepUp : stepUps) {
                stepUpsToInsert.add(new Step_Up__c(
                    Engage_Legal_Record__c = engageLegalId,
                    Step_Up_Date__c = Date.valueOf(stepUp.stepUpDate),
                    Step_Up_DLs__c = stepUp.stepDLs,
                    Type__c = 'Step Up'
                ));
            }
            insert stepUpsToInsert;
        }
    }

    public static String getEngageLegalOptions() {
        Map<String,Set<String>> options = new Map<String,Set<String>>();

        PageReference pr = new PageReference('/apex/Picklist');
        String htmlContent = pr.getContent().toString().unescapeHtml4();
        List<PicklistController.Picklist> picklists = PicklistController.parse(htmlContent,'<select ','<option ');

        return JSON.serialize(picklists);
    }

    /* Get Updated Quote List */
    public static List<Quote> getUpdatedQuoteList(BillingWrappers.Params paramsData) {
        List<Quote> quotes = getQuoteList(paramsData.opportunityId);

        Boolean isUserCanApprove = paramsData.isUserCanApprove != null ? paramsData.isUserCanApprove : false;
        /* update pInfo permissions */
        quotes = populateAvailableApprovalActions(quotes, isUserCanApprove);

        return quotes;
    }

    public static Account getAccount(String accId) {
        return (Account) new AccountSelector()
            .selectAccountForNewWizard(accId)
            .executeQuery()
            .get(0);
    }

    public static Map<String, Area_Codes__c> getAreaCodes(BillingWrappers.BillingCode[] billingCodes) {
        List<BillingWrappers.AreaCodeData> areaCodeDataList = new List<BillingWrappers.AreaCodeData>();

        for (BillingWrappers.BillingCode bc : billingCodes) {
            if (bc.bundles == null) {
                continue;
            }
            for (BillingWrappers.Bundle bundle : bc.bundles) {
                if (bundle.areaCode != null) {
                    areaCodeDataList.add(bundle.areaCode);
                }
                if (bundle.licenses == null) {
                    continue;
                }
                for (BillingWrappers.BundleItem license : bundle.licenses) {
                    if (license.areaCode != null) {
                        areaCodeDataList.add(license.areaCode);
                    }
                }
            }
        }

        Map<String, Area_Codes__c> resultMap = new Map<String, Area_Codes__c>();

        if (areaCodeDataList.isEmpty()) {
            return resultMap;
        }

        Map<String, Object> areaCodeData = AreaCodeService.getAreaCodeData(areaCodeDataList);

        List<Area_Codes__c> areaCodesList =  new AreaCodesSelector()
            .selectAreaCodes()
            .setCondition(
                'Country__c IN :bind0 ' +
                'AND (State__c IN :bind1 OR State__c = null) ' +
                'AND (City__c IN :bind2 OR City__c = null) ' +
                'AND Area_Code__c IN :bind3'
            )
            .setQueryBindings(
                new List<Object>{
                    (Set<String>) areaCodeData.get('countries'),
                    (Set<String>) areaCodeData.get('states'),
                    (Set<String>) areaCodeData.get('cities'),
                    (Set<Integer>) areaCodeData.get('areaCodes')
                }
            )
            .executeQuery();

        for (Area_Codes__c areaCode : areaCodesList) {
            resultMap.put(
                AreaCodeService.getAreaId(areaCode),
                areaCode
            );
        }

        return resultMap;
    }

    public static Map<String, QuoteLineItem> getQLIs(Id quoteId, BillingWrappers.BillingCode[] billingCodes) {

        Map<String, QuoteLineItem> productExtIdToQLIMap = new Map<String, QuoteLineItem>();

        if (quoteId == null) {
            return productExtIdToQLIMap;
        }

        Set<String> elementIdSet = new Set<String>();

        for (BillingWrappers.BillingCode bc : billingCodes) {
            if (bc.bundles == null) {
                continue;
            }
            for (BillingWrappers.Bundle bundle : bc.bundles) {
                elementIdSet.add(bundle.elementID);
                if (bundle.licenses == null) {
                    continue;
                }
                for (BillingWrappers.BundleItem license : bundle.licenses) {
                    elementIdSet.add(license.elementID);
                }
            }
        }

        elementIdSet.remove(null);

        if (elementIdSet.isEmpty()) {
            return productExtIdToQLIMap;
        }

        List<QuoteLineItem> qliList = new QuoteLineItemSelector()
            .selectQuoteLineItemsForSyncCostCenterLineItems(
                new List<Object>{
                    quoteId, elementIdSet
                }
            )
            .executeQuery();

        for (QuoteLineItem qli : qliList) {
            productExtIdToQLIMap.put(qli.Product2.ExtID__c, qli);
        }

        return productExtIdToQLIMap;
    }

    public static void syncCostCenterItems(List<Cost_Center__c> costCenters, BillingWrappers.Params paramsData) {
        List<BillingWrappers.BillingCode> billingCodesToInsert = new List<BillingWrappers.BillingCode>();
        List<BillingWrappers.BillingCode> billingCodesToUpdate = new List<BillingWrappers.BillingCode>();

        Map<Id, Cost_Center__c> costCentersToDelete = new Map<Id, Cost_Center__c>(costCenters);
        Map<String, Cost_Center__c> guidToCostCenterMap = new Map<String, Cost_Center__c>();

        for(BillingWrappers.BillingCode bc : paramsData.billingCodes) {
            if (bc.Id != null){
                billingCodesToUpdate.add(bc);
                Cost_Center__c cc = costCentersToDelete.remove(bc.Id);
                guidToCostCenterMap.put(bc.guid, cc);
            } else {
                billingCodesToInsert.add(bc);
            }
        }
        delete costCentersToDelete.values();

        syncCostCenterLineItems(paramsData.quoteId, billingCodesToUpdate, guidToCostCenterMap);
        updateCostCenterItems(paramsData.quoteId, billingCodesToUpdate);
        if (billingCodesToInsert.size() > 0) {
            createCostCenters(paramsData.quoteId, billingCodesToInsert);
        }
    }

    public static void syncCostCenterLineItems(Id quoteId, List<BillingWrappers.BillingCode> billingCodes, Map<String, Cost_Center__c> guidToCostCenterMap) {

        Map<Id, Cost_Center_Line_Item__c> existingProductsMap = new Map<Id, Cost_Center_Line_Item__c>();
        for (Cost_Center__c cc : guidToCostCenterMap.values()) {
            for(Cost_Center_Line_Item__c prs : cc.Cost_Center_Products__r) {
                existingProductsMap.put(prs.Id, prs);
            }
        }

        Map<String, QuoteLineItem> productExtIdToQLIMap = getQLIs(quoteId, billingCodes);
        Map<String, Area_Codes__c> areaIdToAreaCodesMap = getAreaCodes(billingCodes);

        List<Cost_Center_Line_Item__c> rootItemsToUpsert = new List<Cost_Center_Line_Item__c>();

        for(BillingWrappers.BillingCode bc : billingCodes) {
            if (bc.bundles == null) {
                continue;
            }
            for(BillingWrappers.Bundle bundle : bc.bundles) {
                String bundleAreaId = AreaCodeService.getAreaId(bundle.areaCode);
                Id bundleAcId = areaIdToAreaCodesMap.containsKey(bundleAreaId) ? areaIdToAreaCodesMap.get(bundleAreaId).Id : null;
                Id costCenterId = bc.Id == null ? guidToCostCenterMap.get(bc.guid).Id : bc.Id;
                Cost_Center_Line_Item__c rootItem = bundle.buildCostCenterLineItem(
                    costCenterId,
                    productExtIdToQLIMap.get(bundle.elementID),
                    bundleAcId
                );
                if (rootItem.Cost_Center__c != null) {
                    rootItemsToUpsert.add(rootItem);
                }
                if (rootItem.Id != null) {
                    existingProductsMap.remove(rootItem.Id);
                }
            }
        }
        upsert rootItemsToUpsert;

        Map<String, Id> elementIdToSFIdMap = new Map<String, Id>();
        for (Cost_Center_Line_Item__c rootItem : rootItemsToUpsert) {
            elementIdToSFIdMap.put(rootItem.BundleElementId__c, rootItem.Id);
        }

        List<Cost_Center_Line_Item__c> childItemsToUpsert = new List<Cost_Center_Line_Item__c>();
        for(BillingWrappers.BillingCode bc : billingCodes) {
            if (bc.bundles == null) {
                continue;
            }
            for(BillingWrappers.Bundle bundle : bc.bundles) {
                String bundleAreaId = AreaCodeService.getAreaId(bundle.areaCode);
                Id bundleAcId = areaIdToAreaCodesMap.containsKey(bundleAreaId) ? areaIdToAreaCodesMap.get(bundleAreaId).Id : null;
                Id costCenterId = bc.Id == null ? guidToCostCenterMap.get(bc.guid).Id : bc.Id;
                String bundleElementId = bundle.buildBundleElementId(costCenterId);

                if (bundle.licenses == null) {
                    continue;
                }
                for (BillingWrappers.BundleItem license : bundle.licenses) {
                    String areaId = AreaCodeService.getAreaId(license.areaCode);
                    Id acId = areaIdToAreaCodesMap.containsKey(areaId) ? areaIdToAreaCodesMap.get(areaId).Id : null;
                    Cost_Center_Line_Item__c childItem = license.buildCostCenterLineItem(
                        costCenterId,
                        elementIdToSFIdMap.get(bundleElementId),
                        productExtIdToQLIMap.get(license.elementID),
                        acId
                    );
                    if (childItem.Cost_Center__c != null) {
                        childItemsToUpsert.add(childItem);
                    }
                    if (childItem.Id != null) {
                        existingProductsMap.remove(childItem.Id);
                    }
                }
            }
        }
        upsert childItemsToUpsert;

        try{
            delete existingProductsMap.values();
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
    }
    public static void createCostCenters(String quoteId, BillingWrappers.BillingCode[] billingCodes){
        Decimal costCenterNestingLevel = NGBS_Settings__c.getInstance().CostCenterNestingLevel__c;
        Map<Integer, Map<String,Cost_Center__c>> costCentersMap = new Map<Integer, Map<String, Cost_Center__c>>();
        Map<String,Cost_Center__c> allCostCentersMap = new Map<String, Cost_Center__c>();
        Map<String,Tax_Location__c> taxLocations = createTaxLocations(billingCodes);

        if (costCenterNestingLevel != null) {
            for (Integer i = 0; i < costCenterNestingLevel; i++) {
                Map<String,Cost_Center__c> currentLevelCostCenters = new Map<String,Cost_Center__c>();

                for (Integer j = 0; j < billingCodes.size(); j++) {
                    BillingWrappers.BillingCode bc = billingCodes[j];
                    if (bc.depth == i) {
                        Cost_Center__c item = new Cost_Center__c(
                            Quote__c = quoteId,
                            Name = bc.name,
                            Cost_Center_Parent__c = bc.parentId,
                            BillingId__c = bc.billingId
                        );
                        if (taxLocations.containsKey(bc.guid)) {
                            item.Tax_Location__c = taxLocations.get(bc.guid).Id;
                        }
                        if (i > 0) {
                            if (bc.parentId != null) {
                                item.Cost_Center_Parent__c = bc.parentId;
                            } else {
                                item.Cost_Center_Parent__c = costCentersMap.get(i-1).get(bc.parentXid).Id;
                            }
                        }
                        currentLevelCostCenters.put(bc.guid,item);
                    }
                }
                upsert currentLevelCostCenters.values();
                costCentersMap.put(i,currentLevelCostCenters);
                allCostCentersMap.putAll(currentLevelCostCenters);
            }
        }
        syncCostCenterLineItems(quoteId, billingCodes, allCostCentersMap);
    }

    public static Map<String,Tax_Location__c> createTaxLocations(BillingWrappers.BillingCode[] billingCodes) {
        Map<String,Tax_Location__c> taxLocations = new Map<String,Tax_Location__c>();
        Set<String> locationsBillingIds = new Set<String>();
        List<Tax_Location__c> newTaxLocations = new List<Tax_Location__c> ();

        for (BillingWrappers.BillingCode bc : billingCodes) {
            if (bc.AddressId == null) {
                continue;
            }
            locationsBillingIds.add(bc.AddressId);
        }

        List<Tax_Location__c> taxLocationsInSF =
        [SELECT Id, Name, City__c, State__c, ZipCode__c, Country__c,
            County__c, Street__c, Street2__c,Phone__c, First_Name__c,
            Last_Name__c,BillingId__c
        FROM Tax_Location__c
        WHERE BillingId__c IN : locationsBillingIds];

        Map<String,Tax_Location__c> taxLocationMapToUpdate = new Map<String, Tax_Location__c>();
        for (Tax_Location__c tl : taxLocationsInSF) {
            taxLocationMapToUpdate.put(tl.BillingId__c, tl);
        }
        for (BillingWrappers.BillingCode bc : billingCodes) {
            if (bc.location == null || (bc.location.label == null && bc.AddressId == null)) {
                continue;
            }
            if ((String.isNotBlank(bc.AddressId) && taxLocationMapToUpdate.containsKey(bc.AddressId))
                || (bc.location != null && (String.isBlank(bc.AddressId) && taxLocationMapToUpdate.containsKey(bc.location.hashcode())))) {
                if (bc.guid == null) {
                    Tax_Location__c taxLocation = String.isNotBlank(bc.AddressId) ? taxLocationMapToUpdate.get(bc.AddressId) : taxLocationMapToUpdate.get(bc.location.hashcode());
                    taxLocation.Id = String.isBlank(bc.location.Id) ? taxLocationMapToUpdate.get(bc.AddressId).Id : bc.location.Id;
                    taxLocation.BillingId__c = bc.AddressId;
                    taxLocation.Name = bc.location.label == null ? bc.AddressId : bc.location.label;
                    taxLocation.Street__c = bc.location.street1;
                    taxLocation.Street2__c = bc.location.street2;
                    taxLocation.Phone__c = bc.location.phone;
                    taxLocation.County__c = bc.location.county;
                    taxLocation.First_Name__c = bc.location.firstName;
                    taxLocation.Last_Name__c = bc.location.lastName;
                    taxLocation.City__c = bc.location.city;
                    taxLocation.State__c = bc.location.state;
                    taxLocation.ZipCode__c = bc.location.zip;
                    taxLocation.Country__c = bc.location.country;

                    taxLocationMapToUpdate.put(String.isNotBlank(bc.AddressId) ? bc.AddressId : bc.location.hashCode(), taxLocation);
                    taxLocations.put(bc.Id, taxLocationMapToUpdate.get(bc.AddressId));
                } else {
                    taxLocations.put(bc.guid, String.isNotBlank(bc.AddressId) ? taxLocationMapToUpdate.get(bc.AddressId) : taxLocationMapToUpdate.get(bc.location.hashcode()));
                }
            } else {
                Tax_Location__c item = new Tax_Location__c(
                    Id = bc.location.Id,
                    BillingId__c = bc.AddressId,
                    Name = bc.location.label == null ? bc.AddressId : bc.location.label,
                    Street__c = bc.location.street1,
                    Street2__c = bc.location.street2,
                    Phone__c = bc.location.phone,
                    County__c = bc.location.county,
                    First_Name__c = bc.location.firstName,
                    Last_Name__c = bc.location.lastName,
                    City__c = bc.location.city,
                    State__c = bc.location.state,
                    ZipCode__c = bc.location.zip,
                    Country__c = bc.location.country
                );
                if (bc.guid == null) {
                    taxLocations.put(bc.Id, item);
                } else {
                    taxLocations.put(bc.guid, item);
                }
                newTaxLocations.add(item);
                taxLocationMapToUpdate.put(String.isBlank(bc.AddressId) ? bc.location.hashcode() : bc.AddressId, item);
            }
        }
        insert newTaxLocations;
        update taxLocationMapToUpdate.values();
        return taxLocations;
    }

    public static void updateCostCenterItems(String quoteId, List<BillingWrappers.BillingCode> billingCodes) {
        List<Cost_Center__c> ccToUpdate = new List<Cost_Center__c>();
        Map<String,Tax_Location__c> taxLocations = createTaxLocations(billingCodes);
        for (BillingWrappers.BillingCode bc : billingCodes) {
            ccToUpdate.add(new Cost_Center__c(
                Id = bc.Id,
                Quote__c = quoteId,
                Name = bc.name,
                Tax_Location__c = taxLocations.containsKey(bc.guid) ? taxLocations.get(bc.guid).Id : null
            )
            );
        }
        update ccToUpdate;
    }

    public static List<BillingWrappers.BillingCode> getBillingCodes(String quoteId) {
        Map<Id,Tax_Location__c> taxLocationMap = new Map<Id, Tax_Location__c>();
        Map<Id,BillingWrappers.BillingCode> bcBillingCodes = new Map<Id,BillingWrappers.BillingCode>();
        List<Cost_Center__c> costCenters = [
            SELECT Id, Name, Cost_Center_Parent__c,Quote__c,BillingId__c, Tax_Location__c,
                AddressId__c, Parent_Billing_Id__c, Billing_Code_Path__c,
                (SELECT Id, Name, Quantity__c, Quote_Line_Item__c, AreaCode__c,
                    Cost_Center__c, ElementId__c, BundleElementId__c, Parent__c,
                    SortOrder__c, AreaCode__r.Country__c, AreaCode__r.State__c,
                    AreaCode__r.City__c, AreaCode__r.Type__c, AreaCode__r.Area_Code__c
                FROM Cost_Center_Products__r)
            FROM Cost_Center__c
            WHERE Quote__c = :quoteId
        ];
        for (Cost_Center__c cc : costCenters) {
            taxLocationMap.put(cc.Tax_Location__c,new Tax_Location__c());
        }
        for (Tax_Location__c tl : [
            SELECT Id, Name, City__c, State__c, ZipCode__c, Country__c,
                County__c, Street__c, Street2__c,Phone__c, First_Name__c, Last_Name__c,BillingId__c
            FROM Tax_Location__c WHERE Id IN : taxLocationMap.keySet()]) {
            taxLocationMap.put(tl.Id, tl);
        }
        for (Cost_Center__c cc : costCenters) {
            BillingWrappers.TaxLocation taxLocation = new BillingWrappers.TaxLocation();
            BillingWrappers.BillingCode bc = new BillingWrappers.BillingCode();

            Tax_Location__c tl = taxLocationMap.get(cc.Tax_Location__c);
            taxLocation.id = tl.Id;
            taxLocation.label = tl.Name;
            taxLocation.street1 = tl.Street__c;
            taxLocation.street2 = tl.Street2__c;
            taxLocation.county = tl.County__c;
            taxLocation.city = tl.City__c;
            taxLocation.state = tl.State__c;
            taxLocation.zip = tl.ZipCode__c;
            taxLocation.country = tl.Country__c;

            List<BillingWrappers.Bundle> bundles = createBundles(cc.Cost_Center_Products__r);

            bc.Id = cc.Id;
            bc.parentId = cc.Cost_Center_Parent__c;
            bc.billingId = cc.BillingId__c;
            bc.name = cc.Name;
            bc.location = taxLocation;
            bc.bundles = bundles;
            bc.addressId = cc.AddressId__c;
            bc.parentBillingId = cc.Parent_Billing_Id__c;
            bc.billingCodePath = cc.Billing_Code_Path__c;
            bcBillingCodes.put(bc.Id, bc);
        }
        return bcBillingCodes.values();
    }

    private static List<BillingWrappers.Bundle> createBundles(List<Cost_Center_Line_Item__c> costCenterLineItemList) {
        Map<Id, BillingWrappers.Bundle> billingCodeBundlesMap = new Map<Id, BillingWrappers.Bundle>();

        Map<Id, Cost_Center_Line_Item__c> rootItemsMap = new Map<Id, Cost_Center_Line_Item__c>();
        Map<Id, Cost_Center_Line_Item__c> childItemsMap = new Map<Id, Cost_Center_Line_Item__c>();

        for (Cost_Center_Line_Item__c ccli : costCenterLineItemList) {
            if (ccli.Parent__c == null) {
                rootItemsMap.put(ccli.Id, ccli);
            } else {
                childItemsMap.put(ccli.Id, ccli);
            }
        }

        for (Cost_Center_Line_Item__c bundleParent : rootItemsMap.values()) {
            BillingWrappers.Bundle bundle = new BillingWrappers.Bundle(bundleParent);

            if (!billingCodeBundlesMap.containsKey(bundle.id)) {
                billingCodeBundlesMap.put(bundle.id, bundle);
            }
        }

        for (Cost_Center_Line_Item__c bundleChild : childItemsMap.values()) {
            BillingWrappers.BundleItem bundleLicense = new BillingWrappers.BundleItem(bundleChild);
            billingCodeBundlesMap.get(bundleChild.Parent__c).licenses.add(bundleLicense);
        }

        return billingCodeBundlesMap.values();
    }

    public static List<BillingWrappers.BillingCode> matchBillingCodesFromBillingApi(
        String quoteId,
        List<BillingWrappers.BillingCode> receivedBillingCodes,
        List<BillingWrappers.Address> taxLocations
    ) {
        if (receivedBillingCodes.size() == 0) {
            return receivedBillingCodes;
        }
        Map<String,Tax_Location__c> taxLocationMap = matchTaxLocationsToBillingCodes(receivedBillingCodes,taxLocations);
        List<Cost_Center__c> costCentersToUpdate = new List<Cost_Center__c>();
        List<Cost_Center__c> costCentersToDelete = new List<Cost_Center__c>();
        Map<String, Cost_Center__c> costCenterMap = new Map<String, Cost_Center__c>();
        Map<String, BillingWrappers.BillingCode> billingCodeMap = new Map<String, BillingWrappers.BillingCode>();
        Set<String> parentBillingIds = new Set<String>();
        for (BillingWrappers.BillingCode bc : receivedBillingCodes) {
            billingCodeMap.put(bc.Id, bc);
            if (bc.parentBillingId != null) {
                parentBillingIds.add(bc.parentBillingId);
            }
        }

        List<Cost_Center__c> costCenters = [SELECT Id, BillingId__c, Name, Tax_Location__c, Cost_Center_Parent__c,
            AddressId__c, Parent_Billing_Id__c, Billing_Code_Path__c
            FROM Cost_Center__c
            WHERE Quote__c = :quoteId];
        Map<Id,Cost_Center__c> costCenterMapById = new Map<Id, Cost_Center__c>(costCenters);
        for(Cost_Center__c cc : costCenters) {
            costCenterMap.put(cc.BillingId__c, cc);
        }
        if (isSameHierarchy(costCenterMap, billingCodeMap, costCenterMapById)) {
            for (Cost_Center__c cc : costCenters) {
                if (billingCodeMap.containsKey(cc.BillingId__c)){
                    BillingWrappers.BillingCode bc = billingCodeMap.get(cc.BillingId__c);
                    Id taxLocationId = taxLocationMap.containsKey(bc.AddressId) && taxLocationMap.get(bc.AddressId).Id != null
                        ? taxLocationMap.get(bc.AddressId).Id
                        : null;
                    if (cc.Name != bc.name
                        || cc.Tax_Location__c != taxLocationId
                        || cc.AddressId__c != bc.addressId
                        || cc.Parent_Billing_Id__c != bc.parentBillingId
                        || cc.Billing_Code_Path__c != bc.billingCodePath
                    ) {
                        cc.Name = bc.name;
                        cc.Tax_Location__c = taxLocationId;
                        cc.AddressId__c = bc.addressId;
                        cc.Parent_Billing_Id__c = bc.parentBillingId;
                        cc.Billing_Code_Path__c = bc.billingCodePath;
                        costCentersToUpdate.add(cc);
                    }
                } else {
                    costCentersToDelete.add(cc);
                }
            }
        }
        update costCentersToUpdate;
        createCostCentersFromBillingApi (costCenterMap, billingCodeMap, parentBillingIds, taxLocationMap, quoteId);
        costCentersToDelete.addAll([SELECT Id FROM Cost_Center__c WHERE Quote__c =:quoteId And BillingId__c = null]);
        delete costCentersToDelete;

        return getBillingCodes(quoteId);
    }

    private static void createCostCentersFromBillingApi(Map<String, Cost_Center__c> costCenterMap, Map<String, BillingWrappers.BillingCode> billingCodeMap,
        Set<String> parentBillingIds, Map<String,Tax_Location__c> taxLocationMap, String quoteId
    ) {
        List<Cost_Center__c> parentCostCentersToInsert = new List<Cost_Center__c>();
        List<Cost_Center__c> childCostCentersToInsert = new List<Cost_Center__c>();
        List<Cost_Center__c> childCostCentersToUpdate = new List<Cost_Center__c>();

        for (BillingWrappers.BillingCode bc : billingCodeMap.values()) {
            if (costCenterMap.containsKey(bc.Id) || !parentBillingIds.contains(bc.Id)){
                continue;
            }
            Cost_Center__c costCenter = new Cost_Center__c(
                Name = bc.name,
                AddressId__c = bc.addressId,
                Parent_Billing_Id__c = bc.parentBillingId,
                Billing_Code_Path__c = bc.billingCodePath,
                Tax_Location__c = taxLocationMap.containsKey(bc.AddressId) && taxLocationMap.get(bc.AddressId).Id != null ?
                    taxLocationMap.get(bc.AddressId).Id : null,
                BillingId__c = bc.Id,
                Quote__c = quoteId
            );
            parentCostCentersToInsert.add(costCenter);
            costCenterMap.put(bc.Id, costCenter);
        }
        insert parentCostCentersToInsert;

        for (BillingWrappers.BillingCode bc : billingCodeMap.values()) {
            if (costCenterMap.containsKey(bc.Id)  || parentBillingIds.contains(bc.Id)) {
                continue;
            }
            Cost_Center__c costCenter = new Cost_Center__c(
                Name = bc.name,
                AddressId__c = bc.addressId,
                Parent_Billing_Id__c = bc.parentBillingId,
                Cost_Center_Parent__c = bc.parentBillingId != null && costCenterMap.containsKey(bc.parentBillingId) ? costCenterMap.get(bc.parentBillingId).Id : null,
                Billing_Code_Path__c = bc.billingCodePath,
                Tax_Location__c = taxLocationMap.containsKey(bc.AddressId) && taxLocationMap.get(bc.AddressId).Id != null ?
                    taxLocationMap.get(bc.AddressId).Id : null,
                BillingId__c = bc.Id,
                Quote__c = quoteId
            );
            childCostCentersToInsert.add(costCenter);
            costCenterMap.put(bc.Id, costCenter);
        }
        insert childCostCentersToInsert;

        for (BillingWrappers.BillingCode bc : billingCodeMap.values()) {
            if (bc.parentBillingId != null
                && costCenterMap.containsKey(bc.parentBillingId)
                && costCenterMap.get(bc.Id).Cost_Center_Parent__c != costCenterMap.get(bc.parentBillingId).Id
            ) {
                costCenterMap.get(bc.Id).Cost_Center_Parent__c = costCenterMap.get(bc.parentBillingId).Id;
                childCostCentersToUpdate.add(costCenterMap.get(bc.Id));
            }
        }
        update childCostCentersToUpdate;
    }

    private static Boolean isSameHierarchy (Map<String, Cost_Center__c> costCenterMap, Map<String, BillingWrappers.BillingCode> billingCodeMap, Map<Id, Cost_Center__c> costCenterMapById){
        Boolean isSame = true;
        for (BillingWrappers.BillingCode bc : billingCodeMap.values()) {
            BillingWrappers.BillingCode billingParent = billingCodeMap.get(bc.parentId);
            Cost_Center__c sfParent;
            if (costCenterMap.containsKey(bc.Id) && costCenterMapById.containsKey(costCenterMap.get(bc.Id).Cost_Center_Parent__c)){
                sfParent = costCenterMapById.get(costCenterMap.get(bc.Id).Cost_Center_Parent__c);

            }

            if (billingParent != null && sfParent != null) {
                if (billingParent.Id != sfParent.BillingId__c) {
                    isSame = false;
                    break;
                }
            }

        }
        return isSame;
    }

    @TestVisible
    private static List<Cost_Center__c> getCostCenters(String quoteId) {
        return [SELECT Id, Name, Cost_Center_Parent__c,Quote__c,BillingId__c, Tax_Location__c,
            Parent_Billing_Id__c, Billing_Code_Path__c, AddressId__c,
                (SELECT Id, Name, Quantity__c, Quote_Line_Item__c, AreaCode__c,
                    Cost_Center__c, ElementId__c, Parent__c, SortOrder__c
                FROM Cost_Center_Products__r)
            FROM Cost_Center__c
            WHERE Quote__c = :quoteId
        ];
    }

    @TestVisible
    private static Map<String,Tax_Location__c> matchTaxLocationsToBillingCodes(BillingWrappers.BillingCode[] receivedBillingCodes, BillingWrappers.Address[] addresses) {
        Map<String, BillingWrappers.TaxLocation> addressesMap = new Map<String, BillingWrappers.TaxLocation>();
        for (BillingWrappers.Address address : addresses) {
            addressesMap.put(address.id, address.address);
        }
        for (BillingWrappers.BillingCode bc : receivedBillingCodes) {
            bc.location = addressesMap.get(bc.AddressId);
        }
        Map<String,Tax_Location__c> taxLocationMap = new Map<String, Tax_Location__c>();
        List<Tax_Location__c> locations = createTaxLocations(receivedBillingCodes).values();
        for (Tax_Location__c tl : locations) {
            taxLocationMap.put(tl.BillingId__c, tl);
        }
        return taxLocationMap;
    }

    @testVisible
    private static void enrichQuoteData(
        Quote record,
        BillingWrappers.QuoteWrapper q,
        Boolean isWizardHasErrors,
        Boolean isUpdate
    ){
        Map<String, Area_Codes__c> areaCodeByAreaId = getAreaCodes(q);
        Area_Codes__c mainAreaCode = areaCodeByAreaId.get(AreaCodeService.getAreaId(q.mainAreaCodeInfo));
        Area_Codes__c faxAreaCode = areaCodeByAreaId.get(AreaCodeService.getAreaId(q.faxAreaCodeInfo));

        record.Id = q.id != null ? q.id : record.Id;
        if (isUpdate) {
            record.Package_Info__c = q.packageInfo;
            record.Name = q.name;
            record.Auto_Renewal__c = q.autoRenewal;
            record.Initial_Term_months__c = q.initialTerm;
            record.Initial_Term_POC__c = q.initialTermPOC;
            record.Term_months__c = q.renewalTerm;
            record.Special_Terms__c = q.specialTerms;
            record.Status = q.status;
            record.QuoteType__c = q.quoteType;
            record.ExpirationDate = q.expirationDate != null ? Date.valueOf(q.expirationDate) : null;
            record.IsShowSmokeModifiedMessage__c = false;
            record.PaymentMethod__c = q.paymentMethod;
            record.FreeShippingTerms__c = q.freeShippingTerms;

            if (Feature_Toggle__c.getInstance().CalculateFSCInQW__c) {
                record.Credit_Amount__c = q.creditAmount;
                record.Free_Service_Taxes__c = q.freeServiceTaxes;
            }
            if (String.isNotBlank(q.dataRetentionDuration)) {
                record.DataRetentionDuration__c = q.dataRetentionDuration;
            }
        }
        record.IsQuoteHasErrors__c = BooleanHelper.toBoolean(isWizardHasErrors);
        record.JustificationandDescription__c = q.justification != null ? q.justification : record.JustificationandDescription__c;
        record.Start_Date__c = !String.isBlank(q.startDate) ? Date.valueOf(q.startDate) : record.Start_Date__c;
        record.End_Date__c = !String.isBlank(q.endDate) ? Date.valueOf(q.endDate) : record.End_Date__c;
        record.UpdateContractTerms__c = BooleanHelper.toBoolean(q.updateContractTerms);
        record.AreaCode__c = mainAreaCode != null ? mainAreaCode.Id : null;
        record.FaxAreaCode__c = faxAreaCode != null ? faxAreaCode.Id : null;
        record.Upsell_Status__c = q.upsellStatus != null ? q.upsellStatus : record.Upsell_Status__c;
        record.Ship_Attention_To__c = q.shippingShipAttentionTo != null ? q.shippingShipAttentionTo : record.Ship_Attention_To__c;
        record.Shipping_Country__c = q.shippingCountry != null ? q.shippingCountry : record.Shipping_Country__c;
        record.Shipping_City__c = q.shippingCity != null ? q.shippingCity : record.Shipping_City__c;
        record.Shipping_State__c = q.shippingState != null ? q.shippingState : record.Shipping_State__c;
        record.Shipping_Address_Line__c = q.shippingAddressLine != null ? q.shippingAddressLine : record.Shipping_Address_Line__c;
        record.Shipping_Postal_Code__c = q.shippingPostalCode != null ? q.shippingPostalCode : record.Shipping_Postal_Code__c;
        record.Shipping_Additional_Address_Line__c = q.shippingAdditionalAddressLine != null ? q.shippingAdditionalAddressLine : record.Shipping_Additional_Address_Line__c;
        record.Shipping_Customer_Name__c = q.shippingCustomerName != null ? q.shippingCustomerName : record.Shipping_Customer_Name__c;
        record.Shipping_Option__c = q.shippingShippingOption != null ? q.shippingShippingOption : record.Shipping_Option__c;
        record.MultipleShippingLocations__c = BooleanHelper.toBoolean(q.shippingMultipleLocations);
        record.NGBSTaxesAdded__c = BooleanHelper.toBoolean(q.isTaxesAdded);
        record.Enabled_LBO__c = BooleanHelper.toBoolean(q.enabledLBO);
        record.LBODealDeskProvision__c = BooleanHelper.toBoolean(q.isLBODealDeskProvision);
        record.IsSendOrderToNGBS__c = !BooleanHelper.toBoolean(q.doNotSendOrderToNGBS);
        record.FSC_Full_MRS_Calculation__c = BooleanHelper.toBoolean(q.isFullCalculationFSC);
        record.Note_To_Customer__c = q.noteToCustomer != null ? q.noteToCustomer : record.Note_To_Customer__c;
        record.OverallDiscretion__c =  q.overallDiscretion;
        if (q.enabledLBO != null && q.enabledLBO) {
            record.InvalidDiscountedPhonesQuantity__c = false;
        }
        record.AverageDiscount__c =  q.averageDiscount;
    }

    private static Map<String, Object> getAreaCodeData(BillingWrappers.QuoteWrapper quoteWrapper) {
        Map<String, Object> areaCodeData = new Map<String, Object> {
            'countries' => new Set<String>(),
            'states'    => new Set<String>(),
            'cities'    => new Set<String>(),
            'areaCodes' => new Set<Integer>()
        };

        if (quoteWrapper != null) {
            if (
                quoteWrapper.mainAreaCodeInfo != null &&
                quoteWrapper.mainAreaCodeInfo.country != null &&
                quoteWrapper.mainAreaCodeInfo.areaCode != null
            ) {
                ((Set<String>) areaCodeData.get('countries')).add(quoteWrapper.mainAreaCodeInfo.country);
                ((Set<String>) areaCodeData.get('states')).add(quoteWrapper.mainAreaCodeInfo.state);
                ((Set<String>) areaCodeData.get('cities')).add(quoteWrapper.mainAreaCodeInfo.city);
                ((Set<Integer>) areaCodeData.get('areaCodes')).add(quoteWrapper.mainAreaCodeInfo.areaCode);
            }
            if (
                quoteWrapper.faxAreaCodeInfo != null &&
                quoteWrapper.faxAreaCodeInfo.country != null &&
                quoteWrapper.faxAreaCodeInfo.areaCode != null &&
                AreaCodeService.getAreaId(quoteWrapper.mainAreaCodeInfo) != AreaCodeService.getAreaId(quoteWrapper.faxAreaCodeInfo)
            ) {
                ((Set<String>) areaCodeData.get('countries')).add(quoteWrapper.faxAreaCodeInfo.country);
                ((Set<String>) areaCodeData.get('states')).add(quoteWrapper.faxAreaCodeInfo.state);
                ((Set<String>) areaCodeData.get('cities')).add(quoteWrapper.faxAreaCodeInfo.city);
                ((Set<Integer>) areaCodeData.get('areaCodes')).add(quoteWrapper.faxAreaCodeInfo.areaCode);
            }
        }

        return areaCodeData;
    }

    private static List<Area_Codes__c> getAreaCodesForInsert(
        BillingWrappers.QuoteWrapper quoteWrapper,
        Map<String, Area_Codes__c> areaCodeByAreaId
    ) {
        List<Area_Codes__c> areaCodes = new List<Area_Codes__c>();
        String faxAreaId = AreaCodeService.getAreaId(quoteWrapper.faxAreaCodeInfo);
        String mainAreaId = AreaCodeService.getAreaId(quoteWrapper.mainAreaCodeInfo);
        Area_Codes__c existingFaxAreaCode = areaCodeByAreaId.get(faxAreaId);
        Area_Codes__c existingMainAreaCode = areaCodeByAreaId.get(mainAreaId);
        Area_Codes__c newFaxAreaCode = AreaCodeService.buildAreaCode(quoteWrapper.faxAreaCodeInfo);
        Area_Codes__c newMainAreaCode = AreaCodeService.buildAreaCode(quoteWrapper.mainAreaCodeInfo);

        if (existingMainAreaCode == null && newMainAreaCode != null) {
            areaCodes.add(newMainAreaCode);
        }

        if (existingFaxAreaCode == null && newFaxAreaCode != null && faxAreaId != mainAreaId) {
            areaCodes.add(newFaxAreaCode);
        }

        return areaCodes;
    }

    private static Map<String, Area_Codes__c> getAreaCodes(BillingWrappers.QuoteWrapper quoteWrapper) {
        Map<String, Object> areaCodeData = getAreaCodeData(quoteWrapper);
        String quoteId = quoteWrapper != null ? quoteWrapper.id : null;
        Map<String, Area_Codes__c> areaCodeByAreaId = AreaCodeService.getAreaCodeWithAreaId(areaCodeData, quoteId);
        List<Area_Codes__c> areaCodesForInsert = getAreaCodesForInsert(
            quoteWrapper, areaCodeByAreaId
        );
        Database.insert(areaCodesForInsert, false);

        AreaCodeService.enrichAreaCodes(areaCodeByAreaId, areaCodesForInsert);

        return areaCodeByAreaId;
    }

    public static final String EMPTY_PARAMSDATA_ERR_MESSAGE = 'The required parameter is missing(paramsData)';
    public static final String EMPTY_QUOTEID_ERR_MESSAGE = 'The required parameter is missing(quoteId)';
    public static final String EMPTY_OPPID_ERR_MESSAGE = 'The required parameter is missing(opportunityId)';
    public static final String EMPTY_LINK_TO_AGREEMENT_ERR_MESSAGE = 'The required parameter is missing(linkToSignedAgreement)';

    @TestVisible
    private static Approval__c createPOCApproval(BillingWrappers.Params paramsData) {

        if (paramsData == null) {
            throw new AquivaHelper.AquivaException(EMPTY_PARAMSDATA_ERR_MESSAGE);
        }

        Id quoteId = (Id) paramsData.quoteId;

        if (quoteId == null) {
            throw new AquivaHelper.AquivaException(EMPTY_QUOTEID_ERR_MESSAGE);
        }

        Id opportunityId = (Id) paramsData.opportunityId;

        if (opportunityId == null) {
            throw new AquivaHelper.AquivaException(EMPTY_OPPID_ERR_MESSAGE);
        }

        Boolean isLinkToSignedAgreementMissing = paramsData.data == null ||
            !paramsData.data.containsKey('linkToSignedAgreement') ||
            String.isBlank(paramsData.data.get('linkToSignedAgreement'));

        if (isLinkToSignedAgreementMissing) {
            throw new AquivaHelper.AquivaException(EMPTY_LINK_TO_AGREEMENT_ERR_MESSAGE);
        }

        String linkToAgreeement = paramsData.data.get('linkToSignedAgreement');
        Boolean enableRingCXPOC = paramsData.data.get('enableRingCXPOC') != null ? 
                    Boolean.valueOf(String.valueOf(paramsData.data.get('enableRingCXPOC'))) : false;
        return createPOCApproval(quoteId, opportunityId, linkToAgreeement, enableRingCXPOC);
    }

    private static Approval__c createPOCApproval(Id quoteId, Id opportunityId, String linkToAgreeement, Boolean enableRingCXPOC) {

        List<Quote> qtList = new QuoteSelector()
            .selectQuoteByIdForPOCApproval(new List<Object>{quoteId})
            .executeQuery();

        Quote currentQuote = qtList.get(0);

        Decimal numberOfPOCUsers = (Decimal) NumberHelper.getNumberNullSafe(
            currentQuote.Total_Number_of_Digital_Lines__c
        );

        if (numberOfPOCUsers < 1 && !enableRingCXPOC) {
            numberOfPOCUsers = 1;
        } else if (numberOfPOCUsers == 0 && enableRingCXPOC) {
            numberOfPOCUsers = null;
        }

        Decimal phonesAmmount = 0;

        for (QuoteLineItem qli : currentQuote.QuoteLineItems) {
            phonesAmmount += (Decimal) NumberHelper.getNumberNullSafe(qli.Quantity);
        }

        Approval__c pocApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Approval__c.Account__c => currentQuote.AccountId,
                Approval__c.Opportunity__c => opportunityId,
                Approval__c.Quote__c => quoteId,
                Approval__c.POC_Application_Form__c => linkToAgreeement,
                Approval__c.Number_of_POC_Users__c => numberOfPOCUsers,
                Approval__c.RecordTypeId => ApprovalHelper.RT_ID_POC_ACCOUNT,
                Approval__c.PhonesAmount__c => phonesAmmount,
                Approval__c.Enable_RingCX_POC__c => enableRingCXPOC
            })
            .create()
            .getRecord();

        return pocApproval;
    }

    public static Quote copyBillingAddressFromAccountToQuote(Id quoteId, Id accountId) {
        Quote q = new Quote(Id = quoteId);

        Account acc = (Account) new AccountSelector()
            .selectAccountById(accountId)
            .selectFields(new List<String>{'BillingPostalCode', 'BillingCity', 'BillingCountry', 'BillingState', 'BillingStreet'})
            .executeQuery()
            .get(0);

        q.Billing_Zip_Postal_Code__c = acc.BillingPostalCode;
        q.Billing_City__c = acc.BillingCity;
        q.Billing_Country__c = acc.BillingCountry;
        q.Billing_State_Province__c = acc.BillingState;
        q.Billing_Street__c = acc.BillingStreet;

        update q;
        return q;
    }

    public static Quote cloneQuote(Id quoteId, Id masterQuoteId) {
        return CloneHelper.cloneQuote(quoteId, masterQuoteId);
    }

    private static Quote updatePackageReferencesOnQuote(Quote record, BillingWrappers.Params paramsData) {
        record.ServiceName__c = null;
        if (paramsData.packageInfo == null){
            return record;
        }

        List<BillingWrappers.QuotePackageInfo> pInfo = (List<BillingWrappers.QuotePackageInfo>)
            JSON.deserialize(paramsData.packageInfo, List<BillingWrappers.QuotePackageInfo>.class);
        if (pInfo.isEmpty()) {
            return record;
        }

        if (pInfo.size() != 1) {
            return record;
        }

        BillingWrappers.QuotePackageInfo packageInfo = pInfo[0];

        if (packageInfo.packageInfo != null) {
            record.PackageNameNew__c = packageInfo.packageInfo.displayName;
            record.PackageNameOld__c = packageInfo.packageInfo.oldPackageName;
        }
        record.ServiceName__c = packageInfo.productName;

        if (String.isBlank(packageInfo.packageInfo.id)) {
            return record;
        }

        List<Package__c> accountPackages = (List<Package__c>) new PackageSelector()
            .selectPackagesByAccountId(paramsData.accountId)
            .executeQuery();

        if (accountPackages.size() == 1) {
            if (packageInfo.packageInfo.id == accountPackages.get(0).Account_Package_Id__c) {
                record.BillingPackage__c = accountPackages.get(0).Id;
            }
        } else if (packageInfo.productName == QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT) {
            for (Package__c accountPackage : accountPackages) {
                if (accountPackage.Service_Type__c == PackageHelper.PROSERV_SERVICE_TYPE) {
                    record.BillingPackage__c = accountPackage.Id;
                }
            }
        }
        return record;
    }

    @TestVisible
    private static void setRenewalConditions(Quote qt, Boolean hasContract) {
        if (qt != null) {
            qt.Auto_Renewal__c = hasContract;
            if (!hasContract) {
                qt.Term_months__c = null;
                qt.Initial_Term_months__c = null;
                qt.Start_Date__c = null;
            }
        }
    }

    @TestVisible
    private static void checkRenewalConditions(Quote oldQuote, Quote newQuote, Quote qt) {
        if (
            (QuoteHelper.isContractDeselected(oldQuote, newQuote) ||
            QuoteHelper.isContractSelected(oldQuote, newQuote)) &&
            !QuoteHelper.isContractChanged(oldQuote, newQuote)
        ) {
            setRenewalConditions(qt, QuoteHelper.isQuoteHasContract(qt));
        }
        if (QuoteHelper.isContractSelected(oldQuote, newQuote)) {
            qt.Initial_Term_months__c = '24';
            qt.Term_months__c = '24';
        }
    }

    @TestVisible
    private static Map<String, Quote> upsertTechnicalQuotes(
        Id masterQuoteId,
        String[] serviceNames
    ) {
        Map<String, BillingWrappers.QuoteWrapper> quoteInfoByServices = new Map<String, BillingWrappers.QuoteWrapper>();

        for (String s: serviceNames) {
            quoteInfoByServices.put(s, new BillingWrappers.QuoteWrapper());
        }

        return QuoteHelper.upsertTechnicalQuotes(masterQuoteId, quoteInfoByServices);
    }

    @TestVisible
    private static Map<String, Quote> upsertTechnicalQuotes(
        Id masterQuoteId,
        Map<String, BillingWrappers.QuoteWrapper> quoteInfoByServices
    ) {
        return QuoteHelper.upsertTechnicalQuotes(masterQuoteId, quoteInfoByServices);
    }

    @TestVisible
    private static Map<String, Quote> upsertTechnicalQuotesUB(
        Id masterQuoteId,
        String[] serviceNames
    ) {
        Map<String, BillingWrappers.QuoteWrapper> quoteInfoByServices = new Map<String, BillingWrappers.QuoteWrapper>();

        for (String s: serviceNames) {
            quoteInfoByServices.put(s, new BillingWrappers.QuoteWrapper());
        }

       return QuoteHelper.upsertTechnicalQuotesUB(masterQuoteId, quoteInfoByServices);
    }

    @TestVisible
    private static Map<String, Quote> upsertTechnicalQuotesUB(
        Id masterQuoteId,
        Map<String, BillingWrappers.QuoteWrapper> quoteInfoByServices
    ) {
        return QuoteHelper.upsertTechnicalQuotesUB(masterQuoteId, quoteInfoByServices);
    }

    @TestVisible
    private static List<ServiceInfo__c> getServiceInfo(Id masterQuoteId) {
        return QuoteHelper.getServiceInfo(masterQuoteId);
    }

    @TestVisible
    private static List<ServiceInfo__c> syncServiceInfo(BillingWrappers.Params params) {
        return QuoteHelper.syncServiceInfo(params.quoteId, params.terminationMap);
    }

    @TestVisible
    private static Map<String, Quote> getTechnicalQuotes(
        Id masterQuoteId,
        String[] serviceNames
    ) {
        return QuoteHelper.getTechnicalQuotesByMasterId(masterQuoteId, serviceNames);
    }

    @TestVisible
    private static Map<String, Quote> getTechnicalQuotesUB(
        Id masterQuoteId,
        String[] serviceNames
    ) {
        return QuoteHelper.getTechnicalQuotesByMasterIdUB(masterQuoteId, serviceNames);
    }

    @TestVisible
    private static void submitPocApproval(Id pocApprovalId) {
        Approval__c pocApproval = (Approval__c) new ListOptional(new ApprovalSelector()
            .selectApprovalsByIds(new List<Object>{new List<Id>{pocApprovalId}})
            .executeQuery()
        ).getFirst();
        if (pocApproval != null && pocApproval.Status__c != ApprovalHelper.STATUS_APPROVED) {
            ApprovalHelper.submitApprovalRequest(
                pocApproval.id,
                ApprovalHelper.PROCESS_POC_ACCOUNT_APPROVAL_V4,
                null
            );
        }
    }

    @TestVisible
    private static void checkAndUpdateOpportunity(Quote existingQuote, BillingWrappers.QuoteWrapper wrapper, Boolean hasRCCC) {
        Opportunity existingOpp = existingQuote.Opportunity;
        if (existingOpp == null || wrapper == null) {
            return;
        }

        List<Opportunity> oppToUpdate = new List<Opportunity>();

        Opportunity updatedOpp = new Opportunity(
            Id = existingOpp.Id,
            ProvisioningDetails__c = wrapper.opportunityProvisioningDetails,
            SelfProvisioned__c = BooleanHelper.toBoolean(wrapper.opportunitySelfProvisioned),
            NumberToBeRCMainNumber__c = wrapper.rcAccountNumber,
            NumberToBeCCNumber__c = wrapper.ccAccountNumber,
            isTermination__c = BooleanHelper.toBoolean(wrapper.isTerminationOpportunity)
        );

        if (existingQuote.isPrimary__c) {
            updatedOpp.RCCCSyncStatus__c = hasRCCC == true
                ? IcbHelper.CC_SYNC_STATUS_NOT_STARTED
                : IcbHelper.CC_SYNC_STATUS_NOT_APPLICABLE;
        }

        Boolean isFieldsValuesChanged = isOpportunityFieldsChanged(existingOpp, updatedOpp);
        if (!isFieldsValuesChanged) {
            return;
        }

        oppToUpdate.add(updatedOpp);

        List<Opportunity> technicalOpportunities = new OpportunitySelector()
            .selectServiceOpportunitiesByMasterId(existingOpp.Id)
            .executeQuery();

        if (!technicalOpportunities.isEmpty()){
            for (Opportunity techOpp: technicalOpportunities) {
                Opportunity techOppRecord = new Opportunity(Id = techOpp.Id);
                techOppRecord.SelfProvisioned__c = BooleanHelper.toBoolean(wrapper.opportunitySelfProvisioned);
                if (techOpp.Tier_Name__c == QuoteHelper.NGBS_RCCC_PRODUCT) {
                    techOppRecord.NumberToBeRCMainNumber__c = wrapper.rcAccountNumber;
                    techOppRecord.NumberToBeCCNumber__c = wrapper.ccAccountNumber;
                }
                oppToUpdate.add(techOppRecord);
            }
        }

        update oppToUpdate;
    }

    private static final Set<String> OPP_FIELDS_TO_CHECK = new Set<String>{
        Opportunity.ProvisioningDetails__c.getDescribe().getName(),
        Opportunity.SelfProvisioned__c.getDescribe().getName(),
        Opportunity.NumberToBeRCMainNumber__c.getDescribe().getName(),
        Opportunity.NumberToBeCCNumber__c.getDescribe().getName(),
        Opportunity.RCCCSyncStatus__c.getDescribe().getName(),
        Opportunity.isTermination__c.getDescribe().getName()
    };

    @TestVisible
    private static Boolean isOpportunityFieldsChanged(Opportunity existingOpp, Opportunity updatedOpp) {
        if (existingOpp == null || updatedOpp == null) {
            return false;
        }

        Boolean objectIsChanged = false;

        for (String fieldName : OPP_FIELDS_TO_CHECK) {
            if (existingOpp.get(fieldName) != updatedOpp.get(fieldName)) {
                objectIsChanged = true;
                break;
            }
        }

        return objectIsChanged;
    }

    public static Response proServIgnite(Id selectedQuoteId, String proServCaseReasons, String action) {
        String proServDetails = action == 'engageProServIgnite' ? QuoteHelper.STATUS_PRO_SERV_IGNITE_INITIATED : QuoteHelper.STATUS_PRO_SERV_IGNITE_CANCELLED;
        Quote quoteToUpdate = new Quote(
            Id = selectedQuoteId,
            ProServ_Details__c = proServDetails
        );
        update quoteToUpdate;
        return EmailHelperIgnite.proServIgnite(selectedQuoteId, proServCaseReasons, action);
    }

    public static BillingWrappers.ProservParam getProservDetail(Id opptyId) {
        BillingWrappers.ProservParam proservParam = new BillingWrappers.ProservParam(null);
        List<Order> orders = new OrderSelector()
            .selectOrdersByOpportunityIds(new List<Object> {new List<Id>{opptyId}, new List<String>{OrderHelper.TYPE_INITIAL_ORDER, OrderHelper.TYPE_CHANGE_ORDER}})
            .executeQuery();

        Set<Id> proservProjectOpptyIds = new Set<Id>();
        for (Order ord : orders) {
            if (ord.ProServProject__r?.Opportunity__c != null) {
                proservProjectOpptyIds.add(ord.ProServProject__r.Opportunity__c);
            }
        }
        if(!proservProjectOpptyIds.isEmpty()){
            List<Package__c> existingPSPackages = (List<Package__c>) new PackageSelector()
                .selectPackagesByOpportunityIdAndServiceName(proservProjectOpptyIds, QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT)
                .selectFields(new List<String>{'Account_Package_Id__c'})
                .executeQuery();

            if(!existingPSPackages.isEmpty()) {
                proservParam = new BillingWrappers.ProservParam(existingPSPackages.get(0).Account_Package_Id__c);
            }
        }
        return proservParam;
    }
}