public without sharing class QtcMetricsController {

    public static final String PERIOD_MONTH = 'month';
    public static final String PERIOD_QUARTER = 'quarter';

    @AuraEnabled(cacheable=true)
    public static List<ChartWrapper> getFilteredData(ChartFilter filter, String monthDate) {
        List<ChartWrapper> result = new List<ChartWrapper>();
        if (filter == null || String.isBlank(monthDate)) {
            return result;
        }

        String quotesQueryString = 
            'SELECT Id, CreatedDate, OpportunityId, ' +
                '(SELECT Id FROM ProcessSteps), (SELECT Id, Status__c FROM DQ_Deal_Qualifications__r) ' +
            'FROM Quote ' +
            'WHERE QuoteType__c = \'' + QuoteHelper.QUOTE_TYPE_AGREEMENT + '\' AND RecordTypeId = \'' +  QuoteHelper.RT_ID_BILLING + '\' AND isPrimary__c = true';

        String selectedMonth = monthDate.split('-')[1];
        String selectedYear = monthDate.split('-')[0];
        quotesQueryString += ' AND CALENDAR_MONTH(CreatedDate) = ' + selectedMonth + ' AND CALENDAR_YEAR(CreatedDate) = ' + selectedYear;

        quotesQueryString = populateQueryStringFilterWithOptions(quotesQueryString, 'Brand_Name__c', 'Opportunity', filter.brands);
        quotesQueryString = populateQueryStringFilterWithOptions(quotesQueryString, 'Type', 'Opportunity', filter.types);
        quotesQueryString = populateQueryStringFilterWithOptions(quotesQueryString, 'Name', 'Opportunity.RecordType', filter.oppRecordTypes);
        quotesQueryString = populateQueryStringFilterWithOptions(quotesQueryString, 'SegmentName__c', 'Account__r', filter.accountSegments);

        List<Quote> allQuotes = Database.query(quotesQueryString);

        Map<Id, Quote> oppIdToQuoteWithoutApprovalMap = new Map<Id, Quote>();
        Map<Id, Quote> oppIdToQuoteWithApprovalMap = new Map<Id, Quote>();

        for (Quote qt : allQuotes) {
            if (qt.ProcessSteps.size() == 0 
                && (qt.DQ_Deal_Qualifications__r.size() == 0 
                    || (qt.DQ_Deal_Qualifications__r.size() == 1 && qt.DQ_Deal_Qualifications__r[0].Status__c == 'New'))
            ) {
                oppIdToQuoteWithoutApprovalMap.put(qt.OpportunityId, qt);
            } else if (qt.ProcessSteps.size() != 0 
                || (qt.DQ_Deal_Qualifications__r.size() == 1 && qt.DQ_Deal_Qualifications__r[0].Status__c == 'Approved')
            ) {
                oppIdToQuoteWithApprovalMap.put(qt.OpportunityId, qt);
            }
        }

        List<dsfs__DocuSign_Status__c> docusignStatusesWithoutApproval = new List<dsfs__DocuSign_Status__c>();
        List<dsfs__DocuSign_Status__c> docusignStatusesWithApproval = new List<dsfs__DocuSign_Status__c>();

        if (filter.lastNDaysApply == true) {
            
            if (filter.lastNDaysPeriod == PERIOD_MONTH) {
                Date lastDayOfMonth = Date.newInstance(Integer.valueOf(selectedYear), Integer.valueOf(selectedMonth), Date.daysInMonth(Integer.valueOf(selectedYear), Integer.valueOf(selectedMonth)));

                docusignStatusesWithoutApproval = [
                    SELECT Id, CreatedDate, dsfs__Opportunity__c 
                    FROM dsfs__DocuSign_Status__c
                    WHERE dsfs__Opportunity__c IN :oppIdToQuoteWithoutApprovalMap.keySet() 
                        AND CALENDAR_MONTH(CreatedDate) = :Integer.valueOf(selectedMonth) AND CALENDAR_YEAR(CreatedDate) = :Integer.valueOf(selectedYear) 
                        AND CreatedDate >= :lastDayOfMonth.addDays(-Integer.valueOf(filter.lastNDaysNumber) + 1)
                ];
                docusignStatusesWithApproval = [
                    SELECT Id, CreatedDate, dsfs__Opportunity__c 
                    FROM dsfs__DocuSign_Status__c
                    WHERE dsfs__Opportunity__c IN :oppIdToQuoteWithApprovalMap.keySet()
                        AND CALENDAR_MONTH(CreatedDate) = :Integer.valueOf(selectedMonth) AND CALENDAR_YEAR(CreatedDate) = :Integer.valueOf(selectedYear) 
                        AND CreatedDate >= :lastDayOfMonth.addDays(-Integer.valueOf(filter.lastNDaysNumber) + 1)
                ];
            } else if (filter.lastNDaysPeriod == PERIOD_QUARTER) {

                Integer quarter = (Integer)Math.ceil(Integer.valueOf(selectedMonth) / 3.0);

                Date firstDayOfNextQuarter; 
                Integer selectedYearInteger = Integer.valueOf(selectedYear);
                if (quarter != 4) {
                    firstDayOfNextQuarter = Date.newInstance(selectedYearInteger, quarter * 3 + 1, 1);
                } else {
                    firstDayOfNextQuarter = Date.newInstance(selectedYearInteger + 1, 1, 1);
                }
                
                Date lastDayOfQuarter = firstDayOfNextQuarter.addDays(-1);

                docusignStatusesWithoutApproval = [
                    SELECT Id, CreatedDate, dsfs__Opportunity__c 
                    FROM dsfs__DocuSign_Status__c
                    WHERE dsfs__Opportunity__c IN :oppIdToQuoteWithoutApprovalMap.keySet() 
                        AND CALENDAR_MONTH(CreatedDate) = :lastDayOfQuarter.month() AND CALENDAR_YEAR(CreatedDate) = :lastDayOfQuarter.year() 
                        AND CreatedDate >= :lastDayOfQuarter.addDays(-Integer.valueOf(filter.lastNDaysNumber) + 1)
                ];
                docusignStatusesWithApproval = [
                    SELECT Id, CreatedDate, dsfs__Opportunity__c 
                    FROM dsfs__DocuSign_Status__c
                    WHERE dsfs__Opportunity__c IN :oppIdToQuoteWithApprovalMap.keySet()
                    AND CALENDAR_MONTH(CreatedDate) = :lastDayOfQuarter.month() AND CALENDAR_YEAR(CreatedDate) = :lastDayOfQuarter.year() 
                    AND CreatedDate >= :lastDayOfQuarter.addDays(-Integer.valueOf(filter.lastNDaysNumber) + 1)
                ];
            }
            
        } else {
            docusignStatusesWithoutApproval = [
                SELECT Id, CreatedDate, dsfs__Opportunity__c 
                FROM dsfs__DocuSign_Status__c
                WHERE dsfs__Opportunity__c IN :oppIdToQuoteWithoutApprovalMap.keySet()
            ];
            docusignStatusesWithApproval = [
                SELECT Id, CreatedDate, dsfs__Opportunity__c 
                FROM dsfs__DocuSign_Status__c
                WHERE dsfs__Opportunity__c IN :oppIdToQuoteWithApprovalMap.keySet()
            ];
        }

        Map<Id, dsfs__DocuSign_Status__c> oppIdToFirstDSWithoutApproval = new Map<Id, dsfs__DocuSign_Status__c>();
        for (dsfs__DocuSign_Status__c ds : docusignStatusesWithoutApproval) {
            if (!oppIdToFirstDSWithoutApproval.containsKey(ds.dsfs__Opportunity__c) 
                || oppIdToFirstDSWithoutApproval.get(ds.dsfs__Opportunity__c).CreatedDate > ds.CreatedDate) {
                    oppIdToFirstDSWithoutApproval.put(ds.dsfs__Opportunity__c, ds);
            }
        }

        Map<Id, dsfs__DocuSign_Status__c> oppIdToFirstDSWithApproval = new Map<Id, dsfs__DocuSign_Status__c>();
        for (dsfs__DocuSign_Status__c ds : docusignStatusesWithApproval) {
            if (!oppIdToFirstDSWithApproval.containsKey(ds.dsfs__Opportunity__c) 
                || oppIdToFirstDSWithApproval.get(ds.dsfs__Opportunity__c).CreatedDate > ds.CreatedDate) {
                    oppIdToFirstDSWithApproval.put(ds.dsfs__Opportunity__c, ds);
            }
        }

        populateChartsData(result, oppIdToQuoteWithoutApprovalMap, oppIdToFirstDSWithoutApproval, false);
        populateChartsData(result, oppIdToQuoteWithApprovalMap, oppIdToFirstDSWithApproval, true);

        return result;
    }

    private static void populateChartsData(List<ChartWrapper> result, Map<Id, Quote> oppIdToQuote, Map<Id, dsfs__DocuSign_Status__c> oppIdToFirstDS, Boolean isWithApprovals) {
        Map<String, List<Decimal>> timeDiffencesToMonthMap = new Map<String, List<Decimal>>();

        Decimal diffSum = 0;
        for (dsfs__DocuSign_Status__c ds : oppIdToFirstDS.values()) {
            Quote qt = oppIdToQuote.get(ds.dsfs__Opportunity__c);
            Decimal hDiff = (Decimal.valueOf(ds.CreatedDate.getTime()) - qt.CreatedDate.getTime())/(1000*60*60);
            if(hDiff < 0) {
                continue;
            }
            String formattedDate = qt.CreatedDate.format('yyyy-MM', 'GMT');
            if (!timeDiffencesToMonthMap.containsKey(formattedDate)) {
                timeDiffencesToMonthMap.put(formattedDate, new List<Decimal>());
            }
            timeDiffencesToMonthMap.get(formattedDate).add(hDiff);
        }
        
        Map<String, Integer> quotesCountByDateMap = new Map<String, Integer>();
        Map<String, Decimal> averageTimeByDateMap = new Map<String, Decimal>();
        Map<String, Decimal> medianTimeByDateMap = new Map<String, Decimal>();

        for (String month : timeDiffencesToMonthMap.keySet()) {
            List<Decimal> timeDifferences = timeDiffencesToMonthMap.get(month);

            // Chart with quotes amount
            Integer count = timeDifferences.size();
            quotesCountByDateMap.put(month, count);

            // Chart with average time to close
            Decimal sum = 0.0;
            for (Decimal timeDiff : timeDifferences) {
                sum += timeDiff;
            }
            if (timeDifferences.size() > 0) {
                Decimal average = sum / timeDifferences.size();
                averageTimeByDateMap.put(month, average.setScale(2));
            }

            // Chart with median time to close
            timeDifferences.sort();
            Decimal median;
            Integer size = timeDifferences.size();
            if (Math.mod(size, 2) == 0) {
                median = (timeDifferences[size / 2 - 1] + timeDifferences[size / 2]) / 2;
            } else {
                median = timeDifferences[(size - 1) / 2];
            }
            medianTimeByDateMap.put(month, median.setScale(2));
        }

        String quotesCountByDateChartName = isWithApprovals ? 'quotesCountByDate' + 'WithApprovals' : 'quotesCountByDate' + 'WithoutApprovals';
        String averageTimeByDateChartName = isWithApprovals ? 'averageTimeByDateMap' + 'WithApprovals' : 'averageTimeByDateMap' + 'WithoutApprovals';
        String medianTimeByDateChartName = isWithApprovals ? 'medianTimeByDateMap' + 'WithApprovals' : 'medianTimeByDateMap' + 'WithoutApprovals';
        result.add(new ChartWrapper(quotesCountByDateChartName, quotesCountByDateMap));
        result.add(new ChartWrapper(averageTimeByDateChartName, averageTimeByDateMap));
        result.add(new ChartWrapper(medianTimeByDateChartName, medianTimeByDateMap));

    }
    
    @AuraEnabled(cacheable=true)
    public static PicklistOptionsWrapper getPicklistValues() {

        PicklistOptionsWrapper optionsWrapper = new PicklistOptionsWrapper();  
        optionsWrapper.brands = getPicklistValues('Opportunity', 'Brand_Name__c');
        optionsWrapper.types = getPicklistValues('Opportunity', 'Type');
        optionsWrapper.oppRecordTypes = getOpportunityRecordTypes();
        optionsWrapper.accountSegments = getUniqueAccountSegments();
        
        return optionsWrapper;
    }

    private static List<PicklistOption> getPicklistValues(String objectApiName, String fieldApiName) {
        List<PicklistOption> options = new List<PicklistOption>();
        List<Schema.PicklistEntry> picklistEntries = ((SObject)Type.forName(objectApiName).newInstance()).getSObjectType().getDescribe().fields.getMap().get(fieldApiName).getDescribe().getPicklistValues();

        for (Schema.PicklistEntry entry : picklistEntries) {
            PicklistOption option = new PicklistOption();
            option.label = entry.getLabel();
            option.value = entry.getValue();
            options.add(option);
        }

        return options;
    }

    private static List<PicklistOption> getOpportunityRecordTypes() {
        List<PicklistOption> options = new List<PicklistOption>();
        
        Map<String, Schema.RecordTypeInfo> recordTypes = Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName();
    
        for (String rtName : recordTypes.keySet()) {
            Schema.RecordTypeInfo rtInfo = recordTypes.get(rtName);
            
            PicklistOption option = new PicklistOption();
            option.label = rtInfo.getName();
            option.value = rtInfo.getRecordTypeId();
            
            options.add(option);
        }
        
        return options;
    }


    private static String populateQueryStringFilterWithOptions(String query, String fieldName, String parentObject, List<String> options) {
        if (options == null || options.isEmpty()) {
            return query;
        }

        String parentObjectQuery = String.isNotBlank(parentObject) ? parentObject + '.' : '';
        String condition = ' AND ' + parentObjectQuery + fieldName + ' IN (';
        for (String opt : options) {
            condition += '\'' + opt + '\', ';
        }
        condition = condition.removeEnd(', ') + ')';

        return query + condition;
    }


    private static List<PicklistOption> getUniqueAccountSegments() {
        List<PicklistOption> options = new List<PicklistOption>();

        List<Segment_Master__c> segments = [SELECT Name FROM Segment_Master__c];
    
        Set<String> uniqueNames = new Set<String>();
        for (Segment_Master__c segment : segments) {
            if (!uniqueNames.contains(segment.Name)) {
                PicklistOption option = new PicklistOption();
                option.label = segment.Name;
                option.value = segment.Name;
                options.add(option);
                uniqueNames.add(segment.Name);
            }
        }
        return options;
    }

    @AuraEnabled(cacheable=true)
    public static TableRowData getCasesStatistic(TableFilter filter, String monthDate) {
        TableRowData result = new TableRowData();

        if (String.isBlank(monthDate) || filter == null || filter.caseOrigins == null) {
            return result;
        }

        result.rowDate = monthDate;

        String allOppsQueryString = 
            'SELECT Id, CreatedDate ' +
            'FROM Opportunity ' + 
            'WHERE (NOT Name LIKE \'%[TEST]%\') AND CPQ_Opportunity__c = false AND PrimaryQuote__c != null';

        String selectedMonth = monthDate.split('-')[1];
        String selectedYear = monthDate.split('-')[0];
        allOppsQueryString += ' AND CALENDAR_MONTH(CreatedDate) = ' + selectedMonth + ' AND CALENDAR_YEAR(CreatedDate) = ' + selectedYear;

        List<Opportunity> allOpps = Database.query(allOppsQueryString);
        result.totalNumberOfOpps = String.valueOf(allOpps.size());

        Set<Id> oppIdsForCalculation = new Set<Id>();
        for (Opportunity opp : allOpps) {
            oppIdsForCalculation.add(opp.Id);
        }

        String casesQueryString = 
            'SELECT Id, Subject, Opportunity_Reference__c, Origin, RecordTypeId ' +
            'FROM Case ' + 
            'WHERE CALENDAR_MONTH(CreatedDate) = ' + selectedMonth + ' AND CALENDAR_YEAR(CreatedDate) = ' + selectedYear +
                ' AND ( ' +
                    'RecordTypeId = \'' + CaseHelper.RT_ID_INTERNAL_BUSINESS_SERVICES + '\'' +
                    ' OR RecordTypeId = \'' + CaseHelper.RT_ID_DEAL_AND_ORDER_SUPPORT + '\'' +
                    ' OR Subject LIKE \'QT2.0_Case%\' OR Subject LIKE \'UQT_Case%\'' + 
                ')';

        List<Case> cases = Database.query(casesQueryString);

        List<String> originsForCreateACase = new List<String>();
        QTC_Metrics_Settings__c qtcSettings = QTC_Metrics_Settings__c.getInstance();
        if (qtcSettings != null) {
            String caseOriginsValue = qtcSettings.CaseOriginsForCreateACase__c;
            if (!String.isBlank(caseOriginsValue)) {
                for (String origin : caseOriginsValue.split(',')) {
                    originsForCreateACase.add(origin);
                }
            }
        }

        Integer reportedCases = 0;
        Integer techCases = 0;

        for (Case cs : cases) {
            Boolean isCreatedByCreateACaseForDD = cs.recordTypeId == CaseHelper.RT_ID_DEAL_AND_ORDER_SUPPORT;
            Boolean isCaseOriginFilterApplied = filter.caseOrigins.isEmpty() || filter.caseOrigins.contains(cs.Origin)
                || (filter.caseOrigins.contains(CaseHelper.CASE_ORIGIN_QUOTING_PAGE) && cs.Subject != null && (cs.Subject.contains('QT2.0_Case') || cs.Subject.contains('UQT_Case')));

            if (isCreatedByCreateACaseForDD && isCaseOriginFilterApplied) {
                reportedCases++;
            }
            if (cs.RecordTypeId == CaseHelper.RT_ID_INTERNAL_BUSINESS_SERVICES && originsForCreateACase.contains(cs.Origin)) {
                techCases++;
            }
        }

        result.casesForDD = String.valueOf(reportedCases);
        result.percentOfDDCasesViaCreateACase = oppIdsForCalculation.size() != 0 ? String.valueOf((Decimal.valueOf(reportedCases)/allOpps.size()*100).setScale(2)) : '-';

        result.casesInSustainingQueueViaCreateACase = String.valueOf(techCases);
        result.percentOfCasesInSustainingQueueViaCreateACase = allOpps.size() != 0 ? String.valueOf((Decimal.valueOf(techCases)/allOpps.size()*100).setScale(2)) : '-';

        return result;
    }
    

    @AuraEnabled(cacheable=true)
    public static TableOptionsWrapper getCasesStatisticOptions() {

        TableOptionsWrapper optionsWrapper = new TableOptionsWrapper();  

        optionsWrapper.caseOrigins = new List<PicklistOption>();
        QTC_Metrics_Settings__c qtcSettings = QTC_Metrics_Settings__c.getInstance();
        if (qtcSettings != null) {
            String caseOriginsValue = qtcSettings.CaseOriginsForCreateACase__c;
            if (!String.isBlank(caseOriginsValue)) {
                for (String origin : caseOriginsValue.split(',')) {
                    PicklistOption option = new PicklistOption();
                    option.label = option.value = origin;
                    optionsWrapper.caseOrigins.add(option);
                }
            }
        }
         
        return optionsWrapper;
    }


    public class PicklistOptionsWrapper {
        @AuraEnabled
        public List<PicklistOption> brands { get; set; }
        
        @AuraEnabled
        public List<PicklistOption> types { get; set; }

        @AuraEnabled
        public List<PicklistOption> oppRecordTypes { get; set; }

        @AuraEnabled
        public List<PicklistOption> accountSegments { get; set; }
    }

    public class PicklistOption {
        @AuraEnabled
        public String label { get; set; }

        @AuraEnabled
        public String value { get; set; }
    }

    public class ChartFilter {
        @AuraEnabled public List<String> brands { get; set; }
        @AuraEnabled public List<String> types { get; set; }
        @AuraEnabled public List<String> oppRecordTypes { get; set; }
        @AuraEnabled public List<String> accountSegments { get; set; }
        
        @AuraEnabled public Boolean lastNDaysApply { get; set; }
        @AuraEnabled public String lastNDaysNumber { get; set; }
        @AuraEnabled public String lastNDaysPeriod { get; set; }
    }

    public class ChartWrapper {
        @AuraEnabled public String chartName;
        @AuraEnabled public Map<String, Decimal> data;

        public ChartWrapper(String chartName, Map<String, Decimal> data) {
            this.chartName = chartName;
            this.data = data;
        }
    }

    public class TableRowData {
        @AuraEnabled public String rowDate;
        @AuraEnabled public String totalNumberOfOpps;
        @AuraEnabled public String totalNumberOfRelatedCases;
        @AuraEnabled public String percentOfCasesRelatedToQuoting;
        @AuraEnabled public String casesInSustainingQueueViaCreateACase;
        @AuraEnabled public String percentOfCasesInSustainingQueueViaCreateACase;
        @AuraEnabled public String casesForDD;
        @AuraEnabled public String percentOfDDCasesViaCreateACase;
    }

    public class TableFilter {
        @AuraEnabled public List<String> caseOrigins  { get; set; }
    }

    public class TableOptionsWrapper {
        @AuraEnabled
        public List<PicklistOption> caseOrigins { get; set; }
    }
}