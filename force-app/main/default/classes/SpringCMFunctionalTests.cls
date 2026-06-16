global with sharing class SpringCMFunctionalTests {
    global SpringCMFunctionalTests(SpringCMIAuthenticator auth) {
        this.authenticator = auth;
        this.svc = new SpringCMService(authenticator);
    }

    SpringCMIAuthenticator authenticator;
     SpringCMService svc;

     global  void TestAuthenticator(){
        string token = authenticator.AccessToken();
        string objURL = authenticator.GetObjectAPIUrl();
        string uldURL = authenticator.GetUploadAPIUrl();
        string dldURL = authenticator.GetDownloadAPIUrl();
        System.debug(token);
        System.assert(token != null);
        System.assert(objURL != null);
        System.assert(uldURL != null);
        System.assert(dldURL != null);
    }

    global  void TestSpringCMUserAuthenticator(){
        
        string token = authenticator.AccessToken();
        System.debug(token);
        System.assert(token != null);
    }

    //Document Tests
    global void TestGetDocumentById(){
        CLMDocument doc = svc.GetDocumentById('f165bf8f-28bb-ea11-9c2e-d89d6716196d').getDocument();
        System.debug(doc.Name);
        System.assert(doc.Name != null);
    }

    global void TestExpandDocumentById(){
        CLMDocumentRequest doc = svc.GetDocumentById('f165bf8f-28bb-ea11-9c2e-d89d6716196d');
        doc.setExpandDocumentProcessTrackingActivities(true);
        doc.setExpandEosParentInfo(true);
        doc.setExpandHistoryItems(true);
        doc.setExpandLock(true);
        doc.setExpandParentFolder(true);
        doc.setExpandPath(true);
        doc.setExpandShareLinks(true);
        doc.setExpandVersions(true);
        
        CLMDocument getDoc = doc.getDocument();
        System.debug(getDoc.Name);
        System.assert(getDoc.Name != null);
    }

    global void TestGetDocumentByPath(){
        CLMDocument doc = svc.GetDocumentByPath('/SDK Test Account/Docusign Test/My folder/Documents/Loan_Agreement_Template.docx').getDocument();
        System.debug(doc.Name);
        System.assert(doc.Name != null);
    }

    global void TestDocumentDownload(){
        Blob doc = svc.GetDocumentById('f165bf8f-28bb-ea11-9c2e-d89d6716196d').downloadDocument('');
        System.debug(doc);
        System.assert(doc != null);        
    }

    global void TestDocumentUpload(){
        CLMFolder fld = svc.GetFolderById('029431a5-1abb-ea11-9c2e-d89d6716196d').getFolder();
        CLMDocument doc = svc.GetDocumentById('f165bf8f-28bb-ea11-9c2e-d89d6716196d').getDocument();
        Blob file = svc.GetDocumentById('f165bf8f-28bb-ea11-9c2e-d89d6716196d').downloadDocument('');
        Map<string,blob> documentsToStore = new Map<string,blob>();
        documentsToStore.put(doc.Name, file);
        CLMDocument uploadDoc = svc.UploadDocuments(fld,documentsToStore,'');
        System.debug(doc.Name);
        System.assert(doc.Name != null);        
    }

    global void TestUpdateDocument(){        
        CLMDocument doc = svc.GetDocumentByPath('/SDK Test Account/Docusign Test/My folder/Documents/Loan_Agreement_Template.docx').getDocument();   
        CLMAttributeFieldValue attrFV = new CLMAttributeFieldValue();
        attrFV.Value = 'Hello!';
        Map<String, CLMAttributeFieldValue> fieldValue = new Map<String, CLMAttributeFieldValue>{'Ip Address'=>attrFV};
        Map<String, Map<String, CLMAttributeFieldValue>> attributes = new Map<String, Map<String, CLMAttributeFieldValue>>{'Legal Approval'=> fieldValue};
        doc.AttributeGroups = attributes;        
        CLMDocument upd = svc.UpdateDocument(doc, false);
        System.debug(upd.Name);
        System.assert(upd.Name != null);
    }

    global void TestDocumentDelete(){
        CLMDocument doc = svc.GetDocumentById('15cebb0c-4dba-ea11-9c2e-d89d6716196d').getDocument();
        CLMDocument del = svc.DeleteDocument(doc);
        System.debug(del.Name);
        System.assert(del.Name != null);
    }

    global void TestDocumentCheckout(){
        CLMDocument doc = svc.GetDocumentByPath('/SDK Test Account/Docusign Test/CheckIn/Version 1.docx').getDocument();  
        string docID = svc.getIDfromHref(doc.Href);
        CLMLock docLock = svc.CheckOutDocuments(docID);
        System.debug(docLock);  
        System.assert(docLock.IsLocked == true);   
    }

    global void TestCancelDocumentCheckout(){
        CLMDocument doc = svc.GetDocumentByPath('/SDK Test Account/Docusign Test/CheckIn/Version 1.docx').getDocument();  
        string docID = svc.getIDfromHref(doc.Href);
        CLMLock docLock = svc.CancelCheckoutDocuments(docID);
        System.debug(docLock.IsLocked);  
        System.assert(docLock.IsLocked == false);   
    }

    global void TestCheckInDocument(){
        CLMDocument ogDoc = svc.GetDocumentByPath('/SDK Test Account/Docusign Test/CheckIn/Version 1.docx').getDocument();  
        string ogDocID = svc.getIDfromHref(ogDoc.Href);

        Blob newDoc = svc.GetDocumentByPath('/SDK Test Account/Docusign Test/CheckIn/Version 2.docx').downloadDocument('');  
        

        CLMDocument updDoc = svc.CheckInDocuments(ogDocID, newDoc, ogDoc.Name);
        System.debug(updDoc.Name);
        System.assert(updDoc.Name != null);
    }
//cant mock this probably need to change the logic
    global void TestMoveDocument(){
        CLMDocument doc = svc.GetDocumentByPath('/SDK Test Account/Docusign Test/response.json').getDocument();
        CLMFolder newfld = svc.GetFolderByPath('/SDK Test Account/Docusign Test/My folder').getFolder();
        
        CLMDocument mvdoc = svc.MoveDocument(doc, newfld);
        System.debug(mvdoc.Name);
        System.assert(mvdoc.Name != null);
    }

   global void TestSearch(){      
       
    CLMAttributeField attr = new CLMAttributeField();
    attr.GroupName = 'Legal Approval';
    attr.Field = 'Ip Address';
    attr.Value = 'Hello!';
    
    List<CLMAttributeField> mylist = new List<CLMAttributeField>();
    mylist.add(attr);
    
    CLMSearch request = new CLMSearch();
    request.AttributeFields = mylist;

    CLMSearch newSearch = svc.Search(request,true);
    System.debug(newSearch.Result.Total);       
    System.assert(newSearch.Result.Total > 0);
       
   }

    //DocGen
    global void TestGetDocLauncherConfigs(){
        CLMDocLauncherItems dl = (CLMDocLauncherItems)svc.GetDocLauncherConfigs();
        System.debug(dl.Items[0].Name);
        System.assert(dl.Items[0].Name != null);
    }

    global void TestGetDocLauncherTask(){
        CLMDocLauncherItems dli = (CLMDocLauncherItems)svc.GetDocLauncherConfigs();
        CLMDocLauncherTasks dlt = new CLMDocLauncherTasks();
        dlt.Data = '<data><test>hello world!</test></data>';
        dlt.DestinationFolder = dli.Items[0].DestinationFolder;
        dlt.DocLauncherConfiguration = dli.Items[0];
        dlt.DataType = 'XML';
        CLMDocLauncherTasks dlr = svc.GetDocLauncherTask(dlt);
        System.debug(dlr.DocLauncherResultUrl);
        System.debug(dlr.DocLauncherResultUrl != null);

    }

     //Folder Tests
     global void TestGetFolderById(){
        CLMFolder fld = svc.GetFolderById('029431a5-1abb-ea11-9c2e-d89d6716196d').getFolder();
        System.debug(fld.Name);
        System.assert(fld.Name != null);
    }

    global void TestGetFolderByPath(){
        CLMFolder fld = svc.GetFolderByPath('/Docusign Test/My Folder').getFolder();
        System.debug(fld.Name);
        System.assert(fld.Name != null);
    }

    global void TestCreateFolder(){        
        CLMFolder fldParent = svc.GetFolderByPath('/Docusign Test/My Folder').getFolder();
        CLMFolder fld = new CLMFolder();
        fld.Name = 'My New Folder';
        fld.ParentFolder = fldParent;
        CLMFolder newFolder = svc.CreateFolder(fld);        
        System.debug(newFolder.Name);
        System.assert(newFolder.Name != null);
    }

    global void TestCreateFolderByPath(){        
        CLMFolder newFolder = svc.CreateFolder('My New Folder','/SDK Test Account/Docusign Test/My folder');
        System.debug(newFolder.Name);
        System.assert(newFolder.Name == 'My New Folder');
    }

    global void TestCreateEOSFolder(){        
        CLMFolder newFolder = svc.FindOrCreateEOSFolder('My EOS Folder', '/SDK Test Account/Docusign Test/My folder', 'Accounts', (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue());
        System.debug(newFolder.Name);
        System.assert(newFolder.Name != null);
    }

    global void TestDeleteFolder(){        
        CLMFolder newFolder = svc.GetFolderByPath('/Docusign Test/My Folder').getFolder();
        CLMFolder fld = svc.DeleteFolder(newFolder);
        System.debug(fld.Name);
        System.assert(fld.Name != null);
    }

    global void TestUpdateFolder(){        
        CLMFolder newFolder = svc.GetFolderByPath('/Docusign Test/My Folder').getFolder();
        newFolder.Name = 'My Folderxxxx';
        CLMFolder fld = svc.UpdateFolder(newFolder, false);
        System.debug(fld.Name);
        System.assert(fld.Name != null);
    }

    global void TestMoveFolder(){
        CLMFolder destinationFolder = svc.GetFolderByPath('/Docusign Test/My Folder').getFolder();
        CLMFolder folderToMove = svc.GetFolderByPath('/Docusign Test/My Folder').getFolder();
        CLMFolder fld = svc.MoveFolder(folderToMove, destinationFolder);
        System.debug(fld.Name);
        System.assert(fld.Name != null);
    }

    global void TestFolderSearch(){      
       
        CLMSearch request = new CLMSearch();
        request.Title = 'Docusign Test'; 
        CLMSearch newSearch = svc.FolderSearch(request,true);
        System.debug(newSearch.Result.Total);       
        System.assert(newSearch.Result.Total > 0);
        
    }

    global void TestExpandFolder()
        {
            CLMFolderRequest fld = svc.GetFolderByPath('/Docusign Test/My Folder');            
            fld.setExpandFolders(true);
            fld.setExpandPath(true);
            fld.setExpandEosInfo(true);
            fld.setExpandAttributeGroups(true);
            fld.setExpandDocuments(true);
            fld.setExpandEosParentInfo(true);
            fld.setExpandParentFolder(true);
            fld.setExpandSecurity(true);
            fld.setExpandShareLinks(true);
            CLMFolder folder = fld.getFolder();            
           System.debug(folder.Path);
           System.assert(folder.Path != null);

        }


    //Workflow Tests
    global void TestStartWorkflow(){
        CLMWorkflow wfParam = new CLMWorkflow();
        wfParam.Name = 'Test Workflow';
        wfParam.Params = '<doc><name>MyTestDoc.docx</name></doc>';

        CLMWorkflow wf = svc.StartWorkflow(wfParam);
        System.debug(wf.Status);
        System.assert(wf.Status != null);

        CLMWorkflow wfSignal = svc.SignalWorkflow(wf);
        
        CLMWorkflow wfDel = svc.DeleteWorkflow(wf);

    }

    global void TestGetWorkflow(string wfHref){        
        CLMWorkflow wfParam = new CLMWorkflow();
        wfParam.Href = wfHref;

        CLMWorkflow wf = svc.GetWorkflowByHref(wfParam);
        System.debug(wf.Status);
        System.assert(wf.Status != null);
    }

    global void TestSignalWorkflow(string wfHref){
        CLMWorkflow wfParam = new CLMWorkflow();
        wfParam.Href = wfHref;
        wfParam.Params = '<doc><name>MyTestDoc.docx</name></doc>';

        CLMWorkflow wf = svc.SignalWorkflow(wfParam);
        System.debug(wf.Status);
        System.assert(wf.Status != null);
    }

    global void TestDeleteWorkflow(string wfHref){
        CLMWorkflow wfParam = new CLMWorkflow();
        wfParam.Href = wfHref;

        CLMWorkflow wf = svc.DeleteWorkflow(wfParam);
        System.debug(wf.Status);
        System.assert(wf.Status != null);
    }
}