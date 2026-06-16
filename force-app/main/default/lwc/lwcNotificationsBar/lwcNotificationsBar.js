import {LightningElement, api, track} from 'lwc';

export default class LwcNotificationsBar extends LightningElement {
    @track isOpen = false;
    @track animateOnAdd = false;
    @track animateOnRemove = false;

    _notifications = [];
    @api set notifications(notifications) {
        const newArr = Array.isArray(notifications)
            ? notifications.map((notification, index) => {
                const n = notification || {};
                const severity = n.severity || 'info';
                return {
                    ...n,
                    iconName: 'utility:' + severity,
                    iconCSSClasses: 'notification__icon-container slds-icon_container slds-m-right_small slds-no-flex slds-align-top slds-theme_' + severity,
                    key: n.header + index,
                };
            })
            : [];
        this.compareAndAnimate(newArr);
        this._notifications = newArr;
    }
    get notifications () {
        return this._notifications;
    }

    get moreNotificationsCount() {
        return this._notifications.length - 1;
    }

    get showMoreNotificationsButton() {
        return this.moreNotificationsCount > 0;
    }

    get hasNotifications() {
        return this._notifications.length > 0;
    }

    get containerCss() {
        return [
            'slds-grid notifications-container',
            this.isOpen && 'notifications--open',
            this.showMoreNotificationsButton && 'notifications--multiple',
            this.animateOnAdd && 'notifications--add',
            this.animateOnRemove && 'notifications--remove',
        ].filter(Boolean).join(' ')
    }

    compareAndAnimate(newArr) {
        const oldHeaders = this._notifications.map(n => n.header);
        const newHeaders = newArr.map(n => n.header);

        const added = () => newHeaders.some(x => !oldHeaders.includes(x));
        const removed = () => oldHeaders.some(x => !newHeaders.includes(x));

        if (added()) {
            this.animateOnAdd = true;
        } else if (removed()) {
            this.animateOnRemove = true;
        }

        setTimeout(() => {
            this.animateOnAdd = false;
            this.animateOnRemove = false;
        }, 1000);
    }

    toggleIsOpen(event) {
        this.isOpen = !this.isOpen;
        if (this.isOpen) {
            event.stopPropagation();
            this._close = this.close.bind(this);
            window.addEventListener('click', this._close);
        }
    }

    _close = null;
    close() {
        this.isOpen = false;
        window.removeEventListener('click', this._close);
    }

    disconnectedCallback() {
        window.removeEventListener('click', this._close);
    }

}