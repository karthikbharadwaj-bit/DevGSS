({
	myAction : function(component, event, helper) {
        component.set("v.ShowSpinnerOpp", true);
        var brandVal = component.find("brand").get("v.value");
        //component.set("v.ShowSpinnerOpp", false);
        component.set("v.partnerContactName", null);
		// BZS-9016 Country BI mapping CS Values
        function setBICountriesCSList(result) {
            const state = result.getState();
            if (state === 'SUCCESS') {
                const resultData = result.getReturnValue();
                if (resultData != null) {
                    component.set("v.BICountriesCSList", resultData);
                }
            }
        }
        const BICountriesCSList = component.get("c.getBICountriesCSList");
        BICountriesCSList.setCallback(this, setBICountriesCSList);
        $A.enqueueAction(BICountriesCSList);
	},

    nextNav : function(component, event, helper) {
        component.set("v.isWholesalePartner", false);
       	var brandVal = component.get("v.brandName");
        if(brandVal != null && brandVal != ''){
            component.set("v.ShowSpinnerOpp", true);
            component.set("v.ShowSection", true);
           // component.find("tierSelect").set("v.value", 'Office');

            var brnd = 'RingCentral';
            if(brandVal.includes(brnd)){
                helper.getCountryStateValues(component,event,helper);
            }else{
               helper.onChangeBrand(component,event,helper,brandVal,'');
            }
            var str = 'RingCentral';
            if(brandVal == 'RingCentral'||brandVal == 'RingCentral UK'||brandVal == 'RingCentral Canada'||brandVal == 'RingCentral EU'||brandVal == 'RingCentral AU'){
                component.set("v.ShowOnlyRC", true);
            }
            var str1 = 'Unify Office';
            if(brandVal.includes(str1)){
                component.set("v.ShowOnlyATOS", true);
            }
        }

    },

    goBack : function(component, event, helper) {
        component.set("v.ShowSpinnerOpp", true);
        component.set("v.ShowSection", false);
        var brandVal = component.get("v.brandName");
        component.find("brand").set("v.value", brandVal);
        component.set("v.ShowOnlyRC", false);
        component.set('v.partnerContactName',null);
        component.get('v.ShowOtherExistingSoln',false);
        component.get('v.ShowOtherCompetitor',false);
        component.get('v.ShowOtherPrompting',false);
        component.get('v.ShowOtherDecision',false);
        component.set('v.searchUser',null);
        component.set('v.isNationalPartnerAccount',false);
        component.set('v.showMitelCustomerType',false);
        component.set('v.ShowMitelDataShare',false);
        component.set('v.psPartnerId',null);
    },

    goBackListView : function(component, event, helper) {
        const retURL = new URL(window.location).searchParams.get("retURL");
        console.log('retURL>'+retURL);
        if (retURL) {
            window.open(retURL, '_parent');
        }
    },

    //Create lookup for Contact
    createLookup : function(component, event, helper){
        var str = true;
        var contactName = component.get('v.partnerContactName');
        $A.createComponent("c:Partner_LookupSearch",
                           {"searchKeyword":contactName,
                            "isSFDC": str,
                            "brandName":component.get("v.brandName")},
                           function(createPartnerComponent, status, errorMessage){
                               if (status === "SUCCESS") {
                                   console.log('createPartnerComponent '+createPartnerComponent)
                                   var lookupDiv = component.find('lookupSearchDiv').get('v.body');
                                   lookupDiv.push(createPartnerComponent);
                                   component.find('lookupSearchDiv').set('v.body', lookupDiv);
                               }
                           }
                          );
    },
    handlePartnerComponentEvent:function(component, event, helper) {
        var brandPreviousVal = component.get("v.brandName");
        var conId = event.getParam("Id");
        var conName = event.getParam("Name");
        var partnerId = event.getParam("PartnerId");
        var accountPartnerType= event.getParam("accountPartnerType");
        const partnerClassification = event.getParam("partnerClassification"); //PBC-9705 P2CSharing
        component.set("v.partnerClassification", partnerClassification); //PBC-9705 P2CSharing
        console.log("partnerContactId"+conId);
        var acc = event.getParam("PartnerAccount");
        if(acc == false){
            component.set('v.partnerContactId',conId);
            component.set('v.partnerContactName',conName);
            component.set('v.partnerId',partnerId);
            component.set('v.psPartnerId',conId);
        }
        var isWholesalePartnerAcc = accountPartnerType != undefined && accountPartnerType.toLowerCase().includes('wholesale-reseller');// BZS-9016
        try {
            if (isWholesalePartnerAcc) {
                component.set("v.isWholesalePartner", true);
                const BI = event.getParam("businessIdentity");
                helper.getBrandCountriesForBI(component, event, helper, BI);
            }
            else {
                component.set("v.isWholesalePartner", false);
            }
        }
        catch (e) {
            console.error('errbi - ' + e);
        }
        const brandsListforBI = component.get("v.brandsListforBI");
        const countriesforBIList = component.get("v.countriesforBI");

        //Added for multiple countries in ACO 3.0
        var partnerAvailableCountries = event.getParam("partnerAvailableCountries");
        var brandVal = component.get("v.brandName");
        var partnercountry = component.get("v.logdPartnrCntry");
        console.log("partnerAvailableCountries"+partnerAvailableCountries);
        // BZS-9016
        if (isWholesalePartnerAcc && brandPreviousVal != brandVal) {
            helper.getCountryStateValues(component,event,helper);
        }
        var countriesArr = [];
        if(partnerAvailableCountries != undefined && partnerAvailableCountries != null && partnerAvailableCountries != ''){
            for(var k=0;k<partnerAvailableCountries.split(';').length;k++){
                countriesArr.push(partnerAvailableCountries.split(';')[k]);
            }
            component.set("v.partnerAvailableCountries",countriesArr);
            if (isWholesalePartnerAcc){
                if (brandsListforBI != undefined && brandsListforBI.length > 0 && countriesforBIList != undefined && countriesforBIList.length > 0) {
                    helper.onChangeBrand(component, event, helper, brandsListforBI[0], countriesforBIList[0]);
                }
            } else {
                helper.onChangeBrand(component,event,helper,brandVal,partnercountry);
            }
        }else{
            component.set("v.partnerAvailableCountries",countriesArr);
        }
        helper.selectAccountDetail(component,event,helper,partnerId);

        var accountVARTerritory= event.getParam("accountVARTerritory");
        var accountPartnerType= event.getParam("accountPartnerType");
        var accountMasterAgentChlMgr=event.getParam("accountMasterAgentChlMgr");

        console.log('accountVARTerritory' +accountVARTerritory);
        console.log('accountPartnerType' +accountPartnerType);
        console.log('accountMasterAgentChlMgr'+accountMasterAgentChlMgr);
        var acc = event.getParam("PartnerAccount");
        if(acc == false){
            component.set('v.partnerContactId',conId);
            component.set('v.partnerContactName',conName);
            component.set('v.partnerId',partnerId);
            if(component.get("v.ShowOnlyRC") == true){
                // Added for BZS-9016 - start
                if (isWholesalePartnerAcc){
                    if (brandsListforBI != undefined && brandsListforBI.length > 0 && countriesforBIList != undefined && countriesforBIList.length > 0) {
                        helper.onChangeBrand(component, event, helper, brandsListforBI[0], countriesforBIList[0]);
                    }
                } else {
                    helper.onChangeBrand(component,event,helper,brandVal,partnercountry);
                }
                // Added for BZS-9016 - end
                if(accountVARTerritory != undefined && accountPartnerType != undefined){
                    if(accountVARTerritory.includes('NAM') && accountPartnerType.includes('Master Agent')){
                        component.set('v.isNationalPartnerAccount',true);
                    }else{
                        component.set('v.isNationalPartnerAccount',false);
                    }
                }else{
                    component.set('v.isNationalPartnerAccount',false);
                }
                console.log('isNationalPartnerAccount'+ component.get('v.isNationalPartnerAccount'));
            }
            else {
                if (isWholesalePartnerAcc){
                    if (brandsListforBI != undefined && brandsListforBI.length > 0 && countriesforBIList != undefined && countriesforBIList.length > 0) {
                        helper.onChangeBrand(component, event, helper, brandsListforBI[0], countriesforBIList[0]);
                    }
                } else {
                    helper.onChangeBrand(component,event,helper,brandVal,partnercountry);
                }
            }
        }
    },

    onchangeCountry:function(component,event,helper){
        var selctedValue = event.getSource().get("v.value");
        component.set('v.selectedCountry',selctedValue);
        helper.onchangeCountry(component,event,helper,selctedValue);
    },

    //Method on SUBMIT
    handleSubmitNew: function(component, event, helper) {
        event.preventDefault();
        component.set('v.ShowSpinnerOpp',true);
        var pcId = component.get('v.partnerContactId');

        var phoneField = component.find('phoneNumber');
        var phoneValue = phoneField.get('v.value');
        const partnerClassification = component.get("v.partnerClassification"); //PBC-9705 P2CSharing

        var emailIdField = component.find('emailId');
        var emailIdValue = emailIdField.get('v.value');

        var regex1  = new RegExp("^[0-9 ,+()-]*$");
        var isValidPhone = regex1.test(phoneValue);
        var valTmp = component.get("v.selectedCompItems").toString().replace(/,/g,';');

        var noOfEmp = component.find("selectedEmp").get("v.value");
        console.log('noOfEmp>>' + noOfEmp);
        //added for PRM-145 starts
        var isMitelProspect = '';
        var mitelCustomerType = '';
        var mitelDataShare ='';
		var partnerProgram ='';//added for QTC-943
        var selectedPSVal = component.get("v.selectedProviderValue");
        if(component.get("v.ShowOnlyRC")){
            isMitelProspect = component.find("isMitelProspect").get("v.value");
            if(isMitelProspect !='' && isMitelProspect != null && isMitelProspect.includes('Yes'))
                mitelCustomerType = component.find("mitelCustomerType").get("v.value");
            //PBC-9705 P2CSharing; PBC-11950
            if(mitelCustomerType !='' && mitelCustomerType != null && (partnerClassification == 'Mitel Referral' || partnerClassification == '' || partnerClassification == null) && mitelCustomerType.includes('Existing Premise Based Customer'))
                mitelDataShare=component.find('mitelDataShare').get('v.value');
            //added for qtc-943 starts
            partnerProgram = component.find('PartnerProgram').get("v.value");
            //added for qtc-943 ends
        }
        //added for PRM-145 ends
        if(phoneValue != null && phoneValue != undefined && phoneValue != '' && !isValidPhone) {
            component.set("v.toastMesg",'Please enter only numeric values in Phone Number field!');
            component.set("v.mesgType", 'error');
            var a = component.get('c.showToast');
        	$A.enqueueAction(a);
            console.log("Please enter only numeric values in Phone Number field!");
        }else if(valTmp == null || valTmp == undefined || valTmp == ''){
            component.set("v.toastMesg",'Please choose one Competitor!');
            component.set("v.mesgType", 'error');
            var a = component.get('c.showToast');
        	$A.enqueueAction(a);
            console.log("Please choose one Competitor!");
        }
        else if (noOfEmp == null || noOfEmp == undefined || noOfEmp == '' || noOfEmp == '-- None --') {
            component.set("v.toastMesg",'Please choose Number of Employees!');
            component.set("v.mesgType", 'error');
            var a = component.get('c.showToast');
        	$A.enqueueAction(a);
            console.log("Please choose Number of Employees!");
        } else if(component.get("v.ShowOnlyRC") && (isMitelProspect == null || isMitelProspect == undefined || isMitelProspect == '' || isMitelProspect == '-- None --') ){
            component.set("v.toastMesg",'Please choose Is This a Mitel Customer or Prospect!');
            component.set("v.mesgType", 'error');
            var a = component.get('c.showToast');
            $A.enqueueAction(a);
        }else if(component.get("v.ShowOnlyRC") && (isMitelProspect.includes('Yes')) && (mitelCustomerType == null || mitelCustomerType == undefined || mitelCustomerType == '' || mitelCustomerType == '-- None --')){
            component.set("v.toastMesg",'Please choose What Type of Mitel Customer or Prospect!');
            component.set("v.mesgType", 'error');
            var a = component.get('c.showToast');
            $A.enqueueAction(a);
        }
        //PBC-9705 P2CSharing; PBC-11950
        else if(component.get("v.ShowOnlyRC") && (partnerClassification == 'Mitel Referral' || partnerClassification == '' || partnerClassification == null) && (mitelCustomerType.includes('Existing Premise Based Customer')) && (mitelDataShare == null || mitelDataShare == undefined || mitelDataShare == '' || mitelDataShare == '-- None --')){
            component.set("v.toastMesg",'Please choose if you agree to share data for this deal with Mitel!');
           component.set("v.mesgType", 'error');
           var a = component.get('c.showToast');
           $A.enqueueAction(a);
       }
	   //added for QTC-943 starts
        else if(component.get("v.ShowOnlyRC") && (partnerProgram == null || partnerProgram == undefined || partnerProgram == '' || partnerProgram == '-- None --')){
               component.set("v.toastMesg",'Please choose Partner Program!');
           component.set("v.mesgType", 'error');
           var a = component.get('c.showToast');
           $A.enqueueAction(a);
            }
        //added for QTC-943 ends
        else if(selectedPSVal == null || selectedPSVal == undefined || selectedPSVal == '' || selectedPSVal == '--Please Select--') {
        	component.set("v.toastMesg",'Please choose Valid Option for Installation Service Provider!');
            component.set("v.mesgType", 'error');
            var a = component.get('c.showToast');
            $A.enqueueAction(a);
        }
		else{
            if(pcId != null && pcId != undefined && pcId != ''){
                var fields = event.getParam("fields");
                fields["Avaya_Partnership_Deal__c"] =true;
                fields["Partner_Contact__c"]=pcId;
                var brandName = component.get("v.brandName");
                fields["Brand_Name__c"] = brandName;
                var chosenCloudSpecialistValue = component.get("v.cloudSpecialistContactId");
                if (chosenCloudSpecialistValue != null && chosenCloudSpecialistValue != undefined && chosenCloudSpecialistValue != '') {
                    fields['Avaya_Cloud_Specialist__c'] = chosenCloudSpecialistValue; //pbc-10695
                }
                // Deal country
                fields['Country__c'] = component.find("selectedCountry").get("v.value");

                //Deal State
                var selectCmp = component.find("selectedState");

                if(selectCmp != null && selectCmp.get('v.disabled')){
                    selectCmp.set('v.disabled',false);
                    fields['State__c'] = '';
                }else{
                    fields['State__c'] =component.find("selectedState").get("v.value");
                }
                console.log('brandName'+brandName);

                var empCmp = component.find("selectedEmp");
                if (empCmp != null && empCmp.get('v.disabled')) {
                    empCmp.set('v.disabled', false);
                    fields['Number_of_Employees__c'] = '-- None --';
                } else {
                    fields['Number_of_Employees__c'] = component.find("selectedEmp").get("v.value");
                }

                var valTmp = component.get("v.selectedCompItems").toString().replace(/,/g,';');
                fields['Competitor_s__c'] = valTmp;
                console.log('valTmpcomp>'+valTmp);
                if(valTmp == undefined || valTmp == null || valTmp == ''){
                    component.set("v.toastMesg",'Please choose one Competitor!');
                    component.set("v.mesgType", 'error');
                    var a = component.get('c.showToast');
        			$A.enqueueAction(a);

                    console.log("Please choose any one Competitor");
                    return;
                }
                //added for mitel prm-283
                var mitelCustomerType = '';
                var isMitelProspect ='';
                if(component.get("v.ShowOnlyRC")){
                    isMitelProspect = component.find("isMitelProspect").get("v.value");
                    if(isMitelProspect !='' && isMitelProspect != null && isMitelProspect.includes('Yes'))
                        mitelCustomerType = component.find("mitelCustomerType").get("v.value");
                }
                //PBC-9705 P2CSharing; PBC-11950
                if(mitelCustomerType !='' && mitelCustomerType != null &&
                (((partnerClassification == 'Mitel Referral' || partnerClassification == '' || partnerClassification == null) && mitelCustomerType == 'Existing Cloud Customer') ||
                partnerClassification == 'Mitel Referral P2C Sharing'))
                    fields['Mitel_Data_Sharing__c'] = 'Yes';
                var selectedPSVal = component.get("v.selectedProviderValue");
                fields['Installation_Service_Provider__c'] = selectedPSVal;
                //added for mitel prm-283 ends
                var insideSalesRep =component.get("v.insideSalesRep");
                if(insideSalesRep != null && insideSalesRep !=undefined && insideSalesRep !=''){
                    fields['Inside_Sales_Rep__c'] = insideSalesRep;
                    console.log('insideSalesRep - '+ fields['Inside_Sales_Rep__c']);
                }

                var userValue = component.find("userId");
                userValue = Array.isArray(userValue) ? userValue[0].get("v.value") : userValue.get("v.value");

                var val = Math.sign(userValue);
                console.log('val>'+val);
                if(val==1){
                    component.find('newRecordFormSection').submit(fields);
                }else{
                    component.set("v.toastMesg",'Forecasted Users cannot be 0 or negative');
                    component.set("v.mesgType", 'error');
                    var a = component.get('c.showToast');
        			$A.enqueueAction(a);
                        console.log("Forecasted Users cannot be 0 or negative");
                    }
            }else{
                component.set("v.toastMesg",'Please choose a Partner Contact before submitting!');
                component.set("v.mesgType", 'error');
                var a = component.get('c.showToast');
        		$A.enqueueAction(a);
                    console.log("Please choose a Partner Contact before submitting!");
                }
        }
    },

    //METHOD TO HANDLE SUCCCESS
    handleSuccessNew : function(component, event, helper) {
        component.set('v.ShowSpinnerOpp',false);
        var record = event.getParam("response");
    	console.log('Record>'+JSON.stringify(record.id));
        var urlString = window.location.href;
        var baseURL = urlString.substring(0, urlString.indexOf("apex/"));
        var recUrl = baseURL + record.id;
        console.log('urlString >'+urlString);
        console.log('recUrl>>'+recUrl);
        component.set("v.toastMesg",'The record has been submitted successfully! Redirecting to record page...');
        component.set("v.mesgType", 'success');
        var a = component.get('c.showToast');
        $A.enqueueAction(a);
        setTimeout(function(){
            if(recUrl){
                window.open(recUrl, '_self');
            }
        }, 3000);

    },
    //METHOD TO HANDLE ERROR
    handleError : function(component, event, helper) {
        console.log("Is ERROR");

        var err = event.getParam('error');
        console.log('event>>'+event);
        console.log('error>>'+JSON.stringify(err));
        component.set("v.toastMesg",'There was some error during processing!');
        component.set("v.mesgType", 'error');
        var a = component.get('c.showToast');
        $A.enqueueAction(a);
    },

    //METHODS TO DISPLAY SPINNER
    showSpinner: function(component, event, helper) {
        var spinner = component.find("loadingSpinner");
        $A.util.removeClass(spinner, "slds-hide");
    },

    hideSpinner : function(component,event,helper){
        var spinner = component.find("loadingSpinner");
        $A.util.addClass(spinner, "slds-hide");
    },

    brandChange:function(component,event,helper){
        var brandVal = component.find("brand").get("v.value");
        console.log("Brand>"+brandVal);
        component.set("v.brandName", brandVal);
        helper.getCountryStateValues(component,event,helper);
        //helper.onChangeBrand(component,event,helper);
        if(brandVal == 'Rainbow Office')
             component.set("v.ShowOnlyALE", true); //pbc-10695
        else
            component.set("v.ShowOnlyALE", false); //pbc-10695
        helper.getCommunityDetail(component, event, helper); //pbc-10695
        component.set("v.cloudSpecialistContactId", null); //pbc-10695
    },

    existingChange:function(component,event,helper){
        var existingfieldValue = component.find("existing").get("v.value");
        console.log("existingField>"+existingfieldValue);
        if(existingfieldValue=='Other'){
            component.set("v.ShowOtherExistingSoln",true);
        }
        else
            component.set("v.ShowOtherExistingSoln",false);

    },
    competitorChange:function(component,event,helper){
        var selectedCompOption = event.getParam("value");
        component.set("v.selectedCompItems" , selectedCompOption);
        var competitorfieldValue = component.find("competitor").get("v.value");
        competitorfieldValue = competitorfieldValue.toString().toLowerCase();
        if(competitorfieldValue.includes('other')){
            component.set("v.ShowOtherCompetitor",true);
        }else{
            component.set("v.ShowOtherCompetitor",false);
        }
        /*
        var competitorfieldValue = component.find("competitor").get("v.value");
        if(competitorfieldValue.includes("Other")){
            component.set("v.ShowOtherCompetitor",true);
        }
        else{
            component.set("v.ShowOtherCompetitor",false);
        }*/
        /*var selectedCompOption = event.getParam("value");
        component.set("v.selectedCompItems" , selectedCompOption);
        console.log('selectedCompOption ' +selectedCompOption);
        var competitorfieldValue = component.find("competitor").get("v.value");
        competitorfieldValue = competitorfieldValue.toString().toLowerCase();
        if(competitorfieldValue.includes('other')){
            component.set("v.ShowOtherCompetitor",true);
        }else{
            component.set("v.ShowOtherCompetitor",false);
        }*/
    },
    promptingChange:function(component,event,helper){
        var promptingfieldValue = component.find("prompting").get("v.value");
        if(promptingfieldValue.includes("Other")){
            component.set("v.ShowOtherPrompting",true);
        }
        else{
            component.set("v.ShowOtherPrompting",false);
        }
    },
    decisionChange:function(component,event,helper){
        var decisionfieldValue = component.find("decision").get("v.value");
        if(decisionfieldValue=='Other'){
            component.set("v.ShowOtherDecision",true);
        }
        else{
            component.set("v.ShowOtherDecision",false);
        }
    },

    showToast : function(component, event, helper) {
        console.log('Selected State >>'+component.find("selectedState").get("v.value"));
        var type = component.get("v.mesgType");
        if(type == 'error'){
            component.set("v.ShowErrorMesg", true);
        }
        else{
            component.set("v.ShowErrorMesg", false);
            component.set("v.ShowMesg", true);
        }
    },
    hideToast : function(component, event, helper) {
        component.set("v.ShowErrorMesg", false);
    },

    onInputChange : function (component, event, helper) {
        var searchContent = component.get("v.searchUser");
        var userPaneCmp = component.find("userPane");
        var dropDownPane = component.find("dropDownList");
        console.log('searchContent'+searchContent);
        if ( searchContent && searchContent.trim().length > 0 ) {
            searchContent = searchContent.trim();
            $A.util.addClass(userPaneCmp,"slds-is-open");
            $A.util.removeClass(userPaneCmp,"slds-is-close");
            helper.searchUsers(component,event, helper,searchContent);
        } else {
            $A.util.removeClass(userPaneCmp,'slds-is-open');
            $A.util.addClass(userPaneCmp,'slds-is-close');
        }

    },

    selectedUser: function (component, event, helper) {
        var ctarget = event.currentTarget;
        var selectedUserId = ctarget.dataset.userid;
        var selectedUserName = ctarget.dataset.username;
        console.log('selectedUserId>'+selectedUserId);
        console.log('selectedUserName>'+selectedUserName);
        if(selectedUserName !=undefined && selectedUserName !=null && selectedUserName !=''){
            var userPaneCmp = component.find("userPane");
            $A.util.removeClass(userPaneCmp,'slds-is-open');
            $A.util.addClass(userPaneCmp,'slds-is-close');
            component.set("v.searchUser",selectedUserName);
            component.set("v.insideSalesRep",selectedUserId);
            console.log('user set>' +component.get("v.searchUser"));
        }else{
            var userPaneCmp = component.find("userPane");
            $A.util.removeClass(userPaneCmp,'slds-is-open');
            $A.util.addClass(userPaneCmp,'slds-is-close');
        }
    },

    hideOnBlur: function (component, event, helper) {
        console.log('inside blur');
        var userPaneCmp = component.find("userPane").getElement();
        var userPaneCmp1 = component.find("usersearch");
        userPaneCmp.focus();
        console.log('userr focus>'+userPaneCmp);
        console.log('event.getSource().get("v.value").trim()>'+event.getSource().get("v.value").trim());
        console.log('event.currentTarget>'+event.currentTarget);
        console.log('inside blur if');
        $A.util.removeClass(userPaneCmp1,'slds-is-open');
        $A.util.addClass(userPaneCmp1,'slds-is-close');
    },
    previewFile :function(component,event,helper){
        console.log('inside preview');
        var rec_id;
        rec_id = component.get("v.territoryAlignmentMap");

        $A.get('e.lightning:openFiles').fire({
            recordIds: [rec_id]
        });
    },

    //added for PRM-145
    handleIsMitelProspect: function(component,event,helper){
        var isMitelProspect = component.find("isMitelProspect").get("v.value");
        console.log('isMitelProspect'+isMitelProspect);
        if(isMitelProspect.includes('Yes'))
            component.set("v.showMitelCustomerType",true);
        else{
            component.find("mitelCustomerType").reset();
            component.set("v.showMitelCustomerType",false);
            component.set("v.ShowMitelDataShare", false);
        }
    },
    changeMitelType: function(component,even,helper){
        var mitelCustomerType = component.find("mitelCustomerType").get("v.value");
        const partnerClassification = component.get("v.partnerClassification"); //PBC-9705 P2CSharing
        //PBC-9705 P2CSharing; PBC-11950
        if ((partnerClassification == 'Mitel Referral' || partnerClassification == '' || partnerClassification == null) && mitelCustomerType =='Existing Premise Based Customer') {
            component.set("v.ShowMitelDataShare", true);
        } else {
            const mitelDataShare = component.find("mitelDataShare");
            if(mitelDataShare != undefined)
                mitelDataShare.reset();
            component.set("v.ShowMitelDataShare", false);
        }
    },
    showtooltip : function(component, event, helper) {
        helper.toggleHelper(component, event);
    },

    hidetooltip : function(component, event, helper) {
        helper.toggleHelper(component, event);
    },

    handleCloudSpecialistEvent: function (component, event, helper) {
        //pbc-10695
        var cloudSpecialistContactId = event.getParam("cloudSpecialistContactId");
        component.set("v.cloudSpecialistContactId", cloudSpecialistContactId);
    },
    getPickListValuesPS: function(component, event, helper) {
      component.set('v.ShowISPField',false);
      var partnerContact = event.getParam("value");
      if (partnerContact != null) {
        helper.getPSPicklistValues(component,event,helper,partnerContact);
      }
    },
    toggledisplayTextON: function(component, event, helper) {
      component.set('v.displayText',true);
    },
    toggledisplayTextOFF: function(component, event, helper) {
      component.set('v.displayText',false);
    }
})