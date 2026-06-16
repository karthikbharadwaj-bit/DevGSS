({
    doInit : function(component, event, helper) {    
        var pageNumber = 1;        
        var pageSize = 10;   
        var accId = component.get('v.recordId');
        var action = component.get("c.getRelatedFilesList");
        action.setParams({
            'accId':accId            
        }); 
        action.setCallback(this,function(response) {
            var state = response.getState();  
            if(state === 'SUCCESS'){
                var retResponse = response.getReturnValue();
                var paginatedList = [];
                if(retResponse != '' && retResponse != null && retResponse != undefined){ 
                    var key = function(a) { return a['createdByDateTime']; }
                    var reverse = -1;     
                    var data = retResponse.fileDetailsList;
                    data.sort(function(a,b){
                        var a = key(a) ? key(a) : '';
                        var b = key(b) ? key(b) : '';
                        return reverse * ((a>b) - (b>a));
                    }); 
                    
                    component.set('v.fileDetailList', data );                    
                    component.set("v.totalRecords", retResponse.totalRecords);
                    component.set("v.totalPages", Math.ceil(retResponse.totalRecords / pageSize)); 
					paginatedList = data.slice(pageNumber-1,pageSize);                                      
                    component.set('v.paginatedList', paginatedList );
                    component.set("v.pageNumber", pageNumber);
                    component.set("v.recordStart", pageNumber);
                    // RecordEnd not displaying logically during PageLoad - Fix - START
                    if(retResponse.totalRecords < pageSize)
                        component.set("v.recordEnd", retResponse.totalRecords);
                    else
                        component.set("v.recordEnd", pageSize);
                    // RecordEnd not displaying logically during PageLoad - Fix - END
                }
            }
            
        });
        $A.enqueueAction(action);
        
    },
    //METHOD WHEN PAGE NUMBER CHANGED
    onSelectChange: function(component, event, helper) {
        var pageNumber = 1;      
        var pageSize = component.find("pageSize").get("v.value");
        var paginatedAllList = component.get('v.fileDetailList');        
        var paginatedList = paginatedAllList.slice(parseInt(((pageNumber-1)*pageSize)),parseInt(((pageNumber-1)*pageSize))+parseInt(pageSize)); 
        component.set('v.paginatedList',paginatedList);
        component.set("v.pageSize", pageSize);        
        component.set("v.pageNumber", pageNumber);
        component.set("v.recordStart", parseInt(((pageNumber-1)*pageSize)+1));
        var recordEnd = parseInt(((pageNumber-1)*pageSize))+parseInt(pageSize); 
        if(recordEnd > component.get('v.totalRecords'))
        {
            recordEnd = component.get('v.totalRecords');
        }
        component.set("v.recordEnd", parseInt(recordEnd));
        component.set("v.totalPages", Math.ceil(component.get('v.totalRecords') / pageSize));
    },
    //Method for pagination
    handleNext: function(component, event, helper) {
        var pageNumber = component.get("v.pageNumber");    
        var pageSize = component.find("pageSize").get("v.value");
        pageNumber++; 
        var paginatedAllList = component.get('v.fileDetailList');
        var paginatedList = paginatedAllList.slice(parseInt(((pageNumber-1)*pageSize)),parseInt(((pageNumber-1)*pageSize))+parseInt(pageSize)); 
        component.set('v.paginatedList',paginatedList);
        component.set("v.pageSize", pageSize);        
        component.set("v.pageNumber", pageNumber);
        component.set("v.recordStart", parseInt(((pageNumber-1)*pageSize)+1));
        var recordEnd = parseInt(((pageNumber-1)*pageSize))+parseInt(pageSize);  
        if(recordEnd > component.get('v.totalRecords'))
        {
            recordEnd = component.get('v.totalRecords');
        }
        component.set("v.recordEnd", parseInt(recordEnd));
        component.set("v.totalPages", Math.ceil(component.get('v.totalRecords') / pageSize));    
        console.log('paginatedList>>'+JSON.stringify(paginatedList));
        console.log('paginatedAllList>>'+JSON.stringify(paginatedAllList));
    },
    //Method for pagination
    handlePrev: function(component, event, helper) {
        var pageNumber = component.get("v.pageNumber");
        var pageSize = component.find("pageSize").get("v.value");
        pageNumber--;
        var paginatedAllList = component.get('v.fileDetailList');
        var paginatedList = paginatedAllList.slice(parseInt(((pageNumber-1)*pageSize)),parseInt(((pageNumber-1)*pageSize))+parseInt(pageSize)); 
        component.set('v.paginatedList',paginatedList);
        component.set("v.pageSize", pageSize);        
        component.set("v.pageNumber", pageNumber);
        component.set("v.recordStart", parseInt(((pageNumber-1)*pageSize)+1));
        var recordEnd = parseInt(((pageNumber-1)*pageSize))+parseInt(pageSize); 
        if(recordEnd > component.get('v.totalRecords'))
        {
            recordEnd = component.get('v.totalRecords');
        }
        component.set("v.recordEnd", parseInt(recordEnd));
        component.set("v.totalPages", Math.ceil(component.get('v.totalRecords') / pageSize));
    },    
    handleSelect: function(component,event,helper){
        var menuValue = event.detail.menuItem.get("v.label");
        var complete = event.detail.menuItem.get("v.value");
        var acr = complete.split('-')[0];
        var type = complete.split('-')[1];
        switch(menuValue)
        {
            case "Delete":
                helper.doDelete(component,event,acr,type);
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