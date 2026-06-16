public without sharing class DeserializeCaseCommentBody {

    @InvocableMethod(label='Get values from Case Comment Body')
    public static List<Response> execute(List<String> bodyOfCaseComments){
        List<Response> responses = new List<Response>();
        for (String body : bodyOfCaseComments) {
            if (SCApiService.isApiComment(body)) {
                String authorName = body.split(SCApiService.AUTHOR_NAME_KEY)[1].split('\n'+SCApiService.COMMENT_KEY)[0];
                String comment = body.split(SCApiService.COMMENT_KEY)[1].split('\n'+SCApiService.UID_KEY)[0];
                String uid = body.split(SCApiService.UID_KEY)[1].split('\n'+SCApiService.EMAIL_KEY)[0];
                String email = body.split(SCApiService.EMAIL_KEY)[1].split('\n'+SCApiService.CREATED_BY_USER_KEY)[0];
                String createdByUser = body.split(SCApiService.CREATED_BY_USER_KEY)[1].split('\n'+SCApiService.CREATED_BY_CONTACT_KEY)[0];
                String createdByContact = body.split(SCApiService.CREATED_BY_CONTACT_KEY)[1];
                Response resp = new Response(comment);
                resp.authorName = authorName;
                resp.uid = uid;
                resp.email = email;
                resp.createdByContact = createdByContact;
                resp.createdByUser = createdByUser;
                responses.add(resp);
            } else {
                try{
                    responses.add((Response) JSON.deserialize(body, Response.class));
                } catch(Exception e) {
                    responses.add(new Response(body));
                }
            }
        }
        return responses;
    }

    public class Response{
        @InvocableVariable(label='UID')
        public String uid;
        @InvocableVariable(label='Email')
        public String email;
        @InvocableVariable(label='Created by user')
        public String createdByUser;
        @InvocableVariable(label='Created by contact')
        public String createdByContact;
        @InvocableVariable(label='Comment')
        public String comment;
        @InvocableVariable(label='Author name')
        public String authorName;

        public Response(string comment){
            this.comment = comment;
        }
    }
}