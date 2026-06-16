import { LightningElement, track } from 'lwc';
import { CHOOSE_PRIMARY_QUOTE, POC, SALES } from "c/snUtils";

export default class SnQuoteSelectPrompt extends LightningElement {

    options = [
        { label: SALES, isChecked: true},
        { label: POC },
    ];
    @track isShowQuotesToSelect = true;

    handleClick() {
        this.isShowQuotesToSelect = !this.isShowQuotesToSelect;
    }

    handleChange(event) {
        const label = event.target.value;
        this.options.forEach(item => item.isChecked = item.label === label)
        this.dispatchEvent(new CustomEvent('pickquotetype', { detail: label }));
    }

    get choosePrimaryQuote() {
        return CHOOSE_PRIMARY_QUOTE;
    }

    get chevron() {
        return `utility:chevron${this.isShowQuotesToSelect ? "down" : "right"}`
    }

    get titleStyle() {
        return `slds-page-header__title step-title title-block ${this.opened ? "opened" : "closed" }-quote-select-prompt`;
    }

    get sectionClasses() {
        return `expandable ${this.isShowQuotesToSelect ? "expanded" : ""}`
    }

}