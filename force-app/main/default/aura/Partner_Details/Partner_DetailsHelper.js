({         
    getPartnerDetail: function(cmp,id) {
        var action = cmp.get("c.checkUserRole");
        action.setParams({});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                cmp.set('v.ShowRecordDetail', true);
                cmp.set('v.ShowListView', false);            
                cmp.set('v.AccountId', id); 
                var url = new URL(location.href); 
                //cmp.set('v.ShowSpinnerOpp',false);
                if(url.searchParams.get('selectedTab') == 'contactTab')
                {
                    cmp.set('v.selSubTabId','contactTab');
                }
                else
                {
                    cmp.set('v.selSubTabId','detailTab');
                }
                cmp.set('v.isAvaya', response.getReturnValue().isAvaya); 
                cmp.set('v.isMasterAgent', response.getReturnValue().isMasterAgent);
                cmp.set("v.isReadOnly", response.getReturnValue().isReadOnly);
                cmp.set("v.partnerCommunity", response.getReturnValue().partnerCommunityName);
                //cmp.set("v.partnerCommunity", response.getReturnValue().communityDetailsRecord.Brand_Name__c);

                cmp.set("v.communityDetailsRecord", response.getReturnValue().communityDetailsRecord);

                var commName = cmp.get("v.partnerCommunity");
                var masterLabel = response.getReturnValue().communityDetailsRecord.MasterLabel;
                var comm = 'RingCentral';
                if(commName.includes(comm)&&masterLabel == 'ignite'){
                    cmp.set("v.ShowOnlyRC", true);
                }
                if(commName.includes('Rainbow Office'))
                {
                    cmp.set("v.ShowOnlyALE", true);
                }
                if (commName.includes('Avaya Cloud Office')) {
                    cmp.set("v.ShowOnlyAvaya", true);
                }
				  // Added for PBC 10653
                if (commName.includes('Unify Office')) {
                    cmp.set("v.ShowOnlyAtos", true);
                 }
                 // Added for PBC 10653
                if(response.getReturnValue().isAvaya== undefined || response.getReturnValue().isAvaya == '' || response.getReturnValue().isAvaya== null){
                    cmp.set('v.ShowSpinnerOpp',false);
                }
                if(response.getReturnValue().isMasterAgent== undefined || response.getReturnValue().isMasterAgent == '' || response.getReturnValue().isMasterAgent== null){
                    cmp.set('v.ShowSpinnerOpp',false);
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
                "objNames": 'Account,Contact'
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
                            component.set("v.partnerFieldsMap", resultData.allObjFieldsMap.Account);
               				component.set("v.contactFieldsMap", resultData.allObjFieldsMap.Contact);			
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
    ContactList: function(component, event) {
        var action = component.get("c.loadListContact");
        action.setParams({ 
            'acctId':component.get("v.AccountId")
        });
        action.setCallback(this, function(response) {
           var state = response.getState();
            if (state === "SUCCESS") {     
                var data = response.getReturnValue();

                component.set('v.PartnerContactsList',data.contactWrapperLst);
                
                component.set('v.contactIds',data.contactLst);
                component.set("v.showContactListView",true);
                if(data == undefined || data == '' || data == null){
                    component.set('v.ShowSpinnerOpp',false);
                }
            }
            else{
                component.set('v.ShowSpinnerOpp',false);
            }
        });
        
        $A.enqueueAction(action);
    },
    // Function to create new contacts on server
    insertContact: function(component, event, helper) {        
        component.set("v.spinner", true);
        var contact = component.get("v.contact"); 
        contact.AccountId = component.get("v.AccountId");
        // Initializing the toast event to show toast
        var toastEvent = $A.get('e.force:showToast');
        var createAction = component.get('c.createContactRecord');
        createAction.setParams({
            newContact: contact
        });
        createAction.setCallback(this, function(response) {           
            // Getting the state from response
            var state = response.getState();
            component.set("v.spinner", false);            
            if(state === 'SUCCESS') {
                
                // Getting the response from server
                var dataMap = response.getReturnValue();
                 if(dataMap.status== undefined || dataMap.status == '' || dataMap.status== null){
                component.set('v.ShowSpinnerOpp',false);
                 }
                // Checking if the status is success
                if(dataMap.status=='success') {                    
                    toastEvent.setParams({
                        'title': 'Success!',
                        'type': 'success',
                        'mode': 'dismissable',
                        'message': dataMap.message
                    });                    
                    toastEvent.fire(); 
                    component.set("v.spinner", false);
                    component.set("v.isNewContact", false);
                    component.set('v.showContactListView',true);
                    this.ContactList(component,component.get("v.AccountId"));
                    
                    
                    
                } else if(dataMap.status=='error') {                    
                    toastEvent.setParams({
                        'title': 'Error!',
                        'type': 'error',
                        'mode': 'dismissable',
                        'message': dataMap.message
                    });                    
                    toastEvent.fire();                
                }
            } else {
                alert('Error in getting data');
                component.set("v.spinner", false);
                component.set('v.ShowSpinnerOpp',false);
            }
        });      
        $A.enqueueAction(createAction);
    },
    searchHelper: function(component,pageNumber,pageSize) {
        // show spinner message
        component.find("Id_spinner").set("v.class" , 'slds-show');        
        var action = component.get("c.loadPartnersAndUsers");
        action.setParams({ 
            'searchKeyWord': component.get("v.searchKeyword"),
            'searchBy': component.get("v.searchBy"),
            'pageNumber': pageNumber,
            'pageSize':pageSize
        });
        action.setCallback(this, function(response) {
            // hide spinner when response coming from server 
            component.find("Id_spinner").set("v.class" , 'slds-hide');
            var state = response.getState();
            if (state === "SUCCESS") {
                var returndata = response.getReturnValue();
                component.set("v.pageNumber", returndata.pageNumber);
                component.set("v.totalRecords", returndata.totalRecords);
                component.set("v.recordStart", returndata.recordStart);
                component.set("v.recordEnd", returndata.recordEnd);
                component.set("v.totalPages", Math.ceil(returndata.totalRecords / pageSize));
                component.set('v.PartnerList', returndata.listPartner); 
                component.set('v.isAvaya', returndata.isAvaya); 
                component.set('v.isLoaded', true); 
                component.set('v.isMasterAgent', returndata.isMasterAgent);
                component.set("v.isReadOnly", returndata.isReadOnly);
                component.set("v.partnerCommunity", returndata.partnerCommunityName);
                component.set("v.communityDetailsRecord", returndata.communityDetailsRecord);
				component.set("v.portalMasterName",returndata.portalTopMasterName);
                component.set("v.portalMasterPartnerId",returndata.portalTopMasterPartnerId);
				//Added for BOB Second set of Changes for JIRA - 6286 start
                var partnerinvoicedetailsmap = new Map();
                var invoiceCopyPartnerList = [];
                var settlementPartnerList = [];
                partnerinvoicedetailsmap.set('--None--','');
                partnerinvoicedetailsmap.set(returndata.portalTopMasterName,returndata.portalTopMasterPartnerId);
                if(partnerinvoicedetailsmap){
                    for(var ele of partnerinvoicedetailsmap.keys()){
                        console.log(':::::Keys:::::'+ele);
                        invoiceCopyPartnerList.push(ele);
                        settlementPartnerList.push(ele); // for PRM-55
                    }
                    console.log(':::::invoiceCopyPartnerList:::::'+invoiceCopyPartnerList);
                    if(invoiceCopyPartnerList){
                        component.set("v.invoiceCopyPartnerList",invoiceCopyPartnerList);
                    }
                    // Added for PRM- 55 start
                    if(settlementPartnerList) {
                        component.set("v.settlementPartnerList",settlementPartnerList);
                    }
                    component.set("v.settlementPartnerMap",partnerinvoicedetailsmap); // for PRM-55
                    // Added for PRM- 55 end
                    component.set("v.invoiceCopyPartnerMap",partnerinvoicedetailsmap);
                }
                //Added for BOB Second set of Changes for JIRA - 6286 end
                
                // if storeResponse size is 0 ,display no record found message on screen.
                if (returndata.listPartner == undefined || returndata.listPartner == '' || returndata.listPartner == null) {
                    component.set("v.Message", true);
                    component.set('v.ShowSpinnerOpp',false);
                } else {
                    component.set("v.Message", false);
                    //component.set('v.ShowSpinnerOpp',false);
                }
                var commName = component.get("v.partnerCommunity");
                var masterLabel = component.get("v.communityDetailsRecord").MasterLabel;
                var comm = 'RingCentral';
                if(commName.includes(comm)&& masterLabel == 'ignite'){
                    component.set("v.ShowOnlyRC", true);
                }
                if(commName.includes('Rainbow Office')){
                    component.set("v.ShowOnlyALE", true);
                }
                if(commName.includes('Unify Office'))
                {
                    component.set("v.ShowOnlyAtos", true);
                }
                  if(commName.includes('Avaya Cloud Office'))
                {
                    component.set("v.ShowOnlyAvaya", true);
                }
            }
        });
        $A.enqueueAction(action);
    }, 
    //Added for BOB Second set of Changes for JIRA - 6286 start
    getBusinessIdentity: function(component,obj,field){
        console.log('inside helper');
        var action = component.get("c.getBusinessPicklistvalues");
        action.setParams({
            'objectName':obj,
            'fieldapiname':field,
            'nullRequired':'false'
        });
        action.setCallback(this,function(Response){
            if(Response.getState() === "SUCCESS"){
                var result = Response.getReturnValue();
                var commName = component.get("v.partnerCommunity");
                console.log('::::::::result::::::'+result);
                console.log('::::::::commName::::::'+commName);
                var businessvalue = [];
                if(commName){
                    if(commName.includes('Avaya Cloud Office')){
                        console.log('::::::::inside avaya::::::'+commName);
                        console.log('::::::::inside for::::::'+result.length);
                        for(var i=0;i<result.length;i++){
                            
                            if(result[i].includes('Avaya')){
                                console.log('::::::::inside if::::::'+result[i]);
                                businessvalue.push(result[i]);
                            }                                
                        }                        
                    }
                    if(commName.includes('Rainbow Office')){
                        console.log('::::::::inside ALE::::::'+commName);
                        for(var i=0;i<result.length;i++){
                            console.log('::::::::inside for::::::'+result[i]);
                            if(result[i].includes('Rainbow')){
                                businessvalue.push(result[i]);
                            }else if(result[i].includes('Alcatel-Lucent')){
                                businessvalue.push(result[i]);
                            }                               
                        }                    
                    }
                    if(commName.includes('Unify Office')){
                        console.log('::::::::inside Atos:::::'+commName);
                        for(var i=0;i<result.length;i++){
                            console.log('::::::::inside for::::::'+result[i]);
                            if(result[i].includes('Unify')){
                                businessvalue.push(result[i]);
                            }else if(result[i].includes('Atos')){
                                businessvalue.push(result[i]);
                            }                                 
                        } 
                    }
                    console.log('::::businessvalue:::'+businessvalue);
                    console.log('::::field::::'+field);
                    if(field == 'BusinessIdentity__c'){
                        console.log('::::Business Identity::::');
                        component.set("v.BusinessIdentityValue",businessvalue);
                    }
                    if(field == 'Partner_Type__c'){
                        console.log('::::Partner Type::::');
                        component.set("v.partnerTypeListDisplayed",businessvalue);
                    }
                }
            }else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                 errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);
    },
    getListofMasterAgents : function(component,event,helper,accid){
        //var partnerinvoicedetailsmap = component.get("v.invoiceCopyPartnerMap");
        //var partnerlist = component.get("v.invoiceCopyPartnerList");
		var TopMasterName = component.get("v.portalMasterName");
        var TopMasterPartnerId = component.get("v.portalMasterPartnerId");
        var partnerMap = new Map();
        //var isNGBSHierarchyExist = false;
        var invoiceCopyPartnerList = [];
        var settlementPartnerList = [];
        partnerMap.set('--None--','');
        console.log(':::::::::::inside helper::::::::::');
        var action = component.get("c.getNGBSPartnerHierarchy");
        action.setParams({
            'AccountId' : accid
        });
        action.setCallback(this, function(response) {
            console.log(':::::response.getState():::'+response.getState());
            if (response.getState() === "SUCCESS") {
                var returndata = response.getReturnValue();
                component.set("v.Notes",returndata);
                console.log(':::::Notes:::'+component.get("v.Notes"));
                var partnerslst = returndata.split(',');
                console.log(':::::returndata:::'+returndata);
                console.log(':::::partnerslst:::'+partnerslst);
                if(partnerslst){
                for(var rec of partnerslst){
                    var output;
                    console.log(':::::inside for rec:::'+rec);
                    if(rec.includes('|')){
                        output = rec.split('|');
                        partnerMap.set(output[1],output[0]);
                        console.log(':::::output:::'+output);
                    }else{
                        partnerMap.set(TopMasterName,TopMasterPartnerId);
                    }
                }
            }
                console.log(':::::partnerMap:::'+partnerMap);
                for(var ele of partnerMap.keys()){
                    console.log(':::::KEys:::::'+ele);
                    invoiceCopyPartnerList.push(ele);
                    settlementPartnerList.push(ele); //added for PRM-55
                }
                console.log(':::::invoiceCopyPartnerList:::::'+invoiceCopyPartnerList);
               
                if(invoiceCopyPartnerList && partnerMap && settlementPartnerList){
                    component.set("v.invoiceCopyPartnerList",invoiceCopyPartnerList);
                    component.set("v.invoiceCopyPartnerMap",partnerMap);
                    component.set("v.settlementPartnerMap",partnerMap);
                    component.set("v.settlementPartnerList",settlementPartnerList);
                }
               
            }else{
                partnerMap.set(TopMasterName,TopMasterPartnerId);
                for(var ele of partnerMap.keys()){
                    console.log(':::::KEys:::::'+ele);
                    invoiceCopyPartnerList.push(ele);
                    settlementPartnerList.push(ele);
                }
                 if(invoiceCopyPartnerList && partnerMap){
                    component.set("v.invoiceCopyPartnerList",invoiceCopyPartnerList);
                    component.set("v.invoiceCopyPartnerMap",partnerMap);
                     component.set("v.settlementPartnerMap",partnerMap);
                    component.set("v.settlementPartnerList",settlementPartnerList);

                }
            }
        });
        $A.enqueueAction(action);
    },
    //Added for BOB Second set of Changes for JIRA - 6286 end
    
    getPartnerRegistrations : function (cmp,pageNumber_pr,pageSize_pr) { 
         cmp.set('v.ShowSpinnerOpp',true);
        var action = cmp.get("c.loadPartnerRegistrations");
        action.setParams({ 
            'pageNumber_pr': pageNumber_pr,
            'pageSize_pr':pageSize_pr
        });
        action.setCallback(this, function(response) {   
            var state = response.getState();
            
            if (state === "SUCCESS") {                 
                var data = response.getReturnValue(); 
                cmp.set("v.pageNumber_pr", data.pageNumber_pr);
                cmp.set("v.totalRecords_pr", data.totalRecords_pr);
                cmp.set("v.recordStart_pr", data.recordStart_pr);
                cmp.set("v.recordEnd_pr", data.recordEnd_pr);
                cmp.set("v.totalPages_pr", Math.ceil(data.totalRecords_pr / pageSize_pr));
                
                cmp.set('v.partnerRegData', data.prtnrReqList); 
                cmp.set('v.ShowSpinnerOpp',false);
                if (data.prtnrReqList == undefined || data.prtnrReqList == '' || returndata.prtnrReqList == null) {
                    cmp.set("v.MessageRegPartners", true);
                    cmp.set('v.ShowSpinnerOpp',false);
                } else {
                    cmp.set("v.MessageRegPartners", false);
                } 
            } 
            else{
                 cmp.set('v.ShowSpinnerOpp',false);
            }             
        });        
        $A.enqueueAction(action);
    },
    
    createUserforContact : function(component,event,helper){

        var contact1 = component.get('v.userContact');
        var toastEvent = $A.get('e.force:showToast');
        var action = component.get("c.createUserForContact");
        component.set('v.ShowSpinnerOpp',true); 
        
        action.setParams({ 
            'contact': contact1,
            'acctId':component.get("v.AccountId"),
            'contactsLst' : component.get("v.contactIds"),
            'userNameInput' : component.get("v.userNameInput"),
        });
        
        action.setCallback(this, function(response) {   
            var state = response.getState();
            
            if (state === "SUCCESS") { 
                var data = response.getReturnValue();
                if(data.indexOf('ERROR') != -1){
                    toastEvent.setParams({
                        'title': 'Error!',
                        'type': 'error',
                        'mode': 'dismissable',
                        'message': 'There was some issue during new Partner User creation. Please contact your admin for more details.'
                    }); 
                    toastEvent.fire();   
                }else{
                     toastEvent.setParams({
                        'title': 'Success!',
                        'type': 'success',
                        'mode': 'dismissable',
                        'message': 'Partner User has been Created Successfully'
                    });
                    toastEvent.fire();   
                }
                this.ContactList(component,event);
                component.set('v.ShowSpinnerOpp',false);
            } 
            else{
                toastEvent.setParams({
                    'title': 'Success!',
                    'type': 'success',
                    'mode': 'dismissable',
                    'message': 'There was some issue during new Partner User creation'
                });
                toastEvent.fire();   
                component.set('v.ShowSpinnerOpp',false);
            }             
        });        
        $A.enqueueAction(action);
    },
    createUserNameForNewUser : function(component,event,helper){
        var contact1 = component.get('v.userContact');
        var toastEvent = $A.get('e.force:showToast');
        var action = component.get("c.createUserNameForNewUser");
        component.set('v.ShowSpinnerOpp',true);        
        action.setParams({ 
            'contact': contact1,
        });        
        action.setCallback(this, function(response) {   
            var state = response.getState();           
            if (state === "SUCCESS") { 
                var data = response.getReturnValue();
                if(data.result.indexOf('ERROR') != -1){
                    toastEvent.setParams({
                        'title': 'Error!',
                        'type': 'error',
                        'mode': 'dismissable',
                        'message': 'There was some issue during new Partner User creation'
                    }); 
                    toastEvent.fire();   
                    component.set('v.isDuplicateUserName',false);
                }else{
                    component.set('v.createdUserName',data.userName);
                    component.set('v.isDuplicateUserName',data.isDuplicateUserName);
                    component.set('v.userNameSuffix',data.userNameSuffix);
                }
                component.set('v.ShowSpinnerOpp',false);
            } 
            else{
                toastEvent.setParams({
                    'title': 'Success!',
                    'type': 'success',
                    'mode': 'dismissable',
                    'message': 'There was some issue during new Partner User creation'
                });
                toastEvent.fire();   
                component.set('v.isDuplicateUserName',false);
                component.set('v.ShowSpinnerOpp',false);
            }             
        });        
        $A.enqueueAction(action);
    },
    verifyIfUserNameExists : function(component,userName){
        var toastEvent = $A.get('e.force:showToast');
        var action = component.get("c.verifyIfUserNameExists");
        component.set('v.ShowSpinnerOpp',true);        
        action.setParams({ 
            'userName': userName,
        });        
        action.setCallback(this, function(response) {
            var state = response.getState();            
            if (state === "SUCCESS") { 
                var data = response.getReturnValue();
                if(data.result.indexOf('ERROR') != -1){
                    toastEvent.setParams({
                        'title': 'Error!',
                        'type': 'error',
                        'mode': 'dismissable',
                        'message': 'There was some issue during new Partner User creation'
                    }); 
                    component.set('v.isDuplicateUserName',true);
                    toastEvent.fire();   
                }else{
                    component.set('v.createdUserName',data.userName);
                    component.set('v.isDuplicateUserName',data.isDuplicateUserName);
                }
                component.set('v.ShowSpinnerOpp',false);
            }else{
                toastEvent.setParams({
                    'title': 'Success!',
                    'type': 'success',
                    'mode': 'dismissable',
                    'message': 'There was some issue during new Partner User creation'
                });
                component.set('v.isDuplicateUserName',true);
                component.set('v.ShowSpinnerOpp',false);
                toastEvent.fire();                  
            }             
        });        
        $A.enqueueAction(action);
    }, 
    // Added for JIRA - 6994 start
    getCountryStateMap: function (component) {
        var action = component.get("c.getBusinessCountryStateMap");
        action.setCallback(this, function (response) {
            if (response.getState() === "SUCCESS") {
                var result = response.getReturnValue();
                var countriesAvailable;
                if(result.availableCountries != undefined)
                    countriesAvailable = result.availableCountries.sort();
                component.set('v.countriesAvailable', countriesAvailable);
                component.set('v.allCountries', countriesAvailable);
                component.set("v.countryStateMapData", result.countryStateMap);
                component.set("v.businessCountryMapData", result.mapBusinessCntry);
                if(result.BI_Set != undefined)
                	component.set("v.BusinessIdentityValue", result.BI_Set.sort());
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " +
                            errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);
    },
    refreshCountryStateMap: function(component, event, helper) {
        component.set('v.ShowSpinnerOpp',false);
        if (component.get("v.isPartnerTypeBillOnBehalf")) { 
            var businessSelected = component.get('v.selectedBusinessIdentity');
            if (businessSelected != null)
            this.onChangeBusinessIdentity(component, event, helper, businessSelected);
        } else {
        var countriesAvailable = component.get('v.allCountries');
        var selectedCountry = component.get("v.selectedCountryValue") != undefined ? component.get("v.selectedCountryValue") : countriesAvailable[0];
        var mapStateValueKeys = component.get("v.countryStateMapData");
                
        component.set('v.countriesAvailable', countriesAvailable);
        component.set("v.selectedCountryValue", selectedCountry);
        
        if (component.find("selectedCountry") != undefined) {
            component.find("selectedCountry").set("v.value", selectedCountry);
        }
        var stateValues = mapStateValueKeys[selectedCountry];
        component.set('v.mapStateValueKeys', stateValues.sort());
    }
    },
    onchangeCountry: function (component, event, helper, selctedValue) {
            var mapCountryStates = JSON.parse(JSON.stringify(component.get("v.countryStateMapData")));
            if (component.find("selectedCountry") == null) {
                return;
            }
            var statesForCountry = [];

            if (mapCountryStates[selctedValue] != undefined && mapCountryStates[selctedValue] != null)
                statesForCountry = mapCountryStates[selctedValue].sort();

            if (component.find("selectedCountry") != undefined && component.find("selectedCountry") != null) {
                component.find("selectedCountry").set("v.value", selctedValue);
            }
            component.set("v.mapStateValueKeys", statesForCountry);
            if (component.find("selectedState") != undefined && component.find("selectedState") != null) {
                component.find("selectedState").set("v.value", statesForCountry[0]);
            }
    },
    onChangeBusinessIdentity: function (component, event, helper, selectedValue) {
            var businessCntryMap = component.get("v.businessCountryMapData");
            var cntryForBusiness = businessCntryMap[selectedValue].sort();

            component.set("v.countriesAvailable", cntryForBusiness);

            this.onchangeCountry(component, event, helper, cntryForBusiness[0]);
    },
    // Added for JIRA - 6994 end
    // Added for PRM-55 start
    getSettlementTypes: function (component, obj,field) {
        var action = component.get("c.getBusinessPicklistvalues");
        action.setParams({
            'objectName':obj,
            'fieldapiname':field,
            'nullRequired':'false'
        });
        action.setCallback(this,function(Response){
            if(Response.getState() === "SUCCESS"){
                var result = Response.getReturnValue();
                component.set("v.settlementTypes",result);
                component.set("v.settlementTypesValueKeys",result);
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                 errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);
    },
    refreshSettlementTypes: function(component, event, helper, pt) {
        var settlementTypesValues = [];
        if (pt.includes('Wholesale-Reseller')) {
            for (var settlementType of component.get('v.settlementTypes')) {
                if (settlementType == 'Rebate-Greater-Of-Wholesale' || settlementType == 'Rebate-Diff-Of-Wholesale' || settlementType == 'MarkUp') {
                    settlementTypesValues.push(settlementType);
                }
            }
            component.set("v.settlementTypesValueKeys",settlementTypesValues);
        } else {
            component.set("v.settlementTypesValueKeys", component.get('v.settlementTypes'));
        }
    },
    getBillingFeedTypes: function (component) {
            var action = component.get("c.getBillingFeedTypeMap");
            action.setCallback(this, function (response) {
                    if (response.getState() === "SUCCESS") {
                        var result = response.getReturnValue();
                        component.set("v.billingFeedTypesMap", result.partnrReqbillFeedMap);
                    } else if (state === "ERROR") {
                        var errors = response.getError();
                        if (errors) {
                            if (errors[0] && errors[0].message) {
                                console.log("Error message: " +
                                    errors[0].message);
                            }
                        } else {
                            console.log("Unknown error");
                        }
                    }
            });
            $A.enqueueAction(action);        
    },
    // Added for PRM-55 end
})