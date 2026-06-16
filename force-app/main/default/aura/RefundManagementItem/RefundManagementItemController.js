({
    toggleExpand: function (component) {
        if (RC.htmlUtils.isTextSelection()) {
            return;
        }

        const item = component.get('v.item');

        item.toggleIsExpanded();

        component.set('v.item', item);
    }
});