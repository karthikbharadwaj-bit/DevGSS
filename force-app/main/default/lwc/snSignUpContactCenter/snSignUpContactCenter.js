import { LightningElement, api } from "lwc";
import handleSubmit from '@salesforce/apex/ProcessOrder.handleSubmit';
import { COMPLETED, ACTIVE, READY, PROCESSING, ERROR, BRAND_RINGCENTRAL, BRAND_RINGCENTRAL_CA, } from "c/snUtils";
import TIME_ZONE from '@salesforce/i18n/timeZone';

export default class SnSignUpContactCenter extends LightningElement {

  @api expanded;
  @api status;
  @api step;
  @api enableValidateButton;
  @api suggestedAddress;
  @api opportunityId;
  @api isReadyForGetOrderToVendorCatalog;
  @api existing;
  @api showAddressValidation;
  @api sldsModalEl;
  timezone;
  geoRegion;
  implementationTeam;
  inContactSegment;
  timezoneValue;
  geoRegionValue;
  implementationTeamValue;
  inContactSegmentValue;
  timezones;
  geoRegions;
  implementationTeams;
  inContactSegments;
  tableLength = 0;
  nicLicensesItems;
  quoteDescription = '';
  countriesToMatch;
  ccNumber;
  brand;
  city;
  state;
  currentUser;

  @api
  get rcccParameters() { };

  set rcccParameters(value) {
    if (value) {
      this.prepopulateRCCCParameters(value);
    }
  }

  get timing() {
    return new Date();
  }

  get header() {
    return `${this.existing ? 'Sync ' : 'Sign Up '} Contact Center ${this.existing ? 'Order' : ''}`;
  }

  get isContactCenterFieldsEmpty() {
    return !(this.ccNumber && this.geoRegion && this.timezone
      && this.inContactSegment && this.implementationTeam);
  }

  get sectionClasses() {
    return this.expanded ? "expandable " + this.expandedHeight : "expandable";
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

  get firstStepSetting() {
    return Boolean(this.status) ? COMPLETED : ACTIVE;
  }

  get secondStepSetting() {
    if (!this.isContactCenterFieldsEmpty || this.isSignedUp) {
      return COMPLETED;
    }
    return Boolean(this.status) ? ACTIVE : READY;
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

  get isSecondStepCompleted() {
    return this.secondStepSetting === COMPLETED;
  }

  get lastStepSetting() {
    if (this.isSignedUp) {
      return COMPLETED;
    }
    return this.penultStepSetting === COMPLETED ? ACTIVE : READY;
  }

  get penultStepSetting() {
    return this.existing ? this.secondStepSetting : this.thirdStepSetting;
  }

  get generalOrDisabledWhenExistingBusiness() {
    return this.existing || this.isGeneralInfoDisabled;
  }

  get isGeneralInfoDisabled() {
    return ![ACTIVE, COMPLETED].includes(this.secondStepSetting) || this.isSignedUp;
  }

  get tableVisibility() {
    return 'slds-scrollable_x ' + (this.tableLength !== 0 ? 'slds-show' : 'slds-hide');
  }

  get expandedHeight() {
    return `expanded${this.tableLength}` + (this.isShowAddressValidation  ? "" : "-existing");
  }

  get textareaStyle() {
    return "slds-textarea" + (this.isGeneralInfoDisabled ? " disable-textarea" : "");
  }

  get isShowSyncInfo() {
    return this.isSignedUp && this.existing;
  }

  get currentUserTimeZone() {
    return TIME_ZONE;
  }

  get isShowAddressValidation() {
    return !this.existing && this.showAddressValidation;
  }

  get descriptionServices() {
    return 'SERVICES:\r\n';
  }

  get descriptionNotes() {
    return [
      'NOTES:\r\n\r',
      'Platform - UserHub\r\n',
      'Manual Outbound Transport - RingCentral\r\n',
      'Dialer Transport - RingCentral\r\n',
      'Implementation ACD/IVR - RingCentral\r\n',
      !this.existing && 'CXone Digital Channels - RingCentral\r\n',
      !this.existing && 'Audio Recording - RingCentral\r\n',
      !this.existing && 'CXone Audio Recording Advanced - RingCentral\r\n',
      !this.existing && 'CXone Screen Recording - RingCentral\r\n',
      !this.existing && 'CXone Quality Management - RingCentral\r\n',
      !this.existing && 'CXone Workforce Management - RingCentral\r\n',
      !this.existing && 'CXone Interaction Analytics - RingCentral\r\n',
      !this.existing && 'CXone Feedback Management - Nice\r\n',
    ].filter(Boolean).join('').trimEnd();
  }

  get increaseDecreaseContractedSeats() {
    return '\r\n\rIn addition to their contracted seats, please increase/decrease from XX to XX. Please increase/decrease ports from XX to XX.';
  }

  get descriptionInitialTerms() {
    return '\r\n\rThe contract initial term is 12 months.';
  }

  get descriptionBillindAddress() {
    return '\r\n\rBilling Address:\r\n\r' + this.city + ', ' + this.state;
  }

  get submittedBy() {
    return '\r\n\rSubmitted by ' + this.currentUser;
  }

  get isCanadaOrUS() {
    return [BRAND_RINGCENTRAL, BRAND_RINGCENTRAL_CA].includes(this.brand);
  }

  get isBillingAddressApplicable() {
    return this.city
      && this.state
      && !this.existing
      && this.isCanadaOrUS;
  }

  connectedCallback() {
    this.init();
  }

  init() {
    handleSubmit({ params: '{"action":"get dictionaries"}' })
      .then(res => this.handleResponse(res))
      .catch(res => this.handleError(res));
  }

  handleResponse(response) {
    const res = JSON.parse(response);

    if (res.messages?.some(m => m.severity === ERROR)) {
      res.messages.filter(m => m.severity === ERROR)
        .forEach(m => this.addMessagesProcessOrder(m));

      return Promise.reject();
    }
    const dictionaries = res.data.body;

    this.countriesToMatch = dictionaries.countries;

    this.timezones = this.mapPicklistValues(dictionaries.timeZones);
    this.inContactSegments = this.mapPicklistValues(dictionaries.nicSegments);
    this.geoRegions = this.mapPicklistValues(dictionaries.geoRegions);
    this.implementationTeams = this.mapPicklistValues(dictionaries.implementationTeams);
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

  mapPicklistValues(picklistValues) {
    return picklistValues.map(p => ({
      value: p.id,
      label: p.name
    }));
  }

  handleTimezone(event) {
    this.handleSetValue('timezone', event.detail.value);
    this.sendSubmitData();
  }

  handleGeoRegion(event) {
    this.handleSetValue('geoRegion', event.detail.value);
    this.sendSubmitData();
  }

  handleImplementationTeam(event) {
    this.handleSetValue('implementationTeam', event.detail.value);
    this.sendSubmitData();
  }

  handleInContactSegment(event) {
    this.handleSetValue('inContactSegment', event.detail.value);
    this.sendSubmitData();
  }

  handleCCNumber(event) {
    this.ccNumber = event.target.value;
    this.sendSubmitData();
  }

  handleQuoteDescriptionChange(event) {
    this.quoteDescription = event.target.value;
    this.sendSubmitData();
  }

  prepopulateRCCCParameters(value) {
    const rcccParams = JSON.parse(JSON.stringify(value));
    this.ccNumber = rcccParams.ccNumber;
    this.currentUser = rcccParams.currentUser?.Name;
    this.brand = rcccParams.brandName;
    this.city = rcccParams.city;
    this.state = rcccParams.state;
    this.buildDescription();
    this.sendSubmitData();
  }

  buildDescription() {
    const data = [
      { isApplicable: true, text: this.descriptionServices },
      { isApplicable: true, text: this.descriptionNotes },
      { isApplicable: this.existing, text: this.increaseDecreaseContractedSeats },
      { isApplicable: !this.existing, text: this.descriptionInitialTerms },
      { isApplicable: this.isBillingAddressApplicable, text: this.descriptionBillindAddress },
      { isApplicable: this.currentUser, text: this.submittedBy }
    ];

    data
      .filter(d => d.isApplicable)
      .forEach(d => this.quoteDescription += d.text + '\r\n');
    this.quoteDescription = this.quoteDescription.trimEnd();
  }

  onBodyHeightChanged(event) {
    const detail = JSON.parse(JSON.stringify(event.detail));
    this.tableLength = detail.length;
  }

  handleSetValue(fieldName, value) {
    this[fieldName] = value;
    this[fieldName + 'Value'] = this[fieldName + 's'].find(s => s.value === value)?.label;
  }

  sendSubmitData() {
    this.dispatchEvent(new CustomEvent('sendsubmitdata', {
      detail: this.submitDataDetail()
    }));
  }

  populateNicLicensesItems(event) {
    const data = JSON.parse(JSON.stringify(event.detail))

    this.nicLicensesItems = data.nicLicensesItems;
    if (this.isContactCenterFieldsEmpty && data.accountParams) {
      this.handleSetValue('timezone', data.accountParams.timeZoneId);
      this.handleSetValue('geoRegion', data.accountParams.geoRegionId);
      this.handleSetValue('inContactSegment', data.accountParams.nicSegmentId);
      this.handleSetValue('implementationTeam', data.accountParams.implementationTeamId);
      this.ccNumber = data.accountParams.contactCenterNumber
    }
    this.sendSubmitData();
  }

  submitDataDetail() {
    let detail = {
      accountParams: {
        timeZoneId: this.timezone,
        geoRegionId: this.geoRegion,
        nicSegmentId: this.inContactSegment,
        implementationTeamId: this.implementationTeam,
        timeZoneValue: this.timezoneValue,
        geoRegionValue: this.geoRegionValue,
        nicSegmentValue: this.inContactSegmentValue,
        implementationTeamValue: this.implementationTeamValue,
        contactCenterNumber: this.ccNumber
      },
      nicLicenses: {
        items: this.nicLicensesItems,
        quoteDescription: this.quoteDescription
      },
      skipAddressValidation: true,
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
}