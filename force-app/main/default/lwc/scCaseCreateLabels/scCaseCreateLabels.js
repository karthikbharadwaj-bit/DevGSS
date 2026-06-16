import correct from "@salesforce/label/c.SC_Case_Create_correct";
import firstName from "@salesforce/label/c.SC_Case_Create_firstName";
import lastName from "@salesforce/label/c.SC_Case_Create_lastName";
import email from "@salesforce/label/c.SC_Case_Create_email";
import phone from "@salesforce/label/c.SC_Case_Create_phone";
import extension from "@salesforce/label/c.SC_Case_Create_extension";
import addTimezone from "@salesforce/label/c.SC_CaseCreate_add_timezone";
import timezonePlaceholder from "@salesforce/label/c.SC_CaseCreate_timezone_placeholder";
import timezoneHelpText from "@salesforce/label/c.SC_CaseCreate_timezone_helptext";
import callbackNumberIs from "@salesforce/label/c.SC_Case_Create_callbackNumberIs";
import callbackPhone from "@salesforce/label/c.SC_Case_Create_callbackPhone";
import yes from "@salesforce/label/c.SC_Case_Create_yes";
import no from "@salesforce/label/c.SC_Case_Create_no";
import submitNotValid from "@salesforce/label/c.SC_Case_Create_submit_not_valid";
import submitNotValidMessage from "@salesforce/label/c.SC_Case_Create_submit_not_valid_message";
import userRequiringPA from "@salesforce/label/c.SC_Case_Create_user_requiring_pa";
import emailPA from "@salesforce/label/c.SC_Case_Create_emain_pa";
import phonePA from "@salesforce/label/c.SC_Case_Create_phone_pa";
import citizenEU from "@salesforce/label/c.SC_Case_Create_citizen_eu";
import describe from "@salesforce/label/c.SC_Case_Create_describe";
import view from "@salesforce/label/c.SC_Case_Create_view";
import download from "@salesforce/label/c.SC_Case_Create_download";
import change from "@salesforce/label/c.SC_Case_Create_change";
import del from "@salesforce/label/c.SC_Case_Create_delete";
import analytics from "@salesforce/label/c.SC_Case_Create_analytics";
import glip from "@salesforce/label/c.SC_Case_Create_glip";
import comments from "@salesforce/label/c.SC_Case_Create_comments";
import attachments from "@salesforce/label/c.SC_Case_Create_attachments";
import availableattachments from "@salesforce/label/c.SC_Case_Create_available_attachments";
import missing_default from "@salesforce/label/c.SC_Case_Create_missing_default";
import missing_subject from "@salesforce/label/c.SC_Case_Create_missing_subject";
import missing_description from "@salesforce/label/c.SC_Case_Create_missing_description";
import missing_email from "@salesforce/label/c.SC_Case_Create_missing_email";
import missing_citizen from "@salesforce/label/c.SC_Case_Create_missing_citizen";
import missing_correct from "@salesforce/label/c.SC_Case_Create_missing_correct";
import missing_numbers from "@salesforce/label/c.SC_Case_Create_missing_numbers";
import missing_numbersFive from "@salesforce/label/c.SC_Case_Create_missing_five_numbers";
import productPlaceholder from "@salesforce/label/c.SC_Case_Create_product_placeholder";
import issuePlaceholder from "@salesforce/label/c.SC_Case_Create_issue_placeholder";
import productAssistancelvl1 from "@salesforce/label/c.SC_Case_Create_need_assists";
import productAssistancelvl2 from "@salesforce/label/c.SC_Case_Create_need_assists_bold";
import note from "@salesforce/label/c.SC_Case_Create_note";
import severityDefinitions from "@salesforce/label/c.SC_Case_Create_severity_definitions";
import severityPlaceholder from "@salesforce/label/c.SC_Case_Create_severity_placeholder";
import severity from "@salesforce/label/c.SC_Case_Create_severity";
import severityHelp from "@salesforce/label/c.SC_Case_Create_severity_help";
import severityHelpLink from "@salesforce/label/c.SC_Case_Create_severity_help_link";
import subject from "@salesforce/label/c.SC_Case_Create_subject";
import description from "@salesforce/label/c.SC_Case_Create_description";
import submit from "@salesforce/label/c.SC_Case_Create_submit";
import emptyQuery from "@salesforce/label/c.SC_Case_Create_empty_query";
import emptyResults from "@salesforce/label/c.SC_Case_Create_empty_results";
import updateInfo from "@salesforce/label/c.SC_Case_Create_update_info";
import secondEmail from "@salesforce/label/c.SC_Case_Create_second_email";
import missing_second_email from "@salesforce/label/c.SC_Case_Create_missing_second_email";
import missing_second_email_title from "@salesforce/label/c.SC_Case_Create_missing_second_email_title";
import emailHelp from "@salesforce/label/c.SC_Case_Create_email_help";
import copyToClipboard from "@salesforce/label/c.SC_Case_Create_copy_to_clipboard";
import copySuccessful from "@salesforce/label/c.SC_Case_Create_copy_successful";
import copyNotSupport from "@salesforce/label/c.SC_Case_Create_copy_not_support";
import errorMessage from "@salesforce/label/c.SC_Case_Create_error_message";
import submittingCase from "@salesforce/label/c.SC_Case_Create_submitting_case";

export const labels = {
    correct: correct || "The below contact information is correct",
    errorMessage: errorMessage || "Something goes wrong!",
    firstName: firstName || "First Name",
    lastName: lastName || "Last Name",
    email: email || "Email Address",
    phone: phone || "Phone",
    extension: extension || "Extension",
    addTimezone: addTimezone || "Timezone of Case Contact",
    timezonePlaceholder: timezonePlaceholder || "Please select Timezone",
    timezoneHelpText: 
        timezoneHelpText || 
        "This field will be used to assign your case to an agent working closely to your timezone.",
    callbackNumberIs: callbackNumberIs || "Callback number is the same as Phone number?",
    callbackPhone: callbackPhone || "Callback Number",
    yes: yes || "Yes",
    no: no || "No",
    submitNotValid: submitNotValid || "Some field is not filled.",
    submitNotValidMessage: submitNotValidMessage || "Check that all fields are filled in correctly.",
    userRequiringPA: userRequiringPA || "User Requiring Privacy Action",
    emailPA: emailPA || "Email of user requiring privacy action",
    phonePA: phonePA || "RC Phone number (if applicable) of user requiring privacy action",
    citizenEU: citizenEU || "Is this user a Citizen or legal resident within the EU (including UK)?",
    describe: describe || "Describe Nature of Data Request",
    view: view || "View",
    download: download || "Download",
    change: change || "Change",
    del: del || "Delete",
    delete: del || "Delete",
    analytics: analytics || "Retain Analytics Data",
    glip: glip || "Retain Glip Messages",
    comments: comments || "Comments (Please list examples)",
    attachments: attachments || "You can add attachments after the case has been created.",
    availableattachments: availableattachments || "If available, please provide attachments that can help with the investigation.",
    productPlaceholder: productPlaceholder || "Please select product area",
    issuePlaceholder: issuePlaceholder || "Please select product issue",
    productAssistancelvl1: productAssistancelvl1 || "Choose the product that best fits your issue.",
    productAssistancelvl2: productAssistancelvl2 || "Choose a category that best applies to your issue.",
    note:
        note ||
        "** Note: This Developer Platform category specifically caters to Developers working with Platform APIs and Sandbox environment **",
    severityDefinitions: severityDefinitions || "Severity Definitions",
    severityPlaceholder: severityPlaceholder || "Please select severity level",
    severity: severity || "Severity Level",
    severityHelp:
        severityHelp || " For Severity 1 cases, please call RingCentral directly. The support number can be found",
    severityHelpLink: severityHelpLink || "here",
    subject: subject || "Subject",
    description: description || "Description",
    submit: submit || "Submit",
    emptyQuery: emptyQuery || "Please enter Subject first",
    emptyResults: emptyResults || "Related articles are not found",
    updateInfo: updateInfo || "The update on the case that you have created will be sent to this email address:",
    secondEmail:
        secondEmail ||
        "If the above email address will not reach the person managing this case, please provide an alternate email address:",
    emailHelp:
        emailHelp ||
        "To update your email address, go to http://service.ringcentral.com and click ‘My Settings’ on the menu bar, then on your name and extension on the left. Update your email in the middle column, and click save.",
    copyToClipboard: copyToClipboard || "Copy to clipboard",
    copySuccessful: copySuccessful || "Copying email to clipboard was successful!",
    copyNotSupport: copyNotSupport || "Copy to clipboard is not supported in your browser",
    submittingCase: submittingCase || "Submitting the case...",
    missing: {
        correct: missing_correct || "Please indicate if your contact information is correct or not.",
        numbers: missing_numbers || "Only numbers",
        numbersFive: missing_numbersFive || "Only numbers, no longer than 5 characters",
        default: missing_default || "Please enter a value",
        subject: missing_subject || "Please enter a subject",
        description: missing_description || "Please enter a description",
        email: missing_email || "Please enter an email in the format of name@domain.name",
        citizen: missing_citizen || "This checkbox is required",
        secEmail: missing_second_email || "You did not confirm the contact email or entered it incorrectly",
        secEmailTitle: missing_second_email_title || "Wrong contact email",
    },
};