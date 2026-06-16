({
    //Get list of Opportunities
    getOppList : function(component, event, helper,pageNumber,pageSize) {
        var val =component.get("v.selectedValue");        
        var action = component.get("c.getOppDataController");
        action.setParams({
            "selectedPartnerAccount":val,
            'pageNumber': pageNumber,
            'pageSize':pageSize,
            'searchKeyWord':component.get("v.searchKeyword"),
            'searchBy': component.get("v.searchBy")
            //'countrySearchBy':component.get("v.searchByCountry")
        });
        action.setCallback(this, function(result) {            
            var state = result.getState();
            if (component.isValid() && state === "SUCCESS"){
                var resultData = result.getReturnValue();
                if(resultData.oppList == undefined){
                    component.set("v.Message", true);
                    component.set('v.ShowSpinnerOpp',false);
                } 
                else{
                    component.set("v.Message", false);
                }
                if(resultData.oppList != undefined)
                {
                    resultData.oppList.forEach(function(record){
                        record.Name =record.Name;
                    });
                    for (var i = 0; i < resultData.oppList.length; i++) { 
                        var row = resultData.oppList[i]; 
                        component.set("v.recordID", resultData.oppList[0].Id);
                        
                        if(row.AccountId){
                            row.AccountName = row.Account.Name;
                        }
                        if(row.Partner_Account__c==null){
                            row.PartnerAccount = ' ';
                        }
                        else{
                            row.PartnerAccount = row.Partner_Account__r.Name;
                        }                    
                        if(row.Partner_Contact__c==null){
                            row.PartnerContact = ' ';
                        }
                        else{
                            row.PartnerContact = row.Partner_Contact__r.Name;
                        }                                   
                        if(row.Owner.Name){
                            row.OwnerName = row.Owner.Name;
                        }
                        if(row.Portal_Cloud_Specialist__c==null){
                            row.PortalCloudSpecialist = ' ';
                        }
                        else{
                            row.PortalCloudSpecialist = row.Portal_Cloud_Specialist__r.Name;
                        } 
                        var recordtype= resultData.oppList[0].RecordTypeName__c;
                    }
                    //alert(resultData.oppList[0]);
                    component.set("v.oppList", resultData.oppList);                    
                    component.set("v.oppType", recordtype);
                } 
      
                component.set("v.pageNumber", resultData.pageNumber);
                component.set("v.totalRecords", resultData.totalRecords);
                component.set("v.recordStart", resultData.recordStart);
                component.set("v.recordEnd", resultData.recordEnd);
                component.set("v.totalPages", Math.ceil(resultData.totalRecords / pageSize));
                if (resultData.oppList == undefined) {
                    component.set("v.Message", true);
                } 
                else{
                    component.set("v.Message", false);
                }
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
                "objNames": 'Opportunity,Account'
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
                            component.set("v.oppFieldsMap", resultData.allObjFieldsMap.Opportunity);
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
    
    //Get partner account list
    getPartnerAccountList : function(component,event,helper){
        var action = component.get("c.getAccountList");
        action.setParams({
        });
        action.setCallback(this, function(result) {            
            var state = result.getState();
            console.log(state);
            component.set("v.partnerCommunity", result.getReturnValue().partnerCommunityName);
            console.log('community name - ' + result.getReturnValue().partnerCommunityName);
            if (component.isValid() && state === "SUCCESS"){
                var resultData = result.getReturnValue();
                component.set("v.communityDetailsRecord", resultData.communityDetailsRecord);
                console.log('comm details>'+JSON.stringify(component.get("v.communityDetailsRecord")));
                if(resultData.listPartnerAccounts != undefined && resultData.listPartnerAccounts.length > 0)
                {
                    component.set("v.selectedValue",resultData.listPartnerAccounts[0].Id);
                    component.set("v.partnerAccounts",resultData.listPartnerAccounts);
                    component.set("v.partnerAccountName",resultData.listPartnerAccounts[0].Name);     
                    component.set("v.accountId",resultData.listPartnerAccounts[0].Id);
                    
                    if(resultData.isAvaya==true || resultData.isMaster==true){
                        component.set('v.ShowConAcc',true);
                        component.set("v.viewAll",true);
                        var pageNumber = 1;        
                        var pageSize = 50;   
                        this.getDataForViewAll(component,helper,pageNumber,pageSize);
                    }
                    else
                    {
                        var pageNumber = 1;        
                        var pageSize = 50;   
                        this.getOppList(component, event, helper,pageNumber,pageSize); 
                    }
                    var comm = component.get("v.partnerCommunity");
                    var str = "RingCentral";
                    if(comm.includes(str)){
                        component.set("v.ShowOnlyRC", true);
                    }
                    
                    //component.set("v.ShowConAcc",resultData.isAvaya);
                }
                component.set("v.isSingleLogin",resultData.isSingleLogin);
            }
        });    
        
        $A.enqueueAction(action); 
    },
    
    gotoOppRecord: function(component, oppId, helper){
        var id_str = oppId;
        component.set('v.ShowSpinnerOpp',false);      
        component.set("v.ShowListView", false);
        $A.createComponent("c:Partner_OpportunitiesDetail",{"recordID" : id_str},
                           function(createAccountComp, status, errorMessage){
                               if (status === "SUCCESS") {                                       
                                   var selAcctDiv = component.find('oppDetailDiv').get('v.body');                                       
                                   selAcctDiv.push(createAccountComp);                                       
                                   component.find('oppDetailDiv').set('v.body', selAcctDiv);                                       
                               }
                           });   
    },
    
    createPartnerQuote : function(component, event, helper) {
        var action = component.get("c.createPartnerQuoteForUpsell");
        action.setParams({  
            accID : component.get("v.accountId")
        });
        action.setCallback(this, function(response){
            if(response.getState() == "SUCCESS"){
                window.open('https://e2euat-rc-portal.cs4.force.com/partner/s/quotetool?id='+ response.getReturnValue().Id+'&editionId='+response.getReturnValue().Product_Edition__c,'_top');
                
            }
        });
        $A.enqueueAction(action);
    },
    getDataForViewAll : function(component,helper,pageNumber,pageSize) {
        console.log()
        var action = component.get("c.getDataForViewAll");  
        action.setParams({
            'pageNumber': pageNumber,
            'pageSize':pageSize,
            'searchKeyWord':component.get("v.searchKeyword"),
            'searchBy': component.get("v.searchBy")
            //'countrySearchBy':component.get("v.searchByCountry")
        });
        action.setCallback(this, function(result) {            
            var state = result.getState();
            if (component.isValid() && state === "SUCCESS"){
                var resultData = result.getReturnValue();
                if(resultData.oppList == undefined){
                    component.set("v.Message", true);
                    component.set('v.ShowSpinnerOpp',false);
                } 
                else{
                    component.set("v.Message", false);
                }
                if(resultData.oppList != undefined)
                {
                    resultData.oppList.forEach(function(record){
                        record.Name =record.Name;
                    });
                    for (var i = 0; i < resultData.oppList.length; i++) { 
                        var row = resultData.oppList[i]; 
                        component.set("v.recordID", resultData.oppList[0].Id);
                        
                        if(row.AccountId){
                            row.AccountName = row.Account.Name;
                        }
                        if(row.Partner_Account__c==null){
                            row.PartnerAccount = ' ';
                        }
                        else{
                            row.PartnerAccount = row.Partner_Account__r.Name;
                        }                    
                        if(row.Partner_Contact__c==null){
                            row.PartnerContact = ' ';
                        }
                        else{
                            row.PartnerContact = row.Partner_Contact__r.Name;
                        }                                   
                        if(row.Owner.Name){
                            row.OwnerName = row.Owner.Name;
                        }
                        if(row.Portal_Cloud_Specialist__c==null){
                            row.PortalCloudSpecialist = ' ';
                        }
                        else{
                            row.PortalCloudSpecialist = row.Portal_Cloud_Specialist__r.Name;
                        } 
                        var recordtype= resultData.oppList[0].RecordTypeName__c;
                    }
                    component.set("v.oppList", resultData.oppList);
                    component.set("v.oppType", recordtype);
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
})