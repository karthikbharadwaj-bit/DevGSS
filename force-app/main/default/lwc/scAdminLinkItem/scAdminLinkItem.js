import { LightningElement, api } from "lwc";

export default class ScAdminLinkItem extends LightningElement {
    @api title;
    @api description;
    @api icon;
    @api link;
}