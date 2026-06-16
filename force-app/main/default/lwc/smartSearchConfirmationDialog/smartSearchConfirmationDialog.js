import {LightningElement, api} from 'lwc';

export default class smartSearchConfirmationDialog extends LightningElement {
    @api visible; //used to hide/show dialog
    @api title; //modal title
    @api name; //reference name of the component
    @api message; //modal message
    @api confirmLabel; //confirm button label
    @api cancelLabel; //cancel button label
    @api rejectLabel; //Extra button needed for take ownership action
    @api originalMessage; //any event/message/detail to be published back to the parent component
    @api params;

    //handles button clicks
    handleClick(event){
        //creates object which will be published to the parent component
        let finalEvent = {
            originalMessage: this.originalMessage,
            params: this.params,
            status: event.target.name
        };
        //dispatch a 'buttonclick' event so the parent component can handle it
        this.dispatchEvent(new CustomEvent('buttonclick', {detail: finalEvent}));
    }
}