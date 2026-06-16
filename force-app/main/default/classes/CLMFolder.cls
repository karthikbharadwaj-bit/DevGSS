global with sharing class CLMFolder {
    global string Name { get; set; }

    global string CreatedDate { get; set; }

    global string CreatedBy { get; set; }

    global string UpdatedDate { get; set; }

    global string UpdatedBy { get; set; }

    global string Description { get; set; }

    global CLMFolder ParentFolder { get; set; }

    global string BrowseDocumentsUrl { get; set; }

    global CLMAccessLevel AccessLevel { get; set; }

    global CLMDocumentItems Documents { get; set; }

    global CLMFolderItems Folders { get; set; }

    global string Path { get; set; }

    global Map<String, Map<String, CLMAttributeFieldValue >> AttributeGroups { get; set; }

    global CLMEosInfo EosInfo { get; set; }

    global CLMEosInfo EosParentInfo { get; set; }

    global CLMSharelinksItems ShareLinks { get; set; }

    global CLMSecurity Security { get; set; }

    global string CreateDocumentHref { get; set; }

    global string Href { get; set; }
}