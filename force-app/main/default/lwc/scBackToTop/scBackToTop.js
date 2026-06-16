import { LightningElement, api, track } from "lwc";
import LABEL from "@salesforce/label/c.SC_backToTop";
export default class ScBackToTop extends LightningElement {
    @api selector;
    @api selectorTo;
    @api offset;
    @track scrollClass = "scrollTop";
    eventInit = false;
    label = LABEL;
    get firstLetter() {
        return this.label.charAt(0);
    }
    get subLabel() {
        return this.label.slice(1);
    }
    offsetTop(el) {
        var offset_top = 0;
        if (el.offsetParent) offset_top = this.offsetTop(el.offsetParent);
        offset_top += el.offsetTop;
        return offset_top;
    }
    scrollClick() {
        window.scrollTo({
            top: this.offsetTo,
            behavior: "smooth"
        });
    }
    connectedCallback() {
        const element = document.querySelector(this.selector) || document.querySelector("body");
        this.offset = this.offsetTop(element);
        this.offsetTo = this.selectorTo ? this.offsetTop(document.querySelector(this.selectorTo) || element) : this.offset;
        const this_ = this;
        try {
            window.app.addScrollEvent();
            this.eventInit = true;
        } catch (e) {
            this.eventInit = false;
        }
        document.addEventListener("sc-app_scroll", function() {
            this_.eventInit = true;
            if (window.pageYOffset > this_.offset) {
                this_.scrollClass = "scrollTop show";
            } else this_.scrollClass = "scrollTop";
        });
    }
    eventInitialization() {
        if (!this.eventInit) {
            try {
                window.app.addScrollEvent();
                this.eventInit = true;
            } catch (e) {
                this.eventInit = false;
                const this_ = this;
                setTimeout(function() {
                    this_.eventInitialization();
                }, 300);
            }
        }
    }
    renderedCallback() {
        this.eventInitialization();
    }
}