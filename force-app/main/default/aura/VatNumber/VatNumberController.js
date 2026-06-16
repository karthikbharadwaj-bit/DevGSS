({
    doInit: function (component, event, helper) {
        component.set('v.errorMessage', $A.get("$Label.c.VatNumberErrVatNotValid"));
        component.set('v.successGSTMessage', $A.get("$Label.c.VatNumberInfoGstValid"));
        component.set('v.swissVATMessage1', $A.get("$Label.c.VatNumberInfoSwitzerland1"));
        component.set('v.swissVATMessage2', $A.get("$Label.c.VatNumberInfoSwitzerland2"));
        component.set('v.swissVatIdExemptUrl', '/lightning/r/Account/'+component.get('v.accountId')+'/related/Approvals__r/view');
        component.set('v.isShowMessage', false);

        let billingCountry = component.get('v.billingCountry');
        component.set('v.fullVATNumber', component.get('v.accVATNumber').trim());
        let accVATNumber = component.get('v.accVATNumber').substring(2, component.get('v.accVATNumber').length).trim();
        component.set('v.accVATNumber', accVATNumber);

        helper.getCountryCode(component, event, helper, billingCountry);
    },

    saveClick: function (component, event, helper) {
        component.set('v.isDisablesSave', true);
        component.set('v.isShowMessage', false);
        component.set('v.cssStyle', 'slds-has-selection');
        let accountId = component.get('v.accountId');
        let countryCode = component.get('v.countryCode');
        let accVATNumber = component.get('v.accVATNumber').trim();
        let countryShortName = (countryCode && countryCode.CountryNameShort__c) ? countryCode.CountryNameShort__c : null;
        if (countryCode && countryCode.VATNumbersByName__c === 'GST') {
            accVATNumber = component.get('v.fullVATNumber').trim()
        }
        helper.saveVATNumber(component, helper, accountId, accVATNumber, countryShortName);
    },

    handleClick: function (component, event, helper) {
        component.set('v.isValid', true);
        component.set('v.isShowMessage', false);
        component.set('v.CssStyle', 'slds-has-selection');
        component.set('v.isDisablesSave', true);
        component.set('v.isDisablesValidate', true);
        helper.isValidAndSave(component, event, helper);
    },

    onChange: function (component, event, helper) {
        component.set('v.isDisablesSave', false);
        component.set('v.isDisablesValidate', false);
        component.set('v.isShowMessage', false);
        component.set('v.cssStyle', 'slds-has-selection');
    },

    showSpinner: function (component, event, helper) {
        let spinner = component.find("loadingSpinner");
        $A.util.removeClass(spinner, "slds-hide");
        component.set('v.isLoadSpinner', true);
    },

    hideSpinner: function (component, event, helper) {
        let spinner = component.find("loadingSpinner");
        $A.util.addClass(spinner, "slds-hide");
        component.set('v.isLoadSpinner', false);
    },
});