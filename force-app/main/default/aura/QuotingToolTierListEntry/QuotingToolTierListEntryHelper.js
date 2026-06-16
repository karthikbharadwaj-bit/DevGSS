({
    /**
     * SHow popover
     * @fires PopoverEvent
     * @param target {object} HTML Element
     * @param iconTheme {string}
     * @param text {string}
     */
    show : function(target,iconTheme, text) {
        //if there is TierID - show tooltip
        if (text != null){
            $A.get("e.c:PopoverEvent").setParams({
            target: target,
            text: 'TierID: ' + text,
            show: true,
            showIcon: true,
            iconTheme: iconTheme,
            preferredPosition: 'top',
            }).fire();
        }
    },
    /**
     * Hide popover
     * @fires PopoverEvent
     */
    hide : function(component, event, helper){
        $A.get("e.c:PopoverEvent").setParams({
        show: false
        }).fire();

    }
})