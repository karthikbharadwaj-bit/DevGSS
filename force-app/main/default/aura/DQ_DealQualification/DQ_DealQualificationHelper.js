({
    CheckIdDQExists: function (component, event, helper, isFromSubmit) {
        console.log('from aura helper'+component.get("v.oppId"));
        const isQuoteWizard = component.get("v.isFromQuoteWizard");
        var url = new URL(location.href);
        //console.log('fromurl'+url.searchParams.get("oppId"));
        //console.log('fromurl'+component.get("v.isFromQuoteWizard"));
        var opid=component.get("v.oppId");
        var id = !isQuoteWizard
        ? url.searchParams.get("oppId")
        : component.get("v.oppId");
        console.log('from aura helper--->'+id);
        if(id==null)
        {
            id=component.get("v.oppId");
           /* console.log('id before'+id);
           id= id.replace("&newTab=1", "");
           console.log('id after'+id);*/

        }
        if (id) {
            console.log('from if'+opid);
            var serverAction = component.get("c.checkDQExistFOROpp");
            serverAction.setParams({
                OppId: id
            });

            serverAction.setCallback(this, function (response) {
                console.log('from action method'+response.getState());
                if (response.getState() == "SUCCESS") {
                    var objDealQualificationWRAP = response.getReturnValue();
                    if (objDealQualificationWRAP) {
                        const dqStatus =
                            objDealQualificationWRAP.DQRec.Status__c;
                        objDealQualificationWRAP.DQRec.Opportunity__c = id;
                        component.set(
                            "v.objDealQualification",
                            objDealQualificationWRAP.DQRec
                        );
                        component.set("v.ShowBackButton",objDealQualificationWRAP.DQRec.IsDQCreatedFromCPQOpp__c);
                        component.set("v.DQTrueUpDateList",objDealQualificationWRAP.DQTrueUpDateList);
                        if (
                            dqStatus == "Pending Approval" ||
                            dqStatus == "Approved"
                        ) {
                            component.set("v.isReadOnly", true);
                        } else {
                            component.set("v.isReadOnly", false);
                        }

                        const justification =
                            objDealQualificationWRAP.DQRec
                        .Justification_Description__c;
                        if (
                            $A.util.isUndefinedOrNull(justification) ||
                            $A.util.isEmpty(justification)
                        ) {
                            component.set("v.isValidDetails", false);
                        } else {
                            component.set("v.isValidDetails", true);
                        }

                        if (
                            !$A.util.isUndefinedOrNull(
                                objDealQualificationWRAP.DQDiscountList
                            )
                        ) {
                            const objectOrignalKeys = [
                                "Promo_Code__c",
                                "Product__c",
                                "Quantity__c",
                                "Product_Category__c",
                                "Product_Sub_Categories__c",
                                "Discount_Type__c",
                                "Discount__c",
                                "Product_Family__c"
                            ];
                            const dqDiscountList = objDealQualificationWRAP.DQDiscountList.map(
                                function (discount) {
                                    const objectKeys = Object.keys(discount);
                                    let unique1 = objectOrignalKeys.filter(
                                        (o) => objectKeys.indexOf(o) === -1
                                    );
                                    let missingValue = {};
                                    unique1.forEach(function (key) {
                                        missingValue[key] = "";
                                    });
                                    return Object.assign(
                                        {},
                                        discount,
                                        missingValue
                                    );
                                }
                            );
                            component.set("v.DQDiscountList", dqDiscountList);
                        }

                        //contact center
                        if(objDealQualificationWRAP.DQDiscountContactCenterList) {
                            component.set(
                                "v.DQDiscountContactCenterList",
                                objDealQualificationWRAP.DQDiscountContactCenterList
                            );
                        }
                        //contact center
                        if(objDealQualificationWRAP.ProductCategoriesContactMap) {
                            var picklistMap = helper.getPicklistMap(
                                component,
                                event,
                                helper,
                                objDealQualificationWRAP.ProductCategoriesContactMap
                            );
                            component.set("v.ProductCategoriesContactMap", picklistMap);
                        }

                        //Sales Quote
                        if(objDealQualificationWRAP.DQDiscountSalesQuoteList) {
                            component.set(
                                "v.DQDiscountSalesQuoteList",
                                objDealQualificationWRAP.DQDiscountSalesQuoteList
                            );
                        }
                        //Sales Quote
                        if(objDealQualificationWRAP.ProductCategoriesSalesMap) {
                            var picklistMap = helper.getPicklistMap(
                                component,
                                event,
                                helper,
                                objDealQualificationWRAP.ProductCategoriesSalesMap
                            );
                            component.set("v.ProductCategoriesSalesMap", picklistMap);

                        }
                        component.set(
                            "v.objDealQualificationWrap",
                            objDealQualificationWRAP
                        );
                        component.set(
                            "v.DQQuoteList",
                            objDealQualificationWRAP.quoteList
                        );
                        component.set(
                            "v.DQApproverList",
                            objDealQualificationWRAP.ApproverDetailList
                        );
                        if (
                            !$A.util.isUndefinedOrNull(
                                objDealQualificationWRAP.approverList
                            )
                        ) {
                            component.set(
                                "v.approverList",
                                objDealQualificationWRAP.approverList
                            );
                            component.set(
                                "v.highestStepOrderNumber",
                                objDealQualificationWRAP.highestStepNumber
                            );
                        }

                        if (
                            objDealQualificationWRAP.DQDiscountList &&
                            objDealQualificationWRAP.DQDiscountList.length >
                            0 &&
                            objDealQualificationWRAP.DQDiscountList[0].Id !=
                            null
                        ) {
                            component.set(
                                "v.CatagoriesVsSubCatPicklistMap",
                                objDealQualificationWRAP.dependentPicklist
                            );
                        }
                        if (objDealQualificationWRAP.RegionPicklistValueMap) {
                            var picklistMap = helper.getPicklistMap(
                                component,
                                event,
                                helper,
                                objDealQualificationWRAP.RegionPicklistValueMap
                            );
                            component.set("v.regionPicklistMap", picklistMap);
                        }
                        if (objDealQualificationWRAP.SegmentPicklistValueMap) {
                            var picklistMap = helper.getPicklistMap(
                                component,
                                event,
                                helper,
                                objDealQualificationWRAP.SegmentPicklistValueMap
                            );
                            component.set("v.segmentPicklistMap", picklistMap);
                        }

                        if (objDealQualificationWRAP.ProductCategoriesMap) {
                            var picklistMap = helper.getPicklistMap(
                                component,
                                event,
                                helper,
                                objDealQualificationWRAP.ProductCategoriesMap
                            );
                            component.set("v.prodCatPicklistMap", picklistMap);
                        }
                        if (
                            !$A.util.isUndefinedOrNull(
                                objDealQualificationWRAP.ProductFamilyMap
                            )
                        ) {
                            var picklistMap = helper.getPicklistMap(
                                component,
                                event,
                                helper,
                                objDealQualificationWRAP.ProductFamilyMap
                            );
                            component.set(
                                "v.prodFamilyPicklistMap",
                                picklistMap
                            );
                        }

                        if (!$A.util.isUndefinedOrNull(objDealQualificationWRAP.specialTermsPicklistValueMap)) {
                            const picklistMap = helper.getPicklistMap(
                                component, event, helper, objDealQualificationWRAP.specialTermsPicklistValueMap
                            );
                            component.set("v.specialTermsPicklistMap", picklistMap);
                        }
                        if (!$A.util.isUndefinedOrNull(objDealQualificationWRAP.freeShippingTermsPicklistValueMap)) {
                            const picklistMap = helper.getPicklistMap(
                                component, event, helper, objDealQualificationWRAP.freeShippingTermsPicklistValueMap
                            );
                            component.set("v.freeShippingTermsPicklistMap", picklistMap);
                        }

                        if (objDealQualificationWRAP.ProductSubCategoriesMap) {
                            var picklistMap = helper.getPicklistMap(
                                component,
                                event,
                                helper,
                                objDealQualificationWRAP.ProductSubCategoriesMap
                            );
                            component.set(
                                "v.prodSubCatPicklistMap",
                                picklistMap
                            );
                        }
                        if (objDealQualificationWRAP.dealTypePicklistValueMap) {
                            var picklistMap = helper.getPicklistMap(
                                component,
                                event,
                                helper,
                                objDealQualificationWRAP.dealTypePicklistValueMap
                            );
                            component.set("v.dealTypePicklistMap", picklistMap);
                        }
                        if (objDealQualificationWRAP.brandPicklistValueMap) {
                            var picklistMap = helper.getPicklistMap(
                                component,
                                event,
                                helper,
                                objDealQualificationWRAP.brandPicklistValueMap
                            );
                            component.set("v.brandPicklistMap", picklistMap);
                        }

                        component.set("v.isChangeApprovalUser",objDealQualificationWRAP.isEnableChangeApprover);

                        if (objDealQualificationWRAP.mapOfPackageNameToId) {
                            var picklistMap = helper.getPicklistMap(
                                component,
                                event,
                                helper,
                                objDealQualificationWRAP.mapOfPackageNameToId
                            );
                            //console.log('picklistMapPackageName>>',objDealQualificationWRAP.mapOfPackageNameToId);
                            component.set("v.mapOfPackageNameToId", picklistMap);
                        }
                        if(isFromSubmit)
                            helper.submitForApprovalDQ(component, event, helper);

                        if(!isFromSubmit)
                            component.set("v.Spinner", false);
                    }
                }
            });
            $A.enqueueAction(serverAction);
            var primiaryquoteaction = component.get("c.getPrimayQuoteLineDetails");
      		 primiaryquoteaction.setParams({
                OppId: id
        	 });
            primiaryquoteaction.setCallback(this, function (response) {
                if (response.getState() == "SUCCESS") {
                   var QliDet = response.getReturnValue();
                    console.log('QLI Det' + JSON.stringify(QliDet) + 'qli length' + QliDet.length);
                    if(QliDet.length > 0){
                        if(QliDet[0].Quote.isPrimary__c == true){
                           component.set('v.HasPrimaryQuote',true);
                    	}

                        for (var i = 0; i < QliDet.length; i++) {
               				 var row = QliDet[i];
                			if (row.Product2Id)
                                row.ProductName = row.Product2.Name;
            			}
            			component.set("v.data",QliDet);
                        if(QliDet[0].Quote.Opportunity.Total_Contract_Value__c != null){
                            component.set("v.tcvval",QliDet[0].Quote.Opportunity.Total_Contract_Value__c);
                        }
                       component.set('v.ISOCode',QliDet[0].CurrencyIsoCode);
                       console.log('currency value ' + component.get('v.ISOCode'));
                       component.set('v.columns',
                       [
            			{label: 'Product', fieldName: 'ProductName', type: 'text',initialWidth: 250},
                           {label: 'Unit Sales Price', fieldName: 'UnitPrice', type: 'currency',typeAttributes:{minimumFractionDigits :'2',currencyDisplayAs : "code",currencyCode: { fieldName: 'CurrencyIsoCode'}}},
           				{label: 'Discount', fieldName: 'Discount_number__c', type: 'text'},
            			{label: 'Effective Price', fieldName: 'EffectivePrice__c', type: 'currency',typeAttributes:{minimumFractionDigits :'2',currencyDisplayAs : "code",currencyCode: { fieldName: 'CurrencyIsoCode'}}},
            			{label: 'Quantity', fieldName: 'Quantity', type: 'text'},
            			{label: 'Total Price', fieldName: 'TotalPrice', type: 'currency',typeAttributes:{minimumFractionDigits :'2',currencyDisplayAs : "code",currencyCode: { fieldName: 'CurrencyIsoCode'}}},
            			{label: 'Total 12Month Price', fieldName: 'Total12MonthPrice__c', type: 'currency',typeAttributes:{minimumFractionDigits :'2',currencyDisplayAs : "code",currencyCode: { fieldName: 'CurrencyIsoCode'}}},
            			{label: 'Dicount Type', fieldName: 'Discount_type__c', type: 'text'}]);
                    }
                }
            });
            $A.enqueueAction(primiaryquoteaction);
        }
    },

    saveDQ: function (component, event, helper,isFromSubmit) {
        var saveDQAction = component.get("c.saveDealQualification");
        var wrapRec = component.get("v.objDealQualificationWrap");
        var DQDiscountList = [];
        var DQDiscountContactCenterList = component.get("v.DQDiscountContactCenterList");
        var DQDiscountSalesQuoteList = component.get("v.DQDiscountSalesQuoteList");
        if(DQDiscountContactCenterList) {
            /*DQDiscountContactCenterList.forEach(function(element) {
                DQDiscountList.push(element);
            });*/

        }
        if(DQDiscountSalesQuoteList) {
            DQDiscountSalesQuoteList.forEach(function(element) {
                DQDiscountList.push(element);
            });
        }
        console.log("DQDiscountList updated>>", DQDiscountList);

        wrapRec.DQDiscountList = DQDiscountList;
        saveDQAction.setParams({
            objDQ: wrapRec.DQRec,
            DQDiscountList: wrapRec.DQDiscountList,
            isDQExist: wrapRec.isDQExist,
            DQTrueUpDateList : component.get("v.DQTrueUpDateList")
        });

        saveDQAction.setCallback(this, function (response) {
            if (response.getState() == "SUCCESS") {
                //if(!isFromSubmit)
                helper.CheckIdDQExists(component, event, helper,isFromSubmit);
            }
            if(response.getState() === 'ERROR') {
                alert(response.getError()[0].message);
                component.set("v.Spinner", false);
            }
        });
        $A.enqueueAction(saveDQAction);
    },

    getPicklistMap: function (component, event, helper, picklistMap) {
        var prodCatMap = [];
        var result = picklistMap;
        for (var key in result) {
            //console.log('result[key]>>',result[key]);
            prodCatMap.push({ key: key, value: result[key] });
        }
        return prodCatMap;
    },

    submitForApprovalDQ: function (component, event, helper) {
        const submitForApprovalAction = component.get(
            "c.submitForApprovalForDealQualification"
        ),
            wrapperRec = component.get("v.objDealQualificationWrap"),
            approverRecordList = wrapperRec.approverList,
            oppId = wrapperRec.DQRec.Opportunity__c,
            dqRecordId = wrapperRec.DQRec.Id,
            dqRec = wrapperRec.DQRec;

        submitForApprovalAction.setParams({
            dqId: dqRecordId,
            oppId: oppId,
            dqRecord: dqRec
        });

        submitForApprovalAction.setCallback(this, function (response) {
            if (response.getState() == "SUCCESS") {
                console.log("I AM IN SUCCESS");
                helper.CheckIdDQExists(component, event, helper,false);
                component.find("tabs").set("v.selectedTabId", "one");
            }
        });
        $A.enqueueAction(submitForApprovalAction);
    },

    revisedApproval: function (component, event) {
        const revisedApprovalAction = component.get(
            "c.revisedDealQualification"
        ),
            wrapperRec = component.get("v.objDealQualificationWrap"),
            approverRecordList = wrapperRec.approverList,
            objDQ = wrapperRec.DQRec,
            helper = this;

        revisedApprovalAction.setParams({
            objDQ: objDQ
        });

        revisedApprovalAction.setCallback(this, function (response) {
            if (response.getState() == "SUCCESS") {
                helper.CheckIdDQExists(component, event, helper);
            }
        });
        $A.enqueueAction(revisedApprovalAction);
    },

    backToQuote: function (component) {
        const callbackFn = component.get("v.submitApprovalCallbackFn"),
            tabName = "main";

        if ("function" === typeof callbackFn) {
            callbackFn.call(this, tabName);
        }
    },
    saveDQValidate: function (component, event, helper,isFromSubmit) {
        var isValidRec = true;
        var DQDiscountSalesQuoteList = component.get("v.DQDiscountSalesQuoteList");
        if(DQDiscountSalesQuoteList) {
            DQDiscountSalesQuoteList.forEach(function(element) {
                if(!$A.util.isEmpty(element.Product_Category__c)
                   ||!$A.util.isEmpty(element.Discount__c)
                   || !$A.util.isEmpty(element.Quantity__c)
                   || !$A.util.isEmpty(element.Product_Package__c)
                   || !$A.util.isEmpty(element.Product__c)) {
                    if($A.util.isEmpty(element.Product_Category__c) || $A.util.isEmpty(element.Discount__c)
                       || $A.util.isEmpty(element.Quantity__c)) {
                        //alert('test');
                        isValidRec = false;
                        helper.showToast('Error','Field : Product Category, Discount, Quanity field are required.','Error');
                        return false;
                    }
                }
            });
        }
        const detailCmp = component.find("dqDetail"),
            isValid = detailCmp.get("v.isValid");

        //if (!isValid) {
        //    alert("Please enter Justification for discount !");
        //    return false;
        //}
        if(isValidRec) {
            component.set("v.Spinner", true);
            helper.saveDQ(component, event, helper,isFromSubmit);
        }
    },

    validateELACondition: function (component, event) {
        const wrapRec = component.get("v.objDealQualificationWrap"),
            dqRecord = wrapRec.DQRec,
            salesQuoteList = component.get("v.DQDiscountSalesQuoteList"),
            productCategoryArr = ['goa_rc_office', 'goa_global_office'];

        let isValid = true;

        if (dqRecord.Is_ELA__c && dqRecord.Is_ELA__c === 'Yes') {
            isValid = false;
            salesQuoteList.forEach(function (item) {
                if (item.Product_Category__c  && item.Product_Category__c !== '' &&
                    productCategoryArr.indexOf(item.Product_Category__c.toLowerCase()) !== -1) {
                        isValid = true;
                        return false;
                    }
            });
        }
        return isValid;
    }
});