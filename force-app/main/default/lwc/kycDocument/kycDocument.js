import { LightningElement, api}  from 'lwc';

export default class KycDocument extends LightningElement {
    @api doc;
    @api files;
    @api isFormLocked;
    @api section;
    _isValid;

    @api
    get isValidDocument() {
        return this._isValid;
    }

    fieldsToInputsMap = {
        'isDocumentNoValid' : '.document-no',
        'isDateOfIssueValid' : '.date-of-issue',
        'isPlaceOfIssueValid' : '.place-of-issue',
        'isIssuingAuthorityValid' : '.issuing-authority',
    };

    set isValidDocument(value) {
        for (let field in value) {
            const input = this.template.querySelector(this.fieldsToInputsMap[field]);
            if (!value[field]) {
                this.setValidate(input);
            } else {
                this.clearValidate(input);
            }
        }
        this._isValid = value;
    }

    connectedCallback() {}

    get documentNo() {
        return this.doc && this.doc.documentNo;
    }
    get dateOfIssue() {
        return this.doc && this.doc.dateOfIssue;
    }
    get placeOfIssue() {
        return this.doc && this.doc.placeOfIssue;
    }
    get issuingAuthority() {
        return this.doc && this.doc.issuingAuthority;
    }

    get isFieldDisable() {
        return this.isFormLocked || this.files && window.app?.isNoActiveFilesForSection(this.section);
    }

    setValidate(input) {
        input?.setCustomValidity("Field is required");
        input?.reportValidity();
    }

    clearValidate(input) {
        input?.setCustomValidity('');
        input?.reportValidity();
    }

    onChange(event) {
        const document = {...this.doc};
        switch (event.target.dataset.id) {
            case 'document-no':
                document.documentNo = event.target.value || '';
                break;
            case 'date-of-issue':
                document.dateOfIssue = event.target.value || null;
                break;
            case 'place-of-issue':
                document.placeOfIssue = event.target.value || '';
                break;
            case 'issuing-authority':
                document.issuingAuthority = event.target.value || '';
                break;
        }
        window.app.setDocument(document);
    }
}