global with sharing class CLMDocumentReminder {
        global string Name { get; set; }

        global DateTime ReminderDate { get; set; }

        global CLMContactItems RecipientContacts { get; set; }

        global CLMUserItems RecipientUsers { get; set; }

        global CLMGroupItems RecipientGroups { get; set; }

        global List<string> RecipientAdHocEmails { get; set; }

        global CLMDocument Document { get; set; }

        global string EmailSubject { get; set; }

        global string EmailBody { get; set; }

        global string EmailFromAddress { get; set; }

        global string CreatedDate { get; set; }

        global string CreatedBy { get; set; }

        global string UpdatedDate { get; set; }

        global string UpdatedBy { get; set; }

        global string Href { get; set; }
}