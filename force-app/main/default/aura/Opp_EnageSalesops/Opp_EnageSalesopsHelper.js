({
	validateOppty : function(component, event, helper, stage, accountId) {
		 var action = component.get("c.opportunityvalidateOpptyBeforeSalesOPsEngagement");
        action.setParams({"oppStage" : stage,
                          "accId" : accountId});
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log("state---->" +state);
            if (state === "SUCCESS") {
                var responseFromCntrl  = response.getReturnValue();
                console.log(responseFromCntrl);
                if(responseFromCntrl='You are not able to engage salesOps if the opportunity is not in the Closed Won stage')
                {
                     var toastEvent = $A.get("e.force:showToast");
                	toastEvent.setParams({
                    "type": "error",
                    "title": "Error!",
                    "message": "You are not able to engage salesOps if the opportunity is not in the Closed Won stage",
                    "mode":'dismissible'
                	});
                toastEvent.fire();
                
                }
                if(responseFromCntrl == "error"){
                 console.log("Error==>" +responseFromCntrl);
                }

                
            }
            
        });
        $A.enqueueAction(action);

	},
    
    
    opportunitycreateCaseFromOpp : function(component, event, helper,record,Oppid,CaseCategory,Type,Description,Priority,Urgency)
    {
        console.log('inside submit helper')
        console.log('Oppid????'+Oppid);
	 var action=component.get("c.createCaseFromOpp");
        
        action.setParams({"oppId" : Oppid,
                          "caseCategory" : CaseCategory,
    					  "caseType":Type,
 						  "caseDescription":Description,
 						  "casePriority":Priority,
 						  "caseUrgency":Urgency,
					      "caseRecord":record});
  
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            
            console.log("state---->" +state);
            if (state === "SUCCESS") {
                var responseFromCntrl  = response.getReturnValue();
                var resp=JSON.parse(responseFromCntrl);
                console.log(responseFromCntrl);
                var url = resp.redirectUrl;
                console.log('resp'+resp.redirectUrl);
                var device = $A.get("$Browser.formFactor");
                 if(device == 'DESKTOP')
                    {
                        var win = window.open(url);
                    	var timer = setInterval(function () {
                            if (win.closed) {
                            	clearInterval(timer);
                            	window.location.reload(); // Refresh the parent page
                            }
                        }, 1000);
                    }
                    else
                    {
                        var urlEvent = $A.get("e.force:navigateToURL");
                        urlEvent.setParams({
                            'url': url
                        });
                        urlEvent.fire();
                    } ;
            	
                
                
                
                if(responseFromCntrl == "error"){
                 console.log("Error==>" +responseFromCntrl);
                }

                
            }
            
        });
        $A.enqueueAction(action);

	},
    
    fetchPicklistValues: function(component,objDetails,controllerField, dependentField) {
        // call the server side function  
        console.log('Inside Fetch picklist');
        var action = component.get("c.getDependentMap");
        // pass paramerters [object definition , contrller field name ,dependent field name] -
        // to server side function 
        action.setParams({
            'objDetail' : objDetails,
            'contrfieldApiName': controllerField,
            'depfieldApiName': dependentField 
        });
        //set callback   
        action.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
                //store the return response from server (map<string,List<string>>)  
                var StoreResponse = response.getReturnValue();
                
                // once set #StoreResponse to depnedentFieldMap attribute 
                component.set("v.dependentFieldMap",StoreResponse);
                console.log('fetch'+StoreResponse['Channel Operations']);
                // create a empty array for store map keys(@@--->which is controller picklist values) 
                var listOfkeys = []; // for store all map keys (controller picklist values)
                var ControllerField = []; // for store controller picklist value to set on lightning:select. 
                
                // play a for loop on Return map 
                // and fill the all map key on listOfkeys variable.
                for (var singlekey in StoreResponse) {
                    listOfkeys.push(singlekey);
                }
                
                //set the controller field value for lightning:select
                if (listOfkeys != undefined && listOfkeys.length > 0) {
                    ControllerField.push('--- None ---');
                }
                
                for (var i = 0; i < listOfkeys.length; i++) {
                    ControllerField.push(listOfkeys[i]);
                }  
                // set the ControllerField variable values to country(controller picklist field)
                //component.set("v.listControllingValues", ControllerField);
            }else{
                alert('Something went wrong..');
            }
        });
        $A.enqueueAction(action);
    },
    fetchDepValues: function(component, ListOfDependentFields) {
        // create a empty array var for store dependent picklist values for controller field  
        var dependentFields = [];
        //dependentFields.push('--- None ---');
        for (var i = 0; i < ListOfDependentFields.length; i++) {
            dependentFields.push(ListOfDependentFields[i]);
        }
        // set the dependentFields variable values to store(dependent picklist field) on lightning:select
        component.set("v.listDependingValues", dependentFields);
        
    },
})