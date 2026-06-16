({
    doInit : function(component, event, helper) {
        
         // get the fields API name and pass it to helper function  
        var controllingFieldAPI = component.get("v.controllingFieldAPI");
        var dependingFieldAPI = component.get("v.dependingFieldAPI");
        var objDetails = component.get("v.objDetail");
        // call the helper function
        helper.fetchPicklistValues(component,objDetails,controllingFieldAPI, dependingFieldAPI);
      
		var action=component.get("c.getOpprecord");
        var recId = component.get("v.recordId");
        action.setParams({
              "recordId":recId
        });
        action.setCallback(this, function(response){
           
            var state = response.getState();  
            console.log('State'+state);
            if(state=='SUCCESS'){
                var Opp=response.getReturnValue();
                console.log('opp'+JSON.stringify(response.getReturnValue()));
               var opportunityId = Opp.Id;
               var accountId =Opp.AccountId;
               var stage = Opp.StageName;
                
               
              component.set("v.Accountid", accountId);
                if(accountId!=null && stage!=null )
                {
                     helper.validateOppty(component, event, helper,stage, accountId);
                }
            
            }
                  });  
		 	$A.enqueueAction(action);
        },
    
    onControllerFieldChange: function(component, event, helper) { 
        console.log('test inside oncontroller');
        var controllerValueKey = event.getSource().get("v.value"); // get selected controller field value
        console.log('test inside oncontroller');
        var depnedentFieldMap = component.get("v.dependentFieldMap");
         console.log(controllerValueKey);
        console.log(depnedentFieldMap);
        
        if (controllerValueKey != '--- None ---' && controllerValueKey != 'SalesOrderExceptDesk' ) {
            console.log('IF');
            var ListOfDependentFields = depnedentFieldMap[controllerValueKey];
            console.log('ListOfDependentFields'+ListOfDependentFields);
            if(ListOfDependentFields.length > 0){
                component.set("v.bDisabledDependentFld" , false);  
                helper.fetchDepValues(component, ListOfDependentFields);    
            }else{
                component.set("v.bDisabledDependentFld" , true); 
                component.set("v.listDependingValues", ['']);
            }
        
            
        } else {
            component.set("v.listDependingValues", ['']);
            component.set("v.bDisabledDependentFld" , true);
        }
    },
    
    showSpinner: function(component, event, helper) {        
        var spinner = component.find("loadingSpinner");
        $A.util.removeClass(spinner, "slds-hide");
      },   
    hideSpinner : function(component,event,helper){           
        var spinner = component.find("loadingSpinner");
        $A.util.addClass(spinner, "slds-hide");
    },
     handleSubmit: function(component,event,helper){
        event.preventDefault(); // Prevent default submit
        
        console.log('handle handleSubmit');
        
        var value = component.get("v.value");
         console.log('value'+value);
         
         if (value='Engage Deals Desk') {
     var record = 'Sales Order Except Desk';
     }
         console.log('record'+record);
        var CaseCategory= component.get("v.CaseCategory");
         console.log('CaseCategory'+CaseCategory);
        var Type= component.get("v.Type");
         console.log('Type'+Type);
        var Priority= component.get("v.Priority");
         console.log('Priority'+Priority);
        var Urgency= component.get("v.Urgency");
         console.log('Urgency'+Urgency);
        var Oppid = component.get("v.recordId");
         console.log('Oppid'+Oppid);
        var Description = component.get("v.Description");
         console.log('Description'+Description);
           helper.opportunitycreateCaseFromOpp(component, event, helper,record,Oppid,CaseCategory,Type,Description,Priority,Urgency);
     },
    handlecancel: function(component,event,helper){
         var recId = component.get("v.recordId");
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
          "recordId":recId,
          "slideDevName": "related"
        });
        navEvt.fire();
        },
})