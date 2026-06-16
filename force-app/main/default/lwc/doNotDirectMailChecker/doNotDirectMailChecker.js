import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import getDoNotDirectMail from '@salesforce/apex/DoNotDirectMailChecker.getDoNotDirectMail';

const OPTIONAL_FIELDS = [
  'Lead.Name','Lead.Email','Lead.Company','Lead.Street','Lead.City','Lead.State','Lead.PostalCode','Lead.Country',
  'Contact.Name','Contact.Email','Contact.MailingStreet','Contact.MailingCity','Contact.MailingState','Contact.MailingPostalCode',
  'Contact.MailingCountry','Contact.Account.Name'
];

export default class DoNotDirectMailChecker extends NavigationMixin(LightningElement) {
  @api recordId;
  @track record;
  objectName;
  wiredRecord; // <-- store the full wire result

  @wire(getRecord, { recordId: '$recordId', optionalFields: OPTIONAL_FIELDS })
  wiredRecord(result) {
    this.wiredRecord = result;// keep handle for refreshApex
    const { data, error } = result;
    if (data) {
      this.record = data;
      this.objectName = data.apiName;
    } else if (error) {
      
      console.error('[HeadlessLogger] wire error:', JSON.stringify(error?.body || error));
    }
  }

  @api
  async invoke() {
    if (!this.recordId) return;

    // ✅ Always refresh LDS before reading fields / deciding what to do
    if (this.wiredRecord) {
      await refreshApex(this.wiredRecord);
      this.record = this.wiredRecord.data;
    }

    // derive object if needed
    if (!this.objectName && this.recordId) {
      const p = this.recordId.substring(0, 3);
      this.objectName = p === '00Q' ? 'Lead' : (p === '003' ? 'Contact' : 'Unknown');
    }

    try {
      // ✅ Non-cacheable Apex ensures the latest DND flag
      const result = await getDoNotDirectMail({ recordId: this.recordId });
      const doNotSend = result?.doNotDirectMail === true;

      if (doNotSend) {
        this.dispatchEvent(new ShowToastEvent({
          title: 'Blocked',
          message: 'This person is opted out of Direct Mail under Communications Preferences. You cannot send a gift.',
          variant: 'error'
        }));
        this.dispatchEvent(new CloseActionScreenEvent());
        return;
      }

      if (!this.record) {
        this.dispatchEvent(new ShowToastEvent({
          title: 'Please try again',
          message: 'Record details are still loading.',
          variant: 'warning'
        }));
        this.dispatchEvent(new CloseActionScreenEvent());
        return;
      }

      const rec = this.record;
      const val = (f) => rec?.fields?.[f]?.value ?? '';
      const enc = (s) => encodeURIComponent(s ?? '');
      let url = 'https://app.sendoso.com/v2/plugin/sends?channel=salesforce';

      if (this.objectName === 'Lead') {
        url += `&name=${enc(val('Name'))}`
             + `&email=${enc(val('Email'))}`
             + `&company_name=${enc(val('Company'))}`
             + `&address=${enc(val('Street'))}`
             + `&city=${enc(val('City'))}`
             + `&state=${enc(val('State'))}`
             + `&zip=${enc(val('PostalCode'))}`
             + `&country=${enc(val('Country'))}`;
      } else if (this.objectName === 'Contact') {
        const accountName = rec?.fields?.Account?.value?.fields?.Name?.value ?? '';
        url += `&name=${enc(val('Name'))}`
             + `&email=${enc(val('Email'))}`
             + `&company_name=${enc(accountName)}`
             + `&address=${enc(val('MailingStreet'))}`
             + `&city=${enc(val('MailingCity'))}`
             + `&state=${enc(val('MailingState'))}`
             + `&zip=${enc(val('MailingPostalCode'))}`
             + `&country=${enc(val('MailingCountry'))}`;
      } else {
        this.dispatchEvent(new CloseActionScreenEvent());
        return;
      }

      this.dispatchEvent(new CloseActionScreenEvent());
      requestAnimationFrame(() => {
        try {
          this[NavigationMixin.Navigate]({ type: 'standard__webPage', attributes: { url } });
        } catch {
          window.open(url, '_blank');
        }
      });
    } catch (e) {
      
      console.error('[HeadlessLogger] Apex error:', e);
      this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: 'Failed to evaluate send eligibility.', variant: 'error' }));
      this.dispatchEvent(new CloseActionScreenEvent());
    }
  }
}