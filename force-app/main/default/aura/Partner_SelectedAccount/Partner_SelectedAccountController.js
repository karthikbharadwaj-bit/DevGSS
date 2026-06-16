({
    doInit:function(component,event,helper){
        var url = new URL(location.href);
        var id= url.searchParams.get('id');
        if(!id)
        {
            id = url.href.split('/')[6];
        }
        var baseURL = url.href.substring(0,url.href.indexOf("/s"));
        component.set('v.baseURL',baseURL);
        /*if(baseURL.includes('atos'))
varOpportunityURLLink=baseURL+'/s/partneropportunities?id=';
else*/
        var OpportunityURLLink = baseURL+'/s/partneropportunities?id=';
        component.set('v.OpportunityURLLink',OpportunityURLLink);
        
        if(!component.get("v.showChangeRequestCMP")){
            var acctId=component.get("v.accountId")
            component.set('v.isActive',true);
            component.set("v.spinner",true);
            helper.getSelectedAccount(component,acctId);
        }
        helper.getTranslations(component,event,helper);
    },
    openAccountChecklistForm:function(component,event,helper){
        //Toshowcomponentasreadonly
        //alert();
        var indexVar = event.currentTarget.dataset.index;
        var selectedAccount = component.get("v.selectedAccount");
        if(selectedAccount.accountCheckLists.length>0){
            var accountChecklistRec = selectedAccount.accountCheckLists[indexVar].accChecklistRec;
            component.set("v.selaccountcheckListRec",accountChecklistRec);
        }
        
        //if(component.get("v.selaccountcheckListRec").Payment_Method__c=='Invoice')
        //component.set("v.paymentMethod",true);
        
        component.set("v.isReadOnly",true);
        component.set('v.showChangeRequestCMP',true);
    },
    gotoChangeAccountRequest:function(component,event,helper){
        
        component.set("v.isReadOnly",false);
        component.set("v.selaccountcheckListRec",component.get("v.obj"));
        
        component.set('v.showChangeRequestCMP',true);
    },
    
    closeModal:function(component,event,helper){
        component.set('v.isActive',false);
        component.destroy();
    },
    
    cancelContact:function(component,event,helper){
        component.set("v.isModalOpen",true);
        component.set("v.isNewContact",false);
        component.set("v.isEditContact",false);
        component.set("v.showCustomerListView",true);
    },
    
    toggleShow:function(component,event,helper){
        component.set("v.toggleShowHide",true);
    },
    
    toggleHide:function(component,event,helper){
        component.set("v.toggleShowHide",false);
    },
    
    addAcctChckLst:function(component,event,helper){
        helper.insertChecklistRecords(component,event,helper);
    },
    
    removeAcctChckLst:function(component,event,helper){
        helper.deleteChecklistRecords(component,event,helper);
    },
    
    newContact:function(component,event,helper){
        var contact=component.get("v.contact");
        contact.FirstName='';
        contact.LastName='';
        contact.Email='';
        contact.Phone='';
        contact.RC_Customer_Role__c='';
        contact.Target_Account_Primary_Member__c=false;
        component.set("v.contact",contact);
        component.set("v.isNewContact",true);
        component.set("v.showCustomerListView",false);
        component.set("v.isEditContact",false);
    },
    
    /*handleSuccessNew:function(component,event,helper){
vartoastEvent=$A.get("e.force:showToast");
toastEvent.setParams({
"type":"success",
"title":"Success!",
"message":"Therecordhasbeencreatedsuccessfully.",
			"mode":'dismissible'
});
toastEvent.fire();
component.set("v.showCustomerListView",true);
component.set("v.isNewContact",false);
},

//METHODTOHANDLEERROR
handleError:function(component,event,helper){

vartoastEvent=$A.get("e.force:showToast");
toastEvent.setParams({
"type":"error",
"title":"Error!",
"message":"Therewassomeerrorduringprocessing!",
"mode":'dismissible'
});
toastEvent.fire();
},*/
    
    getOpportunityList:function(component,event,helper){
        helper.getOpportunityList(component,event,helper);
    },
    newOpportunity:function(component,event,helper){
        var isAvaya=component.get("v.ShowOnlyAvaya");
        component.set('v.showOppDetail',false);
        component.set('v.showOppList',false);
        component.set('v.showNewOpp',true);
        $A.createComponent("c:Partner_OpportunitiesDetail",{"ShowNewSection":true,
                                                            "ShowRecordDetail":false,
                                                            "accountId":component.get('v.AccountRecord').Id,
                                                            "ShowOnlyAvaya":isAvaya,
                                                            "fromcustomer":true,
                                                            "communityDetailsRecord":component.get("v.communityDetailsRecord")},
                           function(createAccountComp,status,errorMessage){
                               if(status==="SUCCESS"){
                                   var selAcctDiv=component.find('oppNewDiv').get('v.body');
                                   selAcctDiv.push(createAccountComp);
                                   component.find('oppNewDiv').set('v.body',selAcctDiv);
                               }
                           });
        
    },
    //Functionusedtocreatenewcontact
    createContact:function(component,event,helper){
        var phoneField=component.find('phoneNumberforContact');
        var phoneValue=phoneField.get('v.value');
        var emailField=component.find('contactEmail');
        var emailValue=emailField.get('v.value');
        var RoleField=component.find('partnerRoleType');
        var RoleValue=RoleField.get('v.value');
        
        var firstName=component.find('firstNameNew');
        var firstNameValue=firstName.get('v.value');
        
        var lastName=component.find('lastNameNew');
        var lastNameValue=lastName.get('v.value');
        
        if(phoneValue ==null || phoneValue == undefined || phoneValue == '' || 
           emailValue == null || emailValue == undefined || emailValue == '' || 
           firstNameValue == null || firstNameValue == '' || 
           lastNameValue == null || lastNameValue == ''){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type":"error",
                "title":component.get("v.translationsMap.Error")+'!',
                "message":component.get("v.translationsMap.Please_enter_all_the_required_details")+'!',
                "mode":'dismissible'
            });
            toastEvent.fire();
        }else{
            var regex1 = new RegExp("^[0-9,+()-]*$");
            var isValidPhone = regex1.test(phoneValue);
            //if(isNaN(phoneValue)){
            if(!isValidPhone){
                var toastEvent=$A.get("e.force:showToast");
                toastEvent.setParams({
                    "type":"error",
                    "title":component.get("v.translationsMap.Error")+'!',
                    "message":component.get("v.translationsMap.Please_enter_only_numeric_values_Phone")+'!',
                    "mode":'dismissible'
                });
                toastEvent.fire();
            }else{
                helper.insertContact(component,event,helper);
                
            }
        }
    },
    
    handleSuccess:function(component,event,helper){
        var toastEvent=$A.get("e.force:showToast");
        toastEvent.setParams({
            "title":component.get("v.translationsMap.Success")+'!',
            "message":component.get("v.translationsMap.The_record_has_been_Saved_successfully"),
        });
        toastEvent.fire();
    },
    onselectOpp:function(component,event,helper){
        var ctarget =event.currentTarget;
        var id_str =ctarget.dataset.value;
        var id_account =ctarget.dataset.account;
        component.set('v.showOppList',false);
        component.set('v.showOppDetail',true);
        $A.createComponent("c:Partner_OpportunitiesDetail",{"recordID":id_str,
                                                            "oppType":ctarget.dataset.record,
                                                            "accountId":ctarget.dataset.account,
                                                            "fromcustomer":true},
                           function(createAccountComp,status,errorMessage){
                               if(status==="SUCCESS"){
                                   var selAcctDiv=component.find('oppDetailDiv').get('v.body');
                                   selAcctDiv.push(createAccountComp);
                                   component.find('oppDetailDiv').set('v.body',selAcctDiv);
                               }
                           });
    },
    handleGoBackComponentEvent:function(component,event,helper){
        var message=event.getParam("goBack");
        if(message==true)
        {
            component.set('v.showOppDetail',false);
            component.set('v.showNewOpp',false);
            
            helper.getOpportunityList(component,event,helper);
        }		
    },
    //Methodstoshowandhidespinners
    showSpinner:function(component,event,helper){
        var spinner=component.find("loadingSpinner");
        $A.util.removeClass(spinner,"slds-hide");
    },
    
    hideSpinner:function(component,event,helper){
        var spinner=component.find("loadingSpinner");
        $A.util.addClass(spinner,"slds-hide");
    },
    goBackToCustomers:function(component,event,helper)
    {
        /*varcmpEvent=component.getEvent("goBackCustomerTabEvent");
cmpEvent.setParams({
"goBackCustomerTab":true});
cmpEvent.fire();
component.destroy();*/
    var urlEvent=$A.get("e.force:navigateToURL");
    urlEvent.setParams({
        //'url':'/partner/s/partnercustomers'
        'url':window.location.pathname
    });
    urlEvent.fire();
},
    onSelectedDoc:function(component,event,helper)
    {
        
        component.set('v.showAttachments',true);
        console.log('insidepop');
        var ctarget=event.currentTarget;
        var id_str=ctarget.dataset.value;
        var action=component.get("c.getAttachments");
        action.setParams({
            "parentId":id_str
        });
        action.setCallback(this,function(result){			
            var state=result.getState();
            if(state==="SUCCESS"){
                var resultData=result.getReturnValue();
                if(resultData != undefined && resultData != '')
                {
                    component.set("v.attachmentList",resultData);
                    component.set("v.ShowContractsFiles",false);
                }
                helper.getFilesForContracts(component,event,helper,id_str,resultData);
            }
            else{
                
            }
        });
        $A.enqueueAction(action);	
    },
    closeModal:function(component,event,helper)
    {
        component.set('v.showAttachments',false);
    },
    editContactDetails:function(component,event,helper){
        
        var objContact=event.getSource().get("v.value");
        
        var contact=component.get("v.editcontact");
        contact.FirstName=objContact.FirstName;
        contact.LastName=objContact.LastName;
        contact.Email=objContact.Email_Address;
        contact.Phone=objContact.Phone_Number;
        //AddedifconditionforALEforjiraBZS-4632
        var contactRole=objContact.Contact_Role;
        if(contactRole.startsWith("RC")){
            var contactRoles=component.get("v.selectedAccount.contactRoles");
            contact.RC_Customer_Role__c=contactRoles[0];
        }else{
            contact.RC_Customer_Role__c=objContact.Contact_Role;
        }
        contact.Target_Account_Primary_Member__c=objContact.Is_Primary;
        contact.contactId=objContact.contactId;
        contact.Id=objContact.Id;
        component.set("v.editcontact",contact);
        component.set("v.isNewContact",false);
        component.set("v.showCustomerListView",false);
        component.set("v.isEditContact",true);
    },
    updateContact :function(component,event,helper){
        var phoneField=component.find('phoneNumberforContactEdit');
        var phoneValue=phoneField.get('v.value');
        var emailField=component.find('contactEmailEdit');
        var emailValue=emailField.get('v.value');
        var RoleField=component.find('partnerRoleTypeEdit');
        var RoleValue=RoleField.get('v.value');
        
        var firstNameEdit=component.find('firstNameEdit');
        var firstNameValueEdit=firstNameEdit.get('v.value');
        var lastNameEdit=component.find('lastNameEdit');
        var lastNameValueEdit=lastNameEdit.get('v.value');
        console.log('RoleValue'+RoleValue);
        if(phoneValue==null || phoneValue==undefined || phoneValue=='' ||
           emailValue==null || emailValue==undefined || emailValue=='' 
           || firstNameValueEdit==null || firstNameValueEdit=='' || 
           lastNameValueEdit==null || lastNameValueEdit==''){
            var toastEvent=$A.get("e.force:showToast");
            toastEvent.setParams({
                "type":"error",
                "title":component.get("v.translationsMap.Error")+'!',
                "message":component.get("v.translationsMap.Please_enter_all_the_required_details")+'!',
                "mode":'dismissible'
            });
            toastEvent.fire();
        }else{
            var regex1 = new RegExp("^[0-9,+()-]*$");
            var isValidPhone =regex1.test(phoneValue);
            
            //if(isNaN(phoneValue)){
            if(!isValidPhone){
                var toastEvent=$A.get("e.force:showToast");
                toastEvent.setParams({
                    "type":"error",
                    "title":component.get("v.translationsMap.Error")+'!',
                    "message":component.get("v.translationsMap.Please_enter_only_numeric_values_Phone")+'!',
                    "mode":'dismissible'
                });
                toastEvent.fire();
            }else{
                helper.updateContact(component,event,helper);
                
            }
        }
    },
    previewFile : function(component,event,helper){
        var rec_id=event.currentTarget.id;
        $A.get('e.lightning:openFiles').fire({
            recordIds:[rec_id]
        });
    },
    entitlementsView : function(component,event,helper){
        var a=component.get('v.AccountRecord');
        var url=new URL(location.href);
        var baseURL=url.href.substring(0,url.href.indexOf("/s"));
        var converturl = baseURL+'/apex/entitlementsview?id='+a.Id;
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            'url':converturl
        });
        urlEvent.fire();
    }
})