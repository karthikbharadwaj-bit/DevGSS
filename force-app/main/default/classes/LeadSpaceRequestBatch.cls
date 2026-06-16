public class LeadSpaceRequestBatch {
    public List<LeadSpaceRequest> leadSpaceRequests {
        get{
            if(leadSpaceRequests == null){
                leadSpaceRequests = new List<leadSpaceRequest>();
            } 
            return leadSpaceRequests;
        }
        set;
    }

    public String getAPIRequest(){
        String body = '{"data": [';

        for(LeadSpaceRequest leadSpaceRequest : leadSpaceRequests){
            body = body + leadSpaceRequest.getAPIRequest() + ',';
        }

        body = body.removeEnd(',');

        body = body + ']}';

        return body; 
    }
}