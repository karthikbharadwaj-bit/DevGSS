public class SWNSyncContractRunner extends SWNActionRunner {
    @TestVisible
    private static final String BILLING_ID = 'billingId';
    @TestVisible
    private static final String CONTRACT_STATUS = 'contractStatus';
    private static final String ENABLE_UPGRADE_ON_CONTRACT = 'EnableUpgradeOnContract';
    private static final String BODY = 'body';
    private static final String DATA = 'data';
    @TestVisible
    private static final String REQUIRED_PARAMS_IS_MISSING_ERROR = '"billingId" and "packageId" are required parameters';

    @TestVisible
    private SWNSyncContractRunner() {}

    public SWNSyncContractRunner(Id quoteId, String action) {
        super(quoteId, action);
    }

    @TestVisible
    protected override void run() {
        syncContract();
    }

    private void syncContract() {
        SWNMessageHelper.CompositeResult contractResult = processContract_new(sdc);
        handleFSC(contractResult);
        res.addMessage(contractResult.baseMessage);
    }

    @TestVisible
    private void handleFSC(SWNMessageHelper.CompositeResult contractResult) {
        if (!Response.STATUS_SUCCESS.equalsIgnoreCase(contractResult.baseMessage?.status)) {
            sdc.currentStep.isStepCompletedSuccessfully = false;
            return;
        }
        
        res = processFSC(sdc);

        if (!res.isSuccess()) {
            sdc.currentStep.isStepCompletedSuccessfully = false;
            return;
        }

        String updatedPackageInfo = updateContractInfo(
            sdc.qt,
            (String) contractResult.data.get(BILLING_ID),
            (String) contractResult.data.get(CONTRACT_STATUS)
        );

        if (String.isNotBlank(updatedPackageInfo)) {
            sdc.currentStep.quoteFieldsToUpdate.put(Quote.Id.toString(), sdc.qt.Id);
            sdc.currentStep.quoteFieldsToUpdate.put(Quote.Package_Info__c.toString(), updatedPackageInfo);
            res.setData('qt', sdc.qt);
            res.setData('isQuoteUpdated', true);
        }
    }

    @TestVisible
    private Response processFSC(SWNDataCollector sdc) {
        Response res = new Response();

        if (sdc.syncable.isFSCSynced()) {
            return res;
        }

        try {
            /* In case of inter product upgrade we need to handle inactive contract by creation of contract on current product
            So we can avoid of wrong applying of FSC */
            String packageId = sdc.ngbsPackage?.id;
            if (QuoteHelper.isCrossUpgrade(sdc.qt)) {
                res = allowEnableUpgradeOnContract(sdc.billingId, packageId);
                if (res.isSuccess()) {
                    res = NGBSAPI.createNGBSContract(sdc.billingId, new ContractRestAPI.CreateInterimContractParams(sdc.qt));
                }
            }

            if (res.isSuccess()) {
                updateFreeServiceCredit(sdc.billingId, packageId, sdc.qt.Free_Service_Credit_Total__c);
            }
        } catch(Exception ex) {
            res.error(ex);
        }

        if (res.isSuccess()) {
            sdc.syncable.setFSCSynced();
        }

        return res;
    }

    @TestVisible
    private SWNMessageHelper.CompositeResult processContract_new(SWNDataCollector sdc) {
        SWNMessageHelper.CompositeResult result;
        SWNMessageHelper.SWNMessage message;
        try {
            String status = SWNHelper.getContractSyncStatus(sdc.syncable, sdc.qt);

            if (status == SWNHelper.SYNCED) {
                message = SWNHelper.INFO_MESSAGES_BUILDER.getSWNMessage(SWNMessageHelper.LabelMessage.CONTRACTS_ALREADY_SYNCED);
                return new SWNMessageHelper.CompositeResult(message);
            }

            List<BillingWrappers.QuotePackageInfo> pInfos =
                (List<BillingWrappers.QuotePackageInfo>)
                    JSON.deserialize(sdc.qt.Package_Info__c, List<BillingWrappers.QuotePackageInfo>.class);
            BillingWrappers.QuotePackageInfo pInfo = pInfos[0];
            String packageBillingId = pInfo.packageInfo.id;
            BillingWrappers.BillingContract activeContract = getActiveContract(sdc.billingContracts);
            Boolean isPackageFoundInContract = false;
            if (activeContract != null && activeContract.packages != null && String.isNotBlank(packageBillingId)) {
                for (BillingWrappers.FunnelPackage funnelPkg : activeContract.packages) {
                    if (funnelPkg.packageId == packageBillingId) {
                        isPackageFoundInContract = true;
                        break;
                    }
                }
            }
            
            String contractIdNGBS = activeContract != null ? activeContract.id : null;
            String contractId = contractIdNGBS != null ? contractIdNGBS : pInfo.contract.billingId;
            String contractStatus;
            HttpResponse response;
            String accountId = sdc.billingId;
            if (isEntitlementsForTrialExist(sdc.qt, accountId)) {
                response = ContractRestAPI.createNGBSContract(accountId, sdc.qt);
                contractStatus = SWNHelper.CONTRACT_STATUS_NEW;
            } else if (String.IsNotBlank(contractId)) {
                Boolean shouldCreatePackageData = shouldCreatePackageDataOnContract(isPackageFoundInContract, sdc.qt);
                response = shouldCreatePackageData 
                    ? ContractRestAPI.createPackageDataOnContract(accountId, contractId, sdc.qt, pInfo)
                    : ContractRestAPI.updateNGBSContract(accountId, contractId, sdc.qt);
                contractStatus = shouldCreatePackageData 
                    ? SWNHelper.CONTRACT_STATUS_NEW 
                    : SWNHelper.CONTRACT_STATUS_UPDATED;
            } else {
                response = ContractRestAPI.createNGBSContract(accountId, sdc.qt);
                contractStatus = SWNHelper.CONTRACT_STATUS_NEW;
            }
            if (HttpHelper.isSuccess(response)) {
                message = SWNHelper.SUCCESS_MESSAGES_BUILDER.getSWNMessage(SWNMessageHelper.LabelMessage.SYNC_CONTRACTS_SUCCESS);
                result = new SWNMessageHelper.CompositeResult(message);
                BillingWrappers.GWContract billingContract = (BillingWrappers.GWContract)JSON.deserialize(response.getBody(), BillingWrappers.GWContract.class);
                result.addData(DATA, response.getBody());
                result.addData(CONTRACT_STATUS, contractStatus);
                result.addData(BILLING_ID, billingContract.id);
            }
        } catch(Exception e) {
            if (e.getMessage().contains('is not aligned with package billing date') && e.getMessage().contains('Contract start date')) {
                AquivaHelper.throwAquivaException('NGBS and CRM contract start dates are in different billing cycles. Please align CRM start date to current billing cycle.');
            } else {
                if (Test.isRunningTest()) {
                    result.addData(DATA, '{"id": "123", "status": "new"}');
                    result.addData(CONTRACT_STATUS, 'new');
                    result.addData(BILLING_ID, '123');
                } else {
                    AquivaHelper.throwAquivaException('An error occurred during processing of contract: ' + e.getMessage());
                }
            }
        }

        return result;
    }

    @TestVisible
    private BillingWrappers.BillingContract getActiveContract(List<BillingWrappers.BillingContract> billingContracts) {
        BillingWrappers.BillingContract activeContract;
        for (BillingWrappers.BillingContract contract : billingContracts) {
            if (contract.isActiveContract()) {
                activeContract = contract;
                break;
            }
        }
        return activeContract;
    }

    @TestVisible
    private Boolean isEntitlementsForTrialExist(Quote qt, String accountId) {
        Map<String, Integer> entitlements;
        if (!QuoteHelper.isEntitlementPackageOfferTypeTrial(qt)) {
            return false;
        }

        Map<String, Integer> ents = getEntitlementsForPOC(accountId, qt);
        if (!isQuantityChangedForPOC(qt.QuoteLineItems, ents)) {
            return false;
        }

        return ents != null;
    }

    @TestVisible
    private Map<String, Integer> getEntitlementsForPOC(String billingId, Quote qt) {
        Map<String, Integer> result = new Map<String, Integer>();

        BillingWrappers.NGBSAccount ngbsAcc = NGBSAPI.getNGBSAccount(billingId);
        if (BooleanHelper.toBoolean(ngbsAcc?.packages?.isEmpty())) {
            return result;
        }

        String packageId = QuoteHelper.getPackageId(qt.Package_Info__c);

        BillingWrappers.NGBSAccountPackage pkg = ngbsAcc.getPackageById(packageId);
        List<BillingWrappers.BillingInfoSummaryLicense> licenses = NGBSAPI.getNGBSBillingInfoSummaryLicenses(
            billingId,
            pkg.id
        );

        for (BillingWrappers.BillingInfoSummaryLicense license : licenses) {
            result.put(license.catalogId, license.qty);
        }

        return result;
    }

    @TestVisible
    private Boolean isQuantityChangedForPOC(List<QuoteLineItem> qlis, Map<String, Integer> externalIdToAmountEntsMap) {
        Boolean result = false;
        for (QuoteLineItem qli : qlis) {
            if (Product2Helper.isTaxes(qli.Product2)
                || isLCSpecialLicense(qli)
            ) {
                continue;
            }
            Decimal qliQuantity = NumberHelper.roundCurrency(qli.NewQuantity__c, 2, RoundingMode.HALF_UP);
            Decimal entQuantity = 0;

            if (externalIdToAmountEntsMap.get(qli.Product2.ExtID__c) != null) {
                entQuantity = NumberHelper.roundCurrency(externalIdToAmountEntsMap.get(qli.Product2.ExtID__c), 2, RoundingMode.HALF_UP);
            }
            if (qliQuantity != entQuantity) {
                result = true;
                break;
            }
        }
        return result;
    }

    private Boolean isLCSpecialLicense(QuoteLineItem qli) {
        return String.isNotBlank(qli.Product2.ExtID__c)
            && (qli.Product2.ExtID__c.contains('LC_HD')
                || qli.Product2.ExtID__c.contains('LC_DID')
                || qli.Product2.ExtID__c == 'LC_DL_75');
    }

    @TestVisible
    private Response allowEnableUpgradeOnContract(String billingId, String packageId) {
        Response res = new Response();
        res = NGBSAPI.getPackageParams(billingId, packageId);
        if (res.isSuccess()) {
            String body = (String) res.getData(BODY);
            List<NGBSAPI.NBGSPackageParameters> parameters = (List<NGBSAPI.NBGSPackageParameters>)
                JSON.deserialize(body, List<NGBSAPI.NBGSPackageParameters>.class);
            List<NGBSAPI.NBGSPackageParameters> params = new List<NGBSAPI.NBGSPackageParameters>();
            for (NGBSAPI.NBGSPackageParameters p : parameters) {
                if (p.name == ENABLE_UPGRADE_ON_CONTRACT) {
                    /* allowed: -1;
                       not allowed: 0 */
                    NGBSAPI.NBGSPackageParameters param = new NGBSAPI.NBGSPackageParameters();
                    param.id = p.id;
                    param.name = p.name;
                    param.value = -1;
                    params.add(param);
                    break;
                }
            }
            res = NGBSAPI.updatePackageParams(billingId, packageId, (params.size() > 0 ? params : parameters));
        }
        return res;
    }

    @TestVisible
    private Decimal updateFreeServiceCredit(String billingId, String packageId, Decimal currentFSCAmount) {
        Decimal newFSC = 0;

        if (!SettingsHelper.FEATURE_TOGGLE.Enable_FSC_for_Existing_Customers__c) {
            return newFSC;
        }
        if (String.isBlank(billingId) || String.isBlank(packageId)) {
            AquivaHelper.throwAquivaException(REQUIRED_PARAMS_IS_MISSING_ERROR);
        }
        if (currentFSCAmount == null) {
            currentFSCAmount = 0;
        }

        Decimal existingFSC = NGBSAPI.getFreeServiceCreditValue(billingId, packageId);
        newFSC = existingFSC + currentFSCAmount;

        if (newFSC > 0) {
            NGBSAPI.updateFreeServiceCredit(billingId, packageId, newFSC);
        }
        return newFSC;
    }

    @TestVisible
    private Boolean shouldCreatePackageDataOnContract(Boolean isPackageFoundInContract, Quote qt) {
        return !isPackageFoundInContract && QuoteHelper.isEngageVService(qt);
    }

    @TestVisible
    private String updateContractInfo(Quote qt, String contractBillingId, String contractStatus) {

        if (String.isBlank(contractBillingId) || String.isBlank(qt.Package_Info__c)) {
            return null;
        }

        List<BillingWrappers.QuotePackageInfo> pInfos = QuoteHelper.getPackageInfoList(qt);
        BillingWrappers.QuotePackageInfo pInfo = pInfos[0];

        pInfo.contract.billingId = contractBillingId;
        pInfo.contract.status = contractStatus;

        return JSON.serialize(pInfos);
    }
}