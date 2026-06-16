({
    isValidAndSave: function (component, event, helper) {
        let accountId = component.get('v.accountId');
        let accVATNumber = component.get('v.accVATNumber').trim();
        let countryCode = component.get('v.countryCode');
        let vatCountry = (countryCode && countryCode.CountryNameShort__c) ? countryCode.CountryNameShort__c : null;
        let brand = component.get('v.brand');

        if (accVATNumber && vatCountry !== 'CH') {
            let action = component.get("c.validateVATNumber");
            action.setParams({
                'VATCountry': vatCountry,
                'VATNumber': accVATNumber,
                'brand' : brand
            });

            action.setCallback(this, function (response) {
                let state = response.getState();
                let result = response.getReturnValue();
                if (state === 'SUCCESS') {
                     if (result && result.data && result.data.isValid) {
                        helper.saveVATNumber(component, helper, accountId, accVATNumber, vatCountry);
                    } else {
                        component.set('v.errorMessage', result.data.error);
                        helper.showMessage(component, false, true);
                    }
                } else {
                    helper.showMessage(component, false, true);
                }
            });
            $A.enqueueAction(action);
        } else if (accVATNumber === '') {
            helper.saveVATNumber(component, helper, accountId, accVATNumber, vatCountry);
        }
    },

    showMessage: function (component, isValid, isShowMessage) {
        component.set('v.isValid', isValid);
        component.set('v.isShowMessage', isShowMessage);
        if (!isValid) {
            component.set('v.isDisablesSave', false);
            component.set('v.isDisablesValidate', false);
            component.set('v.cssStyle', 'slds-has-error');
        } else {
            component.set('v.cssStyle', 'slds-has-success');
        }
    },

    getCountryCode: function (component, event, helper, country) {
        if (country) {
            let action = component.get("c.getCountryCodeSetting");
            action.setParams({
                'country': country
            });

            action.setCallback(this, function (response) {
                let state = response.getState();
                let countryCode = response.getReturnValue();
                if (state === 'SUCCESS') {
                    component.set('v.countryCode', countryCode);

                    if (!countryCode) {
                        component.set('v.validationMethod', '');
                    } else if (!countryCode.VATNumbersByName__c) {
                        component.set('v.validationMethod', $A.get('$Label.c.VatNumberInfoNotAvailableCountry'));
                    } else if (!countryCode.CountryNameShort__c) {
                        component.set('v.validationMethod', $A.get('$Label.c.VatNumberInfoNotSetAlpha2Country'));
                    } else {
                        component.set('v.isVATCountry', true);
                        let fullVatNumber = component.get('v.fullVATNumber');
                        if (fullVatNumber && !fullVatNumber.toUpperCase().startsWith(countryCode.CountryNameShort__c, 0)) {
                            component.set('v.accVATNumber', fullVatNumber);
                        }
                    }
                } else {
                    component.set('v.validationMethod', $A.get('$Label.c.VatNumberErrUnexpectedError'));
                }
            });
            $A.enqueueAction(action);
        } else {
            component.set('v.validationMethod',  $A.get('$Label.c.VatNumberInfoNotValidBillingAddress'));
        }
    },

    saveVATNumber: function (component, helper, accountId, accVATNumber, vatCountry) {
        let action = component.get("c.saveVATNumber");
        let billingId = component.get('v.billingId');

        action.setParams({
            'accountId': accountId,
            'VATNumber': accVATNumber,
            'VATCountry': vatCountry,
        });

        action.setCallback(this, function (response) {
            let state = response.getState();
            let result = response.getReturnValue();
            let isShowMessage = (accVATNumber !== '');
            if (state === 'SUCCESS') {
                if (result && result.data && result.data.errorMessage && result.data.errorMessage !== '') {
                    component.set('v.errorMessage', result.data.errorMessage);
                    helper.showMessage(component, false, isShowMessage);
                } else {
                    if (billingId !== '' && vatCountry != 'CH' && vatCountry != 'IN') {
                        helper.sendVATNumberToNGBS(component, helper, billingId, accVATNumber, vatCountry);
                    } else {
                        helper.showMessage(component, true, isShowMessage);
                    }
                }
            } else {
                component.set('v.errorMessage', helper.constants.UNEXPECTED_ERROR_MESSAGE);
                helper.showMessage(component, false, isShowMessage);
            }
        });
        $A.enqueueAction(action);
    },

    sendVATNumberToNGBS: function (component, helper, billingId, accVATNumber, vatCountry) {
        let action = component.get("c.updateVatNumberInBilling");
        action.setParams({
            'VATCountry': vatCountry,
            'VATNumber': accVATNumber,
            'billingId': billingId,
        });
        action.setCallback(this, function (response) {
            let state = response.getState();
            let result = response.getReturnValue();
            let isShowMessage = (accVATNumber !== '');
            if (state === 'SUCCESS') {
                if (result && result.data && result.data.errorMessage && result.data.errorMessage !== '') {
                    component.set('v.errorMessage', result.data.errorMessage);
                    helper.showMessage(component, false, isShowMessage);
                } else {
                    helper.showMessage(component, true, isShowMessage);
                }
            } else {
                component.set('v.errorMessage', $A.get('$Label.c.VatNumberErrUnexpectedError'));
                helper.showMessage(component, false, isShowMessage);
            }
        });
        $A.enqueueAction(action);
    }
});