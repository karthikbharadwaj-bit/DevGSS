import { LightningElement, api } from 'lwc';

export default class SnChangePartnerProgressItem extends LightningElement {

  @api item;
  @api steps;
  @api idx;
  @api isHideLabel = false;

  get step() {
    return this.steps[this.item.name];
  }
}