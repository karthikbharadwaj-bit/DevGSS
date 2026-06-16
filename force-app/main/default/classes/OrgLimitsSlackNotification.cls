/**
 * Checks single email org limits and post Slack notifications if needed
 * @author Ivan Vdovin
 * @version 1.0
*/
public class OrgLimitsSlackNotification {

    /**
     * Message class with a text property to use Slack webhooks format: {"text": "This is a line of text."})
     */
    @testVisible
    private class SlackJson {

        /* Text for a Slack message */
        private String text;

        /**
        * Constructor - create a new object with a specific value
        * @param text - Slack message text
        */
        public SlackJson(String text) {
            this.text = text;
        }
    }

    /**
     * Class containing all the elements of an instance of System.OrgLimit: {"name": name, "value": value, "maxValue": limit}
     */
    public class OrgLim {

        public String name;
        public Integer value;
        public Integer maxValue;

        /**
        * Constructor - creates a new object with the values of all the methods of System.OrgLimit
        * @param name - corresponds to getName()
        * @param value - corresponds to getValue()
        * @param maxValue - corresponds to getLimit()
        */
        public OrgLim(String name, Integer value, Integer maxValue) {
            this.name = name;
            this.value = value;
            this.maxValue = maxValue;
        }
    }

    /**
     * OrgLims class containing a list of all the OrgLim objects, representing the answer of executing OrgLimits.getAll()
     */
    public class OrgLims {

        public List<OrgLim> elems = new List<OrgLim>();

        /**
        * Constructor - creates a new object with a list of all the organization limits
        */
        public OrgLims() {
            Map<String, System.OrgLimit> limitsMap = Test.isRunningTest() ? new Map<String,System.OrgLimit>() : OrgLimits.getMap();

            for (String key : limitsMap.keySet()) {
                elems.add(new OrgLim(key, limitsMap.get(key).getValue(), limitsMap.get(key).getLimit()));
            }
        }
    }

    /**
     * Method for async execution of the slackPostCallout
     */
    @future(callout=true)
    public static void slackPostCalloutAsync(String slackJsonMessage) {
        slackPostCallout(slackJsonMessage);
    }

    /**
     * Method for sending HTTP post callout
     * @param slackJsonMessage - Slack message text
     * @return returns HTTP response
     */
    public static HttpResponse slackPostCallout(String slackJsonMessage) {

        /* Instantiate a new HTTP object */
        Http http = new Http();

        /* Utilize HttpHelper to post HTTP callout with a text from slackJsonMessage
        Require Slack webhooks url (https://hooks.slack.com) to be added to Named Credentials */
        HttpRequest request = HttpHelper.prepareHttpRequest('callout:Slack_Webhooks/services/T0GJ0ACVB/BGLKW8JAW/5QHFXTcZH9rE5HFZnoovss5t', 'POST', slackJsonMessage);

        /* Return the response in HttpResponse object if any */
        HttpResponse response = http.send(request);

        return response;
    }

    /**
     * Checks org limits usage and post notification if needed
     * @param dangerLevelPercentage - define a level of sent emails which require dev team notification
     * @param limits - element containing a list of organization limits (gathered from System.OrgLimits)
     */
    public static void checkLimitsAndSendWebhook(Integer dangerLevelPercentage, OrgLims limits) {

        /* Create a message (will be instanciated later) */
        SlackJson message;

        /* Adds a new line in the Slack message for each limit that exceeds the dangerLevelPercentage*/
        for (OrgLim ol : limits.elems) {
            Decimal currentLevelPercentage = ol.maxValue == 0 ? 0 : Decimal.valueOf(ol.value).divide(ol.maxValue, 2) * 100;

            if (currentLevelPercentage >= dangerLevelPercentage) {
                if (message == null) {
                    /* When it is the first time writing on the message, we add a special header */
                    message = new SlackJson(String.format('<!here> `Achtung! We almost reached some org limits in {0} ({1}):`',
                                                            new List<Object> {UserInfo.getOrganizationName(), URL.getOrgDomainUrl().getHost().substringBefore('.')}));
                }
                message.text += String.format('\n> *{0}* limit: {1}/{2} ({3}%)',
                                                new List<Object> {ol.name, ol.value, ol.maxValue, currentLevelPercentage});
            }
        }

        if (message != null) {
            /* Serialize SlackJson message */
            String slackJsonMessage = JSON.serialize(message);

            /* Call SlackPostCalloutAsync method to post a message */
            OrgLimitsSlackNotification.SlackPostCalloutAsync(slackJsonMessage);
        }
    }
}