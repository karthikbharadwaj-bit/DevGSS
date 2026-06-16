({
    afterRender: function (component, helper) {
        this.superAfterRender();

        var location = component.get('v.location');
        if (location.showEditLocationFormOnRender){

            location.showEditLocationFormOnRender = false;
            helper.openLocationForm(component);
        }
    },
})