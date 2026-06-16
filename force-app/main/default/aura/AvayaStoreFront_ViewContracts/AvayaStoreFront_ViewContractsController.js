({
	myAction : function(component, event, helper) {
		try
        {
            const url = new URL(location.href);
            const recordId = url.searchParams.get("id");
            component.set("v.recordId", recordId);
            var baseURL = url.href.substring(0, url.href.indexOf("/s"));
            component.set('v.baseURL',baseURL);
            helper.getContracts(component);
        }catch(e){
            console.log(e);
        }
	},
    onSelectedDoc: function(component,event,helper)
    {
      var arr=[];
        component.set('v.showAttachments',true);
        component.set('v.attachmentList',arr);
        component.set('v.contractsFilesList',arr);
          console.log('inside pop');
        var ctarget = event.currentTarget;
        var id_str = ctarget.dataset.value;
        var action = component.get("c.getAttachments");
        action.setParams({
            "parentId":id_str
        });
        action.setCallback(this, function(result) {			            
            var state = result.getState();
            if (state === "SUCCESS"){
                var resultData = result.getReturnValue(); 
               if(resultData != undefined && resultData !='')
                {
                component.set("v.attachmentList",resultData);
                component.set("v.ShowContractsFiles",false);
                }
                console.log("id_str"+resultData);
                helper.getFilesForContracts(component,event,helper,id_str,resultData);
            }
            else{
                
            }
        });
        $A.enqueueAction(action); 	
    },
    previewFile :function(component,event,helper){  
        var rec_id = event.currentTarget.id;  
        $A.get('e.lightning:openFiles').fire({ 
            recordIds: [rec_id]
        });  
    },
    closeModal: function(component, event, helper) {      
        component.set('v.showAttachments', false);
    }
})