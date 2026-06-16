public inherited sharing class CaseSelectorDialogflow {
    private static CaseSelectorDialogflow instance;
    private static String STATUS_CLOSED = 'Closed';
    private static String EXCEPTION_MSG = 'Case number cannot be empty';

    public static CaseSelectorDialogflow getInstance() {
        if (instance == null) {
            instance = new CaseSelectorDialogflow();
        }
        return instance;
    }

    // Fields used across multiple queries
    private static final List<String> BASE_FIELDS = new List<String>{
        'Id',
        'CaseNumber',
        'Subject',
        'Status',
        'Priority',
        'Description',
        'Resolution__c',
        'RecordType.Name',
        'OwnerId'
        };

    public Case getCaseByCaseNumber(String caseNumber) {
        if (String.isBlank(caseNumber)) {
            throw new CaseSelectorException(EXCEPTION_MSG);
        }

        List<Case> cases = [
            SELECT Id, CaseNumber, Subject, Status, Priority, Description, Resolution__c, RecordType.Name, OwnerId
            FROM Case 
            WHERE CaseNumber = :caseNumber 
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        return !cases.isEmpty() ? cases[0] : null;
    }

    public List<Case> getCasesByOwnerId(Id ownerId, Integer limitCount) {
        if (limitCount == null) {
            limitCount = 5; // Default limit
        }

        return [
            SELECT CaseNumber, Status, RecordType.Name, Subject, Description, Priority, Resolution__c, OwnerId 
            FROM Case 
            WHERE OwnerId = :ownerId 
            AND Status != :STATUS_CLOSED
            WITH SECURITY_ENFORCED
            ORDER BY CaseNumber DESC 
            LIMIT :limitCount
        ];
    }

    public List<Case> getSimilarCasesBySubject(String subject, Integer limitCount) {
        if (String.isBlank(subject)) {
            throw new CaseSelectorException('Subject cannot be empty');
        }

        if (limitCount == null) {
            limitCount = 5; // Default limit
        }

        String searchKey = '%' + subject + '%';
        return [
            SELECT Id, CaseNumber, Status, RecordType.Name, Subject, Priority, Resolution__c, Description,OwnerId
            FROM Case
            WHERE Subject LIKE :searchKey
            WITH SECURITY_ENFORCED
            ORDER BY CaseNumber DESC
            LIMIT :limitCount
        ];
    }

    public List<Case> getFilteredCases(String searchText, List<Case> casesToFilter) {
        if (String.isBlank(searchText)) {
            return new List<Case>();
        }

        List<Case> filteredCases = new List<Case>();
        String searchLower = searchText.toLowerCase();

        for (Case c : casesToFilter) {
            if ((c.Description != null && c.Description.toLowerCase().contains(searchLower)) || 
                (c.Subject != null && c.Subject.toLowerCase().contains(searchLower))) {
                    filteredCases.add(c);
            }
        }

        return filteredCases;
    }

    public Map<Id, UserRecordAccess> getCaseAccessByUser(Id userId, Set<Id> caseIds) {
        if (caseIds.isEmpty()) {
            return new Map<Id, UserRecordAccess>();
        }

        Map<Id, UserRecordAccess> accessMap = new Map<Id, UserRecordAccess>();
        for (UserRecordAccess ura : [
            SELECT RecordId, HasReadAccess
            FROM UserRecordAccess 
            WHERE UserId = :userId 
            AND RecordId IN :caseIds
            WITH SECURITY_ENFORCED
        ]) {
            accessMap.put(ura.RecordId, ura);
        }

        return accessMap;
    }

    public Map<String, Id> getCaseIdsByCaseNumbers(List<String> caseNumbers) {
        Map<String, Id> result = new Map<String, Id>();
        if (caseNumbers == null || caseNumbers.isEmpty()) { 
            return result;
        }
        for (Case c : [
            SELECT Id, CaseNumber 
            FROM Case 
            WHERE CaseNumber IN :caseNumbers
            WITH SECURITY_ENFORCED
        ]) {
            result.put(c.CaseNumber, c.Id);
        }
        return result;
    }

    public List<Case> getRelevantClosedCases(Id excludeId) {
        if (excludeId == null) {
            throw new AuraHandledException('Missing excludeId');
        }
        
        GCP_Feature_Toggle__c config = GCP_Feature_Toggle__c.getInstance();
        Integer recordLimit = (config.Record_count__c != null) ? Integer.valueOf(config.Record_count__c) : 500;
        
        List<String> statuses = new List<String>();
        if (String.isNotBlank(config.Status__c)) {
            for (String s : config.Status__c.split(',')) {
                if (String.isNotBlank(s)) {
                    statuses.add(s.trim());
                }
            }
        } else {
            statuses.add('Closed');
        }
        
        List<String> priorities = new List<String>();
        if (String.isNotBlank(config.Priorities__c)) {
            for (String p : config.Priorities__c.split(',')) {
                if (String.isNotBlank(p)) {
                    priorities.add(p.trim());
                }
            }
        } else {
            priorities.add('High');
        }
        
        // Fetch RecordType
        Case excludeCase = [
            SELECT RecordType.Name
            FROM Case
            WHERE Id = :excludeId
            LIMIT 1
        ];
        String excludeCaseRTName = excludeCase.RecordType.Name;
        
        // RecordType list
        List<String> recordTypes = new List<String>();
        if (String.isNotBlank(config.Similar_Case_RecordType__c)) {
            for (String rt : config.Similar_Case_RecordType__c.split(',')) {
                if (String.isNotBlank(rt)) {
                    recordTypes.add(rt.trim());
                }
            }
        }
        Datetime fromDate = config.From_date__c;
    	Datetime toDate   = config.To_date__c;
        
        String baseQuery = 'SELECT CaseNumber, Subject, Description, Resolution__c ' +
            'FROM Case ' +
            'WHERE Status IN :statuses ' +
            'AND Priority IN :priorities ' +
            'AND Id != :excludeId ';
        
        if (config.No_of_years__c != null && config.No_of_years__c > 0) {
            baseQuery += 'AND LastModifiedDate >= LAST_N_YEARS:' + Integer.valueOf(config.No_of_years__c) + ' ';
        } else if (config.From_date__c != null && config.To_date__c != null) {
            baseQuery += 'AND LastModifiedDate >= :fromDate ';
            baseQuery += 'AND LastModifiedDate <= :toDate ';
        } else if (config.From_date__c != null) {
            baseQuery += 'AND LastModifiedDate >= :fromDate ';
        }
        
        if (!recordTypes.isEmpty() && recordTypes.contains(excludeCaseRTName)) {
            baseQuery += 'AND RecordType.Name IN :recordTypes ';
        }
        
        baseQuery += 'ORDER BY LastModifiedDate DESC LIMIT :recordLimit';
        return Database.query(baseQuery);
    }

    public List<CaseComment> getCaseCommentsByCaseIdPaged(Id caseId, String lastSeenId, Integer batchSize) {
        String baseQuery = 'SELECT Id, ParentId, CommentBody,CreatedDate, Parent.CaseNumber FROM CaseComment ' +
            'WHERE ParentId = :caseId ';
        if (!String.isBlank(lastSeenId)) {
            baseQuery += 'AND Id > :lastSeenId ';
        }
        baseQuery += 'ORDER BY Id ASC LIMIT :batchSize';

        return Database.query(baseQuery);
    }
  
    public class CaseSelectorException extends Exception {}
}