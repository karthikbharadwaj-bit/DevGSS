import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import getRequestFormLink from '@salesforce/apex/IcbHelper.getRequestFormLink';
import ACCOUNT_MIGRATION_FLAG from '@salesforce/schema/Account.AccMigrationFlag__c';
import { ACCOUNT_MIGRATION_STATUSES } from "c/snUtils";


export default class AccountMigrationWarning extends LightningElement {
  @api
  recordId;
  formLink;
  accMigrationFlag;

  @wire(getRecord, { recordId: '$recordId', fields: [ACCOUNT_MIGRATION_FLAG] })
  wireRecord({data}) {
    this.accMigrationFlag = data?.fields?.AccMigrationFlag__c?.value;
  }

  connectedCallback() {
    getRequestFormLink()
    .then(res => {
      if (res.status !== 'success') {
        return;
      }
      this.formLink = res.data.formLink;
    });
  }

  get isMigrationInProgressBlocked() {
    return ACCOUNT_MIGRATION_STATUSES.BLOCKING_ACCOUNT_MIGRATION_STATUSES.includes(this.accMigrationFlag);
  }

  get iconType() {
    return this.isMigrationInProgressBlocked ? 'error' : 'warning';
  }

  get showSpinner() {
    return !Boolean(this.accMigrationFlag);
  }

  get iconVariant() {
    return this.iconType === 'error' ? 'inverse' : '';
  }

  get iconName() {
    return `utility:${this.iconType}`;
  }

  get iconAlternativeText() {
    return `${this.iconType.charAt(0).toUpperCase() + this.iconType.slice(1)}!`;
  }

  get mainTheme() {
    return `slds-scoped-notification slds-media slds-media_center slds-theme_${this.iconType}`;
  }
}