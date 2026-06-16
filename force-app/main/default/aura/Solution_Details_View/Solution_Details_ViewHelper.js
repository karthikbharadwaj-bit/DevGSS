({
    fetchData: function (component) {        
        component.set( 'v.mycolumns', [        
        {label: 'Record Id', fieldName: 'linkSolutionId',type: 'url', editable: false, width: '50px',
            typeAttributes:{label: { fieldName: 'Id' }, target: '_blank'}},
        {label: 'Details', fieldName: 'SolutionNote',type: 'text', editable: true}]);
                           
        var action = component.get("c.fetchSolution");
        action.setParams({
            "CaseId": component.get("v.recordId")
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                var results = response.getReturnValue();                 
                if(results.length>0){
                    results.forEach(function(record){
                        record.linkSolutionId = '/'+ record.Id;
                    });
                    component.set("v.solutionList", response.getReturnValue());
                }
            }
        });
        $A.enqueueAction(action);
        component.set("v.isLoading", false);
    },
    
    handleSaveEdition: function (component, event, helper) {
        var draftValues = event.getParam('draftValues');        
        var action = component.get("c.updateSolution");      
        action.setParams({"soln" : draftValues});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                $A.get('e.force:refreshView').fire();
                helper.fetchData(component, event, helper);
            }
            
        });
        $A.enqueueAction(action);        
    },
});