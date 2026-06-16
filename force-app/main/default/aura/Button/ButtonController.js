({
    onMouseOver: function (component, event) {
        var tooltipText = component.get('v.tooltipText');
        if (!tooltipText) return;

        $A.get("e.c:PopoverEvent").setParams({
            target: event.currentTarget,
            show: true,
            showIcon: true,
            iconTheme: 'info',
            text: tooltipText
        }).fire();
    },

    onMouseOut: function () {
        $A.get("e.c:PopoverEvent").setParams({
            show: false,
        }).fire();
    }
});