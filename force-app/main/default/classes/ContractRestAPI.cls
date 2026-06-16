@RestResource(urlMapping='/Contract')
global with sharing class ContractRestAPI {

    @HttpGet
    global static void getContracts() {
        List<Contract__c> contracts = [
                SELECT Id, ExtId__c, Name, Available_in_packages__c, Description__c, Duration__c, Active__c,
                Billing_Countries__c, Business_Identities_Countries__c,
                (SELECT ApplicableTo__c, Discount__c, Duration__c FROM Contract_Discounts__r)
                FROM Contract__c
        ];

        List<BillingWrappers.GWContract> result = new List<BillingWrappers.GWContract>();

        for (Contract__c cont : contracts) {
            BillingWrappers.GWContract gcont = new BillingWrappers.GWContract();
            gcont.id = cont.Id;
            gcont.extId = cont.ExtId__c;
            gcont.name = cont.Name;
            gcont.description = cont.Description__c;
            gcont.duration = cont.Duration__c;
            gcont.availableInPackages = String.isNotBlank(cont.Available_in_packages__c)
                    ? cont.Available_in_packages__c.split(',')
                    : new List<String>();
            gcont.billingCountries = String.isNotBlank(cont.Billing_Countries__c)
                    ? cont.Billing_Countries__c.split(';')
                    : new List<String>();
            gcont.businessIdentitiesCountries = String.isNotBlank(cont.Business_Identities_Countries__c)
                    ? cont.Business_Identities_Countries__c.split(';')
                    : new List<String>();
            gcont.isActive = cont.Active__c;
            BillingWrappers.GWDiscount gdisc = new BillingWrappers.GWDiscount();

            Decimal tid = 1;
            for (Contract_Discount__c cd : cont.Contract_Discounts__r) {
                if (cd.Duration__c == null){
                    continue;
                }
                BillingWrappers.GWDiscountTemplate gtemp = new BillingWrappers.GWDiscountTemplate();
                gtemp.applicableTo.id = cd.ApplicableTo__c;
                gtemp.id = tid;

                tid++;

                BillingWrappers.GWDiscountValue gvalue = new BillingWrappers.GWDiscountValue();
                gvalue.value = cd.Discount__c;
                gtemp.values.put(cd.Duration__c, gvalue);

                gdisc.discountTemplates.add(gtemp);
            }

            gcont.discounts.add(gdisc);
            result.add(gcont);
        }

        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(result));
    }

    public static Contract__c selectContract(BillingWrappers.QuotePackageInfo pInfo) {
        Contract__c accountContract;

        if (pInfo == null || pInfo.contract == null || pInfo.contract.id == null) {
            return accountContract;
        }

        List<Contract__c> contracts = new BillingContractSelector()
            .selectContractWithDiscountsById(pInfo.contract.id)
            .executeQuery();

        if (!contracts.isEmpty()) {
            accountContract = contracts.get(0);
        }

        return accountContract;
    }

    /* TODO move this helper to Aq lib */
    @TestVisible
    private static HttpResponse makeRequest(String url, String method, String body) {

        if(String.isBlank(url) || String.isBlank(method) || String.isBlank(body)) {
            return null;
        }
        return NGBSAPI.requestNGBS(url, method, body);
    }

    public static HttpResponse createNGBSContract(string accountId, Quote qt) {
        HttpResponse res;

        try {
            CreateContractParams params = new CreateContractParams(qt);
            string url = String.format(
                NGBSAPI.settings.BaseEndpoint + NGBSAPI.settings.AccountManagerPath + '/account/{0}/contract',
                new List<String>{accountId}
            );

            res = makeRequest(url, HttpHelper.METHOD_POST, JSON.serialize(params));
        } catch(Exception e) {
            AquivaHelper.throwAquivaException('Create contract: ' + e.getMessage());
        }

        return res;
    }

    public static HttpResponse updateNGBSContract(string accountId, string contractId, Quote qt) {
        HttpResponse res;

        try {
            UpdateContractParams params = new UpdateContractParams(qt);
                string url = String.format(
                NGBSAPI.settings.BaseEndpoint + NGBSAPI.settings.AccountManagerPath + '/account/{0}/contract/{1}',
                new List<String>{accountId, contractId}
            );
            string method = 'PUT';
            res = makeRequest(url, method, JSON.serialize(params));
        } catch(Exception e) {
            AquivaHelper.throwAquivaException('Update contract: ' + e.getMessage());
        }

        return res;
    }

    public static HttpResponse createPackageDataOnContract(String accountId, String contractId, Quote qt, BillingWrappers.QuotePackageInfo pInfo) {
        HttpResponse res;

        try {
            ContractPackage params = new ContractPackage(qt, pInfo);
            system.debug('params contract package: ' + params);
            string url = String.format(
                NGBSAPI.settings.BaseEndpoint + NGBSAPI.settings.AccountManagerPath + '/account/{0}/contract/{1}/package',
                new List<String>{accountId, contractId}
            );
            res = makeRequest(url, HttpHelper.METHOD_POST, JSON.serialize(params));
        } catch(Exception e) {
            AquivaHelper.throwAquivaException('Create package data on contract: ' + e.getMessage());
        }

        return res;
    }

    public static String getContractDescription(String quoteId, BillingWrappers.QuotePackageInfo pInfo) {
        String result = '';
        if (pInfo == null || pInfo.contract == null) {
            return result;
        }

        Map<String, String> contractInfo = new Map<String, String>{
            'salesAgreement'    => quoteId,
            'contractExtId'     => String.valueOf(pInfo.contract.extId)
        };

        result = JSON.serialize(contractInfo);

        return result;
    }

    public static BillingWrappers.BillingContract getActiveContract(List<BillingWrappers.BillingContract> billingContracts) {
        for (BillingWrappers.BillingContract bc : billingContracts) {
            if (bc.isActiveContract()) {
                return bc;
            }
        }
        return null;
    }

    public static Boolean hasActiveContract(List<BillingWrappers.BillingContract> billingContracts) {
        return getActiveContract(billingContracts) != null;
    }

    public virtual class ContractParams {
        public Integer term; // (int32)
        public Integer renewalTerm; // (int32)
        public Boolean autoRenewal;
        public String description;
        public ContractPackage[] packages;
        /*
            Quote:
                Initial_Term_months__c,
                Term_months__c,
                Auto_Renewal__c,
                QuoteLineItems,
        */
        public ContractParams() {}      
        public ContractParams(Quote qt) {
            BillingWrappers.QuotePackageInfo pInfo;
            if (!String.isBlank(qt.Package_Info__c)) {
                pInfo = new BillingWrappers.QuotePackageInfoWrapper(qt.Package_Info__c).getPackageInfo();
            }

            if (qt.UpdateContractTerms__c) {
                this.autoRenewal = qt.Auto_Renewal__c;
                this.renewalTerm = qt?.Term_months__c != null ? Integer.valueOf(qt.Term_months__c) : 0;
                this.term = qt?.Initial_Term_months__c != null ? Integer.valueOf(qt.Initial_Term_months__c) : null;
            }

            this.description = getContractDescription(qt.id, pInfo);
            this.packages = getPackages(qt);
        }

        /*
            QuoteLineItem:
                PackageInfo__c,
                Product2.ExtID__c,
        */
        

       

        virtual ContractPackage[] getPackages(Quote qt) {
            ContractPackage[] result = new List<ContractPackage>();

            if (String.isBlank(qt.Package_Info__c)) {
                return result;
            }
            List<BillingWrappers.QuotePackageInfo> quotePackageInfos = QuoteHelper.getPackageInfoList(qt);

            for (BillingWrappers.QuotePackageInfo pInfo : quotePackageInfos) {
                result.add(getPackage(qt, pInfo));
            }
            return result;
        }

        virtual ContractPackage getPackage(Quote qt,BillingWrappers.QuotePackageInfo pInfo) {
            ContractPackage cp = new ContractPackage(qt,pInfo);
            return cp;
        }
    }

   

  

    public static string convertToUTCString(Date d) {
        return DateTime.newInstance(d, Time.newInstance(0,0,0,0))
                        .format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
    }

    public virtual class CreateInterimContractParams extends CreateContractParams {

        public CreateInterimContractParams(Quote qt) {
            super(qt);
            this.description = 'Interim contract in addition to Target Contract for synching FSC during Cross-Product Upgrade';
        }

        override virtual List<ContractPackage> getPackages(Quote qt) {
            List<InterimContractPackage> result = new List<InterimContractPackage>();

            if (String.isBlank(qt.Package_Info__c)) {
                return result;
            }
            List<BillingWrappers.QuotePackageInfo> quotePackageInfos = QuoteHelper.getPackageInfoList(qt);

            for (BillingWrappers.QuotePackageInfo pInfo : quotePackageInfos) {
                InterimContractPackage icp = new InterimContractPackage(qt, pInfo);

                result.add(icp);
            }
            system.debug('result interim contract package: ' + result);
            return result;
        }

      

    }

    public virtual class CreateContractParams extends ContractParams {
        public string startDate; // (date)
        public NGBS_Discount.DiscountTemplateGroup[] discounts;

        public CreateContractParams(Quote qt) {
            super(qt);

            if(String.isBlank(qt.Initial_Term_months__c)) {
                AquivaHelper.throwAquivaException('initial term can not be empty');
            }
            if(String.isBlank(qt.Term_months__c) && qt.Auto_Renewal__c) {
                AquivaHelper.throwAquivaException('renewal term can not be empty');
            }
            if(qt.Start_Date__c == null) {
                AquivaHelper.throwAquivaException('start date can not be empty');
            }

            BillingWrappers.QuotePackageInfo pInfo = new BillingWrappers.QuotePackageInfoWrapper(qt.Package_Info__c).getPackageInfo();

            this.term = Integer.valueOf(qt.Initial_Term_months__c);
            this.renewalTerm = String.isNotBlank(qt.Term_months__c) ? Integer.valueOf(qt.Term_months__c) : 0;
            this.autoRenewal = qt.Auto_Renewal__c;
            this.startDate = convertToUTCString(qt.Start_Date__c);
            this.description = getContractDescription(qt.id, pInfo);
            this.discounts = new List<NGBS_Discount.DiscountTemplateGroup>();
        }
    }

    public class UpdateContractParams extends ContractParams {
        public UpdateContractParams(Quote qt) {
            super(qt);
        }
    }

    public class ResyncContractParams extends ContractParams {
        public ResyncContractParams(Quote qt) {
            super(qt);

            if (String.isBlank(qt.Initial_Term_months__c)) {
                AquivaHelper.throwAquivaException('initial term cannot be empty');
            }
            if(String.isBlank(qt.Term_months__c) && qt.Auto_Renewal__c) {
                AquivaHelper.throwAquivaException('renewal term can not be empty');
            }

            this.term = Integer.valueOf(qt.Initial_Term_months__c);
            this.renewalTerm = String.isNotBlank(qt.Term_months__c) ? Integer.valueOf(qt.Term_months__c) : 0;
            this.autoRenewal = qt.Auto_Renewal__c;
        }
    }

    public class ContractualLicense {
        public Integer id; // (int64)
        public String catalogId;
        public Integer contractualQty; // (int64)
    }

    public class TargetPackage {
        public String value;
    }

    public virtual class InterimContractPackage extends ContractPackage {
       public InterimContractPackage(Quote qt,BillingWrappers.QuotePackageInfo pInfo) {
        super(qt,pInfo);
        this.licenses = new List<ContractualLicense>();

        // Use existing package target for interim contract
        this.target = getTargetPackage(pInfo);
       }

       override virtual TargetPackage getTargetPackage(BillingWrappers.QuotePackageInfo pInfo) {
        TargetPackage target = new TargetPackage();
        if (pInfo != null && pInfo.existingPackageInfo != null) {
            target.value = pInfo.existingPackageInfo.productName;
        }
        return target;
        }
   }

    public virtual class ContractPackage {
        public String packageId;
        public String packageVersion;
        public TargetPackage target;
        public ContractualLicense[] licenses;
        public SubscriberInfoBuilder.ELASettings licenseAgreementSettings;
        public String description;
    
        public ContractPackage(Quote qt,BillingWrappers.QuotePackageInfo pInfo) {
            system.debug('pInfo: ' + pInfo);
            this.packageId = pInfo.packageInfo.id;
            this.packageVersion = pInfo.packageInfo.version;
            this.description = getContractDescription(qt.id, pInfo);
            this.licenses = getLicenses(qt.QuoteLineItems);

            if (QuoteHelper.isCrossUpgrade(qt)) {
                this.target = getTargetPackage(pInfo);
            }

            // Set ELA settings if applicable
            if (AccountHelper.ACCOUNT_TYPE_ELA_SERVICE == qt.Account.ELA_Account_Type__c
                && Feature_Toggle__c.getInstance().Enable_ELA_Phase_2__c) {
                this.licenseAgreementSettings = new SubscriberInfoBuilder.ELASettings(qt.QuoteLineItems);
            }
        }

     virtual ContractualLicense[] getLicenses(QuoteLineItem[] qlis) {
            ContractualLicense[] result = new List<ContractualLicense>();

            if(qlis == null){
                return result;
            }

            for (QuoteLineItem qli : qlis) {
                if (qli.Product2.ExtID__c != Product2Helper.DL_UNL_ELEMENT_ID && qli.Product2.ExtID__c != Product2Helper.EVNT_EO_2589005) {
                    continue;
                }

                BillingWrappers.QLIPackageInfo qliPackageInfo = (BillingWrappers.QLIPackageInfo)
                    JSON.deserialize(qli.PackageInfo__c, BillingWrappers.QLIPackageInfo.class);

                if (qliPackageInfo.q != null) {
                    ContractualLicense cl = new ContractualLicense();
                    cl.CatalogId = qli.Product2.ExtID__c;
                    cl.ContractualQty = qliPackageInfo.q;
                    result.add(cl);
                }
            }

            return result;
        }

        virtual TargetPackage getTargetPackage(BillingWrappers.QuotePackageInfo pInfo) {
            TargetPackage target = new TargetPackage();
            if(pInfo == null) {
                return target;
            }
            target.value = pInfo.productName;
            return target;
        }

        virtual String getContractDescription(String quoteId, BillingWrappers.QuotePackageInfo pInfo) {
            return ContractRestAPI.getContractDescription(quoteId, pInfo);
        }
    }
}