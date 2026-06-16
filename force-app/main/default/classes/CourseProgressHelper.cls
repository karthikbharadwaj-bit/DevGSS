public with sharing class CourseProgressHelper {

    public static final String CDP_STATUS_PS_PRMIER_PARTNER = 'PS Premier Partner';
    public static final String CDP_STATUS_INCOMPLETE = 'Incomplete';
    public static final String CDP_STATUS_COMPLETE = 'Complete';
    public static final String CDP_STATUS_NONE = 'None';

    @testVisible
    private static Map<Contact, skilljar__Course_Progress__c[]> getCourseProgressesIdsByContact(skilljar__Course_Progress__c[] coursesProgresses) {
        Map<Contact, skilljar__Course_Progress__c[]> courseProgressesByContactId = new Map<Contact, skilljar__Course_Progress__c[]>();

        for (skilljar__Course_Progress__c courseProgress : coursesProgresses) {
            Contact cont = new Contact(Id = courseProgress.skilljar__Contact__c);
            if (!courseProgressesByContactId.containsKey(cont)) {
                courseProgressesByContactId.put(cont, new skilljar__Course_Progress__c[]{});
            }
            courseProgressesByContactId.get(cont).add(courseProgress);
        }

        return courseProgressesByContactId;
    }
    
    @testVisible
    private static Map<Id, Contact[]> getContactsByAccountId(Set<Contact> contacts) {
        Map<Id, Contact[]> contactsByAccountId = new Map<Id, Contact[]>();
        for (Contact cont : (Contact[]) new ContactSelector().selectContactsByIds(new Object[]{contacts})
            .selectFields(new String[]{'Id', 'AccountId'})
            .executeQuery()
        ){
            if (String.isNotBlank(cont.AccountId)) {
                if (!contactsByAccountId.containsKey(cont.AccountId)) {
                    contactsByAccountId.put(cont.AccountId, new Contact[]{});
                }
                contactsByAccountId.get(cont.AccountId).add(cont);

            }
        }
        return contactsByAccountId;
    }

    public static Map<Account, Integer> getCompletedCDPCoursesByAccount(Set<Id> accountIds, skilljar__Course_Progress__c[] coursePorgressToNotQuery) {
        Map<Account, Integer> completedCDPCoursesByAccount = new Map<Account, Integer>();
       
        for (Contact cont : [
            SELECT AccountId, Account.Certified_Delivery_Partner_Status__c, 
                (SELECT Id 
                    FROM skilljar__Course_Progress__r 
                    WHERE CDP_Course__c = true AND skilljar__Completed_At__c != null AND Id NOT IN :coursePorgressToNotQuery
                ) 
            FROM Contact WHERE AccountId IN :accountIds
        ]) {
            Account acc = new Account(
                Id = cont.AccountId, 
                Certified_Delivery_Partner_Status__c = cont.Account.Certified_Delivery_Partner_Status__c
            );
            if (!completedCDPCoursesByAccount.containsKey(acc)) {
                completedCDPCoursesByAccount.put(acc, 0);
            }

            Integer contactCompletedCDPCourses = cont.skilljar__Course_Progress__r.size();
            Integer accountCompletedCDPCourses = completedCDPCoursesByAccount.get(acc);

            completedCDPCoursesByAccount.put(acc, contactCompletedCDPCourses + accountCompletedCDPCourses);

        }

        return completedCDPCoursesByAccount;
    }

    private static Integer getNumberOfCompletedCDPCourses(skilljar__Course_Progress__c[] courseProgresses, Set<Id> oldContactIds) {
        Integer amount = 0;

        for (skilljar__Course_Progress__c cp : courseProgresses) {
            if (cp.skilljar__Completed_At__c != null && !oldContactIds.contains(cp.skilljar__Contact__c)) {
                amount++;
            }
        }

        return amount;
    }

    private static void recalculateContactAccountCDPStatusField(skilljar__Course_Progress__c[] courseProgressesToUpdateAccountCDPStatus, Set<Id> oldContactIds) {
        Map<Contact, skilljar__Course_Progress__c[]> courseProgressesIdsByContact = getCourseProgressesIdsByContact(courseProgressesToUpdateAccountCDPStatus);
        Map<Id, Contact[]> contactsByAccountId = getContactsByAccountId(courseProgressesIdsByContact.keySet());

        if (!contactsByAccountId.isEmpty()) {
            Map<Account, Integer> completedCDPCoursesByAccount = getCompletedCDPCoursesByAccount(
                contactsByAccountId.keySet(), 
                trigger.isDelete ? 
                    new skilljar__Course_Progress__c[]{} : 
                    courseProgressesToUpdateAccountCDPStatus
            );
    
            List<Account> accountsToUpdate = new List<Account>();
    
            for (Account acc : completedCDPCoursesByAccount.keySet()) {
                if (acc.Certified_Delivery_Partner_Status__c != CDP_STATUS_PS_PRMIER_PARTNER) {
                    Integer completedCDPCourses = completedCDPCoursesByAccount.get(acc);
                    for (Contact cont : contactsByAccountId.get(acc.Id)) {
                        Integer completedCDPCoursesByContact = getNumberOfCompletedCDPCourses(courseProgressesIdsByContact.get(new Contact(Id = cont.Id)), oldContactIds);                       
                        completedCDPCourses = trigger.isDelete ?  
                            completedCDPCourses - completedCDPCoursesByContact :
                            completedCDPCourses + completedCDPCoursesByContact;
                    }
                    String newCDPStatus = calculateCDPStatus(
                        completedCDPCourses,
                        acc.Certified_Delivery_Partner_Status__c
                    );
                        
                    if (newCDPStatus != acc.Certified_Delivery_Partner_Status__c) {
                        acc.Certified_Delivery_Partner_Status__c = newCDPStatus;
                        accountsToUpdate.add(acc);
                    }
                }
            }
    
            if (accountsToUpdate.size() > 0) {
                update accountsToUpdate;
            }
        }
    }

    public static void updateAccountCertifiedDeliveryPartnerStatusField(Map<Id, skilljar__Course_Progress__c> newMap, Map<Id, skilljar__Course_Progress__c> oldMap) {
        skilljar__Course_Progress__c[] courseProgressesToUpdateAccountCDPStatus = getCourseProgressesWhereCompletedAtFieldHasChanged(newMap, oldMap);
        Set<Id> oldContactIds = new Set<Id>();
        if (trigger.isUpdate) {
            courseProgressesToUpdateAccountCDPStatus.addAll(getOldAndNewCoursesWhereContactFieldHasChanged(newMap, oldMap, oldContactIds));
        }
        
        if (courseProgressesToUpdateAccountCDPStatus.size() != 0) {
            recalculateContactAccountCDPStatusField(courseProgressesToUpdateAccountCDPStatus, oldContactIds);
        }
    }

    @testVisible
    private static skilljar__Course_Progress__c[] getCourseProgressesWhereCompletedAtFieldHasChanged(Map<Id, skilljar__Course_Progress__c> newMap, Map<Id, skilljar__Course_Progress__c> oldMap) {
        skilljar__Course_Progress__c[] courseProgresses = new skilljar__Course_Progress__c[]{};

        for (Id courseProgressId : trigger.isDelete ? oldMap.keySet() : newMap.keySet()) {
            skilljar__Course_Progress__c newCourseRecord = newMap?.get(courseProgressId);
            skilljar__Course_Progress__c oldCourseRecord = oldMap?.get(courseProgressId);

            if ((trigger.isDelete &&  oldCourseRecord?.skilljar__Completed_At__c != null) 
                || (newCourseRecord?.skilljar__Completed_At__c != oldCourseRecord?.skilljar__Completed_At__c)
            ) {
                courseProgresses.add(trigger.isDelete ? oldCourseRecord : newCourseRecord);
            }
        }

        return courseProgresses;
    }

    @testVisible
    private static skilljar__Course_Progress__c[] getOldAndNewCoursesWhereContactFieldHasChanged(
        Map<Id, skilljar__Course_Progress__c> newMap,
        Map<Id, skilljar__Course_Progress__c> oldMap,
        Set<Id> oldContactIds
    ) {
        skilljar__Course_Progress__c[] courseProgresses = new skilljar__Course_Progress__c[]{};

        for (Id courseProgressId : newMap.keySet()) {
            skilljar__Course_Progress__c newCourseRecord = newMap.get(courseProgressId);
            skilljar__Course_Progress__c oldCourseRecord = oldMap.get(courseProgressId);

            if (newCourseRecord.skilljar__Contact__c != oldCourseRecord.skilljar__Contact__c) {
                courseProgresses.add(oldCourseRecord);
                courseProgresses.add(newCourseRecord);
                oldContactIds.add(oldCourseRecord.skilljar__Contact__c);
            }
        }

        return courseProgresses;
    }

    public static String calculateCDPStatus(Integer amountOfCompletedCDPCourses, String currentCDPStatus) {
        String newCDPStatus = currentCDPStatus;

        if (amountOfCompletedCDPCourses >= 2 && currentCDPStatus != CDP_STATUS_COMPLETE) {
            newCDPStatus = CDP_STATUS_COMPLETE;
        } else if (amountOfCompletedCDPCourses == 1 && currentCDPStatus != CDP_STATUS_INCOMPLETE) {
            newCDPStatus = CDP_STATUS_INCOMPLETE;
        } else if(amountOfCompletedCDPCourses == 0 && currentCDPStatus != CDP_STATUS_NONE) {
            newCDPStatus = CDP_STATUS_NONE;
        }

        return newCDPStatus;
    }
}