import { LightningElement, track, api } from "lwc";
export default class ScTrustStatusItem extends LightningElement {
    @api status;
    @api side;
    @api title;
    @api childrens = [];
    @track minimize = true;
    @api minimizeIsForced = false;
    @track isConnected = false;
    statuses = ["good", "info", "warn", "err"];

    get headerCls() {
        return "sc-trust-item__header" + (this.hide ? " minimize" : "");
    }
    get summaryStatus() {
        return this.hasSub
            ? this.statuses[Math.max.apply(null, this.childrens.map(item => this.statuses.indexOf(item.status)))]
            : this.statuses[0];
    }
    get hasSub() {
        return this.childrens.length > 0;
    }
    get isGoodSub() {
        if (this.hasSub) {
            const allStatuses = this.childrens.every(function(item) {
                return item.status === "good";
            });
            return allStatuses;
        } else return false;
    }
    get subStatuses() {
        return this.childrens;
    }
    get hide() {
        if (this.minimizeIsForced) {
            return this.minimize;
        } else {
            return this.isGoodSub;
        }
    }
    set hide(val) {
        this.minimizeIsForced = true;
        this.minimize = val;
    }
    get loaded() {
        if (this.isConnected) {
            if (this.status) {
                return true;
            } else if (this.hasSub) {
                return (
                    this.childrens.filter(function(item) {
                        return !!item.status;
                    }).length === this.childrens.length
                );
            } else {
                return false;
            }
        }
    }
    doMinimize() {
        this.hide = !this.hide;
    }
    connectedCallback() {
        this.isConnected = true;
    }
}