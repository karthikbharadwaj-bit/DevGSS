global class LiveAgentPreChatControllerGCC {

    public Map<String, String> buttons { get; set; }
    public LiveAgentPreChatControllerGCC() {
        // Get all Chat buttons
        List<LiveChatButton> buttonsList = [SELECT Id, DeveloperName FROM LiveChatButton];
        buttons = new Map<String, String>();
        for(LiveChatButton b : buttonsList){
            buttons.put(b.DeveloperName, String.valueOf(b.Id).substring(0,15)); // Chat button only work with short (15) IDs
        }
    }

    /**
     *
     */
    @remoteAction
    global static Map<String,String> getAccount(Map<String,String> params){
        String accountNumber = params.get('accountNumber');
        String email = params.get('email');
        Map<String,String> result = new Map<String, String>();
        if(!String.isBlank(accountNumber)){
            try{
                List<Account> accounts = [
                        SELECT Id, Name, Total_Account_DL_s__c, Service_Type__c, RC_Service_name__c, RC_Brand__c
                        FROM Account
                        WHERE RC_Account_Number__c = :accountNumber
                        LIMIT 1
                ];
                if (accounts.size() > 0) {
                    defineFreyjaRouting(accounts[0].Id, result);
                    result.put('Total_Account_DL_s__c',String.valueOf(accounts[0].Total_Account_DL_s__c));
                    result.put('Service_Type__c',String.valueOf(accounts[0].Service_Type__c));
                    result.put('RC_Service_name__c',String.valueOf(accounts[0].RC_Service_name__c));
                    result.put('RC_Brand__c',String.valueOf(accounts[0].RC_Brand__c));
                } else {
                    List<Contact> contacts = [
                            SELECT AccountId, Account.Total_Account_DL_s__c, Account.Service_Type__c, Account.RC_Service_name__c, Account.RC_Brand__c
                            FROM Contact
                            WHERE Email = :email
                            LIMIT 1
                    ];
                    if(contacts.size() > 0){
                        defineFreyjaRouting(contacts[0].AccountId, result);
                        result.put('Total_Account_DL_s__c',String.valueOf(contacts[0].Account.Total_Account_DL_s__c));
                        result.put('Service_Type__c',String.valueOf(contacts[0].Account.Service_Type__c));
                        result.put('RC_Service_name__c',String.valueOf(contacts[0].Account.RC_Service_name__c));
                        result.put('RC_Brand__c',String.valueOf(contacts[0].Account.RC_Brand__c));
                    }
                }
            } catch (System.DmlException e){
                for (Integer i = 0; i < e.getNumDml(); i++) {
                    System.debug(e.getDmlMessage(i)); 
                }
            }
        }
        System.Debug(result);
        return result;
    }

    private static void defineFreyjaRouting(Id accId, Map<String, String> result) {
        List<Package__c> packages = [
                SELECT Id, Offer_Type__c
                FROM Package__c
                WHERE Account__c = :accId
        ];
        if (packages.size() == 1) {
            Package__c pkg = packages[0];
            if (String.isNotBlank(pkg.Offer_Type__c)) {
                if (pkg.Offer_Type__c == 'Free') {
                    result.put('freyjaRouting','free');
                } else {
                    result.put('freyjaRouting','freyja');
                }
            } else {
                result.put('freyjaRouting','default');
            }
        } else {
            result.put('freyjaRouting', 'default');
        }
    }
}