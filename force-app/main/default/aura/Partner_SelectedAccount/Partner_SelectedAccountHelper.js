({
    getSelectedAccount: function(component,accountId) {
        var actionAcct = component.get("c.getSelectedAccountDetails");          
        actionAcct.setParams({
            "accountId": accountId
        });
        actionAcct.setCallback(this, function(result) { 
            try{
                var state = result.getState();
                if (component.isValid() && state === "SUCCESS"){    
                    component.set("v.spinner", false); 
                    var resultData = result.getReturnValue();
                    //console.log('Whole wrapper>'+JSON.stringify(resultData));
                    var tempjson = JSON.parse(JSON.stringify(resultData));  
                    //console.log('Parsed wrapper>'+JSON.stringify(tempjson));
                    component.set("v.selectedAccount", JSON.parse(tempjson)); 
                    var selAcc = component.get("v.selectedAccount");   
                    component.set("v.allAccountCheckList",JSON.parse(tempjson).account.Account_Change_Requests__r);
                    //alert(selAcc);
                    component.set("v.contactsList",JSON.parse(tempjson).contactsList);                      
                    //component.set("v.opportunityList",JSON.parse(tempjson).opportunityList);                 
                    var rows = JSON.parse(tempjson).accountContactsList;
                    var preparedRows = [];                    
                    if(rows){
                        for(var i = 0; i < rows.length; i++){
                            var preparedRow = {};
                            var row = rows[i];
                            if (row.Contact){                                
                                preparedRow.Contact_Name = row.Contact.Name;
                                preparedRow.Contact_Role = row.Role;
                                preparedRow.Phone_Number = row.Contact.Phone;
                                preparedRow.Email_Address = row.Contact.Email;  
                                preparedRow.Is_Primary = row.IsPrimary;
                                preparedRow.FirstName = row.Contact.FirstName;
                                preparedRow.LastName = row.Contact.LastName;
                                preparedRow.Id = row.Id;
                                preparedRow.contactId = row.Contact.Id;
                                if(row.IsPrimary==true){
                                    component.set('v.primaryContactExists',true);
                                }
                                preparedRows.push(preparedRow);
                                
                            }
                        }        
                    }
                    component.set('v.contractList',JSON.parse(tempjson).contractList);
                    component.set('v.casesList', JSON.parse(tempjson).casesList);
                    console.log('Case List ->'+JSON.stringify(JSON.parse(tempjson).casesList));
                    console.log('opportunityList ->'+JSON.stringify(JSON.parse(tempjson).opportunityList));
                    component.set('v.accountContactsList',preparedRows);
                    component.set("v.selectedAccountId", selAcc.Id);
                    component.set("v.taxExemptions", selAcc.taxExemptions);
                    component.set("v.invoiceCard", selAcc.invoiceCard); 
                    component.set("v.isNewContact", false);
                    var accountObj = JSON.parse(tempjson).account ;
                    try{
                        var dateString = accountObj.RC_Upgrade_Date__c;
                        if(dateString != null && dateString != undefined && dateString != ''){
                            var dateObject = new Date(dateString);
                            accountObj.RC_Upgrade_Date__c = dateObject.toLocaleDateString();      
                        }
                    }catch(e){
                        console.log('Exception in Parsing Paid Data')
                    }
                    
                    
                    component.set("v.AccountRecord", accountObj);
                    if(accountObj != undefined && accountObj.Type_of_Customer_or_Prospect__c == 'Existing Premise Based Customer' && 
                    accountObj.Partner_Account__r != undefined && 
                    accountObj.Partner_Account__r.Partner_Classification__c == 'Mitel Referral' )
                    component.set("v.showMitelShare", true);//PBC-9705 P2CSharing
                    
                    //component.set("v.AccountRecord", JSON.parse(tempjson).account);
                    //var accStatus = JSON.parse(tempjson).account.RC_Account_Status__c
                    component.set("v.showOppNewBtn", JSON.parse(tempjson).showNewOppBtn);
                    component.set("v.ShowOnlyAvaya", JSON.parse(tempjson).isAvayaOnly); 
                    component.set("v.isReadOnlyProfile", JSON.parse(tempjson).isReadOnly);
                    component.set("v.partnerCommunity", JSON.parse(tempjson).partnerCommunityName);
                    component.set("v.communityDetailsRecord", JSON.parse(tempjson).communityDetailsRecord);
                    console.log('comm details>'+JSON.parse(tempjson));
                    console.log('partner comm>'+component.get("v.partnerCommunity"));
                    console.log('read>' +JSON.parse(tempjson).isReadOnly);
                    var acctChkLstsDisplay = component.get("v.selectedAccount.accountCheckLists"); 
                    console.log('acctChkLstsDisplay'+acctChkLstsDisplay);
                    var partnerComm = component.get("v.partnerCommunity");
                    var masterLabel = component.get("v.communityDetailsRecord").MasterLabel;
                    var accStatus = component.get("v.AccountRecord.RC_Account_Status__c");
                    if(accStatus === 'Paid'){
                        component.set("v.PaidAcct", true);
                    }
                    var comm = 'RingCentral';
                    if(partnerComm.includes(comm)&& masterLabel == 'ignite'){
                        component.set("v.ShowOnlyRC", true);
                    }
                    console.log('RC>'+component.get("v.ShowOnlyRC"));
                    
                    //Atos 3.0
                    var atoscomm = 'Unify Office';
                    if(partnerComm.includes(atoscomm)){
                        component.set("v.ShowOnlyAtos", true);
                    	component.set("v.ShowBI", true);//ACO 4.0                        
                    }else if(partnerComm.includes('Avaya Cloud Office') || partnerComm.includes('Rainbow Office')){
                        component.set("v.ShowBI", true);
                    }//ACO 4.0
                    if(partnerComm.includes("Rainbow Office")){
						component.set("v.isAle", true);
					}
                    console.log('Atos>'+component.get("v.ShowOnlyAtos"));
                    
                    if((acctChkLstsDisplay == undefined) || (acctChkLstsDisplay =='')|| (acctChkLstsDisplay ==null))
                    {
                        component.set("v.Message", true);
                    }
                    else  
                    {
                        component.set("v.Message", false);
                    } 
                    if((JSON.parse(tempjson).contractList == undefined) || (JSON.parse(tempjson).contractList=='')|| (JSON.parse(tempjson).contractList==null))
                    {
                        component.set("v.ContractsMessage", true);
                    }
                    else  
                    {
                        component.set("v.ContractsMessage", false);
                    } 
                    if((JSON.parse(tempjson).casesList == undefined) || (JSON.parse(tempjson).casesList=='')|| (JSON.parse(tempjson).casesList==null))
                    {
                        component.set("v.CasesMessage", true);
                    }
                    else  
                    {
                        component.set("v.CasesMessage", false);
                    } 
                    
                }
                else{
                    
                }
            }catch(e){
                alert(e);
            }
        });    
        component.set("v.showCustomerListView",true);
        $A.enqueueAction(actionAcct);  
    },
    //TranslationStart
    getTranslations:function(component,event,helper)
    {
        try
        {
            var action=component.get("c.getTranslations");
            action.setParams({
                "objNames":'Account,Contact,Opportunity,Account_Change_Request__c,Contract,Case'
            });
            action.setCallback(this,function(result){
                var state=result.getState();
                if(component.isValid() && state==="SUCCESS"){
                    console.log('AllObjFields-'+JSON.stringify(result.getReturnValue()));
                    var resultData=result.getReturnValue();
                    if(resultData != undefined && resultData != null && resultData != '')
                    {
                        if(resultData.allObjFieldsMap != undefined && resultData.allObjFieldsMap != null && 
                           resultData.allObjFieldsMap != '')
                        {
                            component.set("v.accFieldsMap",resultData.allObjFieldsMap.Account);
                            component.set("v.contactFieldsMap",resultData.allObjFieldsMap.Contact);
                            component.set("v.OppFieldsMap",resultData.allObjFieldsMap.Opportunity);
                            component.set("v.AccChangeFieldsMap",resultData.allObjFieldsMap.Account_Change_Request__c);
                            component.set("v.contractFieldsMap",resultData.allObjFieldsMap.Contract);
                            component.set("v.casesFieldsMap",resultData.allObjFieldsMap.Case);
                        }
                        component.set("v.translationsMap",resultData.prmLabelsMap);
                        component.set("v.PRMSpecificTranslationsMap",resultData.prmSpecificLabelsMap);
                    }
                }
            });
            $A.enqueueAction(action);
        }
        catch(e)
        {
            console.log('err-'+e);
        }
    },
    
    //TranslationEnd

    
    // Function to create new contacts on server
    insertContact: function(component, event, helper) {        
        component.set("v.spinner", true);
        var contact = component.get("v.contact"); 
        contact.AccountId = component.get("v.accountId");
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
                // Checking if the status is success
                if(dataMap.status=='success') {                    
                    toastEvent.setParams({
                        'title': 'Success!',
                        'type': 'success',
                        'mode': 'dismissable',
                        'message': dataMap.message
                    });                    
                    toastEvent.fire();            
                    this.getSelectedAccount(component,component.get("v.selectedAccount.Id"));
                    component.set("v.spinner", false);
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
            }
        });        
        $A.enqueueAction(createAction);
    },
    
    insertChecklistRecords: function(component, event, helper){    
        component.set("v.spinner", true);
        var selectedItem = event.currentTarget; 
        var recIndex = selectedItem.dataset.record;
        var toastEvent = $A.get('e.force:showToast');
        var acctChkLsts = component.get("v.selectedAccount.accountCheckLists");        
        var selectedAcctCheckList = acctChkLsts[recIndex];                      
        var actionAcctChkLst = component.get("c.insertAccountCheckList");                 
        actionAcctChkLst.setParams({
            "typeName": selectedAcctCheckList.typeName,
            "comments": selectedAcctCheckList.comments,
            "acctId": component.get("v.selectedAccount.Id")
        });
        
        actionAcctChkLst.setCallback(this, function(response) { 
            try{                
                var state = response.getState();
                if (component.isValid() && state === "SUCCESS"){ 
                    // Getting the response from server
                    var dataMap = response.getReturnValue();
                    if(dataMap.status=='success') {                    
                        toastEvent.setParams({
                            'title': 'Success!',
                            'type': 'success',
                            'mode': 'dismissable',
                            'message': dataMap.message
                        });                    
                        toastEvent.fire();            
                        this.getSelectedAccount(component,component.get("v.selectedAccount.Id"));
                        component.set("v.spinner", false);
                    } else if(dataMap.status=='error') {                    
                        toastEvent.setParams({
                            'title': 'Error!',
                            'type': 'error',
                            'mode': 'dismissable',
                            'message': dataMap.message
                        });                    
                        toastEvent.fire();                
                    }
                    
                    this.getSelectedAccount(component,component.get("v.selectedAccount.Id"));
                    component.set("v.spinner", false);
                }
            }catch(e){
                alert(e);
            }
        });        
        $A.enqueueAction(actionAcctChkLst); 
    },
    
    deleteChecklistRecords: function(component, event, helper){
        
        component.set("v.spinner", true);
        var selectedItem = event.currentTarget; 
        var recIndex = selectedItem.dataset.record;
        var toastEvent = $A.get('e.force:showToast');
        var acctChkLsts = component.get("v.selectedAccount.accountCheckLists");        
        var selectedAcctCheckList = acctChkLsts[recIndex];                      
        var actionAcctChkLst = component.get("c.deleteChecklistRecords");                 
        actionAcctChkLst.setParams({
            "accChkLstId": selectedAcctCheckList.id
        });                
        if(selectedAcctCheckList.isApprovalTagged){           
            toastEvent.setParams({
                'title': 'Oops!',
                'type': 'error',
                'mode': 'dismissable',
                'message': 'This Checklist is now under review for approval. You cannot delete this now.'
            });                    
            toastEvent.fire(); 
            component.set("v.spinner", false);
        }else{        
            actionAcctChkLst.setCallback(this, function(response) { 
                try{                
                    var state = response.getState();
                    if (component.isValid() && state === "SUCCESS"){ 
                        // Getting the response from server
                        var dataMap = response.getReturnValue();
                        if(dataMap.status=='success') {                    
                            toastEvent.setParams({
                                'title': 'Success!',
                                'type': 'success',
                                'mode': 'dismissable',
                                'message': selectedAcctCheckList.typeName+dataMap.message
                            });                    
                            toastEvent.fire();            
                            this.getSelectedAccount(component,component.get("v.selectedAccount.Id"));
                            component.set("v.spinner", false);
                        } else if(dataMap.status=='error') {                    
                            toastEvent.setParams({
                                'title': 'Error!',
                                'type': 'error',
                                'mode': 'dismissable',
                                'message': selectedAcctCheckList.typeName +dataMap.message
                            });                    
                            toastEvent.fire();                
                        }
                        
                        this.getSelectedAccount(component,component.get("v.selectedAccount.Id"));
                        component.set("v.spinner", false);
                    }
                }catch(e){
                    alert(e);
                }
            });        
            $A.enqueueAction(actionAcctChkLst); 
        }
    },
    getOpportunityList: function(component, event, helper){
        var showDtl = component.get('v.showOppDetail');
        var showNew = component.get('v.showNewOpp');
        
        if(showDtl == false && showNew == false){
            var acctId = component.get("v.accountId");
            var actionOppt = component.get("c.getOpportunity");  
            
            actionOppt.setParams({
                "accountId": acctId
            });
            actionOppt.setCallback(this, function(result) { 
                var state = result.getState();
                if (component.isValid() && state === "SUCCESS"){ 
                    var resultData = result.getReturnValue(); 
                    component.set("v.opportunityList",resultData); 
                }else{
                    
                }
            });
            component.set('v.showOppList',true);
            $A.enqueueAction(actionOppt);
        }        
        
    },
    updateContact: function(component, event, helper){
        var acctId = component.get("v.accountId");
        var editContact = component.get("v.editcontact");
        var actionUpdate = component.get("c.updateAccountContactRole");
        
        actionUpdate.setParams({
            "accountId": acctId,
            "FirstName" : editContact.FirstName,
            "LastName":editContact.LastName,
            "Email":editContact.Email,
            "Phone":editContact.Phone,
            "CustomerRole":editContact.RC_Customer_Role__c,
            "Target_Account_Primary_Member":editContact.Target_Account_Primary_Member__c,
            "accContactRoleId":editContact.Id,
            "contactId" : editContact.contactId
        });
        actionUpdate.setCallback(this, function(result) { 
            var state = result.getState();
            var toastEvent = $A.get('e.force:showToast');
            var resultData = result.getReturnValue(); 
            if (state == "SUCCESS" && resultData.indexOf('Success') != -1){ 
                
                resultData = result.getReturnValue(); 
                toastEvent.setParams({
                    'title': 'Success!',
                    'type': 'success',
                    'mode': 'dismissable',
                    'message': resultData
                });                    
                toastEvent.fire();
                var acctId = component.get("v.accountId")
                component.set('v.isActive',false);
                component.set("v.spinner", false);         
                helper.getSelectedAccount(component, acctId);
                //component.set("v.showCustomerListView",false);
                component.set("v.isEditContact",false);
                component.set('v.isActive',false);
                component.set("v.spinner", false);
            }else{
                component.set('v.isActive',false);
                component.set("v.spinner", false);
                component.set("v.isEditContact",true);
                component.set("v.isNewContact", false);
                component.set("v.showCustomerListView",false);
                resultData = result.getReturnValue(); 
                
                toastEvent.setParams({
                    'title': 'Error!',
                    'type': 'error',
                    'mode': 'dismissable',
                    'message': resultData
                });                    
                toastEvent.fire();  
            }
        });
        $A.enqueueAction(actionUpdate);
    },
    getFilesForContracts: function(component,event,helper,contractID,listOfAttachments)
    {
        
        component.set('v.showAttachments',true);
        
        var action = component.get("c.getContractFiles");
        action.setParams({
            "recordId":contractID
        });
        action.setCallback(this, function(result) {			            
            var state = result.getState();
            if (state === "SUCCESS"){
                var resultData = result.getReturnValue(); 
                if(resultData != undefined && resultData !='')
                {
                    component.set("v.contractsFilesList",resultData);
                    component.set("v.ShowContractsFiles",false);
                }
                if((resultData == undefined || resultData =='' || resultData ==null)&&(listOfAttachments==undefined || listOfAttachments ==''|| listOfAttachments ==null)){
                    component.set("v.ShowContractsFiles",true);
                }
            }
            else{
                
            }
        });
        $A.enqueueAction(action); 	
    }
})