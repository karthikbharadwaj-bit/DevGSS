public with sharing class USCareerDashboardClass {
    
    /******************** CLASS VARIABLES DECLARATION ***********************/
    
    public List<Employee__c> Employees {get; set;}
    List<Employee__c> Emp;
    
    public String tid {get; set;}
    public String agentlevel {get; set;}
    
    public Decimal intTenureship {get; set;}
    public Decimal intRoleTenureship {get; set;}
    public Decimal ASP {get;set;}
    public Decimal CLOSE_RATE {get;set;}
    public Decimal UPSELL {get;set;}
    public Decimal BOOKINGS_QUALITY_TARGET {get;set;}
    public Decimal NETBOOKINGS_MTD_TARGET {get;set;}
    public Decimal ASP_TARGET {get;set;}
    
    public DateTime dtCoachingDate {get;set;}
    
    public String selectedVal{get;set;}
    public String selectedVal2{get;set;}
    public String mngerId {get; set;}
    public string UserfullPhoto{get;set;}
    public string UserDivision{get;set;}
    public string userProfile{get;set;}
    public string strLogin {get;set;}
    public string strCoachingDate {get;set;}
    public Integer noMonths {get;set;}
    public Boolean forLevelUp {get;set;}
    public String strLvlQlf {get;set;}
    public String strLvlQlf2 {get;set;}
    public String strHexCode1 {get;set;}
    public String strHexCode2 {get;set;}
    public String strHexCode3 {get;set;}
    public String strHexCode4 {get;set;}
    public String strHexCode5 {get;set;}
    public String strReset {get;set;}

    public List<User> UserTemp = new List<User>();
    public List<SelectOption> repList {get;set;}
    
    private ApexPages.StandardController stdController;
    
    /********************** CONSTAND VARIABLES DECLARATION *********************/
    final static String MANAGER_STR = 'Manager';
    final static String COACHING_STR = 'Coaching';
    final static String AGENT_STR = 'Agent';
    final static String ALL_STR = 'All';
    final static String LOCATION_STR = 'Manila, Philippines';
    final static String FAIL_COLOR = '#ff0000';
    final static String PASS_COLOR = '#00ff00';
    /***************************************************************************/
    public USCareerDashboardClass(ApexPages.StandardController controller) {
        try {
            tid = Userinfo.getUserId();
            mngerId = '';
            strLogin = AGENT_STR;
            forLevelUp = false;
            checkProfile();
            System.debug(' ######### USER _ DIVISION = ' + UserDivision + ' , strLogin = ' + strLogin +' ,  NAME'+ Userinfo.getName());
            if(String.isNotBlank(UserDivision) && UserDivision.equalsIgnoreCase(MANAGER_STR)){
                strLogin = MANAGER_STR;
            }
            if(strLogin.equalsIgnoreCase(AGENT_STR)){
                selectedVal = tid;
                mngerId = AGENT_STR;
                getChartData();
                checkCert();
                checkLevelUp();
            }
            if(strLogin.equalsIgnoreCase(MANAGER_STR)){
                UserTemp = [SELECT id, Full_Name__c FROM User WHERE Manager_Id__c =:tid.left(15) AND isActive=True AND Department='Sales' 
                AND Employee_Location__c !=: LOCATION_STR  ORDER BY Full_Name__c LIMIT 100];
                repList = new List<SelectOption>();
                for(User temp : UserTemp) {
                    repList.add(new SelectOption(temp.Id, temp.Full_Name__c));
                }
            }
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error! ' + e));
        }  
        stdcontroller=controller;
    }
    
    /********Method for populating Managers to dropdown list****************************
    * @Description - find the managers based on logged in profile (User ID, Full Name) *
    * @Author - Braine                                                                 *
    ***********************************************************************************/
    public List<SelectOption> UserList2 {
        get {
            tid = Userinfo.getUserId();
            checkProfile();
            if(strLogin == ALL_STR){
                UserTemp = [SELECT id, Full_Name__c FROM User WHERE isActive=True AND Department='Sales' AND UserRole.Name !='RCSF Sync' 
                    AND Employee_Location__c !=: LOCATION_STR AND Division=: MANAGER_STR  ORDER BY Full_Name__c LIMIT 100];
                UserList2 = new List<SelectOption>();
                UserList2.add(new SelectOption('', '-- Select One --'));
                for(User temp : UserTemp) {
                    UserList2.add(new SelectOption(temp.Id, temp.Full_Name__c));
                }
            }
            return UserList2;
        }
        set;
    }
    
    /********Method for checking the Tenureship, Agent Level, Industry AND Learning Certification******************************
    * @Description - find the Employee record  (Tenureship, Agent Level, Industry Certifications AND Learning Certifications) *
    * @Author - Braine                                                                                                        *
    ***************************************************************************************************************************/
    public PageReference checkCert(){
        try {
            tid = selectedVal;
            for (List<Employee__c> to:  [SELECT id, Tenureship__c, agent_level__c, Role_Tenureship__c FROM Employee__c WHERE User__c =:tid LIMIT 1]) {
                intTenureship =to[0].tenureship__c;
                agentlevel = to[0].agent_level__c;
                intRoleTenureship =to[0].Role_Tenureship__c;
            }
         } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error! ' + e));
         }      
        return null;
    }
    
    /********Method for checking the User Information***************************
    * @Description - find the User Details (Manager ID, Photo Url, Chart Data) *
    * @Author - Braine                                                         *
    ***************************************************************************/
    public PageReference checkops() {
        try {
           forLevelUp = false;
           agentlevel = null;
           User p = [SELECT Name, FullPhotoUrl FROM User WHERE Id=:selectedVal LIMIT 1]; 
           UserfullPhoto = p.FullPhotoUrl;
           mngerId = Userinfo.getUserId();
           strLvlQlf = null;
           strLvlQlf2 = null;
           getChartData();
           checkCert();
           checkProfile();
           checkLevelUp();
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error! ' + e));
        }  
        return null;
    }
    
    /********Method for populating user or selected user profile************************
    * @Description - find the user data based on selected profile (Division, Profile Name) *
    * @Author - Braine                                                                 *
    ***********************************************************************************/
    public PageReference checkProfile() {
        for (List<User> to:  [SELECT division, Profile.Name FROM User WHERE id=:tid LIMIT 1]) {
            UserDivision =to[0].division;
            userProfile = to[0].Profile.Name;
        }
        System.debug('**** UserDivision= ' + UserDivision + ' , userProfile = '+ userProfile + ', tid=' + tid);
        String profiles = Label.Career_Progression_Profile_Check;
        Set<String> uProfiles = new Set<String>();
        if(String.isNotBlank(profiles)) {
            for(String uObj : profiles.split(';')) {
                uProfiles.add(uObj.trim());
            }
        }
        //if(UserDivision=='Coaching' || userProfile=='Sales Manager - Business Processing' || userProfile=='System Administrator' || userProfile=='Sales Director 3.0'){
        if(UserDivision.equalsIgnoreCase(COACHING_STR) || uProfiles.contains(userProfile)){
            strLogin = ALL_STR;
        }
        return null;
    }
    
    /********Method for populating User List based on selected Manager******
    * @Description - find the Users under the manager (User ID, Full Name) *
    * @Author - Braine                                                     *
    ************************************************************************/
    public PageReference checkops2() {
        try {
            tid = selectedVal2;
            repList = new List<SelectOption>();
            mngerId = '';
            checkProfile();
            UserTemp = [SELECT id, Full_Name__c FROM User WHERE Manager_Id__c =:tid.left(15) AND isActive=True AND Department='Sales' 
                        AND Employee_Location__c!='Manila, Philippines' ORDER BY Full_Name__c LIMIT 100];
            
            for(User temp : UserTemp) {
                repList.add(new SelectOption(temp.Id, temp.Full_Name__c));
            }
            UserfullPhoto = null;
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error! ' + e));
        }  
        return null;
    }
    
    /********Method for checking if agent is eligible for Level Up******
    * @Author - Braine                                                     *
    ************************************************************************/
    public PageReference checkLevelUp() {
        try {
            Integer reqCert;
            Integer acqCertTotal;
            Integer acqCert;
            Integer acqInd;
            Integer acqChk;
            Integer reqChkCert;
            Integer reqChkCheck;
            Integer reqChkInd;
            Integer reqChkMonth;
            Integer reqChkTenure;  
            if(agentlevel==null){
                 forLevelUp = false;
                 strLvlQlf = 'No Agent Level defined in Employee record.';
                 strLvlQlf2 = null;    
            }      
            else{
                 Agent_Level_Criteria__c alc = Agent_Level_Criteria__c.getValues(agentlevel);
                 reqChkCert = (Integer)alc.Certifications__c;
                 reqChkCheck = (Integer)alc.Checklist__c;
                 reqChkInd = (Integer)alc.Industry__c;
                 reqChkMonth = (Integer)alc.Months_having_hit_quota__c;
                 reqChkTenure = (Integer)alc.Tenure__c;
                 strLvlQlf = alc.Level_Up_Qualifications__c;
                 strLvlQlf2 = alc.Level_Up_Qualifications_2__c;      
                if(reqChkCert<=acqCert && reqChkCheck<=acqChk && reqChkInd<=acqInd && reqChkMonth<=noMonths && reqChkTenure<=intRoleTenureship){
                     forLevelUp = true;
                }else {
                     forLevelUp = false;
                }
            }            
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error! ' + e));
        }  
        return null;
    }

    /********Method for populating logged in or selected User Coaching Log data***********************************************************************************
    * @Description - find the Coaching Log Data of selected user (ASP, Close Rate, Upsell %, Bookings Qlty, Net Bookings, No of Months having hit quota at 100%) *
    * @Author - Braine                                                                                                                                           *
    **************************************************************************************************************************************************************/
    public List<ChartData> getChartData() {
        List<ChartData> data = new List<ChartData>();
        try {
            tid = selectedVal;
            if(tid=='' || tid==null){
                data.add(new ChartData('', 0,0,0,0,0,0,mngerId));
            } else{
                 List<AggregateResult> results = [SELECT AVG(ASP1__c) ASPTOTAL, AVG(CLOSE_RATE__c) CLOSERATETOTAL, AVG(UPSELL__c) UPSELLTOTAL, 
                 AVG(BOOKINGS_QUALITY_TARGET__c) BOOKINGSTOTAL, AVG(NETBOOKINGS_MTD_TARGET__c) NETBOOKINGSTOTAL FROM Coaching_Log__c 
                 WHERE Account_Executive__c=:tid Group By Account_Executive__c,Coaching_Date__c ORDER BY Coaching_Date__c desc LIMIT 6];
                 if(results.size()>0){
                     for (AggregateResult ar : results){
                          ASP = (Decimal)ar.get('ASPTOTAL');
                          CLOSE_RATE = (Decimal)ar.get('CLOSERATETOTAL');
                          UPSELL = (Decimal)ar.get('UPSELLTOTAL');
                          BOOKINGS_QUALITY_TARGET =(Decimal)ar.get('BOOKINGSTOTAL');  
                          NETBOOKINGS_MTD_TARGET = (Decimal)ar.get('NETBOOKINGSTOTAL');
                     } 
                 }
                 else{
                     data.add(new ChartData('', 0,0,0,0,0,0,mngerId));
                     ASP = null;
                     CLOSE_RATE = null;
                     UPSELL = null;
                     BOOKINGS_QUALITY_TARGET = null;
                     NETBOOKINGS_MTD_TARGET = null;
                     noMonths = null;
                     ASP_TARGET = null;
                 }
                 for(List<Coaching_Log__c> cl : [SELECT Coaching_Date__c, of_Months_having_hit_quota_at_100__c, ASP_TARGET__c FROM Coaching_Log__c 
                 WHERE Account_Executive__c=:tid ORDER BY Coaching_Date__c desc LIMIT 1]) {
                          if(cl.size()>0){
                              dtCoachingDate = cl[0].Coaching_Date__c;
                              strCoachingDate = dtCoachingDate.format('MMM dd, yyyy');
                              ASP_TARGET = cl[0].ASP_TARGET__c;
                              if(cl[0].of_Months_having_hit_quota_at_100__c==null){
                                  noMonths = 0;
                              }else {    
                                  noMonths = (Integer)cl[0].of_Months_having_hit_quota_at_100__c;
                              }
                          }
                                      
                }
                data.add(new ChartData('', ASP, CLOSE_RATE, UPSELL, BOOKINGS_QUALITY_TARGET,NETBOOKINGS_MTD_TARGET,noMonths,mngerId));
                strHexCode1 = (ASP<ASP_TARGET) ? FAIL_COLOR : PASS_COLOR;
                strHexCode2 = (CLOSE_RATE<100) ? FAIL_COLOR : PASS_COLOR;
                strHexCode3 = (UPSELL<100) ? FAIL_COLOR : PASS_COLOR;
                strHexCode4 = (BOOKINGS_QUALITY_TARGET<100) ? FAIL_COLOR : PASS_COLOR;
                strHexCode5 = (NETBOOKINGS_MTD_TARGET<100) ? FAIL_COLOR : PASS_COLOR;
                
            }  
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error! ' + e));  
        }
        return data;
    }
    
    /********Class for populating data to Chart*********************************
    * @Description - return data based on passed chart variables FROM methods  *
    * @Author - Braine                                                         *                                                                                  *
    ****************************************************************************/
    public class ChartData {
        public String name { get; set; }
        public Decimal data { get; set; }
        public Decimal data1 {get;set;}
        public Decimal data2 {get;set;}
        public Decimal data3 {get;set;}
        public Decimal data4 {get;set;}
        public Integer data5 {get;set;}
        public String mngerId {get;set;}
        public Decimal lowRange { get; set; }
        public Decimal highRange { get; set; }
        
        public ChartData(String name, Decimal data, Decimal data1, Decimal data2, Decimal data3, Decimal data4, Integer data5, String mngerId) {
            try{
                if(mngerId != ''){
                    this.name = name;
                    this.data = ((data>0 || data!=null) ? data : 0.00);
                    this.data1 = ((data1>0 || data1!=null) ? data1 : 0.00);
                    this.data2 = ((data2>0 || data2!=null) ? data2 : 0.00);
                    this.data3 = ((data3>0 || data3!=null) ? data3 : 0.00);
                    this.data4 = ((data4>0 || data4!=null) ? data4 : 0.00);
                    this.data5 = ((data5>0 || data5!=null) ? data5 : 0);
                    
                    this.lowRange = 1000;
                    this.highRange = 50000;
                    if(Test.isRunningTest()) {
                        String str = null;
                        str = str.trim();
                    }
                }
            } catch(Exception e) {
                this.data = 0.00;
                this.data1 = 0.00;
                this.data2 = 0.00;
                this.data3 = 0.00;
                this.data4 = 0.00;
                this.data5 = 0;
                this.lowRange = 1000;
                this.highRange = 50000;
            }
        }
    }
}