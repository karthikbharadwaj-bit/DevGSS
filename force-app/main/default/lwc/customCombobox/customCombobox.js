import { LightningElement, api, track } from 'lwc';

export default class CustomCombobox extends LightningElement {
    _options;
    @api 
    get options() {
        return this._options;
    }

    set options(value) {
        if (value) {
            this._options = JSON.parse(JSON.stringify(value));
        }
    }

    _selectedValue;
    @api
    get selectedValue() {
        return this._selectedValue;
    };

    set selectedValue(value) {
        this._selectedValue = value;
        if (!this.options?.find(o => o.value === value)?.isSelected) {
            this.selectItem();
        }
    }

    @api errorMessage;
    @api label;
    @api disabled = false;
    @api required = false;
    @api placeholder = 'Select an Option';
    @api isRelativePosition;
    @api initiallyOpen;
    isOpen = false;
    incorrectValue;
    isInitialized = false;

    get valueOrPlaceholder() {
        return this.options?.find(option => option.value === this.selectedValue)?.label || this.placeholder;
    }

    get isError() {
        return Boolean(this.errorMessage);
    }
    get errorFrame() {
        return this.isError && !this.isOpen;
    }

    get dropDownClass() {
        return `slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click ${this.isOpen || this.initiallyOpen ? 'slds-is-open' : ''}`;
    }

    get dropDownPositionClass() {
        return `slds-dropdown hidden-scrollbar slds-dropdown_length-5 slds-dropdown_fluid slds-dropdown_left ${this.isRelativePosition ? 'dropdown-position' : ''}`;
    }

    get formElementClass() {
        return `slds-form-element ${this.isError ? 'slds-has-error' : ''}`;
    }

    get buttonClass() {
        return `slds-input_faux slds-combobox__input ${this.errorFrame ? 'error-frame' : this.disabled ? 'disabled-frame' : ''}`;
    }

    get placeholderColor() {
        return `slds-truncate ${this.selectedValue && !this.disabled ? 'placeholder-color' : ''}`;
    }

    renderedCallback() {
        if (this.errorMessage && !this.incorrectValue && !this.isInitialized) {
            this.incorrectValue = this.selectedValue;
            this.isInitialized = true;
        }

        if (this.initiallyOpen) {
            this.isOpen = true;
            this.template.querySelector('[data-id="picklist-button"]')?.focus();
        }
    }

    handleClick() {
        this.isOpen = !this.isOpen;
        this.closeDropdownEvent();
    }

    handleBlur() {
        if (!this.selectedValue && this.required) {
            this.errorMessage = 'Complete this field.';
        }
        if (this.incorrectValue !== this.selectedValue || (this.selectedValue && this.required)) {
            this.errorMessage = '';
            this.incorrectValue = '';
        }
        this.close();
    }

    close() {
        this.isOpen = false;
        this.closeDropdownEvent();
    }

    closeDropdownEvent() {
        this.initiallyOpen && this.dispatchEvent(new CustomEvent('closedropdown'));
    }

    clickItem(event) {
        this.selectedValue = event.currentTarget.dataset.id;
    }

    selectItem() {
        this.options?.forEach(item => {
            item.isSelected = item.value === this.selectedValue;
            if (item.isSelected) {
                const selectedOption = {
                    value: item.value,
                    label: item.label
                };
                this.dispatchEvent(new CustomEvent('change', { detail: selectedOption }));
            }
        });
    }
}