({
    getCountryStateValues : function(component,event,helper,partnerCountry){
        var brandName = component.get("v.brandName");
        var action = component.get("c.getCountryStateMap");
        component.set('v.ShowSpinnerOpp',true);
        action.setParams({
            "communityBrand": brandName
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log('State>>'+state);
            if (state === "SUCCESS") {
                var dataResponse = response.getReturnValue();
                var data = dataResponse.countryStateMap;
                var countries = dataResponse.countriesAvailable;
                var competitiors = dataResponse.countryCompetitorMap;
                var brandCntryMap = dataResponse.mapBrandCntry;
                var noOfEmployees = dataResponse.countryNoOfEmployeesMap;
                console.log("countriesAvailable >>"+JSON.stringify(dataResponse.countriesAvailable));
                console.log("brandCntryMap>>"+JSON.stringify(dataResponse.mapBrandCntry));
                console.log("brandCntryMap 1>>"+brandCntryMap);

                var arrayMapKeys = [];
                var stateValues = [];

                var arrayEmpMapKeys = [];
                var empValues = [];

                var arrayCompMapKeys = [];
                var compValues = [];

                var compObj = {};
                var compTmpValue = [];
                var defaultCountryState = [];
                component.set("v.countriesAvailable",countries);
                if(brandName == 'RingCentral'){
            		component.set("v.selectedCountryValue",'United States');
           		}
                var i = 0;
                for(var key in data){
                    if(countries.includes(key)){
                        if(i == 0){
                            stateValues = data[key];
                            arrayMapKeys.push({key: key, value: data[key]});
                            empValues = noOfEmployees[key];
                            arrayEmpMapKeys.push({key: key, value: noOfEmployees[key]});
                            if(competitiors[key] != null && competitiors[key] != undefined && competitiors[key] != ''){
                                compValues = competitiors[key];
                                compTmpValue = [];

                                for(var j=0;j<competitiors[key].length;j++){
                                    compTmpValue.push({value:competitiors[key][j], label:competitiors[key][j]});
                                }
                                arrayCompMapKeys.push({key: key, value: compTmpValue});
                                compValues = compTmpValue;
                            }
                            i++;
                        }else{
                            arrayMapKeys.push({key: key, value: data[key]});
                            arrayEmpMapKeys.push({key: key, value: noOfEmployees[key]});
                            if(competitiors[key] != null && competitiors[key] != undefined && competitiors[key] != ''){
                                compTmpValue = [];
                                for(var j=0;j<competitiors[key].length;j++){
                                    compTmpValue.push({value:competitiors[key][j], label:competitiors[key][j]});
                                }
                                arrayCompMapKeys.push({key: key, value: compTmpValue});
                            }
                        }
                    }
                }

                component.set("v.mapDataBrand",brandCntryMap);
                component.set("v.mapCountryKeys", arrayMapKeys);
                component.set("v.mapData", data);
                // BZS-9016
                if (!component.get("v.isWholesalePartner")) {
                    defaultCountryState = (brandName == 'RingCentral') ? data['United States'] : stateValues;
                    component.set("v.mapCountryValueKeys",defaultCountryState);
                    component.set("v.mapCountryCompValKeys",compValues);
                    component.set("v.mapEmpCompValKeys", empValues);
                }
                component.set("v.mapCompData", competitiors);
                component.set("v.mapCountryCompKeys", arrayCompMapKeys);
                //component.set("v.mapCountryCompValKeys",compValues);

                component.set("v.mapEmpData", noOfEmployees);
                component.set("v.mapEmpCompKeys", arrayEmpMapKeys);
                //component.set("v.mapEmpCompValKeys", empValues);
                //this.onchangeCountry(component,event,helper,'');

            }else{
                //this.onchangeCountry(component,event,helper,'');
                component.set('v.ShowSpinnerOpp',false);
            }
            if(brandName.includes('Avaya Cloud Office')){
                this.onChangeBrand(component,event,helper,brandName,'');
            }
        });
        $A.enqueueAction(action);
    },

    onchangeCountry:function(component,event,helper,selctedValue){
        console.log("selctedValue+++"+selctedValue)
        try{
            var mapCountryStates = (component.get("v.mapData"));
            var mapCountryComp = (component.get("v.mapCompData"));
            var mapCountryEmp = (component.get("v.mapEmpData"));
            var countriesAvailable = component.get("v.countriesAvailable");
            var stateValues = [];
            var compValues = [];
            var empValues = [];
            var isWholesalePartner = component.get("v.isWholesalePartner");

            if(component.find("selectedCountry") == null){
                return;
            }
            var statesForCountry = '';
            var compForCountry ='';
            var empForCountry = '';
            if(selctedValue!=null && selctedValue !='' && selctedValue!=undefined){
                try{
                    statesForCountry = mapCountryStates[selctedValue].toString();
                    compForCountry = mapCountryComp[selctedValue].toString();
               		empForCountry = mapCountryEmp[selctedValue].toString();
                }catch(e){
                    console.log('Dependency picklist error');
                }
                if (!isWholesalePartner) {
                    if ((countriesAvailable.indexOf(selctedValue) == -1) || (statesForCountry == undefined || statesForCountry == '' || statesForCountry == null)) {
                        if (countriesAvailable.indexOf('United States') != -1) {
                            selctedValue = 'United States';
                        } else if (countriesAvailable.indexOf(selctedValue) == -1) {
                            selctedValue = countriesAvailable[0];
                        }
                        statesForCountry = '';
                        compForCountry = '';
                        empForCountry = '';
                    }
                }

                console.log('selctedValue : '+selctedValue);
                console.log('statesForCountry : '+mapCountryStates[selctedValue]);
                if(mapCountryStates[selctedValue] != undefined && mapCountryStates[selctedValue] != null)
                    statesForCountry = mapCountryStates[selctedValue].toString();
                if(mapCountryComp[selctedValue] != undefined && mapCountryComp[selctedValue] != null)
                    compForCountry = mapCountryComp[selctedValue].toString();
                if (mapCountryEmp[selctedValue] != undefined && mapCountryEmp[selctedValue] != null)
                    empForCountry = mapCountryEmp[selctedValue].toString();
            }
            component.find("selectedCountry").set("v.value",selctedValue);
            component.set("v.selectedCountry", selctedValue);
            //component.set("v.selectedCountryValue",selctedValue);
            component.set("v.logdPartnrCntry",selctedValue);
            component.set("v.mapCountryValueKeys",stateValues);

            if(statesForCountry != '' && statesForCountry != undefined && statesForCountry != null){
                for(var i=0;i<statesForCountry.split(',').length;i++){
                    stateValues.push(statesForCountry.split(',')[i]);
                }
                var selectCmp = component.find("selectedState");
                if(selectCmp != null){
                    selectCmp.set('v.disabled',false);
                }
            }else{
                var selectCmp = component.find("selectedState");
                if(selectCmp != null){
                    stateValues.push('-- None --');
                    selectCmp.set('v.disabled',true);
                }
            }
            //for competitors
            if(compForCountry != '' && compForCountry != undefined && compForCountry != null){
                var compObj = {};
                var compTmpValue = [];
                for(var i=0;i<compForCountry.split(',').length;i++){
                    compTmpValue.push({value:compForCountry.split(',')[i], label:compForCountry.split(',')[i]});
                }
                compValues = compTmpValue;
                var comp = component.find("competitor");
                comp.set("v.value","");

            }
            if (empForCountry != '' && empForCountry != undefined && empForCountry != null) {
                for (var i = 0; i < empForCountry.split(',').length; i++) {
                    if (i == 0 && empForCountry.indexOf('--None') == -1 && empForCountry.indexOf('-- None') == -1) {
                        empValues.push('-- None --');
                        empValues.push(empForCountry.split(',')[i]);
                    } else {
                        empValues.push(empForCountry.split(',')[i]);
                    }
                }
                var selectEmpCmp = component.find("selectedEmp");
                if (selectEmpCmp != null) {
                    selectEmpCmp.set('v.disabled', false);
                }
            } else {
                var selectEmpCmp = component.find("selectedEmp");
                if (selectEmpCmp != null) {
                    empValues.push('-- None --');
                    selectEmpCmp.set('v.disabled', true);
                }
            }
            component.set("v.mapCountryCompValKeys",compValues);
            component.set("v.mapCountryValueKeys",stateValues);
            component.set("v.mapEmpCompValKeys", empValues);
            component.find("selectedState").set("v.value",stateValues[0]);
            component.set("v.selectedStateValue",stateValues[0]);

        }catch(e){
            console.log(e);
        }
    },
    onChangeBrand : function(component,event,helper,brandName,countryPart){
        try{
            var brandCntryMap = component.get("v.mapDataBrand");
            var brandSelected = event.getSource().get("v.value");
            var countriesAvailable = [];
            if(brandName != undefined && brandName != null && brandName != ''){
                brandSelected = brandName;
            }
            var country = '';
            var arrayMapKeys = [];
            console.log('brand + '+brandSelected);

            //Added for multiple countries for ACO 3.0
            var partnerAvailableCountries = component.get("v.partnerAvailableCountries");

            var cntryForBrand;
            var isWholesalePartner = component.get("v.isWholesalePartner");
            if (isWholesalePartner) { // BZS-9016
                if (component.get("v.BrandCountriesForBIMap") != undefined && component.get("v.BrandCountriesForBIMap").get(brandSelected) != undefined) {
                    cntryForBrand = Array.from(component.get("v.BrandCountriesForBIMap").get(brandSelected)).toString();
                }
            } else if(brandCntryMap!=null && brandCntryMap !='' && brandCntryMap!= undefined){
                cntryForBrand = brandCntryMap[brandSelected].toString();
            }
            if(cntryForBrand !=null && cntryForBrand !=undefined && cntryForBrand !=''){
                for(var b=0;b<cntryForBrand.split(',').length;b++){
                    if(countryPart != undefined && countryPart != '' && countryPart == cntryForBrand.split(',')[b]){
                        country = cntryForBrand.split(',')[b];
                    }
                    if(!isWholesalePartner && component.get('v.logdPartnrCntry') == cntryForBrand.split(',')[b]){
                        country = cntryForBrand.split(',')[b];
                    }

                    //Added for multiple countries for ACO 3.0
                    if(partnerAvailableCountries != null && partnerAvailableCountries != undefined &&
                       partnerAvailableCountries != ''){
                        if(partnerAvailableCountries.indexOf(cntryForBrand.split(',')[b]) != -1)
                            countriesAvailable.push(cntryForBrand.split(',')[b]);
                    }else{
                        countriesAvailable.push(cntryForBrand.split(',')[b]);
                    }

                    arrayMapKeys.push(cntryForBrand.split(',')[b]);
                }
            }
            component.set("v.mapCountryKeys", arrayMapKeys.sort());
            component.set("v.countriesAvailable",countriesAvailable.sort());
            if(country == undefined || country == ''){
                country = arrayMapKeys[0];
            }
            component.set("v.countriesAvailable",countriesAvailable.sort());
            if (component.get("v.isWholesalePartner")) {
                component.set("v.countriesforBI", countriesAvailable.sort());
            }
            this.onchangeCountry(component,event,helper,country);
        }catch(e){
            console.log(e)
        }
    },
    selectAccountDetail : function(component,helper,partnerId){
        var action = component.get("c.getAccountDetails");
        action.setCallback(this, function(result) {
            var state = result.getState();
            if (component.isValid() && state === "SUCCESS"){
                var resultData = result.getReturnValue();
                component.set('v.ShowSpinnerOpp',false);
                if(resultData.listPartnerAccounts[0].VAR_Territory__c != undefined && resultData.listPartnerAccounts[0].Partner_Type__c != undefined &&
                   resultData.listPartnerAccounts[0].VAR_Territory__c != null && resultData.listPartnerAccounts[0].Partner_Type__c != null &&
                  resultData.listPartnerAccounts[0].VAR_Territory__c != '' && resultData.listPartnerAccounts[0].Partner_Type__c != '')
                {

                    var accountVARTerritory= resultData.listPartnerAccounts[0].VAR_Territory__c;
                    var accountPartnerType= resultData.listPartnerAccounts[0].Partner_Type__c;
                    if(accountVARTerritory != undefined && accountPartnerType != undefined){
                        if(accountVARTerritory.includes('NAM') && accountPartnerType.includes('Master Agent')){
                            component.set('v.isNationalPartnerAccountNew',true);
                        }else{
                             component.set('v.isNationalPartnerAccountNew',false);
                        }
                    }else{
                        component.set('v.isNationalPartnerAccountNew',false);
                    }

                }
            }
            });

        $A.enqueueAction(action);

    },

    searchUsers : function(component,event, helper,searchContent) {
        console.log('name>'+searchContent);
        var action = component.get('c.getStrategicPartnerManagers');
        action.setParams({
            "userName":searchContent
        });
        action.setCallback(this,function(result){
            var state = result.getState();
            console.log('state>'+state);
            if(state=== "SUCCESS"){
                var resultData = result.getReturnValue();
                console.log('userList>'+JSON.stringify(resultData));
                console.log('user res length>'+resultData.length);
                if(resultData != undefined && resultData !=null && resultData !='' && resultData.length>0){
                    component.set("v.portalUserList",resultData);
                }
                else if( resultData.length==0){
                    component.set("v.portalUserList",null);
                    var userPaneCmp = component.find("userPane");
                    setTimeout(function(){
                        $A.util.removeClass(userPaneCmp,'slds-is-open');
                        $A.util.addClass(userPaneCmp,'slds-is-close');
                        component.set("v.searchUser",null);
                    }, 1000);
                }
                console.log('user result>'+JSON.stringify(component.get("v.portalUserList")));
            }
        });
        $A.enqueueAction(action);
    },
    getBrandCountriesForBI: function (component, event, helper, BI) {
        /* Get BrandCountriesCSList for current BI */
        const BICountriesCSList = component.get("v.BICountriesCSList");
        if (BICountriesCSList == undefined) return;

        function getBrandsCountriesListforBI(BICountryRec) {
            const isBIMatched = BICountryRec.Business_Identity__c === BI;
            return isBIMatched;
        }
        const BrandCountriesListforBI = BICountriesCSList.filter(getBrandsCountriesListforBI);

        /* Iterate BrandCountriesCSList of current BI, set BrandCountriesMap */
        const BrandCountriesMapforBI = new Map();
        function setBrandCountriesMapforBI(BrandCountryCSRec) {
            const brand = BrandCountryCSRec.Brand_Name__c;
            const country = BrandCountryCSRec.Country__c;
            let countriesSet = new Set();
            if (BrandCountriesMapforBI.has(brand)) {
                countriesSet = BrandCountriesMapforBI.get(brand);
            }
            countriesSet.add(country);
            BrandCountriesMapforBI.set(brand, countriesSet);
        }

        BrandCountriesListforBI.forEach(setBrandCountriesMapforBI);

        /* Get BrandsList from BrandCountriesMapforBI */
        let brandsSetforBI;
        let brandsListforBI = [];
        if (BrandCountriesMapforBI != undefined) {
            brandsSetforBI = BrandCountriesMapforBI.keys();
            component.set("v.BrandCountriesForBIMap", BrandCountriesMapforBI);
        }
        if (brandsSetforBI != undefined) {
            brandsListforBI = Array.from(brandsSetforBI);
            if (brandsListforBI.length == 0) {
                brandsListforBI.push("");
            }
            component.set("v.brandsListforBI", brandsListforBI);
            component.set("v.brandName", brandsListforBI[0]);
        }
        /* Get CountriesList for selected Brand of BI */
        let countriesSetforBI;
        let countriesListforBI = [];
        if (BrandCountriesMapforBI != undefined && brandsListforBI.length > 0) {
            countriesSetforBI = BrandCountriesMapforBI.get(brandsListforBI[0]);
        }
        if (countriesSetforBI != undefined) {
            countriesListforBI = Array.from(countriesSetforBI).sort();
            component.set("v.countriesforBI", countriesListforBI);
        }
        var selectedCountryPicklist = component.find("selectedCountry");
        if (selectedCountryPicklist != null) {
            if (countriesListforBI.length == 0) {
                selectedCountryPicklist.set("v.disabled", true);
                countriesListforBI.push("-- None --");
                component.set("v.countriesforBI", countriesListforBI);
                this.onchangeCountry(component, event, helper, countriesListforBI[0]);

            } else {
                selectedCountryPicklist.set("v.disabled", false);
            }
        }
    },
    toggleHelper : function(component,event) {
        var toggleText = component.find("tooltip");
        $A.util.toggleClass(toggleText, "toggle");
    },
    getCommunityDetail : function (component, event, helper) {
        //pbc-10695
        var action = component.get("c.getCommunityDetails");
        action.setParams({
            "SFBrandName": component.get("v.brandName")
        });
        action.setCallback(this,function(result){
           var state = result.getState();
            console.log('state>'+state);
            if(state=== "SUCCESS"){
                var resultData = result.getReturnValue();
                component.set("v.communityDetailsRecord", resultData);
            }
        });
        $A.enqueueAction(action);
    },
    getPSPicklistValues: function(component, event, helper, partnerContact) {
        var defaultValue = component.get("v.defaultPSValue");
        var action = component.get("c.getServiceProvider");
        action.setParams({
            "partnerContact": partnerContact
        });
        action.setCallback(this,function(result){
           var state = result.getState();
            if(state=== "SUCCESS"){
                var resultVal = result.getReturnValue();
                component.set("v.mapPSValueKeys",resultVal.picklistValues);
                component.set("v.ShowISPField",resultVal.showISPField);
                component.find("selectedProvider").set("v.value", defaultValue);
            }

        });
        $A.enqueueAction(action);
    }
})