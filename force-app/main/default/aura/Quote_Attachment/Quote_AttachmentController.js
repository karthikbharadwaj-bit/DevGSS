({
	getExistingFiles : function (component, event, helper){
        if(component.get("v.sObjectId"))
		helper.getExistingFiles(component);
	},
	
	handleUploadFinished : function (component, event, helper) {
        helper.handleUploadFinished(component, event);
    },

    handleCancelUpload : function(component, event, helper){
	helper.handleCancelUpload(component);
    },

    handleSaveClick : function(component, event, helper){
	helper.handleSaveClick(component);
    }
})