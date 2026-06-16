global with sharing class CLMDocumentMergeTasks {
        global CLMDocument[] DocumentsToMerge { get; set; }

        global boolean DeleteOriginals { get; set; }

        global CLMDocument ResultDocument { get; set; }

        global string Message { get; set; }

        global string DownloadUrl { get; set; }

        global CLMFolder DestinationFolder { get; set; }

        global string DestinationDocumentName { get; set; }

        global string Status { get; set; }

        global string Href { get; set; }
}