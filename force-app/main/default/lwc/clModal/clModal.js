import {LightningElement, track} from 'lwc';
import ByeditingtheAccount from '@salesforce/label/c.clModalByeditingtheAccount';

export default class LWCModal extends LightningElement {

    @track isOpenModal = false;
    @track label = {
        ByeditingtheAccount
    };
    connectedCallback() {
        window.addEventListener('onEditSelectedAccount', this.handleOpenModal.bind(this));
    }

    handleOpenModal() {
        if (!CL.app.isCreateNewAccount) {
            this.isOpenModal = true;
        } else {
            window.dispatchEvent(new CustomEvent('onEditIsOkay', { bubbles: true, composed: true }));
        }
    }

    handleCloseModal() {
        this.isOpenModal = false;
        window.dispatchEvent(new CustomEvent('onEditIsOkay', { bubbles: true, composed: true }));
    }

    handleCancelModal() {
        this.isOpenModal = false;
        window.dispatchEvent(new CustomEvent('onCancel', { bubbles: true, composed: true }));
    }
}