global with sharing class CLMUserActions {
        global CLMActionBy AssignedTo { get; set; }

        global string WorkflowQueue { get; set; }

        global string Action { get; set; }

        global string Output { get; set; }

        global string Comments { get; set; }

        global CLMActionBy AssignedBy { get; set; }

        global CLMActionBy ActionBy { get; set; }

        global string StartDate { get; set; }

        global string UpdatedDate { get; set; }

        global string EndDate { get; set; }
}