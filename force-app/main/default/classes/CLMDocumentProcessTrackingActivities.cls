global with sharing class CLMDocumentProcessTrackingActivities {

        global string Name { get; set; }

        global string TypeName { get; set; }

        global string Status { get; set; }

        global string Output { get; set; }

        global string StageName { get; set; }

        global string StartDate { get; set; }

        global string EndDate { get; set; }

        global string DueDate { get; set; }

        global string ProcessUid { get; set; }

        global string ProcessName { get; set; }

        global string Document { get; set; }

        global CLMUserActions UserActions { get; set; }

        global string Href { get; set; }
}