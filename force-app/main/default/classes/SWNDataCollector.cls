public class SWNDataCollector {
    public final String action;
    @TestVisible
    private final Id quoteId;

    @TestVisible
    public Quote qt {
        get {
            if (qt == null) {
                qt = (Quote) new ListOptional(new QuoteSelector()
                    .selectQuoteForSyncWithNGBSByQuoteId(quoteId)
                    .executeQuery()
                ).getFirst();
                if (qt == null) {
                    throw new AquivaHelper.AquivaException(QuoteHelper.QUOTE_NOT_FOUND);
                }
            }
            return qt;
        }
        private set;
    }

    @TestVisible
    public Opportunity opp {
        get {
            if (opp == null) {
                opp = qt.Opportunity;
            }
            return opp;
        }
        private set;
    }

    @TestVisible
    public List<QuoteLineItem> qlis {
        get {
            if (qlis == null) {
                qlis = qt.QuoteLineItems;
            }
            return qlis;
        }
        private set;
    }

    @TestVisible
    public Boolean isMPUB {
        get {
            if (isMPUB == null) {
                isMPUB = !qt.ServiceInfo__r.isEmpty();
            }
            return isMPUB;
        }
        private set;
    }

    @TestVisible
    public NGBSSyncables.ISyncable syncable {
        get {
            if (syncable == null) {
                syncable = NGBSSyncables.getSyncable(isMPUB, qt.Id, opp);
            }
            return syncable;
        }
        private set;
    }

    @TestVisible
    public List<Cost_Center__c> costCenters {
        get {
            if (costCenters == null) {
                Id quoteIdForCostCenters = qt.IsMultiProductTechnicalQuote__c ? qt.MasterQuote__c : qt.Id;
                costCenters = new CostCenterSelector()
                    .selectCostCentersForSyncWithNGBSByQuoteId(quoteIdForCostCenters)
                    .executeQuery();
            }
            return costCenters;
        }
        private set;
    }

    @TestVisible
    public String billingId {
        get {
            if (billingId == null) {
                billingId = qt.Account.Billing_ID__c;
            }
            return billingId;
        }
        private set;
    }

    @TestVisible
    public BillingWrappers.NGBSAccount ngbsAcc {
        get {
            if (ngbsAcc == null) {
                ngbsAcc = NGBSAPI.getNGBSAccount(billingId);
            }
            return ngbsAcc;
        }
        private set;
    }

    @TestVisible
    public String packageId {
        get {
            if (packageId == null) {
                packageId = QuoteHelper.getPackageId(qt.Package_Info__c);
            }
            return packageId;
        }
        private set;
    }

    @TestVisible
    public BillingWrappers.NGBSAccountPackage ngbsPackage {
        get {
            if (ngbsPackage == null) {
                ngbsPackage = ngbsAcc?.getPackageById(packageId);
            }
            return ngbsPackage;
        }
        private set;
    }

    @TestVisible
    public List<BillingWrappers.BillingContract> billingContracts {
        get {
            if (billingContracts == null) {
                if (String.isBlank(billingId) || String.isBlank(packageId)) {
                    billingContracts = new List<BillingWrappers.BillingContract>();
                } else {
                    billingContracts = NGBSAPI.requestContractsFromBilling(billingId, packageId);
                }
            }
            return billingContracts;
        }
        private set;
    }

    @TestVisible
    public Account acc {
        get {
            if (acc == null) {
                acc = qt.Account;
            }
            return acc;
        }
        private set;
    }

    public List<Quote> proservQuotes {
        get {
            if (proservQuotes == null) {
                proservQuotes = new QuoteSelector()
                    .selectQuotes()
                    .withoutSelectorFieldsIncluded()
                    .setCondition('OpportunityId = :bind0 AND ProServ_Status__c != :bind1 AND RecordTypeId IN :bind2')
                    .setQueryBindings(new List<Object> {
                        opp.Id,
                        QuoteHelper.PROSERVSTATUS_CANCELLED,
                        QuoteHelper.PROSERV_QUOTE_DEVELOPER_ID_SET
                    })
                    .executeQuery();
            }
            return proservQuotes;
        }
        private set;
    }

    public Response syncScenarioResp {
        get {
            if (syncScenarioResp == null) {
                syncScenarioResp = SWNScenarioHelper.getSyncScenario(this);
            }
            return syncScenarioResp;
        }
        private set;
    }

    @TestVisible
    public SWNScenarioHelper.Scenario currentScenario {
        get {
            if (currentScenario == null) {
                currentScenario = (SWNScenarioHelper.Scenario) syncScenarioResp.data.get(SWNScenarioHelper.SCENARIO);
            }
            return currentScenario;
        }
        private set;
    }

    @TestVisible
    public String currentScenarioKey {
        get {
            if (currentScenarioKey == null) {
                currentScenarioKey = (String) syncScenarioResp.data.get(SWNScenarioHelper.SCENARIO_KEY);
            }
            return currentScenarioKey;
        }
        private set;
    }

    @TestVisible
    public SWNStep currentStep {
        get {
            if (currentStep == null) {
                currentStep = currentScenario.stepsMap.get(action);
            }
            return currentStep;
        }
        private set;
    }

    public SWNDataCollector(Id quoteId) {
        this.quoteId = quoteId;
    }

    public SWNDataCollector(Id quoteId, String action) {
        this.quoteId = quoteId;
        this.action = action;
    }

    public SWNDataCollector(Id quoteId, Boolean isMPUB) {
        this.quoteId = quoteId;
        this.isMPUB = isMPUB;
    }

    // ONLY FOR UNIT TESTS
    @TestVisible
    private SWNDataCollector() {}
}