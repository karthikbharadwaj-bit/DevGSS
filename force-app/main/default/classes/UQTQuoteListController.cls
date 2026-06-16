public with sharing class UQTQuoteListController {
    @TestVisible
    private static final String GET_ACCOUNT_FAIL = 'Failed to load billing account';
    private static final String SWITCHED_TO_ESSENTIALS_REASON = 'Package was switched to Essentials';

    public static Boolean isContactCenterDeleted;
    public static Boolean isProServCancelled;
    public static Boolean isCCProServCancelled;
    public static Boolean isPocToPaid;

    private static final Map<String, String> QUOTE_RT_ID_TO_LABEL = new Map<String, String>{
        QuoteHelper.RT_ID_BILLING => QuoteHelper.RT_NAME_SALES,
        QuoteHelper.RT_ID_POC => QuoteHelper.RT_NAME_POC_QUOTE,
        QuoteHelper.RT_ID_CC => QuoteHelper.RT_NAME_CONTACT_CENTER,
        QuoteHelper.RT_ID_PROSERV => QuoteHelper.RT_NAME_PROSERV,
        QuoteHelper.RT_ID_CC_PROSERV => QuoteHelper.RT_NAME_CC_PROSERV
    };

    @AuraEnabled
    public static Response getBillingAccount(String accString) {
        Response result = new Response();
        Account acc = (Account) JSON.deserialize(accString, Account.Class);
        if (String.isEmpty(acc.Billing_ID__c)) {
            return result;
        }
        // Checking if account wasn't deleted in billing (for Existing Business)
        HttpResponse res;
        try {
            res = NGBSAPI.getAccountSummary(acc.Billing_ID__c);
        } catch (Exception ex) {
            Map<String, Object> exParsed = (Map<String, Object>) JSON.deserializeUntyped(ex.getMessage());
            String responseBody = (String) exParsed.get('responseBody');
            Map<String, Object> responseBodyParsed = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
            String message = (String) responseBodyParsed.get('message');
            AquivaHelper.throwAquivaException(GET_ACCOUNT_FAIL + ' (' + message + ')');
        }
        result.setData('accBillingInfo', res.getBody());
        result.setData('isPOCtoPaid', AccountHelper.isPOCtoPaid(acc));
        return result;
    }

    @AuraEnabled
    public static Response getQuotesData(String oppString, Boolean isPortalFlow) {
        Opportunity opp = (Opportunity) JSON.deserialize(oppString, Opportunity.Class);
        Response result = new Response();

        List<Quote> quotes = (List<Quote>) new QuoteSelector()
            .selectQuotesWithApprovedPOCApprovals(opp.Id, QUOTE_RT_ID_TO_LABEL.keySet())
            .executeQuery();

        // Creating map with pre-defined Record Type label and quotes
        Map<String, List<Quote>> recordTypeNameToQuotesMap = new Map<String, List<Quote>>{
            QuoteHelper.RT_NAME_SALES => new List<Quote>(),
            QuoteHelper.RT_NAME_POC_QUOTE => new List<Quote>(),
            QuoteHelper.RT_NAME_PROSERV => new List<Quote>(),
            QuoteHelper.RT_NAME_CC_PROSERV => new List<Quote>()
        };
        for (Quote qt : quotes) {
            if (!recordTypeNameToQuotesMap.containsKey(QUOTE_RT_ID_TO_LABEL.get(qt.recordTypeId))) {
                recordTypeNameToQuotesMap.put(QUOTE_RT_ID_TO_LABEL.get(qt.recordTypeId), new List<Quote>());
            }
            recordTypeNameToQuotesMap.get(QUOTE_RT_ID_TO_LABEL.get(qt.recordTypeId)).add(qt);
        }

        Boolean isPOCQuotesAvailable = isPOCQuotesAvailable(opp, recordTypeNameToQuotesMap, isPortalFlow);

        if (!isPOCQuotesAvailable) {
            recordTypeNameToQuotesMap.remove(QuoteHelper.RT_NAME_POC_QUOTE);
        }

        Boolean isProServOnly = SettingsService.onlyProServQuotesAvailable(opp);

        result.setData('recordTypeNameToQuotesMap', recordTypeNameToQuotesMap);
        result.setData('isProServOnly', isProServOnly);
        return result;
    }

    @AuraEnabled
    public static Response cloneQuote(Id quoteId, Id masterQuoteId) {
        Response result = new Response();

        result.setData('clonedQuote', CloneHelper.cloneQuote(quoteId, masterQuoteId));

        return result;
    }

    @AuraEnabled
    public static Response makeQuotePrimary(Id quoteId, String oppString, String recordType, Map<String, List<Quote>> recordTypeNameToQuotesMap) {
        Response result = new Response();

        Opportunity opp = (Opportunity) JSON.deserialize(oppString, Opportunity.Class);

        List<Quote> quoteList = (List<Quote>) new QuoteSelector()
            .selectQuotesForPrimaryProcess(opp.Id, quoteId)
            .executeQuery();

        List<Quote> quoteListToUpdate = QuoteHelper.makePrimaryQuote(opp, quoteId, quoteList);
        recordTypeNameToQuotesMap.put(recordType, quoteListToUpdate);

        result.setData('recordTypeNameToQuotesMap', recordTypeNameToQuotesMap);

        return result;
    }

    @AuraEnabled
    public static Response recalculateApprovals(Id quoteId, String recordType, Map<String, List<Quote>> recordTypeNameToQuotesMap){
        Response result = new Response();

        Set<Id> quoteIds = new Set<Id>{quoteId};
        List<Quote> quotesToUpdate = QuoteApprovals.handleQuotes(quoteIds, new Set<Id>(), null);

        Triggers.switchOff();
            update quotesToUpdate;
        Triggers.switchOn();

        recordTypeNameToQuotesMap.put(recordType, quotesToUpdate);

        result.setData('recordTypeNameToQuotesMap', recordTypeNameToQuotesMap);

        return result;
    }

    @AuraEnabled
    public static Response deleteCCAndCancelProServsIfRequired (String recordType, Map<String, List<Quote>> recordTypeNameToQuotesMap) {
        Response result = new Response();

        if (recordType != QuoteHelper.RT_NAME_SALES) {
            result.setData('recordTypeNameToQuotesMap', recordTypeNameToQuotesMap);
            return result;
        }

        Quote newPrimaryQuote;
        for (Quote qt: recordTypeNameToQuotesMap.get(QuoteHelper.RT_NAME_SALES)) {
            if (qt.isPrimary__c == true) {
                newPrimaryQuote = qt;
            }
        }
        recordTypeNameToQuotesMap = deleteCCQuoteProcess(recordTypeNameToQuotesMap);
        recordTypeNameToQuotesMap = cancelProServProcess(newPrimaryQuote, recordTypeNameToQuotesMap);

        result = setContactCenterDeletedAndProServsStatuses(result);
        result.setData('recordTypeNameToQuotesMap', recordTypeNameToQuotesMap);

        return result;
    }

    private static Map<String, List<Quote>> deleteCCQuoteProcess (Map<String, List<Quote>> recordTypeNameToQuotesMap) {
        if (recordTypeNameToQuotesMap.get(QuoteHelper.RT_NAME_CONTACT_CENTER) != null
            && !recordTypeNameToQuotesMap.get(QuoteHelper.RT_NAME_CONTACT_CENTER).isEmpty()) {
            Quote ccQuote = recordTypeNameToQuotesMap.get(QuoteHelper.RT_NAME_CONTACT_CENTER)[0];
            delete ccQuote;
            recordTypeNameToQuotesMap.remove(QuoteHelper.RT_NAME_CONTACT_CENTER);
            isContactCenterDeleted = true;
        }
        return recordTypeNameToQuotesMap;
    }

    private static Map<String, List<Quote>> cancelProServProcess(Quote quote, Map<String, List<Quote>> recordTypeNameToQuotesMap) {
        Boolean isNeedToCancelProservQuote = isProServQuoteNeedsCancel(QuoteHelper.RT_NAME_PROSERV, recordTypeNameToQuotesMap);
        Boolean isNeedToCancelCCProservQuote = isProServQuoteNeedsCancel(QuoteHelper.RT_NAME_CC_PROSERV, recordTypeNameToQuotesMap);

        // Cancelling ProServ
        if (isNeedToCancelProservQuote && isPackageEditionEssentials(quote)) {
            cancelProServ(quote.OpportunityId, QuotingToolQuoteApexController.PROSERV);
            recordTypeNameToQuotesMap.get(QuoteHelper.RT_NAME_PROSERV)[0].ProServ_Status__c = QuoteHelper.PROSERVSTATUS_CANCELLED;
            isProServCancelled = true;
        }
        // Cancelling Contact Center ProServ
        if (isNeedToCancelCCProservQuote) {
            cancelProServ(quote.OpportunityId, QuotingToolQuoteApexController.CC_PROSERV);
            recordTypeNameToQuotesMap.get(QuoteHelper.RT_NAME_CC_PROSERV)[0].ProServ_Status__c = QuoteHelper.PROSERVSTATUS_CANCELLED;
            isCCProServCancelled = true;
        }

        return recordTypeNameToQuotesMap;
    }

    private static void cancelProServ(Id opportunityId, String proServType) {
        QuotingToolQuoteApexController.removeProServProds(opportunityId, proServType, true, false, true);
        QuotingToolQuoteApexController.removeProServProds(opportunityId, proServType, false, true, true);
        QuotingToolQuoteApexController.cancelProServ(
            opportunityId,
            SWITCHED_TO_ESSENTIALS_REASON,
            proServType,
            true
        );
    }

    private static Response setContactCenterDeletedAndProServsStatuses(Response result) {
        result.setData('isContactCenterDeleted', isContactCenterDeleted);
        result.setData('isProServCancelled', isProServCancelled);
        result.setData('isCCProServCancelled', isCCProServCancelled);
        return result;
    }

    private static Boolean isPackageEditionEssentials(Quote quote) {
        BillingWrappers.QuotePackageInfo pInfo = QuoteHelper.getPackageInfo(quote);
        return pInfo?.Edition?.name == QuoteHelper.PACKAGE_EDITION_ESSENTIALS;
    }

    private static Boolean isProServQuoteNeedsCancel (String recordTypeName, Map<String, List<Quote>> recordTypeNameToQuotesMap) {
        return recordTypeNameToQuotesMap.get(recordTypeName) != null && !recordTypeNameToQuotesMap.get(recordTypeName).isEmpty()
            && recordTypeNameToQuotesMap.get(recordTypeName)[0].ProServ_Status__c != QuoteHelper.PROSERVSTATUS_CANCELLED;
    }

    private static Boolean isPOCQuotesAvailable(Opportunity opp, Map<String, List<Quote>> recordTypeNameToQuotesMap, Boolean isPortalFlow) {
        Set<String> oppTiersWithoutPOC = new Set<String>{
            OpportunityHelper.TIER_MEETINGS,
            OpportunityHelper.TIER_FAX,
            OpportunityHelper.TIER_RC_MEETINGS,
            OpportunityHelper.TIER_RC_CONTACT_CENTER,
            OpportunityHelper.TIER_RC_CONTACT_CENTER_LEGACY,
            OpportunityHelper.TIER_ENGAGE_VOICE_LEGACY,
            OpportunityHelper.TIER_ENGAGE_DIGITAL_STANDALONE,
            OpportunityHelper.TIER_ENGAGE_DIGITAL_LEGACY,
            OpportunityHelper.TIER_ENGAGE_UNIFIED,
            OpportunityHelper.TIER_ENGAGE_OMNICHANNEL
        };
        SettingsService.GSPPartnerSetup gspPartner = new SettingsService.GSPPartnerSetup(opp);

        Boolean isNewBusiness = String.isEmpty(opp.Account?.Billing_ID__c);
        List<Quote> pocQuotesList = recordTypeNameToQuotesMap.get(QuoteHelper.RT_NAME_POC_QUOTE);
        Boolean isPOCtoPaidWithPOCQuotes = AccountHelper.isPOCtoPaid(opp.Account)
            && pocQuotesList != null
            && pocQuotesList.size() > 0;

        Feature_Toggle__c featureToggle = Feature_Toggle__c.getInstance();
        List<Package__c> existingPackages = (List<Package__c>) new PackageSelector()
            .selectPackagesByAccountIdForPOC(opp.AccountId)
            .executeQuery();

        Boolean isEDorRCXPaid = false;
        Boolean isOfficePaid = false;
        for(Package__c existingPkg : existingPackages) {
            if(existingPkg.Service_Type__c ==  Constants.CONST_OFFICE){
                isOfficePaid = true;
            }
            if(existingPkg.Service_Type__c == Constants.CONST_ENGAGE_VOICE || existingPkg.Service_Type__c == Constants.CONST_ENGAGE_DIGITAL){
                isEDorRCXPaid = true;
            }
        }

        return (isNewBusiness || isPOCtoPaidWithPOCQuotes || (isOfficePaid && !isEDorRCXPaid))
            && featureToggle.IsPOCQuoteCreationAllowed__c
            && !isPortalFlow
            && !gspPartner.isDisablePOC
            && !OpportunityHelper.isIndia(opp)
            && !OpportunityHelper.isAmazon(opp)
            && !oppTiersWithoutPOC.contains(opp.Tier_Name__c)
            && !OpportunityHelper.isRiseBrand(opp);
    }

    @AuraEnabled
    public static Response checkAccountBillingCountry(String oppString){
        Feature_Toggle__c featureToggle = Feature_Toggle__c.getInstance();
        Response resp = new Response();
        String profileName = ProfileHelper.getCurrentUserProfile().Name;
        Opportunity opp = (Opportunity) JSON.deserialize(oppString, Opportunity.Class);

        if (String.isBlank(oppString)
            || opp.Account.Billing_ID__c != null
            || !featureToggle.EnableBusinessIdentityMapping__c
            || ProfileHelper.EXCLUSION_PROFILES.contains(profileName)
        ) {
            return resp;
        }

        List<Default_Business_Identity_Mapping__mdt> defaultBIMap = new SettingsService.NoSharing().getDefaultBusinessIdentityMapping();
        String country = '';
        Boolean isWrongAccountBillingCountry = false;
        String oppBI = OpportunityHelper.getOpportunityBIName(opp);

        for (Default_Business_Identity_Mapping__mdt record : defaultBIMap) {
            List<String> availableBIList = String.isNotBlank(record.Available_Business_Identities__c)
                ? record.Available_Business_Identities__c.split(';')
                : new List<String>();
            if (String.isNotBlank(opp.Sub_Brand__c) && String.isNotBlank(record.Sub_Brand__c)
                && record.Sub_Brand__c == opp.Sub_Brand__c
                && record.Brand__c == opp.Brand_Name__c
                && (oppBI == record.Default_Business_Identity__c || availableBIList.contains(oppBI))
            ) {
                country = record.Country__c;
                break;
            }
        }
        isWrongAccountBillingCountry = opp.Account.BillingCountry != country;

        if (String.isBlank(country)) {
            for (Default_Business_Identity_Mapping__mdt record : defaultBIMap) {
                List<String> availableBIList = String.isNotBlank(record.Available_Business_Identities__c)
                    ? record.Available_Business_Identities__c.split(';')
                    : new List<String>();
                if (record.Country__c == opp.Account.BillingCountry && record.Brand__c == opp.Brand_Name__c && String.isBlank(record.Sub_Brand__c)) {
                    isWrongAccountBillingCountry = oppBI != record.Default_Business_Identity__c && !availableBIList.contains(oppBI);
                    break;
                }
            }
        }

        resp.setData('isWrongAccountBillingCountry', isWrongAccountBillingCountry);
        return resp;
    }

    @AuraEnabled
    public static Response dropQuote(Id quoteId) {
        return new NoSharing().dropQuote(quoteId);
    }

    public without sharing class NoSharing {
        public Response dropQuote(Id quoteId) {
            Response result = new Response();
            List<Quote> qtList = (List<Quote>) new QuoteSelector()
                .selectQuoteById(new List<Object> { quoteId })
                .executeQuery();

            if (qtList.size() == 0) {
                return result;
            }

            Quote qt = qtList.get(0);


            delete qt;

            result.setData('quoteId', String.valueOf(qt.Id));

            return result;
        }
    }

}