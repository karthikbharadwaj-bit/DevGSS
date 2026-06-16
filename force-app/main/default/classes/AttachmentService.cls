public with sharing class AttachmentService {

    private without sharing class NoSharing {
        public Boolean isSandbox = 
            ((Organization) new OrganizationSelector().selectOrg().setQueryCaching(true).executeQuery()[0]).isSandbox;
    }

    public static final String ATTACHMENT_DOWNLOAD_URL_TEMPLATE = 
        (new NoSharing().isSandbox ? '/support' : '') + '/servlet/servlet.FileDownload?file=';
    
    private static String domainUrl {
        get {
            if (domainUrl == null) {
                domainUrl = URL.getOrgDomainUrl().toExternalForm();
            }
            return domainUrl;
        }
        private set;
    }

    public static String getAttachmentDownloadLink(String attachmentId) {

        if (String.isBlank(attachmentId)) {
            return null;
        }
        return domainUrl + ATTACHMENT_DOWNLOAD_URL_TEMPLATE + attachmentId;
    }
}