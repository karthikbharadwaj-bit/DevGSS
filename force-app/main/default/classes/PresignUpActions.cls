public with sharing class PresignUpActions {
    public static Account prepopulateAccountFields(POWrappers.SignUpParams data) {
        if (data == null) {
            return new Account();
        }

        Account account = new Account(Id = data.opportunity.AccountId);
        Boolean isMPUBAccount = AccountHelper.isMPUBAccount(data.opportunity.Account);

        account.Funnel_not_supported__c = getFunnelNotSupported(data, isMPUBAccount);
        setEnterpriseAccountId(account, data, isMPUBAccount);

        return account;
    }

    public static List<Approval__c> getTaxExemptsOnProcessOrder(POWrappers.SignUpParams[] dataArr) {
        Id masterAccId = getMasterAccountId(dataArr);
        Map<Id, Id> techAccIdToTechOppId = getTechAccIdToTechOppIdMap(dataArr);

        if (masterAccId == null || techAccIdToTechOppId == null) {
            return new List<Approval__c>();
        }

        return ApprovalHelper.getTaxExemptsOnProcessOrder(masterAccId, techAccIdToTechOppId);
    }

    public static void upsertFunnelStatus(Id oppId) {
        List<Quote> quotes = (List<Quote>) new QuoteSelector()
            .selectQuotesByOppIds(new Set<Id> { oppId })
            .executeQuery();
        
        upsertFunnelStatusWithQuotes(quotes, oppId);
    }

    public static void upsertFunnelStatus(Set<Id> targetIds, Id oppId) {
        List<Quote> quotes = (List<Quote>) new QuoteSelector()  
            .selectQuotesByIds(new List<Object>{targetIds})
            .executeQuery();        
        upsertFunnelStatusWithQuotesAndQuoteIds(quotes, oppId, targetIds);
    }

    public static void deleteSalesFunnelStatusRecord(Id oppId) {
        List<SalesFunnelStatus__c> salesFunnelStatuses = new SalesFunnelStatusSelector()
            .selectSalesFunnelStatusByOppIdAndSalesAgentId(oppId, UserInfo.getUserId())
            .executeQuery();
        if (!salesFunnelStatuses.isEmpty()) {
            delete salesFunnelStatuses;
        }
    }

    @TestVisible
    private static String getFunnelNotSupported(POWrappers.SignUpParams data, Boolean isMPUBAccount) {
        if (!QuoteHelper.isOffice(data.targetQuote) || data.assignmentsToManual.isEmpty() || isMPUBAccount) {
            return null;
        }
        AccountHelper.FunnelNotSupportedProductsHandler handler = new AccountHelper.FunnelNotSupportedProductsHandler(
            data.opportunity.AccountId,
            data.opportunity.Id,
            data.assignmentsToManual,
            data.targetQuote.Enabled_LBO__c
        );

        return handler.getProductsDescription();
    }

    @TestVisible
    private static void setEnterpriseAccountId(Account account, POWrappers.SignUpParams data, Boolean isMPUBAccount) {
        if ((QuoteHelper.isEngageOrInContact(data.targetQuote) || QuoteHelper.isEvents(data.targetQuote))
            && data.opportunity.Account.Internal_Enterprise_Account_ID__c == null
            && (!isMPUBAccount || !data.targetQuote.IsMultiProductTechnicalQuote__c)
        ) {
            account.Internal_Enterprise_Account_ID__c = AccountHelper.generateEnterpriseAccountId();
        }
    }

    @TestVisible
    private static Id getMasterAccountId(POWrappers.SignUpParams[] dataArr) {
        for (POWrappers.SignUpParams data : dataArr) {
            if (data.masterAcc == null && data.opportunity?.AccountId != null) {
                return data.opportunity.AccountId;
            }

            if (data.masterAcc != null) {
                return data.masterAcc.Id;
            }
        }

        return null;
    }

    @TestVisible
    private static Map<Id, Id> getTechAccIdToTechOppIdMap(POWrappers.SignUpParams[] dataArr) {
        Map<Id, Id> techAccIdToTechOppId = new Map<Id, Id>();

        for (POWrappers.SignUpParams data : dataArr) {
            if (data.masterAcc != null && data.opportunity?.AccountId != null && data.opportunity?.Id != null) {
                techAccIdToTechOppId.put(data.opportunity.AccountId, data.opportunity.Id);
            }
        }

        return techAccIdToTechOppId;
    }

    @TestVisible
    private static void upsertFunnelStatusWithQuotes(List<Quote> quotes, Id oppId) {
        List<SalesFunnelStatus__c> salesFunnelStatuses = (List<SalesFunnelStatus__c>) new SalesFunnelStatusSelector()
            .selectSalesFunnelStatusByOppIdAndSalesAgentId(oppId, UserInfo.getUserId())
            .executeQuery();
        
        List<SalesFunnelStatus__c> recordsToUpsert = getSalesFunnelStatuses(salesFunnelStatuses, quotes, oppId);
        if (!recordsToUpsert.isEmpty()) {
            upsert recordsToUpsert;
        }
    }

    @TestVisible
    private static void upsertFunnelStatusWithQuotesAndQuoteIds(List<Quote> quotes, Id oppId, Set<Id> quoteIds) {
        
        List<SalesFunnelStatus__c> salesFunnelStatuses = (List<SalesFunnelStatus__c>) new SalesFunnelStatusSelector()
            .selectSalesFunnelStatusByOppIdAndSalesAgentIdAndQuoteIds(oppId, UserInfo.getUserId(), quoteIds)
            .executeQuery();
        
        List<SalesFunnelStatus__c> recordsToUpsert = getSalesFunnelStatuses(salesFunnelStatuses, quotes, oppId);
        if (!recordsToUpsert.isEmpty()) {
            upsert recordsToUpsert;
        }
    }


    @TestVisible
    private static List<SalesFunnelStatus__c> getSalesFunnelStatuses(List<SalesFunnelStatus__c> existingSalesFunnelStatuses, List<Quote> quotes, Id oppId) {
        List<Quote> techQuotes = new List<Quote>();
        List<SalesFunnelStatus__c> recordsToUpsert = new List<SalesFunnelStatus__c>();
        Quote masterQuote;
        Boolean isExistingSalesFunnelStatusPoc = false;

        for (Quote qt: quotes) {
            if (qt.isPrimary__c && (!qt.IsMultiProductTechnicalQuote__c
                    || (!SettingsHelper.FEATURE_TOGGLE.EnableUILessProcessOrderEngage__c && QuoteHelper.isEngage(qt)))) {
                masterQuote = qt;
            }
        }

        for (Quote qt: quotes) {
            if (qt.IsMultiProductTechnicalQuote__c && qt.MasterQuote__c == masterQuote.Id) {
                techQuotes.add(qt);
            }
        }

        for (SalesFunnelStatus__c salesFunnelStatus : existingSalesFunnelStatuses) {
            if (salesFunnelStatus.Quote__r.RecordTypeId == QuoteHelper.RT_ID_POC) {
                isExistingSalesFunnelStatusPoc = true;
            }
        }

        //record only for singleproduct
        if (existingSalesFunnelStatuses.isEmpty() && masterQuote != null && techQuotes.isEmpty()) { 
            recordsToUpsert.add(new SalesFunnelStatus__c(
                IsRequestOpen__c = true,
                Opportunity__c = oppId,
                Sales_Agent__c = UserInfo.getUserId(),
                Quote__c = masterQuote.Id
            ));
        }

        //records only for multiproduct
        if (existingSalesFunnelStatuses.isEmpty() && !techQuotes.isEmpty()) {
            for (Quote techQuote: techQuotes) {
                Boolean isNeedToCreateRecord = QuoteHelper.isOffice(techQuote)
                    || QuoteHelper.isMeetings(techQuote)
                    || QuoteHelper.isEngageLegacyService(techQuote)
                    || QuoteHelper.isProServService(techQuote)
                    || QuoteHelper.isEvents(techQuote);

                if (isNeedToCreateRecord) {
                    recordsToUpsert.add(new SalesFunnelStatus__c(
                        IsRequestOpen__c = true,
                        Opportunity__c = oppId,
                        Sales_Agent__c = UserInfo.getUserId(),
                        Quote__c = techQuote.Id
                    ));
                }
            }
        }

        if (!existingSalesFunnelStatuses.isEmpty()) {
            for (SalesFunnelStatus__c salesFunnelStatus: existingSalesFunnelStatuses) {
                if (!salesFunnelStatus.IsRequestOpen__c) {
                    salesFunnelStatus.IsRequestOpen__c = true;
                    recordsToUpsert.add(salesFunnelStatus);
                }
            }
        }

        return recordsToUpsert;
    }
}