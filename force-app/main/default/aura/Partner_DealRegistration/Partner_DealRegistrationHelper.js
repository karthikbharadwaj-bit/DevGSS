({
    //METHOD TO GET DEAL RECORDS FOR LIST VIEW
    getDealRegList : function(component, event, helper,pageNumber,pageSize) {
        var val =component.get("v.selectedAccountValue");
        var statusval =component.get("v.selectedStatusValue");
        var action = component.get("c.getDealRegDataController");

        action.setParams({
            "selectedPartnerAccount":val,
            "selectedDealStatus":statusval,
            'pageNumber': pageNumber,
            'pageSize':pageSize,
            'searchKeyWord':component.get("v.searchKeyword"),
            'searchBy': component.get("v.searchBy")
        });
        action.setCallback(this, function(result) {
            var state = result.getState();
            if (component.isValid() && state === "SUCCESS"){
                var resultData = result.getReturnValue();
                component.set("v.ShowRecordDetail", false);
                component.set("v.ShowListView", true);
                component.set("v.ShowEditSection",false);
                if(resultData.dealRegList == undefined || resultData.dealRegList == ''){
                    component.set("v.Message", true);
                    component.set('v.ShowSpinnerOpp',false);
                }
                else{
                    component.set("v.Message", false);
                }
                if(resultData.dealRegList != undefined && resultData.dealRegList != '')
                {
                    for (var i = 0; i < resultData.dealRegList.length; i++) {
                        var row = resultData.dealRegList[i];
                        component.set("v.recordID", resultData.dealRegList[0].Id);
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

                    }
                    component.set("v.dealRegList", resultData.dealRegList);
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

    //Translation Start
    getTranslations : function (component, event, helper)
    {
        try
        {
            var action = component.get("c.getTranslations");
            action.setParams({
                "objNames": 'Deal_Registration__c'
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
                            component.set("v.DealRegFieldsMap", resultData.allObjFieldsMap.Deal_Registration__c);
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


    //METHOD TO GET PARTNER ACCOUNTS
    getPartnerAccountList : function(component,helper){
        var action = component.get("c.getAccountList");
        action.setCallback(this, function(result) {
            var state = result.getState();
            if (component.isValid() && state === "SUCCESS"){
                var resultData = result.getReturnValue();
                component.set("v.partnerCommunity", resultData.partnerCommunityName);
                //component.set("v.communityUrl", resultData.partnerMasterLabel);
                component.set("v.communityDetailsRecord", resultData.communityDetailsRecord);

                component.set("v.isReadOnly", resultData.isReadOnly);
                if(resultData.listPartnerAccounts == undefined || resultData.listPartnerAccounts == ''){
                    component.set("v.Message", true);
                    component.set('v.ShowSpinnerOpp',false);
                }else{
                    component.set("v.Message", false);
                }
                if(resultData.listPartnerAccounts != undefined && resultData.listPartnerAccounts.length > 0)
                {
                    component.set("v.selectedAccountValue",resultData.listPartnerAccounts[0].Id);
                    component.set("v.partnerAccountName",resultData.listPartnerAccounts[0].Name);

                    var accountVARTerritory= resultData.listPartnerAccounts[0].VAR_Territory__c;
                    var accountPartnerType= resultData.listPartnerAccounts[0].Partner_Type__c;
                    // PBC-9705 P2CSharing
                    let partnerClassification = resultData.listPartnerAccounts[0].Partner_Classification__c; //Mitel P2CSharing
                    component.set("v.partnerClassification", partnerClassification); //Mitel P2CSharing
                    component.set("v.insideSalesRep",resultData.listPartnerAccounts[0].Inside_Sales_Rep__c);
                    component.set("v.insideSalesRepNew",resultData.listPartnerAccounts[0].Inside_Sales_Rep__c);
                    if(accountVARTerritory != undefined && accountPartnerType != undefined){
                        if(accountVARTerritory.includes('NAM') && accountPartnerType.includes('Master Agent')){
                            component.set('v.isNationalPartnerAccountNew',true);
                        }else{
                            component.set('v.isNationalPartnerAccountNew',false);
                        }
                    }else{
                        component.set('v.isNationalPartnerAccountNew',false);
                    }
                    //added for mitel
                    if(resultData.isMitel == true){
                        component.set("v.isMitel",true);
                    }
                    component.set("v.partnerAccounts",resultData.listPartnerAccounts);
                    var brands=[];
                    brands= resultData.listPartnerAccounts[0].Permitted_Brands__c.split(';');
                    var brandsList=[];
                    for(var i in brands){
                        brandsList.push(brands[i]);
                    }
                    component.set("v.brandsPermitted",brandsList);
                    //component.set("v.currentContactPortalView",resultData.currentUserContactAccess);
                    if(resultData.isAvaya==true || resultData.isMaster){
                        component.set("v.ShowConAccFields",true);
                        component.set("v.viewAll",true);
                    }
                    if(resultData.isAvaya==true){
                        component.set("v.ShowOnlyAvaya",true);
                    }
                    console.log('ShowOnlyAvaya', component.get("v.ShowOnlyAvaya"));
                    if(resultData.isMaster==true){
                        component.set("v.isMasterAgent",true);
                    }
                    if(resultData.currentUserContactAccess=='Full' &&(resultData.isAvaya==undefined && resultData.isMaster==undefined)){
                        component.set("v.isCurrentSubPartnerFullAccess",true);
                    }
                    console.log('resultData.isAvaya++++'+resultData.isAvaya);

                    if(resultData.currentUserContactAccess=='PCM'){
                        component.set("v.isCurrentContactPCM",true);
                    }
                    //added for Single Login
                    component.set("v.isSingleLogin",resultData.isSingleLogin);
                    if(resultData.isReseller == true)
                        component.set("v.isReseller",resultData.isReseller);
                    console.log('isReseller +++'+component.get("v.isReseller"));
                    var str = 'RingCentral';
                    var partnerComm = component.get("v.partnerCommunity");
                    var masterLabel = component.get("v.communityDetailsRecord").MasterLabel;
                    if(partnerComm.includes(str)&&masterLabel == 'ignite'){
                        component.set("v.ShowOnlyRC", true);
                    }
                    var str1 = 'Unify Office';
                    var partnerComm = component.get("v.partnerCommunity");
                    if(partnerComm.includes(str1)){
                        component.set("v.ShowOnlyATOS", true);
                    }
                    console.log('Atos ? +++'+component.get("v.ShowOnlyATOS"));
                    if(partnerComm.includes('Rainbow Office')) {
                        component.set("v.ShowOnlyALE", true);//pbc-10695
                    }
                    if(partnerComm.includes('Avaya Cloud Office')){
                        component.set("v.isNotAvaya",false);
                    }else{
                        component.set("v.isNotAvaya",true);
                    }

                    var accountPartnerCountry = resultData.listPartnerAccounts[0].Partner_Country__c;
                    /*Commented since default of MACM not neededif(resultData.listPartnerAccounts[0].Master_Agent_Channel_Manager__c != null && resultData.listPartnerAccounts[0].Master_Agent_Channel_Manager__c != undefined && resultData.listPartnerAccounts[0].Master_Agent_Channel_Manager__c != '')
                        this.getAccountMasterAgtChlMgr(component, event, helper,resultData.listPartnerAccounts[0].Master_Agent_Channel_Manager__c);*/

                    if(resultData.isAvaya==true || resultData.isMaster){
                        var pageNumber = 1;
                        var pageSize = 50;
                        this.getDataForViewAll(component,helper,pageNumber,pageSize);
                    }else{
                        var pageNumber = 1;
                        var pageSize = 50;
                        this.getDealRegList(component, event, helper,pageNumber,pageSize);
                    }
                }

            }
        });

        $A.enqueueAction(action);
    },

    //METHOD TO GET All Data for View All
    getDataForViewAll : function(component,helper,pageNumber,pageSize){

        var action = component.get("c.getDataForViewAll");
        var statusval =component.get("v.selectedStatusValue");
        action.setParams({
            'pageNumber': pageNumber,
            'pageSize':pageSize,
            'selectedDealStatus':statusval,
            'searchKeyWord':component.get("v.searchKeyword"),
            'searchBy': component.get("v.searchBy")
        });

        action.setCallback(this, function(result) {
            var state = result.getState();
            if (component.isValid() && state === "SUCCESS"){
                var resultData = result.getReturnValue();

                component.set("v.ShowRecordDetail", false);
                component.set("v.ShowListView", true);
                component.set("v.ShowEditSection",false);

                if(resultData.dealRegList == undefined || resultData.dealRegList == ''){
                    component.set("v.Message", true);
                    component.set('v.ShowSpinnerOpp',false);
                }else{
                    component.set("v.Message", false);
                }
                if(resultData.dealRegList != undefined && resultData.dealRegList != ''){
                    for (var i = 0; i < resultData.dealRegList.length; i++) {
                        var row = resultData.dealRegList[i];
                        component.set("v.recordID", resultData.dealRegList[0].Id);
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
                    }
                    component.set("v.dealRegList", resultData.dealRegList);
                    if(resultData.isAvaya==true || resultData.isMaster){
                        component.set("v.ShowConAccFields",true);
                    }
                    if(resultData.isAvaya==true){
                        component.set("v.ShowOnlyAvaya",true);
                    }
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
    getBlockedDomains : function(component,event,helper){
        var action = component.get("c.getBlockedDomains");
        action.setParams({
            'message' : ''
        });

        action.setCallback(this, function(result) {
            var state = result.getState();
            if (component.isValid() && state === "SUCCESS"){
                if(result.getReturnValue() != null && result.getReturnValue() != undefined){
                    component.set('v.blockedDomains',result.getReturnValue());
                }
            }
        });

        $A.enqueueAction(action);
    },
    getCountryStateValues : function(component,event,helper,partnerCountry){
        var toastEvent = $A.get('e.force:showToast');
        var action = component.get("c.getCountryStateMap");
        component.set('v.ShowSpinnerOpp',true);
        let isGuest = component.get("v.isGuestUser");
        if(isGuest)
        {
            if(component.get("v.brandsPermitted_Guest") != undefined)
            {
                action.setParams({
                    "communityBrand": component.get("v.brandsPermitted_Guest")[0]
                });
            }
        }
        else
        {
            action.setParams({
                "who": component.get("v.partnerCommunity")
            });
        }
        action.setCallback(this, function(response) {
            var state = response.getState();

            if (state === "SUCCESS") {
                var dataResponse = response.getReturnValue();
                var data = dataResponse.countryStateMap;
                var countries = dataResponse.countriesAvailable;
                var competitiors = dataResponse.countryCompetitorMap;
                var brandCntryMap = dataResponse.mapBrandCntry;
                var noOfEmployees = dataResponse.countryNoOfEmployeesMap;

                var arrayMapKeys = [];
                var stateValues = [];

                var arrayEmpMapKeys = [];
                var empValues = [];

                var arrayCompMapKeys = [];
                var compValues = [];

                var compObj = {};
                var compTmpValue = [];

                var logPatnrCntry = dataResponse.loggedPartnerCountry;
                component.set("v.logdPartnrCntry",logPatnrCntry);
                component.set("v.countriesAvailable",countries);
                component.set("v.partnerhasAllCntryAcess",dataResponse.partnerhasAllCntryAcess);

                //Added for multiple countries in ACO 3.0
                component.set("v.partnerAvailableCountries",dataResponse.partnerAvailableCountries);

                if(partnerCountry != null && partnerCountry != ''){
                    logPatnrCntry = partnerCountry;
                }
                var i = 0;
                for(var key in data){
                    if(countries.includes(key)){
                        if(i == 0){
                            stateValues = data[key];
                            arrayMapKeys.push(key);
                            empValues = noOfEmployees[key];
                            arrayEmpMapKeys.push(key);
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
                            //arrayMapKeys.push({key: key, value: data[key]});
                            arrayMapKeys.push(key);
                            arrayEmpMapKeys.push(key);
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
                component.set("v.mapCountryValueKeys",stateValues);

                component.set("v.mapCompData", competitiors);
                component.set("v.mapCountryCompKeys", arrayCompMapKeys);
                component.set("v.mapCountryCompValKeys",compValues);

                component.set("v.mapEmpData", noOfEmployees);
                component.set("v.mapEmpCompKeys", arrayEmpMapKeys);
                component.set("v.mapEmpCompValKeys",empValues);
                if(component.get("v.isGuestUser"))
                {
                    helper.showNewSectionHelper(component, event, helper);
                }
                /* if(logPatnrCntry == null || logPatnrCntry == ''){
                    logPatnrCntry = 'United States';
                    this.onchangeCountry(component,event,helper,logPatnrCntry);
                }*/
            }else{
                component.set('v.ShowSpinnerOpp',false);
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
            var isWholesalePartnerAcc = component.get('v.isWholeSalePartner');

            if(component.find("selectedCountry") == null){
                return;
            }
            var statesForCountry = '';
            var compForCountry ='';
            var empForCountry ='';
            try{
                statesForCountry = mapCountryStates[selctedValue].toString();
                compForCountry = mapCountryComp[selctedValue].toString();
                empForCountry = mapCountryEmp[selctedValue].toString();
            }catch(e){
                console.log('Dependency picklist error');
            }
            if (!component.get('v.isWholeSalePartner')) {
                if ((countriesAvailable.indexOf(selctedValue) == -1) || (statesForCountry == undefined || statesForCountry == '' || statesForCountry == null)) {
                    if ((countriesAvailable.indexOf(selctedValue) == -1)) {
                        if (countriesAvailable.indexOf('United States') != -1) {
                            selctedValue = 'United States';
                        } else if (countriesAvailable.indexOf(selctedValue) == -1) {
                            selctedValue = countriesAvailable[0];
                        }
                    }
                    statesForCountry = '';
                    compForCountry = '';
                    empForCountry = '';
                }
            }
            if(mapCountryStates[selctedValue] != undefined && mapCountryStates[selctedValue] != null)
                statesForCountry = mapCountryStates[selctedValue].toString();
            if(mapCountryComp[selctedValue] != undefined && mapCountryComp[selctedValue] != null)
                compForCountry = mapCountryComp[selctedValue].toString();
            if(mapCountryEmp[selctedValue] != undefined && mapCountryEmp[selctedValue] != null)
                empForCountry = mapCountryEmp[selctedValue].toString();

            component.find("selectedCountry").set("v.value",selctedValue);
            component.set("v.selectedCountry", selctedValue);
            //component.set("v.logdPartnrCntry",selctedValue);
            component.set("v.mapCountryValueKeys",stateValues);

            if(statesForCountry != '' && statesForCountry != undefined && statesForCountry != null){
                for(var i=0;i<statesForCountry.split(',').length;i++){
                    if(i == 0 && statesForCountry.indexOf('--None') == -1 && statesForCountry.indexOf('-- None') == -1){
                        stateValues.push('-- None --');
                        stateValues.push(statesForCountry.split(',')[i]);
                    }else{
                        stateValues.push(statesForCountry.split(',')[i]);
                    }
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
                component.set("v.selectedCompItems", "");

            }
            if(empForCountry != '' && empForCountry != undefined && empForCountry != null){
                for(var i=0;i<empForCountry.split(',').length;i++){
                    if(i == 0 && empForCountry.indexOf('--None') == -1 && empForCountry.indexOf('-- None') == -1){
                        empValues.push('-- None --');
                        empValues.push(empForCountry.split(',')[i]);
                    }else{
                        empValues.push(empForCountry.split(',')[i]);
                    }
                }
                var selectEmpCmp = component.find("selectedEmp");
                if(selectEmpCmp != null){
                    selectEmpCmp.set('v.disabled',false);
                }
            }else{
                var selectEmpCmp = component.find("selectedEmp");
                if(selectEmpCmp != null){
                    empValues.push('-- None --');
                    selectEmpCmp.set('v.disabled',true);
                }
            }
            component.set("v.mapCountryCompValKeys",compValues);
            component.set("v.mapCountryValueKeys",stateValues);
            component.set("v.mapEmpCompValKeys",empValues);
            component.find("selectedState").set("v.value",stateValues[0]);

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
            console.log('brandCntryMap>> + '+brandCntryMap[brandSelected]);
            var cntryForBrand;
            if (component.get("v.isWholeSalePartner")) { // BZS-9016
                if (component.get("v.BrandCountriesForBIMap") != undefined && component.get("v.BrandCountriesForBIMap").get(brandSelected) != undefined) {
                cntryForBrand = Array.from(component.get("v.BrandCountriesForBIMap").get(brandSelected)).toString();
                }
            } else if(brandCntryMap[brandSelected] != undefined && brandCntryMap[brandSelected] !=null && brandCntryMap[brandSelected] != '')
            	 cntryForBrand = brandCntryMap[brandSelected].toString();

            //Added for multiple countries for ACO 3.0
            var partnerAvailableCountries = component.get("v.partnerAvailableCountries");

            for(var b=0;b<cntryForBrand.split(',').length;b++){
                if(countryPart != undefined && countryPart != '' && countryPart == cntryForBrand.split(',')[b]){
                    country = cntryForBrand.split(',')[b];
                }

                if(component.get('v.logdPartnrCntry') == cntryForBrand.split(',')[b]){
                    //country = cntryForBrand.split(',')[b];
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

            component.set("v.mapCountryKeys", arrayMapKeys.sort());

            if(country == undefined || country == ''){
                country = arrayMapKeys[0];
            }
            component.set("v.countriesAvailable",countriesAvailable.sort());
            // BZS-9016
            if (component.get("v.isWholeSalePartner")) {
                component.set("v.countriesforBI", countriesAvailable.sort());
            } else {
                component.find("selectedCountry").set("v.disabled", false);
            }
            //For internal rc - replace essentials with edition if ringcentral uk

            var partnerComm = component.get("v.partnerCommunity");
            this.onchangeCountry(component,event,helper,country);
        }catch(e){
            console.log(e)
        }
    },
    getAccountListForStoreFront : function(component,helper){
        console.log('getAccountListForStoreFront');
        var action = component.get("c.getAccountList");
        action.setCallback(this, function(result) {
            var state = result.getState();
            if (component.isValid() && state === "SUCCESS"){
                var resultData = result.getReturnValue();
                console.log('contact access>' +resultData.currentUserContactAccess);
                console.log('isAvaya>' +resultData.isAvaya);
                console.log('isMaster>' +resultData.isMaster);

                component.set("v.partnerCommunity", resultData.partnerCommunityName);
                component.set("v.communityDetailsRecord", resultData.communityDetailsRecord);
                component.set("v.isReadOnly", resultData.isReadOnly);

                if(resultData.listPartnerAccounts == undefined || resultData.listPartnerAccounts == ''){
                    component.set("v.Message", true);
                    component.set('v.ShowSpinnerOpp',false);
                }else{
                    component.set("v.Message", false);
                }
                if(resultData.listPartnerAccounts != undefined && resultData.listPartnerAccounts.length > 0)
                {
                    component.set("v.selectedAccountValue",resultData.listPartnerAccounts[0].Id);
                    component.set("v.partnerAccountName",resultData.listPartnerAccounts[0].Name);
                    component.set("v.partnerAccounts",resultData.listPartnerAccounts);
                    var brands=[];
                    brands= resultData.listPartnerAccounts[0].Permitted_Brands__c.split(';');
                    var brandsList=[];
                    for(var i in brands){
                        brandsList.push(brands[i]);
                    }
                    console.log("brandsList"+brandsList);
                    component.set("v.brandsPermitted",brandsList);

                    if(resultData.isAvaya==true || resultData.isMaster){
                        component.set("v.ShowConAccFields",true);
                        component.set("v.viewAll",true);
                    }
                    if(resultData.isAvaya==true){
                        component.set("v.ShowOnlyAvaya",true);
                    }

                    if(resultData.currentUserContactAccess=='Full' &&(resultData.isAvaya==undefined && resultData.isMaster==undefined)){
                        component.set("v.isCurrentSubPartnerFullAccess",true);
                    }
                    if(resultData.currentUserContactAccess=='PCM'){
                        component.set("v.isCurrentContactPCM",true);
                    }
                }
                var str = 'RingCentral';
                var partnerComm = component.get("v.partnerCommunity");
                var masterLabel = component.get("v.communityDetailsRecord").MasterLabel;
                if(partnerComm.includes(str)&&masterLabel == 'ignite'){
                    component.set("v.ShowOnlyRC", true);
                }
                console.log('partnerComm'+partnerComm)
                if(partnerComm.includes('Avaya Cloud Office')){
                    component.set("v.isNotAvaya",false);
                    var url = new URL(location.href);
                    var action = url.searchParams.get('action');
                    if(action != null && action != undefined && action =='behalf'){
                        this.showNewBehalfSectionHelper(component, event, helper);
                    }else{
                        this.showNewSectionHelper(component, event, helper);
                    }
                }else{
                    try{
                        var urlDeal = component.get('v.RespectiveTabURL').toString();
                        urlDeal = urlDeal.split('?')[0];
                        var urlEvent = $A.get("e.force:navigateToURL");
                        urlEvent.setParams({
                            "url": urlDeal
                        });
                        urlEvent.fire();
                        component.set("v.isNotAvaya",true);
                    }catch(e){
                        console.log(e)
                    }

                }
                console.log('partnerComm'+component.get("v.isNotAvaya"))
            }
        });
        $A.enqueueAction(action);
    },
    showNewSectionHelper:function(component,event,helper){
        component.set("v.ShowListView", false);
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

        console.log('ShowOnlyRC++'+component.get("v.ShowOnlyRC"))
        var stateValues = component.get("v.mapCountryValueKeys");
        if(stateValues.length <=0 || stateValues == ''){
            var selectCmp = component.find("selectedState");
            if(selectCmp != null){
                stateValues.push('-- None --');
                selectCmp.set('v.disabled',true);
            }
            component.set("v.mapCountryValueKeys",stateValues);
        }

        //helper.onchangeCountry(component,event,helper,component.get('v.logdPartnrCntry'));
        if(component.get("v.isGuestUser"))
        {
            this.onChangeBrand(component, event, helper, component.get("v.brandsPermitted_Guest")[0], component.get('v.logdPartnrCntry'));
        }
        else
        {
            if(component.get("v.ShowOnlyRC") == true){
                this.onChangeBrand(component,event,helper,component.get("v.brandsPermitted")[0],component.get('v.logdPartnrCntry'));
            }else{
                this.onChangeBrand(component,event,helper,component.get("v.partnerCommunity")[0],component.get('v.logdPartnrCntry'));
            }
        }
    },

    showNewBehalfSectionHelper:function (component, event, helper) {
        component.set("v.ShowListView", false);
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
        component.set("v.ShowRequiredErrorSection",true);
        var stateValues = component.get("v.mapCountryValueKeys");
        if(stateValues.length <=0 || stateValues == ''){
            var selectCmp = component.find("selectedState");
            if(selectCmp != null){
                stateValues.push('-- None --');
                selectCmp.set('v.disabled',true);
            }
            component.set("v.mapCountryValueKeys",stateValues);
        }
        //helper.onchangeCountry(component,event,helper,component.get('v.logdPartnrCntry'));
        if(component.get("v.ShowOnlyRC") == true){
            this.onChangeBrand(component,event,helper,component.get("v.brandsPermitted")[0],component.get('v.logdPartnrCntry'));
        }else{
            this.onChangeBrand(component,event,helper,component.get("v.partnerCommunity")[0],component.get('v.logdPartnrCntry'));
        }

        var partnerComm = component.get("v.partnerCommunity");
        console.log("partnerComm "+partnerComm);
        if(partnerComm === "Internal RC"){
            component.set("v.ShowOnlyRC", true);
        }
        console.log('RC ?>'+component.get("v.ShowOnlyRC"));
        console.log('ShowCTRL>'+component.get("v.ShowOnlyRC"));
    },

    getAccountMasterAgtChlMgr:function(component, event, helper,accountMasterAgentChlMgr){
        console.log('accountMasterAgentChlMgr >'+accountMasterAgentChlMgr);
        var accountMasterAgentChlMgr=accountMasterAgentChlMgr;
        var action = component.get("c.PartnerAccountMasterAgtChlMgr");
        action.setParams({
            "accountMasterAgentChlMgr": accountMasterAgentChlMgr

        });
        action.setCallback(this, function(result) {
            var state = result.getState();
            console.log('state of ACS>' +state);
            if (component.isValid() && state === "SUCCESS"){
                var resultData = result.getReturnValue();
                console.log('mgr>'+resultData);
                component.set("v.cloudSpecialistContactId",resultData);
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
    //BZS-9016 - start
    getBrandCountriesForBI: function (component, event,helper, BI) {
        /* Get BrandCountriesCSList for current BI */
        const BICountriesCSList = component.get("v.BICountriesCSList");
        if(BICountriesCSList == undefined) return;

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
        let brandsSetforBI, brandsListforBI;
        if (BrandCountriesMapforBI != undefined) {
            brandsSetforBI = BrandCountriesMapforBI.keys();
            component.set("v.BrandCountriesForBIMap", BrandCountriesMapforBI);
        }
        if (brandsSetforBI != undefined) {
            const brandsPicklist = component.find("brandSelected");
            brandsListforBI = Array.from(brandsSetforBI);
            if (brandsPicklist != null) {
                if (brandsListforBI.length == 0) {
                    brandsListforBI.push("-- None --");
                    brandsPicklist.set('v.disabled', true);
                } else {
                    brandsPicklist.set('v.disabled', false);
                }
            }
            component.set("v.brandsListforBI", brandsListforBI);
            component.set("v.selectedBrandValue", brandsListforBI[0]);
        }
        /* Get CountriesList for selected Brand of BI */
        let countriesSetforBI;
        let countriesListforBI = [];
        if (BrandCountriesMapforBI != undefined && brandsListforBI.length > 0) {
            countriesSetforBI = BrandCountriesMapforBI.get(brandsListforBI[0]);
        }
        if (countriesSetforBI != undefined) {
            countriesListforBI = Array.from(countriesSetforBI);
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
    },//BZS-9016 - end
    /* Ignite changes starts */
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
                component.set("v.mapPSValueKeys",resultVal);
                var isNewOnBehalf = component.get("v.NewOnBehalf");
                var providerComponent;
                if (isNewOnBehalf) {
                    providerComponent = component.find("selectedProvider");
                } else {
                    providerComponent = component.find("selectedInstallProvider");
                }
                if (providerComponent) {
                    providerComponent.set("v.value", defaultValue);
                }
            }
        });
        $A.enqueueAction(action);
    },
    getFilteredPicklistValues: function(component, event, helper) {
        var action = component.get("c.getServiceProviderByUser");
        var userId = component.get("v.userId");
        var defaultinstallPSValue = component.get("v.defaultinstallPSValue");

        action.setParams({
            "userId": userId
        });

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var picklistValues = response.getReturnValue();
                component.set("v.mapInstallPSValuesKeys", picklistValues);

            }
        });
        $A.enqueueAction(action);
        //component.find("selectedInstallProvider").set("v.value", defaultPicklistValue);
    }
})