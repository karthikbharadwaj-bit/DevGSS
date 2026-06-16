({
    getCustomerList: function(component, pageNumber, pageSize) {
        var action = component.get("c.getCustomerDataController");        
        action.setParams({
            "searchKeyWord": component.get("v.searchKeyword"),
            "searchBy": component.get("v.searchBy"),
            "pageNumber": pageNumber, 
            "pageSize":pageSize
            //'countrySearchBy':component.get("v.searchByCountry")
        });
        action.setCallback(this, function(result) {            
            var state = result.getState();
            if (component.isValid() && state === "SUCCESS"){
                var resultData = result.getReturnValue();
                component.set("v.communityDetailsRecord", resultData.communityDetailsRecord);
                console.log('comm details>'+JSON.stringify(component.get("v.communityDetailsRecord")));
                console.log('isAvaya'+resultData.isAvaya);
                console.log('isMaster'+resultData.isMaster);
                var data = resultData.customerList;
                component.set("v.customerList", resultData.customerList);
                component.set("v.pageNumber", resultData.pageNumber);
                component.set("v.totalRecords", resultData.totalRecords);
                component.set("v.recordStart", resultData.recordStart);
                component.set("v.recordEnd", resultData.recordEnd);
                component.set("v.totalPages", Math.ceil(resultData.totalRecords / pageSize));
                if(resultData.isAvaya==true || resultData.isMaster==true){
                    component.set("v.ShowConAcc",true);
                }
                component.set("v.isSingleLogin",resultData.isSingleLogin);
                
            }
            
            // if storeResponse size is 0 ,display no record found message on screen.
            if (data == undefined || data == '' || data == null) {
                component.set("v.Message", true);
            } else {
                component.set("v.Message", false);
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
                "objNames": 'Account'
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
                            component.set("v.accFieldsMap", resultData.allObjFieldsMap.Account);
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
    
    selectedAccountView : function(component,accountId){  
        try{
            $A.createComponent("c:Partner_SelectedAccount",{"accountId" : accountId},
                               function(createAccountComp, status, errorMessage){
                                   if (status === "SUCCESS") {
                                       
                                       var selAcctDiv = component.find('selectedAcctDiv').get('v.body');
                                       selAcctDiv.push(createAccountComp);
                                       component.find('selectedAcctDiv').set('v.body', selAcctDiv); 
                                       
                                   }
                               });                          
        }catch(e){
            alert(e);
        }
    },    
})