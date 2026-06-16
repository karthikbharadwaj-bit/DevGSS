({
    getuploadedFiles:function(component){
        console.log("inside get uploaded files");
        try
        {
            var parentRecordId = component.get("v.recordId");
            var action = component.get("c.getFiles");  
            action.setParams({  
                "recordId":parentRecordId  
            });      
            action.setCallback(this,function(response){  
                var state = response.getState();  
                if(state=='SUCCESS'){ 
                    var result = response.getReturnValue();           
                    component.set("v.files",result);  
                    for (var i = 0; i < result.length; i++) {
                        var row = result[i]; 
                        if(row.Title==undefined ||row.Title=='')
                            row.Title='';
                        else
                            row.Title=row.Title+'.'+row.FileType;
                    }
                    if(result == undefined || result =='' ||result ==null)
                        component.set("v.FilesMessage", true);
                    else{
                        component.set("v.FilesMessage", false);
                    }
                } 
                else{
                    component.set("v.FilesMessage", true);
                }
            }); 
            
            $A.enqueueAction(action);  
        }
        catch(e)
        {
            console.log('error - ' + e);
        }
    },
    getRecordAccess:function(component){
    try
        {
            var parentRecordId = component.get("v.recordId");
            var resultData1;
            var action = component.get("c.getUserRecordAccess");
            action.setParams({  
                "AccountChecklistId":parentRecordId  
            });
            action.setCallback(this,function(response){  
                var state = response.getState();
                resultData1 = response.getReturnValue(); 
            component.set("v.recordAccess",resultData1);
            console.log("HasReadAccess - " + component.get("v.recordAccess.HasReadAccess"));
            console.log("HasEditAccess - " + component.get("v.recordAccess.HasEditAccess"));
                if(resultData1.HasReadAccess){
                    console.log("inside has readaccess");
                    this.getuploadedFiles(component);
                }
                if(!resultData1.HasEditAccess){
                    console.log(component.get("v.FilesMessage"));
                    component.set('v.FilesMessage',true);
                    console.log(component.get("v.FilesMessage"));
                }

            });
            $A.enqueueAction(action);
        }catch(e)
        {
            console.log('error - ' + e);
        }
}
})