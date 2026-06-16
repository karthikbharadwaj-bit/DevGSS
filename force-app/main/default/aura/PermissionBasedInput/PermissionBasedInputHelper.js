({
    showInput: function(component) {
        $A.util.addClass(component.find("blockDisplay"), "hidden");
        $A.util.removeClass(component.find("inputDiv"), "hidden");
    },

    hideInput: function(component) {
        $A.util.removeClass(component.find("blockDisplay"), "hidden");
        $A.util.addClass(component.find("inputDiv"), "hidden");
    },

    /**
     * Enter edit mode if edit is allowed and there is no value in field
     * */
    enterEditModeOnInit: function(component) {
        if (!component.get('v.recordValue') && component.get('v.isUserHasEditPermission') && !component.get('v.isInputDisabled')) {
            this.showInput(component);
        }
    },

    updateUI: function(component) {
        // Update UI
        var app = component.get('v.app');
        app.update();
        component.set('v.isPhasesChanged', app.hasUnsavedChanges);
        component.set('v.app', app);
    }
})