global with sharing class CLMWorkflowQueue {
    
        global string Name { get; set; }

        global string CreatedDate { get; set; }

        global string UpdatedDate { get; set; }

        global CLMWorkItemItems WorkItems { get; set; }

        global string Href { get; set; }
}