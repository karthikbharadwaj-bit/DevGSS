public class CaseCommentController {
    public Id caseId { get; set; }
    public Boolean isPublic { get; set; }
    public String bodyText { get; set; }
    public String speechLanguage { get; set; }

    public CaseCommentController(ApexPages.StandardController std) {
        caseId = ApexPages.currentPage().getParameters().get('Id');
        isPublic = false;
        bodyText = '';
        speechLanguage = getSpeechLanguage();
    }

    private String getSpeechLanguage() {
        User currentUser = [SELECT Country__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        String userCountry = currentUser.Country__c;

        if (String.isBlank(userCountry)) {
            return 'en-US';
        }

        CountryLanguageMapping__c languageMapping = CountryLanguageMapping__c.getValues(userCountry);

        if (languageMapping != null && String.isNotBlank(languageMapping.Language__c)) {
            return languageMapping.Language__c;
        } else {
            return 'en-US';
        }
    }

    public PageReference saveComment() {
        try {
            CaseComment cc = new CaseComment(
                ParentId = caseId,
                CommentBody = bodyText,
                IsPublished = isPublic
            );
            insert cc;
            return new PageReference('/' + caseId).setRedirect(true);
        } catch (DmlException e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
        }
    }
}