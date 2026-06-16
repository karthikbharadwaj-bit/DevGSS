/**
 * Invocable Apex action for Screen Flow.
 * Returns whether to show the "Link Jira" warning and the message to display.
 * Used when users edit Jira fields manually - shows non-blocking guidance to use Link Jira button.
 */
public with sharing class JiraWarningFlowAction {

    /**
     * Input for the invocable method - used by Screen Flow.
     */
    public class JiraWarningContextInput {
        @InvocableVariable(label='Case Id' description='The Case record Id' required=true)
        public Id caseId;
    }

    /**
     * Output for the invocable method - used by Screen Flow.
     */
    public class JiraWarningContextOutput {
        @InvocableVariable(label='Show Warning' description='Whether to show the Link Jira guidance')
        public Boolean showWarning;

        @InvocableVariable(label='Message' description='The message to display')
        public String message;
    }

    @InvocableMethod(
        label='Get Jira Warning Context'
        description='Returns whether to show the Link Jira warning for the given Case (profile + record type in scope, no linked Jira)'
        category='Case'
    )
    public static List<JiraWarningContextOutput> getJiraWarningContext(List<JiraWarningContextInput> inputs) {
        List<JiraWarningContextOutput> outputs = new List<JiraWarningContextOutput>();
        for (JiraWarningContextInput input : inputs) {
            JiraWarningContextOutput out = new JiraWarningContextOutput();
            try {
                JiraAccessPermissionService.JiraAccessContext ctx =
                    JiraAccessPermissionService.getAccessContext(input.caseId);
                out.showWarning = ctx.isProfileRecordTypeInScope && !ctx.hasLinkedJiraDetail;
                out.message = String.isNotBlank(ctx.message) ? ctx.message : 'You can use the Link Jira button to link the Jira.';
            } catch (Exception e) {
                out.showWarning = false;
                out.message = '';
            }
            outputs.add(out);
        }
        return outputs;
    }
}