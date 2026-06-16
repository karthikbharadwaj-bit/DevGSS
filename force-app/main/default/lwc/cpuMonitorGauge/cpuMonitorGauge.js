import { LightningElement, api } from 'lwc';

export default class CpuMonitorGauge extends LightningElement {
    @api chartInfo;
    percentageSizes = {};
    chartData;

    displayChart = false;
    
    connectedCallback() {
        this.displayChart = false;

        const chartType = 'gauge';
        
        this.chartData = {
            type: chartType,
            data: {
                datasets: [{
                    borderColor:'#000',
                    borderAlign: 'inner',
                    borderWidth:0,
                    data: this.chartInfo.limits,
                    value: this.chartInfo.value > 15000 ? 15000 : this.chartInfo.value,
                    backgroundColor: ['#00716B', '#FFB75D', '#C23934']
                }],
                labels:[ 'test1', 'test2', 'test3']
            },
            options: {
                animation: {
                    animateRotate: false,
                    animateScale: false
                },
                responsive: true,
                cutoutPercentage: 88,
                title : {
                    display:true,
                    padding:-10,
                    fontSize:18
                },
                layout: {
                    padding: {
                        top:15,
                        bottom: 30
                    }
                },
                needle: {
                    radiusPercentage: 1,
                    widthPercentage: 2,
                    lengthPercentage: 60,
                    color: 'rgba(0, 0, 0, 1)'
                },
                valueLabel: {
                    display: true,
                    color: 'rgba(255, 255, 255, 1)',
                    backgroundColor: 'rgba(0, 0, 0, 0.5)',
                },
                plugins: {
                    datalabels: {
                        align: this.chartInfo.align,
                        offset: this.chartInfo.offset,
                        rotation:[0,0,0]
                    }
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