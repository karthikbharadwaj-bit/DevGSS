public class NGBS_Partner_Hierarchy_Generator {
    @future (callout=true)
    public static void getNGBSHierarchyListFuture(Id accountId, Boolean includeSelf, Boolean saveToAccount) {
        NGBS_Partner_Hierarchy_Generator.getNGBSHierarchyList(accountId, includeSelf, saveToAccount);
    }

    @future (callout=true)
    public static void getNGBSPartnerHierarchyFuture(Set<Id> accountId, Boolean includeSelf, Boolean saveToAccount) {
        List<Account> accListtobeUpdated = new List<Account>();
        for(Id accid : accountId){
            Account acc = new Account(Id = accid);
            acc.Notes__c = NGBS_Partner_Hierarchy_Generator.getNGBSHierarchyList(accid, includeSelf, saveToAccount);
            accListtobeUpdated.add(acc);
        }
        if(accListtobeUpdated != NULL && !accListtobeUpdated.isEmpty()){
            update accListtobeUpdated;
        }
    }

    @AuraEnabled
    public static String getNGBSHierarchyListAura(Id accountId, Boolean includeSelf, Boolean saveToAccount) {
        return NGBS_Partner_Hierarchy_Generator.getNGBSHierarchyList(accountId, includeSelf, saveToAccount);
    }
    
    public static String getNGBSHierarchyList(Id accountId, Boolean includeSelf, Boolean saveToAccount) {
        String endpointBase = 'callout:NGBS_API/restapi/catalog/v1.0/partners/';
        String httpMethod = 'GET';
        Map<String, String> headerDetails = new Map<String, String>();
        headerDetails.put('X-TokenId',('salesforce:crm.partners:' + UserInfo.getUserEmail()));
        headerDetails.put('Accept','application/json');
        Account acc = [select id, NGBS_Partner_Id__c, partner_account__r.NGBS_Partner_Id__c, Description from Account where id =: accountId limit 1];
        String parentId = String.valueOf(includeSelf ? acc.NGBS_Partner_Id__c : acc.partner_account__r.NGBS_Partner_Id__c);
        String output = '';
        
        while(parentId != null) {
            String endpoint = endpointBase + parentId;
            HttpResponse resp = APIUtility.makeHTTPRequest(endpoint, httpMethod, headerDetails, '');
            NGBS_PartnerResponse_Wrapper partner = NGBS_PartnerResponse_Wrapper.parse(resp.getBody());
            parentId = String.valueOf(partner.parentId);
            output += (partner.externalPartnerAccountId + '|' + partner.companyName + ',');
        }
        if(saveToAccount) {
            if(output != '') {
                acc.Notes__c = output.removeEnd(',');
            }
            else {
                acc.Notes__c = '';
            }
            update acc;
        }
        
        return output;
    }
}