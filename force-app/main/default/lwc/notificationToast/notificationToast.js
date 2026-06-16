import { LightningElement, api} from "lwc";
import { subscribe, unsubscribe, onError } from "lightning/empApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import currentUserId from "@salesforce/user/Id";

const CHANNEL_NAME = "/event/Notification_Toast__e";

export default class NotificationToast extends LightningElement {
    @api recordId;
    subscription = {};

    connectedCallback() {
        const ci = this;
        const toastCallback = function (response) {
            let toastData = response["data"]["payload"];
            if (toastData && toastData["UserId__c"] === currentUserId && toastData["RecordId__c"] === ci.recordId) {
                const toastEvent = new ShowToastEvent({
                    title: toastData["Title__c"],
                    message: toastData["Message__c"],
                    variant: toastData["Variant__c"],
                    mode: toastData["Mode__c"]
                });
                ci.dispatchEvent(toastEvent);
            }
        };

        subscribe(CHANNEL_NAME, -1, toastCallback).then((response) => {
            console.log("Subscribed to Notification Toast");
            this.subscription = response;
        });

        onError((error) => {
            console.log("Error in Notification Toast");
            console.log(error);
        });
    }

    disconnectedCallback() {
        unsubscribe(this.subscription, (response) => {
            console.log("Un-Subscribed from Notification Toast");
            console.log(response);
        });
    }
}