global without sharing class AutoCompleteController {
	@RemoteAction
    global static String[] searchUser(String searchStr){
    	String filter = searchStr + '%';
    	List<String> strList = new List<String>();
    	for(User item: [SELECT id, Name from User WHERE name like :filter AND IsActive=true order by Name limit 20]){
            strList.add(item.Name+'|'+item.id);   
            //strList.add('{ label: '+item.Name+', value: '+item.Id+'}');
            //output += item.Name+ '|' + item.id  +'\n';
            //strList.add(item.Name);        
        }
        return strList;
    }
}