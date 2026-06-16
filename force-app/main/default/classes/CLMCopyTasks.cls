global with sharing class CLMCopyTasks {
        global CLMDocument[] DocumentsToCopy { get; set; }

        global CLMFolder[] FoldersToCopy { get; set; }

        global CLMDocument[] DocumentResults { get; set; }

        global CLMFolder[] FolderResults { get; set; }

        global Failed[] FailedDocuments { get; set; }

        global Failed[] FailedFolders { get; set; }

        global CLMDocument ResultDocument { get; set; }

        global string Message { get; set; }

        global string DownloadUrl { get; set; }

        global CLMFolder DestinationFolder { get; set; }

        global string DestinationDocumentName { get; set; }

        global string Status { get; set; }

        global string Href { get; set; }

        global class Failed
        {
            global string Source { get; set; }

            global string Reason { get; set; }
        }
}