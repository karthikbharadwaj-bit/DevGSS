public with sharing class LeadCPUMonitorHelper {

    public static final String[] SOBJECTS_TO_MONITOR = new String[]{'Lead', 'Contact', 'Case'};

    @testVisible
    private static String SOBJECT_TO_TEST;

    @testVisible
    private static Integer AMOUNT_OF_SOBJECT_TO_TEST = 200;

    @AuraEnabled(cacheable=true)
    public static List<CPU_Monitor__c> getCPUMonitorsFilteredByDays(String wantedsObject, Integer days, String orderBy, String sortDirection) {
        try {
            String query = 'SELECT Id, Name, CPU_Usage__c, Transaction_Type__c, Status__c, Error__c, CreatedDate, SOQL_Queries__c, Error_part__c, Lead_Type__c FROM CPU_Monitor__c';
            String dateTimeFormat = DateTime.now().addDays(days * -1).format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
            String wher = ' WHERE CreatedDate >= ' + dateTimeFormat;
            if (wantedsObject == 'Lead Conversion') {
                wher += 'AND Transaction_Type__c = \'Lead Conversion\'';
            } else {
                wher += ' AND (Transaction_Type__c = \''+ wantedsObject + ' Creation\'' + ' OR Transaction_Type__c = \'' + wantedsObject  + ' Update\'' + ')';
            }
            query += wher;
            if (orderBy != null && sortDirection != null) {
                query += ' ORDER BY ' + orderBy + ' ' + sortDirection;
            }
            return (List<CPU_Monitor__C>) Database.query(query);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static string getReportInformation(String transactionType, String days) {
        try {
            Report repRec = [SELECT Id,Name,DeveloperName from Report where DeveloperName = :'CPU_Usage_Last_12_months_3Je'];
            string reportPlannedId = repRec.Id;
            // Retrieves report metadata
            Reports.ReportDescribeResult describe = Reports.ReportManager.describeReport(reportPlannedId);
            Reports.ReportMetadata reportMd = describe.getReportMetadata();
            reportMd.getReportFilters()[0].setValue(days);
            reportMd.getReportFilters()[1].setValue(transactionType);
            // Run report
            Reports.ReportResults reportResult = Reports.ReportManager.runReport(reportPlannedId,reportMd);
            return JSON.serialize(reportResult);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static string getSOQLReportInformation(String days) {
        try {
            Report repRec = [SELECT Id,Name,DeveloperName from Report where DeveloperName = :'SOQL_Queries_Last_12_months_6qm'];
            string reportPlannedId = repRec.Id;
            // Retrieves report metadata
            Reports.ReportDescribeResult describe = Reports.ReportManager.describeReport(reportPlannedId);
            Reports.ReportMetadata reportMd = describe.getReportMetadata();
            reportMd.getReportFilters()[1].setValue(days);
            // Run report
            Reports.ReportResults reportResult = Reports.ReportManager.runReport(reportPlannedId,reportMd);
            return JSON.serialize(reportResult);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public static void sendEmailNotification(List<CPU_Monitor__c> monitors) {
        BatchJobsConfiguration__c bjc = BatchJobsConfiguration__c.getValues('BatchJob_LeadCPUMonitor');

        if (bjc != null && String.isNotBlank(bjc.ErrorEmailDistributionList__c)) {

            String chunkSize = String.valueOf(bjc.ChunkSizeLimit__c != null ? bjc.ChunkSizeLimit__c.intValue() : 200);
            List<String> emailsToSend = bjc.ErrorEmailDistributionList__c.split(',');

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.saveAsActivity = false;
            mail.setToAddresses(emailsToSend);
            mail.setSubject('Process Performance Monitor for ' + Datetime.now());

            String monitorInformation = '';

            for (CPU_Monitor__c monitor : monitors) {
                monitorInformation += '<h3>' + monitor.Transaction_Type__c + ':</h3>' +
                '<p>CPU usage: ' + monitor.CPU_Usage__c + ' ms</p>' +
                '<p>Error: ' + (String.isBlank(monitor.Error__c) ? 'None' : monitor.Error__c) +'</p><br/>';
            }

            List<CPU_Monitor__c> cpuMonitorList = (List<CPU_Monitor__c>) new CPUMonitorSelector()
                .selectCPUMonitorForSendingEmail(new List<Object>{ 'Lead Conversion'})
                .executeQuery();

            Boolean thereIsALeadConversionMonitor = cpuMonitorList.size() > 0;

            monitorInformation += '<h3>Lead Conversion:</h3>' +
            '<p>Last Lead Conversion process in error: ' +(thereIsALeadConversionMonitor
                ? getFormattedDate(cpuMonitorList[0].CreatedDate)
                : ''
            ) +
            '</p>' +
            (thereIsALeadConversionMonitor 
                ? '<p><a href="' + Url.getOrgDomainUrl().toExternalForm() + '/' + cpuMonitorList[0].Lead__c + '">Go to Lead</a></p>' 
                : '') +
            '<p>Record type: ' + (thereIsALeadConversionMonitor ? cpuMonitorList[0].Lead_Type__c : 'None') + '</p>' +
            '<p>Error: ' + 
                (thereIsALeadConversionMonitor && (String.isNotBlank(cpuMonitorList[0]?.Error__c)) 
                ? cpuMonitorList[0].Error__c 
                : 'Unknown error') + 
            '</p>';

            mail.setHtmlBody(
                '' +
                '<h2>Process Trigger Performance Monitor for ' +
                Datetime.now() +
                '</h2><br/>' +
                '<h3><a href="' + Url.getOrgDomainUrl().toExternalForm() + '/lightning/n/Process_Performance_Monitor">Process Performance Monitor</a></h3><br/>' +
                monitorInformation
            );
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
        }
    }

    public static string getFormattedDate(Datetime dat) {
        String dateFormatted = dat.format('MM/dd/yyyy, hh:mm aaa');
        
        double difference = (Datetime.now().getTime() - dat.getTime()) / (1000*60);
        
        if (difference < 60) {
            dateFormatted += ' (' + ((Integer) Math.floor(difference)) + ' minute/s ago)';
        } else if (difference / 60 < 24) {
            dateFormatted += ' (' + ((Integer) Math.floor(difference / 60)) + ' hour/s ago)';
        } else if (difference / (60 * 24) < 30) {
            dateFormatted += ' (' + ((Integer) Math.floor(difference / (60 * 24))) + ' day/s ago)';
        } else if (difference / (60 * 24 * 30) < 30) {
            dateFormatted += ' (' + ((Integer) Math.floor(difference / (60 * 24 * 30))) + ' month/s ago)';
        }

        return dateFormatted;
    }

    public static List<List<String>> parseCSV(String contents, Boolean skipHeaders) {
        List<List<String>> allFields = new List<List<String>>();
        contents = contents.replaceAll(',"""', ',"DBLQT').replaceall('""",', 'DBLQT",');
        contents = contents.replaceAll('""', 'DBLQT');
        List<String> lines = new List<String>();
        try {
            lines = contents.split('\n');
        } catch (System.ListException e) {
            System.debug('Limits exceeded?' + e.getMessage());
        }
        Integer num = 0;
        for (String line : lines) {
            // check for blank CSV lines
            if (line.replaceAll(';', '').trim().length() == 0) {
                break;
            }

            List<String> fields = line.split(';');
            List<String> cleanFields = new List<String>();
            String compositeField;
            Boolean makeCompositeField = false;
            for (String field : fields) {
                if (field.startsWith('"') && field.endsWith('"')) {
                    cleanFields.add(field.replaceAll('DBLQT', '"'));
                } else if (field.startsWith('"')) {
                    makeCompositeField = true;
                    compositeField = field;
                } else if (field.endsWith('"')) {
                    compositeField += ',' + field;
                    cleanFields.add(compositeField.replaceAll('DBLQT', '"'));
                    makeCompositeField = false;
                } else if (makeCompositeField) {
                    compositeField += ',' + field;
                } else {
                    cleanFields.add(field.replaceAll('DBLQT', '"'));
                }
            }

            allFields.add(cleanFields);
        }
        if (skipHeaders) {
            allFields.remove(0);
        }
        return allFields;
    }

    public static List<Lead> csvToLeadList(List<List<String>> parsedCSV) {
        List<Lead> leadsToProcess = new List<Lead>();
        List<String> headers = new List<String>();
        Integer rowNumber = 0;
        for (List<String> row : parsedCSV) {
            if (rowNumber == 0) {
                headers.addAll(row);
                rowNumber++;
            } else {
                Lead newLead = new Lead();
                Integer colNumber = 0;
                for (String col : row) {
                    String headerName = headers[colNumber].trim();
                    if (headerName.length() > 0) {
                        try {
                            newLead.put(headerName, col.trim());
                        } catch (exception e) {
                            System.debug('============== Invalid field specified in header ' + headerName);
                        }
                        colNumber++;
                    }
                }
                newLead.put('Bypass_Notification__c', true);
                leadsToProcess.add(newLead);
                rowNumber++;
            }
        }
        return leadsToProcess;
    }

    public static void initilizesObjects(Map<String, List<sObject>> sObjectsByName) {
        if (!Test.isRunningTest()) {
            LeadCPUMonitorHelper.initializeSObjectsThroughStaticResources(sObjectsByName);
        } else {
            LeadCPUMonitorHelper.initializeSObjectsThroughsObjectBuilder(sObjectsByName);
        }
    }

    private static void initializeSObjectsThroughStaticResources(Map<String, List<sObject>> sObjectsByName) {
        List<StaticResource> srs = (List<StaticResource>) new StaticResourceSelector()
            .selectStaticResourceByNames(new object[]{new String[]{ 'LeadTestCSV', 'ContactTestCSV', 'CaseTestCSV' }})
            .executeQuery();

        for (StaticResource sr : srs) {
            if (sr.name.contains('Contact')) {
                sObjectsByName.put('Contact', (List<Contact>) csvTosObjectList('Contact', sr));
            } else if (sr.name.contains('Lead')) {
                sObjectsByName.put('Lead', csvToLeadList(parseCSV(sr.body.toString(), false)));
            } else if (sr.name.contains('Case')) {
                sObjectsByName.put('Case', (List<Case>) csvTosObjectList('Case', sr));
            }
        }
    }

    private static void initializeSObjectsThroughsObjectBuilder(Map<String, List<sObject>> sObjectsByName) {
        sObjectsByName.put(SOBJECT_TO_TEST, createSObjects(SOBJECT_TO_TEST));
    }

    public static List<sObject> csvTosObjectList(String sObjectName, StaticResource sr) {
        sObject[] sObjects = new sObject[]{};
        String[] rows = sr.body.toString().split('\n');
        String[] fieldsApiName = rows[0].split(';');
        fieldsApiName[fieldsApiName.size() - 1] = fieldsApiName[fieldsApiName.size() - 1].trim();
        for (Integer i=1 ; i<rows.size(); i++) {
            sObject sObj = (SObject) Type.forName(sObjectName).newInstance();
            String[] fieldsValues = rows[i].split(';');
            for (Integer j=0; j<fieldsValues.size(); j++) {
                sObj.put(fieldsApiName[j], j == fieldsValues.size() - 1 ? fieldsValues[j].trim() : fieldsValues[j]);
            }
            sObjects.add(sObj);
        }
        return sObjects;
    }

    private static List<sObject> createSObjects(String sObjectName) {
        SObjectType sObjectType = ((SObject) Type.forName(sObjectName).newInstance()).getSObjectType();
        SObjectBuilder sObjectBuilder = new SObjectBuilder(sObjectType);

        switch on sObjectName {
            when 'Lead' {
                sObjectBuilder.setFields(fieldMapForInsertLead());
            }
            when 'Contact' {
                sObjectBuilder.setFields(fieldMapForInsertContact());
            }
            when 'Case' {
                sObjectBuilder.setFields(fieldMapForInsertCase());
            }
        }

        return (List<sObject>) sObjectBuilder
            .quantity(AMOUNT_OF_SOBJECT_TO_TEST)
            .build()
            .getRecords();
    }

    public static void prepareData(String sObjectName, List<sObject> scope) {
        switch on sObjectName {
            when 'Lead' {
                prepareDataForLead();
            }
            when 'Contact' {
                prepareDataForContact((List<Contact>) scope);
            }
        }
    }

    private static void prepareDataForLead() {
        List<Campaign> campaignsToInsert = new List<Campaign>();
        List<Marketing_Asset__c> assetsToInsert = new List<Marketing_Asset__c>();
        for (Integer i = 1; i <= 3; i++) {
            Campaign ca = (Campaign) new SObjectBuilder(Campaign.SObjectType)
                .setField(Campaign.Name, 'LeadCPUMonitorCampaign')
                .setField(Campaign.BMID__c, 'LeadCPUMonitorBMID' + i)
                .setField(Campaign.Intended_Product__c, 'UK General')
                .build()
                .getRecord();
            campaignsToInsert.add(ca);

            Marketing_Asset__c ma = (Marketing_Asset__c) new SObjectBuilder(Marketing_Asset__c.SObjectType)
                .setField(Marketing_Asset__c.Name, 'LeadCPUMonitorAsset' + i)
                .setField(Marketing_Asset__c.Asset_ID__c, 'LeadCPUMonitorAsset' + i)
                .setField(Marketing_Asset__c.Active__c, true)
                .build()
                .getRecord();
            assetsToInsert.add(ma);
        }
        insert campaignsToInsert;
        insert assetsToInsert;
    }

    private static void prepareDataForContact(List<Contact> contacts) {
        Account acc = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.Name, 'TestAccountMonitoring')
            .setField(Account.RC_Account_Status__c, 'Paid')
            .create()
            .getRecord();
        for (Contact cnt : contacts) {
            cnt.AccountId = acc.Id;
        }
    }

    public static void prepareDataForUpdate(String sObjectName, List<sObject> scope) {
        Map<SObjectField, Object> fieldMap;

        if (sObjectName == 'Lead') {
            fieldMap = fieldMapForUpdateLead();
        } else if (sObjectName == 'Contact') {
            fieldMap = fieldMapForUpdateContact();
        } else if (sObjectName == 'Case') {
            fieldMap = fieldMapForUpdateCase();
        }

        for (sObject sObj : scope) {
            for (sObjectField fieldApiName : fieldMap.keySet()) {
                sObj.put(fieldApiName, fieldMap.get(fieldApiName));
            }
        }
    }

    public static void initializeMonitors(Map<String, MonitorWrapper> monitorBysObject) {
        String today = '' + Date.today().month() + '-' + Date.today().day();
        for (String objectToMonitor : SOBJECTS_TO_MONITOR) {
            monitorBysObject.put(objectToMonitor, new MonitorWrapper(objectToMonitor, today));
        }
    }

    private static Map<SObjectField, Object> fieldMapForInsertLead() {
        return new Map<SObjectField, Object>{
            Lead.LastName => 'batchLeadCPUMonitor',
            Lead.Status => LeadTriggerHelper.LEADSTATUSNEW,
            Lead.Email => 'test@testmail.com',
            Lead.Bypass_Notification__c => true,
            Lead.BMID__c => 'LeadCPUMonitor1',
            Lead.Asset_Id__c => 'LeadCPUMonitorAsset1;LeadCPUMonitorAsset2;LeadCPUMonitorAsset3;'
        };
    }

    private static Map<SObjectField, Object> fieldMapForInsertContact() {
        return new Map<SObjectField, Object>{
            Contact.FirstName => 'Test1',
            Contact.LastName => 'Test1',
            Contact.Email => 'test@test.com',
            Contact.Phone => '1234567890',
            Contact.Preferred_Language__c => 'en_US',
            Contact.Marketo_Sync_Disabled__c => true,
            Contact.Is_Instructor__c => true,
            Contact.Account_Admin__c => true
        };
    }

    private static Map<SObjectField, Object> fieldMapForInsertCase() {
        return new Map<SObjectField, Object>{
            Case.Status => 'New',
            Case.Origin => 'Email',
            Case.Subject => 'Subject Test',
            Case.Description => 'Description test',
            Case.Support_Disposition_Level_1__c => 'Discount',
            Case.Support_Disposition_Level_2__c => 'Add',
            Case.Case_Owner_Manager_Email__c => 'fakeEmail@testEmail.com',
            Case.RecordTypeId => CaseHelper.RT_ID_DEALDESK_CASE
        };
    }

    private static Map<SObjectField, Object> fieldMapForUpdateLead() {
        return new Map<SObjectField, Object>{
            Lead.Status => '2. Contacted'
        };
    }

    private static Map<SObjectField, Object> fieldMapForUpdateContact() {
        return new Map<SObjectField, Object>{
            Contact.Asset_Id__c => 'LeadCPUMonitorAsset3',
            Contact.Email => 'TestEmailMonitoring@Monitoring.com',
            Contact.NumberOfEmployees__c => '2000+',
            Contact.AMP_Advocate_Email__c => 'TestEmailAMPMonitoring@Monitoring.com'
        };
    }

    private static Map<SObjectField, Object> fieldMapForUpdateCase() {
        return new Map<SObjectField, Object>{
            Case.Subject => 'New Subject',
            Case.Description => 'New Description'
        };
    }

    public class MonitorWrapper {
        public Integer insertCpuMaxUsage;
        public Integer updateCpuMaxUsage;
        public String error;
        public CPU_Monitor__c monitorInsert;
        public CPU_Monitor__c monitorUpdate;

        public MonitorWrapper(String sObjectName, String today) {
            insertCpuMaxUsage = 0;
            updateCpuMaxUsage = 0;
            error = '';
            monitorInsert = new CPU_Monitor__c(
                Name = 'Monitor ' + sObjectName + ' Creation ' + today,
                Transaction_Type__c = sObjectName + ' Creation'
            );
            monitorUpdate = new CPU_Monitor__c(
                Name = 'Monitor ' + sObjectName + ' Update ' + today,
                Transaction_Type__c = sObjectName + ' Update'
            );
        }
    }
    
    public static List<SObject> csvToSObjectList(List<List<String>> parsedCSV,String ObjName) {
        List<SObject> recordsToProcess = new List<SObject>();
        List<String> headers = new List<String>();
        Schema.SObjectType sObjectType = ((SObject)Type.forName(ObjName).newInstance()).getSObjectType();
        Integer rowNumber = 0;
        for (List<String> row : parsedCSV) {
            if (rowNumber == 0) {
                headers.addAll(row);
                rowNumber++;
            } else {
                SObject newSObjct = sObjectType.newSObject();
                Integer colNumber = 0;
                for (String col : row) {
                    String headerName = headers[colNumber].trim();
                    if (headerName.length() > 0) {
                        try {
                            newSObjct.put(headerName, col.trim());
                        } catch (exception e) {
                            System.debug('============== Invalid field specified in header ' + headerName);
                        }
                        colNumber++;
                    }
                }
                if(ObjName=='Lead')
                {
                    newSObjct.put('Bypass_Notification__c', true);
                }
                recordsToProcess.add(newSObjct);
                rowNumber++;
            }
        }
        return recordsToProcess;
    }

    public static void prepareData() {
        List<Campaign> campaignsToInsert = new List<Campaign>();
        List<Marketing_Asset__c> assetsToInsert = new List<Marketing_Asset__c>();
        for (Integer i = 1; i <= 3; i++) {
            Campaign ca = (Campaign) new SObjectBuilder(Campaign.SObjectType)
                .setField(Campaign.Name, 'LeadCPUMonitorCampaign')
                .setField(Campaign.BMID__c, 'LeadCPUMonitorBMID' + i)
                .setField(Campaign.Intended_Product__c, 'UK General')
                .build()
                .getRecord();
            campaignsToInsert.add(ca);

            Marketing_Asset__c ma = (Marketing_Asset__c) new SObjectBuilder(Marketing_Asset__c.SObjectType)
                .setField(Marketing_Asset__c.Name, 'LeadCPUMonitorAsset' + i)
                .setField(Marketing_Asset__c.Asset_ID__c, 'LeadCPUMonitorAsset' + i)
                .setField(Marketing_Asset__c.Active__c, true)
                .build()
                .getRecord();
            assetsToInsert.add(ma);
        }
        insert campaignsToInsert;
        insert assetsToInsert;
    }

    public static void sendEmailNotification(
        Integer insertCpuMaxUsage,
        Integer updateCpuMaxUsage,
        String insertError,
        String updateError
    ) {
        BatchJobsConfiguration__c bjc = BatchJobsConfiguration__c.getValues('BatchJob_LeadCPUMonitor');
        if (bjc != null) {
            String chunkSize = String.valueOf(bjc.ChunkSizeLimit__c != null ? bjc.ChunkSizeLimit__c.intValue() : 200);
            List<String> emailsToSend = bjc.ErrorEmailDistributionList__c.split(',');
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.saveAsActivity = false;
            mail.setToAddresses(emailsToSend);
            mail.setSubject('Lead Trigger Performance Monitor for ' + Datetime.now());
            mail.setHtmlBody(
                '' +
                '<h2>Lead Trigger Performance Monitor for ' +
                Datetime.now() +
                '</h2><br/>' +
                '<h3>Lead Insert:</h3>' +
                '<p>Maximum amount of CPU usage: ' +
                insertCpuMaxUsage +
                ' ms' +
                '</p>' +
                '<p>Errors: ' +
                (insertError == '' ? '0' : insertError) +
                '</p><br/>' +
                '<h3>Lead Update:</h3>' +
                '<p>Maximum amount of CPU usage: ' +
                updateCpuMaxUsage +
                ' ms' +
                '</p>' +
                '<p>Errors: ' +
                (updateError == '' ? '0' : updateError) +
                '</p><br/><br/>' +
                '<p>Records processed: ' +
                chunkSize +
                '</p>'
            );
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
        }
    }
}