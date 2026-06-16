({
    popoverEvent: function(component, event, helper){
        var initPositionTimeout = component.get('v.initPositionTimeout');
        var popover = component.find('popover');
        helper.lastAction = event.getParam('show') ? 'show' : 'hide';
        if (event.getParam('show')) {
            clearTimeout(initPositionTimeout);
            var target = event.getParam('target');
            var preferredPosition = event.getParam('preferredPosition');

            var content = event.getParam('content');
            var text = '';
            var showIcon = false;
            var iconTheme,
                iconCollection;

            if (!content){
                // Legacy
                text = event.getParam('text');
                showIcon = event.getParam('showIcon');
                iconTheme = event.getParam('iconTheme');
                iconCollection = event.getParam('iconCollection') || 'utility';
            }
            component.set('v.text', text);
            component.set('v.showIcon',showIcon);
            component.set('v.iconTheme',iconTheme);
            component.set('v.content',content);
            component.set('v.iconCollection',iconCollection);


            component.set('v.target',target);
            helper.setTheme(component, event.getParam('theme'));
            // Calculate popover position in next rendering cycle after contents of popover will be displayed
            if(target) {
                window.setTimeout(
                    $A.getCallback(function () {
                        helper.setPosition(component, target, preferredPosition);
                    })
                );
            }
            $A.util.removeClass(popover, 'popover--hidden');
        } else {
            $A.util.addClass(popover, 'popover--hidden');

            // Move tooltip out of screen after fade out so it will unfold completely
            // If user is fast enough to open another tooltip do not move it out to prevent jump
            initPositionTimeout = setTimeout($A.getCallback(function() {
                if (helper.lastAction === 'show'){
                    return;
                }
                component.set('v.style','');
            }), 300);
            component.set('v.initPositionTimeout', initPositionTimeout);
        }
    }
})