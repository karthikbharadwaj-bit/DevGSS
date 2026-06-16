public class SitemapController {
    // A property to return the proper Sites URL, used to build our full URL later
  public string siteUrl{
    get{
        String surl = site.getcustomwebaddress();
        if (surl != '' && surl != null) {
            return site.getcustomwebaddress();
        } else {
            return site.getcurrentsiteurl();
        }
    }
    set;
  } 

  public Knowledge__kav[] getFAQList(){  
    List<Knowledge__kav> objList = new List<Knowledge__kav>();
    try {
        Set<String> setArticleId=new Set<String>();
        for(Knowledge__DataCategorySelection objCat:[Select r.Parent.ArticleNumber,r.Parent.KnowledgeArticleId, r.ParentId 
                                   From Knowledge__DataCategorySelection r where r.Parent.PublishStatus='Online']){
            setArticleId.add(objCat.ParentId);  
        }
        objList = [Select r.UrlName, r.Title,r.KnowledgeArticleId,r.LastPublishedDate From Knowledge__kav r  where PublishStatus='Online'
                                            AND id IN:setArticleId AND IsVisibleInPkb = true ORDER BY LastPublishedDate DESC LIMIT 1000];
    } catch(Exception e) {}
    return objList; 
}
}