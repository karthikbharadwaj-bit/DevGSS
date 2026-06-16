import { LightningElement, api } from 'lwc';

export default class CpuMonitorListView extends LightningElement {

    listView;
    get columns() {
        if (this.isLeadConversion) {
            return [
                {fieldName: "linkName", label: "CPU Monitor Name", type:'url', typeAttributes: {
                    label: { 
                        fieldName: 'Name' 
                    }, 
                    target: '_blank'
                }},
                {fieldName: "Transaction_Type__c", label: "Transaction Type", sortable: true},
                {fieldName: "CPU_Usage__c", label: "CPU Usage", sortable: true},
                {fieldName: "SOQL_Queries__c", label: "SOQL Queries", sortable: true},
                {fieldName: "Error__c", label: "Error"},
                {fieldName: "Error_part__c", label: "Error Node"},
                {fieldName: "Lead_Type__c", label: "Lead Record Type"},
                {fieldName: "CreatedDate", label: "Created Date", type :'date', sortable: true, typeAttributes : {
                        year: "numeric",
                        month: "long",
                        day: "2-digit",
                        hour: "2-digit",
                        minute: "2-digit"
                }},
                {fieldName: "Status__c", label: "Status", type: 'image'},
            ]
        } else {
            return [
                {fieldName: "linkName", label: "CPU Monitor Name", type:'url', typeAttributes: {
                    label: { 
                        fieldName: 'Name' 
                    }, 
                    target: '_blank'
                }},
                {fieldName: "Transaction_Type__c", label: "Transaction Type", sortable: true},
                {fieldName: "CPU_Usage__c", label: "CPU Usage", sortable: true},
                {fieldName: "Error__c", label: "Error"},
                {fieldName: "CreatedDate", label: "Created Date", type :'date', sortable: true, typeAttributes : {
                        year: "numeric",
                        month: "long",
                        day: "2-digit",
                        hour: "2-digit",
                        minute: "2-digit"
                }},
                {fieldName: "Status__c", label: "Status", type: 'image'},
            ]
        }
    }
    
    _monitors;
    
    @api sortedDirection = 'desc';
    @api sortedBy = 'CreatedDate';
    @api isLeadConversion;
    loadingData;

    page = 1;
    startingRecord = 1;
    endingRecord = 0; 
    pageSize = 15;

    data;

    get obtainData() {
        this.displayRecordPerPage(this.page);
        return this.data;
    }

    setPageSize(event){
        this.pageSize = event.detail.value > 0 ? event.detail.value : 1;
        this.page = 1;
        this.displayRecordPerPage(this.page);
    }
    
    get totalRecountCount(){
        return this.monitors?.length || 0;
    }

    get totalPage() {
        return Math.ceil(this.totalRecountCount / this.pageSize); 
    }

    @api title;
    @api
    set monitors(value) {
        this._monitors = value;
    }

    get monitors() {
        let newData = JSON.parse(JSON.stringify(this._monitors));
        let monitorsCopy = this.deepClone(newData) || [];
        const hostname = window.location.hostname;
        for (let i=0 ; i < monitorsCopy.length ; i++) {
            const initialIndex = monitorsCopy[i].Status__c.indexOf("src=\"") + 5;
            const endIndex = monitorsCopy[i].Status__c.indexOf("\" ");
            monitorsCopy[i].Status__c = monitorsCopy[i].Status__c.substring(initialIndex, endIndex);
            monitorsCopy[i].linkName = `https://${hostname}/${monitorsCopy[i].Id}`;
        }
        return monitorsCopy;
    }
    
    get disabledPreviousButton() {
        return this.page == 1;
    }

    get disabledNextButton() {
        return this.page == this.totalPage;
    }
   
    get dataAvailable() {
        return this.monitors.length > 0;
    }

    deepClone(obj) {
        if( !obj || true == obj ) {
            return obj;
        } 
        var objType = typeof( obj );
        if( "number" == objType || "string" == objType ) {
            return obj;
        }
        var result = Array.isArray( obj ) ? [] : !obj.constructor ? {} : new obj.constructor();
        if( obj instanceof Map ) {
            for( var key of obj.keys() ) {
                result.set( key, this.deepClone( obj.get( key ) ) );
            }
        }
        for( var key in obj ) {
            if( obj.hasOwnProperty( key ) ) {
                result[key] = this.deepClone( obj[ key ] );
            }
        }
           
        return result;
    }

    
    sortColumns( event ) {
        const changeSort = new CustomEvent('changesort', { 
            detail: {
                sortedBy : event.detail.fieldName,
                sortedDirection : event.detail.sortDirection
            } 
        });

        this.dispatchEvent(changeSort);

        this.loadingData = true;
        setTimeout(() => this.loadingData = false, 500);
    }

    previousHandler() {
        if (this.page > 1) {
            this.page = this.page - 1;
            this.displayRecordPerPage(this.page);
        }
    }
    
    nextHandler() {
        if((this.page < this.totalPage) && this.page !== this.totalPage){
            this.page = this.page + 1;
            this.displayRecordPerPage(this.page);            
        }             
    }
    
    displayRecordPerPage(page) {

        this.startingRecord = ((page -1) * this.pageSize) ;
        this.endingRecord = (this.pageSize * page);

        this.endingRecord = (this.endingRecord > this.totalRecountCount) 
                            ? this.totalRecountCount : this.endingRecord; 

        this.data = this.monitors.slice(this.startingRecord, this.endingRecord);

        this.startingRecord = this.startingRecord + 1;
    }
}