import { LightningElement, track } from "lwc";
import SC_chat from "@salesforce/label/c.SC_chat";

export default class ScChatbutton extends LightningElement {
    @track showSnapIns = false;
    label = {
        SC_chat
    };
    iconName = 'comment-regular';
    click(e) {
        e.preventDefault();
        if(window.app) window.app.chatClick();
    }

    get icon() {
        return '#sc-icons-' + this.iconName + '-1';
    }

    constructor() {
        super();
        window.addEventListener("scPageSettings",({detail})=>{
            this.showSnapIns = detail.showSnapIns;
        });
    }
}