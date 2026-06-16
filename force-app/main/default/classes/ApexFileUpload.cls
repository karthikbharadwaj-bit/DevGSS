/*
 * @class ApexFileUpload
 * @desc Lets you uplaod a file in Salesforce by giving a base64 string of the
 *   file, a name for the file, and the Id of the record that you want to attach 
 *   the file to. 
 *
 * @example:
 *   ApexFileUpload.uploadFile(myBase64String, 'Invoice.pdf', '906F0000000kG2UIAU')
 */
public with sharing class ApexFileUpload {

    /*
     * @method uploadFile() 
     * @desc Creates a content version from a given file's base64 and name
     * 
     * @param {String} file - string that represents the file
     * @param {String} filename - full file name with extension, i.e. 'Invoice.pdf'
     * @param {String} recordId - Id of the record you want to attach this file to
     * 
     * @return {ContentVersion} - returns the created ContentDocumentLink Id if the
     *   upload was successful, otherwise returns null
     */
    public static String uploadFile(String file, String filename, String recordId) {
        ContentVersion cv = createContentVersion(file, filename);
        if(cv == null) {
            return null;
        }
        ContentDocumentLink cdl = createContentLink(cv.Id, recordId);
        if (cdl == null) { 
            return null; 
        }
        return cdl.Id;
    }
    
    /*
     * @method createContentVersion() [private]
     * @desc Creates a content version from a given file's base64 and name
     * 
     * @param {String} file - string that represents the file
     * @param {String} filename - full file name with extension, i.e. 'Invoice.pdf'
     * 
     * @return {ContentVersion} - returns the newly created ContentVersion, or null
     *   if there was an error inserting the record
     */
    private static ContentVersion createContentVersion(String file, String filename) {
        ContentVersion cv = new ContentVersion();
        cv.VersionData = Blob.valueOf(file);
        cv.Title = filename;
        cv.PathOnClient = filename;
        try {
            insert cv;
            return cv;
        } catch(DMLException e) {
            System.debug('ContentVersion Error=====>' + e.getMessage());
            return null;
        }
    }
      
    /*
     * @method createContentLink() [private]
     * @desc Creates a content link for a given ContentVersion and record
     * 
     * @param {String} contentVersionId - Id of the ContentVersion of the file
     * @param {String} recordId - Id of the record you want to attach this file to
     * 
     * @return {ContentDocumentLink} - returns the newly created ContentDocumentLink, 
     *   or null if there was an error inserting the record
     */
    private static ContentDocumentLink createContentLink(String contentVersionId, String recordId) {
        if (contentVersionId == null || recordId == null) { return null; }
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            WHERE Id =: contentVersionId
        ].ContentDocumentId;
        cdl.LinkedEntityId = recordId;
        // ShareType is either 'V', 'C', or 'I'
        // V = Viewer, C = Collaborator, I = Inferred
        cdl.ShareType = 'V';
        try {
            insert cdl;
            return cdl;
        } catch(DMLException e) {
            System.debug(e);
            return null;
        }
    }
    
    
    /*
     * @method getContentType() [public]
     * @desc returns file content type based on file extension
     * 
     * @param {String} fileType
     * 
     * @return {String} 
     */
    public static string getContentType(string fileType)
    {
        switch on fileType.toLowerCase()
        {
            when 'docx'
            {
                return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
            }
            when 'csv'
            {
                return 'text/csv';
            }
            when 'txt'
            {
                return 'text/plain';
            }
            when 'json'
            {
                return 'application/json';
            }
            when 'wav'
            {
                return 'audio/wav';
            }
            when 'wmv'
            {
                return 'video/x-ms-wmv';
            }
            when 'mp3'
            {
                return 'audio/mpeg';
            }
            when 'mp4'
            {
                return 'video/mp4';
            }
            when 'png'
            {
                return 'image/png';
            }
            when 'pdf'
            {
                return 'application/pdf';   
            }
            when else {
                return 'text/plain';
            }
        }
    }
}