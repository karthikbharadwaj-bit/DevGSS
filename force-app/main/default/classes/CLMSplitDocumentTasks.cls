global with sharing class CLMSplitDocumentTasks {
    
    global CLMDocument Document { get; set; }

    global string Pages { get; set; }

    global CLMDocument ResultDocument { get; set; }

    global string Message { get; set; }

    global string DownloadUrl { get; set; }

    global CLMFolder DestinationFolder { get; set; }

    global string DestinationDocumentName { get; set; }

    global string Status { get; set; }

    global string Href { get; set; }
}