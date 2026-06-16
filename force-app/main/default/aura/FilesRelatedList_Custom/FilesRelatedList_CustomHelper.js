({
    getuploadedFiles:function(component){
        var action = component.get("c.getFiles");
        action.setParams({  
            "recordId":component.get("v.recordId")  
        });      
        action.setCallback(this,function(response){  
            var state = response.getState();  
            if(state=='SUCCESS'){  
                var result = response.getReturnValue();
                var fileList = [];
                result.forEach(function(res){
                    var data = {};
                    data.Id = res.recordId
                    data.Title = res.Title
                    data.CreatedByName = res.CreatedBy;
                    data.LastModifiedDate = res.LastModifiedDate;
                    data.hasDeletePermission = res.hasDeletePermission;

                    var fileSize = res.filesize ;
                    if(res.NoteType!='NOTE'){
                    if (fileSize < 1024){
                        data.size = fileSize + ' Bytes';
                    }else if (fileSize >= 1024 && fileSize < (1024*1024)){
                        //KB
                        fileSize = Math.round(fileSize/1024)
                        data.size= fileSize + ' KB';
                        }
                    else if (fileSize >= (1024*1024) && fileSize < (1024*1024*1024)){
                         //MB
                         fileSize = Math.round(fileSize/(1024*1024));
                         data.size= fileSize + ' MB';
                        }
                    else{
                        //GB
                        fileSize = Math.round(fileSize/(1024*1024*1024));               
                        data.size = fileSize + ' GB';
                    }
                  }      

                    fileList.push(data);
                                       
                });

                component.set("v.currentfileCount", fileList.length);
                component.set("v.data",fileList); 

       
            }  
        });  
        $A.enqueueAction(action);  
    },

   previewFileAction :function(component, recordId){ 
       var recordId1 =recordId.substr(0, 3);

       if(recordId1=='002'){
             window.open('https://rc.lightning.force.com/lightning/r/Note/'+recordId+'/view');
       }
           else if(recordId1=='00P'){
             window.open('https://rc.file.force.com/servlet/servlet.FileDownload?file='+recordId);
             }
       else{
        $A.get('e.lightning:openFiles').fire({ 
            recordIds: [recordId]
        });  
       }
    },
    
        
    deleteFileAction : function(component,documentId,event) { 
        var action = component.get("c.deleteFiles");           
        action.setParams({
            "sdocumentId":documentId            
        });  
        action.setCallback(this,function(response){  
            var state = response.getState();
            var toastEvent = $A.get("e.force:showToast");
            if(state=='SUCCESS'){  
                this.getuploadedFiles(component);
                component.set("v.Spinner", false);
        toastEvent.setParams({
            message: 'File was Deleted.',
            duration:' 5000',
            key: 'info_alt',
            type: 'success',
            mode: 'pester'
        });
        toastEvent.fire();
            }
            else if(state == 'ERROR'){
                toastEvent.setParams({
            message: 'Notes can only be deleted by System Administrator',
            duration:' 5000',
            key: 'info_alt',
            type: 'error',
            mode: 'pester'
        });
        toastEvent.fire();
            }
        });  
        $A.enqueueAction(action);  
    },

    getRowActions: function (cmp, row, doneCallback) {
        var actions = [{'label': 'Preview','name': 'preview' },
        {'label': 'Delete','name': 'delete' }];

        if (!row.hasDeletePermission) {
            actions[1].disabled = 'true';
        } 
        // simulate a trip to the server
        setTimeout($A.getCallback(function () {
            doneCallback(actions);
        }), 50);

    }
})