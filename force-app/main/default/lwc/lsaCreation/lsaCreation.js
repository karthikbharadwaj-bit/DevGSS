import { api, LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import LocalSubscribedAddress from '@salesforce/schema/LocalSubscribedAddress__c';

export default class LsaCreation  extends NavigationMixin(LightningElement) {
    billingAddress = 'Billing Address';

    @track recordTypes;
    @track selectedRecordType;

    @api recordId;

    @wire(getObjectInfo, {objectApiName:LocalSubscribedAddress})
    getData({data,error}) {

        this.recordTypes = data
            && data.recordTypeInfos
            && Object.values(data.recordTypeInfos)
                .filter(rtInfo => !rtInfo.master && rtInfo.name != this.billingAddress)
                .map(rtInfo => {
                    return {
                        label: rtInfo.name,
                        value: rtInfo.recordTypeId
                    };
                });
        this.selectedRecordType = this.recordTypes && this.recordTypes.length && this.recordTypes[0].value;
    }

    onSubmit() {
        const defaultValues = encodeDefaultFieldValues({
            Approval__c: this.recordId
        });

        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'LocalSubscribedAddress__c',
                actionName: 'new'
            },
            state: {
                defaultFieldValues: defaultValues,
                recordTypeId: this.selectedRecordType,
                nooverride: "1"
            }
        });
    }

    onCancel() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'LocalSubscribedAddress__c',
                actionName: 'view'
            }
        });
    }

    onRecordTypeSelected(evt) {
        this.selectedRecordType = evt.detail.value;
    }
}