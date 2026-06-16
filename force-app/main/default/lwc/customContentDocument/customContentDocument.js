import { LightningElement, api, track, wire } from "lwc";
import getContentDetails from "@salesforce/apex/NotesController.getContentDocumentsDetail";
import deleteDocuments from "@salesforce/apex/NotesController.deleteDocuments";
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";
import { loadStyle } from 'lightning/platformResourceLoader';
import createCustomNote from '@salesforce/apex/NotesController.createCustomNote';
import fileSelectorStyle from '@salesforce/resourceUrl/fileSelectorStyle';


const columns = [
  {
    label: "Title",
    fieldName: "Title",
    //initialWidth:185,
    //wrapText: true,
    cellAttributes: {
      iconName: { fieldName: "icon" },
      iconPosition: "left",
      class: "slds-icon slds-icon_x-medium"
    },
    iconClass: "slds-icon slds-icon_x-medium"
  },
  {
    label: "Last Modified Date",
    fieldName: "LastModifiedDate",
    initialWidth:150,
    wrapText: true,
    cellAttributes: {
      iconPosition: "left"
    }
  },
  {
    label: "Created By",
    fieldName: "CreatedBy",
    initialWidth:170,
    wrapText: true,
    
    cellAttributes: {
      iconName: "standard:user",
      iconPosition: "left"
    }
  },
  { label: "File Size", fieldName: "Size", initialWidth: 80 },
  {
    label: "Preview",
    type: "button-icon",
    initialWidth: 70,
    typeAttributes: {
      label: "",
      name: "Preview",
      variant: "brand-outline",
      iconName: "utility:preview",
      iconPosition: "center"
    }
  },
  {
    label: "Download",
    type: "button-icon",
    initialWidth: 80,
    typeAttributes: {
      label: "",
      name: "Download",
      variant: "brand",
      iconName: "action:download",
      iconPosition: "center"
    }
  },
  {
    label: "Delete",
    type: "button-icon",
    initialWidth: 60,
    typeAttributes: {
      label: "",
      name: "Delete",
      variant: "brand",
      iconName: "action:delete",
      iconPosition: "center"
    }
  }
];


export default class CustomContentDocument extends NavigationMixin(
  LightningElement
) {

  connectedCallback() {
    Promise.all([
      loadStyle(this, fileSelectorStyle)
    ]);
  }
  totalPages;
  pageSizeOptions = [5, 10];
  totalRecords = 0; //Total no.of pages
  pageNumber = 1; //Page number
  recordStart = 1;
  recordEnd = 1;
  get bDisableFirst() {
    return this.pageNumber == 1;
  }

  get bDisableLast() {
    return this.pageNumber == this.totalPages;
  }
  @api recordId;
  @api title;
  @api accept = ".csv,.doc,.xsl,.pdf,.png,.jpg,.jpeg,.docx,.doc";
  
  @track recordToDelete;
  @track isDialogVisible = false;

  @track dataList;
  @track dataList1;
  @track columnsList = columns;
  isLoading = false;
  @track showTable = false;
  @track showpagination = false;

  getBaseUrl() {
    let baseUrl = "https://" + location.host + "/";
    return baseUrl;
  }

  @track finalSyncData;
  @wire(getContentDetails, { recordId: "$recordId" })
  sysncedFiles(result) {
    this.finalSyncData = result;
    this.pageSize = this.pageSizeOptions[0];

    let imageExtensions = ["png", "jpg", "gif"];
    let supportedIconExtensions = [
      "ai",
      "attachment",
      "audio",
      "box_notes",
      "csv",
      "eps",
      "excel",
      "exe",
      "flash",
      "folder",
      "gdoc",
      "gdocs",
      "gform",
      "gpres",
      "gsheet",
      "html",
      "image",
      "keynote",
      "library_folder",
      "link",
      "mp4",
      "overlay",
      "pack",
      "pages",
      "pdf",
      "ppt",
      "psd",
      "quip_doc",
      "quip_sheet",
      "quip_slide",
      "rtf",
      "slide",
      "stypi",
      "txt",
      "unknown",
      "video",
      "visio",
      "webex",
      "word",
      "xml",
      "zip"
    ];

    this.isLoading = true;

    let { error, data } = result;
    if (data) {
      let parsedData = JSON.parse(data);

      if (parsedData == null) {
        this.showTable = false;
      } else {
        this.showTable = true;
      }
      if (this.showTable) {
        let stringifiedData = JSON.stringify(parsedData);
        let finalData = JSON.parse(stringifiedData);

        let baseUrl = this.getBaseUrl();
        finalData.forEach((file) => {
          if (file.filetype != null) {
            let fileType = file.filetype.toLowerCase();
            if (imageExtensions.includes(fileType)) {
              file.icon = "doctype:image";
            } else if (supportedIconExtensions.includes(fileType)) {
              file.icon = "doctype:" + fileType;
            } else {
              file.icon = "doctype:box_notes";
            }
          }
          if (file.NoteType == "NOTE") {
            file.icon = "standard:note";
          }
          if (file.NoteType == "CONTENT_VERSION") {
            file.ContentDocumentId = file.downloadurl;
            file.downloadUrl =
              baseUrl +
              "sfc/servlet.shepherd/document/download/" +
              file.downloadurl;
            file.fileUrl =
              baseUrl +
              "sfc/servlet.shepherd/version/renditionDownload?rendition=THUMB720BY480&versionId=" +
              file.recordid;
            file.Size = this.formatBytes(file.filesize, 2);
          } else if (file.NoteType == "ATTACHMENT") {
            file.title = file.Name;
            file.downloadUrl =
              baseUrl +
              "servlet/servlet.FileDownload?file=" +
              file.recordid +
              "&operationContext=S1";
            file.Size = this.formatBytes(file.filesize, 2);
            file.icon = "doctype:attachment";
          }
        });
        this.dataList = finalData;

        this.totalRecords = finalData ? finalData.length : "";
        this.paginationHelper();
      }
      this.isLoading = false;
    } else if (error) {
      this.isLoading = false;
    } else {
      this.isLoading = false;
    }
  }
    /*CRM - 5815 - Pagination for this EU Component - START */ 	
  nextPage() {
    this.pageNumber = this.pageNumber + 1;
    this.paginationHelper();
  }
  handleRecordsPerPage(event) {
    this.pageSize = event.target.value;
    this.paginationHelper();
  }
  previousPage() {
    this.pageNumber = this.pageNumber - 1;
    this.paginationHelper();
  }
  

  paginationHelper() {
    this.dataList1 = [];

    this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
    if (this.pageNumber <= 1) {
      this.pageNumber = 1;
    } else if (this.pageNumber >= this.totalPages) {
      this.pageNumber = this.totalPages;
    }
    this.recordStart = parseInt(((this.pageNumber-1)*this.pageSize)+1);
    this.recordEnd = parseInt(((this.pageNumber-1)*this.pageSize))+parseInt(this.pageSize); 
    if(this.recordEnd > this.totalRecords)
        {
          this.recordEnd = this.totalRecords;
        }
    for (let i = this.recordStart - 1; i < this.recordEnd; i++) {
        this.dataList1.push(this.dataList[i]);
  }
    if (this.totalRecords > 0) {
      this.showpagination = true;
    } else {
      this.showpagination = false;
    }
  }
  /*CRM - 5815 - Pagination for this EU Component - End */ 	
  formatBytes(bytes, decimals) {
    if (bytes == 0) return "0 Bytes";
    var k = 1024,
      dm = decimals || 2,
      sizes = ["Bytes", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"],
      i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + " " + sizes[i];
  }

  handleRowAction(event) {
    const actionName = event.detail.action.name;
    const row = event.detail.row;
    switch (actionName) {
      case "Preview":
        this.previewFile(row);
        break;
      case "Download":
        this.downloadFile(row);
        break;
      case "Delete":
        event.target.name = "openConfirmation";
        this.deleteFile(event);
        break;
      default:
    }
  }

  deleteFile(event) {
    const file = event.detail.row;

    if (event.target.name === "openConfirmation") {
      this.isDialogVisible = true;
      if (typeof file.ContentDocumentId === "undefined") {
        this.recordToDelete = file.recordid;
      } else {
        this.recordToDelete = file.ContentDocumentId;
      }
    } else if (event.target.name === "confirm") {
      deleteDocuments({ docIds: [this.recordToDelete] })
        .then((response) => {
          if (response == "SUCCESS") {
            this.showNotification("File deleted successfully!", "success");
            refreshApex(this.finalSyncData);
            this.isDialogVisible = false;
          } else {
            this.showNotification(
              "Somehing went wrong. Please contact admin",
              "error"
            );
          }
        })
        .catch((error) => {
          this.showNotification("File deletion failed!", "error");
        });
    } else if (event.target.name === "cancel") {
      this.isDialogVisible = false;
      this.recordToDelete = "";
    }
  }

  previewFile(file) {
    if (file.NoteType == "CONTENT_VERSION") {
      this[NavigationMixin.Navigate]({
        type: "standard__namedPage",
        attributes: {
          pageName: "filePreview"
        },
        state: {
          selectedRecordId: file.ContentDocumentId
        }
      });
    } else if (file.NoteType == "NOTE") {
      this[NavigationMixin.GenerateUrl](
        {
          type: "standard__recordPage",
          attributes: {
            recordId: file.recordid,
            url: file.downloadUrl,
            actionName: "view"
          }
        },
        false
      ).then((url) => {
        window.open(url, "_blank");
      });
    } else if (file.NoteType == "ATTACHMENT") {
      this[NavigationMixin.GenerateUrl](
        {
          type: "standard__webPage",
          attributes: {
            url: file.downloadUrl
          }
        },
        true
      ).then((url) => {
        window.open(url, "_blank");
      });
    }
  }

  downloadFile(file) {
    if (file.NoteType == "CONTENT_VERSION") {
      this[NavigationMixin.Navigate](
        {
          type: "standard__webPage",
          attributes: {
            url: file.downloadUrl
          }
        },
        false
      );
    } else if (file.NoteType == "NOTE") {
      this.showNotification("Invalid Action", "warning");
    } else if (file.NoteType == "ATTACHMENT") {
      this[NavigationMixin.Navigate](
        {
          type: "standard__webPage",
          attributes: {
            url: file.downloadUrl
          }
        },
        false
      );
    }
  }

  showNotification(message, varient) {
    const evt = new ShowToastEvent({
      title: "Notes & Attachments",
      message: message,
      variant: varient
    });
    this.dispatchEvent(evt);
  }

  handleUploadFinished(event) {
    // Get the list of uploaded files
    this.isLoading = true;
    const uploadedFiles = event.detail.files;
    let uploadedFileNames = "";
    for (let i = 0; i < uploadedFiles.length; i++) {
      uploadedFileNames += uploadedFiles[i].name + ", ";
    }
    this.dispatchEvent(
      new ShowToastEvent({
        title: "Success",
        message:
          uploadedFiles.length +
          " Files uploaded Successfully: " +
          uploadedFileNames,
        variant: "success"
      }),
      refreshApex(this.finalSyncData)
    );
    this.isLoading = false;
  }
  // CRM 5858 - Introduction of Custom Notes in this component - Start
  @track isModalOpen = false;
  @track noteTitle = '';
  @track noteContent = '';
  openModal() {
    this.isModalOpen = true;
  }
  closeModal() {
    this.isModalOpen = false;
  }
  handleTitleChange(event) {
    this.noteTitle = event.target.value;
  }
  handleContentChange(event) {
    this.noteContent =event.target.value;
  }
  createCustomNoteJS() {
      createCustomNote({ recordId: this.recordId, title: this.noteTitle, content: this.noteContent })
        .then((response) => {
          this.noteTitle = '';
          this.noteContent = '';
          if (response == "SUCCESS") {
            this.showNotification("Note created successfully!", "success");
            refreshApex(this.finalSyncData);
            this.isDialogVisible = false;
          } 
          
        }) 
        .catch((error) => {
          this.showNotification("Note creation failed!", "error");
        });
        this.isModalOpen = false;
        this.isLoading=true;
      }
}
// CRM 5858 - Introduction of Custom Notes in this component - End