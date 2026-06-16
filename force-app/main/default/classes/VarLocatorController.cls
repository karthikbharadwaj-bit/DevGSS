public class VarLocatorController {
    /************** VARIABLE DECLARATION ****************/
    public String pin {get;set;} 
    public String fullAddress {get;set;} 
    public String travel{get;set;}
    public String errorvalue {get;set;}    
    public Account acc {get;set;} 
    public  string  traveldistance {get;set;}
    public  string selectedCountry {get;set;}
    public boolean hidemap {get;set;}
    public boolean refe {get;set;}
    public List<Account> acclst {get;set;} 
    public List<String> listOfAddresses {get; set;}
    public List<string> accNameList {get;set;}
    public List<wrapAcc> lstwrap {get;set;} 
    public Boolean toShowErrorMsg {get;set;}
    list<string> possibleUSNames = new list<string>{'US','USA','United States','United States of America'};
    list<string> possibleCanadaNames = new list<string>{'CA','CAN','Canada'};
    list<string> possibleUKNames = new list<string>{'UK','United Kingdom'};
    map<string,List<string>> mapCountryValues = new map<string,List<string>>{'USA' => possibleUSNames,'UK' => possibleUKNames,'CA' => possibleCanadaNames};
    
    /************* CONSTRUCTOR **************/
    public VarLocatorController() {
        refe = false ;
        lstwrap =  new list<wrapAcc>();
        acclst = new List<Account>();      
        listOfAddresses = new List<string>();
        accNameList = new List<string>();
        fullAddress = '';
        selectedCountry = 'USA';
        traveldistance = '30';
        acc = new Account();
    }
     
    public List<SelectOption> getTravelItems() {     
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('5','5'));
        options.add(new SelectOption('15','15'));
        options.add(new SelectOption('25','25'));
        options.add(new SelectOption('30','30'));
        return options;
    } 
    
    public List<SelectOption> getCountryItems() {     
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('USA','United States')); 
       options.add(new SelectOption('CA','Canada'));
        options.add(new SelectOption('UK','United Kingdom'));
        return options;
    }            
    
    public void newSearchForParners() {
       refe = false;
    }    
    string RCdistance= '50';
    public pagereference searchPartners() {
        refe = false;
        lstwrap = new list<wrapAcc>();
        listOfAddresses = new List<string>();
        accNameList = new List<string>();
        
        toShowErrorMsg = false;
        if(String.isBlank(pin)){       
            toShowErrorMsg = true;
            errorvalue = 'Please enter a valid Postal Code';
        }  else {  
            refe = true ;
            listOfAddresses.clear();
            system.debug('...../.>>>>'+acc.BillingPostalCode);
            system.debug('...../.>>>>'+acc.BillingPostalCode); 
            acclst=[SELECT  Id,Name,phone,BillingStreet, Contact_Email__c, BillingState,
                    Certifications__c,website, BillingPostalCode, BillingCountry,Technical_Certification__c, BillingCity From Account 
                    WHERE BillingPostalCode =:pin.trim() AND 
                    RecordtypeId=: OpportunityHelper.getOppRecordTypeMap('Partner Account') ];
                for(Account acc:acclst) {
                    fullAddress = '';
                    acc.BillingStreet = acc.BillingStreet == null ? '' : acc.BillingStreet.trim();
                    acc.BillingCity = acc.BillingCity == null ? '' : acc.BillingCity.trim();
                    acc.BillingState = acc.BillingState == null ? '' : acc.BillingState.trim();
                    acc.BillingPostalCode = acc.BillingPostalCode == null ? '' : acc.BillingPostalCode.trim(); 
                    acc.BillingCountry = acc.BillingCountry == null ? '' : acc.BillingCountry.trim(); 
                    fullAddress = (acc.BillingStreet != '' ? (acc.BillingStreet + ', ') : '') + (acc.BillingCity != '' ?(acc.BillingCity + ', ') : '') + (acc.BillingState != '' ?(acc.BillingState + ', ') : '') + (acc.BillingPostalCode != '' ?(acc.BillingPostalCode + ', ') : '') + acc.BillingCountry;
                    system.debug('...../.>>>>'+fullAddress);
                    listOfAddresses.add(fullAddress);
                    accNameList.add(acc.Name);
                    lstwrap.add(new wrapAcc(acc,fullAddress));
                    system.debug('...../.>>>>listOfAddresses'+ listOfAddresses);
                }
                    if(listOfAddresses.isEmpty()) {
                        refe = false;
                        toShowErrorMsg = true;
                        errorvalue = 'No Resellers found for your Postal Code';
                    }
        }
        return null;
    }
    
    public void callClearMapValues() {
        toShowErrorMsg = false;
        errorvalue = '';
        refe = false;
        pin = '';
        selectedCountry = 'USA';
        traveldistance = '30';
    }   
     public class wrapAcc{   
        public Account accObj{get;set;}
        public String accountId{get;set;}
        public string  accName{get;set;}
        public String accPhone{get;set;}
        public String accemail{get;set;}
        public String accWebsite{get;set;}
        public string fulladdress{get;set;}
            public wrapAcc(Account aobj,String fadd){
                accWebsite =aobj.Website;
                accountId = aobj.Id;
                accName = aobj.Name;
              accPhone = aobj.phone; 
              accWebsite = aobj.Website;
              if(!string.isBlank(accWebsite) && !(accWebsite.contains('http://') || accWebsite.contains('https://'))) {
                accWebsite = 'http://'+ aobj.Website;
              } 
                accObj =aobj; 
                accEmail =  aobj.Contact_Email__c;
                fulladdress = fadd;
            }
    }
       
    set<string> setZipCodes1 = new set<string>();
    public void getZipCodesInRadius() {
        refe = false;
        lstwrap = new list<wrapAcc>();
        setZipCodes1 = new set<string>();
        listOfAddresses = new List<string>();
        accNameList = new List<string>();
        toShowErrorMsg = false;
        if(String.isBlank(pin)) {       
            toShowErrorMsg = true;
            errorvalue = 'Please enter a valid Postal Code';
        } else {
            map<string,Decimal> mapDestinationToMiles = new map<string,Decimal>();
            refe = true ;
            listOfAddresses.clear();
            string zipcode = string.escapeSingleQuotes(pin);
            Integer radius = 5;
            radius = Integer.valueOf(traveldistance);
            setZipCodes1 = new set<string>();
            HttpRequest req1 = new HttpRequest();
            Http http1 = new Http();
            req1.setMethod('GET');
            
            req1.setEndPoint('http://api.geonames.org/findNearbyPostalCodesJSON?postalcode='+ zipcode +'&country='+ selectedCountry +'&radius='+ radius +'&username=ankit_24&maxRows=500');
            HTTPResponse resp1 = http1.send(req1);
            string jsonData1 = resp1.getBody();
            System.debug('>>jsonData>>'+jsonData1);
            if(jsonData1 != null) {
                WRZips wrObjZip = (WRZips)System.Json.deserialize(jsonData1,WRZips.class);
                if(wrObjZip != null && wrObjZip.postalCodes != null) {
                    for(WRNeighborZips neighborZipObj : wrObjZip.postalCodes) {
                        if(neighborZipObj.postalCode.trim() != zipcode.trim()) {
                            setZipCodes1.add(neighborZipObj.postalCode);
                            mapDestinationToMiles.put(neighborZipObj.postalCode,neighborZipObj.distance);
                        }
                    }
                }
                System.Debug('>>>wrObjZip>'+wrObjZip);
                System.Debug('>>>setZipCodes>'+setZipCodes1);
                
            }
            
            setZipCodes1.add(zipcode);
            mapDestinationToMiles.put(zipcode,Decimal.ValueOf('0'));
            System.debug('>>map>>'+ mapDestinationToMiles);
            System.Debug('>>>setZipCodes1>>'+ setZipCodes1);
            List<Account> lstAccount = new List<Account>();
            if(selectedCountry == 'USA') {
                lstAccount = [Select BillingStreet, BillingState, BillingPostalCode,Name,
                                phone,website, Contact_Email__c,
                                BillingCountry, BillingCity From Account where BillingPostalCode IN :setZipCodes1
                                and (BillingCountry IN :mapCountryValues.get('USA'))
                                and RecordType.Name = 'Partner Account' limit 40];
            } else if(selectedCountry == 'UK'){
                lstAccount = [Select BillingStreet, BillingState, BillingPostalCode,Name,
                                phone,website, Contact_Email__c,
                                BillingCountry, BillingCity From Account where BillingPostalCode IN :setZipCodes1
                                and (BillingCountry IN :mapCountryValues.get('UK'))
                                and RecordType.Name = 'Partner Account' limit 40];
            } else if(selectedCountry == 'CA') {
                lstAccount = [Select BillingStreet, BillingState, BillingPostalCode,Name,
                                phone,website, Contact_Email__c,
                                BillingCountry, BillingCity From Account where BillingPostalCode IN :setZipCodes1
                                and (BillingCountry IN :mapCountryValues.get('CA'))
                                and RecordType.Name = 'Partner Account' limit 40];
            }
            
            map<decimal,List<Account>> distanceToAccountListMap =  new map<decimal,List<Account>>();
            List<Decimal> distanceList = new List<Decimal>();
            for(Account accObj : lstAccount) {
              if(mapDestinationToMiles != null && mapDestinationToMiles.containskey(accObj.BillingPostalCode)) {
                List<Account> accList = new List<Account>();
                if(distanceToAccountListMap.get(mapDestinationToMiles.get(accObj.BillingPostalCode)) != null) {
                  accList = distanceToAccountListMap.get(mapDestinationToMiles.get(accObj.BillingPostalCode));
                }
                accList.add(accObj);
                distanceList.add(mapDestinationToMiles.get(accObj.BillingPostalCode));
                distanceToAccountListMap.put(mapDestinationToMiles.get(accObj.BillingPostalCode),accList);
              }
            }
            
            if(distanceList.size()>0) {
              system.Debug('>>>>distanceList1>>'+ distanceList);
              distanceList.sort();
              system.Debug('>>>>distanceList>>'+ distanceList);
            }
            
            set<Id> accountIdSet = new set<Id>();
            for(Decimal decimalObj : distanceList) {
              if(distanceToAccountListMap != null && distanceToAccountListMap.containsKey(decimalObj)) {
                for(Account accOb : distanceToAccountListMap.get(decimalObj)) {
                  system.Debug('>>>>accOb.BillingPostalCode>>'+ accOb.BillingPostalCode);
                  if(!accountIdSet.contains(accOb.id)) {
                    System.debug('>>accOb>>'+ accOb.id);
                      System.debug('>>mapDestinationToMiles.get(accOb.BillingPostalCode)>>'+mapDestinationToMiles.get(accOb.BillingPostalCode));

                      if(mapDestinationToMiles != null) {
                          fullAddress = '';
                          accOb.BillingStreet = accOb.BillingStreet == null ? '' : accOb.BillingStreet.trim();
                          accOb.BillingCity = accOb.BillingCity == null ? '' : accOb.BillingCity.trim();
                          accOb.BillingState = accOb.BillingState == null ? '' : accOb.BillingState.trim();
                          accOb.BillingPostalCode = accOb.BillingPostalCode == null ? '' : accOb.BillingPostalCode.trim(); 
                          accOb.BillingCountry = accOb.BillingCountry == null ? '' : accOb.BillingCountry.trim(); 
                          fullAddress = (accOb.BillingStreet != '' ? (accOb.BillingStreet + ', ') : '') + (accOb.BillingCity != '' ?(accOb.BillingCity + ', ') : '') + (accOb.BillingState != '' ?(accOb.BillingState + ', ') : '') + (accOb.BillingPostalCode != '' ?(accOb.BillingPostalCode + ', ') : '') + accOb.BillingCountry;
                          system.debug('...../.>>>>'+fullAddress);
                          listOfAddresses.add(fullAddress);
                          lstwrap.add(new wrapAcc(accOb,fullAddress));
                      }  
                  }
                        accountIdSet.add(accOb.id);    
                }
              }
            }
            
            if(listOfAddresses.isEmpty()) {
                refe = false;
                toShowErrorMsg = true;
                errorvalue = 'No Resellers found for your Postal Code';
            }
            System.debug('>>listOfAddresses>>'+ listOfAddresses);
        }                               
    } 
    
    public class WRJsonOutPutMiles {
      List<string> destination_addresses;
      List<string> origin_addresses;
      list<WRRows> rows;
      string status;    
    }
    
    public class WRRows {
       List<WRElement> elements;
    }
    
    public class WRElement {
        WRVAalues distance;
        WRVAalues duration;
        string status;
    }
    
    public class WRVAalues {
        string text;
        Decimal value;
    }
    
    public class WRZips {
        List<WRNeighborZips> postalCodes;
        string status;
        string message;
        string value;
    }
    
    public class WRNeighborZips {
        string postalCode;
        string adminName2;
        string adminName3;
        string adminCode3;
        string adminCode2;
        Decimal distance;
        string adminCode1;
        string countryCode;
        string lng;
        string placeName;
        string lat;
        string adminName1;
        string status;
    }
    
    public class WRMessage {
        string message;
    }
}