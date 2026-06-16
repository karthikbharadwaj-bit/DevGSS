@RestResource(urlMapping='/PhaseService/*')
global without sharing class PhaseService{

    @HttpPost
    global static void handleRequest() {
        String result = '';
        String body = RestContext.request.requestBody.toString();
        BillingWrappers.PhasesParams params = (BillingWrappers.PhasesParams)JSON.deserialize(body, BillingWrappers.PhasesParams.class);
        RestResponse response = RestContext.response;
        if (response == null) {
            response = new RestResponse();
            RestContext.response = response;
        }
        try {
            if (params.action == 'upsertPhases') {
                result = JSON.serialize(upsertPhases(params.phases));
            }
            if (params.action == 'deletePhases') {
                deletePhases(params.phases, params.selectedQuoteId);
            }
            if (params.action == 'getPhases') {
                result = JSON.serialize(getPhasesWihPhaseLineItems(params.selectedQuoteId));
            }
            if (params.action == 'createPhaseForChangeOrder') {
                createPhaseForChangeOrder(params.orderId, params.selectedQuoteId, params.opportunityId);
            }
            response.responseBody = Blob.valueOf(result);
        } catch(Exception e) {
            Map<String,String> errorMessage = new Map<String,String>();
            errorMessage.put('error', e.getMessage());
            errorMessage.put('stackTrace', e.getStackTraceString());
            response.responseBody = Blob.valueOf(JSON.serialize(errorMessage));
        }
    }

    @TestVisible
    private static Map<String, Phase__c> upsertPhases(List<BillingWrappers.Phase> phases) {
        Map<Integer, String> phaseNumberToUniqId = new Map<Integer, String>();
        List<Phase__c> phaseListToUpsert = new List<Phase__c>();
        Set<Id> quoteIds = new Set<Id>();

        if (phases.isEmpty()) {
            return new Map<String, Phase__c>();
        }

        for (BillingWrappers.Phase phaseWraper : phases) {
            Phase__c phase = buildPhase(phaseWraper);
            phase.Id = phaseWraper.phaseId;
            phaseListToUpsert.add(phase);
            quoteIds.add(phaseWraper.quoteId);
            phaseNumberToUniqId.put(phaseWraper.phaseNumber, phaseWraper.uniqueId);
        }

        upsert phaseListToUpsert;

        return getPhaseUniqIdToPhaseMap(phaseNumberToUniqId, quoteIds);
    }

    @TestVisible
    private static void deletePhases(List<BillingWrappers.Phase> phases, Id selectedQuoteId) {
        Set<Id> phaseIds = new Set<Id>();
        if (selectedQuoteId == null) {
            return;
        }
        for (BillingWrappers.Phase phaseWraper : phases) {
            if (phaseWraper.phaseId != null) {
                phaseIds.add(phaseWraper.phaseId);
            }
        }

        Map<Id, Phase__c> linkedPhasesToQuote =  new Map<Id, Phase__c>((List<Phase__c>)new PhaseSelector()
            .selectPhasesByQuoteIds(new List<Object>{new Set<Id> { selectedQuoteId }})
            .executeQuery());

        List<Phase__c> phasesToDelete = new List<Phase__c>();
        for (Phase__c phase : linkedPhasesToQuote.values()) {
            if (!phaseIds.contains(phase.Id)) {
                phasesToDelete.add(phase);
            }
        }

        if (!phasesToDelete.isEmpty() ) {
            delete phasesToDelete;
        }
    }

    @TestVisible
    private static List<Phase__c> getPhasesWihPhaseLineItems(Id selectedQuoteId) {
        List<Phase__c> phases = new PhaseSelector()
            .selectPhasesByQuoteIds(new List<Object>{new Set<Id> {selectedQuoteId}})
            .executeQuery();
        return phases;
    }

    private static Map<String, Phase__c> getPhaseUniqIdToPhaseMap(Map<Integer, String> phaseNumberToUniqId, Set<Id> quoteIds) {
        Map<String, Phase__c> phaseUniqIdToPhase = new Map<String, Phase__c>();
        List<Phase__c> reselectedPhases = new PhaseSelector()
            .selectPhasesByQuoteIds(new List<Object>{quoteIds})
            .executeQuery();

        if (!reselectedPhases.isEmpty()) {
            for (Phase__c phase : reselectedPhases) {

                if (phaseNumberToUniqId.containsKey((Integer) phase.Phase_Number__c)) {
                    phaseUniqIdToPhase.put(phaseNumberToUniqId.get((Integer) phase.Phase_Number__c), phase);
                }
            }
        }
        return phaseUniqIdToPhase;
    }

    private static void createPhaseForChangeOrder(Id orderId, Id quoteId, Id oppId) {
        try {
            List<Suborder__c> notBilledSuborders = (List<Suborder__c>) new SuborderSelector()
                .selectNotBilledSubordersByOrderId(orderId)
                .executeQuery();

            List<Phase__c> phasesToInsert = new List<Phase__c>();
            for (Suborder__c suborder : notBilledSuborders) {
                phasesToInsert.add(buildPhase(oppId, quoteId, suborder));
            }

            if (phasesToInsert.isEmpty()) {
                return;
            }

            insert phasesToInsert;
        } catch(Exception e) {
            AquivaHelper.throwAquivaException('Error while creating phase for change order: ' + e.getMessage());
        }
    }

    public static Phase__c buildPhase(BillingWrappers.Phase phaseWraper) {
        return buildPhase(phaseWraper.opportunityId, phaseWraper.quoteId, phaseWraper.status, phaseWraper.currencyIsoCode, phaseWraper.phaseNumber, phaseWraper.description, phaseWraper.phaseType, null);
    }

   public static Phase__c buildPhase(Id oppId, Id quoteId, Suborder__c suborder) {
       return buildPhase(
           oppId,
           quoteId,
           PhaseHelper.STATUS_NEW,
           suborder.CurrencyIsoCode,
           suborder.SuborderNumber__c,
           null,
           suborder.Suborder_Type__c,
           suborder.Id
       );
   }

    private static Phase__c buildPhase(
        Id oppId,
        Id quoteId,
        String status,
        String currencyIsoCode,
        Decimal phaseNumber,
        String description,
        String phaseType,
        String suborderId
    ) {
        Phase__c phase = new Phase__c();
        phase.Opportunity__c = oppId;
        phase.Quote__c = quoteId;
        phase.Status__c = status;
        phase.CurrencyIsoCode = currencyIsoCode;
        phase.Phase_Number__c = phaseNumber;
        phase.PhaseDescription__c = description;
        phase.Phase_Type__c = phaseType;
        phase.Suborder__c = suborderId;
        return phase;
    }
}