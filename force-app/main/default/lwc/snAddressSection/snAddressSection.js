import { LightningElement, api, track} from 'lwc';

export default class SnAddressSection extends LightningElement {
  country;
  state;
  zip;
  city;
  address1;
  address2 = "";
  countryOptions;
  stateOptions;
  isAddressValidated;
  @api disableGeneralFields;
  @api serviceSignedUp;
  @api 
  get enableValidateButton() {
    return this._enableValidateButton;
  };

  set enableValidateButton(isEnabled) {
    this._enableValidateButton = isEnabled;
    this.isAddressValidated = false;
    window.dispatchEvent(new CustomEvent('AddressChanged'));
  }
  _enableValidateButton;

  countriesToMatch = [];
  @track invalidElements = [];

  @api
  get countries() {
    return this.countriesToMatch;
  }

  set countries(value) {
    if (value) {
      this.countriesToMatch = value;
      this.countryOptions = this.countriesToMatch.map(c => (
        {
          label: c.name,
          value: c.code 
        }
      ));

      this.populateSuggestedAddress();
    }
  }
  _suggestedAddress;
  @api
  get suggestedAddress() {
    return this._suggestedAddress;
  }

  set suggestedAddress(value) {
    this._suggestedAddress = value;
    this.populateSuggestedAddress();
  }

  get isGeneralFieldsEmpty() {
    const isStateNotRequired = this.isStatesEmpty || this.state;
    const isAddressPopulated = this.country && this.zip && this.city && this.address1 && isStateNotRequired;
    return !(isAddressPopulated);
  }

  get containerClass() {
    return "box slds-m-right_x-small slds-grid slds-grid_vertical-align-start " + (this.invalidElements.length === 0 ? "" : "slds-m-bottom_small");
  }

  checkValidity(event) {
    let element = this.template.querySelector(`[data-id="${event.target.dataset.id}"]`);
    if (!element.checkValidity() && !this.invalidElements.includes(element)) {
      this.invalidElements.push(element);
    }
    if (element.checkValidity() && this.invalidElements.length > 0) {
      this.invalidElements = this.invalidElements.filter(el => el !== element);
    }
  }

  get generalInfoDisabled() {
    return this.serviceSignedUp || this.disableGeneralFields;
  }

  get disabledStates() {
    return this.generalInfoDisabled || this.isStatesEmpty;
  }

  get disabledCountries() {
    return this.generalInfoDisabled || this.isCountriesLoading;
  }

  get isCountriesLoading() {
    return this.countriesToMatch.length === 0;
  }

  get countryLoadingPlaceholder() {
    return this.isCountriesLoading ? 'loading...' : 'Select country';
  }

  get isStatesEmpty() {
    return !this.stateOptions || this.stateOptions.length === 0;
  }

  get isStatesNotEmpty() {
    return !this.isStatesEmpty;
  }

  get statePlaceholder() {
    return this.isStatesEmpty ? '' : 'Select state';
  }

  get disableValidateButton() {
    return !this.enableValidateButton || this.generalInfoDisabled
           || this.isGeneralFieldsEmpty || this.isAddressValidated;
  }

  handleAddressValue1(event) {
    this.address1 = event.detail.value;
    this.enableValidateButton = true;
  }

  handleAddressValue2(event) {
    this.address2 = event.detail.value;
    this.enableValidateButton = true;
  }

  handleCountryValue(event) {
    this.country = event.detail.value;
    this.enableValidateButton = true;
    this.getStatesPicklist();
  }

  handleStateValue(event) {
    this.state = event.detail.value;
    this.enableValidateButton = true;
  }

  handleZipValue(event) {
    this.zip = event.detail.value;
    this.enableValidateButton = true;
  }

  handleCityValue(event) {
    this.city = event.target.value;
    this.enableValidateButton = true;
  }

  getStatesPicklist() {
    this.state = null;
    this.stateOptions = this.countriesToMatch
      .find(c => c.code === this.country).states
      .map(s => (
        {
          label: s.name,
          value: s.name
        }
      ));
  }

  populateSuggestedAddress() {
    if (!this._suggestedAddress) {
        return;
    }
    const bAddress = this._suggestedAddress;
    const matchedCountry = this.findCountry(bAddress.country);
    const matchedState = this.findState(bAddress.state, matchedCountry?.states);

    this.stateOptions = matchedCountry?.states?.map(s => (
      {
        label: s.name,
        value: s.name
      }
    ));
    this.country = matchedCountry?.code;
    this.state = matchedState?.name;
    this.zip = bAddress.zip;
    this.city = bAddress.city;
    this.address1 = bAddress.address1;
    this.address2 = bAddress.address2;
  }

  onValidate() {
    this.isAddressValidated = true;
    window.dispatchEvent(new CustomEvent('ValidateAddressProcessOrder', {
      detail: {
        address1: this.address1,
        address2: this.address2,
        country: this.country, 
        city: this.city,
        state: this.state,
        zip: this.zip,
        skipValidation: true
      }
    }));
  }

  findCountry(value) {
        if (!value || this.isCountriesLoading) {
            return value;
        }
        let country = this.countriesToMatch.find(c => c.name.toUpperCase() === value.trim().toUpperCase());
        if (!country) {
            country = this.countriesToMatch.find(c => c.code.toUpperCase() === value.trim().toUpperCase());
        }
        if (!country) {
            country = this.countriesToMatch.find(c => c.codeAlpha2.toUpperCase() === value.trim().toUpperCase());
        }
        if (!country) {
            country = this.countriesToMatch.find(c => (typeof c.abbreviation) === 'string' && c.abbreviation.toUpperCase() === value.trim().toUpperCase());
        }
        if (!country) {
            country = this.countriesToMatch.find(c => c.id.toString().toUpperCase() === value.trim().toUpperCase());
        }
        return country;
    }

    findState(value, states) {
        if (!value || !states || states.length === 0) {
            return value;
        }
        let state = states.find(c => c.name.toUpperCase() === value.trim().toUpperCase());
        if (!state) {
            state = states.find(c => c.code?.toUpperCase() === value.trim().toUpperCase());
        }
        return state;
    }
}