import { LightningElement, track } from 'lwc';
import { clAppReady, showToast, closeToast } from "c/clService";
import getRequestFormLink from '@salesforce/apex/IcbHelper.getRequestFormLink';
import { MIGRATION_IN_PROGRESS, MIGRATION_IN_PROGRESS_TITLE, ACCOUNT_MIGRATION_STATUSES, WRONG_COUNTRY_BRAND } from "c/snUtils";

export default class ClFooter extends LightningElement {
    @track isLeadConverting = false;
    @track lead = null;
    @track isEmptyBI = null;
    @track isLeadLoaded = false;

    opportunityCreationOption;
    opportunityExists;
    accMigrationFlag;
    isOpportunitiesLoading;
    accountUnblockRequestLink;

    get isConvertDisabled() {
        return this.isLeadConverting
            || (this.lead && this.lead.isConverted)
            || this.disableOpptyCreation
            || this.isEmptyBI;
    }

    get disableOpptyCreation() {
        const isCreateOpptyAction = this.opportunityCreationOption === "selectExistingOpp" && !this.opportunityExists
            || this.opportunityCreationOption === "createNewOpp";

        return isCreateOpptyAction && this.isMigrationInProgressBlocked;
    }

    connectedCallback() {
        getRequestFormLink()
            .then(res => {
                if (res.status !== 'success') {
                    return;
                }

                this.accountUnblockRequestLink = res.data.formLink;
            });
        clAppReady(this.onClAppReady.bind(this));
    }

    onClAppReady() {
        CL.app.rx.loadingStatus.subscribe(loadingStatus => {
            this.isLeadConverting = loadingStatus.isLeadConverting;
            this.isOpportunitiesLoading = loadingStatus.isOpportunitiesLoading;
            this.isLeadLoaded = loadingStatus?.isLeadLoaded;
        });
        CL.app.rx.lead.subscribe(lead => {
            this.lead = lead;
        });
        CL.app.rx.targetAccount.subscribe(account => {
            this.accMigrationFlag = account.accMigrationFlag;
            if (this.isMigrationInProgress) {
                return this.composeToast('warning');
            }
        });
        CL.app.rx.matchedOpportunities.subscribe(opportunities => {
            this.opportunityExists = opportunities.length > 0;
            this.manageToast();
        });
        CL.app.rx.opportunityCreationOption.subscribe(option => {
            this.opportunityCreationOption = option;
            this.manageToast();
        });
        CL.app.serviceSelector.rx.filters.subscribe(filters => {
            this.isEmptyBI = !Boolean(filters.businessIdentity.value);
        });
    }

    cancel() {
        const retURL = new URL(window.location).searchParams.get("retURL");
        if (retURL) {
            window.open(retURL, '_parent');
        } else {
            history.back();
        }
    }


    manageToast() {
        if (this.isOpportunitiesLoading) {
            return
        }

        if (this.disableOpptyCreation) {
            return this.composeToast('error')
        }
        closeToast();
    }


    composeToast(type) {
        showToast({
            title: MIGRATION_IN_PROGRESS_TITLE,
            message: MIGRATION_IN_PROGRESS,
            type: type,
            link: {
                label: 'form',
                url: this.accountUnblockRequestLink
            },
            duration: 0
        });
    }

    get tooltipMessage() {
        if (this.isWrongCountryBrand) {
            return WRONG_COUNTRY_BRAND;
        } else if (this.disableOpptyCreation) {
            return MIGRATION_IN_PROGRESS_TITLE + " " + MIGRATION_IN_PROGRESS;
        } else {
            return "";
        }
    }

    get isWrongCountryBrand() {
        return this.isEmptyBI && this.isLeadLoaded && !!this.lead && !this.isLeadConverting && !this.lead?.isConverted;
    }

    get isShowTooltip() {
        return this.isWrongCountryBrand || this.disableOpptyCreation;
    }

    get isMigrationInProgressBlocked() {
        return ACCOUNT_MIGRATION_STATUSES.BLOCKING_ACCOUNT_MIGRATION_STATUSES.includes(this.accMigrationFlag);
    }

    get isMigrationInProgress() {
        return ACCOUNT_MIGRATION_STATUSES.IN_PROGRESS_ACCOUNT_MIGRATION_STATUSES.includes(this.accMigrationFlag);
    }
}