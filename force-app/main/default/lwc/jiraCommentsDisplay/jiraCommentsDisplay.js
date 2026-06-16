import { LightningElement, api, track } from 'lwc';
import getJiraComments from '@salesforce/apex/CreateJiraController.getJiraComments';
import getJiraAccessContext from '@salesforce/apex/CreateJiraController.getJiraAccessContext';

export default class JiraComments extends LightningElement {
    _recordId;
    @track comments = [];
    @track error;
    @track accessMessage = '';
    @track canViewComments = false;
    @track hasLinkedJiraDetail = false;
    @track isLoading = false;

    pageSize = 10;
    currentPage = 1;

    @api
    get recordId() {
        return this._recordId;
    }

    set recordId(value) {
        if (this._recordId === value) {
            return;
        }
        this._recordId = value;
        this.loadComments();
    }

    get totalPages() {
        return Math.ceil(this.comments.length / this.pageSize);
    }

    get paginatedComments() {
        const startIndex = (this.currentPage - 1) * this.pageSize;
        return this.comments.slice(startIndex, startIndex + this.pageSize);
    }

    get showPagination() {
        return this.totalPages > 1;
    }

    get isFirstPage() {
        return this.currentPage === 1;
    }

    get isLastPage() {
        return this.currentPage === this.totalPages;
    }

    get hasNoComments() {
        return !this.isLoading && this.comments.length === 0 && this.canViewComments && this.hasLinkedJiraDetail;
    }

    get showAccessMessage() {
        return !this.error && !this.isLoading && !!this.accessMessage;
    }

    get showCommentsTable() {
        return !this.error && !this.showAccessMessage && !this.isLoading;
    }

    async loadComments() {
        if (!this.recordId) {
            return;
        }

        this.isLoading = true;
        this.error = undefined;
        this.comments = [];
        this.accessMessage = '';
        this.currentPage = 1;

        try {
            const accessContext = await getJiraAccessContext({ caseId: this.recordId });
            this.canViewComments = accessContext?.canViewComments === true;
            this.hasLinkedJiraDetail = accessContext?.hasLinkedJiraDetail === true;

            console.log('accessContext'+accessContext);
            console.log('getJiraAccessContext'+getJiraAccessContext);

            if (!this.canViewComments) {
                this.accessMessage =
                    accessContext?.commentsAccessMessage ||
                    'Jira Comments is not accessible for your profile/recordtype.';
                return;
            }

        

            if (!this.hasLinkedJiraDetail) {
                this.accessMessage = 'No Jira comments found';
                return;
            }

            const data = await getJiraComments({ caseId: this.recordId });
            this.comments = (data || []).map(comment => ({
                ...comment,
                commentLink: `/lightning/r/Jira_Case_Comment__c/${comment.id}/view`
            }));
        } catch (error) {
            this.error = error;
            this.comments = [];
            this.accessMessage = '';
            this.canViewComments = false;
            this.hasLinkedJiraDetail = false;
        } finally {
            this.isLoading = false;
        }
    }

    get columns() {
        return [
            {
                label: 'Comment Name',
                fieldName: 'commentLink',
                type: 'url',
                typeAttributes: { label: { fieldName: 'name' }, target: '_blank' }
            },
            {
                label: 'Comment Body',
                fieldName: 'body',
                type: 'richText'
            },
            {
                label: 'Author',
                fieldName: 'author',
                type: 'text'
            },
            {
                label: 'Created Date',
                fieldName: 'formattedDate',
                type: 'text'
            }
        ];
    }

    handlePrevious() {
        if (this.currentPage > 1) {
            this.currentPage--;
        }
    }

    handleNext() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
        }
    }
}