global with sharing class SpringCMService {

    global SpringCMService(SpringCMIAuthenticator auth)
    {
        this.requestor = new SpringCMHTTPRequestor(auth);
        this.auth = auth;
    }
    
    
    private SpringCMIAuthenticator auth;
    public SpringCMHTTPRequestor requestor {get;set;}

    public string getIDfromHref(string href)
    { 
        Integer last = href.lastIndexOf('/') + 1;
        Integer endn = href.length();
    
        return href.substring(last, endn);
    }

    global SpringCMItem QueryNext(SpringCMItem springCMItem,System.Type itemType)
    {    
        string response = requestor.Get(springCMItem.Next,null);        
        response = response.replace('"Limit":', '"ItemLimit":');
        return (SpringCMItem)JSON.deserialize(response, itemType);

    }    

    //Document
    global CLMDocument DeleteDocument(CLMDocument doc){
        String docResults = requestor.DeleteCall(doc.Href,new Map<string, string>()); 
        return (CLMDocument)JSON.deserialize(docResults, CLMDocument.class);
    }
    
    global CLMDocumentRequest GetDocumentById(string id)
    {
        return new CLMDocumentRequest(id,null,this,auth.GetObjectAPIUrl());
    }

    global CLMDocumentRequest GetDocumentByPath(string path)
    {
        return new CLMDocumentRequest(null,path, this,auth.GetObjectAPIUrl());
    }

    global CLMDocument UploadDocuments(CLMFolder folder,  Map<String, Blob> documentsToStore, string fileName){

        if (documentsToStore.isEmpty()) {
            return null;
        }
        System.debug('uploadDocuments called for folder:' + folder.CreateDocumentHref);
        String endpoint = folder.CreateDocumentHref.replace('{?name}', '');

        String boundary = '----------------------------741e90d31eff';
        String footer = '--' + boundary + '--';

        String attachmentsStr = '';
        String lastPrepend = '';
        for (String documentName : documentsToStore.keySet()) {
            Blob fileBlob = documentsToStore.get(documentName);
            String fHeader = lastPrepend + '--' + boundary + '\r\n';
            fHeader += String.format('Content-Disposition: form-data; name="files[{0}]"; filename="{0}"\r\nContent-Type: application/octet-stream',
                    new String[] { documentName });
            String fHeaderEncoded = EncodingUtil.base64Encode(Blob.valueOf(fHeader + '\r\n\r\n'));
            while (fHeaderEncoded.endsWith('=')) {
                fHeader += ' ';
                fHeaderEncoded = EncodingUtil.base64Encode(Blob.valueOf(fHeader + '\r\n\r\n'));
                }
            String fBodyEncoded = EncodingUtil.base64Encode(fileBlob);
            String last4Bytes = fBodyEncoded.substring(fBodyEncoded.length() - 4, fBodyEncoded.length());
            if (last4Bytes.endsWith('==')) {
                last4Bytes = last4Bytes.substring(0, 2) + '0K';
                fBodyEncoded = fBodyEncoded.substring(0, fBodyEncoded.length() - 4) + last4Bytes;
                lastPrepend = '';
                }
            else if (last4Bytes.endsWith('=')) {
                last4Bytes = last4Bytes.substring(0, 3) + 'N';
                fBodyEncoded = fBodyEncoded.substring(0, fBodyEncoded.length() - 4) + last4Bytes;
                lastPrepend = '\n';
                }
            else {
                lastPrepend = '\r\n';
                }
            attachmentsStr += fHeaderEncoded + fBodyEncoded;
            }
        footer = lastPrepend + footer;

        String footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));

        Blob bodyBlob = EncodingUtil.base64Decode(attachmentsStr + footerEncoded);
        Map<String, String> headers = new Map<String, String>{'Content-Type' => String.format('multipart/form-data; boundary={0}', new String[] { boundary })};
        System.debug(bodyBlob);
        String doc = requestor.PostBlob(endpoint, bodyBlob, headers, 0);
       

        return (CLMDocument)JSON.deserialize(doc, CLMDocument.class);
    }
    
    global CLMLock CheckOutDocuments(String docID){
        String endpoint = auth.GetObjectAPIUrl()+'/documents/'+docID+'/lock';
        System.debug('***endpoint*** | '+endpoint);
        string doc =  requestor.Post(endpoint,'', new Map<string, string>());
        return (CLMLock)JSON.deserialize(doc, CLMLock.class);
    }

    global CLMLock CancelCheckoutDocuments(String docID){
        String endpoint = auth.GetObjectAPIUrl()+'/documents/'+docID+'/lock';
        string doc =  requestor.DeleteCall(endpoint, new Map<string, string>());
        return (CLMLock)JSON.deserialize(doc, CLMLock.class);
    }

    global CLMDocument CheckInDocuments(String docID,  Blob fileBlob, string fileName){

        String endpoint = auth.GetUploadAPIUrl()+'/documents/'+docID;

        String boundary = '----------------------------741e90d31eff';
        String footer = '--' + boundary + '--';

        String attachmentsStr = '';
        String lastPrepend = '';
        String fHeader = lastPrepend + '--' + boundary + '\r\n';
        fHeader += String.format('Content-Disposition: form-data; name="files[{0}]"; filename="{0}"\r\nContent-Type: application/octet-stream',
                new String[] { fileName });
        String fHeaderEncoded = EncodingUtil.base64Encode(Blob.valueOf(fHeader + '\r\n\r\n'));
        while (fHeaderEncoded.endsWith('=')) {
            fHeader += ' ';
            fHeaderEncoded = EncodingUtil.base64Encode(Blob.valueOf(fHeader + '\r\n\r\n'));
            }
        String fBodyEncoded = EncodingUtil.base64Encode(fileBlob);
        String last4Bytes = fBodyEncoded.substring(fBodyEncoded.length() - 4, fBodyEncoded.length());
        if (last4Bytes.endsWith('==')) {
            last4Bytes = last4Bytes.substring(0, 2) + '0K';
            fBodyEncoded = fBodyEncoded.substring(0, fBodyEncoded.length() - 4) + last4Bytes;
            lastPrepend = '';
            }
        else if (last4Bytes.endsWith('=')) {
            last4Bytes = last4Bytes.substring(0, 3) + 'N';
            fBodyEncoded = fBodyEncoded.substring(0, fBodyEncoded.length() - 4) + last4Bytes;
            lastPrepend = '\n';
            }
        else {
            lastPrepend = '\r\n';
            }
        attachmentsStr += fHeaderEncoded + fBodyEncoded;
        footer = lastPrepend + footer;

        String footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));

        Blob bodyBlob = EncodingUtil.base64Decode(attachmentsStr + footerEncoded);
        Map<String, String> headers = new Map<String, String>{'Content-Type' => String.format('multipart/form-data; boundary={0}', new String[] { boundary })};
        System.debug(bodyBlob);
        String doc = requestor.PostBlob(endpoint, bodyBlob, headers, 0);
       

        return (CLMDocument)JSON.deserialize(doc, CLMDocument.class);
    }

    global CLMDocument MoveDocument(CLMDocument doc, CLMFolder parentFolder){
        doc.ParentFolder = parentFolder;
        return UpdateDocument(doc,false);
    }

    global CLMDocument UpdateDocument(CLMDocumentRequest doc, boolean overwriteAllValues){
        return UpdateDocument(doc.getDocument(),overwriteAllValues);
    }

    global CLMDocument UpdateDocument(CLMDocument doc, boolean overwriteAllValues){
        string updc = '';
        if (overwriteAllValues){
            updc = requestor.Put(doc.Href,JSON.serialize(doc),new Map<string, string>());
        }else{            
            Map<String, String> headers = new Map<String, String>{'X-HTTP-Method-Override' => 'PATCH'};
            updc = requestor.Put(doc.Href,JSON.serialize(doc),headers);             
        }

        return (CLMDocument)JSON.deserialize(updc, CLMDocument.class);
    }

    global CLMSearch Search(CLMSearch request, Boolean LoadAttributes){
        string expand = '';
        if (LoadAttributes)
        {
            expand = '?expand=AttributeGroups';
        }
        string searchResp = requestor.Post(auth.GetObjectAPIUrl()+'/documentsearchtasks'+expand,JSON.serialize(request).replace('"GroupName":', '"Group":'),new Map<string, string>());
        
        return (CLMSearch)JSON.deserialize(searchResp, CLMSearch.class);

    }

    //DocLauncher Tasks
    global SpringCMItem GetDocLauncherConfigs(){
        string dl = requestor.Get(auth.GetObjectAPIUrl()+'/doclauncherconfigurations',new Map<string, string>());
        return (CLMDocLauncherItems)JSON.deserialize(dl, CLMDocLauncherItems.class);
    }

    global CLMDocLauncherTasks GetDocLauncherTask(CLMDocLauncherTasks docLauncherTask){
        string dlt =  requestor.Post(auth.GetObjectAPIUrl()+'/doclaunchertasks',JSON.serialize(docLauncherTask),new Map<string, string>());
        return (CLMDocLauncherTasks)JSON.deserialize(dlt, CLMDocLauncherTasks.class);
    }

    //Folder
    global CLMFolderRequest GetFolderById(string id)
    {
        return new CLMFolderRequest(id,null,null,null,null,this,auth.GetObjectAPIUrl());
    }

    global CLMFolderRequest GetFolderByPath(string path)
    {
        return new CLMFolderRequest(null,path,null,null,null,this,auth.GetObjectAPIUrl());
    }

    global CLMFolderRequest GetFolderByEOS(string eosObjType, string eosObjID)
    {
        return new CLMFolderRequest(null,null,eosObjType,eosObjID,null,this,auth.GetObjectAPIUrl());
    }

    global CLMFolderRequest GetFolderBySystemType(string folderType)
    {
        return new CLMFolderRequest(null,null,null,null,folderType,this,auth.GetObjectAPIUrl());
    }

    
    global CLMFolder CreateFolder(CLMFolder folder){
        string fld = requestor.Post(auth.GetObjectAPIUrl()+'/folders',JSON.serialize(folder),new Map<string, string>());
        System.debug('fld | ' + fld);
        CLMFolder newFolder = (CLMFolder)JSON.deserialize(fld, CLMFolder.class);
        return newFolder;
    }

   global CLMFolder CreateFolder(string name, string path){
        
        CLMFolder parentFolder = GetFolderByPath(path).getFolder();
        CLMFolder newFolder = new CLMFolder();
        newFolder.ParentFolder = parentFolder;
        newFolder.Name = name;
        return CreateFolder(newFolder);
    }
 
    global CLMFolder FindOrCreateEOSFolder(string folderName, string path, string objectType, string objectId){
        CLMFolder eosFolder = new CLMFolder();
        CLMEosInfo eosInfo = new CLMEosInfo();
        eosInfo.Name = folderName;
        eosInfo.ObjectType = objectType;
        eosInfo.ObjectId = objectId;
        eosInfo.Path = path;
        eosFolder.EosInfo = eosInfo;
        return CreateFolder(eosFolder);
    }

    global CLMFolder DeleteFolder(CLMFolder folder){
        string fld =  requestor.DeleteCall(folder.Href, new Map<string, string>());
        return (CLMFolder)JSON.deserialize(fld, CLMFolder.class);
    }

    global CLMFolder UpdateFolder (CLMFolder folder, Boolean overwriteAllAttributes){
        string fld = '';
        if (overwriteAllAttributes){
            fld = requestor.Put(folder.Href,JSON.serialize(folder),new Map<string, string>());
        }else{
            Map<String, String> headers = new Map<String, String>{'X-HTTP-Method-Override' => 'PATCH'};
            fld = requestor.Put(folder.Href,JSON.serialize(folder),headers); 
        }

        return (CLMFolder)JSON.deserialize(fld, CLMFolder.class);
    }

    global CLMFolder MoveFolder(CLMFolder folderToMove, CLMFolder destinationFolder){

        folderToMove.ParentFolder = destinationFolder;
        return UpdateFolder(folderToMove, false);

    }

    global CLMSearch FolderSearch(CLMSearch request, Boolean LoadAttributes){
        string expand = '';
        if (LoadAttributes)
        {
            expand = '?expand=AttributeGroups';
        }
        string searchResp = requestor.Post(auth.GetObjectAPIUrl()+'/foldersearchtasks'+expand,JSON.serialize(request),new Map<string, string>());        
        return (CLMSearch)JSON.deserialize(searchResp, CLMSearch.class);

    }



    //Workflow
    global CLMWorkflow StartWorkflow(CLMWorkflow workflow){
        
        string wf =  requestor.Post(auth.GetObjectAPIUrl()+'/workflows',JSON.serialize(workflow),new Map<string, string>());
        return (CLMWorkflow)JSON.deserialize(wf, CLMWorkflow.class);
    }

    global CLMWorkflow GetWorkflowByHref(CLMWorkflow workflow){

        string wf =  requestor.Get(workflow.Href, new Map<string, string>());
        return (CLMWorkflow)JSON.deserialize(wf, CLMWorkflow.class);
    }

    global CLMWorkflow SignalWorkflow(CLMWorkflow workflow){

        string wf =  requestor.Post(workflow.Href+'/signal',JSON.serialize(workflow), new Map<string, string>());
        return (CLMWorkflow)JSON.deserialize(wf, CLMWorkflow.class);

    }

    global CLMWorkflow DeleteWorkflow(CLMWorkflow workflow){
        string wf =  requestor.DeleteCall(workflow.Href, new Map<string, string>());
        return (CLMWorkflow)JSON.deserialize(wf, CLMWorkflow.class);
    }
}