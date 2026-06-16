import { LightningElement, api, track } from 'lwc';
import { INFO } from "c/snUtils";

const LINK_PLACEHOLDER = '{1}';

export default class ModalWindowNotificationBar extends LightningElement {
    @api messages = [];
    @track isBarOpen = false;

    toggleNotifications() {
        this.isBarOpen = !this.isBarOpen;
    }

    get notifications() {
        return this.messages.map((message, index) => {
            let notification = {
                id: index,
                containerCssClass: 'notification theme_' + message.severity,
                text: message.message,
                helpTextCssClass: 'notification__help-text--open ' +
                    (message.messageDetails && 'notification__help-text'),
                icon: 'utility:' + message.severity,
                iconClass: message.severity === INFO ? 'icon-grey' : 'icon-white',
                quantityIconClass: message.severity === INFO ? 'slds-badge slds-badge_inverse' : 'slds-badge slds-badge_lightest',
                isShowQuantity: index === 0,
                textContainer: 'slds-media__body slds-grid_vertical-align-end',
            };
            this.setUpHelpText(notification, message);
            return notification;
        });
    }

    setUpHelpText(notification, message) {
        if (message.url && message.messageDetails != null && message.messageDetails.includes(LINK_PLACEHOLDER)) {
            let messageDetailsParts = message.messageDetails.split(LINK_PLACEHOLDER);
            notification.helpTextFirstPart = messageDetailsParts[0];
            notification.helpTextSecondPart = messageDetailsParts[1];
            notification.linkText = message.urlLabel;
            notification.linkHref = message.url;
        } else {
            notification.helpText = message.messageDetails;
        }
    }

    onClose() {
        this.dispatchEvent(new CustomEvent('removemessages'));
    }

    get notificationsContainer() {
        return 'notification-container slds-grid notifications--' + (this.isBarOpen ? 'open' : 'closed');
    }

    get showNotificationsQuantity() {
        return this.notifications.length > 1;
    }

    get notificationsQuantity() {
        return this.notifications.length - 1;
    }
}