public class NGBSAPIExceptionHelper {
    public class ExceptionMessage {
        public String requestEndpoint;
        public String responseStatus;
        public String responseBody;

        public ExceptionMessage() {}

        public ExceptionMessage(String requestEndpoint, String responseStatus, String responseBody) {
            this.requestEndpoint = requestEndpoint;
            this.responseStatus = responseStatus;
            this.responseBody = responseBody;
        }

        public ExceptionResponseBody parseResponseBody() {
            if (responseBody == null) {
                return new ExceptionResponseBody();
            }
            try {
                return (ExceptionResponseBody) JSON.deserialize(responseBody, ExceptionResponseBody.class);
            } catch (JSONException e) {
                return createExceptionResponseBody(responseBody);
            }
        }

    }

    public class ExceptionResponseBody {
        public String status;
        public List<ExceptionInfo> messages;
        public String message;

        public ExceptionResponseBody() {}

        public ExceptionResponseBody(String status, List<ExceptionInfo> messages) {
            this.status = status;
            this.messages = messages;
        }
    }

    public class ExceptionInfo {
        public String severity;
        public String message;

        public ExceptionInfo(String severity, String message) {
            this.severity = severity;
            this.message = message;
        }
    }

    public static List<Response.ResponseMessage> handleNGBSAPIException(NGBSAPI.NGBSAPIException e, String label) {
        return formatMessages(
            parseNGBSAPIExceptionMessage(e?.getMessage()).parseResponseBody(),
            label
        );
    }

    private static ExceptionMessage parseNGBSAPIExceptionMessage(String message) {
        if (message == null) {
            return new ExceptionMessage();
        }
        try {
            return (ExceptionMessage) JSON.deserialize(message, ExceptionMessage.class);
        } catch (JSONException e) {
            return createExceptionMessage(message);
        }
    }

    private static List<Response.ResponseMessage> formatMessages(ExceptionResponseBody responseBody, String label) {
        List<Response.ResponseMessage> exceptionInfoMessages = new List<Response.ResponseMessage>();
        if (responseBody.messages != null) {
            for (ExceptionInfo infoMessage : responseBody.messages) {
                exceptionInfoMessages.add(
                    new Response.ResponseMessage(
                        label, infoMessage.message, infoMessage.severity
                    )
                );
            }
        }
        if (responseBody.message != null) {
            exceptionInfoMessages.add(
                new Response.ResponseMessage(
                    label, responseBody.message, Response.SEVERITY_ERROR
                )
            );
        }
        return exceptionInfoMessages;
    }

    private static ExceptionResponseBody createExceptionResponseBody(String message) {
        return new ExceptionResponseBody(
            Response.STATUS_ERROR,
            new List<ExceptionInfo>{new ExceptionInfo(Response.SEVERITY_ERROR, message)}
        );
    }

    private static ExceptionMessage createExceptionMessage(String message) {
        return new ExceptionMessage(
            null,
            Response.STATUS_ERROR,
            JSON.serialize(createExceptionResponseBody(message))
        );
    }
}