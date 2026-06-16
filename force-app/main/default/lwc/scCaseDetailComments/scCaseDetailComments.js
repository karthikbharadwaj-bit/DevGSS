import { track, api } from "lwc";
import BaseService from "c/lwcBaseService";
import { labels } from "c/scCaseDetailLabels";
import postComment from "@salesforce/apex/SupportCommunityViewCase.postComment";

export default class ScCaseDetailComments extends BaseService {
    labels = labels;
    @api comments = [];
    @api caseId;
    @api isClosed;
    @track loading = false;
    @track newComment = "";
    inputSelector = ".sc-case-comments__input";
    eventsName = {
        sendComment: "sendcomment",
    };
    get loadingCls() {
        return `sc-case-comments__loading${this.loading ? " show" : ""}`;
    }
    submitComment() {
        this.loading = true;
        BaseService.invokeServiceMethod(postComment, { caseId: this.caseId, commentBody: this.newComment })
            .then(result => {
                this.loading = false;
                if (result.commentDetail) {
                    BaseService.pushEvent(this.eventsName.sendComment, result.commentDetail, this);
                    this.template.querySelector(this.inputSelector).value = "";
                } else {
                    throw new Error("Wrong response from server (Send comment)");
                }
            })
            .catch(error => {
                console.error(error);
                this.loading = false;
                BaseService.errorToast(this.labels.errorMessage, error);
            });
    }
    handlePressEnter(evt) {
        if (evt.keyCode === 13) {
            this.newComment = evt.target.value.trim();
            this.submitComment();
        }
    }
    handleNewComment() {
        this.newComment = this.template.querySelector(this.inputSelector).value.trim();
        this.submitComment();
    }
}