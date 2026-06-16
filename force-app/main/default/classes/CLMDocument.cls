global with sharing class CLMDocument {

        global string Name { get; set; }

        global string CreatedDate { get; set; }

        global string CreatedBy { get; set; }

        global string UpdatedDate { get; set; }

        global string UpdatedBy { get; set; }

        global string Description { get; set; }

        global CLMFolder ParentFolder { get; set; }

        global string Path { get; set; }

        global CLMHistoryItems HistoryItems { get; set; }

        global Map<String, Map<String, CLMAttributeFieldValue>> AttributeGroups { get; set; }

        global CLMAccessLevel AccessLevel { get; set; }

        global long PageCount { get; set; }

        global CLMEosInfo EosParentInfo { get; set; }

        global CLMLock Lock { get; set; }

        global string Version { get; set; }

        global string PreviewUrl { get; set; }

        global CLMDocumentItems Versions { get; set; }

        global CLMSharelinksItems ShareLinks { get; set; }

        global CLMDocumentProcessTrackingActivitesItems DocumentProcessTrackingActivities { get; set; }

        // global SpringCMItem<object> DocumentReminders { get; set; }

        global CLMDocumentItems RelatedDocuments { get; set; }

        global string DownloadDocumentHref { get; set; }

        global long NativeFileSize { get; set; }

        global long PdfFileSize { get; set; }

        global string Href { get; set; }
}