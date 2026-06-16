({
    createChart : function(current, response, xLabels, yValues) {
        if (response.length != 0 && typeof response[0].year_mo__c !== "undefined") {
            response = this.sortByLastModifiedDate(response);
            var counter = 0;
            var priorMonthYear = response[0].year_mo__c.split('-');
            var currentMonthYear;
            var valueToPush;
            do {
                if (counter < response.length) {
                    valueToPush = this.getFieldForChart(current, response, counter);
                    
                    if (response[counter] && response[counter].year_mo__c) {
                        currentMonthYear = response[counter].year_mo__c.split('-');
                    } else {
                        currentMonthYear = 0;
                    }
                    if (counter == 0) {
                        if (valueToPush) {
                            xLabels.unshift(this.formatMonthYear(priorMonthYear));
                            yValues.unshift(valueToPush);
                        } else {
                            response.shift();
                            continue;
                        }
                    } else if (valueToPush
                              && ((this.getMonthNumber(priorMonthYear) - 1 === this.getMonthNumber(currentMonthYear)
                                  && this.getMonthNumber(priorMonthYear) !== 1)
                                || (this.getMonthNumber(priorMonthYear) === 1
                                  && this.getMonthNumber(currentMonthYear) === 12)) ) {
                        xLabels.unshift(this.formatMonthYear(currentMonthYear));
                        yValues.unshift(valueToPush);
                        priorMonthYear = currentMonthYear;

                    } else if ((this.getMonthNumber(currentMonthYear) < this.getMonthNumber(priorMonthYear)
                                && this.getMonthNumber(priorMonthYear) - this.getMonthNumber(currentMonthYear) > 1)
                              || (this.getMonthNumber(currentMonthYear) > this.getMonthNumber(priorMonthYear)
                                && this.getMonthNumber(currentMonthYear) - this.getMonthNumber(priorMonthYear) < 11) ) {

                    counter--;
                    if (priorMonthYear[1] != 1) {
                        if (priorMonthYear < 10) {
                            priorMonthYear[1] = "0" + (this.getMonthNumber(priorMonthYear) - 1);
                        } else {
                            priorMonthYear[1] = this.getMonthNumber(priorMonthYear) - 1;
                        }
                        
                    } else {
                        priorMonthYear[1] = "12";
                        priorMonthYear[0] = priorMonthYear[0] - 1;
                    }
                    xLabels.unshift(this.formatMonthYear(priorMonthYear))
                    yValues.unshift(0)
                    
                	}
                } else {
                    this.fillWithMonthAndYear(xLabels, yValues, priorMonthYear);
                }
                counter++;
            } while (counter < 5 && xLabels.length < 6);

            if (xLabels.length < 6) {
                var lengthDifference = 6 - xLabels.length;
                for (var i = 0; i < lengthDifference; i++) {
                    this.fillWithMonthAndYear(xLabels, yValues, priorMonthYear);
                }
            }
        } else {
            this.fillWithEmptyValues(xLabels, yValues, 6);
        }
    },
    
    sortByLastModifiedDate : function(response){
        var sortedResponse = [];
        var responseLength = response.length;
        for (var i = 0; i < responseLength; i++) {
            for (var j = 0; j < response.length; j++) {
                if (!sortedResponse[i]) {
                    sortedResponse[i] = response[j];
                }
                if (this.getMostRecentlyModified(sortedResponse[i].LastModifiedDate, response[j].LastModifiedDate)
                    && sortedResponse[i].year_mo__c.split('-')[0] == response[j].year_mo__c.split('-')[0]
                    && sortedResponse[i].year_mo__c.split('-')[1] == response[j].year_mo__c.split('-')[1]) {
                        sortedResponse[i] = response[j];
                }
            }
            response.splice(response.indexOf(sortedResponse[i]), 1);
        }
        return sortedResponse;
    },

    fillWithMonthAndYear : function(xLabels, yValues, monthYear) {
        var nextMonth;
        if (this.getMonthNumber(monthYear) !== 1) {
            nextMonth = this.getMonthNumber(monthYear) - 1;
            if (nextMonth < 10) {
                monthYear[1] = "0" + String (nextMonth);
            } else {
                monthYear[1] = nextMonth; 
            }
        } else {
            nextMonth = "12";
            monthYear[1] = nextMonth;
            monthYear[0] = monthYear[0] - 1;
        }
        xLabels.unshift(monthYear[0] + '-' + monthYear[1]);
        yValues.unshift(0);
    },

    fillWithEmptyValues : function(xLabels, yValues, looper) {
        var thisMonth = new Date();
        thisMonth = thisMonth.getMonth() + 1;
        var thisYear = new Date();
        thisYear = thisYear.getFullYear();
        for (var i = 0; i < looper; i++) {
            var constructedMonthYear;
            if (thisMonth != 1) {
                if (i !== 0) {
                    thisMonth--;
                }
                
                if (thisMonth < 10) {
                    thisMonth = "0" + String (thisMonth);
                }
                constructedMonthYear = thisYear + '-' + thisMonth;
            } else {
                thisMonth = "12";
                thisYear = thisYear - 1;
                constructedMonthYear = thisYear + '-' + thisMonth;
            }
            xLabels.unshift(constructedMonthYear)
            yValues.unshift(0);
        }
    },

    getMonthNumber : function(monthYear) {
        return Number (monthYear[1]);
    },

    formatMonthYear : function(splitMonthYear) {
        var formattedMonthYear = splitMonthYear[0] + '-' + splitMonthYear[1];
        return formattedMonthYear;
    },

    getFieldForChart : function(current, response, index) {
        const tollFree = 'Toll Free';
        const agents = 'Agents';
        const rcMeetings = 'RC meetings';
        if (current == 'Billed Minutes' && response[index].cc_num_billed_mins__c) {
            return response[index].cc_num_billed_mins__c;
        } else if (current == tollFree && response[index].tf_mins_used__c) {
            return response[index].tf_mins_used__c;
        } else if (current == agents && response[index].cc_config_agents__c) {
            return response[index].cc_config_agents__c;
        } else if (current == rcMeetings && response[index].LM_Num_Hosts_Exceeded__c) {
            return response[index].LM_Num_Hosts_Exceeded__c;
        } else {
            return 0;
        }
    },
    
    getMostRecentlyModified : function(priorModified, currentModified) {
        if (this.getDateLastModified(priorModified) < this.getDateLastModified(currentModified)) {
            return true;
        } else {
            return false;
        }
    },
    
    getDateLastModified : function(lastModified) {
    	var  relevantNumbers = new Date(lastModified.split(".")[0]);
        return relevantNumbers;
    },
})