public class chkContactOnAccount{
    //Check duplicasy of email in contacts of related account updated on 1/23/2015 , Case # 03194577       
    public static  void areContactMailAllowedInsertUpdate(Contact[] lstNewContacts, Map<Id, Contact> OldContactsMap) {
        Set<String> contactEmails = new Set<String>();
        Set<Id> accountIds = new Set<Id>();
        Map<Id, Contact> contactIds = new Map<Id, Contact>();   
        for (Contact con : lstNewContacts) {
            contactIds.put(con.id, con);
            if ((con.email != null && con.Email.length() > 0 && OldContactsMap == null) ||
                (OldContactsMap != null && con.Email != OldContactsMap.get(con.Id).Email)) {
                    contactEmails.add(con.email);
                }
            if (con.AccountId != null) {
                accountIds.add(con.accountid);
            }
        }  
        
        List<Contact> searchcontact = new List<Contact>([Select Id, Name, Email, AccountId from Contact where 
                                                               AccountId IN :accountIds and email IN :contactEmails 
                                                               and Id NOT IN:contactIds.keyset()]);
        
     
        if (searchcontact.isEmpty()) {
            return;
        }

        for (Contact con : lstNewContacts) {
            for (Contact searchedContact : searchcontact) {
                if (searchedContact.Email == con.Email
                    && searchedContact.AccountId == con.AccountId
                    && UserInfo.getProfileId() != HardcodedIdsMapper.getMatchedObjectId('00e80000001OK6kAAG')) {
                        con.addError('Contact with provided Email already exist on Account');
                }
            }
        }
    }
}