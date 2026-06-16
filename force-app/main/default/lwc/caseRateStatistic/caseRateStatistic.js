import { LightningElement, track, wire } from 'lwc';
import getCasesStatistic from '@salesforce/apex/QtcMetricsController.getCasesStatistic';
import getCasesStatisticOptions from '@salesforce/apex/QtcMetricsController.getCasesStatisticOptions';


export default class CaseRateStatistic extends LightningElement {

    @track tableColumns;
    @track tableData = [];

    @track yearFromOptions;
    @track yearToOptions;

    dateFilterOptions = [
        { label: '1 Year', value: '1year' },
        { label: 'Select Year', value: 'selectYear' }
    ];
    yearOptions = [];

    monthQuarterOptions = [
        { label: 'Month', value: 'Month' },
        { label: 'Quarter', value: 'Quarter' },
    ];

    @track caseOriginsOptions = [];

    defaultFilters = {
        caseOrigins: [],
        dateOption: '1year',
        dateRangeFrom: null,
        dateRangeTo: null
    }

    @track applyingFilters = JSON.parse(JSON.stringify(this.defaultFilters));
    @track appliedFilters = JSON.parse(JSON.stringify(this.defaultFilters));

    get showYearOptions () {
        return this.applyingFilters.dateOption != '1year';
    }

    get tableRows() {
        return this.tableData.map((row, index) => {
            return {
                id: `row-${index}`,
                cells: this.tableColumns.map(col => {
                    return {
                        field: col.field,
                        value: row[col.field]
                    };
                })
            };
        });
    }

    get clearButtonClass() {
        return this.isClearDisabled ? 'slds-button slds-button_brand white-button disabled' : 'slds-button slds-button_brand white-button';
    }

    get applyButtonClass() {
        return this.isApplyDisabled ? 'slds-button slds-button_brand disabled' : 'slds-button slds-button_brand';
    }

    get isClearDisabled() {
        return this.deepEqual(          
            JSON.parse(JSON.stringify(this.defaultFilters)), 
            JSON.parse(JSON.stringify(this.applyingFilters))
        );
    }

    get isApplyDisabled() {
        return this.deepEqual(          
            JSON.parse(JSON.stringify(this.applyingFilters)), 
            JSON.parse(JSON.stringify(this.appliedFilters))
        ); 
    }

    @wire(getCasesStatisticOptions)
    retrieveOptions({error, data}) {
        if (data) {
            this.caseOriginsOptions = data.caseOrigins.map(option => ({
                label: option.label,
                value: option.value.replace(/\s/g, ''),
                selected: true
            }));
            this.defaultFilters.caseOrigins = this.appliedFilters.caseOrigins = this.applyingFilters.caseOrigins = data.caseOrigins.map(item => item.label);

            this.loadCasesStatistic(this.defaultFilters);
        } else if (error) {
            console.log('Error retrieving picklist values: ', error);
        }
    }

    connectedCallback() {

        this.initiateOptions();

        this.tableColumns = [    
            { label: 'Date', field: 'rowDate' },
            { label: 'Total Number of Opportunities with quotes', field: 'totalNumberOfOpps' },

            { label: 'Number of cases in OM/DM via "Create a Case" submission (created on this date)', field: 'casesForDD' },
            { label: '% of cases in OM/DM via "Create a Case" submission to the number of opps', field: 'percentOfDDCasesViaCreateACase' },

            { label: 'Number of cases in Sustaining Queue via "Create a Case" (created on this date)', field: 'casesInSustainingQueueViaCreateACase' },
            { label: '% of Cases in Sustaining Queue via "Create a Case" to the number of opps', field: 'percentOfCasesInSustainingQueueViaCreateACase' },
        ];
    }

    initiateOptions() {
        const currentYear = new Date().getFullYear();
        const startYear = 2021;

        for (let year = startYear; year <= currentYear; year++) {
            this.yearOptions.push({ label: String(year), value: String(year) });
        }

        this.yearFromOptions = this.yearToOptions = this.yearOptions;
    }

    async loadCasesStatistic(filterForLoad) {

        if (!filterForLoad) {
            return;
        }

        let startMonthDate, endMonthDate;
        const currentDate = new Date();
        if (filterForLoad.dateOption === '1year') {
            startMonthDate = new Date(currentDate.getFullYear() - 1, currentDate.getMonth(), 1);
            endMonthDate = new Date(currentDate.getFullYear(), currentDate.getMonth(), 0);            
        } else if (filterForLoad.dateOption === 'selectYear' && filterForLoad.dateRangeFrom && filterForLoad.dateRangeTo) {
            const startYear = new Date(filterForLoad.dateRangeFrom).getFullYear();
            const endYear = new Date(filterForLoad.dateRangeTo).getFullYear();
            startMonthDate = new Date(startYear, 0, 1);
            endMonthDate = new Date(endYear, 11, 31);
        }

        if (currentDate <= endMonthDate) {
            endMonthDate = new Date(currentDate.getFullYear(), currentDate.getMonth(), 0);
        }

        let iterMonthDate = startMonthDate;
        while (iterMonthDate <= endMonthDate) {
            const formattedMonth = this.formatDateToYearMonth(iterMonthDate);
            try {
                const { dateRangeFrom, dateRangeTo, dateOption, ...apexFilterForLoad } = filterForLoad;

                const casesData = await getCasesStatistic({ filter: apexFilterForLoad, monthDate: formattedMonth });
                this.tableData.push(casesData);
                console.log(`Data for ${formattedMonth}:`, casesData);

            } catch (error) {
                console.error(`Error for ${formattedMonth}:`, error);
            }

            iterMonthDate.setMonth(iterMonthDate.getMonth() + 1);
        }
    }

    handleDateFilterChange(event) {
        this.applyingFilters.dateOption = event.detail.value;
        this.applyingFilters.dateRangeFrom = this.showYearOptions ? (new Date().getFullYear()).toString() : null;
        this.applyingFilters.dateRangeTo = this.showYearOptions ? (new Date().getFullYear()).toString() : null;
        if (this.showYearOptions) {
            this.yearToOptions = this.yearOptions.filter(option => parseInt(option.value) >= parseInt(this.applyingFilters.dateRangeTo));
        }
    }
    
    handleYearFromFilterChange(event) {
        this.applyingFilters.dateRangeFrom = event.detail.value;
        this.yearToOptions = this.yearOptions.filter(option => parseInt(option.value) >= parseInt(event.detail.value));
    }

    handleYearToFilterChange(event) {
        this.applyingFilters.dateRangeTo = event.detail.value;
        this.yearFromOptions = this.yearOptions.filter(option => parseInt(option.value) <= parseInt(event.detail.value));
    }

    handleOriginsChange(event) {
        this.applyingFilters.caseOrigins = this.createArrayOfSelectedOptions(event.detail);
    }

    handleClearFilters() {
        this.caseOriginsOptions = this.caseOriginsOptions.map(option => ({
            ...option,
            selected: true,
        }));

        this.applyingFilters = JSON.parse(JSON.stringify(this.defaultFilters)); 
    }

    async handleApplyFilters() {
        this.isLoadingData = true;
        this.appliedFilters = JSON.parse(JSON.stringify(this.applyingFilters));
        this.tableData = [];
        await this.loadCasesStatistic(this.applyingFilters);

    }

    deepEqual(objectA, objectB) {
        if (objectA === objectB) {
            return true;
        }
    
        if (typeof objectA !== 'object' || typeof objectB !== 'object') {
            return false;
        }

        const keysA = Object.keys(objectA);
        const keysB = Object.keys(objectB);
        
        if (keysA.length !== keysB.length) {
            return false;
        }
        
        for (const key of keysA) {
            if (!keysB.includes(key) || !this.deepEqual(objectA[key], objectB[key])) {
                return false;
            }
        }
        
        return true;
    }

    createArrayOfSelectedOptions(eventDetail) {
        if (!eventDetail) {
            return;
        }
        const selectedOptions = eventDetail.map(item => item.label);

        if (selectedOptions.includes('Select All')) {
            return [];
        }

        return selectedOptions;
    }

    formatDateToYearMonth(date) {
        const year = date.getFullYear();
        const month = (date.getMonth() + 1).toString().padStart(2, '0');
        return `${year}-${month}`;
    }


}