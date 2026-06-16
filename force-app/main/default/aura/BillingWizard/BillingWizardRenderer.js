({
	afterRender: function(component, helper) {
		this.superAfterRender();
		helper.initAngular(component);
    }
})