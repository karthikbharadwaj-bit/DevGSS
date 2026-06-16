({
    unrender: function (component, helper) {
        this.superUnrender();
        helper.removeEventListeners();
    }
});