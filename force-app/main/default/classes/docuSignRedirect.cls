public class docuSignRedirect {    

    
    public PageReference docusignRedirectURL() 
    {
          Pagereference page = Page.dsfs__DocuSign_CreateEnvelope;
          String docuSignURL=page.getUrl();

          
          String pageParameters = '';
          
          if(ApexPages.currentPage().getParameters()!=null)
          {
          
            String sourceId = ApexPages.currentPage().getParameters().get('SourceID');
            if (!String.isEmpty(sourceId)) {
               pageParameters = pageParameters + '&SourceID=' + sourceId;
            }
            
            String crl = ApexPages.currentPage().getParameters().get('CRL');
            if (!String.isEmpty(crl)) {
               pageParameters = pageParameters + '&CRL=' + crl;
            }
               
            String res = ApexPages.currentPage().getParameters().get('RES');
            if (!String.isEmpty(res)) {
               pageParameters = pageParameters + '&RES=' + res;
            }
              
            String dseid = ApexPages.currentPage().getParameters().get('DSEID');
            if (!String.isEmpty(dseid)) { 
               pageParameters = pageParameters + '&DESID=' + dseid;
            }
           
            page = new PageReference(docuSignURL + pageParameters);
            
            page.setRedirect(true);
          }
          return page;
    }
    

}