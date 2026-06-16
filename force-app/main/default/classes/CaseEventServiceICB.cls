@RestResource(UrlMapping='/rccc/nic/event/create')
global with sharing class CaseEventServiceICB {

    class CaseEventValidationException extends Exception {
        List<IcbHelper.IcbMessage> messages;

        public CaseEventValidationException(List<IcbHelper.IcbMessage> icbMessages) {
            messages = icbMessages;
        }
    }

    class CaseSuspensionException extends Exception {
        List<IcbHelper.IcbMessage> messages;

        public CaseSuspensionException(List<IcbHelper.IcbMessage> icbMessages) {
            messages = icbMessages;
        }
    }

    private static final Set<IcbHelper.ICBEventType> NON_MESSAGE_TYPE_EVENTS = new Set<IcbHelper.ICBEventType> {
        IcbHelper.ICBEventType.CHANGE_NIC_OK,
        IcbHelper.ICBEventType.CHANGE_NIC_SKIP
    };

    @HttpPost
    global static void handleEventRequest() {
        try {
            String body = RestContext.request.requestBody.toString();

            if (RestContext.response == null) {
                RestContext.response = new RestResponse();
            }

            IcbHelper.IcbEventRequest params = (IcbHelper.IcbEventRequest)
                JSON.deserialize(body, IcbHelper.IcbEventRequest.class);

            handleEvent(params);

            IcbHelper.setResponse(IcbHelper.STATUS_SUCCESS);

        } catch (CaseSuspensionException e) {
            IcbHelper.handleSuspension(e.messages);

        } catch (CaseEventValidationException e) {
            IcbHelper.handleError(e.messages);

        } catch (Exception e) {
            IcbHelper.handleError(e);
        }
    }

    private static void handleEvent(IcbHelper.IcbEventRequest params) {
        Opportunity affectedOpportunity = (Opportunity) new ListOptional(new OpportunitySelector()
            .selectOpportunityForSyncWithNGBS(params.oppId)
            .selectFields(new Set<String> {
                'Primary_Opportunity_Contact__c',
                'MasterOpportunity__r.AccountId',
                'MasterOpportunity__r.Primary_Opportunity_Contact__c',
                'MasterOpportunity__r.Order_Management_Owner__c'
            })
            .executeQuery()
        ).getFirst();

        Case affectedCase = (Case) new ListOptional(new CaseSelector()
            .selectCasesIcbByNumber(new List<String> { params.caseNumber })
            .executeQuery())
        .getFirst();

        IcbHelper.ICBEventType eventType = getEventType(params);
        List<IcbHelper.IcbMessage> errorMessages = validateRequest(eventType, affectedOpportunity, affectedCase, params);
        if (errorMessages != null) {
            throw new CaseEventValidationException(errorMessages);
        }

        if (!NON_MESSAGE_TYPE_EVENTS.contains(eventType)) {
            Opportunity oppToNotify = OpportunityHelper.getMasterOpportunity(affectedOpportunity);

            createOppChatterPost(oppToNotify, params.message, params.messageDetails);
            EmailNotificationHelper.sendEmail(params.message, params.messageDetails, affectedOpportunity, affectedCase);
        }
    }

    private static List<IcbHelper.IcbMessage> validateRequest(
        IcbHelper.ICBEventType eventType,
        Opportunity affectedOpportunity,
        Case affectedCase,
        IcbHelper.IcbEventRequest params
    ) {
        if (String.isBlank(params.oppId)) {
            return IcbHelper.createErrorList(IcbHelper.OPPORTUNITY_ID_IS_MISSING, null);
        }

        if (affectedOpportunity == null) {
            return IcbHelper.createErrorList(IcbHelper.OPPORTUNITY_NOT_FOUND, null);
        }

        Boolean isMessageType = !NON_MESSAGE_TYPE_EVENTS.contains(eventType);
        if (params.message == null && isMessageType) {
            return IcbHelper.createErrorList(
                IcbHelper.EMPTY_MESSAGE_PARAM,
                IcbHelper.EMPTY_MESSAGE_PARAM_DETAILS
            );
        }

        Opportunity oppToNotify = OpportunityHelper.getMasterOpportunity(affectedOpportunity);
        switch on eventType {
            when SIGNUP_END_OK {
                updateRCCCSyncStatus(oppToNotify, eventType);
            }
            when CHANGE_SFDC_NGBS_ERROR {
                updateRCCCSyncStatus(oppToNotify, eventType);
                NGBSSyncables.ISyncable syncable = getSyncable(affectedOpportunity);
                if (syncable.isICBProvisioningComplete()) {
                    return handleFailedSync(oppToNotify, syncable);
                }
            }
            when CHANGE_NIC_ERROR, CHANGE_INVOICE_WAITING, CHANGE_END_ERROR {
                updateRCCCSyncStatus(oppToNotify, eventType);
                handleSuspension(affectedOpportunity, oppToNotify, affectedCase, params);
            }
            when CHANGE_ICB_ACCOUNT_CREATION_ERROR,
                CHANGE_NIC_WAITING_TOO_LONG,
                CHANGE_SFDC_CASE_ERROR,
                CHANGE_ICB_ERROR,
                SIGNUP_END_ERROR,
                SIGNUP_ICB_ACCOUNT_CREATION_ERROR,
                SIGNUP_NGBS_ERROR,
                SIGNUP_NGBS_DISCOUNTS_ERROR,
                SIGNUP_NGBS_ACTIVATION_ERROR,
                SIGNUP_NGBS_LIMITS_ERROR,
                SIGNUP_SFDC_SYNC_ERROR,
                SIGNUP_NIC_ERROR
            {
                updateRCCCSyncStatus(oppToNotify, eventType);
                return handleErrorEvent(oppToNotify, params);
            }
        }

        return null;
    }

    private static void handleSuspension(
        Opportunity affectedOpportunity,
        Opportunity oppToNotify,
        Case affectedCase,
        IcbHelper.IcbEventRequest params
    ) {
        String message = params.message ?? IcbHelper.OPPORTUNITY_PROVISIONING_IS_PAUSED;
        String messageDetail = params.messageDetails ?? IcbHelper.OPPORTUNITY_PROVISIONING_IS_PAUSED_DETAILS;

        createOppChatterPostForOrderManagementOwner(oppToNotify, message, messageDetail);
        EmailNotificationHelper.sendEmail(message, messageDetail, affectedOpportunity, affectedCase);

        throw new CaseSuspensionException(
            IcbHelper.createResponseList(
                IcbHelper.STATUS_SUCCESS,
                message,
                messageDetail
            )
        );
    }

    private static List<IcbHelper.IcbMessage> handleFailedSync(Opportunity oppToNotify, NGBSSyncables.ISyncable syncable) {
        String message = IcbHelper.OPPORTUNITY_SYNC_WITH_NGBS_FAILED;
        String messageDetail = IcbHelper.OPPORTUNITY_SYNC_WITH_NGBS_FAILED_DETAILS;

        Case problemCase = CaseHelper.createCase(
            oppToNotify.AccountId,
            oppToNotify,
            messageDetail,
            IcbHelper.ICBEventType.CHANGE_SFDC_NGBS_ERROR.name(),
            true
        );

        insert problemCase;

        Id userIdToNotify = oppToNotify.Order_Management_Owner__c ?? oppToNotify.OwnerId;
        ChatterHelper.createChatterPost(
            userIdToNotify,
            oppToNotify.Id,
            problemCase.Id,
            message,
            messageDetail + ' Case was created: '
        );

        blockSyncWithNGBS(syncable);

        return IcbHelper.createErrorList(
            message,
            messageDetail
        );
    }

    private static void blockSyncWithNGBS(NGBSSyncables.ISyncable syncable) {
        syncable.setICBNotSynced();
        syncable.updateSObject();
    }

    private static NGBSSyncables.ISyncable getSyncable(Opportunity affectedOpportunity) {
        Boolean isMPUB = !affectedOpportunity.isMultiproductTechnicalOpportunity__c;
        return isMPUB ? getSyncableMPUB(affectedOpportunity) : getSyncableMPL(affectedOpportunity);
    }

    private static NGBSSyncables.ISyncable getSyncableMPUB(Opportunity affectedOpportunity) {
        Quote rcccQuote;
        List<Quote> techQuotes = (List<Quote>) new QuoteSelector()
            .selectTechQuotesByOppIdUB(affectedOpportunity.Id)
            .executeQuery();

        for (Quote qt : techQuotes) {
            if (QuoteHelper.isRCCC(qt)) {
                rcccQuote = qt;
                break;
            }
        }

        return NGBSSyncables.getSyncable(true, rcccQuote.Id, affectedOpportunity);
    }

    private static NGBSSyncables.ISyncable getSyncableMPL(Opportunity affectedOpportunity) {
        return NGBSSyncables.getSyncable(false, null, affectedOpportunity);
    }

    private static List<IcbHelper.IcbMessage> handleErrorEvent(Opportunity oppToNotify, IcbHelper.IcbEventRequest params) {
        String message = params.message ?? IcbHelper.OPPORTUNITY_SYNC_WITH_NGBS_FAILED;
        String messageDetail = params.messageDetails;

        createOppChatterPostForOrderManagementOwner(oppToNotify, message, messageDetail);
        return IcbHelper.createErrorList(
            message,
            messageDetail
        );
    }

    private static void updateRCCCSyncStatus(Opportunity oppToUpdate, IcbHelper.ICBEventType type) {
        Triggers.switchOff();
        update new Opportunity(
            Id = oppToUpdate.Id,
            RCCCSyncStatus__c = IcbHelper.CC_SYNC_STATUSES.get(type) ?? IcbHelper.DEFAULT_SYNC_ERROR
        );
        Triggers.switchOn();
    }

    @TestVisible
    private static void createOppChatterPost(Opportunity opp, String message, String messageDetail) {
        createOppChatterPost(opp.OwnerId, opp, message, messageDetail);
    }

    @TestVisible
    private static void createOppChatterPostForOrderManagementOwner(Opportunity opp, String message, String messageDetail) {
        Id userIdToNotify = opp.Order_Management_Owner__c ?? opp.OwnerId;
        createOppChatterPost(userIdToNotify, opp, message, messageDetail);
    }

    private static void createOppChatterPost(Id userIdToNotify, Opportunity opp, String message, String messageDetail) {
        ChatterHelper.createChatterPost(
            userIdToNotify,
            opp.Id,
            message,
            messageDetail
        );
    }

    private static IcbHelper.ICBEventType getEventType(IcbHelper.IcbEventRequest params) {
        try {
            return IcbHelper.ICBEventType.valueOf(params.type);
        } catch (NoSuchElementException e) {
            return null;
        }
    }
}