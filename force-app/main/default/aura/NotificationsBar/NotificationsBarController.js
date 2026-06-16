({
    // doInit: function(component) {
    //     var notifications = [
    //         // {
    //         //     text: function(){
    //         //         return $A.get("$Label.c.notificationText"),
    //         //     }
    //         //     type: 'info', // warning, error
    //         //     priority: function(){
    //         //         return 1;
    //         //     },
    //         //     check: function(){
    //         //         return true || false;
    //         //     }
    //         // }
    //     ];
    //     component.set("v.notifications", notifications);
    // },

    update: function(component, event, helper) {
        helper.checkNotifications(component);
    },

    close: function(component, event, helper) {
        helper.closeNotifications(component);
    },

    toggleNotifications: function(component, event, helper) {
        var notificationsContainer = component.find('notificationsContainer');
        if ($A.util.hasClass(notificationsContainer, 'notifications--open')) {
            helper.closeNotifications(component);
        } else {
            helper.openNotifications(component);
        }
    }
});