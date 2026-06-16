import {LightningElement, track, wire} from 'lwc';

import getFilteredData from '@salesforce/apex/QtcMetricsController.getFilteredData';
import getPicklistValues from '@salesforce/apex/QtcMetricsController.getPicklistValues';

export default class QuoteMetricsDashboard extends LightningElement {

    @track isLoading = true;
    @track messages = [];
    @track displayChart = false;

    @track chartsDataBuilder = {};

    defaultPercentageSizes = {
        height: '420px',
        width: '90%'
    };
    
    chartsDataTypeOptions = [
        { label: 'Median', value: 'Median' },
        { label: 'Average', value: 'Average' }
    ];

    @track brandOptions = [];
    @track typeOptions = [];
    @track oppRecordTypeOptions = [];
    @track accountSegmentOptions = [];
    @track yearFromOptions;
    @track yearToOptions;
    yearOptions = [];

    dateFilterOptions = [
        { label: '1 Year', value: '1year' },
        { label: 'Select Year', value: 'selectYear' }
    ];

    monthQuarterOptions = [
        { label: 'Month', value: 'Month' },
        { label: 'Quarter', value: 'Quarter' },
    ];

    chartsData = {};

    defaultFilters = {
        dataType: 'Median',
        dateOption: '1year',
        dateRangeFrom: null,
        dateRangeTo: null,
        brands: [],
        types: [],
        oppRecordTypes: [],
        accountSegments: [],
        lastNDaysApply: false,
        lastNDaysNumber: '3',
        lastNDaysPeriod: 'quarter'
    }

    @track applyingFilters = JSON.parse(JSON.stringify(this.defaultFilters));
    @track appliedFilters = JSON.parse(JSON.stringify(this.defaultFilters));

    get showYearOptions() {
        return this.applyingFilters.dateOption != '1year';
    }

    get nDaysOptions() {
        const options = [];
        for (let i = 1; i <= 30; i++) {
            options.push({ label: i.toString(), value: i.toString(), selected: i.toString() === this.applyingFilters.lastNDaysNumber });
        }
        return options;
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

    get clearButtonClass() {
        return this.isClearDisabled ? 'slds-button slds-button_brand white-button disabled' : 'slds-button slds-button_brand white-button';
    }

    get applyButtonClass() {
        return this.isApplyDisabled ? 'slds-button slds-button_brand disabled' : 'slds-button slds-button_brand';
    }


    @wire(getPicklistValues)
    retrievePicklistValues({error, data}) {
        if (data) {
            this.brandOptions = data.brands.map(option => ({
                label: option.label,
                value: option.value.replace(/\s/g, ''),
                selected: true
            }));

            this.typeOptions = data.types.map(option => ({
                label: option.label,
                value: option.value.replace(/\s/g, ''),
                selected: true
            }));

            this.oppRecordTypeOptions = data.oppRecordTypes.map(option => ({
                label: option.label,
                value: option.value,
                selected: true
            }));

            this.accountSegmentOptions = data.accountSegments.map(option => ({
                label: option.label,
                value: option.value,
                selected: true
            }));
            this.loadFilteredData(this.defaultFilters);
        } else if (error) {
            console.log('Error retrieving picklist values: ', error);
        }
    }

    async connectedCallback() {
        try {
            this.initiateOptions();
        } catch(e) {
            console.log('error occured while init' + e);
        }
    }

    initiateOptions() {
        const currentYear = new Date().getFullYear();
        const startYear = 2021;

        for (let year = startYear; year <= currentYear; year++) {
            this.yearOptions.push({ label: String(year), value: String(year) });
        }

        this.yearFromOptions = this.yearToOptions = this.yearOptions;
    }


    async loadFilteredData(filterForLoad) {

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
            // Format the currentMonth as 'YYYY-MM'
            const formattedMonth = iterMonthDate.toISOString().slice(0, 7);
            try {
                const { dateRangeFrom, dateRangeTo, dateOption, ...apexFilterForLoad } = filterForLoad;
                const quotesData = await getFilteredData({ filter: apexFilterForLoad , monthDate: formattedMonth });
                
                // Update the chartsData map
                quotesData.forEach(chartWrapper => {
                    const chartName = chartWrapper.chartName;
                    const data = chartWrapper.data;

                    if (this.chartsData.hasOwnProperty(chartName)) {
                        const existingData = this.chartsData[chartName];
                        this.chartsData[chartName] = { ...existingData, ...data };
                    } else {
                        this.chartsData[chartName] = data;
                    }
                });
                await this.applyingChartsData();
                this.handleChartLoaded();

            } catch (error) {
                console.error(`Error for ${formattedMonth}:`, error);
            }

            iterMonthDate.setMonth(iterMonthDate.getMonth() + 1);
        }

    }

    async applyingChartsData() {

        if (!this.chartsData || Object.keys(this.chartsData).length === 0) {
            console.log('data was not loaded');
            return
        }

        const optionsQuoteWithoutApprovals = {
            responsive: true,
            maintainAspectRatio: false,
            scales: {
                xAxes: [{
                    ticks: {
                        source: 'data', // Use data labels for ticks
                        maxRotation: 0, // Prevent label overlapping
                        autoSkip: true,
                        autoSkipPadding: 20,
                    },
                    
                }],
                yAxes: [{
                    ticks: {
                        beginAtZero: true,
                        stepSize: this.getStepSize(Object.values(this.chartsData.quotesCountByDateWithoutApprovals), 1),
                    },
                }],
            },
        }

        this.chartsDataBuilder.chartDataQuotesNumberWithoutApprovals = { 
            type: 'bar',
            data: {
                labels: Object.keys(this.chartsData.quotesCountByDateWithoutApprovals), // X-axis labels
                datasets: [{
                    label: 'Number of quotes without approvals',
                    data: Object.values(this.chartsData.quotesCountByDateWithoutApprovals), // Y-axis data
                    backgroundColor: 'rgba(54, 162, 235, 0.6)' // Chart color
                }]
            },
            options: optionsQuoteWithoutApprovals
        };

        let optionsQuoteWithApprovals = JSON.parse(JSON.stringify(optionsQuoteWithoutApprovals));
        optionsQuoteWithApprovals.scales.yAxes[0].ticks.stepSize = this.getStepSize(Object.values(this.chartsData.quotesCountByDateWithApprovals), 1);
        this.chartsDataBuilder.chartDataQuotesNumberWithApprovals = { 
            type: 'bar',
            data: {
                labels: Object.keys(this.chartsData.quotesCountByDateWithApprovals), // X-axis labels
                datasets: [{
                    label: 'Number of quotes with approvals',
                    data: Object.values(this.chartsData.quotesCountByDateWithApprovals), // Y-axis data
                    backgroundColor: 'rgba(54, 162, 235, 0.6)' // Chart color
                }]
            },
            options: optionsQuoteWithApprovals
        };
        

        let optionsTime = JSON.parse(JSON.stringify(optionsQuoteWithoutApprovals));
        optionsTime.scales.yAxes[0].ticks.stepSize = undefined;
        const timeToQuoteWithoutApprovals = this.appliedFilters.dataType == 'Median' ? this.chartsData.medianTimeByDateMapWithoutApprovals : this.chartsData.averageTimeByDateMapWithoutApprovals
        this.chartsDataBuilder.chartDataTimeToQuoteWithoutApprovals = { 
            type: 'bar',
            data: {
                labels: Object.keys(timeToQuoteWithoutApprovals), // X-axis labels
                datasets: [{
                    label: 'Quoting time (hours)',
                    data: Object.values(timeToQuoteWithoutApprovals), // Y-axis data
                    backgroundColor: 'rgba(54, 162, 235, 0.6)' // Chart color
                }]
            },
            options: optionsTime
        };

        const timeToQuoteWithApprovals = this.appliedFilters.dataType == 'Median' ? this.chartsData.medianTimeByDateMapWithApprovals : this.chartsData.averageTimeByDateMapWithApprovals
        this.chartsDataBuilder.chartDataTimeToQuoteWithApprovals = { 
            type: 'bar',
            data: {
                labels: Object.keys(timeToQuoteWithApprovals), // X-axis labels
                datasets: [{
                    label: 'Quoting time (hours)',
                    data: Object.values(timeToQuoteWithApprovals), // Y-axis data
                    backgroundColor: 'rgba(54, 162, 235, 0.6)' // Chart color
                }]
            },
            options: optionsTime
        };

        this.showCharts(true);
    }


    handleChartLoaded() {
        this.isLoading = false;
    }

    handleDataTypeFilterChange(event) {
        this.applyingFilters.dataType = event.detail.value;
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

    handleBrandChange(event) {
        this.applyingFilters.brands = this.createArrayOfSelectedOptions(event.detail);
    }
    
    handleTypeChange(event) {
        this.applyingFilters.types = this.createArrayOfSelectedOptions(event.detail);
    }

    handleOppRecordTypeChange(event) {
        this.applyingFilters.oppRecordTypes = this.createArrayOfSelectedOptions(event.detail);
    }

    handleSegmentChange(event) {
        this.applyingFilters.accountSegments = this.createArrayOfSelectedOptions(event.detail);
    }

    handleNDaysChange(event) {
        this.applyingFilters.lastNDaysNumber = event.target.value;
    }

    handleMonthQuarterChange(event) {
        this.applyingFilters.lastNDaysPeriod = event.target.value;
    }

    handleShowNDaysCheckboxChange(event) {
        this.applyingFilters.lastNDaysApply = event.target.checked;
    }

    handleClearFilters() {
        this.applyingFilters = JSON.parse(JSON.stringify(this.defaultFilters)); 

        this.brandOptions = this.brandOptions.map(option => ({
            ...option,
            selected: true,
        }));

        this.typeOptions = this.typeOptions.map(option => ({
            ...option,
            selected: true,
        }));

        this.oppRecordTypeOptions = this.oppRecordTypeOptions.map(option => ({
            ...option,
            selected: true,
        }));

        this.accountSegmentOptions = this.accountSegmentOptions.map(option => ({
            ...option,
            selected: true,
        }));
    
    }

    async handleApplyFilters() {
        this.isLoading = true;
        this.appliedFilters = JSON.parse(JSON.stringify(this.applyingFilters));
        this.chartsData = {};
        await this.loadFilteredData(this.applyingFilters);
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

    getStepSize(arrayOfValues, minStepValue) {

        const maxValue = Math.max(...arrayOfValues);
        
        // Calculate the step size
        let stepSize = Math.ceil(maxValue / 10);
        
        // Ensure stepSize is a multiple of 5 without being less than minStepValue
        stepSize = Math.max(Math.round(stepSize / 5) * 5, minStepValue);
        
        return stepSize;
    }

    showCharts(show) {
        if (show) {
            this.displayChart = true;
        } else {
            this.displayChart = false;
        }
    }

    formatDateToYearMonth(date) {
        const year = date.getFullYear();
        const month = (date.getMonth() + 1).toString().padStart(2, '0'); // Adding 1 to month as it's zero-based
        
        return `${year}-${month}`;
    }

}