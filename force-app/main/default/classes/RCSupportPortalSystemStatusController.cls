public class RCSupportPortalSystemStatusController{

	public System_Status__c objStatus;
	public Boolean isPublicDescFound {get;set;}
	public String strClassName {get;set;}
	public string strResolvedDescription; 
	public string strOpenDescription;
	public List<string> resolveDescriptionLst {get;set;}
	public List<string> openDescriptionLst {get;set;}
	public String iconShade {get;set;}	
	public String srcURL {get;set;}
	public String targetURL {get;set;}
	
	
	public RCSupportPortalSystemStatusController() {
		Apexpages.currentPage().getHeaders().put('X-UA-Compatible', 'IE=9');
		targetURL = '';
		Map<String, String> pageNameMap = new Map<String, String>();
		Map<String, String> srcToKeyMap = new Map<String, String>();		
		
		if(getUKPortal()){
			srcToKeyMap.put('1','Customer Care Centre');
			srcToKeyMap.put('3','Learning Centre');
		}
		else{
			srcToKeyMap.put('1','Customer Care Center');
			srcToKeyMap.put('3','Learning Center');
		}
		srcToKeyMap.put('2','Knowledgebase');		
		srcToKeyMap.put('4','Guides & Videos'); 
		srcToKeyMap.put('5','Downloads');
		srcToKeyMap.put('6', 'Contact Support');
		
		if(getUKPortal()){
			pageNameMap.put('1', '');
			pageNameMap.put('2', 'RCSupportPortalKnowledgebaseUK?ln=kb&pg=2');
			pageNameMap.put('3', 'RCSupportPortalLCHomeUK?ln=lc&pg=3');
			pageNameMap.put('4', 'RCSupportPortalGuidesVideosUK?ln=all&pg=4');
			pageNameMap.put('5', 'RCSupportPortalDownloadsUK?ln=all&pg=5');
			pageNameMap.put('6', 'RCContactSupp');
		}
		else{
			pageNameMap.put('1', '');
			pageNameMap.put('2', 'RCSupportPortalKnowledgebase?ln=kb&pg=2');
			pageNameMap.put('3', 'RCSupportPortalLCHome?ln=lc&pg=3');
			pageNameMap.put('4', 'RCSupportPortalGuidesVideos?ln=all&pg=4');
			pageNameMap.put('5', 'RCSupportPortalDownloads?ln=all&pg=5');
			pageNameMap.put('6', 'RCContactSupp');
			
		}
		
	
		String src = ApexPages.currentPage().getParameters().get('src');
	
		if(String.isNotBlank(src)) {
			if(srcToKeyMap.get(src) != null) {
				srcURL = pageNameMap.get(src) +'' + targetURL;
				targetURL = srcToKeyMap.get(src);
			} 
		}
		
		
 		openDescriptionLst = new List<String>();
	 	resolveDescriptionLst = new List<String>();
	   	isPublicDescFound = false;
	   	RCSiteSetup__c  objSite = getSiteDetail();
	   	objStatus = new System_Status__c();
	   	String strRegion = 'US';
	   	strClassName = 'status-bg-right-green';
	         iconShade = 'fa fa-circle green';
	  
		if(objSite.Brand_Filter__c!=null){
			if(objSite.Brand_Filter__c.indexOf('US')>0){
				strRegion='US'; 
			} else if(objSite.Brand_Filter__c.indexOf('UK')>0){
				strRegion='UK';
			} else if(objSite.Brand_Filter__c.indexOf('CAN')>0){
				strRegion='CAN';
			}
			strRegion='%'+strRegion+'%';
	      	boolean flag = false;
	     	try {
	     		/* For Resolved Status
				   New Change - 20th November 2014 : No matter the color of the service status button, 
				                                     if there are any Resolved Issues resolved over 6 hours ago, 
				                                     the PFD for those issues should not be displayed on the Service Status bar.
				   Case Number - 03076521
				*/
		 		for(System_Status__c sysObj : [SELECT createdDate,IncidentID__c,Internal_Status__c,Public_Description__c,Region__c,Severity__c,
		                   							  Summary__c,System_Status__c,Name, Incident_Resolved_Date__c 
		                   					   FROM System_Status__c 
		                   					   WHERE Region__c Like : strRegion AND Severity__c != null AND Severity__c != '' AND 
		                   						((Internal_Status__c = 'RESOLVED' AND Incident_Resolved_Date__c > :system.now().addHours(-6)) OR  Internal_Status__c = 'CLOSED') 
		                   						order by  Severity__c desc, Incident_Resolved_Date__c desc NULLS LAST]) {
		        	if(((!String.isBlank(sysObj.Public_Description__c) && !sysObj.Public_Description__c.equalsIgnoreCase('false'))) && !string.isBlank(sysObj.Internal_Status__c)) {
	        			if((sysObj.Internal_Status__c.equalsIgnoreCase('RESOLVED') && sysObj.Incident_Resolved_Date__c > system.now().addHours(-6)) || 
	        			    sysObj.Internal_Status__c.equalsIgnoreCase('CLOSED')) {
	        		   		resolveDescriptionLst.add(String.isBlank(sysObj.Public_Description__c) ? '' : sysObj.Public_Description__c.trim());
	            		}
        			}           							
				} 
				/* For Open Status 
				   New Change - 20th November 2014 : If there are no Current Issues AND no Resolved Issues resolved within the last 6 hours: 
				                                     display the status as Green with proper message.
				                                   : Change the logic of status display as follows
				                                   		•         GREEN Status – when No Issues or Level 0 issues
														•         YELLOW Status – When Level 1 issues
														•         RED Status – When Level 2 + issues
				                                   
				   Case Number - 03076521
				*/
				
				List<String> level1 = new List<String>();
                List<String> level2 = new List<String>();
                List<String> level3 = new List<String>();
                List<String> level4 = new List<String>();
                List<String> levelNormal = new List<String>();
                List<String> levelCritical = new List<String>();
				
				for(System_Status__c sysObj : [SELECT createdDate,IncidentID__c,Internal_Status__c,Public_Description__c,Region__c,Severity__c,
		                   						      Summary__c,System_Status__c,Name 
		                   					   FROM System_Status__c 
		                   					   WHERE Region__c like : strRegion AND Severity__c != null AND Severity__c != '' AND 
		                   						(Internal_Status__c = 'OPEN' OR (Internal_Status__c = 'RESOLVED' AND Incident_Resolved_Date__c > :system.now().addHours(-6))) 
		                   						order by  Severity__c asc, Incident_Start_Date__c desc NULLS LAST]) {
		          
					if(((!String.isBlank(sysObj.Public_Description__c) && !sysObj.Public_Description__c.equalsIgnoreCase('false'))) && !string.isBlank(sysObj.Internal_Status__c)) {
	        			if(!sysObj.Internal_Status__c.equalsIgnoreCase('RESOLVED')) {
			            	if(flag == false && (!sysObj.Severity__c.EqualsIgnoreCase('Critical Ticket - Critical') && !sysObj.Severity__c.EqualsIgnoreCase('Critical Ticket - Normal'))) {
				            	flag = true;
				            	if(sysObj.Severity__c.EqualsIgnoreCase('Severity Level-3')){
								    strClassName = 'status-bg-right-orange';
								    iconShade = 'fa fa-circle yellow';
								} else if((sysObj.Severity__c.EqualsIgnoreCase('Severity Level-1') || sysObj.Severity__c.EqualsIgnoreCase('Severity Level-2'))){
								    strClassName='status-bg-right-red';
								    iconShade = 'fa fa-circle red';
								} else {
									strClassName = 'status-bg-right-green';
									iconShade = 'fa fa-circle green';
								}
			            	}
			            	//openDescriptionLst.add(String.isBlank(sysObj.Public_Description__c) ? '' : sysObj.Public_Description__c.trim());
			            }
        			}
        			
        			if(((!String.isBlank(sysObj.Public_Description__c) && !sysObj.Public_Description__c.equalsIgnoreCase('false'))) && !string.isBlank(sysObj.Internal_Status__c)) {
	        			if(!sysObj.Internal_Status__c.equalsIgnoreCase('RESOLVED')) {
		        			if(sysObj.Severity__c.EqualsIgnoreCase('Severity Level-1')){
		        				level1.add(String.isBlank(sysObj.Public_Description__c) ? '' : sysObj.Public_Description__c.trim());
		        			}
		        			
		        			if(sysObj.Severity__c.EqualsIgnoreCase('Severity Level-2')){
		        				level2.add(String.isBlank(sysObj.Public_Description__c) ? '' : sysObj.Public_Description__c.trim());
		        			}
		        			if(sysObj.Severity__c.EqualsIgnoreCase('Severity Level-3')){
		        				level3.add(String.isBlank(sysObj.Public_Description__c) ? '' : sysObj.Public_Description__c.trim());
		        			}
		        			if(sysObj.Severity__c.EqualsIgnoreCase('Severity Level-4')){
		        				level4.add(String.isBlank(sysObj.Public_Description__c) ? '' : sysObj.Public_Description__c.trim());
		        			}
		        			if(sysObj.Severity__c.EqualsIgnoreCase('Critical Ticket - Critical')){
		        				levelCritical.add(String.isBlank(sysObj.Public_Description__c) ? '' : sysObj.Public_Description__c.trim());
		        			}
		        			if(sysObj.Severity__c.EqualsIgnoreCase('Critical Ticket - Normal')){
		        				levelNormal.add(String.isBlank(sysObj.Public_Description__c) ? '' : sysObj.Public_Description__c.trim());
		        			}
        			
	        			}
        			}
				}
	           
	           if(level1.size()>0){
	           		openDescriptionLst.addAll(level1);
	           }
	           if(level2.size()>0){
	           		openDescriptionLst.addAll(level2);
	           }
	           if(level3.size()>0){
	           		openDescriptionLst.addAll(level3);
	           }
	           if(level4.size()>0){
	           		openDescriptionLst.addAll(level4);
	           }
	           if(levelCritical.size()>0){
	           		openDescriptionLst.addAll(levelCritical);
	           }
	           if(levelNormal.size()>0){
	           		openDescriptionLst.addAll(levelNormal);
	           }
	           	
		        if(resolveDescriptionLst.size() != 0 || openDescriptionLst.size() != 0) {
		        	isPublicDescFound = true;
		        } else {
		        	strClassName = 'status-bg-right-green';
		        	iconShade = 'fa fa-circle green';
		        }
     		} catch(Exception e) {
	       		//strException =e.getMessage();
	     	}
  		}
	}
	
	/************************************** To GET Site Details ************************************************************************/
   	private RCSiteSetup__c  getSiteDetail(){
   		RCSiteSetup__c siteSetup= null;
   		String siteName = null;
    	try {
    		if(Test.isRunningTest()){
    			siteName = 'rcsupport';
    		}
    		else{
    			siteName = Site.getName();
    		}
    		
         	if(siteName == null || siteName.length()==0) {
           		siteName = 'rcsupport';
          	}
        	siteSetup = [SELECT RCSiteName__c, RootCategoryName__c, CategoryGroupName__c, CacheMaxAge__c,
                       		Category1Description__c, Category2Description__c, Category3Description__c,
                       		Category4Description__c, Category5Description__c, Category6Description__c,
                       		HomeAdText__c, HomeAdTitle__c, Brand_Filter__c
                       		FROM RCSiteSetup__c
                       		WHERE RCSiteName__c = :siteName];
      	} catch (QueryException  e) {
      		System.debug('QueryException occurred???'+e);
     		siteSetup = new RCSiteSetup__c();
    	}
  	return siteSetup;
    }
    
  public Boolean getUKPortal(){
    if(Site.getName()!=null && Site.getName()!='' && (Site.getName()).lastIndexOfIgnoreCase('RCSupportPortalUK')>-1){
    return true;
    }
    return false;
  }
}