import { LightningElement, api } from 'lwc';
const CONTAINER = 'combobox';
const INPUT = 'input';
export default class SearchableDropdown extends LightningElement {
    @api comboboxOptions;
    @api sldsModalEl;
    @api width;
    @api disabled = false;
    @api placeholder = 'Search...';
    @api label;
    @api required = false;

    inputText = null;
    container;
    selectedItem = null;
    searchResults = [];
    hideError = true;

    @api
    get selectedValue() {}

    set selectedValue(value) {
        if (value) {
            this.inputText = value;
        }
    }

    get emptyResult() {
        return this.searchResults.length === 0
    }

    get hideIcon() {
        return this.inputText && this.disabled;
    }

    get icon() {
        return this.inputText ? 'utility:close' : 'utility:search';
    }

    get iconClass() {
        return [
            'slds-input__icon slds-input__icon_right',
            this.inputText && 'close-hover',
            'icon',
        ].filter(Boolean).join(' ');
    }

    get formElementClass() {
        return [
            'slds-form-element',
            this.isError && 'slds-has-error',
        ].filter(Boolean).join(' ');
    }

    get inputClass() {
        return [
            'slds-input slds-combobox__input',
            'input-text',
            this.isError && 'error'
        ].filter(Boolean).join(' ');
    }

    get isError() {
        return Boolean(this.errorMessage);
    }

    get errorMessage() {
        if (!this.required) {
            return null;
        }

        return !this.hideError && 'Complete this field.' || '';
    }

    onFocus() {
        this.showDropdownOptions();
    }

    onBlur() {
        this.hideError = this.validateInput();
        this.toggleDropdown(false);
    }

    validateInput() {
        return Boolean(this.selectedItem) && this.selectedItem.label === this.inputText;
    }

    onSelect(event) {
        this.modifyItem(event.currentTarget.dataset.value);
        this.inputText = this.selectedItem.label;
        this.toggleDropdown(false);

        this.fireEvent(this.selectedItem.value);
    }

    modifyItem(itemValue) {
        this.searchResults = this.comboboxOptions.reduce((result, item) => {
            if (item.value === itemValue) {
                this.selectedItem = {...item, selected: true};
                result.unshift(this.selectedItem);
            } else {
                result.push(item);
            }
            
            return result;
        }, []);
    }

    fireEvent(value) {
        this.dispatchEvent(new CustomEvent('change', {
            detail: {value: value}
        }));
    }

    onEnterData(event) {
        this.inputText = event.target.value;
        this.searchResults = this.comboboxOptions.filter((result) => {
            return result.label.toLowerCase().includes(this.inputText.toLowerCase());
        })

        this.fireEvent(null);
    }

    clearResults() {
        this.searchResults = [];
    }

    removeItem() {
        this.inputText = null;
        this.selectedItem = null;
        this.toggleDropdown(true);
        this.searchResults = this.comboboxOptions;

        const input = this.getElement(INPUT);
        input.focus();

        this.fireEvent(null);
    }

    toggleDropdown(isOpen) {
        if (!this.container) {
            this.container = this.getElement('container');
        }
        
        if (isOpen) {
            this.container.classList.add('slds-is-open');
            return;
        }

        this.container.classList.remove('slds-is-open');
    }

    showDropdownOptions() {
        if (this.searchResults.length === 0 && !this.inputText && this.comboboxOptions) {
            this.searchResults = this.comboboxOptions;
        }

        this.setDropdownPosition();
        this.toggleDropdown(true);
    }

    setDropdownPosition() {
        const input = this.getElement(INPUT);
        let dropdown = this.getElement(CONTAINER);

        if (!input || !dropdown) {
            return;
        }

        const inputRect = input.getBoundingClientRect();
        const modalRect = this.sldsModalEl.getBoundingClientRect();

        dropdown.style.position = 'fixed';
        dropdown.style.top = `${inputRect.top + inputRect.height}px`;
        dropdown.style.left = `${inputRect.left - modalRect.left}px`;
        dropdown.style.width = `${inputRect.width}px`;
        dropdown.style.zIndex = 9101;
    }

    getElement(dataId) {
        return this.template.querySelector(`[data-id="${dataId}"]`);
    }

    @api
    clearSelection() {
        this.inputText = null;
        this.selectedItem = null;
        this.searchResults = this.comboboxOptions;
    }
}