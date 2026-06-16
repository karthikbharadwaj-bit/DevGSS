import { LightningElement, api } from "lwc";

export default class ScSvgIcon extends LightningElement {
    @api iconName;
    @api size;
    @api width;
    @api height;
    get style() {
        return (this.width? 'width:' + this.width + ';' :'') +
            (this.height? 'height:' + this.height + ';':'');
    }
    get className() {
        return ("sc-icon_" + this.size) || '';
    }
    get icon() {
        return '#sc-icons-' + this.iconName + '-1';
    }
}