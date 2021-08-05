/**
 * Created by Igor Malyuta on 31.05.2019.
 *
 * WARNING: This Apex Class is part of a package ct-batch-panel. You'll lose any edits you make directly in the org if you reinstall or upgrade the package
 */

public abstract class Batch_ScheduledAbstract implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {

    public static final String INTERVAL_MINUTES = 'Minutes';
    public static final String INTERVAL_HOURS = 'Hours';
    public static final String INTERVAL_DAYS = 'Days';
    public static final String INTERVAL_WEEKS = 'Weeks';
    public static final String INTERVAL_MONTHS = 'Months';
    
    private Long startTimeMs = Datetime.now().getTime();

    public abstract Type getType();

    /**
     * Description of the purpose of this batch to display on the panel
     * @return description
     */
    public virtual String getBatchDescription() {
        return null;
    }

    /**
     * Pre-setup for batch panel
     * @return interval mode
    */
    public virtual String getRecommendedIntervalMode() {
        return INTERVAL_MINUTES;
    }

    /**
     * Pre-setup for batch panel
     * @return relaunch interval
    */
    public virtual Integer getRecommendedRelaunchInterval() {
        return 10;
    }

    /**
     * Pre-setup for batch panel
     * @return recommended scope size
    */
    public virtual Integer getRecommendedScopeSize() {
        return 200;
    }
    
    /**
     * Final logic will be executed in finish
     */
    public virtual void finalAction() {

    }

    public virtual void finish(Database.BatchableContext bc) {
        finalAction();
        List<Batch_Detail__c> batchDetails = [
                SELECT
                        Interval_Mode__c,
                        Relaunch_Interval__c,
                        Scope_Size__c
                FROM Batch_Detail__c
                WHERE Name = :getType().getName()
        ];
        if (!batchDetails.isEmpty()) {
            Batch_Detail__c detail = batchDetails.get(0);
            detail.Last_Duration_Min__c = (0.0 + Datetime.now().getTime() - startTimeMs)/(1000*60);
            update detail;
            Integer executionMinutes = Math.round(detail.Last_Duration_Min__c);
            System.debug('Batch execution time in minutes: ' + executionMinutes);
            Integer minutes = getMinutesByMode(detail.Interval_Mode__c, detail.Relaunch_Interval__c.intValue());
            minutes = minutes - executionMinutes;
            Integer scopeSize = detail.Scope_Size__c.intValue();
            System.debug('Next Scope Size: ' + scopeSize);
            if(Test.isRunningTest()) return;
            if(minutes > 0){
                System.scheduleBatch((Database.Batchable<SObject>) getType().newInstance(), getType().getName(), minutes, scopeSize);
            } else{
                Database.executeBatch((Database.Batchable<SObject>) getType().newInstance(), scopeSize);
            }
        }
    }

    public static Integer getMinutesByMode(String intervalMode, Integer interval) {
        Integer minutes;
        switch on intervalMode {
            when 'Hours' {
                minutes = interval * 60;
            }
            when 'Days' {
                minutes = interval * 1440;
            }
            when 'Weeks' {
                minutes = interval * 10080;
            }
            when 'Months' {
                minutes = interval * 43800;
            }
            when else {
                minutes = interval;
            }
        }

        return minutes;
    }
}