({
    /**
     * Collapse notifications. Only the top one will be visible
     */
    closeNotifications: function(component) {
        var activeNotifications = component.get('v.activeNotifications');

        activeNotifications.forEach(function(notification){
            notification.isHelpTextShown = false;
        });
        component.set('v.activeNotifications', activeNotifications);

        $A.util.removeClass(component.find('notificationsContainer'), 'notifications--open');
        $A.util.removeClass(component.find('notificationsOverlay'), 'notifications-overlay--open');
    },

    /**
     * Show all notifications
     */
    openNotifications: function(component) {
        $A.util.addClass(component.find('notificationsContainer'), 'notifications--open');
        $A.util.addClass(component.find('notificationsOverlay'), 'notifications-overlay--open');
    },

    checkNotifications: function(component) {
        var notifications = component.get("v.notifications");
        var activeNotifications = component.get("v.activeNotifications");
        var newNotifications = [];
        notifications.forEach(function(notification) {
            if (notification.check()) {
                newNotifications.push(this.prepareNotification(component, notification));
            }
        }, this);

        var searchActiveNotifications = activeNotifications.map(function (n) {
            return n.name;
        });
        var notificationsToRemove = newNotifications.filter(function (n) {
            return searchActiveNotifications.indexOf(n.name) > -1;
        });
        var notificationsToAdd = newNotifications.filter(function (n) {
            return searchActiveNotifications.indexOf(n.name) === -1;
        });
        component.set("v.activeNotifications", newNotifications);
        var domActions = [];
        if (newNotifications.length === 0) {
            domActions.push('hide');
        } else {
            if (newNotifications.length === 1) {
                domActions.push('one');
            } else {
                domActions.push('multiple');
            }

            if (notificationsToAdd.length > 0) {
                domActions.push('add');
            } else if (notificationsToRemove.length < activeNotifications.length) {
                domActions.push('remove');
            }
        }
        if (domActions.length > 0) {
            this.animate(component, domActions);
        }
    },

    prepareNotification: function(component, notification) {
        var preparedNotification = Object.assign({}, notification);
        if (typeof preparedNotification.text === 'function')
            preparedNotification.text = preparedNotification.text();
        return preparedNotification;
    },

    /**
     * Apply styles to notification bar
     */
    animate: function(component, domActions) {
        if (Array.isArray(domActions)) {
            var notificationsContainer = component.find('notificationsContainer');
            var removeClass = [];
            var addClass = [];
            var addClassRevert = false;
            var removeClassRevert = false;
            domActions.forEach(function(action) {
                switch (action) {
                    case 'add':
                        removeClass.push('slds-hide');
                        addClass.push('notifications--add');
                        addClassRevert = true;
                        break;
                    case 'remove':
                        addClass.push('notifications--remove');
                        removeClassRevert = true;
                        break;
                    case 'hide':
                        addClass.push('slds-hide');
                        break;
                    case 'one':
                        removeClass.push('notifications--multiple');
                        break;
                    case 'multiple':
                        addClass.push('notifications--multiple');
                        break;
                }
            });

            removeClass.forEach(function(cssClass) {
                $A.util.removeClass(notificationsContainer, cssClass);
            });
            addClass.forEach(function(cssClass) {
                $A.util.addClass(notificationsContainer, cssClass);
            });
            if (addClassRevert) {
                setTimeout($A.getCallback(function() {
                    if (component.isValid() && notificationsContainer.isValid()) {
                        $A.util.removeClass(notificationsContainer, "notifications--add");
                    }
                }), 1000);
            }
            if (removeClassRevert) {
                setTimeout($A.getCallback(function() {
                    if (component.isValid() && notificationsContainer.isValid()) {
                        $A.util.removeClass(notificationsContainer, "notifications--remove");
                    }
                }), 1000);
            }
        }
    }

});