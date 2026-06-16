public class chiliPiperRedirect {    
    public PageReference chiliPiperRedirectURL() 
    {
          String chiliPiperURL='';
          PageReference page;
          String pageParameters='';
          if(ApexPages.currentPage().getParameters()!=null)
          {
              String user_id = ApexPages.currentPage().getParameters().get('user_id');
              String first_name = ApexPages.currentPage().getParameters().get('first_name');
              String last_name = ApexPages.currentPage().getParameters().get('last_name');
              String email = ApexPages.currentPage().getParameters().get('email');
              String phone = ApexPages.currentPage().getParameters().get('phone');
              String brandName = ApexPages.currentPage().getParameters().get('brand');
              String service_id = ApexPages.currentPage().getParameters().get('service_id');
              String locale = ApexPages.currentPage().getParameters().get('locale');  
              String return_url = ApexPages.currentPage().getParameters().get('return_url');            
              if (!String.isEmpty(brandName)){ 
                  pageParameters = 'brand=' + brandName;   
              }            
              if (!String.isEmpty(user_id))
              {
                  if(pageParameters != '')
                  {
                      pageParameters += '&'; 
                  }
                  pageParameters += 'user_id=' + user_id; 
              }                                 
              if (!String.isEmpty(first_name)) 
              {
                  if(pageParameters != '')
                  {
                      pageParameters += '&'; 
                  }
                  pageParameters += 'first_name=' + first_name; 
              }                              
              if (!String.isEmpty(last_name)) 
              {
                  if(pageParameters != '')
                  {
                      pageParameters += '&'; 
                  }
                  pageParameters += 'last_name=' + last_name;
              }                                  
              if (!String.isEmpty(email)) 
              {
                  if(pageParameters != '')
                  {
                      pageParameters += '&'; 
                  }
                  pageParameters += 'email=' + email;    
              }                              
              if (!String.isEmpty(phone))
              {
                  if(pageParameters != '')
                  {
                      pageParameters += '&'; 
                  }
                  pageParameters += 'phone=' + phone;
              }                                    
              if (!String.isEmpty(service_id)) 
              {
                  if(pageParameters != '')
                  {
                      pageParameters += '&'; 
                  }
                  pageParameters += 'service_id=' + service_id;
              }
              if (!String.isEmpty(return_url)) 
              {
                  if(pageParameters != '')
                  {
                      pageParameters += '&'; 
                  }
                  pageParameters += 'return_url=' + return_url;
              }
                 
                                                 
              List<Chili_Piper__mdt> lstChiliPiperURLMapping = [select Brand__c,URL__c from Chili_Piper__mdt where Brand__c=:brandName];
              if(lstChiliPiperURLMapping.size()>0)
              {
                    chiliPiperURL = lstChiliPiperURLMapping[0].URL__c;
                    page = new PageReference(chiliPiperURL + '?' + pageParameters);
                    page.setRedirect(true);
              }  
              else
              {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Invalid Brand Name'));
              }    
          }
          return page;
    }
}