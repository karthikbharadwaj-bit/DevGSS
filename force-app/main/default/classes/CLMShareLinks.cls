global with sharing class CLMShareLinks {
        global string Url { get; set; }

        global DateTime ExpirationDate { get; set; }

        global boolean AllowNativeDownload { get; set; }

        global boolean AllowPdfDownload { get; set; }

        global string PreviewBehavior { get; set; }

        global string CreatedBy { get; set; }

        global string UpdatedBy { get; set; }

        global string CreatedDate { get; set; }

        global string UpdatedDate { get; set; }

        global CLMFolder Folder { get; set; }

        global CLMDocument Document { get; set; }

        global string Href { get; set; }
}