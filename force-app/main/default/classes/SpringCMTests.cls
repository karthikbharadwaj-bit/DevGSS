@isTest
global with sharing class SpringCMTests {

    global static SpringCMIAuthenticator authenticator;

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest static void RunTests(){
        authenticator = new CMAPIUserAuthenticator('test','test','https://auth.springcm.com/api/v201606/apiuser','na11','v201411');
        Test.setMock(HttpCalloutMock.class, new SpringCMHttpMockResponseGenerator());
        SpringCMFunctionalTests tests = new SpringCMFunctionalTests(authenticator);
        tests.TestAuthenticator();
        tests.TestGetDocumentById();
        tests.TestGetDocumentByPath();
        tests.TestDocumentDownload();
        tests.TestDocumentUpload();
        tests.TestUpdateDocument();
        tests.TestDocumentDelete();
        tests.TestDocumentCheckout();
        tests.TestExpandDocumentById();
        tests.TestCancelDocumentCheckout();
        tests.TestCheckInDocument();
        tests.TestSearch();
        tests.TestGetDocLauncherConfigs();
        tests.TestGetDocLauncherTask();
        tests.TestGetFolderById();
        tests.TestGetFolderByPath();
        tests.TestCreateFolderByPath();
        tests.TestCreateEOSFolder();
        tests.TestDeleteFolder();
        tests.TestUpdateFolder();
        tests.TestMoveFolder();
        tests.TestFolderSearch();
        tests.TestExpandFolder();
        tests.TestStartWorkflow();

        authenticator = new DSAPIUserAuthenticator('123132123', '213213213', 'account-d.docusign.com', '234324234', 'MIICXAIBAAKBgQCQ0GttQjvrDenKKsxP6l3O+kQjN1aRECcdEqxzOR7kqo2af95sMDpYXmcfe6OM84Gow6Bmog1EtzcMc5SZSb+WnJQBddeRl/Yy3Q+qKiDhn06tu035V1NcsNbs0eeW/7jAa3w0qqHQdaKc/+EF36wkOQ3/CKAfNShX975DKw15JQIDAQABAoGARUwG7CyywYNR6dVbGa7cHwxxiKyVdytUnDvwW97sop3ezxz7Uaguc1URYeZnWC66UAj0+8f2M3i9Fe9FH6lDzVNjAzSBq+gIDq8Sj84ehF/zadSglzKFaU0ObY2BVD7o1E9mY4eNdHyOFfbt21LvWjQUkVBbEPajB5MrxXG0Vm0CQQDfe94+y8fXVoNNmipUsrCHVAi0xtR2m8Sxkj9Rb3+RzdRJTbyVJIqNR2CijDbcZZ6W/tLz5c2MnDwDYiD955TDAkEApeJUko3pQ5l3yBFCNrsXZp+KA4dVTtjzAK7EcL+FFMCnDmnGHVWJBhbsbJTL3yo8bo11dXboAc05SFaLhBw79wJAU+hP80fTilgjCFnfltlYShcVBbq5PqcRXJJKT6sLPJUJJVSYf26uzoiEEcOPPYSx3INkdMpNOIPYTHTlai8uvQJATGm2xY/DbRVLvQheNPH39Jj3LWrw3BJJ1f2rlbhTaFzaV2RYE3ksVnbGz7m3NASzs8VL3yE3/GR5x52+RMvwvwJBAJmm4Bx2NtgCdkWBKYXnp6Q7Mo0Z8TAjpH/iSv98Qxf7BiaZ0SxL6Yj22z1BIFPFZqkVScs6B6IEeFnN4vbChuU=','na11','v2', 'signature impersonation spring_read spring_write');
        Test.setMock(HttpCalloutMock.class, new SpringCMHttpMockResponseGenerator());
        SpringCMFunctionalTests testDS = new SpringCMFunctionalTests(authenticator);
        testDS.TestAuthenticator();

        authenticator = new CMSalesforceUserAuthenticator('test', 'test','https://auth.springcm.com/api/v201606/salesforce','na11','v201411', '1232133','');
        Test.setMock(HttpCalloutMock.class, new SpringCMHttpMockResponseGenerator());
        SpringCMFunctionalTests testSFDC = new SpringCMFunctionalTests(authenticator);
        testSFDC.TestAuthenticator();

        authenticator = new CMSalesforceUserAuthenticator('test', 'test','https://auth.springcm.com/api/v201606/salesforce','na11','v201411', '1232133');
        Test.setMock(HttpCalloutMock.class, new SpringCMHttpMockResponseGenerator());
        SpringCMFunctionalTests testSFDC2 = new SpringCMFunctionalTests(authenticator);
        testSFDC2.TestAuthenticator();

    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest static void TestModels(){

        CLMDocument doc = new CLMDocument();
        object test;
        test = doc.AccessLevel;
        test = doc.AttributeGroups;
        test = doc.CreatedBy;
        test = doc.CreatedDate;
        test = doc.Description;
        test = doc.DocumentProcessTrackingActivities;
        test = doc.DownloadDocumentHref;
        test = doc.EosParentInfo;
        test = doc.HistoryItems;
        test = doc.Href;
        test = doc.Lock;
        test = doc.Name;
        test = doc.NativeFileSize;
        test = doc.PageCount;
        test = doc.ParentFolder;
        test = doc.Path;
        test = doc.PdfFileSize;
        test = doc.PreviewUrl;
        test = doc.RelatedDocuments;
        test = doc.ShareLinks;
        test = doc.UpdatedBy;
        test = doc.UpdatedDate;
        test = doc.Version;
        test = doc.Versions;

        CLMAccessLevel accessLevel = new CLMAccessLevel();
        test = accessLevel.See;
        test = accessLevel.Read;
        test = accessLevel.Write;
        test = accessLevel.Move;
        test = accessLevel.Create;
        test = accessLevel.SetAccess;

        CLMAccount account = new CLMAccount();
        test = account.Id;
        test = account.Name;
        test = account.Type;
        test = account.DefaultCulture;
        test = account.DefaultTimeZone;
        test = account.AttributeGroups;
        test = account.SalesForceOrgId;
        test = account.LogoUrl;
        test = account.BrandingUrl;
        test = account.Href;

        CLMActionBy actionBy = new CLMActionBy();
        test =  actionBy.Email;
        test =  actionBy.FullName;
        test =  actionBy.User;

        CLMAttributeField attrFld = new CLMAttributeField();
        test =  attrFld.GroupName;
        test =  attrFld.Field;
        test =  attrFld.Value;
        test =  attrFld.MinValue;
        test =  attrFld.MaxValue;

        CLMAttributeFieldValue attrFldVl = new CLMAttributeFieldValue();
        test =  attrFldVl.AttributeType;
        test =  attrFldVl.RepeatingAttribute;
        test =  attrFldVl.Value;

        CLMAttributeGroup attrGrp = new CLMAttributeGroup();
        test = attrGrp.GroupName;
        test = attrGrp.Exclude;

        CLMAttributeGroupFields attrGrpFld = new CLMAttributeGroupFields();
        test = attrGrpFld.Name;
        test = attrGrpFld.ReadOnly;
        test = attrGrpFld.RepeatingAttribute;
        test = attrGrpFld.Required;
        test = attrGrpFld.Type;

        CLMAttributeGroups attrGrps = new CLMAttributeGroups();
        test = attrGrps.Attributes;
        test = attrGrps.Href;
        test = attrGrps.IsSystem;
        test = attrGrps.Name;

        CLMDocumentAttributeGroupDetails docAttrDt = new CLMDocumentAttributeGroupDetails();
        test = docAttrDt.AttributeType;
        test = docAttrDt.RepeatingAttribute;
        test = docAttrDt.Value;

        CLMDocumentItems docItems = new CLMDocumentItems();
        test = docItems.Items;

        CLMDocumentMergeTasks docMrgTsk = new CLMDocumentMergeTasks();
        test = docMrgTsk.DeleteOriginals;
        test = docMrgTsk.DestinationDocumentName;
        test = docMrgTsk.DestinationFolder;
        test = docMrgTsk.DocumentsToMerge;
        test = docMrgTsk.DownloadUrl;
        test = docMrgTsk.Href;
        test = docMrgTsk.Message;
        test = docMrgTsk.ResultDocument;
        test = docMrgTsk.Status;

        CLMDocumentProcessTrackingActivities docPTA = new CLMDocumentProcessTrackingActivities();
        test = docPTA.Document;
        test = docPTA.DueDate;
        test = docPTA.EndDate;
        test = docPTA.Href;
        test = docPTA.Name;
        test = docPTA.Output;
        test = docPTA.ProcessName;
        test = docPTA.ProcessUid;
        test = docPTA.StageName;
        test = docPTA.StartDate;
        test = docPTA.Status;
        test = docPTA.TypeName;
        test = docPTA.UserActions;

        CLMDocumentReminder docRmdr = new CLMDocumentReminder();
        test = docRmdr.CreatedBy;
        test = docRmdr.CreatedDate;
        test = docRmdr.Document;
        test = docRmdr.EmailBody;
        test = docRmdr.EmailFromAddress;
        test = docRmdr.EmailSubject;
        test = docRmdr.Href;
        test = docRmdr.Name;
        test = docRmdr.RecipientAdHocEmails;
        test = docRmdr.RecipientContacts;
        test = docRmdr.RecipientGroups;
        test = docRmdr.RecipientUsers;
        test = docRmdr.ReminderDate;
        test = docRmdr.UpdatedBy;
        test = docRmdr.UpdatedDate;

        CLMGroup grp = new CLMGroup();
        test = grp.CreatedDate;
        test = grp.GroupMembers;
        test = grp.GroupType;
        test = grp.Href;
        test = grp.Name;
        test = grp.UpdatedDate;

        CLMContact cnt = new CLMContact();
        test = cnt.Email;
        test = cnt.FirstName;
        test = cnt.LastName;
        test = cnt.Address1;
        test = cnt.Address2;
        test = cnt.Address3;
        test = cnt.City;
        test = cnt.State;
        test = cnt.ZipCode;
        test = cnt.Country;
        test = cnt.Title;
        test = cnt.Company;
        test = cnt.Department;
        test = cnt.FaxNumber;
        test = cnt.PhoneNumber;
        test = cnt.Shared;
        test = cnt.Groups;
        test = cnt.Href;

        CLMContactItems cntItms = new CLMContactItems();
        test = cntItms.Items;

        CLMCopyTasks cpyTsk = new CLMCopyTasks();
        test = cpyTsk.DestinationDocumentName;
        test = cpyTsk.DestinationFolder;
        test = cpyTsk.DocumentResults;
        test = cpyTsk.DocumentsToCopy;
        test = cpyTsk.DownloadUrl;
        test = cpyTsk.FailedDocuments;
        test = cpyTsk.FailedFolders;
        test = cpyTsk.FolderResults;
        test = cpyTsk.FoldersToCopy;
        test = cpyTsk.Href;
        test = cpyTsk.Message;
        test = cpyTsk.ResultDocument;
        test = cpyTsk.Status;

        CLMDocLauncher dl = new CLMDocLauncher();
        test = dl.DestinationFolder;
        test = dl.Href;
        test = dl.Name;

        CLMDocLauncherTasks dlt = new CLMDocLauncherTasks();
        test = dlt.Data;
        test = dlt.DataType;
        test = dlt.DestinationFolder;
        test = dlt.DocLauncherConfiguration;
        test = dlt.DocLauncherResultUrl;
        test = dlt.Href;
        test = dlt.Status;
        test = dlt.UrlExpirationDate;


        CLMDocumentProcessTrackingActivitesItems docPTAI = new CLMDocumentProcessTrackingActivitesItems();
        test = docPTAI.Items;

        CLMExternalReviewTasks ert = new CLMExternalReviewTasks();
        test = ert.AddSignature;
        test = ert.AlsoNotify;
        test = ert.Comment;
        test = ert.Documents;
        test = ert.DueDate;
        test = ert.EmailMessage;
        test = ert.EmailSubject;
        test = ert.Href;
        test = ert.Recipient;
        test = ert.Sender;
        test = ert.Status;

        CLMFolder fld = new CLMFolder();
        test = fld.Name;
        test = fld.CreatedDate;
        test = fld.CreatedBy;
        test = fld.UpdatedDate;
        test = fld.UpdatedBy;
        test = fld.Description;
        test = fld.ParentFolder;
        test = fld.BrowseDocumentsUrl;
        test = fld.AccessLevel;
        test = fld.Documents;
        test = fld.Folders;
        test = fld.Path;
        test = fld.AttributeGroups;
        test = fld.EosInfo;
        test = fld.EosParentInfo;
        test = fld.ShareLinks;
        test = fld.Security;
        test = fld.CreateDocumentHref;
        test = fld.Href;

        CLMFolderArchiveTasks fldAT = new CLMFolderArchiveTasks();
        test = fldAT.ArchiveSize;
        test = fldAT.BaseFolder;
        test = fldAT.DestinationDocumentName;
        test = fldAT.DestinationFolder;
        test = fldAT.DownloadUrl;
        test = fldAT.Href;
        test = fldAT.Message;
        test = fldAT.ResultDocument;
        test = fldAT.Status;

        CLMFolderSearchTasks fldST = new CLMFolderSearchTasks();
        test = fldST.AllWords;
        test = fldST.AnyWords;
        test = fldST.Description;
        test = fldST.Href;
        test = fldST.IncludeSubFolders;
        test = fldST.InFolder;
        test = fldST.Phrase;
        test = fldST.Result;
        test = fldST.Status;
        test = fldST.Title;
        test = fldST.UpdatedBy;
        test = fldST.WithoutWords;

        CLMHistoryItems hi = new CLMHistoryItems();
        test = hi.Action;
        test = hi.Comment;
        test = hi.CreatedDate;
        test = hi.MoreInfo;
        test = hi.RelatedDocument;
        test = hi.User;
        test = hi.UserEmail;

        CLMLock lk = new CLMLock();
        test = lk.CheckInHref;
        test = lk.IsLocked;
        test = lk.LockDate;
        test = lk.LockOwner;
        test = lk.Type;

        CLMPermissionSet ps = new CLMPermissionSet();
        test = ps.Name;
        test = ps.Permissions;
        test = ps.Href;

        CLMPermissionSetsItems psi = new CLMPermissionSetsItems();
        test = psi.Items;

        CLMSearch src = new CLMSearch();
        test = src.AllWords;
        test = src.AnyAttributeField;
        test = src.AnyWords;
        test = src.AttributeFields;
        test = src.AttributeGroups;
        test = src.Content;
        test = src.Description;
        test = src.Extensions;
        test = src.Href;
        test = src.IncludeSubFolders;
        test = src.InFolder;
        test = src.Phrase;
        test = src.Result;
        test = src.Status;
        test = src.Title;
        test = src.UpdatedBy;
        test = src.UpdatedOnOrAfter;
        test = src.UpdatedOnOrBefore;
        test = src.WithoutWords;

        CLMSecurity sec = new CLMSecurity();
        test = sec.Groups;
        test = sec.Roles;
        test = sec.Users;

        CLMShareLinks slks = new CLMShareLinks();
        test = slks.AllowNativeDownload;
        test = slks.AllowPdfDownload;
        test = slks.CreatedBy;
        test = slks.CreatedDate;
        test = slks.Document;
        test = slks.ExpirationDate;
        test = slks.Folder;
        test = slks.Href;
        test = slks.PreviewBehavior;
        test = slks.UpdatedBy;
        test = slks.UpdatedDate;
        test = slks.Url;

        CLMSharelinksItems slksi = new CLMSharelinksItems();
        test = slksi.Items;

        CLMSignatureTasks sigtsk = new CLMSignatureTasks();
        test = sigtsk.CcEmails;
        test = sigtsk.Document;
        test = sigtsk.EmailMessage;
        test = sigtsk.EmailSubject;
        test = sigtsk.ExpirationDate;
        test = sigtsk.Href;
        test = sigtsk.InPersonSigning;
        test = sigtsk.Message;
        test = sigtsk.SignaturesOrdered;
        test = sigtsk.SignerPassword;
        test = sigtsk.Status;
        test = sigtsk.ToEmails;
        test = sigtsk.WrittenRequired;

        CLMSplitDocumentTasks splt = new CLMSplitDocumentTasks();
        test = splt.DestinationDocumentName;
        test = splt.DestinationFolder;
        test = splt.Document;
        test = splt.DownloadUrl;
        test = splt.Href;
        test = splt.Message;
        test = splt.Pages;
        test = splt.ResultDocument;
        test = splt.Status;

        SpringCMItem scmi = new SpringCMItem();
        test = scmi.First;
        test = scmi.Href;
        test = scmi.ItemLimit;
        test = scmi.Last;
        test = scmi.Next;
        test = scmi.Offset;
        test = scmi.Previous;
        test = scmi.Total;

        CLMUser usr = new CLMUser();
        test = usr.UserName;
        test = usr.Email;
        test = usr.FirstName;
        test = usr.LastName;
        test = usr.Address1;
        test = usr.Address2;
        test = usr.Address3;
        test = usr.City;
        test = usr.State;
        test = usr.ZipCode;
        test = usr.Title;
        test = usr.Company;
        test = usr.Department;
        test = usr.EnableStartDate;
        test = usr.EnableEndDate;
        test = usr.FaxNumber;
        test = usr.PhoneNumber;
        test = usr.ManagedBy;
        test = usr.ManagedUsers;
        test = usr.WorkItems;
        test = usr.RecentDocuments;
        test = usr.WatchedDocumentsProcessTrackingActivities;
        test = usr.WorkflowQueues;
        test = usr.Groups;
        test = usr.SendActivationEmail;
        test = usr.Role;
        test = usr.PermissionSets;
        test = usr.Persona;
        test = usr.PortalOnly;
        test = usr.Country;
        test = usr.WatchedDocuments;
        test = usr.CreatedDate;
        test = usr.UpdatedDate;
        test = usr.ExemptFromUserSync;
        test = usr.Href;

        CLMUserActions ua = new CLMUserActions();
        test = ua.Action;
        test = ua.ActionBy;
        test = ua.AssignedBy;
        test = ua.AssignedTo;
        test = ua.Comments;
        test = ua.EndDate;
        test = ua.Output;
        test = ua.StartDate;
        test = ua.UpdatedDate;
        test = ua.WorkflowQueue;

        CLMWorkflow wf = new CLMWorkflow();
        test = wf.EndDate;
        test = wf.Href;
        test = wf.Info;
        test = wf.Name;
        test = wf.Params;
        test = wf.StartDate;
        test = wf.Status;
        test = wf.WorkflowDocuments;

        CLMWorkflowQueue wfq = new CLMWorkflowQueue();
        test = wfq.CreatedDate;
        test = wfq.Href;
        test = wfq.Name;
        test = wfq.UpdatedDate;
        test = wfq.WorkItems;

        CLMWorkItem wi = new CLMWorkItem();
        test = wi.AssignDate;
        test = wi.Assignee;
        test = wi.AssigneeInstructions;
        test = wi.CreatedDate;
        test = wi.Documents;
        test = wi.DueDate;
        test = wi.Href;
        test = wi.Name;
        test = wi.Type;
        test = wi.Workflow;
        test = wi.WorkItemUrl;

        CLMFolderItems fi = new CLMFolderItems();
        test = fi.Items;

        CLMGroupItems gi = new CLMGroupItems();
        test = gi.Items;

        CLMUserItems ui = new CLMUserItems();
        test = ui.Items;

        CLMWorkflowQueueItems wqi = new CLMWorkflowQueueItems();
        test = wqi.Items;

        CLMWorkItemItems wii = new CLMWorkItemItems();
        test = wii.Items;


    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest static void RunSalesforceAuthenticatorTests(){
        authenticator = new CMSalesforceUserAuthenticator('tets','test','https://auth.springcm.com/api/v201606/salesforce','na1');
        Test.setMock(HttpCalloutMock.class, new SpringCMHttpMockResponseGenerator());
        SpringCMFunctionalTests tests = new SpringCMFunctionalTests(authenticator);
        tests.TestAuthenticator();

    }



}