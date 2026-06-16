import { LightningElement, api } from 'lwc';
import TIME_ZONE from '@salesforce/i18n/timeZone';

const ITEM_CLASS = 'slds-progress__item_content slds-grid slds-grid_vertical slds-grid_align-spread '
export default class SnProgressItem extends LightningElement {

  @api item;
  @api steps;
  @api idx;
  @api isHideLabel = false;
  @api lastIdx;

  get step() {
    return this.steps[this.item.name];
  }

  get isStepTimingExist() {
    return Boolean(this.item.timing);
  }

  get isExecutorExist() {
    return Boolean(this.item.executorName);
  }

  get currentUserTimeZone() {
    return TIME_ZONE;
  }

  get isLastItem() {
    return this.lastIdx === this.idx;
  }

  get isSyncedClass() {
    return this.item.isSync || this.item.isSkip ? ITEM_CLASS + 'text-color':  ITEM_CLASS;
  }

}