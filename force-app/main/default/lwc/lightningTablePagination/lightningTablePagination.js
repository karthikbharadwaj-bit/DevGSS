import { LightningElement, api, track } from "lwc";

const DELAY = 300;
export default class LightningTablePagination extends LightningElement {

    @api showTable = false;
    @api records;
    @api recordsperpage;
    @api columns;

    @track draftValues = [];
    @track recordsToDisplay;

    totalRecords;
    pageNo;
    totalPages;
    startRecord;
    endRecord;
    end = false;
    pagelinks = [];
    isLoading = false;
    defaultSortDirection = 'asc';
    sortDirection = 'asc';
    ortedBy;

    connectedCallback() {
        this.isLoading = true;
        this.setRecordsToDisplay();
        console.log(this.columns);
    }
    setRecordsToDisplay() {
        this.isLoading = true;
        this.totalRecords = this.records.length;
        this.pageNo = 1;
        this.totalPages = Math.ceil(this.totalRecords / this.recordsperpage);
        this.preparePaginationList();
        let recordLimit = this.totalPages <=10 ? this.totalPages: 10;
        for (let i = 1; i <=  recordLimit; i++) {
            this.pagelinks.push(i);
        }
        this.isLoading = false;
    }
    handleClick(event) {
        let label = event.target.label;
        if (label === "First") {
            this.handleFirst();
        } else if (label === "Previous") {
            this.handlePrevious();
        } else if (label === "Next") {
            this.handleNext();
        } else if (label === "Last") {
            this.handleLast();
        }
    }

    handleNext() {
      
        if((this.pagelinks[this.pagelinks.length-1] +1) <= this.totalPages){
            this.pagelinks.shift();
            this.pagelinks.push(this.pagelinks[this.pagelinks.length-1] +1);
        }
         if( ( this.pageNo + 1) <=this.totalPages ){
            this.pageNo += 1;
            this.preparePaginationList();
        }
    }

    handlePrevious() {
        if((this.pagelinks[0] -1) >= 1){
            this.pagelinks.pop();
            this.pagelinks.unshift(this.pagelinks[0] -1);
        }
        if( ( this.pageNo - 1) >=1 ){
            this.pageNo -= 1;
            this.preparePaginationList();
        }
        
    }

    handleFirst() {
        this.pageNo = 1;
        if (this.totalPages >= 10) {
            this.pagelinks = [];
            for (let start = 1; start <= 10; start++) {
                this.pagelinks.push(start);
            }
        }
        this.preparePaginationList();
    }

    handleLast() {
        this.pageNo = this.totalPages;
        if( (this.totalPages -10) >=1){
            this.pagelinks = [];
            for(let start = this.totalPages -10; start<=this.totalPages ;start++){
                this.pagelinks.push(start);
            }
        }
        this.preparePaginationList();
    }
    preparePaginationList() {
        this.isLoading = true;
        let begin = (this.pageNo - 1) * parseInt(this.recordsperpage);
        let end = parseInt(begin) + parseInt(this.recordsperpage);
        this.recordsToDisplay = this.records.slice(begin, end);

        this.startRecord = begin + parseInt(1);
        this.endRecord = end > this.totalRecords ? this.totalRecords : end;
        this.end = end > this.totalRecords ? true : false;

        window.clearTimeout(this.delayTimeout);
        this.delayTimeout = setTimeout(() => {
            this.disableEnableActions();
        }, DELAY);
        this.isLoading = false;
    }

    disableEnableActions() {
        let buttons = this.template.querySelectorAll("lightning-button");

        buttons.forEach(bun => {
            if (bun.label === this.pageNo) {
                bun.disabled = true;
            } else {
                bun.disabled = false;
            }

            if (bun.label === "First") {
                bun.disabled = this.pageNo === 1 ? true : false;
            } else if (bun.label === "Previous") {
                bun.disabled = this.pageNo === 1 ? true : false;
            } else if (bun.label === "Next") {
                bun.disabled = this.pageNo === this.totalPages ? true : false;
            } else if (bun.label === "Last") {
                bun.disabled = this.pageNo === this.totalPages ? true : false;
            }
        });
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row.Id;
        const rowAction = new CustomEvent('actions', {
            detail: { 
                actionName : actionName,
                data : row
            }
        });
        this.dispatchEvent(rowAction);
    }

    handlePage(button) {
        this.pageNo = button.target.label;
        this.preparePaginationList();
    }

    onHandleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.recordsToDisplay];
        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.recordsToDisplay = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }
    sortBy( field, reverse, primer ) {

        const key = primer
        ? function( x ) {
            return primer(x[field]);
        }
        : function( x ) {
            return x[field];
        };

        return function( a, b ) {
            a = key(a);
            b = key(b);
            return reverse * ( ( a > b ) - ( b > a ) );
        };
    }
}