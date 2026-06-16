global with sharing class CLMFolderSearchTasks {
        global string Status { get; set; }

        global string AllWords { get; set; }

        global string AnyWords { get; set; }

        global string WithoutWords { get; set; }

        global string Phrase { get; set; }

        global string InFolder { get; set; }

        global boolean IncludeSubFolders { get; set; }

        global string Title { get; set; }

        global string Description { get; set; }

        global string UpdatedBy { get; set; }

        global string Href { get; set; }

        global CLMFolderItems Result { get; set; }

    
}