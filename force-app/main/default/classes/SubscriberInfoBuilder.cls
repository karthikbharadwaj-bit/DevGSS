public with sharing class SubscriberInfoBuilder {
    private static final Feature_Toggle__c featureToggle = Feature_Toggle__c.getInstance();

    SubscriberInfo sInfo = new SubscriberInfo();

    public SubscriberInfoBuilder() {}

    public SubscriberInfoBuilder(
        User user,
        Account acc,
        Contact contact,
        Quote qt,
        AssignmentData[] assignments,
        Map<Id, List<CustomAddressAssignments__c>> addressAssignmentsMap,
        String paymentMethod,
        Boolean isMPUB
    ) {
        sInfo.contactInfo = getContactInfo(acc, contact);
        sInfo.salesAgentInfo = getSalesAgentInfo(user);
        sInfo.LicenseCategories = getLicenseCategories(acc, contact, qt, assignments, addressAssignmentsMap);

        sInfo.billingAddress = isMPUB && QuoteHelper.isEngageOrInContact(qt) && qt.IsMultiProductTechnicalQuote__c ? null : new BillingAddress(acc, contact);

        if (String.isNotEmpty(acc?.ELA_Account_Type__c) && featureToggle.Enable_ELA_Phase_2__c) {
            sInfo.ELAContract = new ELAContractInfo(acc, qt?.QuoteLineItems);
        }

        if (paymentMethod == QuoteHelper.PAYMENT_METHOD_INVOICE
            || paymentMethod == QuoteHelper.PAYMENT_METHOD_INVOICE_ON_BEHALF
            || paymentMethod == QuoteHelper.PAYMENT_METHOD_WHOLESALE
        ) {
            sInfo.billingAccountContactInfo = this.getPayableContactInfo(acc);
        }
    }

    public String getValue() {
        String resultStr = JSON.serialize(sInfo);
        System.debug('SubscriberInfo:' + JSON.serializePretty(sInfo));
        return EncodingUtil.base64Encode(Blob.valueOf(resultStr));
    }

    public ContactInfoRequest getPayableContactInfo(Account acc) {
        String recordType = AccountHelper.isInvoiceOnBehalfAccount(acc)
            ? ApprovalHelper.RT_ID_INVOICE_ON_BEHALF_REQUEST
            : AccountHelper.isWholesaleAccount(acc)
                ? ApprovalHelper.RT_ID_INVOICE_WHOLESALE_REQUEST
                : ApprovalHelper.RT_ID_INVOICING_REQUEST;
        List<Approval__c> invoiceApprovals = (List<Approval__c>) new ApprovalSelector()
            .selectInvoiceApprovalsForPayableInfo(new List<Object>{
                new List<Id>{ recordType },
                new Set<Id>{ acc.Id },
                new List<String>{ ApprovalHelper.STATUS_APPROVED }})
            .executeQuery();

        if (invoiceApprovals.size() > 0) {
            Approval__c lastApprovedApproval = invoiceApprovals.get(0);
            List<Contact> payableContacts = (List<Contact>) new ContactSelector()
                .selectContactById(new List<Object>{ lastApprovedApproval.AccountPayableContact__c })
                .executeQuery();
            if (payableContacts.size() > 0) {
                return new ContactInfoRequest(acc, payableContacts.get(0));
            }
        }
        return null;
    }

    public SubscriberInfo getJsonValue() {
        return sInfo;
    }

    public SubscriberInfo getJsonWithoutZeroLicenses() {
        List<LicenseCategoryRequest> lcrList = new List<LicenseCategoryRequest>();
        for (LicenseCategoryRequest lcr : sInfo.LicenseCategories) {
            List<LicenseRequest> lrList = new List<LicenseRequest>();
            for (LicenseRequest l : lcr.licenses) {
                if (l.qty != 0) {
                    lrList.add(l);
                }
            }
            lcrList.add(new LicenseCategoryRequest(lcr.licenseCategory, lrList));
        }
        sInfo.LicenseCategories = lcrList;
        return sInfo;
    }

    private ContactInfoRequest getContactInfo(Account acc, Contact c) {
        return c != null ? new ContactInfoRequest(acc, c) : null;
    }

    private SalesAgentInfoRequest getSalesAgentInfo(User user) {
        return new SalesAgentInfoRequest(user);
    }

    public LicenseCategoryRequest[] getLicenseCategories(Account acc, Contact contact, Quote qt, AssignmentData[] assignments, Map<Id, List<CustomAddressAssignments__c>> addressAssignmentsMap) {
        List<LicenseCategoryRequest> result = new List<LicenseCategoryRequest>();

        if (assignments == null) {
            return result;
        }

        SCBuilder scBuilder = new SCBuilder();
        DLBuilder dlBuilder = new DLBuilder();
        DLBuilder dlccBuilder = new DLBuilder();
        DLBuilder dliBuilder = new DLBuilder();
        DLBuilder dlbyocBuilder = new DLBuilder();
        OtherBuilder otherBuilder = new OtherBuilder();
        SHIPBuilder shipBuilder = new SHIPBuilder();

        for (AssignmentData ad : assignments) {

            switch on ad.categoryRoot {
                when 'SC' {
                    scBuilder.add(ad);
                }
                when 'DL' {
                    dlBuilder.add(ad, qt.Enabled_LBO__c, addressAssignmentsMap);
                }
                when 'DL-CC' {
                    dlccBuilder.add(ad, qt.Enabled_LBO__c, addressAssignmentsMap);
                }
                when 'DLI' {
                    dliBuilder.add(ad, qt.Enabled_LBO__c, addressAssignmentsMap);
                }
                when 'DL-BYOC' {
                    dlbyocBuilder.add(ad, qt.Enabled_LBO__c, addressAssignmentsMap);
                }
                when else {
                    otherBuilder.add(ad, qt.Enabled_LBO__c, addressAssignmentsMap);
                }
            }
        }

        /* It works only for office */
        if (QuoteHelper.isOfficeService(qt)) {
            shipBuilder.add(acc, contact, addressAssignmentsMap, qt.Enabled_LBO__c);
        }

        if (scBuilder.lcr != null) {
            result.add(scBuilder.lcr);
        }
        if (dlBuilder.lcr != null) {
            result.add(dlBuilder.lcr);
        }
        if (dlccBuilder.lcr != null) {
            result.add(dlccBuilder.lcr);
        }
        if (dliBuilder.lcr != null) {
            result.add(dliBuilder.lcr);
        }
        if (dlbyocBuilder.lcr != null) {
            result.add(dlbyocBuilder.lcr);
        }
        if (shipBuilder.lcr != null) {
            result.add(shipBuilder.lcr);
        }
        result.addAll(otherBuilder.values);

        System.debug(
            'scBuilder:'+
            JSON.serialize(scBuilder.lcr)
        );
        System.debug(
            'dlBuilder:'+
            JSON.serialize(dlBuilder.lcr)
        );
        System.debug(
            'otherBuilder:'+
            JSON.serialize(otherBuilder.values)
        );
        System.debug(
            'shipBuilder:'+
            JSON.serialize(shipBuilder.lcr)
        );

        return result;
    }

    abstract class Builder {}

    class SCBuilder extends Builder {
        public SCBuilder() {}

        LicenseCategoryRequest lcr;

        public void add(AssignmentData ad) {

            if (lcr == null) {
                lcr = new LicenseCategoryRequest(ad.categoryRoot, new List<LicenseRequest>());
            }

            PhoneNumberInfoRequest pnir;
            if (ad.areaCode != null) {
                pnir = new PhoneNumberInfoRequest(ad.areaCode);
            }

            LicenseRequest lr = new LicenseRequest(
                ad.parent.Product2.ExtID__c,
                (Integer) ad.quantity,
                pnir,
                null,
                null,
                null,
                ad.Parent.Product2.ShippingType__c
            );

            lcr.licenses.add(lr);
        }
    }

    @TestVisible
    class DLBuilder extends Builder {
        public DLBuilder() {}

        public LicenseCategoryRequest lcr;

        public void add(AssignmentData ad, Boolean isLBO, Map<Id, List<CustomAddressAssignments__c>> addressAssignmentsMap) {
            List<String> excludeCategoryList = new List<String>{'DL', 'DLI', 'DL-CC', 'DL-BYOC'};
            if (excludeCategoryList.contains(ad.categoryPath)) {
                return;
            }

            List<String> excludeList = new List<String>{'CRF', 'E911', 'DID', 'IVN', 'CRF-CC', 'E911-CC', 'DID-CC'};
            for (String exclude : excludeList) {
                if(ad.categoryPath.containsIgnoreCase(exclude)) {
                    return;
                }
            }

            if (lcr == null) {
                lcr = new LicenseCategoryRequest(ad.categoryRoot, new List<LicenseRequest>());
            }

            if (featureToggle.Shipping_Tab_New_Business__c && !addressAssignmentsMap.isEmpty()) {
                List<LicenseRequest> licensesList = getShippingAssignmentInfo(lcr, ad, addressAssignmentsMap, isLBO);
                lcr.licenses.addAll(licensesList);

                Boolean isNonAssignableLicenseMissed = licensesList.isEmpty() && Product2Helper.NON_ASSIGNABLE_LICENSES.contains(ad.parent.Product2.ExtID__c);
                if (isNonAssignableLicenseMissed) {
                    LicenseRequest lr = buildLicenseRequest(ad, isLBO);
                    lcr.licenses.add(lr);
                }
            } else {
                LicenseRequest lr = buildLicenseRequest(ad, isLBO);
                lcr.licenses.add(lr);
            }
        }

        private LicenseRequest buildLicenseRequest(AssignmentData ad, Boolean isLBO) {
            PhoneNumberInfoRequest pnir;
            if (!isLBO) {
                pnir = new PhoneNumberInfoRequest(ad.areaCode);
            }

            DeviceTypeInfoRequest dtir = new DeviceTypeInfoRequest(ad.child.Product2.ExtID__c, null, ad.child.Product2.ShippingType__c);
            return new LicenseRequest(
                ad.parent.Product2.ExtID__c,
                (Integer) ad.quantity,
                pnir,
                dtir,
                null,
                null,
                ad.parent.Product2.ShippingType__c
            );
        }
    }

    @TestVisible
    class SHIPBuilder extends Builder {
        @TestVisible
        LicenseCategoryRequest lcr;

        public void add(Account acc, Contact contact, Map<Id, List<CustomAddressAssignments__c>> addressAssignmentsMap, Boolean isLBO) {
            if (addressAssignmentsMap.isEmpty() || !featureToggle.Shipping_Tab_New_Business__c) {
                return;
            }

            if (lcr == null) {
                lcr = new LicenseCategoryRequest(Product2Helper.SHIPPING_CATEGORY, new List<LicenseRequest>());
            }

            lcr.licenses.addAll(getShippingAssignmentInfo(lcr, null, addressAssignmentsMap, isLBO));
        }
    }

    class OtherBuilder extends Builder {
        public OtherBuilder() {}

        public Map<String, LicenseCategoryRequest> licenseCategoryRequestMap = new Map<String, LicenseCategoryRequest>();

        public LicenseCategoryRequest[] values {
            get {
                return this.licenseCategoryRequestMap.values();
            }
        }

        public void add(AssignmentData ad, Boolean isLBO, Map<Id, List<CustomAddressAssignments__c>> addressAssignmentsMap) {
            PhoneNumberInfoRequest pnir;

            LicenseCategoryRequest lcr = licenseCategoryRequestMap.get(ad.categoryRoot);
            if (lcr == null) {
                lcr = new LicenseCategoryRequest(ad.categoryRoot, new List<LicenseRequest>());
                licenseCategoryRequestMap.put(ad.categoryRoot, lcr);
            }

            if (ad.areaCode != null && !isLBO) {
                pnir = new PhoneNumberInfoRequest(ad.areaCode);
            }

            if (featureToggle.Shipping_Tab_New_Business__c && Product2Helper.SHIPPING_PHONES.contains(lcr.licenseCategory)) {
                lcr.licenses.addAll(getShippingAssignmentInfo(lcr, ad, addressAssignmentsMap, isLBO));
            } else {
                LicenseRequest lr = new LicenseRequest(
                    ad.parent.Product2.ExtID__c,
                    (Integer) ad.quantity,
                    pnir,
                    null,
                    null,
                    null,
                    ad.parent.Product2.ShippingType__c
                );
                lcr.licenses.add(lr);
            }
        }
    }

    public class PhoneNumberInfoRequest {
        public String areaCode;
        public String city;
        public String country;

        public PhoneNumberInfoRequest(AreaCodeData ac) {
            if (ac != null) {
                this.areaCode = ac.areaCode;
                this.city = ac.city;
                this.country = ac.country;
            }
        }
    }

    public class DeviceTypeInfoRequest {
        public String catalogId;
        public String shippingGroupId;
        public String shippingReq;

        public DeviceTypeInfoRequest(String catalogId, String shippingGroupId, String shippingReq) {
            this.catalogId = catalogId;
            this.shippingGroupId = shippingGroupId;
            this.shippingReq = shippingReq;
        }
    }

    public class ShippingAddress {
        public String zipCode;
        public String companyName;
        public String state;
        public String shippingGroupId;
        public String name;
        public String firstName;
        public String lastName;
        public String country;
        public String city;
        public String addressLine1;
        public String addressLine2;

        public ShippingAddress(
            Account acc,
            Contact contact,
            CustomAddressAssignments__c caa
        ) {
            if (contact == null && caa == null) {
                return;
            }
            if (caa != null) {
                this.zipCode = caa.CustomAddress__r.PostalCode__c;
                this.companyName = caa.QuoteLineItem__r.Quote.Account.Name;
                this.state = caa.CustomAddress__r.State__c;
                this.shippingGroupId = caa.CustomAddress__c;
                this.firstName = caa.AttentionTo__c.split(' ')[0] ;
                this.lastName = caa.AttentionTo__c.split(' ').size() > 1 ? caa.AttentionTo__c.split(' ')[1] : caa.AttentionTo__c.split(' ')[0];
                this.country = caa.CustomAddress__r.Country__c;
                this.city = caa.CustomAddress__r.City__c;
                this.addressLine1 = caa.CustomAddress__r.AddressLine__c;
                this.addressLine2 = caa.CustomAddress__r.AdditionalAddressLine__c;
            } else {
                this.zipCode = acc.BillingPostalCode;
                this.companyName = acc.Name;
                this.state = acc.BillingState;
                this.shippingGroupId = '1';
                this.name = String.isNotBlank(contact.FirstName) ? contact.FirstName + ' ' + contact.LastName : contact.LastName;
                this.firstName = contact.FirstName;
                this.lastName = contact.LastName;
                this.country = acc.BillingCountry;
                this.city = acc.BillingCity;
                this.addressLine1 = acc.BillingStreet;
                this.addressLine2 = '';
            }
        }
    }

    public class LicenseRequest {
        public String catalogId;
        public Integer qty;
        public String shippingGroupId;
        public PhoneNumberInfoRequest[] phoneNumberInfo;
        public DeviceTypeInfoRequest[] deviceTypeInfo;
        public ShippingAddress[] shippingAddress;
        public String shippingReq;

        public LicenseRequest(
            String catalogId,
            Integer qty,
            PhoneNumberInfoRequest phoneNumberInfo,
            DeviceTypeInfoRequest deviceTypeInfo,
            ShippingAddress shippingAddress,
            String shippingGroupId,
            String shippingReq
        ) {
            this.catalogId = catalogId;
            this.qty = qty;
            this.shippingGroupId = shippingGroupId;
            this.shippingReq = shippingReq;
            if (phoneNumberInfo != null) {
                this.phoneNumberInfo = new PhoneNumberInfoRequest[]{phoneNumberInfo};
            }
            if (deviceTypeInfo != null) {
                this.deviceTypeInfo = new DeviceTypeInfoRequest[]{deviceTypeInfo};
            }
            if (shippingAddress != null) {
                this.shippingAddress = new ShippingAddress[]{shippingAddress};
            }
        }
    }

    public class LicenseCategoryRequest {
        public String licenseCategory;
        public LicenseRequest[] licenses;

        public LicenseCategoryRequest(String licenseCategory, LicenseRequest[] licenses) {
            this.licenseCategory = licenseCategory;
            this.licenses = licenses;
        }
    }


    public class AreaCodeData {
        public String areaCode;
        public String city;
        public String country;

        public AreaCodeData(Area_Codes__c ac) {
            this.areaCode = String.valueOf(ac.Area_Code__c);
            this.city = ac.City__c;
            this.country = ac.Country__c;
        }
    }

    public virtual class SubscriberInfo {
        public ContactInfoRequest contactInfo;
        public SalesAgentInfoRequest salesAgentInfo;
        public LicenseCategoryRequest[] LicenseCategories;
        public BillingAddress billingAddress;
        public ELAContractInfo ELAContract;
        public ContactInfoRequest billingAccountContactInfo;
    }

    public class ContactInfoRequest {
        public String firstName;
        public String lastName;
        public String email;
        public String contactPhone;
        public String companyName;

        public ContactInfoRequest(Account acc, Contact c) {
            this.firstName = c.FirstName;
            this.lastName = c.LastName;
            this.email = c.Email;
            this.contactPhone = c.Phone;
            this.companyName = acc.Name;
        }
    }

    public class UsedQuantity {
        private Map<Id, Map<Id, Integer>> usedQuantityMap = new Map<Id, Map<Id, Integer>>();

        public void add(AssignmentLineItem__c ali) {
            if (ali == null) {
                return;
            }
            add(ali.Parent__c, ali.AreaCode__c, ali.Quantity__c);
            add(ali.Child__c, ali.AreaCode__c, ali.Quantity__c);
        }

        public void add(Id qliId, Id acId, Decimal qty) {
            if (usedQuantityMap.get(qliId) == null ) {
                usedQuantityMap.put(qliId, new Map<Id, Integer>());
            }

            Map<Id, Integer> acMap = usedQuantityMap.get(qliId);

            if (acMap.get(acId) == null) {
                acMap.put(acId, 0);
            }

            acMap.put(acId, acMap.get(acId) + (Integer) qty);
        }

        public Integer getQuantity(Id qliId, Id acId) {
            if (
                qliId == null ||
                acId == null ||
                usedQuantityMap.get(qliId) == null ||
                usedQuantityMap.get(qliId).get(acId) == null
            ) {
                return 0;
            }

            return usedQuantityMap.get(qliId).get(acId);
        }
    }

    public class SalesAgentInfoRequest {
        public String salesAgentId;
        public String name;

        public SalesAgentInfoRequest(User u){
            this.salesAgentId = u.Id;
            this.name = u.Name;
        }
    }

    public class AssignmentData {
        public String categoryRoot;
        public String categoryCode;
        public String categoryPath;
        public QuoteLineItem parent;
        public QuoteLineItem child;
        public SubscriberInfoBuilder.AreaCodeData areaCode;
        public Integer quantity;
        public Boolean isLboWithProvisionMixMode = false;

        @TestVisible
        private AssignmentData() {}

        public AssignmentData(AssignmentLineItem__c ali, Map<Id, QuoteLineItem> qliMap, Map<Id, Area_Codes__c> acMap) {
            this.parent = qliMap.get(ali.Parent__c);
            this.child = qliMap.get(ali.Child__c);
            this.areaCode = new SubscriberInfoBuilder.AreaCodeData(acMap.get(ali.AreaCode__c));
            this.quantity = (Integer) ali.Quantity__c;

            this.setCategoryPath(this.parent);
        }

        public AssignmentData(Area_Code_Line_Item__c acli, Map<Id, QuoteLineItem> qliMap, Map<Id, Area_Codes__c> acMap, Integer qty) {
            this.parent = qliMap.get(acli.Quote_Line_Item__c);
            this.areaCode = new AreaCodeData(acMap.get(acli.Area_Code__c));
            this.quantity = qty;

            this.setCategoryPath(this.parent);
        }

        public AssignmentData(QuoteLineItem qli, Map<Id, Area_Codes__c> acMap, Boolean isLBOQuote) {
            this.parent = qli;
            if (isLBOQuote && qli.Quote.AreaCode__c != null) {
                this.areaCode = new AreaCodeData(acMap.get(qli.Quote.AreaCode__c));
            }
            this.quantity = (Integer) qli.NewQuantity__c;

            this.setCategoryPath(this.parent);
        }

        public AssignmentData(QuoteLineItem qli, Decimal remainder) {
            this.parent = qli;
            this.quantity =  (Integer) remainder;
            this.isLboWithProvisionMixMode = true;

            this.setCategoryPath(this.parent);
        }

        public void setCategoryPath(QuoteLineItem qli) {
            BillingWrappers.QLIPackageInfo pInfo = new BillingWrappers.QLIPackageInfo(qli.PackageInfo__c);

            if (String.isBlank(pInfo.categoryCode)) {
                AquivaHelper.throwAquivaException('categoryCode is empty');
            }
            if (String.isBlank(pInfo.categoryPath)) {
                AquivaHelper.throwAquivaException('categoryPath is empty');
            }

            this.categoryCode = pInfo.categoryCode;
            this.categoryPath = pInfo.categoryPath;
            this.categoryRoot = pInfo.categoryPath.split(':').get(0);
        }
    }

    public class BillingAddress {
        public String firstName;
        public String lastName;
        public String addressLine1;
        public String addressLine2;
        public String city;
        public String state;
        public String zipCode;
        public String country;
        public String contactPhone;
        public TaxSettings taxSettings;

        public BillingAddress() {}

        public BillingAddress(Account acc, Contact cont) {
            Map<String, String> countryNameMap = SettingsHelper.getCountryCodesFullName();
            if (cont != null && cont.Id != null) {
                this.firstName = cont.FirstName;
                this.lastName = cont.LastName;
                this.contactPhone = cont.Phone;
            }
            if (acc != null && acc.Id != null) {
                this.addressLine1 = acc.BillingStreet != null ? acc.BillingStreet : null;
                this.city = acc.BillingCity != null ? acc.BillingCity : null;
                this.state = acc.BillingState != null ? acc.BillingState : null;
                this.zipCode = acc.BillingPostalCode != null ? acc.BillingPostalCode : null;
                this.country = acc.BillingCountry != null ? countryNameMap.get(acc.BillingCountry.toLowerCase()) : null;
                String mappedCountry = acc.BillingCountry != null ? countryNameMap.get(acc.BillingCountry.toLowerCase()) : null;
                this.country = mappedCountry != null ? mappedCountry : acc.BillingCountry;
                if (TaxExemptionHelper.isEnabled) {
                    List<Approval__c> taxApprovals = getTaxApprovals(acc.Id);
                    if (!taxApprovals.isEmpty()) {
                        this.taxSettings = new TaxSettings(taxApprovals);
                    } else {
                        /* Not allowed to send "taxSettings: null" in SAF/CCB/ICB */
                        String vatNumber = null;
                        String gstNumber = null;
                        if (TaxExemptionHelper.isIndiaCountry(acc.BillingCountry)) {
                            gstNumber = acc.VATNumber__c;
                        } else {
                            if (SettingsService.isSwitzerland(acc.BillingCountry) && acc.VATNumber__c != null) {
                                vatNumber = trimCountryCodeFromVatNumber(acc.VATNumber__c, acc.BillingCountry);
                            } else {
                                vatNumber = acc.VATNumber__c;
                            }
                        }
                        this.taxSettings = new TaxSettings();
                        this.taxSettings.VATNumber = vatNumber;
                        this.taxSettings.VATExemption = false;
                        this.taxSettings.localTaxExemption = false;
                        this.taxSettings.countyTaxExemption = false;
                        this.taxSettings.federalTaxExemption = false;
                        this.taxSettings.stateTaxExemption = false;
                        this.taxSettings.VATExemptionCountry = vatNumber != null ? this.country : null;
                        this.taxSettings.SEZWOPExemption = false;
                        this.taxSettings.GSTNumber = gstNumber;
                    }
                }
            }
        }

        public String trimCountryCodeFromVatNumber(String vatNumber, String country) {
            Map<String, CountryCodes__c> countryCodes = CountryCodes__c.getAll();

            for (CountryCodes__c countryCode : countryCodes.values()) {
                if (vatNumberStartsWithCountryCode(vatNumber, country, countryCode)) {
                    return vatNumber.substring(countryCode.CountryNameShort__c.length());
                }
            }

            return vatNumber;
        }

        public Boolean vatNumberStartsWithCountryCode(String vatNumber, String country, CountryCodes__c countryCode) {
            return countryCode.CountryNameShort__c != null
                && vatNumber.toLowerCase().startsWith(countryCode.CountryNameShort__c.toLowerCase())
                && countryCode.CountryName__c.containsIgnoreCase(country);
        }
    }

    public class TaxSettings {
        public Boolean countyTaxExemption;
        public Boolean localTaxExemption;
        public Boolean stateTaxExemption;
        public Boolean federalTaxExemption;
        public Boolean VATExemption;
        public String VATNumber;
        public String VATExemptionCountry;
        public Boolean SEZWOPExemption;
        public String GSTNumber;
        public Boolean salesTaxExemption;

        public TaxSettings(){}

        public TaxSettings(List <Approval__c> taxApprovals) {
            Approval__c app = taxApprovals.get(0);
            NGBSAPI.TaxExemption taxSettings = new NGBSAPI.TaxExemption();
            Map<String, String> countryNameMap = SettingsHelper.getCountryCodesFullName();

            taxSettings.setFederalTaxExemption(TaxExemptionHelper.isTaxExemptionActive(app.FederalTaxExemption__c));
            taxSettings.setStateTaxExemption(TaxExemptionHelper.isTaxExemptionActive(app.StateTaxExemption__c));
            taxSettings.setCountyTaxExemption(TaxExemptionHelper.isTaxExemptionActive(app.CountyTaxExemption__c));
            taxSettings.setLocalTaxExemption(TaxExemptionHelper.isTaxExemptionActive(app.LocalTaxExemption__c));
            taxSettings.setVatExemption(TaxExemptionHelper.isTaxExemptionActive(app.VATExemption__c));
            taxSettings.setVatNumber(app.VATNumber__c);
            taxSettings.setSezWopExemption(TaxExemptionHelper.isTaxExemptionActive(app.SEZWOPExemption__c));
            taxSettings.setGstNumber(app.GstNo__c);
            taxSettings.setSalesTaxExemption(TaxExemptionHelper.isTaxExemptionActive(app.SalesTaxExemption__c));
            if (countryNameMap.size() > 0 && app.VATCountry__c != null) {
                taxSettings.setVatCountry(countryNameMap.get(app.VATCountry__c.toLowerCase()));
            }

            this.federalTaxExemption = taxSettings.getFederalTaxExemption();
            this.stateTaxExemption = taxSettings.getStateTaxExemption();
            this.countyTaxExemption = taxSettings.getCountyTaxExemption();
            this.localTaxExemption = taxSettings.getLocalTaxExemption();
            this.VATExemption = taxSettings.getVatExemption();
            this.VATNumber = taxSettings.getVatNumber();
            this.GSTNumber = taxSettings.getGstNumber();
            this.SEZWOPExemption = taxSettings.getSezWopExemption();
            this.salesTaxExemption = taxSettings.getSalesTaxExemption();
            if (countryNameMap.size() > 0) {
                this.VATExemptionCountry = taxSettings.getVatCountry();
            }
        }
    }

    /*
        Assignments
    */
    public static Map<String, AssignmentData[]> getAssignmentsFilterByLimits(
        QuoteLineItem[] qlis,
        Area_Code_Line_Item__c[] aclis,
        AssignmentLineItem__c[] alis,
        Map<Id, QuoteLineItem> qliMap,
        Map<Id, Area_Codes__c> acMap,
        Quote targetQuote,
        Quote proServQuote,
        Quote ccProServQuote,
        String oppBi,
        Boolean hasProServTechQuote
    ) {
        Boolean isLBOQuote = targetQuote.Enabled_LBO__c;
        String productName = BillingWrappers.parseQuotePackageInfo(targetQuote.Package_Info__c)?.productName;

        AssignmentData[] assignments = getAssignments(
            qlis,
            aclis,
            alis,
            qliMap,
            acMap,
            isLBOQuote,
            productName,
            proServQuote,
            ccProServQuote,
            hasProServTechQuote
        );

        /* Specific logic */
        assignments = assignSetupAreaCodes(assignments);

        Map<String, AssignmentData[]> result = filterByLimits(assignments, isLBOQuote, oppBi);
        return result;
    }

    public static AssignmentData[] getAssignments(
        QuoteLineItem[] qlis,
        Area_Code_Line_Item__c[] aclis,
        AssignmentLineItem__c[] alis,
        Map<Id, QuoteLineItem> qliMap,
        Map<Id, Area_Codes__c> acMap,
        Boolean isLBOQuote,
        String productName,
        Quote proServQuote,
        Quote ccProServQuote,
        Boolean hasProServTechQuote
    ) {
        AssignmentData[] result = new List<AssignmentData>();
        UsedQuantity uq = new UsedQuantity();
        Set<Id> assignIdsByAssignment = new Set<Id>();
        Map<Id, Decimal> qliIdToAssignmentQuantitySum = new Map<Id, Decimal>();
        Boolean isUILessMvpWithShipping = featureToggle.Shipping_Tab_New_Business__c
            && featureToggle.EnableUILessProcessOrderMVP__c
            &&  productName == QuoteHelper.NGBS_OFFICE_PRODUCT;

        for (AssignmentLineItem__c ali : alis) {
            result.add(
                new AssignmentData(ali, qliMap, acMap)
            );

            assignIdsByAssignment.add(ali.Parent__c);
            assignIdsByAssignment.add(ali.Child__c);

            uq.add(ali);

            /* qliIdToAssignmentQuantitySum map contains child id/parent id => sum child's quantity */
            if (!qliIdToAssignmentQuantitySum.containsKey(ali.Child__c) && qliIdToAssignmentQuantitySum.containsKey(ali.Parent__c)) {
                qliIdToAssignmentQuantitySum.put(ali.Child__c, ali.Quantity__c);
                qliIdToAssignmentQuantitySum.put(ali.Parent__c, qliIdToAssignmentQuantitySum.get(ali.Parent__c) + ali.Quantity__c);
                continue;
            }
            if (qliIdToAssignmentQuantitySum.containsKey(ali.Child__c) && !qliIdToAssignmentQuantitySum.containsKey(ali.Parent__c)) {
                Decimal sumQuantity = qliIdToAssignmentQuantitySum.get(ali.Child__c) + ali.Quantity__c;
                qliIdToAssignmentQuantitySum.put(ali.Parent__c, ali.Quantity__c);
                qliIdToAssignmentQuantitySum.put(ali.Child__c, sumQuantity);
                continue;
            }
            if (qliIdToAssignmentQuantitySum.containsKey(ali.Child__c) && qliIdToAssignmentQuantitySum.containsKey(ali.Parent__c)) {
                Decimal childSumQuantity = qliIdToAssignmentQuantitySum.get(ali.Child__c) + ali.Quantity__c;
                qliIdToAssignmentQuantitySum.put(ali.Parent__c, qliIdToAssignmentQuantitySum.get(ali.Parent__c) + ali.Quantity__c);
                qliIdToAssignmentQuantitySum.put(ali.Child__c, childSumQuantity);
                continue;
            }
            if (!qliIdToAssignmentQuantitySum.containsKey(ali.Child__c) && !qliIdToAssignmentQuantitySum.containsKey(ali.Parent__c)) {
                qliIdToAssignmentQuantitySum.put(ali.Child__c, ali.Quantity__c);
                qliIdToAssignmentQuantitySum.put(ali.Parent__c, ali.Quantity__c);
                continue;
            }
        }

        Set<Id> assignIdsByACLI = new Set<Id>();
        for (Area_Code_Line_Item__c acli : aclis) {
            Integer usedQty = uq.getQuantity(acli.Quote_Line_Item__c, acli.Area_Code__c);
            Integer remainQty = (Integer) acli.Quantity__c - usedQty;
            if (remainQty == 0) {
                continue;
            }
            result.add(
                new AssignmentData(acli, qliMap, acMap, remainQty)
            );
            assignIdsByACLI.add(acli.Quote_Line_Item__c);
        }

        Set<Id> assignIds = new Set<Id>();
                assignIds.addAll(assignIdsByAssignment);
                assignIds.addAll(assignIdsByACLI);

        if (
            isUILessMvpWithShipping &&
            ((proServQuote != null && proServQuote?.ProServ_Status__c == QuoteHelper.PROSERVSTATUS_SOLD) ||
            (ccProServQuote != null && ccProServQuote?.ProServ_Status__c == QuoteHelper.PROSERVSTATUS_SOLD) ||
            hasProServTechQuote)
        ) {
            qlis = removeShippingDevices(qlis);
        }

        for (QuoteLineItem qli : qlis) {
            if (isUILessMvpWithShipping && !isLBOQuote) {
                if ((assignIds.contains(qli.Id) && qliIdToAssignmentQuantitySum.get(qli.Id) == qli.NewQuantity__c) || qli.Item_type__c == 'Tax') {
                    continue;
                }

                result = buildAssignmentDataForUILessMVP(qli, qliIdToAssignmentQuantitySum, result);
            } else {
                if (assignIds.contains(qli.Id) || qli.Item_type__c == 'Tax') {
                    continue;
                }
                result.add(
                    new AssignmentData(qli, acMap, isLBOQuote)
                );
            }
        }

        return result;
    }

    public static List<AssignmentData> splitAssignment(AssignmentData ad, Integer autoQty, Integer manualQty) {
        AssignmentData auto = ad.clone();
                       auto.quantity = autoQty;
        AssignmentData manual = ad.clone();
                       manual.quantity = manualQty;
        return new List<AssignmentData> {auto, manual};
    }

    public static Map<String, AssignmentData[]> filterByLimits(AssignmentData[] assignments, Boolean isLBOQuote, String oppBi) {
        AssignmentData[] auto = new List<AssignmentData>();
        AssignmentData[] manual = new List<AssignmentData>();


        Map<String, Integer> limitsMap = new Map<String, Integer>();
        Map<String, Boolean> manualUpsellMap = new Map<String, Boolean>();

        for(Funnel_Limits__c fl : Funnel_Limits__c.getAll().values()) {
            if (fl.Only_LBO__c == isLBOQuote) {
                limitsMap.put(fl.Categories__c, (Integer) fl.Quantity__c);
                manualUpsellMap.put(fl.Categories__c, fl.Manual_Upsell__c);
            }
        }

        Map<String, Integer> sumQtyMap = new Map<String, Integer>();

        // ...
        Map<String, String> keyTolimitsMapKey = new Map<String, String>();
        for (String key : limitsMap.keySet()) {
            for (String k : key.split(' ')) {
                keyTolimitsMapKey.put(k, key);
            }
        }

        List<String> bypassLicenses = QuoteLineItemHelper.getLicensesForPurchaseBypass(oppBi);

        for (AssignmentData ad : assignments) {
            String key = keyTolimitsMapKey.get(ad.categoryCode);

            if (key == null || Product2Helper.DL_CATEGORIES.contains(ad.categoryCode)) {
                auto.add(ad);
                continue;
            }

            if (bypassLicenses.contains(ad.parent?.Product2?.ExtID__c)) {
                auto.add(ad);
                continue;
            }

            Integer limitVal = limitsMap.get(key);
            Boolean isManual = manualUpsellMap.get(key);

            if (sumQtyMap.get(key) == null) {
                sumQtyMap.put(key, 0);
            }

            Integer currentQty = ad.quantity;
            Integer prevSumQty = sumQtyMap.get(key);
            Integer nextSumQty = prevSumQty + currentQty;

            if (limitVal > 0 && prevSumQty < limitVal) {
                if(nextSumQty <= limitVal) {
                    auto.add(ad);
                } else {
                    Integer exceed = nextSumQty - limitVal;
                    AssignmentData[] splitted = splitAssignment(ad, currentQty - exceed, exceed);
                    auto.add( splitted.get(0) );

                    if(isManual) {
                        manual.add( splitted.get(1) );
                    }
                }
            } else {
                if(isManual) {
                    manual.add(ad);
                }
            }

            sumQtyMap.put(key, nextSumQty);
        }

        return new Map<String, AssignmentData[]> {
            'auto' => auto,
            'manual' => manual
        };
    }

    public static AssignmentData[] assignSetupAreaCodes(AssignmentData[] assignments) {
        final String SETUP = 'VF T800F';

        for (AssignmentData ad : assignments) {
            if (SETUP.containsIgnoreCase(ad.categoryCode)) {
                List<String> splittedPath = ad.categoryPath.split(':');
                String parentCategoryCode = splittedPath.size() > 2 ? splittedPath.get(1) : splittedPath.get(0);

                for (AssignmentData adInner : assignments) {
                    if (adInner.categoryCode == parentCategoryCode) {
                        ad.areaCode = adInner.areaCode;
                    }
                }
            }
        }

        return assignments;
    }

    public static List<Approval__c> getTaxApprovals (Id accountId) {
        List<Approval__c> approvedApp = new List<Approval__c>();
        approvedApp = (List<Approval__c>) new ApprovalSelector()
            .selectTaxExemptApprovalsInStatuses(new List<Object>{
                accountId,
                new List<String>{ApprovalHelper.STATUS_APPROVED}})
            .addOrdering('CreatedDate', QueryFactory.SortOrder.DESCENDING)
            .executeQuery();

        return approvedApp;
    }

    public class ELAContractInfo {
        public ELALicense[] licenses;
        public ELASettings elaSettings;

        public ELAContractInfo(Account acc, QuoteLineItem[] qlis) {
            if (AccountHelper.isElaService(acc)) {
                this.elaSettings = new ELASettings(qlis);
            } else {
                String[] elaLicenses = UserCustomSettingHelper.getELALicenses();
                this.licenses = new List<ELALicense>();
                for (QuoteLineItem qli : qlis) {
                    if (elaLicenses.contains(qli?.Product_Lic_Id__c)) {
                        this.licenses.add(new ELALicense(qli));
                    }
                }
            }
        }
    }

    public class ELALicense {
        public String catalogId;
        public Integer contractualQty = 0;

        public ELALicense(QuoteLineItem qli) {
            this.catalogId = qli?.Product_Lic_Id__c;
            this.contractualQty = qli?.NewQuantity__c.intValue();
        }
    }

    public class ELASettings {
        public ELASettingsLicenseItem[] licenses = new List<ELASettingsLicenseItem>();

        public ELASettings(QuoteLineItem[] qlis) {
            String[] elaLicenses = UserCustomSettingHelper.getELALicenses();
            for (QuoteLineItem qli : qlis) {
                if (elaLicenses.contains(qli?.Product_Lic_Id__c)) {
                    this.licenses.add(new ELASettingsLicenseItem(qli));
                }
            }
        }
    }

    public class ELASettingsLicenseItem {
        public String catalogId;
        public Integer maxQty = 0;

        public ELASettingsLicenseItem(QuoteLineItem qli) {
            this.catalogId = qli?.Product_Lic_Id__c;
            this.maxQty = qli?.NewQuantity__c.intValue();
        }
    }

    public static List<LicenseRequest> getShippingAssignmentInfo(LicenseCategoryRequest lcr, AssignmentData ad, Map<Id, List<CustomAddressAssignments__c>> addressAssignmentsMap, Boolean isLBO){
        List<LicenseRequest> lrs = new List<LicenseRequest>();
        Integer qty = ad?.quantity != null ? (Integer) ad.quantity : 0;
        for (Id caId : addressAssignmentsMap.keySet()) {
            if (lcr.licenseCategory == Product2Helper.SHIPPING_CATEGORY) {
                Boolean isShippingAvailableForLicense = false;
                for (CustomAddressAssignments__c addressAssignment : addressAssignmentsMap.get(caId)) {
                    if (Product2Helper.isShippingTypeAuto(addressAssignment.QuoteLineItem__r.Product2)) {
                        isShippingAvailableForLicense = true;
                    }
                }
                if (!isShippingAvailableForLicense) {
                    continue;
                }
                ShippingAddress sa = new ShippingAddress(null, null, addressAssignmentsMap.get(caId)[0]);
                lrs.add(
                    new LicenseRequest(
                        addressAssignmentsMap.get(caId)[0].ShippingLicenseTree__c.split(':')[2],
                        1,
                        null,
                        null,
                        sa,
                        null,
                        null
                    )
                );
            } else {
                Integer assignedQty = 0;
                for (CustomAddressAssignments__c caa : addressAssignmentsMap.get(caId)) {
                    BillingWrappers.QLIPackageInfo qliPackage = new BillingWrappers.QLIPackageInfo(caa.QuoteLineItem__r.PackageInfo__c);
                    if (
                        (
                            (
                                String.valueOf(caa?.AssignmentLineItem__r?.AreaCode__r?.Area_Code__c) == ad?.areaCode?.areaCode
                                    && (caa?.AssignmentLineItem__r?.Parent__c == ad.parent.Id || ad?.isLboWithProvisionMixMode)
                                    && !isLBO
                            )
                                || isLBO
                        )
                            && (
                                (qliPackage.categoryCode == lcr.licenseCategory
                                    && ad.parent.Product2.ExtID__c == caa.QuoteLineItem__r.Product_Lic_Id__c)
                                || ad.child.Product2.ExtID__c == caa.QuoteLineItem__r.Product_Lic_Id__c
                                )
                    ) {
                        assignedQty += (Integer) caa.Quantity__c;
                    }
                }
                if (assignedQty > 0) {
                    QuoteLineItem item = isLBO || ad?.isLboWithProvisionMixMode ? ad?.parent : ad?.child;
                    Boolean isShippingAvailableForLicense = Product2Helper.isShippingTypeAuto(item.Product2);
                    Id shippingGroupId = isShippingAvailableForLicense ? caId : null;

                    PhoneNumberInfoRequest pnir;
                    DeviceTypeInfoRequest dtir = new DeviceTypeInfoRequest(null, shippingGroupId, null);
                    if (!ad?.isLboWithProvisionMixMode && !isLBO) {
                        pnir = new PhoneNumberInfoRequest(ad.areaCode);
                        dtir.catalogId = ad.child.Product2.ExtID__c;
                        dtir.shippingReq = ad.child.Product2.ShippingType__c;
                    }
                    lrs.add(
                        new LicenseRequest(
                            ad.parent.Product2.ExtID__c,
                            assignedQty,
                            pnir,
                            dtir,
                            null,
                            shippingGroupId,
                            ad.parent.Product2.ShippingType__c
                        )
                    );
                    qty = qty - assignedQty;
                }
            }
        }
        if (qty > 0) {
            PhoneNumberInfoRequest pnir;
            DeviceTypeInfoRequest dtir;
            if (!ad?.isLboWithProvisionMixMode && !isLBO) {
                pnir = new PhoneNumberInfoRequest(ad.areaCode);
                dtir = new DeviceTypeInfoRequest(ad.child.Product2.ExtID__c, null, ad.child.Product2.ShippingType__c);
            }
            lrs.add(new LicenseRequest(
                ad.parent.Product2.ExtID__c,
                qty,
                pnir,
                dtir,
                null,
                null,
                ad.parent.Product2.ShippingType__c
            ));
        }
        return lrs;
    }

    @TestVisible
    private static AssignmentData[] buildAssignmentDataForUILessMVP(
        QuoteLineItem qli,
        Map<Id, Decimal> qliIdToAssignmentQuantitySum,
        AssignmentData[] result
    ) {
        List<String> catalogIds = new List<String>();
        for (AssignmentData ad: result) {
            catalogIds.add(ad.parent.Product2.ExtID__c);
        }
        BillingWrappers.QLIPackageInfo pInfo = new BillingWrappers.QLIPackageInfo(qli.PackageInfo__c);
        if (Product2Helper.SHIPPING_PHONES.contains(pInfo.categoryCode) || Product2Helper.DL_CATEGORIES.contains(pInfo.categoryCode)) {
            Decimal remainder = qli.NewQuantity__c;
            if (qliIdToAssignmentQuantitySum.containsKey(qli.Id)) {
                remainder = qli.NewQuantity__c - qliIdToAssignmentQuantitySum.get(qli.Id);
            }
            result.add(new AssignmentData(qli, remainder));
        } else if (!catalogIds.contains(qli.Product2.ExtID__c)) {
            result.add(new AssignmentData(qli, null, false));
        }

        return result;
    }

    public static QuoteLineItem[] removeShippingDevices(QuoteLineItem[] qlis) {
        List<QuoteLineItem> filteredQlis = new List<QuoteLineItem>();
        for (QuoteLineItem qli : qlis) {
            BillingWrappers.QLIPackageInfo pInfo = new BillingWrappers.QLIPackageInfo(qli.PackageInfo__c);
            if (!Product2Helper.SHIPPING_PHONES.contains(pInfo.categoryCode)) {
                filteredQlis.add(qli);
            }
        }
        return filteredQlis;
    }
    public static AssignmentLineItem__c[] removeShippingAlis(AssignmentLineItem__c[] alis, Set<Id> filteredQliIds) {
        List<AssignmentLineItem__c> filteredAlis = new List<AssignmentLineItem__c>();
        for (AssignmentLineItem__c ali : alis) {
            if (filteredQliIds.contains(ali.Child__c)) {
                filteredAlis.add(ali);
            }
        }
        return filteredAlis;
    }

    public static Area_Code_Line_Item__c[] removeShippingAclis(Area_Code_Line_Item__c[] aclis, Set<Id> filteredQliIds) {
        List<Area_Code_Line_Item__c> filteredAclis = new List<Area_Code_Line_Item__c>();
        for (Area_Code_Line_Item__c acli : aclis) {
            if (filteredQliIds.contains(acli.Quote_Line_Item__c)) {
                filteredAclis.add(acli);
            }
        }
        return filteredAclis;
    }
}