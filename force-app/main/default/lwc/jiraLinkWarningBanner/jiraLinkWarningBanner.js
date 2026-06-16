import { LightningElement, api } from 'lwc';
import getJiraAccessContext from '@salesforce/apex/CreateJiraController.getJiraAccessContext';


const DEFAULT_BODY =
    'Please use the Create/Link Jira button (if available on your page) to manage Jira updates through automation instead of manually editing Jira fields. This ensures better data consistency and process accuracy.';

/**
 * Warning banner on Case record pages for users whose profile + record type
 * are in Jira CMDT scope. Shown whenever in scope, regardless of Jira field values.
 */
export default class JiraLinkWarningBanner extends LightningElement {
    _recordId;

    showBanner = false;
    bannerBody = DEFAULT_BODY;

    @api
    get recordId() {
        return this._recordId;
    }

    set recordId(value) {
        if (this._recordId === value) {
            return;
        }
        this._recordId = value;
        this.loadContext();
    }

    async loadContext() {
        if (!this.recordId) {
            this.showBanner = false;
            return;
        }

        this.showBanner = false;

        try {
            const ctx = await getJiraAccessContext({ caseId: this.recordId });
            const inScope = ctx?.isProfileRecordTypeInScope === true;
            this.showBanner = inScope;

            // Use LWC copy only. Apex getJiraAccessContext().message is often the same as
            // JiraAccessPermissionService.LINK_JIRA_MESSAGE and would override DEFAULT_BODY.
            this.bannerBody = DEFAULT_BODY;
        } catch (e) {
            // eslint-disable-next-line no-console
            console.warn('jiraLinkWarningBanner: unable to load Jira access context', e);
            this.showBanner = false;
            this.bannerBody = DEFAULT_BODY;
        }
    }
}