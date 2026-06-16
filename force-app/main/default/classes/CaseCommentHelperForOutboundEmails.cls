public with sharing class CaseCommentHelperForOutboundEmails {
    
    // To get the maximum length of the Case Comment Body
    public static Integer getMaxCommentLength() {
        return CaseComment.CommentBody.getDescribe().getLength();
    }
    
    public static void createCaseComments(Map<Id, EmailMessage> emailByCaseId, Map<Id, Case> matchingCases, Integer MAX_COMMENT_LENGTH) {
        List<CaseComment> caseComments = new List<CaseComment>();
        
        for (Id caseId : matchingCases.keySet()) {
            EmailMessage email = emailByCaseId.get(caseId);
            if (email != null) {
                String commentBody = String.isNotBlank(email.TextBody) ? email.TextBody : 'No email body provided.';
                
                // Truncate Case Comment body if it's too long & add '...' at the end
                if (commentBody.length() > MAX_COMMENT_LENGTH) {
                    commentBody = commentBody.substring(0, MAX_COMMENT_LENGTH - 3) + '...';
                }
                caseComments.add(new CaseComment(
                    ParentId = caseId,
                    CommentBody = commentBody,
                    IsPublished = true // Public comment
                ));
            }
        }
        
        // Bulk insert case comments
        if (!caseComments.isEmpty()) {
            try {
                insert caseComments;
            } catch (DmlException e) {
                // Capture one exception record summarizing failure
                logException(e, caseComments.size());
            }
        }
    }
    
    // Common method to log exception details into Exception_And_Notification_History__c for Case Comment logic
    public static void logException(DmlException e, Integer caseCommentsSize) {
        Exception_And_Notification_History__c exceptionObj = new Exception_And_Notification_History__c();
        exceptionObj.File_Associated__c = 'CreateCaseCommentsForEmails - Bulk Insert Failed';
        exceptionObj.content_var_01__c = 'Total Failed Case Comments: ' + caseCommentsSize;       
        // Populate error details
        exceptionObj.recordTypeId = ExceptionAndNotificationHelper.getRcId(ExceptionAndNotificationHelper.EXCEPTION_RECORD_TYPE);
        exceptionObj.Line_Number__c = e.getLineNumber();
        exceptionObj.Exception__c = e.getTypeName();
        exceptionObj.stackTraceString__c = e.getStackTraceString();
        exceptionObj.Exception_Desc__c = e.getMessage();
        exceptionObj.Modified_By__c = UserInfo.getUserId();
        
        // Insert the error log record
        insert exceptionObj;
    }
    
    // New common reusable method to match the template with email body
    public static Boolean isEmailMatchingTemplate(EmailMessage email, String templateName) {
        if (email == null || (email.HtmlBody == null && email.TextBody == null)) {
            return false;
        }
        
        EmailTemplate template = [SELECT HtmlValue FROM EmailTemplate WHERE Name = :templateName LIMIT 1];
        if (template == null || template.HtmlValue == null) {
            return false;
        }
        
        String emailContent = email.HtmlBody != null ? email.HtmlBody : email.TextBody;
        
        String cleanedEmail = cleanContent(emailContent);
        String cleanedTemplate = cleanContent(template.HtmlValue);
        
        return isContentMatch(cleanedEmail, cleanedTemplate);
    }
    
    // Normalize and clean content for comparison
    @TestVisible
    private static String cleanContent(String content) {
        if (content == null) {
            return '';
        }
        
        // 1. Remove all merge fields (both {{field}} and {{{field}}} formats)
        content = content.replaceAll('\\{\\{.*?\\}\\}', '')
            .replaceAll('\\{\\{\\{.*?\\}\\}\\}', '');
        
        // 2. Remove HTML tags but preserve line breaks
        content = content.replaceAll('<br\\s*/?>', '\n') // Convert <br> to newlines
            .replaceAll('<[^>]+>', ' ')     // Remove other tags
            .replaceAll('&nbsp;', ' ');      // Replace non-breaking spaces
        
        // 3. Normalize whitespace and trim
        content = content.replaceAll('\\s+', ' ').trim();
        
        // 4. Convert to lowercase for case-insensitive comparison
        return content.toLowerCase();
    }
    
    // Smart content matching using key segments
    @TestVisible
    private static Boolean isContentMatch(String emailContent, String templateContent) {
        if (String.isBlank(emailContent)){
            return false;
        } 
        
        // Extract key segments (non-trivial sentences)
        List<String> templateSegments = getKeySegments(templateContent);
        if (templateSegments.isEmpty()){
            return false;
        } 
        
        // Check if email contains all key segments
        for (String segment : templateSegments) {
            if (!emailContent.contains(segment)) {
                return false;
            }
        }
        return true;
    }
    
    
    // Extract the parts of the template
    private static List<String> getKeySegments(String content) {
        List<String> segments = new List<String>();
        
        // Split into sentences/phrases
        List<String> sentences = content.split('[\\.\\!\\?]');
        
        for (String sentence : sentences) {
            sentence = sentence.trim();
            // Only consider meaningful segments
            if (sentence.length() > 30 && !sentence.contains('{') && !sentence.contains('}')) {
                segments.add(sentence);
            }
        }
        
        // If no long segments found, use the first 100 chars as fallback
        if (segments.isEmpty() && content.length() > 0) {
            segments.add(content.substring(0, Math.min(100, content.length())));
        }
        
        return segments;
    }
}