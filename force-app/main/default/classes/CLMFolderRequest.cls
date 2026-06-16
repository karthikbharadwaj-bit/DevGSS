global with sharing class CLMFolderRequest {

    global CLMFolderRequest(string folderId,string folderPath,string eosObjType,string eosObjID,string folderType, SpringCMService svc, string apiURL)
    {
        pid = folderId;
        ppath = folderPath;
        eosOT = eosObjType;
        eosOID = eosObjID;
        folT = folderType;
        scmsvc = svc;
        aURL = apiURL;
    }


    global CLMFolderRequest(CLMFolder folder, SpringCMService svc)
    {   
        this.pfolder = folder;
        this.pid = svc.getIDfromHref(folder.Href);
        scmsvc = svc;
        //aURL = apiURL;
    }

    private string pid;
    private string ppath;
    private string eosOT;
    private string eosOID;
    private string folT;
    private SpringCMService scmsvc;
    private CLMFolder pfolder;       
    private string aURL;
    private Boolean pexpandParentFolder;
    private Boolean pexpandDocuments;
    private Boolean pexpandFolders;
    private Boolean pexpandPath;
    private Boolean pexpandEosParentInfo;
    private Boolean pexpandEosInfo;
    private Boolean pexpandShareLinks;
    private Boolean pexpandAttributeGroups;
    private Boolean pexpandSecurity;


    global Boolean getExpandParentFolder() {return pexpandParentFolder;} 
    global void setExpandParentFolder(Boolean value) {if (pexpandParentFolder != value) { pfolder = null;} pexpandParentFolder = value; }
    
    global Boolean getExpandDocuments() {return pexpandDocuments;} 
    global void setExpandDocuments(Boolean value) {if (pexpandDocuments != value) { pfolder = null;} pexpandDocuments = value; }

    global Boolean getExpandFolders() {return pexpandFolders;} 
    global void setExpandFolders(Boolean value) {if (pexpandFolders != value) { pfolder = null;} pexpandFolders = value; }       

    global Boolean getExpandPath() { return pexpandPath;}
    global void setExpandPath(Boolean value) {if (pexpandPath != value) { pfolder = null; } pexpandPath = value; }

    global Boolean getExpandEosParentInfo() { return pexpandEosParentInfo;}
    global void setExpandEosParentInfo(Boolean value) { if (pexpandEosParentInfo != value) { pfolder = null; } pexpandEosParentInfo = value; }

    global Boolean getExpandEosInfo() { return pexpandEosInfo;}
    global void setExpandEosInfo(Boolean value) { if (pexpandEosInfo != value) { pfolder = null; } pexpandEosInfo = value; }

    global Boolean getExpandShareLinks() {return pexpandShareLinks;}
    global void setExpandShareLinks(Boolean value) { if (pexpandShareLinks != value) { pfolder = null; } pexpandShareLinks = value; }         

    global Boolean getExpandAttributeGroups() {return pexpandAttributeGroups;}
    global void setExpandAttributeGroups(Boolean value) { if (pexpandAttributeGroups != value) { pfolder = null; } pexpandAttributeGroups = value; }

    global Boolean getExpandSecurity() {return pexpandSecurity;}
    global void setExpandSecurity(Boolean value) { if (pexpandSecurity != value) { pfolder = null; } pexpandSecurity = value; }
    
    global CLMFolder getFolder()  {            
        if (pfolder == null)
        {
            this.Result();
        }
        return pfolder;        
    }

    private CLMFolder Result()
    {
        if (pfolder != null)
        {
            return pfolder;
        }
        //eosOT = eosObjType;
        //eosOID = eosObjID;
        //folT = folderType;

        System.debug('Path');
        System.debug(ppath);
        System.debug('aURL');
        System.debug(aURL);
        //Folder By Path
        if (!string.isEmpty(ppath) && (aURL.contains('v2/') || aURL.contains('V2/')))
        {       
            System.debug(aURL);
            string js = scmsvc.requestor.Get(aURL+'/folders/path?path=' + EncodingUtil.urlEncode(ppath,'UTF-8') +'&' +ExpandFolder(), new Map<string, string>());
            pfolder= (CLMFolder)JSON.deserialize(js, CLMFolder.class);       
        }

        if (!string.isEmpty(ppath) && (aURL.contains('/v201411') || aURL.contains('/V201411')))
        {       
            System.debug(aURL);
            string js = scmsvc.requestor.Get(aURL+'/folders?path=' + EncodingUtil.urlEncode(ppath,'UTF-8') +'&' +ExpandFolder(), new Map<string, string>());
            pfolder= (CLMFolder)JSON.deserialize(js, CLMFolder.class);       
        }
        
        //SystemFolder
        if (!string.isEmpty(folT) && (aURL.contains('v2/') || aURL.contains('V2/')))
        {        
            string js = scmsvc.requestor.Get(aURL+'/folders/type?SystemFolder=' + EncodingUtil.urlEncode(folT,'UTF-8') +'&' +ExpandFolder(), new Map<string, string>());
            pfolder= (CLMFolder)JSON.deserialize(js, CLMFolder.class);    
        }
        if (!string.isEmpty(folT) && (aURL.contains('/v201411') || aURL.contains('/V201411')))
        {        
            string js = scmsvc.requestor.Get(aURL+'/folders?SystemFolder=' + EncodingUtil.urlEncode(folT,'UTF-8') +'&' +ExpandFolder(), new Map<string, string>());
            pfolder= (CLMFolder)JSON.deserialize(js, CLMFolder.class);             
        }

        //Folder By EOS
        if (!string.isEmpty(eosOT) && !string.isEmpty(eosOID) && (aURL.contains('v2/') || aURL.contains('V2/')))
        {       
            string js = scmsvc.requestor.Get(aURL+'/folders/eos?eosObjectType=' + EncodingUtil.urlEncode(eosOT,'UTF-8') +'&eosObjectId='+ EncodingUtil.urlEncode(eosOID,'UTF-8') + ExpandFolder(), new Map<string, string>());
            pfolder= (CLMFolder)JSON.deserialize(js, CLMFolder.class);       
        }

        if (!string.isEmpty(eosOT) && !string.isEmpty(eosOID) && (aURL.contains('/v201411') || aURL.contains('/V201411')))
        {       
            string js = scmsvc.requestor.Get(aURL+'/folders?eosObjectType=' + EncodingUtil.urlEncode(eosOT,'UTF-8') +'&eosObjectId='+ EncodingUtil.urlEncode(eosOID,'UTF-8') + ExpandFolder(), new Map<string, string>());
            pfolder= (CLMFolder)JSON.deserialize(js, CLMFolder.class);       
        }


        //Folder By ID
        if (pid != null)
        {
            string jsi =  scmsvc.requestor.Get(aURL+'/folders/' + pid + '?' +ExpandFolder(), new Map<string, string>());
            System.debug(jsi);
            pfolder= (CLMFolder)JSON.deserialize(jsi, CLMFolder.class);
        }

        return pfolder;
    }


    private String ExpandFolder()
    {

        List<String> expandString = new List<string>(); 

        if (pexpandParentFolder  == true)
        {
            expandString.Add('ParentFolder');
        }
        if (pexpandDocuments  == true)
        {
            expandString.Add('Documents');
        }
        if (pexpandFolders  == true)
        {
            expandString.Add('Folders');
        }
        if (pexpandPath  == true)
        {
            expandString.Add('Path');
        }
        if (pexpandEosParentInfo  == true)
        {
            expandString.Add('EosParentInfo');
        }
        if (pexpandEosInfo  == true)
        {
            expandString.Add('Eosinfo');
        }
        if (pexpandShareLinks  == true)
        {
            expandString.Add('ShareLinks');
        }
        if (pexpandAttributeGroups  == true)
        {
            expandString.Add('AttributeGroups');
        }
        if (pexpandSecurity  == true)
        {
            expandString.Add('Security');
        }

        if (expandString.size() == 0) { return ''; }


        return 'expand='+ string.join(expandString,',');
    }
}