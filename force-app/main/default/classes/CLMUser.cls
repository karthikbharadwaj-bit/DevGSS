global with sharing class CLMUser {
        global string UserName { get; set; }

        global string Email { get; set; }

        global string FirstName { get; set; }

        global string LastName { get; set; }

        global string Address1 { get; set; }

        global string Address2 { get; set; }

        global string Address3 { get; set; }

        global string City { get; set; }

        global string State { get; set; }

        global string ZipCode { get; set; }

        global string Title { get; set; }

        global string Company { get; set; }

        global string Department { get; set; }

        global string EnableStartDate { get; set; }

        global string EnableEndDate { get; set; }

        global string FaxNumber { get; set; }

        global string PhoneNumber { get; set; }

        global CLMUserItems ManagedBy { get; set; }

        global CLMGroupItems ManagedUsers { get; set; }

        global CLMWorkItemItems WorkItems { get; set; }

        global CLMDocumentItems RecentDocuments { get; set; }

        global CLMDocumentProcessTrackingActivitesItems WatchedDocumentsProcessTrackingActivities { get; set; }

        global CLMWorkflowQueueItems WorkflowQueues { get; set; }

        global CLMGroupItems Groups { get; set; }

        global boolean SendActivationEmail { get; set; }

        global string Role { get; set; }

        global CLMPermissionSetsItems PermissionSets { get; set; }

        global string Persona { get; set; }

        global boolean PortalOnly { get; set; }

        global string Country { get; set; }

        global CLMDocumentItems WatchedDocuments { get; set; }

        global DateTime CreatedDate { get; set; }

        global DateTime UpdatedDate { get; set; }

        global boolean ExemptFromUserSync { get; set; }

        global string Href { get; set; }
}