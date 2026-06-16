({
	loadData : function(component, event, helper) {
        console.log('in controller>>>');
		var idParam = helper.getJsonFromUrl().id;//will get abc as id
        console.log('idParam>>',idParam);
        component.set('v.quoteId',idParam);
	}
})