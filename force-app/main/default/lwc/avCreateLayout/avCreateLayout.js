import { LightningElement, api, track } from 'lwc';

export default class AvCreateLayout extends LightningElement {
    _sections;
    @api
    get sections() {
        return this._sections || [];
    }
    set sections(value) {
        if (value) {
            this._sections = value;
        }
    }

    @api
    detailguid;

    @api
    recordtypename;

    @api
    headerLabel;

    @api
    checkApprovalFieldsValidity() {
        this.sections.forEach(section => {
           section.columns.forEach(column => {
               column.items.forEach(field => {

                   const fieldId = field.id;

                   let inputField = this.template.querySelector(`.fieldValidity[data-id="${fieldId}"]`);
                   if (inputField) {
                       inputField.reportValidity();
                       window.app.updateFieldValidity(this.detailguid, fieldId, inputField.checkValidity());
                   }

                   let lookupField = this.template.querySelector(`c-input-lookup[data-id="${fieldId}"]`);
                   if (lookupField && lookupField.required && !lookupField.lookupId) {
                       lookupField.setFieldValidity(false, window.app.ERROR_MESSAGES.REQUIRED_FIELD);
                       window.app.updateFieldValidity(this.detailguid, fieldId, lookupField.isValidValue);
                   }
               })
           })
        });
    }

    connectedCallback() {
       this.sections = this.validateSections();
    }

    onInputChange(event) {
        const inputField = this.template.querySelector(`.fieldValidity[data-id="${event.target.dataset.id}"]`);
        if (inputField) {
            let sections = JSON.parse(JSON.stringify(this.sections));
            this.sections = this.getSectionsWithControllingFieldOptions(inputField.value, sections);
            const value = inputField.type === 'checkbox'
                ? inputField.checked
                : inputField.value;
            window.app.updateField(this.detailguid, event.target.dataset.id, value);
        }
    }

    onInputLookupChange(event) {
        const lookupField = this.template.querySelector(`c-input-lookup[data-id="${event.target.dataset.id}"]`);
        if (lookupField) {
            window.app.updateField(this.detailguid, event.target.dataset.id, event.detail.value);
            window.app.updateFieldValidity(this.detailguid, event.target.dataset.id, lookupField.isValidValue);
        }
    }

    @api
    cScrollTo(fieldId) {
        let inputField = this.template.querySelector(`.fieldValidity[data-id="${fieldId}"]`);
        if (inputField) {
            inputField.scrollIntoView({behavior: 'smooth'});
            setTimeout(() => {inputField.focus()}, 300);

            return;
        }

        let lookupField = this.template.querySelector(`c-input-lookup[data-id="${fieldId}"]`);
        if (lookupField) {
            lookupField.scrollToField();
        }
    }

    reportCustomValidity(field, errorMessage) {
        field.setCustomValidity(errorMessage);
        field.reportValidity();
    }

    getSectionsWithControllingFieldOptions(value, sections) {
        sections.forEach(section => {
            section.columns.forEach(column => {
                column.items.forEach(field => {
                    if (field.controllerValues && field.controllerValues.hasOwnProperty(value)) {
                        field.options = field.controllerValues[value][field.fieldName];
                    }
                });
            });
        });

        return sections;
    }

    validateSections() {
        let fieldValues = [];
        let sections = JSON.parse(JSON.stringify(this.sections));
        sections.forEach(section => {
            section.columns.forEach(column => {
                column.items.forEach(field => {
                    if (field.value) {
                        fieldValues.push(field.value);
                    }
                });
            });
        });

        fieldValues.forEach(value => {
            sections = this.getSectionsWithControllingFieldOptions(value, sections);
        });

        return sections;
    }
}