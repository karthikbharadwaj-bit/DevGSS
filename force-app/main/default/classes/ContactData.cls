public without sharing class ContactData implements IContactData{
	
    public Interface IContactData{
        void deleteContactsByAccountIds(Set<Id> accountIds);
        List<Contact> createContacts(List<Contact> newContacts);
        List<Contact> getContactsByAccountIds(Set<Id> accountIds);
    }

    public void deleteContactsByAccountIds(Set<Id> accountIds){
        DELETE [SELECT Id FROM Contact WHERE AccountId IN:accountIds]; 
    }

    public List<Contact> createContacts(List<Contact> newContacts){
        INSERT newContacts;
        return newContacts;
    }

    public List<Contact> getContactsByAccountIds(Set<Id> accountIds){
        return [SELECT Id, Name, AccountId, Email, CreatedBy.Name, Marketo_Sync_Disabled__c FROM Contact WHERE AccountId IN:accountIds];
    }

    public class ContactDataMock implements IContactData{
        private List<Contact> contactsToReturn = new List<Contact>();

        public List<Contact> getContactsToReturn() {
            return contactsToReturn;
        }

        public void setContactsToReturn(List<Contact> contactsToReturn) {
            this.contactsToReturn = contactsToReturn;
        }

        public void deleteContactsByAccountIds(Set<Id> accountIds){
            contactsToReturn.clear();
        }

        public List<Contact> createContacts(List<Contact> newContacts){
            contactsToReturn.addAll(newContacts);
            return newContacts;
        }

        public List<Contact> getContactsByAccountIds(Set<Id> accountIds){
            return contactsToReturn;
        }
    }

}