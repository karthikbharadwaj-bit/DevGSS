import { LightningElement, api, wire} from 'lwc';
import validateRestrictedData from '@salesforce/apex/EURestrictedNotificationController.validateEURestrictedData';
import hideNotes from '@salesforce/apex/EURestrictedNotificationController.hideNotes';
import getEUBannerMsg from '@salesforce/apex/EURestrictedNotificationController.getEUBannerMsg';

export default class EuRestrictedNotification extends LightningElement {
    @api recordId;
    showNotifcation = false;
    bannerMsg = '';

    // Get the SObjectType and the Fields
    @wire(validateRestrictedData, {
        recordId: '$recordId'
    })
    wiredFieldSetMetadata({
        error,data  
    }) {
        this.isLoading = true;
        if (data && data == true) {
            console.log(':::Data - '+JSON.stringify(data));
            this.showNotifcation = true;
            console.log('::: In Data Show Notification - '+this.showNotifcation);
        } else if (error) {
            console.error('::: error', this.error);
            console.log('::: In Error Show Notification - '+this.showNotifcation);
        }
    }

    /* Below method introduced to retrieve banner msg from custom metadata and bind to html, which was actually 
    hardcoded in html before */ 
    @wire(getEUBannerMsg)
    wiredBannerMsg({error,data})
    {
        if (data) {
            this.bannerMsg = data;
            console.log(':::Data - '+JSON.stringify(data));
        }
        else if(error){
            console.error('::: Error in getEUBannerMsg js method - ', this.error);
            console.log('::: Error in getEUBannerMsg js method -  - '+this.error + 'and the value of bannerMsg - ' + this.bannerMsg );
        }
    }



    @wire(hideNotes, {
        recordId: '$recordId'
    })
    wiredhideNotes({
        error,data  
    }) {
        if (data && data != false) {
            console.error('::: hideNotesUtility inside data', data);
            //To hide the Notes button from the Utility bar upon EU Restricted Profile access
            const style = document.createElement('style');
            style.innerHTML = `
            div[data-component-id='notes_utilityBarNoteList'] {
                display:none;
            }`;
            document.head.appendChild(style);
        }else if (error) {
            console.error('::: hideNotesUtility error', this.error);
        }
    }

}