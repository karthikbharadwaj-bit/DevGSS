public class ExcludePartnerNonBusinessHours {

    @InvocableMethod(label='Determine next follow up Date' description='Returns the next follow up date excluding the holidays')
    public static List<Result> nextFollowUpDate(List<Requests> records) {
        final Integer defaultHours = 24;
        List<Result> results = new List<Result>();
        Set<String> bsName = new Set<String>();
        Map<String,Id> bsNameIDMap = new Map<String,Id>();
        List<String> interval;
        DateTime targetTime;
        Integer hours ;
        Integer loopCount = 0;
        Integer increment = 0;
        Boolean isWithin = false;

        for (Requests rec : records) {
            bsName.add(rec.businessHoursName);
        }
        List<BusinessHours> bsList = [SELECT Id,Name FROM BusinessHours WHERE Name in :bsName];
        for (BusinessHours bs : bsList) {
            bsNameIDMap.put(bs.Name,bs.Id);
        }
        for (Requests record : records) {
        interval = new List<String>();
        targetTime = DateTime.now();
        isWithin = false;
        if (bsNameIDMap.containsKey(record.businessHoursName)) {
            Id businessHoursId = bsNameIDMap.get(record.businessHoursName);
            
            if (record.followUpInterval != '') {
                interval = record.followUpInterval.split(',');
            }
            hours = (interval.size() > 0  && record.followUpCount.intValue() < interval.size()) 
                            ? Integer.valueOf(interval[record.followUpCount.intValue()]) : defaultHours;
            loopCount = Math.ceil((Decimal)hours/defaultHours).intValue();
            increment = (hours >= defaultHours) ? defaultHours : hours;
            // Based on the number of days to skip, each day is incrementally checked to determine if it is a business day.
            for (Integer i = 1; i <= loopCount; i++ ) {
                while (!isWithin) {
                    targetTime = targetTime.addHours(increment);
                    isWithin= BusinessHours.isWithin(businessHoursId, targetTime);
                }
                isWithin = false;
            }
        }
        Result res = new Result();
        res.nextFollowDate = targetTime;
        results.add(res);
        }
        return results;
    }


    public class Requests {
        @InvocableVariable(label='BusinessHours Name from mdt' required=true )
        public String businessHoursName;

        @InvocableVariable(label='Follow up count from Record' required=true placeholderText='Number. Ex. 2')
        public Decimal followUpCount;

        @InvocableVariable(label='Follow up Interval from mdt' required=true placeholderText='String. Ex. 24,48,120')
        public String followUpInterval;
    }

    public class Result {
        @InvocableVariable(label='Next Follow Up Date' required=true)
        public DateTime nextFollowDate;
    }
}