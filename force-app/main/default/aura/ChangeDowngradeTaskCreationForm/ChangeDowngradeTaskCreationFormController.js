({
	initPanel: function (cmp, event, helper) {
		var opts = {};
		var todayDate = new Date();
		opts.taskDueDate = (todayDate.getMonth() + 2 > 12 ? todayDate.getFullYear() + 1 : todayDate.getFullYear()) + '-' + (todayDate.getMonth() + 2 > 12 ? 1 : todayDate.getMonth() + 2) + '-' + todayDate.getDate();
		cmp.set('v.options', opts);
	},

	onChangeTextValue: function (cmp, event, helper) {
		var chValueEvent = cmp.getEvent('changeValue');
		chValueEvent.setParams({object:'Task', field:'Subject', value:cmp.find("taskSubject").elements[0].value});
		chValueEvent.fire();
	},

	onChangeDateValue: function (cmp, event, helper) {
		var chValueEvent = cmp.getEvent('changeValue');
		chValueEvent.setParams({object:'Task', field:'ActivityDate', value:cmp.find("taskDueDate").get("v.value")});
		chValueEvent.fire();
	},

	onChangeStatusValue: function (cmp,evt,helper) {
		var chValueEvent = cmp.getEvent('changeValue');
		chValueEvent.setParams({object:'Task', field:'Status', value:evt.getSource().elements[0].value});
		chValueEvent.fire();
	},

	onChangePriorityValue: function (cmp,evt,helper) {
		var chValueEvent = cmp.getEvent('changeValue');
		chValueEvent.setParams({object:'Task', field:'Priority', value:evt.getSource().elements[0].value});
		chValueEvent.fire();
	}

})