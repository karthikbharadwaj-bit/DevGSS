jQuery.noConflict();
(function(j$){

    function OpenInNewTab(url) {
          var win = window.open(url, '_blank');
          win.focus();
    }

    function showCalendarOnPage() {
        j$("div[id$='calendarTimesheet']").fullCalendar({
            header: {
                left: 'prev,next today',
                center: 'title',
                right: 'month,basicWeek,basicDay'
            },
            //defaultDate: '2016-01-12',
            editable: false,
            eventLimit: true, // allow "more" link when too many events
            events: function(start, end, timezone, callback) {
                Visualforce.remoting.Manager.invokeAction(
                    'ILTCalendarController.getEventsJSONforCurrentUser',
                    function(result, event){
                        if (event.status) {
                            callback(JSON.parse(result));
                        } else if (event.type === 'exception') {
                            console.log(event, result);
                        } else {
                        	console.log(event, result);
                        }
                    },
                    {escape: false}
                );
            },
            eventClick : function(event, jsEvent, view) {
                var startHref = window.location.href;
                if (startHref.indexOf('/apex/') > 0) {
                    startHref = startHref.substr(0, startHref.indexOf('/apex/'));
                } else {
                    startHref = "";
                }
                OpenInNewTab(startHref + "/apex/redwing__trainingplandetail?id=" + event.tpId);
            }
        });

    }

    j$(document).ready(function(){
    	showCalendarOnPage();
    });

})(jQuery);
