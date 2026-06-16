({
    doInit: function (component, event, helper) {
        var url = new URL(location.href);
        var baseURL = url.href.substring(0, url.href.indexOf("/s"));
        var OpportunityURLLink = baseURL + "/s/partneropportunities?id=";
        var id = url.searchParams.get("id");

        component.set("v.recordID", id);
        component.set("v.RespectiveTabURL", url);
        component.set("v.OpportunityURLLink", OpportunityURLLink);

        if (id == null || id === "") {
            component.set("v.ShowListView", true);
            component.set("v.ShowRecordDetail", false);
            component.set("v.ShowComponentButtons", false);
            $A.enqueueAction(helper.getPartnerAccountList(component, event, helper));
            $A.enqueueAction(helper.actionGetCurrentUserInfo(component, event, helper));
            $A.enqueueAction(helper.actionGetTranslations(component, event, helper));
        } else {
            component.set("v.ShowSpinnerLead", true);
            component.set("v.ShowListView", false);
            component.set("v.ShowRecordDetail", true);
            component.set("v.ShowComponentButtons", true);
            $A.enqueueAction(helper.actionGetCurrentUserInfo(component, event, helper));
            $A.enqueueAction(helper.actionGetTranslations(component, event, helper));
            $A.enqueueAction(helper.actionGetLeadDetails(component, event, helper));
            $A.enqueueAction(helper.actionGetCountryStateMap(component, event, helper));
        }
    },

    onSelectChange: function (component, event, helper) {
        var isShowConAcc = component.get("v.ShowConAcc");
        var isViewAll = false;
        if (isShowConAcc) {
            isViewAll = component.find("filterType").get("v.checked");
        }
        if (isViewAll) {
            var pageNumber = 1;
            var pageSize = component.find("pageSizeForAll").get("v.value");
            helper.getDataForViewAll(component, helper, pageNumber, pageSize);
        } else {
            var pageNumber = 1;
            var pageSize = component.find("pageSize").get("v.value");
            helper.getLeadList(component, event, helper, pageNumber, pageSize);
        }
    },

    handleNext: function (component, event, helper) {
        var pageNumber = component.get("v.pageNumber");
        var isShowConAcc = component.get("v.ShowConAcc");
        var isViewAll = false;
        if (isShowConAcc) {
            isViewAll = component.find("filterType").get("v.checked");
        }
        if (isViewAll) {
            var pageSize = component.find("pageSizeForAll").get("v.value");
            pageNumber++;
            helper.getDataForViewAll(component, helper, pageNumber, pageSize);
        } else {
            var pageSize = component.find("pageSize").get("v.value");
            pageNumber++;
            helper.getLeadList(component, event, helper, pageNumber, pageSize);
        }
    },

    handlePrev: function (component, event, helper) {
        var pageNumber = component.get("v.pageNumber");
        var isShowConAcc = component.get("v.ShowConAcc");
        var isViewAll = false;
        if (isShowConAcc) {
            isViewAll = component.find("filterType").get("v.checked");
        }
        if (isViewAll) {
            var pageSize = component.find("pageSizeForAll").get("v.value");
            pageNumber--;
            helper.getDataForViewAll(component, helper, pageNumber, pageSize);
        } else {
            var pageSize = component.find("pageSize").get("v.value");
            pageNumber--;
            helper.getLeadList(component, event, helper, pageNumber, pageSize);
        }
    },

    onChangeVal: function (component, event, helper) {
        var pageNumber = component.get("v.pageNumber");
        var pageSize = component.find("pageSize").get("v.value");
        helper.getLeadList(component, event, helper, pageNumber, pageSize);
        component.set("v.ShowRecordDetail", false);
    },

    goBack: function (component, event, helper) {
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            url: window.location.pathname + "?id=" + component.get("v.recordID")
        });
        urlEvent.fire();
    },

    showEditSectionAres: function (component, event, helper) {
        console.log("RC? >" + component.get("v.ShowOnlyRC"));
        component.set("v.ShowEditSection", true);
        component.set("v.ShowListView", false);
        component.set("v.ShowRecordDetail", true);
        component.set("v.ShowSpinnerOpp", true);
        component.set("v.ShowComponentButtons", false);
        var leadRecord = component.get("v.leadRecord");
        console.log("hgsd" + component.get("v.partnerhasAllCntryAcess"));
        var comm = component.get("v.partnerCommunity");
        var str = "RingCentral";
        if (comm.includes(str)) {
            component.set("v.ShowOnlyRC", true);
        }
        if (comm.includes("Avaya Cloud Office")) {
            component.set("v.isAvaya", true);
        }
        console.log("RC? >" + component.get("v.ShowOnlyRC"));
        if (component.find("selectedCountry") != null) {
            component.find("selectedCountry").set("v.value", leadRecord.Country__c);
            var selctedValue = component.find("selectedCountry").get("v.value");
            if (selctedValue === "United States" || selctedValue === "Canada") {
                component.set("v.CountryReq", true);
            } else {
                component.set("v.CountryReq", false);
            }
        }
        try {
            var competitorSel =
                leadRecord.Competitors__c != null && true &&
                leadRecord.Competitors__c !== ""
                    ? leadRecord.Competitors__c.toString()
                    : "";
            var stateSelected =
                leadRecord.State__c != null && true && leadRecord.State__c !== ""
                    ? leadRecord.State__c.toString()
                    : "";
            var countrySelcted =
                leadRecord.Country__c != null && true && leadRecord.Country__c !== ""
                    ? leadRecord.Country__c.toString()
                    : "";
            var employeeSelcted =
                leadRecord.NumberOfEmployees__c != null && true &&
                leadRecord.NumberOfEmployees__c !== ""
                    ? leadRecord.NumberOfEmployees__c.toString()
                    : "";

            helper.onChangeBrand(
                component,
                event,
                helper,
                leadRecord.Lead_Brand_Name__c,
                countrySelcted,
                stateSelected,
                competitorSel,
                employeeSelcted
            );
        } catch (e) {
            console.log("error" + e);
        }
    },

    goBackToViewList: function (component, event, helper) {
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            url: window.location.pathname
        });
        urlEvent.fire();
    },

    showSpinner: function (component, event, helper) {
        var spinner = component.find("loadingSpinner");
        $A.util.removeClass(spinner, "slds-hide");
    },

    hideSpinner: function (component, event, helper) {
        var spinner = component.find("loadingSpinner");
        $A.util.addClass(spinner, "slds-hide");
    },

    saveDetails: function (component, event, helper) {
        var leadRecord = component.get("v.leadRecord");
        var action = component.get("c.updateLead");
        action.setParams({
            leadRec: leadRecord
        });
        action.setCallback(this, function (result) {
            var responsedata = result.getReturnValue();
            if ((responsedata = "Success")) {
                component.set("v.ShowEditSection", false);
                component.set("v.ShowComponentButtons", true);
                component.set("v.ShowRecordDetail", true);
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    type: "success",
                    title: component.get("v.translationsMap.Success") + "!",
                    message: component.get("v.translationsMap.Record_has_been_updated_successfully"),
                    mode: "dismissible"
                });
                toastEvent.fire();
            } else {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    type: "error",
                    title: component.get("v.translationsMap.Error"),
                    message: responsedata,
                    mode: "dismissible"
                });
                toastEvent.fire();
            }
        });
        $A.enqueueAction(action);
    },

    convertLead: function (component, event, helper) {
        var l = component.get("v.leadRecord");
        console.log("lead record for convert>" + JSON.stringify("l"));

        var action = component.get("c.convertLeadRecord");
        action.setParams({
            lead: l
        });
        component.set("v.ShowSpinnerLead", true);
        action.setCallback(this, function (result) {
            var state = result.getState();
            console.log("state>" + state);


            if (state === "SUCCESS") {
                var toastEvent = $A.get("e.force:showToast");
                var urlEvent = $A.get("e.force:navigateToURL");
                var responsedata = result.getReturnValue();

                if (responsedata.convertResponse === "Success") {
                    toastEvent.setParams({
                        type: "success",
                        title: component.get("v.translationsMap.Success") + "!",
                        message: component.get("v.translationsMap.Lead_has_been_converted_successfully") + "!",
                        mode: "dismissible"
                    });
                    console.log("redirecting");
                    urlEvent.setParams({
                        url: window.location.pathname
                    });
                } else {
                    component.set("v.ShowSpinnerLead", false);
                    console.log("responsedata.convertResponse" + responsedata.convertResponse);
                    toastEvent.setParams({
                        type: "error",
                        title: "Error",
                        message: responsedata.convertResponse,
                        mode: "dismissible"
                    });
                    urlEvent.setParams({
                        url: window.location.pathname
                    });
                }

                toastEvent.fire();
                urlEvent.fire();
            }
        });
        $A.enqueueAction(action);
    },

    handleSubmit: function (component, event, helper) {
        event.preventDefault();

        var phoneField = component.find("phoneNumber");
        var phoneValue = phoneField.get("v.value");
        var regex1 = new RegExp("^[0-9 ,+()-]*$");
        var isValidPhone = regex1.test(phoneValue);
        var noOfEmp = component.find("selectedEmp").get("v.value");
        var stateVal = component.find("selectedState").get("v.value");
        var countryReq = component.get("v.CountryReq");
        var isAvaya = component.get("v.isAvaya");
        console.log("noOfEmp>>" + noOfEmp);

        var toastEvent = $A.get("e.force:showToast");
        if (phoneValue != null && phoneValue !== "" && !isValidPhone) {
            toastEvent.setParams({
                type: "error",
                title: component.get("v.translationsMap.Error") + "!",
                message: component.get("v.translationsMap.Please_enter_only_numeric_values_Phone") + "!",
                mode: "dismissible"
            });
        } else if (noOfEmp == null || noOfEmp === "" || noOfEmp === "-- None --") {
            toastEvent.setParams({
                type: "error",
                title: component.get("v.translationsMap.Error") + "!",
                message: component.get("v.translationsMap.Please_choose_Number_of_Employees") + "!",
                mode: "dismissible"
            });
        } else if (
            countryReq === true &&
            isAvaya === true &&
            (stateVal == null || stateVal === "" || stateVal === "-- None --")
        ) {
            toastEvent.setParams({
                type: "error",
                title: component.get("v.translationsMap.Error") + "!",
                message: component.get("v.translationsMap.Please_choose_a_State_Province") + "!",
                mode: "dismissible"
            });
        } else {
            var fields = event.getParam("fields");
            fields["City__c"] = fields["City"];
            // Deal country
            fields["Country__c"] = component.find("selectedCountry").get("v.value");

            //Deal State
            var selectCmp = component.find("selectedState");
            if (selectCmp != null && selectCmp.get("v.disabled")) {
                selectCmp.set("v.disabled", false);
                fields["State__c"] = "-- None --";
            } else {
                fields["State__c"] = component.find("selectedState").get("v.value");
            }
            var empCmp = component.find("selectedEmp");
            if (empCmp != null && empCmp.get("v.disabled")) {
                empCmp.set("v.disabled", false);
                fields["NumberOfEmployees__c"] = "-- None --";
            } else {
                fields["NumberOfEmployees__c"] = component.find("selectedEmp").get("v.value");
            }

            console.log("fields['State__c']" + fields["State__c"]);
            console.log("fields['Country__c']" + fields["Country__c"]);
            var valTmp = component.get("v.selectedCompItems").toString().replace(/,/g, ";");

            fields["Competitors__c"] = valTmp;
            if (valTmp === undefined || valTmp === "") {
                toastEvent.setParams({
                    type: "error",
                    title: component.get("v.translationsMap.Error") + "!",
                    message: component.get("v.translationsMap.Please_choose_any_one_Competitor") + "!",
                    mode: "dismissible"
                });
                return;
            }
            //Chosen Avaya CloudOffice Specialist
            var chosenCloudSpecialistValue = component.get("v.cloudSpecialistContactId");
            console.log("chosenCloudSpecialistValue" + chosenCloudSpecialistValue);
            if (
                chosenCloudSpecialistValue != null &&
                chosenCloudSpecialistValue !== ""
            ) {
                fields["Avaya_Cloud_Specialist__c"] = chosenCloudSpecialistValue;
                console.log("chosenCloudSpecialistValue>" + fields["Avaya_Cloud_Specialist__c"]);
            } else {
                fields["Avaya_Cloud_Specialist__c"] = "";
            }
            console.log("chosenCloudSpecialistValue>" + fields["Avaya_Cloud_Specialist__c"]);
            if (component.get("v.ShowOnlyAtos") === true) {
                fields["Lead_Tier_Name__c"] = component.find("tierSelected").get("v.value");
                if (fields["Lead_Tier_Name__c"].includes("RC Meetings")) {
                    fields["Number_of_Users__c"] = "";
                    console.log("Number_of_Users__c" + fields["Number_of_Users__c"]);
                }
                if (fields["Lead_Tier_Name__c"].includes("Office")) {
                    fields["Forecasted_RingCentral_Video_Users__c"] = "";
                    console.log(
                        "Forecasted_RingCentral_Video_Users__c" + fields["Forecasted_RingCentral_Video_Users__c"]
                    );
                }
            }
            component.find("editRecordForm").submit(fields);
        }
        toastEvent.fire();
    },
    onTierChange: function (component, event, helper) {
        console.log("inside tier change");
        console.log("selectedTier : " + component.find("tierSelected").get("v.value"));
        var selectedTier = component.find("tierSelected").get("v.value");
        if (selectedTier === "RC Meetings") component.set("v.RCMeetings", true);
        else component.set("v.RCMeetings", false);
    },

    handleError: function (component, event, helper) {
        var err = event.getParam("error");
        var errStr = JSON.stringify(err);
        var toastEvent = $A.get("e.force:showToast");

        if (errStr.indexOf("Please enter Cloud Specialist Contact Id") !== -1) {
            toastEvent.setParams({
                type: "error",
                title: component.get("v.translationsMap.Error") + "!",
                message: component.get("v.translationsMap.Please_search_and_choose_valid_Cloud_Spe") + "!",
                mode: "dismissible"
            });
        } else {
            toastEvent.setParams({
                type: "error",
                title: component.get("v.translationsMap.Error") + "!",
                message: component.get("v.translationsMap.There_was_some_error_during_processing") + "!",
                mode: "dismissible"
            });
        }
        toastEvent.fire();
    },

    handleSuccessNew: function (component, event, helper) {
        var record = event.getParam("response");

        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            type: "success",
            title: component.get("v.translationsMap.Success") + "!",
            message: component.get("v.translationsMap.The_record_has_been_Saved_successfully"),
            mode: "dismissible"
        });
        toastEvent.fire();
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            url: window.location.pathname + "?id=" + record.id
        });
        urlEvent.fire();
    },

    createAccountLookup: function (component, event, helper) {
        $A.createComponent(
            "c:Partner_LookupSearch",
            { searchPartnerAccount: true },
            function (createPartnerComponent, status, errorMessage) {
                if (status === "SUCCESS") {
                    var lookupDiv = component.find("lookupSearchDiv").get("v.body");
                    lookupDiv.push(createPartnerComponent);
                    component.find("lookupSearchDiv").set("v.body", lookupDiv);
                }
            }
        );
    },

    handlePartnerComponentEvent: function (component, event, helper) {
        var conId = event.getParam("Id");
        var conName = event.getParam("Name");
        var acc = event.getParam("PartnerAccount");
        if (acc === true) {
            component.set("v.selectedValue", conId);
            component.set("v.partnerAccountName", conName);
            var pageNumber = component.get("v.pageNumber");
            var pageSize = component.find("pageSize").get("v.value");
            helper.getLeadList(component, event, helper, pageNumber, pageSize);
        }
    },

    toggleFilterBy: function (component, event, helper) {
        var isViewAll = component.find("filterType").get("v.checked");
        component.set("v.viewAll", isViewAll);
        if (isViewAll) {
            var pageNumber = 1;
            var pageSize = 50;
            helper.getDataForViewAll(component, helper, pageNumber, pageSize);
        } else {
            var pageNumber = 1;
            var pageSize = 50;
            helper.getLeadList(component, event, helper, pageNumber, pageSize);
        }
    },

    doFilterSearch: function (component, event, helper) {
        var isShowConAcc = component.get("v.ShowConAcc");
        var isViewAll = false;
        if (isShowConAcc) {
            isViewAll = component.find("filterType").get("v.checked");
        }
        if (isViewAll) {
            var pageNumber = 1;
            var pageSize = component.find("pageSizeForAll").get("v.value");
            helper.getDataForViewAll(component, helper, pageNumber, pageSize);
        } else {
            var pageNumber = component.get("v.pageNumber");
            var pageSize = component.find("pageSize").get("v.value");
            pageNumber = 1;
            helper.getLeadList(component, event, helper, pageNumber, pageSize);
        }
    },

    requestLeadConversion: function (component, event, helper) {
        var leadId = component.get("v.recordID");

        if (helper.isLeadHasDuplicates(component, event, helper)) {
            $A.get("e.c:ModalRequestEvent").setParams({
                header: 'Lead cannot be converted',
                content: 'The lead you are trying to convert has duplicates. This will require assistance from the IPA team. Please click ‘Request lead conversion’ to proceed with submitting the request to the IPA team.',
                buttons: [{
                    label: 'Request lead conversion',
                    variant: 'brand',
                    callback: function() {
                        $A.enqueueAction(helper.actionRequestToConvertLead(component, event, helper, leadId));
                    }
                }]
            }).fire();
        } else {
            if (helper.isIgniteFlowEnabled(component, event, helper)) {
                $A.get("e.force:navigateToURL").setParams({
                    url: "/partner-convert-lead?recordId=" + leadId
                }).fire();
            } else {
                $A.enqueueAction(helper.actionRequestToConvertLead(component, event, helper, leadId));
            }
        }
    },

    onchangeCountry: function (component, event, helper) {
        var mapCountryStates = component.get("v.mapData");
        var selctedValue = event.getSource().get("v.value");
        if (selctedValue === "United States" || selctedValue === "Canada") {
            component.set("v.CountryReq", true);
        } else {
            component.set("v.CountryReq", false);
        }
        helper.onchangeCountry(component, event, helper, selctedValue);
    },

    handleChange: function (cmp, event) {
        var selectedCompOption = event.getParam("value");
        cmp.set("v.selectedCompItems", selectedCompOption);
    },

    handleCloudSpecialistEvent: function (component, event, helper) {
        console.log("inside cloudspe event set");
        var cloudSpecialistContactId = event.getParam("cloudSpecialistContactId");
        var cloudSpecialistContactName = event.getParam("cloudSpecialistContactName");
        console.log("cloudSpecialistContactId" + cloudSpecialistContactId);
        console.log("cloudSpecialistContactName" + cloudSpecialistContactName);
        component.set("v.cloudSpecialistContactId", cloudSpecialistContactId);
    }
});