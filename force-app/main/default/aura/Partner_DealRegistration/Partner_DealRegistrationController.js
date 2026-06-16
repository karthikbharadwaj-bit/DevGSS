({
    //INIT METHOD
    doInit : function(component, event, helper) {
        try{
            /* Ignite change start*/
          var userId = $A.get("$SObjectType.CurrentUser.Id");
          component.set("v.userId", userId);

          // Call the helper method to get picklist values
          helper.getFilteredPicklistValues(component, event, helper, userId);
          /* Ignite change end */
            console.log("partnerContact - " + JSON.stringify(component.get("v.partnerContact")));
             // Country BI mapping CS Values
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
            let permittedBrands, permittedBrandsList;
            if(component.get("v.partnerContact") != undefined)
            {
                permittedBrands = component.get("v.partnerContact.Permitted_Brands__c");
                permittedBrandsList = permittedBrands.split(';');
                component.set("v.brandsPermitted_Guest",permittedBrandsList);
                component.set("v.partnerCommunity",permittedBrandsList);
            }
            const action1 = component.get("c.isGuestUser");
            action1.setParams({
            });
            action1.setCallback(this, function (result) {
                const state = result.getState();
                console.log('state - ' + state);
                const resultData = result.getReturnValue();
                console.log('resultData - ' + resultData);
                if(resultData == true)
                {
                    component.set("v.isGuestUser", true);
                }
        var userId = $A.get("$SObjectType.Contact.Fields.FirstName");
        console.log(userId);
        var url = new URL(location.href);
        component.set('v.RespectiveTabURL',url);
        var id = url.searchParams.get('id');
        if(!id){
            id = url.href.split('/')[6];
        }
        var baseURL = url.href.substring(0, url.href.indexOf("/s"));
        component.set('v.baseURL',baseURL);
        if(id != null && id != undefined && id !=''){
            component.set("v.recordID", id);
            component.set("v.ShowListView", false);
            component.set("v.ShowRecordDetail", true);
            var action = component.get("c.getDealRecordList");
            action.setParams({
                "DealRecordId":id
            });
            action.setCallback(this, function(result) {
                try{
                    var resultData = result.getReturnValue();
                    var emailIdValue = resultData.dealReg.Email_Address__c;
                    var emailDomian = emailIdValue.substring(emailIdValue.indexOf('@')+1,emailIdValue.length)
                    var blockedDomains = component.get('v.blockedDomains');
                    var communityName = resultData.partnerCommunityName;
                    component.set("v.partnerCommunity", resultData.partnerCommunityName);
                    component.set("v.communityDetailsRecord", resultData.communityDetailsRecord);

                    if(resultData.dealReg.Is_Pending_Due_to_Domain__c == true){
                        component.set("v.ShowBlockedDomainSection",true);
                    }
                    if(resultData.dealReg != undefined &&
                        resultData.dealReg.Type_of_Customer_or_Prospect__c == 'Existing Premise Based Customer' &&
                    resultData.dealReg.Partner_Account__r != undefined &&
                    (resultData.dealReg.Partner_Account__r.Partner_Classification__c == 'Mitel Referral' || resultData.dealReg.Partner_Account__r.Partner_Classification__c == '' || resultData.dealReg.Partner_Account__r.Partner_Classification__c == null)) //PBC-11950
                        component.set("v.ShowMitelShareDetailPage", true); //PBC-9705 P2CSHaring
                    component.set("v.DealRegRecord", resultData.dealReg);
                    if(resultData.dealReg.Status__c == 'Rejected' &&
                       (resultData.dealReg.Deal_Rejection_Reason__c!=null && resultData.dealReg.Deal_Rejection_Reason__c!=undefined)){
                        component.set("v.ShowDealRejReasonSection",true);
                    }
                    if(resultData.isSingleLogin == true)
                    	component.set("v.isSingleLogin",resultData.isSingleLogin);
                    if(resultData.isReseller == true)
                    	component.set("v.isReseller",resultData.isReseller);
                    console.log('isReseller +++'+component.get("v.isReseller"));
                    if(resultData.isAvaya==true ||resultData.isMaster==true){
                        component.set("v.ShowConAccFields",true);
                    }
                    if(resultData.isAvaya==true){
                        component.set("v.ShowOnlyAvaya",true);
                    }
                     console.log('ShowOnlyAvaya', component.get("v.ShowOnlyAvaya"));
                    var str = 'RingCentral';
                    var partnerComm = component.get("v.partnerCommunity");
                    var masterLabel = component.get("v.communityDetailsRecord").MasterLabel;
                    if(partnerComm.includes(str)&&masterLabel == 'ignite'){
                        component.set("v.ShowOnlyRC", true);
                    }
                    if(partnerComm.includes('Rainbow Office')) {
                        component.set("v.ShowOnlyALE", true);//pbc-10695
                    }
                    var str1 = 'Unify Office';
                    var partnerComm1 = component.get("v.partnerCommunity");
                    if(partnerComm1.includes(str1)){
                        component.set("v.ShowOnlyATOS", true);
                    }
                    console.log('Atos ? +++'+component.get("v.ShowOnlyATOS"));
                    if(partnerComm.includes('Avaya Cloud Office')){
                        component.set("v.isNotAvaya",false);
                    }else{
                        component.set("v.isNotAvaya",true);
                    }
                    //added for mitel partners
                    console.log("isMitel "+resultData.isMitel)
                    if(resultData.isMitel == true){
                        component.set("v.isMitel",true);
                    }
                }catch(e){
                    console.log(e);
                }
                //component.set("v.ShowConAccFields",resultData.isAvaya);
                //component.set("v.ShowOnlyAvaya",resultData.isAvayaCorp);

            });
            $A.enqueueAction(action);
        }else{
            if(!component.get("v.isGuestUser"))
            {
                component.set("v.ShowListView",true);
                var source = url.searchParams.get('source');
                console.log('source '+source);

                if(source != null && source != undefined && source !=''){
                    if(source == 'storefront'){
                        helper.getAccountListForStoreFront(component, event, helper);
                    }else{
                        helper.getPartnerAccountList(component, event, helper);
                    }
                }else{
                    helper.getPartnerAccountList(component, event, helper);
                }
                const action2 = component.get('c.checkWholesalePartnerEditions');
                    action2.setCallback(this, function(result) {
                        const state = result.getState();
                        const resultData = result.getReturnValue();
                        if(state === "SUCCESS" ) {
                            if (resultData != null) {
                                if (resultData.length > 0) {
                                    component.set('v.wholesalePckEditions', resultData);
                                    component.set('v.selectedWholesaleEditionValue', resultData[0]);
                                } else {
                                    component.set('v.selectedWholesaleEditionValue', '');
                                }
                            }
                        }
                    });
                $A.enqueueAction(action2);
            }
        }

        /*else{
            helper.getPartnerAccountList(component, event, helper);
        }*/
        helper.getCountryStateValues(component,event,helper);
        helper.getTranslations(component, event, helper);
            });
            $A.enqueueAction(action1);
        }
        catch(e){
            console('error'+e);
        }
    },
    //METHOD WHEN GO BUTTON IS CLICKED
    doFilter : function(component, event, helper) {
        var isShowConAcc = component.get("v.ShowConAccFields");
        var isViewAll = false;
        if(isShowConAcc){
            isViewAll = component.find("filterType").get("v.checked");
        }
        if(isViewAll){
            var pageNumber = 1;
            var pageSize = component.find("pageSizeForAll").get("v.value");
            helper.getDataForViewAll(component,helper,pageNumber,pageSize);
        }else{
            var pageNumber = component.get("v.pageNumber");
            var pageSize = component.find("pageSize").get("v.value");
            pageNumber = 1;
            helper.getDealRegList(component, event, helper,pageNumber,pageSize);
        }
    },
    //METHOD WHEN GO BACK IS CLICKED
    goBackToViewList:function (component, event, helper) {

        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            //'url': '/partner/s/partnerdealregistration'
            'url':window.location.pathname
        });
        urlEvent.fire();
    },

    //METHODS FOR PAGINATION
    handlePrev: function(component, event, helper) {
        var pageNumber = component.get("v.pageNumber");
        var isShowConAcc = component.get("v.ShowConAccFields");
        var isViewAll = false;
        if(isShowConAcc){
            isViewAll = component.find("filterType").get("v.checked");
        }
        if(isViewAll){
            var pageSize = component.find("pageSizeForAll").get("v.value");
            pageNumber--;
            helper.getDataForViewAll(component,helper,pageNumber,pageSize);
        }
        else{
            var pageSize = component.find("pageSize").get("v.value");
            pageNumber--;
            helper.getDealRegList(component, event, helper,pageNumber,pageSize);
        }
        /*var pageSize = component.find("pageSize").get("v.value");
        pageNumber--;
        helper.getDealRegList(component, event, helper,pageNumber,pageSize); */
    },
    handleNext: function(component, event, helper) {
        var pageNumber = component.get("v.pageNumber");
        /*var pageSize = component.find("pageSize").get("v.value");
        pageNumber++;
        helper.getDealRegList(component, event, helper,pageNumber,pageSize);  */
        var isShowConAcc = component.get("v.ShowConAccFields");
        var isViewAll = false;
        if(isShowConAcc){
            isViewAll = component.find("filterType").get("v.checked");
        }
        if(isViewAll){
            var pageSize = component.find("pageSizeForAll").get("v.value");
            pageNumber++;
            helper.getDataForViewAll(component,helper,pageNumber,pageSize);
        }
        else{
            var pageSize = component.find("pageSize").get("v.value");
            pageNumber++;
            helper.getDealRegList(component, event, helper,pageNumber,pageSize);
        }
    },

    toggleFilterBy: function(component,event,helper){
        var isViewAll = component.find("filterType").get("v.checked");
        component.set("v.viewAll",isViewAll);
        if(isViewAll){
            var pageNumber = 1;
            var pageSize = 50;
            helper.getDataForViewAll(component,helper,pageNumber,pageSize);
        }else{
            var pageNumber = 1;
            var pageSize = 50;
            helper.getDealRegList(component, event, helper,pageNumber,pageSize);
        }
    },

    onSelectChange: function(component, event, helper) {
        var val =component.get("v.selectedAccountValue");
        if(val != undefined)
        {
            var isShowConAcc = component.get("v.ShowConAccFields");
            var isViewAll = false;
            if(isShowConAcc){
                isViewAll = component.find("filterType").get("v.checked");
            }
            if(isViewAll){
                var pageNumber = 1;
                var pageSize = component.find("pageSizeForAll").get("v.value");
                helper.getDataForViewAll(component,helper,pageNumber,pageSize);
            }
            else{
                var pageNumber = 1;
                var pageSize = component.find("pageSize").get("v.value");
                helper.getDealRegList(component, event, helper,pageNumber,pageSize);
            }
        }
    },
    //METHOD WHEN EDIT BUTTON IS CLICKED
    showEditSectionArea:function(component,event,helper){
        component.set("v.ShowListView", false);
        component.set("v.ShowRecordDetail", false);
        component.set("v.ShowEditSection",true);
        component.set("v.ShowNewSection",false);
    },
    //METHOD WHEN NEW BUTTON IS CLICKED
    showNewSectionArea:function(component,event,helper){
        component.set("v.ShowListView", false);
        component.set("v.cloudSpecialistContactId", null);//pbc-10695
        component.set("v.ShowRecordDetail", false);
        component.set("v.ShowEditSection",false);
        component.set("v.ShowNewSection",true);
        component.set("v.ShowOtherPrompting",false);
        component.set("v.ShowOtherCompetitor",false);
        component.set("v.ShowOtherExistingSoln",false);
        component.set("v.ShowOtherDecision",false);
        component.set("v.partnerContactId",null);
        component.set("v.partnerContactName",null);
        component.set("v.ShowRequiredErrorSection",true);
        console.log('insideSalesRep - '+ component.get("v.insideSalesRep"));
        const loggedinPartner = component.get("v.partnerAccounts");
        var accountPartnerType = loggedinPartner[0].Partner_Type__c;
        try {
            if (accountPartnerType != undefined && accountPartnerType.toLowerCase().includes('wholesale-reseller')) {
                component.set("v.isWholeSalePartner", true);
                const BI = loggedinPartner[0].BusinessIdentity__c;
                helper.getBrandCountriesForBI(component, event, helper, BI);
            }
            else {
                component.set("v.isWholeSalePartner", false);
            }
        }
        catch (e) {
            console.error('errBi ' + e);
        }
        var stateValues = component.get("v.mapCountryValueKeys");
        if(stateValues.length <=0 || stateValues == ''){
            var selectCmp = component.find("selectedState");
            if(selectCmp != null){
                stateValues.push('-- None --');
                selectCmp.set('v.disabled',true);
            }
            component.set("v.mapCountryValueKeys",stateValues);
        }
        component.set("v.CountryReq",true);
        //helper.onchangeCountry(component,event,helper,component.get('v.logdPartnrCntry'));
        const brandsListforBI = component.get("v.brandsListforBI");
        const countriesforBIList = component.get("v.countriesforBI");
        if (component.get("v.isWholeSalePartner")) {
            if (brandsListforBI != undefined && brandsListforBI.length > 0
                && countriesforBIList != undefined && countriesforBIList.length > 0) {
                helper.onChangeBrand(component, event, helper, brandsListforBI[0], countriesforBIList[0]);
            }
        } else if (component.get("v.ShowOnlyRC") == true) {
            helper.onChangeBrand(component, event, helper, component.get("v.brandsPermitted")[0], component.get('v.logdPartnrCntry'));
        } else {
            helper.onChangeBrand(component, event, helper, component.get("v.partnerCommunity")[0], component.get('v.logdPartnrCntry'));
        }
    },
    //METHOD WHEN NEW (ON BEHALF) IS CLICKED
    showNewBehalfSectionArea:function (component, event, helper) {
        component.set("v.ShowListView", false);
        component.set("v.cloudSpecialistContactId", null);//pbc-10695
        component.set("v.ShowRecordDetail", false);
        component.set("v.ShowEditSection",false);
        component.set("v.ShowNewSection",true);
        component.set('v.NewOnBehalf',true);
        component.set("v.ShowOtherPrompting",false);
        component.set("v.ShowOtherCompetitor",false);
        component.set("v.ShowOtherExistingSoln",false);
        component.set("v.ShowOtherDecision",false);
        component.set("v.partnerContactId",null);
        component.set("v.partnerContactName",null);
        component.set("v.psPartnerId",null); //Added for LTR-673 PS Deal Reg
        component.set("v.ShowRequiredErrorSection",true);
        component.set("v.isWholeSalePartner", false);// BZS-9020, BZS-9016
        var stateValues = component.get("v.mapCountryValueKeys");
        if(stateValues.length <=0 || stateValues == ''){
            var selectCmp = component.find("selectedState");
            if(selectCmp != null){
                stateValues.push('-- None --');
                selectCmp.set('v.disabled',true);
            }
            component.set("v.mapCountryValueKeys",stateValues);
        }
        component.set("v.CountryReq",true);
        //helper.onchangeCountry(component,event,helper,component.get('v.logdPartnrCntry'));
        if(component.get("v.ShowOnlyRC") == true){
            helper.onChangeBrand(component,event,helper,component.get("v.brandsPermitted")[0],component.get('v.logdPartnrCntry'));
        }else{
            helper.onChangeBrand(component,event,helper,component.get("v.partnerCommunity")[0],component.get('v.logdPartnrCntry'));
        }
        var str = 'RingCentral';
        var partnerComm = component.get("v.partnerCommunity");
        var masterLabel = component.get("v.communityDetailsRecord").MasterLabel;
        if(partnerComm.includes(str)&&masterLabel == 'ignite'){
            component.set("v.ShowOnlyRC", true);
        }

    },
    //METHOD WHEN GO BACK IS CLICKED
    goBack:function (component, event, helper) {
        component.set("v.ShowEditSection", false);
        component.set("v.ShowRecordDetail", true);
        component.set("v.ShowNewSection",false);
        component.set("v.ShowNewSection",false);
        component.set("v.ShowNewBehalfSection",false);
        component.set("v.psPartnerId",null); //Added for LTR-673 PS Deal Reg
    },
    //METHOD TO GO BACK TO LIST VIEW
    goBackListView:function (component, event, helper) {
        try{
            if(component.get("v.isGuestUser"))
            {
                component.set("v.ShowNewSection", false);
                component.set("v.ShowListView", false);
                component.set("v.showGuestLogin", true);
            }
            else
            {
                component.set("v.ShowListView", true);
                component.set("v.ShowNewSection",false);
                component.set('v.NewOnBehalf',false);
                component.set('v.ShowMitelCustomerType',false);//added for mitel
                if(component.get("v.ShowOnlyRC") == true || component.get("v.ShowOnlyATOS") == true)
                {
                    component.set('v.searchUser',null);
                    component.set('v.isNationalPartnerAccount',false);
                    component.set('v.insideSalesRep',component.get("v.insideSalesRepNew"));
                }
                var url = component.get('v.RespectiveTabURL');
                var source = url.searchParams.get('source');
                if(source != null && source != undefined && source !='' && source == 'storefront'){
                    var urlDeal = component.get('v.RespectiveTabURL').toString();
                    urlDeal = urlDeal.split('?')[0];
                    var urlEvent = $A.get("e.force:navigateToURL");
                    urlEvent.setParams({
                        "url": urlDeal
                    });
                    urlEvent.fire();
                }
            }
        }catch(e){
            console.log(e)
        }

    },
    //METHOD TO HANDLE SUCCESS OF RECORD EDIT FORM
    handleSuccessNew : function(component, event, helper) {
        var record = event.getParam("response");
        if(record.Is_Pending_Due_to_Domain__c == true){
            component.set("v.ShowBlockedDomainSection",true);
        }
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type": "success",
            "title": component.get("v.translationsMap.Success")+'!',
            "message": component.get("v.translationsMap.The_record_has_been_submitted_successful"),
            "mode":'dismissible'
        });
        toastEvent.fire();
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            //'url': '/partner/s/partnerdealregistration?id='+record.id
            'url': window.location.pathname +'?id=' +record.id
        });
        urlEvent.fire();
    },
    //METHOD TO HANDLE ERROR
    handleError : function(component, event, helper) {
        var err = event.getParam('error');
        if(component.get("v.isGuestUser"))
        {
            if(err.status == '404')
            {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "success",
                    "duration": 3000,
                    "title": 'Success!',
                    "message": "The record has been submitted successfully",
                    "mode": 'dismissible'
                });
                toastEvent.fire();
                component.set("v.ShowNewSection", false);
                component.set("v.ShowListView", false);
                component.set("v.showGuestLogin", true);
                return;
            }
        }
        console.log('errir>>'+JSON.stringify(err));
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type": "error",
            "title": component.get("v.translationsMap.Error")+'!',
            "message": component.get("v.translationsMap.There_was_some_error_during_processing")+'!',
            "mode":'dismissible'
        });
        toastEvent.fire();
    },
    //METHOD TO HANDLE SUBMIT OF EDIT PAGE
    handleSubmit : function(component, event, helper) {
        event.preventDefault();
        var fields = event.getParam("fields");
        component.find('editRecordForm').submit(fields);
    },

    //METHOD TO HANDLE SUBMIT FOR NEW PAGE
    handleSubmitNew: function(component, event, helper) {
        component.set("v.ShowRequiredErrorSection",false);
        event.preventDefault();
        var onBehalf = component.get('v.NewOnBehalf');
        var pcId = component.get('v.partnerContactId');
        var limitedUser = component.get('v.isCurrentSubPartnerLimitedAccess');
        var singleLogin = component.get('v.isSingleLogin');

        var phoneField = component.find('phoneNumber');
        var phoneValue = phoneField.get('v.value');

        var emailIdField = component.find('emailId');
        var emailIdValue = emailIdField.get('v.value');

        var regex1  = new RegExp("^[0-9 ,+()-]*$");
        var isValidPhone = regex1.test(phoneValue);
        var valTmp = component.get("v.selectedCompItems").toString().replace(/,/g,';');

        var noOfEmp = component.find("selectedEmp").get("v.value");
        console.log('noOfEmp>>'+noOfEmp);
        var stateVal = component.find('selectedState').get("v.value");
        var countryReq = component.get("v.CountryReq");
        var notAvaya = component.get("v.isNotAvaya");
        var isWholesalePartner = component.get("v.isWholeSalePartner");
        const partnerClassification = component.get("v.partnerClassification");// PBC-9705 P2CSharing
        var isMitelCustomerValue = '';
        var mitelCustomerTypeValue = '';
        var mitelDataShare ='';
		var partnerProgram ='';//added for QTC-943
        var selectedISPValue = ''; 
        var selectedISPValueforNew = '';
        if(component.get("v.ShowOnlyRC")){
            partnerProgram = component.find('PartnerProgram').get('v.value');
        }
        if(component.get("v.ShowOnlyRC")) {
        	if(onBehalf == true) {
            	selectedISPValue = component.find('selectedProvider').get('v.value');
        	} else {
               selectedISPValueforNew = component.find('selectedInstallProvider').get('v.value');
            }
        }
        if(component.get("v.isMitel")){
            isMitelCustomerValue = component.find('isMitelCustomer').get('v.value');
            if(isMitelCustomerValue != null && isMitelCustomerValue != '' && isMitelCustomerValue.includes('Yes'))
                mitelCustomerTypeValue = component.find('mitelCustomerType').get('v.value');
            // PBC-9705 P2CSharing; PBC-11950
            if(mitelCustomerTypeValue !=null && mitelCustomerTypeValue != '' && (partnerClassification == 'Mitel Referral' || partnerClassification == '' || partnerClassification == null) && mitelCustomerTypeValue.includes('Existing Premise Based Customer'))
                mitelDataShare=component.find('mitelDataShare').get('v.value');
        }
        // Ignite change start
        // New Onbehalf
        if(component.get("v.ShowOnlyRC")) {
            var fields = event.getParam("fields");
            if(onBehalf == true){
                var selectedPSVal = component.get("v.selectedProviderValue");
                console.log('selectedPSVal1 +++ '+selectedPSVal);
                fields["Installation_Service_Provider__c"] = selectedPSVal;
            }else{  //New
                var selectedPSValue = component.get("v.installProviderValue");
                console.log('selectedPSValue +++ '+selectedPSValue);
                fields["Installation_Service_Provider__c"] = selectedPSValue;
            }
        }
        // Ignite change End

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
        } else if((onBehalf == true && component.get("v.ShowOnlyRC") && (selectedISPValue == null || selectedISPValue == undefined || selectedISPValue == '' || selectedISPValue == '--Please Select--'))) {
        	var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                 "type" : "error",
                 "title" : component.get("v.translationsMap.Error") + '!',
                 "message" : 'Please choose Valid Option for Installation Service Provider!',
                 "mode" :'dismissible'
            });
            toastEvent.fire();
	   	} else if((onBehalf == false && component.get("v.ShowOnlyRC") && (selectedISPValueforNew == null || selectedISPValueforNew == undefined || selectedISPValueforNew == '' || selectedISPValueforNew == '--Please Select--'))) {
       		var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                 "type" : "error",
                 "title" : component.get("v.translationsMap.Error") + '!',
                 "message" : 'Please choose Valid Option for Installation Service Provider!',
                 "mode" :'dismissible'
         	});
            toastEvent.fire();
		} else if(valTmp == null || valTmp == undefined || valTmp == ''){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type": "error",
                "title": component.get("v.translationsMap.Error")+'!',
                "message": component.get("v.translationsMap.Please_choose_one_Competitor")+'!',
                "mode":'dismissible'
            });
            toastEvent.fire();
        }else if(noOfEmp == null || noOfEmp == undefined || noOfEmp == '' || noOfEmp == '-- None --'){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type": "error",
                "title": component.get("v.translationsMap.Error")+'!',
                "message": component.get("v.translationsMap.Please_choose_Number_of_Employees")+'!',
                "mode":'dismissible'
            });
            toastEvent.fire();
        }else if (countryReq === true && notAvaya === false && (stateVal == null || stateVal == undefined || stateVal == '' || stateVal == '-- None --')){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type": "error",
                "title": component.get("v.translationsMap.Error")+'!',
                "message": component.get("v.translationsMap.Please_choose_a_State_Province	")+'!',
                "mode":'dismissible'
            });
            toastEvent.fire();
        }else if (component.get("v.isMitel") && (isMitelCustomerValue == null || isMitelCustomerValue == undefined || isMitelCustomerValue == '' || isMitelCustomerValue == '-- None --')){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
             "type": "error",
             "title": component.get("v.translationsMap.Error")+'!',
             "message": 'Please choose is this a Mitel Customer or Prospect!',
             "mode":'dismissible'
         });
         toastEvent.fire();
     }else if(component.get("v.isMitel") && (isMitelCustomerValue.includes('Yes')) && (mitelCustomerTypeValue == null || mitelCustomerTypeValue == undefined || mitelCustomerTypeValue == '' || mitelCustomerTypeValue == '-- None --')){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
             "type": "error",
             "title": component.get("v.translationsMap.Error")+'!',
             "message": 'Please choose What Type of Mitel Customer or Prospect!',
             "mode":'dismissible'
         });
         toastEvent.fire();
     }
     // PBC-9705 P2CSharing; PBC-11950
     else if(component.get("v.isMitel") && (partnerClassification == 'Mitel Referral' || partnerClassification == '' || partnerClassification == null) && (mitelCustomerTypeValue.includes('Existing Premise Based Customer')) && (mitelDataShare == null || mitelDataShare == undefined || mitelDataShare == '' || mitelDataShare == '-- None --')){
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type": "error",
            "title": component.get("v.translationsMap.Error") + '!',
            "message": 'Please choose if you agree to share data for this deal with Mitel',
            "mode": 'dismissible'
        });
        toastEvent.fire();
    }// Added for QTC-943
         else if(component.get("v.ShowOnlyRC") && (partnerProgram == null || partnerProgram == undefined || partnerProgram == '' || partnerProgram == '-- None --')){
             var toastEvent = $A.get("e.force:showToast");
             toastEvent.setParams({
                 "type": "error",
                 "title": component.get("v.translationsMap.Error") + '!',
                 "message": 'Please choose Partner Program',
                 "mode": 'dismissible'
             });
             toastEvent.fire();
         }
        //added for QTC-943 ends
		else
            {
                if ((!onBehalf && !singleLogin) || ((onBehalf || singleLogin) && pcId != null && pcId != undefined && pcId != ''))
                {
                    var fields = event.getParam("fields");
                    //if(component.get("v.partnerCommunity") == 'Avaya Cloud Office')
                    fields["Avaya_Partnership_Deal__c"] =true;
                    fields["Portal_Deal__c"] =true;
                    if(onBehalf == true || singleLogin)
                    {
                        fields["Partner_Contact__c"]=pcId;
                    }
                    let isGuestUser = component.get("v.isGuestUser");
                    if(isGuestUser) {
                        if(component.get("v.partnerContact") != undefined)
                        {
                            fields["Partner_Contact__c"] = component.get("v.partnerContact.Id");
                        }
                    }
                    //var brandName = component.get("v.partnerCommunity");
                    var brandName = component.get("v.selectedBrandValue");
                    fields["Brand_Name__c"] = brandName;

                    // Deal country
                    fields['Country__c'] = component.find("selectedCountry").get("v.value");

                    //Deal State
                    var selectCmp = component.find("selectedState");

                    if(selectCmp != null && selectCmp.get('v.disabled')){
                        selectCmp.set('v.disabled',false);
                        fields['State__c'] = '-- None --';
                    }else{
                        fields['State__c'] =component.find("selectedState").get("v.value");
                    }

                    var empCmp = component.find("selectedEmp");
                    if(empCmp != null && empCmp.get('v.disabled')){
                        empCmp.set('v.disabled',false);
                        fields['Number_of_Employees__c'] = '-- None --';
                    }else{
                        fields['Number_of_Employees__c'] =component.find("selectedEmp").get("v.value");
                    }

                    var valTmp = component.get("v.selectedCompItems").toString().replace(/,/g,';');
                    fields['Competitor_s__c'] = valTmp;

                    if(valTmp == undefined || valTmp == null || valTmp == ''){
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "type": "error",
                            "title": component.get("v.translationsMap.Error")+'!',
                            "message":component.get("v.translationsMap.Please_choose_any_one_Competitor"),
                            "mode":'dismissible'
                        });
                        toastEvent.fire();
                        return;
                    }
                    //added for mitel prm-283 starts
                    var isMitelCustomerValue = '';
                    var mitelCustomerTypeValue = '';
                    if (component.get("v.isMitel")) {
                        isMitelCustomerValue = component.find('isMitelCustomer').get('v.value');
                        if (isMitelCustomerValue != null && isMitelCustomerValue != '' && isMitelCustomerValue.includes('Yes'))
                            mitelCustomerTypeValue = component.find('mitelCustomerType').get('v.value');

                    }
                    // PBC-9705 P2CSharing; PBC-11950
                if(mitelCustomerTypeValue != null && mitelCustomerTypeValue != '' &&
                (((partnerClassification == 'Mitel Referral' || partnerClassification == '' || partnerClassification == null) && mitelCustomerTypeValue == 'Existing Cloud Customer') ||
                partnerClassification == 'Mitel Referral P2C Sharing'))
                        fields['Mitel_Data_Sharing__c'] = 'Yes';
                    //added for mitel prm-283 ends
                    //edition
                    //fields['Edition__c'] = component.find("editionSelect").get("v.value");

                    var userValue = component.find("userId");
                    userValue = Array.isArray(userValue) ? userValue[0].get("v.value") : userValue.get("v.value");

                    var val = Math.sign(userValue);
                    console.log('ShowOnlyRC - '+ component.get("v.ShowOnlyRC"));
                    if(component.get("v.ShowOnlyRC") == true || component.get("v.ShowOnlyATOS") == true)
                    {
                        var insideSalesRep =component.get("v.insideSalesRep");
                        if(insideSalesRep != null && insideSalesRep !=undefined && insideSalesRep !=''){
                            fields['Inside_Sales_Rep__c'] = insideSalesRep;
                            console.log('insideSalesRep - '+ fields['Inside_Sales_Rep__c']);
                        }
                    }

					//Chosen Avaya CloudOffice Specialist
                    var chosenCloudSpecialistValue=component.get("v.cloudSpecialistContactId");
                    if(chosenCloudSpecialistValue != null && chosenCloudSpecialistValue !=undefined && chosenCloudSpecialistValue !=''){
                        fields['Avaya_Cloud_Specialist__c']=chosenCloudSpecialistValue;
                        console.log('chosenCloudSpecialistValue>'+fields['Avaya_Cloud_Specialist__c']);
                    }

                    component.set('v.ShowSpinnerOpp',true);
                    if(val==1){
                        component.find('newRecordFormSection').submit(fields);
                    }
                    else{
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "type": "error",
                            "title": component.get("v.translationsMap.Error")+'!',
                            "message": component.get("v.translationsMap.Forecasted_Users_cannot_be_0_or_negative"),
                            "mode":'dismissible'
                        });
                        toastEvent.fire();
                    }
                }
                else
                {
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


    //METHODS TO DISPLAY SPINNER
    showSpinner: function(component, event, helper) {
        var spinner = component.find("loadingSpinner");
        $A.util.removeClass(spinner, "slds-hide");
    },
    hideSpinner : function(component,event,helper){
        var spinner = component.find("loadingSpinner");
        $A.util.addClass(spinner, "slds-hide");
    },
    existingChange:function(component,event,helper){
        var existingfieldValue = component.find("existing").get("v.value");
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
        }
        else{
            component.set("v.ShowOtherCompetitor",false);
        }
    },
    promptingChange:function(component,event,helper){
        var promptingfieldValue = component.find("prompting").get("v.value");
        if(promptingfieldValue.includes('Other')){
            component.set("v.ShowOtherPrompting",true);
        }else{
            component.set("v.ShowOtherPrompting",false);
        }
    },
    /*decisionChange:function(component,event,helper){
        var decisionfieldValue = component.find("decision").get("v.value");
        if(decisionfieldValue=='Other'){
            component.set("v.ShowOtherDecision",true);
        }
        else{
            component.set("v.ShowOtherDecision",false);
        }
    },*/
    createLookup : function(component, event, helper){
        var contactName = component.get('v.partnerContactName');
        var newOnBehalf = component.get('v.NewOnBehalf');
        var newSection = false;
        if(newOnBehalf == false){
            newSection = true;
        }
        $A.createComponent("c:Partner_LookupSearch",
                           {"searchKeyword":contactName,
                            "isCurrentContactPCM":component.get("v.isCurrentContactPCM"),
                            "isSingleLogin":component.get("v.isSingleLogin"), //added for Single Login
                            "isNew":newSection}, //added for Single Login
                           function(createPartnerComponent, status, errorMessage){
                               if (status === "SUCCESS") {
                                   var lookupDiv = component.find('lookupSearchDiv').get('v.body');
                                   lookupDiv.push(createPartnerComponent);
                                   component.find('lookupSearchDiv').set('v.body', lookupDiv);
                               }
                           }
                          );

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
        var partnerId = event.getParam("PartnerId");
        var PartnerCountry = event.getParam("PartnerCountry");
        var permittedBrands= event.getParam("brandsPermitted");
        var acc = event.getParam("PartnerAccount");
        var accountMasterAgentChlMgr=event.getParam("accountMasterAgentChlMgr");
        console.log('accountMasterAgentChlMgr'+accountMasterAgentChlMgr);
        var partnerAccountId = event.getParam("AccountId");
        component.set('v.isMitel', event.getParam("isMitel")); //added for mitel
        //Added for multiple countries in ACO 3.0
        var partnerAvailableCountries = event.getParam("partnerAvailableCountries");
        console.log("partnerAvailableCountries"+partnerAvailableCountries);
        var countriesArr = [];
        // BZS-9016
        const brandsPicklist = component.find("brandSelected");
        const selectedCountryPicklist = component.find("selectedCountry");
        if (brandsPicklist != null) {
            brandsPicklist.set("v.disabled", false);
        }
        if (selectedCountryPicklist != null) {
            selectedCountryPicklist.set("v.disabled", false);
        }
        if(partnerAvailableCountries != undefined && partnerAvailableCountries != null && partnerAvailableCountries != ''){
            for(var k=0;k<partnerAvailableCountries.split(';').length;k++){
                countriesArr.push(partnerAvailableCountries.split(';')[k]);
            }
            component.set("v.partnerAvailableCountries",countriesArr)
        }else{
            component.set("v.partnerAvailableCountries",countriesArr)
        }

        var brands=[];
        if(PartnerCountry == ''){
            PartnerCountry = component.get('v.logdPartnrCntry');
        }
        if(permittedBrands!= undefined){

            brands= permittedBrands.split(';');
            var brandsList=[];
            for(var i in brands){
                brandsList.push(brands[i]);
            }
        }
        var accountTerritory= event.getParam("accountTerritory");
        component.set('v.accountTerritory',accountTerritory);
        console.log('accountTerritory'+ component.get('v.accountTerritory'));
        var accountVARTerritory= event.getParam("accountVARTerritory");
        var accountPartnerType= event.getParam("accountPartnerType");
        var accountMasterAgentChlMgr=event.getParam("accountMasterAgentChlMgr");
        var isWholesalePartnerAcc = accountPartnerType != undefined && accountPartnerType.toLowerCase().includes('wholesale-reseller');// BZS-9020, BZS-9016
        //  BZS-9016
        try {
            if (isWholesalePartnerAcc) {
                component.set("v.isWholeSalePartner", true);
                const BI = event.getParam("businessIdentity");
                helper.getBrandCountriesForBI(component, event, helper, BI);
            }
            else {
                component.set("v.isWholeSalePartner", false);
            }
        }
        catch (e) {
            console.error('errbi - ' + e);
        }
        var territoryAlignmentMap = event.getParam("territoryAlignmentMap");
        var insideSalesRep = event.getParam("insideSalesRep");
        component.set('v.insideSalesRep',insideSalesRep);
        console.log('insideSalesRep - '+insideSalesRep);
        component.set('v.partnerClassification', event.getParam("partnerClassification"));// PBC-9705 P2CSharing
        if(territoryAlignmentMap != undefined)
        {
            var n = territoryAlignmentMap.lastIndexOf('/');
            var FileId = territoryAlignmentMap.substring(n + 1);
            component.set('v.territoryAlignmentMap',FileId);
        }
        else
        {
            component.set('v.territoryAlignmentMap','');
        }
        console.log('FileId>'+FileId);
        console.log('accountVARTerritory' +accountVARTerritory);
        console.log('accountPartnerType' +accountPartnerType);
        console.log('accountMasterAgentChlMgr'+accountMasterAgentChlMgr);
        console.log('territoryAlignmentMap - '+territoryAlignmentMap);

        if(acc == false){
            component.set('v.partnerContactId',conId);
            component.set('v.partnerContactName',conName);
            component.set('v.partnerId',partnerId);
            component.set("v.psPartnerId",conId); //Added for LTR-673 PS Deal Reg
            component.set("v.brandsPermitted",brandsList);
             if (!isWholesalePartnerAcc && component.get("v.ShowOnlyRC") == true) {
                component.set("v.selectedBrandValue", brandsList[0]);
            }
            //component.set("v.cloudSpecialistContactId",accountMasterAgentChlMgr); Commented since default of MACM not needed
            const brandsListforBI = component.get("v.brandsListforBI");
            const countriesforBIList = component.get("v.countriesforBI");
            if(component.get("v.ShowOnlyRC") == true || component.get("v.ShowOnlyATOS") == true){
                if (component.get("v.isWholeSalePartner")) {
                    if (brandsListforBI != undefined && brandsListforBI.length > 0 && countriesforBIList != undefined && countriesforBIList.length > 0) {
                        helper.onChangeBrand(component, event, helper, brandsListforBI[0], countriesforBIList[0]);
                    }
                } else {
                    helper.onChangeBrand(component, event, helper, component.get("v.brandsPermitted")[0], PartnerCountry);
                }
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
            }else{
                if (component.get("v.isWholeSalePartner")) {
                    if (brandsListforBI != undefined && brandsListforBI.length > 0 && countriesforBIList != undefined && countriesforBIList.length > 0) {
                        helper.onChangeBrand(component, event, helper, brandsListforBI[0], countriesforBIList[0]);
                    }
                } else {
                    helper.onChangeBrand(component, event, helper, component.get("v.partnerCommunity")[0], PartnerCountry);
                }
                /*Commented since default of MACM not needed if(accountMasterAgentChlMgr!=undefined && accountMasterAgentChlMgr!=null &&accountMasterAgentChlMgr!=''){
                    helper.getAccountMasterAgtChlMgr(component, event, helper,accountMasterAgentChlMgr);
                }*/
            }
        }else{
            component.set('v.selectedAccountValue',conId);
            component.set('v.partnerAccountName',conName);
            var pageNumber = component.get("v.pageNumber");
            var pageSize = component.find("pageSize").get("v.value");
            helper.getDealRegList(component, event, helper,pageNumber,pageSize);
        }
       // if(PartnerCountry != '')
         //   helper.onchangeCountry(component, event, helper,PartnerCountry);
         // BZS-9020 starts
        if (isWholesalePartnerAcc) {
            var action = component.get('c.getWholesalePartnerPackageEditions');
            action.setParams({"partnerAccountId": partnerAccountId});
            action.setCallback(this, function(result) {
                var state = result.getState();
                if (state === "SUCCESS") {
                    var editions = result.getReturnValue();
                    if (editions != null){
                        component.set('v.wholesalePckEditions', editions);
                        if (editions.length > 0) {
                            component.set('v.selectedWholesaleEditionValue', editions[0]);
                        }
                        else {
                            component.set('v.selectedWholesaleEditionValue', '');
                        }
                    }
                }
            });
            $A.enqueueAction(action);
            // Added for BZS-9017
            component.set("v.tierNames", ['Office']);

        }
        // BZS-9020 ends
    },
    getNDAFile : function(component, event, helper) {
        var baseURL = component.get('v.baseURL');
        var action = component.get('c.getNDADocument');
        action.setCallback(this,function(result){
            var state = result.getState();
            if(state=== "SUCCESS"){
                var urlEvent = $A.get("e.force:navigateToURL");
                var id=result.getReturnValue();
                if(id!=null){
                    urlEvent.setParams({
                        'url': baseURL+'/servlet/servlet.FileDownload?file='+id
                    });
                    urlEvent.fire();
                }
                else
                {
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": "error",
                        "title": "Error!",
                        "message": "There is no document",
                        "mode":'dismissible'
                    });
                    toastEvent.fire();
                }
            }
        });
        $A.enqueueAction(action);
    },
    onchangeCountry:function(component,event,helper){
        var selctedValue = event.getSource().get("v.value");
        if(selctedValue == 'United States' || selctedValue == 'Canada'){
            component.set("v.CountryReq",true);
        }
        else{
            component.set("v.CountryReq",false);
        }
        console.log('CountryReq>>>'+component.get("v.CountryReq"));
        component.set('v.selectedCountry', selctedValue);
        helper.onchangeCountry(component,event,helper,selctedValue);
    },
    onChangeBrand : function(component,event,helper){
        helper.onChangeBrand(component,event,helper);
    },
     handleCloudSpecialistEvent: function(component,event,helper){
        console.log('inside cloudspe event set');
        var cloudSpecialistContactId = event.getParam("cloudSpecialistContactId");
        var cloudSpecialistContactName = event.getParam("cloudSpecialistContactName");
        console.log('cloudSpecialistContactId'+cloudSpecialistContactId);
        console.log('cloudSpecialistContactName'+cloudSpecialistContactName);
        component.set("v.cloudSpecialistContactId",cloudSpecialistContactId);
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
            console.log('insideSalesRep - '+ component.get("v.insideSalesRep"));
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
        var NewOnBehalf = component.get("v.NewOnBehalf");
        var isSingleLogin = component.get("v.isSingleLogin");
        if(NewOnBehalf==true || isSingleLogin)
            rec_id = component.get("v.territoryAlignmentMap");

        $A.get('e.lightning:openFiles').fire({
            recordIds: [rec_id]
        });
    },
    changeMitelCustomer:function(component,event,helper){
        var isMitelCustomerfieldValue = component.find("isMitelCustomer").get("v.value");
        console.log(isMitelCustomerfieldValue);
        if(isMitelCustomerfieldValue.includes('Yes')){
            component.set("v.ShowMitelCustomerType",true);
        }else{
            component.set("v.ShowMitelCustomerType",false);
        }
    },
    changeMitelType: function(component,even,helper){
        var mitelCustomerType = component.find("mitelCustomerType").get("v.value");
        const partnerClassification = component.get("v.partnerClassification");// PBC-9705 P2CSharing
        // PBC-9705 P2CSharing; PBC-11950
        if ((partnerClassification == 'Mitel Referral' || partnerClassification == '' || partnerClassification == null) && mitelCustomerType =='Existing Premise Based Customer') {
            component.set("v.ShowMitelDataShare", true);
        } else {
            component.set("v.ShowMitelDataShare", false);
        }
    },
    //Ignite changes 
    getPickListValuesPS: function(component, event, helper) {
        if(component.get("v.ShowOnlyRC") == true){
            console.log('Inside Picklist toggle');
            var partnerContact = event.getParam("value");
            console.log(partnerContact);
            if (partnerContact != null){
                helper.getPSPicklistValues(component, event, helper, partnerContact);
            }
        }
    },
    toggledisplayTextON: function(component, event, helper) {
        component.set('v.displayText',true);
	},
    toggledisplayTextOFF: function(component, event, helper) {
        component.set('v.displayText',false);
	}
})