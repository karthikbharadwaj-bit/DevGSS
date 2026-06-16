import { LightningElement, track, api } from 'lwc';
import { NavigationMixin } from "lightning/navigation";

export default class KycSectionDetail extends NavigationMixin(LightningElement) {
    @api file;
    @api isFormLocked;
    connectedCallback() {}

    get title() {
        return this.file && this.file.name;
    }
    get name() {
        return this.file && window.app.truncName(this.file.name, 20);
    }
    get fileSize() {
        return this.file && window.app.getFileSize(this.file.size);
    }
    get imageSrc() {
        const documentForceUrl = window.location.origin.split('.')[0] + '--c.documentforce.com';
        return this.file && documentForceUrl +
            '/sfc/servlet.shepherd/version/renditionDownload?rendition=THUMB120BY90&versionId=' +
            this.file.latestPublishedVersionId;
    }
    get fileIcon () {
        return !this.file.id && 'doctype:attachment';
    }
    get isHasId() {
        return this.file.id;
    }

    onDownLoadClick() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: window.app.baseUrl + '/sfc/servlet.shepherd/document/download/' + this.file.contentDocumentId,
            },
        });
    }

    onDeleteClick() {
        window.app.deleteFile(this.file.uid);
    }
}