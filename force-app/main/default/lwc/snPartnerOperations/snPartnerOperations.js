import { LightningElement, api, track } from 'lwc';

import getPartnerOperationSteps from '@salesforce/apex/PartnerOperationsController.getPartnerOperationSteps';
import getPartnerOperationScenario from '@salesforce/apex/PartnerOperationsController.getPartnerOperationScenario';
import getDefaultFieldValues from '@salesforce/apex/PartnerOperationsController.getDefaultFieldValues';
import validateStep from '@salesforce/apex/PartnerOperationsController.validateStep';
import getCurrentOperation from '@salesforce/apex/PartnerOperationsController.getCurrentOperation';
import getWholesaleRecordTypeId from '@salesforce/apex/PartnerOperationsController.getWholesaleRecordTypeId';

export default class SnPartnerOperations extends LightningElement {

  @api
  initialLog = {};
  @api
  oppRecordType;
  @track
  accId;
  @track
  errorMessageDescription = '';
  @track
  isShowErrorButton = false;

  operationLog = {};

  isProcess = false;
  isCompleted = false;
  isReady = false;
  isError = false;

  steps = [];
  scenario = {};

  defaultFieldValues = {};

  wholesaleRecordTypeId = '';
  operationType = '';
  caseCreationMessage = 'Thank you for the report. Case is successfully created';
  changePartnerTitle = 'Change to Wholesale Partner';
  switchPartnerTitle = 'Switch Account to Wholesale';

  _items;
  set items(steps) {
    /* find active */
    let activeStepIdx = steps.findIndex(step => !step.isSync);

    /* completed state */
    this.isCompleted = activeStepIdx === -1;

    const items = steps.map((item, idx) => {
      if (activeStepIdx === idx) {
        item = {
          ...item,
          isActive: true,
          isUnavailable: false
        };
      }
      return item;
    });

    this._items = items;
  }
  get items() {
    return this._items || [];
  }

  connectedCallback() {
    this.init();
  }

  init() {
    this.operationLog = this.initialLog;
    this.accId = this.operationLog?.account;
    this.operationType = this.initialLog?.actionType === 'change Partner' ?  this.changePartnerTitle : this.switchPartnerTitle;
    console.log('partner operation: ', this.initialLog?.actionType);
    console.log('partner operation: ', this.operationLog);
    getPartnerOperationSteps()
      .then(res => this.handleResponse(res))
      .then(data => {
        this.steps = data.steps;
      })
      .then(() => getPartnerOperationScenario({logId: this.operationLog.id}))
      .then(res => this.handleResponse(res))
      .then(data => this.setScenario(data))
      .then(() => getWholesaleRecordTypeId())
      .then(res => this.handleResponse(res))
      .then(data => {
        this.wholesaleRecordTypeId = data.wholesaleRecordTypeId;
      })
      .catch(res => this.handleMessages(res));
  }


  getScenario() {
    return getPartnerOperationScenario({logId: this.operationLog.id});
  }

  setScenario(data) {
    let scenario = data.scenario;
    if (!this.operationLog?.id) {
      scenario = {
        steps: this.baseSteps,
        isCompleted: false
      }
    }
    scenario.steps.sort(this.compare);
    this.scenario = scenario;
    this.items = this.setExistingSteps(this.scenario.steps);
    this.isReady = true;
  }

  updateOperation(operationLog) {
    this.operationLog = JSON.parse(operationLog);
  }

  handleResponse(res) {
    console.log('handleResponse: ', res);
    if (res.status !== 'success') {
      throw res;
    }

    if (res.data.redirectUrl) {
      window.open(res.data.redirectUrl, '_blank');
    }

    this.handleMessages(res);
    return res.data;
  }

  setExistingSteps(steps) {
    return Object.keys(steps)?.reduce((result, key) => {
        let item = { ...steps[key], isDisabled: steps[key].isSync, isButton: true, isUnavailable: false };
        if (key === '1') {
            item = !Boolean(this.operationLog?.opportunity)
              ? { ...steps[key], isDisabled: true,  isButton: true, isUnavailable: true}
              : { ...steps[key], isDisabled: steps[key].isSync, isButton: true, isUnavailable: false};
        } else if (key === '2') {
          item = !Boolean(this.operationLog?.approval)
            ? { ...steps[key], isDisabled: true, isButton: false, isUnavailable: true}
            : { ...steps[key], isDisabled: false, isButton: false, isUnavailable: false};
        } else if (key === '3') {
          item = !Boolean(this.operationLog?.opportunity && this.operationLog?.approval)
            ? { ...steps[key], isDisabled: true, isButton: false, isUnavailable: true}
            : { ...steps[key], isDisabled: false, isButton: false};
        }
      result.push(item);
      console.log('result ', result);
      return result;

    }, []);
  }

  handleMessages(res) {
    console.log('handleMessages: ', res);

    const isUnhandledApexException = res && res.body && res.body.exceptionType && res.body.message;

    if (isUnhandledApexException) {

      const maxMessageLength = 300;

      const title = `Unexpected exception occurred (${res.body.exceptionType})`;

      const errorMessage = res.body.message.length > maxMessageLength
        ? res.body.message.substring(0, maxMessageLength).concat('...')
        : res.body.message;

      this.showToast({
        title: title,
        message: errorMessage,
        type: 'error',
        duration: false
      });

    } else if (res && res.messages) {
      res.messages.forEach(m => {
        this.errorMessageDescription = m.messageDetails;
        this.isShowErrorButton = m.severity === 'error' ?  true : false;
        this.isError = this.isShowErrorButton;
        if (m.messageDetails === this.caseCreationMessage) {
          this.showToast({
            title: m.message,
            message: m.messageDetails,
            type: m.severity || m.status,
            duration: false
          });
        }
      });
    }
  }

  onActionClick(event) {
    event.preventDefault();
    const action = event.currentTarget.dataset.action;

    switch (action) {
      case 'Create New Opportunity':
        window.open('/apex/OpportunityCreationForm?RecordType=' + this.oppRecordType
          + '&accid=' + this.operationLog?.account
          + '&partnerId=' + this.operationLog?.partnerInfo?.id
          + '&ngbsPartnerId=' + this.operationLog?.partnerInfo?.ngbsPartnerId
          + '&ent=Opportunity&save_new=1&sfdc.override=1');
        break;

      case 'Create New Request':
        this.isProcess = true;
        const approvalDetails = {
            accountId: this.operationLog?.account,
            accountPartnerId: this.operationLog?.partnerInfo?.id,
            action: ''
        };

        getDefaultFieldValues({params: approvalDetails})
          .then(res => this.handleResponse(res))
          .then(data => {
            this.defaultFieldValues = data.defaultFieldValues;
          }).then(() =>{
            if (this.defaultFieldValues != null) {
                delete this.defaultFieldValues.Id;
                delete this.defaultFieldValues.attributes;
                delete this.defaultFieldValues.Status__c;
            }
            let base64Context = {
                'type': 'standard__recordPage',
                'attributes': {
                  'recordId': this.operationLog?.opportunity,
                  'actionName': 'view',
                  'objectApiName': 'Opportunity',
                  'recTypeId': this.wholesaleRecordTypeId,
                  'partnerAccountId': this.operationLog?.partnerInfo?.id,
                  'defaultFieldValues': this.defaultFieldValues
                },
                "state": {}
            }
            var base64Code = window.btoa(JSON.stringify(base64Context));
            window.open('/lightning/o/Approval__c/new?inContextOfRef=1.' + base64Code + '&count=1');
          })
          .catch(res => this.handleMessages(res))
          .then(() => this.isProcess = false);
        break;
      case 'Open Invoice-Wholesale Request':
        window.open('/lightning/r/Approval/' + this.operationLog?.approval + '/view' );
        break;
      case 'Open Wholesale Opportunity':
        window.open('/lightning/r/Opportunity/' + this.operationLog?.opportunity + '/view' );
        break;
      default:
        console.log('no action found: "' + action + '"');
        break;
    }
  }

  onNext() {
    this.isProcess = true;

    getCurrentOperation({ accountId: this.operationLog.account })
      .then(res => this.handleResponse(res))
      .then(data => this.updateOperation(data.operation))
      .then(() => validateStep({ params: JSON.stringify({ logId: this.operationLog.id, name: this.activeStep.name }) }))
      .then(res => this.handleResponse(res))
      .then(() => getPartnerOperationScenario({logId: this.operationLog.id}))
      .then(res => this.handleResponse(res))
      .then(data => this.setScenario(data))
      .catch(res => this.handleMessages(res))
      .then(() => this.isProcess = false);

  }

  onClose() {
    this.dispatchEvent(new CustomEvent('refreshPage', {}));
  }

  onShowError() {
    this.isError = !this.isError;
  }

  showToast({title, message, type = 'info', duration}) {
    window.dispatchEvent(new CustomEvent('ShowToastEvent', {
      detail: {title, message, type, duration}
    }));
  }

  compare(a, b) {
    const orderA = a.order;
    const orderB = b.order;

    let comparison = 0;
    if (orderA > orderB) {
      comparison = 1;
    } else if (orderA < orderB) {
      comparison = -1;
    }
    return comparison;
  }

  get activeStep() {
    return this.items.find(item => item.isActive);
  }

  get baseSteps() {
    return Object.keys(this.steps)?.reduce((result, key) => {
        const item = { ...this.steps[key], isSync: false};
      result.push(item);
      return result;
    }, []);
  }

  get isShowNext() {
    return !this.isCompleted && this.isReady;
  }

  get isShowSpinner() {
    return !this.isReady || this.isProcess;
  }

  get isShowReportButton(){
      return Boolean(this.operationLog?.id);
  }

  get isShowError() {
    return this.isError;
  }

  get
}