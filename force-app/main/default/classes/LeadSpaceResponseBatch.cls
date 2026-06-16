public class LeadSpaceResponseBatch {
    public List<LeadSpaceResponse> results {get; set;}
    public String serializedResponse;

    public static LeadSpaceResponseBatch parse(String json) {
        return (LeadSpaceResponseBatch) System.JSON.deserialize(json, LeadSpaceResponseBatch.class);
    }
}