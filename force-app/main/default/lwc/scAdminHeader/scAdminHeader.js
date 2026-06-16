import { LightningElement, track, api } from "lwc";
import getSupportedLanguages from "@salesforce/apex/TopicRatingController.getSupportedLanguages";

export default class ScAdminHeader extends LightningElement {
    @api changed;
    @api rows;
    @api lang = "en_US";

    @track langs = [{ label: "US", value: "en_US" }];

    smallTitle = "Admin Panel";
    mainTitle = "Support Community";
    defaultMinRows = 1;
    defaultMaxRows = 25;
    errorMessage = "Something goes wrong!";
    toastEventName = "ShowToastEvent";

    get bigTitle() {
        return `${this.mainTitle} ${this.smallTitle}`;
    }
    get isDisabled() {
        return !this.changed;
    }
    get curLangLabel() {
        const curLang = this.langs.find(l => l.value === this.lang);
        return curLang ? curLang.label : "US";
    }
    get messages() {
        return {
            cancel: "Do you want to cancel all your changes?\nYour changes won't be saved.",
            reset: `Do you want Trending Topics for "${this.curLangLabel}" to be set by default?`
        };
    }

    pushEvent(name, detail, target) {
        target = target || this;
        const cEvent = new CustomEvent(name, {
            detail
        });
        target.dispatchEvent(cEvent);
    }
    getLangs() {
        getSupportedLanguages()
            .then(result => {
                if (result.data && result.status === "success") {
                    let buf = [];
                    const keys = Object.keys(result.data).sort();
                    const len = keys.length;
                    for (let i = 0; i < len; i++) {
                        let item = {};
                        item.value = keys[i];
                        item.label = result.data[keys[i]];
                        buf.push(item);
                    }
                    this.langs = buf;
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
    onCancel() {
        if (confirm(this.messages.cancel)) {
            this.dispatchEvent(new CustomEvent("cancel"));
        }
    }
    onReset() {
        if (confirm(this.messages.reset)) {
            this.dispatchEvent(new CustomEvent("reset"));
        }
    }
    onSave() {
        this.dispatchEvent(new CustomEvent("save"));
    }
    langHandleChange(evt) {
        if (this.isDisabled || confirm(this.messages.cancel)) {
            this.pushEvent("languagechange", evt.target.value);
        } else if (!this.isDisabled) {
            const buf = this.lang;
            this.lang = "";
            setTimeout(() => {
                this.lang = buf;
            }, 1);
        }
    }
    handleRowChange(evt) {
        const val = evt.target.value;
        const min = (evt.target.getAttribute("min") * 1) | this.defaultMinRows;
        const max = (evt.target.getAttribute("max") * 1) | this.defaultMaxRows;
        if (val >= min && val <= max) {
            this.pushEvent("rowchange", evt.target.value);
        }
    }
    connectedCallback() {
        this.getLangs();
    }
}