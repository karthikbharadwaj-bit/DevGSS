({
    afterRender: function (component, helper) {
        this.superAfterRender();
        helper.checkVisibility(component);
        helper.checkMessages(component);
        helper.checkShowDetails(component);
    },
    rerender: function (component, helper) {
        this.superRerender();
        helper.checkInputsDisabling(component);
    }
})