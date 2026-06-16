({
    //Method to execute on load
    doInit : function(component, event, helper) {
        var url = new URL(location.href);
        var baseURL = url.href.substring(0, url.href.indexOf("/s"));
        component.set('v.baseURL',baseURL);

        var DealSupportURLLink=baseURL +'/s/dealsupport?id=';
         component.set('v.DealSupportURLLink',DealSupportURLLink);
        var isNewOpp = component.get('v.ShowNewSection');

        helper.getIsIgniteUQTFlow(component, event, helper);

        if(isNewOpp == false)
        {
            var id_str = component.get("v.recordID");
            component.set("v.ShowRecordDetail", true);
            component.set("v.ShowComponentButtons", true);
            component.set("v.showQuotes", true);
            var action = component.get("c.getOppRecordList");
            action.setParams({
                "OppRecordId":id_str
            });
            action.setCallback(this, function(result) {
                var state = result.getState();
                if(state=="SUCCESS"){
                    component.set("v.hasReadAccess",result.getReturnValue().hasReadAccess);
                    if(result.getReturnValue().hasReadAccess==true){
                        console.log('state>' +result.getState());
                        var resultData = result.getReturnValue().oppty;
                        component.set("v.selectedEmployeeValue", resultData.Number_of_Employees__c); //Bug fix - CRM-3277
                        component.set("v.communityDetailsRecord", result.getReturnValue().communityDetailsRecord);
                        component.set("v.Est12MPriceStd",JSON.stringify(component.get("v.communityDetailsRecord").Estimated_12M_Booking_Standard__c));
                        component.set("v.Est12MPriceRCMeetings",JSON.stringify(component.get("v.communityDetailsRecord").Estimated_12M_RingCentral_Video_Pipeline__c));
                        component.set("v.isIgnite", result.getReturnValue().isIgnite);
                        console.log('isIgnite>'+result.getReturnValue().isIgnite);
                        component.set("v.partnerCommunity", result.getReturnValue().partnerCommunityName);
                        component.set("v.isReadOnly", result.getReturnValue().isReadOnly);
                        component.set("v.isSingleLogin",result.getReturnValue().isSingleLogin);
                        component.set("v.salesQuote",result.getReturnValue().salesQuote)
                        if(resultData.Partner_Quotes__r != null && resultData.Partner_Quotes__r.length > 0) {
                            component.set("v.isChangeOrderSubmitted",true);
                        }
                        component.set("v.OpportunityRecord", resultData);
                        if(resultData.Tier_Name__c == 'RC Meetings')
                        {
                            component.set("v.RCMeetings", true);
                        }
                        //component.set("v.ShowComponentButtons", true);
                        component.set("v.accCountry", result.getReturnValue().accCountry);//ACO 3.0
                        component.set("v.oppStage", resultData.StageName);
                        component.set("v.oppType", resultData.Type);
                        //helper.getEmployees(component, event, helper);
                        component.set("v.accountId", resultData.AccountId);
                        if(result.getReturnValue().isAvaya==true || result.getReturnValue().isMaster==true){
                            component.set('v.ShowConAcc',true);
                        }
                        if(result.getReturnValue().isAvaya==true){
                            component.set('v.ShowOnlyAvaya',true);

                        }
                        if(resultData.dsfs__R00N80000002fD9vEAE__r == undefined)
                        {
                            component.set("v.Message", true);
                        }
                        if(resultData.Deal_Supports__r == undefined)
                        {
                            component.set("v.DealStatusMessage", true);
                        }
                        var partner = component.get("v.partnerCommunity");
                        var masterLabel = component.get('v.communityDetailsRecord').MasterLabel;
                        var brand = 'RingCentral';
                        if(partner.includes(brand)&&masterLabel == 'ignite'){
                            component.set("v.ShowOnlyRC", true);
                            if(resultData != undefined && resultData.Partner_Account__r != undefined &&
                                resultData.Partner_Account__r.Partner_Classification__c == 'Mitel Referral') {
                                    component.set("v.showMitelShare", true); //PBC-9705 P2CSharing
                            }
                        }
                        // For JIRA BZS-4920
                        if (partner.includes('Rainbow Office')) {
                            component.set("v.ShowOnlyALE", true);
                        }
                        var RCMeetingsCountries = ['France', 'Ireland', 'Italy', 'Portugal', 'Spain', 'Belgium', 'Netherlands',
                                                   'Austria', 'Germany'];
                        if(partner.includes('Unify Office')){
                            component.set("v.ShowOnlyAtos", true);
                            if(RCMeetingsCountries.includes(resultData.Account.BillingCountry))
                            {
                                var tierNames = ["Office","RC Meetings"];
                                component.set("v.tierNames",tierNames);
                            }
                        }
                        helper.getEmployees(component, event, helper);

                        helper.checkSalesQuote(component,result);
                    }
                    else{
                        component.set("v.hasReadAccess", false);
                    }
                }
            });
            $A.enqueueAction(action);
        }
		// Added for PBC-11156
        else{
            var action = component.get("c.getAccountList");
            action.setCallback(this, function(result) {
                var state = result.getState();
                if(state=="SUCCESS"){
                        console.log('state>' +result.getState());
                        var resultData = result.getReturnValue();
                        component.set("v.partnerCommunity", result.getReturnValue().partnerCommunityName);
                         console.log('partnercomm >>>> '+component.get("v.partnerCommunity"));
                           	var str = 'RingCentral';
                            var partnerComm = component.get("v.partnerCommunity");
                            var masterLabel = component.get("v.communityDetailsRecord").MasterLabel;
                    console.log("Partner Community" +partnerComm);
                    console.log("Master Lable" +masterLabel);
                    console.log("include" +partnerComm.includes(str));
                            if(partnerComm.includes(str) && masterLabel == 'ignite') {
                                console.log("Inside If");
                                component.set("v.ShowOnlyRC", true);
                            }
                            console.log('ShowOnlyRC', component.get("v.ShowOnlyRC"));
                        	}

      			 });
            $A.enqueueAction(action);

            action = component.get("c.isExistingBusiness");
            action.setParams({ accId: component.get("v.accountId") });
            action.setCallback(this, function(res) {
                component.set('v.isExistingBusiness', res.getReturnValue());
            });
            $A.enqueueAction(action);
        }

        var action = component.get("c.isShowUnifiedQuotingWizard");
        action.setParams({ oppId: component.get("v.recordID") });
        action.setCallback(this, function(res) {
            component.set('v.isShowUnifiedQuotingWizard', res.getReturnValue());
        });
        $A.enqueueAction(action);

        action = component.get("c.getDOSCaseRecordTypeId");
        action.setCallback(this, function(res) {
            component.set('v.caseRecordTypeId', res.getReturnValue());
        });
        $A.enqueueAction(action);

        helper.getTranslations(component,event,helper);
    },
    goToQuoteTool : function(component, event, helper) {
        helper.checkPartnerQuoteExist(component, event, helper);
    },

    onTierChange: function(component, event, helper) {
        console.log('inside tier change');
        console.log('selectedTier : '+component.find("tierSelected").get("v.value"));
        var selectedTier = component.find("tierSelected").get("v.value");
        if(selectedTier=='RC Meetings')
            component.set("v.RCMeetings",true);
        else
            component.set("v.RCMeetings",false);
    },

    /*sendWithDocuSign : function(component, event, helper) {
        component.set('v.ShowSpinnerOpp',false);
        var oppId = component.get("v.OpportunityRecord").Id;
        $A.createComponent("c:Partner_OpportunitiesDocuSign",{"oppRecordId":oppId},
                           function(createAccountComp, status, errorMessage){
                               if (status === "SUCCESS") {
                                   var docuSignDiv = component.find('docuSignDiv').get('v.body');
                                   docuSignDiv.push(createAccountComp);
                                   component.find('docuSignDiv').set('v.body', docuSignDiv);
                               }
                           });

    },*/
    //METHOD TO HANDLE SUCCESS OF RECORD EDIT FORM
    handleSuccess : function(component, event, helper) {
        var record = event.getParam("response");
        var action = component.get("c.getOppRecordList");
        action.setParams({
            "OppRecordId":record.id
        });
        action.setCallback(this, function(result) {
            var responsedata = result.getReturnValue().oppty;
            if(responsedata != undefined)
            {
                component.set('v.OpportunityRecord',responsedata);
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "success",
                    "title": "Success!",
                    "message": "The record has been Saved successfully.",
                    "mode":'dismissible'
                });
                toastEvent.fire();
                component.set("v.ShowRecordDetail", true);
                component.set("v.ShowEditSection",false);
                component.set("v.ShowNewSection",false);
                component.set("v.ShowComponentButtons", true);
            }
        });
        $A.enqueueAction(action);
    },
    //METHOD TO HANDLE ERROR
    handleError : function(component, event, helper) {
        var err = event.getParam('error');
        var errStr = JSON.stringify(err);
        if(errStr.indexOf('Please enter Cloud Specialist Contact Id') != -1){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type": "error",
                "title": "Error!",
                "message": "Please search and choose valid Cloud Specialist User.Please refresh the page once!",
                "mode":'dismissible'
            });
            toastEvent.fire();
        }else{
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type": "error",
                "title": "Error!",
                "message": "There was some error during processing!",
                "mode":'dismissible'
            });
            toastEvent.fire();
        }
    },
    //METHOD TO HANDLE SUBMIT OF EDIT PAGE
    handleSubmit : function(component, event, helper) {
        event.preventDefault();
        var fields = event.getParam("fields");

        fields['Number_of_Employees__c'] = component.find("employeeSelect").get("v.value"); //Bug fix - CRM-3277
         //Chosen Avaya CloudOffice Specialist
        var chosenCloudSpecialistValue=component.get("v.cloudSpecialistContactId");
        console.log('chosenCloudSpecialistValue'+chosenCloudSpecialistValue);
        if(chosenCloudSpecialistValue != null && chosenCloudSpecialistValue !=undefined && chosenCloudSpecialistValue !=''){
            fields['Avaya_Cloud_Specialist__c']=chosenCloudSpecialistValue;
            console.log('chosenCloudSpecialistValue>'+fields['Avaya_Cloud_Specialist__c']);
        }
        else{
            fields['Avaya_Cloud_Specialist__c'] = '';
             console.log('chosenCloudSpecialistValue>'+fields['Avaya_Cloud_Specialist__c']);
        }
        //console.log('Tier : '+component.find("tierSelected").get("v.value"));
        if(component.get("v.ShowOnlyAtos")==true){
            fields['Tier_Name__c'] = component.find("tierSelected").get("v.value");

            if(fields['Tier_Name__c'].includes('RC Meetings')){
                fields['Forecasted_Users__c'] = '';
                fields['X12_Month_Booking__c'] = '';
                var est12M =  fields['Forecasted_RingCentral_Video_Users__c'] *  component.get("v.Est12MPriceRCMeetings");
                fields['Estimated_12M_RingCentral_Video_Pipeline__c'] =  est12M;
                console.log('Forecasted_RingCentral_Video_Users__c' +fields['Forecasted_RingCentral_Video_Users__c']);
                console.log('Est12MPriceRCMeetings' + component.get("v.Est12MPriceRCMeetings"));
                console.log('Est12MPriceRCMeetings',est12M);
                console.log('Estimated_12M_RingCentral_Video_Pipeline__c' +fields['Estimated_12M_RingCentral_Video_Pipeline__c']);
            }
            if(fields['Tier_Name__c'].includes('Office')){
                fields['Forecasted_RingCentral_Video_Users__c'] = '';
                fields['Estimated_12M_RingCentral_Video_Pipeline__c'] = '';
                var est12M  =  fields['Forecasted_Users__c'] *  component.get("v.Est12MPriceStd");
                fields['X12_Month_Booking__c'] =  est12M;
                console.log('fc user>'+fields['Forecasted_Users__c']);
                console.log('Forecasted_RingCentral_Video_Users__c' +fields['Forecasted_RingCentral_Video_Users__c']);
                console.log('X12_Month_Booking__c' +fields['X12_Month_Booking__c']);
            }
        }
        component.find('editRecordForm').submit(fields);
    },
    //handle submit for new opportunity creation
    handleSubmitNew : function(component, event, helper) {
        event.preventDefault();
        var fields = event.getParam("fields");
        var opp = component.get("v.OpportunityRecord");
        var chosenCloudSpecialistValue=component.get("v.cloudSpecialistContactId");
        //component.set("v.oppType", opp.Type);
        var accId = component.get("v.accountId");
        var action = component.get("c.createOpportunity");
        action.setParams({
            "oppty":opp,
            "accountId":accId,
            "chosenCloudSpecialistValue":component.get("v.cloudSpecialistContactId")
        });
        action.setCallback(this, function(result) {
            if(result.getReturnValue().responseMessage == 'Success')
            {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "success",
                    "title": "Success!",
                    "message": "The record has been Saved successfully.",
                    "mode":'dismissible'
                });
                toastEvent.fire();
                console.log('url for opp>'+component.get('v.baseURL'));
                console.log('opp id'+result.getReturnValue().opp.Id);
                var urlLink='';
                var urlOpp=component.get('v.baseURL');
				urlLink=urlOpp +'/s/partneropportunities?id=' +result.getReturnValue().opp.Id;
                var urlEvent = $A.get("e.force:navigateToURL");
                urlEvent.setParams({
                    'url': urlLink
                });
                urlEvent.fire();

            }
            else
            {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "error",
                    "title": "Error!",
                    "message": result.getReturnValue().responseMessage,
                    "mode":'dismissible'
                });
                toastEvent.fire();
            }

        });
        $A.enqueueAction(action);
    },
    //Method to show edit section
    showEditSectionAres: function (component, event, helper) {
        component.set("v.ShowEditSection", true);
        component.set("v.ShowListView", false);
        component.set("v.ShowRecordDetail", false);
        component.set('v.ShowSpinnerOpp',true);
        component.set("v.ShowComponentButtons", false);
    },
    //Method to execute to return to detail page
    goBack:function (component, event, helper) {
        try
        {
        var url = new URL(location.href);
        var customerIndex = url.href.indexOf("/partnercustomers");

        if(customerIndex == -1)
        {
            component.set("v.ShowEditSection", false);
            component.set("v.ShowRecordDetail", true);
            component.set("v.ShowComponentButtons", true);
            var urlEvent = $A.get("e.force:navigateToURL");
            console.log('record Id - ' + component.get("v.recordID"));
            urlEvent.setParams({
                //'url': '/partner/s/partneropportunities?id='+component.get("v.recordID")
                'url': window.location.pathname +'?id=' +component.get("v.recordID")
            });
            urlEvent.fire();
        }
        else
        {
            var action = component.get("c.getOppRecordList");
            action.setParams({
                "OppRecordId":component.get("v.recordID")
            });
            action.setCallback(this, function(result) {
                var resultData = result.getReturnValue().oppty;
                //alert(resultData.Partner_Quotes__r);
                component.set("v.OpportunityRecord", resultData);
                component.set("v.ShowEditSection", false);
                component.set("v.ShowRecordDetail", true);
                component.set("v.ShowComponentButtons", true);
            });
            $A.enqueueAction(action);
        }
        }
        catch(e)
        {
            console.log('exception - ' + e);
        }
    },
    //Method to execute to return to list view
    goBackToViewList:function (component, event, helper) {
        component.set("v.ShowRecordDetail", false);
        component.set("v.ShowListView", true);
        component.set("v.showQuotes", false);
        component.set("v.showDocuSign", false);

        var url = new URL(location.href);
        var customerIndex = url.href.indexOf("/partnercustomers");
        if(customerIndex == -1)
        {
            var urlEvent = $A.get("e.force:navigateToURL");
            urlEvent.setParams({
                //'url': '/partner/s/partneropportunities'
                'url':window.location.pathname
            });
            urlEvent.fire();
        }
        else
        {
            var cmpEvent = component.getEvent("goBackEvent");
            cmpEvent.setParams({
                "goBack": true});
            cmpEvent.fire();
        }
    },

    //Generate Contract functionality
    /*navigateToContract : function(component, event, helper){
        var oppId =component.get("v.recordID");
        var action = component.get("c.getPartnerQuote");
        component.set('v.ShowSpinnerOpp',false);
        action.setParams({
            "selectedOpportunity":oppId
        });
        action.setCallback(this, function(result) {
            var state = result.getState();
            var response = result.getReturnValue();
            var primaryPartnerQuote=response;
            $A.createComponent("c:Partner_QuoteEngageLegal",
                               {"oppId" : oppId,
                                "partnerQuoteId" : primaryPartnerQuote},
                               function(createPartnerComponent, status, errorMessage){
                                   if (status === "SUCCESS") {
                                       var pcDiv = component.find('generateContractDiv').get('v.body');
                                       pcDiv.push(createPartnerComponent);
                                       component.find('generateContractDiv').set('v.body', pcDiv);
                                   }
                               }
                              );
        })
        $A.enqueueAction(action);
    },
    //Account Checklist functionality
    navigateToAccChecklist : function(component, event, helper){
        try{
            var accountId = component.get("v.OpportunityRecord").AccountId;
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
    },*/
    showSpinner: function(component, event, helper) {
        var spinner = component.find("loadingSpinner");
        $A.util.removeClass(spinner, "slds-hide");
    },

    hideSpinner : function(component,event,helper){
        var spinner = component.find("loadingSpinner");
        $A.util.addClass(spinner, "slds-hide");
    },

    createDealSupport : function(component, event, helper) {
        var comments=component.find('comments');
        var commentValue=comments.get('v.validity').valueMissing;
        var typeds=component.find('ds_type');
        var typeValue=typeds.get('v.validity').valueMissing;

        if(commentValue) {
            comments.showHelpMessageIfInvalid();
            comments.focus();
        }

        if(typeValue) {
            typeds.showHelpMessageIfInvalid();
            typeds.focus();
        }
      if(commentValue==false&&typeValue==false) {
		helper.insertDealSupport(component, event, helper);
        }
	},

    cancelDealSupport: function(component, event, helper) {

        component.set("v.showCreateDealStatus", false);
        component.set("v.ShowRecordDetail", true);
        var cmpEvent = component.getEvent("cancelEvent");
        cmpEvent.setParams({
            "goBack": true});
        cmpEvent.fire();
	},
     redirectToDealSupport : function(component,event,helper) {
        component.set("v.ShowRecordDetail",false);
        component.set("v.showCreateDealStatus",true);
    },

    handleCloudSpecialistEvent: function(component,event,helper){
        console.log('inside cloudspe event set');
        var cloudSpecialistContactId = event.getParam("cloudSpecialistContactId");
        var cloudSpecialistContactName = event.getParam("cloudSpecialistContactName");
        console.log('cloudSpecialistContactId'+cloudSpecialistContactId);
        console.log('cloudSpecialistContactName'+cloudSpecialistContactName);
        component.set("v.cloudSpecialistContactId",cloudSpecialistContactId);
    },
    processOrder: function(component,event,helper){
        if(component.get("v.oppType") == 'Existing Business'){
            component.set("v.showPartnerChecklistCMP",true);
            return;
        }
        helper.checkAccountList(component, event, helper);
    },
    handleSave : function(component, event, helper) {
        var addressList = [];
        var shippingAddressList = component.get("v.ShippingAddressList");
        if(shippingAddressList) {
            for(var wrapRec of shippingAddressList) {
                addressList.push(wrapRec.acrRec);
            }
        }
        component.set("v.showSpinner",true);
            var isShippingExist = false;
            var objQuote = component.get("v.salesQuote");
            for(var addressRec of addressList) {
                if(addressRec.Type__c == 'Shipping Address') {
                    isShippingExist = true;
                }
            }
            console.log('isShippingExist - '+isShippingExist);
            var childCmp = component.find("AccountCheckList");
            var showProductSection = component.get("v.showProductSection");
            var communityBrand='';
            if(component.get("v.communityDetailsRecord")!=undefined && component.get("v.communityDetailsRecord") !='' && component.get("v.communityDetailsRecord") !=null)
                communityBrand = component.get("v.communityDetailsRecord").Brand_Name__c;
            else
                communityBrand = component.get('v.Quote.Opportunity__r.Brand_Name__c');
            if(showProductSection)
            {
                if(!isShippingExist)
                {
                    helper.showToast('Error', 'Please select shipping address before submiting quote.', 'error');
                    component.set("v.showSpinner",false);
                    return;
                }
            }

            childCmp = component.find("AccountCheckList");
            childCmp.submitDetails();

    },
    closeModel : function(component, event, helper) {
           component.set("v.showPartnerChecklistCMP",false);
    },

    openCreateCaseForm: function (component, event, helper) {
        var defaultFieldValues = {};
        defaultFieldValues.AccountId = component.get('v.accountId');
        defaultFieldValues.Opportunity_Reference__c = component.get('v.recordID');
        defaultFieldValues.RecordTypeId = component.get('v.caseRecordTypeId');
        defaultFieldValues.Case_Category__c = 'Ignite Partner';
        defaultFieldValues.Origin = 'Opportunity';
        defaultFieldValues.OwnerId = $A.get("v.OpportunityRecord.OwnerId");
        defaultFieldValues.CSM__c = component.get("v.OpportunityRecord.Account.CSM__c");
        defaultFieldValues.AccountOwner__c = component.get("v.OpportunityRecord.Account.OwnerId");

        let encodedData = btoa(JSON.stringify(defaultFieldValues));
        window.open(component.get("v.baseURL")+ '/s/partner-create-case?encodedData=' + encodedData, '_blank');
    },

    forecasterUserMouseOver: function(component, event, helper) {
        helper.toggleToolTip(component,"forecastedUserTooltip",'hide');
    },
    
    forecasterUserMouseOut: function(component, event, helper) {
        helper.toggleToolTip(component,"forecastedUserTooltip",'show');
    },

    forecasterCCUserMouseOver: function(component, event, helper) {
        helper.toggleToolTip(component,"forecastedCCUserTooltip",'hide');
    },

    forecasterCCUserMouseOut: function(component, event, helper) {
        helper.toggleToolTip(component,"forecastedCCUserTooltip",'show');
    }
})