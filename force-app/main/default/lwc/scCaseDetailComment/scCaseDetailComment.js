import { track, api } from "lwc";
import BaseService from "c/lwcBaseService";

export default class ScCaseDetailComment extends BaseService {
    @api author;
    @api body;
    @api avatar;
    @api date;
    @api isCaseAuthor;
    @api isCurrentUser;
    labels = {
        author: "Creator",
    };
    get pic() {
        return this.avatar || "/profilephoto/005/T";
    }
    get wrapperCls() {
        return `sc-case-comment__wrapper${this.isCurrentUser ? " sc-case-comment__wrapper_current" : ""}`;
    }
    get bodyCls() {
        return `sc-case-comment__body${this.isCaseAuthor ? " sc-case-comment__body_owner" : ""}`;
    }
}