import { LightningElement, track } from "lwc";

export default class LwcToasts extends LightningElement {
    timer;
    defaultDuration = 4000;

    @track show = false;
    @track type = "info";
    @track title = "";
    @track message = "";
    @track duration = this.defaultDuration;

    get mainClass() {
        return `slds-notify_container slds-is-fixed ${this.show ? "" : " slds-hide"}`;
    }
    get statusClass() {
        return `slds-notify slds-notify_toast slds-theme_${this.type}`;
    }
    get iconName() {
        return `utility:${this.type}`;
    }
    get iconText() {
        return this.type.charAt(0).toUpperCase() + this.type.slice(1);
    }
    get hasDescription() {
        return this.message.length > 0;
    }

    constructor() {
        super();
        window.addEventListener("ShowToastEvent", this.onShowToastEvent.bind(this));
        window.addEventListener("OnCloseToastEvent", () => this.close());
    }
    close() {
        clearTimeout(this.timer);
        this.show = false;
    }
    onShowToastEvent(event) {
        clearTimeout(this.timer);
        try {
            const eData = JSON.parse(JSON.stringify(event.detail));
            this.type = eData.type || "info";
            this.title = eData.title || "";
            this.message = eData.message || ""; // TODO: make desc 'innerHTML'
            this.show = true; // TODO: animation show / hide
            this.duration = eData.duration !== undefined ? eData.duration : this.defaultDuration;
            if (this.duration) {
                this.timer = setTimeout(() => {
                    this.show = false;
                }, this.duration);
            }

            if (this.hasDescription) {
                const messageContent = this.template.querySelector('.message-content');
                messageContent.innerHTML = `<p>${this.message}</p>`;

                if (eData.link && eData.link.url && eData.link.label) {
                    const linkTag = `<a href="${eData.link.url}" target="_blank">${eData.link.label}</a>`
                    const messageWithLink = this.message.replace(eData.link.label, linkTag)
                    messageContent.innerHTML = `<p>${messageWithLink}</p>`;
                }
            }
        } catch (e) {
            console.error("Wrong event details for toast!", e);
        }
    }
}