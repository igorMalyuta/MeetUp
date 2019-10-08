/**
 * Created by Igor Malyuta on 31.05.2019.
 */

public abstract class Batch_ScheduledAbstract implements Database.Batchable<SObject>, Database.Stateful {

    public abstract Type getType();

    public void finish(Database.BatchableContext param1) {
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
            Integer minutes = getMinutesByMode(detail.Interval_Mode__c, detail.Relaunch_Interval__c.intValue());
            Integer scopeSize = detail.Scope_Size__c.intValue();
            System.scheduleBatch(
                    (Database.Batchable<SObject>) getType().newInstance(), getType().getName(), minutes, scopeSize);
        }
    }

    private Integer getMinutesByMode(String intervalMode, Integer interval) {
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