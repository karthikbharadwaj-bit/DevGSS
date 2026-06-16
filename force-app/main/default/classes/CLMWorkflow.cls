global with sharing class CLMWorkflow {
        global string Name { get; set; }

        global string StartDate { get; set; }

        global string EndDate { get; set; }

        global string Status { get; set; }

        global string Info { get; set; }

        global string Params { get; set; }

        global CLMDocumentItems WorkflowDocuments { get; set; }

        global string Href { get; set; }
}