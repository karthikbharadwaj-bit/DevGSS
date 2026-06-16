import { api, LightningElement } from 'lwc';

export default class kycParticipationAgreement extends LightningElement {
    @api approval;
    @api participationAgreementFiles;
    @api isFormLocked;
    _isValid;

    @api
    get isValidPSADate() {
        return this._isValid;
    }

    set isValidPSADate(value) {
        const inputCmp = this.template.querySelector('.dateOfSign');
        if (!value) {
            inputCmp?.setCustomValidity("Enter date before saving, field is required");
            inputCmp?.reportValidity();
        } else if (!this._isValidValue && value) {
            inputCmp?.setCustomValidity('');
            inputCmp?.reportValidity();
        }
        this._isValid = value;
    }

    get dateOfSign() {
        return this.approval && this.approval.dateOfSign;
    }

    get isDateOfSignDisable() {
        return this.isFormLocked || this.participationAgreementFiles && window.app?.isNoActiveFilesForSection(window.app.sections.PARTICIPATION_AGREEMENT);
    }

    connectedCallback() {}

    onChange(event) {
        const app = {...this.approval};
        switch (event.target.dataset.id) {
            case 'dateOfSign':
                app.dateOfSign = event.target.value || '';
                break;
        }

        window.app.updateApproval(app);
    }
}