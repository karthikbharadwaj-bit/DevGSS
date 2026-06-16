import { track, api } from "lwc";
import BaseService from "c/lwcBaseService";
import { labels } from "c/scCaseDetailLabels";
import { File } from "./file";
import deleteAttachment from "@salesforce/apex/SupportCommunityViewCase.deleteAttachment";
import getAttachments from "@salesforce/apex/SupportCommunityViewCase.getAttachments";

export default class ScCaseDetailAttachments extends BaseService {
    @api title = "Attachments";
    @track labels = labels;
    @track files = [];
    @track caseId;
    @track loading = true;
    @track upload = false;
    @track drop = false;
    @track isClosed = false;
    @track attachmentValue;
    @track maxSize = 5;
    @track apexUrl = "../scCaseDetailAttachments";

    eventsName = {
        info: "SCCaseDetailAttachments",
    };

    get link() {
        return this.loading ? "" : `${this.apexUrl}?id=${encodeURIComponent(this.caseId)}`;
    }
    get disabledAdd() {
        return this.loading || this.upload || this.isClosed;
    }
    get uploadCls() {
        return `sc-case-attach__upload${this.upload ? " show" : ""}`;
    }
    get wrapperCls() {
        return `sc-case-attach__wrapper${this.drop ? " drop" : ""}`;
    }
    openAttach() {
        BaseService.showModal(
            "Upload file",
            `<iframe src="${this.link}" width="100%" height="100%"></iframe>`,
            null,
            () => {
                this.updateInfo();
            },
            false
        );
    }
    removeFromList(id) {
        this.files = this.files.filter(item => item.id !== id);
    }
    async removeModal() {
        return await new Promise(resolve => {
            BaseService.showModal(
                this.labels.deleteAttachment,
                this.labels.deleteAttachmentSure,
                [
                    {
                        name: "ok",
                        label: "Ok",
                        variant: "brand",
                        callback: () => {
                            resolve(true);
                        },
                    },
                    {
                        name: "cancel",
                        label: "Cancel",
                        callback: () => {
                            resolve(false);
                        },
                    },
                ],
                () => {
                    resolve(false);
                }
            );
        });
    }
    async removeAttachment(evt) {
        evt.preventDefault();
        evt.stopPropagation();
        const attachmentId = evt.target.value;
        if (await this.removeModal()) {
            this.upload = true;
            BaseService.invokeServiceMethod(deleteAttachment, { caseId: this.caseId, attachmentId })
                .then(() => {
                    this.upload = false;
                    this.removeFromList(attachmentId);
                })
                .catch(error => {
                    this.upload = false;
                    console.error(error);
                    BaseService.errorToast(this.labels.errorMessage, error);
                });
        }
    }
    updateInfo() {
        BaseService.invokeServiceMethod(getAttachments, { caseId: this.caseId})
            .then(result => {
                this.upload = false;
                if(result.attachments) {
                    this.files = result.attachments.map(item => new File(item.id, item.name, item.url, item.fileSize));
                }
                else {
                    throw new Error("Attachments not found!");
                }
            })
            .catch(error => {
                this.upload = false;
                console.error(error);
                BaseService.errorToast(this.labels.errorMessage, error);
            });
    }
    onInfoLoad({ detail }) {
        this.loading = false;
        this.files = detail.attachments.map(item => new File(item.id, item.name, item.url, item.fileSize));
        this.caseId = detail.caseId;
        this.isClosed = detail.isClosed;
    }
    constructor() {
        super();
        window.addEventListener(this.eventsName.info, this.onInfoLoad.bind(this));
    }
}