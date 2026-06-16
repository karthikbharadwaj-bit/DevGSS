({
    showPopover: function(component, target, textSource, iconTheme){
        if (textSource) {
            $A.get("e.c:PopoverEvent").setParams({
                target: target,
                show: true,
                showIcon: true,
                iconTheme: iconTheme,
                preferredPosition: 'top',
                text: component.get('v.' + textSource)
            }).fire();
        }
    }
})