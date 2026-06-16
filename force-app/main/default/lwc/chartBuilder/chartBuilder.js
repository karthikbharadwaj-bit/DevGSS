import { LightningElement, api } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import chartjs from '@salesforce/resourceUrl/chart';

export default class ChartBuilder extends LightningElement {
    
    @api percentageSizes
    chartDataCopy

    @api 
    get chartData() {
        return this._chartData;
    }

    set chartData(value) {
        this._chartData = value;
        this.loadData();
        this.renderChart();
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

    loadData() {
        let newData = JSON.parse(JSON.stringify(this.chartData));
        this.chartDataCopy = this.deepClone(newData);
    }

    async connectedCallback() {
        try {

            await this.loadScripts();
            const ctx = this.template.querySelector('canvas.gaugechart').getContext('2d');
            this.loadData();
            this.chart = new window.Chart(ctx, this.chartDataCopy);

            this.chart.canvas.parentNode.style.height = this.percentageSizes.height;
            this.chart.canvas.parentNode.style.width = this.percentageSizes.width;
            this.chart.canvas.parentNode.style.margin = 'auto';
            this.setStyle();

        } catch(e) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: e,
                    variant: 'error',
                }),
            );
        }
    }

    renderChart() {
        try {
            const ctx = this.template.querySelector('canvas.gaugechart').getContext('2d');
            if (this.chart) {
                // If the chart already exists, destroy it before re-rendering
                this.chart.destroy();
            }
            this.chart = new window.Chart(ctx, this.chartDataCopy);
            this.setStyle();

        } catch(e) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: e,
                    variant: 'error',
                }),
            );
        }
    }

    setStyle() {
        if (this.chart && this.chart.canvas) {
            this.chart.canvas.parentNode.style.height = this.percentageSizes.height;
            this.chart.canvas.parentNode.style.width = this.percentageSizes.width;
            this.chart.canvas.parentNode.style.margin = 'auto';
        }
    }

    async loadScripts() {
        await loadScript(this, chartjs + '/chartjs.bundle.js');
        await loadScript(this, chartjs + '/chartjs-gauge.js');
        await loadScript(this, chartjs + '/chartjs.datalabels.js');
    }
}