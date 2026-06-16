global with sharing class ApexWebServices {
    private static final String SELECT_STRING = '---Select---';
    public static final String TREASURY_QUEUE = 'Billing Credit Check';

    /**
    * @description return permission for the profile
    * @param  profileId Id of user's profile
    * @return Boolean value of permission for profile
     */
    @AuraEnabled
    public static OrderDetail getOrderDetail(String orderId){
        OrderDetail orderdetail=new OrderDetail();
        try{
            Order order = [Select Id,Status,TotalBandwidthOnQuote__c,TotalBandwidthOnOrder__c,RecordTypeId from Order where Id=:orderId];
            boolean hasPermission = FeatureManagement.checkPermission('PermissionsActivateOrder');
            orderdetail.order = order;
            orderdetail.hasPermission = hasPermission;
        }
        catch(Exception ex){
            system.debug('Error:'+ex.getmessage());
        }
        return orderdetail;
    }
    @AuraEnabled
    public static OrderDetailforDeactivate getOrderDetailforDeactivate(String orderId){
        OrderDetailforDeactivate orderdetail = new OrderDetailforDeactivate();
        try{
            Order order = [Select Id,Status from Order where Id=:orderId];
            Id profileId=userinfo.getProfileId();
			Profile profile = [Select Id,Name from Profile where Id=:profileId];
            String profileName = profile.Name;
            orderdetail.order = order;
            orderdetail.profileName = profileName;
        }
        catch(Exception ex){
            system.debug('Error:'+ex.getmessage());
        }
        return orderdetail;

    }
    webService static Boolean havePermissionByProfile( String profileId, String permission ) {
        String query = 'SELECT ' + permission + ' FROM Profile WHERE Id = \'' + profileId + '\'';
        Profile profile = Database.query( query );
        return Boolean.valueOf( profile.get( permission ) );
    }

    /**
    * @description The method is started from JavaScript button "Complete Order" and "Deactivate Order" in accordance with second parameter in the method. Also related records with Order are locked or unlocked and changed Status on Order
    * @param  orderId Id of Order records
    * @param  lock    Boolean value specifies what to do with order: true - lock, false - unlock
    * @return Boolean value specifies that all products have been finished successfully or not.
     */
     @AuraEnabled
    webService static Boolean activateOrderWithChildren( String orderId, Boolean lock ) {
        List<Order> orders = [SELECT Id, RecordType.DeveloperName FROM Order WHERE Id = :orderId];
        List<Case> cases = [SELECT Id FROM Case WHERE Order__c = :orderId AND RecordType.DeveloperName = 'inContact_Order'];
        List<Site__c> sites = [SELECT Id FROM Site__c WHERE Order__c = :orderId];
        List<Hardware_Line_Item__c> hardwares = [SELECT Id FROM Hardware_Line_Item__c WHERE Order__c = :orderId];
        List<Phase__c> phases = [SELECT Id FROM Phase__c WHERE Order__c = :orderId];
        Boolean successAllLock;

        Order order = orders.get(0);
        if ( lock ) {
            order.Status = 'Completed';
        } else {
            if ( order.RecordType.DeveloperName == 'Contact_Center' ) {
                order.Status = 'Requires Attention';
            } else {
                order.Status = 'In Progress';
            }
        }
        update order;

        if (lock) {
            successAllLock = lockRecords(orders);
            successAllLock = lockRecords(cases);
            successAllLock = lockRecords(sites);
            successAllLock = lockRecords(hardwares);
            successAllLock = lockRecords(phases);
        } else {
            successAllLock = unlockRecords(orders);
            successAllLock = unlockRecords(cases);
            successAllLock = unlockRecords(sites);
            successAllLock = unlockRecords(hardwares);
            successAllLock = unlockRecords(phases);
        }

        System.debug( 'All records was ' + ( lock ? 'lock' : 'unlock' ) + 'ed with status >>> ' + successAllLock );

        return successAllLock;
    }

    /**
    * @description For locking records
    * @param  objects - list of objects
    * @return Boolean value specifies that all records have been finished successfully or not.
     */
    private static Boolean lockRecords( List<SObject> objects ) {
        Boolean success = true;

        if( !objects.isEmpty() ) {
            Approval.LockResult[] lrList = Approval.lock(objects, true);

            for (Approval.LockResult lr : lrList) {
                if (lr.isSuccess()) {
                    System.debug('Successfully locked record of SObject with ID: ' + lr.getId());
                } else {
                    // Operation failed, so get all errors
                    success = false;
                    for (Database.Error err : lr.getErrors()) {
                        System.debug('The following error has occurred.');
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('record of SObject fields that affected this error: ' + err.getFields());
                    }
                }
            }
        }

        return success;
    }

    /**
    * @description For unlocking records
    * @param  objects - list of objects
    * @return Boolean value specifies that all records have been finished successfully or not.
     */
    private static Boolean unlockRecords( List<SObject> objects ) {
        Boolean success = true;

        if( !objects.isEmpty() ) {
            Approval.UnlockResult[] lrList = Approval.unlock(objects, true);

            for (Approval.UnlockResult lr : lrList) {
                if (lr.isSuccess()) {
                    System.debug('Successfully locked record of SObject with ID: ' + lr.getId());
                } else {
                    // Operation failed, so get all errors
                    success = false;
                    for (Database.Error err : lr.getErrors()) {
                        System.debug('The following error has occurred.');
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('record of SObject fields that affected this error: ' + err.getFields());
                    }
                }
            }
        }

        return success;
    }

    /**
    * @description The method is started from JavaScript button "Complete Phase".
    * @param  phaseId Id of Phase records
    * @param  lock    Boolean value specifies what to do with order: true - lock, false - unlock
    * @return Boolean value specifies that all products have been finished successfully or not.
     */
    webService static Boolean completePhase(String phaseId, Boolean lock) {
        List<Phase__c> phases = [SELECT Id FROM Phase__c WHERE Id = :phaseId];
        List<Hardware_Line_Item__c> hardwares = [SELECT Id FROM Hardware_Line_Item__c WHERE RingCentral_Hardware_Phase__c = :phaseId];
        Boolean successAllLock;

        if (lock) {
            successAllLock = lockRecords(phases);
            successAllLock = lockRecords(hardwares);
        }

        System.debug( 'All records was ' + ( lock ? 'lock' : 'unlock' ) + 'ed with status >>> ' + successAllLock );

        return successAllLock;
    }

    /**
    * @description The method is started from JavaScript button "Change Order".
    * @param  orderId Id of Order record where 'ChangeOrder' btn was pressed
    * @return Boolean value specifies that current Order is completed or not.
    */
    @AuraEnabled
    webservice static Boolean checkOrderIsCompleted(String orderId) {

        if(orderId == null) {
            return false;
        }

        Order currentOrder = [select Id, Status, (select Id, Completed_Date__c from Phases__r) from Order where Id = :orderId];

        // all phases has non empty completionDate
        Boolean foundNotCompletedPhase = false;

        for(Phase__c phase : currentOrder.Phases__r) {
            if(phase.Completed_Date__c == null) {
                foundNotCompletedPhase = true;
            }
        }

        Boolean orderIsCompleted = currentOrder.Phases__r.isEmpty() ?
                currentOrder.Status == 'Completed' : (!foundNotCompletedPhase || currentOrder.Status == 'Completed');

        return orderIsCompleted;
    }

    /**
    * @description The method is used in JavaScript button "Change Order".
    * @param  orderId Id of Order record where 'ChangeOrder' btn was pressed
    * @return Boolean value specifies that Order has phase in 'Pending Approval' status.
    */
    @AuraEnabled
    webservice static Boolean checkPhasesIsPendingApproval(String orderId) {

        if(orderId == null) {
            return false;
        }

        Order currentOrder = [select Id, (select Id, Status__c from Phases__r) from Order where Id = :orderId];

        Boolean foundPendingForApprovalPhase = false;

        for(Phase__c phase : currentOrder.Phases__r) {
            if(phase.Status__c == PhaseHelper.STATUS_PENDING_APPROVAL) {
                foundPendingForApprovalPhase = true;
                break;
            }
        }

        return foundPendingForApprovalPhase;
    }

    /**
    * @description The method is started from JavaScript button "Change Order".
    * @param  orderId Id of Order record where 'ChangeOrder' btn was pressed
    * @return created change order Opportunity Id
    */
    @AuraEnabled
    webservice static String changeOrder(String orderId) {
        if (String.isBlank(orderId)) {
            return null;
        }
        PhaseTriggerHandler.changeOrderFlow = true;
        OpportunityTriggerHelperRefactored.isChangeOrderFlow = true;
        Response changeOrderResponse = ChangeOrder.createChangeOrder(orderId);
        PhaseTriggerHandler.changeOrderFlow = false;
        OpportunityTriggerHelperRefactored.isChangeOrderFlow = false;
        return JSON.serialize(changeOrderResponse);
    }

    @AuraEnabled
    public static Id getLastCreatedChangeOrderId(String proservProjectId) {
        return OrderHelper.getLastCreatedChangeOrder(proservProjectId).Id;
    }

    public class CloseOpportunityParams {
        public Id opportunityId;
        public Id mpUbTechQuoteId;
        public String rcNumber;
        public String ccNumber;
        public String approvalId;
    }

    public class QueriedData {
        public Opportunity opportunity;
        public List<Quote> quotes;
        public List<Phase__c> phases;
        public List<Area_Code_Line_Item__c> areaCodeLineItems;
        public String userProfileName;
        public List<TierTypeSetting__c> tierTypeSetting;
        public Integer optyQuantity;
        public Map<Id, Cost_Center_Line_Item__c> costCenterLineItems;
        public AccountContactRole accContactRole;
        public Account masterAccount;
        public Map<String, List<Approval__c>> approvalsMap;
        public List<Promotion__c> promoList;
        public List<PartnerOperationsLog__c> partnerOperationsLogs;
    }

    /**
     * [prevalidationActions - Basically actions which should be fired after prompts logic]
     * @param closeParams [Parameters populated by user if needed on opportunity close]
     */
    private static void queryData(
        CloseOpportunityParams closeOpportunityParams,
        QueriedData queriedParams
    ) {
        if (closeOpportunityParams == null) {
            AquivaHelper.throwAquivaException('Empty list of parameters for closing the opportunity');
        }
        /**
         * @param opportunity
         **/
        queriedParams.opportunity = (Opportunity) new OpportunitySelector()
            .selectOpportunityForClose(new Set<Id>{closeOpportunityParams.opportunityId})
            .executeQuery()
            .get(0);
        /**
         * @param quotes
         **/
        if (closeOpportunityParams.mpUbTechQuoteId != null) {
            // For MPUB technical quote validation, get just the specific technical quote
            queriedParams.quotes = new QuoteSelector()
                .selectTechQuotesForClose(new List<Object>{ closeOpportunityParams.opportunityId, closeOpportunityParams.mpUbTechQuoteId })
                .executeQuery();
        } else if (OpportunityHelper.isMasterMultiProductOpportunity(closeOpportunityParams.opportunityId)) {
            List<Quote> techQuotes = new QuoteSelector()
                .selectTechQuotesForClose(new List<Object>{ closeOpportunityParams.opportunityId })
                .executeQuery();

            queriedParams.quotes = !techQuotes.isEmpty()
                ? techQuotes
                : new QuoteSelector()
                    .selectQuotesForClose(closeOpportunityParams.opportunityId)
                    .executeQuery();
        } else {
            queriedParams.quotes = new QuoteSelector()
                .selectQuotesForClose(closeOpportunityParams.opportunityId)
                .executeQuery();
        }
        /**
         * @param phases
         **/
        queriedParams.phases = new PhaseSelector()
            .selectPhasesForClose(new List<Object>{queriedParams.quotes})
            .executeQuery();

        Quote qtBilling = QuoteHelper.getPrimaryQuote(queriedParams.quotes, true);
        /**
         * @param areaCodeLineItems
         **/
        queriedParams.areaCodeLineItems = [
            SELECT Id, Quote_Line_Item__c
            FROM Area_Code_Line_Item__c
            WHERE Quote_Line_Item__r.QuoteId IN :queriedParams.quotes
        ];
        /**
         * @param userProfileName
         **/
        queriedParams.userProfileName = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId()].Name;
        /**
         * @param tierTypeSetting
         **/
        queriedParams.tierTypeSetting = TierTypeSetting__c.getall().values();
        Set<String> stages = new Set<String>{OpportunityHelper.STAGE_NAME_DOWNGRADED};
        stages.addAll(OpportunityHelper.STAGE_NAMES_CLOSED);
        /**
         * @param optyQuantity
         **/
        queriedParams.optyQuantity = [
            SELECT count()
            FROM Opportunity
            WHERE AccountId = :queriedParams.opportunity.AccountId
            AND StageName NOT IN :stages
        ];
        /**
         * @param costCenterLineItems
         **/
        queriedParams.costCenterLineItems = new Map<Id, Cost_Center_Line_Item__c>();
        if (qtBilling != null) {
            Set<Id> qliIds = new Set<Id>(
                new Map<Id, QuoteLineItem>(qtBilling.QuoteLineItems).keySet()
            );

            queriedParams.costCenterLineItems = new Map<Id, Cost_Center_Line_Item__c>(
                (List<Cost_Center_Line_Item__c>) new CostCenterLineItemSelector()
                    .selectCostCentersLineItemsForCloseValidation(qliIds)
                    .executeQuery()
            );
        }

        List<AccountContactRole> accContactRoleList = new AccountContactRoleSelector()
            .selectAccountContactRoles()
            .selectFields(new List<String>{
                'AccountId', 'Contact.FirstName', 'Contact.LastName', 'Contact.Email', 'Contact.Phone'
            })
            .setCondition('AccountId = \'' + queriedParams.opportunity.AccountId + '\'' +  ' AND IsPrimary = true AND Role = \'' + OpportunityHelper.CONTACT_ROLE_SIGNATORY + '\'')
            .executeQuery();
        /**
         * @param accContactRole
         **/
        queriedParams.accContactRole =
            accContactRoleList.isEmpty() ? null : accContactRoleList.get(0);
        /**
         * @param masterAccount
         **/
        if (!String.isBlank(queriedParams.opportunity.Account?.Master_Account__c)) {
            queriedParams.masterAccount = (Account) new AccountSelector()
                .selectAccountForOpportunityClose(new List<Object>{new Set<Id> {
                    queriedParams.opportunity.Account.Master_Account__c}
                })
                .executeQuery()
                .get(0);
        }

        queriedParams.opportunity.NumberToBeRCMainNumber__c = closeOpportunityParams.rcNumber;
        queriedParams.opportunity.NumberToBeCCNumber__c = closeOpportunityParams.ccNumber;

        Set<Id>accIdSet = new Set<Id>{queriedParams.opportunity.AccountId};
        if (queriedParams.opportunity.Account.Master_Account__c != null) {
            accIdSet.add(queriedParams.opportunity.Account.Master_Account__c);
        }

        List<Approval__c> accApprovals = (List<Approval__c>) new ApprovalSelector()
            .selectApprovalsForAccount(new List<Object>{accIdSet})
            .executeQuery();
        List<Approval__c> invoiceApprovals = new List<Approval__c>();
        List<Approval__c> invoiceOfficeApprovals = new List<Approval__c>();
        List<Approval__c> kycApprovals = new List<Approval__c>();
        List<Approval__c> vatIdExemptAprovals = new List<Approval__c>();
        List<Approval__c> taxExemptAprovals = new List<Approval__c>();
        for (Approval__c approval : accApprovals) {
            if (approval.RecordTypeId == ApprovalHelper.RT_ID_INVOICING_REQUEST) {
                if (approval.Account__c == queriedParams.opportunity.AccountId) {
                    invoiceApprovals.add(approval);
                } else if (approval.Account__c == queriedParams.opportunity.Account.Master_Account__c) {
                    invoiceOfficeApprovals.add(approval);
                }
            } else if (approval.RecordTypeId == ApprovalHelper.RT_ID_KYC_APPROVAL_REQUEST) {
                kycApprovals.add(approval);
            } else if (approval.RecordTypeId == ApprovalHelper.RT_ID_VAT_ID_Exemption && approval.Status__c == ApprovalHelper.STATUS_APPROVED) {
                vatIdExemptAprovals.add(approval);
            } else if (approval.RecordTypeId == ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL && approval.Status__c == ApprovalHelper.STATUS_APPROVED) {
                taxExemptAprovals.add(approval);
            }
        }
        /**
         * @param approvalsMap
         **/
        queriedParams.approvalsMap = new Map<String, List<Approval__c>>();
        queriedParams.approvalsMap.put('invoice', invoiceApprovals);
        queriedParams.approvalsMap.put('invoiceOffice', invoiceOfficeApprovals);
        queriedParams.approvalsMap.put('KYC', kycApprovals);
        queriedParams.approvalsMap.put('vatIdExempt', vatIdExemptAprovals);
        queriedParams.approvalsMap.put('taxexempt', taxExemptAprovals);
        /**
         * @param promoList
         **/
        queriedParams.promoList = new List<Promotion__c>();
        if (qtBilling != null) {
            queriedParams.promoList = (List<Promotion__c>) new PromotionSelector()
                .selectPromotionByQuoteId(new List<Object>{new Set<Id>{qtBilling.Id}})
                .executeQuery();
        }
        /**
         * @param partnerOperationsLog
         */
        queriedParams.partnerOperationsLogs = QuoteHelper.getPartnerOperationLog(closeOpportunityParams.opportunityId);
    }

    /**
     * [prevalidationActions - Basically actions which should be fired after prompts logic]
     * @param closeParams [Parameters populated by user if needed on opportunity close]
     */
    private static void postvalidationActions(CloseOpportunityParams closeParams, Opportunity oppToUpdate) {
        Boolean isEngageTerminationOpportunity =
            BooleanHelper.toBoolean(OpportunityHelper.engageOppIdToTerminationStatus(new List<Opportunity>{oppToUpdate})?.get(oppToUpdate.Id));

        if (isEngageTerminationOpportunity) {
            OpportunityHelper.closeOpportunity(oppToUpdate);
            List<Quote> quotes = (List<Quote>) new QuoteSelector()
                .selectQuotesForAccount(new Set<Id>{oppToUpdate.AccountId})
                .executeQuery();
            List<Quote> updateQuotes = new List<Quote>();
            for (Quote q : quotes) {
                if (QuoteHelper.isNeedSetQuoteInvalid(q, new List<Opportunity> {oppToUpdate})) {
                    Quote updatedQuote = new Quote(Id = q.Id, Quote_is_Invalid__c = true);
                    updateQuotes.add(updatedQuote);
                }
            }
            update updateQuotes;
        }

        if (closeParams.rcNumber != null && closeParams.ccNumber != null || isEngageTerminationOpportunity) {
            update oppToUpdate;
        }

        // Engage legal approval recall
        if (closeParams.approvalId != null) {
            ApprovalHelperCls.recall(closeParams.approvalId);
        }

        if (OpportunityHelper.isVerizon(oppToUpdate)) {
            update oppToUpdate;
        }
    }

    /**
     * [validateOnCloseOpportunity  - Opportunity close js button]
     * @param  closeOpportunityParams [Params need to contain
     *                                   opportunityId - Opportunity id which is going to be closed
     *                                 and optionally
     *                                   rcNumber - NumberToBeRCMainNumber__c
     *                                   ccNumber - NumberToBeCCNumber__c
     *                                   approvalId - Approval id
     *                                 ]
     * @return                        [description]
     */
    webservice static string validateOnCloseOpportunity(String closeOpportunityParamsString) {
        Response resp;
        try {
            if (String.isBlank(closeOpportunityParamsString)) {
                return JSON.serialize(new Response(
                    'Error',
                    'Close opportunity parameters are not specified',
                    Response.SEVERITY_ERROR
                ));
            }
            CloseOpportunityParams params = (CloseOpportunityParams) JSON.deserialize(
                closeOpportunityParamsString, CloseOpportunityParams.class);

            QueriedData queriedParams = new QueriedData();
            queryData(
                params,
                queriedParams
            );

            BillingWrappers.NGBSAccount accountInfo = getNGBSAccount(queriedParams.opportunity.Account.Billing_ID__c);

            OpportunityHelper.QuotesWrapper qtsWrapper = new OpportunityHelper.QuotesWrapper(queriedParams.quotes, queriedParams.opportunity);
            String paymentMethod = QuoteHelper.getPaymentMethod(queriedParams.opportunity.Account, queriedParams.opportunity, qtsWrapper.primaryQuote, accountInfo, true);

            if (accountInfo == null) {
                accountInfo = getNGBSAccount(queriedParams.masterAccount.Billing_ID__c);
            }

            resp = OpportunityHelper.validateOpportunityOnClose(
                queriedParams.opportunity,
                qtsWrapper,
                queriedParams.phases,
                queriedParams.areaCodeLineItems,
                queriedParams.userProfileName,
                queriedParams.tierTypeSetting,
                queriedParams.optyQuantity,
                queriedParams.costCenterLineItems,
                queriedParams.accContactRole,
                queriedParams.masterAccount,
                queriedParams.approvalsMap,
                queriedParams.promoList,
                paymentMethod,
                queriedParams.partnerOperationsLogs,
                accountInfo
            );

            postvalidationActions(params, queriedParams.opportunity);

        } catch (Exception e) {
            resp = new Response(e);
        }
        return JSON.serialize(resp);
    }

    private static BillingWrappers.NGBSAccount getNGBSAccount(String billingId) {
        return String.isNotBlank(billingId) ? NGBSAPI.getNGBSAccount(billingId) : null;
    }

    webservice static Response validateELOpportunity (Id opportunityId, String buttonName) {
        return validateELOpportunityWithStatusesList(opportunityId, buttonName);
    }

    private static Response validateELOpportunityWithStatusesList (Id opportunityId, String buttonName) {
        List<Approval__c> approvals = new List<Approval__c> ([
                SELECT Id, Status__c, CreatedById, RecordTypeId
                FROM Approval__c
                WHERE Record_Type_Name__c = :ApprovalHelper.RT_NAME_ENGAGE_LEGAL AND Opportunity__c = :opportunityId
        ]);
        return validateELApprovals(approvals, buttonName);
    }

    public static Response validateELApprovals(List<Approval__c> approvals, String buttonName) {
        List<String> recallNotNeeded = new List<String>{
            ApprovalHelper.STATUS_COMPLETED,
            ApprovalHelper.STATUS_REJECTED,
            ApprovalHelper.STATUS_LOST,
            ApprovalHelper.STATUS_RECALLED
        };
        if ('Send with DocuSign'.equals(buttonName)) {
            recallNotNeeded.add(ApprovalHelper.STATUS_READY_FOR_SIGNATURE);
            recallNotNeeded.add(ApprovalHelper.STATUS_OUT_FOR_SIGNATURE);
        }

        Response resp = new Response();

        for (Approval__c approval : approvals) {
            if (recallNotNeeded.contains(approval.Status__c)
                || approval.RecordTypeId != ApprovalHelper.RT_ID_ENGAGE_LEGAL) {
                continue;
            }

            if (approval.Status__c == ApprovalHelper.STATUS_PENDING
                || !AquivaHelper.isCurrentUserSuitableForRecallingEL() ) {
                resp = processApprovalInProgress(approval);
                break;
            } else {
                resp.setData('approvalId', approval.Id);
                break;
            }
        }

        return resp;
    }

    /**
     * [processApprovalInProgress description]
     * @param  appRecord [Approval__c record]
     * @return           [Response with error
     *                             Approval submitter != User who pushed "Close" or "Send with docusign" button
     *                    Response positive
     *                             Approval submitter == User who pushed "Close" or "Send with docusign" button]
     */
    private static Response processApprovalInProgress(Approval__c appRecord) {
        Response resp = new Response();
        if (UserInfo.getUserId() == appRecord.CreatedById) {
            resp.setData('approvalId', appRecord.Id);
        } else {
            User approvalSubmitter = UserHelper.getORQueryUsers(new Set<Id>{appRecord.CreatedById}).values()[0];
            resp.addMessage(
                'Please contact ' +
                + approvalSubmitter.Name +
                + ' to recall the Legal Engagement process before closing the opportunity',
                Response.SEVERITY_ERROR
            );
        }
        return resp;
    }

    webService static String validateOpptyBeforeSalesOPsEngagement(String accId, String oppStage) {
        if (!OpportunityHelper.isClosed(oppStage)) {
            return 'You are not able to engage salesOps if the opportunity is not in the Closed Won stage';
        }

        Account acc = [
                SELECT Id, Payment_Method__c
                FROM Account
                WHERE Id = :accId
        ];

        List<String> allowedApprovalStatuses = new List<String>{'Approved', 'Recalled', 'Rejected'};

        if (acc.Payment_Method__c == 'Invoice') {
            List<Approval__c> approvals = new List<Approval__c> ([
                    SELECT Id, Status__c
                    FROM Approval__c
                    WHERE Record_Type_Name__c = 'Invoicing Request' AND Account__c = :accId
            ]);
            for (Approval__c appr: approvals) {
                if (!allowedApprovalStatuses.contains(appr.Status__c)) {
                    return 'You are not able to engage salesOps if under related account there is an Invoicing Request which is not in terminal status';
                }
            }
        }
        return null;
    }

    webService static String createCaseFromOpp(String oppId,
                                                String caseCategory,
                                                String caseType,
                                                String caseDescription,
                                                String casePriority,
                                                String caseUrgency,
                                                String caseRecord) {
        Map<String, String> jsonResult = new Map<String, String>();
        String redirectUrl = '';
        String baseUrl = System.URL.getOrgDomainUrl().toExternalForm();
        Map <String, Schema.RecordTypeInfo> caseRecordType = Case.SObjectType.getDescribe().getRecordTypeInfosByName();
        Id rtId = caseRecordType.get(caseRecord).getRecordTypeId();
        Case cs = new Case();
        Opportunity opp;
        String ownerRole;

        try {
            opp = [
                    SELECT AccountId, Name, CloseDate, StageName,
                            OwnerId, Owner.UserRoleId
                    FROM Opportunity
                    WHERE Id =: Id.valueOf(oppId)
                    ];

            if (opp.Owner != null
                && opp.Owner.UserRoleId != null) {
                ownerRole = [
                            SELECT Name
                            FROM UserRole
                            WHERE Id =: opp.Owner.UserRoleId
                            ].Name;
            }
            cs.OwnerId = [
                        SELECT Id
                        FROM Group
                        WHERE Type = 'Queue'
                        AND Name =: 'Sales Order Except Desk Queue'
                        LIMIT 1
                        ].Id;
            cs.Description = caseDescription;
            cs.Case_Category__c = caseCategory;
            cs.Type1__c = (caseType == SELECT_STRING? null : caseType);
            cs.RecordTypeId = rtId;
            cs.Case_Originator__c = opp.OwnerId;
            cs.AccountId = opp.AccountId;
            cs.Opportunity_Reference__c = Id.valueOf(oppId);
            cs.Segment__c = ownerRole;

            insert cs;
            redirectUrl += baseUrl + '/' + cs.Id;

            jsonResult.put('status', 'success');
            jsonResult.put('message', 'Redirecting to opportunity creation page');
            jsonResult.put('redirectUrl', redirectUrl);

            return JSON.serialize(jsonResult);
        } catch (Exception e) {
            jsonResult.put('status', 'error');
            jsonResult.put('header', 'Error occurred during URL creation');
            jsonResult.put('message', e.getStackTraceString() + '<br/>' + e.getMessage());

            return JSON.serialize(jsonResult);
        }
    }

    webService static String getPicklistValues(String field) {
        Map<String, String> jsonResult = new Map<String, String>();
        String pickListValuesString = '';
        Schema.DescribeFieldResult fieldResult;

        switch on field {
            when 'category' {
                fieldResult = Case.Case_Category__c.getDescribe();
            }
            when 'type' {
                fieldResult = Case.Type1__c.getDescribe();
            }
        }
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            if (pickListVal.getLabel() != 'Sales Order Except Desk') {
                pickListValuesString += pickListVal.getLabel() + ';';
            }
        }

        jsonResult.put('values', pickListValuesString.removeEnd(';'));
        return JSON.serialize(jsonResult);
    }

    webservice static void savePhoneNumbersForOrders(Id oppId, String rcNumber, String ccNumber) {
        update new Opportunity(
            Id = oppId,
            NumberToBeRCMainNumber__c = rcNumber,
            NumberToBeCCNumber__c = ccNumber
        );
    }

    @AuraEnabled
    webservice static Boolean getFeatureToogle() {
		Feature_Toggle__c featureToogleSetting = Feature_Toggle__c.getInstance();
        return featureToogleSetting.NewChangeOrderFlow__c;
    }
    webService static List<String> dnbiValidationForQueueAndCompanyName(Id approvalId){

        List<String> errorMessage = new List<String>();

        User[] users = [SELECT User.Id
                        FROM User
                        WHERE Id
                        IN (SELECT UserOrGroupId
                            FROM GroupMember
                            WHERE Group.Name = :TREASURY_QUEUE)];

        User runningUser = [SELECT User.Id FROM User WHERE Id = :UserInfo.getUserId()];
        String dnbiApproval = [SELECT Business_Name__c FROM D_B_Credit_Check__c WHERE Approval__c =: approvalId LIMIT 1].Business_Name__c;

        if (!users.contains(runningUser)) {
            errorMessage.add('Only users in the Billing Credit Check queue are authorized to perform this action.');

        } else {

            User dnbiUser = D_B_Credit_CheckObj.getDnbiUser();

                List<ProcessInstanceWorkitem> currentApprover = [SELECT Id, ActorId
                                                                 FROM ProcessInstanceWorkitem
                                                                 WHERE ProcessInstance.TargetObjectId = :approvalId
                                                                 LIMIT 1];

                    if (currentApprover.isEmpty()) {
                        errorMessage.add('Cannot run Credit Check. Invoice Request has no approval');
                    } else if (currentApprover[0].ActorId != dnbiUser.Id) {
                        errorMessage.add('In order to run the Credit Check, the current approver must be D&B Credit Check');
                    }
                }
        if (String.isBlank(dnbiApproval)) {
            errorMessage.add('A Company name is required in order to submit for credit approval');
        }
        return errorMessage;
    }

    public class OrderDetail{
        @AuraEnabled
        public Order order {get;set;}
        @AuraEnabled
        public boolean hasPermission {get;set;}
    }

    public class OrderDetailforDeactivate{
        @AuraEnabled
        public Order order {get;set;}
        @AuraEnabled
        public String profileName {get;set;}
    }
}