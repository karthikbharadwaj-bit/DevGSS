public class LeadSpaceResponseBatchPolling {
    public String id {get; set;}

    public static LeadSpaceResponseBatchPolling parse(String json) {
        return (LeadSpaceResponseBatchPolling) System.JSON.deserialize(json, LeadSpaceResponseBatchPolling.class);
    }
}