({
	onClick : function(component, event, helper) {
        var urlval = event.getSource().get("v.id");
    	window.open(urlval, '_blank');
	}
})