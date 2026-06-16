@RestResource(urlMapping='/getCaseCommentsForGCP')
global with sharing class DialogflowShowCaseCommentsGCP {

    public class CaseCommentDTO {
        public Id CaseCommentRecordId;
        public Id ParentId;
        public String CommentBody;
        public String CaseNumber;
        public Datetime CreatedDate;

        public CaseCommentDTO(CaseComment cc) {
            this.CaseCommentRecordId = cc.Id;
            this.ParentId = cc.ParentId;
            this.CommentBody = cc.CommentBody;
            this.CaseNumber = cc.Parent.CaseNumber;
            this.CreatedDate = cc.CreatedDate;
        }
    }

    @HttpPost
    global static void getCommentsByCaseId() {
        try {
            RestRequest req = RestContext.request;
            Map<String, Object> bodyMap = (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());

            Id recordId = (Id) bodyMap.get('recordId');
            String lastSeenId = (String) bodyMap.get('lastProcessedCommentId'); // Optional
            Integer batchSize = (bodyMap.containsKey('currentBatchSize')) ? Integer.valueOf(bodyMap.get('currentBatchSize')) : 200;

            if (String.isBlank(recordId)) {
                throw new AuraHandledException('Missing recordId');
            }
            // Get total count (for tracking)
            Integer totalCount = [
                SELECT COUNT() FROM CaseComment WHERE ParentId = :recordId
            ];

            Integer processedSoFar = 0;
            if (!String.isBlank(lastSeenId)) {
                processedSoFar = [
                    SELECT COUNT() 
                    FROM CaseComment 
                    WHERE ParentId = :recordId AND Id <= :lastSeenId
                ];
            }

            List<CaseComment> rawComments = CaseSelectorDialogflow.getInstance()
                .getCaseCommentsByCaseIdPaged(recordId, lastSeenId, batchSize);

            List<CaseCommentDTO> commentList = new List<CaseCommentDTO>();
            for (CaseComment cc : rawComments) {
                commentList.add(new CaseCommentDTO(cc));
            }

            String newLastSeenId = commentList.isEmpty() ? null : commentList[commentList.size() - 1].CaseCommentRecordId;

            Map<String, Object> response = new Map<String, Object>{
                'totalCaseCommentCount' => totalCount,
                    'currentBatchSize' => commentList.size(),
                    'cumulativeProcessedCount' => processedSoFar + commentList.size(),
                    'hasMoreComments' => (processedSoFar + commentList.size() < totalCount),
                    'lastProcessedCommentId' => newLastSeenId,
                    'caseComments' => commentList
                    };

            RestResponse res = RestContext.response;
            res.addHeader('Content-Type', 'application/json');
            res.responseBody = Blob.valueOf(JSON.serialize(response));
            res.statusCode = 200;
        } catch (Exception e) {
            DialogflowResponseHandler.handleException(e);
        }
    }
}