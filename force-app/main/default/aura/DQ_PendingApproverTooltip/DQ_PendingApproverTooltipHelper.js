({
    toggleHelper : function(component,event) {
        const toggleText = component.find("tooltip");
        $A.util.toggleClass(toggleText, "toggle");
    }
})