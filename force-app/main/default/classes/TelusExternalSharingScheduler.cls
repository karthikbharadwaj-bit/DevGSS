/**
 * @author Dmitry Malenko
 * @date 7/18/2019
 * @description Fix for CASE 08723003: No Porting cases coming into TELUS case queue
		Issue: External system creating Case with Case Comment in the same time and Salesforce 2 Salesforce connection sometimes has conflicts in this records.
		Fix: If we have conflict we inserting Case Comment after 5 minutes after Case inserted.
 */
public class TelusExternalSharingScheduler implements Schedulable {

	static public final Set<String> TELUS_RECORD_TYPES = new Set<String>{
		'Porting - In (TELUS)'
	};

	public void execute (SchedulableContext sc) {
		Datetime last2HTimestamp = Datetime.now();
		last2HTimestamp = last2HTimestamp.addHours(-2);

		CaseCommentSelector caseCommentSelector = new CaseCommentSelector();
        List<Object> bindings = new List<Object>();
        bindings.add(TELUS_RECORD_TYPES);
        bindings.add(last2HTimestamp);

        List<CaseComment> latestCaseComments = (List<CaseComment>) caseCommentSelector
                    .selectCaseCommentsByCreatedDate(bindings)
                    .executeQuery();
		Map<Id,CaseComment> latestCaseCommentsMap = new Map<Id,CaseComment>(latestCaseComments);

		// If no have Partner Communication records for case - will send this case to onLocalCaseCommentInsert method
		PartnerCommunicationSelector partnerCommunicationSelector = new PartnerCommunicationSelector();
        bindings = new List<Object>();
        bindings.add(latestCaseCommentsMap.keySet());

        List<Partner_Communication__c> relPartnerCommunications = (List<Partner_Communication__c>) partnerCommunicationSelector
                    .selectPartnerCommunicationsByCaseCommentId(bindings)
                    .executeQuery();

		Map<Id,Partner_Communication__c> caseIdToPCMap = new Map<Id,Partner_Communication__c>();
		for (Partner_Communication__c currPC: relPartnerCommunications) {
			caseIdToPCMap.put(currPC.Case_Comment_ID__c, currPC);
		}

		List<CaseComment> caseCommentsWithoutPC = new List<CaseComment>();
		for (CaseComment currCaseComment: latestCaseCommentsMap.values()) {
			if (!caseIdToPCMap.containsKey(currCaseComment.Id)) {
				caseCommentsWithoutPC.add(currCaseComment);
			}
		}

		// Trying to process Case Comments again
		if (caseCommentsWithoutPC.size() > 0) {
			TelusExternalSharingHelperCls.onLocalCaseCommentInsert(caseCommentsWithoutPC);
		}
		
		if (!Test.isRunningTest()) {
			// Aborting current Cron Job
			Id jobId = sc.getTriggerId();
			System.abortJob(jobId);
			// System.abortJob can only be used in the context of a User with the "Modify All Data" system permission
		}
		
	}

}