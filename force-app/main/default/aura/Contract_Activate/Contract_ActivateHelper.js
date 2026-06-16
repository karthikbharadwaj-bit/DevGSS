({
    
    handleRecordUpdated : function(component, event, helper){
        var changeType = event.getParams().changeType;
        
        if (changeType === "LOADED") {
            
            var contractStatus = component.get("v.contractRecord.Status");
            console.log('contractStatus on load : ' + contractStatus);
            
            var inactiveValues = new Array("Inactive","Trash Bin");
            var isContractActive = false;
            var isContractInacive = false;
            
            if(contractStatus == "Active"){                
                isContractActive = true;
                console.log('isContractActive : ' + isContractActive);
            }
            
            if(inactiveValues.includes(contractStatus)){
                isContractInacive = true;
                console.log('isContractInacive : ' + isContractInacive);
            }
            
            helper.saveContract(component, isContractActive, isContractInacive);
        }
        
    },
    
    saveContract : function(component, isContractActive, isContractInacive) {
        
        var tmType = '';        
        var tmMessage = '';       
        var errMsg = "";
        var toastEvent = $A.get("e.force:showToast");
        var showOuterToast = false;
        
        if(isContractActive){
            
            tmType = 'Info';
            tmMessage = 'Contract is activated already.';
            showOuterToast = true;
            
        }
        else if(isContractInacive){
            
            tmType = 'Error';
            tmMessage = 'Sorry! Cannot activate Inactive/Trash contract.';
            showOuterToast = true;
        }        
            else{
                
                component.set("v.contractRecord.Status", "Active");
                component.find("conRec").saveRecord($A.getCallback(function(saveResult) {
                    
                    if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {                
                        
                        tmType = 'Success';
                        tmMessage = 'Contract is activated successfully.';
                        
                        
                    } else if (saveResult.state === "INCOMPLETE") {
                        
                        tmType = 'Error';
                        tmMessage = 'An internal error has occured. Please contact administrator.';
                        
                    } else if (saveResult.state === "ERROR") {                     
                        
                        // saveResult.error is an array of errors, 
                        // so collect all errors into one message
                        for (var i = 0; i < saveResult.error.length; i++) {
                            errMsg += saveResult.error[i].message + "\n";
                        }
                        
                        tmType = 'Error';
                        tmMessage = errMsg;
                        
                    } else {
                        
                        errMsg = 'Unknown problem, state: ' + saveResult.state + ', error: ' + 
                            JSON.stringify(saveResult.error);
                        
                        tmType = 'Error';
                        tmMessage = errMsg;
                        
                    }
                    
                    console.log(tmType + '--'+ tmMessage);                
                    
                    toastEvent.setParams({
                        "type": tmType,            
                        "message": tmMessage,
                        "mode":'dismissible'
                    });
                    toastEvent.fire();
                    
                }));
            }
        
        if(showOuterToast){
            console.log(tmType + '--'+ tmMessage);                
            
            toastEvent.setParams({
                "type": tmType,            
                "message": tmMessage,
                "mode":'dismissible'
            });
            toastEvent.fire();
        }
        
        
        $A.get("e.force:closeQuickAction").fire();  
    }   
    
    
})