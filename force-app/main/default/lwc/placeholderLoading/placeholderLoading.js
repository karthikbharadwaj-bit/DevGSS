import { LightningElement, api } from "lwc";

const TYPE_LINE = "line";

export default class PlaceholderLoading extends LightningElement {
    @api type = "line";
    @api width = "100%";
    @api height = "21px";

    get style() {
        return [this.width && `width:${this.width}`, this.height && `height:${this.height}`].filter(Boolean).join(";");
    }

    get isLine() {
        return this.type === TYPE_LINE;
    }
}