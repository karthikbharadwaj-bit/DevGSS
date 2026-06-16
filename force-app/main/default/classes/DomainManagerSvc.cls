public class DomainManagerSvc implements IDomainManagerSvc{

    public Interface IDomainManagerSvc {
        String getDomainPartFromUrl(String url);
        String getDomainPartFromEmailAddress(String emailAddress);
        Boolean domainIsInIgnoredDomainList(String inputDomain);
    }
    
    Map<String, String> domainPartFromUrlCache = new Map<String, String>();
    public String getDomainPartFromUrl(String url){
        if(string.isEmpty(url)){
            return null;
        }
        String domainPartInCache = domainPartFromUrlCache.get(url);
        if(domainPartInCache != null){
            return domainPartInCache;
        }
        Pattern validDomainPattern = 
            Pattern.compile('^((http|https)://)??(www[.])??([a-zA-Z0-9]|-)+?([.][a-zA-Z0-9(-|/|=|?)??]+?)+?$');
        Matcher validDomainMatcher = validDomainPattern.matcher(url);
        if(!validDomainMatcher.matches()){
            domainPartFromUrlCache.put(url, '');
            return '';
        }
        
        url = (url.contains('http://') ? url.substringAfter('http://') : url);
        url = (url.contains('https://') ? url.substringAfter('https://') : url);
        url = (url.contains('www.') ? url.substringAfter('www.') : url);
        url = (url.contains('/') ? url.substringBefore('/') : url);
        
        domainPartFromUrlCache.put(url, url.toLowerCase());
        return url.toLowerCase();
    }

    public String getDomainPartFromEmailAddress(String emailAddress){
        if(!String.isEmpty(emailAddress)){
            return emailAddress.substringAfter('@').toLowerCase();
        }
        return null;
    }

    Map<String, Boolean> queriedDomainsCache = new Map<String, Boolean>();
    public Boolean domainIsInIgnoredDomainList(String inputDomain){
        Boolean domainInCache = queriedDomainsCache.get(inputDomain);
        if(domainInCache != null){
            return domainInCache;
        }
        Set<String> blackList = CompanyMatchingIgnoredDomains__c.getAll().keyset();

        String currentSearch = '';
        for(String currentItem : blackList){
            //System.Debug('currentItem:::' + currentItem);
            if(currentItem.Contains('*')){
                currentSearch = currentItem.remove('*');
                if(inputDomain.contains(currentSearch)){
                    queriedDomainsCache.put(inputDomain, true);
                    return true;
                }
            } else {
                if(inputDomain == currentItem) {
                    queriedDomainsCache.put(inputDomain, true);
                    return true;
                }
            }		
        }
        queriedDomainsCache.put(inputDomain, false);
        return false;
    }
}