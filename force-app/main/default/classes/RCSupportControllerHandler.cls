public class RCSupportControllerHandler {
    public String str { get; set; }
    public Boolean isGuestUser { get; set; }
    public String strSeesionId { get; set; }
    public Boolean isTokenFound { get; set; }
    public String strPageUrl { get; set; }
    public String strPostFix = '';
    public User objUser { get; set; }
    public String strLCClassName { get; set; }
    public map<String, String> mapArticleUrl { get; set; }
    public map<String, String> mapArticleSummary { get; set; }
    public String siteArticle { get; set; }
    public List<String> articleOrderedList { get; set; }
    public String CurrentURl { get; set; }
    public String defaultName { get; set; }
    public String ln { get; set; }
    public String currentSiteURL { get; set; }
    public String currentPageName { get; set; }
    public String source { get; set; }
    public Double accountDL { get; set; }
    public String serviceName { get; set; }
    public String pageTitle { get; set; }
    public String offerType { get; set; }
    public Boolean showCaseList { get; set; }
    public String urlDomain { get; set; }

    public static final String SEARCH_PAGE_NAME_LEARNING_CENTER = 'LearningCenterSearch';
    public static final String SEARCH_PAGE_NAME_UK = 'RCSupportPortalSearchNewUK';
    public static final String SEARCH_PAGE_NAME_US = 'RCSupportPortalGlobalSearch';

    public String userToken {
        get {
            Cookie userToken = ApexPages.currentPage().getCookies().get('userToken');
            return userToken.getValue();
        }
    }

    public RCSupportControllerHandler() {

        showCaseList = true;
        Apexpages.currentPage().getHeaders().put('X-UA-Compatible', 'IE=edge');
        if (apexpages.currentPage().getParameters().get('ln') != null && apexpages.currentPage().getParameters().get('ln') != '') {
            ln = apexpages.currentPage().getParameters().get('ln');
        } else {
            ln = '';
        }
        System.debug('ln is ~~~~~~~~~~~~~~~~~~~' + ln);
        if (UserInfo.getUserType() == 'Guest') {
            isGuestUser = true;
            showCaseList = false;
        } else {
            isGuestUser = false;
        }
        System.debug('isGuestUser>>' + isGuestUser);
        // CHANGES STARTS FOR CSV BASED ARTICLE LISTING
        mapArticleUrl = new Map<String, String>();
        mapArticleSummary = new Map<String, String>();
        articleOrderedList = new List<String>();
        // CHANGES ENDS FOR CSV BASED ARTICLE LISTING
        isTokenFound = isValidTokenFound();
        objUser = new User();
        if (isGuestUser != true) {
            objUser = [
                    SELECT AboutMe, IsActive, CommunityNickname, CompanyName, Country, CreatedDate, Department,
                            Division, Email, Name, IsPortalEnabled, LastLoginDate, UserType, Username,Profile.Name,UserRole.Name,
                            FullPhotoUrl,Contact.AccountId, Contact.Account.Total_Account_DL_s__c,Contact.Account.RC_Service_name__c,
                            Contact.FirstName, Contact.LastName, Contact.Email 
                    FROM User
                    WHERE id = :UserInfo.getUserId()
            ];
            accountDL = objUser.Contact.Account.Total_Account_DL_s__c;
            serviceName = objUser.Contact.Account.RC_Service_name__c;

            List<Package__c> serviceAccounts = [SELECT Offer_Type__c FROM Package__c WHERE Account__r.Id = :objUser.Contact.AccountId];

            if (objUser.Contact.Account != null && serviceAccounts.size() == 1) {
                offerType = serviceAccounts.get(0).Offer_Type__c;
                if (offerType == 'Free') {
                    showCaseList = false;
                }
            }
            if (serviceName != NULL) {
                serviceName = serviceName.tolowercase();
            }
        } else {
            accountDL = 0; serviceName = '';
        }
        CurrentURl = Site.getBaseUrl();
        system.debug('=======================' + CurrentURl);
        if (CurrentURl.contains('rcsupportCA2012') || CurrentURl.contains('success.ringcentral.ca')) {
            defaultName = 'Canada';
        } else if (CurrentURl.contains('RCSupportPortalUK') || CurrentURl.contains('success.ringcentral.co.uk')) {
            defaultName = 'United Kingdom';
        } else {
            defaultName = 'United States';
        }

        System.debug('defaultName>' + defaultName);
        if (String.isNotBlank(ApexPages.CurrentPage().getParameters().get('LCtabId'))) {
            strLCClassName = ApexPages.CurrentPage().getParameters().get('LCtabId');
        } else {
            strLCClassName = 'getting_0';
        }

        //if(strLCClassName.equals('Faxing_0') && getUKPortal()!=true){
        pageTitle = 'RingCentral Customer Care Center';
        //}
        knowledgeArticleMap('ArticleNaviagationListForUSCAandUK', (getUKPortal() ? 'UK' : 'US/CA'));
        urlDomain = SnapInsSettings__c.getInstance().PathForSnapInsChatScript__c;
    }

/************************ GET DOCUMENT FOR ARTICLE LISTING **********************************/

    public PageReference setPageParameter() {
        PageReference pageRef;
        String ln = apexpages.currentPage().getParameters().get('ln');
        System.debug('ln>>>>>>>>>>>>>>>>>>>>>>>>>>>' + apexpages.currentPage().getParameters().get('ln') + '====' + ln);
        System.debug('URL is >>>>>>>>>' + currentSiteURL);
        if (source.equalsIgnoreCase('learningCenterPage')) {
            pageRef = new PageReference(currentSiteURL + 'RCSupportPortalLearningCenter?LCtabId=settings_21&ln=learning_center');
        } else if (source.equalsIgnoreCase('kb')) {
            pageRef = new PageReference(currentSiteURL + 'RCSupportPortalLearningCenter?LCtabId=number_0&ln=kb');
        } else if (source.equalsIgnoreCase('numberTransferPage')) {
            pageRef = new PageReference(currentSiteURL + 'RCSupportPortalLearningCenter?LCtabId=number_0&ln=learning_center');
        }

        return pageRef;
    }

    public static List<Document> getMyDocument(String docName) {
        return [SELECT body, Name, bodyLength, ContentType, Url FROM Document WHERE Name = :docName];
    }

    public Map<String, String> knowledgeArticleMap(String docName, String brandName) {
        String[] fileLines = new String[]{
        };
        System.debug('brandName>>>>' + brandName);
        List<Document> lstDoc = getMyDocument(docName);
        try {
            if (lstDoc != null && lstDoc.size() != 0 && lstDoc[0].body != null) {
                String csvFile = lstDoc[0].body.toString();
                fileLines = csvFile.split('#EOL#');
                Integer counter = 0;
                for (String line : fileLines) {
                    if (!String.isBlank(line) && line != '' && line != null && ++counter > 1) {

                        String[] inputvalues = line.split(',\\*-\\*,');
                        System.debug ('line num ' + line + '  inputvalues>' + inputvalues);
                        System.debug('brand is>>>> ' + brandName + '   ' + inputvalues);
                        if (inputvalues != null && (inputvalues.size() == 3 || inputvalues.size() == 4)) {

                            if (brandName.containsIgnoreCase('UK')) {
                                System.debug('brand name UK');
                                if ((inputvalues[0]).containsIgnoreCase('UK')) {
                                    System.debug('input contains UK');
                                    if (String.isNotBlank(inputvalues[1].replaceAll('"', '').trim())) {
                                        mapArticleUrl.put(inputvalues[1].replaceAll('"', '').trim(), inputvalues[2]);

                                        if (inputvalues.size() == 4) {
                                            mapArticleSummary.put(inputvalues[1].replaceAll('"', '').trim(), (String.isBlank(inputvalues[3]) ? '' : inputvalues[3].trim()));
                                        } else {
                                            mapArticleSummary.put(inputvalues[1].replaceAll('"', '').trim(), '');
                                        }
                                        articleOrderedList.add(inputvalues[1].replaceAll('"', '').trim());
                                    }
                                } else {
                                }

                            } else if (brandName.containsIgnoreCase('US')) {
                                if ((inputvalues[0]).containsIgnoreCase('US/CA')) {
                                    if (String.isNotBlank(inputvalues[1].replaceAll('"', '').trim())) {
                                        mapArticleUrl.put(inputvalues[1].replaceAll('"', '').trim(), inputvalues[2]);

                                        if (inputvalues.size() == 4) {
                                            mapArticleSummary.put(inputvalues[1].replaceAll('"', '').trim(), (String.isBlank(inputvalues[3]) ? '' : inputvalues[3].trim()));
                                        } else {
                                            mapArticleSummary.put(inputvalues[1].replaceAll('"', '').trim(), '');
                                        }

                                        articleOrderedList.add(inputvalues[1].replaceAll('"', '').trim());
                                    }
                                } else {
                                }
                            } else {
                                System.debug('Brand name is Else');
                                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Article file not configured properly');
                                return null;
                            }
                        }//value 3 or 4
                        else {
                            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Article file not configured properly');
                            return null;
                        }//input size not 3 or 4
                    }//if line is not blank
                }//for all lines

            } else {///when document is blank
                System.debug('ARTICLE WAS NOT CONFIGURED');
                mapArticleUrl.put('No articles configured.', 'No articles configured.');
                mapArticleSummary.put('No articles configured.', '');
                articleOrderedList.add('No articles configured.');
            }
        } catch (Exception e) {
            System.debug('ARTICLE WAS NOT CONFIGURED End catch');
        }

        return null;
    }
    public PageReference showTabsDetail() {
        PageReference objPage = null;
        if (getUKPortal()) {
            objPage = new PageReference('/RCSupportPortalLearningCenterUK');
        } else {
            objPage = new PageReference('/RCSupportPortalLearningCenter');
        }
        objPage.getParameters().put('LCtabId', strLCClassName);
        return objPage;
    }
    public PageReference updateUserProfile() {
        try {
            update objUser;
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Profile Successfully updated');
            ApexPages.addMessage(msg);
        } catch (Exception e) {
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR,
                    e.getMessage());
            ApexPages.addMessage(msg);
        }
        return null;
    }
    public Boolean isValidTokenFound() {
        String strToken = getValidToken();
        if (strToken != null && strToken != '') {
            System.debug('Token is not null');
            return true;
        }
        System.debug('Token is  null');
        return false;
    }

    public String getURL() {
        return Site.getName();
    }

    public Boolean getUKPortal() {
        return String.isNotEmpty(Site.getName()) && (Site.getName()).lastIndexOfIgnoreCase('RCSupportPortalUK') > -1;
    }

    public Boolean getCAPortal() {
        return String.isNotEmpty(Site.getName()) && (Site.getName()).lastIndexOfIgnoreCase('rcsupportCA2012') > -1;
    }

    public Boolean getLearningCenterPortal() {
        return String.isNotEmpty(Site.getName()) && (Site.getName()).lastIndexOfIgnoreCase('LearningCenter') > -1;
    }

    public String getSearchFilter() {
        String searchFilter = '';
        RCSupportPortalSettings__c rcSupportPortalSettings = RCSupportPortalSettings__c.getInstance();

        if (getLearningCenterPortal()){
            searchFilter = rcSupportPortalSettings.Search_Filter_for_Learning_Center__c;
        } else if (getUKPortal()){
            searchFilter = rcSupportPortalSettings.Search_Filter_for_co_uk__c;
        } else if (getCAPortal()){
            searchFilter = rcSupportPortalSettings.Search_Filter_for_ca__c;
        } else {
            searchFilter = rcSupportPortalSettings.Search_Filter_for_com__c;
        }

        return searchFilter;
    }

    public String getSearchHubName() {
        String searchHubName = '';
        RCSupportPortalSettings__c rcSupportPortalSettings = RCSupportPortalSettings__c.getInstance();

        if (getLearningCenterPortal()){
            searchHubName = rcSupportPortalSettings.Search_Hub_Name_for_Learning_Center__c;
        } else if (getUKPortal()){
            searchHubName = rcSupportPortalSettings.Search_Hub_Name_for_co_uk__c;
        } else if (getCAPortal()){
            searchHubName = rcSupportPortalSettings.Search_Hub_Name_for_ca__c;
        } else {
            searchHubName = rcSupportPortalSettings.Search_Hub_Name_for_com__c;
        }

        return searchHubName;
    }

    public String getSearchPageName() {
        String searchPageURL = '';

        if (getLearningCenterPortal()){
            searchPageURL = SEARCH_PAGE_NAME_LEARNING_CENTER;
        } else if (getUKPortal()){
            searchPageURL = SEARCH_PAGE_NAME_UK;
        } else {
            searchPageURL = SEARCH_PAGE_NAME_US;
        }

        return searchPageURL;
    }

    public String getSearchPipeline() {
        String searchPipeline = '';
        RCSupportPortalSettings__c rcSupportPortalSettings = RCSupportPortalSettings__c.getInstance();

        if (getLearningCenterPortal()){
            searchPipeline = rcSupportPortalSettings.Search_Pipeline_for_Learning_Center__c;
        } else if (getUKPortal()){
            searchPipeline = rcSupportPortalSettings.Search_Pipeline_for_co_uk__c;
        } else if (getCAPortal()){
            searchPipeline = rcSupportPortalSettings.Search_Pipeline_for_ca__c;
        } else {
            searchPipeline = rcSupportPortalSettings.Search_Pipeline_for_com__c;
        }

        return searchPipeline;
    }

    public String strPageUrl2 { get; set; }

    public Pagereference validateLoginDetail() {
        try {
            if (isTokenFound == true) {
                String tokenVal = getValidToken();
                if (tokenVal != null && tokenVal != '') {
                    String loginToken = tokenVal;
                    string username;
                    string password;

                    if (loginToken != null) {
                        String[] strSplitToken = loginToken.split('&');
                        username = strSplitToken[0].split('=')[1];
                        password = strSplitToken[1].split('=')[1];
                        str = username + password;
                    }
                    String strPage = ApexPages.CurrentPage().getParameters().get('NEXTPAGE');
                    if (strPage != null && strPage != '' && strPage.indexOf(strPostFix) >= 0) {
                        strPage = '/' + strPage.removeEndIgnoreCase(strPostFix);
                    } else if (ApexPages.CurrentPage().getParameters().get('ARTICLENAME') != null && ApexPages.CurrentPage().getParameters().get('ARTICLENAME') != '') {
                        strPage = '';
                        strPage = '/articles/RC_Knowledge_Article/' + ApexPages.CurrentPage().getParameters().get('ARTICLENAME');
                    }
                    Pagereference pageRef = Site.login(username, password, '' + strPage);
                    pageRef.setRedirect(true);
                    return pageRef;
                }
            }
        } catch (Exception e) {
        }
        return null;
    }

    public String getNextPageName() {
        String strPage = null;

        if (ApexPages.currentPage().getParameters().get('startURL') != null && ApexPages.currentPage().getParameters().get('startURL') != '') {
            strPage = ApexPages.currentPage().getParameters().get('startURL');
            if (strPage != null && strPage != '' && strPage.indexOf('/') >= 0) {
                strPage = strPage.substringAfterLast('/');
                return strPage + strPostFix;
            }

        }
        return 'RCSupportPortalHome' + strPostFix;
    }
    public String getValidToken() {
        String strToken = ApexPages.CurrentPage().getParameters().get('token');
        system.debug('===========strToken: ' + strToken);
        if (strToken != null && strToken != '') {
            Cookie userToken = new Cookie('userToken', strToken, null, -1, false);
            ApexPages.currentPage().setCookies(new Cookie[]{
                    userToken
            });
            String tokenUrlDecoded = EncodingUtil.urlDecode(strToken, 'UTF-8');
            tokenUrlDecoded = tokenUrlDecoded.replaceAll(' ', '+');
            Blob tokenDecodedBases64 = Encodingutil.base64Decode(tokenUrlDecoded);
            Blob cryptoKey = Blob.valueOf('v7Y2g2webAqutAcr4DEC3uTAnaspEgA8');
            Blob initVector = Blob.valueof('da4atrABufastacr');
            // Decrypt the data
            Blob decryptedData = Crypto.decrypt('AES256', cryptoKey, initVector, tokenDecodedBases64);
            String tokenVal = decryptedData.toString();
            // it is fixed for mul
            return tokenVal;
        }
        return null;
    }


    public Pagereference login() {
        if (isTokenFound == true) {
            return validateLoginDetail();
        } else {
            PageReference objPage = new PageReference('https://service.ringcentral.com/login.asp');
            //PageReference objPage=new PageReference('http://sp2.ringcentral.com/login/login.php');
            objPage.getParameters().put('p_next_page', getNextPageName());
            objPage.setRedirect(true);
            return objPage;
        }
        return null;
    }
    public String strUserType { get; set; }

    public Pagereference PageAuthorization() {
        if (UserInfo.getUserType() == 'Guest') {
            isGuestUser = true;
        } else {
            isGuestUser = false;
            return null;
        }
        return login();
    }
    public Pagereference getPageAuthorization() {
        if (UserInfo.getUserType() == 'Guest') {
            isGuestUser = true;
        } else {
            isGuestUser = false;
            return null;
        }
        return login();
    }


    public Pagereference openCase() {
        return new Pagereference('/RCSupportPortalCreateNewCase');
    }

    public Pagereference openMyCase() {
        return new Pagereference('/RCSupportAdvMyCases');
    }


    public String getPageDetail() {
        return ApexPages.currentPage().getUrl();
    }
    public String articleNum { get; set; }
    public String articleSummary { get; set; }
    public String urlName { get; set; }
    public String articleLastModifiedDate { get; set; }

    public Boolean getIsArticleDetailsPage() {
        String pageURL = ApexPages.currentPage().getUrl();
        if (pageURL != null && pageURL.indexOf('TOCArticleRendererPkb') > -1) {
            try {
                KnowledgeArticle kv = [SELECT ArticleNumber,Id,IsDeleted,LastModifiedDate FROM KnowledgeArticle WHERE Id = :apexpages.currentPage().getParameters().get('id')];
                KnowledgeArticleVersion kav = [
                        SELECT ArticleNumber,Id,MasterVersionId,PublishStatus,Summary,Title,UrlName,VersionNumber,LastModifiedDate
                        FROM KnowledgeArticleVersion
                        WHERE Language = 'en_US' AND PublishStatus = 'Online' AND ArticleNumber = :kv.ArticleNumber
                ];
                pageTitle = kav.Title;
                articleNum = kav.ArticleNumber;
                articleSummary = kav.Summary;
                urlName = kav.UrlName;
                articleLastModifiedDate = kav.LastModifiedDate.format('MM/dd/yy HH:mm a');
                return true;
            } catch (Exception e) {
                System.debug('Exception in getIsArticleDetailsPage(), exception message: ' + e.getMessage());
            }
        }
        return false;
    }

    public String getURLProtocol() {
        return URL.getOrgDomainUrl().getProtocol();
    }

    public String getCommunityId() {
        String strReturnString = 'false';
        for (Community objCommunity : [SELECT Id FROM Community WHERE Name = 'RingCentral Customer Community' limit 1]) {
            strReturnString = objCommunity.id;
        }
        return strReturnString;
    }

    /*********************************************************************************************
   * @Description : Method to redirect control to different pages.                              *
   * @Params      : void                                                                        *
   * @Return      : void                                                                        *
   *********************************************************************************************/
    public PageReference redirectToPage() {
        PageReference redirectToPage = null;
        try {
            String currentURL = URL.getCurrentRequestUrl().toExternalForm();
            system.debug('#### Current URL = ' + currentURL);
            if (currentURL.contains('RCSupportPortalCreateNewCase')) {
                if (offerType == 'Free') {
                    currentURL = currentURL.replace('RCSupportPortalCreateNewCase', 'SelfSupport');
                    redirectToPage = new PageReference(currentURL);
                    redirectToPage.setRedirect(true);
                    return redirectToPage;
                } else {
                    currentURL = currentURL.replace('RCSupportPortalCreateNewCase', 'SupportPortalCaseCreate?pageid=contact');
                }
            }
            if (currentURL.contains('RCContactSupp')) {
                currentURL = currentURL.replace('RCContactSupp', 'SupportPortalContact?pageid=contact');
            }

            system.debug('#### Replaced Current URL = ' + currentURL);

            if (currentURL.contains('btcloudphone')) {
                redirectToPage = new PageReference(currentURL);
                redirectToPage.setRedirect(true);
                system.debug('#### Redirecting to Page = ' + redirectToPage);
                return redirectToPage;
            }
        } catch (Exception ex) {
            system.debug('#### Exception at line = ' + ex.getLineNumber() + ' ,Exception Message = ' + ex.getMessage());
        }
        return redirectToPage;
    }
}