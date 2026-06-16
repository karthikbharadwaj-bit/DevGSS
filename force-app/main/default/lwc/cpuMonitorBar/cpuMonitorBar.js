import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { LightningElement, api } from 'lwc';

export default class CpuMonitorBar extends LightningElement {
    @api chartInfo;
    percentageSizes = {};
    chartData;

    displayChart = false;

    connectedCallback() {
        this.displayChart = false;

        const chartType = 'bar';
        
        this.chartData = {
            type: chartType,
            data: {
                labels: this.chartInfo.infoValues.labels,
                datasets: [{
                    label: this.chartInfo.label,
                    data: this.chartInfo.infoValues.values,
                    backgroundColor: '#00A1E0',
                    borderColor: '#005170',
                    borderWidth:1
                }]
            },
            options: {
                maintainAspectRatio: false,
                responsive: true,
                plugins: {
                    datalabels: {
                        display: false
                    }
                },
                scales : {
                    yAxes: [{
                        gridLines: {
                            color: this.chartInfo.gridLineColors,
                            lineWidth: this.chartInfo.lineWidth,
                            drawBorder: false
                        },
                        ticks: {
                            beginAtZero: true,
                            stepSize: 2000,
                            suggestedMin:0,
                            suggestedMax:this.chartInfo.suggestedMax
                        },
                        scaleLabel: {
                            display: true,
                            labelString: this.chartInfo.labelString
                        }
                    }],
                    xAxes: [{
                        gridLines: {
                            display:false
                        },
                        barThickness: 20,
                        maxBarThickness: 20
                    }]
                }
            }
        };

        this.percentageSizes = {
            height: this.chartInfo.height,
            width: this.chartInfo.width
        }

        
        this.displayChart = true;
    }

}