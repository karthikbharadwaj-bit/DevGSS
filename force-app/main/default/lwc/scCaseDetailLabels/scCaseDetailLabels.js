import name from "@salesforce/label/c.SC_Case_Detail_name";
import accountName from "@salesforce/label/c.SC_Case_Detail_account_name";
import caseNumber from "@salesforce/label/c.SC_Case_Detail_case_number";
import created from "@salesforce/label/c.SC_Case_Detail_created";
import status from "@salesforce/label/c.SC_Case_Detail_status";
import add from "@salesforce/label/c.SC_Case_Detail_add";
import comments from "@salesforce/label/c.SC_Case_Detail_comments";
import maxFileSize from "@salesforce/label/c.SC_Case_Detail_max_file_size";
import commentsPlaceholder from "@salesforce/label/c.SC_Case_Detail_comments_placeholder";
import addComment from "@salesforce/label/c.SC_Case_Detail_add_comment";
import emptyAttachments from "@salesforce/label/c.SC_Case_Detail_empty_attachments";
import userRequiringPA from "@salesforce/label/c.SC_Case_Create_user_requiring_pa";
import firstName from "@salesforce/label/c.SC_Case_Create_firstName";
import lastName from "@salesforce/label/c.SC_Case_Create_lastName";
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
import description from "@salesforce/label/c.SC_Case_Create_description";
import duplicate from "@salesforce/label/c.SC_Case_Detail_duplicate";
import yes from "@salesforce/label/c.SC_Case_Create_yes";
import no from "@salesforce/label/c.SC_Case_Create_no";
import uploading from "@salesforce/label/c.SC_Case_Detail_uploading";
import deleteAttachment from "@salesforce/label/c.SC_Case_Detail_delete_attachment";
import deleteAttachmentSure from "@salesforce/label/c.SC_Case_Detail_delete_attachment_sure";
import errorMessage from "@salesforce/label/c.SC_Case_Create_error_message";

export const labels = {
    name: name || "Name",
    accountName: accountName || "Account Name",
    caseNumber: caseNumber || "Case Number",
    created: created || "Created",
    status: status || "Status",
    add: add || "Add",
    comments: comments || "Comments",
    maxFileSize: maxFileSize || "Up to {0}MB",
    commentsPlaceholder: commentsPlaceholder || "Write comment here...",
    addComment: addComment || "Add comment",
    emptyAttachments: emptyAttachments || "To add attachment click «+ Add»",
    userRequiringPA: userRequiringPA || "User Requiring Privacy Action",
    firstName: firstName || "First Name",
    lastName: lastName || "Last Name",
    emailPA: emailPA || "Email of user requiring privacy action",
    phonePA: phonePA || "RC Phone number (if applicable) of user requiring privacy action",
    citizenEU: citizenEU || "Is this user a Citizen or legal resident within the EU (including UK)?",
    describe: describe || "Describe Nature of Data Request",
    view: view || "View",
    download: download || "Download",
    change: change || "Change",
    delete: del || "Delete",
    analytics: analytics || "Retain Analytics Data",
    glip: glip || "Retain Glip Messages",
    description: description || "Description",
    duplicate: duplicate || "Duplicate",
    yes: yes || "Yes",
    no: no || "No",
    uploading: uploading || "Uploading file...",
    deleteAttachment: deleteAttachment || "Delete attachment",
    deleteAttachmentSure: deleteAttachmentSure || "Are you sure you want to delete this file?",
    errorMessage: errorMessage || "Something goes wrong!",
};