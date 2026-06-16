public class SupportPortalSitemapController {
  // A property to return the proper Sites URL, used to build our full URL later
public string siteUrl{
  get{
    String surl = site.getBaseSecureUrl();
    if (surl != '' && surl != null) {
        return surl;
    } else {
        return site.getBaseUrl();
    }
  }
  set;
}
public Boolean getUKPortal(){
   if(Site.getName()!=null && Site.getName()!='' && (Site.getName()).lastIndexOfIgnoreCase('RCSupportPortalUK')>-1){ 
     return true;
   }
  return false;
}
// A method to retrieve the most recent 1000 FAQ__kav articles
public Knowledge__kav[] getFAQList(){  
  List<Knowledge__kav> objList = new List<Knowledge__kav>();
    try {
      Set<String> setArticleId=new Set<String>();
      Boolean isUKPortal=getUKPortal();
      
      for(Knowledge__DataCategorySelection objdata:[Select r.Parent.ArticleNumber,r.Parent.KnowledgeArticleId, r.ParentId,
                                 r.DataCategoryGroupName,r.DataCategoryName  From Knowledge__DataCategorySelection r where r.Parent.PublishStatus='Online']){
      
       if(isUKPortal && objdata.DataCategoryGroupName=='RCProductVersion' && (objdata.DataCategoryName=='ALL' || objdata.DataCategoryName=='RCUK2013')){
          setArticleId.add(objdata.ParentId);
       }else if(!isUKPortal && objdata.DataCategoryGroupName=='RCProductVersion' && (objdata.DataCategoryName=='ALL' || objdata.DataCategoryName=='RC2013') ){
            setArticleId.add(objdata.ParentId);
        } 
        
        
      }
    objList = [Select r.UrlName, r.Title,r.KnowledgeArticleId,r.LastPublishedDate,RC_Knowledge_Article_Ranking__c From Knowledge__kav r  where PublishStatus='Online'
                                            AND id IN:setArticleId AND IsVisibleInPkb = true ORDER BY RC_Knowledge_Article_Ranking__c,LastPublishedDate DESC];
    } catch(Exception e) {}
  return objList; 
}
}