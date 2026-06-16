global class ApprovalVfTemplateController {
    global ApprovalVfTemplateController() {
    }

    global static Quote controllerQuote {get; set;}

    public static String totalChanges {
        get{
            if (totalChanges == null) {
                totalChanges = TemplateEngine.createDoc(
                        controllerQuote.Id,
                        QuoteHelper.getTemplate(QuoteHelper.TOTAL_CHANGES_TEMPLATE)
                );
            }
            return totalChanges;
        }
        set;
    }

    public static String changedDetails {
        get{
            if (changedDetails == null) {
                changedDetails = TemplateEngine.createDoc(
                        controllerQuote.Id,
                        QuoteHelper.getTemplate(QuoteHelper.CHANGED_DETAILS_TEMPLATE)
                );
            }
            return changedDetails;
        }
        set;
    }

    public static String approvalUrl {
        get{
            String url = '';

            ProcessInstanceWorkitemSelector selector = new ProcessInstanceWorkitemSelector();
            List<ProcessInstanceWorkitem> workItemList = selector
                .selectProcessInstanceWorkitems(new List<Object>{new Set<Id>{ controllerQuote.Id }})
                .selectFields(new List<String>{'ProcessInstance.TargetObjectId'})
                .setCondition('ProcessInstance.TargetObjectId IN :bind0')
                .executeQuery();

            if (!workItemList.isEmpty()) {
                url = 'https://' + System.Url.getOrgDomainUrl().getHost() +
                    '/p/process/ProcessInstanceWorkitemWizardStageManager?id=' + workItemList[0].Id;
            }
            return url;
        }
    }
}