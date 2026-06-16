global with sharing class CLMFolderArchiveTasks {

    global CLMFolder BaseFolder { get; set; }

    global CLMDocumentItems DocumentsToZip { get; set; }

    global CLMFolderItems FoldersToZip { get; set; }

    global long ArchiveSize { get; set; }

    global CLMDocument ResultDocument { get; set; }

    global string Message { get; set; }

    global string DownloadUrl { get; set; }

    global CLMFolder DestinationFolder { get; set; }

    global string DestinationDocumentName { get; set; }

    global string Status { get; set; }

    global string Href { get; set; }
}