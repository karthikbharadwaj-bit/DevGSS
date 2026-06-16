public with sharing class ManilaCareerDashboardClass
{
    public List<Employee__c> Employees {get; set;}
    List<Employee__c> Emp;
    public String tid {get; set;}
    public String agentlevel {get; set;}
    public Boolean industrycert1 {get;set;}
    public Boolean industrycert2 {get;set;}
    public Boolean industrycert3 {get;set;}
    public Boolean industrycert4 {get;set;}
    public Boolean industrycert5 {get;set;}
    public Boolean industrycert6 {get;set;}
    public Decimal intTenureship {get; set;}
    public Decimal incidentPoint  {get; set;}
    public Decimal QMFScore {get; set;}
    public Decimal NPSScore {get; set;}
    private ApexPages.StandardController stdController;
    public String selectedVal{get;set;}
    public List<User> UserTemp = new List<User>();
    public String MngerId {get; set;}
    public Decimal SalesPerf {get; set;}
    public string UserfullPhoto{get;set;}
    public string UserDivision{get;set;}
    public string UserProfile{get;set;}
    public String kevinWilliamsUser { get;set; }
    public String neilSerranoUser { get;set; }
    public String adminProfile { get;set; }
    public Set<String> salesProfile  {get;set;} //----- created to store Sales Mgr profile and its EU restricted one - EU Privacy Phase 3 changes

    public ManilaCareerDashboardClass(ApexPages.StandardController controller){
         try {
             kevinWilliamsUser = HardcodedIdsMapper.getMatchedObjectId('00580000003v7OfAAI');
             neilSerranoUser = HardcodedIdsMapper.getMatchedObjectId('0058000000383lXAAQ');
             adminProfile = HardcodedIdsMapper.getMatchedObjectId('00e80000000l1hKAAQ');
             salesProfile = new Set<String>();
               //EU Privacy Phase 3 Changes - START
              List<EU_Component_reference__mdt> profileList = [Select DeveloperName, Values__c from EU_Component_reference__mdt where Apex_Classes__c like '%ManilaCareerDashboardClass%' and developername = 'ManilaCareerDashboard'];
              for(EU_Component_reference__mdt profRec:profileList){
              	if(String.isNotBlank(profRec.Values__c)) {
                  salesProfile.addall(profRec.Values__c.split(','));
                }
              }
              //EU Privacy Phase 3 Changes - END
          tid = Userinfo.getUserId();

                    for (List<Employee__c> to:  [SELECT id, Tenureship__c, agent_level__c, Industry_Certified_Legal__c, Industry_Certified_Healthcare__c, Industry_Certified_High_Technology__c, Industry_Certified_Government__c, Industry_Certified_Real_Estate__c, Industry_Certified_Construction__c FROM Employee__c where User__c =:tid ]) {
                    intTenureship =to[0].tenureship__c;
                    agentlevel = to[0].agent_level__c;
                    industrycert1 = to[0].Industry_Certified_Legal__c;
                    industrycert2 = to[0].Industry_Certified_Healthcare__c;
                    industrycert3 = to[0].Industry_Certified_High_Technology__c;
                    industrycert4 = to[0].Industry_Certified_Government__c;
                    industrycert5 = to[0].Industry_Certified_Real_Estate__c;
                    industrycert6 = to[0].Industry_Certified_Construction__c;
                    }
                    
                    if(agentlevel == ''){
                    agentlevel = 'Level 0';
                    }
                    
                    incidentPoint = 0.00;
                    

                    QMFScore = 0.00;
                    if(agentlevel =='Level 0'){
                        for(AggregateResult ar2 : [SELECT avg(Overall_ACE_Score__c) avg from quality_monitoring_form__c where agent_name__r.id=:tid and QMF_Info__c='Completed' and Monitored_Date__c = LAST_N_MONTHS:3]) {
                          QMFScore = (Decimal) ar2.get('avg');
                        }
                    }
                    else if(agentlevel=='Level 1'){
                        for(AggregateResult ar2 : [SELECT avg(Overall_ACE_Score__c) avg from quality_monitoring_form__c where agent_name__r.id=:tid and QMF_Info__c='Completed' and Monitored_Date__c = LAST_N_MONTHS:6]) {
                          QMFScore = (Decimal) ar2.get('avg');
                        }
                    }
                    else{
                        for(AggregateResult ar2 : [SELECT avg(Overall_ACE_Score__c) avg from quality_monitoring_form__c where agent_name__r.id=:tid and QMF_Info__c='Completed' and Monitored_Date__c = LAST_N_MONTHS:1]) {
                          QMFScore = (Decimal) ar2.get('avg');
                        }
                    }
                    
                    SalesPerf= 0.00;
                    
                    NPSScore = 0.00;
                    for(AggregateResult ar3 : [select SUM(sales_ltr_eval__c) nps1, SUM(Likely_to_Recommend_Rel__c) nps2, count(id) cnt from Survey__c where OwnerID=:tid and Response_Date__c = LAST_N_MONTHS:6]) {
                          NPSScore = ((Integer) ar3.get('nps1') + (Integer) ar3.get('nps2')) / (Integer) ar3.get('cnt');
                    }


                   MngerId = tid;
                   
          } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error! ' + e));
          }  
          stdcontroller=controller;
    }

    public List<SelectOption> UserList
    {
        get
        {
                    tid = Userinfo.getUserId();
                    
                    for (List<User> to:  [SELECT division, ProfileID FROM User where id=:tid ]) {
                    UserDivision =to[0].division;
                    UserProfile = to[0].ProfileId;
                    }
                    
                    if(tid== kevinWilliamsUser) {
                        UserTemp = [SELECT id, Full_Name__c FROM User where Manager_Id__c in :HardcodedIdsMapper.getMatchedObjectId(new List<String>{'00580000001uUVe','00580000001h4uu','00580000003tAKS','00580000005T9ym','00580000003d8K1'}) and isactive=True order by Full_Name__c];
                    }
                    if(tid== neilSerranoUser) {
                        UserTemp = [SELECT id, Full_Name__c FROM User where Manager_Id__c in :HardcodedIdsMapper.getMatchedObjectId(new List<String>{'00580000001ufzn','0058000000379Z1','00580000001hRXh','00580000008HT8K','00580000003d8Iy','00580000008VIAr','00580000004dtCR','005800000037OaK','00580000003bzV7'}) and isactive=True order by Full_Name__c];
                    }
                    if(UserDivision=='Coaching' && !(tid== kevinWilliamsUser && tid== neilSerranoUser)) {
                        UserTemp = [SELECT id, Full_Name__c FROM User where isactive=True and Department='Sales' and UserRole.Name!='RCSF Sync' and (Employee_Location__c='Manila, Philippines' or id= :HardcodedIdsMapper.getMatchedObjectId('0058000000643Sj'))  order by Full_Name__c];
                    }
                    if(UserDivision=='Manager' && (tid!= kevinWilliamsUser && tid!= neilSerranoUser)) {
                        UserTemp = [SELECT id, Full_Name__c FROM User where Manager_Id__c =:tid.left(15) and isactive=True and Department='Sales' and Employee_Location__c='Manila, Philippines' order by Full_Name__c];
                    }
                    if(salesProfile.contains(UserProfile) || UserProfile== adminProfile) {
                        UserTemp = [SELECT id, Full_Name__c FROM User where isactive=True and Department='Sales' and UserRole.Name!='RCSF Sync' and (Employee_Location__c='Manila, Philippines' or id= :HardcodedIdsMapper.getMatchedObjectId('0058000000643Sj')) order by Full_Name__c];
                    }
                    UserList = new List<SelectOption>();
                    UserList.add(new SelectOption('', '--- Select User ---')); 
                    for(User temp : UserTemp)
                    {
                        UserList.add(new SelectOption(temp.Id, temp.Full_Name__c));
                    }
             return UserList;
        }
        set;
    }
    
    
    public PageReference checkops()
    {
    
    try {

                    for (List<Employee__c> to:  [SELECT id, Tenureship__c, agent_level__c, Industry_Certified_Legal__c, Industry_Certified_Healthcare__c, Industry_Certified_High_Technology__c, Industry_Certified_Government__c, Industry_Certified_Real_Estate__c, Industry_Certified_Construction__c FROM Employee__c where User__c =:selectedVal]) {
                    intTenureship =to[0].tenureship__c;
                    agentlevel = to[0].agent_level__c;
                    industrycert1 = to[0].Industry_Certified_Legal__c;
                    industrycert2 = to[0].Industry_Certified_Healthcare__c;
                    industrycert3 = to[0].Industry_Certified_High_Technology__c;
                    industrycert4 = to[0].Industry_Certified_Government__c;
                    industrycert5 = to[0].Industry_Certified_Real_Estate__c;
                    industrycert6 = to[0].Industry_Certified_Construction__c;
                    }
                    
                    if(agentlevel == ''){
                    agentlevel = 'Level 0';
                    }
                    
                    incidentPoint = 0.00;
                    
                    QMFScore = 0.00;
                    if(agentlevel =='Level 0'){
                        for(AggregateResult ar2 : [SELECT avg(Overall_ACE_Score__c) avg from quality_monitoring_form__c where agent_name__r.id=:selectedVal and QMF_Info__c='Completed' and Monitored_Date__c = LAST_N_MONTHS:3]) {
                          QMFScore = (Decimal) ar2.get('avg');
                        }
                    }
                    else if(agentlevel=='Level 1'){
                        for(AggregateResult ar2 : [SELECT avg(Overall_ACE_Score__c) avg from quality_monitoring_form__c where agent_name__r.id=:selectedVal and QMF_Info__c='Completed' and Monitored_Date__c = LAST_N_MONTHS:6]) {
                          QMFScore = (Decimal) ar2.get('avg');
                        }
                    }
                    else{
                        for(AggregateResult ar2 : [SELECT avg(Overall_ACE_Score__c) avg from quality_monitoring_form__c where agent_name__r.id=:selectedVal and QMF_Info__c='Completed' and Monitored_Date__c = LAST_N_MONTHS:1]) {
                          QMFScore = (Decimal) ar2.get('avg');
                        }
                    }
                    
                    SalesPerf= 0.00;
                    
                    User p = [Select Name, FullPhotoUrl From User where Id=:selectedVal]; 
                    UserfullPhoto = p.FullPhotoUrl;
                    
                    NPSScore = 0.00;
                    for(AggregateResult ar3 : [select SUM(sales_ltr_eval__c) nps1, SUM(Likely_to_Recommend_Rel__c) nps2, count(id) cnt from Survey__c where OwnerID=:selectedVal and Response_Date__c = LAST_N_MONTHS:6]) {
                          NPSScore = ((Decimal) ar3.get('nps1') + (Decimal) ar3.get('nps2')) / (Decimal) ar3.get('cnt');
                    }
                    

                   MngerId = tid;
                   
          } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error! ' + e));
          }  

        return null;
    }

    }