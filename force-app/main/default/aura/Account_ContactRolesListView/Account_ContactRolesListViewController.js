({
    doInit : function(component, event, helper) {    
        var pageNumber = 1;        
        var pageSize = 10;   
        var accId = component.get('v.accountId');
        var accName = component.get('v.accountName');
        var action = component.get("c.getCRDataController");
        action.setParams({
            'accId':accId,
            'pageNumber': pageNumber,
            'pageSize':pageSize
        }); 
        action.setCallback(this,function(response) {
            var state = response.getState();  
            if(state === 'SUCCESS'){
                var retResponse = response.getReturnValue();
                if(retResponse != '' && retResponse != null && retResponse != undefined){
                    if(retResponse.accountContactsList.length>3)
                    {
                        component.set('v.isViewAll', true);
                    }
                    else{
                        component.set('v.isViewAll', false);
                    }
                    
                    component.set('v.ContactRolesList', retResponse.accountContactsList );
                    component.set("v.pageNumber", retResponse.pageNumber);
                    component.set("v.totalRecords", retResponse.totalRecords);
                    component.set("v.recordStart", retResponse.recordStart);
                    component.set("v.recordEnd", retResponse.recordEnd);
                    component.set("v.totalPages", Math.ceil(retResponse.totalRecords / pageSize)); 
                    
                      //To check if the edit and delete access is present for the user
                    if(retResponse.checkdeleteAccess){
                        component.set("v.deleteflag" , true);
                    }else{
                        component.set("v.deleteflag" , false);
                    }
                    
                    if(retResponse.checkeditAccess){
                        component.set("v.editflag" , true); 
                    }else{
                        component.set("v.editflag" , false);
                    }
                    if(retResponse.checkcreateAccess){
                        component.set("v.createflag" , true); 
                    }else{
                        component.set("v.createflag" , false);
                    }
                }
            }
            
        });
        $A.enqueueAction(action);
        
    },
    //METHOD WHEN PAGE NUMBER CHANGED
    onSelectChange: function(component, event, helper) {
        var accId = component.get('v.accountId');
        var pageNumber = 1;      
        var pageSize = component.find("pageSize").get("v.value");
        component.set("v.pageSize", pageSize);
        var action = component.get("c.getCRDataController");
        action.setParams({
            'accId':accId,
            'pageNumber': pageNumber,
            'pageSize':pageSize
        });        
        action.setCallback(this, function(result) { 
            var state = result.getState();
            if (state === "SUCCESS"){
                console.log('inside getlist callback success');
                var resultData = result.getReturnValue();
                if(resultData.accountContactsList != undefined && resultData.accountContactsList != ''){
                    component.set("v.ContactRolesList", resultData.accountContactsList);
                } 
                component.set("v.pageNumber", resultData.pageNumber);
                component.set("v.totalRecords", resultData.totalRecords);
                component.set("v.recordStart", resultData.recordStart);
                component.set("v.recordEnd", resultData.recordEnd);
                component.set("v.totalPages", Math.ceil(resultData.totalRecords / pageSize));
                
            }
        });        
        $A.enqueueAction(action); 
    },
    //Method for pagination
    handleNext: function(component, event, helper) {
        var accId = component.get('v.accountId');
        var pageNumber = component.get("v.pageNumber");    
        var pageSize = component.find("pageSize").get("v.value");
        pageNumber++; 
        var action = component.get("c.getCRDataController");
        action.setParams({
            'accId':accId,
            'pageNumber': pageNumber,
            'pageSize':pageSize
        });        
        action.setCallback(this, function(result) { 
            var state = result.getState();
            if (state === "SUCCESS"){
                var resultData = result.getReturnValue();
                if(resultData.accountContactsList != undefined && resultData.accountContactsList != ''){
                    component.set("v.ContactRolesList", resultData.accountContactsList);
                } 
                component.set("v.pageNumber", resultData.pageNumber);
                component.set("v.totalRecords", resultData.totalRecords);
                component.set("v.recordStart", resultData.recordStart);
                component.set("v.recordEnd", resultData.recordEnd);
                component.set("v.totalPages", Math.ceil(resultData.totalRecords / pageSize));
                
            }
        });        
        $A.enqueueAction(action);       
    },
    //Method for pagination
    handlePrev: function(component, event, helper) {
        var accId = component.get('v.accountId');
        var pageNumber = component.get("v.pageNumber");
        var pageSize = component.find("pageSize").get("v.value");
        pageNumber--;
        //helper.getSelectedList(component, event, helper,accId,pageNumber,pageSize); 
        var action = component.get("c.getCRDataController");
        action.setParams({
            'accId':accId,
            'pageNumber': pageNumber,
            'pageSize':pageSize
        });        
        action.setCallback(this, function(result) {    
            console.log('inside getlist callback');
            var state = result.getState();
            console.log('ERROR',result.getError());
            if (state === "SUCCESS"){
                console.log('inside getlist callback success');
                var resultData = result.getReturnValue();
                if(resultData.accountContactsList != undefined && resultData.accountContactsList != ''){
                    component.set("v.ContactRolesList", resultData.accountContactsList);
                } 
                component.set("v.pageNumber", resultData.pageNumber);
                component.set("v.totalRecords", resultData.totalRecords);
                component.set("v.recordStart", resultData.recordStart);
                component.set("v.recordEnd", resultData.recordEnd);
                component.set("v.totalPages", Math.ceil(resultData.totalRecords / pageSize));
            }
        });        
        $A.enqueueAction(action); 
    },
    addContactRole: function(component,event,helper){
        var recId = component.get('v.accountId');
        var url = new URL(location.href);
        var baseURL = url.href.substring(0, url.href.indexOf("/s"));
        var vfurl= baseURL+'/apex/AccountContactRoleCreation?accId='+recId;
        window.open(vfurl);
        
    },
    handleSelect: function(component,event,helper){
        var menuValue = event.detail.menuItem.get("v.label");
        var acr = event.detail.menuItem.get("v.value");
        switch(menuValue)
        {
            case "Edit":
                helper.doEdit(component,event,acr);
                break;
            case "Delete":
                helper.validateAccountContactRole(component, event, acr);
                break;
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
})