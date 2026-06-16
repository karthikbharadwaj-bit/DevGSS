import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import fetchRelatedFiles from '@salesforce/apex/MassDownloadFilesController.fetchRelatedFiles';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class BulkDownloadFiles extends LightningElement {
    @track files = [];
    @track selectedFiles = new Set();
    @track isLoading = true;
    
    _recordId;

    get allFilesSelected() {
        return this.files.length > 0 && this.selectedFiles.size === this.files.length;
    }

    get isDownloadDisabled() {
        return this.selectedFiles.size === 0;
    }

    @api 
    get recordId() {
        return this._recordId;
    }

    set recordId(value) {
        if (value) {
            this._recordId = value;
            this.loadFiles();
        }
    }

    loadFiles() {
        if (!this._recordId) return;

        this.isLoading = true;
        this.selectedFiles = new Set();

        fetchRelatedFiles({ recordId: this._recordId })
            .then(result => {
                this.files = result?.length > 0 
                    ? result.map(file => ({ 
                        id: file.Id, 
                        title: file.Title,
                        selected: false // ✅ Initialize selected property
                    })) 
                    : [];
            })
            .catch(error => {
                this.showToast('Error', error.body?.message || 'Failed to fetch files', 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleSelectAll(event) {
        const isChecked = event.target.checked;

        this.files = this.files.map(file => ({
            ...file,
            selected: isChecked
        }));

        if (isChecked) {
            this.selectedFiles = new Set(this.files.map(file => file.id));
        } else {
            this.selectedFiles.clear();
        }
    }

    handleFileSelection(event) {
        const fileId = event.target.dataset.id;
        const isChecked = event.target.checked;

        this.files = this.files.map(file => 
            file.id === fileId ? { ...file, selected: isChecked } : file
        );

        if (isChecked) {
            this.selectedFiles.add(fileId);
        } else {
            this.selectedFiles.delete(fileId);
        }
    }

    handleDownloadAll() {
        if (!this.files.length) {
            this.showToast('No Files', 'There are no files available to download.', 'info');
            return;
        }
        this.downloadFiles(this.files.map(file => file.id));
    }

    handleDownloadSelected() {
        if (this.selectedFiles.size === 0) {
            this.showToast('No Selection', 'Please select at least one file to download.', 'info');
            return;
        }
        this.downloadFiles([...this.selectedFiles]);
    }

    downloadFiles(fileIds) {
        const downloadUrl = `/sfc/servlet.shepherd/version/download/${fileIds.join('/')}`;

        // ✅ Open the file download in a new tab
        window.open(downloadUrl, '_blank');

        // ✅ Show success message
        this.showToast('Download Started', 'Your download should begin shortly.', 'success');

        // ✅ Auto-close the modal after a delay
        setTimeout(() => {
            this.closeModal(); // Close the modal after download starts
        }, 3000); // Adjust the delay as needed (3 seconds)
    }


    closeModal() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ 
            title, 
            message, 
            variant,
            mode: variant === 'error' ? 'sticky' : 'dismissible'
        }));
    }
}