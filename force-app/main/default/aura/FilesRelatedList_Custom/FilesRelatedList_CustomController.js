({
    init : function(component, event, helper) {
        var rowActions = helper.getRowActions.bind(this, component)
		 helper.getuploadedFiles(component,event, helper)
        component.set('v.columns', [
            { label: 'Title', fieldName: 'Title', type:'text'},
            { label: 'Created By', fieldName: 'CreatedByName', type: 'text' },
            { label: 'Last Modified', fieldName: 'LastModifiedDate', type: 'date',
              typeAttributes: { day: "numeric", month: "numeric", year: "numeric",hour: '2-digit', minute: '2-digit',  hour24: true }, },
            { label: 'Size', fieldName: 'size', type: 'text' },
            { type: 'action', typeAttributes: { rowActions: rowActions } }
        ]); 

    },

    UploadFinished : function(component, event, helper) {
        var uploadedFiles = event.getParam("files");
        helper.getuploadedFiles(component); 
         var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            message: uploadedFiles.length + ' File was added to the Contract',
            duration:' 5000',
            key: 'info_alt',
            type: 'success',
            mode: 'pester'
        });
        toastEvent.fire();      
    }, 
    closeModel: function(component, event, helper) {
      // Set isModalOpen attribute to false  
      component.set("v.isModalOpen", false);
   },
    nameThatButton : function(cmp, event, helper) {
    var whatAction = event.getSource().getLocalId();
        cmp.set("v.pressedButton", whatAction);
        helper.deleteFileAction(cmp,cmp.get("v.fileToDelete"),event)
        cmp.set("v.isModalOpen",false);
    },

    handleRowAction: function (cmp, event, helper) {
        var action = event.getParam('action');
        switch (action.name) {
            case 'preview':
                helper.previewFileAction(cmp,event.getParam('row').Id)
                break;
            case 'delete':
                cmp.set("v.fileToDelete",event.getParam('row').Id);
              	cmp.set("v.isModalOpen",true);
                break;
        }
    },
    
    
})