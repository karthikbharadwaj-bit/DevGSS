/*************************************************
ProtectionRuleExceptions class
ProtectionRuleExceptions checks for certain predefined conditions and returns whether to use protection rules or not.
/************************************************/
public with sharing class ProtectionRuleExceptions {
	Lead leadToCheck;
	Boolean returnCheck;
	Map<String, String> mapProtectedEmailAddresses = new Map<String, String>{
			'fake@email.com' => 'fake@email.com', 'fake@fake.com' => 'fake@fake.com'};	
	Map<String, String> mapProtectedBrands = new Map<String, String>{
			'ringcentral office@hand from at&t' => 'RingCentral Office@Hand from AT&T',
			'at&t office@hand' => 'AT&T Office@Hand', 'rogers' => 'Rogers'};	
    Map<String, String> mapPRLeadSource = new Map<String, String> {
    'about to be cancelled' => 'About To Be Cancelled', 'about to be cancelled uk' => 'About To Be Cancelled UK'
    };
    
	public ProtectionRuleExceptions(Lead leadToCheck){
        this.leadToCheck = leadToCheck;
        returnCheck = true;
    }
	
	public Boolean useProtectionRuleCheck (){
		try{
			returnCheck = (fakeEmailCheck() && brandCheck() && leadSourceCheck());//Do and of all conditions, if any of them is false, return with false
			
		}catch(Exception exp){
			return returnCheck;
		}
		
		return returnCheck;
	}
	
	private Boolean fakeEmailCheck(){
		return ((leadToCheck.Email != null && mapProtectedEmailAddresses.get(leadToCheck.Email.trim().toLowerCase()) != null)? false : true);
	}
	
	private Boolean brandCheck(){
		return ((leadToCheck.Lead_Brand_Name__c != null 
			&& mapProtectedBrands.get(leadToCheck.Lead_Brand_Name__c.trim().toLowerCase()) != null)? false : true);		
	}
	private Boolean leadSourceCheck() {
    	return ((leadToCheck.LeadSource != null && mapPRLeadSource.get(leadToCheck.LeadSource.trim().toLowerCase()) != null)? false : true);
    }
}