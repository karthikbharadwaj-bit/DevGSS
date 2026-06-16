public  class MultiSheetExcelGenerate {
    public DataModel dm {get;set;}
       
   //TerritoryChangeController controller
 
     public String obj {get;set;}
   	 public Id userid;
   	 public String objType;	
   	 public String name;
       
    public MultiSheetExcelGenerate(){
       userid = Apexpages.currentPage().getParameters().get('userid');
       objType = Apexpages.currentPage().getParameters().get('objtype');
       name = Apexpages.currentPage().getParameters().get('username');
       obj = objtype;
        
        dm = new DataModel();
        dm.data = new list<DataModel.Model>();

   System.debug('--------------------------------------------ExcelClass-----------------'+userid);     
   System.debug('--------------------------------------------ExcelClass-----------------'+objType); 
   System.debug('--------------------------------------------ExcelClass-----------------'+obj); 
   //CURRENT_OWNER__C   CURRENT_OWNER_EMAIL__C  CURRENT_OWNER_NAME__C
   
    if(objType == 'Account'){
    DataModel.Model model = new DataModel.Model();
        model.sheetname = 'Account';
        model.headers = new list<string>{'Id','OwnerId','Current_Owner__c','CURRENT_OWNER_EMAIL__C','CURRENT_OWNER_NAME__C'};
        model.data = new list<map<string,string>>();
        for(Account act: [SELECT Id, OwnerId,Current_Owner__c,Current_Owner_Email__c ,CURRENT_OWNER_NAME__C  from Account Where Current_Owner__c =:userid LIMIT 10000]){
            map<string,string> rowdata = new map<string,string>();
             rowdata.put('Id',act.Id);
            rowdata.put('OwnerId',act.OwnerId);
            rowdata.put('Current_Owner__c',act.Current_Owner__c);
            rowdata.put('CURRENT_OWNER_EMAIL__C',(act.CURRENT_OWNER_EMAIL__C == null ? '':act.CURRENT_OWNER_EMAIL__C));
            rowdata.put('CURRENT_OWNER_NAME__C',(act.CURRENT_OWNER_NAME__C == null ? '':act.CURRENT_OWNER_NAME__C)); 
            model.data.add(rowdata);
        }
        dm.data.add(model);
    } 
     if(objType == 'Lead'){
    DataModel.Model model = new DataModel.Model();
        model.sheetname = 'Lead';
       model.headers = new list<string>{'Id','OwnerId','OWNER_MANAGER_EMAIL__C','OWNER_MANAGER_NAME__C'};
        model.data = new list<map<string,string>>();
        for(Lead act: [SELECT Id, OwnerId,OWNER_MANAGER_EMAIL__C,OWNER_MANAGER_NAME__C   from Lead Where Ownerid =:userid And isConverted=false LIMIT 10000]){
            map<string,string> rowdata = new map<string,string>();
            rowdata.put('Id',act.Id);
            rowdata.put('OwnerId',act.OwnerId);
            rowdata.put('OWNER_MANAGER_EMAIL__C',(act.OWNER_MANAGER_EMAIL__C == null ? '':act.OWNER_MANAGER_EMAIL__C));
            rowdata.put('OWNER_MANAGER_NAME__C',(act.OWNER_MANAGER_NAME__C == null ? '':act.OWNER_MANAGER_NAME__C)); 
            model.data.add(rowdata);
        }
        dm.data.add(model);
    } 
    
    if(objType == 'Case'){
    DataModel.Model model = new DataModel.Model();
        model.sheetname = 'Case';
       model.headers = new list<string>{'Id','OwnerId'};
        model.data = new list<map<string,string>>();
        for(Case act: [SELECT Id, OwnerId  from Case Where Ownerid =:userid LIMIT 10000]){
            map<string,string> rowdata = new map<string,string>();
            rowdata.put('Id',act.Id);
            rowdata.put('OwnerId',act.OwnerId);
            model.data.add(rowdata);
        }
        dm.data.add(model);
    } 
    
    if(objType == 'Contact'){
    DataModel.Model model = new DataModel.Model();
        model.sheetname = 'Contact';
       model.headers = new list<string>{'Id','OwnerId'};
        model.data = new list<map<string,string>>();
        for(Contact act: [SELECT Id, OwnerId  from Contact Where Ownerid =:userid LIMIT 10000]){
            map<string,string> rowdata = new map<string,string>();
            rowdata.put('Id',act.Id);
            rowdata.put('OwnerId',act.OwnerId);
            model.data.add(rowdata);
        }
        dm.data.add(model);
    } 
    
      if(objType == 'Opportunity'){
    DataModel.Model model = new DataModel.Model();
        model.sheetname = 'Opportunity';
       model.headers = new list<string>{'Id','OwnerId','OWNER_MANAGER_EMAIL__C','OWNER_MANAGER_NAME__C'};
        model.data = new list<map<string,string>>();
        for(Opportunity act: [SELECT Id, OwnerId,OWNER_MANAGER_EMAIL__C,OWNER_MANAGER_NAME__C   from Opportunity Where Ownerid =:userid LIMIT 10000]){
            map<string,string> rowdata = new map<string,string>();
            rowdata.put('Id',act.Id);
            rowdata.put('OwnerId',act.OwnerId);
            rowdata.put('OWNER_MANAGER_EMAIL__C',(act.OWNER_MANAGER_EMAIL__C == null ? '':act.OWNER_MANAGER_EMAIL__C));
            rowdata.put('OWNER_MANAGER_NAME__C',(act.OWNER_MANAGER_NAME__C == null ? '':act.OWNER_MANAGER_NAME__C)); 
            model.data.add(rowdata);
        }
        dm.data.add(model);
    } 
  }
}