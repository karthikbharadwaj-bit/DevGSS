import { LightningElement, track, api } from "lwc";

export default class SnAddressValidationWindow extends LightningElement {

    @api isModalOpen;
    @api isInvalidModalOpen;
    @api enteredAddress;
    @track isEnteredAddressChecked = true;
    @track initiallyOpenDropdown;

    _suggestedAddressOptions;
    @api 
    get suggestedAddressOptions() {
        return this._suggestedAddressOptions;
    };

    set suggestedAddressOptions(value) {
        this.isEnteredAddressChecked = !value?.length;
        this.initiallyOpenDropdown = value?.length > 1;

        this._suggestedAddressOptions = value?.map(address => (
            {
              value: JSON.stringify(address),
              label: this.convertAddress(address)
            }
        ));
    }

    closeDropdown() {
        this.initiallyOpenDropdown = false;
    }

    _suggestedAddress;
    get suggestedAddress() {
        return this._suggestedAddress || this.suggestedAddressOptions?.[0]?.value
    };

    set suggestedAddress(value) {
        this._suggestedAddress = value;
    }

    get isSuggestedAddressChecked() {
        return !this.isEnteredAddressChecked;
    }

    get enteredBillingAddress() {
        return this.convertAddress(this.enteredAddress);
    }

    convertAddress(billingAddress) {
        const address1 = billingAddress.address1 + ', ';
        const address2 = billingAddress.address2 ? billingAddress.address2 + ', ' : '';
        const city = billingAddress.city + ', ';
        const state = billingAddress.state ? billingAddress.state + ', ' : '';
        const country = billingAddress.country + ', ';
        const zip = '(' + billingAddress.zip + ')';

        return address1 + address2 + city + state + country + zip;
    }

    handleEnteredAddressCheck() {
        this.isEnteredAddressChecked = true;
    }

    handleSuggestedAddressCheck() {
        this.isEnteredAddressChecked = false;
    }

    handleSuggestedAddress(event) {
        this.suggestedAddress = event.detail.value;
    }

    submitAddress() {
        const selectedAddress = this.isEnteredAddressChecked ? this.enteredAddress : JSON.parse(this.suggestedAddress);
        if (!this.isEnteredAddressChecked) {
            selectedAddress.skipValidation = true;
        }
        this.dispatchEvent(new CustomEvent('validatedaddress', {
            detail: {selectedAddress} 
        }));

        this.resetParams();
    }

    closeModal() {
        this.dispatchEvent(new CustomEvent('closeaddressvalidation'));
        this.resetParams();
    }

    resetParams() {
        this.isEnteredAddressChecked = true;
        this.suggestedAddress = null;
        this.isModalOpen = false;
    }

    get modalWindow() {
        const invalidWindow = this.isInvalidModalOpen ? '-invalid': '';
        return 'slds-modal slds-fade-in-open slds-align_absolute-center main' + invalidWindow;
    }

}