({
    getLeadList: function (component, event, helper, pageNumber, pageSize) {
        try {
            var val = component.get("v.selectedValue");
            console.log("account val>" + val);
            var action = component.get("c.getLeadDataController");
            action.setParams({
                selectedPartnerAccount: val,
                pageNumber: pageNumber,
                pageSize: pageSize,
                searchKeyWord: component.get("v.searchKeyword"),
                searchBy: component.get("v.searchBy")
            });
            action.setCallback(this, function (result) {
                var state = result.getState();
                if (component.isValid() && state === "SUCCESS") {
                    component.set("v.ShowRecordDetail", false);
                    component.set("v.ShowListView", true);
                    component.set("v.ShowConvertedSection", false);
                    var resultData = result.getReturnValue();
                    component.set("v.isReadOnly", resultData.isReadOnly);
                    if (resultData.leadList === undefined || resultData.leadList === "") {
                        component.set("v.Message", true);
                        component.set("v.ShowSpinnerLead", false);
                    } else {
                        component.set("v.Message", false);
                    }
                    if (resultData.leadList !== undefined && resultData.leadList !== "") {
                        for (var i = 0; i < resultData.leadList.length; i++) {
                            var row = resultData.leadList[i];
                            if (row.Partner_Account__c == null) {
                                row.PartnerAccount = " ";
                                row.PartnerId = " ";
                                row.PartnerChannelManager = " ";
                            } else {
                                row.PartnerAccount = row.Partner_Account__r.Name;
                                row.PartnerId = row.Partner_Account__r.Partner_ID__c;
                                row.PartnerChannelManager = row.Partner_Account__r.Partner_Channel_Manager__c;
                            }
                            if (row.Partner_Contact__c == null) {
                                row.PartnerContact = " ";
                            } else {
                                row.PartnerContact = row.Partner_Contact__r.Name;
                            }
                            if (row.Owner.Name) {
                                row.OwnerName = row.Owner.Name;
                            }
                            if (row.Portal_Cloud_Specialist__c == null) {
                                row.PortalCloudSpecialist = " ";
                            } else {
                                row.PortalCloudSpecialist = row.Portal_Cloud_Specialist__r.Name;
                            }
                        }
                        component.set("v.leadList", resultData.leadList);
                    }

                    component.set("v.pageNumber", resultData.pageNumber);
                    component.set("v.totalRecords", resultData.totalRecords);
                    component.set("v.recordStart", resultData.recordStart);
                    component.set("v.recordEnd", resultData.recordEnd);
                    component.set("v.totalPages", Math.ceil(resultData.totalRecords / pageSize));
                }
            });
            $A.enqueueAction(action);
        } catch (e) {
            console.log(e);
        }
    },

    getPartnerAccountList: function (component, helper) {
        var action = component.get("c.getAccountList");
        action.setCallback(this, function (result) {
            var state = result.getState();
            if (component.isValid() && state === "SUCCESS") {
                var resultData = result.getReturnValue();
                component.set("v.isReadOnly", resultData.isReadOnly);
                component.set("v.partnerCommunity", resultData.partnerCommunityName);
                console.log("comm name>" + component.get("v.partnerCommunity"));
                component.set("v.communityDetailsRecord", resultData.communityDetailsRecord);
                console.log("comm details>" + JSON.stringify(component.get("v.communityDetailsRecord")));
                component.set(
                    "v.Est12MPriceStd",
                    JSON.stringify(component.get("v.communityDetailsRecord").Estimated_12M_Booking_Standard__c)
                );
                console.log("price value std" + component.get("v.Est12MPriceStd"));
                component.set(
                    "v.Est12MPriceRCMeetings",
                    JSON.stringify(
                        component.get("v.communityDetailsRecord").Estimated_12M_RingCentral_Video_Pipeline__c
                    )
                );
                console.log("price value rc meetings>" + component.get("v.Est12MPriceRCMeetings"));
                if (resultData.listPartnerAccounts === undefined || resultData.listPartnerAccounts === "") {
                    component.set("v.Message", true);
                    component.set("v.ShowSpinnerLead", false);
                } else {
                    component.set("v.Message", false);
                }
                if (resultData.listPartnerAccounts !== undefined && resultData.listPartnerAccounts.length > 0) {
                    component.set("v.selectedValue", resultData.listPartnerAccounts[0].Id);
                    component.set("v.partnerAccounts", resultData.listPartnerAccounts);
                    component.set("v.partnerAccountName", resultData.listPartnerAccounts[0].Name);
                    component.set("v.accountId", resultData.listPartnerAccounts[0].Id);
                    if (resultData.isAvaya === true || resultData.isMaster === true) {
                        component.set("v.ShowConAcc", true);
                        component.set("v.viewAll", true);
                    }
                    if (resultData.isAvaya === true) {
                        component.set("v.ShowOnlyAvaya", true);
                    }
                    component.set("v.isSingleLogin", resultData.isSingleLogin);
                    var isAvayaMaster = component.get("v.ShowConAcc");
                    var comm = component.get("v.partnerCommunity");
                    var str = "RingCentral";
                    if (comm.includes(str)) {
                        component.set("v.ShowOnlyRC", true);
                    }
                    console.log("rc? >" + component.get("v.ShowOnlyRC"));
                    if (comm.includes("Unify Office")) {
                        component.set("v.ShowOnlyAtos", true);
                        var tierNames = ["Office", "RC Meetings"];
                        component.set("v.tierNames", tierNames);
                    }
                    console.log("Atos>" + component.get("v.ShowOnlyAtos"));
                    console.log("tiers>" + component.get("v.tierNames"));
                    if (resultData.isAvaya === true || resultData.isMaster) {
                        var pageNumber = 1;
                        var pageSize = 50;
                        this.getDataForViewAll(component, helper, pageNumber, pageSize);
                    } else {
                        var pageNumber = 1;
                        var pageSize = 50;
                        this.getLeadList(component, event, helper, pageNumber, pageSize);
                    }
                }
            }
        });
        return action;
    },

    getDataForViewAll: function (component, helper, pageNumber, pageSize) {
        console.log("pageNumber" + pageNumber);
        console.log("pageSize" + pageSize);
        var action = component.get("c.getDataForViewAll");

        action.setParams({
            pageNumber: pageNumber,
            pageSize: pageSize,
            searchKeyWord: component.get("v.searchKeyword"),
            searchBy: component.get("v.searchBy")
        });

        action.setCallback(this, function (result) {
            var state = result.getState();
            if (component.isValid() && state === "SUCCESS") {
                component.set("v.ShowRecordDetail", false);
                component.set("v.ShowListView", true);
                component.set("v.ShowConvertedSection", false);
                var resultData = result.getReturnValue();
                component.set("v.isReadOnly", resultData.isReadOnly);
                if (resultData.leadList === undefined || resultData.leadList === "") {
                    component.set("v.Message", true);
                    component.set("v.ShowSpinnerLead", false);
                } else {
                    component.set("v.Message", false);
                }
                if (resultData.leadList !== undefined && resultData.leadList !== "") {
                    for (var i = 0; i < resultData.leadList.length; i++) {
                        var row = resultData.leadList[i];
                        if (row.Partner_Account__c == null) {
                            row.PartnerAccount = " ";
                            row.PartnerId = " ";
                            row.PartnerChannelManager = " ";
                        } else {
                            row.PartnerAccount = row.Partner_Account__r.Name;
                            row.PartnerId = row.Partner_Account__r.Partner_ID__c;
                            row.PartnerChannelManager = row.Partner_Account__r.Partner_Channel_Manager__c;
                        }
                        if (row.Partner_Contact__c == null) {
                            row.PartnerContact = " ";
                        } else {
                            row.PartnerContact = row.Partner_Contact__r.Name;
                        }
                        if (row.Owner.Name) {
                            row.OwnerName = row.Owner.Name;
                        }
                        if (row.Portal_Cloud_Specialist__c == null) {
                            row.PortalCloudSpecialist = " ";
                        } else {
                            row.PortalCloudSpecialist = row.Portal_Cloud_Specialist__r.Name;
                        }
                    }
                    component.set("v.leadList", resultData.leadList);
                    if (resultData.isAvaya === true || resultData.isMaster) {
                        component.set("v.ShowConAccFields", true);
                    }
                    if (resultData.isAvaya === true) {
                        component.set("v.ShowOnlyAvaya", true);
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

    isIgniteFlowEnabled: function(component, event, helper) {
        var currentUser = component.get("v.currentUser");
        var leadRecord = component.get("v.leadRecord");
        var isIgniteDisabledBrand = component.get("v.isIgniteDisabledBrand");
        var customPermissions = Boolean(currentUser.customPermissions) ? currentUser.customPermissions : [];

        return customPermissions.indexOf("IgniteUQTFlow") > -1 && leadRecord.Partner_Program__c === "Ignite" && !isIgniteDisabledBrand;
    },

    isLeadHasDuplicates: function(component, event, helper) {
        var duplicates = component.get('v.duplicateIdList');

        return Array.isArray(duplicates) && duplicates.length > 0;
    },

    initConvertLeadButton: function(component, event, helper) {
        var leadRecord = component.get("v.leadRecord");
        var translations = component.get("v.translationsMap");
        var button = component.find("requestLeadConvertbtn");

        if (!Boolean(button)) {
            return;
        }

        button.set('v.disabled', leadRecord.IsAvayaConverted__c);

        if (helper.isIgniteFlowEnabled(component, event, helper)) {
            button.set('v.label', translations['Convert_Lead']);
        }
    },

    setConvertLeadButtonState: function(component, event, helper, value) {
        var button = component.find("requestLeadConvertbtn");
        button.set('v.disabled', Boolean(value));
    },

    actionRequestToConvertLead: function (component, event, helper, leadId) {
        var action = component.get("c.requestToConvertLead");

        action.setParams({ leadId: leadId });
        action.setCallback(this, function (result) {
            var data = result.getReturnValue();
            var toastEvent = $A.get("e.force:showToast");

            if (data === "SUCCESS") {
                helper.setConvertLeadButtonState(component, event, helper, true);

                component.set("v.showLeadRequestConv", true);

                toastEvent.setParams({
                    type: "success",
                    title: "Success!",
                    message: "Request Submitted!",
                    mode: "dismissible"
                });
            } else {
                toastEvent.setParams({
                    type: "error",
                    title: "Error!",
                    message: "Request Not Submitted",
                    mode: "dismissible"
                });
            }
            toastEvent.fire();
        });

        return action;
    },

    onchangeCountry: function (component, event, helper, country, state, competitor, employeeSelcted) {
        console.log("country" + country);
        try {
            var mapCountryStates = component.get("v.mapData");
            var mapCountryComp = component.get("v.mapCompData");
            var mapCountryEmp = component.get("v.mapEmpData");
            var selctedValue = country;
            var stateValues = [];
            var empValues = [];
            var statesForCountry = "";
            var compForCountry = "";
            var empForCountry = "";
            var countriesAvailable = component.get("v.countriesAvailable");
            try {
                statesForCountry = mapCountryStates[selctedValue].toString();
                compForCountry = mapCountryComp[selctedValue].toString();
                empForCountry = mapCountryEmp[selctedValue].toString();
            } catch (e) {
                console.log("Dependency picklist error");
            }

            if (
                countriesAvailable.indexOf(selctedValue) === -1 ||
                statesForCountry === undefined ||
                statesForCountry === "" ||
                statesForCountry == null
            ) {
                if (countriesAvailable.indexOf(selctedValue) === -1) {
                    if (countriesAvailable.indexOf("United States") !== -1) {
                        selctedValue = "United States";
                    } else if (countriesAvailable.indexOf(selctedValue) === -1) {
                        selctedValue = countriesAvailable[0];
                    }
                }
                statesForCountry = "";
                compForCountry = "";
                empForCountry = "";
            }
            console.log("country --" + selctedValue);
            if (component.get("v.partnerCommunity").includes("Unify Office")) {
                //ATOS 21.2 -- Including US, UK and Australia --
                var RCMeetingsCountries = [
                    "France",
                    "Ireland",
                    "Italy",
                    "Portugal",
                    "Spain",
                    "Belgium",
                    "Netherlands",
                    "Austria",
                    "Germany",
                    "United States",
                    "United Kingdom",
                    "Australia",
                ];
                var tierNames = ["Office"];
                if (RCMeetingsCountries.includes(selctedValue)) {
                    console.log("inside if");
                    tierNames = ["Office", "RC Meetings"];
                } else {
                    console.log("inside else");
                    component.set("v.RCMeetings", false);
                    component.find("tierSelected").set("v.value", "Office");
                }
                component.set("v.tierNames", tierNames);
                console.log("tiervalue>" + component.find("tierSelected").get("v.value"));
            }
            if (mapCountryStates[selctedValue] !== undefined && mapCountryStates[selctedValue] != null)
                statesForCountry = mapCountryStates[selctedValue].toString();
            if (mapCountryComp[selctedValue] !== undefined && mapCountryComp[selctedValue] != null)
                compForCountry = mapCountryComp[selctedValue].toString();
            if (mapCountryEmp[selctedValue] !== undefined && mapCountryEmp[selctedValue] != null)
                empForCountry = mapCountryEmp[selctedValue].toString();
            var compValues = [];

            component.find("selectedCountry").set("v.value", selctedValue);
            component.set("v.mapCountryValueKeys", stateValues);
            if (statesForCountry !== "" && statesForCountry !== undefined && statesForCountry != null) {
                for (var i = 0; i < statesForCountry.split(",").length; i++) {
                    if (
                        i === 0 &&
                        statesForCountry.indexOf("--None") === -1 &&
                        statesForCountry.indexOf("-- None") === -1
                    ) {
                        stateValues.push("-- None --");
                        stateValues.push(statesForCountry.split(",")[i]);
                    } else {
                        stateValues.push(statesForCountry.split(",")[i]);
                    }
                }
                component.find("selectedState").set("v.value", stateValues[0]);
                var selectCmp = component.find("selectedState");
                if (selectCmp != null) {
                    selectCmp.set("v.disabled", false);
                }
            } else {
                var selectCmp = component.find("selectedState");
                if (selectCmp != null) {
                    stateValues.push("-- None --");
                    selectCmp.set("v.disabled", true);
                }
            }
            //for competitors
            if (compForCountry !== "" && compForCountry !== undefined && compForCountry != null) {
                var compObj = {};
                var compTmpValue = [];
                for (var i = 0; i < compForCountry.split(",").length; i++) {
                    compTmpValue.push({ value: compForCountry.split(",")[i], label: compForCountry.split(",")[i] });
                }
                compValues = compTmpValue;
                var comp = component.find("competitor");
                comp.set("v.value", "");
                component.set("v.selectedCompItems", "");
            }
            if (empForCountry !== "" && empForCountry !== undefined && empForCountry != null) {
                for (var i = 0; i < empForCountry.split(",").length; i++) {
                    if (i === 0 && empForCountry.indexOf("--None") === -1 && empForCountry.indexOf("-- None") === -1) {
                        empValues.push("-- None --");
                        empValues.push(empForCountry.split(",")[i]);
                    } else {
                        empValues.push(empForCountry.split(",")[i]);
                    }
                }
                var selectEmpCmp = component.find("selectedEmp");
                if (selectEmpCmp != null) {
                    selectEmpCmp.set("v.disabled", false);
                }
            }
            component.set("v.mapCountryValueKeys", stateValues);
            component.set("v.mapCountryCompValKeys", compValues);
            component.set("v.mapEmpCompValKeys", empValues);
            if (state !== undefined && state != null && state !== "" && stateValues.includes(state)) {
                component.find("selectedState").set("v.value", state.toLocaleUpperCase());
            }
            if (employeeSelcted !== undefined && employeeSelcted != null && employeeSelcted !== "") {
                component.find("selectedEmp").set("v.value", employeeSelcted);
            }
            if (competitor !== undefined && competitor != null && competitor !== "") {
                var compTmpValue = [];
                for (var k = 0; k < competitor.split(";").length; k++) {
                    compTmpValue.push(competitor.split(";")[k].toLocaleUpperCase());
                }
                console.log("compTmpValue ++ " + compTmpValue);

                component.find("competitor").set("v.value", compTmpValue);
                component.set("v.selectedCompItems", competitor);
            }
        } catch (e) {
            console.log(e);
        }
    },

    onChangeBrand: function (component, event, helper, brandName, countryPart, state, competitor, employeeSelcted) {
        try {
            var brandCntryMap = component.get("v.mapDataBrand");
            var brandSelected = event.getSource().get("v.value");
            var countriesAvailable = [];
            if (brandName !== undefined && brandName != null && brandName !== "") {
                brandSelected = brandName;
            }
            var country = "";
            var arrayMapKeys = [];

            var cntryForBrand = brandCntryMap[brandSelected].toString();

            //Added for multiple countries for ACO 3.0
            var partnerAvailableCountries = component.get("v.partnerAvailableCountries");

            for (var b = 0; b < cntryForBrand.split(",").length; b++) {
                if (b === 0) {
                    country = cntryForBrand.split(",")[b];
                }
                if (countryPart !== undefined && countryPart !== "" && countryPart === cntryForBrand.split(",")[b]) {
                    country = cntryForBrand.split(",")[b];
                }
                if (component.get("v.logdPartnrCntry") === cntryForBrand.split(",")[b]) {
                    country = cntryForBrand.split(",")[b];
                }

                //Added for multiple countries for ACO 3.0
                if (
                    partnerAvailableCountries != null &&
                    partnerAvailableCountries !== undefined &&
                    partnerAvailableCountries !== ""
                ) {
                    if (partnerAvailableCountries.indexOf(cntryForBrand.split(",")[b]) !== -1)
                        countriesAvailable.push(cntryForBrand.split(",")[b]);
                } else {
                    countriesAvailable.push(cntryForBrand.split(",")[b]);
                }

                arrayMapKeys.push({ key: cntryForBrand.split(",")[b], value: cntryForBrand.split(",")[b] });
            }
            component.set("v.mapCountryKeys", arrayMapKeys);
            component.set("v.countriesAvailable", countriesAvailable);
            this.onchangeCountry(component, event, helper, country, state, competitor, employeeSelcted);
        } catch (e) {
            console.log(e);
        }
    },

    processGetLeadDetails: function(component, event, helper, resultData) {
        var LeanDataUserId = $A.get("$Label.c.LeanDataUserId");
        var partnerCommunityName = resultData.partnerCommunityName;
        var leadRecord = resultData.leadRecord;
        var salesName = leadRecord.Inside_Sales_Rep__c !== undefined ? leadRecord.Inside_Sales_Rep__r.Name : "";
        var leadCountry = leadRecord.Country__c;
        var leadOwnerId = leadRecord.OwnerId;
        var leanQueueId;

        var STRING_RINGCENTRAL = "RingCentral";
        var STRING_AVAYA_CLOUD_OFFICE = "Avaya Cloud Office";
        var STRING_UNIFY_OFFICE = "Unify Office";

        var RCMeetingsCountries = [
            "France",
            "Ireland",
            "Italy",
            "Portugal",
            "Spain",
            "Belgium",
            "Netherlands",
            "Austria",
            "Germany"
        ];

        if (partnerCommunityName.includes(STRING_RINGCENTRAL)) {
            component.set("v.ShowOnlyRC", true);
        }

        if (partnerCommunityName.includes(STRING_AVAYA_CLOUD_OFFICE)) {
            component.set("v.isAvaya", true);

            if (leadCountry === 'Australia') {
                component.set("v.ShowAvayaAus", true);
            }
        }

        if (partnerCommunityName.includes(STRING_UNIFY_OFFICE)) {
            component.set("v.ShowOnlyAtos", true);

            if (RCMeetingsCountries.includes(leadCountry)) {
                var tierNames = ["Office", "RC Meetings"];
                component.set("v.tierNames", tierNames);
            }
        }

        if (leadRecord.Inside_Sales_Rep__c === undefined) {
            leadRecord.ChannelManager = " ";
        } else {
            leadRecord.ChannelManager = salesName;
        }

        if (LeanDataUserId !== undefined) {
            leanQueueId = LeanDataUserId;
        }

        component.set("v.isReadOnly", resultData.isReadOnly);
        component.set("v.partnerCommunity", resultData.partnerCommunityName);
        component.set("v.communityDetailsRecord", resultData.communityDetailsRecord);
        component.set("v.leadRecord", resultData.leadRecord);
        component.set('v.showLeadRequestConv', leadRecord.IsAvayaConverted__c);
        component.set("v.isSingleLogin", resultData.isSingleLogin);
        component.set("v.ShowOnlyAvaya", resultData.isAvaya === true);
        component.set("v.duplicateIdList", resultData.duplicateIdList);
        component.set("v.isIgniteDisabledBrand", resultData.isIgniteDisabledBrand);
        component.set("v.isInvalidUsers", (
                leadOwnerId.substring(0, 15) === leanQueueId ||
                leadRecord.Number_of_Users__c > 100 ||
                leadRecord.Forecasted_RingCentral_Video_Users__c > 100
            )
        );
        component.set('v.isLeadConvertAvailable', (
                !Boolean(component.get('v.isAvaya')) &&
                (
                    leadRecord.Sector__c !== 'Public Sector' &&
                    leadRecord.Sector__c !== 'Education' &&
                    Boolean(leadRecord.Sector__c)
                )
            )
        );
        component.set("v.showMitelShare", (
                leadRecord.Partner_Account__r !== undefined &&
                leadRecord.Partner_Account__r.Partner_Classification__c === "Mitel Referral" &&
                leadRecord.Type_of_Customer_or_Prospect__c === "Existing Premise Based Customer"
            )
        ); //PBC-9705 P2CSharing
        component.set("v.ShowConAcc", (
                resultData.isAvaya === true ||
                resultData.isMaster === true
            )
        );

        helper.initConvertLeadButton(component, event, helper);
    },

    actionGetLeadDetails: function(component, event, helper) {
        var action = component.get("c.getLeadDetail");
        var leadId = component.get("v.recordID");

        action.setParams({ leadRecordId: leadId });
        action.setCallback(this, function (response) {
            try {
                helper.handleAuraActionResponse(component, event, helper, action, response);
                helper.processGetLeadDetails(component, event, helper, response.getReturnValue());
            } catch (ex) {
                console.error(ex);
            } finally {
                component.set("v.ShowSpinnerLead", false);
            }
        });

        return action;
    },

    processCountryStateValues: function(component, event, helper, dataResponse) {
        var leadRecord = component.get('v.leadRecord');
        var leadPartnerCountry = Boolean(leadRecord.Partner_Account__r) ? leadRecord.Partner_Account__r.Partner_Country__c : null;

        var data = dataResponse.countryStateMap;
        var countries = dataResponse.countriesAvailable;
        var brandCntryMap = dataResponse.mapBrandCntry;

        var competitiors = dataResponse.countryCompetitorMap;
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
        component.set("v.logdPartnrCntry", logPatnrCntry);
        component.set("v.countriesAvailable", countries);
        component.set("v.partnerhasAllCntryAcess", dataResponse.partnerhasAllCntryAcess);

        //Added for multiple countries in ACO 3.0
        component.set("v.partnerAvailableCountries", dataResponse.partnerAvailableCountries);

        if (leadPartnerCountry !== undefined && leadPartnerCountry != null && leadPartnerCountry !== "") {
            logPatnrCntry = leadPartnerCountry;
        }
        console.log("competitiors" + competitiors);
        var i = 0;
        for (var key in data) {
            if (countries.includes(key)) {
                if (i === 0) {
                    stateValues = data[key];
                    arrayMapKeys.push({ key: key, value: data[key] });
                    empValues = noOfEmployees[key];
                    arrayEmpMapKeys.push({ key: key, value: data[key] });
                    if (
                        competitiors[key] != null &&
                        competitiors[key] !== undefined &&
                        competitiors[key] !== ""
                    ) {
                        compValues = competitiors[key];
                        compTmpValue = [];
                        for (var j = 0; j < competitiors[key].length; j++) {
                            compTmpValue.push({ value: competitiors[key][j], label: competitiors[key][j] });
                        }
                        arrayCompMapKeys.push({ key: key, value: compTmpValue });
                        compValues = compTmpValue;
                    }
                    i++;
                } else {
                    arrayMapKeys.push({ key: key, value: data[key] });
                    arrayEmpMapKeys.push({ key: key, value: data[key] });
                    if (
                        competitiors[key] != null &&
                        competitiors[key] !== undefined &&
                        competitiors[key] !== ""
                    ) {
                        compTmpValue = [];
                        for (var j = 0; j < competitiors[key].length; j++) {
                            compTmpValue.push({ value: competitiors[key][j], label: competitiors[key][j] });
                        }
                        arrayCompMapKeys.push({ key: key, value: compTmpValue });
                    }
                }
            }
        }

        component.set("v.mapDataBrand", brandCntryMap);

        component.set("v.mapCountryKeys", arrayMapKeys);
        component.set("v.mapData", data);
        component.set("v.mapCountryValueKeys", stateValues);

        component.set("v.mapCompData", competitiors);
        component.set("v.mapCountryCompKeys", arrayCompMapKeys);
        component.set("v.mapCountryCompValKeys", compValues);

        component.set("v.mapEmpData", noOfEmployees);
        component.set("v.mapEmpCompKeys", arrayEmpMapKeys);
        component.set("v.mapEmpCompValKeys", empValues);
    },

    actionGetCountryStateMap: function (component, event, helper) {
        var action = component.get("c.getCountryStateMap");

        action.setParams({ who: "" });
        action.setCallback(this, function (response) {
            try {
                helper.handleAuraActionResponse(component, event, helper, action, response);
                helper.processCountryStateValues(component, event, helper, response.getReturnValue());
            } catch (ex) {
                console.error(ex);
            } finally {
                component.set("v.ShowSpinnerLead", false);
            }
        });

        return action;
    },

    actionGetTranslations: function (component, event, helper) {
        var action = component.get("c.getTranslations");
        action.setParams({ objNames: "Lead" });
        action.setCallback(this, function (response) {
            try {
                helper.handleAuraActionResponse(component, event, helper, action, response);

                var resultData = response.getReturnValue();
                if (Boolean(resultData.allObjFieldsMap)) {
                    component.set("v.leadFieldsMap", resultData.allObjFieldsMap.Lead);
                }

                component.set("v.translationsMap", resultData.prmLabelsMap);
                component.set("v.PRMSpecificTranslationsMap", resultData.prmSpecificLabelsMap);
            } catch (ex) {
                console.error(ex);
            } finally {
                component.set("v.ShowSpinnerLead", false);
            }
        });

        return action;
    },

    actionGetCurrentUserInfo: function (component, event, helper) {
        var action = component.get("c.getCurrentUserInfo");
        action.setCallback(this, function (response) {
            try {
                helper.handleAuraActionResponse(component, event, helper, action, response);

                var currentUser = response.getReturnValue();
                component.set("v.currentUser", currentUser);
            } catch (ex) {
                console.error(ex);
            } finally {
                component.set("v.ShowSpinnerLead", false);
            }
        });

        return action;
    },

    handleAuraActionResponse: function(component, event, helper, action, response) {
        console.log('action.getName(): ' + action.getName());
        console.log('result.getState(): ' + response.getState());
        console.log('result.getReturnValue(): ' + JSON.stringify(response.getReturnValue()));

        if (response.getState() !== "SUCCESS") {
            throw this.raiseAuraActionError(component, event, helper, action, response);
        }

        if (!Boolean(response.getReturnValue())) {
            throw this.raiseResponseError(component, event, helper, action, response, 'No response data');
        }
    },

    raiseResponseError: function(component, event, helper, action, response, message) {
        var error = new Error('Action ' + action.getName() + ' encountered an error: ' + message);

        error.action = action;
        error.response = response;

        return error;
    },

    raiseAuraActionError: function(component, event, helper, action, response) {
        var errorMessageString = helper.getAuraActionResponseErrors(component, event, helper, action, response)
            .map(function(message) { return '\n - ' + message });
        var error = new Error('Action ' + action.getName() + ' encountered errors:\n' + errorMessageString);

        error.action = action;
        error.response = response;

        return error;
    },

    getAuraActionResponseErrors: function(component, event, helper, action, response) {
        if (response.getError().length === 0) {
            return;
        }

        var errors = response.getError();
        var messages = [];
        for (var i = 0; i < errors.length; i++) {
            messages.push(errors[i].message);
        }

        return messages;
    }
});