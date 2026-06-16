public with sharing class CasePriorityIncrementSched implements Schedulable {

    public static final Integer DEFAULT_INCREMENT_PERIOD = 7;
    public static final String AFFECTED_CASES_STATUS = 'Hold';
    public static final String DEFAULT_BUSINESS_HOURS_NAME = 'CSP';
    public static final String QUEUE_DEV_NAME = 'Biz_Serv_Dev_Team';
    public static final List<String> PRIORITIES = new List<String>{'Low', 'Medium', 'High', 'Critical'};

    private Long incrementPeriodInMilliSeconds;
    private String businessHoursId;

    public CasePriorityIncrementSched() {
        this(DEFAULT_INCREMENT_PERIOD, DEFAULT_BUSINESS_HOURS_NAME);
    }
    public CasePriorityIncrementSched(Integer numberOfDays) {
        this(numberOfDays, DEFAULT_BUSINESS_HOURS_NAME);
    }

    public CasePriorityIncrementSched(Integer numberOfDays, String businessHoursName) {
        List<BusinessHours> bisHours = (new BusinessHoursSelector()).newQueryFactory()
            .selectFields(new List<Schema.SObjectField>{BusinessHours.Id})
            .setCondition('Name = :bind0')
            .setQueryBindings(new List<Object>{businessHoursName})
            .executeQuery();
        if (bisHours.isEmpty()) {
            AquivaHelper.throwAquivaException('No such BusinessHours : \'' + businessHoursName + '\'.');
        } else {
            this.businessHoursId = bisHours[0].Id;
        }
        this.incrementPeriodInMilliSeconds = numberOfDays * 24 * 3600 * 1000;
    }

    public void execute(SchedulableContext cforceontext) {
        Set<Id> caseOwners = getQueueMembers();
        if (caseOwners.isEmpty()){
            return; 
        }

        List<Case> cases = getCasesWithLastUpdateInformation(caseOwners);
        List<Case> casesWithIncreasedPriority = getCasesWithIncreasedPriorities(cases);

        if (!casesWithIncreasedPriority.isEmpty()) {
            update casesWithIncreasedPriority;
        }
    }

    public static Set<Id> getQueueMembers() {
        Set<Id> caseOwners = new Set<Id>(); 
        List<GroupMember> gms = (new GroupMemberSelector()).newQueryFactory()
            .selectFields(new List<Schema.SObjectField>{GroupMember.UserOrGroupId, GroupMember.GroupId})
            .setCondition('Group.DeveloperName = :bind0 AND Group.Type = \'Queue\'')
            .setQueryBindings(new List<Object>{QUEUE_DEV_NAME})
            .executeQuery();
        if (!gms.isEmpty()) {
            // add queue itself
            caseOwners.add(gms[0].GroupId);
            for (GroupMember gm: gms) {
                // add all of queue members
                caseOwners.add(gm.UserOrGroupId);
            }
        }
        return caseOwners;
    }

    /*
     * For each case record also returns a CaseHistory record 
     * which contains information about when 'Priority' and/or 'Status' field was last time modified.
     */
    @TestVisible
    private List<Case> getCasesWithLastUpdateInformation(Set<Id> caseOwners) {
        return (new CaseSelector()).newQueryFactory()
            .selectFields(new List<Schema.SObjectField>{Case.Id, Case.Priority, Case.CreatedDate})
            .subselect(
                new CaseHistorySelector().newQueryFactory()
                    .selectField(CaseHistory.CreatedDate)
                    .setCondition('Field IN (\'Priority\', \'Status\')')
                    .addOrdering(CaseHistory.CreatedDate, QueryFactory.SortOrder.DESCENDING)
                    .setLimit(1))
            .setCondition('OwnerId IN :bind0 AND Status = :bind1')
            .setQueryBindings(new List<Object>{caseOwners, AFFECTED_CASES_STATUS})
            .executeQuery();
    }

    @TestVisible
    private List<Case> getCasesWithIncreasedPriorities(List<Case> cases) {
        List<Case> casesWithIncreasedPriority = new List<Case>();
        DateTime now = System.now();

        for (Case c : cases) {
            Datetime lastUpdate;
            if (c.Histories.isEmpty()) {
                // Priority and Status fields was not modified since this case was created
                lastUpdate = c.CreatedDate;
            } else {
                lastUpdate = c.Histories[0].CreatedDate;
            }

            if (BusinessHours.diff(businessHoursId, lastUpdate, now) > this.incrementPeriodInMilliSeconds) {
                String nextPriority = getNextPriority(c.Priority);
                if (nextPriority != null) {
                    c.Priority = nextPriority;
                    casesWithIncreasedPriority.add(c);
                }
            }
        }
        return casesWithIncreasedPriority;
    }

    public static String getNextPriority(String currentPriority) {
        Iterator<String> iter = PRIORITIES.iterator();
        while (iter.hasNext()) {
            if (iter.next() == currentPriority && iter.hasNext()) {
                return iter.next();
            }
        }
        return null;
    }

}