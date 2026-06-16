import { LightningElement, track, api } from "lwc";
import handleSubmit from '@salesforce/apex/ProcessOrder.handleSubmit';
const MAX_ITEMS = 5;
export default class SnOrderToVendorTable extends LightningElement {
    @api disabledGeneralInfo;
    @api opportunityId;
    @api existing;
    @track currentPage = 1;
    @track currency = 'USD';
    @track orderToVendorItems = [];
    orderToVendorMap = new Map();
    nicLicensesItems;
    accountParams;

    get isLargeOrder() {
        return this.orderToVendorItems.length > MAX_ITEMS;
    }

    get totalPriceTitle() {
        return `Total Price (${this.currency})`;
    }

    get listPrice() {
        return `List Price (${this.currency})`;
    }

    get priceToVendor() {
        return `Price to Vendor (${this.currency})`;
    }

    @api
    get isReadyForGetOrderToVendorCatalog() {}

    set isReadyForGetOrderToVendorCatalog(value) {
        if (value) {
            handleSubmit({
                params: JSON.stringify({
                    action: "request order to vendor",
                    targetId: this.opportunityId,
                    isChangeOrder: this.existing
                }),
            })
                .then((res) => this.handleResponse(res))
                .catch((res) => this.handleError(res));
        }
    }

    passNicItems() {
        this.nicLicensesItems = this.orderToVendorItems.map(item => (
            {
                vendorSKU: item.vendorSKU,
                priceToVendor: item.priceToVendor,
                newQuantity: this.existing ? item.newQuantity : item.quantity
            }
        ));
        this.dispatchEvent(
            new CustomEvent("passniclicensesitems", {
                detail: {
                    nicLicensesItems: this.nicLicensesItems,
                    accountParams: this.accountParams
                }
            })
        );
    }

    get pagesQuantity() {
        return Math.ceil(this.orderToVendorItems.length / MAX_ITEMS);
    }

    get offset() {
        return (this.currentPage - 1) * MAX_ITEMS;
    }

    get page() {
        return this.orderToVendorItems.slice(this.offset, this.offset + MAX_ITEMS);
    }

    get sumOrderAmount() {
        let sum = 0;
        this.orderToVendorItems.forEach((item) => (sum += item.totalPrice));
        return sum;
    }

    sendLengthDetails() {
        const currentLength = this.isLargeOrder ? this.page.length + 1 : this.page.length;
        this.dispatchEvent(
            new CustomEvent("bodyheight", {
                detail: {
                    length: currentLength,
                },
            })
        );
    }

    handleChangePage({ detail }) {
        this.currentPage = detail.page;
        this.sendLengthDetails();
    }

    handleResponse(response) {
        const res = JSON.parse(response);

        if (res.messages && res.messages.length > 0 && res.messages.some(m => m.severity === 'error')) {
            res.messages.filter(m => m.severity === 'error')
            .forEach(m => this.addMessagesProcessOrder(m));

            return Promise.reject();
        }

        this.orderToVendorItems = res.data.body.nicLicenses.items;
        this.accountParams = res.data.body.accountParams;

        this.orderToVendorItems.forEach(item => {
            this.orderToVendorMap.set(item.name, item);
        });

        this.currency = res.data.body.nicLicenses.currency.toUpperCase();
        this.sendLengthDetails();
        if (this.orderToVendorItems.length !== 0) {
            this.passNicItems();
        }
    }

    handleError(errorResponse) {
        if (!errorResponse) {
            return;
        }
        const errorMessage = {
            messageDetails: errorResponse.body?.message || errorResponse,
            severity: 'error'
        }
        this.addMessagesProcessOrder(errorMessage);
    }


    addMessagesProcessOrder(message) {
        window.dispatchEvent(new CustomEvent("AddNotificationBarMessage", {
          detail: message
        }));
    }

    handlePriceToVendorChange(event) {
        const inputCmp = this.template.querySelector(`[data-id="${event.target.label}"]`);
        const item = this.orderToVendorMap.get(event.target.label);

        if (!Boolean(event.target.value)) {
            inputCmp.setCustomValidity('Invalid value.');
        } else if (event.target.value > item.listPrice) {
            inputCmp.setCustomValidity(`Cannot be more than ${item.listPrice}.`);
        } else if (event.target.value < 0) {
            inputCmp.setCustomValidity('Cannot be less than 0.');
        } else {
            inputCmp.setCustomValidity('');

            item.priceToVendor = +event.target.value;
            item.totalPrice = Math.max(item.priceToVendor * (this.existing ? item.newQuantity : item.quantity), 0);

            this.orderToVendorItems = Array.from(this.orderToVendorMap.values());
            this.passNicItems();
        }
        inputCmp.reportValidity();
    }

    get tableStyle() {
        return "slds-table slds-table_cell-buffer slds-table_bordered"
            + (this.disabledGeneralInfo ? " table-disabled" : "");
    }

    get quantityLabel() {
        return (this.existing ? "Change " : "") + "Quantity";
    }

    get paginationCells() {
        return this.existing ? "9" : "7";
    }

    get totalSumRowCells() {
        return `${+this.paginationCells - 1}`;
    }
}