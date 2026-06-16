import {
    COMPLETED,
    ACTIVE,
    SYNCED,
    MVP,
    ENGAGE_VOICE,
    ENGAGE_DIGITAL,
    CONTACT_CENTER,
    PROCESSING,
    READY_TO_FUNNEL,
    TIER_MAP,
    MEETINGS,
    TIER_PROFESSIONAL_SERVICES,
    RC_EVENT,
    INITIAL_NGBS_ACCOUNT_STATUS,
    ACTIVE_NGBS_ACCOUNT_STATUS,
} from "c/snUtils";

export class Service {
    isSubmitReady;
    address;
    isExpanded;
    status;
    tier;
    tierLabel;
    packageId;
    packageVersion;
    currentStep;
    isUILessProcessOrderEnabled;
    oppId;
    quoteId;
    queryData;
    signUpData;
    submitData;
    isLast;
    isPOC;
    order;
    enableValidateButton = true;
    dataRetentionDuration;
    billingPackage;
    masterQuoteId;
    isMPUB;
    isMultiProductTechnicalQuote;

    // Sync
    isExistingBusiness;
    isSyncCompleted;
    isSyncInProcess;
    isSyncReady;
    isShowNext;
    isShowSkip;
    nextButtonLabel;

    // change order
    isSyncedToICB;
    isProvisioningCompleted;

    // Quote type selection
    availableQuoteTypes = [];
    selectedQuoteType;

    // Quote containers - primary storage for quote-specific data
    SalesQuote = null;
    POCQuote = null;

    // Account status property
    ngbsAccountStatus;

    // Helper getter for selected quote container
    get selectedContainer() {
        return this.selectedQuoteType === "Sales"
            ? this.SalesQuote
            : this.selectedQuoteType === "POC"
            ? this.POCQuote
            : null;
    }

    constructor(params) {
        this.isExpanded = Boolean(params.isExpanded);
        this.tierLabel = params.tierLabel;
        this.oppId = params.oppId;
        this.quoteId = params.quoteId;
        this.tier = TIER_MAP.get(params.tierLabel).tier;
        this.order = TIER_MAP.get(params.tierLabel).order;
        this.isExistingBusiness = params.isExistingBusiness;
        this.packageId = params.packageId;
        this.packageVersion = params.packageVersion;
        this.isSyncedToICB = !this.isCC || params.isSyncedToICB;
        this.isProvisioningCompleted = !this.isCC || params.isProvisioningCompleted;
        this.isUILessProcessOrderEnabled = Boolean(params.isUiLess);
        this.isPOC = params.isPOC;
        this.isMPUB = params.isMPUB;
        this.isMultiProductTechnicalQuote = params.isMultiProductTechnicalQuote;
        this.billingPackage = params.billingPackage;
    }

    get isMVP() {
        return this.tier === MVP || this.tier === MEETINGS;
    }

    get isRCEvent() {
        return this.tier === RC_EVENT;
    }

    get isEngage() {
        return [ENGAGE_VOICE, ENGAGE_DIGITAL].includes(this.tier);
    }

    get isCC() {
        return this.tier === CONTACT_CENTER;
    }

    get isMeetings() {
        return this.tier === MEETINGS;
    }

    get isServiceMvpOrMeetings() {
        return this.isMVP || this.isMeetings;
    }

    get isProServ() {
        return this.tier === TIER_PROFESSIONAL_SERVICES;
    }

    get segment() {
        return `sn-segment${this.isLast ? "-last" : ""} slds-m-horizontal_medium`;
    }

    setActive() {
        this.status = this.status !== COMPLETED ? ACTIVE : this.status;
    }

    setLast() {
        this.isLast = true;
    }

    setCompleted() {
        this.status = COMPLETED;
        this.currentStep = SYNCED;
    }

    setProcessing() {
        this.status = this.status !== COMPLETED ? PROCESSING : this.status;
    }

    setAccountStatus(ngbsAccountStatus, quoteType = null) {
        this.ngbsAccountStatus = ngbsAccountStatus;
        if (quoteType === "Sales" && this.SalesQuote) {
            this.SalesQuote.ngbsAccountStatus = ngbsAccountStatus;
            console.log("this.SalesQuote.ngbsAccountStatus--> ", this.SalesQuote.ngbsAccountStatus);
        } else if (quoteType === "POC" && this.POCQuote) {
            this.POCQuote.ngbsAccountStatus = ngbsAccountStatus;
            console.log("this.POCQuote.ngbsAccountStatus--> ", this.POCQuote.ngbsAccountStatus);
        }
    }

    setAddress(address) {
        this.address = address;
        this.enableValidateButton = false;
    }

    setBillingPackage(billingPackageId) {
        this.billingPackage = billingPackageId;
    }

    get isMvpAndUILess() {
        return this.isMVP && this.isUILessProcessOrderEnabled;
    }

    get isNotMvpAndUILess() {
        return !this.isMVP && this.isUILessProcessOrderEnabled;
    }

    get isMvpOrNotUILess() {
        return this.isMVP || !this.isUILessProcessOrderEnabled;
    }

    get isMeetingsAndUILess() {
        return this.isMeetings && this.isUILessProcessOrderEnabled;
    }

    get isNotMeetingsAndUILess() {
        return !this.isMeetings && this.isUILessProcessOrderEnabled;
    }

    get isMeetingsOrNotUILess() {
        return this.isMeetings || !this.isUILessProcessOrderEnabled;
    }

    get isNotUILessEngage() {
        return this.isEngage && !this.isUILessProcessOrderEnabled;
    }

    get isInContactNotReadyForSync() {
        return this.isExistingBusiness && !this.isSyncedToICB && !this.isProvisioningCompleted;
    }

    setCurrentStep(step) {
        this.currentStep = step;
        if (step === READY_TO_FUNNEL && (this.isMvpAndUILess || this.isMeetingsAndUILess || this.isRCEvent)) {
            this.setActive();
        }

        if (step === SYNCED) {
            this.isNotMvpAndUILess || this.isNotMeetingsAndUILess ? this.setActive() : this.setCompleted();
        }
    }

    submitNotReady() {
        this.isSubmitReady = false;
    }

    addQuoteType(quoteType, quoteId, quoteData = {}) {
        if (!this.availableQuoteTypes.includes(quoteType)) {
            this.availableQuoteTypes.push(quoteType);
        }

        const quoteContainer = {
            quoteId: quoteId,

            isExpanded: this.isExpanded,
            tierLabel: this.tierLabel,
            oppId: this.oppId,
            tier: this.tier,
            order: this.order,
            isUILessProcessOrderEnabled: this.isUILessProcessOrderEnabled,
            isMPUB: this.isMPUB,
            isMultiProductTechnicalQuote: this.isMultiProductTechnicalQuote,

            isExistingBusiness:
                quoteData.isExistingBusiness !== undefined ? quoteData.isExistingBusiness : this.isExistingBusiness,
            packageId: quoteData.packageId !== undefined ? quoteData.packageId : this.packageId,
            packageVersion: quoteData.packageVersion !== undefined ? quoteData.packageVersion : this.packageVersion,
            isSyncedToICB: quoteData.isSyncedToICB !== undefined ? quoteData.isSyncedToICB : this.isSyncedToICB,
            isProvisioningCompleted:
                quoteData.isProvisioningCompleted !== undefined
                    ? quoteData.isProvisioningCompleted
                    : this.isProvisioningCompleted,
            isPOC: quoteData.isPOC !== undefined ? quoteData.isPOC : this.isPOC,
            billingPackage: quoteData.billingPackage !== undefined ? quoteData.billingPackage : this.billingPackage,
            masterQuoteId: quoteData.masterQuoteId,

            currentStep: this.currentStep,
            address: this.address,
            isLast: this.isLast,
            enableValidateButton: this.enableValidateButton,
            isSubmitReady: this.isSubmitReady,
            queryData: this.queryData,
            submitData: this.submitData,
            isSyncCompleted: this.isSyncCompleted,
            isSyncInProcess: this.isSyncInProcess,
            isSyncReady: this.isSyncReady,
            isShowNext: this.isShowNext,
            isShowSkip: this.isShowSkip,
            nextButtonLabel: this.nextButtonLabel,
            dataRetentionDuration: this.dataRetentionDuration,

            ngbsAccountStatus: this.ngbsAccountStatus,

            status: this.status
        };

        if (quoteType === "Sales") {
            this.SalesQuote = quoteContainer;
        } else if (quoteType === "POC") {
            this.POCQuote = quoteContainer;
        }

        if (!this.quoteId) {
            this.quoteId = quoteContainer.quoteId;
            this.packageId = quoteContainer.packageId;
            this.packageVersion = quoteContainer.packageVersion;
            this.isPOC = quoteContainer.isPOC;
            this.selectedQuoteType = quoteType;
            this.masterQuoteId = quoteContainer.masterQuoteId;
            this.applyQuoteData(quoteData);
        }
    }

    computeQuoteStatus(quoteData) {
        /*if (quoteData.isExistingBusiness && quoteData.isSyncedToICB && quoteData.isProvisioningCompleted) {
            return COMPLETED;
        }
        if (quoteData.isExistingBusiness) {
            return PROCESSING;
        }*/
        return ACTIVE; 
    }

    // Apply quote-specific data to service properties (without status)
    applyQuoteData(quoteData) {
        if (quoteData.isExistingBusiness !== undefined) this.isExistingBusiness = quoteData.isExistingBusiness;
        if (quoteData.isSyncedToICB !== undefined) this.isSyncedToICB = quoteData.isSyncedToICB;
        if (quoteData.isProvisioningCompleted !== undefined)
            this.isProvisioningCompleted = quoteData.isProvisioningCompleted;
        if (quoteData.masterQuoteId !== undefined) this.masterQuoteId = quoteData.masterQuoteId;
    }

    // Apply status using existing framework methods (for quote switching)
    applyStatusAfterQuoteSwitch(opportunity) {
        if (this.isInContactNotReadyForSync) {
            this.setActive(); 
        } else if (this.isProServ && opportunity?.Account?.Internal_Enterprise_Account_ID__c && !this.billingPackage) {
            this.setProcessing(); 
        }
    }

    get hasMultipleQuoteTypes() {
        return this.filteredQuoteTypes.length > 1;
    }

    get hasSingleQuoteType() {
        return this.filteredQuoteTypes.length === 1;
    }

    get displayPackageName() {
        const tierInfo = TIER_MAP.get(this.tierLabel);
        return tierInfo?.tier || this.tierLabel;
    }

    get singleQuoteTypeMessage() {
        const hasSalesQuoteSignedUp =
            this.SalesQuote &&
            (this.SalesQuote.status === COMPLETED ||
                this.SalesQuote.ngbsAccountStatus === INITIAL_NGBS_ACCOUNT_STATUS ||
                this.SalesQuote.ngbsAccountStatus === ACTIVE_NGBS_ACCOUNT_STATUS);

        const hasPOCQuoteSignedUp =
            this.POCQuote &&
            (this.POCQuote.status === COMPLETED ||
                this.POCQuote.ngbsAccountStatus === INITIAL_NGBS_ACCOUNT_STATUS ||
                this.POCQuote.ngbsAccountStatus === ACTIVE_NGBS_ACCOUNT_STATUS);

        if (hasSalesQuoteSignedUp) {
            return ""; 
        }

        if (this.hasSingleQuoteType) {
            const availableType = this.filteredQuoteTypes[0];

            // Don't show message for Sales-only scenarios (when POC was never available)
            if (availableType === "Sales" && !this.availableQuoteTypes.includes("POC")) {
                return ""; 
            }

            // Show message when POC is the only available quote type (Sales was never available)
            if (availableType === "POC") {
                return `Only ${availableType} Quote is available for ${this.displayPackageName} Package`;
            }
        }
        return "";
    }

    get quoteSelectionOptions() {
        // Use filtered quote types based on business rules
        return this.filteredQuoteTypes.map((type) => ({
            label: type,
            value: type,
            uniqueId: `${this.tierLabel.replace(/[^a-zA-Z0-9]/g, "")}-${type}`, // Sanitized unique ID (only alphanumeric)
            isChecked: this.selectedQuoteType === type,
        }));
    }

    selectQuoteType(quoteType) {
        if (!this.isQuoteTypeAvailable(quoteType)) {
            console.warn(`Cannot select ${quoteType} quote for ${this.tierLabel}`);
            return false;
        }

        if (this.availableQuoteTypes.includes(quoteType)) {
            this.saveCurrentStateToQuote();

            this.selectedQuoteType = quoteType;

            const selectedContainer = this.selectedContainer;

            if (selectedContainer) {
                this.quoteId = selectedContainer.quoteId;
                this.packageId = selectedContainer.packageId;
                this.packageVersion = selectedContainer.packageVersion;
                this.isPOC = selectedContainer.isPOC;
                this.masterQuoteId = selectedContainer.masterQuoteId;
                this.isExistingBusiness = selectedContainer.isExistingBusiness;
                this.isSyncedToICB = selectedContainer.isSyncedToICB;
                this.isProvisioningCompleted = selectedContainer.isProvisioningCompleted;
                this.status = selectedContainer.status /*|| "active"*/; 
                this.currentStep = selectedContainer.currentStep || null; 
                this.billingPackage = selectedContainer.billingPackage;
                this.dataRetentionDuration = selectedContainer.dataRetentionDuration;
                this.address = selectedContainer.address || null; 
                this.isExpanded = selectedContainer.isExpanded;
                this.isLast = selectedContainer.isLast;
                this.order = selectedContainer.order;
                this.enableValidateButton = selectedContainer.enableValidateButton;

                this.ngbsAccountStatus = selectedContainer.ngbsAccountStatus;
                this.isSubmitReady = selectedContainer.isSubmitReady || false; 

                this.queryData = selectedContainer.queryData || null;
                this.signUpData = selectedContainer.signUpData
                    ? JSON.parse(JSON.stringify(selectedContainer.signUpData))
                    : null; 
                this.submitData = selectedContainer.submitData || null;
            }

            this.applyQuoteData(selectedContainer);

            return true;
        }
        return false;
    }

    saveCurrentStateToQuote() {
        const currentData = {
            isExistingBusiness: this.isExistingBusiness,
            isSyncedToICB: this.isSyncedToICB,
            isProvisioningCompleted: this.isProvisioningCompleted,
            status: this.status,
            currentStep: this.currentStep,
            ngbsAccountStatus: this.ngbsAccountStatus,  
            address: this.address, 
            billingPackage: this.billingPackage, 
            isSubmitReady: this.isSubmitReady, 
            isSyncCompleted: this.isSyncCompleted, 
            queryData: this.queryData, 
            signUpData: this.signUpData ? JSON.parse(JSON.stringify(this.signUpData)) : null, 
            submitData: this.submitData, 
        };

        if (this.selectedQuoteType === "Sales" && this.SalesQuote) {
            Object.assign(this.SalesQuote, currentData);
        } else if (this.selectedQuoteType === "POC" && this.POCQuote) {
            Object.assign(this.POCQuote, currentData);
        }
    }


    // Check if a quote type is available based on business rules
    isQuoteTypeAvailable(quoteType) {
        const quote = quoteType === "Sales" ? this.SalesQuote : this.POCQuote;
        if (!quote) return false;

        if (quoteType === "POC" && this.SalesQuote?.isExistingBusiness) {
            return false;
        }

        return true;
    }

    get filteredQuoteTypes() {
        return this.availableQuoteTypes.filter((type) => this.isQuoteTypeAvailable(type));
    }
}