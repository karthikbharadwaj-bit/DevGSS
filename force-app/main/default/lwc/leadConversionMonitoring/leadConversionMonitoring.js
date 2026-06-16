import { LightningElement, api } from "lwc";
import { NavigationMixin } from 'lightning/navigation';
import getLastErrorLeadConversionCPUMonitor from "@salesforce/apex/LeadConversionMonitoringHelper.getLastErrorLeadConversionCPUMonitor";
import getCPUMonitorByRecordId from "@salesforce/apex/LeadConversionMonitoringHelper.getCPUMonitorByRecordId";

export default class LeadConversionMonitoring extends NavigationMixin(LightningElement) {
    @api recordId;
    cpuMonitor;
    cpuMonitorCreatedDate;
    get cpuMonitorDateDifference() {
        let difference = (new Date() - Date.parse(this.cpuMonitorCreatedDate)) / (1000*60);
        if (difference < 60) {
            return ' (' + Math.floor(difference) + ' minute/s ago)';
        } else if (difference / 60 < 24) {
            return ' (' + Math.floor(difference / 60) + ' hour/s ago)';
        } else if (difference / (60 * 24) < 30) {
            return ' (' + Math.floor(difference / (60 * 24)) + ' day/s ago)';
        } else {
            return ' (' + Math.floor(difference / (60 * 24 * 30)) + ' month/s ago)';
        }
    }
    leadRecordType;
    hasRendered = false;
    successBoxes = [];
    showArrows = [];
    failBox;
    showErrorDate = false;

    async renderedCallback() {
        if (!this.hasRendered) {
            if (this.recordId){
                let that = this;
                this.cpuMonitor = await getCPUMonitorByRecordId({recordId : that.recordId});
            } else {
                this.cpuMonitor = await getLastErrorLeadConversionCPUMonitor();
                this.showErrorDate = true;
            }
            if (this.cpuMonitor) {
                this.cpuMonitorCreatedDate = this.cpuMonitor.CreatedDate;
                this.leadRecordType = this.cpuMonitor.Lead_Type__c;
                this.showMonitor(true);
                this.getBoxes();
                this.addClassToBoxes();
                this.addClassToArrows();
            } else {
                this.showMonitor(false);
            }
            this.hasRendered = true;
        }
    }

    getBoxes() {
        let usedBoxes = ["PrepareLead", "ConvertLead"];
        if (this.cpuMonitor.Create_Account__c) {
            usedBoxes.push("CreateAccount");
        } else {
            usedBoxes.push("ExistingAccount");
        }
        if (this.cpuMonitor.Create_Opportunity__c) {
            usedBoxes.push("CreateOpportunity");
        } else if (this.cpuMonitor.Opportunity__c !== undefined) {
            usedBoxes.push("ExistingOpportunity");
        } else {
            usedBoxes.push('MergeContactOnly');
        }
        if (this.cpuMonitor.Create_Quotes__c) {
            usedBoxes.push("CreateQuotes");
        }
        if (this.cpuMonitor.Is_ELA_Account__c) {
            usedBoxes.push("ELAAccount");
        }
        if (this.cpuMonitor.Error__c) {
            this.failBox = this.cpuMonitor.Error_part__c;
            let errorIndex = usedBoxes.indexOf(this.cpuMonitor.Error_part__c);
            this.successBoxes = errorIndex !== -1 ? usedBoxes.slice(0, errorIndex) : usedBoxes;
        } else {
            this.successBoxes = usedBoxes;
        }
    }

    addClassToBoxes() {
        const boxes = this.template.querySelectorAll(".slds-box");
        for (let i = 0; i < boxes.length; i++) {
            if (this.successBoxes.includes(boxes[i].dataset.id)) {
                boxes[i].classList.remove("slds-theme_shade");
                boxes[i].classList.add("slds-theme_success");
                const boxIndex = this.successBoxes.indexOf(boxes[i].dataset.id);
                if (boxIndex > 0) {
                    this.showArrows.push(this.successBoxes[boxIndex - 1] + this.successBoxes[boxIndex]);
                }
            }
            if (this.failBox && this.failBox === boxes[i].dataset.id) {
                boxes[i].classList.remove("slds-theme_shade");
                boxes[i].classList.add("slds-theme_error");
                if (!this.recordId) {
                    boxes[i].setAttribute("title",this.cpuMonitor.Error__c);
                    boxes[i].classList.add("pointer");
                }
                if (this.successBoxes.length > 0) {
                    this.showArrows.push(this.successBoxes[this.successBoxes.length - 1] + this.failBox);
                }
            }
        }
    }

    addClassToArrows() {
        const arrows = this.template.querySelectorAll(".arrow");
        for (let i = 0; i < arrows.length; i++) {
            if (this.showArrows.includes(arrows[i].dataset.id)) {
                arrows[i].classList.remove("hideElement");
            }
            if (arrows[i].dataset.id === "VariableArrow" && this.showArrows.length > 2) {
                arrows[i].classList.remove("hideElement");
                arrows[i].classList.add(this.showArrows[2]);
            }
        }
    }

    showMonitor(showMonitor) {
        if (showMonitor) {
            let showElement = this.template.querySelector('[data-id="monitor"]');
            showElement.classList.remove("hideElement");
        } else {
            let noMonitorMsg = this.template.querySelector('[data-id="noMonitorMsg"]');
            noMonitorMsg.classList.remove("hideElement");
        }
    }

    redirectToError(event) {
        if (event.currentTarget.dataset.id === this.failBox) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.cpuMonitor.Id,
                    objectApiName: 'CPU_Monitor__c',
                    actionName: 'view'
                }
            });
        }
    }
}