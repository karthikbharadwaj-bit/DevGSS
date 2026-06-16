({
    doInit: function(component, event, helper) {
        var url = new URL(location.href);
        component.set('v.RespectiveTabURL',url);
        var id = url.searchParams.get('id'); 
        if(id != null && id != undefined && id !='')
        {
            component.set("v.spinner", true);         
            component.set('v.isModalOpen',true);
            component.set('v.primaryContactExists',false);  
            component.set('v.listView',false);
            component.set('v.showDetail',true);
            helper.selectedAccountView(component, id);
        }
        else
        {
            var pageNumber = 1;        
        	var pageSize = 50; 
        	helper.getCustomerList(component, pageNumber, pageSize);
        }
            helper.getTranslations(component, event, helper);
    },
    
    handleNext: function(component, event, helper) {
        var pageNumber = component.get("v.pageNumber");  
        var pageSize = component.find("pageSize").get("v.value");
        pageNumber++;
        helper.getCustomerList(component, pageNumber, pageSize);
    },
    
    handleUploadFinished: function (cmp, event) {
        // Get the list of uploaded files
        var uploadedFiles = event.getParam("files"); 
        alert("Files uploaded : " + uploadedFiles.length);
    },
    
    handlePrev: function(component, event, helper) {
        var pageNumber = component.get("v.pageNumber");  
        var pageSize = component.find("pageSize").get("v.value");
        pageNumber--;
        helper.getCustomerList(component, pageNumber, pageSize);
    },
    
    onSelectChange: function(component, event, helper) {
        var page = 1;
        var pageSize = component.find("pageSize").get("v.value");
        helper.getCustomerList(component, page, pageSize);
    },    
    
    searchCustomers: function(component, event, helper) {        
        var searchField = component.find('searchField');
        var isValueMissing = searchField.get('v.validity').valueMissing;
        // if value is missing show error message and focus on field        
        if(isValueMissing) {
            searchField.showHelpMessageIfInvalid();
            searchField.focus();
        }else{
            // else call helper function            
            var pageNumber = component.get("v.pageNumber");  
            var pageSize = component.find("pageSize").get("v.value");
            pageNumber = 1;
            helper.getCustomerList(component,pageNumber,pageSize);
        }
    },
    handleGoBackComponentEvent:function(component, event, helper) {
        var message = event.getParam("goBackCustomerTab");        
        if(message == true)
        {
            component.set('v.listView',true);
            component.set('v.showDetail',false);
        }		
	},
    //METHODS TO DISPLAY SPINNER
    showSpinner: function(component, event, helper) {        
        var spinner = component.find("loadingSpinner");
        $A.util.removeClass(spinner, "slds-hide");
    },
    //METHODS TO HIDE SPINNER
    hideSpinner : function(component,event,helper){           
        var spinner = component.find("loadingSpinner");
        $A.util.addClass(spinner, "slds-hide");
    },
   
})