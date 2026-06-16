({
    
    doInit : function(component, event, helper) {
        var pageNumber = 1;
        var pageSize = 50;
        component.set("v.ShowRecordDetail", false);
        component.set('v.ShowSpinnerQuote',true);
        var url = new URL(location.href);
        var baseURL = url.href.substring(0, url.href.indexOf("/s"));
        component.set('v.baseURL',baseURL);
        var OpportunityURLLink=baseURL +'/s/partneropportunities?id=';
        component.set('v.OpportunityURLLink',OpportunityURLLink);
        helper.getPartnerAccountList(component, event, helper);
        helper.getTranslations(component, event, helper);       
    },
    redirectTOQuoteTool : function(component, event, helper) {
        var rectarget = event.currentTarget;
        var indx = rectarget.getAttribute("class");
        var quoteRec  = component.get("v.quoteList")[indx];
        var oppType = quoteRec.Opportunity__r.Type;
        console.log('oppType>>>',oppType);
        var baseURL = component.get('v.baseURL');
        var urlLink=baseURL +'/s/quotetool?step=5&id='+quoteRec.Id;
          // BZS-5535 modified Upsell to Existing Business 
        if(oppType != 'Existing Business'){ 
            //alert(oppType);
            //window.open('/partner/s/quotetool?id='+quoteRec.Id +'&step=5','_top');
            var urlEvent = $A.get("e.force:navigateToURL");
            urlEvent.setParams({
                'url':urlLink
            });
            urlEvent.fire();
        } else {
            component.set("v.changeOrderId",quoteRec.Id);
            component.set("v.showChangeRequestCMP",true);
            component.set("v.ExistingChangeOrder", true);// Fix for CRM-4287
        }
    },
    onSelectChange: function (component, event, helper) {
        var pageNumber = 1;
        /*var pageSize = component.find("pageSize").get("v.value");
        component.set('v.ShowSpinnerLead',true);
        helper.getQuoteDataList(component, event, helper, pageNumber, pageSize,'');*/
        component.set('v.ShowSpinnerQuote',true);
        var isShowConAcc = component.get("v.ShowConAcc");
        var isViewAll = false;
        if(isShowConAcc){
            isViewAll = component.find("filterType").get("v.checked");
        }
        if(isViewAll){
            var pageNumber = 1;
            var pageSize = component.find("pageSizeForAll").get("v.value");        
            helper.getQuoteDataList(component,event,helper,pageNumber,pageSize,'ALL');
        }
        else{
            var pageNumber = 1;        
            var pageSize = component.find("pageSize").get("v.value");    
            helper.getQuoteDataList(component, event, helper, pageNumber, pageSize,''); 
        }
        
    },
    //METHOD WHEN NEXT BUTTON IS CLICKED
    handleNext: function (component, event, helper) {
        var pageNumber = component.get("v.pageNumber");
        component.set('v.ShowSpinnerQuote',true);
        var isShowConAcc = component.get("v.ShowConAcc");
        var isViewAll = false;
        if(isShowConAcc){
            isViewAll = component.find("filterType").get("v.checked");
        }
        if(isViewAll){
            var pageSize = component.find("pageSizeForAll").get("v.value");
            pageNumber++;
            helper.getQuoteDataList(component,event,helper,pageNumber,pageSize,'ALL');
        }
        else{
            var pageSize = component.find("pageSize").get("v.value");
            pageNumber++;
            helper.getQuoteDataList(component, event, helper, pageNumber, pageSize,'');
        }
        /*var pageSize = component.find("pageSize").get("v.value");
        pageNumber++;
        component.set('v.ShowSpinnerQuote',true);
        helper.getQuoteDataList(component, event, helper, pageNumber, pageSize,'');*/
    },
    //METHOD WHEN PREV BUTTON IS CLICKED
    handlePrev: function (component, event, helper) {
        var pageNumber = component.get("v.pageNumber");
        component.set('v.ShowSpinnerQuote',true);
        var isShowConAcc = component.get("v.ShowConAcc");
        var isViewAll = false;
        if(isShowConAcc){
            isViewAll = component.find("filterType").get("v.checked");
        }
        if(isViewAll){
            var pageSize = component.find("pageSizeForAll").get("v.value");
            pageNumber--;
            helper.getQuoteDataList(component,event,helper,pageNumber,pageSize,'ALL');
        }
        else{
            var pageSize = component.find("pageSize").get("v.value");
            pageNumber--;
            helper.getQuoteDataList(component, event, helper, pageNumber, pageSize,'');
        }
        /* var pageSize = component.find("pageSize").get("v.value");
        pageNumber--;
        component.set('v.ShowSpinnerQuote',true);
        helper.getQuoteDataList(component, event, helper, pageNumber, pageSize,'');*/
    },
    toggleFilterBy: function(component,event,helper){
        
        var isViewAll = component.find("filterType").get("v.checked");        
        
        component.set('v.ShowSpinnerQuote',true);
        if(isViewAll){            
            var pageNumber = 1;        
            var pageSize = 50;    
            helper.getQuoteDataList(component,event,helper,pageNumber,pageSize,'ALL');
            
        }else{
            var pageNumber = 1;        
            var pageSize = 50;        
            helper.getQuoteDataList(component, event, helper,pageNumber,pageSize,''); 
            
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
        component.set('v.ShowSpinnerQuote',true);
        if(acc == true)
        {
            component.set('v.selectedValue',conId);
            component.set('v.partnerAccountName',conName);
            var pageNumber = 1; 
            var pageSize = 50;
            
            if(component.find("pageSize") != undefined && component.find("pageSize") != null){
                pageSize =  component.find("pageSize").get("v.value");
            }
            //var pageSize = component.find("pageSize").get("v.value");
            helper.getQuoteDataList(component, event, helper,pageNumber,pageSize,'');  	 
        }              
    },
    //METHOD WHEN GO BUTTON IS CLICKED
    doFilterSearch : function(component, event, helper) {  
        
        var isShowConAcc = component.get("v.ShowConAcc");
        var isViewAll = false;
        if(isShowConAcc){
            isViewAll = component.find("filterType").get("v.checked");
        }
        component.set('v.ShowSpinnerQuote',true);
        if(isViewAll){            
            var pageNumber = 1; 
            var pageSize = component.find("pageSizeForAll").get("v.value");  
            helper.getQuoteDataList(component, event, helper,pageNumber,pageSize,'ALL');                               
        }else{
            var pageNumber = component.get("v.pageNumber");  
            var pageSize = component.find("pageSize").get("v.value"); 
            pageNumber = 1;
            helper.getQuoteDataList(component, event, helper,pageNumber,pageSize,'');   
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