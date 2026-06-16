import { Approval } from './Approval';
import { File } from './File';
import { BillingAddress } from './BillingAddress';

KycDetailsError.prototype = Object.create(Error.prototype);
KycDetailsError.prototype.constructor = KycDetailsError;

const MESSAGES = {
    wrongState: 'State is incorrect. Please provide valid India state',
    wrongGstNumber: 'Provided GST number is incorrect',
    gstNumberMismatch: 'Provided GST number doesn\'t match the billing state on the account. Billing state for provided GST number should be: {0}',
};

export class App {
    documentTypes = {
        IDENTITY_DOCUMENT: 'Identity Document',
        PHOTO_ID: 'PhotoId',
        AUTHORISATION_LETTER: 'Authorisation letter'
    }

    sections = {
        IDENTITY_ATTACHMENT: '0',
        PHOTO_ID_ATTACHMENT: '1',
        AUTHORISATION_LETTER_ATTACHMENT: '2',
        PARTICIPATION_AGREEMENT: '3',
        GST_ATTACHMENT: '4',
        SEZ_LETTER_ATTACHMENT: '5',
        GIR_ATTACHMENT: '6',
        ADDRESS_SIGNATORY_ATTACHMENT: '7',
        PASSPORT_SIGNATORY_ATTACHMENT: '8'
    }

    sectionIdToSectionNameMap = {
        [this.sections.IDENTITY_ATTACHMENT]: 'Identity document of company',
        [this.sections.PHOTO_ID_ATTACHMENT]: 'Photo ID Proof Type of Authorised Signatory',
        [this.sections.AUTHORISATION_LETTER_ATTACHMENT]: 'Authorisation Letter for Authorised Signatory',
        [this.sections.GIR_ATTACHMENT]: 'PAN/GIR No.',
        [this.sections.GST_ATTACHMENT]: 'GST No. & Certificate',
        [this.sections.SEZ_LETTER_ATTACHMENT]: 'Exemption/SEZ Certificate Number & Certificate',
        [this.sections.ADDRESS_SIGNATORY_ATTACHMENT]: 'Address of the Authorised Signatory',
        [this.sections.PASSPORT_SIGNATORY_ATTACHMENT]: 'Passport of the Authorised Signatory',
        [this.sections.PARTICIPATION_AGREEMENT]: 'Signed off Participation Agreement',
    }

    sectionToDocumentTypeMap = {
        [this.sections.IDENTITY_ATTACHMENT] : this.documentTypes.IDENTITY_DOCUMENT,
        [this.sections.PHOTO_ID_ATTACHMENT] : this.documentTypes.PHOTO_ID,
        [this.sections.AUTHORISATION_LETTER_ATTACHMENT] : this.documentTypes.AUTHORISATION_LETTER,
    };

    constructor() {
        this.initVariables();
        this.rx = {
            approval: new NA.rxjs.BehaviorSubject(),
            billingAddress: new NA.rxjs.BehaviorSubject(),
            documents: new NA.rxjs.BehaviorSubject(),
            files: new NA.rxjs.BehaviorSubject(),
            isLoading: new NA.rxjs.BehaviorSubject(),
            isShowSectionDetails: new NA.rxjs.BehaviorSubject(),
        };
    }

    setData(response) {
        this.initVariables();
        this.setApproval(response);
        this.setBillingAddress(response);
        this.setDocuments();
        this.setFiles(response);
        this.setUserPermissionToEditRequestAfterFinalStep(response);
        this.setIsUserHasPermissionSetToEditKYCApprovalRequest(response);
        this.setIsUserHasPermissionSetToReadKYCApprovalRequest(response);
        this.setUserInfo(response);
    }

    initVariables() {
        this.initialBillingAddress = null;
        this.modifiedBillingAddress = null;

        this.initialApproval = null;
        this.modifiedApproval = null;

        this.initialDocuments = {
            [this.documentTypes.IDENTITY_DOCUMENT]: {
                type: this.documentTypes.IDENTITY_DOCUMENT
            },
            [this.documentTypes.PHOTO_ID]: {
                type: this.documentTypes.PHOTO_ID
            },
            [this.documentTypes.AUTHORISATION_LETTER]: {
                type: this.documentTypes.AUTHORISATION_LETTER
            },
        };
        this.modifiedDocuments = {};

        this.initialFiles = {
            [this.sections.IDENTITY_ATTACHMENT]: [],
            [this.sections.PHOTO_ID_ATTACHMENT]: [],
            [this.sections.AUTHORISATION_LETTER_ATTACHMENT]: [],
            [this.sections.GIR_ATTACHMENT]: [],
            [this.sections.GST_ATTACHMENT]: [],
            [this.sections.SEZ_LETTER_ATTACHMENT]: [],
            [this.sections.ADDRESS_SIGNATORY_ATTACHMENT]: [],
            [this.sections.PASSPORT_SIGNATORY_ATTACHMENT]: [],
            [this.sections.PARTICIPATION_AGREEMENT]: []
        }
        this.modifiedFiles = {};

        this.isLoading = false;
        this.isShowSectionDetails = false;
        this.isUserCanEditRequestAfterFinalStep = false;
        this.isUserHasPermissionSetToEditKYCApprovalRequest = false;
        this.isUserHasPermissionSetToReadKYCApprovalRequest = false;

        this.userInfo = {};
    }

    setApproval(response) {
        this.initialApproval = response && response.data && response.data.approval
            ? new Approval(response.data.approval)
            : null;
        this.modifiedApproval = this.initialApproval;
        this.rx.approval.next(this.modifiedApproval);
    }

    setBillingAddress(response) {
        this.initialBillingAddress = response && response.data
            ? new BillingAddress(response.data.billingAddress)
            : null;
        this.modifiedBillingAddress = {...this.initialBillingAddress};
        this.rx.billingAddress.next(this.modifiedBillingAddress);
    }

    setDocuments() {
        if (this.initialApproval && this.initialApproval.rawDocuments.length) {
            this.initialApproval.rawDocuments.forEach(doc => {
                this.initialDocuments[doc.type] = doc;
            });
        }

        Object.values(this.documentTypes).forEach(type => {
            this.initialDocuments[type].approvalId = this.initialApproval.id;
        });

        this.modifiedDocuments = {...this.initialDocuments};

        this.rx.documents.next(this.modifiedDocuments);
    }

    setFiles(response) {
        if (response && response.data && response.data.files) {
            JSON.parse(response.data.files).forEach(f => {
                const file = new File(f);
                file.sectionId = this.fileIdToSectionMap[file.contentDocumentId];
                this.initialFiles[file.sectionId].push(file);
            });
            /* Deep clone is required */
            this.modifiedFiles = JSON.parse(JSON.stringify(this.initialFiles));
        }
        this.rx.files.next(this.modifiedFiles);
    }

    setDocument(doc) {
        this.modifiedDocuments[doc.type] = doc;
        this.rx.documents.next(this.modifiedDocuments);
    }

    updateApproval(app) {
        this.modifiedApproval = app;
        this.rx.approval.next(this.modifiedApproval);
    }

    updateBillingAddress(modifiedObj) {
        this.modifiedBillingAddress = modifiedObj;
        this.rx.billingAddress.next(this.modifiedBillingAddress);
    }

    isApprovalHasUnsavedChanges() {
        return Boolean(
            this.initialApproval
            && this.modifiedApproval
            && (this.initialApproval.gstNo != this.modifiedApproval.gstNo
                || this.initialApproval.gstStateCodeOfCustomer != this.modifiedApproval.gstStateCodeOfCustomer
                || this.initialApproval.dateOfSign != this.modifiedApproval.dateOfSign)
        );
    }
    isApprovalFieldChanged(field) {
        return this.initialApproval && this.modifiedApproval && this.initialApproval[field] != this.modifiedApproval[field];
    }

    isBillingAddressHasUnsavedChanges() {
        let isAddressChanged = false;
        if (this.initialBillingAddress && this.modifiedBillingAddress) {
            Object.keys(this.modifiedBillingAddress).forEach(
                key => isAddressChanged |=
                    this.initialBillingAddress[key] != this.modifiedBillingAddress[key]
            );
        }
        return isAddressChanged;
    }

    setFile(targetSectionId, uploadedFiles) {
        Array.prototype.forEach.call(uploadedFiles, file => {
            file.parentId = this.getParentId(targetSectionId);
            file.uid = new Date().getTime() + Math.random();
            file.sectionId = targetSectionId;
            this.modifiedFiles[targetSectionId].push(file);
        });

        this.rx.files.next(this.modifiedFiles);
    }

    setLoadingStatus(status) {
        this.isLoading = status;
        this.rx.isLoading.next(this.isLoading);
    }

    toggleSectionDetails() {
        this.isShowSectionDetails = !this.isShowSectionDetails;
        this.rx.isShowSectionDetails.next(this.isShowSectionDetails);
    }

    deleteFile(uid) {
        Object.values(this.modifiedFiles).forEach(sectionFiles =>{
            sectionFiles.forEach(f => {
                if (f.uid === uid) {
                    f.isDeleted = true;
                }
            });
        });
        this.rx.files.next(this.modifiedFiles);
    }

    get fileIdToSectionMap() {
        /* It is considered that file ids are stored in following way:
         * 'id_1,id_2;id_3;id_4,id_5;;;;;id_6;'
         * Sections are divided by ';'
         * List of files in section are divided via ','
         */
        let result = {};
        const filesArrayId = this.initialApproval && this.initialApproval.kycFiles.split(';');
        for (let i = 0; i < filesArrayId.length; i++) {
            if (filesArrayId[i] !== '') {
                const idsForSection = filesArrayId[i].split(',');
                idsForSection.forEach(id => result[id] = i);
            }
        }
        return result;
    }

    getParentId(targetSectionId) {
        const documentType = this.sectionToDocumentTypeMap[targetSectionId];
        return documentType
            ? this.modifiedDocuments[documentType].id
            : this.initialApproval.id;
    }

    isDocumentsHaveUnsavedChanges() {
        return this.getChangedDocuments().length;
    }

    getChangedDocuments() {
        var changedDocuments = [];

        Object.values(this.documentTypes).forEach(type => {
            const initialDocument = this.initialDocuments[type];
            const modifiedDocument = this.modifiedDocuments[type];
            if (this.isDocumentChanged(initialDocument,modifiedDocument)) {
                changedDocuments.push(modifiedDocument);
            }
        });
        return changedDocuments;
    }

    isDocumentChanged(iDoc, mDoc) {
        return iDoc && mDoc &&
            (iDoc.dateOfIssue != mDoc.dateOfIssue ||
            iDoc.documentNo != mDoc.documentNo ||
            iDoc.issuingAuthority != mDoc.issuingAuthority ||
            iDoc.placeOfIssue != mDoc.placeOfIssue)
    }

    isFilesChanged() {
        return Object.keys(this.modifiedFiles).some(sectionId => {
            if (!this.modifiedFiles[sectionId]) {
                return false;
            }
            const newFilesUploaded = this.modifiedFiles[sectionId].filter(f => f.id || !f.isDeleted).length != this.initialFiles[sectionId].length;
            const filesDeleted = this.modifiedFiles[sectionId].some(file => file.id && file.isDeleted);

            return newFilesUploaded || filesDeleted;
        });
    }

    getFilesToDelete() {
        let filesToDelete = [];
        Object.keys(this.modifiedFiles).forEach(sectionId => {
            const sectionFiles = this.modifiedFiles[sectionId];
            filesToDelete.push(...sectionFiles.filter(f => f.id && f.isDeleted).map(f => f.contentDocumentId));
        });
        return filesToDelete;
    }

    getFilesToCreate() {
        let filesToCreate = [];
        Object.keys(this.modifiedFiles).forEach(sectionId => {
            const sectionFiles = this.modifiedFiles[sectionId];
            filesToCreate.push(...sectionFiles.filter(f => !f.id && !f.isDeleted));
        });
        return filesToCreate;
    }

    resetForm() {
        this.modifiedApproval = JSON.parse(JSON.stringify(this.initialApproval));
        this.modifiedBillingAddress = JSON.parse(JSON.stringify(this.initialBillingAddress));
        this.modifiedDocuments = JSON.parse(JSON.stringify(this.initialDocuments));
        this.modifiedFiles = JSON.parse(JSON.stringify(this.initialFiles));

        this.rx.approval.next(this.modifiedApproval);
        this.rx.billingAddress.next(this.modifiedBillingAddress);
        this.rx.documents.next(this.modifiedDocuments);
        this.rx.files.next(this.modifiedFiles);
    }

    getDocumentIdOnDownload(event) {
        const sectionFiles = this.modifiedFiles[event.target.dataset.id.substring(1)];
        return sectionFiles[sectionFiles.length - 1].contentDocumentId;
    }

    getFileSize(bytes) {
        if (bytes == 0) {
            return '0 Byte';
        }
        const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
        let i = parseInt(Math.floor(Math.log(bytes) / Math.log(1024)));
        return Math.round(bytes / Math.pow(1024, i), 2) + ' ' + sizes[i];
    }

    truncName(name, num) {
        if (name.length <= num) {
            return name;
        }
        return name.slice(0, num) + '...';
    }

    get baseUrl() {
        return window.location.origin;
    }

    isNoActiveFilesForSection(sectionNumber) {
        return sectionNumber
            && (!this.modifiedFiles[sectionNumber]
                || this.modifiedFiles[sectionNumber]
                    && !this.modifiedFiles[sectionNumber].filter(file => !file.isDeleted).length);
    }

    isBillingAddressPopulated() {
        return this.modifiedBillingAddress
            && this.modifiedBillingAddress.billingStreet
            && this.modifiedBillingAddress.billingCity
            && this.modifiedBillingAddress.billingState
            && this.modifiedBillingAddress.billingCountry
            && this.modifiedBillingAddress.billingPostalCode;
    }

    isInvalidBillingStreet() {
        return this.modifiedBillingAddress
            && this.modifiedBillingAddress.billingStreet
            && this.modifiedBillingAddress.billingStreet.length > 150;
    }

    isGstNoEmpty() {
        return !this.modifiedApproval.gstNo?.length
            && !this.isNoActiveFilesForSection(window.app.sections.GST_ATTACHMENT);
    }

    deleteFilesForSection(sectionNumber) {
        this.modifiedFiles[sectionNumber] && this.modifiedFiles[sectionNumber].forEach(file => {
            this.deleteFile(file.uid);
        });
    }

    getUserPermissionToEditRequestAfterFinalStep() {
        return this.isUserCanEditRequestAfterFinalStep;
    }

    setUserPermissionToEditRequestAfterFinalStep(response) {
        const value = response?.data?.isUserCanEditRequestAfterFinalStep;
        if (this.isUserCanEditRequestAfterFinalStep != value) {
            this.isUserCanEditRequestAfterFinalStep = value;
        }
    }

    setIsUserHasPermissionSetToEditKYCApprovalRequest(response) {
        const value = (response?.data?.isUserHasPermissionSetToEditKYCApprovalRequest || response?.data?.isUserCanEditRequestAfterFinalStep);
        if (this.isUserHasPermissionSetToEditKYCApprovalRequest != value) {
            this.isUserHasPermissionSetToEditKYCApprovalRequest = value;
        }
    }

    getIsUserHasPermissionSetToEditKYCApprovalRequest() {
        return this.isUserHasPermissionSetToEditKYCApprovalRequest;
    }

    setIsUserHasPermissionSetToReadKYCApprovalRequest(response) {
        const value = response?.data?.isUserHasPermissionSetToReadKYCApprovalRequest;
        if (this.isUserHasPermissionSetToReadKYCApprovalRequest != value) {
            this.isUserHasPermissionSetToReadKYCApprovalRequest = value;
        }
    }

    getIsUserHasPermissionSetToReadKYCApprovalRequest() {
        return this.isUserHasPermissionSetToReadKYCApprovalRequest;
    }

    getUserInfo() {
        return this.userInfo;
    }
    setUserInfo(response) {
        this.userInfo = {
            userId: response?.data?.userId,
            userSessionId: response?.data?.userSessionId,
            orgHost: response?.data?.orgHost
        };
    }
}

export function KycDetailsError(error) {
    this.name = error.typeName;
    this.data = error.data;
    if (Array.isArray(error.messages) && error.messages.length) {
        this.message = error.messages.map(e => {
            if (error.stackTrace) {
                return `${this.name}: ${e.message} \n ${error.stackTrace}`;
            }
            return e.message;
        }).join(', \n');
    } else if (this.data?.hasOwnProperty('isValidState') && !this.data?.isValidState) {
        this.message = MESSAGES.wrongState;
    } else if (this.data?.hasOwnProperty('isValidGstNoForState') && !this.data?.isValidGstNoForState) {
        this.message = this.data.alpha2Code
            ? MESSAGES.gstNumberMismatch.replace('{0}', this.data.alpha2Code)
            : MESSAGES.wrongGstNumber;
    } else {
        this.message = error.messages;
    }

    if (Error.captureStackTrace) {
        Error.captureStackTrace(this, this.constructor);
    } else {
        this.stack = error.stackTrace;
    }
}