({
	doInit: function (component, event, helper) {
		component.set("v.isLoading", true);
		helper.generateDataTableColumn(component);
		helper.init(component);
	},

	handleClick: function (component, event, helper) {
		const cmp = event.currentTarget,
			dqId = cmp.dataset.dqid;
         
       
        
            urlEvent = $A.get("e.force:navigateToURL");

		urlEvent.setParams({
			url: "/apex/DQ_DealQualificationMain?oppId=" + dqId
		});
		urlEvent.fire();
            
        
			
	},

	handleMenuSelect: function (component, event, helper) {
		const selectedMenuItemValue = event.getParam("value"),
			cmp = event.getSource(),
			approvalIdWithDealQualId = cmp.get("v.class"),
			idsArray = approvalIdWithDealQualId.split(":"),
			approvalId = idsArray[0],
			dealQualId = idsArray[1];

		component.set("v.approverId", approvalId);
		component.set("v.isApprovalAction", true);
		component.set("v.isForApprove", false);
		component.set("v.dealQualId", dealQualId);
		if (selectedMenuItemValue === "approve") {
			component.set("v.isForApprove", true);
		}
	},

	handleRowAction: function (component, event, helper) {
		const selectedRows = event.getParam("selectedRows");
		
        component.set("v.selectedDQRecords", selectedRows);
        component.set("v.isDisabled", $A.util.isEmpty(selectedRows));
	},

	openModel: function (component, event, helper) {
		component.set("v.isModalOpen", true);
	},

	closeModel: function (component, event, helper) {
		component.set("v.isModalOpen", false);
	},

	submitDetails: function (component, event, helper) {
        component.set("v.isModalOpen", false);
        component.set("v.isLoading", true);
        helper.submitAction(component);
    },
    
    handleBtnClick: function (component, event, helper) {
        const target = event.getSource(),
            actionName = target.get("v.name");
        component.set("v.bulkAction", actionName);
        component.set("v.isModalOpen", true);
    },
    
     handleRowHandlerAction : function(cmp,event,helper){
       const action = event.getParam('action'),
        row = event.getParam('row'),
           oppId = row.oppId;
           const quoteid = cmp.get("v.quoteid");
           console.log('row'+JSON.stringify(row));
     // navigate to sObject detail page    
          if ( action.name == 'View' ) {
              window.open('/apex/DQ_DealQualificationMain?oppId=' + oppId);
           }
    
       
    },
});