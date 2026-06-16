import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
export default class GeneratePDF extends NavigationMixin(LightningElement) {
    _recordId;
    
    @api
    get recordId() {
        return this._recordId;
    }

    set recordId(recordId) {
        if (recordId !== this._recordId) {
            this._recordId = recordId;
        }
    }

    @api invoke(){
        const parameterObjectId = 'objectid='+this._recordId;
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__webPage',
            attributes: {
                url: '/apex/pdfgenerator?'+parameterObjectId
            }
        }).then(generatedUrl => {
            window.open(generatedUrl);
        });
    }
}