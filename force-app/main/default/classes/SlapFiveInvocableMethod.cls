public with sharing class SlapFiveInvocableMethod {

    public class Request {
        @InvocableVariable(required=true)
        public String jsonPayloadList;
    }

    public class Response {
        @InvocableVariable
        public String status;

        @InvocableVariable
        public String jobId;

        @InvocableVariable
        public String message;
    }

    @InvocableMethod(
        label='Send Data to SlapFive (Async)'
        description='Enqueues async callout to SlapFive'
    )
    public static List<Response> createHttpCallout(List<Request> requests) {
        List<Response> responses = new List<Response>();

        for (Request req : requests) {
            Response res = new Response();
            try {
                Id jobId = System.enqueueJob(
                    new SlapFiveQueueable(req.jsonPayloadList)
                );
                res.status = 'Queued';
                res.jobId = String.valueOf(jobId);
                res.message = 'Success';
            } catch (Exception ex) {
                res.status = 'FailedToQueue';
                res.message = ex.getMessage();
            }
            responses.add(res);
        }
        return responses;
    }
}