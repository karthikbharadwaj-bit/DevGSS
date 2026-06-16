({  
   doInit:function(component,event,helper){  
     helper.getFileshelp(component);  
   } ,  
    downloadAttachment :function(component,event,helper){  
        var selectedItem = event.currentTarget;
        var recId = selectedItem.dataset.record;
        window.open('/servlet/servlet.FileDownload?file='+recId,'_blank');
    },
   //Open File onclick event  
   OpenFile :function(component,event,helper){  
     var rec_id = event.currentTarget.id;  
     $A.get('e.lightning:openFiles').fire({ //Lightning Openfiles event  
       recordIds: [rec_id] //file id  
     });  
   },  
   UploadFinished : function(component, event, helper) {  
     var uploadedFiles = event.getParam("files");  
     var documentId = uploadedFiles[0].documentId;  
     var fileName = uploadedFiles[0].name;  
     helper.UpdateDocument(component,event,documentId);  
     var toastEvent = $A.get("e.force:showToast");  
     toastEvent.setParams({  
       "title": "Success!",  
       "message": "File "+fileName+" Uploaded successfully."  
     });  
     toastEvent.fire();  
     /* Open File after upload  
     $A.get('e.lightning:openFiles').fire({  
       recordIds: [documentId]  
     });*/  
   },  
    doSave: function(component, event, helper) {
        if (component.find("fileId").get("v.files").length > 0) {
            helper.uploadHelper(component, event);
        } else {
            alert('Please Select a Valid File');
        }
    },
 
    handleFilesChange: function(component, event, helper) {
        var fileName = 'No File Selected..';
        if (event.getSource().get("v.files").length > 0) {
            fileName = event.getSource().get("v.files")[0]['name'];
        }
        component.set("v.fileName", fileName);
    },
 })