global with sharing class CLMContact {
    
        global string Email { get; set; }

        global string FirstName { get; set; }

        global string LastName { get; set; }

        global string Address1 { get; set; }

        global string Address2 { get; set; }

        global string Address3 { get; set; }

        global string City { get; set; }

        global string State { get; set; }

        global string ZipCode { get; set; }

        global string Country { get; set; }

        global string Title { get; set; }

        global string Company { get; set; }

        global string Department { get; set; }

        global string FaxNumber { get; set; }

        global string PhoneNumber { get; set; }

        global boolean Shared { get; set; }

        global CLMGroupItems Groups { get; set; }

        global string Href { get; set; }
   
}