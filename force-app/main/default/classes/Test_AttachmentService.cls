@isTest
private class Test_AttachmentService {

    private static final String FILE_TITLE = 'Title';
    private static final String FILE_DESCRIPTION = 'Desc';

    @isTest
    static void testGetAttachmentDownloadLink() {

        String fileUrl = AttachmentService.getAttachmentDownloadLink('attId');
        System.assertEquals(
            System.Url.getOrgDomainUrl().toExternalForm() + AttachmentService.ATTACHMENT_DOWNLOAD_URL_TEMPLATE + 'attId',
            fileUrl,
            'Received incorrent link'
        );
    }

    @isTest
    static void testGetAttachmentDownloadLink_blankId_shouldReturnNull() {

        String fileUrl = AttachmentService.getAttachmentDownloadLink('');
        System.assert(null == fileUrl, 'Received link for blank Id');
    }

}