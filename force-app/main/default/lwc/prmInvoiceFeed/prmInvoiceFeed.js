import { LightningElement } from 'lwc';

import invoiceFeedColumns from './columnDefinition';

import getInvoiceFeedForPartner from '@salesforce/apex/Partner_Invoice_Feed.getInvoiceFeedForPartner';
import searchPartnerAccountUsingName from '@salesforce/apex/Partner_Invoice_Feed.searchPartnerAccountUsingName';
import getInvoiceReportForPartner from '@salesforce/apex/Partner_Invoice_Feed.getInvoiceReportForPartner';

export default class PrmInvoiceFeed extends LightningElement {
  searchValue;
  showSearchResults = false;
  searchResult = [];
  invoiceFeedColumns = invoiceFeedColumns;
  invoiceFeed;

  handleSearchInputChange = (event) => {
    this.searchValue = event.detail.value;
    if (this.searchValue) {
      setTimeout(async () => {
        this.showSearchResults = true;
        this.searchResult = await searchPartnerAccountUsingName({ name: `%${this.searchValue}%` });
      }, 1000);
    } else {
      this.searchResult = [];
    }
  }

  handlePartnerSelection = async (event) => {
    if (event.currentTarget.dataset.item) {
      console.log(this.invoiceFeed);
      this.searchValue = event.currentTarget.dataset.name;
      this.invoiceFeed = JSON.parse(await getInvoiceFeedForPartner({ ngbsPartnerId: event.currentTarget.dataset.item }));
    }
    this.showSearchResults = false;
  }

  handleRowAction = async (event) => {
    const action = event.detail.action;
    const row = event.detail.row;
    switch (action.name) {
      case 'download':
        const response = await getInvoiceReportForPartner({ ngbsPartnerId: row.partnerId, reportId: row.reportId });
        
        //Download Logic
        const hiddenElement = document.createElement('a');
        hiddenElement.href = 'data:' + row.contentType + ';charset=utf-8,' + encodeURI(response);
        hiddenElement.target = '_self';
        hiddenElement.download = row.fileName;
        document.body.appendChild(hiddenElement);
        hiddenElement.click();
        document.body.removeChild(hiddenElement);
        break;
        //Download Logic
    }
  }
}