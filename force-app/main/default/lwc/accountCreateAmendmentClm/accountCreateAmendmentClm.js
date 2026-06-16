import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';

import ACCOUNT_NAME_FIELD from '@salesforce/schema/Account.Name';
import ACCOUNT_BRAND_FIELD from '@salesforce/schema/Account.RC_Brand__c';
import ACCOUNT_BILLING_COUNTRY_FIELD from '@salesforce/schema/Account.BillingCountry';

import getEndpointsSettings from '@salesforce/apex/SettingsHelper.getEndpointsSettings';
import getBrandToAllowedCountryMapping from '@salesforce/apex/SettingsHelper.getBrandToAllowedCountryMapping';
import getPrimaryContactRoleByAccountId from '@salesforce/apex/AccountContactRoleHelper.getPrimaryContactRoleByAccountId';

const ACC_FIELDS = [
    ACCOUNT_NAME_FIELD,
    ACCOUNT_BRAND_FIELD,
    ACCOUNT_BILLING_COUNTRY_FIELD
];

export default class AccountCreateAmendmentClm extends LightningElement {
    @api recordId;

    @wire(getRecord, { recordId: '$recordId', fields: ACC_FIELDS })
    account;

    @wire(getPrimaryContactRoleByAccountId, { accountId: '$recordId' })
    primaryContactRole;

    @api invoke() {
        const initialToastTitle = this.getInitialToastTitle();
        const initialToastMessage = this.getInitialToastMessage();

        if (Boolean(initialToastTitle)) {
            const toastEvt = this.generateErrorToast(initialToastTitle, initialToastMessage);
            this.dispatchEvent(toastEvt);
            return;
        }

        this.processBrandAndEnpointSettings();
    }

    get accName() {
        return this.account.data.fields.Name.value;
    }

    get accBrand() {
        return this.account.data.fields.RC_Brand__c.value;
    }

    get accBillingCountry() {
        return this.account.data.fields.BillingCountry.value;
    }

    getInitialToastTitle() {
        if (!this.accBrand && !this.accBillingCountry) {
            return "Fill in the Brand and Billing Country fields for this Account";
        }
        if (!this.accBrand) {
            return "Fill in the Brand field for this Account";
        }
        if (!this.accBillingCountry) {
            return "Fill in the Billing Country field on this Account";
        }
        if (!this.primaryContactRole.data) {
            return "Please add a Primary Signatory Contact Role on the Account";
        }
    }

    getInitialToastMessage() {
        return 'Contact Deal Desk for any questions.';
    }

    getConfigUrl() {
        const configURL = "/doclauncher/eos/Amendment_Assignment_Name%20Change_Other_Account?aid=CLMAccountId&eos[0].Id="
            + this.recordId
            + "&eos[0].System=Salesforce&eos[0].Type=Account&eos[0].Name="
            + this.accName
            + "%20-%20"
            + this.recordId
            + "%20&eos[0].ScmPath=/Salesforce/Accounts"

        return configURL;
    }

    processBrandAndEnpointSettings() {
        getBrandToAllowedCountryMapping({})
            .then(mapping => {
                if (!mapping) {
                    const toastEvt = this.generateErrorToast(
                        "Brand To Allowed Country Mapping is not populated",
                        this.getInitialToastMessage()
                    );
                    this.dispatchEvent(toastEvt);
                    return;
                }

                const mappingParsed = JSON.parse(mapping);
                const currentBrandMapping = mappingParsed.filter(m => m.BrandName__c === this.accBrand)[0];

                if (!currentBrandMapping) {
                    const toastEvt = this.generateErrorToast(
                        "Please validate the Brand on this Account",
                        this.getInitialToastMessage()
                    );
                    this.dispatchEvent(toastEvt);
                    return;
                }

                if (!currentBrandMapping.AllowedCountries__c.split(';').includes(this.accBillingCountry)) {
                    const toastEvt = this.generateErrorToast(
                        "Please validate the Brand and Billing Country on this Account",
                        this.getInitialToastMessage()
                    );
                    this.dispatchEvent(toastEvt);
                    return;
                }

                getEndpointsSettings({})
                    .then(es => {
                        if (!es.DocuSign_CLM_Endpoint__c) {
                        const toastEvt = this.generateErrorToast("CLM Endpoint is not populated", "Please contact IT Support.");
                        this.dispatchEvent(toastEvt);
                        } else {
                            const clmAmendmentConfigURL = this.getConfigUrl();
                            const clmInstanceURL = es.DocuSign_CLM_Endpoint__c.replace(/\/*$/, "");
                            window.open(clmInstanceURL + clmAmendmentConfigURL.replace('CLMAccountId', es.DocusignCLMAccountId__c), '_blank');
                        }
                    })
                    .catch(error => {
                        const toastEvt = this.generateErrorToast("Couldn't open CLM NDA generation", "Please contact IT Support.");
                        this.dispatchEvent(toastEvt);
                    });
            });
    }

    generateErrorToast(title, message) {
        return new ShowToastEvent({
            title: title,
            message: message,
            variant: "error",
            mode: "sticky",
        });
    }
}