({
	getContracts : function(component) {
		var action = component.get("c.getContractDetails");
        action.setParams({
                "accountId": component.get("v.recordId")
            });
        action.setCallback(this, function (result) {
                var state = result.getState();
                if (state === "SUCCESS") {
                    component.set("v.contractList",result.getReturnValue());
                    if((result.getReturnValue() == undefined) || (result.getReturnValue()=='')|| (result.getReturnValue()==null))
                    {
                        component.set("v.ContractsMessage", true);
                    }
                    else  
                    {
                        component.set("v.ContractsMessage", false);
                    }
                }
        });
        $A.enqueueAction(action);
	},
    getFilesForContracts: function(component,event,helper,contractID,listOfAttachments)
    {
        
        component.set('v.showAttachments',true);
        
        var action = component.get("c.getContractFiles");
        action.setParams({
            "recordId":contractID
        });
        action.setCallback(this, function(result) {			            
            var state = result.getState();
            if (state === "SUCCESS"){
                var resultData = result.getReturnValue();
                console.log("resultData "+result.getReturnValue());
                if(resultData != undefined && resultData !='')
                {
                    component.set("v.contractsFilesList",resultData);
                    component.set("v.ShowContractsFiles",false);
                }
                if((resultData == undefined || resultData =='' || resultData ==null)&&(listOfAttachments==undefined || listOfAttachments ==''|| listOfAttachments ==null)){
                    component.set("v.ShowContractsFiles",true);
                }
            }
            else{
                
            }
        });
        $A.enqueueAction(action); 	
    }
})