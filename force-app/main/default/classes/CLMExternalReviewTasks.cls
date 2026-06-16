global with sharing class CLMExternalReviewTasks {
    
        global CLMUser Sender { get; set; }

        global CLMDocumentItems Documents { get; set; }        

        global Recipient Recipient { get; set; }

        global AlsoNotify[] AlsoNotify { get; set; }

        global string Status { get; set; }

        global string DueDate { get; set; }

        global string EmailSubject { get; set; }

        global string EmailMessage { get; set; }

        global string Comment { get; set; }

        global boolean AddSignature { get; set; }

        global string Href { get; set; }

    global class Recipient
    {
        global string Name { get; set; }

        global string Email { get; set; }
    }

    global class AlsoNotify
    {
        global string Name { get; set; }

        global string Email { get; set; }
    }
}