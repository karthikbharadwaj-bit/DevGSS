global with sharing class CLMSignatureTasks {
    
        global CLMDocument Document { get; set; }

        global string EmailSubject { get; set; }

        global string EmailMessage { get; set; }

        global string[] ToEmails { get; set; }

        global string[] CcEmails { get; set; }

        global boolean SignaturesOrdered { get; set; }

        global string ExpirationDate { get; set; }

        global string SignerPassword { get; set; }

        global boolean InPersonSigning { get; set; }

        global boolean WrittenRequired { get; set; }

        global string Message { get; set; }

        global string Status { get; set; }

        global string Href { get; set; }
}