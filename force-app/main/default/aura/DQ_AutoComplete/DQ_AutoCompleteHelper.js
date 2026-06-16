({
	searchRecords: function (component, searchString) {
		var action = component.get("c.getRecords"),
            valueField = component.get("v.valueFieldApiName");
		action.setParams({
			searchString: searchString,
			objectApiName: component.get("v.objectApiName"),
			idFieldApiName: component.get("v.idFieldApiName"),
			valueFieldApiName: valueField,
			extendedWhereClause: component.get("v.extendedWhereClause"),
			maxRecords: component.get("v.maxRecords")
		});
		action.setCallback(this, function (response) {
			var state = response.getState();
			if (state === "SUCCESS") {
				const serverResult = response.getReturnValue();
				const results = [];
                const valueSplitArr = valueField.split(".");
                serverResult.forEach((element) => {
                    let resultValue = element[component.get("v.valueFieldApiName")];
                    if (!$A.util.isEmpty(valueSplitArr)) {
                        if (valueSplitArr.length > 1) {
                            resultValue = element[valueSplitArr[0]][valueSplitArr[1]];
                        } else if (valueSplitArr.length === 1) {
                            resultValue = element[valueSplitArr[0]];
                        }
                    	
                	}
					const result = {
						id: element[component.get("v.idFieldApiName")],
						value: resultValue
					};
					results.push(result);
				});
				component.set("v.results", results);
				if (serverResult.length > 0) {
					component.set("v.openDropDown", true);
				}
			} else {
				var toastEvent = $A.get("e.force:showToast");
				if (toastEvent) {
					toastEvent.setParams({
						title: "ERROR",
						type: "error",
						message: "Something went wrong!! Check server logs!!"
					});
					toastEvent.fire();
				}
			}
		});
		$A.enqueueAction(action);
	}
});