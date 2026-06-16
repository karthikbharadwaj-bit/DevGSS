export class Button {
    constructor({ name, variant, label, iconName, iconPosition, callback }, inx) {
        this.name = name || inx;
        this.variant = variant || "neutral";
        this.label = label || "";
        this.iconName = iconName || "";
        this.iconPosition = iconPosition || "";
        this.callback = callback;
        this.id = inx;
    }
}