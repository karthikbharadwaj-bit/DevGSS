({
    /**
     * SHow popover
     * @fires PopoverEvent
     * @param target {object} HTML Element
     * @param iconTheme {string}
     * @param text {string}
     */
    showPopover: function(target, iconTheme, text){
        $A.get("e.c:PopoverEvent").setParams({
            target: target,
            show: true,
            showIcon: true,
            iconTheme: iconTheme,
            preferredPosition: 'top',
            text: text
        }).fire();
    },
    /**
     * Hide popover
     * @fires PopoverEvent
     */
    hidePopover: function(){
        $A.get("e.c:PopoverEvent").setParams({
            show: false
        }).fire();
    }
})