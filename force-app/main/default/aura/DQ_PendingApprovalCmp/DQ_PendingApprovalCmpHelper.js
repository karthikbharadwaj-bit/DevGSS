({
	init : function(component) {
		const action = component.get("c.loadPendingApproval"),
            helper = this;
        console.log('{!$Site.BaseUrl}');
        action.setCallback(this, function (response){
            if (response.getState() === 'SUCCESS') {
                var records = response.getReturnValue();
                console.log('records'+JSON.stringify(records));
                
                component.set("v.pendingApprovalList", response.getReturnValue());
                component.set("v.isLoading", false);
            }
        });
        
        $A.enqueueAction(action);
    },
    
    generateDataTableColumn: function (component) {
        component.set('v.columns', [
            {type: "button", initialWidth:300,typeAttributes: {
            	label: {fieldName: 'dqName'},
                name: 'View',
                title: 'View',
            	value: 'view',
                iconPosition: 'left',
                variant: 'base'
            }},
            {label: 'Level', fieldName: 'level', type: 'text', initialWidth:80},
            {label: 'Status', fieldName: 'status', type: 'text', initialWidth:80},
            {label: 'Submitted Date', fieldName: 'submittedDate', type: 'date', initialWidth:180},
            {label: 'Reason', fieldName: 'reason', type: 'text', initialWidth:250, wrapText: true},
            {label: 'Special Term', fieldName: 'specialTerm', type: 'text', initialWidth:160},
            {label: 'Minimum Initial Term', fieldName: 'minimumInitialTerm', type: 'text', initialWidth:160},
            {label: 'Total Quote', fieldName: 'totalQuote', type: 'text', initialWidth:160},
            {label: 'Overall Discount', fieldName: 'overallDiscount', type: 'number', initialWidth:160},
            {label: 'Cost of One-Time items', fieldName: 'costOfOneTimeItems', type: 'number', initialWidth:160},
            {label: 'New Annual Recurring Charges', fieldName: 'newAnnualRecurringCharges', type: 'number', initialWidth:160},
            {label: 'Brand', fieldName: 'brand', type: 'text', initialWidth:160},
            {label: 'Segment', fieldName: 'segment', type: 'text', initialWidth:160},
            {label: 'Montly Reccuring Charge', fieldName: 'monthlyRecurringCharge', type: 'number', initialWidth:160}
            
        ]);
    },

    submitAction: function (component) {
        const action = component.get("c.rejectApproveAction"),
            helper = this,
            selectedRecords = component.get("v.selectedDQRecords"),
            actionVal = component.get("v.bulkAction"),
            commentsVal = component.get("v.comments"),
            params = {
                action: actionVal,
                comments: commentsVal,
                listOfDQApproverIds: helper.pluckDQAIds(selectedRecords)  
            };

        action.setParams(params);
        
        action.setCallback(this, function (response){
            if (response.getState() === 'SUCCESS') {
                component.set("v.pendingApprovalList", response.getReturnValue());
                helper.showToast(component);
                helper.resetConfigVal(component);
            }
        });
        
        $A.enqueueAction(action);
    },

    pluckDQAIds: function (selectedDQRecords) {
        return selectedDQRecords.map(function (eachRecord) {
            return eachRecord.id;
        })
    },

    resetConfigVal: function (component) {
        component.set("v.isLoading", false);
        component.set("v.bulkAction", undefined);
        component.set("v.selectedDQRecords", undefined);
        component.set("v.comments", undefined);
        component.set("v.isDisabled", true);
    },

    showToast : function(component) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Success!",
            "type": 'success',
            "message": "The record has been updated successfully."
        });
        toastEvent.fire();
    }
})