public class InventionCustomLookupCtrl {
	public String strSearch {get;set;}
	public List<User> lstUsers{get;set;}
	
	public InventionCustomLookupCtrl(){
		strSearch = ApexPages.currentPage().getParameters().get('strSearch');
		getUsersList(strSearch);
	}
	
	public PageReference searchUser(){
		getUsersList(strSearch);
		return null; 
	}
	
	public void getUsersList(String strFind){
		if(String.isNotBlank(strFind)){
			String strLike = '%'+strFind+'%';
			lstUsers = [SELECT Id, Name, Profile.Name, UserRole.Name FROM User WHERE Name like :strLike AND IsActive = true];
		}else{
			lstUsers = new List<User>();
		}
	}
	
	public boolean getisUserFound(){
		if(lstUsers != null && lstUsers.size() > 0){
			return true;
		}
		return false;
	}
}