import { LightningElement, track } from 'lwc';

export default class QtcMetrics extends LightningElement {

    @track tabs = {
        quotes: true,
        cases: false,
    };

    get tabsToDisplay() {
        const tabArray = [];

        for (const key in this.tabs) {
            tabArray.push({ 
                label: key.charAt(0).toUpperCase() + key.slice(1),
                index: key,
                class: `tab${this.tabs[key] ? ' active' : ''}` 
            });
        }

        return tabArray;
 
    }

    activateTab(event) {
        Object.keys(this.tabs).forEach(key => {
            this.tabs[key] = false;
          });
        
        this.tabs[event.currentTarget.dataset.tab] = true;

    }
}