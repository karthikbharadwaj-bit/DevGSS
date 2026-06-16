import { LightningElement, api } from 'lwc';

const SELECTED_COLOR = '#0176D3'

export default class ButtonGroup extends LightningElement {
    @api title;
    @api items = [];

    get hasItems() {
        return this.items.length > 0
    }

    handleChangeValue(e) {
        const buttonId = e.currentTarget.dataset.id;
        const changeValue = new CustomEvent('changevalue', { 
            detail: {
                value : buttonId
            } 
        });
        this.dispatchEvent(changeValue);
        const buttons = this.template.querySelectorAll('.slds-checkbox_button');
        for (let i = 0; i < buttons.length; i++) {
            const isSelectedButton = buttons[i].dataset.id === buttonId;
            buttons[i].style.backgroundColor = isSelectedButton ? SELECTED_COLOR : 'transparent';
            buttons[i].style.color = isSelectedButton ? 'white' : SELECTED_COLOR;
        }

    }

    connectedCallback() {
        setTimeout(() => {
            const buttons = this.template.querySelectorAll('.slds-checkbox_button');
            buttons[0].style.backgroundColor = SELECTED_COLOR;
            buttons[0].style.color = 'white';
        }, 500);
    }
}