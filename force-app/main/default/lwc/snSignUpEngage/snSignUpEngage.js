import { LightningElement, api } from 'lwc';
import {
  COMPLETED,
  ACTIVE,
  SYNCED,
  READY,
  TIME_ZONE_OPTIONS_ENGAGE,
  LANGUAGE_OPTIONS_ENGAGE,
  PROCESSING,
  ENGAGE_VOICE,
  ERROR,
  BRAND_NAMES,
} from "c/snUtils";
import handleSubmit from '@salesforce/apex/ProcessOrder.handleSubmit';
import getCountries from '@salesforce/apex/CCBAPI.getCountries';
const SLDS_COL = 'slds-col';
const SLDS_RIGHT_MARGIN = 'slds-m-right_medium';
const DROPBOX_VOICE = 'dropbox-voice';
const DROPBOX = 'dropbox';
const INVALID = 'Invalid';
const PLATFORM_LOCATION = 'platform-location';
const DEFAULT_PLATFORM_LOCATION_VALIDATION_ERROR = 'Default location for the specified brand is not identified. Select the eligible location from the list';
const SECTION_HEIGHT_MP = 313;
const SECTION_HEIGHT_MPUB = 222;
const PROGRESS_ITEM_HEIGHT = 94;
export default class SnSignUpEngage extends LightningElement {
  _expanded;
  @api
  get expanded() {
    return this._expanded;
  }

  set expanded(value) {
    this._expanded = value;
    this.calculateSectionHeight();
  }

  @api status;
  @api brandName;
  @api showAddressValidation;
  @api currencyIsoCode;
  _step;
  @api
  get step() {
    return this._step;
  }

  set step(value) {
    if (value === SYNCED && this.isInvalidPlatformLocation) {
      this.engageError = { id: PLATFORM_LOCATION, tier: this.tier };
    }
    this._step = value;
  }

  _engageError;

  @api
  get engageError() {
    this._engageError;
  };

  set engageError(error) {
    if (error?.tier !== this.tier) {
      return;
    }
    switch (error.id) {
      case 'PlatformId':
        this.platformErrorMessage = `${error.id} ${INVALID}`;
        break;
      case 'Domain':
        this._engageError = error.id;
        break;
      case 'platform-location':
        this.addEngageError();
        break;
      default:
        break;
    }
  }

  @api retentionDurationData;
  @api enableValidateButton;
  @api suggestedAddress;
  @api tier;
  @api sldsModalEl;
  platformErrorMessage;

  platformLocationOptions = [];
  platformOptions = [];
  timezoneValue;
  languageValue;
  platformLocationValue;
  platformValue;
  rcEngageDigitalDomain;
  validatedAddressData;
  countriesToMatch;
  ccbPlatforms = [];
  basePicklistHeight = 0;
  expandableId = 'expandable-id';
  progressStepId = 'progress-step-id';
  currencyInrLocationCode = 'IN1';

  get isEngageVoice() {
    return this.tier === ENGAGE_VOICE;
  }

  get isProcessing() {
    return this.status === PROCESSING;
  }

  get isServiceReady() {
    return [ACTIVE, COMPLETED].includes(this.status);
  }

  get isStartedSignUp() {
    return this.isProcessing || this.isSignedUp;
  }

  get isSignedUp() {
    return this.status === COMPLETED;
  }

  get isEngageFieldsEmpty() {
    return this.isEngageVoice
      ? !this.isEngageVoiceFilled
      : !this.isEngageFilled;
  }

  get isEngageFilled() {
    return this.timezoneValue
      && this.languageValue && this.rcEngageDigitalDomain
      && this.platformLocationValue && this.platformValue;
  }

  get isEngageVoiceFilled() {
    return this.timezoneValue && this.platformLocationValue && this.platformValue;
  }

  get firstStepSetting() {
    return Boolean(this.status) ? COMPLETED : ACTIVE;
  }

  get secondStepSetting() {
    if (this.isSignedUp || !this.isEngageFieldsEmpty && !Boolean(this._engageError)) {
      return COMPLETED;
    }
    return Boolean(this.status) ? ACTIVE : READY;
  }

  get isSecondStepCompleted() {
    return this.secondStepSetting === COMPLETED;
  }

  get isAddressValidated() {
    return !this.enableValidateButton;
  }

  get thirdStepSetting() {
    if (this.isAddressValidated || this.isSignedUp) {
      return COMPLETED;
    }
    return this.isSecondStepCompleted ? ACTIVE : READY;
  }

  get lastStepSetting() {
    if (this.isSignedUp) {
      return COMPLETED;
    }
    return this.thirdStepSetting === COMPLETED ? ACTIVE : READY;
  }

  get isGeneralInfoDisabled() {
    return ![ACTIVE, COMPLETED].includes(this.secondStepSetting) || this.isSignedUp;
  }

  get platformLocationLabel() {
    return `${this.tier} Platform Location`;
  }

  get rcPlatformLabel() {
    return `RC ${this.tier} Platform`;
  }

  get timezoneOptions() {
    return TIME_ZONE_OPTIONS_ENGAGE;
  }

  get languageOptions() {
    return LANGUAGE_OPTIONS_ENGAGE;
  }

  get dropBoxClass() {
    return [
      SLDS_COL,
      SLDS_RIGHT_MARGIN,
      this.isEngageVoice ? DROPBOX_VOICE : DROPBOX
    ].filter(Boolean).join(' ');
  }

  handlePlatformLocationChange(event) {
    this.platformLocationValue = event.detail.value;
    this.setHighPriorityPlatformByLocation(this.platformLocationOptions.find(pl => pl.value === this.platformLocationValue));
    const element = this.getElement(event.target.dataset.id);
    this.setCustomValidation(element, '', !element.checkValidity());
    this.platformValue = this.platformOptions[0].value;
    this.sendSubmitData();
  }

  handlePlatformChange(event) {
    this.platformValue = event.detail.value;
    const element = this.getElement(PLATFORM_LOCATION);
    this.setCustomValidation(element, '', !element.checkValidity() && this.platformValue);
    this.sendSubmitData();
  }

  handleTimezoneChange(event) {
    this.timezoneValue = event.detail.value;
    this.sendSubmitData();
  }

  handleLanguageChange(event) {
    this.languageValue = event.detail.value;
    this.sendSubmitData();
  }

  handleEngageDigitalDomainChange(event) {
    this.rcEngageDigitalDomain = event.target.value;
    this.sendSubmitData();
  }

  connectedCallback() {
    this.init();
  }

  renderedCallback() {
    if (Boolean(this._engageError)) {
      const element = this.getElement(this._engageError);
      this.setCustomValidation(element, `${this._engageError + ' ' + INVALID}`, element.checkValidity());
    }
    this.calculateSectionHeight();
    this.calculateProgressStepHeight();
  }

  handleOnBlur(event) {
    if (this._engageError === event.target.dataset.id && !this.isEngageFieldsEmpty) {
      const element = this.getElement(event.target.dataset.id);
      this._engageError = null;
      this.setCustomValidation(element, '', true);
      this.sendSubmitData();
    }
  }

  sendSubmitData() {
    this.dispatchEvent(new CustomEvent('sendsubmitdata', {
      detail: this.submitDataDetail()
    }));
  }

  init() {
    handleSubmit({
      params: JSON.stringify({
        action: 'request engage platforms',
        isEngageVoice: this.isEngageVoice
      })
    })
    .then(res => this.handleResponse(res, this.handleEngagePlatforms.bind(this)))
    .then(() => getCountries())
    .then(res => this.handleResponse(res, this.handleGetCountries.bind(this)))
    .catch(res => this.handleError(res));
  }

  handleGetCountries(res) {
    this.countriesToMatch = res.data.countries;
  }

  handleResponse(response, handler) {
    const res = JSON.parse(response);
    const errorMessages = res.messages?.filter(m => m.severity === ERROR)

    if (errorMessages?.length > 0) {
      errorMessages.forEach(m => this.addMessagesProcessOrder(m));;
      return Promise.reject();
    }

    handler(res);
  }

  handleEngagePlatforms(res) {
    this.ccbPlatforms.push(...res.data.body);
    this.setPlatformLocationOptions();
    this.setPreselectedPlatformValues();
  }

  setPreselectedPlatformValues() {
    const mappedLocation = this.findPlatformLocationByBrandName;
    if (mappedLocation) {
      this.platformLocationValue = mappedLocation.value;
      this.setHighPriorityPlatformByLocation(mappedLocation);
    } else {
      this.platformLocationValue = this.platformLocationOptions[0].value;
      this.setPlatformOptions();
    }
  }

  get isInvalidPlatformLocation() {
    return !Boolean(this.findPlatformLocationByBrandName) && this.platformLocationOptions.length > 0;
  }

  get findPlatformLocationByBrandName() {
    if(this.currencyIsoCode === 'INR') {
      return this.platformLocationOptions.find(p => p.value === this.currencyInrLocationCode);
    }
    else{
    return this.platformLocationOptions.find(p => p.value.includes(BRAND_NAMES.get(this.brandName)));
    }
    
  }

  findPlatformsByLocation(location) {
    return this.ccbPlatforms.filter(p => p.group === location?.value);
  }

  getHighPriorityPlatform(platforms) {
    return platforms.sort((a, b) => a.order - b.order)[0];
  }

  platformOptionValue() {
    return this.isEngageVoice ? 'id' : 'name';
  }

  setPlatformLocationOptions() {
    this.platformLocationOptions = this.ccbPlatforms.reduce((result, v) => {

      if (!result.some(r => r.value === v.group)) {
        result.push({
          value: v.group,
          label: v.group
        });
      }

      return result;
    }, []);
  }

  setPlatformOptions() {
    this.platformValue = null;
    this.platformOptions = this.ccbPlatforms.reduce((result, v) => {

      if (v.group === this.platformLocationValue) {
        result.push({
          value: v[this.platformOptionValue()],
          label: v.title
        });
      }

      return result;
    }, []);
  }

  get disablePlatformOptions() {
    return this.isGeneralInfoDisabled || this.platformOptions.length === 0;
  }

  handleError(errorResponse) {
    if (!errorResponse) {
      return;
    }
    this.addMessagesProcessOrder({
        messageDetails: errorResponse.body?.message || errorResponse,
        severity: ERROR
    });
  }

  addMessagesProcessOrder(message) {
    window.dispatchEvent(new CustomEvent("AddNotificationBarMessage", {
      detail: message
    }));
  }

  calculateSectionHeight() {
    const element = this.getElement(PLATFORM_LOCATION);
    const diffPicklistHeight = element?.offsetHeight - this.basePicklistHeight;
    const sectionHeight = this.showAddressValidation ? SECTION_HEIGHT_MP : SECTION_HEIGHT_MPUB;
    const expandedHeight = !element?.checkValidity() ? sectionHeight + diffPicklistHeight : sectionHeight;
    const height = this.expanded ? expandedHeight : 0;
    this.setHeight(height, this.expandableId);
  }

  calculateProgressStepHeight() {
    const locationElement = this.getElement(PLATFORM_LOCATION);
    const diffPicklistHeight = locationElement?.offsetHeight - this.basePicklistHeight;
    const height = !locationElement?.checkValidity() ? PROGRESS_ITEM_HEIGHT + diffPicklistHeight : PROGRESS_ITEM_HEIGHT;
    this.setHeight(height, this.progressStepId);
  }

  getElement(dataId) {
    return this.template.querySelector(`[data-id="${dataId}"]`);
  }

  setHeight(value, dataId) {
    this.getElement(dataId)?.style?.setProperty('height', `${value}px`);
  }

  setHighPriorityPlatformByLocation(location) {
    this.setPlatformOptions();
    const mappedPlatforms = this.findPlatformsByLocation(location);
    const highPriorityPlatform = this.getHighPriorityPlatform(mappedPlatforms);
    this.platformValue = highPriorityPlatform[this.platformOptionValue()];
  }

  setCustomValidation(element, message, isInvalid) {
    if (isInvalid) {
      element.setCustomValidity(message);
      element.reportValidity();
    }
  }

  addEngageError() {
    const element = this.getElement(PLATFORM_LOCATION);
    this.setCustomValidation(element, DEFAULT_PLATFORM_LOCATION_VALIDATION_ERROR, true);
    this.basePicklistHeight = element.offsetHeight;
  }

  submitDataDetail() {
    let detail = {
      packageLocation: this.platformLocationValue,
      engageShardName: this.platformValue,
      platformId: this.platformValue,
      engageDomain: this.rcEngageDigitalDomain,
      timezone: this.timezoneValue,
      locale: this.languageValue,
      locationNotFoundByPackage: true,
      migration: false,
      packageIsLegacy: false,
      provisionUserAccount: false,
      isSecondStepCompleted: this.isSecondStepCompleted
    };

    if (this.showAddressValidation) {
      detail = {
        ...detail,
        billingAddress: this.suggestedAddress
      };
    }
    return detail;
  }

  @api
    clearTimezone() {
        this.timezoneValue = null;
        // Also clear the searchable dropdown display
        const dropdown = this.template.querySelector('c-searchable-dropdown');
        if (dropdown) {
            dropdown.clearSelection();
        }
    }
}