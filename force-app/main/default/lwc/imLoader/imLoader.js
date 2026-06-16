import { LightningElement, api } from "lwc";

const BASIC_EVENT_NAME = "imLoader";

export default class ImLoader extends LightningElement {
    @api step = 1;
    @api show = false;
    @api count = 1;
    @api current = 0;
    @api inx = 0;

    get percent() {
        return  Math.floor((this.current * 100) / (this.count || 1))
    }
    get percentText() {
        return `${this.percent}%`;
    }
    clear() {
        this.show = false;
        this.count = 1;
        this.current = 0;
    }
    onHandleAction({detail}) {
        switch (detail.action) {
            case "hide":
                this.clear();
                break;
            case "show":
                this.clear();
                this.count = detail.count;
                this.show = true;
                break;
            case "loaded":
                this.current = detail.loaded;
                this.count = detail.count;
                break;
        }
    }
    get eventName() {
        return this.inx ? `${BASIC_EVENT_NAME}-${this.inx}`: BASIC_EVENT_NAME;
    }
    connectedCallback() {
        window.addEventListener(this.eventName, this.onHandleAction.bind(this));
    }
}