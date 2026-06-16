global with sharing class CLMDocumentRequest {
    
    global CLMDocumentRequest(string documentId,string documentPath, SpringCMService svc, string apiURL)
    {
        pid = documentId;
        ppath = documentPath;
        scmsvc = svc;
        aURL = apiURL;

        System.debug(apiURL);
    }

    global CLMDocumentRequest(CLMDocument document, SpringCMService svc)
    {   
        this.pdocument = document;
        this.pid = svc.getIDfromHref(document.Href);
        scmsvc = svc;

    }

        private string pid;
        private string ppath;
        private SpringCMService scmsvc;
        private string pdc;
        private string pav;
        private string aURL;
        private CLMDocument pdocument;
        private Boolean pexpandParentFolder;
        private Boolean pexpandDocuments;
        private Boolean pexpandFolders;
        private Boolean pexpandPath;
        private Boolean pexpandEosParentInfo;
        private Boolean pexpandEosInfo;
        private Boolean pexpandShareLinks;
        private Boolean pexpandAttributeGroups;
        private Boolean pexpandSecurity;
        private Boolean pexpandVersions;
        private Boolean pexpandLock;
        private Boolean pexpandDocumentProcessTrackingActivities;
        private Boolean pexpandHistoryItems;

        global Boolean getExpandParentFolder() {    
            return pexpandParentFolder;
        } 

        global void setExpandParentFolder(Boolean value) { 
            if (pexpandParentFolder != value) {
                pdocument = null; 
            } 
            pexpandParentFolder = value; 
        } 

         global Boolean getExpandPath() { return pexpandPath;}

         global void setExpandPath(Boolean value) {
            if (pexpandPath != value) {
                pdocument = null; 
            } 

            pexpandPath = value; 
        } 


         global Boolean getExpandEosParentInfo() { return pexpandEosParentInfo;}
         global void setExpandEosParentInfo(Boolean value) { if (pexpandEosParentInfo != value) { pdocument = null; } pexpandEosParentInfo = value; }

         global Boolean getExpandShareLinks() {return pexpandShareLinks;}
         global void setExpandShareLinks(Boolean value) { if (pexpandShareLinks != value) { pdocument = null; } pexpandShareLinks = value; } 
        
         global Boolean getExpandAttributeGroups() {return pexpandAttributeGroups;}
         global void setExpandAttributeGroups(Boolean value) { if (pexpandAttributeGroups != value) { pdocument = null; } pexpandAttributeGroups = value; }
        
         global Boolean getExpandHistoryItems() {return pexpandHistoryItems;} 
         global void setExpandHistoryItems(Boolean value){ if (pexpandHistoryItems != value) { pdocument = null; } pexpandHistoryItems = value; } 

         global Boolean getExpandVersions() {return pexpandVersions;} 
         global void setExpandVersions(Boolean value){ if (pexpandVersions != value) { pdocument = null; } pexpandVersions = value; } 
         global Boolean getExpandLock() {return pexpandLock;} 
         global void setExpandLock(Boolean value){ if (pexpandLock != value) { pdocument = null; } pexpandLock = value; } 
         global Boolean getExpandDocumentProcessTrackingActivities() {return pexpandDocumentProcessTrackingActivities;}
         global void setExpandDocumentProcessTrackingActivities(Boolean value){ if (pexpandDocumentProcessTrackingActivities != value) { pdocument = null; } pexpandDocumentProcessTrackingActivities = value; } 


         global CLMDocument getDocument()  {
            
                 if (pdocument == null)
                 {
                     this.Result();
                 }
 
                 return pdocument;
             
         }

         private CLMDocument Result()
         {
             if (pdocument != null)
             {
                 return pdocument;
             }
             if (!string.isEmpty(ppath))
             {
                
                string js = scmsvc.requestor.Get( aURL+'/documents?path=' + EncodingUtil.urlEncode(ppath,'UTF-8') +'&' +ExpandDocument(), new Map<string, string>());
                System.debug(js);
                 pdocument= (CLMDocument)JSON.deserialize(js, CLMDocument.class);
                     
                 
             }
             if (pid != null)
             {
 
                System.debug(aURL);
                string jsi =  scmsvc.requestor.Get(aURL+'/documents/' + pid + '?' +ExpandDocument(), new Map<string, string>());
                pdocument= (CLMDocument)JSON.deserialize(jsi, CLMDocument.class);
             }
 
             return pdocument;
         }

         global Blob downloadDocument(String acceptType){

            Map<String, String> headers = new Map<String, String>{'Accept' => acceptType};

            System.debug('downloadDocument called for document:' + this.Result().DownloadDocumentHref);
            String endpoint = this.Result().DownloadDocumentHref;
            Blob responseBody = scmsvc.requestor.GetBlob(endpoint, headers, 0);
            if (responseBody == null){
                return null;
            }
            return responseBody;
         }


         private String ExpandDocument()
         {
 
             List<String> expandString = new List<string>(); 
 
             if (pexpandParentFolder == true)
             {
                 expandString.Add('ParentFolder');
             }
             if (pexpandHistoryItems == true)
             {
                 expandString.Add('HistoryItems');
             }
             if (pexpandLock == true)
             {
                 expandString.Add('Lock');
             }
             if (pexpandPath == true)
             {
                 expandString.Add('Path');
             }
             if (pexpandEosParentInfo == true)
             {
                 expandString.Add('EosParentInfo');
             }
             if (pexpandDocumentProcessTrackingActivities == true)
             {
                 expandString.Add('DocumentProcessTrackingActivities');
             }
             if (pexpandShareLinks == true)
             {
                 expandString.Add('ShareLinks');
             }
             if (pexpandAttributeGroups == true)
             {
                 expandString.Add('AttributeGroups');
             }
             if (pexpandVersions == true)
             {
                 expandString.Add('Versions');
             }
 
             if (expandString.size() == 0) { return ''; }
 
 
             return 'expand='+ string.join(expandString,',');
         }

        
    }