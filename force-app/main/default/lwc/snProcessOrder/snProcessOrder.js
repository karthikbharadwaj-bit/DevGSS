import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import { Service } from './Service';
import handleSignUp from '@salesforce/apex/ProcessOrder.handleSignUp';
import getOppBillingDetail from '@salesforce/apex/ProcessOrder.getOppBillingDetail';
import createOrders from '@salesforce/apex/ProcessOrder.createOrders';
import { CloseActionScreenEvent } from 'lightning/actions';
import modal from '@salesforce/resourceUrl/signupmodalcss';
import handleSubmit from '@salesforce/apex/ProcessOrder.handleSubmit';
import updateSyncInfoAfterSyncICB from '@salesforce/apex/ProcessOrder.updateSyncInfoAfterSyncICB';
import customRulesValidation from '@salesforce/apex/SyncWithNGBS.customRulesValidation';
import updateServiceInfoAfterSignUp from '@salesforce/apex/QuoteHelper.updateServiceInfoAfterSignUp';
import checkIsMainCostCenterExist from '@salesforce/apex/ProcessOrder.checkIsMainCostCenterExist';
import createMainCostCenter from '@salesforce/apex/ProcessOrder.createMainCostCenter';
import {
    COMPLETED,
    ACTIVE,
    PROCESSING,
    ORDERS_CREATION,
    QUERYING_DATA,
    VALIDATION,
    PREPARING_CASES,
    PREPARING,
    FUNNEL_REQUEST,
    SYNCED,
    READY_TO_FUNNEL,
    SIGN_UP_IN_PROCESS,
    SIGNED_UP,
    OFFICE,
    RING_CENTRAL_CONTACT_CENTER,
    ERROR,
    INFO,
    INITIAL_NGBS_ACCOUNT_STATUS,
    ACTIVE_NGBS_ACCOUNT_STATUS,
    ACCOUNT_INACTIVE_STATUSES,
    POC,
    ENGAGE_VOICE,
    ENGAGE_DIGITAL_STANDALONE,
    CONTACT_ORDER_MANAGEMENT,
    MEETINGS,
    ADMIN_PREVIEW,
    COPY_JSON,
    PROSERV,
    CC_PROSERV,
    CC_SYNC_STATUS_STARTED,
    DEFAULT_SYNC_ERROR,
    READY_TO_CREATE_MAIN_COST_CENTER,
    COST_CENTER_CREATED,
    PROSERV_SIGNUP_REQUEST_SEND,
    TIER_RC_EVENT,
    RC_EVENT,
    TIER_MAP,
    TIER_PROFESSIONAL_SERVICES,
    REQUIRES_MVP_SERVICE_COMPLETED,
    REQUIRES_PAID_OFFICE_COMPLETION,
    REQUIRES_POC_OFFICE_COMPLETION,
    SIGNUP_BLOCKED_MESSAGE,
    POC_DEALS_RESTRICTED_FOR_STANDALONE,
 } from "c/snUtils";
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import hasAdminPreviewPermission from '@salesforce/customPermission/UILessSignUpPreviewForAdmins';
import CASE_OBJECT from '@salesforce/schema/Case';

const CASE_CREATE_ERROR = 'An error occurred while ICB case creation. Try again.';
const DOS_RECORD_TYPE_NAME = 'Deal and Order Support';
const IN_PROCESS = 'IN_PROCESS';
const STYLESHEET_ID = 'processOrderModalWindowId';


export default class SnProcessOrder extends NavigationMixin(LightningElement) {
    @api opportunityId;
    @api recordId;
    targetId;
    hasRendered;
    opportunity;
    ngbsAccountStatus;
    ngbsPackageInfoMap = {};
    productNameToPackageIsActiveStatusMap;
    sldsModalEl;

    boundHandleAddMessage;
    boundValidateAddress;
    boundHandleAddressChanged;

    isCompleted;

    servicesMap = new Map();
    @track services = [];
    currentTier;

    @track isReadyForValidation = false;

    @track messages = [];
    targetIds;

    isMultiProductFTEnabled = true;
    rcccParameters;

    openSelectAddressWindow;
    openInvalidAddressWindow;
    suggestedBillingAddresses;

    engageError;
    isResponseHasError = false;
    techMasterQuote;

    spinnerText;
    isProcess = false;
    isReadyForGetOrderToVendorCatalog;
    isSimplifiedLboDownsellEnabled = false;

    initialLoading = true;
    caseNumber;
    isMPUB = false;

    selectedSignUpTab;
    signupBody;

    @track userHasClickedTierArrow = false;

    @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
    objectInfo;

    get dOSRecordTypeId() {
        const recordTypeInfos = this.objectInfo.data.recordTypeInfos;
        return Object.keys(recordTypeInfos).find(
            (recordType) => recordTypeInfos[recordType].name === DOS_RECORD_TYPE_NAME
        );
    }

    get isSeveralServices() {
        const hasEventsOrEngageDigitalSalesQuote =
            this.servicesMap.get(TIER_RC_EVENT)?.SalesQuote || this.servicesMap.get(ENGAGE_DIGITAL_STANDALONE)?.SalesQuote;
        const hasOfficeSalesQuote = this.servicesMap.get(OFFICE)?.SalesQuote;
        const byPassCondition = hasEventsOrEngageDigitalSalesQuote && !hasOfficeSalesQuote;

        const isCurrentServiceEventsOrEngageDigitalStandalone =
            this.currentTier === TIER_RC_EVENT || this.currentTier === ENGAGE_DIGITAL_STANDALONE;

        if (isCurrentServiceEventsOrEngageDigitalStandalone && byPassCondition) {
            return false;
        }

        if (byPassCondition) {
            const adjustedSize = this.servicesMap.size - 1;
            return adjustedSize > 1;
        }
        return this.servicesMap.size > 1;
    }

    get disableWhenOfficeNotCompleted() {
        const officeService = this.servicesMap?.get(OFFICE);
        if (!officeService || this.currentTier === OFFICE || !this.isSeveralServices) {
            return false;
        }

        const isOfficePOCCompleted =
            officeService?.POCQuote?.status === COMPLETED ||
            officeService?.POCQuote?.ngbsAccountStatus === ACTIVE_NGBS_ACCOUNT_STATUS;
        const isOfficeSalesCompleted =
            officeService?.SalesQuote?.status === COMPLETED ||
            officeService?.SalesQuote?.ngbsAccountStatus === ACTIVE_NGBS_ACCOUNT_STATUS;

        if (isOfficePOCCompleted && !isOfficeSalesCompleted && this.currentService.selectedQuoteType === "Sales") {
            return true;
        }

        if (!isOfficePOCCompleted && !isOfficeSalesCompleted) {
            return true;
        }

        return false;
    }

    get isQuoteTypeDisabledForService() {
        return this.isSeveralServices && !this.isNGBSAccountActive;
    }

    get office() {
        return this.servicesMap.get(OFFICE);
    }

    get meetings() {
        return this.servicesMap.get(MEETINGS);
    }

    get contactCenter() {
        return this.servicesMap.get(RING_CENTRAL_CONTACT_CENTER);
    }

    get RCEvents() {
        return this.servicesMap.get(TIER_RC_EVENT);
    }

    get childServicesNames() {
        return [...this.servicesMap.keys()].filter(service => service !== OFFICE)?.join(',  ');
    }

    get opportunityRecordId() {
        return this.recordId || this.opportunityId;
    }

    get isShowAddressValidation() {
        // Address validation is hidden for EV/ED, CC MPUB flow, but it remains for ED Standalone (Single Product) and MPLite
        return !this.isMPUB || (!this.isSeveralServices && !this.sfAccountStatus);
    }

    get skipAddressValidation() {
        return (
            this.currentService.isExistingBusiness ||
            this.currentService.isSubmitReady ||
            (!this.isShowAddressValidation && this.currentService.submitData.isSecondStepCompleted)
        );
    }

    clickTierOption(event) {
        this.clearNotifications();
        this.isResponseHasError = false;

        const clickedTier = event.currentTarget.dataset.id;
        const clickedService = this.servicesMap.get(clickedTier);

        const isTierChanged = clickedTier !== this.currentTier;
        if (isTierChanged) {
            this.isReadyForValidation = false;
        }

        this.currentTier = clickedTier;
        this.userHasClickedTierArrow = true;

        const wasExpanded = clickedService?.isExpanded;
        clickedService.isExpanded = !wasExpanded;

        if (!wasExpanded) {
            this.collapseAllServices();
            clickedService.isExpanded = true;
        }

        this.updateLayout();
    }

    collapseAllServices() {
        this.servicesMap.forEach((service) => {
            if (service !== this.currentService) {
                service.isExpanded = false;
            }
        });
    }

    handleQuoteTypeChange(event) {
        this.clearNotifications();
        this.isResponseHasError = false;
        const { tier, selectedQuoteType } = event.detail;
        const service = Array.from(this.servicesMap.values()).find((s) => s.tier === tier);

        if (service) {
            service.saveCurrentStateToQuote();

            service.selectQuoteType(selectedQuoteType);

            const selectedContainer = service.selectedContainer;
            if (selectedContainer && selectedContainer.status) {
                service.status = selectedContainer.status;
            }

            this.updateServiceAccountStatus(service);

            service.applyStatusAfterQuoteSwitch(this.opportunity);

            if (service.tierLabel !== this.currentTier) {
                this.currentTier = service.tierLabel;

                this.servicesMap.forEach((svc, key) => {
                    svc.isExpanded = key === this.currentTier;
                });

                this.userHasClickedTierArrow = true;
            } else {
                service.isExpanded = true;
            }

            if (this.isReadyForValidation) {
                this.clearServiceTimezone();
            }

            this.isReadyForValidation = false;
            this.updateLayout();
        }

        this.updateNgbsAccountStatusFromQuoteType();
    }

    isQuoteCompleted(quote) {
        return quote?.status === COMPLETED || quote?.ngbsAccountStatus === ACTIVE_NGBS_ACCOUNT_STATUS;
    }

    validateSalesServicePrerequisite(currentService, officeService, isOfficeSalesCompleted, isStandaloneService) {
        const isCurrentServicePOC = currentService.selectedQuoteType === POC || currentService.isPOC;
        
        if (isCurrentServicePOC || isOfficeSalesCompleted) {
            return true;
        }

        const canBypassForStandalone = isStandaloneService && !officeService.SalesQuote;
        
        if (!canBypassForStandalone) {
            const serviceDisplayName = currentService.displayPackageName;
            const errorMessage = currentService.isExistingBusiness
                ? REQUIRES_MVP_SERVICE_COMPLETED(serviceDisplayName)
                : REQUIRES_PAID_OFFICE_COMPLETION(serviceDisplayName);
            this.addMessage(
                ERROR,
                SIGNUP_BLOCKED_MESSAGE(currentService.isExistingBusiness, errorMessage)
            );
            return false;
        }

        return true;
    }

    validatePOCServicePrerequisite(currentService, isOfficePOCCompleted, isOfficeSalesCompleted) {
        const isCurrentServicePOC = currentService.selectedQuoteType === POC || currentService.isPOC;
        
        if (!isCurrentServicePOC) {
            return true;
        }

        if (isOfficePOCCompleted || isOfficeSalesCompleted) {
            return true;
        }

        const serviceDisplayName = currentService.displayPackageName;
        const errorMessage = currentService.isExistingBusiness
            ? REQUIRES_MVP_SERVICE_COMPLETED(serviceDisplayName)
            : REQUIRES_POC_OFFICE_COMPLETION(serviceDisplayName);
        this.addMessage(
            ERROR,
            SIGNUP_BLOCKED_MESSAGE(currentService.isExistingBusiness, errorMessage)
        );
        return false;
    }

    validateServicesPrerequisite() {
        const currentService = this.servicesMap.get(this.currentTier);
        if (!currentService || this.currentTier === OFFICE) return true;

        const officeService = this.servicesMap.get(OFFICE);
        if (!officeService) return true;

        const isOfficePOCCompleted = this.isQuoteCompleted(officeService.POCQuote);
        const isOfficeSalesCompleted = this.isQuoteCompleted(officeService.SalesQuote);
        const isStandaloneService = this.currentTier === TIER_RC_EVENT || this.currentTier === ENGAGE_DIGITAL_STANDALONE;

        if (!this.validateSalesServicePrerequisite(currentService, officeService, isOfficeSalesCompleted, isStandaloneService)) {
            return false;
        }

        if (!this.validatePOCServicePrerequisite(currentService, isOfficePOCCompleted, isOfficeSalesCompleted)) {
            return false;
        }

        return true;
    }

    validateStandaloneSalesToPOC() {
        const currentService = this.servicesMap.get(this.currentTier);
        if (!currentService) return true;

        const isCurrentServicePOC = currentService.selectedQuoteType === POC || currentService.isPOC;
        if (!isCurrentServicePOC) return true;

        const isStandaloneServiceType = (tierLabel) => 
            tierLabel === TIER_RC_EVENT || tierLabel === ENGAGE_DIGITAL_STANDALONE;
        
        const servicesWithSalesQuote = [];
        let hasOtherServiceSalesQuote = false;

        for (const service of this.servicesMap.values()) {
            if (!service.SalesQuote) continue;
            
            if (isStandaloneServiceType(service.tierLabel)) {
                servicesWithSalesQuote.push(service);
            } else {
                hasOtherServiceSalesQuote = true;
                break;
            }
        }
        
        if (servicesWithSalesQuote.length === 1 && !hasOtherServiceSalesQuote) {
            const standaloneService = servicesWithSalesQuote[0];
            if (this.isQuoteCompleted(standaloneService.SalesQuote) || standaloneService.status === COMPLETED) {
                const serviceDisplayName = standaloneService.displayPackageName || standaloneService.tierLabel;
                const errorMessage = POC_DEALS_RESTRICTED_FOR_STANDALONE(serviceDisplayName);
                this.addMessage(ERROR, errorMessage);
                return false;
            }
        }

        return true;
    }

    handleContinueClick() {
        this.targetIds = new Set();

        Array.from(this.servicesMap.values()).forEach((service) => {
            if (service.availableQuoteTypes.length === 1 && !service.selectedQuoteType) {
                service.selectQuoteType(service.availableQuoteTypes[0]);
            }
        });

        if (!this.validateServicesPrerequisite()) return;
        if (!this.validateStandaloneSalesToPOC()) return;

        const currentService = this.servicesMap.get(this.currentTier);
        if (currentService) {
            const isOfficeTier = this.currentTier === OFFICE;
            const shouldAddToTargetIds =
                (currentService.isInContactNotReadyForSync ||
                    !currentService.status ||
                    currentService.status === ACTIVE) &&
                (isOfficeTier ? !this.isNGBSAccountActive && !this.isNGBSAccountInitial : true) &&
                currentService.status !== COMPLETED;

            if (
                currentService.masterQuoteId &&
                !this.targetIds.has(currentService.masterQuoteId) &&
                shouldAddToTargetIds
            ) {
                this.targetIds.add(currentService.masterQuoteId);
            }

            if (currentService.quoteId && !this.targetIds.has(currentService.quoteId) && shouldAddToTargetIds) {
                this.targetIds.add(currentService.quoteId);
            }

            this.populateMasterAndProservQuotes(this.techMasterQuote);
        }

        if ((this.isNGBSAccountActive && this.isServiceMvpOrMeetings) || this.currentService.status === COMPLETED) {
            this.currentService.setCompleted();
        }

        if (currentService) {
            currentService.isExpanded = false;
        }

        this.isReadyForValidation = true;

        this.updateServiceExpandability();

        if (this.targetIds.size === 0) {
            return;
        }

        if (this.shouldContinueBackgroundProcess) {
            this.isProcess = true;
            this.createOrderRecords(this.targetIds)
                .then(() => this.startSignUpProcess())
                .catch((res) => this.handleError(res));
        }
    }

    get currentService() {
        return this.servicesMap.get(this.currentTier);
    }

    get ngbsPackageInfo() {
        return this.ngbsPackageInfoMap[this.currentService?.quoteId];
    }

    get isRCCC() {
        return this.currentTier === RING_CENTRAL_CONTACT_CENTER;
    }

    renderedCallback() {
        if (!this.hasRendered && this.opportunityRecordId) {
            this.hasRendered = true;
            this.targetId = this.opportunityRecordId;
            this.initComponent();
            this.sldsModalEl = this.template.querySelector('[data-id="modal-window"]');
        }
    }

    connectedCallback() {
        const head = document.head || document.getElementsByTagName('head')[0];
        const style = document.createElement('link');
        style.href = modal;
        style.rel = 'stylesheet';
        style.id = STYLESHEET_ID;
        head.appendChild(style);

        this.boundHandleAddMessage = this.handleAddMessage.bind(this);
        this.boundValidateAddress = this.validateAddress.bind(this);
        this.boundHandleAddressChanged = this.handleAddressChanged.bind(this);

        this.handleEventListener('addEventListener');
    }

    disconnectedCallback() {
        const style = document.querySelector(`#${STYLESHEET_ID}`);
        style?.remove();

        this.handleEventListener('removeEventListener');
    }

    handleEventListener(action) {
        const eventListeners = [
            {name: "AddNotificationBarMessage", handler: this.boundHandleAddMessage},
            {name: "ValidateAddressProcessOrder", handler: this.boundValidateAddress},
            {name: "AddressChanged", handler: this.boundHandleAddressChanged}
        ];

        eventListeners.forEach(({ name, handler }) => {
            window[action](name, handler);
        });
    }

    handleAddressChanged() {
        this.currentService?.submitNotReady();
        this.updateLayout();
    }

    prepareEngageSubmitData() {
        const signUpData = this.currentService.signUpData;
        const rcAccountId = this.opportunity.Account.RC_User_ID__c;

        this.currentService.submitData = {
            ...this.currentService.submitData,
            rcAccountId: rcAccountId,
            contractStartDate: signUpData.targetQuote.Start_Date__c
        };
        if (this.isShowAddressValidation) {
            this.currentService.submitData = {
                ...this.currentService.submitData,
                billingAddress: {
                    ...this.currentService.address,
                    firstName: signUpData.contact.FirstName,
                    lastName: signUpData.contact.LastName,
                    phoneNumber: signUpData.contact.Phone
                }
            };
        }
    }

    prepareContactCenterSubmitData() {
        if (this.isShowAddressValidation) {
            this.currentService.submitData = {
                ...this.currentService.submitData,
                billingAddress: this.currentService.address,
            };
        }
    }

    initComponent() {
        getOppBillingDetail({
            "OppId": this.targetId
        })
            .then(params => this.handleInitResponse(params))
            .then(() => this.shouldValidateCustomRules && this.runCustomRulesValidation())
            .then(() => this.completeProcessOrderUISettings())
            .then(() => this.setBannerForNewBusiness())
            .catch((res) => this.handleError(res));
    }

    setBannerForNewBusiness() {
        if (!this.currentService?.isExistingBusiness && this.childServicesNames && this.isOnlyOfficeCompleted()) {
            this.addMessage(INFO, CONTACT_ORDER_MANAGEMENT(this.childServicesNames));
        }
    }

    isOnlyOfficeCompleted() {
        return (
            this.office?.status === COMPLETED &&
            !this.services.some((service) => service.tierLabel !== OFFICE && service.status === COMPLETED)
        );
    }

    handleInitResponse(params) {
        if (params.message) {
            return Promise.reject(params.message);
        }
        this.isMultiProductFTEnabled = params.isMultiProductFTEnabled;
        this.isSimplifiedLboDownsellEnabled = params.isSimplifiedLboDownsellEnabled;

        this.opportunity = params.opportunity;
        this.isMPUB = params.isMPUB;

        this.productNameToPackageIsActiveStatusMap = params.productNameToPackageIsActiveStatusMap;

        if (params.opportunity.Parent_Order__c != null) {
            return Promise.reject("This is a Change Order Opportunity. Sync with NGBS is not required");
        }

        if (!params.isMultiProductFTEnabled) {
            return Promise.reject();
        }

        this.targetIds = this.parseServices(params);

        this.initializeServicesCollapsed();

        //this.populateMasterAndProservQuotes(params);
        this.techMasterQuote = params.masterAndTechQuotes;

        if (this.servicesMap.size === 0) {
            if (!this.opportunity.isTermination__c) {
                return Promise.reject('At least one quote on the opportunity is required to sign up a customer');
            }
            this.setTermination();
        }
        this.setCurrentService();
        this.updateNgbsAccountStatusFromQuoteType();

        this.servicesMap.values().forEach((service) => {
            if (service.tierLabel !== "Office") {
                if (service.tier === ENGAGE_VOICE) {
                    const officeService = this.servicesMap.get(OFFICE);
                    const isOfficeCompleted =
                        officeService?.POCQuote?.status === COMPLETED ||
                        officeService?.SalesQuote?.status === COMPLETED ||
                        officeService?.ngbsAccountStatus === ACTIVE_NGBS_ACCOUNT_STATUS;
                    service.isQuoteTypeDisabledForService = !isOfficeCompleted;
                } else {
                    service.isQuoteTypeDisabledForService = this.isQuoteTypeDisabledForService;
                }
            } else {
                service.isQuoteTypeDisabledForService = false;
            }
        });

        this.updateLayout();
        return Promise.resolve();
    }

    createOrderRecords(targetIds) {
        this.spinnerText = ORDERS_CREATION;
        return createOrders({
            OppId: this.targetId,
            targetIds: Array.from(targetIds),
        });
    }

    populateMasterAndProservQuotes(params) {
            params.filter((q) => this.isProServOrCCProServ(q))
            .forEach((q) => this.targetIds.add(q.Id));
    }

    parseServices(params) {
        if (!params?.masterAndTechQuotes?.length) {
            return new Set();
        }

        const syncInfoMap = params.qtIdToSyncInfoMap || {};
        const productStatusMap = params.productNameToPackageIsActiveStatusMap || {};
        const uiLessMap = params.uiLessMap || {};

        const validQuotes = params.masterAndTechQuotes.filter((qt) => !this.isProServOrCCProServ(qt));

        const quotesByTier = new Map();

        for (const qt of validQuotes) {
            let pkgInfos;
            try {
                pkgInfos = JSON.parse(qt.Package_Info__c);
            } catch (e) {
                console.warn("Invalid Package_Info__c JSON for quote:", qt.Id);
                continue;
            }

            if (pkgInfos.length !== 1 || qt.IsDeselected__c) {
                continue;
            }

            const pInfo = pkgInfos[0];
            const tierLabel = pInfo.productName;
            const isPOC = pInfo.offerType === "POC" || this.isPOCQuote(qt);

            if (!quotesByTier.has(tierLabel)) {
                quotesByTier.set(tierLabel, {
                    salesQuotes: [],
                    pocQuotes: [],
                    order: this.getServiceOrder(tierLabel),
                });
            }

            const quoteData = { quote: qt, pkgInfo: pInfo };
            if (isPOC) {
                quotesByTier.get(tierLabel).pocQuotes.push(quoteData);
            } else {
                quotesByTier.get(tierLabel).salesQuotes.push(quoteData);
            }
        }

        const servicesArray = [];

        for (const [tierLabel, quotes] of quotesByTier) {
            const { salesQuotes, pocQuotes, order } = quotes;
            const hasSalesQuote = salesQuotes.length > 0;
            const hasPocQuote = pocQuotes.length > 0;

            const primaryQuoteData = hasSalesQuote ? salesQuotes[0] : pocQuotes[0];
            if (!primaryQuoteData) continue;

            const service = this.createService(
                primaryQuoteData.quote,
                primaryQuoteData.pkgInfo,
                params,
                syncInfoMap,
                uiLessMap
            );

            service.order = order;

            if (hasSalesQuote) {
                const { quote: salesQuote, pkgInfo: salesPkgInfo } = salesQuotes[0];
                const salesSyncInfo = syncInfoMap[salesQuote.Id] || {};

                const salesQuoteData = this.createQuoteData(salesQuote, salesPkgInfo, service, salesSyncInfo, false);

                service.addQuoteType("Sales", salesQuote.Id, salesQuoteData);
            }

            if (hasPocQuote) {
                const { quote: pocQuote, pkgInfo: pocPkgInfo } = pocQuotes[0];
                const pocSyncInfo = syncInfoMap[pocQuote.Id] || {};

                const pocQuoteData = this.createQuoteData(pocQuote, pocPkgInfo, service, pocSyncInfo, true);

                service.addQuoteType("POC", pocQuote.Id, pocQuoteData);
            }

            this.updateServiceAccountStatus(service, params);
            service.selectQuoteType(hasSalesQuote ? "Sales" : "POC");

            const signedUpInfo = productStatusMap[tierLabel];
            this.updateQuoteContainerStatus(service, signedUpInfo);
            this.updateParentServiceStatus(service, signedUpInfo);

            servicesArray.push({ service, order });
        }

        servicesArray.sort((a, b) => a.order - b.order);
        this.servicesMap = new Map(servicesArray.map(({ service }) => [service.tierLabel, service]));

        console.log("servicesMap--> ", this.servicesMap);
        return new Set();
    }

    createQuoteData(quote, pkgInfo, service, syncInfo, isPOC) {
        return {
            isExistingBusiness: !!quote.PackageNameOld__c,
            isSyncedToICB: !service.isCC || syncInfo.isSyncedToICB,
            isProvisioningCompleted: !service.isCC || syncInfo.isICBProvisioningComplete,
            packageId: pkgInfo.id,
            packageVersion: pkgInfo.version,
            isPOC: isPOC,
            tier: service.tier,
            tierLabel: service.tierLabel,
            masterQuoteId: quote?.MasterQuote__c,
        };
    }

    createService(quote, pkgInfo, params, syncInfoMap, uiLessMap) {
        const syncInfo = syncInfoMap[quote.Id] || {};
        return new Service({
            tierLabel: pkgInfo.productName,
            oppId: quote.OpportunityId,
            quoteId: quote.Id,
            isExistingBusiness: !!quote.BillingPackage__c,
            existingBusinessSyncClicked: false,
            packageId: pkgInfo.id,
            packageVersion: pkgInfo.version,
            isSyncedToICB: syncInfo.isSyncedToICB,
            isProvisioningCompleted: syncInfo.isICBProvisioningComplete,
            isUiLess: uiLessMap[pkgInfo.productName],
            isPOC: pkgInfo.offerType === 'POC',
            isMultiProductTechnicalQuote: quote.IsMultiProductTechnicalQuote__c,
            billingPackage: quote.BillingPackage__c,
        });
    }

    getServiceOrder(tierLabel) {
        const tierInfo = TIER_MAP.get(tierLabel);
        return tierInfo ? tierInfo.order : 999; // Default to end if not found
    }

    isMasterQuote(quote) {
        return quote.isPrimary__c && !quote.IsMultiProductTechnicalQuote__c && !quote.IsDeselected__c;
        //&& !this.isPOCQuote(quote);
    }

    isProServOrCCProServ(quote) {
        return quote.RecordType.Name === PROSERV || quote.RecordType.Name === CC_PROSERV;
    }

    isPOCQuote(quote) {
        return quote.RecordType.Name === POC;
    }

    isSelectedQuoteTypeSignedUp(service, signedUpInfo) {
        if (typeof signedUpInfo === "boolean") {
            return signedUpInfo;
        }

        if (signedUpInfo && typeof signedUpInfo === "object") {
            const selectedQuoteType = service.selectedQuoteType;

            if (selectedQuoteType === "Sales" && signedUpInfo.salesSignedUp) {
                return true;
            } else if (selectedQuoteType === "POC" && signedUpInfo.pocSignedUp) {
                return true;
            }

            return false;
        }

        return false;
    }

    updateQuoteContainerStatus(service, signedUpInfo) {
        if (typeof signedUpInfo === "boolean") {
            if (service.SalesQuote && signedUpInfo) {
                this.setQuoteContainerStatus(service.SalesQuote, service);
            }
            return;
        }

        if (signedUpInfo && typeof signedUpInfo === "object") {
            if (service.SalesQuote){
                service.SalesQuote.status = service.SalesQuote.ngbsAccountStatus === INITIAL_NGBS_ACCOUNT_STATUS ? ACTIVE : service.SalesQuote.status;
                service.status = service.SalesQuote.status === ACTIVE ? ACTIVE : service.status;
                if (signedUpInfo.salesSignedUp) {
                    this.setQuoteContainerStatus(service.SalesQuote, service);
                }
            }
            if (service.POCQuote){
                service.POCQuote.status = service.POCQuote.ngbsAccountStatus === INITIAL_NGBS_ACCOUNT_STATUS ? ACTIVE : service.POCQuote.status;
                service.status = service.POCQuote.status === ACTIVE ? ACTIVE : service.status;
                if (signedUpInfo.pocSignedUp) {
                    this.setQuoteContainerStatus(service.POCQuote, service);
            }
          }
       }
    }

    setQuoteContainerStatus(quoteContainer, service) {
        if (!quoteContainer) return;

        const isExistingBusiness = quoteContainer.isExistingBusiness;
        if (!isExistingBusiness) {
            quoteContainer.status = COMPLETED;
        } else if (
            service.isProServ &&
            this.opportunity.Account.Internal_Enterprise_Account_ID__c &&
            !service.billingPackage
        ) {
            quoteContainer.status = PROCESSING;
        }
    }

    updateParentServiceStatus(service, signedUpInfo) {
        const selectedContainer = service.selectedContainer;

        if (!selectedContainer) return;

        const isSelectedQuoteTypeSignedUp = this.isSelectedQuoteTypeSignedUp(service, signedUpInfo);

        if (service.isInContactNotReadyForSync || !isSelectedQuoteTypeSignedUp) {
            return;
        }

        if (selectedContainer.status === COMPLETED) {
            service.setCompleted();
        } else if (selectedContainer.status === PROCESSING) {
            service.setProcessing();
        }
    }

    startSignUpProcess() {
        this.isProcess = true;

        this.showStepsStarted();
        handleSignUp({
            params: JSON.stringify({
                action: 'QUERY_DATA',
                targetIds: Array.from(this.targetIds)
            })
        })
            .then(res => this.handleResponse(res, this.handleQueryData.bind(this)))
            .then(() => this.validateData())
            .then(res => this.handleResponse(res, this.handleValidation.bind(this)))
            .then(() => this.createDealDeskCaseDescriptions())
            .then(res => this.handleResponse(res, this.handleDealDeskCaseDescriptions.bind(this)))
            .then(() => this.preSignUpAction())
            .then(res => this.handleResponse(res, this.handlePreparing.bind(this)))
            .then(() => this.finishPreSignUpActions())
            .catch(res => this.handleError(res));
    }

    validateData() {
        return handleSignUp({
            params: JSON.stringify({
                action: 'VALIDATE_DATA',
                dataArr: [this.currentService.queryData]
            })
        });
    }

    createDealDeskCaseDescriptions() {
        return handleSignUp({
            params: JSON.stringify({
                action: 'CREATE_DEAL_DESK_CASE_DESCRIPTION',
                dataArr: [this.currentService.queryData]
            })
        });
    }

    finishPreSignUpActions() {
        if (
            this.isSeveralServices ||
            this.currentService.isMvpAndUILess ||
            this.currentService.isMeetingsAndUILess ||
            (this.isRCEvent && !this.isSeveralServices)
        ) {
            return this.stopSignUpProcess();
        }
        if (!this.isServiceSigned) {
            return this.startValidateProcessOrder();
        }
        this.currentService.setCurrentStep(SYNCED);
        this.addMessage(INFO, SIGNED_UP(this.currentService.tier));
        this.stopSignUpProcess();
    }

    preSignUpAction() {
        return handleSignUp({
            params: JSON.stringify({
                action: 'EXECUTE_PRESIGNUP_ACTIONS',
                dataArr: [this.currentService.queryData]
            })
        });
    }

    startValidateProcessOrder() {
        this.spinnerText = "Processing " + this.currentService.tier + "...";
        if (this.currentService.isMvpOrNotUILess || this.currentService.isMeetingsOrNotUILess) {
            this.spinnerText = "Signing Up " + this.currentService.tier + "...";
            this.currentService.setProcessing();
            this.currentService.setCurrentStep(FUNNEL_REQUEST);
        }
        this.updateLayout();

        handleSignUp({
            params: JSON.stringify({
                action: 'VALIDATE_PROCESS_ORDER',
                data: this.currentService.signUpData
            })
        })
        .then(res => this.handleResponse(res, () => {}))
        .then(() => this.startFunnelRequest())
        .catch(res => this.handleError(res));
    }

    async updateMasterOpptyRCCCSyncStatus(rcccSyncStatus) {
        if (!this.isRCCC) {
            return;
        }
        try {
            const res = await handleSignUp({
                params: JSON.stringify({
                    action: 'UPDATE_PROCESS_ORDER_CC_SYNC_STATUS',
                    rcccSyncStatus: rcccSyncStatus,
                    data: this.currentService.signUpData
                })
            });
            await this.handleResponse(res, () => {});

        } catch (res) {
            this.handleError(res);
        }
    }

    async startFunnelRequest() {
        try {
            let res = await handleSignUp({
                params: JSON.stringify({
                    action: 'SIGNUP',
                    data: this.currentService.signUpData
                })
            });
            await this.handleResponse(res, this.handleFunnelRequest.bind(this));

            if (this.isServiceMvpOrMeetings || this.isProServ || this.isRCEvent) {
              await this.updateServiceInfoAfterSignUp();
            }

            this.stopSignUpProcess();
            await this.updateMasterOpptyRCCCSyncStatus(CC_SYNC_STATUS_STARTED);

        } catch (res) {
            this.handleError(res);
            await this.updateMasterOpptyRCCCSyncStatus(DEFAULT_SYNC_ERROR);
        }
    }

    async handleResponse(res, handler) {
        const response = JSON.parse(res);
        console.log('handleResponse: ', response);

        if (response.messages?.length > 0) {
            this.messages.push(...response.messages);
            if (response.messages.some(m => m.severity === ERROR)) {
                this.currentService.isExpired = false;
                await Promise.reject(response.messages);
            }
        }

        await handler(response);
        this.updateLayout();

        if (response?.data?.redirectUrl) {
            this.addMessage('success', 'Request sent successfully. Complete SignUp in Funnel');
            this.redirect(response);
            this.isCompleted = !this.isMultiProductFTEnabled;
            if (!this.currentService?.isExistingBusiness && this.childServicesNames) {
                this.addMessage(INFO, CONTACT_ORDER_MANAGEMENT(this.childServicesNames));
            }
        }
    }

    startProServSignUp() {
        this.spinnerText = "Signing Up " + this.currentService.tier + "...";
        this.startFunnelRequest()
            .catch(res => this.handleError(res));
    }

    showStepsStarted() {
        this.setMultiSteps(QUERYING_DATA);
    }

    handleQueryData(response) {
        response.data.services?.forEach(service => {
            const [pInfo] = JSON.parse(service.data.targetQuote?.Package_Info__c);

            const cService = this.servicesMap.get(pInfo?.productName);
            cService.queryData = service.data;
            cService.dataRetentionDuration = pInfo?.offerType === 'POC' ? service.data.targetQuote?.DataRetentionDuration__c : service.data.primaryQuote?.DataRetentionDuration__c;
        });
        this.setMultiSteps(VALIDATION);
    }

    handleValidation() {
        this.setMultiSteps(PREPARING_CASES);
    }

    handleDealDeskCaseDescriptions() {
        this.setMultiSteps(PREPARING);
    }

    handlePreparing(response) {
        response.data.updatedData.forEach(preparedData => {
            const tier = JSON.parse(preparedData.targetQuote.Package_Info__c)[0].productName;
            const service = this.servicesMap.get(tier);

            service.setCurrentStep(READY_TO_FUNNEL);
            service.signUpData = preparedData;

            const account = service.signUpData?.opportunity?.Account || this.opportunity.Account;
            service.address = {
                city: account.BillingCity,
                country: account.BillingCountry,
                zip: account.BillingPostalCode,
                state: account.BillingState,
                address1: account.BillingStreet
            }
        });

        const signUpData = this.contactCenter?.signUpData;
        this.rcccParameters = {
            ccNumber: signUpData?.opportunity?.NumberToBeCCNumber__c,
            city: this.contactCenter?.address?.city,
            state: this.contactCenter?.address?.state,
            brandName: signUpData?.opportunity?.Account?.RC_Brand__c || signUpData?.opportunity?.Brand_Name__c,
            currentUser: signUpData?.user
        };
    }

    handleFunnelRequest(response) {
        if (this.currentService.isMvpAndUILess || this.currentService.isMeetingsAndUILess) {
            return this.handleRequest(response);
        }


        if (this.isProServ) {
            this.currentService.setCurrentStep(PROSERV_SIGNUP_REQUEST_SEND);
        } else {
            this.currentService.setCurrentStep(SYNCED);
        }

        if(this.isRCEvent){
            if (response.status === 'success') {
                this.addMessage('success', `${this.currentService.tier} submitted successfully`);
                this.currentService.setCompleted();
            }
        }

        if (this.isRCCC) {
            this.isReadyForGetOrderToVendorCatalog = true;
        }
    }

    handleSignupBodyPreview(response) {
        this.signupBody = response.data.signupBody.requestBodyMap;
    }

    handleRequest(response) {
        const status = response.data?.data?.result?.orderStatus;
        if (status === IN_PROCESS) {
            this.opportunity.Account.Internal_Enterprise_Account_ID__c = response.data.data.FSG_SID;
            this.currentService.setCurrentStep(READY_TO_FUNNEL);
            this.currentService.ngbsAccountStatus = INITIAL_NGBS_ACCOUNT_STATUS;
        }
    }

    async handleSubmitResponse(response) {
        this.isProcess = false;
        if (response.data.status === 'submitted') {
            this.addMessage('success', `${this.currentService.tier} submitted successfully`);
        }

        this.currentService.setCompleted();

        if (this.currentService.isCC && this.currentService.isExistingBusiness) {
            await updateSyncInfoAfterSyncICB({
                "quoteId": this.currentService.quoteId,
                "userName": this.currentService.signUpData?.user?.Name
            });
        }
        if (!this.currentService?.isExistingBusiness) {
            await this.updateServiceInfoAfterSignUp();
        }
    }

    // for CC submit is 2 requests in a row, PATCH and POST
    // they are split into 2 synchronous requests
    // because after PATCH response inContact case is created
    // and case number is sent in POST request
    handleSubmitPatchResponse(response) {
        this.caseNumber = response.data.caseNumber;
    }

    callSignUp() {
        handleSignUp({
            params: JSON.stringify({
                action: 'SIGNUP',
                data: this.currentService.signUpData
            })
        })
            .then(res => res.data.redirectUrl && this.redirect(res))
            .then(() => this.updateServiceInfoAfterSignUp())
            .then(() => this.isProcess = false);
    }

    handleError(errorResponse) {
        console.log('handleError: ', errorResponse);
        this.stopSignUpProcess();
        if (!errorResponse) {
            return;
        }
        this.isResponseHasError = true;

        if (Array.isArray(errorResponse)) {
            return this.parseEngageErrors(errorResponse);
        }

        const errorMessage = errorResponse.body?.message || errorResponse.message || errorResponse;
        if (errorMessage.includes(CASE_CREATE_ERROR)) {
            this.handleCaseCreationError()
        }

        this.addMessage(ERROR, errorMessage);
    }

    handleCaseCreationError() {
        this.isResponseHasError = false;
    }

    parseEngageErrors(errorMessages) {
        if (errorMessages.some(m => m.messageDetails?.toLowerCase().includes('domain'))) {
            this.engageError = {
                tier: this.currentService.tier,
                id: 'Domain'
            }
        }
        if (errorMessages.some(m => m.messageDetails?.toLowerCase().includes('platformid'))) {
            this.engageError = {
                tier: this.currentService.tier,
                id: 'PlatformId'
            }
        }
    }

    redirect(response) {
        window.open(response.data.redirectUrl, '_blank');
    }

    get isProcessOrError() {
        return this.isProcess || this.isResponseHasError;
    }

    get disableSignUp() {
        return this.isProServ || (this.isRCEvent && this.isSeveralServices)
            ? this.disableWhenOfficeNotCompleted
            : this.isProcessOrError || !this.currentService?.isSubmitReady;
    }

    get disableOldSignUp() {
        return this.isProcessOrError || this.disableWhenOfficeNotCompleted;
    }

    get disableProcessButton() {
        return (
            this.isProcessOrError ||
            this.disableWhenOfficeNotCompleted ||
            (this.currentService?.currentStep !== READY_TO_FUNNEL &&
                this.currentService?.currentStep !== READY_TO_CREATE_MAIN_COST_CENTER)
        );
    }

    clearNotifications() {
        if (this.messages.length > 0) {
            this.messages = [];
        }
    }

    clickSignUp() {
        if (this.isServiceMvpOrMeetings || this.isRCEvent) {
            return this.clickProcess();
        }
        if (this.isProServ) {
            return this.clickProServProcess();
        }
        this.clearNotifications()
        this.isProcess = true;

        this.currentService.setProcessing();
        this.startSubmit();
    }

    clickProcess() {
        this.clearNotifications()
        this.isProcess = true;
        this.isProServ ? this.processProServ() : this.startValidateProcessOrder();
    }

    clickProServProcess() {
        this.clearNotifications();
        this.isProcess = true;
        this.startProServSignUp();
    }

    clickCopyJSON() {
        const hiddenInput = document.createElement('input');
        hiddenInput.setAttribute('value', JSON.stringify(this.signupBody));
        document.body.appendChild(hiddenInput);
        hiddenInput.select();
        document.execCommand('copy');
        document.body.removeChild(hiddenInput);
    }

    clickExistingBusinessSync() {
        this.clearNotifications();

        if (!this.validateServicesPrerequisite()) return;

        this.currentService.existingBusinessSyncClicked = true;
        this.currentService.saveCurrentStateToQuote();
        this.updateLayout();
    }

    get isExistingCC() {
        return this.currentService?.isCC && this.currentService?.isExistingBusiness;
    }

    get hasAdminPreviewPermission() {
        return hasAdminPreviewPermission;
    }

    get showCopyJsonButton() {
        return this.hasAdminPreviewPermission && this.selectedSignUpTab == ADMIN_PREVIEW;
    }

    get signupJsonFormatted() {
        return JSON.stringify(this.signupBody, null, 2);
    }

    get copyJsonButtonText() {
        return COPY_JSON;
    }

    get signUpButtonText() {
        return `${this.isExistingCC ? 'Sync ' : 'Sign Up '}` + (this.currentService?.tier || '') + `${this.isExistingCC ? ' Order' : ''}`;
    }

    get processButtonText() {
        return `Process ${this.currentService?.tier || ''}`;
    }

    get showSignUpButton() {
        return (
            !this.showProcessButton &&
            this.currentService?.status !== COMPLETED &&
            this.isNewBusinessOrNotSyncedToIcb &&
            !this.showOldSignUpButton &&
            !this.showCopyJsonButton &&
            this.isReadyForValidation
        );
    }

    get showOldSignUpButton() {
        return (
            !this.currentService?.isUILessProcessOrderEnabled &&
            this.currentService?.status !== COMPLETED &&
            this.isNewBusinessOrNotSyncedToIcb &&
            this.isSeveralServices &&
            this.isReadyForValidation
        );
    }

    get showProcessButton() {
        return (
            this.isSeveralServices &&
            this.currentService?.currentStep !== SYNCED &&
            this.currentService?.status !== COMPLETED &&
            this.isNewBusinessOrNotSyncedToIcb &&
            !this.showOldSignUpButton &&
            !this.isServiceMvpOrMeetings &&
            this.currentService?.currentStep !== COST_CENTER_CREATED &&
            !this.isRCEvent &&
            this.isReadyForValidation
        );
    }

    get showExistingBusinessSyncButton() {
        return (
            this.currentService?.isExistingBusiness &&
            this.currentService?.status !== COMPLETED &&
            !this.currentService?.existingBusinessSyncClicked
        );
    }

    get disableExistingBusinessSync() {
        return this.isProcessOrError;
    }

    get existingBusinessSyncButtonText() {
        return `Sync ${this.currentService?.tier || ""} Order`;
    }

    get hideAllSignUpButtons() {
        return this.initialLoading || this.showStatusButton || this.isCurrentServiceAnyQuoteSignedUp; // Hide all buttons if any quote is already signed up
    }

    get isNewBusinessOrNotSyncedToIcb() {
        return !this.currentService?.isExistingBusiness || !this.currentService?.isSyncedToICB;
    }

    get showContinueButton() {
        if (!this.isBasicValidationPassed()) {
            return false;
        }

        if(this.isCCValidationPassed()){
            return true;
        }

        if (!this.isCurrentServiceValidForContinue()) {
            return false;
        }

        if (!this.isNgbsAccountStatusValid()) {
            return false;
        }

        if (!this.areAllQuoteTypesSelected()) {
            return false;
        }

        return this.isServiceOrderAndInteractionValid();
    }

    isBasicValidationPassed() {
        return (
            this.currentService &&
            !this.isReadyForValidation &&
            this.servicesMap.size > 0 &&
            (!this.currentService?.isExistingBusiness || (this.currentService.isCC && this.currentService.isInContactNotReadyForSync))
        );
    }

    isCCValidationPassed() {
        const currentService = this.servicesMap.get(this.currentTier);
        // Special case: Enable continue button for RingCentral Contact Center
        if(currentService.isInContactNotReadyForSync){
            return true;
        }

        if (currentService.isCC && currentService.SalesQuote?.ngbsAccountStatus === INITIAL_NGBS_ACCOUNT_STATUS && currentService.SalesQuote?.status !== COMPLETED) {
            return true;
        }

        return false;
    }

    isNgbsAccountStatusValid() {
        const ngbsStatus = this.currentService.ngbsAccountStatus;
        return ngbsStatus !== INITIAL_NGBS_ACCOUNT_STATUS && ngbsStatus !== ACTIVE_NGBS_ACCOUNT_STATUS;
    }

    areAllQuoteTypesSelected() {
        const services = this.servicesMap.values();

        for (const service of services) {
            if (service.availableQuoteTypes.length > 1 && service.selectedQuoteType == null) {
                return false;
            }
        }
        return true;
    }

    isCurrentServiceValidForContinue() {
        console.log('currentservic inside isCurrentServiceValidForContinue--> ',this.currentService);
        const currentService = this.servicesMap.get(this.currentTier);
        if (!currentService) {
            return false;
        }

        if (currentService.SalesQuote?.status === COMPLETED || currentService.POCQuote?.status === COMPLETED || currentService.POCQuote?.ngbsAccountStatus === INITIAL_NGBS_ACCOUNT_STATUS) {
            return false;
        }

        if (this.isPocCompletedButSalesNot(currentService)) {
            return true;
        }

        return true;
    }

    isPocCompletedButSalesNot(currentService) {
        const hasBothQuoteTypes =
            currentService.availableQuoteTypes.includes("Sales") && currentService.availableQuoteTypes.includes("POC");

        if (!hasBothQuoteTypes) {
            return false;
        }

        return currentService.SalesQuote?.status !== COMPLETED && currentService.POCQuote?.status === COMPLETED;
    }

    isServiceOrderAndInteractionValid() {
        const serviceKeys = Array.from(this.servicesMap.keys());
        const firstService = this.servicesMap.get(serviceKeys[0]);
        const isCurrentTierFirstService = this.currentTier === serviceKeys[0];

        if (isCurrentTierFirstService) {
            return firstService?.status !== COMPLETED;
        }

        return this.userHasClickedTierArrow;
    }

    get isCurrentServiceSalesQuoteSignedUp() {
        const currentService = this.servicesMap.get(this.currentTier);
        if (!currentService) return false;

        return currentService.SalesQuote && currentService.SalesQuote.status === COMPLETED;
    }

    get isCurrentServicePOCOnlySignedUp() {
        const currentService = this.servicesMap.get(this.currentTier);
        if (!currentService) return false;

        return (
            currentService.availableQuoteTypes.includes("Sales") &&
            currentService.availableQuoteTypes.includes("POC") &&
            currentService.SalesQuote &&
            currentService.SalesQuote.status !== COMPLETED &&
            currentService.POCQuote &&
            currentService.POCQuote.status === COMPLETED
        );
    }

    get isCurrentServiceAnyQuoteSignedUp() {
        const currentService = this.servicesMap.get(this.currentTier);
        if (!currentService) return false;

        if(currentService.isInContactNotReadyForSync){
            return false;
        }

        if(currentService.isCC && currentService.SalesQuote?.ngbsAccountStatus === INITIAL_NGBS_ACCOUNT_STATUS && currentService.SalesQuote?.status !== COMPLETED){
            return false;
        }

        if (
            currentService.SalesQuote &&
            (currentService.SalesQuote.status === COMPLETED ||
                currentService.SalesQuote.ngbsAccountStatus === INITIAL_NGBS_ACCOUNT_STATUS ||
                currentService.SalesQuote.ngbsAccountStatus === ACTIVE_NGBS_ACCOUNT_STATUS)
        ) {
            return true;
        }

        if (
            currentService.POCQuote &&
            (currentService.POCQuote.status === COMPLETED ||
                currentService.POCQuote.ngbsAccountStatus === INITIAL_NGBS_ACCOUNT_STATUS ||
                currentService.POCQuote.ngbsAccountStatus === ACTIVE_NGBS_ACCOUNT_STATUS)
        ) {
            return true;
        }

        return false;
    }

    get shouldContinueBackgroundProcess() {
        return this.shouldRunSignUpSteps;
    }

    get shouldRunSignUpSteps() {
        return this.targetIds.size > 0;
    }

    get shouldValidateCustomRules() {
        return this.services.some((s) => (s.isExistingBusiness && s.status !== COMPLETED) || s.isCC);
    }

    get expandableContentClass() {
        return this.isReadyForValidation ||
            this.currentService?.status === COMPLETED ||
            this.currentService?.ngbsAccountStatus === INITIAL_NGBS_ACCOUNT_STATUS
            ? "expandable"
            : "expandable not-ready-for-validation";
    }

    updateServiceExpandability() {
        Array.from(this.servicesMap.values()).forEach((service) => {
            service.isExpanded = false;
        });

        const currentService = this.servicesMap.get(this.currentTier);
        if (currentService) {
            currentService.isExpanded = true;
        }

        this.updateLayout();
    }

    initializeServicesCollapsed() {
        Array.from(this.servicesMap.values()).forEach((service) => {
            service.isExpanded = false;
        });
    }

    handleSubmitDataUpdate(event) {
        const detail = JSON.parse(JSON.stringify(event.detail));
        this.currentService.submitData = detail;

        this.isResponseHasError = false;

        if (!Boolean(detail?.timezone) && this.currentService.isEngage) {
            this.currentService.isSubmitReady = false;
            this.updateLayout();
            return;
        }

        if (!this.skipAddressValidation) {
            return;
        }

        this.prepareSubmit();
    }

    validateAddress(event) {
        this.spinnerText = 'Address Validation...';
        this.isProcess = true;
        const billingAddress = JSON.parse(JSON.stringify(event.detail));
        this.currentService.setAddress(billingAddress);

        handleSubmit({
            params: JSON.stringify({
                action: "validate address",
                data: { billingAddress },
                tier: this.currentService.tierLabel
            }),
        })
            .then((res) => this.handleResponse(res, this.handleAddressValidationResponse.bind(this)))
            .catch((res) => this.handleError(res));
    }

    handleAddressValidationResponse(response) {
        this.isProcess = false;
        const resBody = response.data.body
        switch (resBody?.status?.toLowerCase()) {
            case 'invalid':
                this.openInvalidAddressWindow = true;
                this.openSelectAddressWindow = true;
                break;
            case 'ambiguous':
                this.suggestedBillingAddresses = resBody.suggestedAddresses;
                this.openSelectAddressWindow = true;
                break;
            case 'valid':
                this.addMessage('success', 'Address successfully validated');
                this.prepareSubmit();
                break;
            default:
                this.handleError(resBody?.message || 'Unexpected error occured during address validation in external system');
                break;
        }
    }

    handleValidatedAddress(event) {
        this.closeAddressValidationWindow();
        const address = JSON.parse(JSON.stringify(event.detail))
        this.currentService.setAddress(address.selectedAddress);

        this.prepareSubmit();
    }

    closeAddressValidationWindow() {
        this.openSelectAddressWindow = false;
        this.openInvalidAddressWindow = false;
    }

    addMessage(severity, message) {
        this.messages.push(
            { severity, message }
        );
    }

    updateLayout() {
        this.services = [...this.servicesMap.values()];
    }

    async startSubmit() {
      this.spinnerText = `${this.isExistingCC ? 'Syncing ' : 'Signing Up '}` + this.currentService.tier + "...";
      try {
          let params = {
              action: 'submit ' + this.currentService.tier,
              targetId: this.currentService.oppId,
              data: this.currentService.submitData,
              isChangeOrder: this.currentService.isExistingBusiness,
              accountId: this.currentService.signUpData?.opportunity.Account.Id,
              isEngageVoice: this.currentService.tier === ENGAGE_VOICE,
              quoteId: this.currentService.quoteId,
              isMPUB: this.isMPUB,
              isMultiProductTechnicalQuote: this.currentService.isMultiProductTechnicalQuote,
          };
          let res = await handleSubmit({ params: JSON.stringify(params) });

          if (this.currentService.isCC) {
              await this.handleResponse(res, this.handleSubmitPatchResponse.bind(this));
              params = {...params, action: 'submit post contact center', caseNumber: this.caseNumber};
              res = await handleSubmit({ params: JSON.stringify(params) });
          }

          await this.handleResponse(res, this.handleSubmitResponse.bind(this));

      } catch (res) {
          this.handleError(res);
          await this.updateMasterOpptyRCCCSyncStatus(DEFAULT_SYNC_ERROR);
      }
    }

    prepareSubmit() {
        this.currentService.isSubmitReady = true;

        this.currentService.isEngage && this.prepareEngageSubmitData();
        this.currentService.isCC && this.prepareContactCenterSubmitData();

        this.updateLayout();
    }

    setMultiSteps(step) {
        this.spinnerText = step;
        this.currentService?.setCurrentStep(step);
    }

    get currentAddress() {
        return this.currentService?.address;
    }

    handleServiceTimezoneChange(event) {
        this.currentService.signUpData.timezoneId = JSON.parse(JSON.stringify(event.detail))?.timezoneId;

        this.currentService.isSubmitReady = Boolean(this.currentService.signUpData.timezoneId);
        this.updateLayout();
    }

    clearServiceTimezone() {
        const currentService = this.servicesMap.get(this.currentTier);
        if (!currentService) return;

        let component = null;

        if (currentService.isServiceMvpOrMeetings) {
            component = this.template.querySelector("c-sn-mvp-sign-up");
        } else if (currentService.isEngage) {
            component = this.template.querySelector("c-sn-sign-up-engage");
        }

        if (component && component.clearTimezone) {
            component.clearTimezone();
        }
    }

    handleRCEventTimezoneChange(event) {
        this.currentService.signUpData.timezoneName = JSON.parse(JSON.stringify(event.detail))?.timezoneName;

        this.currentService.isSubmitReady = Boolean(this.currentService.signUpData.timezoneName);
        this.updateLayout();
    }

    handleSelectedSignUpTab(event) {
        this.selectedSignUpTab = event.detail.selectedSignUpTab;
        if (this.selectedSignUpTab === ADMIN_PREVIEW) {
            handleSignUp({
                params: JSON.stringify({
                    action: 'BODY_PREVIEW',
                    data: this.currentService.signUpData
                })
            })
            .then(res => this.handleResponse(res, this.handleSignupBodyPreview.bind(this)))
            .catch(res => this.handleError(res));
        }
    }

    get sfAccountStatus() {
        return this.opportunity?.Account.RC_Account_Status__c;
    }

    get masterOpportunityService() {
        return this.servicesMap.get(this.opportunity?.Tier_Name__c);
    }

    get isShowSpinner() {
        return this.isProcess || this.initialLoading;
    }

    get accountName() {
        return this.currentService?.signUpData?.opportunity.Account.Name
            || this.opportunity?.Account.Name
            || 'loading...';
    }

    get showSyncButtons() {
        return this.currentService?.isSyncReady && !this.currentService?.isSyncCompleted;
    }

    get isShowSkip() {
        return this.currentService.isShowSkip;
    }

    get isShowNext() {
        return !this.isResponseHasError && this.currentService.isShowNext;
    }

    get nextButtonLabel() {
        return this.currentService.nextButtonLabel;
    }

    get checkButtonLabel() {
        return `Check ${this.currentService.tier} Status`;
    }

    get isServiceSignUpInProcess() {
        if (this.currentService.ngbsAccountStatus === INITIAL_NGBS_ACCOUNT_STATUS) {
            return !!this.opportunity?.Account?.Internal_Enterprise_Account_ID__c || true;
        }
        return false;
    }

    get isServiceSigned() {
        if (this.isProServ) {
            return this.isProServ && this.currentService.billingPackage;
        }
        return (
            this.isServiceMvpOrMeetings &&
            this.opportunity.Account.Billing_ID__c &&
            (this.isNGBSAccountActive ||
                this.isNGBSAccountInitial ||
                this.currentService.ngbsAccountStatus === INITIAL_NGBS_ACCOUNT_STATUS)
        );
    }

    get isNGBSAccountActive() {
        return this.ngbsAccountStatus === ACTIVE_NGBS_ACCOUNT_STATUS;
    }

    get isNGBSAccountInitial() {
        return (
            this.ngbsAccountStatus === INITIAL_NGBS_ACCOUNT_STATUS &&
            !ACCOUNT_INACTIVE_STATUSES.includes(this.sfAccountStatus)
        );
    }

    get showStatusButton() {
        return (
            (this.isProServ &&
                this.currentService?.status !== COMPLETED &&
                this.currentService?.currentStep === PROSERV_SIGNUP_REQUEST_SEND) ||
            (this.isServiceMvpOrMeetings &&
                (this.isServiceSignUpInProcess || this.isNGBSAccountInitial) &&
                !this.currentService?.isExistingBusiness &&
                !this.isNGBSAccountActive)
        );
    }

    get getQueryServicesData() {
        return [...this.servicesMap.values()].reduce((result, service) => {
            service.queryData && result.push(service.queryData);
            return result;
        }, []);
    }

    get opptyBrandName() {
        return this.opportunity.Brand_Name__c;
    }

    get opptyCurrencyIsoCode() {
        return this.opportunity.CurrencyIsoCode;
    }

    get isServiceMvpOrMeetings() {
        return this.currentService?.isServiceMvpOrMeetings;
    }

    get isProServ() {
        return this.currentService?.isProServ;
    }

    get isRCEvent() {
        return this.currentService?.isRCEvent;
    }

    stopSignUpProcess() {
        this.initialLoading = false;
        this.isProcess = false;
    }

    checkServiceStatus() {
        this.isProcess = true;
        this.spinnerText = 'Request in progress';
        getOppBillingDetail({ "OppId": this.targetId })
            .then(params => this.handleCheckStatus(params))
            .catch(res => this.handleError(res));
    }

    handleCheckStatus(params) {
        this.opportunity = params.opportunity;
        this.populateAccountIdsInSignUpData();
        this.populateBillingPackageForService(params);

        this.productNameToPackageIsActiveStatusMap = params.productNameToPackageIsActiveStatusMap;

        this.updateNgbsAccountStatusFromQuoteType();

        this.updateServiceAccountStatus(this.currentService, params);

        if (
            this.ngbsAccountStatus === "Active" &&
            this.currentService.selectedContainer &&
            this.currentService.selectedContainer.ngbsAccountStatus === "Active"
        ) {
            this.currentService.setCompleted();
            this.template.querySelectorAll("c-sn-tier-option").forEach((tierOption) => {
                tierOption.isQuoteTypeDisabled = this.isQuoteTypeDisabledForService;
            });
        }

        this.isProcess = false;
        this.setServiceCompleted();
        this.spinnerText = '';

        this.updateLayout();
    }

    populateAccountIdsInSignUpData() {
        this.servicesMap.forEach(({ signUpData }) => {
            if (signUpData) {
                const { opportunity } = signUpData;
                const targetAccount = this.determineTargetAccount(opportunity);

                this.assignAccountIds(targetAccount);
            }
        });
    }

    determineTargetAccount(opportunity) {
        const isMasterAccountApplicable = !this.isMPUB && opportunity.Account.Master_Account__r;
        return isMasterAccountApplicable ? opportunity.Account.Master_Account__r : opportunity.Account;
    }

    assignAccountIds(targetAccount) {
        const { Billing_ID__c, RC_User_ID__c } = this.opportunity.Account;
        Object.assign(targetAccount, { Billing_ID__c, RC_User_ID__c });
    }

    setServiceCompleted() {
        this.clearNotifications();
        if (
            this.isServiceSigned &&
            this.currentService.status !== PROCESSING &&
            (this.currentService.status !== ACTIVE || this.currentService.tierLabel === TIER_PROFESSIONAL_SERVICES)
        ) {
            if (this.isNGBSAccountInitial) {
                this.addMessage("info", SIGNED_UP(this.currentService.tier));
            }
            this.currentService.setCompleted();
        } else {
            this.addMessage("info", SIGN_UP_IN_PROCESS(this.currentService.tier));
        }

        if (!this.isNGBSAccountActive) {
            const shouldShowSignedUp = this.isNGBSAccountInitial || this.currentService.status === COMPLETED;
            this.addMessage(
                INFO,
                shouldShowSignedUp ? SIGNED_UP(this.currentService.tier) : SIGN_UP_IN_PROCESS(this.currentService.tier)
            );
        }
    }

    onNextSync() {
        if (!this.validateServicesPrerequisite()) return;

        this.currentService.isSyncInProcess = true;
        this.template.querySelector(`c-sn-main[data-quote-id="${this.currentService.quoteId}"]`)?.onNextSync();
    }

    onSkipSync() {
        this.template.querySelector(`c-sn-main[data-quote-id="${this.currentService.quoteId}"]`)?.onSkipSync();
    }

    handleSyncEvent(event) {
        const service = this.servicesMap.get(event.detail.tierLabel);
        new Map(Object.entries(event.detail)).forEach((v, k) => (service[k] = v));

        if (service.isSyncCompleted) {
            service.setCompleted();
            if (service.SalesQuote) {
                service.SalesQuote.status = service.status;
            }
        }
        this.updateLayout();
    }

    handleAddMessage(event) {
        this.messages.push(event.detail);
    }

    hideDivider() {
        [...this.servicesMap?.values()]?.at(-1)?.setLast();
        this.updateLayout();
    }

    setTermination() {
        const service = new Service({
            tierLabel: this.opportunity.Tier_Name__c,
            oppId: this.opportunity.Id,
            isExistingBusiness: true
        });
        this.servicesMap.set(service.tierLabel, service);
    }

    setCurrentService() {

        this.currentTier = [...this.servicesMap.keys()][0];
        this.currentService.isExpanded = true;

        this.userHasClickedTierArrow = false;
    }

    updateServiceAccountStatus(service = null, params = null) {
        const servicesToUpdate = service ? [service] : Array.from(this.servicesMap.values());

        servicesToUpdate.forEach((currentService) => {
            const tierLabel = currentService.tierLabel;
            const signedUpInfo = params
                ? params.productNameToPackageIsActiveStatusMap[tierLabel]
                : this.productNameToPackageIsActiveStatusMap[tierLabel];

            if (!signedUpInfo) {
                return;
            }

            const availableQuoteTypes = currentService.availableQuoteTypes;

            availableQuoteTypes.forEach((quoteType) => {
                const statusKey = quoteType === "POC" ? "pocStatus" : "salesStatus";
                const actualStatus = signedUpInfo[statusKey];

                if (actualStatus !== null && actualStatus !== undefined) {
                    if (quoteType === "Sales" && currentService.SalesQuote) {
                        currentService.SalesQuote.ngbsAccountStatus = actualStatus;
                    } else if (quoteType === "POC" && currentService.POCQuote) {
                        currentService.POCQuote.ngbsAccountStatus = actualStatus;
                    }
                }
            });
        });
    }

    completeProcessOrderUISettings() {
        // hide divider line under last service
        this.hideDivider();
        this.initialLoading = false;
        this.spinnerText = '';
    }

    isPOC(services) {
        return services.some(s => s.isPOC);
    }

    setPOC() {
        this.servicesMap = new Map([[this.pocService.tierLabel, this.pocService]]);
        this.targetIds = new Set([this.pocService.quoteId]);
        this.setCurrentService();
        this.completeProcessOrderUISettings();
    }

    get modalWindowStyle() {
        return 'slds-modal' + (this.initialLoading ? '-initial' : 'slds-fade-in-open slds-scrollable_y');
    }

    get temporaryWindowStyle() {
        return `font-size: 20px;height:${this.contactCenter?.isExpanded ? 5 : 0 }rem`;
    }

    onClose() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    navigateToNewCasePage() {
        let caseMap = new Map();
        caseMap.set('Case_Category__c', 'Provisioning Assistance');
        caseMap.set('Origin', 'Process Order');
        caseMap.set('AccountId', this.opportunity.AccountId);
        caseMap.set('Opportunity_Reference__c', this.opportunity.Id);
        caseMap.set('CSM__c', this.opportunity.Account.CSM__c);
        caseMap.set('ParentPartnerAccount__c', this.opportunity.Account.Parent_Partner_Account__c);
        caseMap.set('AccountOwner__c', this.opportunity.Account.OwnerId);

        let encodedString = this.encodeDefaultFieldValues(caseMap);
        window.open('/apex/CaseCreationRedirect?mapParam=' + encodedString);
    }

    encodeDefaultFieldValues(caseMap) {
        const encodedString = encodeURIComponent(
            Array.from(caseMap.keys()).reduce((result, key) => {
                const value = caseMap.get(key);
                return value ? `${result}${key}=${value},` : result;
            }, "")
        );
        return encodedString;
    }

    async runCustomRulesValidation() {
        const messages = JSON.parse(await customRulesValidation({opportunityId: this.opportunityRecordId}));
        if (messages && messages.length > 0) {
          await Promise.reject(messages);
        }
    }

    async updateServiceInfoAfterSignUp() {
        await updateServiceInfoAfterSignUp({"quoteId": this.currentService.quoteId});
    }

    async processProServ() {
        handleSignUp({
            params: JSON.stringify({
                action: 'VALIDATE_PROCESS_ORDER',
                data: this.currentService.signUpData
            })
        })
        .then(res => this.handleResponse(res, () => {}))
        .catch(res => this.handleError(res));
        if (this.currentService.currentStep === READY_TO_CREATE_MAIN_COST_CENTER) {
            this.spinnerText = 'Creating Main Cost Center...';
            try {
                const params = {
                    params: JSON.stringify({
                        billingId: this.currentService.signUpData.opportunity.Account.Billing_ID__c
                    })
                };
                const res = JSON.parse(
                    await createMainCostCenter(params)
                );
                if (res?.data?.isMainCostCenterCreated) {
                  this.currentService.setCurrentStep(COST_CENTER_CREATED);
                }
                this.isProcess = false;
            } catch (res) {
                this.handleError(res);
            }
        }

        if (this.currentService.currentStep !== READY_TO_CREATE_MAIN_COST_CENTER || this.currentService.currentStep !== COST_CENTER_CREATED) {
            this.spinnerText = 'Checking Main Cost Center...';
            try {
                const params = {
                    params: JSON.stringify({
                        billingId: this.currentService.signUpData.opportunity.Account.Billing_ID__c
                    })
                };
                const res = JSON.parse(
                    await checkIsMainCostCenterExist(params)
                );

                res?.data?.isMainCostCenterExist
                    ? this.currentService.setCurrentStep(COST_CENTER_CREATED)
                    : this.currentService.setCurrentStep(READY_TO_CREATE_MAIN_COST_CENTER);
                this.isProcess = false;
            } catch (res) {
                this.handleError(res);
            }
        }
    }

  populateBillingPackageForService(params) {
    params.masterAndTechQuotes.forEach((quote) => {
      const isNeedToPopulatePackageId = this.currentService.billingPackage == null
        && quote.IsMultiProductTechnicalQuote__c
        && quote.ServiceName__c == this.currentService.tier;

      if (isNeedToPopulatePackageId) {
        this.currentService.setBillingPackage(quote.BillingPackage__c);
      }
    });
  }


    updateNgbsAccountStatusFromQuoteType() {
        console.log("updateNgbsAccountStatusFromQuoteType ", this.productNameToPackageIsActiveStatusMap);
        if (!this.productNameToPackageIsActiveStatusMap || !this.currentTier) {
            return;
        }

        if (this.currentTier !== "Office") {
            return;
        }

        const tierStatusInfo = this.productNameToPackageIsActiveStatusMap[this.currentTier];
        if (!tierStatusInfo) {
            this.ngbsAccountStatus = null;
            return;
        }

        const currentService = this.servicesMap.get(this.currentTier);

        const selectedQuoteType = currentService?.selectedQuoteType || "Sales"; // Default to Sales
        let quoteSpecificStatus = null;

        if (selectedQuoteType === "POC") {
            quoteSpecificStatus = tierStatusInfo.pocStatus;
        } else if (selectedQuoteType === "Sales") {
            quoteSpecificStatus = tierStatusInfo.salesStatus;
        }

        if (quoteSpecificStatus === "Active") {
            this.ngbsAccountStatus = "Active";
        } else if (quoteSpecificStatus === "Initial") {
            this.ngbsAccountStatus = "Initial";
        } else {
            this.ngbsAccountStatus = null;
        }
    }
}