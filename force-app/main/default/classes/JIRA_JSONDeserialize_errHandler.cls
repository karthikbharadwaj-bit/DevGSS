public class JIRA_JSONDeserialize_errHandler{

    public String status;
    public cls_data[] data;


    public static JIRA_JSONDeserialize_errHandler parse(string jSon){
        return (JIRA_JSONDeserialize_errHandler) System.JSON.deserialize(jSon, JIRA_JSONDeserialize_errHandler.class);
    }

    public class cls_data {
        public String status;
        public String message;
    }

}