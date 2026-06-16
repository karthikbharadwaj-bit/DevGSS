import {Approval} from './Approval';
import {TE_CONSTANTS} from 'c/teConstants';

export class App {
    constructor() {
        this.approval = null;
        this.biId = null;

        this.options = [];
        this.taxExemptionState = {
            federal: null,
            state: null,
            county: null,
            local: null,
            vat: null,
            indian: null,
            sales: null,
        };
        this.loadingStatus = {
            isApprovalLoading: false,
            isApprovalLoaded: false,
        };
        this.errorsToShow = {};
        this.isTaxTeamMember = false;
        this.isUnsavedChanges = false;
        this.isUnableToClearExemptOnSubmit = false;
        this.isShowVATExemption = false;
        this.isVATFieldsEnabled = false;
        this.VATNumber = '';
        this.VATCountry = '';
        this.GSTNumber = '';
        this.isShowIndianExemption = false;
        this.isShowSalesExemption = false;
        this.brand = '';
        this.salesExemptionDisabled = false;

        this.rx = {
            loadingStatus: new TE.rxjs.ReplaySubject(),
            errorsToShow: new TE.rxjs.ReplaySubject(),
            // Approval
            approval: new TE.rxjs.ReplaySubject(),

            options: new TE.rxjs.ReplaySubject(),
            taxExemptionState: new TE.rxjs.ReplaySubject(),
            isTaxTeamMember: new TE.rxjs.ReplaySubject(),
            isShowVATExemption: new TE.rxjs.ReplaySubject(),
            isVATFieldsEnabled: new TE.rxjs.ReplaySubject(),
            VATNumber: new TE.rxjs.ReplaySubject(),
            VATCountry: new TE.rxjs.ReplaySubject(),
            GSTNumber: new TE.rxjs.ReplaySubject(),
            isShowIndianExemption: new TE.rxjs.ReplaySubject(),
            brand: new TE.rxjs.ReplaySubject()
        };
    }

    setBI(opportunityBI) {
        this.biId = JSON.parse(opportunityBI)?.biId;
    }

    setLoadingStatus(newLoadingStatuses = {}) {
        this.loadingStatus = Object.assign(this.loadingStatus, newLoadingStatuses);
        this.rx.loadingStatus.next(this.loadingStatus);
    }

    setSalesExemptionDisabled(disabledStatus) {
        this.salesExemptionDisabled = disabledStatus;
    }

    setApproval(approval) {
        this.approval = approval ? new Approval(approval.data.record) : null;
        this.rx.approval.next(this.approval);

        if (this.approval) {
            this.presetStatuses();
        }
    }

    presetStatuses() {
        this.setTaxExemptionState({
            federal: this.approval.record.FederalTaxExemption__c,
            state: this.approval.record.StateTaxExemption__c,
            county: this.approval.record.CountyTaxExemption__c,
            local: this.approval.record.LocalTaxExemption__c,
            vat: this.approval.record.VATExemption__c,
            indian: this.approval.record.SEZWOPExemption__c,
            sales: this.approval.record.SalesTaxExemption__c,
        });
    }

    isApprovedAny() {
        return (this.isApproved(this.approval.record.FederalTaxExemption__c)
        || this.isApproved(this.approval.record.StateTaxExemption__c)
        || this.isApproved(this.approval.record.CountyTaxExemption__c)
        || this.isApproved(this.approval.record.LocalTaxExemption__c)
        || this.isApproved(this.approval.record.SEZWOPExemption__c)
        || this.isApproved(this.approval.record.VATExemption__c)
        || this.isApproved(this.approval.record.SalesTaxExemption__c));
    }

    isApprovedAndNotSaved() {
        return (this.isApproved(this.taxExemptionState.federal)
        || this.isApproved(this.taxExemptionState.state)
        || this.isApproved(this.taxExemptionState.county)
        || this.isApproved(this.taxExemptionState.local)
        || this.isApproved(this.taxExemptionState.indian)
        || this.isApproved(this.taxExemptionState.vat)
        || this.isApproved(this.taxExemptionState.sales));
    }

    isRejectedAndNotSaved() {
        return (this.isRejected(this.taxExemptionState.federal)
        || this.isRejected(this.taxExemptionState.state)
        || this.isRejected(this.taxExemptionState.county)
        || this.isRejected(this.taxExemptionState.local)
        || this.isRejected(this.taxExemptionState.indian)
        || this.isRejected(this.taxExemptionState.vat)
        || this.isRejected(this.taxExemptionState.sales));
    }

    isRejectedAny() {
        return (this.isRejected(this.approval.record.FederalTaxExemption__c)
        || this.isRejected(this.approval.record.StateTaxExemption__c)
        || this.isRejected(this.approval.record.CountyTaxExemption__c)
        || this.isRejected(this.approval.record.LocalTaxExemption__c)
        || this.isRejected(this.approval.record.SEZWOPExemption__c)
        || this.isRejected(this.approval.record.VATExemption__c)
        || this.isRejected(this.approval.record.SalesTaxExemption__c));
    }

    isRequestedAny() {
        return (this.isRequested(this.approval.record.FederalTaxExemption__c)
        || this.isRequested(this.approval.record.StateTaxExemption__c)
        || this.isRequested(this.approval.record.CountyTaxExemption__c)
        || this.isRequested(this.approval.record.LocalTaxExemption__c)
        || this.isRequested(this.approval.record.SEZWOPExemption__c)
        || this.isRequested(this.approval.record.VATExemption__c)
        || this.isRequested(this.approval.record.SalesTaxExemption__c));
    }

    isRequestedAnyAndNotSaved() {
        return this.isRequested(this.taxExemptionState.federal)
            || this.isRequested(this.taxExemptionState.state)
            || this.isRequested(this.taxExemptionState.county)
            || this.isRequested(this.taxExemptionState.local)
            || this.isRequested(this.taxExemptionState.indian)
            || this.isRequested(this.taxExemptionState.vat)
            || this.isRequested(this.taxExemptionState.sales);
    }

    setPermissions(permission) {
        this.isTaxTeamMember = permission.data.isTaxTeamMember;
        this.rx.isTaxTeamMember.next(this.isTaxTeamMember);
    }

    setOptions(options) {
        this.options = [...options];
        this.rx.options.next(this.options);
    }

    setTaxExemptionState(taxExemptionState = {}) {
        this.taxExemptionState = Object.assign(this.taxExemptionState, taxExemptionState);
        this.rx.taxExemptionState.next(this.taxExemptionState);
    }

    setSalesTaxExemption(state) {
        this.taxExemptionState.sales = state;
        this.rx.taxExemptionState.next(this.taxExemptionState);
    }

    isApproved(exemption) {
        return exemption === TE_CONSTANTS.APPROVAL.TAX_EXEMPTION_STATE.APPROVED;
    }

    isRejected(exemption) {
        return exemption === TE_CONSTANTS.APPROVAL.TAX_EXEMPTION_STATE.REJECTED;
    }

    isRequested(exemption) {
        return exemption === TE_CONSTANTS.APPROVAL.TAX_EXEMPTION_STATE.REQUESTED;
    }

    isStateCurrent(exemption) {
        return exemption === TE_CONSTANTS.APPROVAL.TAX_EXEMPTION_STATE.CURRENT;
    }

    isPendingApproval() {
        return this.approval.record.Status__c === TE_CONSTANTS.APPROVAL.STATUS.PENDING_APPROVAL;
    }

    isNewStatus() {
        return this.approval.record.Status__c === TE_CONSTANTS.APPROVAL.STATUS.NEW;
    }

    isApprovalApproved() {
        return this.approval.record.Status__c === TE_CONSTANTS.APPROVAL.STATUS.APPROVED;
    }

    isApprovalRejected() {
        return this.approval.record.Status__c === TE_CONSTANTS.APPROVAL.STATUS.REJECTED;
    }

    isUnsavedExempts() {
        return this.isUnsavedChanges;
    }

    isRestricetedToClearExemptsOnSubmit() {
        return this.isUnableToClearExemptOnSubmit;
    }

    isExemptionPendingApproval() {
        return (this.isRequested(this.approval.record.FederalTaxExemption__c) &&
            this.isRequested(this.taxExemptionState.federal)
            || this.isRequested(this.approval.record.StateTaxExemption__c) &&
            this.isRequested(this.taxExemptionState.state)
            || this.isRequested(this.approval.record.CountyTaxExemption__c) &&
            this.isRequested(this.taxExemptionState.county)
            || this.isRequested(this.approval.record.LocalTaxExemption__c) &&
            this.isRequested(this.taxExemptionState.local)
            || this.isRequested(this.approval.record.SEZWOPExemption__c) &&
            this.isRequested(this.taxExemptionState.indian)
            || this.isRequested(this.approval.record.VATExemption__c) &&
            this.isRequested(this.taxExemptionState.vat)
            || this.isRequested(this.approval.record.SalesTaxExemption__c) &&
            this.isRequested(this.taxExemptionState.sales));
    }

    isApprovalBlocked() {
        return this.isApprovalRejected()
            && (
                this.isStateCurrent(this.approval.record.FederalTaxExemption__c)
                    && this.isStateCurrent(this.approval.record.StateTaxExemption__c)
                    && this.isStateCurrent(this.approval.record.CountyTaxExemption__c)
                    && this.isStateCurrent(this.approval.record.LocalTaxExemption__c)
                    && (!this.isAmazon || this.isStateCurrent(this.approval.record.SalesTaxExemption__c))
                ||
                this.isStateCurrent(this.approval.record.SEZWOPExemption__c)
                ||
                this.isStateCurrent(this.approval.record.VATExemption__c)
            );
    }

    isApprovalProcessing() {
        return (this.isApprovalApproved() || this.isApprovalRejected())
            && this.isRequestedAny();
    }

    get isAmazon() {
        return this.biId === TE_CONSTANTS.BI_ID_AMAZON;
    }

    setShowVATExemption(value) {
        this.isShowVATExemption = value;
        this.rx.isShowVATExemption.next(value);
    }

    setVATFieldsEnabled(value) {
        this.isVATFieldsEnabled = value;
        this.rx.isVATFieldsEnabled.next(value);
    }

    setVATNumber(value) {
        this.VATNumber = value || '';
        this.rx.VATNumber.next(this.VATNumber);
    }

    setVATCountry(value) {
        this.VATCountry = value || '';
        this.rx.VATCountry.next(this.VATCountry);
    }

    isShowUSTaxExemption() {
        return !this.isShowVATExemption && !this.isShowIndianExemption;
    }

    isShowVATTaxExemption() {
        return this.isShowVATExemption && !this.isShowIndianExemption;
    }

    isShowIndianTaxExemption() {
        return !this.isShowVATExemption && this.isShowIndianExemption;
    }

    isShowSalesTaxExemption() {
        return this.isShowSalesExemption;
    }

    setShowIndianExemption(value) {
        this.isShowIndianExemption = value;
        this.rx.isShowIndianExemption.next(value);
    }

    setShowSalesTaxExemption(value) {
        this.isShowSalesExemption = value;
    }

    setGSTNumber(value) {
        this.GSTNumber = value || '';
        this.rx.GSTNumber.next(this.GSTNumber);
    }

    setBrand(value) {
      this.brand = value || '';
    }

}