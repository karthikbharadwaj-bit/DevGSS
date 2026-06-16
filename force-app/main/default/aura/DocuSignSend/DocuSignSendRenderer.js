({
    afterRender: function(component) {
        setTimeout($A.getCallback(() => {
            component.find('fadeInContainer').forEach(cmp => $A.util.addClass(cmp, 'fade-in-base_rendered'));
        }));
        return this.superAfterRender();
    }
});