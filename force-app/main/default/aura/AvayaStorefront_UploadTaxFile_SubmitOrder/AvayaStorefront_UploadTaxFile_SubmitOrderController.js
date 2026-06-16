({
	myAction : function(component, event, helper) {
        try
        {
            const url = new URL(location.href);
            const recordId = url.searchParams.get("id");
            component.set("v.recordId", recordId);
            helper.getRecordAccess(component);
            //helper.getuploadedFiles(component);
        }
        catch(e)
        {
            console.log(e);
        }
	},
    handleUploadFinished:function (component, event, helper) {
        var uploadedFiles = event.getParam("files");
        var documentId = uploadedFiles[0].documentId;
        component.set("v.documentId",documentId);
        var fileName = uploadedFiles[0].name;
        component.set("v.Attachments",fileName);
        helper.getuploadedFiles(component); 
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type": "success",
            "title": "Success!",
            "message": "The file has been uploaded successfully.",
            "mode":'dismissible'
        });
        toastEvent.fire();
    },
     previewFile :function(component,event,helper){  
        var rec_id = event.currentTarget.id;  
        $A.get('e.lightning:openFiles').fire({ 
            recordIds: [rec_id]
        });  
    }    
})