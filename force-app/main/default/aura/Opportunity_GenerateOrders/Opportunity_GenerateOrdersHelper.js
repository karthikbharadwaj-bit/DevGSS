({
	generateOrders : function(component, event, helper) {
		return new Promise(resolve => {
			var isBillingOpportunity = component.get('v.isBillingOpportunity');
			if (isBillingOpportunity) {
				this.processDataNewBilling(component, event, helper);
			} else {
				this.processData(component ,event, helper);
			}
		});
	},

	processData : function (component, event, helper) {
		var action1 = component.get("c.processData");
		var opportunityId = component.get('v.oppId');
		action1.setParams({
			"oppId" : component.get('v.oppId'),
			"rcNumber" : component.get('v.rcNumberInput'),
			"ccNumber" : component.get('v.ccNumber')
		});

		action1.setCallback(this, function(response){
			var state = response.getState();
			if(state == "SUCCESS"){
				var res = response.getReturnValue();
				var result = JSON.parse(res);

				var options = {};

				switch (result.status) {
					case 'success':
						options.details = 'The page will be reloaded';
						location.reload();

					case 'error':
					case 'info':
						options.theme = result.status;

						if (result.hasOwnProperty('details')) {
							options.header = result.message;
							options.details = result.details;
						} else {
							options.header = result.message;
							options.details = result.message;
						}

						if (result.message === 'Orders are already generated for this Opportunity') {
							options.details = 'You can find them in the <a href=#' + opportunityId + '_RelatedOrderList>related list below</a>';
						}
						console.log('opt'+JSON.stringify(options));
						this.addMessage(component, options);
						this.showMessages(component);
						break;

					case 'action required':
						helper.askForRCandCCNumbers(component, helper, result);
					break;

					default:
					// proccessData
					break;
				}
				helper.hideSpinner(component);
			} else {
				helper.hideSpinner(component);

				var options = {
					theme: 'error',
					header: 'Generate Orders webservice call failed',
					details: error
				};

				this.addMessage(component, options);
				this.showMessages(component);
			}
			});
		$A.enqueueAction(action1);
	},

	processDataNewBilling:function(component, event, helper) {
		console.log('In process Datanewbilling');

		var params = {
			"oppId": component.get('v.oppId'),
			"rcNumber": component.get('v.rcNumberInput'),
			"ccNumber": component.get('v.ccNumber')
		}

		try {
			var action1 = component.get("c.processData");
			action1.setParams(params);
			action1.setCallback(this, function(response){

				var state = response.getState();

				if(state == "SUCCESS"){
					helper.hideSpinner(component);
					var res = response.getReturnValue();
					var result = JSON.parse(res);
					if (res) {
						if (result.status == 'action required') {
							this.askForRCandCCNumbers(component, helper, result);
						} else {
							helper.hideSpinner(component);
							var messages = result;

							var toastEvent = $A.get("e.force:showToast");
							toastEvent.setParams({
								"type": messages.status,
								"title": messages.message,
								"message":messages.message,
								"mode":'dismissible'
							});
							toastEvent.fire();

							component.set('v.isMessageprompt', true);
							component.set('v.infoMessage', messages.message);

							if (messages.message == 'Orders were successfully created') {
								setTimeout(function(){
									$A.get('e.force:refreshView').fire(); 
								}, 1300);
							}
						}
					}
				}
			});
			$A.enqueueAction(action1);
		} catch (e) {
			this.addMessage(component, {
				theme: 'error',
				header: 'An error has occurred processing request to webservices',
				details: 'Please contact administrator'
			});
		} finally {
			this.showMessages(component);
		}
	},

	askForRCandCCNumbers:function(component, helper, result) {
		var rcNumber = result['Account.RC_Account_Number__c'];
		component.set('v.rcNumber', rcNumber);
		component.set('v.isGenerateorderprompt', true);
	},

	addMessage:function(component, result) {
		var messages = component.get('v.messages');
		if (!result || !result.details) {
			return;
		}
		console.log('messages = ' + messages);
		console.log('result = ' + JSON.stringify(result));
		var res = JSON.stringify(result);

		var toastEvent = $A.get("e.force:showToast");
		toastEvent.setParams({
			"type":result.theme,
			"title": result.header,
			"message": result.details,
			"mode":'dismissible'
		});
		toastEvent.fire();

		messages.push({
			theme: res.theme,
			header: res.header,
			details: res.details
		});
		
		component.set('v.messages', messages);
	},

	showMessages : function (component) {
		console.log('inside show messages');
		console.log('messages = ' + component.get('v.messages'));
	},

	showSpinner: function(component, event, helper) {
        // make Spinner attribute true for display loading spinner
        component.set("v.spinner", true);
    },

    // this function automatic call by aura:doneWaiting event
    hideSpinner : function(component,event,helper){
        // make Spinner attribute to false for hide loading spinner
        component.set("v.spinner", false);
    }

})