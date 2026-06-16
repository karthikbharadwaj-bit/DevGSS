public class ContactQueueable implements Queueable {
  Map<Id, Contact> oldMapContact = new Map<Id, Contact>();
  List<Contact> contacts = new List<Contact>();
  public ContactQueueable(
    List<Contact> newContacts,
    Map<Id, Contact> oldMapContact
  ) {
    this.oldMapContact = oldMapContact;
    this.contacts = newContacts;
  }
  public ContactQueueable(List<Contact> newContacts) {
    this.contacts = newContacts;
  }
  public void execute(QueueableContext context) {
    ContactTriggerHelper.updateLeadspaceAccount(this.contacts, this.oldMapContact);
  }
}