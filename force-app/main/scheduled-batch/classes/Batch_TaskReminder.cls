/**
 * Created by Igor Malyuta on 04.11.2019.
 */

public class Batch_TaskReminder extends Batch_ScheduledAbstract{

    public Database.QueryLocator start(Database.BatchableContext param1) {
        return Database.getQueryLocator([
                SELECT Id, Is_Reminder_Send__c
                FROM Task
                WHERE ReminderDateTime = TODAY
                AND Is_Reminder_Send__c = FALSE
        ]);
    }

    public void execute(Database.BatchableContext param1, List<Task> tasks) {
        //Send email
        for (Task t : tasks) t.Is_Reminder_Send__c = true;
        update tasks;
    }

    public override Type getType() {
        return Batch_TaskReminder.class;
    }


}