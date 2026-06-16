public class BatchJob_FileCopy implements Database.Batchable<sObject>, Database.Stateful {
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

	public BatchJob_FileCopy(Map<Id, Id> copyFromToMap){
		this(copyFromToMap, false);
	}

	public BatchJob_FileCopy(Map<Id, Id> copyFromToMap, Boolean latestOnly) {
		this.latestOnly = latestOnly;
		this.copyFromToMap = copyFromToMap;
        system.debug('keys'+keys);
		query = 'SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink  where LinkedEntityId IN : keys';
		
	}

	public void execute() {
		Database.executeBatch(this, DEFAULT_SCOPE);
	}
	
	public BatchJob_FileCopy(Id copyFrom, Id copyTo) {
		this(new Map<Id, Id> { copyFrom => copyTo });
	}
	
	public Iterable<sObject> start(Database.BatchableContext BC) {
                system.debug('query===>'+query);

		return Database.query(query);
	}

   	public void execute(Database.BatchableContext BC, List<sObject> scope) {
        system.debug('test1');
        system.debug('parentIdsProcessed');

		List<ContentDocumentlink> contentDocList = (List<ContentDocumentlink>)scope;
		List<ContentDocumentlink> filesToInsert = new List<ContentDocumentlink>();
        
        Set<Id> contentDocId = new Set<Id>();
        
        for(ContentDocumentlink file: contentDocList){
            contentDocId.add(file.ContentDocumentId);
            
        }
        
        Map<Id , Id> contentDocParMap = new Map<Id , Id>();
        for(ContentDocumentlink conDoc : [SELECT ContentDocumentId, LinkedEntity.type, LinkedEntityId from ContentDocumentLink  where ContentDocumentId IN : contentDocId]){
            if(conDoc.LinkedEntity.type != 'Approval__c' && conDoc.LinkedEntity.type != 'User'){
                
                    contentDocParMap.put(conDoc.ContentDocumentId , conDoc.LinkedEntityId);
                
            }
        }
        
        system.debug(contentDocParMap);
        
        for(ContentDocumentlink file: contentDocList) {
            /*if(this.parentIdsProcessed.contains(file.LinkedEntityId) && this.latestOnly){
                continue;
            }*/
            system.debug(contentDocParMap);
            system.debug(copyFromToMap.get(file.LinkedEntityId));
            if(contentDocParMap.isEmpty() || !contentDocParMap.containsKey(file.ContentDocumentId) || (contentDocParMap.containsKey(file.ContentDocumentId) && contentDocParMap.get(file.ContentDocumentId) != copyFromToMap.get(file.LinkedEntityId))){
                ContentDocumentlink newcontentDoc = file.clone();
                newcontentDoc.LinkedEntityId = copyFromToMap.get(file.LinkedEntityId);
                newcontentDoc.ContentDocumentId = file.ContentDocumentId;
                filesToInsert.add(newcontentDoc);
                //this.parentIdsProcessed.add(file.LinkedEntityId);
            }
        }
        if(!filesToInsert.isEmpty()){
            insert filesToInsert;
        }
    }
    
    public void finish(Database.BatchableContext BC) {
		
	}

}