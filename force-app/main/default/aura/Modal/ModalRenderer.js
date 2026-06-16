({
    afterRender: function (component, helper) {
        this.superAfterRender();
        if (component.get('v.Modal.autoShow'))
            helper.show(component);
    }
});