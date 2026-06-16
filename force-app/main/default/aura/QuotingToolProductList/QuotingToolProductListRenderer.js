({
    afterRender: function (component, helper) {
        this.superAfterRender();
        helper.addEventListeners(component);
    },

    unrender: function (component, helper) {
        this.superUnrender();
        helper.removeEventListeners();
    }
});