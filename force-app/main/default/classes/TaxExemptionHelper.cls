public class TaxExemptionHelper {
    public final static Boolean isEnabled = Feature_Toggle__c.getInstance().Enable_Account_Based_Tax_Exemption__c;
    public final static String CURRENT = 'Current';
    public final static String APPROVED = 'Approved';
    public final static String PENDING = 'Pending Approval';
    public final static String REQUESTED = 'Requested';
    public final static String REJECTED = 'Rejected';
    public final static Set<String> VATBRANDS = new Set<String>{
        RingCentralHelper.BRAND_RINGCENTRAL_EU,
        RingCentralHelper.BRAND_RINGCENTRAL_UK,
        RingCentralHelper.BRAND_AVAYA,
        RingCentralHelper.BRAND_ATOS,
        RingCentralHelper.BRAND_RAINBOW
    };

    public final static Set<String> VATCURRENCIES = new Set<String>{
        RingCentralHelper.EUR,
        RingCentralHelper.GBP
    };

    public static Boolean notCheckVATNumber = false; // for AccountTriggerHandler bypass
    public static Boolean isFastApprovalExecuted = false; // for ApprovalTriggerHandler not sending TE asynchronously to NGBS on fast approval
    public static Map<String, Boolean> isAutomaticApprovalMap = new Map<String, Boolean>();

    public final static String INDIA_COUNTRY = 'India';
    public final static Integer NA_RELATED_LIST_SEZ_CERTIFICATE_ORDER = 5;

    public final static String TEA_ERROR_APPROVED_KYC_NOT_FOUND = 'Approved KYC Approval doesnt exist';
    public final static String TEA_ERROR_SEZ_CERT_NOT_FOUND = 'KYC Approval doesn\'t contain SEZWOP Cert Attachment';

    public static NGBSAPI.TaxExemption getTaxExemption(String billingId) {
        if (billingId != null) {
            HttpResponse response = NGBSAPI.requestNGBS(
                String.format(NGBSAPI.NGBS_ACCOUNT_TAX_EXEMPTION_SETTINGS,
                new List<String> {billingId}),
                HttpHelper.METHOD_GET);

            if (response.getStatusCode() == 200) {
                return (NGBSAPI.TaxExemption) JSON.deserialize(response.getBody(), NGBSAPI.TaxExemption.class);
            }
        }

        return null;
    }

    public static void submitForTaxExemptionApproval(List<Approval__c> approvals) {
        try {
            Set<Id> approvalIdsToApprove = new Set<Id>();

            for (Approval__c approval : approvals) {
                if (approval == null) {
                    continue;
                }
                Boolean isApprove = String.isNotBlank(approval.VATCountry__c) && String.isNotBlank(approval.VATNumber__c)
                    || String.isNotBlank(approval.Account__c)
                        && (isIndiaCountry(approval.Account__r.BillingCountry)
                            || approval.SEZWOPExemption__c == ApprovalHelper.STATUS_REQUESTED);

                if (isApprove) {
                    approvalIdsToApprove.add(approval.Id);
                }

                ApprovalHelper.submitApprovalRequest(
                    approval.Id,
                    ApprovalHelper.PROCESS_TAX_EXEMPTION_APPROVAL_PROCESS,
                    'tax exemption approval process'
                );
            }

            ApprovalHelper.processApprovalRequest(approvalIdsToApprove, null, 'Approve');
        } catch(Exception ex) {
            AquivaHelper.throwAquivaException(ex.getMessage());
        }
    }

    public static void updateVATNumberOnAccount(List<Approval__c> approvals) {
        List<Account> accountsToUpdate = new List<Account>();

        Set<Id> accountIdsToUpdate = new Set<Id>{};
        for (Approval__c approval : approvals) {
            accountIdsToUpdate.add(approval.Account__c);
        }

        Map<Id, Account> approvalAccounts = new  Map<Id, Account>(
            (List<Account>) new AccountSelector().selectAccounts()
                .setQueryBindings(new List<Object>{ accountIdsToUpdate })
                .selectFields(new List<Schema.SObjectField>{
                    Account.Id,
                    Account.VATNumber__c,
                    Account.TaxExemptionApprovals__c
                })
                .setCondition('Id IN :bind0')
                .executeQuery()
        );

        for (Approval__c approval : approvals) {
            Account acc = approvalAccounts.get(approval.Account__c);
            if (acc == null) {
                continue;
            }
            if (approval.VATCountryForCheck__c != null && approval.VATNumber__c != null) {
                acc.VATNumber__c = approval.VATCountryForCheck__c + approval.VATNumber__c;
                acc.TaxExemptionApprovals__c = true;
                acc.ConfirmTaxExemptionRemoval__c  = false;
                accountsToUpdate.add(acc);
            }
        }

        if (!accountsToUpdate.isEmpty()) {
            notCheckVATNumber = true;
            update accountsToUpdate;
        }
    }

    @future(callout=true)
    public static void postTaxExemptionAsync(String billingId,
                                                Boolean federal,
                                                Boolean state,
                                                Boolean county,
                                                Boolean local,
                                                Boolean sales,
                                                Boolean vat,
                                                Boolean sezWOP,
                                                String vatCountry,
                                                String vatNumber,
                                                String gstNumber) {
        postTaxExemption(billingId, federal, state, county, local, sales, vat, sezWOP, vatCountry, vatNumber, gstNumber);
    }

    public static HttpResponse postTaxExemption(String billingId,
                                                Boolean federal,
                                                Boolean state,
                                                Boolean county,
                                                Boolean local,
                                                Boolean sales,
                                                Boolean vat,
                                                Boolean sezWOP,
                                                String vatCountry,
                                                String vatNumber,
                                                String gstNumber) {
        if (billingId != null) {
            String body = prepareTaxExemptionBody(federal, state, county, local, sales, vat, sezWOP, vatCountry, vatNumber, gstNumber);
            HttpResponse response = NGBSAPI.requestNGBS(
                String.format(NGBSAPI.NGBS_ACCOUNT_TAX_EXEMPTION_SETTINGS, new List<String> {billingId}),
                HttpHelper.METHOD_POST,
                body,
                'application/json');

            return response;
        }

        return null;
    }

    public static String prepareTaxExemptionBody(Boolean federal, Boolean state, Boolean county, Boolean local, Boolean sales, Boolean vat, Boolean sezWOP, String vatCountry, String vatNumber, String gstNumber) {
        JSONGenerator generator = JSON.createGenerator(true);
        generator.writeStartObject();
            generator.writeBooleanField('federalTaxExemption', federal == null
                                                                ? false
                                                                : federal);
            generator.writeBooleanField('stateTaxExemption', state == null
                                                                ? false
                                                                : state);
            generator.writeBooleanField('countyTaxExemption', county == null
                                                                ? false
                                                                : county);
            generator.writeBooleanField('localTaxExemption', local == null
                                                                ? false
                                                                : local);
            generator.writeBooleanField('salesTaxExemption', sales == null
                                                                ? false
                                                                : sales);
            generator.writeBooleanField('VATExemption', vat == null
                                                                ? false
                                                                : vat);
        if (sezWOP != null) {
            generator.writeBooleanField('SEZWOPExemption', sezWOP);
        }
        if(vatCountry != null && vatNumber != null) {
            generator.writeStringField('VATCountry', vatCountry);
            generator.writeStringField('VATNumber', vatNumber);
        }
        if(gstNumber != null) {
            generator.writeStringField('GSTNumber', gstNumber);
        }
        generator.writeEndObject();

        return generator.getAsString();
    }

    public static Boolean isTaxExemptionActive(String taxExemptionState) {
        return taxExemptionState == TaxExemptionHelper.CURRENT
            || taxExemptionState == TaxExemptionHelper.APPROVED;
    }

    public static Response syncExemptWithNGBS(Approval__c exemptApproval) {
        return syncExemptWithNGBS(exemptApproval, false);
    }

    public static Response syncExemptWithNGBS(Approval__c exemptApproval, Boolean isFirstInit) {
        Response resp = new Response();

        if (exemptApproval == null) {
            return resp;
        }
        if (!AccountHelper.isExistingBusiness(exemptApproval.Account__r)) {
            return resp;
        }

        NGBSAPI.TaxExemption ngbsExemptionState = getTaxExemption(exemptApproval.Account__r.Billing_ID__c);
        Response exemptChanges = getExemptChanges(exemptApproval, ngbsExemptionState); // not exempt approval
        Boolean isNGBSExemptionsChanged = (Boolean) exemptChanges.data.get('isNGBSExemptionsChanged');

        if (isNGBSExemptionsChanged && (isFirstInit || Boolean.valueOf(exemptApproval.SyncWithBillingIsNotRequired__c))) {
            /* Update approval with values from NGBS and add warning message"*/
            applyCurrentTaxExemption(ngbsExemptionState, exemptApproval, exemptChanges);
            if (!isFirstInit) {
                resp.setData('isExemptChangedOnNGBS', Label.NGBS_Tax_Exemptions_Changed);
            }
        }
        return resp;
    }

    public static Approval__c getApproval(String approvalId) {
        Approval__c approval;
        if (approvalId != null && Id.valueOf(approvalId).getSObjectType() == Approval__c.getSobjectType()) {
            List<Approval__c> listApprovals = (List<Approval__c>)(new ApprovalSelector()
                .selectTaxExemptionApprovalsById(new List<Object>{new List<Id>{approvalId}})
                .executeQuery());
            approval = listApprovals.size() > 0 ? listApprovals.get(0) : null;
        }
        return approval;
    }

    @TestVisible
    private static Response getExemptChanges(Approval__c approval, NGBSAPI.TaxExemption ngbsExemptions) {
        Response resp = new Response();

        Boolean isFederalChanged = isExemptionChanged(ngbsExemptions.getFederalTaxExemption(), approval.FederalTaxExemption__c);
        Boolean isStateChanged = isExemptionChanged(ngbsExemptions.getStateTaxExemption(), approval.StateTaxExemption__c);
        Boolean isCountyChanged = isExemptionChanged(ngbsExemptions.getCountyTaxExemption(), approval.CountyTaxExemption__c);
        Boolean isLocalChanged = isExemptionChanged(ngbsExemptions.getLocalTaxExemption(), approval.LocalTaxExemption__c);
        Boolean isSalesTaxChanged = isExemptionChanged(ngbsExemptions.getSalesTaxExemption(), approval.SalesTaxExemption__c);
        Boolean isVatChanged = isExemptionChanged(ngbsExemptions.getVatExemption(), approval.VATExemption__c);
        Boolean isSEZWOPChanged = isExemptionChanged(ngbsExemptions.getSEZWOPExemption(), approval.SEZWOPExemption__c);

        resp.setData('isFederalChanged', isFederalChanged);
        resp.setData('isStateChanged', isStateChanged);
        resp.setData('isCountyChanged', isCountyChanged);
        resp.setData('isLocalChanged', isLocalChanged);
        resp.setData('isSalesTaxChanged', isSalesTaxChanged);
        resp.setData('isVatChanged', isVatChanged);
        resp.setData('isSEZWOPChanged', isSEZWOPChanged);
        resp.setData('isNGBSExemptionsChanged', isFederalChanged || isStateChanged || isCountyChanged || isLocalChanged || isSalesTaxChanged || isVatChanged || isSEZWOPChanged);
        return resp;
    }

    private static Boolean isExemptionChanged(Boolean ngbsExemption, String sfdcExemption) {
        Boolean isSFDCCurrentExemption = sfdcExemption == TaxExemptionHelper.CURRENT;
        Boolean ngbsExemptSafe = BooleanHelper.toBoolean(ngbsExemption);
        return ngbsExemptSafe && !isSFDCCurrentExemption || !ngbsExemptSafe && isSFDCCurrentExemption;
    }

    private static void applyCurrentTaxExemption(NGBSAPI.TaxExemption ngbsExemptionState, Approval__c exemptApproval, Response exemptChanges) {
        if (ngbsExemptionState == null
            || String.isBlank(exemptApproval.Id)
            || exemptApproval.Id.getSObjectType() != Approval__c.getSobjectType()
        ) {
            return;
        }

        Approval__c approval = new Approval__c( Id = exemptApproval.Id );

        approval.FederalTaxExemption__c = getCurrentExemptBasedOnNGBS(
            ngbsExemptionState.getFederalTaxExemption(), exemptChanges.data.get('isFederalChanged'), exemptApproval.FederalTaxExemption__c
        );
        approval.StateTaxExemption__c = getCurrentExemptBasedOnNGBS(
            ngbsExemptionState.getStateTaxExemption(), exemptChanges.data.get('isStateChanged'), exemptApproval.StateTaxExemption__c
        );
        approval.CountyTaxExemption__c = getCurrentExemptBasedOnNGBS(
            ngbsExemptionState.getCountyTaxExemption(), exemptChanges.data.get('isCountyChanged'), exemptApproval.CountyTaxExemption__c
        );
        approval.LocalTaxExemption__c = getCurrentExemptBasedOnNGBS(
            ngbsExemptionState.getLocalTaxExemption(), exemptChanges.data.get('isLocalChanged'), exemptApproval.LocalTaxExemption__c
        );
        approval.SalesTaxExemption__c = getCurrentExemptBasedOnNGBS(
            ngbsExemptionState.getSalesTaxExemption(), exemptChanges.data.get('isSalesTaxChanged'), exemptApproval.SalesTaxExemption__c
        );
        approval.VATExemption__c = getCurrentExemptBasedOnNGBS(
            ngbsExemptionState.getVatExemption(), exemptChanges.data.get('isVatChanged'), exemptApproval.VATExemption__c
        );
        approval.SEZWOPExemption__c = getCurrentExemptBasedOnNGBS(
            ngbsExemptionState.getSEZWOPExemption(), exemptChanges.data.get('isSEZWOPChanged'), exemptApproval.SEZWOPExemption__c
        );

        update approval;
    }

    private static String getCurrentExemptBasedOnNGBS(Boolean ngbsExemption, Object isNGBSExemptionChanged, String sfdcExemption) {
        if (Boolean.valueOf(isNGBSExemptionChanged)) {
            return ngbsExemption ? CURRENT : null;
        }
        return sfdcExemption;
    }

    @future(callout=true)
    public static void completeApproval(List<Id> approvalIds, boolean kyc) {
        List<Account> accountsToUpdate = new List<Account>();
        List<Approval__c> approvalsToUpdate = new List<Approval__c>();
        List<Approval__c> approvalsToReject = new List<Approval__c>();

        Map<Id, Account> techAccs = new Map<Id, Account>();
        List<Opportunity> techOpps = new List<Opportunity>();

        List<Approval__c> approvals = (List<Approval__c>) new ApprovalSelector()
            .selectTaxExemptionApprovalsById(new List<Object>{approvalIds})
            .executeQuery();

        Map<Id, Approval__c> idToApprovals = new Map<Id, Approval__c> (approvals);
        Set<Id> masterAccountIds = new Set<Id>();
        Set<Id> masterOpptyIds = new Set<Id>();
        List<Approval__c> techApprovalsToInsert = new List<Approval__c>();
        User technicalUser;

        for (Approval__c salesforceApproval : idToApprovals.values()) {
            masterAccountIds.add(salesforceApproval.Account__c);
            masterOpptyIds.add(salesforceApproval.Opportunity__c);

            NGBSAPI.TaxExemption billingTaxExemptions = isExistingBusiness(salesforceApproval)
                ? getTaxExemption(salesforceApproval.Account__r.Billing_ID__c)
                : null;
            Approval__c completedApproval = approveOrRejectRequestedApproval(salesforceApproval, billingTaxExemptions);
            approvalsToUpdate.add(completedApproval);
        }

        if (!masterAccountIds.isEmpty()) {
            Map<Id, Approval__c> idToRejects = new Map<Id, Approval__c> ((List<Approval__c>) new ApprovalSelector()
                .selectApprovedTaxExemptionApprovalsForAccount(new List<Object>{masterAccountIds, new List<String>{APPROVED}, !kyc ? idToApprovals.keySet() : new Set<Id>()})
                .executeQuery());
            for (Approval__c rejectApproval : idToRejects.values()) {
                if (rejectApproval.Status__c == ApprovalHelper.STATUS_APPROVED) {
                    approvalsToReject.add(rejectApproval);
                }
            }

            techAccs = new Map<Id, Account>((List<Account>) new AccountSelector()
                .selectMPTechAccountsByMasterIds(masterAccountIds)
                .executeQuery());

            techOpps = (List<Opportunity>) new OpportunitySelector()
                .selectMPTechOppsByMasterIds(masterOpptyIds)
                .executeQuery();

            technicalUser = UserHelper.getMultiproductTechnicalUser();
        }
        for (Approval__c app : approvalsToUpdate) {
            if (app.Status__c != ApprovalHelper.STATUS_APPROVED || kyc) {
                continue;
            }

            Approval__c initialApproval = idToApprovals.get(app.Id);

            if (app.Account__c != null) {
                if (app.VATNumber__c != null && !isIndiaCountry(initialApproval.Account__r.BillingCountry)) {
                    accountsToUpdate.add(new Account(Id = app.Account__c, TaxExemptionApprovals__c = true, VATNumber__c = (app.VATCountryForCheck__c + app.VATNumber__c)));
                } else {
                    accountsToUpdate.add(new Account(Id = app.Account__c, TaxExemptionApprovals__c = true, Tax_Exempt__c = true));
                }
            }

            techApprovalsToInsert = createTechnicalApprovalsToInsert(initialApproval, app, techAccs, techOpps, technicalUser);

            if (!isExistingBusiness(initialApproval)) {
                continue;
            }
            updateBillingTaxExemptions(initialApproval, app, techAccs);
        }

        Triggers.switchOff();
        if (!approvalsToUpdate.isEmpty()) {
            update approvalsToUpdate;
        }
        Triggers.switchOn();

        if (!techApprovalsToInsert.isEmpty()) {
            insert techApprovalsToInsert;
        }

        String comment = 'Approval was rejected due to another approval was approved';
        if (!approvalsToReject.isEmpty()) {
            BusinessIdentitiesService.updateApprovals(approvalsToReject, comment, false);
        }

        if (!accountsToUpdate.isEmpty()) {
            notCheckVATNumber = true;
            update accountsToUpdate;
        }
    }

    public static List<Approval__c> createTechnicalApprovalsToInsert(
        Approval__c initialApproval,
        Approval__c updatedApproval,
        Map<Id, Account> techAccs,
        List<Opportunity> techOpps,
        User technicalUser
    ) {
        List<Approval__c> techApprovalsToInsert = new List<Approval__c>();

        for (Account acc : techAccs.values()) {
            if (acc.Master_Account__c == initialApproval.Account__c) {
                for (Opportunity opp : techOpps) {
                    Approval__c newTechApproval;
                    if (opp.MasterOpportunity__c == initialApproval.Opportunity__c && opp.AccountId == acc.Id) {
                        newTechApproval = updatedApproval.clone(false, true, false, true);
                        newTechApproval.Name = initialApproval.Name + opp.Tier_Name__c;
                        newTechApproval.RecordTypeId = ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL;
                        newTechApproval.Account__c = acc.Id;
                        newTechApproval.Opportunity__c = opp.Id;
                        newTechApproval.MasterApproval__c = initialApproval.Id;
                        newTechApproval.Status__c = ApprovalHelper.STATUS_APPROVED;
                        newTechApproval.IsMultiProductTechnicalApproval__c = true;
                        newTechApproval.Contact__c = null;

                        if (technicalUser != null) {
                            newTechApproval.OwnerId = technicalUser.Id;
                        }
                    }

                    if (newTechApproval != null) {
                        techApprovalsToInsert.add(newTechApproval);
                    }

                }
            }
        }
        return techApprovalsToInsert;
    }

    public static void updateBillingTaxExemptions(Approval__c initialApproval, Approval__c updatedApproval, Map<Id, Account> techAccs) {
        postTaxExemption(
            initialApproval.Account__r.Billing_ID__c,
            isTaxExemptionActive(updatedApproval.FederalTaxExemption__c),
            isTaxExemptionActive(updatedApproval.StateTaxExemption__c),
            isTaxExemptionActive(updatedApproval.CountyTaxExemption__c),
            isTaxExemptionActive(updatedApproval.LocalTaxExemption__c),
            isTaxExemptionActive(updatedApproval.SalesTaxExemption__c),
            isTaxExemptionActive(updatedApproval.VATExemption__c),
            isTaxExemptionActive(updatedApproval.SEZWOPExemption__c),
            updatedApproval.VATCountryForCheck__c,
            updatedApproval.VATNumber__c,
            updatedApproval.GstNo__c
        );

        for (Account techAcc : techAccs.values()) {
            if (String.isNotBlank(techAcc.Billing_ID__c)) {
                postTaxExemption(
                    techAcc.Billing_ID__c,
                    isTaxExemptionActive(updatedApproval.FederalTaxExemption__c),
                    isTaxExemptionActive(updatedApproval.StateTaxExemption__c),
                    isTaxExemptionActive(updatedApproval.CountyTaxExemption__c),
                    isTaxExemptionActive(updatedApproval.LocalTaxExemption__c),
                    isTaxExemptionActive(updatedApproval.SalesTaxExemption__c),
                    isTaxExemptionActive(updatedApproval.VATExemption__c),
                    isTaxExemptionActive(updatedApproval.SEZWOPExemption__c),
                    updatedApproval.VATCountryForCheck__c,
                    updatedApproval.VATNumber__c,
                    updatedApproval.GstNo__c
                );
            }
        }
    }

    public static Boolean isExistingBusiness(Approval__c app) {
        return app.Account__r.Billing_ID__c != null;
    }

    public static Approval__c approveOrRejectRequestedApproval(Approval__c salesforceApproval, NGBSAPI.TaxExemption billingTaxExemptions) {
        Approval__c completedApproval = new Approval__c();

        completedApproval.Id = salesforceApproval.Id;
        completedApproval.Status__c = salesforceApproval.Status__c;
        completedApproval.FederalTaxExemption__c = determineTaxExemptionState(
            salesforceApproval.FederalTaxExemption__c,
            billingTaxExemptions == null ? null : billingTaxExemptions.getFederalTaxExemption(),
            salesforceApproval.Status__c);
        completedApproval.StateTaxExemption__c = determineTaxExemptionState(
            salesforceApproval.StateTaxExemption__c,
            billingTaxExemptions == null ? null : billingTaxExemptions.getStateTaxExemption(),
            salesforceApproval.Status__c);
        completedApproval.CountyTaxExemption__c = determineTaxExemptionState(
            salesforceApproval.CountyTaxExemption__c,
            billingTaxExemptions == null ? null : billingTaxExemptions.getCountyTaxExemption(),
            salesforceApproval.Status__c);
        completedApproval.LocalTaxExemption__c = determineTaxExemptionState(
            salesforceApproval.LocalTaxExemption__c,
            billingTaxExemptions == null ? null : billingTaxExemptions.getLocalTaxExemption(),
            salesforceApproval.Status__c);
        completedApproval.SalesTaxExemption__c = determineTaxExemptionState(
            salesforceApproval.SalesTaxExemption__c,
            billingTaxExemptions == null ? null : billingTaxExemptions.getSalesTaxExemption(),
            salesforceApproval.Status__c);
        completedApproval.VATExemption__c = determineTaxExemptionState(
            salesforceApproval.VATExemption__c,
            billingTaxExemptions == null ? null : billingTaxExemptions.getVatExemption(),
            salesforceApproval.Status__c);
        completedApproval.SEZWOPExemption__c = determineTaxExemptionState(
            salesforceApproval.SEZWOPExemption__c,
            billingTaxExemptions == null ? null : billingTaxExemptions.getSEZWOPExemption(),
            salesforceApproval.Status__c);
        completedApproval.GstNo__c = salesforceApproval.GstNo__c;
        completedApproval.VATCountryForCheck__c = salesforceApproval.VATCountryForCheck__c;
        completedApproval.VATNumber__c = salesforceApproval.VATNumber__c;
        completedApproval.Account__c = salesforceApproval.Account__c;

        return completedApproval;
    }

    private static String determineTaxExemptionState(String salesforceTaxExemption, Boolean billingTaxExemption, String approvalStatus) {
        String taxExemptState = salesforceTaxExemption;

        if (isExistingBusiness(billingTaxExemption)) {
            if (billingExemptionBecameTrue(salesforceTaxExemption, billingTaxExemption)) {
                taxExemptState = CURRENT;
            }
            if (billingExemptionBecameFalse(salesforceTaxExemption, billingTaxExemption)) {
                taxExemptState = null;
            }
            if (approvalWasApproved(salesforceTaxExemption, billingTaxExemption, approvalStatus)) {
                taxExemptState = APPROVED;
            }
            if (approvalWasRejected(salesforceTaxExemption, billingTaxExemption, approvalStatus)) {
                taxExemptState = REJECTED;
            }
        } else {
            if (approvalWasApproved(salesforceTaxExemption, approvalStatus)) {
                taxExemptState = APPROVED;
            }
            if (approvalWasRejected(salesforceTaxExemption, approvalStatus)) {
                taxExemptState = REJECTED;
            }
        }

        return taxExemptState;
    }

    private static Boolean isExistingBusiness(Boolean billingTaxExemption) {
        return billingTaxExemption != null;
    }

    private static Boolean billingExemptionBecameTrue(String salesforceTaxExemption, Boolean billingTaxExemption) {
        return salesforceTaxExemption != CURRENT
            && billingTaxExemption;
    }

    private static Boolean billingExemptionBecameFalse(String salesforceTaxExemption, Boolean billingTaxExemption) {
        return salesforceTaxExemption != APPROVED
            && salesforceTaxExemption != REJECTED
            && salesforceTaxExemption != REQUESTED
            && !billingTaxExemption;
    }

    private static Boolean approvalWasApproved(String salesforceTaxExemption, String approvalStatus) {
        return salesforceTaxExemption == REQUESTED
            && approvalStatus == ApprovalHelper.STATUS_APPROVED;
    }

    private static Boolean approvalWasApproved(String salesforceTaxExemption, Boolean billingTaxExemption, String approvalStatus) {
        return salesforceTaxExemption == REQUESTED
            && !billingTaxExemption
            && approvalStatus == ApprovalHelper.STATUS_APPROVED;
    }

    private static Boolean approvalWasRejected(String salesforceTaxExemption, String approvalStatus) {
        return salesforceTaxExemption == REQUESTED
            && approvalStatus == ApprovalHelper.STATUS_REJECTED;
    }

    private static Boolean approvalWasRejected(String salesforceTaxExemption, Boolean billingTaxExemption, String approvalStatus) {
        return salesforceTaxExemption == REQUESTED
            && !billingTaxExemption
            && approvalStatus == ApprovalHelper.STATUS_REJECTED;
    }

    public static Boolean isAccountBasedTaxExemptionFlow(Approval__c approval) {
        return isAnyExemptRequested(approval);
    }

    private static Boolean isAnyExemptRequested(Approval__c approval) {
        return approval != null
            && (approval.FederalTaxExemption__c == REQUESTED
            || approval.StateTaxExemption__c == REQUESTED
            || approval.CountyTaxExemption__c == REQUESTED
            || approval.LocalTaxExemption__c == REQUESTED
            || approval.VATExemption__c == REQUESTED
            || approval.SEZWOPExemption__c == REQUESTED);
    }

    public static Boolean checkAttachIdsForIndia(String attachStr) {
        List<String> sections = !String.isBlank(attachStr)
            ? attachStr.split(';')
            : new List<String>();
        if (sections.size() > NA_RELATED_LIST_SEZ_CERTIFICATE_ORDER && String.isNotBlank(sections[NA_RELATED_LIST_SEZ_CERTIFICATE_ORDER])) {
            for (String docId: sections[NA_RELATED_LIST_SEZ_CERTIFICATE_ORDER].split(',')) {
                if (String.isNotBlank(docId)) {
                    return true;
                }
            }
        }
        return false;
    }

    public static String getKycErrorForTEACreation(Approval__c kycApproval) {
        String errMsg = '';

        if (kycApproval == null) {
            errMsg = TEA_ERROR_APPROVED_KYC_NOT_FOUND;
        } else if (!TaxExemptionHelper.checkAttachIdsForIndia(kycApproval.KycFiles__c)) {
            errMsg = TEA_ERROR_SEZ_CERT_NOT_FOUND;
        }

        return errMsg;
    }

    public static void populateFieldsForSalesTaxExemptionApprovals(Approval__c app, Opportunity opp, Map<Id, Approval__c> masterOppToMasterApproval) {
        app.Opportunity__c = opp.Id;
        app.recordTypeId = ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL;
        app.Account__c = opp.accountId;
        app.Status__c = ApprovalHelper.STATUS_APPROVED;
        app.SalesTaxExemption__c = ApprovalHelper.STATUS_APPROVED;
        app.Name = ApprovalHelper.AUTOMATIC_APPROVAL;
        if (BooleanHelper.toBoolean(opp.IsMultiProductTechnicalOpportunity__c)) {
            app.OwnerId = opp.OwnerId;
            app.IsMultiProductTechnicalApproval__c = opp.IsMultiProductTechnicalOpportunity__c;
            app.MasterApproval__c = masterOppToMasterApproval?.get(opp.MasterOpportunity__c)?.Id;
        }
    }

    public static Boolean isIndiaCountry(String country) {
        Map<String, String> countryCodes = SettingsService.getCountryCodes();
        String indianAlpha3 = countryCodes.get(INDIA_COUNTRY.toLowerCase());
        String indianAlpha2 = 'IN';

        return INDIA_COUNTRY.equalsIgnoreCase(country)
            || indianAlpha3 != null && indianAlpha3.equalsIgnoreCase(country)
            || indianAlpha2.equalsIgnoreCase(country);
    }

    public static Map<Id, Approval__c> getLastApprovedKYCApprovalByAccounts(List<Id> accIds) {
        Map<Id, Approval__c> approvalsByAccount = new Map<Id, Approval__c>();

        List<Account> accList = new AccountSelector()
            .selectAccountWithApprovedKYCApprovals(new List<Object>{accIds})
            .executeQuery();

        for (Account acc: accList) {
            Approval__c lastUpdatedKYCApproval = !acc.Approvals__r.isEmpty()
                ? acc.Approvals__r[0]
                : null;
            if (lastUpdatedKYCApproval?.Status__c == ApprovalHelper.STATUS_APPROVED) {
                approvalsByAccount.put(acc.Id, lastUpdatedKYCApproval);
            }
        }

        return approvalsByAccount;
    }
}