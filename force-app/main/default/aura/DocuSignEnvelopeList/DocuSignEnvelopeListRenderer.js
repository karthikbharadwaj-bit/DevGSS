({
    afterRender: function(component) {
        setTimeout($A.getCallback(() => $A.util.addClass(component.find('fadeInContainer'), 'fade-in-base_rendered')));
        return this.superAfterRender();
    }
});