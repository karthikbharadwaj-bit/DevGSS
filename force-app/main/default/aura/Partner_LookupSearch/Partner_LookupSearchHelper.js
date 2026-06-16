({
	searchPartners: function(component, event, helper) {
        var action = component.get("c.getPartnerData");   
        action.setParams({
            "searchKeyWord": component.get("v.searchKeyword"),
            "isMasterPartner": component.get("v.isMasterPartner"),
            "searchBy": component.get("v.searchBy"),
            "isCurrentContactPCM":component.get("v.isCurrentContactPCM"), 
            "isSingleLogin":component.get("v.isSingleLogin"), //added for Single Login
            "isNew":component.get("v.isNew") // added for Single Login
        });
        action.setCallback(this, function(result) {            
            var state = result.getState();
            console.log('state' +state);
            if (component.isValid() && state === "SUCCESS"){
                var resultData = result.getReturnValue();
                var data = resultData.partnerContactList;
                component.set("v.partnerContactList", data); 
                component.set('v.showList',true);
            }            
            // if storeResponse size is 0 ,display no record found message on screen.
            if (data == '') {
                component.set("v.displayErrorMessage", true);
                component.set('v.errorMessage','No Records found...');
            } else if(data.length > 50){
                component.set("v.displayErrorMessage", true);
                component.set('v.errorMessage','Search query returned too many results. Please try refining your search!');
            } 
            else{
                component.set("v.displayErrorMessage", false);
            }
            
        });        
        $A.enqueueAction(action);        
    },
    
     //Translation Start
    getTranslations : function (component, event, helper) 
    {
        try
        {
            var action = component.get("c.getTranslations");
            action.setParams({
                "objNames": 'Contact'
            });
            action.setCallback(this, function (result) {
                var state = result.getState();
                if (component.isValid() && state === "SUCCESS") {
                    console.log('AllObjFields - ' + JSON.stringify(result.getReturnValue()));
                    var resultData = result.getReturnValue();
                    if(resultData != undefined && resultData != null && resultData != '')
                    {
                        if(resultData.allObjFieldsMap != undefined && resultData.allObjFieldsMap != null && 
                           resultData.allObjFieldsMap != '')
                        {
                            component.set("v.conFieldsMap", resultData.allObjFieldsMap.Contact);
                        }
                        component.set("v.translationsMap", resultData.prmLabelsMap);
                        component.set("v.PRMSpecificTranslationsMap", resultData.prmSpecificLabelsMap);
                    }
                }
            });
            $A.enqueueAction(action);
        }
        catch(e)
        {
            console.log('err - ' + e);
        } 
    },
     //Translation End
    
    searchPartnerAccounts: function(component, event, helper) {
        console.log('inside pa');
        var action = component.get("c.getPartnerAccountData");        
        action.setParams({
            "searchKeyWord": component.get("v.searchKeyword")            
        });
        action.setCallback(this, function(result) {            
            var state = result.getState();
            console.log('state' +state);
            if (component.isValid() && state === "SUCCESS"){
                var resultData = result.getReturnValue();
                var data = resultData.partnerAccountList;
                component.set("v.partnerAccountList", data); 
                component.set('v.showList',true);
            } 
            // if storeResponse size is 0 ,display no record found message on screen.
            if (data == '') {
                component.set("v.displayErrorMessage", true);
                component.set('v.errorMessage','No Records found...');
            } else if(data.length > 20){
                component.set("v.displayErrorMessage", true);
                component.set('v.errorMessage','Search query returned too many results. Please try refining your search!');
            } 
            else{
                component.set("v.displayErrorMessage", false);
            }
        });        
        $A.enqueueAction(action);        
    },
    searchPartnersSFDC: function(component, event, helper) {
        console.log('ispcm>'+component.get("v.isCurrentContactPCM"));
        console.log('isSFDC >'+component.get("v.isSFDC"));
        console.log('brand >'+component.get("v.brandName"));
        var action = component.get("c.getPartnerDataforSFDC");   
        action.setParams({
            "searchKeyWord": component.get("v.searchKeyword"),
            "searchBy": component.get("v.searchBy"),
            "isSFDC":component.get("v.isSFDC"),
            "brandName":component.get("v.brandName")
        });
        action.setCallback(this, function(result) {            
            var state = result.getState();
            console.log('state' +state);
            if (component.isValid() && state === "SUCCESS"){
                var resultData = result.getReturnValue();
                var data = resultData.partnerContactList;
                component.set("v.partnerContactList", data); 
                component.set('v.showList',true);
            }            
            // if storeResponse size is 0 ,display no record found message on screen.
            if (data == '') {
                component.set("v.displayErrorMessage", true);
                component.set('v.errorMessage','No Records found...');
            } else if(data.length > 20){
                component.set("v.displayErrorMessage", true);
                component.set('v.errorMessage','Search query returned too many results. Please try refining your search!');
            } 
            else{
                component.set("v.displayErrorMessage", false);
            }
            
        });        
        $A.enqueueAction(action);        
    },
})