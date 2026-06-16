({
   
    doInit : function(component,event,helper){
        console.log('viewAllBool : ' + component.get("v.viewAllBool"));
        helper.doInitHelper(component,event,helper);
    },
    
    
    handleSortingOfRows : function(component,event,helper){
       helper.handleSortingOfRows(component,event,helper);
    },
    
    //Method to enable or disable Approve and Reject button
    handleRowSelection : function(component,event,helper){
        helper.handleRowSelection(component,event,helper);
    },
    
    //Method to Approve the selected records
    handleApproveAction : function(component,event,helper){
        helper.processSelectedRecords(component,event,helper,'Approve');
    },
    
    //Method to Reject the selected records
    handleRejectAction : function(component,event,helper){
        helper.processSelectedRecords(component,event,helper,'Reject');
    },
    loadAll : function(component, event, helper) {
        
        component.set("v.viewAllBool", true);
        //helper.getData(component, event, true,0);
        helper.navigateToViewAllMode(component, event,helper);
        
    }
})