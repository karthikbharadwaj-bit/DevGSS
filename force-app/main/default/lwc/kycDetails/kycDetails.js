import { LightningElement, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { loadScript } from "lightning/platformResourceLoader";
import { App } from './App';
import { KycDetailsError } from './App';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { subscribe, onError } from "lightning/empApi";
import { loadStyle } from 'lightning/platformResourceLoader';
import KycDetailsDependencies from '@salesforce/resourceUrl/KycDetailsDependencies';
import KycDetailsStyles from '@salesforce/resourceUrl/KycDetailsStyles';
import { KycDocumentValidation } from './KycDocumentValidation';

import getData from '@salesforce/apex/KycDetailsHelper.getData';
import saveDocuments from '@salesforce/apex/KycDetailsHelper.saveDocuments';
import deleteFiles from '@salesforce/apex/KycDetailsHelper.deleteFiles';
import createFileJunctionObject from '@salesforce/apex/KycDetailsHelper.createContentDocumentLink';
import updateApproval from '@salesforce/apex/KycDetailsHelper.updateApproval';
import updateLsaBillingAddress from '@salesforce/apex/KycDetailsHelper.updateLsaBillingAddress';

export default class KycDetails extends NavigationMixin(LightningElement) {
    @api recordId;

    @track attachmentCounter = 0;
    @track acceptedFileFormats = '.image,.png,.jpeg,.doc,.docx,.txt,.pdf';

    @track isSaveCancelDisabled;
    @track isLoading;

    @track identityDocument;
    @track photoIdDocument;
    @track authorisationLetterDocument;
    @track approval;
    @track billingAddress;
    @track isValidPSADate = true;
    @track isValidGstNo = true;
    @track isGstCorrect = true;
    @track gstValidationInitialized = false;
    @track isValidBillingStreet = true;
    @track isValidIdentityDocument = new KycDocumentValidation(true, true, true, true);
    @track isValidPhotoIdDocument = new KycDocumentValidation(true, true, true, true);
    @track isValidAuthorisationLetterDocument = new KycDocumentValidation(true, true, true, true);

    @track identityDocumentSectionId;
    @track photoIdSectionId;
    @track authorisationLetterSectionId;

    @track detailsSection = {
        i0:{show: false, size: '', name: '', date: '', title: '', singleAttachment: true, fileAmount: true,},
        i1:{show: false, size: '', name: '', date: '', title: '', singleAttachment: true, fileAmount: true,},
        i2:{show: false, size: '', name: '', date: '', title: '', singleAttachment: true, fileAmount: true,},
        i3:{show: false, size: '', name: '', date: '', title: '', singleAttachment: true, fileAmount: true,},
        i4:{show: false, size: '', name: '', date: '', title: '', singleAttachment: true, fileAmount: true,},
        i5:{show: false, size: '', name: '', date: '', title: '', singleAttachment: true, fileAmount: true,},
        i6:{show: false, size: '', name: '', date: '', title: '', singleAttachment: true, fileAmount: true,},
        i7:{show: false, size: '', name: '', date: '', title: '', singleAttachment: true, fileAmount: true,},
        i8:{show: false, size: '', name: '', date: '', title: '', singleAttachment: true, fileAmount: true,}
    }

    isShowSectionDetails = false;
    validatedWithErrorSections = [];
    @track activeSectionFiles = [];
    @track activeSectionName = '';
    @track activeSectionId = '';

    identityDocumentSectionName = 'identityDocumentSection';
    photoIdDocumentSectionName = 'photoIdDocumentSection';
    authorisationLetterDocumentSectionName = 'authorisationLetterDocumentSection';

    LABELS = {
        success: 'Success',
        error: 'Error'
    };

    ERROR_LABELS = {
        emptyFileError: 'File you have uploaded is an empty text file. Please attach another document.'
    };

    get isFormLocked() {
        if (!this.approval?.status) {
            return true;
        }
        let shouldLockForm = true;
        if(['Approved', 'Rejected'].includes(this.approval.status)) {
            shouldLockForm = !window.app.getUserPermissionToEditRequestAfterFinalStep();
        } else if(window.app.getIsUserHasPermissionSetToEditKYCApprovalRequest()) { 
            shouldLockForm = false;
        } else {
            shouldLockForm = window.app.getIsUserHasPermissionSetToReadKYCApprovalRequest();
        }
        return shouldLockForm;
    }
    get isFormGstLocked() {
        return this.isFormLocked || !window.app.isBillingAddressPopulated();
    }

    get participationAgreementFiles() {
        return window.app && Object.assign([], this.detailsSection['i' + window.app.sections.PARTICIPATION_AGREEMENT].files);
    }

    get gstFiles() {
        return window.app && Object.assign([], this.detailsSection['i' + window.app.sections.GST_ATTACHMENT].files);
    }

    get identityAttachmentFiles() {
        return window.app && Object.assign([], this.detailsSection['i' + window.app.sections.IDENTITY_ATTACHMENT].files);
    }

    get photoIdAttachmentFiles() {
        return window.app && Object.assign([], this.detailsSection['i' + window.app.sections.PHOTO_ID_ATTACHMENT].files);
    }

    get AuthorisationLetterAttachmentFiles() {
        return window.app && Object.assign([], this.detailsSection['i' + window.app.sections.AUTHORISATION_LETTER_ATTACHMENT].files);
    }

    connectedCallback() {
        loadScript(this, KycDetailsDependencies + "/NA.js")
            .then(() => {
                this.createApp();
                this.init();
            })
            .catch(error => {
                console.error(error);
            });

        const channelName = "/event/KYC_Approval_Status_Update__e";
        const _this = this;
        subscribe(channelName, -1, (response) => {
            let eventData = response["data"]["payload"];
            if (eventData && eventData["Approval__c"] === _this.recordId) {
                _this.getData({approvalId: _this.recordId});
            }
        }).then(() => {
            console.log("Subscribed to approval status update");
        });

        onError((error) => {
            console.log("Error in approval status update subscription");
            console.log(JSON.stringify(error));
        });
    }

    renderedCallback() {
        Promise.all([
            loadStyle(this, KycDetailsStyles)
        ]);
    }

    createApp() {
        window.app = new App();
    }

    init() {
        this.getData();
        this.initSubscriptions();
        this.setSectionsIds();
    }

    getData() {
        getData({approvalId: this.recordId})
            .then(response => {
                this.checkErrors(response);
                window.app.setData(response);
            })
            .catch(error => {
                if (error.body?.message) {
                    this.showNotification(this.LABELS.error, error.body.message, this.LABELS.error)
                } else {
                    this.showNotification(this.LABELS.error, error.message, this.LABELS.error);
                }
            });
    }

    initSubscriptions() {
        window.app.rx.approval.subscribe(approval=>{
            this.approval = approval;
            this.checkApprovalRequiredFieldsValidity();
            if (!this.gstValidationInitialized) {
                if (approval && approval.gstNo && approval.gstNo.trim() !== '') {
                    this.isGstCorrect = false;
                } else {
                    this.isGstCorrect = true;
                }
                this.gstValidationInitialized = true;
            } 
            
            this.validateButtons();
        });

        window.app.rx.billingAddress.subscribe(address => {
            this.billingAddress = address;
            if (!window.app.isBillingAddressPopulated()) {
                this.resetGstFields();
            }
            this.validateButtons();
        });

        window.app.rx.documents.subscribe(documents => {
            if (documents) {
                this.identityDocument = documents[window.app.documentTypes.IDENTITY_DOCUMENT];
                this.photoIdDocument = documents[window.app.documentTypes.PHOTO_ID];
                this.authorisationLetterDocument = documents[window.app.documentTypes.AUTHORISATION_LETTER];
                this.checkDocumentsRequiredFieldValidity();
                this.validateButtons();
            }
        });

        window.app.rx.isLoading.subscribe(isLoading => {
            this.isLoading = isLoading;
            this.validateButtons();
        });

        window.app.rx.isShowSectionDetails.subscribe(isShowSectionDetails => {
            this.isShowSectionDetails = isShowSectionDetails;
        });

        window.app.rx.files.subscribe(files => {
            if (files) {
                this.attachmentCounter = 0;
                Object.keys(files).forEach(sectionId => {
                    const sectionFiles = files[sectionId].filter(f => !f.isDeleted);
                    const sectionFilesAmount = sectionFiles.length;

                    this.detailsSection['i' + sectionId].show = sectionFilesAmount;
                    this.attachmentCounter += sectionFilesAmount;

                    this.detailsSection['i' + sectionId].files = files[sectionId];
                    this.detailsSection['i' + sectionId].fileAmount = sectionFilesAmount;
                    if (sectionFilesAmount === 1) {
                        this.detailsSection['i' + sectionId].singleAttachment = true;
                        this.detailsSection['i' + sectionId].size = window.app.getFileSize(sectionFiles[0].size);
                        this.detailsSection['i' + sectionId].name = window.app.truncName(sectionFiles[0].name, 25);
                        this.detailsSection['i' + sectionId].title = sectionFiles[0].name;
                        this.detailsSection['i' + sectionId].date = new Date(sectionFiles[0].lastModified).toDateString();
                    } else if (sectionFilesAmount > 1) {
                        this.detailsSection['i' + sectionId].singleAttachment = false;
                    }
                });
                this.activeSectionFiles = this.activeSectionId && [...this.detailsSection[this.activeSectionId].files];
                this.validateButtons();
            }
        });
        window.app.rx.files.subscribe(files => {
            if (!files) {
                return;
            }
            this.cleanDocumentsFields();
            if (window.app.isNoActiveFilesForSection(window.app.sections.GST_ATTACHMENT)) {
                this.updateApprovalFieldValue({'gstNo': null});
                this.setFieldValidity('gstNo', true);
            }
            if (window.app.isNoActiveFilesForSection(window.app.sections.PARTICIPATION_AGREEMENT)) {
                this.updateApprovalFieldValue({'dateOfSign': null});
                this.setFieldValidity('dateOfSign', true);
            }
        });
    }

    setSectionsIds() {
        this.identityDocumentSectionId = window.app.sections.IDENTITY_ATTACHMENT;
        this.photoIdSectionId = window.app.sections.PHOTO_ID_ATTACHMENT;
        this.authorisationLetterSectionId = window.app.sections.AUTHORISATION_LETTER_ATTACHMENT;
    }

    cleanDocumentsFields() {
        Object.keys(window.app.sectionToDocumentTypeMap).forEach(section => {
            this.cleanDocumentFields(section);
        })
    }

    cleanDocumentFields(sectionId) {
        if (window.app.isNoActiveFilesForSection(sectionId)) {
            this.updateDocumentFieldValue(
                {
                    'documentNo': null,
                    'placeOfIssue': null,
                    'dateOfIssue': null,
                    'issuingAuthority': null
                }, 
                sectionId
            );
            this.setDocumentValidity(window.app.sectionToDocumentTypeMap[sectionId], new KycDocumentValidation(true, true, true, true));
        }
    }

    validateButtons() {
        const hasUnsavedChanges = window.app && (
            window.app.isDocumentsHaveUnsavedChanges() ||
            window.app.isApprovalHasUnsavedChanges() ||
            window.app.isFilesChanged() ||
            window.app.isBillingAddressHasUnsavedChanges()
        );
        
        this.isSaveCancelDisabled = !hasUnsavedChanges || this.isLoading || !this.isGstCorrect;
   
    }

    handleGstValidation(event) {
        if (event && event.detail && typeof event.detail.isGstCorrect !== 'undefined') {

            this.isGstCorrect = event.detail.isGstCorrect;
            
            this.validateButtons();
        }
    }

    onCancel() {
        window.app.resetForm();
        this.resetFieldsErrors();
    }

    onSave() {
        window.app.setLoadingStatus(true);
        const fileIds =  window.app.getFilesToDelete();

        if (!this.validateRequiredFields()) {
            window.app.setLoadingStatus(false);
            return;
        }
        this.updateBillingAddress(JSON.stringify(this.billingAddress))
            .then((result) => {
                this.checkErrors(result);
                return this.saveDocuments();
            })
            .then((result) => {
                this.checkErrors(result);
                return this.deleteFiles(fileIds);
            })
            .then((result) => {
                this.checkErrors(result);
                return this.createFiles();
            })
            .then((result) => {
                this.checkErrors(result);
                const params = {
                    approval: {
                        approvalId: this.approval.id,
                        accountId: this.approval.account.Id,
                        gstNo: this.approval.gstNo,
                        gstStateCodeOfCustomer: this.approval.gstStateCodeOfCustomer,
                        dateOfSign: this.approval.dateOfSign,
                        billingState: this.billingAddress.billingState
                    },
                    fileIdsToDelete: fileIds,
                    fileIdsToCreate: result
                };

                return this.updateApproval(params);
            })
            .then((result) => {
                this.checkErrors(result);
                window.location.reload();
            })
            .catch((result) => {
                this.showNotification(this.LABELS.error, result.message, this.LABELS.error);
                window.app.setLoadingStatus(false);
            });
    }

    validateRequiredFields() {
        let result = this.validateBillingStreetLength()
            & this.validateGstNoPopulating()
            & this.validateDateInput()
            & this.validateAuthorisationLetterDocument()
            & this.validatePhotoIdDocument()
            & this.validateIdentityDocument();
        if(!result) {
            this.scrollToSection();
        }
        return result;
    }

    validateGstNoPopulating() {
        if (window.app.isGstNoEmpty()) {
            this.isValidGstNo = false;
            this.openSection('gstSection');
            this.validatedWithErrorSections.push('gstSection');
        } else {
            this.isValidGstNo = true;
        }
        return this.isValidGstNo;
    }

    validateDateInput() {
        if (!window.app.isNoActiveFilesForSection(window.app.sections.PARTICIPATION_AGREEMENT) && !this.approval.dateOfSign) {
            this.openSection('dateOfSignSection');
            this.validatedWithErrorSections.push('dateOfSignSection');
            this.isValidPSADate = false;
        } else {
            this.isValidPSADate = true;
        }
        return this.isValidPSADate;
    }

    validateIdentityDocument() {
        let validateResult = true;
        if (!window.app.isNoActiveFilesForSection(window.app.sections.IDENTITY_ATTACHMENT)
            && this.isValidIdentityDocument
        ) {
            validateResult = this.validateDocument(this.isValidIdentityDocument, this.identityDocument, this.identityDocumentSectionName);
        }
        if(!validateResult) {
            this.validatedWithErrorSections.push('identityDocumentSection');
        }
        return validateResult;
    }

    validatePhotoIdDocument() {
        let validateResult = true;
        if (!window.app.isNoActiveFilesForSection(window.app.sections.PHOTO_ID_ATTACHMENT)
            && this.isValidPhotoIdDocument
        ) {
            validateResult = this.validateDocument(this.isValidPhotoIdDocument, this.photoIdDocument, this.photoIdDocumentSectionName);
        }
        if(!validateResult){
            this.validatedWithErrorSections.push('photoIdDocumentSection');
        }
        return validateResult;
    }

    validateAuthorisationLetterDocument() {
        let validateResult = true;
        if (!window.app.isNoActiveFilesForSection(window.app.sections.AUTHORISATION_LETTER_ATTACHMENT)
            && this.isValidAuthorisationLetterDocument
        ) {
            validateResult = this.validateDocument(this.isValidAuthorisationLetterDocument, this.authorisationLetterDocument, this.authorisationLetterDocumentSectionName);
        }
        if(!validateResult) {
            this.validatedWithErrorSections.push('authorisationLetterDocumentSection');
        }
        return validateResult;
    }

    validateDocument(documentValidator, document, nameOfSection) {
        this.openSection(nameOfSection);
        documentValidator.isDocumentNoValid = Boolean(document.documentNo);
        documentValidator.isPlaceOfIssueValid = Boolean(document.placeOfIssue);
        documentValidator.isDateOfIssueValid = Boolean(document.dateOfIssue);
        documentValidator.isIssuingAuthorityValid = Boolean(document.issuingAuthority);
        if (nameOfSection === this.identityDocumentSectionName) {
            this.isValidIdentityDocument = {...documentValidator};
        } else if (nameOfSection === this.photoIdDocumentSectionName) {
            this.isValidPhotoIdDocument = {...documentValidator};
        } else if (nameOfSection === this.authorisationLetterDocumentSectionName) {
            this.isValidAuthorisationLetterDocument = {...documentValidator};
        }
        return documentValidator.isDocumentNoValid
            && documentValidator.isPlaceOfIssueValid
            && documentValidator.isDateOfIssueValid
            && documentValidator.isIssuingAuthorityValid;
    }

    validateBillingStreetLength() {
        if (window.app.isInvalidBillingStreet()) {
            this.isValidBillingStreet = false;
            this.openSection('billingAddressSection');
            this.validatedWithErrorSections.push('billingAddressSection');
        } else {
            this.isValidBillingStreet = true;
        }
        return this.isValidBillingStreet;
    }

    saveDocuments() {
        const documents = window.app.getChangedDocuments();
        return documents.length
            ? saveDocuments({params: JSON.stringify(documents)})
            : Promise.resolve();
    }

    deleteFiles(fileIds) {
        return fileIds.length
            ? deleteFiles({
                params: JSON.stringify({
                    contentDocumentIdSet: fileIds,
                    approvalId: this.recordId
                })
            })
            : Promise.resolve();
    }

    createFiles() {
        const files =  window.app.getFilesToCreate();
        if (!files.length) {
            return Promise.resolve();
        }

        return new Promise((resolve, reject) => {
            let filesUploadResult = {};

            const doNextUpload = (counter) => {
                const file = files[counter];
                this.loadFileData(file)
                    .then((fileData) => {
                        return this.loadFileToSF(fileData);
                    })
                    .then((resp) => {
                        this.checkErrors(resp);
                        return createFileJunctionObject({file: resp});
                    })
                    .then((resp) => {
                        this.checkErrors(resp);
                        counter++;
                        filesUploadResult[file.sectionId]
                            ? filesUploadResult[file.sectionId].push(resp.data.fileId)
                            : filesUploadResult[file.sectionId] = [resp.data.fileId];

                        if (counter < files.length) {
                            doNextUpload(counter);
                        } else {
                            resolve(filesUploadResult);
                        }
                    })
                    .catch(() => {
                        this.showNotification(this.LABELS.error, this.ERROR_LABELS.emptyFileError, this.LABELS.error);
                        window.app.setLoadingStatus(false);
                    });
            }
            doNextUpload(0);
        });
    }

    loadFileData(file) {
        return new Promise((resolve, reject) => {
            let reader = new FileReader();
            reader.readAsDataURL(file);
            reader.onload = () => {
                let base64 = 'base64,';
                let content = reader.result.indexOf(base64) + base64.length;
                let fileContents = reader.result.substring(content);

                const params = {name: file.name, base64Data: fileContents, parentId: file.parentId};
                resolve(params);
            }
        });
    }

    loadFileToSF(fileData) {
        if (!fileData) {
            return new Promise((reject) => reject());
        }

        const userInfo = window.app.getUserInfo();

        const data = {
            Title: fileData.name,
            PathOnClient: '\\' + fileData.name,
            OwnerId: userInfo.userId,
            VersionData: fileData.base64Data,
        };
        return new Promise((resolve) => {
            fetch('https://' + userInfo.orgHost + '/services/data/v44.0/sobjects/ContentVersion', {
                method: 'POST',
                headers: {
                    'Authorization': 'Bearer ' + userInfo.userSessionId,
                    'Content-Security-Policy' : 'script-src',
                    'Content-Type' : 'application/json'
                },
                body: JSON.stringify(data)
            })
            .then((resp) => {
                this.checkErrors(resp);
                /* fetch() return response with body in ReadableStream format */
                return resp?.text();
            })
            .then((respBody) => {
                const dataJSON = JSON.parse(respBody);
                resolve({
                    status: dataJSON?.success ? this.LABELS.success : this.LABELS.error,
                    cvFileId: dataJSON?.id,
                    entityId: fileData.parentId
                });
            });
        });
    }

    updateApproval(params) {
        return !params.fileIdsToDelete.length && !params.fileIdsToCreate && !window.app.isApprovalHasUnsavedChanges()
            ? Promise.resolve()
            : updateApproval({params: JSON.stringify(params)});
    }

    updateBillingAddress(params) {
        return window.app.isBillingAddressHasUnsavedChanges()
            ? updateLsaBillingAddress({params: params})
            : Promise.resolve();
    }

    handleFileSelection(event) {
        if (event.target.files.length > 0) {
            window.app.setFile(event.target.dataset.id, event.target.files);
            /* To be able to reselect same file */
            event.target.value = '';
        }
    }

    toggle(event) {
        const buttonSelector = '[data-id="' + event.currentTarget.dataset.id + '"]';
        const sectionSelector = '[data-id="' + event.currentTarget.dataset.id + 'Section' + '"]';
        this.template.querySelector(buttonSelector).classList.toggle('slds-is-open');
        this.template.querySelector(sectionSelector).classList.toggle('slds-is-open');
    }

    onViewAllClicked(event) {
        event.stopPropagation();
        this.activeSectionId = event.target.dataset.id;
        this.activeSectionFiles = this.detailsSection[this.activeSectionId].files;
        this.activeSectionName = window.app.sectionIdToSectionNameMap[this.activeSectionId.substring(1)];
        window.app.toggleSectionDetails();
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

    getFileSize(bytes) {
        if (bytes == 0) {
            return '0 Byte';
        }
        const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
        let i = parseInt(Math.floor(Math.log(bytes) / Math.log(1024)));
        return Math.round(bytes / Math.pow(1024, i), 2) + ' ' + sizes[i];
    }

    showNotification(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }

    updateApprovalFieldValue(fields) {
        let updatedAppr = this.updateObjectFieldValue(fields, this.approval);
        if (updatedAppr) {
            window.app.updateApproval(updatedAppr);
        }
    }

    updateDocumentFieldValue(fields, section) {
        let updatedDocument;
        if (section === window.app.sections.IDENTITY_ATTACHMENT) {
            updatedDocument = this.updateObjectFieldValue(fields, this.identityDocument);
        } else if (section === window.app.sections.PHOTO_ID_ATTACHMENT) {
            updatedDocument = this.updateObjectFieldValue(fields, this.photoIdDocument);
        } else if (section === window.app.sections.AUTHORISATION_LETTER_ATTACHMENT) {
            updatedDocument = this.updateObjectFieldValue(fields, this.authorisationLetterDocument);
        }
        if (updatedDocument) {
            window.app.setDocument(updatedDocument);
        }
    }

    updateBillingAddressFieldValue(fields) {
        let updatedAcc = this.updateObjectFieldValue(fields, this.billingAddress);
        if (updatedAcc) {
            window.app.updateBillingAddress(updatedAcc);
        }
    }

    updateObjectFieldValue(fields, obj) {
        if (!fields) {
            return;
        }
        let newObj = {...obj};
        Object.keys(fields).forEach(field => {
            newObj[field] = fields[field];
        })
        return newObj;
    }

    openSection(dataId) {
        const section = this.getElementById(dataId);
        if (!section.classList.contains('slds-is-open')) {
            section.classList.toggle('slds-is-open');
        }
    }

    scrollToSection() {
        const section = this.getElementById(this.validatedWithErrorSections[this.validatedWithErrorSections.length - 1]);
        section.scrollIntoView({
            block: 'center',
            behavior: 'smooth'
        });
    }

    getElementById(dataId) {
        const elementSelector = '[data-id="' + dataId + '"]';
        return this.template.querySelector(elementSelector);
    }

    checkApprovalRequiredFieldsValidity() {
        this.checkRequiredFieldValidity('gstNo', this.isValidGstNo, window.app.sections.GST_ATTACHMENT);
        this.checkRequiredFieldValidity('dateOfSign', this.isValidPSADate, window.app.sections.PARTICIPATION_AGREEMENT);
    }

    checkDocumentsRequiredFieldValidity() {
        this.checkDocumentRequiredFieldValidity(this.identityDocumentSectionName);
        this.checkDocumentRequiredFieldValidity(this.photoIdDocumentSectionName);
        this.checkDocumentRequiredFieldValidity(this.authorisationLetterDocumentSectionName);
    }

    checkRequiredFieldValidity(fieldName, isValid, filesSectionId) {
        if (window.app?.isApprovalFieldChanged(fieldName)) {
            if (!isValid && this.approval[fieldName]) {
                this.setFieldValidity(fieldName, true);
            }/* When user remove Gst No from active Gst section with uploaded file */
            else if (isValid
                && !this.approval[fieldName]
                && !window.app.isNoActiveFilesForSection(filesSectionId)) {
                this.setFieldValidity(fieldName, false);
            }
        }
    }

    checkDocumentRequiredFieldValidity(sectionName) {
        if (sectionName === this.authorisationLetterDocumentSectionName) {
            this.validateAuthorisationLetterDocument();
        }
        if (sectionName === this.photoIdDocumentSectionName) {
            this.validatePhotoIdDocument();
        }
        if (sectionName === this.identityDocumentSectionName) {
            this.validateIdentityDocument();
        }
    }

    setFieldValidity(field, value) {
        switch (field) {
            case 'gstNo': this.isValidGstNo = value;
            case 'dateOfSign': this.isValidPSADate = value;
        }
    }

    setDocumentValidity(document, value) {
        switch (document) {
            case window.app.documentTypes.IDENTITY_DOCUMENT: 
                this.isValidIdentityDocument = value;
            case window.app.documentTypes.PHOTO_ID:
                this.isValidPhotoIdDocument = value;
            case window.app.documentTypes.AUTHORISATION_LETTER:
                this.isValidAuthorisationLetterDocument = value;
            }
    }

    resetFieldsErrors() {
        this.isValidGstNo = true;
        this.isValidPSADate = true;
    }

    resetGstFields() {
        window.app.deleteFilesForSection(window.app.sections.GST_ATTACHMENT);
        this.updateApprovalFieldValue({
            'gstNo': null,
            'gstStateCodeOfCustomer': null
        });
    }

    checkErrors(result) {
        if (result?.status === this.LABELS.error.toLowerCase()) {
            this.throwError(result);
        }
    }

    throwError(result) {
        if (result) {
            throw new KycDetailsError(result);
        }
    }
}