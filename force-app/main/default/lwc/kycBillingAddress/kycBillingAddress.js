import { LightningElement, api, track } from 'lwc';

export default class KycBillingAddress extends LightningElement {
    @api billingAddress;
    @api isFormLocked;
    _isValidStreet;

    connectedCallback() {}

    get city() {
        return this.billingAddress && this.billingAddress.billingCity;
    }
    get country() {
        return this.billingAddress && this.billingAddress.billingCountry;
    }
    get postalCode() {
        return this.billingAddress && this.billingAddress.billingPostalCode;
    }
    get state() {
        return this.billingAddress && this.billingAddress.billingState;
    }
    get street() {
        return this.billingAddress && this.billingAddress.billingStreet;
    }

    @api
    get isValidStreet() {
        return this._isValidStreet;
    }
    set isValidStreet(value) {
        const billingStreetInputCmp = this.template.querySelector('[data-id="billingStreet"]');
        if (!value) {
            billingStreetInputCmp?.setCustomValidity("Maximum street length is exceeded");
            billingStreetInputCmp?.reportValidity();
        } else if (!this._isValidStreet && value) {
            billingStreetInputCmp?.setCustomValidity('');
            billingStreetInputCmp?.reportValidity();
        }
        this._isValidStreet = value;
    }

    onChange(event) {
        let changedAddress = {...this.billingAddress};
        changedAddress[event.target.dataset.id] = event.target.value || '';
        window.app.updateBillingAddress(changedAddress);
    }
}