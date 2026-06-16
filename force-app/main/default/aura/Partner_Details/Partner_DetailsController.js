({
    init: function (cmp, event, helper) {
        var url = new URL(location.href);
        cmp.set('v.RespectiveTabURL',url);
        var baseURL = url.href.substring(0, url.href.indexOf("/s"));
        cmp.set('v.baseURL',baseURL);
        var opts = [
            { value: "General Partner", label: "General Partner" },
            { value: "Master Agent", label: "Master Agent" }
        ];

        cmp.set("v.partnerTypes", opts);
        var id = url.searchParams.get('id');
        if(id != null && id != undefined && id !=''){
            helper.getPartnerDetail(cmp,id);
        }
        else{
            var pageNumber = 1;
            var pageSize = 50;
            helper.searchHelper(cmp,pageNumber,pageSize);
        }
            //helper.getBusinessIdentity(cmp,'Partner_Request__c','BusinessIdentity__c');
            helper.getBusinessIdentity(cmp,'Partner_Request__c','Partner_Type__c');
            helper.getTranslations(cmp, event, helper);
            helper.getCountryStateMap(cmp);
        	// Added for PRM - 55 Wholesale Reseller PRM/CRM start
            helper.getSettlementTypes(cmp,'Partner_Request__c','Settlement_Type__c');
            helper.getBillingFeedTypes(cmp);
            // Added for PRM - 55 Wholesale Reseller PRM/CRM end
    },
    newContact: function(component, event, helper) {
        var contact = component.get("v.contact");
        contact.FirstName = '';
        contact.LastName = '';
        contact.Email = '';
        contact.Phone = '';
        contact.RC_Customer_Role__c = '';
        contact.Target_Account_Primary_Member__c = false;
        component.set("v.contact",contact);
        component.set("v.isNewContact", true);
        component.set("v.showContactListView",false);

    },
    // Function used to create new contact
    createContact: function(component, event, helper) {
        var phoneField = component.find('phoneNumberforContact');
        var phoneValue = phoneField.get('v.value');
        var emailField = component.find('contactEmail');
        var emailValue = emailField.get('v.value');
        var RoleField = component.find('partnerRoleType');
        var RoleValue = RoleField.get('v.value');

        if(phoneValue == null || phoneValue == undefined || phoneValue == '' ||
           emailValue == null || emailValue == undefined || emailValue == ''||
           RoleValue == null  || RoleValue == undefined || RoleValue == ''){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type": "error",
                "title": component.get("v.translationsMap.Error")+'!',
                "message": component.get("v.translationsMap.Please_enter_all_the_required_details")+'!',
                "mode":'dismissible'
            });
            toastEvent.fire();
        }else{
            //if(isNaN(phoneValue)){
            var regex1  = new RegExp("^[0-9 ,+()-]*$");
            var isValidPhone = regex1.test(phoneValue);

            if(!isValidPhone){
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "error",
                    "title": component.get("v.translationsMap.Error")+'!',
                    "message": component.get("v.translationsMap.Please_enter_only_numeric_values_Phone")+'!',
                    "mode":'dismissible'
                });
                toastEvent.fire();
            }else {
                helper.insertContact(component, event, helper);
            }
        }
    },
    cancelContact: function(component, event, helper){
        component.set("v.isNewContact", false);
        component.set("v.showContactListView",true);
    },
    handleNext: function(component, event, helper) {
        var pageNumber = component.get("v.pageNumber");
        var pageSize = component.find("pageSize").get("v.value");
        pageNumber++;
        helper.searchHelper(component,pageNumber,pageSize);
    },

    handlePrev: function(component, event, helper) {
        var pageNumber = component.get("v.pageNumber");
        var pageSize = component.find("pageSize").get("v.value");
        pageNumber--;
        helper.searchHelper(component,pageNumber,pageSize);
    },

    onSelectChange: function(component, event, helper) {
        var pageNumber = 1;
        var pageSize = component.find("pageSize").get("v.value");
        helper.searchHelper(component,pageNumber,pageSize);
    },
    handleNext_pr: function(component, event, helper) {
        var pageNumber_pr = component.get("v.pageNumber_pr");
        var pageSize_pr = component.find("pageSize_pr").get("v.value");
        pageNumber_pr++;
        helper.getPartnerRegistrations(component,pageNumber_pr,pageSize_pr);
    },

    handlePrev_pr: function(component, event, helper) {
        var pageNumber_pr = component.get("v.pageNumber_pr");
        var pageSize_pr = component.find("pageSize_pr").get("v.value");
        pageNumber_pr--;
        helper.getPartnerRegistrations(component,pageNumber_pr,pageSize_pr);
    },

    onSelectChange_pr: function(component, event, helper) {
        var pageNumber_pr = 1;
        var pageSize_pr = component.find("pageSize_pr").get("v.value");
        helper.getPartnerRegistrations(component,pageNumber_pr,pageSize_pr);
    },

    tabSelected: function (cmp, event, helper) {
        if(cmp.get('v.selTabId')=='registeredPartners'){
            cmp.set('v.newParterVisible', false);

            cmp.set('v.isWorkingWithPartner',false);
            cmp.set('v.workingWithPartnerVal','No');
            cmp.set('v.masterPartnerContactName','');
            cmp.set('v.masterPartnerId','');

            var pageNumber_pr = 1;
            var pageSize_pr = 50;
            helper.getPartnerRegistrations(cmp,pageNumber_pr,pageSize_pr);
        }

        if(cmp.get('v.selTabId')=='partnerTab'){
            cmp.set('v.newParterVisible', false);

            cmp.set('v.isWorkingWithPartner',false);
            cmp.set('v.workingWithPartnerVal','No');
            cmp.set('v.masterPartnerContactName','');
            cmp.set('v.masterPartnerId','');
        }
    },
    registerNewPartner: function (cmp,event, helper) {
        cmp.set('v.showBillingFeedType',false);// Added for PRM-55
        cmp.set('v.newParterVisible', true);
        cmp.set('v.selTabId','partnerTabRegistration');
        cmp.set('v.masterPartnerAccountName','');
        helper.refreshCountryStateMap(cmp, event, helper);
    },
    onchangeCountry: function (component, event, helper) {
        var selectedValue = event.getSource().get("v.value");
        helper.onchangeCountry(component, event, helper, selectedValue);
    },
    onChangeBusiness: function (component, event, helper) {
        var selectedValue = event.getSource().get("v.value");
        helper.onChangeBusinessIdentity(component, event, helper, selectedValue);
    },
    updateSelectedText: function (cmp, event) {
        var selectedRows = event.getParam('selectedRows');
        cmp.set('v.selectedRowsCount', selectedRows.length);
    },

    searchPartners: function(component, event, helper) {
        var searchField = component.find('searchField');
        var isValueMissing = searchField.get('v.validity').valueMissing;
        // if value is missing show error message and focus on field
        if(isValueMissing) {
            searchField.showHelpMessageIfInvalid();
            searchField.focus();
        }else{
            // else call helper function
            var pageNumber = component.get("v.pageNumber");
            var pageSize = component.find("pageSize").get("v.value");
            pageNumber = 1;
            helper.searchHelper(component,pageNumber,pageSize);
        }
    },

    goBackToViewList: function(component, event, helper) {
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            //'url': '/partner/s/partnerdetails'
            'url':window.location.pathname
        });
        urlEvent.fire();
    },
    closeForm: function (cmp) {
        cmp.set('v.newParterVisible', false);
        cmp.set('v.selTabId','registeredPartners');

        cmp.set('v.isWorkingWithPartner',false);
        cmp.set('v.workingWithPartnerVal','No');
        cmp.set('v.masterPartnerContactName','');
        cmp.set('v.masterPartnerId','');
    },
    onchangeWWP: function(component, event, helper){
        var wwp = component.get("v.workingWithPartnerVal");
        if(wwp=="Yes"){
            component.set("v.isWorkingWithPartner",true);
        }else{
            component.set("v.isWorkingWithPartner",false);
            component.set('v.masterPartnerAccountName','');
            component.set('v.masterPartnerId','');
            component.set("v.NGBSAccId",'');
            var accid = component.get("v.NGBSAccId");//Added for BOB
            helper.getListofMasterAgents(component,event,helper,accid);
        }
    },

    onchangePT : function(component, event, helper){
        var pt = component.get("v.selectedPartnerType");
        // Added for PRM- 55 start
        helper.refreshSettlementTypes(component, event, helper, pt);
        // Added for PRM - 55 end
        if(pt=="Alcatel-Lucent - Bill-on-Behalf" || pt=="Atos - Bill-on-Behalf" || pt=="Avaya - Bill-on-Behalf"){
            component.set("v.isPartnerTypeBillOnBehalf",true);
            component.set('v.isPartnerTypeWholesaleReseller', false);
            // Added for JIRA - 6994 start
            var businessIdentities = component.get('v.BusinessIdentityValue');
            component.set('v.selectedBusinessIdentity', businessIdentities[0]);
            helper.onChangeBusinessIdentity(component, event, helper, businessIdentities[0]);
            // Added for JIRA - 6994 end
        }
        // Added Wholesale-Reseller check for PRM - 55 start
        else if (pt == "Wholesale-Reseller" || pt == "Alcatel-Lucent - Wholesale-Reseller" || pt == "Atos - Wholesale-Reseller" || pt == "Avaya - Wholesale-Reseller") {
            component.set("v.isPartnerTypeBillOnBehalf",true);
            component.set('v.isPartnerTypeWholesaleReseller', true);
            // Added for JIRA - 6994 start
            var businessIdentities = component.get('v.BusinessIdentityValue');
            component.set('v.selectedBusinessIdentity', businessIdentities[0]);
            helper.onChangeBusinessIdentity(component, event, helper, businessIdentities[0]);
            // Added for JIRA - 6994 end
        }
        else{
            component.set("v.isPartnerTypeBillOnBehalf",false);
             component.set('v.isPartnerTypeWholesaleReseller', false);
            // Added for JIRA - 6994 start
            helper.refreshCountryStateMap(component, event, helper);
            // Added for JIRA - 6994 end
        }
    },

    getContactList: function(component,event,helper){
        helper.ContactList(component,event,helper);
    },

    getAccList: function(component,event,helper){
        var action = component.get("c.loadAccount");
        action.setParams({
            'acctId':component.get("v.AccountId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var data = response.getReturnValue();
                component.set('v.AccountRecord',data);
                if(data== undefined || data == '' || data== null){
                component.set('v.ShowSpinnerOpp',false);
                }
            }else{
                 component.set('v.ShowSpinnerOpp',false);
            }

        });
        $A.enqueueAction(action);
    },


    handleSubmitPR : function(component, event, helper) {
        event.preventDefault();
        var onBehalf = component.get('v.isWorkingWithPartner');
         // added for JIRA - 6286 Bill On Behalf PRM/CRM  start
        var isBOB = component.get('v.isPartnerTypeBillOnBehalf');
        var isBS = component.get('v.isBillingSupport');

        var firstNameBoB = component.find('firstnamebob');
        var lastnameBOB = component.find('lastnamebob');
        var emailBOB = component.find('emailAddressbob');
        var phoneBOB = component.find('mobileNumberbob');

        var firstNameBS = component.find('firstnamebs');
        var lastnameBS = component.find('lastnamebs');
        var emailBS = component.find('emailAddressbs');
        var phoneBS = component.find('mobileNumberbs');

        var firstNameBoBValue;
        var lastnameBOBValue;
        var emailBOBValue;
        var phoneBOBValue;

        var firstNameBSValue;
        var lastnameBSValue;
        var emailBSValue;
        var phoneBSValue;

        if(firstNameBoB!=undefined){
            firstNameBoBValue = firstNameBoB.get('v.value');
        }
        if(lastnameBOB!=undefined){
            lastnameBOBValue = lastnameBOB.get('v.value');
        }
        if(emailBOB!=undefined){
            emailBOBValue = emailBOB.get('v.value');
        }
        if(phoneBOB!=undefined){
            phoneBOBValue = phoneBOB.get('v.value');
        }

		if(firstNameBS!=undefined){
            firstNameBSValue = firstNameBS.get('v.value');
        }
        if(lastnameBS!=undefined){
            lastnameBSValue = lastnameBS.get('v.value');
        }
        if(emailBS!=undefined){
            emailBSValue = emailBS.get('v.value');
        }
        if(phoneBS!=undefined){
            phoneBSValue = phoneBS.get('v.value');
        }
        // added for JIRA - 6286 Bill On Behalf PRM/CRM  end
        // Added for Wholesale reseller PRM - 55 start
        var isReseller = component.get('v.isPartnerTypeWholesaleReseller');
        var resellerError = false;
        var settlementType = component.find('selectedSettlementType');
        var partnerReqBillingFeed = component.find('partnerReqBillingFeed');
        var billingFeedtype = component.find('selectedBillingFeedType');
        var settlementPartnerName = component.get("v.selectedSettlementPartner");
        var settlementRatePartnerName = component.get("v.selectedSettlementRatePartner");
        var billingFeedTypeValue = component.get("v.selectedBillingFeedType");
        // Added for Wholesale reseller PRM - 55 end
        var mpcId = component.get('v.masterPartnerContactId');
        var phoneField = component.find('phoneNumber');
        var phoneValue = phoneField.get('v.value');
        var mobileField = component.find('mobileNumber');
        var mobileValue = mobileField.get('v.value');
        var regex1  = new RegExp("^[0-9 ,+()-]*$");
        var isValidPhone = regex1.test(phoneValue);
        var isValidMobile = regex1.test(mobileValue);
        var communityBrand=component.get('v.communityDetailsRecord').Brand_Name__c;
        var masterLabel = component.get("v.communityDetailsRecord").MasterLabel;
        var BOBError = true;
        var isValidphoneBOB = regex1.test(phoneBOBValue);
        var isValidphoneBS = regex1.test(phoneBSValue);
        let externalSIDVal, portalLinkIdName;
        // added for JIRA - 6286 Bill On Behalf PRM/CRM start
        console.log('is BOB value in the Submit PR>>>>>>>>' +isBOB);

        if(!isBOB){
            BOBError = false;
        }
        else{
            if(!firstNameBoBValue){
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "error",
                    "title": "Error!",
                    "message": "Incomplete First Name(Accounts Payable) fields . Please Fill before submitting",
                    "mode":'dismissible'
                });
                toastEvent.fire();
                }

            if(!lastnameBOBValue){
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "error",
                    "title": "Error!",
                    "message": "Incomplete Last Name(Accounts Payable) fields . Please Fill before submitting",
                    "mode":'dismissible'
                });
                toastEvent.fire();
                }

            if(!emailBOBValue){
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "error",
                    "title": "Error!",
                    "message": "Incomplete Email(Accounts Payable) fields . Please Fill before submitting",
                    "mode":'dismissible'
                });
                toastEvent.fire();
                }


            if(!phoneBOBValue){
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "error",
                    "title": "Error!",
                    "message": "Incomplete Phone(Accounts Payable) fields . Please Fill before submitting",
                    "mode":'dismissible'
                });
                toastEvent.fire();
                }

            if(firstNameBoBValue && lastnameBOBValue && emailBOBValue && phoneBOBValue && !isBS){
                if(!isValidphoneBOB){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": "error",
                        "title": "Error!",
                        "message": "Please enter only numeric values in Phone Number(Accounts Payable) field!",
                        "mode":'dismissible'
                    });
                    toastEvent.fire();

                }
                else if(isValidphoneBOB && (phoneBOBValue.toString().length < 7 || phoneBOBValue.toString().length > 32)) {
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": "error",
                        "title": "Error!",
                        "message": "Phone(Accounts Payable) field should be in between 7-32 digits.!",
                        "mode":'dismissible'
                    });
                    toastEvent.fire();
                    }
                else{
                     BOBError = false;
                }
            }
            if(firstNameBoBValue && lastnameBOBValue && emailBOBValue && phoneBOBValue && isBS){
                    if(!firstNameBSValue){
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "type": "error",
                            "title": "Error!",
                            "message": "Incomplete First Name(Billing Support) fields . Please Fill before submitting",
                            "mode":'dismissible'
                        });
                        toastEvent.fire();
                        }

                    if(!lastnameBSValue){
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "type": "error",
                            "title": "Error!",
                            "message": "Incomplete Last Name(Billing Support) fields . Please Fill before submitting",
                            "mode":'dismissible'
                        });
                        toastEvent.fire();
                        }

                    if(!emailBSValue){
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "type": "error",
                            "title": "Error!",
                            "message": "Incomplete Email(Billing Support) fields . Please Fill before submitting",
                            "mode":'dismissible'
                        });
                        toastEvent.fire();
                        }
                    if(!phoneBSValue){
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "type": "error",
                            "title": "Error!",
                            "message": "Incomplete Phone(Billing Support) fields . Please Fill before submitting",
                            "mode":'dismissible'
                        });
                        toastEvent.fire();
                        }
                    if(firstNameBSValue && lastnameBSValue && emailBSValue && phoneBSValue){
                        if(!isValidphoneBS){
                            var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({
                                "type": "error",
                                "title": "Error!",
                                "message": "Please enter only numeric values in Phone Number(Billing Support) field!",
                                "mode":'dismissible'
                            });
                            toastEvent.fire();
                    	}
                        else if(isValidphoneBS && (phoneBSValue.toString().length < 7 || phoneBSValue.toString().length > 32)) {
                            var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({
                                "type": "error",
                                "title": "Error!",
                                "message": "Phone(Billing Support) field should be in between 7-32 digits.!",
                                "mode":'dismissible'
                            });
                            toastEvent.fire();
                        }
                        else if(phoneBOBValue.toString().length < 7 || phoneBOBValue.toString().length > 32) {

                            var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({
                                "type": "error",
                                "title": "Error!",
                                "message": "Phone(Accounts Payable) field should be in between 7-32 digits.!",
                                "mode":'dismissible'
                            });
                            toastEvent.fire();
                        }
                        else{
                            BOBError = false;
                        }
                    }
            }

        }
        // added for JIRA - 6286 Bill On Behalf PRM/CRM  end
        // Added for Wholesale reseller PRM - 55 PRM/CRM  start
        if (!isReseller) {
            resellerError = false;
        } else {
            if (settlementType.get('v.value') == null || settlementType.get('v.value') == '') {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "error",
                    "title": component.get("v.translationsMap.Error")+'!',
                    "message": 'Settlement Type is required'+'!',
                    "mode":'dismissible'
                });
                toastEvent.fire();
                resellerError = true;
            }
            if (settlementPartnerName == undefined || settlementPartnerName == '--None--') {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "error",
                    "title": component.get("v.translationsMap.Error")+'!',
                    "message": 'Settlement Partner Id is required'+'!',
                    "mode":'dismissible'
                });
                toastEvent.fire();
                resellerError = true;
            }
            if (settlementRatePartnerName == undefined ||  settlementRatePartnerName == '--None--') {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "error",
                    "title": component.get("v.translationsMap.Error")+'!',
                    "message": 'Settlement Rate Partner Id is required'+'!',
                    "mode":'dismissible'
                });
                toastEvent.fire();
                resellerError = true;
            }
        }
        // Added for Wholesale reseller PRM - 55 PRM/CRM end
        if(communityBrand!= undefined && (!(communityBrand.includes('RingCentral')&&masterLabel == 'ignite')))
        {
            externalSIDVal = component.find('ExternalSIDField').get("v.value");
            portalLinkIdName = component.get('v.communityDetailsRecord').Portal_Link_Id__c;
        }
        //if(phoneValue != null && phoneValue != undefined && phoneValue != '' && isNaN(phoneValue)) {
            if(phoneValue != null && phoneValue != undefined && phoneValue != '' && !isValidPhone) {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type": "error",
                "title": component.get("v.translationsMap.Error")+'!',
                "message": component.get("v.translationsMap.Please_enter_only_numeric_values_Phone")+'!',
                "mode":'dismissible'
            });
            toastEvent.fire();
        }
        //else if(mobileValue != null && mobileValue != undefined && mobileValue != '' && isNaN(mobileValue)) {
        else if(mobileValue != null && mobileValue != undefined && mobileValue != '' && !isValidMobile) {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type": "error",
                "title": component.get("v.translationsMap.Error")+'!',
                "message": component.get("v.translationsMap.Please_enter_only_numeric_values_in_Mobi")+'!',
                "mode":'dismissible'
            });
            toastEvent.fire();
        }
        //JIRA BZS-7232 phone length validation start
        else if(phoneValue != null && phoneValue != undefined && phoneValue != '' && (phoneValue.toString().length < 7 || phoneValue.toString().length > 32)) {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "error",
                    "title": "Error!",
                    "message": "Phone number field should be in between 7-32 digits.!",
                    "mode":'dismissible'
                });
                toastEvent.fire();
            }
        //JIRA BZS-7232 phone length validation end
            else if(externalSIDVal != null && externalSIDVal != undefined && externalSIDVal != '' && externalSIDVal.indexOf(' ') != -1)
            {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "error",
                    "title": "Error!",
                    "message": "Space is not allowed in " + portalLinkIdName,
                    "mode": 'dismissible'
                });
                toastEvent.fire();
            }
            else
            {
                if(onBehalf == false ||
                   (onBehalf == true && mpcId != null && mpcId != undefined && mpcId != ''))
                {
                    if(communityBrand != undefined ){
                        if(communityBrand.includes('RingCentral')&&masterLabel == 'ignite'){
                            var brandName = 'RingCentral';
                        }
                        else{
                            var brandName = communityBrand;
                        }
                    }
                    //var partnerType = component.get("v.partnerSelectedValue");
                    var fields = event.getParam("fields");
                    // Added for JIRA - 6286 start
                    var partnerType = component.get("v.selectedPartnerType");
                    //Added for BOB Second set of Changes for JIRA - 6286 start
                    var businessIdentity = component.get("v.selectedBusinessIdentity");
                    var partnerMap = component.get("v.invoiceCopyPartnerMap");
                    var invoicecopypatnerName = component.get("v.selectedInvoiceCopyPartner");
                    var notes = component.get("v.Notes");
                    console.log('::::::notes:::::'+notes);
                    //Added for BOB Second set of Changes for JIRA - 6286 end
                    // Added for PRM-55 Wholesale Reseller start
                    var settlementPartnerMap = component.get("v.settlementPartnerMap");
                    // Added for PRM-55 Wholesale Reseller end
                    if(communityBrand != undefined && communityBrand != '' && communityBrand != null){
                            fields["Partner_Type__c"] =partnerType;
                        	//Added for BOB Second set of Changes for JIRA - 6286 start
                            if(businessIdentity){
                                fields["BusinessIdentity__c"] = businessIdentity;
                            }
                            if(invoicecopypatnerName && partnerMap){
                                var invoicecopypatnerId = partnerMap.get(invoicecopypatnerName);
                                console.log('::::invoicecopypatnerName::::'+invoicecopypatnerName+'::::::invoicecopypatnerId:::::'+invoicecopypatnerId);
                                fields["Invoice_Copy_Partner_ID__c"] = invoicecopypatnerId;
                            }
                            //Added for BOB Second set of Changes for JIRA - 6286 end
                            // Added for Wholesale reseller PRM-55 start
                            if (isReseller) {
                                if (settlementPartnerName && settlementPartnerMap) {
                                    fields["Settlement_Partner_ID__c"] = settlementPartnerMap.get(settlementPartnerName);
                                }
                                if (settlementRatePartnerName && settlementPartnerMap) {
                                    fields["Settlement_Rate_Partner_ID__c"] = settlementPartnerMap.get(settlementRatePartnerName);
                                }
                                fields["Reseller_Partner_Type__c"] = 'Regular Partner';
                            }
                            // Added for Wholesale reseller PRM-55 end
                    }
                    // Added for JIRA - 6286 end
                    if(communityBrand != undefined ){
                        if(communityBrand.includes('Avaya Cloud Office')){
                            var companyNameTmp = fields["Partner_Company_Name__c"] +' - ACO';
                            fields["Partner_Company_Name__c"] = companyNameTmp;
                            //fields["Partner_Type__c"] ="Avaya";
                        }else{
                            var companyNameTmp = fields["Partner_Company_Name__c"] +' - '+brandName;
                            fields["Partner_Company_Name__c"] = companyNameTmp;
                        }
                    }
                    if(communityBrand != undefined ){
                        if(!(communityBrand.includes('RingCentral')&&masterLabel == 'ignite')){
                            fields["External_SID__c"] = externalSIDVal;
                        }
                    }
                    fields["Avaya_Partnership_Reg__c"]=true;
                    fields["Brand_Name__c"] = brandName;
                    if(communityBrand != undefined ){
                        if(communityBrand.includes('RingCentral')&&masterLabel == 'ignite'){
                            fields["Partner_Type__c"] ='Master Agent';
                            fields["Partner_Request_Source__c"] = 'Distributor';
                        }
                        else
                        {
                            //fields["Partner_Type__c"] =component.get('v.communityDetailsRecord').Portal_Partner_Type__c;
                        }
                    }
                   	if(notes){
                        fields["Notes__c"] = notes;
                    }
                    fields["Partner_Role__c"] = "General Partner";
                    if(onBehalf == true){
                        fields["Master_Partner_Contact__c"]=mpcId;
                        fields["AD__c"] = "Yes";
                        //fields["Partner_Role__c"] = "General Partner";
                    }else{
                        fields["AD__c"] = "No";
                        //fields["Partner_Role__c"] = "Master Agent";
                    }
                    // Added for JIRA - 6994 start
                // Country
                fields['Partner_Country__c'] = component.find("selectedCountry").get("v.value");

                //State
                var selectCmp = component.find("selectedState");

                if (selectCmp != null ) {
                    if (selectCmp.get('v.disabled')) {
                        selectCmp.set('v.disabled', false);
                        fields['Partner_State__c'] = '-- None --';
                    } else {
                        fields['Partner_State__c'] = component.find("selectedState").get("v.value");
                    }
                }
                // Added for PRM - 55 start
                if (settlementType != undefined) {
                    fields['Settlement_Type__c'] = settlementType.get('v.value');
                }
                if (billingFeedtype != undefined && billingFeedtype.get('v.value')) {
                    fields['Billing_Feed_Type__c'] = billingFeedtype.get('v.value');
                }
                // Added for PRM - 55 end
                // Added for JIRA - 6994 end
                    var email = component.find("emailAddress").get("v.value");
                    var confirmEmail = component.find("confirmEmail").get("v.value");
                    if(email==confirmEmail){
                        //added - shruthi chunchu for JIRA - 6286 Bill On Behalf PRM/CRM start
                        if(BOBError == false && !resellerError){
                        component.find('partnerRegistrationForm').submit(fields);
                        }
                        //added - shruthi chunchu for JIRA - 6286 Bill On Behalf PRM/CRM end
                    }
                    else {
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "type": "error",
                            "title": component.get("v.translationsMap.Error")+'!',
                            "message": component.get("v.translationsMap.The_email_does_not_match_Please_check_a"),
                            "mode":'dismissible'
                        });
                        toastEvent.fire();
                    }

                }
                else{
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": "error",
                        "title": component.get("v.translationsMap.Error")+'!',
                        "message": component.get("v.translationsMap.Please_choose_a_Partner_Contact_before_s")+'!',
                        "mode":'dismissible'
                    });
                    toastEvent.fire();
                }
            }
    },
    handleSuccessPR : function(component, event, helper) {

        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type": "success",
            "title": component.get("v.translationsMap.Success")+'!',
            "message": component.get("v.translationsMap.The_record_has_been_Saved_successfully"),
            "mode":'dismissible'
        });
        toastEvent.fire();
        var pageNumber_pr = 1;
        var pageSize_pr = 50;
        helper.getPartnerRegistrations(component,pageNumber_pr,pageSize_pr);
        component.set("v.newParterVisible", false);
        component.set("v.selTabId",'registeredPartners');

    },
    handleErrorPR : function(component, event, helper) {
        var err = event.getParam('error');
        console.log('err>'+JSON.stringify(err));
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type": "error",
            "title":  component.get("v.translationsMap.Error")+'!',
            "message":  component.get("v.translationsMap.There_was_some_error_during_processing"),
            "mode":'dismissible'
        });
        toastEvent.fire();
    },

    //METHODS TO DISPLAY SPINNER
    showSpinner: function(component, event, helper) {
		var spinner = component.find("loadingSpinner");
        $A.util.removeClass(spinner, "slds-hide");
        console.log('loading');
    },
    hideSpinner : function(component,event,helper){
        var spinner = component.find("loadingSpinner");
        $A.util.addClass(spinner, "slds-hide");
         console.log('loaded');

    },
    showNewBehalfSectionArea:function (component, event, helper) {
        component.set('v.NewOnBehalf',true);
        component.set('v.newParterVisible', true);
        component.set('v.selTabId','partnerTabRegistration');
    },
    createLookup :function (component, event, helper) {
        var contactName = component.get('v.masterPartnerAccountName');
        $A.createComponent("c:Partner_LookupSearch",{"searchKeyword":contactName,"isMasterPartner":true},
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
        var partnerId = event.getParam("PartnerId");
        var partnerAccount = event.getParam("PartnerAccountName");
        var accid = event.getParam("AccountId");//Added for BOB second set of changes for JIRA - 6286
        component.set('v.masterPartnerContactId',conId);
        component.set('v.masterPartnerContactName',conName);
        component.set('v.masterPartnerAccountName',partnerAccount);
        component.set('v.masterPartnerId',partnerId);
        component.set('v.NGBSAccId',accid);//Added for BOB second set of changes for JIRA - 6286
        helper.getListofMasterAgents(component,event,helper,accid);
    },
     createUserShowAlert : function(component,event,helper){
         var contact = event.getSource().get("v.value");
         component.set('v.userContact',contact);
         helper.createUserNameForNewUser(component, event, helper);
         component.set('v.showConfirmModal',true);
    },
    VerifyUserShowAlert : function(component,event,helper){
        var userNameInput = component.get("v.userNameInput");
        var userNameSuffix = component.get("v.userNameSuffix");
        var toastEvent = $A.get('e.force:showToast');
        if(userNameInput != null && userNameInput != ''){
            if(userNameInput.indexOf('@') == -1 || userNameInput.indexOf('.') == -1
               || userNameInput.startsWith('.') || userNameInput.startsWith('@')
               || userNameInput.endsWith('@') || userNameInput.endsWith('.')
               || userNameInput.indexOf('.') == userNameInput.indexOf('@')+1){
                toastEvent.setParams({
                    'title': component.get("v.translationsMap.Error")+'!',
                    'type': 'error',
                    'mode': 'dismissable',
                    'message': component.get("v.translationsMap.Please_Enter_a_valid_user_name")
                });
                toastEvent.fire();
            }else{
                //if(!userNameInput.endsWith('.aco')){
                if(!userNameInput.endsWith(userNameSuffix)){
                    //userNameInput = userNameInput + '.aco';
                    userNameInput = userNameInput + userNameSuffix;
                }
                helper.verifyIfUserNameExists(component, userNameInput);
            }
        }else{
            toastEvent.setParams({
                'title': component.get("v.translationsMap.Error")+'!',
                'type': 'error',
                'mode': 'dismissable',
                'message': component.get("v.translationsMap.Please_Enter_a_valid_user_name")
            });
            toastEvent.fire();
        }
        //component.set('v.isDuplicateUserName',false);
        component.set('v.isBackButtonClicked',false);
        component.set('v.showConfirmModal',true);
    },
    createUser:function(component, event, helper) {
        var yesOrNo = event.getSource().get("v.value");
        var userNameInput = component.get("v.userNameInput");
        var isDuplicateUserName = component.get("v.isDuplicateUserName");
        if(yesOrNo == 'Yes'){
            helper.createUserforContact(component, event, helper);
            component.set('v.showConfirmModal',false);
        }else if(yesOrNo == 'Back'){
            component.set('v.isBackButtonClicked',true);
            component.set('v.isDuplicateUserName',true);
            component.set('v.showConfirmModal',true);
        }else{
            component.set('v.isBackButtonClicked',false);
            component.set('v.isDuplicateUserName',false);
            component.set('v.userNameInput','');
            component.set('v.showConfirmModal',false);
        }
    },

    editDetail: function(component, event, helper) {
        component.set('v.ShowSpinnerOpp',true);
        component.set('v.showDetailSection',false);
        component.set('v.showEditSection',true);
        component.set('v.ShowSpinnerOpp',false);
    },

    closeEditSection: function(component, event, helper) {
        try
        {
            var url = new URL(location.href);
            var urlEvent = $A.get("e.force:navigateToURL");
            urlEvent.setParams({
                'url':window.location.pathname +'?id=' +url.searchParams.get('id')
            });
            urlEvent.fire();
        }
        catch(e)
        {
            console.log('error - ' + e);
        }
    },

    successPartnerEdit : function(component, event, helper) {
        component.set('v.ShowSpinnerOpp',false);
        var record = event.getParam("response");
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type": "success",
            "title": component.get("v.translationsMap.Success")+'!',
            "message": component.get("v.translationsMap.The_record_has_been_Saved_successfully"),
            "mode":'dismissible'
        });
        toastEvent.fire();
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            'url':window.location.pathname +'?id=' +record.id
        });
        urlEvent.fire();
    },

    submitPartnerEdit : function(component, event, helper) {
        try
        {
            component.set('v.ShowSpinnerOpp',true);
            let brandName = component.get('v.communityDetailsRecord').Brand_Name__c;
            var masterLabel = component.get("v.communityDetailsRecord").MasterLabel;
			  // Added for PBC 10653
                let managerEmail;
                if(brandName != undefined && brandName ==='Unify Office'){
                    managerEmail =component.find('managerEmails').get("v.value");
                }
            if(brandName != undefined && (!(brandName.includes('RingCentral')&&masterLabel == 'ignite')))
            {
                event.preventDefault();
                let externalSIDVal = component.find('ExternalSIDField').get("v.value");
                let portalLinkIdName = component.get('v.communityDetailsRecord').Portal_Link_Id__c;
                if(externalSIDVal.indexOf(' ') != -1)
                {
                    component.set('v.ShowSpinnerOpp',false);
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": "error",
                        "title": "Error!",
                        "message": "Space is not allowed in " + portalLinkIdName,
                        "mode": 'dismissible'
                    });
                    toastEvent.fire();
                    return;
                }
                var fields = event.getParam("fields");
                fields["External_SID__c"] = externalSIDVal;
                // Added for PBC 10653
                component.find('partnerEditForm').submit(fields);
            }
        }
        catch(e)
        {
            console.log('exception - ' + e);
        }
    },
    // Added for PRM-55 start
    onPartnerRequiresBillingFeedChange: function(component, event, helper) {
        var value = event.getSource().get("v.value");
        var billingFeedTypesMap = component.get('v.billingFeedTypesMap');
        console.log(billingFeedTypesMap[value] + ' billingFeedTypesMap[value] ' + value);
        component.set('v.availableBillingFeedTypes',billingFeedTypesMap[value]);

        if (value == 'Yes') {
            component.set('v.showBillingFeedType',true);
        } else {
            component.set('v.showBillingFeedType',false);
        }
    },
    // Added for PRM-55 end

})