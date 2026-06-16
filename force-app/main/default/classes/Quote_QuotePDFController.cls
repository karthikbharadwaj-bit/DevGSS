//Ankit Sharma  08/01/2019

/*
 Change History
 ********************************************************************************************************************
 SCRUM/Jira              ModifiedBy      Date        Description                                          Tag

 ********************************************************************************************************************
 */
global class Quote_QuotePDFController{
  public QuotePDFWrapper objPartnerQuotePDF{ get; set; }

  public Quote_QuotePDFController(){
    String quoteId = ApexPages.currentPage().getParameters().get('Id');
    String Longform = ApexPages.currentPage().getParameters().get('Longform');//Added for Longform quote
    System.debug('Longform ' + Longform);
    objPartnerQuotePDF = getPDFData(quoteId);
    objPartnerQuotePDF.isLongForm = Longform;//Added for Longform quote
    String myGeneratedFileName = objPartnerQuotePDF.quoteRec.name + '.pdf';
    Apexpages.currentPage().getHeaders().put('content-disposition', 'attachment; filename=' + myGeneratedFilename);
  }

  public static QuotePDFWrapper getPDFData(String quoteId){
    String BrandName = 'Avaya Cloud Office';
    String CountryName = 'United States';

    QuotePDFWrapper objWrapp = new QuotePDFWrapper();
    Partner_Quote__c objPartnerQuote = Quote_PartnerQuoteUtil.getQuote(quoteId);
    List<QuoteLineWrapper> quoteLineList = new List<QuoteLineWrapper>();
    //Checking if any Discount request  closed approved or not and have promocode
    List<Deal_Support__c> existingDiscountRequest = [Select Id FROM Deal_Support__c WHERE Type__c = 'Discount Request' and Status__c = 'Closed-Approved' and Partner_Quote__c = :quoteId and Promo_Code__c != null];
    if (!existingDiscountRequest.isEmpty()){
      objWrapp.isClosedApprovedDiscountReq = true;
    }

    for (Partner_Quote_Line__c eachQuoteLine : Quote_PartnerQuoteUtil.getQuoteLinesForOutput(quoteId)){
      if (eachQuoteLine.Product_Catalogue__r.Category_Name__c == 'Implementation'){
        //System.assert(false,eachQuoteLine.Product_Catalogue__r.Category_Name__c);
        objWrapp.outputDisplayName = eachQuoteLine.Product_Catalogue__r.Output_Display_Name__c;
        continue;
      }

      QuoteLineWrapper newRecord = new QuoteLineWrapper();
      String packageProductType = eachQuoteLine.Product_Catalogue__r.Package_Product_Type__c;
      newRecord.isHeaderProduct = false;
      if (packageProductType != null && packageProductType.contains('Header')){
        newRecord.isHeaderProduct = true;
      }

      newRecord.objQuoteLine = eachQuoteLine;
      if (eachQuoteLine.Discount_Number__c != null && eachQuoteLine.List_Price__c != null && eachQuoteLine.Discount_Number__c > 0 && eachQuoteLine.Discount_Type__c == '%'){
        eachQuoteLine.Effective_Price__c = eachQuoteLine.List_Price__c - ((eachQuoteLine.List_Price__c * eachQuoteLine.Discount_Number__c) / 100);
      }
      else if (eachQuoteLine.Discount_Number__c != null && eachQuoteLine.List_Price__c != null && eachQuoteLine.Discount_Number__c > 0 && eachQuoteLine.Discount_Type__c == 'Amt'){
        eachQuoteLine.Effective_Price__c = eachQuoteLine.List_Price__c - eachQuoteLine.Discount_Number__c;
      }
      else{
        eachQuoteLine.Effective_Price__c = eachQuoteLine.List_Price__c;
      }
      quoteLineList.add(newRecord);
    }
    objWrapp.quoteRec = objPartnerQuote;
    Decimal oneTimeTotal = 0;
    Decimal reccuringTotal = 0;
    For (Partner_Quote_line__c eachLine : objPartnerQuote.Partner_Quote_Products__r){
      if (eachLine.Product_Catalogue__r.plan__c == 'One - Time'){
        oneTimeTotal += eachLine.Total_Price__c == null ? 0 : eachLine.Total_Price__c;
      }
      else{
        reccuringTotal += eachLine.Total_Price__c == null ? 0 : eachLine.Total_Price__c;
      }

    }

    if (objPartnerQuote != null && objPartnerQuote.Opportunity__r.Brand_Name__c != null){
      BrandName = objPartnerQuote.Opportunity__r.Brand_Name__c;
    }
    if (objPartnerQuote != null && objPartnerQuote.Opportunity__r.Account.BillingCountry != null){
      CountryName = objPartnerQuote.Opportunity__r.Account.BillingCountry;
    }
    //added for switzerland starts
    String language = 'English';
    if (CountryName == 'Switzerland'){
      if (objPartnerQuote.Opportunity__r.Account.Preferred_Language__c != null){
        language = objPartnerQuote.Opportunity__r.Account.Preferred_Language__c;
      }
    }
    //added for switzerland ends
    Quote_PDF_Details__mdt objMetadataPdfDetails = getQuoteDetailsMetaDataRecord(false, CountryName, BrandName, language);
    system.debug('BrandNameiii?>>>' + BrandName);
    if (objMetadataPdfDetails == null){
      //System.assert(false,BrandName);
      objMetadataPdfDetails = getQuoteDetailsMetaDataRecord(true, 'United States', BrandName, language);
    }

    objWrapp.quoteLineList = quoteLineList;
    objWrapp.oneTimeTotal = oneTimeTotal;
    objWrapp.reccuringTotal = reccuringTotal;
    objWrapp.currencySymbol = getCurrencySymbolFromIso(objPartnerQuote.CurrencyIsoCode);
    //objWrapp.listOfQuotePDFDetails = listOfQuotePDFDetails[0];
    objWrapp.pdfDetails = setPDFDetails(new QuotePDFDetails(), objMetadataPdfDetails);
    return objWrapp;
  }

  public static Quote_PDF_Details__mdt getQuoteDetailsMetaDataRecord(Boolean isDefault, String CountryName, String BrandName, String Language){
    List<Quote_PDF_Details__mdt> listofQuotePDFDetails = new List<Quote_PDF_Details__mdt>();
    if (CountryName == 'Switzerland'){
      listofQuotePDFDetails = [SELECT Id, Header_Table_Column_1__c, Header_Table_Column_2__c, Sub_Header_1__c, Sub_Header_2__c, Header_Field_1__c, Header_Field_2__c, DeveloperName, MasterLabel, Language, NamespacePrefix, Label, QualifiedApiName, Country__c, Brand_Name__c, Header_Table_Column3__c, Header_Table_Column_4__c, Header_Table_Column5__c, Header_Table_Column6__c, Header_Table_Column7__c, Header_Table_Column8__c, Footer_Content__c, Body_Header_Table_Column1__c, Body_Header_Table_Column2__c, Body_Header_Table_Column3__c, Body_Header_Table_Column4__c, Disclaimer__c, Body_Header_Table_Column5__c, Body_Header_Table_Column6__c, Is_Default__c, Office_to_MVP_Change_Notification__c, Glip_to_Video_Notification__c FROM Quote_PDF_Details__mdt WHERE Is_Default__c = :isDefault and Country__c = :CountryName and Brand_Name__c like:('%' + BrandName + '%') and Language__c = :Language];
    }
    else{
      listofQuotePDFDetails = [SELECT Id, Header_Table_Column_1__c, Header_Table_Column_2__c, Sub_Header_1__c, Sub_Header_2__c, Header_Field_1__c, Header_Field_2__c, DeveloperName, MasterLabel, Language, NamespacePrefix, Label, QualifiedApiName, Country__c, Brand_Name__c, Header_Table_Column3__c, Header_Table_Column_4__c, Header_Table_Column5__c, Header_Table_Column6__c, Header_Table_Column7__c, Header_Table_Column8__c, Footer_Content__c, Body_Header_Table_Column1__c, Body_Header_Table_Column2__c, Body_Header_Table_Column3__c, Body_Header_Table_Column4__c, Disclaimer__c, Body_Header_Table_Column5__c, Body_Header_Table_Column6__c, Is_Default__c, Office_to_MVP_Change_Notification__c, Glip_to_Video_Notification__c FROM Quote_PDF_Details__mdt WHERE Is_Default__c = :isDefault and Country__c = :CountryName and Brand_Name__c like:('%' + BrandName + '%')];
    }
    if (listofQuotePDFDetails != null && listofQuotePDFDetails.size() > 0){
      return listofQuotePDFDetails[0];
    }
    return null;
  }

  public static String getCurrencySymbolFromIso(String Iso){
    String currencySymbol = ('USD' == Iso ? '$' : ('CAD' == Iso ? 'CA$' : ('AUD' == Iso ? 'A$' : ('EUR' == Iso ? '€' : ('GBP' == Iso ? '£' : ('JPY' == Iso ? '¥' : ('KRW' == Iso ? '₩' : ('CNY' == Iso ? '元' : Iso))))))));
    return currencySymbol;
  }

  public static QuotePDFDetails setPDFDetails(QuotePDFDetails obj, Quote_PDF_Details__mdt objMetadata){
    obj.headerTitle1 = objMetadata.Header_Field_1__c;
    obj.headerTitle2 = objMetadata.Header_Field_2__c;
    obj.subHeader1 = objMetadata.Sub_Header_1__c;
    obj.subHeader2 = objMetadata.Sub_Header_2__c;
    obj.bodyTableColumn1 = objMetadata.Body_Header_Table_Column1__c;
    obj.bodyTableColumn2 = objMetadata.Body_Header_Table_Column2__c;
    obj.bodyTableColumn3 = objMetadata.Body_Header_Table_Column3__c;
    obj.bodyTableColumn4 = objMetadata.Body_Header_Table_Column4__c;
    obj.bodyTableColumn5 = objMetadata.Body_Header_Table_Column5__c;
    obj.bodyTableColumn6 = objMetadata.Body_Header_Table_Column6__c;
    obj.HeaderTableColumn1 = objMetadata.Header_Table_Column_1__c;
    obj.HeaderTableColumn2 = objMetadata.Header_Table_Column_2__c;
    obj.HeaderTableColumn3 = objMetadata.Header_Table_Column3__c;
    obj.HeaderTableColumn4 = objMetadata.Header_Table_Column_4__c;
    obj.HeaderTableColumn5 = objMetadata.Header_Table_Column5__c;
    obj.HeaderTableColumn6 = objMetadata.Header_Table_Column6__c;
    obj.HeaderTableColumn7 = objMetadata.Header_Table_Column7__c;
    obj.HeaderTableColumn8 = objMetadata.Header_Table_Column8__c;
    obj.disclaimer = objMetadata.Disclaimer__c;
    obj.footerContent = objMetadata.Footer_Content__c;
    obj.officetoMvPNotify = objMetadata.Office_to_MVP_Change_Notification__c;
    obj.gliptovideoNotify = objMetadata.Glip_to_Video_Notification__c;
    return obj;
  }

  public class QuotePDFWrapper{
    public Partner_Quote__c quoteRec{ get; set; }

    public String outputDisplayName{ get; set; }

    public String currencySymbol{ get; set; }

    public List<QuoteLineWrapper> quoteLineList{ get; set; }

    public Decimal oneTimeTotal{ get; set; }

    public Decimal reccuringTotal{ get; set; }

    public Boolean isClosedApprovedDiscountReq{ get; set; }

    public Quote_PDF_Details__mdt listOfQuotePDFDetails{ get; set; }

    public QuotePDFDetails pdfDetails{ get; set; }

    //Added for Longform quote
    public String isLongForm{ get; set; }

  }

  public class QuotePDFDetails{
    public String headerTitle1{ get; set; }

    public String headerTitle2{ get; set; }

    public String subHeader1{ get; set; }

    public String subHeader2{ get; set; }

    public String bodyTableColumn1{ get; set; }

    public String bodyTableColumn2{ get; set; }

    public String bodyTableColumn3{ get; set; }

    public String bodyTableColumn4{ get; set; }

    public String bodyTableColumn5{ get; set; }

    public String bodyTableColumn6{ get; set; }

    public String HeaderTableColumn1{ get; set; }

    public String HeaderTableColumn2{ get; set; }

    public String HeaderTableColumn3{ get; set; }

    public String HeaderTableColumn4{ get; set; }

    public String HeaderTableColumn5{ get; set; }

    public String HeaderTableColumn6{ get; set; }

    public String HeaderTableColumn7{ get; set; }

    public String HeaderTableColumn8{ get; set; }

    public String disclaimer{ get; set; }

    public String footerContent{ get; set; }

    public String officetoMvPNotify{ get; set; }

    public String gliptovideoNotify{ get; set; }

  }

  public class QuoteLineWrapper{
    public Partner_Quote_Line__c objQuoteLine{ get;private  set; }

    public Boolean isHeaderProduct{ get;private  set; }

  }

}