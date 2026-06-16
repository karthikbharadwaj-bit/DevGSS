@RestResource(UrlMapping='/AccountService/*')
global with sharing class AccountService {
    private static final String ERROR_ACTION = 'Cannot find action';
    public static final String CONVERT_ACCOUNT_TO_ELA = 'convertAccountToEla';

    @HttpPost
    global static void handleRequest() {
        String body = RestContext.request.requestBody.toString();
        Response resp = new Response();

        if (RestContext.response == null) {
            RestContext.response = new RestResponse();
        }

        try {
            RequestParams params = (RequestParams) JSON.deserialize(body, RequestParams.class);

            switch on params.action {
                when 'getAccountNature' {
                    resp.setData(getAccountNature(params.accountIdSet));
                }
                when 'getAccountData' {
                    resp.setData(getAccountData(params));
                }
                when 'linkData' {
                    resp.setData(linkData(params));
                }
                when 'templatesForAccount' {
                    resp.setData(getTemplatesForAccount(params));
                }
                when 'attachPdf' {
                    resp.setData(attachPdfToAccount(params));
                }
                when 'getAccountsOnAccountViewer' {
                    resp.setData(getAccountsOnAccountViewer(params));
                }
                when 'getTechnicalAccounts' {
                    resp.setData(getTechnicalAccounts(params));
                }
                when 'createElaServiceAccounts' {
                    resp.setData(handleElaAccounts(params));
                }
                when 'convertAccountToEla' {
                    resp.setData(handleElaAccounts(params));
                }
                when 'discardPartnerOperations' {
                    resp.setData(discardPartnerOperations(params));
                }
                when 'createTechnicalAccounts' {
                    resp.setData(createTechnicalAccounts(params));
                }
                when 'getCCLegacyEntitlements' {
                    resp.setData(getCCLegacyEntitlements(params));
                }
                when 'getSubBrandAndDefaultBI' {
                    resp.setData(getSubBrandAndDefaultBI(params));
                }
                when else {
                    resp.error(ERROR_ACTION);
                }
            }
        } catch (Exception ex) {
            System.debug('///AccountService exception ' + ex);
            RestContext.response.responseBody = Blob.valueOf(
                JSON.serialize(getErrorResponse(ex))
            );
            return;
        }
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(resp));
    }

    private static Response getAccountNature(Set<Id> accIds) {
        Response resp = new Response();
        Integer accountsAmount = [
            SELECT count()
            FROM Account
            WHERE (Id IN :accIds) OR (Master_Account__c IN :accIds)
        ];
        /* Case id belongs to master account - that means it has some child accs => soql result will be > 1 else == 1 */
        resp.setData('isChildAccount', accountsAmount == 1);
        return resp;
    }

    private static Response getCCLegacyEntitlements(RequestParams params) {
        Entitlement__c[] entitlements = new List<Entitlement__c>();
        EntitlementSelector entlSelector = new EntitlementSelector();

        entitlements = entlSelector.getEntitlements(params.accountId).executeQuery();

		Response resp = new Response();
        resp.setData('entitlements', entitlements);
        return resp;
    }

    private static Response getAccountData(RequestParams params) {
        Response resp = new Response();
        List<Account> accList;

        if (params.soqlParams.queryMethod == 'childById') {
            accList = (List<Account>) new AccountSelector()
                .selectChildAccById(new List<Object>{params.accountIdSet})
                .subselect(new PackageSelector(AccountHelper.ACCOUNT_RELATION_TECH_ACCOUNTS_NAME, Account.SObjectType).selectPackageForApproval())
                .executeQuery();
        }
        if (params.soqlParams.queryMethod == 'childByMasterId') {
            accList = (List<Account>) new AccountSelector()
                .selectChildAccByMasterAccount(new List<Object>{params.accountIdSet})
                .subselect(new PackageSelector(AccountHelper.ACCOUNT_RELATION_TECH_ACCOUNTS_NAME, Account.SObjectType).selectPackageForApproval())
                .executeQuery();
        }
        if (params.soqlParams.queryMethod == 'childByMasterIdWithBindedQuotes') {
            accList = (List<Account>) new AccountSelector()
                .selectChildAccByMasterAccountWithBindedQuotes(new List<Object>{params.accountIdSet})
                .subselect(new PackageSelector(AccountHelper.ACCOUNT_RELATION_TECH_ACCOUNTS_NAME, Account.SObjectType).selectPackageForApproval())
                .executeQuery();
        }
        if (params.soqlParams.queryMethod == 'masterById') {
            Boolean isSearchAmongContacts =
                (FeatureManagement.checkPermission(CustomPermissionHelper.PERMISSION_EXPANDED_ENGAGE_BINDING));

            if (isSearchAmongContacts) {
                accList = (List<Account>) new AccountSelector()
                    .selectAccWithContactByContact(new List<Object>{
                        params.accountIdSet,
                        new Set<String>{params.soqlParams.roleContact.lastName},
                        new Set<String>{params.soqlParams.roleContact.phone},
                        new Set<String>{params.soqlParams.relationContact.lastName},
                        new Set<String>{params.soqlParams.relationContact.phone}
                    })
                    .subselect(new PackageSelector()
                        .newQueryFactory()
                        .selectFields(new List<String>{'Service_Type__c', 'Enterprise_Account_ID__c'})
                    )
                    .executeQuery();
            } else {
                accList = (List<Account>) new AccountSelector()
                    .selectAccWithContactByContactId(new List<Object>{
                        params.accountIdSet,
                        new Set<String>{params.soqlParams.roleContact.contactId},
                        new Set<String>{params.soqlParams.relationContact.contactId}
                    })
                    .subselect(new PackageSelector()
                        .newQueryFactory()
                        .selectFields(new List<String>{'Service_Type__c', 'Enterprise_Account_ID__c'})
                    )
                    .executeQuery();
            }
        }

        resp.setData('accData', accList);
        return resp;
    }

    private static Response linkData(RequestParams params) {
        Response resp = new Response();

        linkAccounts(params.accountAssignments);
        linkQuotes(params.quoteWrapperList);
        /* Only for India accounts */
        copyParentMsaAttachment(params.accountAssignments);

        resp.setData('reselectedQuotes', QuoteService.getQuoteList(params.opportunityId));
        return resp;
    }

    private static void linkAccounts(Map<String, String> accountMap) {
        List<Account> accountsToUpdate = new List<Account>();
        for (Id childAccountId : accountMap.keySet()) {
            Account acc = new Account(Id = childAccountId, Master_Account__c = accountMap.get(childAccountId));
            accountsToUpdate.add(acc);
        }
        update accountsToUpdate;
    }

    private static void linkQuotes(List<BillingWrappers.QuoteWrapper> quoteWrapperList) {
        List<Quote> quotesToUpdate = new List<Quote>();
        for (BillingWrappers.QuoteWrapper qt : quoteWrapperList) {
            Quote childQuote = new Quote(
                Id = qt.id,
                ParentQuote__c = qt.parentQuoteId,
                Initial_Term_months__c = qt.initialTerm
            );
            if (qt.renewalTerm != null) {
                childQuote.Term_months__c = qt.renewalTerm;
            }
            if (qt.autoRenewal != null) {
                childQuote.Auto_Renewal__c = qt.autoRenewal;
            }
            if (qt.endDate != null) {
                childQuote.End_Date__c = Date.valueOf(qt.endDate);
            }
            if (qt.startDate != null) {
                childQuote.Start_Date__c = Date.valueOf(qt.startDate);
            }
            quotesToUpdate.add(childQuote);
        }
        update quotesToUpdate;
    }
    @TestVisible
    private static void copyParentMsaAttachment(Map<String, String> accAssignmentMap) {
        Map<Id, Contract> parentMap = buildAttParentsMap(accAssignmentMap);
        /* Collect attachments */
        Map<String, List<Attachment>> atts = getAtts(parentMap, accAssignmentMap.keySet());
        /* Parent Account to parent MSA */
        Map<Id, Attachment> parentAccIdToAttMap = buildParentAccIdToAttMap(atts.get('parentMsa'), parentMap);
        /* Copied Parent MSAs */
        List<Attachment> attachmentsToInsert = buildAttachmentsToInsert(accAssignmentMap, parentAccIdToAttMap);

        try{
            insert attachmentsToInsert;
        } catch(Exception e) {
            PlatformLog.logResult(
                'AccountService', e.getMessage(), null, null, null, true
            );
        }
        /* Remove existing Attachments only if new ones were inserted */
        List<Attachment> childAccAtts = atts.get('childMsa');
        if (!childAccAtts.isEmpty()) {
            delete childAccAtts;
        }
    }

    @TestVisible
    private static Map<Id, Contract> buildAttParentsMap(Map<String, String> accAssignmentMap) {
        Set<String> accIdSet = new Set<String>();
        accIdSet.addAll(accAssignmentMap.keySet());
        accIdSet.addAll(accAssignmentMap.values());

        Map<Id, Account> accMap = new Map<Id,Account>((List<Account>) new AccountSelector()
            .selectAccountsWithActiveSignedContract(new List<Object>{new List<String>(accIdSet)})
            .executeQuery());

        Map<Id, Contract> parentMap = new Map<Id, Contract>();
        for (Account acc : accMap.values()) {
            /* Skip non India child Accounts */
            if (acc.Approvals__r.isEmpty() || !accAssignmentMap.containsKey(acc.Id)) {
                continue;
            }

            Id parentAccountId = accAssignmentMap.get(acc.Id);
            List<Contract> parentAccContracts = accMap.get(parentAccountId)?.Contracts;
            if (parentAccContracts != null && !parentAccContracts.isEmpty()) {
                Contract activeContract = parentAccContracts[0];
                parentMap.put(activeContract.Id, activeContract);
            }
        }

        return parentMap;
    }

    @TestVisible
    private static Map<String, List<Attachment>> getAtts(Map<Id, Contract> parentMap, Set<String> childAccStringIdSet) {
        Set<Id> parentIds = new Set<Id>((List<Id>)new List<String>(childAccStringIdSet));
        parentIds.addAll(parentMap.keySet());

        Map<String, List<Attachment>> attMap = new Map<String, List<Attachment>>{
            'childMsa' => new List<Attachment>(),
            'parentMsa' => new List<Attachment>()
        };

        for (Attachment att : (List<Attachment>) new AttachmentSelector().selectMsaByParentId(parentIds).executeQuery()) {
            if (parentMap.containsKey(att.ParentId)) {
                attMap.get('parentMsa').add(att);
            } else {
                attMap.get('childMsa').add(att);
            }
        }
        return attMap;
    }

    @TestVisible
    public static Map<Id, Attachment> buildParentAccIdToAttMap(List<Attachment> attList, Map<Id, Contract> parentMap) {
        Map<Id, Attachment> parentAccIdToAttachmentMap = new Map<Id, Attachment>();
        for (Attachment att : attList) {
            Id parentAccId = parentMap.get(att.ParentId).AccountId;
            /* Process only last Created MSA */
            if (!parentAccIdToAttachmentMap.containskey(parentAccId)) {
                parentAccIdToAttachmentMap.put(parentAccId, att);
            }
        }

        return parentAccIdToAttachmentMap;
    }

    @TestVisible
    private static List<Attachment> buildAttachmentsToInsert(Map<String, String> accAssignmentMap, Map<Id, Attachment> parentAccIdToAttMap) {
        List<Attachment> attachmentsToInsert = new List<Attachment>();
        for (Id childAccountId : accAssignmentMap.keySet()) {
            Id parentAccountId = accAssignmentMap.get(childAccountId);

            Attachment originalAtt = parentAccIdToAttMap.get(parentAccountId);

            if (originalAtt != null) {
                Attachment clonedAtt = originalAtt.clone();
                clonedAtt.ParentId = childAccountId;

                attachmentsToInsert.add(clonedAtt);
            }
        }
        return attachmentsToInsert;
    }

    @testVisible
    private static Map<String, String> getErrorResponse(Exception ex) {
        return new Map<String, String> {
            'error'      => ex.getMessage(),
            'stackTrace' => ex.getStackTraceString()
        };
    }

    private static Response getTemplatesForAccount(RequestParams params) {
        Response resp = new Response();

        String brand = params.data.get('brand');
        String billingCountry = params.data.get('billingCountry');

        List<RC_Quote_Template__c> templates = getTemplates(brand, billingCountry);

        resp.setData('templates', templates);
        return resp;
    }

    private static List<RC_Quote_Template__c> getTemplates(String brand, String billingCountry) {
        List<RC_Quote_Template__c> templates = new List<RC_Quote_Template__c>();
        if (brand == RingCentralHelper.BRAND_RINGCENTRAL_EU) {
            String mappedBillingCountry = SettingsService.getCountryCodeToCountryMapping().get(billingCountry);
            templates = new RCQuoteTemplateSelector()
                .selectNdaTemplatesByBillingCountry(new List<Object> {
                    mappedBillingCountry == null
                        ? billingCountry
                        : mappedBillingCountry})
                .executeQuery();
        } else if (brand == RingCentralHelper.BRAND_RINGCENTRAL
            || brand == RingCentralHelper.BRAND_RINGCENTRAL_CANADA
            || brand == RingCentralHelper.BRAND_RINGCENTRAL_UK
            || brand == RingCentralHelper.BRAND_RINGCENTRAL_AU) {
            templates = new RCQuoteTemplateSelector()
                .selectNdaTemplatesByBrand(new List<Object> {brand})
                .executeQuery();
        }

        return templates;
    }

    private static Response attachPdfToAccount(RequestParams params) {
        Response resp = new Response();
        Id accountId = params.data.get('accountId');
        Id templateId = params.data.get('templateId');

        Account acc = (Account) new AccountSelector().selectAccountById(accountId)
            .selectFields(new List<String> {'Name'})
            .executeQuery()
            .get(0);

        RC_Quote_Template__c templateObj = (RC_Quote_Template__c) new RCQuoteTemplateSelector()
            .selectNdaTemplatesById(new List<Object> {templateId})
            .executeQuery()
            .get(0);

        if (templateObj == null) {
            return null;
        }

        Blob pdfBlob;
        if (Test.isRunningTest()) {
            pdfBlob = Blob.toPdf('data for test');
        } else {
            PageReference pdfPage = Page.PreviewPDF;
            if (pdfPage != null) {
                pdfPage.getParameters().put('templateId', templateId);
                pdfPage.getParameters().put('objectId', accountId);
                pdfBlob = pdfPage.getContent();
            }
        }

        String attachmentName = 'Non-Disclosure Agreement for ' + acc.Name + ' ' + System.now() + '.pdf';
        Attachment a = new Attachment(
            parentId = accountId,
            Name = attachmentName,
            body = pdfBlob);

        insert a;
        resp.setData('attachment', a);
        return resp;
    }

    public static Response getAccountsOnAccountViewer(RequestParams params) {
        Response resp = new Response();
        Account[] selectedAccounts = (Account[]) new AccountSelector()
            .selectAccountsByIds(new List<Object>{params.accountIds})
            .selectFields(new List<String>{'Partner_Account__c.NGBS_Partner_ID__c'})
                .subselect(new PackageSelector().selectPackageForApproval())
            .executeQuery();
        resp.setData('salesforceAccounts', selectedAccounts);
        return resp;
    }

    public static Response getTechnicalAccounts(RequestParams params) {
        Response resp = new Response();
        List<Account> technicalAccounts = AccountHelper.getTechnicalAccounts(params.accountId);
        resp.setData('technicalAccounts', technicalAccounts);
        return resp;
    }

    public class RequestParams {
        public Set<Id> accountIdSet;
        public String action;
        public Map<String, String> accountAssignments;
        public List<BillingWrappers.QuoteWrapper> quoteWrapperList;
        public String opportunityId;
        public SoqlParams soqlParams;
        public Map<String, String> data;
        public Id accountId;
        public String[] accountIds;
        public String accountName;
        public String contactId;
        public Integer numberOfAccounts;
        public String logId;
        public String approvalId;
        public List<String> serviceNames;
    }

    public class SoqlParams {
        public ContactParams roleContact;
        public ContactParams relationContact;
        public String queryMethod;
    }

    public class ContactParams {
        public String contactId;
        public String lastName;
        public String phone;
    }

    private static Response handleElaAccounts(RequestParams params) {
        Response resp = new Response();

        Account elaBillingAccount = AccountSelector.getAccountWithLeadConvertFields(params.accountIds[0]);

        List<Account> elaServiceAccountList = AccountHelper.generateElaServiceAccounts(
            elaBillingAccount,
            params.numberOfAccounts,
            params.accountName);

        if (params.action == CONVERT_ACCOUNT_TO_ELA) {
            List<Account> allElaAccountList = new List<Account>(elaServiceAccountList);
            AccountHelper.convertAccountToElaBilling(elaBillingAccount);
            allElaAccountList.add(elaBillingAccount);
            upsert allElaAccountList;
        } else {
            insert elaServiceAccountList;
        }

        List<AccountContactRole> acRoleList = new List<AccountContactRole>();
        List<AccountRelation__c> accountRelationList = new List<AccountRelation__c>();

        for (Account elaServiceAccount : elaServiceAccountList) {
            acRoleList.add(
                AccountHelper.createAccountContactRole(elaServiceAccount.Id, params.contactId)
            );
            accountRelationList.add(
                AccountHelper.createAccountRelationEla(elaBillingAccount.Id, elaServiceAccount.Id)
            );
        }

        insert acRoleList;
        insert accountRelationList;

        return resp;
    }

    public static Response discardPartnerOperations(RequestParams params) {
        Response resp = new Response();
        Response downgradeResp = new Response();
        Response recallResp = new Response();
        Response rejectResp = new Response();

        if (params.approvalId != null) {
            recallResp = PartnerOperationsController.recallApproval(params.approvalId);

            if (recallResp.messages[0].severity != 'error') {
                downgradeResp = PartnerOperationsController.downgradeOpportunity(params.opportunityId);
                rejectResp = PartnerOperationsController.rejectPartnerOperation(params.logId);
                resp.setData(downgradeResp);
                resp.setData(rejectResp);
            }
            resp.setData(recallResp);
        } else {
            downgradeResp = PartnerOperationsController.downgradeOpportunity(params.opportunityId);
            rejectResp = PartnerOperationsController.rejectPartnerOperation(params.logId);
            resp.setData(downgradeResp);
            resp.setData(rejectResp);
        }

        return resp;
    }

    public static Response createTechnicalAccounts(RequestParams params) {
        Response resp = new Response();
        if (params.accountId != null && params.serviceNames != null) {
            Map<String, Account> result = AccountHelper.createTechnicalAccounts(params.accountId, params.serviceNames);
            resp.setData('result', JSON.serializePretty(result));
        }

        return resp;
    }

    public static Response getSubBrandAndDefaultBI(RequestParams params) {
        Response response = new Response();
        if (params.accountId != null) {
            Map<String, String> subBrandBIMap = SettingsService.getSubBrandAndDefaultBI(null, params.accountId);
            String defaultBI = subBrandBIMap.get('defaultBI');
            String subBrand = subBrandBIMap.get('subBrand');
            String country = subBrandBIMap.get('country');
            String brand = subBrandBIMap.get('brand');
            List<String> availableBIs = SettingsService.getAvailableBusinessIdentities(defaultBI, subBrand, country, brand);
            response.setData('defaultBI', defaultBI);
            response.setData('subBrand', subBrand);
            response.setData('availableBIs', JSON.serialize(availableBIs));
        }
        return response;
    }
}