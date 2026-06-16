({
	getOrdersFromController: function(component) {
		var helper = this;

		component.set('v.isLoad', true);

		helper.request(component, helper, 'c.getOrders', {accId: component.get('v.accId')})
			.then($A.getCallback(function(res) {
				if(!component.isValid()) return;

				console.log('init success', res);

				var quotes = [];
				var groupByQuote =	_.groupBy(res, function(item) {
			 		return item.Quote.Id;
				});

				_.mapObject(groupByQuote, function(val, key) {
					quotes.push({
						Id: key,
						Name: val[0].Quote.Name,
						CreatedDate: val[0].Quote.CreatedDate,
						Orders: val,
					});
				})

				console.log('quotes', quotes);

				// Sort Orders
				var quotes = helper.sortBy(
					quotes,
					{type: 'date', value: 'CreatedDate', order: 'desc'},
					{type: '', value: 'Name', order: 'desc'}
				);

				var quote,
						order;
				for (var i = 0; i < quotes.length; i++) {
					quote = quotes[i];
					quote.Orders = helper.sortBy(
						quote.Orders,
						{type: 'date', value: 'CreatedDate', order: 'desc'}
					);

					for (var k = 0; k < quote.Orders.length; k++) {
						order = quote.Orders[k];
						order.OrderItems = helper.sortBy(
							order.OrderItems,
							{type: 'date', value: 'CreatedDate', order: 'desc'},
							{type: '', value: 'Product2.Name', order: 'desc'}
						);
					}
				}

				component.set('v.data', quotes);
				component.set('v.isLoad', false);
			}))
			.catch($A.getCallback(function(res) {
				helper.showPrompt(component, true, 'An error occurred while receiving the orders.');
				console.log('init Error', res);
			}));
	},

	sortBy: function(array, field1, field2, field3) {
		var helper = this;
		if(!array || !Array.isArray(array)) return array;

		var result = array.sort(function (a, b) {
			var r;
			var result1 = r = helper.getSortValueByType(a, b, field1);

			if(field2) {
				var result2 = helper.getSortValueByType(a, b, field2);
				r = result1 || result2;
			}

			if(field3) {
				var result3 = helper.getSortValueByType(a, b, field3);
				r = result1 || result2 || result3;
			}

			return r;
		});

		return result;
	},

	getSortValueByType: function(a, b, field) {
		var f = field.value.split('.');
		_a = f.length === 1 ? a[field.value] : a[f[0]][f[1]];
		_b = f.length === 1 ? b[field.value] : b[f[0]][f[1]];

		// Date
		if(field.type === 'date') {
			if(field.order === 'asc') {
				return new Date(_a).getTime() - new Date(_b).getTime()
			} else {
				return new Date(_b).getTime() - new Date(_a).getTime()
			}
		}
		// Boolean
		else if(field.type === 'boolean') {
			if(field.order === 'asc') {
				// false values first
				return (_a === _b)? 0 : _a? 1 : -1;
			} else {
				// true values first
				return (_a === _b)? 0 : _a? -1 : 1;
			}
		}
		// Other
		else {
			if(field.order === 'asc') {
				return _a < _b;
			} else {
				return _b < _a;
			}
		}
	},

	showPrompt: function(component, value, text) {
		component.set('v.isLoad', false);
		component.set('v.prompt.text', '');

		var modal = component.find('modal');
		var modalBg = component.find('modal-bg');

		if(value) {
			$A.util.addClass(modalBg, 'slds-backdrop--open');
			$A.util.addClass(modal, 'slds-fade-in-open');
			$A.util.removeClass(modal, 'slds-hide');
			component.set('v.prompt.text', text);
		} else {
			$A.util.removeClass(modalBg, 'slds-backdrop--open');
			$A.util.removeClass(modal, 'slds-fade-in-open');
			$A.util.addClass(modal, 'slds-hide');
		}

	},

	request: function(component, helper, controller, params) {
		var p = new Promise(function(resolve, reject) {
			var action = component.get(controller);
			if(params) {
				action.setParams(params);
			}
			action.setCallback(helper, function(response) {
				if(response.getState() === 'SUCCESS') {
					var res = response.getReturnValue();
					if(res) {
						resolve(res);
					} else {
						reject(res);
					}
				} else {
					reject(response);
				}
			});
			$A.enqueueAction(action);
		});
		return p;
	},
})