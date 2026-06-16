public class NdaPdfPreviewControllerExtension {
    public final static String ERROR_NO_SIGNATORY_ROLE = 'Please add a contact of type \'Signatory\' to this account.';
    public final static String ERROR_EMPTY_BRAND = '\'Brand\' needs to be populated on the account before an NDA can be generated.';
    public final static String ERROR_BLANK_BILLING_COUNTRY = '\'Billing Country\' needs to be populated on the account before an NDA can be generated.';
    public final static String ERROR_BILLING_COUNTRY_NOT_IN_LIST = 'An NDA cannot be generated because of the billing country tied to this account. Please contact the Sales Desk on this request.';
    public final static String ERROR_RC_BRAND_NOT_IN_LIST = 'An NDA can be generated only for RingCentral Brand at this point. Please contact the Sales Desk on this request.';

    public Boolean showError {get;set;}
    public String errorMessage {get;set;}

    public String billingWizardURL { get; set; }
    public String origin { get; set; }
    public String sId { get; set; }

    private ApexPages.StandardController controller;

    public NdaPdfPreviewControllerExtension(ApexPages.StandardController accountController) {
        billingWizardURL = EndpointsSettingsHandler.uqtServerEndpoint;
        origin = URL.getOrgDomainUrl().toExternalForm();
        sId = SettingsService.getSessionId();

        this.controller = accountController;
        this.showError = false;

        this.errorMessage = getError();
        if (String.isNotBlank(this.errorMessage)) {
            this.showError = true;
        }
    }

    @testVisible
    private String getError() {
        if (signatoryContactRoleNotExist()) {
            return ERROR_NO_SIGNATORY_ROLE;
        } else if (isBrandBlank()) {
            return ERROR_EMPTY_BRAND;
        } else if (isBillingCountryNotPopulatedForRcEu()) {
            return ERROR_BLANK_BILLING_COUNTRY;
        } else if (isBillingCountryNotInPdfList()) {
            return ERROR_BILLING_COUNTRY_NOT_IN_LIST;
        } else if (isBrandNotInRCBrandList()) {
            return ERROR_RC_BRAND_NOT_IN_LIST;
        } else {
            return '';
        }
    }

    private Boolean signatoryContactRoleNotExist() {
        List<AccountContactRole> contactRoles = new AccountContactRoleSelector()
            .newQueryFactory()
            .setCondition('AccountId = \'' + controller.getId() + '\' AND Role = \'Signatory\'')
            .executeQuery();

        return contactRoles.isEmpty();
    }

    private Boolean isBrandBlank() {
        return String.isBlank(((Account) controller.getRecord()).RC_Brand__c);
    }

    private Boolean isBillingCountryNotPopulatedForRcEu() {
        Account acc = (Account) controller.getRecord();

        if (acc.RC_Brand__c == RingCentralHelper.BRAND_RINGCENTRAL_EU) {
            return String.isBlank(acc.BillingCountry);
        } else {
            return false;
        }
    }

    private Boolean isBillingCountryNotInPdfList() {
        Account acc = (Account) controller.getRecord();

        if (acc.RC_Brand__c == RingCentralHelper.BRAND_RINGCENTRAL_EU) {
            List<RC_Quote_Template__c> templates = new RCQuoteTemplateSelector()
                .selectNdaTemplatesByBillingCountryAndBrand(new List<Object> {acc.BillingCountry, RingCentralHelper.BRAND_RINGCENTRAL_EU})
                .executeQuery();

            return templates.isEmpty();
        } else {
            return false;
        }
    }

    private Boolean isBrandNotInRCBrandList() {
        String rcBrandName = ((Account) controller.getRecord()).RC_Brand__c;
        List<String> brandList = new List<String>{
            RingCentralHelper.BRAND_RINGCENTRAL,
            RingCentralHelper.BRAND_RINGCENTRAL_CANADA,
            RingCentralHelper.BRAND_RINGCENTRAL_EU,
            RingCentralHelper.BRAND_RINGCENTRAL_UK,
            RingCentralHelper.BRAND_RINGCENTRAL_AU
        };

        if (!brandList.contains(rcBrandName)) {
            return String.isNotBlank(rcBrandName);
        } else {
            return false;
        }
    }
}