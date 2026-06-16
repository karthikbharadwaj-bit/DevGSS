({
    afterRender: function (component, helper) {
        this.superAfterRender();
        helper.addEventListeners(component);
    }
});