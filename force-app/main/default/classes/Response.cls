global class Response {
    public static final String STATUS_SUCCESS = 'success';
    public static final String STATUS_WARNING = 'warning';
    public static final String STATUS_INFO = 'info';
    public static final String STATUS_ERROR = 'error';

    public static final String SEVERITY_INFO = 'info';
    public static final String SEVERITY_SUCCESS = 'success';
    public static final String SEVERITY_WARNING = 'warning';
    public static final String SEVERITY_ERROR = 'error';

    public Response () {}

    public Response (String message, String messageDetails , String severity) {
        addMessage(message, messageDetails, severity);
    }

    public Response (List<Response.ResponseMessage> messages) {
        addMessages(messages);
    }

    public Response (Exception e) {
        error(e);
    }

    global class ResponseMessage {

        @AuraEnabled public String severity;
        @AuraEnabled public String message;
        @AuraEnabled public String messageDetails;
        @AuraEnabled public String url;
        @AuraEnabled public String urlLabel;

        public ResponseMessage(String message, String messageDetails, String severity) {
            this.severity = String.isNotBlank(severity) ? severity : SEVERITY_INFO;
            this.message = message;
            this.messageDetails = messageDetails;
        }

        public ResponseMessage(String message, String messageDetails, String severity, String url, String urlLabel) {
            this.severity = String.isNotBlank(severity) ? severity : SEVERITY_INFO;
            this.message = message;
            this.messageDetails = messageDetails;
            this.url = url;
            this.urlLabel = urlLabel;
        }
    }

    @AuraEnabled public String status = STATUS_SUCCESS;
    @AuraEnabled public ResponseMessage[] messages = new List<ResponseMessage>();
    @AuraEnabled public Map<String, Object> data = new Map<String, Object>();
    @AuraEnabled public String stackTrace;
    @AuraEnabled public String typeName;

    /* Set Statuses */
    /* Error */
    public void error(Exception e) {
        this.error(e.getMessage());
        this.stackTrace = e.getStackTraceString();
        this.typeName = e.getTypeName();
    }

    public void error(String message) {
        this.error();
        this.addMessage(message, SEVERITY_ERROR);
    }

    public void error(String message, String messageDetails) {
        this.error();
        this.addMessage(message, messageDetails, SEVERITY_ERROR);
    }

    public void error() {
        this.status = STATUS_ERROR;
    }

    /* Warning */
    public void warning(String message) {
        this.warning();
        this.addMessage(message, SEVERITY_WARNING);
    }

    public void warning(String message, String messageDetails) {
        this.warning();
        this.addMessage(message, messageDetails, SEVERITY_WARNING);
    }

    public void warning() {
        this.status = STATUS_WARNING;
    }
    /* Info */
    public void info(String message) {
        this.info();
        this.addMessage(message, STATUS_INFO);
    }

    public void info(String message, String messageDetails) {
        this.info();
        this.addMessage(message, messageDetails, STATUS_INFO);
    }

    public void info() {
        this.status = STATUS_INFO;
    }


    /* Check statuses */
    public Boolean isError() {
        return this.status == STATUS_ERROR;
    }

    public Boolean isSuccess() {
        return this.status == STATUS_SUCCESS;
    }

    public Boolean isWarning() {
        return this.status == STATUS_WARNING;
    }

    public Boolean isInfo() {
        return this.status == STATUS_INFO;
    }

    /* Messages */
    public void addMessage(String message, String severity) {
        if (message == null) {
            return;
        }
        this.addMessage( new ResponseMessage(message, null, severity) );
    }

    public void addMessage(String message, String messageDetails , String severity) {
        if (message == null) {
            return;
        }
        this.addMessage( new ResponseMessage(message, messageDetails, severity) );
    }

    public void addMessage(SWNMessageHelper.SWNMessage msg) {
        if (String.isBlank(msg.message) && String.isBlank(msg.header)) {
            return;
        }
        this.addMessage(msg.header, msg.message, msg.status);
    }

    public void addMessage(String message, String messageDetails, String severity, String url, String urlLabel) {
        if (message == null) {
            return;
        }
        this.addMessage( new ResponseMessage(message, messageDetails, severity, url, urlLabel) );
    }

    public void addMessage(ResponseMessage resMessage) {
        if (resMessage == null) {
            return;
        }
        this.messages.add(resMessage);
    }
    public void addMessages(ResponseMessage[] resMessages) {
        for (ResponseMessage resMessage : resMessages) {
            this.addMessage(resMessage);
        }
    }

    /* Data */
    public Object getData(String key) {
        return this.data.get(key);
    }

    public void setData(String key, Object data) {
        this.data.put(key, data);
    }

    public void setData(Response r) {
        this.status = r.status;
        this.addMessages(r.messages);
        this.data.putAll(r.data);
    }
}