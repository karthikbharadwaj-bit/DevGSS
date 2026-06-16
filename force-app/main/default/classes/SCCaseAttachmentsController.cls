global with sharing class SCCaseAttachmentsController {

    private static final Integer BYTE_TO_MB_RATIO = 1024 * 1024;

    global String uploadStatus {get;set;}

    global Integer attachmentStorageLimit {get;set;}
    global Integer attachmentSizeLimit {get;set;}

    global Integer attachmentSize {get;set;}
    global String attachmentName {get;set;}
    global Blob attachmentBody {get;set;}

    global SCCaseAttachmentsController(ApexPages.StandardController controller) {
        this.uploadStatus = 'none';
        this.attachmentStorageLimit = SCCaseService.STORAGE_LIMIT / BYTE_TO_MB_RATIO;
        this.attachmentSizeLimit = SCCaseService.FILE_SIZE_LIMIT / BYTE_TO_MB_RATIO;
    }

    global PageReference attachFile() {

        try {
            String caseId = ApexPages.currentPage().getParameters().get('id');

            Attachment attachment = new Attachment(
                Name = attachmentName,
                Body = attachmentBody
            );
            if (attachmentSize < SCCaseService.FILE_SIZE_LIMIT
                    && attachmentSize < SCCaseService.getAttachmentStorageSpaceLeft(caseId)) {
                SCCaseService.addAttachment(caseId, attachment);
                this.uploadStatus = 'success';
            } else {
                this.uploadStatus = 'limitExceeded';
            }
        } catch (Exception ex) {
            this.uploadStatus = 'error';
        }
        this.attachmentBody = null;
        return null;
    }
}