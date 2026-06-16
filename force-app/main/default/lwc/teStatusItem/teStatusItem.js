import { LightningElement, api, wire, track } from 'lwc';
import {TE_CONSTANTS} from 'c/teConstants';

export default class TeStatusItem extends LightningElement {
    @api option;

    @track isFederalExemption = false;
    @track isStateExemption = false;
    @track isCountyExemption = false;
    @track isLocalExemption = false;
    @track isVatExemption = false;
    @track isIndianExemption = false;
    @track isSalesExemption = false;

    @track isTaxTeamMember;

    @track isFederalDisabled;
    @track isStateDisabled;
    @track isCountyDisabled;
    @track isLocalDisabled;
    @track isVatDisabled;
    @track isShowVatExemption;
    @track isVATFieldsEnabled;
    @track isIndianDisabled;
    @track isSalesDisabled;

    connectedCallback() {
        window.app.rx.taxExemptionState.subscribe(taxExemptionState=>{
            this.isFederalExemption = this.option === taxExemptionState.federal;
            this.isStateExemption = this.option === taxExemptionState.state;
            this.isCountyExemption = this.option === taxExemptionState.county;
            this.isLocalExemption = this.option === taxExemptionState.local;
            this.isIndianExemption = this.option === taxExemptionState.indian;
            this.isVatExemption = this.option === taxExemptionState.vat;
            this.isSalesExemption = this.option === taxExemptionState.sales;
        })

        window.app.rx.isTaxTeamMember.subscribe(isTaxTeamMember=>{
            this.isTaxTeamMember = isTaxTeamMember;
        })

        window.app.rx.isShowVATExemption.subscribe(isShowVatExemption => {this.isShowVatExemption = isShowVatExemption;});
        window.app.rx.isVATFieldsEnabled.subscribe(isVATFieldsEnabled => {
            this.isVATFieldsEnabled = isVATFieldsEnabled;
            this.isVatDisabled = this.isVatDisabled || !this.isVATFieldsEnabled;
        });

        window.app.rx.approval.subscribe(approval => {
            const commonDisableSymptom = this.isOptionCurrent()
                || !this.isTaxTeamMember && (this.isOptionApproved() || this.isOptionRejected())
                || !this.isTaxTeamMember && !window.app.isNewStatus()
                || this.isTaxTeamMember && window.app.isPendingApproval() && this.isOptionRequested()
                || this.isTaxTeamMember && (this.isOptionApproved() || this.isOptionRejected()) && window.app.isNewStatus()
                || window.app.isApprovalApproved() || window.app.isApprovalRejected();

            this.isFederalDisabled = commonDisableSymptom || window.app.isStateCurrent(approval.record.FederalTaxExemption__c);
            this.isStateDisabled = commonDisableSymptom || window.app.isStateCurrent(approval.record.StateTaxExemption__c);
            this.isCountyDisabled = commonDisableSymptom || window.app.isStateCurrent(approval.record.CountyTaxExemption__c);
            this.isLocalDisabled = commonDisableSymptom || window.app.isStateCurrent(approval.record.LocalTaxExemption__c);
            this.isVatDisabled = commonDisableSymptom || window.app.isStateCurrent(approval.record.VATExemption__c)
                || !this.isVATFieldsEnabled;
            this.isIndianDisabled = commonDisableSymptom || window.app.isStateCurrent(approval.record.SEZWOPExemption__c);
            this.isSalesDisabled = commonDisableSymptom || window.app.isStateCurrent(approval.record.SalesTaxExemption__c) || window.app.salesExemptionDisabled;
            }
        )
    }

    isOptionCurrent() {
        return this.option === TE_CONSTANTS.APPROVAL.TAX_EXEMPTION_STATE.CURRENT;
    }

    isOptionRequested() {
        return this.option === TE_CONSTANTS.APPROVAL.TAX_EXEMPTION_STATE.REQUESTED;
    }

    isOptionApproved() {
        return this.option === TE_CONSTANTS.APPROVAL.TAX_EXEMPTION_STATE.APPROVED;
    }

    isOptionRejected() {
        return this.option === TE_CONSTANTS.APPROVAL.TAX_EXEMPTION_STATE.REJECTED;
    }

    onFederalExemptionChange(event) {
        window.app.setTaxExemptionState({federal: event.target.checked
            ? this.option
            : window.app.approval.record.FederalTaxExemption__c === this.option
                ? null
                : window.app.approval.record.FederalTaxExemption__c});
    }

    onStateExemptionChange(event) {
        window.app.setTaxExemptionState({state: event.target.checked
            ? this.option
            : window.app.approval.record.StateTaxExemption__c === this.option
                ? null
                : window.app.approval.record.StateTaxExemption__c});
    }

    onCountyExemptionChange(event) {
        window.app.setTaxExemptionState({county: event.target.checked
            ? this.option
            : window.app.approval.record.CountyTaxExemption__c === this.option
                ? null
                : window.app.approval.record.CountyTaxExemption__c});
    }

    onLocalExemptionChange(event) {
        window.app.setTaxExemptionState({local: event.target.checked
            ? this.option
            : window.app.approval.record.LocalTaxExemption__c === this.option
                ? null
                : window.app.approval.record.LocalTaxExemption__c});
    }

    onVatExemptionChange(event) {
        window.app.setTaxExemptionState({vat: event.target.checked
            ? this.option
            : window.app.approval.record.VATExemption__c === this.option
                ? null
                : window.app.approval.record.VATExemption__c});
    }

    onIndianExemptionChange(event) {
        window.app.setTaxExemptionState({indian: event.target.checked
                ? this.option
                : window.app.approval.record.SEZWOPExemption__c === this.option
                    ? null
                    : window.app.approval.record.SEZWOPExemption__c});
    }

    onSalesExemptionChange(event) {
        window.app.setTaxExemptionState({sales: event.target.checked
                ? this.option
                : window.app.approval.record.SalesTaxExemption__c === this.option
                    ? null
                    : window.app.approval.record.SalesTaxExemption__c});
    }

    get isShowUSTaxExemption() {
        return window.app && window.app.isShowUSTaxExemption();
    }

    get isShowVATTaxExemption() {
        return window.app && window.app.isShowVATTaxExemption();
    }

    get isShowIndianTaxExemption() {
        return window.app && window.app.isShowIndianTaxExemption();
    }

    get isShowSalesTaxExemption() {
        return window.app && window.app.isShowSalesTaxExemption();
    }

    get statusSLDSClass() {
        return this.isShowSalesTaxExemption
        ? 'slds-col slds-text-title_caps slds-p-top_small slds-size_2-of-7'
        : 'slds-col slds-text-title_caps slds-p-top_small slds-size_4-of-12';
    }

    get taxSLDSClass() {
        return this.isShowSalesTaxExemption
        ? 'slds-col slds-p-top_small slds-size_1-of-7'
        : 'slds-col slds-p-top_small slds-size_2-of-12';
    }
}