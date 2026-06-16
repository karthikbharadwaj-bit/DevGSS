import { LightningElement } from 'lwc';
import getReportInformation from '@salesforce/apex/LeadCPUMonitorHelper.getReportInformation';
import getSOQLReportInformation from '@salesforce/apex/LeadCPUMonitorHelper.getSOQLReportInformation';
import getCPUMonitorsFilteredByDays from '@salesforce/apex/LeadCPUMonitorHelper.getCPUMonitorsFilteredByDays';

const YELLOW = '#FFB75D';
const RED = '#C23934';
const TRANSPARENT = 'rgba(0, 0, 0, 0)';

export default class CpuMonitorContainer extends LightningElement {
    selectedObject = 'Lead';
    selectedDays = '7';

    gaugeChartCreationInfo = {};
    gaugeChartUpdateInfo = {};
    gaugeChartLeadConversionInfo = {};

    barChartCreationInfo = {};
    barChartUpdateInfo = {};
    barChartLeadConversion = {};

    dataCreation;
    dataUpdate;
    leadConversionData;
    leadConversionSOQLData;

    creationDates = [];
    updateDates = [];
    cpuLeadConversionDates = [];
    soqlLeadConversionDates = [];

    creationValues = [];
    updateValues = [];
    cpuLeadConversionValues = [];
    soqlLeadConversionValues = [];

    displayChart = false;
    displayLeadConversion = false;
    displayCPUupdate = false;

    cpuMonitorsForListView = [];

    sortedDirection = 'desc';
    sortedBy = 'CreatedDate';

    isLeadConversion = false;
    
    get notDisplayChart() {
        return !this.displayChart;
    }

    get totalCPUUsageLeadConversion() {
        return this.cpuLeadConversionValues.length > 0 ? 
        Math.round(this.cpuLeadConversionValues.reduce((pv,cv) => pv + cv) / this.cpuLeadConversionValues.length) : 
        0;
    }

    get totalSOQLLeadConversion() {
        return this.soqlLeadConversionValues.length > 0 ? 
        this.soqlLeadConversionValues.reduce((pv,cv) => pv > cv ? pv : cv) : 
        0;
    }

    get totalCPUUsageCreation() {
        return this.creationValues.length > 0 ? 
            Math.round(this.creationValues.reduce((pv,cv) => pv + cv) / this.creationValues.length) : 
            0;
    }

    get totalCPUUsageUpdate() {
        return this.updateValues.length > 0 ? 
            Math.round(this.updateValues.reduce((pv,cv) => pv + cv) / this.updateValues.length) : 
            0;
    }

    get objectOptions() {
        return [
            { label: 'Lead', value: 'Lead' },
            { label: 'Contact', value: 'Contact' },
            { label: 'Case', value: 'Case' },
            { label: 'Lead Conversion', value: 'Lead Conversion'}
        ];
    }

    get labelLastDays() {
        return `LAST ${this.selectedDays} DAYS`
    }

    get dayOptions(){
        return [
            { label: '7 Days', value: 7},
            { label: '15 Days', value: 15},
            { label: '30 Days', value: 30},
            { label: '3 Months', value: 90},
            { label: '6 Months', value: 180},
            { label: '12 Months', value: 365},
        ]
    }

    getValues(data) {
        const infoValues = {
            labels : [],
            values: []
        };

        for (var i = 0; i < (data.groupingsDown.groupings.length); i++) {
            //Iterate and prepare the list of Labels for the chart
            var labelItem = data.groupingsDown.groupings[i].label;
            var keyTemp = data.groupingsDown.groupings[i].key;
            //Prepeare the chart data to be plotted.
            var valueTemp = data.factMap[keyTemp + "!T"].aggregates[0].value;
            infoValues.values.push(valueTemp);
            infoValues.labels.push(labelItem);
        }
        return infoValues;
    }

    updateGaugeChartInfo() {
        if (this.isLeadConversion) {
            this.gaugeChartCreationInfo = {
                value : this.totalCPUUsageLeadConversion,
                title : `${this.selectedObject} CPU Performance`,
                height: '220px',
                width: '440px',
                limits : [8000, 10000, 15000],
                align: [335, 2, 60],
                offset:[136, 37, 81]
            };
            
            this.gaugeChartLeadConversionInfo = {
                value : this.totalSOQLLeadConversion,
                title : `${this.selectedObject} SOQL Queries`,
                height: '220px',
                width: '440px',
                limits : [90, 100, 110],
                align: [196, 30, 48],
                offset:[-220, 17, 18]
            };
        } else {
            this.gaugeChartCreationInfo = {
                value : this.totalCPUUsageCreation,
                title : `${this.selectedObject} Creation Performance`,
                height: '220px',
                width: '440px',
                limits : [8000, 10000, 15000],
                align: [335, 2, 60],
                offset:[136, 37, 81]
            };
            
            this.gaugeChartUpdateInfo = {
                value : this.totalCPUUsageUpdate,
                title : `${this.selectedObject} Update Performance`,
                height: '220px',
                width: '440px',
                limits : [8000, 10000, 15000],
                align: [335, 2, 60],
                offset:[136, 37, 81]
            };
        }
    }

    loadData() {
        if (this.isLeadConversion) {
            const cpuMonitorData = JSON.parse(this.leadConversionData);
            const soqlMonitorData = JSON.parse(this.leadConversionSOQLData);
            if (cpuMonitorData?.groupingsDown?.groupings !== null) {
                const infoCPU = this.getValues(cpuMonitorData);
                this.cpuLeadConversionValues = infoCPU.values;
                this.cpuLeadConversionDates = infoCPU.labels;
            } else {
                this.cpuLeadConversionValues = [];
                this.cpuLeadConversionDates = [];
            }
            if (soqlMonitorData?.groupingsDown?.groupings !== null) {
                const infoSOQL = this.getValues(soqlMonitorData);
                this.soqlLeadConversionValues = infoSOQL.values;
                this.soqlLeadConversionDates = infoSOQL.labels;
            } else {
                this.soqlLeadConversionValues = [];
                this.soqlLeadConversionDates = [];
            }
        } else {
            const dataCreation = JSON.parse(this.dataCreation);
            const dataUpdate   = JSON.parse(this.dataUpdate);
    
            if (dataCreation?.groupingsDown?.groupings !== null) {
                const infoCreation = this.getValues(dataCreation);
                this.creationValues = infoCreation.values;
                this.creationDates = infoCreation.labels;
            } else {
                this.creationDates = [];
                this.creationValues = [];
            }
            if (dataUpdate?.groupingsDown?.groupings !== null) {
                const infoUpdate = this.getValues(dataUpdate);
                this.updateValues = infoUpdate.values;
                this.updateDates = infoUpdate.labels;
            } else {
                this.updateValues = [];
                this.updateDates = [];
            }
        }

        this.updateGaugeChartInfo();
        this.updateBarChartInfo();
    }

    updateBarChartInfo() {
        if (this.isLeadConversion) {
            this.barChartCreationInfo = {
                infoValues : {
                    labels: this.cpuLeadConversionDates,
                    values: this.cpuLeadConversionValues
                },
                title : `${this.selectedObject} CPU Usage`,
                height: '240px',
                width: '90%',
                label: 'CPU Usage',
                labelString: 'CPU Usage (ms)',
                suggestedMax: 15000,
                gridLineColors: [TRANSPARENT, TRANSPARENT, TRANSPARENT, RED, YELLOW],
                lineWidth: [0,0,0, 3, 1]
            };
            this.barChartUpdateInfo = {
                infoValues : {
                    labels: this.soqlLeadConversionDates,
                    values: this.soqlLeadConversionValues
                },
                title : `${this.selectedObject} SOQL Queries`,
                height: '240px',
                width: '90%',
                label: 'SOQL Queries',
                labelString: 'SOQL Queries',
                suggestedMax: 100,
                gridLineColors: [RED, YELLOW, TRANSPARENT],
                lineWidth: [3, 1, 0]
            };

        } else {
            const maxCreationValue = this.creationValues.length > 0 ? Math.max.apply(null, this.creationValues) : 0;
            const maxUpdateValue = this.updateValues.length > 0 ? Math.max.apply(null, this.updateValues) : 0;
            let gridLineCreationColors = [RED, YELLOW];
            let gridLineCreationWidth = [3, 1];
            let gridLineUpdateColors = [RED, YELLOW];
            let gridLineUpdateWidth = [3, 1];
            for (let i = 10000; i < maxCreationValue; i += 2000) {
                gridLineCreationColors.unshift(TRANSPARENT);
                gridLineCreationWidth.unshift(0);
            }
            for (let i = 10000; i < maxUpdateValue; i += 2000) {
                gridLineUpdateColors.unshift(TRANSPARENT);
                gridLineUpdateWidth.unshift(0);
            }
            this.barChartCreationInfo = {
                infoValues : {
                    labels: this.creationDates,
                    values: this.creationValues
                },
                title : `${this.selectedObject} Creation CPU Usage`,
                height: '240px',
                width: '90%',
                label: 'CPU Usage',
                labelString: 'CPU Usage (ms)',
                suggestedMax: 10000,
                gridLineColors: gridLineCreationColors,
                lineWidth: gridLineCreationWidth
            };
            
            this.barChartUpdateInfo = {
                infoValues : {
                    labels: this.updateDates,
                    values: this.updateValues
                },
                title : `${this.selectedObject} Update CPU Usage`,
                height: '240px',
                width: '90%',
                label: 'CPU Usage',
                labelString: 'CPU Usage (ms)',
                suggestedMax: 10000,
                gridLineColors: gridLineUpdateColors,
                lineWidth: gridLineUpdateWidth
            };
        }
    }

    async handleOnChangeCombobox(e) {
        this.showCharts(false);
        this.selectedObject = e.target.value;
        this.isLeadConversion = this.selectedObject === 'Lead Conversion';
        await this.loadCPUMonitorDataFromApex();
        await this.loadListViewInfo();
        this.loadData();
        this.showCharts(true);
    }

    async handleChangeSelectedDay(e) {
        this.showCharts(false);
        this.selectedDays = e.detail.value;
        await this.loadCPUMonitorDataFromApex();
        await this.loadListViewInfo();
        this.loadData();
        this.showCharts(true);
    }

    async handleChangeSort(event) {
        this.sortedDirection = event.detail.sortedDirection;
        this.sortedBy = event.detail.sortedBy;
        await this.loadListViewInfo();
    }

    async loadCPUMonitorDataFromApex() {
        const sobject = this.selectedObject;
        const days = this.labelLastDays;
        if (this.isLeadConversion) {
            this.leadConversionData = await getReportInformation({transactionType: sobject, days});
            this.leadConversionSOQLData = await getSOQLReportInformation({days});
        } else {
            this.dataCreation = await getReportInformation({transactionType: sobject + ' Creation', days});
            this.dataUpdate = await getReportInformation({transactionType: sobject + ' Update', days});
        }
    }

    async loadListViewInfo(){
        this.cpuMonitorsForListView = await getCPUMonitorsFilteredByDays({
            days: this.selectedDays, 
            wantedsObject: this.selectedObject,
            orderBy:this.sortedBy,
            sortDirection: this.sortedDirection
        })
    }

    async connectedCallback() {
        await this.loadCPUMonitorDataFromApex();
        await this.loadListViewInfo();
        
        this.loadData();
        
        this.showCharts(true);
    }

    showCharts(show) {
        if (show) {
            if (this.isLeadConversion) {
                this.displayLeadConversion = true;
            } else {
                this.displayCPUupdate = true;
            }
            this.displayChart = true;
        } else {
            this.displayChart = false;
            this.displayLeadConversion = false;
            this.displayCPUupdate = false;
        }
    }
}