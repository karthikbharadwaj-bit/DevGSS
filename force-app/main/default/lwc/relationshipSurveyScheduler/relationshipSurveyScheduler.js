import { LightningElement, track } from 'lwc';
import getRelationshipJobs from '@salesforce/apex/Schedule_Batch_createRelationshipSurvey.getRelationshipJobs';
import scheduleRelationshipSurvey from '@salesforce/apex/Schedule_Batch_createRelationshipSurvey.scheduleBatchcreateRelationshipSurvey';
import deleteJobByCronId from '@salesforce/apex/Schedule_Batch_createRelationshipSurvey.deleteJobByCronId';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
const pillContainerObj =
{
    type: 'icon',
    label: '',
    iconName: 'standard:event',
};
const JOBS_COL = [
    {
        label: 'Job Name',
        fieldName: 'jobDetailName',
        type: 'text',
        sortable: false
    },
    {
        label: 'Next Scheduled Run',
        fieldName: 'NextFireTime',
        type: 'date',
        sortable: false,
        typeAttributes: {
            day: 'numeric',
            month: 'numeric',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit',
            hour12: false
        }
    },
];
export default class RelationshipSurveyScheduler extends LightningElement {
    @track scheduleDatesList = [];
    @track scheduleDatesToDisplay = [];
    @track showTable = false;
    @track noRecordsFound = true;
    @track isLoading = false;
    @track isSubmitted = false;
    @track error;
    @track selectedJobIds = [];
    @track result = '';
    @track scheduleResult = "";
    @track scheduledJobs = [];
    medalliaJobsList ={};
    jobColumns = JOBS_COL;

    @track isModalOpen = false;
    @track disableAbortBtn = false;
    @track abortSubStr = 'Jobs';
    onLoadSearch = true;
    overlappingQuarters = new Map();


    get minDate() {
        return this.formatMinDate();
    }

    get showDatesList() {
        return this.scheduleDatesList.length > 0;
    }

    get disableSubmitBtn() {
        return this.scheduleDatesList.length <= 0;
    }

    get showAbortBtn() {
        return this.selectedJobIds.length > 0
    }

    connectedCallback() {
        this.getRelationshipSurveyJobs(false);
    }

    handleDateChange(event) {
        var value = event.target.value;
        var minDate = this.minDate;
        this.scheduleResult = "";
        var isDuplicateDate = false;
        const [year, quarter] = this.deconstructDateIntoYearQuarter(value);
        // Restrict inputing more than one date for a quarter
        // Temporarily commented for testing
        this.scheduleDatesList.forEach(date => {
            const [selectedYear, selectedQtr] = this.deconstructDateIntoYearQuarter(date);
            if (year == selectedYear && quarter == selectedQtr) isDuplicateDate = true;
        })
        if (isDuplicateDate) event.currentTarget.setCustomValidity("Cannot add multiple dates for the same quarter");
        else event.currentTarget.setCustomValidity("");
        
        event.currentTarget.reportValidity();
        this.scheduleResult = "";
        if (!this.scheduleDatesList.includes(value) && value >= minDate && !isDuplicateDate) {
            this.scheduleDatesList.push(value);
            this.constructDatesToDisplay(value);
        }
        if (value >= minDate && !isDuplicateDate) {
            this.template.querySelector("lightning-input").value = '';
        }
        //console.log('scheduleDatesList ' + this.scheduleDatesList.toString());
    }

    constructDatesToDisplay(scheduleDate) {
        var item = Object.create(pillContainerObj);
        item.label = scheduleDate;
        this.scheduleDatesToDisplay.push(item);
    }

    handleDateRemove(event) {
        const index = event.detail.index;
        this.scheduleDatesToDisplay.splice(index, 1);
        this.scheduleDatesList.splice(index, 1);
        if (this.isSubmitted) this.validateScheduleDates(); // Temporarily commented for testing
    }

    validateScheduleDates() {
        let scheduledQuarterMap = new Map();
        let overlappingQuarters = new Map();
        try {
            for (let job of this.scheduledJobs) {
                const [year, quarter] = this.deconstructDateIntoYearQuarter(job.NextFireTime);

                if (!scheduledQuarterMap.has(year)) {
                    scheduledQuarterMap.set(year, [quarter]);
                }
                let temp = scheduledQuarterMap.get(year);
                if (!temp.includes(quarter)) {
                    temp.push(quarter);
                }
                scheduledQuarterMap.set(year, temp);
            }

            for (let inputDt of this.scheduleDatesList) {
                const [year, quarter] = this.deconstructDateIntoYearQuarter(inputDt);

                if (!scheduledQuarterMap.has(year)) {
                    scheduledQuarterMap.set(year, []);
                }
                let temp = scheduledQuarterMap.get(year);
                if (!temp.includes(quarter)) {
                    temp.push(quarter);
                } else { // if quarter is already added then date overlaps
                    let quarterDateMap = new Map();
                    if (!overlappingQuarters.has(year)) {
                        quarterDateMap.set(quarter, []);
                        overlappingQuarters.set(year, quarterDateMap);
                    }
                    let temp = overlappingQuarters.get(year); // temp - map of quarter - arr of dates
                    if (!temp.has(quarter)) {
                        temp.set(quarter, []);
                    }
                    temp.get(quarter).push(inputDt);
                    overlappingQuarters.set(year, temp);
                }
                scheduledQuarterMap.set(year, temp);
            }
            // if (overlappingQuarters.size > 0) 
            this.constructErrorMsgForOverlappingQtr(overlappingQuarters);
            this.overlappingQuarters = overlappingQuarters;
        } catch (err) {
            console.log(err);
        }
        //console.log(overlappingQuarters + "overlappingQuarters!!!!!");
        return overlappingQuarters.size <= 0;
    }

    deconstructDateIntoYearQuarter(inputDt) {
        let dt = new Date(inputDt);
        let month = dt.getMonth();
        let year = dt.getFullYear();
        let quarter = this.getQuarterForMonth(month);
        return [year, quarter];
    }

    getQuarterForMonth(month) {
        return Math.floor(month / 3 + 1);
    }

    constructErrorMsgForOverlappingQtr(overlappingQuarters) { // overlappingQuarters is a map inside a map with key - year, value - map -> key - quarter , val - array of dates
        let errMsg = '';
        for (let key of overlappingQuarters.keys()) {
            //console.log(key + ' Key#########');
            let valueMap = overlappingQuarters.get(key);
            let quarters = Array.from(valueMap.keys());
            //console.log(quarters + ' value ###########');

            let baseStr = 'Job is ';
            if (quarters.length > 1) baseStr = "Jobs are ";
            let qtrBaseStr = (quarters.length == 1 ? "Quarter " : "Quarters ");

            if (quarters.length > 0) {
                if (errMsg != '') {
                    errMsg = errMsg + ", " + qtrBaseStr + quarters.join(", ") + " for the year " + key;
                } else
                    errMsg = baseStr + "already scheduled for the " + qtrBaseStr + quarters.join(", ") + " for the Year " + key;
            }
        }
        if (errMsg == '') this.isSubmitted = false;
        this.result = errMsg;
    }

    handleSubmit() {
        this.isSubmitted = true;
        if (!this.validateScheduleDates()) return;
        //console.log("Scheduling the jobs !!!!!!");
        this.scheduleResult = "";
        this.onLoadSearch = false;
        scheduleRelationshipSurvey({ dates: this.scheduleDatesList })
            .then(data => {
                //console.log(data);
                let errDates = [];
                let errDatesStr = '';
                if (data != null && data != undefined) {
                    let resultMap = new Map(Object.entries(data));
                    if (resultMap.size != this.scheduleDatesList.length) {
                        for (let jobDate of resultMap.keys()) {
                            if (data[jobDate] == null) {
                                errDates.push(jobDate);
                            }
                        }
                        errDatesStr = errDates.join(", ");
                        if (errDatesStr != '') this.scheduleResult = "Unable to schedule on " + errDatesStr;
                    } else this.scheduleResult = "";
                } else this.scheduleResult = "";
                this.resetDates();
                this.getRelationshipSurveyJobs(true);
                this.isSubmitted = false;
            })
            .catch(error => {
                if (error.body != undefined) this.scheduleResult = error.body.message;
                else this.scheduleResult = 'Error Occured while scheduling!';
                console.log(error);
                this.resetDates();
                this.isSubmitted = false;
            })
    }

    resetDates() {
        this.scheduleDatesList = [];
        this.scheduleDatesToDisplay = [];
        this.selectedJobIds = [];
    }

    getRelationshipSurveyJobs(isSubmitted) {
        //console.log('Getting Scheduled Jobs...');
        if ((typeof isSubmitted == 'boolean') && !isSubmitted) {
            this.showTable = false;
        } else if (this.onLoadSearch && this.scheduledJobs) {
            this.showTable = true;
            return;
        } else {
            this.showTable = true;
            this.isLoading = true;
        }
        getRelationshipJobs()
            .then(data => {
                let result = JSON.parse(JSON.stringify(data));
                this.isLoading = false;
                //console.log(data);
                if (data != undefined && data.length > 0) {
                    this.noRecordsFound = false;
                    let jobsList = [];
                    let medalliaJobsList = [];
                    for (let job of result) {
                        if(job.CronJobDetail.Name.indexOf('Medallia') !== -1){
                            let name = job.CronJobDetail.Name.split(" ")[1];
                            if(medalliaJobsList[name]!=null){
                                medalliaJobsList[name].push(job.Id);
                            }else  medalliaJobsList[name] = [job.Id];
                        }else{
                            job['jobDetailName'] = job.CronJobDetail.Name;
                            jobsList.push(job);
                        }
                    }
                    this.scheduledJobs = jobsList;
                    this.medalliaJobsList = medalliaJobsList;
                } else {
                    this.scheduledJobs = [];
                    this.noRecordsFound = true;
                }
            })
            .catch(err => {
                console.log(err);
                this.scheduledJobs = [];
                this.error = err;
                this.noRecordsFound = false;
                this.isLoading = false;
            })
    }

    handleRowSelection(event) {
        let selectedRows = event.detail.selectedRows;
        //console.log(selectedRows + " selected rows@@@@@@@22");
        
        let jobIds = [];
        for(let row of selectedRows){ 
            //console.log(row);
            let name = row.CronJobDetail.Name.split(" ")[1];
            jobIds.push(row.Id);
            jobIds.push(...this.medalliaJobsList[name]);
        };

        this.selectedJobIds = jobIds;
    }

    openConfirmationModal() {
        if (this.selectedJobIds.length > 0) {
            this.abortSubStr = this.selectedJobIds.length == 1 ? 'Job' : 'Jobs';
            this.isModalOpen = true;
        }
    }

    closeModal() {
        this.isModalOpen = false;
    }

    abortSelectedJobs(event) {

        this.disableAbortBtn = true;
        //console.log(JSON.stringify(this.selectedJobIds));
        deleteJobByCronId({ cronIds: this.selectedJobIds })
            .then(data => {
                this.disableAbortBtn = false;
                this.onLoadSearch = false;
                this.getRelationshipSurveyJobs(true);
                this.closeModal();
                this.resetDates();
                this.result = '';
                this.scheduleResult = "";
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'The Scheduled Jobs are aborted successfully.',
                        variant: 'success',
                        mode: 'dismissable',
                    })
                );
            })
            .catch(err => {
                this.disableAbortBtn = false;
                this.closeModal();
                this.result = '';
                this.scheduleResult = "";
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error Occurred. ',
                        message: err.body.message,
                        variant: 'error',
                        mode: 'dismissable',
                    })
                );
            })
    }

    formatMinDate() {
        // var minDate = new Date(new Date().setDate(new Date().getDate() + 1)); // tomorrow
        var minDate = new Date();
        //console.log(minDate + 'Min Date');
        const yyyy = minDate.getFullYear().toString();
        const mm = this.formatWithZero(minDate.getMonth() + 1);
        const dd = this.formatWithZero(minDate.getDate());

        return yyyy + '-' + mm + '-' + dd; // Example: 2019-11-08
    }

    formatWithZero(number) {
        return (number < 10 ? '0' : '') + number.toString();
    }

}