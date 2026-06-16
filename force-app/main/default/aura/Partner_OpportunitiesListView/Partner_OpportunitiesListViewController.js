({
    //Method to execute on load
    doInit : function(component, event, helper) {
        var pageNumber = 1;        
        var pageSize = 50; 
        
        // the function that reads the url parameters
        var url = new URL(location.href);
        component.set('v.RespectiveTabURL',url);
        var id = url.searchParams.get('id');    
        
        if(id != null && id != undefined && id !=''){
            helper.gotoOppRecord(component, id, helper);   
        } else{
            helper.getPartnerAccountList(component, event, helper);        
        }                    
        
        var url = new URL(location.href);            
        var baseURL = url.href.substring(0, url.href.indexOf("/s"));        
        component.set('v.baseURL',baseURL);
        helper.getTranslations(component, event, helper);
    },
    
    //Method for pagination
    handleNext: function(component, event, helper) {
        var pageNumber = component.get("v.pageNumber"); 
       var isShowConAcc = component.get("v.ShowConAcc");
        var isViewAll = false;
        if(isShowConAcc){
            isViewAll = component.find("filterType").get("v.checked");
        }
        if(isViewAll){
            var pageSize = component.find("pageSizeForAll").get("v.value");
            pageNumber++;
             helper.getDataForViewAll(component,helper,pageNumber,pageSize);
        }
        else{
            var pageSize = component.find("pageSize").get("v.value");
            pageNumber++;
             helper.getOppList(component, event, helper,pageNumber,pageSize);   
        }
        /*var pageSize = component.find("pageSize").get("v.value");
        pageNumber++;
        helper.getOppList(component, event, helper,pageNumber,pageSize); */
    },
    
    //Method to update Opportunity after Edit
    saveDetails: function(component, event, helper) {
        var oppRecord = component.get('v.OpportunityRecord');
        if(oppRecord.StageName == null || oppRecord.CloseDate == null)
        {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type": "error",
                "title":  component.get("v.translationsMap.Error"),
                "message": component.get("v.translationsMap.Please_enter_the_Stage_and_Close_Date_be")+'!',
                "mode":'dismissible'
            });
            toastEvent.fire();
        }
        else
        {
            var action = component.get("c.updateOpportunity");        
            action.setParams({
                "oppty":oppRecord
            });
            action.setCallback(this, function(result) { 
                var responsedata = result.getReturnValue();
                if(responsedata = 'Success')
                {
                    component.set("v.ShowEditSection", false);
                    component.set("v.ShowComponentButtons", true);
                    component.set("v.ShowRecordDetail", true);           
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": "success",
                        "title":  component.get("v.translationsMap.Success")+'!',
                        "message": component.get("v.translationsMap.Record_has_been_updated_successfully"),
                        "mode":'dismissible'
                    });
                    toastEvent.fire();
                }
                else
                {
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": "error",
                        "title": "Error",
                        "message": responsedata,
                        "mode":'dismissible'
                    });
                    toastEvent.fire();
                }
                
            });        
            $A.enqueueAction(action); 
        }        
    },
    //Method for pagination
    handlePrev: function(component, event, helper) {
        var pageNumber = component.get("v.pageNumber");
        var isShowConAcc = component.get("v.ShowConAcc");
        var isViewAll = false;
        if(isShowConAcc){
            isViewAll = component.find("filterType").get("v.checked");
        }
        if(isViewAll){
            var pageSize = component.find("pageSizeForAll").get("v.value");
             pageNumber--;
           helper.getDataForViewAll(component,helper,pageNumber,pageSize); 
        }
        else{
            var pageSize = component.find("pageSize").get("v.value");
             pageNumber--;
             helper.getOppList(component, event, helper,pageNumber,pageSize);  
        }
        /*var pageSize = component.find("pageSize").get("v.value");
        pageNumber--;
        helper.getOppList(component, event, helper,pageNumber,pageSize);*/  
    },
    //Method to execute on number of records per page update
    onSelectChange: function(component, event, helper) {
        var val =component.get("v.selectedValue");        
        if(val != undefined)
        {
            var isShowConAcc = component.get("v.ShowConAcc");
            var isViewAll = false;
            if(isShowConAcc){
                isViewAll = component.find("filterType").get("v.checked");
            }
            if(isViewAll){
                var pageNumber = 1;
                var pageSize = component.find("pageSizeForAll").get("v.value");        
                helper.getDataForViewAll(component,helper,pageNumber,pageSize);  
            }
            else{
                var pageNumber = 1;        
                var pageSize = component.find("pageSize").get("v.value");    
                helper.getOppList(component, event, helper,pageNumber,pageSize); 
            }
            /*var pageNumber = 1;
            var pageSize = component.find("pageSize").get("v.value");        
            helper.getOppList(component, event, helper,pageNumber,pageSize); */
        }
    },
    //Method to execute on picklist value change for partner account
    onChangeVal:function (component, event, helper) {
        var pageNumber = component.get("v.pageNumber");  
        var pageSize = component.find("pageSize").get("v.value");
        helper.getOppList(component, event, helper,pageNumber,pageSize);
        component.set("v.ShowRecordDetail", false);
    },
    //Methods to show and hide spinners
    showSpinner: function(component, event, helper) {        
        var spinner = component.find("loadingSpinner");
        $A.util.removeClass(spinner, "slds-hide");
    },
    
    hideSpinner : function(component,event,helper){           
        var spinner = component.find("loadingSpinner");
        $A.util.addClass(spinner, "slds-hide");
    },
    handleGoBackComponentEvent:function(component, event, helper) {
        var message = event.getParam("goBack");
        if(message == true){
            component.set("v.ShowRecordDetail", false);
            component.set("v.ShowListView", true);
            component.set("v.showQuotes", false);
            component.set("v.showDocuSign", false);
        }		
    },
    createAccountLookup : function(component, event, helper){
        $A.createComponent("c:Partner_LookupSearch",{"searchPartnerAccount":true},
                           function(createPartnerComponent, status, errorMessage){
                               if (status === "SUCCESS") {                	
                                   var lookupDiv = component.find('lookupSearchDiv').get('v.body');
                                   lookupDiv.push(createPartnerComponent);
                                   component.find('lookupSearchDiv').set('v.body', lookupDiv);                    
                               }
                           }
                          );       
    },
    handlePartnerComponentEvent:function(component, event, helper) {
        var conId = event.getParam("Id");
        var conName = event.getParam("Name");
        var acc = event.getParam("PartnerAccount");
        if(acc == true)
        {
            component.set('v.selectedValue',conId);
            component.set('v.partnerAccountName',conName);
            var pageNumber = component.get("v.pageNumber");  
            var pageSize = component.find("pageSize").get("v.value");
            helper.getOppList(component, event, helper,pageNumber,pageSize);
        }        
    },
    toggleFilterBy: function(component,event,helper){
        var isViewAll = component.find("filterType").get("v.checked");    
        if(isViewAll){            
            var pageNumber = 1;        
            var pageSize = 50;  
            helper.getDataForViewAll(component,helper,pageNumber,pageSize);
        }else{
            var pageNumber = 1;        
            var pageSize = 50;        
            helper.getOppList(component, event, helper,pageNumber,pageSize); 
        }
    },
    doFilterSearch : function(component, event, helper) {    
        var isShowConAcc = component.get("v.ShowConAcc");
        var isViewAll = false;
        if(isShowConAcc){
            isViewAll = component.find("filterType").get("v.checked");
        }
        if(isViewAll){            
            var pageNumber = 1;   
            var pageSize = component.find("pageSizeForAll").get("v.value");  
            helper.getDataForViewAll(component,helper,pageNumber,pageSize);                                   
        }else{
            var pageNumber = component.get("v.pageNumber");  
            var pageSize = component.find("pageSize").get("v.value"); 
            pageNumber = 1;
            helper.getOppList(component, event, helper,pageNumber,pageSize);  
        }
    },
})