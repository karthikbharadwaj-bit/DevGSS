global class AddWhatsAppUsageQLIBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    private static final Set<String> INCLUDE_PACKAGE_CATALOG_IDS = getIncludePackageCatalogIds();
    private static final String NEW_LICENSE_EXTID = System.Label.NewLicenseExternalId;
    private static final String TARGET_SERVICE_NAME = System.Label.TargetServiceName;
    
    // Stateful variables to track progress
    global Integer totalQuotesProcessed = 0;
    global Integer totalQLIsInserted = 0;
    global Integer totalSkipped = 0;
    global Integer totalNotEligible = 0;
    global Integer totalFailed = 0;
    global Integer totalErrors = 0;
    global Integer totalNotIncluded = 0;
    global Integer totalNoPricebookEntry = 0;
    global Integer totalNoEngageVoice = 0;
    global Map<Id, String> errorMap = new Map<Id, String>();
    global List<String> successfulQuotes = new List<String>();
    global List<String> unprocessableQuotes = new List<String>();
    global List<String> failedMasterQuotes = new List<String>();
    global List<String> failedTechnicalQuotes = new List<String>();
    
    // Constructor
    global AddWhatsAppUsageQLIBatch() {}
    
    // Start method - Query for QLIs to process
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, QuoteId, Quote.Pricebook2Id, Quote.IsMultiProductTechnicalQuote__c, 
                   Quote.CurrencyIsoCode, PackageCatalogId__c, PackageVersion__c
            FROM QuoteLineItem 
            WHERE ServiceName__c = :TARGET_SERVICE_NAME
            AND Quote.Status IN ('Draft', 'Agreement')
            AND Quote.CreatedDate = LAST_N_MONTHS:12
            AND Quote.Opportunity.StageName NOT IN ('7. Closed won', '0. Downgraded')
            AND Quote.Opportunity.Forecast_Category_Internal__c != 'Omit - Administrative/Test'
            AND Quote.Opportunity.Account.RC_Account_Status__c NOT IN ('Cancelled', 'Disabled', 'Canceled', 'Suspended', 'Free', 'Deleted')
            AND Quote.IsQuoteHasErrors__c = false
            AND Quote.isPrimary__c = true
            ORDER BY Quote.CreatedDate ASC 
        ]);
    }
    
    // Execute method - Process each batch
    global void execute(Database.BatchableContext BC, List<QuoteLineItem> scope) {
        try {
            String NewLicenseProductId = getNewLicenseProductId();
            if (NewLicenseProductId == null) {
                return;
            }
            
            // Extract unique Quote IDs and build quotes map
            Set<Id> masterQuoteIds = new Set<Id>();
            Map<Id, Quote> allQuotesMap = new Map<Id, Quote>();
            
            for (QuoteLineItem qli : scope) {
                masterQuoteIds.add(qli.QuoteId);
                if (!allQuotesMap.containsKey(qli.QuoteId)) {
                    allQuotesMap.put(qli.QuoteId, new Quote(
                        Id = qli.QuoteId,
                        Pricebook2Id = qli.Quote.Pricebook2Id,
                        IsMultiProductTechnicalQuote__c = qli.Quote.IsMultiProductTechnicalQuote__c,
                        CurrencyIsoCode = qli.Quote.CurrencyIsoCode
                    ));
                }
            }
            
            // Find technical quotes and their QLIs
            List<Quote> technicalQuotes = [
                SELECT Id, Pricebook2Id, CurrencyIsoCode, IsMultiProductTechnicalQuote__c,
                       (SELECT QuoteId, PackageCatalogId__c, PackageVersion__c
                        FROM QuoteLineItems 
                        WHERE ServiceName__c = :TARGET_SERVICE_NAME)
                FROM Quote 
                WHERE ServiceName__c = :TARGET_SERVICE_NAME
                AND MasterQuote__c IN :masterQuoteIds
                AND IsMultiProductTechnicalQuote__c = true
            ];
            
            // Add technical quotes to the map
            List<QuoteLineItem> allQLIs = new List<QuoteLineItem>(scope);
            for (Quote techQuote : technicalQuotes) {
                allQuotesMap.put(techQuote.Id, techQuote);
                allQLIs.addAll(techQuote.QuoteLineItems);
            }
            
            totalQuotesProcessed += allQuotesMap.size();
            
            // Get PricebookEntry mapping
            Map<String, PricebookEntry> pricebookCurrencyMap = getPricebookEntries(allQuotesMap.values(), NewLicenseProductId );
            
            // Check for existing New License QLIs
            Set<Id> existingQuotesWithNewLicense = getQuotesWithNewLicense(allQuotesMap.keySet(), NewLicenseProductId);
            
            // Build Engage Voice QLI mapping
            Map<Id, QuoteLineItem> engageVoiceQLIMap = buildEngageVoiceQLIMap(allQLIs);
            
            // Create new QLIs
            List<QuoteLineItem> qliToInsert = createNewLicenseQLIs(
                allQuotesMap.values(), 
                NewLicenseProductId,
                pricebookCurrencyMap,
                existingQuotesWithNewLicense,
                engageVoiceQLIMap
            );
            
            if (!qliToInsert.isEmpty()) {
                insertQLIs(qliToInsert);
            }
            
        } catch (Exception e) {
            System.debug('Batch execution error: ' + e.getMessage());
            totalFailed++;
            totalErrors++;
        }
    }
    
    // Finish method - Send email with results
    global void finish(Database.BatchableContext BC) {
        sendResultsEmail(BC);
    }
    
    // Helper methods
    /*Helper method to get New License Product ID using External ID */
    private String getNewLicenseProductId() {
        List<Product2> products = [
            SELECT Id FROM Product2 
            WHERE ExtID__c = :NEW_LICENSE_EXTID AND IsActive = true LIMIT 1
        ];
        return products.isEmpty() ? null : products[0].Id;
    }
    
    /* Helper method to parse Package Catalog IDs from custom labels */
    private static Set<String> getIncludePackageCatalogIds() {
        Set<String> catalogIds = new Set<String>();
        String labelValue = System.Label.IncludePackageCatalogIds;
            if (String.isNotBlank(labelValue)) {
                List<String> idList = labelValue.split(',');
                for (String id : idList) {
                    if (String.isNotBlank(id.trim())) {
                        catalogIds.add(id.trim());
                    }
                }
            }
        return catalogIds;
    }
    
    private Map<String, PricebookEntry> getPricebookEntries(List<Quote> quotes, String productId) {
        Set<Id> pricebookIds = new Set<Id>();
        for (Quote quote : quotes) {
            if (quote.Pricebook2Id != null) {
                pricebookIds.add(quote.Pricebook2Id);
            }
        }
        
        List<PricebookEntry> pbes = [
            SELECT Id, Pricebook2Id, CurrencyIsoCode
            FROM PricebookEntry 
            WHERE Product2Id = :productId AND Pricebook2Id IN :pricebookIds AND IsActive = true
        ];
        
        Map<String, PricebookEntry> pricebookCurrencyMap = new Map<String, PricebookEntry>();
        for (PricebookEntry pbe : pbes) {
            pricebookCurrencyMap.put(pbe.Pricebook2Id + '_' + pbe.CurrencyIsoCode, pbe);
        }
        return pricebookCurrencyMap;
    }
    
    private Set<Id> getQuotesWithNewLicense(Set<Id> quoteIds, String productId) {
        Set<Id> existingQuotesWithNewLicense = new Set<Id>();
        for (QuoteLineItem qli : [SELECT QuoteId FROM QuoteLineItem WHERE QuoteId IN :quoteIds AND Product2Id = :productId]) {
            existingQuotesWithNewLicense.add(qli.QuoteId);
        }
        return existingQuotesWithNewLicense;
    }
    
    private Map<Id, QuoteLineItem> buildEngageVoiceQLIMap(List<QuoteLineItem> allQLIs) {
        Map<Id, QuoteLineItem> engageVoiceQLIMap = new Map<Id, QuoteLineItem>();
        for (QuoteLineItem qli : allQLIs) {
            if (!engageVoiceQLIMap.containsKey(qli.QuoteId)) {
                engageVoiceQLIMap.put(qli.QuoteId, qli);
            }
        }
        return engageVoiceQLIMap;
    }
    
    private String createPackageInfoJson(String packageVersion, String packageCatalogId) {
        return '{"version":"' + packageVersion + '","q":1,"id":"' + packageCatalogId + 
               '","duration":"Monthly","discount":{"Value":0,"Type":"Money"},"categoryPath":"SCREENRECORDING","categoryCode":"SCREENRECORDING"}';
    }
    
    private String createPackageInfoQLIJson(String packageVersion, String packageCatalogId) {
        return '{"version":"' + packageVersion + '","targetPriceCalculations":{"targetPrice":"","recommendedDiscount":0},"q":1,"price":null,"partnerInfo":null,"parent":null,"originalDiscount":null,"lboxes":[],"lbox":null,"isPhoneLeasingEnabled":null,"isCore":null,"id":"' + packageCatalogId + 
               '","duration":"Monthly","discount":{"Value":0,"Type":"Money"},"categoryPath":"SCREENRECORDING","categoryCode":"SCREENRECORDING"}';
    }
    
    private List<QuoteLineItem> createNewLicenseQLIs(
        List<Quote> quotes, 
        String productId,
        Map<String, PricebookEntry> pricebookCurrencyMap,
        Set<Id> existingQuotesWithNewLicense,
        Map<Id, QuoteLineItem> engageVoiceQLIMap
    ) {
        List<QuoteLineItem> qliToInsert = new List<QuoteLineItem>();
        
        for (Quote quote : quotes) {
            // Skip if already has New LIcense
            if (existingQuotesWithNewLicense.contains(quote.Id)) {
                totalSkipped++;
                continue;
            }
            
            // Check if Engage Voice QLI exists and get package info
            QuoteLineItem engageVoiceQLI = engageVoiceQLIMap.get(quote.Id);
            if (engageVoiceQLI == null) {
                totalNoEngageVoice++;
                totalNotEligible++;
                unprocessableQuotes.add(quote.Id);
                continue;
            }
            
            if (!INCLUDE_PACKAGE_CATALOG_IDS.contains(engageVoiceQLI.PackageCatalogId__c)) {
                totalNotIncluded++;
                totalNotEligible++;
                unprocessableQuotes.add(quote.Id);
                continue;
            }
            
            // Get pricebook entry
            String pricebookKey = quote.Pricebook2Id + '_' + quote.CurrencyIsoCode;
            PricebookEntry pbe = pricebookCurrencyMap.get(pricebookKey);
            if (pbe == null) {
                totalNoPricebookEntry++;
                totalNotEligible++;
                unprocessableQuotes.add(quote.Id);
                continue;
            }
            
            // Create new License Recording QLI
            String packageInfoJson = createPackageInfoJson(engageVoiceQLI.PackageVersion__c, engageVoiceQLI.PackageCatalogId__c);
            String packageInfoQLIJson = createPackageInfoQLIJson(engageVoiceQLI.PackageVersion__c, engageVoiceQLI.PackageCatalogId__c);
            
            QuoteLineItem newQLI = new QuoteLineItem(
                QuoteId = quote.Id,
                PricebookEntryId = pbe.Id,
                Product2Id = productId,
                Quantity = 1,
                UnitPrice = 0,
                Description = 'RCX - Screen Recording add-on license',
                Discount = 0,
                Discount_number__c = 0,
                Discount_type__c = 'Percentage',
                ChargeTerm__c = 'Monthly',
                Package_Info__c = packageInfoJson,
                Package_Info_QLI__c = packageInfoQLIJson,
                PackageInfo__c = packageInfoQLIJson,
                PackageCatalogId__c = engageVoiceQLI.PackageCatalogId__c,
                PackageVersion__c = engageVoiceQLI.PackageVersion__c,
                IsMultiProductTechnicalQLI__c = quote.IsMultiProductTechnicalQuote__c,
                ServiceName__c = TARGET_SERVICE_NAME
            );
            
            qliToInsert.add(newQLI);
        }
        
        return qliToInsert;
    }
    
    private void insertQLIs(List<QuoteLineItem> qliToInsert) {
        Database.SaveResult[] results = Database.insert(qliToInsert, false);
        
        for (Integer i = 0; i < results.size(); i++) {
            Database.SaveResult result = results[i];
            QuoteLineItem qli = qliToInsert[i];
            
            if (result.isSuccess()) {
                totalQLIsInserted++;
                successfulQuotes.add(qli.QuoteId);
            } else {
                totalFailed++;
                totalErrors++;
                
                // Categorize by quote type
                if (qli.IsMultiProductTechnicalQLI__c) {
                    failedTechnicalQuotes.add(qli.QuoteId);
                } else {
                    failedMasterQuotes.add(qli.QuoteId);
                }
                
                String errorMsg = '';
                for (Database.Error error : result.getErrors()) {
                    errorMsg += error.getMessage() + '; ';
                }
                errorMap.put(qli.QuoteId, errorMsg);
            }
        }
    }
    
    private void sendResultsEmail(Database.BatchableContext BC) {
        try {
            AsyncApexJob job = [SELECT CreatedBy.Email FROM AsyncApexJob WHERE Id = :BC.getJobId()];
            if (job.CreatedBy.Email != null) {
                String emailBody = buildEmailBody(BC);
                
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(new String[]{job.CreatedBy.Email});
                email.setSubject('RCX Screen Recording Batch Results - ' + BC.getJobId());
                email.setPlainTextBody(emailBody);
                Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
            }
        } catch (Exception e) {
            System.debug('Email error: ' + e.getMessage());
        }
    }
    
    private String buildEmailBody(Database.BatchableContext BC) {
        String emailBody = 'RCX Screen Recording Add-on Batch Results:\n\n' +
                    'Summary:\n' +
                    '- Quotes processed: ' + totalQuotesProcessed + '\n' +
                    '- Screen Recording QLIs inserted: ' + totalQLIsInserted + '\n' +
                    '- Total errors: ' + totalErrors + '\n' +
                    '- Skipped (already had Screen Recording): ' + totalSkipped + '\n' +
                    '- Not included (package not approved): ' + totalNotIncluded + '\n' +
                    '- No pricebook entry: ' + totalNoPricebookEntry + '\n' +
                    '- No engage voice: ' + totalNoEngageVoice + '\n\n';
                
                if (!successfulQuotes.isEmpty()) {
                    emailBody += 'SUCCESSFUL Screen Recording QLI Insertions (' + successfulQuotes.size() + '):\n';
                    emailBody += String.join(successfulQuotes, ', ') + '\n\n';
                }
                
                if (!errorMap.isEmpty()) {
                    emailBody += 'Failed Quotes (' + errorMap.size() + '):\n';
                    for (Id quoteId : errorMap.keySet()) {
                        emailBody += '- ' + quoteId + ': ' + errorMap.get(quoteId) + '\n';
                    }
                    emailBody += '\n';
                }
                
                if (!failedMasterQuotes.isEmpty()) {
                    emailBody += 'Failed Master Quotes (' + failedMasterQuotes.size() + '):\n';
                    emailBody += String.join(failedMasterQuotes, ', ') + '\n\n';
                }
                
                if (!failedTechnicalQuotes.isEmpty()) {
                    emailBody += 'Failed Technical Quotes (' + failedTechnicalQuotes.size() + '):\n';
                    emailBody += String.join(failedTechnicalQuotes, ', ') + '\n\n';
                }
                
                if (!unprocessableQuotes.isEmpty()) {
                    emailBody += 'Unprocessable Quotes (' + unprocessableQuotes.size() + '):\n';
                    emailBody += String.join(unprocessableQuotes, ', ') + '\n\n';
                }
                
                Set<String> allFailedIds = new Set<String>();
                allFailedIds.addAll(failedMasterQuotes);
                allFailedIds.addAll(failedTechnicalQuotes);
                allFailedIds.addAll(unprocessableQuotes);
                
                if (!allFailedIds.isEmpty()) {
                    emailBody += 'All Failed/Unprocessable Quote IDs (' + allFailedIds.size() + '):\n';
                    emailBody += String.join(new List<String>(allFailedIds), ', ') + '\n\n';
                }
                
                emailBody += 'Batch Job ID: ' + BC.getJobId() + '\n';
                emailBody += 'Completed: ' + DateTime.now().format();
        
        return emailBody;
    }
}