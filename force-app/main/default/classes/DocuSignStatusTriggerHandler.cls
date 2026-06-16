public abstract with sharing class DocuSignStatusTriggerHandler extends Triggers.TriggerHandlerBase {
    public static final String CONTRACT_STATUS_TERMINATED = 'Terminated';
    private static final String CONTRACT_STATUS_AMENDED_AND_CLOSED = 'Amended and Closed';
    private static final String APPROVAL_STATUS_COMPLETED = 'Completed';
    private static final String APPROVAL_RT_NAME_ENGAGE_LEGAL = 'Engage Legal';
    public static final String STATUS_Docusign_Completed = 'Docusign Completed';
    public static final String CONTRACT_VERSION_STATUS_STATUS_ACTIVE = 'Active';
    public static final String CONTRACT_VERSION_STATUS_AMENDED_AND_CLOSED = 'Amended and Closed';
    public static Boolean byPassSetApprovalType = false;

    // To change statuses one to one on related quote use this mapping
    // Just add statuses here
    private static final Map<String, String> STATUS_MAPPING_DOCUSIGN_TO_QUOTE = new Map<String, String>{
        DocuSignHelper.ENVELOPE_STATUS_SENT => QuoteTriggerHelper.STATUS_PRESENTED
    };

    private static final Map<String, String> EXCEPTION_TRANSFORM = new Map<String, String>{
        Label.DocuSign_ExceptionQuoteType_ErrorMessageStandard => Label.DocuSign_ExceptionQuoteType_ErrorMessageReplacer
    };

    public List<dsfs__DocuSign_Status__c> recordsToProcess = new List<dsfs__DocuSign_Status__c>();
    private static Map<Id, Quote> statusIdToQuoteMap = new Map<Id, Quote>();

    protected abstract Set<String> getHandlingStatuses();

    public DocuSignStatusTriggerHandler(List<sObject> recList) {
        super(recList);
        for (dsfs__DocuSign_Status__c appr : (List<dsfs__DocuSign_Status__c>) triggerRecords) {
            if (this.getHandlingStatuses().contains(appr.dsfs__Envelope_Status__c)) {
                recordsToProcess.add(appr);
            }
        }
    }

    public DocuSignStatusTriggerHandler() {
        this(Trigger.isDelete ? Trigger.old : Trigger.new);
    }

    private static void buildStatusIdToNonActiveQuoteMap() {
        buildStatusIdToNonActiveQuoteMap(Trigger.new);
    }

    private static void buildStatusIdToNonActiveQuoteMap(List<dsfs__DocuSign_Status__c> statuses) {

        Map<Id, Id> quoteIdToStatusId = new Map<Id, Id>();
        Map<Id, Id> opptyIdToStatusId = new Map<Id, Id>();
        for (dsfs__DocuSign_Status__c s : statuses) {
            if (String.isNotBlank(s.dfsq__Quote__c)) {
                quoteIdToStatusId.put(s.dfsq__Quote__c, s.Id);
            }
            else if (String.isNotBlank(s.dsfs__Opportunity__c)) {
                opptyIdToStatusId.put(s.dsfs__Opportunity__c, s.Id);
            }
        }

        if (statusIdToQuoteMap.isEmpty()) {

            if (!quoteIdToStatusId.isEmpty()) {
                for (Quote q : [
                    SELECT Id, RecordType.Name, AccountId, Initial_Term_months__c, Term_months__c, Auto_Renewal__c, Status,
                        Start_Date__c, End_Date__c, QuoteType__c, Upsell_Status__c, Opp_Type__c,
                        (SELECT Opportunity.Tier_Name__c FROM Master_Quotes__r WHERE Opp_Type__c = :OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS)
                    FROM Quote
                    WHERE Id IN :quoteIdToStatusId.keySet()
                ]) {
                    statusIdToQuoteMap.put(quoteIdToStatusId.get(q.Id), q);
                }
            }

            if (!opptyIdToStatusId.isEmpty()) {
                for (Opportunity opp : [
                    SELECT Id, Is_Billing_Opportunity__c, (
                        SELECT Id, RecordType.Name, AccountId, Initial_Term_months__c, Term_months__c, Auto_Renewal__c, Start_Date__c, End_Date__c, QuoteType__c,
                            Upsell_Status__c
                        FROM Quotes
                        WHERE isPrimary__c = TRUE
                        AND Status != 'Active'
                    )
                    FROM Opportunity
                    WHERE Id IN :opptyIdToStatusId.keySet()
                ]) {
                    String rtName = opp.Is_Billing_Opportunity__c
                        ? QuoteHelper.RT_NAME_BILLING
                        : QuoteHelper.RT_NAME_SALES;
                    for (Quote qt : opp.Quotes) {
                        if (qt.RecordType.Name.equalsIgnoreCase(rtName)) {
                            statusIdToQuoteMap.put(opptyIdToStatusId.get(opp.Id), qt);
                            break;
                        }
                    }
                }
            }
        }

    }

    private static Map<Id, Map<String, Quote>> buildOldTechnicalQuotes(List<Account> accounts) {
        Map<Id, Map<String, Quote>> oldQuoteIdToTechQuotes = new Map<Id, Map<String, Quote>>();

        for (Account acc : accounts) {
            if (!acc.Quotes__r.isEmpty()) {
                oldQuoteIdToTechQuotes.put(acc.Quotes__r[0].Id, new Map<String, Quote>());
            }
        }

        if (!oldQuoteIdToTechQuotes.isEmpty()) {
            List<Quote> techQuotes = [SELECT Initial_Term_months__c, Term_months__c, Start_Date__c, End_Date__c,
                                            Auto_Renewal__c, Opportunity.Tier_Name__c, AccountId, Opp_Type__c, MasterQuote__c
                                        FROM Quote WHERE MasterQuote__c IN :oldQuoteIdToTechQuotes.keySet()];

            for (Quote techQuote : techQuotes) {
                oldQuoteIdToTechQuotes.get(techQuote.MasterQuote__c).put(techQuote.Opportunity.Tier_Name__c, techQuote);
            }
        }

        return oldQuoteIdToTechQuotes;
    }

    public class SetOldAgreementExecuted extends DocuSignStatusTriggerHandler {

        public SetOldAgreementExecuted() {
            super();
        }
        protected override Set<String> getHandlingStatuses() {
            return new Set<String>{
                DocuSignHelper.ENVELOPE_STATUS_COMPLETED
            };
        }

        override public void handle() {
            Map<Id, Account> accounts = getRelatedAccounts();
            Map<Id, Quote> quoteMap = new Map<Id, Quote>();
            Set<Id> activeQuotesIdSet = new Set<Id>();
            buildStatusIdToNonActiveQuoteMap();
            Map<Id, Map<String, Quote>> oldQuoteIdToTechnicalQuotes = buildOldTechnicalQuotes(accounts.values());
            for (dsfs__DocuSign_Status__c status : recordsToProcess) {
                try {
                    Account acc = accounts.get(status.dsfs__Company__c);
                    if (status.dfsq__Quote__c != null) {
                        Quote nextQuote = statusIdToQuoteMap.get(status.Id);

                        if (acc != null && nextQuote != null && !nextQuote.RecordType.Name.equalsIgnoreCase(QuoteHelper.RT_NAME_POC_QUOTE)) {
                            List<Quote> listChilds = getListChildQuotes(nextQuote.Id);
                            Quote activeOldQuote = !acc.Quotes__r.isEmpty() ? acc.Quotes__r[0] : null;

                            if (activeOldQuote != null && activeOldQuote.Id != nextQuote.Id) {
                                activeOldQuote.Status = QuoteTriggerHelper.STATUS_EXECUTED;
                                quoteMap.put(activeOldQuote.Id, activeOldQuote);

                                acc.Active_Sales_Agreement__c = null;
                                accounts.put(acc.Id, acc);

                                nextQuote.Previous_Sales_Agreement__c = activeOldQuote.Id;
                                if (nextQuote.Initial_Term_months__c == null) {
                                    nextQuote.Initial_Term_months__c = activeOldQuote.Initial_Term_months__c;
                                    nextQuote.End_Date__c = activeOldQuote.End_Date__c;
                                }
                                nextQuote.Term_months__c = activeOldQuote.Term_months__c != nextQuote.Term_months__c && nextQuote.Term_months__c != null
                                    ? nextQuote.Term_months__c
                                    : activeOldQuote.Term_months__c;
                                nextQuote.Auto_Renewal__c = activeOldQuote.Auto_Renewal__c != nextQuote.Auto_Renewal__c
                                    ? nextQuote.Auto_Renewal__c
                                    : activeOldQuote.Auto_Renewal__c;
                                nextQuote.Start_Date__c = activeOldQuote.Start_Date__c;
                                if (QuoteHelper.isMultiProductEBMasterQuote(nextQuote)) {
                                    for (Quote oldTechQuote : oldQuoteIdToTechnicalQuotes.get(activeOldQuote.Id).values()) {
                                        if (oldTechQuote.Opp_Type__c == OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS) {
                                            oldTechQuote.Status = activeOldQuote.Status;
                                            quoteMap.put(oldTechQuote.Id, oldTechQuote);
                                            if (!accounts.containsKey(oldTechQuote.AccountId)) {
                                                accounts.put(oldTechQuote.AccountId, new Account(Id = oldTechQuote.AccountId, Active_Sales_Agreement__c = null));
                                            }
                                        }
                                    }

                                    for (Quote nextTechQuote : nextQuote.Master_Quotes__r) {
                                        Quote oldTechQuote = oldQuoteIdToTechnicalQuotes.get(activeOldQuote.Id).get(nextTechQuote.Opportunity.Tier_Name__c);
                                        nextTechQuote.Status = nextQuote.Status;
                                        nextTechQuote.Start_Date__c = oldTechQuote.Start_Date__c;
                                        nextTechQuote.End_Date__c = oldTechQuote.End_Date__c;
                                        nextTechQuote.Auto_Renewal__c = oldTechQuote.Auto_Renewal__c;
                                        nextTechQuote.Previous_Sales_Agreement__c = oldTechQuote.Id;
                                        quoteMap.put(nextTechQuote.Id, nextTechQuote);
                                    }
                                    if (status.dsfs__Envelope_Status__c == DocuSignHelper.ENVELOPE_STATUS_COMPLETED) {
                                        nextQuote.Status = QuoteTriggerHelper.STATUS_ACTIVE;
                                        for (Quote nextTechQuote : nextQuote.Master_Quotes__r) {
                                            Quote techQuote = quoteMap.get(nextTechQuote.Id);

                                            if (techQuote == null) {
                                                quoteMap.put(nextTechQuote.Id, nextTechQuote);
                                            } else {
                                                techQuote.Status = nextQuote.Status;
                                            }
                                            
                                        }
                                        quoteMap.put(nextQuote.Id, nextQuote);
                                    }
                                }

                                byPassSetApprovalType = true;
                            } else {
                                nextQuote.Status = QuoteTriggerHelper.STATUS_ACTIVE;
                                for (Quote q : listChilds) {
                                    q.Status = QuoteTriggerHelper.STATUS_ACTIVE;
                                    nextQuote.Status = QuoteTriggerHelper.STATUS_ACTIVE;
                                    q.Initial_Term_months__c = nextQuote.Initial_Term_months__c;
                                    q.Term_months__c = nextQuote.Term_months__c;
                                    q.Auto_Renewal__c = nextQuote.Auto_Renewal__c;
                                    q.End_Date__c = nextQuote.End_Date__c;
                                    q.Start_Date__c = nextQuote.Start_Date__c;
                                    quoteMap.put(q.Id, q);
                                }

                                if (QuoteHelper.isMultiProductEBMasterQuote(nextQuote)) {
                                    for (Quote nextTechQuote : nextQuote.Master_Quotes__r) {
                                        nextTechQuote.Status = nextQuote.Status;
                                        quoteMap.put(nextTechQuote.Id, nextTechQuote);
                                    }
                                }
                            }
                        }

                        quoteMap.put(nextQuote.Id, nextQuote);
                    }
                } catch (Exception ex) {
                    System.debug(ex.getMessage());
                    PlatformLog.logException(DocuSignStatusTriggerHandler.class.getName(), ex);
                }
            }

            if (!accounts.isEmpty()) {
                try {
                    update accounts.values();
                } catch (Exception ex) {
                    System.debug(ex.getMessage());
                    PlatformLog.logException(DocuSignStatusTriggerHandler.class.getName(), ex);
                }
            }
            if (!quoteMap.values().isEmpty()) {
                try {
                    update quoteMap.values();
                } catch (Exception ex) {
                    System.debug(ex.getMessage());
                    PlatformLog.logException(DocuSignStatusTriggerHandler.class.getName(), ex);
                }
            }
        }

        private Map<Id, Account> getRelatedAccounts() {
            Set<Id> accountIds = new Set<Id>();
            for (dsfs__DocuSign_Status__c status : recordsToProcess) {
                accountIds.add(status.dsfs__Company__c);
            }
            return new Map<Id, Account>([
                SELECT Id, Name,
                    (SELECT Id, AccountId, Initial_Term_months__c, Term_months__c, Auto_Renewal__c, Start_Date__c, End_Date__c
                        FROM Quotes__r
                        WHERE Status = :QuoteTriggerHelper.STATUS_ACTIVE AND IsMultiProductTechnicalQuote__c = false
                        LIMIT 1)
                FROM Account
                WHERE Id IN :accountIds
            ]);
        }
    }

    public class DocuSign_ChangeQuoteStatusAccordingly extends DocuSignStatusTriggerHandler {
        protected override Set<String> getHandlingStatuses() {
            return STATUS_MAPPING_DOCUSIGN_TO_QUOTE.keySet();
        }

        override public void handle() {
            Map<Id, Quote> quoteMap = new Map<Id, Quote>();
            for (dsfs__DocuSign_Status__c rec : recordsToProcess) {
                try {
                    if (rec.dfsq__Quote__c != null) {
                        Quote qt = statusIdToQuoteMap.get(rec.Id);
                        if (qt != null) {
                            List<Quote> listChilds = getListChildQuotes(qt.Id);
                            qt.Status = STATUS_MAPPING_DOCUSIGN_TO_QUOTE.get(rec.dsfs__Envelope_Status__c);
                            quoteMap.put(qt.Id, qt);
                            for (Quote q : listChilds) {
                                q.Status = STATUS_MAPPING_DOCUSIGN_TO_QUOTE.get(rec.dsfs__Envelope_Status__c);
                                quoteMap.put(q.Id, q);
                            }

                            if (QuoteHelper.isMultiProductEBMasterQuote(qt)) {
                                for (Quote techQuote : qt.Master_Quotes__r) {
                                    techQuote.Status = qt.Status;
                                    quoteMap.put(techQuote.Id, techQuote);
                                }
                            }
                        }
                    }
                } catch (Exception ex) {
                    System.debug(ex.getMessage());
                    PlatformLog.logException(DocuSignStatusTriggerHandler.class.getName(), ex);
                }
            }

            if (!quoteMap.values().isEmpty()) {
                try {
                    update quoteMap.values();
                } catch (Exception ex) {
                    System.debug(ex.getMessage());
                    PlatformLog.logException(DocuSignStatusTriggerHandler.class.getName(), ex);
                }
            }
        }

        public DocuSign_ChangeQuoteStatusAccordingly() {
            super();
        }
    }

    @future
    private static void updateObjects(String objects) {
        try {
            List<Approval__c> appToUpdateList = (List<Approval__c>) JSON.deserialize(objects, List<Approval__c>.class);

            if (!appToUpdateList.isEmpty()) {
                update appToUpdateList;
            }
        } catch (Exception ex) {
            System.debug(ex.getMessage());
            PlatformLog.logException(DocuSignStatusTriggerHandler.class.getName(), ex);
        }
    }

    //This class will process DocuSign status records, which status was changed to the "Completed"
    //It will create an active contract under related account and process approvals
    //All logic related to the attachments processing see in: AttachmentTriggerHelper class
    public class DocuSign_ChangeEnvelopeStatus extends Triggers.TriggerHandlerBase {
        override public void handle() {

            dsfs__DocuSign_Status__c[] completedStatusesRecords = getCompletedStatuses((List<dsfs__DocuSign_Status__c>) Trigger.new);
            system.debug('completedStatusesRecords :' + completedStatusesRecords);
            system.debug('completedStatusesRecords.size() :' + completedStatusesRecords.size());
            if (completedStatusesRecords.size() == 0) {
                return;
            }

            Set<Id> accountIdSet = new Set<Id>();
            Map<Id, dsfs__DocuSign_Status__c> accountIdToDocuSignMap = new Map<Id, dsfs__DocuSign_Status__c>();
            Set<Id> opportunityIdSet = new Set<Id>();
            Set<Id> parentQuoteIdSet = new Set<Id>();
           
            for (dsfs__DocuSign_Status__c docuSignObj : completedStatusesRecords) {

                if (docuSignObj.dfsq__Quote__c != null) {
                    accountIdSet.add(docuSignObj.dsfs__Company__c);
                    accountIdToDocuSignMap.put(docuSignObj.dsfs__Company__c, docuSignObj);
                    opportunityIdSet.add(docuSignObj.dsfs__Opportunity__c);
                    parentQuoteIdSet.add(docuSignObj.dfsq__Quote__c);
                }
            }

            Boolean isNewContractTermFlow = Feature_Toggle__c.getInstance().Enable_new_Contract_Term_flow__c;

            if (!accountIdSet.isEmpty()) {
                Map<Id, Account> childAccountMap = new Map<Id, Account>();
                childAccountMap = getChildAccounts(accountIdSet);
                accountIdSet.addAll(childAccountMap.keySet());

                /* Populate opportunity id set with values from child quotes opportunities */
                for (Account childAcc : childAccountMap.values()) {
                    for (Quote qt : childAcc.Quotes__r) {
                        /* Need to use only quotes/Opportunitites which have parents from list */
                        if (parentQuoteIdSet.contains(qt.ParentQuote__c)) {
                            opportunityIdSet.add(qt.OpportunityId);
                        }
                    }
                }

                /* Replenish map with (acc -> docusign) for child accounts */
                for (Account childAcc : childAccountMap.values()) {
                    /* Child Account should refer to the same docusign record as Master account */
                    dsfs__DocuSign_Status__c statusFromParent = accountIdToDocuSignMap.get(childAcc.Master_Account__c);
                    accountIdToDocuSignMap.put(childAcc.Id, statusFromParent);
                }

                if (accountIdSet.isEmpty()) {
                    return;
                }

                Map<Id, Account> accountMap = getAccountsWithContracts(accountIdSet);
                Map<Id, Contract> accountIdToContractMap = new Map<Id, Contract>();
                if (Feature_Toggle__c.getInstance().Enable_new_Contract_Term_flow__c) {
                    List<Contract> contractList = getContracts(accountMap.keySet());
                    accountIdToContractMap = processNewContractTermFlow(completedStatusesRecords, contractList, accountMap);
                } else {
                    accountIdToContractMap = processContracts(accountMap, childAccountMap, accountIdToDocuSignMap);
                }

                updateApprovals(opportunityIdSet, accountIdToContractMap, accountIdToDocuSignMap);

            }

        }

        private Map<Id, Contract> processContracts(
            Map<Id, Account> accountMap,
            Map<Id, Account> childAccountMap,
            Map<Id, dsfs__DocuSign_Status__c> accountIdToDocuSignMap
        ) {
            List<Contract> contractsToInsert = new List<Contract>();
            Map<Id, Contract> accountIdToContractMap = new Map<Id, Contract>();

            for (Account acc : accountMap.values()) {

                if (acc.Contracts.isEmpty()) {
                    contractsToInsert.add(buildContract(acc.Id));
                } else {
                    /* Account Id to Last Active Contract */
                    accountIdToContractMap.put(acc.Id, acc.Contracts[0]);
                }
            }
            insert contractsToInsert;

            /* Replenish map with newly created contracts*/
            for (Contract cc : contractsToInsert) {
                /* Account Id to Last Active Contract */
                accountIdToContractMap.put(cc.AccountId, cc);
            }

            populateParentContractAndActivateContract(contractsToInsert, childAccountMap, accountIdToContractMap);

            return accountIdToContractMap;
        }

        // TODO Rewrite after merge
        private Map<Id, Contract> processNewContractTermFlow(
            List<dsfs__DocuSign_Status__c> completedStatusesRecords,
            List<Contract> contractList,
            Map<Id, Account> accountMap
        ) {

            Set<Id> quoteIdSet = new Set<Id>();

            for (dsfs__DocuSign_Status__c docuSignObj : completedStatusesRecords) {
                if (docuSignObj.dfsq__Quote__c != null) {
                    quoteIdSet.add(docuSignObj.dfsq__Quote__c);
                }
            }

            if (quoteIdSet.isEmpty()) {
                return new Map<Id, Contract>();
            }

            Map<Id, Quote> accountIdToQuoteMap = buildAccountIdToQuoteMap(accountMap.values(), quoteIdSet);

            Map<Id, List<Contract>> accountIdToContractListMap = buildAccountIdToContractListMap(contractList);
            Map<Id, Contract> accountIdToLatestContractMap = buildAccountIdToLatestContractMap(accountIdToContractListMap);

            List<Contract> contractsToInsert = new List<Contract>();
            List<Contract> contractsToUpdate = new List<Contract>();
            Map<Id, ContractVersion__c> accountIdToContractVersionMap = new Map<Id, ContractVersion__c>();

            List<ContractVersion__c> versionsToUpdate = new List<ContractVersion__c>();

            for (Account acc : accountMap.values()) {

                if (!acc.Contracts.isEmpty() && acc.Master_Account__c != null) {
                    continue;
                }

                Quote activeAgreement = accountIdToQuoteMap.get(acc.Id);
                Contract previousContract = accountIdToLatestContractMap.get(acc.Id);

                ContractHandleResult result = buildContractAndVersions(
                    activeAgreement,
                    acc,
                    previousContract
                );

                if (result.contractToUpdate != null) {
                    contractsToUpdate.add(result.contractToUpdate);
                }

                if (result.versionToUpdate != null) {
                    versionsToUpdate.add(result.versionToUpdate);
                }

                if (result.contractToInsert != null) {
                    contractsToInsert.add(result.contractToInsert);
                }

                if (result.accountIdToContractVersionMap != null && !result.accountIdToContractVersionMap.isEmpty()) {
                    accountIdToContractVersionMap.putAll(result.accountIdToContractVersionMap);
                }

            }

            update contractsToUpdate;

            update versionsToUpdate;

            insertContracts(contractsToInsert);

            insertContractVersions(accountIdToContractVersionMap, contractsToInsert);

            Map<Id, Contract> accountIdToContractMap = new Map<Id, Contract>();
            for (Contract cc : contractsToInsert) {
                accountIdToContractMap.put(cc.AccountId, cc);
            }

            return accountIdToContractMap;
        }

        private Map<Id, Quote> buildAccountIdToQuoteMap(List<Account> accounts, Set<Id> quoteIdSet) {

            // build map where Master and Child account point to (the same) Quote

            Map<Id, Account> masterAccIdToChildAccountMap = new Map<Id, Account>();
            for (Account acc : accounts) {
                if (acc.Master_Account__c != null) {
                    masterAccIdToChildAccountMap.put(acc.Master_Account__c, acc);
                }
            }

            Map<Id, Quote> activeAgreementMap = buildActiveAgreementMap(quoteIdSet);

            Map<Id, Quote> accountIdToQuoteMap = new Map<Id, Quote>();

            for (Quote qt : activeAgreementMap.values()) {
                accountIdToQuoteMap.put(qt.AccountId, qt);
                if (masterAccIdToChildAccountMap.containsKey(qt.AccountId)) {
                    Id childAccId = masterAccIdToChildAccountMap.get(qt.AccountId).Id;
                    accountIdToQuoteMap.put(childAccId, qt);
                }
            }

            return accountIdToQuoteMap;
        }

        private ContractHandleResult buildContractAndVersions(Quote qt, Account acc, Contract previousActiveContract) {

            Boolean isQuoteHasContract = QuoteHelper.isQuoteHasContract(qt);

            if (previousActiveContract == null && !isQuoteHasContract) {
                return new ContractHandleResult();
            }

            Map<Id, ContractVersion__c> accountIdToContractVersionMap = new Map<Id, ContractVersion__c>();

            ContractHandleResult result = new ContractHandleResult();

            if (previousActiveContract == null) {

                Contract newContract = buildContract(acc.Id, qt);
                ContractVersion__c contractVersion = buildContractVersion(qt, acc.Name);

                accountIdToContractVersionMap.put(acc.Id, contractVersion);

                result.contractToInsert = newContract;
                result.accountIdToContractVersionMap = accountIdToContractVersionMap;
            } else {

                ContractVersion__c lastContractVersion;
                if (!previousActiveContract.ContractVersions__r.isEmpty()) {
                    lastContractVersion = previousActiveContract.ContractVersions__r.get(0);

                    if (!isQuoteHasContract) {
                        previousActiveContract.Status = CONTRACT_STATUS_TERMINATED;

                        lastContractVersion.Status__c = CONTRACT_STATUS_TERMINATED;

                        result.contractToUpdate = previousActiveContract;
                        result.versionToUpdate = lastContractVersion;

                        return result;
                    } else {
                        lastContractVersion.Status__c = CONTRACT_VERSION_STATUS_AMENDED_AND_CLOSED;
                        result.versionToUpdate = lastContractVersion;
                    }
                }

                ContractVersion__c newContractVersion = buildContractVersion(
                    qt,
                    acc.Name,
                    previousActiveContract.Id,
                    lastContractVersion
                );

                accountIdToContractVersionMap.put(acc.Id, newContractVersion);

                result.accountIdToContractVersionMap = accountIdToContractVersionMap;
            }

            return result;
        }

        private Map<Id, List<Contract>> buildAccountIdToContractListMap(List<Contract> contractList) {
            Map<Id, List<Contract>> accountIdToContractListMap = new Map<Id, List<Contract>>();

            for (Contract cont : contractList) {
                if (!accountIdToContractListMap.containsKey(cont.AccountId) && cont.AccountId != null) {
                    accountIdToContractListMap.put(cont.AccountId, new List<Contract>());
                }
                accountIdToContractListMap.get(cont.AccountId).add(cont);
            }
            return accountIdToContractListMap;
        }

        private Map<Id, Contract> buildAccountIdToLatestContractMap(Map<Id, List<Contract>> accIdToContractListMap) {
            Map<Id, Contract> accountIdToLatestContractMap = new Map<Id, Contract>();

            for (Id accId : accIdToContractListMap.keySet()) {
                Contract latestContract = findContractWithLatestSignDate(accIdToContractListMap.get(accId));
                if (latestContract != null) {
                    accountIdToLatestContractMap.put(accId, latestContract);
                }
            }
            return accountIdToLatestContractMap;
        }

        private Contract findContractWithLatestSignDate(List<Contract> contrs) {
            Datetime dt = Datetime.newInstance(1900, 12, 31, 00, 00, 00);
            Contract latestContract;
            for (Contract c : contrs) {
                if (c.Original_Signed_Date__c > dt && c.Original_Signed_Date__c != null) {
                    dt = c.Original_Signed_Date__c;
                    latestContract = c;
                }
            }
            return latestContract;
        }

        private Map<Id, Account> getAccountsWithContracts(Set<Id> accIdSet) {
            List<Account> accList = (List<Account>) new AccountSelector()
                .selectAccountsWithActiveContract(new List<Object>{
                    new List<Id>(accIdSet)
                })
                .executeQuery();
            return (new Map<Id, Account>(accList));
        }

        private Map<Id, Account> getChildAccounts(Set<Id> potentialMasterIdSet) {
            List<Account> accList = (List<Account>) new AccountSelector()
                .selectChildAccounts(new List<Object>{
                    new List<Id>(potentialMasterIdSet)
                })
                .executeQuery();

            return (new Map<Id, Account>(accList));
        }

        private void populateParentContractAndActivateContract(
            List<Contract> insertedContracts,
            Map<Id, Account> childAccountMap,
            Map<Id, Contract> accountIdToContractMap
        ) {

            for (Contract cc : insertedContracts) {
                cc.Status = DocuSignHelper.CONTRACT_STATUS_ACTIVE;

                Account childAccount = childAccountMap.get(cc.AccountId);
                if (childAccount == null) {
                    continue;
                }
                Contract parentContract = accountIdToContractMap.get(childAccount.Master_Account__c);
                if (parentContract != null) {
                    cc.ParentContract__c = parentContract.Id;
                }
            }

            update insertedContracts;
        }

        private dsfs__DocuSign_Status__c[] getCompletedStatuses(dsfs__DocuSign_Status__c[] docuSignObjects) {
            List<dsfs__DocuSign_Status__c> result = new List<dsfs__DocuSign_Status__c>();
            for (dsfs__DocuSign_Status__c entry : docuSignObjects) {
                if (this.isChangedFieldTo(entry, dsfs__DocuSign_Status__c.dsfs__Envelope_Status__c, DocuSignHelper.ENVELOPE_STATUS_COMPLETED)) {
                    result.add(entry);
                }
            }
            return result;
        }

        private List<Contract> getContracts(Set<Id> accountIdSet) {
            return (List<Contract>) new ContractSelector()
                .selectActiveContractsByAccountId(accountIdSet)
                .executeQuery();
        }

        private Map<Id, Quote> buildActiveAgreementMap(Set<Id> quoteIdSet) {

            Map<Id, Quote> result = new Map<Id, Quote>();

            if (quoteIdSet == null || quoteIdSet.isEmpty()) {
                return result;
            }

            List<Quote> quotes = new QuoteSelector()
                .selectQuotesForContractPopulation(quoteIdSet)
                .executeQuery();

            result = new Map<Id, Quote>(quotes);

            return result;
        }

        private void updateApprovals(
            Set<Id> oppIds,
            Map<Id, Contract> accIdToContractMap,
            Map<Id, dsfs__DocuSign_Status__c> accIdToDocuSignMap
        ) {

            List<Approval__c> approvalList = [
                SELECT Id, Executed_Contract__c, Contracts__c, Opportunity__c, Opportunity__r.AccountId
                FROM Approval__c
                WHERE Status__c = :APPROVAL_STATUS_COMPLETED
                AND RecordType.Name = :APPROVAL_RT_NAME_ENGAGE_LEGAL
                AND Opportunity__c IN :oppIds
            ];

            if (approvalList.isEmpty()) {
                return;
            }

            List <Approval__c> approvalsToUpdate = new List <Approval__c>();

            for (Approval__c app : approvalList) {
                Id accId = app.Opportunity__r.AccountId;
                if (accIdToContractMap.containsKey(accId)) {
                    app.Contracts__c = accIdToContractMap.get(accId).Id;
                }
                if (accIdToDocuSignMap.containsKey(accId)) {
                    app.Executed_Contract__c = accIdToDocuSignMap.get(accId).Id;
                }
                approvalsToUpdate.add(app);
            }

            if (!approvalsToUpdate.isEmpty()) {
                updateObjects(JSON.serialize(approvalsToUpdate));
            }
        }

        private Contract buildContract(Id accId) {
            return buildContract(accId, null);
        }

        private Contract buildContract(Id accId, Quote activeAgreement) {
            Contract con = new Contract(
                AccountId = accId,
                Original_Signed_Date__c = System.today(),
                Source__c = 'Automation',
                Status = 'Draft'
            );

            if (activeAgreement != null) {
                con.Auto_Renewal__c = activeAgreement.Auto_Renewal__c;
                con.Start_Date__c = activeAgreement.Start_Date__c;
                con.End_Date__c = activeAgreement.End_Date__c;
                if (!String.isBlank(activeAgreement.Term_months__c)) {
                    con.Renewal_Term__c = QuoteHelper.getNumberFromString(activeAgreement.Term_months__c);
                }
                if (!String.isBlank(activeAgreement.Initial_Term_months__c)) {
                    con.Initial_Term__c = QuoteHelper.getNumberFromString(activeAgreement.Initial_Term_months__c);
                }
            }

            con.Original_Auto_Renewal__c = con.Auto_Renewal__c;
            con.Original_Start_Date__c = con.Start_Date__c;
            con.Original_End_Date__c = con.End_Date__c;
            con.Original_Initial_Term__c = con.Initial_Term__c;
            con.Original_Renewal_Term__c = con.Renewal_Term__c;

            return con;
        }

        private ContractVersion__c buildContractVersion(Quote activeAgreement, String accName) {
            return buildContractVersion(activeAgreement, accName, null, null);
        }

        private ContractVersion__c buildContractVersion(Quote activeAgreement, String accName, Id contractId, ContractVersion__c previousVersion) {

            ContractVersion__c contractVersion;

            if (previousVersion == null) {
                contractVersion = buildFirstVersion(activeAgreement);
            } else {
                contractVersion = buildNextVersion(previousVersion, activeAgreement);
            }

            contractVersion.Contract__c = contractId;

            contractVersion.Name = accName + ' Version ' + contractVersion.VersionNumber__c;

            return contractVersion;
        }

        private ContractVersion__c buildFirstVersion(Quote activeAgreement) {

            ContractVersion__c contractVersion = new ContractVersion__c(
                AutoRenewal__c = activeAgreement.Auto_Renewal__c,
                StartDate__c = activeAgreement.Start_Date__c,
                EndDate__c = activeAgreement.End_Date__c,
                Status__c = CONTRACT_VERSION_STATUS_STATUS_ACTIVE,
                VersionNumber__c = 1
            );

            if (!String.isBlank(activeAgreement.Term_months__c)) {
                contractVersion.RenewalTerm__c = QuoteHelper.getNumberFromString(activeAgreement.Term_months__c);
            }
            if (!String.isBlank(activeAgreement.Initial_Term_months__c)) {
                contractVersion.InitialTerm__c = QuoteHelper.getNumberFromString(activeAgreement.Initial_Term_months__c);
            }

            return contractVersion;
        }

        private ContractVersion__c buildNextVersion(ContractVersion__c previousVersion, Quote activeAgreement) {

            ContractVersion__c contractVersion = new ContractVersion__c(
                AutoRenewal__c = activeAgreement.Auto_Renewal__c,
                StartDate__c = activeAgreement.Start_Date__c,
                Status__c = CONTRACT_VERSION_STATUS_STATUS_ACTIVE
            );

            if (!String.isBlank(activeAgreement.Term_months__c)) {
                contractVersion.RenewalTerm__c = QuoteHelper.getNumberFromString(activeAgreement.Term_months__c);
            } else {
                contractVersion.RenewalTerm__c = previousVersion.RenewalTerm__c;
            }

            if (!String.isBlank(activeAgreement.Initial_Term_months__c)) {
                contractVersion.EndDate__c = activeAgreement.End_Date__c;
                contractVersion.InitialTerm__c = QuoteHelper.getNumberFromString(activeAgreement.Initial_Term_months__c);
            } else {
                contractVersion.EndDate__c = previousVersion.EndDate__c;
                contractVersion.InitialTerm__c = previousVersion.InitialTerm__c;
            }

            if (previousVersion.VersionNumber__c != null) {
                contractVersion.VersionNumber__c = previousVersion.VersionNumber__c.intValue() + 1;
            }

            return contractVersion;
        }

        private void insertContracts(Contract[] contractsToInsert) {
            insert contractsToInsert;
            updateContracts(contractsToInsert);
        }

        private void updateContracts(Contract[] contractsToUpdate) {
            for (Contract entry : contractsToUpdate) {
                entry.Status = DocuSignHelper.CONTRACT_STATUS_ACTIVE;
            }
            update contractsToUpdate;
        }

        private void insertContractVersions(Map<Id, ContractVersion__c> accIdToVersionMap, List<Contract> newContracts) {

            List<ContractVersion__c> contractVersions = new List<ContractVersion__c>();

            for (ContractVersion__c version : accIdToVersionMap.values()) {
                if (version.Contract__c != null) {
                    contractVersions.add(version);
                }
            }

            for (Contract con : newContracts) {
                if (accIdToVersionMap.containsKey(con.AccountId)) {
                    ContractVersion__c version = accIdToVersionMap.get(con.AccountId);
                    version.Contract__c = con.Id;
                    contractVersions.add(version);
                }
            }

            insert contractVersions;
        }

    }

    private class ContractHandleResult {
        public Contract contractToInsert;
        public Contract contractToUpdate;
        public ContractVersion__c versionToUpdate;
        public Map<Id, ContractVersion__c> accountIdToContractVersionMap;
    }

    /**
     * Contains info that should be coppied to docusign status before it is created
     */
    public class PrepopulationParams {
        public Id quoteId;
        public Id opportunityId;
        public Id accountId;
    }

    public class PrepopulateFields extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<dsfs__DocuSign_Status__c> docusignStatusList = new List<dsfs__DocuSign_Status__c>();
            for (dsfs__DocuSign_Status__c dss : (List<dsfs__DocuSign_Status__c>) Trigger.new) {
                if ((dss.dsfs__Opportunity__c == null || (dss.dfsq__Quote__c == null))
                    && dss.dsfs__DocuSign_Envelope_ID__c != null) {
                    docusignStatusList.add(dss);
                }
            }

            Set<String> docusignEnvelopeIdSet = new Set<String>();
            for (dsfs__DocuSign_Status__c dss : docusignStatusList) {
                docusignEnvelopeIdSet.add(dss.dsfs__DocuSign_Envelope_ID__c);
            }

            Map<String, PrepopulationParams> prepopulationParams = getDocusignPrepopulationParams(docusignEnvelopeIdSet);

            for (dsfs__DocuSign_Status__c dss : docusignStatusList) {
                PrepopulationParams params = prepopulationParams.get(dss.dsfs__DocuSign_Envelope_ID__c.toLowerCase());
                if (params == null) {
                    continue;
                }

                dss.dsfs__Opportunity__c = params.opportunityId;
                dss.dfsq__Quote__c = params.quoteId;
                dss.dsfs__Company__c = params.accountId;
            }
        }

        private Map<String, PrepopulationParams> getDocusignPrepopulationParams(Set<String> docusignEnvelopeIdSet) {
            Map<String, PrepopulationParams> result = new Map<String, PrepopulationParams>();

            List<dsfs__DocuSign_Envelope__c> docusignEnvelopeList = [
                SELECT Id, dsfs__Source_Object__c, dsfs__Source_Object_Parent__c, dsfs__DocuSign_Envelope_ID__c
                FROM dsfs__DocuSign_Envelope__c
                WHERE dsfs__DocuSign_Envelope_ID__c IN :docusignEnvelopeIdSet
            ];

            Map<Id, List<dsfs__DocuSign_Envelope__c>> sourceIdToEnvelopeList = new Map<Id, List<dsfs__DocuSign_Envelope__c>>();
            Map<Id, List<dsfs__DocuSign_Envelope__c>> cpqSourceIdToEnvelopeList = new Map<Id, List<dsfs__DocuSign_Envelope__c>>();

            for (dsfs__DocuSign_Envelope__c item : docusignEnvelopeList) {
                if (SFDescribeHelper.isValidSalesforceId(item.dsfs__Source_Object__c, Schema.Quote.sObjectType)) {
                    if (!sourceIdToEnvelopeList.containsKey(item.dsfs__Source_Object__c)) {
                        sourceIdToEnvelopeList.put(item.dsfs__Source_Object__c, new List<dsfs__DocuSign_Envelope__c>());
                    }
                    sourceIdToEnvelopeList.get(item.dsfs__Source_Object__c).add(item);
                }

            }

            if (sourceIdToEnvelopeList != null || !sourceIdToEnvelopeList.isEmpty()) {
                for (Quote qt : [SELECT Id, Opportunity.Id, Opportunity.AccountId FROM Quote WHERE Id IN :sourceIdToEnvelopeList.keySet()]) {
                    for (dsfs__DocuSign_Envelope__c envelope : sourceIdToEnvelopeList.get(qt.Id)) {
                        PrepopulationParams params = new PrepopulationParams();
                        params.quoteId = qt.Id;
                        params.opportunityId = qt.Opportunity.Id;
                        params.accountId = qt.Opportunity.AccountId;

                        result.put(envelope.dsfs__DocuSign_Envelope_ID__c, params);
                    }
                }
            }

            return result;
        }
    }

    @testVisible
    private static List<Quote> getListChildQuotes(Id parentId) {
        return (List<Quote>) new QuoteSelector()
            .selectQuotes()
            .setCondition('ParentQuote__c = \'' + parentId + '\'')
            .executeQuery();
    }

    public class PopulateAccountNdaStatus extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Map<Id, Account> accountsToUpdate = new Map<Id, Account>();

            for (dsfs__DocuSign_Status__c envelope : (List<dsfs__DocuSign_Status__c>) Trigger.new) {
                if (isAccountNdaEnvelopeStatusChanged(envelope)) {
                    accountsToUpdate.put(
                        envelope.dsfs__Company__c,
                        new Account(
                            Id = envelope.dsfs__Company__c,
                            NdaStatus__c = AccountHelper.DOCUSIGN_TO_NDA_STATUS.get(envelope.dsfs__Envelope_Status__c)
                        ));
                }
            }
            update accountsToUpdate.values();
        }

        private boolean isAccountNdaEnvelopeStatusChanged(dsfs__DocuSign_Status__c envelope) {
            Boolean envelopeAttachmentsContainsNda = false;
            for (Attachment att : (List<Attachment>) new AttachmentSelector()
                .selectAttachmentsByParentId(new List<String>{
                    envelope.Id
                })
                .executeQuery()) {
                if (att.Name.startsWithIgnoreCase(AttachmentHelper.NDA_NAME_PREFIX)) {
                    envelopeAttachmentsContainsNda = true;
                }
            }

            return envelopeAttachmentsContainsNda
                && isChangedFieldToAnyString(
                envelope,
                dsfs__DocuSign_Status__c.dsfs__Envelope_Status__c,
                AccountHelper.DOCUSIGN_TO_NDA_STATUS.keySet()
            )
                && envelope.dsfs__Company__c != null
                && envelope.dsfs__Opportunity__c == null
                && envelope.dfsq__Quote__c == null
                && envelope.dsfs__Case__c == null;
        }
    }
}