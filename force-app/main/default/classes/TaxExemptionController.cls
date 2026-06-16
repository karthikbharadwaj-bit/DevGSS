public without sharing class TaxExemptionController {
    public final static String EXEMPT_EXISTS = Label.Tax_Exemptions_Requested;
    public final static String FAILED_TO_UPDATE_APPROVAL = 'Approval update failed';
    public final static String ERROR_MESSAGE_TO_ADMINISTRATOR = 'An error occurred. Please try again later or contact your system administrator.';
    public final static List<String> ignoreVatNumbers = new List<String> {'vatushka!'};

    public class CustomException extends Exception {}

    public TaxExemptionController(ApexPages.StandardController stdController) {}

    @AuraEnabled
    public static List<String> getTaxExemptionOptions() {
        List<String> optionList = new List<String>();

        List<PicklistController.Picklist> optionsWrapper = SFDescribeHelper.getPicklistOptions(
            'Approval__c',
            ApprovalHelper.RT_NAME_TAX_EXEMPT_APPROVAL,
            'CountyTaxExemption__c'
        );
        for (PicklistController.Option option : optionsWrapper[0].Options) {
            if (option.Label != '--None--') {
                optionList.add(option.Label);
            }
        }
        return optionList;
    }

    @AuraEnabled
    public static Response initTaxExemptionPage(String approvalId) {
        Response resp = new Response();

        Approval__c exemptApproval = getApproval(approvalId);
        if (!exemptApproval.SyncWithBillingIsNotRequired__c) {
            TaxExemptionHelper.syncExemptWithNGBS(exemptApproval, true);
            Triggers.switchOff();
            update (new Approval__c(Id = approvalId, SyncWithBillingIsNotRequired__c = true));
            Triggers.switchOn();
        }

        exemptApproval = getApproval(approvalId);
        if (exemptApproval == null) {
            return resp;
        }

        if (exemptApproval != null && String.isBlank(exemptApproval.CountyTaxExemption__c)) {
            if (SettingsService.isSwitzerland(exemptApproval.Account__r.BillingCountry)) {
                exemptApproval.VATCountryForCheck__c = SettingsService.getAlpha2CountryCode(exemptApproval.Account__r.BillingCountry);
            }
            if (SettingsService.isTaiwan(exemptApproval.Account__r.BillingCountry)) {
                exemptApproval.VATCountryForCheck__c = getCountryCode(exemptApproval.Account__r.BillingCountry);
            }
        }
        resp.setData('record', exemptApproval);
        return resp;
    }

    @AuraEnabled
    public static Approval__c getApproval(String approvalId) {
        return TaxExemptionHelper.getApproval(approvalId);
    }

    @AuraEnabled
    public static Response getPermissions() {
        CustomPermissionHelper customPermissions = new CustomPermissionHelper();
        Boolean isTaxTeamMember =
            customPermissions.hasPermission(CustomPermissionHelper.PERMISSION_PROCESS_TAX_EXEMPTIONS);

        Response resp = new Response();
        resp.setData('isTaxTeamMember', isTaxTeamMember);
        return resp;
    }

    /* Approve/Reject request for approval */
    @AuraEnabled
    public static Response setApprovalAction(Approval__c app, Map<String, String> approvalParams) {
        Response resp = new Response();
        Approval__c exemptApproval = (Approval__c) app;

        resp = TaxExemptionHelper.syncExemptWithNGBS(exemptApproval);

        if (resp.data.get('isExemptChangedOnNGBS') != null) {
            resp.setData('record', getApproval(exemptApproval.Id));
            return resp;
        }

        String action = approvalParams.get('action');
        if (!String.isBlank(action)) {
            ApprovalHelper.setApprovalAction(exemptApproval.Id, action);
        }

        resp.setData('record', getApproval(exemptApproval.Id));
        return resp;
    }

    public static void updateApproval(Id approvalId, Map<String, String> exemptionStateParams) {
        if (approvalId != null && Id.valueOf(approvalId).getSObjectType() == Approval__c.getSobjectType()) {
            String VATNumber = exemptionStateParams.get('VATNumber');
            String countryCode = exemptionStateParams.get('VATCountry');
            Approval__c app = new Approval__c(
                Id = approvalId,
                FederalTaxExemption__c = exemptionStateParams.get('federal'),
                StateTaxExemption__c = exemptionStateParams.get('state'),
                CountyTaxExemption__c = exemptionStateParams.get('county'),
                LocalTaxExemption__c = exemptionStateParams.get('local'),
                SalesTaxExemption__c = exemptionStateParams.get('sales'),
                SEZWOPExemption__c = exemptionStateParams.get('indian'),
                VATExemption__c = exemptionStateParams.get('vat'),
                VATNumber__c = (VATNumber != null && VATNumber.startsWithIgnoreCase(countryCode) ? VATNumber.removeStart(countryCode) : VATNumber),
                VATCountryForCheck__c  = exemptionStateParams.get('VATCountry'),
                GstNo__c = exemptionStateParams.get('GSTNumber')
            );
            update app;
        } else {
            throw new CustomException(FAILED_TO_UPDATE_APPROVAL);
        }
    }

    @AuraEnabled
    public static Response saveApproval(sObject app, Map<String, String> exemptionStateParams) {
        Response resp = new Response();
        Approval__c exemptApproval = (Approval__c) app;
        /* For case when approver is not current assigned approver */
        if (Approval.isLocked(exemptApproval.id)) {
            Approval.unlock(exemptApproval.id);
        }

        try{
            updateApproval(exemptApproval.Id, exemptionStateParams);
        } catch(DmlException e){
            throw new CustomException(e.getDmlMessage(0));
        }

        resp.setData('record', getApproval(exemptApproval.Id));
        return resp;
    }

    @AuraEnabled
    public static Response updateVATNumberOnAccount(sObject app){
        Response resp = new Response();
        Approval__c exemptApproval = (Approval__c) app;

        try {
            if (exemptApproval.VATCountryForCheck__c == null || TaxExemptionHelper.isIndiaCountry(exemptApproval.Account__r.BillingCountry)) {
                resp.setData('success', '');
                resp.setData('record', getApproval(exemptApproval.Id));
                return resp;
            }
            TaxExemptionHelper.updateVATNumberOnAccount(new List<Approval__c>{ exemptApproval });
        } catch (AquivaHelper.AquivaException ex) {
            resp.setData('errorMessage', ex.getMessage());
        }
        resp.setData('record', getApproval(exemptApproval.Id));
        return resp;
    }

    @AuraEnabled
    public static Response submitForApproval(sObject app) {

        Response resp = new Response();
        Approval__c exemptApproval = (Approval__c) app;

        resp = TaxExemptionHelper.syncExemptWithNGBS(exemptApproval);

        if (resp.data.get('isExemptChangedOnNGBS') != null) {
            resp.setData('record', getApproval(exemptApproval.Id));
            return resp;
        }

        try {
            TaxExemptionHelper.submitForTaxExemptionApproval(new List<Approval__c>{ exemptApproval });
        } catch(AquivaHelper.AquivaException ex) {
            resp.setData('isMissedEntryCriteria', ex.getMessage());
        }
        resp.setData('record', getApproval(exemptApproval.Id));
        return resp;
    }

    @AuraEnabled
    public static Response validateExemptions(sObject app, Map<String, String> exemptionStateParams) {
        Response resp = new Response();
        Approval__c exemptApproval = (Approval__c) app;

        List<Approval__c> accountApprovals = (List<Approval__c>) new ApprovalSelector()
            .selectTaxExemptApprovalsInStatuses(new List<Object>{
                exemptApproval.Account__c,
                new List<String>{ApprovalHelper.STATUS_PENDING_APPROVAL}})
            .executeQuery();

        Set<String> requestedExempts = new Set<String>();
        for (Approval__c record : accountApprovals) {
            if (record.Id == exemptApproval.Id) {
                continue;
            }
            if (record.FederalTaxExemption__c == exemptionStateParams.get('federal')
                && record.FederalTaxExemption__c == TaxExemptionHelper.REQUESTED) {
                    requestedExempts.add('federal exemption');
            }
            if (record.StateTaxExemption__c == exemptionStateParams.get('state')
                && record.StateTaxExemption__c == TaxExemptionHelper.REQUESTED) {
                    requestedExempts.add('state exemption');
            }
            if (record.CountyTaxExemption__c == exemptionStateParams.get('county')
                && record.CountyTaxExemption__c == TaxExemptionHelper.REQUESTED) {
                    requestedExempts.add('county exemption');
            }
            if (record.LocalTaxExemption__c == exemptionStateParams.get('local')
                && record.LocalTaxExemption__c == TaxExemptionHelper.REQUESTED) {
                    requestedExempts.add('local exemption');
            }
            if (record.VATExemption__c == exemptionStateParams.get('vat')
                && record.VATExemption__c == TaxExemptionHelper.REQUESTED) {
                    requestedExempts.add('vat exemption');
            }
            if (record.SalesTaxExemption__c == exemptionStateParams.get('sales')
                && record.SalesTaxExemption__c == TaxExemptionHelper.REQUESTED) {
                    requestedExempts.add('sales exemption');
            }
        }
        String errorMessage = EXEMPT_EXISTS;
        errorMessage += String.join(new List<String>(requestedExempts), ', ');
        if (errorMessage != EXEMPT_EXISTS) {
            resp.setData('isExemptExist', errorMessage);
        }

        resp.setData('record', getApproval(exemptApproval.Id));
        return resp;
    }

    @AuraEnabled
    public static Boolean isShowVATExemption(String approvalId) {
        Set<String> vatBrands = TaxExemptionHelper.VATBRANDS;
        Set<String> currencyCodes = TaxExemptionHelper.VATCURRENCIES;

        Approval__c exemptApproval = getApproval(approvalId);

        if (exemptApproval == null) {
            return null;
        } else if (exemptApproval.Opportunity__c == null || exemptApproval.Opportunity__r.Brand_Name__c == null) {
            return false;
        } else if (SettingsService.isSwitzerland(exemptApproval.Account__r.BillingCountry)) {
            return true;
        } else if (SettingsService.isTaiwan(exemptApproval.Account__r.BillingCountry)) {
            return true;
        } else if (vatBrands.contains(exemptApproval.Opportunity__r.Brand_Name__c)) {
            return currencyCodes.contains(exemptApproval.Opportunity__r.CurrencyIsoCode);
        }

        return false;
    }

    @AuraEnabled
    public static Boolean isVATFieldsEnabled(String approvalId) {
        Boolean isVATFieldsEnabled = true;
        Approval__c exemptApproval = getApproval(approvalId);
        if (exemptApproval == null) {
            return null;
        }

        return isVATFieldsEnabled;
    }

    @AuraEnabled
    public static Response validateVATNumber(String VATCountry, String VATNumber, String brand) {
        ValidationResult vr = new ValidationResult();
        String endpoint = RingCentralVariousSettings__c.getInstance().GW_Endpoint__c + '/api/projects/ws/saf_auxiliary_services/';
        Response resp = new Response();

        if (String.isBlank(VATCountry)) {
            vr.isValid = false;
            vr.error = 'VAT Country is not defined.';
        }

        if (String.isBlank(VATNumber)) {
            vr.isValid = false;
            vr.error = 'VAT Number is not defined.';
        }

        if (VATCountry != null && VATNumber != null && endpoint != null) {
            String brandContext = brand;
            VATBody body = getVatBody(VATNumber, VATCountry, brandContext);

            try {
                HttpRequest request = new HttpRequest();
                request.setHeader('Content-Type', 'application/json');
                request.setEndpoint(endpoint);
                request.setMethod(HttpHelper.METHOD_POST);
                request.setTimeout(HttpHelper.DEFAULT_TIMEOUT_MS);
                request.setBody(JSON.serializePretty(body));
                HttpResponse res = new Http().send(request);

                vr = getVATValidationResult(res);
            } catch (Exception ex) {
                vr.isValid = false;
                if (ex instanceof NullPointerException) {
                    vr.error = ERROR_MESSAGE_TO_ADMINISTRATOR;
                } else {
                    vr.error = ex.getMessage();
                }
            }
        }

        resp.setData('isValid', vr.isValid);
        resp.setData('error', vr.error);

        return resp;
    }

    public static ValidationResult getVATValidationResult(HttpResponse response) {

        ValidationResult vr = new ValidationResult();
        String jsonResponse = response.getBody();

        if (response.getStatusCode() != 200) {
            vr.isValid = false;
            vr.error = ERROR_MESSAGE_TO_ADMINISTRATOR;
        } else {
            Map<String, Object> jsonValues = (Map<String, Object>)JSON.deserializeUntyped(jsonResponse);
            Map<String, Object> resultMap = (Map<String, Object>)jsonValues.get('result');

            if (resultMap.containsKey('vatNumberStatus')) {
                String vatNumberStatus = resultMap.get('vatNumberStatus').toString();
                switch on vatNumberStatus.toUpperCase() {
                    when 'VALID' {
                        vr.isValid = true;
                        vr.error = '';
                    }
                    when 'NOT_VALID' {
                        vr.isValid = false;
                        vr.error = 'VAT Number is not valid';
                    }
                    when 'SERVICE_NOT_AVAILABLE' {
                        vr.isValid = false;
                        vr.error = 'Service not available';
                    }
                }
            } else {
                vr.isValid = false;
                vr.error = ERROR_MESSAGE_TO_ADMINISTRATOR;
            }
        }
        return vr;
    }

    public class ValidationResult {
        public Boolean isValid {get; set;}
        public String error {get; set;}
    }

    @AuraEnabled
    public static Response saveVATNumber(String accountId, String VATNumber, String VATCountry) {
        Response resp = new Response();
        try {
            String vatNumberToUpdate = null;
            if (String.isNotBlank(VATNumber)) {
                if (VATNumber.startsWithIgnoreCase(VATCountry)) {
                    VATNumber = VATNumber.removeStart(VATCountry);
                }
                vatNumberToUpdate = ignoreVatNumbers.contains(VATNumber) || VATCountry == 'AU'
                    ? VATNumber
                    : VATCountry + VATNumber;
            }

            update new Account(Id = accountId, VATNumber__c = vatNumberToUpdate);

            resp.setData('success', '');
        }  catch (DmlException ex) {
            System.debug(ex.getDmlMessage(0));
            resp.setData('errorMessage', ex.getDmlMessage(0));
        }
        return resp;
    }

    @AuraEnabled
    public static String getCountryCode(String country) {
        return SettingsService.getAlpha2CountryCode(country);
    }

    @AuraEnabled
    public static CountryCodes__c getCountryCodeSetting(String country) {
        return SettingsService.getCountryCodeSetting(country);
    }

    public class VATBody {
        public String method;
        public VatParams params;

    }
    public class VatParams {
        public String vatNumber;
        public String countryCode;
        public String brandContext;
    }

    private static VATBody getVatBody(String vatNumber, String countryCode, String brandContext) {
        TaxExemptionController.VatParams params = new TaxExemptionController.VatParams();
        params.vatNumber = (vatNumber.startsWithIgnoreCase(countryCode)) ? vatNumber.removeStart(countryCode) : vatNumber;
        params.countryCode = countryCode;
        if (brandContext != null) {
            params.brandContext = brandContext;
        }
        TaxExemptionController.VATBody body = new TaxExemptionController.VATBody();
        body.method = 'validation.checkVatNumber';
        body.params  = params;

        return body;
    }

    @AuraEnabled
    public static Response updateVatNumberInBilling(String VATCountry, String VATNumber, String billingId) {
        Response resp = new Response();
        if (billingId != null && String.isNotEmpty(billingId)) {
            String body = VATCountry != null ? prepareVatNumberBody(VATCountry, VATNumber) : TaxExemptionHelper.prepareTaxExemptionBody(null, null, null, null, null, null, null, null, null, VATNumber);
            String endPoint = VATCountry != null ? NGBSAPI.NGBS_ACCOUNT_TAX_EXEMPTION_SETTINGS + '/VATNumber' : NGBSAPI.NGBS_ACCOUNT_TAX_EXEMPTION_SETTINGS;
            try {
                HttpResponse response = NGBSAPI.requestNGBS(
                        String.format(endPoint, new List<String>{
                                billingId
                        }),
                        HttpHelper.METHOD_POST,
                        body,
                        'application/json');
                BillingVatResponse resultResponse = (BillingVatResponse) JSON.deserialize(response.getBody(), BillingVatResponse.class);
                resp.setData('vatNumber', resultResponse.VATNumber);
                resp.setData('vatCountry', resultResponse.VATCountry);
            } catch (Exception e) {
                resp.setData('errorMessage', e.getMessage());
            }
        }

        return resp;
    }

    public static String prepareVatNumberBody(String vatCountry, String vatNumber) {
        JSONGenerator generator = JSON.createGenerator(true);
        generator.writeStartObject();
        if(vatCountry != null && vatNumber != null) {
            generator.writeStringField('VATCountry', vatCountry);
            generator.writeStringField('VATNumber', vatNumber.replace(vatCountry, ''));
        }
        generator.writeEndObject();

        return generator.getAsString();
    }

    public class BillingVatResponse {
        public String VATNumber;
        public String VATCountry;
    }
    @AuraEnabled
    public static Boolean isShowIndianTaxExemption(String approvalId) {
        Approval__c exemptApproval = getApproval(approvalId);
        return  exemptApproval != null
                && exemptApproval.Account__c != null
                && TaxExemptionHelper.isIndiaCountry(exemptApproval.Account__r.BillingCountry);
    }

    @AuraEnabled
    public static Boolean isShowSalesTaxExemption(String approvalId) {
        Approval__c exemptApproval = getApproval(approvalId);
        return  exemptApproval != null
                && exemptApproval.Account__c != null
                && OpportunityHelper.isAmazon(exemptApproval.Opportunity__r);
    }

    @AuraEnabled
    public static Map<String, String> getAttachmentsName(List<Id> attachmentIds) {
        Map<String, String> result = new Map<String, String>();
        List<ContentVersion> cvList = new ContentVersionSelector()
            .selectContentVersionByContentDocumentId(new List<Object>{attachmentIds})
            .executeQuery();

        for (ContentVersion cv: cvList) {
            result.put(String.valueof(cv.ContentDocumentId), cv.Title);
        }
        return result;
    }
}