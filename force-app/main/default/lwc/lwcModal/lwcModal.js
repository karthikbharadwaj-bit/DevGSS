import { LightningElement, track } from "lwc";
import { Button } from "./button";
/**
 * @class lwcModal
 * @classDescription Shows a modal window, with the ability to specify a title, insert html markup, configure displayed buttons
 * @example const callbackValue = await new Promise(resolve => {
 *    const cEvent = new CustomEvent("ShowModalEvent", {
 *        detail: {
 *            title: "My Title",
 *            message: "<div>some text</div><input type="email" name="email" class="slds-input"/>",
 *            callback: val => {
 *                resolve(val);
 *            },
 *            footer: [
 *                {
 *                    name: "ok",
 *                    label: "Ok",
 *                    callback: ({action, values}) => {
 *                      resolve(values);
 *                      },
 *                },
 *                {
 *                    name: "cancel",
 *                    label: "Cancel",
 *                    variant: "neutral",
 *                    callback: ({action, values}) => {
 *                      resolve(false);
 *                      },
 *                },
 *            ],
 *        },
 *    });
 *    window.dispatchEvent(cEvent);
 * });
 * @return {Object} Return {action: "name_of_button", values: [{name:"input_name",value:"input_values"}] } ( if close then return {action:"close"} ) in callback function
 */
export default class LwcModal extends LightningElement {
    @track isOpen = false;
    @track title;
    @track footer;
    @track message = "";
    @track directional = false;

    callback;
    get modalCls() {
        return `slds-modal${this.isOpen ? " slds-fade-in-open" : ""}`;
    }
    get backdropCls() {
        return `slds-backdrop${this.isOpen ? " slds-backdrop_open" : ""}`;
    }
    get headerCls() {
        return `slds-modal__header${!this.hasHeader ? " slds-modal__header_empty" : ""}`;
    }
    get footerCls() {
        return `slds-modal__footer${this.directional ? " slds-modal__footer_directional" : ""}`;
    }
    get hasHeader() {
        return !!this.title;
    }
    get hasFooter() {
        return (!!this.footer) && this.footer.length > 0;
    }
    changeDescription() {
        const contentElement = this.template.querySelector(".slds-modal__content");
        if(contentElement) {
            contentElement.innerHTML = this.message;
        }
    }
    closeForm(noEvent) {
        if (noEvent !== true && this.callback) {
            try {
                this.callback({ action: "close" });
            } catch (e) {
                console.warn(e);
            }
        }
        this.isOpen = false;
    }
    checkMessageInputs() {
        const inputs = [...this.template.querySelectorAll(".slds-modal__content input")];
        if (inputs.length > 0) {
            return {
                values: inputs.map(inp => {
                    return { name: inp.name, value: inp.value };
                }),
            };
        } else return {};
    }
    handleFooterClick(evt) {
        try {
            const btnName = evt.target.name;
            const btnVal = evt.target.value;
            const returnValue = Object.assign({ action: btnName }, this.checkMessageInputs());
            if (!!this.footer[btnVal].callback) {
                this.footer[btnVal].callback(returnValue);
            } else if (!!this.callback) {
                this.callback(returnValue);
            }
        } catch (e) {
            console.warn(e);
        }
        this.closeForm(true);
    }

    constructor() {
        super();
        window.addEventListener("ShowModalEvent", this.onShowModalEvent.bind(this));
    }

    /**
     * @class lwcModal
     * @param {{callback: *, title: *, message: *}}      detail Params for create modal
     * @param {String}      detail.title Title
     * @param {String}      detail.message Message of modal ( can be DOM )
     * @param {Boolean}      detail.directional Makes buttons inside the footer spread to both left and right.
     * @param {Function}    detail.callback Callback function (return value is event name)
     * @param {Object[]}    detail.footer Array of footer buttons (lightning-button)
     * @param {Function}      detail.footer[].callback Callback for button
     * @param {String}      detail.footer[].name Button name
     * @param {String}      detail.footer[].label Button label
     * @param {String}      detail.footer[].variant Button variation ( brand, neutral, outline-brand, inverse, destructive, text-destructive, success)
     * @param {String}      detail.footer[].iconName Button icon (like "lightning-button")
     * @param {String}      detail.footer[].iconPosition Button icon position ("left" | "right")
     *
     */
    onShowModalEvent({ detail = { title, message, callback, directional } }) {
        try {
            this.title = detail.title;
            this.directional = detail.directional;
            this.message = detail.message || "";
            if (detail.footer && Array.isArray(detail.footer)) {
                this.footer = detail.footer.map((btn, inx) => new Button(btn, inx));
            } else {
                this.footer = [];
            }
            this.isOpen = true;
            this.callback = detail.callback;
        } catch (e) {
            console.error("Wrong event details for modal!", e);
        }
        this.changeDescription();


    }
}