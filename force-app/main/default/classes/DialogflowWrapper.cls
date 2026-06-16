public class DialogflowWrapper {
    
    // Case wrapper
    public class CaseWrapper {
        @AuraEnabled public String caseNumber { get; set; }
        @AuraEnabled public String subject { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public String priority { get; set; }
        @AuraEnabled public String description { get; set; }
        @AuraEnabled public String resolution { get; set; }
        @AuraEnabled public String recordTypeName { get; set; }
        @AuraEnabled public String ownerId { get; set; }
        
        public CaseWrapper(Case caseRecord) {
            this.caseNumber = caseRecord.CaseNumber;
            this.subject = caseRecord.Subject;
            this.status = caseRecord.Status;
            this.priority = caseRecord.Priority;
            this.description = caseRecord.Description;
            this.resolution = caseRecord.Resolution__c;
            this.recordTypeName = caseRecord.RecordType?.Name;
            this.ownerId = caseRecord.OwnerId;
        }
    }
    
    // Case Comment wrapper
    public class CaseCommentWrapper {
        @AuraEnabled public String commentBody { get; set; }
        @AuraEnabled public String parentId { get; set; }
        @AuraEnabled public Boolean isPublished { get; set; }
        @AuraEnabled public CaseWrapper caseDetails { get; set; }
        
        public CaseCommentWrapper(CaseComment comment, Case parentCase) {
            this.commentBody = comment.CommentBody;
            this.parentId = comment.ParentId;
            this.isPublished = comment.IsPublished;
            this.caseDetails = new CaseWrapper(parentCase);
        }
    }
    
    // Knowledge Article wrapper
    public class KnowledgeArticleWrapper {
        @AuraEnabled public String title { get; set; }
        @AuraEnabled public String articleNumber { get; set; }
        @AuraEnabled public String summary { get; set; }
        
        public KnowledgeArticleWrapper(Knowledge__kav article) {
            this.title = article.Title;
            this.articleNumber = article.ArticleNumber;
            this.summary = article.Summary;
        }
    }
    
    // Convert list of SObjects to list of wrappers
    public static List<CaseWrapper> wrapCases(List<Case> cases) {
        List<CaseWrapper> wrappers = new List<CaseWrapper>();
        for (Case c : cases) {
            wrappers.add(new CaseWrapper(c));
        }
        return wrappers;
    }
    
    public static List<KnowledgeArticleWrapper> wrapArticles(List<Knowledge__kav> articles) {
        List<KnowledgeArticleWrapper> wrappers = new List<KnowledgeArticleWrapper>();
        for (Knowledge__kav article : articles) {
            wrappers.add(new KnowledgeArticleWrapper(article));
        }
        return wrappers;
    }
}