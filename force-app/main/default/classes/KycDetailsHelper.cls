public with sharing class KycDetailsHelper {
    
    public class KycDetailsHelperException extends Exception {}

    public static final String UNEXPECTED_ERROR_GST_VALIDATION = 'An unexpected error occurred during GST validation:';

    public static final Integer COUNT_OF_SECTIONS = 9;
    /* See kycDetails App sections */
    public static final Integer IDENTITY_ATTACHMENT_SECTION = 0;
    public static final Integer PHOTO_ID_ATTACHMENT_SECTION = 1;
    public static final Integer AUTHORISATION_LETTER_ATTACHMENT_SECTION = 2;
    public static final Integer PARTICIPATION_AGREEMENT_SECTION = 3;
    public static final Integer GST_ATTACHMENT_SECTION = 4;
    public static final Integer SEZ_ATTACHMENT_SECTION = 5;
    public static final Integer GIR_ATTACHMENT_SECTION = 6;
    public static final Integer ADDRESS_SIGNATORY_ATTACHMENT_SECTION = 7;
    public static final Integer PASSPORT_SIGNATORY_ATTACHMENT_SECTION = 8;

    public static final List<Integer> sectionIdsList = new List<Integer> {
        IDENTITY_ATTACHMENT_SECTION,
        PHOTO_ID_ATTACHMENT_SECTION,
        AUTHORISATION_LETTER_ATTACHMENT_SECTION,
        PARTICIPATION_AGREEMENT_SECTION,
        GST_ATTACHMENT_SECTION,
        SEZ_ATTACHMENT_SECTION,
        GIR_ATTACHMENT_SECTION,
        ADDRESS_SIGNATORY_ATTACHMENT_SECTION,
        PASSPORT_SIGNATORY_ATTACHMENT_SECTION
    };

    public static final Map<Integer,String> sectionIdToSectionNameMap = new Map<Integer,String> {
        IDENTITY_ATTACHMENT_SECTION => 'Identity document of company',
        PHOTO_ID_ATTACHMENT_SECTION => 'Photo ID Proof Type of Authorised Signatory',
        AUTHORISATION_LETTER_ATTACHMENT_SECTION => 'Authorisation Letter for Authorised Signatory',
        PARTICIPATION_AGREEMENT_SECTION => 'Signed off Participation Agreement',
        GST_ATTACHMENT_SECTION => 'GST No. & Certificate',
        SEZ_ATTACHMENT_SECTION => 'Exemption/SEZ Certificate Number & Certificate',
        GIR_ATTACHMENT_SECTION => 'PAN/GIR No.',
        ADDRESS_SIGNATORY_ATTACHMENT_SECTION => 'Address of the Authorised Signatory',
        PASSPORT_SIGNATORY_ATTACHMENT_SECTION => 'Passport of the Authorised Signatory'
    };

    public static final String KYC_APPROVAL_READ_PERMISSION_SET_NAME = 'KYC Approval Read';
    public static final String KYC_APPROVAL_EDIT_PERMISSION_SET_NAME = 'KYC Approval Edit';
    /* For India Office account billing address is edited through KYC Approval
    * and address synced from approval (it's stored in Local Subscribed Address system record) to account after KYC is approved.
    * However billing address on India Office account can't be edited by sales
    * so @accountsForBillingAddressSync is a static storage for accounts which have this permission to edit while syncing */
    private static Set<Id> accountsForBillingAddressSync = new Set<Id>();

    @AuraEnabled
    public static Response getData(Id approvalId) {
        Response resp = new Response();

        try {
            if (approvalId != null) {
                List<Approval__c> approvalList = new ApprovalSelector()
                    .selectKYCRequestApprovalForNotesAttachmentsById(new List<Object>{new Set<Id>{approvalId}})
                    .executeQuery();
                /* Approval */
                Approval__c record = !approvalList.isEmpty() ? approvalList[0] : null;
                /* Files of approval and of its documents */
                List<FileWrapper> files = getFiles(record);
                /* Billing Address data stored in LSA */
                LocalSubscribedAddress__c lsaBillingAddress = (LocalSubscribedAddress__c) new LocalSubscribedAddressSelector()
                    .selectLocalSubscribedAddressesBillingAddressByApprovals(new List<Object>{new Set<Id>{record.Id}})
                    .executeQuery()
                    .get(0);

                resp.setData('approval', record);
                resp.setData('billingAddress', lsaBillingAddress);
                resp.setData('files', JSON.serialize(files));
                resp.setData('isUserCanEditRequestAfterFinalStep',
                    isUserProfileHasPermissionToEditKYCRequestAfterFinalAction());
                resp.setData('isUserHasPermissionSetToEditKYCApprovalRequest',
                isUserHasPermissionSetToEditKYCApprovalRequest());
                resp.setData('isUserHasPermissionSetToReadKYCApprovalRequest',
                    isUserHasPermissionSetToReadKYCApprovalRequest());
                resp.setData('userId', UserInfo.getUserId());
                resp.setData('userSessionId', UserSessionController.fetchUserSessionId());
                resp.setData('orgHost', System.Url.getOrgDomainUrl().getHost());
            }
        } catch (Exception e) {
            resp.error(e);
        }

        return resp;
    }

    public static List<FileWrapper> getFiles(Approval__c record) {
        List<FileWrapper> result = new List<FileWrapper>();
        if (record == null) {
            return result;
        }

        List<String> sections = !String.isBlank(record.KycFiles__c)
            ? record.KycFiles__c.split(';')
            : new List<String>();

        Set<String> contentDocumentIdSet = new Set<String>();
        for (String section : sections) {
            List<String> sectionFiles = section.split(',');
            contentDocumentIdSet.addAll(sectionFiles);
        }

        List<ContentVersion> cvList = new ContentVersionSelector()
            .selectContentVersionByContentDocumentId(new List<Object>{contentDocumentIdSet})
            .executeQuery();

        Map<Id,ContentVersion> cdIdToLastContentVersionMap = new Map<Id,ContentVersion>();
        for (ContentVersion item : cvList) {
            if (!cdIdToLastContentVersionMap.containsKey(item.ContentDocumentId) ||
                cdIdToLastContentVersionMap.get(item.ContentDocumentId).LastModifiedDate < item.LastModifiedDate) {

                cdIdToLastContentVersionMap.put(item.ContentDocumentId, item);
            }
        }

        List<ContentDocumentLink> cdlList = new ContentDocumentLinkSelector()
            .selectLinksByLinkedEntityAndDocumentId(new List<Object>{contentDocumentIdSet, getParentIdSet(record)})
            .executeQuery();

        for (ContentDocumentLink cdl : cdlList) {
            ContentVersion cv = cdIdToLastContentVersionMap.get(cdl.ContentDocumentId);
            FileWrapper fw = new FileWrapper(cv, cdl);
            result.add(fw);
        }

        return result;
    }

    public static Set<Id> getParentIdSet(Approval__c app) {
        Set<Id> result = new Set<Id>();
        if (app != null) {
            result.add(app.Id);
            Map<Id, Document__c> docMap = new Map<Id, Document__c>(app.Documents__r);
            result.addAll(docMap.keySet());
        }
        return result;
    }

    @AuraEnabled
    public static Response saveDocuments(String params) {
        Response resp = new Response();
        List<Document__c> docList = new List<Document__c>();

        List<DocumentsWrapper> docListWrapper = (List<DocumentsWrapper>) JSON.deserialize(params, List<DocumentsWrapper>.class);
        for (DocumentsWrapper item : docListWrapper) {
            Document__c doc = new Document__c(
                Id = item.id,
                Approval__c = item.approvalId,
                DateOfIssue__c = item.dateOfIssue,
                DocumentNo__c = item.documentNo,
                IssuingAuthority__c = item.issuingAuthority,
                PlaceOfIssue__c = item.placeOfIssue,
                Type__c = item.type
            );
            docList.add(doc);
        }
        try {
            update docList;
        } catch (Exception e) {
            resp.error(e);
        }

        return resp;
    }

    @AuraEnabled
    public static Response deleteFiles(String params) {
        Response resp = new Response();
        FileToDeleteWrapper deleteWrapper = (FileToDeleteWrapper) JSON.deserialize(params, FileToDeleteWrapper.class);

        if (deleteWrapper.approvalId == null) {
            return resp;
        }

        try {
            List<Approval__c> approvalList = new ApprovalSelector()
                .selectKYCRequestApprovalForNotesAttachmentsById(new List<Object>{new Set<Id>{deleteWrapper.approvalId}})
                .executeQuery();

            if (approvalList.isEmpty()) {
                return resp;
            }

            deleteContentDocuments(deleteWrapper, approvalList);
        } catch (Exception e) {
            resp.error(e);
        }

        return resp;
    }

    @AuraEnabled
    public static Response createContentDocumentLink(Map<String, Object> file) {
        Response resp = new Response();

        String fileJson = JSON.serialize(file);
        FileToCreateWrapper f = (FileToCreateWrapper) JSON.deserialize(fileJson, FileToCreateWrapper.class);

        try {
            List<ContentVersion> cv = new ContentVersionSelector()
                .selectContentVersionById(new List<Object>{new Set<Id>{f.cvFileId}})
                .executeQuery();

            ContentDocumentLink cl = new ContentDocumentLink(
                ContentDocumentId = cv[0].ContentDocumentId,
                LinkedEntityId = f.entityId,
                ShareType = 'I',
                Visibility = 'AllUsers'
            );
            insert cl;

            resp.setData('fileId', cv[0].ContentDocumentId);
        } catch (Exception e) {
            resp.error(e);
        }

        return resp;
    }

    @AuraEnabled
    public static Response updateApproval(String params) {
        Response resp = new Response();

        UpdateApprovalWrapper wrapper = (UpdateApprovalWrapper) JSON.deserialize(params, UpdateApprovalWrapper.class);
        if (wrapper.approval.approvalId == null) {
            return resp;
        }
        try {
            List<Approval__c> approvalList = new ApprovalSelector()
                .selectKYCRequestApprovalForNotesAttachmentsById(new List<Object>{
                    new Set<Id>{wrapper.approval.approvalId}})
                .executeQuery();
            Approval__c record = !approvalList.isEmpty() ? approvalList[0] : null;
            String newKycFiles = String.join(prepareNewSectionsForKycFiles(wrapper, record), ';');
            update new Approval__c(
                Id = wrapper.approval.approvalId,
                KycFiles__c = newKycFiles,
                GstNo__c = wrapper.approval.gstNo,
                GstStateCodeOfCustomer__c = wrapper.approval.gstStateCodeOfCustomer,
                DateOfSignOff__c = wrapper.approval.dateOfSign,
                GstStateNameOfCustomer__c = wrapper.approval.billingState
            );
        } catch (Exception e) {
            resp.error(e);
        }

        return resp;
    }

    @AuraEnabled
    public static Response updateLsaBillingAddress(String params) {
        Response resp = new Response();
        BillingAddressWrapper billingAddressWrapper = (BillingAddressWrapper) JSON.deserialize(params, BillingAddressWrapper.class);
        LocalSubscribedAddress__c lsa = billingAddressWrapper.getLsaBillingAddress();
        try {
            if (lsa.Id != null) {
                update lsa;
            }
        } catch (Exception e) {
            resp.error(e);
        }

        return resp;
    }

    private class BillingAddressWrapper {
        public String id;
        public String billingStreet;
        public String billingCity;
        public String billingState;
        public String billingCountry;
        public String billingPostalCode;

        public LocalSubscribedAddress__c getLsaBillingAddress() {
            return new LocalSubscribedAddress__c(
                Id = this.Id,
                StreetAddress__c = this.billingStreet,
                City__c = this.billingCity,
                State__c = this.billingState,
                District__c = this.billingCountry,
                PinCode__c = this.billingPostalCode
            );
        }
    }

    @AuraEnabled
    public static Response validateBillingState(String params) {
        ApprovalWrapper wrapper = (ApprovalWrapper) JSON.deserialize(params, ApprovalWrapper.class);
        String gstNo2Symbols = wrapper.gstNo?.left(2);
        String billingState = wrapper.billingState;
        Response resp = new Response();

        if (String.isBlank(billingState)) {
            resp.setData('isValidState', true);
            resp.setData('isValidGstNoForState', true);
            return resp;
        }
        try {
            List<BillingWrappers.CountryStates> statesList = getStates('IND');

            Boolean isPopulatedGstNo = !String.isBlank(gstNo2Symbols);
            Boolean isValidState = false;
            Boolean isValidGstNoForState = !isPopulatedGstNo;

            for (BillingWrappers.CountryStates state : statesList) {
                if (isValidBillingState(billingState, state)) {
                    isValidState = true;
                    resp.setData('stateName', state.stateName);
                    resp.setData('primaryTaxCode', state.primaryTaxCode);
                }
                if (isPopulatedGstNo && (gstNo2Symbols == state.primaryTaxCode || gstNo2Symbols == state.alternateTaxCode)) {
                    resp.setData('alpha2Code', state.alpha2Code);
                    isValidGstNoForState = isValidBillingState(billingState, state);
                }
                if (isValidState && isValidGstNoForState) {
                    break;
                }
            }
            resp.setData('isValidState', isValidState);
            resp.setData('isValidGstNoForState', isValidGstNoForState);
        } catch (Exception e) {
            resp.error(e);
        }

        return resp;
    }

    public static List<BillingWrappers.CountryStates> getStates(String countryCode) {
        String endpoint = String.format(NGBSAPI.NGBS_STATES, new List<String> {countryCode});
        String responseBody = NGBSAPI.requestNGBS(endpoint, HttpHelper.METHOD_GET).getBody();
        List<BillingWrappers.CountryStates> statesList = (List<BillingWrappers.CountryStates>)
            JSON.deserialize(responseBody, List<BillingWrappers.CountryStates>.class);
        return statesList;
    }

    @TestVisible
    private static Boolean isValidBillingState(String billingState, BillingWrappers.CountryStates state) {
        return billingState == state.stateName || billingState == state.alpha2Code;
    }

    private static List<String> getListOfEmptyStringsByCountOfSections() {
        List<String> listEmptyStrings = new List<String>();
        for (Integer i = 0; i < COUNT_OF_SECTIONS; i++) {
            listEmptyStrings.add('');
        }
        return listEmptyStrings;
    }

    @AuraEnabled
    public static Boolean isUserProfileHasPermissionToEditKYCRequestAfterFinalAction() {
        Id userProfileId = UserInfo.getProfileId();
        return ProfileHelper.isSysAdmin(userProfileId) || ProfileHelper.isCrmProfile(userProfileId);
    }

    @AuraEnabled
    public static Boolean isUserHasPermissionSetToEditKYCApprovalRequest() {
        List<PermissionSetAssignment> permissionSetAssignmentList = 
            (List<PermissionSetAssignment>) new PermissionSetAssignmentSelector()
                .selectPSABasedOnAssigneeAndLabel(new List<Object>{UserInfo.getUserId(), KYC_APPROVAL_EDIT_PERMISSION_SET_NAME})
                .executeQuery();
        return !permissionSetAssignmentList.isEmpty();
    }

    @AuraEnabled
    public static Boolean isUserHasPermissionSetToReadKYCApprovalRequest() {
        List<PermissionSetAssignment> permissionSetAssignmentList = 
            (List<PermissionSetAssignment>) new PermissionSetAssignmentSelector()
                .selectPSABasedOnAssigneeAndLabel(new List<Object>{UserInfo.getUserId(), KYC_APPROVAL_READ_PERMISSION_SET_NAME})
                .executeQuery();
        return !permissionSetAssignmentList.isEmpty();
    }

    public class FileToCreateWrapper {
        public String cvFileId;
        public String entityId;
    }

    public class FileToDeleteWrapper {
        public Set<Id> contentDocumentIdSet;
        public Id approvalId;
    }

    public class UpdateApprovalWrapper {
        public ApprovalWrapper approval;
        public List<String> fileIdsToDelete;
        public Map<String,List<String>> fileIdsToCreate;

        @TestVisible
        public UpdateApprovalWrapper(ApprovalWrapper approval, List<String> fileIdsToDelete, Map<String,List<String>> fileIdsToCreate) {
            this.approval = approval;
            this.fileIdsToDelete = fileIdsToDelete;
            this.fileIdsToCreate = fileIdsToCreate;
        }
    }

    public class FileWrapper {
        public String id;
        public String pathOnClient;
        public String title;
        public Integer contentSize;
        public String contentDocumentId;
        public String contentUrl;
        public String fileType;
        public DateTime lastModifiedDate;
        public String parentId;
        public String latestPublishedVersionId;

        public FileWrapper(ContentVersion cv, ContentDocumentLink cdl) {
            this.id = cv.Id;
            this.pathOnClient = cv.PathOnClient;
            this.title = cv.Title;
            this.contentSize = cv.ContentSize;
            this.contentDocumentId = cv.ContentDocumentId;
            this.contentUrl = cv.ContentUrl;
            this.fileType = cv.FileType;
            this.lastModifiedDate = cv.LastModifiedDate;
            this.parentId = cdl.LinkedEntityId;
            this.latestPublishedVersionId = cdl.ContentDocument.LatestPublishedVersionId;
        }
    }

    public class DocumentsWrapper {
        public Id id;
        public Id approvalId;
        public Date dateOfIssue;
        public String documentNo;
        public String issuingAuthority;
        public String placeOfIssue;
        public String type;

        @TestVisible
        public DocumentsWrapper(Id id, Id approvalId, Date dateOfIssue, String documentNo, String issuingAuthority, String placeOfIssue, String type) {
            this.id = id;
            this.approvalId = approvalId;
            this.dateOfIssue = dateOfIssue;
            this.documentNo = documentNo;
            this.issuingAuthority = issuingAuthority;
            this.placeOfIssue = placeOfIssue;
            this.type = type;
        }
    }

    public class ApprovalWrapper {
        public String approvalId;
        public String accountId;
        public String gstNo;
        public Date dateOfSign;
        public String gstStateCodeOfCustomer;
        public String billingState;

        @TestVisible
        public ApprovalWrapper(String approvalId) {
            this.approvalId = approvalId;
        }
    }

    public static void setAccountsForBillingAddressSync(Set<Id> accIds) {
        if (accIds != null) {
            accountsForBillingAddressSync = new Set<Id>(accIds);
        }
    }

    public static Boolean canEditBillingAddressOnAccount(Id accId) {
        return accountsForBillingAddressSync.contains(accId);
    }

    public static List<String> prepareNewSectionsForKycFiles(UpdateApprovalWrapper wrapper, Approval__c record) {
        List<String> newSections = new List<String>();

        List<String> sections = !String.isBlank(record.KycFiles__c)
            ? record.KycFiles__c.split(';', -1)
            : getListOfEmptyStringsByCountOfSections();
        for (Integer i = 0; i < sections.size(); i++) {
            List<String> sectionFiles = sections[i].split(',');
            List<String> newSection = new List<String>();

            for (String fileId : sectionFiles) {
                if (!wrapper.fileIdsToDelete.contains(fileId)) {
                    newSection.add(fileId);
                }
            }

            if (wrapper.fileIdsToCreate?.get(String.valueOf(i)) != null) {
                newSection.addAll(wrapper.fileIdsToCreate.get(String.valueOf(i)));
            }

            newSections.add(String.join(newSection, ','));
        }

        return newSections;
    }

    public static void deleteContentDocuments(FileToDeleteWrapper deleteWrapper, List<Approval__c> approvalList) {
        /* Collect all existing document links for documents */
        List<ContentDocumentLink> cdlList = new ContentDocumentLinkSelector()
            .selectLinksByDocumentId(new List<Object>{deleteWrapper.contentDocumentIdSet})
            .executeQuery();

        Map<Id, List<ContentDocumentLink>> cdIdToCdlListMap = new Map<Id, List<ContentDocumentLink>>();
        for (ContentDocumentLink cdl : cdlList) {
            if (!cdIdToCdlListMap.containsKey(cdl.ContentDocumentId)) {
                cdIdToCdlListMap.put(cdl.ContentDocumentId, new List<ContentDocumentLink>());
            }
            cdIdToCdlListMap.get(cdl.ContentDocumentId).add(cdl);
        }

        List<ContentDocumentLink> cdlToDelete = new List<ContentDocumentLink>();
        List<ContentDocument> cdToDelete = new List<ContentDocument>();

        Set<Id> linkedEntityIdSet = getParentIdSet(approvalList[0]);
        for (Id cdId : cdIdToCdlListMap.keyset()) {
            /* When document relates to more than 1 entity - only document link should be removed */
            if (cdIdToCdlListMap.get(cdId).size() > 2) {
                for (ContentDocumentLink cdl : cdIdToCdlListMap.get(cdId)) {
                    if (linkedEntityIdSet.contains(cdl.LinkedEntityId)) {
                        cdlToDelete.add(cdl);
                    }
                }
            } else {
                /* When document relates to only user entity the document itself should be deleted */
                cdToDelete.add(new ContentDocument(Id = cdId));
            }
        }

        if (!cdlToDelete.isEmpty()) {
            delete cdlToDelete;
        }

        if (!cdToDelete.isEmpty()) {
            delete cdToDelete;
        }
    }
    
    @AuraEnabled
    public static Boolean validateGstNumber(String gstNo) {
        Boolean isValidGst = false;
        try {
            String endPointUrl = 'callout:DeloitteBoultOnGSTValidation/gstn/validate/' + EncodingUtil.urlEncode(gstNo, 'UTF-8');
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endPointUrl);
            req.setMethod('GET');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Authorization', 'Bearer ' + '{!$credential.Password}');
            Http http = new Http();
            HttpResponse response = http.send(req);
            if (response.getStatusCode() == 200) {
                Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                String statusCd = (String)responseData.get('status_cd');
                if(statusCd == '1'){
                    string gstnStatus = (String)responseData.get('GstnStatus');
                    if(gstnStatus == 'Active'){
                        isValidGst = true;
                    }
                }
            }
        } catch (Exception e) {
            throw new KycDetailsHelperException(UNEXPECTED_ERROR_GST_VALIDATION + ' ' + e.getMessage());
        }
        
        return isValidGst;
    }
}