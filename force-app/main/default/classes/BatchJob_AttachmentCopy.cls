public class BatchJob_AttachmentCopy implements Database.Batchable<sObject>, Database.Stateful {
	private static final Integer DEFAULT_SCOPE = 3;

	private Boolean latestOnly;
	private Map<Id, Id> copyFromToMap;
	private Set<Id> keys {
		get{
			if(null != this.copyFromToMap){
				return this.copyFromToMap.keySet();
			} else {
				return null;
			}
		}
	}
	private String query;
	private Set<Id> parentIdsProcessed = new Set<Id>();

	public BatchJob_AttachmentCopy(Map<Id, Id> copyFromToMap){
		this(copyFromToMap, false);
	}

	public BatchJob_AttachmentCopy(Map<Id, Id> copyFromToMap, Boolean latestOnly) {
		this.latestOnly = latestOnly;
		this.copyFromToMap = copyFromToMap;
		query = 'SELECT Id, Name, Body, ParentId FROM Attachment WHERE ParentId IN: keys ORDER BY CreatedDate DESC';
	}

	public void execute() {
		Database.executeBatch(this, DEFAULT_SCOPE);
	}
	
	public BatchJob_AttachmentCopy(Id copyFrom, Id copyTo) {
		this(new Map<Id, Id> { copyFrom => copyTo });
	}
	
	public Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

   	public void execute(Database.BatchableContext BC, List<sObject> scope) {
		List<Attachment> attList = (List<Attachment>)scope;
		List<Attachment> toInsert = new List<Attachment>();
		for(Attachment att: attList) {
			if(this.parentIdsProcessed.contains(att.ParentId) && this.latestOnly){
				continue;
			}
			Attachment newAtt = att.clone();
			newAtt.ParentId = copyFromToMap.get(att.ParentId);
			toInsert.add(newAtt);
			this.parentIdsProcessed.add(att.ParentId);
		}
		insert toInsert;
	}
	
	public void finish(Database.BatchableContext BC) {
		
	}
	
}