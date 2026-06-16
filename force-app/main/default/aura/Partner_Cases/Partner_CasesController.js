({
    doInit : function(component, event, helper) {
        try
        {
            var url = new URL(location.href);
            component.set('v.RespectiveTabURL',url);
            var baseURL = url.href.substring(0, url.href.indexOf("/s"));   
            component.set('v.baseURL',baseURL);
            var id = url.searchParams.get('id'); 
            if(id != null && id != undefined && id !='')
            {
                component.set("v.loadingSpinner", true);
                component.set('v.listView',false);
                component.set('v.showDetail',true);
                helper.getSelectedCase(component, id);
                helper.getAttachments(component, id);
                helper.getLightningFiles(component, id);
                helper.getComments(component, id);
                helper.getEmails(component, id);
                component.set("v.loadingSpinner", false);
            }
            else
            {
                var pageNumber = 1;        
                var pageSize = 50;
                helper.getCaseList(component, pageNumber, pageSize);
            }
                 helper.getTranslations(component, event, helper);
        }
        catch(e)
        {
            console.log('error - '+e);            
        }
    },
    
    handleNext: function(component, event, helper) {
        var pageNumber = component.get("v.pageNumber");  
        var pageSize = component.find("pageSize").get("v.value");
        pageNumber++;
        helper.getCaseList(component, pageNumber, pageSize);
    },
    
    handlePrev: function(component, event, helper) {
        var pageNumber = component.get("v.pageNumber");  
        var pageSize = component.find("pageSize").get("v.value");
        pageNumber--;
        helper.getCaseList(component, pageNumber, pageSize);
    },
    
    onSelectChange: function(component, event, helper) {
        var page = 1;
        var pageSize = component.find("pageSize").get("v.value");
        helper.getCaseList(component, page, pageSize);
    },
    
    searchCases: function(component, event, helper) { 
        try
        {
            var searchField = component.find('searchField');
            var isValueMissing = searchField.get('v.validity').valueMissing;      
            if(isValueMissing) {
                searchField.showHelpMessageIfInvalid();
                searchField.focus();
            }else{       
                var pageNumber = component.get("v.pageNumber");  
                console.log('pageNumber - '+ pageNumber);  
                var pageSize = component.find("pageSize").get("v.value");
                console.log('pageSize - '+ pageSize);  
                pageNumber = 1;
                helper.getCaseList(component,pageNumber,pageSize);
            }
        }
        catch(e)
        {
            console.log('error - '+ e);
        }
    },
    
    showSpinner: function(component, event, helper) {    
        component.set("v.loadingSpinner", true);
    },
    
    hideSpinner : function(component,event,helper){ 
        console.log('hide ..');
        component.set("v.loadingSpinner", false);
    },
    
    goBackToViewList:function (component, event, helper) {
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            'url':window.location.pathname
        });
        urlEvent.fire();
    },
    
    closeSelectedEmail : function(component,event,helper){ 
        component.set("v.showSelectedEmail", false);
    },
    
    onSelectEmail : function(component,event,helper){ 
        var ctarget = event.currentTarget;
        var id = ctarget.dataset.id; 
        helper.getCaseEmail(component, id);
    }

})