import { LightningElement, track, api } from "lwc";

import createProblemCase from "@salesforce/apex/CaseHelper.createProblemCase";
import getAccountNameById from "@salesforce/apex/AccountHelper.getAccountNameById";
import getLeadNameById from "@salesforce/apex/LeadHelper.getLeadNameById";

export default class LwcReportProblemModal extends LightningElement {
    @track isModalOpen;
    @track isError;
    @api leadConvert;
    @api quickOpptyPage;
    @api signUp;

    _leadId;
    @api 
    get leadId() {
        return this._leadId;
    }

    set leadId(lId) {
        this._leadId = lId;

        if (lId && !this.leadName) {
            this.leadName = 'Loading...';
            getLeadNameById({ leadId: this.leadId })
                .then((res) => this.handleResponse(res))
                .then((data) => (this.leadName = data.Name));
        }

        if (!lId) {
            this.leadName = null;
        }
    }

    _accountId;
    @api 
    get accountId() {
        return this._accountId;
    }

    set accountId(accId) {
        this._accountId = accId;

        if (accId && !this.accName) {
            this.accName = 'Loading...';
            getAccountNameById({ accId: this.accountId })
                .then((res) => this.handleResponse(res))
                .then((data) => (this.accName = data.Name));
        }

        if (!accId) {
            this.accName = null;
        }
    }
    @api opportunityId;
    @api accName;
    @track leadName;

    wholesaleSubject = "Wholesale_Partner_Operations";
    leadConvertSubject = "Lead_Convert_Issue";
    quickOpptySubject = "Create_Opportunity_Issue";
    signUpSubject = "Sing_Up_Issue";
    descriptionText;

    openModal() {
        this.isModalOpen = true;
        this.isError = false;
    }

    closeModal() {
        this.isModalOpen = false;
    }

    errorShown() {
        this.descriptionText = this.template.querySelector("textarea").value;

        if (!this.descriptionText) {
            this.isError = true;
            this.template.querySelector(".slds-textarea:invalid").style = "border-color:red";
            return;
        }

        this.isError = false;
        this.template.querySelector(".slds-textarea").style = "border-color:gray";
    }

    submitDetails() {
        this.descriptionText = this.template.querySelector("textarea").value;

        if (!this.descriptionText) {
            this.isError = true;
            this.template.querySelector(".slds-textarea:invalid").style = "border-color:red";
            return;
        }

        createProblemCase({
            leadId: this.leadId,
            accId: this.accountId,
            oppId: this.opportunityId,
            description: this.descriptionText,
            caseSubject: this.caseSubject,
        })
        .then((res) => this.handleResponse(res))
        .then((this.isModalOpen = false));
    }

    handleResponse(res) {
        if (res.status !== "success") {
            throw res;
        }

        this.handleMessages(res);
        return res.data;
    }

    showToast({ title, message, type = "info", duration, caseId = null, caseNumber = null }) {
        window.dispatchEvent(
            new CustomEvent("ShowToastEvent", {
                detail: { title, message, type, duration, caseId, caseNumber },
            })
        );
    }

    handleMessages(res) {
        console.log("handleMessages: ", res);

        const isUnhandledApexException = res?.body?.exceptionType && res.body.message;

        if (isUnhandledApexException) {
            const maxMessageLength = 300;

            const title = `Unexpected exception occurred (${res.body.exceptionType})`;

            const errorMessage =
                res.body.message.length > maxMessageLength
                    ? res.body.message.substring(0, maxMessageLength).concat("...")
                    : res.body.message;

            this.showToast({
                title: title,
                message: errorMessage,
                type: "error",
                duration: false,
            });
        } else if (res && res.messages) {
            res.messages.forEach((m) => {
                this.showToast({
                    title: m.message,
                    message: m.messageDetails,
                    type: m.severity || m.status,
                    duration: false,
                    caseId: res.data?.caseId,
                    caseNumber: res.data?.caseNumber,
                });
            });
        }
    }

    get caseSubject() {
        if (this.leadConvert) {
            return this.leadConvertSubject;
        }

        if (this.quickOpptyPage) {
            return this.quickOpptySubject;
        }

        if (this.signUp) {
            return this.signUpSubject;
        }
        return this.wholesaleSubject;
    }

    get caseTitle() {
        return this.caseSubject.split("_").join(" ");
    }

    get backdrop() {
        return `slds-backdrop slds-backdrop_open ${this.signUp ? "custom_backdrop" : ""}`;
    }
}