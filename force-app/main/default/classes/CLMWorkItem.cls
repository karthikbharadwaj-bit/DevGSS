global with sharing class CLMWorkItem {
        global string Name { get; set; }

        global string Type { get; set; }

        global CLMUser Assignee { get; set; }

        global string AssignDate { get; set; }

        global string DueDate { get; set; }

        global CLMDocumentItems Documents { get; set; }

        global string AssigneeInstructions { get; set; }

        global CLMWorkflow Workflow { get; set; }

        //global SpringCMItem<object> Selections { get; set; }

        //global SpringCMItem<string> Selected { get; set; }

        global string CreatedDate { get; set; }

        global string WorkItemUrl { get; set; }

        global string Href { get; set; }
}