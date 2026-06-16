import { LightningElement, api, track } from 'lwc';
import { showToast } from 'c/clService';

import getSyncInfo from '@salesforce/apex/SyncWithNGBS.getSyncInfo';
import getSyncSteps from '@salesforce/apex/SyncWithNGBS.getSyncSteps';
import getSyncScenario from '@salesforce/apex/SyncWithNGBS.getSyncScenario';
import syncWithNGBS_v3 from '@salesforce/apex/SyncWithNGBS.syncWithNGBS_v3';
import updateRCCCSyncStatus from '@salesforce/apex/SyncWithNGBS.updateRCCCSyncStatus';
import syncEntitlements from '@salesforce/apex/SyncWithNGBS.syncEntitlements';
import validateSyncWithNGBS from '@salesforce/apex/SyncWithNGBS.validateSyncWithNGBS';
import createDealDeskCaseDescriptions from '@salesforce/apex/SyncWithNGBS.createDealDeskCaseDescriptions';
import postValidationAction from '@salesforce/apex/SyncWithNGBS.postValidationAction';
import updateServiceInfoAfterSync from '@salesforce/apex/QuoteHelper.updateServiceInfoAfterSync';
import activateOrderForOpportunity from '@salesforce/apex/OrderHelper.activateOrderForOpportunity';
import { CloseActionScreenEvent } from 'lightning/actions';
import { TIER_MAP, RING_CENTRAL_CONTACT_CENTER, SUSPENDED_ACCOUNT_ERROR_MSG } from 'c/snUtils';

export default class SnMain extends LightningElement {

  @api opportunityId;
  @api recordId;
  @api isSimplifiedLboDownsellEnabled;
  @api quoteId;

  syncInfo = {};
  isReady = false;
  isProcess = false;
  isCompleted = false;
  isFailedWithError = false;
  scenario = {};
  syncStepExecutorInfo = {};
  syncStepExecutorReason = '';
  currentStepView = false;
  showRefreshBackdrop = false;
  isMultiproductEnabled;

  @api isProcessOrderSpinnerShown;
  @api postValidationActionAvailable;
  @api expanded;
  @api tier;
  @api onNextSync() {
    this.onNext();
  }

  @api onSkipSync() {
    this.onSkip();
  }

  syncTiming = {};
  syncUserName = {};

  hasRendered = false;

  setActive(item) {
    return {
      ...item,
      isSync: false,
      isSkip: false,
      isActive: true,
    };
  }

  setSkipped(item) {
    return {
      ...item,
      isSync: false,
      isSkip: true,
      isActive: false,
    };
  }

  setBlocked(item) {
    return {
      ...item,
      isBlocked: true,
    };
  }

  setSynced(item) {
    return {
      ...item,
      isSync: true,
      isSkip: false,
      isActive: false,
    };
  }

  setNotSynced(item) {
    return {
      ...item,
      isSync: false,
      isSkip: false,
      isActive: false,
    }
  }

  renderedCallback() {
    if (!this.hasRendered && this.opportunityRecordId) {
      this.hasRendered = true;
      this.init();
    }
  }

  async init() {
    try {
      const validateResp = await this.requestValidateSyncWithNGBS();
      await this.validateSuspendedAccount(validateResp);
      await this.createDealDeskCaseDescriptions();
      if (this.postValidationActionAvailable) {
        await postValidationAction({"quoteId": this.quoteId});
      }
      await syncEntitlements({"quoteId": this.quoteId});
      await this.setSyncSteps();
      await this.setSyncScenario();
      await this.getInfoPromise();
      //await this.processAutoSteps();
      this.isReady = true;
      this.manageProcessOrder();
    } catch (res) {
      this.handleMessages(res);
    }
  }

  async requestValidateSyncWithNGBS() {
    return validateSyncWithNGBS({"quoteId": this.quoteId});
  }

  async validateSuspendedAccount(res) {
    const messages = JSON.parse(res);
    if (messages && messages.length === 1 && messages[0].messageDetails === SUSPENDED_ACCOUNT_ERROR_MSG) {
      showToast({
          title: '',
          message: SUSPENDED_ACCOUNT_ERROR_MSG,
          type: 'warning',
          duration: false
      });
    } else if (messages && messages.length > 0) {
      this.isFailedWithError = true;
      await this.reject(messages);
    }
  }

  async createDealDeskCaseDescriptions() {
    let response = await createDealDeskCaseDescriptions({"quoteId": this.quoteId});
    this.handleResponse(response);
  }

  async setSyncSteps() {
    const res = await getSyncSteps();
    this.steps = this.handleResponse(res).steps;
  }

  async setSyncScenario() {
    const res = await getSyncScenario({quoteId: this.quoteId});
    this.scenario = this.handleResponse(res).scenario;
    this.scenario.steps.forEach(step => {
      if (this.steps.hasOwnProperty(step.name)) {
        this.steps[step.name] = step;
      }
    });
  }

  async reject(reasons){
      await Promise.reject({messages: reasons});
  }

  getStep(name) {
    return {name}
  }

  @track _items;
  set items(steps) {

    /* convert */
    let items = steps.map(item => {
      item = this.getStep(item.name);
      item = this.getStepStatus(item, this.syncInfo);

      /* we store skip status in app state */
      item = this.getStepStatus(item, this.state);

      item = this.getStepActions(item);
      item.isAuto = this.syncInfo[item.name]?.auto;
      return item;
    });

    /* find active */
    let activeStepIdx = items.findIndex(item => {
      return !item.isSync && !item.isSkip;
    });

    /* completed state */
    this.isCompleted = activeStepIdx === -1;

    /* set active */
    items = items.map((item, idx) => {
      if (activeStepIdx === idx) {
        item = this.setActive(item);
      }
      if (activeStepIdx != -1 && activeStepIdx < idx) {
        item = this.setBlocked(item);
      }
      return item;
    });

    items = items.map((item) => {
        if (this.syncTiming[item.name]) {
            item.timing = this.syncTiming[item.name];
        }
        item.executorName = this.syncUserName?.[item.name]
            ? (this.tier != RING_CENTRAL_CONTACT_CENTER ? ' by ' : ' Initiated by ') + this.syncUserName?.[item.name]
            : '';
        return item;
    });

    this._items = items;
  }

  get items() {
    return this._items || [];
  }

  get activeStep() {
    return this.items.find(item => item.isActive);
  }

  getStepActions(item) {
    const info = this.syncInfo[item.name];
    item.skip = info.skip;
    return item;
  }

  getStepStatus(item, val) {
      const status = val && val[item.name] && val[item.name].status;

      switch (status) {
        case 'SYNCED':
          item = this.setSynced(item);
          break;
        case 'NOT_SYNCED':
          item = this.setNotSynced(item);
          break;
        case 'SKIPPED':
          item = this.setSkipped(item);
          break;
        default:
          break;
      }

    return item;
  }

  getInfoPromise() {
    return getSyncInfo({quoteId: this.quoteId, steps: this.scenario.stepNames})
      .then(res => this.handleResponse(res))
      .then(data => {
        this.syncInfo = data;

        // update sync timing info
        const opportunitySyncInfo = data.syncInfo && JSON.parse(data.syncInfo) || {};
        this.syncTiming = opportunitySyncInfo.timeStampMap || {};
        this.syncUserName = opportunitySyncInfo.userNameMap || {};

        // update steps
        this.items = this.scenario.steps;
        // update step executor info
        try {
            this.syncStepExecutorInfo = JSON.parse(data.NGBSSyncExecutorInfo);
            this.syncStepExecutorReason = this.syncStepExecutorInfo.reason === 'MANUALLY' ? 'manually' : 'automatically';
        } catch {
            this.syncStepExecutorInfo = {};
            this.syncStepExecutorReason = '';
        }

        this.currentStepView = this.allowCurrentStepView;
      })
      .catch(res => this.handleMessages(res));
  }

  manageProcessOrder() {
    const syncEvent = new CustomEvent("getsyncdata", {
      detail: {
        tierLabel : this.tier,
        isSyncReady : this.isReady,
        isShowNext : this.isShowNext,
        isShowSkip : this.isShowSkip,
        nextButtonLabel : this.nextButtonLabel,
        isSyncInProcess : this.isProcess,
        isSyncCompleted : this.isCompleted
      }
    });

    this.dispatchEvent(syncEvent);
  }

  async processAutoSteps() {
    if (!this.isSimplifiedLboDownsellEnabled) {
      return;
    }

    if (this.isProcess) {
      return;
    }

    if (!this.activeStep || !this.activeStep.isAuto) {
      return;
    }

    let currentStepName = this.activeStep.name;
    await this.callSync({ action: this.activeStep.name }, true);

    if (this.activeStep && this.activeStep.name !== currentStepName) {
      return this.processAutoSteps();
    }
  }

  onSelectedHandler(event) {
    this.items = this.items.map( (item, idx) => {
      item.isSelected = false;
      if (idx === event.detail.idx) {
        item.isSelected = true;
      }
      return item;
    });
  }

  setSkipStep() {
    if (!this.state) {
      this.state = {};
    }
    if (!this.state[this.activeStep.name]) {
      this.state[this.activeStep.name] = {};
    }
    this.state[this.activeStep.name].status = 'SKIPPED';
  }

  async updateServiceInfo() {
      let response = await updateServiceInfoAfterSync({quoteId: this.quoteId});
      this.handleMessages(response);
  }

  async activateOrder() {
      let response = await activateOrderForOpportunity({quoteId: this.quoteId})
      if (response.status === 'success') {
          showToast({
              title: response.data.message,
              message: response.data.url,
              type: 'info',
              duration: false
          });
      } else {
          const resMessage = response.messages[0];
          showToast({
              title: resMessage.message,
              message: resMessage.messageDetails,
              type: 'error',
              duration: false
          });
      }
  }

  onClose() {
    this.dispatchEvent(new CloseActionScreenEvent());
  }

  onSkip() {
    this.setSkipStep();
    this.items = this.scenario.steps;
    this.manageProcessOrder();
    this.runAfterSyncCompletedActions();
  }

  onNext() {
    this.callSync({
        action: this.activeStep.name,
    });
  }

  async callSync(paramsOverride, isAuto = false) {
      this.isProcess = true;
      const params = {
          quoteId: this.quoteId,
          ...paramsOverride
      };

      console.log('active step: ', this.activeStep);
      console.log('params: ', params);

      try {
        const res = await syncWithNGBS_v3(params);
        this.handleResponse(res);
        await this.getInfoPromise();
      } catch (res) {
        await this.handleSyncWithNGBSError(res);
      } finally {
        this.isProcess = false;
        this.manageProcessOrder();

        await this.runAfterSyncCompletedActions();
      }
  }

  handleMessages(res) {
    console.log('handleMessages: ', res);

    const isUnhandledApexError = res && res.body && res.body.message && (res.body.exceptionType || res.errorType);

    if (isUnhandledApexError) {

      const errorType = res.body.exceptionType || res.errorType;
      const maxMessageLength = 300;

      let title = `Unexpected exception occurred (${errorType})`;

      const errorMessage = res.body.message.length > maxMessageLength
        ? res.body.message.substring(0, maxMessageLength).concat('...')
        : res.body.message;

      if (res.body.message.includes('There is a duplicate value')) {
          this.isFailedWithError = true;
          title = title.substr(0, title.indexOf(' ('));
      }
      this.addMessagesProcessOrder({
        message: title,
        messageDetails: errorMessage,
        severity: 'error'
      });
    } else if (res && res.messages) {
      res.messages.forEach(m => {
        this.addMessagesProcessOrder(m);
     });
    }
  }

  addMessagesProcessOrder(message) {
    message.message = TIER_MAP.get(this.tier).tier + ': ' + message.message;
    window.dispatchEvent(new CustomEvent("AddNotificationBarMessage", {
      detail: message
    }));
  }

  async handleSyncWithNGBSError(res) {
    this.handleMessages(res);
    await updateRCCCSyncStatus({quoteId: this.quoteId});
  }

  handleResponse(res) {
    console.log('handleResponse: ', res);
    if (res.status !== 'success') {
      throw res;
    }

    if (res.data.redirectUrl) {
      window.open(res.data.redirectUrl, '_blank');
      if (this.currentStep?.name === 'SYNC_TO_ICB') {
        this.showRefreshBackdrop = true;
      }
    }

    this.handleMessages(res);
    return res.data;
  }

  get isShowNext() {
    return !this.isCompleted && this.isReady && this.activeStep;
  }

  get isShowSkip() {
    return this.activeStep && this.activeStep.skip;
  }

  get isShowSpinner() {
    return !this.isProcessOrderSpinnerShown && (!this.isReady && !this.isFailedWithError || this.isProcess);
  }

  get opportunityRecordId() {
      return this.recordId || this.opportunityId;
  }

  get stepItems() {
      const items = this.items.reduce((result, i) => {
          result[i.name] = i;
          return result;
      }, {});
      const steps = this.scenario?.steps || [];
      return steps.map(s => ({
          ...s,
          item: items[s.name]
      }))
  }

  get currentStep() {
    return this.stepItems.find(s => s.item?.isActive);
  }

  get allowCurrentStepView() {
    return ['SYNC_TO_ICB', 'SYNC_TO_INCONTACT'].includes(this.currentStep?.name);
  }

  get nextButtonLabel() {
    switch (this.activeStep?.name) {
        case 'SYNC_TO_ICB':
            return 'Open ICB';
        case 'SYNC_TO_INCONTACT':
            return 'Refresh';
        default:
            return 'Next';
    }
  }

  showOverview() {
    this.currentStepView = false;
  }

  showCurrentStep() {
    this.currentStepView = true;
  }

  get currentStepButtonCss() {
    return [
      'slds-button',
      'view-button',
      this.currentStepView && 'slds-text-link_reset'
    ].filter(Boolean).join(' ')
  }

  get overviewButtonCss() {
    return [
      'slds-button',
      'view-button',
      !this.currentStepView && 'slds-text-link_reset'
    ].filter(Boolean).join(' ')
  }

  get processOrderHeight() {
    return `${this.minHeightStyle}height: ${this.expanded ? 67 * this.items.length + 15 : 0}px;`;
  }

  get minHeightStyle() {
    return `min-height: ${this.isShowSpinner && this.expanded ? 80 : 0}px;`;
  }

  get lastIdx() {
    return this._items.length - 1;
  }

  onBackdropRefresh () {
      this.showRefreshBackdrop = false;
      this.isProcess = true;
      this.getInfoPromise()
          .then(() => this.isProcess = false);
  }

  async runAfterSyncCompletedActions() {
      try {
          if (this.isCompleted) {
              await this.updateServiceInfo();
              await this.activateOrder();
          }
      } catch (res) {
          this.handleMessages(res);
      }
  }
}