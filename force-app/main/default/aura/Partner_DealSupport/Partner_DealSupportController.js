({//Method to execute on load
    doInit: function (component, event, helper) {
        try {
            console.log('inside init');
            var url = new URL(location.href);
            component.set('v.RespectiveTabURL', url);
            var id = url.searchParams.get('id');
            if (id != null && id != undefined && id != '') {
                component.set("v.recordID", id);
                component.set("v.ShowListView", false);
                component.set("v.ShowRecordDetail", true);
                $A.createComponent("c:Partner_DealSupportDetail", { "recordID": id },
                    function (createComp, status, errorMessage) {
                        if (status === "SUCCESS") {
                            var selDealDiv = component.find('dealSupportDetailDiv').get('v.body');
                            selDealDiv.push(createComp);
                            component.find('dealSupportDetailDiv').set('v.body', selDealDiv);
                        }
                    });
            } else {
                component.set("v.isClosedStsIncluded", true);
                helper.getPartnerAccountList(component, event, helper);
            }
            helper.getTranslations(component, event, helper);
        }
        catch (e) {
            console.log(e);
        }
    },

    toggleFilterBy: function (component, event, helper) {
        var isShowConAcc = component.get("v.ShowConAcc");
        if (isShowConAcc) {
            var isViewAll = component.find("filterType").get("v.checked");
            component.set("v.viewAll", isViewAll);
            if (isViewAll) {
                var pageNumber = 1;
                var pageSize = 50;
                pageSize = component.find("pageSizeForAll").get("v.value");
                component.set("v.ShowSpinnerDeal", true);
                helper.getDataForViewAll(component, helper, pageNumber, pageSize);
            }
            else {
                var pageNumber = 1;
                var pageSize = 50;
                pageSize = component.find("pageSize").get("v.value");
                helper.getDealSupportList(component, pageNumber, pageSize);
            }
        } else {
            var pageNumber = 1;
            var pageSize = component.find("pageSize").get("v.value");
            helper.getDealSupportList(component, pageNumber, pageSize);
        }
    },

    doFilter: function (component, event, helper) {
        var isShowConAcc = component.get("v.ShowConAcc");
        var isViewAll = false;
        if (isShowConAcc) {
            isViewAll = component.find("filterType").get("v.checked");
        }
        component.set("v.isClosedStsIncluded", true);
        if (isViewAll) {
            var pageNumber = 1;
            var pageSize = component.find("pageSizeForAll").get("v.value");
            console.log('inside viewall');
            helper.getDataForViewAll(component, helper, pageNumber, pageSize);
        } else {
            var pageNumber = 1;
            var pageSize = component.find("pageSize").get("v.value");
            console.log('inside getlist');
            helper.getDealSupportList(component, pageNumber, pageSize);
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
        }
        else {
            var pageNumber = 1;
            var pageSize = component.find("pageSize").get("v.value");
            helper.getDealSupportList(component, pageNumber, pageSize);
        }
        /*var pageNumber = 1;
        var pageSize = component.find("pageSize").get("v.value");        
        helper.getDealSupportList(component,pageNumber,pageSize);*/
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
        }
        else {
            var pageSize = component.find("pageSize").get("v.value");
            pageNumber++;
            helper.getDealSupportList(component, pageNumber, pageSize);
        }
        /* var pageSize = component.find("pageSize").get("v.value");
        pageNumber++;
        helper.getDealSupportList(component,pageNumber,pageSize);*/
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
        }
        else {
            var pageSize = component.find("pageSize").get("v.value");
            pageNumber--;
            helper.getDealSupportList(component, pageNumber, pageSize);
        }
        /*var pageSize = component.find("pageSize").get("v.value");
        pageNumber--;
        helper.getDealSupportList(component,pageNumber,pageSize);*/
    },

    showNewSectionArea: function (component, event, helper) {
        component.set("v.ShowRecordDetail", false);
        component.set("v.ShowListView", false);
        component.set("v.ShowNewSection", true);
        $A.createComponent("c:Partner_DealSupportNew", {
            "translationsMap": component.get("v.translationsMap")
        },
            function (createComp, status, errorMessage) {
                if (status === "SUCCESS") {
                    var selNewDealDiv = component.find('NewDealSupportDiv').get('v.body');
                    selNewDealDiv.push(createComp);
                    component.find('NewDealSupportDiv').set('v.body', selNewDealDiv);
                }
            });
    },
    handleGoBackComponentEvent: function (component, event, helper) {
        var message = event.getParam("goBack");
        if (message == true) {
            component.set("v.ShowRecordDetail", false);
            component.set("v.ShowListView", true);
            var pageNumber = 1;
            var pageSize = 50;
            helper.getDealSupportList(component, pageNumber, pageSize);
        }
    },
    handleNewCancel: function (component, event, helper) {
        var message = event.getParam("goBack");
        if (message == true) {
            component.set("v.ShowRecordDetail", false);
            component.set("v.ShowNewSection", false);
            component.set("v.ShowListView", true);
        }
    },
    showSpinner: function (component, event, helper) {
        var spinner = component.find("loadingSpinner");
        $A.util.removeClass(spinner, "slds-hide");
        console.log('loading');
    },
    hideSpinner: function (component, event, helper) {
        /*window.setTimeout(
        $A.getCallback(function() {*/
        var spinner = component.find("loadingSpinner");
        $A.util.addClass(spinner, "slds-hide");
        console.log('loaded');
        /* }), 3000
        );*/
    },
    createAccountLookup: function (component, event, helper) {
        $A.createComponent("c:Partner_LookupSearch", { "searchPartnerAccount": true },
            function (createPartnerComponent, status, errorMessage) {
                if (status === "SUCCESS") {
                    var lookupDiv = component.find('lookupSearchDiv').get('v.body');
                    lookupDiv.push(createPartnerComponent);
                    component.find('lookupSearchDiv').set('v.body', lookupDiv);
                }
            }
        );
    },
    handlePartnerComponentEvent: function (component, event, helper) {
        var conId = event.getParam("Id");
        var conName = event.getParam("Name");
        var acc = event.getParam("PartnerAccount");
        if (acc == true) {
            component.set('v.selectedValue', conId);
            component.set('v.partnerAccountName', conName);
            var pageNumber = component.get("v.pageNumber");
            var pageSize = component.find("pageSize").get("v.value");
            helper.getDealSupportList(component, pageNumber, pageSize);
        }
    },

})