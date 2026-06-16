import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getKnowledgeArticleContentVersions from '@salesforce/apex/KnowledgeArticleController.getKnowledgeArticleContentVersions';

export default class KnowledgeArticleLinks extends NavigationMixin(LightningElement) {
    @api recordId; // Knowledge Article Id
    contentVersion; // Holds the latest content version
    error;
    isLoading = true; // Spinner control
    noFileAttached = false; // Flag if no attachment is available

    @wire(getKnowledgeArticleContentVersions, { knowledgeArticleId: '$recordId' })
    wiredContentVersion({ data, error }) {
        if (data) {
            if (data.title === '' && data.base64Content === '') {
                // No file attached, so set noFileAttached to true
                this.noFileAttached = true;
            } else {
                this.contentVersion = data;
                this.noFileAttached = false;
            }
            this.error = undefined;
        } else if (error) {
            this.error = error.body.message;
            this.contentVersion = undefined;
            this.noFileAttached = true;
        }
        this.isLoading = false; // Stop spinner
    }

    renderedCallback() {
        if (this.contentVersion && this.contentVersion.base64Content) {
            const fileExtension = this.contentVersion.fileExtension?.toLowerCase();
            
            if (fileExtension === 'pdf') {
                this.handlePdfPreview();
            } else if (fileExtension === 'html' || fileExtension === 'htm') {
                this.handleHtmlPreview();
            } else {
                this.handleOtherFileTypes();
            }
        }
    }

    handlePdfPreview() {
        // Use Salesforce native PDF viewer
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview'
            },
            state: {
                selectedRecordId: this.contentVersion.contentDocumentId
            }
        });
    }

    handleHtmlPreview() {
        try {
            const decoder = new TextDecoder("utf-8");
            const binaryString = atob(this.contentVersion.base64Content); // Decode Base64
            const utf8Content = decoder.decode(new Uint8Array(binaryString.split('').map(char => char.charCodeAt(0))));
            const htmlPreviewElement = this.template.querySelector('.html-preview');
            if (htmlPreviewElement) {
                htmlPreviewElement.innerHTML = utf8Content; // Insert UTF-8 decoded content
            }
        } catch (error) {
            console.error('Error rendering HTML content:', error);
            const htmlPreviewElement = this.template.querySelector('.html-preview');
            if (htmlPreviewElement) {
                htmlPreviewElement.innerHTML = '<p>Error rendering HTML content. Please try downloading the file.</p>';
            }
        }
    }

    handleOtherFileTypes() {
        // Show download link or preview button for other file types
        const previewElement = this.template.querySelector('.file-preview');
        if (previewElement) {
            previewElement.innerHTML = `
                <div class="slds-box slds-theme_shade">
                    <p><strong>File:</strong> ${this.contentVersion.title}</p>
                    <p><strong>Type:</strong> ${this.contentVersion.fileType}</p>
                    <lightning-button 
                        label="Preview File" 
                        onclick={this.handleFilePreview.bind(this)}
                        variant="brand">
                    </lightning-button>
                </div>
            `;
        }
    }

    handleFilePreview() {
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview'
            },
            state: {
                selectedRecordId: this.contentVersion.contentDocumentId
            }
        });
    }

    // Getters for template conditional rendering
    get isPdfFile() {
        return this.contentVersion?.fileExtension?.toLowerCase() === 'pdf';
    }

    get isHtmlFile() {
        const ext = this.contentVersion?.fileExtension?.toLowerCase();
        return ext === 'html' || ext === 'htm';
    }

    get isOtherFileType() {
        const ext = this.contentVersion?.fileExtension?.toLowerCase();
        return ext && ext !== 'pdf' && ext !== 'html' && ext !== 'htm';
    }
}