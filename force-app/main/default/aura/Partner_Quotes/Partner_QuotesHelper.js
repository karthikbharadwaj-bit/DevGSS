({
	helperMethod: function () {

	},

	//METHOD TO GET Quote RECORDS FOR LIST VIEW
	getQuoteDataList: function (component, event, helper, pageNumber, pageSize, viewAll) {
		var val = component.get("v.selectedValue");
		var action = component.get("c.getQuoteData");
		action.setParams({
			'pageNumber': pageNumber,
			'pageSize': pageSize,
			'searchKeyWord': component.get("v.searchKeyword"),
			'searchBy': component.get("v.searchBy"),
			'viewAll': viewAll,
			'selectedPartnerAccount': val,
		});
		action.setCallback(this, function (result) {
			var state = result.getState();
			if (component.isValid() && state === "SUCCESS") {

				var resultData = result.getReturnValue();
				if (resultData.quoteList == undefined || resultData.quoteList == '') {
					component.set("v.Message", true);
					component.set("v.ShowRecordDetail", false);
				} else {
					component.set("v.Message", false);
				}
				if (resultData.quoteList != undefined && resultData.quoteList != '') {
					//Fix for CRM-4287 starts 
					for (var i = 0; i < resultData.quoteList.length; i++) {
						var row = resultData.quoteList[i];

						if (row.Status == 'Pending Order' && row.Opportunity__r.Type == 'Existing Business') {
							component.set("v.isChangeOrderSubmitted", true);
						} else {
							component.set("v.isChangeOrderSubmitted", false);
						}
					}  //Fix for CRM-4287 ends
					component.set("v.quoteList", resultData.quoteList);
					component.set("v.ShowRecordDetail", true);
				}
				if (resultData.isAvaya == true || resultData.isMaster == true) {
					component.set("v.ShowConAcc", true);

				}
				component.set("v.pageNumber", resultData.pageNumber);
				component.set("v.totalRecords", resultData.totalRecords);
				component.set("v.recordStart", resultData.recordStart);
				component.set("v.recordEnd", resultData.recordEnd);
				component.set("v.totalPages", Math.ceil(resultData.totalRecords / pageSize));
				component.set('v.ShowSpinnerQuote', false);
				console.log('yes');
			} else {
				component.set('v.ShowSpinnerQuote', false);
				console.log('no');
			}


		});
		$A.enqueueAction(action);

	},

	//Translation Start
	getTranslations: function (component, event, helper) {
		try {
			var action = component.get("c.getTranslations");
			action.setParams({
				"objNames": 'Partner_Quote__c'
			});
			action.setCallback(this, function (result) {
				var state = result.getState();
				if (component.isValid() && state === "SUCCESS") {
					console.log('AllObjFields - ' + JSON.stringify(result.getReturnValue()));
					var resultData = result.getReturnValue();
					if (resultData != undefined && resultData != null && resultData != '') {
						if (resultData.allObjFieldsMap != undefined && resultData.allObjFieldsMap != null &&
							resultData.allObjFieldsMap != '') {
							component.set("v.quoteFieldsMap", resultData.allObjFieldsMap.Partner_Quote__c);
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
	//Translation End
	//METHOD TO GET LIST OF  PARTNER ACCOUNT
	getPartnerAccountList: function (component, event, helper) {
		var action = component.get("c.getAccountList");
		action.setCallback(this, function (result) {
			var state = result.getState();
			if (component.isValid() && state === "SUCCESS") {
				var resultData = result.getReturnValue();
				if (resultData.listPartnerAccounts != undefined && resultData.listPartnerAccounts.length > 0) {
					component.set("v.selectedValue", resultData.listPartnerAccounts[0].Id);
					component.set("v.partnerAccounts", resultData.listPartnerAccounts);
					component.set("v.partnerAccountName", resultData.listPartnerAccounts[0].Name);
					component.set("v.accountId", resultData.listPartnerAccounts[0].Id);
					component.set("v.partnerCommunity", resultData.partnerCommunityName);
					if (resultData.isAvaya == true || resultData.isMaster == true) {
						component.set("v.ShowConAcc", true);
						component.set("v.viewAll", true);
						var pageNumber = 1;
						var pageSize = 50;
						this.getQuoteDataList(component, event, helper, pageNumber, pageSize, 'ALL');
					}
					else {
						var pageNumber = 1;
						var pageSize = 50;
						this.getQuoteDataList(component, event, helper, pageNumber, pageSize, '');
					}
					if (resultData.isAvaya == true) {
						component.set("v.ShowOnlyAvaya", true);
					}
					component.set("v.isSingleLogin", resultData.isSingleLogin);
				}
			}
		});
		$A.enqueueAction(action);
	},

})