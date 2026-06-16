import { LightningElement,api } from 'lwc';

export default class Paginator extends LightningElement {
    @api currentPage;
    @api lastPage;
    @api disableNextIntialLoad;
    disablePrevious;
    disableNext;
    executed;
   
    constructor(){
        super()
        
    }
    connectedCallback() {       
    }
    
    renderedCallback() {         
        if((this.currentPage == 1 || this.currentPage == undefined) && (this.lastPage != 1 || this.lastPage != undefined)){          
            this.disablePrevious = true;
            this.disableNext = false;
        }else if(this.currentPage < this.lastPage && this.currentPage != this.lastPage){       
            this.disablePrevious = false;
            this.disableNext = false;
        }
        if((this.currentPage >1 && this.currentPage == this.lastPage)){
            this.disableNext = true;
            this.disablePrevious = false;
        }else if(this.currentPage ==1 && this.currentPage == this.lastPage){
            this.disableNext = true;
            this.disablePrevious = true;
        }               
    }

    previousHandler() {
        this.dispatchEvent(new CustomEvent('previous'));
    }

    nextHandler() {
        this.dispatchEvent(new CustomEvent('next'));
    }  
}