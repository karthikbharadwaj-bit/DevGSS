export class Error {
    get isWarning() {
        return this.level === "warning";
    }
    get styleCls() {
        return `slds-notify_toast slds-theme_${this.level}`
    }
    get icon() {
        return `utility:${this.level}`;
    }
    get iconVariant() {
        return this.level === "error" ? "inverse": "";
    }
    get iconText() {
        this.isWarning ? "Warning": "Error"
    }
    get levelNum() {
        return this.isWarning ? 2: 1;
    }
    constructor(id, text, level) {
       this.id = id;
       this.level = level || "error";
       this.text = text || "Something goes wrong";
    }
}