({
    //Get list of Opportunities
    getDealSupportList: function (component, pgnmbr, pgsize) {
        console.log('inside ds list');
        var val = component.get("v.selectedValue");
        var statusval = component.get("v.selectedStatusValue");
        var typeval = component.get("v.selectedTypeValue");
        var isLegalEscalated = false;
        var isAvayaEscalated = false;
        var showOnlyRC = component.get("v.ShowOnlyRC");
        if (showOnlyRC == false) {
            if (typeval == 'Any' || typeval == 'New Contract Request') {
                component.set("v.showLegalToggle", true);
                if (component.get("v.escalatedToLegal") == true) {
                    isLegalEscalated = true;
                }
            }
            if (typeval == 'Any' || typeval == 'Discount Request') {
                if (component.get("v.escalatedToAvayaDealDesk") == true) {
                    isAvayaEscalated = true;
                    component.set("v.showLegalToggle", false);
                }
                else {
                    component.set("v.showLegalToggle", true);
                }
            } else {
                var isShowConAcc = component.get("v.ShowConAcc");
                if (isShowConAcc) {
                    component.set("v.showLegalToggle", true);
                    var isSalesOverlay = component.find("filterTypeOwner").get("v.checked");
                    if (isSalesOverlay != undefined || isSalesOverlay != '')
                        component.set("v.salesOverlay", isSalesOverlay);
                    console.log('isSalesOverlay' + isSalesOverlay);
                }
            }
        }
        var action = component.get("c.getDealSupportDataController");
        action.setParams({
            "selectedPartnerAccount": val,
            "selectedSupportStatus": statusval,
            "selectedType": typeval,
            "pageNumber": pgnmbr,
            "pageSize": pgsize,
            'searchKeyWord': component.get("v.searchKeyword"),
            'searchBy': component.get("v.searchBy"),
            "isSalesOverlay": component.get("v.salesOverlay"),
            "isEscalated": isLegalEscalated,
            "isClosedStsIncluded": component.get("v.isClosedStsIncluded"),
            "isAvayaEscalated": isAvayaEscalated,
            "includeRecordsRoutedToDD": component.get("v.includeRecordsRoutedToDD")
        });
        action.setCallback(this, function (result) {
            var state = result.getState();
            console.log('state' + state);
            try {
                if (component.isValid() && state === "SUCCESS") {
                    console.log('57+++')
                    var resultData = result.getReturnValue();
                    if (resultData.dealSupportList != undefined && resultData.dealSupportList != '') {
                        component.set("v.Message", false);
                        resultData.dealSupportList.forEach(function (record) {
                            record.Name = record.Name;
                        });
                        for (var i = 0; i < resultData.dealSupportList.length; i++) {
                            console.log('i+++' + i)
                            var row = resultData.dealSupportList[i];
                            component.set("v.recordID", resultData.dealSupportList[0].Id);

                            if (row.Partner_Account__c == null) {
                                row.PartnerAccount = ' ';
                                row.PartnerId = ' ';
                            }
                            else {
                                row.PartnerAccount = row.Partner_Account__r.Name;
                                row.PartnerId = row.Partner_Account__r.Partner_ID__c;
                            }

                            if (row.Partner_Contact__c == undefined) {
                                row.PartnerContact = ' ';
                            }
                            else {
                                if (row.Partner_Contact__r.FirstName == undefined)
                                    row.Partner_Contact__r.FirstName = '';
                                if (row.Partner_Contact__r.LastName == undefined)
                                    row.Partner_Contact__r.LastName = '';
                                row.PartnerContact = row.Partner_Contact__r.FirstName + row.Partner_Contact__r.LastName;
                            }
                            if (row.Partner_Quote__c == null) {
                                row.PartnerQuote = ' ';
                            }
                            else {
                                row.PartnerQuote = row.Partner_Quote__r.Name;
                            }
                            if (row.Customer_Account__c == null) {
                                row.CustomerAccount = ' ';
                            }
                            else {
                                row.CustomerAccount = row.Customer_Account__r.Name;
                            }
                            if (row.Portal_Cloud_Specialist__c != undefined && row.Portal_Cloud_Specialist__c != '') {
                                if (row.Opportunity__c != undefined && row.Opportunity__c != '') {
                                    if (row.Opportunity__r.Portal_Cloud_Specialist__c == undefined || row.Opportunity__r.Portal_Cloud_Specialist__c == '' || row.Opportunity__r.Portal_Cloud_Specialist__c == null)
                                        row.PortalCloudSpecialist = ' ';
                                    else
                                        row.PortalCloudSpecialist = row.Opportunity__r.Portal_Cloud_Specialist__r.Name;
                                }
                                else if (row.Lead__c != undefined && row.Lead__c != '' && row.Lead__r != null) {
                                    if (row.Lead__r.Portal_Cloud_Specialist__c == undefined || row.Lead__r.Portal_Cloud_Specialist__c == '' || row.Lead__r.Portal_Cloud_Specialist__c == null)
                                        row.PortalCloudSpecialist = ' ';
                                    else
                                        row.PortalCloudSpecialist = row.Lead__r.Portal_Cloud_Specialist__r.Name;
                                } else {
                                    row.PortalCloudSpecialist = ' ';
                                }

                            } else {
                                row.PortalCloudSpecialist = ' ';
                            }
                        }
                        component.set("v.dealSupportList", resultData.dealSupportList);
                    }
                    component.set("v.pageNumber", resultData.pageNumber);
                    component.set("v.totalRecords", resultData.totalRecords);
                    component.set("v.recordStart", resultData.recordStart);
                    component.set("v.recordEnd", resultData.recordEnd);
                    component.set("v.totalPages", Math.ceil(resultData.totalRecords / pgsize));
                    if (resultData.dealSupportList == undefined || resultData.dealSupportList == '') {
                        component.set("v.Message", true);
                        component.set("v.ShowSpinnerDeal", false);
                    } else {
                        component.set("v.Message", false);
                    }
                    console.log('If done+++')
                }
            } catch (e) {
                console.log(e);
            }
        });
        $A.enqueueAction(action);
    },
    //Get partner account list
    getPartnerAccountList: function (component, event, helper) {
        var action = component.get("c.getAccountList");
        action.setParams({
        });
        action.setCallback(this, function (result) {
            var state = result.getState();
            console.log('state>' + state);
            if (component.isValid() && state === "SUCCESS") {
                var resultData = result.getReturnValue();
                component.set("v.isReadOnly", resultData.isReadOnly);

                component.set("v.communityDetailsRecord", resultData.communityDetailsRecord);

                if (resultData.listPartnerAccounts == undefined || resultData.listPartnerAccounts == '') {
                    component.set("v.Message", true);
                    component.set('v.ShowSpinnerDeal', false);
                } else {
                    component.set("v.Message", false);

                }
                if (resultData.listPartnerAccounts != undefined && resultData.listPartnerAccounts.length > 0) {
                    component.set("v.selectedValue", resultData.listPartnerAccounts[0].Id);
                    component.set("v.partnerAccounts", resultData.listPartnerAccounts);
                    component.set("v.partnerAccountName", resultData.listPartnerAccounts[0].Name);

                    component.set("v.accountId", resultData.listPartnerAccounts[0].Id);
                    component.set("v.ShowConAcc", resultData.isAvaya);
                    console.log('isavaya>' + component.get("v.ShowConAcc"));
                    component.set("v.partnerCommunity", resultData.partnerCommunityName);
                    var masterLabel = component.get("v.communityDetailsRecord").MasterLabel;
                    console.log('ShowOnlyRC '+masterLabel);
                    if (resultData.partnerCommunityName.includes('RingCentral')&& masterLabel=='ignite')
                        component.set("v.ShowOnlyRC", true);
                    //Added by Yuvaana for ProServ
                    if (resultData.partnerCommunityName.includes('Avaya Cloud Office'))
                        component.set("v.ShowOnlyAvaya", true);
                    if (resultData.partnerCommunityName.includes('Rainbow Office'))
                        component.set("v.ShowOnlyALE", true);
                    console.log('ShowOnlyALE>' + component.get("v.ShowOnlyALE"));
                    if (resultData.isAvaya == true)
                        component.set("v.viewAll", true);

                }
                //Added by Saradha for pagination
                if (resultData.isAvaya == true || resultData.isMaster == true) {
                    component.set("v.viewAll", true);
                    var pageNumber = 1;
                    var pageSize = 50;
                    this.getDataForViewAll(component, helper, pageNumber, pageSize);
                } else {
                    var pageNumber = 1;
                    var pageSize = 50;
                    this.getDealSupportList(component, pageNumber, pageSize)
                    // this.getDataForViewAll(component,helper,pageNumber,pageSize);
                }
                component.set("v.isSingleLogin", resultData.isSingleLogin);
                console.log('isSingleLogin??' + component.get('v.isSingleLogin'));
            }
        });

        $A.enqueueAction(action);
    },

    //TranslationStart
    getTranslations: function (component, event, helper) {
        try {
            var action = component.get("c.getTranslations");
            action.setParams({
                "objNames": 'Deal_Support__c'
            });
            action.setCallback(this, function (result) {
                var state = result.getState();
                if (component.isValid() && state === "SUCCESS") {
                    console.log('AllObjFields-' + JSON.stringify(result.getReturnValue()));
                    var resultData = result.getReturnValue();
                    if (resultData != undefined && resultData != null && resultData != '') {
                        if (resultData.allObjFieldsMap != undefined && resultData.allObjFieldsMap != null &&
                            resultData.allObjFieldsMap != '') {
                            component.set("v.dealSupportFieldsMap", resultData.allObjFieldsMap.Deal_Support__c);
                        }
                        component.set("v.translationsMap", resultData.prmLabelsMap);
                        component.set("v.PRMSpecificTranslationsMap", resultData.prmSpecificLabelsMap);
                    }
                }
            });
            $A.enqueueAction(action);
        }
        catch (e) {
            console.log('err - ' + e);
        }
    },
    //TranslationEnd
    //METHOD TO GET All Data for View All
    getDataForViewAll: function (component, helper, pageNumber, pageSize) {
        console.log('inside view all');
        var statusval = component.get("v.selectedStatusValue");
        var typeval = component.get("v.selectedTypeValue");
        var isLegalEscalated = false;
        var isAvayaEscalated = false;
        console.log('typeval' + typeval);
        console.log('statusval' + statusval);
        var showOnlyRC = component.get("v.ShowOnlyRC");
        console.log('ShowOnlyRC '+showOnlyRC);
        if (showOnlyRC == false) {
            if (typeval == 'Any' || typeval == 'New Contract Request') {
                component.set("v.showLegalToggle", true);
                if (component.get("v.escalatedToLegal") == true) {
                    isLegalEscalated = true;

                }
            }
            if (typeval == 'Any' || typeval == 'Discount Request') {
                if (component.get("v.escalatedToAvayaDealDesk") == true) {
                    isAvayaEscalated = true;
                    component.set("v.showLegalToggle", false);
                }
                else {
                    component.set("v.showLegalToggle", true);
                }
            } else {
                var isShowConAcc = component.get("v.ShowConAcc");
                if (isShowConAcc) {
                    component.set("v.showLegalToggle", true);
                    var isSalesOverlay = component.find("filterTypeOwner").get("v.checked");
                    if (isSalesOverlay != undefined || isSalesOverlay != '')
                        component.set("v.salesOverlay", isSalesOverlay);
                    console.log('isSalesOverlay' + isSalesOverlay);
                }
            }
        }
        var action = component.get("c.getDataForViewAll");
        action.setParams({
            "selectedSupportStatus": statusval,
            "selectedType": typeval,
            "pageNumber": pageNumber,
            "pageSize": pageSize,
            'searchKeyWord': component.get("v.searchKeyword"),
            'searchBy': component.get("v.searchBy"),
            "isSalesOverlay": component.get("v.salesOverlay"),
            "isEscalated": isLegalEscalated,
            "isClosedStsIncluded": component.get("v.isClosedStsIncluded"),
            "isAvayaEscalated": isAvayaEscalated,
            "includeRecordsRoutedToDD": component.get("v.includeRecordsRoutedToDD")
        });
        /*action.setCallback(this, function(result) {     
            var state = result.getState();
            console.log('state'+state);
            if (component.isValid() && state === "SUCCESS"){
                var resultData = result.getReturnValue();
                if(resultData.dealSupportList != undefined && resultData.dealSupportList !='')
                {
                    component.set("v.Message", false);
                    resultData.dealSupportList.forEach(function(record, index){
                        record.Name =record.Name;
                        console.log('rec -- '+ index +'  ' + record.Id + ' ' + record.Name);
                    });
                    console.log('lenght++'+resultData.dealSupportList.length)
                    for (var i = 0; i < resultData.dealSupportList.length; i++) { 
                        console.log('i++++'+i)
                        var row = resultData.dealSupportList[i]; 
                        
                        if(row.Partner_Account__c==undefined){
                            row.PartnerAccount = ' ';
                            row.PartnerId = ' ';
                        }
                        else{
                            row.PartnerAccount = row.Partner_Account__r.Name;
                            row.PartnerId = row.Partner_Account__r.Partner_ID__c;
                        } 
                        
                        if(row.Partner_Contact__c==undefined){
                            row.PartnerContact = ' ';
                        }
                        else{
                            if(row.Partner_Contact__r.FirstName==undefined)
                                row.Partner_Contact__r.FirstName ='';
                            if(row.Partner_Contact__r.LastName==undefined)
                                row.Partner_Contact__r.LastName ='';
                            row.PartnerContact = row.Partner_Contact__r.FirstName+row.Partner_Contact__r.LastName;
                        }        
                        //console.log('row.Partner_Quote__c -- '+row.Partner_Quote__c);
                        if(row.Partner_Quote__c==undefined){
                            row.PartnerQuote = ' ';
                        }
                        else{
                            //console.log('Partner_Quote__r.Id -- '+row.Partner_Quote__r.Id);
                            //console.log('Partner_Quote__r.Name -- '+row.Partner_Quote__r.Name);
                            row.PartnerQuote = row.Partner_Quote__r.Name;
                        }  
                        //console.log('row.Customer_Account__c -- '+row.Customer_Account__c);
                        if(row.Customer_Account__c == undefined){
                            row.CustomerAccount = ' ';
                        }
                        else{
                            //console.log('row.Customer_Account__r.Name -- '+row.Customer_Account__r.Name);
                            row.CustomerAccount = row.Customer_Account__r.Name;
                        }  
                        //console.log('row.Opportunity__c -- '+row.Opportunity__c);
                        //console.log('row.Lead__c -- '+row.Lead__c);
                         if(row.Portal_Cloud_Specialist__c !=undefined){
                             if(row.Opportunity__c!=undefined){
                                if(row.Opportunity__r.Portal_Cloud_Specialist__c == undefined || row.Opportunity__r.Portal_Cloud_Specialist__c == '' ||row.Opportunity__r.Portal_Cloud_Specialist__c == null)
                                    row.PortalCloudSpecialist = ' ';
                                else
                                    row.PortalCloudSpecialist = row.Opportunity__r.Portal_Cloud_Specialist__r.Name;
                            }
                            else if(row.Lead__c!=undefined){
                                if(row.Lead__r.Portal_Cloud_Specialist__c == undefined || row.Lead__r.Portal_Cloud_Specialist__c == '' ||row.Lead__r.Portal_Cloud_Specialist__c == null)
                                    row.PortalCloudSpecialist = ' ';
                                else
                                    row.PortalCloudSpecialist = row.Lead__r.Portal_Cloud_Specialist__r.Name;
                            }else{
                                  row.PortalCloudSpecialist = ' ';
                            }
                            
                        }else{
                            row.PortalCloudSpecialist = ' ';
                        }
                    }
                    console.log('s');
                    component.set("v.dealSupportList", resultData.dealSupportList);
                    
                }  
                console.log('s');
                component.set("v.pageNumber", resultData.pageNumber);
                component.set("v.totalRecords", resultData.totalRecords);
                component.set("v.recordStart", resultData.recordStart);
                component.set("v.recordEnd", resultData.recordEnd);
                component.set("v.totalPages", Math.ceil(resultData.totalRecords / pageSize));
                if(resultData.dealSupportList == undefined || resultData.dealSupportList ==''){
                    component.set("v.Message", true);
                    component.set("v.ShowSpinnerDeal", false);
                    
                } else {
                    component.set("v.Message", false);
                } 
                
            }
        });    */
        action.setCallback(this, function (result) {
            var state = result.getState();
            console.log('state' + state);
            if (component.isValid() && state === "SUCCESS") {
                var resultData = result.getReturnValue();
                if (resultData.dealSupportList != undefined && resultData.dealSupportList != '') {
                    component.set("v.Message", false);
                    resultData.dealSupportList.forEach(function (record) {
                        record.Name = record.Name;
                    });
                    console.log('lenght++' + resultData.dealSupportList.length)
                    for (var i = 0; i < resultData.dealSupportList.length; i++) {
                        console.log('i++++' + i)
                        var row = resultData.dealSupportList[i];

                        if (row.Partner_Account__c == null) {
                            row.PartnerAccount = ' ';
                            row.PartnerId = ' ';
                        }
                        else {
                            row.PartnerAccount = row.Partner_Account__r.Name;
                            row.PartnerId = row.Partner_Account__r.Partner_ID__c;
                        }

                        if (row.Partner_Contact__c == undefined) {
                            row.PartnerContact = ' ';
                        }
                        else {
                            if (row.Partner_Contact__r.FirstName == undefined)
                                row.Partner_Contact__r.FirstName = '';
                            if (row.Partner_Contact__r.LastName == undefined)
                                row.Partner_Contact__r.LastName = '';
                            row.PartnerContact = row.Partner_Contact__r.FirstName + row.Partner_Contact__r.LastName;
                        }
                        if (row.Partner_Quote__c == null) {
                            row.PartnerQuote = ' ';
                        }
                        else {
                            row.PartnerQuote = row.Partner_Quote__r.Name;
                        }
                        if (row.Customer_Account__c == null) {
                            row.CustomerAccount = ' ';
                        }
                        else {
                            row.CustomerAccount = row.Customer_Account__r.Name;
                        }
                        if (row.Portal_Cloud_Specialist__c != undefined && row.Portal_Cloud_Specialist__c != '') {
                            if (row.Opportunity__c != undefined && row.Opportunity__c != '') {
                                if (row.Opportunity__r.Portal_Cloud_Specialist__c == undefined || row.Opportunity__r.Portal_Cloud_Specialist__c == '' || row.Opportunity__r.Portal_Cloud_Specialist__c == null)
                                    row.PortalCloudSpecialist = ' ';
                                else
                                    row.PortalCloudSpecialist = row.Opportunity__r.Portal_Cloud_Specialist__r.Name;
                            }
                            else if (row.Lead__c != undefined && row.Lead__c != '') {
                                if (row.Lead__r.Portal_Cloud_Specialist__c == undefined || row.Lead__r.Portal_Cloud_Specialist__c == '' || row.Lead__r.Portal_Cloud_Specialist__c == null)
                                    row.PortalCloudSpecialist = ' ';
                                else
                                    row.PortalCloudSpecialist = row.Lead__r.Portal_Cloud_Specialist__r.Name;
                            } else {
                                row.PortalCloudSpecialist = ' ';
                            }

                        } else {
                            row.PortalCloudSpecialist = ' ';
                        }
                    }
                    component.set("v.dealSupportList", resultData.dealSupportList);

                }
                component.set("v.pageNumber", resultData.pageNumber);
                component.set("v.totalRecords", resultData.totalRecords);
                component.set("v.recordStart", resultData.recordStart);
                component.set("v.recordEnd", resultData.recordEnd);
                component.set("v.totalPages", Math.ceil(resultData.totalRecords / pageSize));
                if (resultData.dealSupportList == undefined || resultData.dealSupportList == '') {
                    component.set("v.Message", true);
                    component.set("v.ShowSpinnerDeal", false);

                } else {
                    component.set("v.Message", false);
                }

            }
        });
        $A.enqueueAction(action);
    },


})