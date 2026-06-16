({
    afterRender: function (component, helper) {
        this.superAfterRender();
        helper.restartAppOnTabOpen(component);
    }
});