({
    scriptsLoaded : function(component, event, helper) {
        const graphType = component.get('v.graphType');
        const billedMinutes = 'Billed Minutes';
        const tollFree = 'Toll Free';
        const agents = 'Agents';
        const rcMeetings = 'RC meetings';
        const billedMinutesTitle = 'Monthly Contact Center Billed Minutes';
        const tollFreeTitle = 'Monthly Toll Free Minutes';
        const agentsTitle = 'Monthly Contact Center Configured Seats';
        const rcMeetingsTitle = '# of Hosts Exceeding Capacity';
        let data = [];
        let action = component.get('c.getUpsellInsightsProductUsages');
        action.setParams({
            accountId: component.get('v.recordId')
        });
        action.setCallback(this, resp => {
            const state = resp.getState();
            if(state == 'SUCCESS'){
                if(resp.getReturnValue() != null){
                    var xLabels = [];
                    var yValues = [];
                    var returnedValues = resp.getReturnValue();

                    helper.createChart(graphType, returnedValues, xLabels, yValues);

                    var graphTitle = '';
                    if(graphType == billedMinutes){
                        graphTitle = billedMinutesTitle;
                    } else if(graphType == tollFree){
                        graphTitle = tollFreeTitle;
                    } else if(graphType == agents){
                        graphTitle = agentsTitle;
                    } else if(graphType == rcMeetings){
                        graphTitle = rcMeetingsTitle;
                    }

                    var ctx = component.find("chart").getElement(); 
                    var chart = new Chart(ctx, {
                        type: 'line',
                        data: {
                            labels: xLabels,
                            datasets: [
                                {
                                    data: yValues,
                                    label: graphTitle,
                                    borderColor: "#7e9ac3",
                                    fill: false
                                }
                            ]
                        },
                        options: {
                            responsive: false,
                            maintainAspectRatio: false,
                            title: {
                                display: false,
                                text: graphTitle
                            },
                            scales: {
                                yAxes: [{
                                    ticks: {
                                        min: 0
                                    }
                                }]
                            },
                            legend: {
                                display: false
                            },
                        }
                    });
                } else {
                    alert('Cannot retrieve chart.');
                }
            } else {
                alert('Cannot retrieve chart.');
            }
        });
        $A.enqueueAction(action);
    },
    init: function (component, event, helper) {
    }
})