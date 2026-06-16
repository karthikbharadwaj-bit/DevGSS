import { LightningElement, track } from "lwc";
import getAdminLinks from "@salesforce/apex/TopicRatingController.getAdminLinks";

export default class ScAdminLinks extends LightningElement {
    @track navigation = [];
    @track error;

    errorMessage = "Something goes wrong!";
    toastEventName = "ShowToastEvent";

    pushEvent(name, detail, target) {
        target = target || this;
        const cEvent = new CustomEvent(name, {
            detail
        });
        target.dispatchEvent(cEvent);
    }
    getNavigation() {
        getAdminLinks({ filters: this.filterStr })
            .then(result => {
                if (result.data && result.status === "success") {
                    this.navigation = JSON.parse(JSON.stringify(result.data.links));
                } else {
                    throw new Error(result.messages.map(item => item.message).join("\n"));
                }
            })
            .catch(error => {
                console.error(error);
                this.pushEvent(
                    this.toastEventName,
                    {
                        type: "error",
                        title: this.errorMessage,
                        message: error.message
                    },
                    window
                );
            });
    }
    connectedCallback() {
        this.getNavigation();
    }
}